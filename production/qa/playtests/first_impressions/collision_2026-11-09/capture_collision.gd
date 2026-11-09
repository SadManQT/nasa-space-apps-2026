extends "probe_garden.gd"

const Habitat = preload("res://scripts/world/habitat_room_builder.gd")
const CandidatePath := "proposed_obstacles.json"
var overlay: MeshInstance3D
var heading: Label

func _run() -> void:
	root.size = Vector2i(1280, 720)
	room = Room.new()
	room.room_id = "LOC-03"
	room.build_navigation = false
	root.add_child(room)
	room.set_scene_context("EX-CH01-S11")
	var camera := Camera3D.new()
	room.add_child(camera)
	camera.position = Vector3(-5.75, 2.15, -0.2)
	camera.look_at(Vector3(-3.2, 0.8, -1.8))
	camera.fov = 77
	camera.current = true
	var capsule := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.27
	mesh.height = 1.7
	capsule.mesh = mesh
	capsule.position = Vector3(-4.4, 0.89, -2.2)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("20b8c9")
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	capsule.material_override = material
	room.add_child(capsule)
	var canvas := CanvasLayer.new()
	root.add_child(canvas)
	heading = Label.new()
	heading.position = Vector2(18, 16)
	heading.add_theme_font_size_override("font_size", 22)
	heading.add_theme_color_override("font_shadow_color", Color.BLACK)
	heading.add_theme_constant_override("shadow_offset_x", 2)
	heading.add_theme_constant_override("shadow_offset_y", 2)
	canvas.add_child(heading)
	await _shot("current", "CURRENT COLLISION - red physics boxes, blue production capsule\nStatic layout diagnostic; candidate position, not a recorded player replay")
	var base: String = get_script().resource_path.get_base_dir()
	var proposed: Array = JSON.parse_string(FileAccess.get_file_as_string(base.path_join(CandidatePath)))
	for spec in proposed:
		var body := room.collision_root.get_node_or_null(String(spec.id)) as StaticBody3D
		var at := Vector3(spec.position[0], spec.position[1], spec.position[2])
		var size := Vector3(spec.size[0], spec.size[1], spec.size[2])
		if body == null:
			Habitat.collider(room.collision_root, String(spec.id), at, size)
		else:
			body.position = at
			(body.get_child(0).shape as BoxShape3D).size = size
	await _shot("proposed", "PROPOSED COLLISION - geometry-only candidate, NOT APPLIED TO GAME\nBench/rack remain solid; exact reported movement still needs reproduction")
	room.free()
	canvas.free()
	await process_frame
	print("GARDEN COLLISION CAPTURE RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _shot(id: String, text: String) -> void:
	if overlay != null:
		overlay.free()
	heading.text = text
	overlay = MeshInstance3D.new()
	var lines := ImmediateMesh.new()
	var ink := StandardMaterial3D.new()
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ink.albedo_color = Color("ff6b6b")
	ink.no_depth_test = true
	lines.surface_begin(Mesh.PRIMITIVE_LINES, ink)
	for id_body in ["tara_bay", "tara_enclosure", "archive", "crop_rack"]:
		var body := room.collision_root.get_node_or_null(id_body) as StaticBody3D
		if body == null:
			continue
		var shape := body.get_child(0) as CollisionShape3D
		var half := (shape.shape as BoxShape3D).size * 0.5
		var corners: Array[Vector3] = []
		for i in range(8):
			corners.append(shape.global_position + Vector3(half.x if i & 1 else -half.x, half.y if i & 2 else -half.y, half.z if i & 4 else -half.z))
		for edge in [[0,1],[2,3],[4,5],[6,7],[0,2],[1,3],[4,6],[5,7],[0,4],[1,5],[2,6],[3,7]]:
			lines.surface_add_vertex(corners[edge[0]])
			lines.surface_add_vertex(corners[edge[1]])
	lines.surface_end()
	overlay.mesh = lines
	room.add_child(overlay)
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	var out := OS.get_environment("TEST_LOG_DIR")
	_check(root.get_texture().get_image().save_png(out.path_join("M1-65_collision_" + id + ".png")) == OK, "write " + id)
