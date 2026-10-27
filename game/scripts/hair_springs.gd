extends Node
class_name HairSprings

const SPRING_PREFIXES: Array[String] = ["Hair", "Ponytail", "Apron", "Strap"]
const HEAD_NAMES: Array[String] = ["mixamorig_Head", "mixamorig:Head", "Head"]
const NECK_NAMES: Array[String] = ["mixamorig_Neck", "mixamorig:Neck", "Neck"]
const BACK_NAMES: Array[String] = ["mixamorig_Spine2", "mixamorig:Spine2", "Spine2", "mixamorig_Spine1"]

@export var skeleton_path: NodePath
@export_range(0.0, 1.0, 0.01) var stiffness: float = 0.38
@export_range(0.0, 1.0, 0.01) var drag: float = 0.18
@export_range(0.0, 1.0, 0.01) var gravity: float = 0.08
@export_range(0.0, 1.0, 0.01) var collision_radius: float = 0.14

var skeleton: Skeleton3D
var simulator: SpringBoneSimulator3D
var chains: Array[String] = []
var collisions: Array[SpringBoneCollisionSphere3D] = []

func _ready() -> void:
	build()

func build(target: Node = null) -> Dictionary:
	if target != null and target is Skeleton3D:
		skeleton = target as Skeleton3D
	elif not skeleton_path.is_empty():
		skeleton = get_node_or_null(skeleton_path) as Skeleton3D
	else:
		skeleton = _find_skeleton(get_parent())
	if skeleton == null or not ClassDB.class_exists("SpringBoneSimulator3D"):
		return {"chains": 0, "collisions": 0}
	if simulator != null and is_instance_valid(simulator):
		simulator.queue_free()
	for collision in collisions:
		if is_instance_valid(collision):
			collision.queue_free()
	collisions.clear()
	chains.clear()
	var roots := _find_chain_roots()
	if roots.is_empty():
		return {"chains": 0, "collisions": 0}
	simulator = SpringBoneSimulator3D.new()
	simulator.name = "AnimeSpringBoneSimulator"
	skeleton.add_child(simulator)
	simulator.set_setting_count(roots.size())
	for setting in roots.size():
		var root_bone: int = roots[setting]
		var end_bone := _find_chain_end(root_bone)
		var root_name := skeleton.get_bone_name(root_bone)
		var end_name := skeleton.get_bone_name(end_bone)
		chains.append(root_name)
		simulator.set_root_bone_name(setting, root_name)
		simulator.set_end_bone_name(setting, end_name)
		simulator.set_center_bone_name(setting, _first_bone(HEAD_NAMES, root_bone))
		simulator.set_stiffness(setting, clampf(stiffness, 0.0, 1.0))
		simulator.set_drag(setting, clampf(drag, 0.0, 1.0))
		simulator.set_gravity(setting, clampf(gravity, 0.0, 1.0))
		simulator.set_gravity_direction(setting, Vector3.DOWN)
		if end_bone == root_bone:
			simulator.set_extend_end_bone(setting, true)
	_create_collisions()
	return {"chains": chains.size(), "collisions": collisions.size()}

func _find_chain_roots() -> Array[int]:
	var result: Array[int] = []
	for bone in skeleton.get_bone_count():
		if not _is_spring_bone(skeleton.get_bone_name(bone)):
			continue
		var parent := skeleton.get_bone_parent(bone)
		if parent < 0 or not _is_spring_bone(skeleton.get_bone_name(parent)):
			result.append(bone)
	return result

func _find_chain_end(root: int) -> int:
	var best := root
	var best_depth := 0
	for bone in skeleton.get_bone_count():
		var depth := _depth_from(bone, root)
		if depth > best_depth:
			best_depth = depth
			best = bone
	return best

func _depth_from(bone: int, root: int) -> int:
	var depth := 0
	var current := bone
	while current >= 0:
		if current == root:
			return depth if _is_spring_bone(skeleton.get_bone_name(bone)) else -1
		current = skeleton.get_bone_parent(current)
		depth += 1
	return -1

func _is_spring_bone(name: String) -> bool:
	var suffix := name
	if name.contains("_"):
		suffix = name.get_slice("_", 1)
	for prefix in SPRING_PREFIXES:
		if suffix.begins_with(prefix) or name.begins_with(prefix):
			return true
	return false

func _first_bone(names: Array[String], fallback: int) -> String:
	for name in names:
		if skeleton.find_bone(name) >= 0:
			return name
	return skeleton.get_bone_name(fallback) if fallback >= 0 else ""

func _create_collisions() -> void:
	var entries: Array[Dictionary] = [
		{"name": "Head", "bones": HEAD_NAMES, "offset": Vector3(0.0, 0.0, 0.0), "radius": collision_radius * 0.9},
		{"name": "Neck", "bones": NECK_NAMES, "offset": Vector3(0.0, 0.025, 0.0), "radius": collision_radius * 0.75},
		{"name": "UpperBack", "bones": BACK_NAMES, "offset": Vector3(0.0, 0.0, -0.08), "radius": collision_radius * 1.3},
	]
	for entry in entries:
		var bone_name := _first_bone(entry["bones"], -1)
		if bone_name.is_empty() or skeleton.find_bone(bone_name) < 0:
			continue
		var sphere := SpringBoneCollisionSphere3D.new()
		sphere.name = "SpringCollision_" + String(entry["name"])
		sphere.set_bone_name(bone_name)
		sphere.position_offset = entry["offset"]
		sphere.radius = float(entry["radius"])
		skeleton.add_child(sphere)
		collisions.append(sphere)
	if simulator != null:
		for setting in simulator.get_setting_count():
			simulator.set_collision_count(setting, collisions.size())
			for i in collisions.size():
				simulator.set_collision_path(setting, i, simulator.get_path_to(collisions[i]))
			simulator.set_enable_all_child_collisions(setting, true)

func _find_skeleton(node: Node) -> Skeleton3D:
	if node == null:
		return null
	if node is Skeleton3D:
		return node as Skeleton3D
	return node.find_child("Skeleton3D", true, false) as Skeleton3D
