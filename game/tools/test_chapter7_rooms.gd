## M3-7R: every Chapter 7 scene is staged in its proper location (STORY_FULL.md scene locations, the CHAPTER_07 scene
## scripts, scene_rosters.json, doc 09) with the M3-7A shelter and uplink props and EN_Fabrication, and every join of doc 24
## §2.9 that touches Chapter 7 can play in the world. Builds the real room scenes with the real PlayerController and cast,
## then checks the mapping and rosters, stations for every scene action, navigation, collision, props resting, readable
## signs and screens, the bridge, clue and story-echo objects, per-scene light levels, seating, and that the Chapter 1 and
## Chapter 6 rooms come back exactly outside the chapter.
##   Godot --headless --path game --script res://tools/test_chapter7_rooms.gd
##   --capture (windowed) also writes production/qa/evidence/M3-7R_*.png and M3-7R_runtime.txt.
extends SceneTree

const Contract = preload("res://scripts/world/room_contract.gd")
const Presentation = preload("res://scripts/world/room_presentation.gd")
const Staging = preload("res://scripts/world/room_staging.gd")
const Gates = preload("res://scripts/missions/extended_gate_catalog.gd")
const Roster = preload("res://scripts/companions/companion_roster.gd")
const Crew = preload("res://scripts/world/campaign_crew.gd")
const C7 = preload("res://assets/props/chapter7_assets.gd")
const Player = preload("res://scenes/player/player.tscn")
const SCENE_FILES := {"LOC-01": "commons", "LOC-02": "service_rooms", "LOC-03": "garden", "LOC-04": "safe_room"}
const PLAYER_ANCHOR := {"LOC-01": "commons_player", "LOC-02": "service_player", "LOC-03": "garden_player", "LOC-04": "safe_player"}
## STORY_FULL.md / CHAPTER_07: the warning at the Mission Table (S01); the Safe Room S02-S08; the Commons network
## diagnostic and care desk (S09-S10); the fabrication bench and route simulator (S11); departure boards and loadout (S12).
const EXPECTED_ROOM := {
	"EX-CH07-S01": "LOC-01", "EX-CH07-S02": "LOC-04", "EX-CH07-S03": "LOC-04", "EX-CH07-S04": "LOC-04",
	"EX-CH07-S05": "LOC-04", "EX-CH07-S06": "LOC-04", "EX-CH07-S07": "LOC-04", "EX-CH07-S08": "LOC-04",
	"EX-CH07-S09": "LOC-01", "EX-CH07-S10": "LOC-01", "EX-CH07-S11": "LOC-02", "EX-CH07-S12": "LOC-01",
}
## Canon lines quoted word for word on staged words (exempt from the player-text patterns).
const CANON_LINES := ["EX-CH07-S01-L02", "EX-CH07-S07-L01", "EX-CH06-S09-L01"]
const ROLES := ["Kai", "Amara", "Ferreira", "Mei", "Rafi"]
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
	var line := "CHAPTER 7 ROOMS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures]
	print(line)
	report.append(line)
	if capture:
		var file := FileAccess.open("res://../production/qa/evidence/M3-7R_runtime.txt", FileAccess.WRITE)
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
		_check(roster.size() == 5, scene_id + " all five lunar occupants are in the scene (STORY_FULL continuity lock)")
		for id in roster:
			_check(String(roster[id].physical_location_id) == room_id, "%s %s is physically at %s" % [scene_id, id, room_id])
		for target in Gates.targets_for_scene(scene_id):
			_check(not Contract.station_focus(scene_id, String(target.target_id)).is_empty(), scene_id + " action has a room station: " + String(target.target_id))
	_check(Contract.room_for_scene("EX-CH06-S12") == "LOC-03" and Contract.room_for_scene("EX-CH08-S01") == "LOC-08", "neighbouring chapters keep their rooms")

# ------------------------------------------------------------------------------------------------ one scene

func _check_scene(room: CampaignRoom, scene_id: String, player: PlayerController) -> void:
	var room_id := room.room_id
	var layout := Contract.staged_layout(room_id, scene_id)
	var stage: Dictionary = room.stage()
	_check(not stage.get("layers", []).is_empty() and room.visual_root.has_node(Staging.ROOT_NAME), scene_id + " room carries its Chapter 7 staging")
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
	await _walk(player, layout, scene_id)
	for obstacle in stage.obstacles:
		var at := Presentation.vector(obstacle.position)
		var size := Presentation.vector(obstacle.size)
		_check(not _ray(at + Vector3(size.x * 0.5 + 0.15, 0, 0), at).is_empty(), scene_id + " staged furniture blocks movement: " + String(obstacle.id))
	_check_doors(room, map, spawn, scene_id)
	_check_anchors(room, map, scene_id)
	_check_staged_objects(room, layout, scene_id)
	_check_staged_text(room, map, scene_id)
	_check_bridges(room, scene_id)

func _walk(player: PlayerController, layout: Dictionary, scene_id: String) -> void:
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

## Everyone the roster puts in this room has a scene anchor on the deck, clear of furniture and of each other; in the
## Safe Room everyone not at a work anchor sits in an installed seat (doc 09: no wandering during exposure, S05-S08).
func _check_anchors(room: CampaignRoom, map: RID, scene_id: String) -> void:
	var roster := Roster.scene_roster(scene_id)
	var active := Roster.playable_actor(scene_id)
	var placed: Array[Vector3] = []
	var order := Contract.scene_order(scene_id) % 100
	for id in roster:
		if id == active:
			continue
		var at := Crew.anchor_position(room.room_id, id, scene_id)
		_check(Contract.staged_anchors(room.room_id, scene_id).keys().any(func(key): return String(key).ends_with("_" + id)), "%s %s has an authored anchor" % [scene_id, id])
		var seated := room.room_id == "LOC-04" and room.has_installed_seat_at(at)
		_check(seated or NavigationServer3D.map_get_closest_point(map, at).distance_to(at) < 0.3, "%s %s stands on walkable deck or sits in a seat %s" % [scene_id, id, str(at)])
		for other in placed:
			_check(at.distance_to(other) > 0.6, "%s %s keeps 0.6 m from the next person" % [scene_id, id])
		placed.append(at)
		if room.room_id == "LOC-04":
			_check(room.has_installed_seat_at(at) == (order >= 5), "%s %s %s" % [scene_id, id, "is seated for the storm steps" if order >= 5 else "works standing at a staged anchor"])

## Staged furniture rests on the deck, a wall, a surface or flush on a panel face, stays inside the room, and every
## large floor-standing addition has collision over its footprint.
func _check_staged_objects(room: CampaignRoom, layout: Dictionary, scene_id: String) -> void:
	var staged := room.visual_root.get_node(Staging.ROOT_NAME) as Node3D
	var half := Vector2(float(layout.bounds_m[0]), float(layout.bounds_m[1])) * 0.5
	var surfaces: Array[AABB] = []
	for node in room.visual_root.get_children() + staged.get_children():
		if node is Node3D and node.visible and node != staged and String(node.name) != "HabitatKit":
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
		_check(box.position.x >= -half.x - 0.02 and box.end.x <= half.x + 0.02 and box.position.z >= -half.y - 0.02 and box.end.z <= half.y + 0.02, scene_id + " staged object inside the room footprint: " + id)
		var base := box.position.y
		var supported := absf(base) < 0.03
		var wall := absf(box.end.z - half.y) < 0.12 or absf(box.position.z + half.y) < 0.12 or absf(box.end.x - half.x) < 0.12 or absf(box.position.x + half.x) < 0.12
		var centre := box.get_center()
		for surface in surfaces:
			if surface == box:
				continue
			if surface.end.y <= base + 0.03 and surface.end.y >= base - 0.04 and centre.x >= surface.position.x and centre.x <= surface.end.x and centre.z >= surface.position.z and centre.z <= surface.end.z:
				supported = true
			# a plate or card mounted flush on a panel's face (the valve diagram on the water wall, a note on a lid)
			var overlaps_y := box.position.y < surface.end.y and box.end.y > surface.position.y
			var flush_z := (absf(box.position.z - surface.end.z) < 0.01 or absf(box.end.z - surface.position.z) < 0.01) and box.position.x < surface.end.x and box.end.x > surface.position.x
			var flush_x := (absf(box.position.x - surface.end.x) < 0.01 or absf(box.end.x - surface.position.x) < 0.01) and box.position.z < surface.end.z and box.end.z > surface.position.z
			if overlaps_y and (flush_z or flush_x) and box.size.y < surface.size.y:
				supported = true
		_check((supported or wall) and base > -0.03, scene_id + " staged object rests on the deck, a wall, a surface or a panel face (base %.3f m): %s" % [base, id])
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

## Every staged wall label faces walkable deck, never mirrored; staged words and the M3-7A live screens use player
## language (canon dialogue quoted from the catalog is exempt).
func _check_staged_text(room: CampaignRoom, map: RID, scene_id: String) -> void:
	var staged := room.visual_root.get_node(Staging.ROOT_NAME) as Node3D
	var words: Array[String] = []
	for label in staged.find_children("*", "Label3D", true, false):
		if not label.is_visible_in_tree() or String(label.text).strip_edges().is_empty():
			continue
		words.append(String(label.text))
		if label.billboard != BaseMaterial3D.BILLBOARD_DISABLED:
			continue
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
		_check(front < 0.35, scene_id + " staged label reads from walkable deck: " + String(label.text).left(40))
		_check(not label.double_sided, scene_id + " staged label is single-sided: " + String(label.text).left(40))
		_check(not String(label.text).contains("{line}"), scene_id + " sign template is filled: " + String(label.name))
	for node in staged.get_children():
		for screen in node.get_meta("screen_text", {}).values():
			words.append(String((screen as Label).text))
			_check(not String((screen as Label).text).contains("{line}"), scene_id + " screen template is filled on " + String(node.name))
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

func _screen(staged: Node, id: String, screen: String) -> String:
	var node := staged.get_node_or_null(id)
	if node == null or not node.get_meta("screen_text", {}).has(screen):
		return ""
	return String((node.get_meta("screen_text")[screen] as Label).text)

func _part(node: Node3D, part: String) -> Node3D:
	var found := C7.parts(node, part)
	return found[0] if not found.is_empty() else null

func _practical_scale(room: CampaignRoom) -> float:
	var practical := room.get_node("RoomLighting/Practical_0") as OmniLight3D
	return practical.light_energy / float(practical.get_meta("base_energy", practical.light_energy))

## Doc 24 §2.9 rows CH06->CH07 .. CH07->CH08, §4 clue 21 and doc 09's revisit rule, scene by scene.
func _check_bridges(room: CampaignRoom, scene_id: String) -> void:
	var staged := room.visual_root.get_node(Staging.ROOT_NAME) as Node3D
	var order := Contract.scene_order(scene_id) % 100
	if room.room_id == "LOC-01":
		_check(staged.has_node("commons_seat_5") and staged.has_node("commons_mug_5"), scene_id + " five seats and five mugs at the table")
		var chair := (staged.get_node("commons_seat_5") as Node3D).position
		if order == 1:
			_check(chair.is_equal_approx(Vector3(0, 0, -1.75)), scene_id + " Ferreira's chair is at the head as the warning arrives")
		else:
			_check(chair.x > 1.9 and absf(chair.z) < 0.3, scene_id + " Ferreira's chair stands among the cadets' after she gave up the head (canon S01)")
		var diag := staged.get_node("network_diagnostic") as Node3D
		var display := _text(staged, "main_display_text")
		match order:
			1:
				var warning := _text(staged, "storm_warning_text")
				_check(warning.contains("23 JULY 2012") and warning.contains("STEREO-A") and warning.contains("COUNTERFACTUAL"), scene_id + " the warning carries its labelled 2012 source (S01 -> S02)")
				_check(["kai", "amara", "mei", "rafi"].all(func(r): return staged.has_node("observation_card_" + r)), scene_id + " the four specialists' observations lie together on the table")
				_check(display.contains(Staging.line_text("EX-CH07-S01-L02")), scene_id + " Rao confirms the labelled source live, word for word")
				_check(_screen(staged, "network_diagnostic", "Screen_Diag").contains("EARTH LINK   LIVE") and _part(diag, "IsolationKey").rotation_degrees.z == 0.0, scene_id + " every radio path passes before the storm")
			9:
				_check(display.contains("NO ANSWER") and display.contains("READING 2"), scene_id + " Earth does not answer; two separated clearance readings are pending (S08 -> S09)")
				_check(_screen(staged, "network_diagnostic", "Screen_Diag").contains("NOT TESTED") and is_equal_approx(_part(diag, "IsolationKey").rotation_degrees.z, 90.0), scene_id + " the exposed branch is still isolated and the branch tests wait for the player")
			10:
				_check(staged.has_node("bypass_diagram") and _text(staged, "bypass_diagram_text").contains("THREE ROAD REPEATERS"), scene_id + " the saved relay-bypass diagram lies on the care desk (S09 -> S10)")
				var card := _part(diag, "DataCard")
				var pivot: Array = C7.entry("PR_NetworkDiagnostic").moving_parts.DataCard
				_check(card != null and card.position.z < float(pivot[2]) - 0.04, scene_id + " the diagnostic's data card is out")
				_check(_screen(staged, "network_diagnostic", "Screen_Diag").contains("EXTERNAL FEEDTHROUGH   FAIL") and staged.has_node("fault_tag"), scene_id + " the external branch is diagnosed and labelled (doc 09 fault label)")
				_check(staged.has_node("spare_case") and _text(staged, "spare_case_text").contains("12 DEC 2046"), scene_id + " the December spare waits sealed in its case (S10 -> S11)")
				_check(_text(staged, "outbox_text").contains("QUEUED FOR EARTH"), scene_id + " reports queue for Earth and cannot send (clue 22 setup)")
				_check(display.contains("THREE DATED MAINTENANCE GATES"), scene_id + " the stable care board is on the main display")
				var case := staged.get_node("founder_case") as Node3D
				_check(C7.count_seeds(case) == 30 and is_equal_approx(_part(case, "Latch").rotation_degrees.x, 0.0), scene_id + " the founder case is checked latched, 15 + 15, without opening")
			12:
				_check(_text(staged, "board_rover").contains("FERREIRA\nKAI\nRAFI") and _text(staged, "board_aurora").contains("MEI\nAMARA"), scene_id + " five names face two destination boards")
				_check(not staged.has_node("spare_case") and staged.has_node("packed_case") and _text(staged, "packed_case_text").contains("PACKED"), scene_id + " the controller Kai labelled is packed (S11 -> S12)")
				_check(_text(staged, "route_card_text").contains("THREE ROAD REPEATERS") and staged.has_node("repeater_case_3"), scene_id + " the three-site route and its repeaters are packed (S11 -> S12)")
				for id in ["checklist_rover_text", "checklist_aurora_text"]:
					var sheet := _text(staged, id)
					_check(sheet.contains("8 APR 2047, 00:00") and sheet.contains("SMALL GUIDE LIGHT: IN THE PLAN"), scene_id + " duplicate checklist dated 8 Apr 00:00 with the guide light in the plan (CH07 -> CH08): " + id)
				_check(_text(staged, "home_ledger_text").contains("33 H") and _text(staged, "home_ledger_text").contains("LAST 3 H"), scene_id + " the home-night ledger counts two, then five")
				_check(["helmet_1", "helmet_2", "helmet_3"].all(func(h): return staged.has_node(h)), scene_id + " three travellers, three helmets")
		_check((staged.has_node("care_desk")) == (order >= 10), scene_id + " the care desk stands from the stable-care interval on")
	elif room.room_id == "LOC-04":
		_check(not _visible_sign(room, "KAI   AMARA   MEI   RAFI") and _text(staged, "roster_names").contains("FERREIRA"), scene_id + " the roll-call board names five")
		_check(staged.has_node("april_card") and _text(staged, "april_card_text").contains("11 APR 2046"), scene_id + " April's four-name card is pinned beside the roster")
		var board := staged.get_node("shelter_diagram") as Node3D
		var slot := {"Kai": "Seat_1", "Amara": "Seat_2", "Ferreira": "Seat_3", "Mei": "Seat_4", "Rafi": "Seat_5"} if order >= 3 else {"Kai": "Park_1", "Amara": "Park_2", "Mei": "Park_3", "Rafi": "Park_4", "Ferreira": "Park_5"}
		for role in ROLES:
			var marker := _part(board, "SeatMarker_" + role)
			_check(marker != null and marker.position.is_equal_approx(C7.socket_position("PR_ShelterDiagram", slot[role])), scene_id + " %s's seat marker on %s (S02 -> S03: five markers on the diagram)" % [role, slot[role]])
		var shown := ["Kai", "Amara", "Ferreira", "Mei", "Rafi"].filter(func(r): return board.find_children("Label_" + r, "Label3D", true, false).size() == 1)
		_check(shown.size() == 5, scene_id + " every marker carries its name")
		_check(order < 3 or _text(staged, "plan_sheet_text").contains("AFTER THE STEP 6 SAMPLE") or order >= 7, scene_id + " the plan states when the borrowed water returns (S03 -> S04)")
		if order >= 4:
			var valve := staged.get_node("valve_diagram") as Node3D
			_check(_part(valve, "WaterCell_4").visible and not _part(valve, "WaterCell_5").visible, scene_id + " four water units held in the wall")
			_check(is_equal_approx(_part(valve, "ReturnSelector").rotation_degrees.z, 35.0) and _screen(staged, "valve_diagram", "Screen_Return").contains("AFTER THE STEP 6 SAMPLE"), scene_id + " the return is set after the step-6 sample")
			var case := staged.get_node("seed_case") as Node3D
			_check(C7.count_seeds(case) == 30, scene_id + " the founder case holds 15 + 15 seeds")
			_check(is_equal_approx(_part(case, "Latch").rotation_degrees.x, 0.0) == (order >= 5), scene_id + " the case is latched from S05 (S04 -> S05: the latched 15 + 15 case)")
		else:
			_check(not staged.has_node("valve_diagram") and not staged.has_node("seed_case"), scene_id + " valve plate and founder case arrive with S04")
		var closed := order >= 6 and order <= 8
		_check(_text(staged, "hatch_latch_text").ends_with("CLOSED" if closed else "OPEN") and _text(staged, "hatch_seal_text").ends_with("CLOSED" if closed else "OPEN"), scene_id + " both hatch indications agree (S05 -> S06)")
		var telemetry := _screen(staged, "telemetry", "Screen_Systems")
		match order:
			6:
				_check(telemetry.contains("STEP 1 OF 6"), scene_id + " the first wave on the telemetry")
			7:
				_check(telemetry.contains("FOUR STEPS LEFT"), scene_id + " 'Four steps left' when the log ends (S07 -> S08)")
				_check(_screen(staged, "archive_player", "Screen_Archive").contains(Staging.line_text("EX-CH07-S07-L01")), scene_id + " the last log's caption quotes Noor word for word (clue 21)")
				var player := (staged.get_node("archive_player") as Node3D).position
				for id in ["first_seed_packet", "signed_page", "founder_ledger"]:
					_check(staged.has_node(id) and (staged.get_node(id) as Node3D).position.distance_to(player) < 1.5, scene_id + " the log lies beside the " + id)
				_check(staged.has_node("alo_petal") and (staged.get_node("alo_petal") as Node3D).position.distance_to((staged.get_node("seed_case") as Node3D).position) < 0.5, scene_id + " Alo's pressed petal rests by the founder case")
			8:
				_check(telemetry.contains("PEAK ON THE CHART"), scene_id + " the peak arrives on the chart")
		_check(staged.has_node("archive_player") and staged.has_node("telemetry"), scene_id + " archive player and local telemetry are installed")
		var scale: float = {6: 0.5, 7: 0.42, 8: 0.5}.get(order, 1.0)
		_check(absf(_practical_scale(room) - scale) < 0.001, scene_id + " practicals at the storm plan level x%.2f" % scale)
		var guide := staged.get_node("guide_strip_west") as MeshInstance3D
		_check(((guide.material_override as StandardMaterial3D).shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED) == closed, scene_id + " low amber guide strips glow during the storm steps")
	elif room.room_id == "LOC-02":
		var bench := staged.get_node("fabrication_bench") as Node3D
		var spare := bench.get_node_or_null("spare_controller") as Node3D
		_check(spare != null and spare.position.is_equal_approx(C7.socket_position("EN_Fabrication_Bench", "Socket_Controller")), scene_id + " the December spare sits in the bench cradle")
		_check(staged.has_node("spare_case_open") and _text(staged, "kai_note_text").contains("KAI"), scene_id + " Kai's note is still clipped inside the opened case (S10 -> S11)")
		var sim := staged.get_node("route_simulator") as Node3D
		for k in 3:
			_check(_part(sim, "RepeaterPin_%d" % (k + 1)).position.is_equal_approx(C7.socket_position("EN_Fabrication_RouteSimulator", "PinPark_%d" % (k + 1))), scene_id + " repeater pin %d waits parked" % (k + 1))
		_check(_screen(staged, "fabrication_bench", "Screen_Echo").contains("BENCH RESULT ONLY") and _screen(staged, "route_simulator", "Screen_Route").contains("NOT FIELD PROOF"), scene_id + " a bench pass is not field verification")
		_check(staged.has_node("guide_branch") and staged.has_node("a42_panel") and staged.has_node("hand_light_in_locker") and not staged.has_node("eclipse_board"), scene_id + " Chapter 6's guide light, test panel and lamp clip stay; the eclipse board is gone")

func _visible_sign(room: CampaignRoom, text: String) -> bool:
	for node in room.visual_root.get_children():
		if node is Label3D and node.text == text and node.visible:
			return true
	return false

# ---------------------------------------------------------------------------------------- re-staging, echoes

## One room instance re-staged scene after scene ends exactly as built: Chapter 1 has no staging and its own navigation
## and signs, Chapter 6 gets its own Commons back, and the Safe Room keeps its storm equipment after the storm.
func _check_restaging() -> void:
	var safe := await _room("LOC-04")
	var base_polys := (safe.navigation_root.get_node("NavigationRegion") as NavigationRegion3D).navigation_mesh.get_polygon_count()
	var base_focus := safe.focus_root.get_child_count()
	for scene_id in ["EX-CH07-S06", "EX-CH01-S08", "EX-CH07-S02", "EX-CH07-S07"]:
		safe.set_scene_context(scene_id)
		await process_frame
		var region := safe.navigation_root.get_node("NavigationRegion") as NavigationRegion3D
		_check(safe.navigation_root.get_child_count() == 1, scene_id + " re-staging keeps one navigation map")
		if scene_id == "EX-CH01-S08":
			_check(safe.stage().layers.is_empty() and not safe.visual_root.has_node(Staging.ROOT_NAME), "the Chapter 1 Safe Room shows no Chapter 7 staging after re-staging")
			_check(region.navigation_mesh.get_polygon_count() == base_polys and safe.focus_root.get_child_count() == base_focus, "Chapter 1 Safe Room navigation and stations return exactly")
			_check(_visible_sign(safe, "KAI   AMARA   MEI   RAFI"), "Chapter 1 roll-call board names its four again")
			_check(is_equal_approx((safe.get_node("RoomLighting/Practical_0") as OmniLight3D).light_energy, 0.7), "Chapter 1 Safe Room light level restored")
		elif scene_id == "EX-CH07-S07":
			_check(safe.focus_root.has_node("Focus_safe_archive_player") and safe.focus_root.get_child_count() > base_focus, "re-staged Chapter 7 stations return")
	safe.free()
	await process_frame
	var commons := await _room("LOC-01")
	for scene_id in ["EX-CH07-S12", "EX-CH06-S06", "EX-CH07-S10", "EX-CH01-S01"]:
		commons.set_scene_context(scene_id)
		await process_frame
		var staged := commons.visual_root.get_node_or_null(Staging.ROOT_NAME)
		if scene_id == "EX-CH06-S06":
			_check(staged.has_node("eclipse_monitor") and not staged.has_node("network_diagnostic") and not staged.has_node("loadout_table_top"), "Chapter 6 gets its eclipse desk back, without Chapter 7's equipment")
			_check((staged.get_node("commons_seat_5") as Node3D).position.is_equal_approx(Vector3(0, 0, -1.75)), "in Chapter 6 Ferreira's chair is still at the head")
		elif scene_id == "EX-CH07-S10":
			_check(staged.has_node("care_desk") and not staged.has_node("loadout_table_top") and not staged.has_node("eclipse_monitor"), "re-staged S10 shows the care desk only")
		elif scene_id == "EX-CH01-S01":
			_check(staged == null and commons.stage().layers.is_empty(), "the Chapter 1 Commons is unchanged")
	commons.free()
	await process_frame
	var service := await _room("LOC-02")
	service.set_scene_context("EX-CH07-S11")
	await process_frame
	service.set_scene_context("EX-CH01-S05")
	await process_frame
	_check(not service.visual_root.has_node(Staging.ROOT_NAME) and (service.visual_root.get_node("PR_HandLight") as Node3D).visible, "the Chapter 1 service rooms are unchanged after the fabrication bench")
	service.free()
	await process_frame

## Doc 24 §5.2: D9's record stays under Ferreira's mug wherever her place is, D10 shows its own object, D12 packs Kai's
## copy of the observation he sent home; nothing appears without its recorded option.
func _check_echoes() -> void:
	var commons := await _room("LOC-01")
	commons.set_scene_context("EX-CH07-S10")
	await process_frame
	var staged := commons.visual_root.get_node(Staging.ROOT_NAME)
	_check(not staged.has_node("ferreira_record") and not staged.has_node("outbox_photo_strip") and not staged.has_node("n_holder_card"), "no echo objects without a recorded choice")
	for option in ["EX-CH05-S05-OPT01", "EX-CH05-S05-OPT02"]:
		for scene_id in ["EX-CH07-S01", "EX-CH07-S10"]:
			commons.set_story_choices({"EX-CH05-S05-CHOICE": {"option_id": option}})
			commons.set_scene_context(scene_id)
			await process_frame
			staged = commons.visual_root.get_node(Staging.ROOT_NAME)
			var mug := _bounds(commons, staged.get_node("commons_mug_5"))
			var record := _bounds(commons, staged.get_node("ferreira_record"))
			_check(record.has_point(Vector3(mug.get_center().x, record.get_center().y, mug.get_center().z)), "D9 %s: her mug stands on the record in %s" % [option, scene_id])
	commons.set_story_choices({"EX-CH05-S11-CHOICE": {"option_id": "EX-CH05-S11-OPT01"}})
	await process_frame
	staged = commons.visual_root.get_node(Staging.ROOT_NAME)
	_check(_text(staged, "outbox_photo_strip").contains("WHAT GROWS NEXT") and not staged.has_node("n_holder_card"), "D10 'Would you like to see what grows next?' queues Mei's photo strip for N.")
	commons.set_story_choices({"EX-CH05-S11-CHOICE": {"option_id": "EX-CH05-S11-OPT02"}})
	commons.set_scene_context("EX-CH07-S12")
	await process_frame
	staged = commons.visual_root.get_node(Staging.ROOT_NAME)
	_check(staged.has_node("n_holder_card") and not staged.has_node("outbox_photo_strip") and not staged.has_node("kai_family_copy"), "D10 'We kept a place for your work.' keeps the N. holder at the table; no D12 copy without its choice")
	for option in {"EX-CH06-S08-OPT01": "THE RING DIAGRAM", "EX-CH06-S08-OPT02": "THE PROTECTED-SERVICE PLAN"}.keys():
		var words: String = {"EX-CH06-S08-OPT01": "THE RING DIAGRAM", "EX-CH06-S08-OPT02": "THE PROTECTED-SERVICE PLAN"}[option]
		commons.set_story_choices({"EX-CH06-S08-CHOICE": {"option_id": option}})
		await process_frame
		staged = commons.visual_root.get_node(Staging.ROOT_NAME)
		_check(_text(staged, "kai_family_copy_text").contains(words), "D12 %s: Kai packs his family's copy for the rover" % option)
	commons.free()
	await process_frame

## The real cast placement: the room is staged before anyone stands in it, bodies stand at the scene anchors, and in the
## Safe Room the crew works standing during preparation and sits in the five seats for the storm steps.
func _check_crew() -> void:
	var crew := Crew.new()
	root.add_child(crew)
	for scene_id in ["EX-CH07-S01", "EX-CH07-S02", "EX-CH07-S06", "EX-CH07-S11", "EX-CH07-S12"]:
		var room := await _room(Contract.room_for_scene(scene_id))
		var start: Array = Contract.anchors(room.room_id)[PLAYER_ANCHOR[room.room_id]]
		var player := crew.place(scene_id, room, Vector3(start[0], start[1], start[2]))
		for frame in 4:
			await physics_frame
		_check(room.scene_context() == scene_id and not room.stage().layers.is_empty(), scene_id + " the room is staged by the crew placement")
		_check(crew.local_ids.size() == 5, scene_id + " all five are placed")
		for id in crew.local_ids:
			var body: PlayerController = crew.bodies[id]
			if body == player:
				continue
			var at := Crew.anchor_position(room.room_id, id, scene_id)
			_check(Vector2(body.position.x - at.x, body.position.z - at.z).length() < 0.15, "%s %s placed at the scene anchor" % [scene_id, id])
			if room.room_id == "LOC-04":
				_check(body.foot_ik_enabled == (scene_id == "EX-CH07-S02"), "%s %s %s" % [scene_id, id, "stands at work" if scene_id == "EX-CH07-S02" else "sits in an installed seat"])
		_check(room.get_node_or_null("CrewSeats") == null, scene_id + " no stand-in benches")
		room.free()
		await process_frame
	crew.free()
	await process_frame

# ----------------------------------------------------------------------------------------------- capture

const SHOTS := [
	["EX-CH07-S01", "ch07_table", "S01_mission_table"],
	["EX-CH07-S01", "ch07_warning", "S01_shared_warning"],
	["EX-CH07-S01", "ch07_main_display", "S01_earth_desk"],
	["EX-CH07-S02", "ch07_shelter", "S02_safe_room"],
	["EX-CH07-S02", "ch07_west_wall", "S02_shelter_diagram"],
	["EX-CH07-S02", "ch07_roll_call", "S02_roll_call_board"],
	["EX-CH07-S03", "ch07_west_wall", "S03_five_markers"],
	["EX-CH07-S03", "ch07_forecast_table", "S03_planning_table"],
	["EX-CH07-S04", "ch07_water_wall", "S04_water_wall"],
	["EX-CH07-S04", "ch07_seed_case", "S04_seed_case"],
	["EX-CH07-S05", "player", "S05_player", 3.14159],
	["EX-CH07-S06", "ch07_shelter", "S06_first_wave"],
	["EX-CH07-S06", "ch07_west_wall", "S06_hatch_agrees"],
	["EX-CH07-S07", "ch07_forecast_table", "S07_last_log"],
	["EX-CH07-S07", "ch07_archive", "S07_archive_close"],
	["EX-CH07-S08", "ch07_forecast_table", "S08_peak"],
	["EX-CH07-S09", "ch07_main_display", "S09_no_answer"],
	["EX-CH07-S09", "ch07_diagnostic", "S09_diagnostic"],
	["EX-CH07-S10", "ch07_care_desk", "S10_care_desk"],
	["EX-CH07-S10", "ch07_diagnostic", "S10_fault_label"],
	["EX-CH07-S11", "ch07_bench", "S11_fabrication_bench"],
	["EX-CH07-S11", "ch07_simulator", "S11_route_simulator"],
	["EX-CH07-S11", "ch07_spare_case", "S11_kai_note"],
	["EX-CH07-S12", "ch07_departure", "S12_departure_boards"],
	["EX-CH07-S12", "ch07_loadout", "S12_rover_loadout"],
	["EX-CH07-S12", "ch07_table", "S12_chair_off_the_head"],
]

func _capture_all() -> void:
	var crew := Crew.new()
	root.add_child(crew)
	var camera := Camera3D.new()
	camera.fov = 70
	root.add_child(camera)
	var room: CampaignRoom = null
	var current := ""
	var choices := {"EX-CH05-S05-CHOICE": {"option_id": "EX-CH05-S05-OPT02"}, "EX-CH05-S11-CHOICE": {"option_id": "EX-CH05-S11-OPT02"}, "EX-CH06-S08-CHOICE": {"option_id": "EX-CH06-S08-OPT01"}}
	for shot in SHOTS:
		var scene_id := String(shot[0])
		if scene_id != current:
			if room != null:
				room.free()
				await process_frame
			room = await _room(Contract.room_for_scene(scene_id))
			var start: Array = Contract.anchors(room.room_id)[PLAYER_ANCHOR[room.room_id]]
			crew.place(scene_id, room, Vector3(start[0], start[1], start[2]), choices)
			current = scene_id
			for frame in 30:
				await process_frame
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
			var spec: Dictionary = Contract.staged_layout(room.room_id, scene_id, choices).review_views.get(view, {})
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
		if String(shot[2]) in ["S01_mission_table", "S06_first_wave", "S07_last_log", "S11_fabrication_bench", "S12_departure_boards"]:
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
	_check(image.save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/M3-7R_%s.png" % id)) == OK, "capture " + id)

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
		var local: AABB = room.global_transform.affine_inverse() * mesh.global_transform * mesh.get_aabb()
		box = local if first else box.merge(local)
		first = false
	return box
