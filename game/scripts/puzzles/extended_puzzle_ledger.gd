extends RefCounted
class_name ExtendedPuzzleLedger

const P05Script = preload("res://scripts/puzzles/p05_falling_pressure.gd")
const P06Script = preload("res://scripts/puzzles/p06_harvest_future.gd")

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
	var p05_expected: Dictionary = P05Script.expected_payload(action)
	if not p05_expected.is_empty():
		return _validate_p05(action, payload, p05_expected)
	var p06_expected: Dictionary = P06Script.expected_payload(action)
	if not p06_expected.is_empty():
		return _validate_p06(action, payload, p06_expected)
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
			if int(payload.get("genuine", -1)) != 6 or int(payload.get("artifacts_rejected", -1)) != 2: return "P-10 requires six genuine flashes and both persistent artifacts rejected."
		"p11_commit_allocation":
			if int(payload.get("total", -1)) != 7 or not bool(payload.get("essentials", false)) or not bool(payload.get("pump", false)) or not bool(payload.get("camera", false)): return "P-11 requires five essentials plus one pump and one camera for seven units."
		"p12_reset_sequence":
			if payload.get("sequence", []) != ["isolate", "zero", "reset", "reconnect", "camera_test"]: return "P-12 requires isolate, zero/fault check, reset, reconnect and camera-branch test."
		"p13_commit_plan":
			if int(payload.get("water", -1)) != 4 or int(payload.get("crate", -1)) != 2 or String(payload.get("heat", "")) != "COZY" or String(payload.get("light", "")) != "DIM" or int(payload.get("reserve", -1)) != 30: return "P-13 witness requires W4, K2, COZY/DIM and protected reserve 30."
		"p14_route_reading_1", "p14_route_reading_2":
			if not (payload.get("reading") is int or payload.get("reading") is float) or not is_finite(float(payload.reading)) or float(payload.reading) < 0 or float(payload.reading) >= 1.0: return "P-14 route clearance requires a reading below 1."
		"p15_choose_surveyed_route":
			if String(payload.get("route", "")) != "SURVEYED" or int(payload.get("reserve", -1)) < 2: return "P-15 requires the surveyed route and at least two units of return reserve."
		"p15_restore_marker_2":
			if String(payload.get("battery", "")) != "SPARE" or String(payload.get("test", "")) != "PASS": return "Repeater marker 2 needs the spare battery and a passing chain test."
		"p16_local_bearing":
			if String(payload.get("bearing", "")) != "L2": return "The local relay bearing witness is L2."
		"p16_earth_bearing":
			if String(payload.get("bearing", "")) != "E3": return "The Earth relay bearing witness is E3."
		"p16_checksum":
			if String(payload.get("value", "")) != "ALO42": return "The final checksum witness is ALO42."
	return ""

func _validate_p05(action: String, payload: Dictionary, expected: Dictionary) -> String:
	if expected.has("reading"):
		var want := int(expected["reading"])
		if int(payload.get("reading", -1)) != want:
			return "The manual gauge reading for %s must match the %d relative test unit needle." % [action, want]
		return ""
	for key in ["main", "garden", "return"]:
		if expected.has(key) and int(payload.get(key, -1)) != int(expected[key]):
			return "Every post-repair steady check must read %d/%d/%d across MAIN, GARDEN, and RETURN." % [int(expected.get("main", 0)), int(expected.get("garden", 0)), int(expected.get("return", 0))]
	return ""

func _validate_p06(action: String, payload: Dictionary, expected: Dictionary) -> String:
	if action == "p06_count_42":
		var want_total := int(expected.get("total", 0))
		var want_wells := int(expected.get("wells", 0))
		if int(payload.get("total", -1)) != want_total or int(payload.get("wells", -1)) != want_wells:
			return "Six counting wells of seven seeds must total %d across %d wells." % [want_total, want_wells]
		return ""
	if action == "p06_allocate_12_30":
		var want_planted := int(expected.get("planted", 0))
		var want_reserve := int(expected.get("reserve", 0))
		if int(payload.get("planted", -1)) != want_planted or int(payload.get("reserve", -1)) != want_reserve:
			return "Seed allocation must preserve %d planted and %d sealed reserve seeds." % [want_planted, want_reserve]
		return ""
	return ""
