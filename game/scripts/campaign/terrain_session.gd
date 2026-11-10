extends Node3D

## Campaign-owned adoption of Sadman's surveyed room contract. The room keeps
## all target/door/pressure IDs; only an explicitly ready placement gets ground.
const Contract = preload("res://scripts/world/room_contract.gd")
const Stream = preload("res://scripts/terrain/terrain_stream.gd")
const EarthSky = preload("res://assets/environment/terrain/earth_sky.gd")
const Heightfield = preload("res://assets/environment/terrain/lola/terrain_heightfield.gd")
const Region = preload("res://assets/environment/terrain/lola/lola_region.gd")
var stream: Node3D
var origin := Vector3.ZERO
var turn := Basis.IDENTITY
var placement: Dictionary = {}
var earth_presented := false
var configured := false

## prepare() behind a loading card without stalling it: the detail heightfield (40-165 ms) loads on a worker thread
## and the coarse tile GLBs through threaded requests; then configure (about 25 ms) runs on one frame and the rock
## chunks build one per frame until the stream is settled.
func prepare_incremental(room_id: String, scene_id: String, segment: String = "") -> Dictionary:
	var place := Contract.terrain(room_id, segment)
	if configured or not is_inside_tree() or not place.get("omit_staging_floor", false):
		return prepare(room_id, scene_id, null, segment)
	var region := String(place.region_id)
	var job := {}
	var task := WorkerThreadPool.add_task(func() -> void: job.field = Heightfield.load_region(region, true))
	var held: Array = []
	var paths: Array = []
	for entry in Region.tiles_info(region).get("tiles", []):
		if not entry.lods.is_empty() and ResourceLoader.load_threaded_request(String(entry.lods[-1].path)) == OK:
			paths.append(String(entry.lods[-1].path))
	var info := Region.tiles_info(region)
	if info.get("vista") is Dictionary:
		var vista_lods: Array = info.vista.get("lods", [])
		if not vista_lods.is_empty() and ResourceLoader.load_threaded_request(String(vista_lods[-1].path)) == OK:
			paths.append(String(vista_lods[-1].path))
	for map_key in ["normal_map", "ao_map"]:
		if info.has(map_key):
			var map_path := "%s/%s/%s" % [Region.LOLA, region, String(info[map_key])]
			if ResourceLoader.exists(map_path) and ResourceLoader.load_threaded_request(map_path) == OK:
				paths.append(map_path)
	var stream_profile: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Stream.PROFILE)) if FileAccess.file_exists(Stream.PROFILE) else {}
	for detail_path in [Region.DETAIL_ALBEDO, Region.DETAIL_NORMAL, String(stream_profile.get("detail_albedo", "")), String(stream_profile.get("detail_normal", ""))]:
		if not detail_path.is_empty() and ResourceLoader.exists(detail_path) and not paths.has(detail_path) and ResourceLoader.load_threaded_request(detail_path) == OK:
			paths.append(detail_path)
	var vista_id := String(stream_profile.get("vista_regions", {}).get(region, ""))
	if not vista_id.is_empty():
		var vista_info := Region.tiles_info(vista_id)
		var want_vista_lod := int(stream_profile.get("vista_lod", 1))
		for v_tile in vista_info.get("tiles", []):
			var v_lods: Array = v_tile.get("lods", [])
			if not v_lods.is_empty():
				var picked: Dictionary = Region._pick_lod(v_lods, want_vista_lod)
				var v_path := String(picked.get("path", ""))
				if not v_path.is_empty() and ResourceLoader.load_threaded_request(v_path) == OK:
					paths.append(v_path)
		if vista_info.get("vista") is Dictionary:
			var vv_lods: Array = vista_info.vista.get("lods", [])
			if not vv_lods.is_empty():
				var picked_vv: Dictionary = Region._pick_lod(vv_lods, want_vista_lod)
				var vv_path := String(picked_vv.get("path", ""))
				if not vv_path.is_empty() and ResourceLoader.load_threaded_request(vv_path) == OK:
					paths.append(vv_path)
		for map_key in ["normal_map", "ao_map"]:
			if vista_info.has(map_key):
				var v_map_path := "%s/%s/%s" % [Region.LOLA, vista_id, String(vista_info[map_key])]
				if ResourceLoader.exists(v_map_path) and ResourceLoader.load_threaded_request(v_map_path) == OK:
					paths.append(v_map_path)
	for rock in Stream.Scatter.catalog().get("rocks", []):
		for lod_path in rock.get("lods", []):
			if ResourceLoader.exists(String(lod_path)) and ResourceLoader.load_threaded_request(String(lod_path)) == OK:
				paths.append(String(lod_path))
	while not WorkerThreadPool.is_task_completed(task):
		await get_tree().process_frame
	WorkerThreadPool.wait_for_task_completion(task)
	for path in paths:
		while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().process_frame
		held.append(ResourceLoader.load_threaded_get(path))  # held so configure's load() hits the cache
		await get_tree().process_frame
	if not is_inside_tree():
		return {"accepted": false, "reason": "The terrain session left the tree while it was loading."}
	await get_tree().process_frame
	var result := await prepare_staged(room_id, scene_id, job.get("field"), segment)
	while result.get("enabled", false) and is_instance_valid(stream) and not stream.settled():
		await get_tree().process_frame
	held.clear()
	await get_tree().process_frame
	return result

func prepare_staged(room_id: String, scene_id: String, field: TerrainHeightfield = null, segment: String = "") -> Dictionary:
	if configured or not is_inside_tree():
		return {"accepted": false, "reason": "Terrain preparation needs a fresh campaign terrain session in the scene tree."}
	placement = Contract.terrain(room_id, segment)
	if not placement.get("omit_staging_floor", false):
		return {"accepted": true, "enabled": false, "reason": placement.get("pending", "This room uses its existing floor.")}
	origin = _vector(placement.origin_m)
	turn = Basis(Vector3.UP, deg_to_rad(float(placement.get("yaw_deg", 0.0))))
	var start := player_anchor(placement.anchors)
	var clear_areas: Array = placement.exclusions.map(func(area): return {"position": _vector(area.position), "radius_m": float(area.radius_m)})
	stream = Stream.new()
	stream.name = "SurveyedTerrain"
	stream.transform = Transform3D(turn, origin).affine_inverse()
	add_child(stream)
	if not await stream.configure_incremental(String(placement.region_id), origin + turn * start, clear_areas, field):
		return _abort("The surveyed terrain could not be prepared.")
	await get_tree().process_frame
	var sky_scene := String(placement.get("sky_rows", {}).get(scene_id, scene_id))
	var rig: Node3D = stream.lighting(sky_scene, segment)
	if rig == null:
		return _abort("The exterior has no dated lighting for this site and scene.")
	rig.basis = turn.inverse()
	add_child(rig)
	var environments := rig.find_children("*", "WorldEnvironment", false, false)
	if not environments.is_empty():
		earth_presented = EarthSky.apply(environments[0].environment, Contract.earth(room_id, scene_id, segment), float(stream.config.sun_energy))
	configured = true
	return {"accepted": true, "enabled": true, "player_anchor": start, "earth_presented": earth_presented}

func prepare(room_id: String, scene_id: String, field: TerrainHeightfield = null, segment: String = "") -> Dictionary:
	if configured or not is_inside_tree():
		return {"accepted": false, "reason": "Terrain preparation needs a fresh campaign terrain session in the scene tree."}
	placement = Contract.terrain(room_id, segment)
	if not placement.get("omit_staging_floor", false):
		return {"accepted": true, "enabled": false, "reason": placement.get("pending", "This room uses its existing floor.")}
	origin = _vector(placement.origin_m)
	turn = Basis(Vector3.UP, deg_to_rad(float(placement.get("yaw_deg", 0.0))))
	var start := player_anchor(placement.anchors)
	var clear_areas: Array = placement.exclusions.map(func(area): return {"position": _vector(area.position), "radius_m": float(area.radius_m)})
	stream = Stream.new()
	stream.name = "SurveyedTerrain"
	stream.transform = Transform3D(turn, origin).affine_inverse()
	add_child(stream)
	if not stream.configure(String(placement.region_id), origin + turn * start, clear_areas, field):
		return _abort("The surveyed terrain could not be prepared.")
	var sky_scene := String(placement.get("sky_rows", {}).get(scene_id, scene_id))
	var rig: Node3D = stream.lighting(sky_scene, segment)
	if rig == null:
		return _abort("The exterior has no dated lighting for this site and scene.")
	rig.basis = turn.inverse()
	add_child(rig)
	var environments := rig.find_children("*", "WorldEnvironment", false, false)
	if not environments.is_empty():
		earth_presented = EarthSky.apply(environments[0].environment, Contract.earth(room_id, scene_id, segment), float(stream.config.sun_energy))
	configured = true
	return {"accepted": true, "enabled": true, "player_anchor": start, "earth_presented": earth_presented}

func _abort(reason: String) -> Dictionary:
	if stream != null:
		remove_child(stream)
		stream.queue_free()
		stream = null
	placement = {}
	origin = Vector3.ZERO
	turn = Basis.IDENTITY
	return {"accepted": false, "reason": reason}

func move_focus(room_local: Vector3) -> bool:
	return configured and stream.move_focus(origin + turn * room_local)

static func player_anchor(anchors: Dictionary) -> Vector3:
	for key in anchors:
		if String(key).ends_with("_player"):
			return _vector(anchors[key])
	return Vector3.ZERO

static func _vector(value: Array) -> Vector3:
	return Vector3(float(value[0]), float(value[1]), float(value[2]))
