## M3-104: the EN_Airlock_GlovePort pressure window as the player meets it in LOC-05 (EX-CH02-S04) and both faces of
## the module, so the asset's open back can be compared before and after the source fix. Views:
##   S04_alo_glove_ports  the M3-2R review view (ch02_glove_ports), close over the ports and up through the window
##   station_eye          a 1.6 m eye at the glove-port station (the sightline test_chapter2_rooms.gd checks)
##   chamber_side         inside Alo's sealed chamber, looking back at the module's far face (evidence only)
##   far_face             the module as built in the M3-2A studio vestibule, from behind the garden wall (no chamber)
##   Godot --path game --resolution 1600x900 --script res://tools/capture_m3_104.gd -- --label after
## Writes production/qa/evidence/M3-104_<label>_<view>.png. Needs a window (not headless).
extends SceneTree

const Contract = preload("res://scripts/world/room_contract.gd")
const Presentation = preload("res://scripts/world/room_presentation.gd")
const Airlock = preload("res://assets/environment/EN_Airlock/en_airlock.gd")
const EVIDENCE_DIR := "res://../production/qa/evidence/"
const SCENE_ID := "EX-CH02-S04"
## LOC-05 room-space views (the module stands at (2, 0, -2) turned half a revolution, so its far face is at z -2.15 and
## Alo's chamber runs to z -2.78); an empty spec takes the room data's own review view of that name.
const ROOM_VIEWS := [
	["S04_alo_glove_ports", "ch02_glove_ports", {}],
	["station_eye", "", {"from": [2.0, 1.6, -1.15], "to": [2.0, 1.56, -2.55], "fov": 50.0}],
	["chamber_side", "", {"from": [2.0, 1.72, -2.745], "to": [2.0, 1.48, -2.12], "fov": 84.0}],
]
var checks := 0
var failures := 0
var label := "after"
var _drawn_frames := 0

func _init() -> void:
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL ", message)

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.has("--label") and args.find("--label") + 1 < args.size():
		label = args[args.find("--label") + 1]
	root.size = Vector2i(1600, 900)
	root.always_on_top = true
	root.grab_focus()
	RenderingServer.frame_post_draw.connect(_count_draw)
	await _room_views()
	await _far_face()
	print("M3-104 CAPTURE RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

## The real LOC-05 room scene staged for S04, built the way the campaign's loading card does (test_chapter2_rooms.gd).
func _room_views() -> void:
	var room := (load("res://scenes/campaign/rooms/airlock.tscn") as PackedScene).instantiate() as CampaignRoom
	room.load_approved_assets = false
	root.add_child(room)
	room.load_approved_assets = true
	await room.load_assets_incremental()
	room.set_scene_context(SCENE_ID)
	var camera := Camera3D.new()
	room.add_child(camera)
	camera.current = true
	for frame in 30:
		await process_frame
	for view in ROOM_VIEWS:
		var spec: Dictionary = view[2]
		if String(view[1]) != "":
			spec = Contract.staged_layout(room.room_id, SCENE_ID).review_views.get(String(view[1]), {})
		_check(spec.has("from") and spec.has("to"), "view " + String(view[0]) + " has a camera")
		camera.fov = float(spec.get("fov", 70.0))
		camera.position = Presentation.vector(spec.from)
		camera.look_at(Presentation.vector(spec.to))
		for frame in 20:
			await process_frame
		await _save(String(view[0]))
	room.free()
	await process_frame

## The module alone in the M3-2A studio vestibule (test_en_airlock.gd's evidence environment): its far face from
## behind the garden wall, with one soft fill from the camera side, since nothing is built behind that wall.
func _far_face() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#030406")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.86, 0.88, 0.92)
	env.ambient_light_energy = 0.06
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.ssao_enabled = true
	env.glow_enabled = true
	env.glow_intensity = 0.45
	env.glow_hdr_threshold = 1.2
	var world := WorldEnvironment.new()
	world.environment = env
	stage.add_child(world)
	var airlock := Airlock.new()
	airlock.build_on_ready = false
	stage.add_child(airlock)
	airlock.build()
	var fill := OmniLight3D.new()
	fill.position = Vector3(2.3, 2.1, 5.3)
	fill.light_color = Color(1.0, 0.86, 0.72)
	fill.light_energy = 1.2
	fill.omni_range = 4.0
	stage.add_child(fill)
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.current = true
	camera.fov = 58.0
	camera.position = Vector3(2.35, 1.6, 5.75)
	camera.look_at(Vector3(2.0, 1.4, 4.15))
	for frame in 20:
		await process_frame
	await _save("far_face")
	stage.free()
	await process_frame

func _count_draw() -> void:
	_drawn_frames += 1

## Waits for a drawn frame; a covered macOS window never draws, so after half a second the viewport is drawn by hand.
func _draw_frame() -> void:
	var drawn := _drawn_frames
	for frame in 30:
		await process_frame
		if _drawn_frames > drawn:
			return
	RenderingServer.force_draw(false)

## Saves the presented frame, re-reading a blank (shader-compile) frame for up to two seconds.
func _save(view: String) -> void:
	await _draw_frame()
	var image := root.get_texture().get_image()
	for attempt in 120:
		if not _blank(image):
			break
		await _draw_frame()
		image = root.get_texture().get_image()
	_check(not _blank(image), "capture " + view + " shows a rendered frame")
	var path := ProjectSettings.globalize_path(EVIDENCE_DIR + "M3-104_%s_%s.png" % [label, view])
	_check(image.save_png(path) == OK, "saved " + path.get_file())

func _blank(image: Image) -> bool:
	var brightest := 0.0
	for gx in 16:
		for gy in 9:
			var c := image.get_pixel(int((gx + 0.5) * image.get_width() / 16.0), int((gy + 0.5) * image.get_height() / 9.0))
			brightest = maxf(brightest, c.get_luminance())
	return brightest < 0.03
