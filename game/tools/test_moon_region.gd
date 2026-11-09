## M3-60: Verification, 60 fps performance probe, screenshot capture and walk-through video capture for MoonRegion
## (the walkable region around Aurora and the Cold-Trap approach on real M1-36 LOLA terrain).
##   Godot --headless --path game --script res://tools/test_moon_region.gd
##   Godot --path game --resolution 1280x720 --position 40,40 --script res://tools/test_moon_region.gd -- --capture
extends SceneTree

const RegionScene = preload("res://scenes/world/moon_region.tscn")
const RegionScript = preload("res://scripts/world/moon_region.gd")
const Presentation = preload("res://scripts/world/room_presentation.gd")
const Heightfield = preload("res://assets/environment/terrain/lola/terrain_heightfield.gd")
const Player = preload("res://scenes/player/player.tscn")
const EXPECTED_PLACES := [
	"masts_and_solar_arrays",
	"landing_pad",
	"expedition_zero_survey_markers",
	"boulder_field",
	"crater_rim_lookout",
	"cold_trap_edge",
	"relay_sites",
]
const VALID_REASON_KINDS := ["job", "clue", "view", "measurement"]
const BANNED_TEXT := ["M3-60", "M1-36", "M1-82", "LOC-06", "LOC-07", "LOC-08", "LOC-09", "LOC-10", "TODO", "TBD", "FIXME"]

var checks := 0
var failures := 0
var _drawn_frames := 0

func _init() -> void:
	RenderingServer.frame_post_draw.connect(func() -> void: _drawn_frames += 1)
	if OS.get_cmdline_user_args().has("--capture") and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL ", message)

func _run() -> void:
	var capture := OS.get_cmdline_user_args().has("--capture") and DisplayServer.get_name() != "headless"
	root.size = Vector2i(1280, 720)
	_check_catalog()
	await _check_region_sectors_and_walks()
	if capture:
		await _capture_screenshots_and_walkthrough()
	print("MOON REGION %sRESULT: %s (%d checks, %d failures)" % ["CAPTURE " if capture else "", "PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _check_catalog() -> void:
	var cat := RegionScript.catalog()
	_check(not cat.is_empty() and int(cat.get("schema_version", 0)) == 1, "moon_region.json loads with schema_version 1")
	var locations: Dictionary = cat.get("locations", {})
	for loc_key in ["LOC-06", "LOC-07", "LOC-08", "LOC-09_B1", "LOC-09_B2", "LOC-09_B3", "LOC-09", "LOC-10"]:
		_check(locations.has(loc_key), "moon_region.json defines location " + loc_key)
	var places := RegionScript.places_worth_visiting()
	_check(places.size() == EXPECTED_PLACES.size(), "moon_region.json defines all 7 places worth visiting from doc 25 §4.1")
	var seen_ids: Array = []
	var seen_kinds: Dictionary = {}
	for place in places:
		var pid := String(place.get("id", ""))
		var kind := String(place.get("reason_kind", ""))
		var hook := String(place.get("reason_hook", ""))
		seen_ids.append(pid)
		seen_kinds[kind] = true
		_check(EXPECTED_PLACES.has(pid), "place id is canonical: " + pid)
		_check(VALID_REASON_KINDS.has(kind), "%s has valid reason_kind (%s)" % [pid, kind])
		_check(hook.begins_with(kind + ": ") and hook.length() > 16, "%s carries a structured reason hook (%s)" % [pid, hook])
	for kind in VALID_REASON_KINDS:
		_check(seen_kinds.has(kind), "places worth visiting cover reason kind: " + kind)

func _check_region_sectors_and_walks() -> void:
	var region := RegionScene.instantiate() as MoonRegion
	_check(region != null, "moon_region.tscn instantiates as MoonRegion")
	root.add_child(region)
	var player := Player.instantiate() as PlayerController
	player.character_glb = "res://assets/characters/CH_Kai/CH_Kai.glb"
	player.controlled = false
	(player.get_node("FollowCamera") as FollowCamera).capture_mouse = false
	root.add_child(player)

	# 1. Check aurora_ridge locations (LOC-06, LOC-07, LOC-08, LOC-09_B1, LOC-09_B2)
	for pair in [
		["LOC-06", "EX-CH04-S09", true],
		["LOC-07", "EX-CH04-S02", true],
		["LOC-08", "EX-CH05-S01", true],
		["LOC-09_B1", "EX-CH04-S04", true],
		["LOC-09_B2", "EX-CH04-S04", true],
	]:
		var loc_key := String(pair[0])
		var scene_id := String(pair[1])
		var expect_earth := bool(pair[2])
		var res := await region.travel_to_location(loc_key, scene_id)
		_check(bool(res.get("accepted", false)) and String(res.get("sector", "")) == "aurora_ridge", "%s travels on aurora_ridge (%s)" % [loc_key, scene_id])
		_check(bool(res.get("earth_presented", false)) == expect_earth, "%s (%s) earth_presented == %s" % [loc_key, scene_id, str(expect_earth)])
		_check_lighting_rules(region, loc_key + " " + scene_id, false)
		var loc_node := region.location_node(loc_key)
		_check(loc_node != null and loc_node.is_inside_tree(), loc_key + " node is placed in MoonRegion")
		if loc_key == "LOC-07":
			_check(loc_node.has_node("annex_exterior_hatch") and loc_node.has_node("annex_exterior_station") and loc_node.has_node("marker_2034_annex") and loc_node.has_node("PR_AnnexDrum"), "LOC-07 exterior has sealed hatch, utility station, 2034 survey marker and drum")
		elif loc_key == "LOC-08":
			var garage_room := loc_node as CampaignRoom
			_check(garage_room != null and garage_room.visual_root.has_node("berm") and garage_room.visual_root.has_node("rover_door"), "LOC-08 stands on aurora_ridge with its regolith berm and openable rover door")
		await _walk_probe(region, player, res.get("player_spawn_world", Vector3.ZERO), loc_key)

	# 2. Check aurora_ridge §4.1 places worth visiting
	for pid in ["masts_and_solar_arrays", "landing_pad", "expedition_zero_survey_markers", "boulder_field", "crater_rim_lookout", "relay_sites"]:
		var visit := await region.visit_place(pid)
		_check(bool(visit.get("accepted", false)) and region.place_node(pid) != null, "visit_place(%s) succeeds and landmark node exists" % pid)
		await _walk_probe(region, player, visit.get("approach_world", Vector3.ZERO), "place:" + pid)

	_check_no_banned_labels(region, "aurora_ridge")

	# 3. Check cold_trap locations (LOC-09_B3, LOC-09 last bend, LOC-10 vault shelf)
	for pair in [
		["LOC-09_B3", "EX-CH04-S04", true],
		["LOC-09", "EX-CH04-S05", false],
		["LOC-10", "EX-CH04-S06", false],
	]:
		var loc_key := String(pair[0])
		var scene_id := String(pair[1])
		var expect_earth := bool(pair[2])
		var res := await region.travel_to_location(loc_key, scene_id)
		_check(bool(res.get("accepted", false)) and String(res.get("sector", "")) == "cold_trap", "%s travels on cold_trap (%s)" % [loc_key, scene_id])
		_check(bool(res.get("earth_presented", false)) == expect_earth, "%s (%s) earth_presented == %s" % [loc_key, scene_id, str(expect_earth)])
		_check_lighting_rules(region, loc_key + " " + scene_id, true)
		var room := region.location_node(loc_key) as CampaignRoom
		_check(room != null and room.on_terrain(), loc_key + " stands on TerrainStream ground without flat staging floor")
		if room != null:
			var tl := room.terrain_lighting()
			_check(bool(tl.get("ready", false)) and room.work_lights().size() >= 3, "%s work lights are switched on and ready under dark Sun (%d lamps)" % [loc_key, room.work_lights().size()])
		await _walk_probe(region, player, res.get("player_spawn_world", Vector3.ZERO), loc_key)

	# 4. Check cold_trap §4.1 place worth visiting (cold_trap_edge)
	var edge_visit := await region.visit_place("cold_trap_edge")
	_check(bool(edge_visit.get("accepted", false)) and region.place_node("cold_trap_edge") != null, "visit_place(cold_trap_edge) succeeds and landmark node exists")
	await _walk_probe(region, player, edge_visit.get("approach_world", Vector3.ZERO), "place:cold_trap_edge")

	_check_no_banned_labels(region, "cold_trap")

	player.free()
	region.free()
	await process_frame

func _check_lighting_rules(region: MoonRegion, tag: String, dark_row: bool) -> void:
	var rig := region.lighting_rig
	_check(rig != null and rig.has_node("World") and rig.has_node("Sun"), tag + " has DatedLunarLighting with World and Sun")
	if rig == null:
		return
	var env := (rig.get_node("World") as WorldEnvironment).environment
	var sun := rig.get_node("Sun") as DirectionalLight3D
	_check(env.ambient_light_source == Environment.AMBIENT_SOURCE_DISABLED and env.reflected_light_source == Environment.REFLECTION_SOURCE_DISABLED, tag + " disables ambient and reflected sky fill (ART_BIBLE §2)")
	_check(not env.fog_enabled and not env.volumetric_fog_enabled, tag + " has no fog or haze (ART_BIBLE §2)")
	_check(is_zero_approx(sun.light_angular_distance) and is_zero_approx(sun.light_size) and sun.shadow_enabled, tag + " uses one hard low Sun with sharp shadows")
	if dark_row:
		_check(rig.has_node("HorizonOccluder"), tag + " dark cold-trap row places HorizonOccluder so local floor is in shadow")

func _walk_probe(region: MoonRegion, player: PlayerController, start_world: Vector3, label: String) -> void:
	region.move_focus(start_world, true)
	for f in 3:
		await physics_frame
	var query := PhysicsRayQueryParameters3D.create(start_world + Vector3.UP * 8.0, start_world + Vector3.DOWN * 8.0, 1)
	var hit := root.get_world_3d().direct_space_state.intersect_ray(query)
	_check(not hit.is_empty(), label + " has solid terrain/plinth collision under spawn")
	var ground_y := float(hit.position.y) if not hit.is_empty() else start_world.y
	player.set_physics_process(false)
	player.global_position = Vector3(start_world.x, ground_y + 0.08, start_world.z)
	for frame in 10:
		player.velocity = Vector3.DOWN
		player.move_and_slide()
		await physics_frame
	var settled_pos := player.global_position
	for step in 16:
		player.velocity = Vector3(1.8, -1.0, -1.2)
		player.move_and_slide()
		region.move_focus(player.global_position)
		await physics_frame
	var moved_xz := Vector2(player.global_position.x - settled_pos.x, player.global_position.z - settled_pos.z).length()
	_check(player.is_on_floor() and moved_xz > 0.2 and absf(player.global_position.y - ground_y) < 1.8, label + " PlayerController walks across collision without falling through")

func _check_no_banned_labels(region: MoonRegion, sector_tag: String) -> void:
	for label in region.find_children("*", "Label3D", true, false):
		var l := label as Label3D
		if not l.visible:
			continue
		for banned in BANNED_TEXT:
			_check(not l.text.contains(banned), "%s visible Label3D '%s' has no developer code '%s'" % [sector_tag, l.name, banned])

# ------------------------------------------------------------------------------------------------- capture & perf

const CAPTURE_SHOTS := [
	{
		"file": "M3-60_LOC06_mast_courtyard",
		"loc": "LOC-06",
		"scene": "EX-CH04-S09",
		"cam_offset": [-13.5, 2.2, 6.5],
		"look_offset": [-2.0, 1.3, -5.5],
		"fov": 62.0
	},
	{
		"file": "M3-60_LOC07_annex_exterior",
		"loc": "LOC-07",
		"scene": "EX-CH04-S02",
		"cam_offset": [4.2, 2.0, 4.8],
		"look_offset": [-0.3, 0.6, -0.8],
		"fov": 60.0
	},
	{
		"file": "M3-60_LOC08_garage_and_apron",
		"loc": "LOC-08",
		"scene": "EX-CH05-S01",
		"cam_offset": [22.0, 2.4, 8.5],
		"look_offset": [2.0, 0.2, 1.0],
		"fov": 62.0
	},
	{
		"file": "M3-60_LOC09_B1_ridge_approach",
		"loc": "LOC-09_B1",
		"scene": "EX-CH04-S04",
		"cam_offset": [4.6, 2.3, 3.2],
		"look_offset": [-5.0, 1.7, -5.5],
		"fov": 66.0
	},
	{
		"file": "M3-60_LOC09_cold_trap_edge",
		"loc": "LOC-09",
		"scene": "EX-CH04-S05",
		"cam_offset": [1.5, 2.4, 6.0],
		"look_offset": [-2.5, 0.2, -4.0],
		"fov": 66.0
	},
	{
		"file": "M3-60_LOC10_vault_shelf",
		"loc": "LOC-10",
		"scene": "EX-CH04-S06",
		"cam_offset": [4.5, 2.0, 5.5],
		"look_offset": [0.0, 0.2, -0.8],
		"fov": 66.0
	},
	{
		"file": "M3-60_crater_rim_earth_horizon",
		"loc": "LOC-06",
		"scene": "EX-CH04-S09",
		"place": "crater_rim_lookout",
		"look_at_earth": true,
		"fov": 56.0
	},
]

func _capture_screenshots_and_walkthrough() -> void:
	var region := RegionScene.instantiate() as MoonRegion
	root.add_child(region)
	var camera := Camera3D.new()
	camera.far = 70000.0
	root.add_child(camera)
	camera.current = true

	var frame_times_ms: Array[float] = []

	for shot in CAPTURE_SHOTS:
		var loc_key := String(shot.get("loc", "LOC-06"))
		var scene_id := String(shot.get("scene", "EX-CH04-S02"))
		var res := await region.travel_to_location(loc_key, scene_id)
		var base_node := region.location_node(loc_key)
		for f in 180:
			await process_frame
			if region.settled() and f > 45:
				break
		camera.fov = float(shot.get("fov", 62.0))
		if bool(shot.get("look_at_earth", false)):
			var rim_node := region.place_node("crater_rim_lookout")
			var rim_pos := rim_node.global_position if rim_node != null else Vector3(-36.0, region.height_at(-36.0, -32.0), -32.0)
			var earth_dir := Presentation.vector(region.earth_spec.get("direction", [0.76, 0.006, 0.64])).normalized()
			camera.global_position = rim_pos - earth_dir * 4.2 + Vector3(0.0, 1.65, 0.0)
			camera.look_at(camera.global_position + earth_dir * 1000.0, Vector3.UP)
		else:
			var cam_off := Presentation.vector(shot.get("cam_offset", [0.0, 2.0, 6.0]))
			var look_off := Presentation.vector(shot.get("look_offset", [0.0, 1.0, 0.0]))
			camera.global_position = base_node.global_transform * cam_off
			camera.look_at(base_node.global_transform * look_off, Vector3.UP)
		for f in 24:
			var t0 := Time.get_ticks_usec()
			await process_frame
			var dt := float(Time.get_ticks_usec() - t0) / 1000.0
			if f >= 8:
				frame_times_ms.append(dt)
		await _draw_frame()
		await _save_png(String(shot.file))
		print("saved ", shot.file)

	frame_times_ms.sort()
	var median_ms := frame_times_ms[frame_times_ms.size() / 2] if not frame_times_ms.is_empty() else 0.0
	var p95_ms := frame_times_ms[int(frame_times_ms.size() * 0.95)] if not frame_times_ms.is_empty() else 0.0
	print("M3-60 PERF PROBE: median=%.2f ms, p95=%.2f ms (%d frames)" % [median_ms, p95_ms, frame_times_ms.size()])
	_check(median_ms <= 20.0, "MoonRegion median frame time <= 20.0 ms (measured %.2f ms)" % median_ms)

	# Capture walk-through video frames across the ridge (LOC-06 courtyard -> LOC-07 annex exterior -> crater rim lookout -> LOC-08 garage apron)
	await _record_walkthrough_video(region, camera)

	camera.free()
	region.free()
	await process_frame

func _record_walkthrough_video(region: MoonRegion, camera: Camera3D) -> void:
	await region.travel_to_location("LOC-06", "EX-CH05-S01")
	for f in 90:
		await process_frame
		if region.settled() and f > 30:
			break
	var tmp_dir := "/tmp/m3_60_walkthrough_frames"
	DirAccess.make_dir_recursive_absolute(tmp_dir)
	var waypoints := [
		Vector3(0.0, 0.0, 10.0),
		Vector3(-4.0, 0.0, 2.0),
		Vector3(-12.0, 0.0, -8.0),
		Vector3(-22.0, 0.0, -18.0),
		Vector3(-10.0, 0.0, -34.0),
		Vector3(6.0, 0.0, -56.0),
		Vector3(18.0, 0.0, -70.0),
	]
	var total_frames := 72  # 3 seconds at 24 fps
	camera.fov = 64.0
	for idx in total_frames:
		var u := float(idx) / float(total_frames - 1) * float(waypoints.size() - 1)
		var seg := mini(int(floor(u)), waypoints.size() - 2)
		var t := u - float(seg)
		var p0: Vector3 = waypoints[seg]
		var p1: Vector3 = waypoints[seg + 1]
		var pos := p0.lerp(p1, t)
		pos.y = region.height_at(pos.x, pos.z) + 1.7
		var ahead := (p1 - p0).normalized()
		var target := pos + ahead * 12.0
		target.y = region.height_at(target.x, target.z) + 1.4
		region.move_focus(pos)
		camera.global_position = pos
		camera.look_at(target, Vector3.UP)
		await _draw_frame()
		var img := root.get_texture().get_image()
		img.save_jpg("%s/%05d.jpg" % [tmp_dir, idx], 0.92)
	var mp4_path := ProjectSettings.globalize_path("res://../production/qa/evidence/M3-60_walkthrough.mp4")
	var out := []
	var code := OS.execute("ffmpeg", [
		"-y", "-framerate", "24", "-i", tmp_dir + "/%05d.jpg",
		"-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "20", mp4_path
	], out, true)
	_check(code == 0 and FileAccess.file_exists(mp4_path), "encoded walk-through video to production/qa/evidence/M3-60_walkthrough.mp4")
	print("saved M3-60_walkthrough.mp4")

func _draw_frame() -> void:
	var drawn := _drawn_frames
	for frame in 30:
		await process_frame
		if _drawn_frames > drawn:
			return
	RenderingServer.force_draw(false)

func _save_png(id: String) -> void:
	var image := root.get_texture().get_image()
	for attempt in 60:
		if not _blank(image):
			break
		await _draw_frame()
		image = root.get_texture().get_image()
	_check(not _blank(image), "capture " + id + " is non-blank")
	var out_path := ProjectSettings.globalize_path("res://../production/qa/evidence/%s.png" % id)
	_check(image.save_png(out_path) == OK, "saved " + id)

func _blank(image: Image) -> bool:
	var brightest := 0.0
	for gx in 16:
		for gy in 9:
			var c := image.get_pixel(int((gx + 0.5) * image.get_width() / 16.0), int((gy + 0.5) * image.get_height() / 9.0))
			brightest = maxf(brightest, c.get_luminance())
	return brightest < 0.03
