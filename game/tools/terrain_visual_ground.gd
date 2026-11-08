## M1-91: the visible terrain surface near a room: the triangles of the finest LOD tile meshes that TerrainStream shows
## around the player (cold_trap and aurora_ridge: LOD1, 20 m vertex spacing), in the region's site frame. Collision and
## the published anchors follow the 10 m detail heightfield, which the 20 m mesh smooths over, so the visible ground
## can stand tens of centimetres above or below it; a small prop placed on the heightfield can vanish into the visible
## ground. test_terrain_work_lights.gd rests the hand light on what the player sees with it, tests lamp beams against it
## and reports how far it stands off the heightfield (terrain integration follow-up).
extends RefCounted

const Region = preload("res://assets/environment/terrain/lola/lola_region.gd")
const CELL_M := 20.0
## Vec2i cell -> PackedVector3Array of triangle corners (site frame), every triangle overlapping the cell in plan.
var _cells: Dictionary = {}

## The visible surface of region_id's finest tiles that overlap the site-frame rectangle area (x, z).
static func load_region(region_id: String, area: Rect2) -> RefCounted:
	var ground: RefCounted = (load("res://tools/terrain_visual_ground.gd") as GDScript).new()
	for entry in Region.tiles_info(region_id).get("tiles", []):
		var half := float(entry.size_m) * 0.5
		var tile := Rect2(float(entry.center_x_m) - half, float(entry.center_z_m) - half, half * 2.0, half * 2.0)
		if not tile.intersects(area):
			continue
		var finest: Dictionary = entry.lods[0]
		for lod in entry.lods:
			if int(lod.lod) < int(finest.lod):
				finest = lod
		var scene := load(String(finest.path)) as PackedScene
		if scene == null:
			continue
		var node := scene.instantiate() as Node3D
		ground._add(node, Transform3D(Basis.IDENTITY, Vector3(float(entry.center_x_m), 0, float(entry.center_z_m))), area)
		node.free()
	return ground

func _add(node: Node, into: Transform3D, area: Rect2) -> void:
	var here := into * (node as Node3D).transform if node is Node3D else into
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		var faces := (node as MeshInstance3D).mesh.get_faces()
		for index in range(0, faces.size(), 3):
			var a: Vector3 = here * faces[index]
			var b: Vector3 = here * faces[index + 1]
			var c: Vector3 = here * faces[index + 2]
			# Skip the tiles' vertical skirts: no area in plan.
			if absf((b.x - a.x) * (c.z - a.z) - (c.x - a.x) * (b.z - a.z)) < 1e-4:
				continue
			var low := Vector2(minf(a.x, minf(b.x, c.x)), minf(a.z, minf(b.z, c.z)))
			var high := Vector2(maxf(a.x, maxf(b.x, c.x)), maxf(a.z, maxf(b.z, c.z)))
			if not Rect2(low, high - low).intersects(area):
				continue
			for cx in range(floori(low.x / CELL_M), floori(high.x / CELL_M) + 1):
				for cz in range(floori(low.y / CELL_M), floori(high.y / CELL_M) + 1):
					# Packed arrays are values: take the cell's list out, extend it and store it back.
					var key := Vector2i(cx, cz)
					var list: PackedVector3Array = _cells.get(key, PackedVector3Array())
					list.append_array(PackedVector3Array([a, b, c]))
					_cells[key] = list
	for child in node.get_children():
		_add(child, here, area)

## The visible ground height at site-frame (x, z), or NAN where no loaded tile covers it.
func height_at(x: float, z: float) -> float:
	var triangles: PackedVector3Array = _cells.get(Vector2i(floori(x / CELL_M), floori(z / CELL_M)), PackedVector3Array())
	var best := NAN
	for index in range(0, triangles.size(), 3):
		var a := triangles[index]
		var b := triangles[index + 1]
		var c := triangles[index + 2]
		var area := (b.x - a.x) * (c.z - a.z) - (c.x - a.x) * (b.z - a.z)
		var u := ((b.x - x) * (c.z - z) - (c.x - x) * (b.z - z)) / area
		var v := ((c.x - x) * (a.z - z) - (a.x - x) * (c.z - z)) / area
		var w := 1.0 - u - v
		if u >= -1e-6 and v >= -1e-6 and w >= -1e-6:
			var y := u * a.y + v * b.y + w * c.y
			best = y if is_nan(best) else maxf(best, y)
	return best
