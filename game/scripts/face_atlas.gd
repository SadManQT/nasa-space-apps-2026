extends Node
class_name FaceAtlas

const FACE_SHADER: Shader = preload("res://shaders/face_atlas.gdshader")
const FPS: float = 30.0
const MIN_HOLD: float = 2.0 / FPS
const ANTICIPATION: float = 0.04
const VISEME_TO_MOUTH: Dictionary = {
	"sil": 0, "PP": 1, "FF": 7, "TH": 8, "DD": 2, "kk": 2, "CH": 2, "SS": 2,
	"nn": 2, "RR": 5, "aa": 4, "E": 3, "I": 3, "O": 5, "U": 6,
}
static var _fallback_texture: Texture2D
const EXPRESSION_FRAMES: Dictionary = {
	"neutral": {"eye": 0, "brow": 0, "mouth": 0},
	"happy": {"eye": 3, "brow": 0, "mouth": 3},
	"worried": {"eye": 5, "brow": 3, "mouth": 1},
	"surprised": {"eye": 4, "brow": 1, "mouth": 4},
	"serious": {"eye": 0, "brow": 2, "mouth": 0},
}

enum BlinkPhase { WAIT, HALF_CLOSE, CLOSED, HALF_OPEN, DOUBLE_GAP }

@export var audio_player_path: NodePath
@export var mirror_left_eye: bool = false   # v7 atlases draw each eye for its own side (face_eyeL / face_eyeR)
@export var blink_enabled: bool = true
@export var expression: String = "neutral"

var _meshes: Dictionary = {}
var _materials: Dictionary = {}
var _body: MeshInstance3D
var _skeleton: Skeleton3D
var _head_bone := -1
var _head_forward := Vector3(0.0, 0.0, 1.0)
var _head_up := Vector3.UP
var _face_offset := Vector3(0.0, 0.07, 0.0)   # the face's centre in the head bone's frame
var _face_radius := 0.14
var _audio_player: Node
var _cues: Array[Dictionary] = []
var _duration: float = 0.0
var _line_active := false
var _line_clock := 0.0
var _last_audio_time := 0.0
var _line_had_started := false
var _current_mouth_frame := 0
var _expression_mouth_frame := 0
var _eye_frame := 0
var _brow_frame := 0
var _blink_phase: BlinkPhase = BlinkPhase.WAIT
var _blink_timer := 3.0
var _blink_elapsed := 0.0
var _blink_double := false
var _rng := RandomNumberGenerator.new()

signal line_finished

func _ready() -> void:
	_find_face_meshes(get_parent())
	_apply_face_materials()
	_resolve_audio()
	_rng.randomize()
	_schedule_blink()
	set_expression(expression)
	_process(0.0)

func setup(character: Node) -> void:
	if character == null:
		return
	_find_face_meshes(character)
	_apply_face_materials()
	_resolve_audio()
	set_expression(expression)

func set_expression(name: String) -> void:
	var key := name.to_lower()
	if not EXPRESSION_FRAMES.has(key):
		key = "neutral"
	expression = key
	var frames: Dictionary = EXPRESSION_FRAMES[key]
	_eye_frame = int(frames["eye"])
	_brow_frame = int(frames["brow"])
	_expression_mouth_frame = int(frames["mouth"])
	_update_eye_and_brow()
	if not _line_active:
		_set_mouth_frame(_expression_mouth_frame)

func play_line(stream: AudioStream, cues_path: String) -> bool:
	_resolve_audio()
	_line_active = false
	_line_clock = 0.0
	_last_audio_time = 0.0
	_line_had_started = false
	var valid := _load_cues(cues_path)
	_set_audio_stream(stream)
	_audio_play()
	_line_active = valid
	_line_had_started = valid
	set_process(true)
	return valid

func stop() -> void:
	_audio_stop()
	_line_active = false
	_line_had_started = false
	_set_mouth_frame(_expression_mouth_frame)

func seek(time: float) -> void:
	_line_clock = clampf(time, 0.0, _duration)
	_last_audio_time = _line_clock
	_audio_seek(_line_clock)
	_update_mouth_from_clock()

func mouth_frame_at(time: float) -> int:
	if _cues.is_empty() or time < 0.0 or (_duration > 0.0 and time >= _duration):
		return _expression_mouth_frame
	var index := -1
	for i in _cues.size():
		if time >= float(_cues[i]["effective"]):
			index = i
		else:
			break
	if index < 0:
		return _expression_mouth_frame
	while index > 0 and time < float(_cues[index - 1]["hold_until"]):
		index -= 1
	return int(_cues[index]["frame"])

func get_current_mouth_frame() -> int:
	return _current_mouth_frame

func get_blink_timer() -> float:
	return _blink_timer

func _process(delta: float) -> void:
	_update_blink(maxf(delta, 0.0))
	if not _line_active:
		_update_eye_and_brow()
		return
	_line_clock = _read_audio_time()
	if _duration > 0.0 and _line_clock >= _duration:
		_line_active = false
		_set_mouth_frame(_expression_mouth_frame)
		if _line_had_started:
			line_finished.emit()
		_line_had_started = false
		return
	_update_mouth_from_clock()

static func _get_fallback_texture() -> Texture2D:
	if _fallback_texture == null:
		var image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
		image.fill(Color.WHITE)
		_fallback_texture = ImageTexture.create_from_image(image)
	return _fallback_texture

# Where the face is and where it looks, for the toon shaders' smooth face lighting (body skin and face layers alike).
func _update_face_light() -> void:
	if _skeleton == null or _head_bone < 0 or not _skeleton.is_inside_tree():   # e.g. a character being swapped out
		return
	var head := _skeleton.global_transform * _skeleton.get_bone_global_pose(_head_bone)
	var forward := (head.basis * _head_forward).normalized()
	var centre := head * _face_offset
	var targets: Array = _materials.values()
	if _body != null and _body.get_active_material(0) is ShaderMaterial:
		targets.append(_body.get_active_material(0))
	for material in targets:
		(material as ShaderMaterial).set_shader_parameter("face_center", centre)
		(material as ShaderMaterial).set_shader_parameter("face_forward", forward)
		(material as ShaderMaterial).set_shader_parameter("face_radius", _face_radius)

func _find_face_meshes(character: Node = null) -> void:
	if character == null:
		character = self
	_body = character.find_child("Body", true, false) as MeshInstance3D
	if _skeleton != null and _skeleton.skeleton_updated.is_connected(_update_face_light):
		_skeleton.skeleton_updated.disconnect(_update_face_light)
	_skeleton = character.find_child("Skeleton3D", true, false) as Skeleton3D
	if _skeleton != null:   # after the modifiers (gaze, lean) have moved the head, so the light follows the visible face
		_skeleton.skeleton_updated.connect(_update_face_light)
	_head_bone = -1
	if _skeleton != null:
		for bone in _skeleton.get_bone_count():
			if _skeleton.get_bone_name(bone).ends_with("Head"):
				_head_bone = bone
				var rest := _skeleton.get_bone_global_rest(bone).basis.inverse()
				_head_forward = rest * Vector3(0.0, 0.0, 1.0)   # the character faces +Z in its rest pose
				_head_up = rest * Vector3.UP
				break
	_meshes.clear()
	for name in ["FaceEyeL", "FaceEyeR", "FaceMouth", "FaceBrowL", "FaceBrowR"]:
		var found := character.find_child(name, true, false) as MeshInstance3D
		if found != null:
			_meshes[name] = found
	_fit_face_light()

# The lit-as-one face spans the drawn face: centred between the eyes and the mouth, reaching past chin and brow.
func _fit_face_light() -> void:
	_face_offset = _head_up * 0.07
	_face_radius = 0.14
	var eyes: Array[Vector3] = []
	for name in ["FaceEyeL", "FaceEyeR"]:
		if _meshes.has(name):
			eyes.append(_rest_centre(_meshes[name]))
	if _head_bone < 0 or eyes.is_empty() or not _meshes.has("FaceMouth") or not is_inside_tree():
		return
	var eye := eyes[0] if eyes.size() == 1 else (eyes[0] + eyes[1]) * 0.5
	var mouth := _rest_centre(_meshes["FaceMouth"])
	var head_rest := _skeleton.global_transform * _skeleton.get_bone_global_rest(_head_bone)
	_face_offset = head_rest.affine_inverse() * ((eye + mouth) * 0.5)
	_face_radius = 2.0 * eye.distance_to(mouth)

func _rest_centre(mesh: MeshInstance3D) -> Vector3:
	return mesh.global_transform * mesh.get_aabb().get_center()

func _apply_face_materials() -> void:
	_materials.clear()
	for name in _meshes:
		var mesh := _meshes[name] as MeshInstance3D
		if mesh.mesh == null or mesh.mesh.get_surface_count() == 0:
			continue
		var current := mesh.get_active_material(0)
		if current is ShaderMaterial and (current as ShaderMaterial).shader == FACE_SHADER:
			_materials[name] = current   # applied already (_ready, then setup): keep it, its atlas came from the source material
			current.set_shader_parameter("mirror_left", name == "FaceEyeL" and mirror_left_eye)
			continue
		var source := current as StandardMaterial3D
		var material := ShaderMaterial.new()
		material.shader = FACE_SHADER
		material.set_shader_parameter("shadow_color", ToonMaterials.CHARACTER_SHADOW_COLOR)
		var atlas: Texture2D = source.albedo_texture if source != null and source.albedo_texture != null else _get_fallback_texture()
		material.set_shader_parameter("atlas", atlas)
		var cols := 3
		var rows := 3
		if String(name).begins_with("FaceEye"):
			cols = 3
			rows = 2
		elif String(name).begins_with("FaceBrow"):
			cols = 2
			rows = 2
		material.set_shader_parameter("cols", cols)
		material.set_shader_parameter("rows", rows)
		material.set_shader_parameter("alpha_cutoff", 0.08)
		material.set_shader_parameter("mirror_left", name == "FaceEyeL" and mirror_left_eye)
		mesh.set_surface_override_material(0, material)
		_materials[name] = material
	_update_eye_and_brow()
	_set_mouth_frame(_current_mouth_frame if _line_active else _expression_mouth_frame)

func _update_eye_and_brow() -> void:
	var eye := _eye_frame
	if _blink_phase == BlinkPhase.HALF_CLOSE or _blink_phase == BlinkPhase.HALF_OPEN:
		eye = 1
	elif _blink_phase == BlinkPhase.CLOSED:
		eye = 2
	for name in ["FaceEyeL", "FaceEyeR"]:
		if _materials.has(name):
			(_materials[name] as ShaderMaterial).set_shader_parameter("frame", eye)
	for name in ["FaceBrowL", "FaceBrowR"]:
		if _materials.has(name):
			(_materials[name] as ShaderMaterial).set_shader_parameter("frame", _brow_frame)

func _set_mouth_frame(value: int) -> void:
	_current_mouth_frame = clampi(value, 0, 8)
	if _materials.has("FaceMouth"):
		(_materials["FaceMouth"] as ShaderMaterial).set_shader_parameter("frame", _current_mouth_frame)

func _update_mouth_from_clock() -> void:
	_set_mouth_frame(mouth_frame_at(_line_clock))

func _schedule_blink() -> void:
	_blink_timer = _rng.randf_range(2.0, 6.0)

func _update_blink(delta: float) -> void:
	if not blink_enabled:
		_blink_phase = BlinkPhase.WAIT
		_blink_elapsed = 0.0
		_blink_double = false
		_update_eye_and_brow()
		return
	while delta > 0.0:
		if _blink_phase == BlinkPhase.WAIT:
			var step := minf(delta, _blink_timer)
			_blink_timer -= step
			delta -= step
			if _blink_timer > 0.000001:
				break
			_blink_phase = BlinkPhase.HALF_CLOSE
			_blink_double = _rng.randf() < 0.15
		else:
			var duration := 0.05
			if _blink_phase == BlinkPhase.CLOSED:
				duration = 0.04
			elif _blink_phase == BlinkPhase.HALF_OPEN:
				duration = 0.05
			elif _blink_phase == BlinkPhase.DOUBLE_GAP:
				duration = 0.08
			var step := minf(delta, duration - _blink_elapsed)
			_blink_elapsed += step
			delta -= step
			if _blink_elapsed < duration - 0.000001:
				_update_eye_and_brow()
				break
			_blink_elapsed = 0.0
			match _blink_phase:
				BlinkPhase.HALF_CLOSE: _blink_phase = BlinkPhase.CLOSED
				BlinkPhase.CLOSED: _blink_phase = BlinkPhase.HALF_OPEN
				BlinkPhase.HALF_OPEN:
					if _blink_double:
						_blink_double = false
						_blink_phase = BlinkPhase.DOUBLE_GAP
					else:
						_blink_phase = BlinkPhase.WAIT
						_schedule_blink()
				BlinkPhase.DOUBLE_GAP: _blink_phase = BlinkPhase.HALF_CLOSE
		_update_eye_and_brow()

func _load_cues(path: String) -> bool:
	_cues.clear()
	_duration = 0.0
	if not FileAccess.file_exists(path):
		push_warning("FaceAtlas cue file not found: " + path)
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return false
	var root: Dictionary = parsed
	var raw_duration: Variant = root.get("duration", 0.0)
	var raw_cues: Variant = root.get("cues", [])
	if not _is_number(raw_duration) or not raw_cues is Array:
		return false
	_duration = maxf(float(raw_duration), 0.0)
	var last := -INF
	for raw in raw_cues as Array:
		if not raw is Dictionary:
			return false
		var cue: Dictionary = raw
		if not _is_number(cue.get("t")) or not cue.get("shape", "") is String:
			return false
		var t := float(cue["t"])
		if t < 0.0 or t > _duration or t < last:
			return false
		last = t
		var shape := String(cue["shape"]).trim_prefix("viseme_")
		_cues.append({"effective": maxf(0.0, t - ANTICIPATION), "frame": int(VISEME_TO_MOUTH.get(shape, 0)), "hold_until": 0.0})
	for i in _cues.size():
		var next_effective := _duration
		if i + 1 < _cues.size():
			next_effective = float(_cues[i + 1]["effective"])
		var minimum_hold := MIN_HOLD if int(_cues[i]["frame"]) != 0 else 0.0
		_cues[i]["hold_until"] = maxf(next_effective, float(_cues[i]["effective"]) + minimum_hold)
	return true

func _resolve_audio() -> void:
	if _audio_player != null:
		return
	if not audio_player_path.is_empty():
		_audio_player = get_node_or_null(audio_player_path)
	if _audio_player == null:
		for candidate in find_children("*", "AudioStreamPlayer", true, false):
			_audio_player = candidate
			break

func _set_audio_stream(stream: AudioStream) -> void:
	if _audio_player is AudioStreamPlayer:
		(_audio_player as AudioStreamPlayer).stream = stream
	elif _audio_player is AudioStreamPlayer3D:
		(_audio_player as AudioStreamPlayer3D).stream = stream

func _audio_play() -> void:
	if _audio_player is AudioStreamPlayer:
		(_audio_player as AudioStreamPlayer).play()
	elif _audio_player is AudioStreamPlayer3D:
		(_audio_player as AudioStreamPlayer3D).play()

func _audio_stop() -> void:
	if _audio_player is AudioStreamPlayer:
		(_audio_player as AudioStreamPlayer).stop()
	elif _audio_player is AudioStreamPlayer3D:
		(_audio_player as AudioStreamPlayer3D).stop()

func _audio_seek(time: float) -> void:
	if _audio_player is AudioStreamPlayer:
		(_audio_player as AudioStreamPlayer).seek(time)
	elif _audio_player is AudioStreamPlayer3D:
		(_audio_player as AudioStreamPlayer3D).seek(time)

func _read_audio_time() -> float:
	if _audio_player == null:
		return _line_clock
	var raw := 0.0
	if _audio_player is AudioStreamPlayer:
		raw = (_audio_player as AudioStreamPlayer).get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
	elif _audio_player is AudioStreamPlayer3D:
		raw = (_audio_player as AudioStreamPlayer3D).get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
	raw = maxf(raw, 0.0)
	if raw < _last_audio_time:
		raw = _last_audio_time
	_line_clock = raw
	_last_audio_time = raw
	return _line_clock

func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT
