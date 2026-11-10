## M3-3P: Chapter 3 puzzles are real panels in the production campaign: real
## nearby USE opens the P-05 panel, nothing commits without the player's choice,
## a held choice is refused, and the supported choice locks in once.
## Run with `-- --capture` in a window to save the screen.
extends SceneTree

const CampaignScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const RouteScript = preload("res://scripts/missions/extended_campaign_route.gd")
var storage = preload("res://tools/support/isolated_storage.gd").new()
var checks := 0
var failures := 0

func _init() -> void:
	CampaignCutscenePlayer.autoplay = false
	if not storage.setup("chapter3_panel_wiring"):
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var director := DirectorScript.new()
	director.new_campaign(CampaignContentFull.EXPECTED_CONTENT_REVISION)
	var route := RouteScript.new(director)
	_check(bool(route.start_at("EX-CH03-S01").get("accepted", false)), "fixture projects into Chapter 3")
	var state: Dictionary = director.snapshot()
	state["route_runtime"] = route.snapshot()
	state.route_runtime["chapter"] = 3
	var campaign := CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	campaign.initial_snapshot = state
	root.add_child(campaign)
	await process_frame
	await process_frame
	var hud: Control = campaign.hud
	_check(campaign.route != null and campaign.route.current_scene_id() == "EX-CH03-S01" and hud != null and hud.chapter3_panel != null, "production campaign opens EX-CH03-S01 with a Chapter 3 panel")
	var id := "p05_equip_gauge"
	var target: Node3D = campaign.physical_target(id)
	_check(target != null, "the P-05 gauge is a physical target")
	if target == null:
		_finish(campaign)
		return
	var approach: Array = target.get_meta("approach_m", [])
	campaign._player.global_position = campaign._room.to_global(Vector3(float(approach[0]), float(approach[1]), float(approach[2]))) if approach.size() == 3 else target.global_position + Vector3(0, 0, 1)
	campaign._player.velocity = Vector3.ZERO
	await physics_frame
	campaign._player.follow_camera.camera.look_at(target.global_position)
	_check(campaign.nearby_target().get("target_id", "") == id, "the gauge is the nearby target")
	var before: Dictionary = campaign.director.snapshot()
	var opened: Dictionary = campaign.interact_nearby()
	await process_frame
	_check(bool(opened.get("chapter3_panel", false)) and hud.chapter3_panel.is_open() and hud.chapter3_panel.target_id() == id, "real nearby USE opens the P-05 decision panel")
	_check(campaign.director.snapshot().receipts == before.receipts and not bool(campaign.route.current_flags().get("p05_equip_gauge_done", false)), "opening the panel commits nothing")
	var panel: Chapter3PuzzlePanel = hud.chapter3_panel
	_check(not panel.request_commit().get("accepted", false), "locking in without a choice is refused")
	_check(campaign.director.snapshot().receipts == before.receipts, "the refused lock-in changes nothing")
	_check(bool(panel.choose("option", "held").get("accepted", false)), "the player can pick the unsupported option")
	var held: Dictionary = panel.try_it()
	_check(not bool(held.get("accepted", false)) or not bool(campaign.route.current_flags().get("p05_equip_gauge_done", false)), "trying the unsupported option does not complete the step")
	_check(not bool(campaign.route.current_flags().get("p05_equip_gauge_done", false)), "the held choice committed nothing")
	_check(bool(panel.choose("option", "supported").get("accepted", false)), "the player picks the supported option")
	var tried: Dictionary = panel.try_it()
	_check(bool(tried.get("accepted", false)), "the supported choice previews as accepted")
	_check(not bool(campaign.route.current_flags().get("p05_equip_gauge_done", false)), "the preview is read only")
	if OS.get_cmdline_user_args().has("--capture") and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/M3-3P_chapter3_panel.png"))
	var requested: Dictionary = panel.request_commit()
	_check(bool(requested.get("accepted", false)), "lock-in asks for confirmation")
	var confirmed: Dictionary = panel.confirm_commit()
	await process_frame
	_check(bool(confirmed.get("accepted", false)) and bool(campaign.route.current_flags().get("p05_equip_gauge_done", false)), "the confirmed supported choice commits the step")
	_check(campaign.director.snapshot().receipts.size() == before.receipts.size() + 1, "exactly one receipt is charged")
	_finish(campaign)

func _finish(campaign: Node) -> void:
	campaign.free()
	storage.cleanup()
	print("CHAPTER 3 PANEL WIRING RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)
