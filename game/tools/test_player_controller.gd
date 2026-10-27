# Godot --headless --path game --fixed-fps 60 --script res://tools/test_player_controller.gd
# -- --glb=/absolute/character.glb tests another build; default is the v4 reference.
# -- --strict-contact also fails on touchdown/toe-off scuffs in the source clips.
extends SceneTree

const TestLevel: PackedScene = preload("res://scenes/dev/locomotion_test.tscn")
const FootSlideScript: Script = preload("res://scripts/review/foot_slide.gd")
const DT: float = 1.0 / 60.0

class PoseProbe extends SkeletonModifier3D:
	var positions: Array[Vector3] = []
	var rotations: Array[Quaternion] = []
	var foot_surface: Dictionary = {}
	var surface_meter: RefCounted
	var max_rotation: float = 0.0
	var max_translation: float = 0.0
	var sample_surface: bool = false

	func _process_modification_with_delta(delta: float) -> void:
		var rig := get_skeleton()
		var next_rotations: Array[Quaternion] = []
		var next_positions: Array[Vector3] = []
		for bone in rig.get_bone_count():
			var rotation := rig.get_bone_pose_rotation(bone)
			var position := rig.global_transform * rig.get_bone_global_pose(bone).origin
			if rotations.size() == rig.get_bone_count():
				max_rotation = maxf(max_rotation, rad_to_deg(rotations[bone].angle_to(rotation)))
				max_translation = maxf(max_translation, positions[bone].distance_to(position))
			next_rotations.append(rotation)
			next_positions.append(position)
		rotations = next_rotations
		positions = next_positions
		if sample_surface:
			foot_surface = surface_meter.sample(delta)

var _failures: int = 0
var _checks: int = 0
var _player: PlayerController
var _probe: PoseProbe
var _level: Node3D
var _largest_speed_jump: float = 0.0
var _blend_error: float = 0.0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("PLAYER TEST Godot ", Engine.get_version_info().string)
	_level = TestLevel.instantiate()
	_player = _level.get_node("Player") as PlayerController
	_player.character_glb = "res://assets/characters/CH_Kai/CH_Kai.glb"
	root.add_child(_level)
	if not _check(_player.animation != null and _player.animation.tree != null, "runtime GLTFDocument character and AnimationTree"):
		quit(1)
		return
	_player.position = Vector3(-14.0, 0.0, 10.0)
	_player.follow_camera.capture_mouse = false
	_player.follow_camera.recenter_speed = 0.0
	_player.animation.idle_variations = false
	_probe = PoseProbe.new()
	_probe.surface_meter = FootSlideScript.new()
	_probe.surface_meter.setup(_player.character, _player.animation.skeleton)
	_player.animation.skeleton.add_child(_probe)
	await _frames(30)
	print("ASSET ", _player.loaded_path)
	_check(_player.animation.skeleton.get_bone_count() == 65, "65-bone Mixamo rig")
	_check(_player.pose_modifier.solvers.size() == 2, "ClassDB TwoBoneIK3D available and configured")
	_check(_player._gaze_modifiers.size() == 2, "ClassDB LookAtModifier3D head and neck")
	_probe.max_rotation = 0.0
	_probe.max_translation = 0.0
	Input.action_press("move_forward")
	await _frames(180)
	_check(absf(_player.horizontal_speed - _player.tuning.walk_speed) < 0.04, "walk reaches measured target")
	await _measure_feet("walk", 180)
	Input.action_press("run")
	await _measure_feet("walk_to_run", 90)
	await _measure_feet("run", 180)
	_check(absf(_player.horizontal_speed - _player.tuning.run_speed) < 0.04, "run reaches measured target")
	Input.action_release("run")
	await _measure_feet("run_to_walk", 120)
	Input.action_release("move_forward")
	await _frames(90)
	_check(_player.horizontal_speed < 0.01, "smooth stop reaches rest")
	print("TRANSITIONS max_speed_delta=%.6f m/s/frame blend_error=%.6f max_bone_rotation=%.6f deg/frame max_joint_displacement=%.6f m/frame" % [_largest_speed_jump, _blend_error, _probe.max_rotation, _probe.max_translation])
	_check(_largest_speed_jump < 0.32, "speed changes stay below 0.32 m/s/frame")
	_check(_blend_error < 0.001, "blend position follows actual horizontal speed")
	_check(_probe.max_rotation < 16.0, "start/stop/blend rotations stay below 16 degrees/frame")
	await _test_actions()
	await _test_inputs_and_layers()
	await _test_turns()
	await _test_obstacles()
	await _test_camera()
	_test_clip_fallbacks()
	_test_hold_layers()
	await _test_hold_speed()
	await _test_switching()
	for name in ["move_forward", "move_back", "move_left", "move_right", "run", "sprint", "interact"]:
		Input.action_release(name)
	_level.free()
	await process_frame
	print("PLAYER RESULT: %s (%d checks, %d failures)" % ["PASS" if _failures == 0 else "FAIL", _checks, _failures])
	quit(0 if _failures == 0 else 1)

func _frames(count: int) -> void:
	for frame in count:
		var previous := _player.horizontal_speed
		await physics_frame
		await process_frame
		_largest_speed_jump = maxf(_largest_speed_jump, absf(_player.horizontal_speed - previous))
		var blend: float = _player.animation.tree.get("parameters/Locomotion/blend_position")
		_blend_error = maxf(_blend_error, absf(blend - _player.horizontal_speed))

func _measure_feet(label: String, count: int) -> void:
	var previous: Array[Vector3] = []
	var was_locked: Array[bool] = [false, false]
	var total: float = 0.0
	var maximum: float = 0.0
	var samples: int = 0
	var surface_sum: float = 0.0
	var surface_max: float = 0.0
	var surface_count: int = 0
	var planted_surface_sum: float = 0.0
	var planted_surface_max: float = 0.0
	var planted_surface_count: int = 0
	_probe.surface_meter.reset()
	_probe.sample_surface = true
	for frame in count:
		await _frames(1)
		var now: Array[Vector3] = []
		for side in 2:
			var bone := _player.pose_modifier.foot_bones[side]
			var p := _probe.positions[bone]
			now.append(p)
			var planted := _player.pose_modifier.locked[side] and _player.pose_modifier.weights[side] >= 0.999
			if previous.size() == 2 and planted and was_locked[side]:
				var distance := Vector2(p.x - previous[side].x, p.z - previous[side].z).length()
				var speed := distance / DT
				total += speed
				maximum = maxf(maximum, speed)
				samples += 1
			if not _probe.foot_surface.is_empty():
				var foot: Dictionary = _probe.foot_surface["left" if side == 0 else "right"]
				if foot.contact_samples > 0:
					surface_sum += foot.slide_speed
					surface_max = maxf(surface_max, foot.slide_speed)
					surface_count += 1
					if planted and was_locked[side]:
						planted_surface_sum += foot.slide_speed
						planted_surface_max = maxf(planted_surface_max, foot.slide_speed)
						planted_surface_count += 1
			was_locked[side] = planted
		previous = now
	_probe.sample_surface = false
	print("FEET %s planted_samples=%d joint_mean=%.6f joint_max=%.6f m/s surface_samples=%d surface_mean=%.6f surface_max=%.6f m/s" % [label, samples, total / maxi(samples, 1), maximum, surface_count, surface_sum / maxi(surface_count, 1), surface_max])
	print("  planted boot surface samples=%d mean=%.6f max=%.6f m/s" % [planted_surface_count, planted_surface_sum / maxi(planted_surface_count, 1), planted_surface_max])
	if OS.get_cmdline_user_args().has("--strict-contact"):
		_check(surface_count >= 8 and surface_max < 0.20, label + " all near-floor surface motion < 0.20 m/s, including touchdown and toe-off")
	elif surface_max >= 0.20:
		print("QUALITY_LIMIT %s touchdown/toe-off surface motion exceeds 0.20 m/s; run --strict-contact to enforce" % label)
	_check(samples >= 8, label + " has stance samples")
	_check(maximum < 0.20, label + " stance foot world speed < 0.20 m/s")
	_check(planted_surface_count >= 8 and planted_surface_max < 0.20, label + " planted boot surface speed < 0.20 m/s")

func _test_actions() -> void:
	_probe.max_rotation = 0.0
	_check(not _player.animation.request_action("Unknown"), "unknown action rejected")
	_check(_player.animation.request_action("Wave"), "Wave action accepted")
	await _frames(10)
	_check(_player.animation.action_weight > 0.1 and _player.animation.action_weight < 1.0, "action fades in")
	_check(bool(_player.animation.tree.get("parameters/Action/active")), "AnimationTree one-shot active")
	Input.action_press("move_forward")
	await _frames(20)
	_check(_player.horizontal_speed < 0.01, "full body action locks movement")
	var duration := _player.animation.action_duration
	await _frames(int(ceil(duration / DT)))
	_check(_player.animation.action_name.is_empty() and not _player.animation.movement_locked, "one-shot releases back to locomotion")
	_check(_player.horizontal_speed > 0.1, "held input resumes after action")
	Input.action_release("move_forward")
	await _frames(90)
	_player.animation.set_talking(true)
	await _frames(40)
	_check(float(_player.animation.tree.get("parameters/Talk/blend_amount")) > 0.99, "standing talk fades in")
	_player.animation.set_talking(false)
	await _frames(40)
	_check(float(_player.animation.tree.get("parameters/Talk/blend_amount")) < 0.01, "talk returns to idle")
	_check(_player.animation.action_weight == 0.0 and not bool(_player.animation.tree.get("parameters/Action/active")), "action fade finishes at zero weight")
	print("ACTION max_bone_rotation=%.6f deg/frame" % _probe.max_rotation)
	_check(_probe.max_rotation < 16.0, "action entry and return have bounded bone rotation")

func _test_inputs_and_layers() -> void:
	_player.animation.set_talking(true)
	await _frames(40)
	_player.animation.set_talking(true, true)
	await _frames(60)
	_check(_player.animation._talk_node.animation == "motion/Listen_loop" and _player.animation._talk_weight > 0.99, "talk can crossfade to listen")
	_player.animation.set_talking(false)
	await _frames(40)
	_player.animation.idle_variations = true
	_player.animation._idle_timer = 0.0
	await _frames(10)
	_check(bool(_player.animation.tree.get("parameters/IdleVariation/active")), "idle variation crossfades in")
	Input.action_press("move_forward")
	await _frames(50)
	_check(not bool(_player.animation.tree.get("parameters/IdleVariation/active")), "movement fades out idle variation")
	Input.action_release("move_forward")
	await _frames(90)
	_player.animation.idle_variations = false
	_player.global_position = Vector3(-14.0, 0.0, 10.0)
	_player.reset_physics_interpolation()
	var stick := InputEventJoypadMotion.new()
	stick.device = 0
	stick.axis = JOY_AXIS_LEFT_Y
	stick.axis_value = -1.0
	Input.parse_input_event(stick)
	await _frames(90)
	_check(absf(_player.horizontal_speed - _player.tuning.run_speed) < 0.05, "full left stick selects run")
	stick.axis_value = -0.65
	Input.parse_input_event(stick)
	await _frames(90)
	_check(_player.horizontal_speed > 0.2 and _player.horizontal_speed < _player.tuning.walk_speed, "partial left stick selects analog walk")
	stick.axis_value = 0.0
	Input.parse_input_event(stick)
	await _frames(90)
	for fixture in [[Vector3(1.3, 0.0, 0.0), "Inspect"], [Vector3(-2.5, 0.0, -1.3), "OpenDoor"]]:
		_player.global_position = fixture[0]
		_player.reset_physics_interpolation()
		await _frames(15)
		Input.action_press("interact")
		await _frames(2)
		Input.action_release("interact")
		_check(_player.animation.action_name == fixture[1], "E near test interactable starts " + fixture[1])
		await _frames(int(ceil(_player.animation.action_duration / DT)) + 30)
	_player.look_at_enabled = false
	_player.foot_ik_enabled = false
	_player.lean_enabled = false
	await _frames(60)
	_check(_player.pose_modifier.solvers.all(func(solver): return not solver.active), "foot placement can be disabled")
	_check(_player._gaze_modifiers.all(func(modifier): return modifier.influence == 0.0), "gaze can be disabled")
	_player.look_at_enabled = true
	_player.foot_ik_enabled = true
	_player.lean_enabled = true
	if _player.animation.has_clip("Sprint_loop"):
		_player.global_position = Vector3(-14.0, 0.0, 10.0)
		_player._yaw = PI
		_player._turn_velocity = 0.0
		Input.action_press("move_forward")
		Input.action_press("run")
		Input.action_press("sprint")
		await _frames(120)
		_check(_player.horizontal_speed > _player.tuning.run_speed + 0.1, "sprint selects the measured sprint gait with scaled cadence")
		Input.action_release("move_forward")
		Input.action_release("run")
		Input.action_release("sprint")
		await _frames(2)
		_check(_player.animation.action_name.is_empty(), "a sprint stop blends down through the gaits (no flailing stop clip)")
		await _frames(150)
		_check(_player.horizontal_speed < 0.01, "sprint stop reaches rest")
	var source := _player.animation.player.get_animation("OpenDoor")
	var clean := _player.animation.player.get_animation("motion/OpenDoor")
	var maximum_root_offset := 0.0
	for track in clean.get_track_count():
		if clean.track_get_type(track) == Animation.TYPE_POSITION_3D and String(clean.track_get_path(track)).ends_with("_Hips"):
			for key in clean.track_get_key_count(track):
				var position: Vector3 = clean.track_get_key_value(track, key)
				maximum_root_offset = maxf(maximum_root_offset, Vector2(position.x, position.z).length())
	_check(source != clean and maximum_root_offset < 0.00001, "controller animation copies strip horizontal action root motion")

func _test_turns() -> void:
	_player.global_position = Vector3(-14.0, 0.0, 10.0)
	Input.action_press("move_forward")
	await _frames(90)
	Input.action_release("move_forward")
	Input.action_press("move_back")
	var max_yaw_step := 0.0
	for frame in 120:
		var yaw := _player.visual.rotation.y
		await _frames(1)
		max_yaw_step = maxf(max_yaw_step, absf(angle_difference(yaw, _player.visual.rotation.y)))
	print("PIVOT max_yaw_delta=%.6f deg/frame final_speed=%.6f" % [rad_to_deg(max_yaw_step), _player.horizontal_speed])
	_check(rad_to_deg(max_yaw_step) < 10.0 and cos(_player.visual.rotation.y) > 0.95, "reversal brakes, pivots smoothly and faces new input")
	Input.action_release("move_back")
	await _frames(90)

func _test_obstacles() -> void:
	_player.global_position = Vector3(4.0, 0.0, -1.0)
	_player._yaw = PI
	_player._turn_velocity = 0.0
	_player.follow_camera.yaw = 0.0
	Input.action_press("move_forward")
	for frame in 400:
		await _frames(1)
		if _player.global_position.z < -6.0:
			break
	print("STAIRS position=", _player.global_position)
	_check(_player.global_position.z < -5.0 and _player.global_position.y > 0.7, "controller climbs 18 cm stairs")
	Input.action_release("move_forward")
	await _frames(90)
	_player.global_position = Vector3(-5.0, 0.0, -1.5)
	Input.action_press("move_forward")
	await _frames(170)
	print("RAMP position=", _player.global_position)
	_check(_player.global_position.z < -4.0 and _player.global_position.y > 0.5, "controller walks up ramp")
	Input.action_release("move_forward")
	await _frames(90)

func _test_camera() -> void:
	_player.global_position = Vector3(0.0, 0.0, 2.6)
	_player.follow_camera.yaw = 0.0
	_player.follow_camera.pitch = 0.0
	await _frames(60)
	var camera := _player.follow_camera.camera
	var minimum_clearance := INF
	var overlaps := 0
	for frame in 90:
		_player.follow_camera.look(Vector2(0.018, 0.0))
		await _frames(1)
		var query := PhysicsShapeQueryParameters3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = 0.12
		query.shape = sphere
		query.transform.origin = camera.global_position
		query.collision_mask = 1
		query.exclude = [_player.get_rid()]
		overlaps += _player.get_world_3d().direct_space_state.intersect_shape(query).size()
		minimum_clearance = minf(minimum_clearance, absf(camera.global_position.z - 3.85))
	print("CAMERA overlaps=%d nearest_wall_z_distance=%.6f m" % [overlaps, minimum_clearance])
	_check(overlaps == 0, "camera sphere remains outside wall through orbit")
	_player.follow_camera.look(Vector2(0.0, -100.0))
	_check(_player.follow_camera.pitch <= deg_to_rad(_player.follow_camera.max_pitch_degrees), "camera pitch clamped")

func _test_clip_fallbacks() -> void:
	var source := _player.animation.player
	var player := AnimationPlayer.new()
	_player.add_child(player)
	player.root_node = player.get_path_to(source.get_node(source.root_node))
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var library := AnimationLibrary.new()
	library.add_animation("Idle_loop", source.get_animation("Idle_loop").duplicate())
	library.add_animation("WalkBasic_loop", source.get_animation("Walk_loop").duplicate())
	library.add_animation("RunBasic_loop", source.get_animation("Run_loop").duplicate())
	player.add_animation_library("", library)
	var transform_before := _player.visual.transform
	_player.visual.top_level = true
	_player.visual.global_transform = Transform3D.IDENTITY
	var clips := LocomotionClips.new()
	var ready := clips.prepare(player, _player.animation.skeleton)
	_player.visual.top_level = false
	_player.visual.transform = transform_before
	_check(ready and clips.gaits == ["WalkBasic_loop", "RunBasic_loop", "RunBasic_loop"], "neutral gait aliases work without style or sprint clips")
	player.free()

func _hold_fixture(with_poses: bool) -> PlayerAnimation:
	var motion := PlayerAnimation.new()
	_player.add_child(motion)
	var player := AnimationPlayer.new()
	motion.add_child(player)
	var source := _player.animation.player
	player.root_node = player.get_path_to(source.get_node(source.root_node))
	var library := AnimationLibrary.new()
	for clip in ["Idle_loop", "Walk_loop", "Run_loop", "SprintStop"]:
		if source.has_animation(clip):
			library.add_animation(clip, source.get_animation(clip).duplicate())
	if not library.has_animation("SprintStop"):
		var stop := source.get_animation("Idle_loop").duplicate() as Animation
		stop.loop_mode = Animation.LOOP_NONE
		library.add_animation("SprintStop", stop)
	if with_poses:
		for clip in PlayerAnimation.HOLD_CLIPS:
			var pose := source.get_animation("Idle_loop").duplicate() as Animation
			# Deliberately change every bone: the filter must protect the rest of the body.
			for track in pose.get_track_count():
				if pose.track_get_type(track) == Animation.TYPE_ROTATION_3D:
					for key in pose.track_get_key_count(track):
						var rotation: Quaternion = pose.track_get_key_value(track, key)
						pose.track_set_key_value(track, key, rotation * Quaternion(Vector3.RIGHT, 0.6))
			library.add_animation(clip, pose)
	player.add_animation_library("", library)
	var before := _player.visual.transform
	_player.visual.top_level = true
	_player.visual.global_transform = Transform3D.IDENTITY
	_check(motion.setup(player, _player.animation.skeleton, _player.tuning.duplicate()), "hold fixture prepares")
	_player.visual.top_level = false
	_player.visual.transform = before
	motion.idle_variations = false
	return motion

func _test_hold_layers() -> void:
	_player.animation.tree.active = false
	for with_poses in [false, true]:
		var motion := _hold_fixture(with_poses)
		var rig := motion.skeleton
		for mode in [PlayerAnimation.Hold.BOX, PlayerAnimation.Hold.RIGHT]:
			var paths := motion.hold_filter_paths(mode)
			var blend := motion._graph.get_node("HoldBox" if mode == PlayerAnimation.Hold.BOX else "HoldRight") as AnimationNodeBlend2
			var expected: Array[String] = []
			for side in ["Left", "Right"] if mode == PlayerAnimation.Hold.BOX else ["Right"]:
				for suffix in ["Shoulder", "Arm", "ForeArm", "Hand", "HandThumb1", "HandThumb2", "HandThumb3", "HandIndex1", "HandIndex2", "HandIndex3", "HandMiddle1", "HandMiddle2", "HandMiddle3", "HandRing1", "HandRing2", "HandRing3", "HandPinky1", "HandPinky2", "HandPinky3"]:
					expected.append(side + suffix)
			var exact := paths.size() == expected.size() and blend.filter_enabled
			for path in paths:
				var bone_name := String(path.get_subname(0)).trim_prefix("mixamorig_").trim_prefix("mixamorig:")
				exact = exact and bone_name in expected and blend.is_path_filtered(path)
				expected.erase(bone_name)
			_check(exact and expected.is_empty(), "hold %d filters exactly its shoulder, arm, forearm, hand and 15 finger bones" % mode)
		var max_step := 0.0
		for mode in [PlayerAnimation.Hold.BOX, PlayerAnimation.Hold.RIGHT, PlayerAnimation.Hold.NONE]:
			var before := motion.hold_weights
			motion.set_hold(mode)
			_check(motion.hold_weights == before, "set_hold does not jump the weights")
			for frame in 12:
				before = motion.hold_weights
				motion.advance(DT, motion.tuning.run_speed)
				max_step = maxf(max_step, maxf(absf(motion.hold_weights.x - before.x), absf(motion.hold_weights.y - before.y)))
			var target := Vector2(1.0 if mode == PlayerAnimation.Hold.BOX else 0.0, 1.0 if mode == PlayerAnimation.Hold.RIGHT else 0.0) if with_poses else Vector2.ZERO
			_check(motion.hold_weights.is_equal_approx(target), "hold reaches its target in 0.2 s (poses=%s, mode=%d)" % [with_poses, mode])
		_check(max_step <= DT / PlayerAnimation.HOLD_FADE + 0.00001, "hold weights ramp without jumps, including BOX to RIGHT")
		for mode in [PlayerAnimation.Hold.BOX, PlayerAnimation.Hold.RIGHT]:
			for speed in [0.0, motion.tuning.walk_speed, motion.tuning.run_speed, motion.tuning.sprint_speed]:
				motion.set_hold(mode)
				motion.advance(0.2, speed)
				var held: Array[Transform3D] = []
				for bone in rig.get_bone_count():
					held.append(rig.get_bone_pose(bone))
				motion.hold_weights = Vector2.ZERO
				motion.set_hold(PlayerAnimation.Hold.NONE)
				motion.advance(0.0, speed)
				var unaffected := true
				var changed := 0
				var paths := motion.hold_filter_paths(mode)
				for bone in rig.get_bone_count():
					var path := NodePath(String(motion.player.get_node(motion.player.root_node).get_path_to(rig)) + ":" + rig.get_bone_name(bone))
					var same := held[bone].is_equal_approx(rig.get_bone_pose(bone))
					if path not in paths or not with_poses:
						unaffected = unaffected and same
					elif not same:
						changed += 1
				_check(unaffected and (not with_poses or changed > 0), "hold %d speed %.2f preserves legs, torso, head and unselected arm (poses=%s)" % [mode, speed, with_poses])
		if with_poses:
			_check(motion.player.get_animation("motion/CarryBox_pose").loop_mode == Animation.LOOP_LINEAR, "short pose loops without a _loop suffix")
			motion.set_hold(PlayerAnimation.Hold.BOX)
			motion.advance(0.2, motion.tuning.run_speed)
			_check(motion.play_transition("SprintStop"), "stop transition accepts input while holding")
			motion.advance(0.1, motion.tuning.walk_speed)
			_check(motion.hold_weights.x == 1.0 and motion.action_name == "SprintStop", "stop transition and hold layer run together")
		motion.free()
	_player.animation.tree.active = true
	_player.animation.advance(0.0, 0.0)

func _test_hold_speed() -> void:
	_player.global_position = Vector3(-14.0, 0.0, 10.0)
	_player._yaw = PI
	_player._turn_velocity = 0.0
	_player.follow_camera.yaw = 0.0
	_player.set_hold(PlayerAnimation.Hold.BOX)
	Input.action_press("move_forward")
	Input.action_press("run")
	Input.action_press("sprint")
	await _frames(120)
	_check(is_equal_approx(_player.desired_speed, _player.tuning.run_speed) and absf(_player.horizontal_speed - _player.tuning.run_speed) < 0.05, "BOX caps sprint at run speed, even without a pose clip")
	_player.set_hold(PlayerAnimation.Hold.RIGHT)
	await _frames(90)
	_check(is_equal_approx(_player.desired_speed, _player.tuning.sprint_speed), "RIGHT permits sprint")
	Input.action_release("move_forward")
	Input.action_release("run")
	Input.action_release("sprint")
	await _frames(150)
	_player.set_hold(PlayerAnimation.Hold.BOX)
	await _test_turns()
	_check(_player.animation.hold_mode == PlayerAnimation.Hold.BOX, "hold survives braking, pivot and stop")
	_player.set_hold(PlayerAnimation.Hold.NONE)

func _test_switching() -> void:
	_player.set_hold(PlayerAnimation.Hold.BOX)
	for index in [2, 0]:     # Mei (ponytail springs), then back to Kai
		var spot := _player.global_position
		var facing := _player.visual.global_rotation.y
		var camera_yaw := _player.follow_camera.yaw
		var cast: String = _level.CAST[index]
		_level.switch_character(index)
		var fresh := _level.get_node("Player") as PlayerController
		_check(fresh != _player and fresh.loaded_path.get_file() == cast + ".glb", "switch loads " + cast)
		_check(fresh.global_position.distance_to(spot) < 0.01 and absf(angle_difference(fresh.visual.global_rotation.y, facing)) < 0.01 and is_equal_approx(fresh.follow_camera.yaw, camera_yaw), cast + " keeps the spot, facing and camera")
		_check(fresh.animation.hold_mode == PlayerAnimation.Hold.BOX, cast + " keeps the hold")
		_check(fresh.character.get_node_or_null("FaceAtlas") != null and fresh.character.get_node_or_null("HairSprings") != null, cast + " gets face layers and hair springs")
		var face := fresh.character.get_node("FaceAtlas") as FaceAtlas
		print("FACE LIGHT %s radius %.3f m" % [cast, face._face_radius])
		_check(face._face_radius > 0.06 and face._face_radius < 0.3 and not is_equal_approx(face._face_radius, 0.14), cast + " face light fitted to the drawn face")
		_player = fresh
		await _frames(10)
	_player.set_hold(PlayerAnimation.Hold.NONE)

func _check(condition: bool, message: String) -> bool:
	_checks += 1
	if condition:
		print("  ok ", message)
	else:
		_failures += 1
		push_error("FAIL " + message)
	return condition
