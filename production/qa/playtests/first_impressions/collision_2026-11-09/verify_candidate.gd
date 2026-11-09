extends "probe_garden.gd"

const Habitat = preload("res://scripts/world/habitat_room_builder.gd")

func _run() -> void:
	var candidate := OS.get_cmdline_user_args().has("--candidate")
	room = Room.new()
	room.room_id = "LOC-03"
	room.build_navigation = false
	root.add_child(room)
	room.set_scene_context("EX-CH01-S11")
	if candidate:
		var bench := room.collision_root.get_node("tara_bay") as StaticBody3D
		bench.position.y = 0.4
		(bench.get_child(0).shape as BoxShape3D).size.y = 0.8
		Habitat.collider(room.collision_root, "tara_enclosure", Vector3(-3.2, 1.1, -1.5), Vector3(0.8, 0.8, 0.8))
		(room.collision_root.get_node("crop_rack").get_child(0).shape as BoxShape3D).size = Vector3(0.73, 2.01, 1.46)
	player = Player.instantiate() as CharacterBody3D
	player.set_script(null)
	player.get_node("FollowCamera").free()
	root.add_child(player)
	await physics_frame
	await physics_frame
	var capsule := player.get_node("CollisionShape3D") as CollisionShape3D
	_check(is_equal_approx(capsule.shape.radius, 0.27), "production capsule radius preserved")
	var ray := PhysicsRayQueryParameters3D.create(Vector3(-4.4, 1.3, -1.5), Vector3(-3.8, 1.3, -1.5), 1)
	_check(room.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(), "empty air outside Tara enclosure has no blocker")
	await _motion("visible_crop_front_clearance", Vector3(-4.4, 0.04, -0.5), [Vector3(-4.4, 0.04, 0.3)])
	_check(motions[-1].route[-1].reached, "capsule reaches visible rack-front clearance")
	await _motion("solid_bench", Vector3(-3.2, 0.04, 0.5), [Vector3(-3.2, 0.04, -1.5)])
	_check(not motions[-1].route[-1].reached and String(motions[-1].route[-1].contacts[0].path).ends_with("tara_bay"), "visible solid bench still blocks")
	await _motion("solid_rack", Vector3(-4.9, 0.04, 0), [Vector3(-4.9, 0.04, 1.3)])
	_check(not motions[-1].route[-1].reached and String(motions[-1].route[-1].contacts[0].path).ends_with("crop_rack"), "visible crop rack still blocks")
	await _motion("west_front_return", Vector3(-4.4, 0.04, -2.2), [Vector3(-4.4, 0.04, -0.5), Vector3(0, 0.04, -0.5), Vector3(0, 0.04, 0.5)])
	_check(motions[-1].route.all(func(leg): return leg.reached), "existing route around bench remains clear")
	var out := OS.get_environment("TEST_LOG_DIR")
	var file := FileAccess.open(out.path_join("candidate_trace.json"), FileAccess.WRITE)
	_check(file != null, "write candidate trace")
	if file != null:
		file.store_string(JSON.stringify({"candidate": candidate, "motions": motions, "checks": checks, "failures": failures}, " "))
		file.close()
	player.free()
	room.free()
	await process_frame
	print("GARDEN COLLISION CANDIDATE RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)
