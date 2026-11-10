## P-05/P-06 authored decisions, ledger safety, phase budget, persistence and
## the Chapter 3 panel's actual choice -> preview -> confirm contract.
extends SceneTree

const P05 = preload("res://scripts/puzzles/p05_falling_pressure.gd")
const P06 = preload("res://scripts/puzzles/p06_harvest_future.gd")
const Ledger = preload("res://scripts/puzzles/extended_puzzle_ledger.gd")
const Catalog = preload("res://scripts/missions/extended_gate_catalog.gd")
const PanelScene: PackedScene = preload("res://scenes/ui/chapter3_puzzle_panel.tscn")

class FakeRoute:
	extends RefCounted
	const P05Script = preload("res://scripts/puzzles/p05_falling_pressure.gd")
	const P06Script = preload("res://scripts/puzzles/p06_harvest_future.gd")
	const LedgerScript = preload("res://scripts/puzzles/extended_puzzle_ledger.gd")
	var p05_model: RefCounted
	var p06_model: RefCounted
	var ledger: RefCounted

	func _init() -> void:
		p05_model = P05Script.new()
		p06_model = P06Script.new()
		ledger = LedgerScript.new()

	func p05() -> RefCounted:
		return p05_model

	func p06() -> RefCounted:
		return p06_model

	func chapter3_view(target_id: String) -> Dictionary:
		var model: RefCounted = p05_model if target_id.begins_with("p05_") else p06_model
		var spec: Dictionary = model.step(target_id)
		var scene_data: Dictionary = model.scene(String(spec.get("scene", "")))
		var clues: Array = []
		for raw in scene_data.get("clues", []):
			var clue: Dictionary = raw.duplicate(true)
			var holders: Array = []
			for holder in clue.get("holders", []):
				holders.append(model.role(String(holder)).get("name", holder))
			clue["holder_names"] = holders
			clue["found"] = model.found_clues(String(scene_data.get("id", ""))).has(String(clue.get("id", "")))
			clues.append(clue)
		return {"target_id": target_id, "step": spec, "scene": scene_data, "clues": clues, "puzzle_id": model.puzzle_id_for_step(target_id), "puzzle": model.puzzle(model.puzzle_id_for_step(target_id)), "mission_id": scene_data.get("mission", ""), "data_card": {}, "scenario_datetime": "", "resources": {}, "route": {}, "readings": {}, "selection": model.selection(target_id), "attempt": model.payload_for(target_id), "hints": model.revealed_hints(target_id), "hints_total": model.hint_ladder(target_id).size(), "attempts": model.attempts(target_id), "signed": model.signed_roles(target_id), "committed": ledger.has_receipt(target_id), "prerequisite_reason": "", "first_time": not model.first_time_seen(model.puzzle_id_for_step(target_id))}

	func chapter3_preview(target_id: String, payload: Dictionary) -> Dictionary:
		return ledger.preview("P-05" if target_id.begins_with("p05_") else "P-06", target_id, payload)

var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_content_and_catalog()
	_test_model_and_ledger()
	_test_phase_limits()
	await _test_panel()
	print("P05 P06 PUZZLES RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_content_and_catalog() -> void:
	var a := P05.new()
	var b := P06.new()
	_check(not a.data().is_empty() and not b.data().is_empty(), "both authored content files load")
	for entry in [[a, 1, 6, 33], [b, 7, 12, 19]]:
		var model: RefCounted = entry[0]
		var action_ids: Array = []
		for order in range(int(entry[1]), int(entry[2]) + 1):
			for action in Catalog._actions(3, order):
				action_ids.append(String(action))
			var scene_id := "EX-CH03-S%02d" % order
			var targets: Array = Catalog.targets_for_scene(scene_id)
			var empty_defaults := true
			var plain_labels := true
			for target in targets:
				empty_defaults = empty_defaults and (target.get("payload_defaults", {}) as Dictionary).is_empty()
				plain_labels = plain_labels and not String(target.get("focus_label", "")).is_empty()
			_check(empty_defaults and plain_labels, scene_id + " has player decisions and useful labels")
		action_ids.sort()
		var authored: Array = model.data().steps.keys()
		authored.sort()
		_check(action_ids == authored and authored.size() == int(entry[3]), "all catalog actions have cards in " + model.data().puzzle_id)
		var keys_match := true
		for action in authored:
			var spec: Dictionary = model.step(String(action))
			keys_match = keys_match and model.data().answers.has(action) and P05.KINDS.has(String(spec.get("kind", ""))) and model.scene(String(spec.get("scene", ""))).has("clues")
		_check(keys_match, "each step has an answer, supported control and scene clues")
	_check(int(a.data().simulation.investigation_phases) == 4 and int(a.data().simulation.max_inspections_per_phase) == 2 and float(a.data().simulation.phase_hours_as_abstract_budget) == 7.2, "P-05 uses the four-phase abstract budget")
	_check(int(b.data().simulation.total_seeds) == 42 and int(b.data().simulation.planted) == 12 and int(b.data().simulation.reserve) == 30, "P-06 seed arithmetic comes from content")
	var s02: Array = Catalog.targets_for_scene("EX-CH03-S02")
	var candidate_flags := true
	for target in s02:
		if String(target.target_id).begins_with("p05_inspect_"):
			candidate_flags = candidate_flags and target.required_flags == ["p05_read_return_t0_done"]
	_check(candidate_flags, "six candidates may be inspected in any order after t0 taps")

func _test_model_and_ledger() -> void:
	var a := P05.new()
	var b := P06.new()
	var ledger := Ledger.new()
	var all_good := true
	var all_empty_held := true
	var all_wrong_held := true
	var inspection_index := 0
	for order in range(1, 13):
		for raw_action in Catalog._actions(3, order):
			var action := String(raw_action)
			var model: RefCounted = a if action.begins_with("p05_") else b
			var puzzle_id := "P-05" if action.begins_with("p05_") else "P-06"
			var spec: Dictionary = model.step(action)
			all_empty_held = all_empty_held and not bool(model.payload_for(action).get("accepted", false)) and not bool(ledger.preview(puzzle_id, action, {}).get("accepted", false))
			var wrong: Dictionary = {}
			if String(spec.kind) == "number":
				wrong = {"reading": int(model.data().answers[action].reading) + 1}
				model.select(action, "value", int(model.data().answers[action].reading))
			elif action.begins_with("p05_inspect_") and String(spec.get("scene", "")) == "EX-CH03-S02":
				var phase := int(inspection_index / 2) + 1
				inspection_index += 1
				model.select(action, "option", "phase_%d" % phase)
				wrong = {"candidate": "other", "phase": phase}
			else:
				model.select(action, "option", "supported")
				wrong = spec.options[1].payload
			all_wrong_held = all_wrong_held and not bool(ledger.preview(puzzle_id, action, wrong).get("accepted", false))
			var attempt: Dictionary = model.payload_for(action)
			var result: Dictionary = ledger.commit(puzzle_id, action, attempt.get("payload", {}))
			if not bool(attempt.get("accepted", false)) or not bool(result.get("accepted", false)):
				print("WITNESS DETAIL ", action, " -> ", attempt, " / ", result)
			all_good = all_good and bool(attempt.get("accepted", false)) and bool(result.get("accepted", false))
	_check(all_empty_held, "no Chapter 3 operation accepts an unselected or empty payload")
	_check(all_wrong_held, "every Chapter 3 operation safely holds a wrong reading or decision")
	_check(all_good, "selected P-05/P-06 witness completes all 52 ledger actions")
	_check(not bool(ledger.preview("P-06", "p05_equip_gauge", {"instrument": "mechanical_gauge"}).get("accepted", false)), "puzzle ID mismatch cannot reuse a receipt")
	_check(not bool(Ledger.new().preview("P-05", "p05_read_main_t0", {"reading": "100"}).get("accepted", false)), "numeric witness rejects string coercion")
	_check(not bool(Ledger.new().preview("P-05", "p05_read_main_t0", {"reading": 100.0001}).get("accepted", false)), "direct ledger input cannot approximate a marked gauge reading")
	var held_selection: Dictionary = a.selection("p05_read_main_t0")
	_check(not bool(a.select("p05_read_main_t0", "value", 99.6).accepted) and not bool(a.select("p05_read_main_t0", "value", 100.4).accepted) and a.selection("p05_read_main_t0") == held_selection, "fractional gauge readings are rejected without changing the selection")
	_check(not bool(a.select("p05_read_main_t0", "value", -1).accepted) and not bool(a.select("p05_read_main_t0", "value", 121).accepted), "gauge readings outside the instrument scale are rejected")
	var saved := a.snapshot()
	var restored := P05.new()
	_check(bool(restored.restore(saved).accepted) and restored.selection("p05_equip_gauge") == a.selection("p05_equip_gauge"), "P-05 selected state survives a snapshot")
	var invalid_option: Dictionary = saved.duplicate(true)
	invalid_option.selections["p05_equip_gauge"] = {"option": "invented"}
	_check(not bool(restored.restore(invalid_option).accepted) and restored.snapshot() == saved, "invalid saved option is held without changing the live puzzle")
	_check(bool(a.find_clue("EX-CH03-S03", "c1").accepted) and bool(a.find_clue("EX-CH03-S03", "c1").duplicate), "aftershock evidence files once")
	var hints: Array = [a.reveal_hint("p05_preview_garden_isolation"), a.reveal_hint("p05_preview_garden_isolation"), a.reveal_hint("p05_preview_garden_isolation"), a.reveal_hint("p05_preview_garden_isolation")]
	_check(bool(hints[0].accepted) and bool(hints[1].accepted) and bool(hints[2].accepted) and not bool(hints[3].accepted), "three-tier P-05 hints stop after the procedure")
	var saved_b := b.snapshot()
	var restored_b := P06.new()
	_check(bool(restored_b.restore(saved_b).accepted) and restored_b.selection("p06_allocate_12_30") == b.selection("p06_allocate_12_30"), "P-06 selected state survives a snapshot")
	_check(bool(ledger.restore(ledger.snapshot()).accepted) and ledger.has_receipt("p05_stable_read_5") and ledger.has_receipt("p06_allocate_12_30"), "ledger receipts survive restore")
	var live := Ledger.new()
	live.p05().select("p05_equip_gauge", "option", "supported")
	live.p05().find_clue("EX-CH03-S03", "c1")
	live.p05().reveal_hint("p05_preview_garden_isolation")
	live.p05().count_attempt("p05_equip_gauge")
	live.p05().select("p05_isolate_garden", "option", "supported")
	live.p05().sign_poll("p05_isolate_garden", "amara")
	live.p06().select("p06_count_42", "option", "supported")
	live.commit("P-05", "p05_equip_gauge", {"instrument": "mechanical_gauge"})
	var live_snapshot: Dictionary = live.snapshot()
	var loaded := Ledger.new()
	_check(bool(loaded.restore(live_snapshot).accepted) and loaded.snapshot() == live_snapshot, "ledger saves receipts and both puzzle models together")
	_check(loaded.p05().signed_roles("p05_isolate_garden") == ["amara"] and loaded.p05().found_clues("EX-CH03-S03") == ["c1"] and loaded.p05().attempts("p05_equip_gauge") == 1, "team poll, found clue and attempt survive Continue")
	var malformed: Dictionary = live_snapshot.duplicate(true)
	malformed.p05.selections["p05_equip_gauge"] = {"option": "invented"}
	_check(not bool(live.restore(malformed).accepted) and live.snapshot() == live_snapshot, "malformed nested puzzle state cannot partly restore the ledger")
	_check(not bool(live.restore({}).accepted) and live.snapshot() == live_snapshot, "missing ledger fields cannot erase a receipt")
	_check(bool(Ledger.new().restore({"schema_version": 1, "receipts": {}}).accepted), "legacy ledger saves without Chapter 3 selections still load")
	live.p05().select("p05_isolate_garden", "option", "held")
	_check(live.p05().signed_roles("p05_isolate_garden").is_empty(), "changing a signed choice invalidates the Class poll")

func _test_phase_limits() -> void:
	var ledger := Ledger.new()
	_check(not bool(ledger.preview("P-05", "p05_inspect_tank", {"candidate": "tank", "phase": 2}).accepted), "phase 2 cannot be entered before phase 1")
	_check(not bool(ledger.preview("P-05", "p05_inspect_annex", {"candidate": "annex", "phase": 1}).accepted), "aftershock annex is unavailable in phase 1")
	ledger.commit("P-05", "p05_inspect_tank", {"candidate": "tank", "phase": 1})
	_check(not bool(ledger.preview("P-05", "p05_inspect_garden", {"candidate": "garden", "phase": 2}).accepted), "phase cannot advance before its second inspection")
	ledger.commit("P-05", "p05_inspect_habitat", {"candidate": "habitat", "phase": 1})
	_check(not bool(ledger.preview("P-05", "p05_inspect_garden", {"candidate": "garden", "phase": 1}).accepted), "third inspection in one phase is held")
	_check(bool(ledger.preview("P-05", "p05_inspect_garden", {"candidate": "garden", "phase": 2}).accepted), "next phase can inspect the garden collar")
	_check(not bool(ledger.preview("P-05", "p05_read_main_t10", {"reading": 100}).accepted), "t10 requires all six candidate inspections")
	_check(not bool(ledger.preview("P-05", "p05_stable_read_1", {"main": 100, "garden": 100, "return": 100}).accepted), "steady readings require a prior slow reopen")
	_check(not bool(ledger.preview("P-06", "p06_count_42", {"wells": 6, "total": 41}).accepted), "41 seeds cannot pass the 42-seed witness")
	_check(not bool(ledger.preview("P-06", "p06_allocate_12_30", {"planted": 12, "reserve": 29}).accepted), "29 reserve seeds cannot pass the founder split")

func _test_panel() -> void:
	var route := FakeRoute.new()
	var panel := PanelScene.instantiate()
	root.add_child(panel)
	await process_frame
	var commits: Array = []
	panel.commit_requested.connect(func(id: String, payload: Dictionary) -> void: commits.append({"id": id, "payload": payload}))
	panel.open(route, "p05_equip_gauge", {"class_mode": false})
	_check(not bool(panel.request_commit().accepted), "panel cannot lock an unselected operation")
	panel.choose("option", "held")
	_check(not bool(panel.try_it().accepted), "wrong panel choice is held by the ledger")
	panel.choose("option", "supported")
	_check(bool(panel.try_it().accepted), "player's supported choice previews through the ledger")
	_check(bool(panel.request_commit().accepted) and bool(panel.confirm_commit().accepted), "accepted tried choice can be confirmed")
	_check(commits.size() == 1 and commits[0].id == "p05_equip_gauge" and commits[0].payload.instrument == "mechanical_gauge", "panel emits the selected payload once")
	panel.open(route, "p06_count_42", {"class_mode": false})
	panel.choose("option", "held")
	_check(not bool(panel.try_it().accepted), "P-06 wrong count is held in the same panel")
	panel.choose("option", "supported")
	_check(bool(panel.try_it().accepted), "P-06 six-by-seven count previews")
	panel.open(route, "p05_read_main_t0", {"class_mode": false})
	var quick_read: Button = panel.find_child("Choice_value_100", true, false)
	_check(quick_read != null, "gauge card offers a one-press witnessed value")
	if quick_read != null:
		quick_read.pressed.emit()
		_check(bool(panel.try_it().accepted) and int(panel.last_try().payload.reading) == 100, "quick gauge selection builds the player's reading")
	panel.open(route, "p05_isolate_garden", {"class_mode": true})
	panel.choose("option", "supported")
	_check(not bool(panel.sign("amara").accepted), "Class role cannot sign before the selected plan passes TRY IT")
	panel.try_it()
	_check(not bool(panel.request_commit().accepted), "class mode requires Go/No-Go station signatures")
	for role_id in ["amara", "kai", "mei", "rafi"]:
		panel.sign(role_id)
	_check(bool(panel.request_commit().accepted), "four role signatures clear the safe garden isolation")
	panel.cancel_confirm()
	panel.choose("option", "held")
	_check(route.p05().signed_roles("p05_isolate_garden").is_empty(), "changing the panel choice clears prior Class signatures")
	panel.choose("option", "supported")
	panel.try_it()
	_check(not bool(panel.request_commit().accepted), "restoring the old choice does not restore stale signatures")
	panel.close()
	panel.queue_free()
	await process_frame

func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		print("FAIL ", description)
