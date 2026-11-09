extends RefCounted
class_name AssetGeometry

# Raw glTF preserves the approved runtime look (including face layers). Reuse
# its parsed resources instead of decoding images/meshes on every room cut.
# Bound retained scenes; live instances keep their own resources alive on eviction.
# 28 holds the largest working set without evicting: the garden (12 with its dated plant
# models) plus the power room (6) as the look-ahead, plus the five cast bodies and five EVA suits.
const CACHE_LIMIT := 28
const ANIM_BATCH_SIZE := 8
static var _scenes: Dictionary = {}
static var _recent: Array[String] = []
static var pinned: Array[String] = []

static var _image_extension: GLTFDocumentExtension
static var _raw_loader: ResourceFormatLoader
static var _requests: Dictionary = {}

static func request(path: String) -> Error:
	if is_prepared(path) or _requests.has(path):
		return OK
	if not FileAccess.file_exists(path):
		return ERR_FILE_NOT_FOUND
	if _raw_loader == null:
		_image_extension = preload("res://scripts/loading/raw_gltf_images.gd").new()
		GLTFDocument.register_gltf_document_extension(_image_extension, true)
		_raw_loader = preload("res://scripts/loading/raw_gltf_loader.gd").new()
		ResourceLoader.add_resource_format_loader(_raw_loader, true)
	var key := path + ".lla_gltf"
	var error := ResourceLoader.load_threaded_request(key, "GLTFState", false, ResourceLoader.CACHE_MODE_IGNORE)
	if error == OK:
		_requests[path] = key
	return error

static func is_prepared(path: String) -> bool:
	return _scenes.has(path) and _scenes[path].modified == FileAccess.get_modified_time(path)

static func prepare(path: String, tree: SceneTree) -> bool:
	if is_prepared(path):
		return true
	if request(path) != OK:
		return false
	var key: String = _requests[path]
	while ResourceLoader.load_threaded_get_status(key) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await tree.process_frame
	if ResourceLoader.load_threaded_get_status(key) != ResourceLoader.THREAD_LOAD_LOADED:
		_requests.erase(path)
		return false
	var state := ResourceLoader.load_threaded_get(key) as GLTFState
	_requests.erase(path)
	if state == null:
		return false
	if LoadTrace.enabled:
		LoadTrace.steps.append({"step": "worker_decode:" + path, "ms": state.get_meta("decode_ms")})
		LoadTrace.steps.append({"step": "worker_mipmaps:" + path, "ms": state.get_meta("mipmaps_ms")})
	# Node creation and packing always stay on the main thread.
	await tree.process_frame
	var document := state.get_meta("raw_document") as GLTFDocument
	var all_anims: Array[GLTFAnimation] = state.get_animations().duplicate()
	var root: Node3D = null
	if all_anims.size() <= ANIM_BATCH_SIZE:
		var stamp := LoadTrace.begin()
		root = document.generate_scene(state) as Node3D
		LoadTrace.end("glb_generate_scene:" + path, stamp)
		if root == null:
			return false
	else:
		var orig_names: PackedStringArray = []
		for n in state.get_nodes():
			orig_names.append(n.original_name)
		var empty_anims: Array[GLTFAnimation] = []
		state.set_animations(empty_anims)
		var stamp := LoadTrace.begin()
		root = document.generate_scene(state) as Node3D
		var max_step_ms := (Time.get_ticks_usec() - stamp) / 1000.0
		if root == null:
			LoadTrace.end("glb_generate_scene:" + path, stamp)
			return false
		var nodes := state.get_nodes()
		for idx in nodes.size():
			nodes[idx].mesh = -1
		var lib := AnimationLibrary.new()
		var offset := 0
		while offset < all_anims.size():
			await tree.process_frame
			var batch_stamp := Time.get_ticks_usec()
			state.set_unique_names([])
			state.set_unique_animation_names([])
			for sk in state.get_skeletons():
				sk.unique_names = []
			for idx in nodes.size():
				nodes[idx].set_name(orig_names[idx])
			var slice: Array[GLTFAnimation] = all_anims.slice(offset, mini(offset + ANIM_BATCH_SIZE, all_anims.size()))
			state.set_animations(slice)
			var temp_root := document.generate_scene(state) as Node3D
			if temp_root != null:
				var temp_ap := temp_root.find_children("*", "AnimationPlayer", true, false)
				if not temp_ap.is_empty():
					var temp_lib := (temp_ap[0] as AnimationPlayer).get_animation_library("")
					for anim_name in temp_lib.get_animation_list():
						lib.add_animation(anim_name, temp_lib.get_animation(anim_name))
				temp_root.free()
			max_step_ms = maxf(max_step_ms, (Time.get_ticks_usec() - batch_stamp) / 1000.0)
			offset += ANIM_BATCH_SIZE
		var ap := AnimationPlayer.new()
		ap.name = "AnimationPlayer"
		root.add_child(ap)
		ap.owner = root
		ap.add_animation_library("", lib)
		if LoadTrace.enabled:
			LoadTrace.steps.append({"step": "glb_generate_scene:" + path, "ms": max_step_ms})
	await tree.process_frame
	var stamp := LoadTrace.begin()
	var scene := PackedScene.new()
	var error := scene.pack(root)
	LoadTrace.end("glb_pack:" + path, stamp)
	await tree.process_frame
	root.free()
	if error != OK:
		return false
	_remember(path, scene)
	await tree.process_frame
	return true

static func _remember(path: String, scene: PackedScene) -> void:
	_scenes[path] = {"modified": FileAccess.get_modified_time(path), "scene": scene}
	_recent.erase(path)
	_recent.append(path)
	while _recent.size() > CACHE_LIMIT:
		var victim := ""
		for candidate in _recent:
			if candidate not in pinned:
				victim = candidate
				break
		if victim.is_empty():
			victim = _recent[0]
		_recent.erase(victim)
		_scenes.erase(victim)

static func load_glb(path: String) -> Node3D:
	if not FileAccess.file_exists(path):
		push_error("Missing GLB: " + path)
		return null
	var modified := FileAccess.get_modified_time(path)
	if _scenes.has(path) and _scenes[path].modified == modified:
		_recent.erase(path)
		_recent.append(path)
		return (_scenes[path].scene as PackedScene).instantiate() as Node3D
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	state.handle_binary_image = GLTFState.HANDLE_BINARY_EMBED_AS_UNCOMPRESSED
	var stamp := LoadTrace.begin()
	var error := document.append_from_file(path, state)
	LoadTrace.end("glb_decode:" + path, stamp)
	if error != OK:
		push_error("GLB import failed (%s): %s" % [error, path])
		return null
	stamp = LoadTrace.begin()
	var root := document.generate_scene(state) as Node3D
	LoadTrace.end("glb_generate_scene:" + path, stamp)
	if root == null:
		return null
	stamp = LoadTrace.begin()
	var scene := PackedScene.new()
	if scene.pack(root) == OK:
		_remember(path, scene)
	LoadTrace.end("glb_pack:" + path, stamp)
	return root

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
