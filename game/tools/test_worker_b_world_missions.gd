## Godot --headless --path game --script res://tools/test_worker_b_world_missions.gd
extends SceneTree

const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const SaveScript = preload("res://scripts/save/save_service.gd")
const RoomContract = preload("res://scripts/world/room_contract.gd")
const RoomScript = preload("res://scripts/world/campaign_room.gd")
const WorldRouteScript = preload("res://scripts/world/world_route.gd")
const NavigationScript = preload("res://scripts/navigation/route_navigation.gd")
const RosterScript = preload("res://scripts/companions/companion_roster.gd")
const DispatcherScript = preload("res://scripts/interactions/interaction_dispatcher.gd")
const RouteScript = preload("res://scripts/missions/chapter1_route.gd")
const RegistryScript = preload("res://scripts/missions/mission_registry.gd")
const GateCatalog = preload("res://scripts/missions/chapter1_gate_catalog.gd")
const PlanFixture = preload("res://tools/support/p02_plan_fixture.gd")

var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await _test_room_contracts_and_loading()
	_test_navigation_and_pressure_boundaries()
	_test_rosters_and_switching()
	_test_dispatcher_transaction_fixture()
	_test_registry_honesty()
	_test_chapter1_route_order_and_physical_gates()
	print("WORKER B WORLD/MISSIONS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_room_contracts_and_loading() -> void:
	var scene_paths := {
		"LOC-01": "res://scenes/campaign/rooms/commons.tscn",
		"LOC-02": "res://scenes/campaign/rooms/service_rooms.tscn",
		"LOC-03": "res://scenes/campaign/rooms/garden.tscn",
		"LOC-04": "res://scenes/campaign/rooms/safe_room.tscn",
		"LOC-06": "res://scenes/campaign/rooms/exterior.tscn",
	}
	for room_id in scene_paths:
		var validation := RoomContract.validate(room_id)
		_check(bool(validation.get("valid", false)), room_id + " room contract validates")
		var contract := RoomContract.room(room_id)
		_check(contract.get("bounds_m", []).size() == 2 and contract.get("focus_targets", []).size() > 0, room_id + " declares canonical dimensions and focus targets")
		for asset_path in contract.get("asset_paths", []):
			_check(FileAccess.file_exists(String(asset_path)), room_id + " reuses an existing approved asset: " + String(asset_path).get_file())
		var packed: PackedScene = load(scene_paths[room_id])
		_check(packed != null, room_id + " room scene loads")
		var room: CampaignRoom = packed.instantiate() as CampaignRoom
		room.load_approved_assets = false
		get_root().add_child(room)
		await process_frame
		var roots := room.named_roots()
		for root_name in ["visual_root", "collision_root", "focus_root", "pressure_root", "door_root", "anchor_root", "navigation_root"]:
			_check(roots.get(root_name) != null, room_id + " exposes named " + root_name)
		_check(room.get_node("CollisionRoot").get_child_count() >= 5, room_id + " has independent collision geometry")
		_check(room.collision_root.get_node("FloorCollision").find_children("*", "MeshInstance3D", true, false).size() > 0, room_id + " has a visible floor for navigation")
		_check(room.get_node("FocusTargets").get_child_count() == contract.get("focus_targets", []).size(), room_id + " registers every focus target")
		_check(room.get_node("PressureBoundaries").get_child_count() == contract.get("boundary_ids", []).size(), room_id + " registers pressure boundaries")
		room.queue_free()
		await process_frame

func _test_navigation_and_pressure_boundaries() -> void:
	var boundary_validation := NavigationScript.validate_boundaries()
	_check(bool(boundary_validation.get("valid", false)), "all named Chapter 1 pressure boundaries validate")
	_check(not NavigationScript.can_traverse("LOC-01", "LOC-06", {}).get("accepted", false), "closed exterior airlock blocks direct movement")
	_check(not NavigationScript.can_traverse("LOC-03", "GARDEN_CHAMBER", {"garden_viewing_shutter": NavigationScript.default_boundary_state("garden_viewing_shutter")}).get("accepted", false), "closed garden viewing shutter blocks chamber traversal")
	_check(NavigationScript.point_inside_room("LOC-01", Vector3.ZERO), "Commons route bounds contain its player origin")
	_check(not NavigationScript.point_inside_room("LOC-02", Vector3(8.0, 0.0, 0.0)), "Service Rooms route bounds reject an outside point")
	var world := WorldRouteScript.new(DirectorScript.new())
	var blocked := world.can_traverse_to("LOC-06")
	_check(not bool(blocked.get("accepted", false)), "WorldRoute preserves the closed airlock boundary")
	var no_suit := world.prepare_airlock(false)
	_check(not bool(no_suit.get("accepted", false)), "airlock preparation rejects missing suit check")
	var prepared := world.prepare_airlock(true)
	_check(bool(prepared.get("accepted", false)), "airlock preparation accepts suit and exposure checks")
	var outside := world.transition_to("LOC-06")
	_check(bool(outside.get("accepted", false)) and world.current_room_id() == "LOC-06", "prepared airlock permits safe exterior traversal")
	world.close_airlock()
	_check(not bool(world.can_traverse_to("LOC-01").get("accepted", false)), "closed airlock blocks return traversal")
	var shutter_bad := world.open_garden_shutter(false)
	_check(not bool(shutter_bad.get("accepted", false)), "garden shutter rejects an unverified chamber")
	var shutter_good := world.open_garden_shutter(true)
	_check(bool(shutter_good.get("accepted", false)) and bool(world.boundary_state("garden_viewing_shutter").get("open", false)), "verified garden shutter opens through the route service")
	var authored_world := WorldRouteScript.new(DirectorScript.new())
	var authored_base_cut := authored_world.set_scene("EX-CH01-S11", {"authored_viewpoint_cut": true, "label": "test base-room cut"})
	_check(bool(authored_base_cut.get("accepted", false)) and authored_world.current_room_id() == "LOC-03", "authored base-room scene cut updates the world without bypassing the exterior airlock")

func _test_rosters_and_switching() -> void:
	var world := WorldRouteScript.new()
	for chapter in range(1, 9):
		for number in range(1, 13):
			var id := "EX-CH%02d-S%02d" % [chapter, number]
			var entered := world.set_scene(id, {"authored_viewpoint_cut": true})
			var actors := world.roster()
			var player := RosterScript.playable_actor(id)
			_check(bool(entered.get("accepted", false)) and actors.has(player) and actors[player].physical_location_id == world.current_room_id(), "B10 production roster and structured playable actor agree for " + id)
			_check((actors.ferreira.physical_location_id == "EARTH_SCREEN") == (chapter < 5), "B10 Ferreira arrival is honored for " + id)
			if chapter in [4, 8]:
				_check(actors.mei.physical_location_id in ["LOC-01", "LOC-02", "LOC-03", "LOC-04", "LOC-05"] and actors.amara.physical_location_id in ["LOC-01", "LOC-02", "LOC-03", "LOC-04", "LOC-05"], "B10 Mei and Amara remain at Aurora for " + id)
			if (chapter == 4 and number >= 2 and number <= 9) or (chapter == 8 and number <= 11):
				_check(actors.kai.physical_location_id == actors.rafi.physical_location_id and actors.kai.physical_location_id != actors.mei.physical_location_id and (chapter != 8 or actors.ferreira.physical_location_id == actors.kai.physical_location_id), "B10 canonical rover team remains separate for " + id)
	world.set_scene("EX-CH05-S01", {"authored_viewpoint_cut": true})
	var stale_roster := world.snapshot()
	stale_roster.roster.ferreira.physical_location_id = "EARTH_SCREEN"
	_check(bool(world.restore(stale_roster).get("accepted", false)) and world.roster().ferreira.physical_location_id != "EARTH_SCREEN", "B10 old saved rosters inherit the corrected physical arrival")
	var temporary = RouteScript.new()
	var reference: WeakRef = weakref(temporary)
	temporary = null
	_check(reference.get_ref() == null, "staged route validation releases its dispatcher and director instead of leaking every autosave")

	var ch01 := RosterScript.scene_roster("EX-CH01-S01")
	_check(bool(RosterScript.validate_roster(ch01).get("valid", false)), "Chapter 1 scene roster validates")
	_check(String(ch01.kai.physical_location_id) == "LOC-01" and String(ch01.ferreira.physical_location_id) == "EARTH_SCREEN", "Mei/Aurora cadets are physical while Ferreira remains Earth-side")
	_check(bool(RosterScript.can_switch(ch01, "kai", "mei").get("accepted", false)), "co-located cadets can switch viewpoint")
	_check(not bool(RosterScript.can_switch(ch01, "kai", "ferreira").get("accepted", false)), "Earth-screen Ferreira cannot be freely selected as a lunar body")
	var ch04 := RosterScript.chapter_roster("CH04")
	_check(String(ch04.kai.physical_location_id) == "LOC-09" and String(ch04.rafi.physical_location_id) == "LOC-09" and String(ch04.mei.physical_location_id) == "LOC-01", "CH04 field/base roster preserves Kai/Rafi versus Mei/Amara")
	var ch08 := RosterScript.chapter_roster("CH08")
	_check(String(ch08.ferreira.physical_location_id) == "LOC-11" and String(ch08.kai.team_id) == "rover" and String(ch08.mei.team_id) == "home", "CH08 roster preserves Ferreira/Kai/Rafi rover and Mei/Amara home")

func _test_dispatcher_transaction_fixture() -> void:
	var director := DirectorScript.new()
	var dispatcher := DispatcherScript.new(director)
	dispatcher.register_target({
		"target_id": "fixture_valve",
		"room_id": "LOC-02",
		"focus_label": "Fixture valve",
		"verb": "Use",
		"command_verb": "set_phase",
		"command_target_id": "WORLD_PHYSICAL",
		"command_id": "fixture-valve-01",
		"owning_mission_id": "EX-M0103",
		"owning_scene_id": "EX-CH01-S07",
		"required_flags": ["calibrated"],
	})
	var missing := dispatcher.focus("fixture_valve", {"room_id": "LOC-02", "flags": {"calibrated": false}})
	_check(not bool(missing.get("accepted", false)), "interaction prerequisite rejects an uncalibrated target")
	var focused := dispatcher.focus("fixture_valve", {"room_id": "LOC-02", "flags": {"calibrated": true}})
	_check(bool(focused.get("accepted", false)), "focus succeeds after physical prerequisite")
	var inspected := dispatcher.inspect()
	var used := dispatcher.use({"phase": "fixture:valve"})
	var preview := dispatcher.preview()
	_check(bool(inspected.get("accepted", false)) and bool(used.get("accepted", false)) and bool(preview.get("accepted", false)), "focus -> inspect -> use -> preview reaches a pure preview")
	_check(int(director.query().get("state_revision", -1)) == 0, "interaction preview leaves authoritative revision unchanged")
	var committed := dispatcher.confirm()
	_check(bool(committed.get("accepted", false)) and int(director.query().get("state_revision", -1)) == 1, "explicit confirm produces the physical state result")
	var duplicate := dispatcher.confirm()
	_check(bool(duplicate.get("duplicate", false)) and int(director.query().get("state_revision", -1)) == 1, "duplicate confirm returns one receipt without a second commit")
	var cancel_focus := dispatcher.focus("fixture_valve", {"room_id": "LOC-02", "flags": {"calibrated": true}})
	dispatcher.use({"phase": "fixture:cancel"})
	dispatcher.preview()
	dispatcher.cancel("fixture cancel")
	_check(not bool(dispatcher.confirm().get("accepted", false)), "cancel removes the pending physical confirmation")
	var stale_dispatcher := DispatcherScript.new(director)
	stale_dispatcher.register_target({
		"target_id": "fixture_stale",
		"room_id": "LOC-02",
		"focus_label": "Stale fixture",
		"verb": "Use",
		"command_verb": "set_phase",
		"command_target_id": "WORLD_PHYSICAL",
		"command_id": "fixture-stale-01",
		"owning_mission_id": "EX-M0103",
		"owning_scene_id": "EX-CH01-S07",
	})
	stale_dispatcher.focus("fixture_stale", {"room_id": "LOC-02"})
	stale_dispatcher.use({"phase": "fixture:stale"})
	stale_dispatcher.preview()
	var external := {"command_id": "fixture-external", "issuer": "test", "owning_mission_id": "EX-M0103", "owning_scene_id": "EX-CH01-S07", "expected_state_revision": int(director.query().get("state_revision", 0)), "target_id": "WORLD_PHYSICAL", "verb": "set_phase", "payload": {"phase": "fixture:external"}}
	_check(bool(director.commit(external).get("accepted", false)), "external command advances the revision for stale fixture")
	_check(not bool(stale_dispatcher.confirm().get("accepted", false)), "stale preview is rejected without mutation")
	var paused := director.pause("fixture pause")
	_check(bool(paused.get("accepted", false)), "pause is explicit and accepted")
	_check(not bool(director.commit({"command_id": "fixture-paused", "issuer": "test", "owning_mission_id": "EX-M0103", "owning_scene_id": "EX-CH01-S07", "expected_state_revision": int(director.query().get("state_revision", 0)), "target_id": "WORLD_PHYSICAL", "verb": "set_phase", "payload": {"phase": "fixture:blocked"}}).get("accepted", false)), "pause blocks a physical commit")
	director.resume()
	var save := SaveScript.new()
	var path := OS.get_temp_dir().path_join("worker_b_fixture_%d.json" % Time.get_ticks_usec())
	var saved := save.save(director.snapshot(), path)
	var loaded := save.load(path)
	_check(bool(saved.get("accepted", false)) and bool(loaded.get("accepted", false)) and loaded.get("snapshot", {}).get("state_revision", -1) == director.snapshot().get("state_revision", -2), "physical fixture state survives primitive save/load")
	save.clear(path)

func _test_registry_honesty() -> void:
	var registry := RegistryScript.new()
	var validation := registry.validate_honesty()
	_check(bool(validation.get("valid", false)), "mission registry loads 32 canonical missions and exposes honest blocked gates")
	_check(int(validation.get("status", {}).get("implemented_count", 0)) == 8 and int(validation.get("status", {}).get("unimplemented_count", 0)) == 24, "registry distinguishes the four Chapter 1 and four Chapter 2 adapters from 24 unimplemented missions")
	var later = registry.create("EX-M0201")
	var later_status: Dictionary = later.status()
	_check(String(later_status.get("status", "")) in ["ready", "active", "complete"] and later_status.get("missing_scene_ids", []).size() == 3, "Chapter 2 mission status exposes its three physical scene gates")
	var chapter_scene: PackedScene = load("res://scenes/campaign/missions/EX-M0101.tscn")
	var mission_scene: Node = chapter_scene.instantiate()
	_check(String(mission_scene.get("mission_id")) == "EX-M0101" and mission_scene.get("scene_ids").size() == 3, "EX-M0101 scene composition exposes its three canonical scenes")
	mission_scene.free()

func _test_chapter1_route_order_and_physical_gates() -> void:
	var route := RouteScript.new(DirectorScript.new())
	PlanFixture.prepare(route)
	var dialogue_only := route.acknowledge_dialogue("EX-CH01-S01-L01")
	_check(bool(dialogue_only.get("accepted", false)) and not bool(route.gate_status().get("ready", false)), "dialogue acknowledgement never completes the S01 physical gate")
	_check(bool(route.perform("commission_route").get("accepted", false)), "S01 commissioning route is a real interaction")
	_check(bool(route.perform("commission_result").get("accepted", false)), "S01 result inspection is a separate physical action")
	_check(bool(route.perform("charter_card").get("accepted", false)), "S01 charter acknowledgement is a physical card read")
	_check(bool(route.advance_scene().get("accepted", false)) and route.current_scene_id() == "EX-CH01-S02", "S01 advances only after all physical predicates")
	for target_id in ["classify_information", "roll_call", "practice_fault"]:
		_check(bool(route.perform(target_id).get("accepted", false)), "S02 physical action committed: " + target_id)
	_check(bool(route.advance_scene().get("accepted", false)) and route.current_scene_id() == "EX-CH01-S03", "S02 advances in canonical order")
	for target_id in ["calibrate_probe", "span_probe", "recheck_probe", "inspect_packet", "compare_atmosphere"]:
		print("BEGIN S03 ", target_id)
		_check(bool(route.perform(target_id).get("accepted", false)), "S03 P-01 physical action committed: " + target_id)
	_check(bool(route.advance_scene().get("accepted", false)) and route.current_scene_id() == "EX-CH01-S04", "S03 advances only after calibration, provenance and atmosphere checks")
	for target_id in ["plant_alo", "plant_tara", "water_alo", "water_tara", "label_alo", "label_tara", "seal_alo", "seal_tara", "record_paired_conditions", "confirm_services"]:
		_check(bool(route.perform(target_id).get("accepted", false)), "S04 P-01/garden action committed: " + target_id)
	_check(bool(route.advance_scene().get("accepted", false)) and route.current_scene_id() == "EX-CH01-S05", "S04 plants both cassettes and advances")
	for target_id in ["test_hand_light", "care_montage", "confirm_date_transition"]:
		_check(bool(route.perform(target_id).get("accepted", false)), "S05 dated-care action committed: " + target_id)
	_check(bool(route.advance_scene().get("accepted", false)) and route.current_scene_id() == "EX-CH01-S06", "S05 requires explicit date transition")
	for target_id in ["arrange_timeline", "ack_schedule"]:
		_check(bool(route.perform(target_id).get("accepted", false)), "S06 timeline action committed: " + target_id)
	_check(bool(route.advance_scene().get("accepted", false)) and route.current_scene_id() == "EX-CH01-S07", "S06 advances without dialogue-only completion")
	_check(bool(route.perform("role_cards").get("accepted", false)), "S07 role acknowledgement is a physical role-card check")
	_check(bool(route.perform("p02_shift1").get("accepted", false)), "P-02 shift 1 goes through PuzzleHost and ExpeditionSimulation")
	_check(bool(route.perform("p02_stage_shift2").get("accepted", false)), "P-02 shift 2 preview is staged and paused without committing")
	_check(int(route.director().snapshot().get("current_shift", -1)) == 1, "staged shift 2 does not advance the authoritative shift")
	_check(bool(route.advance_scene().get("accepted", false)) and route.current_scene_id() == "EX-CH01-S08", "S07 requires committed shift 1 plus staged shift 2")
	for target_id in ["shelter_drill", "verify_drill_baseline", "p02_shift2"]:
		_check(bool(route.perform(target_id).get("accepted", false)), "S08 physical/P-02 action committed: " + target_id)
	_check(bool(route.advance_scene().get("accepted", false)) and route.current_scene_id() == "EX-CH01-S09", "S08 commits shift 2 only after no-cost drill verification")
	for target_id in ["combine_cards", "ack_earth_set", "p02_shifts3_4"]:
		_check(bool(route.perform(target_id).get("accepted", false)), "S09 physical/P-02 action committed: " + target_id)
	_check(bool(route.advance_scene().get("accepted", false)) and route.current_scene_id() == "EX-CH01-S10", "S09 resolves shifts 3-4 in order")
	for target_id in ["confirm_four_sheltered", "p02_shift5_alarm"]:
		_check(bool(route.perform(target_id).get("accepted", false)), "S10 shelter/alarm action committed: " + target_id)
	_check(bool(route.advance_scene().get("accepted", false)) and route.current_scene_id() == "EX-CH01-S11", "S10 commits exactly one exclusive alarm response")
	for target_id in ["verify_exposure_order", "return_water", "p02_shifts6_7", "review_outcome"]:
		_check(bool(route.perform(target_id).get("accepted", false)), "S11 recovery/P-02 action committed: " + target_id)
	_check(String(route.last_result().get("result", {}).get("ending", route.director().snapshot().get("status", ""))) in ["BLOOM", "GOLDEN", "complete"], "S11 produces a safe Bloom-family outcome")
	_check(bool(route.advance_scene().get("accepted", false)) and route.current_scene_id() == "EX-CH01-S12", "S11 advances after outcome review")
	for target_id in ["verify_chamber", "open_shutter", "tag_bloom", "inspect_tara", "complete_debrief"]:
		_check(bool(route.perform(target_id).get("accepted", false)), "S12 bloom/debrief action committed: " + target_id)
	var final_advance := route.advance_scene()
	_check(bool(final_advance.get("accepted", false)) and bool(final_advance.get("chapter_complete", false)), "S12 closes the Chapter 1 physical route")
	_check(route.completed_scene_ids().size() == 12 and bool(route.chapter_ready().get("ready", false)), "all twelve canonical scenes and CH02 readiness require physical gates")
	var saved_route := route.snapshot()
	_check(saved_route.get("world", {}).get("current_scene_id", "") == "EX-CH01-S12" and saved_route.get("completed_scene_ids", []).size() == 12, "route snapshot contains room and mission primitive state")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)
