extends Node3D
class_name CampaignCrew

## Presentation only: the roster owns location; operations own facts and resources.
## Bodies persist across viewpoint cuts so a cut cannot duplicate a character.
const Roster = preload("res://scripts/companions/companion_roster.gd")
const Contract = preload("res://scripts/world/room_contract.gd")
const PlayerScene = preload("res://scenes/player/player.tscn")
const Helmet = preload("res://assets/props/PR_Helmet_Roles/helmet_roles.gd")
## Each cast member's body in the outfit the current scene stages (bodies[id]); every outfit body ever built is kept
## in _wardrobe ("<id>/<outfit>"), so a cut back to an earlier outfit reuses it and never duplicates a character.
var bodies: Dictionary = {}
var _wardrobe: Dictionary = {}
var local_ids: Array[String] = []
var player: PlayerController
var room: CampaignRoom
var _speaker := ""
var _screen: Sprite3D
var _screen_label: Label3D
var _screen_area := Vector2(2.8, 1.4)
var _screen_backdrop: Sprite3D

## Stages next_room for scene_id (chapter staging, scene anchors, carried objects) and places the scene's roster in
## it: the playable actor at player_at, everyone else at the scene's anchors. choices is story_log.choices; it only
## moves relationship staging, e.g. who stands at Kai's shoulder in EX-CH06-S10 (doc 24 §5.2 D11); moments is
## story_log.moments (e.g. the CH01-MUGS-NAMED mugs).
func place(scene_id: String, next_room: CampaignRoom, player_at: Vector3, choices: Dictionary = {}, moments: Array = []) -> PlayerController:
	room = next_room
	local_ids.clear()
	# The room is staged first, so its scene furniture, stations and anchors exist before anyone stands in it.
	room.set_story_choices(choices, moments)
	room.set_scene_context(scene_id)
	var active := Roster.playable_actor(scene_id)
	var roster := Roster.scene_roster(scene_id)
	# The scene's anchors once per placement: the room's base anchors under its applied staging.
	var anchors := Contract.anchors(room.room_id)
	anchors.merge(room.stage().get("anchors", {}), true)
	# On the terrain provider's ground the same anchors stand at the terrain height (RoomContract.terrain, M1-82).
	anchors.merge(room.terrain_anchors(), true)
	# A scene whose staging moves the viewpoint (M3-3R: EX-CH03-S07 starts in the cold annex under the warm bay) names
	# its own "<room>_player" anchor; it wins over the room's base player anchor the caller passes.
	for key in room.stage().get("anchors", {}):
		if String(key).ends_with("_player"):
			var staged: Array = room.stage().anchors[key]
			player_at = Vector3(staged[0], staged[1], staged[2])
	var outfits: Dictionary = room.stage().get("outfits", {})
	for body in _wardrobe.values():
		body.hide()
		body.process_mode = Node.PROCESS_MODE_DISABLED
		body.collision_layer = 0
		body.set_controlled(false)
	for id in roster:
		if roster[id].physical_location_id != room.room_id or not roster[id].present:
			continue
		var body := _body(id, String(outfits.get(id, "")))
		body.show()
		body.character.show()
		body.process_mode = Node.PROCESS_MODE_INHERIT
		body.collision_layer = 2
		body.set_controlled(id == active)
		body.animation.reset_presentation()
		body.foot_ik_enabled = true
		body.attention_target = null
		local_ids.append(id)
		if id == active:
			player = body
			body.position = player_at
		else:
			body.position = _anchor_in(anchors, room.room_id, id)
		body.face_towards(Vector3(0, 0, -2))
		body.reset_placement()
	# In the Safe Room a listener at an installed crew seat sits in it (doc 09: no wandering during exposure); one at a
	# staged work anchor (e.g. EX-CH07-S02 at the shelter diagram) stands. No fictitious hand/tool contact.
	if room.room_id == "LOC-04":
		for id in local_ids:
			var body: PlayerController = bodies[id]
			if id == active or not room.has_installed_seat_at(body.position):
				continue
			body.face_towards(body.position + Vector3.FORWARD)
			body.animation.set_rest_clip("SitIdle_loop")
			body.foot_ik_enabled = false
	_build_screen()
	_attach_carried(room.stage().get("carried", {}))
	return player

## The floor point where cast member id stands in a room: the scene's staged anchor when scene_id is given
## (RoomContract.staged_anchors), else the room's base anchor, else a safe rear lane.
static func anchor_position(room_id: String, id: String, scene_id: String = "", choices: Dictionary = {}) -> Vector3:
	return _anchor_in(Contract.anchors(room_id) if scene_id.is_empty() else Contract.staged_anchors(room_id, scene_id, choices), room_id, id)

static func _anchor_in(anchors: Dictionary, room_id: String, id: String) -> Vector3:
	for key in anchors:
		if String(key).ends_with("_" + id):
			var at: Array = anchors[key]
			return Vector3(at[0], at[1], at[2])
	# Later-room kit contracts omit some of the five anchors. Use explicit safe
	# rear lanes, away from front-facing controls, with one slot per actor.
	var slot := Roster.ACTOR_IDS.find(id)
	var width: float = Contract.room(room_id).bounds_m[0]
	var depth: float = Contract.room(room_id).bounds_m[1]
	return Vector3((slot - 2) * minf(1.5, (width - 2.0) / 5.0), 0, minf(3.3, depth / 2.0 - 0.7))

## Objects a cast member carries in this scene (room staging "carried": id -> {path, bone, position,
## rotation_degrees}), e.g. the charged hand light clipped to Kai from EX-CH06-S01 to S11 (doc 24 §2.9). Every body
## loses last scene's carried object first, so a viewpoint cut never duplicates one.
func _attach_carried(carried: Dictionary) -> void:
	for id in bodies:
		var body: PlayerController = bodies[id]
		for old in body.find_children("Carried_*", "BoneAttachment3D", true, false):
			old.get_parent().remove_child(old)
			old.queue_free()
		if not carried.has(id) or not local_ids.has(id) or body.character == null:
			continue
		var spec: Dictionary = carried[id]
		var rigs := body.character.find_children("*", "Skeleton3D", true, false)
		var model := AssetGeometry.load_glb(String(spec.path))
		if rigs.is_empty() or model == null:
			continue
		var rig := rigs[0] as Skeleton3D
		var bone := rig.find_bone(String(spec.bone))
		if bone < 0:
			model.free()
			continue
		var socket := BoneAttachment3D.new()
		socket.name = "Carried_" + String(spec.path).get_file().get_basename()
		socket.bone_name = String(spec.bone)
		rig.add_child(socket)
		# The authored point is in the rig's rest space (character facing +Z, its right side at -X); the attachment
		# follows the bone from there, so the object rides with the hips in every clip.
		var rest := Transform3D(Basis.from_euler(_radians(spec.get("rotation_degrees", [0, 0, 0]))), _vector(spec.get("position", [0, 0, 0])))
		model.transform = rig.get_bone_global_rest(bone).affine_inverse() * rest
		socket.add_child(model)

static func _vector(value: Array) -> Vector3:
	return Vector3(float(value[0]), float(value[1]), float(value[2]))

static func _radians(value: Array) -> Vector3:
	return Vector3(deg_to_rad(float(value[0])), deg_to_rad(float(value[1])), deg_to_rad(float(value[2])))

## The cast member's body in an outfit: "" is the everyday coverall; "eva" is the fitted EVA suit (M3-3A CH_<Name>_EVA)
## with the role-striped helmet seated on its neck ring, visor up, and a helmet lamp (EX-CH03-S07's suited annex entry).
func _body(id: String, outfit: String = "") -> PlayerController:
	var key := id + "/" + outfit
	if _wardrobe.has(key):
		bodies[id] = _wardrobe[key]
		return bodies[id]
	var body := PlayerScene.instantiate() as PlayerController
	var cast := id.capitalize()
	body.name = cast if outfit.is_empty() else cast + "_" + outfit.to_upper()
	body.controlled = false
	body.gravity = 1.62
	var suffix := "_EVA" if outfit == "eva" else ""
	body.character_glb = "res://assets/characters/CH_%s%s/CH_%s%s.glb" % [cast, suffix, cast, suffix]
	if not suffix.is_empty() and ResourceLoader.exists("res://resources/player/ch_%s.tres" % id):
		body.tuning = load("res://resources/player/ch_%s.tres" % id) as LocomotionTuning  # the cast member's own gait
	var camera := body.get_node("FollowCamera") as FollowCamera
	camera.active = false
	camera.capture_mouse = false
	add_child(body)
	body.set_controlled(false)
	if outfit == "eva" and body.character != null:
		var helmet := Helmet.instance()
		if helmet != null and Helmet.apply_role(helmet, id) and Helmet.equip(helmet, body.character, id) != null:
			helmet.name = "Helmet"
			Helmet.set_visor_closed(helmet, 0.0)
			var socket := helmet.find_child("Socket_Lamp", true, false) as Node3D
			var lamp := SpotLight3D.new()
			lamp.name = "HelmetLamp"
			lamp.position = socket.position if socket != null else Vector3(0, 0.35, 0.17)
			lamp.rotation_degrees = Vector3(-12, 180, 0)  # the helmet faces +Z; a spot shines along its -Z
			lamp.light_color = Color(1.0, 0.95, 0.88)
			lamp.light_energy = 2.5
			lamp.spot_range = 7.0
			lamp.spot_angle = 32.0
			lamp.shadow_enabled = true
			helmet.add_child(lamp)
		elif helmet != null and helmet.get_parent() == null:
			helmet.free()
	_wardrobe[key] = body
	bodies[id] = body
	return body

## The HUD passes only the currently displayed, already-gated caption.
func present_line(line: Dictionary, reduced_motion: bool) -> void:
	_speaker = String(line.get("speaker_id", ""))
	var speaker: PlayerController = bodies.get(_speaker) if local_ids.has(_speaker) else null
	for id in local_ids:
		var body: PlayerController = bodies[id]
		body.attention_target = speaker if body != speaker else player
		body.look_at_enabled = not reduced_motion
		body.animation.idle_variations = not reduced_motion and room.room_id != "LOC-04"
		# Full-body Talk would lift a seated listener off the bench. Keep the
		# seated base and its gaze; captions identify that speaker exactly.
		body.animation.set_talking(not line.is_empty() and not reduced_motion and room.room_id != "LOC-04", body != speaker)
	if _screen != null:
		var earth := _speaker in ["rao", "ferreira"] and not local_ids.has(_speaker)
		_screen.visible = earth
		_screen_label.visible = earth
		_screen_backdrop.visible = false  # the Earth room shows only during a call (_show_earth_desk)
		if earth:
			var path := "res://assets/ui/portraits/CH_%s_screen.png" % _speaker.capitalize()
			_screen.texture = load(path) if ResourceLoader.exists(path) else null
			var origin := String(line.get("origin_label", ""))
			_show_earth_desk(origin)
			var origin_word := String(UiDesign.text().get("dialogue", {}).get("origins", {}).get(origin, origin.capitalize()))
			_screen_label.text = _speaker.capitalize() + (" · " + origin_word if not origin_word.is_empty() else "")

func react(result: Dictionary, reduced_motion: bool) -> void:
	if reduced_motion or not result.get("accepted", false) or result.get("duplicate", false) or result.get("result", {}).get("duplicate", false) or room.room_id == "LOC-04":
		return
	for id in local_ids:
		var body: PlayerController = bodies[id]
		if body != player and id != _speaker:
			body.animation.request_action("Inspect" if room.room_id == "LOC-03" else "Agree")
			break

func set_paused(value: bool) -> void:
	for id in local_ids:
		bodies[id].process_mode = Node.PROCESS_MODE_DISABLED if value else Node.PROCESS_MODE_INHERIT

## The Earth screen: EN_EarthDesk (the room behind the caller) as a 16:9 backdrop,
## the caller's portrait over it, and the caller's name with the source word.
func _build_screen() -> void:
	_screen = null
	_screen_label = null
	_screen_backdrop = null
	# The Commons screen, or a room's staged Earth console (the garden's from EX-CH02-S01, M3-2R; Ferreira's Earth link in
	# the service rooms, EX-CH03-S03, and at the annex, EX-CH03-S06, M3-3R).
	var spec := room.fixture("earth_screen")
	if room.room_id != "LOC-01" and spec.is_empty():
		return
	var at := Vector3(0, 2, -5.2)
	_screen_area = Vector2(2.8, 1.4)
	# "yaw" turns a wall-mounted screen (90: on a west wall, facing +X); its box size then runs along that wall.
	var facing := Basis(Vector3.UP, deg_to_rad(float(spec.get("yaw", 0.0))))
	if not spec.is_empty():
		# The portrait lies on the screen's room-facing surface, inset from its bezel.
		var centre: Array = spec.position
		var size: Array = spec.size
		var across_x := absf(facing.z.z) >= absf(facing.z.x)
		var depth := float(size[2]) if across_x else float(size[0])
		at = Vector3(float(centre[0]), float(centre[1]), float(centre[2])) + facing.z * (depth * 0.5 + 0.01)
		_screen_area = Vector2(float(size[0]) if across_x else float(size[2]), float(size[1])) * 0.94
	# EN_EarthDesk lies just behind the caller, on the same screen.
	_screen_backdrop = Sprite3D.new()
	_screen_backdrop.name = "EarthDesk"
	_screen_backdrop.position = at - facing.z * 0.005
	_screen_backdrop.shaded = false
	_screen_backdrop.transparent = false  # opaque pass: the caller and caption always draw over it
	room.add_child(_screen_backdrop)
	_screen = Sprite3D.new()
	_screen.name = "EarthPortrait"
	_screen.position = at
	_screen.pixel_size = 0.004
	_screen.shaded = false
	room.add_child(_screen)
	_screen_label = Label3D.new()
	_screen_label.position = at + facing * Vector3(0, -_screen_area.y * 0.5 - 0.12, 0.005)
	_screen_label.font_size = 32
	_screen_label.pixel_size = 0.005
	# Caller and caption are both see-through; sorting by centre distance alone put the portrait over
	# the caption whenever the camera stood close to the screen, so the caption always draws last.
	_screen_label.render_priority = 1
	room.add_child(_screen_label)
	for layer in [_screen_backdrop, _screen, _screen_label]:
		layer.basis = facing
		layer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF  # a lit screen throws no shadow on its wall
	_screen.hide()
	_screen_label.hide()
	_screen_backdrop.hide()

## Puts EN_EarthDesk behind the portrait (the archive variant for a stored recording), as large as fits inside the
## physical screen, and fits the portrait to the backdrop's height (never past the bezel), so Rao and Ferreira
## appear on the same screen at the same size.
func _show_earth_desk(origin_label: String) -> void:
	var desk: Dictionary = UiKit.kit().get("earth_screen", {})
	var path := String(desk.get("variants", {}).get(origin_label.to_upper(), desk.get("base", "")))
	var texture: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_screen_backdrop.texture = texture
	_screen_backdrop.visible = texture != null
	var aspect := float(texture.get_height()) / float(texture.get_width()) if texture != null else 9.0 / 16.0
	var height_m := minf(_screen_area.y, _screen_area.x * aspect)
	if texture != null:
		_screen_backdrop.pixel_size = height_m / float(texture.get_height())
	if _screen.texture != null:
		var pixels := Vector2(_screen.texture.get_size())
		_screen.pixel_size = minf(_screen_area.x / pixels.x, height_m / pixels.y)
