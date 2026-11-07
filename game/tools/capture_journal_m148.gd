## Windowed, isolated M1-48 evidence: every journal tab after EX-CH01-S03 and
## after EX-CH01-S12, the resume card in pause and on Continue, and the journal
## at 150% text. Run after run_tests.sh has imported assets:
##   Godot --path game --windowed --resolution 1280x720 --script res://tools/capture_journal_m148.gd
## Writes production/qa/evidence/M1-48_*.png and M1-48_probes.json; a Godot
## exit code alone is never evidence, the printed RESULT line is.
extends SceneTree
const PlantInput = preload("res://tools/support/p01_input_fixture.gd")

const CampaignScene: PackedScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const MainScene: PackedScene = preload("res://scenes/main.tscn")
const Gates = preload("res://scripts/missions/chapter1_gate_catalog.gd")
const PlanFixture = preload("res://tools/support/p02_plan_fixture.gd")
const TABS := ["now", "evidence", "garden", "decisions"]
var storage = preload("res://tools/support/isolated_storage.gd").new()
var campaign: Chapter1Campaign
var failures := 0
var probes := {}

func _init() -> void:
	# Main plays scene-entry films; this isolated UI capture keeps the journal in view.
	CampaignCutscenePlayer.autoplay = false
	if not storage.setup("M1-48-capture"):
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
	PlanFixture.prepare(campaign.route)
	var scenes := Gates.scene_ids()
	for index in scenes.size():
		var scene_id: String = scenes[index]
		if scene_id == "EX-CH01-S04":
			await _capture_tabs("s03")
			_probe_journal_layout("s03")
		await _confirm_choice(scene_id, scene_id + ("-OPT02" if scene_id in ["EX-CH01-S01", "EX-CH01-S06"] else "-OPT01"))
		var targets := Gates.targets_for_scene(scene_id)
		if scene_id == "EX-CH01-S03":
			targets.push_back(targets.pop_front())
			var compare: Dictionary = targets.pop_at(3)
			targets.push_back(compare)
		for target in targets:
			var result: Dictionary = campaign.route.perform(String(target.target_id), PlantInput.payload(String(target.target_id)))
			if not bool(result.get("accepted", false)):
				_probe("perform_" + String(target.target_id), false)
		if scene_id == "EX-CH01-S12":
			# Complete S12 on the route only, so Chapter 1 stays current and
			# every late capture belongs to Night One.
			var completed: Dictionary = campaign.route.advance_scene()
			_probe("s12_completes_on_route", bool(completed.get("accepted", false)) and bool(completed.get("chapter_complete", false)))
			campaign._sync_route_projection()
			campaign.hud.refresh_scene()
			await _capture_tabs("s12")
			_probe_journal_layout("s12")
			break
		var advanced: Dictionary = campaign.advance_scene()
		if not bool(advanced.get("accepted", false)):
			_probe("advance_" + scene_id, false)
		if campaign.loading:
			await campaign.wait_loading()
	_probe("chapter_one_traversed", campaign.route.chapter_ready().get("ready", false))
	# Pause shows the resume card.
	campaign.hud.panels.open_panel("pause")
	await _capture("resume_pause")
	var pause_card := campaign.hud.panels._body.get_node_or_null("ResumeCard")
	_probe("pause_shows_resume_card", pause_card != null and pause_card.find_children("ResumeLine*", "Label", true, false).size() <= 6)
	campaign.hud.panels.close_panel()
	# 150% text: Now and Evidence reflow.
	var next := campaign.director.snapshot()
	next.accessibility.large_text = true
	campaign.director.restore_snapshot(next)
	campaign.hud.apply_accessibility()
	campaign.hud._on_journal_pressed()
	await _capture("journal_150_now")
	_probe("large_text_tabs_fit", campaign.hud.get_viewport_rect().encloses(campaign.hud.panels._panel.get_global_rect()) and campaign.hud.get_viewport_rect().encloses(campaign.hud.panels._close_button.get_global_rect()))
	campaign.hud.panels.select_journal_tab("evidence")
	await _capture("journal_150_evidence")
	_probe("large_text_stacks_evidence_columns", campaign.hud.panels._body.get_node_or_null("EvidenceColumns") is VBoxContainer)
	var tab := campaign.hud.panels._side.get_node_or_null("Tab_evidence") as Button
	_probe("large_text_uses_150_percent_font", tab != null and tab.get_theme_font_size("font_size") == 21)
	campaign.hud.panels.close_panel()
	next = campaign.director.snapshot()
	next.accessibility.large_text = false
	campaign.director.restore_snapshot(next)
	campaign.hud.apply_accessibility()
	# Continue from the title: the saved checkpoint opens on "Previously at Aurora".
	var saved: Dictionary = campaign.save_campaign()
	_probe("checkpoint_saved_for_continue", bool(saved.get("accepted", false)))
	campaign.free()
	campaign = null
	await process_frame
	var main := MainScene.instantiate()
	storage.configure(main)
	root.add_child(main)
	# The title enables Continue only once its own boot has finished.
	for frame in 1200:
		await process_frame
		if bool(main.get("title_ready")):
			break
	_probe("title_ready_before_continue", bool(main.get("title_ready")))
	main.call("_continue_expedition")
	for frame in 600:
		await process_frame
		if main.get("_campaign") != null and not bool(main.get("_launching")):
			break
	var continued = main.get("_campaign")
	if continued == null:
		_probe("continue_launches_campaign", false)
	else:
		await continued.wait_loading()
		for frame in 10:
			await process_frame
		var active: String = continued.hud.panels.active_panel()
		_probe("continue_opens_resume_card", active == "resume")
		await _capture("resume_continue")
		var card: Node = continued.hud.panels._body.get_node_or_null("ResumeCard")
		_probe("continue_resume_card_has_lines", card != null and card.find_children("ResumeLine*", "Label", true, false).size() >= 2)
		continued.hud.panels.close_panel()
		_probe("continue_resumes_after_card", not bool(continued.director.query().get("paused", true)))
	main.queue_free()
	await process_frame
	_finish()

func _confirm_choice(scene_id: String, option_id: String) -> void:
	campaign.hud._decision_review.pressed.emit()
	await process_frame
	var option := campaign.hud.panels.find_child(option_id, true, false) as Button
	var confirm := campaign.hud.panels.find_child("ConfirmChoice", true, false) as Button
	if option == null or confirm == null:
		_probe("decision_review_" + scene_id, false)
		campaign.hud.panels.close_panel()
		return
	option.button_pressed = true
	option.pressed.emit()
	confirm.pressed.emit()
	await process_frame

func _capture_tabs(label: String) -> void:
	campaign.hud._on_journal_pressed()
	for tab in TABS:
		campaign.hud.panels.select_journal_tab(tab)
		await _capture("%s_%s" % [label, tab])
	campaign.hud.panels.close_panel()

func _probe_journal_layout(label: String) -> void:
	campaign.hud._on_journal_pressed()
	var panels := campaign.hud.panels
	_probe(label + "_panel_fits_window", campaign.hud.get_viewport_rect().encloses(panels._panel.get_global_rect()))
	_probe(label + "_close_control_visible", campaign.hud.get_viewport_rect().encloses(panels._close_button.get_global_rect()))
	var tabs := panels._side.find_children("Tab_*", "Button", false, false)
	_probe(label + "_four_tabs_44px", tabs.size() == 4 and tabs.all(func(button): return button.size.y >= 44.0))
	_probe(label + "_focus_on_open_tab", root.gui_get_focus_owner() != null and root.gui_get_focus_owner().name == "Tab_now")
	var tall := true
	for button in panels.find_children("*", "Button", true, false):
		if button.is_visible_in_tree() and button.size.y < 44.0:
			tall = false
	_probe(label + "_controls_44px", tall)
	panels.close_panel()

func _finish() -> void:
	var path := ProjectSettings.globalize_path("res://../production/qa/evidence/M1-48_probes.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		failures += 1
	else:
		file.store_string(JSON.stringify(probes, "\t"))
		file.close()
	if campaign != null and is_instance_valid(campaign):
		campaign.free()
	storage.cleanup()
	print("JOURNAL CAPTURE RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)

func _probe(label: String, passed: bool) -> void:
	probes[label] = passed
	if not passed:
		failures += 1
	print("M1-48 probe: ", label, " = ", passed)

func _capture(label: String) -> void:
	for frame in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	var evidence_path := "production/qa/evidence/M1-48_%s.png" % label
	var path := ProjectSettings.globalize_path("res://../" + evidence_path)
	var error := root.get_texture().get_image().save_png(path)
	if error != OK:
		failures += 1
	print("M1-48 evidence: ", evidence_path, " (", error, ")")
