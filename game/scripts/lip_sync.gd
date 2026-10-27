# Drives face blend shapes from a Rhubarb cue file and the audio clock.
extends Node
class_name LipSync

signal line_finished

const VISEME_NAMES: Array[String] = [
	"viseme_sil", "viseme_PP", "viseme_FF", "viseme_TH", "viseme_DD", "viseme_kk",
	"viseme_CH", "viseme_SS", "viseme_nn", "viseme_RR", "viseme_aa", "viseme_E",
	"viseme_I", "viseme_O", "viseme_U", "jawOpen"
]
const OPENING_SHAPES: Array[String] = [
	"viseme_aa", "viseme_E", "viseme_I", "viseme_O", "viseme_U", "viseme_DD",
	"viseme_kk", "viseme_CH", "viseme_SS", "viseme_nn", "viseme_RR", "viseme_TH", "jawOpen"
]
const PP_MIN_HOLD: float = 0.05
const FF_MIN_HOLD: float = 0.04

@export var face_mesh_path: NodePath
@export var audio_player_path: NodePath
@export_range(0.0, 0.2, 0.001) var anticipation: float = 0.04
@export_range(0.0, 0.2, 0.001) var attack: float = 0.025
@export_range(0.0, 0.3, 0.001) var hold: float = 0.05
@export_range(0.0, 0.5, 0.001) var release: float = 0.08
@export_range(0.0, 0.3, 0.001) var interruption_fade: float = 0.08

var _face_mesh: MeshInstance3D
var _audio_player: Node
var _mixer: Node
var _blend_indices: Dictionary = {}
var _shape_names: Array[String] = VISEME_NAMES.duplicate()
var _cues: Array[Dictionary] = []
var _env: Array[float] = []
var _duration: float = 0.0
var _line_active: bool = false
var _line_valid: bool = false
var _line_clock: float = 0.0
var _last_audio_time: float = 0.0
var _seek_pending: bool = false
var _seek_target: float = 0.0
var _line_had_started: bool = false
var _releasing: bool = false
var _release_elapsed: float = 0.0
var _release_from: Dictionary = {}
var _crossfade_active: bool = false
var _crossfade_elapsed: float = 0.0
var _crossfade_from: Dictionary = {}
var _working_weights: Dictionary = {}
var _current_weights: Dictionary = {}

func _ready() -> void:
	_reset_dictionary(_working_weights)
	_reset_dictionary(_current_weights)

func play_line(stream: AudioStream, cues_path: String) -> void:
	_resolve_nodes()
	_cache_blend_shapes()
	var was_active := _line_active or _releasing
	if was_active:
		_copy_weights(_current_weights, _crossfade_from)
	_crossfade_active = was_active and interruption_fade > 0.0
	_crossfade_elapsed = 0.0
	_releasing = false
	_line_clock = 0.0
	_last_audio_time = 0.0
	_seek_pending = false
	_line_had_started = true
	_line_valid = _load_cues(cues_path)
	_set_audio_stream(stream)
	_audio_play()
	_line_active = true
	set_process(true)
	if not _crossfade_active:
		_reset_dictionary(_current_weights)

func stop(immediate: bool = false) -> void:
	if _audio_player != null:
		_audio_stop()
	_line_active = false
	if immediate:
		_releasing = false
		_reset_dictionary(_current_weights)
		_apply_weights(_current_weights)
		set_process(false)
		return
	if _line_had_started or _releasing:
		_begin_release()
	else:
		_reset_dictionary(_current_weights)
		_apply_weights(_current_weights)
		set_process(false)

func pause() -> void:
	_set_stream_paused(true)

func resume() -> void:
	_set_stream_paused(false)

func seek(time: float) -> void:
	var target := maxf(time, 0.0)
	if _duration > 0.0:
		target = minf(target, _duration)
	_audio_seek(target)
	_line_clock = target
	_last_audio_time = target
	_seek_target = target
	_seek_pending = true
	if _line_active:
		_evaluate_into(_line_clock, _working_weights)
		_copy_weights(_working_weights, _current_weights)
		_apply_weights(_current_weights)

# Returns deterministic speech weights without reading the audio device.
func weights_at(time: float) -> Dictionary:
	var result: Dictionary = {}
	_reset_dictionary(result)
	if not _line_valid or time < 0.0 or (_duration > 0.0 and time >= _duration):
		return result
	_evaluate_into(time, result)
	return result

func get_current_weights() -> Dictionary:
	return _current_weights.duplicate()

func get_current_envelope() -> float:
	return _envelope_at(_line_clock)

func set_mixer(mixer: Node) -> void:
	_mixer = mixer

func clear_mixer(mixer: Node) -> void:
	if _mixer == mixer:
		_mixer = null

func _process(delta: float) -> void:
	if _releasing:
		_release_elapsed += delta
		var release_alpha := clampf(_release_elapsed / maxf(release, 0.001), 0.0, 1.0)
		for shape in _shape_names:
			_current_weights[shape] = lerpf(float(_release_from.get(shape, 0.0)), 0.0, release_alpha)
		_apply_weights(_current_weights)
		if release_alpha >= 1.0:
			_releasing = false
			_line_had_started = false
			_reset_dictionary(_current_weights)
			set_process(false)
		return
	if not _line_active:
		return
	var audio_time := _read_audio_time()
	if _line_valid and _duration > 0.0 and audio_time >= _duration:
		_evaluate_into(_duration - 0.000001, _working_weights)
		_copy_weights(_working_weights, _current_weights)
		_apply_weights(_current_weights)
		_begin_release()
		return
	if not _line_valid and not _audio_is_playing():
		_begin_release()
		return
	_evaluate_into(audio_time, _working_weights)
	if _crossfade_active:
		_crossfade_elapsed += delta
		var crossfade_alpha := clampf(_crossfade_elapsed / maxf(interruption_fade, 0.001), 0.0, 1.0)
		for shape in _shape_names:
			_current_weights[shape] = lerpf(float(_crossfade_from.get(shape, 0.0)), float(_working_weights.get(shape, 0.0)), crossfade_alpha)
		if crossfade_alpha >= 1.0:
			_crossfade_active = false
	else:
		_copy_weights(_working_weights, _current_weights)
	_apply_weights(_current_weights)

func _begin_release() -> void:
	if _releasing:
		return
	_line_active = false
	_release_elapsed = 0.0
	_copy_weights(_current_weights, _release_from)
	_releasing = release > 0.0 and not _weights_are_zero(_release_from)
	if _line_had_started:
		line_finished.emit()
		_line_had_started = false
	if not _releasing:
		_reset_dictionary(_current_weights)
		_apply_weights(_current_weights)
		set_process(false)

func _read_audio_time() -> float:
	if _stream_paused():
		return _line_clock
	var raw := _audio_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
	raw = maxf(raw, 0.0)
	if _seek_pending:
		if absf(raw - _seek_target) <= 0.08:
			_seek_pending = false
		else:
			return _line_clock
	if raw < _last_audio_time:
		raw = _last_audio_time
	_line_clock = raw
	_last_audio_time = raw
	return _line_clock

func _resolve_nodes() -> void:
	if _face_mesh == null and not face_mesh_path.is_empty():
		_face_mesh = get_node_or_null(face_mesh_path) as MeshInstance3D
	if _audio_player == null and not audio_player_path.is_empty():
		var candidate := get_node_or_null(audio_player_path)
		if candidate is AudioStreamPlayer or candidate is AudioStreamPlayer3D:
			_audio_player = candidate

func _load_cues(path: String) -> bool:
	_cues.clear()
	_env.clear()
	_shape_names = VISEME_NAMES.duplicate()
	_duration = 0.0
	if not FileAccess.file_exists(path):
		_cue_warning("cue file not found: " + path)
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_cue_warning("could not open cue file: " + path)
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_cue_warning("cue file is not a JSON object: " + path)
		return false
	var root: Dictionary = parsed
	var duration_value: Variant = root.get("duration")
	var raw_cues: Variant = root.get("cues")
	if not _is_number(duration_value) or not raw_cues is Array:
		_cue_warning("cue file needs numeric duration and an array of cues: " + path)
		return false
	_duration = float(duration_value)
	if _duration < 0.0:
		_cue_warning("cue duration cannot be negative: " + path)
		return false
	var raw_env: Variant = root.get("env", null)
	if raw_env != null:
		if not raw_env is Array:
			_cue_warning("cue envelope is not an array: " + path)
			return false
		for value in raw_env as Array:
			if not _is_number(value):
				_cue_warning("cue envelope contains a non-number: " + path)
				return false
			_env.append(clampf(float(value), 0.0, 1.0))

	var last_t := -1.0
	for raw_cue in raw_cues as Array:
		if not raw_cue is Dictionary:
			_cue_warning("cue is not an object: " + path)
			_cues.clear()
			return false
		var cue: Dictionary = raw_cue
		var t_value: Variant = cue.get("t")
		var shape_value: Variant = cue.get("shape")
		var weight_value: Variant = cue.get("weight")
		if not _is_number(t_value) or not _is_number(weight_value) or not shape_value is String:
			_cue_warning("cue needs numeric t/weight and a string shape: " + path)
			_cues.clear()
			return false
		var t := float(t_value)
		var shape := String(shape_value)
		if t < 0.0 or t > _duration or t < last_t or shape.is_empty():
			_cue_warning("cue timestamps must be ordered and inside duration: " + path)
			_cues.clear()
			return false
		last_t = t
		var target_attack := maxf(attack, 0.0)
		var target_hold := maxf(hold, 0.0)
		if shape == "viseme_PP":
			target_hold = maxf(target_hold, PP_MIN_HOLD)
		elif shape == "viseme_FF":
			target_hold = maxf(target_hold, FF_MIN_HOLD)
		var start := maxf(0.0, t - maxf(anticipation, 0.0))
		var attack_end := start + target_attack
		_cues.append({
			"t": t,
			"shape": shape,
			"weight": clampf(float(weight_value), 0.0, 1.0),
			"start": start,
			"attack_end": attack_end,
			"min_hold_end": attack_end + target_hold,
		})
		if not _shape_names.has(shape):
			_shape_names.append(shape)
	# each cue holds until the next one begins (its natural end), then releases into it
	for i in _cues.size():
		var next_t := _duration if i + 1 >= _cues.size() else float(_cues[i + 1]["t"])
		var hold_end := maxf(next_t, float(_cues[i]["min_hold_end"]))
		_cues[i]["hold_end"] = hold_end
		_cues[i]["end"] = hold_end + maxf(release, 0.0)
	_cache_blend_shapes()
	_reset_dictionary(_working_weights)
	_reset_dictionary(_current_weights)
	return true

func _cache_blend_shapes() -> void:
	_blend_indices.clear()
	if _face_mesh == null or _face_mesh.mesh == null:
		return
	for shape in _shape_names:
		var index: int = _face_mesh.find_blend_shape_by_name(shape)
		if index >= 0:
			_blend_indices[shape] = index

func _evaluate_into(time: float, output: Dictionary) -> void:
	_reset_dictionary(output)
	if not _line_valid or time < 0.0:
		return
	var pp := 0.0
	for cue in _cues:
		var value := _target_value(cue, time)
		if value <= 0.0:
			continue
		var shape := String(cue["shape"])
		output[shape] = minf(1.0, float(output.get(shape, 0.0)) + value * float(cue["weight"]))
		if shape == "viseme_PP":
			pp = maxf(pp, float(output[shape]))
	var opening_total := 0.0
	for shape in OPENING_SHAPES:
		opening_total += float(output.get(shape, 0.0))
	var opening_scale := 1.0
	if pp > 0.0:
		opening_scale *= 1.0 - pp
	if not _env.is_empty():
		opening_scale *= lerpf(0.55, 1.0, _envelope_at(time))
	if opening_total > 1.0:
		opening_scale *= 1.0 / opening_total
	for shape in OPENING_SHAPES:
		output[shape] = clampf(float(output.get(shape, 0.0)) * opening_scale, 0.0, 1.0)

func _target_value(cue: Dictionary, time: float) -> float:
	var start := float(cue["start"])
	var attack_end := float(cue["attack_end"])
	var hold_end := float(cue["hold_end"])
	var end := float(cue["end"])
	if time < start or time >= end:
		return 0.0
	if attack_end > start and time < attack_end:
		return (time - start) / (attack_end - start)
	if time <= hold_end:
		return 1.0
	if end > hold_end:
		return 1.0 - (time - hold_end) / (end - hold_end)
	return 0.0

func _envelope_at(time: float) -> float:
	if _env.is_empty():
		return 1.0
	var position := clampf(time * 100.0, 0.0, float(_env.size() - 1))
	var first := int(floor(position))
	var second := mini(first + 1, _env.size() - 1)
	return lerpf(_env[first], _env[second], position - float(first))

func _apply_weights(weights: Dictionary) -> void:
	if _face_mesh == null or is_instance_valid(_mixer):
		return
	for shape in _blend_indices:
		_face_mesh.set_blend_shape_value(int(_blend_indices[shape]), float(weights.get(shape, 0.0)))

func _set_audio_stream(stream: AudioStream) -> void:
	if _audio_player is AudioStreamPlayer:
		(_audio_player as AudioStreamPlayer).stream = stream
	elif _audio_player is AudioStreamPlayer3D:
		(_audio_player as AudioStreamPlayer3D).stream = stream

func _audio_play() -> void:
	if _audio_player is AudioStreamPlayer:
		(_audio_player as AudioStreamPlayer).stream_paused = false
		(_audio_player as AudioStreamPlayer).play()
	elif _audio_player is AudioStreamPlayer3D:
		(_audio_player as AudioStreamPlayer3D).stream_paused = false
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

func _audio_playback_position() -> float:
	if _audio_player is AudioStreamPlayer:
		return (_audio_player as AudioStreamPlayer).get_playback_position()
	if _audio_player is AudioStreamPlayer3D:
		return (_audio_player as AudioStreamPlayer3D).get_playback_position()
	return _line_clock

func _audio_is_playing() -> bool:
	if _audio_player is AudioStreamPlayer:
		return (_audio_player as AudioStreamPlayer).playing
	if _audio_player is AudioStreamPlayer3D:
		return (_audio_player as AudioStreamPlayer3D).playing
	return false

func _set_stream_paused(value: bool) -> void:
	if _audio_player is AudioStreamPlayer:
		(_audio_player as AudioStreamPlayer).stream_paused = value
	elif _audio_player is AudioStreamPlayer3D:
		(_audio_player as AudioStreamPlayer3D).stream_paused = value

func _stream_paused() -> bool:
	if _audio_player is AudioStreamPlayer:
		return (_audio_player as AudioStreamPlayer).stream_paused
	if _audio_player is AudioStreamPlayer3D:
		return (_audio_player as AudioStreamPlayer3D).stream_paused
	return false

func _reset_dictionary(dictionary: Dictionary) -> void:
	for shape in _shape_names:
		dictionary[shape] = 0.0

func _copy_weights(source: Dictionary, destination: Dictionary) -> void:
	for shape in _shape_names:
		destination[shape] = float(source.get(shape, 0.0))

func _weights_are_zero(weights: Dictionary) -> bool:
	for value in weights.values():
		if absf(float(value)) > 0.0001:
			return false
	return true

func _cue_warning(message: String) -> void:
	push_warning("LipSync " + message)

func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT
