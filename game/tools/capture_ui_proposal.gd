extends SceneTree

var storage = preload("res://tools/support/isolated_storage.gd").new()
var captures := 0
var failures := 0

func _init() -> void:
	CampaignCutscenePlayer.autoplay = false
	call_deferred("_run")

func _run() -> void:
	if not storage.setup("ui-proposal-captures") or not storage.prepare_rendering_cache():
		quit(1)
		return
	for path in ["res://assets/ui/title/aurora_cinematic.png", "res://assets/ui/branding/aurora_mark.svg", "res://assets/ui/proposal/probe_setup.png", "res://assets/ui/proposal/practice_atlas.png"]:
		var texture := load(path) as Texture2D
		assert(texture != null and texture.get_width() > 0 and texture.get_height() > 0 and maxi(texture.get_width(), texture.get_height()) <= 2048, "UI asset import and texture budget")
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	var menu: MainMenu = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	menu.setup({})
	await _shot("01_title")
	menu.set_accessibility({"large_text": true})
	await _shot("01_title_large")
	menu.set_accessibility({"large_text": false})
	menu.open_settings()
	menu._settings_menu.show_tab("assist")
	await _shot("04_settings")
	menu._settings_menu.game_settings.set_accessibility_option("large_text", true, false)
	menu._settings_menu.show_tab("assist")
	await _shot("04_settings_large")
	menu._close_settings()
	menu.free()
	await process_frame
	var chapters = load("res://scripts/ui/chapter_select.gd").new()
	chapters.save_path = storage.path
	root.add_child(chapters)
	await _shot("13_chapters")
	chapters.settings.large_text = true
	chapters.show_tab("chapters")
	await _shot("13_chapters_large")
	chapters.free()
	var trainer = load("res://scripts/trainer/mission_trainer.gd").new()
	trainer.results_path = storage.directory.path_join("trainer.json")
	root.add_child(trainer)
	await _shot("14_trainer")
	trainer.settings.large_text = true
	trainer.show_catalog()
	await _shot("14_trainer_large")
	trainer.free()
	var moon := MoonTrainer.new()
	moon.results_path = storage.directory.path_join("moon.json")
	root.add_child(moon)
	while not moon.field_ready:
		await process_frame
	await _shot("14_moon_trainer")
	moon.free()
	var campaign: Chapter1Campaign = load("res://scenes/campaign/chapter1_campaign.tscn").instantiate()
	storage.configure(campaign)
	root.add_child(campaign)
	await campaign.wait_loading()
	for frame in 6:
		await physics_frame
	campaign.hud.panels.hint_player.close()
	await _shot("05_campaign_hud")
	campaign.hud.panels.open_panel("journal_discovery")
	campaign.hud.panels.select_journal_tab("science")
	await _shot("08_journal_science")
	campaign.hud.panels.close_panel()
	campaign.hud.open_messages()
	await _shot("11_comms")
	campaign.hud.comms_panel.close_inbox()
	if campaign.hud.open_family("greenhouse"):
		await _shot("09_greenhouse")
		campaign.hud.close_family()
	else:
		failures += 1
	var inputs = load("res://tools/support/p01_input_fixture.gd")
	var gates = load("res://scripts/missions/chapter1_gate_catalog.gd")
	while campaign.route.current_scene_id() != "EX-CH01-S03":
		for spec in gates.targets_for_scene(campaign.route.current_scene_id()):
			var result: Dictionary = campaign.route.perform(String(spec.target_id), inputs.payload(String(spec.target_id)))
			assert(result.get("accepted", false), "campaign capture prerequisite must succeed")
		assert(campaign.route.advance_scene().accepted, "capture route advances through real gates")
	campaign._sync_route_projection()
	campaign._refresh_world()
	await campaign.wait_loading()
	campaign.hud.refresh_scene()
	campaign.hud.open_messages()
	campaign.hud.comms_panel.select_thread("crew")
	for message in campaign.hud.comms_service.messages_for_thread("crew"):
		if String(message.get("sender", "")) in ["Kai", "Rafi", "Amara", "Mei"]:
			campaign.hud.comms_panel.select_message(String(message.id))
			break
	assert(not campaign.hud.comms_panel._portrait_views.is_empty(), "delivered crew uses approved model portraits")
	await _shot("11_comms_crew")
	campaign.hud.comms_panel.set_text_scale(true)
	await _shot("11_comms_large")
	campaign.hud.comms_panel.close_inbox()
	assert(inputs.complete_probe_transfer(campaign.route).accepted, "probe transfer precedes calibration")
	assert(campaign.hud.p01_panel.open(campaign, "calibrate_probe"), "calibration uses real campaign view")
	campaign.hud.panels.hint_player.close()
	campaign.hud.p01_panel.choose("reference", "dry")
	campaign.hud.p01_panel.choose("raw_reading", 10)
	campaign.hud.p01_panel.choose("calibrated_reading", 0)
	campaign.hud.p01_panel._render()
	await _shot("07_calibration")
	campaign.hud.p01_panel.preview()
	await _shot("07_calibration_prediction")
	campaign.hud.p01_panel.discard()
	campaign.hud.panels.open_panel("pause")
	await _shot("15_pause")
	campaign.hud.panels.close_panel()
	campaign.hud.hide()
	var route := Chapter1Route.new(CampaignDirector.new())
	route.start_at("EX-CH01-S07")
	var table: MissionTablePanel = load("res://scenes/ui/mission_table_panel.tscn").instantiate()
	root.add_child(table)
	table.open(route, "p02_shift1")
	await _shot("06_mission_table")
	table.close()
	table.free()
	assert(await campaign.preparation.wait_idle(), "capture owns its look-ahead until drained")
	campaign.free()
	await process_frame
	print("UI PROPOSAL CAPTURE RESULT: %s (%d captures, %d failures)" % ["PASS" if failures == 0 else "FAIL", captures, failures])
	storage.cleanup()
	quit(0 if failures == 0 else 1)

func _shot(name: String) -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	for frame in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://../production/qa/evidence/M4-22/" + name + ".png")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if image.save_png(path) != OK:
		failures += 1
	else:
		captures += 1
