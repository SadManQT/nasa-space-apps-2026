extends RefCounted
class_name TerrainHeightfield

## Reads one LOLA heightmap (r16 + sidecar json written by production/tools/make_terrain.py) and
## answers height, slope and Sun-direction questions in the region's Godot frame: the story site is
## the origin, X runs along the map's columns (toward 90 deg E), Z along the rows (southward on the
## map, toward 180 deg E), Y is up and equals height minus the site's height. Every region follows
## the Moon's sphere like its tiles (Y also drops by (X^2 + Z^2) / (2 R)), so a Sun a degree below the
## site's horizontal lights the far terrain as on the real Moon. Terrain data stays read-only;
## nothing here edits the NASA grids.

const LOLA_ROOT := "res://assets/environment/terrain/lola"
const MANIFEST := LOLA_ROOT + "/lola_terrain.json"
const SUN_TABLE := LOLA_ROOT + "/sun_positions.json"
## Radius of the LOLA reference sphere (m).
const MOON_RADIUS_M := 1737400.0
## Region kinds whose tiles and collision follow the Moon's curvature (build_terrain_tiles.py CURVED_KINDS).
const CURVED_KINDS := ["hero", "vista", "corridor"]

var region_id: String = ""
var columns: int = 0
var rows: int = 0
var metres_per_pixel: float = 1.0
var z_min_m: float = 0.0
var z_max_m: float = 0.0
var site: Dictionary = {}
var meta: Dictionary = {}
## True when Godot Y includes the curvature drop (every kind in CURVED_KINDS).
var curved: bool = false
## Absolute heights in metres above the 1,737.4 km sphere, row-major, top row first.
var heights := PackedFloat32Array()


## Load a region by id from the manifest. `detail` picks the hero region's authored-crater copy
## (heightmap_<mpp>m_detail.r16) when it exists, which is what the visual tiles were built from.
static func load_region(id: String, detail: bool = false) -> TerrainHeightfield:
	var manifest := _read_json(MANIFEST)
	var entry: Dictionary = manifest.get("regions", {}).get(id, {})
	if entry.is_empty():
		push_error("TerrainHeightfield: unknown region " + id)
		return null
	var meta_path := String(entry.get("meta", ""))
	if detail:
		var candidate := meta_path.replace("m.json", "m_detail.json")
		if FileAccess.file_exists(candidate):
			meta_path = candidate
	return load_meta(meta_path)


## Load from a sidecar json path; the r16 sits next to it with the same base name.
static func load_meta(meta_path: String) -> TerrainHeightfield:
	var hf := TerrainHeightfield.new()
	hf.meta = _read_json(meta_path)
	if hf.meta.is_empty():
		push_error("TerrainHeightfield: cannot read " + meta_path)
		return null
	hf.region_id = String(hf.meta.get("region", ""))
	hf.columns = int(hf.meta.get("columns", 0))
	hf.rows = int(hf.meta.get("rows", 0))
	hf.metres_per_pixel = float(hf.meta.get("metres_per_pixel", 1.0))
	hf.z_min_m = float(hf.meta.get("z_min_m", 0.0))
	hf.z_max_m = float(hf.meta.get("z_max_m", 0.0))
	hf.site = hf.meta.get("site", {})
	hf.curved = String(hf.meta.get("kind", "")) in CURVED_KINDS
	var raw_path := meta_path.get_basename() + ".r16"
	var file := FileAccess.open(raw_path, FileAccess.READ)
	if file == null:
		push_error("TerrainHeightfield: cannot open " + raw_path)
		return null
	var bytes := file.get_buffer(file.get_length())
	file.close()
	if bytes.size() != hf.columns * hf.rows * 2:
		push_error("TerrainHeightfield: %s has %d bytes, expected %d" % [raw_path, bytes.size(), hf.columns * hf.rows * 2])
		return null
	var span := hf.z_max_m - hf.z_min_m
	hf.heights.resize(hf.columns * hf.rows)
	for i in hf.columns * hf.rows:
		hf.heights[i] = hf.z_min_m + float(bytes.decode_u16(i * 2)) * span / 65535.0
	return hf


## Absolute height (m above the sphere) of pixel (col, row); clamps to the grid.
func height_px(col: int, row: int) -> float:
	col = clampi(col, 0, columns - 1)
	row = clampi(row, 0, rows - 1)
	return heights[row * columns + col]


## Metres the sphere falls below the site's horizontal at Godot (x, z): (x^2 + z^2) / (2 R).
static func curvature_drop(x: float, z: float) -> float:
	return (x * x + z * z) / (2.0 * MOON_RADIUS_M)


## Godot Y of the terrain at (x, z) in the site frame, bilinear: what the tiles and collision show
## (height minus the site's height, minus the curvature drop).
func height_at(x: float, z: float) -> float:
	return elevation_at(x, z) - float(site.get("height_m", 0.0)) - (curvature_drop(x, z) if curved else 0.0)


## LOLA height in metres above the 1,737.4 km sphere at Godot (x, z), bilinear (science readouts).
func elevation_at(x: float, z: float) -> float:
	var fc: float = x / metres_per_pixel + float(site.get("pixel_col", 0.0))
	var fr: float = z / metres_per_pixel + float(site.get("pixel_row", 0.0))
	var c0 := clampi(int(floor(fc)), 0, columns - 2)
	var r0 := clampi(int(floor(fr)), 0, rows - 2)
	var tc := clampf(fc - float(c0), 0.0, 1.0)
	var tr := clampf(fr - float(r0), 0.0, 1.0)
	var h00 := height_px(c0, r0)
	var h10 := height_px(c0 + 1, r0)
	var h01 := height_px(c0, r0 + 1)
	var h11 := height_px(c0 + 1, r0 + 1)
	return lerpf(lerpf(h00, h10, tc), lerpf(h01, h11, tc), tr)


## True local slope in degrees at Godot (x, z) (against the local vertical, so curvature does not
## count), from central differences one pixel apart.
func slope_deg_at(x: float, z: float) -> float:
	var d := metres_per_pixel
	var dx := (elevation_at(x + d, z) - elevation_at(x - d, z)) / (2.0 * d)
	var dz := (elevation_at(x, z + d) - elevation_at(x, z - d)) / (2.0 * d)
	return rad_to_deg(atan(sqrt(dx * dx + dz * dz)))


## Godot extent of the grid in the site frame: {x_min, x_max, z_min, z_max}.
func extent() -> Dictionary:
	var sc: float = float(site.get("pixel_col", 0.0))
	var sr: float = float(site.get("pixel_row", 0.0))
	return {"x_min": -sc * metres_per_pixel, "x_max": (columns - 1 - sc) * metres_per_pixel,
			"z_min": -sr * metres_per_pixel, "z_max": (rows - 1 - sr) * metres_per_pixel}


## A HeightMapShape3D of the whole grid in Godot Y (see height_at). Put it on a CollisionShape3D with
## the transform from collision_transform(): the shape is unit-spaced and centred, so the node is
## scaled by metres_per_pixel and shifted so the site stays at the origin.
func to_height_map_shape() -> HeightMapShape3D:
	var shape := HeightMapShape3D.new()
	shape.map_width = columns
	shape.map_depth = rows
	var data := PackedFloat32Array()
	data.resize(columns * rows)
	var site_h: float = float(site.get("height_m", 0.0))
	var sc: float = float(site.get("pixel_col", 0.0))
	var sr: float = float(site.get("pixel_row", 0.0))
	for row in rows:
		var z := (float(row) - sr) * metres_per_pixel
		for col in columns:
			var i := row * columns + col
			data[i] = heights[i] - site_h
			if curved:
				data[i] -= curvature_drop((float(col) - sc) * metres_per_pixel, z)
	shape.map_data = data
	return shape


## Transform that places to_height_map_shape() in the site frame (see that function).
func collision_transform() -> Transform3D:
	var sc: float = float(site.get("pixel_col", 0.0))
	var sr: float = float(site.get("pixel_row", 0.0))
	var origin := Vector3((float(columns - 1) / 2.0 - sc) * metres_per_pixel, 0.0, (float(rows - 1) / 2.0 - sr) * metres_per_pixel)
	return Transform3D(Basis.from_scale(Vector3(metres_per_pixel, 1.0, metres_per_pixel)), origin)


## Unit vector toward a body given Horizons azimuth (deg from local north through east) and
## elevation (deg) at this region's site. Local north points away from the pole, which on the map is
## the direction from (0, 0) through the site, so it is not simply -Z.
func sun_direction(az_deg: float, el_deg: float) -> Vector3:
	return sun_direction_at(float(site.get("x_m", 0.0)), float(site.get("y_m", 1.0)), az_deg, el_deg)


## Same as sun_direction() for a site at south-polar-stereographic map coordinates (x_m, y_m).
static func sun_direction_at(site_x_m: float, site_y_m: float, az_deg: float, el_deg: float) -> Vector3:
	var r := sqrt(site_x_m * site_x_m + site_y_m * site_y_m)
	var nx := site_x_m / r
	var ny := site_y_m / r
	var north := Vector3(nx, 0.0, -ny)
	var east := Vector3(ny, 0.0, nx)
	var az := deg_to_rad(az_deg)
	var el := deg_to_rad(el_deg)
	return (north * cos(az) + east * sin(az)) * cos(el) + Vector3.UP * sin(el)


## Basis for a DirectionalLight3D so that it shines from the body at (az, el): -Z of the light looks
## away from the Sun, along the shadows.
func sun_light_basis(az_deg: float, el_deg: float) -> Basis:
	return Basis.looking_at(-sun_direction(az_deg, el_deg), Vector3.UP)


## The bundled JPL Horizons table (see sun_positions.json "about" and "columns").
static func sun_table() -> Dictionary:
	return _read_json(SUN_TABLE)


## The Sun/Earth row computed for one story scene (e.g. "EX-CH08-S08"), or {} when none exists. A scene played in
## several segments (M3-106: EX-CH04-S04 at the beacon corners B1, B2, B3) has one row per segment, each with the terrain
## horizon where that segment stands; "" asks for the scene's own row.
static func scene_lighting(scene_id: String, segment: String = "") -> Dictionary:
	for row in sun_table().get("scene_lighting", []):
		if String(row.get("scene", "")) == scene_id and String(row.get("segment", "")) == segment:
			return row
	return {}


## The credit line that must accompany any use of this terrain (Data Card, credits, video).
static func credit_line(short: bool = false) -> String:
	var manifest := _read_json(MANIFEST)
	return String(manifest.get("credit_line_short" if short else "credit_line", ""))


static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
