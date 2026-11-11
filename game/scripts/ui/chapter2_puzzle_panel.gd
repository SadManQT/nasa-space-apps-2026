extends "res://scripts/ui/chapter3_puzzle_panel.gd"
class_name Chapter2PuzzlePanel

## M3-2P: P-03 and P-04 as decision cards at their physical props. The card,
## clues and hints come from the authored content; TRY IT runs the campaign's
## read-only Chapter 2 preview and LOCK IN emits the exact previewed payload,
## which the HUD confirms through confirm_chapter2_choice.

var _campaign: Node

## Opens one Chapter 2 step for the campaign that requested it.
func open_for(campaign: Node, target_id: String, settings: Dictionary = {}) -> void:
	_campaign = campaign
	open(campaign.route, target_id, settings)

func _model() -> RefCounted:
	return _route.chapter2_puzzles()

func _refresh_view() -> void:
	_view = _route.chapter2_view(_target_id)

func try_it() -> Dictionary:
	if _committed():
		return _hold("This step is already locked in.")
	_refresh_view()
	var attempt: Dictionary = _view.get("attempt", {})
	if not bool(attempt.get("accepted", false)):
		_last_try = {"accepted": false, "reason": String(attempt.get("reason", "Finish the decision first.")), "incomplete": true}
		return _hold(String(_last_try.reason))
	var payload: Dictionary = attempt.get("payload", {})
	var local: String = _model().knowledge_check(_target_id)
	var result: Dictionary
	if not local.is_empty():
		result = {"accepted": false, "reason": local}
	elif _campaign == null:
		result = {"accepted": false, "reason": "The Chapter 2 preview is unavailable."}
	else:
		result = _campaign.preview_chapter2_choice(_target_id, payload)
	_last_try = result.duplicate(true)
	_last_try["payload"] = payload.duplicate(true)
	if bool(result.get("accepted", false)):
		_tried_key = _selection_key()
		_last_try["before"] = {"resources": _view.get("resources", {}).duplicate(true)}
		_last_try["after"] = {"resources": result.get("query", {}).get("resources", {}).duplicate(true)}
		_notice = "Accepted. Nothing has changed yet. Read the preview, then lock in with Space."
		_notice_kind = "ok"
		_focus_name = "Commit"
	else:
		_tried_key = ""
		_model().count_attempt(_target_id)
		var reason := String(result.get("reason", "Held."))
		_notice = "Held · " + _model().feedback_for(_target_id, String(attempt.get("option_id", "")), "", reason)
		_notice_kind = "held"
		_focus_name = "Try"
		_offer_first_hint()
	_render()
	return _last_try

func _render_decision() -> Control:
	if String(_view.get("step", {}).get("kind", "")) != "fields":
		return super._render_decision()
	var column := _column("YOUR DECISION", 0)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var step: Dictionary = _view.get("step", {})
	if bool(_view.get("first_time", false)):
		_render_first_time(column)
	var locked := _committed()
	if locked:
		column.add_child(_wrap("✓ LOCKED IN · this step is already recorded. Retry the checkpoint to change it.", 14, GREEN))
	var prerequisite := String(_view.get("prerequisite_reason", ""))
	if not prerequisite.is_empty():
		column.add_child(_wrap("WAITING · " + prerequisite, 14, MUSTARD))
	column.add_child(_wrap(String(step.get("title", "")).to_upper(), 15, CYAN))
	var selection: Dictionary = _view.get("selection", {})
	for field in step.get("fields", {}):
		var spec: Dictionary = step.fields[field]
		column.add_child(_wrap(String(spec.get("label", field)), 13, IVORY))
		var row := HFlowContainer.new()
		row.add_theme_constant_override("h_separation", 6)
		row.add_theme_constant_override("v_separation", 6)
		column.add_child(row)
		for option in spec.get("options", []):
			var id := String(option.get("id", ""))
			var chosen := String(selection.get(field, "")) == id
			var key := String(field)
			row.add_child(_option_button(("● " if chosen else "○ ") + String(option.get("label", id)), "Choice_%s_%s" % [key, id], chosen, locked, func() -> void: choose(key, id)))
	return column
