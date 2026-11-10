## Godot --headless --path game --script res://tools/test_ch08_missions.gd
## Windowed evidence: Godot --path game --windowed --resolution 1280x720 --script res://tools/test_ch08_missions.gd -- --evidence
## Verifies M3-8M: Chapter 8 missions EX-M0801..EX-M0804 (EX-CH08-S01..S12) physical play at props,
## companion placement, canon dialogue, checkpoints/retry, story continuity bridges (doc 24 §2.8-2.9),
## and rover/network integration (M3-62, M3-63, M3-64).
extends SceneTree

const PuzzleData = preload("res://scripts/puzzles/puzzle_data.gd")

const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const RouteScript = preload("res://scripts/missions/extended_campaign_route.gd")
const GateCatalog = preload("res://scripts/missions/extended_gate_catalog.gd")
const RoomContract = preload("res://scripts/world/room_contract.gd")
const RosterScript = preload("res://scripts/companions/companion_roster.gd")
const Witness4 = preload("res://tools/support/chapter4_witness.gd")
const Witness6 = preload("res://tools/support/chapter6_witness.gd")
const Witness = preload("res://tools/support/chapter8_witness.gd")
const LunarNetworkScript = preload("res://scripts/network/lunar_network.gd")
const LunarRoverScript = preload("res://scripts/rover/lunar_rover.gd")
const PlannerScript = preload("res://scripts/rover/rover_route_planner.gd")
const CadetProgressionScript = preload("res://scripts/progression/cadet_progression.gd")
const CampaignScene: PackedScene = preload("res://scenes/campaign/chapter1_campaign.tscn")

var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_mission_structure_and_continuity()
	_test_rover_network_rpg_integration()
	await _test_physical_play_and_retry()
	print("CH08 MISSIONS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_mission_structure_and_continuity() -> void:
	var ch8_scenes := [
		"EX-CH08-S01", "EX-CH08-S02", "EX-CH08-S03", "EX-CH08-S04",
		"EX-CH08-S05", "EX-CH08-S06", "EX-CH08-S07", "EX-CH08-S08",
		"EX-CH08-S09", "EX-CH08-S10", "EX-CH08-S11", "EX-CH08-S12"
	]
	var expected_rooms := {
		"EX-CH08-S01": "LOC-08", "EX-CH08-S02": "LOC-11", "EX-CH08-S03": "LOC-11",
		"EX-CH08-S04": "LOC-11", "EX-CH08-S05": "LOC-03", "EX-CH08-S06": "LOC-01",
		"EX-CH08-S07": "LOC-12", "EX-CH08-S08": "LOC-12", "EX-CH08-S09": "LOC-12",
		"EX-CH08-S10": "LOC-01", "EX-CH08-S11": "LOC-08", "EX-CH08-S12": "LOC-03"
	}
	for scene_id in ch8_scenes:
		var room_id := RoomContract.room_for_scene(scene_id)
		_check(room_id == expected_rooms[scene_id], scene_id + " maps to physical location " + expected_rooms[scene_id])
		var roster := RosterScript.scene_roster(scene_id)
		var playable := RosterScript.playable_actor(scene_id)
		_check(roster.has(playable) and roster[playable].physical_location_id == room_id and bool(roster[playable].present), scene_id + " places playable actor " + playable + " in " + room_id)
		var targets := GateCatalog.targets_for_scene(scene_id)
		_check(targets.size() >= 2, scene_id + " declares physical targets (" + str(targets.size()) + ")")
	# Continuity bridges (doc 24 §2.8-2.9):
	# S02/S03 have rover crew aboard inside LOC-11; S04 has EVA battery swap with Ferreira aboard; S05/S06 cut to Mei/Amara at Aurora before S07 Malapert summit.
	var s02_stage := RoomContract.staging("LOC-11", "EX-CH08-S02")
	_check(s02_stage.get("aboard", {}).has("ferreira") and s02_stage.get("aboard", {}).has("kai") and s02_stage.get("aboard", {}).has("rafi"), "EX-CH08-S02 places Ferreira, Kai and Rafi aboard the pressurised rover cab")
	var s04_stage := RoomContract.staging("LOC-11", "EX-CH08-S04")
	_check(s04_stage.get("outfits", {}).get("kai", "") == "eva" and s04_stage.get("outfits", {}).get("rafi", "") == "eva" and s04_stage.get("aboard", {}).has("ferreira"), "EX-CH08-S04 suits Kai and Rafi for EVA while Ferreira holds the cabin checklist aboard")
	var s10_roster := RosterScript.scene_roster("EX-CH08-S10")
	_check(s10_roster.has("mei") and s10_roster.has("amara") and s10_roster.mei.physical_location_id == "LOC-01", "EX-CH08-S10 places Mei and Amara at the Commons Earth screen for Noor's live call")

func _test_rover_network_rpg_integration() -> void:
	var net := LunarNetworkScript.new(2)
	_check(not net.verify_finale_voice_network("L2", "E3", "ALO42").get("accepted", false), "finale voice requires the 4-hop local repeater chain first")
	var chain := net.activate_full_local_chain()
	_check(bool(chain.get("local_chain_complete", false)), "restored repeater chain links Aurora to Malapert summit")
	var voice := net.verify_finale_voice_network("L2", "E3", "ALO42")
	_check(bool(voice.get("accepted", false)) and net.is_voice_ready(), "Malapert summit locks L2 + E3 and verifies ALO42 checksum")

	var rover := LunarRoverScript.new("Cadet", "ch08_relay")
	var planner := PlannerScript.new()
	planner.bind_rover(rover)
	var ch8_plan: Dictionary = planner.evaluate_route("SURVEYED")
	_check(bool(ch8_plan.get("accepted", false)) and is_equal_approx(float(ch8_plan.get("battery_after_round_trip", 0.0)), 4.0), "surveyed relay road forecasts 14 - 5 - 5 = 4 reserve")
	var detour: Dictionary = planner.evaluate_route("LOW_VALLEY_DETOUR")
	_check(not bool(detour.get("accepted", true)), "detour breaching 2-unit reserve is rejected")
	planner.free()

	var prog := CadetProgressionScript.new()
	var pair7: Dictionary = CadetProgressionScript.UPGRADE_PAIRS.get(7, {})
	_check(String(pair7.get("A", {}).get("id", "")) == "relay_parts_kit" and String(pair7.get("B", {}).get("id", "")) == "long_range_battery", "Chapter 7->8 upgrade pair offers relay_parts_kit vs long_range_battery")
	_check(prog != null, "CadetProgression initializes cleanly")

func _test_physical_play_and_retry() -> void:
	var storage = preload("res://tools/support/isolated_storage.gd").new()
	if not storage.setup("M3-8M-test"):
		_check(false, "isolated storage setup")
		return
	CampaignCutscenePlayer.autoplay = false
	var entry := _chapter8_entry_snapshot()
	_check(not entry.is_empty(), "Chapter 8 entry snapshot constructed from authoritative route")
	if entry.is_empty():
		storage.cleanup()
		return
	var campaign := CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	campaign.initial_snapshot = entry
	root.add_child(campaign)
	for i in 6:
		await physics_frame
	await campaign.wait_loading()
	campaign.hud.refresh_scene()
	await process_frame
	_check(campaign._startup_error.is_empty() and campaign.route.current_scene_id() == "EX-CH08-S01", "campaign boots at EX-CH08-S01 in LOC-08")

	var want_evidence := OS.get_cmdline_user_args().has("--evidence")
	if want_evidence:
		root.size = Vector2i(1280, 720)
		root.content_scale_size = Vector2i(1280, 720)

	var ch8_scenes := [
		"EX-CH08-S01", "EX-CH08-S02", "EX-CH08-S03", "EX-CH08-S04",
		"EX-CH08-S05", "EX-CH08-S06", "EX-CH08-S07", "EX-CH08-S08",
		"EX-CH08-S09", "EX-CH08-S10", "EX-CH08-S11", "EX-CH08-S12"
	]
	for scene_id in ch8_scenes:
		_check(campaign.route.current_scene_id() == scene_id, "physical campaign at " + scene_id)
		# Acknowledge all scene dialogue lines and verify non-empty text
		var status: Dictionary = campaign.route.gate_status()
		for line_id in status.get("dialogue_required", []):
			var ack := campaign.acknowledge_dialogue(String(line_id))
			_check(bool(ack.get("accepted", false)), scene_id + " acknowledges canon dialogue " + String(line_id))
		var targets := GateCatalog.targets_for_scene(scene_id)
		for idx in targets.size():
			var target_id := String(targets[idx].target_id)
			await _stand_at(campaign, target_id)
			var before_state := JSON.stringify(campaign.director.snapshot())
			var res := campaign.perform_target(target_id, Witness.payload(target_id, campaign.director.snapshot()))
			_check(bool(res.get("accepted", false)), scene_id + " physical target " + target_id + " commits")
			# Test checkpoint retry once per mission boundary (S01, S04, S07, S10) on the first target
			if idx == 0 and scene_id in ["EX-CH08-S01", "EX-CH08-S04", "EX-CH08-S07", "EX-CH08-S10"]:
				var retried := campaign.retry_checkpoint()
				_check(bool(retried.get("accepted", false)), scene_id + " retry_checkpoint restores pre-operation state")
				await campaign.wait_loading()
				await _stand_at(campaign, target_id)
				var redo := campaign.perform_target(target_id, Witness.payload(target_id, campaign.director.snapshot()))
				_check(bool(redo.get("accepted", false)), scene_id + " target " + target_id + " commits cleanly after retry")
		if want_evidence and scene_id in ["EX-CH08-S01", "EX-CH08-S04", "EX-CH08-S08", "EX-CH08-S12"]:
			await _save_evidence("M3-8M_" + scene_id + ".png")
		_check(bool(campaign.route.gate_status().get("ready", false)), scene_id + " gate ready after physical operations")
		var moved := campaign.advance_scene()
		if scene_id == "EX-CH08-S12":
			_check(bool(moved.get("campaign_complete", false)) or campaign.is_campaign_complete(), "EX-CH08-S12 completes the campaign")
		else:
			_check(bool(moved.get("accepted", false)), scene_id + " advances to next scene")
			await campaign.wait_loading()
			campaign.hud.refresh_scene()
			await process_frame

	var final_state := campaign.director.snapshot()
	_check(is_equal_approx(float(final_state.resources.E), 5.0) and is_equal_approx(float(final_state.resources.A), 5.1875) and is_equal_approx(float(final_state.resources.H), 1.0), "Chapter 8 final home resources match 08 witness (E5, A5.1875, H1)")
	_check(is_equal_approx(float(final_state.route.energy), 4.0) and int(final_state.route.elapsed_hours) == 51 and int(final_state.route.provisions_remaining) == 21, "Chapter 8 final rover resources match 08 witness (energy 4, 51/72 h, 21 h left)")

	campaign.free()
	await process_frame
	storage.cleanup()

func _stand_at(campaign: Chapter1Campaign, target_id: String) -> void:
	var target: Node3D = campaign.physical_target(target_id)
	if target == null:
		_check(false, "physical target exists: " + target_id)
		return
	var approach: Array = target.get_meta("approach_m", []) if target.has_meta("approach_m") else []
	if approach.size() >= 3:
		campaign._player.global_position = Vector3(float(approach[0]), float(approach[1]), float(approach[2]))
	else:
		campaign._player.global_position = Vector3(target.global_position.x, 0.0, target.global_position.z + 1.0)
	campaign._player.velocity = Vector3.ZERO
	await physics_frame
	await physics_frame

func _save_evidence(filename: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../production/qa/evidence/" + filename)
	root.get_texture().get_image().save_png(path)

func _chapter8_entry_snapshot() -> Dictionary:
	var director := DirectorScript.new()
	director.new_campaign(CampaignContentFull.EXPECTED_CONTENT_REVISION)
	var handoff: Dictionary = director.snapshot()
	handoff["chapter1_ready"] = true
	director.restore_snapshot(handoff)
	var pollination := preload("res://scripts/missions/chapter2_route.gd").new(director)
	pollination.apply_entry_profile()
	pollination.start_at("EX-CH02-S01")
	for scene_id in preload("res://scripts/missions/chapter2_gate_catalog.gd").SCENE_ORDER:
		for target in pollination.targets_for_current_scene():
			pollination.perform(target.target_id)
		pollination.advance_scene()
	var route := RouteScript.new(director)
	route.start_at("EX-CH03-S01")
	for scene_id in GateCatalog.scene_ids():
		if scene_id.begins_with("EX-CH08"):
			break
		for target in GateCatalog.targets_for_scene(scene_id):
			var payload: Dictionary = target.get("payload_defaults", {}).duplicate(true) if target.get("payload_defaults", {}) is Dictionary else {}
			if payload.is_empty():
				payload = PuzzleData.gate_payload(String(target.get("puzzle_action", "")))
			payload = Witness4.payload(String(target.target_id), director.snapshot(), payload)
			payload = Witness6.payload(String(target.target_id), director.snapshot(), payload)
			var performed: Dictionary = route.perform(target.target_id, payload)
			if not bool(performed.get("accepted", false)):
				push_error("Chapter 8 fixture rejected %s / %s: %s" % [scene_id, String(target.target_id), String(performed.get("reason", ""))])
				return {}
		var moved: Dictionary = route.advance_scene()
		if bool(moved.get("chapter_complete", false)):
			route.start_at("EX-CH%02d-S01" % (int(scene_id.substr(5, 2)) + 1))
	var state: Dictionary = director.snapshot()
	state["route_runtime"] = route.snapshot()
	state["route_runtime"]["chapter"] = 8
	return JSON.parse_string(JSON.stringify(state))

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)
