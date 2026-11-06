extends SceneTree

# Native Forward+ captures use only real trainer choices and shared UI.
const MainScene = preload("res://scenes/main.tscn")
const Fixture = preload("res://tools/support/trainer_fixture.gd")
var storage = preload("res://tools/support/isolated_storage.gd").new()
var trainer: Control
var failures := 0
var probe: Array[String] = []

func _init() -> void:
	if not storage.setup("M1-29-capture") or not storage.prepare_rendering_cache():
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	root.always_on_top = true
	root.grab_focus()
	var main := MainScene.instantiate()
	storage.configure(main)
	main.trainer_results_path = storage.directory.path_join("trainer-results.json")
	root.add_child(main)
	while not main.title_ready:
		await process_frame
	var menu := main.get_node("TitleLayer/MainMenu") as MainMenu
	var title_entry := menu.find_child("MissionTrainerEntry", true, false) as Button
	title_entry.grab_focus()
	await _capture("title")
	title_entry.pressed.emit()
	trainer = main.get("_trainer")
	await process_frame
	for group in ["Power", "Life support", "Shielding", "Food"]:
		await _group_capture(group, "catalog_")
	trainer.select_scenario("P-02")
	await _brief_initial("brief_top")
	(trainer.find_child("BriefSource", true, false) as Button).pressed.emit()
	await _capture("brief_source")
	trainer.panels.close_panel()
	trainer.open_decision()
	await _capture("day_choices")
	Fixture.prepare(trainer.exercise, "GOLDEN")
	# Reopen to show the authored choices, then submit each real panel gate.
	trainer.open_decision()
	for gate in 5:
		Fixture.share(trainer.exercise)
		trainer.table.share_card("kai")
		if gate == 1:
			await _capture("dark_choices")
		if gate == 3:
			# Exercise the actual assisted task rather than fabricating its outcome.
			trainer.exercise.mission_table().reset_alarm_task()
			trainer.table.start_task()
			trainer.table.task_step(0)
			await _capture("alarm_task")
			for index in range(1, trainer.exercise.mission_table().alarm_task_steps()):
				trainer.table.task_step(index)
			trainer.table.end_task()
		_expect(trainer.table.preview().accepted, "real panel preview gate %d" % gate)
		_expect(trainer.table.request_commit().accepted, "real confirmation gate %d" % gate)
		if gate == 3:
			await _capture("alarm_confirmation")
		_expect(trainer.table.confirm_commit().accepted, "real commit gate %d" % gate)
		await process_frame
	_expect(trainer.exercise.outcome().ending == "GOLDEN", "actual five-gate Golden result")
	await _capture("outcome")
	(trainer.panels.find_child("ReviewDecisions", true, false) as Button).pressed.emit()
	await _capture("replay")
	for shift in 7:
		(trainer.panels.find_child("ReplayNext", true, false) as Button).pressed.emit()
	(trainer.panels.find_child("Answer0", true, false) as Button).pressed.emit()
	await _capture("science_debrief")
	(trainer.panels.find_child("DebriefSource", true, false) as Button).pressed.emit()
	await _capture("debrief_source")
	(trainer.panels.find_child("BackToDebrief", true, false) as Button).pressed.emit()
	trainer.settings.large_text = true
	trainer.panels.set_accessibility(trainer.settings)
	await _capture("science_150")
	await _reach(trainer.panels.find_child("DebriefSource", true, false), trainer.panels._scroll)
	await _capture("science_150_actions")
	trainer._show_outcome()
	await _capture("outcome_150")
	await _reach(trainer.panels.find_child("TrainerReportBack", true, false), trainer.panels._scroll)
	await _capture("outcome_150_actions")
	(trainer.panels.find_child("EndingRetry", true, false) as Button).pressed.emit()
	_expect(trainer.table.is_open() and trainer.exercise.director().query().current_shift == 5, "Retry uses actual pre-final checkpoint")
	await _capture("retry_150")
	probe.append("OBSERVED inherited M1-55 table frame: %s; Close button: %s; viewport: %s" % [trainer.table._frame.get_global_rect(), (trainer.table.find_child("CloseTable", true, false) as Control).get_global_rect(), root.get_visible_rect()])
	trainer.show_catalog()
	for group in ["Power", "Life support", "Shielding", "Food"]:
		await _group_capture(group, "catalog_150_")
	trainer.select_scenario("P-02")
	await _brief_initial("brief_150_top")
	await _reach(trainer.find_child("BeginTraining", true, false), trainer._scroll)
	await _capture("brief_150_actions")
	var prior_results := FileAccess.get_file_as_bytes(main.trainer_results_path)
	trainer.store.path = storage.directory.path_join("absent-folder/capture-results.json")
	Fixture.prepare(trainer.exercise)
	trainer.open_decision()
	for gate in 5:
		Fixture.share(trainer.exercise)
		trainer.table.share_card("kai")
		_expect(trainer.table.preview().accepted and trainer.table.request_commit().accepted and trainer.table.confirm_commit().accepted, "real write-failure attempt gate %d" % gate)
		await process_frame
	var save_status := trainer.panels.find_child("TrainerSaveStatus", true, false) as Label
	_expect(save_status != null and save_status.text.contains("could not be saved"), "actual save failure is on active report")
	_expect(FileAccess.get_file_as_bytes(main.trainer_results_path) == prior_results, "actual save failure preserves earlier results")
	await _capture("outcome_write_failure")
	trainer.exit_requested.emit()
	await process_frame
	menu.set_accessibility({"large_text": true})
	await _capture("title_150")
	title_entry.grab_focus()
	await process_frame
	await process_frame
	(menu.find_child("TitleContentScroll", true, false) as ScrollContainer).ensure_control_visible(title_entry)
	await _capture("title_150_entry")
	probe.append("title preparation before teardown: preparing=%s ready=%s" % [main.preparation.preparing, main.preparation.campaign_ready])
	_expect(await main.preparation.wait_campaign(), "title background preparation finishes before capture teardown")
	probe.append("title preparation after wait: preparing=%s ready=%s" % [main.preparation.preparing, main.preparation.campaign_ready])
	main.free()
	DirAccess.remove_absolute(storage.directory.path_join("trainer-results.json"))
	storage.cleanup()
	var file := FileAccess.open("res://../production/qa/evidence/M1-29_capture_probe.txt", FileAccess.WRITE)
	file.store_string("\n".join(probe) + "\n")
	print("M1-29 CAPTURE RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)

func _group_capture(group: String, prefix: String) -> void:
	for child in trainer._body.get_children():
		if child is Label and child.text == group:
			await _reach(child, trainer._scroll)
			await _capture(prefix + group.to_lower().replace(" ", "_"))
			return
	_expect(false, "catalog group " + group)

func _reach(control: Control, scroll: ScrollContainer) -> void:
	await process_frame
	await process_frame
	scroll.scroll_vertical = int(control.position.y)
	await process_frame
	_expect(scroll.get_global_rect().intersects(control.get_global_rect()), "scroll reaches " + control.name)

func _capture(label: String) -> void:
	await create_timer(0.2).timeout
	await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/M1-29_%s.png" % label))
	_expect(result == OK, "screenshot " + label)

func _expect(condition: bool, message: String) -> void:
	probe.append(("ok " if condition else "FAIL ") + message)
	if not condition:
		failures += 1
		push_error("FAIL " + message)

func _brief_initial(label: String) -> void:
	await process_frame
	await process_frame
	await process_frame
	var reading: Rect2 = trainer._scroll.get_global_rect()
	for index in 4:
		var line := trainer._body.get_child(index) as Label
		_expect(reading.encloses(line.get_global_rect()), label + " initially shows " + line.text)
	_expect(root.gui_get_focus_owner() == trainer._scroll, label + " starts with reading focus")
	await _capture(label)
