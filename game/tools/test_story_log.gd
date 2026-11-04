## Schema migration, catalog validation and authoritative story command checks.
extends SceneTree

const State = preload("res://scripts/core/campaign_state.gd")
const Director = preload("res://scripts/core/campaign_director.gd")
const Saves = preload("res://scripts/save/save_service.gd")
const Campaign = preload("res://scripts/campaign/chapter1_campaign.gd")
const Route = preload("res://scripts/missions/chapter1_route.gd")

var checks := 0
var failures := 0
var save_service := Saves.new()
var path := ""

func _init() -> void:
	path = OS.get_temp_dir().path_join("lla-story-log-%d-%d.json" % [OS.get_process_id(), Time.get_ticks_usec()])
	_test_v2_load_migrates_empty_story_log()
	_test_v1_migrates_through_v2()
	_test_v2_retry_checkpoint_remains_resumable()
	_test_choice_preview_confirmation_and_idempotency()
	_test_choice_locks_at_scene_exit()
	_test_moments_are_unique_and_preview_is_inert()
	_test_story_validation()
	save_service.clear(path)
	print("STORY LOG RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_v2_load_migrates_empty_story_log() -> void:
	var v2 := State.new_snapshot()
	v2.schema_version = 2
	v2.erase("story_log")
	v2["custom_legacy_value"] = {"preserved": ["yes"]}
	var original := v2.duplicate(true)
	_write(v2)
	var loaded := save_service.load(path)
	_check(loaded.get("accepted", false) and loaded.get("migrated", false), "v2_save_loads_and_migrates_to_v3")
	var migrated: Dictionary = loaded.get("snapshot", {})
	_check(migrated.get("schema_version") == 3 and migrated.get("story_log") == {"choices": {}, "moments": []}, "v2_migration_adds_empty_story_log")
	migrated.erase("story_log")
	migrated.erase("save_format")
	migrated.schema_version = 2
	_check(_json_same(migrated, original) and v2 == original, "v2_migration_preserves_every_existing_field_and_source")
	var invalid := original.duplicate(true)
	invalid.erase("receipts")
	_check(not save_service.migrate(invalid).accepted, "malformed_v2_does_not_bypass_current_validation")

func _test_v1_migrates_through_v2() -> void:
	var v1 := {"schema_version": 1, "save_id": "legacy", "resources": {"energy": 14, "air": 6, "alo_health": 6, "water_shielding": 0, "crate_shielding": 0, "crop_condition": 8, "rations": 12.0, "exposure": 0}}
	var result := save_service.migrate(v1)
	_check(result.accepted and result.from_schema == 1 and result.to_schema == 3 and State.is_compatible(result.snapshot), "v1_migrates_through_v2_to_valid_v3")
	_check(result.snapshot.story_log == {"choices": {}, "moments": []} and not v1.has("story_log"), "v1_migration_is_empty_and_does_not_mutate_source")

func _test_v2_retry_checkpoint_remains_resumable() -> void:
	var director := Director.new()
	director.new_campaign(preload("res://scripts/content/content_loader.gd").EXPECTED_CONTENT_REVISION)
	var route := Route.new(director)
	var v2 := director.snapshot()
	v2["route_runtime"] = route.snapshot()
	v2.schema_version = 2
	v2.erase("story_log")
	v2.route_runtime.retry_checkpoint.director.schema_version = 2
	v2.route_runtime.retry_checkpoint.director.erase("story_log")
	_write(v2)
	save_service.session_validator = Campaign.restore_session
	var loaded := save_service.load(path)
	_check(loaded.get("accepted", false), "v2_production_save_with_retry_checkpoint_can_continue")
	if loaded.get("accepted", false):
		var resumed := Campaign.restore_session(loaded.snapshot)
		_check(resumed.accepted and resumed.route.retry().accepted, "migrated_nested_retry_director_remains_restorable")
		_check(loaded.snapshot.route_runtime.retry_checkpoint.director.schema_version == 3 and loaded.snapshot.route_runtime.retry_checkpoint.director.story_log.choices.is_empty(), "nested_v2_director_receives_schema3_and_empty_story_log")
	save_service.session_validator = Callable()

func _test_choice_preview_confirmation_and_idempotency() -> void:
	var director := Director.new()
	director.new_campaign()
	var command := _command(director, "record_choice", {"choice_id": "EX-CH01-S01-CHOICE", "option_id": "EX-CH01-S01-OPT01"}, "first-choice")
	var before := director.snapshot()
	var preview := director.preview(command)
	_check(preview.accepted and preview.snapshot.story_log == before.story_log and director.snapshot() == before, "choice_preview_adds_no_entry_receipt_or_revision")
	var confirmed := director.commit(command)
	var snapshot := director.snapshot()
	_check(confirmed.accepted and snapshot.story_log.choices.size() == 1, "confirm_EX_CH01_S01_CHOICE_adds_exactly_one_entry")
	_check(snapshot.story_log.choices["EX-CH01-S01-CHOICE"] == {"option_id": "EX-CH01-S01-OPT01", "scene_id": "EX-CH01-S01", "scenario_datetime": before.scenario_datetime, "state_revision": before.state_revision + 1}, "choice_metadata_matches_committed_scene_time_and_revision")
	_check(snapshot.state_revision == before.state_revision + 1 and snapshot.receipts.has(command.command_id) and snapshot.mission_receipts.has(command.command_id), "choice_uses_existing_receipts_and_revision_protocol")
	_check(snapshot.resources == before.resources and snapshot.knowledge_flags == before.knowledge_flags and snapshot.scenario_datetime == before.scenario_datetime, "choice_never_changes_science_resources_knowledge_or_time")
	var repeat := director.commit(command)
	_check(repeat.accepted and repeat.get("duplicate", false) and director.snapshot() == snapshot, "repeated_command_id_adds_nothing")
	_check(save_service.save(snapshot, path).accepted, "confirmed_choice_saves")
	var restored := Director.new()
	var loaded := save_service.load(path)
	_check(loaded.accepted and restored.restore_snapshot(loaded.snapshot).accepted, "confirmed_choice_loads_and_restores")
	_check(restored.commit(command).get("duplicate", false) and _json_same(restored.snapshot().story_log, snapshot.story_log), "command_id_stays_idempotent_after_save_reload")
	var invalid := _command(director, "record_choice", {"choice_id": "EX-CH01-S01-CHOICE", "option_id": "EX-CH01-S02-OPT01"})
	var rejected := director.commit(invalid)
	_check(not rejected.accepted and String(rejected.reason).contains("Unknown option_id") and director.snapshot() == snapshot, "unknown_option_id_rejected_with_reason_and_no_changes")
	var future := _command(director, "record_choice", {"choice_id": "EX-CH01-S02-CHOICE", "option_id": "EX-CH01-S02-OPT01"})
	_check(not director.commit(future).accepted, "future_scene_choice_rejected")
	var foreign := _command(director, "record_choice", {"choice_id": "EX-CH01-S01-CHOICE", "option_id": "EX-CH01-S01-OPT01"})
	foreign.owning_scene_id = "EX-CH01-S02"
	_check(not director.commit(foreign).accepted, "foreign_scene_command_rejected")
	director.pause()
	_check(not director.commit(_command(director, "record_choice", command.payload)).accepted, "story_commit_obeys_pause")
	director.resume()
	var stale := _command(director, "record_choice", command.payload)
	stale.expected_state_revision = -1
	_check(not director.commit(stale).accepted, "story_commit_obeys_revision_check")
	var revised := director.commit(_command(director, "record_choice", {"choice_id": "EX-CH01-S01-CHOICE", "option_id": "EX-CH01-S01-OPT02"}))
	_check(revised.accepted and director.snapshot().story_log.choices.size() == 1 and director.snapshot().story_log.choices["EX-CH01-S01-CHOICE"].option_id == "EX-CH01-S01-OPT02", "choice_can_be_revised_before_exit_without_duplicate_entries")

func _test_choice_locks_at_scene_exit() -> void:
	var director := Director.new()
	director.new_campaign()
	var payload := {"choice_id": "EX-CH01-S01-CHOICE", "option_id": "EX-CH01-S01-OPT01"}
	director.commit(_command(director, "record_choice", payload))
	var exit_command := _command(director, "set_phase", {"phase": "scene_complete:EX-CH01-S01", "physical_gate": true}, "scene-complete:EX-CH01-S01")
	_check(director.commit(exit_command).accepted, "scene_exit_receipt_commits")
	var before := director.snapshot()
	var changed := director.commit(_command(director, "record_choice", {"choice_id": payload.choice_id, "option_id": "EX-CH01-S01-OPT02"}))
	_check(not changed.accepted and String(changed.reason).contains("locked") and director.snapshot() == before, "choice_cannot_change_after_scene_exit_before_route_projection")
	director.commit(_command(director, "set_phase", {"phase": "briefing"}))
	_check(not director.commit(_command(director, "record_choice", payload)).accepted, "exit_lock_survives_later_phase_changes")
	var fresh := Director.new()
	fresh.restore_snapshot(director.snapshot())
	_check(not fresh.commit(_command(fresh, "record_choice", payload)).accepted, "exit_lock_survives_snapshot_restore")

func _test_moments_are_unique_and_preview_is_inert() -> void:
	var director := Director.new()
	director.new_campaign()
	var command := _command(director, "record_moment", {"moment_id": "CH01-MUGS-NAMED"}, "moment-one")
	var before := director.snapshot()
	_check(director.preview(command).accepted and director.snapshot() == before, "moment_preview_is_inert")
	_check(director.commit(command).accepted and director.snapshot().story_log.moments == ["CH01-MUGS-NAMED"], "moment_commits_once")
	var revision: int = director.snapshot().state_revision
	_check(director.commit(command).get("duplicate", false) and director.snapshot().state_revision == revision, "moment_command_id_is_idempotent")
	director.commit(_command(director, "record_moment", command.payload))
	_check(director.snapshot().story_log.moments == ["CH01-MUGS-NAMED"], "moment_stays_unique_across_distinct_commands")
	director.commit(_command(director, "record_moment", {"moment_id": "CH08-LIGHT-CLIPPED"}))
	_check(director.snapshot().story_log.moments == ["CH01-MUGS-NAMED", "CH08-LIGHT-CLIPPED"], "moments_preserve_recording_order")
	_check(save_service.save(director.snapshot(), path).accepted and save_service.load(path).snapshot.story_log == director.snapshot().story_log, "moments_round_trip_through_disk")
	for bad in ["", "  ", 42, null, []]:
		_check(not director.commit(_command(director, "record_moment", {"moment_id": bad})).accepted, "malformed_moment_id_rejected: " + str(bad))

func _test_story_validation() -> void:
	var entry := {"option_id": "EX-CH01-S01-OPT01", "scene_id": "EX-CH01-S01", "scenario_datetime": "2046-04-11 06:00 UTC", "state_revision": 1}
	var valid := State.new_snapshot()
	valid.state_revision = 1
	valid.story_log.choices["EX-CH01-S01-CHOICE"] = entry.duplicate(true)
	_check(State.validate_snapshot(valid).valid, "valid_story_entry_passes_snapshot_validation")
	for pair in [["option_id", "EX-CH01-S02-OPT01"], ["option_id", null], ["scene_id", "EX-CH01-S02"], ["scenario_datetime", "2046-02-30 00:00 UTC"], ["scenario_datetime", "2047-01-01 00:00 UTC"], ["state_revision", -1], ["state_revision", 0.5], ["state_revision", 2], ["state_revision", "one"], ["state_revision", INF]]:
		var bad := valid.duplicate(true)
		bad.story_log.choices["EX-CH01-S01-CHOICE"][pair[0]] = pair[1]
		_check(not State.validate_snapshot(bad).valid, "invalid_choice_metadata_rejected: %s=%s" % pair)
	for field in entry:
		var bad := valid.duplicate(true)
		bad.story_log.choices["EX-CH01-S01-CHOICE"].erase(field)
		_check(not State.validate_snapshot(bad).valid, "missing_choice_metadata_rejected: " + field)
	for malformed in [{}, {"choices": [], "moments": []}, {"choices": {}, "moments": {}}, {"choices": {"unknown": entry}, "moments": []}, {"choices": {"EX-CH01-S01-CHOICE": []}, "moments": []}, {"choices": {}, "moments": ["same", "same"]}, {"choices": {}, "moments": [42]}, {"choices": {}, "moments": [""]}]:
		var bad := valid.duplicate(true)
		bad.story_log = malformed
		_check(not State.validate_snapshot(bad).valid and not save_service.migrate(bad).accepted, "malformed_story_log_rejected_by_state_and_save: " + str(malformed))
	var dedication := valid.duplicate(true)
	dedication.story_log.choices = {"EX-CH03-S11-DEDICATION": {"option_id": "reserved-option-id", "scene_id": "EX-CH03-S11", "scenario_datetime": entry.scenario_datetime, "state_revision": 1}}
	_check(State.validate_snapshot(dedication).valid, "reserved_dedication_identity_accepted_without_new_canon_text")
	var catalog: Dictionary = preload("res://scripts/content/content_loader.gd").load_full()
	var all_options_valid := true
	for scene in catalog.scenes:
		for option in scene.choice.options:
			all_options_valid = all_options_valid and State.story_choice_problem(scene.choice.id, option.id).is_empty() and State.story_choice_scene_id(scene.choice.id) == scene.id
	_check(all_options_valid, "all_96_catalog_choices_resolve_their_own_options_and_scenes")

func _command(director: RefCounted, verb: String, payload: Dictionary, command_id: String = "") -> Dictionary:
	var query: Dictionary = director.query()
	return {"command_id": command_id if not command_id.is_empty() else "%s:%d" % [verb, query.state_revision], "issuer": "story_log_test", "owning_mission_id": query.mission_id, "owning_scene_id": query.scene_id, "expected_state_revision": query.state_revision, "target_id": payload.get("choice_id", payload.get("moment_id", "test")), "verb": verb, "payload": payload.duplicate(true)}

func _write(snapshot: Dictionary) -> void:
	save_service.clear(path)
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify(snapshot))
	file.close()

func _json_same(left: Dictionary, right: Dictionary) -> bool:
	# Godot parses JSON numbers as floats; compare both through that boundary.
	return JSON.parse_string(JSON.stringify(left)) == JSON.parse_string(JSON.stringify(right))

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)
