## Chapter 1 architecture assembled from the approved metre-grid PBR habitat kit.
## Layout, portals, obstacles and traversal samples live in the existing room JSONs.
extends RefCounted

const Kit = preload("res://assets/environment/kit/habitat_kit.gd")
const Presentation = preload("res://scripts/world/room_presentation.gd")
const Airlock = preload("res://assets/environment/EN_Airlock/en_airlock.gd")
const Garage = preload("res://assets/environment/EN_Garage/en_garage.gd")
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
	if String(layout.get("shell", "")) == "garage":
		build_garage(room, layout)
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
			if not in_opening(layout, at):
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
	if layout.has("lower_deck"):
		_lower_deck(room, layout, batches)
	_publish(shell, batches)
	# Pressure connectors terminate at a second closed door. Location changes remain
	# explicit WorldRoute transitions; the player cannot walk off a staged room's deck.
	for portal in layout.portals:
		connector(room, layout, portal)
	if layout.get("floor_openings", []).is_empty():
		collider(room.collision_root, "FloorCollision", Vector3(0, -0.15, 0), Vector3(width, 0.3, depth))
	else:
		# The deck is solid everywhere except its openings (M3-3R: the N.R. hatch well, whose floor module brings its
		# own deck and leaf collision): one box per run of solid 1 m cells in each row.
		_cell_colliders(room.collision_root, "FloorCollision", layout.floor_openings, Vector2(-width * 0.5, -depth * 0.5), width, depth, -0.15, 0.3)
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
	# "shell_yaw_deg" turns the module about the room centre (LOC-05: 180, so the garden wall is the north wall and
	# every station is approached from +Z like the other rooms' equipment walls).
	var turn := Basis(Vector3.UP, deg_to_rad(float(layout.get("shell_yaw_deg", 0.0))))
	airlock.transform = Transform3D(turn, turn * Vector3(-float(layout.bounds_m[0]) * 0.5, 0, -float(layout.bounds_m[1]) * 0.5))
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
	for portal in layout.portals:
		connector(room, layout, portal)
	var width := float(layout.bounds_m[0])
	var depth := float(layout.bounds_m[1])
	collider(room.collision_root, "FloorCollision", Vector3(0, -0.15, 0), Vector3(width, 0.3, depth))
	collider(room.collision_root, "CeilingCollision", Vector3(0, float(layout.ceiling_height_m) + 0.1, 0), Vector3(width, 0.2, depth))

## LOC-08 (M3-105): the approved M3-4A garage (en_garage.gd from garage.json, decisions 1-7) as the room shell, moved by
## layout "shell_offset_m" so the room centre is the origin and the ready-room deck is y = 0 like every kit room (the
## vacuum bay floor is then y = -1.40). The garage keeps running on its own node ("Garage": the dock tunnel cycle, the
## dock hatch, the rover door, the cargo lock, the relief locker); the pieces named in "garage_roles" and the docked
## rover move under VisualRoot with their role as name; the inner door becomes the room's portal (a KitDoor with its
## corridor connector, decision 2). The room's practicals replace the kit light strips (as in LOC-05), the bay keeps
## its 5,000 K floods (layout "bay_floods"), and the deck, its ceiling and the porch stair get collision.
static func build_garage(room: Node3D, layout: Dictionary) -> void:
	var garage := Garage.new()
	garage.name = "Garage"
	garage.build_on_ready = false
	garage.with_lights = false
	garage.position = Presentation.vector(layout.shell_offset_m)
	room.visual_root.add_child(garage)
	garage.build()
	var door: Node3D = garage.nodes.get("inner_door")
	if door != null:
		garage.nodes.erase("inner_door")
		garage.remove_child(door)
		door.free()
	var batches: Dictionary = {}
	for child in garage.get_children():
		var id := _airlock_piece(String(child.name))
		if id in AIRLOCK_BATCHED or id in AIRLOCK_DROPPED:
			if id in AIRLOCK_BATCHED:
				if not batches.has(id):
					batches[id] = []
				batches[id].append(garage.transform * (child as Node3D).transform)
			garage.remove_child(child)
			child.free()
	var shell := Node3D.new()
	shell.name = "HabitatKit"
	room.visual_root.add_child(shell)
	_publish(shell, batches)
	for role in layout.get("garage_roles", []):
		var node: Node3D = garage.rover if String(role) == "VH_Rover" else garage.nodes.get(String(role))
		if node == null:
			continue
		var placed := garage.transform * node.transform
		garage.remove_child(node)
		node.name = String(role)
		node.transform = placed
		room.visual_root.add_child(node)
	for portal in layout.portals:
		connector(room, layout, portal)
	var deck: Dictionary = layout.deck
	var low := Vector2(deck.min[0], deck.min[1])
	var high := Vector2(deck.max[0], deck.max[1])
	var centre := (low + high) * 0.5
	collider(room.collision_root, "FloorCollision", Vector3(centre.x, -0.15, centre.y), Vector3(high.x - low.x, 0.3, high.y - low.y))
	collider(room.collision_root, "CeilingCollision", Vector3(centre.x, float(layout.ceiling_height_m) + 0.1, centre.y), Vector3(high.x - low.x, 0.2, high.y - low.y))
	# The porch stair is drawn as steps on EN_Garage_EVAPorch but has no collision of its own: one ramp over the nosings.
	var stair: Dictionary = layout.get("stair", {})
	if not stair.is_empty():
		var top := Presentation.vector(stair.top)
		var foot := Presentation.vector(stair.bottom)
		var run := Vector2(foot.x - top.x, foot.y - top.y)
		var ramp := collider(room.collision_root, "StairRamp", (top + foot) * 0.5 - Vector3(0, 0.03, 0), Vector3(run.length(), 0.06, float(stair.width_m)))
		ramp.rotation.z = atan2(run.y, run.x)
	# The floods live with the garage's own geometry (RoomLighting is built after the shell and holds the ready room's
	# practicals, which chapter staging dims; the vacuum bay's work lights stay as they are).
	var floods := Node3D.new()
	floods.name = "BayFloods"
	room.visual_root.add_child(floods)
	for index in layout.get("bay_floods", []).size():
		var spec: Dictionary = layout.bay_floods[index]
		var flood := SpotLight3D.new()
		flood.name = "BayFlood_%d" % index
		flood.position = Presentation.vector(spec.position)
		flood.rotation_degrees = Vector3(-90, 0, 0)
		flood.light_color = Garage.BAY_LIGHT
		flood.light_energy = float(spec.get("energy", 6.0))
		flood.spot_range = float(spec.get("range_m", 8.0))
		flood.spot_angle = float(spec.get("angle_deg", 66.0))
		flood.shadow_enabled = bool(spec.get("shadow", false))
		floods.add_child(flood)

## The kit or airlock piece id a placed node was named after (Godot adds "@...@n" to repeated sibling names).
static func _airlock_piece(node_name: String) -> String:
	var id := node_name.trim_prefix("@")
	return id.get_slice("@", 0)

## True when a point lies inside one of the layout's "floor_openings" ({"center": [x, z], "size": [w, d]}).
static func in_opening(layout: Dictionary, at: Vector3) -> bool:
	return _inside_any(layout.get("floor_openings", []), at)

static func _inside_any(openings: Array, at: Vector3) -> bool:
	for opening in openings:
		var half := Vector2(float(opening.size[0]), float(opening.size[1])) * 0.5
		if absf(at.x - float(opening.center[0])) < half.x and absf(at.z - float(opening.center[1])) < half.y:
			return true
	return false

static func _cell_colliders(parent: Node3D, id: String, openings: Array, origin: Vector2, width: int, depth: int, y: float, thickness: float) -> void:
	for z in depth:
		var run_start := -1
		for x in width + 1:
			var solid := x < width and not _inside_any(openings, Vector3(origin.x + x + 0.5, 0, origin.y + z + 0.5))
			if solid and run_start < 0:
				run_start = x
			elif not solid and run_start >= 0:
				collider(parent, id, Vector3(origin.x + (run_start + x) * 0.5, y, origin.y + z + 0.5), Vector3(x - run_start, thickness, 1.0))
				run_start = -1

## M3-3R: a lower deck under the room (LOC-07: the 2034 annex 3 m below the warm-side bay), batched from the deck's own
## pieces (EN_ZeroAnnex grating, frosted ceiling with dead fixtures, riveted walls and corners) with metre-space
## collision. "lower_deck": {"y", "bounds": [x0, z0, x1, z1] (whole metres), "ceiling_height_m", "pieces": {floor,
## ceiling, lamp, wall, corner}, "lamp_cells": [[x, z], ...] (cell minimum corners), "well": {"center", "size"} (open up
## to the deck above, lined between the two ceilings)}.
static func _lower_deck(room: Node3D, layout: Dictionary, batches: Dictionary) -> void:
	var deck: Dictionary = layout.lower_deck
	var y := float(deck.y)
	var b: Array = deck.bounds
	var x0 := int(b[0])
	var z0 := int(b[1])
	var x1 := int(b[2])
	var z1 := int(b[3])
	var height := float(deck.get("ceiling_height_m", 2.6))
	var pieces: Dictionary = deck.pieces
	var wells: Array = [deck.well] if deck.has("well") else []
	var lamps: Array = deck.get("lamp_cells", [])
	for x in range(x0, x1):
		for z in range(z0, z1):
			var at := Vector3(x + 0.5, y, z + 0.5)
			_batch(batches, String(pieces.floor), at)
			if not _inside_any(wells, at):
				var lamp := lamps.any(func(c): return int(c[0]) == x and int(c[1]) == z)
				_batch(batches, String(pieces.lamp if lamp else pieces.ceiling), at)
	for x in range(x0 + 1, x1):
		_batch(batches, String(pieces.wall), Vector3(x, y, z1), 0)
		_batch(batches, String(pieces.wall), Vector3(x, y, z0), 180)
	for z in range(z0 + 1, z1):
		_batch(batches, String(pieces.wall), Vector3(x0, y, z), -90)
		_batch(batches, String(pieces.wall), Vector3(x1, y, z), 90)
	for corner in [[x0, z0, 180], [x1, z0, 90], [x0, z1, -90], [x1, z1, 0]]:
		_batch(batches, String(pieces.corner), Vector3(corner[0], y, corner[1]), corner[2])
	var centre := Vector3((x0 + x1) * 0.5, y, (z0 + z1) * 0.5)
	var size := Vector2(x1 - x0, z1 - z0)
	collider(room.collision_root, "LowerFloorCollision", centre + Vector3(0, -0.15, 0), Vector3(size.x, 0.3, size.y))
	for wall in [[Vector3(0, 0, -size.y * 0.5), Vector3(size.x, height, 0.18)], [Vector3(0, 0, size.y * 0.5), Vector3(size.x, height, 0.18)],
			[Vector3(-size.x * 0.5, 0, 0), Vector3(0.18, height, size.y)], [Vector3(size.x * 0.5, 0, 0), Vector3(0.18, height, size.y)]]:
		collider(room.collision_root, "LowerWall", centre + wall[0] + Vector3(0, height * 0.5, 0), wall[1])
	_cell_colliders(room.collision_root, "LowerCeilingCollision", wells, Vector2(x0, z0), x1 - x0, z1 - z0, y + height + 0.1, 0.2)
	for well in wells:
		# The well's lining between the annex ceiling and the upper deck, so nobody looks into the slab.
		var at := Vector3(float(well.center[0]), 0, float(well.center[1]))
		var half := Vector2(float(well.size[0]), float(well.size[1])) * 0.5
		var low := y + height
		for side in [[Vector3(0, 0, -half.y), Vector3(half.x * 2.0, -low, 0.04)], [Vector3(0, 0, half.y), Vector3(half.x * 2.0, -low, 0.04)],
				[Vector3(-half.x, 0, 0), Vector3(0.04, -low, half.y * 2.0)], [Vector3(half.x, 0, 0), Vector3(0.04, -low, half.y * 2.0)]]:
			var middle: Vector3 = at + side[0] + Vector3(0, low * 0.5, 0)
			collider(room.collision_root, "WellLining", middle, side[1])
			Presentation.mesh_box(room.visual_root, "WellLining", middle, side[1], Color(deck.get("well_color", "#3b4034")), false, true)

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
	for mesh in passage.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
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
	if layout.navigation.has("areas"):
		_area_navigation(mesh, layout, cell, radius)
		region.navigation_mesh = mesh
		parent.add_child(region)
		region.set_navigation_map(nav_map)
		return
	var width := float(layout.bounds_m[0])
	var depth := float(layout.bounds_m[1])
	var vertices := PackedVector3Array()
	# A lower deck (M3-3R, LOC-07) is a second, unconnected walkable grid in the same mesh: the ladder between the two
	# is climbed, never walked. Each obstacle belongs to the deck its centre stands in.
	var split := -1.0e9
	if layout.has("lower_deck"):
		split = float(layout.lower_deck.y) + float(layout.lower_deck.get("ceiling_height_m", 2.6))
	vertices = _deck_cells(mesh, vertices, Vector2(-width * 0.5, -depth * 0.5), width, depth, 0.0, cell, radius, layout.obstacles.filter(func(o): return float(o.position[1]) >= split))
	if layout.has("lower_deck"):
		var b: Array = layout.lower_deck.bounds
		vertices = _deck_cells(mesh, vertices, Vector2(float(b[0]), float(b[1])), float(b[2]) - float(b[0]), float(b[3]) - float(b[1]), float(layout.lower_deck.y), cell, radius, layout.obstacles.filter(func(o): return float(o.position[1]) < split))
	mesh.vertices = vertices
	region.navigation_mesh = mesh
	parent.add_child(region)
	region.set_navigation_map(nav_map)

## Appends one deck's walkable cells: the wall clearance and each grown furniture footprint are rasterised once; a cell
## is blocked when it overlaps a footprint by more than a touching edge.
static func _deck_cells(mesh: NavigationMesh, vertices: PackedVector3Array, origin: Vector2, width: float, depth: float, y: float, cell: float, radius: float, obstacles: Array) -> PackedVector3Array:
	var nx := int(width / cell)
	var nz := int(depth / cell)
	var base := vertices.size()
	for z in range(nz + 1):
		for x in range(nx + 1):
			vertices.append(Vector3(origin.x + x * cell, y, origin.y + z * cell))
	var blocked := PackedByteArray()
	blocked.resize(nx * nz)
	var edge := ceili(radius / cell - 0.0001)
	_block_cells(blocked, nx, 0, edge, 0, nz)
	_block_cells(blocked, nx, nx - edge, nx, 0, nz)
	_block_cells(blocked, nx, 0, nx, 0, edge)
	_block_cells(blocked, nx, 0, nx, nz - edge, nz)
	for obstacle in obstacles:
		var at := Presentation.vector(obstacle.position)
		var size := Presentation.vector(obstacle.size)
		var low := Vector2(at.x - size.x * 0.5 - radius - origin.x, at.z - size.z * 0.5 - radius - origin.y) / cell
		var high := Vector2(at.x + size.x * 0.5 + radius - origin.x, at.z + size.z * 0.5 + radius - origin.y) / cell
		_block_cells(blocked, nx, floori(low.x + 0.0001), ceili(high.x - 0.0001), floori(low.y + 0.0001), ceili(high.y - 0.0001))
	for z in nz:
		for x in nx:
			if blocked[z * nx + x] == 0:
				var a := base + z * (nx + 1) + x
				mesh.add_polygon(PackedInt32Array([a, a + 1, a + nx + 2, a + nx + 1]))
	return vertices

## M3-105: walkable "areas" at their own heights (LOC-08: the ready-room deck, the EVA porch, its stair and the vacuum
## bay floor): each {"id", "min": [x, z], "max": [x, z], "y" or "ramp": {"axis": "x", "from": [x, y], "to": [x, y]},
## "open": edges ("west", "east", "north", "south") that join another area, so they keep no wall clearance}. Corners lie
## on the room's cell lattice, so areas that meet at the same height share vertices and connect; an obstacle blocks
## the areas its height overlaps, or only the one named by its "area".
static func _area_navigation(mesh: NavigationMesh, layout: Dictionary, cell: float, radius: float) -> void:
	var vertices := PackedVector3Array()
	var shared := {}
	var edge := ceili(radius / cell - 0.0001)
	for area in layout.navigation.areas:
		var lo := Vector2(float(area.min[0]), float(area.min[1]))
		var hi := Vector2(float(area.max[0]), float(area.max[1]))
		var nx := int(round((hi.x - lo.x) / cell))
		var nz := int(round((hi.y - lo.y) / cell))
		var open: Array = area.get("open", [])
		var blocked := PackedByteArray()
		blocked.resize(nx * nz)
		if not open.has("west"):
			_block_cells(blocked, nx, 0, edge, 0, nz)
		if not open.has("east"):
			_block_cells(blocked, nx, nx - edge, nx, 0, nz)
		if not open.has("north"):
			_block_cells(blocked, nx, 0, nx, 0, edge)
		if not open.has("south"):
			_block_cells(blocked, nx, 0, nx, nz - edge, nz)
		var floor_low := minf(_area_y(area, lo.x, lo.y), _area_y(area, hi.x, hi.y))
		var floor_high := maxf(_area_y(area, lo.x, lo.y), _area_y(area, hi.x, hi.y))
		for obstacle in layout.obstacles:
			var at := Presentation.vector(obstacle.position)
			var size := Presentation.vector(obstacle.size)
			if obstacle.has("area"):
				if String(obstacle.area) != String(area.id):
					continue
			elif at.y + size.y * 0.5 < floor_low + 0.05 or at.y - size.y * 0.5 > floor_high + 1.8:
				continue
			var a := (Vector2(at.x - size.x * 0.5 - radius, at.z - size.z * 0.5 - radius) - lo) / cell
			var b := (Vector2(at.x + size.x * 0.5 + radius, at.z + size.z * 0.5 + radius) - lo) / cell
			_block_cells(blocked, nx, floori(a.x + 0.0001), ceili(b.x - 0.0001), floori(a.y + 0.0001), ceili(b.y - 0.0001))
		for z in nz:
			for x in nx:
				if blocked[z * nx + x] != 0:
					continue
				var corners := PackedInt32Array()
				for corner: Vector2i in [Vector2i(x, z), Vector2i(x + 1, z), Vector2i(x + 1, z + 1), Vector2i(x, z + 1)]:
					var px: float = lo.x + corner.x * cell
					var pz: float = lo.y + corner.y * cell
					var point := Vector3(px, _area_y(area, px, pz), pz)
					var key := Vector3i(roundi(point.x * 1000.0), roundi(point.y * 1000.0), roundi(point.z * 1000.0))
					if not shared.has(key):
						shared[key] = vertices.size()
						vertices.append(point)
					corners.append(int(shared[key]))
				mesh.add_polygon(corners)
	mesh.vertices = vertices

static func _area_y(area: Dictionary, x: float, z: float) -> float:
	if not area.has("ramp"):
		return float(area.get("y", 0.0))
	var ramp: Dictionary = area.ramp
	var along := x if String(ramp.get("axis", "x")) == "x" else z
	var t := clampf((along - float(ramp.from[0])) / (float(ramp.to[0]) - float(ramp.from[0])), 0.0, 1.0)
	return lerpf(float(ramp.from[1]), float(ramp.to[1]), t)

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
		# M1-94: chunk large shell batches into spatial quadrants centered at their centroid so frustum culling drops
		# tiles/overhead runs behind the camera and visibility_range switches distant quadrants to LOD1; boundary shell
		# tiles/walls/runs cast no shadows into the interior omni shadow maps.
		var transforms: Array = batches[id]
		var groups: Array = []
		if transforms.size() >= 32:
			var quadrants := {Vector2i(0, 0): [], Vector2i(1, 0): [], Vector2i(0, 1): [], Vector2i(1, 1): []}
			for xf: Transform3D in transforms:
				var q := Vector2i(1 if xf.origin.x >= 0.0 else 0, 1 if xf.origin.z >= 0.0 else 0)
				quadrants[q].append(xf)
			for q in quadrants:
				if not quadrants[q].is_empty():
					groups.append({"suffix": "_Q%d%d" % [q.x, q.y], "items": quadrants[q]})
		else:
			groups.append({"suffix": "", "items": transforms})
		var split := 12.0
		for group in groups:
			var items: Array = group.items
			var center := Vector3.ZERO
			for xf: Transform3D in items:
				center += xf.origin
			center /= float(items.size())
			for source in _templates[id]:
				var lod := int(source.lod)
				var batch := MultiMeshInstance3D.new()
				batch.name = String(id) + "_" + String(source.name) + String(group.suffix) + "_LOD%d" % lod
				batch.position = center
				batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				batch.multimesh = MultiMesh.new()
				batch.multimesh.transform_format = MultiMesh.TRANSFORM_3D
				batch.multimesh.mesh = source.mesh
				batch.multimesh.instance_count = items.size()
				for index in items.size():
					var world_xf: Transform3D = items[index] * source.transform
					batch.multimesh.set_instance_transform(index, Transform3D(world_xf.basis, world_xf.origin - center))
				batch.visibility_range_begin = split if lod == 1 else 0.0
				batch.visibility_range_end = split if lod == 0 else 0.0
				parent.add_child(batch)
