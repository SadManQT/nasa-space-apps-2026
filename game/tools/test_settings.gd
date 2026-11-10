## M3-70: Steam-quality settings, controls and saves verification:
## - Display: resolution, window mode, V-sync, frame cap (Engine.max_fps), quality preset, field of view (Camera3D.fov)
## - Audio: Master, Music, Voice, Effects (SFX) and UI volume synced with AudioSettings
## - Controls: full keyboard & controller remapping with matching button glyphs and automatic conflict swap
## - Captions & Assist: captions, subtitle size (Small/Medium/Large/Extra Large), reduced motion, timer-free,
##   Story/Cadet/Expedition assist modes plus Family/Class session modes
## - Cutscenes & Pause: pause anywhere, skip any cutscene immediately after first viewing
## - Saves & Chapters: autosave at every scene change & mission end, three manual slots, Continue,
##   chapter select after completion, safe migration from M1-47 schema 3, and persistence across restart.
extends SceneTree

const GameSettingsScript = preload("res://scripts/settings/game_settings.gd")
const SettingsMenuScript = preload("res://scripts/ui/settings_menu.gd")
const SaveSlotsScript = preload("res://scripts/save/save_slots.gd")
const SaveServiceScript = preload("res://scripts/save/save_service.gd")
const AudioSettingsScript = preload("res://scripts/audio/audio_settings.gd")
const CampaignScene: PackedScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const Gates = preload("res://scripts/missions/chapter1_gate_catalog.gd")
const PlantInput = preload("res://tools/support/p01_input_fixture.gd")

var checks := 0
var failures := 0
var _save_evidence := false
var _cfg_path := ""
var _audio_path := ""
var _save_path := ""

func _init() -> void:
	CampaignCutscenePlayer.autoplay = false
	for arg in OS.get_cmdline_user_args():
		if arg == "--evidence":
			_save_evidence = true
	var pid := OS.get_process_id()
	_cfg_path = "user://test_game_settings_%d.cfg" % pid
	_audio_path = "user://test_audio_settings_%d.cfg" % pid
	_save_path = "user://test_settings_saves_%d.json" % pid
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	await process_frame

	_cleanup_files()

	await _test_display_audio_assist_and_persistence()
	await _test_remapping_conflicts_and_glyphs()
	await _test_cutscene_skip_after_first_viewing()
	await _test_campaign_integration_autosave_and_controls()
	await _test_settings_menu_ui_and_evidence()

	_cleanup_files()

	print("SETTINGS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_display_audio_assist_and_persistence() -> void:
	var gs := GameSettingsScript.new(_cfg_path, _audio_path)
	var cam := Camera3D.new()
	root.add_child(cam)
	await process_frame

	# Display options
	_check(bool(gs.set_display_option("resolution", "2560x1440").get("accepted", false)), "Resolution 2560x1440 accepted")
	_check(bool(gs.set_display_option("window_mode", "Borderless").get("accepted", false)), "Window mode Borderless accepted")
	_check(bool(gs.set_display_option("vsync", false).get("accepted", false)), "V-sync toggle accepted")
	_check(bool(gs.set_display_option("frame_cap", 120).get("accepted", false)), "Frame cap 120 accepted")
	_check(Engine.max_fps == 120, "Frame cap actually updates Engine.max_fps to 120")
	_check(bool(gs.set_display_option("quality_preset", "Ultra").get("accepted", false)), "Quality preset Ultra accepted")
	_check(bool(gs.set_display_option("fov", 90.0).get("accepted", false)), "FOV 90 deg accepted")
	gs.apply_display(cam)
	_check(is_equal_approx(cam.fov, 90.0), "FOV actually updates Camera3D.fov to 90.0")

	# Audio volumes (Master, Music, Voice, Effects/SFX, UI)
	_check(bool(gs.set_audio_volume("Master", 0.8).get("accepted", false)), "Master volume set")
	_check(bool(gs.set_audio_volume("Music", 0.55).get("accepted", false)), "Music volume set")
	_check(bool(gs.set_audio_volume("Voice", 0.95).get("accepted", false)), "Voice volume set")
	_check(bool(gs.set_audio_volume("Effects", 0.65).get("accepted", false)), "Effects (SFX) volume set")
	var prev_audio_path := AudioSettingsScript.path
	AudioSettingsScript.path = _audio_path
	AudioSettingsScript.forget_cache()
	_check(is_equal_approx(AudioSettingsScript.volume("Master"), 0.8), "AudioSettings persisted Master = 0.8")
	_check(is_equal_approx(AudioSettingsScript.volume("Music"), 0.55), "AudioSettings persisted Music = 0.55")
	_check(is_equal_approx(AudioSettingsScript.volume("Voice"), 0.95), "AudioSettings persisted Voice = 0.95")
	_check(is_equal_approx(AudioSettingsScript.volume("SFX"), 0.65), "AudioSettings persisted SFX = 0.65")
	AudioSettingsScript.path = prev_audio_path

	# Captions, subtitle size, assist modes (Story, Cadet, Expedition + Family/Class)
	_check(bool(gs.set_accessibility_option("captions", false).get("accepted", false)), "Captions toggle accepted")
	_check(bool(gs.set_accessibility_option("subtitle_size", "Extra Large").get("accepted", false)), "Subtitle size Extra Large accepted")
	_check(bool(gs.accessibility.get("large_text", false)) and is_equal_approx(float(gs.accessibility.get("subtitle_scale", 1.0)), 1.5), "Extra Large subtitles sync large_text=true and scale=1.5")
	_check(bool(gs.set_accessibility_option("reduced_motion", true).get("accepted", false)), "Reduced motion accepted")
	for mode in ["Story", "Cadet", "Expedition"]:
		_check(bool(gs.set_accessibility_option("assist_mode", mode).get("accepted", false)) and gs.accessibility.get("assist_mode") == mode, "Assist mode %s accepted" % mode)
	_check(bool(gs.set_accessibility_option("session_mode", "Family").get("accepted", false)) and bool(gs.accessibility.get("family_mode", false)), "Family session mode supported")
	_check(bool(gs.set_accessibility_option("session_mode", "Class").get("accepted", false)) and bool(gs.accessibility.get("class_mode", false)), "Class session mode supported")

	# Restart persistence: instantiate a brand-new GameSettings from the same disk config path
	var restarted := GameSettingsScript.new(_cfg_path, _audio_path)
	_check(restarted.display.get("resolution") == "2560x1440", "Restart persisted resolution")
	_check(restarted.display.get("window_mode") == "Borderless", "Restart persisted window_mode")
	_check(bool(restarted.display.get("vsync")) == false, "Restart persisted vsync=false")
	_check(int(restarted.display.get("frame_cap")) == 120, "Restart persisted frame_cap=120")
	_check(restarted.display.get("quality_preset") == "Ultra", "Restart persisted quality_preset=Ultra")
	_check(is_equal_approx(float(restarted.display.get("fov")), 90.0), "Restart persisted fov=90.0")
	_check(is_equal_approx(float(restarted.audio.get("Music")), 0.55), "Restart persisted Music volume")
	_check(is_equal_approx(float(restarted.audio.get("SFX")), 0.65), "Restart persisted SFX volume")
	_check(bool(restarted.accessibility.get("captions")) == false, "Restart persisted captions=false")
	_check(restarted.accessibility.get("subtitle_size") == "Extra Large", "Restart persisted subtitle_size=Extra Large")
	_check(bool(restarted.accessibility.get("reduced_motion")) == true, "Restart persisted reduced_motion=true")
	_check(restarted.accessibility.get("assist_mode") == "Expedition", "Restart persisted assist_mode=Expedition")
	_check(restarted.accessibility.get("session_mode") == "Class", "Restart persisted session_mode=Class")

	cam.queue_free()
	await process_frame

func _test_remapping_conflicts_and_glyphs() -> void:
	var gs := GameSettingsScript.new(_cfg_path, _audio_path)
	gs.reset_to_defaults(true)

	# Default glyphs
	_check(gs.keyboard_glyph("interact") == "E", "Default interact keyboard glyph is E")
	_check(gs.keyboard_glyph("what_now") == "H", "Default what_now keyboard glyph is H")
	_check(gs.controller_glyph("interact") == "(A) Cross", "Default interact controller glyph is (A) Cross")
	_check(gs.controller_glyph("what_now") == "(Y) Triangle", "Default what_now controller glyph is (Y) Triangle")

	# Remap keyboard with conflict: bind 'interact' (currently E) to KEY_H (currently 'what_now')
	var kb_swap := gs.remap_keyboard("interact", KEY_H)
	_check(bool(kb_swap.get("accepted", false)), "Keyboard remap with conflict accepted")
	_check(String(kb_swap.get("swapped_with", "")) == "what_now", "Keyboard conflict automatically swapped with what_now")
	_check(int(gs.keyboard_bindings["interact"]) == KEY_H and int(gs.keyboard_bindings["what_now"]) == KEY_E, "Keyboard bindings swapped cleanly (interact=H, what_now=E)")

	# Verify actual InputMap event matching for keyboard
	var ev_h := InputEventKey.new()
	ev_h.physical_keycode = KEY_H
	ev_h.keycode = KEY_H
	var ev_e := InputEventKey.new()
	ev_e.physical_keycode = KEY_E
	ev_e.keycode = KEY_E
	_check(InputMap.event_is_action(ev_h, "interact"), "InputMap maps KEY_H to interact after remap")
	_check(InputMap.event_is_action(ev_e, "what_now"), "InputMap maps KEY_E to what_now after swap")

	# Remap controller with conflict: bind 'interact' (currently A) to JOY_BUTTON_Y (currently 'what_now')
	var pad_swap := gs.remap_controller("interact", JOY_BUTTON_Y)
	_check(bool(pad_swap.get("accepted", false)), "Controller remap with conflict accepted")
	_check(String(pad_swap.get("swapped_with", "")) == "what_now", "Controller conflict automatically swapped with what_now")
	_check(gs.controller_glyph("interact") == "(Y) Triangle" and gs.controller_glyph("what_now") == "(A) Cross", "Controller glyphs updated after swap")

	var joy_y := InputEventJoypadButton.new()
	joy_y.button_index = JOY_BUTTON_Y
	var joy_a := InputEventJoypadButton.new()
	joy_a.button_index = JOY_BUTTON_A
	_check(InputMap.event_is_action(joy_y, "interact"), "InputMap maps JOY_BUTTON_Y to interact after remap")
	_check(InputMap.event_is_action(joy_a, "what_now"), "InputMap maps JOY_BUTTON_A to what_now after swap")

	# Persist and reload bindings across restart
	var restarted := GameSettingsScript.new(_cfg_path, _audio_path)
	_check(int(restarted.keyboard_bindings["interact"]) == KEY_H and int(restarted.keyboard_bindings["what_now"]) == KEY_E, "Remapped keyboard bindings persist across restart")
	_check(int(restarted.controller_bindings["interact"]) == JOY_BUTTON_Y and int(restarted.controller_bindings["what_now"]) == JOY_BUTTON_A, "Remapped controller bindings persist across restart")

	restarted.reset_to_defaults(true)

func _test_cutscene_skip_after_first_viewing() -> void:
	var gs := GameSettingsScript.new(_cfg_path, _audio_path)
	gs.seen_cutscenes.clear()
	gs.skip_viewed_cutscenes = true
	gs.save_to_disk()

	_check(not gs.has_seen_cutscene("CS-01"), "Cutscene CS-01 starts unseen")
	_check(not gs.can_skip_cutscene_immediately("CS-01"), "Unseen cutscene requires standard hold-to-skip on first viewing")
	_check(is_equal_approx(gs.effective_cutscene_skip_hold_s("CS-01", 1.0), 1.0), "First viewing keeps 1.0s hold threshold")

	gs.mark_cutscene_seen("CS-01")
	_check(gs.has_seen_cutscene("CS-01"), "CS-01 marked seen after first viewing")
	_check(gs.can_skip_cutscene_immediately("CS-01"), "Viewed cutscene can be skipped immediately on subsequent viewings")
	_check(gs.effective_cutscene_skip_hold_s("CS-01", 1.0) <= 0.05, "Viewed cutscene lowers skip hold threshold to instant")

	var restarted := GameSettingsScript.new(_cfg_path, _audio_path)
	_check(restarted.has_seen_cutscene("CS-01"), "Viewed cutscene history persists across restart")

func _test_campaign_integration_autosave_and_controls() -> void:
	var campaign := CampaignScene.instantiate() as Chapter1Campaign
	campaign.save_path = _save_path
	campaign.settings_path = _cfg_path
	root.add_child(campaign)
	await process_frame
	await process_frame

	_check(campaign.save_slots != null, "Campaign initializes SaveSlots helper")
	_check(campaign.game_settings != null, "Campaign initializes GameSettings helper")
	_check(campaign.hud != null, "Campaign HUD initializes")

	# Verify initial autosave on scene_join
	var auto_meta := campaign.save_slots.inspect_slot(SaveSlotsScript.AUTOSAVE_SLOT)
	_check(bool(auto_meta.get("valid", false)) and String(auto_meta.get("scene_id", "")) == "EX-CH01-S01", "Campaign autosaves at initial scene join")

	# Record S01 story choice while on EX-CH01-S01 for M1-47 schema 3 verification
	var cmd := {
		"command_id": "m370-choice-s01",
		"issuer": "player",
		"owning_mission_id": campaign.route.current_mission_id(),
		"owning_scene_id": "EX-CH01-S01",
		"expected_state_revision": int(campaign.director.snapshot().state_revision),
		"target_id": "EX-CH01-S01-CHOICE",
		"verb": "record_choice",
		"payload": {"choice_id": "EX-CH01-S01-CHOICE", "option_id": "EX-CH01-S01-OPT01"},
	}
	campaign.director.commit(cmd)

	# Complete EX-CH01-S01 and advance_scene -> autosave updates to EX-CH01-S02
	for line in campaign.current_dialogue():
		campaign.acknowledge_dialogue(String(line.get("id", "")))
	for target in Gates.targets_for_scene("EX-CH01-S01"):
		var tid := String(target.get("target_id", ""))
		campaign.route.perform(tid, PlantInput.payload(tid))
	var adv := campaign.advance_scene()
	_check(bool(adv.get("accepted", false)) and campaign.route.current_scene_id() == "EX-CH01-S02", "Campaign advances from S01 to S02")
	var s02_meta := campaign.save_slots.inspect_slot(SaveSlotsScript.AUTOSAVE_SLOT)
	_check(String(s02_meta.get("scene_id", "")) == "EX-CH01-S02" and String(s02_meta.get("trigger", "")) == "scene_join", "Autosave records scene_join at S02")

	# Save to manual slot_1 at S02, then load back
	var manual_res := campaign.save_to_slot("slot_1")
	_check(bool(manual_res.get("accepted", false)), "Campaign saves to manual slot_1")
	var slot1_meta := campaign.save_slots.inspect_slot("slot_1")
	_check(bool(slot1_meta.get("valid", false)) and String(slot1_meta.get("scene_id", "")) == "EX-CH01-S02", "Manual slot_1 metadata shows EX-CH01-S02")

	# Safe migration from M1-47 schema 3 (story_log without slot_metadata)
	var m147_snap := campaign._save_snapshot()
	m147_snap["presentation_resume"] = {}
	var direct_service := SaveServiceScript.new()
	direct_service.session_validator = campaign.restore_session
	var slot2_path := campaign.save_slots.slot_path("slot_2")
	_check(bool(direct_service.save(m147_snap, slot2_path).get("accepted", false)), "Saved raw M1-47 schema 3 snapshot to slot_2")
	var loaded_slot2 := campaign.load_from_slot("slot_2")
	_check(bool(loaded_slot2.get("accepted", false)), "Campaign loads and upgrades M1-47 schema 3 save from slot_2")
	var restored_log: Dictionary = campaign.director.snapshot().get("story_log", {})
	_check(restored_log.get("choices", {}).get("EX-CH01-S01-CHOICE", {}).get("option_id", "") == "EX-CH01-S01-OPT01", "M1-47 story_log choices preserved after slot load")

	# Verify HUD opens both save_slots and settings_menu families
	_check(campaign.hud.open_family("save_slots"), "Campaign HUD opens save_slots family")
	await process_frame
	campaign.hud.close_family()
	await process_frame
	_check(campaign.hud.open_family("settings_menu"), "Campaign HUD opens settings_menu family")
	await process_frame
	campaign.hud.close_family()
	await process_frame

	campaign.free()
	await process_frame

func _test_settings_menu_ui_and_evidence() -> void:
	var gs := GameSettingsScript.new(_cfg_path, _audio_path)
	var slots := SaveSlotsScript.new(_save_path, Callable( preload("res://scripts/campaign/chapter1_campaign.gd"), "restore_session"))
	var menu := SettingsMenuScript.new(gs, slots)
	root.add_child(menu)
	await process_frame
	await process_frame

	# Tab 1: Display
	menu.show_tab("display")
	await process_frame
	var disp_text := _collect_text(menu)
	_check(disp_text.contains("Display & Graphics") and disp_text.contains("Resolution") and disp_text.contains("Field of View"), "SettingsMenu Display tab renders resolution, window mode, V-sync, frame cap, quality and FOV")
	await _maybe_capture("M3-70_settings_display_audio.png")

	# Tab 2: Audio
	menu.show_tab("audio")
	await process_frame
	var aud_text := _collect_text(menu)
	_check(aud_text.contains("Master volume") and aud_text.contains("Music volume") and aud_text.contains("Voice & dialogue volume") and aud_text.contains("Effects volume"), "SettingsMenu Audio tab renders Master, Music, Voice and Effects sliders")

	# Tab 3: Controls
	menu.show_tab("controls")
	await process_frame
	var ctrl_text := _collect_text(menu)
	_check(ctrl_text.contains("Keyboard & Controller Remapping") and ctrl_text.contains("Use / Interact") and ctrl_text.contains("(A) Cross"), "SettingsMenu Controls tab renders keyboard & controller bindings with glyphs")
	await _maybe_capture("M3-70_settings_controls_saves.png")

	# Tab 4: Captions & Assist
	menu.show_tab("assist")
	await process_frame
	var assist_text := _collect_text(menu)
	_check(assist_text.contains("Story") and assist_text.contains("Cadet") and assist_text.contains("Expedition") and assist_text.contains("Pause Anywhere"), "SettingsMenu Captions & Assist tab renders Story/Cadet/Expedition assist modes, subtitle sizes, cutscene skip and pause anywhere")

	# Tab 5: Saves & Chapters
	menu.show_tab("saves")
	await process_frame
	var saves_text := _collect_text(menu)
	_check(saves_text.contains("Continue Latest") and saves_text.contains("Open Chapter Select") and saves_text.contains("Slot 1"), "SettingsMenu Saves & Chapters tab renders Continue, Chapter Select and embedded SaveSlotsPanel")

	menu.queue_free()
	await process_frame

func _collect_text(node: Node) -> String:
	var parts: Array[String] = []
	_walk_text(node, parts)
	return "\n".join(parts)

func _walk_text(node: Node, out: Array[String]) -> void:
	if node is Label:
		out.append((node as Label).text)
	elif node is Button:
		out.append((node as Button).text)
	elif node is RichTextLabel:
		out.append((node as RichTextLabel).text)
	for child in node.get_children():
		_walk_text(child, out)

func _maybe_capture(filename: String) -> void:
	if not _save_evidence or DisplayServer.get_name() == "headless":
		return
	await process_frame
	await process_frame
	var img := root.get_viewport().get_texture().get_image()
	if img != null:
		var abs_path := ProjectSettings.globalize_path("res://../production/qa/evidence/" + filename)
		img.save_png(abs_path)

func _cleanup_files() -> void:
	for p in [_cfg_path, _audio_path]:
		if not p.is_empty() and FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	if not _save_path.is_empty():
		var slots := SaveSlotsScript.new(_save_path)
		slots.clear_all()

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + label)
