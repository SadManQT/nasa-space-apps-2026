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
	var paint_orm_uid := ResourceUID.text_to_id("uid://c4y0dt47sdboo")
	_check(paint_orm_uid != ResourceUID.INVALID_ID and ResourceUID.has_id(paint_orm_uid) and ResourceUID.get_id_path(paint_orm_uid) == "res://assets/environment/kit/textures/lod1/T_Kit_Paint_ORM_LOD1.png", "T_Kit_Paint_ORM_LOD1.png registers tracked uid://c4y0dt47sdboo without fallback")
	for entry in catalog.pieces:
		_test_piece(entry)
	_test_grid_assembly()
	_test_moving_parts()
	await _test_corridor()
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
	_check(closed.position.z <= -0.16 and absf(closed.get_center().x) < 0.03 and absf(closed.get_center().y - 1.2) < 0.03, "closed hatch leaf covers the 1.2 m opening in front of the collar")
	_check(closed.end.z > -0.08 and closed.end.z <= 0.0, "the leaf's far-side wheel and handles reach into the bulkhead opening, so the hatch works from both modules")
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

func _test_corridor() -> void:
	# A 3 m corridor (the LOC-02 service corridor pattern): three ring segments chained along -Z from a door module.
	var corridor := Node3D.new()
	root.add_child(corridor)
	var sockets: Dictionary = Kit.piece("EN_Kit_BulkheadRing").sockets
	var pitch := float(sockets.chain_pitch_m)
	_check(is_equal_approx(pitch, 1.0) and float(Kit.piece("EN_Kit_BulkheadRing").footprint_m[1]) == pitch, "ring segments chain on the 1 m grid")
	var boxes: Array[AABB] = []
	for k in 3:
		var ring := Kit.place(corridor, "EN_Kit_BulkheadRing", Vector3(0, 0, -pitch * (k + 0.5)))
		boxes.append(ring.transform * Kit.bounds(ring, 0))
	var butt := true
	for k in 2:
		butt = butt and absf(boxes[k].position.z - boxes[k + 1].end.z) <= 0.001
	_check(butt and absf(boxes[0].end.z) <= 0.001 and absf(boxes[2].position.z + 3.0) <= 0.001, "chained segments butt end to end: a 3 m corridor from 0 to -3 m")
	_check(absf(boxes[0].position.y + 0.14) <= 0.002, "a mounted ring sits 0.14 m below the floor so its tread is the walking surface")
	var door := Kit.place(corridor, "EN_Kit_DoorFrame", Vector3(-0.5, 0, 0.265), 180)
	var hatch := Kit.place(corridor, "EN_Kit_Hatch", Vector3(6, 0, 0))
	await physics_frame
	await physics_frame
	var space := root.get_world_3d().direct_space_state
	var floor_ok := true
	for z in [-0.5, -0.99, -1.01, -1.5, -2.95]:
		var hit := _ray(space, Vector3(0, 1.5, z), Vector3(0, -1, z))
		floor_ok = floor_ok and not hit.is_empty() and absf(hit.position.y - float(sockets.walk_y)) <= 0.01
	_check(floor_ok, "the corridor floor collides at y = 0 inside the segments and across every joint")
	var side := _ray(space, Vector3(0, 1.0, -1.5), Vector3(2, 1.0, -1.5))
	_check(not side.is_empty() and absf(side.position.x - 1.16) <= 0.01, "the corridor walls collide 1.16 m either side of the centre line")
	var top := _ray(space, Vector3(0, 1.0, -1.5), Vector3(0, 4, -1.5))
	_check(not top.is_empty() and absf(top.position.y - float(sockets.clear_height_m)) <= 0.01, "clear height %.2f m inside the corridor (above every adult cadet)" % float(sockets.clear_height_m))
	var route_closed := _ray(space, Vector3(0, 1.0, -2.5), Vector3(0, 1.0, 1.5))
	_check(not route_closed.is_empty() and route_closed.position.z > -0.01 and route_closed.position.z < 0.3, "the closed door leaf blocks the corridor at the door module")
	var hatch_closed := _ray(space, Vector3(6, 1.2, -1.0), Vector3(6, 1.2, 1.0))
	_check(not hatch_closed.is_empty() and hatch_closed.position.z < -0.08, "the closed hatch leaf blocks the round opening")
	Kit.set_door_open(door, 1.0)
	Kit.set_hatch_open(hatch, 1.0)
	await physics_frame
	await physics_frame
	space = root.get_world_3d().direct_space_state
	_check(_ray(space, Vector3(0, 1.0, -2.5), Vector3(0, 1.0, 1.5)).is_empty(), "with the door open the route runs from the corridor into the room (the leaf's collision moved with it)")
	_check(_ray(space, Vector3(6, 1.2, -1.0), Vector3(6, 1.2, 1.0)).is_empty(), "with the hatch open the 1.18 m opening is clear")
	corridor.free()

func _ray(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> Dictionary:
	return space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))

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

const WARM_WHITE := Color(1.0, 0.81, 0.65)  # 4000 K blackbody in sRGB: living areas (sheet B: 3200-4000 K)
const SERVICE_WHITE := Color(1.0, 0.89, 0.81)  # 5000 K blackbody in sRGB: service corridor (sheet B)

func _evidence() -> void:
	root.size = Vector2i(1600, 1000)
	root.always_on_top = true
	root.grab_focus()
	var caption := _caption()
	# 1 and 2: every piece on a neutral stage, game LOD then Compatibility LOD. The camera stands on the -Z side so the
	# wall faces look at it; the wall pieces form the back row, the floor, ceiling, runs, light and ring the front row.
	# The LOD0 stage forces the game LOD (its visibility range would otherwise hand over to LOD1 at this distance).
	for lod in 2:
		var stage := _studio()
		root.add_child(stage)
		var ids := Kit.ids()
		for i in ids.size():
			var node := Kit.instance(ids[i], false, 0) if lod == 0 else Kit.instance(ids[i], false)
			if lod == 1:
				node.get_node("LOD0").visible = false
				for mesh in node.get_node("LOD1").find_children("*", "MeshInstance3D", true, false):
					mesh.visibility_range_begin = 0.0
			var column := i % 6
			var front := i >= 6
			# +X runs to the camera's left, so columns count down in x to read left to right in catalogue order.
			node.position = Vector3(8.75 - column * 3.5, 0.0, -4.5 if front else 2.4)
			if ids[i] in ["EN_Kit_CeilingTile", "EN_Kit_LightStrip"]:
				node.rotation_degrees = Vector3(180, 0, 0)
				node.position.y = 0.08 if ids[i] == "EN_Kit_LightStrip" else 0.06
			if ids[i] in ["EN_Kit_PipeRun", "EN_Kit_CableRun"]:
				node.rotation_degrees.y = -30
			stage.add_child(node)
			var label := Label3D.new()
			label.text = ids[i].trim_prefix("EN_Kit_")
			label.font_size = 56
			label.pixel_size = 0.007
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.no_depth_test = true
			label.outline_size = 10
			label.outline_modulate = Color(1, 1, 1, 0.9)
			label.position = node.position + Vector3(0, 0.25, -1.7)
			label.modulate = Color(0.12, 0.16, 0.27)
			stage.add_child(label)
		_set_caption(caption, "M1-05 habitat kit, %s" % ["LOD0: game LOD with collision" if lod == 0 else "LOD1: Compatibility build, 512 px textures"],
			"The 12 pieces from the approved sheets A and B in catalogue order, imported by Godot from the kit GLBs. Neutral studio light, not gameplay lighting.")
		await _capture("M1-05_godot_kit_lod%d" % lod)
		stage.free()
	# 3 to 5: a 6 x 4 m sample room and a 4 m ring corridor, lit only by the kit's own light strips (practical lights)
	var room := _sample_room()
	root.add_child(room)
	var camera := Camera3D.new()
	camera.fov = 68
	room.add_child(camera)
	camera.current = true
	camera.position = Vector3(0.9, 1.55, 0.9)
	camera.look_at(Vector3(4.6, 1.3, 3.6))
	_set_caption(caption, "M1-05 sample assembly: a 6 x 4 m room built from kit pieces on the 1 m grid",
		"Far wall: corner, straight, window, equipment bay (its screen is the live-UI slot). Floor and ceiling tiles, six light strips; lit only by the strips' downlights with screen-space bounce light.")
	await _capture("M1-05_godot_room")
	camera.position = Vector3(5.2, 1.55, 3.2)
	camera.look_at(Vector3(1.2, 1.2, -1.2))
	Kit.set_door_open(room, 1.0)
	Kit.set_hatch_open(room, 1.0)
	_set_caption(caption, "M1-05 sample assembly: the door and the hatch open",
		"Near wall: the sliding pressure door open (its leaf parked in the jamb) onto the ring corridor. Left wall: the round hatch swung into the room, 0.6 m sill, 1.18 m clear opening.")
	await _capture("M1-05_godot_room_open")
	camera.position = Vector3(2.5, 1.62, -3.95)
	camera.look_at(Vector3(2.5, 1.25, 2.0))
	_set_caption(caption, "M1-05 sample assembly: the service corridor",
		"Four 1 m bulkhead ring segments chained on the grid between two door modules: quilted liner, handrails at 1.0 m, anti-slip tread, an orange seal line at every joint, 5000 K light strips. The open door leads into the room.")
	await _capture("M1-05_godot_corridor")
	Kit.set_door_open(room, 0.0)
	Kit.set_hatch_open(room, 0.0)
	room.free()
	caption.get_parent().get_parent().free()

## A caption panel across the top of the capture: a heading line and a wrapped detail line on a dark backing.
func _caption() -> Label:
	var layer := CanvasLayer.new()
	layer.layer = 10
	root.add_child(layer)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.05, 0.09, 0.86)
	style.set_corner_radius_all(6)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	panel.position = Vector2(16, 12)
	layer.add_child(panel)
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# the project stretches canvas items from 1280 x 720, so size the caption in the visible rect's units
	label.custom_minimum_size = Vector2(root.get_visible_rect().size.x - 32 - 36, 0)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.93, 0.95, 0.98))
	label.add_theme_constant_override("line_spacing", 2)
	panel.add_child(label)
	return label

func _set_caption(label: Label, heading: String, detail: String) -> void:
	label.text = heading + "\n" + detail
	(label.get_parent() as Control).reset_size()

## A ceiling luminaire's light: a soft-shadowed downlight just under the diffuser face, so the ceiling gets only
## bounce light (as under a real recessed strip) and the strip's emissive face blooms slightly.
func _downlight(at: Vector3, color: Color, energy: float, reach: float = 4.5) -> SpotLight3D:
	var lamp := SpotLight3D.new()
	lamp.position = at
	lamp.rotation_degrees = Vector3(-90, 0, 0)
	lamp.light_color = color
	lamp.light_energy = energy
	lamp.light_size = 0.08
	lamp.spot_range = reach
	lamp.spot_angle = 82.0
	lamp.spot_angle_attenuation = 0.7
	lamp.shadow_enabled = true
	return lamp

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
	camera.size = 12.5
	camera.position = Vector3(0, 8, -12)
	# The stage is not in the tree yet, and look_at() needs a global transform, so aim the basis directly.
	camera.basis = Basis.looking_at(Vector3(0, 1.0, 0.6) - camera.position, Vector3.UP)
	stage.add_child(camera)
	camera.current = true
	return stage

func _sample_room() -> Node3D:
	var room := Node3D.new()
	var env := WorldEnvironment.new()
	var look := Environment.new()
	look.background_mode = Environment.BG_COLOR
	look.background_color = Color("#030406")
	look.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	look.ambient_light_color = Color(0.86, 0.88, 0.92)
	look.ambient_light_energy = 0.06
	look.tonemap_mode = Environment.TONE_MAPPER_AGX
	look.tonemap_exposure = 1.0
	look.ssao_enabled = true
	look.ssao_radius = 0.6
	look.ssao_intensity = 1.6
	look.ssil_enabled = true
	look.ssil_radius = 3.0
	look.ssil_intensity = 1.2
	look.glow_enabled = true
	look.glow_intensity = 0.45
	look.glow_bloom = 0.02
	look.glow_hdr_threshold = 1.2
	look.fog_enabled = false
	env.environment = look
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
			room.add_child(_downlight(Vector3(x, Kit.mount_y("EN_Kit_LightStrip") - 0.015, z), WARM_WHITE, 2.4))
	# the service corridor behind the near-wall door: four ring segments chained along -Z, closed by a second door
	# module; the door module's corridor face (skirting) is at z = -0.265, so the first segment starts there
	var ring_sockets: Dictionary = Kit.piece("EN_Kit_BulkheadRing").sockets
	var strip_y := float(ring_sockets.light_strip_y)
	for k in 4:
		var zc := -0.265 - float(ring_sockets.chain_pitch_m) * (k + 0.5)
		Kit.place(room, "EN_Kit_BulkheadRing", Vector3(2.5, 0, zc))
		var strip := Kit.place(room, "EN_Kit_LightStrip", Vector3(2.5, 0, zc), 90)
		strip.position.y = strip_y
		room.add_child(_downlight(Vector3(2.5, strip_y - 0.015, zc), SERVICE_WHITE, 1.5, 3.5))
	Kit.place(room, "EN_Kit_DoorFrame", Vector3(2, 0, -4.38), 180)
	# the next module behind the hatch: one segment along -X (its near end on the hatch's far collar at x = -0.23),
	# closed by a door module, so the open hatch shows a lit passage rather than a void
	Kit.place(room, "EN_Kit_BulkheadRing", Vector3(-0.73, 0, 1.5), 90)
	var hatch_strip := Kit.place(room, "EN_Kit_LightStrip", Vector3(-0.73, 0, 1.5))
	hatch_strip.position.y = strip_y
	room.add_child(_downlight(Vector3(-0.73, strip_y - 0.015, 1.5), SERVICE_WHITE, 1.5, 3.5))
	Kit.place(room, "EN_Kit_DoorFrame", Vector3(-1.345, 0, 2.0), -90)
	return room


func _capture(label: String) -> void:
	await process_frame
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(EVIDENCE_DIR + label + ".png")
	var error := root.get_texture().get_image().save_png(path)
	_check(error == OK, "evidence written: " + label)
