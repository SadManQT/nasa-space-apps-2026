extends Node3D
class_name HeldProp

const PALM_HALF_THICKNESS: float = 0.015

var skeleton: Skeleton3D
var mode: PlayerAnimation.Hold = PlayerAnimation.Hold.NONE
var prop: Node3D
var prop_bounds := AABB()
var grip := Vector3.ZERO
var _bones: Dictionary = {}

func setup(rig: Skeleton3D, hold: PlayerAnimation.Hold, scene: PackedScene) -> bool:
	if skeleton != null and skeleton.skeleton_updated.is_connected(update_alignment):
		skeleton.skeleton_updated.disconnect(update_alignment)
	if prop != null:
		prop.free()
		prop = null
	skeleton = rig
	mode = hold
	_bones.clear()
	if mode == PlayerAnimation.Hold.NONE:
		return true
	if skeleton == null or scene == null:
		return false
	for suffix in ["LeftHand", "LeftHandMiddle1", "RightHand", "RightHandMiddle1", "RightHandMiddle2", "RightHandMiddle3", "RightHandIndex1", "RightHandPinky1"]:
		var bone := LocomotionClips.bone(skeleton, suffix)
		if bone < 0:
			push_error("Held prop needs bone " + suffix)
			return false
		_bones[suffix] = bone
	prop = scene.instantiate() as Node3D
	add_child(prop)
	prop_bounds = AssetGeometry.bounds(prop)
	if prop_bounds.size.x <= 0.0001:
		prop.free()
		prop = null
		return false
	# The hand light is authored along +X; its central barrel is the grip.
	var marker := prop.find_child("Grip", true, false) as Node3D
	grip = prop.to_local(marker.global_position) if marker != null else prop_bounds.get_center()
	ToonMaterials.apply_to_tree(prop, false, true)
	# Read the final pose after IK, gaze and spring modifiers have run.
	skeleton.skeleton_updated.connect(update_alignment)
	update_alignment()
	return true

func bone_position(suffix: String) -> Vector3:
	return skeleton.global_transform * skeleton.get_bone_global_pose(_bones[suffix]).origin

func palm_center(side: String) -> Vector3:
	return (bone_position(side + "Hand") + bone_position(side + "HandMiddle1")) * 0.5

func update_alignment() -> void:
	if prop == null or not is_instance_valid(skeleton) or not skeleton.is_inside_tree() or not prop.is_inside_tree():
		return
	var right := palm_center("Right")
	var axes := skeleton.global_basis.orthonormalized()
	if mode == PlayerAnimation.Hold.BOX:
		# The palms press on the case's sides (palm centres sit a palm's half thickness outside it), at its back third.
		var left := palm_center("Left")
		var width := absf((right - left).dot(axes.x)) - 2.0 * PALM_HALF_THICKNESS
		axes = axes.scaled(Vector3.ONE * maxf(width / prop_bounds.size.x, 0.001))
		var centre := (left + right) * 0.5 + axes.z * (prop_bounds.size.z / 6.0)
		prop.global_transform = Transform3D(axes, centre - axes * prop_bounds.get_center())
	else:
		# A power grip: the handle runs across the palm (index to pinky) through the centre of the finger curl,
		# its +X end out of the thumb side and its +Y face (the light's switch) under the thumb.
		var across := (bone_position("RightHandIndex1") - bone_position("RightHandPinky1")).normalized()
		var forward := (bone_position("RightHandMiddle1") - bone_position("RightHand")).normalized()
		var centre := curl_centre()
		if across.is_zero_approx() or forward.is_zero_approx() or not centre.is_finite():
			return
		var up := across.cross(forward)
		up = (up - across * up.dot(across)).normalized()
		axes = Basis(across, up, across.cross(up))
		prop.global_transform = Transform3D(axes, centre - axes * grip)

# Centre of the circle through the right middle finger's three joints: the axis of whatever the hand grips.
func curl_centre() -> Vector3:
	var a := bone_position("RightHandMiddle1")
	var ab := bone_position("RightHandMiddle2") - a
	var ac := bone_position("RightHandMiddle3") - a
	var n := ab.cross(ac)
	if n.length_squared() < 1e-12:
		return Vector3.INF
	return a + (n.cross(ab) * ac.length_squared() + ac.cross(n) * ab.length_squared()) / (2.0 * n.length_squared())
