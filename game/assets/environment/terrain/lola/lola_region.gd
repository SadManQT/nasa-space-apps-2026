extends RefCounted

## Puts one LOLA terrain region into a scene (board M1-34): every tile's GLB LODs with their
## visibility ranges, the regolith material (terrain_lola.gdshader with the region's object-space
## normal map and AO) and, on request, a HeightMapShape3D collider that matches the meshes. The
## region's Godot frame has the story site at the origin (see terrain_heightfield.gd); a vista region
## shares its hero region's frame and leaves an 8 km hole for it. M1-36 owns streaming; this builds
## a whole region at once.
##
##   const LolaRegion = preload("res://assets/environment/terrain/lola/lola_region.gd")
##   add_child(LolaRegion.build("aurora_ridge", {"collision": true}))
##   add_child(LolaRegion.build("aurora_vista"))

const Heightfield = preload("res://assets/environment/terrain/lola/terrain_heightfield.gd")
const SHADER = preload("res://assets/environment/terrain/lola/terrain_lola.gdshader")
const LOLA := "res://assets/environment/terrain/lola"
const DETAIL_ALBEDO := "res://assets/environment/terrain/textures/T_Regolith_Compacted_BaseColor.png"
const DETAIL_NORMAL := "res://assets/environment/terrain/textures/T_Regolith_Compacted_Normal.png"


## The region's tiles.json (written by build_terrain_tiles.py), or {} if the tiles are not built.
static func tiles_info(region_id: String) -> Dictionary:
	var path := LOLA + "/" + region_id + "/tiles.json"
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


## The regolith ShaderMaterial for a region: its normal and AO maps on UV1, the M1-35 regolith detail
## on UV2. Options: "detail" (bool, default true), "lunar_lambert" (0..1, default 1).
static func make_material(region_id: String, options: Dictionary = {}) -> ShaderMaterial:
	var info := tiles_info(region_id)
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	if info.has("normal_map"):
		mat.set_shader_parameter("normal_os", load(LOLA + "/" + region_id + "/" + String(info.normal_map)))
	else:
		mat.set_shader_parameter("use_normal_os", false)
	if info.has("ao_map"):
		mat.set_shader_parameter("ao_map", load(LOLA + "/" + region_id + "/" + String(info.ao_map)))
	var detail: bool = bool(options.get("detail", true)) and ResourceLoader.exists(DETAIL_ALBEDO) and ResourceLoader.exists(DETAIL_NORMAL)
	mat.set_shader_parameter("use_detail", detail)
	if detail:
		mat.set_shader_parameter("detail_albedo", load(DETAIL_ALBEDO))
		mat.set_shader_parameter("detail_normal", load(DETAIL_NORMAL))
	mat.set_shader_parameter("lunar_lambert", float(options.get("lunar_lambert", 1.0)))
	return mat


## Build the region as a Node3D named "LolaTerrain_<region_id>". Options:
##   "lod": -1 (default) instances every LOD with its visibility range; a number instances only that
##          LOD (or the nearest coarser one a tile has) with no range, for captures and maps;
##   "collision": true adds a StaticBody3D with the HeightMapShape3D (detail field on hero regions);
##   "material": a Material to use instead of make_material(region_id, options).
## Returns null when the region has no tiles.
static func build(region_id: String, options: Dictionary = {}) -> Node3D:
	var info := tiles_info(region_id)
	if info.is_empty():
		push_error("LolaRegion: no tiles.json for " + region_id)
		return null
	var root := Node3D.new()
	root.name = "LolaTerrain_" + region_id
	var mat: Material = options.get("material", null)
	if mat == null:
		mat = make_material(region_id, options)
	var want_lod := int(options.get("lod", -1))
	var sets: Array = []
	for tile in info.get("tiles", []):
		sets.append([String(tile.get("id", "")), tile.get("lods", []), Vector3(float(tile.get("center_x_m", 0.0)), 0.0, float(tile.get("center_z_m", 0.0)))])
	if info.get("vista") != null:
		var v: Dictionary = info.vista
		sets.append(["Vista", v.get("lods", []), Vector3(float(v.get("center_x_m", 0.0)), 0.0, float(v.get("center_z_m", 0.0)))])
	for entry in sets:
		var lods: Array = entry[1]
		var chosen: Array = lods
		if want_lod >= 0:
			chosen = [_pick_lod(lods, want_lod)] if not lods.is_empty() else []
		for lod in chosen:
			var node := _instance(String(lod.get("path", "")), mat)
			if node == null:
				continue
			node.name = "%s_LOD%d" % [entry[0], int(lod.get("lod", 0))]
			node.position = entry[2]
			if want_lod < 0:
				for mi in _meshes(node):
					mi.visibility_range_begin = float(lod.get("visible_from_m", 0.0))
					mi.visibility_range_end = minf(float(lod.get("visible_to_m", 0.0)), 1.0e8)
			root.add_child(node)
	if bool(options.get("collision", false)):
		var hf: TerrainHeightfield = Heightfield.load_region(region_id, true)
		if hf != null:
			var body := StaticBody3D.new()
			body.name = "Collision"
			var shape := CollisionShape3D.new()
			shape.shape = hf.to_height_map_shape()
			shape.transform = hf.collision_transform()
			body.add_child(shape)
			root.add_child(body)
	return root


static func _pick_lod(lods: Array, want: int) -> Dictionary:
	var best: Dictionary = lods[lods.size() - 1]
	for lod in lods:
		if int(lod.get("lod", 0)) >= want:
			return lod
	return best


static func _instance(path: String, mat: Material) -> Node3D:
	var scene = load(path)
	if not scene is PackedScene:
		push_error("LolaRegion: cannot load " + path)
		return null
	var node: Node3D = scene.instantiate()
	for mi in _meshes(node):
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return node


static func _meshes(node: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		out.append(node)
	for child in node.find_children("*", "MeshInstance3D", true, false):
		out.append(child)
	return out
