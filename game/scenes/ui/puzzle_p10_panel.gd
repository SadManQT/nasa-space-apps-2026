extends Control
class_name PuzzleP10Panel

## P-10 — Flashes and a Signature (08 §P-10, 22 §7.3-7.4, UI_09).
##
## Panel contract (like MissionTablePanel / P01Panel):
##   open(model, target_id) -> bool   — model is a P10FlashesSignature;
##     target_id is the catalog action this opening commits
##     ("p10_verify_flashes", "p10_clean_panel", "p10_patch_dome_spur",
##     "p10_verify_pressure", "p10_match_noor_identity",
##     "p10_send_invitation", or any other p10_* action).
##   commit_requested(target_id, payload) — emitted when the player confirms;
##     the caller sends the payload to the route (route.perform) and then
##     calls committed(result).
##   committed(result) — shows the observed result after the route commits.
## The panel never changes campaign resources: tagging candidates, running
## repairs and choosing an invitation only edit the puzzle model's working
## state. Preview ("Try it") and commit share the model's rule function.
## Three stages (25 §6): Learn (compare frames), Apply (two repairs and the
## pressure test), Twist (the signed identity and one invitation). Plain
## words only (25 §1.1). Mistags stay correctable; a hint never changes an
## ending.

const PREDICTION_PROMPT := "Tag the candidates, then try it. Nothing is filed until you lock it in."

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
	_notice = "Compare the frame before and after. A real flash changes; a detector fault stays."
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
	if _target == "p10_verify_flashes":
		_notice = String(_model.clear_tags().get("reason", "Tags cleared."))
	else:
		_choice = {}
		_notice = "Choice cleared. The evidence has not changed."
	_prediction = {}
	_preview_context = ""
	_render()

func _payload_for_target() -> Dictionary:
	match _target:
		"p10_verify_flashes":
			var c: Dictionary = _model.counts()
			return {"genuine": int(c.get("genuine", 0)), "artifacts_rejected": int(c.get("artifacts_rejected", 0))}
		"p10_clean_panel":
			return {"repair": String(_choice.get("repair", ""))}
		"p10_patch_dome_spur":
			return {"repair": String(_choice.get("repair", ""))}
		"p10_match_noor_identity":
			return {"identity": String(_choice.get("identity", ""))}
		"p10_send_invitation":
			return {"invitation": String(_choice.get("invitation", ""))}
		"p10_exclude_unsupported_impact_claim":
			return {"claim": "impact_2034_fault", "column": String(_choice.get("column", ""))}
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
	if not (_model.snapshot().get("tags", {}) as Dictionary).is_empty() and not _observed:
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
	_notice = "Observed: " + String(result.get("reason", "Recorded.")) if _observed else UiDesign.player_words(String(result.get("reason", "Move back to the monitor and try again.")))
	_focus = "ClosePanel" if _observed else "TryIt"
	_render()

func show_result(result: Dictionary) -> void:
	committed(result)

func teach_first_use() -> void:
	if hint_player != null and not hint_player.has_seen("p10"):
		hint_player.set_settings(_settings)
		hint_player.show_how_to("p10", true)

func reveal_hint() -> void:
	_hint_tier = _hint_tier % 3 + 1
	var text := String(_model.hint(_hint_tier))
	if hint_player != null:
		var lesson := {"title": "Flashes and a Signature", "purpose": "Tell a real flash from a detector fault across neighbouring frames.", "steps": ["Compare more than one frame.", "A real flash changes; a detector fault stays.", "Verify six transients, then clean and patch."], "nudge": text}
		hint_player.set_settings(_settings)
		hint_player.request_hint("p10", lesson)
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
	_label(_stack, "Flashes and a Signature", "heading")
	_label(_stack, "Learn: compare frames. Apply: two repairs. Twist: a signed name.", "body")
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
		_label(choices, "Discard these unconfirmed choices? The candidates stay on the monitor.")
		_button(choices, "Keep choosing", "KeepChoosing", func(): _leaving = false; _render())
		_button(choices, "Discard choices and leave", "DiscardChoices", discard)
	elif _confirming:
		_label(choices, "Lock in this step?\n" + _board_text())
		_button(choices, "Confirm choice", "ConfirmChoice", confirm_commit)
		_button(choices, "Back to the board", "BackToBoard", cancel_confirm)
	elif _observed:
		_label(choices, "Step recorded. Close this panel and follow the next goal.")
	else:
		_render_inputs(choices)
	var forecast := _column(columns, "Projected result")
	var projected := _label(forecast, _board_text() if _prediction.get("accepted", false) else PREDICTION_PROMPT)
	projected.name = "PuzzlePrediction"
	_label(forecast, "A real flash changes; a detector fault stays. Two symptoms need two repairs.")
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
		"p10_verify_flashes":
			_label(column, "Learn — ten candidates. Compare the frame before and after, then tag each one.")
			var tags: Dictionary = _model.snapshot().get("tags", {})
			for candidate in data.get("candidates", []):
				var id := String(candidate.get("id", ""))
				var tag := String(tags.get(id, "untagged"))
				_label(column, "%s — %s. Frames: %s. Now: %s." % [candidate.get("label", ""), candidate.get("location", ""), ", ".join((candidate.get("appears_in_frames", []) as Array).map(func(f): return "frame " + str(f))), tag])
				var row := HBoxContainer.new()
				column.add_child(row)
				_button(row, "Flash", "TagFlash_" + id, func(): _tag(id, "flash"))
				_button(row, "Artifact", "TagArtifact_" + id, func(): _tag(id, "artifact"))
			_label(column, "A real flash appears in one frame at a mapped surface location. A detector fault stays on the same detector pixel in every frame.")
		"p10_clean_panel":
			_label(column, "Apply — the panel trend is below its reference. Dust lowers solar income from 8 to 6 until cleaned.")
			_button(column, "Clean the panel", "Repair_clean", func(): _choose("repair", "clean", "Chosen: clean the panel."))
			_button(column, "Verify the Dust Shield instead", "Repair_shield", func(): _choose("repair", "shield", "Chosen: verify the Dust Shield. It prevents the dust event and supplies this verification task instead."))
			_label(column, "Chosen: " + String(_choice.get("repair", "not chosen yet")))
		"p10_patch_dome_spur":
			_label(column, "Apply — a small leak on an isolated branch. Patch it from its safe side; never open the living enclosure.")
			_button(column, "Patch the dome spur from its safe side", "Repair_patch", func(): _choose("repair", "patch", "Chosen: patch the dome spur."))
			_button(column, "Verify the Whipple bumper instead", "Repair_bumper", func(): _choose("repair", "bumper", "Chosen: verify the Whipple bumper. It prevents the leak event and supplies this verification task instead."))
			_label(column, "Chosen: " + String(_choice.get("repair", "not chosen yet")))
		"p10_verify_pressure":
			_label(column, "Apply — verify pressure after the clean and the patch. The test proves both repairs.")
			_label(column, "Panel: " + ("clean" if _model.maintenance_passed() else "not clean yet") + ". Dome spur: " + ("patched" if _model.maintenance_passed() else "not patched yet") + ".")
		"p10_exclude_unsupported_impact_claim":
			_label(column, "Report — what does tonight prove about the 2034 relay failure?")
			_button(column, "File it as Unsupported", "Claim_unsupported", func(): _choose("column", "unsupported", "Chosen: Unsupported. Tonight's flashes do not date the old fault."))
			_button(column, "File it as Supported", "Claim_supported", func(): _choose("column", "supported", "Chosen: Supported."))
		"p10_match_noor_identity":
			_label(column, "Twist — the signed page and the permission note. Who does the signed manifest name?")
			for option in data.get("choices", {}).get("identity", {}).get("options", []):
				_button(column, String(option.get("label", "")), "Identity_" + String(option.get("value", "")), func(): _choose("identity", String(option.get("value", "")), "Chosen: " + String(option.get("label", ""))))
		"p10_send_invitation":
			_label(column, "Twist — one invitation, sent once, with its receipt kept.")
			for option in data.get("choices", {}).get("invitation", {}).get("options", []):
				_button(column, String(option.get("label", "")), "Invite_" + String(option.get("value", "")), func(): _choose("invitation", String(option.get("value", "")), "Chosen: " + String(option.get("label", ""))))
		_:
			_label(column, "Confirm this step. The board shows what it needs.")
			_button(column, "Confirm: " + _target.replace("_", " "), "ConfirmStep", func(): _choose("confirmed", true, "Ready to confirm this step."))

func _choose(field: String, value, notice: String) -> void:
	_choice[field] = value
	_notice = notice
	_prediction = {}
	_preview_context = ""
	_render()

func _tag(candidate_id: String, tag: String) -> void:
	var result: Dictionary = _model.tag_candidate(candidate_id, tag)
	_notice = String(result.get("reason", ""))
	_prediction = {}
	_preview_context = ""
	_render()

func _observed_text() -> String:
	var snapshot: Dictionary = _model.snapshot()
	var c: Dictionary = _model.counts()
	var forecast: Dictionary = _model.forecast(false)
	var resources: Dictionary = snapshot.get("resources", {})
	var lines: Array[String] = []
	lines.append("Candidates: 10 on the monitor — 8 genuine flashes, 2 fixed artifacts.")
	lines.append("Tagged: %d flashes, %d artifacts, %d false reports." % [c.get("genuine", 0), c.get("artifacts_rejected", 0), c.get("false_reports", 0)])
	lines.append("Maintenance: panel %s, dome spur %s, pressure %s." % ["clean" if bool(snapshot.get("cleaned", false)) or bool(snapshot.get("shield_verified", false)) else "not done", "patched" if bool(snapshot.get("patched", false)) or bool(snapshot.get("bumper_verified", false)) else "not done", "verified" if bool(snapshot.get("pressure_verified", false)) else "not verified"])
	lines.append("Phases sampled: %d of 3. Battery %s, air %s, food %s." % [snapshot.get("phases_done", 0), resources.get("E", ""), resources.get("A", ""), resources.get("R", "")])
	lines.append("Forecast with immediate repairs: battery %s, air %s, food %s." % [forecast.get("E", ""), forecast.get("A", ""), forecast.get("R", "")])
	lines.append("Identity: " + ("Dr. Noor Rahman, matched." if bool(snapshot.get("identity_matched", false)) else "not matched yet."))
	return "\n".join(lines)

func _board_text() -> String:
	var snapshot: Dictionary = _model.snapshot()
	var c: Dictionary = _model.counts()
	var lines: Array[String] = []
	match _target:
		"p10_verify_flashes":
			lines.append("Verify: %d genuine flashes, %d artifacts rejected, %d false reports." % [c.get("genuine", 0), c.get("artifacts_rejected", 0), c.get("false_reports", 0)])
			if _model.golden():
				lines.append("Golden observation: all eight flashes, no false report.")
		"p10_match_noor_identity":
			lines.append("Identity: Dr. Noor Rahman, from the signed page.")
		"p10_send_invitation":
			lines.append("Invitation: " + String(snapshot.get("invitation", "not chosen")))
		_:
			lines.append("Step: " + _target)
			lines.append("Maintenance passed: " + ("yes" if _model.maintenance_passed() else "not yet"))
			lines.append("Phases sampled: %d of 3." % snapshot.get("phases_done", 0))
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
		target = find_child("TagFlash_F1", true, false) as Control
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
