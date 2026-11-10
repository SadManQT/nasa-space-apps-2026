extends "res://scripts/ui/chapter8_puzzle_panel.gd"
class_name Chapter3PuzzlePanel

## P-05 and P-06 share the campaign's clues / decision / read-only preview
## layout. Every payload comes from a choice or instrument value the player set.
## The route methods below are the Chapter 3 hookup contract.

func _model() -> RefCounted:
	return _route.p05() if _target_id.begins_with("p05_") else _route.p06()

func _refresh_view() -> void:
	_view = _route.chapter3_view(_target_id)

func sign(role_id: String) -> Dictionary:
	if _tried_key.is_empty() or _tried_key != _selection_key() or not bool(_last_try.get("accepted", false)):
		return _hold("Try and review this exact decision before signing the team poll.")
	return super.sign(role_id)

func try_it() -> Dictionary:
	if _committed():
		return _hold("This step is already locked in.")
	_refresh_view()
	var attempt: Dictionary = _view.get("attempt", {})
	if not bool(attempt.get("accepted", false)):
		_last_try = {"accepted": false, "reason": String(attempt.get("reason", "Finish the decision first.")), "incomplete": true}
		_notice = String(_last_try.reason)
		_notice_kind = "held"
		_render()
		return _last_try
	var payload: Dictionary = attempt.get("payload", {})
	var result: Dictionary = _route.chapter3_preview(_target_id, payload)
	_last_try = result.duplicate(true)
	_last_try["payload"] = payload.duplicate(true)
	if bool(result.get("accepted", false)):
		_tried_key = _selection_key()
		var advisory: String = _model().advisory_for(_target_id, String(attempt.get("option_id", "")))
		_notice = "Accepted. Nothing has changed yet. Read the preview, then lock in with Space." if advisory.is_empty() else "Accepted with an advisory: " + advisory
		_notice_kind = "ok" if advisory.is_empty() else "advisory"
		_focus_name = "Commit"
	else:
		_tried_key = ""
		_model().count_attempt(_target_id)
		var reason := String(result.get("reason", "Held."))
		var feedback: String = _model().feedback_for(_target_id, String(attempt.get("option_id", "")), String(attempt.get("feedback_key", "")), reason)
		_notice = "Held: " + feedback
		_notice_kind = "held"
		_focus_name = "Try"
		_offer_first_hint()
	_render()
	return _last_try

func _render_number(column: VBoxContainer, step: Dictionary, locked: bool) -> void:
	var bounds: Dictionary = step.get("number", {})
	var selection: Dictionary = _view.get("selection", {})
	column.add_child(_wrap(String(step.get("formula", "")), 12, MUTED))
	var chosen = selection.get("value", null)
	for raw in bounds.get("samples", []):
		var value := int(raw)
		var selected := chosen != null and int(chosen) == value
		column.add_child(_option_button(("Selected: " if selected else "Read: ") + str(value) + " " + String(bounds.get("unit", "")), "Choice_value_%d" % value, selected, locked, func() -> void: choose("value", value)))
	_render_stepper(column, String(bounds.get("label", "Reading")), "value", selection.get("value", null), bounds, String(bounds.get("unit", "")), locked)

## Chapter 3 decisions affect the station, air and founder seeds. Keep the
## shared preview layout but show only the values this route actually projects.
func _render_before_after(column: VBoxContainer, before: Dictionary, after: Dictionary) -> void:
	var old_resources: Dictionary = before.get("resources", {})
	var new_resources: Dictionary = after.get("resources", {})
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	column.add_child(grid)
	for row in [["E", "Battery"], ["A", "Air"], ["H", "Garden health"], ["C", "Crop"], ["R", "Food (crew-days)"]]:
		var key := String(row[0])
		if not old_resources.has(key) or not new_resources.has(key):
			continue
		var old_value := float(old_resources[key])
		var new_value := float(new_resources[key])
		grid.add_child(_label(String(row[1]), 12, MUTED))
		grid.add_child(_label("%s  →  %s  (%s)" % [_amount(old_value), _amount(new_value), _signed(new_value - old_value)], 12, IVORY if is_equal_approx(old_value, new_value) else (GREEN if new_value > old_value else MUSTARD)))
	var old_inventory: Dictionary = before.get("inventories", {})
	var new_inventory: Dictionary = after.get("inventories", {})
	for row in [["allocated12", "Seeds for planting"], ["reserve30", "Protected founder seeds"]]:
		var key := String(row[0])
		if old_inventory.has(key) and new_inventory.has(key):
			grid.add_child(_label(String(row[1]), 12, MUTED))
			grid.add_child(_label("%s  →  %s" % [str(old_inventory[key]), str(new_inventory[key])], 12, IVORY))

func _render_confirmation() -> void:
	var step: Dictionary = _view.get("step", {})
	var box := _card_box(false, true)
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_child(box)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 8)
	box.add_child(inner)
	inner.add_child(_wrap("LOCK IN · " + String(step.get("title", "")).to_upper(), 20, MUSTARD))
	inner.add_child(_wrap("This records the checked decision. RETRY restores the checkpoint before it.", 15, IVORY))
	inner.add_child(_wrap("Decision: " + _payload_sentence(_last_try.get("payload", {})), 14, CYAN))
	var before: Dictionary = _last_try.get("before", {})
	var after: Dictionary = _last_try.get("after", {})
	if not before.is_empty() and not after.is_empty():
		inner.add_child(_wrap("Projected station state after confirmation:", 13, IVORY))
		_render_before_after(inner, before, after)
	var statuses: Array = _model().poll_status(_target_id, true, "", String(_notice.trim_prefix("Accepted with an advisory: ")) if _notice_kind == "advisory" else "")
	var poll: Array = []
	for status in statuses:
		poll.append("%s: %s" % [String(status.name), String(status.status)])
	if not poll.is_empty():
		inner.add_child(_wrap("Poll · " + " · ".join(poll), 13, GREEN))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 8)
	_content.add_child(row)
	var back := _button("BACK · ESC", "CancelCommit")
	back.pressed.connect(cancel_confirm)
	row.add_child(back)
	var confirm := _button("CONFIRM · SPACE", "ConfirmCommit")
	confirm.pressed.connect(func() -> void: confirm_commit())
	row.add_child(confirm)

func _commit_reason() -> String:
	if _view.is_empty():
		_refresh_view()
	if bool(_view.get("committed", false)):
		return "This step is already locked in."
	var prerequisite := String(_view.get("prerequisite_reason", ""))
	if not prerequisite.is_empty():
		return prerequisite
	var attempt: Dictionary = _view.get("attempt", {})
	if not bool(attempt.get("accepted", false)):
		return String(attempt.get("reason", "Finish the decision first."))
	if _tried_key.is_empty() or _tried_key != _selection_key():
		return "Press TRY IT to check this decision before locking it in."
	if bool(_settings.get("class_mode", false)):
		for role_id in _view.get("step", {}).get("poll", []):
			if not (_view.get("signed", []) as Array).has(role_id):
				return "%s has not signed the poll yet." % String(_model().role(String(role_id)).get("name", role_id))
	return ""
