## Exercises all twelve scenes through the real campaign controller and HUD.
extends SceneTree
const PlantInput = preload("res://tools/support/p01_input_fixture.gd")

const CampaignScene: PackedScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const SaveScript = preload("res://scripts/save/save_service.gd")
const PlanFixture = preload("res://tools/support/p02_plan_fixture.gd")
const RoomContract = preload("res://scripts/world/room_contract.gd")
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
	await _test_decision_review_layout()
	campaign = CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	root.add_child(campaign)
	await process_frame
	PlanFixture.prepare(campaign.route)
	if campaign.route == null or campaign.hud == null:
		_check(false, "production campaign initializes its route and HUD")
		_finish()
		return
	_check(is_equal_approx(campaign._player.gravity, 1.62), "production player uses lunar gravity")
	for index in ACTIONS.size():
		var scene_id := "EX-CH01-S%02d" % (index + 1)
		_check(campaign.route.current_scene_id() == scene_id, "controller enters " + scene_id)
		var choice_id := scene_id + "-CHOICE"
		var option_id := scene_id + ("-OPT01" if index % 2 == 0 else "-OPT02")
		var before_story: Dictionary = campaign.director.snapshot().story_log.duplicate(true)
		var before_revision: int = campaign.director.snapshot().state_revision
		campaign.hud._decision_review.pressed.emit()
		var option := campaign.hud.panels.find_child(option_id, true, false) as Button
		var confirm := campaign.hud.panels.find_child("ConfirmChoice", true, false) as Button
		_check(option != null and confirm != null and confirm.disabled, scene_id + " decision review requires an explicit selection")
		if option == null or confirm == null:
			_finish()
			return
		option.pressed.emit()
		_check(campaign.director.snapshot().story_log == before_story and campaign.director.snapshot().state_revision == before_revision, scene_id + " UI preview adds no choice or receipt")
		_check(not confirm.disabled, scene_id + " preview enables confirmation")
		confirm.pressed.emit()
		var entry: Dictionary = campaign.director.snapshot().story_log.choices.get(choice_id, {})
		_check(entry.get("option_id") == option_id and entry.get("scene_id") == scene_id and entry.get("state_revision") == before_revision + 1, scene_id + " UI confirmation records exactly one choice with commit metadata")
		var choice_save: Dictionary = SaveScript.new().load(storage.path)
		_check(choice_save.get("snapshot", {}).get("story_log", {}).get("choices", {}).get(choice_id) == JSON.parse_string(JSON.stringify(entry)), scene_id + " confirmation autosaves the choice")
		await process_frame
		await process_frame
		await process_frame  # the Continue control sits in the goal card (doc 25 §2.2); no scroll list any more
		_check(campaign.hud.get_viewport_rect().encloses(campaign.hud._advance.get_global_rect()), scene_id + " advance control stays onscreen")
		for target_id in ACTIONS[index]:
			var target := campaign.physical_target(String(target_id))
			if target == null:
				_check(false, scene_id + " has physical target " + String(target_id))
				_finish()
				return
			# M1-108: the probe transfer gates the dry-zero commit.
			if String(target_id) == "calibrate_probe":
				PlantInput.complete_probe_transfer(campaign.route)
			campaign._player.global_position = Vector3(target.global_position.x, 0.0, target.global_position.z + 1.0)
			campaign._player.velocity = Vector3.ZERO
			await physics_frame
			var result := campaign.perform_target(String(target_id), PlantInput.payload(String(target_id)))
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
		if campaign.hud.panels.active_panel() == "chapter1_outcome":
			_check(campaign.hud.panels.find_child("ReplayChoice", true, false) != null, "physical debrief starts with the real decision replay")
			campaign.hud.panels.close_panel()
		var advance := campaign.advance_scene()
		_check(bool(advance.get("accepted", false)), scene_id + " advances through the production controller")
		if index == ACTIONS.size() - 1:
			_check(campaign.available_upgrade_chapter() == 1, "Chapter 1 offers its earned upgrade at the real boundary")
			# The chapter end shows What you learned first; closing it opens the upgrade choice.
			_check(is_instance_valid(campaign.hud._family_panel) and campaign.hud._family_panel.name == "AcademyManual", "Chapter 1 ends on its What you learned page")
			campaign.hud.close_family()
			for _frame in 3:
				await process_frame
			_check(is_instance_valid(campaign.hud._family_panel) and campaign.hud._family_panel.name != "AcademyManual", "closing that page opens the Chapter 1 upgrade choice")
			_check(bool(campaign.choose_upgrade(1, "A").get("accepted", false)), "Player chooses the earned Chapter 1 upgrade before the Chapter 2 handoff")
			_check(not is_instance_valid(campaign.hud._family_panel) and not campaign.query().paused, "Chapter 1 upgrade handoff closes its modal and resumes gameplay")
		var locked: Dictionary = campaign.director.commit({"command_id": "change-after-exit:" + scene_id, "issuer": "test", "owning_mission_id": campaign.director.query().mission_id, "owning_scene_id": scene_id, "expected_state_revision": campaign.director.query().state_revision, "target_id": choice_id, "verb": "record_choice", "payload": {"choice_id": choice_id, "option_id": scene_id + "-OPT02"}})
		_check(not locked.get("accepted", true) and String(locked.get("reason", "")).contains("locked"), scene_id + " choice cannot change after its real scene exit")
		if not bool(advance.get("accepted", false)):
			_finish()
			return
		await process_frame
	_check(campaign.route.current_scene_id() == "EX-CH02-S01" and campaign.route.completed_scene_ids().is_empty() and String(campaign.director.snapshot().get("chapter_id", "")) == "CH02", "final Chapter 1 scene transitions into Chapter 2")
	_check(campaign.director.snapshot().story_log.choices.size() == 12, "all twelve Chapter 1 confirmed choices survive the garden reload and Chapter 2 handoff")
	_check(campaign.hud._advance.disabled, "Chapter 2 advance stays disabled until its physical gate is ready")
	_check(String(campaign.director.snapshot().get("scenario_datetime", "")).begins_with("2046-04-30"), "B03 handoff advances from bloom to the dated P-03 entry")
	await _test_chapter2_handoff()
	_finish()

func _test_decision_review_layout() -> void:
	var original_size := root.size
	var original_scale := root.content_scale_size
	var panels := preload("res://scripts/ui/campaign_panels.gd").new()
	root.add_child(panels)
	panels.set_content_top(24)
	var catalog: Dictionary = preload("res://scripts/content/content_loader.gd").load_full()
	for resolution in [Vector2i(1280, 720), Vector2i(640, 480)]:
		root.content_scale_size = resolution
		root.size = resolution
		for large in [false, true]:
			# Match the production HUD clearance at its native logical size.
			panels.set_content_top((270.0 if large else 226.0) if resolution.x == 1280 else 24.0)
			for scene in catalog.scenes.slice(0, 12):
				var choice: Dictionary = scene.choice.duplicate(true)
				choice["choice_id"] = choice.id
				panels.bind_query({"scene_id": scene.id, "puzzle": choice, "accessibility": {"large_text": large}})
				panels.open_panel("puzzle")
				for frame in 5:
					await process_frame
				var label := "%s %s %s text" % [scene.id, resolution, "150%" if large else "normal"]
				_check(panels.get_viewport_rect().encloses(panels._panel.get_global_rect()), label + " decision panel fits viewport")
				_check(panels.get_viewport_rect().encloses(panels._close_button.get_global_rect()), label + " close control stays visible")
				var option := panels.find_child(String(choice.options[1].id), true, false) as Button
				option.pressed.emit()
				for frame in 3:
					await process_frame
				var confirm := panels.find_child("ConfirmChoice", true, false) as Button
				confirm.grab_focus()
				for frame in 3:
					await process_frame
				_check(confirm.has_focus() and panels.get_viewport_rect().encloses(confirm.get_global_rect()), label + " confirmation scrolls into view on focus")
				panels.close_panel()
	panels.free()
	root.content_scale_size = original_scale
	root.size = original_size

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
			var target_id := String(spec.target_id)
			var target := campaign.physical_target(target_id)
			_check(target != null, "B01 physical target exists: " + target_id)
			if target == null: return
			var expected_station := RoomContract.station_focus(scene_id, target_id)
			if not expected_station.is_empty():
				_check(String(target.get_meta("target_id", "")) == expected_station, "Chapter 2 operation uses its authored room station: " + target_id)
			var approach := Vector3(target.global_position.x, 0, target.global_position.z + 1)
			for ft in RoomContract.staged_layout(campaign.route.current_room_id(), scene_id).get("focus_targets", []):
				if String(ft.get("target_id", "")) == String(target.get_meta("target_id", "")) and ft.has("approach_m"):
					var a: Array = ft.approach_m
					approach = Vector3(float(a[0]), float(a[1]), float(a[2]))
					break
			campaign._player.global_position = approach
			campaign._player.velocity = Vector3.ZERO
			await physics_frame
			# P-03 and P-04 take the player's chosen inputs, never catalog defaults.
			var choices := {"record_stem_prediction": {"prediction": "Both visible colours may appear", "reason": "Alo has purple and Tara has green stems; the complete genotype is not established.", "future_test": "Compare descendant stem observations after seed harvest."},
				"assign_date_token": {"value": "2034-04"}, "assign_device_token": {"value": "HORT-01"}, "assign_channel_token": {"value": "ENGINEERING"}}
			var action := campaign.perform_target(target_id, choices.get(target_id, {}))
			_check(bool(action.get("accepted", false)), "production Chapter 2 commits " + target_id + " (" + String(action.get("reason", "")) + ")")
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
		if number == 12:
			_check(campaign.available_upgrade_chapter() == 2, "Chapter 2 offers its earned upgrade before Chapter 3")
			# The chapter end shows What you learned first; closing it opens the upgrade choice.
			_check(is_instance_valid(campaign.hud._family_panel) and campaign.hud._family_panel.name == "AcademyManual", "Chapter 2 ends on its What you learned page")
			campaign.hud.close_family()
			for _frame in 3:
				await process_frame
			_check(is_instance_valid(campaign.hud._family_panel) and campaign.hud._family_panel.name != "AcademyManual", "closing that page opens the Chapter 2 upgrade choice")
			_check(bool(campaign.choose_upgrade(2, "A").get("accepted", false)), "Player chooses the earned Chapter 2 upgrade before Chapter 3")
			_check(not is_instance_valid(campaign.hud._family_panel) and not campaign.query().paused, "Chapter 2 upgrade handoff closes its modal and resumes gameplay")
		await process_frame
	_check(campaign.route.current_scene_id() == "EX-CH03-S01", "real Chapter 2 gameplay hands off to Chapter 3")
