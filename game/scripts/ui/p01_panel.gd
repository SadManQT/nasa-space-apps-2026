extends Control
class_name P01Panel

const PREDICTION_PROMPT := "Choose your values, then try them. The real equipment stays unchanged during a prediction."

## Local selections only. The campaign owns forecasts, validation and physical commits.
signal opened(target_id: String)
signal closed(target_id: String)
signal commit_requested(target_id: String, payload: Dictionary)
signal sources_requested

var hint_player: HintPlayer
var _campaign: Chapter1Campaign
var _target := ""
var _view: Dictionary = {}
var _choices: Dictionary = {}
var _prediction: Dictionary = {}
var _preview_context := ""
var _confirming := false
var _leaving := false
var _observed := false
var _notice := ""
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

func open(campaign: Chapter1Campaign, target_id: String) -> bool:
	var value := campaign.p01_view(target_id)
	if not value.get("accepted", false):
		return false
	_return_focus = get_viewport().gui_get_focus_owner()
	_campaign = campaign
	_target = target_id
	_view = value
	_settings = campaign.query().get("accessibility", {})
	_choices = {}
	_prediction = {}
	_preview_context = ""
	_confirming = false
	_leaving = false
	_observed = false
	_notice = "Choose what you predict, then try it safely. Nothing changes until you confirm."
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

func selection() -> Dictionary:
	return _choices.duplicate(true)

func choose(field: String, value) -> void:
	if not visible or _observed:
		return
	_choices[field] = value
	_prediction = {}
	_preview_context = ""
	_confirming = false
	_notice = "Selection changed. Try it to see what this would do."
	var notice := find_child("ProbeNotice", true, false) as Label
	if notice != null:
		notice.text = _notice
	var projected := find_child("ProbePrediction", true, false) as Label
	if projected != null:
		projected.text = PREDICTION_PROMPT

func undo() -> void:
	_choices.clear()
	_prediction.clear()
	_preview_context = ""
	_notice = "Choices cleared. The equipment has not changed."
	_render()

func _payload() -> Dictionary:
	var payload := _choices.duplicate(true)
	payload.erase("confirmed")
	return payload

func preview() -> Dictionary:
	if _choices.is_empty() or (_simple_action() and _choices.get("confirmed") != true):
		_prediction = {"accepted": false, "reason": "Choose an input before trying it."}
	else:
		_prediction = _campaign.forecast_target(_target, _payload())
	_preview_context = _context() if _prediction.get("accepted", false) else ""
	_notice = "Prediction accepted. Compare the projected observation, then confirm when ready." if _prediction.get("accepted", false) else "Try again: " + UiDesign.player_words(String(_prediction.get("reason", "Check your selection.")))
	_focus = "ProbePrediction" if _prediction.get("accepted", false) else "TryIt"
	_render()
	return _prediction.duplicate(true)

func request_commit() -> Dictionary:
	if not visible or _observed or _preview_context.is_empty() or _preview_context != _context():
		_notice = "Try these choices again before confirming; the equipment or your selection may have changed."
		_render()
		return {"accepted": false, "reason": _notice}
	_confirming = true
	_focus = "ConfirmChoice"
	_render()
	return {"accepted": true}

func confirm_commit() -> Dictionary:
	if not _confirming or not request_commit().accepted:
		return {"accepted": false}
	var payload := _payload()
	var target := _target
	discard()
	commit_requested.emit(target, payload)
	return {"accepted": true}

func cancel_confirm() -> void:
	_confirming = false
	_focus = "LockIn"
	_render()

func request_close() -> void:
	if not _choices.is_empty() and not _observed:
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

func show_result(result: Dictionary) -> void:
	_observed = bool(result.get("accepted", false))
	_confirming = false
	_prediction = {}
	_preview_context = ""
	_view = _campaign.p01_view(_target)
	_notice = "Observed: " + (_action_title() + " completed. " + _explanation() if _observed else UiDesign.player_words(String(result.get("reason", "Move back to the equipment and try again."))))
	_focus = "CloseProbe" if _observed else "TryIt"
	_render()

func teach_first_use() -> void:
	if hint_player != null and not hint_player.has_seen("probe"):
		hint_player.set_settings(_settings)
		hint_player.show_how_to("probe", true)

func reveal_hint() -> void:
	if hint_player == null:
		return
	var lesson := HowToCard.lesson("probe")
	lesson.nudge = "Check the instrument before trusting it."
	lesson.relationship = "Use the two reference cups. " + String(lesson.get("relationship", ""))
	lesson.example = "Dry must read 0, wet 100, then fill both to 50. Any calibrated moisture from 40 through 60 is accepted."
	hint_player.set_settings(_settings)
	hint_player.request_hint("p01", lesson)

func _context() -> String:
	var state := _campaign.director.snapshot()
	state.erase("presentation_resume")
	return JSON.stringify([_campaign.route.snapshot(), state, _choices])

func _simple_action() -> bool:
	return _view.get("action", "") in ["scan_packet", "seal_alo", "seal_tara"]

func _action_title() -> String:
	return {"set_zero": "Set the dry zero", "set_span": "Set the wet span", "recheck": "Recheck both references", "scan_packet": "Scan the seed packet", "plant_alo": "Place Alo's seed", "plant_tara": "Place Tara's seed", "water_alo": "Water Alo", "water_tara": "Water Tara", "label_alo_external": "Label Alo's cassette", "label_tara_indoor": "Label Tara's cassette", "seal_alo": "Close Alo's seal", "seal_tara": "Close Tara's seal"}.get(_view.get("action", ""), "Check the equipment")

func _explanation() -> String:
	if _target in ["calibrate_probe", "span_probe", "recheck_probe"]:
		return "Two known references let you trust the probe before measuring the seedlings."
	return "One seed per cassette, calibrated moisture and distinct labels make this a fair comparison."

func _render() -> void:
	if not visible or _campaign == null:
		return
	var focused := get_viewport().gui_get_focus_owner()
	if _focus.is_empty() and focused != null and is_ancestor_of(focused):
		_focus = String(focused.name)
	for child in _stack.get_children():
		_stack.remove_child(child)
		child.queue_free()
	_frame.position = Vector2(16, 16)
	_frame.size = get_viewport_rect().size - Vector2(32, 32)
	_label(_stack, _action_title(), "heading")
	_label(_stack, "Check the probe, then plant the pair safely.", "body")
	var scroll := ScrollContainer.new()
	scroll.name = "ProbeScroll"
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
	var actual := _label(observed, _readings(_view), "body")
	actual.name = "ProbeObserved"
	var equipment := _column(columns, "Your prediction")
	if _leaving:
		_label(equipment, "Discard these unconfirmed choices? The equipment will stay as it is.")
		_button(equipment, "Keep choosing", "KeepChoosing", func(): _leaving = false; _render())
		_button(equipment, "Discard choices and leave", "DiscardChoices", discard)
	elif _confirming:
		_label(equipment, "Use this prediction at the equipment?\n" + _selection_text())
		_button(equipment, "Confirm choice", "ConfirmChoice", confirm_commit)
		_button(equipment, "Back to prediction", "BackToPrediction", cancel_confirm)
	elif _observed:
		_label(equipment, "Action complete. Close this panel and follow the next goal.")
	else:
		_render_inputs(equipment)
	var forecast := _column(columns, "Projected result")
	var projected := _label(forecast, _readings(_prediction.p01) if _prediction.get("accepted", false) and _prediction.has("p01") else PREDICTION_PROMPT)
	projected.name = "ProbePrediction"
	projected.focus_mode = Control.FOCUS_ALL
	_label(forecast, _explanation())
	var reason := String(_view.get("prerequisite_reason", ""))
	if not reason.is_empty():
		_label(forecast, reason)
	var notice := _label(_stack, _notice)
	notice.name = "ProbeNotice"
	var footer := HFlowContainer.new()
	footer.add_theme_constant_override("h_separation", 8)
	footer.add_theme_constant_override("v_separation", 8)
	_stack.add_child(footer)
	if not _observed and not _confirming and not _leaving:
		_button(footer, "Undo choices", "UndoChoices", undo)
		_button(footer, "Try it", "TryIt", preview)
		_button(footer, "Lock in", "LockIn", request_commit)
	_button(footer, "Hint", "ProbeHint", reveal_hint)
	_button(footer, "Data cards", "ProbeSources", func(): sources_requested.emit())
	_button(footer, "Close", "CloseProbe", request_close)
	UiDesign.apply_type(_frame, get_viewport_rect().size.y, 1.5 if _settings.get("large_text", false) else 1.0)
	_restore_focus.call_deferred()

func _render_inputs(column: VBoxContainer) -> void:
	match String(_view.get("action", "")):
		"set_zero", "set_span":
			_options(column, "reference", [["dry", "Dry reference"], ["wet", "Wet reference"]])
			_number(column, "raw_reading", "Raw reading", 10)
			_number(column, "calibrated_reading", "Calibrated reading", 10)
		"recheck":
			_number(column, "dry_reading", "Dry reading", 10)
			_number(column, "wet_reading", "Wet reading", 10)
		"plant_alo", "plant_tara":
			_options(column, "cassette", [["alo", "Alo cassette"], ["tara", "Tara cassette"]])
			_number(column, "seed_count", "Seeds to place", 1)
		"label_alo_external", "label_tara_indoor":
			_label(column, "Alo is in the outer test chamber. Tara stays in the indoor reference bay.")
			_options(column, "label", [[_view.profile.labels.alo, "External test"], [_view.profile.labels.tara, "Indoor reference"]])
		"water_alo", "water_tara":
			_label(column, "Calibrated moisture · %s–%s of 100 is safe. Excess can drain to waste." % [_view.profile.moisture_min, _view.profile.moisture_max])
			_number(column, "moisture", "Moisture of 100", 10)
		_:
			_button(column, ("Selected: " if _choices.get("confirmed", false) else "Select: ") + _action_title(), "SelectAction", func(): choose("confirmed", true); _render())

func _options(column: VBoxContainer, field: String, options: Array) -> void:
	for option in options:
		_button(column, ("Selected: " if _choices.get(field) == option[0] else "") + option[1], "Choose_" + option[0], func(): choose(field, option[0]); _render())

func _number(column: VBoxContainer, field: String, title: String, step: float) -> void:
	_label(column, title)
	var row := HBoxContainer.new()
	column.add_child(row)
	_button(row, "−", "Minus_" + field, func(): _adjust(field, -step))
	var entry := LineEdit.new()
	entry.name = "Input_" + field
	entry.placeholder_text = "Not chosen"
	entry.text = str(_choices[field]) if _choices.has(field) else ""
	entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry.custom_minimum_size = Vector2(90, 44)
	entry.accessibility_name = title
	entry.tooltip_text = title + "; type a number or use minus and plus."
	entry.text_changed.connect(func(text): choose(field, text.to_float() if text.is_valid_float() else text))
	row.add_child(entry)
	_button(row, "+", "Plus_" + field, func(): _adjust(field, step))

func _adjust(field: String, amount: float) -> void:
	var value = _choices.get(field)
	choose(field, float(value) + amount if value is float or value is int else 0.0)
	_render()

func _readings(view: Dictionary) -> String:
	var state: Dictionary = view.get("state", {})
	var profile: Dictionary = view.get("profile", _view.profile)
	var complete: Dictionary = view.get("completion", {})
	return "\n".join([
		"Reference targets: dry raw %s ? %s; wet raw %s ? %s." % [profile.references.dry.raw, profile.references.dry.calibrated, profile.references.wet.raw, profile.references.wet.calibrated],
		"Seed packet: " + ("scanned" if state.get("packet_scanned", false) else "not scanned"),
		"Probe: " + ("rechecked" if state.get("probe_rechecked", false) else ("span set" if state.get("probe_spanned", false) else ("zero set" if state.get("probe_zeroed", false) else "not calibrated"))),
		"Alo: %s seed; moisture %s of 100; label: %s; %s" % [state.get("cassette_alo_seed_count", 0), state.get("moisture_alo", 0), _label_text(String(state.get("alo_label", ""))), "sealed" if state.get("alo_sealed", false) else "open"],
		"Tara: %s seed; moisture %s of 100; label: %s; %s" % [state.get("cassette_tara_seed_count", 0), state.get("moisture_tara", 0), _label_text(String(state.get("tara_label", ""))), "sealed" if state.get("tara_sealed", false) else "open"],
		"Paired planting: " + ("complete" if complete.get("complete", false) else "not complete"),
	])

func _label_text(value: String) -> String:
	return {"EXTERNAL_TEST": "External test", "INDOOR_REFERENCE": "Indoor reference"}.get(value, "Not labelled")

func _selection_text() -> String:
	var lines: Array[String] = []
	for field in _choices:
		if field != "confirmed":
			lines.append(field.replace("_", " ").capitalize() + ": " + str(_choices[field]))
	return "\n".join(lines) if not lines.is_empty() else _action_title()

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
	if target == null:
		target = find_child("Choose_dry", true, false) as Control
	if target == null:
		target = find_child("TryIt", true, false) as Control
	if target == null:
		target = find_child("CloseProbe", true, false) as Control
	if target != null:
		target.grab_focus()
	_focus = ""

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
