extends RefCounted

## Read-only Chapter 1 review. Historical forecasts are recomputed from receipt
## inputs with the shared simulator; no current plan or future knowledge is used.
const Table = preload("res://scripts/puzzles/p02_mission_table.gd")
const Simulation = preload("res://scripts/simulation/expedition_simulation.gd")
const LESSONS := [
	{"title": "Power and air", "question": "Why make air in daylight?", "options": ["Use charging energy before it overflows", "Plants instantly make all the crew's air", "Darkness removes the need for air"], "correct": 0, "why": "Charging fills the battery before systems spend energy. Making air in daylight can use energy that would otherwise overflow. Exactly zero energy is not a blackout; demand must exceed the available energy.", "source": "vsat_relocatable_array", "fields": ["E", "A"]},
	{"title": "Shelter and garden water", "question": "Why can shelter water hurt Alo?", "options": ["The plant sees the radiation", "The wall borrows water from the garden reservoir", "Crates consume the garden's water"], "correct": 1, "why": "The wall and garden share water. A wall holding at least 4 leaves the garden thirsty. Exposure is resolved before an ordinary drain; crate shielding is separate from water.", "source": "clowdsley_2021_shielding", "fields": ["W", "K", "H", "Z"]},
	{"title": "Evidence and the training model", "question": "Which label means a real measurement?", "options": ["Simulated", "Fiction", "Observed"], "correct": 2, "why": "Observed labels measured records. September 2017 proton observations inform this April 2046 exercise. Resource costs, game exposure and the seven-shift night are training rules. Game exposure is not a medical dose. The shift-4 Earth-link cutoff is an authored event; Earth is below the pole's horizon and rising.", "source": "goes13_protons_2017_09", "fields": ["Z"]},
]

static func view(state: Dictionary, route: Dictionary) -> Dictionary:
	var ending := String(route.get("ending", ""))
	if ending.is_empty():
		return {}
	var report := Table.ending_report({"ending": ending, "final_state": state.resources, "snapshot": state})
	var by_shift := {}
	for receipt in state.get("receipts", {}).values():
		for row in receipt.get("trace", []):
			if row is Dictionary and row.has("shift") and row.has("before") and row.has("after"):
				by_shift[int(row.shift)] = row.duplicate(true)
	var numbers := by_shift.keys()
	numbers.sort()
	var replay: Array = []
	var blackouts := 0
	for shift in numbers:
		var actual: Dictionary = by_shift[shift]
		var historical := Simulation.new().entry_profile()
		historical["resources"] = actual.before.duplicate(true)
		historical["current_shift"] = int(shift) - 1
		historical["blackout_count"] = blackouts
		# Chapter 1 has no acquired upgrades. Never copy later campaign modifiers.
		var step := {"heat": int(actual.heat), "air_production": int(actual.air_production), "light": int(actual.light), "transfer": String(actual.transfer), "sheltered": not actual.causes.has("crew-not-sheltered")}
		if int(shift) == 5:
			step["pump_confirmations"] = int(actual.action_progress) if actual.action == "PUMP" else 0
			step["stack_slots"] = int(actual.action_progress) if actual.action == "STACK" else 0
		var prediction: Dictionary = Simulation.new().preview(historical, {"shift": step})
		replay.append({"shift": int(shift), "actual": actual, "forecast": prediction.get("final_state", {}), "choice": choice_text(actual), "why": why(actual)})
		if actual.blackout:
			blackouts += 1
	var checkpoint: Dictionary = route.get("retry_checkpoint", {})
	report.merge({"resources": state.resources.duplicate(true), "replay": replay, "safe_ending": bool(route.get("chapter_ready", {}).get("safe_ending", false)), "can_retry": not checkpoint.is_empty(), "retry_shift": int(checkpoint.get("director", {}).get("current_shift", 0)) + 1, "lessons": LESSONS.duplicate(true)})
	return report

static func readings(resources: Dictionary, fields: Array = ["E", "A", "H", "W", "K", "C", "R", "Z"]) -> String:
	var words: Dictionary = UiDesign.text().get("station", {}).get("fields", {})
	var rows: Array[String] = []
	for field in fields:
		var value = resources.get(field, "--")
		var number := str(int(value)) if (value is int or value is float) and float(value) == floor(float(value)) else str(value)
		var spec: Dictionary = words.get(field, {})
		var capacity := String(spec.get("capacity", {"W": "water_capacity", "K": "crate_capacity"}.get(field, "")))
		var scale := " %s %d" % [String(spec.get("scale", "of")), int(resources[capacity])] if resources.has(capacity) else ""
		var unit := String(spec.get("unit", "training units" if field == "Z" else ""))
		rows.append("%s %s%s%s" % ["Training radiation dose" if field == "Z" else String(spec.get("word", field)), number, scale, " " + unit if not unit.is_empty() else ""])
	return " \u00b7 ".join(rows)

static func choice_text(trace: Dictionary) -> String:
	var heat: String = "Daylight" if Table.is_day_shift(int(trace.shift)) else ["Cold", "Cool", "Cozy"][int(trace.heat)]
	var transfer := String({"FILL": "Fill the wall", "HOLD": "Keep water in place", "DRAIN": "Return water", "WAIT": "Wait", "PUMP": "Pump water", "STACK": "Stack crates"}.get(String(trace.transfer), trace.transfer))
	var text := "%s heat \u00b7 Air maker %d \u00b7 %s light \u00b7 %s" % [heat, int(trace.air_production), ["Off", "Dim", "Full"][int(trace.light)], transfer]
	if trace.action in ["PUMP", "STACK"]:
		text += " \u00b7 %d steps (%s)" % [int(trace.action_progress), "complete" if trace.action_success else "partial"]
	return text

static func why(trace: Dictionary) -> String:
	var notes: Array[String] = []
	if int(trace.overflow) > 0:
		notes.append("Daylight charging overflowed by %d before spending." % int(trace.overflow))
	if trace.blackout:
		notes.append("Demand exceeded available energy, so a blackout reduced air, Alo health and crop condition.")
	elif int(trace.after.E) == 0:
		notes.append("The battery reached exactly zero without a blackout.")
	if not Table.is_day_shift(int(trace.shift)):
		notes.append(["Cold heat reduced Alo health by 2 and crop condition by 1.", "Cool heat reduced Alo health by 1.", "Cozy heat avoided cold damage."][int(trace.heat)])
	notes.append(["Off light reduced Alo health and crop condition by 1.", "Dim light left plant health unchanged.", "Full light supports Alo health and crop condition by 1, within their caps."][int(trace.light)])
	if trace.causes.has("thirst:post-transfer-water>=4"):
		notes.append("At least 4 water remained in the wall after transfer, so thirst reduced Alo health and crop condition by 1.")
	if int(trace.shift) in [5, 6]:
		notes.append("Shelter %d gave game exposure +%d before any ordinary drain." % [int(trace.shelter), int(trace.dose)])
	if trace.crates_removed:
		notes.append("Temporary crates were removed before shift 7.")
	if int(trace.after.H) == 0:
		notes.append("Alo reached its terminal state in this attempt; later care cannot restore it.")
	if int(trace.after.A) == 0 or int(trace.after.Z) > 3 or trace.causes.has("crew-not-sheltered"):
		notes.append("Flight rules stopped this attempt at the crew safety limit.")
	return " ".join(notes)
