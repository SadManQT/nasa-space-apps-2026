extends SceneTree

## Windowed evidence from the real campaign HUD, with isolated saves. Fixture
## choices earn each ending through P-02; no ending/predicate is overwritten.
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
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.always_on_top = true
	root.grab_focus()
	CampaignCutscenePlayer.autoplay = false
	for ending in ["GOLDEN", "BLOOM", "ALO_LOST", "MISSION_STOPPED"]:
		var route: RefCounted = Fixture.play(ending)
		var state: Dictionary = route.director().snapshot()
		state.scene_id = route.current_scene_id()
		state.mission_id = route.current_mission_id()
		state.route_runtime = route.snapshot()
		campaign = CampaignScene.instantiate() as Chapter1Campaign
		storage.configure(campaign)
		campaign.initial_snapshot = state
		root.add_child(campaign)
		await process_frame
		campaign.hud.open_outcome()
		_expect(campaign.hud.panels.active_panel() == "outcome" and campaign.director.query().paused, ending + ": production outcome opens with operations paused")
		await _capture(ending.to_lower())
		if ending == "GOLDEN":
			_press("ReviewReplay")
			for index in 7:
				await _capture("replay_shift%d" % (index + 1))
				_press("NextShift" if index < 6 else "ReadDebrief")
			await _capture("debrief")
			var source := campaign.hud.panels.find_child("Source_clowdsley_2021_shielding", true, false) as Button
			source.grab_focus()
			await _capture("debrief_water_sources")
			source.pressed.emit()
			await _capture("data_card")
			for child in campaign.hud.panels._body.get_children():
				if child is Button and child.text == "RETURN TO SCIENCE DEBRIEF":
					child.pressed.emit()
					break
			_press("DebriefQuestions")
			_press("Answer_day_air_0")
			await _capture("questions")
			_press("Answer_measurement_2")
			await _capture("questions_observed")
			_press("OutcomeContinue")
			_expect(not campaign.director.query().paused and campaign.route.current_scene_id() == "EX-CH01-S11" and not campaign.route.chapter_ready().ready, "Continue returns to required story gates without unlocking Chapter 2")
			campaign.hud.open_outcome()
			var large: Dictionary = campaign.director.snapshot()
			large.accessibility.large_text = true
			campaign.director.restore_snapshot(large)
			campaign.hud.panels.bind_query(campaign.query().merged({"outcome": campaign.route.outcome_view()}, true))
			await _capture("large_text")
			root.size = Vector2i(640, 480)
			root.content_scale_size = Vector2i(640, 480)
			await _capture("compact_large_text")
			_press("OutcomeRetry")
			_expect(int(campaign.director.query().current_shift) == 5 and campaign.route.outcome_view().is_empty(), "Retry restores the physical checkpoint before shifts 6–7")
			root.size = Vector2i(1280, 720)
			root.content_scale_size = Vector2i(1280, 720)
		campaign.hud.panels.close_panel()
		campaign.free()
		await process_frame
	storage.cleanup()
	var line := "M1-19 OUTCOME CAPTURE RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures]
	probe.append(line)
	var file := FileAccess.open(ProjectSettings.globalize_path("res://../production/qa/evidence/M1-19_capture_probe.txt"), FileAccess.WRITE)
	if file != null:
		file.store_string("\n".join(probe) + "\n")
	print(line)
	quit(0 if failures == 0 else 1)

func _press(id: String) -> void:
	var button := campaign.hud.panels.find_child(id, true, false) as Button
	_expect(button != null, "control available: " + id)
	if button != null:
		button.grab_focus()
		button.pressed.emit()

func _capture(label: String) -> void:
	for frame in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	var panels := campaign.hud.panels
	var viewport := panels.get_viewport_rect()
	_expect(viewport.encloses(panels._panel.get_global_rect()) and viewport.encloses(panels._close_button.get_global_rect()), label + ": panel and Close fit the viewport")
	var focused := root.gui_get_focus_owner()
	if focused != null:
		_expect(viewport.encloses(focused.get_global_rect()), label + ": focused control remains visible")
	var path := ProjectSettings.globalize_path("res://../production/qa/evidence/M1-19_%s.png" % label)
	_expect(root.get_texture().get_image().save_png(path) == OK, "screenshot: " + path.get_file())
	probe.append("%s: viewport=%s panel=%s focus=%s" % [label, str(viewport), str(panels._panel.get_global_rect()), str(focused.get_global_rect()) if focused != null else "none"])

func _expect(value: bool, message: String) -> void:
	probe.append(("ok   " if value else "FAIL ") + message)
	if not value:
		failures += 1
		push_error("FAIL " + message)
