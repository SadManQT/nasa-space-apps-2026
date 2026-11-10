extends RefCounted
class_name ExtendedPuzzleLedger

const P05 = preload("res://scripts/puzzles/p05_falling_pressure.gd")
const P06 = preload("res://scripts/puzzles/p06_harvest_future.gd")
const Chapter4 = preload("res://scripts/puzzles/chapter4_puzzles.gd")
const Chapter6 = preload("res://scripts/puzzles/chapter6_puzzles.gd")
const Chapter8 = preload("res://scripts/puzzles/chapter8_puzzles.gd")

var _receipts := {}
var _p05: RefCounted = P05.new()
var _p06: RefCounted = P06.new()

## The panel and the ledger use the same authoritative Chapter 3 selections.
func p05() -> RefCounted:
	return _p05

func p06() -> RefCounted:
	return _p06

func preview(puzzle_id: String, action: String, payload: Dictionary = {}) -> Dictionary:
	if _receipts.has(action):
		if action.begins_with("p05_") or action.begins_with("p06_"):
			var receipt: Dictionary = _receipts[action]
			if String(receipt.get("puzzle_id", "")) != puzzle_id or receipt.get("payload", {}) != payload:
				return {"accepted": false, "duplicate": false, "reason": "That Chapter 3 action is already recorded with a different decision."}
		return {"accepted": true, "duplicate": true, "reason": "Puzzle action already has a receipt."}
	var error := _validate(puzzle_id, action, payload)
	if not error.is_empty():
		return {"accepted": false, "duplicate": false, "reason": error}
	return {"accepted": true, "duplicate": false, "reason": "Puzzle action preview accepted.", "puzzle_id": puzzle_id, "action": action}

func commit(puzzle_id: String, action: String, payload: Dictionary = {}) -> Dictionary:
	var check := preview(puzzle_id, action, payload)
	if not bool(check.get("accepted", false)):
		return check
	if bool(check.get("duplicate", false)):
		return check
	_receipts[action] = {"puzzle_id": puzzle_id, "payload": payload.duplicate(true)}
	return {"accepted": true, "duplicate": false, "reason": "Puzzle action committed once.", "puzzle_id": puzzle_id, "action": action}

func has_receipt(action: String) -> bool:
	return _receipts.has(action)

func flags() -> Dictionary:
	var result := {}
	for action in _receipts.keys():
		result[String(action) + "_ledger_recorded"] = true
	return result

func snapshot() -> Dictionary:
	return {"schema_version": 1, "receipts": _receipts.duplicate(true), "p05": _p05.snapshot(), "p06": _p06.snapshot()}

func restore(data: Dictionary) -> Dictionary:
	var version = data.get("schema_version", null)
	if not (version is int or version is float) or float(version) != 1.0:
		return {"accepted": false, "reason": "Extended puzzle ledger snapshot is incompatible."}
	if not data.get("receipts", null) is Dictionary:
		return {"accepted": false, "reason": "Extended puzzle receipts must be a Dictionary."}
	var receipts: Dictionary = data.receipts
	var staged_p05: RefCounted = P05.new()
	var staged_p06: RefCounted = P06.new()
	for action in receipts:
		if not action is String or not receipts[action] is Dictionary:
			return {"accepted": false, "reason": "Extended puzzle receipt has an invalid action."}
		var receipt: Dictionary = receipts[action]
		if not receipt.get("puzzle_id", null) is String or not receipt.get("payload", null) is Dictionary:
			return {"accepted": false, "reason": "Extended puzzle receipt has an invalid payload."}
		if String(action).begins_with("p05_") or String(action).begins_with("p06_"):
			var is_p05 := String(action).begins_with("p05_")
			var model: RefCounted = staged_p05 if is_p05 else staged_p06
			if String(receipt.puzzle_id) != ("P-05" if is_p05 else "P-06") or not model.is_step(action) or not String(model.validate_action(action, receipt.payload)).is_empty():
				return {"accepted": false, "reason": "Chapter 3 save contains an invalid puzzle receipt."}
	if data.has("p05"):
		if not data.p05 is Dictionary:
			return {"accepted": false, "reason": "P-05 save state must be a Dictionary."}
		var p05_result: Dictionary = staged_p05.restore(data.p05)
		if not bool(p05_result.get("accepted", false)):
			return p05_result
	if data.has("p06"):
		if not data.p06 is Dictionary:
			return {"accepted": false, "reason": "P-06 save state must be a Dictionary."}
		var p06_result: Dictionary = staged_p06.restore(data.p06)
		if not bool(p06_result.get("accepted", false)):
			return p06_result
	_receipts = data.get("receipts", {}).duplicate(true)
	_p05 = staged_p05
	_p06 = staged_p06
	return {"accepted": true, "reason": "Extended puzzle ledger restored."}

func _validate(puzzle_id: String, action: String, payload: Dictionary) -> String:
	if puzzle_id.is_empty() or action.is_empty():
		return "Every extended puzzle action needs a stable puzzle and action ID."
	if action.begins_with("p05_") or action.begins_with("p06_"):
		var model: RefCounted = _p05 if action.begins_with("p05_") else _p06
		var expected_id := "P-05" if action.begins_with("p05_") else "P-06"
		if puzzle_id != expected_id:
			return "Puzzle ID does not match this Chapter 3 operation."
		var reason: String = model.validate_action(action, payload)
		if not reason.is_empty():
			return reason
		if action.begins_with("p05_"):
			return _validate_p05_sequence(action, payload)
		return ""
	# P-07, P-08, P-11, P-12, P-15 and P-16: the player's own decisions, checked against
	# the answer keys in res://resources/campaign/profiles/campaign_rules.json (never pre-filled).
	if Chapter4.is_step(action):
		return Chapter4.validate(action, payload)
	if Chapter6.is_step(action):
		return Chapter6.validate(action, payload)
	if Chapter8.is_step(action):
		return Chapter8.validate(action, payload)
	match action:
		"p07_choose_route_b":
			if String(payload.get("route", "")) != "B": return "Route B is the only route within both slope and return-reserve limits."
		"p07_verify_slope":
			if int(payload.get("slope", -1)) > 15 or int(payload.get("slope", -1)) < 0: return "The surveyed route must remain at or below the 15 degree game limit."
		"p07_verify_return_reserve":
			if int(payload.get("reserve", -1)) < 30: return "The rover must retain at least 30 return-reserve units."
		"p07_set_threshold_12":
			if int(payload.get("reference", -1)) != 2 or int(payload.get("threshold", -1)) != 12: return "P-07 threshold is reference 2 plus 10, or 12."
		"p07_tag_positive_18", "p07_tag_positive_19":
			if int(payload.get("reading", -1)) not in [18, 19]: return "Only readings 18 and 19 are positive in the supplied witness."
		"p07_retain_negative_2":
			if int(payload.get("reading", -1)) != 2: return "Reading 2 is the negative control."
		"p08_warm_cold":
			if String(payload.get("stage", "")) != "cool": return "The sealed warm-up must move from cold to cool first."
		"p08_warm_room":
			if String(payload.get("stage", "")) != "room": return "The sealed warm-up must finish at room stage."
		"p08_inventory_12":
			if int(payload.get("count", -1)) != 12: return "The vault inventory requires twelve distinct specimens."
		"p09_commit_sequence":
			if payload.get("order", []) != ["seedling_chart", "relay_fault", "evacuation_order", "boarding"] or String(payload.get("conclusion", "")) != "ALL_FOUR_RETURNED": return "P-09 requires the timestamp order and supported all-returned conclusion."
		"p10_verify_flashes":
			# 08: at least six verified flashes, both artifacts rejected; all
			# eight with no false report is the Golden observation.
			if int(payload.get("genuine", -1)) < 6 or int(payload.get("genuine", -1)) > 8 or int(payload.get("artifacts_rejected", -1)) != 2: return "P-10 requires six to eight genuine flashes and both persistent artifacts rejected."
		"p11_commit_allocation":
			if int(payload.get("total", -1)) != 7 or not bool(payload.get("essentials", false)) or not bool(payload.get("pump", false)) or not bool(payload.get("camera", false)): return "P-11 requires five essentials plus one pump and one camera for seven units."
		"p12_reset_sequence":
			if payload.get("sequence", []) != ["isolate", "zero", "reset", "reconnect", "camera_test"]: return "P-12 requires isolate, zero/fault check, reset, reconnect and camera-branch test."
		"p13_commit_plan":
			# 08: W4/K2 is the witness; W5/K1 ends identically, so both commit.
			# Water and crate share the shielding job: crate == 6 - water.
			if int(payload.get("water", -1)) < 4 or int(payload.get("water", -1)) > 5 or int(payload.get("crate", -1)) != 6 - int(payload.get("water", -1)) or String(payload.get("heat", "")) != "COZY" or String(payload.get("light", "")) != "DIM" or int(payload.get("reserve", -1)) != 30: return "P-13 requires W4/K2 or W5/K1, COZY/DIM and protected reserve 30."
		"p14_route_reading_1", "p14_route_reading_2":
			if not (payload.get("reading") is int or payload.get("reading") is float) or not is_finite(float(payload.reading)) or float(payload.reading) < 0 or float(payload.reading) >= 1.0: return "P-14 route clearance requires a reading below 1."
	return ""

func _validate_p05_sequence(action: String, payload: Dictionary) -> String:
	if action.begins_with("p05_inspect_") and String(_p05.step(action).get("scene", "")) == "EX-CH03-S02":
		var value = payload.get("phase", null)
		if not (value is int or value is float) or not is_finite(float(value)) or float(value) != float(int(value)):
			return "Choose a whole-number investigation phase."
		var phase := int(value)
		var protocol: Dictionary = _p05.data().get("simulation", {})
		var phase_limit := int(protocol.get("investigation_phases", 4))
		var capacity := int(protocol.get("max_inspections_per_phase", 2))
		if phase < 1 or phase > phase_limit:
			return "Use one of the four investigation phases."
		var inspected := 0
		for recorded in _receipts:
			if String(recorded).begins_with("p05_inspect_") and String(_p05.step(String(recorded)).get("scene", "")) == "EX-CH03-S02":
				inspected += 1
		var expected_phase := int(inspected / capacity) + 1
		if phase != expected_phase:
			return "Use phase %d for this check. The simulator advances after each pair of inspections; phase four is the repair." % expected_phase
		if action == "p05_inspect_annex" and phase < 2:
			return "The annex branch indicator changes after the phase-two aftershock."
	if action == "p05_read_main_t10":
		var inspections := 0
		for recorded in _receipts:
			if String(recorded).begins_with("p05_inspect_"):
				inspections += 1
		if inspections != 6:
			return "Inspect all six candidates before the t10 comparison."
	if action == "p05_verify_annex_isolation" and not _receipts.has("p05_inspect_annex"):
		return "Inspect the annex branch before verifying its automatic isolation."
	if action.begins_with("p05_stable_read_"):
		var index := int(action.trim_prefix("p05_stable_read_"))
		var previous := "p05_reopen_garden_slow" if index == 1 else "p05_stable_read_%d" % (index - 1)
		if not _receipts.has(previous):
			return "Reopen slowly, then log five steady checks in order."
	return ""
