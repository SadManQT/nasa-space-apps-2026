## M3-60: Walkable lunar region around Aurora Station and the Cold-Trap approach on the M1-36 LOLA terrain provider
## (TerrainStream). Assembles LOC-06 (mast courtyard), LOC-07 (Expedition Zero annex exterior), LOC-08 (rover garage and
## landing apron), LOC-09 (cold-trap approach segments B1, B2, B3 and last bend) and LOC-10 (cold-trap vault shelf) on
## real LOLA terrain with streaming, collision, dated JPL Horizons lighting (one hard low Sun, black sky, true-size
## Earth near the horizon when above terrain, no fog, no ambient fill), and the 7 places worth visiting from
## game-design/25_PLAYER_CLARITY_AND_MOON_JOURNEY.md §4.1, each with its structured reason hook (job, clue, view or
## measurement).
extends Node3D
class_name MoonRegion

const CATALOG_PATH := "res://assets/environment/moon_region/moon_region.json"
const Contract = preload("res://scripts/world/room_contract.gd")
const Presentation = preload("res://scripts/world/room_presentation.gd")
const Stream = preload("res://scripts/terrain/terrain_stream.gd")
const Heightfield = preload("res://assets/environment/terrain/lola/terrain_heightfield.gd")
const EarthSky = preload("res://assets/environment/terrain/earth_sky.gd")
const Kit = preload("res://assets/environment/kit/habitat_kit.gd")
const Staging = preload("res://scripts/world/room_staging.gd")
const Geometry = preload("res://scripts/asset_geometry.gd")
const Chapter8Assets = preload("res://assets/environment/EN_MalapertSummit/chapter8_assets.gd")
const ROOM_SCENES := {
	"LOC-06": "res://scenes/campaign/rooms/exterior.tscn",
	"LOC-08": "res://scenes/campaign/rooms/garage.tscn",
}

@export var auto_configure := false
@export var initial_sector := "aurora_ridge"
@export var initial_scene := "EX-CH04-S02"
@export var initial_segment := ""

static var _catalog: Dictionary = {}

var active_sector := ""
var active_location := ""
var active_scene := ""
var active_segment := ""
var stream: Node3D
var lighting_rig: Node3D
var locations_root: Node3D
var landmarks_root: Node3D
var focus_root: Node3D
var earth_presented := false
var earth_spec: Dictionary = {}
var location_nodes: Dictionary = {}
var place_nodes: Dictionary = {}
var _fields: Dictionary = {}

static func catalog() -> Dictionary:
	if _catalog.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
		_catalog = parsed if parsed is Dictionary else {}
	return _catalog

static func places_worth_visiting() -> Array:
	return catalog().get("places_worth_visiting", []).duplicate(true)

static func place_spec(place_id: String) -> Dictionary:
	for entry in catalog().get("places_worth_visiting", []):
		if String(entry.get("id", "")) == place_id:
			return entry.duplicate(true)
	return {}

static func location_spec(loc_key: String) -> Dictionary:
	return (catalog().get("locations", {}).get(loc_key, {}) as Dictionary).duplicate(true)

func _ready() -> void:
	_ensure_roots()
	if auto_configure and active_sector.is_empty():
		configure_sector(initial_sector, initial_scene, initial_segment)

func _ensure_roots() -> void:
	if locations_root == null:
		locations_root = Node3D.new()
		locations_root.name = "Locations"
		add_child(locations_root)
	if landmarks_root == null:
		landmarks_root = Node3D.new()
		landmarks_root.name = "Landmarks"
		add_child(landmarks_root)
	if focus_root == null:
		focus_root = Node3D.new()
		focus_root.name = "RegionFocusTargets"
		add_child(focus_root)

func _field(region_id: String) -> TerrainHeightfield:
	if not _fields.has(region_id):
		_fields[region_id] = Heightfield.load_region(region_id, true)
	return _fields[region_id]

## Configures or switches the active LOLA terrain sector ("aurora_ridge" or "cold_trap"), builds its locations and §4.1
## landmarks on the real heightfield, and applies the dated JPL Horizons lighting row for scene_id / segment.
func configure_sector(sector_id: String, scene_id: String = "", segment: String = "", start_focus: Variant = null) -> Dictionary:
	_ensure_roots()
	var sectors: Dictionary = catalog().get("sectors", {})
	if not sectors.has(sector_id) or not is_inside_tree():
		return {"accepted": false, "reason": "Unknown sector or MoonRegion not inside scene tree: " + sector_id}
	var sector: Dictionary = sectors[sector_id]
	var chosen_scene := scene_id if not scene_id.is_empty() else String(sector.get("default_scene", "EX-CH04-S02"))
	var start: Vector3 = start_focus if start_focus is Vector3 else Presentation.vector(sector.get("start_m", [0.0, 0.0, 0.0]))
	if active_sector != sector_id or stream == null:
		_clear_sector()
		active_sector = sector_id
		var field := _field(sector_id)
		var exclusions := _sector_exclusions(sector_id)
		stream = Stream.new()
		stream.name = "TerrainStream"
		add_child(stream)
		if not stream.configure(sector_id, start, exclusions, field):
			return {"accepted": false, "reason": "TerrainStream failed to configure sector " + sector_id}
		await _build_sector_locations(sector_id, chosen_scene)
		_build_sector_landmarks(sector_id)
	else:
		stream.move_focus(start, true)
		_restage_sector_locations(chosen_scene)
	apply_lighting(chosen_scene, segment, start)
	return {
		"accepted": true,
		"sector": active_sector,
		"scene_id": active_scene,
		"segment": active_segment,
		"earth_presented": earth_presented,
		"location_ids": location_nodes.keys(),
		"place_ids": place_nodes.keys(),
	}

## Travels to a canonical location ("LOC-06", "LOC-07", "LOC-08", "LOC-09_B1", "LOC-09_B2", "LOC-09_B3", "LOC-09",
## "LOC-10"), switching sectors if needed, staging the location for scene_id, moving the streaming focus to the
## location's player anchor, and applying the dated Horizons lighting row.
func travel_to_location(loc_key: String, scene_id: String = "", segment_override: String = "") -> Dictionary:
	var resolved_key := loc_key
	if loc_key == "LOC-09" and not segment_override.is_empty():
		resolved_key = "LOC-09_" + segment_override
	var spec := location_spec(resolved_key)
	if spec.is_empty():
		return {"accepted": false, "reason": "Unknown location: " + resolved_key}
	var sector_id := String(spec.get("sector", "aurora_ridge"))
	var seg := segment_override if not segment_override.is_empty() else String(spec.get("segment", ""))
	var chosen_scene := scene_id if not scene_id.is_empty() else String(spec.get("default_scene", "EX-CH04-S02"))
	var origin := Presentation.vector(spec.get("origin_m", [0.0, 0.0, 0.0]))
	var turn := Basis(Vector3.UP, deg_to_rad(float(spec.get("yaw_deg", 0.0))))
	var spawn_local := Presentation.vector(spec.get("player_spawn_local_m", [0.0, 0.0, 3.0]))
	var spawn_world := origin + turn * spawn_local
	var field := _field(sector_id)
	if field != null and resolved_key != "LOC-08":
		spawn_world.y = field.height_at(spawn_world.x, spawn_world.z)
	var res := await configure_sector(sector_id, chosen_scene, seg, spawn_world)
	if not bool(res.get("accepted", false)):
		return res
	active_location = resolved_key
	var loc_node := location_node(resolved_key)
	if loc_node is CampaignRoom:
		var room := loc_node as CampaignRoom
		room.set_scene_context(chosen_scene)
		var anchors := room.terrain_anchors()
		if not anchors.is_empty():
			for key in anchors:
				if String(key).ends_with("_player"):
					spawn_world = room.global_transform * Presentation.vector(anchors[key])
					break
	stream.move_focus(spawn_world, true)
	apply_lighting(chosen_scene, seg, origin, String(spec.get("room_id", resolved_key)))
	return {
		"accepted": true,
		"location_key": resolved_key,
		"room_id": String(spec.get("room_id", resolved_key)),
		"sector": active_sector,
		"scene_id": active_scene,
		"segment": active_segment,
		"player_spawn_world": spawn_world,
		"origin_world": origin,
		"earth_presented": earth_presented,
	}

## Travels to one of the 7 places worth visiting from doc 25 §4.1, returning its spawn position, focus target and reason hook.
func visit_place(place_id: String, scene_id: String = "") -> Dictionary:
	var spec := place_spec(place_id)
	if spec.is_empty():
		return {"accepted": false, "reason": "Unknown place worth visiting: " + place_id}
	var loc_key := String(spec.get("location_id", "LOC-06"))
	var loc_info := location_spec(loc_key)
	var chosen_scene := scene_id if not scene_id.is_empty() else String(loc_info.get("earth_scene", loc_info.get("default_scene", "EX-CH04-S02")))
	var travel := await travel_to_location(loc_key, chosen_scene)
	if not bool(travel.get("accepted", false)):
		return travel
	var pos := Presentation.vector(spec.get("position_m", [0.0, 0.0, 0.0]))
	var approach := Presentation.vector(spec.get("approach_m", [pos.x, pos.y, pos.z + 2.5]))
	if stream != null and stream.field != null:
		pos.y = stream.field.height_at(pos.x, pos.z)
		approach.y = stream.field.height_at(approach.x, approach.z)
	stream.move_focus(approach, true)
	return {
		"accepted": true,
		"place_id": place_id,
		"title": String(spec.get("title", "")),
		"sector": active_sector,
		"location_id": loc_key,
		"position_world": pos,
		"approach_world": approach,
		"reason_kind": String(spec.get("reason_kind", "")),
		"reason_hook": String(spec.get("reason_hook", "")),
		"focus_target_id": String(spec.get("focus_target_id", "")),
	}

func move_focus(world_point: Vector3, force: bool = false) -> bool:
	if stream == null:
		return false
	return stream.move_focus(world_point, force)

func settled() -> bool:
	return stream != null and stream.settled()

func height_at(x: float, z: float) -> float:
	return stream.field.height_at(x, z) if stream != null and stream.field != null else 0.0

func elevation_at(x: float, z: float) -> float:
	return stream.field.elevation_at(x, z) if stream != null and stream.field != null else 0.0

func slope_deg_at(x: float, z: float) -> float:
	return stream.field.slope_deg_at(x, z) if stream != null and stream.field != null else 0.0

func location_node(loc_key: String) -> Node3D:
	return location_nodes.get(loc_key) as Node3D

func place_node(place_id: String) -> Node3D:
	return place_nodes.get(place_id) as Node3D

## All focus targets across placed rooms and regional landmarks, in world coordinates.
func all_focus_targets() -> Array:
	var out: Array = []
	for loc_key in location_nodes:
		var node: Node3D = location_nodes[loc_key]
		if node is CampaignRoom:
			var room := node as CampaignRoom
			for item in room.focus_targets():
				var copy: Dictionary = item.duplicate(true)
				var w := room.global_transform * Presentation.vector(item.position)
				copy["world_position"] = [w.x, w.y, w.z]
				copy["location_key"] = String(loc_key)
				out.append(copy)
	if focus_root != null:
		for child in focus_root.get_children():
			var c := child as Node3D
			out.append({
				"target_id": String(c.get_meta("target_id", c.name)),
				"label": String(c.get_meta("focus_label", c.name)),
				"verb": String(c.get_meta("verb", "Inspect")),
				"reason_kind": String(c.get_meta("reason_kind", "")),
				"reason_hook": String(c.get_meta("reason_hook", "")),
				"place_id": String(c.get_meta("place_id", "")),
				"position": [c.position.x, c.position.y, c.position.z],
				"world_position": [c.global_position.x, c.global_position.y, c.global_position.z],
			})
	return out

## Applies dated JPL Horizons lighting for scene_id / segment in the active sector, obeying ART_BIBLE §2 (one hard low
## Sun, black sky, no ambient or reflected sky fill, no fog, true-size Earth near the horizon when earth_above_terrain
## is true, and HorizonOccluder on dark cold-trap rows so the local floor stays in shadow while distant crater rims stay
## sunlit).
func apply_lighting(scene_id: String, segment: String = "", at_origin: Vector3 = Vector3.ZERO, earth_room_id: String = "") -> Node3D:
	if stream == null or stream.field == null:
		return null
	if lighting_rig != null and is_instance_valid(lighting_rig):
		remove_child(lighting_rig)
		lighting_rig.free()
		lighting_rig = null
	var row := Heightfield.scene_lighting(scene_id, segment)
	if row.is_empty() or String(row.get("site", "")) != String(stream.field.site.id):
		var fallback_scene := "EX-CH04-S02" if active_sector == "aurora_ridge" else "EX-CH04-S06"
		row = Heightfield.scene_lighting(fallback_scene, "")
		scene_id = fallback_scene
		segment = ""
	active_scene = scene_id
	active_segment = segment
	lighting_rig = Node3D.new()
	lighting_rig.name = "DatedLunarLighting"
	lighting_rig.set_meta("ephemeris", row.duplicate(true))
	var world := WorldEnvironment.new()
	world.name = "World"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.fog_enabled = false
	env.volumetric_fog_enabled = false
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	world.environment = env
	lighting_rig.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_energy = float(stream.config.sun_energy)
	sun.light_angular_distance = 0.0
	sun.light_size = 0.0
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = float(stream.config.shadow_distance_m)
	sun.directional_shadow_split_1 = float(stream.config.shadow_splits[0])
	sun.directional_shadow_split_2 = float(stream.config.shadow_splits[1])
	sun.directional_shadow_split_3 = float(stream.config.shadow_splits[2])
	sun.directional_shadow_blend_splits = true
	sun.shadow_normal_bias = 1.5
	sun.shadow_bias = 0.03
	sun.basis = stream.field.sun_light_basis(float(row.sun_az_deg), float(row.sun_el_deg))
	lighting_rig.add_child(sun)
	if String(row.get("sun_state", "")) == "dark":
		var toward: Vector3 = stream.field.sun_direction(float(row.sun_az_deg), 0.0)
		var distance := 400.0
		var top := distance * tan(deg_to_rad(float(row.terrain_horizon_deg)))
		var wall := MeshInstance3D.new()
		wall.name = "HorizonOccluder"
		var box := BoxMesh.new()
		box.size = Vector3(6000.0, 3000.0, 20.0)
		wall.mesh = box
		wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		wall.transform = Transform3D(Basis.looking_at(-toward, Vector3.UP), at_origin + toward * distance + Vector3.UP * (top - 1500.0))
		lighting_rig.add_child(wall)
	var query_room := earth_room_id if not earth_room_id.is_empty() else ("LOC-06" if active_sector == "aurora_ridge" else "LOC-10")
	if query_room in ["LOC-07", "LOC-08"]:
		query_room = "LOC-06"
	var query_seg := segment if query_room == "LOC-09" else ""
	earth_spec = Contract.earth(query_room, scene_id, query_seg)
	if bool(earth_spec.get("presented", false)) and not query_seg.is_empty():
		var place := Contract.terrain(query_room, query_seg)
		var yaw := float(place.get("yaw_deg", 0.0))
		if not is_zero_approx(yaw):
			var to_site := Basis(Vector3.UP, deg_to_rad(yaw))
			var e_dir := to_site * Presentation.vector(earth_spec.direction)
			var s_dir := to_site * Presentation.vector(earth_spec.sun_direction)
			earth_spec.direction = [e_dir.x, e_dir.y, e_dir.z]
			earth_spec.sun_direction = [s_dir.x, s_dir.y, s_dir.z]
	earth_presented = EarthSky.apply(env, earth_spec, float(stream.config.sun_energy))
	add_child(lighting_rig)
	return lighting_rig

func _clear_sector() -> void:
	location_nodes.clear()
	place_nodes.clear()
	if locations_root != null:
		for child in locations_root.get_children():
			locations_root.remove_child(child)
			child.free()
	if landmarks_root != null:
		for child in landmarks_root.get_children():
			landmarks_root.remove_child(child)
			child.free()
	if focus_root != null:
		for child in focus_root.get_children():
			focus_root.remove_child(child)
			child.free()
	if lighting_rig != null and is_instance_valid(lighting_rig):
		remove_child(lighting_rig)
		lighting_rig.free()
		lighting_rig = null
	if stream != null and is_instance_valid(stream):
		remove_child(stream)
		stream.free()
		stream = null

func _sector_exclusions(sector_id: String) -> Array:
	var exclusions: Array = []
	for loc_key in catalog().get("locations", {}):
		var spec: Dictionary = catalog().locations[loc_key]
		if String(spec.get("sector", "")) != sector_id:
			continue
		var room_id := String(spec.get("room_id", ""))
		var seg := String(spec.get("segment", ""))
		var place := Contract.terrain(room_id, seg)
		for area in place.get("exclusions", []):
			exclusions.append({"position": Presentation.vector(area.position), "radius_m": float(area.radius_m)})
		var origin := Presentation.vector(spec.get("origin_m", [0.0, 0.0, 0.0]))
		exclusions.append({"position": origin, "radius_m": 24.0 if room_id == "LOC-08" else 14.0})
	for place in catalog().get("places_worth_visiting", []):
		if String(place.get("sector", "")) == sector_id:
			var p := Presentation.vector(place.get("position_m", [0.0, 0.0, 0.0]))
			var a := Presentation.vector(place.get("approach_m", [p.x, p.y, p.z]))
			exclusions.append({"position": p, "radius_m": 6.0})
			exclusions.append({"position": a, "radius_m": 4.0})
	return exclusions

func _build_sector_locations(sector_id: String, scene_id: String) -> void:
	for loc_key in catalog().get("locations", {}):
		var spec: Dictionary = catalog().locations[loc_key]
		if String(spec.get("sector", "")) != sector_id:
			continue
		var room_id := String(spec.get("room_id", ""))
		var seg := String(spec.get("segment", ""))
		var loc_scene := String(spec.get("default_scene", scene_id))
		if room_id == "LOC-07":
			var annex := _build_loc07_exterior(spec)
			location_nodes[loc_key] = annex
			continue
		var room: CampaignRoom
		if ROOM_SCENES.has(room_id):
			room = (load(ROOM_SCENES[room_id]) as PackedScene).instantiate() as CampaignRoom
		else:
			room = CampaignRoom.new()
			room.room_id = room_id
		room.name = String(loc_key)
		room.terrain_segment = seg
		room.terrain_ground = room_id != "LOC-08"
		room.upcoming_scene = loc_scene
		var origin := Presentation.vector(spec.get("origin_m", [0.0, 0.0, 0.0]))
		if room_id == "LOC-08" and stream != null and stream.field != null:
			origin.y = stream.field.height_at(origin.x, origin.z) + 1.4
		var turn := Basis(Vector3.UP, deg_to_rad(float(spec.get("yaw_deg", 0.0))))
		room.transform = Transform3D(turn, origin)
		locations_root.add_child(room)
		if room_id == "LOC-08":
			if room.has_node("RoomLighting/RoomEnvironment"):
				room.get_node("RoomLighting/RoomEnvironment").free()
			if room.has_node("RoomLighting/KeyLight"):
				(room.get_node("RoomLighting/KeyLight") as DirectionalLight3D).light_energy = 0.0
			if room.garage() != null:
				room.garage().set_rover_door_open(true)
			_build_garage_apron(room, origin, turn)
		room.set_scene_context(loc_scene)
		location_nodes[loc_key] = room
	await get_tree().process_frame

func _restage_sector_locations(scene_id: String) -> void:
	for loc_key in location_nodes:
		var node: Node3D = location_nodes[loc_key]
		if node is CampaignRoom:
			var spec := location_spec(loc_key)
			(node as CampaignRoom).set_scene_context(scene_id if not scene_id.is_empty() else String(spec.get("default_scene", "EX-CH04-S02")))

## Builds the LOC-07 Expedition Zero Annex Exterior surface assembly on Aurora's south-west flank: the sealed surface
## hatch housing, external utility isolation feed, 2034 storage drum, and 2034 N.R. survey datum marker resting on the
## LOLA terrain.
func _build_loc07_exterior(spec: Dictionary) -> Node3D:
	var holder := Node3D.new()
	holder.name = "LOC-07"
	var origin := Presentation.vector(spec.get("origin_m", [-18.0, -1.533, -14.0]))
	var y_ground := height_at(origin.x, origin.z)
	origin.y = y_ground
	var turn := Basis(Vector3.UP, deg_to_rad(float(spec.get("yaw_deg", 25.0))))
	holder.transform = Transform3D(turn, origin)
	holder.set_meta("room_id", "LOC-07")
	holder.set_meta("location_key", "LOC-07")
	locations_root.add_child(holder)
	# Sealed surface bulkhead & hatch module from EN_ZeroAnnex
	var hatch := Staging.kit_prop(holder, {
		"id": "annex_exterior_hatch",
		"piece": "EN_ZeroAnnex_FloorHatch",
		"position": [0.0, 0.08, 0.0],
		"yaw": 0.0,
		"parts": {"Cover": 0.35},
		"inks": [
			{
				"id": "nameplate",
				"part": "HatchLeaf",
				"text": "N.R. 2034",
				"position": [0.0, 0.2445, 0.3],
				"pitch": -90.0,
				"yaw": 0.0,
				"size": 0.032,
				"color": "#1b1e22",
				"font": "print"
			},
			{
				"id": "cover_plan_ref",
				"part": "Cover",
				"text": "EXPEDITION ZERO ANNEX\nSEALED BULKHEAD BOUNDARY",
				"position": [0.0, 0.3826, -0.55],
				"pitch": -90.0,
				"yaw": 0.0,
				"size": 0.011,
				"color": "#1b1e22",
				"font": "print"
			}
		]
	})
	if hatch != null:
		_ground_child(holder, hatch, -0.02)
	var station := Staging.kit_prop(holder, {
		"id": "annex_exterior_station",
		"piece": "EN_ZeroAnnex_SupportStation",
		"position": [-2.2, 0.0, -1.2],
		"yaw": 15.0,
		"texts": {
			"Screen": {
				"text": "ANNEX FEED ISOLATED\n2034 DATUM LOGGED",
				"px": [560, 330],
				"bg": "#0b1220",
				"fg": "#9ff0c4",
				"flip": "h"
			}
		},
		"inks": [
			{
				"id": "station_plate",
				"text": "EXPEDITION ZERO UTILITY BOUNDARY",
				"position": [0.0, 0.6, -0.3125],
				"yaw": 180.0,
				"size": 0.02,
				"color": "#1b1e22",
				"font": "print"
			}
		]
	})
	if station != null:
		_ground_child(holder, station, 0.0)
	var marker := Kit.place(holder, "EN_ColdTrap_SurveyMarker2034", Vector3(2.1, 0.0, -0.8), 165.0)
	if marker != null:
		marker.name = "marker_2034_annex"
		_ground_child(holder, marker, 0.0)
		Staging.ink(marker, {
			"id": "annex_survey_tag",
			"text": "2034 SURVEY DATUM\nANNEX S-W BULKHEAD",
			"position": [0.0, 0.88, -0.03],
			"yaw": 180.0,
			"size": 0.014,
			"color": "#1b1e22",
			"font": "print"
		})
	var drum := Geometry.load_glb("res://assets/props/PR_AnnexDrum/PR_AnnexDrum.glb")
	if drum != null:
		drum.name = "PR_AnnexDrum"
		drum.position = Vector3(1.4, 0.0, -1.9)
		drum.rotation_degrees = Vector3(0.0, 32.0, 0.0)
		holder.add_child(drum)
		_ground_child(holder, drum, 0.0)
	return holder

func _build_garage_apron(room: CampaignRoom, origin: Vector3, turn: Basis) -> void:
	# Walkable ramp from the garage bay floor (local x = +6.0, y = -1.4, z = +1.5) onto the surrounding LOLA terrain
	var ramp := StaticBody3D.new()
	ramp.name = "ApronRampCollision"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(8.0, 0.25, 5.6)
	shape.shape = box
	ramp.add_child(shape)
	var door_local := Vector3(8.5, -1.45, 1.5)
	var outer_world := origin + turn * Vector3(12.5, 0.0, 1.5)
	var outer_y := height_at(outer_world.x, outer_world.z) - origin.y
	door_local.y = (-1.4 + outer_y) * 0.5 - 0.1
	ramp.position = door_local
	ramp.rotation.z = atan2(outer_y - (-1.4), 8.0)
	room.collision_root.add_child(ramp)

func _build_sector_landmarks(sector_id: String) -> void:
	for spec in catalog().get("places_worth_visiting", []):
		if String(spec.get("sector", "")) != sector_id:
			continue
		var place_id := String(spec.get("id", ""))
		var pos := Presentation.vector(spec.get("position_m", [0.0, 0.0, 0.0]))
		pos.y = height_at(pos.x, pos.z)
		var holder := Node3D.new()
		holder.name = "Place_" + place_id
		holder.position = pos
		holder.set_meta("place_id", place_id)
		holder.set_meta("reason_kind", String(spec.get("reason_kind", "")))
		holder.set_meta("reason_hook", String(spec.get("reason_hook", "")))
		landmarks_root.add_child(holder)
		place_nodes[place_id] = holder
		match place_id:
			"landing_pad":
				var beacon := Kit.place(holder, "EN_ColdTrap_BeaconMast", Vector3(0.0, 0.0, 0.0), -40.0)
				if beacon != null:
					beacon.name = "landing_pad_beacon"
				var marker_a := Kit.place(holder, "EN_ColdTrap_ReturnMarker", Vector3(-4.0, height_at(pos.x - 4.0, pos.z + 3.0) - pos.y, 3.0), 20.0)
				if marker_a != null:
					marker_a.name = "pad_marker_west"
				var marker_b := Kit.place(holder, "EN_ColdTrap_ReturnMarker", Vector3(4.0, height_at(pos.x + 4.0, pos.z - 3.0) - pos.y, -3.0), -20.0)
				if marker_b != null:
					marker_b.name = "pad_marker_east"
				var sign_node := Kit.place(holder, "EN_ColdTrap_SlopeSign", Vector3(2.2, height_at(pos.x + 2.2, pos.z + 1.5) - pos.y, 1.5), 140.0)
				if sign_node != null:
					sign_node.name = "pad_sign"
					Staging.ink(sign_node, {
						"id": "pad_label",
						"text": "LANDING APRON\nAZ 100 · PAD CLEAR",
						"position": [0.0, 1.25, -0.03],
						"yaw": 180.0,
						"size": 0.022,
						"color": "#1b1e22",
						"font": "print"
					})
			"boulder_field":
				for idx in 3:
					var offset := Vector3(idx * 2.4 - 2.0, 0.0, (idx % 2) * 1.8 - 0.9)
					offset.y = height_at(pos.x + offset.x, pos.z + offset.z) - pos.y
					var stake := Kit.place(holder, "EN_ColdTrap_SampleStake", offset, float(idx * 35))
					if stake != null:
						stake.name = "boulder_stake_%d" % (idx + 1)
				var slope_post := Kit.place(holder, "EN_ColdTrap_SlopeSign", Vector3(-1.8, height_at(pos.x - 1.8, pos.z + 1.2) - pos.y, 1.2), 160.0)
				if slope_post != null:
					slope_post.name = "boulder_slope_sign"
					Staging.ink(slope_post, {
						"id": "boulder_label",
						"text": "EJECTA BOULDER FIELD\nSLOPE %.1f°" % slope_deg_at(pos.x, pos.z),
						"position": [0.0, 1.25, -0.03],
						"yaw": 180.0,
						"size": 0.02,
						"color": "#1b1e22",
						"font": "print"
					})
			"crater_rim_lookout":
				var marker := Kit.place(holder, "EN_ColdTrap_ReturnMarker", Vector3(-1.6, height_at(pos.x - 1.6, pos.z) - pos.y, 0.0), 45.0)
				if marker != null:
					marker.name = "rim_lookout_marker"
				var plaque := Kit.place(holder, "EN_ColdTrap_SlopeSign", Vector3(1.2, height_at(pos.x + 1.2, pos.z - 0.6) - pos.y, -0.6), 145.0)
				if plaque != null:
					plaque.name = "rim_lookout_plaque"
					Staging.ink(plaque, {
						"id": "rim_label",
						"text": "SHACKLETON RIM LOOKOUT\nEARTH HORIZON SIGHTLINE",
						"position": [0.0, 1.25, -0.03],
						"yaw": 180.0,
						"size": 0.018,
						"color": "#1b1e22",
						"font": "print"
					})
			"relay_sites":
				var repeater := Chapter8Assets.instance("EN_RelayRoad_Repeater")
				if repeater != null:
					repeater.name = "ridge_relay_repeater"
					repeater.position = Vector3(2.8, height_at(pos.x + 2.8, pos.z - 2.0) - pos.y, -2.0)
					repeater.rotation_degrees.y = -65.0
					holder.add_child(repeater)
					Chapter8Assets.set_lamp(repeater, "Lamp_Link", Color(0.35, 1.0, 0.45), 4.0)
		_add_place_focus_target(spec, pos)

func _add_place_focus_target(spec: Dictionary, world_pos: Vector3) -> Node3D:
	var node := Node3D.new()
	var target_id := String(spec.get("focus_target_id", "place_" + String(spec.get("id", ""))))
	node.name = "Focus_" + target_id
	node.position = world_pos + Vector3(0.0, 1.1, 0.0)
	node.add_to_group("interactable")
	node.set_meta("target_id", target_id)
	node.set_meta("focus_label", String(spec.get("focus_label", spec.get("title", target_id))))
	node.set_meta("verb", String(spec.get("verb", "Inspect")))
	node.set_meta("place_id", String(spec.get("id", "")))
	node.set_meta("reason_kind", String(spec.get("reason_kind", "")))
	node.set_meta("reason_hook", String(spec.get("reason_hook", "")))
	focus_root.add_child(node)
	var label := Label3D.new()
	label.text = String(spec.get("focus_label", spec.get("title", target_id)))
	label.position = Vector3(0.0, 0.7, 0.0)
	label.font_size = 32
	label.pixel_size = 0.0012
	label.fixed_size = true
	label.hide()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	node.add_child(label)
	return node

func _ground_child(parent: Node3D, child: Node3D, y_offset: float = 0.0) -> void:
	if stream == null or stream.field == null:
		return
	var w := parent.global_transform * child.position
	var ground_y: float = float(stream.field.height_at(w.x, w.z)) + y_offset
	child.position.y += ground_y - w.y
