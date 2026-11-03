extends Node3D
class_name CampaignCrew

## Presentation only: the roster owns location; operations own facts and resources.
## Bodies persist across viewpoint cuts so a cut cannot duplicate a character.
const Roster = preload("res://scripts/companions/companion_roster.gd")
const Contract = preload("res://scripts/world/room_contract.gd")
const PlayerScene = preload("res://scenes/player/player.tscn")
var bodies: Dictionary = {}
var local_ids: Array[String] = []
var player: PlayerController
var room: CampaignRoom
var _speaker := ""
var _seats: Node3D
var _screen: Sprite3D
var _screen_label: Label3D

func place(scene_id: String, next_room: CampaignRoom, player_at: Vector3) -> PlayerController:
	room = next_room
	local_ids.clear()
	var active := Roster.playable_actor(scene_id)
	var roster := Roster.scene_roster(scene_id)
	for body in bodies.values():
		body.hide()
		body.process_mode = Node.PROCESS_MODE_DISABLED
		body.collision_layer = 0
		body.set_controlled(false)
	for id in roster:
		if roster[id].physical_location_id != room.room_id or not roster[id].present:
			continue
		var body := _body(id)
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
			body.position = anchor_position(room.room_id, id)
		body.face_towards(Vector3(0, 0, -2))
		body.reset_placement()
	# A safe, simple bench backs seated listeners; no fictitious hand/tool contact.
	_seats = Node3D.new()
	_seats.name = "CrewSeats"
	room.add_child(_seats)
	if room.room_id == "LOC-04":
		for id in local_ids:
			if id == active:
				continue
			var body: PlayerController = bodies[id]
			body.face_towards(body.position + Vector3.FORWARD)
			body.animation.set_rest_clip("SitIdle_loop")
			body.foot_ik_enabled = false
			_add_seat(body.position)
	_build_screen()
	return player

static func anchor_position(room_id: String, id: String) -> Vector3:
	var anchors := Contract.anchors(room_id)
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

func _body(id: String) -> PlayerController:
	if bodies.has(id):
		return bodies[id]
	var body := PlayerScene.instantiate() as PlayerController
	body.name = id.capitalize()
	body.controlled = false
	body.gravity = 1.62
	body.character_glb = "res://assets/characters/CH_%s/CH_%s.glb" % [id.capitalize(), id.capitalize()]
	var camera := body.get_node("FollowCamera") as FollowCamera
	camera.active = false
	camera.capture_mouse = false
	add_child(body)
	body.set_controlled(false)
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
		if earth:
			var path := "res://assets/ui/portraits/CH_%s_screen.png" % _speaker.capitalize()
			_screen.texture = load(path) if ResourceLoader.exists(path) else null
			_screen_label.text = "%s / %s" % [_speaker.capitalize(), line.get("origin_label", "EARTH SCREEN")]

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

func _add_seat(at: Vector3) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.65, 0.12, 0.6)
	mesh.mesh = box
	mesh.position = at + Vector3(0, 0.43, 0.1)
	_seats.add_child(mesh)
	ToonMaterials.apply_to_tree(mesh, false, false)

func _build_screen() -> void:
	_screen = null
	_screen_label = null
	if room.room_id != "LOC-01":
		return
	_screen = Sprite3D.new()
	_screen.name = "EarthPortrait"
	_screen.position = Vector3(0, 2, -5.2)
	_screen.pixel_size = 0.004
	_screen.shaded = false
	room.add_child(_screen)
	_screen_label = Label3D.new()
	_screen_label.position = Vector3(0, 0.9, -5.15)
	_screen_label.font_size = 32
	_screen_label.pixel_size = 0.005
	room.add_child(_screen_label)
	_screen.hide()
	_screen_label.hide()
