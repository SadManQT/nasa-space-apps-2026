# Optional speech accents, added after animation by the Skeleton3D modifier stack.
extends SkeletonModifier3D
class_name HeadAccent

const MAX_ANGLE_DEGREES: float = 4.0
const ONSET_HIGH: float = 0.65
const ONSET_LOW: float = 0.35
const ONSET_COOLDOWN: float = 0.18

@export var lip_sync_path: NodePath
@export var enabled: bool = false:
	set(value):
		enabled = value
		active = value
		_reset_accent()
@export_range(0.0, 4.0, 0.1) var max_angle_degrees: float = 4.0
@export_range(0.0, 0.3, 0.01) var neck_share: float = 0.2
@export_range(0.01, 0.3, 0.01) var smoothing: float = 0.06
@export_range(0.05, 0.6, 0.01) var decay: float = 0.18

var _lip_sync: LipSync
var _head_index: int = -1
var _neck_index: int = -1
var _skeleton_version: int = -1
var _target := Vector2.ZERO
var _offset := Vector2.ZERO
var _armed: bool = false
var _cooldown: float = 0.0
var _tilt_sign: float = 1.0

func _init() -> void:
	active = false

func _ready() -> void:
	if not lip_sync_path.is_empty():
		_lip_sync = get_node_or_null(lip_sync_path) as LipSync
	active = enabled
	_reset_accent()

func _reset_accent() -> void:
	_target = Vector2.ZERO
	_offset = Vector2.ZERO
	_cooldown = 0.0
	_tilt_sign = 1.0
	# Enabling on an already loud (or absent) envelope must not invent an onset.
	_armed = is_instance_valid(_lip_sync) and _lip_sync.get_current_envelope() <= ONSET_LOW

func _skeleton_changed(_old_skeleton: Skeleton3D, _new_skeleton: Skeleton3D) -> void:
	_skeleton_version = -1

func _process_modification_with_delta(delta: float) -> void:
	if not enabled or not active:
		return
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	if skeleton.get_version() != _skeleton_version:
		_head_index = _find_mixamo_bone(skeleton, "Head")
		_neck_index = _find_mixamo_bone(skeleton, "Neck")
		_skeleton_version = skeleton.get_version()
	_update_accent(maxf(delta, 0.0))
	if _head_index < 0:
		return
	# Split one bounded rotation across head and neck: total accent <= 4 degrees.
	var share := clampf(neck_share, 0.0, 0.3) if _neck_index >= 0 else 0.0
	_apply_offset(skeleton, _head_index, 1.0 - share)
	if _neck_index >= 0:
		_apply_offset(skeleton, _neck_index, share)

func _find_mixamo_bone(skeleton: Skeleton3D, bone: String) -> int:
	var index := skeleton.find_bone("mixamorig:" + bone)
	# GLTFDocument sanitizes ':' to '_' because Skeleton3D forbids colons.
	if index < 0:
		index = skeleton.find_bone("mixamorig_" + bone)
	return index

func _update_accent(delta: float) -> void:
	if delta <= 0.0:
		return
	_cooldown = maxf(0.0, _cooldown - delta)
	var envelope := _lip_sync.get_current_envelope() if is_instance_valid(_lip_sync) else 0.0
	envelope = clampf(envelope, 0.0, 1.0)
	if envelope <= ONSET_LOW:
		_armed = true
	var limit := deg_to_rad(clampf(max_angle_degrees, 0.0, MAX_ANGLE_DEGREES))
	if _armed and envelope >= ONSET_HIGH and _cooldown <= 0.0:
		_target = Vector2(1.0, 0.3 * _tilt_sign).normalized() * limit * envelope
		_tilt_sign *= -1.0
		_armed = false
		_cooldown = ONSET_COOLDOWN
	_offset = _offset.lerp(_target, 1.0 - exp(-delta / maxf(smoothing, 0.01))).limit_length(limit)
	_target *= exp(-delta / maxf(decay, 0.01))

func _apply_offset(skeleton: Skeleton3D, bone: int, share: float) -> void:
	var rotation_vector := Vector3(_offset.x, 0.0, _offset.y) * share
	var angle := rotation_vector.length()
	if angle <= 0.000001:
		return
	var accent := Quaternion(rotation_vector / angle, angle)
	var pose := skeleton.get_bone_pose_rotation(bone)
	# Godot handles influence and restores the input pose after the modifier pass.
	skeleton.set_bone_pose_rotation(bone, (pose * accent).normalized())
