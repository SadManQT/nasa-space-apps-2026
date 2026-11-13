## M1-129 kid-friendly flow (13 Nov review): a clean title menu, Shanto's credits role, the solid
## cerulean main action, the shorter pause menu, the eased follow camera, and the job-done card with
## its star challenge and "Job N of M" progress, in units and in a real production campaign.
## Isolated user:// storage; never touches the player's save or star tally.
extends SceneTree

const CampaignScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
var storage = preload("res://tools/support/isolated_storage.gd").new()
var checks := 0
var failures := 0

func _init() -> void:
	if not storage.setup("kid_friendly_ui"):
		push_error("Unable to isolate test storage.")
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	await _title_menu()
	_credits()
	_primary_palette()
	await _pause_menu()
	_camera_easing()
	_seat_tuning()
	await _job_feedback_unit()
	await _campaign_job_done()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(JobFeedback.STARS_PATH))
	storage.cleanup()
	print("KID FRIENDLY UI RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _title_menu() -> void:
	var menu := load("res://scenes/ui/main_menu.tscn").instantiate() as MainMenu
	root.add_child(menu)
	await process_frame
	menu.setup({"checkpoint_id": "EX-CH01-S02-CHECKPOINT", "scene_id": "EX-CH01-S02"})
	await process_frame
	var note := menu.get("_save_note") as Label
	_check(not note.visible, "a saved game shows no checkpoint line on the title")
	_check(not _text(menu).contains("EX-CH") and not _text(menu).contains("CHECKPOINT"), "no internal checkpoint code anywhere on the title")
	_check(not menu._continue_button.disabled and menu._continue_button.text == "Continue expedition", "Continue stays available for a real save")
	menu.show_note("Checkpoint could not be opened. Saved files are preserved.")
	_check(note.visible and note.text.contains("could not"), "a load problem is still explained on the title")
	menu.setup({})
	await process_frame
	_check(not note.visible and menu._continue_button.disabled and menu._continue_button.text == "Continue", "no save: a quiet disabled Continue and no note")
	menu.free()

func _credits() -> void:
	var shanto: Dictionary = {}
	for member in CreditsPanel.TEAM_ROSTER:
		_check(String(member.role) != "Presenter", "credits list build roles, not Presenter: " + String(member.name))
		if String(member.name).begins_with("Shahariar Rahman Shanto"):
			shanto = member
	var role := String(shanto.get("role", ""))
	_check(role.contains("storyline") and role.contains("UI/UX") and role.contains("modelling"), "Shanto credited for storyline updates, UI/UX and modelling: " + role)
	var readme := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://").path_join("../README.md").simplify_path())
	_check(readme.contains("| Shahariar Rahman Shanto | Storyline updates · UI/UX · 3D modelling |"), "README team table matches the in-game credits")

func _primary_palette() -> void:
	var button := UiDesign.make_primary(UiDesign.button("Resume"))
	for state in ["normal", "hover", "pressed"]:
		var box := button.get_theme_stylebox(state)
		_check(box is StyleBoxFlat, "primary %s is a solid fill, not the retired gradient" % state)
	var normal := button.get_theme_stylebox("normal") as StyleBoxFlat
	_check(normal != null and normal.bg_color.is_equal_approx(UiDesign.colour("accent")), "primary action uses the house cerulean")
	_check(UiKit.contrast_ratio(UiDesign.colour("ink"), UiDesign.colour("accent")) >= 4.5, "ink text on cerulean passes 4.5:1")
	var hover := button.get_theme_stylebox("hover") as StyleBoxFlat
	_check(hover != null and hover.bg_color.get_luminance() > normal.bg_color.get_luminance(), "hover is a lighter blue")
	var focus := button.get_theme_stylebox("focus") as StyleBoxFlat
	_check(focus != null and not focus.draw_center and focus.border_width_left >= 2, "keyboard focus keeps a clear ring on the primary action")
	button.free()
	var theme := load("res://resources/ui/lla_theme.tres") as Theme
	_check(theme.get_stylebox("normal", "PrimaryButton") is StyleBoxFlat, "the saved theme's PrimaryButton is solid cerulean too")

func _pause_menu() -> void:
	var panels := load("res://scenes/ui/campaign_panels.tscn").instantiate() as CampaignPanels
	root.add_child(panels)
	await process_frame
	var opened := []
	panels.set_pause_actions([
		{"label": "What now", "name": "WhatNow", "action": func() -> void: opened.append("what_now")},
		{"label": "Settings", "name": "Settings", "action": func() -> void: opened.append("settings")},
		{"label": "Save and quit", "name": "SaveAndQuit", "action": func() -> void: opened.append("quit")},
		{"label": "Greenhouse", "name": "Open_greenhouse", "action": func() -> void: opened.append("greenhouse")},
		{"label": "Rover Dashboard", "name": "Open_rover", "action": func() -> void: opened.append("rover")},
	])
	panels.set_content_top(64)
	panels.open_panel("pause")
	await process_frame
	var body: VBoxContainer = panels._body
	var resume := body.get_child(0) as Button
	_check(resume != null and resume.name == "Resume" and resume.get_theme_stylebox("normal") is StyleBoxFlat, "pause leads with a solid cerulean Resume")
	var tools := body.find_child("StationTools", true, false) as GridContainer
	var more := body.find_child("MoreTools", true, false) as Button
	_check(tools != null and not tools.visible and more != null, "station tools wait behind one toggle")
	_check(body.find_child("SaveAndQuit", true, false) is Button and body.find_child("WhatNow", true, false) is Button, "everyday actions stay one click away")
	more.button_pressed = true
	await process_frame
	_check(tools.visible and tools.get_child_count() == 2, "the toggle reveals every station tool")
	(tools.get_child(0) as Button).pressed.emit()
	_check(opened.has("greenhouse"), "a revealed tool still opens its panel")
	_check(not String(CampaignPanels.PANEL_DEFINITIONS.pause.description).contains("clock"), "pause explains itself in plain words")
	panels.free()

func _camera_easing() -> void:
	var camera := FollowCamera.new()
	camera._snap = false
	var eased := camera._eased_room(1.0, 0.4, 1.0 / 60.0, 3.3)
	_check(eased < 1.0 and eased >= 0.4 and eased <= 0.4 + FollowCamera.PULL_IN_SLACK_M / 3.3 + 0.0001, "an obstacle pulls the arm in fast but within the safe slack: %.3f" % eased)
	var settle := 1.0
	for frame in 30:
		settle = camera._eased_room(settle, 0.4, 1.0 / 60.0, 3.3)
	_check(is_equal_approx(snappedf(settle, 0.001), 0.4), "the arm reaches the obstacle distance within half a second")
	_check(camera._eased_room(0.4, 1.0, 1.0 / 60.0, 3.3) < 0.5, "the arm eases back out slowly")
	camera._snap = true
	_check(is_equal_approx(camera._eased_room(1.0, 0.4, 1.0 / 60.0, 3.3), 0.4), "a placement reset takes the new room at once")
	camera.free()

func _seat_tuning() -> void:
	for cast in ["amara", "ferreira", "kai", "mei", "rafi"]:
		var tuning := load("res://resources/player/ch_%s.tres" % cast) as LocomotionTuning
		_check(tuning != null and tuning.seat_recline_degrees <= 10.0 and tuning.seat_pelvis_height > 0.5 and tuning.seat_pelvis_height < 0.6 and tuning.seat_pelvis_forward > 0.05, cast + " has a measured, modest seat fit")

func _job_feedback_unit() -> void:
	JobFeedback.save_stars(0)
	var feedback := JobFeedback.new()
	root.add_child(feedback)
	await process_frame
	_check(not feedback.is_showing(), "job card starts hidden")
	feedback.show_done("Power path on. Extra sunlight now has a use.", "Battery: storing", "Check what happened at the table", "Switch on the power path")
	_check(feedback.is_showing() and feedback.is_challenge_active(), "a hands-on job shows the card and its star challenge")
	var label := feedback.find_child("ChallengeLabel", true, false) as Label
	_check(label.text.contains("Switch on the power path") and label.text.contains("Click"), "the challenge names the job and how to play: " + label.text)
	var next := feedback.find_child("Next", true, false) as Label
	_check(next.visible and next.text.contains("Check what happened"), "the card says what comes next")
	var zone := feedback.zone()
	_check(zone.x >= 0.1 and zone.y <= 0.9 and zone.y > zone.x, "the green band sits inside the gauge")
	_check(feedback.resolve_at((zone.x + zone.y) * 0.5), "a press inside the green earns a star")
	_check(JobFeedback.stars() == 1 and not feedback.is_challenge_active(), "the star is saved and the challenge ends")
	feedback.show_done("Sorted.", "", "", "Sort the facts")
	var miss_at := feedback.zone().x - 0.05 if feedback.zone().x > 0.2 else feedback.zone().y + 0.05
	_check(not feedback.resolve_at(miss_at) and JobFeedback.stars() == 1, "a miss is gentle and costs nothing")
	feedback.show_done("Choice recorded.")
	_check(feedback.is_showing() and not feedback.is_challenge_active() and not feedback.try_star(), "decisions get the card without a challenge")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	feedback.show_done("Done.", "", "", "Count the crew")
	feedback._input(click)
	_check(not feedback.is_challenge_active(), "one click plays the challenge")
	feedback.hide_now()
	_check(not feedback.is_showing(), "the card can be dismissed at once (a panel opening)")
	_check(JobFeedback.plain_meter("Reserves unchanged: Battery E:14 - Air A:6") == "Reserves unchanged: Battery 14 · Air 6", "meter lines drop station letters: " + JobFeedback.plain_meter("Reserves unchanged: Battery E:14 - Air A:6"))
	var headline := feedback.find_child("Headline", true, false) as Label
	_check(headline.autowrap_mode == TextServer.AUTOWRAP_OFF, "the headline never wraps letter by letter")
	_check(JobFeedback.progress_text(1, 3, 0) == "●○○  Job 2 of 3", "progress reads Job 2 of 3")
	_check(JobFeedback.progress_text(0, 1, 0).is_empty() and JobFeedback.progress_text(0, 1, 2) == "★ 2", "one-job scenes show only the stars")
	feedback.free()

func _campaign_job_done() -> void:
	JobFeedback.save_stars(0)
	CampaignCutscenePlayer.autoplay = false
	var campaign := CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	root.add_child(campaign)
	for frame in 900:
		await process_frame
		if not campaign.loading and campaign.hud != null and campaign._player != null:
			break
	var hud = campaign.hud
	_check(hud != null and hud._progress != null, "production HUD builds the job progress line")
	if hud == null:
		campaign.free()
		return
	await process_frame
	_check(hud._progress.visible and String(hud._progress.text).contains("Job 1 of"), "the first scene shows Job 1 of its jobs: " + String(hud._progress.text))
	var target: Node3D = campaign.physical_target("commission_route")
	_check(target != null, "the opening job has a real target")
	if target == null:
		campaign.free()
		return
	campaign._player.position = target.position + Vector3(0.0, -target.position.y, 1.0)
	await physics_frame
	var result: Dictionary = campaign.perform_target("commission_route")
	await process_frame
	_check(bool(result.get("accepted", false)), "the opening job is done through the real runtime")
	var card: JobFeedback = hud._job_feedback
	_check(card.is_showing() and card.is_challenge_active(), "the job-done card and star challenge appear after a hands-on job")
	var card_panel := card.find_child("JobDoneCard", true, false) as Control
	for frame in 3:
		await process_frame
	var view := card_panel.get_viewport_rect().size
	var rect := Rect2(card_panel.position, card_panel.size)
	_check(rect.position.y < view.y * 0.25 and rect.end.y < view.y * 0.62, "the card stays in the upper part of the screen, clear of the subtitles: %s in %s" % [str(rect), str(view)])
	var result_label := card.find_child("Result", true, false) as Label
	_check(result_label.text.begins_with("Power path on"), "the card shows the job's own result line: " + result_label.text)
	_check(not hud._toast.visible or hud._toast.modulate.a < 1.0, "the top-right toast steps aside for the card")
	_check(String(hud._status.text).begins_with("Power path on"), "the result stays on record for What now and Last result")
	_check(String(hud._progress.text).contains("Job 2 of"), "progress advances to the next job: " + String(hud._progress.text))
	var zone: Vector2 = card.zone()
	card.resolve_at((zone.x + zone.y) * 0.5)
	await process_frame
	_check(String(hud._progress.text).contains("★ 1"), "an earned star shows on the goal card: " + String(hud._progress.text))
	hud.panels.open_panel("pause")
	await process_frame
	_check(not card.is_showing(), "opening the pause menu clears the card")
	hud.panels.close_panel()
	campaign.free()
	await process_frame

func _text(node: Node) -> String:
	var out := ""
	if node is Label and (node as Label).visible:
		out += (node as Label).text + "\n"
	elif node is Button:
		out += (node as Button).text + "\n"
	for child in node.get_children():
		out += _text(child)
	return out

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL " + message)
