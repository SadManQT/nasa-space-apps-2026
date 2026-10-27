extends Node
class_name ToonMaterials

const CHARACTER_SHADER: Shader = preload("res://shaders/toon_character.gdshader")
const WORLD_SHADER: Shader = preload("res://shaders/toon_world.gdshader")
const OUTLINE_SHADER: Shader = preload("res://shaders/toon_outline.gdshader")
const CHARACTER_SHADOW_COLOR := Color("#59405f")
static var _fallback_texture: Texture2D

static func apply_to_tree(root: Node, characters: bool = false, add_outlines: bool = true) -> int:
	if root == null:
		return 0
	var count := 0
	if root is MeshInstance3D:
		count += _apply_mesh(root as MeshInstance3D, characters, add_outlines)
	for node in root.find_children("*", "MeshInstance3D", true, false):
		count += _apply_mesh(node as MeshInstance3D, characters, add_outlines)
	return count

static func apply_to_mesh(mesh_instance: MeshInstance3D, characters: bool = false, add_outlines: bool = true) -> int:
	return _apply_mesh(mesh_instance, characters, add_outlines)

static func _apply_mesh(mesh_instance: MeshInstance3D, characters: bool, add_outlines: bool) -> int:
	if mesh_instance == null or mesh_instance.mesh == null:
		return 0
	# Face layers use their atlas shader and must keep their cell uniforms.
	if mesh_instance.name.begins_with("Face"):
		return 0
	var changed := 0
	for surface in mesh_instance.mesh.get_surface_count():
		var source := mesh_instance.get_active_material(surface) as StandardMaterial3D
		if source == null:
			continue
		# shortcut: keep translucent decals/glass intact until a toon transparency pass exists.
		if source.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
			continue
		var styled := ShaderMaterial.new()
		styled.shader = CHARACTER_SHADER if characters else WORLD_SHADER
		var fallback := _get_fallback_texture()
		styled.set_shader_parameter("base_texture", fallback)
		styled.set_shader_parameter("normal_texture", fallback)
		styled.set_shader_parameter("base_color", source.albedo_color)
		styled.set_shader_parameter("roughness_value", source.roughness)
		# These diffuse toon shaders paint metal in albedo; scalar metal also suppresses their light.
		styled.set_shader_parameter("metallic_value", 0.0)
		if source.albedo_texture != null:
			_ensure_mipmaps(source.albedo_texture)
			styled.set_shader_parameter("base_texture", source.albedo_texture)
			styled.set_shader_parameter("use_base_texture", true)
		if source.normal_enabled and source.normal_texture != null:
			_ensure_mipmaps(source.normal_texture)
			styled.set_shader_parameter("normal_texture", source.normal_texture)
			styled.set_shader_parameter("use_normal_texture", true)
			styled.set_shader_parameter("normal_scale_value", source.normal_scale)
		if characters:
			styled.set_shader_parameter("hair_specular", _looks_like_hair(mesh_instance, source))
			styled.set_shader_parameter("shadow_color", CHARACTER_SHADOW_COLOR)
		else:
			styled.set_shader_parameter("shadow_color", Color("#62586d"))
		if add_outlines:
			var outline := ShaderMaterial.new()
			outline.shader = OUTLINE_SHADER
			outline.set_shader_parameter("base_texture", fallback)
			outline.set_shader_parameter("base_color", source.albedo_color)
			outline.set_shader_parameter("outline_width", 0.0022 if characters else 0.0014)
			outline.set_shader_parameter("outline_darkness", 0.72 if characters else 0.6)
			if source.albedo_texture != null:
				outline.set_shader_parameter("base_texture", source.albedo_texture)
				outline.set_shader_parameter("use_base_texture", true)
			styled.next_pass = outline
		mesh_instance.set_surface_override_material(surface, styled)
		changed += 1
	return changed

# GLBs loaded at runtime (AssetGeometry.load_glb) bring full-size images only: without mipmaps distant detail
# sparkles and the world shader's cel flatten has no blurred level to read. Built once, in place, per texture.
static func _ensure_mipmaps(texture: Texture2D) -> void:
	if not texture is ImageTexture:
		return
	var image := texture.get_image()
	if image == null or image.has_mipmaps() or image.is_compressed():
		return
	image.generate_mipmaps()
	(texture as ImageTexture).set_image(image)

static func _looks_like_hair(mesh_instance: MeshInstance3D, source: StandardMaterial3D) -> bool:
	var mesh_name := mesh_instance.name.to_lower()
	var material_name := source.resource_name.to_lower()
	return mesh_name.contains("hair") or material_name.contains("hair")

static func _get_fallback_texture() -> Texture2D:
	if _fallback_texture == null:
		var image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
		image.fill(Color.WHITE)
		_fallback_texture = ImageTexture.create_from_image(image)
	return _fallback_texture
