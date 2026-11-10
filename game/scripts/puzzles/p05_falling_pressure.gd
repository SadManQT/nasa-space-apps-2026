extends RefCounted
class_name P05FallingPressure

## Chapter 3 player evidence and decisions. The content file owns every answer,
## option, clue, feedback line and hint. No operation has a default selection.

const SCHEMA_VERSION := 1
const KINDS := ["choice", "number", "confirm"]
static var _content_cache: Dictionary = {}

var _path: String
var _puzzle_id: String
var _data: Dictionary = {}
var _selections := {}
var _found := {}
var _hints := {}
var _polls := {}
var _attempts := {}
var _first_time_seen := {}

func _init(path: String = "res://resources/campaign/content/p05_falling_pressure.json", puzzle_id: String = "P-05") -> void:
	_path = path
	_puzzle_id = puzzle_id

func data() -> Dictionary:
	if _data.is_empty():
		if _content_cache.has(_path):
			_data = _content_cache[_path]
			return _data
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(_path)) if FileAccess.file_exists(_path) else null
		if parsed is Dictionary and int(parsed.get("schema_version", 0)) == SCHEMA_VERSION and String(parsed.get("puzzle_id", "")) == _puzzle_id and parsed.get("steps", null) is Dictionary and parsed.get("scenes", null) is Dictionary and parsed.get("answers", null) is Dictionary:
			_data = parsed
			_content_cache[_path] = parsed
		else:
			push_error("Chapter 3 puzzle content is missing or invalid: " + _path)
	return _data

func is_step(target_id: String) -> bool:
	return data().get("steps", {}).has(target_id)

func step(target_id: String) -> Dictionary:
	return data().get("steps", {}).get(target_id, {}).duplicate(true)

func scene(scene_id: String) -> Dictionary:
	return data().get("scenes", {}).get(scene_id, {}).duplicate(true)

func puzzle(puzzle_id: String) -> Dictionary:
	return data().get("puzzles", {}).get(puzzle_id, {}).duplicate(true)

func role(role_id: String) -> Dictionary:
	return data().get("roles", {}).get(role_id, {"name": role_id.capitalize()}).duplicate(true)

func focus_label(target_id: String) -> String:
	return String(step(target_id).get("title", ""))

func puzzle_id_for_step(target_id: String) -> String:
	return _puzzle_id if is_step(target_id) else ""

func step_ids_for_scene(scene_id: String) -> Array:
	var result: Array = []
	for id in data().get("steps", {}):
		if String(data().steps[id].get("scene", "")) == scene_id:
			result.append(String(id))
	return result

func hint_ladder(target_id: String) -> Array:
	var scene_hints: Array = scene(String(step(target_id).get("scene", ""))).get("new_hints", [])
	return scene_hints.duplicate() if not scene_hints.is_empty() else (puzzle(puzzle_id_for_step(target_id)).get("hints", []) as Array).duplicate()

func validate_action(target_id: String, payload: Dictionary) -> String:
	if not is_step(target_id):
		return "Unknown Chapter 3 puzzle step."
	var answer: Dictionary = data().get("answers", {}).get(target_id, {})
	if answer.is_empty():
		return "This puzzle step has no authored answer key."
	var allowed: Array = answer.keys()
	allowed.append("_puzzle_action")
	if target_id.begins_with("p05_inspect_") and String(step(target_id).get("scene", "")) == "EX-CH03-S02":
		allowed.append("phase")
	if payload.has("_puzzle_action") and payload._puzzle_action != target_id:
		return "This decision is for a different Chapter 3 operation."
	for key in payload:
		if not allowed.has(key):
			return "This decision contains an unsupported input."
	for key in answer:
		if not payload.has(key) or not _same_value(payload[key], answer[key]):
			return String(step(target_id).get("wrong_reason", "That reading or decision does not match the evidence. Try the supported option."))
	return ""

func _same_value(actual, expected) -> bool:
	if expected is int or expected is float:
		return (actual is int or actual is float) and is_finite(float(actual)) and float(actual) == float(expected)
	return typeof(actual) == typeof(expected) and actual == expected

func select(target_id: String, field: String, value) -> Dictionary:
	var spec := step(target_id)
	if spec.is_empty():
		return _reject("Unknown Chapter 3 step: " + target_id)
	var current: Dictionary = _selections.get(target_id, {}).duplicate(true)
	match String(spec.get("kind", "")):
		"choice":
			if field != "option":
				return _reject("Choose one option.")
			var ids: Array = (spec.get("options", []) as Array).map(func(option): return String(option.get("id", "")))
			if not ids.has(String(value)):
				return _reject("That option is not on this card.")
			current["option"] = String(value)
		"number":
			if field != "value":
				return _reject("Enter a number from the instrument.")
			var bounds: Dictionary = spec.get("number", {})
			var number_error := _number_error(bounds, value)
			if not number_error.is_empty():
				return _reject(number_error)
			current["value"] = float(value)
		"confirm":
			if field != "confirmed":
				return _reject("Read back this check first.")
			current["confirmed"] = bool(value)
		_:
			return _reject("This step has no supported decision control.")
	if current != _selections.get(target_id, {}):
		_polls.erase(target_id)
	_selections[target_id] = current
	return {"accepted": true, "reason": "", "selection": current.duplicate(true)}

func reset(target_id: String) -> void:
	_selections.erase(target_id)
	_polls.erase(target_id)

func selection(target_id: String) -> Dictionary:
	return _selections.get(target_id, {}).duplicate(true)

func payload_for(target_id: String, _context: Dictionary = {}) -> Dictionary:
	var spec := step(target_id)
	if spec.is_empty():
		return _reject("Unknown Chapter 3 step: " + target_id)
	var current: Dictionary = _selections.get(target_id, {})
	var payload := {}
	var option_id := ""
	match String(spec.get("kind", "")):
		"choice":
			option_id = String(current.get("option", ""))
			if option_id.is_empty():
				return _reject("Choose one option first.", "incomplete")
			var found := false
			for option in spec.get("options", []):
				if String(option.get("id", "")) == option_id:
					payload = option.get("payload", {}).duplicate(true)
					found = true
			if not found:
				return _reject("Choose an option from this card.", "incomplete")
		"number":
			if not current.has("value"):
				return _reject("Enter the measured number first.", "incomplete")
			var number_error := _number_error(spec.get("number", {}), current.value)
			if not number_error.is_empty():
				return _reject(number_error, "incomplete")
			payload[String(spec.get("payload_key", "reading"))] = int(roundf(float(current.value)))
		"confirm":
			if not bool(current.get("confirmed", false)):
				return _reject("Read the check, then confirm it.", "incomplete")
			payload = spec.get("payload", {}).duplicate(true)
	return {"accepted": true, "reason": "", "payload": payload, "feedback_key": "", "option_id": option_id}

func feedback_for(target_id: String, option_id: String, _feedback_key: String, ledger_reason: String) -> String:
	for option in step(target_id).get("options", []):
		if String(option.get("id", "")) == option_id and not String(option.get("feedback", "")).is_empty():
			return String(option.feedback)
	return ledger_reason

func advisory_for(target_id: String, option_id: String) -> String:
	for option in step(target_id).get("options", []):
		if String(option.get("id", "")) == option_id:
			return String(option.get("advisory", ""))
	return ""

func count_attempt(target_id: String) -> int:
	_attempts[target_id] = int(_attempts.get(target_id, 0)) + 1
	return int(_attempts[target_id])

func attempts(target_id: String) -> int:
	return int(_attempts.get(target_id, 0))

func find_clue(scene_id: String, clue_id: String) -> Dictionary:
	var ids: Array = (scene(scene_id).get("clues", []) as Array).map(func(entry): return String(entry.get("id", "")))
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
	if not (step(target_id).get("poll", []) as Array).has(role_id):
		return _reject("That role is not polled for this decision.")
	if not bool(payload_for(target_id).get("accepted", false)):
		return _reject("Choose the decision before asking for a signature.")
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
		var status := "GO" if accepted else ("NO-GO" if String(spec.get("no_go_role", "")) == String(role_id) else "HOLD")
		result.append({"role_id": role_id, "name": String(role(role_id).get("name", role_id)), "status": status, "note": advisory if accepted else reason, "signed": signed_roles(target_id).has(role_id)})
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
	if not (data_in.get("schema_version", 0) is int or data_in.get("schema_version", 0) is float) or float(data_in.get("schema_version", 0)) != float(SCHEMA_VERSION):
		return _reject("Chapter 3 puzzle snapshot is incompatible.")
	for key in ["selections", "found", "hints", "polls", "attempts", "first_time_seen"]:
		if not data_in.get(key, null) is Dictionary:
			return _reject("Chapter 3 puzzle snapshot requires a Dictionary for " + key + ".")
	for target_id in data_in.selections:
		if not target_id is String or not is_step(target_id) or not data_in.selections[target_id] is Dictionary:
			return _reject("Chapter 3 selections name an unknown step.")
		var saved: Dictionary = data_in.selections[target_id]
		var spec: Dictionary = step(target_id)
		match String(spec.get("kind", "")):
			"choice":
				var options: Array = (spec.get("options", []) as Array).map(func(option): return String(option.get("id", "")))
				if saved.size() != 1 or not saved.get("option", null) is String or not options.has(saved.option):
					return _reject("Chapter 3 save contains an invalid option.")
			"number":
				if saved.size() != 1 or not saved.has("value") or not _number_error(spec.get("number", {}), saved.value).is_empty():
					return _reject("Chapter 3 save contains an invalid instrument reading.")
			"confirm":
				if saved.size() != 1 or not saved.get("confirmed", null) is bool:
					return _reject("Chapter 3 save contains an invalid confirmation.")
			_:
				return _reject("Chapter 3 save contains an unsupported control.")
	for scene_id in data_in.found:
		if not scene_id is String or not data().get("scenes", {}).has(scene_id) or not data_in.found[scene_id] is Array:
			return _reject("Chapter 3 save contains an invalid evidence board.")
		var known: Array = (scene(scene_id).get("clues", []) as Array).map(func(clue): return String(clue.get("id", "")))
		var seen: Array = []
		for clue_id in data_in.found[scene_id]:
			if not clue_id is String or not known.has(clue_id) or seen.has(clue_id):
				return _reject("Chapter 3 save contains an invalid clue.")
			seen.append(clue_id)
	for target_id in data_in.hints:
		if not target_id is String or not is_step(target_id) or not _whole_in_range(data_in.hints[target_id], 0, hint_ladder(target_id).size()):
			return _reject("Chapter 3 save contains an invalid hint tier.")
	for target_id in data_in.polls:
		if not target_id is String or not is_step(target_id) or not data_in.polls[target_id] is Array or not data_in.selections.has(target_id):
			return _reject("Chapter 3 save contains an invalid team poll.")
		var allowed: Array = step(target_id).get("poll", [])
		var seen_roles: Array = []
		for role_id in data_in.polls[target_id]:
			if not role_id is String or not allowed.has(role_id) or seen_roles.has(role_id):
				return _reject("Chapter 3 save contains an invalid poll signature.")
			seen_roles.append(role_id)
	for target_id in data_in.attempts:
		if not target_id is String or not is_step(target_id) or not _whole_in_range(data_in.attempts[target_id], 0, 1000000):
			return _reject("Chapter 3 save contains an invalid attempt count.")
	for puzzle_id in data_in.first_time_seen:
		if puzzle_id != _puzzle_id or not data_in.first_time_seen[puzzle_id] is bool:
			return _reject("Chapter 3 save contains an invalid first-use card.")
	_selections = data_in.selections.duplicate(true)
	_found = data_in.found.duplicate(true)
	_hints = data_in.hints.duplicate(true)
	_polls = data_in.polls.duplicate(true)
	_attempts = data_in.attempts.duplicate(true)
	_first_time_seen = data_in.first_time_seen.duplicate(true)
	return {"accepted": true, "reason": "Chapter 3 puzzle state restored."}

func _number_error(bounds: Dictionary, value) -> String:
	if not (value is int or value is float) or not is_finite(float(value)):
		return "Enter a finite number from the instrument."
	var reading := float(value)
	var minimum := float(bounds.get("min", 0))
	var maximum := float(bounds.get("max", 100))
	var increment := float(bounds.get("step", 1))
	if reading < minimum or reading > maximum:
		return "Use a reading within the instrument scale."
	if increment <= 0.0 or absf((reading - minimum) / increment - roundf((reading - minimum) / increment)) > 0.000001:
		return "Use a marked reading from the instrument scale."
	return ""

func _whole_in_range(value, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == float(int(value)) and int(value) >= minimum and int(value) <= maximum

func _reject(reason: String, feedback_key: String = "") -> Dictionary:
	return {"accepted": false, "reason": reason, "feedback_key": feedback_key, "payload": {}, "option_id": ""}
