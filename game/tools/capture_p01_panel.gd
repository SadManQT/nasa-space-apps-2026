extends SceneTree

const CampaignScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const Gates = preload("res://scripts/missions/chapter1_gate_catalog.gd")
const Inputs = preload("res://tools/support/p01_input_fixture.gd")
var storage = preload("res://tools/support/isolated_storage.gd").new()
var campaign: Chapter1Campaign
var panel: P01Panel
var failures := 0
var probe: Array[String] = []
var shots: Array[String] = []

func _init() -> void:
	CampaignCutscenePlayer.autoplay = false
	if not storage.setup("M1-08-capture") or not storage.prepare_rendering_cache():
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	root.always_on_top = true
	root.grab_focus()
	campaign = CampaignScene.instantiate()
	storage.configure(campaign)
	root.add_child(campaign)
	await process_frame
	campaign.hud.panels.hint_player.seen_path = storage.directory.path_join("how-to.cfg")
	while campaign.route.current_scene_id() != "EX-CH01-S03":
		for spec in Gates.targets_for_scene(campaign.route.current_scene_id()):
			campaign.route.perform(String(spec.target_id), Inputs.payload(String(spec.target_id)))
		campaign.route.advance_scene()
	campaign._sync_route_projection()
	campaign._refresh_world()
	campaign.hud.refresh_scene()
	await _near("calibrate_probe")
	campaign.interact_nearby()
	panel = campaign.hud.p01_panel
	_expect(panel.is_open(), "actual nearby USE opens calibration panel")
	await _capture("first_use")
	campaign.hud.panels.hint_player.close()
	await _capture("calibration_unset")
	await _press("Choose_wet", "mouse")
	_expect(panel.selection().get("reference") == "wet", "native mouse chooses wet reference")
	await _type("raw_reading", "110")
	await _type("calibrated_reading", "100")
	await _press("TryIt", "keyboard")
	_expect(not panel._prediction.get("accepted", false), "native wrong prediction rejects without punishment")
	await _capture("calibration_retry")
	await _press("Choose_dry", "controller")
	_expect(panel.selection().get("reference") == "dry", "native controller A chooses dry reference")
	await _type("raw_reading", "10")
	await _type("calibrated_reading", "0")
	await _press("TryIt", "keyboard")
	_expect(panel._prediction.get("accepted", false), "typed numeric selection reaches authoritative forecast")
	await _capture("calibration_prediction")
	var before: Dictionary = campaign.route.snapshot()
	for level in range(1, 4):
		await _press("ProbeHint", "controller")
		_expect(campaign.hud.panels.hint_player.level == level and campaign.query().paused, "hint %d keeps pause union" % level)
		await _capture("hint_%d" % level)
		await _key(KEY_ESCAPE)
		_expect(panel.is_open() and campaign.query().paused and panel.selection().calibrated_reading == 0, "hint restores panel selection and pause")
	await _press("ProbeSources", "mouse")
	_expect(campaign.hud.panels.active_panel() == "sources" and campaign.query().paused, "Data Card entry uses existing source reader")
	await _capture("data_cards")
	campaign.hud.panels.close_panel()
	_expect(panel.is_open() and campaign.query().paused and campaign.route.snapshot() == before, "sources return preserves exact route and pause")
	await _pad(JOY_BUTTON_Y)
	_expect(panel._confirming, "native controller Y requests confirmation")
	await _capture("calibration_confirm")
	await _pad(JOY_BUTTON_B)
	_expect(not panel._confirming and panel.is_open(), "controller B steps back")
	panel._settings.large_text = true
	panel._render()
	await _capture("calibration_prediction_150")
	await _key(KEY_ESCAPE)
	_expect(panel._leaving, "native Escape asks before dirty leave")
	await _capture("discard_150")
	await _press("KeepChoosing", "keyboard")
	await _pad(JOY_BUTTON_Y)
	await _capture("calibration_confirm_150")
	await _pad(JOY_BUTTON_Y)
	_expect(campaign.route.snapshot().p01.probe_zeroed, "native confirmation performs physical calibration")
	panel._settings.large_text = true
	panel._render()
	await _capture("calibration_observed_150")
	panel.discard()
	for target in ["span_probe", "recheck_probe", "inspect_packet"]:
		await _near(target)
		campaign.interact_nearby()
		for key in Inputs.payload(target):
			panel.choose(key, Inputs.payload(target)[key])
		if Inputs.payload(target).is_empty():
			panel.choose("confirmed", true)
		panel.preview()
		await _capture(target)
		panel.request_commit()
		panel.confirm_commit()
		panel.discard()
	campaign.route.perform("compare_atmosphere")
	campaign.route.advance_scene()
	campaign._sync_route_projection()
	campaign._refresh_world()
	campaign.hud.refresh_scene()
	for target in ["plant_alo", "plant_tara", "water_alo", "water_tara", "label_alo", "label_tara", "seal_alo", "seal_tara"]:
		await _near(target)
		campaign.interact_nearby()
		_expect(panel.is_open(), "nearby planting panel " + target)
		for key in Inputs.payload(target):
			panel.choose(key, Inputs.payload(target)[key])
		if Inputs.payload(target).is_empty():
			panel.choose("confirmed", true)
		if target == "water_alo":
			panel.choose("moisture", 61)
			panel.preview()
			await _capture("water_retry")
			panel.choose("moisture", 40.25)
		panel.preview()
		await _capture(target)
		panel._settings.large_text = true
		panel._render()
		if target in ["plant_alo", "water_alo", "label_alo", "seal_alo"]:
			await _capture(target + "_150")
		panel.request_commit()
		panel.confirm_commit()
		panel.discard()
	_expect(campaign.p01_view("seal_tara").completion.complete, "native whole panel sequence completes with chosen fractional moisture")
	campaign.free()
	await process_frame
	storage.cleanup()
	var file := FileAccess.open("res://../production/qa/evidence/M1-08_capture_probe.txt", FileAccess.WRITE)
	file.store_string("\n".join(probe) + "\nScreenshots: " + ", ".join(shots) + "\n")
	file.close()
	print("M1-08 CAPTURE RESULT: %s (%d captures, %d failures)" % ["PASS" if failures == 0 else "FAIL", shots.size(), failures])
	quit(0 if failures == 0 else 1)

func _near(id: String) -> void:
	var target := campaign.physical_target(id)
	campaign._player.global_position = target.global_position + Vector3(0, 0, 1)
	campaign._player.velocity = Vector3.ZERO
	await physics_frame
	campaign._player.get_viewport().get_camera_3d().look_at(target.global_position)

func _type(field: String, text: String) -> void:
	await process_frame
	await process_frame
	var entry := panel.find_child("Input_" + field, true, false) as LineEdit
	entry.grab_focus()
	entry.select_all()
	await _key(KEY_BACKSPACE)
	for character in text:
		await _key(character.unicode_at(0), character.unicode_at(0))
	await _key(KEY_TAB)

func _press(id: String, device: String) -> void:
	await process_frame
	await process_frame
	var control := panel.find_child(id, true, false) as Control
	control.grab_focus()
	await process_frame
	await process_frame
	_expect(root.gui_get_focus_owner() == control, "input focus reaches " + id)
	if device == "mouse":
		for down in [true, false]:
			var event := InputEventMouseButton.new()
			event.button_index = MOUSE_BUTTON_LEFT
			event.position = control.get_global_rect().get_center()
			event.pressed = down
			Input.parse_input_event(event)
			Input.flush_buffered_events()
			await process_frame
	elif device == "controller":
		await _pad(JOY_BUTTON_A)
	else:
		await _key(KEY_ENTER)

func _key(code: int, character: int = 0) -> void:
	for down in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.unicode = character
		event.pressed = down
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await process_frame

func _pad(code: int) -> void:
	for down in [true, false]:
		var event := InputEventJoypadButton.new()
		event.button_index = code
		event.pressed = down
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await process_frame

func _capture(id: String) -> void:
	await create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	if panel.is_open() and not panel._covered:
		_expect(root.get_visible_rect().encloses(panel._frame.get_global_rect()), id + " frame fits viewport")
		for button in panel._frame.find_children("*", "Button", true, false):
			_expect(button.size.y >= 44, id + " target >=44 " + String(button.name))
			var width: float = button.get_theme_font("font").get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x
			_expect(button.size.x >= width, id + " button text fits " + String(button.name))
		var close := panel.find_child("CloseProbe", true, false) as Control
		_expect(root.get_visible_rect().encloses(close.get_global_rect()), id + " close stays visible")
	var name := "M1-08_" + id + ".png"
	_expect(root.get_texture().get_image().save_png("res://../production/qa/evidence/" + name) == OK, "captured " + name)
	shots.append(name)

func _expect(value: bool, label: String) -> void:
	probe.append(("PASS " if value else "FAIL ") + label)
	if not value:
		failures += 1
		push_error(label)
		quit(1)
