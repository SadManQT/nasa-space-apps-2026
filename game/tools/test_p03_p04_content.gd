## P-03 / P-04 authored puzzle data (M1-104): both files parse, every scene,
## mission, room, target, action, line and source id already exists, the
## answers match the puzzle scripts and gate payloads, and the numbers match
## game-design/08_PUZZLE_DESIGNS.md and the P-03 profile.
extends SceneTree

const GateCatalog = preload("res://scripts/missions/chapter2_gate_catalog.gd")
const P03Script = preload("res://scripts/puzzles/p03_pollination.gd")
const P04Script = preload("res://scripts/puzzles/p04_recorder_reconstruction.gd")
const P03_PATH := "res://resources/campaign/content/p03_pollination.json"
const P04_PATH := "res://resources/campaign/content/p04_recorder_reconstruction.json"
const CATALOG_PATH := "res://resources/campaign/content/campaign_catalog.json"
const CARDS_PATH := "res://resources/campaign/content/mission_data_cards.json"
const SOURCES_PATH :="res://resources/data/nasa/puzzle_sources.json"
const DESIGN_PATH := "res://../game-design/08_PUZZLE_DESIGNS.md"

var checks := 0
var failures := 0
var lines := {}
var design := ""

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for line in _json(CATALOG_PATH).get("dialogue", []):
		lines[String(line.id)] = String(line.text)
	design = FileAccess.get_file_as_string(ProjectSettings.globalize_path(DESIGN_PATH))
	_check(design.contains("## P-03") and design.contains("## P-04"), "08 puzzle design is readable")
	var p03 := _json(P03_PATH)
	var p04 := _json(P04_PATH)
	for data in [p03, p04]:
		_common(data)
	_p03(p03)
	_p04(p04)
	print("P03 P04 CONTENT RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(1 if failures else 0)

func _common(data: Dictionary) -> void:
	var puzzle := String(data.get("puzzle_id", ""))
	_check(int(data.get("schema_version", 0)) == 1, puzzle + " schema_version 1")
	# Registered for the puzzle, or on the mission data card of one of its missions.
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
			_check(clue_ids.has(id), "%s investigation clue %s exists" % [puzzle, id])
		if step.has("choice_id"):
			_check(data.choices.has(step.choice_id), "%s choice %s exists" % [puzzle, step.choice_id])
	for choice in data.choices.values():
		for options in ([choice.options] if choice.has("options") else choice.get("fields", {}).values()):
			var right := 0
			for option in options:
				_check(not String(option.get("feedback", "")).is_empty() or bool(option.correct), "%s option %s has feedback" % [puzzle, option.value])
				right += 1 if bool(option.correct) else 0
			_check(right >= 1, "%s choice has a correct option" % puzzle)
	for tier in data.hints.values():
		_check(tier.size() == 3, puzzle + " hints have three tiers")
	var raw := JSON.stringify(data)
	_check(not raw.contains("Noor") and not raw.contains("Rahman") and not raw.contains("N.R."), puzzle + " keeps N. anonymous")
	var bangla := false
	for i in raw.length():
		bangla = bangla or (raw.unicode_at(i) >= 0x0980 and raw.unicode_at(i) <= 0x09FF)
	_check(not bangla, puzzle + " has no Bangla script")

func _p03(data: Dictionary) -> void:
	var order := []
	for run in P03Script.RUN_STEPS.keys():
		order.append_array(P03Script.RUN_STEPS[run])
	var steps := []
	for step in data.steps:
		steps.append(step.action)
	_check(steps == order, "P-03 steps follow the script order")
	var profile: Dictionary = P03Script.profile()
	var n: Dictionary = data.numbers
	for key in ["E", "A", "H", "C", "R"]:
		_check(float(n.entry[key]) == float(profile.resources[key]), "P-03 entry %s matches profile" % key)
	_check(float(n.per_reciprocal_cycle.E) == float(profile.sampled.cycle_energy) and float(n.per_reciprocal_cycle.A) == float(profile.sampled.cycle_air), "P-03 cycle charge matches profile")
	_check(float(n.background_food.supply_min) == float(profile.background.supply) and float(n.background_food.total_consumption) == float(profile.background.total_consumption), "P-03 background food matches profile")
	for i in 3:
		_check(String(profile.sampled.dates[i]).begins_with(n.run_dates[i]), "P-03 run date %d matches profile" % (i + 1))
	var care := ["2046-04-30"]
	for day in range(2, 8):
		care.append("2046-05-%02d" % (day - 1))
	_check(n.care_dates == care, "P-03 care dates match the script")
	var e: Dictionary = n.entry
	var w: Dictionary = n.after_three_sampled_operations
	for text in ["E%d/%d,A%d/%d,H%d,C%d,R%d" % [e.E, e.E_max, e.A, e.A_max, e.H, e.C, e.R], "E%d,A%d,H%d,C%d,R%s" % [w.E, w.A, w.H, w.C, str(w.R)], "least%d" % n.background_food.supply_min, "consumption%d" % n.background_food.total_consumption, "leaves%d" % n.background_food.remaining, "E%d/A%d" % [n.per_reciprocal_cycle.E, n.per_reciprocal_cycle.A], "days 1, 4 and 7"]:
		_check(design.contains(text), "08 P-03 states " + text)
	for hint in data.hints.runs:
		_check(design.contains(hint), "P-03 hint is 08 text: " + hint)
	var defaults := {}
	for target in GateCatalog.targets_for_scene("EX-CH02-S06"):
		if target.get("puzzle_action", "") == "p03_record_prediction":
			defaults = target.payload_defaults
	for field in ["prediction", "reason", "future_test"]:
		var hit := false
		for option in data.choices.prediction.fields[field]:
			hit = hit or (bool(option.correct) and option.value == defaults.get(field, null))
		_check(hit, "P-03 prefilled %s is a correct option" % field)

func _p04(data: Dictionary) -> void:
	_check(data.expected == P04Script.EXPECTED, "P-04 expected tokens match the script")
	_check(design.contains("A.DATE=%s; B.DEVICE=%s; C.CHANNEL=%s" % [data.expected.date, data.expected.device, data.expected.channel]), "08 P-04 states the token answer")
	for hint in data.hints.tokens:
		_check(design.contains(hint), "P-04 hint is 08 text: " + hint)
	var actions := []
	for scene_id in ["EX-CH02-S09", "EX-CH02-S10", "EX-CH02-S11"]:
		for target in GateCatalog.targets_for_scene(scene_id):
			actions.append(target.get("puzzle_action", ""))
			if target.has("payload_defaults"):
				_check(target.payload_defaults.value == data.expected[String(target.puzzle_action).trim_prefix("p04_assign_")], "P-04 prefilled %s matches" % target.puzzle_action)
	for step in data.steps:
		_check(actions.has(step.action), "P-04 step %s is a catalog action" % step.action)
	var labels := {}
	for label in data.source_labels:
		labels[label.id] = label
		_check(data.expected[label.field] == label.value, "P-04 source label %s value" % label.id)
	for field in ["date", "device", "channel"]:
		for option in data.choices[field].options:
			var puzzle := P04Script.new()
			var accepted := bool(puzzle.preview_action(data.choices[field].action, {"value": option.value}).accepted)
			_check(accepted == bool(option.correct), "P-04 %s option %s agrees with the script" % [field, option.value])
			_check(labels.has(option.source_label_id), "P-04 %s option names a source label" % field)

func _json(path: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	_check(parsed is Dictionary, "parses " + path)
	return parsed if parsed is Dictionary else {}

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		print("FAIL " + label)
