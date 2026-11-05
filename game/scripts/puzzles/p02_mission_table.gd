extends RefCounted
class_name P02MissionTable

## P-02 Seven Shifts planning state behind the Mission Table.
##
## Holds only what the player has decided and read: per-shift settings, the
## role-card receipts (read privately, shared with the crew, signed the team
## plan), hint progress and the shift-5 alarm task progress. It never does
## resource arithmetic. `plan_for_gate` turns the selections into the exact plan
## ExpeditionSimulation previews and commits, so the forecast and the committed
## result come from the same pure function. Option lists, role cards, hints and
## worked plans live in res://resources/campaign/content/p02_mission_table.json.

const DATA_PATH := "res://resources/campaign/content/p02_mission_table.json"
const SCHEMA_VERSION := 1
const SHIFT_COUNT := 7
const NIGHT_FIELDS := ["heat", "air_production", "light", "transfer"]
const DAY_FIELDS := ["air_production", "light", "transfer"]
const ALARM_FIELDS := ["heat", "air_production", "light", "action"]
const TASK_IDLE := "idle"
const TASK_RUNNING := "running"
const TASK_RESOLVED := "resolved"

static var _data_cache: Dictionary = {}

var _selections := {}
var _shared := {}
var _read := {}
var _sign_offs := {}
var _hint_level := 0
var _golden_hint_level := 0
var _bloom_achieved := false
var _alarm := {}

func _init() -> void:
	_alarm = _empty_alarm()

## The parsed data file. Cached; returns {} if the file is missing or invalid.
static func data() -> Dictionary:
	if _data_cache.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH)) if FileAccess.file_exists(DATA_PATH) else null
		if parsed is Dictionary and int(parsed.get("schema_version", 0)) == SCHEMA_VERSION:
			_data_cache = parsed
		else:
			push_error("P-02 Mission Table data is missing or invalid: " + DATA_PATH)
	return _data_cache

## True when `target_id` is one of the six P-02 Mission Table gates.
static func is_gate(target_id: String) -> bool:
	return data().get("gates", {}).has(target_id)

## Shift numbers resolved by one gate, e.g. [3, 4] for p02_shifts3_4.
static func gate_shifts(target_id: String) -> Array:
	var shifts: Array = []
	for value in data().get("gates", {}).get(target_id, {}).get("shifts", []):
		shifts.append(int(value))
	return shifts

## Display metadata for a gate: label, commit_label and preview_only.
static func gate_info(target_id: String) -> Dictionary:
	return data().get("gates", {}).get(target_id, {}).duplicate(true)

static func is_day_shift(shift: int) -> bool:
	return data().get("day_shifts", [1, 2]).has(float(shift)) or data().get("day_shifts", [1, 2]).has(shift)

static func is_alarm_shift(shift: int) -> bool:
	return shift == int(data().get("alarm_shift", 5))

## The fields the player sets for `shift`, in display order.
static func fields_for_shift(shift: int) -> Array:
	if is_alarm_shift(shift):
		return ALARM_FIELDS.duplicate()
	return DAY_FIELDS.duplicate() if is_day_shift(shift) else NIGHT_FIELDS.duplicate()

## Option list for one field: [{value, label, cost}].
static func field_options(field: String) -> Array:
	return data().get("fields", {}).get(field, {}).get("options", []).duplicate(true)

static func field_label(field: String) -> String:
	return String(data().get("fields", {}).get(field, {}).get("label", field.to_upper()))

## Sets one field of one shift's plan after checking that the value is legal
## for that shift. Committed shifts are read-only. Returns {accepted, reason}.
func set_choice(shift: int, field: String, value, committed_shift: int = 0) -> Dictionary:
	if shift < 1 or shift > SHIFT_COUNT:
		return _reject("Shift must be between 1 and 7.")
	if shift <= committed_shift:
		return _reject("Shift %d is already committed; retry its checkpoint to change it." % shift)
	if not fields_for_shift(shift).has(field):
		return _reject("%s is not set in shift %d." % [field_label(field), shift])
	var normalised = _normalise(field, value)
	if normalised == null:
		return _reject("%s cannot be %s." % [field_label(field), str(value)])
	var selection: Dictionary = _selections.get(shift, {}).duplicate()
	if is_alarm_shift(shift) and _alarm_locked(selection, field, normalised):
		return _reject("STACK sets heat COOL, air maker OFF and light OFF for this shift.")
	selection[field] = normalised
	if field == "action":
		if String(normalised) == "STACK":
			for key in data().get("stack_forces", {}):
				selection[key] = _normalise(key, data().stack_forces[key])
		if String(normalised) != String(_alarm.get("action", "")):
			_alarm = _empty_alarm()
			_alarm["action"] = String(normalised)
	_selections[shift] = selection
	return {"accepted": true, "reason": "Shift %d %s set to %s." % [shift, field_label(field), _value_label(field, normalised)]}

## One shift's selections; missing fields mean the player has not chosen yet.
func selection(shift: int) -> Dictionary:
	return _selections.get(shift, {}).duplicate()

## Fields still unset for `shift`.
func missing_fields(shift: int) -> Array:
	var result: Array = []
	var current: Dictionary = _selections.get(shift, {})
	for field in fields_for_shift(shift):
		if not current.has(field):
			result.append(field)
	return result

func is_shift_planned(shift: int) -> bool:
	return missing_fields(shift).is_empty()

## The simulation step for one planned shift, or {} while a field is unset.
## Shift 5 carries the alarm task progress so an incomplete PUMP/STACK
## previews and commits exactly the partial effect the player achieved.
func step_for_shift(shift: int) -> Dictionary:
	if not is_shift_planned(shift):
		return {}
	var current: Dictionary = _selections[shift]
	var step := {
		"heat": "DAY" if is_day_shift(shift) else String(current.heat),
		"air_production": int(current.air_production),
		"light": String(current.light),
	}
	if is_alarm_shift(shift):
		step["transfer"] = String(current.action)
		step["pump_confirmations"] = alarm_progress() if String(current.action) == "PUMP" else 0
		step["stack_slots"] = alarm_progress() if String(current.action) == "STACK" else 0
	else:
		step["transfer"] = String(current.transfer)
	return step

## The exact plan a gate commits ({shift} or {shifts}); {} until every field of
## every shift in the gate is set.
func plan_for_gate(target_id: String) -> Dictionary:
	var shifts := gate_shifts(target_id)
	if shifts.is_empty():
		return {}
	var steps: Array = []
	for shift in shifts:
		var step := step_for_shift(int(shift))
		if step.is_empty():
			return {}
		steps.append(step)
	return {"shift": steps[0]} if steps.size() == 1 else {"shifts": steps}

## Planned steps from `first_shift` onward, stopping at the first unplanned
## shift. Used for the whole-night projection; the caller labels the rest as
## not yet planned.
func plan_from(first_shift: int) -> Dictionary:
	var steps: Array = []
	for shift in range(maxi(1, first_shift), SHIFT_COUNT + 1):
		var step := step_for_shift(shift)
		if step.is_empty():
			break
		steps.append(step)
	return {"shifts": steps}

## Why this gate cannot be committed yet, or "" when it can. The order matches
## what the player must do: read the arrived cards, set every field, finish a
## started alarm task.
func commit_block_reason(target_id: String, committed_shift: int) -> String:
	var shifts := gate_shifts(target_id)
	if shifts.is_empty():
		return "This operation is not a Mission Table shift."
	if int(shifts[0]) != committed_shift + 1:
		return "The Mission Table is at shift %d; this gate resolves shift %d." % [committed_shift + 1, int(shifts[0])]
	for card in role_cards(committed_shift):
		if bool(card.arrived) and not bool(card.shared):
			return "Share %s's card with the crew first." % String(card.name)
	return plan_block_reason(target_id, committed_shift)

## Why the plan itself cannot be committed for this gate, or "" when it can:
## every field set and any started alarm task finished. The route enforces
## this on every P-02 commit; card sharing is a Mission Table step on top.
func plan_block_reason(target_id: String, committed_shift: int) -> String:
	var shifts := gate_shifts(target_id)
	if shifts.is_empty():
		return "This operation is not a Mission Table shift."
	if int(shifts[0]) <= committed_shift:
		return "This gate's shifts are already committed."
	if int(shifts[0]) != committed_shift + 1:
		return "The Mission Table is at shift %d; this gate resolves shift %d." % [committed_shift + 1, int(shifts[0])]
	for shift in shifts:
		var missing := missing_fields(int(shift))
		if not missing.is_empty():
			return "Choose %s for shift %d." % [field_label(String(missing[0])), int(shift)]
	if shifts.has(int(data().get("alarm_shift", 5))):
		var action := String(_selections.get(int(data().get("alarm_shift", 5)), {}).get("action", ""))
		if action in ["PUMP", "STACK"] and String(_alarm.get("state", TASK_IDLE)) != TASK_RESOLVED:
			return "Run the %s task and finish or end it before committing." % action
	return ""

## The four role cards with arrival and shared state for the current shift.
## A card that has not arrived carries no facts, so future information stays
## hidden.
func role_cards(committed_shift: int) -> Array:
	var result: Array = []
	for raw in data().get("role_cards", []):
		var card: Dictionary = raw.duplicate(true)
		var arrived := committed_shift + 1 >= int(card.get("arrives_shift", 1))
		card["arrived"] = arrived
		card["shared"] = bool(_shared.get(String(card.role_id), false))
		card["read"] = bool(_read.get(String(card.role_id), false))
		if not arrived:
			card["facts"] = []
			card["quote"] = ""
		result.append(card)
	return result

## Marks a delivered card as shared with the crew. Sharing a card twice is a
## harmless no-op; a card that has not arrived cannot be shared. With
## `require_read` (Class mode) the role's player must have read the card
## privately first, so sharing is a separate act from receiving it.
func share(role_id: String, committed_shift: int, require_read: bool = false) -> Dictionary:
	for card in role_cards(committed_shift):
		if String(card.role_id) != role_id:
			continue
		if not bool(card.arrived):
			return _reject("%s's card arrives at shift %d." % [String(card.name), int(card.arrives_shift)])
		if require_read and not bool(_read.get(role_id, false)):
			return _reject("%s's note has not been read privately yet." % String(card.name))
		var duplicate := bool(_shared.get(role_id, false))
		_shared[role_id] = true
		return {"accepted": true, "duplicate": duplicate, "reason": "%s shared the %s card. Read by the crew." % [String(card.name), String(card.role).to_lower()]}
	return _reject("Unknown role card: " + role_id)

## Records that the role's player read a delivered card privately (the
## hand-off screen or a printed card). Reading twice is a harmless no-op; a
## card that has not arrived cannot be read.
func mark_read(role_id: String, committed_shift: int) -> Dictionary:
	for card in role_cards(committed_shift):
		if String(card.role_id) != role_id:
			continue
		if not bool(card.arrived):
			return _reject("%s's card arrives at shift %d." % [String(card.name), int(card.arrives_shift)])
		var duplicate := bool(_read.get(role_id, false))
		_read[role_id] = true
		return {"accepted": true, "duplicate": duplicate, "reason": "%s read the %s note privately." % [String(card.name), String(card.role).to_lower()]}
	return _reject("Unknown role card: " + role_id)

## Identifies one exact plan for one gate at one committed shift. Sign-offs
## are bound to this key, so any change to the plan (a choice, a worked plan,
## alarm task progress, a retry) makes earlier signatures stale.
func plan_key(target_id: String, committed_shift: int) -> String:
	return JSON.stringify(plan_for_gate(target_id)) + "@" + str(committed_shift)

## One role signs the current, complete plan for `target_id`. Signing the same
## plan twice is a harmless no-op; signing a changed plan replaces the old
## signature.
func sign_off(role_id: String, target_id: String, committed_shift: int) -> Dictionary:
	if not data().get("role_cards", []).any(func(card): return String(card.get("role_id", "")) == role_id):
		return _reject("Unknown role: " + role_id)
	var block := plan_block_reason(target_id, committed_shift)
	if not block.is_empty():
		return _reject(block)
	var key := plan_key(target_id, committed_shift)
	var duplicate := String(_sign_offs.get(role_id, "")) == key
	_sign_offs[role_id] = key
	return {"accepted": true, "duplicate": duplicate, "reason": "%s signed the team plan." % _role_name(role_id)}

## Roles whose signature matches the current plan for this gate, in card order.
func signed_roles(target_id: String, committed_shift: int) -> Array:
	var key := plan_key(target_id, committed_shift)
	var result: Array = []
	for card in data().get("role_cards", []):
		var role_id := String(card.get("role_id", ""))
		if String(_sign_offs.get(role_id, "")) == key:
			result.append(role_id)
	return result

## Roles that signed an earlier version of the plan and must sign again.
func stale_sign_offs(target_id: String, committed_shift: int) -> Array:
	var key := plan_key(target_id, committed_shift)
	var result: Array = []
	for card in data().get("role_cards", []):
		var role_id := String(card.get("role_id", ""))
		var signed := String(_sign_offs.get(role_id, ""))
		if not signed.is_empty() and signed != key:
			result.append(role_id)
	return result

## Forgets every signature, e.g. when the crew mode changes.
func clear_sign_offs() -> void:
	_sign_offs.clear()

## The communication receipts the debrief reports separately: which notes
## were read privately, which were shared with the crew and which roles signed
## the plan currently on the table.
func communication_record() -> Dictionary:
	var read: Array = []
	var shared: Array = []
	for card in data().get("role_cards", []):
		var role_id := String(card.get("role_id", ""))
		if bool(_read.get(role_id, false)):
			read.append(role_id)
		if bool(_shared.get(role_id, false)):
			shared.append(role_id)
	return {"read": read, "shared": shared, "sign_offs": _sign_offs.duplicate()}

## Reveals the next progressive hint. Golden hints unlock only after a first
## Bloom and follow H1-H3. Hints never change ending eligibility.
func next_hint() -> Dictionary:
	var hints: Array = data().get("hints", [])
	if _hint_level < hints.size():
		_hint_level += 1
		return {"accepted": true, "level": "H%d" % _hint_level, "text": String(hints[_hint_level - 1])}
	var golden: Array = data().get("golden_hints", [])
	if _bloom_achieved and _golden_hint_level < golden.size():
		_golden_hint_level += 1
		return {"accepted": true, "level": "G%d" % _golden_hint_level, "text": String(golden[_golden_hint_level - 1])}
	return _reject("All available hints are shown." if _bloom_achieved else "All hints are shown. Golden hints unlock after a first Bloom.")

## Hints revealed so far, in order, as [{level, text}].
func revealed_hints() -> Array:
	var result: Array = []
	var hints: Array = data().get("hints", [])
	for index in mini(_hint_level, hints.size()):
		result.append({"level": "H%d" % (index + 1), "text": String(hints[index])})
	var golden: Array = data().get("golden_hints", [])
	for index in mini(_golden_hint_level, golden.size()):
		result.append({"level": "G%d" % (index + 1), "text": String(golden[index])})
	return result

## Worked plans the player has unlocked through hints: Bloom after H3,
## Golden after G2.
func unlocked_worked_plans() -> Array:
	var result: Array = []
	if _hint_level >= data().get("hints", []).size():
		result.append("bloom")
	if _golden_hint_level >= data().get("golden_hints", []).size():
		result.append("golden")
	return result

## Copies a worked plan into every shift that is not yet committed. Earlier
## committed shifts keep their real values, so the result can differ from the
## worked ending; the forecast shows the actual consequence.
func apply_worked_plan(plan_id: String, committed_shift: int = 0) -> Dictionary:
	var plan: Dictionary = data().get("worked_plans", {}).get(plan_id, {})
	if plan.is_empty():
		return _reject("Unknown worked plan: " + plan_id)
	var shifts: Array = plan.get("shifts", [])
	for index in shifts.size():
		var shift := index + 1
		if shift <= committed_shift:
			continue
		var step: Dictionary = shifts[index]
		for field in fields_for_shift(shift):
			if step.has(field):
				var value = _normalise(field, step[field])
				if value != null:
					var current: Dictionary = _selections.get(shift, {})
					current[field] = value
					_selections[shift] = current
		if is_alarm_shift(shift) and String(step.get("action", "")) != String(_alarm.get("action", "")):
			_alarm = _empty_alarm()
			_alarm["action"] = String(step.get("action", ""))
	return {"accepted": true, "reason": "%s copied into the uncommitted shifts. Preview before committing." % String(plan.get("title", plan_id))}

# --- Shift 5 alarm task -----------------------------------------------------

## Starts the chosen PUMP or STACK task. `assisted` (timer-free) tasks have no
## countdown; timed tasks report their limit so the UI can resolve at expiry.
func start_alarm_task(assisted: bool) -> Dictionary:
	var action := String(_selections.get(int(data().get("alarm_shift", 5)), {}).get("action", ""))
	if not action in ["PUMP", "STACK"]:
		return _reject("Choose PUMP or STACK before starting a task; WAIT has no task.")
	if String(_alarm.get("state", TASK_IDLE)) != TASK_IDLE:
		return _reject("The %s task has already started." % action)
	var task: Dictionary = data().get("alarm_tasks", {}).get(action, {})
	_alarm["action"] = action
	_alarm["state"] = TASK_RUNNING
	_alarm["assisted"] = assisted
	return {"accepted": true, "reason": "%s task started." % action, "timer_seconds": 0 if assisted else int(task.get("timer_seconds", 0))}

## Accepts one task step. PUMP valves must be confirmed in order; STACK slots
## may be filled in any order. Each accepted step counts once. Completing every
## step resolves the task.
func task_step(step_index: int) -> Dictionary:
	if String(_alarm.get("state", TASK_IDLE)) != TASK_RUNNING:
		return _reject("Start the alarm task first.")
	var action := String(_alarm.get("action", ""))
	var steps := alarm_task_steps()
	if step_index < 0 or step_index >= steps:
		return _reject("That step is not part of the %s task." % action)
	var done: Array = _alarm.get("done", [])
	if done.has(step_index):
		return {"accepted": true, "duplicate": true, "reason": "Already confirmed.", "progress": done.size()}
	if action == "PUMP" and step_index != done.size():
		return _reject("Confirm the valves in order: step %d is next." % (done.size() + 1))
	done.append(step_index)
	_alarm["done"] = done
	if done.size() >= steps:
		_alarm["state"] = TASK_RESOLVED
	return {"accepted": true, "duplicate": false, "reason": "Step %d of %d confirmed." % [done.size(), steps], "progress": done.size()}

## Ends a running task with whatever progress it has (timer expiry or the
## player choosing to stop). Resolves once; later calls are no-ops.
func resolve_alarm_task() -> Dictionary:
	if String(_alarm.get("state", TASK_IDLE)) == TASK_RESOLVED:
		return {"accepted": true, "duplicate": true, "progress": alarm_progress(), "reason": "The task is already resolved."}
	if String(_alarm.get("state", TASK_IDLE)) != TASK_RUNNING:
		return _reject("No alarm task is running.")
	_alarm["state"] = TASK_RESOLVED
	return {"accepted": true, "duplicate": false, "progress": alarm_progress(), "reason": "Task resolved with %d of %d steps." % [alarm_progress(), alarm_task_steps()]}

## Clears task progress, e.g. when retrying the shift-5 checkpoint.
func reset_alarm_task() -> void:
	var action := String(_alarm.get("action", ""))
	_alarm = _empty_alarm()
	_alarm["action"] = action

func alarm_progress() -> int:
	return (_alarm.get("done", []) as Array).size()

func alarm_task_steps() -> int:
	return int(data().get("alarm_tasks", {}).get(String(_alarm.get("action", "")), {}).get("steps", 0))

## Task state for presentation: action, state, progress, steps, step labels,
## which steps are done and whether it runs without a timer.
func alarm_state() -> Dictionary:
	var task: Dictionary = data().get("alarm_tasks", {}).get(String(_alarm.get("action", "")), {})
	return {
		"action": String(_alarm.get("action", "")),
		"state": String(_alarm.get("state", TASK_IDLE)),
		"assisted": bool(_alarm.get("assisted", true)),
		"progress": alarm_progress(),
		"steps": int(task.get("steps", 0)),
		"timer_seconds": int(task.get("timer_seconds", 0)),
		"step_labels": task.get("step_labels", []).duplicate(),
		"done": (_alarm.get("done", []) as Array).duplicate(),
	}

# --- Endings ----------------------------------------------------------------

## Records a finished night so Golden hints can unlock after a first Bloom.
func record_ending(ending: String) -> void:
	if ending in ["BLOOM", "GOLDEN"]:
		_bloom_achieved = true

func bloom_achieved() -> bool:
	return _bloom_achieved

## Ending card and mastery stars for a simulation result. Stars: crew exposure
## Z<=3, no blackout, Alo alive. Returns {} when the result has no ending yet.
static func ending_report(result: Dictionary) -> Dictionary:
	var ending := String(result.get("ending", ""))
	if ending.is_empty():
		return {}
	var final_state: Dictionary = result.get("final_state", {})
	var snapshot: Dictionary = result.get("snapshot", {})
	var blackouts := int(snapshot.get("blackout_count", 0))
	for record in result.get("trace", []):
		if bool(record.get("blackout", false)) and blackouts == 0:
			blackouts = 1
	var stars := {
		"safe_exposure": int(final_state.get("Z", 0)) <= 3,
		"no_blackout": blackouts == 0,
		"alo_alive": int(final_state.get("H", 0)) > 0,
	}
	var card: Dictionary = data().get("endings", {}).get(ending, {}).duplicate(true)
	card["ending"] = ending
	card["stars"] = stars
	card["star_count"] = stars.values().count(true)
	card["unsafe_predicates"] = result.get("unsafe_predicates", []).duplicate()
	card["unlocks_chapter2"] = ending in ["BLOOM", "GOLDEN"]
	return card

# --- Persistence ------------------------------------------------------------

## Primitive, JSON-safe planning state for saves.
func snapshot() -> Dictionary:
	var selections := {}
	for shift in _selections:
		selections[str(shift)] = _selections[shift].duplicate()
	return {
		"schema_version": SCHEMA_VERSION,
		"selections": selections,
		"shared": _shared.duplicate(),
		"read": _read.duplicate(),
		"sign_offs": _sign_offs.duplicate(),
		"hint_level": _hint_level,
		"golden_hint_level": _golden_hint_level,
		"bloom_achieved": _bloom_achieved,
		"alarm": _alarm.duplicate(true),
	}

## Restores a snapshot after validating every field; an invalid snapshot is
## rejected without changing the live table.
func restore(raw) -> Dictionary:
	if not raw is Dictionary or float(raw.get("schema_version", 0)) != SCHEMA_VERSION:
		return _reject("Unsupported Mission Table snapshot.")
	for key in ["selections", "shared", "alarm"]:
		if not raw.get(key, null) is Dictionary:
			return _reject("Mission Table snapshot requires a Dictionary for " + key + ".")
	var selections := {}
	for key in raw.selections:
		var shift := int(key) if String(key).is_valid_int() else 0
		if shift < 1 or shift > SHIFT_COUNT or not raw.selections[key] is Dictionary:
			return _reject("Mission Table snapshot names an invalid shift.")
		var restored := {}
		for field in raw.selections[key]:
			if not fields_for_shift(shift).has(String(field)):
				return _reject("Mission Table snapshot has an invalid field for shift %d." % shift)
			var value = _normalise(String(field), raw.selections[key][field])
			if value == null:
				return _reject("Mission Table snapshot has an invalid value for shift %d." % shift)
			restored[String(field)] = value
		selections[shift] = restored
	var shared := {}
	for role_id in raw.shared:
		if not raw.shared[role_id] is bool:
			return _reject("Mission Table shared state must be boolean.")
		shared[String(role_id)] = raw.shared[role_id]
	# Receipts added with Class mode; saves written before them restore empty.
	var read := {}
	if raw.has("read"):
		if not raw.read is Dictionary:
			return _reject("Mission Table read receipts must be a Dictionary.")
		for role_id in raw.read:
			if not raw.read[role_id] is bool:
				return _reject("Mission Table read receipts must be boolean.")
			read[String(role_id)] = raw.read[role_id]
	var sign_offs := {}
	if raw.has("sign_offs"):
		if not raw.sign_offs is Dictionary:
			return _reject("Mission Table sign-offs must be a Dictionary.")
		for role_id in raw.sign_offs:
			if not raw.sign_offs[role_id] is String:
				return _reject("Mission Table sign-offs must name a plan key.")
			sign_offs[String(role_id)] = raw.sign_offs[role_id]
	for key in ["hint_level", "golden_hint_level"]:
		var value = raw.get(key, 0)
		if not (value is int or value is float) or float(value) < 0 or float(value) != floor(float(value)):
			return _reject("Mission Table hint level must be a whole number.")
	var alarm: Dictionary = raw.alarm
	if not alarm.get("state", TASK_IDLE) in [TASK_IDLE, TASK_RUNNING, TASK_RESOLVED] or not alarm.get("done", []) is Array or not alarm.get("action", "") is String:
		return _reject("Mission Table alarm task state is invalid.")
	_selections = selections
	_shared = shared
	_read = read
	_sign_offs = sign_offs
	_hint_level = int(raw.get("hint_level", 0))
	_golden_hint_level = int(raw.get("golden_hint_level", 0))
	_bloom_achieved = bool(raw.get("bloom_achieved", false))
	_alarm = _empty_alarm()
	_alarm["action"] = String(alarm.get("action", ""))
	_alarm["state"] = String(alarm.get("state", TASK_IDLE))
	_alarm["assisted"] = bool(alarm.get("assisted", true))
	var done: Array = []
	for value in alarm.get("done", []):
		if (value is int or value is float) and not done.has(int(value)):
			done.append(int(value))
	_alarm["done"] = done
	return {"accepted": true, "reason": "Mission Table restored."}

# --- Internals --------------------------------------------------------------

func _empty_alarm() -> Dictionary:
	return {"action": "", "state": TASK_IDLE, "assisted": true, "done": []}

func _alarm_locked(selection_data: Dictionary, field: String, value) -> bool:
	if String(selection_data.get("action", "")) != "STACK" or field == "action":
		return false
	var forced = _normalise(field, data().get("stack_forces", {}).get(field, null))
	return forced != null and value != forced

static func _normalise(field: String, value):
	for option in field_options(field):
		var option_value = option.get("value")
		if option_value is String and value is String and String(value).to_upper() == String(option_value):
			return String(option_value)
		if (option_value is int or option_value is float) and (value is int or value is float) and int(value) == int(option_value) and float(value) == floor(float(value)):
			return int(option_value)
	return null

static func _value_label(field: String, value) -> String:
	for option in field_options(field):
		if _normalise(field, option.get("value")) == value:
			return String(option.get("label", str(value)))
	return str(value)

func _role_name(role_id: String) -> String:
	for card in data().get("role_cards", []):
		if String(card.get("role_id", "")) == role_id:
			return String(card.get("name", role_id))
	return role_id

func _reject(reason: String) -> Dictionary:
	return {"accepted": false, "duplicate": false, "reason": reason}
