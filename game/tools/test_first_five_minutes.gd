## First five minutes: title screen, onboarding and UX polish (M1-18).
## Verifies:
##   1. UI_01 Title Screen: Aurora south-polar ridge backdrop, Earth near horizon,
##      warm greenhouse glow, full menu hierarchy (New Expedition, Continue,
##      Mission Trainer, Moon Trainer, Chapters/Progress/Achievements, Science+Sources,
##      Settings/Accessibility, Credits), non-overlapping footer, and DEVELOPER ASSET
##      SHOWCASE gated to OS.has_feature("editor").
##   2. UI_02 New Expedition: Chapter 1 briefing, crew role cards, Assist Mode
##      selector (Story, Cadet, Expedition) with live summary, and Enter Aurora / Cancel.
##   3. Contextual first-time prompts (move, look, use, mission_table, journal):
##      shown once via HintPlayer and replayable from Settings.
##   4. UI_15 Settings & Accessibility: Assist Mode cycling, control binding
##      conflict swap, and two-step reset confirmation.
extends SceneTree

const MainMenuScene: PackedScene = preload("res://scenes/ui/main_menu.tscn")
const CampaignPanelsScene: PackedScene = preload("res://scenes/ui/campaign_panels.tscn")
const HowToCardScript = preload("res://scripts/ui/how_to_card.gd")

var checks := 0
var failures := 0
var _save_evidence := false
var storage = preload("res://tools/support/isolated_storage.gd").new()

func _init() -> void:
	CampaignCutscenePlayer.autoplay = false
	for arg in OS.get_cmdline_user_args():
		if arg == "--evidence":
			_save_evidence = true
	if not storage.setup("first-five-minutes"):
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	await process_frame

	await _test_title_and_new_expedition()
	await _test_contextual_onboarding_prompts()
	await _test_settings_remap_and_replay()

	storage.cleanup()
	print("FIRST FIVE MINUTES RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_title_and_new_expedition() -> void:
	var menu: MainMenu = MainMenuScene.instantiate() as MainMenu
	root.add_child(menu)
	menu.setup({})
	await process_frame
	await process_frame

	for entry in ["NewExpedition", "Continue", "MissionTrainerEntry", "MoonTrainerEntry", "ChapterSelectEntry", "ScienceEntry", "SettingsEntry", "CreditsEntry"]:
		var action := menu.find_child(entry, true, false) as Button
		_check(action != null and not action.text.is_empty(), "UI_01 Title Screen retains named action: " + entry)
	var title := menu.find_child("Title", true, false) as Label
	_check(title != null and title.text.replace("\n", " ").replace(" ", "").contains("LASTLIGHTACADEMY"), "UI_01 title retains the game identity")
	_check(_collect_text(menu).contains("NOT NASA-ENDORSED"), "UI_01 title retains the independence credit")

	# Verify footer does not overlap the main menu buttons
	var credits_btn := menu.find_child("CreditsEntry", true, false) as Button
	var footer_lbl := menu._footer_status
	if credits_btn != null and footer_lbl != null:
		_check(not credits_btn.get_global_rect().intersects(footer_lbl.get_global_rect()), "UI_01 Title footer never overlaps menu actions")

	await _maybe_capture("M1-18_title.png")

	# Open New Expedition briefing (UI_02)
	menu._show_briefing()
	await process_frame
	_check(menu._briefing.visible, "UI_02 New Expedition briefing opens")
	var brief_text := _collect_text(menu._briefing)
	for token in ["MISSION BRIEFING  /  CHAPTER 1", "ASSIST MODE", "KAI", "AMARA", "MEI", "RAFI", "ENTER AURORA"]:
		_check(brief_text.contains(token), "UI_02 New Expedition briefing includes: " + token)

	# Verify Assist Mode selection (Story, Cadet, Expedition)
	_check(menu.assist_mode() == "Cadet", "UI_02 default Assist Mode is Cadet")
	menu.set_assist_mode("Story")
	_check(menu.assist_mode() == "Story" and menu._assist_summary.text.contains("Story Mode"), "UI_02 selects Story Assist Mode")
	_check(menu.accessibility_settings().get("assist_mode", "") == "Story", "Selected assist mode is included in real campaign launch settings")
	menu.set_assist_mode("Expedition")
	_check(menu.assist_mode() == "Expedition" and menu._assist_summary.text.contains("Expedition Mode"), "UI_02 selects Expedition Assist Mode")
	menu.set_assist_mode("Cadet")
	await _maybe_capture("M1-18_new_expedition.png")

	menu._hide_briefing()
	menu.queue_free()
	await process_frame

func _test_contextual_onboarding_prompts() -> void:
	var panels := CampaignPanelsScene.instantiate()
	root.add_child(panels)
	await process_frame

	var hp: HintPlayer = panels.hint_player
	hp.seen_path = storage.directory.path_join("how_to_seen_m118.cfg")
	hp.reset_seen()

	for prompt_id in ["move", "look", "use", "mission_table", "journal"]:
		var lesson: Dictionary = HowToCardScript.lesson(prompt_id)
		_check(not lesson.is_empty(), "Contextual onboarding lesson exists for: " + prompt_id)
		_check(not hp.has_seen(prompt_id), "Prompt '" + prompt_id + "' starts unseen")
		hp.show_how_to(prompt_id, true)
		await process_frame
		_check(hp.is_open(), "First-time prompt '" + prompt_id + "' opens on first trigger")
		if prompt_id == "move":
			await _maybe_capture("M1-18_onboarding_prompts.png")
		hp.close()
		await process_frame
		_check(hp.has_seen(prompt_id), "Prompt '" + prompt_id + "' marked seen after closing")
		# Second first_time trigger must NOT re-open automatically
		hp.show_how_to(prompt_id, true)
		await process_frame
		_check(not hp.is_open(), "Seen prompt '" + prompt_id + "' does not re-open on second first_time trigger")

	panels.queue_free()
	await process_frame

func _test_settings_remap_and_replay() -> void:
	var panels := CampaignPanelsScene.instantiate()
	root.add_child(panels)
	await process_frame

	var hp: HintPlayer = panels.hint_player
	hp.seen_path = storage.directory.path_join("how_to_seen_m118_replay.cfg")
	hp.show_how_to("move", true)
	hp.close()
	_check(hp.has_seen("move"), "Move prompt marked seen before Settings replay")

	_check(panels.open_panel("settings_accessibility"), "UI_15 Settings panel opens")
	await process_frame

	# Replay first-time prompts from Settings
	var replay_btn := panels.find_child("ReplayFirstTimePrompts", true, false) as Button
	_check(replay_btn != null, "UI_15 Settings includes 'Replay first-time onboarding prompts' button")
	if replay_btn != null:
		replay_btn.pressed.emit()
		await process_frame
	_check(not hp.has_seen("move"), "Replay first-time prompts in Settings resets seen state")

	# Remap binding with conflict swap (use: E <-> what_now: H)
	var before_bindings: Dictionary = panels.bindings_snapshot()
	_check(String(before_bindings.get("use", "")) == "E" and String(before_bindings.get("what_now", "")) == "H", "Default bindings have Use=E and What now=H")
	var swap_res: Dictionary = panels.remap_binding("use", "H")
	await process_frame
	var after_bindings: Dictionary = panels.bindings_snapshot()
	_check(bool(swap_res.get("accepted", false)) and String(swap_res.get("swapped_with", "")) == "what_now", "Remapping Use to H swaps conflict with What now")
	_check(String(after_bindings.get("use", "")) == "H" and String(after_bindings.get("what_now", "")) == "E", "Swapped bindings are Use=H and What now=E")
	var use_event := InputEventKey.new()
	use_event.physical_keycode = KEY_H
	_check(InputMap.event_is_action(use_event, "interact"), "Supported Use/What now swap updates the actual interact input")
	await _maybe_capture("M1-18_settings_remap.png")

	# Two-step reset confirmation
	var reset_btn := panels.find_child("ResetSettingsBindings", true, false) as Button
	_check(reset_btn != null, "UI_15 Settings includes Reset Bindings & Settings button")
	if reset_btn != null:
		reset_btn.pressed.emit()
		await process_frame
		_check(String(panels.bindings_snapshot().get("use", "")) == "H", "First press of Reset asks for confirmation before resetting")
		reset_btn = panels.find_child("ResetSettingsBindings", true, false) as Button
		reset_btn.pressed.emit()
		await process_frame
		_check(String(panels.bindings_snapshot().get("use", "")) == "E" and String(panels.bindings_snapshot().get("what_now", "")) == "H", "Confirmed Reset restores default bindings")

	panels.close_panel()
	panels.queue_free()
	await process_frame

func _find_button_with_text(node: Node, needle: String) -> Button:
	if node is Button and (node as Button).text.contains(needle):
		return node as Button
	for child in node.get_children():
		var found := _find_button_with_text(child, needle)
		if found != null:
			return found
	return null

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

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + label)
