extends Node3D
class_name FollowCamera

@export var active := true
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
## Obstacles pull the camera in quickly but never within a single frame. Running through the
## Safe Room's seat rows snapped the arm in by up to 0.5 m between two frames, so the player
## jumped 80 px on screen (13 Nov review, M1-129).
@export var pull_in_time: float = 0.07
## How far the eased camera may trail an obstacle: less than the probe sphere's radius plus the
## spring margin (0.30 m), so the near plane (0.05 m) never reaches the surface.
const PULL_IN_SLACK_M := 0.18
## Static world the camera keeps clear of (the spring arm itself no longer collides: this script
## is the single owner of camera collision, so the two cannot fight over the arm length).
@export_flags_3d_physics var obstacle_mask: int = 1

var yaw: float = 0.0
var pitch: float = -0.12
var spring: SpringArm3D
var camera: Camera3D
var target: CharacterBody3D
var _anchor := Vector3.ZERO
var _quiet_time: float = 0.0
var _initialized: bool = false
var _arm_length: float = 0.0
var _shoulder_fraction: float = 1.0
var _snap := true

## A real play session may take the pointer; tools, tests and clip recording never do.
static func may_capture_pointer() -> bool:
	var args := OS.get_cmdline_args()
	return DisplayServer.get_name() != "headless" and not (args.has("--script") or args.has("-s") or args.has("--write-movie"))

func _ready() -> void:
	target = get_parent() as CharacterBody3D
	top_level = true
	spring = SpringArm3D.new()
	spring.name = "SpringArm3D"
	spring.spring_length = distance
	_arm_length = distance
	spring.margin = 0.12
	spring.collision_mask = 0  # collision is swept and eased in update_camera (obstacle_mask)
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
	camera.current = active
	spring.add_child(camera)
	if active and capture_mouse and may_capture_pointer():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		look(event.screen_relative * mouse_sensitivity)
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and may_capture_pointer():
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
	var reach := desired.distance_to(shoulder)
	var shoulder_room := desired.distance_to(_safe_point(desired, shoulder)) / reach if reach > 0.001 else 1.0
	_shoulder_fraction = _eased_room(_shoulder_fraction, shoulder_room, delta, reach)
	global_position = desired.lerp(shoulder, _shoulder_fraction)
	var endpoint := global_position + global_basis.z * distance
	var safe_endpoint := _safe_point(global_position, endpoint)
	var available := minf(distance, global_position.distance_to(safe_endpoint))
	_arm_length = _eased_room(_arm_length / distance, available / distance, delta, distance) * distance
	_snap = false
	spring.spring_length = _arm_length
	# Set immediately as well as using the arm's physics update (including inward moves).
	camera.position.z = spring.spring_length

## Moves a 0..1 fraction of free room toward what the sweep found: inward fast (pull_in_time) but
## never more than PULL_IN_SLACK_M behind the obstacle, outward slowly (collision_recovery).
## A placement reset (teleport, scene cut) takes the new room at once.
func _eased_room(current: float, room: float, delta: float, length_m: float) -> float:
	if _snap or length_m <= 0.001:
		return room
	if room < current:
		var eased := lerpf(current, room, 1.0 - exp(-delta / maxf(pull_in_time, 0.001)))
		return clampf(eased, room, room + PULL_IN_SLACK_M / length_m)
	return lerpf(current, room, 1.0 - exp(-delta / maxf(collision_recovery, 0.001)))

func _safe_point(from: Vector3, to: Vector3) -> Vector3:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = spring.shape
	query.transform = Transform3D(Basis.IDENTITY, from)
	query.motion = to - from
	query.collision_mask = obstacle_mask
	query.exclude = [target.get_rid()]
	var fractions := target.get_world_3d().direct_space_state.cast_motion(query)
	var length := from.distance_to(to)
	var fraction := maxf(0.0, fractions[0] - spring.margin / maxf(length, 0.001)) if fractions[0] < 1.0 else 1.0
	return from.lerp(to, fraction)

func reset_placement() -> void:
	_initialized = false
	_quiet_time = 0.0
	_arm_length = distance
	_shoulder_fraction = 1.0
	_snap = true
