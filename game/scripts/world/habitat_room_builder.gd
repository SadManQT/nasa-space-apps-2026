## Chapter 1 architecture assembled from the approved metre-grid PBR habitat kit.
## Layout, portals, obstacles and traversal samples live in the existing room JSONs.
extends RefCounted

const Kit = preload("res://assets/environment/kit/habitat_kit.gd")
const Presentation = preload("res://scripts/world/room_presentation.gd")
const Airlock = preload("res://assets/environment/EN_Airlock/en_airlock.gd")
## Airlock shell pieces the room replaces: floor and ceiling tiles become MultiMesh batches over the room's floor and
## ceiling collision proxies, and the kit light strips give way to the room's practical fixtures (ceiling_strips).
const AIRLOCK_BATCHED := ["EN_Kit_FloorTile", "EN_Kit_CeilingTile"]
const AIRLOCK_DROPPED := ["EN_Kit_LightStrip"]
static var _templates: Dictionary = {}

## Builds batched kit geometry and a closed physical shell with actual portal holes.
static func build(room: Node3D, layout: Dictionary) -> void:
	if String(layout.get("shell", "")) == "airlock":
		build_airlock(room, layout)
		return
	var shell := Node3D.new()
	shell.name = "HabitatKit"
	room.visual_root.add_child(shell)
	var batches: Dictionary = {}
	var width := int(layout.bounds_m[0])
	var depth := int(layout.bounds_m[1])
	var height := float(layout.ceiling_height_m)
	for x in width:
		for z in depth:
			var at := Vector3(x - width * 0.5 + 0.5, 0, z - depth * 0.5 + 0.5)
			_batch(batches, "EN_Kit_FloorTile", at)
			_batch(batches, "EN_Kit_CeilingTile", at)
	for side in ["north", "south", "west", "east"]:
		var length := width if side in ["north", "south"] else depth
		for index in range(1, length):
			var offset := float(index) - length * 0.5
			var in_portal := false
			for portal in layout.portals:
				if portal.wall == side and absf(offset - float(portal.offset_m)) <= 1.0:
					in_portal = true
			if in_portal:
				continue
			var piece := "EN_Kit_Wall_Straight"
			if index % 5 == 0:
				piece = "EN_Kit_Wall_EquipBay" if side in ["west", "east"] else "EN_Kit_Wall_Window"
			_batch(batches, piece, wall_point(layout, side, offset), wall_yaw(side))
		# Collision spans the solid walls only. Each door frame supplies its jambs/header.
		var cuts: Array = [-length * 0.5]
		for portal in layout.portals:
			if portal.wall == side:
				cuts.append(float(portal.offset_m) - 1.5)
				cuts.append(float(portal.offset_m) + 1.5)
		cuts.append(length * 0.5)
		cuts.sort()
		for index in range(0, cuts.size() - 1, 2):
			var span := float(cuts[index + 1]) - float(cuts[index])
			var center := wall_point(layout, side, (float(cuts[index]) + float(cuts[index + 1])) * 0.5)
			center.y = height * 0.5
			var size := Vector3(span, height, 0.18) if side in ["north", "south"] else Vector3(0.18, height, span)
			collider(room.collision_root, side + "Wall", center, size)
	for corner in [[-1, -1, 180], [1, -1, 90], [-1, 1, -90], [1, 1, 0]]:
		_batch(batches, "EN_Kit_Wall_Corner", Vector3(corner[0] * width * 0.5, 0, corner[1] * depth * 0.5), corner[2])
	for run in layout.get("kit_runs", []):
		for index in int(run.count):
			var at := Presentation.vector(run.position) + Presentation.vector(run.step) * index
			_batch(batches, String(run.piece), at, float(run.get("yaw", 0)))
	_publish(shell, batches)
	# Pressure connectors terminate at a second closed door. Location changes remain
	# explicit WorldRoute transitions; the player cannot walk off a staged room's deck.
	for portal in layout.portals:
		connector(room, layout, portal)
	collider(room.collision_root, "FloorCollision", Vector3(0, -0.15, 0), Vector3(width, 0.3, depth))
	collider(room.collision_root, "CeilingCollision", Vector3(0, height + 0.1, 0), Vector3(width, 0.2, depth))

## LOC-05 (M3-2R): the approved M3-2A double-interlock vestibule (en_airlock.gd from airlock.json, 8 x 4 m) as the
## room shell, moved so the room centre is the origin like every kit room. The interlock keeps running on its own
## node ("Airlock": hatches, panels, lamps, pump, pass-through lids); the pieces named in layout "airlock_roles" move
## under VisualRoot with their role as name, so focus targets and selection frames find them like any other prop;
## the inner door becomes the room's portal (a KitDoor that mirrors WorldRoute, with its corridor connector).
static func build_airlock(room: Node3D, layout: Dictionary) -> void:
	var airlock := Airlock.new()
	airlock.name = "Airlock"
	airlock.build_on_ready = false
	airlock.with_lights = false
	airlock.position = Vector3(-float(layout.bounds_m[0]) * 0.5, 0, -float(layout.bounds_m[1]) * 0.5)
	room.visual_root.add_child(airlock)
	airlock.build()
	var door: Node3D = airlock.nodes.get("inner_door")
	if door != null:
		airlock.nodes.erase("inner_door")
		airlock.remove_child(door)
		door.free()
	var batches: Dictionary = {}
	for child in airlock.get_children():
		var id := _airlock_piece(String(child.name))
		if id in AIRLOCK_BATCHED or id in AIRLOCK_DROPPED:
			if id in AIRLOCK_BATCHED:
				if not batches.has(id):
					batches[id] = []
				batches[id].append(airlock.transform * (child as Node3D).transform)
			airlock.remove_child(child)
			child.free()
	var shell := Node3D.new()
	shell.name = "HabitatKit"
	room.visual_root.add_child(shell)
	_publish(shell, batches)
	for role in layout.get("airlock_roles", []):
		var node: Node3D = airlock.nodes.get(String(role))
		if node == null:
			continue
		var placed := airlock.transform * node.transform
		airlock.remove_child(node)
		node.name = String(role)
		node.transform = placed
		room.visual_root.add_child(node)
		if String(role) == "glove_ports":
			open_window_back(node)
	for portal in layout.portals:
		connector(room, layout, portal)
	var width := float(layout.bounds_m[0])
	var depth := float(layout.bounds_m[1])
	collider(room.collision_root, "FloorCollision", Vector3(0, -0.15, 0), Vector3(width, 0.3, depth))
	collider(room.collision_root, "CeilingCollision", Vector3(0, float(layout.ceiling_height_m) + 0.1, 0), Vector3(width, 0.2, depth))

## Opens the back of a wall module that reuses the kit window frame. EN_Airlock_GlovePort closes its back face with
## one 1.0 x 2.6 m plate (two triangles, drawn double-sided), so its pressure window showed grey paint instead of
## Alo's sealed chamber. This drops only that plate from the placed copy (the GLB is unchanged): the room data builds
## the chamber walls behind the module, and the window and ports seal the wall as before. Returns triangles dropped.
static func open_window_back(module: Node3D) -> int:
	var dropped := 0
	for child in module.find_children("*", "MeshInstance3D", true, false):
		var instance := child as MeshInstance3D
		var source := instance.mesh as ArrayMesh
		if source == null:
			continue
		var opened := ArrayMesh.new()
		var removed := 0
		for surface in source.get_surface_count():
			var arrays := source.surface_get_arrays(surface)
			var index_data: Variant = arrays[Mesh.ARRAY_INDEX]
			if index_data is PackedInt32Array:
				var indices: PackedInt32Array = index_data
				var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				var kept := PackedInt32Array()
				for t in indices.size() / 3:
					var a := vertices[indices[t * 3]]
					var b := vertices[indices[t * 3 + 1]]
					var c := vertices[indices[t * 3 + 2]]
					# the back plate: behind the module's front face, flat, and larger than any other part (> 0.5 m2)
					if a.z > 0.1 and absf(a.z - b.z) < 0.001 and absf(a.z - c.z) < 0.001 and (b - a).cross(c - a).length() * 0.5 > 0.5:
						removed += 1
						continue
					kept.append(indices[t * 3])
					kept.append(indices[t * 3 + 1])
					kept.append(indices[t * 3 + 2])
				arrays[Mesh.ARRAY_INDEX] = kept
			opened.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			opened.surface_set_material(surface, source.surface_get_material(surface))
			opened.surface_set_name(surface, source.surface_get_name(surface))
		if removed > 0:
			instance.mesh = opened
			dropped += removed
	return dropped

## The kit or airlock piece id a placed node was named after (Godot adds "@...@n" to repeated sibling names).
static func _airlock_piece(node_name: String) -> String:
	var id := node_name.trim_prefix("@")
	return id.get_slice("@", 0)

## Adds the approved corridor rings behind a portal, with a pressure-rated end door.
static func connector(room: Node3D, layout: Dictionary, portal: Dictionary) -> void:
	var passage := Node3D.new()
	passage.name = "Connector_" + String(portal.boundary_id)
	passage.rotation_degrees.y = wall_yaw(String(portal.wall))
	passage.position = wall_point(layout, String(portal.wall), float(portal.offset_m))
	room.visual_root.add_child(passage)
	var count := int(portal.get("corridor_segments", 1))
	for index in count:
		Kit.place(passage, "EN_Kit_BulkheadRing", Vector3(-0.5, 0, 0.765 + index))
		Kit.place(passage, "EN_Kit_LightStrip", Vector3(-0.5, -0.3, 0.765 + index), 90, false)
	var end := Kit.place(passage, "EN_Kit_DoorFrame", Vector3(-1, 0, count + 0.53), 180)
	Kit.set_door_open(end, 0)
	collider(passage, "ThresholdDeck", Vector3(-0.5, -0.06, count + 0.36), Vector3(0.96, 0.12, 0.6))
	var light := OmniLight3D.new()
	light.position = Vector3(-0.5, 1.9, 0.7)
	light.omni_range = count + 2.0
	light.light_color = Color(layout.lighting.key_color)
	light.light_energy = 0.35
	passage.add_child(light)

## The wall-plane point of a grid-aligned module (door opening is offset within it).
static func wall_point(layout: Dictionary, wall: String, offset: float) -> Vector3:
	match wall:
		"north": return Vector3(offset, 0, -float(layout.bounds_m[1]) * 0.5)
		"south": return Vector3(offset, 0, float(layout.bounds_m[1]) * 0.5)
		"west": return Vector3(-float(layout.bounds_m[0]) * 0.5, 0, offset)
	return Vector3(float(layout.bounds_m[0]) * 0.5, 0, offset)

## Kit panels face into the room; their thickness sits outside its usable footprint.
static func wall_yaw(wall: String) -> float:
	return {"north": 180.0, "south": 0.0, "west": -90.0, "east": 90.0}[wall]

## Creates a metre-space collision proxy shared by shell, furniture and navigation.
static func collider(parent: Node3D, id: String, at: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = id
	body.position = at
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	parent.add_child(body)
	return body

## Builds connected navigation cells, subtracting furniture with agent-radius clearance.
## A separate map per staged room prevents overlapping local coordinates from merging.
static func navigation(parent: Node3D, layout: Dictionary) -> void:
	var region := NavigationRegion3D.new()
	region.name = "NavigationRegion"
	# One static mesh is published during the loading card. Synchronous region
	# publication avoids Godot 4.7.2's lost consecutive async region update (#124766).
	NavigationServer3D.region_set_use_async_iterations(region.get_rid(), false)
	var nav_map := NavigationServer3D.map_create()
	NavigationServer3D.map_set_use_async_iterations(nav_map, false)
	NavigationServer3D.map_set_active(nav_map, true)
	region.set_meta("private_navigation_map", nav_map)
	var mesh := NavigationMesh.new()
	var cell := float(layout.navigation.cell_m)
	mesh.cell_size = cell
	NavigationServer3D.map_set_cell_size(nav_map, cell)
	NavigationServer3D.map_set_cell_height(nav_map, mesh.cell_height)
	var radius := float(layout.navigation.agent_radius_m)
	var width := float(layout.bounds_m[0])
	var depth := float(layout.bounds_m[1])
	var nx := int(width / cell)
	var nz := int(depth / cell)
	var vertices := PackedVector3Array()
	for z in range(nz + 1):
		for x in range(nx + 1):
			vertices.append(Vector3(-width * 0.5 + x * cell, 0, -depth * 0.5 + z * cell))
	mesh.vertices = vertices
	# Rasterise the wall clearance and each grown furniture footprint once. A cell is
	# blocked when it overlaps a footprint by more than a touching edge.
	var blocked := PackedByteArray()
	blocked.resize(nx * nz)
	var edge := ceili(radius / cell - 0.0001)
	_block_cells(blocked, nx, 0, edge, 0, nz)
	_block_cells(blocked, nx, nx - edge, nx, 0, nz)
	_block_cells(blocked, nx, 0, nx, 0, edge)
	_block_cells(blocked, nx, 0, nx, nz - edge, nz)
	for obstacle in layout.obstacles:
		var at := Presentation.vector(obstacle.position)
		var size := Presentation.vector(obstacle.size)
		var low := Vector2(at.x - size.x * 0.5 - radius + width * 0.5, at.z - size.z * 0.5 - radius + depth * 0.5) / cell
		var high := Vector2(at.x + size.x * 0.5 + radius + width * 0.5, at.z + size.z * 0.5 + radius + depth * 0.5) / cell
		_block_cells(blocked, nx, floori(low.x + 0.0001), ceili(high.x - 0.0001), floori(low.y + 0.0001), ceili(high.y - 0.0001))
	for z in nz:
		for x in nx:
			if blocked[z * nx + x] == 0:
				var a := z * (nx + 1) + x
				mesh.add_polygon(PackedInt32Array([a, a + 1, a + nx + 2, a + nx + 1]))
	region.navigation_mesh = mesh
	parent.add_child(region)
	region.set_navigation_map(nav_map)

static func _block_cells(blocked: PackedByteArray, nx: int, x0: int, x1: int, z0: int, z1: int) -> void:
	var nz := blocked.size() / nx
	for z in range(maxi(z0, 0), mini(z1, nz)):
		for x in range(maxi(x0, 0), mini(x1, nx)):
			blocked[z * nx + x] = 1

static func _batch(batches: Dictionary, id: String, at: Vector3, yaw: float = 0) -> void:
	if not batches.has(id):
		batches[id] = []
	at.y += Kit.mount_y(id)
	batches[id].append(Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), at))

static func _publish(parent: Node3D, batches: Dictionary) -> void:
	for id in batches:
		if not _templates.has(id):
			var template := Kit.instance(id, false)
			var sources: Array = []
			for lod in 2:
				for source in template.get_node("LOD%d" % lod).find_children("*", "MeshInstance3D", true, false):
					var xf := source.transform as Transform3D
					var ancestor := source.get_parent()
					while ancestor != template:
						xf = ancestor.transform * xf
						ancestor = ancestor.get_parent()
					sources.append({"mesh": source.mesh, "name": String(source.name), "transform": xf, "lod": lod})
			_templates[id] = sources
			template.free()
		for source in _templates[id]:
			var lod := int(source.lod)
			var batch := MultiMeshInstance3D.new()
			batch.name = String(id) + "_" + String(source.name) + "_LOD%d" % lod
			batch.multimesh = MultiMesh.new()
			batch.multimesh.transform_format = MultiMesh.TRANSFORM_3D
			batch.multimesh.mesh = source.mesh
			batch.multimesh.instance_count = batches[id].size()
			for index in batches[id].size():
				batch.multimesh.set_instance_transform(index, batches[id][index] * source.transform)
			batch.visibility_range_begin = 12.0 if lod == 1 else 0.0
			batch.visibility_range_end = 12.0 if lod == 0 else 0.0
			parent.add_child(batch)
