extends SceneTree

const Contract = preload("res://scripts/world/room_contract.gd")
const Room = preload("res://scripts/world/campaign_room.gd")
const Player = preload("res://scenes/player/player.tscn")
var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	for number in range(1, 7):
		var id := "LOC-%02d" % number
		var layout := Contract.layout(id)
		_check(not layout.is_empty() and layout.room_id == id, id + " has an authored layout")
		var definition := Contract.room(id)
		var room := Room.new()
		room.room_id = id
		room.load_approved_assets = true
		root.add_child(room)
		_check(room.collision_root.get_node("FloorCollision").get_child_count() == 2, id + " floor has visible geometry aligned with collision")
		_check(room.get_node("RoomLighting/KeyLight").shadow_enabled, id + " has a shadow-casting key")
		var environment: Environment = room.get_node("RoomLighting/RoomEnvironment").environment
		_check(not environment.fog_enabled and not environment.volumetric_fog_enabled, id + " has no fog")
		for target in definition.focus_targets:
			var matching: Array = layout.props.filter(func(prop): return prop.id == target.asset_id)
			matching.append_array(layout.fixtures.filter(func(fixture): return fixture.id == target.asset_id))
			_check(not matching.is_empty(), id + " target is attached to an authored visual: " + target.target_id)
			var visual := room.visual_root.get_node_or_null(String(target.asset_id)) as Node3D
			_check(visual != null, id + " target visual exists in the actual room")
			if visual != null:
				var local_point := visual.to_local(preload("res://scripts/world/room_presentation.gd").vector(target.position))
				_check(preload("res://scripts/asset_geometry.gd").bounds(visual).grow(1.1).has_point(local_point), id + " target anchor reaches its actual prop bounds")
		for prop in layout.props:
			_check(prop.position.size() == 3 and prop.rotation_degrees.size() == 3 and prop.scale.size() == 3, id + " prop has explicit transform: " + prop.id)
		if id == "LOC-06":
			_check(environment.ambient_light_energy == 0 and room.get_node("RoomLighting/FillLight").light_energy == 0, "vacuum has no atmospheric fill")
			_check(absf(room.get_node("RoomLighting/KeyLight").rotation_degrees.x) <= 6, "Sun stays low")
			_check(room.collision_root.get_node_or_null("CeilingCollision") == null, "courtyard has open sky")
		else:
			_check(room.collision_root.has_node("CeilingCollision") and room.visual_root.find_children("CeilingStrip*", "MeshInstance3D", true, false).size() == 4, id + " has ceiling and practical strips")
		if OS.get_cmdline_user_args().has("--evidence"):
			var player := Player.instantiate() as PlayerController
			player.character_glb = "res://assets/characters/CH_Kai/CH_Kai.glb"
			var player_anchor: Array = []
			for key in layout.anchors:
				if String(key).ends_with("_player"):
					player_anchor = layout.anchors[key]
			player.position = Vector3(player_anchor[0], player_anchor[1], player_anchor[2])
			(player.get_node("FollowCamera") as FollowCamera).capture_mouse = false
			room.add_child(player)
			for index in 12:
				await physics_frame
			if id == "LOC-06":
				player.character.hide() # EVA outfit is a separate asset task; do not show duty clothes in vacuum.
			else:
				room.set_focus_target(String(definition.focus_targets[0].target_id))
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/M1-01_" + id + ".png"))
		room.free()
		await process_frame
	var storage = preload("res://tools/support/isolated_storage.gd").new()
	_check(storage.setup("room_presentation"), "isolate production saves")
	var runtime = load("res://scenes/campaign/chapter1_campaign.tscn").instantiate()
	storage.configure(runtime)
	root.add_child(runtime)
	for index in 4:
		await physics_frame
	runtime._player.position = Vector3(0, 0, 2.5)
	for index in 4:
		await physics_frame
	_check(runtime.nearby_target().get("target_id") == "commission_route", "in-range/in-view E prompt selects the actual Mission Table")
	_check(runtime.hud.get("_nearby_id") == "commission_route" and runtime.hud.call("_prompt_text", "commission_route") == "Trace the power route", "the prompt on the highlighted prop names its job (doc 25 §1 rule 7)")
	if OS.get_cmdline_user_args().has("--evidence"):
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/M1-01_campaign_prompt.png"))
	runtime._player.follow_camera.yaw = PI
	for index in 4:
		await physics_frame
	_check(runtime.nearby_target().is_empty(), "targets behind the camera cannot receive the E interaction")
	runtime.free()
	storage.cleanup()
	print("ROOM PRESENTATION RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL " + message)
