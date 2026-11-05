## Windowed M1-37 evidence: Class mode on one machine, from the title's crew
## choice through private crew notes, the Mission Table and the team plan.
## Run after run_tests.sh has imported assets:
##   Godot --path game --windowed --script res://tools/capture_class_mode_m137.gd
## Writes production/qa/evidence/M1-37_*.png, M1-37_capture_probe.txt and, when
## --frames-dir=<dir> is given, a 2 fps frame sequence of one scripted Class
## shift for the walkthrough video (the shell runner encodes it).
extends SceneTree

const MainScene = preload("res://scenes/main.tscn")
const GateCatalog = preload("res://scripts/missions/chapter1_gate_catalog.gd")
const TableScript = preload("res://scripts/puzzles/p02_mission_table.gd")
const CLASS4 := {"mode": "class", "players": 4}
const SOLO := {"mode": "solo", "players": 1}
var storage = preload("res://tools/support/isolated_storage.gd").new()
var main: Node
var campaign: Chapter1Campaign
var failures := 0
var probe: Array = []
var frames_dir := ""
var frame_index := 0

func _init() -> void:
	if not storage.setup("M1-37-capture"):
		quit(1)
		return
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--frames-dir="):
			frames_dir = argument.trim_prefix("--frames-dir=")
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.always_on_top = true
	root.grab_focus()
	CampaignCutscenePlayer.autoplay = false
	main = MainScene.instantiate()
	storage.configure(main)
	root.add_child(main)
	while not main.title_ready:
		await process_frame
	var menu := main.get_node("TitleLayer/MainMenu") as MainMenu
	menu.set_crew(CLASS4)
	menu._show_briefing()
	await _capture("title_briefing_class4")
	await _hold(4.0)
	menu.set_crew({"mode": "class", "players": 2})
	await _capture("title_briefing_class2")
	menu.set_crew(CLASS4)
	_expect(menu.crew_settings() == CLASS4, "the briefing holds the Class 4 choice")
	menu._hide_briefing()
	await main._launch_campaign({})
	await process_frame
	campaign = main.get_node("Chapter1Campaign") as Chapter1Campaign
	_expect(campaign != null and campaign.query().get("crew", {}) == CLASS4, "the title's crew choice starts the expedition in Class mode")
	await _goto("EX-CH01-S07")
	campaign.route.perform("role_cards")
	campaign.hud.refresh_scene()
	await _capture("hud_crew_notes_button")
	await _hold(4.0)
	# Player 1 (Kai) and Player 2 (Amara) read their notes privately.
	_expect(campaign.hud.open_crew_notes(), "CREW NOTES opens the hand-off")
	var cards := campaign.hud.crew_cards
	await _capture("handoff_cover_kai")
	await _hold(5.0)
	cards.reveal()
	await _capture("handoff_reveal_kai")
	await _hold(8.0)
	cards.hide_card()
	await _capture("handoff_cover_amara")
	await _hold(4.0)
	cards.reveal()
	await _hold(8.0)
	cards.hide_card()
	await process_frame
	var receipts: Array = campaign.route.mission_table().role_cards(0)
	_expect(bool(receipts[0].read) and bool(receipts[1].read), "both private reads are recorded")
	_expect(campaign.hud.open_mission_table("p02_shift1"), "the HUD opens the Mission Table in Class mode")
	var table := campaign.hud.mission_table
	_expect(table.crew() == CLASS4 and table.find_child("CrewModeChip", true, false) != null, "the table shows the Class chip")
	await _capture("table_class_private_notes")
	await _hold(6.0)
	_expect(not _text(table).contains("The battery holds 20"), "no fact appears on the shared table")
	table.share_card("kai")
	await _hold(3.0)
	table.share_card("amara")
	table.choose(1, "air_production", 2)
	await _hold(3.0)
	table.choose(1, "light", "FULL")
	await _hold(3.0)
	table.choose(1, "transfer", "HOLD")
	var preview: Dictionary = table.preview()
	_expect(bool(preview.accepted) and int(preview.forecast.final_state.E) == 15, "shift 1 preview E15")
	await _capture("table_class_preview")
	await _hold(6.0)
	table.request_commit()
	await _capture("team_plan_waiting")
	await _hold(5.0)
	table.sign_off("kai")
	await _hold(3.0)
	table.sign_off("amara")
	await _capture("team_plan_two_signed")
	await _hold(4.0)
	table.sign_off("mei")
	await _hold(3.0)
	table.sign_off("rafi")
	await _capture("team_plan_all_signed")
	await _hold(5.0)
	var lock := table.find_child("ConfirmCommit", true, false) as Button
	_expect(lock != null and not lock.disabled, "four signatures enable the operator lock-in")
	await _stand_at("p02_shift1")
	var before_shift := int(campaign.director.query().current_shift)
	table.confirm_commit()
	await process_frame
	_expect(int(campaign.director.query().current_shift) == before_shift + 1 and int(campaign.director.snapshot().resources.E) == 15, "the signed plan commits exactly its preview")
	campaign.hud.refresh_scene()
	await _capture("hud_after_lock_in")
	await _hold(6.0)
	campaign.hud.panels.open_panel("settings_accessibility")
	await _capture("settings_crew_mode")
	campaign.hud.panels.close_panel()
	# 150% text on the hand-off.
	_set_large_text(true)
	_expect(campaign.hud.open_crew_notes(), "the hand-off reopens at 150% text")
	cards.reveal()
	await _capture("handoff_large_text")
	var hide_button := cards.find_child("Hide", true, false) as Control
	_expect(hide_button != null and campaign.hud.get_viewport_rect().encloses(hide_button.get_global_rect()), "the HIDE control stays on screen at 150% text")
	cards.cancel()
	_set_large_text(false)
	# Solo keeps its one-step confirmation.
	campaign.handle_ui_command({"verb": "set_crew", "payload": SOLO})
	_expect(campaign.query().get("crew", {}) == SOLO and not (campaign.hud.get("_crew_button") as Button).visible, "Settings returns to Solo and hides CREW NOTES")
	_expect(campaign.hud.open_mission_table("p02_stage_shift2"), "the table opens for the staged shift 2 in Solo")
	table.choose(2, "air_production", 0)
	table.choose(2, "light", "FULL")
	table.choose(2, "transfer", "HOLD")
	table.preview()
	table.request_commit()
	_expect(table.find_child("SoloNote", true, false) != null and table.find_child("SignOff_kai", true, false) == null, "Solo confirmation has no signature round")
	await _capture("solo_confirmation")
	table.cancel_confirm()
	table.close()
	campaign.free()
	storage.cleanup()
	probe.append("frames: %d" % frame_index)
	probe.append("RESULT %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	var file := FileAccess.open(ProjectSettings.globalize_path("res://../production/qa/evidence/M1-37_capture_probe.txt"), FileAccess.WRITE)
	if file != null:
		file.store_string("\n".join(probe) + "\n")
	print("M1-37 CLASS MODE CAPTURE RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)

func _goto(scene_id: String) -> void:
	while campaign.route.current_scene_id() != scene_id:
		var current: String = campaign.route.current_scene_id()
		var ids: Array = ["calibrate_probe", "span_probe", "recheck_probe", "inspect_packet", "compare_atmosphere"] if current == "EX-CH01-S03" else GateCatalog.targets_for_scene(current).map(func(spec): return String(spec.target_id))
		for target_id in ids:
			campaign.route.perform(target_id)
		if not bool(campaign.route.advance_scene().get("accepted", false)):
			_expect(false, "reach " + scene_id + " (stuck at " + current + ")")
			return
	campaign._sync_route_projection()
	campaign._refresh_world()
	await campaign.wait_loading()
	campaign.hud.refresh_scene()
	await process_frame

func _set_large_text(value: bool) -> void:
	var state: Dictionary = campaign.director.snapshot()
	state.accessibility.large_text = value
	campaign.director.restore_snapshot(state)
	campaign.hud.apply_accessibility()

func _stand_at(target_id: String) -> void:
	var target := campaign.physical_target(target_id)
	if target == null:
		_expect(false, "physical target " + target_id)
		return
	campaign._player.global_position = Vector3(target.global_position.x, 0.0, target.global_position.z + 1.0)
	campaign._player.velocity = Vector3.ZERO
	await physics_frame
	await physics_frame

func _text(node: Node) -> String:
	var parts: Array = []
	_collect(node, parts)
	return "\n".join(parts)

func _collect(node: Node, parts: Array) -> void:
	if node is CanvasItem and not (node as CanvasItem).visible:
		return
	if node is Label:
		parts.append((node as Label).text)
	elif node is Button:
		parts.append((node as Button).text)
	for child in node.get_children():
		_collect(child, parts)

func _expect(condition: bool, message: String) -> void:
	probe.append(("ok   " if condition else "FAIL ") + message)
	if not condition:
		failures += 1
		push_error("FAIL " + message)

## Real-time pause while frames are recorded at 2 fps for the walkthrough.
func _hold(seconds: float) -> void:
	if frames_dir.is_empty():
		return
	var remaining := seconds
	while remaining > 0.0:
		await create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		image.save_png(frames_dir.path_join("frame_%04d.png" % frame_index))
		frame_index += 1
		remaining -= 0.5

func _capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../production/qa/evidence/M1-37_%s.png" % label)
	var error := root.get_texture().get_image().save_png(path)
	if error != OK:
		failures += 1
	probe.append("screenshot %s (%s)" % [path.get_file(), "saved" if error == OK else "error %d" % error])
	print("M1-37 evidence: ", path, " (", error, ")")
	if not frames_dir.is_empty():
		await _hold(1.0)
