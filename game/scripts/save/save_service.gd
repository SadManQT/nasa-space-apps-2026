extends RefCounted
class_name SaveService

## Versioned primitive save service with a validated temporary file and a
## one-generation backup. Scene-tree objects, callbacks and secrets are never
## accepted as part of the save contract.

const SCHEMA_VERSION := 3
const FORMAT_ID := "last-light-academy-save"
# Keep the installed slot's filename so existing expeditions are discovered.
const DEFAULT_PATH := "user://last_light_expedition_v2.json"
const StateScript = preload("res://scripts/core/campaign_state.gd")

## Optional check that a structurally valid save can actually resume
## (Chapter1Campaign.restore_session). It returns {"accepted": bool, "reason"}.
## When set, a save that fails it is treated like a corrupt file: load falls
## back to the backup, and save never preserves it as the backup.
var session_validator := Callable()

func save(snapshot: Dictionary, path: String = DEFAULT_PATH) -> Dictionary:
	var migration := migrate(snapshot)
	if not bool(migration.get("accepted", false)):
		return {"accepted": false, "migrated": false, "recovered": false, "path": path, "reason": String(migration.get("reason", "Invalid save snapshot."))}
	var candidate: Dictionary = migration["snapshot"]
	var session := _validate_session(candidate)
	if not bool(session.get("accepted", false)):
		return session
	var encoded := JSON.stringify(candidate)
	var temp_path := path + ".tmp"
	if not _write_validated_snapshot(temp_path, encoded):
		_remove_temporary(temp_path)
		return {"accepted": false, "migrated": false, "recovered": false, "path": path, "reason": "Unable to write and verify the temporary save."}
	var absolute_path := ProjectSettings.globalize_path(path)
	var absolute_temp_path := ProjectSettings.globalize_path(temp_path)
	var backup_path := path + ".bak"
	if FileAccess.file_exists(path):
		# A recovery write may be replacing a corrupt primary. Never destroy an
		# already-valid backup in that case: it is the only repeatable recovery
		# source if the newly restored primary is corrupted again.
		var old_primary_valid := bool(_load_candidate(path).get("accepted", false))
		if old_primary_valid:
			var old_text := FileAccess.get_file_as_string(path)
			var backup_temp_path := backup_path + ".tmp"
			if not _write_validated_snapshot(backup_temp_path, old_text) or DirAccess.rename_absolute(ProjectSettings.globalize_path(backup_temp_path), ProjectSettings.globalize_path(backup_path)) != OK:
				_remove_temporary(temp_path)
				_remove_temporary(backup_temp_path)
				return {"accepted": false, "migrated": false, "recovered": false, "path": path, "reason": "Unable to preserve the previous verified checkpoint."}
	# Rename replaces the file atomically. Keep the old primary on failure;
	# deleting or opening it for a direct write creates an unrecoverable gap.
	if DirAccess.rename_absolute(absolute_temp_path, absolute_path) != OK:
		_remove_temporary(temp_path)
		return {"accepted": false, "migrated": false, "recovered": false, "path": path, "reason": "Unable to install the validated save; the previous checkpoint was retained."}
	return {
		"accepted": true,
		"migrated": bool(migration.get("migrated", false)),
		"recovered": false,
		"path": path,
		"backup_path": backup_path,
		"schema_version": SCHEMA_VERSION,
		"save_id": String(candidate.get("save_id", "")),
		"snapshot": candidate.duplicate(true),
	}

func load(path: String = DEFAULT_PATH, fallback_snapshot: Dictionary = {}) -> Dictionary:
	var primary_exists := FileAccess.file_exists(path)
	var primary := _load_candidate(path)
	if bool(primary.get("accepted", false)):
		return {
			"accepted": true,
			"migrated": bool(primary.get("migrated", false)),
			"recovered": false,
			"path": path,
			"schema_version": SCHEMA_VERSION,
			"snapshot": primary["snapshot"].duplicate(true),
		}
	var backup := _load_candidate(path + ".bak")
	if bool(backup.get("accepted", false)):
		# Restore through the same validated save path. This produces a fresh
		# primary and retains the recovered data for the next failure.
		var repaired := save(backup["snapshot"], path)
		return {
			"accepted": true,
			"migrated": bool(backup.get("migrated", false)),
			"recovered": true,
			"repair_accepted": bool(repaired.get("accepted", false)),
			"repair_reason": String(repaired.get("reason", "")),
			"path": path,
			"reason": "primary_corrupt_recovered_from_backup",
			"primary_reason": String(primary.get("reason", "")),
			"snapshot": backup["snapshot"].duplicate(true),
		}
	return {"accepted": false, "migrated": false, "recovered": false, "path": path, "reason": "save_corrupt_no_valid_backup" if primary_exists else "save_missing", "primary_reason": String(primary.get("reason", "")), "snapshot": fallback_snapshot.duplicate(true)}

## Reads, migrates and (when a validator is set) resume-checks one file.
func _load_candidate(path: String) -> Dictionary:
	var read := _read_snapshot(path)
	if not bool(read.get("valid", false)):
		return {"accepted": false, "reason": String(read.get("reason", "invalid"))}
	var migration := migrate(read["snapshot"])
	if not bool(migration.get("accepted", false)):
		return migration
	var session := _validate_session(migration["snapshot"])
	if not bool(session.get("accepted", false)):
		return session
	return migration

func _validate_session(snapshot: Dictionary) -> Dictionary:
	if session_validator.is_valid():
		var session = session_validator.call(snapshot)
		if not session is Dictionary or not bool(session.get("accepted", false)):
			return {"accepted": false, "reason": "checkpoint cannot resume: " + (String(session.get("reason", "unknown")) if session is Dictionary else "unknown")}
	return {"accepted": true}

## Copies and validates v1/v2 saves into schema 3 without changing the source.
func migrate(snapshot: Dictionary) -> Dictionary:
	var validation := _validate_snapshot(snapshot)
	if not bool(validation.get("valid", false)):
		return {"accepted": false, "migrated": false, "reason": String(validation.get("reason", "Invalid save snapshot."))}
	var from_version := int(snapshot.get("schema_version", 0))
	if from_version == SCHEMA_VERSION:
		var current := snapshot.duplicate(true)
		current["save_format"] = FORMAT_ID
		return {"accepted": true, "migrated": false, "from_schema": from_version, "to_schema": SCHEMA_VERSION, "snapshot": current}
	if from_version == 1:
		return _migrate_v1(snapshot)
	if from_version == 2:
		return _migrate_v2(snapshot)
	return {"accepted": false, "migrated": false, "from_schema": from_version, "to_schema": SCHEMA_VERSION, "reason": "Unsupported save schema version."}

func recover_corrupt(path: String = DEFAULT_PATH, fallback_snapshot: Dictionary = {}) -> Dictionary:
	var loaded: Dictionary = self.load(path, fallback_snapshot)
	if bool(loaded.get("recovered", false)):
		return loaded
	if bool(loaded.get("accepted", false)):
		loaded["recovered"] = false
		return loaded
	var fallback := migrate(fallback_snapshot)
	var valid_fallback := bool(fallback.get("accepted", false)) and bool(_validate_session(fallback.get("snapshot", {})).get("accepted", false))
	return {
		"accepted": valid_fallback,
		"migrated": bool(fallback.get("migrated", false)),
		"recovered": valid_fallback,
		"path": path,
		"reason": "fallback_snapshot_used" if valid_fallback else String(loaded.get("reason", "save_unavailable")),
		"snapshot": fallback.get("snapshot", {}).duplicate(true),
	}

func has_valid_save(path: String = DEFAULT_PATH) -> bool:
	return bool(self.load(path).get("accepted", false))

func clear(path: String = DEFAULT_PATH) -> bool:
	var ok := true
	for candidate in [path, path + ".tmp", path + ".bak", path + ".bak.tmp"]:
		if FileAccess.file_exists(candidate):
			ok = DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate)) == OK and ok
	return ok

func _migrate_v1(source: Dictionary) -> Dictionary:
	var result := source.duplicate(true)
	result["schema_version"] = 2
	result["save_format"] = FORMAT_ID
	if not result.has("mission_receipts"):
		result["mission_receipts"] = result.get("receipts", {}).duplicate(true)
	if not result.has("knowledge_flags"):
		result["knowledge_flags"] = result.get("knowledge", []).duplicate(true)
	if not result.has("accessibility"):
		result["accessibility"] = result.get("settings", {}).duplicate(true)
	var defaults := StateScript.new_snapshot()
	for key in defaults:
		if key == "story_log":
			continue
		if not result.has(key):
			result[key] = defaults[key].duplicate(true) if defaults[key] is Array or defaults[key] is Dictionary else defaults[key]
	for key in defaults["accessibility"]:
		if not result["accessibility"].has(key):
			result["accessibility"][key] = defaults["accessibility"][key]
	var resources: Dictionary = result.get("resources", {}).duplicate(true)
	var aliases := {"energy": "E", "air": "A", "alo_health": "H", "water_shielding": "W", "crate_shielding": "K", "crop_condition": "C", "rations": "R", "exposure": "Z"}
	for old_key in aliases.keys():
		if resources.has(old_key) and not resources.has(aliases[old_key]):
			resources[aliases[old_key]] = resources[old_key]
	for pair in [["energy_capacity", 20], ["air_capacity", 10], ["health_capacity", 10], ["water_capacity", 6], ["crate_capacity", 2], ["crop_capacity", 10]]:
		if not resources.has(pair[0]):
			resources[pair[0]] = pair[1]
	result["resources"] = resources
	var validation := _validate_snapshot(result)
	if not bool(validation.get("valid", false)):
		return {"accepted": false, "migrated": true, "from_schema": 1, "to_schema": SCHEMA_VERSION, "reason": String(validation.get("reason", "Migrated snapshot is invalid."))}
	var migrated := _migrate_v2(result)
	migrated["from_schema"] = 1
	return migrated

func _migrate_v2(source: Dictionary) -> Dictionary:
	var result := source.duplicate(true)
	result["schema_version"] = SCHEMA_VERSION
	result["save_format"] = FORMAT_ID
	result["story_log"] = {"choices": {}, "moments": []}
	# A production save also owns the pre-operation director checkpoint. Upgrade
	# that state through the same boundary or Continue/retry rejects old saves.
	var runtime = result.get("route_runtime", {})
	if runtime is Dictionary:
		var checkpoint = runtime.get("retry_checkpoint", {})
		if checkpoint is Dictionary and checkpoint.get("director") is Dictionary:
			var nested := migrate(checkpoint.director)
			if not bool(nested.get("accepted", false)):
				return {"accepted": false, "migrated": true, "from_schema": 2, "to_schema": SCHEMA_VERSION, "reason": "Invalid migrated retry checkpoint: " + String(nested.get("reason", "unknown"))}
			checkpoint["director"] = nested.snapshot
	var validation := _validate_snapshot(result)
	if not bool(validation.get("valid", false)):
		return {"accepted": false, "migrated": true, "from_schema": 2, "to_schema": SCHEMA_VERSION, "reason": String(validation.get("reason", "Migrated snapshot is invalid."))}
	return {"accepted": true, "migrated": true, "from_schema": 2, "to_schema": SCHEMA_VERSION, "snapshot": result}

func _read_snapshot(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"valid": false, "reason": "missing"}
	var parser := JSON.new()
	var parse_error := parser.parse(FileAccess.get_file_as_string(path))
	if parse_error != OK or not parser.data is Dictionary:
		return {"valid": false, "reason": "json"}
	var parsed: Dictionary = parser.data
	var validation := _validate_snapshot(parsed)
	return {"valid": bool(validation.get("valid", false)), "snapshot": parsed, "reason": validation.get("reason", "")}

func _validate_snapshot(snapshot: Dictionary) -> Dictionary:
	if not _is_primitive(snapshot):
		return {"valid": false, "reason": "save data must contain only finite JSON primitives"}
	var version = snapshot.get("schema_version", 0)
	if not (version is int or version is float) or float(version) != floor(float(version)) or int(version) not in [1, 2, SCHEMA_VERSION]:
		return {"valid": false, "reason": "Unsupported save schema version."}
	if not snapshot.get("save_id", null) is String or String(snapshot["save_id"]).is_empty():
		return {"valid": false, "reason": "save requires a nonempty save_id"}
	if snapshot.has("save_format") and snapshot["save_format"] != FORMAT_ID:
		return {"valid": false, "reason": "save format does not match Last Light Academy"}
	if not snapshot.has("resources") or not snapshot["resources"] is Dictionary:
		return {"valid": false, "reason": "save resources must be a Dictionary"}
	if snapshot.has("_node") or snapshot.has("node"):
		return {"valid": false, "reason": "scene-tree references are not serializable save data"}
	for key in ["E", "A", "H", "W", "K", "C", "R", "Z"]:
		var resource_key: String = key if snapshot["resources"].has(key) else {"E": "energy", "A": "air", "H": "alo_health", "W": "water_shielding", "K": "crate_shielding", "C": "crop_condition", "R": "rations", "Z": "exposure"}[key]
		if not snapshot["resources"].has(resource_key):
			return {"valid": false, "reason": "save resources are missing " + key}
		var value = snapshot["resources"][resource_key]
		if not (value is int or value is float) or float(value) < 0.0:
			return {"valid": false, "reason": "save resource " + key + " must be a nonnegative number"}
	if int(version) == SCHEMA_VERSION:
		return StateScript.validate_snapshot(snapshot)
	if int(version) == 2:
		var current := snapshot.duplicate(true)
		current["schema_version"] = SCHEMA_VERSION
		current["story_log"] = {"choices": {}, "moments": []}
		return StateScript.validate_snapshot(current)
	for key in ["receipts", "settings", "accessibility"]:
		if snapshot.has(key) and not snapshot[key] is Dictionary:
			return {"valid": false, "reason": "legacy save " + key + " must be a Dictionary"}
	if snapshot.has("knowledge") and not snapshot["knowledge"] is Array:
		return {"valid": false, "reason": "legacy save knowledge must be an Array"}
	return {"valid": true}

func _is_primitive(value: Variant, depth: int = 0) -> bool:
	# Bound recursion so cyclic or excessively nested inputs cannot hang a save.
	if depth > 64:
		return false
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_STRING:
			return true
		TYPE_FLOAT:
			return is_finite(value)
		TYPE_ARRAY:
			for item in value:
				if not _is_primitive(item, depth + 1):
					return false
		TYPE_DICTIONARY:
			for key in value:
				if not key is String or not _is_primitive(value[key], depth + 1):
					return false
		_:
			return false
	return true

func _write_validated_snapshot(path: String, encoded: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(encoded)
	file.flush()
	var error := file.get_error()
	file.close()
	return error == OK and FileAccess.get_file_as_string(path) == encoded and bool(_read_snapshot(path).get("valid", false))

func _remove_temporary(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
