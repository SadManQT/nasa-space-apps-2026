## Godot --headless --path game --script res://tools/test_save_service_recovery.gd
extends SceneTree

const SaveScript = preload("res://scripts/save/save_service.gd")
const StateScript = preload("res://scripts/core/campaign_state.gd")

var checks := 0
var failures := 0
var service := SaveScript.new()
var path := ""

func _init() -> void:
	path = OS.get_temp_dir().path_join("lla-save-recovery-%d-%d.json" % [OS.get_process_id(), Time.get_ticks_usec()])
	_test_missing_primary()
	_test_invalid_snapshots()
	_test_failed_writes()
	_test_migration()
	service.clear(path)
	print("SAVE RECOVERY RESULT: %d/%d checks, %d failures" % [checks - failures, checks, failures])
	quit(0 if failures == 0 else 1)

func _seed() -> void:
	service.clear(path)
	var snapshot := StateScript.new_snapshot()
	_check(bool(service.save(snapshot, path).get("accepted", false)), "seed first verified checkpoint")
	snapshot["state_revision"] = 7
	_check(bool(service.save(snapshot, path).get("accepted", false)), "seed primary and previous checkpoint backup")

func _test_missing_primary() -> void:
	_seed()
	DirAccess.remove_absolute(path)
	var recovered := service.load(path)
	_check(bool(recovered.get("accepted", false)) and bool(recovered.get("recovered", false)) and recovered.get("snapshot", {}).get("state_revision", -1) == 0, "missing primary recovers the verified backup")
	_check(FileAccess.file_exists(path) and FileAccess.file_exists(path + ".bak"), "missing primary recovery repairs the slot and retains its backup")
	service.clear(path)
	_check(not bool(service.load(path).get("accepted", false)) and service.load(path).get("reason", "") == "save_missing", "empty slot remains missing")

func _test_invalid_snapshots() -> void:
	_seed()
	var primary_text := FileAccess.get_file_as_string(path)
	var backup_text := FileAccess.get_file_as_string(path + ".bak")
	var cases := {}
	var missing_revision := StateScript.new_snapshot()
	missing_revision.erase("state_revision")
	cases["missing revision"] = missing_revision
	for pair in [["schema_version", 99], ["schema_version", 2.5], ["state_revision", -1], ["current_shift", "one"], ["receipts", []], ["acknowledged_line_ids", {}], ["accessibility", {"captions": "true"}], ["save_format", "another-game"]]:
		var invalid := StateScript.new_snapshot()
		invalid[pair[0]] = pair[1]
		cases["%s=%s" % [pair[0], pair[1]]] = invalid
	for value in [{"wrong": 1}, "14", INF]:
		var invalid := StateScript.new_snapshot()
		invalid["resources"]["E"] = value
		cases["invalid resource " + str(value)] = invalid
	var object_value := StateScript.new_snapshot()
	object_value["presentation_resume"] = {"nested": RefCounted.new()}
	cases["nested Object"] = object_value
	for label in cases:
		_check(not bool(service.save(cases[label], path).get("accepted", false)), "reject " + label)
	_check(FileAccess.get_file_as_string(path) == primary_text and FileAccess.get_file_as_string(path + ".bak") == backup_text, "invalid writes preserve both verified files")
	var invalid_primary := StateScript.new_snapshot()
	invalid_primary["resources"]["E"] = "broken"
	_write_text(path, JSON.stringify(invalid_primary))
	var recovered := service.load(path)
	_check(bool(recovered.get("recovered", false)) and recovered.get("snapshot", {}).get("state_revision", -1) == 0, "malformed resource values recover the backup instead of entering runtime")
	service.clear(path)
	_check(not bool(service.recover_corrupt(path, {"invalid": true}).get("accepted", false)), "invalid fallback snapshots are rejected")

func _test_failed_writes() -> void:
	_seed()
	var primary_text := FileAccess.get_file_as_string(path)
	var backup_text := FileAccess.get_file_as_string(path + ".bak")
	DirAccess.make_dir_absolute(path + ".bak.tmp")
	var changed := StateScript.new_snapshot()
	changed["state_revision"] = 8
	var failed := service.save(changed, path)
	_check(not bool(failed.get("accepted", false)), "backup staging failure rejects the write")
	_check(FileAccess.get_file_as_string(path) == primary_text and FileAccess.get_file_as_string(path + ".bak") == backup_text, "backup staging failure preserves primary and previous backup")
	DirAccess.remove_absolute(path + ".bak.tmp")
	_write_text(path, "{corrupt")
	DirAccess.make_dir_absolute(path + ".tmp")
	var recovered := service.load(path)
	_check(bool(recovered.get("accepted", false)) and bool(recovered.get("recovered", false)), "readable backup remains usable when primary repair fails")
	_check(not bool(recovered.get("repair_accepted", true)), "recovery reports a failed primary repair")
	_check(FileAccess.get_file_as_string(path + ".bak") == backup_text, "failed primary repair preserves the recovery source")
	DirAccess.remove_absolute(path + ".tmp")
	DirAccess.remove_absolute(path)
	DirAccess.make_dir_absolute(path)
	var install_failed := service.save(changed, path)
	_check(not bool(install_failed.get("accepted", false)), "failed primary installation rejects the save")
	_check(FileAccess.get_file_as_string(path + ".bak") == backup_text and not FileAccess.file_exists(path + ".tmp"), "failed primary installation preserves its backup and removes staging data")
	DirAccess.remove_absolute(path)

func _test_migration() -> void:
	var old := {"schema_version": 1, "save_id": "legacy", "resources": {"energy": 14, "air": 6, "alo_health": 6, "water_shielding": 0, "crate_shielding": 0, "crop_condition": 8, "rations": 12.0, "exposure": 0}}
	var migrated := service.migrate(old)
	_check(bool(migrated.get("accepted", false)) and StateScript.is_compatible(migrated.get("snapshot", {})), "schema one migration supplies a restorable current state")
	old["knowledge"] = "bad collection"
	_check(not bool(service.save(old, path).get("accepted", false)), "schema one write rejects malformed collections before migration")

func _write_text(target: String, value: String) -> void:
	var file := FileAccess.open(target, FileAccess.WRITE)
	assert(file != null)
	file.store_string(value)
	file.close()

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		print("  FAIL ", message)
