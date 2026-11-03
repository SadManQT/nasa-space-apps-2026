## Godot --headless --path game --script res://tools/test_campaign_session.gd
## Production-session smoke: boot, enter, act, save, restore, resume.
extends SceneTree

const SaveScript = preload("res://scripts/save/save_service.gd")
const MainScene: PackedScene = preload("res://scenes/main.tscn")
const CampaignScene: PackedScene = preload("res://scenes/campaign/chapter1_campaign.tscn")

var storage = preload("res://tools/support/isolated_storage.gd").new()

var checks := 0
var failures := 0
var _root: Node
var _original_user_dir := ""

func _init() -> void:
	if not storage.setup("test_campaign_session"):
		push_error("Unable to isolate test storage.")
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	_check(OS.get_user_data_dir() != storage.original_user_dir, "session fixture cannot overwrite player saves")
	var save = SaveScript.new()
	save.clear(storage.path)
	_root = MainScene.instantiate()
	storage.configure(_root)
	root.add_child(_root)
	await process_frame
	_check(_root.get_node_or_null("TitleLayer/MainMenu") != null, "production boot presents the title menu")
	_root.call("_launch_campaign", {})
	await process_frame
	var campaign := _root.get_node_or_null("Chapter1Campaign") as Chapter1Campaign
	_check(campaign != null and campaign.route != null and campaign.route.current_scene_id() == "EX-CH01-S01", "new expedition enters the canonical Chapter 1 opening scene")
	_check(campaign != null and campaign.hud != null and campaign.hud.panels != null, "campaign session builds the accessible HUD and panel layer")
	if campaign == null or campaign.route == null or campaign.hud == null:
		_finish(save)
		return
	var target := campaign.physical_target("commission_route")
	if target != null:
		campaign._player.global_position = Vector3(target.global_position.x, 0.0, target.global_position.z + 1.0)
	await physics_frame
	var action: Dictionary = campaign.perform_target("commission_route") if campaign != null else {}
	_check(bool(action.get("accepted", false)) and bool(campaign.route.gate_status().get("physical_flags", {}).get("commission_route_confirmed", false)), "first physical operation commits through the authoritative route")
	campaign.hud._on_next_line()
	campaign.hud._on_next_line()
	var saved: Dictionary = save.load(storage.path)
	_check(bool(saved.get("accepted", false)) and saved.snapshot.acknowledged_line_ids.size() == 2, "B20 acknowledgements autosave immediately without a manual save")
	var saved_snapshot: Dictionary = saved.get("snapshot", {}) if saved.get("snapshot", {}) is Dictionary else {}
	_check(bool(saved.get("accepted", false)) and not saved_snapshot.is_empty(), "session saves a validated campaign checkpoint")
	var restored := CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(restored)
	restored.initial_snapshot = saved_snapshot
	root.add_child(restored)
	await process_frame
	_check(restored.route != null and restored.route.current_scene_id() == "EX-CH01-S01" and bool(restored.route.gate_status().get("physical_flags", {}).get("commission_route_confirmed", false)), "continue restore resumes the same scene and physical evidence")
	_check(restored.hud._dialogue_index == 2 and restored.hud._caption_line.text == String(restored.current_dialogue()[2].text), "B20 continued HUD resumes at the first unacknowledged line")
	var exited: Array = []
	restored.exit_requested.connect(func() -> void: exited.append(true))
	restored.save_path = storage.directory.path_join("missing/slot.json")
	restored.hud._on_next_line()
	_check(restored.hud._status.text.contains("AUTOSAVE FAILED"), "B17 failed acknowledgement autosave stays visible in the HUD")
	restored.exit_to_title()
	_check(exited.is_empty() and restored.hud._status.text.contains("SAVE FAILED"), "B17 failed exit-save retains the live session and explains retry/discard")
	restored.exit_to_title()
	_check(exited.size() == 1, "B17 explicit second TITLE request discards only after the failure notice")
	restored.save_path = storage.path
	_check(bool(restored.save_campaign().get("accepted", false)) and not restored._exit_without_save_armed, "B17 successful retry saves the still-live session and clears discard state")
	for index in restored.current_dialogue().size():
		restored.hud._on_next_line()
	var all_acknowledged: Dictionary = save.load(storage.path)
	var complete := CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(complete)
	complete.initial_snapshot = all_acknowledged.get("snapshot", {})
	root.add_child(complete)
	await process_frame
	_check(complete.hud._next_line.disabled and complete.hud._dialogue_index == complete.current_dialogue().size(), "B20 completed dialogue remains complete after another disk restore")
	complete.free()
	_finish(save, restored)

func _finish(save: RefCounted, restored: Node = null) -> void:
	if is_instance_valid(_root):
		_root.free()
	if is_instance_valid(restored):
		restored.free()
	_check(save.clear(storage.path), "session fixture cleans its isolated save files")
	storage.cleanup()
	print("CAMPAIGN SESSION RESULT: %s (%d/%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks - failures, checks, failures])
	quit(0 if failures == 0 else 1)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)
