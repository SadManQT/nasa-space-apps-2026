## M3-2R: every Chapter 2 scene is staged in its proper location (STORY_FULL.md scene locations, the CHAPTER_02 scene
## scripts, doc 09, doc 22 section 4) and LOC-05 is a real kit room built from the approved M3-2A airlock. Builds the
## real room scenes with the real PlayerController and cast, then checks the mapping and rosters, a station for every
## scene action, navigation, collision, props resting, readable signs in player words, the doc 24 section 2.9 joins
## (CH01 -> CH02 .. CH02 -> CH03), the section 4 clue objects 4-9, the section 5.2 echoes D4 and D5, the running
## interlock inside the room, and that Chapter 1 and Chapter 6 keep their rooms.
##   Godot --headless --path game --script res://tools/test_chapter2_rooms.gd
##   --capture (windowed, production/qa/evidence/M3-2R_capture.sh) renders only the evidence views and frame timings
##   into production/qa/evidence/M3-2R_*.png and M3-2R_runtime.txt; the checks above stay in the headless run.
extends SceneTree

const Contract = preload("res://scripts/world/room_contract.gd")
const Presentation = preload("res://scripts/world/room_presentation.gd")
const Staging = preload("res://scripts/world/room_staging.gd")
const Gates = preload("res://scripts/missions/extended_gate_catalog.gd")
const Roster = preload("res://scripts/companions/companion_roster.gd")
const Crew = preload("res://scripts/world/campaign_crew.gd")
const Player = preload("res://scenes/player/player.tscn")
const SCENE_FILES := {"LOC-01": "commons", "LOC-02": "service_rooms", "LOC-03": "garden", "LOC-05": "airlock"}
const PLAYER_ANCHOR := {"LOC-01": "commons_player", "LOC-02": "service_player", "LOC-03": "garden_player", "LOC-05": "transfer_player"}
## STORY_FULL.md: Tara reference bay and Earth console, indoor botanical bench (garden); garden service corridor and
## transfer interlock, Tara bench / transfer route / Alo glove ports, paired care stations (LOC-05, P-03 in 08); paired
## observation bench (garden); Aurora mission table; recorder service bench, evidence board, playback station (LOC-02,
## P-04 in 08); Earth-link console and the brace zone beside the mission table (Commons).
const EXPECTED_ROOM := {
	"EX-CH02-S01": "LOC-03", "EX-CH02-S02": "LOC-03", "EX-CH02-S03": "LOC-05", "EX-CH02-S04": "LOC-05",
	"EX-CH02-S05": "LOC-05", "EX-CH02-S06": "LOC-03", "EX-CH02-S07": "LOC-01", "EX-CH02-S08": "LOC-02",
	"EX-CH02-S09": "LOC-02", "EX-CH02-S10": "LOC-02", "EX-CH02-S11": "LOC-01", "EX-CH02-S12": "LOC-01",
}
## Wall planes inside a room's footprint that carry wall-mounted staging (LOC-05: the vestibule face of the partition).
const INTERIOR_WALLS := {"LOC-05": [{"axis": "x", "at": -1.0}]}
const CANON_LINES := ["EX-CH02-S10-L01", "EX-CH02-S10-L03"]
## Stations where the crew stand by design: the marked brace zone holds all four in S12.
const SHARED_STATIONS := ["commons_brace_zone"]
## Test-only physics layer for the visible-surface copies the footprint check rays against (layer 16).
const FOOTPRINT_LAYER := 1 << 15
const PLANTS_IN_BLOOM := [{"individual_id": "ALO-01", "stage": "pollinated"}, {"individual_id": "TARA-01", "stage": "bloom"}]
## Window pane materials: the kit glass and the glove-port module's pressure glazing (M3-104).
const GLAZING := ["M_Kit_Glass", "M_Airlock_PressureGlass"]
var checks := 0
var failures := 0
var capture := false
var report: Array[String] = []
var _patterns: Array[RegEx] = []
var _started_usec := 0
var _drawn_frames := 0

func _init() -> void:
	# doc 25 section 8.1 player-text patterns (test_player_text.gd): no internal ids or engineering verbs on any sign.
	for source in ["EX-CH\\d", "\\bP-\\d\\d\\b", "\\b[EAWKSZCRH] ?\\d", "\\b(LOC|MSG|CS|SFX|CUE|J)-[A-Z0-9]{2}", "(?i)\\b(commit\\w*|stage[sd]?|acknowledg\\w*|role constraints?|operations?)\\b"]:
		var regex := RegEx.new()
		regex.compile(source)
		_patterns.append(regex)
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL ", message)

## A capture run prints each phase with its elapsed time, so a host watchdog log shows where a run stalled.
func _progress(step: String) -> void:
	if capture:
		print("M3-2R progress %.1f s: %s" % [(Time.get_ticks_usec() - _started_usec) / 1000000.0, step])

func _run() -> void:
	capture = OS.get_cmdline_user_args().has("--capture")
	_started_usec = Time.get_ticks_usec()
	root.size = Vector2i(1600, 900)
	if capture:
		root.always_on_top = true
		root.grab_focus()
		RenderingServer.frame_post_draw.connect(_count_draw)
		# The window is only needed for pictures and frame times; every check already runs headless in run_tests.sh,
		# so the windowed pass stays short on the shared two-slot gate.
		await _capture_all()
	else:
		await _check_all()
	var line := "CHAPTER 2 ROOMS %sRESULT: %s (%d checks, %d failures)" % ["CAPTURE " if capture else "", "PASS" if failures == 0 else "FAIL", checks, failures]
	print(line)
	report.append(line)
	if capture:
		var file := FileAccess.open("res://../production/qa/evidence/M3-2R_runtime.txt", FileAccess.WRITE)
		file.store_string("\n".join(report) + "\n")
	quit(0 if failures == 0 else 1)

func _check_all() -> void:
	_check_mapping()
	await _check_airlock_room()
	var player := Player.instantiate() as PlayerController
	player.character_glb = "res://assets/characters/CH_Kai/CH_Kai.glb"
	player.controlled = false
	(player.get_node("FollowCamera") as FollowCamera).capture_mouse = false
	root.add_child(player)
	player.set_physics_process(false)
	for scene_id in EXPECTED_ROOM:
		var room := await _room(String(EXPECTED_ROOM[scene_id]))
		room.set_scene_context(scene_id)
		for frame in 3:
			await physics_frame
		await _check_scene(room, scene_id, player)
		room.free()
		await process_frame
	player.free()
	await _check_join_into_chapter3()
	await _check_restaging()
	await _check_echoes()
	await _check_named_cup()
	await _check_crew()

## Builds a real room scene the way the campaign's loading card does (incremental prop binding).
func _room(room_id: String) -> CampaignRoom:
	var room := (load("res://scenes/campaign/rooms/%s.tscn" % SCENE_FILES[room_id]) as PackedScene).instantiate() as CampaignRoom
	room.load_approved_assets = false
	root.add_child(room)
	room.load_approved_assets = true
	await room.load_assets_incremental()
	if room_id == "LOC-03":
		room.apply_plant_state(PLANTS_IN_BLOOM)
	return room

# ------------------------------------------------------------------------------------------- mapping and rosters

func _check_mapping() -> void:
	# The campaign loader's LOC-05 entry is Atik's (LoadPreparation.ROOM_SCENES); this suite builds airlock.tscn itself.
	var airlock_scene := (load("res://scenes/campaign/rooms/airlock.tscn") as PackedScene).instantiate()
	_check(airlock_scene is CampaignRoom and String(airlock_scene.room_id) == "LOC-05" and airlock_scene.has_node("AirlockPreload"), "airlock.tscn is the LOC-05 room scene and carries its kit and airlock GLBs as dependencies")
	airlock_scene.free()
	for scene_id in EXPECTED_ROOM:
		var room_id := Contract.room_for_scene(scene_id)
		_check(room_id == EXPECTED_ROOM[scene_id], scene_id + " is staged in its STORY_FULL location " + String(EXPECTED_ROOM[scene_id]))
		_check(String(Gates.gate(scene_id).get("room_id", "")) == room_id, scene_id + " gate names the same room")
		var roster := Roster.scene_roster(scene_id)
		var active := Roster.playable_actor(scene_id)
		_check(String(roster[active].physical_location_id) == room_id, scene_id + " playable actor stands in the scene's room")
		for id in ["kai", "amara", "mei", "rafi"]:
			_check(String(roster[id].physical_location_id) == room_id, "%s %s is physically at %s" % [scene_id, id, room_id])
		_check(String(roster.ferreira.physical_location_id) == "EARTH_SCREEN", scene_id + " Ferreira is on the Earth screen only (before 12 Dec)")
		for target in Gates.targets_for_scene(scene_id):
			var station := Contract.station_focus(scene_id, String(target.target_id))
			_check(not station.is_empty(), scene_id + " action has a room station: " + String(target.target_id))
	_check(Contract.room_for_scene("EX-CH01-S12") == "LOC-03" and Contract.room_for_scene("EX-CH03-S01") == "LOC-02", "neighbouring chapters keep their rooms")
	_check(Contract.room("LOC-05").bounds_m == [8.0, 4.0], "LOC-05 is the canonical 8 x 4 m vestibule (doc 09), not the old 10 x 8 m greybox")

# ------------------------------------------------------------------------------------------- LOC-05 base room

## The airlock is a kit room like M1-06's: batched shell, real portal, the M3-2A interlock still running inside it.
func _check_airlock_room() -> void:
	var room := await _room("LOC-05")
	var layout := Contract.layout("LOC-05")
	# Reachability through the room contract: each LOC-05 boundary is shared with the room on its other side (the
	# Commons inner door, the surface hatch). RouteNavigation's door_commons_airlock rule is Atik's to add.
	var neighbours := {"door_commons_airlock": "LOC-01", "airlock_exterior": "LOC-06"}
	_check(Contract.room("LOC-05").boundary_ids == neighbours.keys(), "LOC-05 has exactly the inner door and the surface hatch")
	for boundary_id in neighbours:
		_check(Contract.room(neighbours[boundary_id]).boundary_ids.has(boundary_id), "LOC-05 reaches %s through %s" % [neighbours[boundary_id], boundary_id])
	var world := WorldRoute.new()
	var legacy := world.snapshot()
	legacy.boundaries.erase("door_commons_airlock")
	_check(bool(WorldRoute.new().restore(legacy).get("accepted", false)), "checkpoints made before the vestibule boundary still restore")
	_check(room.build_room().get("duplicate", false), "LOC-05 rebuild is idempotent")
	_check(room.visual_root.has_node("HabitatKit") and room.visual_root.get_node("HabitatKit").get_child_count() < 40, "LOC-05 floor and ceiling tiles are MultiMesh batches")
	var airlock := room.airlock()
	_check(airlock != null and airlock.has_method("request_cycle"), "LOC-05 carries the running M3-2A interlock")
	for role in layout.airlock_roles:
		_check(room.visual_root.has_node(String(role)), "airlock piece is a named room prop: " + String(role))
	_check(not airlock.nodes.has("inner_door") and room.door_root.has_node("Door_door_commons_airlock"), "the inner door is the room's portal (KitDoor mirrors WorldRoute)")
	_check(room.visual_root.has_node("Connector_door_commons_airlock"), "the inner door has its corridor connector")
	_check(airlock.state_text("inner") == "SAFE TO OPEN" and airlock.state_text("outer") == "SEALED", "the chamber starts at habitat pressure: inner SAFE TO OPEN, outer SEALED")
	_check(not bool(airlock.set_hatch("outer", true).accepted), "the outer hatch refuses while the chamber is at habitat pressure")
	_check(bool(airlock.request_cycle("surface").accepted) and airlock.state_text("inner") == "EQUALISING", "a cycle shows EQUALISING on both panels")
	airlock.advance(60.0)
	_check(airlock.state_text("outer") == "SAFE TO OPEN" and airlock.state_text("inner") == "SEALED", "after the cycle only the outer hatch reads SAFE TO OPEN")
	airlock.request_cycle("habitat")
	airlock.advance(60.0)
	_check(bool(airlock.set_lid("LidA", true).accepted) and not bool(airlock.set_lid("LidB", true).accepted), "the pass-through keeps one lid shut")
	airlock.set_lid("LidA", false)
	var lights := room.get_node("RoomLighting").get_children().filter(func(n): return n is OmniLight3D and String(n.name).begins_with("Practical_"))
	_check(lights.size() == 4 and lights.filter(func(n): return n.shadow_enabled).size() == 2, "LOC-05 has the kit rooms' four practicals, two with shadows")
	_check(not room.get_node("RoomLighting").get_children().any(func(n): return n is SpotLight3D), "the airlock's own six shadowed spotlights are not built (the room's practicals light it)")
	var chamber := room.get_node("RoomLighting/ChamberLight") as OmniLight3D
	_check(chamber != null and not chamber.shadow_enabled and chamber.omni_range < 1.75, "the cycled chamber's unshadowed light cannot reach past the partition")
	var door := room.door_root.get_node("Door_door_commons_airlock") as Node3D
	_check(absf(door.global_position.x - 4.0) < 0.01 and absf(door.global_position.z - 0.5) < 0.01, "the inner door sits where the turned airlock.json puts it (east wall)")
	room.free()
	await process_frame

# ------------------------------------------------------------------------------------------------ one scene

func _check_scene(room: CampaignRoom, scene_id: String, player: PlayerController) -> void:
	var room_id := room.room_id
	var layout := Contract.staged_layout(room_id, scene_id)
	var stage: Dictionary = room.stage()
	_check(not stage.get("layers", []).is_empty() and room.visual_root.has_node(Staging.ROOT_NAME), scene_id + " room carries its Chapter 2 staging")
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
	for target in layout.focus_targets:
		var approach := Presentation.vector(target.approach_m)
		var point := Presentation.vector(target.position)
		var path := NavigationServer3D.map_get_path(map, spawn, approach, true)
		_check(not path.is_empty() and path[path.size() - 1].distance_to(approach) < 0.4, scene_id + " reachable approach " + String(target.target_id))
		_check(_ray(approach + Vector3.UP * 1.4, point).is_empty(), scene_id + " interaction line of sight " + String(target.target_id))
	await _walk(room, player, layout, scene_id)
	for obstacle in stage.obstacles:
		var at := Presentation.vector(obstacle.position)
		var size := Presentation.vector(obstacle.size)
		_check(not _ray(at + Vector3(size.x * 0.5 + 0.15, 0, 0), at).is_empty(), scene_id + " staged furniture blocks movement: " + String(obstacle.id))
	_check_doors(room, map, spawn, scene_id)
	_check_anchors(room, map, scene_id)
	await _check_staged_objects(room, layout, scene_id)
	_check_staged_text(room, map, scene_id)
	_check_bridges(room, scene_id)

func _walk(room: CampaignRoom, player: PlayerController, layout: Dictionary, scene_id: String) -> void:
	player.position = Vector3(layout.walk_probe[0][0], 0.04, layout.walk_probe[0][1])
	player.velocity = Vector3.ZERO
	for point in layout.walk_probe:
		var goal := Vector3(point[0], 0, point[1])
		for step in 700:
			var delta := goal - player.position
			delta.y = 0
			if delta.length() < 0.09:
				break
			player.velocity = delta.normalized() * 3.0 + Vector3.DOWN
			player.move_and_slide()
			await physics_frame
		_check(Vector2(player.position.x - goal.x, player.position.z - goal.z).length() < 0.12, scene_id + " player walks unobstructed to " + str(goal))
	player.velocity = Vector3.ZERO

## Doc 09 clearances stay true with the staged furniture: a 1 m approach to every door is clear and reachable.
func _check_doors(room: CampaignRoom, map: RID, spawn: Vector3, scene_id: String) -> void:
	for node in room.door_root.get_children():
		if not node is CampaignDoor or String(node.boundary_id) == "garden_viewing_shutter":
			continue
		var inward: Vector3 = -node.global_basis.z
		inward.y = 0
		var approach: Vector3 = node.global_position + inward.normalized() * 1.0
		approach.y = 0
		var path := NavigationServer3D.map_get_path(map, spawn, approach, true)
		_check(not path.is_empty() and path[path.size() - 1].distance_to(approach) < 0.2, scene_id + " 1 m door approach stays clear: " + String(node.boundary_id))

## Everyone the roster puts in this room has a scene anchor on the deck, clear of furniture and of each other, and
## leaves the scene's stations free: crew bodies block the player (collision layer 2) and the interaction ray, so no
## one stands within 0.8 m of a station's approach or within 0.4 m of the line from that approach to the station.
func _check_anchors(room: CampaignRoom, map: RID, scene_id: String) -> void:
	var roster := Roster.scene_roster(scene_id)
	var active := Roster.playable_actor(scene_id)
	var layout := Contract.staged_layout(room.room_id, scene_id)
	var lanes: Array = []
	for target in Gates.targets_for_scene(scene_id):
		var station := Contract.station_focus(scene_id, String(target.target_id))
		for focus in layout.focus_targets:
			if String(focus.target_id) == station and station not in SHARED_STATIONS:
				var approach := Presentation.vector(focus.approach_m)
				var point := Presentation.vector(focus.position)
				lanes.append([station, Vector2(approach.x, approach.z), Vector2(point.x, point.z)])
	var placed: Array[Vector3] = []
	for id in roster:
		if String(roster[id].physical_location_id) != room.room_id or id == active:
			continue
		var at := Crew.anchor_position(room.room_id, id, scene_id)
		_check(Contract.staged_anchors(room.room_id, scene_id).keys().any(func(key): return String(key).ends_with("_" + id)), "%s %s has an authored anchor" % [scene_id, id])
		_check(NavigationServer3D.map_get_closest_point(map, at).distance_to(at) < 0.3, "%s %s stands on walkable deck %s" % [scene_id, id, str(at)])
		for other in placed:
			_check(at.distance_to(other) > 0.6, "%s %s keeps 0.6 m from the next person" % [scene_id, id])
		placed.append(at)
		var foot := Vector2(at.x, at.z)
		for lane in lanes:
			var line := Geometry2D.get_closest_point_to_segment(foot, lane[1], lane[2])
			_check(foot.distance_to(lane[1]) >= 0.8 and foot.distance_to(line) >= 0.4, "%s %s leaves the %s station and its sightline free" % [scene_id, id, lane[0]])

## Staged objects rest on the deck, a wall or another surface and stay inside the room, except inside a sealed
## enclosure the room data names (Alo's chamber behind the glove ports); plants are always inside an enclosure; every
## large floor-standing addition has collision over its footprint; and anything resting on furniture is carried by
## the geometry people see over its whole footprint (the round mission-table top, not its square bounds).
func _check_staged_objects(room: CampaignRoom, layout: Dictionary, scene_id: String) -> void:
	var staged := room.visual_root.get_node(Staging.ROOT_NAME) as Node3D
	var half := Vector2(float(layout.bounds_m[0]), float(layout.bounds_m[1])) * 0.5
	var enclosures: Array[AABB] = []
	for spec in layout.get("sealed_enclosures", []):
		enclosures.append(AABB(Presentation.vector(spec.min), Presentation.vector(spec.max) - Presentation.vector(spec.min)))
	var surfaces: Array[AABB] = []
	var resting: Array[Node3D] = []
	for node in room.visual_root.get_children() + staged.get_children():
		if node is Node3D and node.visible and node != staged and String(node.name) not in ["HabitatKit", "Airlock"]:
			var box := _bounds(room, node)
			if box.size != Vector3.ZERO:
				surfaces.append(box)
	for node in staged.get_children():
		if not node is Node3D or node is Label3D:
			continue
		var box := _bounds(room, node)
		if box.size == Vector3.ZERO:
			continue
		var id := String(node.name)
		var enclosed := enclosures.any(func(e): return e.grow(0.02).encloses(box))
		if id.begins_with("PL_"):
			_check(enclosed or (room.room_id == "LOC-03"), scene_id + " a staged plant stays inside a sealed enclosure: " + id)
		_check(enclosed or (box.position.x >= -half.x - 0.02 and box.end.x <= half.x + 0.02 and box.position.z >= -half.y - 0.02 and box.end.z <= half.y + 0.02), scene_id + " staged object inside the room footprint: " + id)
		var base := box.position.y
		var supported := absf(base) < 0.03 or enclosed
		var wall := absf(box.end.z - half.y) < 0.12 or absf(box.position.z + half.y) < 0.12 or absf(box.end.x - half.x) < 0.12 or absf(box.position.x + half.x) < 0.12
		for plane in INTERIOR_WALLS.get(room.room_id, []):
			wall = wall or (plane.axis == "x" and (absf(box.end.x - float(plane.at)) < 0.12 or absf(box.position.x - float(plane.at)) < 0.12))
		var centre := box.get_center()
		for surface in surfaces:
			if surface == box:
				continue
			# mounted on the face of a board, panel or device (a card on the lineage board, a sticker on the recorder)
			var on_z := (absf(box.position.z - surface.end.z) < 0.02 or absf(box.end.z - surface.position.z) < 0.02) and centre.x >= surface.position.x and centre.x <= surface.end.x
			var on_x := (absf(box.position.x - surface.end.x) < 0.02 or absf(box.end.x - surface.position.x) < 0.02) and centre.z >= surface.position.z and centre.z <= surface.end.z
			if (on_z or on_x) and centre.y >= surface.position.y and centre.y <= surface.end.y:
				wall = true
			if surface.end.y > base + 0.03 or surface.end.y < base - 0.04:
				continue
			if centre.x >= surface.position.x and centre.x <= surface.end.x and centre.z >= surface.position.z and centre.z <= surface.end.z:
				supported = true
		_check((supported or wall) and base > -0.03, scene_id + " staged object rests on the deck, a wall or a surface (base %.3f m): %s" % [base, id])
		if supported and not wall and not enclosed and absf(base) >= 0.03:
			resting.append(node)
		if absf(base) < 0.03 and box.size.y >= 0.5:
			var covered := true
			for u in 5:
				for v in 5:
					var point := Vector3(lerpf(box.position.x + 0.1, box.end.x - 0.1, u / 4.0), 0.3, lerpf(box.position.z + 0.1, box.end.z - 0.1, v / 4.0))
					var inside := false
					for obstacle in layout.obstacles:
						var area := AABB(Presentation.vector(obstacle.position) - Presentation.vector(obstacle.size) * 0.5, Presentation.vector(obstacle.size))
						inside = inside or (point.x >= area.position.x and point.x <= area.end.x and point.z >= area.position.z and point.z <= area.end.z)
					covered = covered and inside
			_check(covered, scene_id + " large staged object has collision over its footprint: " + id)
	await _check_footprints(room, staged, resting, scene_id)

## Each object resting on furniture has the visible surface under its whole footprint: nine points 1.5 cm in from
## its edges (10 % for small items) each find a visible face within 5 cm above to 4 cm below its base. Rays run against trimesh copies of
## the room's visible meshes on a test-only physics layer, never against the coarse collision boxes.
func _check_footprints(room: CampaignRoom, staged: Node3D, resting: Array[Node3D], scene_id: String) -> void:
	if resting.is_empty():
		return
	var holder := Node3D.new()
	room.add_child(holder)
	var owners := {}
	for node in room.visual_root.get_children() + staged.get_children():
		if not node is Node3D or node == staged or String(node.name) in ["HabitatKit", "Airlock"]:
			continue
		var meshes := (node as Node).find_children("*", "MeshInstance3D", true, false)
		if node is MeshInstance3D:
			meshes.append(node)
		for mesh in meshes:
			var instance := mesh as MeshInstance3D
			if instance.mesh == null or instance.visibility_range_begin > 0.0 or not instance.is_visible_in_tree() or instance.get_viewport() != room.get_viewport():
				continue
			var body := StaticBody3D.new()
			body.collision_layer = FOOTPRINT_LAYER
			body.collision_mask = 0
			var shape := CollisionShape3D.new()
			shape.shape = instance.mesh.create_trimesh_shape()
			body.add_child(shape)
			holder.add_child(body)
			body.global_transform = instance.global_transform
			if not owners.has(node):
				var rids: Array[RID] = []
				owners[node] = rids
			(owners[node] as Array).append(body.get_rid())
	await physics_frame
	var space := root.get_world_3d().direct_space_state
	for node in resting:
		var box := _bounds(room, node)
		var inset := Vector2(minf(box.size.x * 0.1, 0.015), minf(box.size.z * 0.1, 0.015))
		var missed: Array[String] = []
		for u in 3:
			for v in 3:
				var at := room.global_transform * Vector3(lerpf(box.position.x + inset.x, box.end.x - inset.x, u / 2.0), box.position.y, lerpf(box.position.z + inset.y, box.end.z - inset.y, v / 2.0))
				# a point counts when any ray within 1 cm finds a face, so a seam between two imported faces is no gap
				var found := false
				for offset in [Vector3.ZERO, Vector3(0.01, 0, 0), Vector3(-0.01, 0, 0), Vector3(0, 0, 0.01), Vector3(0, 0, -0.01)]:
					var query := PhysicsRayQueryParameters3D.create(at + offset + Vector3.UP * 0.05, at + offset + Vector3.DOWN * 0.04, FOOTPRINT_LAYER)
					if owners.has(node):
						query.exclude = owners[node]
					found = found or not space.intersect_ray(query).is_empty()
				if not found:
					missed.append("(%.2f, %.2f)" % [at.x, at.z])
		_check(missed.is_empty(), scene_id + " the furniture under it carries its whole footprint: %s (unsupported at %s)" % [node.name, ", ".join(missed)])
	holder.free()

## Every staged label faces walkable deck within a 50-degree cone and 2.2 m (wall boards are read at an angle in a
## small room), signs are single-sided and never mirrored, templates are filled, and staged words stay in player
## language (the canon 2034 lines quoted from the catalog are exempt).
func _check_staged_text(room: CampaignRoom, map: RID, scene_id: String) -> void:
	var staged := room.visual_root.get_node(Staging.ROOT_NAME) as Node3D
	for label in staged.find_children("*", "Label3D", true, false):
		if not label.is_visible_in_tree() or label.billboard != BaseMaterial3D.BILLBOARD_DISABLED or String(label.text).strip_edges().is_empty():
			continue
		var words := String(label.text)
		for line_id in CANON_LINES:
			words = words.replace(Staging.line_text(line_id), "")
		for regex in _patterns:
			_check(regex.search(words) == null, scene_id + " staged words stay in player language: " + String(label.text).left(40))
		var facing: Vector3 = label.global_basis.z
		if absf(facing.y) > 0.7:
			continue  # a page lying on a table reads from above
		facing.y = 0
		facing = facing.normalized()
		var at: Vector3 = label.global_position
		at.y = 0
		var front := 99.0
		for angle in [0.0, -25.0, 25.0, -50.0, 50.0]:
			var direction := Basis(Vector3.UP, deg_to_rad(angle)) * facing
			for reach in [0.8, 1.2, 1.6, 2.2]:
				var probe: Vector3 = at + direction * reach
				front = minf(front, NavigationServer3D.map_get_closest_point(map, probe).distance_to(probe))
		_check(front < 0.35, scene_id + " staged label reads from walkable deck: " + String(label.text).left(40))
		if label.get_parent() == staged:
			_check(not label.double_sided, scene_id + " staged sign is single-sided: " + String(label.text).left(40))
	for node in staged.get_children():
		if node is Label3D:
			_check(not String(node.text).contains("{line}"), scene_id + " sign template is filled: " + String(node.name))

# ------------------------------------------------------------------------------------------------- the joins

func _text(staged: Node, id: String) -> String:
	var label := staged.get_node_or_null(id) as Label3D
	return label.text if label != null else ""

## Doc 24 section 2.9 rows CH01 -> CH02 .. CH02 S11 -> S12 and section 4 clues 4-9, scene by scene.
func _check_bridges(room: CampaignRoom, scene_id: String) -> void:
	var staged := room.visual_root.get_node(Staging.ROOT_NAME) as Node3D
	var order := Contract.scene_order(scene_id) % 100
	match room.room_id:
		"LOC-03":
			_check(not room.fixture("earth_screen").is_empty() and staged.has_node("earth_screen"), scene_id + " the garden's Earth console is installed (CH01 -> CH02: it lights as Tara opens)")
			_check(_text(staged, "earth_console_title").contains("CONTACT RETURNED 30 APR") == (order == 1), scene_id + " the console reads 'contact returned 30 Apr' on the day it returns")
			_check((room.visual_root.get_node("PL_Tara_Bloom") as Node3D).visible, scene_id + " Tara is in flower in her bay")
			var alo := _bounds(room, staged.get_node("growth_photo_alo"))
			var tara := _bounds(room, staged.get_node("growth_photo_tara"))
			_check(alo.size.is_equal_approx(tara.size) and absf(alo.get_center().y - tara.get_center().y) < 0.001, scene_id + " Tara's photograph hangs beside Alo's at equal size (S01 -> S02)")
			_check(_text(staged, "alo_id_text").contains("PURPLE") and _text(staged, "tara_id_text").contains("GREEN") and _text(staged, "tara_id_text").contains("30 APR 2046"), scene_id + " both identity cards: same variety, stem colours, Tara's first flower 30 Apr (clue S01-1)")
			_check(staged.has_node("protocol_sheet") and _text(staged, "protocol_text").contains("BRUSH A: TARA TO ALO"), scene_id + " the protocol Mei opened lies on the bench")
			_check(staged.has_node("PR_PaperBee") == (order >= 2 and order <= 6), scene_id + " the paper bee sits beside the protocol from S02 until it goes to the table (S02 -> S03, S06 -> S07)")
			_check(staged.has_node("practice_flower_model") == (order >= 2) and staged.has_node("magnified_flower") == (order >= 2), scene_id + " magnified images and the nonliving practice model are on the bench from S02")
			if order >= 2:
				var model := staged.get_node("practice_flower_model")
				_check(model.find_children("Anther*", "MeshInstance3D", true, false).size() == 6 and model.find_children("Petal*", "MeshInstance3D", true, false).size() == 4, scene_id + " the practice model has the mustard flower's four petals and six stamens")
			var stamps := staged.find_children("care_bee_*", "Node3D", false, false)
			_check(stamps.size() == (3 if order >= 6 else 0), scene_id + " the seven-date strip with three bee runs hangs under the photographs once the seventh date is logged (S05 -> S06)")
			if order >= 6:
				_check(stamps.filter(func(s): return absf((s as Node3D).rotation_degrees.z) > 5.0).size() == 1, scene_id + " exactly one bee stamp is slightly crooked")
				_check(staged.has_node("prediction_thread") and staged.has_node("family_tree_page"), scene_id + " the prediction is threaded to the family-tree page (S06 -> S07)")
			_check(staged.has_node("PR_SeedTray") == (order == 6), scene_id + " Kai brings the clean seed tray in S06")
		"LOC-05":
			var airlock := room.airlock()
			_check(staged.has_node("PL_Alo_Bloom") and staged.has_node("PR_PollinationKit"), scene_id + " Alo flowers behind the glove ports; brushes A and B wait in the carrier")
			_check(_alo_in_window(room, staged, Contract.staged_layout(room.room_id, scene_id)), scene_id + " Alo's flowers show through the glove-port window from the station (glass only: the window opens through the module as built)")
			_check(not airlock.is_lid_open("LidA") and not airlock.is_lid_open("LidB") and airlock.state_text("inner") == "SAFE TO OPEN", scene_id + " both pass-through lids shut, pressure unchanged (S03 -> S04)")
			_check(_text(staged, "carrier_latch_word") == "CARRIER LATCHED", scene_id + " the carrier latch shows a word as well as a lamp (S02 -> S03, Kai's latch)")
			_check(_text(staged, "space_weather_text").begins_with("SPACE WEATHER") and _text(staged, "space_weather_text").contains("CHECK BEFORE EACH RUN"), scene_id + " space weather is checked before each run (clue 7, S05 Rafi)")
			_check(staged.has_node("kai_sketch_line") and staged.has_node("route_tick_4"), scene_id + " Kai's straight line hangs beside the real route with its four sealed boundaries (clue 6)")
			_check(staged.has_node("contact_image") == (order == 5) and _text(staged, "route_record_text").contains("DONE") == (order == 5), scene_id + " the saved contact image and run 1 are on the record in S05 (S04 -> S05)")
			var shown := staged.find_children("route_bee_*", "Node3D", false, false)
			_check(shown.size() == (1 if order == 5 else 0), scene_id + " only the completed 30 Apr run carries a bee stamp at the start of S05")
		"LOC-01":
			_check(staged.has_node("brace_edge_n") and staged.has_node("brace_zone_word"), scene_id + " the marked interior brace zone is beside the mission table")
			if order == 7:
				var recorder := _bounds(room, staged.get_node("PR_Recorder2034"))
				var bee := _bounds(room, staged.get_node("PR_PaperBee"))
				_check(recorder.grow(0.08).intersects(bee), scene_id + " the paper bee's wing is at the horticulture recorder (clue 4)")
				_check(_text(staged, "recorder_sticker_text").contains("HORT-01") and _text(staged, "lifecycle_old_trial/Caption").contains("HORT-01"), scene_id + " recorder and old trial card share the equipment number HORT-01 (S07 -> S08)")
				_check(_text(staged, "lifecycle_reference/Caption").contains("REFERENCE") and _text(staged, "lifecycle_old_trial/Caption").contains("NO FLOWERS"), scene_id + " the life-cycle cards mark reference and old-trial evidence honestly")
				var tray := _bounds(room, staged.get_node("PR_SeedTray"))
				var strip := _bounds(room, staged.get_node("care_strip"))
				_check(tray.grow(0.1).intersects(strip), scene_id + " Kai's clean seed tray lies beside the care strip (S06 -> S07)")
			else:
				_check(not staged.has_node("PR_Recorder2034"), scene_id + " the recorder has gone to the service bench")
			if order >= 11:
				var cup := _bounds(room, staged.get_node("reply_cup"))
				var lamp := _bounds(room, staged.get_node("reply_indicator_lamp"))
				_check(cup.get_center().distance_to(lamp.get_center()) < 0.3 and not (room.visual_root.get_node("PR_Mug") as Node3D).visible, scene_id + " the cup stands beside the pending-reply indicator (S11 -> S12)")
				_check(_text(staged, "package_receipt").contains("DELIVERED") and _text(staged, "package_reply").contains("PENDING"), scene_id + " the receipt column stands apart from the reply column (clue 9)")
				_check(_text(staged, "atmosphere_row_tank").contains("TANK PRESSURE · WARNING") == (order == 12), scene_id + " one atmosphere indicator turns red only after the quake")
				_check(staged.get_node("reply_cup").has_meta("rattle") == (order == 12), scene_id + " the cup trembles at the start of S12")
			_check(staged.has_node("service_cover") == (order == 12) and staged.has_node("brace_token_kai") == (order == 12), scene_id + " the displaced service cover and the four name tokens appear in S12")
		"LOC-02":
			_check(staged.has_node("PR_Recorder2034") and staged.has_node("recorder_new_sticker") and staged.has_node("recorder_old_plate"), scene_id + " the recorder on its service bench, the newer sticker over the older plate (clue 5)")
			_check(staged.has_node("card_serial") and staged.has_node("card_date") and staged.has_node("card_trial") and staged.has_node("card_person_empty"), scene_id + " three source cards and the clean empty space where a person might belong (S08 -> S09)")
			_check(_text(staged, "card_trial_text").contains("FLOWERING NOT REACHED"), scene_id + " the old chart says flowering was not reached (Alo's bloom is still a first)")
			_check(staged.has_node("files_card") == (order >= 9), scene_id + " the three recorder files are on the board from S09")
			if order == 9:
				_check(_text(staged, "files_text").contains("DATE: ?") and _text(staged, "playback_text").contains("LOCKED"), scene_id + " playback stays locked until the mapping holds (S09 -> S10)")
			if order >= 10:
				_check(_text(staged, "files_text").contains("2034-04") and _text(staged, "files_text").contains("HORT-01") and _text(staged, "files_text").contains("ENGINEERING"), scene_id + " the files carry 08's three tokens")
				_check(_text(staged, "playback_engineer").contains(Staging.line_text("EX-CH02-S10-L01")) and _text(staged, "playback_n").contains(Staging.line_text("EX-CH02-S10-L03")), scene_id + " both 2034 transcripts word for word (clues 7, 8)")
				_check(_text(staged, "playback_header").contains("2034-04"), scene_id + " the date stays visible above both transcripts")

## The line from a 1.6 m eye at the glove-port station to the top of Alo's flowers crosses the module's window
## glass and no other face of the module, as the GLB is built: the window opens through to the far face (M3-104; M3-2A's
## kit window frame had a closed back plate behind the glass).
func _alo_in_window(room: CampaignRoom, staged: Node3D, layout: Dictionary) -> bool:
	var eye := Vector3.ZERO
	for focus in layout.focus_targets:
		if String(focus.target_id) == "transfer_glove_ports":
			eye = Presentation.vector(focus.approach_m) + Vector3.UP * 1.6
	var alo := _bounds(room, staged.get_node("PL_Alo_Bloom"))
	var flowers := Vector3(alo.get_center().x, alo.end.y - 0.04, alo.get_center().z)
	var through_glass := false
	for mesh in room.visual_root.get_node("glove_ports").find_children("*", "MeshInstance3D", true, false):
		var instance := mesh as MeshInstance3D
		if instance.visibility_range_begin > 0.0:
			continue
		var to_local := instance.global_transform.affine_inverse() * room.global_transform
		var from := to_local * eye
		var to := to_local * flowers
		for surface in instance.mesh.get_surface_count():
			var material := instance.get_active_material(surface)
			var glass: bool = material != null and material.resource_name in GLAZING
			var faces: PackedVector3Array = instance.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = instance.mesh.surface_get_arrays(surface)[Mesh.ARRAY_INDEX]
			for t in indices.size() / 3:
				if Geometry3D.segment_intersects_triangle(from, to, faces[indices[t * 3]], faces[indices[t * 3 + 1]], faces[indices[t * 3 + 2]]) != null:
					if not glass:
						return false
					through_glass = true
	return through_glass

## CH02 -> CH03: no time jump; the same red pressure warning on the air console at 22:05.
func _check_join_into_chapter3() -> void:
	var room := await _room("LOC-02")
	room.set_scene_context("EX-CH03-S01")
	await process_frame
	var staged := room.visual_root.get_node(Staging.ROOT_NAME)
	_check(_text(staged, "air_warning_row_tank").contains("TANK PRESSURE · WARNING"), "CH03-S01 opens on the same red pressure warning (CH02 -> CH03)")
	# The same warning, not a look-alike: the air console repeats the Commons panel's rows, and both tank symbols are red.
	var commons := _display(Contract.staged_layout("LOC-01", "EX-CH02-S12"), "atmosphere_")
	var console := _display(Contract.staged_layout("LOC-02", "EX-CH03-S01"), "air_warning_")
	_check(commons.rows == console.rows and commons.rows.size() == 4, "CH03-S01's screen shows the S12 panel's rows word for word")
	_check(commons.tank == "#e8352a" and console.tank == "#e8352a", "the oxygen-tank symbol is red on both displays")
	_check(_display(Contract.staged_layout("LOC-01", "EX-CH02-S11"), "atmosphere_").tank != "#e8352a", "the tank symbol is not red before the quake")
	_check(staged.has_node("evidence_board") and staged.has_node("PR_Recorder2034"), "the evidence board and recorder are still there the same night")
	room.set_scene_context("EX-CH03-S06")
	await process_frame
	_check(not room.visual_root.has_node(Staging.ROOT_NAME) or not room.visual_root.get_node(Staging.ROOT_NAME).has_node("evidence_board"), "the board leaves after the same night")
	room.free()
	await process_frame

## One atmosphere display in staged data: its title and row words, and the tank symbol's colour.
func _display(layout: Dictionary, prefix: String) -> Dictionary:
	var rows: Array = []
	for sign in layout.signs:
		if String(sign.get("id", "")).begins_with(prefix + "row_") or String(sign.get("id", "")) == prefix + "title":
			rows.append(String(sign.text))
	var tank := ""
	for fixture in layout.fixtures:
		if String(fixture.id) == prefix + "tank_symbol":
			tank = String(fixture.color)
	return {"rows": rows, "tank": tank}

# ---------------------------------------------------------------------------------------- re-staging, echoes

## One room instance re-staged scene after scene ends exactly as built: Chapter 1 has no staging and its own
## navigation and stations, and Chapter 6 keeps the garden's Earth console but none of Chapter 2's bench.
func _check_restaging() -> void:
	var garden := await _room("LOC-03")
	var base_polys := (garden.navigation_root.get_node("NavigationRegion") as NavigationRegion3D).navigation_mesh.get_polygon_count()
	var base_focus := garden.focus_root.get_child_count()
	for scene_id in ["EX-CH02-S02", "EX-CH02-S06", "EX-CH01-S12", "EX-CH02-S01", "EX-CH06-S12"]:
		garden.set_scene_context(scene_id)
		await process_frame
		var region := garden.navigation_root.get_node("NavigationRegion") as NavigationRegion3D
		_check(garden.navigation_root.get_child_count() == 1, scene_id + " re-staging keeps one navigation map")
		if scene_id == "EX-CH01-S12":
			_check(garden.stage().layers.is_empty() and not garden.visual_root.has_node(Staging.ROOT_NAME), "Chapter 1 shows no Chapter 2 staging after re-staging")
			_check(region.navigation_mesh.get_polygon_count() == base_polys and garden.focus_root.get_child_count() == base_focus, "Chapter 1 navigation and stations return exactly")
			_check(garden.fixture("earth_screen").is_empty(), "the Chapter 1 garden has no Earth console")
		if scene_id == "EX-CH06-S12":
			var staged := garden.visual_root.get_node(Staging.ROOT_NAME)
			_check(staged.has_node("earth_screen") and not staged.has_node("botanical_bench") and not staged.has_node("prediction_card"), "Chapter 6 keeps the Earth console, not the Chapter 2 bench or the prediction")
	garden.free()
	await process_frame
	var airlock := await _room("LOC-05")
	for scene_id in ["EX-CH02-S03", "EX-CH02-S05", "EX-CH02-S04", "EX-CH04-S01"]:
		airlock.set_scene_context(scene_id)
		await process_frame
	_check(not airlock.visual_root.has_node(Staging.ROOT_NAME) and airlock.navigation_root.get_child_count() == 1, "the airlock outside Chapter 2 is the plain M3-2A vestibule")
	airlock.free()
	await process_frame

## Doc 24 section 5.2: D4 shows the player's own prediction (catalog words) and D5 how the voice was first filed.
func _check_echoes() -> void:
	var garden := await _room("LOC-03")
	garden.set_scene_context("EX-CH02-S06")
	await process_frame
	var staged := garden.visual_root.get_node(Staging.ROOT_NAME)
	_check(not staged.has_node("prediction_choice"), "no prediction sentence before the choice is recorded")
	garden.set_story_choices({"EX-CH02-S06-CHOICE": {"option_id": "EX-CH02-S06-OPT02"}})
	await process_frame
	staged = garden.visual_root.get_node(Staging.ROOT_NAME)
	_check(_text(staged, "prediction_choice").contains("Available evidence is insufficient to choose a pattern"), "D4 OPT02: the uncertainty is the recorded prediction, in the catalog's words")
	garden.set_story_choices({"EX-CH02-S06-CHOICE": {"option_id": "EX-CH02-S06-OPT01"}})
	await process_frame
	staged = garden.visual_root.get_node(Staging.ROOT_NAME)
	_check(_text(staged, "prediction_choice").contains("Both visible colours may appear"), "D4 OPT01: 'Both visible colours may appear'")
	garden.set_scene_context("EX-CH04-S01")
	await process_frame
	staged = garden.visual_root.get_node(Staging.ROOT_NAME)
	_check(staged != null and staged.has_node("prediction_choice"), "the prediction is still pinned for the October count (CH04-S01)")
	garden.free()
	await process_frame
	var service := await _room("LOC-02")
	service.set_scene_context("EX-CH02-S10")
	await process_frame
	staged = service.visual_root.get_node(Staging.ROOT_NAME)
	_check(not staged.has_node("card_voice"), "no voice card before the classification is recorded")
	service.set_story_choices({"EX-CH02-S10-CHOICE": {"option_id": "EX-CH02-S10-OPT02"}})
	await process_frame
	staged = service.visual_root.get_node(Staging.ROOT_NAME)
	_check(_text(staged, "card_voice_text").contains("KEPT AS AN INFERENCE · 6 MAY 2046"), "D5 OPT02: kept as an inference since 6 May")
	service.set_story_choices({"EX-CH02-S10-CHOICE": {"option_id": "EX-CH02-S10-OPT01"}})
	await process_frame
	staged = service.visual_root.get_node(Staging.ROOT_NAME)
	_check(_text(staged, "card_voice_text").contains("CORRECTED TO AN INFERENCE · 6 MAY 2046"), "D5 OPT01: corrected to an inference on 6 May")
	_check(staged.get_node("card_voice").global_position.x > 0.72 and staged.get_node("card_voice").global_position.x < 1.28, "the voice card is in the Inferred column")
	service.free()
	await process_frame

## M1-84's named mugs (CH01-MUGS-NAMED) and the S11 cup: the cup by the pending-reply indicator is one of the table's
## own mugs, so with or without the moment exactly one mug stands there and no two mugs share a spot; it rattles in S12.
func _check_named_cup() -> void:
	for moments in [[], ["CH01-MUGS-NAMED"]]:
		var named: bool = not moments.is_empty()
		for scene_id in ["EX-CH02-S11", "EX-CH02-S12"]:
			var layout := Contract.staged_layout("LOC-01", scene_id, {}, moments)
			var lamp := Vector3.ZERO
			for fixture in layout.fixtures:
				if String(fixture.id) == "reply_indicator_lamp":
					lamp = Presentation.vector(fixture.position)
			var mugs: Array = layout.props.filter(func(p): return String(p.get("path", "")).get_file().begins_with("PR_Mug"))
			var at_lamp: Array = mugs.filter(func(p): return Presentation.vector(p.position).distance_to(lamp) < 0.3)
			_check(mugs.size() == 4 and at_lamp.size() == 1, "%s %s mugs: four on the table, one by the pending-reply indicator" % [scene_id, "named" if named else "nameless"])
			for i in mugs.size():
				for j in range(i + 1, mugs.size()):
					_check(Presentation.vector(mugs[i].position).distance_to(Presentation.vector(mugs[j].position)) > 0.1, "%s %s and %s do not share a spot" % [scene_id, mugs[i].id, mugs[j].id])
			if at_lamp.size() == 1:
				_check(String(at_lamp[0].id) == ("commons_mug_amara" if named else "reply_cup"), scene_id + " the cup is " + ("Amara's named mug" if named else "the nameless table mug"))
				_check(at_lamp[0].has("rattle") == (scene_id == "EX-CH02-S12"), scene_id + " the cup rattles only at the start of S12")
	var commons := await _room("LOC-01")
	commons.set_story_choices({}, ["CH01-MUGS-NAMED"])
	commons.set_scene_context("EX-CH02-S12")
	await process_frame
	var staged := commons.visual_root.get_node(Staging.ROOT_NAME)
	_check(staged.has_node("commons_mug_amara") and staged.get_node("commons_mug_amara").has_meta("rattle") and not staged.has_node("reply_cup"), "S12 with named mugs: Amara's mug trembles, no second cup")
	commons.free()
	await process_frame

## The real cast placement: the room is staged before anyone stands in it, bodies stand at the scene anchors, the
## garden's Earth console shows Ferreira's delayed praise in S01, and the four stand on their tokens in S12.
func _check_crew() -> void:
	var crew := Crew.new()
	root.add_child(crew)
	for scene_id in ["EX-CH02-S01", "EX-CH02-S04", "EX-CH02-S10", "EX-CH02-S12"]:
		var room := await _room(Contract.room_for_scene(scene_id))
		var anchors := Contract.anchors(room.room_id)
		var start: Array = anchors[PLAYER_ANCHOR[room.room_id]]
		var player := crew.place(scene_id, room, Vector3(start[0], start[1], start[2]))
		for frame in 4:
			await physics_frame
		_check(room.scene_context() == scene_id and not room.stage().layers.is_empty(), scene_id + " the room is staged by the crew placement")
		for id in crew.local_ids:
			var body: PlayerController = crew.bodies[id]
			if body == player:
				continue
			var at := Crew.anchor_position(room.room_id, id, scene_id)
			_check(Vector2(body.position.x - at.x, body.position.z - at.z).length() < 0.15, "%s %s placed at the scene anchor" % [scene_id, id])
		if scene_id == "EX-CH02-S01":
			crew.present_line({"speaker_id": "ferreira", "origin_label": "EARTH LINK", "text": Staging.line_text("EX-CH02-S01-L01")}, false)
			var portrait := room.get_node_or_null("EarthPortrait") as Sprite3D
			_check(portrait != null and portrait.visible and portrait.texture != null, "S01 Ferreira's praise arrives on the garden's Earth console")
			if portrait != null:
				_check(portrait.global_basis.z.dot(Vector3.RIGHT) > 0.99 and absf(portrait.global_position.x + 5.92) < 0.03, "the portrait faces the room from the west-wall console")
		if scene_id == "EX-CH02-S12":
			var staged := room.visual_root.get_node(Staging.ROOT_NAME)
			for id in crew.local_ids:
				if crew.bodies[id] == player:
					continue
				var token := staged.get_node("brace_token_" + id) as Node3D
				_check(Vector2(crew.bodies[id].position.x - token.position.x, crew.bodies[id].position.z - token.position.z + 0.32).length() < 0.2, "S12 %s stands at their name token in the brace zone" % id)
		room.free()
		await process_frame
	crew.free()
	await process_frame

# ----------------------------------------------------------------------------------------------- capture

const SHOTS := [
	["EX-CH02-S01", "ch02_earth_console", "S01_earth_console_tara"],
	["EX-CH02-S01", "ch02_growth_record", "S01_paired_identity_cards"],
	["EX-CH02-S01", "player", "S01_player", 1.9],
	["EX-CH02-S02", "ch02_bench", "S02_botanical_bench"],
	["EX-CH02-S02", "flower_close", "S02_practice_model_close"],
	["EX-CH02-S03", "overview", "S03_airlock_vestibule"],
	["EX-CH02-S03", "ch02_route_wall", "S03_route_and_kai_line"],
	["EX-CH02-S03", "player", "S03_player", 2.6],
	["EX-CH02-S04", "ch02_glove_ports", "S04_alo_glove_ports"],
	["EX-CH02-S04", "ch02_bench", "S04_carrier_microscope"],
	["EX-CH02-S05", "ch02_care_record", "S05_care_and_route_record"],
	["EX-CH02-S06", "ch02_growth_record", "S06_seven_dates_prediction"],
	["EX-CH02-S06", "ch02_bench", "S06_seed_tray_bench"],
	["EX-CH02-S07", "ch02_table", "S07_mission_table"],
	["EX-CH02-S07", "recorder_close", "S07_bee_and_recorder"],
	["EX-CH02-S08", "ch02_recorder_bench", "S08_recorder_bench"],
	["EX-CH02-S08", "ch02_evidence_board", "S08_evidence_board"],
	["EX-CH02-S09", "ch02_evidence_board", "S09_reconstruction"],
	["EX-CH02-S10", "ch02_playback", "S10_playback_transcripts"],
	["EX-CH02-S10", "ch02_evidence_board", "S10_inference_board"],
	["EX-CH02-S11", "ch02_package", "S11_evidence_package"],
	["EX-CH02-S11", "ch02_cup", "S11_cup_reply_pending"],
	["EX-CH02-S12", "ch02_brace_zone", "S12_brace_zone"],
	["EX-CH02-S12", "ch02_atmosphere", "S12_red_warning"],
	["EX-CH03-S01", "warning_close", "CH03_S01_same_warning"],
]
## Close-ups that are evidence only (the room JSONs keep the shared review views).
const CLOSE := {
	"flower_close": {"from": [-2.0, 1.25, 2.95], "to": [-2.15, 0.98, 3.55]},
	"recorder_close": {"from": [-0.45, 1.12, 1.15], "to": [0.0, 0.93, 0.28]},
	"warning_close": {"from": [1.4, 1.65, -0.1], "to": [1.4, 2.04, -1.6]},
}

func _capture_all() -> void:
	var crew := Crew.new()
	root.add_child(crew)
	var camera := Camera3D.new()
	camera.fov = 70
	root.add_child(camera)
	var room: CampaignRoom = null
	var current := ""
	var choices := {"EX-CH02-S06-CHOICE": {"option_id": "EX-CH02-S06-OPT01"}, "EX-CH02-S10-CHOICE": {"option_id": "EX-CH02-S10-OPT02"}}
	for shot in SHOTS:
		var scene_id := String(shot[0])
		if scene_id != current:
			if room != null:
				room.free()
				await process_frame
			_progress("staging " + scene_id)
			room = await _room(Contract.room_for_scene(scene_id))
			var start: Array = Contract.anchors(room.room_id)[PLAYER_ANCHOR[room.room_id]]
			crew.place(scene_id, room, Vector3(start[0], start[1], start[2]), choices)
			current = scene_id
			for frame in 30:
				await process_frame
			if scene_id == "EX-CH02-S01":
				crew.present_line({"speaker_id": "ferreira", "origin_label": "EARTH LINK"}, false)
		var view := String(shot[1])
		if view == "player":
			var player := crew.player
			player.follow_camera.yaw = float(shot[3])
			player.follow_camera.pitch = -0.1
			player.follow_camera.reset_placement()
			player.follow_camera.camera.current = true
			for frame in 30:
				player.follow_camera.update_camera(1.0 / 60.0, player.follow_camera.yaw, 0)
				await process_frame
		else:
			var spec: Dictionary = CLOSE.get(view, Contract.staged_layout(room.room_id, scene_id, choices).review_views.get(view, {}))
			camera.position = Presentation.vector(spec.from)
			camera.look_at(Presentation.vector(spec.to))
			camera.current = true
			for frame in 20:
				await process_frame
		await _draw_frame()
		await _save(String(shot[2]))
		_progress("saved " + String(shot[2]))
		if String(shot[2]) in ["S01_earth_console_tara", "S04_alo_glove_ports", "S07_mission_table", "S10_playback_transcripts"]:
			await _time(room.room_id + " " + scene_id)
	if room != null:
		room.free()
	camera.free()
	crew.free()

func _time(label: String) -> void:
	# Frame times only mean something while the window is really drawing; wait up to a minute for that.
	for wait in 3600:
		if DisplayServer.window_can_draw():
			break
		await process_frame
	for frame in 60:
		await process_frame
	var drawn_before := _drawn_frames
	var samples: Array[float] = []
	var previous := Time.get_ticks_usec()
	for frame in 180:
		await process_frame
		var now := Time.get_ticks_usec()
		samples.append((now - previous) / 1000.0)
		previous = now
	samples.sort()
	if _drawn_frames - drawn_before < 171:
		report.append("%s windowed frame ms with cast: not measured (window drew %d of 180 frames; macOS reported it covered)" % [label, _drawn_frames - drawn_before])
		return
	report.append("%s windowed frame ms with cast: p50=%.2f p95=%.2f; draw calls=%d" % [label, samples[90], samples[171], Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])

## Waits for the next drawn frame. When macOS reports the window covered (another capture window on top of it, the
## lock screen), Godot stops drawing and frame_post_draw never fires (the 7 Nov stalls), so after half a second of
## frames without a draw the capture renders every viewport itself.
func _draw_frame() -> void:
	var drawn := _drawn_frames
	for frame in 30:
		await process_frame
		if _drawn_frames > drawn:
			return
	RenderingServer.force_draw(false)

func _count_draw() -> void:
	_drawn_frames += 1

## Saves the presented frame, re-reading a blank (shader-compile) frame for up to two seconds.
func _save(id: String) -> void:
	var image := root.get_texture().get_image()
	for attempt in 120:
		if not _blank(image):
			break
		await _draw_frame()
		image = root.get_texture().get_image()
	_check(not _blank(image), "capture " + id + " shows a rendered frame")
	_check(image.save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/M3-2R_%s.png" % id)) == OK, "capture " + id)

func _blank(image: Image) -> bool:
	var brightest := 0.0
	for gx in 16:
		for gy in 9:
			var c := image.get_pixel(int((gx + 0.5) * image.get_width() / 16.0), int((gy + 0.5) * image.get_height() / 9.0))
			brightest = maxf(brightest, c.get_luminance())
	return brightest < 0.03

# ----------------------------------------------------------------------------------------------- helpers

func _ray(from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	return root.get_world_3d().direct_space_state.intersect_ray(query)

## Visible mesh bounds of a node in room space (far LODs, hidden helpers and a print's own photographic world skipped).
func _bounds(room: CampaignRoom, node: Node) -> AABB:
	var box := AABB()
	var first := true
	var meshes := node.find_children("*", "MeshInstance3D", true, false)
	if node is MeshInstance3D:
		meshes.append(node)
	for mesh in meshes:
		if (mesh as GeometryInstance3D).visibility_range_begin > 0.0 or not mesh.is_visible_in_tree() or mesh.name == "Edge" or mesh.get_viewport() != room.get_viewport():
			continue
		var local: AABB = room.global_transform.affine_inverse() * mesh.global_transform * mesh.get_aabb()
		box = local if first else box.merge(local)
		first = false
	return box
