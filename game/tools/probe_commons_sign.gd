## M1-79 windowed evidence: the commons name plate beside the Earth screen, read from the commons_player anchor.
## Needs a window (not --headless). Saves production/qa/evidence/M1-79_*.png and prints SIGN PROBE lines with the
## sign's measured size in each frame and how much of its text box actually rendered as sign-yellow letters (a
## sign hidden behind a fixture renders none).
##   Godot --path game --resolution 1600x900 --script res://tools/probe_commons_sign.gd
extends SceneTree

const Crew = preload("res://scripts/world/campaign_crew.gd")
const Room = preload("res://scripts/world/campaign_room.gd")
const Contract = preload("res://scripts/world/room_contract.gd")
const Presentation = preload("res://scripts/world/room_presentation.gd")
const SHOT_SIZE := Vector2i(1600, 900)
const SIGN_TEXT := "AURORA / COMMONS"
const OUT := "res://../production/qa/evidence/"
# Rendered letters must cover at least this share of the sign's projected text box (the 16 capitals fill about a
# quarter of it; the old sign behind the Earth screen rendered none).
const MIN_LETTER_COVER := 0.08
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	root.size = SHOT_SIZE
	DisplayServer.window_set_size(SHOT_SIZE)
	var layout := Contract.layout("LOC-01")
	var anchor := Presentation.vector(layout.anchors.commons_player)
	var crew := Crew.new()
	root.add_child(crew)
	var room := Room.new()
	room.room_id = "LOC-01"
	root.add_child(room)
	var sign := _sign(room)
	_expect(sign != null, "the commons name sign is built")
	if sign == null:
		_finish()
		return
	var camera := Camera3D.new()
	room.add_child(camera)
	# Chapter 1 opening (EX-CH01-S01): Rao on the Earth screen, the player at the commons_player anchor.
	var player := crew.place("EX-CH01-S01", room, anchor)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	crew.present_line({"speaker_id": "rao", "origin_label": "EARTH LINK"}, false)
	var image := await _gameplay_view(player, sign, "player")
	_crop(image, Rect2i(600, 270, 520, 180), "player_sign_x2")
	player.hide()  # the eye shot stands where the player's body is
	await _still(camera, anchor + Vector3.UP * 1.6, Vector3(1.4, 1.9, -6.0), 65.0, sign, "anchor_eye")
	await _still(camera, Vector3(0.9, 1.7, -2.3), Vector3(1.75, 2.05, -6.0), 60.0, sign, "display_wall")
	# Chapter 6 (EX-CH06-S09): the eclipse desk, monitor, message log and pin board below the sign, practicals at 35 %.
	player = crew.place("EX-CH06-S09", room, anchor)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await _gameplay_view(player, sign, "ch06_player")
	# Chapter 7 (EX-CH07-S01): the kept ring frame and Noor's note on the pin board, under the plate.
	crew.place("EX-CH07-S01", room, anchor)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await _still(camera, Vector3(2.5, 1.7, -3.3), Vector3(2.65, 1.95, -6.0), 55.0, sign, "ch07_pin_board")
	room.free()
	crew.free()
	await process_frame
	_finish()

func _finish() -> void:
	print("SIGN PROBE RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)

func _expect(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL ", message)

func _sign(room: Node3D) -> Label3D:
	for node in room.find_children("*", "Label3D", true, false):
		if (node as Label3D).text == SIGN_TEXT:
			return node as Label3D
	return null

## The gameplay view: the controlled body's FollowCamera at its default framing (yaw 0 faces the Earth screen
## wall, pitch -0.12), settled as the game settles it.
func _gameplay_view(player: PlayerController, sign: Label3D, shot: String) -> Image:
	player.set_physics_process(false)
	var follow := player.follow_camera
	follow.yaw = 0.0
	follow.pitch = -0.12
	follow.reset_placement()
	follow.camera.current = true
	for frame in 30:
		follow.update_camera(1.0 / 60.0, PI, 0.0)
		await process_frame
	return await _shoot(follow.camera, sign, shot)

func _still(camera: Camera3D, from: Vector3, to: Vector3, fov: float, sign: Label3D, shot: String) -> Image:
	camera.position = from
	camera.look_at(to)
	camera.fov = fov
	camera.current = true
	for frame in 20:
		await process_frame
	return await _shoot(camera, sign, shot)

## Saves the frame and reports the sign's projected text box, its em height (and the same view's em at 1080
## lines) and the share of the box drawn in sign-yellow letters.
func _shoot(camera: Camera3D, sign: Label3D, shot: String) -> Image:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	for attempt in 120:
		if not _blank(image):
			break
		await process_frame
		await RenderingServer.frame_post_draw
		image = root.get_texture().get_image()
	_expect(not _blank(image), shot + " shows a rendered frame")
	_expect(image.save_png(ProjectSettings.globalize_path(OUT + "M1-79_%s.png" % shot)) == OK, "save M1-79_%s.png" % shot)
	var box := sign.get_aabb()
	var xf := sign.global_transform
	# unproject_position answers in the stretched base canvas (1280x720 here), not in the saved frame's pixels.
	var to_frame := Vector2(image.get_size()) / root.get_visible_rect().size
	var rect := Rect2()
	var first := true
	for corner in [box.position, box.position + Vector3(box.size.x, 0, 0), box.position + Vector3(0, box.size.y, 0), box.end]:
		var at: Vector3 = xf * corner
		_expect(not camera.is_position_behind(at), shot + " sign is in front of the camera")
		var pixel := camera.unproject_position(at) * to_frame
		rect = Rect2(pixel, Vector2.ZERO) if first else rect.expand(pixel)
		first = false
	var em := float(sign.font_size) * sign.pixel_size
	var em_px := (camera.unproject_position(xf.origin + xf.basis.y.normalized() * em * 0.5) * to_frame).distance_to(camera.unproject_position(xf.origin - xf.basis.y.normalized() * em * 0.5) * to_frame)
	var inside := Rect2(Vector2.ZERO, Vector2(image.get_size())).encloses(rect)
	var cover := _letter_cover(image, Rect2i(rect)) if inside else 0.0
	print("SIGN PROBE: M1-79_%s.png text box %dx%d px at (%d, %d), em %.1f px (%.1f px at 1080 lines), letters cover %.0f %% of the box" % [shot, rect.size.x, rect.size.y, rect.position.x, rect.position.y, em_px, em_px * 1080.0 / image.get_height(), cover * 100.0])
	_expect(inside, shot + " the whole sign is in frame")
	_expect(cover >= MIN_LETTER_COVER, shot + " the sign's letters render (not hidden behind anything)")
	return image

## Share of pixels in the rect drawn in the sign's yellow (bright, red and green high, blue low; the tray's orange
## latches and the navy plate do not count).
func _letter_cover(image: Image, rect: Rect2i) -> float:
	var area := rect.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	if area.size.x <= 0 or area.size.y <= 0:
		return 0.0
	var hits := 0
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var c := image.get_pixel(x, y)
			if c.r > 0.5 and c.g > 0.6 * c.r and c.b < 0.55 * c.r:
				hits += 1
	return float(hits) / float(area.size.x * area.size.y)

## A 2x nearest-neighbour crop for reviewing the sign at the frame's real pixel size.
func _crop(image: Image, rect: Rect2i, shot: String) -> void:
	var crop := image.get_region(rect)
	crop.resize(rect.size.x * 2, rect.size.y * 2, Image.INTERPOLATE_NEAREST)
	_expect(crop.save_png(ProjectSettings.globalize_path(OUT + "M1-79_%s.png" % shot)) == OK, "save M1-79_%s.png" % shot)

func _blank(image: Image) -> bool:
	var brightest := 0.0
	for gx in 16:
		for gy in 9:
			var c := image.get_pixel(int((gx + 0.5) * image.get_width() / 16.0), int((gy + 0.5) * image.get_height() / 9.0))
			brightest = maxf(brightest, c.get_luminance())
	return brightest < 0.03
