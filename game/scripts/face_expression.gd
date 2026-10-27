# Owns face blend shapes and composes expression with LipSync speech weights.
extends Node
class_name FaceExpression

const EXPRESSION_NAMES: Array[String] = ["exprNeutral", "exprSerious", "browUp", "browDown", "eyesBlink"]
const SHAPE_NAMES: Array[String] = [
	"viseme_sil", "viseme_PP", "viseme_FF", "viseme_TH", "viseme_DD", "viseme_kk",
	"viseme_CH", "viseme_SS", "viseme_nn", "viseme_RR", "viseme_aa", "viseme_E",
	"viseme_I", "viseme_O", "viseme_U", "jawOpen", "exprNeutral", "exprSerious",
	"browUp", "browDown", "eyesBlink"
]
const BLINK_CLOSE: float = 0.04
const BLINK_HOLD: float = 0.02
const BLINK_OPEN: float = 0.06
const DOUBLE_BLINK_GAP: float = 0.08
const DOUBLE_BLINK_CHANCE: float = 0.15

enum BlinkPhase { WAIT, CLOSE, HOLD, OPEN, DOUBLE_GAP }

@export var face_mesh_path: NodePath
@export var lip_sync_path: NodePath
@export var blink_enabled: bool = true
@export var brow_accents: bool = false
@export_range(0.0, 1.0, 0.01) var brow_accent_scale: float = 0.15

var _face_mesh: MeshInstance3D
var _lip_sync: LipSync
var _blend_indices: Dictionary = {}
var _current: Dictionary = {}
var _targets: Dictionary = {}
var _fade_left: Dictionary = {}
var _blink_timer: float = 3.0
var _blink_phase: BlinkPhase = BlinkPhase.WAIT
var _blink_elapsed: float = 0.0
var _blink_double: bool = false
var _blink_value: float = 0.0
var _accent_value: float = 0.0
var _last_envelope: float = 0.0
var _rng := RandomNumberGenerator.new()

func _init() -> void:
	for shape in EXPRESSION_NAMES:
		_current[shape] = 0.0
		_targets[shape] = 0.0
		_fade_left[shape] = 0.0

func _ready() -> void:
	_resolve_nodes()
	_cache_blend_shapes()
	_rng.randomize()
	_schedule_blink()
	if is_instance_valid(_lip_sync) and is_instance_valid(_face_mesh) and _face_mesh.mesh != null:
		# Higher priorities run later, regardless of sibling order in the scene.
		process_priority = _lip_sync.process_priority + 1
		_lip_sync.set_mixer(self)

func _exit_tree() -> void:
	if is_instance_valid(_lip_sync):
		if _lip_sync._mixer != self:
			return
		_lip_sync.clear_mixer(self)
	# Remove our expression contribution and hand the current speech back intact.
	if is_instance_valid(_face_mesh):
		var speech: Dictionary = _lip_sync.get_current_weights() if is_instance_valid(_lip_sync) else {}
		for shape in _blend_indices:
			_face_mesh.set_blend_shape_value(int(_blend_indices[shape]), clampf(float(speech.get(shape, 0.0)), 0.0, 1.0))

# Independent layers: fade a previous expression to zero when switching moods.
# eyesBlink can also be held manually; missing and unknown shapes are harmless.
func set_expression(name: String, weight: float, fade: float = 0.25) -> void:
	if not _targets.has(name):
		return
	_targets[name] = clampf(weight, 0.0, 1.0)
	_fade_left[name] = maxf(fade, 0.0)
	if fade <= 0.0:
		_current[name] = _targets[name]

func _process(delta: float) -> void:
	delta = maxf(delta, 0.0)
	for shape in EXPRESSION_NAMES:
		var remaining := float(_fade_left[shape])
		if remaining <= 0.0:
			_current[shape] = float(_targets[shape])
		else:
			var step := minf(delta / remaining, 1.0)
			_current[shape] = lerpf(float(_current[shape]), float(_targets[shape]), step)
			_fade_left[shape] = maxf(0.0, remaining - delta)
	_update_blink(delta)
	_update_brow_accent(delta)
	if not is_instance_valid(_face_mesh):
		return
	var speech: Dictionary = {}
	if is_instance_valid(_lip_sync):
		speech = _lip_sync.get_current_weights()
	for shape in _blend_indices:
		var expression_weight := float(_current.get(shape, 0.0))
		if shape == "eyesBlink":
			expression_weight += _blink_value
		elif shape == "browUp":
			expression_weight += _accent_value
		var final_weight := clampf(float(speech.get(shape, 0.0)) + expression_weight, 0.0, 1.0)
		_face_mesh.set_blend_shape_value(int(_blend_indices[shape]), final_weight)

func _resolve_nodes() -> void:
	if not face_mesh_path.is_empty():
		_face_mesh = get_node_or_null(face_mesh_path) as MeshInstance3D
	if not lip_sync_path.is_empty():
		_lip_sync = get_node_or_null(lip_sync_path) as LipSync

func _cache_blend_shapes() -> void:
	_blend_indices.clear()
	if not is_instance_valid(_face_mesh) or _face_mesh.mesh == null:
		return
	for shape in SHAPE_NAMES:
		var index: int = _face_mesh.find_blend_shape_by_name(shape)
		if index >= 0:
			_blend_indices[shape] = index

func _schedule_blink() -> void:
	_blink_timer = _rng.randf_range(2.0, 6.0)

func _update_blink(delta: float) -> void:
	if not blink_enabled or float(_current["eyesBlink"]) > 0.0:
		if _blink_phase != BlinkPhase.WAIT:
			_schedule_blink()
		_blink_value = 0.0
		_blink_phase = BlinkPhase.WAIT
		_blink_elapsed = 0.0
		_blink_double = false
		return
	# Carry unused time into the next phase, including at low frame rates.
	while delta > 0.0:
		if _blink_phase == BlinkPhase.WAIT:
			var wait_step := minf(delta, _blink_timer)
			_blink_timer -= wait_step
			delta -= wait_step
			if _blink_timer > 0.000001:
				return
			_blink_phase = BlinkPhase.CLOSE
			_blink_double = _rng.randf() < DOUBLE_BLINK_CHANCE
		else:
			var duration := BLINK_CLOSE
			if _blink_phase == BlinkPhase.HOLD:
				duration = BLINK_HOLD
			elif _blink_phase == BlinkPhase.OPEN:
				duration = BLINK_OPEN
			elif _blink_phase == BlinkPhase.DOUBLE_GAP:
				duration = DOUBLE_BLINK_GAP
			var step := minf(delta, duration - _blink_elapsed)
			_blink_elapsed += step
			delta -= step
			if _blink_phase == BlinkPhase.CLOSE:
				_blink_value = clampf(_blink_elapsed / BLINK_CLOSE, 0.0, 1.0)
			elif _blink_phase == BlinkPhase.HOLD:
				_blink_value = 1.0
			elif _blink_phase == BlinkPhase.OPEN:
				_blink_value = 1.0 - clampf(_blink_elapsed / BLINK_OPEN, 0.0, 1.0)
			if _blink_elapsed < duration - 0.000001:
				return
			_blink_elapsed = 0.0
			match _blink_phase:
				BlinkPhase.CLOSE:
					_blink_phase = BlinkPhase.HOLD
				BlinkPhase.HOLD:
					_blink_phase = BlinkPhase.OPEN
				BlinkPhase.OPEN:
					_blink_value = 0.0
					if _blink_double:
						_blink_double = false
						_blink_phase = BlinkPhase.DOUBLE_GAP
					else:
						_blink_phase = BlinkPhase.WAIT
						_schedule_blink()
				BlinkPhase.DOUBLE_GAP:
					_blink_phase = BlinkPhase.CLOSE

func _update_brow_accent(delta: float) -> void:
	if not brow_accents or not is_instance_valid(_lip_sync):
		_accent_value = move_toward(_accent_value, 0.0, delta * 5.0)
		_last_envelope = 0.0
		return
	var envelope := _lip_sync.get_current_envelope()
	if envelope > 0.65 and _last_envelope <= 0.65:
		_accent_value = maxf(_accent_value, brow_accent_scale)
	_last_envelope = envelope
	_accent_value = move_toward(_accent_value, 0.0, delta * 3.0)
