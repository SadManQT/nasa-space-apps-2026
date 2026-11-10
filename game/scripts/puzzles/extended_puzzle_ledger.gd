extends RefCounted
class_name ExtendedPuzzleLedger

const Chapter4 = preload("res://scripts/puzzles/chapter4_puzzles.gd")
const Chapter6 = preload("res://scripts/puzzles/chapter6_puzzles.gd")
const Chapter8 = preload("res://scripts/puzzles/chapter8_puzzles.gd")

var _receipts := {}

func preview(puzzle_id: String, action: String, payload: Dictionary = {}) -> Dictionary:
	if _receipts.has(action):
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
	return {"schema_version": 1, "receipts": _receipts.duplicate(true)}

func restore(data: Dictionary) -> Dictionary:
	var version = data.get("schema_version", 1)
	if not (version is int or version is float) or float(version) != 1.0:
		return {"accepted": false, "reason": "Extended puzzle ledger snapshot is incompatible."}
	if not data.get("receipts", {}) is Dictionary:
		return {"accepted": false, "reason": "Extended puzzle receipts must be a Dictionary."}
	_receipts = data.get("receipts", {}).duplicate(true)
	return {"accepted": true, "reason": "Extended puzzle ledger restored."}

func _validate(puzzle_id: String, action: String, payload: Dictionary) -> String:
	if puzzle_id.is_empty() or action.is_empty():
		return "Every extended puzzle action needs a stable puzzle and action ID."
	# P-07, P-08, P-11, P-12, P-15 and P-16: the player's own decisions, checked against
	# the answer keys in res://resources/campaign/profiles/campaign_rules.json (never pre-filled).
	if Chapter4.is_step(action):
		return Chapter4.validate(action, payload)
	if Chapter6.is_step(action):
		return Chapter6.validate(action, payload)
	if Chapter8.is_step(action):
		return Chapter8.validate(action, payload)
	match action:
		"p05_read_main_t0", "p05_read_main_t10":
			if int(payload.get("reading", -1)) != 100: return "The main trunk witness must read 100."
		"p05_read_garden_t0":
			if int(payload.get("reading", -1)) != 82: return "The first garden witness must read 82."
		"p05_read_garden_t10":
			if int(payload.get("reading", -1)) != 74: return "The falling garden witness must read 74."
		"p05_read_return_t0", "p05_read_return_t10":
			if int(payload.get("reading", -1)) != 100: return "The return trunk witness must read 100."
		"p05_stable_read_1", "p05_stable_read_2", "p05_stable_read_3", "p05_stable_read_4", "p05_stable_read_5":
			if int(payload.get("main", -1)) != 100 or int(payload.get("garden", -1)) != 100 or int(payload.get("return", -1)) != 100: return "Every post-repair check must read 100/100/100."
		"p06_count_42":
			if int(payload.get("total", -1)) != 42 or int(payload.get("wells", -1)) != 6: return "P-06 requires six wells totalling exactly 42 seeds."
		"p06_allocate_12_30":
			if int(payload.get("planted", -1)) != 12 or int(payload.get("reserve", -1)) != 30: return "P-06 allocation must preserve 12 planted and 30 reserve seeds."
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
