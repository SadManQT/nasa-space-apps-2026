## Windowed, isolated M1-47 evidence. Run after run_tests.sh has imported assets:
## Godot --path game --windowed --script res://tools/capture_story_log.gd
extends SceneTree

const CampaignScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
var storage = preload("res://tools/support/isolated_storage.gd").new()
var campaign: Chapter1Campaign
var failures := 0

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
	campaign.hud._decision_review.pressed.emit()
	await process_frame
	var option := campaign.hud.panels.find_child("EX-CH01-S01-OPT02", true, false) as Button
	option.button_pressed = true
	option.pressed.emit()
	await _capture("preview")
	if not campaign.director.snapshot().story_log.choices.is_empty():
		failures += 1
	(campaign.hud.panels.find_child("ConfirmChoice", true, false) as Button).pressed.emit()
	if campaign.director.snapshot().story_log.choices.get("EX-CH01-S01-CHOICE", {}).get("option_id") != "EX-CH01-S01-OPT02":
		failures += 1
	campaign.hud._decision_review.pressed.emit()
	await _capture("recorded")
	campaign.hud.panels.close_panel()
	# Exercise long catalog labels and keyboard-reachable confirmation at 150%.
	var next := campaign.director.snapshot()
	next.accessibility.large_text = true
	campaign.director.restore_snapshot(next)
	campaign.route.start_at("EX-CH01-S06")
	campaign._sync_route_projection()
	campaign.hud.refresh_scene()
	campaign.hud._decision_review.pressed.emit()
	await process_frame
	option = campaign.hud.panels.find_child("EX-CH01-S06-OPT02", true, false) as Button
	option.button_pressed = true
	option.pressed.emit()
	var confirm := campaign.hud.panels.find_child("ConfirmChoice", true, false) as Button
	confirm.grab_focus()
	await _capture("large_text")
	if not campaign.hud.get_viewport_rect().encloses(confirm.get_global_rect()):
		failures += 1
	campaign.free()
	storage.cleanup()
	print("STORY LOG CAPTURE RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)

func _capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../production/qa/evidence/M1-47_%s.png" % label)
	var error := root.get_texture().get_image().save_png(path)
	if error != OK:
		failures += 1
	print("M1-47 evidence: ", path, " (", error, ")")
