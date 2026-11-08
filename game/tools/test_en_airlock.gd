## M3-2A: the Chapter 2 asset set loads, keeps the kit conventions and works as the LOC-05 double interlock.
## Headless: game/tools/run_tests.sh en_airlock
## Evidence (needs a window): Godot --path game --script res://tools/test_en_airlock.gd -- --evidence
extends SceneTree

const Kit = preload("res://assets/environment/kit/habitat_kit.gd")
const Airlock = preload("res://assets/environment/EN_Airlock/en_airlock.gd")
const EVIDENCE_DIR := "res://../production/qa/evidence/"
const CANON_STATES := ["SEALED", "EQUALISING", "SAFE TO OPEN"]  # 09_WORLD_AND_LEVEL_DESIGN.md LOC-05
var checks := 0
var failures := 0
var _drawn_frames := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		print("FAIL ", message)

func _run() -> void:
	var catalog := Airlock.catalog()
	_check(catalog.pieces.size() == 5, "five airlock pieces (suit locker, bench, glove port, pass-through, interlock panel)")
	_check(catalog.props.size() == 2, "two Chapter 2 props (paper bee, seed tray)")
	_check(catalog.interlock.states == CANON_STATES, "the interlock's words are the canonical SEALED / EQUALISING / SAFE TO OPEN")
	_check(float(catalog.interlock.equalise_seconds) > 0.0, "equalise time is a positive gameplay value in the data file")
	_check(catalog.vestibule.bounds_m == [8.0, 4.0], "the vestibule is the canonical 8 x 4 m (LOC-05)")
	for entry in catalog.pieces:
		_test_piece(entry)
	_test_props()
	_test_glove_port_window()
	_test_moving_parts()
	var airlock := await _test_vestibule()
	_test_interlock(airlock)
	await _test_hatch_physics(airlock)
	_test_pass_through(airlock)
	_test_save_restore(airlock)
	airlock.free()
	if OS.get_cmdline_user_args().has("--evidence"):
		await _evidence()
	print("EN_AIRLOCK RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_piece(entry: Dictionary) -> void:
	var id: String = entry.id
	_check(entry.lods.size() == 2 and entry.triangles.size() == 2, id + " has a game LOD and a Compatibility LOD")
	_check(int(entry.triangles[0]) <= 8000 and int(entry.triangles[1]) <= int(entry.triangles[0]), id + " within the 8k modular budget, LOD1 no heavier than LOD0")
	for path in entry.lods:
		_check(load(path) is PackedScene, "load " + String(path))
	var node := Airlock.instance(id)
	root.add_child(node)
	_check(node.get_node_or_null("LOD0") != null and node.get_node_or_null("LOD1") != null, id + " builds both LOD children")
	var box := Kit.bounds(node, 0)
	_check(absf(box.position.y) <= 0.01, id + " stands on the floor (lowest point y = 0)")
	var textured := 0
	var opaque := 0
	var max_tex := 0
	for mesh in (node.get_node("LOD0") as Node3D).find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.mesh.get_surface_count():
			var material := mesh.get_active_material(surface) as StandardMaterial3D
			if material == null:
				continue
			if material.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and not material.emission_enabled and not material.resource_name.begins_with("Screen") and not material.resource_name.begins_with("RoleTab"):
				opaque += 1
				if material.albedo_texture != null and material.normal_texture != null:
					textured += 1
			for texture in [material.albedo_texture, material.normal_texture, material.roughness_texture]:
				if texture != null:
					max_tex = maxi(max_tex, maxi(texture.get_width(), texture.get_height()))
	_check(opaque > 0 and textured == opaque, id + " every opaque surface carries the kit's shared albedo and normal maps (%d/%d)" % [textured, opaque])
	_check(max_tex in [512, 1024], id + " game LOD resolves the kit's shared sets through ../kit/textures (largest %d px)" % max_tex)
	var bodies := (node.get_node("LOD0") as Node3D).find_children("*", "StaticBody3D", true, false)
	_check(bodies.size() >= 1 and (node.get_node("LOD1") as Node3D).find_children("*", "StaticBody3D", true, false).is_empty(), id + " carries collision on the game LOD only")
	if entry.kind == "wall":
		_check(absf(box.size.x - 1.0) <= 0.01 and absf(box.size.y - 2.6) <= 0.01, id + " is a 1 m x 2.6 m wall module")
		_check(box.position.z <= 0.001 and box.end.z >= 0.149, id + " face on z = 0 with the body behind it")
	node.free()

func _test_props() -> void:
	var bee_entry := Airlock.prop("PR_PaperBee")
	var bee := (load(bee_entry.path) as PackedScene).instantiate() as Node3D
	root.add_child(bee)
	_check(bee.find_child("Socket_Grip", true, false) != null and bee.find_child("Socket_Rest", true, false) != null, "paper bee exposes Socket_Grip (held) and Socket_Rest (placed)")
	_check(bee.find_children("*", "Skeleton3D", true, false).is_empty() and bee.find_children("*", "AnimationPlayer", true, false).is_empty(), "paper bee is a plain folded prop: no rig, no baked animation")
	var bee_box := _bounds(bee)
	_check(bee_box.size.z > 0.07 and bee_box.size.z < 0.1 and bee_box.size.y < 0.05, "paper bee is palm-sized (about 9 cm long, under 5 cm tall)")
	_check(absf(bee_box.position.y) <= 0.002, "paper bee rests on its legs at y = 0")
	var names := PackedStringArray()
	for mesh in bee.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.mesh.get_surface_count():
			var material: Material = mesh.get_active_material(surface)
			if material != null and not names.has(material.resource_name):
				names.append(material.resource_name)
	_check(names.has("M_PaperGold") and names.has("M_PaperNavy") and names.has("M_PaperWhite"), "paper bee is gold duo paper with navy bands and white wings (materials %s)" % ", ".join(names))
	bee.free()
	var tray_entry := Airlock.prop("PR_SeedTray")
	var tray := (load(tray_entry.path) as PackedScene).instantiate() as Node3D
	root.add_child(tray)
	var tray_box := _bounds(tray)
	_check(absf(tray_box.size.x - 0.5) <= 0.01 and tray_box.size.y < 0.07, "seed tray is 0.50 m long like the 2034 seedling tray and under 7 cm tall")
	_check(absf(tray_box.position.y) <= 0.002, "seed tray stands on the floor")
	tray.free()

## M3-104: the glove-port window opens through the module as built. In both LODs, lines through the pane (its axis, and
## from a standing eye 0.85 m in front towards the four corners of the view) cross the glazing and no other face, and
## the far face is closed everywhere else: lines through the wall above, below and beside the window, behind both ports
## and through the frame's four rounded corners meet it at z = 0.15.
func _test_glove_port_window() -> void:
	var node := Airlock.instance("EN_Airlock_GlovePort")
	root.add_child(node)
	var sockets: Dictionary = Airlock.piece("EN_Airlock_GlovePort").sockets
	var centre := Vector3(sockets.window_centre[0], sockets.window_centre[1], 0.0)
	var half := Vector2(sockets.window_size[0], sockets.window_size[1]) * 0.5
	var eye := Vector3(0.0, 1.6, -0.85)
	var through: Array = [[centre + Vector3(0, 0, -0.4), centre + Vector3(0, 0, 0.6)]]
	for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var aim := centre + Vector3(corner.x * half.x * 0.7, corner.y * half.y * 0.7, 0.03)
		through.append([eye, eye + (aim - eye) * (0.6 - eye.z) / (aim.z - eye.z)])
	var closed: Array[Vector2] = [Vector2(0, 0.6), Vector2(0, 2.3), Vector2(-0.43, centre.y), Vector2(0.43, centre.y)]
	for port in sockets.ports:
		closed.append(Vector2(port[0], port[1]))
	for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		closed.append(Vector2(corner.x * 0.35, centre.y + corner.y * 0.28))  # outside the frame's 0.18 m corner arcs, inside its box
	for lod in ["LOD0", "LOD1"]:
		var part := node.get_node(lod) as Node3D
		var clear := true
		for line in through:
			var crossed := _crossings(node, part, line[0], line[1])
			clear = clear and not crossed.is_empty()
			for hit in crossed:
				clear = clear and bool(hit.glass)
		_check(clear, "EN_Airlock_GlovePort %s: lines through the pressure window cross its pane and nothing else (the window opens through the module)" % lod)
		var sealed := true
		for at in closed:
			var back := false
			for hit in _crossings(node, part, Vector3(at.x, at.y, 0.10), Vector3(at.x, at.y, 0.20)):
				back = back or (not bool(hit.glass) and absf(float(hit.z) - 0.15) < 0.005)
			sealed = sealed and back
		_check(sealed, "EN_Airlock_GlovePort %s: the far face is closed at z = 0.15 everywhere but the window" % lod)
		var glazing := 0
		for mesh in part.find_children("*", "MeshInstance3D", true, false):
			for surface in (mesh as MeshInstance3D).mesh.get_surface_count():
				var material := (mesh as MeshInstance3D).get_active_material(surface) as StandardMaterial3D
				if material != null and material.resource_name.begins_with("M_Airlock_PressureGlass"):
					glazing += 1
					_check(material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED and material.roughness > 0.1, "EN_Airlock_GlovePort %s pane is clear glazing with softened reflections (roughness %.2f)" % [lod, material.roughness])
		_check(glazing == 1, "EN_Airlock_GlovePort %s has one pressure-glazing surface" % lod)
	node.free()

## Every face of the meshes under part that the segment from -> to (in the piece's frame) crosses, as
## {"glass": the face is pressure glazing, "z": the crossing's z in the piece's frame}.
func _crossings(piece: Node3D, part: Node3D, from: Vector3, to: Vector3) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for child in part.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		var to_mesh := mesh.global_transform.affine_inverse() * piece.global_transform
		var to_piece := piece.global_transform.affine_inverse() * mesh.global_transform
		var a := to_mesh * from
		var b := to_mesh * to
		for surface in mesh.mesh.get_surface_count():
			var material := mesh.get_active_material(surface)
			var glass: bool = material != null and material.resource_name.begins_with("M_Airlock_PressureGlass")
			var arrays := mesh.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			for t in indices.size() / 3:
				var hit: Variant = Geometry3D.segment_intersects_triangle(a, b, vertices[indices[t * 3]], vertices[indices[t * 3 + 1]], vertices[indices[t * 3 + 2]])
				if hit != null:
					out.append({"glass": glass, "z": (to_piece * (hit as Vector3)).z})
	return out

func _test_moving_parts() -> void:
	var pt := Airlock.instance("EN_Airlock_PassThrough")
	root.add_child(pt)
	for lid in ["LidA", "LidB"]:
		var leaves := pt.find_children(lid, "Node3D", true, false)
		_check(leaves.size() == 2, lid + " node in both LODs of the pass-through")
		_check((leaves[0] as Node3D).find_children("*", "StaticBody3D", true, false).size() == 1, lid + " carries its own collision so it moves with the lid")
	var sockets: Dictionary = Airlock.piece("EN_Airlock_PassThrough").sockets
	var lid_a := pt.find_children("LidA", "Node3D", true, false)[0] as Node3D
	var closed := _subtree_bounds(lid_a, pt)
	_check(closed.position.z < -0.42 and absf(closed.get_center().x) < 0.03, "closed room-side lid covers the chamber mouth in front of the seal frame")
	lid_a.rotation_degrees.y = float(sockets.lids.LidA.open_rotation_deg_y)
	var opened := _subtree_bounds(lid_a, pt)
	_check(opened.position.z < -0.9 and opened.end.x < 0.0, "open room-side lid swings into the room (-Z) beside its left hinge")
	lid_a.rotation_degrees.y = 0.0
	var lid_b := pt.find_children("LidB", "Node3D", true, false)[0] as Node3D
	lid_b.rotation_degrees.y = float(sockets.lids.LidB.open_rotation_deg_y)
	var opened_b := _subtree_bounds(lid_b, pt)
	_check(opened_b.end.z > 0.6 and opened_b.position.x > 0.0, "open far-side lid swings away from the room (+Z) beside its right hinge")
	lid_b.rotation_degrees.y = 0.0
	var carrier := Vector3(sockets.carrier_socket[0], sockets.carrier_socket[1], sockets.carrier_socket[2])
	_check(carrier.y > 1.0 and carrier.z < 0.0 and carrier.z > -0.42, "carrier socket sits inside the chamber at bench height")
	pt.free()
	var panel := Airlock.instance("EN_Airlock_InterlockPanel")
	root.add_child(panel)
	_check(Kit.screen_surfaces(panel).size() == 2, "interlock panel exposes one 'Screen' surface per LOD for the live words")
	for lamp in ["LampSealed", "LampEqualising", "LampSafe"]:
		_check(Airlock.surfaces_named(panel, lamp).size() == 2, "interlock panel has the %s lamp in both LODs" % lamp)
	_check(panel.find_children("CycleLever", "Node3D", true, false).size() == 2, "cycle lever is a pivoted child in both LODs")
	panel.free()
	var locker := Airlock.instance("EN_Airlock_SuitLocker")
	root.add_child(locker)
	_check(Airlock.surfaces_named(locker, "RoleTab").size() == 2, "suit locker exposes the RoleTab slot in both LODs")
	locker.free()

func _test_vestibule() -> Node3D:
	var airlock := Airlock.new()
	airlock.build_on_ready = false
	airlock.with_lights = false
	root.add_child(airlock)
	var result: Dictionary = airlock.build()
	_check(result.accepted and int(result.placements) > 60, "vestibule assembled from airlock.json (%d placements)" % int(result.placements))
	_check(airlock.build().get("duplicate", false), "a second build call is a no-op (duplicate), not a second room")
	for role in ["inner_door", "inner_hatch", "outer_hatch", "vestibule_panel", "chamber_panel", "pass_through", "glove_ports", "bench", "locker_kai", "locker_amara", "locker_mei", "locker_rafi", "locker_ferreira"]:
		_check(airlock.nodes.has(role), "role placed: " + role)
	var colours := {}
	for cadet in Airlock.catalog().cadets:
		colours[String(cadet.name).to_lower()] = Color(String(cadet.role_colour))
	for name in colours:
		var locker: Node3D = airlock.nodes["locker_" + name]
		var tab := Airlock.surfaces_named(locker.get_node("LOD0"), "RoleTab")
		var ok := tab.size() == 1 and (tab[0].material as StandardMaterial3D).albedo_color.is_equal_approx(colours[name])
		_check(ok, name.capitalize() + "'s locker tab carries the role colour from ART_BIBLE section 3")
	await process_frame
	await physics_frame
	await physics_frame
	var space := root.get_world_3d().direct_space_state
	var floor_ok := true
	for p in [Vector3(0.5, 1, 0.5), Vector3(2.5, 1, 2.5), Vector3(4.9, 1, 3.9), Vector3(6.5, 1, 2.0), Vector3(7.9, 1, 0.1)]:
		var hit := _ray(space, p, Vector3(p.x, -1, p.z))
		floor_ok = floor_ok and not hit.is_empty() and absf(hit.position.y) <= 0.01
	_check(floor_ok, "the floor collides at y = 0 across the vestibule and the chamber")
	var west := _ray(space, Vector3(2.5, 1.0, 2.0), Vector3(-2.0, 1.0, 2.0))
	_check(not west.is_empty() and west.position.x > -0.2 and west.position.x < 0.1, "the closed inner door (to LOC-01) blocks the west end")
	var south := _ray(space, Vector3(2.5, 1.5, 2.0), Vector3(2.5, 1.5, -2.0))
	_check(not south.is_empty() and south.position.z > -0.01 and south.position.z < 0.65, "the near wall (or a locker against it) blocks the south side")
	var north := _ray(space, Vector3(4.5, 1.5, 2.0), Vector3(4.5, 1.5, 6.0))
	_check(not north.is_empty() and absf(north.position.z - 4.0) <= 0.02, "the garden-side wall collides at z = 4")
	var chamber_box := _ray(space, Vector3(3.0, 1.2, 2.0), Vector3(3.0, 1.2, 6.0))
	_check(not chamber_box.is_empty() and absf(chamber_box.position.z - (4.0 - 0.45)) <= 0.06, "the pass-through chamber (and its closed lid) stands about 0.45 m into the room from the garden wall")
	var partition := _ray(space, Vector3(2.5, 1.2, 2.0), Vector3(9.0, 1.2, 2.0))
	_check(not partition.is_empty() and partition.position.x > 4.6 and partition.position.x < 5.0, "the closed inner hatch leaf blocks the partition at x = 5")
	var outer := _ray(space, Vector3(6.6, 1.2, 1.5), Vector3(10.0, 1.2, 1.5))
	_check(not outer.is_empty() and outer.position.x > 7.6 and outer.position.x < 8.0, "the closed outer hatch leaf blocks the east end at x = 8")
	var clearance := _ray(space, Vector3(2.5, 1.0, 2.0), Vector3(2.5, 4.0, 2.0))
	_check(not clearance.is_empty() and absf(clearance.position.y - 2.6) <= 0.02, "clear height 2.6 m under the ceiling tiles")
	return airlock

func _test_interlock(airlock: Node3D) -> void:
	_check(airlock.state_text("inner") == "SAFE TO OPEN" and airlock.state_text("outer") == "SEALED", "at start the chamber matches the habitat: inner panel SAFE TO OPEN, outer panel SEALED")
	_check(not airlock.set_hatch("outer", true).accepted, "the outer hatch refuses to open while the chamber is at habitat pressure")
	_check(airlock.set_hatch("inner", true).accepted and airlock.is_hatch_open("inner"), "the inner hatch opens on SAFE TO OPEN")
	_check(airlock.set_hatch("inner", true).get("duplicate", false), "opening an open hatch again is a duplicate input, not a change")
	_check(not airlock.request_cycle("surface").accepted, "a cycle is refused while a hatch is open")
	_check(airlock.set_hatch("inner", false).accepted and not airlock.is_hatch_open("inner"), "the inner hatch closes")
	var started: Dictionary = airlock.request_cycle("surface")
	_check(started.accepted and airlock.is_cycling() and airlock.state_text("inner") == "EQUALISING" and airlock.state_text("outer") == "EQUALISING", "a cycle to the surface starts: both panels read EQUALISING")
	var repeat: Dictionary = airlock.request_cycle("surface")
	_check(repeat.accepted and repeat.get("duplicate", false) and is_equal_approx(float(repeat.seconds_left), float(started.seconds_left)), "repeating the request does not restart the cycle")
	_check(not airlock.request_cycle("habitat").accepted, "a cycle back is refused while this one runs")
	_check(not airlock.set_hatch("inner", true).accepted and not airlock.set_hatch("outer", true).accepted, "no hatch opens while EQUALISING")
	airlock.advance(float(Airlock.interlock().equalise_seconds) * 0.5)
	_check(airlock.is_cycling(), "half way through the cycle is still EQUALISING")
	airlock.advance(float(Airlock.interlock().equalise_seconds) * 0.5 + 0.01)
	_check(not airlock.is_cycling() and airlock.chamber_side() == "surface", "the cycle finishes at the surface")
	_check(airlock.state_text("outer") == "SAFE TO OPEN" and airlock.state_text("inner") == "SEALED", "outer panel SAFE TO OPEN, inner panel SEALED (two boundaries never open together)")
	_check(not airlock.set_hatch("inner", true).accepted, "the inner hatch stays shut while the chamber is at vacuum")
	_check(airlock.set_hatch("outer", true).accepted, "the outer hatch opens")
	_check(not airlock.set_hatch("inner", true).accepted, "with the outer hatch open the inner hatch refuses")
	for text in [airlock.state_text("inner"), airlock.state_text("outer")]:
		_check(CANON_STATES.has(text), "panel words are canonical English: " + text)

func _test_hatch_physics(airlock: Node3D) -> void:
	await physics_frame
	await physics_frame
	var space := root.get_world_3d().direct_space_state
	_check(_ray(space, Vector3(6.6, 1.2, 1.5), Vector3(8.6, 1.2, 1.5)).is_empty(), "with the outer hatch open the 1.18 m opening to the surface is clear")
	_check(airlock.set_hatch("outer", false).accepted, "the outer hatch closes")
	await physics_frame
	await physics_frame
	space = root.get_world_3d().direct_space_state
	_check(not _ray(space, Vector3(6.6, 1.2, 1.5), Vector3(8.6, 1.2, 1.5)).is_empty(), "closed again, the leaf blocks the opening")
	_check(airlock.request_cycle("habitat").accepted, "cycle back to the habitat")
	airlock.advance(float(Airlock.interlock().equalise_seconds) + 0.01)
	_check(airlock.set_hatch("inner", true).accepted, "the inner hatch opens once the chamber is back at habitat pressure")
	await physics_frame
	await physics_frame
	space = root.get_world_3d().direct_space_state
	_check(_ray(space, Vector3(2.5, 1.2, 2.0), Vector3(6.0, 1.2, 2.0)).is_empty(), "with the inner hatch open the route from the vestibule into the chamber is clear")
	airlock.set_hatch("inner", false)

func _test_pass_through(airlock: Node3D) -> void:
	_check(airlock.set_lid("LidA", true).accepted and airlock.is_lid_open("LidA"), "the room-side pass-through lid opens")
	_check(not airlock.set_lid("LidB", true).accepted, "the far-side lid refuses while the room-side lid is open (sealed transfer)")
	_check(airlock.set_lid("LidA", false).accepted, "the room-side lid closes")
	_check(airlock.set_lid("LidB", true).accepted and airlock.is_lid_open("LidB"), "then the far-side lid opens for the garden")
	_check(airlock.set_lid("LidB", true).get("duplicate", false), "repeating the lid command is a duplicate")
	airlock.set_lid("LidB", false)

func _test_save_restore(airlock: Node3D) -> void:
	airlock.request_cycle("surface")
	airlock.advance(1.0)
	airlock.set_lid("LidA", true)
	var saved: Dictionary = airlock.snapshot()
	var twin := Airlock.new()
	twin.build_on_ready = false
	twin.with_lights = false
	root.add_child(twin)
	twin.build()
	twin.restore(saved)
	_check(twin.is_cycling() and twin.state_text("outer") == "EQUALISING" and twin.is_lid_open("LidA") and not twin.is_lid_open("LidB"), "a restored airlock resumes the running cycle and the open lid")
	_check(is_equal_approx(float(twin.snapshot().equalising_left), float(saved.equalising_left)), "the restored cycle keeps its remaining time")
	twin.advance(float(Airlock.interlock().equalise_seconds))
	_check(twin.state_text("outer") == "SAFE TO OPEN", "the restored cycle completes on its own")
	twin.free()
	airlock.set_lid("LidA", false)

func _ray(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> Dictionary:
	return space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))

func _bounds(node: Node3D) -> AABB:
	return _subtree_bounds(node, node)

func _subtree_bounds(leaf: Node3D, ancestor: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mesh in leaf.find_children("*", "MeshInstance3D", true, false):
		var xf := ancestor.global_transform.affine_inverse() * (mesh as MeshInstance3D).global_transform
		var aabb := xf * (mesh as MeshInstance3D).get_aabb()
		box = aabb if first else box.merge(aabb)
		first = false
	return box

# ----------------------------------------------------------------------------------------------- evidence

func _evidence() -> void:
	root.size = Vector2i(1600, 1000)
	root.always_on_top = true
	root.grab_focus()
	RenderingServer.frame_post_draw.connect(func(): _drawn_frames += 1)
	var stage := _studio()
	root.add_child(stage)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#030406")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.86, 0.88, 0.92)
	env.ambient_light_energy = 0.06
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.ssao_enabled = true
	env.ssil_enabled = true
	env.ssil_intensity = 1.2
	env.glow_enabled = true
	env.glow_intensity = 0.45
	env.glow_hdr_threshold = 1.2
	env.fog_enabled = false
	var world := WorldEnvironment.new()
	world.environment = env
	stage.add_child(world)
	var airlock := Airlock.new()
	airlock.build_on_ready = false
	stage.add_child(airlock)
	airlock.build()
	var camera: Camera3D = stage.get_node("Camera")
	var caption: Label = _caption()
	# 1. vestibule overview from the garden-wall corner by the partition (the first capture stood inside the
	# corner wall's body at x 0.45 and showed a blank face): lockers, inner door, bench and the near wall
	_aim(camera, Vector3(4.6, 2.2, 3.6), Vector3(1.6, 0.9, 0.6), 80)
	_set_caption(caption, "EN_Airlock vestibule (LOC-05), from the garden wall", "8 x 4 m double interlock: five suit lockers in role colours against the near wall, inner door to the commons on the left, suit-up bench on the right; the partition with the inner hatch and panel stands behind the camera at x = 5")
	await _capture("M3-2A_godot_vestibule")
	# 2. the garden wall close: glove ports, pass-through with the room-side lid open. The strips light the floor,
	# not this wall, so the capture carries one soft fill from the camera side (evidence only, not part of the asset)
	airlock.set_lid("LidA", true)
	var fill := _fill(stage, Vector3(2.4, 2.0, 1.9))
	_aim(camera, Vector3(2.4, 1.6, 1.3), Vector3(2.7, 1.3, 4.0), 62)
	_set_caption(caption, "Glove ports and sealed carrier pass-through", "LidA open towards the room; LidB (garden side) stays locked while it is; the carrier socket is inside the white chamber (soft fill light for the capture)")
	await _capture("M3-2A_godot_pass_through")
	fill.free()
	airlock.set_lid("LidA", false)
	# 3. interlock panel: SAFE TO OPEN on the inner side, then the cycle
	_aim(camera, Vector3(3.6, 1.5, 1.4), Vector3(5.0, 1.4, 0.7), 50)
	_set_caption(caption, "Interlock panel: live words on the Screen slot", "Inner panel reads SAFE TO OPEN while the chamber matches the habitat; the green lamp is lit")
	await _capture("M3-2A_godot_panel_safe")
	airlock.request_cycle("surface")
	airlock.advance(0.5)
	_set_caption(caption, "Interlock panel: EQUALISING", "Pump sound plays only while the cycle runs; both hatches refuse to open")
	await _capture("M3-2A_godot_panel_equalising")
	airlock.advance(float(Airlock.interlock().equalise_seconds))
	_set_caption(caption, "Interlock panel: SEALED", "Chamber now at surface pressure: the inner panel reads SEALED, the outer panel SAFE TO OPEN")
	await _capture("M3-2A_godot_panel_sealed")
	# 4. the chamber from the inner hatch (cycled back, inner hatch open)
	airlock.request_cycle("habitat")
	airlock.advance(float(Airlock.interlock().equalise_seconds))
	airlock.set_hatch("inner", true)
	_aim(camera, Vector3(3.9, 1.5, 2.3), Vector3(7.6, 1.2, 1.8), 62)
	_set_caption(caption, "Airlock chamber through the open inner hatch", "Outer hatch to the surface (LOC-06) and the chamber's own panel; only one hatch opens at a time")
	await _capture("M3-2A_godot_chamber")
	airlock.set_hatch("inner", false)
	# 5. props: paper bee and seed tray on the bench
	var bee := (load(Airlock.prop("PR_PaperBee").path) as PackedScene).instantiate() as Node3D
	bee.position = Vector3(3.55, 0.45, 0.25)
	bee.rotation_degrees.y = 35
	stage.add_child(bee)
	var tray := (load(Airlock.prop("PR_SeedTray").path) as PackedScene).instantiate() as Node3D
	tray.position = Vector3(4.35, 0.45, 0.25)
	stage.add_child(tray)
	_aim(camera, Vector3(3.95, 0.95, 0.95), Vector3(3.95, 0.47, 0.25), 55)
	_set_caption(caption, "PR_PaperBee and PR_SeedTray on the bench", "Origami bee in gold duo paper with navy bands (no face); clean 12-cell tray, 0.50 m")
	await _capture("M3-2A_godot_props")
	_aim(camera, Vector3(3.42, 0.62, 0.42), Vector3(3.55, 0.46, 0.25), 30)
	_set_caption(caption, "PR_PaperBee close", "About 9 cm long; sockets Socket_Grip and Socket_Rest for held and placed states")
	await _capture("M3-2A_godot_paper_bee")
	stage.free()

## A soft warm omni fill for one capture, freed by the caller; it never ships with the asset.
func _fill(stage: Node3D, at: Vector3) -> OmniLight3D:
	var fill := OmniLight3D.new()
	fill.position = at
	fill.light_color = Color(1.0, 0.86, 0.72)
	fill.light_energy = 1.1
	fill.omni_range = 6.0
	fill.omni_attenuation = 1.4
	fill.shadow_enabled = false
	stage.add_child(fill)
	return fill

func _aim(camera: Camera3D, from: Vector3, at: Vector3, fov: float) -> void:
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = fov
	camera.global_position = from
	camera.look_at(at, Vector3.UP)

func _caption() -> Label:
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_top = -128
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.05, 0.08, 0.86)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 22)
	panel.add_child(label)
	return label

func _set_caption(label: Label, heading: String, detail: String) -> void:
	label.text = heading + "\n" + detail

func _studio() -> Node3D:
	var stage := Node3D.new()
	var camera := Camera3D.new()
	camera.name = "Camera"
	stage.add_child(camera)
	camera.current = true
	return stage

## A covered macOS window may stop drawing: bound the wait and draw explicitly, as the M3-2R capture does.
func _capture(label: String) -> void:
	await process_frame
	await process_frame
	await process_frame
	var drawn := _drawn_frames
	for frame in 30:
		await process_frame
		if _drawn_frames > drawn:
			break
	if _drawn_frames == drawn:
		RenderingServer.force_draw(false)
	var path := ProjectSettings.globalize_path(EVIDENCE_DIR + label + ".png")
	var error := root.get_texture().get_image().save_png(path)
	_check(error == OK, "evidence written: " + label)
