extends SceneTree

## Windowed capture for board M1-34: renders the LOLA terrain in Godot 4.7 Forward+ with the game's
## region builder (lola_region.gd: GLB LODs, terrain_lola.gdshader) under the Sun of a dated story
## scene from sun_positions.json (JPL Horizons azimuth and elevation, never clamped), one hard
## DirectionalLight3D, black sky, no ambient light, and saves production/qa/evidence/
##   M1-34_<region>_topdown.png  every region alone, orthographic, north (away from the pole) up
##   M1-34_<hero>_ground.png     hero + its vista from 1.7 m above the site, across the Sun
##   M1-34_<hero>_vista.png      the same from 250 m above the site, down-Sun along the shadows
## Each frame carries a caption with the scene, UTC, Sun angles and data source. Run through
## production/tools/heavy.py (production/qa/evidence/M1-34_capture.sh wraps it).
##   godot --path game --windowed --resolution 1600x900 --script res://tools/capture_terrain_m134.gd [-- --region=aurora_ridge]

const Heightfield = preload("res://assets/environment/terrain/lola/terrain_heightfield.gd")
const LolaRegion = preload("res://assets/environment/terrain/lola/lola_region.gd")
const LOLA := "res://assets/environment/terrain/lola"
const OUT := "res://../production/qa/evidence/"
## The vista region that surrounds each hero region (same site, same frame).
const VISTAS := {"aurora_ridge": "aurora_vista", "malapert_summit": "malapert_vista"}
const SUN_ENERGY := 6.0
var failures := 0
var captured: Array[String] = []
var caption: Label

func _init() -> void:
	call_deferred("_run")

func _json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

var scenes: Dictionary = {}

func _run() -> void:
	var manifest := _json(LOLA + "/lola_terrain.json")
	scenes = manifest.get("preview_scenes", {})
	var only := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--region="):
			only = arg.trim_prefix("--region=")
	var layer := CanvasLayer.new()
	root.add_child(layer)
	caption = Label.new()
	caption.position = Vector2(16, 12)
	caption.add_theme_font_size_override("font_size", 18)
	caption.add_theme_color_override("font_color", Color(0.92, 0.92, 0.9))
	caption.add_theme_color_override("font_outline_color", Color.BLACK)
	caption.add_theme_constant_override("outline_size", 6)
	layer.add_child(caption)
	var ids: Array = []
	for id in manifest.get("regions", {}):
		if only.is_empty() or String(id) == only:
			ids.append(String(id))
	ids.sort()
	for id in ids:
		await _capture_region(id, manifest.regions[id])
	print("TERRAIN CAPTURE RESULT: %s (%d files, %d failures)" % ["PASS" if failures == 0 else "FAIL", captured.size(), failures])
	for f in captured:
		print("  ", f)
	quit(0 if failures == 0 else 1)

## The scene_lighting row used for a site (manifest preview_scenes, the same row as the Python
## previews and review sheets), or the first row for that site.
func _scene_sun(site_id: String) -> Dictionary:
	var row := Heightfield.scene_lighting(String(scenes.get(site_id, "")))
	if not row.is_empty():
		return row
	for r in Heightfield.sun_table().get("scene_lighting", []):
		if String(r.get("site", "")) == site_id:
			return r
	return {}

func _world(hf: TerrainHeightfield, az: float, el: float, shadow_m: float) -> Node3D:
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.02, 0.023, 0.04)  # space black (#05060A)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
	e.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	e.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.environment = e
	world.add_child(env)
	var light := DirectionalLight3D.new()
	light.light_energy = SUN_ENERGY
	light.light_color = Color(1.0, 0.99, 0.97)
	light.light_angular_distance = 0.53  # the Sun's disc seen from the Moon
	light.shadow_enabled = true
	light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	light.directional_shadow_max_distance = shadow_m
	light.directional_shadow_split_1 = 0.03
	light.directional_shadow_split_2 = 0.12
	light.directional_shadow_split_3 = 0.4
	light.directional_shadow_blend_splits = true
	light.shadow_normal_bias = 1.5
	light.shadow_bias = 0.03
	light.transform.basis = hf.sun_light_basis(az, el)
	world.add_child(light)
	return world

func _capture_region(id: String, entry: Dictionary) -> void:
	var info := LolaRegion.tiles_info(id)
	if info.is_empty():
		print("FAIL ", id, ": no tiles.json")
		failures += 1
		return
	var hf: TerrainHeightfield = Heightfield.load_region(id, true)
	if hf == null:
		failures += 1
		return
	var kind := String(entry.get("kind", ""))
	var site_id := String(entry.get("site", ""))
	var sun := _scene_sun(site_id)
	if sun.is_empty():
		print("FAIL ", id, ": no dated Sun for ", site_id)
		failures += 1
		return
	var az := float(sun.sun_az_deg)
	var el := float(sun.sun_el_deg)
	var meta: Dictionary = hf.meta
	var source := "LOLA %d m/px, %s" % [int(hf.metres_per_pixel), String(meta.get("source_product", ""))]
	var when := "%s  %s UTC  Sun az %.1f deg, el %+.2f deg (JPL Horizons; %s at the site)" % [String(sun.scene), String(sun.utc), az, el, String(sun.sun_state)]
	var ext: Dictionary = hf.extent()
	var size_x: float = ext.x_max - ext.x_min
	var size_z: float = ext.z_max - ext.z_min
	var center := Vector3((ext.x_min + ext.x_max) / 2.0, 0.0, (ext.z_min + ext.z_max) / 2.0)
	# 1. top-down orthographic view of the region alone, north at the top
	var world := _world(hf, az, el, maxf(size_x, size_z) * 1.2)
	var terrain := LolaRegion.build(id, {"lod": 1 if kind == "hero" else 0})
	if terrain == null:
		failures += 1
		world.queue_free()
		return
	world.add_child(terrain)
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.current = true
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = maxf(size_z, size_x * 900.0 / 1600.0)
	cam.near = 10.0
	cam.far = 60000.0
	cam.position = center + Vector3(0.0, 20000.0, 0.0)
	cam.look_at(center, Vector3(0.0, 0.0, -1.0))
	caption.text = "%s (%s), top-down, north up, %.1f x %.1f km\n%s\n%s" % [id, kind, size_x / 1000.0, size_z / 1000.0, when, source]
	await _snap("M1-34_%s_topdown.png" % id)
	world.queue_free()
	await process_frame
	if kind != "hero":
		return
	# 2. ground and 3. elevated views: the hero region with every LOD and its surrounding vista
	world = _world(hf, az, el, 20000.0)
	world.add_child(LolaRegion.build(id))
	if VISTAS.has(id):
		var vista := LolaRegion.build(String(VISTAS[id]))
		if vista != null:
			world.add_child(vista)
	cam = Camera3D.new()
	world.add_child(cam)
	cam.current = true
	cam.fov = 60.0
	cam.near = 0.5
	cam.far = 80000.0
	var sun_dir: Vector3 = hf.sun_direction(az, el)
	var flat_sun := Vector3(sun_dir.x, 0.0, sun_dir.z).normalized()
	var eye := Vector3(0.0, hf.height_at(0.0, 0.0) + 1.7, 0.0)
	var across := Vector3(-flat_sun.z, 0.0, flat_sun.x)
	cam.position = eye
	cam.look_at(eye + across * 1000.0 + Vector3(0.0, -12.0, 0.0), Vector3.UP)
	caption.text = "%s: eye 1.7 m above the site, looking across the Sun (with %s)\n%s\n%s" % [id, String(VISTAS.get(id, "no vista")), when, source]
	await _snap("M1-34_%s_ground.png" % id)
	cam.position = eye + Vector3(0.0, 250.0, 0.0)
	cam.look_at(cam.position - flat_sun * 1000.0 + Vector3(0.0, -140.0, 0.0), Vector3.UP)
	caption.text = "%s: 250 m above the site, looking down-Sun along the shadows\n%s\n%s" % [id, when, source]
	await _snap("M1-34_%s_vista.png" % id)
	world.queue_free()
	await process_frame

func _snap(name: String) -> void:
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path(OUT + name)
	var err := img.save_png(path)
	if err != OK:
		print("FAIL save ", path, " ", err)
		failures += 1
	else:
		captured.append(path)
		print("captured ", name)
