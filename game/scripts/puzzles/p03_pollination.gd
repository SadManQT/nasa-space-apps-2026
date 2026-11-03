extends RefCounted
class_name P03Pollination

const RUN_STEPS := {
	0: ["p03_scan_tara", "p03_collect_tara_pollen", "p03_seal_brush_a", "p03_transfer_to_alo", "p03_scan_alo", "p03_collect_alo_pollen", "p03_seal_brush_b", "p03_transfer_to_tara", "p03_complete_run_1"],
	1: ["p03_run_2_forward", "p03_run_2_reverse", "p03_complete_run_2"],
	2: ["p03_run_3_forward", "p03_run_3_reverse", "p03_complete_run_3"],
}

var _run_index := 0
var _step_index := 0
var _care_dates: Array[String] = ["2046-04-30"]
var _prediction := {}
var _completed_actions: Array[String] = []

func preview_action(action: String, payload: Dictionary = {}) -> Dictionary:
	if action in ["p03_record_prediction"]:
		if _run_index < 3 or _care_dates.size() < 7:
			return _reject("Record the three reciprocal runs and seven care dates before the stem prediction.")
		if String(payload.get("prediction", "")).is_empty() or String(payload.get("reason", "")).is_empty() or String(payload.get("future_test", "")).is_empty():
			return _reject("A prediction needs an expectation, a reason and a future comparison criterion.")
		return _accept("Prediction is explicit and remains revisable.")
	if action.begins_with("p03_log_care_day_"):
		var day := int(action.trim_prefix("p03_log_care_day_"))
		if day < 2 or day > 7:
			return _reject("P-03 care visits must use the seven dated campaign days.")
		var date := "2046-05-%02d" % (day - 1)
		if _care_dates.has(date):
			return _reject("This P-03 care date is already recorded.")
		return _accept("Dated care visit is ready to record.")
	var steps: Array = RUN_STEPS.get(_run_index, [])
	if _step_index >= steps.size():
		return _reject("This reciprocal run is already complete.")
	if String(steps[_step_index]) != action:
		return _reject("P-03 sequence requires %s before %s." % [String(steps[_step_index]), action])
	return _accept("P-03 action is in the supported order.")

func commit_action(action: String, payload: Dictionary = {}) -> Dictionary:
	var check := preview_action(action, payload)
	if not bool(check.get("accepted", false)):
		return check
	if action == "p03_record_prediction":
		_prediction = {
			"expectation": String(payload.get("prediction", "")),
			"reason": String(payload.get("reason", "")),
			"future_test": String(payload.get("future_test", "")),
			"recorded_at": String(payload.get("scenario_datetime", "2046-05-06 12:00 UTC")),
		}
		_completed_actions.append(action)
		return _accept("Dated prediction recorded without a guaranteed ratio.")
	if action.begins_with("p03_log_care_day_"):
		var day := int(action.trim_prefix("p03_log_care_day_"))
		_care_dates.append("2046-05-%02d" % (day - 1))
		_care_dates.sort()
		_completed_actions.append(action)
		return _accept("Care date recorded once.")
	_step_index += 1
	_completed_actions.append(action)
	if action in ["p03_complete_run_1", "p03_complete_run_2", "p03_complete_run_3"]:
		_run_index += 1
		_step_index = 0
	return _accept("P-03 action recorded once.")

func flags() -> Dictionary:
	var result := {
		"p03_run_1_complete": _run_index >= 1,
		"p03_run_2_complete": _run_index >= 2,
		"p03_run_3_complete": _run_index >= 3,
		"p03_three_runs": _run_index >= 3,
		"p03_seven_care_dates": _care_dates.size() >= 7,
		"p03_prediction_recorded": not _prediction.is_empty(),
		"p03_complete": _run_index >= 3 and _care_dates.size() >= 7 and not _prediction.is_empty(),
	}
	for action in _completed_actions:
		result[String(action) + "_done"] = true
	return result

func snapshot() -> Dictionary:
	return {"schema_version": 1, "run_index": _run_index, "step_index": _step_index, "care_dates": _care_dates.duplicate(), "prediction": _prediction.duplicate(true), "completed_actions": _completed_actions.duplicate()}

func restore(data: Dictionary) -> Dictionary:
	if not data is Dictionary or int(data.get("schema_version", 1)) != 1:
		return {"accepted": false, "reason": "P-03 snapshot is incompatible."}
	_run_index = clampi(int(data.get("run_index", 0)), 0, 3)
	_step_index = maxi(0, int(data.get("step_index", 0)))
	_care_dates = data.get("care_dates", ["2046-04-30"]).duplicate()
	_prediction = data.get("prediction", {}).duplicate(true)
	_completed_actions = data.get("completed_actions", []).duplicate()
	return {"accepted": true, "reason": "P-03 restored."}

func _accept(reason: String) -> Dictionary:
	return {"accepted": true, "duplicate": false, "reason": reason}

func _reject(reason: String) -> Dictionary:
	return {"accepted": false, "duplicate": false, "reason": reason}
