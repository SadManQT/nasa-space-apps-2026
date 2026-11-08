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
	# Ferreira's portrait is her approved Earth duty layer (M3-5A take A): 16:9 with its own control room, like Rao's.
	var ferreira := load("res://assets/ui/portraits/CH_Ferreira_screen.png") as Texture2D
	var rao := load("res://assets/ui/portraits/CH_Rao_screen.png") as Texture2D
	_check(ferreira != null and rao != null and ferreira.get_size() == rao.get_size(), "Ferreira's duty portrait matches Rao's screen portrait size")
	# Noor's live call (M4-06) uses her cut-out portrait over the Dhaka rooftop (morning at EX-CH08-S10, noon at EX-CH08-S12).
	var noor := load(Crew.NOOR_PORTRAIT) as Texture2D
	var rooftop_morning := load(Crew.NOOR_ROOFTOP) as Texture2D
	var rooftop_noon := load(Crew.NOOR_ROOFTOP_NOON) as Texture2D
	_check(noor != null and rooftop_morning != null and rooftop_noon != null, "CH_Noor_live and both EN_NoorRooftop variants load")
	if rooftop_morning != null and rooftop_noon != null and base != null:
		_check(rooftop_morning.get_size() == base.get_size() and rooftop_noon.get_size() == base.get_size(), "both Noor rooftop backdrops are 16:9 like the Earth room")

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
		if child is Label3D and portrait != null and absf(child.position.z - portrait.position.z) < 0.05:
			caption = child
	# The screen is the commons' earth_screen fixture; its picture area is the fixture face inside the bezel.
	var spec := room.fixture("earth_screen")
	_check(not spec.is_empty(), "the commons has its Earth screen fixture")
	var area := Vector2(float(spec.get("size", [2.8, 1.4, 0])[0]), float(spec.get("size", [2.8, 1.4, 0])[1])) * 0.94
	_check(backdrop != null and portrait != null and caption != null, "the commons builds the Earth screen layers")
	if backdrop == null or portrait == null or caption == null:
		_finish()
		return
	_check(not backdrop.visible and not portrait.visible and not caption.visible, "the screen is dark before any call")
	_check(not backdrop.transparent and portrait.render_priority < caption.render_priority, "draw order is room (opaque), caller, caption from any camera distance")
	_check([backdrop, portrait, caption].all(func(layer): return layer.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF), "the screen casts no shadow on its wall")
	_check(backdrop.position.z < portrait.position.z and portrait.position.z - backdrop.position.z < 0.02, "the Earth room lies just behind the caller on the screen face")
	var fit_height := minf(area.y, area.x * 9.0 / 16.0)
	var bottom := backdrop.position.y - area.y * 0.5
	_check(caption.position.y < bottom and caption.position.y > bottom - 0.3, "the caption sits just under the screen")

	for case in [["rao", "EARTH LINK", base, "Rao · Earth link"], ["ferreira", "QUEUED TEXT", base, "Ferreira · Message"],
			["ferreira", "STORED RECORDING", archive, "Ferreira · Recording"]]:
		crew.present_line({"speaker_id": case[0], "origin_label": case[1]}, false)
		_check(backdrop.visible and portrait.visible and caption.visible, "%s on the %s: room, caller and caption show" % [case[0], case[1]])
		_check(backdrop.texture == case[2], "%s on the %s uses the %s room" % [case[0], case[1], "archive" if case[2] == archive else "live"])
		_check(caption.text == case[3], "caption reads '%s' (got '%s')" % [case[3], caption.text])
		var room_height := backdrop.pixel_size * backdrop.texture.get_height()
		var caller_height := portrait.pixel_size * portrait.texture.get_height()
		_check(absf(room_height - caller_height) < 0.005, "%s fills the screen height like the room (%.3f m vs %.3f m)" % [case[0], caller_height, room_height])
		_check(absf(room_height - fit_height) < 0.005 and backdrop.pixel_size * backdrop.texture.get_width() <= area.x + 0.005, "the Earth room is as large as fits inside the screen's bezel (%.3f m high)" % room_height)
		_check(portrait.pixel_size * portrait.texture.get_width() <= area.x + 0.005, "%s stays inside the bezel" % case[0])

	crew.present_line({"speaker_id": "kai", "origin_label": "LOCAL LIVE"}, false)
	_check(not backdrop.visible and not portrait.visible and not caption.visible, "a local speaker turns the Earth screen off, room included")
	crew.present_line({"speaker_id": "rao", "origin_label": "EARTH LINK"}, false)
	_check(backdrop.visible and backdrop.texture == base, "the next Earth call brings the live room back")
	var rao_height := portrait.pixel_size * portrait.texture.get_height()

	# Noor's queued text messages (CH05/CH06) and 2034 audio recording (CH07) do not turn on the live video screen.
	for non_live in ["QUEUED TEXT", "STORED RECORDING"]:
		crew.present_line({"speaker_id": "noor", "origin_label": non_live}, false)
		_check(not backdrop.visible and not portrait.visible and not caption.visible, "Noor's %s does not turn on the live Earth screen" % non_live)

	# Noor's live Earth-link calls (M4-06): morning rooftop at EX-CH08-S10, noon rooftop at EX-CH08-S12.
	for noor_case in [["EX-CH08-S10", rooftop_morning, "morning"], ["EX-CH08-S12", rooftop_noon, "noon"]]:
		var scene_id: String = noor_case[0]
		var expected_rooftop: Texture2D = noor_case[1]
		var time_of_day: String = noor_case[2]
		crew.place(scene_id, room, Vector3.ZERO)
		for i in 3:
			await physics_frame
		backdrop = room.get_node_or_null("EarthDesk") as Sprite3D
		portrait = room.get_node_or_null("EarthPortrait") as Sprite3D
		caption = null
		for child in room.get_children():
			if child is Label3D and portrait != null and absf(child.position.z - portrait.position.z) < 0.05:
				caption = child
		crew.present_line({"speaker_id": "noor", "origin_label": "EARTH LINK"}, false)
		_check(backdrop.visible and portrait.visible and caption.visible, "Noor on EARTH LINK (%s): rooftop, caller and caption show" % scene_id)
		_check(backdrop.texture == expected_rooftop, "Noor at %s uses the %s Dhaka rooftop backdrop (%s)" % [scene_id, time_of_day, backdrop.texture.resource_path if backdrop.texture != null else "null"])
		_check(portrait.texture == noor, "Noor at %s uses her cut-out portrait CH_Noor_live.png" % scene_id)
		_check(caption.text == "Noor · Earth link", "Noor's caption reads 'Noor · Earth link' (got '%s')" % caption.text)
		var rooftop_height := backdrop.pixel_size * backdrop.texture.get_height()
		var noor_height := portrait.pixel_size * portrait.texture.get_height()
		_check(absf(noor_height - rao_height) < 0.005 and absf(noor_height - rooftop_height) < 0.005, "Noor at %s has the same height as Rao's portrait and the backdrop (%.3f m vs %.3f m)" % [scene_id, noor_height, rao_height])
		_check(backdrop.pixel_size * backdrop.texture.get_width() <= area.x + 0.005 and portrait.pixel_size * portrait.texture.get_width() <= area.x + 0.005, "Noor and her rooftop backdrop at %s never extend past the bezel" % scene_id)

	# Verify Rao on EARTH LINK still uses EN_EarthDesk unchanged after Noor's call.
	crew.present_line({"speaker_id": "rao", "origin_label": "EARTH LINK"}, false)
	_check(backdrop.texture == base and portrait.texture == rao and caption.text == "Rao · Earth link", "Rao keeps EN_EarthDesk after Noor's call")

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
