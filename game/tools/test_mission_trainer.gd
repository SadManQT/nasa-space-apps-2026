extends SceneTree

const Adapter = preload("res://scripts/trainer/p02_trainer.gd")
const Trainer = preload("res://scripts/trainer/mission_trainer.gd")
const Results = preload("res://scripts/trainer/trainer_results.gd")
const Fixture = preload("res://tools/support/trainer_fixture.gd")
const MainScene = preload("res://scenes/main.tscn")
const Save = preload("res://scripts/save/save_service.gd")
const Legacy = preload("res://scripts/save/legacy_save.gd")
var storage = preload("res://tools/support/isolated_storage.gd").new()
var checks := 0
var failures := 0
var entry: Dictionary
var canaries: Dictionary = {}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_check(ResourceLoader.exists("res://scripts/trainer/mission_trainer.gd"), "title has an independently playable Mission Trainer")
	_check(FileAccess.file_exists("res://resources/trainer/scenarios.json"), "trainer offers sixteen authored scenarios")
	_check(storage.setup("M1-29"), "user namespace is isolated before scenes")
	_check(storage.prepare_rendering_cache(), "isolated rendering cache parents prepared")
	for path in [storage.path, storage.path + ".bak", storage.legacy_path, Save.DEFAULT_PATH, Save.DEFAULT_PATH + ".bak", Legacy.SAVE_PATH]:
		_write(path, "campaign canary " + path)
		canaries[path] = FileAccess.get_file_as_bytes(path)
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/trainer/scenarios.json"))
	_check(catalog.scenarios.size() == 16 and catalog.groups.values() == ["Power", "Life support", "Shielding", "Food"], "sixteen scenarios use the four requested demand labels")
	var seen := {}
	var available := 0
	for row in catalog.scenarios:
		_check(not seen.has(row.id) and catalog.groups.has(row.demand), "unique scenario and valid demand " + row.id)
		seen[row.id] = true
		if row.get("adapter", "") == "p02":
			available += 1
			entry = row
	_check(available == 1 and entry.id == "P-02", "only the implemented real panel is playable")
	_test_logic()
	_test_storage()
	await _test_ui()
	_check_canaries("all starts, real commits, finishes, retries, exits and reloads")
	for path in canaries:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for suffix in ["results.json", "corrupt.json", "invalid.json"]:
		DirAccess.remove_absolute(storage.directory.path_join(suffix))
	storage.cleanup()
	print("MISSION TRAINER RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_logic() -> void:
	for ending in ["BLOOM", "GOLDEN", "ALO_LOST", "MISSION_STOPPED"]:
		var exercise := Adapter.new()
		_check(exercise.begin(entry).accepted, ending + " starts from a valid full-schema isolated profile")
		var initial: Dictionary = exercise.director().snapshot()
		_check(initial.resources == preload("res://scripts/simulation/expedition_simulation.gd").new().entry_profile().resources and initial.upgrades.choices.is_empty(), "entry uses profile resources and no campaign upgrades")
		Fixture.prepare(exercise, ending)
		var count := 0
		while not exercise.current_gate().is_empty() and count < 6:
			count += 1
			var target: String = exercise.current_gate()
			Fixture.share(exercise)
			var before: Dictionary = exercise.director().snapshot()
			var local: Dictionary = exercise.mission_table().snapshot()
			var view: Dictionary = exercise.mission_table_view(target)
			_check(exercise.director().snapshot() == before and local == exercise.mission_table().snapshot(), "reading forecasts does not mutate state or choices")
			var plan: Dictionary = exercise.mission_table().plan_for_gate(target)
			_check(not exercise.commit_gate("wrong", plan, before.state_revision).accepted, "out-of-order target rejected")
			_check(not exercise.commit_gate(target, {}, before.state_revision).accepted, "wrong plan rejected")
			_check(not exercise.commit_gate(target, plan, before.state_revision - 1).accepted, "stale revision rejected")
			_check(exercise.director().snapshot() == before, "all rejected attempts are inert")
			var result: Dictionary = exercise.commit_gate(target, plan, before.state_revision)
			_check(result.accepted and result.final_state == view.gate_preview.final_state, "real shared preview matches real shared commit")
			var committed: Dictionary = exercise.director().snapshot()
			_check(not exercise.commit_gate(target, plan, before.state_revision).accepted and exercise.director().snapshot() == committed, "duplicate gate cannot spend twice")
		var report := exercise.outcome()
		_check(report.ending == ending and not report.replay.is_empty() and report.lessons.size() == 3, ending + " is a genuine result with receipt replay and three questions")
		_check(report.star_count == report.stars.values().count(true), "canonical stars count without question/time/hint penalties")
		var state: Dictionary = exercise.director().snapshot()
		_check(exercise.outcome() == report and exercise.director().snapshot() == state, "outcome/replay/questions are read-only")
		for row in report.replay:
			_check(row.forecast == row.actual.after, "recorded choices reproduce actual outcome")
		_check(exercise.retry().accepted and exercise.outcome().is_empty() and not exercise.current_gate().is_empty(), "retry restores actual precommit checkpoint and clears outcome")
		_check_canaries(ending)

func _test_storage() -> void:
	var exercise := Adapter.new()
	exercise.begin(entry)
	Fixture.prepare(exercise)
	while not exercise.current_gate().is_empty():
		Fixture.share(exercise)
		var target: String = exercise.current_gate()
		exercise.commit_gate(target, exercise.mission_table().plan_for_gate(target), exercise.director().query().state_revision)
	var store := Results.new()
	store.path = storage.directory.path_join("results.json")
	_check(store.load_results().accepted and store.results.is_empty(), "new trainer has no fabricated result")
	_check(store.record("P-02", exercise.outcome()).accepted, "actual result saves to separate file")
	var reloaded := Results.new()
	reloaded.path = store.path
	var loaded := reloaded.load_results()
	_check(loaded.accepted and reloaded.results == JSON.parse_string(JSON.stringify(store.results)), "separate results reload exactly through JSON numeric representation")
	_check(store.record("P-02", exercise.outcome()).accepted, "updating existing result is atomic and supported")
	var prior := FileAccess.get_file_as_bytes(store.path)
	var invalid: Dictionary = exercise.outcome()
	invalid.star_count = 4
	_check(not store.record("P-02", invalid).accepted and FileAccess.get_file_as_bytes(store.path) == prior, "invalid stars cannot overwrite prior results")
	_check(not store.record("P-01", exercise.outcome()).accepted, "unimplemented scenario cannot fabricate results")
	store.path = storage.directory.path_join("corrupt.json")
	_write(store.path, "broken training file")
	_check(not store.load_results().accepted and not store.record("P-02", exercise.outcome()).accepted and FileAccess.get_file_as_string(store.path) == "broken training file", "corrupt results remain preserved with actionable failure")
	store.path = storage.directory.path_join("absent-folder/results.json")
	_check(not store.record("P-02", exercise.outcome()).accepted, "write failure is reported")
	store.path = storage.directory.path_join("rename-target")
	DirAccess.make_dir_absolute(store.path)
	_check(not store.record("P-02", exercise.outcome()).accepted and DirAccess.dir_exists_absolute(store.path), "rename failure is visible and preserves existing directory")
	DirAccess.remove_absolute(store.path)
	_check_canaries("trainer result reload/corruption/write failure")

func _test_ui() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	var main := MainScene.instantiate()
	storage.configure(main)
	main.trainer_results_path = storage.directory.path_join("results.json")
	root.add_child(main)
	while not main.title_ready:
		await process_frame
	var menu := main.get_node("TitleLayer/MainMenu") as MainMenu
	menu.set_accessibility({"large_text": true, "timer_free": true, "reduced_motion": true})
	(menu.find_child("MissionTrainerEntry", true, false) as Button).grab_focus()
	var enter := InputEventKey.new()
	enter.keycode = KEY_ENTER
	enter.physical_keycode = KEY_ENTER
	enter.pressed = true
	root.push_input(enter, true)
	enter = enter.duplicate()
	enter.pressed = false
	root.push_input(enter, true)
	await process_frame
	await process_frame
	var trainer: Control = main.get("_trainer")
	_check(trainer != null and not menu.visible and menu.process_mode == Node.PROCESS_MODE_DISABLED and main.get("_campaign") == null, "real title entry blocks hidden menu without launching campaign")
	_check(trainer.settings.large_text, "title settings carry into trainer")
	var rows := 0
	for child in trainer._body.get_children():
		if child is Button and String(child.name).begins_with("Scenario_"):
			rows += 1
			_check(child.custom_minimum_size.y >= 44 and child.disabled == (child.name != "Scenario_P-02"), "real catalog availability and minimum control target")
	_check(rows == 16 and not trainer.select_scenario("P-01"), "all catalog rows present and coming-soon cannot start")
	await _check_page(trainer, "catalog at 150 percent")
	_walk_new_text(trainer._body, "catalog")
	(trainer.find_child("Scenario_P-02", true, false) as Button).pressed.emit()
	await process_frame
	_check(trainer._page == "brief" and trainer.exercise.director().query().current_shift == 0, "one scenario click opens NASA brief without spending a shift")
	_check(trainer.find_child("BeginTraining", true, false) != null, "reading has an explicit continue and no countdown gate")
	await _check_page(trainer, "brief at 150 percent")
	_walk_new_text(trainer._body, "brief")
	(trainer.find_child("BriefSource", true, false) as Button).pressed.emit()
	_check(trainer.panels.active_panel() == "data_card", "brief opens existing source card")
	_walk_new_text(trainer.panels, "brief source")
	_check((trainer.find_child("BeginTraining", true, false) as Button).disabled, "source modal blocks obscured page controls")
	await _cancel(true)
	_check(trainer.panels.active_panel().is_empty() and not (trainer.find_child("BeginTraining", true, false) as Button).disabled, "controller Back closes source modal and restores page controls")
	_check(root.gui_get_focus_owner() != null and trainer._body.is_ancestor_of(root.gui_get_focus_owner()), "source close restores page keyboard focus")
	(trainer.find_child("BeginTraining", true, false) as Button).pressed.emit()
	_check(trainer.table.is_open() and trainer.table.target_id() == "p02_shift1", "brief opens the actual campaign puzzle panel")
	await _cancel(false)
	await process_frame
	_check(trainer._page == "decision" and trainer.exercise.director().query().current_shift == 0, "closing choices preserves attempt with resume")
	(trainer.find_child("ResumeTraining", true, false) as Button).pressed.emit()
	Fixture.prepare(trainer.exercise)
	var prior_results := FileAccess.get_file_as_bytes(trainer.store.path)
	trainer.store.path = storage.directory.path_join("absent-folder/ui-results.json")
	var gates := 0
	while trainer.table.is_open() and gates < 6:
		gates += 1
		Fixture.share(trainer.exercise)
		trainer.table.share_card("kai")
		_check(trainer.table.preview().accepted and trainer.table.request_commit().accepted, "real panel preview and confirmation")
		_check(trainer.table.confirm_commit().accepted, "real panel submits genuine choice plan")
		await process_frame
	_check(gates == 5 and trainer.panels.active_panel() == "chapter1_outcome", "all five actual gates reach outcome")
	var save_status := trainer.panels.find_child("TrainerSaveStatus", true, false) as Label
	_check(save_status != null and save_status.is_visible_in_tree() and save_status.text.contains("could not be saved"), "actual record failure is visible on the active training report")
	_check(FileAccess.get_file_as_bytes(main.trainer_results_path) == prior_results, "failed UI result write preserves previous real results")
	var rating := trainer.panels.find_child("TrainerStarRating", true, false) as Label
	_check(rating != null and rating.text == "%d of 3 stars" % trainer.exercise.outcome().star_count, "trainer summary displays its actual canonical earned star count")
	_walk_new_text(trainer.panels, "trainer outcome")
	_check(trainer.panels.find_child("EndingContinue", true, false) == null and trainer.panels.find_child("TrainerReportBack", true, false) != null, "trainer report offers training actions without story unlock")
	(trainer.panels.find_child("ReviewDecisions", true, false) as Button).pressed.emit()
	for shift in 7:
		_walk_new_text(trainer.panels, "trainer replay")
		_check(trainer.panels.find_child("ReplayChoice", true, false) != null, "UI presents actual receipt choice")
		(trainer.panels.find_child("ReplayNext", true, false) as Button).pressed.emit()
	for lesson in 3:
		_walk_new_text(trainer.panels, "trainer science question")
		_check(trainer.panels.find_child("DebriefQuestion", true, false) != null, "UI exposes science question")
		(trainer.panels.find_child("Answer0", true, false) as Button).pressed.emit()
		_check(not (trainer.panels.find_child("AnswerFeedback", true, false) as Label).text.is_empty(), "question gives explanation without changing stars")
		if lesson < 2:
			(trainer.panels.find_child("DebriefNext", true, false) as Button).pressed.emit()
	(trainer.panels.find_child("DebriefSource", true, false) as Button).pressed.emit()
	(trainer.panels.find_child("BackToDebrief", true, false) as Button).pressed.emit()
	_check(trainer.panels.find_child("DebriefQuestion", true, false) != null, "source returns to same question")
	(trainer.panels.find_child("EndingRetry", true, false) as Button).pressed.emit()
	_check(trainer.table.is_open() and trainer.exercise.director().query().current_shift == 5, "UI retry resumes actual pre-final-step checkpoint")
	trainer.show_catalog()
	await _cancel(true)
	await process_frame
	_check(menu.visible and menu.process_mode == Node.PROCESS_MODE_INHERIT and menu.accessibility_settings().large_text and root.gui_get_focus_owner() == menu.find_child("MissionTrainerEntry", true, false), "Back restores exact title entry focus and settings")
	main.call("_open_trainer")
	await process_frame
	trainer = main.get("_trainer")
	_check(trainer.store.results.has("P-02"), "reopened trainer reads separately persisted real result")
	trainer.exit_requested.emit()
	main.free()
	await process_frame

func _check_page(trainer: Control, context: String) -> void:
	await process_frame
	await process_frame
	for child in trainer._body.get_children():
		if child is Control:
			trainer._scroll.ensure_control_visible(child)
			await process_frame
			_check(child.get_global_rect().size.x <= trainer._scroll.size.x + 1, context + " wraps within scroll width")
	var exit_button := trainer._body.get_child(trainer._body.get_child_count() - 1) as Button
	exit_button.grab_focus()
	await process_frame
	_check(trainer._scroll.get_global_rect().intersects(exit_button.get_global_rect()), context + " last control reachable")

func _check_canaries(context: String) -> void:
	for path in canaries:
		_check(FileAccess.get_file_as_bytes(path) == canaries[path], "campaign bytes preserved " + context + " " + path.get_file())

func _write(path: String, value: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	_check(file != null, "isolated canary/file writable")
	if file != null:
		file.store_string(value)
		file.close()

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL " + message)

func _cancel(controller: bool) -> void:
	var event: InputEvent
	if controller:
		var pad := InputEventJoypadButton.new()
		pad.button_index = JOY_BUTTON_B
		pad.pressed = true
		event = pad
	else:
		var key := InputEventKey.new()
		key.keycode = KEY_ESCAPE
		key.physical_keycode = KEY_ESCAPE
		key.pressed = true
		event = key
	root.push_input(event, true)
	await process_frame
	await process_frame

# New trainer screens only; the unchanged Mission Table has its own M1-55 work.
func _walk_new_text(node: Node, context: String) -> void:
	if node is CanvasItem and not node.is_visible_in_tree():
		return
	if node is Label or node is Button or node is RichTextLabel:
		var value: String = node.get_parsed_text() if node is RichTextLabel else node.text
		var regex := RegEx.new()
		regex.compile("EX-CH\\d|\\bP-\\d\\d\\b|\\b(LOC|MSG|CS|SFX|CUE|J)-[A-Z0-9]{2}" if node.has_meta("verbatim") else "EX-CH\\d|\\bP-\\d\\d\\b|\\b[EAWKSZCRH] ?\\d|(?i:commit\\w*|\\bstage[sd]?\\b|acknowledg\\w*|role constraints?|\\boperations?\\b)")
		_check(regex.search(value) == null, context + " plain player text: " + value.left(75))
	for child in node.get_children():
		_walk_new_text(child, context)
