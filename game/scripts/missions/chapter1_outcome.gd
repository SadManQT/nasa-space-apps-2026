extends RefCounted
class_name Chapter1Outcome

## Read-only Chapter 1 closure and causal replay. Forecasts are captured before
## commit; actual readings come from simulation receipts, never the edited plan.
const Table = preload("res://scripts/puzzles/p02_mission_table.gd")
const Simulation = preload("res://scripts/simulation/expedition_simulation.gd")
const CONTENT_PATH := "res://resources/campaign/content/chapter1_debrief.json"
const RESOURCE_KEYS := ["E", "A", "H", "W", "K", "C", "R", "Z"]

## Append only newly committed shifts. Primitive records travel with the route
## save and its existing physical checkpoint, so retry removes abandoned history.
static func record(history: Dictionary, before: Dictionary, forecast: Dictionary, result: Dictionary, plan: Dictionary, cards: Array) -> void:
	if not result.get("accepted", false) or result.get("duplicate", false):
		return
	if history.is_empty():
		var initial := {}
		for key in ["resources", "scenario_datetime", "current_shift", "upgrades", "blackout_count"]:
			if before.has(key):
				initial[key] = before[key]
		history.merge({"initial": initial.duplicate(true), "shifts": []})
	var steps: Array = plan.get("shifts", [plan.get("shift", plan.get("step", {}))])
	var predictions: Array = forecast.get("trace", [])
	for index in result.get("trace", []).size():
		var actual: Dictionary = result.trace[index]
		var predicted := {}
		for prediction in predictions:
			if int(prediction.shift) == int(actual.shift):
				predicted = prediction.after.duplicate(true)
		history.shifts.append({"shift": int(actual.shift), "step": steps[index].duplicate(true), "forecast": predicted, "actual": actual.duplicate(true), "cards": cards.duplicate(true)})

## Validate saved replay records before replacing any live route state. Older
## saves without a replay remain valid and explicitly lack forecast evidence.
static func validate(value) -> bool:
	if not value is Dictionary:
		return false
	if value.is_empty():
		return true
	if not value.get("initial") is Dictionary or not value.get("shifts") is Array or value.shifts.size() > Table.SHIFT_COUNT:
		return false
	var initial: Dictionary = preload("res://scripts/core/campaign_state.gd").new_snapshot()
	initial.merge(value.initial, true)
	if not preload("res://scripts/core/campaign_state.gd").is_compatible(initial):
		return false
	var previous := int(value.initial.get("current_shift", 0))
	for row in value.shifts:
		if not row is Dictionary or not row.get("step") is Dictionary or not row.get("forecast") is Dictionary or not row.get("actual") is Dictionary or not row.get("cards") is Array:
			return false
		var shift = row.get("shift")
		if not (shift is int or shift is float) or float(shift) != previous + 1 or int(shift) > Table.SHIFT_COUNT:
			return false
		previous = int(shift)
		if not _valid_trace(row.actual, previous):
			return false
		for card in row.cards:
			if not card is Dictionary or not card.get("name") is String or not card.get("arrived") is bool or not card.get("shared") is bool:
				return false
		for key in row.step:
			if key in ["heat", "light", "transfer", "alarm_action"]:
				if not (row.step[key] is String or row.step[key] is int or row.step[key] is float):
					return false
			elif key in ["sheltered", "crew_sheltered"]:
				if not row.step[key] is bool:
					return false
			elif not Simulation.is_amount(row.step[key]):
				return false
		for key in ["before", "after"]:
			if not row.actual.get(key) is Dictionary:
				return false
			for resource in RESOURCE_KEYS:
				if not Simulation.is_amount(row.actual[key].get(resource)):
					return false
		if not row.forecast.is_empty():
			for resource in RESOURCE_KEYS:
				if not Simulation.is_amount(row.forecast.get(resource)):
					return false
	return true

static func _valid_trace(trace: Dictionary, shift: int) -> bool:
	var trace_shift = trace.get("shift")
	if not (trace_shift is int or trace_shift is float) or float(trace_shift) != shift:
		return false
	for key in ["heat", "light", "air_production", "action_progress", "overflow", "shelter", "dose"]:
		var amount = trace.get(key)
		if not Simulation.is_amount(amount) or float(amount) != floor(float(amount)):
			return false
		if key in ["heat", "light", "air_production"] and int(amount) > 2:
			return false
	for key in ["blackout", "action_success", "crates_removed"]:
		if not trace.get(key) is bool:
			return false
	if not trace.get("transfer") in ["FILL", "HOLD", "DRAIN", "PUMP", "STACK", "WAIT"] or not trace.get("action") is String:
		return false
	if not trace.get("causes") is Array or not trace.causes.all(func(cause): return cause is String):
		return false
	return true

## Build presentation from authoritative state and recorded receipts. This
## cannot unlock a chapter, alter resources or commit an operation.
static func view(state: Dictionary, ending: String, history: Dictionary, checkpoint: Dictionary, safe_ending: bool, table: RefCounted) -> Dictionary:
	if ending.is_empty():
		return {}
	var report := Table.ending_report({"ending": ending, "final_state": state.resources, "snapshot": state})
	var content: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONTENT_PATH))
	# A pre-update checkpoint may acquire modern records partway through the
	# night. Merge its earlier receipts rather than discarding that real history.
	# Only captured forecasts can populate the prediction column.
	var by_shift := {}
	for receipt in state.get("receipts", {}).values():
		for actual in receipt.get("trace", []):
			if actual is Dictionary and actual.has("shift") and actual.has("after") and _valid_trace(actual, int(actual.shift)):
				by_shift[int(actual.shift)] = {"shift": int(actual.shift), "step": {}, "forecast": {}, "actual": actual.duplicate(true), "cards": []}
	for row in history.get("shifts", []):
		by_shift[int(row.shift)] = row.duplicate(true)
	var rows: Array = []
	var numbers := by_shift.keys()
	numbers.sort()
	for number in numbers:
		rows.append(by_shift[number])
	for row in rows:
		row["shift"] = int(row.shift)
		row["choice"] = choice_text(row.actual)
		row["why"] = why(row.actual)
		row["matches"] = not row.forecast.is_empty() and readings(row.forecast) == readings(row.actual.after)
	report.merge({"chapter1": true, "resources": state.resources.duplicate(true), "replay": rows, "content": content, "safe_ending": safe_ending, "retry_shift": int(checkpoint.get("director", {}).get("current_shift", 0)) + 1, "can_retry": not checkpoint.is_empty(), "comparison": compare(history), "comparison_available": history.get("shifts", []).size() == Table.SHIFT_COUNT, "roles": table.role_cards(int(state.get("current_shift", 0)))})
	return report

## Compact, labelled readings in a stable order, shared by forecast and actual.
static func readings(resources: Dictionary) -> String:
	var values: Array[String] = []
	for key in RESOURCE_KEYS:
		values.append("%s %s" % [key, _number(resources.get(key, "—"))])
	return "  ·  ".join(values)

static func _number(value) -> String:
	if (value is int or value is float) and float(value) == floor(float(value)):
		return str(int(value))
	return str(value)

## Describe settings from the committed trace, including partial alarm work.
static func choice_text(trace: Dictionary) -> String:
	var heat: String = "DAY" if Table.is_day_shift(int(trace.shift)) else ["COLD", "COOL", "COZY"][int(trace.heat)]
	var text := "Heat %s · Air maker %s · Light %s · %s" % [heat, _number(trace.air_production), ["OFF", "DIM", "FULL"][int(trace.light)], String(trace.transfer)]
	if String(trace.get("action", "")) in ["PUMP", "STACK"]:
		text += " · %d task steps (%s)" % [int(trace.action_progress), "complete" if trace.action_success else "partial"]
	return text

## Explain actual effects, including ordering, without presenting game units as
## measured dose or inventing a medical outcome for a stopped training mission.
static func why(trace: Dictionary) -> String:
	var notes: Array[String] = []
	if int(trace.get("overflow", 0)) > 0:
		notes.append("Daylight charging filled the battery; %s energy overflowed before spending." % _number(trace.overflow))
	if trace.get("blackout", false):
		notes.append("Demand exceeded available energy: the blackout penalty affected air, Alo and crops.")
	elif int(trace.after.get("E", -1)) == 0:
		notes.append("The battery reached exactly zero; this shift had no blackout.")
	if not Table.is_day_shift(int(trace.shift)):
		var heat := int(trace.heat)
		notes.append(["COLD reduced Alo health by 2 and crop condition by 1.", "COOL reduced Alo health by 1.", "COZY avoided cold damage."][heat])
	var light := int(trace.light)
	notes.append(["OFF light reduced plant health and crop condition by 1.", "DIM light left plant health and crop condition unchanged.", "FULL light added 1 to plant health and crop condition, within their caps."][light])
	if (trace.get("causes", []) as Array).has("thirst:post-transfer-water>=4"):
		notes.append("The wall still held at least 4 water after transfer, so thirst reduced Alo and crop condition by 1.")
	if int(trace.shift) in [5, 6]:
		notes.append("Shelter %s gave game exposure +%s; exposure was resolved before any ordinary drain." % [_number(trace.shelter), _number(trace.dose)])
	if trace.get("crates_removed", false):
		notes.append("Temporary crate shielding was removed before shift 7.")
	if int(trace.after.get("H", 0)) == 0:
		notes.append("Alo reached its terminal state in this attempt; later care cannot restore it.")
	if int(trace.after.get("A", 0)) == 0:
		notes.append("Air reached zero. Flight rules stopped operations and kept this attempt from advancing.")
	if int(trace.after.get("Z", 0)) > 3:
		notes.append("Game exposure exceeded the crew safety limit. Flight rules stopped operations.")
	return " ".join(notes)

## Exhaustively compare one ordinary setting at a time using the real P-02
## preview. Only complete, safe, sheltered alternatives with healthier Alo are
## suggested. This is a labelled counterfactual, never a replacement receipt.
static func compare(history: Dictionary) -> Dictionary:
	var rows: Array = history.get("shifts", [])
	if rows.size() != Table.SHIFT_COUNT or int(history.get("initial", {}).get("current_shift", -1)) != 0:
		return {}
	var steps: Array = rows.map(func(row): return row.step.duplicate(true))
	var simulation := Simulation.new()
	var original: Dictionary = simulation.preview(history.initial, {"shifts": steps})
	if not original.get("accepted", false):
		return {}
	var best := {}
	var best_health := int(original.final_state.H)
	for index in steps.size():
		for field in Table.fields_for_shift(index + 1):
			if field == "action":
				continue # No hypothetical motor-task success or free intervention.
			for option in Table.field_options(field):
				var candidate: Array = steps.duplicate(true)
				var old = candidate[index].get(field)
				if old == option.value:
					continue
				candidate[index][field] = option.value
				var result: Dictionary = simulation.preview(history.initial, {"shifts": candidate})
				if not result.get("accepted", false) or not result.get("ending", "") in ["BLOOM", "GOLDEN"] or int(result.final_state.H) <= best_health:
					continue
				if candidate.any(func(step): return not bool(step.get("sheltered", step.get("crew_sheltered", true)))):
					continue
				best_health = int(result.final_state.H)
				best = {"shift": index + 1, "field": field, "from": old, "to": option.value, "health_gain": best_health - int(original.final_state.H), "actual": original.final_state.duplicate(true), "alternative": result.final_state.duplicate(true), "ending": result.ending}
	return best
