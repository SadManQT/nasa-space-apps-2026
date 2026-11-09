extends SceneTree

const CampaignScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const Inputs = preload("res://tools/support/p01_input_fixture.gd")
const Gates = preload("res://scripts/missions/chapter1_gate_catalog.gd")
var storage = preload("res://tools/support/isolated_storage.gd").new()
var checks := 0
var failures := 0

func _init() -> void:
	CampaignCutscenePlayer.autoplay = false
	call_deferred("_run")

func _run() -> void:
	_check(ResourceLoader.exists("res://scenes/ui/p01_panel.tscn"), "chosen-input panel exists")
	if failures > 0:
		_finish()
		return
	_check(storage.setup("p01_panel"), "isolated player storage")
	root.size = Vector2i(1280, 720)
	var campaign = CampaignScene.instantiate()
	storage.configure(campaign)
	root.add_child(campaign)
	await process_frame
	campaign.hud.panels.hint_player.seen_path = storage.directory.path_join("how-to.cfg")
	while campaign.route.current_scene_id() != "EX-CH01-S03":
		for spec in Gates.targets_for_scene(campaign.route.current_scene_id()):
			campaign.route.perform(String(spec.target_id), Inputs.payload(String(spec.target_id)))
		_check(campaign.route.advance_scene().accepted, "fixture reaches calibration")
	campaign._sync_route_projection()
	campaign._refresh_world()
	campaign.hud.refresh_scene()
	await physics_frame
	await _near(campaign, "calibrate_probe")
	var before: Dictionary = campaign.route.snapshot()
	var receipts: Dictionary = campaign.director.snapshot().interaction_receipts
	_check(campaign.interact_nearby().get("p01_panel_requested", false), "real nearby USE requests panel")
	var panel = campaign.hud.get("p01_panel")
	_check(panel != null and panel.is_open(), "nearby USE opens owned HUD panel")
	if panel == null:
		campaign.free()
		_finish()
		return
	if campaign.hud.panels.hint_player.is_open():
		campaign.hud.panels.hint_player.close()
	await _focus_walk(panel)
	var dry_button := panel.find_child("Choose_dry", true, false) as Button
	dry_button.grab_focus()
	await process_frame
	await process_frame
	await _pad(JOY_BUTTON_A)
	_check(panel.selection().get("reference") == "dry", "controller A selects the focused reference once")
	panel.undo()
	await process_frame
	await process_frame
	dry_button = panel.find_child("Choose_dry", true, false) as Button
	dry_button.grab_focus()
	await _pad(JOY_BUTTON_DPAD_DOWN)
	_check(root.gui_get_focus_owner() == panel.find_child("Choose_wet", true, false), "controller down reaches the next reference")
	_check(campaign.query().paused and panel.selection().is_empty(), "reading pauses with every input unset")
	_check(not panel.preview().accepted and not panel.request_commit().accepted, "unset input cannot predict or submit")
	panel.choose("reference", "wet")
	panel.choose("raw_reading", 110)
	panel.choose("calibrated_reading", 100)
	_check(not panel.preview().accepted and not panel.request_commit().accepted, "wrong reference gets retry without confirmation")
	_check(campaign.route.snapshot() == before and campaign.director.snapshot().interaction_receipts == receipts, "wrong inputs and forecast preserve route and receipts")
	panel.choose("reference", "dry")
	panel.choose("raw_reading", 10)
	panel.choose("calibrated_reading", 0)
	_check(panel.preview().accepted and panel.request_commit().accepted, "explicit dry 10 to 0 predicts and confirms")
	panel.cancel_confirm()
	await process_frame
	await process_frame
	var delivered: Dictionary = campaign.update_message_metadata({"delivered_ids": ["MSG-CH01-001"], "read_ids": ["MSG-CH01-001"]})
	_check(bool(delivered.get("persisted", false)), "bounded message update persists during puzzle reading")
	_check(panel.request_commit().accepted, "message delivery/read preserves the accepted gameplay prediction")
	panel.cancel_confirm()
	await process_frame
	await process_frame
	var entry := panel.find_child("Input_calibrated_reading", true, false) as LineEdit
	entry.grab_focus()
	entry.select_all()
	await _key(KEY_1, 49)
	_check(root.gui_get_focus_owner() == entry, "typing keeps the live numeric field and caret")
	_check((panel.find_child("ProbeNotice", true, false) as Label).text.begins_with("Selection changed"), "typed edits immediately invalidate visible forecast feedback")
	_check(not _labels(panel).contains("Probe: zero set"), "typed edits remove the stale projected observation")
	panel.choose("calibrated_reading", 1)
	_check(not panel.request_commit().accepted, "editing invalidates the accepted prediction")
	panel.request_close()
	_check(panel.is_open(), "dirty leave asks before discarding")
	panel.discard()
	_check(not campaign.query().paused and campaign.route.snapshot() == before, "discard resumes without physical mutation")
	campaign.interact_nearby()
	_check(panel.selection().is_empty(), "reopen never silently restores a successful selection")
	for key in Inputs.payload("calibrate_probe"):
		panel.choose(key, Inputs.payload("calibrate_probe")[key])
	_check(panel.preview().accepted, "reopened explicit prediction accepted")
	campaign.director.pause("external")
	campaign.director.resume()
	# A separately committed operation changes the snapshot even if the panel remains open.
	var choice: Dictionary = campaign.current_scene_data().get("choice", {})
	var command: Dictionary = campaign.hud.panels.command_for("record_choice", String(choice.options[0].id), {"choice_id": choice.id, "option_id": choice.options[0].id})
	var changed: Dictionary = campaign.handle_ui_command(command)
	_check(bool(changed.get("accepted", false)) and not bool(changed.get("duplicate", false)), "real accepted story choice changes the authoritative context")
	_check(not panel.request_commit().accepted, "changed authoritative context requires another prediction")
	_check(panel.preview().accepted and panel.request_commit().accepted, "fresh prediction recovers")
	campaign._player.global_position += Vector3(20, 0, 0)
	_check(panel.confirm_commit().accepted, "confirmation dispatches chosen input")
	_check(panel.is_open() and not campaign.route.snapshot().p01.probe_zeroed, "physical range is revalidated and rejection reopens feedback")
	panel.discard()
	await _near(campaign, "calibrate_probe")
	var reopened: Dictionary = campaign.interact_nearby()
	_check(panel.is_open(), "retry USE opens: " + str(reopened) + " paused=" + str(campaign._ui_paused))
	for key in Inputs.payload("calibrate_probe"):
		panel.choose(key, Inputs.payload("calibrate_probe")[key])
	_check(panel.preview().accepted, "physical retry prediction: " + str(panel._prediction))
	_check(panel.request_commit().accepted, "physical retry confirmation opens: " + panel._notice)
	panel.confirm_commit()
	_check(campaign.route.snapshot().p01.probe_zeroed and panel.is_open(), "confirmed physical action shows observed result: " + panel._notice + " target=" + panel._target)
	var committed: Dictionary = campaign.route.snapshot()
	_check(not panel.confirm_commit().accepted and campaign.route.snapshot() == committed, "duplicate confirmation never submits twice")
	panel.discard()
	var saved: Dictionary = campaign._save_snapshot()
	var restored: Dictionary = campaign.restore_session(JSON.parse_string(JSON.stringify(saved)))
	_check(restored.accepted and restored.route.snapshot().p01.probe_zeroed, "JSON save restores calibration")
	_check(restored.route.perform("calibrate_probe", Inputs.payload("calibrate_probe")).accepted and restored.route.snapshot().p01.receipts.size() == 1, "restored duplicate keeps exactly one receipt")
	await _scan_feedback(campaign)
	await _planting(campaign)
	campaign.free()
	await process_frame
	storage.cleanup()
	_finish()

func _planting(campaign) -> void:
	for id in ["span_probe", "recheck_probe", "inspect_packet", "compare_atmosphere"]:
		campaign.route.perform(id, Inputs.payload(id))
	_check(campaign.route.advance_scene().accepted, "fixture reaches planting")
	campaign._sync_route_projection()
	campaign._refresh_world()
	campaign.hud.refresh_scene()
	await physics_frame
	for target in ["plant_alo", "plant_tara", "water_alo", "water_tara", "label_alo", "label_tara", "seal_alo", "seal_tara"]:
		await _near(campaign, target)
		var use: Dictionary = campaign.interact_nearby()
		var panel = campaign.hud.get("p01_panel")
		_check(panel.is_open() and panel.selection().is_empty(), "fresh selection for " + target + " " + str(use) + " paused=" + str(campaign._ui_paused))
		if target.begins_with("water"):
			for reading in [39, 61]:
				panel.choose("moisture", reading)
				_check(not panel.preview().accepted, "out-of-band water retries " + str(reading))
			for reading in [40.0, 60.0, 40.25, 59.75]:
				panel.choose("moisture", reading)
				_check(panel.preview().accepted, "inclusive and fractional moisture " + str(reading))
			panel.choose("moisture", 40.25 if target == "water_alo" else 60)
		else:
			for key in Inputs.payload(target):
				panel.choose(key, Inputs.payload(target)[key])
			if Inputs.payload(target).is_empty():
				panel.choose("confirmed", true)
		if target.begins_with("label"):
			var wrong := "INDOOR_REFERENCE" if target == "label_alo" else "EXTERNAL_TEST"
			var right := "EXTERNAL_TEST" if target == "label_alo" else "INDOOR_REFERENCE"
			var wrong_button := panel.find_child("Choose_" + wrong, true, false) as Button
			var right_button := panel.find_child("Choose_" + right, true, false) as Button
			_check(wrong_button != null and right_button != null, "both real label choices are available for " + target)
			if wrong_button != null:
				await process_frame
				await process_frame
				wrong_button.grab_focus()
				await _pad(JOY_BUTTON_A)
				_check(panel.selection().get("label") == wrong and not panel.preview().accepted, "real controller chooses a wrong label and gets a safe retry")
			panel.choose("label", right)
		_check(panel.preview().accepted and panel.request_commit().accepted, "selected planting action predicts " + target)
		if target.begins_with("label"):
			var observed := panel.find_child("ProbeObserved", true, false) as Label
			var projected := panel.find_child("ProbePrediction", true, false) as Label
			_check(observed != null and observed.text.to_lower().contains("label: not labelled"), "observed cassette has no label before confirmation")
			var expected := "label: external test" if target == "label_alo" else "label: indoor reference"
			_check(projected != null and projected.text.to_lower().contains(expected), "forecast visibly shows the chosen cassette label")
		panel.confirm_commit()
		if target.begins_with("label"):
			var observed := panel.find_child("ProbeObserved", true, false) as Label
			var expected := "label: external test" if target == "label_alo" else "label: indoor reference"
			_check(observed != null and observed.text.to_lower().contains(expected), "committed label is visible in the actual observation")
		panel.discard()
	_check(campaign.route.snapshot().p01.moisture_alo == 40.25 and campaign.route.snapshot().p01.moisture_tara == 60 and campaign.p01_view("seal_tara").completion.complete, "whole planting panel retains chosen moisture and completes")

func _near(campaign, id: String) -> void:
	var target: Node3D = campaign.physical_target(id)
	campaign._player.global_position = target.global_position + Vector3(0, 0, 1)
	campaign._player.velocity = Vector3.ZERO
	await physics_frame
	campaign._player.get_viewport().get_camera_3d().look_at(target.global_position)

func _check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("FAIL " + label)

func _finish() -> void:
	print("P01 PANEL RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _focus_walk(panel) -> void:
	for large in [false, true]:
		panel._settings.large_text = large
		panel._render()
		await process_frame
		await process_frame
		for index in range(28):
			await _key(KEY_TAB)
			var focused := root.gui_get_focus_owner()
			_check(focused != null and panel.is_ancestor_of(focused) and focused.is_visible_in_tree(), "Tab stays inside the puzzle at text scale " + str(large))
	panel._settings.large_text = false
	panel._render()
	await process_frame

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

func _labels(node: Node) -> String:
	var text := ""
	if node is Label and node.is_visible_in_tree():
		text += node.text + "\n"
	for child in node.get_children():
		text += _labels(child)
	return text

func _pad(code: int) -> void:
	for down in [true, false]:
		var event := InputEventJoypadButton.new()
		event.button_index = code
		event.pressed = down
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await process_frame

func _scan_feedback(campaign) -> void:
	for id in ["span_probe", "recheck_probe"]:
		_check(bool(campaign.route.perform(id, Inputs.payload(id)).get("accepted", false)), "prepare real packet scan " + id)
	await _near(campaign, "inspect_packet")
	campaign.interact_nearby()
	var panel = campaign.hud.p01_panel
	panel.choose("confirmed", true)
	_check(panel.preview().accepted, "chosen packet scan predicts")
	var observed := panel.find_child("ProbeObserved", true, false) as Label
	var projected := panel.find_child("ProbePrediction", true, false) as Label
	_check(observed != null and observed.text.contains("Seed packet: not scanned"), "packet observation is unscanned before confirmation")
	_check(projected != null and projected.text.contains("Seed packet: scanned"), "packet forecast visibly differs from the observation")
	_check(panel.request_commit().accepted and panel.confirm_commit().accepted, "explicit packet scan confirms")
	observed = panel.find_child("ProbeObserved", true, false) as Label
	_check(campaign.route.snapshot().p01.packet_scanned and observed != null and observed.text.contains("Seed packet: scanned"), "actual committed packet state is visible")
	panel.discard()
