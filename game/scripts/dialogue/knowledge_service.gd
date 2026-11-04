extends RefCounted
class_name CampaignKnowledge

## Canonical scene IDs identify acquired records; observations use the owning
## operation's existing label. Never copy a scene's future prose into the journal.
const Content = preload("res://scripts/content/content_loader.gd")
const Chapter1 = preload("res://scripts/missions/chapter1_gate_catalog.gd")
const Chapter2 = preload("res://scripts/missions/chapter2_gate_catalog.gd")
const Extended = preload("res://scripts/missions/extended_gate_catalog.gd")
static var _content: Dictionary = {}

static func content() -> Dictionary:
	if _content.is_empty():
		_content = Content.load_full()
	return _content

static func grant_operation(next: Dictionary, command: Dictionary) -> Array:
	var scene_id := String(command.get("owning_scene_id", ""))
	var scene := Content.scene_by_id(content(), scene_id)
	if scene.is_empty() or command.get("verb") == "acknowledge_line":
		return []
	var chapter := int(scene.get("chapter_number", 0))
	var targets: Array = Chapter1.targets_for_scene(scene_id) if chapter == 1 else Chapter2.targets_for_scene(scene_id) if chapter == 2 else Extended.targets_for_scene(scene_id)
	var matches := targets.filter(func(target): return target.get("command_id") == command.get("command_id"))
	if matches.is_empty():
		return []
	var target: Dictionary = matches[0]
	var events: Array = []
	if not next.acquired_evidence_ids.has(scene_id):
		next.acquired_evidence_ids.append(scene_id)
		events.append({"type": "evidence_acquired", "evidence_id": scene_id})
	var record := {}
	for item in next.knowledge:
		if item is Dictionary and item.get("id") == scene_id:
			record = item
	if record.is_empty():
		record = {"id": scene_id, "title": scene.title, "evidence_label": scene.evidence_tag, "observations": []}
		next.knowledge.append(record)
	var observation_id := String(target.target_id)
	if not record.observations.any(func(item): return item.id == observation_id):
		var label := String(target.get("focus_label", "Observation recorded"))
		if label.to_lower().contains("noor") and not next.knowledge_flags.has("noor_identity_revealed"):
			label = "Gardener identity evidence recorded."
		record.observations.append({"id": observation_id, "text": label})
	# Revelation belongs to the final physical evidence step, never a caption.
	if target == targets.back():
		for flag in scene.get("knowledge_reveals", []):
			_grant_flag(next, String(flag), events)
	if observation_id == "p16_confirm_path_records":
		_grant_flag(next, "relay_local_verified", events)
		_grant_flag(next, "relay_earth_verified", events)
	return events

static func _grant_flag(next: Dictionary, flag: String, events: Array) -> void:
	if not next.knowledge_flags.has(flag):
		next.knowledge_flags.append(flag)
		events.append({"type": "knowledge_unlocked", "knowledge_flag": flag})

static func line_allowed(line_id: String, flags: Array, scene_id: String) -> bool:
	var line := Content.dialogue_by_id(content(), line_id)
	if line.is_empty() or line.scene_id != scene_id:
		return false
	for required in line.get("knowledge_required", []):
		if not flags.has(required):
			return false
	return true

static func journal(snapshot: Dictionary) -> Array:
	var entries: Array = []
	var references: Array = []
	for item in snapshot.get("knowledge", []):
		if item is Dictionary and snapshot.get("acquired_evidence_ids", []).has(item.get("id")):
			entries.push_front(item.duplicate(true))
		elif item is String:
			var label: String = {"aurora_commissioning": "Aurora commissioning", "p02_contract_loaded": "Seven-shift training rules"}.get(item, "")
			if not label.is_empty():
				references.append({"title": label, "evidence_label": "Training reference", "observations": []})
	entries.append_array(references)
	return entries
