## Windowed M1-37 evidence: the crew choice over the real title, then the
## Class Mission Table, the privacy hand-off and the team-plan sign-off.
##   Godot --path game --resolution 1280x720 -s tools/capture_class_mode_m137.gd -- --capture
## Writes production/qa/evidence/M1-37_*.png.
extends SceneTree

const MainScene = preload("res://scenes/main.tscn")
const MainScript = preload("res://scripts/main.gd")
const CampaignScript = preload("res://scripts/campaign/chapter1_campaign.gd")
const GateCatalog = preload("res://scripts/missions/chapter1_gate_catalog.gd")
const PlantInput = preload("res://tools/support/p01_input_fixture.gd")
const PlanFixture = preload("res://tools/support/p02_plan_fixture.gd")
const PanelScene = preload("res://scenes/ui/mission_table_panel.tscn")

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var main := MainScene.instantiate()
	# Isolated save paths: the capture never touches a real slot.
	main.set("save_path", OS.get_temp_dir().path_join("lla-m137-capture.json"))
	main.set("legacy_save_path", OS.get_temp_dir().path_join("lla-m137-legacy.json"))
	root.add_child(main)
	for i in 240:
		await process_frame
		if main.get("_menu") != null and is_instance_valid(main.get("_menu")) and main.get("_menu").is_visible_in_tree():
			break
	for i in 30:
		await process_frame
	main.call("_choose_crew")
	await _capture("crew_choice")
	main.call("_close_crew_choice")
	main.queue_free()
	await process_frame

	var fresh: Dictionary = MainScript.build_new_expedition_snapshot({"mode": "class", "players": 3})
	var route: RefCounted = CampaignScript.restore_session(fresh.snapshot).route
	PlanFixture.prepare(route)
	var attempts := 0
	while route.current_scene_id() != "EX-CH01-S07" and attempts < 12:
		attempts += 1
		var ids: Array = []
		if route.current_scene_id() == "EX-CH01-S03":
			ids = ["calibrate_probe", "span_probe", "recheck_probe", "inspect_packet", "compare_atmosphere"]
		else:
			for spec in GateCatalog.targets_for_scene(route.current_scene_id()):
				ids.append(String(spec.target_id))
		for target_id in ids:
			if target_id == "calibrate_probe":
				PlantInput.complete_probe_transfer(route)
			route.perform(target_id, PlantInput.payload(target_id))
		if not bool(route.advance_scene().get("accepted", false)):
			break
	route.perform("role_cards")
	var panel := PanelScene.instantiate() as MissionTablePanel
	root.add_child(panel)
	await process_frame
	panel.open(route, "p02_shift1")
	await _show_notes(panel)
	await _capture("class_table_private_notes")
	panel.read_card()
	await _capture("handoff_cover")
	panel.handoff().reveal()
	await _capture("handoff_revealed")
	panel.handoff().hide_card()
	panel.handoff().reveal()
	panel.handoff().hide_card()
	panel.share_card("kai")
	await _show_notes(panel)
	await _capture("class_table_after_read_share")
	panel.share_card("amara")
	panel.preview()
	panel.request_commit()
	panel.sign_off("kai")
	panel.sign_off("amara")
	await _capture("team_plan_two_signed")
	panel.sign_off("mei")
	panel.sign_off("rafi")
	await _capture("team_plan_all_signed")
	panel.queue_free()
	# Later puzzles (every puzzle but P-02): the real sign-off panel, two of four signed.
	var signoff := ClassSignoffPanel.new()
	root.add_child(signoff)
	signoff.open_for(null, {"focus_label": "P-13 · The storm plan", "crew": route.director().crew(),
		"required_roles": ["kai", "amara", "mei", "rafi"], "signed_roles": ["kai", "amara"]})
	await _capture("later_puzzle_signoff")
	print("M1-37 CAPTURE RESULT: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

# The crew-notes column sits below the plan and forecast; scroll to it.
func _show_notes(panel: Control) -> void:
	for i in 3:
		await process_frame
	var scroll := panel.find_child("TableBodyScroll", true, false) as ScrollContainer
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)

func _capture(label: String) -> void:
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../production/qa/evidence/M1-37_%s.png" % label)
	var error := root.get_texture().get_image().save_png(path)
	if error != OK:
		failures += 1
	print("M1-37 evidence: ", path, " (", error, ")")
