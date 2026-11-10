extends RefCounted
class_name P14StormExecution

## P-14 — Three Waves and a Broken Link (game-design/08 §P-14, 22 §9).
## Pure rule model: the player executes the P-13 six-step storm plan,
## plays Noor's last log in the lull after step 2, keeps the hatch closed
## during exposure, then diagnoses the failed uplink branch by branch and
## clears the route with two below-threshold dosimeter readings ten
## scenario minutes apart. The answers live in
## game/resources/campaign/content/p14_storm_execution.json; the step
## arithmetic is the P-13 forecast (P13StormPlan), sampled as the steps
## execute. Dose is sampled before an ordinary transfer; the Chapter 7
## dose limit is 6, not 3; K stays installed through step 6.
##
## The witness ends E6, A2.5, H1, C3, R9, Z0, W2, K2, reserve 30 safe,
## with local PASS, direct FAIL, external FAIL, route F-EXT and readings
## 0.4 then 0.3. A 1.2 reading does not clear the route, and one safe
## reading is insufficient.

const DataScript = preload("res://scripts/puzzles/puzzle_data.gd")
const P13Script = preload("res://scripts/puzzles/p13_storm_plan.gd")
const SimulationScript = preload("res://scripts/simulation/expedition_simulation.gd")

var _planner: RefCounted
var _steps_done := 0
var _resources := {}
var _step_results: Array = []
var _hatch_closed := true
var _log_played := false
var _academy_recorded := false
var _progress_saved := false
var _case_sealed := false
var _crops_safe := false
var _reserve_safe := false
var _branch_results := {"local": "", "direct": "", "external": ""}
var _route := ""
var _readings: Array = []
var _packed := {"controller": false, "battery": false, "route": false, "bench": false}
var _assigned := {"field": false, "home": false}
var _signed := false
var _done: Array = []

static func data() -> Dictionary:
	return DataScript.data("P-14")

func _init() -> void:
	_planner = P13Script.new()
	_resources = _entry_resources()

func _entry_resources() -> Dictionary:
	var entry: Dictionary = P13Script.profile().get("resources", {})
	return {"E": float(entry.get("E", 30)), "A": float(entry.get("A", 10)), "H": float(entry.get("H", 6)), "C": float(entry.get("C", 8)), "R": float(entry.get("R", 18)), "Z": 0, "W": int(entry.get("water", 4)) if entry.has("water") else 4, "K": 2, "reserve": 30}

## The P-13 plan this execution follows: a P13StormPlan snapshot, a
## forecast plan dictionary, or nothing (the data witness).
func set_plan(plan: Dictionary) -> Dictionary:
	if _steps_done > 0:
		return _reject("The storm has started; the plan cannot change now.")
	var water := int(plan.get("water", 4))
	var crate := int(plan.get("crate", 2))
	var heat := String(plan.get("heat", "COZY"))
	var light := String(plan.get("light", "DIM"))
	var drain_step := int(plan.get("drain_step", 6))
	var check: Dictionary = _planner.forecast({"water": water, "crate": crate, "heat": heat, "light": light, "drain_step": drain_step})
	if not bool(check.get("feasible", false)):
		var problems: Array = check.get("problems", [])
		return _reject("That plan is not feasible: " + String(problems[0] if not problems.is_empty() else "check the forecast."))
	_planner.set_water(water)
	_planner.set_crate(crate)
	_planner.set_heat(heat)
	_planner.set_light(light)
	_planner.set_drain_step(drain_step)
	_resources["W"] = water
	_resources["K"] = crate
	return _accept("Storm plan set: W%d, K%d, %s/%s, drain step %d." % [water, crate, heat, light, drain_step])

func plan() -> Dictionary:
	var snap: Dictionary = _planner.snapshot()
	return {"water": snap.get("water", 4), "crate": snap.get("crate", 2), "heat": snap.get("heat", "COZY"), "light": snap.get("light", "DIM"), "drain_step": snap.get("drain_step", 6)}

## The six-step forecast for the stored plan. Pure: it never changes state.
func forecast() -> Dictionary:
	return _planner.forecast()

## Execute the next steps (2 for the first wave, 4 for the rest), sampling
## the forecast as the steps run. Dose is scored before the step 6 drain.
func execute_steps(count: int) -> Dictionary:
	if _steps_done + count > 6:
		return _reject("Only %d storm steps remain." % (6 - _steps_done))
	if not _hatch_closed:
		return _reject(String(data().get("feedback", {}).get("hatch_open", "The hatch interlock prevents storm EVA.")))
	var result := forecast()
	if not bool(result.get("feasible", false)):
		var problems: Array = result.get("problems", [])
		return _reject("The plan is not feasible: " + String(problems[0] if not problems.is_empty() else "check the forecast."))
	var steps: Array = result.get("steps", [])
	var ending: Dictionary = result.get("ending", {})
	var start_water := int(plan().get("water", 4))
	var crate := int(plan().get("crate", 2))
	for offset in count:
		var index := _steps_done + offset
		var record: Dictionary = steps[index]
		_step_results.append(record.duplicate(true))
		_resources = {"E": float(record.get("E", 0)), "A": float(record.get("A", 0)), "H": int(record.get("H", 0)), "C": int(record.get("C", 0)), "R": float(record.get("R", 0)), "Z": int(record.get("Z", 0)), "W": int(ending.get("W", 2)) if index == 5 else start_water, "K": crate, "reserve": 30}
	_steps_done += count
	return _accept("Steps %d to %d executed: E%s A%s H%s C%s R%s Z%s." % [_steps_done - count + 1, _steps_done, _resources["E"], _resources["A"], _resources["H"], _resources["C"], _resources["R"], _resources["Z"]])

func play_log() -> Dictionary:
	if _log_played:
		return {"accepted": true, "duplicate": true, "reason": "Noor's last log already played."}
	if _steps_done != 2:
		return _reject("Noor's last log plays after step 2 in the lull, once the first wave is checked.")
	_log_played = true
	return _accept("Noor's last log: the seeds are called Alo, light. The Academy takes its name from that hope.")

func record_academy_name() -> Dictionary:
	if not _log_played:
		return _reject("Play Noor's last log before recording the Academy name.")
	if _academy_recorded:
		return {"accepted": true, "duplicate": true, "reason": "The Academy name is already recorded."}
	_academy_recorded = true
	return _accept("Last Light Academy recorded from the log.")

func save_progress_report() -> Dictionary:
	if _steps_done < 2:
		return _reject("Execute the first wave before saving the progress report.")
	if _progress_saved:
		return {"accepted": true, "duplicate": true, "reason": "The progress report is already saved."}
	_progress_saved = true
	return _accept("Progress report saved after the first wave.")

func confirm_case_sealed() -> Dictionary:
	if _case_sealed:
		return {"accepted": true, "duplicate": true, "reason": "The seed case is already confirmed sealed."}
	_case_sealed = true
	return _accept("Seed case confirmed sealed by its sensors; it is never opened.")

func confirm_crops_safe() -> Dictionary:
	if _steps_done < 6:
		return _reject("Finish all three waves before confirming the crops are safe.")
	if _crops_safe:
		return {"accepted": true, "duplicate": true, "reason": "The crops are already confirmed safe."}
	if int(_resources.get("C", 0)) <= 0:
		return _reject("The living garden is lost; the crops are not safe.")
	_crops_safe = true
	return _accept("Living crops confirmed safe after the storm.")

func confirm_reserve_safe() -> Dictionary:
	if _steps_done < 6:
		return _reject("Finish all three waves before confirming the founder reserve.")
	if _reserve_safe:
		return {"accepted": true, "duplicate": true, "reason": "The founder reserve is already confirmed safe."}
	_reserve_safe = true
	return _accept("Founder reserve of 30 confirmed safe after the storm.")

## Branch tests after step 6. The outcomes are scripted facts: the local
## network passes, the direct dish path fails, the external feedthrough
## fails. A working local radio isolates the failure to the Earth path.
func test_branch(branch: String) -> Dictionary:
	if _steps_done < 6:
		return _reject(String(data().get("feedback", {}).get("steps_incomplete", "Finish all three waves before going outside.")))
	if branch != "local" and branch != "direct" and branch != "external":
		return _reject("Test the local network, the direct dish path or the external feedthrough.")
	if String(_branch_results.get(branch, "")) != "":
		return {"accepted": true, "duplicate": true, "reason": "The %s branch already tested %s." % [branch, String(_branch_results.get(branch, ""))]}
	var outcome := "PASS" if branch == "local" else "FAIL"
	_branch_results[branch] = outcome
	return _accept("Branch %s: %s." % [branch, outcome])

func branches_tested() -> bool:
	return String(_branch_results.get("local", "")) != "" and String(_branch_results.get("direct", "")) != "" and String(_branch_results.get("external", "")) != ""

func select_route(route: String) -> Dictionary:
	if not branches_tested():
		return _reject("Test all three branches before selecting the failed route.")
	if route != "F-EXT":
		return _reject(String(data().get("feedback", {}).get("wrong_branch", "The broken branch is the external feedthrough.")))
	_route = route
	return _accept("Route F-EXT selected: the external feedthrough failed.")

## One dosimeter reading. The minute is the scenario minute of the reading:
## the first reading sets it, the second must be ten minutes later.
## Without a minute the model records 0, then 10.
func record_reading(value, minute: int = -1) -> Dictionary:
	if _route != "F-EXT":
		return _reject("Select the failed route F-EXT before recording route readings.")
	if _readings.size() >= 2:
		return {"accepted": true, "duplicate": true, "reason": "Two clear readings are already recorded."}
	if not (value is int or value is float) or not is_finite(float(value)) or float(value) < 0:
		return _reject("A route reading must be a finite nonnegative number.")
	if float(value) >= 1.0:
		return _reject(String(data().get("feedback", {}).get("reading_not_clear", "A 1.2 reading does not clear the route.")))
	var at := minute
	if _readings.is_empty():
		if at < 0:
			at = 0
	else:
		var first: Dictionary = _readings[0]
		if at < 0:
			at = int(first.get("minute", 0)) + 10
		elif at != int(first.get("minute", 0)) + 10:
			return _reject("The second reading comes ten scenario minutes after the first.")
	_readings.append({"value": float(value), "minute": at})
	if _readings.size() == 2:
		return _accept("Second clear reading %s at minute %d: the route is clear." % [value, at])
	return _accept("First clear reading %s at minute %d." % [value, at])

func readings_clear() -> bool:
	if _readings.size() != 2:
		return false
	var first: Dictionary = _readings[0]
	var second: Dictionary = _readings[1]
	return float(first.get("value", 1)) < 1.0 and float(second.get("value", 1)) < 1.0 and int(second.get("minute", -1)) - int(first.get("minute", 0)) == 10

func route_clear() -> bool:
	return _route == "F-EXT" and readings_clear()

func complete() -> bool:
	return _steps_done == 6 and float(_resources.get("A", 0)) > 0 and int(_resources.get("Z", 99)) <= 6 and int(_resources.get("H", 0)) > 0 and int(_resources.get("C", 0)) > 0 and route_clear() and _log_played and _crops_safe and _reserve_safe

func hint(tier: int) -> String:
	var hints: Array = data().get("hints", {}).get("execution", [])
	if tier < 1 or tier > hints.size():
		return ""
	return String(hints[tier - 1])

## Return the execution to its fresh state. A committed step cannot be
## undone here; the route's checkpoint retry is the way back.
func reset() -> Dictionary:
	if _steps_done > 0 or not _readings.is_empty():
		return _reject("Storm steps already executed cannot be undone here.")
	_log_played = false
	_academy_recorded = false
	_progress_saved = false
	_case_sealed = false
	_crops_safe = false
	_reserve_safe = false
	_branch_results = {"local": "", "direct": "", "external": ""}
	_route = ""
	_readings = []
	_packed = {"controller": false, "battery": false, "route": false, "bench": false}
	_assigned = {"field": false, "home": false}
	_signed = false
	_done = []
	return _accept("Execution cleared. The evidence has not changed.")

func preview_action(action: String, payload: Dictionary = {}) -> Dictionary:
	if _done.has(action):
		return {"accepted": true, "duplicate": true, "reason": "P-14 action already has a receipt."}
	match action:
		"p14_confirm_five_occupants":
			return _accept("Five occupants confirmed for the storm.")
		"p14_check_hatch_one", "p14_check_hatch_two":
			if String(payload.get("hatch", "closed")) != "closed":
				return _reject(String(data().get("feedback", {}).get("hatch_open", "The hatch interlock prevents storm EVA.")))
			return _accept("Hatch seal checked: closed during exposure.")
		"p14_commit_steps_1_2":
			if _steps_done != 0:
				return _reject("Steps 1 and 2 are already executed.")
			if not _hatch_closed:
				return _reject(String(data().get("feedback", {}).get("hatch_open", "The hatch interlock prevents storm EVA.")))
			var first_plan := forecast()
			if not bool(first_plan.get("feasible", false)):
				var first_problems: Array = first_plan.get("problems", [])
				return _reject("The plan is not feasible: " + String(first_problems[0] if not first_problems.is_empty() else "check the forecast."))
			return _accept("Steps 1 and 2 are ready to execute.")
		"p14_save_forecast_comparison":
			if _steps_done < 2:
				return _reject("Execute steps 1 and 2 before saving the forecast comparison.")
			return _accept("The forecast comparison is ready to save.")
		"p14_confirm_case_sealed":
			return _accept("The seed case is ready to confirm sealed.")
		"p14_read_final_log":
			if _steps_done != 2:
				return _reject("Noor's last log plays after step 2 in the lull, once the first wave is checked.")
			if String(payload.get("log_timing", "after_step_2")) != "after_step_2":
				return _reject("The log belongs in the lull after step 2.")
			return _accept("Noor's last log is ready to play.")
		"p14_record_academy_name":
			if not _log_played:
				return _reject("Play Noor's last log before recording the Academy name.")
			return _accept("The Academy name is ready to record.")
		"p14_save_progress_report":
			if _steps_done < 2:
				return _reject("Execute the first wave before saving the progress report.")
			return _accept("The progress report is ready to save.")
		"p14_commit_steps_3_6":
			if _steps_done != 2:
				return _reject("Execute steps 1 and 2 and play the log before the last four steps.")
			if not _log_played:
				return _reject("Play Noor's last log in the lull before the last four steps.")
			var rest_plan := forecast()
			if not bool(rest_plan.get("feasible", false)):
				var rest_problems: Array = rest_plan.get("problems", [])
				return _reject("The plan is not feasible: " + String(rest_problems[0] if not rest_problems.is_empty() else "check the forecast."))
			return _accept("Steps 3 to 6 are ready to execute.")
		"p14_confirm_crops_safe":
			if _steps_done < 6:
				return _reject(String(data().get("feedback", {}).get("steps_incomplete", "Finish all three waves before going outside.")))
			return _accept("The crops are ready to confirm safe.")
		"p14_confirm_reserve_30":
			if _steps_done < 6:
				return _reject(String(data().get("feedback", {}).get("steps_incomplete", "Finish all three waves before going outside.")))
			return _accept("The founder reserve is ready to confirm safe.")
		"p14_diagnose_external_branch":
			if _steps_done < 6:
				return _reject(String(data().get("feedback", {}).get("steps_incomplete", "Finish all three waves before going outside.")))
			if String(payload.get("route", "")) != "" and String(payload.get("route", "")) != "F-EXT":
				return _reject(String(data().get("feedback", {}).get("wrong_branch", "The broken branch is the external feedthrough.")))
			if branches_tested():
				return _accept("External feedthrough diagnosed: local PASS, direct FAIL, external FAIL.")
			return _accept("All three branches are ready to test.")
		"p14_route_reading_1", "p14_route_reading_2":
			if _route != "F-EXT":
				return _reject("Select the failed route F-EXT before recording route readings.")
			if action == "p14_route_reading_2" and _readings.size() < 1:
				return _reject("Record the first reading before the second.")
			if action == "p14_route_reading_1" and _readings.size() >= 1:
				return _reject("The first reading is already recorded.")
			if not payload.has("reading"):
				return _reject("Choose a dosimeter reading.")
			if float(payload.get("reading", 1)) >= 1.0:
				return _reject(String(data().get("feedback", {}).get("reading_not_clear", "A 1.2 reading does not clear the route.")))
			return _accept("Reading %s is below the threshold of 1." % payload.get("reading", ""))
		"p14_reconcile_local_stability", "p14_reconcile_supplies", "p14_date_march_gate":
			if not route_clear():
				return _reject(String(data().get("feedback", {}).get("one_reading_insufficient", "Two clear readings, ten scenario minutes apart, clear the route.")))
			return _accept("Departure preparation is ready after a clear route.")
		"p14_pack_controller", "p14_pack_battery", "p14_pack_three_site_route":
			if not route_clear():
				return _reject("Clear the route before packing for departure.")
			return _accept("Packing is ready after a clear route.")
		"p14_bench_test":
			if not bool(_packed.get("controller", false)):
				return _reject("Pack the controller before the bench test.")
			return _accept("The bench test is ready.")
		"p14_assign_field_team", "p14_assign_home_team":
			if not bool(_packed.get("bench", false)):
				return _reject("Bench-test the controller before assigning teams.")
			return _accept("Team assignment is ready.")
		"p14_sign_departure_prep":
			if not bool(_assigned.get("field", false)) or not bool(_assigned.get("home", false)):
				return _reject("Assign both teams before signing the departure preparation.")
			return _accept("Departure preparation is ready to sign.")
	return _reject("Unknown P-14 action: " + action)

func commit_action(action: String, payload: Dictionary = {}) -> Dictionary:
	var check := preview_action(action, payload)
	if not bool(check.get("accepted", false)):
		return check
	if bool(check.get("duplicate", false)):
		return check
	var result := _apply_action(action, payload)
	if bool(result.get("accepted", false)) and not _done.has(action):
		_done.append(action)
	return result

func _apply_action(action: String, payload: Dictionary) -> Dictionary:
	match action:
		"p14_commit_steps_1_2":
			return execute_steps(2)
		"p14_commit_steps_3_6":
			return execute_steps(4)
		"p14_read_final_log":
			return play_log()
		"p14_record_academy_name":
			return record_academy_name()
		"p14_save_progress_report", "p14_save_forecast_comparison":
			if action == "p14_save_progress_report":
				return save_progress_report()
			return _accept("Forecast comparison saved after the first wave.")
		"p14_confirm_case_sealed":
			return confirm_case_sealed()
		"p14_confirm_crops_safe":
			return confirm_crops_safe()
		"p14_confirm_reserve_30":
			return confirm_reserve_safe()
		"p14_diagnose_external_branch":
			var local := test_branch("local")
			var direct := test_branch("direct")
			var external := test_branch("external")
			if not bool(local.get("accepted", false)) or not bool(direct.get("accepted", false)) or not bool(external.get("accepted", false)):
				return _reject("Test all three branches before selecting the failed route.")
			return select_route(String(payload.get("route", "F-EXT")))
		"p14_route_reading_1", "p14_route_reading_2":
			return record_reading(payload.get("reading", 1.0), int(payload.get("minute", -1)))
		"p14_pack_controller":
			_packed["controller"] = true
			return _accept("Controller packed.")
		"p14_pack_battery":
			_packed["battery"] = true
			return _accept("Battery spare packed.")
		"p14_pack_three_site_route":
			_packed["route"] = true
			return _accept("Three-site route packed.")
		"p14_bench_test":
			_packed["bench"] = true
			return _accept("Bench test passed. A bench pass is not field verification.")
		"p14_assign_field_team":
			_assigned["field"] = true
			return _accept("Field team assigned: Kai and Rafi with Ferreira.")
		"p14_assign_home_team":
			_assigned["home"] = true
			return _accept("Home team assigned: Mei and Amara hold Aurora.")
		"p14_sign_departure_prep":
			_signed = true
			return _accept("Departure preparation signed.")
	return _accept("P-14 action recorded once.")

func flags() -> Dictionary:
	return {
		"p14_steps_done": _steps_done,
		"p14_log_played": _log_played,
		"p14_academy_recorded": _academy_recorded,
		"p14_case_sealed": _case_sealed,
		"p14_crops_safe": _crops_safe,
		"p14_reserve_safe": _reserve_safe,
		"p14_branch_local": String(_branch_results.get("local", "")),
		"p14_branch_direct": String(_branch_results.get("direct", "")),
		"p14_branch_external": String(_branch_results.get("external", "")),
		"p14_route": _route,
		"p14_readings": _readings.duplicate(true),
		"p14_readings_clear": readings_clear(),
		"p14_route_clear": route_clear(),
		"p14_complete": complete(),
		"route_clear_pending": route_clear(),
		"radio_external_failed": String(_branch_results.get("external", "")) == "FAIL",
		"final_log_heard": _log_played,
		"all_crew_safe": complete(),
	}

func snapshot() -> Dictionary:
	return {"schema_version": 1, "plan": plan(), "steps_done": _steps_done, "resources": _resources.duplicate(true), "step_results": _step_results.duplicate(true), "hatch_closed": _hatch_closed, "log_played": _log_played, "academy_recorded": _academy_recorded, "progress_saved": _progress_saved, "case_sealed": _case_sealed, "crops_safe": _crops_safe, "reserve_safe": _reserve_safe, "branch_results": _branch_results.duplicate(true), "route": _route, "readings": _readings.duplicate(true), "packed": _packed.duplicate(true), "assigned": _assigned.duplicate(true), "signed": _signed, "done": _done.duplicate()}

func restore(state: Dictionary) -> Dictionary:
	var version = state.get("schema_version", 1)
	if not (version is int or version is float) or float(version) != 1.0:
		return _reject("P-14 snapshot is incompatible.")
	var plan_state = state.get("plan", {})
	if not plan_state is Dictionary or int(plan_state.get("water", -1)) not in [0, 2, 4, 5, 6] or int(plan_state.get("crate", -1)) < 0 or int(plan_state.get("crate", 99)) > 2:
		return _reject("P-14 plan must name a valid storm plan.")
	if not (state.get("steps_done", null) is int or state.get("steps_done", null) is float) or int(state.get("steps_done", -1)) < 0 or int(state.get("steps_done", 99)) > 6:
		return _reject("P-14 steps must be 0 to 6.")
	if not state.get("resources", {}) is Dictionary:
		return _reject("P-14 resources must be a dictionary.")
	for key in ["E", "A", "H", "C", "R", "Z"]:
		if not SimulationScript.is_amount((state.get("resources", {}) as Dictionary).get(key, null)):
			return _reject("P-14 resources must be finite nonnegative numbers.")
	for key in ["hatch_closed", "log_played", "academy_recorded", "progress_saved", "case_sealed", "crops_safe", "reserve_safe", "signed"]:
		if not state.get(key, null) is bool:
			return _reject("P-14 execution state must be boolean.")
	if not state.get("branch_results", {}) is Dictionary or not state.get("readings", []) is Array or not state.get("done", []) is Array:
		return _reject("P-14 branches, readings and receipts must be a dictionary and arrays.")
	_planner = P13Script.new()
	_planner.set_water(int(plan_state.get("water", 4)))
	_planner.set_crate(int(plan_state.get("crate", 2)))
	_planner.set_heat(String(plan_state.get("heat", "COZY")))
	_planner.set_light(String(plan_state.get("light", "DIM")))
	_planner.set_drain_step(int(plan_state.get("drain_step", 6)))
	_steps_done = int(state.get("steps_done", 0))
	_resources = state.get("resources", {}).duplicate(true)
	_step_results = state.get("step_results", []).duplicate(true)
	_hatch_closed = bool(state.get("hatch_closed", true))
	_log_played = bool(state.get("log_played", false))
	_academy_recorded = bool(state.get("academy_recorded", false))
	_progress_saved = bool(state.get("progress_saved", false))
	_case_sealed = bool(state.get("case_sealed", false))
	_crops_safe = bool(state.get("crops_safe", false))
	_reserve_safe = bool(state.get("reserve_safe", false))
	_branch_results = state.get("branch_results", {}).duplicate(true)
	_route = String(state.get("route", ""))
	_readings = state.get("readings", []).duplicate(true)
	_packed = state.get("packed", {}).duplicate(true)
	_assigned = state.get("assigned", {}).duplicate(true)
	_signed = bool(state.get("signed", false))
	_done.assign(state.get("done", []))
	return _accept("P-14 restored.")

func _accept(reason: String) -> Dictionary:
	return {"accepted": true, "duplicate": false, "reason": reason}

func _reject(reason: String) -> Dictionary:
	return {"accepted": false, "duplicate": false, "reason": reason}
