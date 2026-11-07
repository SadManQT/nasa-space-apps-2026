## M3-105 / M3-106 / M3-4R: the Chapter 4 rooms. LOC-08 is the approved M3-4A rover garage (en_garage.gd from
## garage.json, decisions 1-7): a pressurised ready room on its plinth (deck y 0), the vacuum bay (floor y -1.40) with the
## EVA porch and its stair, VH_Rover docked at the tunnel. Builds the real room scenes with the real PlayerController and
## cast, then checks the scene map and rosters, a station for every scene action, the multi-level navigation and
## collision, the dock's SEALED / EQUALISING / SAFE TO OPEN cycle with its pump hum and time card, props resting, live
## words in player language on every screen, the doc 24 section 2.9 joins, and the suits in vacuum.
##   Godot --headless --path game --script res://tools/test_chapter4_rooms.gd
##   --capture (windowed, production/qa/evidence/M3-4R_capture.sh) renders only the evidence views into
##   production/qa/evidence/<task>_*.png; every check stays in the headless run.
extends SceneTree

const Contract = preload("res://scripts/world/room_contract.gd")
const Presentation = preload("res://scripts/world/room_presentation.gd")
const Staging = preload("res://scripts/world/room_staging.gd")
const Habitat = preload("res://scripts/world/habitat_room_builder.gd")
const Gates = preload("res://scripts/missions/extended_gate_catalog.gd")
const Roster = preload("res://scripts/companions/companion_roster.gd")
const Crew = preload("res://scripts/world/campaign_crew.gd")
const Garage = preload("res://assets/environment/EN_Garage/en_garage.gd")
const Player = preload("res://scenes/player/player.tscn")
const Stream = preload("res://scripts/terrain/terrain_stream.gd")
const SCENE_FILES := {"LOC-01": "commons", "LOC-02": "service_rooms", "LOC-03": "garden", "LOC-04": "safe_room", "LOC-05": "airlock", "LOC-08": "garage"}
const PLAYER_ANCHOR := {"LOC-01": "commons_player", "LOC-03": "garden_player", "LOC-08": "rover_player"}
## The garage's scenes (M3-105): CH04 departure (S02-S03) and return (S09), Ferreira's arrival (CH05-S01), and the two
## destination boards of CH07-S12, CH08-S01 and the CH08-S11 return.
const GARAGE_SCENES := ["EX-CH04-S02", "EX-CH04-S03", "EX-CH04-S09", "EX-CH05-S01", "EX-CH07-S12", "EX-CH08-S01", "EX-CH08-S11"]
const EXPECTED_ROOM := {
	"EX-CH04-S01": "LOC-03", "EX-CH04-S02": "LOC-08", "EX-CH04-S03": "LOC-08", "EX-CH04-S04": "LOC-09",
	"EX-CH04-S05": "LOC-09", "EX-CH04-S06": "LOC-10", "EX-CH04-S07": "LOC-10", "EX-CH04-S08": "LOC-10",
	"EX-CH04-S09": "LOC-08", "EX-CH04-S10": "LOC-03", "EX-CH04-S11": "LOC-01", "EX-CH04-S12": "LOC-01",
	"EX-CH05-S01": "LOC-08", "EX-CH07-S12": "LOC-08", "EX-CH08-S01": "LOC-08", "EX-CH08-S11": "LOC-08",
}
## Stations several cast members may stand at by design (none in the garage).
const SHARED_STATIONS: Array = []
## Test-only physics layer for the visible-surface copies the footprint check rays against (layer 16).
const FOOTPRINT_LAYER := 1 << 15
var checks := 0
var failures := 0
var capture := false
var _patterns: Array[RegEx] = []
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

func _run() -> void:
	capture = OS.get_cmdline_user_args().has("--capture")
	root.size = Vector2i(1600, 900)
	if capture:
		root.always_on_top = true
		root.grab_focus()
		RenderingServer.frame_post_draw.connect(func() -> void: _drawn_frames += 1)
		await _capture_all()
	else:
		await _check_all()
	print("CHAPTER 4 ROOMS %sRESULT: %s (%d checks, %d failures)" % ["CAPTURE " if capture else "", "PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _check_all() -> void:
	_check_mapping()
	await _check_garage_room()
	await _check_dock_cycle()
	var player := Player.instantiate() as PlayerController
	player.character_glb = "res://assets/characters/CH_Kai/CH_Kai.glb"
	player.controlled = false
	(player.get_node("FollowCamera") as FollowCamera).capture_mouse = false
	root.add_child(player)
	player.set_physics_process(false)
	for scene_id in GARAGE_SCENES:
		var room := await _room("LOC-08")
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
	var scene := (load("res://scenes/campaign/rooms/garage.tscn") as PackedScene).instantiate()
	_check(scene is CampaignRoom and String(scene.room_id) == "LOC-08" and scene.has_node("GaragePreload") and scene.has_node("HabitatKitPreload"), "garage.tscn is the LOC-08 room scene and carries its kit, garage and rover GLBs as dependencies")
	scene.free()
	for scene_id in EXPECTED_ROOM:
		var room_id := Contract.room_for_scene(scene_id)
		_check(room_id == EXPECTED_ROOM[scene_id], scene_id + " is staged in its STORY_FULL location " + String(EXPECTED_ROOM[scene_id]))
		_check(String(Gates.gate(scene_id).get("room_id", "")) == room_id, scene_id + " gate names the same room")
		var roster := Roster.scene_roster(scene_id)
		var active := Roster.playable_actor(scene_id)
		_check(String(roster[active].physical_location_id) == room_id, scene_id + " playable actor stands in the scene's room")
		if room_id != "LOC-08":
			continue
		for target in Gates.targets_for_scene(scene_id):
			_check(not Contract.station_focus(scene_id, String(target.target_id)).is_empty(), scene_id + " action has a room station: " + String(target.target_id))
	for scene_id in ["EX-CH04-S02", "EX-CH04-S03", "EX-CH04-S09"]:
		var roster := Roster.scene_roster(scene_id)
		_check(roster.rafi.physical_location_id == "LOC-08" and roster.kai.physical_location_id == "LOC-08" and roster.mei.physical_location_id == "LOC-01" and roster.amara.physical_location_id == "LOC-01", scene_id + " two field cadets in the garage, two at home (S02 -> S03 'the hatch closes on two field and two home')")
		_check(roster.ferreira.physical_location_id == "EARTH_SCREEN", scene_id + " Ferreira is on the Earth link only")
	_check(Roster.scene_roster("EX-CH07-S12").values().all(func(row): return row.physical_location_id == "LOC-08"), "EX-CH07-S12 all five face the garage's two destination boards (moved from the Commons)")
	_check(Roster.scene_roster("EX-CH05-S01").values().all(func(row): return row.physical_location_id == "LOC-08"), "EX-CH05-S01 all five meet at the garage dock")
	var contract := Contract.room("LOC-08")
	_check(contract.bounds_m == [12.0, 9.0] and String(contract.pressure) == "pressurised", "LOC-08 is canon's 12 x 9 m garage with a pressurised ready room (decision 1)")
	_check(contract.boundary_ids == ["door_commons_garage", "garage_dock_hatch", "rover_bay_door"], "LOC-08's boundaries are the corridor door, the dock hatch and the rover door")
	var layout := Contract.layout("LOC-08")
	_check(String(layout.zones.rover_bay.pressure) == "vacuum" and String(layout.zones.eva_porch.pressure) == "vacuum" and String(layout.zones.ready_room.pressure) == "pressurised", "the bay and the porch are vacuum, the ready room is pressurised (decisions 1 and 4)")
	var place := Contract.terrain("LOC-08")
	_check(place.region_id == "aurora_ridge" and not bool(place.omit_staging_floor) and absf(float(place.site_from.distance_m) - 80.0) < 0.01 and absf(float(place.site_from.azimuth_deg) - 150.0) < 0.01, "the garage stands on the Aurora ridge 80 m from Aurora at azimuth 150 (decision 3)")
	_check(Vector2(place.origin_xz_m[0], place.origin_xz_m[1]).length() > 79.9 and Vector2(place.origin_xz_m[0], place.origin_xz_m[1]).length() < 80.1, "its placement origin is 80 m from Aurora's site")

# ------------------------------------------------------------------------------------------------ LOC-08 base room

## The garage is a kit room like M1-06's: batched shell, a real corridor portal, the M3-4A pieces under VisualRoot, the
## docked rover, collision on three levels and navigation on the deck, the porch and its stair, and the bay floor.
func _check_garage_room() -> void:
	var room := await _room("LOC-08")
	var layout := Contract.layout("LOC-08")
	_check(room.build_room().get("duplicate", false), "LOC-08 rebuild is idempotent")
	_check(room.visual_root.has_node("HabitatKit") and room.visual_root.get_node("HabitatKit").get_child_count() < 20, "LOC-08 floor and ceiling tiles are MultiMesh batches")
	var bay := room.garage()
	_check(bay != null and bay.has_method("request_dock_cycle"), "LOC-08 carries the running garage (dock, rover door, cargo lock, relief locker)")
	for role in layout.garage_roles:
		_check(room.visual_root.has_node(String(role)), "garage piece is a named room prop: " + String(role))
	_check(not bay.nodes.has("inner_door") and room.door_root.has_node("Door_door_commons_garage") and room.visual_root.has_node("Connector_door_commons_garage"), "the inner door is the room's portal with its corridor connector (decision 2)")
	var door := room.door_root.get_node("Door_door_commons_garage") as Node3D
	_check(absf(door.global_position.x + 3.5) < 0.01 and absf(door.global_position.z + 4.5) < 0.01, "the corridor door sits where garage.json puts the inner door (north wall)")
	_check(_staged_words(room) == 0, "the base room draws no chapter words")
	await physics_frame
	await physics_frame
	var deck := _ray(Vector3(-1.0, 2.0, -3.0), Vector3(-1.0, -3.0, -3.0))
	_check(not deck.is_empty() and absf(deck.position.y) < 0.03, "the ready-room deck is walkable at y 0")
	var porch := _ray(Vector3(-4.5, 2.0, 2.0), Vector3(-4.5, -3.0, 2.0))
	_check(not porch.is_empty() and absf(porch.position.y) < 0.03, "the EVA porch is level with the deck (decision 4)")
	var floor_hit := _ray(Vector3(5.0, 2.0, 3.9), Vector3(5.0, -3.0, 3.9))
	_check(not floor_hit.is_empty() and absf(floor_hit.position.y + 1.4) < 0.03, "the vacuum bay floor is 1.40 m below the deck (the loading-dock section)")
	var stair := _ray(Vector3(-1.6, 1.0, 4.2), Vector3(-1.6, -3.0, 4.2))
	_check(not stair.is_empty() and absf(stair.position.y + 0.7) < 0.08, "the porch stair has a walkable ramp halfway down (%.2f)" % (stair.position.y if not stair.is_empty() else 99.0))
	_check(not _ray(Vector3(0.0, 1.2, -2.0), Vector3(0.0, 1.2, -1.0)).is_empty(), "the pressure wall stops anyone walking from the deck into the bay")
	var region := room.navigation_root.get_node("NavigationRegion") as NavigationRegion3D
	var map := region.get_navigation_map()
	NavigationServer3D.map_force_update(map)
	var on_deck := Vector3(-1.8, 0, -2.9)
	var on_porch := Vector3(-4.5, 0, 1.0)
	var on_bay := Vector3(4.6, -1.4, 2.5)
	for point in [on_deck, on_porch, on_bay]:
		_check(NavigationServer3D.map_get_closest_point(map, point).distance_to(point) < 0.2, "navigation covers %s" % str(point))
	var down := NavigationServer3D.map_get_path(map, on_porch, on_bay, true)
	_check(not down.is_empty() and down[down.size() - 1].distance_to(on_bay) < 0.3, "a suited cadet can walk from the porch down the stair to the bay floor")
	var through := NavigationServer3D.map_get_path(map, on_deck, on_porch, true)
	_check(through.is_empty() or through[through.size() - 1].distance_to(on_porch) > 1.0, "no path leads from the pressurised deck into the vacuum (the pressure wall, decision 1)")
	var lights := room.get_node("RoomLighting").get_children()
	var practicals := lights.filter(func(n): return n is OmniLight3D and String(n.name).begins_with("Practical_"))
	var floods := room.visual_root.get_node("BayFloods").get_children().filter(func(n): return n is SpotLight3D)
	_check(practicals.size() == 4 and practicals.filter(func(n): return n.shadow_enabled).size() == 2, "the ready room has the kit rooms' four practicals, two with shadows")
	_check(floods.size() == 3 and floods.filter(func(n): return n.shadow_enabled).size() == 2 and floods.all(func(n): return n.position.z > -1.35), "the bay keeps three 5,000 K floods, two with shadows, all in the bay")
	_check(not room.visual_root.find_children("*", "SpotLight3D", true, false).any(func(n): return n.get_parent() == bay), "en_garage's own lights are not doubled")
	var pump := bay.get_node_or_null("DockPump") as AudioStreamPlayer3D
	_check(pump != null and (bay.transform * pump.position).z < -1.5, "the pump hum plays in the ready room, never in the vacuum bay")
	var rover := room.visual_root.get_node("VH_Rover") as Node3D
	var hatch := _bounds(room, rover)
	_check(hatch.position.y > -1.45 and hatch.position.y < -1.35, "VH_Rover stands on the bay floor")
	room.free()
	await process_frame

func _staged_words(room: CampaignRoom) -> int:
	var staged := room.visual_root.get_node_or_null(Staging.ROOT_NAME)
	return 0 if staged == null else staged.find_children("*", "Label3D", true, false).size()

## The dock (garage.json "dock"): SAFE TO OPEN only when the docked tunnel holds cabin pressure; EQUALISING runs the
## pump with its labelled time card; the hatch opens only on SAFE TO OPEN; one cargo-lock door at a time.
func _check_dock_cycle() -> void:
	var room := await _room("LOC-08")
	var bay := room.garage()
	var dock: Dictionary = Garage.dock()
	_check(bay.is_docked() and bay.dock_state() == "SAFE TO OPEN" and not bay.is_dock_hatch_open(), "at rest the rover is docked and the tunnel holds cabin pressure, hatch shut")
	var words := bay.nodes.docking_port.get_node_or_null("DockWords") as Label3D
	_check(words != null and words.text == "SAFE TO OPEN" and not words.double_sided, "the dock panel shows the live word")
	_check(bool(room.set_door_open("garage_dock_hatch", true)) and bay.is_dock_hatch_open(), "WorldRoute's dock boundary opens the hatch on SAFE TO OPEN")
	_check(not bool(bay.request_dock_cycle("vacuum").accepted), "the tunnel never pumps down with the hatch open")
	_check(not bool(bay.set_docked(false).accepted), "the rover cannot undock with the hatch open")
	room.set_door_open("garage_dock_hatch", false)
	var started: Dictionary = bay.request_dock_cycle("vacuum")
	_check(bool(started.accepted) and bay.dock_state() == "EQUALISING" and words.text == "EQUALISING", "pumping the tunnel down shows EQUALISING")
	_check(String(started.time_card).contains("PUMPING DOWN") and String(started.time_card).contains("MIN") and String(started.time_card).contains("SHOWN IN"), "the cycle carries a labelled time card (real minutes, shown in seconds): " + String(started.time_card))
	_check(String((bay.nodes.docking_port.get_node("DockTimeCard") as Label3D).text) == String(started.time_card), "the time card is on the dock panel while the pump runs")
	_check(bool(bay.request_dock_cycle("vacuum").get("duplicate", false)) and not bool(bay.request_dock_cycle("habitat").accepted), "a repeat is a duplicate; the other side waits")
	bay.advance(float(dock.equalise_seconds) + 0.1)
	_check(bay.dock_state() == "SEALED" and words.text == "SEALED" and (bay.nodes.docking_port.get_node("DockTimeCard") as Label3D).text.is_empty(), "the pumped-down tunnel reads SEALED and the time card clears")
	_check(not bool(bay.set_dock_hatch_open(true).accepted) and not bay.is_dock_hatch_open(), "the hatch refuses to open on SEALED")
	_check(bool(bay.set_docked(false).accepted) and bay.dock_state() == "SEALED" and not bool(bay.request_dock_cycle("habitat").accepted), "with the rover away nothing can be equalised")
	bay.set_docked(true)
	bay.request_dock_cycle("habitat")
	var saved: Dictionary = bay.dock_snapshot()
	bay.advance(float(dock.equalise_seconds) + 0.1)
	_check(bay.dock_state() == "SAFE TO OPEN" and bool(bay.set_dock_hatch_open(true).accepted), "equalised to the cabin, the hatch opens")
	bay.dock_restore(saved)
	_check(bay.dock_state() == "EQUALISING" and not bay.is_dock_hatch_open(), "a saved cycle restores mid-way, hatch shut")
	_check(float(dock.real_seconds) > float(dock.equalise_seconds) * 5.0, "the on-screen cycle is compressed from the real tunnel time")
	_check(bay.set_lock_door("InnerDoor", true) and not bay.set_lock_door("OuterDoor", true), "the dry cargo lock never opens both doors (decision 5)")
	room.free()
	await process_frame

# ------------------------------------------------------------------------------------------------ one scene

func _check_scene(room: CampaignRoom, scene_id: String, player: PlayerController) -> void:
	var layout := Contract.staged_layout(room.room_id, scene_id)
	var stage: Dictionary = room.stage()
	_check(not stage.get("layers", []).is_empty() and room.visual_root.has_node(Staging.ROOT_NAME), scene_id + " the garage carries its staging")
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
	await _check_staged_objects(room, layout, scene_id)
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
		_check(Vector2(player.position.x - goal.x, player.position.z - goal.z).length() < 0.12 and absf(player.position.y) < 0.1, scene_id + " player walks unobstructed on the deck to " + str(goal))
	player.velocity = Vector3.ZERO

## Doc 09 clearances: a 1 m approach to the corridor door stays clear and reachable.
func _check_doors(room: CampaignRoom, map: RID, spawn: Vector3, scene_id: String) -> void:
	for node in room.door_root.get_children():
		if not node is CampaignDoor:
			continue
		var inward: Vector3 = -node.global_basis.z
		inward.y = 0
		var approach: Vector3 = node.global_position + inward.normalized() * 1.0
		approach.y = 0
		var path := NavigationServer3D.map_get_path(map, spawn, approach, true)
		_check(not path.is_empty() and path[path.size() - 1].distance_to(approach) < 0.2, scene_id + " 1 m door approach stays clear: " + String(node.boundary_id))

## Everyone the roster puts in the garage has a scene anchor on walkable deck (or, suited, on the porch), clear of each
## other and of the scene's stations and their sightlines.
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
	var placed: Array[Vector3] = [Presentation.vector(Contract.anchors(room.room_id).rover_player)]
	for id in roster:
		if String(roster[id].physical_location_id) != room.room_id or id == active:
			continue
		var at := Crew.anchor_position(room.room_id, id, scene_id)
		_check(Contract.staged_anchors(room.room_id, scene_id).has("rover_" + id), "%s %s has an authored anchor" % [scene_id, id])
		_check(NavigationServer3D.map_get_closest_point(map, at).distance_to(at) < 0.3, "%s %s stands on walkable floor %s" % [scene_id, id, str(at)])
		var suited := String(layout.stage.outfits.get(id, "")) == "eva"
		_check(suited == (at.z > -1.35), "%s %s is suited exactly when standing in the vacuum (porch or bay)" % [scene_id, id])
		for other in placed:
			_check(at.distance_to(other) > 0.6, "%s %s keeps 0.6 m from the next person" % [scene_id, id])
		placed.append(at)
		var foot := Vector2(at.x, at.z)
		for lane in lanes:
			var line := Geometry2D.get_closest_point_to_segment(foot, lane[1], lane[2])
			_check(foot.distance_to(lane[1]) >= 0.8 and foot.distance_to(line) >= 0.4, "%s %s leaves the %s station and its sightline free" % [scene_id, id, lane[0]])

## Staged objects rest on the deck, a wall or another surface and stay inside the room, except inside a sealed
## enclosure the room data names (the dry cargo lock's chamber); every large floor-standing addition has collision over
## its footprint; anything resting on furniture is carried by the geometry people see.
func _check_staged_objects(room: CampaignRoom, layout: Dictionary, scene_id: String) -> void:
	var staged := room.visual_root.get_node(Staging.ROOT_NAME) as Node3D
	var half := Vector2(float(layout.bounds_m[0]), float(layout.bounds_m[1])) * 0.5
	var enclosures: Array[AABB] = []
	for spec in layout.get("sealed_enclosures", []):
		enclosures.append(AABB(Presentation.vector(spec.min), Presentation.vector(spec.max) - Presentation.vector(spec.min)))
	var surfaces: Array[AABB] = []
	var resting: Array[Node3D] = []
	for node in room.visual_root.get_children() + staged.get_children():
		if node is Node3D and node.visible and node != staged and String(node.name) not in ["HabitatKit", "Garage", "berm", "VH_Rover", "eva_porch"]:
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
		_check(enclosed or (box.position.x >= -half.x - 0.02 and box.end.x <= half.x + 0.02 and box.position.z >= -half.y - 0.02 and box.end.z <= -1.5 + 0.02), scene_id + " staged object stays in the ready room or a sealed enclosure: " + id)
		var base := box.position.y
		var supported := absf(base) < 0.03 or enclosed
		var wall := absf(box.position.z + half.y) < 0.12 or absf(box.end.x - half.x) < 0.12 or absf(box.position.x + half.x) < 0.12
		for plane in layout.get("interior_walls", []):
			wall = wall or (plane.axis == "z" and (absf(box.end.z - float(plane.at)) < 0.12 or absf(box.position.z - float(plane.at)) < 0.12))
		var centre := box.get_center()
		for surface in surfaces:
			if surface == box:
				continue
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

## Each object resting on furniture has the visible surface under its whole footprint (nine points 1.5 cm in from its
## edges, rays against trimesh copies of the visible meshes on a test-only layer, never the coarse collision boxes).
func _check_footprints(room: CampaignRoom, staged: Node3D, resting: Array[Node3D], scene_id: String) -> void:
	if resting.is_empty():
		return
	var holder := Node3D.new()
	room.add_child(holder)
	var owners := {}
	for node in room.visual_root.get_children() + staged.get_children():
		if not node is Node3D or node == staged or String(node.name) in ["HabitatKit", "Garage", "berm"]:
			continue
		var meshes := (node as Node).find_children("*", "MeshInstance3D", true, false)
		if node is MeshInstance3D:
			meshes.append(node)
		for mesh in meshes:
			var instance := mesh as MeshInstance3D
			if instance.mesh == null or instance.visibility_range_begin > 0.0 or not instance.is_visible_in_tree():
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

## Every staged word faces walkable deck within a 50-degree cone and 2.2 m, is single-sided and in player language.
func _check_staged_text(room: CampaignRoom, map: RID, scene_id: String) -> void:
	var staged := room.visual_root.get_node(Staging.ROOT_NAME) as Node3D
	for label in staged.find_children("*", "Label3D", true, false):
		if not label.is_visible_in_tree() or label.billboard != BaseMaterial3D.BILLBOARD_DISABLED or String(label.text).strip_edges().is_empty():
			continue
		for regex in _patterns:
			_check(regex.search(String(label.text)) == null, scene_id + " staged words stay in player language: " + String(label.text).left(40))
		_check(not label.double_sided, scene_id + " staged words are single-sided: " + String(label.text).left(40))
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
		_check(front < 0.35, scene_id + " staged words read from walkable deck: " + String(label.text).left(40))

# ------------------------------------------------------------------------------------------------- the joins

func _text(staged: Node, id: String) -> String:
	var label := staged.get_node_or_null(id) as Label3D
	return label.text if label != null else ""

## Doc 24 section 2.9: CH04 S01 -> S02 (the rover checklist), S02 -> S03 (two field and two home), S08 -> S09 (the case
## travelling home), S09 -> S10 (the dry glovebox), CH04 -> CH05 (the 8-12 Dec flight), CH05 S01 -> S02 (the five-person
## roster), CH07 -> CH08 (the duplicate checklists and the two destination boards), CH08 S10 -> S11 (the same road home).
func _check_bridges(room: CampaignRoom, scene_id: String) -> void:
	var staged := room.visual_root.get_node(Staging.ROOT_NAME) as Node3D
	var bay := room.garage()
	var board_rover := _text(staged, "board_rover")
	var board_aurora := _text(staged, "board_aurora")
	_check(not board_rover.is_empty() and not board_aurora.is_empty(), scene_id + " both departure boards carry live words (decision 7)")
	_check(not _text(staged, "seal_status").is_empty() and not _text(staged, "supply_ledger").is_empty() and not _text(staged, "pad_camera_text").is_empty(), scene_id + " the seal station, the supply ledger and the pad camera are lit with words")
	match scene_id:
		"EX-CH04-S02", "EX-CH04-S03":
			_check(board_rover.contains("RAFI") and board_rover.contains("KAI") and not board_rover.contains("MEI") and board_aurora.contains("MEI") and board_aurora.contains("AMARA") and not board_aurora.contains("KAI"), scene_id + " each person is on exactly one ledger: two field, two home (S02 -> S03)")
			_check(_text(staged, "supply_ledger").contains("48 H") and _text(staged, "supply_ledger").contains("NOT ON THE"), scene_id + " the rover's independent manifest is separate from the base ledger")
			_check(staged.has_node("PR_VaultCarrier") and staged.has_node("PR_IceScanner"), scene_id + " the closed carrier and the scanner wait to go out with the rover")
			_check(staged.has_node("spare_light") and _text(staged, "spare_light_label").contains("SPARE LIGHT"), scene_id + " Kai's spare light hangs in its labelled position")
			_check(bay.dock_state() == "SAFE TO OPEN", scene_id + " the departing rover's tunnel holds cabin pressure")
			_check(staged.has_node("card_b_text") == (scene_id == "EX-CH04-S03"), scene_id + " the three route cards are on the board only for the route choice")
			if scene_id == "EX-CH04-S03":
				_check(_text(staged, "card_b_text").contains("12°") and _text(staged, "card_b_text").contains("40 LEFT") and _text(staged, "card_b_text").contains("30 NEEDED"), scene_id + " route B passes both limits with canon's numbers (P-07)")
				_check(_text(staged, "card_a_text").contains("15°") and _text(staged, "card_c_text").contains("RETURN RESERVE"), scene_id + " routes A and C carry the reason each fails")
				_check(_text(staged, "console_map").contains("BLIND CORNER"), scene_id + " the radio plan bends with the ridge (S03 -> S04)")
		"EX-CH04-S09":
			_check(bay.dock_state() == "SEALED" and not bay.is_dock_hatch_open(), scene_id + " the returning rover's tunnel starts SEALED: the player equalises it")
			_check(bay.is_lock_door_open("InnerDoor") and not bay.is_lock_door_open("OuterDoor"), scene_id + " the dry cargo lock's inner door is open, the porch door shut")
			var chamber: Dictionary = Contract.layout("LOC-08").sealed_enclosures[0]
			var lock := AABB(Presentation.vector(chamber.min), Presentation.vector(chamber.max) - Presentation.vector(chamber.min)).grow(0.02)
			_check(lock.encloses(_bounds(room, staged.get_node("vault_case"))) and lock.encloses(_bounds(room, staged.get_node("sleeve_base"))), scene_id + " the sealed case lies in its sleeve inside the dry cargo lock (decision 5)")
			_check(staged.has_node("sealed_sample") and _text(staged, "sample_tag").contains("OWN RECORD"), scene_id + " the sealed sample keeps its own record")
			var report := _text(staged, "console_slope")
			_check(report.contains("CREW 2") and report.contains("CARGO 2") and report.contains("PRESSURE") and report.contains("RESERVE"), scene_id + " the same report shape: crew, cargo, pressure, reserve")
			_check(_text(staged, "lock_status").contains("SEALED CASE"), scene_id + " the lock shows the case is in, sealed (S09 -> S10: the dry glovebox)")
		"EX-CH05-S01":
			_check(bay.dock_state() == "SEALED", scene_id + " the open command waits for two agreeing checks: the tunnel starts SEALED")
			_check(_text(staged, "pad_camera_text").contains("500 M") and _text(staged, "pad_camera_text").contains("DUST SETTLED"), scene_id + " Ferreira is on the landing-pad camera, dust settled (no plume)")
			_check(board_aurora.contains("FERREIRA") and board_aurora.contains("FIVE"), scene_id + " the five-person roster (S01 -> S02)")
			_check(_text(staged, "relief_locker_plate").contains("8–12 DEC") and _text(staged, "lock_status").contains("RELIEF CARGO"), scene_id + " the relief cargo waits in the cargo lock for its seal check; the relief locker is labelled for the 8-12 Dec flight")
		"EX-CH07-S12", "EX-CH08-S01":
			_check(board_rover.contains("FERREIRA\nKAI\nRAFI") and board_aurora.contains("MEI\nAMARA"), scene_id + " five names face two destination boards")
			_check(staged.has_node("packed_case") and _text(staged, "packed_case_text").contains("PACKED") and _text(staged, "route_card_text").contains("THREE ROAD REPEATERS") and staged.has_node("repeater_case_3"), scene_id + " the controller Kai labelled, the route and three repeaters are packed (CH07 S11 -> S12)")
			for id in ["checklist_rover_text", "checklist_aurora_text"]:
				var sheet := _text(staged, id)
				_check(sheet.contains("8 APR 2047, 00:00") and sheet.contains("SMALL GUIDE LIGHT: IN THE PLAN"), scene_id + " duplicate checklist dated 8 Apr 00:00 with the guide light in the plan (CH07 -> CH08): " + id)
			_check(_text(staged, "home_ledger_text").contains("33 H") and _text(staged, "home_ledger_text").contains("LAST 3 H"), scene_id + " the home-night ledger counts two, then five")
			_check(_text(staged, "console_map").contains("24 H OUT") and _text(staged, "console_map").contains("72 H"), scene_id + " the journey card: 24 out, 3 repair, 24 back, 72 h of supplies")
			_check(["helmet_1", "helmet_2", "helmet_3"].all(func(h): return staged.has_node(h)), scene_id + " three travellers, three helmets")
		"EX-CH08-S11":
			_check(bay.dock_state() == "SEALED", scene_id + " the airlock does not open because a reunion is due: the tunnel starts SEALED")
			_check(board_rover.contains("HOME") and board_aurora.contains("FIVE HOME"), scene_id + " five home, three hours to first light")
	_check(_text(staged, "relief_locker_plate").contains("RELIEF CARGO") == (Contract.scene_order(scene_id) >= 412 and Contract.scene_order(scene_id) <= 512), scene_id + " the relief locker is labelled for the relief cargo from CH04-S12 to CH05")

## Doc 24 section 5.2 D12 in the garage: Kai packs his family's copy only with its recorded option.
func _check_echoes() -> void:
	var room := await _room("LOC-08")
	room.set_scene_context("EX-CH07-S12")
	await process_frame
	var staged := room.visual_root.get_node(Staging.ROOT_NAME)
	_check(not staged.has_node("kai_family_copy"), "no D12 copy without its choice")
	for option in {"EX-CH06-S08-OPT01": "THE RING DIAGRAM", "EX-CH06-S08-OPT02": "THE PROTECTED-SERVICE PLAN"}.keys():
		var words: String = {"EX-CH06-S08-OPT01": "THE RING DIAGRAM", "EX-CH06-S08-OPT02": "THE PROTECTED-SERVICE PLAN"}[option]
		room.set_story_choices({"EX-CH06-S08-CHOICE": {"option_id": option}})
		await process_frame
		staged = room.visual_root.get_node(Staging.ROOT_NAME)
		_check(_text(staged, "kai_family_copy_text").contains(words), "D12 %s: Kai packs his family's copy for the rover" % option)
	room.free()
	await process_frame

## Re-staging puts the base garage back exactly: nodes, navigation, stations, the garage's pose and the screens.
func _check_restaging() -> void:
	var room := await _room("LOC-08")
	var region := room.navigation_root.get_node("NavigationRegion") as NavigationRegion3D
	var base_polys := region.navigation_mesh.get_polygon_count()
	var base_focus := room.focus_root.get_child_count()
	for scene_id in ["EX-CH04-S09", "EX-CH07-S12", "EX-CH04-S02", "EX-CH05-S01", "EX-CH01-S01"]:
		room.set_scene_context(scene_id)
		await process_frame
		var bay := room.garage()
		if scene_id == "EX-CH01-S01":
			region = room.navigation_root.get_node("NavigationRegion") as NavigationRegion3D
			_check(not room.visual_root.has_node(Staging.ROOT_NAME) and room.stage().layers.is_empty(), "outside its scenes the garage carries no chapter staging")
			_check(region.navigation_mesh.get_polygon_count() == base_polys and room.focus_root.get_child_count() == base_focus, "the base garage's navigation and stations return exactly")
			_check(not bay.is_lock_door_open("InnerDoor") and bay.dock_state() == "SAFE TO OPEN", "the garage's pose returns to rest")
			var glowing := room.visual_root.find_children("*", "MeshInstance3D", true, false).filter(func(m): return (m as MeshInstance3D).get_surface_override_material_count() > 0 and range((m as MeshInstance3D).get_surface_override_material_count()).any(func(i): return (m as MeshInstance3D).get_surface_override_material(i) != null and (m as MeshInstance3D).get_surface_override_material(i).resource_name == "Screen_live"))
			_check(glowing.is_empty(), "no live screen material is left behind")
		elif scene_id == "EX-CH04-S02":
			_check(not bay.is_lock_door_open("InnerDoor") and room.stage().layers.has("ch04_departure") and not room.stage().layers.has("ch07_departure"), "S02 after CH07-S12: the departure kit, without the April loadout or the open lock")
	room.free()
	await process_frame

## The real cast placement: the room is staged first, bodies stand at the scene anchors, and a cadet in the vacuum wears
## their fitted EVA suit (CH_<Name>_EVA, M3-3A): Kai on the porch in S09, nobody suited on the pressurised deck.
func _check_crew() -> void:
	var crew := Crew.new()
	root.add_child(crew)
	for scene_id in ["EX-CH04-S02", "EX-CH04-S09", "EX-CH05-S01", "EX-CH07-S12", "EX-CH04-S03"]:
		var room := await _room("LOC-08")
		var start: Array = Contract.anchors("LOC-08").rover_player
		var player := crew.place(scene_id, room, Vector3(start[0], start[1], start[2]))
		for frame in 4:
			await physics_frame
		_check(room.scene_context() == scene_id and not room.stage().layers.is_empty(), scene_id + " the room is staged by the crew placement")
		var roster := Roster.scene_roster(scene_id)
		var here := roster.keys().filter(func(id): return roster[id].physical_location_id == "LOC-08")
		_check(crew.local_ids.size() == here.size(), scene_id + " everyone the roster puts in the garage is placed (%d)" % here.size())
		for id in crew.local_ids:
			var body: PlayerController = crew.bodies[id]
			var suited := String(body.loaded_path).ends_with("_EVA.glb")
			_check(suited == (String(room.stage().outfits.get(id, "")) == "eva"), "%s %s %s" % [scene_id, id, "wears the EVA suit in the vacuum" if suited else "is unsuited in the ready room"])
			if suited:
				_check(body.character.find_children("Helmet", "Node3D", true, false).size() == 1, "%s %s wears the role helmet on the suit's neck ring (M3-3A)" % [scene_id, id])
			_check(body.visible and body.collision_layer == 2, "%s %s is shown and solid" % [scene_id, id])
			if body == player:
				continue
			var at := Crew.anchor_position("LOC-08", id, scene_id)
			_check(Vector2(body.position.x - at.x, body.position.z - at.z).length() < 0.15, "%s %s placed at the scene anchor" % [scene_id, id])
		_check(crew.get_children().filter(func(n): return n is PlayerController and n.visible).size() == crew.local_ids.size(), scene_id + " no hidden suited or unsuited twin is shown")
		room.free()
		await process_frame
	crew.free()
	await process_frame

# ------------------------------------------------------------------------------------------------- capture

const SHOTS := [
	["EX-CH04-S02", "ch04_departure", "M3-105_S02_departure_kit"],
	["EX-CH04-S02", "ch04_boards", "M3-105_S02_two_ledgers"],
	["EX-CH04-S02", "ch04_spare_light", "M3-105_S02_spare_light"],
	["EX-CH04-S02", "overview", "M3-105_S02_ready_room"],
	["EX-CH04-S03", "ch04_route_cards", "M3-105_S03_route_cards"],
	["EX-CH04-S03", "pressure_wall", "M3-105_S03_pressure_wall"],
	["EX-CH04-S09", "ch04_return_dock", "M3-105_S09_dock_sealed"],
	["EX-CH04-S09", "ch04_dock_panel", "M3-105_S09_dock_panel_sealed"],
	["EX-CH04-S09", "ch04_dock_panel", "M3-105_S09_dock_panel_equalising", "equalise"],
	["EX-CH04-S09", "ch04_return_lock", "M3-105_S09_case_in_dry_lock"],
	["EX-CH04-S09", "ch04_return_porch", "M3-105_S09_kai_on_porch"],
	["EX-CH04-S09", "bay", "M3-105_S09_vacuum_bay"],
	["EX-CH05-S01", "ch05_pad_camera", "M3-105_CH05_S01_pad_camera"],
	["EX-CH05-S01", "ch05_relief_locker", "M3-105_CH05_S01_relief_locker"],
	["EX-CH07-S12", "ch07_departure", "M3-105_CH07_S12_destination_boards"],
	["EX-CH07-S12", "ch07_loadout", "M3-105_CH07_S12_loadout"],
	["EX-CH08-S11", "boards", "M3-105_CH08_S11_five_home"],
]

func _capture_all() -> void:
	var crew := Crew.new()
	root.add_child(crew)
	var camera := Camera3D.new()
	camera.fov = 70
	root.add_child(camera)
	var room: CampaignRoom = null
	var current := ""
	for shot in SHOTS:
		var scene_id := String(shot[0])
		if scene_id != current:
			if room != null:
				room.free()
				await process_frame
			room = await _room(Contract.room_for_scene(scene_id))
			var start: Array = Contract.anchors(room.room_id)[PLAYER_ANCHOR[room.room_id]]
			crew.place(scene_id, room, Vector3(start[0], start[1], start[2]))
			current = scene_id
			for frame in 30:
				await process_frame
		if shot.size() > 3 and String(shot[3]) == "equalise":
			room.garage().request_dock_cycle("habitat")  # the returning crew equalise the tunnel: pump hum and time card
			room.garage().set_process(false)  # hold the cycle mid-way for the picture
		var spec: Dictionary = Contract.staged_layout(room.room_id, scene_id).review_views.get(String(shot[1]), {})
		camera.position = Presentation.vector(spec.from)
		camera.look_at(Presentation.vector(spec.to))
		camera.current = true
		for frame in 20:
			await process_frame
		await _draw_frame()
		await _save(String(shot[2]))
		print("saved ", shot[2])
	if room != null:
		room.free()
	camera.free()
	crew.free()
	await _capture_garage_exterior()

## The garage on the real Aurora ridge (M1-82 frame, exterior_terrain.json LOC-08: 80 m from Aurora at azimuth 150, the
## rover door turned to azimuth 100) under the dated EX-CH04-S02 Sun from its JPL Horizons row, rover door open.
func _capture_garage_exterior() -> void:
	var place := Contract.terrain("LOC-08")
	var origin := Presentation.vector(place.origin_m)
	var room := await _room("LOC-08")
	room.set_scene_context("EX-CH04-S02")
	room.garage().set_rover_door_open(true)
	room.get_node("RoomLighting/RoomEnvironment").free()
	var site := Node3D.new()
	site.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(float(place.yaw_deg))), origin).affine_inverse()
	root.add_child(site)
	var stream := Stream.new()
	site.add_child(stream)
	stream.configure(String(place.region_id), origin, [{"position": origin, "radius_m": 24.0}])
	var rig := stream.lighting("EX-CH04-S02")
	_check(rig != null, "the garage's exterior has its dated EX-CH04-S02 Sun")
	if rig != null:
		site.add_child(rig)
	for frame in 600:
		await process_frame
		if stream.pending.is_empty() and frame > 60:
			break
	var camera := Camera3D.new()
	camera.far = 70000.0
	root.add_child(camera)
	for view in [["M3-105_exterior_rover_door", Vector3(24.0, 1.2, 9.0), Vector3(4.0, -0.4, 1.5), 62.0], ["M3-105_exterior_berm", Vector3(30.0, 6.0, -16.0), Vector3(2.0, 0.0, 0.0), 55.0]]:
		camera.fov = float(view[3])
		camera.position = view[1]
		camera.look_at(view[2])
		camera.current = true
		for frame in 30:
			await process_frame
		await _draw_frame()
		await _save(String(view[0]))
		print("saved ", view[0])
	camera.free()
	site.free()
	room.free()
	await process_frame

## Waits for the next drawn frame; when macOS reports the window covered, renders the viewports itself.
func _draw_frame() -> void:
	var drawn := _drawn_frames
	for frame in 30:
		await process_frame
		if _drawn_frames > drawn:
			return
	RenderingServer.force_draw(false)

func _save(id: String) -> void:
	var image := root.get_texture().get_image()
	for attempt in 120:
		if not _blank(image):
			break
		await _draw_frame()
		image = root.get_texture().get_image()
	_check(not _blank(image), "capture " + id + " shows a rendered frame")
	_check(image.save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/%s.png" % id)) == OK, "capture " + id)

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
		if (mesh as GeometryInstance3D).visibility_range_begin > 0.0 or not mesh.is_visible_in_tree() or mesh.name == "Edge" or mesh.get_viewport() != room.get_viewport():
			continue
		var local: AABB = room.global_transform.affine_inverse() * mesh.global_transform * mesh.get_aabb()
		box = local if first else box.merge(local)
		first = false
	return box
