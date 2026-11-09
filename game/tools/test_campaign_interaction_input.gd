extends SceneTree
const Scene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const Legacy = preload("res://scenes/dev/locomotion_test.tscn")
const Gates = preload("res://scripts/missions/chapter1_gate_catalog.gd")
var storage = preload("res://tools/support/isolated_storage.gd").new()
var campaign: Chapter1Campaign
var checks := 0
var failures := 0
var trace: Array = []
var shots: Array[String] = []
var ui_input: Array = []

func _init() -> void:
	CampaignCutscenePlayer.autoplay = false
	if not storage.setup("campaign_interaction_input") or (_capture_enabled() and not storage.prepare_rendering_cache()):
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	if _capture_enabled():
		root.always_on_top = true
		root.grab_focus()
	campaign = Scene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	root.add_child(campaign)
	await process_frame
	campaign.hud.panels.hint_player.seen_path = storage.directory.path_join("how-to.cfg")
	if not await _near("commission_route"):
		campaign.free()
		_finish()
		return
	var generic := campaign._player.nearest_interactable()
	_check(generic != null, "real production station is also a generic interactable")
	await _capture("commission_before")
	var commission := await _press_e(campaign._player, "commission")
	_check(bool(campaign.route.current_flags().get("commission_route_confirmed", false)), "real E commits the production station action")
	_check(not _has_inspect(commission), "campaign E does not also request generic Inspect")
	await _capture("commission_after")
	for scene in ["EX-CH01-S01", "EX-CH01-S02"]:
		for spec in Gates.targets_for_scene(scene):
			_check(bool(campaign.route.perform(String(spec.target_id)).get("accepted", false)), "normal calibration setup " + String(spec.target_id))
		_check(bool(campaign.route.advance_scene().get("accepted", false)), "normal scene advance " + scene)
	campaign._sync_route_projection()
	campaign._refresh_world()
	campaign.hud.refresh_scene()
	if not await _near("calibrate_probe"):
		campaign.free()
		_finish()
		return
	await _capture("dry_zero_before")
	var before: Dictionary = campaign.route.snapshot()
	var requests: Array = []
	campaign.p01_panel_requested.connect(func(view): requests.append(view))
	var calibration := await _press_e(campaign._player, "dry_zero")
	var panel := campaign.hud.p01_panel
	_check(panel.is_open() and requests.size() == 1 and panel.selection().is_empty(), "one real E opens one actual unset calibration panel")
	_check(not _has_inspect(calibration), "real calibration E has no unrelated generic Inspect")
	if campaign.hud.panels.hint_player.is_open():
		await _key(KEY_ESCAPE)
	await _capture("dry_zero_panel")
	await _key(KEY_ESCAPE)
	_check(not panel.is_open() and campaign.route.snapshot() == before and not campaign.director.query().paused, "cancel closes the real panel without solving and restores control")
	await _near("calibrate_probe")
	await _press_e(campaign._player, "dry_zero_reopen")
	await _press_button("Choose_dry")
	await _type("raw_reading", "10")
	await _type("calibrated_reading", "0")
	await _press_button("TryIt")
	_check(bool(panel._prediction.get("accepted", false)), "actual typed calibration input reaches the shared forecast")
	await _press_button("LockIn")
	await _press_button("ConfirmChoice")
	_check(bool(campaign.route.snapshot().p01.probe_zeroed) and campaign.route.snapshot().p01.receipts.size() == 1, "actual player confirmation calibrates once with one receipt")
	await _capture("dry_zero_observed")
	await _key(KEY_ESCAPE)
	_check(not panel.is_open() and not campaign.director.query().paused and campaign._player.process_mode != Node.PROCESS_MODE_DISABLED, "observed result closes back to playable control")
	campaign.free()
	campaign = null
	await process_frame
	var level := Legacy.instantiate()
	root.add_child(level)
	var player := level.get_node("Player") as PlayerController
	player.follow_camera.capture_mouse = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player.global_position = Vector3(2.5, 0.04, 1.5)
	player.reset_physics_interpolation()
	for frame in range(4):
		await physics_frame
	_check(player.nearest_interactable() != null, "real legacy console is reachable")
	var standalone := await _press_e(player, "standalone")
	_check(_has_inspect(standalone), "real E still requests intended generic Inspect outside campaign")
	level.free()
	await process_frame
	DirAccess.remove_absolute(storage.directory.path_join("how-to.cfg"))
	_finish()

func _near(id: String) -> bool:
	var target := campaign.physical_target(id)
	if target == null:
		_check(false, "real target exists " + id)
		return false
	campaign._player.global_position = Vector3(target.global_position.x, 0.04, target.global_position.z + 1.0)
	campaign._player.velocity = Vector3.ZERO
	campaign._player.reset_physics_interpolation()
	for frame in range(4):
		await physics_frame
	campaign._player.follow_camera.camera.look_at(target.global_position)
	_check(campaign.nearby_target().get("target_id", "") == id, "real physical target selected " + id)
	return true

func _press_e(player: PlayerController, phase: String) -> Array:
	# A busy one-shot could reject Inspect and hide the original second consumer.
	for frame in range(180):
		if player.placement_frames == 0 and player.animation.action_name.is_empty() and player.animation._pending_action.is_empty():
			break
		await physics_frame
		await process_frame
	_check(player.animation.has_clip("Inspect") and player.animation.action_name.is_empty() and player.animation._pending_action.is_empty() and not player.animation.movement_locked and player.placement_frames == 0 and player.controlled and Input.get_vector("move_left", "move_right", "move_forward", "move_back", 0.15).is_zero_approx(), "settled actor can accept Inspect before real E: " + phase)
	var samples: Array = [_sample(player)]
	for down in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = KEY_E
		event.keycode = KEY_E
		event.pressed = down
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		for frame in range(3):
			await physics_frame
			await process_frame
			samples.append(_sample(player))
	trace.append({"phase": phase, "scene": campaign.route.current_scene_id() if campaign != null else "standalone", "samples": samples})
	return samples

func _sample(player: PlayerController) -> Dictionary:
	var generic := player.nearest_interactable()
	return {"body": String(player.name), "asset": player.loaded_path, "rest_clip": String(player.animation._rest_node.animation), "active_action": player.animation.action_name, "pending_action": player.animation._pending_action, "generic_target": String(generic.name) if generic != null else "", "generic_action": String(generic.get_meta("action", "Inspect")) if generic != null else "", "move_input": str(Input.get_vector("move_left", "move_right", "move_forward", "move_back", 0.15)), "window_focus": root.has_focus()}

func _has_inspect(samples: Array) -> bool:
	return samples.any(func(sample): return sample.active_action == "Inspect" or sample.pending_action == "Inspect")

func _press_button(id: String) -> void:
	await process_frame
	await process_frame
	var button := campaign.hud.p01_panel.find_child(id, true, false) as Button
	_check(button != null, "actual control exists " + id)
	if button == null:
		return
	button.grab_focus()
	await process_frame
	await process_frame
	_check(root.gui_get_focus_owner() == button, "actual keyboard focus reaches " + id)
	await _key(KEY_ENTER)

func _type(field: String, text: String) -> void:
	await process_frame
	await process_frame
	var entry := campaign.hud.p01_panel.find_child("Input_" + field, true, false) as LineEdit
	entry.grab_focus()
	await process_frame
	await process_frame
	_check(root.gui_get_focus_owner() == entry, "actual keyboard focus reaches " + field)
	entry.select_all()
	await _key(KEY_BACKSPACE)
	for character in text:
		await _key(character.unicode_at(0), character.unicode_at(0))
	_check(entry.text == text, "actual typed field " + field + " expected " + text + " got " + entry.text)
	ui_input.append({"field": field, "text": entry.text, "focus": root.gui_get_focus_owner() == entry, "window_focus": root.has_focus()})
	await _key(KEY_TAB)

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

func _capture_enabled() -> bool:
	return OS.get_cmdline_user_args().has("--capture")

func _capture(id: String) -> void:
	if not _capture_enabled():
		return
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	var name := "M1-107_" + id + ".png"
	_check(root.get_texture().get_image().save_png("res://../production/qa/evidence/" + name) == OK, "capture " + name)
	shots.append(name)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func _finish() -> void:
	var directory := OS.get_environment("TEST_LOG_DIR")
	var path := "res://../production/qa/evidence/M1-107_input_trace.json" if _capture_enabled() else directory.path_join("input_trace.json")
	if not directory.is_empty() or _capture_enabled():
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify({"trace": trace, "ui_input": ui_input, "captures": shots, "checks": checks, "failures": failures}, " "))
	storage.cleanup()
	print("CAMPAIGN INTERACTION INPUT RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)
