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
