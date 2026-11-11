extends "res://scripts/puzzles/p05_falling_pressure.gd"
class_name Chapter2Puzzles

## M3-2P: the player's selections, filed clues, hints and attempts for every
## P-03 and P-04 physical step. The cards are built from the authored content
## files (choices, clues, hints, panel_steps); the P-03/P-04 rule models stay the
## authority for anything the route commits. A knowledge check whose answer is
## not part of the route payload is checked here, from the same content.

const GateCatalog = preload("res://scripts/missions/chapter2_gate_catalog.gd")
const SOURCES := {"P-03": "res://resources/campaign/content/p03_pollination.json", "P-04": "res://resources/campaign/content/p04_recorder_reconstruction.json"}
const ROLES := {
	"amara": {"name": "Amara", "role": "atmosphere", "letter": "A"},
	"kai": {"name": "Kai", "role": "power and heat", "letter": "K"},
	"mei": {"name": "Mei", "role": "horticulture", "letter": "M"},
	"rafi": {"name": "Rafi", "role": "safety", "letter": "R"},
	"all": {"name": "the whole crew", "role": "shared", "letter": "*"},
}
static var _built: Dictionary = {}

func _init() -> void:
	super("", "CH2")

func data() -> Dictionary:
	if _built.is_empty():
		_built = _build()
	return _built

func puzzle_id_for_step(target_id: String) -> String:
	return String(step(target_id).get("puzzle", ""))

func hint_ladder(target_id: String) -> Array:
	var spec := step(target_id)
	return (data().get("hints", {}).get(String(spec.get("puzzle", "")), {}).get(String(spec.get("hints", "")), []) as Array).duplicate()

## Records one field of a multi-field card ("fields"); other kinds use the base.
func select(target_id: String, field: String, value) -> Dictionary:
	var spec := step(target_id)
	if String(spec.get("kind", "")) != "fields":
		return super.select(target_id, field, value)
	var options: Array = spec.get("fields", {}).get(field, {}).get("options", [])
	if options.is_empty():
		return _reject("That line is not on this card.")
	if not options.map(func(option): return String(option.get("id", ""))).has(String(value)):
		return _reject("That option is not on this card.")
	var current: Dictionary = _selections.get(target_id, {}).duplicate(true)
	current[field] = String(value)
	_selections[target_id] = current
	return {"accepted": true, "reason": "", "selection": current.duplicate(true)}

func payload_for(target_id: String, context: Dictionary = {}) -> Dictionary:
	var spec := step(target_id)
	if String(spec.get("kind", "")) != "fields":
		return super.payload_for(target_id, context)
	var current: Dictionary = _selections.get(target_id, {})
	var payload := {}
	for field in spec.get("fields", {}):
		if not current.has(field):
			return _reject("Choose a line for %s first." % String(spec.fields[field].get("label", field)), "incomplete")
		if bool(spec.get("payload_fields", false)):
			payload[field] = _option(spec.fields[field].get("options", []), String(current[field])).get("value", "")
	return {"accepted": true, "reason": "", "payload": payload, "feedback_key": "", "option_id": ""}

## Empty when the selection passes this card's own knowledge check. Steps whose
## answer travels in the payload return empty: the route model judges them.
func knowledge_check(target_id: String) -> String:
	var spec := step(target_id)
	if not bool(spec.get("local_check", false)):
		return ""
	var current: Dictionary = _selections.get(target_id, {})
	if String(spec.get("kind", "")) == "choice":
		var option := _option(spec.get("options", []), String(current.get("option", "")))
		return "" if bool(option.get("correct", false)) else String(option.get("feedback", spec.get("wrong_reason", "")))
	if String(spec.get("kind", "")) == "fields":
		for field in spec.get("fields", {}):
			var option := _option(spec.fields[field].get("options", []), String(current.get(field, "")))
			if not bool(option.get("correct", false)):
				return String(option.get("feedback", spec.get("wrong_reason", "")))
	return ""

func feedback_for(target_id: String, option_id: String, feedback_key: String, ledger_reason: String) -> String:
	var local := knowledge_check(target_id)
	if not local.is_empty():
		return local
	var spec := step(target_id)
	if String(spec.get("kind", "")) == "fields":
		var current: Dictionary = _selections.get(target_id, {})
		for field in spec.get("fields", {}):
			var option := _option(spec.fields[field].get("options", []), String(current.get(field, "")))
			if not option.is_empty() and not bool(option.get("correct", false)):
				return String(option.get("feedback", ledger_reason))
		return ledger_reason
	return super.feedback_for(target_id, option_id, feedback_key, ledger_reason)

## Multi-field selections are validated here; the base restores the rest.
func restore(data_in: Dictionary) -> Dictionary:
	if not data_in.get("selections", null) is Dictionary:
		return _reject("Chapter 2 puzzle snapshot requires a Dictionary for selections.")
	var copy := data_in.duplicate(true)
	var fields_selections := {}
	for target_id in data_in.selections:
		if not target_id is String or String(step(target_id).get("kind", "")) != "fields":
			continue
		var saved = data_in.selections[target_id]
		if not saved is Dictionary:
			return _reject("Chapter 2 save contains an invalid card.")
		var fields: Dictionary = step(target_id).get("fields", {})
		for field in saved:
			if not fields.has(field) or _option(fields[field].get("options", []), String(saved[field])).is_empty():
				return _reject("Chapter 2 save contains an invalid line.")
		fields_selections[target_id] = saved.duplicate(true)
		copy.selections.erase(target_id)
	# First-use cards are kept per puzzle (P-03, P-04), not under the base id.
	var seen = data_in.get("first_time_seen", {})
	if not seen is Dictionary:
		return _reject("Chapter 2 save contains an invalid first-use card.")
	for puzzle_id in seen:
		if not SOURCES.has(puzzle_id) or not seen[puzzle_id] is bool:
			return _reject("Chapter 2 save contains an invalid first-use card.")
	copy["first_time_seen"] = {}
	var result := super.restore(copy)
	if bool(result.get("accepted", false)):
		for target_id in fields_selections:
			_selections[target_id] = fields_selections[target_id]
		_first_time_seen = seen.duplicate(true)
	return result

func _option(options: Array, id: String) -> Dictionary:
	for option in options:
		if String(option.get("id", "")) == id:
			return option
	return {}

func _build() -> Dictionary:
	var result := {"schema_version": SCHEMA_VERSION, "puzzle_id": "CH2", "roles": ROLES.duplicate(true), "puzzles": {}, "scenes": {}, "steps": {}, "answers": {}, "hints": {}}
	var targets := {}
	for scene_id in GateCatalog.scene_ids():
		for target in GateCatalog.targets_for_scene(scene_id):
			targets[String(target.target_id)] = target
	for puzzle_id in SOURCES:
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(SOURCES[puzzle_id])) if FileAccess.file_exists(SOURCES[puzzle_id]) else null
		if not parsed is Dictionary or not parsed.get("panel_steps", null) is Dictionary:
			push_error("Chapter 2 puzzle content is missing or invalid: " + String(SOURCES[puzzle_id]))
			continue
		var content: Dictionary = parsed
		var panel: Dictionary = content.get("panel", {})
		result.puzzles[puzzle_id] = {"title": String(content.get("title", "")), "hints": content.get("hints", {}).values()[0] if not content.get("hints", {}).is_empty() else [], "first_time_card": panel.get("first_time_card", {})}
		result.hints[puzzle_id] = content.get("hints", {})
		for scene in content.get("scenes", []):
			var scene_id := String(scene.scene_id)
			var stage: Dictionary = content.get("stages", {}).get(String(scene.get("stage", "")), {})
			var clues: Array = []
			for clue in content.get("clues", []):
				if String(clue.get("scene_id", "")) == scene_id:
					clues.append({"id": String(clue.id), "kind": String(clue.get("kind", "")).replace("_", " "), "where": String(clue.get("label", "")), "text": String(clue.get("text", "")), "holders": [String(clue.get("holder", "all"))], "line_id": String(clue.get("line_id", ""))})
			result.scenes[scene_id] = {"id": scene_id, "mission": String(scene.mission_id), "stage": String(scene.get("stage", "")), "title": String(stage.get("label", "")), "goal": String(stage.get("goal", "")), "takeaway": String(stage.get("takeaway", "")), "aha": String(stage.get("takeaway", "")), "clues": clues, "flight_rules": panel.get("flight_rules", []), "risk": panel.get("risk", {}), "wrong_idea": String(panel.get("wrong_idea", ""))}
		for target_id in content.panel_steps:
			var target: Dictionary = targets.get(target_id, {})
			if target.is_empty():
				push_error("Chapter 2 panel step has no physical target: " + String(target_id))
				continue
			var spec := _step_spec(content, content.panel_steps[target_id], target)
			spec["puzzle"] = puzzle_id
			if String(spec.get("why", "")).is_empty():
				spec["why"] = String(result.scenes.get(spec.scene, {}).get("goal", ""))
			result.steps[target_id] = spec
	return result

func _step_spec(content: Dictionary, entry: Dictionary, target: Dictionary) -> Dictionary:
	var scene_id := String(target.get("owning_scene_id", ""))
	var spec := {"scene": scene_id, "title": String(target.get("focus_label", "")), "hints": String(entry.get("hints", "runs" if String(target.get("puzzle_id", "")) == "P-03" else "tokens")), "why": "", "wrong_reason": "That does not match the evidence yet. Read the clues and try again."}
	if entry.has("confirm"):
		spec.merge({"kind": "confirm", "goal": String(entry.confirm), "readback": String(entry.confirm), "payload": {}})
		return spec
	var choice: Dictionary = content.get("choices", {}).get(String(entry.get("check", "")), {})
	spec["goal"] = String(choice.get("prompt", ""))
	if choice.has("options"):
		var key := String(choice.get("payload_key", ""))
		spec.merge({"kind": "choice", "local_check": key.is_empty(), "options": []})
		for option in choice.options:
			spec.options.append({"id": String(option.value), "label": String(option.label), "detail": "", "correct": bool(option.get("correct", false)), "feedback": String(option.get("feedback", "")), "payload": {key: String(option.value)} if not key.is_empty() else {}})
	elif choice.has("fields"):
		spec.merge({"kind": "fields", "local_check": false, "payload_fields": true, "fields": {}})
		for field in choice.fields:
			spec.fields[field] = {"label": String(field).replace("_", " ").capitalize(), "options": (choice.fields[field] as Array).map(func(option): return {"id": String(option.value), "value": String(option.value), "label": String(option.label), "correct": bool(option.get("correct", false)), "feedback": String(option.get("feedback", ""))})}
	elif choice.has("statements"):
		spec.merge({"kind": "fields", "local_check": true, "payload_fields": false, "fields": {}})
		for statement in choice.statements:
			spec.fields[String(statement.id)] = {"label": String(statement.text), "options": (choice.get("columns", []) as Array).map(func(column): return {"id": String(column), "label": String(column).capitalize(), "correct": String(column) == String(statement.answer), "feedback": "%s %s" % [String(choice.get("wrong_feedback", "")), String(statement.get("feedback", ""))]})}
	elif choice.has("items"):
		spec.merge({"kind": "fields", "local_check": true, "payload_fields": false, "fields": {}})
		spec["why"] = String(choice.get("receipt_note", ""))
		for item in choice.items:
			var include := bool(item.get("include", false))
			var leave_out_note := "The package needs the %s; without it Ferreira cannot check the copy." % String(item.label).to_lower()
			spec.fields[String(item.id)] = {"label": String(item.label), "options": [
				{"id": "include", "label": "Include", "correct": include, "feedback": String(item.get("feedback", ""))},
				{"id": "leave_out", "label": "Leave out", "correct": not include, "feedback": leave_out_note}]}
	return spec
