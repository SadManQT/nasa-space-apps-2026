## Windowed probe for the Earth screen (M1-07). Needs a window (not --headless).
##   --shots      saves production/qa/evidence/M1-07_earth_desk_{rao,ferreira,recording,wide}.png
##                from LOC-01 with the crew placed for EX-CH01-S01
##   Godot --path game --script res://tools/probe_earth_screen.gd -- --shots
## (Its --portrait mode, which re-rendered Ferreira's cut-out portrait, is gone: since M3-5A her screen
## portrait is the approved duty-layer take A, CH_Ferreira_Duty, and must not be overwritten.)
extends SceneTree

const Crew = preload("res://scripts/world/campaign_crew.gd")
const Room = preload("res://scripts/world/campaign_room.gd")
const SHOT_SIZE := Vector2i(1280, 720)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	if args.has("--shots"):
		await _shots()
	print("EARTH SCREEN PROBE RESULT: PASS")
	quit(0)

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
