extends RefCounted
class_name P03Pollination

const SimulationScript = preload("res://scripts/simulation/expedition_simulation.gd")
const StateScript = preload("res://scripts/core/campaign_state.gd")

## P-03 numbers from game-design/08_PUZZLE_DESIGNS.md, held as data. Returns
## {} (and reports why) when the profile file is missing or malformed.
static func profile() -> Dictionary:
	var rules: Dictionary = SimulationScript.load_profile("p03_pollination")
	if rules.is_empty():
		return {}
	var sampled = rules.get("sampled", null)
	var background = rules.get("background", null)
	var problem := ""
	if not sampled is Dictionary or not background is Dictionary:
		problem = "sampled and background ledgers are required"
	elif not sampled.get("dates", null) is Array or sampled.dates.size() != RUN_STEPS.size():
		problem = "one sampled date per reciprocal run is required"
	else:
		for date in sampled.dates + [background.get("end_datetime", null)]:
			if not date is String or not StateScript.is_scenario_datetime(date):
				problem = "ledger dates must be UTC date and minute strings"
		for key in ["daylight_energy", "basic_energy", "full_light_energy", "cycle_energy", "breathing_air", "cycle_air", "health_gain", "crop_gain", "food_consumption"]:
			if not SimulationScript.is_amount(sampled.get(key, null)):
				problem = "sampled." + key + " must be a finite nonnegative number"
		for key in ["supply", "total_consumption"]:
			if not SimulationScript.is_amount(background.get(key, null)):
				problem = "background." + key + " must be a finite nonnegative number"
	if not problem.is_empty():
		push_error("P-03 profile is invalid: " + problem)
		return {}
	return rules

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
		var unsupported := prediction_feedback(payload)
		if not unsupported.is_empty():
			return _reject(unsupported)
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

const CONTENT := "res://resources/campaign/content/p03_pollination.json"

## Empty when every chosen prediction field is a supported option from the
## content file; otherwise that option's feedback (a promised ratio is refused).
static func prediction_feedback(payload: Dictionary) -> String:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(CONTENT)) if FileAccess.file_exists(CONTENT) else null
	var fields: Dictionary = parsed.get("choices", {}).get("prediction", {}).get("fields", {}) if parsed is Dictionary else {}
	if fields.is_empty():
		return "The P-03 prediction options could not be read."
	for field in ["prediction", "reason", "future_test"]:
		var chosen := String(payload.get(field, ""))
		var known := false
		for option in fields.get(field, []):
			if String(option.get("value", "")) == chosen:
				known = true
				if not bool(option.get("correct", false)):
					return String(option.get("feedback", "That claim goes beyond the evidence."))
		if not known:
			return "Choose the %s from the prediction card." % field.replace("_", " ")
	return ""

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
	var version = data.get("schema_version", 0)
	if not (version is int or version is float) or float(version) != 1.0:
		return _reject("P-03 snapshot is incompatible.")
	for key in ["run_index", "step_index"]:
		var value = data.get(key)
		if not (value is int or value is float) or not is_finite(float(value)) or float(value) != floor(float(value)) or float(value) < 0:
			return _reject("P-03 counters must be nonnegative integers.")
	var run := int(data.run_index)
	var step := int(data.step_index)
	if run > RUN_STEPS.size() or step >= (RUN_STEPS.get(run, [""]) as Array).size():
		return _reject("P-03 run/step is outside the sequence.")
	for key in ["care_dates", "completed_actions"]:
		if not data.get(key) is Array:
			return _reject("P-03 lists must be arrays.")
		for value in data[key]:
			if not value is String:
				return _reject("P-03 lists must contain strings.")
	if not data.get("prediction") is Dictionary:
		return _reject("P-03 prediction must be a dictionary.")
	_run_index = run
	_step_index = step
	_care_dates.assign(data.care_dates)
	_prediction = data.prediction.duplicate(true)
	_completed_actions.assign(data.completed_actions)
	return _accept("P-03 restored.")

func _accept(reason: String) -> Dictionary:
	return {"accepted": true, "duplicate": false, "reason": reason}

func _reject(reason: String) -> Dictionary:
	return {"accepted": false, "duplicate": false, "reason": reason}

## Turns a reciprocal-run commit into its sampled daylight-operation ledger
## (FULL light, O0, basics, breathing and the once-per-cycle E1/A1 charge) and
## the stem prediction into the dated background food ledger for the
## seven-day interval. Returns {} when the profile cannot be verified.
func ledger_command(command: Dictionary, state: Dictionary) -> Dictionary:
	var action := String(command.payload.get("_puzzle_action", ""))
	var next := command.duplicate(true)
	if not action.begins_with("p03_complete_run_") and action != "p03_record_prediction":
		return next
	var rules := profile()
	if rules.is_empty():
		return {}
	var sample: Dictionary = rules.sampled
	var deltas := {}
	if action.begins_with("p03_complete_run_"):
		var resources: Dictionary = state.resources
		var charged := minf(float(resources.energy_capacity), float(resources.E) + float(sample.daylight_energy))
		deltas = {
			"E": charged - float(resources.E) - float(sample.basic_energy) - float(sample.full_light_energy) - float(sample.cycle_energy),
			"A": -float(sample.breathing_air) - float(sample.cycle_air),
			"H": float(sample.health_gain),
			"C": float(sample.crop_gain),
			"R": -float(sample.food_consumption),
		}
		next.payload["scenario_datetime"] = sample.dates[_run_index]
	else:
		# Sampled food is already charged; the background ledger adds the planned
		# supply and the unsampled share of the interval's total consumption.
		var sampled_food: float = float(sample.food_consumption) * sample.dates.size()
		deltas["R"] = float(rules.background.supply) - (float(rules.background.total_consumption) - sampled_food)
		next.payload["scenario_datetime"] = rules.background.end_datetime
	next["verb"] = "apply_delta"
	next.payload["deltas"] = deltas
	return next
