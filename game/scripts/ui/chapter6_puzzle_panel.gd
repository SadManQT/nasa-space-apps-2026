extends "res://scripts/ui/chapter8_puzzle_panel.gd"
class_name Chapter6PuzzlePanel

## The Chapter 6 puzzle panel: P-11 Protect the Small Light and P-12 Observe,
## Isolate, Restore, one operation at a time. Reuses Chapter8PuzzlePanel's
## 3-column Clues / Decision / Preview layout, accessibility scaling, hints and
## Go/No-Go poll, bound to `route.chapter6()`, `route.chapter6_view()` and
## `route.chapter6_preview()`.

const Ch6PuzzleScript = preload("res://scripts/puzzles/chapter6_puzzles.gd")

func _model() -> RefCounted:
	return _route.chapter6()

func _refresh_view() -> void:
	_view = _route.chapter6_view(_target_id)

func try_it() -> Dictionary:
	if _committed():
		return _hold("This step is already locked in.")
	_refresh_view()
	var attempt: Dictionary = _view.get("attempt", {})
	if not bool(attempt.get("accepted", false)):
		_last_try = {"accepted": false, "reason": String(attempt.get("reason", "")), "incomplete": true}
		_notice = String(attempt.get("reason", "Finish the decision first."))
		_notice_kind = "held"
		_render()
		return _last_try
	var payload: Dictionary = attempt.get("payload", {})
	var result: Dictionary = _route.chapter6_preview(_target_id, payload)
	_last_try = result.duplicate(true)
	_last_try["payload"] = payload.duplicate(true)
	if bool(result.get("accepted", false)):
		_tried_key = _selection_key()
		var advisory: String = _model().advisory_for(_target_id, String(attempt.get("option_id", "")))
		_notice = ("Accepted with an advisory: " + advisory) if not advisory.is_empty() else "Accepted. Nothing has changed yet. Read the preview, then lock in with Space."
		_notice_kind = "advisory" if not advisory.is_empty() else "ok"
		_focus_name = "Commit"
	else:
		_tried_key = ""
		_model().count_attempt(_target_id)
		var reason := String(result.get("reason", "Held."))
		var feedback: String = _model().feedback_for(_target_id, String(attempt.get("option_id", "")), String(attempt.get("feedback_key", "")), reason)
		_notice = "Held · " + feedback + ("" if feedback == reason or bool(result.get("unmet", false)) else "  (" + reason + ")")
		_notice_kind = "held"
		_focus_name = "Try"
		_offer_first_hint()
	_render()
	return _last_try

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
				return "%s has not signed the poll yet." % String(Ch6PuzzleScript.role(String(role_id)).get("name", role_id))
	return ""
