extends CharacterBody3D
class_name RoverVehicle

## Shared physical rover for the campaign and Moon Trainer. The model owns budgets.
const Geometry = preload("res://scripts/asset_geometry.gd")
const RoverModel = preload("res://scripts/rover/lunar_rover.gd")

var model: RefCounted
var driver: PlayerController
var field: TerrainHeightfield
## Campaign terrain sessions can map their staged world coordinates to the source field.
var height_at_world: Callable
var slope_at_world: Callable
var controls_enabled := true
var in_shadow := false
var _cab: Camera3D
var _chase: Camera3D
var _headlights: Array[SpotLight3D] = []
var _visual: Node3D
var _dust: CPUParticles3D

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	floor_snap_length = 0.6
	floor_max_angle = deg_to_rad(40.0)
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.8
	capsule.height = 2.4
	collider.shape = capsule
	collider.position.y = 1.2
	add_child(collider)
	_visual = Geometry.load_glb("res://assets/vehicles/VH_Rover/VH_Rover.glb")
	if _visual != null:
		add_child(_visual)
		var bounds := Geometry.bounds(_visual)
		var scale_factor := 2.8 / maxf(0.1, bounds.size.y)
		_visual.scale *= scale_factor
		_visual.position = -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * scale_factor
		_visual.rotation.y = PI
	_cab = Camera3D.new()
	_cab.name = "CabCamera"
	_cab.position = Vector3(0.0, 2.2, -0.9)
	add_child(_cab)
	_chase = Camera3D.new()
	_chase.name = "ChaseCamera"
	_chase.position = Vector3(0.0, 4.6, 8.0)
	_chase.rotation.x = -0.28
	add_child(_chase)
	for x in [-0.85, 0.85]:
		var light := SpotLight3D.new()
		light.position = Vector3(x, 1.1, -2.2)
		light.spot_range = 45.0
		light.spot_angle = 30.0
		light.light_energy = 5.0
		light.shadow_enabled = true
		light.visible = false
		add_child(light)
		_headlights.append(light)
	_dust = CPUParticles3D.new()
	_dust.position = Vector3(0.0, 0.3, 1.8)
	_dust.amount = 24
	_dust.lifetime = 1.2
	_dust.direction = Vector3(0.0, 0.6, 0.8)
	_dust.spread = 18.0
	_dust.gravity = Vector3(0.0, -RoverModel.MOON_G, 0.0)
	_dust.initial_velocity_min = 0.6
	_dust.initial_velocity_max = 1.4
	var grain := SphereMesh.new()
	grain.radius = 0.025
	grain.height = 0.05
	_dust.mesh = grain
	_dust.emitting = false
	add_child(_dust)
	if model == null:
		model = RoverModel.new()

func bind_model(value: RefCounted, terrain_field: TerrainHeightfield = null) -> void:
	model = value
	field = terrain_field

func board(player: PlayerController) -> Dictionary:
	if player == null or player.global_position.distance_to(global_position) > 4.5:
		return {"accepted": false, "reason": "Walk up to the rover before boarding."}
	driver = player
	driver.set_controlled(false)
	driver.hide()
	driver.collision_layer = 0
	var result: Dictionary = model.board_rover()
	_sync_camera()
	return result

func exit_vehicle() -> Dictionary:
	var exit_position := global_position + global_basis.x * 2.5
	if field != null or slope_at_world.is_valid():
		model.current_slope_deg = _slope(global_position)
	var safe_exit := false
	for side in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK]:
		var candidate: Vector3 = global_position + global_basis * side * 2.8
		if field != null or height_at_world.is_valid():
			candidate.y = _height(candidate) + 0.15
		if _slope(candidate) > float(model.max_incline_deg):
			continue
		if is_inside_tree():
			var query := PhysicsShapeQueryParameters3D.new()
			var capsule := CapsuleShape3D.new()
			capsule.radius = 0.3
			capsule.height = 1.7
			query.shape = capsule
			query.transform = Transform3D(Basis.IDENTITY, candidate + Vector3.UP * 1.15)
			query.collision_mask = 1
			query.exclude = [get_rid()]
			if not get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
				continue
		exit_position = candidate
		safe_exit = true
		break
	if not safe_exit:
		return {"accepted": false, "reason": "Park beside clear, gentle ground before climbing out."}
	var result: Dictionary = model.disembark_rover()
	if not bool(result.get("accepted", false)):
		return result
	if driver != null:
		driver.global_position = exit_position
		driver.collision_layer = 2
		driver.show()
		driver.set_controlled(true)
		driver.reset_placement()
		driver = null
	return result

func toggle_camera_view() -> String:
	var view: String = model.toggle_camera_view()
	_sync_camera()
	return view

func active_camera() -> Camera3D:
	return _cab if model != null and String(model.camera_view) == "cab" else _chase

func _sync_camera() -> void:
	if driver != null and _cab != null:
		active_camera().make_current()

func _physics_process(delta: float) -> void:
	if model == null or not bool(model.aboard) or not controls_enabled:
		return
	step_controls(delta, Input.get_action_strength("move_forward"), Input.get_axis("move_left", "move_right"))

func _height(at: Vector3) -> float:
	return float(height_at_world.call(at.x, at.z)) if height_at_world.is_valid() else field.height_at(at.x, at.z)

func _slope(at: Vector3) -> float:
	return float(slope_at_world.call(at.x, at.z)) if slope_at_world.is_valid() else (field.slope_deg_at(at.x, at.z) if field != null else (rad_to_deg(get_floor_angle()) if is_on_floor() else 0.0))

func step_controls(delta: float, throttle: float, steering: float) -> Dictionary:
	if model == null:
		return {"accepted": false, "reason": "Rover model is not bound."}
	# Four-wheel steering lets a stopped rover pivot slowly (VIPER-style), so a slope clamp or a boulder never traps it.
	var steer := clampf(steering, -1.0, 1.0)
	rotation.y -= steer * delta * 3.0
	var forward := -global_basis.z
	var ahead := global_position + forward * maxf(1.5, float(model.speed_m_s) * delta)
	var slope := _slope(ahead)
	var before := global_position
	var distance_before := float(model.distance_driven_m)
	var battery_before := float(model.battery)
	var effective_throttle := 0.0 if absf(steer) > 0.25 else throttle
	model.step_drive(delta, effective_throttle, slope, in_shadow)
	if absf(steer) > 0.25:
		model.speed_m_s = move_toward(float(model.speed_m_s), 0.0, delta * 2.5)
	velocity.x = forward.x * float(model.speed_m_s)
	velocity.z = forward.z * float(model.speed_m_s)
	velocity.y = -0.2 if is_on_floor() else velocity.y - RoverModel.MOON_G * delta
	move_and_slide()
	if velocity.y <= 0.0:
		apply_floor_snap()
	var travelled := Vector2(global_position.x - before.x, global_position.z - before.z).length()
	var billed := float(model.distance_driven_m) - distance_before
	if billed > 0.0 and travelled < billed * 0.5 and (field != null or height_at_world.is_valid()):
		var step_pos := before + forward * billed
		step_pos.y = _height(step_pos) + 0.12
		global_position = step_pos
		travelled = Vector2(global_position.x - before.x, global_position.z - before.z).length()
	# Collisions must not charge distance that the physical rover did not travel.
	model.distance_driven_m = distance_before + travelled
	model.battery = maxf(0.0, battery_before - travelled * float(model.planned_one_way_energy) / maxf(1.0, float(model.planned_one_way_distance_m)))
	if billed > 0.0 and travelled < billed * 0.1:
		model.speed_m_s = 0.0
	if driver != null:
		driver.global_position = global_position + Vector3.UP * 1.0
		_sync_camera()
	for light in _headlights:
		light.visible = bool(model.headlights_on)
	if _dust != null:
		_dust.emitting = travelled > 0.005 and is_on_floor()
	return model.dashboard_readout()
