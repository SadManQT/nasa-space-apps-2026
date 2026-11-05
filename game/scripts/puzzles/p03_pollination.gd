extends RefCounted
class_name P03Pollination

## Interactive rule and state model for Chapter 2 Puzzle P-03 (Alo Meets Tara).
## All structures, brushes, carrier modes, care dates, stem-colour prediction
## options, clues, and progressive hints live in
## res://resources/campaign/content/p03_pollination.json; numeric simulation
## deltas live in res://resources/campaign/profiles/p03_pollination.json.

const SimulationScript = preload("res://scripts/simulation/expedition_simulation.gd")
const CONTENT_PATH := "res://resources/campaign/content/p03_pollination.json"

const RUN_STEPS := {
	0: ["p03_scan_tara", "p03_collect_tara_pollen", "p03_seal_brush_a", "p03_transfer_to_alo", "p03_scan_alo", "p03_collect_alo_pollen", "p03_seal_brush_b", "p03_transfer_to_tara", "p03_complete_run_1"],
	1: ["p03_run_2_forward", "p03_run_2_reverse", "p03_complete_run_2"],
	2: ["p03_run_3_forward", "p03_run_3_reverse", "p03_complete_run_3"],
}

static var _content_cache: Dictionary = {}

var _run_index := 0
var _step_index := 0
var _care_dates: Array[int] = [1]
var _prediction: Dictionary = {}
var _flags: Dictionary = {}

var _weather_mode := ""
var _carrier_mode := ""
var _donor_id := ""
var _source_structure := ""
var _brush_id := ""
var _recipient_id := ""
var _target_structure := ""
var _brush_dirty: Dictionary = {"A": false, "B": false}
var _brush_pollen: Dictionary = {"A": "", "B": ""}
var _contaminated_transfer := false
var _care_draft: Dictionary = {}
var _draft_prediction: Dictionary = {"prediction": "", "reason": "", "future_test": ""}
var _shared_clues: Array[String] = []
var _hint_tier: Dictionary = {"pollination": 0, "prediction": 0}
var _last_feedback := ""
var _worked_plan_active := false

## Loads the P-03 interactive content definition from JSON.
static func data() -> Dictionary:
	if _content_cache.is_empty():
		var file := FileAccess.open(CONTENT_PATH, FileAccess.READ)
		if file != null:
			var parsed = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				_content_cache = parsed
	return _content_cache.duplicate(true)

## Loads and validates the numeric P-03 simulation profile.
static func profile() -> Dictionary:
	var rules: Dictionary = SimulationScript.load_profile("p03_pollination")
	var valid := _validate_profile(rules)
	return rules if bool(valid.get("accepted", false)) else {}

## Returns true when `action` belongs to P-03.
static func is_p03_action(action: String) -> bool:
	return action.begins_with("p03_")

## Selects the space-weather verification mode (`go_checked` or `skip_check`).
func select_weather_mode(mode_id: String) -> Dictionary:
	_weather_mode = mode_id.strip_edges()
	var opt := _find_item("weather_modes", _weather_mode)
	if opt.is_empty():
		_last_feedback = "Choose a valid space-weather check option."
		return _reject(_last_feedback)
	_last_feedback = String(opt.get("feedback", ""))
	return {"accepted": bool(opt.get("valid", false)), "reason": _last_feedback, "weather_mode": _weather_mode, "scientific_puzzle": true}

## Selects the brush carrier and pressure-boundary mode (`sealed_interlock`, `open_carrier`, or `join_chambers`).
func select_carrier_mode(mode_id: String) -> Dictionary:
	_carrier_mode = mode_id.strip_edges()
	var opt := _find_item("carrier_modes", _carrier_mode)
	if opt.is_empty():
		_last_feedback = "Choose how the brush carrier crosses the pressure boundary."
		return _reject(_last_feedback)
	_last_feedback = String(opt.get("feedback", ""))
	return {"accepted": bool(opt.get("valid", false)), "reason": _last_feedback, "carrier_mode": _carrier_mode, "scientific_puzzle": true}

## Selects the donor plant (`TARA-01` or `ALO-01`).
func select_donor(plant_id: String) -> Dictionary:
	var plants: Dictionary = data().get("plants", {})
	if not plants.has(plant_id):
		_last_feedback = "Select either Tara (TARA-01) or Alo (ALO-01) as the donor plant."
		return _reject(_last_feedback)
	_donor_id = plant_id
	var plant: Dictionary = plants[plant_id]
	_last_feedback = "Selected %s in %s as pollen donor." % [plant.get("label", plant_id), plant.get("chamber", "")]
	return {"accepted": true, "reason": _last_feedback, "donor_id": _donor_id, "scientific_puzzle": true}

## Selects the donor flower structure (`anther`, `petal`, or `stigma`).
func select_source_structure(structure_id: String) -> Dictionary:
	_source_structure = structure_id.strip_edges()
	var opt := _find_item("structures", _source_structure)
	if opt.is_empty():
		_last_feedback = "Select a flower structure on the donor plant."
		return _reject(_last_feedback)
	_last_feedback = String(opt.get("feedback", ""))
	if not bool(opt.get("valid_collect", false)):
		return {"accepted": false, "reason": _last_feedback, "source_structure": _source_structure, "scientific_puzzle": true}
	return {"accepted": true, "reason": _last_feedback, "source_structure": _source_structure, "scientific_puzzle": true}

## Selects the pollination brush (`A`, `B`, or `UNLABELLED`).
func select_brush(brush_id: String) -> Dictionary:
	_brush_id = brush_id.strip_edges()
	var opt := _find_item("brushes", _brush_id)
	if opt.is_empty():
		_last_feedback = "Select Brush A (Tara -> Alo) or Brush B (Alo -> Tara)."
		return _reject(_last_feedback)
	if not bool(opt.get("valid", false)):
		_last_feedback = String(opt.get("feedback", ""))
		return {"accepted": false, "reason": _last_feedback, "brush_id": _brush_id, "scientific_puzzle": true}
	if bool(_brush_dirty.get(_brush_id, false)):
		_last_feedback = String(data().get("feedback_messages", {}).get("dirty_brush", "Replace the dirty brush tip before collecting pollen."))
		return {"accepted": false, "reason": _last_feedback, "brush_id": _brush_id, "brush_dirty": true, "scientific_puzzle": true}
	_last_feedback = String(opt.get("feedback", ""))
	return {"accepted": true, "reason": _last_feedback, "brush_id": _brush_id, "scientific_puzzle": true}

## Replaces a brush tip with a fresh sterile tip (unlimited clean tips).
func replace_brush_tip(brush_id: String) -> Dictionary:
	var key := brush_id.strip_edges()
	if key not in ["A", "B"]:
		return _reject("Choose Brush A or Brush B to replace its sterile tip.")
	_brush_dirty[key] = false
	_brush_pollen[key] = ""
	_last_feedback = "Replaced Brush %s with a fresh sterile tip." % key
	return {"accepted": true, "reason": _last_feedback, "brush_id": key, "brush_dirty": false, "scientific_puzzle": true}

## Marks a brush tip dirty (for example after touching the wrong donor or an unsealed surface).
func mark_brush_dirty(brush_id: String, reason: String = "") -> Dictionary:
	var key := brush_id.strip_edges()
	if key not in ["A", "B"]:
		return _reject("Unknown brush identifier.")
	_brush_dirty[key] = true
	_last_feedback = reason if not reason.is_empty() else String(data().get("feedback_messages", {}).get("dirty_brush", "Brush tip is dirty; replace the tip before collecting."))
	return {"accepted": true, "reason": _last_feedback, "brush_id": key, "brush_dirty": true, "scientific_puzzle": true}

## Selects the recipient plant (`ALO-01` or `TARA-01`).
func select_recipient(plant_id: String) -> Dictionary:
	var plants: Dictionary = data().get("plants", {})
	if not plants.has(plant_id):
		_last_feedback = "Select either Alo (ALO-01) or Tara (TARA-01) as the recipient plant."
		return _reject(_last_feedback)
	_recipient_id = plant_id
	if not _donor_id.is_empty() and _recipient_id == _donor_id:
		_last_feedback = String(data().get("feedback_messages", {}).get("self_pollination", "Brassica rapa is self-incompatible; choose the partner plant."))
		return {"accepted": false, "reason": _last_feedback, "recipient_id": _recipient_id, "scientific_puzzle": true}
	var plant: Dictionary = plants[plant_id]
	_last_feedback = "Selected %s in %s as pollen recipient." % [plant.get("label", plant_id), plant.get("chamber", "")]
	return {"accepted": true, "reason": _last_feedback, "recipient_id": _recipient_id, "scientific_puzzle": true}

## Selects the recipient flower structure (`stigma`, `petal`, or `anther`).
func select_target_structure(structure_id: String) -> Dictionary:
	_target_structure = structure_id.strip_edges()
	var opt := _find_item("structures", _target_structure)
	if opt.is_empty():
		_last_feedback = "Select a target structure on the recipient flower."
		return _reject(_last_feedback)
	if not bool(opt.get("valid_transfer", false)):
		_last_feedback = String(data().get("feedback_messages", {}).get("petal_selected", String(opt.get("feedback", ""))))
		return {"accepted": false, "reason": _last_feedback, "target_structure": _target_structure, "scientific_puzzle": true}
	_last_feedback = String(opt.get("feedback", ""))
	return {"accepted": true, "reason": _last_feedback, "target_structure": _target_structure, "scientific_puzzle": true}

## Checks or unchecks a dated care visit (Days 2..7) in the interactive logbook.
func toggle_care_day(day: int, checked: bool = true) -> Dictionary:
	if day < 1 or day > 7:
		return _reject("Care visits are numbered Day 1 through Day 7.")
	_care_draft[str(day)] = checked
	_last_feedback = "Care log Day %d/7 marked %s." % [day, "ready" if checked else "unchecked"]
	return {"accepted": true, "reason": _last_feedback, "day": day, "checked": checked, "scientific_puzzle": true}

## Selects one of the three pre-registered stem-colour prediction fields (`prediction`, `reason`, `future_test`).
func select_prediction_field(field: String, value: String) -> Dictionary:
	var group_key: String = {"prediction": "expectations", "reason": "reasons", "future_test": "future_tests"}.get(field, "")
	if group_key.is_empty():
		return _reject("Unknown prediction field.")
	var options: Array = data().get("prediction_options", {}).get(group_key, [])
	var chosen := value.strip_edges()
	_draft_prediction[field] = chosen
	for item in options:
		if item is Dictionary and (String(item.get("value", "")) == chosen or String(item.get("id", "")) == chosen):
			_draft_prediction[field] = String(item.get("value", chosen))
			_last_feedback = String(item.get("feedback", ""))
			return {
				"accepted": bool(item.get("valid", false)),
				"reason": _last_feedback,
				"field": field,
				"value": _draft_prediction[field],
				"scientific_puzzle": true,
			}
	_last_feedback = "Select a documented option for %s." % field
	return {"accepted": false, "reason": _last_feedback, "field": field, "value": chosen, "scientific_puzzle": true}

## Shares a crew clue card in Class mode (`P03-C1`..`P03-C4`).
func share_clue(clue_id: String) -> Dictionary:
	var clues: Array = data().get("clues", [])
	for item in clues:
		if item is Dictionary and String(item.get("id", "")) == clue_id:
			if not _shared_clues.has(clue_id):
				_shared_clues.append(clue_id)
			_last_feedback = "Shared clue %s (%s)." % [clue_id, item.get("label", "")]
			return {"accepted": true, "reason": _last_feedback, "shared_clues": _shared_clues.duplicate(), "scientific_puzzle": true}
	return _reject("Unknown P-03 clue ID.")

## Reveals the next progressive hint tier (1..3) for `pollination` or `prediction` without solving the puzzle.
func next_hint(topic: String = "pollination") -> Dictionary:
	var key := "prediction" if topic == "prediction" else "pollination"
	var all_hints: Array = data().get("hints", {}).get(key, [])
	var tier := mini(int(_hint_tier.get(key, 0)) + 1, all_hints.size())
	_hint_tier[key] = tier
	var revealed := hints_for(key)
	var latest: String = String(revealed.back()) if not revealed.is_empty() else ""
	_last_feedback = "Hint %d/%d: %s" % [tier, all_hints.size(), latest]
	return {"accepted": true, "topic": key, "tier": tier, "max_tier": all_hints.size(), "hint": latest, "hints": revealed, "scientific_puzzle": true}

## Returns the currently revealed hints for `pollination` or `prediction`.
func hints_for(topic: String = "pollination") -> Array:
	var key := "prediction" if topic == "prediction" else "pollination"
	var all_hints: Array = data().get("hints", {}).get(key, [])
	var tier := clampi(int(_hint_tier.get(key, 0)), 0, all_hints.size())
	return all_hints.slice(0, tier)

## Resets uncommitted workbench or prediction selections for the current step without losing completed steps.
func reset_current_step() -> Dictionary:
	_weather_mode = ""
	_carrier_mode = ""
	_donor_id = ""
	_source_structure = ""
	_brush_id = ""
	_recipient_id = ""
	_target_structure = ""
	_brush_dirty = {"A": false, "B": false}
	_brush_pollen = {"A": "", "B": ""}
	if _prediction.is_empty():
		_draft_prediction = {"prediction": "", "reason": "", "future_test": ""}
	_worked_plan_active = false
	_last_feedback = "Current step choices reset; completed pollination runs and care logs remain intact."
	return {"accepted": true, "reason": _last_feedback, "scientific_puzzle": true}

## Configures the workbench selections required for a single P-03 action using the JSON specification.
func configure_for_action(action: String) -> Dictionary:
	var content := data()
	if action == "p03_record_prediction":
		var pred_opts: Dictionary = content.get("prediction_options", {})
		for field_map in [["prediction", "expectations"], ["reason", "reasons"], ["future_test", "future_tests"]]:
			for item in pred_opts.get(field_map[1], []):
				if item is Dictionary and bool(item.get("valid", false)):
					_draft_prediction[field_map[0]] = String(item.get("value", ""))
					break
		_last_feedback = "Configured valid stem-colour prediction options."
		return {"accepted": true, "reason": _last_feedback, "payload": payload_for_action(action)}
	if action.begins_with("p03_log_care_day_"):
		var day := int(action.trim_prefix("p03_log_care_day_"))
		_care_draft[str(day)] = true
		_last_feedback = "Marked care visit Day %d/7 in the logbook." % day
		return {"accepted": true, "reason": _last_feedback, "payload": payload_for_action(action)}
	var req: Dictionary = content.get("step_requirements", {}).get(action, {})
	if req.is_empty():
		return _reject("No step configuration found for " + action)
	if req.has("requires_weather"):
		_weather_mode = String(req.get("requires_weather", "go_checked"))
	if req.has("carrier_mode"):
		_carrier_mode = String(req.get("carrier_mode", "sealed_interlock"))
	if req.has("donor_id"):
		_donor_id = String(req.get("donor_id", ""))
	if req.has("source_structure"):
		_source_structure = String(req.get("source_structure", "anther"))
	if req.has("brush_id"):
		var b := String(req.get("brush_id", "A"))
		_brush_id = b
		_brush_dirty[b] = false
	if req.has("recipient_id"):
		_recipient_id = String(req.get("recipient_id", ""))
	if req.has("target_structure"):
		_target_structure = String(req.get("target_structure", "stigma"))
	_last_feedback = "Configured workbench for: %s" % String(req.get("label", action))
	return {"accepted": true, "reason": _last_feedback, "payload": payload_for_action(action)}

## Applies the complete documented worked choices across all P-03 steps (used by headless route test fixtures).
func apply_worked_plan() -> Dictionary:
	_worked_plan_active = true
	_weather_mode = "go_checked"
	_carrier_mode = "sealed_interlock"
	_brush_dirty = {"A": false, "B": false}
	for day in range(1, 8):
		_care_draft[str(day)] = true
	configure_for_action("p03_record_prediction")
	var next_act := next_expected_action()
	if not next_act.is_empty():
		configure_for_action(next_act)
	return {"accepted": true, "reason": "Applied P-03 worked pollination and prediction plan."}

## Returns the next expected P-03 action ID based on current progress.
func next_expected_action() -> String:
	if _run_index == 0:
		var steps0: Array = RUN_STEPS[0]
		if _step_index < steps0.size():
			return String(steps0[_step_index])
	if _run_index == 1:
		for day in [2, 3]:
			if not _care_dates.has(day):
				return "p03_log_care_day_%d" % day
		var steps1: Array = RUN_STEPS[1]
		if _step_index < steps1.size():
			return String(steps1[_step_index])
	if _run_index == 2:
		for day in [4, 5, 6, 7]:
			if not _care_dates.has(day):
				return "p03_log_care_day_%d" % day
		var steps2: Array = RUN_STEPS[2]
		if _step_index < steps2.size():
			return String(steps2[_step_index])
	if _run_index >= 3 and _care_dates.size() >= 7 and _prediction.is_empty():
		return "p03_record_prediction"
	return ""

## Builds the action payload from the player's current interactive selections.
func payload_for_action(action: String) -> Dictionary:
	if _worked_plan_active and action != "p03_record_prediction" and not action.begins_with("p03_log_care_day_"):
		var req: Dictionary = data().get("step_requirements", {}).get(action, {})
		if not req.is_empty():
			return {
				"weather_mode": String(req.get("requires_weather", _weather_mode if not _weather_mode.is_empty() else "go_checked")),
				"carrier_mode": String(req.get("carrier_mode", _carrier_mode if not _carrier_mode.is_empty() else "sealed_interlock")),
				"donor_id": String(req.get("donor_id", _donor_id)),
				"source_structure": String(req.get("source_structure", _source_structure if not _source_structure.is_empty() else "anther")),
				"brush_id": String(req.get("brush_id", _brush_id)),
				"recipient_id": String(req.get("recipient_id", _recipient_id)),
				"target_structure": String(req.get("target_structure", _target_structure if not _target_structure.is_empty() else "stigma")),
			}
	if action == "p03_record_prediction":
		var result: Dictionary = {}
		for key in ["prediction", "reason", "future_test"]:
			var val := String(_draft_prediction.get(key, "")).strip_edges()
			if not val.is_empty():
				result[key] = val
		return result
	if action.begins_with("p03_log_care_day_"):
		var day := int(action.trim_prefix("p03_log_care_day_"))
		return {
			"day": day,
			"care_confirmed": bool(_care_draft.get(str(day), false)),
		}
	return {
		"weather_mode": _weather_mode,
		"carrier_mode": _carrier_mode,
		"donor_id": _donor_id,
		"source_structure": _source_structure,
		"brush_id": _brush_id,
		"recipient_id": _recipient_id,
		"target_structure": _target_structure,
	}

## Validates a P-03 action without mutating authoritative state.
func preview_action(action: String, payload: Dictionary = {}) -> Dictionary:
	var rules := profile()
	if rules.is_empty():
		return _reject("P-03 profile is missing or invalid.")
	var content := data()
	var messages: Dictionary = content.get("feedback_messages", {})
	var effective := payload_for_action(action).merged(payload, true)

	if action in ["p03_record_prediction"]:
		if _run_index < 3 or _care_dates.size() < 7:
			return _reject("Complete all three reciprocal pollination runs and seven dated care logs before recording the stem prediction.")
		var pred_check := _validate_prediction(effective, content)
		if not bool(pred_check.get("accepted", false)):
			return pred_check
		return {"accepted": true, "reason": "Stem-colour prediction verified.", "scientific_puzzle": true}

	if action.begins_with("p03_log_care_day_"):
		var day := int(action.trim_prefix("p03_log_care_day_"))
		if day < 2 or day > 7 or not _care_dates.has(day - 1) or _care_dates.has(day):
			return _reject("Daily care logs must be recorded in date order across the seven-day pollination window.")
		if (day <= 3 and _run_index < 1) or (day >= 4 and _run_index < 2):
			return _reject("This daily care entry belongs to a later pollination window.")
		var confirmed := bool(effective.get("care_confirmed", payload.has("day") or payload.get("_puzzle_action", "") == action and _worked_plan_active))
		if not confirmed:
			return _reject("Check off Day %d in the 7-Day Care Logbook before locking in the care visit." % day)
		return {"accepted": true, "reason": "Care visit %d/7 verified." % day, "scientific_puzzle": true}

	if _run_index >= 3:
		return _reject("All three reciprocal pollination runs are already complete.")
	var steps: Array = RUN_STEPS.get(_run_index, [])
	if _step_index >= steps.size() or steps[_step_index] != action:
		return _reject("Follow the reciprocal pollination sequence: donor scan, anther pollen collection, closed carrier seal, partner stigma transfer, then reverse direction.")
	if (_run_index == 1 and not _care_dates.has(3)) or (_run_index == 2 and not _care_dates.has(7)):
		return _reject("Record the intermediate daily care observations before the next scheduled pollination run.")

	var req: Dictionary = content.get("step_requirements", {}).get(action, {})
	if req.is_empty():
		return {"accepted": true, "scientific_puzzle": true}

	if req.has("requires_weather"):
		var w := String(effective.get("weather_mode", ""))
		if w != String(req.get("requires_weather", "go_checked")):
			var w_opt := _find_item("weather_modes", w)
			var w_msg := String(w_opt.get("feedback", "")) if not w_opt.is_empty() else String(messages.get("missing_weather_check", "Confirm space weather is GO before starting a transfer."))
			return _reject(w_msg)

	if req.has("donor_id"):
		var d := String(effective.get("donor_id", ""))
		var expected_d := String(req.get("donor_id", ""))
		if d.is_empty():
			return _reject("Select donor plant %s on the pollination workbench." % expected_d)
		if d != expected_d:
			if req.has("recipient_id") and d == String(req.get("recipient_id", "")):
				return _reject("Wrong donor direction: start this transfer from %s, not %s." % [expected_d, d])
			return _reject("Select %s as the pollen donor for this step." % expected_d)

	if req.has("source_structure"):
		var s := String(effective.get("source_structure", ""))
		if s == "petal":
			return _reject(String(messages.get("petal_selected", "Touching a petal transfers no pollen.")))
		if s != String(req.get("source_structure", "anther")):
			return _reject("Select the donor flower's anther (pollen sac) to collect pollen.")

	if req.has("brush_id"):
		var b := String(effective.get("brush_id", ""))
		var expected_b := String(req.get("brush_id", ""))
		if b == "UNLABELLED":
			var u_opt := _find_item("brushes", "UNLABELLED")
			return _reject(String(u_opt.get("feedback", messages.get("wrong_brush_direction", "Use separate labelled brushes A and B."))))
		if b.is_empty():
			return _reject("Select clean Brush %s on the pollination workbench." % expected_b)
		if b != expected_b:
			return _reject(String(messages.get("wrong_brush_direction", "Use Brush A for Tara->Alo and Brush B for Alo->Tara.")))
		if bool(_brush_dirty.get(b, false)):
			return _reject(String(messages.get("dirty_brush", "Replace the dirty brush tip before collecting pollen.")))

	if req.has("carrier_mode"):
		var c := String(effective.get("carrier_mode", ""))
		if c != String(req.get("carrier_mode", "sealed_interlock")):
			var c_opt := _find_item("carrier_modes", c)
			var c_msg := String(c_opt.get("feedback", "")) if not c_opt.is_empty() else String(messages.get("unsealed_carrier", "Seal the brush inside its closed carrier and open one pressure door at a time."))
			return _reject(c_msg)

	if req.has("recipient_id"):
		var r := String(effective.get("recipient_id", ""))
		var d_check := String(effective.get("donor_id", req.get("donor_id", "")))
		var expected_r := String(req.get("recipient_id", ""))
		if r.is_empty():
			return _reject("Select recipient partner plant %s." % expected_r)
		if r == d_check:
			return _reject(String(messages.get("self_pollination", "Cultivar self-incompatibility: transfer pollen to the partner plant.")))
		if r != expected_r:
			return _reject("This transfer goes to %s." % expected_r)

	if req.has("target_structure"):
		var t := String(effective.get("target_structure", ""))
		if t == "petal":
			return _reject(String(messages.get("petal_selected", "Touching a petal transfers no pollen.")))
		if t != String(req.get("target_structure", "stigma")):
			return _reject("Select the recipient flower's receptive stigma to deliver pollen.")

	return {"accepted": true, "reason": String(req.get("label", "Pollination step verified.")), "scientific_puzzle": true}

## Commits a validated P-03 action and advances the puzzle state.
func commit_action(action: String, payload: Dictionary = {}) -> Dictionary:
	var check := preview_action(action, payload)
	if not bool(check.get("accepted", false)):
		if payload.get("target_structure", _target_structure) == "stigma":
			var req: Dictionary = data().get("step_requirements", {}).get(action, {})
			var chosen_brush := String(payload.get("brush_id", _brush_id))
			if chosen_brush in ["A", "B"] and (bool(_brush_dirty.get(chosen_brush, false)) or (req.has("brush_id") and chosen_brush != String(req.get("brush_id", "")))):
				_contaminated_transfer = true
				_brush_dirty[chosen_brush] = true
		_last_feedback = String(check.get("reason", "Pollination step needs adjustment."))
		return check

	var effective := payload_for_action(action).merged(payload, true)
	_flags[action + "_done"] = true
	if action == "p03_record_prediction":
		_prediction = {
			"prediction": String(effective.get("prediction", "")).strip_edges(),
			"reason": String(effective.get("reason", "")).strip_edges(),
			"future_test": String(effective.get("future_test", "")).strip_edges(),
		}
		_flags["p03_prediction_recorded"] = true
		_last_feedback = "Recorded pre-registered stem-colour prediction."
		return {"accepted": true, "flags": flags(), "scientific_puzzle": true}

	if action.begins_with("p03_log_care_day_"):
		var day := int(action.trim_prefix("p03_log_care_day_"))
		_care_dates.append(day)
		_care_draft[str(day)] = true
		_last_feedback = "Logged care observation Day %d/7." % day
		return {"accepted": true, "flags": flags(), "scientific_puzzle": true}

	if action in ["p03_collect_tara_pollen", "p03_run_2_forward", "p03_run_3_forward"]:
		_brush_pollen["A"] = "TARA-01"
	elif action in ["p03_collect_alo_pollen", "p03_run_2_reverse", "p03_run_3_reverse"]:
		_brush_pollen["B"] = "ALO-01"

	_step_index += 1
	if action in ["p03_complete_run_1", "p03_complete_run_2", "p03_complete_run_3"]:
		_run_index += 1
		_step_index = 0
		_flags["p03_run_%d_complete" % _run_index] = true
	_last_feedback = String(check.get("reason", "Step committed."))
	return {"accepted": true, "flags": flags(), "scientific_puzzle": true}

## Returns the authoritative P-03 completion flags.
func flags() -> Dictionary:
	var result := _flags.duplicate(true)
	result.merge({
		"p03_run_1_complete": _run_index >= 1,
		"p03_run_2_complete": _run_index >= 2,
		"p03_run_3_complete": _run_index >= 3,
		"p03_three_runs": _run_index >= 3,
		"p03_seven_care_dates": _care_dates.size() >= 7,
		"p03_prediction_recorded": not _prediction.is_empty(),
		"p03_uncontaminated": not _contaminated_transfer,
		"p03_complete": _run_index >= 3 and _care_dates.size() >= 7 and not _prediction.is_empty(),
	}, true)
	return result

## Returns a primitive, JSON-safe snapshot of P-03 state for save/load and retry checkpoints.
func snapshot() -> Dictionary:
	return {
		"run_index": _run_index,
		"step_index": _step_index,
		"care_dates": _care_dates.duplicate(),
		"prediction": _prediction.duplicate(true),
		"flags": _flags.duplicate(true),
		"weather_mode": _weather_mode,
		"carrier_mode": _carrier_mode,
		"donor_id": _donor_id,
		"source_structure": _source_structure,
		"brush_id": _brush_id,
		"recipient_id": _recipient_id,
		"target_structure": _target_structure,
		"brush_dirty": _brush_dirty.duplicate(true),
		"brush_pollen": _brush_pollen.duplicate(true),
		"contaminated_transfer": _contaminated_transfer,
		"care_draft": _care_draft.duplicate(true),
		"draft_prediction": _draft_prediction.duplicate(true),
		"shared_clues": _shared_clues.duplicate(),
		"hint_tier": _hint_tier.duplicate(true),
		"last_feedback": _last_feedback,
		"worked_plan_active": _worked_plan_active,
	}

## Restores P-03 state from a primitive snapshot.
func restore(saved: Dictionary) -> Dictionary:
	for key in ["run_index", "step_index", "care_dates", "prediction", "flags"]:
		if not saved.has(key):
			return _reject("P-03 snapshot is missing " + key + ".")
	if not saved.care_dates is Array or not saved.prediction is Dictionary or not saved.flags is Dictionary:
		return _reject("P-03 snapshot fields have invalid types.")
	_run_index = int(saved.get("run_index", 0))
	_step_index = int(saved.get("step_index", 0))
	_care_dates.clear()
	for day in saved.get("care_dates", [1]):
		_care_dates.append(int(day))
	_prediction = saved.get("prediction", {}).duplicate(true) if saved.get("prediction", {}) is Dictionary else {}
	_flags = saved.get("flags", {}).duplicate(true) if saved.get("flags", {}) is Dictionary else {}
	_weather_mode = String(saved.get("weather_mode", ""))
	_carrier_mode = String(saved.get("carrier_mode", ""))
	_donor_id = String(saved.get("donor_id", ""))
	_source_structure = String(saved.get("source_structure", ""))
	_brush_id = String(saved.get("brush_id", ""))
	_recipient_id = String(saved.get("recipient_id", ""))
	_target_structure = String(saved.get("target_structure", ""))
	_brush_dirty = {"A": false, "B": false}
	if saved.get("brush_dirty") is Dictionary:
		for k in ["A", "B"]:
			_brush_dirty[k] = bool(saved.brush_dirty.get(k, false))
	_brush_pollen = {"A": "", "B": ""}
	if saved.get("brush_pollen") is Dictionary:
		for k in ["A", "B"]:
			_brush_pollen[k] = String(saved.brush_pollen.get(k, ""))
	_contaminated_transfer = bool(saved.get("contaminated_transfer", false))
	_care_draft = {}
	if saved.get("care_draft") is Dictionary:
		for k in saved.care_draft:
			_care_draft[str(k)] = bool(saved.care_draft[k])
	_draft_prediction = {"prediction": "", "reason": "", "future_test": ""}
	if saved.get("draft_prediction") is Dictionary:
		for k in ["prediction", "reason", "future_test"]:
			_draft_prediction[k] = String(saved.draft_prediction.get(k, ""))
	_shared_clues.clear()
	if saved.get("shared_clues") is Array:
		for c in saved.shared_clues:
			_shared_clues.append(String(c))
	_hint_tier = {"pollination": 0, "prediction": 0}
	if saved.get("hint_tier") is Dictionary:
		for k in ["pollination", "prediction"]:
			_hint_tier[k] = int(saved.hint_tier.get(k, 0))
	_last_feedback = String(saved.get("last_feedback", ""))
	_worked_plan_active = bool(saved.get("worked_plan_active", false))
	return {"accepted": true}

## Returns the adjusted director command for a P-03 action.
func ledger_command(command: Dictionary, _snapshot: Dictionary) -> Dictionary:
	var action := String(command.get("payload", {}).get("_puzzle_action", ""))
	var adjustment := command_adjustment(action, _run_index)
	if not bool(adjustment.get("accepted", false)):
		return {}
	var next := command.duplicate(true)
	next["verb"] = adjustment.verb
	var payload: Dictionary = next.get("payload", {}).duplicate(true)
	for key in adjustment.payload.keys():
		payload[key] = adjustment.payload[key]
	next["payload"] = payload
	return next

## Builds a complete view model for the ScientificPuzzlePanel UI.
func view_for_scene(scene_id: String, target_id: String = "") -> Dictionary:
	var content := data()
	var stage_id := "learn"
	if scene_id in ["EX-CH02-S04", "EX-CH02-S05"]:
		stage_id = "apply"
	elif scene_id == "EX-CH02-S06":
		stage_id = "twist"
	var topic := "prediction" if stage_id == "twist" else "pollination"
	return {
		"puzzle_id": "P-03",
		"title": String(content.get("title", "Alo Meets Tara")),
		"subtitle": String(content.get("subtitle", "")),
		"question": String(content.get("question", "")),
		"goal_one_line": String(content.get("goal_one_line", "")),
		"first_time_explainer": content.get("first_time_explainer", {}),
		"stage": content.get("stages", {}).get(stage_id, {}),
		"stage_id": stage_id,
		"scene_id": scene_id,
		"target_id": target_id,
		"next_action": next_expected_action(),
		"run_index": _run_index,
		"step_index": _step_index,
		"care_dates": _care_dates.duplicate(),
		"care_draft": _care_draft.duplicate(true),
		"weather_mode": _weather_mode,
		"carrier_mode": _carrier_mode,
		"donor_id": _donor_id,
		"source_structure": _source_structure,
		"brush_id": _brush_id,
		"recipient_id": _recipient_id,
		"target_structure": _target_structure,
		"brush_dirty": _brush_dirty.duplicate(true),
		"contaminated_transfer": _contaminated_transfer,
		"draft_prediction": _draft_prediction.duplicate(true),
		"committed_prediction": _prediction.duplicate(true),
		"plants": content.get("plants", {}),
		"structures": content.get("structures", []),
		"brushes": content.get("brushes", []),
		"carrier_modes": content.get("carrier_modes", []),
		"weather_modes": content.get("weather_modes", []),
		"care_schedule": content.get("care_dates", []),
		"prediction_options": content.get("prediction_options", {}),
		"clues": content.get("clues", []),
		"shared_clues": _shared_clues.duplicate(),
		"hint_topic": topic,
		"hints_revealed": hints_for(topic),
		"hint_tier": int(_hint_tier.get(topic, 0)),
		"hint_max": content.get("hints", {}).get(topic, []).size(),
		"bridges": content.get("bridges", {}),
		"last_feedback": _last_feedback,
		"flags": flags(),
	}

## Computes the resource and date command adjustment for a P-03 action.
static func command_adjustment(action: String, completed_runs: int) -> Dictionary:
	var rules := profile()
	if rules.is_empty():
		return _reject("P-03 profile is missing or invalid.")
	if not action.begins_with("p03_complete_run_") and action != "p03_record_prediction":
		return {"accepted": true, "verb": "set_phase", "payload": {"phase": "execute"}}
	var sampled: Dictionary = rules.get("sampled", {})
	var background: Dictionary = rules.get("background", {})
	var dates: Array = sampled.get("dates", [])
	var condition_gains: Array = sampled.get("plant_condition_gain_per_run", [])
	var deltas: Dictionary = {}
	var scenario_datetime := ""
	if action.begins_with("p03_complete_run_"):
		if completed_runs < 0 or completed_runs >= dates.size() or completed_runs >= condition_gains.size():
			return _reject("P-03 sampled pollination run index is out of range.")
		var net_energy := int(sampled.get("solar_generation", 0)) - int(sampled.get("base_load", 0)) - int(sampled.get("operation_energy_cost", 0))
		var net_air := int(sampled.get("recycle_gain", 0)) - int(sampled.get("crew_air_draw", 0)) - int(sampled.get("operation_air_cost", 0))
		deltas = {
			"E": net_energy,
			"A": net_air,
			"H": int(sampled.get("habitat_health_gain", 0)),
			"C": int(condition_gains[completed_runs]),
			"R": -float(sampled.get("food_consumption", 0.0)),
		}
		scenario_datetime = String(dates[completed_runs])
	else:
		var sampled_food := float(sampled.get("food_consumption", 0.0)) * float(dates.size())
		var remaining_food_delta := float(background.get("food_supply_gain", 0.0)) - float(background.get("total_consumption", 0.0)) + sampled_food
		deltas = {"R": remaining_food_delta}
		scenario_datetime = String(background.get("completion_datetime", ""))
	return {
		"accepted": true,
		"verb": "apply_delta",
		"payload": {
			"deltas": deltas,
			"scenario_datetime": scenario_datetime,
			"ledger": "p03_pollination",
		},
	}

func _validate_prediction(effective: Dictionary, content: Dictionary) -> Dictionary:
	var messages: Dictionary = content.get("feedback_messages", {})
	var pred_opts: Dictionary = content.get("prediction_options", {})
	for pair in [["prediction", "expectations"], ["reason", "reasons"], ["future_test", "future_tests"]]:
		var field: String = pair[0]
		var group: String = pair[1]
		var val := String(effective.get(field, "")).strip_edges()
		if val.is_empty():
			return _reject(String(messages.get("prediction_incomplete", "Select your expectation, scientific reason, and future test in the Stem Prediction panel before locking in.")))
		var matched_valid := false
		for opt in pred_opts.get(group, []):
			if opt is Dictionary and (String(opt.get("value", "")) == val or String(opt.get("id", "")) == val):
				if not bool(opt.get("valid", false)):
					return _reject(String(opt.get("feedback", "That prediction option is not supported by the parent stem observations.")))
				matched_valid = true
				break
		if not matched_valid:
			return _reject("Select a documented scientific option for %s." % field)
	return {"accepted": true}

func _find_item(list_key: String, item_id: String) -> Dictionary:
	for item in data().get(list_key, []):
		if item is Dictionary and String(item.get("id", "")) == item_id:
			return item
	return {}

static func _validate_profile(rules: Dictionary) -> Dictionary:
	if rules.is_empty() or not rules.get("entry") is Dictionary or not rules.get("sampled") is Dictionary or not rules.get("background") is Dictionary:
		return _reject("P-03 profile sections are missing.")
	var entry: Dictionary = rules.entry
	for key in ["E", "E_max", "A", "A_max", "H", "C", "R"]:
		if not entry.has(key):
			return _reject("P-03 entry profile is missing " + key + ".")
	var sampled: Dictionary = rules.sampled
	if not sampled.get("dates") is Array or not sampled.get("plant_condition_gain_per_run") is Array:
		return _reject("P-03 sampled schedule arrays are missing.")
	if sampled.dates.size() != 3 or sampled.plant_condition_gain_per_run.size() != 3:
		return _reject("P-03 sampled schedule must define three pollination runs.")
	return {"accepted": true}

static func _reject(reason: String) -> Dictionary:
	return {"accepted": false, "reason": reason, "scientific_puzzle": true}
