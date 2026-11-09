extends SceneTree

const Campaign = preload("res://scripts/campaign/chapter1_campaign.gd")
const Director = preload("res://scripts/core/campaign_director.gd")
const Content = preload("res://scripts/content/content_loader.gd")
const Route = preload("res://scripts/missions/chapter1_route.gd")
const Save = preload("res://scripts/save/save_service.gd")
const Host = preload("res://scripts/puzzles/puzzle_host.gd")
var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var unopened := Campaign.new()
	_check(unopened.has_method("update_message_metadata"), "campaign message API exists before startup")
	if unopened.has_method("update_message_metadata"):
		var unavailable: Dictionary = unopened.update_message_metadata({"delivered_ids": ["MSG-CH01-001"]})
		_check(not bool(unavailable.get("accepted", false)) and not bool(unavailable.get("persisted", true)), "unstarted expedition rejects writes safely")
		_check(unopened.message_metadata() == {"delivered_ids": [], "read_ids": []}, "unstarted expedition reports empty message metadata")
	unopened.free()
	var campaign := _fresh()
	if not campaign.has_method("update_message_metadata") or not campaign.has_method("message_metadata"):
		_check(false, "the campaign exposes bounded persisted message updates")
		campaign.free()
		_finish()
		return
	_check(campaign.message_metadata() == {"delivered_ids": [], "read_ids": []}, "fresh New has no delivered/read messages")
	var checkpoint: Dictionary = campaign.route._retry_checkpoint.director.duplicate(true)
	var host := Host.new()
	host.bind(campaign.director, "P-02", "EX-M0102", "EX-CH01-S05")
	var plan := {"shifts": [{"heat": "DAY", "air_production": 2, "light": "FULL", "transfer": "HOLD"}]}
	_check(bool(host.preview(plan).get("accepted", false)), "real gameplay preview before reading")
	var messages := {"delivered_ids": ["MSG-CH01-001", "MSG-CH01-002"], "read_ids": ["MSG-CH01-001"]}
	var result: Dictionary = campaign.update_message_metadata(messages)
	_check(bool(result.get("accepted", false)) and bool(result.get("persisted", false)), "accepted metadata update uses the existing save store")
	_check(_gameplay(campaign.director.snapshot()) == _gameplay(checkpoint), "delivery/read changes no gameplay or pre-message revision")
	_check(_gameplay(campaign.director._checkpoint) == _gameplay(checkpoint), "delivery/read does not move the gameplay checkpoint")
	var loaded: Dictionary = campaign.save_service.load(campaign.save_path)
	var continued: Dictionary = Campaign.restore_session(loaded.get("snapshot", {}))
	_check(bool(continued.get("accepted", false)) and continued.director.message_metadata() == messages, "real JSON save and Continue retain delivery/read state")
	var copy: Dictionary = campaign.message_metadata()
	copy.read_ids.append("MSG-CH01-002")
	_check(campaign.message_metadata() == messages, "public query returns a copy")
	var bytes := FileAccess.get_file_as_bytes(campaign.save_path)
	var state: Dictionary = campaign.director.snapshot()
	for bad in [{"resources": {}}, {"read_ids": ["MSG-UNKNOWN"]}, {"delivered_ids": 4}]:
		var rejected: Dictionary = campaign.update_message_metadata(bad)
		_check(not bool(rejected.get("accepted", false)) and campaign.director.snapshot() == state, "malformed update is rejected atomically")
		_check(FileAccess.get_file_as_bytes(campaign.save_path) == bytes, "rejected update never writes a save")
	campaign.route.pause("inbox")
	var read: Dictionary = campaign.update_message_metadata({"read_ids": ["MSG-CH01-002"]})
	_check(bool(read.get("persisted", false)) and bool(campaign.director.query().paused), "reading while paused saves without resuming gameplay")
	_check(not bool(campaign.save_service.load(campaign.save_path).snapshot.paused), "saved checkpoint resumes playable")
	campaign.route.resume()
	_check(bool(host.commit("message-preview-shift", plan).get("accepted", false)), "preview from before messages remains committable")
	_check(bool(campaign.route.retry().get("accepted", false)) and _gameplay(campaign.director.snapshot()) == _gameplay(checkpoint), "route retry restores the original gameplay checkpoint")
	_check(campaign.message_metadata().read_ids == ["MSG-CH01-001", "MSG-CH01-002"], "read metadata survives retry")
	var stable: Dictionary = campaign.director.snapshot()
	var duplicate: Dictionary = campaign.update_message_metadata({"read_ids": ["MSG-CH01-002"]})
	_check(bool(duplicate.get("duplicate", false)) and bool(duplicate.get("persisted", false)) and campaign.director.snapshot() == stable, "duplicate metadata remains idempotent and safely saves")
	DirAccess.make_dir_absolute(campaign.save_path + ".tmp")
	print("EXPECTED SAVE WARNING: real blocked temporary save")
	var failed: Dictionary = campaign.update_message_metadata({"delivered_ids": ["MSG-CH01-003"]})
	_check(bool(failed.get("accepted", false)) and not bool(failed.get("persisted", true)) and not String(failed.get("reason", "")).is_empty(), "failed disk write reports accepted in-memory update but not persisted")
	_check(campaign.message_metadata().delivered_ids.has("MSG-CH01-003") and campaign.save_service.load(campaign.save_path).snapshot.presentation_resume.messages.delivered_ids == ["MSG-CH01-001", "MSG-CH01-002"], "failed save retains live metadata and the previous disk checkpoint")
	DirAccess.remove_absolute(campaign.save_path + ".tmp")
	var recovered: Dictionary = campaign.update_message_metadata({"delivered_ids": ["MSG-CH01-003"]})
	_check(bool(recovered.get("duplicate", false)) and bool(recovered.get("persisted", false)), "repeating an update retries a failed write")
	var old: Dictionary = campaign._save_snapshot()
	old.get("presentation_resume", {}).erase("messages")
	_check(bool(campaign.save_service.save(old, campaign.save_path).get("accepted", false)), "legacy checkpoint with no message metadata remains valid")
	var legacy: Dictionary = Campaign.restore_session(campaign.save_service.load(campaign.save_path).snapshot)
	_check(bool(legacy.get("accepted", false)) and legacy.director.message_metadata() == {"delivered_ids": [], "read_ids": []}, "legacy Continue returns empty messages")
	campaign.save_service.clear(campaign.save_path)
	campaign.free()
	var fresh := _fresh()
	_check(fresh.message_metadata() == {"delivered_ids": [], "read_ids": []}, "fresh New resets the previous expedition's messages")
	fresh.free()
	_finish()

func _fresh() -> Chapter1Campaign:
	var campaign := Campaign.new()
	campaign.director = Director.new()
	campaign.director.new_campaign(Content.EXPECTED_CONTENT_REVISION)
	campaign.route = Route.new(campaign.director)
	campaign.save_service = Save.new()
	campaign.save_service.session_validator = Campaign.restore_session
	campaign.save_path = OS.get_temp_dir().path_join("lla-message-%d-%d.json" % [OS.get_process_id(), Time.get_ticks_usec()])
	return campaign

func _gameplay(snapshot: Dictionary) -> Dictionary:
	var copy := snapshot.duplicate(true)
	copy.get("presentation_resume", {}).erase("messages")
	return copy

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func _finish() -> void:
	print("CAMPAIGN MESSAGES RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)
