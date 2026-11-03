extends RefCounted
class_name SaveService

## Versioned primitive save service with a validated temporary file and a
## one-generation backup. Scene-tree objects, callbacks and secrets are never
## accepted as part of the save contract.

const SCHEMA_VERSION := 2
const FORMAT_ID := "last-light-academy-save"
const DEFAULT_PATH := "user://last_light_expedition_v2.json"

func save(snapshot: Dictionary, path: String = DEFAULT_PATH) -> Dictionary:
	var candidate := snapshot.duplicate(true)
	candidate["schema_version"] = SCHEMA_VERSION
	candidate["save_format"] = FORMAT_ID
	var validation := _validate_snapshot(candidate)
	if not bool(validation.get("valid", false)):
		return {"accepted": false, "migrated": false, "recovered": false, "path": path, "reason": String(validation.get("reason", "Invalid save snapshot."))}
	var encoded := JSON.stringify(candidate)
	var temp_path := path + ".tmp"
	var temp := FileAccess.open(temp_path, FileAccess.WRITE)
	if temp == null:
		return {"accepted": false, "migrated": false, "recovered": false, "path": path, "reason": "Unable to open the atomic temporary save."}
	temp.store_string(encoded)
	temp.flush()
	temp.close()
	var check = JSON.parse_string(FileAccess.get_file_as_string(temp_path))
	if not check is Dictionary:
		return {"accepted": false, "migrated": false, "recovered": false, "path": path, "reason": "Temporary save validation failed."}
	var absolute_path := ProjectSettings.globalize_path(path)
	var absolute_temp_path := ProjectSettings.globalize_path(temp_path)
	var backup_path := path + ".bak"
	var absolute_backup_path := ProjectSettings.globalize_path(backup_path)
	if FileAccess.file_exists(path):
		# A recovery write may be replacing a corrupt primary. Never destroy an
		# already-valid backup in that case: it is the only repeatable recovery
		# source if the newly restored primary is corrupted again.
		var old_primary_valid := bool(_read_snapshot(path).get("valid", false))
		if old_primary_valid:
			var old_text := FileAccess.get_file_as_string(path)
			var backup := FileAccess.open(backup_path, FileAccess.WRITE)
			if backup != null:
				backup.store_string(old_text)
				backup.flush()
				backup.close()
		var remove_error := DirAccess.remove_absolute(absolute_path)
		if remove_error != OK:
			return {"accepted": false, "migrated": false, "recovered": false, "path": path, "reason": "Unable to replace the previous save atomically."}
	if DirAccess.rename_absolute(absolute_temp_path, absolute_path) != OK:
		# A direct write is only used after the temporary JSON has been parsed and
		# the old file has been backed up. It keeps Windows user-data providers
		# usable while preserving the validation boundary.
		var direct := FileAccess.open(path, FileAccess.WRITE)
		if direct == null:
			return {"accepted": false, "migrated": false, "recovered": false, "path": path, "reason": "Unable to install the validated save."}
		direct.store_string(encoded)
		direct.flush()
		direct.close()
		if FileAccess.file_exists(temp_path):
			DirAccess.remove_absolute(absolute_temp_path)
	return {
		"accepted": true,
		"migrated": false,
		"recovered": false,
		"path": path,
		"backup_path": backup_path,
		"schema_version": SCHEMA_VERSION,
		"save_id": String(candidate.get("save_id", "")),
		"snapshot": candidate.duplicate(true),
	}

func load(path: String = DEFAULT_PATH, fallback_snapshot: Dictionary = {}) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"accepted": false, "migrated": false, "recovered": false, "path": path, "reason": "save_missing", "snapshot": fallback_snapshot.duplicate(true)}
	var primary := _read_snapshot(path)
	if bool(primary.get("valid", false)):
		var migration := migrate(primary["snapshot"])
		if bool(migration.get("accepted", false)):
			return {
				"accepted": true,
				"migrated": bool(migration.get("migrated", false)),
				"recovered": false,
				"path": path,
				"schema_version": SCHEMA_VERSION,
				"snapshot": migration["snapshot"].duplicate(true),
			}
	var backup_path := path + ".bak"
	var backup := _read_snapshot(backup_path)
	if bool(backup.get("valid", false)):
		var migration_backup := migrate(backup["snapshot"])
		if bool(migration_backup.get("accepted", false)):
			# Restore through the same validated save path. This produces a fresh
			# primary and retains the recovered data for the next failure.
			save(migration_backup["snapshot"], path)
			return {
				"accepted": true,
				"migrated": bool(migration_backup.get("migrated", false)),
				"recovered": true,
				"path": path,
				"reason": "primary_corrupt_recovered_from_backup",
				"snapshot": migration_backup["snapshot"].duplicate(true),
			}
	return {"accepted": false, "migrated": false, "recovered": false, "path": path, "reason": "save_corrupt_no_valid_backup", "snapshot": fallback_snapshot.duplicate(true)}

func migrate(snapshot: Dictionary) -> Dictionary:
	var from_version := int(snapshot.get("schema_version", 0))
	if from_version == SCHEMA_VERSION:
		var current := snapshot.duplicate(true)
		current["save_format"] = FORMAT_ID
		var valid_current := _validate_snapshot(current)
		if not bool(valid_current.get("valid", false)):
			return {"accepted": false, "migrated": false, "from_schema": from_version, "to_schema": SCHEMA_VERSION, "reason": String(valid_current.get("reason", "Invalid current save."))}
		return {"accepted": true, "migrated": false, "from_schema": from_version, "to_schema": SCHEMA_VERSION, "snapshot": current}
	if from_version == 1:
		return _migrate_v1(snapshot)
	return {"accepted": false, "migrated": false, "from_schema": from_version, "to_schema": SCHEMA_VERSION, "reason": "Unsupported save schema version."}

func recover_corrupt(path: String = DEFAULT_PATH, fallback_snapshot: Dictionary = {}) -> Dictionary:
	var loaded: Dictionary = self.load(path, fallback_snapshot)
	if bool(loaded.get("recovered", false)):
		return loaded
	if bool(loaded.get("accepted", false)):
		loaded["recovered"] = false
		return loaded
	return {
		"accepted": not fallback_snapshot.is_empty(),
		"migrated": false,
		"recovered": not fallback_snapshot.is_empty(),
		"path": path,
		"reason": "fallback_snapshot_used" if not fallback_snapshot.is_empty() else String(loaded.get("reason", "save_unavailable")),
		"snapshot": fallback_snapshot.duplicate(true),
	}

func has_valid_save(path: String = DEFAULT_PATH) -> bool:
	return bool(self.load(path).get("accepted", false))

func clear(path: String = DEFAULT_PATH) -> bool:
	var ok := true
	for candidate in [path, path + ".tmp", path + ".bak"]:
		if FileAccess.file_exists(candidate):
			ok = DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate)) == OK and ok
	return ok

func _migrate_v1(source: Dictionary) -> Dictionary:
	var result := source.duplicate(true)
	result["schema_version"] = SCHEMA_VERSION
	result["save_format"] = FORMAT_ID
	if not result.has("state_revision"):
		result["state_revision"] = 0
	if not result.has("checkpoint_id"):
		result["checkpoint_id"] = "MIGRATED-CHECKPOINT"
	if not result.has("mission_receipts"):
		result["mission_receipts"] = result.get("receipts", {}).duplicate(true)
	if not result.has("interaction_receipts"):
		result["interaction_receipts"] = {}
	if not result.has("knowledge_flags"):
		result["knowledge_flags"] = result.get("knowledge", []).duplicate(true)
	if not result.has("acknowledged_line_ids"):
		result["acknowledged_line_ids"] = []
	if not result.has("current_shift"):
		result["current_shift"] = 0
	if not result.has("explicit_time_receipts"):
		result["explicit_time_receipts"] = {}
	if not result.has("actors"):
		result["actors"] = {}
	if not result.has("plants"):
		result["plants"] = []
	if not result.has("upgrades"):
		result["upgrades"] = {"acquisition_chapter": {}, "choices": {}, "applied_profile_revision": "p02-base-v1"}
	if not result.has("route"):
		result["route"] = {}
	if not result.has("settings_revision"):
		result["settings_revision"] = 1
	if not result.has("accessibility"):
		result["accessibility"] = result.get("settings", {}).duplicate(true)
	if not result.has("presentation_resume"):
		result["presentation_resume"] = {}
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
	return {"accepted": true, "migrated": true, "from_schema": 1, "to_schema": SCHEMA_VERSION, "snapshot": result}

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
	if not snapshot.has("schema_version") or not snapshot.has("save_id"):
		return {"valid": false, "reason": "save requires schema_version and save_id"}
	if not snapshot.has("resources") or not snapshot["resources"] is Dictionary:
		return {"valid": false, "reason": "save resources must be a Dictionary"}
	if snapshot.has("_node") or snapshot.has("node"):
		return {"valid": false, "reason": "scene-tree references are not serializable save data"}
	for key in ["E", "A", "H", "W", "K", "C", "R", "Z"]:
		if not snapshot["resources"].has(key) and not snapshot["resources"].has({"E": "energy", "A": "air", "H": "alo_health", "W": "water_shielding", "K": "crate_shielding", "C": "crop_condition", "R": "rations", "Z": "exposure"}.get(key, key)):
			return {"valid": false, "reason": "save resources are missing " + key}
	return {"valid": true}
