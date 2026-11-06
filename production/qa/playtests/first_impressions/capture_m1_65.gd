extends SceneTree

## Assisted UI inspection, not a fresh-player playtest. Run from the repo root:
## Godot --path game --windowed --resolution 1280x720 --rendering-method gl_compatibility
##   --script ../production/qa/playtests/first_impressions/capture_m1_65.gd
## Uses the existing isolated-storage helper; never reads the player's save.
const MAIN = preload("res://scenes/main.tscn")
var storage = preload("res://tools/support/isolated_storage.gd").new()
var main: Node
var observations: Array = []
var failures := 0
var output := "res://../production/qa/evidence/"
var old_autoplay := true

func _init() -> void:
	old_autoplay = CampaignCutscenePlayer.autoplay
	CampaignCutscenePlayer.autoplay = false
	if not storage.setup("M1-65-assisted-inspection"):
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	main = MAIN.instantiate()
	storage.configure(main)
	root.add_child(main)
	for i in 3600:
		if bool(main.get("title_ready")):
			break
		await process_frame
	if not bool(main.get("title_ready")):
		_fail("Title did not become ready within 3600 frames")
		_finish()
		return
	var menu = main.get("_menu")
	await _capture("01_title")
	menu.get("_begin_button").pressed.emit()
	await _capture("02_briefing")
	menu.call("_hide_briefing")
	menu.open_panel("settings_accessibility")
	await _capture("03_title_settings")
	menu.set_accessibility({"large_text": true})
	await _capture("04_title_settings_large")
	menu.get("_panels").close_panel()
	await _capture("05_title_large")
	menu.set_accessibility({"large_text": false})
	menu.open_science()
	await _capture("06_sources")
	menu.close_science()
	main.call("_start_new_expedition")
	for i in 7200:
		var candidate = main.get("_campaign")
		if candidate != null and not bool(main.get("_launching")) and not bool(candidate.get("loading")):
			break
		await process_frame
	var campaign = main.get("_campaign")
	if campaign == null or bool(main.get("_launching")) or campaign.hud == null:
		_fail("Campaign did not become ready within 7200 frames")
		_finish()
		return
	await _capture("07_arrival_dialogue")
	var hud = campaign.hud
	for i in 30:
		if not hud.get("_dialogue_bar").visible or hud.get("_next_line").disabled:
			break
		hud.call("_on_next_line")
		await create_timer(0.25).timeout
	await _capture("08_arrival_walking")
	hud.panels.open_panel("what_now")
	await _capture("09_what_now")
	hud.panels.open_panel("pause")
	await _capture("10_pause")
	hud.panels.open_panel("journal_discovery")
	await _capture("11_journal")
	hud.panels.open_panel("settings_accessibility")
	hud.panels.set_accessibility({"large_text": true})
	hud.apply_accessibility()
	await _capture("12_campaign_settings_large")
	hud.panels.close_panel()
	await _capture("13_campaign_large")
	_finish()

func _capture(label: String) -> void:
	await create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	var filename := "M1-65_%s.png" % label
	var error := root.get_texture().get_image().save_png(ProjectSettings.globalize_path(output + filename))
	var texts: Array = []
	_visible_text(root, texts)
	observations.append({"capture": filename, "error": error, "viewport": [root.size.x, root.size.y], "visible_text": texts})
	if error != OK:
		_fail("Could not save " + filename)
	print("M1-65 evidence: ", filename, " (", error, ")")

func _visible_text(node: Node, rows: Array) -> void:
	if node is Control and not (node as Control).is_visible_in_tree():
		return
	var value := ""
	if node is Label or node is RichTextLabel or node is Button:
		value = String(node.get("text"))
	if not value.is_empty():
		var rect: Rect2 = (node as Control).get_global_rect()
		rows.append({"text": value, "rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y], "node": String(node.get_path())})
	for child in node.get_children():
		_visible_text(child, rows)

func _fail(message: String) -> void:
	failures += 1
	push_error(message)

func _finish() -> void:
	var f := FileAccess.open(output + "M1-65_ui_inventory.json", FileAccess.WRITE)
	if f == null:
		_fail("Could not write UI inventory")
	else:
		f.store_string(JSON.stringify(observations, "\t") + "\n")
		f.close()
	if is_instance_valid(main):
		main.queue_free()
		await process_frame
	storage.cleanup()
	CampaignCutscenePlayer.autoplay = old_autoplay
	print("M1-65 CAPTURE RESULT: %s (%d captures, %d failures)" % ["PASS" if failures == 0 and observations.size() == 13 else "FAIL", observations.size(), failures])
	quit(0 if failures == 0 and observations.size() == 13 else 1)
