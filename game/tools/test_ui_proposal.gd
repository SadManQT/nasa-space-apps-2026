extends SceneTree

var storage = preload("res://tools/support/isolated_storage.gd").new()
var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_check(storage.setup("ui-proposal"), "test preferences and save slots are isolated")
	_check(storage.prepare_rendering_cache(), "isolated user directory exists before persistent settings writes")
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	for path in ["ui/main_menu", "ui/settings_menu", "ui/chapter_select/chapter_select", "ui/mission_table_panel", "ui/p01_panel", "ui/greenhouse_panel", "ui/campaign_panels", "ui/chapter1_campaign_hud", "trainer/mission_trainer", "trainer/moon_trainer"]:
		var scene := load("res://scenes/" + path + ".tscn") as PackedScene
		var formal := scene.instantiate() as Control
		_check(formal != null and formal.find_children("*", "Control", true, false).size() >= 5, path + " composition is visible before runtime binding")
		formal.free()
	_check(ResourceLoader.exists("res://assets/ui/title/aurora_cinematic.png"), "clean background art is packaged inside the project")
	var menu: MainMenu = load("res://scenes/ui/main_menu.tscn").instantiate()
	menu.save_path = storage.path
	root.add_child(menu)
	menu.setup({})
	menu._panels.remap_binding("use", "H")
	await process_frame
	for large in [false, true]:
		menu.set_accessibility({"large_text": large})
		await process_frame
		_check(menu._continue_button.disabled and menu._continue_button.focus_mode == Control.FOCUS_NONE, "no-save Continue is visibly unavailable and skipped by keyboard")
		for name in ["NewExpedition", "MissionTrainerEntry", "MoonTrainerEntry", "ChapterSelectEntry", "SettingsEntry", "ScienceEntry", "CreditsEntry"]:
			var button := menu.find_child(name, true, false) as Button
			button.grab_focus()
			await process_frame
			await process_frame
			_check(button.has_focus() and root.get_visible_rect().encloses(button.get_global_rect()), "keyboard reveals " + name + " at text scale " + str(large))
		var settings_entry := menu.get_node("%SettingsEntry") as Button
		settings_entry.grab_focus()
		settings_entry.pressed.emit()
		await process_frame
		var settings := menu.find_child("SettingsMenu", true, false) as SettingsMenu
		_check(settings != null and settings.is_visible_in_tree(), "title Settings opens the complete persistent settings interface")
		_check(menu._begin_button.disabled, "title actions are disabled behind Settings")
		if settings != null:
			for tab in ["display", "audio", "controls", "assist", "saves"]:
				settings.show_tab(tab)
				await process_frame
				await process_frame
				_check(settings.active_tab == tab and settings._body.get_child_count() > 0, "all existing settings remain connected: " + tab)
			settings.show_tab("controls")
			var before := int(settings.game_settings.keyboard_bindings.interact)
			(settings.find_child("RebindKey_interact", true, false) as Button).pressed.emit()
			await _escape()
			_check(settings._listening_action.is_empty() and int(settings.game_settings.keyboard_bindings.interact) == before and is_instance_valid(menu._settings_menu), "Escape cancels rebind without closing settings or changing the binding")
			if not large:
				(settings.find_child("RebindKey_interact", true, false) as Button).pressed.emit()
				await _key(KEY_F)
				_check(_interact_key(KEY_F), "full Settings remap survives its accessibility callback after a legacy H shortcut")
			settings.show_tab("assist")
			if large:
				(settings.find_child("SubtitleSize_ExtraLarge", true, false) as Button).pressed.emit()
				root.size = Vector2i(1280, 720)
				await process_frame
				await process_frame
				for id in ["CloseSettingsButton", "ResetSettingsButton"]:
					var action := settings.find_child(id, true, false) as Button
					_check(root.get_visible_rect().encloses(action.get_global_rect()), "150% settings keeps " + id + " inside720p")
			_check(_interact_key(KEY_F), "text and accessibility changes preserve the configured Use key")
			settings.show_tab("saves")
			(settings.find_child("OpenChapterSelectButton", true, false) as Button).pressed.emit()
			await process_frame
			_check(is_instance_valid(settings._chapter_select_overlay), "settings reaches the real chapter selector")
			await _escape()
			_check(not is_instance_valid(settings._chapter_select_overlay) and is_instance_valid(menu._settings_menu), "Escape returns from chapters to settings")
			await _escape()
			_check(menu._settings_menu == null and not menu._begin_button.disabled and settings_entry.has_focus(), "Escape restores title focus and button availability")
	menu.open_settings()
	var preferences := menu._settings_menu
	preferences.show_tab("assist")
	if preferences.game_settings.accessibility.captions:
		(preferences.find_child("CaptionsToggle", true, false) as Button).pressed.emit()
	(preferences.find_child("SubtitleSize_ExtraLarge", true, false) as Button).pressed.emit()
	(preferences.find_child("SessionMode_Family", true, false) as Button).pressed.emit()
	var launch := menu.accessibility_settings()
	_check(launch.get("family_mode", false) and launch.get("session_mode") == "Family" and launch.get("subtitle_scale") == 1.5, "full settings handoff retains session flags and exact subtitle scale")
	menu.free()
	print("UI PROPOSAL PHASE: reload the actual app and launch with saved preferences")
	var main = load("res://scenes/main.tscn").instantiate()
	storage.configure(main)
	root.add_child(main)
	while not main.title_ready:
		await process_frame
	var restored: MainMenu = main.get("_menu")
	_check(not restored.captions_visible() and restored.text_scale() == 1.5, "restarting restores title preferences before opening Settings")
	_check(restored.accessibility_settings().get("family_mode", false) and _interact_key(KEY_F), "restarting retains Family mode and full keyboard remapping")
	await main._launch_campaign({})
	var campaign: Chapter1Campaign = main.get("_campaign")
	await campaign.wait_loading()
	var active: Dictionary = campaign.query().get("accessibility", {})
	_check(active.get("family_mode", false) and not active.get("captions", true) and active.get("subtitle_scale") == 1.5, "actual campaign receives all configured preferences")
	_check(_interact_key(KEY_F), "fresh campaign panels never restore the stale legacy H shortcut over F")
	_check(campaign.hud._prompt_key.text == "F", "in-world Use hint displays the configured key")
	main.free()
	storage.cleanup()
	print("UI PROPOSAL RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _escape() -> void:
	await _key(KEY_ESCAPE)

func _key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
	await process_frame
	await process_frame

func _interact_key(code: Key) -> bool:
	return InputMap.action_get_events("interact").any(func(event): return event is InputEventKey and event.physical_keycode == code)

func _check(ok: bool, detail: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(detail)
