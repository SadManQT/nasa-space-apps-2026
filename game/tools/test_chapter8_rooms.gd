## M3-8R: every Chapter 8 scene is staged in its proper location (STORY_FULL.md scene locations, the CHAPTER_08 scene
## scripts, scene_rosters.json, doc 09) with the approved M3-8A road and summit sets, and every join of doc 24 §2.9 that
## touches Chapter 8, its §4 clues and §5.2 echoes can play in the world. Builds the real room scenes with the real
## PlayerController and cast, then checks the mapping and the two teams, stations for every scene action, navigation,
## collision, walking, resting props, readable words, the crew inside pressure or suited (aboard the rover cabin, EVA
## suits with the visor down outside), the Moon rules (black sky, the dated 3 % crescent Earth at its true size only
## where presented, faint stars only on the dark road), the dish aimed at that Earth, and that earlier chapters'
## rooms come back exactly. EX-CH08-S01 and S11 play in the EN_Garage room (LOC-08), which M3-105 builds and stages.
##   Godot --headless --path game --script res://tools/test_chapter8_rooms.gd
##   --capture (windowed) also writes production/qa/evidence/M3-8R_*.png and M3-8R_runtime.txt.
extends SceneTree

const Contract = preload("res://scripts/world/room_contract.gd")
const Presentation = preload("res://scripts/world/room_presentation.gd")
const Staging = preload("res://scripts/world/room_staging.gd")
const Gates = preload("res://scripts/missions/extended_gate_catalog.gd")
const Roster = preload("res://scripts/companions/companion_roster.gd")
const Crew = preload("res://scripts/world/campaign_crew.gd")
const C8 = preload("res://assets/environment/EN_MalapertSummit/chapter8_assets.gd")
const Player = preload("res://scenes/player/player.tscn")
const SCENE_FILES := {"LOC-01": "commons", "LOC-03": "garden", "LOC-11": "relay_road", "LOC-12": "malapert_summit"}
## STORY_FULL.md / CHAPTER_08: the garage departure and arrival (S01, S11: EN_Garage, M3-105); the relay road's marker-two
## sector, aboard (S02-S03) and EVA (S04); the garden home loop (S05); Aurora's console (S06); the summit platform
## (S07-S09); Aurora's table for the three-place call (S10); the garden at first light (S12).
const EXPECTED_ROOM := {
	"EX-CH08-S01": "LOC-08", "EX-CH08-S02": "LOC-11", "EX-CH08-S03": "LOC-11", "EX-CH08-S04": "LOC-11",
	"EX-CH08-S05": "LOC-03", "EX-CH08-S06": "LOC-01", "EX-CH08-S07": "LOC-12", "EX-CH08-S08": "LOC-12",
	"EX-CH08-S09": "LOC-12", "EX-CH08-S10": "LOC-01", "EX-CH08-S11": "LOC-08", "EX-CH08-S12": "LOC-03",
}
## The other site of a two-site scene, staged for its viewpoint card (the field team aboard at the summit).
const CUTS := {"EX-CH08-S06": "LOC-12", "EX-CH08-S10": "LOC-12"}
const FIELD := ["ferreira", "kai", "rafi"]
const HOME := ["mei", "amara"]
## Rows of sun_positions.json that present Earth over the summit (S07 and S09 through exterior_terrain.json sky_rows).
const SUMMIT_ROWS := {"EX-CH08-S06": "EX-CH08-S06", "EX-CH08-S07": "EX-CH08-S06", "EX-CH08-S08": "EX-CH08-S08", "EX-CH08-S09": "EX-CH08-S10", "EX-CH08-S10": "EX-CH08-S10"}
var checks := 0
var failures := 0
var capture := false
var report: Array[String] = []
var _patterns: Array[RegEx] = []

func _init() -> void:
	# doc 25 §8.1 player-text patterns (test_player_text.gd): no internal ids or engineering verbs on any staged word.
	for source in ["EX-CH\\d", "\\bP-\\d\\d\\b", "\\b[EAWKSZCH] ?\\d", "\\b(LOC|MSG|CS|SFX|CUE|J)-[A-Z0-9]{2}", "(?i)\\b(commit\\w*|stage[sd]?|acknowledg\\w*|role constraints?|operations?)\\b"]:
		var regex := RegEx.new()
		regex.compile(source)
		_patterns.append(regex)
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL ", message)

func _run() -> void:
	capture = OS.get_cmdline_user_args().has("--capture")
	root.size = Vector2i(1600, 900)
	if capture:
		root.always_on_top = true
		root.grab_focus()
	_check_mapping()
	var player := Player.instantiate() as PlayerController
	player.character_glb = "res://assets/characters/CH_Kai/CH_Kai.glb"
	player.controlled = false
	(player.get_node("FollowCamera") as FollowCamera).capture_mouse = false
	root.add_child(player)
	player.set_physics_process(false)
	for scene_id in EXPECTED_ROOM:
		var room_id := String(EXPECTED_ROOM[scene_id])
		if not SCENE_FILES.has(room_id):
			continue
		var room := await _room(room_id)
		room.set_scene_context(scene_id)
		for frame in 3:
			await physics_frame
		await _check_scene(room, scene_id, player)
		room.free()
		await process_frame
	player.free()
	await _check_cuts()
	await _check_echoes()
	await _check_restaging()
	await _check_crew()
	if capture:
		await _capture_all()
	var line := "CHAPTER 8 ROOMS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures]
	print(line)
	report.append(line)
	if capture:
		var file := FileAccess.open("res://../production/qa/evidence/M3-8R_runtime.txt", FileAccess.WRITE)
		file.store_string("\n".join(report) + "\n")
	quit(0 if failures == 0 else 1)

## Builds a real room scene the way the campaign's loading card does (incremental prop binding).
func _room(room_id: String) -> CampaignRoom:
	var room := (load("res://scenes/campaign/rooms/%s.tscn" % SCENE_FILES[room_id]) as PackedScene).instantiate() as CampaignRoom
	room.load_approved_assets = false
	root.add_child(room)
	room.load_approved_assets = true
	await room.load_assets_incremental()
	return room

# ------------------------------------------------------------------------------------------- mapping and teams

func _check_mapping() -> void:
	for scene_id in EXPECTED_ROOM:
		var room_id := Contract.room_for_scene(scene_id)
		_check(room_id == EXPECTED_ROOM[scene_id], scene_id + " is staged in its location " + String(EXPECTED_ROOM[scene_id]))
		_check(String(Gates.gate(scene_id).get("room_id", "")) == room_id, scene_id + " gate names the same room")
		var roster := Roster.scene_roster(scene_id)
		var active := Roster.playable_actor(scene_id)
		_check(roster.size() == 5, scene_id + " all five lunar occupants are on the roster")
		_check(String(roster.get(active, {}).get("physical_location_id", "")) == room_id, "%s the playable %s is in the scene's room" % [scene_id, active])
		var order := Contract.scene_order(scene_id) % 100
		if order == 12:
			_check(roster.values().all(func(r): return String(r.physical_location_id) == "LOC-03"), scene_id + " all five are home in the garden")
			continue
		# Continuity lock: Ferreira, Kai and Rafi on the rover; Mei and Amara at Aurora (canon, all of 8-10 Apr).
		var field_room := String(roster.kai.physical_location_id)
		for id in FIELD:
			_check(String(roster[id].team_id) == "rover" and String(roster[id].physical_location_id) == field_room, "%s %s travels with the rover team" % [scene_id, id])
		for id in HOME:
			_check(String(roster[id].team_id) == "home" and String(roster[id].physical_location_id) in ["LOC-01", "LOC-03"], "%s %s keeps Aurora" % [scene_id, id])
		_check(field_room in ["LOC-08", "LOC-11", "LOC-12"], "%s the rover team is at the garage, on the road or at the summit (%s)" % [scene_id, field_room])
		if SCENE_FILES.has(room_id):
			for target in Gates.targets_for_scene(scene_id):
				_check(not Contract.station_focus(scene_id, String(target.target_id)).is_empty(), scene_id + " action has a room station: " + String(target.target_id))
	_check(Contract.room_for_scene("EX-CH07-S12") == "LOC-08", "Chapter 7's departure stays in the garage (M3-105)")
	var road := Contract.room("LOC-11")
	var summit := Contract.room("LOC-12")
	_check(road.pressure == "vacuum" and summit.pressure == "vacuum" and road.boundary_ids == ["relay_route_boundary"], "the road and the summit platform are open vacuum")
	_check(Contract.layout("LOC-11").assembly == "exterior_kit" and Contract.layout("LOC-12").assembly == "exterior_kit", "both are authored exterior rooms")

# ------------------------------------------------------------------------------------------------ one scene

func _check_scene(room: CampaignRoom, scene_id: String, player: PlayerController) -> void:
	var room_id := room.room_id
	var layout := Contract.staged_layout(room_id, scene_id)
	var stage: Dictionary = room.stage()
	_check(stage.get("layers", []).any(func(id): return String(id).begins_with("ch08_")), scene_id + " room carries its Chapter 8 staging")
	var region := room.navigation_root.get_node("NavigationRegion") as NavigationRegion3D
	var map := region.get_navigation_map()
	NavigationServer3D.map_force_update(map)
	_check(room.navigation_root.get_child_count() == 1, scene_id + " exactly one navigation map after staging")
	var spawn := Vector3(layout.walk_probe[0][0], 0, layout.walk_probe[0][1])
	_check(NavigationServer3D.map_get_closest_point(map, spawn).distance_to(spawn) < 0.4, scene_id + " spawn lies on navigation")
	for point in layout.walk_probe:
		var goal := Vector3(point[0], 0, point[1])
		var path := NavigationServer3D.map_get_path(map, spawn, goal, true)
		_check(path.size() > 0 and path[path.size() - 1].distance_to(goal) < 0.4, scene_id + " obstacle-aware path reaches " + str(goal))
	var focus_ids: Array = room.focus_targets().map(func(t): return String(t.target_id))
	for target in Gates.targets_for_scene(scene_id):
		_check(focus_ids.has(String(target.world_focus_id)), scene_id + " gate focus exists: " + String(target.world_focus_id))
		_check(focus_ids.has(Contract.station_focus(scene_id, String(target.target_id))), scene_id + " station exists for " + String(target.target_id))
	var aboard: Dictionary = stage.get("aboard", {})
	# The walker from the previous room stands aside while sight lines are checked.
	player.position = Vector3(0, -50, 0)
	await physics_frame
	for target in layout.focus_targets:
		var point := Presentation.vector(target.position)
		if bool(target.get("cab", false)):
			# A cab console: used from a seat inside the sealed cabin, within the 3 m reach of the aboard playable seat.
			var active := Roster.playable_actor(scene_id)
			_check(aboard.has(active) and Presentation.vector(aboard[active].at).distance_to(point) < 3.0, scene_id + " the cab console is within reach of the playable seat: " + String(target.target_id))
			continue
		var approach := Presentation.vector(target.approach_m)
		var path := NavigationServer3D.map_get_path(map, spawn, approach, true)
		_check(not path.is_empty() and path[path.size() - 1].distance_to(approach) < 0.4, scene_id + " reachable approach " + String(target.target_id))
		var hit := _ray(approach + Vector3.UP * 1.4, point)
		# A control on a piece with its own collision (the isolator handle, the pedestal screens) is reached at its surface.
		var own := _asset_node(room, String(target.get("asset_id", "")))
		var clear := hit.is_empty() or (own != null and own.is_ancestor_of(hit.collider)) or String(hit.collider.name) == String(target.get("asset_id", "-"))
		_check(clear, scene_id + " interaction line of sight " + String(target.target_id) + ("" if clear else " (blocked by %s)" % String(hit.collider.get_path())))
	await _walk(player, layout, scene_id)
	for obstacle in stage.obstacles:
		var at := Presentation.vector(obstacle.position)
		var size := Presentation.vector(obstacle.size)
		_check(not _ray(at + Vector3(size.x * 0.5 + 0.15, 0, 0), at).is_empty(), scene_id + " staged furniture blocks movement: " + String(obstacle.id))
	_check_doors(room, map, spawn, scene_id)
	_check_anchors(room, map, scene_id)
	_check_staged_text(room, map, scene_id)
	if Contract.room(room_id).pressure == "vacuum":
		_check_exterior(room, scene_id)
	_check_bridges(room, scene_id)

func _walk(player: PlayerController, layout: Dictionary, scene_id: String) -> void:
	player.position = Vector3(layout.walk_probe[0][0], 0.04, layout.walk_probe[0][1])
	player.velocity = Vector3.ZERO
	for point in layout.walk_probe:
		var goal := Vector3(point[0], 0, point[1])
		for step in 900:
			var delta := goal - player.position
			delta.y = 0
			if delta.length() < 0.09:
				break
			player.velocity = delta.normalized() * 3.0 + Vector3.DOWN
			player.move_and_slide()
			await physics_frame
		_check(Vector2(player.position.x - goal.x, player.position.z - goal.z).length() < 0.12, scene_id + " player walks unobstructed to " + str(goal))
	player.velocity = Vector3.ZERO

## Doc 09 clearances stay true with the staged furniture: a 1 m approach to every door or boundary marker is reachable.
func _check_doors(room: CampaignRoom, map: RID, spawn: Vector3, scene_id: String) -> void:
	for node in room.door_root.get_children():
		if not node is CampaignDoor or String(node.boundary_id) == "garden_viewing_shutter":
			continue
		var inward: Vector3 = -node.global_basis.z
		inward.y = 0
		var approach: Vector3 = node.global_position + inward.normalized() * 1.0
		approach.y = 0
		var path := NavigationServer3D.map_get_path(map, spawn, approach, true)
		_check(not path.is_empty() and path[path.size() - 1].distance_to(approach) < 0.25, scene_id + " 1 m door approach stays clear: " + String(node.boundary_id))
		if Contract.room(room.room_id).pressure == "vacuum":
			var half: Vector2 = Vector2(Contract.room(room.room_id).bounds_m[0], Contract.room(room.room_id).bounds_m[1]) * 0.5
			_check(absf(node.position.x) < half.x and absf(node.position.z) < half.y, scene_id + " boundary marker stands inside the room: " + String(node.boundary_id))

## Everyone the roster puts in this room stands on walkable ground clear of each other, or rides a cab seat inside the
## rover's footprint (aboard).
func _check_anchors(room: CampaignRoom, map: RID, scene_id: String) -> void:
	var roster := Roster.scene_roster(scene_id)
	var active := Roster.playable_actor(scene_id)
	var aboard: Dictionary = room.stage().get("aboard", {})
	var rover := _obstacle(room, "rover")
	var placed: Array[Vector3] = []
	for id in roster:
		if String(roster[id].physical_location_id) != room.room_id:
			continue
		if aboard.has(id):
			var seat := Presentation.vector(aboard[id].at)
			_check(rover.has_volume() and rover.grow(-0.4).has_point(seat + Vector3.UP * 0.5), "%s %s rides inside the sealed rover cabin" % [scene_id, id])
			continue
		if id == active:
			continue
		var at := Crew.anchor_position(room.room_id, id, scene_id)
		_check(Contract.staged_anchors(room.room_id, scene_id).keys().any(func(key): return String(key).ends_with("_" + id)), "%s %s has an authored anchor" % [scene_id, id])
		_check(NavigationServer3D.map_get_closest_point(map, at).distance_to(at) < 0.3, "%s %s stands on walkable ground %s" % [scene_id, id, str(at)])
		for other in placed:
			_check(at.distance_to(other) > 0.6, "%s %s keeps 0.6 m from the next person" % [scene_id, id])
		placed.append(at)
	_check(room.room_id != "LOC-11" and room.room_id != "LOC-12" or roster.keys().all(func(id): return String(roster[id].physical_location_id) != room.room_id or aboard.has(id) or String(room.stage().get("outfits", {}).get(id, "")) == "eva"), scene_id + " outside, every cast member is aboard the cabin or in an EVA suit")

func _obstacle(room: CampaignRoom, id: String) -> AABB:
	for spec in room.stage().get("obstacles", []) + Contract.layout(room.room_id).get("obstacles", []):
		if String(spec.id) == id:
			return AABB(Presentation.vector(spec.position) - Presentation.vector(spec.size) * 0.5, Presentation.vector(spec.size))
	return AABB()

## Every staged label faces walkable ground, never mirrored; staged words and the live screens use player language.
func _check_staged_text(room: CampaignRoom, map: RID, scene_id: String) -> void:
	var staged := room.visual_root.get_node_or_null(Staging.ROOT_NAME) as Node3D
	var words: Array[String] = []
	if staged != null:
		for label in staged.find_children("*", "Label3D", true, false):
			if not label.is_visible_in_tree() or String(label.text).strip_edges().is_empty():
				continue
			words.append(String(label.text))
			_check(not label.double_sided, scene_id + " staged label is single-sided: " + String(label.text).left(40))
			var facing: Vector3 = label.global_basis.z
			if absf(facing.y) > 0.7:
				continue  # a page lying on a table reads from above
			facing.y = 0
			facing = facing.normalized()
			var at: Vector3 = label.global_position
			at.y = 0
			var front := 99.0
			for reach in [0.8, 1.2, 1.6, 2.0]:
				var probe: Vector3 = at + facing * reach
				front = minf(front, NavigationServer3D.map_get_closest_point(map, probe).distance_to(probe))
			_check(front < 0.35, scene_id + " staged label reads from walkable ground: " + String(label.text).left(40))
	for node in room.visual_root.get_children():
		for screen in node.get_meta("screen_text", {}).values():
			words.append(String((screen as Label).text))
	for text in words:
		for regex in _patterns:
			_check(regex.search(text) == null, scene_id + " staged words stay in player language: " + text.left(40))

## ART_BIBLE §2 on the flat staging floor: one dated Sun or none, the black sky, Earth only where the dated row presents
## it (at its true 1.9 deg, the thin crescent of 9 Apr 2047), faint stars only where no sunlit ground is in view, and
## the Earth dish aimed at that Earth.
func _check_exterior(room: CampaignRoom, scene_id: String) -> void:
	var environment := (room.get_node("RoomLighting/RoomEnvironment") as WorldEnvironment).environment
	var key := room.get_node("RoomLighting/KeyLight") as DirectionalLight3D
	var earth := Contract.earth(room.room_id, scene_id)
	var shader := (environment.sky.sky_material as ShaderMaterial).shader if environment.sky != null else null
	_check(environment.ambient_light_energy == 0.0 and not environment.fog_enabled and not environment.volumetric_fog_enabled, scene_id + " no ambient glow, fog or haze in vacuum")
	if room.room_id == "LOC-11":
		_check(not bool(earth.presented) and is_zero_approx(key.light_energy), scene_id + " the dated row leaves the road dark: no Sun, no Earth (below the horizon)")
		var stars := float(room.stage().lighting.get("stars", 0.0))
		_check(environment.background_mode == Environment.BG_SKY and shader != null and shader.resource_path.ends_with("sky_env_stars.gdshader") and stars > 0.0, scene_id + " faint stars over the dark road (rule 12)")
		var intensity := float((environment.sky.sky_material as ShaderMaterial).get_shader_parameter("star_intensity")) if shader != null else 9.0
		var floods: bool = room.stage().piece_states.get("rover", {}).get("lights", "") == "eva_stop"
		_check(intensity <= (0.4 if floods else 1.0), scene_id + " stars stay faint (%.2f), barely visible under the work floods" % intensity)
	else:
		_check(bool(earth.presented) and String(earth.source).contains(String(SUMMIT_ROWS[scene_id])), scene_id + " the dated Earth is presented from its row " + String(SUMMIT_ROWS.get(scene_id, "")))
		_check(absf(float(earth.angular_diameter_deg) - 1.899) < 0.001 and float(earth.illuminated_fraction) < 0.04 and float(earth.illuminated_fraction) > 0.02, scene_id + " Earth at its true 1.9 deg, a 3 %% crescent (%.3f lit)" % float(earth.illuminated_fraction))
		_check(shader != null and shader.resource_path.ends_with("sky_env_earth.gdshader"), scene_id + " Earth drawn in the black sky pass, no stars over the sunlit pad")
		var to_sun := Presentation.vector(earth.sun_direction)
		_check(rad_to_deg((-key.global_basis.z).angle_to(-to_sun)) < 0.1 and key.light_energy > 0.0, scene_id + " the key light is the dated Sun, %.1f deg high" % rad_to_deg(asin(to_sun.y)))
		var dish := room.visual_root.get_node("relay_deck").find_child("DishElevation", true, false) as Node3D
		var off := rad_to_deg(dish.global_basis.y.normalized().angle_to(Presentation.vector(earth.direction)))
		_check(off < 0.5, scene_id + " the Earth dish aims at the dated Earth (off by %.2f deg)" % off)

# ------------------------------------------------------------------------------------------------- the joins

func _text(room: CampaignRoom, id: String) -> String:
	var staged := room.visual_root.get_node_or_null(Staging.ROOT_NAME)
	var label := staged.get_node_or_null(id) as Label3D if staged != null else null
	return label.text if label != null and label.visible else ""

func _asset_node(room: CampaignRoom, id: String) -> Node:
	if id.is_empty():
		return null
	var node := room.visual_root.get_node_or_null(id)
	return node if node != null else _staged_node(room, id)

func _screen(room: CampaignRoom, piece: String, slot: String) -> String:
	var node := _asset_node(room, piece)
	if node == null or not node.get_meta("screen_text", {}).has(slot):
		return ""
	return String((node.get_meta("screen_text")[slot] as Label).text)

func _lamp(room: CampaignRoom, piece: String, slot: String) -> Color:
	var node := room.visual_root.get_node(piece)
	var pair: Array = C8.surfaces(node, slot)[0]
	var material := (pair[0] as MeshInstance3D).get_surface_override_material(int(pair[1])) as StandardMaterial3D
	return material.emission if material != null and material.emission_enabled else Color.BLACK

func _rover_lights(room: CampaignRoom) -> Array:
	var rover := room.visual_root.get_node_or_null("rover")
	if rover == null:
		rover = room.visual_root.get_node(Staging.ROOT_NAME).get_node_or_null("rover")
	return rover.get_children().filter(func(n): return n is Light3D and n.visible).map(func(n): return String(n.name)) if rover != null else []

## Doc 24 §2.9 rows CH08 S01 -> S12, §4 clues 22-23 and doc 09's revisit rule, scene by scene.
func _check_bridges(room: CampaignRoom, scene_id: String) -> void:
	var order := Contract.scene_order(scene_id) % 100
	match room.room_id:
		"LOC-11":
			var staged := room.visual_root.get_node(Staging.ROOT_NAME)
			_check(staged.has_node("rover"), scene_id + " the pressurised rover is on the road")
			var guide := room.get_node("RoomLighting/" + Staging.ROOT_NAME).get_children().filter(func(n): return String(n.name).begins_with("guide_glow"))
			_check(guide.size() == 4 and _lamp(room, "guide_light_1", "Lamp_Guide").r > 0.5, scene_id + " amber guide lights every 18 m, alternate sides")
			var repeater := room.visual_root.get_node("repeater_r2") as Node3D
			if order == 2:
				_check(not repeater.visible and _rover_lights(room).has("Headlight_L"), scene_id + " the start of cruise: no service pad yet, headlights on the road (S02 -> S03: cruise begins)")
			else:
				_check(repeater.visible and _lamp(room, "repeater_r2", "Lamp_Beacon") == Color.BLACK, scene_id + " marker two is dark")
			if order == 3:
				var rover := (staged.get_node("rover") as Node3D).position
				var beam := Vector3(sin((staged.get_node("rover") as Node3D).rotation.y), 0, cos((staged.get_node("rover") as Node3D).rotation.y))
				_check(rover.z > 0.0 and rover.z < 9.0 and absf(rover.x - repeater.position.x) < 10.0 and rad_to_deg(beam.angle_to((repeater.position - rover) * Vector3(1, 0, 1))) < 10.0, scene_id + " the rover brakes at the known pad, headlights on the dark marker (S03 -> S04)")
				_check(room.visual_root.get_node("bypass_barrier").visible and room.visual_root.get_node("bypass_slope_sign").visible, scene_id + " the unsupported bypass is closed by the turnback barrier and slope sign")
			if order == 4:
				var rover := (staged.get_node("rover") as Node3D).position
				_check(absf(rover.x) < 10.0 and rover.z < 3.0 and _rover_lights(room).has("RoofFlood_L"), scene_id + " the rover is braked on the pad with its roof work floods on (S03 -> S04)")
				_check(staged.has_node("spare_battery_module"), scene_id + " the replacement battery module waits at the repeater")
		"LOC-12":
			var housing := room.visual_root.get_node("controller_housing") as Node3D
			var lamps := [0, 1, 2].map(func(i): return _lamp(room, "controller_housing", "Lamp_Status_%d" % i))
			match order:
				6, 7:
					_check(lamps.all(func(c): return c == Color.BLACK), scene_id + " the relay housing is dark (S06 -> S07)")
					if order == 7:
						var door := housing.find_child("DoorHinge", true, false) as Node3D
						_check(absf(door.rotation_degrees.y - 105.0) < 0.1, scene_id + " Ferreira braces the service door open")
						_check(room.visual_root.get_node(Staging.ROOT_NAME).has_node("spare_controller"), scene_id + " the compatible spare lies beside the housing")
						_check(_screen(room, "control_pedestal", "Screen_LocalLeg").contains("NO POWER"), scene_id + " the antenna panel waits unpowered")
				8:
					_check(lamps[0].r > 0.8 and lamps[0].g < 0.8 and lamps[1].r > 0.8 and lamps[2] == Color.BLACK, scene_id + " two unverified channels: two amber lamps (S07 -> S08)")
					var earth_leg := _screen(room, "control_pedestal", "Screen_EarthLeg")
					_check(earth_leg.contains("SCENARIO VALUE") and earth_leg.contains("PATH BLOCKED") and _screen(room, "control_pedestal", "Screen_LocalLeg").contains("SCENARIO VALUE"), scene_id + " labelled scenario bearings and a separate blockage check (canon S08)")
					var quads := room.visual_root.get_node("control_pedestal").find_children("PieceScreenQuad_*", "MeshInstance3D", true, false)
					_check(quads.size() >= 3 and quads.all(func(q): return (q.material_override as StandardMaterial3D).albedo_texture is ViewportTexture), scene_id + " the three live screens show their pictures on the screen faces")
				9:
					_check(lamps.all(func(c): return c.g > 0.8), scene_id + " both legs locked: three green lamps (S08 -> S09)")
					var checksum := _screen(room, "control_pedestal", "Screen_Checksum")
					_check(checksum.contains("ALO42") and checksum.contains("EXACT"), scene_id + " ALO42 must come back exactly")
					_check(checksum.contains("QUEUED FOR EARTH") and checksum.contains("AURORA, EARTH. LISTENING."), scene_id + " the queued outbox sends and the listening log arrives (clue 22)")
			if order >= 7:
				_check(_rover_lights(room).has("RoofFlood_L"), scene_id + " the rover's roof floods light the suited work")
		"LOC-01":
			_check(_staged(room, "commons_mug_5") and (_staged_node(room, "commons_mug_5") as Node3D).position.distance_to(Vector3(2.3, 0.74, -5.5)) < 0.01, scene_id + " Ferreira's mug waits on the care desk while she is away")
			_check(_text(room, "home_ledger_text").contains("33 H") and _text(room, "home_ledger_text").contains("LAST 3 H"), scene_id + " the home-night ledger counts two, then five")
			if order == 6:
				var board := _text(room, "ch08_packet_board")
				_check(board.contains("NEW   RAFI   MALAPERT SUMMIT PAD   9 APR 2047, 00:00") and board.contains("OLD") and board.contains("THREE ABOARD"), scene_id + " the current summit packet beside the stale approach packet")
				_check(board.contains("HOME CHECKS FIRST") and board.contains("SMALL GUIDE LIGHT: ON, WHERE PLANNED"), scene_id + " home checks first; the guide light where it was planned (S05 -> S06)")
				_check(board.contains("EARTH UPLINK: STILL DOWN") and _text(room, "outbox_text").contains("NOT SENT"), scene_id + " the Earth uplink is still down; reports still queued")
			if order == 10:
				_check(_text(room, "outbox_text").contains("VOICE CHECKS") and _text(room, "outbox_text").contains("RETURN DEPARTS 03:00"), scene_id + " voice checks, telemetry and the return departure time (S10 -> S11)")
				_check(_screen(room, "network_diagnostic", "Screen_Diag").contains("LIVE VIA THE MALAPERT RELAY"), scene_id + " the Earth link runs through the repaired relay")
				_check(_staged(room, "mei_tablet"), scene_id + " Mei's tablet is at her place for the invitation")
		"LOC-03":
			var panel := _text(room, "home_panel_text")
			_check(_staged(room, "home_panel") and _staged(room, "guide_light_small") and _staged(room, "manual_gauge"), scene_id + " home-loop panel, Amara's independent gauge and the small guide light")
			_check(_staged(room, "descendant_rack") and _text(room, "descendants_card_text").contains("DESCENDANTS"), scene_id + " the plants are labelled descendants; Alo is never shown alive")
			_check(room.visual_root.get_node(Staging.ROOT_NAME).has_node("PL_Cotton_Young"), scene_id + " cotton grows in Tara's bay")
			if order == 5:
				_check(panel.contains("COOL") and panel.contains("DIM") and panel.contains("RETURN: OPEN") and panel.contains("2 HERE FOR 33 H, THEN 5"), scene_id + " the home loop and the home forecast (S05 -> S06)")
			if order == 12:
				_check(panel.contains("FIVE PEOPLE HOME") and panel.contains("30 SEEDS") and panel.contains("11, RETAINED") and panel.contains("COTTON: ALIVE"), scene_id + " the final records before the shutter opens")
				_check(_text(room, "earth_console_title").contains("LIVE"), scene_id + " Noor's Earth console is live")
				_check(_staged(room, "photo_board") and _text(room, "photo_frame_text").contains("SHARED PHOTO"), scene_id + " the first-light photo board waits for the shared photo")

func _staged(room: CampaignRoom, id: String) -> bool:
	var node := _staged_node(room, id)
	return node != null and node.is_visible_in_tree()

func _staged_node(room: CampaignRoom, id: String) -> Node:
	var staged := room.visual_root.get_node_or_null(Staging.ROOT_NAME)
	return staged.get_node_or_null(id) if staged != null else null

# ----------------------------------------------------------------------------- viewpoint cuts, echoes, restaging

## The summit side of S06 and S10: the rover parked on the pad with all three aboard (nobody talks from the open
## exterior), the dark housing beyond the cabin window in S06, the locked relay in S10.
func _check_cuts() -> void:
	for scene_id in CUTS:
		var room := await _room(String(CUTS[scene_id]))
		room.set_scene_context(scene_id)
		await process_frame
		var aboard: Dictionary = room.stage().get("aboard", {})
		_check(FIELD.all(func(id): return aboard.has(id)), scene_id + " the rover team is aboard the pressurised cabin at the summit")
		_check_exterior(room, scene_id)
		var lamps := [0, 1, 2].map(func(i): return _lamp(room, "controller_housing", "Lamp_Status_%d" % i))
		if scene_id == "EX-CH08-S06":
			_check(lamps.all(func(c): return c == Color.BLACK), scene_id + " the dark relay housing beyond the window (S06 -> S07)")
			# From the cabin window the first thing the view meets on the way to the housing is the housing itself.
			var view: Dictionary = room.stage().review_views.cab_s06
			var housing := room.visual_root.get_node("controller_housing") as Node3D
			var hit := _ray(Presentation.vector(view.from), housing.global_position + Vector3.UP * 1.0, [room.collision_root.get_node("rover")])
			_check(not hit.is_empty() and (housing.is_ancestor_of(hit.collider) or String(hit.collider.name) == "controller_housing"), scene_id + " the dark housing is in clear view from the cabin window" + ("" if hit.is_empty() else " (first hit %s)" % String(hit.collider.get_path())))
		else:
			_check(lamps.all(func(c): return c.g > 0.8) and _screen(room, "control_pedestal", "Screen_Checksum").contains("RETURN DEPARTS 9 APR, 03:00"), scene_id + " the relay holds both legs; the return time is on the cabin console (S10 -> S11)")
		room.free()
		await process_frame

## Doc 24 §5.2 echoes in Chapter 8: D1 day-one photo (S05-S12), D10 the invitation open on Mei's screen (S10), and at
## first light D2, D6, D9, D10, D11 and the D13 plaque, each only for the option recorded.
func _check_echoes() -> void:
	var garden := await _room("LOC-03")
	var commons := await _room("LOC-01")
	var cases := [
		[garden, "EX-CH08-S05", "EX-CH01-S01-CHOICE", ["EX-CH01-S01-OPT01", "EX-CH01-S01-OPT02"], "day_one_photo", ["AIR", "PLANTING BAY"]],
		[commons, "EX-CH08-S10", "EX-CH05-S11-CHOICE", ["EX-CH05-S11-OPT01", "EX-CH05-S11-OPT02"], "mei_tablet_text", ["WHAT GROWS NEXT", "WE KEPT A PLACE"]],
		[garden, "EX-CH08-S12", "EX-CH01-S04-CHOICE", ["EX-CH01-S04-OPT01", "EX-CH01-S04-OPT02"], "ch08_d2_notebook_opt0%d_text", ["PAIRED PHOTOGRAPHS", "CONDITIONS TABLE"]],
		[garden, "EX-CH08-S12", "EX-CH06-S01-CHOICE", ["EX-CH06-S01-OPT01", "EX-CH06-S01-OPT02"], "ch08_d11_light_opt0%d_text", ["RAFI", "AMARA"]],
		[garden, "EX-CH08-S12", "EX-CH05-S05-CHOICE", ["EX-CH05-S05-OPT01", "EX-CH05-S05-OPT02"], "ch08_d9_record_opt0%d_text", ["ASCENT MANIFEST", "GREENHOUSE SERVICE NOTE"]],
		[garden, "EX-CH08-S12", "EX-CH03-S11-DEDICATION", ["EX-CH03-S11-DEDICATION-OPT01", "EX-CH03-S11-DEDICATION-OPT02", "EX-CH03-S11-DEDICATION-OPT03"], "ch08_d6_tray_opt0%d_text", ["LIGHT AND STAR", "FOR ALO AND TARA", "THE NEXT SMALL THING"]],
		[garden, "EX-CH08-S12", "EX-CH08-S12-CHOICE", ["EX-CH08-S12-OPT01", "EX-CH08-S12-OPT02"], "dedication_plaque_text", ["EVERY HAND THAT KEPT THE LIGHT", "THE GARDENS WE LEAVE"]],
	]
	for case in cases:
		var room: CampaignRoom = case[0]
		for index in (case[3] as Array).size():
			room.set_story_choices({String(case[2]): {"option_id": String(case[3][index])}})
			room.set_scene_context(String(case[1]))
			await process_frame
			var id := String(case[4]) % (index + 1) if String(case[4]).contains("%d") else String(case[4])
			var shown := _text(room, id)
			if id == "day_one_photo":
				var print_node := _staged_node(room, id)
				shown = String((print_node.get_node("Caption") as Label3D).text) if print_node != null else ""
			_check(shown.contains(String(case[5][index])), "%s %s %s echoes as '%s'" % [case[1], case[2], case[3][index], case[5][index]])
			for other in (case[3] as Array).size():
				if other != index and String(case[4]).contains("%d"):
					_check(_text(room, String(case[4]) % (other + 1)).is_empty(), "%s %s shows only the recorded option" % [case[1], case[2]])
		room.set_story_choices({})
		room.set_scene_context("EX-CH08-S12" if room == garden else "EX-CH08-S10")
		await process_frame
		_check(_text(room, "dedication_plaque_text").is_empty() or room != garden, "no dedication is engraved before the player chooses")
	garden.free()
	commons.free()

## One room re-staged scene after scene ends exactly as built: Chapter 7's care desk and Chapter 1 come back in the
## Commons, and the summit's door and stations do not pile up.
func _check_restaging() -> void:
	var commons := await _room("LOC-01")
	commons.set_scene_context("EX-CH08-S10")
	await process_frame
	commons.set_scene_context("EX-CH07-S10")
	await process_frame
	_check(_text(commons, "outbox_text").contains("NOT SENT") and _staged_node(commons, "mei_tablet") == null, "Chapter 7's care desk returns without Chapter 8 staging")
	_check((_staged_node(commons, "commons_mug_5") as Node3D).position.distance_to(Vector3(0.66, 0.762, 0.08)) < 0.01, "Ferreira's mug is at her place in Chapter 7")
	commons.set_scene_context("EX-CH01-S01")
	await process_frame
	_check(commons.stage().layers.is_empty() and not commons.visual_root.has_node(Staging.ROOT_NAME), "the Chapter 1 Commons shows no later staging")
	commons.free()
	var summit := await _room("LOC-12")
	var base_focus := summit.focus_root.get_child_count()
	for scene_id in ["EX-CH08-S07", "EX-CH08-S09", "EX-CH08-S07"]:
		summit.set_scene_context(scene_id)
		await process_frame
	var door := (summit.visual_root.get_node("controller_housing") as Node3D).find_child("DoorHinge", true, false) as Node3D
	_check(absf(door.rotation_degrees.y - 105.0) < 0.1 and summit.navigation_root.get_child_count() == 1, "the summit re-stages cleanly (door, one navigation map)")
	summit.set_scene_context("EX-CH08-S08")
	await process_frame
	_check(is_zero_approx(door.rotation_degrees.y) and summit.focus_root.get_child_count() == base_focus + 1, "the housing door closes again and staged stations do not pile up")
	summit.free()

# ------------------------------------------------------------------------------------------------ the cast

## CampaignCrew places each staged scene's roster: the playable body and the companions, suited outside with the visor
## down, hidden aboard the sealed cabin (the playable one keeps its camera at its cab seat), never a coverall in vacuum.
func _check_crew() -> void:
	var crew := Crew.new()
	root.add_child(crew)
	for scene_id in EXPECTED_ROOM:
		var room_id := String(EXPECTED_ROOM[scene_id])
		if not SCENE_FILES.has(room_id):
			continue
		var room := await _room(room_id)
		var anchors := Contract.anchors(room_id)
		var player_at := Vector3.ZERO
		for key in anchors:
			if String(key).ends_with("_player"):
				player_at = Vector3(anchors[key][0], anchors[key][1], anchors[key][2])
		var player := crew.place(scene_id, room, player_at)
		for frame in 4:
			await physics_frame
		var roster := Roster.scene_roster(scene_id)
		var expected := roster.values().filter(func(r): return String(r.physical_location_id) == room_id).size()
		_check(crew.local_ids.size() == expected, "%s places exactly the %d in the room" % [scene_id, expected])
		_check(player != null and player == crew.bodies[Roster.playable_actor(scene_id)] and player.follow_camera.camera.current, scene_id + " the playable body owns the camera")
		var aboard: Dictionary = room.stage().get("aboard", {})
		var vacuum := String(Contract.room(room_id).pressure) == "vacuum"
		for id in crew.local_ids:
			var body: PlayerController = crew.bodies[id]
			if aboard.has(id):
				_check(not body.character.visible and body.collision_layer == 0 and body.collision_mask == 0 and is_zero_approx(body.gravity), "%s %s rides hidden in the cabin" % [scene_id, id])
				if body == player:
					_check(body.follow_camera.target_height > 4.4 and body.follow_camera.distance > 6.0, scene_id + " the rider's camera chases over the rover roof, not inside the hull")
				continue
			_check(is_equal_approx(body.gravity, 1.62) and is_equal_approx(body.follow_camera.distance, 3.3), "%s %s walks with lunar gravity and the usual camera" % [scene_id, id])
			_check(body.visible and body.character.visible, "%s %s is shown" % [scene_id, id])
			if vacuum:
				var helmet := body.character.find_child("Helmet", true, false) as Node3D
				var visor := helmet.find_child("Visor", true, false) as Node3D if helmet != null else null
				_check(String(body.character_glb).contains("_EVA") and visor != null and visor.rotation_degrees.x > 70.0, "%s %s wears the EVA suit with the visor down outside (%s, helmet %s)" % [scene_id, id, body.character_glb, helmet != null])
			else:
				_check(not String(body.character_glb).contains("_EVA"), "%s %s wears the coverall indoors" % [scene_id, id])
		if aboard.has(Roster.playable_actor(scene_id)):
			_check(player.position.distance_to(Presentation.vector(aboard[Roster.playable_actor(scene_id)].at)) < 0.05, scene_id + " the playable rider sits at the cab seat")
		room.free()
		await process_frame
	crew.free()

func _ray(from: Vector3, to: Vector3, exclude: Array = []) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = exclude.filter(func(n): return n is CollisionObject3D).map(func(n): return n.get_rid())
	return root.get_world_3d().direct_space_state.intersect_ray(query)

# --------------------------------------------------------------------------------------------- windowed capture

const SHOTS := [
	["S02_cab_road_start", "LOC-11", "EX-CH08-S02", "cab_s02", 70.0],
	["S03_cab_dark_marker", "LOC-11", "EX-CH08-S03", "cab_s03", 70.0],
	["S03_road_bypass", "LOC-11", "EX-CH08-S03", "road_s03", 55.0],
	["S04_battery_swap", "LOC-11", "EX-CH08-S04", "s04_pad", 60.0],
	["S04_pad_wide", "LOC-11", "EX-CH08-S04", "s04_wide", 60.0],
	["S05_home_panel", "LOC-03", "EX-CH08-S05", "ch08_home_panel", 60.0],
	["S05_guide_light", "LOC-03", "EX-CH08-S05", "ch08_guide_light", 60.0],
	["S06_packet_board", "LOC-01", "EX-CH08-S06", "ch08_packet_board", 60.0],
	["S06_summit_cab_view", "LOC-12", "EX-CH08-S06", "cab_s06", 60.0],
	["S07_housing", "LOC-12", "EX-CH08-S07", "s07_housing", 55.0],
	["S07_summit_overview", "LOC-12", "EX-CH08-S07", "summit_overview", 60.0],
	["S08_pedestal", "LOC-12", "EX-CH08-S08", "s08_pedestal", 50.0],
	["S08_toward_earth", "LOC-12", "EX-CH08-S08", "summit_toward_earth", 30.0],
	["S08_earth_close", "LOC-12", "EX-CH08-S08", "earth_close", 6.0],
	["S09_checksum", "LOC-12", "EX-CH08-S09", "s09_checksum", 45.0],
	["S10_summit_cab", "LOC-12", "EX-CH08-S10", "cab_s10", 50.0],
	["S10_call_table", "LOC-01", "EX-CH08-S10", "ch08_call_table", 60.0],
	["S12_home_panel", "LOC-03", "EX-CH08-S12", "ch08_home_panel", 60.0],
	["S12_photo_board", "LOC-03", "EX-CH08-S12", "ch08_photo_board", 60.0],
	["S12_first_light", "LOC-03", "EX-CH08-S12", "ch08_first_light", 70.0],
]

## Windowed: each shot with the scene's cast placed by CampaignCrew (choices recorded so the echoes show), from the
## room's review views. The dated Earth crescent is also framed at 6 deg so its phase can be checked by eye.
func _capture_all() -> void:
	var crew := Crew.new()
	root.add_child(crew)
	var camera := Camera3D.new()
	root.add_child(camera)
	var choices := {"EX-CH01-S01-CHOICE": {"option_id": "EX-CH01-S01-OPT02"}, "EX-CH05-S11-CHOICE": {"option_id": "EX-CH05-S11-OPT02"},
		"EX-CH01-S04-CHOICE": {"option_id": "EX-CH01-S04-OPT01"}, "EX-CH06-S01-CHOICE": {"option_id": "EX-CH06-S01-OPT02"},
		"EX-CH05-S05-CHOICE": {"option_id": "EX-CH05-S05-OPT02"}, "EX-CH03-S11-DEDICATION": {"option_id": "EX-CH03-S11-DEDICATION-OPT02"},
		"EX-CH08-S12-CHOICE": {"option_id": "EX-CH08-S12-OPT01"}}
	for shot in SHOTS:
		var room := await _room(String(shot[1]))
		var player_at := Vector3.ZERO
		var anchors := Contract.anchors(room.room_id)
		for key in anchors:
			if String(key).ends_with("_player"):
				player_at = Vector3(anchors[key][0], anchors[key][1], anchors[key][2])
		if Contract.room_for_scene(String(shot[2])) == room.room_id:
			crew.place(String(shot[2]), room, player_at, choices)
		else:
			for body in crew.get_children():
				(body as Node3D).hide()
			room.set_story_choices(choices)
			room.set_scene_context(String(shot[2]))
		var views: Dictionary = Contract.staged_layout(room.room_id, String(shot[2]), choices).review_views
		var view: Dictionary = views.get(String(shot[3]), {})
		if String(shot[3]) == "earth_close":
			var earth := Contract.earth(room.room_id, String(shot[2]))
			var eye := Vector3(5.645, 1.7, -8.837)  # on the Earth viewpoint rail's standing plate (M3-8A anchor earth_view)
			view = {"from": [eye.x, eye.y, eye.z], "to": [eye.x + earth.direction[0] * 50.0, eye.y + earth.direction[1] * 50.0, eye.z + earth.direction[2] * 50.0]}
		camera.fov = float(shot[4])
		camera.global_position = Presentation.vector(view.from)
		camera.look_at(Presentation.vector(view.to), Vector3.UP)
		camera.current = true
		for frame in 24:
			await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		image.save_png("res://../production/qa/evidence/M3-8R_%s.png" % shot[0])
		report.append("shot %s: %s %s" % [shot[0], shot[2], shot[3]])
		room.free()
		await process_frame
	camera.free()
	crew.free()
