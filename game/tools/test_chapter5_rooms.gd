## M3-5R: every Chapter 5 scene is staged in its proper location (STORY_FULL.md scene locations, the CHAPTER_05 scene
## scripts, doc 22 7.1-7.4, scene_rosters.json, doc 09) with the M3-5A props (the 2034 records, the document sleeve, the
## impact-camera monitor and frames, the cotton seed, the marker tape), and every join of doc 24 2.9 that touches
## Chapter 5 can play in the world. Builds the real room scenes with the real PlayerController and cast, then checks the
## mapping and rosters, stations for every scene action, navigation, collision, props resting, readable signs, the bridge,
## clue and story-echo objects, per-scene light levels, seating at the Commons table, and that the Chapter 1 and Chapter 6
## rooms come back exactly outside the chapter.
##   Godot --headless --path game --script res://tools/test_chapter5_rooms.gd
##   --capture (windowed) only renders: production/qa/evidence/M3-5R_*.png and M3-5R_runtime.txt (the checks are headless).
extends SceneTree

const Contract = preload("res://scripts/world/room_contract.gd")
const Presentation = preload("res://scripts/world/room_presentation.gd")
const Staging = preload("res://scripts/world/room_staging.gd")
const Gates = preload("res://scripts/missions/extended_gate_catalog.gd")
const Roster = preload("res://scripts/companions/companion_roster.gd")
const Crew = preload("res://scripts/world/campaign_crew.gd")
const Player = preload("res://scenes/player/player.tscn")
const SCENE_FILES := {"LOC-01": "commons", "LOC-02": "service_rooms", "LOC-03": "garden", "LOC-08": "garage"}
const PLAYER_ANCHOR := {"LOC-01": "commons_player", "LOC-02": "service_player", "LOC-03": "garden_player", "LOC-08": "rover_player"}
## STORY_FULL.md / CHAPTER_05 / doc 22 7.1-7.4: the arrival at the garage dock (S01, "Landing camera and airlock", staged
## by M3-105 and checked object by object in test_chapter4_rooms.gd), the corridor watch and atmosphere panel (S02), the Mission Table, records desk, spare locker and impact
## monitor (S03-S07, S09-S11), the maintenance console and isolated garden spur (S08), Tara's bay (S12).
const EXPECTED_ROOM := {
	"EX-CH05-S01": "LOC-08", "EX-CH05-S02": "LOC-02", "EX-CH05-S03": "LOC-01", "EX-CH05-S04": "LOC-01",
	"EX-CH05-S05": "LOC-01", "EX-CH05-S06": "LOC-01", "EX-CH05-S07": "LOC-01", "EX-CH05-S08": "LOC-02",
	"EX-CH05-S09": "LOC-01", "EX-CH05-S10": "LOC-01", "EX-CH05-S11": "LOC-01", "EX-CH05-S12": "LOC-03",
}
## Who sits at the Commons table (EX-CH05-S05: CS-09's shared frame, Ferreira at the head; S11: her first meal sitting down).
const SEATED := {"EX-CH05-S05": ["ferreira", "kai", "amara", "rafi"], "EX-CH05-S11": ["ferreira", "kai", "amara"]}
## Canon lines quoted word for word on staged words (exempt from the player-text patterns).
const CANON_LINES := ["EX-CH05-S12-L01"]
## Ceiling-hung pieces (the fifth mug's clip rail over the table) rest on the ceiling, not on a surface.
const HUNG_PREFIX := "mug_clip"
var checks := 0
var failures := 0
var capture := false
var report: Array[String] = []
var _drawn_frames := 0
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
		# The windowed pass only renders: the checks are the headless suite (run_tests.sh). macOS stops drawing a covered
		# window (another capture window, the lock screen), so the pass counts drawn frames and draws itself when it must.
		root.always_on_top = true
		root.grab_focus()
		RenderingServer.frame_post_draw.connect(func(): _drawn_frames += 1)
		await _capture_all()
		_finish()
		return
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
	_finish()

func _finish() -> void:
	var line := "CHAPTER 5 ROOMS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures]
	print(line)
	report.append(line)
	if capture:
		var file := FileAccess.open("res://../production/qa/evidence/M3-5R_runtime.txt", FileAccess.WRITE)
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
		_check(Contract.scene_room_map().get(scene_id, "") == room_id, scene_id + " is in the explicit scene-to-room map")
		_check(String(Gates.gate(scene_id).get("room_id", "")) == room_id, scene_id + " gate names the same room")
		var roster := Roster.scene_roster(scene_id)
		_check(roster.size() == 5 and roster.has("ferreira"), scene_id + " all five, Ferreira in person (she lands on 12 Dec 2046)")
		for id in roster:
			_check(String(roster[id].physical_location_id) == room_id, "%s %s is physically at %s" % [scene_id, id, room_id])
		for target in Gates.targets_for_scene(scene_id):
			_check(not Contract.station_focus(scene_id, String(target.target_id)).is_empty(), scene_id + " action has a room station: " + String(target.target_id))
	_check(Contract.room_for_scene("EX-CH04-S12") == "LOC-01" and Contract.room_for_scene("EX-CH06-S01") == "LOC-02", "neighbouring chapters keep their rooms")
	# CH04 -> CH05: the fifth mug hangs on its clip above the Commons table until she lands, then stands at her place.
	for scene_id in ["EX-CH04-S12", "EX-CH05-S01", "EX-CH05-S02"]:
		var mugs: Array = Contract.staged_layout("LOC-01", scene_id).props.filter(func(p): return String(p.id) == "commons_mug_5")
		var clipped: bool = scene_id != "EX-CH05-S02"
		_check(mugs.size() == 1 and (float(mugs[0].position[1]) > 2.1) == clipped, scene_id + (" the fifth mug hangs on its clip above the Commons table" if clipped else " her mug stands at her place at the table (S01 -> S02)"))

# ------------------------------------------------------------------------------------------------ one scene

func _check_scene(room: CampaignRoom, scene_id: String, player: PlayerController) -> void:
	var room_id := room.room_id
	var layout := Contract.staged_layout(room_id, scene_id)
	var stage: Dictionary = room.stage()
	_check(stage.get("layers", []).any(func(id): return String(id).begins_with("ch05_")) and room.visual_root.has_node(Staging.ROOT_NAME), scene_id + " room carries its Chapter 5 staging")
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

## Everyone the roster puts in this room has a scene anchor on the deck, clear of furniture and of each other, or sits
## in an installed seat where the scene seats them (S05, S11), and only there.
func _check_anchors(room: CampaignRoom, map: RID, scene_id: String) -> void:
	var roster := Roster.scene_roster(scene_id)
	var active := Roster.playable_actor(scene_id)
	var placed: Array[Vector3] = []
	for id in roster:
		if id == active:
			continue
		var at := Crew.anchor_position(room.room_id, id, scene_id)
		_check(Contract.staged_anchors(room.room_id, scene_id).keys().any(func(key): return String(key).ends_with("_" + id)), "%s %s has an authored anchor" % [scene_id, id])
		var seated := room.has_installed_seat_at(at)
		_check(seated == (SEATED.get(scene_id, []) as Array).has(id), "%s %s %s" % [scene_id, id, "sits in an installed seat" if seated else "stands"])
		_check(seated or NavigationServer3D.map_get_closest_point(map, at).distance_to(at) < 0.3, "%s %s stands on walkable deck or sits in a seat %s" % [scene_id, id, str(at)])
		for other in placed:
			_check(at.distance_to(other) > 0.6, "%s %s keeps 0.6 m from the next person" % [scene_id, id])
		placed.append(at)

## Staged furniture rests on the deck, a wall, a surface or flush on a panel face (or hangs from the ceiling), stays
## inside the room, and every large floor-standing addition has collision over its footprint.
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
		var supported := absf(base) < 0.03 or id.begins_with(HUNG_PREFIX)
		var wall := absf(box.end.z - half.y) < 0.12 or absf(box.position.z + half.y) < 0.12 or absf(box.end.x - half.x) < 0.12 or absf(box.position.x + half.x) < 0.12
		var centre := box.get_center()
		for surface in surfaces:
			if surface == box:
				continue
			if surface.end.y <= base + 0.03 and surface.end.y >= base - 0.04 and centre.x >= surface.position.x and centre.x <= surface.end.x and centre.z >= surface.position.z and centre.z <= surface.end.z:
				supported = true
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

## Every staged wall label faces walkable deck, never mirrored; staged words use player language (canon dialogue quoted
## from the catalog is exempt).
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
		# A page lying on a table reads from above. The garage's live words (M3-105) include screens read by suited crew
		# from the vacuum bay, off this pressurised navigation mesh: test_chapter4_rooms.gd checks them zone by zone.
		if absf(facing.y) <= 0.7 and room.room_id != "LOC-08":
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

## M3-101: the D10 holder is the real M3-99 PR_LabelHolder "n" prop (a GLB),
## so its presence is asserted at the data level: the staged layout either
## carries the prop with variant "n" or it does not. The scene-level room
## cannot load GLB props in the LFS-stub copy.
func _n_holder(scene_id: String, choices: Dictionary) -> Dictionary:
	for prop in Contract.staged_layout("LOC-01", scene_id, choices).props:
		if String(prop.get("id", "")) == "n_holder":
			return prop
	return {}

func _practical_scale(room: CampaignRoom) -> float:
	var practical := room.get_node("RoomLighting/Practical_0") as OmniLight3D
	return practical.light_energy / float(practical.get_meta("base_energy", practical.light_energy))

## The texture an unshaded live surface shows (the impact monitor's Screen, the landing camera print), or null.
func _surface_texture(node: Node, material_name: String) -> Texture2D:
	for mesh in node.find_children("*", "MeshInstance3D", true, false):
		var instance := mesh as MeshInstance3D
		if instance.mesh == null:
			continue
		for i in instance.mesh.get_surface_count():
			var source := instance.mesh.surface_get_material(i)
			var live := instance.get_surface_override_material(i) as StandardMaterial3D
			if source != null and source.resource_name == material_name and live != null:
				return live.albedo_texture
	return null

## Doc 24 §2.9 rows CH04->CH05 .. CH05->CH06, §4 clues 14 and 17-20, §3.5 F11 and doc 09's revisit rule, scene by scene.
func _check_bridges(room: CampaignRoom, scene_id: String) -> void:
	var staged := room.visual_root.get_node(Staging.ROOT_NAME) as Node3D
	var order := Contract.scene_order(scene_id) % 100
	var light: float = {5: 0.8, 7: 0.3}.get(order, 1.0)
	_check(absf(_practical_scale(room) - light) < 0.001, scene_id + " practicals at x%.2f" % light)
	if room.room_id == "LOC-01":
		_check(staged.has_node("commons_seat_5"), scene_id + " five seats at the table, Ferreira's at the head")
		_check((staged.get_node("commons_seat_5") as Node3D).position.is_equal_approx(Vector3(0, 0, -1.75)), scene_id + " her chair is at the head of the table all chapter")
		var mug := staged.get_node_or_null("commons_mug_5") as Node3D
		if order >= 6 and order <= 10:
			_check(mug == null, scene_id + " her mug is at the corridor watch station (S06 canon), not at the table")
		else:
			_check(mug != null and absf(mug.position.y - 0.762) < 0.002, scene_id + " her mug stands at her place at the table (S01 -> S02, S11 canon)")
		_check(staged.has_node("records_desk") == (order >= 6), scene_id + " the records desk stands from S06")
		_check(staged.has_node("spare_locker_back"), scene_id + " the spare is stored once in the Commons spare locker from S02")
		match order:
			3:
				_check(staged.has_node("records_2034") and staged.has_node("document_sleeve"), scene_id + " the four records and the sleeve she brought from her shelf are on the table (S02 -> S03)")
				var sleeve := staged.get_node("document_sleeve") as Node3D
				_check(not (sleeve.find_child("Seal", true, false) as Node3D).visible, scene_id + " the sleeve is open, its seal gone")
				_check(_text(staged, "record_text_ascentmanifest").contains("BOARDED 4") and _text(staged, "record_text_ascentmanifest").contains("N.R."), scene_id + " the ascent manifest: four departed, four boarded, the N.R. signature (clue 17)")
				_check(_text(staged, "record_text_relayfault").contains("12:00") and _text(staged, "record_text_evacuationorder").contains("12:10") and _text(staged, "record_text_servicenote").contains("3 APR 2034"), scene_id + " the records carry the 08 P-09 times")
				_check(not staged.has_node("record_order_ascentmanifest"), scene_id + " set down without arranging them")
				_check(staged.has_node("frozen_trays_photo"), scene_id + " the frozen-tray photograph lies with the records (S03 -> S04)")
			4:
				_check(staged.has_node("record_order_servicenote") and _text(staged, "record_order_ascentmanifest") == "4", scene_id + " the records lie in the supported order (S03 -> S04)")
				_check(staged.has_node("frozen_trays_close") and staged.has_node("alo_petal"), scene_id + " the frozen-garden photographs beside Alo's pressed petal")
				_check(_text(staged, "growth_sheet_2034_text").contains("BEFORE FLOWERING") and _text(staged, "alo_record_text").contains("42 SEEDS"), scene_id + " two timelines kept apart: the 2034 sheet and Alo's own record")
				_check(_text(staged, "caption_card_text").contains("OLD GARDEN"), scene_id + " Mei's draft caption before the revision")
			5:
				var records := staged.get_node("records_2034") as Node3D
				var order_sheet := records.find_child("Record_EvacuationOrder", true, false) as Node3D
				_check(order_sheet != null and order_sheet.global_basis.y.dot(Vector3.UP) < -0.99, scene_id + " Ferreira has turned the evacuation order over")
				var note := _text(staged, "record_text_evacuationorder")
				_check(note.contains("I TOLD HER SOMEONE WOULD COME BACK FOR IT") and note.contains("RADIO NOT RESTORED"), scene_id + " her 2034 margin note on its back (clue 18)")
				_check(_text(staged, "caption_card_text").contains("YOUNG UNFLOWERED SEEDLINGS"), scene_id + " Mei's revised caption carries over (S04 -> S05)")
			6:
				_check(_text(staged, "procedure_screen_text").contains("OPENS WITHOUT EARTH"), scene_id + " the replacement procedure opens without Earth (S06 -> S07)")
				_check(_text(staged, "relay_diagram_2034_text").contains("ISOLATION POINTS") and _text(staged, "service_card_text").contains("RC-0417"), scene_id + " the old relay diagram beside the spare's service card")
				var crate_lid: Node3D = staged.get_node("spare_crate").find_child("Lid", true, false) as Node3D if staged.has_node("spare_crate") else null
				_check(crate_lid != null and absf(crate_lid.rotation_degrees.x + 90.0) < 1.0 and _text(staged, "kai_note_text").contains("CHECK EVERY CONNECTOR"), scene_id + " Kai's signed note clipped inside the open crate, the controller still packed")
				_check(_text(staged, "mei_question_text").contains("WHO WROTE N.") and staged.has_node("current_garden_photo"), scene_id + " Mei's question beside a current photograph")
			7:
				var monitor := staged.get_node_or_null("impact_monitor") as Node3D
				var frame := _surface_texture(monitor, "Screen") if monitor != null else null
				_check(frame != null and frame.resource_path.ends_with("C02_a_1.png"), scene_id + " the impact monitor shows an authored candidate frame (dark plain, no streaks)")
				_check(_text(staged, "observation_log_text").contains("0 OF 6") and _text(staged, "amplified_view_text").contains("NOT NAKED-EYE"), scene_id + " the frame log starts empty; an amplified instrument view")
			9:
				var display := _text(staged, "main_display_text")
				_check(display.contains("UNSUPPORTED: AN IMPACT CAUSED THE 2034 RELAY FAULT") and display.contains("NOT ESTABLISHED"), scene_id + " the report moves the strong claim to unsupported and keeps the honest blank")
				_check(_text(staged, "damage_report_text").contains("NO VERIFIED STRIKE") and _text(staged, "observation_record_text").contains("SIX FLASHES"), scene_id + " tonight's record beside the 2034 damage report, dates apart (S08 -> S09)")
				_check(_text(staged, "observation_log_text").contains("CONFIRMED, WITH A REASON: 6"), scene_id + " the frame log is complete")
			10:
				_check(_text(staged, "signed_page_text").contains("DR NOOR RAHMAN") and _text(staged, "signed_page_text").contains("CONSENT"), scene_id + " the signed page shared with her consent (clue 19)")
				_check(_text(staged, "signature_card_text").count("N.R.") == 2, scene_id + " the manifest's N.R. beside the page's (S09 -> S10)")
				_check(_text(staged, "receipt_text").contains("DELIVERED 30 APR") and _text(staged, "receipt_text").contains("42 SEEDS"), scene_id + " report receipts: made versus delivered")
				_check(staged.has_node("noor_2034_portrait"), scene_id + " her 2034 portrait appears only on the signed page")
				var packet := room.visual_root.get_node_or_null("PR_SeedPacket") as Node3D
				_check(packet != null and (staged.get_node("signed_page") as Node3D).position.distance_to(packet.position) < 0.5, scene_id + " the signed page lies beside the ALO / N. packet")
			11:
				_check(_text(staged, "composer_text").contains("TO: DR NOOR RAHMAN") and _text(staged, "composer_text").contains("WE KEPT A PLACE FOR YOUR WORK."), scene_id + " the composer addresses Noor by name with both authored openings (S10 -> S11)")
				_check(staged.has_node("invitation_photo"), scene_id + " the current garden photograph to attach")
	elif room.room_id == "LOC-02":
		_check(staged.has_node("watch_desk") and _text(staged, "watch_log_text").contains("ANNEX HATCH N.R."), scene_id + " Ferreira's corridor watch passes the annex hatch N.R. (doc 24 3.5 F11)")
		_check(_text(staged, "correction_tag_text").contains("CORRECTED 7 MAY 2046") and _text(staged, "correction_tag_text").contains("REASON"), scene_id + " Amara's months-old correction stays visible, dated, with its reason")
		_check(room.focus_root.has_node("Focus_service_second_gauge"), scene_id + " the independent gauge on its hook is the second gauge")
		var mug := staged.get_node_or_null("ferreira_mug_watch")
		_check((mug != null) == (order >= 6 and order <= 10), scene_id + " her mug is on the watch desk from S06 until she brings it back in S11")
		if order == 2:
			_check(staged.has_node("sealed_sleeve") and (staged.get_node("sealed_sleeve").find_child("Seal", true, false) as Node3D).visible, scene_id + " the sealed sleeve from her relief cargo waits unopened on her locker shelf (S02 -> S03)")
			_check(_text(staged, "corridor_crate_text").contains("SPARE RELAY CONTROLLER") and _text(staged, "received_manifest_text").contains("RC-0417"), scene_id + " the controller's sealed crate with the received manifest")
			_check(_text(staged, "inventory_board_text").contains("STORED ONCE") and _text(staged, "inventory_board_text").contains("OPEN WITHOUT EARTH"), scene_id + " the inventory board: stored once, procedure local")
			_check(_text(staged, "reading_sheet_text").contains("______"), scene_id + " today's reading waits for the player's signature")
		else:
			_check(not staged.has_node("sealed_sleeve") and not staged.has_node("corridor_crate"), scene_id + " the sleeve and the crate have left the corridor")
			_check(_text(staged, "maintenance_screen_text").contains("REFERENCE 8") and _text(staged, "maintenance_screen_text").contains("TODAY 6"), scene_id + " the panel trend below its reference (08: dust 8 -> 6)")
			_check(_text(staged, "maintenance_screen_text").contains("OBSERVATION PHASE"), scene_id + " the observation clock carried into maintenance (S07 -> S08)")
			_check(_text(staged, "spur_trace_text").contains("THIS BRANCH ONLY") and staged.has_node("spur_patch_kit") and staged.has_node("cleaning_kit"), scene_id + " a separate spur trace, the patch and cleaning kits: two causes, two measurements")
			_check(_text(staged, "enclosure_tag_text").contains("STAYS CLOSED"), scene_id + " the living enclosure stays closed")
	elif room.room_id == "LOC-03":
		_check(staged.has_node("PL_Cotton_Seed") and not (room.visual_root.get_node("PL_Tara_Bloom") as Node3D).visible and not (room.visual_root.get_node("PL_Alo_Bud") as Node3D).visible, scene_id + " one cotton specimen planted in Tara's bay; Alo and Tara are records now")
		_check(_text(staged, "taras_bay_sign").contains("TARA'S BAY") and _text(staged, "taras_bay_sign").contains("15 DEC 2046"), scene_id + " Tara's name stays on the frame")
		_check(_text(staged, "noor_text_card_text").contains(Staging.line_text("EX-CH05-S12-L01")), scene_id + " Noor's text pinned where a gardener can read it, word for word (clue 20)")
		_check(_text(staged, "manifest_note_text").contains("LET ONE GROW FURTHER.") and _text(staged, "manifest_note_text").contains("2019"), scene_id + " the manifest note pinned on the bay (clue 14)")
		var petals: Array = room.stage().props.filter(func(p): return String(p.get("path", "")).contains("PR_PressedPetal"))
		_check(petals.size() == 1 and staged.has_node("alo_petal") and (staged.get_node("alo_petal") as Node3D).position.distance_to(Vector3(-3.2, 0.62, -0.91)) < 0.7 and (staged.get_node("alo_petal_caption") as Node3D).position.distance_to((staged.get_node("alo_petal") as Node3D).position) < 0.15, scene_id + " Alo's one pressed petal, off the lineage board, beside the cotton label with its caption")
		_check(_text(staged, "quarantine_record_text").contains("1 PLANTED + 11 STORED = 12") and _text(staged, "founder_ledger_text").contains("30") and _text(staged, "founder_ledger_text").contains("SEPARATE"), scene_id + " vault 1 + 11 = 12 and the founder 30 kept as two ledgers")
		_check(_text(staged, "care_card_text").contains("15 DEC") and _text(staged, "care_card_text").contains("12 JAN"), scene_id + " dated care into January")
		var tape: Dictionary = room.stage().carried.get("kai", {})
		_check(String(tape.get("path", "")).ends_with("PR_MarkerTape.glb"), scene_id + " Kai carries the marker tape for January's guide-light circuit (CH05 -> CH06)")

func _visible_sign(room: CampaignRoom, text: String) -> bool:
	for node in room.visual_root.get_children():
		if node is Label3D and node.text == text and node.visible:
			return true
	return false

# ---------------------------------------------------------------------------------------- re-staging, echoes

## One room instance re-staged scene after scene ends exactly as built: Chapter 1 has no staging and its own navigation,
## Chapter 6 gets its own rooms back without the Chapter 5 furniture.
func _check_restaging() -> void:
	var commons := await _room("LOC-01")
	var base_polys := (commons.navigation_root.get_node("NavigationRegion") as NavigationRegion3D).navigation_mesh.get_polygon_count()
	var base_focus := commons.focus_root.get_child_count()
	for scene_id in ["EX-CH05-S07", "EX-CH05-S01", "EX-CH01-S01", "EX-CH05-S10", "EX-CH06-S06"]:
		commons.set_scene_context(scene_id)
		await process_frame
		var staged := commons.visual_root.get_node_or_null(Staging.ROOT_NAME)
		_check(commons.navigation_root.get_child_count() == 1, scene_id + " re-staging keeps one navigation map")
		match scene_id:
			"EX-CH01-S01":
				_check(staged == null and commons.stage().layers.is_empty(), "the Chapter 1 Commons is unchanged after Chapter 5")
				_check((commons.navigation_root.get_node("NavigationRegion") as NavigationRegion3D).navigation_mesh.get_polygon_count() == base_polys and commons.focus_root.get_child_count() == base_focus, "Chapter 1 Commons navigation and stations return exactly")
				_check(is_equal_approx((commons.get_node("RoomLighting/Practical_0") as OmniLight3D).light_energy, 0.7), "Chapter 1 Commons light level restored after the night observation")
			"EX-CH05-S01":
				_check(staged.has_node("mug_clip_rail") and not staged.has_node("impact_monitor") and not staged.has_node("records_desk"), "re-staged S01 Commons: the mug still on its clip, no Chapter 5 furniture yet")
			"EX-CH05-S10":
				_check(staged.has_node("signed_page") and staged.has_node("impact_monitor") and not staged.has_node("mug_clip_rail"), "re-staged S10 keeps the monitor (props accumulate) and the signed page")
			"EX-CH06-S06":
				_check(staged.has_node("eclipse_monitor") and not staged.has_node("records_desk") and not staged.has_node("impact_monitor") and not staged.has_node("spare_locker_back"), "Chapter 6 gets its eclipse desk back, without Chapter 5's desk, monitor and locker")
	commons.free()
	await process_frame
	var service := await _room("LOC-02")
	service.set_scene_context("EX-CH05-S08")
	await process_frame
	service.set_scene_context("EX-CH01-S05")
	await process_frame
	_check(not service.visual_root.has_node(Staging.ROOT_NAME) and (service.visual_root.get_node("PR_HandLight") as Node3D).visible, "the Chapter 1 service rooms are unchanged after the maintenance")
	service.set_scene_context("EX-CH06-S01")
	await process_frame
	var staged := service.visual_root.get_node(Staging.ROOT_NAME)
	_check(staged.has_node("guide_branch") and not staged.has_node("watch_desk") and not staged.has_node("maintenance_desk"), "Chapter 6 power room opens beside Kai's taped branch, without Chapter 5's watch desk")
	service.free()
	await process_frame
	var garden := await _room("LOC-03")
	garden.set_scene_context("EX-CH05-S12")
	await process_frame
	garden.set_scene_context("EX-CH06-S01")
	await process_frame
	staged = garden.visual_root.get_node(Staging.ROOT_NAME)
	_check(staged.has_node("PL_Cotton_Young") and not staged.has_node("PL_Cotton_Seed") and not staged.has_node("cotton_pin_board"), "by January the cotton has grown; the planting-day board is gone")
	garden.set_scene_context("EX-CH01-S04")
	await process_frame
	_check((garden.visual_root.get_node("PL_Tara_Bloom") as Node3D).visible and _visible_sign(garden, "TARA / INDOOR REFERENCE"), "the Chapter 1 garden has Tara back in her own bay")
	garden.free()
	await process_frame

## Doc 24 §5.2: D5's voice card in S03, D9's record at her place from S06 (her mug on it again from S11), D10's N. holder
## and the composer's chosen opening; nothing appears without its recorded option.
func _check_echoes() -> void:
	var commons := await _room("LOC-01")
	commons.set_scene_context("EX-CH05-S03")
	await process_frame
	var staged := commons.visual_root.get_node(Staging.ROOT_NAME)
	_check(not staged.has_node("voice_card"), "no D5 card without the recorded CH02 choice")
	for option in {"EX-CH02-S10-OPT01": "CORRECTED TO AN INFERENCE", "EX-CH02-S10-OPT02": "KEPT AS AN INFERENCE"}.keys():
		commons.set_story_choices({"EX-CH02-S10-CHOICE": {"option_id": option}})
		await process_frame
		staged = commons.visual_root.get_node(Staging.ROOT_NAME)
		var words: String = {"EX-CH02-S10-OPT01": "CORRECTED TO AN INFERENCE", "EX-CH02-S10-OPT02": "KEPT AS AN INFERENCE"}[option]
		_check(_text(staged, "voice_card_text").contains(words), "D5 %s: the Evidence card says how the voice was first filed" % option)
	commons.set_story_choices({})
	commons.set_scene_context("EX-CH05-S06")
	await process_frame
	staged = commons.visual_root.get_node(Staging.ROOT_NAME)
	_check(not staged.has_node("ferreira_record"), "no D9 record without the recorded choice")
	for option in {"EX-CH05-S05-OPT01": "ASCENT MANIFEST", "EX-CH05-S05-OPT02": "GREENHOUSE SERVICE NOTE"}.keys():
		var words: String = {"EX-CH05-S05-OPT01": "ASCENT MANIFEST", "EX-CH05-S05-OPT02": "GREENHOUSE SERVICE NOTE"}[option]
		commons.set_story_choices({"EX-CH05-S05-CHOICE": {"option_id": option}})
		commons.set_scene_context("EX-CH05-S06")
		await process_frame
		staged = commons.visual_root.get_node(Staging.ROOT_NAME)
		_check(_text(staged, "ferreira_record_title").contains(words) and not staged.has_node("commons_mug_5"), "D9 %s: after S05 the record lies at her place while her mug is at the watch" % option)
		commons.set_scene_context("EX-CH05-S11")
		await process_frame
		staged = commons.visual_root.get_node(Staging.ROOT_NAME)
		var mug := _bounds(commons, staged.get_node("commons_mug_5"))
		var record := _bounds(commons, staged.get_node("ferreira_record"))
		_check(record.has_point(Vector3(mug.get_center().x, record.get_center().y, mug.get_center().z)), "D9 %s: from S11 her mug stands on the record again" % option)
	commons.set_story_choices({})
	await process_frame
	staged = commons.visual_root.get_node(Staging.ROOT_NAME)
	_check(_n_holder("EX-CH05-S11", {}).is_empty() and _text(staged, "composer_text").contains("HOW SHOULD THE INVITATION BEGIN?"), "before the choice the composer offers both openings and no holder waits")
	commons.set_story_choices({"EX-CH05-S11-CHOICE": {"option_id": "EX-CH05-S11-OPT01"}})
	await process_frame
	staged = commons.visual_root.get_node(Staging.ROOT_NAME)
	_check(_text(staged, "composer_text").contains("WOULD YOU LIKE TO SEE WHAT GROWS NEXT?") and _text(staged, "composer_text").contains("DELIVERED ONCE") and _n_holder("EX-CH05-S11", {"EX-CH05-S11-CHOICE": {"option_id": "EX-CH05-S11-OPT01"}}).is_empty(), "D10 OPT01: the chosen opening, delivered once, no reply yet; no holder")
	commons.set_story_choices({"EX-CH05-S11-CHOICE": {"option_id": "EX-CH05-S11-OPT02"}})
	await process_frame
	staged = commons.visual_root.get_node(Staging.ROOT_NAME)
	var holder := _n_holder("EX-CH05-S11", {"EX-CH05-S11-CHOICE": {"option_id": "EX-CH05-S11-OPT02"}})
	_check(_text(staged, "composer_text").contains("WE KEPT A PLACE FOR YOUR WORK.") and _text(staged, "composer_text").contains("NO REPLY YET") and not holder.is_empty() and String(holder.get("variant", "")) == "n", "D10 OPT02: the seed-label holder marked N. sits at the table from S11")
	commons.free()
	await process_frame

## The real cast placement: the room is staged before anyone stands in it, bodies stand at the scene anchors, the crew
## sits at the Commons table where the scene seats it, and Kai carries the marker tape in S12.
func _check_crew() -> void:
	var crew := Crew.new()
	root.add_child(crew)
	for scene_id in ["EX-CH05-S01", "EX-CH05-S02", "EX-CH05-S05", "EX-CH05-S08", "EX-CH05-S11", "EX-CH05-S12"]:
		var room := await _room(Contract.room_for_scene(scene_id))
		var start: Array = Contract.anchors(room.room_id)[PLAYER_ANCHOR[room.room_id]]
		var player := crew.place(scene_id, room, Vector3(start[0], start[1], start[2]))
		for frame in 4:
			await physics_frame
		_check(room.scene_context() == scene_id and not room.stage().layers.is_empty(), scene_id + " the room is staged by the crew placement")
		_check(crew.local_ids.size() == 5 and crew.local_ids.has("ferreira"), scene_id + " all five are placed, Ferreira in person")
		for id in crew.local_ids:
			var body: PlayerController = crew.bodies[id]
			if body == player:
				continue
			var at := Crew.anchor_position(room.room_id, id, scene_id)
			_check(Vector2(body.position.x - at.x, body.position.z - at.z).length() < 0.15, "%s %s placed at the scene anchor" % [scene_id, id])
			var sits := (SEATED.get(scene_id, []) as Array).has(id)
			_check(body.foot_ik_enabled == not sits, "%s %s %s" % [scene_id, id, "sits in an installed seat" if sits else "stands"])
			if sits:
				var facing := room.installed_seat_facing(at)
				var forward: Vector3 = (body.get("visual") as Node3D).global_basis.z
				_check(facing != Vector3.ZERO and forward.dot(facing) > 0.9, "%s %s faces the way the seat faces" % [scene_id, id])
		_check(room.get_node_or_null("CrewSeats") == null, scene_id + " no stand-in benches")
		if scene_id == "EX-CH05-S12":
			var kai: PlayerController = crew.bodies["kai"]
			_check(kai.find_children("Carried_PR_MarkerTape", "BoneAttachment3D", true, false).size() == 1, scene_id + " the marker tape rides on Kai's hip")
		room.free()
		await process_frame
	crew.free()
	await process_frame

# ----------------------------------------------------------------------------------------------- capture

const SHOTS := [
	["EX-CH05-S01", "ch05_pad_camera", "S01_pad_camera"],
	["EX-CH05-S01", "ch05_relief_locker", "S01_relief_locker"],
	["EX-CH05-S01", "player", "S01_player", 0.0],
	["EX-CH05-S02", "ch05_corridor", "S02_spare_crate"],
	["EX-CH05-S02", "ch05_inventory_board", "S02_inventory_board"],
	["EX-CH05-S02", "ch05_atmosphere_panel", "S02_atmosphere_panel"],
	["EX-CH05-S02", "ch05_second_gauge", "S02_second_gauge"],
	["EX-CH05-S02", "ch05_watch_desk", "S02_watch_and_sleeve"],
	["EX-CH05-S03", "ch05_records", "S03_records"],
	["EX-CH05-S03", "ch05_sleeve", "S03_sleeve"],
	["EX-CH05-S04", "ch05_archive", "S04_archive_images"],
	["EX-CH05-S04", "ch05_records", "S04_records_in_order"],
	["EX-CH05-S05", "ch05_shared_frame", "S05_shared_seating"],
	["EX-CH05-S05", "ch05_records", "S05_margin_note"],
	["EX-CH05-S05", "ch05_caption", "S05_revised_caption"],
	["EX-CH05-S06", "ch05_records_desk", "S06_records_desk"],
	["EX-CH05-S06", "ch05_kai_note", "S06_kai_note"],
	["EX-CH05-S06", "ch05_question", "S06_mei_question"],
	["EX-CH05-S07", "ch05_monitor", "S07_impact_monitor"],
	["EX-CH05-S07", "player", "S07_night_observation", -0.31],
	["EX-CH05-S08", "ch05_maintenance_console", "S08_maintenance_console"],
	["EX-CH05-S08", "ch05_spur", "S08_garden_spur"],
	["EX-CH05-S08", "ch05_watch_desk", "S08_mug_at_the_watch"],
	["EX-CH05-S09", "ch05_report", "S09_bounded_report"],
	["EX-CH05-S09", "ch05_evidence_table", "S09_evidence_table"],
	["EX-CH05-S10", "ch05_signed_page", "S10_signed_page"],
	["EX-CH05-S10", "ch05_rao", "S10_rao_live"],
	["EX-CH05-S11", "ch05_composer", "S11_composer"],
	["EX-CH05-S11", "ch05_head_of_table", "S11_mug_beside_four"],
	["EX-CH05-S12", "ch05_cotton_bay", "S12_cotton_in_taras_bay"],
	["EX-CH05-S12", "ch05_pin_board", "S12_noor_text"],
	["EX-CH05-S12", "ch05_quarantine", "S12_vault_ledger"],
	["EX-CH05-S12", "ch05_founder_ledger", "S12_founder_ledger"],
	["EX-CH05-S12", "player", "S12_player", 1.01],
]

func _capture_all() -> void:
	var crew := Crew.new()
	root.add_child(crew)
	var camera := Camera3D.new()
	camera.fov = 70
	root.add_child(camera)
	var room: CampaignRoom = null
	var current := ""
	var choices := {"EX-CH05-S05-CHOICE": {"option_id": "EX-CH05-S05-OPT02"}, "EX-CH05-S11-CHOICE": {"option_id": "EX-CH05-S11-OPT02"}, "EX-CH02-S10-CHOICE": {"option_id": "EX-CH02-S10-OPT02"}}
	var catalog = JSON.parse_string(FileAccess.get_file_as_string(Staging.CATALOG_PATH))
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
		if scene_id == "EX-CH05-S10" and view == "ch05_rao":
			for line in catalog.lines:
				if String(line.id) == "EX-CH05-S10-L01":
					crew.present_line(line, true)
		if view == "player":
			var player := crew.player
			player.follow_camera.yaw = float(shot[3])
			player.follow_camera.pitch = -0.12
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
		await _draw_frame()
		await _save(String(shot[2]))
		if String(shot[2]) in ["S01_pad_camera", "S02_spare_crate", "S05_shared_seating", "S07_impact_monitor", "S12_cotton_in_taras_bay"]:
			await _time(room.room_id + " " + scene_id)
	if room != null:
		room.free()
	camera.free()
	crew.free()

func _time(label: String) -> void:
	# Frame times only mean something while the window really draws; wait up to a minute for that.
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
		report.append("%s windowed frame ms with cast: not measured (the window drew %d of 180 frames; macOS reported it covered)" % [label, _drawn_frames - drawn_before])
		return
	report.append("%s windowed frame ms with cast: p50=%.2f p95=%.2f; draw calls=%d" % [label, samples[90], samples[171], Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])

## Saves the presented frame, re-reading a blank (shader-compile) frame for up to two seconds.
func _save(id: String) -> void:
	var image := root.get_texture().get_image()
	for attempt in 120:
		if not _blank(image):
			break
		await _draw_frame()
		image = root.get_texture().get_image()
	_check(not _blank(image), "capture " + id + " shows a rendered frame")
	_check(image.save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/M3-5R_%s.png" % id)) == OK, "capture " + id)

## Waits for the next drawn frame; when the window has not drawn for half a second (covered), renders every viewport.
func _draw_frame() -> void:
	var drawn := _drawn_frames
	for frame in 30:
		await process_frame
		if _drawn_frames > drawn:
			return
	RenderingServer.force_draw(false)

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
		# A plant_photo print renders its subject in its own SubViewport world: not in the room.
		if (mesh as GeometryInstance3D).visibility_range_begin > 0.0 or not mesh.is_visible_in_tree() or mesh.name == "Edge" or mesh.get_viewport() != room.get_viewport():
			continue
		var local: AABB = room.global_transform.affine_inverse() * mesh.global_transform * mesh.get_aabb()
		box = local if first else box.merge(local)
		first = false
	return box
