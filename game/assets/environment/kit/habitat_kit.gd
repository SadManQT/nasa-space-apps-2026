## M1-05: the modular habitat kit catalogue and instancing helper.
## Reads kit.json next to this script (written by production/tools/build_habitat_kit.py), builds a piece as a
## two-LOD node with Godot visibility ranges and the collision nodes the GLB already carries, applies each
## piece's mount offset, and drives the door and hatch leaves. M1-06 assembles rooms from this; it owns layout.
extends RefCounted

const CATALOG_PATH := "res://assets/environment/kit/kit.json"
## Extension catalogues in the same schema (M3-3A: the Expedition Zero annex pieces). Their pieces are placed,
## bounded and driven exactly like kit pieces; catalog() and ids() stay the kit's own.
const EXTENSION_CATALOGS: Array[String] = ["res://assets/environment/EN_ZeroAnnex/annex.json"]
const DOOR_LEAF := "DoorLeaf"
const HATCH_LEAF := "HatchLeaf"
const SCREEN_MATERIAL := "Screen"
const PIECE_META := "piece_id"
static var _catalog: Dictionary = {}
static var _extensions: Array = []
static var _scenes: Dictionary = {}

## The whole catalogue: conventions, pieces (id, lods, triangles, footprint_m, mount_y, sockets) and materials.
static func catalog() -> Dictionary:
	if _catalog.is_empty():
		_catalog = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	return _catalog

## Every piece id in catalogue order.
static func ids() -> PackedStringArray:
	var out := PackedStringArray()
	for entry in catalog().pieces:
		out.append(entry.id)
	return out

## Every extension catalogue that exists on disk (missing files are skipped, so the kit works without them).
static func extensions() -> Array:
	if _extensions.is_empty():
		for path in EXTENSION_CATALOGS:
			if FileAccess.file_exists(path):
				var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
				if parsed is Dictionary and parsed.has("pieces"):
					_extensions.append(parsed)
	return _extensions

## The catalogue entry for one piece (kit or extension), or an empty dictionary for an unknown id.
static func piece(id: String) -> Dictionary:
	for entry in catalog().pieces:
		if entry.id == id:
			return entry
	for ext in extensions():
		for entry in ext.pieces:
			if entry.id == id:
				return entry
	return {}

## Every piece id of one extension catalogue (by its res:// path), in catalogue order.
static func extension_ids(path: String) -> PackedStringArray:
	var out := PackedStringArray()
	if FileAccess.file_exists(path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary and parsed.has("pieces"):
			for entry in parsed.pieces:
				out.append(entry.id)
	return out

## The catalogue id of a node built by instance() (its "piece_id" meta), or the node's name for anything else.
static func piece_id(node: Node) -> String:
	return String(node.get_meta(PIECE_META)) if node.has_meta(PIECE_META) else String(node.name)

## The vertical offset that puts a piece's finished surface on the room's floor or ceiling plane.
static func mount_y(id: String) -> float:
	return float(piece(id).get("mount_y", 0.0))

static func _scene(path: String) -> PackedScene:
	if not _scenes.has(path):
		_scenes[path] = load(path)
	return _scenes[path]

## Builds a piece: a Node3D named after the id holding one child per LOD. LOD0 keeps the GLB's StaticBody3D
## collision unless with_collision is false; LOD1 is visual only and takes over beyond lod_distance_m.
## max_lod 0 forces the game LOD everywhere (for close-up review); max_lod 1 is the normal two-LOD group.
static func instance(id: String, with_collision: bool = true, max_lod: int = 1) -> Node3D:
	var entry := piece(id)
	if entry.is_empty():
		push_error("HabitatKit: unknown piece " + id)
		return null
	return instance_entry(entry, with_collision, max_lod)

## Builds a piece from a catalogue entry of this shape (id, lods, lod_distance_m), so kit extensions that keep
## their own catalogue (game/assets/environment/EN_Airlock/airlock.json, M3-2A) get the same two-LOD group.
static func instance_entry(entry: Dictionary, with_collision: bool = true, max_lod: int = 1) -> Node3D:
	var node := Node3D.new()
	node.name = String(entry.id)
	node.set_meta(PIECE_META, String(entry.id))  # survives a rename in a level (set_part_open looks the piece up by this)
	var switch := float(entry.get("lod_distance_m", 12.0))
	var lods: Array = entry.lods
	var last := mini(max_lod, lods.size() - 1)
	for lod in range(last + 1):
		var packed := _scene(lods[lod])
		if packed == null:
			push_error("HabitatKit: missing " + String(lods[lod]))
			continue
		var child := packed.instantiate() as Node3D
		child.name = "LOD%d" % lod
		for mesh in child.find_children("*", "MeshInstance3D", true, false):
			var geometry := mesh as GeometryInstance3D
			geometry.visibility_range_begin = switch if lod > 0 else 0.0
			geometry.visibility_range_end = switch if (lod == 0 and last > 0) else 0.0
			geometry.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		if lod > 0 or not with_collision:
			for body in child.find_children("*", "StaticBody3D", true, false):
				body.get_parent().remove_child(body)
				body.free()
		node.add_child(child)
	return node

## Instances a piece under parent at a grid position (the finished floor is y = 0) with a yaw in degrees.
## The piece's mount offset is applied for you, so floor tiles and ceiling tiles land on their planes.
static func place(parent: Node3D, id: String, position: Vector3, yaw_degrees: float = 0.0, with_collision: bool = true, max_lod: int = 1) -> Node3D:
	var node := instance(id, with_collision, max_lod)
	if node == null:
		return null
	node.position = position + Vector3(0.0, mount_y(id), 0.0)
	node.rotation_degrees = Vector3(0.0, yaw_degrees, 0.0)
	parent.add_child(node)
	return node

## Slides every DoorLeaf in the node along the module's +X by the catalogue travel times fraction (0 closed, 1 open).
static func set_door_open(node: Node3D, fraction: float) -> void:
	var sockets: Dictionary = piece("EN_Kit_DoorFrame").get("sockets", {})
	var travel := float(sockets.get("leaf_travel_m", 1.25))
	var rest := float(sockets.get("opening_centre", [-0.5, 0, 0])[0])
	for leaf in node.find_children(DOOR_LEAF, "Node3D", true, false):
		(leaf as Node3D).position.x = rest + travel * clampf(fraction, 0.0, 1.0)

## Swings every HatchLeaf in the node about its hinge towards the room (-Z) by the catalogue angle times fraction.
static func set_hatch_open(node: Node3D, fraction: float) -> void:
	var sockets: Dictionary = piece("EN_Kit_Hatch").get("sockets", {})
	var angle := float(sockets.get("open_rotation_deg_y", 100.0))
	for leaf in node.find_children(HATCH_LEAF, "Node3D", true, false):
		(leaf as Node3D).rotation_degrees.y = angle * clampf(fraction, 0.0, 1.0)

## Drives a named moving part of a piece from its catalogue "sockets.parts" entry (M3-3A annex pieces): fraction 0 is
## the GLB rest pose, 1 the open or displaced pose. Kinds: "rotate" (degrees about the part's local axis x, y or z),
## "slide" (metres along that axis) and "pose" (lerp from rest_position to position, with a yaw). Every child named
## after the part is driven (one per LOD). The node must be a piece built by instance(): the piece id travels in its
## "piece_id" meta, so a level may rename the node (falls back to the node name for pieces built another way).
static func set_part_open(node: Node3D, part: String, fraction: float) -> void:
	var id := piece_id(node)
	var parts: Dictionary = piece(id).get("sockets", {}).get("parts", {})
	if not parts.has(part):
		push_error("HabitatKit: piece %s has no moving part %s" % [id, part])
		return
	var spec: Dictionary = parts[part]
	var t := clampf(fraction, 0.0, 1.0)
	for leaf in node.find_children(part, "Node3D", true, false):
		var child := leaf as Node3D
		match String(spec.get("kind", "")):
			"rotate":
				var deg := float(spec.get("degrees", 0.0)) * t
				var rot := Vector3.ZERO
				match String(spec.get("axis", "y")):
					"x": rot.x = deg
					"z": rot.z = deg
					_: rot.y = deg
				child.rotation_degrees = rot
			"slide":
				if not child.has_meta("rest_position"):
					child.set_meta("rest_position", child.position)
				var rest: Vector3 = child.get_meta("rest_position")
				var axis := Vector3.RIGHT
				match String(spec.get("axis", "x")):
					"y": axis = Vector3.UP
					"z": axis = Vector3.BACK
				child.position = rest + axis * float(spec.get("metres", 0.0)) * t
			"pose":
				var rest_pose: Array = spec.get("rest_position", [child.position.x, child.position.y, child.position.z])
				var open_pose: Array = spec.get("position", rest_pose)
				child.position = Vector3(rest_pose[0], rest_pose[1], rest_pose[2]).lerp(Vector3(open_pose[0], open_pose[1], open_pose[2]), t)
				child.rotation_degrees = Vector3(0.0, float(spec.get("yaw_degrees", 0.0)) * t, 0.0)

## The live-UI surfaces of a piece: [{mesh: MeshInstance3D, surface: int}] for every surface whose material is
## named "Screen". Assign a ViewportTexture material with mesh.set_surface_override_material(surface, material).
static func screen_surfaces(node: Node3D) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for mesh in node.find_children("*", "MeshInstance3D", true, false):
		var instance_mesh := mesh as MeshInstance3D
		if instance_mesh.mesh == null:
			continue
		for surface in instance_mesh.mesh.get_surface_count():
			var material := instance_mesh.get_active_material(surface)
			if material != null and material.resource_name.begins_with(SCREEN_MATERIAL):
				out.append({"mesh": instance_mesh, "surface": surface})
	return out

## Axis-aligned bounds of a built piece's visual meshes, in the piece's local space.
static func bounds(node: Node3D, lod: int = 0) -> AABB:
	var box := AABB()
	var first := true
	var group := node.get_node_or_null("LOD%d" % lod)
	if group == null:
		return box
	for mesh in group.find_children("*", "MeshInstance3D", true, false):
		var instance_mesh := mesh as MeshInstance3D
		var xf := node.global_transform.affine_inverse() * instance_mesh.global_transform if node.is_inside_tree() else _local_transform(instance_mesh, node)
		var aabb := xf * instance_mesh.get_aabb()
		box = aabb if first else box.merge(aabb)
		first = false
	return box

static func _local_transform(leaf: Node3D, ancestor: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var current: Node = leaf
	while current != null and current != ancestor:
		if current is Node3D:
			xf = (current as Node3D).transform * xf
		current = current.get_parent()
	return xf
