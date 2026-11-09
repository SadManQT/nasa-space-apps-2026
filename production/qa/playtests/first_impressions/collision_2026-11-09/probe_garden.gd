extends SceneTree

const Room = preload("res://scripts/world/campaign_room.gd")
const Player = preload("res://scenes/player/player.tscn")
var room: CampaignRoom
var player: CharacterBody3D
var grid: Array = []
var motions: Array = []
var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	room = Room.new()
	room.room_id = "LOC-03"
	room.build_navigation = false
	root.add_child(room)
	room.set_scene_context("EX-CH01-S11")
	player = Player.instantiate() as CharacterBody3D
	player.set_script(null)
	player.get_node("FollowCamera").free()
	root.add_child(player)
	await physics_frame
	await physics_frame
	var capsule := player.get_node("CollisionShape3D") as CollisionShape3D
	_check(capsule.shape is CapsuleShape3D and is_equal_approx(capsule.shape.radius, 0.27), "production player capsule")
	for xi in range(38):
		for zi in range(51):
			var at := Vector3(-5.5 + xi * 0.1, 0.04, -3.5 + zi * 0.1)
			var hits := _occupancy(at)
			grid.append({"x": at.x, "z": at.z, "hits": hits})
	await _motion("direct_to_center_west", Vector3(-4.4, 0.04, -2.2), [Vector3(0, 0.04, 0.5)])
	await _motion("west_then_front_return", Vector3(-4.4, 0.04, -2.2), [Vector3(-4.4, 0.04, -0.5), Vector3(0, 0.04, -0.5), Vector3(0, 0.04, 0.5)])
	await _motion("west_lane_toward_crop_rack", Vector3(-4.4, 0.04, -2.2), [Vector3(-4.4, 0.04, 1.0)])
	await _motion("archive_to_north", Vector3(-4.4, 0.04, -2.2), [Vector3(-4.4, 0.04, -3.4)])
	await _motion("direct_to_center_corner", Vector3(-4.2, 0.04, -2.3), [Vector3(0, 0.04, 0.5)])
	var colliders: Array = []
	for body in room.find_children("*", "StaticBody3D", true, false):
		for shape in body.find_children("*", "CollisionShape3D", true, false):
			if shape.shape is BoxShape3D and shape.global_position.x < -1.5:
				colliders.append({"path": String(body.get_path()), "position": _v(shape.global_position), "size": _v(shape.shape.size), "disabled": shape.disabled})
	var visuals: Array = []
	for id in ["tara_bench", "tara_enclosure", "seed_archive", "PL_CropRack"]:
		var node := room.visual_root.get_node_or_null(id) as Node3D
		if node != null:
			var bounds := _visible_bounds(node)
			visuals.append({"id": id, "min": _v(bounds.position), "max": _v(bounds.end), "size": _v(bounds.size)})
	var out := OS.get_environment("TEST_LOG_DIR")
	var f := FileAccess.open(out.path_join("garden_probe.json"), FileAccess.WRITE)
	_check(f != null, "write diagnostic")
	if f != null:
		f.store_string(JSON.stringify({"method": "bare production capsule, actual LOC-03 static collision; candidate starts, not recorded player coordinates", "radius_m": capsule.shape.radius, "height_m": capsule.shape.height, "grid": grid, "motions": motions, "colliders": colliders, "visuals": visuals, "checks": checks, "failures": failures}, " "))
		f.close()
	player.free()
	room.free()
	await process_frame
	print("GARDEN COLLISION DIAGNOSTIC RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _occupancy(at: Vector3) -> Array:
	var capsule := player.get_node("CollisionShape3D") as CollisionShape3D
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = capsule.shape
	q.transform = Transform3D(Basis.IDENTITY, at) * capsule.transform
	q.collision_mask = 1
	q.exclude = [player.get_rid()]
	var hits: Array = []
	for hit in room.get_world_3d().direct_space_state.intersect_shape(q, 16):
		hits.append(String(hit.collider.get_path()))
	hits.sort()
	return hits

func _motion(id: String, start: Vector3, goals: Array) -> void:
	player.position = start
	await physics_frame
	var at_start := _occupancy(start)
	var route: Array = []
	for raw_goal in goals:
		var goal: Vector3 = raw_goal
		var contacts: Array = []
		for step in range(240):
			var delta := goal - player.position
			delta.y = 0
			if delta.length() < 0.02:
				break
			var hit := player.move_and_collide(delta.normalized() * minf(0.04, delta.length()))
			if hit != null:
				contacts.append({"path": String(hit.get_collider().get_path()), "point": _v(hit.get_position()), "normal": _v(hit.get_normal())})
				break
			await physics_frame
		route.append({"goal": _v(goal), "end": _v(player.position), "reached": player.position.distance_to(goal) < 0.03, "contacts": contacts})
		if not contacts.is_empty():
			break
	motions.append({"id": id, "start": _v(start), "start_overlaps": at_start, "route": route})

func _v(v: Vector3) -> Array:
	return [v.x, v.y, v.z]

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func _visible_bounds(node: Node3D) -> AABB:
	var bounds := AABB()
	var first := true
	var meshes := node.find_children("*", "MeshInstance3D", true, false)
	if node is MeshInstance3D:
		meshes.append(node)
	for mesh in meshes:
		if not mesh.is_visible_in_tree() or mesh.visibility_range_begin > 0 or "SelectionFrame" in String(mesh.get_path()):
			continue
		var box: AABB = mesh.global_transform * mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	return bounds
