extends SceneTree

## Headless checks for the LOLA terrain (board M1-34): heightmaps decode and match their sidecars,
## the story sites sit at the origin, every GLB LOD imports with decreasing triangle counts, the
## expected footprint and vertices on the (curved) heightfield, UV1 lands on the right texel of the
## object-space normal map (which must agree with the heightfield), the region builder wires LODs,
## material and collision, the Horizons tables are sane, and the NASA fixture validates.

const Heightfield = preload("res://assets/environment/terrain/lola/terrain_heightfield.gd")
const LolaRegion = preload("res://assets/environment/terrain/lola/lola_region.gd")
const Science = preload("res://scripts/science/science_data.gd")
const LOLA := "res://assets/environment/terrain/lola"
var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		print("FAIL ", message)

func _json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

func _run() -> void:
	var manifest := _json(LOLA + "/lola_terrain.json")
	_check(not manifest.is_empty(), "manifest loads")
	var credit := String(manifest.get("credit_line", ""))
	_check(credit.contains("NASA") and credit.contains("LOLA") and credit.contains("does not endorse"), "credit line names NASA LOLA and disclaims endorsement")
	_check(Heightfield.credit_line() == credit and not Heightfield.credit_line(true).is_empty(), "loader exposes both credit lines")
	var regions: Dictionary = manifest.get("regions", {})
	for id in ["aurora_ridge", "aurora_vista", "cold_trap", "relay_road", "relay_road_mid", "malapert_summit", "malapert_vista"]:
		_check(regions.has(id), "manifest lists region " + id)
	_curvature()
	for id in regions:
		_region(String(id), regions[id], manifest)
	_builder()
	_sun(manifest)
	_fixture()
	print("TERRAIN LOLA RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _curvature() -> void:
	# 10 km from the site the sphere has fallen 10,000^2 / (2 x 1,737,400) = 28.78 m below its horizontal
	_check(absf(Heightfield.curvature_drop(6000.0, 8000.0) - 28.779) < 0.01, "curvature drop is r^2 / 2R")

func _region(id: String, entry: Dictionary, manifest: Dictionary) -> void:
	var meta := _json(String(entry.get("meta", "")))
	_check(not meta.is_empty(), id + ": sidecar json")
	var raw := FileAccess.open(String(entry.get("heightmap", "")), FileAccess.READ)
	_check(raw != null and raw.get_length() == int(meta.get("columns", 0)) * int(meta.get("rows", 0)) * 2, id + ": r16 size matches columns x rows x 2")
	_check(float(meta.get("metres_per_pixel", 0.0)) == float(entry.get("metres_per_pixel", -1.0)) and float(meta.get("metres_per_pixel", 0.0)) in [5.0, 10.0, 20.0, 40.0, 80.0], id + ": metres per pixel is a LOLA grid scale")
	_check(String(meta.get("source_url", "")).begins_with("https://pgda.gsfc.nasa.gov/"), id + ": source is a NASA PGDA product")
	var hf := Heightfield.load_region(id)
	_check(hf != null, id + ": heightfield loads")
	if hf == null:
		return
	var site: Dictionary = hf.site
	_check(site.pixel_col >= 0 and site.pixel_col < hf.columns and site.pixel_row >= 0 and site.pixel_row < hf.rows, id + ": site inside the grid")
	var step: float = (hf.z_max_m - hf.z_min_m) / 65535.0
	if String(meta.get("kind", "")) != "corridor":
		# exact on the site's own product; within 5 m when the site was pinned on another LOLA grid
		var same_product: bool = String(manifest.get("sites", {}).get(String(site.get("id", "")), {}).get("product", "")) == String(meta.get("source_product", "-"))
		var tol: float = step * 2.0 + 0.05 if same_product else 5.0
		_check(absf(hf.height_at(0.0, 0.0)) <= tol, id + ": site height is the origin (%.3f m, tolerance %.2f)" % [hf.height_at(0.0, 0.0), tol])
	_check(hf.z_min_m > -12000.0 and hf.z_max_m < 12000.0 and hf.z_max_m > hf.z_min_m, id + ": height range is lunar")
	var ext: Dictionary = hf.extent()
	var size_x: float = ext.x_max - ext.x_min
	_check(absf(size_x - float(hf.columns - 1) * hf.metres_per_pixel) < 0.01, id + ": extent matches the grid")
	_check(hf.curved, id + ": Godot Y follows the Moon's curvature")
	var far := Vector2(ext.x_max * 0.9, ext.z_max * 0.9)
	_check(absf(hf.height_at(far.x, far.y) - (hf.elevation_at(far.x, far.y) - float(site.height_m) - Heightfield.curvature_drop(far.x, far.y))) < 1e-3, id + ": height_at = elevation - site height - curvature drop")
	var dir := Heightfield.sun_direction_at(float(site.x_m), float(site.y_m), 90.0, 1.5)
	_check(absf(dir.length() - 1.0) < 1e-5 and absf(dir.y - sin(deg_to_rad(1.5))) < 1e-5, id + ": sun_direction is a unit vector with the right elevation")
	var shape := hf.to_height_map_shape()
	_check(shape.map_width == hf.columns and shape.map_depth == hf.rows and shape.map_data.size() == hf.columns * hf.rows, id + ": HeightMapShape3D covers the grid")
	var probe_col := clampi(int(site.pixel_col) + hf.columns / 3, 0, hf.columns - 1)
	var probe_row := clampi(int(site.pixel_row) + hf.rows / 3, 0, hf.rows - 1)
	var px := (float(probe_col) - float(site.pixel_col)) * hf.metres_per_pixel
	var pz := (float(probe_row) - float(site.pixel_row)) * hf.metres_per_pixel
	_check(absf(shape.map_data[probe_row * hf.columns + probe_col] - hf.height_at(px, pz)) < 0.01, id + ": collision heights equal height_at (curvature included)")
	var tiles := LolaRegion.tiles_info(id)
	if tiles.is_empty():
		_check(false, id + ": tiles.json missing")
		return
	_check(bool(tiles.get("curvature", false)) == hf.curved, id + ": tiles and heightfield agree on curvature")
	var ao_check: Dictionary = tiles.get("ao_bake", {}).get("orientation_check", {})
	_check(float(ao_check.get("corr_with_crests", 0.0)) > 0.05 and float(ao_check.get("corr_with_crests", 0.0)) > float(ao_check.get("corr_if_flipped", 1.0)) + 0.05, id + ": baked AO is darker in bowls, in the right orientation " + str(ao_check))
	var lod_sets: Array = []  # [id, lods, footprint (x, z) m, centre (x, z) m]
	for tile in tiles.get("tiles", []):
		lod_sets.append([String(tile.get("id", "")), tile.get("lods", []), Vector2(float(tile.get("size_m", 0.0)), float(tile.get("size_m", 0.0))), Vector2(float(tile.get("center_x_m", 0.0)), float(tile.get("center_z_m", 0.0)))])
	if tiles.get("vista") != null:
		var v: Dictionary = tiles["vista"]
		lod_sets.append(["vista", v.get("lods", []), Vector2(float(v.get("size_x_m", 0.0)), float(v.get("size_z_m", 0.0))), Vector2(float(v.get("center_x_m", 0.0)), float(v.get("center_z_m", 0.0)))])
	_check(not lod_sets.is_empty(), id + ": has tiles or a vista mesh")
	var detail: TerrainHeightfield = Heightfield.load_region(id, true)
	var normal_img := Image.load_from_file(ProjectSettings.globalize_path(LOLA + "/" + id + "/" + String(tiles.get("normal_map", ""))))
	var sampled := 0
	var uv_checked := false
	for lod_set in lod_sets:
		var lods: Array = lod_set[1]
		var last_tris := 1 << 30
		for lod in lods:
			var label := "%s %s LOD%d" % [id, lod_set[0], int(lod.get("lod", -1))]
			var scene = load(String(lod.get("path", "")))
			_check(scene is PackedScene, label + " imports")
			if not scene is PackedScene:
				continue
			var node: Node = scene.instantiate()
			var mesh_node := _first_mesh(node)
			_check(mesh_node != null and mesh_node.mesh != null and mesh_node.mesh.get_surface_count() >= 1, label + " has a mesh")
			if mesh_node != null and mesh_node.mesh != null:
				var tris := 0
				for s in mesh_node.mesh.get_surface_count():
					tris += mesh_node.mesh.surface_get_arrays(s)[Mesh.ARRAY_INDEX].size() / 3
				_check(tris == int(lod.get("triangles", -1)), label + " triangle count recorded (%d)" % tris)
				_check(tris < last_tris, label + " has fewer triangles than the previous LOD")
				last_tris = tris
				var aabb: AABB = mesh_node.mesh.get_aabb()
				var want: Vector2 = lod_set[2]
				_check(absf(aabb.size.x - want.x) < want.x * 0.02 and absf(aabb.size.z - want.y) < want.y * 0.02, label + " footprint is %.0f x %.0f m" % [want.x, want.y])
				if sampled < 8:
					var field: TerrainHeightfield = detail if String(lod.get("field", "lola")) == "detail" and detail != null else hf
					_vertices(label, mesh_node.mesh, lod_set[3], field, float(tiles.get("skirt_m", 25.0)) * (1.0 if lod_set[0] != "vista" else 4.0))
					sampled += 1
				if not uv_checked and int(lod.get("lod", -1)) <= 1 and normal_img != null and not normal_img.is_empty():
					_uv_and_normals(id, mesh_node.mesh, lod_set[3], detail if detail != null else hf, ext, normal_img)
					uv_checked = true
			node.free()
	_check(uv_checked, id + ": UV1 and normal map checked on a near LOD")
	for key in ["normal_map", "ao_map"]:
		_check(tiles.has(key), id + ": has " + key)
		if tiles.has(key):
			var tex = load(LOLA + "/" + id + "/" + String(tiles[key]))
			_check(tex is Texture2D and tex.get_width() >= 1024, id + ": " + key + " loads")
	_check(String(tiles.get("normal_map_space", "")).begins_with("object space"), id + ": normal map is object space (no double-counted slope)")
	if String(meta.get("kind", "")) == "hero":
		_check(detail != null and detail.meta.has("detail_layer") and int(detail.meta.detail_layer.get("count", 0)) > 100, id + ": authored crater detail layer recorded with its law and seed")
		_check(detail != null and float(detail.meta.detail_layer.get("diameter_max_m", 999.0)) <= 60.0, id + ": detail craters stay below what LOLA resolves (<= 60 m)")

## Mesh vertices (in the tile's frame, offset by centre) lie on the field they were built from;
## skirt vertices sit exactly `skirt` below it. Godot stores imported vertex positions as 16-bit
## steps of the mesh's bounding box, so the tolerance grows with the mesh: 0.5 m plus one vertical
## step plus one horizontal step on a 31-degree slope (2.6 m steps on the 169 km corridor).
func _vertices(label: String, mesh: Mesh, centre: Vector2, field: TerrainHeightfield, skirt: float) -> void:
	var verts: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var box: AABB = mesh.get_aabb()
	var tol: float = 0.5 + box.size.y / 65535.0 + maxf(box.size.x, box.size.z) / 65535.0 * 0.6
	var worst := 0.0
	var compared := 0
	for k in 24:
		var v: Vector3 = verts[int(float(k) / 24.0 * float(verts.size()))]
		var d: float = field.height_at(v.x + centre.x, v.z + centre.y) - v.y
		if absf(d - skirt) < 1.0:
			continue
		worst = maxf(worst, absf(d))
		compared += 1
	_check(compared >= 12 and worst < tol, "%s vertices lie on the heightfield (%d compared, worst %.3f m, tolerance %.2f m)" % [label, compared, worst, tol])

## UV1 at a vertex is the vertex's place in the region (v = 0 at the north edge, after the glTF V
## flip), and the object-space normal map texel there matches the heightfield's own normal.
func _uv_and_normals(id: String, mesh: Mesh, centre: Vector2, field: TerrainHeightfield, ext: Dictionary, img: Image) -> void:
	var arrays: Array = mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	_check(uvs.size() == verts.size(), id + ": UV1 present")
	if uvs.size() != verts.size():
		return
	var worst_uv := 0.0
	var angle_sum := 0.0
	var angle_flipped := 0.0
	var n := 0
	var d: float = field.metres_per_pixel * 2.0
	for k in 64:
		var i := int((float(k) + 0.5) / 64.0 * float(verts.size()))
		var p := Vector2(verts[i].x + centre.x, verts[i].z + centre.y)
		var want := Vector2((p.x - ext.x_min) / (ext.x_max - ext.x_min), (p.y - ext.z_min) / (ext.z_max - ext.z_min))
		worst_uv = maxf(worst_uv, uvs[i].distance_to(want))
		var nf := Vector3(field.height_at(p.x - d, p.y) - field.height_at(p.x + d, p.y), 2.0 * d, field.height_at(p.x, p.y - d) - field.height_at(p.x, p.y + d)).normalized()
		angle_sum += rad_to_deg(nf.angle_to(_texel(img, uvs[i])))
		angle_flipped += rad_to_deg(nf.angle_to(_texel(img, Vector2(uvs[i].x, 1.0 - uvs[i].y))))
		n += 1
	_check(worst_uv < 0.002, "%s: UV1 maps each vertex to its place in the region (worst %.5f)" % [id, worst_uv])
	var mean_err := angle_sum / float(n)
	var mean_flip := angle_flipped / float(n)
	_check(mean_err < 3.0 and mean_err < mean_flip * 0.6, "%s: normal map texels match the heightfield normal (mean %.2f deg; %.2f deg if V were flipped)" % [id, mean_err, mean_flip])

func _texel(img: Image, uv: Vector2) -> Vector3:
	var c := img.get_pixel(clampi(int(uv.x * img.get_width()), 0, img.get_width() - 1), clampi(int(uv.y * img.get_height()), 0, img.get_height() - 1))
	return Vector3(c.r * 2.0 - 1.0, c.g * 2.0 - 1.0, c.b * 2.0 - 1.0).normalized()

func _builder() -> void:
	var mat := LolaRegion.make_material("aurora_ridge")
	_check(mat is ShaderMaterial and mat.shader != null and mat.get_shader_parameter("normal_os") is Texture2D and mat.get_shader_parameter("ao_map") is Texture2D, "builder material carries the region's normal and AO maps")
	_check(float(mat.get_shader_parameter("lunar_lambert")) == 1.0 and bool(mat.get_shader_parameter("use_detail")), "builder material uses lunar-Lambert regolith with the M1-35 detail")
	var region := LolaRegion.build("aurora_ridge", {"collision": true})
	_check(region != null, "builder builds aurora_ridge")
	if region == null:
		return
	var info := LolaRegion.tiles_info("aurora_ridge")
	var expected := 0
	for tile in info.get("tiles", []):
		expected += tile.get("lods", []).size()
	var meshes := region.find_children("*", "MeshInstance3D", true, false)
	_check(meshes.size() == expected, "every LOD of every tile is placed (%d of %d)" % [meshes.size(), expected])
	var ranged := 0
	for mi in meshes:
		if mi.material_override == mat or mi.material_override is ShaderMaterial:
			if mi.visibility_range_end > mi.visibility_range_begin:
				ranged += 1
	_check(ranged == meshes.size(), "each LOD has the regolith material and a visibility range")
	var shapes := region.find_children("*", "CollisionShape3D", true, false)
	_check(shapes.size() == 1 and shapes[0].shape is HeightMapShape3D, "collision is one HeightMapShape3D (never the visual mesh)")
	region.free()
	var single := LolaRegion.build("aurora_vista", {"lod": 0})
	_check(single != null and single.find_children("*", "MeshInstance3D", true, false).size() == 1, "a fixed-LOD build places one mesh per tile")
	if single != null:
		single.free()

func _first_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var found := _first_mesh(child)
		if found != null:
			return found
	return null

func _sun(manifest: Dictionary) -> void:
	var table := Heightfield.sun_table()
	_check(not table.is_empty() and table.has("windows") and table.has("scene_lighting"), "sun table loads")
	var rows_total := 0
	var bad := 0
	for key in table.get("windows", {}):
		var w: Dictionary = table.windows[key]
		_check(String(w.get("request_urls", [""])[0]).begins_with("https://ssd.jpl.nasa.gov/api/horizons.api"), "window %s cites its Horizons request" % key)
		for row in w.get("rows", []):
			rows_total += 1
			if not (float(row[1]) >= 0.0 and float(row[1]) < 360.0 and absf(float(row[2])) < 3.0 and absf(float(row[4])) < 10.0):
				bad += 1
	_check(rows_total > 500 and bad == 0, "every Horizons row has a polar-plausible azimuth/elevation (%d rows, %d bad)" % [rows_total, bad])
	var scenes: Array = table.get("scene_lighting", [])
	_check(scenes.size() >= 14, "scene lighting covers the exterior scenes (%d)" % scenes.size())
	for s in scenes:
		_check(String(s.get("sun_state", "")) in ["lit", "dark", "partial"] and s.has("terrain_horizon_deg"), "scene %s has a terrain-checked Sun state" % String(s.get("scene", "")))
	var summit := Heightfield.scene_lighting("EX-CH08-S08")
	_check(not summit.is_empty() and bool(summit.get("earth_above_terrain", false)), "Chapter 8 summit row: Earth clears the real terrain")
	for scene_id in ["EX-CH04-S05", "EX-CH04-S06"]:
		_check(String(Heightfield.scene_lighting(scene_id).get("sun_state", "")) == "dark", scene_id + ": the permanently shadowed cold trap stays dark")
	for scene_id in ["EX-CH08-S03", "EX-CH08-S04"]:
		var road := Heightfield.scene_lighting(scene_id)
		_check(String(road.get("site", "")) == "relay_road_mid" and String(road.get("sun_state", "")) == "dark" and not bool(road.get("earth_above_terrain", true)), scene_id + ": the relay road's valley is dark, Earth below its horizon (M1-87)")
	_check(Heightfield.scene_lighting("EX-NOPE").is_empty(), "unknown scene gets no invented lighting")
	for sid in ["aurora", "cold_trap", "relay_road_mid", "malapert_summit"]:
		var site: Dictionary = table.get("sites", {}).get(sid, {})
		_check(site.get("terrain_horizon_deg_by_azimuth", []).size() == 360, sid + ": 360-azimuth terrain horizon recorded")
		_check(manifest.get("sites", {}).has(sid), sid + ": manifest lists the site")
		_check(manifest.get("preview_scenes", {}).has(sid), sid + ": manifest names the dated scene used for previews and captures")

func _fixture() -> void:
	var science := Science.new()
	var card := science.card("lro_lola_south_pole_terrain")
	_check(not card.pending, "LOLA fixture is a verified Data Card source")
	_check(String(card.get("credit_line", "")).contains("NASA"), "Data Card carries the made-from-NASA-data credit line")
	_check(card.get("evidence_label") == "Computed", "terrain card is labelled Computed")
	_check(science.validate().valid, "all fixtures still validate: " + str(science.validate().errors))
	var names := {}
	for d in card.get("derived", []):
		names[String(d.get("name", ""))] = d.get("value")
	for key in ["relay_road_length", "relay_road_length_over_12_deg", "aurora_longest_sun_below_terrain_april_2046", "malapert_terrain_horizon_toward_earth", "eclipse_12_jan_2047_sun_and_earth_above_aurora_terrain"]:
		_check(names.has(key) and names[key] != null, "Data Card derives " + key)
	_check(String(card.get("boundary", "")).contains("120 km"), "Data Card keeps the game's 120 km beside the computed road")
	for puzzle in ["P-07", "P-15", "P-16"]:
		var listed := false
		for c in science.cards_for_puzzle(puzzle):
			if c.source_id == "lro_lola_south_pole_terrain":
				listed = true
		_check(listed, puzzle + " lists the terrain source")
