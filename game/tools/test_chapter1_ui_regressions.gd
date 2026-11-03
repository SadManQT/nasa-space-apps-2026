## Isolated production UI integration checks; never touches the player's slot.
extends SceneTree

const MainScene = preload("res://scenes/main.tscn")
const CampaignScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const Gates = preload("res://scripts/missions/chapter1_gate_catalog.gd")
const SaveScript = preload("res://scripts/save/save_service.gd")
const LegacyScript = preload("res://scripts/save/legacy_save.gd")

var storage = preload("res://tools/support/isolated_storage.gd").new()

var checks := 0
var failures := 0
var _original_user_dir := ""

func _init() -> void:
	if not storage.setup("test_chapter1_ui_regressions"):
		push_error("Unable to isolate test storage.")
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	var main := MainScene.instantiate()
	storage.configure(main)
	root.add_child(main)
	await process_frame
	var menu := main.get_node("TitleLayer/MainMenu") as MainMenu
	var title_settings := _find_button(menu, "SETTINGS / ACCESSIBILITY")
	_reveal_control(title_settings)
	await process_frame
	await process_frame
	_check(menu.get_global_rect().encloses(title_settings.get_global_rect()), "title settings can be reached at 1280x720")
	menu.set_accessibility({"large_text": true, "captions": false})
	await process_frame
	await process_frame
	_reveal_control(title_settings)
	await process_frame
	_check(menu.get_global_rect().encloses(title_settings.get_global_rect()), "title settings can be reached with large text")
	main.call("_launch_campaign", {})
	await process_frame
	await process_frame
	var campaign := main.get_node("Chapter1Campaign") as Chapter1Campaign
	var hud := campaign.hud
	var player := campaign.get("_player") as PlayerController
	var stage := main.get_node_or_null("TitleStage")
	_check(stage != null and stage.process_mode == Node.PROCESS_MODE_DISABLED and not stage.visible, "title geometry and lights are disabled during the expedition")
	_check(not player.follow_camera.capture_mouse and not player.follow_camera.is_processing_unhandled_input(), "campaign camera leaves the pointer available for operations")
	_check(bool(campaign.query().get("accessibility", {}).get("large_text", false)), "title accessibility choices carry into a new campaign")
	_check(not bool(campaign.query().get("accessibility", {}).get("captions", true)), "title caption choice carries into a new campaign")
	var caption := hud.get("_caption_line") as Label
	_check(not caption.visible, "captions off hides the production caption")
	_check((hud.get("_title") as Label).get_theme_font_size("font_size") > 21, "large text scales the production HUD")
	var advance := hud.get("_advance") as Button
	_check(hud.get_global_rect().encloses(advance.get_global_rect()), "advance control stays inside the 1280x720 viewport")
	var title_button := _find_button(hud, "TITLE")
	_check(title_button != null and hud.get_global_rect().encloses(title_button.get_global_rect()), "title control stays inside the viewport")
	hud.refresh_after_action({"accepted": false, "reason": "TEST: preceding physical check is missing"})
	_check((hud.get("_status") as Label).text == "TEST: preceding physical check is missing", "rejection cause survives gate refresh")
	var pause := _find_button(hud, "PAUSE")
	var settings := _find_button(hud, "SETTINGS")
	_check(pause != null and settings != null, "pause and settings are reachable in the production HUD")
	hud.panels.open_panel("pause")
	_check(bool(campaign.director.query().get("paused", false)) and player.process_mode == Node.PROCESS_MODE_DISABLED, "opening a modal pauses authoritative actions and movement")
	_check(advance.disabled and title_button != null and title_button.disabled, "modal panels exclude underlying controls from keyboard focus")
	hud.panels.close_panel()
	_check(not bool(campaign.director.query().get("paused", true)) and player.process_mode != Node.PROCESS_MODE_DISABLED, "closing a modal resumes actions and movement")
	hud.panels.open_panel("settings_accessibility")
	await process_frame
	await process_frame
	_check(hud.get_global_rect().encloses((hud.panels.get("_close_button") as Button).get_global_rect()), "large-text settings keep their close control inside the viewport")
	var caption_toggle: CheckButton
	for child in (hud.panels.get("_body") as VBoxContainer).get_children():
		if child is CheckButton and child.text == "Captions on":
			caption_toggle = child
	caption_toggle.grab_focus()
	caption_toggle.button_pressed = true
	caption_toggle.pressed.emit()
	await process_frame
	_check(root.gui_get_focus_owner() is CheckButton and hud.panels.is_ancestor_of(root.gui_get_focus_owner()), "changing a setting preserves keyboard focus inside the panel")
	hud.panels.close_panel()
	_check(not campaign.perform_target("commission_route").get("accepted", false), "operation buttons reject targets outside physical range")
	if campaign.has_method("physical_target") and campaign.has_method("interact_nearby"):
		var target: Node3D = campaign.call("physical_target", "commission_route")
		player.position = target.position + Vector3(0.0, -target.position.y, 1.0)
		_check(campaign.call("interact_nearby").get("accepted", false) and campaign.route.current_flags().get("commission_route_confirmed", false), "nearby E action commits the real physical operation")
	else:
		_check(false, "nearby E action commits the real physical operation")
	var traversed := true
	for scene_id in Gates.scene_ids():
		if scene_id in ["EX-CH01-S02", "EX-CH01-S04"]:
			campaign.call("_refresh_world")
			if scene_id == "EX-CH01-S02":
				_check(campaign._player.character_glb.contains("CH_Rafi"), "Safe Room scene uses its authored Rafi viewpoint")
			else:
				_check(not campaign._room.visual_root.get_node("PL_Alo_Bud").visible and not campaign._room.visual_root.get_node("PL_Tara_Bloom").visible, "April 11 seed cassettes do not display future buds or flowers")
		var targets := Gates.targets_for_scene(scene_id)
		if scene_id == "EX-CH01-S03":
			targets.push_back(targets.pop_front())
			var compare: Dictionary = targets.pop_at(3)
			targets.push_back(compare)
		for target in targets:
			var result: Dictionary = campaign.route.perform(String(target.target_id))
			if not bool(result.get("accepted", false)):
				traversed = false
				push_error("Traversal failed: " + String(target.target_id) + " " + str(result))
		var result: Dictionary = campaign.route.advance_scene()
		if not bool(result.get("accepted", false)):
			traversed = false
	_check(traversed and campaign.route.chapter_ready().get("ready", false), "real Chapter 1 operations reach the completed chapter")
	campaign.call("_refresh_world")
	_check(campaign._room.visual_root.get_node_or_null("PL_Alo_Bloom") != null and not campaign._room.visual_root.get_node("PL_Tara_Bloom").visible, "April 27 first bloom shows Alo bloom and keeps Tara's later bloom hidden")
	hud.refresh_scene({"chapter_complete": true})
	_check(advance.disabled and (hud.get("_status") as Label).text.contains("CHAPTER 1 COMPLETE"), "completed chapter shows a clear ending and disables repeated advance")
	main.call("_show_title")
	await process_frame
	stage = main.get_node_or_null("TitleStage")
	_check(stage != null and stage.process_mode != Node.PROCESS_MODE_DISABLED and stage.visible, "return to title restores its stage")
	main.queue_free()
	await process_frame
	var before := FileAccess.get_file_as_string(storage.path)
	var invalid := CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(invalid)
	invalid.initial_snapshot = {"schema_version": -1}
	root.add_child(invalid)
	await process_frame
	_check(FileAccess.get_file_as_string(storage.path) == before, "rejected restore never replaces an existing checkpoint")
	_check(invalid.hud == null, "rejected restore does not start a replacement campaign")
	invalid.queue_free()
	await process_frame
	var missing_route: Dictionary = JSON.parse_string(before)
	missing_route.erase("route_runtime")
	invalid = CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(invalid)
	invalid.initial_snapshot = missing_route
	root.add_child(invalid)
	await process_frame
	_check(invalid.hud == null and FileAccess.get_file_as_string(storage.path) == before, "missing route state rejects restore without erasing physical evidence")
	invalid.queue_free()
	await process_frame
	SaveScript.new().clear(storage.path)
	var corrupt := FileAccess.open(storage.path, FileAccess.WRITE)
	corrupt.store_string("{}")
	corrupt.close()
	main = MainScene.instantiate()
	storage.configure(main)
	root.add_child(main)
	main.call("_start_new_expedition")
	var replacement := main.get("_replace_dialog") as ConfirmationDialog
	_check(replacement != null and replacement.visible and FileAccess.get_file_as_string(storage.path) == "{}", "invalid occupied slot still requires explicit replacement")
	_check((main.get_node("TitleLayer/MainMenu").get("_save_note") as Label).text.contains("could not"), "unreadable checkpoint error is shown on title")
	main.queue_free()
	await process_frame
	SaveScript.new().clear(storage.path)
	var legacy_file := FileAccess.open(storage.legacy_path, FileAccess.WRITE)
	legacy_file.store_string(JSON.stringify({"content_revision": "story-data-extended-02-commissioning-slice"}))
	legacy_file.close()
	main = MainScene.instantiate()
	storage.configure(main)
	root.add_child(main)
	_check(main.call("_load_campaign_snapshot").is_empty() and FileAccess.file_exists(storage.legacy_path), "legacy checkpoint is preserved without inventing full-route evidence")
	main.queue_free()
	await process_frame
	_check(SaveScript.new().clear(storage.path) and LegacyScript.clear_save(storage.legacy_path), "UI fixture cleans its isolated save files")
	storage.cleanup()
	print("CHAPTER 1 UI REGRESSIONS: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _find_button(node: Node, text: String) -> Button:
	for child in node.get_children():
		if child is Button and child.text == text:
			return child as Button
		var found := _find_button(child, text)
		if found != null:
			return found
	return null

func _reveal_control(control: Control) -> void:
	var ancestor := control.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer:
			ancestor.ensure_control_visible(control)
		ancestor = ancestor.get_parent()

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)
