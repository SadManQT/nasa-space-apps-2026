## P-13 / P-14 interactive panels (M3-7P): the data files parse and agree
## with 08/22/24, the gate catalog no longer pre-fills these two puzzles,
## the models accept correct play and reject wrong and boundary inputs with
## the contradiction named, the ledger agrees with the models, and both
## panels drive a full open / Try it / Lock in / observed-result flow.
extends SceneTree

const GateCatalog = preload("res://scripts/missions/extended_gate_catalog.gd")
const PuzzleData = preload("res://scripts/puzzles/puzzle_data.gd")
const P13Script = preload("res://scripts/puzzles/p13_storm_plan.gd")
const P14Script = preload("res://scripts/puzzles/p14_storm_execution.gd")
const LedgerScript = preload("res://scripts/puzzles/extended_puzzle_ledger.gd")
const P13PanelScene: PackedScene = preload("res://scenes/ui/puzzle_p13_panel.tscn")
const P14PanelScene: PackedScene = preload("res://scenes/ui/puzzle_p14_panel.tscn")
const P13_PATH := "res://resources/campaign/content/p13_storm_plan.json"
const P14_PATH := "res://resources/campaign/content/p14_storm_execution.json"
const CATALOG_PATH := "res://resources/campaign/content/campaign_catalog.json"
const CARDS_PATH := "res://resources/campaign/content/mission_data_cards.json"
const SOURCES_PATH := "res://resources/data/nasa/puzzle_sources.json"
const DESIGN_PATH := "res://../game-design/08_PUZZLE_DESIGNS.md"

var checks := 0
var failures := 0
var lines := {}
var design := ""
var _captured: Dictionary = {}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for line in _json(CATALOG_PATH).get("dialogue", []):
		lines[String(line.id)] = String(line.text)
	design = FileAccess.get_file_as_string(ProjectSettings.globalize_path(DESIGN_PATH))
	_check(design.contains("## P-13") and design.contains("## P-14"), "08 puzzle design is readable")
	var p13 := _json(P13_PATH)
	var p14 := _json(P14_PATH)
	_common(p13)
	_common(p14)
	_p13(p13)
	_p14(p14)
	_model_p13()
	_model_p14()
	_ledger_agreement()
	root.size = Vector2i(1280, 720)
	await process_frame
	await _panel_p13()
	await _panel_p14()
	print("P13 P14 PANELS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _common(data: Dictionary) -> void:
	var puzzle := String(data.get("puzzle_id", ""))
	_check(int(data.get("schema_version", 0)) == 1, puzzle + " schema_version 1")
	var allowed: Array = _json(SOURCES_PATH).puzzles.get(puzzle, []).duplicate()
	var cards: Dictionary = _json(CARDS_PATH).missions
	for scene in data.scenes:
		allowed.append_array(cards.get(scene.mission_id, {}).get("source_ids", []))
	for id in data.source_ids:
		_check(allowed.has(id) and FileAccess.file_exists("res://resources/data/nasa/%s.json" % id), "%s source %s is registered" % [puzzle, id])
	var scene_ids := []
	for scene in data.scenes:
		var gate := GateCatalog.gate(scene.scene_id)
		_check(not gate.is_empty() and gate.mission_id == scene.mission_id and gate.room_id == scene.room_id, "%s scene %s matches gate catalog" % [puzzle, scene.scene_id])
		scene_ids.append(scene.scene_id)
	for stage in ["learn", "apply", "twist"]:
		var block: Dictionary = data.stages.get(stage, {})
		_check(not block.is_empty() and not String(block.get("goal", "")).is_empty(), "%s has %s stage" % [puzzle, stage])
		for id in block.get("scenes", []):
			_check(scene_ids.has(id), "%s %s scene %s listed" % [puzzle, stage, id])
	var clue_ids := []
	for clue in data.clues:
		clue_ids.append(clue.id)
		_check(scene_ids.has(clue.scene_id), "%s clue %s scene" % [puzzle, clue.id])
		match String(clue.kind):
			"line": _check(lines.get(clue.get("line_id", ""), "") == clue.text, "%s clue %s quotes catalog line" % [puzzle, clue.id])
			"data_card": _check(data.source_ids.has(clue.get("source_id", "")), "%s clue %s cites a listed source" % [puzzle, clue.id])
			"object": _check(not String(clue.text).is_empty(), "%s clue %s has text" % [puzzle, clue.id])
			_: _check(false, "%s clue %s kind" % [puzzle, clue.id])
	for step in data.investigation:
		var targets := []
		for target in GateCatalog.targets_for_scene(step.scene_id):
			targets.append(target.target_id)
		_check(targets.has(step.target_id), "%s investigation target %s exists" % [puzzle, step.target_id])
		for id in step.clue_ids:
			_check(clue_ids.has(id), "%s investigation clue %s exists" % [puzzle, step.clue_ids])
		if step.has("choice_id"):
			_check(data.choices.has(step.choice_id), "%s choice %s exists" % [puzzle, step.choice_id])
	for choice in data.choices.values():
		if not choice is Dictionary or not choice.has("options"):
			continue
		var right := 0
		for option in choice.options:
			_check(not String(option.get("feedback", "")).is_empty() or bool(option.correct), "%s option %s has feedback" % [puzzle, option.value])
			right += 1 if bool(option.correct) else 0
		_check(right >= 1, "%s choice has a correct option" % puzzle)
	for tier in data.hints.values():
		_check(tier.size() == 3, puzzle + " hints have three tiers")
	var raw := JSON.stringify(data)
	var bangla := false
	for i in raw.length():
		bangla = bangla or (raw.unicode_at(i) >= 0x0980 and raw.unicode_at(i) <= 0x09FF)
	_check(not bangla, puzzle + " has no Bangla script")

func _p13(data: Dictionary) -> void:
	var water: Array = data.expected.water
	_check(water.size() == 6 and int(water[0]) == 4 and int(water[4]) == 4 and int(water[5]) == 2, "P-13 expected water is 4,4,4,4,4,2")
	var gate: Dictionary = data.gate_payloads["p13_commit_plan"]
	_check(int(gate.get("water", -1)) == 4 and int(gate.get("crate", -1)) == 2 and String(gate.get("heat", "")) == "COZY" and String(gate.get("light", "")) == "DIM" and int(gate.get("reserve", -1)) == 30, "P-13 gate payload is W4 K2 COZY/DIM reserve 30")
	var has_defaults := false
	for target in GateCatalog.targets_for_scene("EX-CH07-S03"):
		if target.get("puzzle_action", "") == "p13_commit_plan":
			has_defaults = not (target.get("payload_defaults", {}) as Dictionary).is_empty()
	_check(not has_defaults, "P-13 commit no longer comes pre-filled from the catalog")
	_check(PuzzleData.gate_payload("p13_commit_plan") == data.gate_payloads["p13_commit_plan"], "P-13 data payload is the route-walk payload")
	for stamp in ["multipliers [1,1,2,2,1,1]", "E30/32", "W [4,4,4,4,4,2]"]:
		_check(design.contains(stamp), "08 P-13 states " + stamp)
	for hint in data.hints.plan:
		_check(design.contains(hint), "P-13 hint is 08 text: " + hint)
	var n: Dictionary = data.numbers
	_check(int(n.entry.E) == 30 and int(n.entry.A) == 10 and int(n.entry.H) == 6 and int(n.entry.C) == 8 and int(n.entry.R) == 18, "P-13 entry matches 08")
	var ending: Dictionary = n.witness_ending
	_check(int(ending.get("E", -1)) == 6 and is_equal_approx(float(ending.get("A", 0)), 2.5) and int(ending.get("H", -1)) == 1 and int(ending.get("C", -1)) == 3 and is_equal_approx(float(ending.get("R", 0)), 9) and int(ending.get("Z", -1)) == 0, "P-13 witness ending is E6 A2.5 H1 C3 R9 Z0")
	var profile: Dictionary = P13Script.profile()
	_check(not profile.is_empty(), "P-13 profile loads")
	_check(int(profile.resources.E) == int(n.entry.E) and int(profile.resources.A) == int(n.entry.A), "P-13 profile entry matches data")
	_check(int(profile.phases) == 6, "P-13 profile has six steps")
	var multipliers: Array = profile.multipliers
	_check(multipliers.size() == 6 and int(multipliers[2]) == 2 and int(multipliers[3]) == 2 and int(multipliers[5]) == 1, "P-13 profile multipliers match 08")
	_check(is_equal_approx(float(profile.breathing_air), 1.25) and is_equal_approx(float(profile.food_consumption), 1.5), "P-13 profile rates are 1.25 air and 1.5 food")

func _p14(data: Dictionary) -> void:
	var readings: Array = data.expected.readings
	_check(readings.size() == 2 and is_equal_approx(float(readings[0]), 0.4) and is_equal_approx(float(readings[1]), 0.3), "P-14 expected readings are 0.4 then 0.3")
	_check(String(data.expected.route) == "F-EXT" and String(data.expected.local) == "PASS" and String(data.expected.direct) == "FAIL" and String(data.expected.external) == "FAIL", "P-14 expected branch results select F-EXT")
	var gate1: Dictionary = data.gate_payloads["p14_route_reading_1"]
	var gate2: Dictionary = data.gate_payloads["p14_route_reading_2"]
	_check(is_equal_approx(float(gate1.get("reading", -1)), 0.4), "P-14 first gate payload is reading 0.4")
	_check(is_equal_approx(float(gate2.get("reading", -1)), 0.3), "P-14 second gate payload is reading 0.3")
	var has_defaults := false
	for target in GateCatalog.targets_for_scene("EX-CH07-S09"):
		if String(target.get("puzzle_action", "")).begins_with("p14_route_reading"):
			has_defaults = has_defaults or not (target.get("payload_defaults", {}) as Dictionary).is_empty()
	_check(not has_defaults, "P-14 route readings no longer come pre-filled from the catalog")
	_check(PuzzleData.gate_payload("p14_route_reading_1") == data.gate_payloads["p14_route_reading_1"], "P-14 first data payload is the route-walk payload")
	_check(PuzzleData.gate_payload("p14_route_reading_2") == data.gate_payloads["p14_route_reading_2"], "P-14 second data payload is the route-walk payload")
	for stamp in ["0.4 then 0.3", "Z<=6"]:
		_check(design.contains(stamp), "08 P-14 states " + stamp)
	for hint in data.hints.execution:
		_check(design.contains(hint), "P-14 hint is 08 text: " + hint)
	var n: Dictionary = data.numbers
	_check(int(n.reading_threshold) == 1 and int(n.reading_gap_minutes) == 10 and is_equal_approx(float(n.readings_unsafe), 1.2), "P-14 threshold is 1, gap ten minutes, 1.2 does not clear")
	var ending: Dictionary = n.witness_ending
	_check(int(ending.get("E", -1)) == 6 and is_equal_approx(float(ending.get("A", 0)), 2.5) and int(ending.get("H", -1)) == 1 and int(ending.get("C", -1)) == 3 and is_equal_approx(float(ending.get("R", 0)), 9) and int(ending.get("Z", -1)) == 0, "P-14 witness ending is E6 A2.5 H1 C3 R9 Z0")

func _ready_p13() -> RefCounted:
	var model = P13Script.new()
	model.confirm_roster(5)
	model.latch_seed(2)
	model.isolate_uplink()
	return model

func _model_p13() -> void:
	var model := P13Script.new()
	_check(not model.preview_action("p13_commit_plan", model.gate_payload()).accepted, "P-13 commit without roster, seeds and uplink rejected")
	_check(not model.confirm_roster(4).accepted, "P-13 four-person roster rejected")
	_check(not model.set_water(3).accepted, "P-13 odd water value rejected")
	var forecast: Dictionary = model.forecast()
	var ending: Dictionary = forecast.get("ending", {})
	_check(bool(forecast.get("feasible", false)) and int(ending.get("E", -1)) == 6 and is_equal_approx(float(ending.get("A", 0)), 2.5) and int(ending.get("H", -1)) == 1 and int(ending.get("C", -1)) == 3 and is_equal_approx(float(ending.get("R", 0)), 9) and int(ending.get("Z", -1)) == 0 and int(ending.get("W", -1)) == 2 and int(ending.get("K", -1)) == 2, "P-13 witness forecast ends E6 A2.5 H1 C3 R9 Z0 W2 K2")
	var ready = _ready_p13()
	_check(ready.preview_action("p13_commit_plan", ready.gate_payload()).accepted, "P-13 witness plan predicts")
	_check(ready.commit_plan(ready.gate_payload()).accepted, "P-13 witness plan commits once")
	_check(bool(ready.commit_plan(ready.gate_payload()).get("duplicate", false)), "P-13 duplicate commit returns the receipt")
	_check(bool(ready.flags().get("p13_complete", false)), "P-13 flags mark the plan complete")
	var copy := P13Script.new()
	_check(copy.restore(JSON.parse_string(JSON.stringify(ready.snapshot()))).accepted and bool(copy.flags().get("p13_complete", false)), "P-13 snapshot restores the committed plan")
	_check(not copy.restore({"schema_version": 2}).accepted, "P-13 bad snapshot version rejected")
	var alt = _ready_p13()
	alt.set_water(5)
	alt.set_crate(1)
	var alt_forecast: Dictionary = alt.forecast()
	var alt_ending: Dictionary = alt_forecast.get("ending", {})
	_check(bool(alt_forecast.get("feasible", false)) and int(alt_ending.get("E", -1)) == 6 and is_equal_approx(float(alt_ending.get("A", 0)), 2.5) and int(alt_ending.get("H", -1)) == 1 and int(alt_ending.get("C", -1)) == 3 and int(alt_ending.get("W", -1)) == 3 and int(alt_ending.get("K", -1)) == 1, "P-13 W5/K1 alternative ends like the witness with W3 K1")
	_check(alt.commit_action("p13_commit_plan", {"water": 5, "crate": 1, "heat": "COZY", "light": "DIM", "reserve": 30}).accepted, "P-13 W5/K1 alternative commits")
	var wide = _ready_p13()
	wide.set_water(6)
	wide.set_crate(0)
	var wide_forecast: Dictionary = wide.forecast()
	_check(not bool(wide_forecast.get("feasible", false)) and int((wide_forecast.get("ending", {}) as Dictionary).get("H", 99)) == 0, "P-13 W6/K0 fails: the sixth step still draws on the garden")
	_check(not wide.commit_plan({"water": 6, "crate": 0, "heat": "COZY", "light": "DIM", "reserve": 30}).accepted, "P-13 W6/K0 does not commit")
	_check(not wide.commit_plan(wide.gate_payload()).accepted and String(wide.commit_plan(wide.gate_payload()).get("reason", "")).contains("differs from the board"), "P-13 payload that disagrees with the board rejected")
	var thin = _ready_p13()
	thin.set_water(2)
	_check(not thin.commit_plan({"water": 2, "crate": 2, "heat": "COZY", "light": "DIM", "reserve": 30}).accepted, "P-13 W2/K2 shield 4 doses the crew")
	var early = _ready_p13()
	early.set_drain_step(3)
	var early_result: Dictionary = early.commit_plan(early.gate_payload())
	_check(not early_result.accepted and String(early_result.get("reason", "")).contains("step 6"), "P-13 early drain rejected with the step 6 order")
	var none = _ready_p13()
	none.set_drain_step(0)
	_check(not none.commit_plan(none.gate_payload()).accepted, "P-13 no drain leaves health at zero")
	var cool = _ready_p13()
	cool.set_heat("COOL")
	var cool_result: Dictionary = cool.commit_plan({"water": 4, "crate": 2, "heat": "COOL", "light": "DIM", "reserve": 30})
	_check(not cool_result.accepted and String(cool_result.get("reason", "")).contains("COZY"), "P-13 COOL heat rejected with the COZY schedule")
	var full = _ready_p13()
	full.set_light("FULL")
	var full_forecast: Dictionary = full.forecast()
	var full_ending: Dictionary = full_forecast.get("ending", {})
	_check(bool(full_forecast.get("feasible", false)) and int(full_ending.get("E", -1)) == 0 and int(full_ending.get("H", -1)) == 7 and int(full_ending.get("C", -1)) == 9, "P-13 FULL light forecasts E0 H7 C9")
	_check(not full.commit_plan({"water": 4, "crate": 2, "heat": "COZY", "light": "FULL", "reserve": 30}).accepted, "P-13 FULL light still needs the COZY/DIM schedule to commit")
	var unready = P13Script.new()
	unready.confirm_roster(5)
	var unready_result: Dictionary = unready.commit_plan(unready.gate_payload())
	_check(not unready_result.accepted and String(unready_result.get("reason", "")).contains("seed"), "P-13 unlatched seeds block the commit")
	_check(not unready.preview_action("p13_verify_water_shield", {"water": 2, "crate": 2}).accepted, "P-13 water shield verification rejects W2")
	_check(unready.preview_action("p13_verify_water_shield", {"water": 4, "crate": 2}).accepted, "P-13 water shield verification accepts W4")
	_check(not unready.preview_action("p13_verify_drain_order", {"drain_step": 3}).accepted, "P-13 drain order verification rejects step 3")
	_check(unready.preview_action("p13_verify_drain_order", {"drain_step": 6}).accepted, "P-13 drain order verification accepts step 6")
	_check(not unready.commit_action("p13_confirm_five_person_profile", {"occupants": 4}).accepted, "P-13 four-person profile action rejected")
	_check(unready.commit_action("p13_confirm_five_person_profile", {"occupants": 5}).accepted, "P-13 five-person profile action commits")

func _model_p14() -> void:
	var model := P14Script.new()
	_check(not model.play_log().accepted, "P-14 log before step 2 rejected")
	_check(not model.test_branch("local").accepted, "P-14 branch test before step 6 rejected")
	_check(not model.record_reading(0.4).accepted, "P-14 reading before the route is selected rejected")
	_check(not model.set_plan({"water": 2, "crate": 2, "heat": "COZY", "light": "DIM", "drain_step": 6}).accepted, "P-14 infeasible plan rejected")
	_check(model.set_plan({"water": 5, "crate": 1, "heat": "COZY", "light": "DIM", "drain_step": 6}).accepted, "P-14 W5/K1 plan accepted")
	var first := model.commit_action("p14_commit_steps_1_2", {})
	_check(first.accepted, "P-14 steps 1 and 2 execute")
	var after_two: Dictionary = model.snapshot().get("resources", {})
	_check(int(after_two.get("E", -1)) == 22 and is_equal_approx(float(after_two.get("A", 0)), 7.5) and int(after_two.get("H", -1)) == 4 and int(after_two.get("C", -1)) == 6 and is_equal_approx(float(after_two.get("R", 0)), 15) and int(after_two.get("Z", -1)) == 0, "P-14 after steps 1 and 2: E22 A7.5 H4 C6 R15 Z0")
	_check(bool(model.commit_action("p14_commit_steps_1_2", {}).get("duplicate", false)), "P-14 duplicate steps 1 and 2 return the receipt")
	_check(not model.commit_action("p14_commit_steps_3_6", {}).accepted, "P-14 steps 3 to 6 before the log rejected")
	_check(model.play_log().accepted, "P-14 log plays in the lull after step 2")
	_check(model.commit_action("p14_record_academy_name", {}).accepted, "P-14 Academy name records from the log")
	_check(model.commit_action("p14_save_progress_report", {}).accepted, "P-14 progress report saves after the first wave")
	var rest := model.commit_action("p14_commit_steps_3_6", {})
	_check(rest.accepted, "P-14 steps 3 to 6 execute")
	var end: Dictionary = model.snapshot().get("resources", {})
	_check(int(end.get("E", -1)) == 6 and is_equal_approx(float(end.get("A", 0)), 2.5) and int(end.get("H", -1)) == 1 and int(end.get("C", -1)) == 3 and is_equal_approx(float(end.get("R", 0)), 9) and int(end.get("Z", -1)) == 0 and int(end.get("W", -1)) == 3 and int(end.get("K", -1)) == 1, "P-14 W5/K1 execution ends E6 A2.5 H1 C3 R9 Z0 W3 K1")
	_check(model.commit_action("p14_confirm_crops_safe", {}).accepted, "P-14 crops confirm safe after the storm")
	_check(model.commit_action("p14_confirm_reserve_30", {}).accepted, "P-14 founder reserve confirms safe after the storm")
	_check(not model.commit_action("p14_diagnose_external_branch", {"route": "F-DIRECT"}).accepted, "P-14 direct branch diagnosis rejected")
	var diagnosed := model.commit_action("p14_diagnose_external_branch", {"route": "F-EXT"})
	_check(diagnosed.accepted, "P-14 external feedthrough diagnosed")
	var branches: Dictionary = model.snapshot().get("branch_results", {})
	_check(String(branches.get("local", "")) == "PASS" and String(branches.get("direct", "")) == "FAIL" and String(branches.get("external", "")) == "FAIL", "P-14 branch results are local PASS, direct FAIL, external FAIL")
	_check(not model.commit_action("p14_route_reading_1", {"reading": 1.2}).accepted, "P-14 reading 1.2 does not clear the route")
	_check(model.commit_action("p14_route_reading_1", {"reading": 0.4}).accepted, "P-14 first reading 0.4 records")
	_check(not model.readings_clear(), "P-14 one reading is insufficient")
	_check(not model.record_reading(0.3, 5).accepted, "P-14 second reading five minutes later rejected")
	_check(model.commit_action("p14_route_reading_2", {"reading": 0.3}).accepted, "P-14 second reading 0.3 records ten minutes later")
	_check(model.readings_clear() and model.route_clear(), "P-14 two clear readings clear the route")
	_check(bool(model.flags().get("p14_complete", false)), "P-14 flags mark the execution complete")
	var copy := P14Script.new()
	_check(copy.restore(JSON.parse_string(JSON.stringify(model.snapshot()))).accepted and int(copy.snapshot().get("steps_done", 0)) == 6 and (copy.snapshot().get("readings", []) as Array).size() == 2, "P-14 snapshot restores six steps and two readings")
	_check(not copy.restore({"schema_version": 2}).accepted, "P-14 bad snapshot version rejected")
	_check(model.commit_action("p14_reconcile_local_stability", {}).accepted, "P-14 local stability reconciles after a clear route")
	_check(model.commit_action("p14_pack_controller", {}).accepted, "P-14 controller packs after a clear route")
	_check(model.commit_action("p14_bench_test", {}).accepted, "P-14 bench test passes after packing")
	_check(model.commit_action("p14_assign_field_team", {}).accepted, "P-14 field team assigns after the bench test")
	_check(model.commit_action("p14_assign_home_team", {}).accepted, "P-14 home team assigns after the bench test")
	_check(model.commit_action("p14_sign_departure_prep", {}).accepted, "P-14 departure preparation signs after both teams assign")
	var witness := P14Script.new()
	witness.commit_action("p14_commit_steps_1_2", {})
	witness.play_log()
	witness.commit_action("p14_commit_steps_3_6", {})
	var witness_end: Dictionary = witness.snapshot().get("resources", {})
	_check(int(witness_end.get("E", -1)) == 6 and is_equal_approx(float(witness_end.get("A", 0)), 2.5) and int(witness_end.get("H", -1)) == 1 and int(witness_end.get("C", -1)) == 3 and is_equal_approx(float(witness_end.get("R", 0)), 9) and int(witness_end.get("Z", -1)) == 0 and int(witness_end.get("W", -1)) == 2 and int(witness_end.get("K", -1)) == 2, "P-14 witness execution ends E6 A2.5 H1 C3 R9 Z0 W2 K2")

func _ledger_agreement() -> void:
	var ledger := LedgerScript.new()
	var gate: Dictionary = PuzzleData.gate_payload("p13_commit_plan")
	_check(ledger.preview("P-13", "p13_commit_plan", gate).accepted, "ledger accepts the P-13 gate payload")
	_check(ledger.preview("P-13", "p13_commit_plan", {"water": 5, "crate": 1, "heat": "COZY", "light": "DIM", "reserve": 30}).accepted, "ledger accepts the W5/K1 alternative")
	_check(not ledger.preview("P-13", "p13_commit_plan", {"water": 6, "crate": 0, "heat": "COZY", "light": "DIM", "reserve": 30}).accepted, "ledger rejects W6/K0")
	_check(not ledger.preview("P-13", "p13_commit_plan", {"water": 2, "crate": 2, "heat": "COZY", "light": "DIM", "reserve": 30}).accepted, "ledger rejects W2/K2")
	_check(not ledger.preview("P-13", "p13_commit_plan", {"water": 4, "crate": 1, "heat": "COZY", "light": "DIM", "reserve": 30}).accepted, "ledger rejects W4/K1")
	_check(not ledger.preview("P-13", "p13_commit_plan", {"water": 4, "crate": 2, "heat": "COOL", "light": "DIM", "reserve": 30}).accepted, "ledger rejects COOL heat")
	_check(not ledger.preview("P-13", "p13_commit_plan", {"water": 4, "crate": 2, "heat": "COZY", "light": "FULL", "reserve": 30}).accepted, "ledger rejects FULL light")
	_check(not ledger.preview("P-13", "p13_commit_plan", {"water": 4, "crate": 2, "heat": "COZY", "light": "DIM", "reserve": 29}).accepted, "ledger rejects reserve 29")
	var committed := ledger.commit("P-13", "p13_commit_plan", gate)
	_check(committed.accepted and bool(ledger.commit("P-13", "p13_commit_plan", gate).get("duplicate", false)), "ledger records the P-13 receipt once")
	_check(ledger.preview("P-14", "p14_route_reading_1", {"reading": 0.4}).accepted, "ledger accepts reading 0.4")
	_check(ledger.preview("P-14", "p14_route_reading_2", {"reading": 0.3}).accepted, "ledger accepts reading 0.3")
	_check(ledger.preview("P-14", "p14_route_reading_1", {"reading": 0.99}).accepted, "ledger accepts any reading below 1")
	_check(not ledger.preview("P-14", "p14_route_reading_1", {"reading": 1.2}).accepted, "ledger rejects reading 1.2")
	_check(not ledger.preview("P-14", "p14_route_reading_1", {"reading": -0.1}).accepted, "ledger rejects a negative reading")

func _panel_p13() -> void:
	_check(ResourceLoader.exists("res://scenes/ui/puzzle_p13_panel.tscn"), "P-13 panel scene exists")
	var model := P13Script.new()
	var panel = P13PanelScene.instantiate()
	root.add_child(panel)
	await process_frame
	_check(panel.open(model, "p13_confirm_five_person_profile"), "P-13 panel opens for the roster")
	_press(panel, "Roster_4")
	_check(not panel.preview().accepted, "P-13 panel four-person roster cannot predict")
	_press(panel, "Roster_5")
	_check(panel.preview().accepted, "P-13 panel five-person roster predicts")
	_check(panel.request_commit().accepted, "P-13 panel roster lock-in opens confirmation")
	_captured = {}
	panel.commit_requested.connect(func(target: String, payload: Dictionary): _captured = {"target": target, "payload": payload})
	_check(panel.confirm_commit().accepted, "P-13 panel roster confirmation dispatches")
	_check(_captured.get("target", "") == "p13_confirm_five_person_profile" and _captured.get("payload", {}) == {"occupants": 5}, "P-13 panel emits the five-person roster")
	_check(model.commit_action("p13_confirm_five_person_profile", _captured.get("payload", {})).accepted, "P-13 panel roster commits through the model")
	panel.discard()
	_check(panel.open(model, "p13_commit_plan"), "P-13 panel opens for the plan")
	_press(panel, "Water_2")
	_check(not panel.preview().accepted and String((panel.find_child("PuzzleNotice", true, false) as Label).text).contains("seed"), "P-13 panel plan without latched seeds names the seeds first")
	model.latch_seed(2)
	model.isolate_uplink()
	_check(not panel.preview().accepted and String((panel.find_child("PuzzleNotice", true, false) as Label).text).contains("Dose 8"), "P-13 panel W2 plan names the dose limit")
	_press(panel, "Water_4")
	_press(panel, "Drain_3")
	_check(not panel.preview().accepted and String((panel.find_child("PuzzleNotice", true, false) as Label).text).contains("step 6"), "P-13 panel early drain names the step 6 order")
	_press(panel, "Drain_6")
	_press(panel, "Heat_COOL")
	_check(not panel.preview().accepted and String((panel.find_child("PuzzleNotice", true, false) as Label).text).contains("COZY"), "P-13 panel COOL heat names the COZY schedule")
	_press(panel, "Heat_COZY")
	_check(panel.preview().accepted, "P-13 panel witness plan predicts")
	_press(panel, "UndoChoices")
	_check(int(model.snapshot().get("water", -1)) == 4 and int(model.snapshot().get("seed_latched", -1)) == 0, "P-13 panel undo clears the plan and preparation")
	model.confirm_roster(5)
	model.latch_seed(2)
	model.isolate_uplink()
	_check(panel.preview().accepted, "P-13 panel witness plan predicts again after undo")
	_check(panel.request_commit().accepted, "P-13 panel lock-in opens confirmation")
	panel.cancel_confirm()
	_check(panel.request_commit().accepted, "P-13 panel lock-in recovers after backing out")
	_captured = {}
	panel.commit_requested.connect(func(target: String, payload: Dictionary): _captured = {"target": target, "payload": payload})
	_check(panel.confirm_commit().accepted, "P-13 panel confirmation dispatches")
	_check(_captured.get("target", "") == "p13_commit_plan" and _payload_matches_gate(_captured.get("payload", {}), model.gate_payload()), "P-13 panel emits the gate payload")
	_check(not panel.is_open(), "P-13 panel closes on confirmation like P-01")
	var result: Dictionary = model.commit_action("p13_commit_plan", _captured.get("payload", {}))
	panel.open(model, "p13_commit_plan")
	panel.committed(result)
	_check(panel.is_open() and String((panel.find_child("PuzzleNotice", true, false) as Label).text).contains("Plan feasible"), "P-13 panel shows the observed result after the route commits")
	_check(not panel.confirm_commit().accepted, "P-13 panel duplicate confirmation never submits twice")
	panel.discard()
	var fresh := P13Script.new()
	panel.open(fresh, "p13_commit_plan")
	_press(panel, "Water_2")
	panel.request_close()
	_check(panel.is_open(), "P-13 panel dirty leave asks before discarding")
	panel.discard()
	_check(not panel.is_open(), "P-13 panel discard closes")
	panel.open(fresh, "p13_commit_plan")
	panel.reveal_hint()
	_check(String((panel.find_child("PuzzleNotice", true, false) as Label).text).begins_with("Hint 1 of 3: Put the seeds inside"), "P-13 panel hint one is the 08 H1")
	panel.reveal_hint()
	_check(String((panel.find_child("PuzzleNotice", true, false) as Label).text).begins_with("Hint 2 of 3: Water and cargo"), "P-13 panel hint two is the 08 H2")
	panel.discard()
	panel.free()
	await process_frame

func _panel_p14() -> void:
	_check(ResourceLoader.exists("res://scenes/ui/puzzle_p14_panel.tscn"), "P-14 panel scene exists")
	var model := P14Script.new()
	var panel = P14PanelScene.instantiate()
	root.add_child(panel)
	await process_frame
	_check(panel.open(model, "p14_commit_steps_1_2"), "P-14 panel opens for steps 1 and 2")
	_press(panel, "ExecuteSteps")
	_check(panel.preview().accepted, "P-14 panel steps 1 and 2 predict")
	_check(panel.request_commit().accepted, "P-14 panel steps lock-in opens confirmation")
	_captured = {}
	panel.commit_requested.connect(func(target: String, payload: Dictionary): _captured = {"target": target, "payload": payload})
	_check(panel.confirm_commit().accepted, "P-14 panel steps confirmation dispatches")
	_check(_captured.get("target", "") == "p14_commit_steps_1_2" and (_captured.get("payload", {}) as Dictionary).is_empty(), "P-14 panel emits an empty payload for the steps")
	var result: Dictionary = model.commit_action("p14_commit_steps_1_2", _captured.get("payload", {}))
	panel.open(model, "p14_commit_steps_1_2")
	panel.committed(result)
	_check(panel.is_open() and String((panel.find_child("PuzzleNotice", true, false) as Label).text).contains("Steps 1 to 2"), "P-14 panel shows the observed steps after the route commits")
	panel.discard()
	_check(panel.open(model, "p14_read_final_log"), "P-14 panel opens for the log")
	_press(panel, "Log_before_step_1")
	_check(not panel.preview().accepted, "P-14 panel early log cannot predict")
	_press(panel, "Log_after_step_2")
	_check(panel.preview().accepted, "P-14 panel lull log predicts")
	_captured = {}
	panel.commit_requested.connect(func(target: String, payload: Dictionary): _captured = {"target": target, "payload": payload})
	panel.request_commit()
	_check(panel.confirm_commit().accepted, "P-14 panel log confirmation dispatches")
	_check(_captured.get("payload", {}) == {"log_timing": "after_step_2"}, "P-14 panel emits the lull log timing")
	_check(model.commit_action("p14_read_final_log", _captured.get("payload", {})).accepted and bool(model.snapshot().get("log_played", false)), "P-14 panel log commits through the model")
	panel.discard()
	_check(panel.open(model, "p14_commit_steps_3_6"), "P-14 panel opens for steps 3 to 6")
	_press(panel, "ExecuteSteps")
	_check(panel.preview().accepted, "P-14 panel steps 3 to 6 predict")
	_captured = {}
	panel.commit_requested.connect(func(target: String, payload: Dictionary): _captured = {"target": target, "payload": payload})
	panel.request_commit()
	_check(panel.confirm_commit().accepted, "P-14 panel last steps confirmation dispatches")
	var rest: Dictionary = model.commit_action("p14_commit_steps_3_6", _captured.get("payload", {}))
	_check(rest.accepted and int(model.snapshot().get("steps_done", 0)) == 6, "P-14 panel last steps commit through the model")
	panel.open(model, "p14_commit_steps_3_6")
	panel.committed(rest)
	_check(String((panel.find_child("PuzzleNotice", true, false) as Label).text).contains("Steps 3 to 6"), "P-14 panel shows the observed last steps")
	panel.discard()
	_check(panel.open(model, "p14_diagnose_external_branch"), "P-14 panel opens for the diagnosis")
	_press(panel, "Branch_F-DIRECT")
	_check(not panel.preview().accepted and String((panel.find_child("PuzzleNotice", true, false) as Label).text).contains("external feedthrough"), "P-14 panel direct branch names the external feedthrough")
	_press(panel, "Branch_F-EXT")
	_check(panel.preview().accepted, "P-14 panel external branch predicts")
	_captured = {}
	panel.commit_requested.connect(func(target: String, payload: Dictionary): _captured = {"target": target, "payload": payload})
	panel.request_commit()
	_check(panel.confirm_commit().accepted, "P-14 panel diagnosis confirmation dispatches")
	_check(_captured.get("payload", {}) == {"route": "F-EXT"}, "P-14 panel emits the F-EXT route")
	_check(model.commit_action("p14_diagnose_external_branch", _captured.get("payload", {})).accepted and String(model.snapshot().get("route", "")) == "F-EXT", "P-14 panel diagnosis commits through the model")
	panel.discard()
	_check(panel.open(model, "p14_route_reading_1"), "P-14 panel opens for the first reading")
	# Node names cannot contain "." so the reading buttons are Reading_0_4 and friends.
	_press(panel, "Reading_1_2")
	_check(not panel.preview().accepted, "P-14 panel reading 1.2 cannot predict")
	_press(panel, "Reading_0_4")
	_check(panel.preview().accepted, "P-14 panel reading 0.4 predicts")
	_captured = {}
	panel.commit_requested.connect(func(target: String, payload: Dictionary): _captured = {"target": target, "payload": payload})
	panel.request_commit()
	_check(panel.confirm_commit().accepted, "P-14 panel first reading confirmation dispatches")
	_check(_captured.get("payload", {}) == {"reading": 0.4}, "P-14 panel emits the first reading 0.4")
	_check(model.commit_action("p14_route_reading_1", _captured.get("payload", {})).accepted, "P-14 panel first reading commits through the model")
	panel.discard()
	_check(panel.open(model, "p14_route_reading_2"), "P-14 panel opens for the second reading")
	_press(panel, "Reading_0_3")
	_check(panel.preview().accepted, "P-14 panel reading 0.3 predicts")
	_captured = {}
	panel.commit_requested.connect(func(target: String, payload: Dictionary): _captured = {"target": target, "payload": payload})
	panel.request_commit()
	_check(panel.confirm_commit().accepted, "P-14 panel second reading confirmation dispatches")
	_check(_captured.get("payload", {}) == {"reading": 0.3}, "P-14 panel emits the second reading 0.3")
	_check(model.commit_action("p14_route_reading_2", _captured.get("payload", {})).accepted and model.readings_clear(), "P-14 panel second reading commits and clears the route")
	panel.discard()
	panel.open(model, "p14_route_reading_2")
	panel.reveal_hint()
	_check(String((panel.find_child("PuzzleNotice", true, false) as Label).text).begins_with("Hint 1 of 3: Finish all three waves"), "P-14 panel hint one is the 08 H1")
	panel.reveal_hint()
	_check(String((panel.find_child("PuzzleNotice", true, false) as Label).text).begins_with("Hint 2 of 3: A working local radio"), "P-14 panel hint two is the 08 H2")
	panel.discard()
	panel.free()
	await process_frame

func _payload_matches_gate(emitted: Dictionary, gate: Dictionary) -> bool:
	return int(emitted.get("water", -1)) == int(gate.get("water", -1)) and int(emitted.get("crate", -1)) == int(gate.get("crate", -1)) and String(emitted.get("heat", "")) == String(gate.get("heat", "")) and String(emitted.get("light", "")) == String(gate.get("light", "")) and int(emitted.get("reserve", -1)) == int(gate.get("reserve", -1))

func _press(panel: Control, button_name: String) -> void:
	var button := panel.find_child(button_name, true, false) as Button
	_check(button != null, "panel has button " + button_name)
	if button != null:
		button.pressed.emit()

func _json(path: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	_check(parsed is Dictionary, "parses " + path)
	return parsed if parsed is Dictionary else {}

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL " + label)
