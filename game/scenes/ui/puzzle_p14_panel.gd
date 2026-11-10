extends Control
class_name PuzzleP14Panel

## P-14 — Three Waves and a Broken Link (08 §P-14, 22 §9, UI_09).
##
## Panel contract (like MissionTablePanel / P01Panel / P10Panel):
##   open(model, target_id) -> bool   — model is a P14StormExecution;
##     target_id is the catalog action this opening commits
##     ("p14_commit_steps_1_2", "p14_commit_steps_3_6", "p14_read_final_log",
##     "p14_diagnose_external_branch", "p14_route_reading_1",
##     "p14_route_reading_2", or any other p14_* action).
##   commit_requested(target_id, payload) — emitted when the player confirms;
##     the caller sends the payload to the route (route.perform) and then
##     calls committed(result).
##   committed(result) — shows the observed result after the route commits.
## The panel never changes campaign resources: executing steps, playing the
## log, testing branches and recording readings only edit the puzzle
## model's working state. Preview ("Try it") and commit share the model's
## rule function. Three stages (25 §6): Learn (first wave checked), Apply
## (log and last waves), Twist (a broken link, a clear route). Plain words
## only (25 §1.1). A hint never changes an ending.

const PREDICTION_PROMPT := "Check the forecast, then try it. Nothing is filed until you lock it in."

signal opened(target_id: String)
signal closed(target_id: String)
signal commit_requested(target_id: String, payload: Dictionary)
signal sources_requested

var hint_player: HintPlayer
var _model: RefCounted
var _target := ""
var _choice: Dictionary = {}
var _prediction: Dictionary = {}
var _preview_context := ""
var _confirming := false
var _leaving := false
var _observed := false
var _dirty := false
var _notice := ""
var _hint_tier := 0
var _settings: Dictionary = {}
var _frame: PanelContainer
var _stack: VBoxContainer
var _focus := ""
var _return_focus: Control
var _covered := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100
	theme = UiKit.theme()
	var shade := ColorRect.new()
	shade.color = UiDesign.colour("scrim")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	_frame = UiDesign.glass_panel(UiDesign.colour("amara"))
	_frame.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_frame)
	_stack = VBoxContainer.new()
	_stack.add_theme_constant_override("separation", 12)
	_frame.add_child(_stack)
	get_viewport().size_changed.connect(_render)
	hide()

func open(model: RefCounted, target_id: String) -> bool:
	if model == null or not model.has_method("preview_action"):
		return false
	_return_focus = get_viewport().gui_get_focus_owner()
	_model = model
	_target = target_id
	_choice = {}
	_prediction = {}
	_preview_context = ""
	_confirming = false
	_leaving = false
	_observed = false
	_dirty = false
	_notice = "Finish all three waves before going outside. A working local radio isolates the failure to the Earth path."
	_hint_tier = 0
	show()
	opened.emit(_target)
	_render()
	return true

func is_open() -> bool:
	return visible

func set_covered(value: bool) -> void:
	_covered = value
	for child in get_children():
		(child as CanvasItem).visible = not value
	if not value:
		_restore_focus.call_deferred()

func undo() -> void:
	_choice = {}
	_notice = "Choice cleared. The evidence has not changed."
	_prediction = {}
	_preview_context = ""
	_dirty = false
	_render()

func _payload_for_target() -> Dictionary:
	match _target:
		"p14_read_final_log":
			return {"log_timing": String(_choice.get("log_timing", ""))}
		"p14_diagnose_external_branch":
			return {"route": String(_choice.get("route", ""))}
		"p14_route_reading_1", "p14_route_reading_2":
			if not _choice.has("reading"):
				return {}
			return {"reading": float(_choice.get("reading", 0.0))}
	return {}

func preview() -> Dictionary:
	_prediction = _model.preview_action(_target, _payload_for_target())
	_preview_context = _context() if _prediction.get("accepted", false) else ""
	_notice = "Prediction accepted. Compare the board, then lock it in when ready." if _prediction.get("accepted", false) else "Try again: " + UiDesign.player_words(String(_prediction.get("reason", "Check the board.")))
	_focus = "LockIn" if _prediction.get("accepted", false) else "TryIt"
	_render()
	return _prediction.duplicate(true)

func request_commit() -> Dictionary:
	if not visible or _observed or _preview_context.is_empty() or _preview_context != _context():
		_notice = "Try these choices again before locking them in; the board or your choices may have changed."
		_render()
		return {"accepted": false, "reason": _notice}
	_confirming = true
	_focus = "ConfirmChoice"
	_render()
	return {"accepted": true}

func confirm_commit() -> Dictionary:
	if not _confirming or not request_commit().accepted:
		return {"accepted": false}
	var payload: Dictionary = _payload_for_target()
	var target := _target
	discard()
	commit_requested.emit(target, payload)
	return {"accepted": true}

func cancel_confirm() -> void:
	_confirming = false
	_focus = "LockIn"
	_render()

func request_close() -> void:
	if _dirty and not _observed:
		_leaving = true
		_focus = "KeepChoosing"
		_render()
	else:
		discard()

func discard() -> void:
	if not visible:
		return
	hide()
	_confirming = false
	closed.emit(_target)
	if is_instance_valid(_return_focus) and _return_focus.is_visible_in_tree():
		_return_focus.grab_focus()

## Shows the observed result after the caller commits the payload, mirroring
## the HUD re-open flow for P01Panel: open(model, target) then committed().
func committed(result: Dictionary) -> void:
	show()
	_observed = bool(result.get("accepted", false))
	_confirming = false
	_prediction = {}
	_preview_context = ""
	_notice = "Observed: " + String(result.get("reason", "Recorded.")) if _observed else UiDesign.player_words(String(result.get("reason", "Move back to the storm and try again.")))
	_focus = "ClosePanel" if _observed else "TryIt"
	_render()

func show_result(result: Dictionary) -> void:
	committed(result)

func teach_first_use() -> void:
	if hint_player != null and not hint_player.has_seen("p14"):
		hint_player.set_settings(_settings)
		hint_player.show_how_to("p14", true)

func reveal_hint() -> void:
	_hint_tier = _hint_tier % 3 + 1
	var text := String(_model.hint(_hint_tier))
	if hint_player != null:
		var lesson := {"title": "Three Waves and a Broken Link", "purpose": "Execute the six-step storm plan, then diagnose the failed uplink and clear the route.", "steps": ["Finish all three waves before going outside.", "A working local radio isolates the failure to the Earth path.", "Keep the six-step witness, select F-EXT and record two below-threshold readings."], "nudge": text}
		hint_player.set_settings(_settings)
		hint_player.request_hint("p14", lesson)
	_notice = "Hint %d of 3: %s" % [_hint_tier, text]
	_render()

func _context() -> String:
	return JSON.stringify(_model.snapshot())

func _render() -> void:
	if not visible or _model == null:
		return
	var focused := get_viewport().gui_get_focus_owner()
	if _focus.is_empty() and focused != null and is_ancestor_of(focused):
		_focus = String(focused.name)
	for child in _stack.get_children():
		_stack.remove_child(child)
		child.queue_free()
	_frame.position = Vector2(16, 16)
	_frame.size = get_viewport_rect().size - Vector2(32, 32)
	_label(_stack, "Three Waves and a Broken Link", "heading")
	_label(_stack, "Learn: first wave checked. Apply: log and last waves. Twist: a broken link, a clear route.", "body")
	var scroll := ScrollContainer.new()
	scroll.name = "PuzzleScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	_stack.add_child(scroll)
	var columns := GridContainer.new()
	columns.columns = 3 if get_viewport_rect().size.x >= 1200 and not _settings.get("large_text", false) else 1
	columns.add_theme_constant_override("h_separation", 24)
	columns.add_theme_constant_override("v_separation", 16)
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(columns)
	var observed := _column(columns, "Observed data")
	_label(observed, _observed_text(), "body").name = "PuzzleObserved"
	var choices := _column(columns, "Your choices")
	if _leaving:
		_label(choices, "Discard these unconfirmed choices? The storm stays as it was.")
		_button(choices, "Keep choosing", "KeepChoosing", func(): _leaving = false; _render())
		_button(choices, "Discard choices and leave", "DiscardChoices", discard)
	elif _confirming:
		_label(choices, "Lock in this step?\n" + _board_text())
		_button(choices, "Confirm choice", "ConfirmChoice", confirm_commit)
		_button(choices, "Back to the storm", "BackToBoard", cancel_confirm)
	elif _observed:
		_label(choices, "Step recorded. Close this panel and follow the next goal.")
	else:
		_render_inputs(choices)
	var forecast := _column(columns, "Projected result")
	var projected := _label(forecast, _board_text() if _prediction.get("accepted", false) else PREDICTION_PROMPT)
	projected.name = "PuzzlePrediction"
	_label(forecast, "Six storm steps. Dose is sampled before an ordinary transfer. Two readings below 1, ten minutes apart, clear the route.")
	var notice := _label(_stack, _notice)
	notice.name = "PuzzleNotice"
	var footer := HFlowContainer.new()
	footer.add_theme_constant_override("h_separation", 8)
	footer.add_theme_constant_override("v_separation", 8)
	_stack.add_child(footer)
	if not _observed and not _confirming and not _leaving:
		_button(footer, "Undo choices", "UndoChoices", undo)
		_button(footer, "Try it", "TryIt", preview)
		_button(footer, "Lock in", "LockIn", request_commit)
	_button(footer, "Hint", "PuzzleHint", reveal_hint)
	_button(footer, "Data cards", "PuzzleSources", func(): sources_requested.emit())
	_button(footer, "Close", "ClosePanel", request_close)
	UiDesign.apply_type(_frame, get_viewport_rect().size.y, 1.5 if _settings.get("large_text", false) else 1.0)
	_restore_focus.call_deferred()

func _render_inputs(column: VBoxContainer) -> void:
	var data: Dictionary = _model.data()
	match _target:
		"p14_commit_steps_1_2":
			_label(column, "Learn — execute storm steps 1 and 2, then compare the result with the forecast. The hatch stays closed during exposure.")
			_label(column, "Forecast for steps 1 and 2: " + _forecast_line(0, 2))
			_button(column, "Execute steps 1 and 2", "ExecuteSteps", func(): _choose("confirmed", true, "Ready to execute steps 1 and 2."))
		"p14_commit_steps_3_6":
			_label(column, "Apply — execute storm steps 3 to 6: the peak, then the last exposure, then the drain. Noor's log plays first, in the lull.")
			_label(column, "Forecast for steps 3 to 6: " + _forecast_line(2, 6))
			_button(column, "Execute steps 3 to 6", "ExecuteSteps", func(): _choose("confirmed", true, "Ready to execute steps 3 to 6."))
		"p14_read_final_log":
			_label(column, "Apply — Noor's last log explains Alo and the Last Light Academy name. When does it play?")
			for option in data.get("choices", {}).get("log_timing", {}).get("options", []):
				_button(column, String(option.get("label", "")), "Log_" + String(option.get("value", "")), func(): _choose("log_timing", String(option.get("value", "")), "Chosen: " + String(option.get("label", ""))))
			_label(column, "Chosen: " + str(_choice.get("log_timing", "not chosen yet")))
		"p14_diagnose_external_branch":
			_label(column, "Twist — test the three branches. Local network, direct dish path, external feedthrough: which one failed?")
			_label(column, "Local: " + _branch_text("local") + ". Direct: " + _branch_text("direct") + ". External: " + _branch_text("external") + ".")
			for option in data.get("choices", {}).get("branch", {}).get("options", []):
				_button(column, String(option.get("label", "")), "Branch_" + String(option.get("value", "")), func(): _choose("route", String(option.get("value", "")), "Chosen: " + String(option.get("label", ""))))
			_label(column, "Chosen: " + str(_choice.get("route", "not chosen yet")))
		"p14_route_reading_1", "p14_route_reading_2":
			var key := "reading_1" if _target == "p14_route_reading_1" else "reading_2"
			_label(column, "Twist — one dosimeter reading. The threshold is 1; two clear readings ten scenario minutes apart clear the route.")
			for option in data.get("choices", {}).get(key, {}).get("options", []):
				# Node names cannot contain "." so the reading 0.4 button is Reading_0_4.
				_button(column, String(option.get("label", "")), "Reading_" + str(option.get("value", 0.0)).replace(".", "_"), func(): _choose("reading", float(option.get("value", 0.0)), "Chosen reading: " + String(option.get("label", ""))))
			_label(column, "Chosen: " + str(_choice.get("reading", "not chosen yet")))
		_:
			_label(column, "Confirm this step. The board shows what it needs.")
			_button(column, "Confirm: " + _target.replace("_", " "), "ConfirmStep", func(): _choose("confirmed", true, "Ready to confirm this step."))

func _choose(field: String, value, notice: String) -> void:
	_choice[field] = value
	_notice = notice
	_dirty = true
	_prediction = {}
	_preview_context = ""
	_render()

func _branch_text(branch: String) -> String:
	var snap: Dictionary = _model.snapshot()
	var results: Dictionary = snap.get("branch_results", {})
	var outcome := String(results.get(branch, ""))
	return outcome if not outcome.is_empty() else "not tested"

func _forecast_line(from_step: int, to_step: int) -> String:
	var result: Dictionary = _model.forecast()
	var steps: Array = result.get("steps", [])
	var parts: Array[String] = []
	for index in range(from_step, mini(to_step, steps.size())):
		var record: Dictionary = steps[index]
		parts.append("step %d: shelter %d, dose %d" % [record.get("step", 0), record.get("shelter", 0), record.get("dose", 0)])
	return ", ".join(parts)

func _observed_text() -> String:
	var snap: Dictionary = _model.snapshot()
	var resources: Dictionary = snap.get("resources", {})
	var readings: Array = snap.get("readings", [])
	var lines: Array[String] = []
	lines.append("Storm steps done: %d of 6. Battery %s, air %s, health %s, crops %s, food %s, dose %s." % [snap.get("steps_done", 0), resources.get("E", ""), resources.get("A", ""), resources.get("H", ""), resources.get("C", ""), resources.get("R", ""), resources.get("Z", "")])
	lines.append("Log: " + ("played — the seeds are called Alo, light." if bool(snap.get("log_played", false)) else "not played yet."))
	lines.append("Branches: local %s, direct %s, external %s." % [_branch_text("local"), _branch_text("direct"), _branch_text("external")])
	lines.append("Route: " + (String(snap.get("route", "not selected")) if not String(snap.get("route", "")).is_empty() else "not selected."))
	var reading_texts: Array[String] = []
	for reading in readings:
		reading_texts.append("%s at minute %d" % [reading.get("value", ""), reading.get("minute", 0)])
	lines.append("Readings: " + (", ".join(reading_texts) if not reading_texts.is_empty() else "none yet."))
	lines.append("Route clear: " + ("yes" if bool(snap.get("readings", []).size() == 2) and _model.readings_clear() else "not yet."))
	return "\n".join(lines)

func _board_text() -> String:
	var snap: Dictionary = _model.snapshot()
	var result: Dictionary = _model.forecast()
	var ending: Dictionary = result.get("ending", {})
	var lines: Array[String] = []
	match _target:
		"p14_commit_steps_1_2", "p14_commit_steps_3_6":
			lines.append("Forecast ending: E%s, A%s, H%s, C%s, R%s, Z%s, W%s, K%s, reserve %s." % [ending.get("E", ""), ending.get("A", ""), ending.get("H", ""), ending.get("C", ""), ending.get("R", ""), ending.get("Z", ""), ending.get("W", ""), ending.get("K", ""), ending.get("reserve", "")])
			if not bool(result.get("feasible", false)):
				lines.append("Not feasible: " + ", ".join(result.get("problems", [])))
		"p14_read_final_log":
			lines.append("Log: " + ("played." if bool(snap.get("log_played", false)) else "plays after step 2 in the lull."))
		"p14_diagnose_external_branch":
			lines.append("Local: " + _branch_text("local") + ". Direct: " + _branch_text("direct") + ". External: " + _branch_text("external") + ".")
			lines.append("Route: " + (String(snap.get("route", "not selected")) if not String(snap.get("route", "")).is_empty() else "not selected."))
		"p14_route_reading_1", "p14_route_reading_2":
			lines.append("Readings so far: %d of 2." % (snap.get("readings", []) as Array).size())
			lines.append("Threshold: 1. A 1.2 reading does not clear the route.")
		_:
			lines.append("Step: " + _target)
			lines.append("Storm steps done: %d of 6." % snap.get("steps_done", 0))
	return "\n".join(lines)

func _column(parent: Control, title: String) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	parent.add_child(column)
	_label(column, title, "heading")
	return column

func _label(parent: Node, text: String, token: String = "body") -> Label:
	var label := UiDesign.label(text, token)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, id: String, action: Callable) -> Button:
	var button := UiDesign.button(text)
	button.name = id
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _restore_focus() -> void:
	if not visible or _covered or (hint_player != null and hint_player.is_open()):
		return
	var target := find_child(_focus, true, false) as Control if not _focus.is_empty() else null
	if target == null and _focus.is_empty():
		var current := get_viewport().gui_get_focus_owner()
		if current != null and is_ancestor_of(current) and current.is_visible_in_tree():
			target = current
	if target == null:
		target = find_child("ExecuteSteps", true, false) as Control
	if target == null:
		target = find_child("TryIt", true, false) as Control
	if target == null:
		target = find_child("ClosePanel", true, false) as Control
	if target != null:
		target.grab_focus()
	_focus = ""
	if bool(_prediction.get("accepted", false)) and not _confirming and not _leaving:
		var scroll := find_child("PuzzleScroll", true, false) as ScrollContainer
		var projected := find_child("PuzzlePrediction", true, false) as Control
		if scroll != null and projected != null:
			scroll.ensure_control_visible(projected)

func _input(event: InputEvent) -> void:
	if not visible or _covered or (hint_player != null and hint_player.is_open()):
		return
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A:
		var focused := get_viewport().gui_get_focus_owner()
		if focused is Button and is_ancestor_of(focused) and not focused.disabled:
			focused.pressed.emit()
			get_viewport().set_input_as_handled()
		return
	var back: bool = (event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE) or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B)
	var confirm: bool = event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_Y
	if back:
		if _leaving:
			_leaving = false
			_render()
		elif _confirming:
			cancel_confirm()
		else:
			request_close()
	elif confirm:
		if _confirming:
			confirm_commit()
		else:
			request_commit()
	if back or confirm:
		get_viewport().set_input_as_handled()
