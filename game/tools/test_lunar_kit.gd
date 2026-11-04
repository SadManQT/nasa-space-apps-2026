extends SceneTree

const Scatter = preload("res://assets/environment/terrain/lunar_scatter.gd")
var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		print("FAIL ", message)

func _run() -> void:
	var catalog := Scatter.catalog()
	_check(catalog.rocks.size() == 16, "sixteen distinct rock variants")
	_check(catalog.materials.size() == 3, "three regolith surfaces")
	for rock in catalog.rocks:
		_check(rock.triangles[0] > rock.triangles[1] and rock.triangles[1] > rock.triangles[2], rock.id + " has decreasing LOD complexity")
		for path in rock.lods:
			_check(load(path) is PackedScene, "load " + path)
	for material in catalog.materials:
		var mat := load(material.path) as StandardMaterial3D
		_check(mat != null and mat.albedo_texture != null and mat.normal_texture != null, material.id + " loads both textures")
	_check(is_equal_approx(Scatter.slope_density(Vector3.UP), 1.0), "level ground full density")
	_check(Scatter.slope_density(Vector3.UP.rotated(Vector3.RIGHT, deg_to_rad(30))) < .5, "slope reduces density")
	for normal in [Vector3.DOWN, Vector3.RIGHT, Vector3.ZERO, Vector3(NAN, 0, 0)]:
		_check(Scatter.slope_density(normal) == 0, "walls/undersides/invalid normals rejected")
	var samples: Array = []
	for x in 20:
		for z in 20:
			samples.append({"position": Vector3(x * 2, 0, z * 2), "normal": Vector3.UP, "area_m2": 4.0})
	var records := Scatter.placements(samples, 351104)
	_check(records.size() > 30, "non-empty useful scatter")
	_check(records == Scatter.placements(samples, 351104), "same seed reproduces positions/variants/rotations")
	_check(records != Scatter.placements(samples, 351105), "different seed changes scatter")
	var excluded := Scatter.placements(samples, 351104, [{"position": Vector3(20, 0, 20), "radius_m": 5.0}])
	var clearance := true
	var separated := true
	var aligned := true
	for item in excluded:
		clearance = clearance and item.position.distance_to(Vector3(20, 0, 20)) >= 5.0 + item.radius_m
	for i in records.size():
		aligned = aligned and records[i].transform.basis.y.is_equal_approx(Vector3.UP)
		for j in range(i):
			separated = separated and records[i].position.distance_to(records[j].position) >= records[i].radius_m + records[j].radius_m
	_check(clearance, "landing zones/paths can exclude rocks")
	_check(separated, "size-aware spacing prevents intersecting boulders")
	_check(aligned, "rock bases align to surface normals")
	var tilted_normal := Vector3.UP.rotated(Vector3.RIGHT, deg_to_rad(25))
	var tilted := Scatter.placements([{"position": Vector3(4, 3, 2), "normal": tilted_normal, "area_m2": 1000.0}], 31)
	_check(tilted.size() == 1 and tilted[0].transform.basis.y.is_equal_approx(tilted_normal), "inclined terrain aligns the local up axis")
	_check(tilted.size() == 1 and tilted[0].transform.origin == Vector3(4, 3, 2), "sample altitude retained")
	_check(Scatter.placements([{}, {"position": Vector3.ZERO, "normal": Vector3.UP, "area_m2": -1}], 1).is_empty(), "bad samples skipped")
	var all: Array[Dictionary] = []
	for i in 16:
		all.append({"variant": i, "transform": Transform3D.IDENTITY})
	var group := Scatter.build_group(all)
	root.add_child(group)
	_check(group.get_child_count() == 16, "every variant builds")
	_check(group.find_children("*", "MeshInstance3D", true, false).size() == 48, "all three LOD meshes present")
	_check(group.find_children("*", "CollisionShape3D", true, false).size() == 12, "simplified collision only on rocks at least 35 cm")
	var ranges := true
	for item in group.get_children():
		var meshes := item.find_children("*", "MeshInstance3D", true, false)
		ranges = ranges and meshes[0].visibility_range_end == meshes[1].visibility_range_begin
		ranges = ranges and meshes[1].visibility_range_end == meshes[2].visibility_range_begin
		ranges = ranges and meshes[2].visibility_range_end == 0
	_check(ranges, "LOD ranges meet with no gap and distant LOD stays visible")
	group.free()
	var visual_only := Scatter.build_group(all, false)
	_check(visual_only.find_children("*", "CollisionShape3D", true, false).is_empty(), "collision opt-out for distant chunks")
	visual_only.free()
	if OS.get_cmdline_user_args().has("--evidence"):
		await _evidence(catalog)
	print("LUNAR KIT RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _evidence(catalog: Dictionary) -> void:
	root.size = Vector2i(1280, 900)
	var scene := Node3D.new()
	root.add_child(scene)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.02, 0.025, 0.035)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = .18
	scene.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -30, 0)
	light.light_energy = 1.8
	scene.add_child(light)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 19
	camera.position = Vector3(0, 17, 14)
	scene.add_child(camera)
	camera.look_at(Vector3.ZERO)
	for i in 16:
		var rock: Dictionary = catalog.rocks[i]
		var obj := (load(rock.lods[0]) as PackedScene).instantiate() as Node3D
		obj.scale = Vector3.ONE * 2.0 / float(rock.size_m)
		obj.position = Vector3((i % 4 - 1.5) * 3.8, 0, (i / 4 - 1.5) * 3.8)
		scene.add_child(obj)
	var title := Label.new()
	title.text = "M1-35 | 16 fracture forms | normalized display sizes | provisional surfaces"
	title.position = Vector2(24, 20)
	title.add_theme_font_size_override("font_size", 22)
	root.add_child(title)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png("res://../production/qa/evidence/M1-35_godot_rocks.png")
	_check(error == OK, "Godot contact evidence written")
	# Ground-patch preview under lunar lighting: black sky, 5-degree hard Sun,
	# no ambient/fog. Each patch is 4 m square and retains its authored UVs.
	for child in scene.get_children():
		if child != camera and child != light and child != env:
			child.queue_free()
	env.environment.background_color = Color.BLACK
	env.environment.ambient_light_energy = 0
	light.rotation_degrees = Vector3(-5, -35, 0)
	light.shadow_enabled = true
	light.light_energy = 4
	camera.position = Vector3(0, 10, 7)
	camera.size = 14
	camera.look_at(Vector3.ZERO)
	title.text = "M1-35 | Fresh / rover-compacted / boot-disturbed | provisional | hard Sun at 5 degrees"
	for i in 3:
		var path := "res://assets/environment/terrain/rocks/" + String(catalog.materials[i].id) + ".glb"
		var patch := (load(path) as PackedScene).instantiate() as Node3D
		patch.position.x = (i - 1) * 4.2
		scene.add_child(patch)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	error = root.get_texture().get_image().save_png("res://../production/qa/evidence/M1-35_godot_regolith.png")
	_check(error == OK, "Godot lunar material evidence written")
	scene.free()
	title.free()
