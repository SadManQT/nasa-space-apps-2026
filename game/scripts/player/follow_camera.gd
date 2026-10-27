extends Node3D
class_name FollowCamera

@export var distance: float = 3.3
@export var shoulder_offset: float = 0.42
@export var target_height: float = 1.4
@export var mouse_sensitivity: float = 0.0025
@export var stick_sensitivity: float = 2.0
@export var invert_y: bool = false
@export var min_pitch_degrees: float = -55.0
@export var max_pitch_degrees: float = 65.0
@export var position_lag: float = 0.10
@export var collision_recovery: float = 0.18
@export var recenter_delay: float = 1.5
@export var recenter_speed: float = 1.4
@export var capture_mouse: bool = true

var yaw: float = 0.0
var pitch: float = -0.12
var spring: SpringArm3D
var camera: Camera3D
var target: CharacterBody3D
var _anchor := Vector3.ZERO
var _quiet_time: float = 0.0
var _initialized: bool = false
var _arm_length: float = 0.0

func _ready() -> void:
	target = get_parent() as CharacterBody3D
	top_level = true
	spring = SpringArm3D.new()
	spring.name = "SpringArm3D"
	spring.spring_length = distance
	_arm_length = distance
	spring.margin = 0.12
	spring.collision_mask = 1
	var shape := SphereShape3D.new()
	shape.radius = 0.18
	spring.shape = shape
	add_child(spring)
	if target != null:
		spring.add_excluded_object(target.get_rid())
	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.fov = 65.0
	camera.near = 0.05
	camera.current = true
	spring.add_child(camera)
	if capture_mouse and DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		look(event.screen_relative * mouse_sensitivity)
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func look(motion: Vector2) -> void:
	yaw -= motion.x
	pitch -= motion.y * (-1.0 if invert_y else 1.0)
	pitch = clampf(pitch, deg_to_rad(min_pitch_degrees), deg_to_rad(max_pitch_degrees))
	_quiet_time = 0.0

func update_camera(delta: float, facing_yaw: float, speed: float) -> void:
	if target == null:
		return
	var stick := Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down", 0.18)
	if stick.length_squared() > 0.0:
		look(stick * stick_sensitivity * delta)
	else:
		_quiet_time += delta
	if _quiet_time > recenter_delay and speed > 0.2:
		yaw = lerp_angle(yaw, facing_yaw - PI, 1.0 - exp(-recenter_speed * delta))
	var desired := target.global_position + Vector3.UP * target_height
	_anchor = _anchor.lerp(desired, 1.0 - exp(-delta / maxf(position_lag, 0.001))) if _initialized else desired
	_initialized = true
	global_position = _anchor
	rotation = Vector3(pitch, yaw, 0.0)
	# Sweep the shoulder too; a spring alone cannot protect a pivot inside a wall.
	var shoulder := _anchor + global_basis.x * shoulder_offset
	var safe_shoulder := _safe_point(desired, shoulder)
	global_position = safe_shoulder
	var endpoint := global_position + global_basis.z * distance
	var safe_endpoint := _safe_point(global_position, endpoint)
	var available := minf(distance, global_position.distance_to(safe_endpoint))
	_arm_length = available if available < _arm_length else lerpf(_arm_length, available, 1.0 - exp(-delta / maxf(collision_recovery, 0.001)))
	spring.spring_length = _arm_length
	# Set immediately as well as using the arm's physics update (including inward moves).
	camera.position.z = spring.spring_length

func _safe_point(from: Vector3, to: Vector3) -> Vector3:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = spring.shape
	query.transform = Transform3D(Basis.IDENTITY, from)
	query.motion = to - from
	query.collision_mask = spring.collision_mask
	query.exclude = [target.get_rid()]
	var fractions := target.get_world_3d().direct_space_state.cast_motion(query)
	var length := from.distance_to(to)
	var fraction := maxf(0.0, fractions[0] - spring.margin / maxf(length, 0.001)) if fractions[0] < 1.0 else 1.0
	return from.lerp(to, fraction)
