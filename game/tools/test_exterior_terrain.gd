## M1-82: every playable exterior has an owner placement on the real LOLA terrain (rooms/exterior_terrain.json) that
## Atik's TerrainStream (M1-36) can adopt without editing the rooms: region and site-frame origin, anchors, focus
## targets, approaches, props, fixtures and doors on the ground, rock-clear exclusions, and the explicit
## omit_staging_floor flag (CampaignRoom.terrain_ground). Checks the published numbers against the region's detail
## heightfield, walkable lanes, the terrain-mode room (no staging floor, rails, flat navigation or greybox lights; same
## ids, doors and pressure markers), the unchanged flat rooms, a real player walking on the provider's collision, and
## the dated Earth (RoomContract.earth, EarthSky): true angular size, only where a bundled Horizons row says it clears
## the local terrain, never on hidden dates.
##   Godot --headless --path game --script res://tools/test_exterior_terrain.gd
##   -- --write   re-derives the published numbers from the heightfields into exterior_terrain.json
##   -- --capture (windowed) also writes production/qa/evidence/M1-82_*.png
extends SceneTree

const Contract = preload("res://scripts/world/room_contract.gd")
const Presentation = preload("res://scripts/world/room_presentation.gd")
const Heightfield = preload("res://assets/environment/terrain/lola/terrain_heightfield.gd")
const EarthSky = preload("res://assets/environment/terrain/earth_sky.gd")
const Stream = preload("res://scripts/terrain/terrain_stream.gd")
const Crew = preload("res://scripts/world/campaign_crew.gd")
const Player = preload("res://scenes/player/player.tscn")
const ROOM_SCENES := {"LOC-06": "res://scenes/campaign/rooms/exterior.tscn"}
## Walkable incline (the VIPER design limit the relay road already uses) and the rock-clear radii, metres.
const SLOPE_LIMIT_DEG := 15.0
const BURY_LIMIT_M := 0.6
const APPROACH_M := 1.5
const ANCHOR_CLEAR_M := 2.0
const APPROACH_CLEAR_M := 1.5
const FOCUS_CLEAR_M := 1.5
const DOOR_CLEAR_M := 1.5
const PROP_CLEAR_M := 1.0
const LANE_STEP_M := 2.0
const LANE_CLEAR_M := 1.2
## A walker's half-width when testing a lane against door and prop collision.
const WALKER_RADIUS_M := 0.45
## A base may sit into the slope by up to 10 % of its footprint diagonal (a graded pad), or BURY_LIMIT_M if larger.
const BURY_GRADE := 0.1
const Roster = preload("res://scripts/companions/companion_roster.gd")
## Scenes whose exterior has a computed horizon and a Horizons row that puts Earth above it (sun_positions.json).
const EARTH_SHOWN := {"LOC-06": ["EX-CH01-S01", "EX-CH01-S12", "EX-CH04-S02", "EX-CH04-S09", "EX-CH05-S01"]}
## Capture: room, dated scene, extra evidence light (a permanently shadowed floor is black under its true Sun).
const SHOTS := [["LOC-06", "EX-CH04-S09", false], ["LOC-09", "EX-CH04-S05", false], ["LOC-10", "EX-CH04-S06", true]]
var checks := 0
var failures := 0
var _fields: Dictionary = {}

func _init() -> void:
	if OS.get_cmdline_user_args().has("--capture") and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL ", message)

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	root.size = Vector2i(1600, 900)
	if args.has("--write"):
		_write()
	await _check_placements()
	await _check_rooms()
	await _check_walks()
	_check_earth()
	if args.has("--capture"):
		await _capture_all()
	print("EXTERIOR TERRAIN RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _field(region_id: String) -> TerrainHeightfield:
	if not _fields.has(region_id):
		_fields[region_id] = Heightfield.load_region(region_id, true)
	return _fields[region_id]

func _make_room(room_id: String, on_terrain: bool) -> CampaignRoom:
	var room: CampaignRoom
	if ROOM_SCENES.has(room_id):
		room = (load(ROOM_SCENES[room_id]) as PackedScene).instantiate() as CampaignRoom
	else:
		room = CampaignRoom.new()
		room.room_id = room_id
	room.terrain_ground = on_terrain
	root.add_child(room)
	return room

func _ready_rooms() -> Array:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Contract.TERRAIN_PATH))
	return data.rooms.keys().filter(func(id): return bool(data.rooms[id].get("omit_staging_floor", false)))

# ------------------------------------------------------------------------------------------- derivation

## The published numbers for one placement, from a flat build of the room and the region's detail heightfield.
func _derive(room_id: String, place: Dictionary) -> Dictionary:
	var field := _field(String(place.region_id))
	var room := _make_room(room_id, false)
	var origin := Vector3(float(place.origin_xz_m[0]), 0, float(place.origin_xz_m[1]))
	origin.y = field.height_at(origin.x, origin.z)
	var ground := func(x: float, z: float) -> float: return field.height_at(origin.x + x, origin.z + z) - origin.y
	var out := {"origin_m": _r3(origin), "anchors": {}, "focus_targets": {}, "focus_approaches": {}, "props": {}, "fixtures": {}, "doors": {}, "bury_m": {}}
	var clear: Array = []
	var targets: Array = []
	var player := Vector3.ZERO
	for marker in room.anchor_root.get_children():
		var at: Vector3 = marker.position
		at.y += ground.call(at.x, at.z)
		out.anchors[String(marker.name)] = _r3(at)
		clear.append([at, ANCHOR_CLEAR_M])
		if String(marker.name).ends_with("_player"):
			player = at
		else:
			targets.append([String(marker.name), at, not String(marker.name).ends_with("_airlock")])
	# What stops a walker: the room's doors (closed pressure boundaries) and any prop with collision.
	var blockers: Array = []
	for door in room.door_root.get_children():
		if door is CollisionObject3D:
			blockers.append([door.transform, AABB(Vector3(-0.6, 0, -0.09), Vector3(1.2, 2.1, 0.18))])
	for id in _prop_ids(room_id):
		var model := room.visual_root.get_node_or_null(String(id)) as Node3D
		if model != null and not model.find_children("*", "CollisionShape3D", true, false).is_empty():
			blockers.append([model.transform, AssetGeometry.bounds(model)])
	for focus in room.focus_root.get_children():
		var id := String(focus.get_meta("target_id"))
		var at: Vector3 = focus.position
		out.focus_targets[id] = _r3(at + Vector3(0, ground.call(at.x, at.z), 0))
		var flat := _approach(at, player, blockers)
		var approach := Vector3(flat.x, ground.call(flat.x, flat.y), flat.y)
		out.focus_approaches[id] = _r3(approach)
		clear.append([Vector3(at.x, ground.call(at.x, at.z), at.z), FOCUS_CLEAR_M])
		clear.append([approach, APPROACH_CLEAR_M])
		targets.append([id, approach, true])
	for door in room.door_root.get_children():
		var id := String(door.get_meta("boundary_id", ""))
		if id.is_empty() or not door is Node3D:
			continue
		var rest := _rest(ground, door.transform, AABB(Vector3(-0.6, 0, -0.09), Vector3(1.2, 0, 0.18)))
		out.doors[id] = _r3(door.position + Vector3(0, rest.x, 0))
		out.bury_m["Door_" + id] = snappedf(rest.y - rest.x, 0.001)
		var foot := Vector3(door.position.x, rest.x, door.position.z)
		clear.append([foot, DOOR_CLEAR_M])
		targets.append(["Door_" + id, foot, false])
	var layout := Contract.layout(room_id)
	for spec in layout.get("fixtures", []):
		var node := room.visual_root.get_node(String(spec.id)) as Node3D
		var size := Presentation.vector(spec.size)
		var rest := _rest(ground, node.transform, AABB(Vector3(-size.x, 0, -size.z) * 0.5, Vector3(size.x, 0, size.z)))
		out.fixtures[String(spec.id)] = _r3(node.position + Vector3(0, rest.x, 0))
		out.bury_m[String(spec.id)] = snappedf(rest.y - rest.x, 0.001)
		clear.append([Vector3(node.position.x, rest.x, node.position.z), Vector2(size.x, size.z).length() * 0.5 + PROP_CLEAR_M])
	for id in _prop_ids(room_id):
		var model := room.visual_root.get_node_or_null(String(id)) as Node3D
		if model == null:
			continue
		var box := AssetGeometry.bounds(model)
		var base := _base_box(model, box)
		var rest := _rest(ground, model.transform, base)
		out.props[String(id)] = _r3(model.position + Vector3(0, rest.x, 0))
		out.bury_m[String(id)] = snappedf(rest.y - rest.x, 0.001)
		var corner := model.transform * box.position
		var base_low := model.transform * base.position
		var base_high := model.transform * base.end
		out.footprint_m = out.get("footprint_m", {})
		out.footprint_m[String(id)] = snappedf(Vector2(base_high.x - base_low.x, base_high.z - base_low.z).length(), 0.001)
		clear.append([Vector3(model.position.x, rest.x, model.position.z), Vector2(corner.x - model.position.x, corner.z - model.position.z).length() + PROP_CLEAR_M])
	# Rock-clear lanes from the player's anchor to everyone and everything the scene sends them to; a lane a door or
	# prop collider would cut goes round it through one waypoint (published under "detours").
	var bounds: Array = Contract.room(room_id).bounds_m
	out.detours = {}
	var slope := 0.0
	for target in targets:
		var legs: Array = [Vector2(player.x, player.z)]
		var goal := Vector2(target[1].x, target[1].z)
		if bool(target[2]) and not _lane_clear(legs[0], goal, blockers):
			var via = _detour(legs[0], goal, blockers, bounds)
			if via != null:
				legs.append(via)
				out.detours[target[0]] = [_r3(Vector3(via.x, ground.call(via.x, via.y), via.y))]
		legs.append(goal)
		for leg in legs.size() - 1:
			var from: Vector2 = legs[leg]
			var span: Vector2 = legs[leg + 1] - from
			var count := int(span.length() / LANE_STEP_M)
			for index in range(1, count + 1):
				var p := from + span * (float(index) / float(count + 1))
				clear.append([Vector3(p.x, ground.call(p.x, p.y), p.y), LANE_CLEAR_M])
			if bool(target[2]):
				for index in int(span.length() / 0.5) + 1:
					var p := from + span.normalized() * 0.5 * index
					slope = maxf(slope, field.slope_deg_at(origin.x + p.x, origin.z + p.y))
	out.max_walk_slope_deg = snappedf(slope, 0.01)
	out.exclusions = clear.map(func(item): return {"position": _r3(item[0] + origin), "radius_m": snappedf(item[1], 0.001)})
	var low := INF
	var high := -INF
	for gx in int(float(bounds[0]) / 2.0) + 1:
		for gz in int(float(bounds[1]) / 2.0) + 1:
			var h: float = ground.call(-float(bounds[0]) * 0.5 + gx * 2.0, -float(bounds[1]) * 0.5 + gz * 2.0)
			low = minf(low, h)
			high = maxf(high, h)
	out.ground_y_range_m = [snappedf(low, 0.001), snappedf(high, 0.001)]
	room.free()
	return out

## The approach to a target: APPROACH_M from it, toward the player anchor, turned in 15 deg steps until the straight
## lane from the player anchor clears every door and prop collider by a walker's half-width.
func _approach(at: Vector3, player: Vector3, blockers: Array) -> Vector2:
	var toward := Vector2(player.x - at.x, player.z - at.z)
	var reach := minf(APPROACH_M, toward.length())
	for turn in [0, 1, -1, 2, -2, 3, -3, 4, -4, 5, -5, 6, -6, 7, -7, 8, -8, 9, -9, 10, -10, 11, -11, 12]:
		var spot := Vector2(at.x, at.z) + toward.normalized().rotated(deg_to_rad(15.0 * turn)) * reach
		if _lane_clear(Vector2(player.x, player.z), spot, blockers):
			return spot
	return Vector2(at.x, at.z) + toward.normalized() * reach

## The shortest single waypoint on a 1 m grid inside the room whose two legs both clear the blockers, or null.
func _detour(from: Vector2, to: Vector2, blockers: Array, bounds: Array) -> Variant:
	var best = null
	var best_length := INF
	var half := Vector2(float(bounds[0]), float(bounds[1])) * 0.5 - Vector2.ONE
	for gx in range(-int(half.x), int(half.x) + 1):
		for gz in range(-int(half.y), int(half.y) + 1):
			var via := Vector2(gx, gz)
			var length := from.distance_to(via) + via.distance_to(to)
			if length < best_length and _lane_clear(from, via, blockers) and _lane_clear(via, to, blockers):
				best = via
				best_length = length
	return best

## The part of a prop that meets the ground: the box of its vertices within 0.15 m of its lowest point (so panels and
## arms overhanging the base do not count as its footprint), in the prop's own frame.
func _base_box(model: Node3D, box: AABB) -> AABB:
	var base := AABB()
	var found := false
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		if (mesh as MeshInstance3D).mesh == null or (mesh as GeometryInstance3D).visibility_range_begin > 0.0:
			continue
		var into := model.global_transform.affine_inverse() * (mesh as Node3D).global_transform
		for surface in (mesh as MeshInstance3D).mesh.get_surface_count():
			for vertex in (mesh as MeshInstance3D).mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
				var p: Vector3 = into * vertex
				if p.y <= box.position.y + 0.15:
					base = base.expand(p) if found else AABB(p, Vector3.ZERO)
					found = true
	return base if found else box

func _lane_clear(from: Vector2, to: Vector2, blockers: Array) -> bool:
	var steps := int(from.distance_to(to) / 0.1) + 1
	for index in steps + 1:
		var p := from.lerp(to, float(index) / float(steps))
		for blocker in blockers:
			var local: Vector3 = (blocker[0] as Transform3D).affine_inverse() * Vector3(p.x, 0, p.y)
			var box: AABB = blocker[1]
			var scale: float = (blocker[0] as Transform3D).basis.get_scale().x
			var margin := WALKER_RADIUS_M / scale
			if local.x > box.position.x - margin and local.x < box.end.x + margin and local.z > box.position.z - margin and local.z < box.end.z + margin:
				return false
	return true

## Lowest and highest room-local ground under a footprint (box in the node's own frame): Vector2(low, high).
func _rest(ground: Callable, transform: Transform3D, box: AABB) -> Vector2:
	var low := INF
	var high := -INF
	for corner in [Vector3(box.position.x, 0, box.position.z), Vector3(box.end.x, 0, box.position.z), Vector3(box.position.x, 0, box.end.z), Vector3(box.end.x, 0, box.end.z), Vector3((box.position.x + box.end.x) * 0.5, 0, (box.position.z + box.end.z) * 0.5)]:
		var at: Vector3 = transform * corner
		var h: float = ground.call(at.x, at.z)
		low = minf(low, h)
		high = maxf(high, h)
	return Vector2(low, high)

func _prop_ids(room_id: String) -> Array:
	var layout := Contract.layout(room_id)
	if not layout.get("props", []).is_empty():
		return layout.props.map(func(p): return String(p.id))
	return Contract.room(room_id).asset_paths.map(func(p): return String(p).get_file().get_basename())

func _r3(v: Vector3) -> Array:
	return [snappedf(v.x, 0.001), snappedf(v.y, 0.001), snappedf(v.z, 0.001)]

## M3-105: a room that builds its own floor on a graded pad near a site (LOC-08: the garage 80 m from Aurora at
## azimuth 150, its rover door facing azimuth 100; garage.json "site", decision 3), placed with the same frame as the
## terrain rooms: origin_xz_m from the site's local north, yaw_deg turning room +X (the rover door's outward normal) onto
## the bearing, origin_m with the room's floor level ("floor_y_m", the bay floor) on the ground at the apron, and the
## pad's ground relative to that floor and its steepest cell under the berm's footprint.
func _derive_pad(place: Dictionary) -> Dictionary:
	var field := _field(String(place.region_id))
	var spec: Dictionary = place.site_from
	var site: Dictionary = Heightfield.sun_table().sites[String(spec.site)]
	var at := _site_in_region(site, field)
	var out_dir := Heightfield.sun_direction_at(float(site.x_m), float(site.y_m), float(spec.azimuth_deg), 0.0)
	var o := at + Vector2(out_dir.x, out_dir.z) * float(spec.distance_m)
	var door := Heightfield.sun_direction_at(float(site.x_m), float(site.y_m), float(spec.door_bearing_deg), 0.0)
	var yaw := atan2(-door.z, door.x)
	var turn := Basis(Vector3.UP, yaw)
	var apron := turn * Presentation.vector(spec.apron_local_m)
	var floor_height := field.height_at(o.x + apron.x, o.y + apron.z)
	var origin := Vector3(o.x, floor_height - float(spec.apron_local_m[1]), o.y)
	var low := INF
	var high := -INF
	var slope := 0.0
	var foot: Array = spec.pad_footprint_m
	for gx in int(float(foot[0]) / 2.0) + 1:
		for gz in int(float(foot[1]) / 2.0) + 1:
			var p := turn * Vector3(-float(foot[0]) * 0.5 + gx * 2.0, 0, -float(foot[1]) * 0.5 + gz * 2.0)
			var h := field.height_at(o.x + p.x, o.y + p.z) - floor_height
			low = minf(low, h)
			high = maxf(high, h)
			slope = maxf(slope, field.slope_deg_at(o.x + p.x, o.y + p.z))
	return {"origin_xz_m": [snappedf(o.x, 0.001), snappedf(o.y, 0.001)], "yaw_deg": snappedf(rad_to_deg(yaw), 0.01), "origin_m": _r3(origin),
			"pad_ground_m": [snappedf(low, 0.001), snappedf(high, 0.001)], "pad_max_slope_deg": snappedf(slope, 0.01)}

func _write() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Contract.TERRAIN_PATH))
	for room_id in data.rooms:
		var place: Dictionary = data.rooms[room_id]
		if bool(place.get("omit_staging_floor", false)):
			place.merge(_derive(String(room_id), place), true)
		elif place.has("site_from"):
			place.merge(_derive_pad(place), true)
	var file := FileAccess.open(Contract.TERRAIN_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, " ", false) + "\n")
	file.close()
	Contract._terrain = {}
	print("wrote ", Contract.TERRAIN_PATH)

## Every number of derived equals the stored one within 2 mm (keys, order of lists, values).
func _same(stored: Variant, derived: Variant) -> bool:
	if derived is Dictionary:
		return stored is Dictionary and derived.keys().all(func(key): return stored.has(key) and _same(stored[key], derived[key]))
	if derived is Array:
		if not stored is Array or stored.size() != derived.size():
			return false
		for index in derived.size():
			if not _same(stored[index], derived[index]):
				return false
		return true
	if derived is float or derived is int:
		return (stored is float or stored is int) and absf(float(stored) - float(derived)) <= 0.002
	return stored == derived

# ------------------------------------------------------------------------------------------- placements

func _check_placements() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Contract.TERRAIN_PATH))
	var sites: Dictionary = Heightfield.sun_table().sites
	for room_id in Contract.room_ids():
		if String(Contract.room(room_id).pressure) == "vacuum":
			_check(data.rooms.has(room_id), room_id + " (an exterior) has a terrain placement")
	for scene_id in ["EX-CH04-S04", "EX-CH04-S05", "EX-CH04-S06", "EX-CH04-S07", "EX-CH04-S08", "EX-CH08-S03", "EX-CH08-S04", "EX-CH08-S10"]:
		_check(data.rooms.has(Contract.room_for_scene(scene_id)), scene_id + " exterior room has a placement (scene map unchanged)")
	for room_id in data.rooms:
		var place: Dictionary = data.rooms[room_id]
		var field := _field(String(place.region_id))
		_check(field != null, room_id + " region " + String(place.region_id) + " loads")
		if field == null:
			continue
		var ext := field.extent()
		var half := Vector2(Contract.room(room_id).bounds_m[0], Contract.room(room_id).bounds_m[1]) * 0.5
		var o := Vector2(place.origin_xz_m[0], place.origin_xz_m[1])
		_check(o.x - half.x > ext.x_min and o.x + half.x < ext.x_max and o.y - half.y > ext.z_min and o.y + half.y < ext.z_max, room_id + " room footprint lies inside the heightfield")
		_check(sites.has(String(place.ephemeris_site)), room_id + " ephemeris site has Horizons rows")
		var site_at := _site_in_region(sites.get(String(place.ephemeris_site), {}), field)
		_check(o.distance_to(site_at) < 2000.0, "%s stands %.0f m from its ephemeris site (direction error < 0.07 deg)" % [room_id, o.distance_to(site_at)])
		var horizon := String(place.horizon_site)
		_check(horizon.is_empty() or (horizon == String(place.ephemeris_site) and o.distance_to(site_at) < 50.0), room_id + " horizon site, if any, is where the room stands")
		_check(not String(place.get("placement", "")).is_empty(), room_id + " says why it stands there")
		if not bool(place.omit_staging_floor):
			_check(not String(place.get("pending", "")).is_empty(), room_id + " keeps its flat staging and says why")
			if place.has("site_from"):
				_check(_same(place, _derive_pad(place)), room_id + " pad placement matches the heightfield (run -- --write after a change)")
				var pad: Array = place.pad_ground_m
				_check(float(pad[1]) - float(pad[0]) < float(place.site_from.pad_relief_limit_m), "%s pad relief %.2f m stays inside its berm and grading (limit %.1f m)" % [room_id, float(pad[1]) - float(pad[0]), float(place.site_from.pad_relief_limit_m)])
				var placed := Basis(Vector3.UP, deg_to_rad(float(place.yaw_deg))) * Vector3.RIGHT
				var bearing := Heightfield.sun_direction_at(float(sites[String(place.site_from.site)].x_m), float(sites[String(place.site_from.site)].y_m), float(place.site_from.door_bearing_deg), 0.0)
				_check(placed.distance_to(bearing) < 0.001, "%s rover door faces azimuth %.0f" % [room_id, float(place.site_from.door_bearing_deg)])
			continue
		var derived := _derive(String(room_id), place)
		_check(_same(place, derived), room_id + " published numbers match the heightfield (run -- --write after a room or terrain change)")
		_check(float(place.get("max_walk_slope_deg", 99)) <= SLOPE_LIMIT_DEG, "%s lanes stay walkable (max %.1f deg)" % [room_id, float(place.get("max_walk_slope_deg", 99))])
		for key in place.get("bury_m", {}):
			var limit := maxf(BURY_LIMIT_M, BURY_GRADE * float(place.get("footprint_m", {}).get(key, 0.0)))
			_check(float(place.bury_m[key]) <= limit, "%s %s rests without floating, its deepest corner %.2f m in (limit %.2f)" % [room_id, key, float(place.bury_m[key]), limit])
		var circles: Array = place.get("exclusions", []).map(func(e): return [Presentation.vector(e.position) - Presentation.vector(place.origin_m), float(e.radius_m)])
		for group in ["anchors", "focus_approaches", "props", "doors"]:
			for id in place.get(group, {}):
				var at := Presentation.vector(place[group][id])
				_check(circles.any(func(c): return Vector2(c[0].x - at.x, c[0].z - at.z).length() < c[1]), "%s %s %s is clear of rocks" % [room_id, group, id])
		for id in place.get("focus_approaches", {}):
			var at := Presentation.vector(place.focus_approaches[id])
			_check(field.slope_deg_at(o.x + at.x, o.y + at.z) <= SLOPE_LIMIT_DEG, "%s approach to %s is walkable" % [room_id, id])
			_check(at.distance_to(Presentation.vector(place.focus_targets[id])) < 3.0, "%s approach to %s is within interaction range" % [room_id, id])
	_check(not bool(data.rooms["LOC-11"].omit_staging_floor), "LOC-11 waits for a walkable relay-road patch")

func _site_in_region(site: Dictionary, field: TerrainHeightfield) -> Vector2:
	return Vector2(float(site.get("x_m", 0)) - float(field.site.x_m), -(float(site.get("y_m", 0)) - float(field.site.y_m)))

# ------------------------------------------------------------------------------------------- rooms

func _check_rooms() -> void:
	for room_id in _ready_rooms():
		var place := Contract.terrain(room_id)
		var flat := _make_room(room_id, false)
		var ground := _make_room(room_id, true)
		_check(flat.collision_root.has_node("FloorCollision") and flat.collision_root.has_node("ApronRail") and flat.has_node("RoomLighting") and flat.navigation_root.get_child_count() == 1 and not flat.on_terrain(), room_id + " flat staging is unchanged when the terrain is not used")
		for marker in flat.anchor_root.get_children():
			_check(marker.position == Presentation.vector(Contract.anchors(room_id)[marker.name]), room_id + " flat anchor unchanged: " + marker.name)
		_check(ground.on_terrain() and not ground.collision_root.has_node("FloorCollision") and not ground.collision_root.has_node("ApronRail"), room_id + " terrain mode omits the staging floor and apron rails")
		_check(not ground.has_node("RoomLighting") and ground.navigation_root.get_child_count() == 0, room_id + " terrain mode leaves lighting and navigation to the provider")
		for root_name in ["anchor_root", "focus_root", "door_root", "pressure_root"]:
			var ids := func(room: CampaignRoom) -> Array: return (room.named_roots()[root_name] as Node3D).get_children().map(func(n): return String(n.name))
			_check(ids.call(flat) == ids.call(ground), room_id + " terrain mode keeps every " + root_name + " id")
		_check(ground.focus_targets().map(func(t): return t.target_id) == flat.focus_targets().map(func(t): return t.target_id), room_id + " RoomContract focus targets unchanged")
		for pair in [["anchors", ground.anchor_root, ""], ["focus_targets", ground.focus_root, "Focus_"], ["doors", ground.door_root, "Door_"], ["fixtures", ground.visual_root, ""], ["props", ground.visual_root, ""]]:
			for id in place.get(pair[0], {}):
				var node := (pair[1] as Node3D).get_node_or_null(String(pair[2]) + String(id)) as Node3D
				_check(node != null and node.position.distance_to(Presentation.vector(place[pair[0]][id])) < 0.001, "%s %s %s stands on its terrain spot" % [room_id, pair[0], id])
		_check(ground.terrain_anchors() == place.anchors, room_id + " terrain anchors are published to the crew")
		flat.free()
		ground.free()
		await process_frame
	var pending := _make_room("LOC-11", true)
	_check(not pending.on_terrain() and pending.collision_root.has_node("FloorCollision"), "LOC-11 keeps its flat floor even when terrain is requested")
	pending.free()
	# The crew stands on the terrain anchors (EX-CH04-S04: Kai and Rafi on the surveyed ridge).
	var ridge := _make_room("LOC-09", true)
	var crew := Crew.new()
	root.add_child(crew)
	var place := Contract.terrain("LOC-09")
	crew.place("EX-CH04-S04", ridge, Presentation.vector(place.anchors.ridge_player))
	for id in ["kai", "rafi"]:
		var body: PlayerController = crew.bodies.get(id)
		var spot := Presentation.vector(place.anchors["ridge_player" if id == Roster.playable_actor("EX-CH04-S04") else "ridge_" + id])
		_check(body != null and body.visible and body.position.distance_to(spot) < 0.001, "EX-CH04-S04 %s stands at the terrain anchor %s" % [id, str(spot)])
	crew.free()
	ridge.free()
	await process_frame

# ------------------------------------------------------------------------------------------- walking

## A real player stands and walks on the provider's collision (Atik's TerrainStream, configured from the placement).
func _check_walks() -> void:
	for room_id in _ready_rooms():
		var place := Contract.terrain(room_id)
		var origin := Presentation.vector(place.origin_m)
		var room := _make_room(room_id, true)
		var stream := Stream.new()
		stream.position = -origin
		root.add_child(stream)
		var start: Vector3 = Presentation.vector(place.anchors[_player_anchor(place)])
		var clear: Array = place.exclusions.map(func(e): return {"position": Presentation.vector(e.position), "radius_m": float(e.radius_m)})
		_check(stream.configure(String(place.region_id), origin + start, clear), room_id + " TerrainStream configures from the placement")
		var player := Player.instantiate() as PlayerController
		player.character_glb = "res://assets/characters/CH_Kai/CH_Kai.glb"
		player.controlled = false
		(player.get_node("FollowCamera") as FollowCamera).capture_mouse = false
		root.add_child(player)
		player.set_physics_process(false)
		player.position = start + Vector3.UP * 0.05
		for frame in 20:
			player.velocity = Vector3.DOWN
			player.move_and_slide()
			await physics_frame
		_check(player.is_on_floor() and absf(player.position.y - start.y) < 0.15, "%s player stands on the terrain at the player anchor (%.2f vs %.2f)" % [room_id, player.position.y, start.y])
		# Everyone's anchor except the player's own and the airlock reference beyond the closed outer hatch.
		var goals: Array = place.focus_approaches.keys().map(func(k): return [k, place.focus_approaches[k]]) + place.anchors.keys().filter(func(k): return not String(k).ends_with("_player") and not String(k).ends_with("_airlock")).map(func(k): return [k, place.anchors[k]])
		for pair in goals:
			var goal := Presentation.vector(pair[1])
			player.position = start + Vector3.UP * 0.05
			for frame in 6:
				player.velocity = Vector3.DOWN
				player.move_and_slide()
				await physics_frame
			for waypoint in place.detours.get(pair[0], []) + [pair[1]]:
				var to := Presentation.vector(waypoint)
				for step in 900:
					var delta := to - player.position
					delta.y = 0
					if delta.length() < 0.1:
						break
					player.velocity = delta.normalized() * 3.0 + Vector3.DOWN
					player.move_and_slide()
					stream.move_focus(player.position + origin)
					await physics_frame
			var reached := Vector2(player.position.x - goal.x, player.position.z - goal.z).length() < 0.15
			_check(reached and absf(player.position.y - goal.y) < 0.2, "%s player walks on the terrain to %s (at %s)" % [room_id, str(goal), str(player.position)])
		player.free()
		stream.free()
		room.free()
		await process_frame

func _player_anchor(place: Dictionary) -> String:
	for key in place.anchors:
		if String(key).ends_with("_player"):
			return String(key)
	return ""

# ------------------------------------------------------------------------------------------- Earth

func _check_earth() -> void:
	var rows: Array = Heightfield.sun_table().scene_lighting
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Contract.TERRAIN_PATH))
	for room_id in data.rooms:
		for row in rows:
			var spec := Contract.earth(String(room_id), String(row.scene))
			var wanted: bool = EARTH_SHOWN.get(room_id, []).has(String(row.scene))
			_check(bool(spec.presented) == wanted, "%s %s Earth %s: %s" % [room_id, row.scene, "shown" if wanted else "hidden", spec.get("reason", "presented")])
			if not bool(spec.presented):
				_check(not spec.has("direction"), "%s %s no Earth direction on a hidden date" % [room_id, row.scene])
				continue
			var dir := Presentation.vector(spec.direction)
			_check(is_equal_approx(dir.length(), 1.0) and absf(rad_to_deg(asin(dir.y)) - float(row.earth_el_deg)) < 0.01, "%s %s Earth at the row's elevation %.2f deg" % [room_id, row.scene, float(row.earth_el_deg)])
			_check(absf(float(spec.angular_diameter_deg) - rad_to_deg(2.0 * atan(6371.0 / 384400.0))) < 0.001, "%s %s Earth is %.3f deg across" % [room_id, row.scene, float(spec.angular_diameter_deg)])
			var fraction := float(spec.illuminated_fraction)
			_check(fraction > 0.0 and fraction < 1.0 and bool(row.earth_above_terrain), "%s %s lit fraction %.2f from the Sun-Earth elongation" % [room_id, row.scene, fraction])
			var field := _field(String(data.rooms[room_id].region_id))
			_check(Presentation.vector(spec.sun_direction).distance_to(field.sun_direction(float(row.sun_az_deg), float(row.sun_el_deg))) < 0.001, "%s %s Earth is lit by the same Sun as the dated rig" % [room_id, row.scene])
	var eclipse := Contract.earth("LOC-06", "EX-CH06-S07")
	_check(not bool(eclipse.presented) and String(eclipse.reason).contains("eclipse"), "the 12 Jan 2047 eclipse is never drawn in the open sky")
	_check(not bool(Contract.earth("LOC-06", "EX-CH02-S03").presented) and not bool(Contract.earth("LOC-06", "EX-CH08-S08").presented), "no row, or another site's row: no Earth")
	_check(not bool(Contract.earth("LOC-01", "EX-CH01-S01").presented), "an interior has no exterior sky")
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color.BLACK
	_check(not EarthSky.apply(environment, Contract.earth("LOC-06", "EX-CH01-S09")) and environment.background_mode == Environment.BG_COLOR, "a hidden date leaves the black sky untouched")
	var shown := Contract.earth("LOC-06", "EX-CH04-S09")
	_check(EarthSky.apply(environment, shown, 6.0) and environment.background_mode == Environment.BG_SKY and environment.sky.sky_material.shader == EarthSky.SHADER, "a shown date puts Earth into the sky pass")
	var material := environment.sky.sky_material as ShaderMaterial
	_check(material.get_shader_parameter("earth_dir").distance_to(Presentation.vector(shown.direction)) < 1e-5 and is_equal_approx(float(material.get_shader_parameter("earth_radius")), deg_to_rad(Contract.EARTH_ANGULAR_DIAMETER_DEG * 0.5)), "the sky draws Earth at the dated direction and true radius")
	EarthSky.clear(environment)
	_check(environment.background_mode == Environment.BG_COLOR and environment.sky == null, "clear restores the black sky")

# ------------------------------------------------------------------------------------------- capture

func _capture_all() -> void:
	root.always_on_top = true
	for shot in SHOTS:
		var room_id := String(shot[0])
		var scene_id := String(shot[1])
		var place := Contract.terrain(room_id)
		var origin := Presentation.vector(place.origin_m)
		var room := _make_room(room_id, true)
		room.set_scene_context(scene_id)
		var start := Presentation.vector(place.anchors[_player_anchor(place)])
		var stream := Stream.new()
		stream.position = -origin
		root.add_child(stream)
		stream.configure(String(place.region_id), origin + start, place.exclusions.map(func(e): return {"position": Presentation.vector(e.position), "radius_m": float(e.radius_m)}))
		var rig := stream.lighting(scene_id)
		_check(rig != null, "%s %s has its dated Sun rig" % [room_id, scene_id])
		if rig == null:
			stream.free()
			room.free()
			continue
		root.add_child(rig)
		var world := rig.find_children("*", "WorldEnvironment", false, false)[0] as WorldEnvironment
		var earth := Contract.earth(room_id, scene_id)
		EarthSky.apply(world.environment, earth, float(stream.config.sun_energy))
		var work: OmniLight3D = null
		if bool(shot[2]):
			work = OmniLight3D.new()
			work.light_energy = 3.0
			work.omni_range = 40.0
			root.add_child(work)
		var camera := Camera3D.new()
		camera.far = 70000.0
		root.add_child(camera)
		for frame in 600:
			await process_frame
			if stream.pending.is_empty() and frame > 60:
				break
		# Aim at what the scene uses: its focus targets and props together.
		var spots: Array = place.focus_targets.values() + place.props.values()
		var focus := Vector3.ZERO
		for spot in spots:
			focus += Presentation.vector(spot)
		focus /= float(spots.size())
		var away := Vector3(start.x - focus.x, 0, start.z - focus.z).normalized()
		var tag := "%s_%s" % [room_id.replace("-", ""), scene_id.substr(3).replace("-", "")]
		if work != null:
			work.position = start + away * 6.0 + Vector3.UP * 4.0
		await _shot(camera, start + away * 14.0 + Vector3(4.0, 7.0, 0.0), focus, 60.0, tag + "_wide")
		await _shot(camera, start + Vector3.UP * 1.6, focus + Vector3.UP * 0.6, 70.0, tag + "_ground")
		if bool(earth.presented):
			var direction := Presentation.vector(earth.direction)
			var eye := _clear_eye(place, direction)
			await _shot(camera, eye, eye + direction * 1000.0, 70.0, tag + "_ground_toward_earth")
			# Measured from 20 m up, so no prop stands between the lens and Earth (0.3 deg above the horizontal).
			var high := start + Vector3.UP * 20.0
			await _shot(camera, high, high + direction * 1000.0, 4.0, tag + "_earth_close")
			var size := _disc_degrees(root.get_texture().get_image(), 4.0)
			print("%s Earth measured %.3f deg across in the render (published %.3f deg, %s)" % [tag, size, Contract.EARTH_ANGULAR_DIAMETER_DEG, earth.source])
			_check(absf(size - Contract.EARTH_ANGULAR_DIAMETER_DEG) < 0.2, "%s Earth renders %.2f deg across (true size %.2f)" % [tag, size, Contract.EARTH_ANGULAR_DIAMETER_DEG])
		camera.free()
		if work != null:
			work.free()
		rig.free()
		stream.free()
		room.free()
		await process_frame

## The standing eye (1.6 m over an anchor or approach) whose first 40 m toward Earth pass farthest from every prop.
func _clear_eye(place: Dictionary, direction: Vector3) -> Vector3:
	var best := Vector3.ZERO
	var best_gap := -1.0
	for spot in place.anchors.values() + place.focus_approaches.values():
		var eye := Presentation.vector(spot) + Vector3.UP * 1.6
		var gap := INF
		for prop in place.props.values():
			var to := Presentation.vector(prop) - eye
			var along := clampf(to.dot(direction), 0.0, 40.0)
			gap = minf(gap, Vector2(to.x - direction.x * along, to.z - direction.z * along).length())
		if gap > best_gap:
			best_gap = gap
			best = eye
	return best

func _shot(camera: Camera3D, from: Vector3, to: Vector3, fov: float, id: String) -> void:
	camera.fov = fov
	camera.position = from
	camera.look_at(to)
	camera.current = true
	for frame in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/M1-82_%s.png" % id)) == OK, "capture " + id)

## The rendered Earth's angular size: the largest extent of its lit pixels, in degrees of the vertical field of view.
func _disc_degrees(image: Image, fov: float) -> float:
	var x0 := image.get_width()
	var x1 := -1
	var y0 := image.get_height()
	var y1 := -1
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).get_luminance() > 0.08:
				x0 = mini(x0, x)
				x1 = maxi(x1, x)
				y0 = mini(y0, y)
				y1 = maxi(y1, y)
	if x1 < 0:
		return 0.0
	return float(maxi(x1 - x0, y1 - y0) + 1) * fov / float(image.get_height())
