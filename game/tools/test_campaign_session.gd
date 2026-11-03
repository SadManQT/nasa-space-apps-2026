## Godot --headless --path game --script res://tools/test_campaign_session.gd
## Production-session smoke: boot, enter, act, save, restore, resume.
extends SceneTree

const SaveScript = preload("res://scripts/save/save_service.gd")
const MainScene: PackedScene = preload("res://scenes/main.tscn")
const CampaignScene: PackedScene = preload("res://scenes/campaign/chapter1_campaign.tscn")

var checks := 0
var failures := 0
var _root: Node
var _original_user_dir := ""

func _init() -> void:
	_original_user_dir = OS.get_user_data_dir()
	ProjectSettings.set_setting("application/config/use_custom_user_dir", true)
	ProjectSettings.set_setting("application/config/custom_user_dir_name", "LastLightAcademy-tests/session-%d" % Time.get_ticks_usec())
	if OS.get_user_data_dir() == _original_user_dir or DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir()) != OK:
		push_error("Session test could not isolate its save directory.")
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	_check(OS.get_user_data_dir() != _original_user_dir, "session fixture cannot overwrite player saves")
	var save = SaveScript.new()
	save.clear()
	_root = MainScene.instantiate()
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
	var saved: Dictionary = campaign.save_campaign() if campaign != null else {}
	var saved_snapshot: Dictionary = saved.get("snapshot", {}) if saved.get("snapshot", {}) is Dictionary else {}
	_check(bool(saved.get("accepted", false)) and not saved_snapshot.is_empty(), "session saves a validated campaign checkpoint")
	var restored := CampaignScene.instantiate() as Chapter1Campaign
	restored.initial_snapshot = saved_snapshot
	root.add_child(restored)
	await process_frame
	_check(restored.route != null and restored.route.current_scene_id() == "EX-CH01-S01" and bool(restored.route.gate_status().get("physical_flags", {}).get("commission_route_confirmed", false)), "continue restore resumes the same scene and physical evidence")
	_finish(save, restored)

func _finish(save: RefCounted, restored: Node = null) -> void:
	if is_instance_valid(_root):
		_root.free()
	if is_instance_valid(restored):
		restored.free()
	_check(save.clear(), "session fixture cleans its isolated save files")
	DirAccess.remove_absolute(OS.get_user_data_dir())
	print("CAMPAIGN SESSION RESULT: %s (%d/%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks - failures, checks, failures])
	quit(0 if failures == 0 else 1)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)
