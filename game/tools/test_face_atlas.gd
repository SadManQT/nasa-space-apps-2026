# Run: Godot --headless --path game --script res://tools/test_face_atlas.gd
extends SceneTree

var _checks := 0
var _failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var root := Node3D.new()
	for name in ["FaceEyeL", "FaceEyeR", "FaceMouth", "FaceBrowL"]:
		var mesh := MeshInstance3D.new()
		mesh.name = name
		mesh.mesh = QuadMesh.new()
		var material := StandardMaterial3D.new()
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_texture = _atlas_texture()
		mesh.set_surface_override_material(0, material)
		root.add_child(mesh)
	var face := FaceAtlas.new()
	face.name = "FaceAtlas"
	root.add_child(face)
	get_root().add_child(root)
	_check(face._meshes.size() == 4, "finds available face layers and tolerates missing FaceBrowR")
	_check(face._materials.size() == 4, "atlas shader materials are installed on the layers")
	var atlas_before = (face._materials["FaceMouth"] as ShaderMaterial).get_shader_parameter("atlas")
	face.setup(root)
	_check(atlas_before != FaceAtlas._get_fallback_texture() and (face._materials["FaceMouth"] as ShaderMaterial).get_shader_parameter("atlas") == atlas_before, "setup after _ready keeps each layer's own atlas")
	var eye := face._materials["FaceEyeL"] as ShaderMaterial
	_check(not face.mirror_left_eye and not eye.get_shader_parameter("mirror_left"), "v7 left eye uses its own unmirrored atlas")
	face.mirror_left_eye = true
	face.setup(root)
	_check(face._materials["FaceEyeL"] == eye and eye.get_shader_parameter("mirror_left"), "repeated setup updates mirroring without replacing the material")
	_check(eye.get_shader_parameter("shadow_color") == ToonMaterials.CHARACTER_SHADOW_COLOR, "face and character share the same shadow tint")
	face._line_active = true
	face._set_mouth_frame(6)
	face.setup(root)
	_check(face.get_current_mouth_frame() == 6, "repeated setup preserves the current speech mouth")
	face._line_active = false
	var bare := root.get_node("FaceBrowL") as MeshInstance3D
	bare.set_surface_override_material(0, StandardMaterial3D.new())
	face.setup(root)
	_check((face._materials["FaceBrowL"] as ShaderMaterial).get_shader_parameter("atlas") != null, "untextured source gets a valid fallback atlas")
	_check(face._load_cues("res://tools/test_data/kai_test_visemes.json"), "loads the Kai Rhubarb cue JSON")
	_check(face.mouth_frame_at(0.03) == 3, "anticipates the E cue by 40 ms")
	_check(face.mouth_frame_at(0.12) == 2, "maps SS to the B mouth cell")
	var custom := _cue_file()
	_check(face._load_cues(custom), "loads a short timing fixture")
	_check(face.mouth_frame_at(0.02) == 0 and face.mouth_frame_at(0.12) == 4, "holds each snapped mouth shape for at least two 30 fps frames")
	face.set_expression("happy")
	_check(face._expression_mouth_frame == 3 and face._eye_frame == 3 and face._brow_frame == 0, "happy expression sets eye, brow and default mouth cells")
	face._blink_timer = 0.0
	face._process(0.05)
	_check(face._blink_phase == FaceAtlas.BlinkPhase.CLOSED or face._blink_phase == FaceAtlas.BlinkPhase.HALF_CLOSE, "blink scheduler enters a short half-close/closed sequence")
	var gaps: Array[float] = []
	face._rng.seed = 42
	for i in 100:
		face._schedule_blink()
		gaps.append(face._blink_timer)
	_check(gaps.all(func(value: float): return value >= 2.0 and value <= 6.0), "blink interval remains within 2-6 seconds")
	_check(face.mouth_frame_at(-1.0) == 3, "expression mouth is used before speech starts")
	root.free()
	DirAccess.remove_absolute(custom)
	print("PASS FaceAtlas (%d checks, %d cue frames checked)" % [_checks, 16])
	quit(1 if _failures > 0 else 0)

func _atlas_texture() -> Texture2D:
	var image := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	return ImageTexture.create_from_image(image)

func _cue_file() -> String:
	var path := OS.get_temp_dir().path_join("face_atlas_%d.json" % OS.get_process_id())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"duration": 0.2, "cues": [
		{"t": 0.0, "shape": "viseme_sil", "weight": 1.0},
		{"t": 0.1, "shape": "viseme_aa", "weight": 1.0}
	]}))
	file.close()
	return path

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("  ok ", message)
	else:
		_failures += 1
		push_error("FAIL " + message)
