## M1-35: build a chunk from terrain-provider samples in this group's local space.
## M1-36 supplies the real terrain samples and owns chunk streaming/lifetime.
extends RefCounted

const CATALOG_PATH := "res://assets/environment/terrain/kit.json"
const RULES_PATH := "res://assets/environment/terrain/scatter_rules.json"
static var _scenes: Dictionary = {}
static var _catalog: Dictionary = {}
static var _rules: Dictionary = {}

static func catalog() -> Dictionary:
	if _catalog.is_empty():
		_catalog = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	return _catalog

static func rules() -> Dictionary:
	if _rules.is_empty():
		_rules = JSON.parse_string(FileAccess.get_file_as_string(RULES_PATH))
	return _rules

static func slope_density(normal: Vector3) -> float:
	if not normal.is_finite() or normal.length_squared() < 0.0001:
		return 0.0
	var degrees := rad_to_deg(acos(clampf(normal.normalized().dot(Vector3.UP), -1.0, 1.0)))
	var curve: Array = rules().slope_density
	for i in range(1, curve.size()):
		if degrees <= float(curve[i][0]):
			return lerpf(float(curve[i - 1][1]), float(curve[i][1]),
				inverse_lerp(float(curve[i - 1][0]), float(curve[i][0]), degrees))
	return 0.0

## Each sample: {position: Vector3, normal: Vector3, area_m2: float}.
## Give stable sample ordering and a stable per-chunk seed to reproduce a chunk.
## Exclusions: [{position: Vector3, radius_m: float}], in the same local space.
static func placements(samples: Array, seed_value: int, exclusions: Array = []) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var config := rules()
	var rocks: Array = catalog().rocks
	var result: Array[Dictionary] = []
	for sample in samples:
		if not sample is Dictionary or not sample.get("position") is Vector3 or not sample.get("normal") is Vector3:
			continue
		var point: Vector3 = sample.position
		var normal: Vector3 = sample.normal
		var area := float(sample.get("area_m2", 0.0))
		if not point.is_finite() or not is_finite(area) or area <= 0:
			continue
		var chance := 1.0 - exp(-float(config.density_per_m2) * area * slope_density(normal))
		if rng.randf() >= chance:
			continue
		var total := 0.0
		for weight in config.variant_weights:
			total += float(weight)
		var pick := rng.randf() * total
		var index := 0
		for i in config.variant_weights.size():
			pick -= float(config.variant_weights[i])
			if pick <= 0:
				index = i
				break
		var size := float(rocks[index].size_m)
		var radius := size * float(config.spacing_radius_factor)
		var obstructed := false
		for other in result + exclusions:
			if point.distance_to(other.position) < radius + float(other.radius_m):
				obstructed = true
				break
		if obstructed:
			continue
		var up := normal.normalized()
		var right := Vector3.FORWARD.cross(up).normalized()
		var basis := Basis(right, up, right.cross(up)).rotated(up, rng.randf() * TAU)
		result.append({"variant": index, "transform": Transform3D(basis, point),
			"position": point, "radius_m": radius, "size_m": size})
	return result

static func build_group(records: Array[Dictionary], collisions: bool = true) -> Node3D:
	var group := Node3D.new()
	group.name = "LunarRockChunk"
	var rocks: Array = catalog().rocks
	var config := rules()
	for record in records:
		var variant: Dictionary = rocks[int(record.variant)]
		var item := Node3D.new()
		item.name = variant.id
		item.transform = record.transform
		group.add_child(item)
		var first := maxf(float(config.lod0_min_distance_m), float(variant.size_m) * float(config.lod0_size_multiplier))
		var second := first * float(config.lod1_multiplier)
		for lod in 3:
			var path: String = variant.lods[lod]
			if not _scenes.has(path):
				_scenes[path] = load(path)
			var model: Node3D = (_scenes[path] as PackedScene).instantiate()
			item.add_child(model)
			for child in model.find_children("*", "MeshInstance3D", true, false):
				var mesh := child as MeshInstance3D
				mesh.visibility_range_begin = 0.0 if lod == 0 else (first if lod == 1 else second)
				mesh.visibility_range_end = first if lod == 0 else (second if lod == 1 else 0.0)
				mesh.visibility_range_begin_margin = 0.0
				mesh.visibility_range_end_margin = 0.0
				if lod == 2 and collisions and float(variant.size_m) >= float(config.collision_min_size_m):
					var body := StaticBody3D.new()
					body.name = "RockCollision"
					body.collision_layer = 1
					body.collision_mask = 0
					var shape := CollisionShape3D.new()
					shape.shape = mesh.mesh.create_convex_shape(true, false)
					# Use the mesh's transform relative to the exported model root.
					var transform := mesh.transform
					var parent := mesh.get_parent()
					while parent != item:
						transform = (parent as Node3D).transform * transform
						parent = parent.get_parent()
					body.transform = transform
					body.add_child(shape)
					item.add_child(body)
	return group
