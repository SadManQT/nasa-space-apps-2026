## Headless checks for the station's Earth screen (M1-07): EN_EarthDesk behind the Earth-side caller,
## the archive room for stored recordings, both callers at the same size, the caption in player words,
## a fixed draw order (room, caller, caption), and a screen that is dark when nobody is calling.
##   Godot --headless --path game --script res://tools/test_earth_screen.gd
extends SceneTree

const Crew = preload("res://scripts/world/campaign_crew.gd")
const Room = preload("res://scripts/world/campaign_room.gd")
var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var desk: Dictionary = UiKit.kit().get("earth_screen", {})
	var base := load(String(desk.get("base", ""))) as Texture2D
	var archive := load(String(desk.get("variants", {}).get("STORED RECORDING", ""))) as Texture2D
	_check(base != null and archive != null, "EN_EarthDesk and its archive variant load")
	if base != null and archive != null:
		_check(absf(float(base.get_width()) / base.get_height() - 16.0 / 9.0) < 0.01, "the Earth room is 16:9 like the screen")
		_check(archive.get_size() == base.get_size(), "the archive room matches the live room's size")
	var ferreira := Image.load_from_file(ProjectSettings.globalize_path("res://assets/ui/portraits/CH_Ferreira_screen.png"))
	_check(ferreira != null and ferreira.detect_alpha() != Image.ALPHA_NONE and ferreira.get_pixel(4, 4).a < 0.05, "Ferreira's portrait is cut out, so the Earth room shows behind her")

	var crew := Crew.new()
	root.add_child(crew)
	var room := Room.new()
	room.room_id = "LOC-01"
	root.add_child(room)
	crew.place("EX-CH01-S01", room, Vector3.ZERO)
	for i in 3:
		await physics_frame
	var backdrop := room.get_node_or_null("EarthDesk") as Sprite3D
	var portrait := room.get_node_or_null("EarthPortrait") as Sprite3D
	var caption: Label3D = null
	for child in room.get_children():
		if child is Label3D and child.position.z > -5.3 and child.position.z < -5.0:
			caption = child
	_check(backdrop != null and portrait != null and caption != null, "the commons builds the Earth screen layers")
	if backdrop == null or portrait == null or caption == null:
		_finish()
		return
	_check(not backdrop.visible and not portrait.visible and not caption.visible, "the screen is dark before any call")
	_check(not backdrop.transparent and portrait.render_priority < caption.render_priority, "draw order is room (opaque), caller, caption from any camera distance")
	var screen_top := backdrop.position.y + float(desk.get("width_m", 4.8)) * 9.0 / 16.0 / 2.0
	var sign: Label3D = null
	for node in room.find_children("*", "Label3D", true, false):
		if (node as Label3D).text == String(room.get_meta("room_name", "")) and not (node as Label3D).text.is_empty():
			sign = node
	_check(sign != null, "the commons has its wall sign")
	if sign != null:
		var sign_box := sign.global_transform * sign.get_aabb()
		_check(screen_top < sign_box.position.y - 0.05, "the screen's top edge (%.2f m) stays clear of the wall sign (from %.2f m)" % [screen_top, sign_box.position.y])
	_check([backdrop, portrait, caption].all(func(layer): return layer.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF), "the screen casts no shadow on its wall")
	_check(caption.position.y > backdrop.position.y - float(desk.get("width_m", 4.8)) * 9.0 / 32.0, "the caption sits on the screen as a lower third")

	for case in [["rao", "EARTH LINK", base, "Rao · Earth link"], ["ferreira", "QUEUED TEXT", base, "Ferreira · Message"],
			["ferreira", "STORED RECORDING", archive, "Ferreira · Recording"]]:
		crew.present_line({"speaker_id": case[0], "origin_label": case[1]}, false)
		_check(backdrop.visible and portrait.visible and caption.visible, "%s on the %s: room, caller and caption show" % [case[0], case[1]])
		_check(backdrop.texture == case[2], "%s on the %s uses the %s room" % [case[0], case[1], "archive" if case[2] == archive else "live"])
		_check(caption.text == case[3], "caption reads '%s' (got '%s')" % [case[3], caption.text])
		var room_height := backdrop.pixel_size * backdrop.texture.get_height()
		var caller_height := portrait.pixel_size * portrait.texture.get_height()
		_check(absf(room_height - caller_height) < 0.005, "%s fills the screen height like the room (%.3f m vs %.3f m)" % [case[0], caller_height, room_height])
		_check(absf(backdrop.pixel_size * backdrop.texture.get_width() - float(desk.get("width_m", 4.8))) < 0.005, "the Earth room spans the screen width from ui_kit.json")

	crew.present_line({"speaker_id": "kai", "origin_label": "LOCAL LIVE"}, false)
	_check(not backdrop.visible and not portrait.visible and not caption.visible, "a local speaker turns the Earth screen off, room included")
	crew.present_line({"speaker_id": "rao", "origin_label": "EARTH LINK"}, false)
	_check(backdrop.visible and backdrop.texture == base, "the next Earth call brings the live room back")

	var garden := Room.new()
	garden.room_id = "LOC-03"
	root.add_child(garden)
	crew.place("EX-CH01-S05", garden, Vector3.ZERO)
	for i in 3:
		await physics_frame
	_check(garden.get_node_or_null("EarthDesk") == null, "only the commons has an Earth screen")
	garden.free()
	room.free()
	crew.free()
	_finish()

func _finish() -> void:
	print("EARTH SCREEN RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL " + message)
