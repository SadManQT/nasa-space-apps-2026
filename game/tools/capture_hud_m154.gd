## Windowed M1-54 evidence (doc 25 §2.2 states on the clean HUD). The "after"
## of the before/after pair is the moment of M1-09_hud_plan_button.png: the
## start of EX-CH01-S07 with Amara's first line. Run after run_tests.sh:
##   Godot --path game --windowed --resolution 1280x720 --script res://tools/capture_hud_m154.gd
## Writes production/qa/evidence/M1-54_*.png; the printed RESULT line is the evidence.
extends SceneTree
const PlantInput = preload("res://tools/support/p01_input_fixture.gd")

const CampaignScene: PackedScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const Gates = preload("res://scripts/missions/chapter1_gate_catalog.gd")
const PlanFixture = preload("res://tools/support/p02_plan_fixture.gd")
var storage = preload("res://tools/support/isolated_storage.gd").new()
var campaign: Chapter1Campaign
var failures := 0

func _init() -> void:
	CampaignCutscenePlayer.autoplay = false
	if not storage.setup("M1-54-capture"):
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	campaign = CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	root.add_child(campaign)
	await process_frame
	var hud := campaign.hud
	PlanFixture.prepare(campaign.route)
	for scene_id in Gates.scene_ids():
		if scene_id == "EX-CH01-S07":
			break
		var targets := Gates.targets_for_scene(scene_id)
		if scene_id == "EX-CH01-S03":
			targets.push_back(targets.pop_front())
			targets.push_back(targets.pop_at(3))
		for target in targets:
			campaign.route.perform(String(target.target_id), PlantInput.payload(String(target.target_id)))
		campaign.advance_scene()
		if campaign.loading:
			await campaign.wait_loading()
	await _capture("after_s07_dialogue")  # pair: M1-09_hud_plan_button.png
	while (hud.get("_dialogue_bar") as Control).visible and not (hud.get("_next_line") as Button).disabled:
		hud.call("_on_next_line")
	await create_timer(0.6).timeout
	await _capture("walking")
	hud.panels.open_panel("what_now")
	await _capture("what_now")
	hud.panels.close_panel()
	hud.panels.open_panel("pause")
	await _capture("pause")
	hud.panels.open_panel("settings_accessibility")
	await _capture("settings")
	hud.panels.close_panel()
	var first: Dictionary = Gates.targets_for_scene("EX-CH01-S07")[0]
	hud.refresh_after_action(campaign.route.perform(String(first.target_id)))
	hud.call("_refresh_query")
	await _capture("toast_and_strip")
	hud.panels.set_accessibility({"large_text": true})
	hud.apply_accessibility()
	await _capture("large_text")
	print("M1-54 CAPTURE RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	storage.cleanup()
	quit(0 if failures == 0 else 1)

func _capture(label: String) -> void:
	await create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../production/qa/evidence/M1-54_%s.png" % label)
	var error := root.get_texture().get_image().save_png(path)
	if error != OK:
		failures += 1
	print("M1-54 evidence: M1-54_%s.png (%s)" % [label, error])
