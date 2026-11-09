extends "res://tools/test_garden_collision.gd"

var trace: Array = []
var _keys := {KEY_W: false, KEY_A: false, KEY_S: false, KEY_D: false}
var _trial_id := ""
var _step := 0

func _run() -> void:
	root.size = Vector2i(1280, 720)
	if _capture_enabled():
		root.always_on_top = true
		root.grab_focus()
	for ending in ["BLOOM", "MISSION_STOPPED"]:
		if not await _load_checkpoint(ending):
			break
		for mode in ["keyboard", "controller"]:
			_trial_id = ending.to_lower() + "_" + mode
			await _trial(mode)
		campaign.free()
		campaign = null
		await process_frame
	_finish()

func _load_checkpoint(ending: String) -> bool:
	var route: RefCounted = Fixture.play(ending)
	var state: Dictionary = route.director().snapshot()
	state.merge({"scene_id": route.current_scene_id(), "mission_id": route.current_mission_id(), "completed_scene_ids": route.completed_scene_ids(), "route_runtime": route.snapshot().merged({"chapter": 1})}, true)
	var service := SaveService.new()
	service.session_validator = Chapter1Campaign.restore_session
	_check(bool(service.save(state, storage.path).get("accepted", false)), ending + " saves isolated real route checkpoint")
	var loaded := service.load(storage.path)
	_check(bool(loaded.get("accepted", false)), ending + " checkpoint passes actual SaveService restore validation")
	campaign = Scene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	campaign.initial_snapshot = loaded.get("snapshot", {})
	root.add_child(campaign)
	await process_frame
	await physics_frame
	await process_frame
	_check(campaign._startup_error.is_empty(), ending + " production campaign restores without startup error")
	if not campaign._startup_error.is_empty():
		return false
	room = campaign._room
	player = campaign._player
	player.follow_camera.capture_mouse = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_check(campaign.route.current_scene_id() == "EX-CH01-S11" and room.room_id == "LOC-03", ending + " uses the actual reported garden scene")
	_check(String(campaign.route.snapshot().get("ending", "")) == ending, ending + " restores the requested authoritative ending")
	_check((String(campaign.director.query().get("status", "")) == "mission_stopped") == (ending == "MISSION_STOPPED"), ending + " restores distinct mission safety status")
	_check(player.is_physics_processing() and player.controlled and not campaign.director.query().paused, ending + " real controller is active and unpaused")
	return true

func _trial(mode: String) -> void:
	await _release()
	# One fixture placement before any input. Recovery below never writes a
	# player transform, movement velocity, facing, action or animation state.
	player.global_position = Vector3(-4.4, 0.04, -2.2)
	player.reset_placement()
	player.reset_physics_interpolation()
	player.face_towards(Vector3(-3.4, 0.04, -1.2))
	player.follow_camera.yaw = 0
	for frame in range(180):
		await physics_frame
		await process_frame
		if player.placement_frames == 0 and player.animation.action_name.is_empty() and player.animation._pending_action.is_empty():
			break
	_check(_capsule_clear(), _trial_id + " starts outside solid geometry")
	var capsule := player.get_node("CollisionShape3D") as CollisionShape3D
	_check(is_equal_approx(capsule.shape.radius, 0.27) and player.collision_mask == 3, _trial_id + " keeps production capsule and world/crew collision")
	var flags: Dictionary = campaign.route.current_flags().duplicate(true)
	var resources: Dictionary = campaign.director.snapshot().resources.duplicate(true)
	var touched := false
	for frame in range(180):
		_send_world(Vector3(1, 0, 1), mode)
		await _tick("approach_contact")
		if _contacts().any(func(path): return String(path).ends_with("/tara_bay")):
			touched = true
			_record("actual_bench_contact")
			break
	_check(touched, _trial_id + " actual input reaches the solid bench contact")
	await _release()
	await _capture(_trial_id + "_contact")
	var contact_z := player.global_position.z
	_check(await _walk_to(Vector3(-4.65, 0, contact_z), mode), _trial_id + " can reverse away from contact")
	_check(await _walk_to(Vector3(-4.65, 0, -0.5), mode), _trial_id + " can steer along the outside of the bench")
	_check(await _walk_to(Vector3(0, 0, -0.5), mode), _trial_id + " can return across the clear front lane")
	_check(await _walk_to(Vector3(0, 0, 0.5), mode), _trial_id + " returns to the room center")
	_check(Vector2(player.global_position.x, player.global_position.z - 0.5).length() < 0.25 and absf(player.global_position.y) < 0.06, _trial_id + " finishes grounded at center")
	_check(player.is_physics_processing() and player.controlled and not player.animation.movement_locked and not campaign.director.query().paused, _trial_id + " restores free movement without a runtime bypass")
	_check(campaign.route.current_flags() == flags and campaign.director.snapshot().resources == resources, _trial_id + " movement does not alter gates/resources")
	await _capture(_trial_id + "_returned")
	await _release()

func _capsule_clear() -> bool:
	var shape := player.get_node("CollisionShape3D") as CollisionShape3D
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape.shape
	query.transform = shape.global_transform
	query.collision_mask = player.collision_mask
	query.exclude = [player.get_rid()]
	return player.get_world_3d().direct_space_state.intersect_shape(query).is_empty()

func _walk_to(goal: Vector3, mode: String) -> bool:
	var reached := false
	for frame in range(360):
		var delta := goal - player.global_position
		delta.y = 0
		if delta.length() < 0.11:
			reached = true
			break
		_send_world(delta, mode)
		await _tick("recover")
	await _release()
	_record("leg_end:" + str(goal))
	return reached and Vector2(player.global_position.x - goal.x, player.global_position.z - goal.z).length() < 0.25

func _send_world(direction: Vector3, mode: String) -> void:
	var local := Basis(Vector3.UP, -player.follow_camera.yaw) * direction.normalized()
	if mode == "keyboard":
		var wanted := {KEY_W: local.z < -0.35, KEY_A: local.x < -0.35, KEY_S: local.z > 0.35, KEY_D: local.x > 0.35}
		for key in wanted:
			if _keys[key] != wanted[key]:
				var event := InputEventKey.new()
				event.physical_keycode = key
				event.keycode = key
				event.pressed = wanted[key]
				Input.parse_input_event(event)
				_keys[key] = wanted[key]
	else:
		for row in [[JOY_AXIS_LEFT_X, local.x * 0.7], [JOY_AXIS_LEFT_Y, local.z * 0.7]]:
			var event := InputEventJoypadMotion.new()
			event.device = 0
			event.axis = row[0]
			event.axis_value = row[1]
			Input.parse_input_event(event)
	Input.flush_buffered_events()

func _release() -> void:
	for key in _keys:
		if _keys[key]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			event.keycode = key
			event.pressed = false
			Input.parse_input_event(event)
			_keys[key] = false
	for axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]:
		var event := InputEventJoypadMotion.new()
		event.device = 0
		event.axis = axis
		event.axis_value = 0
		Input.parse_input_event(event)
	Input.flush_buffered_events()
	for frame in range(12):
		await _tick("released")

func _tick(phase: String) -> void:
	await physics_frame
	await process_frame
	_step += 1
	if _step % 10 == 0:
		_record(phase)

func _contacts() -> Array:
	var result: Array = []
	for index in range(player.get_slide_collision_count()):
		result.append(String(player.get_slide_collision(index).get_collider().get_path()))
	return result

func _record(phase: String) -> void:
	if not is_instance_valid(player):
		return
	trace.append({"trial": _trial_id, "phase": phase, "physics_frame": Engine.get_physics_frames(), "position": _v(player.global_position), "camera_yaw": player.follow_camera.yaw, "input": str(Input.get_vector("move_left", "move_right", "move_forward", "move_back", 0.15)), "stick": [Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)], "action": player.animation.action_name, "pending_action": player.animation._pending_action, "movement_locked": player.animation.movement_locked, "placement_frames": player.placement_frames, "on_wall": player.is_on_wall(), "speed": player.horizontal_speed, "contacts": _contacts()})

func _capture(id: String) -> void:
	if not _capture_enabled():
		return
	var camera := Camera3D.new()
	room.add_child(camera)
	camera.global_position = Vector3(-5.75, 2.15, -0.2) if id.ends_with("contact") else Vector3(-4.0, 2.2, 3.2)
	camera.look_at(player.global_position + Vector3.UP * 0.8)
	camera.current = true
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(OS.get_environment("TEST_LOG_DIR").path_join("M1-123_" + id + ".png")) == OK, "write real controller capture " + id)
	camera.free()
	player.follow_camera.camera.current = true

func _finish() -> void:
	var out := OS.get_environment("TEST_LOG_DIR")
	if not out.is_empty():
		var file := FileAccess.open(out.path_join("movement_trace.json"), FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify({"checks": checks, "failures": failures, "trace": trace}, " "))
			file.close()
	if is_instance_valid(campaign):
		campaign.free()
	storage.cleanup()
	print("GARDEN MOVEMENT RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)
