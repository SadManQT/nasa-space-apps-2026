extends SceneTree
const PlantInput = preload("res://tools/support/p01_input_fixture.gd")
const Route = preload("res://scripts/missions/chapter1_route.gd")
const Director = preload("res://scripts/core/campaign_director.gd")
const Gates = preload("res://scripts/missions/chapter1_gate_catalog.gd")
const PanelScene = preload("res://scenes/ui/mission_table_panel.tscn")
var failures := 0
var checks := 0
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(1280, 720)
	var route = Route.new(Director.new())
	while route.current_scene_id() != "EX-CH01-S07":
		var ids: Array = []
		for spec in Gates.targets_for_scene(route.current_scene_id()):
			ids.append(String(spec.target_id))
		if route.current_scene_id() == "EX-CH01-S03":
			ids = ["calibrate_probe", "span_probe", "recheck_probe", "inspect_packet", "compare_atmosphere"]
		for id in ids:
			# M1-108: the probe transfer gates the dry-zero commit.
			if id == "calibrate_probe":
				PlantInput.complete_probe_transfer(route)
			route.perform(id, PlantInput.payload(id))
		route.advance_scene()
	route.perform("role_cards")
	var panel = PanelScene.instantiate()
	root.add_child(panel)
	var before: Dictionary = route.director().snapshot()
	panel.open(route, "p02_shift1", {"large_text": true})
	await process_frame
	await process_frame
	await _guide_visible(panel, "GuideStep1")
	_check(panel.find_child("GuideStep1", true, false) != null, "fresh first shift teaches air first")
	_check(not route.mission_table().selection(1).has("air_production") and not route.mission_table().selection(1).has("light"), "guide never chooses air or light")
	_check(route.mission_table().selection(1).get("transfer") == "HOLD", "hidden early water holds only when unset")
	_check(panel.find_child("Crew_rafi", true, false) == null and panel.find_child("Row_1_transfer", true, false) == null, "unarrived information stays hidden")
	await _keyboard_cycle(panel)
	panel.choose(1, "air_production", 2)
	await _guide_visible(panel, "GuideStep2")
	_check((panel.find_child("TableStatus", true, false) as Label).text.contains("Air maker set to High: Battery cost 2 per shift"), "choice feedback names High and real battery cost")
	_check(panel.find_child("GuideStep2", true, false) != null, "air choice teaches light next")
	panel.choose(1, "light", "FULL")
	await _guide_visible(panel, "GuideStep3")
	_check(panel.find_child("GuideStep3", true, false) != null, "light choice teaches Try it next")
	panel.share_card("kai")
	panel.share_card("amara")
	var prediction: Dictionary = panel.preview()
	_check(prediction.accepted and prediction.forecast.final_state.E == 15 and prediction.forecast.final_state.A == 7 and prediction.forecast.trace[0].overflow == 2, "first forecast is real E15 A7 overflow2")
	await process_frame
	await process_frame
	var close: Control = panel.find_child("CloseTable", true, false)
	_check(root.get_visible_rect().encloses(close.get_global_rect()) and root.get_visible_rect().encloses(panel._frame.get_global_rect()), "150 percent frame and fixed footer fit 720p")
	_check(panel.find_child("NightStrip", true, false) != null, "night has its seven shift strip")
	for word in ["Battery", "Air", "Alo", "Tara", "Garden", "Shelter", "Radiation"]:
		_check(panel.find_child("Forecast_" + word, true, false) != null, word + " has before/after forecast")
	var emitted: Array = []
	panel.commit_requested.connect(func(id, plan): emitted.append([id, plan]))
	var y := InputEventJoypadButton.new()
	y.button_index = JOY_BUTTON_Y
	y.pressed = true
	panel._input(y)
	_check(panel.find_child("ConfirmCommit", true, false) != null and emitted.is_empty(), "controller Y opens confirmation only")
	var b := InputEventJoypadButton.new()
	b.button_index = JOY_BUTTON_B
	b.pressed = true
	panel._input(b)
	_check(panel.is_open() and panel.find_child("ConfirmCommit", true, false) == null, "controller B cancels confirmation")
	panel._input(b)
	_check(not panel.is_open() and emitted.is_empty(), "controller B closes without locking")
	panel.open(route, "p02_shift1")
	_check(panel.find_child("GuideStep3", true, false) != null, "reopen derives guide from actual choices")
	_check(route.director().snapshot() == before, "reading choosing trying and cancelling never changes station state")
	panel.close()
	route.mission_table().set_choice(1, "transfer", "FILL")
	panel.open(route, "p02_shift1")
	_check(route.mission_table().selection(1).transfer == "FILL", "reopen preserves explicit water choice")
	panel.close()
	route.mission_table().set_choice(1, "transfer", "DRAIN")
	panel.open(route, "p02_shift1")
	_check(route.mission_table().selection(1).transfer == "DRAIN", "reopen preserves explicit drain choice")
	panel.close()
	route.mission_table().apply_worked_plan("bloom")
	_check(route.perform("p02_shift1").accepted, "campaign completes the actual first shift")
	panel.open(route, "p02_stage_shift2")
	panel.share_card("rafi")
	_check(panel._guide_step() == 0 and panel.preview().accepted and panel.request_commit().accepted, "shift-two preparation has no first-shift guide")
	var stage: Dictionary = panel.confirm_commit()
	var state: Dictionary = route.director().snapshot()
	_check(stage.accepted and route.perform(stage.target_id, {"plan": stage.plan}).accepted and route.director().snapshot().resources == state.resources and route.director().query().current_shift == 1, "preparing shift two preserves resources and time")
	panel.free()
	await _test_trainer_and_later_gates()
	print("M155 MISSION TABLE RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_trainer_and_later_gates() -> void:
	var exercise := preload("res://scripts/trainer/p02_trainer.gd").new()
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/trainer/scenarios.json"))
	for entry in catalog.scenarios:
		if entry.get("adapter", "") == "p02":
			exercise.begin(entry)
	preload("res://tools/support/trainer_fixture.gd").prepare(exercise, "GOLDEN")
	var panel := PanelScene.instantiate() as MissionTablePanel
	root.add_child(panel)
	var emitted: Array = []
	panel.commit_requested.connect(func(id, plan):
		emitted.append(id)
		var result: Dictionary = exercise.commit_gate(id, plan, exercise.director().snapshot().state_revision)
		_check(result.accepted, "trainer accepts exact emitted plan " + id))
	for gate in 3:
		preload("res://tools/support/trainer_fixture.gd").share(exercise)
		panel.open(exercise, exercise.current_gate(), {"large_text": true})
		await process_frame
		await process_frame
		_check(panel.find_child("GuideStep1", true, false) == null, "trainer starts after the first-shift guide")
		_check((panel.find_child("Crew_rafi", true, false) != null) == (gate >= 1) and (panel.find_child("Crew_mei", true, false) != null) == (gate >= 2), "trainer gates reveal notes exactly on arrival")
		_check((panel.find_child("NightStrip", true, false) as Control).get_child_count() == 7, "exactly seven shift cells")
		if gate > 0:
			_check(panel._guide_step() == 0 and panel.find_child("Row_%d_transfer" % (2 if gate == 1 else 3), true, false) != null, "later gates have water controls and no guide")
			_check((panel.find_child("Row_3_heat", true, false) != null) == (gate == 2), "heat appears at first dark shift")
		var before: Dictionary = exercise.director().snapshot()
		_check(panel.preview().accepted, "trainer forecast accepted")
		_key(panel, KEY_SPACE)
		_check(emitted.size() == gate and panel.find_child("ConfirmCommit", true, false) != null, "Space opens confirmation without spending")
		_key(panel, KEY_ESCAPE)
		_check(panel.is_open() and exercise.director().snapshot() == before, "Escape cancels without mutation")
		_key(panel, KEY_SPACE)
		_key(panel, KEY_SPACE)
		_check(emitted.size() == gate + 1 and not panel.is_open(), "two Spaces submit exactly once")
		_key(panel, KEY_SPACE)
		_check(emitted.size() == gate + 1, "closed panel ignores duplicate Space")
	preload("res://tools/support/trainer_fixture.gd").share(exercise)
	panel.open(exercise, exercise.current_gate(), {"large_text": true})
	_check(exercise.current_gate() == "p02_shift5_alarm", "trainer reaches shift five")
	for action in ["PUMP", "STACK", "WAIT"]:
		panel.choose(5, "action", action)
		if action != "STACK":
			panel.choose(5, "heat", "COOL")
			panel.choose(5, "air_production", 0)
			panel.choose(5, "light", "OFF")
		if action != "WAIT":
			panel.start_task()
			_check(not (panel.find_child("TaskStep_1", true, false) as Button).text.contains("BUNK SLOT"), "task instructions use sentence case")
			_check(not panel.task_step(1).accepted if action == "PUMP" else panel.task_step(3).accepted, "ordered valves and unordered bundles")
			panel.task_step(0)
			panel.end_task()
			var partial: Dictionary = panel.preview()
			_check(partial.accepted and not partial.forecast.trace[0].action_success, action + " partial task has actual partial forecast")
			exercise.mission_table().reset_alarm_task()
			panel.start_task()
			for index in exercise.mission_table().alarm_task_steps():
				panel.task_step(index)
			panel.end_task()
		var prediction: Dictionary = panel.preview()
		_check(prediction.accepted, action + " forecast accepted")
		if action == "STACK":
			_check(prediction.forecast.trace[0].heat == 1 and prediction.forecast.trace[0].air_production == 0 and prediction.forecast.trace[0].light == 0, "STACK forced settings remain authoritative")
			_check((panel.find_child("Choice_5_heat_COOL", true, false) as Button).disabled, "forced STACK controls visibly disabled")
		_check(panel.find_child("Forecast_Radiation", true, false) != null, action + " dose is displayed")
	(panel.find_child("TableMore", true, false) as Button).pressed.emit()
	await process_frame
	await process_frame
	var more := panel.find_child("TableMore", true, false) as Button
	_check(root.gui_get_focus_owner() == more, "More retains valid focus after rebuild")
	await _press_key(KEY_ENTER)
	_check(panel.find_child("MoreDetails", true, false) == null, "Enter closes More through focused button")
	more = panel.find_child("TableMore", true, false) as Button
	var next := more.find_next_valid_focus()
	_check(next != null and panel.is_ancestor_of(next), "Tab stays inside the shared panel")
	_check(more.find_prev_valid_focus() != null and panel.is_ancestor_of(more.find_prev_valid_focus()), "back Tab stays inside the shared panel")
	root.size = Vector2i(800, 720)
	panel.open(exercise, exercise.current_gate(), {"large_text": true})
	await process_frame
	await process_frame
	_check(root.get_visible_rect().encloses(panel._frame.get_global_rect()), "narrow large-text frame has no horizontal overflow")
	_check(root.get_visible_rect().encloses((panel.find_child("CloseTable", true, false) as Control).get_global_rect()), "narrow large-text footer remains reachable")
	panel.free()
	root.size = Vector2i(1280, 720)

func _key(panel: Control, keycode: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = true
	panel._input(event)
func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL " + message)


func _guide_visible(panel: Control, id: String) -> void:
	for frame in 6:
		await process_frame
	var scroll := panel.find_child("TableBodyScroll", true, false) as ScrollContainer
	var guide := panel.find_child(id, true, false) as Control
	_check(guide != null and scroll.get_global_rect().encloses(guide.get_global_rect()), "guide remains visible after deferred focus " + id)

func _press_key(keycode: Key, backwards: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.shift_pressed = backwards
	event.pressed = true
	root.push_input(event, true)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)
	await process_frame
	await process_frame

func _keyboard_cycle(panel: Control) -> void:
	var seen := {}
	for step in 16:
		var focused := root.gui_get_focus_owner()
		_check(focused != null and panel.is_ancestor_of(focused), "Tab focus remains in the table")
		if focused != null:
			seen[String(focused.name)] = true
		await _press_key(KEY_TAB)
	for id in ["Choice_1_air_production_0", "Choice_1_air_production_1", "Choice_1_air_production_2", "Share_kai", "More_kai", "Share_amara", "More_amara", "Preview", "CloseTable", "TableMore"]:
		_check(seen.has(id), "Tab reaches " + id)
	var focused := root.gui_get_focus_owner()
	var previous := focused.find_prev_valid_focus() if focused != null else null
	await _press_key(KEY_TAB, true)
	_check(previous != null and root.gui_get_focus_owner() == previous, "Shift Tab follows the reverse table order")
