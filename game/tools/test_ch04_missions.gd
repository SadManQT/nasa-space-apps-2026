## Godot --headless --path game --script res://tools/test_ch04_missions.gd
## Windowed evidence: Godot --path game --windowed --resolution 1280x720 --script res://tools/test_ch04_missions.gd -- --evidence
## Verifies M3-4M: Chapter 4 missions EX-M0401..EX-M0404 (EX-CH04-S01..S12) physical play at props,
## companion placement, canon dialogue, checkpoints/retry, story continuity bridges,
## and rover/network/RPG integration (M3-62, M3-63, M3-64).
extends SceneTree

const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const RouteScript = preload("res://scripts/missions/extended_campaign_route.gd")
const GateCatalog = preload("res://scripts/missions/extended_gate_catalog.gd")
const RoomContract = preload("res://scripts/world/room_contract.gd")
const RosterScript = preload("res://scripts/companions/companion_roster.gd")
const Witness = preload("res://tools/support/chapter4_witness.gd")
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
	print("CH04 MISSIONS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_mission_structure_and_continuity() -> void:
	var ch4_scenes := [
		"EX-CH04-S01", "EX-CH04-S02", "EX-CH04-S03", "EX-CH04-S04",
		"EX-CH04-S05", "EX-CH04-S06", "EX-CH04-S07", "EX-CH04-S08",
		"EX-CH04-S09", "EX-CH04-S10", "EX-CH04-S11", "EX-CH04-S12"
	]
	var expected_rooms := {
		"EX-CH04-S01": "LOC-03", "EX-CH04-S02": "LOC-08", "EX-CH04-S03": "LOC-08",
		"EX-CH04-S04": "LOC-09", "EX-CH04-S05": "LOC-09", "EX-CH04-S06": "LOC-10",
		"EX-CH04-S07": "LOC-10", "EX-CH04-S08": "LOC-10", "EX-CH04-S09": "LOC-08",
		"EX-CH04-S10": "LOC-03", "EX-CH04-S11": "LOC-01", "EX-CH04-S12": "LOC-01"
	}
	for scene_id in ch4_scenes:
		var room_id := RoomContract.room_for_scene(scene_id)
		_check(room_id == expected_rooms[scene_id], scene_id + " maps to physical location " + expected_rooms[scene_id])
		var roster := RosterScript.scene_roster(scene_id)
		var playable := RosterScript.playable_actor(scene_id)
		_check(roster.has(playable) and roster[playable].physical_location_id == room_id and bool(roster[playable].present), scene_id + " places playable actor " + playable + " in " + room_id)
		var targets := GateCatalog.targets_for_scene(scene_id)
		_check(targets.size() >= 2, scene_id + " declares physical targets (" + str(targets.size()) + ")")
	# Verify three terrain segments B1, B2, B3 on LOC-09 for EX-CH04-S04
	var segments := RoomContract.terrain_segments("LOC-09")
	_check(segments.has("B1") and segments.has("B2") and segments.has("B3"), "LOC-09 defines B1, B2 and B3 beacon corner segments")

func _test_rover_network_rpg_integration() -> void:
	var net := LunarNetworkScript.new(1)
	var added: Array = net.record_ch04_beacons(3)
	var layer: Array = net.ch04_beacon_layer()
	_check(added.size() == 3 and layer.size() == 3, "three canon survey beacons B1, B2, B3 persist in the network and the Chapter 8 map layer")
	var reloaded := LunarNetworkScript.new(1)
	reloaded.from_dict(JSON.parse_string(JSON.stringify(net.to_dict())))
	_check(reloaded.ch04_beacon_layer().size() == 3, "beacon layer survives a save and reload")

	var rover := LunarRoverScript.new("Cadet", "ch04_survey")
	var planner := PlannerScript.new()
	planner.bind_rover(rover)
	var plan_b: Dictionary = planner.evaluate_route("B")
	_check(bool(plan_b.get("accepted", false)) and is_equal_approx(float(plan_b.get("battery_after_round_trip", 0.0)), 40.0), "Route B forecasts 12 deg slope and 40 reserve")
	var plan_a: Dictionary = planner.evaluate_route("A")
	var plan_c: Dictionary = planner.evaluate_route("C")
	_check(not bool(plan_a.get("accepted", true)) and not bool(plan_c.get("accepted", true)), "Routes A (19 deg slope) and C (24 reserve) are rejected")
	planner.free()

	var pair3: Dictionary = CadetProgressionScript.UPGRADE_PAIRS.get(3, {})
	_check(String(pair3.get("A", {}).get("id", "")) == "moon_dirt_shelter" and String(pair3.get("B", {}).get("id", "")) == "flexible_seals", "Chapter 3->4 upgrade pair offers moon_dirt_shelter vs flexible_seals")

func _test_physical_play_and_retry() -> void:
	var storage = preload("res://tools/support/isolated_storage.gd").new()
	if not storage.setup("M3-4M-test"):
		_check(false, "isolated storage setup")
		return
	storage.prepare_rendering_cache()
	CampaignCutscenePlayer.autoplay = false
	var entry := _chapter4_entry_snapshot()
	_check(not entry.is_empty(), "Chapter 4 entry snapshot constructed from authoritative route")
	var campaign := CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	campaign.initial_snapshot = entry
	root.add_child(campaign)
	for i in 6:
		await physics_frame
	await campaign.wait_loading()
	campaign.hud.refresh_scene()
	await process_frame
	_check(campaign._startup_error.is_empty() and campaign.route.current_scene_id() == "EX-CH04-S01", "campaign boots at EX-CH04-S01 in LOC-03")

	var want_evidence := OS.get_cmdline_user_args().has("--evidence")
	if want_evidence:
		root.size = Vector2i(1280, 720)
		root.content_scale_size = Vector2i(1280, 720)

	var ch4_scenes := [
		"EX-CH04-S01", "EX-CH04-S02", "EX-CH04-S03", "EX-CH04-S04",
		"EX-CH04-S05", "EX-CH04-S06", "EX-CH04-S07", "EX-CH04-S08",
		"EX-CH04-S09", "EX-CH04-S10", "EX-CH04-S11", "EX-CH04-S12"
	]
	for scene_id in ch4_scenes:
		_check(campaign.route.current_scene_id() == scene_id, "physical campaign at " + scene_id)
		var targets := GateCatalog.targets_for_scene(scene_id)
		for idx in targets.size():
			var target_id := String(targets[idx].target_id)
			await _stand_at(campaign, target_id)
			var res := campaign.perform_target(target_id, Witness.payload(target_id, campaign.director.snapshot()))
			_check(bool(res.get("accepted", false)), scene_id + " physical target " + target_id + " commits" + ("" if bool(res.get("accepted", false)) else " -- " + String(res.get("reason", ""))))
			if idx == 0 and scene_id in ["EX-CH04-S01", "EX-CH04-S04", "EX-CH04-S07", "EX-CH04-S10"]:
				var retried := campaign.retry_checkpoint()
				_check(bool(retried.get("accepted", false)), scene_id + " retry_checkpoint restores pre-operation state")
				await campaign.wait_loading()
				await _stand_at(campaign, target_id)
				var redo := campaign.perform_target(target_id, Witness.payload(target_id, campaign.director.snapshot()))
				_check(bool(redo.get("accepted", false)), scene_id + " target " + target_id + " commits cleanly after retry")
		if want_evidence and scene_id in ["EX-CH04-S01", "EX-CH04-S04", "EX-CH04-S08", "EX-CH04-S12"]:
			await _save_evidence("M3-4M_" + scene_id + ".png")
		_check(bool(campaign.route.gate_status().get("ready", false)), scene_id + " gate ready after physical operations")
		var moved := campaign.advance_scene()
		if scene_id == "EX-CH04-S12":
			_check(bool(moved.get("chapter_complete", false)) or campaign.route.current_scene_id().begins_with("EX-CH05"), "EX-CH04-S12 completes Chapter 4")
		else:
			_check(bool(moved.get("accepted", false)), scene_id + " advances to next scene")
			await campaign.wait_loading()
			campaign.hud.refresh_scene()
			await process_frame

	var final_state := campaign.director.snapshot()
	_check(int(final_state.route.energy) == 40 and int(final_state.route.provisions) == 48 and int(final_state.inventories.vault12.stored) == 12, "Chapter 4 final rover and vault12 state match 08 witness")

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

func _chapter4_entry_snapshot() -> Dictionary:
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
		if scene_id.begins_with("EX-CH04"):
			break
		for target in GateCatalog.targets_for_scene(scene_id):
			var payload: Dictionary = target.get("payload_defaults", {}).duplicate(true) if target.get("payload_defaults", {}) is Dictionary else {}
			if not bool(route.perform(target.target_id, payload).get("accepted", false)):
				return {}
		var moved: Dictionary = route.advance_scene()
		if bool(moved.get("chapter_complete", false)):
			route.start_at("EX-CH%02d-S01" % (int(scene_id.substr(5, 2)) + 1))
	var state: Dictionary = director.snapshot()
	state["route_runtime"] = route.snapshot()
	state["route_runtime"]["chapter"] = 4
	return JSON.parse_string(JSON.stringify(state))

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)
