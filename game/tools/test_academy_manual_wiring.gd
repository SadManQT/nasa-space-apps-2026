## M3-69: the curriculum is part of the real game: the pause menu and the Journal
## open the Academy Manual, a chapter end shows "What you learned" and then the
## upgrade choice, and the cadet record lists the twelve competencies.
## Run with `-- --capture` in a window to save the screens.
extends SceneTree

const CampaignScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const RouteScript = preload("res://scripts/missions/chapter2_route.gd")
var storage = preload("res://tools/support/isolated_storage.gd").new()
var checks := 0
var failures := 0
var capture := false

func _init() -> void:
	CampaignCutscenePlayer.autoplay = false
	capture = OS.get_cmdline_user_args().has("--capture") and DisplayServer.get_name() != "headless"
	if not storage.setup("academy_manual_wiring"):
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var director := DirectorScript.new()
	director.new_campaign(CampaignContentFull.EXPECTED_CONTENT_REVISION)
	var route := RouteScript.new(director)
	_check(bool(route.start_at("EX-CH02-S01").get("accepted", false)), "fixture projects into Chapter 2 with Chapter 1 complete")
	var state: Dictionary = director.snapshot()
	var done: Array = state.get("completed_scene_ids", []).duplicate()
	for n in range(1, 13):
		var id := "EX-CH01-S%02d" % n
		if not done.has(id):
			done.append(id)
	state["completed_scene_ids"] = done
	state["route_runtime"] = route.snapshot()
	state.route_runtime["chapter"] = 2
	_check(state.get("completed_scene_ids", []).has("EX-CH01-S12"), "Chapter 1 is complete in the snapshot")
	var campaign := CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	campaign.initial_snapshot = state
	root.add_child(campaign)
	await process_frame
	await process_frame
	var hud: Control = campaign.hud
	_check(hud != null and hud.panels != null, "production campaign HUD is up")
	_check(hud.panels.JOURNAL_TABS.any(func(tab): return tab.id == "manual"), "the Journal has a Manual tab")
	hud.panels.open_journal("manual")
	await process_frame
	var open_button := hud.panels._body.find_child("OpenAcademyManual", true, false) as Button
	_check(open_button != null, "the Manual tab offers the Academy Manual")
	if open_button != null:
		open_button.pressed.emit()
		await process_frame
		await process_frame
	var manual := hud._family_panel as Control
	_check(manual != null and manual.name == "AcademyManual", "the Journal button opens the Academy Manual")
	_check(manual != null and manual.current_page().get("kind", "") == "index", "it opens on the index of twelve competencies")
	await _shot("M3-69_manual_index.png")
	hud.close_family()
	await process_frame
	# The pause menu lists it, too.
	var listed := false
	for action in hud.panels._pause_actions:
		if String(action.get("name", "")) == "Open_manual":
			listed = true
	_check(listed, "the pause menu lists the Academy Manual")
	# Chapter end: "What you learned" first, then the upgrade choice.
	_check(hud.open_chapter_learning(1, 1), "a completed chapter opens its What you learned page")
	await process_frame
	await process_frame
	var learned := hud._family_panel as Control
	_check(learned != null and learned.name == "AcademyManual" and learned.current_page().get("kind", "") == "chapter", "the chapter page is shown")
	await _shot("M3-69_what_you_learned_ch01.png")
	hud.close_family()
	for i in 4:
		await process_frame
	_check(is_instance_valid(hud._family_panel) and hud._family_panel.name != "AcademyManual" and hud._family_panel.get("active_tab") == "upgrades", "closing the page opens the Chapter 1 upgrade choice")
	hud.close_family()
	await process_frame
	_check(not hud.open_chapter_learning(5, 0), "a chapter that is not complete has no What you learned page")
	_check(hud._family_panel == null, "no panel is left open after a refused page")
	# The cadet record lists the competencies.
	_check(hud.open_family("cadet_record"), "the cadet record opens")
	hud._family_panel.call("open_tab", "learning")
	await process_frame
	await process_frame
	var rows: int = hud._family_panel._body.get_child_count()
	_check(rows == 12, "the Learning tab lists the twelve competencies (%d)" % rows)
	await _shot("M3-69_cadet_record_learning.png")
	hud.close_family()
	campaign.free()
	await process_frame
	storage.cleanup()
	print("ACADEMY MANUAL WIRING RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _shot(file: String) -> void:
	if capture:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/" + file))

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)
