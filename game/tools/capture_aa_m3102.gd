## M3-102: compares the project's 3D anti-aliasing options on the fine repeating detail that shimmers (the
## EN_ZeroAnnex grating deck by headlamp, and the habitat-kit floor tiles and rails of the service rooms).
## For every mode it saves a still, the frame time with vsync off (Godot's GPU timer reads 0 on Metal), and a shimmer score: the mean per-pixel change when the camera
## moves about half a pixel, which is what reads as crawling in motion (lower is steadier).
##   Godot --path game --resolution 1600x900 --script res://tools/capture_aa_m3102.gd
## Writes production/qa/evidence/M3-102_<view>_<mode>.png and M3-102_aa_compare.txt. Needs a window (not headless).
extends "res://tools/test_ch03_assets.gd"

const MODES := [
	["off", Viewport.MSAA_DISABLED, Viewport.SCREEN_SPACE_AA_DISABLED, false],
	["msaa2", Viewport.MSAA_2X, Viewport.SCREEN_SPACE_AA_DISABLED, false],
	["msaa4", Viewport.MSAA_4X, Viewport.SCREEN_SPACE_AA_DISABLED, false],
	["fxaa", Viewport.MSAA_DISABLED, Viewport.SCREEN_SPACE_AA_FXAA, false],
	["smaa", Viewport.MSAA_DISABLED, Viewport.SCREEN_SPACE_AA_SMAA, false],
	["taa", Viewport.MSAA_DISABLED, Viewport.SCREEN_SPACE_AA_DISABLED, true],
	["msaa2_smaa", Viewport.MSAA_2X, Viewport.SCREEN_SPACE_AA_SMAA, false],
	["msaa2_taa", Viewport.MSAA_2X, Viewport.SCREEN_SPACE_AA_DISABLED, true],  # the project default chosen in M3-102
]
var report: PackedStringArray = []

func _run() -> void:
	root.size = Vector2i(1600, 900)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)  # uncapped, so the frame time shows the AA cost
	Engine.max_fps = 0
	report.append("M3-102 anti-aliasing comparison, %s, %s, window %s" % [Time.get_datetime_string_from_system(), RenderingServer.get_current_rendering_method(), root.size])
	report.append("view            mode       frame_ms  shimmer")
	# 1: the cold annex grating by headlamp, low and grazing (as in M3-3A_annex_cold)
	var scene := _annex_sample()
	root.add_child(scene)
	var camera := Camera3D.new()
	camera.fov = 70
	scene.add_child(camera)
	camera.current = true
	var lamp := SpotLight3D.new()
	lamp.light_color = Color(1.0, 0.95, 0.88)
	lamp.light_energy = 6.0
	lamp.spot_range = 12.0
	lamp.spot_angle = 38.0
	lamp.shadow_enabled = true
	camera.add_child(lamp)
	camera.position = Vector3(1.2, -ANNEX_DROP + 1.55, 1.6)
	camera.look_at(Vector3(5.5, -ANNEX_DROP + 0.4, -2.2))
	await _compare("annex_grating", camera)
	scene.free()
	# 2: a kit room: the service rooms' anti-slip floor tiles, rails and quilted panels at a walking eye height
	var room := (load("res://scenes/campaign/rooms/service_rooms.tscn") as PackedScene).instantiate() as CampaignRoom
	root.add_child(room)
	await room.load_assets_incremental()
	var eye := Camera3D.new()
	eye.fov = 70
	room.add_child(eye)
	eye.current = true
	eye.position = Vector3(-4.6, 1.6, 2.6)
	eye.look_at(Vector3(4.0, 0.9, -2.5))
	await _compare("kit_room", eye)
	room.free()
	var path := ProjectSettings.globalize_path(EVIDENCE_DIR + "M3-102_aa_compare.txt")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("\n".join(report) + "\n")
	file.close()
	print("\n".join(report))
	print("M3-102 AA COMPARE RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

## Every mode on one view: a still, the median frame time over 120 uncapped frames, and the half-pixel shimmer score.
func _compare(view: String, camera: Camera3D) -> void:
	var start := camera.transform
	# a camera step that moves the image about half a pixel at the view's centre distance
	var step := 0.5 * 2.0 * tan(deg_to_rad(camera.fov * 0.5)) * 6.0 / float(root.size.y)
	for mode in MODES:
		root.msaa_3d = mode[1]
		root.screen_space_aa = mode[2]
		root.use_taa = mode[3]
		camera.transform = start
		for _i in range(30):  # let TAA converge and the GPU timer settle
			await process_frame
		var times: Array[float] = []
		var last := Time.get_ticks_usec()
		for _i in range(120):
			await process_frame
			var now := Time.get_ticks_usec()
			times.append((now - last) / 1000.0)
			last = now
		times.sort()
		var still := await _grab()
		still.save_png(ProjectSettings.globalize_path(EVIDENCE_DIR + "M3-102_%s_%s.png" % [view, mode[0]]))
		camera.transform = start.translated_local(Vector3(step, 0, 0))
		for _i in range(30 if mode[3] else 4):
			await process_frame
		var moved := await _grab()
		var shimmer := _mean_change(still, moved)
		_check(times[60] > 0.0, "%s %s: frame time measured" % [view, mode[0]])
		report.append("%-15s %-12s %6.2f  %7.3f" % [view, mode[0], times[60], shimmer])
	camera.transform = start

func _grab() -> Image:
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

## Mean absolute luminance change (0-255) over the frame's centre 60 %, on every 2nd pixel.
func _mean_change(a: Image, b: Image) -> float:
	var total := 0.0
	var count := 0
	var w := a.get_width()
	var h := a.get_height()
	for y in range(int(h * 0.2), int(h * 0.8), 2):
		for x in range(int(w * 0.2), int(w * 0.8), 2):
			total += absf(a.get_pixel(x, y).get_luminance() - b.get_pixel(x, y).get_luminance())
			count += 1
	return 255.0 * total / maxf(count, 1)
