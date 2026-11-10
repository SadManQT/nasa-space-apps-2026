## M3-6R: every Chapter 6 scene is staged in its proper location (STORY_FULL.md scene locations, the CHAPTER_06 scene
## scripts, doc 09) with the M3-6A eclipse props, and every join of doc 24 §2.9 that touches Chapter 6 can play in
## the world. Builds the real room scenes with the real PlayerController and cast, then checks the mapping and
## rosters, stations for every scene action, navigation, collision, props resting, readable signs, the bridge, clue
## and story-echo objects, per-scene light levels, and that the Chapter 1 rooms are untouched outside the chapter.
##   Godot --headless --path game --script res://tools/test_chapter6_rooms.gd
##   --capture (windowed) also writes production/qa/evidence/M3-6R_*.png and M3-6R_runtime.txt.
extends SceneTree

const Contract = preload("res://scripts/world/room_contract.gd")
const Presentation = preload("res://scripts/world/room_presentation.gd")
const Staging = preload("res://scripts/world/room_staging.gd")
const Gates = preload("res://scripts/missions/extended_gate_catalog.gd")
const Roster = preload("res://scripts/companions/companion_roster.gd")
const Crew = preload("res://scripts/world/campaign_crew.gd")
const Props = preload("res://assets/props/eclipse_power/eclipse_props.gd")
const Player = preload("res://scenes/player/player.tscn")
const SCENE_FILES := {"LOC-01": "commons", "LOC-02": "service_rooms", "LOC-03": "garden"}
const PLAYER_ANCHOR := {"LOC-01": "commons_player", "LOC-02": "service_player", "LOC-03": "garden_player"}
## STORY_FULL.md scene locations: power room S01-S05, S10-S11 (the debrief at the board, SC-0605); the eclipse desk
## and Mission Table S06-S09 (SC-0603/0604); the monitoring calendar and garden S12.
const EXPECTED_ROOM := {
	"EX-CH06-S01": "LOC-02", "EX-CH06-S02": "LOC-02", "EX-CH06-S03": "LOC-02", "EX-CH06-S04": "LOC-02",
	"EX-CH06-S05": "LOC-02", "EX-CH06-S06": "LOC-01", "EX-CH06-S07": "LOC-01", "EX-CH06-S08": "LOC-01",
	"EX-CH06-S09": "LOC-01", "EX-CH06-S10": "LOC-02", "EX-CH06-S11": "LOC-02", "EX-CH06-S12": "LOC-03",
}
## "Mei has not watched the power rehearsal; she has been checking plants" (EX-CH06-S06); SC-0605's cast has no Mei.
const MEI_ELSEWHERE := {"EX-CH06-S01": "LOC-03", "EX-CH06-S02": "LOC-03", "EX-CH06-S03": "LOC-03", "EX-CH06-S05": "LOC-03", "EX-CH06-S10": "LOC-01"}
const NOOR_LINE := "EX-CH06-S09-L01"
var checks := 0
var failures := 0
var capture := false
var report: Array[String] = []
var _patterns: Array[RegEx] = []

func _init() -> void:
	# doc 25 §8.1 player-text patterns (test_player_text.gd): no internal ids or engineering verbs on any staged sign.
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
	var line := "CHAPTER 6 ROOMS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures]
	print(line)
	report.append(line)
	if capture:
		var file := FileAccess.open("res://../production/qa/evidence/M3-6R_runtime.txt", FileAccess.WRITE)
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
		var active := Roster.playable_actor(scene_id)
		_check(String(roster[active].physical_location_id) == room_id, scene_id + " playable actor stands in the scene's room")
		for id in roster:
			var expected: String = MEI_ELSEWHERE.get(scene_id, room_id) if id == "mei" else room_id
			_check(String(roster[id].physical_location_id) == expected, "%s %s is physically at %s" % [scene_id, id, expected])
		# every action of the scene happens at a named station of that room
		for target in Gates.targets_for_scene(scene_id):
			var station := Contract.station_focus(scene_id, String(target.target_id))
			_check(not station.is_empty(), scene_id + " action has a room station: " + String(target.target_id))
	# the chapter before and after keep their own mapping
	_check(Contract.room_for_scene("EX-CH05-S12") == "LOC-03" and Contract.room_for_scene("EX-CH07-S01") == "LOC-01", "neighbouring chapters keep their rooms")

# ------------------------------------------------------------------------------------------------ one scene

func _check_scene(room: CampaignRoom, scene_id: String, player: PlayerController) -> void:
	var room_id := room.room_id
	var layout := Contract.staged_layout(room_id, scene_id)
	var stage: Dictionary = room.stage()
	_check(not stage.get("layers", []).is_empty() and room.visual_root.has_node(Staging.ROOT_NAME), scene_id + " room carries its Chapter 6 staging")
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
	# every gate target and every station is a real, reachable, visible focus node
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
	_check_anchors(room, layout, map, scene_id)
	_check_staged_objects(room, layout, scene_id)
	_check_staged_text(room, map, scene_id)
	await _check_bridges(room, scene_id)

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

## Everyone the roster puts in this room has a scene anchor on the deck, clear of furniture and of each other.
func _check_anchors(room: CampaignRoom, layout: Dictionary, map: RID, scene_id: String) -> void:
	var roster := Roster.scene_roster(scene_id)
	var active := Roster.playable_actor(scene_id)
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

## Staged furniture rests on the deck, a wall or another surface, stays inside the room, and every large
## floor-standing addition has collision over its footprint.
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
			# a plate, card or clip mounted flush on a panel's face (the Chapter 3 lineage board's petal and nameplates,
			# which stay; the same rule as test_chapter7_rooms.gd)
			var overlaps_y := box.position.y < surface.end.y and box.end.y > surface.position.y
			var flush_z := (absf(box.position.z - surface.end.z) < 0.01 or absf(box.end.z - surface.position.z) < 0.01) and box.position.x < surface.end.x and box.end.x > surface.position.x
			var flush_x := (absf(box.position.x - surface.end.x) < 0.01 or absf(box.end.x - surface.position.x) < 0.01) and box.position.z < surface.end.z and box.end.z > surface.position.z
			if overlaps_y and (flush_z or flush_x) and box.size.y < surface.size.y:
				supported = true
		_check((supported or wall) and base > -0.03, scene_id + " staged object rests on the deck, a wall or a surface (base %.3f m): %s" % [base, id])
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

## Every staged wall label (signs and the M3-6A plates) faces walkable deck, never mirrored, and staged words use
## player language (canon dialogue quoted from the catalog is exempt).
func _check_staged_text(room: CampaignRoom, map: RID, scene_id: String) -> void:
	var staged := room.visual_root.get_node(Staging.ROOT_NAME) as Node3D
	var canon := Staging.line_text(NOOR_LINE)
	for label in staged.find_children("*", "Label3D", true, false):
		if not label.is_visible_in_tree() or label.billboard != BaseMaterial3D.BILLBOARD_DISABLED or String(label.text).strip_edges().is_empty():
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
		if label.get_parent() == staged:
			_check(not label.double_sided, scene_id + " staged sign is single-sided: " + String(label.text).left(40))
		var words := String(label.text).replace(canon, "")
		for regex in _patterns:
			_check(regex.search(words) == null, scene_id + " staged words stay in player language: " + String(label.text).left(40))
	for node in staged.get_children():
		if node is Label3D:
			_check(not String(node.text).contains("{line}"), scene_id + " sign template is filled: " + String(node.name))

# ------------------------------------------------------------------------------------------------- the joins

## Doc 24 §2.9 rows CH05->CH06 .. CH06->CH07, §4 clue 20 and the light direction of §2.6, scene by scene.
func _check_bridges(room: CampaignRoom, scene_id: String) -> void:
	var staged := room.visual_root.get_node(Staging.ROOT_NAME) as Node3D
	var order := Contract.scene_order(scene_id) % 100
	if room.room_id == "LOC-02":
		var branch := staged.get_node("guide_branch") as Node3D
		_check(Props.nodes_named(branch, "MarkerTape").all(func(n): return (n as Node3D).visible), scene_id + " Kai's marker tape is on the guide-light branch (CH05 -> CH06)")
		_check(bool(branch.get_meta("light_on", false)), scene_id + " the guide light is on")
		var label := Props.label(branch, "Branch")
		_check(label != null and label.visible == (order >= 5), scene_id + " branch label appears once Kai labels it in S04 (S04 -> S05)")
		_check(not (room.visual_root.get_node("PR_HandLight") as Node3D).visible, scene_id + " the Chapter 1 bench spot is empty: the lamp lives in its clip")
		_check(staged.has_node("hand_light_in_locker") == (order == 1), scene_id + " hand light is in its clip only before Kai clips it on (S01 -> S02, S11 -> S12)")
		_check(room.stage().carried.has("kai") == (order >= 2 and order <= 11), scene_id + " the charged lamp rides on Kai from S02 to S11")
		var board := staged.get_node("eclipse_board") as Node3D
		var cards := board.find_children("PR_SegmentCard_*", "Node3D", true, false).filter(func(n): return String(n.get_meta("eclipse_prop", "")) == "PR_SegmentCard")
		var tags := board.find_children("PR_ServiceTag_*", "Node3D", true, false).filter(func(n): return String(n.get_meta("eclipse_prop", "")) == "PR_ServiceTag")
		_check(cards.size() == 5, scene_id + " five segment cards on the board (S02 -> S03)")
		_check((tags.size() > 0) == (order >= 4), scene_id + " the accepted plan is on the board from S04")
		var forecast: Label = board.get_meta("text_screens", {}).get("Forecast")
		_check(forecast != null and forecast.text.contains("7 UNITS") == (order >= 4), scene_id + " forecast strip shows the seven-unit plan once agreed (S03 -> S04)")
		var panel := staged.get_node("a42_panel") as Node3D
		var expected_state: String = {10: "f2_tripped", 11: "f2_restored"}.get(order, "normal")
		_check(String(panel.get_meta("eclipse_state", "")) == expected_state, scene_id + " protected-bus panel shows " + expected_state)
		_check(Props.lamp_state(panel, "Air") == "ok" and Props.lamp_state(panel, "Heat") == "ok" and Props.lamp_state(panel, "Guide") == "ok", scene_id + " protected essentials stay on")
		var floods := staged.get_node("flood_west") as Node3D
		_check(bool(floods.get_meta("light_on", false)) == (order < 10), scene_id + " decorative floods shed during the eclipse plan")
		var repeater := staged.get_node("repeater_monitor") as Node3D
		var screen = repeater.get_meta("monitor_screen") if repeater.has_meta("monitor_screen") else null
		if order == 10:
			_check(screen != null and screen.mode == "no_signal", scene_id + " the view screen drops (F2 no signal)")
		elif order == 11:
			_check(screen != null and screen.mode == "live" and screen.filter_in, scene_id + " the camera image returns (S10 -> S11)")
		else:
			_check(screen == null, scene_id + " camera repeater stays dark before the camera is protected")
		var practical := room.get_node("RoomLighting/Practical_0") as OmniLight3D
		var base_energy := float(practical.get_meta("base_energy", practical.light_energy))
		var scale: float = {10: 0.18, 11: 0.55}.get(order, 1.0)
		_check(absf(practical.light_energy - base_energy * scale) < 0.001, scene_id + " practicals at the scene's plan level x%.2f" % scale)
	elif room.room_id == "LOC-01":
		_check(staged.has_node("commons_seat_5") and staged.has_node("commons_mug_5"), scene_id + " five seats and five mugs at the table")
		var monitor := staged.get_node("eclipse_monitor") as Node3D
		var screen = monitor.get_meta("monitor_screen") if monitor.has_meta("monitor_screen") else null
		_check(screen != null and screen.filter_in and screen.mode == "live", scene_id + " filtered camera live with its solar filter in (S06 -> S07)")
		if order == 7:
			await create_timer(1.0).timeout
			_check(screen.phase > 0.1 and screen.phase < 0.5, scene_id + " the eclipse advances toward the ring on the monitor")
		var log_text := (staged.get_node("message_log_text") as Label3D).text
		_check(log_text.contains(Staging.line_text(NOOR_LINE)) == (order == 9), scene_id + " Noor's text arrives in the message log word for word only in S09 (S08 -> S09, clue 20)")
		_check(staged.has_node("ring_frame_print") == (order >= 8), scene_id + " the held ring frame is pinned once the ring is logged")
		var practical := room.get_node("RoomLighting/Practical_0") as OmniLight3D
		var dim := order >= 7 and order <= 9
		_check(absf(practical.light_energy - float(practical.get_meta("base_energy", practical.light_energy)) * (0.35 if dim else 1.0)) < 0.001, scene_id + " Commons practicals dim only while the eclipse lasts")
	elif room.room_id == "LOC-03":
		_check(not (room.visual_root.get_node("PL_Tara_Bloom") as Node3D).visible and not (room.visual_root.get_node("PL_Alo_Bud") as Node3D).visible, scene_id + " Alo and Tara are records now, not living plants")
		_check(staged.has_node("PL_Cotton_Young"), scene_id + " cotton grows in Tara's bay")
		var cotton := _bounds(room, staged.get_node("PL_Cotton_Young"))
		var enclosure := _bounds(room, room.visual_root.get_node("tara_enclosure"))
		_check(enclosure.encloses(cotton), scene_id + " cotton stays inside its enclosure")
		_check(staged.has_node("active_region_print") and String((staged.get_node("active_region_print/Caption") as Label3D).text).contains("ACTIVE REGION"), scene_id + " the active-region image is pinned on the calendar (CH06 -> CH07)")
		var focus := room.focus_root.get_node("Focus_garden_tara_bay")
		_check(String(focus.get_meta("focus_label")) == "Cotton in Tara's bay", scene_id + " Tara's bay is named for what grows there now")

# ---------------------------------------------------------------------------------------- re-staging, echoes

## One room instance re-staged scene after scene ends exactly as built: Chapter 1 has no staging and its own
## navigation, and Chapter 7 keeps what Chapter 6 left (props accumulate).
func _check_restaging() -> void:
	var room := await _room("LOC-02")
	var base_polys := (room.navigation_root.get_node("NavigationRegion") as NavigationRegion3D).navigation_mesh.get_polygon_count()
	var base_focus := room.focus_root.get_child_count()
	for scene_id in ["EX-CH06-S01", "EX-CH06-S10", "EX-CH01-S05", "EX-CH06-S11", "EX-CH07-S11"]:
		room.set_scene_context(scene_id)
		await process_frame
		var region := room.navigation_root.get_node("NavigationRegion") as NavigationRegion3D
		_check(room.navigation_root.get_child_count() == 1, scene_id + " re-staging keeps one navigation map")
		if scene_id == "EX-CH01-S05":
			_check(room.stage().layers.is_empty() and not room.visual_root.has_node(Staging.ROOT_NAME), "Chapter 1 shows no Chapter 6 staging after re-staging")
			_check(region.navigation_mesh.get_polygon_count() == base_polys and room.focus_root.get_child_count() == base_focus, "Chapter 1 navigation and stations return exactly")
			_check((room.visual_root.get_node("PR_HandLight") as Node3D).visible, "Chapter 1 hand light is back on its bench spot")
			_check(is_equal_approx((room.get_node("RoomLighting/Practical_0") as OmniLight3D).light_energy, 0.7), "Chapter 1 light level restored")
		if scene_id == "EX-CH07-S11":
			var staged := room.visual_root.get_node(Staging.ROOT_NAME)
			_check(staged.has_node("guide_branch") and staged.has_node("a42_panel") and not staged.has_node("eclipse_board"), "Chapter 7 keeps the guide light and test panel, not the eclipse board")
			_check(staged.has_node("hand_light_in_locker"), "the lamp is back in its clip after S11")
	room.free()
	await process_frame
	var garden := await _room("LOC-03")
	garden.set_scene_context("EX-CH01-S12")
	var chapter1 := garden.visual_root.get_node_or_null(Staging.ROOT_NAME)
	_check(garden.stage().layers == ["ch01_nameplates_at_plants"] and chapter1 != null and chapter1.get_children().map(func(node): return String(node.name)) == ["alo_holder", "tara_holder"] and (garden.visual_root.get_node("PL_Tara_Bloom") as Node3D).visible, "the Chapter 1 garden shows only its two plant nameplates")
	garden.free()
	await process_frame

## Doc 24 §5.2: D9 and D10 objects appear only for their recorded option, D11 moves who stands at Kai's shoulder.
func _check_echoes() -> void:
	var commons := await _room("LOC-01")
	commons.set_scene_context("EX-CH06-S06")
	await process_frame
	var staged := commons.visual_root.get_node(Staging.ROOT_NAME)
	_check(not staged.has_node("ferreira_record") and _n_holder("EX-CH06-S06", {}).is_empty(), "no echo objects without a recorded choice")
	commons.set_story_choices({"EX-CH05-S05-CHOICE": {"option_id": "EX-CH05-S05-OPT02"}, "EX-CH05-S11-CHOICE": {"option_id": "EX-CH05-S11-OPT02"}})
	await process_frame
	staged = commons.visual_root.get_node(Staging.ROOT_NAME)
	_check(staged.has_node("ferreira_record") and String((staged.get_node("ferreira_record_title") as Label3D).text).begins_with("GREENHOUSE SERVICE NOTE"), "D9 'What came home?' leaves the greenhouse service note at Ferreira's place")
	var holder := _n_holder("EX-CH06-S06", {"EX-CH05-S11-CHOICE": {"option_id": "EX-CH05-S11-OPT02"}})
	_check(not holder.is_empty() and String(holder.get("variant", "")) == "n", "D10 'We kept a place for your work.' puts the N. holder at the table")
	var mug := _bounds(commons, staged.get_node("commons_mug_5"))
	var record := _bounds(commons, staged.get_node("ferreira_record"))
	_check(record.has_point(Vector3(mug.get_center().x, record.get_center().y, mug.get_center().z)), "her mug stands on the record")
	commons.set_story_choices({"EX-CH05-S05-CHOICE": {"option_id": "EX-CH05-S05-OPT01"}})
	await process_frame
	staged = commons.visual_root.get_node(Staging.ROOT_NAME)
	_check(String((staged.get_node("ferreira_record_title") as Label3D).text).begins_with("ASCENT MANIFEST") and _n_holder("EX-CH06-S06", {"EX-CH05-S05-CHOICE": {"option_id": "EX-CH05-S05-OPT01"}}).is_empty(), "D9 'Why did you wait?' leaves the ascent manifest; no holder without D10")
	commons.free()
	await process_frame
	var amara := Crew.anchor_position("LOC-02", "amara", "EX-CH06-S10")
	var rafi := Crew.anchor_position("LOC-02", "rafi", "EX-CH06-S10")
	var picked := {"EX-CH06-S01-CHOICE": {"option_id": "EX-CH06-S01-OPT01"}}
	_check(Crew.anchor_position("LOC-02", "rafi", "EX-CH06-S10", picked).is_equal_approx(amara) and Crew.anchor_position("LOC-02", "amara", "EX-CH06-S10", picked).distance_to(rafi) > 1.0, "D11 the chosen companion stands at Kai's shoulder in S10")
	var panel := Vector3(-5.0, 0, 2.4)
	_check(amara.distance_to(panel) < 1.0, "without a choice Amara supplies the checkbacks from the panel")

## The real cast placement: the room is staged before anyone stands in it, bodies stand at the scene anchors and
## Kai carries the charged lamp only between S02 and S11.
func _check_crew() -> void:
	var crew := Crew.new()
	root.add_child(crew)
	for scene_id in ["EX-CH06-S01", "EX-CH06-S10", "EX-CH06-S07", "EX-CH06-S12"]:
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
		var kai: PlayerController = crew.bodies.get("kai")
		var carried: Array = kai.find_children("Carried_*", "BoneAttachment3D", true, false) if kai != null else []
		var expect_lamp: bool = scene_id in ["EX-CH06-S10", "EX-CH06-S07"]
		_check(carried.size() == (1 if expect_lamp else 0), scene_id + " Kai carries the hand light only while it is clipped on")
		if expect_lamp and carried.size() == 1:
			var lamp := (carried[0] as Node3D).get_child(0) as Node3D
			var hip := lamp.global_position - kai.global_position
			_check(hip.y > 0.75 and hip.y < 1.1 and Vector2(hip.x, hip.z).length() < 0.35, scene_id + " the lamp rides at Kai's hip (%.2f m up)" % hip.y)
		room.free()
		await process_frame
	crew.free()
	await process_frame

# ----------------------------------------------------------------------------------------------- capture

const SHOTS := [
	["EX-CH06-S01", "ch06_eclipse_wall", "S01_power_room"],
	["EX-CH06-S01", "player", "S01_player", 4.712],
	["EX-CH06-S01", "marker_tape", "S01_marker_tape"],
	["EX-CH06-S01", "ch06_locker", "S01_hand_light_locker"],
	["EX-CH06-S02", "ch06_repeater", "S02_personal_log"],
	["EX-CH06-S03", "ch06_board", "S03_allocation_board"],
	["EX-CH06-S04", "ch06_eclipse_wall", "S04_floods_and_guide"],
	["EX-CH06-S05", "ch06_test_panel", "S05_test_panel"],
	["EX-CH06-S06", "ch06_table", "S06_mission_table"],
	["EX-CH06-S06", "ch06_eclipse_desk", "S06_eclipse_desk"],
	["EX-CH06-S07", "monitor_close", "S07_red_ring"],
	["EX-CH06-S09", "message_log_close", "S09_message_log"],
	["EX-CH06-S10", "ch06_test_panel", "S10_f2_dark"],
	["EX-CH06-S10", "f2_close", "S10_f2_fault_close"],
	["EX-CH06-S10", "ch06_eclipse_wall", "S10_guide_light"],
	["EX-CH06-S10", "player", "S10_player_lamp", 1.571],
	["EX-CH06-S10", "kai_hip", "S10_lamp_on_kai"],
	["EX-CH06-S11", "ch06_board", "S11_debrief_board"],
	["EX-CH06-S11", "ch06_repeater", "S11_camera_restored"],
	["EX-CH06-S12", "ch06_calendar", "S12_monitoring_calendar"],
	["EX-CH06-S12", "ch06_cotton", "S12_cotton"],
	["EX-CH07-S01", "ch06_pin_board", "CH07_pinned_note"],
]
## Close-ups that are evidence only (the room JSONs keep the shared review views).
const CLOSE := {
	"monitor_close": {"from": [2.6, 1.2, -4.55], "to": [2.75, 1.08, -5.6]},
	"message_log_close": {"from": [3.25, 1.2, -4.9], "to": [3.5, 1.0, -5.75]},
	"marker_tape": {"from": [4.3, 1.05, 2.95], "to": [5.0, 0.55, 4.0]},
	"f2_close": {"from": [-5.0, 1.6, 2.25], "to": [-5.0, 1.25, 3.9]},
}

func _capture_all() -> void:
	var crew := Crew.new()
	root.add_child(crew)
	var camera := Camera3D.new()
	camera.fov = 70
	root.add_child(camera)
	var room: CampaignRoom = null
	var current := ""
	var choices := {"EX-CH05-S05-CHOICE": {"option_id": "EX-CH05-S05-OPT02"}, "EX-CH05-S11-CHOICE": {"option_id": "EX-CH05-S11-OPT02"}}
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
			if scene_id == "EX-CH06-S07":
				# the hero frame: totality, only the refracted rim lit (the presentation track is stopped first)
				var monitor := room.visual_root.get_node("ChapterStaging/eclipse_monitor")
				(monitor.get_meta("monitor_track") as Tween).kill()
				monitor.get_meta("monitor_screen").set_phase(0.5)
		var view := String(shot[1])
		if view == "kai_hip":
			var kai: Node3D = crew.bodies["kai"]
			camera.position = kai.global_position + Vector3(0.9, 1.1, 0.25)
			camera.look_at(kai.global_position + Vector3(0, 0.9, 0))
			camera.current = true
			for frame in 20:
				await process_frame
		elif view == "player":
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
		await RenderingServer.frame_post_draw
		await _save(String(shot[2]))
		if String(shot[2]) in ["S01_power_room", "S10_guide_light", "S07_red_ring", "S12_monitoring_calendar"]:
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
	_check(image.save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/M3-6R_%s.png" % id)) == OK, "capture " + id)

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

## M3-101: the D10 holder is the real M3-99 PR_LabelHolder "n" prop (a GLB),
## so its presence is asserted at the data level: the staged layout either
## carries the prop with variant "n" or it does not. The scene-level room
## cannot load GLB props in the LFS-stub copy.
func _n_holder(scene_id: String, choices: Dictionary) -> Dictionary:
	for prop in Contract.staged_layout("LOC-01", scene_id, choices).props:
		if String(prop.get("id", "")) == "n_holder":
			return prop
	return {}

## Visible mesh bounds of a node in room space (far LODs and hidden helpers skipped).
func _bounds(room: CampaignRoom, node: Node) -> AABB:
	var box := AABB()
	var first := true
	var meshes := node.find_children("*", "MeshInstance3D", true, false)
	if node is MeshInstance3D:
		meshes.append(node)
	for mesh in meshes:
		if (mesh as GeometryInstance3D).visibility_range_begin > 0.0 or not mesh.is_visible_in_tree() or mesh.name == "Edge" or mesh.get_viewport() != room.get_viewport():
			continue  # a plant_photo print's subject lives in the print's own SubViewport world, not in the room
		var local: AABB = room.global_transform.affine_inverse() * mesh.global_transform * mesh.get_aabb()
		box = local if first else box.merge(local)
		first = false
	return box
