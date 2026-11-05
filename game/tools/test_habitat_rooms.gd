## M1-06: actual imported rooms, player capsule traversal, portals and obstacle-aware paths.
## --capture also writes the windowed review views and a measured frame-time report.
extends SceneTree

const Contract = preload("res://scripts/world/room_contract.gd")
const Presentation = preload("res://scripts/world/room_presentation.gd")
const Player = preload("res://scenes/player/player.tscn")
const SCENES := ["commons", "service_rooms", "garden", "safe_room"]
var checks := 0
var failures := 0
var report: Array[String] = []
var capture := false

func _init() -> void:
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL ", message)

func _run() -> void:
	capture = OS.get_cmdline_user_args().has("--capture")
	root.size = Vector2i(1600, 900)
	if capture:
		root.always_on_top = true
		root.grab_focus()
	var player := Player.instantiate() as PlayerController
	player.character_glb = "res://assets/characters/CH_Kai/CH_Kai.glb"
	player.controlled = false
	(player.get_node("FollowCamera") as FollowCamera).capture_mouse = false
	root.add_child(player)
	player.set_physics_process(false)
	for index in SCENES.size():
		var id := "LOC-%02d" % (index + 1)
		var room := (load("res://scenes/campaign/rooms/%s.tscn" % SCENES[index]) as PackedScene).instantiate() as CampaignRoom
		# Match the production loading-card path, including delayed prop binding.
		room.load_approved_assets = false
		root.add_child(room)
		room.load_approved_assets = true
		await room.load_assets_incremental()
		var child_count := room.visual_root.get_child_count()
		await room.load_assets_incremental()
		_check(room.visual_root.get_child_count() == child_count, id + " duplicate incremental load does not duplicate props or selection frames")
		var layout := Contract.layout(id)
		await physics_frame
		await physics_frame
		_check(room.build_room().get("duplicate", false), id + " rebuild is idempotent")
		_check(room.visual_root.has_node("HabitatKit"), id + " uses approved modular architecture")
		_check(room.visual_root.get_node("HabitatKit").get_child_count() < 240, id + " repeating geometry is batched")
		for anchor in room.anchor_root.get_children():
			_check(absf(anchor.position.y) < 0.001 or String(anchor.name).ends_with("viewpoint"), id + " grounded crew anchor " + String(anchor.name))
		var region := room.navigation_root.get_node("NavigationRegion") as NavigationRegion3D
		var map := region.get_navigation_map()
		NavigationServer3D.map_force_update(map)
		print(id, " NAV polygons=", region.navigation_mesh.get_polygon_count(), " regions=", NavigationServer3D.map_get_regions(map).size(), " closest=", NavigationServer3D.map_get_closest_point(map, Vector3(0, 0, 1)))
		var spawn := Vector3(layout.walk_probe[0][0], 0, layout.walk_probe[0][1])
		_check(NavigationServer3D.map_get_closest_point(map, spawn).distance_to(spawn) < 0.4, id + " spawn lies on navigation")
		for point in layout.walk_probe:
			var goal := Vector3(point[0], 0, point[1])
			var path := NavigationServer3D.map_get_path(map, spawn, goal, true)
			_check(path.size() > 0 and path[path.size() - 1].distance_to(goal) < 0.4, id + " obstacle-aware path reaches " + str(goal))
		for target in layout.focus_targets:
			var approach := Presentation.vector(target.approach_m)
			var point := Presentation.vector(target.position)
			var path := NavigationServer3D.map_get_path(map, spawn, approach, true)
			_check(not path.is_empty() and path[path.size() - 1].distance_to(approach) < 0.4, id + " reachable approach " + String(target.target_id))
			_check(_ray(approach + Vector3.UP * 1.4, point).is_empty(), id + " interaction line of sight " + String(target.target_id))
		await _walk(room, player, layout)
		await _portals(room)
		for obstacle in layout.obstacles:
			var at := Presentation.vector(obstacle.position)
			var size := Presentation.vector(obstacle.size)
			var start := at + Vector3(size.x * 0.5 + 0.15, 0, 0)
			_check(not _ray(start, at).is_empty(), id + " large prop blocks movement: " + String(obstacle.id))
		for side in [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
			var extent := float(layout.bounds_m[0]) * 0.5 if side.x != 0 else float(layout.bounds_m[1]) * 0.5
			var edge: Vector3 = side * extent + Vector3(0, 2.5, 0)
			_check(not _ray(edge - side * 0.4, edge + side * 0.4).is_empty(), id + " perimeter remains solid " + str(side))
		_check_signs(room, map)
		_check_prop_support(room, layout)
		_check_door_approaches(room, map, spawn)
		if id == "LOC-01":
			var mugs := room.visual_root.get_children().filter(func(n): return String(n.name) == "PR_Mug" or String(n.name).begins_with("commons_mug_"))
			_check(mugs.size() == 4, "Chapter 1 table has four mugs")
		if id == "LOC-04":
			var seats := room.visual_root.get_children().filter(func(n): return String(n.name) == "PR_CrewSeat" or String(n.name).begins_with("shelter_seat_"))
			_check(seats.size() == 5, "shelter has five installed seats")
		if id == "LOC-03":
			room.apply_plant_state([{"individual_id": "ALO-01", "stage": "bud"}, {"individual_id": "TARA-01", "stage": "bud"}])
			room.set_door_open("garden_viewing_shutter", false)
			_check(room.visual_root.get_node("shutter").visible, "viewing shutter closes")
			room.set_door_open("garden_viewing_shutter", true)
			_check(not room.visual_root.get_node("shutter").visible and room.visual_root.get_node("alo_pressure_glazing").visible, "opening shutter retains the sealed pressure pane")
		if capture:
			await _capture(room, player, layout)
		room.free()
		await process_frame
	player.free()
	if capture:
		await _capture_campaign()
	var line := "HABITAT ROOMS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures]
	print(line)
	report.append(line)
	if capture:
		var file := FileAccess.open("res://../production/qa/evidence/M1-06_runtime.txt", FileAccess.WRITE)
		file.store_string("\n".join(report) + "\n")
	quit(0 if failures == 0 else 1)

## Every fixed sign is single-sided and its readable side (a Label3D reads along +Z) faces walkable
## deck, while its back faces a wall or the object it labels, so no player sees mirrored text.
func _check_signs(room: CampaignRoom, map: RID) -> void:
	for label in room.find_children("*", "Label3D", true, false):
		if label.billboard != BaseMaterial3D.BILLBOARD_DISABLED:
			continue
		var facing: Vector3 = label.global_basis.z
		facing.y = 0
		facing = facing.normalized() * 0.8
		var at: Vector3 = label.global_position
		at.y = 0
		# A low rail or bench may sit under a wall sign, so the readable side may reach the deck within 1.6 m.
		var front := 99.0
		for reach in [1.0, 1.5, 2.0]:
			var probe: Vector3 = at + facing * reach
			front = minf(front, NavigationServer3D.map_get_closest_point(map, probe).distance_to(probe))
		var back := NavigationServer3D.map_get_closest_point(map, at - facing).distance_to(at - facing)
		_check(front < 0.35 and front < back and not label.double_sided, room.room_id + " sign reads from the walkable side, never mirrored: " + label.text)

## No floating, sunken or wall-piercing props: each authored prop's real mesh bounds rest on the deck
## or on the top of another authored surface (fixture or prop) and stay inside the room footprint.
func _check_prop_support(room: CampaignRoom, layout: Dictionary) -> void:
	var bounds := {}
	for node in room.visual_root.get_children():
		if node is Node3D and node.visible:
			var box := _mesh_bounds(room, node)
			if box.size != Vector3.ZERO:
				bounds[String(node.name)] = box
	var half := Vector2(float(layout.bounds_m[0]), float(layout.bounds_m[1])) * 0.5
	for prop in layout.props:
		var id := String(prop.id)
		if not bounds.has(id):
			continue
		var box: AABB = bounds[id]
		_check(box.position.x >= -half.x - 0.02 and box.end.x <= half.x + 0.02 and box.position.z >= -half.y - 0.02 and box.end.z <= half.y + 0.02, room.room_id + " prop inside the room footprint: " + id)
		var base := box.position.y
		var supported := absf(base) < 0.03
		var centre := box.get_center()
		for other in bounds:
			var surface: AABB = bounds[other]
			if other == id or surface.end.y > base + 0.03 or surface.end.y < base - 0.04:
				continue
			if centre.x >= surface.position.x and centre.x <= surface.end.x and centre.z >= surface.position.z and centre.z <= surface.end.z:
				supported = true
		_check(supported and base > -0.03, room.room_id + " prop rests on the deck or a surface (base %.3f m): %s" % [base, id])
		# Large floor-standing equipment needs collision over its whole footprint (10 cm trim allowance),
		# so the player capsule cannot walk into its visible mesh.
		if absf(base) < 0.03 and box.size.y >= 0.5:
			var covered := true
			for u in 5:
				for v in 5:
					var point := Vector3(lerpf(box.position.x + 0.1, box.end.x - 0.1, u / 4.0), 0.3, lerpf(box.position.z + 0.1, box.end.z - 0.1, v / 4.0))
					var inside := false
					for obstacle in layout.obstacles:
						var area := AABB(Presentation.vector(obstacle.position) - Presentation.vector(obstacle.size) * 0.5, Presentation.vector(obstacle.size))
						inside = inside or (point.x >= area.position.x and point.x <= area.end.x and point.z >= area.position.z and point.z <= area.end.z)
					covered = covered and inside
			_check(covered, room.room_id + " large prop footprint has collision: " + id)

## Doc 09 clearances: a 1.2 m door opening needs a 1 m interact approach on the navigation mesh,
## reachable from the room's spawn.
func _check_door_approaches(room: CampaignRoom, map: RID, spawn: Vector3) -> void:
	for node in room.door_root.get_children():
		if not node is CampaignDoor or String(node.boundary_id) == "garden_viewing_shutter":
			continue
		var inward: Vector3 = -node.global_basis.z
		inward.y = 0
		var approach: Vector3 = node.global_position + inward.normalized() * 1.0
		approach.y = 0
		var path := NavigationServer3D.map_get_path(map, spawn, approach, true)
		_check(not path.is_empty() and path[path.size() - 1].distance_to(approach) < 0.2, room.room_id + " 1 m door approach is clear and reachable: " + String(node.boundary_id))

func _mesh_bounds(room: CampaignRoom, node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	var meshes := node.find_children("*", "MeshInstance3D", true, false)
	if node is MeshInstance3D:
		meshes.append(node)
	for mesh in meshes:
		# Skip far LODs and hidden helpers such as the selection frame.
		if (mesh as GeometryInstance3D).visibility_range_begin > 0.0 or not mesh.is_visible_in_tree():
			continue
		var local: AABB = room.global_transform.affine_inverse() * mesh.global_transform * mesh.get_aabb()
		box = local if first else box.merge(local)
		first = false
	return box

func _ray(from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	return root.get_world_3d().direct_space_state.intersect_ray(query)

func _walk(room: CampaignRoom, player: PlayerController, layout: Dictionary) -> void:
	player.position = Vector3(layout.walk_probe[0][0], 0.04, layout.walk_probe[0][1])
	player.velocity = Vector3.ZERO
	for point in layout.walk_probe:
		var goal := Vector3(point[0], 0, point[1])
		for step in 700:
			var delta := goal - player.position
			delta.y = 0
			if delta.length() < 0.09:
				break
			player.velocity = delta.normalized() * 3.0 + Vector3.DOWN
			player.move_and_slide()
			await physics_frame
		_check(Vector2(player.position.x - goal.x, player.position.z - goal.z).length() < 0.12, room.room_id + " player walks unobstructed to " + str(goal))
		_check(absf(player.position.y) < 0.06, room.room_id + " player stays on deck")
	player.velocity = Vector3.ZERO
	player.follow_camera.reset_placement()
	report.append(room.room_id + ": scripted PlayerController walk, floor contact and wall/prop/door collision probes executed.")

func _portals(room: CampaignRoom) -> void:
	for node in room.door_root.get_children():
		if not node is CampaignDoor or String(node.boundary_id) == "garden_viewing_shutter":
			continue
		var normal: Vector3 = node.global_basis.z
		var from: Vector3 = node.global_position - normal * 0.5
		var to: Vector3 = node.global_position + normal * 0.5
		room.set_door_open(node.boundary_id, false)
		await physics_frame
		await physics_frame
		_check(not _ray(from, to).is_empty(), room.room_id + " closed pressure door blocks: " + node.boundary_id)
		room.set_door_open(node.boundary_id, true)
		await physics_frame
		await physics_frame
		_check(_ray(from, to).is_empty(), room.room_id + " open door has no invisible wall: " + node.boundary_id)
		room.set_door_open(node.boundary_id, true)
		_check(not node.closed, room.room_id + " duplicate open preserves state")
		room.set_door_open(node.boundary_id, String(node.boundary_id).begins_with("door_"))

func _capture(room: CampaignRoom, player: PlayerController, layout: Dictionary) -> void:
	var camera := Camera3D.new()
	camera.fov = 75
	root.add_child(camera)
	player.hide()
	if room.room_id == "LOC-03":
		# Review both canonical plants on screen: Alo blooms 27 Apr and Tara 30 Apr 2046.
		room.apply_plant_state([{"individual_id": "ALO-01", "stage": "bloom"}, {"individual_id": "TARA-01", "stage": "bloom"}])
	for view_id in layout.review_views:
		var view: Dictionary = layout.review_views[view_id]
		camera.position = Presentation.vector(view.from)
		camera.look_at(Presentation.vector(view.to))
		camera.current = true
		for frame in 20:
			await process_frame
		await RenderingServer.frame_post_draw
		await _save(room.room_id + "_" + String(view_id))
		if room.room_id == "LOC-03" and view_id == "chamber":
			room.set_door_open("garden_viewing_shutter", false)
			await process_frame
			await RenderingServer.frame_post_draw
			await _save(room.room_id + "_chamber_closed")
			room.set_door_open("garden_viewing_shutter", true)
	player.show()
	var player_anchor: Array = layout.anchors[{"LOC-01":"commons_player", "LOC-02":"service_player", "LOC-03":"garden_player", "LOC-04":"safe_player"}[room.room_id]]
	player.position = Presentation.vector(player_anchor)
	player.follow_camera.yaw = 0
	player.follow_camera.pitch = -0.12
	player.follow_camera.reset_placement()
	player.follow_camera.camera.current = true
	for frame in 30:
		player.follow_camera.update_camera(1.0 / 60.0, PI, 0)
		await process_frame
	await RenderingServer.frame_post_draw
	await _save(room.room_id + "_player")
	# Time the steady state, after first-use shader compiles for this room have settled.
	for frame in 90:
		await process_frame
	var samples: Array[float] = []
	var previous := Time.get_ticks_usec()
	for frame in 180:
		await process_frame
		var now := Time.get_ticks_usec()
		samples.append((now - previous) / 1000.0)
		previous = now
	samples.sort()
	report.append("%s windowed frame ms: p50=%.2f p95=%.2f; draw calls=%d objects=%d" % [room.room_id, samples[90], samples[171], Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)])
	camera.free()

## Saves the presented frame; the first frames after a shader compile can still be black on Metal,
## so a blank frame is re-read for up to two seconds and a still-blank capture fails the run.
func _save(id: String) -> void:
	var path := "res://../production/qa/evidence/M1-06_%s.png" % id
	var image := root.get_texture().get_image()
	for attempt in 120:
		if not _blank(image):
			break
		await process_frame
		await RenderingServer.frame_post_draw
		image = root.get_texture().get_image()
	_check(not _blank(image), "capture " + id + " shows a rendered frame")
	_check(image.save_png(ProjectSettings.globalize_path(path)) == OK, "capture " + id)

func _blank(image: Image) -> bool:
	var brightest := 0.0
	for gx in 16:
		for gy in 9:
			var c := image.get_pixel(int((gx + 0.5) * image.get_width() / 16.0), int((gy + 0.5) * image.get_height() / 9.0))
			brightest = maxf(brightest, c.get_luminance())
	return brightest < 0.03

func _capture_campaign() -> void:
	var storage = preload("res://tools/support/isolated_storage.gd").new()
	if not storage.setup("M1-06-capture"):
		_check(false, "isolate production capture saves")
		return
	var autoplay := CampaignCutscenePlayer.autoplay
	CampaignCutscenePlayer.autoplay = false
	var campaign := load("res://scenes/campaign/chapter1_campaign.tscn").instantiate() as Chapter1Campaign
	storage.configure(campaign)
	root.add_child(campaign)
	for frame in 30:
		await physics_frame
	_check(campaign._player != null and campaign._room != null, "real campaign caller instantiates the room and cast")
	await RenderingServer.frame_post_draw
	await _save("campaign")
	# Let first-use shader compiles and the HUD intro settle before timing the steady state.
	for frame in 120:
		await process_frame
	var samples: Array[float] = []
	var previous := Time.get_ticks_usec()
	for frame in 180:
		await process_frame
		var now := Time.get_ticks_usec()
		samples.append((now - previous) / 1000.0)
		previous = now
	samples.sort()
	report.append("Campaign with HUD/cast frame ms (after 2 s settle): p50=%.2f p95=%.2f; draw calls=%d" % [samples[90], samples[171], Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])
	campaign.free()
	storage.cleanup()
	CampaignCutscenePlayer.autoplay = autoplay
