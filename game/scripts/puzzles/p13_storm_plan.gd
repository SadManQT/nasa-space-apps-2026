extends RefCounted
class_name P13StormPlan

## P-13 — One Integrated Storm Plan (game-design/08 §P-13, 22 §9).
## Pure rule model: the player plans six dark 7.2 h storm steps for five
## people — water and crate shielding in shelter, COZY heat, DIM light,
## both founder-reserve compartments latched, the exposed uplink isolated
## before the peak, and the drain in step 6 after that step's exposure.
## The answers live in game/resources/campaign/content/p13_storm_plan.json;
## the step arithmetic follows game/scripts/simulation/expedition_simulation.gd
## (P-02) with the storm rules from 08: dose is sampled every step with the
## step multiplier, the drain follows exposure, K stays installed through
## step 6, and the Chapter 7 dose limit is 6.
##
## The witness plan (W4, K2, COZY/DIM, drain step 6) ends E6, A2.5, H1, C3,
## R9, Z0, W2, K2, reserve 30. The one identical-ending alternative is
## W5/K1 (shield 6, drain to W3); W6/K0 fails because the sixth step still
## draws on the garden (health ends 0). The forecast shows the numbers for
## any schedule; the commit requires the 08 schedule (COZY/DIM) and the
## safety and living-garden goals.

const DataScript = preload("res://scripts/puzzles/puzzle_data.gd")
const SimulationScript = preload("res://scripts/simulation/expedition_simulation.gd")

const MULTIPLIERS := [1, 1, 2, 2, 1, 1]
const HEAT_LEVELS := {"COLD": 0, "COOL": 1, "COZY": 2}
const LIGHT_LEVELS := {"OFF": 0, "DIM": 1, "FULL": 2}

var _water := 4
var _crate := 2
var _heat := "COZY"
var _light := "DIM"
var _drain_step := 6
var _seed_latched := 0
var _uplink_isolated := false
var _roster_five := false
var _committed := false
var _done: Array = []

static func data() -> Dictionary:
	return DataScript.data("P-13")

## JSON numbers arrive as floats, so the storm multipliers are compared
## element by element instead of as one array against int literals.
static func _is_witness_multipliers(value) -> bool:
	if not value is Array:
		return false
	var multipliers: Array = value
	if multipliers.size() != 6:
		return false
	var expected: Array = [1, 1, 2, 2, 1, 1]
	for i in range(6):
		if int(multipliers[i]) != int(expected[i]):
			return false
	return true

## The p13 campaign profile, validated the way P-03 validates its profile.
## Returns {} (and reports why) when the profile is missing or malformed.
static func profile() -> Dictionary:
	var rules: Dictionary = SimulationScript.load_profile("p13_campaign")
	if rules.is_empty():
		return {}
	var resources = rules.get("resources", null)
	var problem := ""
	if not resources is Dictionary:
		problem = "resources are required"
	elif int(rules.get("phases", 0)) != 6:
		problem = "six storm steps are required"
	elif not _is_witness_multipliers(rules.get("multipliers", [])):
		problem = "storm multipliers must be [1, 1, 2, 2, 1, 1]"
	else:
		for key in ["daylight_energy", "basic_energy", "heat", "light", "breathing_air", "food_consumption"]:
			if not SimulationScript.is_amount(rules.get(key, null)):
				problem = key + " must be a finite nonnegative number"
		for key in ["E", "A", "H", "C", "R"]:
			if not SimulationScript.is_amount(resources.get(key, null)):
				problem = "resources." + key + " must be a finite nonnegative number"
	if not problem.is_empty():
		push_error("P-13 profile is invalid: " + problem)
		return {}
	return rules

static func dose_for_shelter(shelter: int) -> int:
	if shelter >= 6:
		return 0
	if shelter >= 4:
		return 1
	if shelter >= 2:
		return 2
	return 3

func _init() -> void:
	var expected: Dictionary = data().get("expected", {})
	_water = int((expected.get("water", [4, 4, 4, 4, 4, 2]) as Array)[0])
	_crate = int(expected.get("crate", 2))
	_heat = String(expected.get("heat", "COZY"))
	_light = String(expected.get("light", "DIM"))
	_drain_step = 6

## Plan setters. Each is a free choice until the plan commits.
func set_water(value: int) -> Dictionary:
	if _committed:
		return _reject("The storm plan is already committed.")
	if value != 0 and value != 2 and value != 4 and value != 5 and value != 6:
		return _reject("Shelter water is 0, 2, 4, 5 or 6; 5 is the W5/K1 alternative.")
	_water = value
	return _accept("Shelter water set to W%d." % value)

func set_crate(value: int) -> Dictionary:
	if _committed:
		return _reject("The storm plan is already committed.")
	if value < 0 or value > 2:
		return _reject("Crate shielding is 0, 1 or 2 units.")
	_crate = value
	return _accept("Crate shielding set to K%d." % value)

func set_heat(value: String) -> Dictionary:
	if _committed:
		return _reject("The storm plan is already committed.")
	if not HEAT_LEVELS.has(value):
		return _reject("Heat is COLD, COOL or COZY.")
	_heat = value
	return _accept("Heat set to %s for all six steps." % value)

func set_light(value: String) -> Dictionary:
	if _committed:
		return _reject("The storm plan is already committed.")
	if not LIGHT_LEVELS.has(value):
		return _reject("Light is OFF, DIM or FULL.")
	_light = value
	return _accept("Light set to %s for all six steps." % value)

func set_drain_step(value: int) -> Dictionary:
	if _committed:
		return _reject("The storm plan is already committed.")
	if value < 0 or value > 6:
		return _reject("The drain step is 0 (no drain) or a step from 1 to 6.")
	_drain_step = value
	return _accept("Drain set for step %d." % value if value > 0 else "Drain removed from the plan.")

func latch_seed(compartments: int) -> Dictionary:
	if _committed:
		return _reject("The storm plan is already committed.")
	if compartments < 0 or compartments > 2:
		return _reject("The founder reserve has two compartments.")
	_seed_latched = compartments
	if compartments == 2:
		return _accept("Both founder-reserve compartments latched: 15 + 15 = 30 protected.")
	return _accept("%d of 2 founder-reserve compartments latched." % compartments)

func isolate_uplink() -> Dictionary:
	if _committed:
		return _reject("The storm plan is already committed.")
	_uplink_isolated = true
	return _accept("Exposed uplink isolated before the peak step.")

func confirm_roster(occupants: int) -> Dictionary:
	if _committed:
		return _reject("The storm plan is already committed.")
	if occupants != 5:
		_roster_five = false
		return _reject("April's card counted four. Today it must count Ferreira too.")
	_roster_five = true
	return _accept("Five names. Five places inside. Air 1.25 and food 1.5 per step.")

## The six-step forecast for the current plan (or an override plan).
## Pure: it never changes state. Dose is sampled every step with the step
## multiplier; the drain follows the exposure it belongs to; H/C follow the
## P-02 plant rules with the post-transfer water.
func forecast(plan: Dictionary = {}) -> Dictionary:
	var rules := profile()
	if rules.is_empty():
		return {}
	var entry: Dictionary = rules.get("resources", {})
	var water: int = int(plan.get("water", _water))
	var crate: int = int(plan.get("crate", _crate))
	var heat_name: String = String(plan.get("heat", _heat))
	var light_name: String = String(plan.get("light", _light))
	var drain_step: int = int(plan.get("drain_step", _drain_step))
	var heat: int = int(HEAT_LEVELS.get(heat_name, 2))
	var light: int = int(LIGHT_LEVELS.get(light_name, 1))
	var state := {"E": float(entry.get("E", 30)), "A": float(entry.get("A", 10)), "H": float(entry.get("H", 6)), "C": float(entry.get("C", 8)), "R": float(entry.get("R", 18)), "Z": 0, "W": water, "K": crate, "reserve": 30}
	var steps: Array = []
	var current_water := water
	for step in 6:
		var multiplier: int = int(MULTIPLIERS[step])
		var shelter := mini(6, current_water + crate)
		var dose := dose_for_shelter(shelter) * multiplier
		state["Z"] = int(state["Z"]) + dose
		var drained := false
		if drain_step == step + 1:
			current_water = maxi(0, current_water - 2)
			drained = true
		var energy_cost := float(rules.get("basic_energy", 1)) + float(heat) + float(light)
		state["E"] = float(state["E"]) - energy_cost
		state["A"] = float(state["A"]) - float(rules.get("breathing_air", 1.25))
		state["R"] = float(state["R"]) - float(rules.get("food_consumption", 1.5))
		var light_delta := light - 1
		var health_delta := light_delta
		var crop_delta := light_delta
		if heat == 0:
			health_delta -= 2
			crop_delta -= 1
		elif heat == 1:
			health_delta -= 1
		if current_water >= 4:
			health_delta -= 1
			crop_delta -= 1
		state["H"] = _apply_non_resurrecting(int(state["H"]), health_delta, 10)
		state["C"] = _apply_non_resurrecting(int(state["C"]), crop_delta, 10)
		steps.append({"step": step + 1, "multiplier": multiplier, "water_at_exposure": current_water + (2 if drained else 0), "shelter": shelter, "dose": dose, "drained": drained, "E": float(state["E"]), "A": float(state["A"]), "H": int(state["H"]), "C": int(state["C"]), "R": float(state["R"]), "Z": int(state["Z"])})
	state["W"] = current_water
	var problems := _forecast_problems(state, drain_step)
	return {"steps": steps, "ending": state, "feasible": problems.is_empty(), "problems": problems}

func _forecast_problems(ending: Dictionary, drain_step: int) -> Array:
	var problems: Array = []
	if int(ending.get("Z", 99)) > 6:
		problems.append("Dose %d is above the Chapter 7 limit of 6." % int(ending.get("Z", 0)))
	if float(ending.get("E", 0)) < 0:
		problems.append("Energy runs out before the storm ends.")
	if float(ending.get("A", 0)) <= 0:
		problems.append("Air runs out before the storm ends.")
	if int(ending.get("H", 0)) <= 0:
		problems.append("Crew health reaches zero before the storm ends.")
	if int(ending.get("C", 0)) <= 0:
		problems.append("The living garden is lost before the storm ends.")
	if float(ending.get("R", 0)) <= 0:
		problems.append("Food runs out before the storm ends.")
	if drain_step != 6:
		problems.append("The borrowed water must return in step 6, after that step's exposure.")
	return problems

## The same rule function preview and commit share. Pure: it never changes
## state. A plan commits only when the roster, the seeds, the uplink, the
## 08 schedule and the forecast goals all hold.
func _check_plan(payload: Dictionary = {}) -> Dictionary:
	var plan := {"water": int(payload.get("water", _water)), "crate": int(payload.get("crate", _crate)), "heat": String(payload.get("heat", _heat)), "light": String(payload.get("light", _light)), "drain_step": int(payload.get("drain_step", _drain_step))}
	if payload.has("water") and int(payload.get("water", -1)) != _water:
		return _reject("The payload differs from the board. Set the water first, then commit.")
	if payload.has("crate") and int(payload.get("crate", -1)) != _crate:
		return _reject("The payload differs from the board. Set the crates first, then commit.")
	if payload.has("heat") and String(payload.get("heat", "")) != _heat:
		return _reject("The payload differs from the board. Set the heat first, then commit.")
	if payload.has("light") and String(payload.get("light", "")) != _light:
		return _reject("The payload differs from the board. Set the light first, then commit.")
	if payload.has("drain_step") and int(payload.get("drain_step", -1)) != _drain_step:
		return _reject("The payload differs from the board. Set the drain step first, then commit.")
	if int(payload.get("reserve", 30)) != 30:
		return _reject("The founder reserve of 30 must stay protected.")
	if not bool(payload.get("roster_five", _roster_five)):
		return _reject(String(data().get("feedback", {}).get("roster_not_five", "Confirm the five-person roster first.")))
	if int(payload.get("seed_latched", _seed_latched)) != 2:
		return _reject(String(data().get("feedback", {}).get("seed_not_latched", "Latch both founder-reserve compartments first.")))
	if not bool(payload.get("uplink_isolated", _uplink_isolated)):
		return _reject(String(data().get("feedback", {}).get("uplink_not_isolated", "Isolate the exposed uplink before the peak step.")))
	if String(plan.get("heat", "")) != "COZY" or String(plan.get("light", "")) != "DIM":
		return _reject("The plan schedules COZY heat and DIM light throughout all six steps.")
	var result := forecast(plan)
	var problems: Array = result.get("problems", [])
	if not problems.is_empty():
		return _reject(String(problems[0]))
	var ending: Dictionary = result.get("ending", {})
	return _accept("Plan feasible: six steps, dose %d, ending E%s A%s H%s C%s R%s, reserve 30 safe." % [ending.get("Z", 0), ending.get("E", ""), ending.get("A", ""), ending.get("H", ""), ending.get("C", ""), ending.get("R", "")])

func commit_plan(payload: Dictionary = {}) -> Dictionary:
	if _committed:
		return {"accepted": true, "duplicate": true, "reason": "The storm plan is already committed."}
	var check := _check_plan(payload)
	if not bool(check.get("accepted", false)):
		return check
	_committed = true
	return check

func gate_payload() -> Dictionary:
	return DataScript.gate_payload("p13_commit_plan")

func hint(tier: int) -> String:
	var hints: Array = data().get("hints", {}).get("plan", [])
	if tier < 1 or tier > hints.size():
		return ""
	return String(hints[tier - 1])

## Return the working plan to the witness defaults. A committed plan cannot
## be undone here; the route's checkpoint retry is the way back.
func reset() -> Dictionary:
	if _committed:
		return _reject("A committed plan cannot be undone here.")
	var expected: Dictionary = data().get("expected", {})
	_water = int((expected.get("water", [4, 4, 4, 4, 4, 2]) as Array)[0])
	_crate = int(expected.get("crate", 2))
	_heat = String(expected.get("heat", "COZY"))
	_light = String(expected.get("light", "DIM"))
	_drain_step = 6
	_seed_latched = 0
	_uplink_isolated = false
	_roster_five = false
	_done = []
	return _accept("Plan cleared. The evidence has not changed.")

func preview_action(action: String, payload: Dictionary = {}) -> Dictionary:
	if _done.has(action):
		return {"accepted": true, "duplicate": true, "reason": "P-13 action already has a receipt."}
	match action:
		"p13_share_observations", "p13_label_counterfactual", "p13_record_current_state":
			return _accept("The storm observations are shared and labelled as a what-if.")
		"p13_confirm_five_person_profile":
			if payload.has("occupants"):
				if int(payload.get("occupants", 0)) != 5:
					return _reject("April's card counted four. Today it must count Ferreira too.")
			elif not _roster_five:
				return _reject("April's card counted four. Today it must count Ferreira too.")
			return _accept("Five-person profile confirmed.")
		"p13_confirm_shelter_roster":
			if not _roster_five and not bool(payload.get("roster_five", false)):
				return _reject("Confirm the five-person roster first.")
			return _accept("All five crew are sheltered for the storm.")
		"p13_confirm_shared_resources":
			return _accept("Six shared water units and two crate units confirmed for one schedule.")
		"p13_commit_plan":
			return _check_plan(payload)
		"p13_latch_founder_reserve":
			if int(payload.get("seed_latched", _seed_latched)) != 2:
				return _reject(String(data().get("feedback", {}).get("seed_not_latched", "Latch both founder-reserve compartments first.")))
			return _accept("Both founder-reserve compartments latched: 15 + 15 = 30 protected.")
		"p13_verify_water_shield":
			if int(payload.get("water", _water)) + int(payload.get("crate", _crate)) < 6:
				return _reject(String(data().get("feedback", {}).get("shelter_too_low", "Shield below 6 doses the crew.")))
			return _accept("Water shield verified: W%d in shelter." % int(payload.get("water", _water)))
		"p13_verify_crate_shield":
			if int(payload.get("crate", _crate)) < 1:
				return _reject("No crate shielding is installed.")
			return _accept("Crate shield verified: K%d installed through the last exposure." % int(payload.get("crate", _crate)))
		"p13_verify_drain_order":
			if int(payload.get("drain_step", _drain_step)) != 6:
				return _reject(String(data().get("feedback", {}).get("early_drain", "The drain waits until step 6, after that step's exposure.")))
			return _accept("Drain order verified: return the water after the sample, not before.")
	return _reject("Unknown P-13 action: " + action)

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
		"p13_confirm_five_person_profile":
			if not _roster_five:
				return confirm_roster(5)
			return _accept("Five-person profile already confirmed.")
		"p13_confirm_shelter_roster":
			_roster_five = true
			return _accept("All five crew are sheltered for the storm.")
		"p13_commit_plan":
			return commit_plan(payload)
		"p13_latch_founder_reserve":
			return latch_seed(2)
		"p13_verify_water_shield", "p13_verify_crate_shield", "p13_verify_drain_order":
			return _accept("P-13 verification recorded once.")
	return _accept("P-13 action recorded once.")

func flags() -> Dictionary:
	var result := forecast()
	var ending: Dictionary = result.get("ending", {})
	return {
		"p13_water": _water,
		"p13_crate": _crate,
		"p13_heat": _heat,
		"p13_light": _light,
		"p13_drain_step": _drain_step,
		"p13_seed_latched": _seed_latched,
		"p13_uplink_isolated": _uplink_isolated,
		"p13_roster_five": _roster_five,
		"p13_feasible": bool(result.get("feasible", false)),
		"p13_ending": ending,
		"p13_committed": _committed,
		"p13_complete": _committed,
		"storm_prepared_pending": _committed,
		"protected_founder_seeds30": _seed_latched == 2,
	}

func snapshot() -> Dictionary:
	return {"schema_version": 1, "water": _water, "crate": _crate, "heat": _heat, "light": _light, "drain_step": _drain_step, "seed_latched": _seed_latched, "uplink_isolated": _uplink_isolated, "roster_five": _roster_five, "committed": _committed, "done": _done.duplicate()}

func restore(state: Dictionary) -> Dictionary:
	var version = state.get("schema_version", 1)
	if not (version is int or version is float) or float(version) != 1.0:
		return _reject("P-13 snapshot is incompatible.")
	if not (state.get("water", null) is int or state.get("water", null) is float) or int(state.get("water", -1)) not in [0, 2, 4, 5, 6]:
		return _reject("P-13 water must be 0, 2, 4, 5 or 6.")
	if not (state.get("crate", null) is int or state.get("crate", null) is float) or int(state.get("crate", -1)) < 0 or int(state.get("crate", 99)) > 2:
		return _reject("P-13 crate shielding must be 0 to 2.")
	if String(state.get("heat", "")) not in HEAT_LEVELS or String(state.get("light", "")) not in LIGHT_LEVELS:
		return _reject("P-13 heat and light must be named settings.")
	if not (state.get("drain_step", null) is int or state.get("drain_step", null) is float) or int(state.get("drain_step", -1)) < 0 or int(state.get("drain_step", 99)) > 6:
		return _reject("P-13 drain step must be 0 to 6.")
	if not (state.get("seed_latched", null) is int or state.get("seed_latched", null) is float) or int(state.get("seed_latched", -1)) < 0 or int(state.get("seed_latched", 99)) > 2:
		return _reject("P-13 seed compartments must be 0 to 2.")
	for key in ["uplink_isolated", "roster_five", "committed"]:
		if not state.get(key, null) is bool:
			return _reject("P-13 preparation must be boolean.")
	if not state.get("done", []) is Array:
		return _reject("P-13 receipts must be an array.")
	for action in state.get("done", []):
		if not action is String:
			return _reject("P-13 receipts must be strings.")
	_water = int(state.get("water", 4))
	_crate = int(state.get("crate", 2))
	_heat = String(state.get("heat", "COZY"))
	_light = String(state.get("light", "DIM"))
	_drain_step = int(state.get("drain_step", 6))
	_seed_latched = int(state.get("seed_latched", 0))
	_uplink_isolated = bool(state.get("uplink_isolated", false))
	_roster_five = bool(state.get("roster_five", false))
	_committed = bool(state.get("committed", false))
	_done.assign(state.get("done", []))
	return _accept("P-13 restored.")

func _apply_non_resurrecting(value: int, delta: int, cap: int) -> int:
	if value <= 0:
		return 0
	return clampi(value + delta, 0, cap)

func _accept(reason: String) -> Dictionary:
	return {"accepted": true, "duplicate": false, "reason": reason}

func _reject(reason: String) -> Dictionary:
	return {"accepted": false, "duplicate": false, "reason": reason}
