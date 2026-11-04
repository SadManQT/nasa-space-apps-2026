# B03 review measurement. Skin boot vertices on the CPU so floor contact refers
# to the boot surface, not the ankle joint ~10 cm above it. Units: metres/seconds.
extends RefCounted

const CONTACT_HEIGHT: float = 0.02

var _actor: Node3D
var _skeleton: Skeleton3D
var _boots: Array[Dictionary] = []
var _previous: Array[PackedVector3Array] = []
var _previous_root := Vector3.ZERO
var _previous_hip := Vector3.ZERO
var _previous_feet: Array[Vector3] = []
var _foot_bones: Array[int] = []
var _hip_bone: int = -1
var _ready: bool = false
# Runtime IK needs only the lowest boot points, not the review's per-vertex
# velocity/contact history. Keep the identical vertices/weights in flat arrays.
static var _boot_cache: Dictionary = {}
var _side_bones: Array[PackedInt32Array] = [PackedInt32Array(), PackedInt32Array()]
var _side_p0: Array[PackedVector3Array] = [PackedVector3Array(), PackedVector3Array()]
var _side_p1: Array[PackedVector3Array] = [PackedVector3Array(), PackedVector3Array()]
var _side_p2: Array[PackedVector3Array] = [PackedVector3Array(), PackedVector3Array()]
var _side_w: Array[PackedVector3Array] = [PackedVector3Array(), PackedVector3Array()]
var _extra_offsets := PackedInt32Array()
var _extra_sides := PackedInt32Array()
var _extra_bones := PackedInt32Array()
var _extra_binds := PackedVector3Array()
var _extra_weights := PackedFloat32Array()

func setup(actor: Node3D, skeleton: Skeleton3D) -> void:
	_actor = actor
	_skeleton = skeleton
	_boots.clear()
	_foot_bones = [_bone("LeftFoot"), _bone("RightFoot")]
	_hip_bone = _bone("Hips")
	_side_bones = [
		PackedInt32Array([_bone("LeftLeg"), _bone("LeftFoot"), _bone("LeftToeBase")]),
		PackedInt32Array([_bone("RightLeg"), _bone("RightFoot"), _bone("RightToeBase")]),
	]
	for instance: MeshInstance3D in actor.find_children("*", "MeshInstance3D", true, false):
		if instance.skin == null or instance.get_node_or_null(instance.skeleton) != skeleton:
			continue
		var cache_key := "%d:%d:%d" % [instance.mesh.get_rid().get_id(), instance.skin.get_rid().get_id(), skeleton.get_bone_count()]
		if _boot_cache.has(cache_key):
			var cached: Array = _boot_cache[cache_key]
			for surface_entry in cached:
				_boots.append(surface_entry)
			continue
		var skin := instance.skin
		var bones := PackedInt32Array()
		var binds: Array[Transform3D] = []
		var bind_side := PackedInt32Array()
		var bind_count := skin.get_bind_count()
		bones.resize(bind_count)
		bind_side.resize(bind_count)
		for i in bind_count:
			var bone := skin.get_bind_bone(i)
			if not skin.get_bind_name(i).is_empty():
				bone = skeleton.find_bone(skin.get_bind_name(i))
			bones[i] = bone
			binds.append(skin.get_bind_pose(i))
			var s := 0
			if bone >= 0:
				var name := skeleton.get_bone_name(bone)
				if name.contains("LeftFoot") or name.contains("LeftToe"):
					s = 1
				elif name.contains("RightFoot") or name.contains("RightToe"):
					s = 2
			bind_side[i] = s
		var instance_surfaces: Array[Dictionary] = []
		for surface in instance.mesh.get_surface_count():
			var arrays := instance.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var joints: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			if vertices.is_empty() or joints.is_empty():
				continue
			var influences := joints.size() / vertices.size()
			var selected: Array[Dictionary] = []
			for v in vertices.size():
				var base := v * influences
				var left := 0.0
				var right := 0.0
				for j in influences:
					var w := weights[base + j]
					if w <= 0.0:
						continue
					var s := bind_side[joints[base + j]]
					if s == 1:
						left += w
					elif s == 2:
						right += w
				# Include the full boot; heel/toe rotation can change the lowest point.
				if maxf(left, right) <= 0.5:
					continue
				var vertex_bones: Array[int] = []
				var vertex_binds: Array[Vector3] = []
				var vertex_weights: Array[float] = []
				var raw_v := vertices[v]
				for j in influences:
					var at: int = base + j
					var w := weights[at]
					if w <= 0.0:
						continue
					var bind := joints[at]
					var bone := bones[bind]
					if bone < 0:
						continue
					vertex_bones.append(bone)
					vertex_binds.append(binds[bind] * raw_v)
					vertex_weights.append(w)
				selected.append({"side": 0 if left > right else 1, "bones": vertex_bones, "binds": vertex_binds, "weights": vertex_weights})
			var entry := {"vertices": selected}
			_boots.append(entry)
			instance_surfaces.append(entry)
		_boot_cache[cache_key] = instance_surfaces
	for side in 2:
		_side_p0[side].clear()
		_side_p1[side].clear()
		_side_p2[side].clear()
		_side_w[side].clear()
	_extra_offsets.clear()
	_extra_sides.clear()
	_extra_bones.clear()
	_extra_binds.clear()
	_extra_weights.clear()
	for surface in _boots:
		for vertex in surface.vertices:
			var side: int = vertex.side
			var sb := _side_bones[side]
			var b0 := sb[0]
			var b1 := sb[1]
			var b2 := sb[2]
			var p0 := Vector3.ZERO
			var p1 := Vector3.ZERO
			var p2 := Vector3.ZERO
			var w_vec := Vector3.ZERO
			var fits := true
			for influence in vertex.bones.size():
				var bone: int = vertex.bones[influence]
				var bind_v: Vector3 = vertex.binds[influence]
				var w: float = vertex.weights[influence]
				if bone == b0:
					p0 += bind_v * w
					w_vec.x += w
				elif bone == b1:
					p1 += bind_v * w
					w_vec.y += w
				elif bone == b2:
					p2 += bind_v * w
					w_vec.z += w
				else:
					fits = false
					break
			if fits:
				_side_p0[side].append(p0)
				_side_p1[side].append(p1)
				_side_p2[side].append(p2)
				_side_w[side].append(w_vec)
			else:
				_extra_offsets.append(_extra_bones.size())
				_extra_sides.append(side)
				for influence in vertex.bones.size():
					_extra_bones.append(vertex.bones[influence])
					_extra_binds.append(vertex.binds[influence])
					_extra_weights.append(vertex.weights[influence])
	_extra_offsets.append(_extra_bones.size())
	reset()

## Exact skinned heights in world space, including all boot vertices and all
## influences. Dot only the Y row; X/Z, velocities and contact arrays are unused
## by locomotion. Does not change the review sampler's temporal state.
func sample_heights(side_filter: int = -1) -> Dictionary:
	var skel_xf := _skeleton.global_transform
	var heights: Array[float] = [INF, INF]
	for side in 2:
		if side_filter >= 0 and side_filter != side:
			continue
		var sb := _side_bones[side]
		var p0_arr := _side_p0[side]
		var count := p0_arr.size()
		if count > 0:
			var p1_arr := _side_p1[side]
			var p2_arr := _side_p2[side]
			var w_arr := _side_w[side]
			var pose0 := skel_xf * _skeleton.get_bone_global_pose(sb[0]) if sb[0] >= 0 else skel_xf
			var pose1 := skel_xf * _skeleton.get_bone_global_pose(sb[1]) if sb[1] >= 0 else skel_xf
			var pose2 := skel_xf * _skeleton.get_bone_global_pose(sb[2]) if sb[2] >= 0 else skel_xf
			var r0 := Vector3(pose0.basis.x.y, pose0.basis.y.y, pose0.basis.z.y)
			var r1 := Vector3(pose1.basis.x.y, pose1.basis.y.y, pose1.basis.z.y)
			var r2 := Vector3(pose2.basis.x.y, pose2.basis.y.y, pose2.basis.z.y)
			var o := Vector3(pose0.origin.y, pose1.origin.y, pose2.origin.y)
			var min_h := INF
			for i in count:
				var h := r0.dot(p0_arr[i]) + r1.dot(p1_arr[i]) + r2.dot(p2_arr[i]) + o.dot(w_arr[i])
				if h < min_h:
					min_h = h
			heights[side] = min_h
	if not _extra_sides.is_empty():
		var rows := PackedVector3Array()
		var origins := PackedFloat32Array()
		for bone in _skeleton.get_bone_count():
			var pose := skel_xf * _skeleton.get_bone_global_pose(bone)
			rows.append(Vector3(pose.basis.x.y, pose.basis.y.y, pose.basis.z.y))
			origins.append(pose.origin.y)
		for vertex in _extra_sides.size():
			var side := _extra_sides[vertex]
			if side_filter >= 0 and side_filter != side:
				continue
			var height := 0.0
			for influence in range(_extra_offsets[vertex], _extra_offsets[vertex + 1]):
				var bone := _extra_bones[influence]
				height += (rows[bone].dot(_extra_binds[influence]) + origins[bone]) * _extra_weights[influence]
			heights[side] = minf(heights[side], height)
	return {"left": {"height": heights[0]}, "right": {"height": heights[1]}}

func reset() -> void:
	_ready = false
	_previous.clear()
	_previous_feet.clear()

func sample(delta: float) -> Dictionary:
	var result := {"root_speed": 0.0, "hip_speed": 0.0}
	var feet: Array[Dictionary] = []
	for side in 2:
		feet.append({"foot_speed": 0.0, "slide_speed": 0.0, "contact_samples": 0, "height": INF, "vertices": 0})
	var transforms: Array[Transform3D] = []
	for bone in _skeleton.get_bone_count():
		transforms.append(_skeleton.global_transform * _skeleton.get_bone_global_pose(bone))
	var current: Array[PackedVector3Array] = []
	for surface in _boots.size():
		var positions := PackedVector3Array()
		var vertices: Array = _boots[surface].vertices
		for v in vertices.size():
			var vertex: Dictionary = vertices[v]
			var position := Vector3.ZERO
			for j in vertex.bones.size():
				position += (transforms[vertex.bones[j]] * vertex.binds[j]) * vertex.weights[j]
			positions.append(position)
			var foot: Dictionary = feet[vertex.side]
			foot.height = minf(foot.height, position.y)
			foot.vertices += 1
			# Both endpoints must be close to y=0. Penetration deeper than 2 cm
			# is not silently classified as contact. Keep the signed clearance.
			if _ready and delta > 0.0:
				var previous := _previous[surface][v]
				if absf(position.y) <= CONTACT_HEIGHT and absf(previous.y) <= CONTACT_HEIGHT:
					foot.slide_speed += _speed(previous, position, delta)
					foot.contact_samples += 1
		current.append(positions)
	var root_position := _actor.global_position
	var hip_position := transforms[_hip_bone].origin if _hip_bone >= 0 else root_position
	for side in 2:
		var foot_position := transforms[_foot_bones[side]].origin if _foot_bones[side] >= 0 else root_position
		if _ready and delta > 0.0:
			feet[side].foot_speed = _speed(_previous_feet[side], foot_position, delta)
		if feet[side].contact_samples > 0:
			feet[side].slide_speed /= feet[side].contact_samples
		if not _ready:
			_previous_feet.append(foot_position)
		else:
			_previous_feet[side] = foot_position
	if _ready and delta > 0.0:
		result.root_speed = _speed(_previous_root, root_position, delta)
		result.hip_speed = _speed(_previous_hip, hip_position, delta)
	_previous_root = root_position
	_previous_hip = hip_position
	_previous = current
	_ready = true
	result.left = feet[0]
	result.right = feet[1]
	return result

func _bone(suffix: String) -> int:
	for i in _skeleton.get_bone_count():
		var name := _skeleton.get_bone_name(i)
		if name == suffix or name.ends_with("_" + suffix) or name.ends_with(":" + suffix):
			return i
	return -1

func _speed(previous: Vector3, current: Vector3, delta: float) -> float:
	return Vector2(current.x - previous.x, current.z - previous.z).length() / delta
