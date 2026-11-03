extends RefCounted
class_name CampaignDialogueService

const ContentScript = preload("res://scripts/content/content_loader.gd")

var _content: Dictionary = {}
var _bound := false

func _init(content: Dictionary = {}) -> void:
	if content.is_empty():
		content = ContentScript.load_full()
	bind(content)

func bind(content: Dictionary) -> Dictionary:
	_content = content.duplicate(true)
	_bound = not _content.is_empty()
	return {"accepted": _bound, "content_revision": String(_content.get("content_revision", ""))}

func content_revision() -> String:
	return String(_content.get("content_revision", ""))

func dialogue_by_id(line_id: String) -> Dictionary:
	return ContentScript.dialogue_by_id(_content, line_id)

func line_available(line: Dictionary, acquired_flags: Array = []) -> bool:
	var flags := _flag_set(acquired_flags)
	for required in line.get("knowledge_required", []):
		if not flags.has(String(required)):
			return false
	return true

func lines_for_scene(scene_id: String, acquired_flags: Array = [], include_locked: bool = false) -> Array:
	var scene := ContentScript.scene_by_id(_content, scene_id)
	if scene.is_empty():
		return []
	var result: Array = []
	for raw_line in scene.get("dialogue", []):
		if not raw_line is Dictionary:
			continue
		var line: Dictionary = raw_line.duplicate(true)
		var available := line_available(line, acquired_flags)
		if available:
			line["available"] = true
			result.append(line)
		elif include_locked:
			# Keep the existence, ID, order and origin visible to a journal/UI
			# without leaking the future text itself.
			line["available"] = false
			line["text"] = ""
			line["line"] = ""
			line["locked_reason"] = "Source not acquired yet."
			result.append(line)
	return result

func caption_for_line(line_id: String, acquired_flags: Array = []) -> Dictionary:
	var line := dialogue_by_id(line_id)
	if line.is_empty():
		return {"available": false, "line_id": line_id, "text": "", "reason": "Unknown dialogue line."}
	if not line_available(line, acquired_flags):
		return {
			"available": false,
			"line_id": line_id,
			"text": "",
			"speaker": String(line.get("speaker_label", "")),
			"origin": String(line.get("origin", "")),
			"origin_label": String(line.get("origin_label", "")),
			"reason": "Source not acquired yet.",
		}
	return {
		"available": true,
		"line_id": line_id,
		"text": String(line.get("text", "")),
		"speaker": String(line.get("speaker_label", "")),
		"speaker_id": String(line.get("speaker_id", "")),
		"origin": String(line.get("origin", "")),
		"origin_label": String(line.get("origin_label", "")),
		"evidence_tag": String(line.get("evidence_tag", "")),
		"source_refs": line.get("source_refs", []).duplicate(true),
	}

func transcript(acquired_flags: Array = [], acknowledged_line_ids: Array = []) -> Array:
	var acknowledged := _flag_set(acknowledged_line_ids)
	var result: Array = []
	for raw_line in _content.get("dialogue", []):
		if not raw_line is Dictionary:
			continue
		var line: Dictionary = raw_line
		if not line_available(line, acquired_flags):
			continue
		var entry := caption_for_line(String(line.get("id", "")), acquired_flags)
		entry["acknowledged"] = acknowledged.has(String(line.get("id", "")))
		result.append(entry)
	return result

## This is the only dialogue-side output that should be sent to a state
## director. It is a primitive acknowledgement command; it intentionally has
## no completion predicate, knowledge grant or physical-operation payload.
func acknowledgement_command(line_id: String, state_revision: int, mission_id: String, scene_id: String, issuer: String = "dialogue") -> Dictionary:
	var line := dialogue_by_id(line_id)
	return {
		"command_id": "dialogue:%s:%d" % [line_id, state_revision],
		"issuer": issuer,
		"owning_mission_id": mission_id,
		"owning_scene_id": scene_id,
		"expected_state_revision": state_revision,
		"target_id": line_id,
		"verb": "acknowledge_line",
		"payload": {"line_id": line_id, "dialogue_only": true},
		"source_exists": not line.is_empty(),
		"completes_predicate": false,
	}

func acknowledgement_result(line_id: String, state_revision: int, mission_id: String, scene_id: String) -> Dictionary:
	## Read-only presentation receipt for callers that do not have a director.
	## It does not mutate this service or imply scene completion.
	return {
		"accepted": not dialogue_by_id(line_id).is_empty(),
		"duplicate": false,
		"input_revision": state_revision,
		"output_revision": state_revision,
		"receipt_id": "",
		"deltas": [{"field": "acknowledged_line_ids", "value": line_id}],
		"events": [{"type": "dialogue_acknowledged", "mission_id": mission_id, "scene_id": scene_id}],
		"warnings": ["Dialogue acknowledgement does not complete a scene or mission."],
		"unsafe_predicates": [],
		"reason": "Caption acknowledged; physical operation remains separate.",
		"next_phase": "",
	}

func _flag_set(values: Array) -> Dictionary:
	var result := {}
	for value in values:
		result[String(value)] = true
	return result
