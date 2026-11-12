extends SceneTree

const Scene = preload("res://scenes/campaign/chapter1_campaign.tscn")
var storage = preload("res://tools/support/isolated_storage.gd").new()
var checks := 0
var failures := 0

func _init() -> void:
	CampaignCutscenePlayer.autoplay = false
	call_deferred("_run")

func _run() -> void:
	_check(storage.setup("hud_world_lifetime"), "isolated player storage")
	root.size = Vector2i(1280, 720)
	var campaign = Scene.instantiate()
	storage.configure(campaign)
	root.add_child(campaign)
	await process_frame
	var hud = campaign.hud
	var camera := Camera3D.new()
	campaign.add_child(camera)
	camera.position = Vector3(2, 1, 3)
	camera.rotation_degrees.y = 37
	camera.h_offset = 0.2
	camera.v_offset = 0.1
	camera.force_update_transform()
	camera.reset_physics_interpolation()
	await process_frame
	var projection_frame := camera.get_camera_transform()
	var view := Vector2(1280, 720)
	for x in [-2.0, 0.0, 2.0]:
		for depth in [-0.000001, 0.0, 0.000001]:
			var projected: Vector2 = hud._project(camera, projection_frame * Vector3(x, 0, depth), view, 24.0)
			_check(projected.is_finite() and Rect2(Vector2(24, 24), view - Vector2(47, 47)).has_point(projected), "camera-plane marker stays finite and within viewport")
			_check(is_equal_approx(projected.y, 696.0) and (is_equal_approx(projected.x, 640.0) if x == 0.0 else (projected.x < 640.0) == (x < 0.0)), "camera-plane marker preserves left/right direction")
	for depth in [-2.0, 2.0]:
		_check(hud._project(camera, projection_frame * Vector3(0.5, 0.2, depth), view, 24.0).is_finite(), "front and behind markers still project normally")
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	var orthographic: Vector2 = hud._project(camera, projection_frame.origin, view, 24.0)
	_check(orthographic.is_finite() and Rect2(Vector2(24, 24), view - Vector2(47, 47)).has_point(orthographic), "orthographic camera-plane projection stays finite and bounded")
	camera.free()
	var target: Node3D = campaign.physical_target("commission_route")
	var player: Node3D = campaign._player
	player.global_position = target.global_position + Vector3(3, 0, 4)
	_check(is_equal_approx(hud._distance_to(target), 5.0), "live world distance uses the real horizontal geometry")
	var parent: Node = target.get_parent()
	parent.remove_child(target)
	hud._marker_node = target
	hud._nearby_id = ""
	_check(hud._distance_to(target) < 0, "detached real target has no world distance")
	hud._update_world_overlay()
	_check(not hud._marker.visible, "detached real target never displays a stale world marker")
	parent.add_child(target)
	_check(is_equal_approx(hud._distance_to(target), 5.0), "reattached real target restores its distance")
	var focus_root: Node3D = campaign._room.focus_root
	var focus_parent: Node = focus_root.get_parent()
	focus_parent.remove_child(focus_root)
	hud._nearby_id = "commission_route"
	hud._update_world_overlay()
	_check(not hud._prompt.visible, "detached real focus-root child never displays a nearby prompt")
	focus_parent.add_child(focus_root)
	hud._nearby_id = ""
	parent = player.get_parent()
	parent.remove_child(player)
	_check(hud._distance_to(target) < 0, "detached real player has no world distance")
	hud._update_world_overlay()
	_check(not hud._marker.visible and not hud._prompt.visible, "no world overlays while the real player leaves the tree")
	parent.add_child(player)
	_check(is_equal_approx(hud._distance_to(target), 5.0), "reattached player restores valid geometry")
	for scene in ["EX-CH01-S02", "EX-CH01-S03"]:
		campaign.route.start_at(scene)
		campaign._sync_route_projection()
		campaign._refresh_world()
		await process_frame
		campaign.hud.refresh_scene()
		await process_frame
		_check(campaign._player.is_inside_tree() and campaign.hud._marker_node.is_inside_tree(), "real room rebuild restores live world references " + scene)
		_check(campaign.hud._distance_to(campaign.hud._marker_node) >= 0, "real rebuilt world distance is available " + scene)
	campaign.free()
	await process_frame
	storage.cleanup()
	print("HUD WORLD LIFETIME RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)
