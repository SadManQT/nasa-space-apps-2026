extends CharacterBody3D
class_name PlayerController

const AnimationScript: Script = preload("res://scripts/player/player_animation.gd")
const PoseScript: Script = preload("res://scripts/player/locomotion_pose.gd")
const OrientationScript: Script = preload("res://scripts/player/foot_orientation.gd")

@export_file("*.glb") var character_glb: String = ""
@export var tuning: LocomotionTuning
@export var gravity: float = 9.8
@export var look_at_enabled: bool = true
@export var foot_ik_enabled: bool = true
@export var lean_enabled: bool = true
@export var interaction_distance: float = 2.0

var visual: Node3D
var character: Node3D
var animation: PlayerAnimation
var follow_camera: FollowCamera
var pose_modifier: LocomotionPose
var loaded_path: String = ""
var horizontal_speed: float = 0.0
var desired_speed: float = 0.0
var _speed: float = 0.0
var _speed_derivative: float = 0.0
var _yaw: float = PI
var _turn_velocity: float = 0.0
var _previous_input := Vector2.ZERO
var _pivoting: bool = false
var _stick_running: bool = false
var _movement_device: int = -1
var _gaze_target: Node3D
var _gaze_modifiers: Array[SkeletonModifier3D] = []

func _ready() -> void:
	floor_snap_length = 0.3
	floor_max_angle = deg_to_rad(46.0)
	floor_constant_speed = true
	floor_stop_on_slope = true
	visual = Node3D.new()
	visual.name = "Visual"
	add_child(visual)
	follow_camera = get_node("FollowCamera") as FollowCamera
	_yaw = global_rotation.y + PI
	follow_camera.yaw = global_rotation.y
	var path := character_glb
	if path.is_empty():   # --glb only stands in for an unset character, so a scene that names one keeps it
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--glb="):
				path = arg.trim_prefix("--glb=")
	if path.is_empty():
		path = default_character_path()
	if not load_character(path):
		push_error("Player could not load " + path)

static func default_character_path() -> String:
	var v7 := ProjectSettings.globalize_path("res://../production/models/v7/CH_Kai/CH_Kai.glb")
	return v7 if FileAccess.file_exists(v7) else "res://assets/characters/CH_Kai/CH_Kai.glb"

func load_character(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	state.handle_binary_image = GLTFState.HANDLE_BINARY_EMBED_AS_UNCOMPRESSED
	var error: Error = document.append_from_file(path, state)
	if error != OK:
		push_error("GLB import failed (%s): %s" % [error, path])
		return false
	var loaded := document.generate_scene(state) as Node3D
	if loaded == null:
		return false
	var players := loaded.find_children("*", "AnimationPlayer", true, false)
	var skeletons := loaded.find_children("*", "Skeleton3D", true, false)
	if players.is_empty() or skeletons.is_empty():
		loaded.free()
		return false
	if character != null:
		push_warning("Replace the player scene to change characters at runtime")
		loaded.free()
		return false
	visual.add_child(loaded)
	character = loaded
	if tuning == null:
		var preset := "res://resources/player/" + path.get_file().get_basename().to_lower() + ".tres"
		tuning = load(preset) as LocomotionTuning if ResourceLoader.exists(preset) else LocomotionTuning.new()
	tuning = tuning.duplicate() as LocomotionTuning
	animation = AnimationScript.new()
	animation.name = "PlayerAnimation"
	add_child(animation)
	# Calibration uses a stationary, metre-space frame, independent of spawn height/yaw.
	var previous_transform := visual.transform
	visual.top_level = true
	visual.global_transform = Transform3D.IDENTITY
	var prepared := animation.setup(players[0] as AnimationPlayer, skeletons[0] as Skeleton3D, tuning)
	visual.top_level = false
	visual.transform = previous_transform
	if not prepared:
		animation.free()
		character.free()
		animation = null
		character = null
		return false
	loaded_path = path
	visual.global_rotation = Vector3(0.0, _yaw, 0.0)
	_setup_modifiers()
	# the game look: toon shading and outlines, the drawn face layers, and hair springs (added last, after the gaze)
	ToonMaterials.apply_to_tree(character, true, true)
	var face := FaceAtlas.new()
	face.name = "FaceAtlas"
	character.add_child(face)
	var springs := HairSprings.new()
	springs.name = "HairSprings"
	character.add_child(springs)
	return true

func _setup_modifiers() -> void:
	var rig := animation.skeleton
	rig.modifier_callback_mode_process = Skeleton3D.MODIFIER_CALLBACK_MODE_PROCESS_MANUAL
	pose_modifier = PoseScript.new()
	pose_modifier.name = "LocomotionPose"
	rig.add_child(pose_modifier)
	pose_modifier.setup(self, animation)
	var orientation = OrientationScript.new()
	orientation.name = "FootOrientation"
	orientation.placement = pose_modifier
	rig.add_child(orientation)
	_gaze_target = Node3D.new()
	_gaze_target.name = "GazeTarget"
	add_child(_gaze_target)
	_gaze_target.global_position = global_position + visual.basis.z * 4.0 + Vector3.UP * 1.5
	if ClassDB.class_exists("LookAtModifier3D"):
		for suffix in ["Neck", "Head"]:
			var bone := LocomotionClips.bone(rig, suffix)
			if bone < 0:
				continue
			var look := ClassDB.instantiate("LookAtModifier3D") as SkeletonModifier3D
			look.name = suffix + "Look"
			rig.add_child(look)
			look.set("bone_name", rig.get_bone_name(bone))
			look.set("target_node", look.get_path_to(_gaze_target))
			look.set("forward_axis", SkeletonModifier3D.BONE_AXIS_PLUS_Z)
			look.set("relative", true)
			look.set("use_angle_limitation", true)
			look.set("primary_limit_angle", deg_to_rad(15.0 if suffix == "Neck" else 40.0))
			look.set("secondary_limit_angle", deg_to_rad(10.0 if suffix == "Neck" else 20.0))
			look.set("duration", 0.25)
			_gaze_modifiers.append(look)

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadMotion and event.axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]:
		_movement_device = event.device

func set_hold(mode: PlayerAnimation.Hold) -> void:
	if animation != null:
		animation.set_hold(mode)

func _physics_process(delta: float) -> void:
	if animation == null:
		return
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back", 0.15)
	var stick := Vector2.ZERO
	if _movement_device >= 0:
		stick = Vector2(Input.get_joy_axis(_movement_device, JOY_AXIS_LEFT_X), Input.get_joy_axis(_movement_device, JOY_AXIS_LEFT_Y))
	_stick_running = stick.length() > (0.86 if _stick_running else 0.92)
	var running := Input.is_action_pressed("run") or _stick_running
	var sprinting := Input.is_action_pressed("sprint") and running
	var camera_basis := Basis(Vector3.UP, follow_camera.yaw)
	var direction := camera_basis * Vector3(input.x, 0.0, input.y)
	desired_speed = (tuning.sprint_speed if sprinting else tuning.run_speed if running else tuning.walk_speed) * input.length()
	if animation.hold_mode == PlayerAnimation.Hold.BOX:
		desired_speed = minf(desired_speed, tuning.run_speed * input.length())
	if animation.movement_locked:
		desired_speed *= animation.action_movement_scale
	var angle := angle_difference(_yaw, atan2(direction.x, direction.z)) if direction.length_squared() > 0.001 else 0.0
	if absf(angle) > deg_to_rad(105.0):
		_pivoting = true
	elif absf(angle) < deg_to_rad(30.0):
		_pivoting = false
	if _pivoting:
		desired_speed = 0.0
	if not _pivoting or horizontal_speed <= 0.18:
		var angular_target := clampf(angle * tuning.turn_rate, -tuning.turn_rate, tuning.turn_rate)
		_turn_velocity = lerpf(_turn_velocity, angular_target, 1.0 - exp(-delta / 0.07))
		_yaw += _turn_velocity * delta
	visual.global_rotation = Vector3(0.0, _yaw, 0.0)
	visual.position.y = lerpf(visual.position.y, 0.0, 1.0 - exp(-delta / 0.10))
	if input.length() > 0.1 and absf(angle) > deg_to_rad(65.0) and _previous_input.distance_to(input) > 0.7:
		var prefix := "TurnRun" if horizontal_speed > tuning.walk_speed + 0.1 else "TurnWalk" if horizontal_speed > 0.2 else "TurnIdle"
		animation.play_transition(prefix + ("L" if angle > 0.0 else "R"))
	# stopping and slowing from a run blend down through the gaits like a walk stop; the library's sudden-stop and
	# run-to-walk clips flail the arms (up to 57 degrees in a frame), so they are not played
	_previous_input = input
	_smooth_speed(delta)
	var forward := Vector3(sin(_yaw), 0.0, cos(_yaw))
	velocity.x = forward.x * _speed
	velocity.z = forward.z * _speed
	velocity.y = -0.1 if is_on_floor() else velocity.y - gravity * delta
	var was_grounded := is_on_floor()
	var previous_y := global_position.y
	_step_up(delta)
	var before := global_position
	move_and_slide()
	if velocity.y <= 0.0:
		apply_floor_snap()
	var height_change := global_position.y - previous_y
	if was_grounded and is_on_floor() and absf(height_change) > 0.04 and absf(height_change) < tuning.step_height + 0.05:
		visual.position.y -= height_change
	var displacement := global_position - before
	horizontal_speed = Vector2(displacement.x, displacement.z).length() / delta
	if is_on_wall() and horizontal_speed < _speed * 0.8:
		for index in get_slide_collision_count():
			if get_slide_collision(index).get_position().y > global_position.y + tuning.step_height + 0.05:
				_speed = horizontal_speed
				_speed_derivative = 0.0
	animation.advance(delta, horizontal_speed)
	pose_modifier.feet_enabled = foot_ik_enabled
	pose_modifier.lean_enabled = lean_enabled
	_update_gaze(delta)
	animation.skeleton.advance(delta)
	follow_camera.update_camera(delta, _yaw, horizontal_speed)
	if Input.is_action_just_pressed("interact"):
		interact()

func _smooth_speed(delta: float) -> void:
	var duration := tuning.acceleration_time if desired_speed > _speed else tuning.braking_time
	var omega := 2.0 / duration
	var change := _speed - desired_speed
	var temp := (_speed_derivative + omega * change) * delta
	var decay := exp(-omega * delta)
	_speed = maxf(0.0, desired_speed + (change + temp) * decay)
	_speed_derivative = (_speed_derivative - omega * temp) * decay

func _step_up(delta: float) -> void:
	if not is_on_floor() or _speed < 0.05 or tuning.step_height <= 0.0:
		return
	var motion := Vector3(velocity.x, 0.0, velocity.z) * delta
	var ahead := motion.normalized() * maxf(motion.length(), 0.08)
	var collision := KinematicCollision3D.new()
	var probe := global_transform
	probe.origin.y += 0.01
	if not test_move(probe, ahead, collision) or collision.get_normal().y > cos(floor_max_angle):
		return
	var raised := global_transform
	var rise := Vector3.UP * tuning.step_height
	if test_move(raised, rise):
		return
	raised.origin += rise
	if test_move(raised, ahead):
		return
	raised.origin += ahead
	var down := KinematicCollision3D.new()
	if test_move(raised, -rise, down) and down.get_normal().y > cos(floor_max_angle):
		var height := tuning.step_height + down.get_travel().y
		if height > 0.005:
			global_position.y += height

func nearest_interactable() -> Node3D:
	var nearest: Node3D
	var limit := interaction_distance * interaction_distance
	for node in get_tree().get_nodes_in_group("interactable"):
		if not node is Node3D:
			continue
		var distance := global_position.distance_squared_to(node.global_position)
		if distance < limit:
			var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, node.global_position + Vector3.UP * 0.4, collision_mask, [get_rid()])
			var hit := get_world_3d().direct_space_state.intersect_ray(query)
			if hit.is_empty() or hit.collider == node:
				nearest = node
				limit = distance
	return nearest

func interact() -> bool:
	var nearest := nearest_interactable()
	if nearest == null:
		return false
	return animation.request_action(String(nearest.get_meta("action", "Inspect")))

func _update_gaze(delta: float) -> void:
	var nearest := nearest_interactable()
	var aim := global_position + Vector3.UP * 1.5 - Basis(Vector3.UP, follow_camera.yaw).z * 5.0
	if nearest != null:
		aim = nearest.global_position + Vector3.UP * 0.8
	_gaze_target.global_position = _gaze_target.global_position.lerp(aim, 1.0 - exp(-delta / 0.18))
	# a target behind the shoulder would wrench the head round (or flip it between the limits): let go of it instead
	var to_aim := _gaze_target.global_position - global_position
	var facing := visual.global_basis.z
	to_aim.y = 0.0; facing.y = 0.0
	var ahead := smoothstep(-0.1, 0.5, facing.normalized().dot(to_aim.normalized())) if to_aim.length() > 0.01 else 0.0
	for modifier in _gaze_modifiers:
		var desired := 1.0 if look_at_enabled else 0.0
		desired *= (1.0 - animation.action_weight) * ahead
		modifier.influence = move_toward(modifier.influence, desired, delta / 0.2)
