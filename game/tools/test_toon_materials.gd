# Run: Godot --headless --path game --script res://tools/test_toon_materials.gd
extends SceneTree

var _checks := 0
var _failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var root := Node3D.new()
	var body := MeshInstance3D.new()
	body.mesh = BoxMesh.new()
	var source := StandardMaterial3D.new()
	source.albedo_color = Color("#d98b68")
	source.roughness = 0.55
	body.set_surface_override_material(0, source)
	root.add_child(body)
	var face := MeshInstance3D.new()
	face.name = "FaceMouth"
	face.mesh = QuadMesh.new()
	face.set_surface_override_material(0, StandardMaterial3D.new())
	root.add_child(face)
	get_root().add_child(root)
	var changed := ToonMaterials.apply_to_tree(root, true)
	_check(changed == 1, "character helper swaps one body material and preserves atlas face layers")
	var styled := body.get_active_material(0) as ShaderMaterial
	_check(styled != null and styled.shader == ToonMaterials.CHARACTER_SHADER, "character shader is assigned")
	_check(styled != null and styled.next_pass is ShaderMaterial, "character material receives an inverted-hull outline next pass")
	_check(face.get_active_material(0) is StandardMaterial3D, "FaceMouth remains available for FaceAtlas")
	var world := MeshInstance3D.new()
	world.mesh = BoxMesh.new()
	world.set_surface_override_material(0, StandardMaterial3D.new())
	root.add_child(world)
	_check(ToonMaterials.apply_to_mesh(world, false, true) == 1 and (world.get_active_material(0) as ShaderMaterial).shader == ToonMaterials.WORLD_SHADER, "world helper uses the softer world shader")
	for textured in [false, true]:
		var metal := StandardMaterial3D.new()
		metal.metallic = 1.0
		metal.normal_texture = ToonMaterials._get_fallback_texture()
		if textured:
			metal.metallic_texture = ToonMaterials._get_fallback_texture()
		world.set_surface_override_material(0, metal)
		ToonMaterials.apply_to_mesh(world, false, false)
		var converted := world.get_active_material(0) as ShaderMaterial
		_check(converted.get_shader_parameter("metallic_value") == 0.0, "scalar and texture metal retain diffuse toon light (texture=%s)" % textured)
		_check(not converted.get_shader_parameter("use_normal_texture"), "disabled normal map stays disabled")
		_check(ToonMaterials.apply_to_mesh(world, false, false) == 0 and world.get_active_material(0) == converted, "toon conversion is idempotent")
	var decal := StandardMaterial3D.new()
	decal.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	world.set_surface_override_material(0, decal)
	_check(ToonMaterials.apply_to_mesh(world, true, true) == 0 and world.get_active_material(0) == decal, "transparent patch edges survive the opaque toon conversion")
	print("PASS ToonMaterials (%d checks, %d swapped materials)" % [_checks, changed + 1])
	root.free()
	quit(1 if _failures > 0 else 0)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("  ok ", message)
	else:
		_failures += 1
		push_error("FAIL " + message)
