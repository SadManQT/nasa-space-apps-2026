## Godot --headless --path game --script res://tools/test_ch06_missions.gd
## Windowed evidence: Godot --path game --windowed --resolution 1280x720 --script res://tools/test_ch06_missions.gd -- --evidence
## Verifies M3-6M: Chapter 6 missions EX-M0601..EX-M0604 (EX-CH06-S01..S12) physical play at props,
## companion placement, canon dialogue, checkpoints/retry, story continuity bridges,
## and hazard/network/RPG integration (M3-62, M3-64, M3-65).
extends SceneTree

const PuzzleData = preload("res://scripts/puzzles/puzzle_data.gd")

const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const RouteScript = preload("res://scripts/missions/extended_campaign_route.gd")
const GateCatalog = preload("res://scripts/missions/extended_gate_catalog.gd")
const RoomContract = preload("res://scripts/world/room_contract.gd")
const RosterScript = preload("res://scripts/companions/companion_roster.gd")
const Witness4 = preload("res://tools/support/chapter4_witness.gd")
const Witness = preload("res://tools/support/chapter6_witness.gd")
const LunarNetworkScript = preload("res://scripts/network/lunar_network.gd")
const LunarHazardsScript = preload("res://scripts/hazards/lunar_hazards.gd")
const CadetProgressionScript = preload("res://scripts/progression/cadet_progression.gd")
const CampaignScene: PackedScene = preload("res://scenes/campaign/chapter1_campaign.tscn")

var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_mission_structure_and_continuity()
	_test_hazard_network_rpg_integration()
	await _test_physical_play_and_retry()
	print("CH06 MISSIONS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_mission_structure_and_continuity() -> void:
	var ch6_scenes := [
		"EX-CH06-S01", "EX-CH06-S02", "EX-CH06-S03", "EX-CH06-S04",
		"EX-CH06-S05", "EX-CH06-S06", "EX-CH06-S07", "EX-CH06-S08",
		"EX-CH06-S09", "EX-CH06-S10", "EX-CH06-S11", "EX-CH06-S12"
	]
	var expected_rooms := {
		"EX-CH06-S01": "LOC-02", "EX-CH06-S02": "LOC-02", "EX-CH06-S03": "LOC-02",
		"EX-CH06-S04": "LOC-02", "EX-CH06-S05": "LOC-02", "EX-CH06-S06": "LOC-01",
		"EX-CH06-S07": "LOC-01", "EX-CH06-S08": "LOC-01", "EX-CH06-S09": "LOC-01",
		"EX-CH06-S10": "LOC-02", "EX-CH06-S11": "LOC-02", "EX-CH06-S12": "LOC-03"
	}
	for scene_id in ch6_scenes:
		var room_id := RoomContract.room_for_scene(scene_id)
		_check(room_id == expected_rooms[scene_id], scene_id + " maps to physical location " + expected_rooms[scene_id])
		var roster := RosterScript.scene_roster(scene_id)
		var playable := RosterScript.playable_actor(scene_id)
		_check(roster.has(playable) and roster[playable].physical_location_id == room_id and bool(roster[playable].present), scene_id + " places playable actor " + playable + " in " + room_id)
		var targets := GateCatalog.targets_for_scene(scene_id)
		_check(targets.size() >= 1, scene_id + " declares physical targets (" + str(targets.size()) + ")")

func _test_hazard_network_rpg_integration() -> void:
	var hazards := LunarHazardsScript.new("Cadet")
	var floods: Dictionary = hazards.evaluate_darkness_budget(5, true, true, true)
	_check(not bool(floods.get("accepted", true)) and bool(floods.get("warning_issued_first", false)), "decorative floods breach the reserve and the darkness warning comes first")
	var plan: Dictionary = hazards.evaluate_darkness_budget(5, true, true, false)
	_check(bool(plan.get("accepted", false)) and int(plan.get("allocation_spent", 0)) == 7 and int(plan.get("reserve_remaining", 0)) == 7, "five essentials + pump + camera spend 7 and keep the 7-unit reserve")

	var net := LunarNetworkScript.new(1)
	var guide: Dictionary = net.place_from_payload("GUIDE-01", "path_light", "LOC-02", [3.5, 1.5], 6, "Protected guide light")
	_check(bool(guide.get("accepted", false)) and net.count_by_kind("path_light") == 1, "protected guide light persists in the network")

	var pair5: Dictionary = CadetProgressionScript.UPGRADE_PAIRS.get(5, {})
	_check(String(pair5.get("A", {}).get("id", "")) == "dust_shield" and String(pair5.get("B", {}).get("id", "")) == "whipple_bumper", "Chapter 5->6 upgrade pair offers dust_shield vs whipple_bumper")

func _test_physical_play_and_retry() -> void:
	var storage = preload("res://tools/support/isolated_storage.gd").new()
	if not storage.setup("M3-6M-test"):
		_check(false, "isolated storage setup")
		return
	storage.prepare_rendering_cache()
	CampaignCutscenePlayer.autoplay = false
	var entry := _chapter6_entry_snapshot()
	_check(not entry.is_empty(), "Chapter 6 entry snapshot constructed from authoritative route")
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
	_check(campaign._startup_error.is_empty() and campaign.route.current_scene_id() == "EX-CH06-S01", "campaign boots at EX-CH06-S01 in LOC-02")

	var want_evidence := OS.get_cmdline_user_args().has("--evidence")
	if want_evidence:
		root.size = Vector2i(1280, 720)
		root.content_scale_size = Vector2i(1280, 720)

	var ch6_scenes := [
		"EX-CH06-S01", "EX-CH06-S02", "EX-CH06-S03", "EX-CH06-S04",
		"EX-CH06-S05", "EX-CH06-S06", "EX-CH06-S07", "EX-CH06-S08",
		"EX-CH06-S09", "EX-CH06-S10", "EX-CH06-S11", "EX-CH06-S12"
	]
	for scene_id in ch6_scenes:
		_check(campaign.route.current_scene_id() == scene_id, "physical campaign at " + scene_id)
		var targets := GateCatalog.targets_for_scene(scene_id)
		for idx in targets.size():
			var target_id := String(targets[idx].target_id)
			await _stand_at(campaign, target_id)
			var res := campaign.perform_target(target_id, Witness.payload(target_id, campaign.director.snapshot()))
			_check(bool(res.get("accepted", false)), scene_id + " physical target " + target_id + " commits" + ("" if bool(res.get("accepted", false)) else " -- " + String(res.get("reason", ""))))
			if idx == 0 and scene_id in ["EX-CH06-S01", "EX-CH06-S04", "EX-CH06-S07", "EX-CH06-S10"]:
				var retried := campaign.retry_checkpoint()
				_check(bool(retried.get("accepted", false)), scene_id + " retry_checkpoint restores pre-operation state")
				await campaign.wait_loading()
				await _stand_at(campaign, target_id)
				var redo := campaign.perform_target(target_id, Witness.payload(target_id, campaign.director.snapshot()))
				_check(bool(redo.get("accepted", false)), scene_id + " target " + target_id + " commits cleanly after retry")
		if want_evidence and scene_id in ["EX-CH06-S01", "EX-CH06-S04", "EX-CH06-S07", "EX-CH06-S10"]:
			await _save_evidence("M3-6M_" + scene_id + ".png")
		_check(bool(campaign.route.gate_status().get("ready", false)), scene_id + " gate ready after physical operations")
		if scene_id == "EX-CH06-S12":
			# Read the reserve at the end of Chapter 6, before Chapter 7's entry profile applies.
			var end_state := campaign.director.snapshot()
			_check(is_equal_approx(float(end_state.resources.E), 7.0), "Chapter 6 final battery reserve matches 08 witness (E = 7; got " + str(end_state.resources.E) + ")")
		var moved := campaign.advance_scene()
		if scene_id == "EX-CH06-S12":
			_check(bool(moved.get("chapter_complete", false)) or campaign.route.current_scene_id().begins_with("EX-CH07"), "EX-CH06-S12 completes Chapter 6")
		else:
			_check(bool(moved.get("accepted", false)), scene_id + " advances to next scene")
			await campaign.wait_loading()
			campaign.hud.refresh_scene()
			await process_frame


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
	if campaign._has_line_of_sight(target):
		return
	# Walk around the prop like a player would until it is in clear view.
	for radius in [1.0, 1.4, 1.8, 2.2]:
		for step in 8:
			var angle := TAU * float(step) / 8.0
			campaign._player.global_position = Vector3(target.global_position.x + cos(angle) * radius, 0.0, target.global_position.z + sin(angle) * radius)
			campaign._player.velocity = Vector3.ZERO
			await physics_frame
			await physics_frame
			if campaign._has_line_of_sight(target):
				return

func _save_evidence(filename: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../production/qa/evidence/" + filename)
	root.get_texture().get_image().save_png(path)

func _chapter6_entry_snapshot() -> Dictionary:
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
		if scene_id.begins_with("EX-CH06"):
			break
		for target in GateCatalog.targets_for_scene(scene_id):
			var payload: Dictionary = target.get("payload_defaults", {}).duplicate(true) if target.get("payload_defaults", {}) is Dictionary else {}
			if payload.is_empty():
				payload = PuzzleData.gate_payload(String(target.get("puzzle_action", "")))
			payload = Witness4.payload(String(target.target_id), director.snapshot(), payload)
			var performed: Dictionary = route.perform(target.target_id, payload)
			if not bool(performed.get("accepted", false)):
				push_error("Chapter 6 fixture rejected %s / %s: %s" % [scene_id, String(target.target_id), String(performed.get("reason", ""))])
				return {}
		var moved: Dictionary = route.advance_scene()
		if bool(moved.get("chapter_complete", false)):
			route.start_at("EX-CH%02d-S01" % (int(scene_id.substr(5, 2)) + 1))
	var state: Dictionary = director.snapshot()
	state["route_runtime"] = route.snapshot()
	state["route_runtime"]["chapter"] = 6
	return JSON.parse_string(JSON.stringify(state))

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)
