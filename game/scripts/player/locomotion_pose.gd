extends SkeletonModifier3D
class_name LocomotionPose

var actor: CharacterBody3D
var animation: PlayerAnimation
var tuning: LocomotionTuning
var feet_enabled: bool = true
var lean_enabled: bool = true
var targets: Array[Node3D] = []
var poles: Array[Node3D] = []
var solvers: Array[SkeletonModifier3D] = []
var foot_bones: Array[int] = []
var toe_bones: Array[int] = []
var locked: Array[bool] = [false, false]
var weights: Array[float] = [0.0, 0.0]
var foot_bases: Array[Basis] = [Basis.IDENTITY, Basis.IDENTITY]
var lock_positions: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var _lock_bases: Array[Basis] = [Basis.IDENTITY, Basis.IDENTITY]
var _rotations: Array[Quaternion] = []
var _positions: Array[Vector3] = []
var _previous_toes: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var _lean := Vector2.ZERO
var _last_velocity := Vector3.ZERO
var _last_yaw: float = 0.0
var _spine: int = -1
var _hips: int = -1
var _pelvis_offset: float = 0.0
var _surface_meter: RefCounted
var toe_rotations: Array[Quaternion] = [Quaternion.IDENTITY, Quaternion.IDENTITY]
var _lock_toes: Array[Quaternion] = [Quaternion.IDENTITY, Quaternion.IDENTITY]
var _released: Array[bool] = [false, false]
var _release_time: Array[float] = [0.0, 0.0]
var _ground: Array[float] = [INF, INF]

func setup(body: CharacterBody3D, motion: PlayerAnimation) -> void:
	actor = body
	animation = motion
	tuning = motion.tuning
	_spine = LocomotionClips.bone(get_skeleton(), "Spine")
	_hips = LocomotionClips.bone(get_skeleton(), "Hips")
	_surface_meter = LocomotionClips.FootSlideScript.new()
	_surface_meter.setup(animation.player.get_node(animation.player.root_node), get_skeleton())
	for side in ["Left", "Right"]:
		foot_bones.append(LocomotionClips.bone(get_skeleton(), side + "Foot"))
		toe_bones.append(LocomotionClips.bone(get_skeleton(), side + "ToeBase"))
		var target := Node3D.new()
		target.name = side + "FootTarget"
		actor.add_child(target)
		targets.append(target)
		var pole := Node3D.new()
		pole.name = side + "KneePole"
		actor.add_child(pole)
		poles.append(pole)
		if ClassDB.class_exists("TwoBoneIK3D"):
			var ik := ClassDB.instantiate("TwoBoneIK3D") as SkeletonModifier3D
			ik.name = side + "FootIK"
			get_skeleton().add_child(ik)
			ik.set("setting_count", 1)
			ik.call("set_root_bone_name", 0, get_skeleton().get_bone_name(LocomotionClips.bone(get_skeleton(), side + "UpLeg")))
			ik.call("set_middle_bone_name", 0, get_skeleton().get_bone_name(LocomotionClips.bone(get_skeleton(), side + "Leg")))
			ik.call("set_end_bone_name", 0, get_skeleton().get_bone_name(foot_bones[-1]))
			ik.call("set_target_node", 0, ik.get_path_to(target))
			ik.call("set_pole_node", 0, ik.get_path_to(pole))
			ik.influence = 1.0
			ik.active = false
			solvers.append(ik)
	_last_yaw = animation.skeleton.global_basis.get_euler().y

func _process_modification_with_delta(delta: float) -> void:
	if animation == null or delta <= 0.0:
		return
	var rig := get_skeleton()
	var weight := 1.0 - exp(-delta / tuning.pose_smoothing)
	var fresh := _rotations.is_empty()
	for bone in rig.get_bone_count():
		var q := rig.get_bone_pose_rotation(bone)
		var p := rig.get_bone_pose_position(bone)
		if fresh:
			_rotations.append(q)
			_positions.append(p)
		else:
			_rotations[bone] = _rotations[bone].slerp(q, weight).normalized()
			_positions[bone] = _positions[bone].lerp(p, weight)
		rig.set_bone_pose_rotation(bone, _rotations[bone])
		rig.set_bone_pose_position(bone, _positions[bone])
	_update_lean(delta)
	if solvers.size() == 2:
		_update_feet(delta, fresh)

func _update_lean(delta: float) -> void:
	var rig := get_skeleton()
	var yaw := rig.global_basis.get_euler().y
	var turn := angle_difference(_last_yaw, yaw) / delta
	var acceleration := (actor.velocity - _last_velocity) / delta
	var forward := rig.global_basis.z.normalized()
	var limit := deg_to_rad(tuning.lean_degrees)
	var desired := Vector2(clampf(acceleration.dot(forward) * 0.008, -limit, limit), clampf(-turn * animation.horizontal_speed * 0.018, -limit, limit))
	if not lean_enabled or animation.action_weight > 0.1:
		desired = Vector2.ZERO
	_lean = _lean.lerp(desired, 1.0 - exp(-delta / 0.18))
	if _spine >= 0:
		var base := rig.get_bone_pose_rotation(_spine)
		rig.set_bone_pose_rotation(_spine, (base * Quaternion.from_euler(Vector3(_lean.x, 0.0, _lean.y))).normalized())
	_last_velocity = actor.velocity
	_last_yaw = yaw

func _update_feet(delta: float, fresh: bool) -> void:
	var rig := get_skeleton()
	if fresh:
		for side in 2:
			_previous_toes[side] = rig.get_bone_global_pose(toe_bones[side]).origin
		return
	var speed := animation.horizontal_speed
	var gait := animation.clips.gaits[0 if speed < tuning.walk_speed + 0.05 else 1]
	if speed > tuning.run_speed + 0.05:
		gait = animation.clips.gaits[2]
	var min_heights: Array = animation.clips.measurements[gait].min_toe_y
	var surfaces: Dictionary = _surface_meter.sample(delta)
	for side in 2:
		var foot := rig.global_transform * rig.get_bone_global_pose(foot_bones[side])
		var toe := rig.global_transform * rig.get_bone_global_pose(toe_bones[side]).origin
		var local_toe := rig.to_local(toe)
		var backwards := (local_toe.z - _previous_toes[side].z) / delta < -0.05
		_previous_toes[side] = local_toe
		var surface: Dictionary = surfaces["left" if side == 0 else "right"]
		var low := float(surface.height) - actor.global_position.y < 0.04 or local_toe.y < float(min_heights[side]) + 0.025
		if not low or not backwards:
			_released[side] = false
		var contact := (low and backwards) or speed < 0.06
		var enabled := feet_enabled and actor.is_on_floor() and (animation.action_weight < 0.05 or animation.action_is_transition)
		var query := PhysicsRayQueryParameters3D.create(foot.origin + Vector3.UP * 0.35, foot.origin - Vector3.UP * 0.55, actor.collision_mask, [actor.get_rid()])
		var hit := actor.get_world_3d().direct_space_state.intersect_ray(query)
		enabled = enabled and not hit.is_empty() and hit.normal.y > cos(actor.floor_max_angle)
		_ground[side] = float(hit.position.y) if enabled else INF
		contact = contact and enabled and not fresh
		var prefix := "Left" if side == 0 else "Right"
		var hip := rig.global_transform * rig.get_bone_global_pose(LocomotionClips.bone(rig, prefix + "UpLeg")).origin
		var knee := rig.global_transform * rig.get_bone_global_pose(LocomotionClips.bone(rig, prefix + "Leg")).origin
		var length := hip.distance_to(knee) + knee.distance_to(foot.origin) - 0.025
		var predicted_hip := hip + actor.velocity * 0.04 - Vector3.UP * 0.10
		if locked[side] and predicted_hip.distance_to(lock_positions[side]) > length:
			_released[side] = true
		contact = contact and not _released[side]
		if contact and not locked[side]:
			lock_positions[side] = foot.origin
			lock_positions[side].y += float(hit.position.y) - float(surface.height)
			_lock_bases[side] = Basis(Quaternion(Vector3.UP, hit.normal)) * foot.basis.orthonormalized()
			_lock_toes[side] = rig.get_bone_pose_rotation(toe_bones[side])
		if contact:
			_release_time[side] = 0.0
			weights[side] = move_toward(weights[side], 1.0, delta / 0.05)
		else:
			_release_time[side] += delta
			weights[side] = minf(weights[side], 1.0 - smoothstep(0.0, 0.16, _release_time[side]))
		locked[side] = contact
		var target := foot.origin
		target = target.lerp(lock_positions[side], weights[side])
		if not contact and weights[side] > 0.0:
			target.y += 0.08 * sin(PI * clampf(_release_time[side] / 0.16, 0.0, 1.0))
		var clearance := 0.0
		if enabled and not contact:
			clearance = maxf(0.0, float(hit.position.y) + 0.035 - float(surface.height))
			target.y = maxf(target.y, foot.origin.y + clearance)
		targets[side].global_position = target
		poles[side].global_position = knee + rig.global_basis.z * 1.5
		foot_bases[side] = foot.basis.orthonormalized().slerp(_lock_bases[side], weights[side])
		toe_rotations[side] = rig.get_bone_pose_rotation(toe_bones[side]).slerp(_lock_toes[side], weights[side])
		solvers[side].active = weights[side] > 0.0 or clearance > 0.0
		solvers[side].influence = 1.0
	_clear_swing_feet()
	_adjust_pelvis(delta)

func _clear_swing_feet() -> void:
	var rig := get_skeleton()
	var poses: Array[Transform3D] = []
	var toes: Array[Quaternion] = []
	for side in 2:
		var pose := rig.get_bone_global_pose(foot_bones[side])
		poses.append(pose)
		toes.append(rig.get_bone_pose_rotation(toe_bones[side]))
		pose.basis = rig.global_basis.inverse() * foot_bases[side]
		rig.set_bone_global_pose(foot_bones[side], pose)
		rig.set_bone_pose_rotation(toe_bones[side], toe_rotations[side])
	var surface: Dictionary = _surface_meter.sample(0.0)
	for side in 2:
		if not locked[side] and is_finite(_ground[side]):
			var original := rig.global_transform * poses[side].origin
			var bottom: float = surface["left" if side == 0 else "right"].height
			var desired := original.y + _ground[side] + 0.06 - bottom
			if desired > targets[side].global_position.y:
				targets[side].global_position.y = desired
				solvers[side].active = true
		rig.set_bone_global_pose(foot_bones[side], poses[side])
		rig.set_bone_pose_rotation(toe_bones[side], toes[side])

func _adjust_pelvis(delta: float) -> void:
	var rig := get_skeleton()
	var drop := 0.0
	for side in 2:
		if weights[side] < 0.01:
			continue
		var prefix := "Left" if side == 0 else "Right"
		var hip := rig.global_transform * rig.get_bone_global_pose(LocomotionClips.bone(rig, prefix + "UpLeg")).origin
		var knee := rig.global_transform * rig.get_bone_global_pose(LocomotionClips.bone(rig, prefix + "Leg")).origin
		var foot := rig.global_transform * rig.get_bone_global_pose(foot_bones[side]).origin
		var length := hip.distance_to(knee) + knee.distance_to(foot) - 0.015
		var target := targets[side].global_position
		var horizontal := Vector2(target.x - hip.x, target.z - hip.z).length_squared()
		var height := sqrt(maxf(0.01, length * length - horizontal))
		drop = maxf(drop, hip.y - target.y - height)
	var desired := clampf(drop, 0.0, 0.20)
	_pelvis_offset = desired if desired > _pelvis_offset else lerpf(_pelvis_offset, desired, 1.0 - exp(-delta / 0.10))
	var position := rig.get_bone_pose_position(_hips)
	position.y -= _pelvis_offset
	rig.set_bone_pose_position(_hips, position)
