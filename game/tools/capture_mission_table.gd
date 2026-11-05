## Windowed M1-09 evidence: the P-02 Mission Table in the real campaign.
## Run after run_tests.sh has imported assets:
##   Godot --path game --windowed --script res://tools/capture_mission_table.gd
## Writes production/qa/evidence/M1-09_*.png and M1-09_capture_probe.txt.
extends SceneTree

const CampaignScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const GateCatalog = preload("res://scripts/missions/chapter1_gate_catalog.gd")
const TableScript = preload("res://scripts/puzzles/p02_mission_table.gd")
var storage = preload("res://tools/support/isolated_storage.gd").new()
var campaign: Chapter1Campaign
var failures := 0
var probe: Array = []

func _init() -> void:
	if not storage.setup("M1-09-capture"):
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.always_on_top = true
	root.grab_focus()
	# The films have their own evidence; keep them from covering the table.
	CampaignCutscenePlayer.autoplay = false
	campaign = CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	root.add_child(campaign)
	await process_frame
	await _goto("EX-CH01-S07")
	campaign.route.perform("role_cards")
	campaign.hud.refresh_scene()
	await _capture("hud_plan_button")
	var table := campaign.hud.mission_table
	_expect(campaign.hud.open_mission_table("p02_shift1"), "the HUD opens the Mission Table for shift 1")
	_expect((table.find_child("Commit", true, false) as Button).disabled, "commit starts disabled until cards are shared and the plan is set")
	await _capture("shift1_cards")
	table.share_card("kai")
	table.share_card("amara")
	table.choose(1, "air_production", 2)
	table.choose(1, "light", "FULL")
	table.choose(1, "transfer", "HOLD")
	var preview: Dictionary = table.preview()
	_expect(bool(preview.accepted) and int(preview.forecast.final_state.E) == 15, "shift 1 preview E15 A7 with 2 overflow")
	await _capture("shift1_preview")
	table.request_commit()
	await _capture("shift1_confirm")
	await _stand_at("p02_shift1")
	var before_shift := int(campaign.director.query().current_shift)
	table.confirm_commit()
	await process_frame
	_expect(int(campaign.director.query().current_shift) == before_shift + 1 and int(campaign.director.snapshot().resources.E) == 15, "the confirmed shift 1 commits exactly its preview")
	# Play the documented Golden plan to the shift-5 alarm to show the task.
	campaign.route.mission_table().apply_worked_plan("golden", 1)
	for role_id in ["kai", "amara", "rafi", "mei"]:
		campaign.route.mission_table().share(role_id, 3)
	await _goto("EX-CH01-S10")
	campaign.route.perform("confirm_four_sheltered")
	campaign.hud.refresh_scene()
	_expect(campaign.hud.open_mission_table("p02_shift5_alarm"), "the HUD opens the alarm response")
	table.start_task()
	table.task_step(0)
	table.task_step(2)
	await _capture("shift5_stack_task")
	table.task_step(1)
	table.task_step(3)
	table.preview()
	await _capture("shift5_stack_preview")
	# 150% text at the same table, then back to the default size.
	table.close()
	_set_large_text(true)
	_expect(campaign.hud.open_mission_table("p02_shift5_alarm"), "the table reopens at 150% text")
	table.preview()
	await _capture("large_text")
	var commit := table.find_child("Commit", true, false) as Control
	probe.append("large text: viewport %s, frame %s, commit %s" % [str(campaign.hud.get_viewport_rect()), str(table._frame.get_global_rect()), str(commit.get_global_rect() if commit != null else Rect2())])
	_expect(commit != null and campaign.hud.get_viewport_rect().encloses(commit.get_global_rect()) and campaign.hud.get_viewport_rect().encloses(table._frame.get_global_rect()), "the table and Commit stay on screen at 150% text")
	table.close()
	_set_large_text(false)
	campaign.hud.open_mission_table("p02_shift5_alarm")
	table.preview()
	table.request_commit()
	await _stand_at("p02_shift5_alarm")
	table.confirm_commit()
	await process_frame
	_expect(int(campaign.director.snapshot().resources.K) == 2, "a complete STACK commits K2")
	await _goto("EX-CH01-S11")
	campaign.route.perform("verify_exposure_order")
	campaign.route.perform("return_water")
	campaign.hud.refresh_scene()
	campaign.hud.open_mission_table("p02_shifts6_7")
	table.preview()
	await _capture("shifts6_7_golden_projection")
	table.request_commit()
	await _capture("shifts6_7_confirm")
	await _stand_at("p02_shifts6_7")
	table.confirm_commit()
	await process_frame
	_expect(String(campaign.route.chapter_ready().ending) == "GOLDEN", "the Golden plan earns GOLDEN BLOOM in the real campaign")
	await _capture("ending_outcome")
	campaign.hud.panels.close_panel()
	campaign.free()
	storage.cleanup()
	probe.append("RESULT %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	var file := FileAccess.open(ProjectSettings.globalize_path("res://../production/qa/evidence/M1-09_capture_probe.txt"), FileAccess.WRITE)
	if file != null:
		file.store_string("\n".join(probe) + "\n")
	print("M1-09 MISSION TABLE CAPTURE RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)

func _goto(scene_id: String) -> void:
	campaign.route.p01_puzzle().apply_canonical_setup()
	while campaign.route.current_scene_id() != scene_id:
		var current: String = campaign.route.current_scene_id()
		var ids: Array = ["calibrate_probe", "span_probe", "recheck_probe", "inspect_packet", "compare_atmosphere"] if current == "EX-CH01-S03" else GateCatalog.targets_for_scene(current).map(func(spec): return String(spec.target_id))
		for target_id in ids:
			if TableScript.is_gate(target_id) and current == "EX-CH01-S10":
				var alarm: Dictionary = campaign.route.mission_table().alarm_state()
				if String(alarm.state) == "idle" and String(alarm.action) in ["PUMP", "STACK"]:
					break
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

func _expect(condition: bool, message: String) -> void:
	probe.append(("ok   " if condition else "FAIL ") + message)
	if not condition:
		failures += 1
		push_error("FAIL " + message)

func _capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../production/qa/evidence/M1-09_%s.png" % label)
	var error := root.get_texture().get_image().save_png(path)
	if error != OK:
		failures += 1
	probe.append("screenshot %s (%s)" % [path.get_file(), "saved" if error == OK else "error %d" % error])
	print("M1-09 evidence: ", path, " (", error, ")")
