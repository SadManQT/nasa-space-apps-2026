extends RefCounted
class_name AssetGeometry

# Raw glTF preserves the approved runtime look (including face layers). Reuse
# its parsed resources instead of decoding images/meshes on every room cut.
# Bound retained scenes; live instances keep their own resources alive on eviction.
const CACHE_LIMIT := 16
static var _scenes: Dictionary = {}
static var _recent: Array[String] = []
static var pinned: Array[String] = []

static var _image_extension: GLTFDocumentExtension
static var _raw_loader: ResourceFormatLoader
static var _requests: Dictionary = {}
static var _preparing: Dictionary = {}

## Schedules one raw decode per path; recovered sessions use the original decoder.
static func request(path: String) -> Error:
	if is_prepared(path) or _requests.has(path):
		return OK
	if PreparationWatchdog.synchronous:
		return ERR_UNAVAILABLE
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

## Coalesces callers through scene publication, with an independent raw fallback.
static func prepare(path: String, tree: SceneTree) -> bool:
	if is_prepared(path):
		return true
	if _preparing.has(path):
		var pending: Dictionary = _preparing[path]
		if not await PreparationWatchdog.wait_until(tree, "geometry_queue:" + path, func(): return pending.done):
			return await _recover_geometry(path, tree, pending)
		return pending.success
	var pending := {"done": false, "success": false, "recovering": false}
	_preparing[path] = pending
	if PreparationWatchdog.synchronous:
		return await _recover_geometry(path, tree, pending)
	var prepared := await _prepare_threaded(path, tree, pending)
	if not pending.done:
		_finish_geometry(path, pending, prepared)
	return pending.success

static func _prepare_threaded(path: String, tree: SceneTree, pending: Dictionary) -> bool:
	if request(path) != OK:
		return await _recover_geometry(path, tree, pending)
	var key: String = _requests[path]
	var completed := await PreparationWatchdog.wait_until(tree, "raw_decode:" + path, func():
		return pending.recovering or ResourceLoader.load_threaded_get_status(key) != ResourceLoader.THREAD_LOAD_IN_PROGRESS)
	if pending.recovering:
		return await _recover_geometry(path, tree, pending)
	if not completed:
		return await _recover_geometry(path, tree, pending)
	var status := ResourceLoader.load_threaded_get_status(key)
	var state: GLTFState
	if status == ResourceLoader.THREAD_LOAD_LOADED or status == ResourceLoader.THREAD_LOAD_FAILED:
		state = ResourceLoader.load_threaded_get(key) as GLTFState
	_requests.erase(path)
	if state == null:
		return await _recover_geometry(path, tree, pending)
	if LoadTrace.enabled:
		LoadTrace.steps.append({"step": "worker_decode:" + path, "ms": state.get_meta("decode_ms")})
		LoadTrace.steps.append({"step": "worker_mipmaps:" + path, "ms": state.get_meta("mipmaps_ms")})
	# Node creation and packing always stay on the main thread. A timed-out
	# follower can take over recovery while this owner yields.
	await tree.process_frame
	if pending.recovering:
		return await _recover_geometry(path, tree, pending)
	var stamp := LoadTrace.begin()
	var document := state.get_meta("raw_document") as GLTFDocument
	var root := document.generate_scene(state) as Node3D
	LoadTrace.end("glb_generate_scene:" + path, stamp)
	if root == null:
		return false
	stamp = LoadTrace.begin()
	var scene := PackedScene.new()
	var error := scene.pack(root)
	LoadTrace.end("glb_pack:" + path, stamp)
	root.free()
	if error != OK:
		return false
	_remember(path, scene)
	await tree.process_frame
	return true

static func _recover_geometry(path: String, tree: SceneTree, pending: Dictionary) -> bool:
	if pending.recovering:
		# The owner yields only to draw the recovery card, then does bounded
		# synchronous work. All followers share its published outcome.
		await PreparationWatchdog.wait_until(tree, "raw_recovery:" + path, func(): return pending.done)
		return pending.success
	pending.recovering = true
	if _requests.has(path):
		PreparationWatchdog.retire_resource(tree, _requests[path])
		_requests.erase(path)
	var prepared: bool = await PreparationWatchdog.fallback(tree, _prepare_sync.bind(path))
	_finish_geometry(path, pending, prepared)
	return prepared

static func _finish_geometry(path: String, pending: Dictionary, success: bool) -> void:
	pending.success = success
	pending.done = true
	_preparing.erase(path)

static func _prepare_sync(path: String) -> bool:
	# Direct GLTFDocument decoding never joins the virtual .lla_gltf request.
	var instance := load_glb(path)
	if instance == null:
		return false
	instance.free()
	return is_prepared(path)

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
