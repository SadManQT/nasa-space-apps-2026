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

func setup(actor: Node3D, skeleton: Skeleton3D) -> void:
	_actor = actor
	_skeleton = skeleton
	_boots.clear()
	_foot_bones = [_bone("LeftFoot"), _bone("RightFoot")]
	_hip_bone = _bone("Hips")
	for instance: MeshInstance3D in actor.find_children("*", "MeshInstance3D", true, false):
		if instance.skin == null or instance.get_node_or_null(instance.skeleton) != skeleton:
			continue
		var skin := instance.skin
		var bones: Array[int] = []
		var binds: Array[Transform3D] = []
		for i in skin.get_bind_count():
			var bone := skin.get_bind_bone(i)
			if not skin.get_bind_name(i).is_empty():
				bone = skeleton.find_bone(skin.get_bind_name(i))
			bones.append(bone)
			binds.append(skin.get_bind_pose(i))
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
				var left := 0.0
				var right := 0.0
				var vertex_bones: Array[int] = []
				var vertex_binds: Array[Vector3] = []
				var vertex_weights: Array[float] = []
				for j in influences:
					var at: int = v * influences + j
					if weights[at] <= 0.0:
						continue
					var bind := joints[at]
					var bone := bones[bind]
					if bone < 0:
						continue
					var name := skeleton.get_bone_name(bone)
					if name.contains("LeftFoot") or name.contains("LeftToe"):
						left += weights[at]
					if name.contains("RightFoot") or name.contains("RightToe"):
						right += weights[at]
					vertex_bones.append(bone)
					vertex_binds.append(binds[bind] * vertices[v])
					vertex_weights.append(weights[at])
				# Include the full boot; heel/toe rotation can change the lowest point.
				if maxf(left, right) > 0.5:
					selected.append({"side": 0 if left > right else 1, "bones": vertex_bones, "binds": vertex_binds, "weights": vertex_weights})
			_boots.append({"vertices": selected})
	reset()

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
