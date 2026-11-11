extends RefCounted

## Test fixture: the accepted P-05 and P-06 answers (from their content data) as
## the payloads a player would build in the Chapter 3 panel. Gameplay never calls
## this; it replaces the gate catalog's old pre-filled payloads for suites that
## drive the extended route without opening the panel.

const P05 = preload("res://scripts/puzzles/p05_falling_pressure.gd")
const P06 = preload("res://scripts/puzzles/p06_harvest_future.gd")

const INSPECTION_PHASE := {"p05_inspect_tank": true, "p05_inspect_habitat": true, "p05_inspect_garden": true, "p05_inspect_return": true, "p05_inspect_airlock": true, "p05_inspect_annex": true}

static func payload(target_id: String, state: Dictionary = {}, base: Dictionary = {}) -> Dictionary:
	var result: Dictionary = base.duplicate(true)
	var model = P05.new() if target_id.begins_with("p05_") else (P06.new() if target_id.begins_with("p06_") else null)
	if model == null:
		return result
	var answer: Dictionary = model.data().get("answers", {}).get(target_id, {})
	for key in answer:
		var value = answer[key]
		result[key] = value.duplicate(true) if value is Array or value is Dictionary else value
	if INSPECTION_PHASE.has(target_id):
		# The simulator advances after every pair of committed inspections.
		var inspected := 0
		for key in state.get("receipts", {}):
			if String(key).contains("p05_inspect_"):
				inspected += 1
		result["phase"] = inspected / 2 + 1
	return result

static func is_witnessed(target_id: String) -> bool:
	return target_id.begins_with("p05_") or target_id.begins_with("p06_")
