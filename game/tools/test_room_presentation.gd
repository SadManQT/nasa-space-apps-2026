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
		_check(room.collision_root.has_node("FloorCollision") and (room.visual_root.has_node("HabitatKit") or room.collision_root.get_node("FloorCollision").get_child_count() == 2), id + " floor has visible geometry aligned with collision")
		_check(room.get_node("RoomLighting/KeyLight").shadow_enabled or room.get_node("RoomLighting").get_children().any(func(n): return n is OmniLight3D and n.shadow_enabled), id + " has motivated shadow-casting lighting")
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
		if room.visual_root.has_node("HabitatKit") and id in ["LOC-01", "LOC-02", "LOC-03", "LOC-04"]:
			var kit_batches := room.visual_root.get_node("HabitatKit").find_children("*", "MultiMeshInstance3D", false, false)
			_check(not kit_batches.is_empty() and kit_batches.all(func(b): return (b as GeometryInstance3D).cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF), id + " boundary kit batches cast no outer omni shadows (M1-94)")
			_check(kit_batches.any(func(b): return String(b.name).contains("_Q00_LOD0") and (b as Node3D).position.length() > 1.0), id + " large shell batches are quadrant-chunked around their centroids (M1-94)")
		if OS.get_cmdline_user_args().has("--capture-m1-94") and id in ["LOC-01", "LOC-02", "LOC-03", "LOC-04"]:
			root.size = Vector2i(1920, 1080)
			var cam := Camera3D.new()
			cam.fov = 58.0
			room.add_child(cam)
			var ext := Vector2(float(layout.bounds_m[0]), float(layout.bounds_m[1]))
			cam.position = Vector3(0.0, 2.05, ext.y * 0.38)
			cam.look_at(Vector3(0.0, 1.05, -ext.y * 0.28), Vector3.UP)
			cam.current = true
			for f in 24:
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/M1-94_" + id + ".png"))
			cam.free()
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
	var autoplay := CampaignCutscenePlayer.autoplay
	CampaignCutscenePlayer.autoplay = false
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
	CampaignCutscenePlayer.autoplay = autoplay
	# M1-76: Compatibility gets cube shadows (the only omni mode OpenGL supports); Forward+ and Mobile keep dual-paraboloid
	_check(RoomPresentation.omni_shadow_mode_for("gl_compatibility") == OmniLight3D.SHADOW_CUBE, "Compatibility renderer uses supported cube shadows")
	_check(RoomPresentation.omni_shadow_mode_for("forward_plus") == OmniLight3D.SHADOW_DUAL_PARABOLOID and RoomPresentation.omni_shadow_mode_for("mobile") == OmniLight3D.SHADOW_DUAL_PARABOLOID, "Forward+ and Mobile keep the dual-paraboloid saving")
	# M1-94: a hidden Node3D's WorldEnvironment (TitleStage during the campaign) is suspended while hidden and restored when shown
	var fake_stage := Node3D.new()
	var fake_world_env := WorldEnvironment.new()
	var fake_env := Environment.new()
	fake_env.ssao_enabled = true
	fake_world_env.environment = fake_env
	fake_stage.add_child(fake_world_env)
	root.add_child(fake_stage)
	fake_stage.hide()
	var test_room := Room.new()
	test_room.room_id = "LOC-01"
	test_room.load_approved_assets = false
	root.add_child(test_room)
	_check(fake_world_env.environment == null, "hidden TitleStage WorldEnvironment is suspended when CampaignRoom enters tree (M1-94)")
	fake_stage.show()
	_check(fake_world_env.environment == fake_env, "showing TitleStage restores its WorldEnvironment (M1-94)")
	test_room.free()
	fake_stage.free()
	print("ROOM PRESENTATION RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL " + message)
