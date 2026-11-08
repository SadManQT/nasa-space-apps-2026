## Godot --headless --path game --script res://tools/test_director_message_metadata.gd
## M1-89: CampaignDirector.update_message_metadata() records inbox deliveries
## and reads in presentation_resume.messages without touching gameplay state,
## the revision a PuzzleHost preview captured, or the pre-shift checkpoint.
extends SceneTree

const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const StateScript = preload("res://scripts/core/campaign_state.gd")
const ResultScript = preload("res://scripts/core/command_result.gd")
const HostScript = preload("res://scripts/puzzles/puzzle_host.gd")
const SaveScript = preload("res://scripts/save/save_service.gd")
const ContentScript = preload("res://scripts/content/content_loader.gd")
const RouteScript = preload("res://scripts/missions/chapter1_route.gd")
const CampaignScript = preload("res://scripts/campaign/chapter1_campaign.gd")

# The first shift of the P-02 Bloom witness plan (game-design/08_PUZZLE_DESIGNS.md).
const SHIFT := {"heat": "DAY", "air_production": 2, "light": "FULL", "transfer": "HOLD"}
const EMPTY := {"delivered_ids": [], "read_ids": []}

var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_puzzle_host_preview_update_commit_retry()
	_test_duplicates_and_order()
	_test_malformed_updates_are_atomic()
	_test_missing_and_fresh_state()
	_test_restore_validates_the_record()
	_test_save_round_trip_and_old_saves()
	_test_route_retry_reapply()
	_test_scene_projection_keeps_record()
	print("DIRECTOR MESSAGE METADATA RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_puzzle_host_preview_update_commit_retry() -> void:
	var director := DirectorScript.new()
	director.new_campaign(ContentScript.EXPECTED_CONTENT_REVISION)
	var host := HostScript.new()
	host.bind(director, "P-02", "EX-M0102", "EX-CH01-S05")
	var plan := {"shifts": [SHIFT]}
	var before: Dictionary = director.snapshot()
	var preview: Dictionary = host.preview(plan)
	_check(bool(preview.get("accepted", false)) and director.snapshot() == before, "PuzzleHost preview is accepted and leaves the director untouched")
	var delivered: Dictionary = director.update_message_metadata({"delivered_ids": ["MSG-CH01-001", "MSG-CH01-002"]})
	_check(bool(delivered.accepted) and not bool(delivered.duplicate) and ResultScript.has_contract(delivered), "a delivery update is accepted with the command-result contract")
	_check(delivered.input_revision == 0 and delivered.output_revision == 0 and delivered.receipt_id == "" and director.query().state_revision == 0, "a message update never advances the gameplay revision or writes a receipt")
	_check(delivered.events.size() == 1 and delivered.events[0].type == "message_metadata_updated" and delivered.events[0].state_revision == 0, "an update publishes one message_metadata_updated event at the unchanged revision")
	_check(delivered.deltas == [{"field": "presentation_resume.messages.delivered_ids", "added": ["MSG-CH01-001", "MSG-CH01-002"]}], "the delta lists exactly the newly delivered IDs")
	_check(_gameplay(director.snapshot()) == _gameplay(before) and director.snapshot() != before, "only presentation_resume.messages changed")
	_check(_gameplay(director._checkpoint) == _gameplay(before), "the pre-shift checkpoint keeps its gameplay state")
	var read: Dictionary = director.update_message_metadata({"read_ids": ["MSG-CH01-001"]})
	_check(bool(read.accepted) and read.messages == {"delivered_ids": ["MSG-CH01-001", "MSG-CH01-002"], "read_ids": ["MSG-CH01-001"]} and read.snapshot == director.snapshot(), "a read update returns the merged record and the live snapshot")
	director.pause("inbox")
	var paused_read: Dictionary = director.update_message_metadata({"read_ids": ["MSG-CH01-002"]})
	_check(bool(paused_read.accepted) and bool(director.query().paused), "the inbox can be read while the expedition is paused")
	director.resume()
	var committed: Dictionary = host.commit("m189-shift-1", plan)
	_check(bool(committed.get("accepted", false)) and director.query().state_revision == 1 and director.query().current_shift == 1, "the preview captured before the message updates still commits")
	var both_read := {"delivered_ids": ["MSG-CH01-001", "MSG-CH01-002"], "read_ids": ["MSG-CH01-001", "MSG-CH01-002"]}
	_check(director.message_metadata() == both_read, "a gameplay commit carries the message record forward")
	_check(_gameplay(director._checkpoint) == _gameplay(before), "the commit took its retry checkpoint from the pre-shift gameplay state")
	var committed_state: Dictionary = director.snapshot()
	var later: Dictionary = director.update_message_metadata({"delivered_ids": ["MSG-CH01-003"], "read_ids": ["MSG-CH01-003"]})
	_check(bool(later.accepted) and _gameplay(director.snapshot()) == _gameplay(committed_state) and director.snapshot().receipts.has("m189-shift-1"), "a post-commit update leaves the committed shift, its receipt and the revision alone")
	_check(_gameplay(director._checkpoint) == _gameplay(before), "a post-commit update never moves the pre-shift checkpoint")
	var all_three := {"delivered_ids": ["MSG-CH01-001", "MSG-CH01-002", "MSG-CH01-003"], "read_ids": ["MSG-CH01-001", "MSG-CH01-002", "MSG-CH01-003"]}
	var retry: Dictionary = host.retry()
	_check(bool(retry.get("accepted", false)) and _gameplay(director.snapshot()) == _gameplay(before), "PuzzleHost retry returns to the same pre-shift gameplay checkpoint")
	_check(not director.snapshot().receipts.has("m189-shift-1") and director.query().current_shift == 0, "retry rolled back the shift and its receipt")
	_check(director.message_metadata() == all_three, "delivered and read messages intentionally survive the gameplay retry")
	var again: Dictionary = host.preview(plan)
	var replay: Dictionary = host.commit("m189-shift-1", plan)
	_check(bool(again.get("accepted", false)) and bool(replay.get("accepted", false)) and not bool(replay.get("duplicate", false)) and director.query().state_revision == 1, "the retried shift commits once more")
	var duplicate: Dictionary = host.commit("m189-shift-1", plan)
	_check(bool(duplicate.get("duplicate", false)) and director.query().state_revision == 1 and director.message_metadata() == all_three, "a replayed commit returns its receipt and keeps the messages")

func _test_duplicates_and_order() -> void:
	var director := DirectorScript.new()
	director.new_campaign(ContentScript.EXPECTED_CONTENT_REVISION)
	var first: Dictionary = director.update_message_metadata({"delivered_ids": ["MSG-CH01-004", "MSG-CH01-002", "MSG-CH01-004"], "read_ids": ["MSG-CH01-002", "MSG-CH01-002"]})
	_check(bool(first.accepted) and director.message_metadata() == {"delivered_ids": ["MSG-CH01-004", "MSG-CH01-002"], "read_ids": ["MSG-CH01-002"]}, "repeats inside one call collapse, arrival order is kept, and delivery plus read can share a call")
	var state: Dictionary = director.snapshot()
	var checkpoint: Dictionary = director._checkpoint.duplicate(true)
	var repeat: Dictionary = director.update_message_metadata({"delivered_ids": ["MSG-CH01-002"], "read_ids": ["MSG-CH01-002"]})
	_check(bool(repeat.accepted) and bool(repeat.duplicate) and repeat.events.is_empty() and repeat.deltas.is_empty(), "a repeated update is accepted as a harmless duplicate")
	_check(director.snapshot() == state and director._checkpoint == checkpoint, "a duplicate update changes nothing at all")
	var nothing: Dictionary = director.update_message_metadata(EMPTY)
	_check(bool(nothing.accepted) and bool(nothing.duplicate) and director.snapshot() == state, "re-applying an empty record is a harmless duplicate")
	var packed: Dictionary = director.update_message_metadata({&"delivered_ids": PackedStringArray(["MSG-CH01-005"])})
	_check(bool(packed.accepted) and director.message_metadata().delivered_ids == ["MSG-CH01-004", "MSG-CH01-002", "MSG-CH01-005"], "StringName keys and PackedStringArray IDs are accepted and stored as plain Strings")
	_check(director.snapshot().presentation_resume.messages.delivered_ids[2] is String, "stored IDs are primitive Strings")
	var copy: Dictionary = director.message_metadata()
	copy.delivered_ids.append("MSG-CH01-999")
	_check(not director.message_metadata().delivered_ids.has("MSG-CH01-999"), "message_metadata() returns a copy")
	var limit_director := DirectorScript.new()
	var many: Array = []
	for index in range(StateScript.MESSAGE_ID_LIMIT):
		many.append("MSG-T-%04d" % index)
	_check(bool(limit_director.update_message_metadata({"delivered_ids": many}).accepted), "a record may hold MESSAGE_ID_LIMIT IDs")
	var overflow: Dictionary = limit_director.update_message_metadata({"delivered_ids": ["MSG-T-OVER"]})
	_check(not bool(overflow.accepted) and limit_director.message_metadata().delivered_ids.size() == StateScript.MESSAGE_ID_LIMIT, "an update that would pass MESSAGE_ID_LIMIT is rejected")

func _test_malformed_updates_are_atomic() -> void:
	var director := DirectorScript.new()
	director.new_campaign(ContentScript.EXPECTED_CONTENT_REVISION)
	director.update_message_metadata({"delivered_ids": ["MSG-CH01-001"], "read_ids": ["MSG-CH01-001"]})
	var host := HostScript.new()
	host.bind(director, "P-02", "EX-M0102", "EX-CH01-S05")
	host.preview({"shifts": [SHIFT]})
	host.commit("m189-atomic", {"shifts": [SHIFT]})
	var state: Dictionary = director.snapshot()
	var checkpoint: Dictionary = director._checkpoint.duplicate(true)
	var cases := {
		"empty metadata": {},
		"String instead of Array": {"delivered_ids": "MSG-CH01-009"},
		"Dictionary instead of Array": {"delivered_ids": {"MSG-CH01-009": true}},
		"null field": {"delivered_ids": ["MSG-CH01-009"], "read_ids": null},
		"integer ID": {"delivered_ids": [9]},
		"null ID": {"delivered_ids": [null]},
		"nested Array ID": {"delivered_ids": [["MSG-CH01-009"]]},
		"empty ID": {"delivered_ids": [""]},
		"blank ID": {"delivered_ids": ["   "]},
		"padded ID": {"delivered_ids": [" MSG-CH01-009"]},
		"overlong ID": {"delivered_ids": ["M".repeat(StateScript.MESSAGE_ID_MAX_LENGTH + 1)]},
		"Object ID": {"delivered_ids": [RefCounted.new()]},
		"root revision key": {"delivered_ids": ["MSG-CH01-009"], "state_revision": 9},
		"root resources key": {"resources": {"E": 99}},
		"root flags key": {"knowledge_flags": ["skip"]},
		"root phase key": {"scene_phase": "complete"},
		"nested messages record": {"messages": {"delivered_ids": ["MSG-CH01-009"]}},
		"whole presentation_resume": {"presentation_resume": {"messages": {"delivered_ids": ["MSG-CH01-009"]}}},
		"integer key": {1: ["MSG-CH01-009"]},
		"read before delivery": {"read_ids": ["MSG-CH01-404"]},
		"valid delivery with an undelivered read": {"delivered_ids": ["MSG-CH01-009"], "read_ids": ["MSG-CH01-404"]},
		"valid delivery with a bad read": {"delivered_ids": ["MSG-CH01-009"], "read_ids": [false]},
	}
	for label in cases:
		var result: Dictionary = director.update_message_metadata(cases[label])
		_check(not bool(result.accepted) and not String(result.reason).is_empty() and director.snapshot() == state and director._checkpoint == checkpoint, "reject %s atomically" % label)
	_check(director.query().state_revision == 1 and director.message_metadata() == {"delivered_ids": ["MSG-CH01-001"], "read_ids": ["MSG-CH01-001"]}, "rejections leave gameplay and the stored record exactly as they were")

func _test_missing_and_fresh_state() -> void:
	var bare := DirectorScript.new()
	_check(bare.message_metadata() == EMPTY, "a director without a campaign reads an empty record")
	_check(bool(bare.update_message_metadata({"delivered_ids": ["MSG-CH01-001"]}).accepted), "the first update creates the record")
	var director := DirectorScript.new()
	var old := StateScript.new_snapshot()
	old.presentation_resume = {"cutscene_id": "CS-CH01-01"}
	var restored: Dictionary = director.restore_snapshot(old)
	_check(bool(restored.accepted) and director.message_metadata() == EMPTY, "a snapshot written before M1-89 restores with an empty record")
	director.update_message_metadata({"delivered_ids": ["MSG-CH01-001"]})
	_check(director.snapshot().presentation_resume.cutscene_id == "CS-CH01-01", "other presentation_resume fields are kept")
	var fresh: Dictionary = director.new_campaign(ContentScript.EXPECTED_CONTENT_REVISION)
	_check(StateScript.message_metadata(fresh) == EMPTY and director.message_metadata() == EMPTY, "a fresh New starts with an empty record")
	director.restore_checkpoint()
	_check(director.message_metadata() == EMPTY, "a fresh New also clears the record from the retry checkpoint")
	var partial := StateScript.new_snapshot()
	partial.presentation_resume = {"messages": {"delivered_ids": ["MSG-CH01-001"]}}
	_check(bool(director.restore_snapshot(partial).accepted) and director.message_metadata() == {"delivered_ids": ["MSG-CH01-001"], "read_ids": []}, "a stored record without read_ids reads it as empty")

func _test_restore_validates_the_record() -> void:
	var director := DirectorScript.new()
	director.update_message_metadata({"delivered_ids": ["MSG-CH01-001"]})
	var state: Dictionary = director.snapshot()
	var records := {
		"non-Dictionary record": "MSG-CH01-001",
		"unknown field": {"delivered_ids": [], "toasts": []},
		"repeated delivery": {"delivered_ids": ["MSG-CH01-001", "MSG-CH01-001"], "read_ids": []},
		"read without delivery": {"delivered_ids": [], "read_ids": ["MSG-CH01-001"]},
		"non-String ID": {"delivered_ids": [1], "read_ids": []},
	}
	for label in records:
		var invalid := StateScript.new_snapshot()
		invalid.presentation_resume = {"messages": records[label]}
		var result: Dictionary = director.restore_snapshot(invalid)
		_check(not bool(result.accepted) and director.snapshot() == state and not bool(StateScript.validate_snapshot(invalid).valid), "restore rejects a %s and keeps the live state" % label)

func _test_save_round_trip_and_old_saves() -> void:
	var path := OS.get_temp_dir().path_join("lla-m189-%d-%d.json" % [OS.get_process_id(), Time.get_ticks_usec()])
	var service := SaveScript.new()
	service.session_validator = CampaignScript.restore_session
	service.clear(path)
	var director := DirectorScript.new()
	director.new_campaign(ContentScript.EXPECTED_CONTENT_REVISION)
	var route := RouteScript.new(director)
	var old_save := _campaign_save(director, route)
	_check(bool(service.save(old_save, path).accepted), "a campaign save without a messages record writes")
	var old_load: Dictionary = service.load(path)
	var old_session: Dictionary = CampaignScript.restore_session(old_load.get("snapshot", {}))
	_check(bool(old_load.get("accepted", false)) and bool(old_session.get("accepted", false)) and old_session.director.message_metadata() == EMPTY, "an old save loads and resumes with an empty record")
	var record := {"delivered_ids": ["MSG-CH01-001", "MSG-CH01-002"], "read_ids": ["MSG-CH01-002"]}
	director.update_message_metadata(record)
	var saved: Dictionary = service.save(_campaign_save(director, route), path)
	var loaded: Dictionary = service.load(path)
	_check(bool(saved.get("accepted", false)) and bool(loaded.get("accepted", false)) and loaded.snapshot.presentation_resume.messages == record, "the record survives a JSON save and load exactly")
	var session: Dictionary = CampaignScript.restore_session(loaded.snapshot)
	var saved_state: Dictionary = loaded.snapshot.duplicate(true)
	saved_state.erase("route_runtime")
	_check(bool(session.get("accepted", false)) and session.director.message_metadata() == record and session.director.snapshot() == saved_state, "a resumed session restores the record and the same gameplay state")
	var resumed: Dictionary = session.director.update_message_metadata({"read_ids": ["MSG-CH01-001"]})
	_check(bool(resumed.accepted) and session.director.message_metadata().read_ids == ["MSG-CH01-002", "MSG-CH01-001"], "updates continue after a load")
	var v2 := _campaign_save(director, route)
	v2.schema_version = 2
	v2.erase("story_log")
	v2.presentation_resume = {}
	_write_text(path, JSON.stringify(v2))
	var migrated: Dictionary = service.load(path)
	_check(bool(migrated.get("accepted", false)) and bool(migrated.get("migrated", false)) and StateScript.message_metadata(migrated.snapshot) == EMPTY, "a schema 2 save migrates with an empty record")
	var tampered := _campaign_save(director, route)
	tampered.presentation_resume.messages.read_ids.append("MSG-CH01-404")
	_check(not bool(service.save(tampered, path).get("accepted", false)), "a save whose record breaks the schema is refused before it reaches disk")
	service.clear(path)

func _test_route_retry_reapply() -> void:
	# CampaignRoute.retry() restores the director snapshot the route captured at
	# its checkpoint. The route keeps messages across that physical retry by
	# capturing the record first and re-applying it (M1-99); the union is
	# idempotent, so this holds whether or not the route already re-applies it.
	var director := DirectorScript.new()
	director.new_campaign(ContentScript.EXPECTED_CONTENT_REVISION)
	var route := RouteScript.new(director)
	var route_checkpoint: Dictionary = route._retry_checkpoint.director.duplicate(true)
	director.update_message_metadata({"delivered_ids": ["MSG-CH01-001", "MSG-CH01-002"], "read_ids": ["MSG-CH01-001"]})
	var keep: Dictionary = director.message_metadata()
	var retried: Dictionary = route.retry()
	var reapplied: Dictionary = director.update_message_metadata(keep)
	_check(bool(retried.get("accepted", false)) and bool(reapplied.accepted) and director.message_metadata() == keep, "re-applying the captured record after a route retry restores it")
	_check(_gameplay(director.snapshot()) == _gameplay(route_checkpoint) and director.query().state_revision == int(route_checkpoint.state_revision), "the re-applied record leaves the route checkpoint's gameplay state alone")
	_check(_gameplay(director._checkpoint) == _gameplay(route_checkpoint) and StateScript.message_metadata(director._checkpoint) == keep, "the director checkpoint the route retry set keeps its gameplay state and receives the record")
	var again: Dictionary = director.update_message_metadata(keep)
	_check(bool(again.accepted) and bool(again.duplicate) and again.events.is_empty(), "re-applying the same record twice is a harmless duplicate")

func _test_scene_projection_keeps_record() -> void:
	# Routes move the director between scenes with project_scene(); the inbox
	# must not lose messages at a scene join.
	var director := DirectorScript.new()
	director.new_campaign(ContentScript.EXPECTED_CONTENT_REVISION)
	var record := {"delivered_ids": ["MSG-CH01-001", "MSG-CH01-002"], "read_ids": ["MSG-CH01-001"]}
	director.update_message_metadata(record)
	var projected: Dictionary = director.project_scene("EX-CH01-S02")
	_check(bool(projected.get("accepted", false)) and director.query().scene_id == "EX-CH01-S02" and director.message_metadata() == record, "a scene projection carries the record into the next scene")
	director.restore_checkpoint()
	_check(director.message_metadata() == record, "the checkpoint behind a projected scene still holds the record")

func _campaign_save(director: RefCounted, route: RefCounted) -> Dictionary:
	var snapshot: Dictionary = director.snapshot()
	snapshot["paused"] = false
	snapshot["chapter_id"] = "CH01"
	snapshot["scene_id"] = route.current_scene_id()
	snapshot["mission_id"] = route.current_mission_id()
	snapshot["route_runtime"] = route.snapshot()
	snapshot["route_runtime"]["chapter"] = 1
	return snapshot

## Everything except presentation_resume.messages.
func _gameplay(snapshot: Dictionary) -> Dictionary:
	var copy := snapshot.duplicate(true)
	var resume = copy.get("presentation_resume", {})
	if resume is Dictionary:
		resume.erase("messages")
	return copy

func _write_text(target: String, value: String) -> void:
	var file := FileAccess.open(target, FileAccess.WRITE)
	if file == null:
		_check(false, "test fixture opens " + target)
		return
	file.store_string(value)
	file.close()

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		print("  FAIL ", message)
