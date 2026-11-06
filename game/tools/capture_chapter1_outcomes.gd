## Actual Godot-window evidence. Fixtures make real choices through the route;
## screenshots use the production campaign, HUD, panel shell and source cards.
extends SceneTree
const Fixture = preload("res://tools/support/chapter1_outcome_fixture.gd")
const CampaignScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
var storage = preload("res://tools/support/isolated_storage.gd").new()
var campaign: Chapter1Campaign
var failures := 0
var probe: Array[String] = []

func _init() -> void:
	if not storage.setup("M1-19-capture"):
		quit(1)
		return
	var prepared: bool = storage.prepare_rendering_cache()
	_expect(prepared, "isolated shader-cache directories prepared")
	if not prepared:
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	root.always_on_top = true
	root.grab_focus()
	CampaignCutscenePlayer.autoplay = false
	for ending in ["BLOOM", "ALO_LOST", "MISSION_STOPPED", "GOLDEN"]:
		var route: RefCounted = Fixture.play(ending)
		var state: Dictionary = route.director().snapshot()
		state.merge({"scene_id": route.current_scene_id(), "mission_id": route.current_mission_id(), "completed_scene_ids": route.completed_scene_ids(), "route_runtime": route.snapshot().merged({"chapter": 1})}, true)
		campaign = CampaignScene.instantiate() as Chapter1Campaign
		storage.configure(campaign)
		campaign.initial_snapshot = state
		root.add_child(campaign)
		await process_frame
		_expect(campaign.hud.show_chapter1_outcome(), ending + " opens from actual saved route")
		var panels := campaign.hud.panels
		_expect((panels.find_child("EndingContinue", true, false) != null) == (ending in ["BLOOM", "GOLDEN"]), ending + " Continue follows safe-ending gate")
		if ending in ["BLOOM", "GOLDEN"]:
			_expect((panels.find_child("EndingContinue", true, false) as Button).disabled, ending + " waits for the physical review task")
		await _capture(ending.to_lower())
		if ending == "GOLDEN":
			(panels.find_child("ReviewDecisions", true, false) as Button).pressed.emit()
			for shift in 5:
				(panels.find_child("ReplayNext", true, false) as Button).pressed.emit()
			await _capture("decision_replay")
			(panels.find_child("ReplayNext", true, false) as Button).pressed.emit()
			(panels.find_child("ReplayNext", true, false) as Button).pressed.emit()
			for index in 3:
				(panels.find_child("Answer%d" % int([0, 1, 2][index]), true, false) as Button).pressed.emit()
				await _capture("science_debrief_%d" % (index + 1))
				if index == 2:
					(panels.find_child("DebriefSource", true, false) as Button).grab_focus()
					await _capture("science_feedback")
				if index < 2:
					(panels.find_child("DebriefNext", true, false) as Button).pressed.emit()
			(panels.find_child("DebriefSource", true, false) as Button).pressed.emit()
			await _capture("nasa_data_card")
			(panels.find_child("BackToDebrief", true, false) as Button).pressed.emit()
			panels.set_accessibility({"large_text": true})
			await _capture("debrief_large_text")
			campaign.hud.show_chapter1_outcome()
			await _capture("golden_large_text")
			(panels.find_child("ReviewDecisions", true, false) as Button).pressed.emit()
			await _capture("replay_large_text")
			panels.close_panel()
			campaign.hud.show_chapter1_outcome()
			(panels.find_child("EndingRetry", true, false) as Button).pressed.emit()
			_expect(int(campaign.director.query().current_shift) == 5, "actual Retry restores pre-final-shift checkpoint")
			await _capture("retry_checkpoint")
		campaign.free()
	storage.cleanup()
	var file := FileAccess.open("res://../production/qa/evidence/M1-19_capture_probe.txt", FileAccess.WRITE)
	file.store_string("\n".join(probe) + "\n")
	print("M1-19 CAPTURE RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)

func _capture(label: String) -> void:
	await create_timer(0.35).timeout
	if label in ["bloom", "golden", "golden_large_text"]:
		var reason := campaign.hud.panels.find_child("EndingContinueReason", true, false) as Control
		_expect(reason != null, label + " shows the next physical task")
		if reason != null:
			campaign.hud.panels._scroll.ensure_control_visible(reason)
	await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../production/qa/evidence/M1-19_%s.png" % label)
	var result := root.get_texture().get_image().save_png(path)
	_expect(result == OK, "screenshot " + path.get_file())

func _expect(condition: bool, message: String) -> void:
	probe.append(("ok " if condition else "FAIL ") + message)
	if not condition:
		failures += 1
		push_error("FAIL " + message)
