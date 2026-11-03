extends Node3D
class_name CampaignRoom

const RoomContract = preload("res://scripts/world/room_contract.gd")
const DoorScript = preload("res://scripts/navigation/campaign_door.gd")
const AssetGeometryScript = preload("res://scripts/asset_geometry.gd")
const ToonMaterialsScript = preload("res://scripts/toon_materials.gd")

@export var room_id := "LOC-01"
@export var load_approved_assets := true
@export var build_navigation := true

var visual_root: Node3D
var collision_root: Node3D
var focus_root: Node3D
var pressure_root: Node3D
var door_root: Node3D
var anchor_root: Node3D
var navigation_root: Node3D
var _built := false

func _ready() -> void:
	build_room()

func build_room() -> Dictionary:
	if _built:
		return {"accepted": true, "room_id": room_id, "duplicate": true}
	var contract := RoomContract.room(room_id)
	if contract.is_empty():
		push_error("CampaignRoom has no contract for " + room_id)
		return {"accepted": false, "reason": "Unknown room contract."}
	visual_root = _node_root("VisualRoot")
	collision_root = _node_root("CollisionRoot")
	focus_root = _node_root("FocusTargets")
	pressure_root = _node_root("PressureBoundaries")
	door_root = _node_root("Doors")
	anchor_root = _node_root("CompanionAnchors")
	navigation_root = _node_root("Navigation")
	_build_floor_and_walls(contract)
	_build_doors(contract)
	_build_focus_targets(contract)
	_build_pressure_markers(contract)
	_build_anchors(contract)
	if build_navigation:
		_build_navigation(contract)
	if load_approved_assets:
		_load_approved_assets(contract)
	set_meta("room_id", room_id)
	set_meta("visual_root", "VisualRoot")
	set_meta("collision_root", "CollisionRoot")
	set_meta("focus_root", "FocusTargets")
	set_meta("pressure_root", "PressureBoundaries")
	set_meta("door_root", "Doors")
	set_meta("anchor_root", "CompanionAnchors")
	_built = true
	return {
		"accepted": true,
		"room_id": room_id,
		"pressure": String(contract.get("pressure", "pressurised")),
		"focus_target_count": focus_root.get_child_count(),
		"door_count": door_root.get_child_count(),
		"anchor_count": anchor_root.get_child_count(),
	}

func focus_targets() -> Array:
	var result: Array = []
	if focus_root == null:
		return result
	for child in focus_root.get_children():
		result.append({
			"target_id": String(child.get_meta("target_id", child.name)),
			"label": String(child.get_meta("focus_label", child.name)),
			"verb": String(child.get_meta("verb", "Inspect")),
			"position": [child.position.x, child.position.y, child.position.z],
		})
	return result

func named_roots() -> Dictionary:
	return {
		"visual_root": visual_root,
		"collision_root": collision_root,
		"focus_root": focus_root,
		"pressure_root": pressure_root,
		"door_root": door_root,
		"anchor_root": anchor_root,
		"navigation_root": navigation_root,
	}

func set_door_open(boundary_id: String, is_open: bool) -> bool:
	if door_root == null:
		return false
	for node in door_root.get_children():
		if String(node.get_meta("boundary_id", "")) == boundary_id and node is CampaignDoor:
			(node as CampaignDoor).set_open(is_open)
			return true
	return false

func _node_root(node_name: String) -> Node3D:
	var existing := get_node_or_null(node_name) as Node3D
	if existing != null:
		return existing
	var node := Node3D.new()
	node.name = node_name
	add_child(node)
	return node

func _build_floor_and_walls(contract: Dictionary) -> void:
	var bounds: Array = contract.get("bounds_m", [10.0, 10.0])
	var width := minf(float(bounds[0]), 40.0)
	var depth := minf(float(bounds[1]), 40.0)
	_add_box(collision_root, "FloorCollision", Vector3(0.0, -0.15, 0.0), Vector3(width, 0.3, depth), Color("#192235"), false)
	# Walls are intentionally owned by CollisionRoot, separate from any GLB
	# visual. Doors are named child bodies so their legal state can disable only
	# the relevant collision shape.
	_add_box(collision_root, "NorthWallCollision", Vector3(0.0, 1.5, -depth * 0.5), Vector3(width, 3.0, 0.2), Color("#263650"), false)
	_add_box(collision_root, "SouthWallCollision", Vector3(0.0, 1.5, depth * 0.5), Vector3(width, 3.0, 0.2), Color("#263650"), false)
	_add_box(collision_root, "WestWallCollision", Vector3(-width * 0.5, 1.5, 0.0), Vector3(0.2, 3.0, depth), Color("#263650"), false)
	_add_box(collision_root, "EastWallCollision", Vector3(width * 0.5, 1.5, 0.0), Vector3(0.2, 3.0, depth), Color("#263650"), false)

func _build_doors(contract: Dictionary) -> void:
	var boundaries: Array = contract.get("boundary_ids", [])
	for index in boundaries.size():
		var boundary_id := String(boundaries[index])
		var door := DoorScript.new()
		door.name = "Door_" + boundary_id
		door.set_meta("boundary_id", boundary_id)
		door.set_meta("focus_target", "door:" + boundary_id)
		var shape := CollisionShape3D.new()
		shape.name = "CollisionShape3D"
		var box := BoxShape3D.new()
		box.size = Vector3(1.2, 2.2, 0.18)
		shape.shape = box
		door.add_child(shape)
		door.position = _door_position(boundary_id, index)
		door.setup(boundary_id, boundary_id.begins_with("door_"))
		door_root.add_child(door)
		var label := Label3D.new()
		label.name = "BoundaryLabel"
		label.text = boundary_id.replace("_", " ").to_upper()
		label.font_size = 24
		label.pixel_size = 0.002
		label.position = Vector3(0.0, 1.3, 0.0)
		door.add_child(label)

func _build_focus_targets(contract: Dictionary) -> void:
	var targets: Array = contract.get("focus_targets", [])
	for raw_target in targets:
		if not raw_target is Dictionary:
			continue
		var target: Dictionary = raw_target
		var node := Node3D.new()
		node.name = "Focus_" + String(target.get("target_id", "target"))
		var position: Array = target.get("position", [0.0, 1.0, 0.0])
		node.position = Vector3(float(position[0]), float(position[1]), float(position[2]))
		node.add_to_group("interactable")
		node.set_meta("target_id", String(target.get("target_id", node.name)))
		node.set_meta("focus_label", String(target.get("label", node.name)))
		node.set_meta("verb", String(target.get("verb", "Inspect")))
		node.set_meta("room_id", room_id)
		focus_root.add_child(node)

func _build_pressure_markers(contract: Dictionary) -> void:
	for raw_boundary in contract.get("boundary_ids", []):
		var boundary_id := String(raw_boundary)
		var marker := Node3D.new()
		marker.name = "PressureBoundary_" + boundary_id
		marker.set_meta("boundary_id", boundary_id)
		marker.set_meta("pressure_logic_owner", "WorldRoute")
		marker.set_meta("closed_state_blocks_movement", true)
		pressure_root.add_child(marker)

func _build_anchors(contract: Dictionary) -> void:
	var anchors: Dictionary = contract.get("anchors", {})
	for anchor_id in anchors.keys():
		var marker := Marker3D.new()
		marker.name = String(anchor_id)
		var position: Array = anchors[anchor_id]
		marker.position = Vector3(float(position[0]), float(position[1]), float(position[2]))
		marker.set_meta("anchor_id", String(anchor_id))
		marker.set_meta("room_id", room_id)
		anchor_root.add_child(marker)

func _build_navigation(contract: Dictionary) -> void:
	var bounds: Array = contract.get("bounds_m", [10.0, 10.0])
	var width := minf(float(bounds[0]), 40.0) - 0.8
	var depth := minf(float(bounds[1]), 40.0) - 0.8
	var region := NavigationRegion3D.new()
	region.name = "NavigationRegion"
	var mesh := NavigationMesh.new()
	mesh.vertices = PackedVector3Array([
		Vector3(-width * 0.5, 0.0, -depth * 0.5),
		Vector3(width * 0.5, 0.0, -depth * 0.5),
		Vector3(width * 0.5, 0.0, depth * 0.5),
		Vector3(-width * 0.5, 0.0, depth * 0.5),
	])
	mesh.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	region.navigation_mesh = mesh
	region.set_meta("route_contract", room_id)
	navigation_root.add_child(region)

func _load_approved_assets(contract: Dictionary) -> void:
	var paths: Array = contract.get("asset_paths", [])
	for index in paths.size():
		var path := String(paths[index])
		var model := AssetGeometryScript.load_glb(path)
		if model == null:
			continue
		model.name = path.get_file().get_basename()
		model.position = _asset_position(index, paths.size())
		model.scale = Vector3.ONE * (0.72 if room_id == "LOC-06" else 0.85)
		visual_root.add_child(model)
		ToonMaterialsScript.apply_to_tree(model, false, true)

func _asset_position(index: int, count: int) -> Vector3:
	var column := index % 3
	var row := index / 3
	return Vector3(float(column - 1) * 2.4, 0.0, -1.4 + float(row) * 2.1)

func _door_position(boundary_id: String, index: int) -> Vector3:
	match boundary_id:
		"door_commons_service", "door_service_garden":
			return Vector3(-2.0 + float(index) * 0.5, 1.1, -5.5 if room_id == "LOC-01" else -2.8)
		"door_commons_garden":
			return Vector3(2.0, 1.1, -5.5)
		"door_commons_safe", "door_service_safe":
			return Vector3(5.5 if room_id == "LOC-01" else 2.8, 1.1, 1.0)
		"garden_viewing_shutter":
			return Vector3(0.0, 1.1, -3.8)
		"airlock_exterior":
			return Vector3(0.0, 1.1, 5.5)
		_:
			return Vector3(-3.0 + float(index), 1.1, 0.0)

func _add_box(parent: Node3D, node_name: String, at: Vector3, size: Vector3, color: Color, visible: bool) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = at
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	if visible:
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = size
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.88
		box.material = material
		mesh.mesh = box
		body.add_child(mesh)
	parent.add_child(body)
	return body
