extends RefCounted
class_name Chapter4Puzzles

## P-07 Survey and Return and P-08 Recover Without Ruining: the player's
## decisions behind every Chapter 4 operation.
##
## Holds only what the player has chosen, found and read: per-step selections
## (route choices, slope/reserve numbers, scanner calibration, tagged samples,
## glovebox warm-up stages, specimen count), found clues, revealed hints and
## Go/No-Go signatures. Step content lives in
## res://resources/campaign/content/chapter4_puzzles.json; answer keys live in
## res://resources/campaign/profiles/campaign_rules.json (`chapter4`).

const DATA_PATH := "res://resources/campaign/content/chapter4_puzzles.json"
const RULES_PATH := "res://resources/campaign/profiles/campaign_rules.json"
const SCHEMA_VERSION := 1
const KINDS := ["choice", "assign", "select_many", "number", "route", "dial", "lock", "procedure", "checks", "confirm", "settings"]

static var _data_cache: Dictionary = {}
static var _rules_cache: Dictionary = {}

var _selections := {}
var _found := {}
var _hints := {}
var _polls := {}
var _attempts := {}
var _first_time_seen := {}

static func data() -> Dictionary:
	if _data_cache.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH)) if FileAccess.file_exists(DATA_PATH) else null
		if parsed is Dictionary and int(parsed.get("schema_version", 0)) == SCHEMA_VERSION and parsed.get("steps", null) is Dictionary and parsed.get("scenes", null) is Dictionary:
			_data_cache = parsed
		else:
			push_error("Chapter 4 puzzle content is missing or invalid: " + DATA_PATH)
	return _data_cache

static func rules() -> Dictionary:
	if _rules_cache.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(RULES_PATH)) if FileAccess.file_exists(RULES_PATH) else null
		if parsed is Dictionary and parsed.get("chapter4", null) is Dictionary:
			_rules_cache = parsed.chapter4.duplicate(true)
		else:
			push_error("Chapter 4 answer keys are missing from " + RULES_PATH)
	return _rules_cache

static func is_step(target_id: String) -> bool:
	return data().get("steps", {}).has(target_id)

static func step(target_id: String) -> Dictionary:
	return data().get("steps", {}).get(target_id, {}).duplicate(true)

static func scene(scene_id: String) -> Dictionary:
	return data().get("scenes", {}).get(scene_id, {}).duplicate(true)

static func puzzle(puzzle_id: String) -> Dictionary:
	return data().get("puzzles", {}).get(puzzle_id, {}).duplicate(true)

static func role(role_id: String) -> Dictionary:
	return data().get("roles", {}).get(role_id, {"name": role_id.capitalize(), "letter": role_id.left(1).to_upper()}).duplicate(true)

static func focus_label(target_id: String) -> String:
	return String(step(target_id).get("title", ""))

static func step_ids_for_scene(scene_id: String) -> Array:
	var result: Array = []
	for id in data().get("steps", {}):
		if String(data().steps[id].get("scene", "")) == scene_id:
			result.append(String(id))
	return result

static func puzzle_id_for_step(target_id: String) -> String:
	return "P-07" if target_id.begins_with("p07_") else ("P-08" if target_id.begins_with("p08_") else "")

static func hint_ladder(target_id: String) -> Array:
	var ladder: Array = puzzle(puzzle_id_for_step(target_id)).get("hints", []).duplicate()
	ladder.append_array(scene(String(step(target_id).get("scene", ""))).get("new_hints", []))
	return ladder

static func validate(action: String, payload: Dictionary) -> String:
	var key := rules()
	if key.is_empty():
		return "Chapter 4 answer keys are unavailable."
	match action:
		"p07_choose_route_b":
			if String(payload.get("route", "")) != String(key.valid_route):
				return "Route B is the only route within both slope and return-reserve limits."
		"p07_verify_slope":
			var slope := int(payload.get("slope", -1))
			if slope < 0 or slope > int(key.max_slope_limit):
				return "The surveyed route must remain at or below the 15 degree game limit."
		"p07_verify_return_reserve":
			if int(payload.get("reserve", -1)) < int(key.min_return_reserve):
				return "The rover must retain at least 30 return-reserve units."
		"p07_set_threshold_12":
			if int(payload.get("reference", -1)) != int(key.dry_reference) or int(payload.get("threshold", -1)) != int(key.scanner_threshold):
				return "The detection threshold is dry reference 2 plus 10, which equals 12."
		"p07_tag_positive_18", "p07_tag_positive_19":
			var pos: Array = key.get("positive_readings", [18, 19])
			var reading := int(payload.get("reading", -1))
			var found_pos := false
			for item in pos:
				if int(item) == reading:
					found_pos = true
			if not found_pos:
				return "Only readings 18 and 19 are positive in the supplied survey."
		"p07_retain_negative_2":
			if int(payload.get("reading", -1)) != int(key.negative_reading):
				return "Reading 2 is the negative control."
		"p08_warm_cold":
			if String(payload.get("stage", "")) != String(key.warm_stage_1):
				return "The sealed warm-up must move from cold to cool first."
		"p08_warm_room":
			if String(payload.get("stage", "")) != String(key.warm_stage_2):
				return "The sealed warm-up must finish at room stage."
		"p08_inventory_12":
			if int(payload.get("count", -1)) != int(key.vault_inventory_count):
				return "The vault inventory requires twelve distinct specimens."
	return ""

func select(target_id: String, field: String, value) -> Dictionary:
	var spec := step(target_id)
	if spec.is_empty():
		return _reject("Unknown Chapter 4 step: " + target_id)
	var kind := String(spec.get("kind", ""))
	var current: Dictionary = _selections.get(target_id, {}).duplicate(true)
	match kind:
		"choice":
			if field != "option":
				return _reject("Choose one option.")
			var ids: Array = (spec.get("options", []) as Array).map(func(option): return String(option.id))
			if not ids.has(String(value)):
				return _reject("That option is not on this card.")
			current["option"] = String(value)
		"number":
			if field != "value" or not (value is int or value is float) or not is_finite(float(value)):
				return _reject("Enter a number.")
			var number: Dictionary = spec.get("number", {})
			current["value"] = clampf(float(value), float(number.get("min", 0)), float(number.get("max", 100)))
		"confirm":
			current["confirmed"] = true if value else false
		_:
			return _reject("This step has no decision to record.")
	_selections[target_id] = current
	return {"accepted": true, "reason": "", "selection": current.duplicate(true)}

func reset(target_id: String) -> void:
	_selections.erase(target_id)

func selection(target_id: String) -> Dictionary:
	return _selections.get(target_id, {}).duplicate(true)

func payload_for(target_id: String, _context: Dictionary = {}) -> Dictionary:
	var spec := step(target_id)
	if spec.is_empty():
		return _reject("Unknown Chapter 4 step: " + target_id)
	var current: Dictionary = _selections.get(target_id, {})
	var kind := String(spec.get("kind", ""))
	var key := String(spec.get("payload_key", ""))
	var payload := {}
	var option_id := ""
	match kind:
		"choice":
			option_id = String(current.get("option", ""))
			if option_id.is_empty():
				return _reject("Choose one option first.", "incomplete")
			for option in spec.get("options", []):
				if String(option.id) == option_id:
					payload = option.get("payload", {}).duplicate(true)
		"number":
			if not current.has("value"):
				return _reject("Enter the number first.", "incomplete")
			payload[key] = int(roundf(float(current.value)))
		"confirm":
			if not bool(current.get("confirmed", false)):
				return _reject("Read the line, then confirm it.", "incomplete")
			payload = spec.get("payload", {}).duplicate(true)
	return {"accepted": true, "reason": "", "payload": payload, "feedback_key": "", "option_id": option_id}

func feedback_for(target_id: String, option_id: String, feedback_key: String, ledger_reason: String) -> String:
	var spec := step(target_id)
	var feedback: Dictionary = spec.get("feedback", {})
	if not feedback_key.is_empty() and feedback.has(feedback_key):
		return String(feedback[feedback_key])
	for option in spec.get("options", []):
		if String(option.id) == option_id and not String(option.get("feedback", "")).is_empty():
			return String(option.feedback)
	if String(spec.get("kind", "")) == "number":
		return String(feedback.get("low" if ledger_reason.contains("at least") or ledger_reason.contains("below") else "wrong", ledger_reason))
	return ledger_reason

func advisory_for(target_id: String, option_id: String) -> String:
	for option in step(target_id).get("options", []):
		if String(option.id) == option_id:
			return String(option.get("advisory", ""))
	return ""

func count_attempt(target_id: String) -> int:
	_attempts[target_id] = int(_attempts.get(target_id, 0)) + 1
	return int(_attempts[target_id])

func attempts(target_id: String) -> int:
	return int(_attempts.get(target_id, 0))

func find_clue(scene_id: String, clue_id: String) -> Dictionary:
	var ids: Array = (scene(scene_id).get("clues", []) as Array).map(func(entry): return String(entry.id))
	if not ids.has(clue_id):
		return _reject("That clue is not in this scene.")
	var found: Array = _found.get(scene_id, []).duplicate()
	if found.has(clue_id):
		return {"accepted": true, "duplicate": true, "reason": "Already on the evidence board."}
	found.append(clue_id)
	_found[scene_id] = found
	return {"accepted": true, "duplicate": false, "reason": "Filed to the evidence board."}

func found_clues(scene_id: String) -> Array:
	return _found.get(scene_id, []).duplicate()

func reveal_hint(target_id: String) -> Dictionary:
	var ladder := hint_ladder(target_id)
	var level := int(_hints.get(target_id, 0))
	if level >= ladder.size():
		return _reject("Every hint for this step is already shown.")
	_hints[target_id] = level + 1
	return {"accepted": true, "level": level + 1, "label": "H%d" % (level + 1), "text": String(ladder[level])}

func revealed_hints(target_id: String) -> Array:
	var ladder := hint_ladder(target_id)
	var result: Array = []
	for index in mini(int(_hints.get(target_id, 0)), ladder.size()):
		result.append({"label": "H%d" % (index + 1), "text": String(ladder[index])})
	return result

func sign_poll(target_id: String, role_id: String) -> Dictionary:
	var roles: Array = step(target_id).get("poll", [])
	if not roles.has(role_id):
		return _reject("That role is not polled for this decision.")
	var signed: Array = _polls.get(target_id, []).duplicate()
	if not signed.has(role_id):
		signed.append(role_id)
	_polls[target_id] = signed
	return {"accepted": true, "reason": "%s signed." % String(role(role_id).get("name", role_id))}

func signed_roles(target_id: String) -> Array:
	return _polls.get(target_id, []).duplicate()

func poll_status(target_id: String, accepted: bool, reason: String, advisory: String) -> Array:
	var spec := step(target_id)
	var result: Array = []
	for role_id in spec.get("poll", []):
		var status := "GO"
		var note := ""
		if not accepted and String(spec.get("no_go_role", "")) == String(role_id):
			status = "NO-GO"
			note = reason
		elif not accepted:
			status = "HOLD"
			note = "Waiting for the check."
		elif not advisory.is_empty():
			status = "ADVISORY"
			note = advisory
		result.append({"role_id": role_id, "name": String(role(role_id).get("name", role_id)), "status": status, "note": note, "signed": signed_roles(target_id).has(role_id)})
	return result

func mark_first_time_seen(puzzle_id: String) -> void:
	_first_time_seen[puzzle_id] = true

func first_time_seen(puzzle_id: String) -> bool:
	return bool(_first_time_seen.get(puzzle_id, false))

func flags() -> Dictionary:
	return {}

func snapshot() -> Dictionary:
	return {"schema_version": SCHEMA_VERSION, "selections": _selections.duplicate(true), "found": _found.duplicate(true), "hints": _hints.duplicate(true), "polls": _polls.duplicate(true), "attempts": _attempts.duplicate(true), "first_time_seen": _first_time_seen.duplicate(true)}

func restore(data_in: Dictionary) -> Dictionary:
	var version = data_in.get("schema_version", 0)
	if not (version is int or version is float) or float(version) != float(SCHEMA_VERSION):
		return _reject("Chapter 4 puzzle snapshot is incompatible.")
	for key in ["selections", "found", "hints", "polls", "attempts", "first_time_seen"]:
		if not data_in.get(key, null) is Dictionary:
			return _reject("Chapter 4 puzzle snapshot requires a Dictionary for " + key + ".")
	for target_id in data_in.selections:
		if not is_step(String(target_id)) or not data_in.selections[target_id] is Dictionary:
			return _reject("Chapter 4 selections name an unknown step.")
	_selections = data_in.selections.duplicate(true)
	_found = data_in.found.duplicate(true)
	_hints = data_in.hints.duplicate(true)
	_polls = data_in.polls.duplicate(true)
	_attempts = data_in.attempts.duplicate(true)
	_first_time_seen = data_in.first_time_seen.duplicate(true)
	return {"accepted": true, "reason": "Chapter 4 puzzle state restored."}

func _reject(reason: String, feedback_key: String = "") -> Dictionary:
	return {"accepted": false, "reason": reason, "feedback_key": feedback_key, "payload": {}, "option_id": ""}
