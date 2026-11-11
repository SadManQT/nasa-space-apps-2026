## Godot --headless --path game --script res://tools/test_ch02_missions.gd
## Windowed evidence: Godot --path game --resolution 1280x720 --script res://tools/test_ch02_missions.gd -- --evidence
## M3-2M: Chapter 2 missions EX-M0201..EX-M0204 (EX-CH02-S01..S12) played at
## their props in the production campaign. Every target is used through real
## nearby USE; P-03 and P-04 steps go through their decision cards with the
## supported choice. Checks rooms, rosters, dated time cards, retry, the P-03
## resource witness and the boundary into Chapter 3.
extends SceneTree

const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const Chapter2Route = preload("res://scripts/missions/chapter2_route.gd")
const GateCatalog = preload("res://scripts/missions/chapter2_gate_catalog.gd")
const RoomContract = preload("res://scripts/world/room_contract.gd")
const RosterScript = preload("res://scripts/companions/companion_roster.gd")
const CampaignScene: PackedScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const EXPECTED_ROOMS := {
	"EX-CH02-S01": "LOC-03", "EX-CH02-S02": "LOC-03", "EX-CH02-S03": "LOC-05",
	"EX-CH02-S04": "LOC-05", "EX-CH02-S05": "LOC-05", "EX-CH02-S06": "LOC-03",
	"EX-CH02-S07": "LOC-01", "EX-CH02-S08": "LOC-02", "EX-CH02-S09": "LOC-02",
	"EX-CH02-S10": "LOC-02", "EX-CH02-S11": "LOC-01", "EX-CH02-S12": "LOC-01",
}
## First P-03/P-04 card of a mission: lock it in, retry the checkpoint, redo it.
const RETRY_AT := ["p03_scan_tara", "assign_date_token"]
const EVIDENCE_AT := ["EX-CH02-S01", "EX-CH02-S04", "EX-CH02-S09", "EX-CH02-S12"]

var checks := 0
var failures := 0
var storage = preload("res://tools/support/isolated_storage.gd").new()

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_structure()
	await _test_physical_play()
	print("CH02 MISSIONS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_structure() -> void:
	for mission_id in ["EX-M0201", "EX-M0202", "EX-M0203", "EX-M0204"]:
		_check(GateCatalog.scenes_for_mission(mission_id).size() == 3, mission_id + " has three scenes")
	for scene_id in GateCatalog.scene_ids():
		var room_id := RoomContract.room_for_scene(scene_id)
		_check(room_id == EXPECTED_ROOMS[scene_id] and String(GateCatalog.gate(scene_id).room_id) == room_id, scene_id + " plays in " + String(EXPECTED_ROOMS[scene_id]))
		var roster := RosterScript.scene_roster(scene_id)
		var playable := RosterScript.playable_actor(scene_id)
		_check(roster.has(playable) and String(roster[playable].physical_location_id) == room_id and bool(roster[playable].present), scene_id + " places playable " + playable + " in " + room_id)
		_check(GateCatalog.targets_for_scene(scene_id).size() >= 1 and not GateCatalog.required_physical(scene_id).is_empty(), scene_id + " has physical targets and a physical gate")
		_check(not GateCatalog.dialogue_ids(scene_id).is_empty(), scene_id + " carries canon dialogue lines")

func _test_physical_play() -> void:
	if not storage.setup("M3-2M-test"):
		_check(false, "isolated storage setup")
		return
	storage.prepare_rendering_cache()
	CampaignCutscenePlayer.autoplay = false
	var campaign := CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	campaign.initial_snapshot = _entry_snapshot()
	root.add_child(campaign)
	for i in 6:
		await physics_frame
	await campaign.wait_loading()
	campaign.hud.refresh_scene()
	await process_frame
	_check(campaign._startup_error.is_empty() and campaign.route.current_scene_id() == "EX-CH02-S01", "campaign boots at EX-CH02-S01")
	var evidence := OS.get_cmdline_user_args().has("--evidence") and DisplayServer.get_name() != "headless"
	if evidence:
		root.size = Vector2i(1280, 720)
	var last_date := ""
	for scene_id in GateCatalog.scene_ids():
		_check(campaign.route.current_scene_id() == scene_id and campaign.route.current_room_id() == EXPECTED_ROOMS[scene_id], "campaign at %s in %s" % [scene_id, EXPECTED_ROOMS[scene_id]])
		var date := String(campaign.director.snapshot().get("scenario_datetime", ""))
		_check(not date.is_empty() and date >= last_date, "%s time card %s does not run backwards" % [scene_id, date])
		last_date = date
		for target in GateCatalog.targets_for_scene(scene_id):
			var target_id := String(target.target_id)
			if not await _use(campaign, target):
				continue
			if RETRY_AT.has(target_id):
				var retried := campaign.retry_checkpoint()
				await campaign.wait_loading()
				_check(bool(retried.get("accepted", false)) and not bool(campaign.route.current_flags().get(String(target.physical_flag), false)), scene_id + " retry restores the state before " + target_id)
				_check(await _use(campaign, target), scene_id + " " + target_id + " commits again after retry")
		if scene_id == "EX-CH02-S05":
			var resources: Dictionary = campaign.director.snapshot().resources
			_check(is_equal_approx(float(resources.E), 16.0) and is_equal_approx(float(resources.A), 4.0) and is_equal_approx(float(resources.H), 9.0) and is_equal_approx(float(resources.C), 10.0) and is_equal_approx(float(resources.R), 14.4), "after three reciprocal runs the 08 witness holds: E16 A4 H9 C10 R14.4 (%s)" % str(resources))
		if evidence and EVIDENCE_AT.has(scene_id):
			_close_cards(campaign)
			for frame in 4:
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/M3-2M_%s.png" % scene_id))
		_check(bool(campaign.route.gate_status().get("ready", false)), scene_id + " gate ready after physical operations (missing %s)" % str(campaign.route.gate_status().get("missing", [])))
		_close_cards(campaign)
		await process_frame
		var moved := campaign.advance_scene()
		await campaign.wait_loading()
		if scene_id == "EX-CH02-S12":
			_check(bool(moved.get("chapter_complete", false)) and bool(campaign.route.chapter_ready().get("ready", false)), "EX-CH02-S12 completes Chapter 2 with every P-03 and P-04 conjunct")
		else:
			_check(bool(moved.get("accepted", false)), scene_id + " advances to the next scene (%s)" % JSON.stringify(moved).left(300))
		campaign.hud.refresh_scene()
		await process_frame
	var p03: Dictionary = campaign.route.snapshot().p03
	_check(int(p03.run_index) == 3 and (p03.care_dates as Array).size() == 7 and String(p03.prediction.get("expectation", "")) == "Both visible colours may appear", "P-03 records three runs, seven care dates and the chosen prediction")
	# Chapter boundary: the earned upgrade, then Chapter 3 begins at its first scene.
	_close_cards(campaign)
	var offered: Array = []
	while campaign.available_upgrade_chapter() > 0 and offered.size() < 3:
		offered.append(campaign.available_upgrade_chapter())
		campaign.choose_upgrade(offered[-1], "A")
	_check(offered.has(2) and campaign.available_upgrade_chapter() == 0, "the after-Chapter-2 upgrade is offered and chosen (%s)" % str(offered))
	# Choosing the earned upgrade at the chapter end starts the next chapter.
	await campaign.wait_loading()
	_check(campaign.route.current_scene_id() == "EX-CH03-S01" and campaign.route.current_room_id() == RoomContract.room_for_scene("EX-CH03-S01"), "Chapter 3 starts at EX-CH03-S01 in its room")
	campaign.free()
	await process_frame
	storage.cleanup()

## Uses one target through real nearby USE. P-03/P-04 targets open their card,
## where the supported selection is tried and locked in.
func _use(campaign: Chapter1Campaign, target: Dictionary) -> bool:
	var target_id := String(target.target_id)
	_close_cards(campaign)
	await _stand_at(campaign, target_id)
	var receipts := (campaign.director.snapshot().receipts as Dictionary).size()
	var used: Dictionary = campaign.interact_nearby()
	await process_frame
	if bool(used.get("chapter2_panel_requested", false)):
		var panel: Chapter2PuzzlePanel = campaign.hud.chapter2_panel
		_check(panel.is_open() and panel.target_id() == target_id, target_id + " opens its decision card")
		_choose_supported(panel, target_id)
		var tried: Dictionary = panel.try_it()
		_check(bool(tried.get("accepted", false)), target_id + " supported choice previews (%s)" % String(panel._notice))
		panel.request_commit()
		var confirmed := panel.confirm_commit()
		await process_frame
		used = {"accepted": bool(confirmed.get("accepted", false))}
	var committed := bool(used.get("accepted", false)) and bool(campaign.route.current_flags().get(String(target.physical_flag), false))
	_check(committed, target_id + " commits at its prop" + ("" if committed else " -- " + String(used.get("reason", ""))))
	_check((campaign.director.snapshot().receipts as Dictionary).size() == receipts + 1, target_id + " charges exactly one receipt")
	return committed

func _choose_supported(panel: Chapter2PuzzlePanel, target_id: String) -> void:
	var spec: Dictionary = panel._model().step(target_id)
	match String(spec.get("kind", "")):
		"choice":
			for option in spec.options:
				if bool(option.correct):
					panel.choose("option", String(option.id))
		"fields":
			for field in spec.fields:
				for option in spec.fields[field].options:
					if bool(option.correct):
						panel.choose(field, String(option.id))
						break
		"confirm":
			panel.choose("confirmed", true)

func _close_cards(campaign: Chapter1Campaign) -> void:
	if campaign.hud.chapter2_panel.is_open():
		campaign.hud.chapter2_panel.close()
	if not campaign.hud.panels.active_panel().is_empty():
		campaign.hud.panels.close_panel()

func _stand_at(campaign: Chapter1Campaign, target_id: String) -> void:
	var target: Node3D = campaign.physical_target(target_id)
	if target == null:
		_check(false, "physical target exists: " + target_id)
		return
	var approach: Array = target.get_meta("approach_m", [])
	campaign._player.global_position = campaign._room.to_global(Vector3(float(approach[0]), float(approach[1]), float(approach[2]))) if approach.size() == 3 else target.global_position + Vector3(0, 0, 1)
	campaign._player.velocity = Vector3.ZERO
	await physics_frame
	for frame in 10:
		campaign._player.follow_camera.camera.look_at(target.global_position)
		await physics_frame
		if String(campaign.nearby_target().get("target_id", "")) == target_id:
			return
	_check(false, "nearby target selected: %s (got %s)" % [target_id, String(campaign.nearby_target().get("target_id", ""))])

func _entry_snapshot() -> Dictionary:
	var director := DirectorScript.new()
	director.new_campaign(CampaignContentFull.EXPECTED_CONTENT_REVISION)
	var handoff: Dictionary = director.snapshot()
	handoff["chapter1_ready"] = true
	director.restore_snapshot(handoff)
	var route := Chapter2Route.new(director)
	route.apply_entry_profile()
	route.start_at("EX-CH02-S01")
	var state: Dictionary = director.snapshot()
	state["route_runtime"] = route.snapshot()
	state.route_runtime["chapter"] = 2
	return JSON.parse_string(JSON.stringify(state))

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("  FAIL: " + message)
