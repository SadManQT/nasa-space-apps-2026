extends RefCounted
class_name AssetGeometry

static func load_glb(path: String) -> Node3D:
	if not FileAccess.file_exists(path):
		push_error("Missing GLB: " + path)
		return null
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	state.handle_binary_image = GLTFState.HANDLE_BINARY_EMBED_AS_UNCOMPRESSED
	var error := document.append_from_file(path, state)
	if error != OK:
		push_error("GLB import failed (%s): %s" % [error, path])
		return null
	return document.generate_scene(state) as Node3D

static func bounds(root: Node3D, posed: bool = false) -> AABB:
	var result := AABB()
	var first := true
	var meshes := root.find_children("*", "MeshInstance3D", true, false)
	if root is MeshInstance3D:
		meshes.append(root)
	for node in meshes:
		var mesh := node as MeshInstance3D
		if mesh.mesh == null:
			continue
		var box := root.global_transform.affine_inverse() * mesh.global_transform * mesh.get_aabb()
		var rig := mesh.get_node_or_null(mesh.skeleton) as Skeleton3D
		if posed and mesh.skin != null and rig != null:
			box = _posed_bounds(mesh, rig, root)
		result = box if first else result.merge(box)
		first = false
	return result

static func _posed_bounds(mesh: MeshInstance3D, rig: Skeleton3D, root: Node3D) -> AABB:
	var transforms: Array[Transform3D] = []
	var to_root := root.global_transform.affine_inverse() * rig.global_transform
	for index in mesh.skin.get_bind_count():
		var bone := mesh.skin.get_bind_bone(index)
		if not mesh.skin.get_bind_name(index).is_empty():
			bone = rig.find_bone(mesh.skin.get_bind_name(index))
		transforms.append(to_root * rig.get_bone_global_pose(bone) * mesh.skin.get_bind_pose(index))
	var result := AABB()
	var first := true
	for surface in mesh.mesh.get_surface_count():
		var arrays := mesh.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var influences := bones.size() / vertices.size()
		for vertex in vertices.size():
			var point := Vector3.ZERO
			for influence in influences:
				var at: int = vertex * influences + influence
				if weights[at] > 0.0:
					point += (transforms[bones[at]] * vertices[vertex]) * weights[at]
			result = AABB(point, Vector3.ZERO) if first else result.expand(point)
			first = false
	return result
