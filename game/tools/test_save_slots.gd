extends SceneTree

## M3-71: Verification suite for save slots, autosave, atomic writes, backup
## recovery, versioned forward migrations (keeping story_log schema 3 readable),
## read-only save metadata API, and SaveSlotsPanel UI.

const SaveScript = preload("res://scripts/save/save_service.gd")
const SlotsScript = preload("res://scripts/save/save_slots.gd")
const PanelScript = preload("res://scripts/ui/save_slots.gd")
const StateScript = preload("res://scripts/core/campaign_state.gd")
const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const RouteScript = preload("res://scripts/missions/chapter1_route.gd")
const CampaignScript = preload("res://scripts/campaign/chapter1_campaign.gd")
const ContentScript = preload("res://scripts/content/content_loader.gd")

var storage = preload("res://tools/support/isolated_storage.gd").new()
var checks := 0
var failures := 0
var write_evidence := false

func _init() -> void:
	write_evidence = OS.get_cmdline_user_args().has("--evidence")
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	_check(storage.setup("M3-71"), "isolated storage configured for M3-71")
	if write_evidence:
		_check(storage.prepare_rendering_cache(), "isolated rendering cache prepared")

	var slots := SlotsScript.new(storage.path, CampaignScript.restore_session)
	slots.clear_all()

	_test_autosave_and_three_manual_slots(slots)
	_test_schema3_and_legacy_forward_migration(slots)
	_test_corrupt_detection_and_backup_recovery(slots)
	_test_readonly_metadata_api(slots)
	await _test_save_slots_panel_ui(slots)

	slots.clear_all()
	storage.cleanup()
	print("SAVE SLOTS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _make_resumable_snapshot(chapter: int = 1, state_rev_bump: int = 0) -> Dictionary:
	var director := DirectorScript.new()
	director.new_campaign(ContentScript.EXPECTED_CONTENT_REVISION)
	var route: RefCounted
	if chapter == 1:
		route = RouteScript.new(director)
	elif chapter == 2:
		route = preload("res://scripts/missions/chapter2_route.gd").new(director)
	else:
		var ext := preload("res://scripts/missions/extended_campaign_route.gd").new(director)
		ext.start_at("EX-CH%02d-S01" % chapter)
		route = ext
	if chapter == 1:
		var cmd := {
			"command_id": "m371-choice-%d" % state_rev_bump,
			"issuer": "player",
			"owning_mission_id": route.current_mission_id(),
			"owning_scene_id": route.current_scene_id(),
			"expected_state_revision": int(director.snapshot().state_revision),
			"target_id": "EX-CH01-S01-CHOICE",
			"verb": "record_choice",
			"payload": {"choice_id": "EX-CH01-S01-CHOICE", "option_id": "EX-CH01-S01-OPT01"},
		}
		director.commit(cmd)
	var snap: Dictionary = director.snapshot()
	snap["chapter_id"] = "CH%02d" % chapter
	snap["scene_id"] = route.current_scene_id()
	snap["mission_id"] = route.current_mission_id()
	snap["route_runtime"] = route.snapshot()
	if state_rev_bump > 0:
		snap["state_revision"] = int(snap.get("state_revision", 0)) + state_rev_bump
	return snap

func _test_autosave_and_three_manual_slots(slots: RefCounted) -> void:
	var ch1 := _make_resumable_snapshot(1)
	var join_save: Dictionary = slots.autosave_scene_join(ch1, "EX-CH01-S01", 325.0)
	_check(bool(join_save.get("accepted", false)) and String(join_save.get("trigger", "")) == "scene_join", "autosave_scene_join writes validated autosave slot")

	var ch1_next := _make_resumable_snapshot(1, 2)
	var mission_save: Dictionary = slots.autosave_mission_end(ch1_next, "EX-M0101", 640.0)
	_check(bool(mission_save.get("accepted", false)) and String(mission_save.get("trigger", "")) == "mission_end", "autosave_mission_end updates autosave and creates .bak backup")
	_check(FileAccess.file_exists(slots.slot_path("autosave")) and FileAccess.file_exists(slots.slot_path("autosave") + ".bak"), "atomic write produces primary and one-generation .bak file")
	_check(not FileAccess.file_exists(slots.slot_path("autosave") + ".tmp"), "atomic write cleans up .tmp file after rename")

	# Three manual slots round-trip
	for idx in range(1, 4):
		var slot_id := "slot_%d" % idx
		var snap := _make_resumable_snapshot(idx, idx)
		var res: Dictionary = slots.save_slot(slot_id, snap, "manual", {"play_time_seconds": float(idx * 900)})
		_check(bool(res.get("accepted", false)), "manual save succeeds for " + slot_id)
		var loaded: Dictionary = slots.load_slot(slot_id)
		_check(bool(loaded.get("accepted", false)), "manual load round-trip succeeds for " + slot_id)
		var loaded_snap: Dictionary = loaded.get("snapshot", {})
		_check(String(loaded_snap.get("chapter_id", "")) == ("CH%02d" % idx), "round-trip preserves chapter_id for " + slot_id)
		var meta: Dictionary = loaded.get("metadata", {})
		_check(int(meta.get("chapter", 0)) == idx and int(meta.get("play_time_seconds", 0)) == idx * 900, "round-trip metadata preserves chapter and play_time for " + slot_id)

func _test_schema3_and_legacy_forward_migration(slots: RefCounted) -> void:
	# Pure M1-47 story_log schema 3 save (without slot_metadata) stays readable and upgrades slot metadata cleanly
	var raw_schema3 := _make_resumable_snapshot(1)
	raw_schema3["presentation_resume"] = {}
	var s1_path: String = slots.slot_path("slot_1")
	_write_raw(s1_path, JSON.stringify(raw_schema3))

	var inspected: Dictionary = slots.inspect_slot("slot_1")
	_check(bool(inspected.get("valid", false)) and int(inspected.get("chapter", 0)) == 1, "existing story_log schema 3 save without slot_metadata is readable by inspect_slot")
	var loaded_s3: Dictionary = slots.load_slot("slot_1")
	_check(bool(loaded_s3.get("accepted", false)), "existing story_log schema 3 save loads cleanly")
	var choices: Dictionary = loaded_s3.get("snapshot", {}).get("story_log", {}).get("choices", {})
	_check(choices.has("EX-CH01-S01-CHOICE") and String(choices["EX-CH01-S01-CHOICE"].get("option_id", "")) == "EX-CH01-S01-OPT01", "story_log schema 3 choices remain intact after slot load")
	var slot_meta: Dictionary = loaded_s3.get("snapshot", {}).get("presentation_resume", {}).get("slot_metadata", {})
	_check(int(slot_meta.get("version", 0)) == 1 and not String(slot_meta.get("thumbnail_path", "")).is_empty(), "schema 3 save is forward-enriched with slot_metadata v1 on load")

	# Schema 2 save forward migration into slot_2
	var raw_v2 := _make_resumable_snapshot(1)
	raw_v2["schema_version"] = 2
	raw_v2.erase("story_log")
	raw_v2["route_runtime"]["retry_checkpoint"]["director"]["schema_version"] = 2
	raw_v2["route_runtime"]["retry_checkpoint"]["director"].erase("story_log")
	var s2_path: String = slots.slot_path("slot_2")
	_write_raw(s2_path, JSON.stringify(raw_v2))

	var loaded_v2: Dictionary = slots.load_slot("slot_2")
	_check(bool(loaded_v2.get("accepted", false)) and bool(loaded_v2.get("migrated", false)), "schema 2 save in slot_2 migrates forward to schema 3")
	_check(loaded_v2.get("snapshot", {}).get("schema_version", 0) == 3 and loaded_v2.get("snapshot", {}).get("story_log") == {"choices": {}, "moments": []}, "migrated schema 2 slot has valid empty story_log")

func _test_corrupt_detection_and_backup_recovery(slots: RefCounted) -> void:
	var s3_first := _make_resumable_snapshot(2, 1)
	var s3_second := _make_resumable_snapshot(2, 5)
	_check(bool(slots.save_slot("slot_3", s3_first, "manual", {"play_time_seconds": 1200.0}).get("accepted", false)), "seed first valid save in slot_3")
	_check(bool(slots.save_slot("slot_3", s3_second, "manual", {"play_time_seconds": 1500.0}).get("accepted", false)), "seed second valid save in slot_3 so .bak holds first checkpoint")

	# Corrupt primary file
	var s3_path: String = slots.slot_path("slot_3")
	_write_raw(s3_path, "{corrupt_json_payload")

	# Read-only inspection detects corruption and reports backup availability without touching disk
	var meta: Dictionary = slots.inspect_slot("slot_3")
	_check(bool(meta.get("corrupt", false)) and bool(meta.get("backup_available", false)), "inspect_slot detects corrupt primary and available .bak")
	_check(FileAccess.get_file_as_string(s3_path) == "{corrupt_json_payload", "inspect_slot is strictly read-only and leaves corrupt primary untouched")

	# Non-auto-recover load offers backup explicitly
	var offered: Dictionary = slots.load_slot("slot_3", false)
	_check(not bool(offered.get("accepted", false)) and bool(offered.get("corrupt", false)) and bool(offered.get("backup_available", false)) and String(offered.get("reason", "")) == "corrupt_primary_backup_offered", "load_slot(allow_auto_recover=false) detects corrupt file and offers backup")

	# Explicit backup recovery falls back to .bak and repairs primary
	var recovered: Dictionary = slots.recover_slot_from_backup("slot_3")
	_check(bool(recovered.get("accepted", false)) and bool(recovered.get("recovered", false)), "recover_slot_from_backup restores verified .bak")
	_check(int(recovered.get("metadata", {}).get("play_time_seconds", 0)) == 1200, "recovered slot matches backup checkpoint metadata")
	_check(bool(slots.inspect_slot("slot_3").get("valid", false)) and not bool(slots.inspect_slot("slot_3").get("corrupt", false)), "slot_3 primary is repaired after backup recovery")

func _test_readonly_metadata_api(slots: RefCounted) -> void:
	var service := SaveScript.new()
	service.session_validator = CampaignScript.restore_session
	var before_bytes := {}
	for slot_id in SlotsScript.ALL_SLOTS:
		var p: String = slots.slot_path(slot_id)
		if FileAccess.file_exists(p):
			before_bytes[slot_id] = FileAccess.get_file_as_bytes(p)
	var all_rows: Array[Dictionary] = service.all_slot_metadata(storage.path)
	_check(all_rows.size() == 4, "SaveService.all_slot_metadata returns 4 slots (autosave + 3 manual)")
	for row in all_rows:
		for required_key in ["slot_id", "chapter", "story_date", "play_time", "thumbnail_path"]:
			_check(row.has(required_key), "metadata row for %s includes %s" % [String(row.get("slot_id", "")), required_key])
	for slot_id in before_bytes.keys():
		var p: String = slots.slot_path(slot_id)
		_check(FileAccess.get_file_as_bytes(p) == before_bytes[slot_id], "all_slot_metadata never modifies bytes of " + slot_id)

func _test_save_slots_panel_ui(slots: RefCounted) -> void:
	# Make slot_2 corrupt with a valid backup so the UI shows both normal and corrupt-backup-offered states
	var valid_s2 := _make_resumable_snapshot(3, 1)
	slots.save_slot("slot_2", valid_s2, "manual", {"play_time_seconds": 2100.0})
	slots.save_slot("slot_2", valid_s2, "manual", {"play_time_seconds": 2200.0})
	_write_raw(slots.slot_path("slot_2"), "{broken_slot_2")

	var panel := PanelScript.new()
	panel.save_path = storage.path
	panel.session_validator = CampaignScript.restore_session
	panel.allow_save_current = true
	panel.current_snapshot_source = func() -> Dictionary: return _make_resumable_snapshot(4, 2)
	root.add_child(panel)
	await process_frame
	await process_frame

	for slot_id in SlotsScript.ALL_SLOTS:
		_check(panel.find_child("SlotCard_" + slot_id, true, false) != null, "SaveSlotsPanel renders card for " + slot_id)
		_check(panel.find_child("SlotThumbnail_" + slot_id, true, false) != null, "SaveSlotsPanel renders thumbnail for " + slot_id)

	var recover_btn := panel.find_child("RecoverSlot_slot_2", true, false) as Button
	_check(recover_btn != null and not recover_btn.disabled, "SaveSlotsPanel offers Restore Backup button for corrupt slot_2")
	await _save_shot("M3-71_save_slots_corrupt_backup.png")

	if recover_btn != null:
		recover_btn.pressed.emit()
		await process_frame
	_check(bool(slots.inspect_slot("slot_2").get("valid", false)), "clicking Restore Backup in SaveSlotsPanel repairs slot_2")

	var save_s1_btn := panel.find_child("SaveSlot_slot_1", true, false) as Button
	_check(save_s1_btn != null and not save_s1_btn.disabled, "SaveSlotsPanel exposes Save Here button on manual slot_1")
	if save_s1_btn != null:
		save_s1_btn.pressed.emit()
		await process_frame
	_check(int(slots.inspect_slot("slot_1").get("chapter", 0)) == 4, "clicking Save Here writes current Chapter 4 snapshot to slot_1")
	await _save_shot("M3-71_save_slots_recovered.png")

	panel.queue_free()
	await process_frame

func _write_raw(target: String, content: String) -> void:
	var f := FileAccess.open(target, FileAccess.WRITE)
	assert(f != null)
	f.store_string(content)
	f.close()

func _save_shot(filename: String) -> void:
	if not write_evidence:
		return
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if img != null:
		var out_path := ProjectSettings.globalize_path("res://../production/qa/evidence/" + filename)
		img.save_png(out_path)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)
