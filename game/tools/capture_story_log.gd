## Windowed, isolated M1-47 evidence. Run after run_tests.sh has imported assets:
## Godot --path game --windowed --script res://tools/capture_story_log.gd
extends SceneTree

const CampaignScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
var storage = preload("res://tools/support/isolated_storage.gd").new()
var campaign: Chapter1Campaign
var failures := 0
var probes := {}

func _init() -> void:
	if not storage.setup("M1-47-capture"):
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.always_on_top = true
	root.grab_focus()
	campaign = CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	root.add_child(campaign)
	await process_frame
	if campaign.hud == null or campaign.route == null:
		_probe("campaign_initializes", false)
		_finish()
		return
	var before := campaign.director.snapshot()
	campaign.hud._decision_review.pressed.emit()
	await process_frame
	var option := campaign.hud.panels.find_child("EX-CH01-S01-OPT02", true, false) as Button
	if option == null:
		_probe("decision_option_exists", false)
		_finish()
		return
	option.button_pressed = true
	option.pressed.emit()
	await _capture("preview")
	var preview := campaign.director.snapshot()
	_probe("preview_preserves_story_log_receipts_and_revision", preview.story_log == before.story_log and preview.receipts == before.receipts and preview.state_revision == before.state_revision)
	_probe_review_layout("normal")
	(campaign.hud.panels.find_child("ConfirmChoice", true, false) as Button).pressed.emit()
	var recorded := campaign.director.snapshot()
	_probe("confirmation_records_exactly_one_choice", recorded.story_log.choices.size() == 1 and recorded.story_log.choices.get("EX-CH01-S01-CHOICE", {}).get("option_id") == "EX-CH01-S01-OPT02")
	var loaded: Dictionary = campaign.save_service.load(storage.path)
	_probe("confirmation_autosaves", loaded.get("accepted", false) and loaded.get("snapshot", {}).get("story_log") == JSON.parse_string(JSON.stringify(recorded.story_log)))
	campaign.hud._decision_review.pressed.emit()
	await _capture("recorded")
	option = campaign.hud.panels.find_child("EX-CH01-S01-OPT02", true, false) as Button
	_probe("reopen_selects_recorded_option", option.button_pressed)
	_probe("unchanged_choice_does_not_enable_confirmation", (campaign.hud.panels.find_child("ConfirmChoice", true, false) as Button).disabled)
	campaign.hud.panels.close_panel()
	# Exercise long catalog labels and keyboard-reachable confirmation at 150%.
	var next := campaign.director.snapshot()
	next.accessibility.large_text = true
	campaign.director.restore_snapshot(next)
	campaign.route.start_at("EX-CH01-S06")
	campaign._sync_route_projection()
	campaign._refresh_world()
	campaign.hud.refresh_scene()
	campaign.hud._decision_review.pressed.emit()
	await process_frame
	option = campaign.hud.panels.find_child("EX-CH01-S06-OPT02", true, false) as Button
	option.button_pressed = true
	option.pressed.emit()
	await _capture("large_text")
	_probe_review_layout("large_text")
	var confirm := campaign.hud.panels.find_child("ConfirmChoice", true, false) as Button
	confirm.grab_focus()
	await _capture("large_text_confirm")
	_probe("large_text_confirmation_reachable_by_focus", confirm.has_focus() and campaign.hud.get_viewport_rect().encloses(confirm.get_global_rect()))
	_probe("large_text_uses_150_percent_font", option.get_theme_font_size("font_size") == 21)
	_finish()

func _finish() -> void:
	var path := ProjectSettings.globalize_path("res://../production/qa/evidence/M1-47_probes.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		failures += 1
	else:
		file.store_string(JSON.stringify(probes, "\t"))
		file.close()
	campaign.free()
	storage.cleanup()
	print("STORY LOG CAPTURE RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)

func _probe_review_layout(label: String) -> void:
	var panels := campaign.hud.panels
	_probe(label + "_panel_fits_window", campaign.hud.get_viewport_rect().encloses(panels._panel.get_global_rect()))
	_probe(label + "_close_control_visible", campaign.hud.get_viewport_rect().encloses(panels._close_button.get_global_rect()))
	var fits := true
	for child in panels._body.get_children():
		if child is Button:
			fits = fits and child.get_global_rect().position.x >= 0 and child.get_global_rect().end.x <= root.size.x
	_probe(label + "_options_fit_window_width", fits)

func _probe(label: String, passed: bool) -> void:
	probes[label] = passed
	if not passed:
		failures += 1
	print("M1-47 probe: ", label, " = ", passed)

func _capture(label: String) -> void:
	for frame in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	var evidence_path := "production/qa/evidence/M1-47_%s.png" % label
	var path := ProjectSettings.globalize_path("res://../" + evidence_path)
	var error := root.get_texture().get_image().save_png(path)
	if error != OK:
		failures += 1
	print("M1-47 evidence: ", evidence_path, " (", error, ")")
