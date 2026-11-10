extends Control
class_name PuzzleP09Panel

## P-09 — Reconstruct the Departure (08 §P-09, 22 §7.1, UI_09).
##
## Panel contract (like MissionTablePanel / P01Panel):
##   open(model, target_id) -> bool   — model is a P09DepartureReconstruction;
##     target_id is the catalog action, normally "p09_commit_sequence".
##   commit_requested(target_id, payload) — emitted when the player confirms;
##     the caller sends the payload to the route (route.perform) and then
##     calls committed(result).
##   committed(result) — shows the observed result after the route commits.
## The panel never changes campaign resources: placing cards, matching
## signatures and choosing a conclusion only edit the puzzle model's working
## board. Preview ("Try it") and commit share the model's rule function.
## Layout follows UI_09: observed data left, choices centre, projected
## result right; Undo / Try it / Lock in / Hint / Data cards / Close below.
## Plain words only (25 §1.1): no puzzle codes or single-letter variables in
## player text. First-time length target 8–15 minutes (25 §6).

const PREDICTION_PROMPT := "Choose your order, then try it. The records stay on the table until you lock them in."

signal opened(target_id: String)
signal closed(target_id: String)
signal commit_requested(target_id: String, payload: Dictionary)
signal sources_requested

var hint_player: HintPlayer
var _model: RefCounted
var _target := ""
var _prediction: Dictionary = {}
var _preview_context := ""
var _confirming := false
var _leaving := false
var _observed := false
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
	if model == null or not model.has_method("preview_commit"):
		return false
	_return_focus = get_viewport().gui_get_focus_owner()
	_model = model
	_target = target_id
	_prediction = {}
	_preview_context = ""
	_confirming = false
	_leaving = false
	_observed = false
	_notice = "Place the four records in time order, match the signatures, and choose what the boarding evidence supports."
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
	_notice = String(_model.reset().get("reason", "Choices cleared."))
	_prediction = {}
	_preview_context = ""
	_render()

func preview() -> Dictionary:
	_prediction = _model.preview_commit()
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
	var payload: Dictionary = _model.gate_payload()
	var target := _target
	discard()
	commit_requested.emit(target, payload)
	return {"accepted": true}

func cancel_confirm() -> void:
	_confirming = false
	_focus = "LockIn"
	_render()

func request_close() -> void:
	if not _model.snapshot().get("placed", []).is_empty() and not _observed:
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
	_notice = "Observed: the departure sequence is committed. All four returned; the garden was left, not a person." if _observed else UiDesign.player_words(String(result.get("reason", "Move back to the table and try again.")))
	_focus = "ClosePanel" if _observed else "TryIt"
	_render()

func show_result(result: Dictionary) -> void:
	committed(result)

func teach_first_use() -> void:
	if hint_player != null and not hint_player.has_seen("p09"):
		hint_player.set_settings(_settings)
		hint_player.show_how_to("p09", true)

func reveal_hint() -> void:
	_hint_tier = _hint_tier % 3 + 1
	var text := String(_model.hint(_hint_tier))
	if hint_player != null:
		var lesson := {"title": "Reconstruct the Departure", "purpose": "Put four records in time order and let the boarding list settle the human question.", "steps": ["Use the timestamps.", "Boarding happened after the retreat order.", "All four signatures boarded."], "nudge": text}
		hint_player.set_settings(_settings)
		hint_player.request_hint("p09", lesson)
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
	_label(_stack, "Reconstruct the Departure", "heading")
	_label(_stack, "Four records, two signatures, one supported conclusion.", "body")
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
		_label(choices, "Discard these unconfirmed choices? The records will stay on the table.")
		_button(choices, "Keep choosing", "KeepChoosing", func(): _leaving = false; _render())
		_button(choices, "Discard choices and leave", "DiscardChoices", discard)
	elif _confirming:
		_label(choices, "Lock in this board?\n" + _board_text())
		_button(choices, "Confirm choice", "ConfirmChoice", confirm_commit)
		_button(choices, "Back to the board", "BackToBoard", cancel_confirm)
	elif _observed:
		_label(choices, "Sequence committed. Close this panel and follow the next goal.")
	else:
		_render_inputs(choices)
	var forecast := _column(columns, "Projected result")
	var projected := _label(forecast, _board_text() if _prediction.get("accepted", false) else PREDICTION_PROMPT)
	projected.name = "PuzzlePrediction"
	_label(forecast, "A condition is not the failure time. The garden was left; the gardener was not.")
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
	_label(column, "Chronology board — tap a record to place it next, tap again to lift it.")
	var placed: Array = _model.snapshot().get("placed", [])
	for card in data.get("cards", []):
		var id := String(card.get("card_id", ""))
		var on_board := placed.has(id)
		var text := ("Placed %d: " % (placed.find(id) + 1) if on_board else "") + "%s — %s" % [card.get("label", ""), card.get("time_text", "")]
		_button(column, text, "Place_" + id, func(): _place_card(id))
	_label(column, "Signatures on the ascent manifest.")
	_button(column, "FER points to Ferreira", "Sign_FER", func(): _match("FER", "ferreira"))
	_button(column, "N.R. points to the gardener (initials only)", "Sign_NR", func(): _match("N.R.", "gardener"))
	_label(column, "Forecast — who is in the station now?")
	_button(column, "Four people, as before", "Roster_4", func(): _roster(4))
	_button(column, "Five people, counting Ferreira", "Roster_5", func(): _roster(5))
	_label(column, "Conclusion — what does the boarding evidence support?")
	for option in data.get("choices", {}).get("conclusion", {}).get("options", []):
		_button(column, String(option.get("label", "")), "Conclusion_" + String(option.get("value", "")), func(): _conclude(String(option.get("value", ""))))

func _place_card(card_id: String) -> void:
	var placed: Array = _model.snapshot().get("placed", [])
	var result: Dictionary = _model.remove_card(card_id) if placed.has(card_id) else _model.place_card(card_id)
	_notice = String(result.get("reason", ""))
	_prediction = {}
	_preview_context = ""
	_render()

func _match(signature: String, person: String) -> void:
	var result: Dictionary = _model.match_signature(signature, person)
	_notice = String(result.get("reason", ""))
	_prediction = {}
	_preview_context = ""
	_render()

func _roster(count: int) -> void:
	var result: Dictionary = _model.verify_roster(count)
	_notice = String(result.get("reason", ""))
	if bool(result.get("accepted", false)):
		var forecast: Dictionary = _model.forecast(count)
		_notice += " Air %s and food %s per shift." % [forecast.get("air_per_shift", ""), forecast.get("food_per_shift", "")]
	_prediction = {}
	_preview_context = ""
	_render()

func _conclude(value: String) -> void:
	var result: Dictionary = _model.select_conclusion(value)
	_notice = String(result.get("reason", ""))
	_prediction = {}
	_preview_context = ""
	_render()

func _observed_text() -> String:
	var data: Dictionary = _model.data()
	var lines: Array[String] = []
	for card in data.get("cards", []):
		lines.append("%s — %s." % [card.get("label", ""), card.get("time_text", "")])
	lines.append("Signatures highlighted: FER and N.R.")
	lines.append("Crew: 4 departed, 4 boarded.")
	lines.append("A photograph of frozen trays: a consequence that cannot date the fault.")
	return "\n".join(lines)

func _board_text() -> String:
	var snapshot: Dictionary = _model.snapshot()
	var placed: Array = snapshot.get("placed", [])
	var order: Array[String] = []
	for id in placed:
		order.append(_card_label(String(id)))
	var lines: Array[String] = []
	lines.append("Board order: " + (" → ".join(order) if not order.is_empty() else "empty"))
	lines.append("Signatures matched: %d of 2." % (snapshot.get("signatures", {}) as Dictionary).size())
	lines.append("Forecast counts: %s people." % snapshot.get("roster_occupants", 0))
	lines.append("Conclusion: " + String(snapshot.get("conclusion", "not chosen")))
	return "\n".join(lines)

func _card_label(card_id: String) -> String:
	for card in _model.data().get("cards", []):
		if String(card.get("card_id", "")) == card_id:
			return String(card.get("label", card_id))
	return card_id

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
		target = find_child("Place_seedling_chart", true, false) as Control
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
