extends Node3D

## Read-only consumer of Sadman's LOLA tiles and Tanvir's rock kit. Configure behind
## the loading card, then call move_focus with the walker/rover's local position.
## Collision follows the full-resolution field independently of visual LOD.
## Room staging must explicitly adopt this provider; it never replaces authored rooms.
const Heightfield = preload("res://assets/environment/terrain/lola/terrain_heightfield.gd")
const Region = preload("res://assets/environment/terrain/lola/lola_region.gd")
const Scatter = preload("res://assets/environment/terrain/lunar_scatter.gd")
const Loads = preload("res://scripts/terrain/terrain_load_queue.gd")
const PROFILE := "res://resources/campaign/profiles/terrain_stream.json"

var field: TerrainHeightfield
var config: Dictionary = {}
var tiles: Dictionary = {}
var collisions: Dictionary = {}
var rocks: Dictionary = {}
var pending: Dictionary = {}
var failures: Array[String] = []
var unavailable: Dictionary = {}
var focus := Vector3.ZERO
var exclusions: Array = []
var _material: Material
var _loads: Node
var _collision_cell := Vector2i(2147483647, 2147483647)
var _rock_cell := Vector2i(2147483647, 2147483647)

## Returns false without modifying an existing world for invalid region ids.
func configure(region_id: String, start: Vector3 = Vector3.ZERO, clear_areas: Array = []) -> bool:
	var info := Region.tiles_info(region_id)
	if info.is_empty() or not start.is_finite() or field != null or not is_inside_tree():
		return false
	var candidate := Heightfield.load_region(region_id, true)
	if candidate == null:
		return false
	var ext := candidate.extent()
	if start.x < ext.x_min or start.x > ext.x_max or start.z < ext.z_min or start.z > ext.z_max:
		return false
	field = candidate
	_loads = Loads.new()
	get_tree().root.add_child(_loads)
	config = JSON.parse_string(FileAccess.get_file_as_string(PROFILE))
	exclusions = clear_areas.duplicate(true)
	_material = Region.make_material(region_id, {"detail": false})
	_material.set_shader_parameter("use_detail", true)
	# The shared kit's imports may predate mipmaps. Build local texture copies
	# once at preparation time; never rewrite the asset owner's import settings.
	for parameter in ["detail_albedo", "detail_normal"]:
		var texture := load(String(config[parameter])) as Texture2D
		if texture != null:
			_material.set_shader_parameter(parameter, texture)
			var pixels := texture.get_image()
			if pixels.is_compressed():
				pixels.decompress()
			if not pixels.has_mipmaps() and pixels.generate_mipmaps(parameter == "detail_normal") == OK:
				_material.set_shader_parameter(parameter, ImageTexture.create_from_image(pixels))
	var entries: Array = info.get("tiles", []).duplicate(true)
	if info.get("vista") is Dictionary:
		var vista: Dictionary = info.vista.duplicate(true)
		vista["id"] = "Vista"
		entries.append(vista)
	for entry in entries:
		var id := String(entry.id)
		var lods: Array = entry.lods
		if lods.is_empty():
			continue
		var lod: Dictionary = lods[-1]
		var node := _instantiate(lod, entry)
		if node == null:
			failures.append("Missing terrain tile: " + id)
			continue
		add_child(node)
		tiles[id] = {"entry": entry, "node": node, "lod": int(lod.lod)}
	var vista_id := String(config.vista_regions.get(region_id, ""))
	if not vista_id.is_empty():
		var backdrop := Region.build(vista_id, {"lod": int(config.vista_lod)})
		if backdrop != null:
			add_child(backdrop)
	move_focus(start, true)
	return failures.is_empty()

func _instantiate(lod: Dictionary, entry: Dictionary, resource: Resource = null) -> Node3D:
	var scene: Resource = resource if resource != null else load(String(lod.path))
	if not scene is PackedScene:
		return null
	var node := (scene as PackedScene).instantiate() as Node3D
	node.name = "%s_LOD%d" % [String(entry.id), int(lod.lod)]
	node.position = Vector3(float(entry.center_x_m), 0, float(entry.center_z_m))
	for mesh in node.find_children("*", "MeshInstance3D", true, false):
		mesh.material_override = _material
		mesh.visibility_range_begin = 0.0
		mesh.visibility_range_end = 0.0
	return node

func contains(point: Vector3) -> bool:
	if field == null or not point.is_finite():
		return false
	var ext := field.extent()
	return point.x >= ext.x_min and point.x <= ext.x_max and point.z >= ext.z_min and point.z <= ext.z_max

## Refuses outside-grid positions instead of extending clamped terrain indefinitely.
func move_focus(point: Vector3, force: bool = false) -> bool:
	if not contains(point):
		return false
	focus = point
	var ext := field.extent()
	var size := float(config.collision_cells) * field.metres_per_pixel
	var cell := Vector2i(floori((point.x - ext.x_min) / size), floori((point.z - ext.z_min) / size))
	if force or cell != _collision_cell:
		_collision_cell = cell
		_sync_collision(cell)
	var rock_cell := Vector2i(floori(point.x / float(config.rock_chunk_m)), floori(point.z / float(config.rock_chunk_m)))
	if force or rock_cell != _rock_cell:
		_rock_cell = rock_cell
		_sync_rocks(rock_cell)
	for id in tiles:
		_request_tile(String(id))
	return true

func _request_tile(id: String) -> void:
	if pending.has(id):
		return
	var tile: Dictionary = tiles[id]
	var distance := Vector2(focus.x - float(tile.entry.center_x_m), focus.z - float(tile.entry.center_z_m)).length()
	var lods: Array = tile.entry.lods
	var chosen: Dictionary = lods[-1]
	for lod in lods:
		if distance < float(lod.visible_to_m):
			chosen = lod
			break
	if int(chosen.lod) == int(tile.lod):
		return
	# Avoid repeatedly swapping at a range boundary. Coarsen only past the margin.
	if int(chosen.lod) > int(tile.lod):
		for lod in lods:
			if int(lod.lod) == int(tile.lod) and distance < float(lod.visible_to_m) + float(config.lod_hysteresis_m):
				return
	var path := String(chosen.path)
	if unavailable.has(path):
		return
	if _loads.request(path):
		pending[id] = {"lod": chosen, "path": path, "started": Time.get_ticks_msec()}
	else:
		unavailable[path] = true
		failures.append("Could not request terrain LOD: " + path)

func _process(_delta: float) -> void:
	# Publish at most one completed replacement per frame. The old tile remains
	# visible if decoding fails or stalls; never block the main thread on a job.
	for id in pending.keys():
		var job: Dictionary = pending[id]
		if _loads.has_result(String(job.path)):
			var tile: Dictionary = tiles[id]
			var resource: Resource = _loads.take(String(job.path))
			var replacement := _instantiate(job.lod, tile.entry, resource) if resource != null else null
			if replacement != null:
				add_child(replacement)
				(tile.node as Node3D).hide()
				(tile.node as Node3D).queue_free()
				tile.node = replacement
				tile.lod = int(job.lod.lod)
			else:
				unavailable[String(job.path)] = true
				failures.append("Terrain LOD failed; retaining previous tile: " + String(job.path))
			pending.erase(id)
			_request_tile(String(id))  # focus may have moved while this LOD loaded
			break
		if Time.get_ticks_msec() - int(job.started) > int(config.resource_timeout_ms):
			_loads.discard(String(job.path))
			unavailable[String(job.path)] = true
			failures.append("Terrain LOD unavailable; retaining previous tile: " + String(job.path))
			pending.erase(id)

func _exit_tree() -> void:
	if is_instance_valid(_loads):
		_loads.release_owner()

func _sync_collision(center: Vector2i) -> void:
	var keep := {}
	var ring := int(config.collision_ring)
	for z in range(center.y - ring, center.y + ring + 1):
		for x in range(center.x - ring, center.x + ring + 1):
			var cell := Vector2i(x, z)
			keep[cell] = true
			if not collisions.has(cell):
				var body := _collision_chunk(cell)
				if body != null:
					add_child(body)
					collisions[cell] = body
	for key in collisions.keys():
		if not keep.has(key):
			(collisions[key] as StaticBody3D).queue_free()
			collisions.erase(key)

func _collision_chunk(cell: Vector2i) -> StaticBody3D:
	var count := int(config.collision_cells)
	var col := cell.x * count
	var row := cell.y * count
	if col < 0 or row < 0 or col >= field.columns - 1 or row >= field.rows - 1:
		return null
	var width := mini(count + 1, field.columns - col)
	var depth := mini(count + 1, field.rows - row)
	var ext := field.extent()
	var step := field.metres_per_pixel
	var start := Vector2(ext.x_min + col * step, ext.z_min + row * step)
	var heights := PackedFloat32Array()
	heights.resize(width * depth)
	for z in depth:
		for x in width:
			heights[z * width + x] = field.height_at(start.x + x * step, start.y + z * step)
	var map := HeightMapShape3D.new()
	map.map_width = width
	map.map_depth = depth
	map.map_data = heights
	var shape := CollisionShape3D.new()
	shape.shape = map
	shape.transform = Transform3D(Basis.from_scale(Vector3(step, 1, step)), Vector3(start.x + (width - 1) * step / 2, 0, start.y + (depth - 1) * step / 2))
	var body := StaticBody3D.new()
	body.name = "Ground_%d_%d" % [cell.x, cell.y]
	body.collision_layer = 1
	body.collision_mask = 0
	body.add_child(shape)
	return body

func rock_records(cell: Vector2i) -> Array[Dictionary]:
	var size := float(config.rock_chunk_m)
	var spacing := float(config.rock_sample_m)
	var samples: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = int(config.rock_seed) + cell.x * 73856093 + cell.y * 19349663
	for z in int(size / spacing):
		for x in int(size / spacing):
			var point := Vector3(cell.x * size + (x + rng.randf()) * spacing, 0, cell.y * size + (z + rng.randf()) * spacing)
			if not contains(point):
				continue
			point.y = field.height_at(point.x, point.z)
			var step := field.metres_per_pixel
			var normal := Vector3(field.height_at(point.x - step, point.z) - field.height_at(point.x + step, point.z), 2 * step, field.height_at(point.x, point.z - step) - field.height_at(point.x, point.z + step)).normalized()
			samples.append({"position": point, "normal": normal, "area_m2": spacing * spacing})
	var placed := Scatter.placements(samples, rng.seed, exclusions)
	var result: Array[Dictionary] = []
	for record in placed:
		# A rock's exclusion circle stays wholly inside its cell. This makes
		# adjacent chunks non-overlapping regardless of load order or reloads.
		var local: Vector3 = record.position - Vector3(cell.x * size, 0, cell.y * size)
		var edge := minf(minf(local.x, size - local.x), minf(local.z, size - local.z))
		if edge >= float(record.radius_m):
			result.append(record)
	return result

func _sync_rocks(center: Vector2i) -> void:
	var keep := {}
	var ring := int(config.rock_ring)
	for z in range(center.y - ring, center.y + ring + 1):
		for x in range(center.x - ring, center.x + ring + 1):
			var cell := Vector2i(x, z)
			keep[cell] = true
			if not rocks.has(cell):
				var group := Scatter.build_group(rock_records(cell))
				add_child(group)
				rocks[cell] = group
	for key in rocks.keys():
		if not keep.has(key):
			(rocks[key] as Node3D).queue_free()
			rocks.erase(key)

## Apply a bundled, dated Horizons row only. No guessed/clamped Sun or Earth.
func lighting(scene_id: String) -> Node3D:
	var row := Heightfield.scene_lighting(scene_id)
	if field == null or row.is_empty() or row.site != field.site.id:
		return null
	var rig := Node3D.new()
	rig.name = "DatedLunarLighting"
	rig.set_meta("ephemeris", row.duplicate(true))
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color.BLACK
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
	world.environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	world.environment.fog_enabled = false
	world.environment.volumetric_fog_enabled = false
	world.environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	rig.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_energy = float(config.sun_energy)
	sun.light_angular_distance = 0.0
	sun.light_size = 0.0
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = float(config.shadow_distance_m)
	sun.directional_shadow_split_1 = float(config.shadow_splits[0])
	sun.directional_shadow_split_2 = float(config.shadow_splits[1])
	sun.directional_shadow_split_3 = float(config.shadow_splits[2])
	sun.directional_shadow_blend_splits = true
	sun.shadow_normal_bias = 1.5
	sun.shadow_bias = 0.03
	sun.basis = field.sun_light_basis(float(row.sun_az_deg), float(row.sun_el_deg))
	rig.add_child(sun)
	return rig
