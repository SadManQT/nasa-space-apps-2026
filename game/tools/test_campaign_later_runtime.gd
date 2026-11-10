## Godot --headless --path game --script res://tools/test_campaign_later_runtime.gd
## Verifies the real production controller crosses CH02 -> CH03 and exposes a physical P-05 target.
extends SceneTree

const CampaignScene: PackedScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const Chapter2RouteScript = preload("res://scripts/missions/chapter2_route.gd")
const SaveScript = preload("res://scripts/save/save_service.gd")
const RoomContract = preload("res://scripts/world/room_contract.gd")

var storage = preload("res://tools/support/isolated_storage.gd").new()

var checks := 0
var failures := 0
var _campaign: Chapter1Campaign
var _original_user_dir := ""

func _init() -> void:
	CampaignCutscenePlayer.autoplay = false
	if not storage.setup("test_campaign_later_runtime"):
		push_error("Unable to isolate test storage.")
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	var director := DirectorScript.new()
	director.new_campaign(CampaignContentFull.EXPECTED_CONTENT_REVISION)
	var route := Chapter2RouteScript.new(director)
	route.start_at("EX-CH02-S12")
	var route_snapshot: Dictionary = route.snapshot()
	route_snapshot["completed_scene_ids"] = ["EX-CH02-S12"]
	var state: Dictionary = director.snapshot()
	state["chapter1_ready"] = true
	state["chapter_id"] = "CH02"
	state["mission_id"] = "EX-M0204"
	state["scene_id"] = "EX-CH02-S12"
	state["completed_scene_ids"] = ["EX-CH02-S12"]
	state["scenario_datetime"] = "2046-05-06 18:00 UTC"
	state["route_runtime"] = route_snapshot
	_campaign = CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(_campaign)
	_campaign.initial_snapshot = state
	root.add_child(_campaign)
	await process_frame
	_check(_campaign.route != null and _campaign.route.current_scene_id() == "EX-CH02-S12", "production runtime restores a Chapter 2 checkpoint")
	_test_panels()
	var transition: Dictionary = _campaign.advance_scene()
	_check(bool(transition.get("upgrade_pending", false)) and _campaign.available_upgrade_chapter() == 2, "Chapter 2 completion offers its earned upgrade before departure")
	var chosen: Dictionary = _campaign.choose_upgrade(2, "A")
	_check(bool(chosen.get("persisted", false)), "Chapter 2 upgrade is saved before departure")
	_check(bool(chosen.get("accepted", false)) and _campaign.route.current_scene_id() == "EX-CH03-S01", "production controller crosses into Chapter 3 after the player chooses an upgrade")
	_check(not is_instance_valid(_campaign.hud._family_panel) and not _campaign.query().paused, "runtime closes the upgrade family before entering Chapter 3")
	_check(String(_campaign.director.snapshot().get("chapter_id", "")) == "CH03" and _campaign.route.current_room_id() == "LOC-02", "Chapter 3 projection and service-room viewpoint are authoritative")
	var target: Node3D = _campaign.physical_target("p05_equip_gauge")
	_check(target != null, "Chapter 3 exposes a physical P-05 gauge target")
	if target != null:
		_campaign._player.global_position = target.global_position + Vector3(0.0, -target.global_position.y, 1.0)
		_campaign._player.velocity = Vector3.ZERO
		await physics_frame
		var operation: Dictionary = _campaign.perform_target("p05_equip_gauge")
		_check(bool(operation.get("accepted", false)) and bool(_campaign.route.current_flags().get("p05_equip_gauge_done", false)), "P-05 operation commits through the production physical interaction")
	else:
		_check(false, "P-05 operation commits through the production physical interaction")
	for chapter in range(3, 9):
		if chapter > 3:
			_check(bool(_campaign._start_extended("EX-CH%02d-S01" % chapter).get("accepted", false)), "later panel fixture enters chapter %d" % chapter)
		_test_panels()
	await _test_later_rooms_and_choices()
	var saved: Dictionary = _campaign.save_campaign()
	if not saved.get("accepted", false):
		print("LATER SAVE DETAIL ", saved.get("reason", ""), " ", _invalid_path(_campaign._save_snapshot()))
	_check(bool(saved.get("accepted", false)), "later-chapter runtime saves a primitive route checkpoint")
	_campaign.free()
	_check(SaveScript.new().clear(storage.path), "later runtime fixture cleans its isolated save")
	storage.cleanup()
	print("LATER CAMPAIGN RUNTIME RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)

func _test_panels() -> void:
	var chapter: String = _campaign.director.query().chapter_id
	_campaign.loading = true
	var shortcut := InputEventKey.new()
	shortcut.physical_keycode = KEY_ESCAPE
	shortcut.pressed = true
	_campaign.hud._unhandled_key_input(shortcut)
	_check(_campaign.hud.panels.active_panel().is_empty() and not _campaign.query().paused, "loading ignores menu shortcuts until HUD setup is complete")
	var voice_before: String = _campaign.audio.voice_line_id
	_campaign.present_dialogue({"id": "loading-dialogue-fixture", "speaker": "Kai", "text": "Wait for the loading card."})
	_check(_campaign.audio.voice_line_id == voice_before, "loading never starts the next dialogue before its HUD and scene are ready")
	_campaign.hud.panels.close_panel()
	_campaign.loading = false
	for panel_id in ["journal_discovery", "pause", "settings_accessibility"]:
		_campaign.hud.panels.open_panel(panel_id, {})
		_check(_campaign.director.query().paused and _campaign._player.process_mode == Node.PROCESS_MODE_DISABLED, "B04 " + chapter + " pauses for " + panel_id)
		_campaign.hud.panels.close_panel()
		_check(not _campaign.director.query().paused and _campaign._player.process_mode == Node.PROCESS_MODE_INHERIT, "B04 " + chapter + " resumes after " + panel_id)
	if not _campaign.is_chapter_complete():
		_check(not _campaign.hud._retry.disabled, "B05 later chapter HUD exposes its persisted retry checkpoint")

func _test_later_rooms_and_choices() -> void:
	# M3-103: LOC-05 airlock in Chapter 2
	var ch2_route := Chapter2RouteScript.new(_campaign.director)
	ch2_route.start_at("EX-CH02-S03")
	_campaign.route = ch2_route
	_campaign._sync_route_projection()
	_campaign._refresh_world()
	await physics_frame
	_check(_campaign._room != null and _campaign._room.room_id == "LOC-05" and _campaign._room.airlock() != null, "M3-103 campaign loads airlock.tscn for EX-CH02-S03")
	_check(_campaign.physical_target("check_space_weather") != null and String(_campaign.physical_target("check_space_weather").get_meta("target_id", "")) == "transfer_space_weather", "M3-103 binds EX-CH02-S03 targets to LOC-05 stations")

	# M3-107: LOC-07 annex and EX-CH03-S11-DEDICATION choice
	_check(bool(_campaign._start_extended("EX-CH03-S06").get("accepted", false)) and _campaign._room.room_id == "LOC-07", "M3-107 campaign loads annex.tscn for EX-CH03-S06")
	_check(bool(_campaign._start_extended("EX-CH03-S11").get("accepted", false)) and _campaign._room.room_id == "LOC-03", "M3-107 enters EX-CH03-S11 in LOC-03")
	var bad_dedication := _campaign.handle_ui_command({"command_id": "choice:dedication:bad", "issuer": "test", "owning_mission_id": "EX-M0304", "owning_scene_id": "EX-CH03-S11", "expected_state_revision": int(_campaign.director.query().get("state_revision", 0)), "target_id": "EX-CH03-S11-DEDICATION", "verb": "record_choice", "payload": {"choice_id": "EX-CH03-S11-DEDICATION", "option_id": "UNKNOWN"}})
	_check(not bool(bad_dedication.get("accepted", false)), "M3-107 rejects unknown dedication option")
	var good_dedication := _campaign.handle_ui_command({"command_id": "choice:dedication:opt02", "issuer": "test", "owning_mission_id": "EX-M0304", "owning_scene_id": "EX-CH03-S11", "expected_state_revision": int(_campaign.director.query().get("state_revision", 0)), "target_id": "EX-CH03-S11-DEDICATION", "verb": "record_choice", "payload": {"choice_id": "EX-CH03-S11-DEDICATION", "option_id": "EX-CH03-S11-DEDICATION-OPT02"}})
	_check(bool(good_dedication.get("accepted", false)) and _campaign._room.stage().get("layers", []).has("ch03_d6_opt02"), "M3-107 records dedication choice and updates LOC-03 sign")

	# M3-109: LOC-08 garage and dock cycle
	_check(bool(_campaign._start_extended("EX-CH04-S09").get("accepted", false)) and _campaign._room.room_id == "LOC-08" and _campaign._room.garage() != null, "M3-109 campaign loads garage.tscn for EX-CH04-S09")
	var bay := _campaign._room.garage()
	_check(bay.dock_state() == "SEALED" and not bool(_campaign.route.world().boundary_state("garage_dock_hatch").get("airlock_ready", false)), "M3-109 EX-CH04-S09 starts with rover dock SEALED")
	var dock_focus: Node3D = _campaign._focus_node("garage_dock")
	_campaign._player.global_position = dock_focus.global_position + Vector3(0.0, -dock_focus.global_position.y, -1.0)
	_campaign._player.velocity = Vector3.ZERO
	await physics_frame
	var dock_cycle := _campaign._interact_garage_dock()
	_check(bool(dock_cycle.get("dock_cycling", false)) and bay.dock_state() == "EQUALISING" and not String(dock_cycle.get("time_card", "")).is_empty(), "M3-109 garage dock interaction starts EQUALISING with time card")
	bay.advance(10.0)
	_check(bay.dock_state() == "SAFE TO OPEN" and bool(_campaign.route.world().boundary_state("garage_dock_hatch").get("airlock_ready", false)), "M3-109 garage dock cycle finishes at SAFE TO OPEN")

	# M3-110: LOC-09 B1 -> B2 -> B3 segment progression in EX-CH04-S04
	_check(bool(_campaign._start_extended("EX-CH04-S04").get("accepted", false)) and _campaign._room.room_id == "LOC-09" and _campaign._room.terrain_segment == "B1", "M3-110 EX-CH04-S04 starts on segment B1")
	for step_id in ["p07_place_beacon_1", "p07_place_beacon_2"]:
		var step_node: Node3D = _campaign.physical_target(step_id)
		_check(step_node != null, "M3-110 target exists for " + step_id)
		if step_node != null:
			_campaign._player.global_position = step_node.global_position + Vector3(1.5, -step_node.global_position.y, 1.5)
			_campaign._player.velocity = Vector3.ZERO
			await physics_frame
			var step_res := _campaign.perform_target(step_id)
			var expected_seg := "B2" if step_id == "p07_place_beacon_1" else "B3"
			_check(bool(step_res.get("accepted", false)) and _campaign._room.terrain_segment == expected_seg and not String(step_res.get("cruise_time_card", "")).is_empty(), "M3-110 advances LOC-09 segment to " + expected_seg)

	# M4-07: LOC-11 / LOC-12 in LoadPreparation.ROOM_SCENES, aboard movement lock, and graded Malapert summit terrain
	_check(LoadPreparation.ROOM_SCENES.get("LOC-11", "") == "res://scenes/campaign/rooms/relay_road.tscn" and LoadPreparation.ROOM_SCENES.get("LOC-12", "") == "res://scenes/campaign/rooms/malapert_summit.tscn", "M4-07 LoadPreparation.ROOM_SCENES maps LOC-11 and LOC-12")
	_check(bool(_campaign._start_extended("EX-CH08-S03").get("accepted", false)) and _campaign._room.room_id == "LOC-11" and _campaign._player.has_meta("aboard"), "M4-07 EX-CH08-S03 places player aboard the pressurised rover in LOC-11")
	var start_pos := _campaign._player.global_position
	Input.action_press("move_forward")
	for i in 5:
		_campaign._player._physics_process(1.0 / 60.0)
	Input.action_release("move_forward")
	_check(_campaign._player.global_position.distance_to(start_pos) < 0.001, "M4-07 aboard player does not walk out of the rover cabin on WASD")
	_check(bool(_campaign._start_extended("EX-CH08-S08").get("accepted", false)) and _campaign._room.room_id == "LOC-12" and bool(RoomContract.terrain("LOC-12").get("omit_staging_floor", false)) and bool(RoomContract.terrain_lighting("LOC-12", "EX-CH08-S08").get("ready", false)) and bool(RoomContract.earth("LOC-12", "EX-CH08-S08").get("presented", false)), "M4-07 EX-CH08-S08 loads LOC-12 with ready graded Malapert summit terrain and dated Earth")


func _invalid_path(value, path: String = "$", depth: int = 0) -> String:
	if depth > 64:
		return path + " too deep"
	if value is Dictionary:
		for key in value:
			if not key is String:
				return path + "." + str(key) + " key type=" + str(typeof(key))
			var invalid := _invalid_path(value[key], path + "." + key, depth + 1)
			if not invalid.is_empty():
				return invalid
	elif value is Array:
		for index in value.size():
			var invalid := _invalid_path(value[index], path + "[" + str(index) + "]", depth + 1)
			if not invalid.is_empty():
				return invalid
	elif typeof(value) not in [TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING]:
		return path + " type=" + str(typeof(value))
	return ""
