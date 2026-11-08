extends RefCounted

## Shared read-only registry for science cards, Journal and the existing player.
const REGISTRY := "res://resources/campaign/content/explainers.json"
static var _entries: Array = []

static func _registry() -> Array:
	if _entries.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(REGISTRY))
		if parsed is Dictionary and parsed.get("explainers") is Array:
			_entries = parsed.explainers
	return _entries

static func find(id: String) -> Dictionary:
	for entry in _registry():
		if entry is Dictionary and entry.get("id") == id:
			return entry.duplicate(true)
	return {}

## Data cards pass their explicit mission and sources; Journal passes reached
## missions and their puzzle references, without source-based future unlocks.
static func matching(used_by: Array = [], source_ids: Array = []) -> Array:
	var result: Array = []
	var seen := {}
	for entry in _registry():
		if not entry is Dictionary or entry.get("kind") != "science" or seen.has(entry.get("id", "")):
			continue
		if used_by.any(func(id): return not str(id).is_empty() and entry.get("used_by", []).has(id)) or source_ids.any(func(id): return entry.get("sources", []).has(id)):
			result.append(entry.duplicate(true))
			seen[entry.id] = true
	return result
