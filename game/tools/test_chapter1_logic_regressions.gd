extends SceneTree
const PlantInput = preload("res://tools/support/p01_input_fixture.gd")

const Director = preload("res://scripts/core/campaign_director.gd")
const Route = preload("res://scripts/missions/chapter1_route.gd")
const Gates = preload("res://scripts/missions/chapter1_gate_catalog.gd")
const Simulation = preload("res://scripts/simulation/expedition_simulation.gd")
const State = preload("res://scripts/core/campaign_state.gd")
const PlantPuzzle = preload("res://scripts/missions/p01_commission_plant.gd")
const PlanFixture = preload("res://tools/support/p02_plan_fixture.gd")

var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_plant_payload_and_prerequisites()
	_test_plant_receipt_size()
	_test_restore_and_retry()
	_test_phase_boundaries_and_dates()
	_test_simulation_safety_and_history()
	_test_dated_boundaries_and_terminal_plant()
	print("CHAPTER 1 LOGIC REGRESSIONS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _new_route() -> RefCounted:
	var director := Director.new()
	director.new_campaign()
	var route := Route.new(director)
	PlanFixture.prepare(route)
	return route

func _targets(scene: String) -> Array:
	if scene == "EX-CH01-S03":
		return ["calibrate_probe", "span_probe", "recheck_probe", "inspect_packet", "compare_atmosphere"]
	var ids := []
	for target in Gates.targets_for_scene(scene):
		ids.append(target.target_id)
	return ids

func _reach(route: RefCounted, scene: String) -> void:
	while route.current_scene_id() != scene:
		for target_id in _targets(route.current_scene_id()):
			var action: Dictionary = route.perform(target_id, PlantInput.payload(target_id))
			if not bool(action.get("accepted", false)):
				_check(false, "fixture action rejected: " + target_id + " " + String(action.get("reason", "")))
				return
		var advanced: Dictionary = route.advance_scene()
		if not bool(advanced.get("accepted", false)):
			_check(false, "fixture scene could not advance")
			return

func _test_plant_payload_and_prerequisites() -> void:
	var route := _new_route()
	_reach(route, "EX-CH01-S04")
	route.perform("plant_alo", PlantInput.payload("plant_alo"))
	route.perform("plant_tara", PlantInput.payload("plant_tara"))
	var before: Dictionary = route.director().snapshot()
	var invalid: Dictionary = route.perform("water_alo", {"moisture": 99})
	_check(not bool(invalid.get("accepted", false)) and route.director().snapshot() == before, "out-of-band watering rejects before writing an authoritative receipt")
	var watered: Dictionary = route.perform("water_alo", {"moisture": 55})
	_check(bool(watered.get("accepted", false)) and int(route.snapshot().p01.moisture_alo) == 55, "watering preserves the player's frozen moisture payload")
	before = route.director().snapshot()
	var duplicate: Dictionary = route.perform("water_alo", {"moisture": 55})
	_check(bool(duplicate.get("accepted", false)) and route.director().snapshot() == before, "duplicate physical input changes neither biology nor director state")
	var direct := _new_route()
	direct.start_at("EX-CH01-S07")
	direct.focus("p02_shift1")
	direct.use({"plan": {"shift": _step("DAY", 2, "FULL", "HOLD")}})
	_check(not bool(direct.preview().get("accepted", false)) and int(direct.director().query().current_shift) == 0, "focus/use/preview cannot bypass the role-card prerequisite")
	var spoofed := _new_route()
	_check(not bool(spoofed.perform("commission_result", {}, {"flags": {"commission_route_confirmed": true}}).get("accepted", false)), "caller context cannot invent authoritative prerequisite flags")

func _test_restore_and_retry() -> void:
	var route := _new_route()
	route.perform("commission_route")
	var director_save: Dictionary = route.director().snapshot()
	var route_save: Dictionary = route.snapshot()
	var resumed := _new_route()
	resumed.director().restore_snapshot(JSON.parse_string(JSON.stringify(director_save)))
	resumed.restore(JSON.parse_string(JSON.stringify(route_save)))
	var retried: Dictionary = resumed.retry()
	_check(bool(retried.get("accepted", false)) and not bool(resumed.current_flags().get("commission_route_confirmed", false)) and int(resumed.director().query().state_revision) == 0, "save/restore retains the matching pre-action director and physical retry state")
	var before: Dictionary = route.snapshot()
	var malformed := before.duplicate(true)
	malformed.current_scene_id = "EX-CH01-S02"
	malformed.p01 = {}
	_check(not bool(route.restore(malformed).get("accepted", false)) and route.snapshot() == before, "invalid P01 restore leaves the route and world unchanged")
	for invalid in [{"field": "boundaries", "key": "airlock_exterior", "value": 2}, {"field": "roster", "key": "kai", "value": []}]:
		malformed = before.duplicate(true)
		malformed.world[invalid.field][invalid.key] = invalid.value
		_check(not bool(route.restore(malformed).get("accepted", false)) and route.snapshot() == before, "malformed " + invalid.field + " rejects without mutating live route state")
	malformed = before.duplicate(true)
	malformed.schema_version = 99
	_check(not bool(route.restore(malformed).get("accepted", false)) and route.snapshot() == before, "unsupported route schema rejects without mutation")
	malformed = before.duplicate(true)
	malformed.completed_scene_ids = ["EX-CH01-S12"]
	_check(not bool(route.restore(malformed).get("accepted", false)) and route.snapshot() == before, "a future completion cannot disable a resumed earlier scene")
	for key in ["current_scene_id", "current_scene_index"]:
		malformed = before.duplicate(true)
		malformed[key] = {}
		var rejection: Dictionary = route.restore(malformed)
		_check(rejection.has("accepted") and not bool(rejection.accepted) and route.snapshot() == before, "structured " + key + " rejects before scalar conversion")
	malformed = before.duplicate(true)
	malformed.world.current_scene_id = {}
	var rejection: Dictionary = route.restore(malformed)
	_check(rejection.has("accepted") and not bool(rejection.accepted) and route.snapshot() == before, "structured world scene ID rejects before scalar conversion")
	_reach(route, "EX-CH01-S11")
	for target_id in _targets("EX-CH01-S11"):
		route.perform(target_id, PlantInput.payload(target_id))
	route.retry()
	_check(int(route.director().query().current_shift) == 5 and not bool(route.current_flags().get("final_shifts_resolved", false)), "outcome review does not replace the pre-final-shifts retry checkpoint")
	_check(bool(route.perform("p02_shifts6_7").get("accepted", false)), "retry can resolve the final shifts again without stale receipts")

func _test_plant_receipt_size() -> void:
	var puzzle := PlantPuzzle.new()
	for action in PlantPuzzle.ORDER:
		puzzle.commit(action, "size:" + action, PlantInput.payload(action))
	_check(JSON.stringify(puzzle.snapshot()).length() < 32000, "the twelve planting steps keep a small serializable retry/save payload")

func _test_phase_boundaries_and_dates() -> void:
	var route := _new_route()
	_reach(route, "EX-CH01-S09")
	route.perform("combine_cards")
	route.perform("ack_earth_set")
	var before: Dictionary = route.director().snapshot()
	var short_plan: Dictionary = route.perform("p02_shifts3_4", {"plan": {"shift": _step("COZY", 0, "OFF", "FILL")}})
	_check(not bool(short_plan.get("accepted", false)) and route.director().snapshot() == before, "a two-shift scene rejects a one-shift plan before committing")
	_reach(route, "EX-CH01-S12")
	for target_id in _targets("EX-CH01-S12"):
		route.perform(target_id, PlantInput.payload(target_id))
	route.advance_scene()
	var final: Dictionary = route.director().snapshot()
	_check(String(final.scenario_datetime) == "2046-04-27 06:00 UTC", "dated care and seven explicit 7.2-hour shifts reach the canonical sunrise")
	_check(String(final.plants[0].stage) == "bloom" and String(final.plants[1].stage) == "bud", "sunrise advances Alo to first bloom while Tara waits until April 30")
	_check(bool(route.chapter_ready().get("ready", false)), "the safe complete route still unlocks Chapter 2")

func _test_simulation_safety_and_history() -> void:
	var sim := Simulation.new()
	var unsafe: Dictionary = sim.preview(sim.entry_profile(), {"shifts": [_step("DAY", 2, "FULL", "HOLD"), _step("DAY", 0, "FULL", "HOLD"), _step("COZY", 0, "OFF", "HOLD"), _step("COZY", 0, "OFF", "HOLD"), _step("COZY", 0, "OFF", "WAIT"), _step("COZY", 0, "OFF", "HOLD"), _step("COZY", 0, "OFF", "HOLD")]})
	_check(String(unsafe.get("ending", "")) == "MISSION_STOPPED" and int(unsafe.snapshot.current_shift) == 6, "cumulative exposure above three stops before the remaining shift")
	var profile: Dictionary = sim.entry_profile()
	profile.current_shift = 5
	profile.resources.E = 10
	profile.resources.A = 6
	profile.resources.H = 7
	profile.resources.W = 4
	profile.resources.Z = 1
	profile.blackout_count = 1
	var prior_blackout: Dictionary = sim.preview(profile, {"shifts": [_step("COZY", 0, "DIM", "DRAIN"), _step("COZY", 0, "DIM", "DRAIN")]})
	_check(String(prior_blackout.ending) == "BLOOM" and int(prior_blackout.snapshot.blackout_count) == 1, "a partial-plan replay keeps earlier blackouts and cannot award Golden")
	profile = sim.entry_profile()
	profile.current_shift = 2
	profile.resources.A = 1
	var stopped: Dictionary = sim.commit(profile, "logic-stop", 0, {"shift": _step("COZY", 0, "OFF", "HOLD")})
	var continued: Dictionary = sim.preview(stopped.snapshot, {"shift": _step("COZY", 2, "OFF", "HOLD")})
	_check(not bool(continued.get("accepted", false)), "an air-failure attempt cannot restart without checkpoint retry")
	profile = sim.entry_profile()
	profile.resources.R = 0.5
	var hungry: Dictionary = sim.preview(profile, {"shift": _step("DAY", 0, "OFF", "HOLD")})
	_check(String(hungry.get("ending", "")) == "MISSION_STOPPED" and float(hungry.final_state.R) >= 0.0, "insufficient food requests resupply without creating negative stores")
	var bad_state := State.new_snapshot()
	bad_state.resources.E = "fourteen"
	_check(not State.is_compatible(bad_state), "director compatibility rejects malformed numeric resource values")

func _test_dated_boundaries_and_terminal_plant() -> void:
	var director := Director.new()
	director.new_campaign()
	var before := director.snapshot()
	var invalid_date := _command(director, "bad-date", "advance_time", {"scenario_datetime": "tomorrow"})
	_check(not bool(director.commit(invalid_date).get("accepted", false)) and director.snapshot() == before, "invalid scenario dates cannot enter state through a dated transition")
	var bad_state := before.duplicate(true)
	bad_state.scenario_datetime = "2046-02-30 10:00 UTC"
	_check(not State.is_compatible(bad_state), "restore rejects impossible calendar dates before a simulation parse")
	for key in ["care_history", "care_receipts", "stress"]:
		bad_state = before.duplicate(true)
		bad_state.plants[0][key] = {} if key == "care_history" else []
		_check(not State.is_compatible(bad_state), "restore rejects malformed biological " + key + " before a care operation")
	var failing := before.duplicate(true)
	failing.current_shift = 2
	failing.resources.H = 1
	director.restore_snapshot(failing)
	director.commit(_command(director, "plant-loss", "commit_shift", {"shift": _step("COLD", 0, "OFF", "HOLD")}))
	_check(int(director.query().resources.H) == 0 and not bool(director.snapshot().plants[0].alive), "zero-health Alo is terminal in the biological ledger as well as the resource gauge")
	var care: Dictionary = director.commit(_command(director, "care-after-loss", "plant_care", {"individual_id": "ALO-01", "care_id": "water"}))
	_check(not bool(care.get("accepted", false)), "care cannot resurrect a lost Alo individual")
	director.restore_checkpoint()
	_check(int(director.query().resources.H) == 1 and bool(director.snapshot().plants[0].alive), "rejected care does not overwrite the earlier safe retry checkpoint")

func _command(director: RefCounted, id: String, verb: String, payload: Dictionary) -> Dictionary:
	return {"command_id": id, "issuer": "logic-test", "owning_mission_id": "EX-M0103", "owning_scene_id": "EX-CH01-S07", "expected_state_revision": int(director.query().state_revision), "target_id": "fixture", "verb": verb, "payload": payload}

func _step(heat, oxygen: int, light, transfer: String) -> Dictionary:
	return {"heat": heat, "air_production": oxygen, "light": light, "transfer": transfer}

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)
