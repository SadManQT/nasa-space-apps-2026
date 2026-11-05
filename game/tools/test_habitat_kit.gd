## M1-05: the modular habitat kit loads, snaps to the metre grid, carries collision, LODs and moving parts.
## Headless: game/tools/run_tests.sh habitat_kit
## Evidence (needs a window): Godot --path game --script res://tools/test_habitat_kit.gd -- --evidence
extends SceneTree

const Kit = preload("res://assets/environment/kit/habitat_kit.gd")
const EVIDENCE_DIR := "res://../production/qa/evidence/"
const WALL_IDS := ["EN_Kit_Wall_Straight", "EN_Kit_Wall_Corner", "EN_Kit_Wall_Window", "EN_Kit_DoorFrame", "EN_Kit_Hatch", "EN_Kit_Wall_EquipBay", "EN_Kit_BulkheadRing"]
var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		print("FAIL ", message)

func _run() -> void:
	var catalog := Kit.catalog()
	_check(catalog.pieces.size() == 12, "twelve approved pieces (sheets A and B)")
	_check(catalog.conventions.wall_height_m == 2.6 and catalog.conventions.grid_m == 1.0, "2.6 m walls on a 1 m grid")
	_check(catalog.materials.size() == 9, "nine reusable kit materials")
	for material in catalog.materials:
		var mat := load(material.path) as StandardMaterial3D
		_check(mat != null and mat.albedo_texture != null and mat.normal_texture != null and mat.roughness_texture != null, material.id + " loads albedo, normal and ORM textures")
	for entry in catalog.pieces:
		_test_piece(entry)
	_test_grid_assembly()
	_test_moving_parts()
	if OS.get_cmdline_user_args().has("--evidence"):
		await _evidence()
	print("HABITAT KIT RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_piece(entry: Dictionary) -> void:
	var id: String = entry.id
	_check(entry.lods.size() == 2 and entry.triangles.size() == 2, id + " has a game LOD and a Compatibility LOD")
	_check(int(entry.triangles[0]) <= 8000 and int(entry.triangles[1]) <= int(entry.triangles[0]), id + " triangle budget 8k and LOD1 no heavier than LOD0")
	for path in entry.lods:
		_check(load(path) is PackedScene, "load " + String(path))
	var node := Kit.instance(id)
	root.add_child(node)
	_check(node.get_node_or_null("LOD0") != null and node.get_node_or_null("LOD1") != null, id + " builds both LOD children")
	var lod0: Node3D = node.get_node("LOD0")
	var lod1: Node3D = node.get_node("LOD1")
	var ranges := true
	var max_tex0 := 0
	var max_tex1 := 0
	var textured := 0
	var opaque := 0
	for mesh in lod0.find_children("*", "MeshInstance3D", true, false):
		ranges = ranges and mesh.visibility_range_begin == 0.0 and mesh.visibility_range_end == float(entry.lod_distance_m)
		for surface in mesh.mesh.get_surface_count():
			var material := mesh.get_active_material(surface) as StandardMaterial3D
			if material == null:
				continue
			if material.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and not material.emission_enabled and not material.resource_name.begins_with("Screen"):
				opaque += 1
				if material.albedo_texture != null and material.normal_texture != null:
					textured += 1
			for texture in [material.albedo_texture, material.normal_texture, material.roughness_texture]:
				if texture != null:
					max_tex0 = maxi(max_tex0, maxi(texture.get_width(), texture.get_height()))
	for mesh in lod1.find_children("*", "MeshInstance3D", true, false):
		ranges = ranges and mesh.visibility_range_begin == float(entry.lod_distance_m) and mesh.visibility_range_end == 0.0
		for surface in mesh.mesh.get_surface_count():
			var material := mesh.get_active_material(surface) as StandardMaterial3D
			if material != null:
				for texture in [material.albedo_texture, material.normal_texture, material.roughness_texture]:
					if texture != null:
						max_tex1 = maxi(max_tex1, maxi(texture.get_width(), texture.get_height()))
	_check(ranges, id + " LOD ranges meet at the switch distance and the far LOD stays visible")
	_check(opaque > 0 and textured == opaque, id + " every opaque surface carries albedo and normal textures (toon-ready)")
	_check(max_tex0 > 0 and max_tex0 <= 1024 and max_tex1 > 0 and max_tex1 <= 512, id + " texture budget: LOD0 <= 1024 px, LOD1 <= 512 px")
	_check(lod0.find_children("*", "StaticBody3D", true, false).size() > 0, id + " game LOD carries collision bodies")
	var shapes := true
	for body in lod0.find_children("*", "StaticBody3D", true, false):
		var shape := body.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if shape == null:
			for child in body.get_children():
				if child is CollisionShape3D:
					shape = child
		shapes = shapes and shape != null and shape.shape != null
	_check(shapes, id + " every collision body has a shape")
	_check(lod1.find_children("*", "StaticBody3D", true, false).is_empty(), id + " Compatibility LOD has no duplicate collision")
	var box := Kit.bounds(node, 0)
	_check(absf(box.position.y) <= 0.01, id + " lowest point on the floor (gate rule)")
	var footprint: Array = entry.footprint_m
	_check(absf(box.size.x - float(footprint[0])) <= 0.01, id + " footprint width %.3f matches catalogue %.2f" % [box.size.x, float(footprint[0])])
	if id in WALL_IDS:
		_check(absf(box.size.y - 2.6) <= 0.01, id + " is 2.6 m tall")
	if id in ["EN_Kit_Wall_Straight", "EN_Kit_Wall_Window", "EN_Kit_Wall_EquipBay"]:
		_check(absf(box.position.x + 0.5) <= 0.005 and absf(box.end.x - 0.5) <= 0.005, id + " spans exactly -0.5..0.5 m on the grid")
		_check(box.end.z >= 0.149 and box.end.z <= 0.151, id + " body ends on the 0.15 m wall depth")
	if id == "EN_Kit_FloorTile" or id == "EN_Kit_CeilingTile":
		_check(absf(box.size.x - 1.0) <= 0.002 and absf(box.size.z - 1.0) <= 0.002, id + " is a true 1 x 1 m tile")
	if id == "EN_Kit_FloorTile":
		_check(absf(float(entry.mount_y) + 0.06) < 0.001 and box.end.y <= 0.075, "floor tile deck sits at y=0 when mounted at -0.06")
	var stripped := Kit.instance(id, false)
	_check(stripped.find_children("*", "StaticBody3D", true, false).is_empty(), id + " collision can be opted out")
	stripped.free()
	node.free()

func _test_grid_assembly() -> void:
	# A 6 x 4 m room: corners take 0.5 m of each wall, straight pieces fill the integer run, floor tiles butt together.
	var room := Node3D.new()
	root.add_child(room)
	var floor_boxes: Array[AABB] = []
	for x in 6:
		for z in 4:
			var tile := Kit.place(room, "EN_Kit_FloorTile", Vector3(x + 0.5, 0, z + 0.5))
			floor_boxes.append(tile.transform * Kit.bounds(tile, 0))
	var tops := true
	var touching := true
	for i in floor_boxes.size():
		tops = tops and absf(float(room.get_child(i).position.y) + 0.06) <= 0.001 and floor_boxes[i].end.y <= 0.015
		for j in range(i):
			var gap := floor_boxes[i].position.x - floor_boxes[j].end.x
			if absf(floor_boxes[i].position.z - floor_boxes[j].position.z) < 0.001 and gap > -0.001 and gap < 0.5:
				touching = touching and absf(gap) <= 0.001
	_check(tops, "floor decks sit on y = 0 when mounted; only the 11 mm tie-down rings stand proud")
	_check(touching, "neighbouring floor tiles butt together without gaps or overlaps")
	var far := Node3D.new()
	room.add_child(far)
	Kit.place(far, "EN_Kit_Wall_Corner", Vector3(0, 0, 4), -90)
	for x in range(1, 6):
		Kit.place(far, "EN_Kit_Wall_Straight", Vector3(x, 0, 4))
	Kit.place(far, "EN_Kit_Wall_Corner", Vector3(6, 0, 4), 0)
	var wall_box := AABB()
	var first := true
	for piece in far.get_children():
		var box: AABB = (piece as Node3D).transform * Kit.bounds(piece, 0)
		wall_box = box if first else wall_box.merge(box)
		first = false
	_check(absf(wall_box.position.x + 0.15) <= 0.005 and absf(wall_box.end.x - 6.15) <= 0.005, "far wall run spans the 6 m room edge; corner columns sit outside the interior on both ends")
	_check(absf(wall_box.position.z - 3.5) <= 0.005 and absf(wall_box.end.z - 4.15) <= 0.06, "far wall faces lie on z = 4 with bodies behind")
	var door := Kit.place(room, "EN_Kit_DoorFrame", Vector3(2, 0, 0), 180)
	var door_box: AABB = door.transform * Kit.bounds(door, 0)
	_check(absf(door_box.position.x - 0.5) <= 0.005 and absf(door_box.end.x - 3.5) <= 0.005, "a 3 m door module fills three grid slots")
	room.free()

func _test_moving_parts() -> void:
	var door := Kit.instance("EN_Kit_DoorFrame")
	root.add_child(door)
	var leaves := door.find_children("DoorLeaf", "Node3D", true, false)
	_check(leaves.size() == 2, "door leaf node in both LODs")
	var closed_x: float = (leaves[0] as Node3D).position.x
	Kit.set_door_open(door, 1.0)
	_check(absf((leaves[0] as Node3D).position.x - closed_x - 1.25) < 0.001, "open door slides the leaf 1.25 m along +X")
	var leaf_box := _subtree_bounds(leaves[0] as Node3D, door)
	_check(leaf_box.end.x <= 1.5 and leaf_box.position.x >= 0.05, "open leaf parks inside the module's wide jamb")
	Kit.set_door_open(door, 0.0)
	_check(absf((leaves[0] as Node3D).position.x - closed_x) < 0.001, "closing restores the leaf")
	var collision := (leaves[0] as Node3D).find_children("*", "StaticBody3D", true, false)
	_check(collision.size() == 1, "the door leaf carries its own collision so it moves with the leaf")
	door.free()
	var hatch := Kit.instance("EN_Kit_Hatch")
	root.add_child(hatch)
	var hatch_leaves := hatch.find_children("HatchLeaf", "Node3D", true, false)
	_check(hatch_leaves.size() == 2, "hatch leaf node in both LODs")
	var closed := _subtree_bounds(hatch_leaves[0] as Node3D, hatch)
	_check(closed.end.z <= -0.08 and absf(closed.get_center().x) < 0.03 and absf(closed.get_center().y - 1.2) < 0.03, "closed hatch leaf covers the 1.2 m opening in front of the collar")
	Kit.set_hatch_open(hatch, 1.0)
	var opened := _subtree_bounds(hatch_leaves[0] as Node3D, hatch)
	_check(absf((hatch_leaves[0] as Node3D).rotation_degrees.y - 100.0) < 0.01, "open hatch swings 100 degrees about its hinge")
	_check(opened.position.z < -0.9 and opened.end.x < 0.2, "the open leaf swings into the room (-Z) beside the hinge, clear of the opening")
	hatch.free()
	var bay := Kit.instance("EN_Kit_Wall_EquipBay")
	root.add_child(bay)
	var screens := Kit.screen_surfaces(bay)
	_check(screens.size() == 2, "equipment bay exposes one 'Screen' surface per LOD for a live UI texture")
	bay.free()
	var window := Kit.instance("EN_Kit_Wall_Window")
	root.add_child(window)
	var glass := false
	for mesh in window.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.mesh.get_surface_count():
			var material := mesh.get_active_material(surface) as StandardMaterial3D
			glass = glass or (material != null and material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED)
	_check(glass, "window pane is a transparent material (left alone by the toon pass)")
	window.free()
	var strip := Kit.instance("EN_Kit_LightStrip")
	root.add_child(strip)
	var glowing := false
	for mesh in strip.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.mesh.get_surface_count():
			var material := mesh.get_active_material(surface) as StandardMaterial3D
			glowing = glowing or (material != null and material.emission_enabled and material.emission_energy_multiplier > 1.0)
	_check(glowing, "light strip diffuser is emissive")
	strip.free()

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
	var title := Label.new()
	title.position = Vector2(24, 18)
	title.add_theme_font_size_override("font_size", 22)
	root.add_child(title)
	# 1 and 2: every piece on a neutral stage, game LOD then Compatibility LOD
	for lod in 2:
		var stage := _studio()
		root.add_child(stage)
		var ids := Kit.ids()
		for i in ids.size():
			var node := Kit.instance(ids[i], false)
			if lod == 1:
				node.get_node("LOD0").visible = false
				for mesh in node.get_node("LOD1").find_children("*", "MeshInstance3D", true, false):
					mesh.visibility_range_begin = 0.0
			var column := i % 6
			var row := i / 6
			node.position = Vector3(-8.5 + column * 3.4, 0.0, -1.0 + row * 4.6)
			if ids[i] in ["EN_Kit_CeilingTile", "EN_Kit_LightStrip"]:
				node.rotation_degrees = Vector3(180, 0, 0)
				node.position.y = 0.08 if ids[i] == "EN_Kit_LightStrip" else 0.06
			if ids[i] in ["EN_Kit_PipeRun", "EN_Kit_CableRun"]:
				node.rotation_degrees.y = -30
			stage.add_child(node)
			var label := Label3D.new()
			label.text = ids[i].trim_prefix("EN_Kit_")
			label.font_size = 64
			label.pixel_size = 0.004
			label.position = node.position + Vector3(0, -0.3, 1.9)
			label.rotation_degrees.x = -90
			label.modulate = Color(0.12, 0.16, 0.27)
			stage.add_child(label)
		title.text = "M1-05 habitat kit | %s | 12 pieces from the approved sheets A and B | studio light, no gameplay lighting" % ["LOD0 (game, with collision)" if lod == 0 else "LOD1 (Compatibility build, 512 px textures)"]
		await _capture("M1-05_godot_kit_lod%d" % lod)
		stage.free()
	# 3 to 5: a 6 x 4 m sample room with a corridor, lit only by its own light strips (practical lights)
	var room := _sample_room()
	root.add_child(room)
	var camera := Camera3D.new()
	camera.fov = 68
	room.add_child(camera)
	camera.position = Vector3(0.9, 1.55, 0.9)
	camera.look_at(Vector3(4.6, 1.3, 3.6))
	title.text = "M1-05 sample assembly | 6 x 4 m room from kit pieces on the 1 m grid | far wall: corner, straight, window, equipment bay | lit by the kit's light strips"
	await _capture("M1-05_godot_room")
	camera.position = Vector3(5.2, 1.55, 3.2)
	camera.look_at(Vector3(1.2, 1.2, -1.2))
	title.text = "M1-05 sample assembly | near wall: sliding pressure door open (leaf parked in the jamb), corridor bulkhead rings beyond | left wall: hatch open"
	Kit.set_door_open(room, 1.0)
	Kit.set_hatch_open(room, 1.0)
	await _capture("M1-05_godot_room_open")
	Kit.set_door_open(room, 0.0)
	Kit.set_hatch_open(room, 0.0)
	camera.position = Vector3(2.5, 1.55, -3.3)
	camera.look_at(Vector3(2.5, 1.2, 1.5))
	title.text = "M1-05 sample assembly | corridor view through two bulkhead rings towards the closed sliding door; pipe and cable runs on the right wall"
	await _capture("M1-05_godot_corridor")
	room.free()
	title.free()

func _studio() -> Node3D:
	var stage := Node3D.new()
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.60, 0.61, 0.63)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.35
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	stage.add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-48, 35, 0)
	key.light_energy = 1.6
	key.shadow_enabled = true
	stage.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-30, -120, 0)
	fill.light_energy = 0.5
	stage.add_child(fill)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 40)
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.52, 0.53, 0.55)
	ground_material.roughness = 0.95
	plane.material = ground_material
	ground.mesh = plane
	ground.position.y = -0.002
	stage.add_child(ground)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 13.5
	camera.position = Vector3(0, 12, 14)
	stage.add_child(camera)
	camera.look_at(Vector3(0, 0.9, 1.3))
	camera.current = true
	return stage

func _sample_room() -> Node3D:
	var room := Node3D.new()
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("#05060A")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.95, 0.9, 0.85)
	env.environment.ambient_light_energy = 0.12
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment.ssao_enabled = true
	env.environment.fog_enabled = false
	room.add_child(env)
	for x in 6:
		for z in 4:
			Kit.place(room, "EN_Kit_FloorTile", Vector3(x + 0.5, 0, z + 0.5))
			Kit.place(room, "EN_Kit_CeilingTile", Vector3(x + 0.5, 0, z + 0.5))
	Kit.place(room, "EN_Kit_Wall_Corner", Vector3(0, 0, 4), -90)
	Kit.place(room, "EN_Kit_Wall_Straight", Vector3(1, 0, 4))
	Kit.place(room, "EN_Kit_Wall_Window", Vector3(2, 0, 4))
	Kit.place(room, "EN_Kit_Wall_EquipBay", Vector3(3, 0, 4))
	Kit.place(room, "EN_Kit_Wall_Straight", Vector3(4, 0, 4))
	Kit.place(room, "EN_Kit_Wall_Straight", Vector3(5, 0, 4))
	Kit.place(room, "EN_Kit_Wall_Corner", Vector3(6, 0, 4), 0)
	Kit.place(room, "EN_Kit_Wall_Straight", Vector3(0, 0, 3), -90)
	Kit.place(room, "EN_Kit_Hatch", Vector3(0, 0, 1.5), -90)
	Kit.place(room, "EN_Kit_Wall_Corner", Vector3(0, 0, 0), 180)
	Kit.place(room, "EN_Kit_DoorFrame", Vector3(2, 0, 0), 180)
	Kit.place(room, "EN_Kit_Wall_Straight", Vector3(4, 0, 0), 180)
	Kit.place(room, "EN_Kit_Wall_Straight", Vector3(5, 0, 0), 180)
	Kit.place(room, "EN_Kit_Wall_Corner", Vector3(6, 0, 0), 90)
	for z in range(1, 4):
		Kit.place(room, "EN_Kit_Wall_Straight", Vector3(6, 0, z), 90)
	var on_right_wall := Basis(Vector3(0, 0, 1), Vector3(-1, 0, 0), Vector3(0, -1, 0))
	for z in range(1, 4):
		var pipes := Kit.place(room, "EN_Kit_PipeRun", Vector3(6, 1.9, z))
		pipes.transform.basis = on_right_wall
		var cables := Kit.place(room, "EN_Kit_CableRun", Vector3(6, 2.32, z))
		cables.transform.basis = on_right_wall
	for x in [2, 4]:
		for z in range(1, 4):
			Kit.place(room, "EN_Kit_LightStrip", Vector3(x, 0, z))
			var lamp := OmniLight3D.new()
			lamp.position = Vector3(x, 2.45, z)
			lamp.light_color = Color(1.0, 0.86, 0.70)
			lamp.light_energy = 2.2
			lamp.omni_range = 5.5
			lamp.shadow_enabled = true
			room.add_child(lamp)
	# corridor beyond the near-wall door: two bulkhead rings and a 2 m wide floor
	for z in [-0.6, -2.6]:
		Kit.place(room, "EN_Kit_BulkheadRing", Vector3(2.5, 0, z))
	for x in [2, 3]:
		for z in [-0.5, -1.5, -2.5, -3.5]:
			Kit.place(room, "EN_Kit_FloorTile", Vector3(x, 0, z))
	var corridor_lamp := OmniLight3D.new()
	corridor_lamp.position = Vector3(2.5, 2.2, -1.6)
	corridor_lamp.light_color = Color(0.95, 0.97, 1.0)
	corridor_lamp.light_energy = 1.6
	corridor_lamp.omni_range = 5.0
	room.add_child(corridor_lamp)
	return room

func _capture(label: String) -> void:
	await process_frame
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(EVIDENCE_DIR + label + ".png")
	var error := root.get_texture().get_image().save_png(path)
	_check(error == OK, "evidence written: " + label)
