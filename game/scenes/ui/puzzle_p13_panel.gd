extends Control
class_name PuzzleP13Panel

## P-13 — One Integrated Storm Plan (08 §P-13, 22 §9, UI_09).
##
## Panel contract (like MissionTablePanel / P01Panel / P10Panel):
##   open(model, target_id) -> bool   — model is a P13StormPlan;
##     target_id is the catalog action this opening commits
##     ("p13_commit_plan", "p13_confirm_five_person_profile",
##     "p13_latch_founder_reserve", "p13_verify_water_shield",
##     "p13_verify_crate_shield", "p13_verify_drain_order", or any other
##     p13_* action).
##   commit_requested(target_id, payload) — emitted when the player confirms;
##     the caller sends the payload to the route (route.perform) and then
##     calls committed(result).
##   committed(result) — shows the observed result after the route commits.
## The panel never changes campaign resources: choosing water, crates, heat,
## light and the drain step only edits the puzzle model's working plan.
## Preview ("Try it") and commit share the model's rule function.
## Three stages (25 §6): Learn (five people, one storm), Apply (one
## six-step plan), Twist (verify before the peak). Plain words only
## (25 §1.1). A hint never changes an ending.

const PREDICTION_PROMPT := "Set the water, crates, heat, light and drain, then try it. Nothing is filed until you lock it in."

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
	_notice = "Water and cargo share the shielding job. Shield 6 gives zero dose even in the peak steps."
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
	if _target == "p13_commit_plan":
		_notice = String(_model.reset().get("reason", "Plan cleared."))
	else:
		_choice = {}
		_notice = "Choice cleared. The evidence has not changed."
	_prediction = {}
	_preview_context = ""
	_dirty = false
	_render()

func _payload_for_target() -> Dictionary:
	var snap: Dictionary = _model.snapshot()
	match _target:
		"p13_commit_plan":
			# The gate payload only: water, crate, heat, light, reserve.
			# Roster, seeds and uplink are preparation state the model
			# already holds from the earlier openings.
			return {"water": int(snap.get("water", 4)), "crate": int(snap.get("crate", 2)), "heat": String(snap.get("heat", "COZY")), "light": String(snap.get("light", "DIM")), "reserve": 30}
		"p13_confirm_five_person_profile":
			return {"occupants": int(_choice.get("occupants", 0))}
		"p13_latch_founder_reserve":
			return {"seed_latched": int(_choice.get("seed_latched", 0))}
		"p13_verify_water_shield", "p13_verify_crate_shield", "p13_verify_drain_order":
			return {"water": int(snap.get("water", 4)), "crate": int(snap.get("crate", 2)), "drain_step": int(snap.get("drain_step", 6))}
	return {}

func preview() -> Dictionary:
	_prediction = _model.preview_action(_target, _payload_for_target())
	_preview_context = _context() if _prediction.get("accepted", false) else ""
	_notice = "Prediction accepted. Compare the forecast, then lock it in when ready." if _prediction.get("accepted", false) else "Try again: " + UiDesign.player_words(String(_prediction.get("reason", "Check the plan.")))
	_focus = "LockIn" if _prediction.get("accepted", false) else "TryIt"
	_render()
	return _prediction.duplicate(true)

func request_commit() -> Dictionary:
	if not visible or _observed or _preview_context.is_empty() or _preview_context != _context():
		_notice = "Try these choices again before locking them in; the plan or your choices may have changed."
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
	_notice = "Observed: " + String(result.get("reason", "Recorded.")) if _observed else UiDesign.player_words(String(result.get("reason", "Move back to the plan and try again.")))
	_focus = "ClosePanel" if _observed else "TryIt"
	_render()

func show_result(result: Dictionary) -> void:
	committed(result)

func teach_first_use() -> void:
	if hint_player != null and not hint_player.has_seen("p13"):
		hint_player.set_settings(_settings)
		hint_player.show_how_to("p13", true)

func reveal_hint() -> void:
	_hint_tier = _hint_tier % 3 + 1
	var text := String(_model.hint(_hint_tier))
	if hint_player != null:
		var lesson := {"title": "One Integrated Storm Plan", "purpose": "Plan six dark storm steps so the crew, the garden and the seeds all stay safe.", "steps": ["Put the seeds inside before the peak.", "Water and cargo share the shielding job.", "Prepare W4 and K2; COZY/DIM throughout; drain in step 6 after exposure."], "nudge": text}
		hint_player.set_settings(_settings)
		hint_player.request_hint("p13", lesson)
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
	_label(_stack, "One Integrated Storm Plan", "heading")
	_label(_stack, "Learn: five people, one storm. Apply: one six-step plan. Twist: verify before the peak.", "body")
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
		_label(choices, "Discard these unconfirmed choices? The plan stays as it was.")
		_button(choices, "Keep choosing", "KeepChoosing", func(): _leaving = false; _render())
		_button(choices, "Discard choices and leave", "DiscardChoices", discard)
	elif _confirming:
		_label(choices, "Lock in this plan?\n" + _board_text())
		_button(choices, "Confirm choice", "ConfirmChoice", confirm_commit)
		_button(choices, "Back to the plan", "BackToBoard", cancel_confirm)
	elif _observed:
		_label(choices, "Step recorded. Close this panel and follow the next goal.")
	else:
		_render_inputs(choices)
	var forecast := _column(columns, "Projected result")
	var projected := _label(forecast, _board_text() if _prediction.get("accepted", false) else PREDICTION_PROMPT)
	projected.name = "PuzzlePrediction"
	_label(forecast, "Six dark steps. Multipliers 1, 1, 2, 2, 1, 1. Shield 6 gives zero dose even in the peak steps.")
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
		"p13_commit_plan":
			_label(column, "Apply — six dark 7.2 h steps for five people. Water and crates in shelter make the shield; the drain waits until step 6.")
			_label(column, "Shelter water (shared units in shelter):")
			for option in data.get("choices", {}).get("water_start", {}).get("options", []):
				_button(column, String(option.get("label", "")), "Water_" + str(int(option.get("value", 4))), func(): _set_water(int(option.get("value", 4))))
			_label(column, "Crate shielding (installed through step 6):")
			for option in data.get("choices", {}).get("crate", {}).get("options", []):
				_button(column, String(option.get("label", "")), "Crate_" + str(int(option.get("value", 2))), func(): _set_crate(int(option.get("value", 2))))
			_label(column, "Heat and light for all six steps:")
			for option in data.get("choices", {}).get("heat", {}).get("options", []):
				_button(column, String(option.get("label", "")), "Heat_" + String(option.get("value", "")), func(): _set_heat(String(option.get("value", "COZY"))))
			for option in data.get("choices", {}).get("light", {}).get("options", []):
				_button(column, String(option.get("label", "")), "Light_" + String(option.get("value", "")), func(): _set_light(String(option.get("value", "DIM"))))
			_label(column, "Drain:")
			for option in data.get("choices", {}).get("drain", {}).get("options", []):
				_button(column, String(option.get("label", "")), "Drain_" + str(int(option.get("value", 6))), func(): _set_drain(int(option.get("value", 6))))
			_label(column, "Preparation (from the earlier openings):")
			_button(column, "Isolate the exposed uplink", "Uplink_Isolate", func(): _set_uplink())
			_label(column, "Plan now: " + _plan_text())
		"p13_confirm_five_person_profile":
			_label(column, "Learn — April's card counted four. Who does the storm forecast count?")
			for option in data.get("choices", {}).get("roster", {}).get("options", []):
				_button(column, String(option.get("label", "")), "Roster_" + str(int(option.get("value", 0))), func(): _choose("occupants", int(option.get("value", 0)), "Chosen: " + String(option.get("label", ""))))
			_label(column, "Chosen: " + str(_choice.get("occupants", "not chosen yet")))
		"p13_latch_founder_reserve":
			_label(column, "Twist — the founder reserve is two compartments, 15 + 15 = 30. Latch them before the peak step.")
			for option in data.get("choices", {}).get("seed", {}).get("options", []):
				_button(column, String(option.get("label", "")), "Seed_" + str(int(option.get("value", 0))), func(): _choose("seed_latched", int(option.get("value", 0)), "Chosen: " + String(option.get("label", ""))))
			_label(column, "Chosen: " + str(_choice.get("seed_latched", "not chosen yet")))
		"p13_verify_water_shield", "p13_verify_crate_shield", "p13_verify_drain_order":
			_label(column, "Twist — verify the committed plan before the storm. The shield and the drain order are checked, not merely scheduled.")
			_label(column, "Plan now: " + _plan_text())
			_button(column, "Confirm: " + _target.replace("_", " "), "ConfirmStep", func(): _choose("confirmed", true, "Ready to confirm this step."))
		_:
			_label(column, "Confirm this step. The board shows what it needs.")
			_button(column, "Confirm: " + _target.replace("_", " "), "ConfirmStep", func(): _choose("confirmed", true, "Ready to confirm this step."))

func _set_water(value: int) -> void:
	var result: Dictionary = _model.set_water(value)
	_notice = String(result.get("reason", ""))
	_dirty = true
	_prediction = {}
	_preview_context = ""
	_render()

func _set_crate(value: int) -> void:
	var result: Dictionary = _model.set_crate(value)
	_notice = String(result.get("reason", ""))
	_dirty = true
	_prediction = {}
	_preview_context = ""
	_render()

func _set_heat(value: String) -> void:
	var result: Dictionary = _model.set_heat(value)
	_notice = String(result.get("reason", ""))
	_dirty = true
	_prediction = {}
	_preview_context = ""
	_render()

func _set_light(value: String) -> void:
	var result: Dictionary = _model.set_light(value)
	_notice = String(result.get("reason", ""))
	_dirty = true
	_prediction = {}
	_preview_context = ""
	_render()

func _set_drain(value: int) -> void:
	var result: Dictionary = _model.set_drain_step(value)
	_notice = String(result.get("reason", ""))
	_dirty = true
	_prediction = {}
	_preview_context = ""
	_render()

func _set_uplink() -> void:
	var result: Dictionary = _model.isolate_uplink()
	_notice = String(result.get("reason", ""))
	_dirty = true
	_prediction = {}
	_preview_context = ""
	_render()

func _choose(field: String, value, notice: String) -> void:
	_choice[field] = value
	_notice = notice
	_dirty = true
	_prediction = {}
	_preview_context = ""
	_render()

func _plan_text() -> String:
	var snap: Dictionary = _model.snapshot()
	return "W%d, K%d, %s/%s, drain step %d, seeds %d of 2 latched, uplink %s, roster %s." % [snap.get("water", 4), snap.get("crate", 2), snap.get("heat", "COZY"), snap.get("light", "DIM"), snap.get("drain_step", 6), snap.get("seed_latched", 0), "isolated" if bool(snap.get("uplink_isolated", false)) else "not isolated", "five" if bool(snap.get("roster_five", false)) else "not confirmed"]

func _observed_text() -> String:
	var snap: Dictionary = _model.snapshot()
	var result: Dictionary = _model.forecast()
	var ending: Dictionary = result.get("ending", {})
	var lines: Array[String] = []
	lines.append("Storm: six dark 7.2 h steps, multipliers 1, 1, 2, 2, 1, 1. Entry E30/32, A10/10, H6, C8, R18.")
	lines.append("Plan now: " + _plan_text())
	lines.append("Forecast ending: E%s, A%s, H%s, C%s, R%s, Z%s, W%s, K%s, reserve %s." % [ending.get("E", ""), ending.get("A", ""), ending.get("H", ""), ending.get("C", ""), ending.get("R", ""), ending.get("Z", ""), ending.get("W", ""), ending.get("K", ""), ending.get("reserve", "")])
	lines.append("Feasible: " + ("yes" if bool(result.get("feasible", false)) else "no — " + ", ".join(result.get("problems", []))))
	lines.append("Committed: " + ("yes" if bool(snap.get("committed", false)) else "not yet."))
	return "\n".join(lines)

func _board_text() -> String:
	var snap: Dictionary = _model.snapshot()
	var result: Dictionary = _model.forecast()
	var ending: Dictionary = result.get("ending", {})
	var lines: Array[String] = []
	match _target:
		"p13_commit_plan":
			for record in result.get("steps", []):
				lines.append("Step %d (x%d): shelter %d, dose %d, E%s A%s H%s C%s R%s Z%s." % [record.get("step", 0), record.get("multiplier", 1), record.get("shelter", 0), record.get("dose", 0), record.get("E", ""), record.get("A", ""), record.get("H", ""), record.get("C", ""), record.get("R", ""), record.get("Z", "")])
			lines.append("Ending: E%s, A%s, H%s, C%s, R%s, Z%s, W%s, K%s, reserve %s." % [ending.get("E", ""), ending.get("A", ""), ending.get("H", ""), ending.get("C", ""), ending.get("R", ""), ending.get("Z", ""), ending.get("W", ""), ending.get("K", ""), ending.get("reserve", "")])
			if not bool(result.get("feasible", false)):
				lines.append("Not feasible: " + ", ".join(result.get("problems", [])))
		"p13_confirm_five_person_profile":
			lines.append("Roster: " + ("five people, including Ferreira." if bool(snap.get("roster_five", false)) else "not confirmed yet."))
		"p13_latch_founder_reserve":
			lines.append("Seed compartments latched: %d of 2." % snap.get("seed_latched", 0))
		_:
			lines.append("Step: " + _target)
			lines.append("Plan now: " + _plan_text())
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
		target = find_child("Water_4", true, false) as Control
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
