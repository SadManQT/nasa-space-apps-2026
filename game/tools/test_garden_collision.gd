extends SceneTree

const Scene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const Fixture = preload("res://tools/support/chapter1_outcome_fixture.gd")
var storage = preload("res://tools/support/isolated_storage.gd").new()
var campaign: Chapter1Campaign
var room: CampaignRoom
var player: PlayerController
var checks := 0
var failures := 0
var motions: Array = []

func _init() -> void:
	CampaignCutscenePlayer.autoplay = false
	if not storage.setup("garden_collision") or (_capture_enabled() and not storage.prepare_rendering_cache()):
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var route: RefCounted = Fixture.play("BLOOM")
	var state: Dictionary = route.director().snapshot()
	state.merge({"scene_id": route.current_scene_id(), "mission_id": route.current_mission_id(), "completed_scene_ids": route.completed_scene_ids(), "route_runtime": route.snapshot().merged({"chapter": 1})}, true)
	campaign = Scene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	campaign.initial_snapshot = JSON.parse_string(JSON.stringify(state))
	root.add_child(campaign)
	await process_frame
	await physics_frame
	await physics_frame
	_check(campaign._startup_error.is_empty(), "production saved campaign restores: " + campaign._startup_error)
	if not campaign._startup_error.is_empty():
		_finish()
		return
	room = campaign._room
	player = campaign._player
	_check(campaign.route.current_scene_id() == "EX-CH01-S11" and room.room_id == "LOC-03", "real campaign activates reported garden scene")
	# Geometry assertions deliberately use the real body with automatic control
	# paused. Real steering/input belongs to the separate movement regression.
	player.set_physics_process(false)
	var capsule := player.get_node("CollisionShape3D") as CollisionShape3D
	_check(is_equal_approx(capsule.shape.radius, 0.27) and is_equal_approx(capsule.shape.height, 1.7), "production capsule dimensions unchanged")
	var flags: Dictionary = campaign.route.current_flags().duplicate(true)
	var resources: Dictionary = campaign.director.snapshot().resources.duplicate(true)
	var ray := PhysicsRayQueryParameters3D.create(Vector3(-4.4, 1.3, -1.5), Vector3(-3.8, 1.3, -1.5), 1)
	_check(room.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(), "empty air outside visible Tara enclosure stays clear")
	var enclosure := _ray(Vector3(-3.8, 1.3, -1.5), Vector3(-2.6, 1.3, -1.5))
	_check(not enclosure.is_empty() and String(enclosure.collider.name) == "tara_enclosure", "visible elevated Tara enclosure remains solid")
	_check(await _motion("rack_front_clearance", Vector3(-4.4, 0.04, -0.5), [Vector3(-4.4, 0.04, 0.3)]), "capsule reaches visible rack-front clearance")
	_check(not await _motion("bench_solid", Vector3(-3.2, 0.04, 0.5), [Vector3(-3.2, 0.04, -1.5)]) and _last_contact("tara_bay"), "visible Tara bench remains solid")
	_check(not await _motion("rack_solid", Vector3(-4.9, 0.04, 0), [Vector3(-4.9, 0.04, 1.3)]) and _last_contact("crop_rack"), "visible crop rack remains solid")
	_check(await _motion("return_lane", Vector3(-4.4, 0.04, -2.2), [Vector3(-4.4, 0.04, -0.5), Vector3(0, 0.04, -0.5), Vector3(0, 0.04, 0.5)]), "return lane around solid bench is physically clear")
	_check(not await _motion("diagonal_bench", Vector3(-4.4, 0.04, -2.2), [Vector3(0, 0.04, 0.5)]) and _last_contact("tara_bay"), "diagonal cannot bypass the actual bench")
	var region := room.navigation_root.get_node("NavigationRegion") as NavigationRegion3D
	var map := region.get_navigation_map()
	NavigationServer3D.map_force_update(map)
	for target in room._layout.focus_targets:
		var goal := Vector3(target.approach_m[0], 0, target.approach_m[2])
		var path := NavigationServer3D.map_get_path(map, Vector3(0, 0, 0.5), goal, true)
		_check(not path.is_empty() and path[-1].distance_to(goal) < 0.4, "generated navigation reaches " + String(target.target_id))
	for door in room.door_root.get_children():
		if not door is CampaignDoor or String(door.boundary_id) == "garden_viewing_shutter":
			continue
		var was_open: bool = not door.closed
		var normal: Vector3 = door.global_basis.z
		var from: Vector3 = door.global_position - normal * 0.5
		var to: Vector3 = door.global_position + normal * 0.5
		room.set_door_open(door.boundary_id, false)
		await physics_frame
		await physics_frame
		_check(not _ray(from, to).is_empty(), "closed pressure door stays solid " + String(door.boundary_id))
		room.set_door_open(door.boundary_id, true)
		await physics_frame
		await physics_frame
		_check(_ray(from, to).is_empty(), "opened pressure door has no invisible wall " + String(door.boundary_id))
		room.set_door_open(door.boundary_id, was_open)
	_check(campaign.route.current_flags() == flags and campaign.director.snapshot().resources == resources, "movement/collision checks do not complete mission gates or alter resources")
	await _capture("garden")
	_finish()

func _motion(id: String, start: Vector3, goals: Array) -> bool:
	player.global_position = start
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	await physics_frame
	var reached := true
	var legs: Array = []
	for raw in goals:
		var goal: Vector3 = raw
		var contacts: Array = []
		for step in range(240):
			var delta := goal - player.global_position
			delta.y = 0
			if delta.length() < 0.02:
				break
			var collision := player.move_and_collide(delta.normalized() * minf(0.04, delta.length()))
			if collision != null:
				contacts.append({"collider": String(collision.get_collider().get_path()), "normal": _v(collision.get_normal())})
				break
			await physics_frame
		var done := player.global_position.distance_to(goal) < 0.03
		legs.append({"goal": _v(goal), "end": _v(player.global_position), "reached": done, "contacts": contacts})
		if not done:
			reached = false
			break
	motions.append({"id": id, "start": _v(start), "legs": legs})
	return reached

func _last_contact(id: String) -> bool:
	var contacts: Array = motions[-1].legs[-1].contacts
	return contacts.any(func(value): return String(value.collider).ends_with("/" + id))

func _ray(from: Vector3, to: Vector3) -> Dictionary:
	return room.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, 1))

func _v(value: Vector3) -> Array:
	return [value.x, value.y, value.z]

func _capture_enabled() -> bool:
	return OS.get_cmdline_user_args().has("--capture")

func _capture(id: String) -> void:
	if not _capture_enabled():
		return
	var camera := Camera3D.new()
	room.add_child(camera)
	camera.global_position = Vector3(-5.75, 2.15, -0.2)
	camera.look_at(Vector3(-3.2, 0.8, -1.8))
	camera.current = true
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	var file := OS.get_environment("TEST_LOG_DIR").path_join("M1-122_" + id + ".png")
	_check(root.get_texture().get_image().save_png(file) == OK, "write integrated campaign capture")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func _finish() -> void:
	var out := OS.get_environment("TEST_LOG_DIR")
	if not out.is_empty():
		var file := FileAccess.open(out.path_join("collision_trace.json"), FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify({"checks": checks, "failures": failures, "motions": motions}, " "))
			file.close()
	if is_instance_valid(campaign):
		campaign.free()
	storage.cleanup()
	print("GARDEN COLLISION RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)
