## Windowed M1-55 evidence: the P-02 Mission Table in the real campaign.
## Run after run_tests.sh has imported assets:
##   Godot --path game --windowed --script res://tools/capture_m155_mission_table.gd
## Writes production/qa/evidence/M1-55_*.png and M1-55_capture_probe.txt.
extends SceneTree
const PlantInput = preload("res://tools/support/p01_input_fixture.gd")

const CampaignScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const GateCatalog = preload("res://scripts/missions/chapter1_gate_catalog.gd")
const TableScript = preload("res://scripts/puzzles/p02_mission_table.gd")
var storage = preload("res://tools/support/isolated_storage.gd").new()
var campaign: Chapter1Campaign
var failures := 0
var probe: Array = []

func _init() -> void:
	if not storage.setup("M1-55-capture") or not storage.prepare_rendering_cache():
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.always_on_top = true
	root.grab_focus()
	# The films have their own evidence; keep them from covering the table.
	CampaignCutscenePlayer.autoplay = false
	campaign = CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	root.add_child(campaign)
	await process_frame
	await _goto("EX-CH01-S07")
	campaign.route.perform("role_cards")
	campaign.hud.refresh_scene()
	var table := campaign.hud.mission_table
	var fresh: Dictionary = campaign.route.mission_table().snapshot()
	for large in [false, true]:
		campaign.route.mission_table().restore(fresh)
		_set_large_text(large)
		_expect(campaign.hud.open_mission_table("p02_shift1"), "fresh guide opens")
		var suffix := "_150" if large else ""
		await _guide_capture("guide1_air" + suffix, "GuideStep1")
		table.choose(1, "air_production", 2)
		await _guide_capture("guide2_light" + suffix, "GuideStep2")
		table.choose(1, "light", "FULL")
		await _guide_capture("guide3_try" + suffix, "GuideStep3")
		table.share_card("kai")
		table.share_card("amara")
		var preview: Dictionary = table.preview()
		_expect(preview.accepted and preview.forecast.final_state.E == 15 and preview.forecast.final_state.A == 7 and preview.forecast.trace[0].overflow == 2, "fresh real forecast Battery15 Air7 overflow2")
		await _capture("shift1_forecast" + suffix)
		table.close()
	_set_large_text(false)
	campaign.hud.open_mission_table("p02_shift1")
	table.preview()
	(table.find_child("More_kai", true, false) as Button).pressed.emit()
	await _reach_note("kai")
	await _capture("crew_portrait_more")
	(table.find_child("TableMore", true, false) as Button).pressed.emit()
	await _reach(table.find_child("PinPlanA", true, false))
	await _capture("more_plan_a")
	table.request_commit()
	await _capture("shift1_confirm")
	await _stand_at("p02_shift1")
	var before_shift := int(campaign.director.query().current_shift)
	table.confirm_commit()
	await process_frame
	_expect(int(campaign.director.query().current_shift) == before_shift + 1 and int(campaign.director.snapshot().resources.E) == 15, "the confirmed shift 1 commits exactly its preview")
	# Play the documented Golden plan to the shift-5 alarm to show the task.
	campaign.route.mission_table().apply_worked_plan("golden", 1)
	for role_id in ["kai", "amara", "rafi", "mei"]:
		campaign.route.mission_table().share(role_id, 3)
	await _goto("EX-CH01-S10")
	campaign.route.perform("confirm_four_sheltered")
	campaign.hud.refresh_scene()
	_expect(campaign.hud.open_mission_table("p02_shift5_alarm"), "the HUD opens the alarm response")
	for response in ["WAIT", "PUMP"]:
		table.choose(5, "action", response)
		table.choose(5, "heat", "COOL")
		table.choose(5, "air_production", 0)
		table.choose(5, "light", "OFF")
		if response == "PUMP":
			table.start_task()
			table.task_step(0)
			table.end_task()
		table.preview()
		await _capture("shift5_" + response.to_lower() + "_forecast")
	table.choose(5, "action", "STACK")
	table.start_task()
	table.task_step(0)
	table.task_step(2)
	await _capture("shift5_stack_task")
	_expect_footer("shift5 task normal")
	table.close()
	_set_large_text(true)
	campaign.hud.open_mission_table("p02_shift5_alarm")
	await _reach(table.find_child("TaskStep_2", true, false))
	await _capture("shift5_stack_task_150")
	_expect_footer("shift5 task 150")
	table.close()
	_set_large_text(false)
	campaign.hud.open_mission_table("p02_shift5_alarm")
	table.task_step(1)
	table.task_step(3)
	table.preview()
	for person in ["rafi", "mei"]:
		await _reach_note(person)
		await _capture("crew_" + person + "_portrait")
	await _capture("shift5_stack_preview")
	# 150% text at the same table, then back to the default size.
	table.close()
	_set_large_text(true)
	_expect(campaign.hud.open_mission_table("p02_shift5_alarm"), "the table reopens at 150% text")
	table.preview()
	await _capture("shift5_150")
	_expect_footer("shift5 150")
	table.request_commit()
	await _capture("shift5_confirmation_150")
	table.cancel_confirm()
	var commit := table.find_child("Commit", true, false) as Control
	probe.append("large text: viewport %s, frame %s, commit %s" % [str(campaign.hud.get_viewport_rect()), str(table._frame.get_global_rect()), str(commit.get_global_rect() if commit != null else Rect2())])
	_expect(commit != null and campaign.hud.get_viewport_rect().encloses(commit.get_global_rect()) and campaign.hud.get_viewport_rect().encloses(table._frame.get_global_rect()), "the table and Commit stay on screen at 150% text")
	table.close()
	_set_large_text(false)
	campaign.hud.open_mission_table("p02_shift5_alarm")
	table.preview()
	table.request_commit()
	await _stand_at("p02_shift5_alarm")
	table.confirm_commit()
	await process_frame
	_expect(int(campaign.director.snapshot().resources.K) == 2, "a complete STACK commits K2")
	await _goto("EX-CH01-S11")
	campaign.route.perform("verify_exposure_order")
	campaign.route.perform("return_water")
	campaign.hud.refresh_scene()
	campaign.hud.open_mission_table("p02_shifts6_7")
	table.preview()
	await _capture("shifts6_7_golden_projection")
	table.request_commit()
	await _capture("shifts6_7_confirm")
	await _stand_at("p02_shifts6_7")
	table.confirm_commit()
	await process_frame
	_expect(String(campaign.route.chapter_ready().ending) == "GOLDEN", "the Golden plan earns GOLDEN BLOOM in the real campaign")
	await _capture("ending_outcome")
	campaign.hud.panels.close_panel()
	campaign.free()
	await _failure_capture()
	await _trainer_capture()
	storage.cleanup()
	probe.append("RESULT %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	var file := FileAccess.open(ProjectSettings.globalize_path("res://../production/qa/evidence/M1-55_capture_probe.txt"), FileAccess.WRITE)
	if file != null:
		file.store_string("\n".join(probe) + "\n")
	print("M1-55 MISSION TABLE CAPTURE RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)

func _goto(scene_id: String) -> void:
	while campaign.route.current_scene_id() != scene_id:
		var current: String = campaign.route.current_scene_id()
		var ids: Array = ["calibrate_probe", "span_probe", "recheck_probe", "inspect_packet", "compare_atmosphere"] if current == "EX-CH01-S03" else GateCatalog.targets_for_scene(current).map(func(spec): return String(spec.target_id))
		for target_id in ids:
			if TableScript.is_gate(target_id) and current == "EX-CH01-S10":
				var alarm: Dictionary = campaign.route.mission_table().alarm_state()
				if String(alarm.state) == "idle" and String(alarm.action) in ["PUMP", "STACK"]:
					break
			campaign.route.perform(target_id, PlantInput.payload(target_id))
		if not bool(campaign.route.advance_scene().get("accepted", false)):
			_expect(false, "reach " + scene_id + " (stuck at " + current + ")")
			return
	campaign._sync_route_projection()
	campaign._refresh_world()
	await campaign.wait_loading()
	campaign.hud.refresh_scene()
	await process_frame

func _set_large_text(value: bool) -> void:
	var state: Dictionary = campaign.director.snapshot()
	state.accessibility.large_text = value
	campaign.director.restore_snapshot(state)
	campaign.hud.apply_accessibility()

func _stand_at(target_id: String) -> void:
	var target := campaign.physical_target(target_id)
	if target == null:
		_expect(false, "physical target " + target_id)
		return
	campaign._player.global_position = Vector3(target.global_position.x, 0.0, target.global_position.z + 1.0)
	campaign._player.velocity = Vector3.ZERO
	await physics_frame
	await physics_frame

func _expect(condition: bool, message: String) -> void:
	probe.append(("ok   " if condition else "FAIL ") + message)
	if not condition:
		failures += 1
		push_error("FAIL " + message)

func _capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../production/qa/evidence/M1-55_%s.png" % label)
	var error := root.get_texture().get_image().save_png(path)
	if error != OK:
		failures += 1
	probe.append("screenshot %s (%s)" % [path.get_file(), "saved" if error == OK else "error %d" % error])
	print("M1-55 evidence: ", path, " (", error, ")")

func _guide_capture(label: String, guide_name: String) -> void:
	await process_frame
	await process_frame
	await process_frame
	var table := campaign.hud.mission_table
	var guide := table.find_child(guide_name, true, false) as Control
	var scroll := table.find_child("TableBodyScroll", true, false) as ScrollContainer
	_expect(guide != null and scroll.get_global_rect().encloses(guide.get_global_rect()), label + " initial viewport shows teaching without manual scroll")
	_expect_footer(label)
	await _capture(label)

func _expect_footer(context: String) -> void:
	var table := campaign.hud.mission_table
	var footer := table.find_child("CloseTable", true, false) as Control
	_expect(root.get_visible_rect().encloses(table._frame.get_global_rect()) and footer != null and root.get_visible_rect().encloses(footer.get_global_rect()), context + " frame and footer fit")
	probe.append(context + " frame=" + str(table._frame.get_global_rect()) + " footer=" + str(footer.get_global_rect()) + " focus=" + str(root.gui_get_focus_owner()))

func _reach(control: Control) -> void:
	await process_frame
	await process_frame
	var scroll := campaign.hud.mission_table.find_child("TableBodyScroll", true, false) as ScrollContainer
	scroll.ensure_control_visible(control)
	await process_frame

func _reach_note(id: String) -> void:
	var table := campaign.hud.mission_table
	for attempt in 900:
		if table._portraits.has(id):
			break
		await process_frame
	_expect(table._portraits.has(id), "approved cast portrait rendered for " + id)
	await _reach(table.find_child("Crew_" + id, true, false))

func _failure_capture() -> void:
	campaign = CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	root.add_child(campaign)
	await process_frame
	preload("res://tools/support/p02_plan_fixture.gd").prepare(campaign.route)
	campaign.route.mission_table().set_choice(1, "air_production", 0)
	await _goto("EX-CH01-S11")
	campaign.route.perform("verify_exposure_order")
	campaign.route.perform("return_water")
	campaign.hud.refresh_scene()
	campaign.hud.open_mission_table("p02_shifts6_7")
	var table := campaign.hud.mission_table
	for card in table.view().cards:
		if card.arrived:
			table.share_card(card.role_id)
	table.preview()
	await _capture("failing_forecast")
	table.request_commit()
	await _capture("failing_confirmation")
	await _stand_at("p02_shifts6_7")
	table.confirm_commit()
	await _capture("failed_report")
	_expect(campaign.route.chapter_ready().ending == "MISSION_STOPPED" and campaign.hud._status.text.contains("Air reached zero"), "actual failed lock-in explains cause")
	campaign.hud.panels.close_panel()
	_expect(campaign.hud._status.is_visible_in_tree(), "actual failed-plan toast is visible after report close")
	await _capture("failed_actual_toast")
	campaign.hud.panels.open_panel("outcome", campaign.hud._last_outcome)
	await _capture("failed_last_result")
	campaign.free()

func _trainer_capture() -> void:
	var main := preload("res://scenes/main.tscn").instantiate()
	storage.configure(main)
	main.trainer_results_path = storage.directory.path_join("trainer-results.json")
	root.add_child(main)
	while not main.title_ready:
		await process_frame
	main._open_trainer()
	await process_frame
	var trainer: Control = main._trainer
	trainer.select_scenario("P-02")
	trainer.open_decision()
	await _trainer_image(trainer, "day_choices")
	preload("res://tools/support/trainer_fixture.gd").prepare(trainer.exercise, "GOLDEN")
	trainer.open_decision()
	for gate in 5:
		preload("res://tools/support/trainer_fixture.gd").share(trainer.exercise)
		trainer.table.share_card("kai")
		if gate == 1:
			await _trainer_image(trainer, "dark_choices")
		if gate == 3:
			trainer.exercise.mission_table().reset_alarm_task()
			trainer.table.start_task()
			trainer.table.task_step(0)
			await _trainer_image(trainer, "alarm_task")
			for index in range(1, trainer.exercise.mission_table().alarm_task_steps()):
				trainer.table.task_step(index)
			trainer.table.end_task()
		_expect(trainer.table.preview().accepted and trainer.table.request_commit().accepted, "trainer real forecast and confirmation gate %d" % gate)
		if gate == 3:
			await _trainer_image(trainer, "alarm_confirmation")
		_expect(trainer.table.confirm_commit().accepted, "trainer real lock-in gate %d" % gate)
		await process_frame
	trainer.settings.large_text = true
	(trainer.panels.find_child("EndingRetry", true, false) as Button).pressed.emit()
	_expect(trainer.table.is_open(), "trainer actual Retry reopens shared table")
	await _trainer_image(trainer, "retry_150")
	_expect(await main.preparation.wait_campaign(), "title background preparation completes before teardown")
	main.free()
	DirAccess.remove_absolute(storage.directory.path_join("trainer-results.json"))

func _trainer_image(trainer: Control, label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var table: Control = trainer.table
	_expect(root.get_visible_rect().encloses(table._frame.get_global_rect()), "trainer " + label + " frame fits")
	var close := table.find_child("CloseTable", true, false) as Control
	var confirm := table.find_child("ConfirmCommit", true, false) as Control
	var action := close if close != null else confirm
	_expect(action != null and root.get_visible_rect().encloses(action.get_global_rect()), "trainer " + label + " essential action fits")
	var path := "res://../production/qa/evidence/M1-29_%s.png" % label
	_expect(root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path)) == OK, "refreshed trainer " + label)
	probe.append("trainer " + label + " frame=" + str(table._frame.get_global_rect()) + " action=" + str(action.get_global_rect()))
