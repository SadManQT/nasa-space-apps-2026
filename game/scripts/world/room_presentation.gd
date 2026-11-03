extends RefCounted
class_name RoomPresentation

const Toon = preload("res://scripts/toon_materials.gd")
const Geometry = preload("res://scripts/asset_geometry.gd")

static func vector(value: Array) -> Vector3:
	return Vector3(float(value[0]), float(value[1]), float(value[2]))

static func mesh_box(parent: Node3D, id: String, position: Vector3, size: Vector3, color: Color, luminous: bool = false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = id
	mesh.position = position
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	if luminous:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.material_override = material
	parent.add_child(mesh, true)
	if not luminous:
		# ToonMaterials reads surface materials, so put this source on the mesh.
		mesh.material_override = null
		box.material = material
		Toon.apply_to_mesh(mesh, false, false)
	return mesh

static func build(room: Node3D, layout: Dictionary, vacuum: bool) -> void:
	var lighting := Node3D.new()
	lighting.name = "RoomLighting"
	room.add_child(lighting)
	var settings: Dictionary = layout.get("lighting", {})
	var world := WorldEnvironment.new()
	world.name = "RoomEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#05060A")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#95A3BC")
	environment.ambient_light_energy = float(settings.get("ambient_energy", 0.0 if vacuum else 0.3))
	environment.fog_enabled = false
	environment.volumetric_fog_enabled = false
	world.environment = environment
	lighting.add_child(world)
	var key := DirectionalLight3D.new()
	key.name = "KeyLight"
	key.rotation_degrees = vector(settings.get("key_rotation_degrees", [-4, -35, 0] if vacuum else [-65, -25, 0]))
	key.light_color = Color(settings.get("key_color", "#FFFFFF"))
	key.light_energy = float(settings.get("key_energy", 1.6))
	key.shadow_enabled = true
	key.directional_shadow_max_distance = 160.0 if vacuum else 40.0
	key.light_size = 0.0
	lighting.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.name = "FillLight"
	fill.rotation_degrees = Vector3(-25, 145, 0)
	fill.light_color = Color("#B9D7FF")
	fill.light_energy = float(settings.get("fill_energy", 0.0 if vacuum else 0.45))
	lighting.add_child(fill)
	if layout.is_empty():
		return
	var visuals := room.get_node("VisualRoot") as Node3D
	for fixture in layout.get("fixtures", []):
		var mesh := mesh_box(visuals, fixture.id, vector(fixture.position), vector(fixture.size), Color(fixture.color))
		if bool(fixture.get("transparent", false)):
			var glass := StandardMaterial3D.new()
			glass.albedo_color = Color(0.55, 0.82, 0.9, 0.13)
			glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			glass.cull_mode = BaseMaterial3D.CULL_DISABLED
			glass.roughness = 0.25
			mesh.material_override = glass
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var frame := selection_frame(mesh, Geometry.bounds(mesh), Color("#A8D8E5"))
			frame.name = "PressureEnclosureFrame"
	if vacuum:
		return
	var bounds: Array = layout.bounds_m
	var width := float(bounds[0])
	var depth := float(bounds[1])
	var height := float(layout.ceiling_height_m)
	var accent := Color(layout.accent_color)
	for x in [-width * 0.25, width * 0.25]:
		for z in [-depth * 0.25, depth * 0.25]:
			mesh_box(visuals, "CeilingStrip", Vector3(x, height - 0.09, z), Vector3(width * 0.28, 0.04, 0.13), Color(settings.strip_color), true)
	# Repeating seams make the shell's scale and corners visible from the camera.
	for x in range(int(-width * 0.5) + 1, int(width * 0.5), 2):
		mesh_box(visuals, "WallSeam", Vector3(x, height * 0.5, -depth * 0.5 + 0.11), Vector3(0.035, height, 0.025), Color("#263343"))
	mesh_box(visuals, "FloorGuide", Vector3(0, 0.015, -depth * 0.5 + 0.25), Vector3(width - 0.4, 0.02, 0.06), accent, true)
	var title := Label3D.new()
	title.text = String(layout.room_id) + " / " + String(room.get_meta("room_name", "AURORA")).to_upper()
	title.position = Vector3(0, height - 0.65, -depth * 0.5 + 0.18)
	title.font_size = 52
	title.pixel_size = 0.005
	title.modulate = accent
	visuals.add_child(title)

static func selection_frame(parent: Node3D, bounds: AABB, color: Color = Color("#F2C230")) -> Node3D:
	var frame := Node3D.new()
	frame.name = "SelectionFrame"
	parent.add_child(frame)
	var box := bounds.grow(0.06)
	var start := box.position
	var end := box.end
	var center := box.get_center()
	for x in [start.x, end.x]:
		for y in [start.y, end.y]:
			mesh_box(frame, "Edge", Vector3(x, y, center.z), Vector3(0.012, 0.012, box.size.z), color, true)
	for x in [start.x, end.x]:
		for z in [start.z, end.z]:
			mesh_box(frame, "Edge", Vector3(x, center.y, z), Vector3(0.012, box.size.y, 0.012), color, true)
	for y in [start.y, end.y]:
		for z in [start.z, end.z]:
			mesh_box(frame, "Edge", Vector3(center.x, y, z), Vector3(box.size.x, 0.012, 0.012), color, true)
	return frame
