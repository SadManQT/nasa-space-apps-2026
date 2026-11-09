extends SceneTree

const Stream = preload("res://scripts/terrain/terrain_stream.gd")
var checks := 0
var failures := 0

func _init() -> void:
	if "--evidence" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL ", label)

func _run() -> void:
	var terrain := Stream.new()
	root.add_child(terrain)
	check(not terrain.configure("missing"), "unknown region rejected")
	check(not terrain.configure("aurora_ridge", Vector3(100000, 0, 100000)), "outside-grid initial focus rejected")
	check(terrain.field == null and terrain.get_child_count() == 0, "invalid start leaves provider retryable and empty")
	check(terrain.configure("aurora_ridge", Vector3.ZERO, [{"position": Vector3.ZERO, "radius_m": 8.0}]), "real terrain configures")
	check(not terrain.configure("cold_trap"), "configure cannot overwrite live world")
	check(terrain.tiles.size() == 16, "all sixteen coarse tiles retained")
	check(terrain.collisions.size() <= 9 and terrain.rocks.size() <= 9, "bounded near collision and scatter rings")
	var original := terrain.focus
	check(not terrain.move_focus(Vector3(100000, 0, 100000)) and terrain.focus == original, "outside-grid focus refused without mutation")
	var rig := terrain.lighting("EX-CH01-S07")
	check(rig != null, "dated Sun rig")
	terrain.add_child(rig)
	var row: Dictionary = rig.get_meta("ephemeris")
	check(float(row.sun_el_deg) < 0, "below-horizontal measured Sun stays below horizontal")
	var sun := rig.get_node("Sun") as DirectionalLight3D
	check(sun.light_size == 0 and sun.light_angular_distance == 0, "hard Sun")
	check(terrain.lighting("EX-CH08-S08") == null, "wrong-site ephemeris refused")
	var a := terrain.rock_records(Vector2i.ZERO)
	var b := terrain.rock_records(Vector2i.ZERO)
	check(a == b, "scatter reproduces exactly")
	var neighbour := terrain.rock_records(Vector2i.RIGHT)
	var overlap := false
	for first in a:
		check(first.position.distance_to(Vector3.ZERO) >= float(first.radius_m) + 8.0, "site exclusion stays clear")
		for second in neighbour:
			if first.position.distance_to(second.position) < float(first.radius_m) + float(second.radius_m):
				overlap = true
	check(not overlap, "neighbouring chunks have no overlapping exclusion circles")
	# Traverse a heightfield chunk seam in both directions, then return.
	for x in [0.0, 79.9, 80.0, 80.1, 161.0, -81.0, 0.0]:
		check(terrain.move_focus(Vector3(x, 0, 0)), "move within terrain")
		await physics_frame
		await physics_frame
		var query := PhysicsRayQueryParameters3D.create(Vector3(x, 500, 0), Vector3(x, -500, 0), 1)
		var hit := terrain.get_world_3d().direct_space_state.intersect_ray(query)
		check(not hit.is_empty(), "ground collider at seam " + str(x))
		if not hit.is_empty():
			check(absf(hit.position.y - terrain.field.height_at(x, 0)) < 0.1, "physical height agrees with field")
		check(terrain.collisions.size() <= 9 and terrain.rocks.size() <= 9, "streamed node counts bounded")
	# Collision supports a walker capsule and a rover-sized box under motion.
	for shape in [CapsuleShape3D.new(), BoxShape3D.new()]:
		var body := CharacterBody3D.new()
		var collision := CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
		root.add_child(body)
		body.position = Vector3(0, terrain.field.height_at(0, 0) + 3, 0)
		for frame in 90:
			await physics_frame
			body.velocity = Vector3(0, -3, 0)
			body.move_and_slide()
		check(body.is_on_floor(), "walker/rover body settles on the shared terrain collision")
		body.free()
	var deadline := Time.get_ticks_msec() + 15000
	while not terrain.pending.is_empty() and Time.get_ticks_msec() < deadline:
		await process_frame
	check(terrain.pending.is_empty() and terrain.failures.is_empty(), "asynchronous LOD work finishes")
	check(terrain.settled() and terrain.rocks.size() == 9, "queued rock chunks build one per frame and settle")
	await _check_dark_row()
	check(terrain.tiles.T11.lod == 0, "near central tile reaches authored finest LOD")
	# Simulate closing the owning terrain immediately after a real request.
	var drain := Stream.Loads.new()
	root.add_child(drain)
	var path := String(terrain.tiles.T11.entry.lods[-1].path)
	check(drain.request(path), "drain starts a real resource request")
	drain.release_owner()
	for frame in 30:
		if not is_instance_valid(drain):
			break
		await process_frame
	check(not is_instance_valid(drain), "abandoned request is consumed and drain frees itself")
	var terrain_drain: Node = terrain._loads
	if "--evidence" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		await _capture(terrain, row)
	terrain.queue_free()
	await process_frame
	await physics_frame
	check(not is_instance_valid(terrain_drain), "terrain exit releases its loader")
	print("TERRAIN STREAM RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

## M1-36: a pre-loaded heightfield is adopted, and a dark row (the Sun below the terrain horizon) turns the Sun off:
## the vault shelf under EX-CH04-S06 is never sunlit.
func _check_dark_row() -> void:
	var cold := Stream.new()
	root.add_child(cold)
	var field := Stream.Heightfield.load_region("cold_trap", true)
	check(cold.configure("cold_trap", Vector3.ZERO, [], field) and cold.field == field, "configure adopts a prepared heightfield")
	var rig := cold.lighting("EX-CH04-S06")
	var row: Dictionary = rig.get_meta("ephemeris") if rig != null else {}
	var sun := rig.get_node_or_null("Sun") as DirectionalLight3D if rig != null else null
	check(String(row.get("sun_state", "")) == "dark" and float(row.sun_el_deg) < float(row.terrain_horizon_deg) and sun != null and not sun.visible, "a dark row's Sun stays below the terrain horizon: no sunlight on the shelf")
	if rig != null:
		rig.free()
	cold.queue_free()
	await process_frame

func _capture(terrain: Node3D, row: Dictionary) -> void:
	print("TERRAIN CAPTURE: rendering ground and vista")
	var camera := Camera3D.new()
	terrain.add_child(camera)
	camera.current = true
	camera.fov = 60
	camera.near = 0.1
	camera.far = 80000
	var direction: Vector3 = terrain.field.sun_direction(float(row.sun_az_deg), float(row.sun_el_deg))
	var across := Vector3(-direction.z, 0, direction.x).normalized()
	var eye := Vector3(0, terrain.field.height_at(0, 0) + 1.7, 0)
	var times: Array[float] = []
	for view in ["ground", "vista"]:
		camera.position = eye + Vector3(0, 250 if view == "vista" else 0, 0)
		camera.look_at(camera.position + across * 1000 + Vector3(0, -140 if view == "vista" else -12, 0))
		for frame in 90:
			var started := Time.get_ticks_usec()
			await process_frame
			if frame > 30:
				times.append((Time.get_ticks_usec() - started) / 1000.0)
		RenderingServer.force_draw()
		var renderer := RenderingServer.get_current_rendering_method()
		var path := "res://../production/qa/evidence/M1-36_%s_%s.png" % [renderer, view]
		check(root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path)) == OK, "save " + path)
	times.sort()
	print("TERRAIN FRAME MS median=%.2f p95=%.2f renderer=%s" % [times[times.size() / 2], times[int(times.size() * 0.95)], RenderingServer.get_current_rendering_method()])
