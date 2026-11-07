## Godot --headless --path game --script res://tools/test_campaign_later_runtime.gd
## Verifies the real production controller crosses CH02 -> CH03 and exposes a physical P-05 target.
extends SceneTree

const CampaignScene: PackedScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const Chapter2RouteScript = preload("res://scripts/missions/chapter2_route.gd")
const SaveScript = preload("res://scripts/save/save_service.gd")

var storage = preload("res://tools/support/isolated_storage.gd").new()

var checks := 0
var failures := 0
var _campaign: Chapter1Campaign
var _original_user_dir := ""

func _init() -> void:
	if not storage.setup("test_campaign_later_runtime"):
		push_error("Unable to isolate test storage.")
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	var director := DirectorScript.new()
	director.new_campaign(CampaignContentFull.EXPECTED_CONTENT_REVISION)
	var route := Chapter2RouteScript.new(director)
	route.start_at("EX-CH02-S12")
	var route_snapshot: Dictionary = route.snapshot()
	route_snapshot["completed_scene_ids"] = ["EX-CH02-S12"]
	var state: Dictionary = director.snapshot()
	state["chapter1_ready"] = true
	state["chapter_id"] = "CH02"
	state["mission_id"] = "EX-M0204"
	state["scene_id"] = "EX-CH02-S12"
	state["completed_scene_ids"] = ["EX-CH02-S12"]
	state["scenario_datetime"] = "2046-05-06 18:00 UTC"
	state.story_log.choices["EX-CH02-S10-CHOICE"] = {
		"option_id": "EX-CH02-S10-OPT02", "scene_id": "EX-CH02-S10",
		"scenario_datetime": "2046-05-06 18:00 UTC", "state_revision": state.state_revision,
	}
	state["route_runtime"] = route_snapshot
	_campaign = CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(_campaign)
	_campaign.initial_snapshot = state
	root.add_child(_campaign)
	await process_frame
	_check(_campaign.route != null and _campaign.route.current_scene_id() == "EX-CH02-S12", "production runtime restores a Chapter 2 checkpoint")
	_test_panels()
	var transition: Dictionary = _campaign.advance_scene()
	_check(bool(transition.get("accepted", false)) and _campaign.route.current_scene_id() == "EX-CH03-S01", "production controller crosses into Chapter 3")
	_check(String(_campaign.director.snapshot().get("chapter_id", "")) == "CH03" and _campaign.route.current_room_id() == "LOC-02", "Chapter 3 projection and service-room viewpoint are authoritative")
	var voice_card := _campaign._room.visual_root.get_node_or_null("ChapterStaging/card_voice_text") as Label3D
	_check(voice_card != null and voice_card.text.contains("KEPT AS AN INFERENCE"), "the production room restores the player's recorded voice classification across the chapter join")
	var target: Node3D = _campaign.physical_target("p05_equip_gauge")
	_check(target != null, "Chapter 3 exposes a physical P-05 gauge target")
	if target != null:
		_campaign._player.global_position = target.global_position + Vector3(0.0, -target.global_position.y, 1.0)
		_campaign._player.velocity = Vector3.ZERO
		await physics_frame
		var operation: Dictionary = _campaign.perform_target("p05_equip_gauge")
		_check(bool(operation.get("accepted", false)) and bool(_campaign.route.current_flags().get("p05_equip_gauge_done", false)), "P-05 operation commits through the production physical interaction")
	else:
		_check(false, "P-05 operation commits through the production physical interaction")
	for chapter in range(3, 9):
		if chapter > 3:
			_check(bool(_campaign._start_extended("EX-CH%02d-S01" % chapter).get("accepted", false)), "later panel fixture enters chapter %d" % chapter)
		_test_panels()
	var saved: Dictionary = _campaign.save_campaign()
	if not saved.get("accepted", false):
		print("LATER SAVE DETAIL ", saved.get("reason", ""), " ", _invalid_path(_campaign._save_snapshot()))
	_check(bool(saved.get("accepted", false)), "later-chapter runtime saves a primitive route checkpoint")
	_campaign.free()
	_check(SaveScript.new().clear(storage.path), "later runtime fixture cleans its isolated save")
	storage.cleanup()
	print("LATER CAMPAIGN RUNTIME RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)

func _test_panels() -> void:
	var chapter: String = _campaign.director.query().chapter_id
	for panel_id in ["journal_discovery", "pause", "settings_accessibility"]:
		_campaign.hud.panels.open_panel(panel_id, {})
		_check(_campaign.director.query().paused and _campaign._player.process_mode == Node.PROCESS_MODE_DISABLED, "B04 " + chapter + " pauses for " + panel_id)
		_campaign.hud.panels.close_panel()
		_check(not _campaign.director.query().paused and _campaign._player.process_mode == Node.PROCESS_MODE_INHERIT, "B04 " + chapter + " resumes after " + panel_id)
	if not _campaign.is_chapter_complete():
		_check(not _campaign.hud._retry.disabled, "B05 later chapter HUD exposes its persisted retry checkpoint")

func _invalid_path(value, path: String = "$", depth: int = 0) -> String:
	if depth > 64:
		return path + " too deep"
	if value is Dictionary:
		for key in value:
			if not key is String:
				return path + "." + str(key) + " key type=" + str(typeof(key))
			var invalid := _invalid_path(value[key], path + "." + key, depth + 1)
			if not invalid.is_empty():
				return invalid
	elif value is Array:
		for index in value.size():
			var invalid := _invalid_path(value[index], path + "[" + str(index) + "]", depth + 1)
			if not invalid.is_empty():
				return invalid
	elif typeof(value) not in [TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING]:
		return path + " type=" + str(typeof(value))
	return ""
