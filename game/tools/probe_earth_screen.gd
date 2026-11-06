## Windowed probes for the Earth screen (M1-07). Needs a window (not --headless).
##   --portrait   re-renders Ferreira's Earth-screen portrait at 1376x768 with a transparent
##                background (res://assets/ui/portraits/CH_Ferreira_screen.png), the same
##                toon runtime and framing family as the installed Rao portrait, lit like EN_EarthDesk.
##                Run it in its own process: a session that rewrites the PNG keeps the old import.
##   --shots      saves production/qa/evidence/M1-07_earth_desk_{rao,ferreira,recording,wide}.png
##                from LOC-01 with the crew placed for EX-CH01-S01
##   Godot --path game --script res://tools/probe_earth_screen.gd -- --portrait --shots
extends SceneTree

const Crew = preload("res://scripts/world/campaign_crew.gd")
const Room = preload("res://scripts/world/campaign_room.gd")
const PORTRAIT_SIZE := Vector2i(1376, 768)
const SHOT_SIZE := Vector2i(1280, 720)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	if args.has("--portrait"):
		await _portrait()
	if args.has("--shots"):
		await _shots()
	print("EARTH SCREEN PROBE RESULT: PASS")
	quit(0)

func _portrait() -> void:
	root.size = PORTRAIT_SIZE
	DisplayServer.window_set_size(PORTRAIT_SIZE)
	var view := SubViewport.new()
	view.size = PORTRAIT_SIZE
	view.transparent_bg = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var scene := Node3D.new()
	view.add_child(scene)
	var body := preload("res://scenes/player/player.tscn").instantiate() as PlayerController
	body.character_glb = "res://assets/characters/CH_Ferreira/CH_Ferreira.glb"
	body.controlled = false
	body.get_node("FollowCamera").active = false
	body.get_node("FollowCamera").capture_mouse = false
	scene.add_child(body)
	body.set_controlled(false)
	body.face_towards(Vector3(0, 0, 2))
	# Lit like the room behind her (EN_EarthDesk): a warm key from the desk lamp at her right
	# (screen left), a cool fill, and a teal rim from the display wall behind.
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-25, -35, 0)
	light.light_energy = 1.25
	light.light_color = Color(1.0, 0.9, 0.8)
	scene.add_child(light)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-15, 160, 0)
	rim.light_energy = 0.6
	rim.light_color = Color(0.6, 0.85, 0.9)
	scene.add_child(rim)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0, 0, 0, 0)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.82, 0.88, 0.95)
	env.environment.ambient_light_energy = 0.4
	scene.add_child(env)
	var camera := Camera3D.new()
	scene.add_child(camera)
	# Rao's installed portrait: head in the upper middle, shoulders and chest to the bottom edge.
	camera.position = Vector3(0, 1.42, 1.25)
	camera.look_at(Vector3(0, 1.36, 0))
	camera.fov = 36
	camera.current = true
	for i in 30:
		await physics_frame
	await RenderingServer.frame_post_draw
	var image := view.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path("res://assets/ui/portraits/CH_Ferreira_screen.png"))
	print("EARTH SCREEN PROBE: Ferreira portrait %dx%d with alpha" % [image.get_width(), image.get_height()])
	view.free()
	await process_frame

func _shots() -> void:
	root.size = SHOT_SIZE
	DisplayServer.window_set_size(SHOT_SIZE)
	var crew := Crew.new()
	root.add_child(crew)
	var room := Room.new()
	room.room_id = "LOC-01"
	root.add_child(room)
	crew.place("EX-CH01-S01", room, Vector3(0, 0, 3.7))  # the commons_player anchor, behind the wide camera
	for i in 5:
		await physics_frame
	var camera := Camera3D.new()
	room.add_child(camera)
	camera.current = true
	var out := ProjectSettings.globalize_path("res://../production/qa/evidence/")
	var screen := (room.get_node("EarthPortrait") as Node3D).position  # the commons' earth_screen fixture
	for shot in [["rao", "rao", "EARTH LINK", Vector3(0, 2.0, -1.2), 52.0], ["ferreira", "ferreira", "EARTH LINK", Vector3(0, 2.0, -1.2), 52.0],
			["recording", "ferreira", "STORED RECORDING", Vector3(0, 2.0, -1.2), 52.0], ["wide", "rao", "EARTH LINK", Vector3(0, 1.7, 3.0), 70.0]]:
		camera.position = shot[3]
		camera.look_at(screen)
		camera.fov = shot[4]
		crew.present_line({"speaker_id": shot[1], "origin_label": shot[2]}, false)
		for i in 10:
			await physics_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out + "M1-07_earth_desk_%s.png" % shot[0])
		print("EARTH SCREEN PROBE: wrote M1-07_earth_desk_%s.png" % shot[0])
	room.free()
	crew.free()
	await process_frame
