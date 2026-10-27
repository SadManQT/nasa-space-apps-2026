extends SkeletonModifier3D

var placement: LocomotionPose
var _rotations: Array[Quaternion] = []

func _process_modification_with_delta(delta: float) -> void:
	if placement == null:
		return
	var rig := get_skeleton()
	for side in placement.solvers.size():
		if not placement.solvers[side].active:
			continue
		var bone := placement.foot_bones[side]
		var pose := rig.get_bone_global_pose(bone)
		pose.basis = rig.global_basis.inverse() * placement.foot_bases[side]
		rig.set_bone_global_pose(bone, pose)
		rig.set_bone_pose_rotation(placement.toe_bones[side], placement.toe_rotations[side])
	# Limit retargeted joint spikes after IK as well as before it.
	var fresh := _rotations.is_empty()
	var limit := deg_to_rad(placement.tuning.maximum_bone_degrees_per_second) * delta
	for bone in rig.get_bone_count():
		var pose := rig.get_bone_pose_rotation(bone)
		if fresh:
			_rotations.append(pose)
		else:
			var angle := _rotations[bone].angle_to(pose)
			_rotations[bone] = _rotations[bone].slerp(pose, minf(1.0, limit / maxf(angle, 0.00001))).normalized()
		rig.set_bone_pose_rotation(bone, _rotations[bone])
