## Exercises all twelve scenes through the real campaign controller and HUD.
extends SceneTree

const CampaignScene: PackedScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const SaveScript = preload("res://scripts/save/save_service.gd")
const ACTIONS := [
	["commission_route", "commission_result", "charter_card"],
	["classify_information", "roll_call", "practice_fault"],
	["calibrate_probe", "span_probe", "recheck_probe", "inspect_packet", "compare_atmosphere"],
	["plant_alo", "plant_tara", "water_alo", "water_tara", "label_alo", "label_tara", "seal_alo", "seal_tara", "record_paired_conditions", "confirm_services"],
	["test_hand_light", "care_montage", "confirm_date_transition"],
	["arrange_timeline", "ack_schedule"],
	["role_cards", "p02_shift1", "p02_stage_shift2"],
	["shelter_drill", "verify_drill_baseline", "p02_shift2"],
	["combine_cards", "ack_earth_set", "p02_shifts3_4"],
	["confirm_four_sheltered", "p02_shift5_alarm"],
	["verify_exposure_order", "return_water", "p02_shifts6_7", "review_outcome"],
	["verify_chamber", "open_shutter", "tag_bloom", "inspect_tara", "complete_debrief"],
]

var storage = preload("res://tools/support/isolated_storage.gd").new()

var checks := 0
var failures := 0
var campaign: Chapter1Campaign

func _init() -> void:
	if not storage.setup("test_chapter1_campaign_flow"):
		push_error("Unable to isolate test storage.")
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	campaign = CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	root.add_child(campaign)
	await process_frame
	if campaign.route == null or campaign.hud == null:
		_check(false, "production campaign initializes its route and HUD")
		_finish()
		return
	_check(is_equal_approx(campaign._player.gravity, 1.62), "production player uses lunar gravity")
	for index in ACTIONS.size():
		var scene_id := "EX-CH01-S%02d" % (index + 1)
		_check(campaign.route.current_scene_id() == scene_id, "controller enters " + scene_id)
		await process_frame
		await process_frame
		campaign.hud._operations_scroll.ensure_control_visible(campaign.hud._advance)
		await process_frame
		_check(campaign.hud.get_viewport_rect().encloses(campaign.hud._advance.get_global_rect()), scene_id + " advance control stays onscreen")
		for target_id in ACTIONS[index]:
			var target := campaign.physical_target(String(target_id))
			if target == null:
				_check(false, scene_id + " has physical target " + String(target_id))
				_finish()
				return
			campaign._player.global_position = Vector3(target.global_position.x, 0.0, target.global_position.z + 1.0)
			campaign._player.velocity = Vector3.ZERO
			await physics_frame
			var result := campaign.perform_target(String(target_id))
			_check(bool(result.get("accepted", false)), scene_id + ": " + String(target_id) + " — " + String(result.get("reason", "")))
			if not bool(result.get("accepted", false)):
				_finish()
				return
		# Save and reload a planted garden, not just the first scene's empty state.
		if index == 3:
			var saved := campaign.save_campaign()
			_check(bool(saved.get("accepted", false)), "garden checkpoint saves")
			var loaded: Dictionary = SaveScript.new().load(storage.path)
			_check(bool(loaded.get("accepted", false)), "garden checkpoint loads")
			var expected: Dictionary = campaign.route.current_flags()
			campaign.free()
			campaign = CampaignScene.instantiate() as Chapter1Campaign
			storage.configure(campaign)
			campaign.initial_snapshot = loaded.get("snapshot", {})
			root.add_child(campaign)
			await process_frame
			_check(campaign.route.current_flags() == expected and bool(campaign.route.gate_status().get("ready", false)), "garden physical evidence survives runtime reload")
		if index == ACTIONS.size() - 1:
			_check(String(campaign.director.snapshot().get("scenario_datetime", "")).begins_with("2046-04-27"), "completed chapter reaches its canonical bloom date")
		var advance := campaign.advance_scene()
		_check(bool(advance.get("accepted", false)), scene_id + " advances through the production controller")
		if not bool(advance.get("accepted", false)):
			_finish()
			return
		await process_frame
	_check(campaign.route.current_scene_id() == "EX-CH02-S01" and campaign.route.completed_scene_ids().is_empty() and String(campaign.director.snapshot().get("chapter_id", "")) == "CH02", "final Chapter 1 scene transitions into Chapter 2")
	_check(campaign.hud._advance.disabled, "Chapter 2 advance stays disabled until its physical gate is ready")
	_check(String(campaign.director.snapshot().get("scenario_datetime", "")).begins_with("2046-04-30"), "B03 handoff advances from bloom to the dated P-03 entry")
	await _test_chapter2_handoff()
	_finish()

func _finish() -> void:
	if is_instance_valid(campaign):
		campaign.free()
	_check(SaveScript.new().clear(storage.path), "full-flow fixture cleans its isolated saves")
	storage.cleanup()
	print("CHAPTER 1 CAMPAIGN FLOW RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)

func _test_chapter2_handoff() -> void:
	var entry: Dictionary = campaign.director.snapshot().resources
	_check(entry.E == 14 and entry.A == 10 and entry.H == 6 and entry.C == 8 and is_equal_approx(entry.R, 18.0), "B03 real Bloom handoff installs E14/A10/H6/C8/R18")
	_check(not campaign.targets_for_current_scene().is_empty() and campaign.hud._targets.get_child_count() > 0, "B01 Chapter 2 exposes its operations through the production controller and HUD")
	for number in range(1, 13):
		var scene_id := "EX-CH02-S%02d" % number
		_check(campaign.route.current_scene_id() == scene_id, "production Chapter 2 reaches " + scene_id)
		for spec in campaign.targets_for_current_scene():
			var target := campaign.physical_target(String(spec.target_id))
			_check(target != null, "B01 physical target exists: " + String(spec.target_id))
			if target == null: return
			campaign._player.global_position = Vector3(target.global_position.x, 0, target.global_position.z + 1)
			campaign._player.velocity = Vector3.ZERO
			await physics_frame
			var action := campaign.perform_target(String(spec.target_id))
			_check(bool(action.get("accepted", false)), "production Chapter 2 commits " + String(spec.target_id))
			if not bool(action.get("accepted", false)): return
		if number == 5:
			var values: Dictionary = campaign.director.snapshot().resources
			_check([values.E, values.A, values.H, values.C] == [16, 4, 9, 10] and is_equal_approx(values.R, 14.4), "B03 sampled reciprocal operations end E16/A4/H9/C10/R14.4")
			var loaded: Dictionary = campaign.save_service.load(storage.path)
			_check(bool(loaded.get("accepted", false)), "B02 production Chapter 2 JSON save loads")
			var expected: Dictionary = campaign.route.snapshot().p03
			campaign.free()
			campaign = CampaignScene.instantiate() as Chapter1Campaign
			storage.configure(campaign)
			campaign.initial_snapshot = loaded.get("snapshot", {})
			root.add_child(campaign)
			await process_frame
			_check(campaign.route != null and campaign.route.snapshot().p03 == expected, "B02 production JSON restore preserves typed pollen actions and care dates")
		if number == 6:
			_check(is_equal_approx(campaign.director.snapshot().resources.R, 4.0), "B03 separate dated background ledger supplies 14 and consumes the unsampled share of 28")
		_check(bool(campaign.advance_scene().get("accepted", false)), "production Chapter 2 advances " + scene_id)
		await process_frame
	_check(campaign.route.current_scene_id() == "EX-CH03-S01", "real Chapter 2 gameplay hands off to Chapter 3")
