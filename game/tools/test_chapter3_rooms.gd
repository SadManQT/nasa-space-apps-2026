## M3-3R: every Chapter 3 scene is staged in its proper location (STORY_FULL.md scene locations, the CHAPTER_03 scene
## scripts, scene_rosters.json, doc 09) and every join of doc 24 §2.9 that touches Chapter 3 can play in the world. LOC-07,
## the Expedition Zero annex, is a real two-deck room: the warm-side access bay with the N.R. floor hatch and the 2034
## annex 3 m below it, built from the M3-3A EN_ZeroAnnex pieces. Builds the real room scenes with the real
## PlayerController and cast, then checks the mapping and rosters, stations for every scene action, navigation on both
## decks, collision, the hatch boundary, props resting, readable signs and live words, the bridge, clue (doc 24 §4
## clues 10-13) and story-echo objects (§5.2 D2, D4, D6, the vigil and Tara moments), light levels, the EVA suits on
## the cold side, and that the Chapter 1, 6 and 7 rooms come back exactly outside the chapter.
##   Godot --headless --path game --script res://tools/test_chapter3_rooms.gd
##   --capture (windowed) also writes production/qa/evidence/M3-3R_*.png and M3-3R_runtime.txt.
extends SceneTree

const Contract = preload("res://scripts/world/room_contract.gd")
const Presentation = preload("res://scripts/world/room_presentation.gd")
const Staging = preload("res://scripts/world/room_staging.gd")
const Gates = preload("res://scripts/missions/extended_gate_catalog.gd")
const Roster = preload("res://scripts/companions/companion_roster.gd")
const Crew = preload("res://scripts/world/campaign_crew.gd")
const Kit = preload("res://assets/environment/kit/habitat_kit.gd")
const C7 = preload("res://assets/props/chapter7_assets.gd")
const Player = preload("res://scenes/player/player.tscn")
const SCENE_FILES := {"LOC-01": "commons", "LOC-02": "service_rooms", "LOC-03": "garden", "LOC-04": "safe_room", "LOC-07": "annex"}
const PLAYER_ANCHOR := {"LOC-01": "commons_player", "LOC-02": "service_player", "LOC-03": "garden_player", "LOC-04": "safe_player", "LOC-07": "annex_player"}
## STORY_FULL.md / CHAPTER_03: the atmosphere service corridor, taps, preview board, spur and console (S01-S05); the annex
## access bay and the cold annex below it (S06-S08); the garden benches and rack (S09-S11); Tara's bay and the lineage
## board in the garden (S12).
const EXPECTED_ROOM := {
	"EX-CH03-S01": "LOC-02", "EX-CH03-S02": "LOC-02", "EX-CH03-S03": "LOC-02", "EX-CH03-S04": "LOC-02",
	"EX-CH03-S05": "LOC-02", "EX-CH03-S06": "LOC-07", "EX-CH03-S07": "LOC-07", "EX-CH03-S08": "LOC-07",
	"EX-CH03-S09": "LOC-03", "EX-CH03-S10": "LOC-03", "EX-CH03-S11": "LOC-03", "EX-CH03-S12": "LOC-03",
}
## Canon lines quoted word for word on staged words (exempt from the player-text patterns).
const CANON_LINES := ["EX-CH03-S03-L03"]
const CADETS := ["kai", "amara", "mei", "rafi"]
const LOWER := -3.0
## The garden plants' dated stages per scene for the windowed captures (PlantService codes; the campaign drives them).
const PLANTS := {
	"EX-CH03-S09": {"ALO-01": "mature_pods", "TARA-01": "pod_bearing"},
	"EX-CH03-S10": {"ALO-01": "mature_dry", "TARA-01": "pod_bearing"},
	"EX-CH03-S11": {"ALO-01": "archived_petal", "TARA-01": "pod_bearing"},
	"EX-CH03-S12": {"ALO-01": "archived_petal", "TARA-01": "mature_dry"},
}
var checks := 0
var failures := 0
var capture := false
var report: Array[String] = []
var _patterns: Array[RegEx] = []

func _init() -> void:
	# doc 25 §8.1 player-text patterns (test_player_text.gd): no internal ids or engineering verbs on any staged word.
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

func _run() -> void:
	capture = OS.get_cmdline_user_args().has("--capture")
	root.size = Vector2i(1600, 900)
	if capture:
		root.always_on_top = true
		root.grab_focus()
	_check_mapping()
	if OS.get_cmdline_user_args().has("--shots-only"):
		# M3-3R_capture.sh runs the checks headless first (the physics walks are slow in a window), then only the shots
		await _capture_all()
		await _finish()
		return
	await _check_annex_room()
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
	await _check_restaging()
	await _check_echoes()
	await _check_crew()
	if capture:
		await _capture_all()
	await _finish()

func _finish() -> void:
	var line := "CHAPTER 3 ROOMS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures]
	print(line)
	report.append(line)
	if capture:
		var file := FileAccess.open("res://../production/qa/evidence/M3-3R_runtime.txt", FileAccess.WRITE)
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

# ------------------------------------------------------------------------------------------- mapping and rosters

func _check_mapping() -> void:
	for scene_id in EXPECTED_ROOM:
		var room_id := Contract.room_for_scene(scene_id)
		_check(room_id == EXPECTED_ROOM[scene_id], scene_id + " is staged in its STORY_FULL location " + String(EXPECTED_ROOM[scene_id]))
		_check(String(Gates.gate(scene_id).get("room_id", "")) == room_id, scene_id + " gate names the same room")
		var roster := Roster.scene_roster(scene_id)
		for id in CADETS:
			_check(roster.has(id) and String(roster[id].physical_location_id) == room_id, "%s %s is physically at %s" % [scene_id, id, room_id])
		_check(String(roster.get("ferreira", {}).get("physical_location_id", "")) == "EARTH_SCREEN", scene_id + " Ferreira is on Earth until Chapter 5 (canon)")
		for target in Gates.targets_for_scene(scene_id):
			_check(not Contract.station_focus(scene_id, String(target.target_id)).is_empty(), scene_id + " action has a room station: " + String(target.target_id))
	_check(Contract.room_for_scene("EX-CH02-S12") == "LOC-01" and Contract.room_for_scene("EX-CH04-S01") == "LOC-03", "neighbouring chapters keep their rooms")
	_check(Contract.validate("LOC-07").valid and Contract.room("LOC-07").boundary_ids == ["door_service_annex", "annex_hatch"], "LOC-07 contract validates with its door and its hatch boundary")
	_check(not Contract.care_round("EX-CH03-S08").is_empty() and Contract.care_round("EX-CH03-S08").has("ALO-01"), "doc 24 7.2: the Care Round visits Alo and Tara in EX-CH03-S08")
	_check(Contract.care_round("EX-CH03-S12").keys() == ["TARA-01"] and Contract.care_round("EX-CH03-S09").is_empty(), "EX-CH03-S12 visits Tara only; no care round outside its scenes")

# ---------------------------------------------------------------------------------------- the annex as a room

## LOC-07 built like the Chapter 1 rooms: batched kit and annex pieces, solid shells on both decks, a 2 x 2 m hatch
## well whose N.R. leaf is the pressure boundary, two unconnected navigation decks and the ladder between them.
func _check_annex_room() -> void:
	var room := await _room("LOC-07")
	var child_count := room.visual_root.get_child_count()
	await room.load_assets_incremental()
	_check(room.visual_root.get_child_count() == child_count, "LOC-07 duplicate incremental load does not duplicate props")
	_check(room.build_room().get("duplicate", false), "LOC-07 rebuild is idempotent")
	_check(room.visual_root.has_node("HabitatKit") and room.visual_root.get_node("HabitatKit").get_child_count() < 240, "LOC-07 repeating geometry (kit and annex) is batched")
	_check(room.pressure_root.get_child_count() == 2 and room.door_root.has_node("Door_door_service_annex") and room.door_root.has_node("Door_annex_hatch"), "LOC-07 registers its pressure door and the N.R. hatch boundary")
	for piece in ["annex_hatch", "annex_station", "annex_ladder", "annex_bench", "annex_archive"]:
		_check(room.visual_root.has_node(piece) and Kit.piece_id(room.visual_root.get_node(piece)).begins_with("EN_ZeroAnnex_"), "LOC-07 places the M3-3A piece " + piece)
	await physics_frame
	await physics_frame
	var hatch := room.visual_root.get_node("annex_hatch") as Node3D
	var cover := hatch.find_children("Cover", "Node3D", true, false)[0] as Node3D
	_check(cover.position.x > 1.1 and absf(cover.rotation_degrees.y - 14.0) < 0.01, "the quake's displaced service cover lies aside (CH02-S12 -> CH03-S06)")
	# the coaming keeps a walking-height guard (an obstacle box to 0.2 m) so nobody steps into an open well; the leaf
	# itself is tested from just under that guard
	_check(not _ray(Vector3(-2.0, 1.0, 0.0), Vector3(-2.0, -1.0, 0.0)).is_empty(), "the hatch opening is guarded at deck level")
	var leaf_hit := _ray(Vector3(-1.9, 0.6, 0.1), Vector3(-1.9, -1.0, 0.1), 0x7fffffff, [room.collision_root.get_node("annex_hatch_coaming").get_rid()])
	_check(not leaf_hit.is_empty() and leaf_hit.position.y > 0.05, "the closed N.R. leaf blocks the opening")
	room.set_door_open("annex_hatch", true)
	await physics_frame
	await physics_frame
	var down := _ray(Vector3(-1.9, 0.6, 0.1), Vector3(-1.9, -3.5, 0.1), 0x7fffffff, [room.collision_root.get_node("annex_hatch_coaming").get_rid()])
	_check(not down.is_empty() and absf(down.position.y - LOWER) < 0.02, "through the open hatch a ray reaches the annex grating 3 m below (hit %.3f)" % (down.position.y if not down.is_empty() else 9.0))
	room.set_door_open("annex_hatch", false)
	await physics_frame
	_check(absf((hatch.find_children("HatchLeaf", "Node3D", true, false)[0] as Node3D).rotation_degrees.z) < 0.01, "closing the hatch boundary swings the leaf shut")
	_check(not _ray(Vector3(-2.0, -1.5, -0.6), Vector3(-2.0, -1.5, 0.8)).is_empty(), "the fixed ladder stands in the hatch well")
	for side in [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
		# off the east door's opening (east wall, offset 0)
		var edge: Vector3 = side * (4.0 if side.x != 0 else 3.0) + Vector3(0, 2.0, -2.0 if side.x != 0 else 0.0)
		_check(not _ray(edge - side * 0.4, edge + side * 0.4).is_empty(), "warm-bay perimeter is solid " + str(side))
		var low: Vector3 = Vector3(1.0, LOWER + 1.5, 0.0) + side * (5.0 if side.x != 0 else 3.0)
		_check(not _ray(low - side * 0.4, low + side * 0.4).is_empty(), "annex perimeter is solid " + str(side))
	_check(not _ray(Vector3(3.0, -1.0, -2.0), Vector3(3.0, 0.5, -2.0)).is_empty() and not _ray(Vector3(3.0, 1.0, -2.0), Vector3(3.0, -1.0, -2.0)).is_empty(), "the slab between the decks is solid away from the well")
	var region := room.navigation_root.get_node("NavigationRegion") as NavigationRegion3D
	var map := region.get_navigation_map()
	NavigationServer3D.map_force_update(map)
	var upper := Vector3(1.6, 0, 0.8)
	var lower := Vector3(-1.3, LOWER, -0.6)
	_check(NavigationServer3D.map_get_closest_point(map, upper).distance_to(upper) < 0.1 and NavigationServer3D.map_get_closest_point(map, lower).distance_to(lower) < 0.1, "both decks are walkable navigation")
	var across := NavigationServer3D.map_get_path(map, upper, lower, true)
	_check(across.is_empty() or across[across.size() - 1].distance_to(lower) > 1.0, "the decks are not connected by a walkable path (the ladder is climbed)")
	for anchor in room.anchor_root.get_children():
		_check(absf(anchor.position.y) < 0.001, "LOC-07 base crew anchor on the warm-side deck: " + String(anchor.name))
	room.free()
	await process_frame

# ------------------------------------------------------------------------------------------------ one scene

func _deck_y(y: float) -> float:
	return LOWER if y < LOWER + 2.0 else 0.0

func _probe_point(point: Array) -> Vector3:
	return Vector3(float(point[0]), float(point[2]) if point.size() > 2 else 0.0, float(point[1]))

func _check_scene(room: CampaignRoom, scene_id: String, player: PlayerController) -> void:
	var room_id := room.room_id
	var layout := Contract.staged_layout(room_id, scene_id)
	var stage: Dictionary = room.stage()
	_check(not stage.get("layers", []).is_empty() and room.visual_root.has_node(Staging.ROOT_NAME), scene_id + " room carries its Chapter 3 staging")
	var region := room.navigation_root.get_node("NavigationRegion") as NavigationRegion3D
	var map := region.get_navigation_map()
	NavigationServer3D.map_force_update(map)
	_check(room.navigation_root.get_child_count() == 1, scene_id + " exactly one navigation map after staging")
	var spawn := _probe_point(layout.walk_probe[0])
	var spawns := {0.0: _probe_point(Contract.layout(room_id).walk_probe[0])}
	spawns[_deck_y(spawn.y)] = spawn
	_check(NavigationServer3D.map_get_closest_point(map, spawn).distance_to(spawn) < 0.4, scene_id + " spawn lies on navigation")
	for point in layout.walk_probe:
		var goal := _probe_point(point)
		var path := NavigationServer3D.map_get_path(map, spawn, goal, true)
		_check(path.size() > 0 and path[path.size() - 1].distance_to(goal) < 0.4, scene_id + " obstacle-aware path reaches " + str(goal))
	var focus_ids: Array = room.focus_targets().map(func(t): return String(t.target_id))
	for target in Gates.targets_for_scene(scene_id):
		var station := Contract.station_focus(scene_id, String(target.target_id))
		_check(focus_ids.has(String(target.world_focus_id)), scene_id + " gate focus exists: " + String(target.world_focus_id))
		_check(focus_ids.has(station), scene_id + " station exists for " + String(target.target_id))
		for spec in layout.focus_targets:
			if String(spec.target_id) == station:
				var approach := Presentation.vector(spec.approach_m)
				var path := NavigationServer3D.map_get_path(map, spawn, approach, true)
				_check(not path.is_empty() and path[path.size() - 1].distance_to(approach) < 0.4, scene_id + " the scene's player can walk to the station for " + String(target.target_id))
	for target in layout.focus_targets:
		var approach := Presentation.vector(target.approach_m)
		var point := Presentation.vector(target.position)
		var from: Vector3 = spawns.get(_deck_y(approach.y), spawn)
		var path := NavigationServer3D.map_get_path(map, from, approach, true)
		_check(not path.is_empty() and path[path.size() - 1].distance_to(approach) < 0.4, scene_id + " reachable approach " + String(target.target_id))
		_check(_ray(approach + Vector3.UP * 1.4, point).is_empty(), scene_id + " interaction line of sight " + String(target.target_id))
	await _walk(player, layout, scene_id)
	for obstacle in stage.obstacles:
		var at := Presentation.vector(obstacle.position)
		var size := Presentation.vector(obstacle.size)
		_check(not _ray(at + Vector3(size.x * 0.5 + 0.15, 0, 0), at).is_empty(), scene_id + " staged furniture blocks movement: " + String(obstacle.id))
	_check_doors(room, map, spawns, scene_id)
	_check_anchors(room, map, scene_id)
	_check_staged_objects(room, layout, scene_id)
	_check_staged_text(room, map, scene_id)
	_check_bridges(room, scene_id)

func _walk(player: PlayerController, layout: Dictionary, scene_id: String) -> void:
	var start := _probe_point(layout.walk_probe[0])
	player.position = start + Vector3(0, 0.04, 0)
	player.velocity = Vector3.ZERO
	for point in layout.walk_probe:
		var goal := _probe_point(point)
		for step in 700:
			var delta := goal - player.position
			delta.y = 0
			if delta.length() < 0.09:
				break
			player.velocity = delta.normalized() * 3.0 + Vector3.DOWN
			player.move_and_slide()
			await physics_frame
		_check(Vector2(player.position.x - goal.x, player.position.z - goal.z).length() < 0.12 and absf(player.position.y - goal.y) < 0.2, scene_id + " player walks unobstructed to " + str(goal))
	player.velocity = Vector3.ZERO

## Doc 09 clearances stay true with the staged furniture: a 1 m approach to every walking door is clear and reachable.
func _check_doors(room: CampaignRoom, map: RID, spawns: Dictionary, scene_id: String) -> void:
	for node in room.door_root.get_children():
		if not node is CampaignDoor or String(node.boundary_id) in ["garden_viewing_shutter", "annex_hatch"]:
			continue
		var inward: Vector3 = -node.global_basis.z
		inward.y = 0
		var approach: Vector3 = node.global_position + inward.normalized() * 1.0
		approach.y = 0
		var path := NavigationServer3D.map_get_path(map, spawns[0.0], approach, true)
		_check(not path.is_empty() and path[path.size() - 1].distance_to(approach) < 0.2, scene_id + " 1 m door approach stays clear: " + String(node.boundary_id))

## Everyone the roster puts in this room has a scene anchor on walkable deck (either annex deck), clear of furniture and
## of each other.
func _check_anchors(room: CampaignRoom, map: RID, scene_id: String) -> void:
	var active := Roster.playable_actor(scene_id)
	var placed: Array[Vector3] = []
	var anchors := Contract.staged_anchors(room.room_id, scene_id)
	var player_at: Array = anchors.get(PLAYER_ANCHOR[room.room_id], [])
	_check(not player_at.is_empty() and NavigationServer3D.map_get_closest_point(map, Vector3(player_at[0], player_at[1], player_at[2])).distance_to(Vector3(player_at[0], player_at[1], player_at[2])) < 0.3, scene_id + " the scene's player anchor stands on walkable deck")
	for id in CADETS:
		if id == active:
			continue
		var at := Crew.anchor_position(room.room_id, id, scene_id)
		_check(anchors.keys().any(func(key): return String(key) == "%s_%s" % [PLAYER_ANCHOR[room.room_id].trim_suffix("_player"), id]), "%s %s has an authored anchor" % [scene_id, id])
		_check(NavigationServer3D.map_get_closest_point(map, at).distance_to(at) < 0.3, "%s %s stands on walkable deck %s" % [scene_id, id, str(at)])
		for other in placed + ([Vector3(player_at[0], player_at[1], player_at[2])] if not player_at.is_empty() else []):
			_check(at.distance_to(other) > 0.6, "%s %s keeps 0.6 m from the next person" % [scene_id, id])
		placed.append(at)

## Staged furniture rests on its deck, a wall, a surface or flush on a panel face, stays inside its deck's footprint, and
## every large floor-standing addition has collision over its footprint.
func _check_staged_objects(room: CampaignRoom, layout: Dictionary, scene_id: String) -> void:
	var staged := room.visual_root.get_node(Staging.ROOT_NAME) as Node3D
	var surfaces: Array[AABB] = []
	for node in room.visual_root.get_children() + staged.get_children():
		if node is Node3D and node.visible and node != staged and String(node.name) != "HabitatKit":
			var box := _bounds(room, node)
			if box.size != Vector3.ZERO:
				surfaces.append(box)
	var ours := _chapter3_ids(room.room_id)
	for node in staged.get_children():
		if not node is Node3D or node is Label3D or not ours.has(String(node.name)):
			continue  # other chapters' objects that stay into Chapter 3 (M3-2R's recorder bench) are their suites'
		var box := _bounds(room, node)
		if box.size == Vector3.ZERO:
			continue
		var id := String(node.name)
		var deck := _deck_y(box.position.y)
		var lo := Vector2(-float(layout.bounds_m[0]) * 0.5, -float(layout.bounds_m[1]) * 0.5)
		var hi := -lo
		if deck < 0.0:
			var b: Array = layout.lower_deck.bounds
			lo = Vector2(b[0], b[1])
			hi = Vector2(b[2], b[3])
		_check(box.position.x >= lo.x - 0.02 and box.end.x <= hi.x + 0.02 and box.position.z >= lo.y - 0.02 and box.end.z <= hi.y + 0.02, scene_id + " staged object inside its deck's footprint: " + id)
		var base := box.position.y - deck
		var supported := absf(base) < 0.03
		var wall := absf(box.end.z - hi.y) < 0.12 or absf(box.position.z - lo.y) < 0.12 or absf(box.end.x - hi.x) < 0.12 or absf(box.position.x - lo.x) < 0.12
		var centre := box.get_center()
		for surface in surfaces:
			if surface == box:
				continue
			if surface.end.y <= box.position.y + 0.03 and surface.end.y >= box.position.y - 0.04 and centre.x >= surface.position.x and centre.x <= surface.end.x and centre.z >= surface.position.z and centre.z <= surface.end.z:
				supported = true
			var overlaps_y := box.position.y < surface.end.y and box.end.y > surface.position.y
			var flush_z := (absf(box.position.z - surface.end.z) < 0.01 or absf(box.end.z - surface.position.z) < 0.01) and box.position.x < surface.end.x and box.end.x > surface.position.x
			var flush_x := (absf(box.position.x - surface.end.x) < 0.01 or absf(box.end.x - surface.position.x) < 0.01) and box.position.z < surface.end.z and box.end.z > surface.position.z
			if overlaps_y and (flush_z or flush_x) and box.size.y < surface.size.y:
				supported = true
		_check((supported or wall) and base > -0.03, scene_id + " staged object rests on its deck, a wall, a surface or a panel face (base %.3f m): %s" % [base, id])
		if absf(base) < 0.03 and box.size.y >= 0.5:
			var covered := true
			for u in 5:
				for v in 5:
					var point := Vector3(lerpf(box.position.x + 0.1, box.end.x - 0.1, u / 4.0), deck + 0.3, lerpf(box.position.z + 0.1, box.end.z - 0.1, v / 4.0))
					var inside := false
					for obstacle in layout.obstacles:
						var area := AABB(Presentation.vector(obstacle.position) - Presentation.vector(obstacle.size) * 0.5, Presentation.vector(obstacle.size))
						inside = inside or area.has_point(point)
					covered = covered and inside
			_check(covered, scene_id + " large staged object has collision over its footprint: " + id)

## Every staged wall label faces walkable deck, never mirrored; staged words, live slot words and inks use player language
## (canon dialogue quoted from the catalog is exempt).
func _check_staged_text(room: CampaignRoom, map: RID, scene_id: String) -> void:
	var staged := room.visual_root.get_node(Staging.ROOT_NAME) as Node3D
	var words: Array[String] = []
	for label in staged.find_children("*", "Label3D", true, false):
		if not label.is_visible_in_tree() or String(label.text).strip_edges().is_empty():
			continue
		words.append(String(label.text))
		var facing: Vector3 = label.global_basis.z
		if absf(facing.y) > 0.7:
			continue  # a page lying on a table reads from above
		facing.y = 0
		facing = facing.normalized()
		var at: Vector3 = label.global_position
		at.y = _deck_y(at.y)
		var front := 99.0
		for reach in [0.8, 1.2, 1.6, 2.0]:
			var probe: Vector3 = at + facing * reach
			front = minf(front, NavigationServer3D.map_get_closest_point(map, probe).distance_to(probe))
		_check(front < 0.35, scene_id + " staged label reads from walkable deck: " + String(label.text).left(40))
		_check(not label.double_sided, scene_id + " staged label is single-sided: " + String(label.text).left(40))
		_check(not String(label.text).contains("{line}"), scene_id + " sign template is filled: " + String(label.name))
	for piece in room.visual_root.get_children():
		for slot_label in piece.get_meta("slot_text", {}).values():
			words.append(String((slot_label as Label).text))
		for ink in piece.find_children("*", "Label3D", true, false):
			words.append(String((ink as Label3D).text))
	for text in words:
		var plain := text
		for id in CANON_LINES:
			plain = plain.replace(Staging.line_text(id), "")
		for regex in _patterns:
			_check(regex.search(plain) == null, scene_id + " staged words stay in player language: " + text.left(40))

# ------------------------------------------------------------------------------------------------- the joins

func _text(staged: Node, id: String) -> String:
	var label := staged.get_node_or_null(id) as Label3D
	return label.text if label != null and label.visible else ""

func _slot(room: CampaignRoom, piece: String, slot: String) -> String:
	var node := room.visual_root.get_node_or_null(piece)
	if node == null or not node.get_meta("slot_text", {}).has(slot):
		return ""
	return String((node.get_meta("slot_text")[slot] as Label).text)

func _part(room: CampaignRoom, piece: String, part: String) -> Node3D:
	var found := (room.visual_root.get_node(piece) as Node3D).find_children(part, "Node3D", true, false)
	return found[0] if not found.is_empty() else null

func _practical_scale(room: CampaignRoom) -> float:
	var practical := room.get_node("RoomLighting/Practical_0") as OmniLight3D
	return practical.light_energy / float(practical.get_meta("base_energy", practical.light_energy))

## Doc 24 §2.9 rows CH02->CH03 .. CH03->CH04, §4 clues 10-13 and doc 09's revisit rule, scene by scene.
func _check_bridges(room: CampaignRoom, scene_id: String) -> void:
	var staged := room.visual_root.get_node(Staging.ROOT_NAME) as Node3D
	var order := Contract.scene_order(scene_id) % 100
	if room.room_id == "LOC-02":
		var board := _text(staged, "ch03_board_readings")
		var panel := _text(staged, "air_warning_row_tank")  # M3-2R's status screen on the air console
		_check(_text(staged, "ch03_tap_main_text").contains("MAIN TANK") and _text(staged, "ch03_tap_garden_text").contains("GARDEN SPUR") and _text(staged, "ch03_tap_return_text").contains("RETURN LINE"), scene_id + " the three labelled taps sit on the real service points")
		_check(absf(_practical_scale(room) - (0.85 if order <= 4 else 1.0)) < 0.001, scene_id + " controlled local response light until the warning clears")
		_check(staged.has_node("ch03_spur_label") and is_equal_approx((staged.get_node("ch03_spur_label") as Node3D).rotation_degrees.z, 8.0), scene_id + " the quake's crooked spur label stays as evidence through the test (S04 -> S05)")
		_check(staged.has_node("garden_spur_clamp") == (order >= 4), scene_id + " the clamp is seated from S04 and stays")
		_check(staged.has_node("manual_gauge") == (order <= 4) and staged.has_node("manual_gauge_on_hook") == (order == 5), scene_id + " the independent gauge: on its work stand, then on its hook when the warning clears (canon S05)")
		match order:
			1:
				_check(panel.contains("TANK PRESSURE · WARNING"), scene_id + " the same red tank warning as CH02-S12, no time jump (CH02 -> CH03)")
				_check(board.contains("HYPOTHESIS (KAI)") and board.contains("REFERENCE CHECKED") and board.contains("OWN SEALED AIR"), scene_id + " Kai's guess filed under hypothesis beside the gauge reference (S01 -> S02)")
			2:
				_check(board.contains("100 -> 100") and board.contains("82 -> 74") and board.contains("PROPOSED BOUNDARY"), scene_id + " three saved readings (08 P-05: 100/100, 82/74, 100/100) and the proposed boundary (S02 -> S03)")
			3:
				_check(board.contains("PREVIEW A") and board.contains("PREVIEW B") and board.contains("ROLLBACK"), scene_id + " the paused previews and the rollback condition (S03 -> S04)")
				_check(_text(staged, "ch03_repair_text").contains(Staging.line_text("EX-CH03-S03-L03")) and staged.has_node("earth_screen"), scene_id + " Ferreira's repair diagram arrives on the Earth link, her line word for word")
			4:
				_check(board.contains("A SEATED CLAMP IS NOT A VERIFIED REPAIR") and staged.has_node("ch03_boundary_front") and _text(staged, "ch03_boundary_text") == "WORK BOUNDARY", scene_id + " the approved sequence and the work boundary round the spur")
			5:
				_check(panel.contains("TANK PRESSURE · OK") and board.contains("CORRECTED 7 MAY") and board.contains("CAMERA INSPECTION 7 MAY") and board.contains("8 MAY"), scene_id + " five checks, the corrected note and the camera-only annex handover (S05 -> S06)")
		_check(staged.has_node("earth_screen") == (order == 3), scene_id + " the Earth-link panel is up only for Ferreira's call")
	elif room.room_id == "LOC-07":
		var leaf := _part(room, "annex_hatch", "HatchLeaf")
		var shutter := _part(room, "annex_hatch", "PortShutter")
		var valve := _part(room, "annex_hatch", "FeedValve")
		var screen := _slot(room, "annex_station", "Screen")
		_check(_part(room, "annex_hatch", "Cover").position.x > 1.1, scene_id + " the displaced cover still lies aside")
		_check(is_equal_approx(valve.rotation_degrees.y, 90.0), scene_id + " the annex utility feed stays isolated")
		_check(leaf.find_children("nameplate", "Label3D", true, false).size() == 1 and (leaf.find_children("nameplate", "Label3D", true, false)[0] as Label3D).text == "N.R.", scene_id + " the hatch is marked N.R. (clue 10), riding on its leaf")
		_check(is_equal_approx(leaf.rotation_degrees.z, 100.0 if order == 7 else 0.0), scene_id + " the hatch is open only for the suited entry")
		var tag := (room.visual_root.get_node("annex_station") as Node3D).get_node_or_null("tool_tag")
		_check((tag != null) == (order >= 7), scene_id + " the gear-wheel tool tag hangs on the warm-side station from the suited entry (clue 12)")
		var chart := _slot(room, "annex_archive", "Document_Chart")
		_check(chart.ends_with("Day 12. Leaves curling. Heat"), scene_id + " the growth chart's last handwritten line stops at 'Day 12. Leaves curling. Heat' (clue 12)")
		var archive := room.visual_root.get_node("annex_archive") as Node3D
		var inks: Array = archive.find_children("*", "Label3D", true, false).map(func(l): return String(l.text))
		_check(inks.any(func(t): return t.contains("FILED BEFORE THE EVACUATION")) and inks.any(func(t): return t.contains("2034")), scene_id + " the route sheet filed before the evacuation and the 2034 service tag (clue 11)")
		_check(is_equal_approx(_part(room, "annex_archive", "SealedCover").rotation_degrees.x, 0.0), scene_id + " the route sheet stays under its sealed cover")
		_check((room.visual_root.get_node("annex_bench") as Node3D).find_children("PL_ZeroSeedlingTray_*", "Node3D", false, false).size() == 2, scene_id + " two frozen 2034 trays on the bench, undisturbed")
		match order:
			6:
				_check(shutter.position.x > (shutter.get_meta("rest_position", Vector3.ZERO) as Vector3).x + 0.1, scene_id + " the camera port is open: a camera goes first")
				var view := (room.visual_root.get_node("annex_station") as Node3D).get_node_or_null("SlotView_Screen") as SubViewport
				_check(view != null and view.find_children("*", "Camera3D", false, false).size() == 1 and screen.contains("HATCH CAMERA"), scene_id + " the inspection camera's live view is on the warm-side screen")
				_check(_text(staged, "boundary_text").contains("CAMERA INSPECTION ONLY") and _text(staged, "boundary_text").contains("8 MAY"), scene_id + " camera-only inspection; suited entry scheduled 8 May (S06 -> S07)")
				_check(_text(staged, "safety_drawing_text").contains("CERTIFIED STATION PLAN") and staged.has_node("earth_screen"), scene_id + " the hatch matches the supplied safety drawing; Ferreira's Earth link is up")
				_check(_text(staged, "gauge_reading").ends_with("0.0"), scene_id + " the boundary reads zero differential")
			7:
				_check(room.stage().outfits == {"mei": "eva", "rafi": "eva"}, scene_id + " Mei and Rafi enter the cold side suited")
				_check(_text(staged, "boundary_text").contains("SUITED ENTRY CLEARED") and screen.contains("LOCAL RADIO"), scene_id + " the entry is cleared; Kai and Amara support on the local radio")
				_check(staged.has_node("return_boundary_n") and _text(staged, "return_boundary_text") == "RETURN BOUNDARY", scene_id + " the return boundary is marked at the ladder foot")
			8:
				var planning := _text(staged, "planning_text")
				_check(planning.contains("DEPOSIT LOGGED BEFORE THE RETREAT") and planning.contains("SLOPE, RETURN RESERVE"), scene_id + " the map's provenance and the present-day checks it cannot satisfy (clue 13)")
				_check(_text(staged, "route_copy_text").contains("SCANNED COPY") and _text(staged, "care_card_text").contains("16 MAY"), scene_id + " the scanned route sheet and the dated care visits to 16 May (S07 -> S08, S08 -> S09)")
	elif room.room_id == "LOC-03":
		var board_has := func(id: String) -> bool: return staged.has_node(id)
		_check(board_has.call("alo_nameplate") == (order >= 10), scene_id + " Alo's nameplate goes onto the lineage board at the harvest (doc 24 7.3 beat 10)")
		match order:
			9:
				_check(_text(staged, "drydown_text").contains("16 TO 21 MAY") and _text(staged, "drydown_text").contains("FIVE DAYS"), scene_id + " the date card names the five-day dry-down before it is accepted")
				_check(_text(staged, "pod_record_text").contains("8 MAY") and _text(staged, "pod_record_text").contains("16 MAY"), scene_id + " the dated pod development 8 to 16 May arrives in the garden (S08 -> S09)")
			10:
				var case := staged.get_node("founder_case") as Node3D
				_check(_text(staged, "ledger_text").contains("42 = 12 + 30"), scene_id + " 42 = 12 + 30 on the bench (S10 -> S11)")
				_check(C7.count_seeds(case) == 30, scene_id + " the open founder case takes the thirty")
				_check(staged.has_node("alo_petal_sleeve") and staged.has_node("counting_tray"), scene_id + " the pressed petal in its sleeve beside the contained tray")
				_check(_text(staged, "alo_record").contains("FORTY-TWO SEEDS"), scene_id + " Alo's record on the lineage board")
			11:
				var case := staged.get_node("founder_case") as Node3D
				_check(C7.count_seeds(case) == 30 and _text(staged, "seal_record_text").contains("FOUNDER RESERVE 30"), scene_id + " the thirty founder seeds remain sealed beside the seal record")
				_check(staged.has_node("alo_petal") and not staged.has_node("alo_petal_sleeve"), scene_id + " the petal now hangs where it can be seen (S11 -> S12)")
				# M3-108: the mounted sleeve's petal side is the kit's front (-Z); it must face the board's review view, not the board
				var mount := staged.get_node("alo_petal") as Node3D
				var eye := Presentation.vector(Contract.staged_layout(room.room_id, scene_id).review_views.lineage_board.from)
				_check((-mount.global_basis.z).dot((eye - mount.global_position).normalized()) > 0.5, scene_id + " the pressed petal faces the garden, not the board")
				_check(_has_material(staged.get_node("descendant_rack"), "M_Rack_Soil"), scene_id + " twelve planted positions on planting day")
				_check(_text(staged, "rack_parent_line").contains("ALO × TARA") and _text(staged, "rack_position_1").contains("VERY IMPORTANT SCIENTIFIC PLANT"), scene_id + " parent line first, then Kai's name on position 1 (canon)")
			12:
				_check(not _has_material(staged.get_node("descendant_rack"), "M_Rack_Soil") and staged.get_node("descendant_rack").find_children("*", "MeshInstance3D", true, false).size() > 12, scene_id + " the October rack: a few green stems among purple ones (CH03 -> CH04)")
				_check(_text(staged, "survey_text").contains("NO DEPARTURE STAMP") and _text(staged, "survey_text").contains("RETURN RESERVE"), scene_id + " the map's preparation list on the survey board (CH03 -> CH04)")
				_check(_text(staged, "care_ledger_text").contains("21 OCTOBER") and _text(staged, "care_ledger_text").contains("31 MAY"), scene_id + " the days between May and October are accounted for")
				_check(_text(staged, "family_tree_text").contains("TWELVE GROWING") and _text(staged, "prediction_test").contains("IN OCTOBER"), scene_id + " the stem prediction stays attached to the October comparison while twelve descendants grow (canon)")
				_check(staged.has_node("working_stock") and _text(staged, "tara_card_text").contains("Alo's thirty can stay sealed"), scene_id + " Tara's working stock, sealed with no count, and Mei's card (approved 5 Nov 2026)")
				var tara := (staged.get_node("tara_nameplate") as Node3D).position
				var petal := (staged.get_node("alo_petal") as Node3D).position
				_check(absf((tara.y + 0.019) - (petal.y + 0.038)) < 0.05, scene_id + " Tara's nameplate stands level with Alo's petal")
				_check(_text(staged, "working_line").contains("TARA × ALO") and _text(staged, "founder_line").contains("FOUNDER RESERVE 30"), scene_id + " the working stock and the founder reserve are separate records")
				_check(_visible_sign(room, "TARA / INDOOR REFERENCE"), scene_id + " Tara's name stays on the bay frame")

func _visible_sign(room: CampaignRoom, text: String) -> bool:
	for node in room.visual_root.get_children():
		if node is Label3D and node.text == text and node.visible:
			return true
	return false

# ---------------------------------------------------------------------------------------- re-staging, echoes

## One room instance re-staged scene after scene ends exactly as built: the annex returns to its base poses and words;
## Chapter 1 has no staging; Chapters 6 and 7 keep what Chapter 3 left (the clamp, the gauge on its hook, the lineage
## board) and nothing else.
func _check_restaging() -> void:
	var annex := await _room("LOC-07")
	var base_polys := (annex.navigation_root.get_node("NavigationRegion") as NavigationRegion3D).navigation_mesh.get_polygon_count()
	var base_focus := annex.focus_root.get_child_count()
	for scene_id in ["EX-CH03-S07", "EX-CH03-S06", "EX-CH03-S08", "EX-CH01-S01"]:
		annex.set_scene_context(scene_id)
		await process_frame
	var leaf := _part(annex, "annex_hatch", "HatchLeaf")
	_check(annex.stage().layers.is_empty() and not annex.visual_root.has_node(Staging.ROOT_NAME), "outside Chapter 3 the annex shows no staging")
	_check(is_equal_approx(leaf.rotation_degrees.z, 0.0) and is_equal_approx(_part(annex, "annex_hatch", "FeedValve").rotation_degrees.y, 0.0) and is_equal_approx(_part(annex, "annex_hatch", "PortShutter").position.x, (_part(annex, "annex_hatch", "PortShutter").get_meta("rest_position", Vector3.ZERO) as Vector3).x), "the hatch returns to its base pose (closed, feed connected, port shut): %s %s %s" % [leaf.rotation_degrees, _part(annex, "annex_hatch", "FeedValve").rotation_degrees, _part(annex, "annex_hatch", "PortShutter").position])
	_check(_part(annex, "annex_hatch", "Cover").position.x > 1.1, "the displaced cover stays the base room's")
	_check(_slot(annex, "annex_station", "Screen").contains("STANDBY") and (annex.visual_root.get_node("annex_station") as Node3D).get_node_or_null("tool_tag") == null, "the station screen and the tool tag return to the base room")
	_check((annex.navigation_root.get_node("NavigationRegion") as NavigationRegion3D).navigation_mesh.get_polygon_count() == base_polys and annex.focus_root.get_child_count() == base_focus, "annex navigation and stations return exactly")
	annex.free()
	await process_frame
	var service := await _room("LOC-02")
	for scene_id in ["EX-CH03-S03", "EX-CH01-S05"]:
		service.set_scene_context(scene_id)
		await process_frame
	_check(not service.visual_root.has_node(Staging.ROOT_NAME) and is_equal_approx((service.get_node("RoomLighting/Practical_0") as OmniLight3D).light_energy, 0.7), "the Chapter 1 service rooms are unchanged after the diagnosis")
	service.set_scene_context("EX-CH06-S01")
	await process_frame
	var staged := service.visual_root.get_node(Staging.ROOT_NAME)
	_check(staged.has_node("garden_spur_clamp") and staged.has_node("manual_gauge_on_hook") and staged.has_node("ch03_spur_label") and not staged.has_node("ch03_diagnostic_board"), "Chapter 6 keeps the seated clamp, the gauge on its hook and the straightened label; the diagnostic board is gone")
	_check(is_equal_approx((staged.get_node("ch03_spur_label") as Node3D).rotation_degrees.z, 0.0), "Kai straightened the spur label once the test was saved")
	service.free()
	await process_frame
	var garden := await _room("LOC-03")
	garden.set_scene_context("EX-CH03-S12")
	await process_frame
	garden.set_scene_context("EX-CH01-S12")
	await process_frame
	_check(not garden.visual_root.has_node(Staging.ROOT_NAME) and (garden.visual_root.get_node("PL_Tara_Bloom") as Node3D).visible, "the Chapter 1 garden is unchanged after Chapter 3")
	garden.set_scene_context("EX-CH06-S12")
	await process_frame
	staged = garden.visual_root.get_node(Staging.ROOT_NAME)
	_check(staged.has_node("alo_petal") and staged.has_node("tara_nameplate") and not staged.has_node("descendant_rack") and not staged.has_node("survey_board"), "Chapter 6 keeps the lineage board (doc 09: props accumulate); the October rack and survey board belong to CH03 -> CH04")
	garden.free()
	await process_frame
	var ch04 := Contract.staging("LOC-03", "EX-CH04-S01", {"EX-CH03-S11-DEDICATION": {"option_id": "EX-CH03-S11-DEDICATION-OPT02"}, "EX-CH02-S06-CHOICE": {"option_id": "EX-CH02-S06-OPT02"}})
	_check(ch04.layers.has("ch03_descendant_rack") and ch04.layers.has("ch03_d6_opt02") and ch04.layers.has("ch02_d4_opt02"), "CH04-S01 opens on the same rack with the chosen dedication and the saved May prediction (CH03 -> CH04)")

## Doc 24 §5.2: D2 shows the notebook layout chosen on day one, D6 the tray dedication, D4 the May prediction; the vigil
## photos and Tara's last photograph need their recorded moments. Nothing appears without its option.
func _check_echoes() -> void:
	var garden := await _room("LOC-03")
	garden.set_scene_context("EX-CH03-S12")
	await process_frame
	var staged := garden.visual_root.get_node(Staging.ROOT_NAME)
	_check(not staged.has_node("d2_record_tara") and not staged.has_node("dedication_card") and not staged.has_node("prediction_choice") and not staged.has_node("tara_last_photo"), "no echo objects without a recorded choice or moment")
	for option in {"EX-CH01-S04-OPT01": "PAIRED PHOTOGRAPHS", "EX-CH01-S04-OPT02": "PAIRED CONDITIONS"}.keys():
		var words: String = {"EX-CH01-S04-OPT01": "PAIRED PHOTOGRAPHS", "EX-CH01-S04-OPT02": "PAIRED CONDITIONS"}[option]
		for scene_id in ["EX-CH03-S09", "EX-CH03-S12"]:
			garden.set_story_choices({"EX-CH01-S04-CHOICE": {"option_id": option}})
			garden.set_scene_context(scene_id)
			await process_frame
			staged = garden.visual_root.get_node(Staging.ROOT_NAME)
			var id := "d2_record_text" if scene_id == "EX-CH03-S09" else "d2_record_tara_text"
			_check(_text(staged, id).contains(words), "D2 %s: the Growth Record in the player's layout in %s" % [option, scene_id])
	for option in {"EX-CH03-S11-DEDICATION-OPT01": "Light and Star", "EX-CH03-S11-DEDICATION-OPT02": "For Alo and Tara", "EX-CH03-S11-DEDICATION-OPT03": "The Next Small Thing"}.keys():
		var words: String = {"EX-CH03-S11-DEDICATION-OPT01": "Light and Star", "EX-CH03-S11-DEDICATION-OPT02": "For Alo and Tara", "EX-CH03-S11-DEDICATION-OPT03": "The Next Small Thing"}[option]
		garden.set_story_choices({"EX-CH03-S11-DEDICATION": {"option_id": option}})
		garden.set_scene_context("EX-CH03-S11")
		await process_frame
		staged = garden.visual_root.get_node(Staging.ROOT_NAME)
		_check(_text(staged, "dedication_card") == words and _text(staged, "dedication_wall").ends_with(words.to_upper()), "D6 %s: the tray card carries the chosen words" % option)
	garden.set_story_choices({"EX-CH02-S06-CHOICE": {"option_id": "EX-CH02-S06-OPT01"}})
	garden.set_scene_context("EX-CH03-S12")
	await process_frame
	staged = garden.visual_root.get_node(Staging.ROOT_NAME)
	_check(staged.has_node("prediction_choice") and staged.has_node("ch03_descendant_rack") == false and staged.has_node("descendant_rack"), "D4: the saved May prediction (M3-2R's card on the lineage board) waits beside the October rack")
	var moments := ["CH03-ALO-VIGIL-1", "CH03-ALO-VIGIL-2", "CH03-ALO-VIGIL-3", "CH03-ALO-VIGIL-4", "CH03-ALO-VIGIL-5", "CH03-TARA-FAREWELL"]
	garden.set_story_choices({}, moments.slice(0, 3))
	garden.set_scene_context("EX-CH03-S10")
	await process_frame
	staged = garden.visual_root.get_node(Staging.ROOT_NAME)
	_check(staged.has_node("vigil_photo_3") and not staged.has_node("vigil_photo_4") and not staged.has_node("mei_tea"), "vigil: one photo per recorded visit, in the same frame")
	garden.set_story_choices({}, moments)
	await process_frame
	staged = garden.visual_root.get_node(Staging.ROOT_NAME)
	_check(staged.has_node("vigil_photo_5") and _text(staged, "vigil_date_5") == "21 MAY" and staged.has_node("mei_tea"), "vigil: five photos 17 to 21 May; Kai's tea for Mei on the bench from the fourth visit")
	garden.set_scene_context("EX-CH03-S12")
	await process_frame
	staged = garden.visual_root.get_node(Staging.ROOT_NAME)
	_check(staged.has_node("tara_last_photo") and _text(staged, "tara_last_photo_caption").contains("31 MAY"), "Tara's last photograph beside her nameplate (moment CH03-TARA-FAREWELL)")
	garden.free()
	await process_frame

## The real cast placement: the room is staged before anyone stands in it, the scene's player anchor wins (the annex
## entry starts on the cold side), bodies stand at the scene anchors, Mei and Rafi wear their fitted EVA suits only for the
## suited entry, and Ferreira's calls get an Earth-link screen where she speaks.
func _check_crew() -> void:
	var crew := Crew.new()
	root.add_child(crew)
	for scene_id in ["EX-CH03-S01", "EX-CH03-S03", "EX-CH03-S06", "EX-CH03-S07", "EX-CH03-S08", "EX-CH03-S10", "EX-CH03-S12"]:
		var room := await _room(Contract.room_for_scene(scene_id))
		var start: Array = Contract.anchors(room.room_id)[PLAYER_ANCHOR[room.room_id]]
		var player := crew.place(scene_id, room, Vector3(start[0], start[1], start[2]))
		for frame in 4:
			await physics_frame
		_check(room.scene_context() == scene_id and not room.stage().layers.is_empty(), scene_id + " the room is staged by the crew placement")
		_check(crew.local_ids.size() == 4 and not crew.local_ids.has("ferreira"), scene_id + " the four cadets are placed; Ferreira is on Earth")
		var staged_player: Array = Contract.staged_anchors(room.room_id, scene_id)[PLAYER_ANCHOR[room.room_id]]
		_check(player.position.distance_to(Vector3(staged_player[0], staged_player[1], staged_player[2])) < 0.2, scene_id + " the player starts at the scene's own anchor")
		for id in crew.local_ids:
			var body: PlayerController = crew.bodies[id]
			if body != player:
				var at := Crew.anchor_position(room.room_id, id, scene_id)
				_check(Vector2(body.position.x - at.x, body.position.z - at.z).length() < 0.15 and absf(body.position.y - at.y) < 0.3, "%s %s placed at the scene anchor" % [scene_id, id])
			var suited: bool = scene_id == "EX-CH03-S07" and id in ["mei", "rafi"]
			_check(body.loaded_path.contains("_EVA") == suited and (body.character.find_child("Helmet", true, false) != null) == suited, "%s %s %s" % [scene_id, id, "wears the fitted EVA suit and helmet on the cold side" if suited else "is in the everyday coverall"])
		_check((room.get_node_or_null("EarthPortrait") != null) == (scene_id in ["EX-CH03-S03", "EX-CH03-S06"] or room.room_id == "LOC-03"), scene_id + " an Earth-link screen where Ferreira calls (and the garden's Earth console from CH02)")
		room.free()
		await process_frame
	crew.free()
	await process_frame

# ----------------------------------------------------------------------------------------------- capture

const SHOTS := [
	["EX-CH03-S01", "ch03_panel", "S01_red_warning"],
	["EX-CH03-S01", "ch03_board", "S01_diagnostic_board"],
	["EX-CH03-S01", "ch03_gauge", "S01_independent_gauge"],
	["EX-CH03-S02", "ch03_board", "S02_three_taps"],
	["EX-CH03-S02", "ch03_spur", "S02_garden_spur_tap"],
	["EX-CH03-S03", "ch03_board", "S03_isolation_preview"],
	["EX-CH03-S03", "ch03_repair", "S03_repair_diagram"],
	["EX-CH03-S03", "ch03_earth", "S03_ferreira_earth_link", "ferreira"],
	["EX-CH03-S04", "ch03_spur", "S04_clamp_and_boundary"],
	["EX-CH03-S05", "ch03_board", "S05_five_checks"],
	["EX-CH03-S05", "ch03_panel", "S05_warning_cleared"],
	["EX-CH03-S05", "ch03_hook", "S05_gauge_on_its_hook"],
	["EX-CH03-S06", "s06_hatch", "S06_nr_hatch"],
	["EX-CH03-S06", "s06_camera_feed", "S06_camera_feed"],
	["EX-CH03-S06", "s06_earth", "S06_ferreira_earth_link", "ferreira"],
	["EX-CH03-S06", "s06_drawing", "S06_safety_drawing"],
	["EX-CH03-S07", "s07_descent", "S07_suited_descent"],
	["EX-CH03-S07", "s07_suits", "S07_cold_side"],
	["EX-CH03-S07", "s07_trays", "S07_frozen_trays"],
	["EX-CH03-S07", "s07_chart", "S07_growth_chart"],
	["EX-CH03-S07", "s07_warm_side", "S07_warm_side_station"],
	["EX-CH03-S07", "player", "S07_player_eva", 3.74],
	["EX-CH03-S08", "s08_table", "S08_evidence_table"],
	["EX-CH03-S08", "s08_board", "S08_map_is_a_plan"],
	["EX-CH03-S09", "s09_maturity", "S09_maturity"],
	["EX-CH03-S09", "s09_bench", "S09_drydown"],
	["EX-CH03-S10", "s10_harvest", "S10_forty_two"],
	["EX-CH03-S10", "s10_vigil", "S10_vigil_photos"],
	["EX-CH03-S10", "lineage_board", "S10_alo_nameplate"],
	["EX-CH03-S11", "s11_rack", "S11_twelve_positions"],
	["EX-CH03-S11", "s11_reserve", "S11_reserve_sealed"],
	["EX-CH03-S11", "lineage_board", "S11_petal_on_board"],
	["EX-CH03-S12", "s12_tara", "S12_tara_farewell"],
	["EX-CH03-S12", "lineage_board", "S12_lineage_board"],
	["EX-CH03-S12", "s12_ledger", "S12_days_in_between"],
	["EX-CH03-S12", "s12_survey", "S12_survey_board"],
	["EX-CH03-S12", "s12_rack", "S12_october_rack"],
]

func _capture_all() -> void:
	var crew := Crew.new()
	root.add_child(crew)
	var camera := Camera3D.new()
	camera.fov = 70
	root.add_child(camera)
	var room: CampaignRoom = null
	var current := ""
	var choices := {"EX-CH01-S04-CHOICE": {"option_id": "EX-CH01-S04-OPT01"}, "EX-CH02-S06-CHOICE": {"option_id": "EX-CH02-S06-OPT01"}, "EX-CH03-S11-DEDICATION": {"option_id": "EX-CH03-S11-DEDICATION-OPT03"}}
	var moments := ["CH03-ALO-VIGIL-1", "CH03-ALO-VIGIL-2", "CH03-ALO-VIGIL-3", "CH03-ALO-VIGIL-4", "CH03-ALO-VIGIL-5", "CH03-TARA-FAREWELL"]
	for shot in SHOTS:
		var scene_id := String(shot[0])
		if scene_id != current:
			if room != null:
				room.free()
				await process_frame
			room = await _room(Contract.room_for_scene(scene_id))
			var start: Array = Contract.anchors(room.room_id)[PLAYER_ANCHOR[room.room_id]]
			crew.place(scene_id, room, Vector3(start[0], start[1], start[2]), choices, moments)
			if PLANTS.has(scene_id):
				var plants: Array = []
				for individual in PLANTS[scene_id]:
					plants.append({"individual_id": individual, "stage": PLANTS[scene_id][individual]})
				room.apply_plant_state(plants)
				room.set_door_open("garden_viewing_shutter", true)  # the photo frame looks through the pressure glazing
			current = scene_id
			for frame in 30:
				await process_frame
		var view := String(shot[1])
		crew.present_line({"speaker_id": String(shot[3]), "origin_label": "EARTH LIVE"} if shot.size() > 3 and shot[3] is String else {}, false)
		if view == "player":
			var player := crew.player
			player.follow_camera.yaw = float(shot[3])
			player.follow_camera.pitch = -0.15
			player.follow_camera.reset_placement()
			player.follow_camera.camera.current = true
			for frame in 30:
				player.follow_camera.update_camera(1.0 / 60.0, player.follow_camera.yaw, 0)
				await process_frame
		else:
			var spec: Dictionary = Contract.staged_layout(room.room_id, scene_id, choices, moments).review_views.get(view, {})
			_check(not spec.is_empty(), "capture %s has its review view %s" % [String(shot[2]), view])
			if spec.is_empty():
				continue
			camera.position = Presentation.vector(spec.from)
			camera.look_at(Presentation.vector(spec.to))
			camera.current = true
			for frame in 20:
				await process_frame
		await RenderingServer.frame_post_draw
		await _save(String(shot[2]))
		if String(shot[2]) in ["S02_three_taps", "S06_nr_hatch", "S07_cold_side", "S10_forty_two"]:
			await _time(room.room_id + " " + scene_id)
	if room != null:
		room.free()
	camera.free()
	crew.free()

func _time(label: String) -> void:
	for frame in 60:
		await process_frame
	var samples: Array[float] = []
	var previous := Time.get_ticks_usec()
	for frame in 180:
		await process_frame
		var now := Time.get_ticks_usec()
		samples.append((now - previous) / 1000.0)
		previous = now
	samples.sort()
	report.append("%s windowed frame ms with cast: p50=%.2f p95=%.2f; draw calls=%d" % [label, samples[90], samples[171], Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])

## Saves the presented frame, re-reading a blank (shader-compile) frame for up to two seconds.
func _save(id: String) -> void:
	var image := root.get_texture().get_image()
	for attempt in 120:
		if not _blank(image):
			break
		await process_frame
		await RenderingServer.frame_post_draw
		image = root.get_texture().get_image()
	_check(not _blank(image), "capture " + id + " shows a rendered frame")
	_check(image.save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/M3-3R_%s.png" % id)) == OK, "capture " + id)

func _blank(image: Image) -> bool:
	var brightest := 0.0
	for gx in 16:
		for gy in 9:
			var c := image.get_pixel(int((gx + 0.5) * image.get_width() / 16.0), int((gy + 0.5) * image.get_height() / 9.0))
			brightest = maxf(brightest, c.get_luminance())
	return brightest < 0.03

# ----------------------------------------------------------------------------------------------- helpers

func _ray(from: Vector3, to: Vector3, mask: int = 1, exclude: Array[RID] = []) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, mask, exclude)
	return root.get_world_3d().direct_space_state.intersect_ray(query)

## The ids of everything the Chapter 3 layers (ch03_*) place in a room, M3-2R's CH02 -> CH03 join screen excepted.
func _chapter3_ids(room_id: String) -> Dictionary:
	var ids := {}
	for layer in Contract.layout(room_id).get("staging", []):
		if not String(layer.get("id", "")).begins_with("ch03_") or String(layer.id) == "ch03_join_pressure_warning":
			continue
		for key in ["props", "fixtures", "chapter7_props", "prints"]:
			for item in layer.get(key, []):
				ids[String(item.get("id", ""))] = true
	return ids

## True when any surface under node uses an imported material of this name (tells the rack's planting-day and October
## variants apart: only the planted cassettes carry seeded soil).
func _has_material(node: Node, material_name: String) -> bool:
	for mesh in node.find_children("*", "MeshInstance3D", true, false):
		var instance := mesh as MeshInstance3D
		for surface in instance.mesh.get_surface_count():
			var material := instance.mesh.surface_get_material(surface)
			if material != null and String(material.resource_name) == material_name:
				return true
	return false

## Visible mesh bounds of a node in room space (far LODs and hidden helpers skipped).
func _bounds(room: CampaignRoom, node: Node) -> AABB:
	var box := AABB()
	var first := true
	var meshes := node.find_children("*", "MeshInstance3D", true, false)
	if node is MeshInstance3D:
		meshes.append(node)
	for mesh in meshes:
		if (mesh as GeometryInstance3D).visibility_range_begin > 0.0 or not mesh.is_visible_in_tree() or mesh.name == "Edge":
			continue
		if mesh.get_viewport() != room.get_viewport():
			continue  # a plant_photo print's subject lives in the print's own SubViewport world, not in the room
		var local: AABB = room.global_transform.affine_inverse() * mesh.global_transform * mesh.get_aabb()
		box = local if first else box.merge(local)
		first = false
	return box
