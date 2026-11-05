extends SceneTree
const Crew = preload("res://scripts/world/campaign_crew.gd")
const Room = preload("res://scripts/world/campaign_room.gd")
const Roster = preload("res://scripts/companions/companion_roster.gd")
const Contract = preload("res://scripts/world/room_contract.gd")
var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if OS.get_cmdline_user_args().has("--portrait"):
		await _portrait()
		quit()
		return
	root.size = Vector2i(1280, 720)
	# Check every authored cut, including split teams and Ferreira's arrival.
	for scene_id in Roster.SCENE_ROSTERS.data.scenes:
		var roster := Roster.scene_roster(scene_id)
		var room_id := Contract.room_for_scene(scene_id)
		var active := Roster.playable_actor(scene_id)
		_check(roster[active].physical_location_id == room_id, scene_id + " player is physically in the viewed room")
		var placed: Array[Vector3] = []
		for id in roster:
			if roster[id].physical_location_id != room_id or id == active:
				continue
			var at := Crew.anchor_position(room_id, id)
			var size: Array = Contract.room(room_id).bounds_m
			_check(absf(at.x) < size[0] / 2.0 - 0.3 and absf(at.z) < size[1] / 2.0 - 0.3, scene_id + " safe anchor " + id)
			for other in placed:
				_check(at.distance_to(other) > 0.6, scene_id + " companions do not overlap")
			placed.append(at)
	var crew := Crew.new()
	root.add_child(crew)
	var seen := {}
	for scene_id in ["EX-CH01-S01", "EX-CH01-S02", "EX-CH01-S04", "EX-CH01-S05", "EX-CH02-S03", "EX-CH03-S06", "EX-CH04-S02", "EX-CH04-S04", "EX-CH04-S06", "EX-CH05-S02", "EX-CH08-S03", "EX-CH08-S07", "EX-CH01-S01"]:
		var room := Room.new()
		room.room_id = Contract.room_for_scene(scene_id)
		root.add_child(room)
		# Stage the player where Chapter1Campaign does: the room's authored *_player anchor. The kit
		# rooms (M1-06) put furniture at the origin, e.g. the Commons Mission Table.
		var player_at := Vector3.ZERO
		var anchors := Contract.anchors(room.room_id)
		for key in anchors:
			if String(key).ends_with("_player"):
				player_at = Vector3(anchors[key][0], anchors[key][1], anchors[key][2])
		var player := crew.place(scene_id, room, player_at)
		for i in 5:
			await physics_frame
		_check(player.position.distance_to(player_at) < 0.1, "viewpoint cut does not snap the player onto another body")
		var expected := 0
		for row in Roster.scene_roster(scene_id).values():
			if row.physical_location_id == room.room_id:
				expected += 1
		_check(crew.local_ids.size() == expected, scene_id + " exact local count")
		_check(player.controlled and player.collision_mask == 3 and player.follow_camera.camera.current, "only active player owns movement and camera")
		var controlled := 0
		for body in crew.bodies.values():
			if body.controlled:
				controlled += 1
			if body.visible:
				_check(body.character.get_node_or_null("FaceAtlas") != null and body.character.get_node_or_null("HairSprings") != null, "shared face and hair setup")
				_check(body.animation.has_clip("Talk_loop") and body.animation.has_clip("Inspect"), "installed clips are usable")
		_check(controlled == 1, "one controlled body")
		var speaker := ""
		for id in crew.local_ids:
			if crew.bodies[id] != player:
				speaker = id
				break
		crew.present_line({"speaker_id": speaker, "origin_label": "LOCAL LIVE"}, false)
		_check(player.attention_target == crew.bodies.get(speaker), "listener gaze tracks displayed speaker")
		crew.set_paused(true)
		_check(crew.bodies.values().all(func(body): return body.process_mode == Node.PROCESS_MODE_DISABLED), "pause stops the whole cast")
		crew.set_paused(false)
		var helper: PlayerController = crew.bodies.get(speaker)
		if helper != null:
			var ray := PhysicsRayQueryParameters3D.create(helper.global_position + Vector3(-1, 0.85, 0), helper.global_position + Vector3(1, 0.85, 0), 2)
			_check(not player.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(), "companion blocks the player collision layer")
		crew.present_line({}, true)
		_check(crew.local_ids.all(func(id): return not crew.bodies[id].look_at_enabled and crew.bodies[id].animation._talk_requested.is_empty()), "reduced motion suppresses gestures and gaze")
		crew.present_line({}, false)
		if OS.get_cmdline_user_args().has("--evidence") and not seen.has(room.room_id):
			await _overview(room, crew)
			seen[room.room_id] = true
		room.free()
		await process_frame
	_check(crew.bodies.size() == 5, "five cached bodies; returning to a scene never duplicates them")
	crew.free()
	print("CAMPAIGN CREW RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _overview(room: CampaignRoom, crew: CampaignCrew) -> void:
	var camera := Camera3D.new()
	room.add_child(camera)
	var depth: float = Contract.room(room.room_id).bounds_m[1]
	camera.position = Vector3(0, 2.8, minf(5.0, depth / 2.0 - 0.6))
	camera.look_at(Vector3(0, 1, 0))
	camera.current = true
	camera.fov = 85
	if Contract.room(room.room_id).pressure == "vacuum":
		# Outfit replacement has its own task; do not document duty clothes as EVA.
		for id in crew.local_ids:
			crew.bodies[id].character.hide()
	crew.present_line({"speaker_id": "ferreira", "origin_label": "EARTH SCREEN"}, false)
	for i in 15:
		await physics_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/M1-17_" + room.room_id + ".png"))
	camera.free()

func _portrait() -> void:
	root.size = Vector2i(512, 512)
	var scene := Node3D.new()
	root.add_child(scene)
	var body := preload("res://scenes/player/player.tscn").instantiate() as PlayerController
	body.character_glb = "res://assets/characters/CH_Ferreira/CH_Ferreira.glb"
	body.controlled = false
	body.get_node("FollowCamera").active = false
	body.get_node("FollowCamera").capture_mouse = false
	scene.add_child(body)
	body.set_controlled(false)
	body.face_towards(Vector3(0, 0, 2))
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-30, -25, 0)
	light.light_energy = 1.5
	scene.add_child(light)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("#263343")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.5
	scene.add_child(env)
	var camera := Camera3D.new()
	scene.add_child(camera)
	camera.position = Vector3(0, 1.48, 1.1)
	camera.look_at(Vector3(0, 1.45, 0))
	camera.fov = 48
	camera.current = true
	for i in 20:
		await physics_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://assets/ui/portraits/CH_Ferreira_screen.png"))
	scene.free()

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + message)
