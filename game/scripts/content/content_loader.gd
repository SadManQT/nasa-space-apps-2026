extends RefCounted
class_name CampaignContentFull

## Validated full-campaign content boundary.

const FULL_PATH := "res://resources/campaign/content/campaign_catalog.json"
const DIALOGUE_PATH := "res://resources/campaign/dialogue_catalog.json"
const EXPECTED_STORY_SHA256 := "2db1f13eda8264db5b16d1dc51138a5397555bda33aa10953260173d2306729f"
const EXPECTED_SCENE_INDEX_SHA256 := "8c0b8cda424d6bc6abb32ef64fd090c9afca53a0eedf16dee74e84dc4d51a934"
const EXPECTED_VO_SHA256 := "aa2bbc83148781d48802796101cc194bea528a78dd15199a1214d4045598b5f7"
const EXPECTED_CONTENT_REVISION := "campaign-content-1-dc4e79f2208c7126"
const EXPECTED_FULL_COUNTS := {"chapters": 8, "missions": 32, "scenes": 96, "dialogue_lines": 388}
const EXPECTED_CATALOG_HASH := "50d470e1a2a4c872509b6a7976e97bf705c52559f3290664509cfe34cacf0b9a"
const EXPECTED_DIALOGUE_CATALOG_HASH := "1d5bb4f1a73f4870db5983fdaa9ddab764f5c22b92c9c13c94bfab40fe44e8b6"

static var _full_cache: Dictionary = {}

static func load_full(path: String = FULL_PATH) -> Dictionary:
	if path == FULL_PATH and not _full_cache.is_empty():
		return _full_cache.duplicate(true)
	var parsed := _read_json(path)
	if parsed.is_empty():
		return {}
	# Keep a defensive compatibility merge for an older generated catalog that
	# stores the dialogue lines only in dialogue_catalog.json.
	if not parsed.has("dialogue") and FileAccess.file_exists(DIALOGUE_PATH):
		var dialogue_catalog := _read_json(DIALOGUE_PATH)
		if not dialogue_catalog.is_empty():
			parsed["dialogue"] = dialogue_catalog.get("lines", []).duplicate(true)
	if path == FULL_PATH:
		_full_cache = parsed.duplicate(true)
	return parsed

static func validate_full(content, dialogue_catalog = null) -> Dictionary:
	var errors: Array[String] = []
	if not content is Dictionary or (content as Dictionary).is_empty():
		errors.append("full campaign catalog is empty")
		return {"valid": false, "errors": errors, "counts": {}}
	content = content as Dictionary
	# Fail closed before typed field access. The frozen hash also protects fields
	# that the structural checks below do not individually inspect.
	if content.get("catalog_hash") != EXPECTED_CATALOG_HASH or _catalog_hash(content) != EXPECTED_CATALOG_HASH:
		errors.append("catalog_hash does not match the frozen campaign catalog")
		return {"valid": false, "errors": errors, "counts": {}}
	if String(content.get("catalog_kind", "")) != "campaign":
		errors.append("catalog_kind must be campaign")
	if int(content.get("schema_version", -1)) != 1:
		errors.append("schema_version must be 1")
	if String(content.get("content_revision", "")) != EXPECTED_CONTENT_REVISION:
		errors.append("content_revision does not match the generated source revision")
	var catalog_hash := String(content.get("catalog_hash", ""))
	if catalog_hash.is_empty():
		errors.append("catalog_hash is missing")
	elif catalog_hash != EXPECTED_CATALOG_HASH or _catalog_hash(content) != catalog_hash:
		errors.append("catalog_hash does not match the frozen catalog")
	var source_hashes_value = content.get("source_hashes", null)
	var source_hashes: Dictionary = {}
	if not source_hashes_value is Dictionary:
		errors.append("source_hashes must be an object")
	else:
		source_hashes = source_hashes_value as Dictionary
		if String(source_hashes.get("story_data_sha256", "")) != EXPECTED_STORY_SHA256:
			errors.append("story-data source hash does not match")
		if String(source_hashes.get("scene_index_sha256", "")) != EXPECTED_SCENE_INDEX_SHA256:
			errors.append("scene-index source hash does not match")
		if String(source_hashes.get("vo_lines_sha256", "")) != EXPECTED_VO_SHA256:
			errors.append("VO source hash does not match")

	var chapters: Array = _array_field(content, "chapters", errors, "chapters")
	var missions: Array = _array_field(content, "missions", errors, "missions")
	var scenes: Array = _array_field(content, "scenes", errors, "scenes")
	var dialogue: Array = _array_field(content, "dialogue", errors, "dialogue")
	var counts: Dictionary = {
		"chapters": chapters.size(),
		"missions": missions.size(),
		"scenes": scenes.size(),
		"dialogue_lines": dialogue.size(),
	}
	for key in EXPECTED_FULL_COUNTS.keys():
		if int(counts.get(key, -1)) != int(EXPECTED_FULL_COUNTS[key]):
			errors.append("expected %s=%s, got %s" % [key, EXPECTED_FULL_COUNTS[key], counts.get(key, -1)])

	var expected_chapter := 1
	var expected_scene_order := 0
	var chapter_ids: Array[String] = []
	var mission_ids: Array[String] = []
	var scene_ids: Array[String] = []
	var dialogue_ids: Array[String] = []
	for chapter in chapters:
		if not chapter is Dictionary:
			errors.append("chapter entry is not an object")
			continue
		var chapter_id := String(chapter.get("id", ""))
		var expected_id := "CH%02d" % expected_chapter
		if chapter_id != expected_id:
			errors.append("chapter order contains %s; expected %s" % [chapter_id, expected_id])
		expected_chapter += 1
		chapter_ids.append(chapter_id)
		var chapter_missions = chapter.get("mission_ids", null)
		var chapter_scenes = chapter.get("scene_ids", null)
		if not chapter_missions is Array or not chapter_scenes is Array:
			errors.append("%s mission_ids and scene_ids must be arrays" % chapter_id)
			continue
		if (chapter_missions as Array).size() != 4 or (chapter_scenes as Array).size() != 12:
			errors.append("%s must declare four missions and twelve scenes" % chapter_id)
	for mission in missions:
		if not mission is Dictionary:
			errors.append("mission entry is not an object")
			continue
		var mission_id := String(mission.get("id", ""))
		if mission_id in mission_ids:
			errors.append("duplicate mission id " + mission_id)
		mission_ids.append(mission_id)
		var mission_scene_value = mission.get("scene_ids", null)
		if not mission_scene_value is Array:
			errors.append("%s scene_ids must be an array" % mission_id)
			continue
		var mission_scene_ids: Array = mission_scene_value as Array
		if mission_scene_ids.size() != 3:
			errors.append("%s must declare exactly three ordered scenes" % mission_id)
		if String(mission.get("completion_predicate_id", "")).is_empty():
			errors.append("%s has no completion predicate" % mission_id)
	for scene in scenes:
		if not scene is Dictionary:
			errors.append("scene entry is not an object")
			continue
		var scene_id := String(scene.get("id", ""))
		if scene_id in scene_ids:
			errors.append("duplicate scene id " + scene_id)
		scene_ids.append(scene_id)
		var expected_scene := "EX-CH%02d-S%02d" % [int(scene.get("chapter_number", 0)), int(scene.get("order", 0))]
		if scene_id != expected_scene:
			errors.append("scene order contains %s; expected %s" % [scene_id, expected_scene])
		var predicate_value = scene.get("exit", null)
		if not predicate_value is Dictionary:
			errors.append(scene_id + " exit must be an object")
			continue
		var predicate: Dictionary = predicate_value as Dictionary
		if bool(predicate.get("requires_dialogue_acknowledgement", true)):
			errors.append(scene_id + " incorrectly makes dialogue acknowledgement a completion requirement")
		var scene_dialogue_value = scene.get("dialogue", null)
		if not scene_dialogue_value is Array:
			errors.append(scene_id + " dialogue must be an array")
			continue
		var scene_dialogue: Array = scene_dialogue_value as Array
		for line in scene_dialogue:
			if line is Dictionary:
				dialogue_ids.append(String(line.get("id", "")))
	for line in dialogue:
		if not line is Dictionary:
			errors.append("dialogue entry is not an object")
			continue
		var line_id := String(line.get("id", ""))
		if line_id.is_empty():
			errors.append("dialogue line has no stable id")
		if String(line.get("text", "")) != String(line.get("line", "")):
			errors.append(line_id + " does not preserve one exact text value")
		if bool(line.get("acknowledgement_completes_predicate", true)):
			errors.append(line_id + " incorrectly completes a predicate on acknowledgement")
	var predicates: Array = _array_field(content, "predicates", errors, "predicates")
	for predicate_entry in predicates:
		if predicate_entry is Dictionary and bool(predicate_entry.get("requires_dialogue_acknowledgement", true)):
			errors.append(String(predicate_entry.get("id", "predicate")) + " is dialogue-gated")
	if dialogue_ids.size() != 388:
		errors.append("nested scene dialogue does not total 388 lines")
	if scene_ids.size() == 96 and mission_ids.size() == 32 and dialogue.size() == 388:
		if dialogue_ids != _dialogue_ids_from_global(dialogue):
			errors.append("scene dialogue order differs from global dialogue order")

	if dialogue_catalog == null:
		dialogue_catalog = _read_json(DIALOGUE_PATH)
	var dialogue_validation := validate_dialogue_catalog(dialogue_catalog)
	for dialogue_error in dialogue_validation.get("errors", []):
		errors.append("dialogue catalog: " + String(dialogue_error))
	if dialogue_catalog is Dictionary and dialogue_catalog.get("content_revision") != content.get("content_revision"):
		errors.append("dialogue catalog revision does not match campaign revision")
	return {"valid": errors.is_empty(), "errors": errors, "counts": counts}

static func validate_dialogue_catalog(dialogue_catalog) -> Dictionary:
	var errors: Array[String] = []
	if not dialogue_catalog is Dictionary or (dialogue_catalog as Dictionary).is_empty():
		errors.append("dialogue catalog is empty or not an object")
		return {"valid": false, "errors": errors, "counts": {}}
	dialogue_catalog = dialogue_catalog as Dictionary
	if dialogue_catalog.get("catalog_hash") != EXPECTED_DIALOGUE_CATALOG_HASH or _catalog_hash(dialogue_catalog) != EXPECTED_DIALOGUE_CATALOG_HASH:
		errors.append("catalog_hash does not match the frozen dialogue catalog")
		return {"valid": false, "errors": errors, "counts": {}}
	if String(dialogue_catalog.get("catalog_kind", "")) != "dialogue":
		errors.append("catalog_kind must be dialogue")
	if int(dialogue_catalog.get("schema_version", -1)) != 1:
		errors.append("schema_version must be 1")
	if String(dialogue_catalog.get("content_revision", "")) != EXPECTED_CONTENT_REVISION:
		errors.append("content_revision does not match the generated source revision")
	var catalog_hash := String(dialogue_catalog.get("catalog_hash", ""))
	if catalog_hash != EXPECTED_DIALOGUE_CATALOG_HASH or _catalog_hash(dialogue_catalog) != catalog_hash:
		errors.append("catalog_hash does not match the frozen dialogue catalog")
	var source_hashes_value = dialogue_catalog.get("source_hashes", null)
	if not source_hashes_value is Dictionary:
		errors.append("source_hashes must be an object")
	else:
		var source_hashes: Dictionary = source_hashes_value as Dictionary
		if String(source_hashes.get("story_data_sha256", "")) != EXPECTED_STORY_SHA256:
			errors.append("story-data source hash does not match")
		if String(source_hashes.get("scene_index_sha256", "")) != EXPECTED_SCENE_INDEX_SHA256:
			errors.append("scene-index source hash does not match")
		if String(source_hashes.get("vo_lines_sha256", "")) != EXPECTED_VO_SHA256:
			errors.append("VO source hash does not match")
	var lines: Array = _array_field(dialogue_catalog, "lines", errors, "dialogue lines")
	if lines.size() != 388:
		errors.append("expected dialogue_lines=388, got %s" % lines.size())
	var line_ids: Array[String] = []
	for raw_line in lines:
		if not raw_line is Dictionary:
			errors.append("dialogue entry is not an object")
			continue
		var line: Dictionary = raw_line as Dictionary
		var line_id := String(line.get("id", ""))
		if line_id.is_empty():
			errors.append("dialogue line has no stable id")
		elif line_id in line_ids:
			errors.append("duplicate dialogue id " + line_id)
		line_ids.append(line_id)
		if String(line.get("text", "")) != String(line.get("line", "")):
			errors.append(line_id + " does not preserve one exact text value")
		if bool(line.get("acknowledgement_completes_predicate", true)):
			errors.append(line_id + " incorrectly completes a predicate on acknowledgement")
	return {"valid": errors.is_empty(), "errors": errors, "counts": {"dialogue_lines": lines.size()}}

static func scene_by_id(content: Dictionary, scene_id: String) -> Dictionary:
	for scene in content.get("scenes", []):
		if scene is Dictionary and String(scene.get("id", "")) == scene_id:
			return scene.duplicate(true)
	return {}

static func mission_by_id(content: Dictionary, mission_id: String) -> Dictionary:
	for mission in content.get("missions", []):
		if mission is Dictionary and String(mission.get("id", "")) == mission_id:
			return mission.duplicate(true)
	return {}

static func dialogue_by_id(content: Dictionary, line_id: String) -> Dictionary:
	for line in content.get("dialogue", []):
		if line is Dictionary and String(line.get("id", "")) == line_id:
			return line.duplicate(true)
	return {}

static func clear_cache() -> void:
	_full_cache.clear()

static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Campaign content is missing: " + path)
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("Campaign content is not a JSON object: " + path)
		return {}
	return parsed as Dictionary

static func _dialogue_ids_from_global(dialogue: Array) -> Array[String]:
	var ids: Array[String] = []
	for line in dialogue:
		if line is Dictionary:
			ids.append(String(line.get("id", "")))
	return ids

static func _array_field(value: Dictionary, key: String, errors: Array[String], label: String) -> Array:
	var field = value.get(key)
	if field is Array:
		return field
	errors.append(label + " must be an array")
	return []

static func _catalog_hash(catalog: Dictionary) -> String:
	var payload := catalog.duplicate(true)
	payload.erase("catalog_hash")
	# Matches build_catalog.py: UTF-8, sorted keys, no whitespace. Godot's JSON
	# encoder normalizes parsed integer-valued numbers to the source integers.
	return JSON.stringify(_canonical_json_value(payload)).sha256_text()

static func _canonical_json_value(value):
	if value is Dictionary:
		var keys: Array = value.keys()
		keys.sort_custom(func(left, right): return String(left) < String(right))
		var ordered := {}
		for key in keys:
			ordered[String(key)] = _canonical_json_value(value[key])
		return ordered
	if value is Array:
		var ordered_array: Array = []
		for item in value:
			ordered_array.append(_canonical_json_value(item))
		return ordered_array
	if typeof(value) == TYPE_FLOAT and is_equal_approx(float(value), round(float(value))):
		return int(value)
	return value
