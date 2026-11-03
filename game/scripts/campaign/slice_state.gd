extends RefCounted
class_name SliceState

const SCHEMA_VERSION := 1
const CONTENT_REVISION := "story-data-extended-02-commissioning-slice"
const SAVE_PATH := "user://last_light_expedition.json"

static func new_snapshot() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"content_revision": CONTENT_REVISION,
		"save_id": "aurora-commissioning",
		"state_revision": 0,
		"checkpoint_id": "EX-CH01-S01-CHECKPOINT",
		"chapter_id": "CH01",
		"mission_id": "EX-M0101",
		"scene_id": "EX-CH01-S01",
		"scene_index": 0,
		"scene_phase": "briefing",
		"completed_scene_ids": [],
		"receipts": {},
		"history": [],
		"knowledge": ["aurora_commissioning"],
		"dialogue_cursor": 0,
		"commissioning_markers": {},
		"resources": {
			"energy": 14,
			"energy_capacity": 20,
			"air": 6,
			"air_capacity": 10,
			"alo_health": 6,
			"water_shielding": 0,
			"crate_shielding": 0,
			"crop_condition": 8,
			"rations": 12,
			"exposure": 0
		},
		"settings": {
			"captions": true,
			"large_text": false,
			"timer_free": true,
			"reduced_motion": false
		},
		"scenario_datetime": "2046-04-11 06:00 UTC",
		"status": "commissioning"
	}

static func is_compatible(snapshot: Dictionary) -> bool:
	return snapshot.get("schema_version", -1) == SCHEMA_VERSION and snapshot.get("content_revision", "") == CONTENT_REVISION and snapshot.get("chapter_id", "") == "CH01"

static func save_snapshot(snapshot: Dictionary, path: String = SAVE_PATH) -> bool:
	var encoded := JSON.stringify(snapshot)
	var temp_path := path + ".tmp"
	var temp := FileAccess.open(temp_path, FileAccess.WRITE)
	if temp == null:
		return false
	temp.store_string(encoded)
	temp.flush()
	temp.close()
	var absolute_path := ProjectSettings.globalize_path(path)
	var absolute_temp_path := ProjectSettings.globalize_path(temp_path)
	if FileAccess.file_exists(path):
		var remove_error := DirAccess.remove_absolute(absolute_path)
		if remove_error != OK:
			return false
	if DirAccess.rename_absolute(absolute_temp_path, absolute_path) == OK:
		return true
	# Some Windows user-data providers reject a cross-handle rename; keep a safe direct fallback.
	var direct := FileAccess.open(path, FileAccess.WRITE)
	if direct == null:
		return false
	direct.store_string(encoded)
	direct.flush()
	direct.close()
	if FileAccess.file_exists(temp_path):
		DirAccess.remove_absolute(absolute_temp_path)
	return true

static func load_snapshot(path: String = SAVE_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return {}
	var snapshot := parsed as Dictionary
	return normalise_snapshot(snapshot) if is_compatible(snapshot) else {}

static func normalise_snapshot(snapshot: Dictionary) -> Dictionary:
	## Older or hand-edited saves may omit optional fields. Fill only missing
	## values from a fresh snapshot; never overwrite the player's progress.
	if not is_compatible(snapshot):
		return {}
	var defaults := new_snapshot()
	var normalised := snapshot.duplicate(true)
	for key in defaults.keys():
		if not normalised.has(key):
			normalised[key] = defaults[key].duplicate(true) if defaults[key] is Array or defaults[key] is Dictionary else defaults[key]
	for key in ["completed_scene_ids", "history", "knowledge"]:
		if not normalised[key] is Array:
			normalised[key] = defaults[key].duplicate(true)
	for key in ["receipts", "commissioning_markers"]:
		if not normalised[key] is Dictionary:
			normalised[key] = defaults[key].duplicate(true)
	var default_resources: Dictionary = defaults.resources
	var resources: Dictionary = normalised.resources if normalised.resources is Dictionary else {}
	for key in default_resources.keys():
		if not resources.has(key):
			resources[key] = default_resources[key]
	normalised.resources = resources
	var default_settings: Dictionary = defaults.settings
	var settings: Dictionary = normalised.settings if normalised.settings is Dictionary else {}
	for key in default_settings.keys():
		if not settings.has(key):
			settings[key] = default_settings[key]
	normalised.settings = settings
	return normalised

static func has_save(path: String = SAVE_PATH) -> bool:
	return not load_snapshot(path).is_empty()

static func clear_save(path: String = SAVE_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return true
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK

static func copy_snapshot(snapshot: Dictionary) -> Dictionary:
	return snapshot.duplicate(true)
