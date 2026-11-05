extends RefCounted
class_name RoomPresentation

const Toon = preload("res://scripts/toon_materials.gd")
const Geometry = preload("res://scripts/asset_geometry.gd")

## Converts an authored metre-space vector from the room data.
static func vector(value: Array) -> Vector3:
	return Vector3(float(value[0]), float(value[1]), float(value[2]))

## Builds a fixture; habitat assemblies retain standard physically based materials.
static func mesh_box(parent: Node3D, id: String, position: Vector3, size: Vector3, color: Color, luminous: bool = false, pbr: bool = false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = id
	mesh.position = position
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	if pbr and not luminous:
		material = (load("res://assets/environment/kit/materials/M_Kit_PaintWhite.tres") as StandardMaterial3D).duplicate()
		# A BoxMesh maps 0..1 across each face; triplanar (with the kit's uv1_scale) keeps the paint
		# grain at the kit walls' density on fixtures of any size instead of stretching it into ripples.
		material.uv1_triplanar = true
	material.albedo_color = color
	# Kit paint keeps the walls' texture-driven roughness (x1.0); a lower multiplier turned large
	# fixtures into lamp mirrors.
	material.roughness = 1.0 if pbr else 0.95
	if luminous:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.material_override = material
	parent.add_child(mesh, true)
	if not luminous and not pbr:
		# ToonMaterials reads surface materials, so put this source on the mesh.
		mesh.material_override = null
		box.material = material
		Toon.apply_to_mesh(mesh, false, false)
	return mesh

## Stages the room's authored fixtures and static, bounded practical-light rig.
static func build(room: Node3D, layout: Dictionary, vacuum: bool) -> void:
	var habitat: bool = layout.get("assembly") == "habitat_kit"
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
	if habitat:
		environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	world.environment = environment
	lighting.add_child(world)
	var key := DirectionalLight3D.new()
	key.name = "KeyLight"
	key.rotation_degrees = vector(settings.get("key_rotation_degrees", [-4, -35, 0] if vacuum else [-65, -25, 0]))
	key.light_color = Color(settings.get("key_color", "#FFFFFF"))
	key.light_energy = float(settings.get("key_energy", 1.6))
	key.shadow_enabled = not habitat
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
	for spec in layout.get("fixtures", []):
		fixture(visuals, spec, habitat)
	if vacuum:
		return
	if habitat:
		_build_practicals(room, layout)
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
	title.text = String(room.get_meta("room_name", "Aurora"))  # a wall sign in player words; no location IDs (doc 25 §1)
	title.position = Vector3(0, height - 0.65, -depth * 0.5 + 0.18)
	title.font_size = 52
	title.pixel_size = 0.005
	title.modulate = accent
	visuals.add_child(title)

## Builds one authored fixture box (habitat rooms keep PBR kit paint; "finish" swaps in a display or satin
## surface; "transparent" makes it pressure glazing with a visible frame). Shared by the base layout and the
## chapter staging.
static func fixture(parent: Node3D, spec: Dictionary, habitat: bool) -> MeshInstance3D:
	var mesh := mesh_box(parent, spec.id, vector(spec.position), vector(spec.size), Color(spec.color), bool(spec.get("emissive", false)), habitat)
	if habitat and spec.has("finish"):
		mesh.material_override = finish_material(String(spec.finish), Color(spec.color))
	if bool(spec.get("transparent", false)):
		var glass := StandardMaterial3D.new()
		glass.albedo_color = Color(0.55, 0.82, 0.9, 0.13)
		glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glass.cull_mode = BaseMaterial3D.CULL_DISABLED
		glass.roughness = 0.25
		mesh.material_override = glass
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var frame := selection_frame(mesh, Geometry.bounds(mesh), Color("#A8D8E5"))
		frame.name = "PressureEnclosureFrame"
	return mesh

## Builds one authored wall sign: single-sided, so a sign authored facing the wrong way disappears instead of
## reading mirrored. Optional "yaw", "pitch" (-90 lays it on a table, top edge away from the reader), "size"
## (pixel size), "font_size", "color" (default: the room accent) and "wrap_m" (word-wrap width in metres).
static func wall_sign(parent: Node3D, spec: Dictionary, layout: Dictionary) -> Label3D:
	var label := Label3D.new()
	label.text = spec.text
	label.position = vector(spec.position)
	label.rotation_degrees = Vector3(float(spec.get("pitch", 0)), float(spec.get("yaw", 0)), 0)
	label.double_sided = false
	label.font_size = int(spec.get("font_size", 40))
	label.pixel_size = float(spec.get("size", 0.0025))
	label.modulate = Color(spec.get("color", layout.get("accent_color", "#ffffff")))
	if spec.has("wrap_m"):
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.width = float(spec.wrap_m) / label.pixel_size
	parent.add_child(label)
	return label

## A smooth, untextured surface for authored fixtures whose kit paint texture would read wrong:
## "screen" is an unlit display behind dark glass, "satin" a painted board with no paint grain.
static func finish_material(finish: String, color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	match finish:
		"screen":
			# Anti-glare glass: a soft sheen rather than mirror-hard lamp highlights.
			material.roughness = 0.32
			material.metallic_specular = 0.35
			material.emission_enabled = true
			material.emission = color.lightened(0.1)
			material.emission_energy_multiplier = 0.2
		_:
			material.roughness = 0.55
	return material

## Draws an accessible selection outline without modifying the source material.
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

## Compatibility (OpenGL) supports only cube shadows for omni lights; asking for dual-paraboloid there logs an
## error per light per frame (M1-76: 560 errors entering the Commons on Intel Arc). Forward+ and Mobile keep the
## measured two-pass dual-paraboloid saving.
static func omni_shadow_mode_for(rendering_method: String) -> OmniLight3D.ShadowMode:
	return OmniLight3D.SHADOW_CUBE if rendering_method == "gl_compatibility" else OmniLight3D.SHADOW_DUAL_PARABOLOID

static func _build_practicals(room: Node3D, layout: Dictionary) -> void:
	var settings: Dictionary = layout.lighting
	for index in layout.ceiling_strips.size():
		var at := vector(layout.ceiling_strips[index])
		# Preserve the four named fixture clusters used by presentation/QA callers.
		mesh_box(room.visual_root, "CeilingStrip", at, Vector3(1.8, 0.04, 0.14), Color(settings.strip_color), true, true)
		var light := OmniLight3D.new()
		light.name = "Practical_%d" % index
		light.position = at - Vector3(0, 0.35, 0)
		light.light_color = Color(settings.key_color)
		light.light_energy = float(settings.practical_energy)
		light.omni_range = float(settings.practical_range_m)
		light.shadow_enabled = index < int(settings.shadow_lights)
		# Dual-paraboloid shadows take two passes instead of a cube's six; with the staged cast in
		# LOC-01 this measured 18.3 -> 16.7 ms p50 (vsync). The light's axis points down so the
		# paraboloid seam lies in the horizontal plane at fixture height, away from floor shadows.
		light.omni_shadow_mode = omni_shadow_mode_for(RenderingServer.get_current_rendering_method())
		light.rotation_degrees.x = -90.0
		light.light_size = 0.16
		room.get_node("RoomLighting").add_child(light)
	# Local practicals (e.g. growth lamps inside a plant enclosure) light only their own fixture's
	# neighbourhood and cast no shadows.
	for spec in layout.get("local_lights", []):
		var lamp := OmniLight3D.new()
		lamp.name = String(spec.id)
		lamp.position = vector(spec.position)
		lamp.light_color = Color(spec.color)
		lamp.light_energy = float(spec.energy)
		lamp.omni_range = float(spec.range_m)
		lamp.shadow_enabled = false
		room.get_node("RoomLighting").add_child(lamp)
	for spec in layout.get("signs", []):
		wall_sign(room.visual_root, spec, layout)
