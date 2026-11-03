## Godot --headless --path game --script res://tools/test_campaign_later_runtime.gd
## Verifies the real production controller crosses CH02 -> CH03 and exposes a physical P-05 target.
extends SceneTree

const CampaignScene: PackedScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const Chapter2RouteScript = preload("res://scripts/missions/chapter2_route.gd")
const SaveScript = preload("res://scripts/save/save_service.gd")

var checks := 0
var failures := 0
var _campaign: Chapter1Campaign
var _original_user_dir := ""

func _init() -> void:
	_original_user_dir = OS.get_user_data_dir()
	ProjectSettings.set_setting("application/config/use_custom_user_dir", true)
	ProjectSettings.set_setting("application/config/custom_user_dir_name", "LastLightAcademy-tests/later-runtime-%d" % Time.get_ticks_usec())
	if OS.get_user_data_dir() == _original_user_dir or DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir()) != OK:
		push_error("Later runtime fixture could not isolate its save directory.")
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	var director := DirectorScript.new()
	director.new_campaign("campaign-content-1-3e003a55fa46e38f")
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
	state["route_runtime"] = route_snapshot
	_campaign = CampaignScene.instantiate() as Chapter1Campaign
	_campaign.initial_snapshot = state
	root.add_child(_campaign)
	await process_frame
	_check(_campaign.route != null and _campaign.route.current_scene_id() == "EX-CH02-S12", "production runtime restores a Chapter 2 checkpoint")
	var transition: Dictionary = _campaign.advance_scene()
	_check(bool(transition.get("accepted", false)) and _campaign.route.current_scene_id() == "EX-CH03-S01", "production controller crosses into Chapter 3")
	_check(String(_campaign.director.snapshot().get("chapter_id", "")) == "CH03" and _campaign.route.current_room_id() == "LOC-02", "Chapter 3 projection and service-room viewpoint are authoritative")
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
	var saved: Dictionary = _campaign.save_campaign()
	_check(bool(saved.get("accepted", false)), "later-chapter runtime saves a primitive route checkpoint")
	_campaign.free()
	_check(SaveScript.new().clear(), "later runtime fixture cleans its isolated save")
	DirAccess.remove_absolute(OS.get_user_data_dir())
	print("LATER CAMPAIGN RUNTIME RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)
