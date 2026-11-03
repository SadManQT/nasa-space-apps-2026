# Godot --headless --path game --script res://tools/test_slice_state.gd
extends SceneTree

var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var state := SliceState.new_snapshot()
	var before := SliceState.copy_snapshot(state)
	var preview_bundle := SliceRules.preview(state, 0, "store_air")
	_check(bool(preview_bundle.result.accepted), "preview accepts a visible option")
	_check(state == before, "preview has no state side effects")
	_check(preview_bundle.result.output_revision == 0, "preview preserves revision")
	_check(preview_bundle.result.resource_changes[0].resource_id == "air", "preview exposes the simulated resource effect")
	var commit_bundle := SliceRules.commit(state, "EX-CH01-S01:store_air:0", 0, "store_air")
	_check(bool(commit_bundle.result.accepted), "commit accepts the same option")
	_check(commit_bundle.snapshot.state_revision == 1, "commit advances once")
	_check(commit_bundle.snapshot.commissioning_markers.air_routed, "commit records the domain marker")
	_check(commit_bundle.snapshot.resources.air == 8 and commit_bundle.snapshot.resources.energy == 13, "commit applies bounded resource deltas")
	_check(commit_bundle.result.resource_changes[0].after == 8, "receipt records the resulting resource value")
	var duplicate := SliceRules.commit(commit_bundle.snapshot, "EX-CH01-S01:store_air:0", 1, "store_air")
	_check(bool(duplicate.result.duplicate), "duplicate command is identified")
	_check(duplicate.snapshot.state_revision == 1, "duplicate command does not charge twice")
	var stale := SliceRules.commit(commit_bundle.snapshot, "stale", 0, "lead_rafi")
	_check(not bool(stale.result.accepted), "stale revision is rejected")
	_check(stale.snapshot.state_revision == 1, "rejected command preserves state")
	var path := OS.get_temp_dir().path_join("slice_state_test_%d.json" % Time.get_ticks_usec())
	_check(SliceState.save_snapshot(commit_bundle.snapshot, path), "snapshot saves")
	var loaded := SliceState.load_snapshot(path)
	_check(loaded.get("state_revision", -1) == 1 and loaded.get("scene_id", "") == "EX-CH01-S02", "snapshot reloads with primitive state")
	_check(loaded.get("resources", {}).get("air", -1) == 8 and loaded.get("resources", {}).get("energy", -1) == 13, "saved resource deltas round trip")
	_check(SliceState.clear_save(path), "test snapshot cleans up")
	var sparse := SliceState.new_snapshot()
	sparse.erase("resources")
	sparse.erase("settings")
	var sparse_path := OS.get_temp_dir().path_join("slice_state_sparse_%d.json" % Time.get_ticks_usec())
	_check(SliceState.save_snapshot(sparse, sparse_path), "sparse snapshot saves")
	var repaired := SliceState.load_snapshot(sparse_path)
	_check(repaired.get("resources", {}).get("energy", -1) == 14 and repaired.get("resources", {}).get("air", -1) == 6, "missing resource fields recover from defaults")
	_check(repaired.get("settings", {}).get("captions", false), "missing accessibility settings recover from defaults")
	_check(SliceState.clear_save(sparse_path), "sparse snapshot cleans up")
	sparse["history"] = "corrupt"
	sparse["receipts"] = 42
	var corrupt_path := OS.get_temp_dir().path_join("slice_state_corrupt_%d.json" % Time.get_ticks_usec())
	_check(SliceState.save_snapshot(sparse, corrupt_path), "corrupt collection snapshot saves")
	var repaired_collections := SliceState.load_snapshot(corrupt_path)
	_check(repaired_collections.get("history") is Array and repaired_collections.get("receipts") is Dictionary, "malformed collections recover safely")
	_check(SliceState.clear_save(corrupt_path), "corrupt collection snapshot cleans up")
	print("SLICE STATE RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)
