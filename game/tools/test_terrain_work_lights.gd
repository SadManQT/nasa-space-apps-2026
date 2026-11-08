## M1-91: the dark Chapter 4 exteriors are lit by their work lights (rooms/terrain_work_lights.json) on the terrain
## provider's ground and on the flat fallback floor, and the ready flag (RoomContract.terrain_lighting) says so only
## where it is true. Below the cold-trap rim the dated Sun is under the terrain horizon (rows EX-CH04-S04 at B3, S05 and
## S06..S08 are "dark") and nothing adds ambient fill, so without them the work area and the puzzle targets render
## black. Checks: the hand light's published poses against the visible ground and the heightfield, off every walking lane
## and inside the rock exclusions; the ready flag for every room, placement and dated row; the work-light props are
## registry-verified assets; the staged rover runs exactly its approved EVA-stop lamps (rover_lights.json,
## VH_Rover_Lit.tscn) with its floods on their focus targets; the built rooms add no ambient, sky or second sun; direct
## light at every focus target, approach, prop and crew anchor a scene uses (the renderer's cone and distance falloff,
## occluded by the terrain and every visible mesh).
##   Godot --headless --path game --script res://tools/test_terrain_work_lights.gd
##   -- --write    re-derives on_ground into terrain_work_lights.json
##   -- --capture  (windowed; add --rendering-method gl_compatibility for the Compatibility renderer) also walks the
##   suited player to every approach in the dated scenes and writes production/qa/evidence/M1-91_<renderer>_*.png with
##   the measured target brightness, lamps on and off.
extends SceneTree

const Contract = preload("res://scripts/world/room_contract.gd")
const Presentation = preload("res://scripts/world/room_presentation.gd")
const Heightfield = preload("res://assets/environment/terrain/lola/terrain_heightfield.gd")
const WorkLights = preload("res://scripts/world/terrain_work_lights.gd")
const EarthSky = preload("res://assets/environment/terrain/earth_sky.gd")
const Stream = preload("res://scripts/terrain/terrain_stream.gd")
const VisualGround = preload("res://tools/terrain_visual_ground.gd")
const REGISTRY := "res://../production/ASSET_REGISTRY.csv"
const ROVER_SCENE := "res://assets/vehicles/VH_Rover/VH_Rover_Lit.tscn"
## The dark placements and scenes the work lights carry: [room, segment ("" = the room's own placement), scene]. They
## are exactly the scenes terrain_work_lights.json "scenes" lists as verified (checked), and every one is built, lit and
## covered here.
## M1-87: terrain-ready rooms whose dark rows have no verified work lights yet (board task named), so the campaign keeps
## them unready on the terrain; remove an entry once its lights are verified.
const UNVERIFIED_DARK := {"LOC-11": "M4-14: LOC-11's staged per-scene rover and guide lights are not yet work lights"}
const LIT := [["LOC-09", "B3", "EX-CH04-S04"], ["LOC-09", "", "EX-CH04-S05"], ["LOC-10", "", "EX-CH04-S06"], ["LOC-10", "", "EX-CH04-S07"], ["LOC-10", "", "EX-CH04-S08"]]
## The scenes the windowed capture measures on screen: [room, segment, scene, full] (full: also the wide view and the lamp
## strip, which show the same rig in the other scenes of a placement). S07 brings the tethered carrier and the probe to
## S06's shelf; S08 plays on S07's staging (LOC-10.json "ch04_vault_recovery" spans both), which the headless run checks,
## so S07's screen checks hold for it.
const CAPTURE := [["LOC-09", "B3", "EX-CH04-S04", true], ["LOC-09", "", "EX-CH04-S05", true], ["LOC-10", "", "EX-CH04-S06", true], ["LOC-10", "", "EX-CH04-S07", false]]
## A prop rests on the ground: tilt at most the walkable incline, gap under its highest contact at most this.
const TILT_LIMIT_DEG := 15.0
const FLOAT_LIMIT_M := 0.15
## A walker's half-width.
const WALKER_RADIUS_M := 0.45
## Direct light a point needs to read (light energy x cone falloff x distance falloff, the renderer's model):
## calibrated on the M1-91 captures, where the dimmest target at this level is a clear mid grey on screen.
const MIN_TARGET_LIGHT := 0.35
## Direct light the player's standing spots and the crew need: enough to see where to walk and who is there.
const MIN_GROUND_LIGHT := 0.15
## Screen brightness (mean luma of a 31 px window round a target's ground spot or a prop, 0..1) a lit target must
## reach, how much of it the lamps must add over the same view with them off, and the ceiling its mean must stay under.
const MIN_SCREEN_LUMA := 0.10
const LAMP_GAIN_LUMA := 0.03
const MAX_SCREEN_LUMA := 0.95
## Clipping: a pixel is clipped when a colour channel reaches CLIP_LEVEL (251 of 255). At most MAX_CLIPPED_SHARE of a
## target's or prop's window may clip (a glint, never a blown-out patch), and at most MAX_FRAME_CLIPPED of a measured view
## (the lit work area must keep its ground texture in both renderers).
const CLIP_LEVEL := 0.985
const MAX_CLIPPED_SHARE := 0.02
const MAX_FRAME_CLIPPED := 0.01
## Props farther than this from the player's eye (the B3 slope sign down the road, in the headlights alone; the capture
## prints its distance) have their brightness reported, not gated, on screen: the Compatibility renderer darkens a lone
## lamp and brightens overlapping ones (renderer difference), so the brightness floor cannot hold for both there. They are still
## gated against clipping, and their direct light is gated in every renderer (_check_coverage).
const NEAR_PROP_M := 15.0
## Ground views per shot at most, and how far round from the first unmeasured mark the next view gathers the others.
const MAX_GROUND_VIEWS := 6
const VIEW_CLUSTER_DEG := 30.0
var checks := 0
var failures := 0
var _fields: Dictionary = {}
var _visuals: Dictionary = {}
## Microsecond stamps of drawn frames. macOS stops drawing a covered window (another worker's capture), and then
## frame_post_draw never fires, so captures count draws instead of awaiting one.
var _draws: Array[int] = []

func _init() -> void:
	if OS.get_cmdline_user_args().has("--capture") and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
		RenderingServer.frame_post_draw.connect(_on_drawn)
	_run.call_deferred()

func _on_drawn() -> void:
	_draws.append(Time.get_ticks_usec())

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL ", message)

func _run() -> void:
	root.size = Vector2i(1600, 900)
	if OS.get_cmdline_user_args().has("--write"):
		_write()
	_check_data()
	_check_verified_scenes()
	_report_visible_ground()
	_check_ready_flags()
	_check_registry()
	await _check_rig()
	await _check_rooms()
	await _check_coverage()
	if OS.get_cmdline_user_args().has("--capture"):
		await _capture_all()
	print("TERRAIN WORK LIGHTS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _field(region_id: String) -> TerrainHeightfield:
	if not _fields.has(region_id):
		_fields[region_id] = Heightfield.load_region(region_id, true)
	return _fields[region_id]

## The turn of a placement's room frame in its region's site frame (a segment's yaw_deg; identity otherwise).
func _turn(place: Dictionary) -> Basis:
	return Basis(Vector3.UP, deg_to_rad(float(place.get("yaw_deg", 0.0))))

## A room-local point in the placement's site frame.
func _site(place: Dictionary, local: Vector3) -> Vector3:
	return Presentation.vector(place.origin_m) + _turn(place) * local

## The heightfield and the visible tile surface under a room-local (x, z), as room-local heights (NAN where no tile is
## loaded for the visible surface).
func _ground_at(place: Dictionary, x: float, z: float) -> float:
	var at := _site(place, Vector3(x, 0, z))
	return _field(String(place.region_id)).height_at(at.x, at.z) - float(place.origin_m[1])

func _seen_at(place: Dictionary, x: float, z: float) -> float:
	var at := _site(place, Vector3(x, 0, z))
	return float(_visual(place).height_at(at.x, at.z)) - float(place.origin_m[1])

## The visible tile surface round a placement (its room bounds plus 40 m, which holds the 15 m-back rover and its
## lamps' reach), keyed by region and origin.
func _visual(place: Dictionary) -> RefCounted:
	var key := "%s %s" % [place.region_id, str(place.origin_m)]
	if not _visuals.has(key):
		var origin := Presentation.vector(place.origin_m)
		_visuals[key] = VisualGround.load_region(String(place.region_id), Rect2(origin.x - 60.0, origin.z - 60.0, 120.0, 120.0))
	return _visuals[key]

func _make_room(room_id: String, segment: String, on_terrain: bool) -> CampaignRoom:
	var room := CampaignRoom.new()
	room.room_id = room_id
	room.terrain_segment = segment
	room.terrain_ground = on_terrain
	root.add_child(room)
	return room

func _lit_rooms() -> Array:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Contract.WORK_LIGHTS_PATH))
	return data.rooms.keys()

## A room's placements: "" (its own) and its segments.
func _placements(room_id: String) -> Array:
	return [""] + Contract.terrain_segments(room_id)

func _lamp_count(room_id: String) -> int:
	return WorkLights.lamp_ids(Contract.work_lights(room_id)).size()

# ------------------------------------------------------------------------------------------- derivation

## The published poses of one room's added work-light props on each placement that omits its staging floor: each rests
## on the visible ground at its xz and yaw, tilted to the plane under its base.
func _derive(room_id: String) -> Dictionary:
	var out := {}
	var spec := Contract.work_lights(room_id)
	if spec.get("props", []).is_empty():
		return out
	for segment in _placements(room_id):
		var place := Contract.terrain(room_id, segment)
		if not bool(place.get("omit_staging_floor", false)):
			continue
		var ground := func(x: float, z: float) -> float: return _ground_at(place, x, z)
		var seen := func(x: float, z: float) -> float:
			var y := _seen_at(place, x, z)
			return float(ground.call(x, z)) if is_nan(y) else y
		var poses := {}
		for prop in spec.props:
			var model := AssetGeometry.load_glb(String(prop.path))
			root.add_child(model)
			var box := AssetGeometry.bounds(model)
			var base := _base_box(model, box)
			var xz := Vector2(float(prop.xz[0]), float(prop.xz[1]))
			var pose := _ground_pose(seen, xz, deg_to_rad(float(prop.yaw_deg)), base)
			var lift := float(seen.call(xz.x, xz.y)) - float(ground.call(xz.x, xz.y))
			poses[String(prop.id)] = {"position": _r3(pose.position), "rotation_degrees": _r3(pose.rotation_degrees), "float_m": snappedf(pose.float_m, 0.001), "tilt_deg": snappedf(pose.tilt_deg, 0.01), "visible_above_field_m": snappedf(lift, 0.001)}
			model.free()
		out[segment] = poses
	return out

## A prop resting on the ground at (xz, yaw), tilted to the least-squares plane through the ground under its base
## corners and centre, lifted until its lowest contact touches: {"position", "rotation_degrees" (Node3D's Euler YXZ),
## "float_m" (the largest gap left under a base corner or its centre), "tilt_deg"}.
func _ground_pose(ground: Callable, at: Vector2, yaw: float, base: AABB) -> Dictionary:
	var turn := Basis(Vector3.UP, yaw)
	var contacts := [Vector3(base.position.x, base.position.y, base.position.z), Vector3(base.end.x, base.position.y, base.position.z),
		Vector3(base.position.x, base.position.y, base.end.z), Vector3(base.end.x, base.position.y, base.end.z), Vector3(base.get_center().x, base.position.y, base.get_center().z)]
	# Plane h = a + b u + c v in the prop's own axes about the base centre (the corners are symmetric, so b and c
	# separate).
	var middle := base.get_center()
	var uh := 0.0
	var uu := 0.0
	var vh := 0.0
	var vv := 0.0
	for contact in contacts:
		var flat: Vector3 = turn * contact
		var h := float(ground.call(at.x + flat.x, at.y + flat.z))
		uh += (contact.x - middle.x) * h
		uu += (contact.x - middle.x) * (contact.x - middle.x)
		vh += (contact.z - middle.z) * h
		vv += (contact.z - middle.z) * (contact.z - middle.z)
	var normal := (turn * Vector3(-uh / maxf(uu, 1e-6), 1.0, -vh / maxf(vv, 1e-6))).normalized()
	var basis := Basis(Quaternion(Vector3.UP, normal)) * turn
	var lift := -INF
	for contact in contacts:
		var p: Vector3 = basis * contact
		lift = maxf(lift, float(ground.call(at.x + p.x, at.y + p.z)) - p.y)
	var gap := 0.0
	for contact in contacts:
		var p: Vector3 = basis * contact
		gap = maxf(gap, lift + p.y - float(ground.call(at.x + p.x, at.y + p.z)))
	var euler := basis.get_euler()
	return {"position": Vector3(at.x, lift, at.y), "rotation_degrees": Vector3(rad_to_deg(euler.x), rad_to_deg(euler.y), rad_to_deg(euler.z)), "float_m": gap, "tilt_deg": rad_to_deg(Vector3.UP.angle_to(normal))}

## The part of a prop that meets the ground: the box of its vertices within 0.15 m of its lowest point, in its frame.
func _base_box(model: Node3D, box: AABB) -> AABB:
	var base := AABB()
	var found := false
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		if (mesh as MeshInstance3D).mesh == null:
			continue
		var into := model.global_transform.affine_inverse() * (mesh as Node3D).global_transform
		for surface in (mesh as MeshInstance3D).mesh.get_surface_count():
			for vertex in (mesh as MeshInstance3D).mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
				var p: Vector3 = into * vertex
				if p.y <= box.position.y + 0.15:
					base = base.expand(p) if found else AABB(p, Vector3.ZERO)
					found = true
	return base if found else box

func _r3(v: Vector3) -> Array:
	return [snappedf(v.x, 0.001), snappedf(v.y, 0.001), snappedf(v.z, 0.001)]

func _write() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Contract.WORK_LIGHTS_PATH))
	for room_id in data.rooms:
		if not data.rooms[room_id].get("props", []).is_empty():
			data.rooms[room_id].on_ground = _derive(String(room_id))
	var file := FileAccess.open(Contract.WORK_LIGHTS_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, " ", false) + "\n")
	file.close()
	Contract._work_lights = {}
	print("wrote ", Contract.WORK_LIGHTS_PATH)

## Every number of derived equals the stored one within 2 mm (keys, order of lists, values).
func _same(stored: Variant, derived: Variant) -> bool:
	if derived is Dictionary:
		return stored is Dictionary and stored.size() == derived.size() and derived.keys().all(func(key): return stored.has(key) and _same(stored[key], derived[key]))
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

# ------------------------------------------------------------------------------------------- data

func _check_data() -> void:
	_check(_lit_rooms() == ["LOC-09", "LOC-10"], "work lights are authored for the two dark cold-trap rooms")
	var rig: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/vehicles/VH_Rover/rover_lights.json"))
	for room_id in _lit_rooms():
		var spec := Contract.work_lights(room_id)
		var layout := Contract.layout(room_id)
		# The staged rover is the room's own (M3-106): the lit VH_Rover_Lit scene, never a second rover.
		var staged: Array = layout.get("props", []).filter(func(p): return String(p.get("id", "")) == String(spec.rover.prop))
		_check(staged.size() == 1 and String(staged[0].get("scene", "")) == ROVER_SCENE and layout.props.filter(func(p): return String(p.path).ends_with("VH_Rover.glb")).size() == 1, "%s work lights run the room's one staged rover (%s, VH_Rover_Lit)" % [room_id, spec.rover.prop])
		_check(rig.states.has(String(spec.rover.state)) and String(spec.rover.state) == "eva_stop", "%s rover runs its approved EVA-stop state (M3-8A decision 7)" % room_id)
		var targets: Array = Contract.room(room_id).focus_targets.map(func(t): return String(t.target_id))
		for lamp in spec.rover.get("aim", {}):
			_check(rig.states.eva_stop.has(String(lamp)) and targets.has(String(spec.rover.aim[lamp])), "%s %s is an EVA-stop lamp turned onto the focus target %s" % [room_id, lamp, spec.rover.aim[lamp]])
		for prop in spec.get("props", []):
			for lamp in prop.lamps:
				_check(not lamp.has("aim") or targets.has(String(lamp.aim)), "%s %s aims at a focus target of the room" % [room_id, lamp.id])
		# Verified scenes are dark rows the scene map stages in this room, on that placement.
		for segment in spec.scenes:
			for scene_id in spec.scenes[segment]:
				var row := Heightfield.scene_lighting(String(scene_id), String(segment))
				_check(Contract.room_for_scene(String(scene_id)) == room_id and String(row.get("sun_state", "")) == "dark", "%s work lights are verified for %s%s, a dark row the scene map stages there" % [room_id, scene_id, "" if String(segment).is_empty() else " at " + String(segment)])
		var derived := _derive(room_id)
		_check(_same(spec.get("on_ground", {}), derived), room_id + " work-light prop poses match the ground (run -- --write after a room, terrain or prop change)")
		for segment in spec.get("on_ground", {}):
			var place := Contract.terrain(room_id, String(segment))
			var lanes := _lanes(place)
			var circles: Array = place.exclusions.map(func(e): return [Presentation.vector(e.position), float(e.radius_m)])
			for prop in spec.props:
				var id := String(prop.id)
				var pose: Dictionary = spec.on_ground[segment][id]
				var at := Presentation.vector(pose.position)
				var site := _site(place, at)
				var model := AssetGeometry.load_glb(String(prop.path))
				root.add_child(model)
				var box := AssetGeometry.bounds(model)
				var reach := Vector2(maxf(absf(box.position.x), absf(box.end.x)), maxf(absf(box.position.z), absf(box.end.z))).length()
				model.free()
				_check(float(pose.float_m) <= FLOAT_LIMIT_M and float(pose.tilt_deg) <= TILT_LIMIT_DEG, "%s %s rests on the ground (gap %.2f m, tilt %.1f deg)" % [room_id, id, float(pose.float_m), float(pose.tilt_deg)])
				var ext := _field(String(place.region_id)).extent()
				_check(site.x > ext.x_min + 10.0 and site.x < ext.x_max - 10.0 and site.z > ext.z_min + 10.0 and site.z < ext.z_max - 10.0 and not is_nan(_seen_at(place, at.x, at.z)), "%s %s stands on loaded terrain and a visible tile" % [room_id, id])
				_check(circles.any(func(c): return Vector2(c[0].x - site.x, c[0].z - site.z).length() + reach < c[1]), "%s %s lies inside the placement's rock exclusions" % [room_id, id])
				var near: Array = lanes.filter(func(lane): return _distance_to_segment(Vector2(at.x, at.z), lane[1], lane[2]) < reach + WALKER_RADIUS_M)
				_check(near.is_empty(), "%s %s lies off every walking lane %s" % [room_id, id, str(near.map(func(lane): return lane[0]))])
				# On the flat floor it lies at its xz: off the same lanes there.
				var flat_near: Array = lanes.filter(func(lane): return _distance_to_segment(Vector2(float(prop.xz[0]), float(prop.xz[1])), lane[1], lane[2]) < reach + WALKER_RADIUS_M)
				_check(flat_near.is_empty(), "%s %s on the flat floor lies off every walking lane" % [room_id, id])

## Every scene terrain_work_lights.json verifies is one this suite builds, lights and covers (LIT), and the capture
## measures it on screen, directly or as a scene of the same placement with exactly its staging (EX-CH04-S08 plays on
## S07's: one LOC-10.json layer spans both).
func _check_verified_scenes() -> void:
	var verified: Array = []
	for room_id in _lit_rooms():
		var scenes: Dictionary = Contract.work_lights(room_id).get("scenes", {})
		for segment in scenes:
			for scene_id in scenes[segment]:
				verified.append([String(room_id), String(segment), String(scene_id)])
	var by_name := func(a: Array, b: Array) -> bool: return str(a) < str(b)
	var listed := LIT.duplicate()
	verified.sort_custom(by_name)
	listed.sort_custom(by_name)
	_check(verified == listed, "the suite builds, lights and covers exactly the verified scenes %s" % str(verified))
	for lit in LIT:
		var staged := Contract.staging(String(lit[0]), String(lit[2]), {}, [], String(lit[1]))
		var shot: Array = CAPTURE.filter(func(c): return c[0] == lit[0] and c[1] == lit[1] and (c[2] == lit[2] or Contract.staging(String(c[0]), String(c[2]), {}, [], String(c[1])) == staged))
		_check(not shot.is_empty(), "%s%s is measured on screen by the capture%s" % [lit[2], "" if String(lit[1]).is_empty() else " at " + String(lit[1]), "" if shot.is_empty() or shot[0][2] == lit[2] else " as %s, whose staging it shares (%s)" % [shot[0][2], ", ".join(staged.layers)]])

## Reported for the terrain owner (terrain integration follow-up): how far the visible tile mesh stands above the collision heightfield
## where each lit placement's anchors, approaches and props stand (they follow the heightfield; the hand light does not).
func _report_visible_ground() -> void:
	var done: Array = []
	for lit in LIT:
		var key := "%s %s" % [lit[0], lit[1]]
		if done.has(key):
			continue
		done.append(key)
		var place := Contract.terrain(String(lit[0]), String(lit[1]))
		var offsets: Array[String] = []
		for group in ["anchors", "focus_approaches", "props"]:
			for id in place.get(group, {}):
				var p := Presentation.vector(place[group][id])
				offsets.append("%s %+.2f" % [id, _seen_at(place, p.x, p.z) - _ground_at(place, p.x, p.z)])
		print("%s visible ground minus heightfield (m): %s" % [key.strip_edges(), ", ".join(offsets)])

## Walking lanes from the player anchor: to each focus approach (through its detour) and each crew anchor, as
## [name, from, to] plan segments.
func _lanes(place: Dictionary) -> Array:
	var start := Vector2.ZERO
	for key in place.anchors:
		if String(key).ends_with("_player"):
			start = Vector2(float(place.anchors[key][0]), float(place.anchors[key][2]))
	var lanes: Array = []
	var goals: Dictionary = {}
	for key in place.focus_approaches:
		goals[key] = place.detours.get(key, []) + [place.focus_approaches[key]]
	for key in place.anchors:
		if not String(key).ends_with("_player"):
			goals[key] = place.detours.get(key, []) + [place.anchors[key]]
	for key in goals:
		var from := start
		for point in goals[key]:
			var to := Vector2(float(point[0]), float(point[2]))
			lanes.append([String(key), from, to])
			from = to
	return lanes

func _distance_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var span := b - a
	var t := 0.0 if span.length_squared() < 1e-9 else clampf((p - a).dot(span) / span.length_squared(), 0.0, 1.0)
	return p.distance_to(a + span * t)

# ------------------------------------------------------------------------------------------- ready flag

## The segment ids whose placement plays a scene ("scene" on a segment placement); a scene played on segments is not
## played on the room's own placement, so that row's flag does not matter.
func _segment_scenes(room_id: String) -> Array:
	var scenes: Array = []
	for segment in Contract.terrain_segments(room_id):
		scenes.append(String(Contract.terrain(room_id, segment).get("scene", "")))
	return scenes

func _check_ready_flags() -> void:
	var rows: Array = Heightfield.sun_table().scene_lighting
	for room_id in Contract.room_ids():
		var verified: Dictionary = Contract.work_lights(room_id).get("scenes", {})
		for row in rows:
			var segment := String(row.get("segment", ""))
			var place := Contract.terrain(room_id, segment)
			var flag := Contract.terrain_lighting(room_id, String(row.scene), segment)
			var wanted: bool = not place.is_empty() and bool(place.get("omit_staging_floor", false)) and String(row.site) == String(place.get("ephemeris_site", "")) and (String(row.sun_state) != "dark" or verified.get(segment, []).has(String(row.scene)))
			_check(bool(flag.ready) == wanted, "%s %s%s ready flag is %s (%s)" % [room_id, row.scene, "" if segment.is_empty() else " " + segment, wanted, flag.reason])
			_check(not String(flag.reason).is_empty() and String(flag.sun_state) == String(row.sun_state) and String(flag.segment) == segment, "%s %s ready flag says why and carries the row's Sun state" % [room_id, row.scene])
	# Every dated scene the scene map plays in a terrain-ready placement is lit, by the Sun or by verified work lights.
	for row in rows:
		var room_id := Contract.room_for_scene(String(row.scene))
		var segment := String(row.get("segment", ""))
		if segment.is_empty() and _segment_scenes(room_id).has(String(row.scene)):
			continue  # played on the room's segments (M3-106: EX-CH04-S04 at B1, B2, B3), not at its own placement
		var place := Contract.terrain(room_id, segment)
		if bool(place.get("omit_staging_floor", false)) and String(row.site) == String(place.ephemeris_site):
			var ready := bool(Contract.terrain_lighting(room_id, String(row.scene), segment).ready)
			if UNVERIFIED_DARK.has(room_id) and String(row.sun_state) == "dark":
				_check(not ready, "%s in %s stays unready on the terrain until its work lights are verified (%s)" % [row.scene, room_id, UNVERIFIED_DARK[room_id]])
				continue
			_check(ready, "%s%s in %s on the terrain is lit (%s Sun)" % [row.scene, "" if segment.is_empty() else " " + segment, room_id, row.sun_state])
	for lit in LIT:
		var flag := Contract.terrain_lighting(String(lit[0]), String(lit[2]), String(lit[1]))
		_check(flag.ready and flag.sun_state == "dark" and String(flag.reason).contains("work lights") and flag.work_lights.size() == _lamp_count(String(lit[0])), "%s%s (%s, dark Sun) is ready on the terrain through its %d work lights" % [lit[2], "" if String(lit[1]).is_empty() else " " + String(lit[1]), lit[0], _lamp_count(String(lit[0]))])
	_check(_lamp_count("LOC-09") == 5 and _lamp_count("LOC-10") == 6, "the rover's five EVA-stop lamps light both rooms, Kai's hand light the shelf too")
	for segment in ["B1", "B2"]:
		var sunlit := Contract.terrain_lighting("LOC-09", "EX-CH04-S04", segment)
		_check(sunlit.ready and sunlit.sun_state == "lit" and String(sunlit.reason).contains("Sun"), "LOC-09 %s is ready by its dated Sun (sunlit at 08:00 UTC)" % segment)
	_check(not bool(Contract.terrain_lighting("LOC-10", "EX-CH04-S05").ready), "a dark scene the room's lights were not verified for is not ready (LOC-10 with the last bend's S05 row)")
	_check(not bool(Contract.terrain_lighting("LOC-10", "EX-CH04-S04", "B3").ready), "a segment the room does not have is not ready")
	_check(not bool(Contract.terrain_lighting("LOC-11", "EX-CH08-S03").ready), "LOC-11 is not ready: its placement stands on the terrain (M1-87) but its dark rows have no verified work lights (M4-14)")
	_check(not bool(Contract.terrain_lighting("LOC-08", "EX-CH04-S02").ready), "LOC-08 is not ready: the garage keeps its own floors")
	_check(not bool(Contract.terrain_lighting("LOC-01", "EX-CH01-S01").ready), "an interior has no terrain lighting")
	var aurora := Contract.terrain_lighting("LOC-06", "EX-CH04-S09")
	_check(aurora.ready and aurora.sun_state == "lit" and aurora.work_lights.is_empty(), "LOC-06 in a sunlit row is ready by the dated Sun alone, with no work lights")
	_check(not bool(Contract.terrain_lighting("LOC-09", "EX-CH02-S03").ready), "a scene without a dated row is not ready")
	_check(Contract.work_light_asset_paths("LOC-10") == ["res://assets/props/PR_HandLight/PR_HandLight.glb"] and Contract.work_light_asset_paths("LOC-09").is_empty() and Contract.work_light_asset_paths("LOC-06").is_empty(), "the shelf publishes its hand light's GLB for loading; the rover is already the room's own prop")

## Every work-light prop and the staged rover are approved assets: a verified ASSET_REGISTRY row at the same game path.
func _check_registry() -> void:
	var rows := {}
	for line: String in FileAccess.get_file_as_string(ProjectSettings.globalize_path(REGISTRY)).split("\n"):
		var cells: PackedStringArray = line.split(",")
		if cells.size() > 3:
			rows[cells[0]] = cells
	var assets := [["VH_Rover", "res://assets/vehicles/VH_Rover/VH_Rover.glb"]]
	for room_id in _lit_rooms():
		for prop in Contract.work_lights(room_id).get("props", []):
			assets.append([String(prop.asset_id), String(prop.path)])
	for asset in assets:
		var row: PackedStringArray = rows.get(String(asset[0]), PackedStringArray())
		_check(row.size() > 3 and row[2] == "verified" and "res://" + row[3].trim_prefix("game/") == String(asset[1]) and FileAccess.file_exists(String(asset[1])), "%s is a verified registry asset at %s" % [asset[0], asset[1]])

# ------------------------------------------------------------------------------------------- rover rig

## The staged rover's lamps are the approved EVA-stop rig (VH_Rover_Lit.tscn's lights: energy, range, cone, edge,
## colour, shadows; the beam axis unless a flood is turned onto its focus target), on the terrain and on the flat floor,
## and every beam leaves the rover unobstructed.
func _check_rig() -> void:
	var approved := (load(ROVER_SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(approved)
	var rig: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/vehicles/VH_Rover/rover_lights.json"))
	var file: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Contract.WORK_LIGHTS_PATH))
	var table: Dictionary = file.compatibility_energy_scale
	var lit := Contract.work_lights("LOC-10")
	var every: Array = rig.states.eva_stop.duplicate()
	for prop in lit.props:
		every.append_array(prop.lamps.map(func(lamp): return String(lamp.id)))
	var each := func(lamp: String) -> bool: return table.has(lamp) and float(table[lamp]) > 0.0 and float(table[lamp]) <= 1.0 and is_equal_approx(WorkLights.energy_scale(lit, "gl_compatibility", lamp), float(table[lamp])) and WorkLights.energy_scale(lit, "forward_plus", lamp) == 1.0 and WorkLights.energy_scale(lit, "mobile", lamp) == 1.0
	_check(table.size() == every.size() and every.all(each), "every work light %s keeps its approved energy in Forward+ and Mobile and has its own Compatibility fraction %s" % [str(every), str(table)])
	var method := RenderingServer.get_current_rendering_method()
	for room_id in _lit_rooms():
		var spec := Contract.work_lights(room_id)
		var aims: Dictionary = spec.rover.get("aim", {})
		for case in [["B3" if room_id == "LOC-09" else "", true], ["", false]]:
			var room := _make_room(room_id, String(case[0]), bool(case[1]))
			var tag := "%s%s %s" % [room_id, "" if String(case[0]).is_empty() else " " + String(case[0]), "terrain" if bool(case[1]) else "flat"]
			var rover := room.visual_root.get_node_or_null(String(spec.rover.prop)) as Node3D
			_check(rover != null and String(rover.get_meta(WorkLights.META, "")) == "eva_stop", tag + " the staged rover runs its EVA-stop state")
			if rover == null:
				room.free()
				continue
			var shell := _trimesh(rover)
			await physics_frame
			await physics_frame
			var space := room.get_world_3d().direct_space_state
			var on: Array = rover.find_children("*", "Light3D", false, false).filter(func(l): return (l as Light3D).visible)
			_check(on.map(func(l): return String(l.name)) == rig.states.eva_stop, "%s rover lights exactly its approved EVA-stop lamps %s" % [tag, str(rig.states.eva_stop)])
			for name in rig.states.eva_stop:
				var light := rover.get_node_or_null(String(name)) as Light3D
				var model := approved.get_node(String(name)) as Light3D
				if light == null:
					_check(false, "%s rover has its %s" % [tag, name])
					continue
				var scale := WorkLights.energy_scale(spec, method, String(name))
				_check(light.get_class() == model.get_class() and is_equal_approx(light.light_energy, model.light_energy * scale) and light.light_color.is_equal_approx(model.light_color) and light.shadow_enabled and light.position.distance_to(model.position) < 0.001, "%s %s keeps the approved %s at its socket, energy %.1f (x %.2f in this renderer), colour, hard-shadowed" % [tag, name, model.get_class(), model.light_energy, scale])
				if not light is SpotLight3D:
					_check(is_equal_approx((light as OmniLight3D).omni_range, (model as OmniLight3D).omni_range), "%s %s is the approved cabin glow" % [tag, name])
					continue
				var spot := light as SpotLight3D
				var reference := model as SpotLight3D
				_check(is_equal_approx(spot.spot_range, reference.spot_range) and is_equal_approx(spot.spot_angle, reference.spot_angle) and is_equal_approx(spot.spot_angle_attenuation, reference.spot_angle_attenuation) and is_equal_approx(spot.spot_attenuation, reference.spot_attenuation), "%s %s keeps the approved cone %.1f deg, range %.0f m and falloff" % [tag, name, reference.spot_angle, reference.spot_range])
				var beam := -spot.global_basis.z
				var wanted := rover.global_basis * -reference.basis.z
				if aims.has(String(name)):
					var target := room.focus_root.get_node("Focus_" + String(aims[name])) as Node3D
					wanted = target.global_position - spot.global_position
				_check(rad_to_deg(beam.angle_to(wanted)) < 0.5, "%s %s points %s" % [tag, name, "at its focus target " + String(aims[name]) if aims.has(String(name)) else "along the approved beam axis"])
				# Unobstructed: nothing of the rover within 1 m along the beam.
				var out := space.intersect_ray(PhysicsRayQueryParameters3D.create(spot.global_position, spot.global_position + beam.normalized() * 1.0, 1 << 19))
				_check(out.is_empty(), "%s %s beam leaves the rover unobstructed" % [tag, name])
			shell.free()
			room.free()
			await process_frame
	approved.free()

## A ray-test copy of the model's own shadow-casting meshes under node, on layer 20; free it after use.
func _trimesh(node: Node3D) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1 << 19
	body.collision_mask = 0
	for mesh in node.find_children("*", "MeshInstance3D", true, false):
		var instance := mesh as MeshInstance3D
		if instance.mesh == null or instance.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			continue
		var faces := instance.mesh.get_faces()
		for index in faces.size():
			faces[index] = instance.global_transform * faces[index]
		var concave := ConcavePolygonShape3D.new()
		concave.set_faces(faces)
		concave.backface_collision = true
		var shape := CollisionShape3D.new()
		shape.shape = concave
		body.add_child(shape)
	root.add_child(body)
	return body

# ------------------------------------------------------------------------------------------- built rooms

func _check_rooms() -> void:
	for lit in LIT:
		var room_id := String(lit[0])
		var segment := String(lit[1])
		var scene_id := String(lit[2])
		var tag := "%s%s %s" % [room_id, "" if segment.is_empty() else " " + segment, scene_id]
		var spec := Contract.work_lights(room_id)
		var room := _make_room(room_id, segment, true)
		var flat := _make_room(room_id, segment, false)
		room.set_scene_context(scene_id)
		flat.set_scene_context(scene_id)
		var lamps := room.work_lights()
		_check(lamps.size() == _lamp_count(room_id) and flat.work_lights().size() == _lamp_count(room_id), "%s switches on its %d work lights on the terrain (%d) and on the flat floor (%d)" % [tag, _lamp_count(room_id), lamps.size(), flat.work_lights().size()])
		_check(flat.has_node("RoomLighting"), tag + " the flat floor keeps its room rig (the dated key light, out on a dark row)")
		# On the terrain nothing in the room adds ambient light, a sky or a second sun: its only lights are the work lights.
		_check(room.find_children("*", "WorldEnvironment", true, false).is_empty() and room.find_children("*", "DirectionalLight3D", true, false).is_empty() and not room.has_node("RoomLighting"), tag + " terrain room adds no environment, ambient fill or directional light")
		var others: Array = room.find_children("*", "Light3D", true, false).filter(func(l): return (l as Node3D).is_visible_in_tree() and not lamps.has(l))
		_check(others.is_empty(), "%s terrain room's only lights are its work lights %s" % [tag, str(others.map(func(l): return String(room.get_path_to(l))))])
		for prop_spec in spec.get("props", []):
			var id := String(prop_spec.id)
			for built in [[room, Presentation.vector(spec.on_ground[segment][id].position), Presentation.vector(spec.on_ground[segment][id].rotation_degrees)], [flat, Vector3(float(prop_spec.xz[0]), 0, float(prop_spec.xz[1])), Vector3(0, float(prop_spec.yaw_deg), 0)]]:
				var host := built[0] as CampaignRoom
				var prop := host.visual_root.get_node_or_null("%s/%s" % [WorkLights.ROOT_NAME, id]) as Node3D
				var where := "terrain" if host == room else "flat floor"
				_check(prop != null and prop.position.distance_to(built[1]) < 0.001 and prop.rotation_degrees.distance_to(built[2]) < 0.01 and String(prop.get_meta("work_light_prop")) == String(prop_spec.asset_id), "%s %s (%s) lies at its %s pose" % [tag, id, prop_spec.asset_id, where])
				if prop == null:
					continue
				for lamp in prop_spec.lamps:
					var light := prop.get_node_or_null(String(lamp.id)) as SpotLight3D
					var lens := light.get_node_or_null("Lens") as MeshInstance3D if light != null else null
					var barrel := prop.global_basis * Presentation.vector(lamp.axis)
					_check(light != null and light.shadow_enabled and light.light_size == 0.0 and lens != null and lens.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and rad_to_deg((-light.global_basis.z).angle_to(barrel)) < 0.5 and light.global_position.distance_to(prop.global_transform * (Presentation.vector(lamp.at) + Presentation.vector(lamp.axis) * WorkLights.LENS_CLEARANCE_M)) < 0.002, "%s %s on the %s is a hard-shadowed lamp shining from just in front of its lit lens, along its barrel" % [tag, lamp.id, where])
				for lamp in prop_spec.lamps:
					var light := prop.get_node_or_null(String(lamp.id)) as Light3D
					_check(light != null and is_equal_approx(light.light_energy, float(lamp.energy) * WorkLights.energy_scale(spec, RenderingServer.get_current_rendering_method(), String(lamp.id))), "%s %s on the %s runs at its energy %.2f times this renderer's fraction" % [tag, lamp.id, where, float(lamp.energy)])
		var state := room.terrain_lighting()
		_check(state.ready and state.on_terrain and int(state.built) == lamps.size() and state.missing.is_empty() and state.segment == segment, "%s CampaignRoom.terrain_lighting() reports ready with every lamp switched on and shown" % tag)
		_check(not bool(flat.terrain_lighting().on_terrain) and int(flat.terrain_lighting().built) == lamps.size(), tag + " flat room reports its lamps but not the terrain")
		# A lamp the scene does not show lights nothing: hiding its prop (as a staging "hide" would) takes its lamps out of
		# work_lights() and the room out of ready under the dark Sun, until it is shown again.
		var hidden_props: Array = [String(spec.rover.prop)] + spec.get("props", []).map(func(p): return "%s/%s" % [WorkLights.ROOT_NAME, p.id])
		for path in hidden_props:
			var node := room.visual_root.get_node(String(path)) as Node3D
			var own: Array = lamps.filter(func(light): return node.is_ancestor_of(light))
			node.hide()
			var hidden := room.terrain_lighting()
			_check(room.work_lights().size() == lamps.size() - own.size() and not bool(hidden.ready) and hidden.missing.size() == own.size() and String(hidden.reason).contains("not on or not shown"), "%s hiding %s takes its %d lamps out and the room out of ready (%s)" % [tag, String(path).get_file(), own.size(), hidden.reason])
			node.show()
		_check(bool(room.terrain_lighting().ready) and room.work_lights().size() == lamps.size(), tag + " is ready again with every prop shown")
		# A visible lamp with no energy cannot light a target. The live hook must refuse readiness even when its prop
		# and Light3D nodes still exist, then recover when the owning system restores the lamp's energy.
		for lamp in lamps:
			var light := lamp as Light3D
			var energy := light.light_energy
			light.light_energy = 0.0
			var unlit := room.terrain_lighting()
			_check(not bool(unlit.ready) and unlit.missing == [WorkLights.lamp_id(light)] and int(unlit.built) == lamps.size() - 1, "%s a zero-energy %s is missing from the live lighting hook" % [tag, light.name])
			light.light_energy = energy
		_check(bool(room.terrain_lighting().ready), tag + " becomes ready after lamp energies recover")
		room._build_work_lights()
		_check(room.work_lights().size() == lamps.size(), tag + " rebuilding the rig retains one instance of every lamp")
		room.free()
		flat.free()
		await process_frame
	# The incremental loader (the campaign's path) puts up the same lamps.
	var lazy := CampaignRoom.new()
	lazy.room_id = "LOC-10"
	lazy.terrain_ground = true
	lazy.load_approved_assets = false
	root.add_child(lazy)
	lazy.set_scene_context("EX-CH04-S06")
	_check(lazy.work_lights().is_empty(), "LOC-10 switches on no lamps before its approved props load")
	_check(not bool(lazy.terrain_lighting().ready) and lazy.terrain_lighting().missing.size() == _lamp_count("LOC-10"), "LOC-10 staged before asynchronous loading is unready with every lamp missing")
	await lazy.load_assets_incremental()
	_check(lazy.work_lights().size() == _lamp_count("LOC-10"), "LOC-10 load_assets_incremental puts up every work light")
	_check(bool(lazy.terrain_lighting().ready) and AssetGeometry.is_prepared("res://assets/props/PR_HandLight/PR_HandLight.glb"), "LOC-10 becomes ready after the added hand light is prepared by the existing asset service")
	await lazy.load_assets_incremental()
	_check(lazy.work_lights().size() == _lamp_count("LOC-10") and bool(lazy.terrain_lighting().ready), "LOC-10 incremental loading can repeat without duplicating a work light")
	lazy.free()
	await process_frame
	# Rooms without work lights are untouched.
	var aurora := _make_room("LOC-06", "", true)
	_check(aurora.work_lights().is_empty() and not aurora.visual_root.has_node(WorkLights.ROOT_NAME), "LOC-06 has no work lights")
	aurora.free()
	await process_frame

# ------------------------------------------------------------------------------------------- coverage

## What a scene asks the player to see on a placement: [name, point, needed light, prop id or ""] for every focus target
## whose prop is shown in the scene (not the rover's own cargo mount, which the crew reach in their helmet lamps' light),
## its approach (on the visible ground), every shown prop and each crew anchor.
func _scene_points(room: CampaignRoom, place: Dictionary) -> Array:
	var points: Array = []
	var shown := func(asset: String) -> bool:
		var node := room.visual_root.get_node_or_null(asset) as Node3D
		return node != null and node.is_visible_in_tree()
	var rover := String(Contract.work_lights(room.room_id).rover.prop)
	for target in Contract.layout(room.room_id).focus_targets:
		var id := String(target.target_id)
		var asset := String(target.get("asset_id", ""))
		if asset == rover or (not asset.is_empty() and not shown.call(asset)) or not place.focus_targets.has(id):
			continue
		points.append(["target " + id, Presentation.vector(place.focus_targets[id]), MIN_TARGET_LIGHT, ""])
		if place.focus_approaches.has(id):
			var spot := Presentation.vector(place.focus_approaches[id])
			var seen := _seen_at(place, spot.x, spot.z)
			points.append(["approach " + id, Vector3(spot.x, maxf(spot.y, seen if not is_nan(seen) else spot.y) + 0.1, spot.z), MIN_GROUND_LIGHT, ""])
	for prop in Contract.layout(room.room_id).props:
		var id := String(prop.id)
		if id == rover or not shown.call(id):
			continue
		var model := room.visual_root.get_node(id) as Node3D
		var box := AssetGeometry.bounds(model)
		# A prop is measured in the middle of its lowest 1.2 m, raised onto the visible ground where the tile mesh covers its
		# base (terrain integration retains its current pose).
		var foot := model.global_transform * box.get_center()
		var seen := _seen_at(place, foot.x, foot.z)
		var bottom := (model.global_transform * box.position).y
		var low := maxf(bottom, seen) if not is_nan(seen) else bottom
		points.append(["prop " + id, Vector3(foot.x, low + minf(box.size.y, 1.2) * 0.5, foot.z), MIN_TARGET_LIGHT, id])
	for id in place.anchors:
		points.append(["crew " + String(id), Presentation.vector(place.anchors[id]) + Vector3.UP * 1.0, MIN_GROUND_LIGHT, ""])
	return points

## Direct light from the room's own lamps at every point a scene asks the player to see, on the terrain.
func _check_coverage() -> void:
	for lit in LIT:
		var room_id := String(lit[0])
		var segment := String(lit[1])
		var place := Contract.terrain(room_id, segment)
		var room := _make_room(room_id, segment, true)
		room.set_scene_context(String(lit[2]))
		var tag := "%s%s %s" % [room_id, "" if segment.is_empty() else " " + segment, lit[2]]
		var occluders := _occluders(room)
		await physics_frame
		await physics_frame
		# The coverage model is Forward+'s (lights add in linear light): approved energies in every renderer.
		var spec := Contract.work_lights(room_id)
		var method := RenderingServer.get_current_rendering_method()
		var report: Array[String] = []
		for point in _scene_points(room, place):
			var best := ""
			var total := 0.0
			for light in room.work_lights():
				var at: Vector3 = point[1]
				if not String(point[3]).is_empty():
					# A prop is lit where a lamp's ray toward its middle first meets it (a solid prop's middle is inside it).
					var hit := room.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create((light as Node3D).global_position, at, 1 << 19))
					if not hit.is_empty() and String((hit.collider as Node).get_meta("mesh_of", "")) == String(point[3]):
						at = hit.position
				var amount := _direct_light(light as Light3D, at, place, room) / WorkLights.energy_scale(spec, method, String(light.name))
				total += amount
				if amount > 0.0 and (best.is_empty() or amount > 0.2 * total):
					best = String(light.name)
			report.append("%s %.2f (%s)" % [point[0], total, best])
			_check(total >= float(point[2]), "%s %s gets %.2f direct light from the work lights (needs %.2f)" % [tag, point[0], total, point[2]])
		print("%s direct light: %s" % [tag, ", ".join(report)])
		for body in occluders:
			body.free()
		room.free()
		await process_frame

## Trimesh colliders for every visible mesh in the room (props, rover, hand light; not lenses, labels or props the
## scene hides), so a ray sees what the renderer's shadow maps see. Returned so the caller frees them.
func _occluders(room: CampaignRoom) -> Array:
	var bodies: Array = []
	for mesh in room.visual_root.find_children("*", "MeshInstance3D", true, false):
		var instance := mesh as MeshInstance3D
		var owner_node: Node = instance
		while owner_node.get_parent() != room.visual_root and owner_node.get_parent() != null and String(owner_node.get_parent().name) != WorkLights.ROOT_NAME:
			owner_node = owner_node.get_parent()
		if instance.mesh == null or not instance.is_visible_in_tree() or instance.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF or instance.visibility_range_begin > 0.0:
			continue
		# Faces in world space on an unscaled body: scaled concave shapes are not reliable in every physics engine.
		var faces := instance.mesh.get_faces()
		var into := instance.global_transform
		for index in faces.size():
			faces[index] = into * faces[index]
		var concave := ConcavePolygonShape3D.new()
		concave.set_faces(faces)
		concave.backface_collision = true
		var body := StaticBody3D.new()
		body.set_meta("mesh_of", String(owner_node.name))
		body.collision_layer = 1 << 19
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		shape.shape = concave
		body.add_child(shape)
		root.add_child(body)
		bodies.append(body)
	return bodies

## The renderer's direct light from one lamp at a room-local point (energy x cone falloff x distance falloff, Godot's
## get_omni_attenuation with the lamp's decay), or 0 when the ground (the higher of the heightfield and the visible tile
## mesh, which is what casts the shadow) or a visible mesh is in the way.
func _direct_light(light: Light3D, point: Vector3, place: Dictionary, room: CampaignRoom) -> float:
	var from := light.global_position
	var to_point := point - from
	var distance := to_point.length()
	var reach: float = (light as SpotLight3D).spot_range if light is SpotLight3D else (light as OmniLight3D).omni_range
	var decay: float = (light as SpotLight3D).spot_attenuation if light is SpotLight3D else (light as OmniLight3D).omni_attenuation
	if distance >= reach or distance < 0.05:
		return 0.0
	var cone := 1.0
	if light is SpotLight3D:
		var spot := light as SpotLight3D
		var cutoff := cos(deg_to_rad(spot.spot_angle))
		var cosine := to_point.normalized().dot(-spot.global_basis.z)
		if cosine <= cutoff:
			return 0.0
		var rim := clampf((1.0 - cosine) / (1.0 - cutoff), 0.0001, 1.0)
		cone = 1.0 - pow(rim, spot.spot_angle_attenuation)
	var nd := pow(distance / reach, 4.0)
	var falloff := pow(maxf(1.0 - nd, 0.0), 2.0) * pow(distance, -decay)
	# Terrain: march the ray over the ground (the last 0.3 m is the target's own ground).
	var steps := int(distance / 0.25)
	for step in range(1, steps):
		var p := from + to_point * (float(step) / float(steps))
		if p.distance_to(point) < 0.3:
			break
		var surface := _ground_at(place, p.x, p.z)
		var shown := _seen_at(place, p.x, p.z)
		if not is_nan(shown):
			surface = maxf(surface, shown)
		if surface > p.y + 0.02:
			return 0.0
	# Meshes: anything between 3 cm out of the lamp and the last 0.15 m before the point (the lens is excluded).
	var query := PhysicsRayQueryParameters3D.create(from + to_point.normalized() * 0.03, point - to_point.normalized() * 0.15, 1 << 19)
	if not room.get_world_3d().direct_space_state.intersect_ray(query).is_empty():
		return 0.0
	return light.light_energy * cone * falloff

# ------------------------------------------------------------------------------------------- capture

## Windowed: each dark placement in its dated scene on the provider's terrain (the stream turned into a segment's
## frame) under the scene's own dated Sun rig, with M3-106's stand-in for the far crater rim (board M3-110 brings it
## into TerrainStream), the scene's suited crew placed by CampaignCrew and the suited player walking to every
## approach. Writes the wide, ground and lamps-off ground views, a strip of the approach views and a strip of the
## lamps, and prints the measured screen brightness at every target in the ground views, and the frame time.
func _capture_all() -> void:
	root.always_on_top = true
	var renderer := "compat" if RenderingServer.get_current_rendering_method() == "gl_compatibility" else "fplus"
	print("capture renderer: ", RenderingServer.get_current_rendering_method())
	var crew := CampaignCrew.new()
	root.add_child(crew)
	for shot in CAPTURE:
		var room_id := String(shot[0])
		var segment := String(shot[1])
		var scene_id := String(shot[2])
		var place := Contract.terrain(room_id, segment)
		var origin := Presentation.vector(place.origin_m)
		var turn := _turn(place)
		var start := Presentation.vector(place.anchors[_player_anchor(place)])
		var room := _make_room(room_id, segment, true)
		var site := Node3D.new()
		site.transform = Transform3D(turn, origin).affine_inverse()
		root.add_child(site)
		var stream := Stream.new()
		site.add_child(stream)
		stream.configure(String(place.region_id), origin + turn * start, place.exclusions.map(func(e): return {"position": Presentation.vector(e.position), "radius_m": float(e.radius_m)}))
		var row := Heightfield.scene_lighting(scene_id, segment)
		var rig := _dated_rig(stream, row, origin)
		site.add_child(rig)
		var world := rig.get_node("World") as WorldEnvironment
		var tag := "M1-91_%s_%s%s_%s" % [renderer, room_id.replace("-", ""), "" if segment.is_empty() else "_" + segment, scene_id.substr(3).replace("-", "")]
		_check(String(row.sun_state) == "dark" and rig.has_node("HorizonOccluder"), "%s has its dated (dark) Sun rig" % tag)
		_check(world.environment.ambient_light_source == Environment.AMBIENT_SOURCE_DISABLED and world.environment.background_color == Color.BLACK, tag + " keeps the black sky and no ambient fill")
		var earth := Contract.earth(room_id, scene_id, segment)
		EarthSky.apply(world.environment, earth, float(stream.config.sun_energy))
		var player := crew.place(scene_id, room, start)
		_check(player != null and crew.local_ids.size() == 2, "%s places the suited field crew (%s)" % [tag, ", ".join(crew.local_ids)])
		var helmets: Array = []
		for id in crew.local_ids:
			var body: PlayerController = crew.bodies[id]
			helmets.append_array(body.find_children("HelmetLamp", "SpotLight3D", true, false))
			_check(String(body.loaded_path).ends_with("_EVA.glb"), "%s %s wears the EVA suit in the vacuum" % [tag, id])
		_check(helmets.size() == crew.local_ids.size(), "%s each suited crew member wears a helmet lamp" % tag)
		print("%s live lighting: %s" % [tag, JSON.stringify(room.terrain_lighting())])
		_check(bool(room.terrain_lighting().ready), tag + " live lighting hook is ready in the staged capture")
		var room_lights: Array = root.find_children("*", "Light3D", true, false).filter(func(l): return not l is DirectionalLight3D and (l as Node3D).is_visible_in_tree() and not helmets.has(l))
		_check(room_lights.size() == room.work_lights().size(), "%s: besides the dated Sun and the crew's helmet lamps, the only lights are the room's work lights" % tag)
		for frame in 600:
			await process_frame
			if stream.pending.is_empty() and frame > 60:
				break
		var camera := Camera3D.new()
		camera.far = 70000.0
		root.add_child(camera)
		var points := _scene_points(room, place).filter(func(p): return String(p[0]).begins_with("target ") or String(p[0]).begins_with("prop "))
		var focus := Vector3.ZERO
		for point in points:
			focus += point[1]
		focus /= float(points.size())
		var away := Vector3(start.x - focus.x, 0, start.z - focus.z).normalized()
		var marks: Array = points.map(func(p): return [p[0], p[1] if String(p[0]).begins_with("prop ") else _ground_spot(place, p[1])])
		var occluders := _occluders(room)
		await physics_frame
		# The wide view looks over the work area from behind the player, to the side away from the rover, with the crew.
		var rover := room.visual_root.get_node(String(Contract.work_lights(room_id).rover.prop)) as Node3D
		var side := signf((rover.position - start).cross(focus - start).y)
		var wide_from := start + away * 11.0 + away.cross(Vector3.UP) * 5.0 * (side if side != 0.0 else 1.0) + Vector3.UP * 6.0
		if bool(shot[3]):
			var wide: Dictionary = await _shot(camera, wide_from, focus, 60.0, tag + "_wide", [])
			print("%s wide view (crew and helmet lamps in): %.4f of the view clipped" % [tag, wide.clipped])
		# The environment views leave the crew and their helmet lamps out (they would hide and light the targets); the
		# approach strip shows them.
		for id in crew.local_ids:
			(crew.bodies[id] as Node3D).hide()
		var approached: Array = _scene_points(room, place).map(func(p): return String(p[0])).filter(func(n): return n.begins_with("approach ")).map(func(n): return n.trim_prefix("approach "))
		var unmeasured: Array = await _ground_views(room, camera, tag, start + Vector3.UP * 1.6, focus, wide_from, marks)
		for mark in unmeasured:
			# A target is also read from its approach (_approach_strip gates it there); a prop must be read in a ground view.
			var target_id := String(mark[0]).trim_prefix("target ")
			var from_approach := String(mark[0]).begins_with("target ") and approached.has(target_id)
			print("%s %s not measured in a ground view (off screen or behind a prop from every view)%s" % [tag, mark[0], "; read from its approach" if from_approach else ""])
			_check(from_approach, "%s %s is measured on screen" % [tag, mark[0]])
		await _frame_time(camera, tag)
		if bool(shot[3]):
			await _lamp_strip(room, camera, tag)
		for id in crew.local_ids:
			(crew.bodies[id] as Node3D).show()
		camera.current = false
		if player != null:
			await _approach_strip(room, place, player, crew.local_ids.map(func(id): return crew.bodies[id]), tag, stream)
		for body in occluders:
			body.free()
		camera.free()
		site.free()
		room.free()
		await process_frame
	crew.free()

## The ground views of one shot, crew hidden. The first looks from the player's eye over the work area; each next one
## aims at the cluster round the first mark still unmeasured (the pending marks within VIEW_CLUSTER_DEG of it), from the
## player's eye if it sees that mark, else from the wide view's spot above and behind the player. Each mark (a target's
## ground spot, a prop) is measured in the first view that has it on screen and in sight, lamps on against the same view
## with them off: it must read (a prop by its lit face, the window's bright tenth; a prop beyond NEAR_PROP_M is
## reported), the lamps must lift it, and neither its window nor the view may clip. Saves <tag>_ground and
## _ground_lamps_off, then _ground_2... and their lamps-off views. Returns the marks no view could measure.
func _ground_views(room: CampaignRoom, camera: Camera3D, tag: String, eye: Vector3, focus: Vector3, high: Vector3, marks: Array) -> Array:
	var pending: Array = marks.duplicate()
	var unmeasured: Array = []
	# work_lights() lists the lamps that are on, so keep the list to switch them back on
	var lamps := room.work_lights()
	var view := 0
	while not pending.is_empty() and view < MAX_GROUND_VIEWS:
		var from := eye
		var to := focus + Vector3.UP * 0.4
		var lead: Array = []
		if view > 0:
			lead = pending[0]
			from = eye if _in_sight(room, eye, lead[1]) else high
			if not _in_sight(room, from, lead[1]):
				unmeasured.append(lead)
				pending.erase(lead)
				continue
			var ahead := Vector2(lead[1].x - from.x, lead[1].z - from.z)
			var cluster: Array = pending.filter(func(mark): return _in_sight(room, from, mark[1]) and absf(rad_to_deg(ahead.angle_to(Vector2(mark[1].x - from.x, mark[1].z - from.z)))) <= VIEW_CLUSTER_DEG)
			to = Vector3.ZERO
			for mark in cluster:
				to += mark[1]
			to /= float(cluster.size())
		var name := "ground" if view == 0 else "ground_%d" % (view + 1)
		view += 1
		var lit: Dictionary = await _shot(camera, from, to, 70.0, "%s_%s" % [tag, name], pending)
		for light in lamps:
			light.visible = false
		var dark: Dictionary = await _shot(camera, from, to, 70.0, "%s_%s_lamps_off" % [tag, name], pending)
		for light in lamps:
			light.visible = true
		print("%s %s view from the %s: %.4f clipped with the lamps on" % [tag, name, "player's eye" if from == eye else "wide view's spot", lit.clipped])
		_check(float(lit.clipped) <= MAX_FRAME_CLIPPED, "%s %s view keeps the lit work area unclipped (%.2f %% of it clipped)" % [tag, name, 100.0 * float(lit.clipped)])
		var still: Array = []
		for index in pending.size():
			var mark: Array = pending[index]
			var on: Vector3 = lit.marks[index]
			var off: Vector3 = dark.marks[index]
			if on.x < 0.0 or not _in_sight(room, from, mark[1]):
				if mark == lead:
					unmeasured.append(mark)  # aimed at and still not measurable: never retried
				else:
					still.append(mark)
				continue
			var prop := String(mark[0]).begins_with("prop ")
			var reads := on.y if prop else on.x
			var gain := (on.y - off.y) if prop else (on.x - off.x)
			var distance := eye.distance_to(mark[1])
			var far: bool = prop and distance > NEAR_PROP_M
			print("%s %s (%s view) screen luma lamps on %.3f (bright tenth %.3f, clipped %.3f) / off %.3f (%.3f)%s" % [tag, mark[0], name, on.x, on.y, on.z, off.x, off.y, " (%.1f m from the player: brightness reported)" % distance if far else ""])
			_check(on.z <= MAX_CLIPPED_SHARE and on.x <= MAX_SCREEN_LUMA, "%s %s does not clip on screen with the lamps (%.3f of its window clipped, mean %.3f)" % [tag, mark[0], on.z, on.x])
			if not far:
				_check(reads >= MIN_SCREEN_LUMA, "%s %s reads on screen with the lamps (%.3f)" % [tag, mark[0], reads])
				_check(gain >= LAMP_GAIN_LUMA, "%s %s is lit by the lamps (+%.3f)" % [tag, mark[0], gain])
		pending = still
	_check(room.work_lights().size() == lamps.size(), tag + " every work light is back on after the lamps-off views")
	return unmeasured + pending

## The dated light of one bundled Horizons row in the region's frame: black sky, no ambient or reflected fill, one Sun
## with hard four-split shadows (the rig TerrainStream.lighting builds for a scene's own row). On a dark row a
## shadow-only wall 400 m toward the Sun with its top at the row's terrain horizon stands in for the far crater rim,
## which lies outside the region's heightfield, so the local ground stays in shadow while rims beyond it stay sunlit.
## The same as test_chapter4_rooms.gd _dated_rig (M3-106) until board M3-110 brings the occluder into TerrainStream.
func _dated_rig(stream: Node3D, row: Dictionary, at: Vector3) -> Node3D:
	var rig := Node3D.new()
	rig.name = "DatedLunarLighting"
	var world := WorldEnvironment.new()
	world.name = "World"
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color.BLACK
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
	world.environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	world.environment.fog_enabled = false
	world.environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	rig.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_energy = float(stream.config.sun_energy)
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = float(stream.config.shadow_distance_m)
	sun.shadow_normal_bias = 1.5
	sun.shadow_bias = 0.03
	sun.basis = stream.field.sun_light_basis(float(row.sun_az_deg), float(row.sun_el_deg))
	rig.add_child(sun)
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
		wall.transform = Transform3D(Basis.looking_at(-toward, Vector3.UP), at + toward * distance + Vector3.UP * (top - 1500.0))
		rig.add_child(wall)
	return rig

## The suited player walks from its anchor to every approach on the provider's collision (following detours), turns to
## the target and is framed by its own follow camera. Work-area brightness is measured with the crew hidden (the room's
## work lights alone); the rover's rear cargo mount is measured with the suited crew's helmet lamps on, as canon lights
## that side of the rover. Every view is saved with everyone there, helmet lamps on, as the player sees it.
func _approach_strip(room: CampaignRoom, place: Dictionary, player: PlayerController, crew: Array, tag: String, stream: Node3D) -> void:
	var follow := player.get_node("FollowCamera") as FollowCamera
	follow.camera.current = true
	player.set_physics_process(false)
	var names: Array = _scene_points(room, place).map(func(p): return String(p[0]))
	var approaches: Array = place.focus_approaches.keys().filter(func(id): return names.has("approach " + String(id)))
	# The forward-facing rover floods do not light its own rear cargo rack. Include that final approach and measure it
	# with the actual suit lamps instead of omitting it from the walking and readability evidence.
	var cargo_targets: Array = Contract.layout(room.room_id).focus_targets.filter(func(t): return String(t.get("asset_id", "")) == String(Contract.work_lights(room.room_id).rover.prop)).map(func(t): return String(t.target_id))
	for id in cargo_targets:
		if place.focus_approaches.has(id) and not approaches.has(id):
			approaches.append(id)
	var strip := Image.create(640 * approaches.size(), 360, false, Image.FORMAT_RGB8)
	var slot := 0
	var start := Presentation.vector(place.anchors[_player_anchor(place)])
	for id in approaches:
		player.position = start + Vector3.UP * 0.05
		follow.reset_placement()
		for waypoint in place.detours.get(id, []) + [place.focus_approaches[id]]:
			var to := Presentation.vector(waypoint)
			for step in 900:
				var delta := to - player.position
				delta.y = 0
				if delta.length() < 0.1:
					break
				player.velocity = delta.normalized() * 3.0 + Vector3.DOWN
				player.move_and_slide()
				stream.call("move_focus", _site(place, player.position))
				await physics_frame
		var goal := Presentation.vector(place.focus_approaches[id])
		_check(Vector2(player.position.x - goal.x, player.position.z - goal.z).length() < 0.15 and absf(player.position.y - goal.y) < 0.25, "%s suited player walks to the %s approach in the lit dated scene" % [tag, id])
		var target := Presentation.vector(place.focus_targets[id])
		var suit_lit: bool = cargo_targets.has(String(id))
		var spot := _ground_spot(place, target)
		if suit_lit:
			var rover := room.visual_root.get_node(String(Contract.work_lights(room.room_id).rover.prop)) as Node3D
			var cargo := rover.global_transform * Vector3(0.0, 1.5, -2.0)
			var hit := room.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP * 1.4, cargo, 1 << 19))
			spot = hit.position if not hit.is_empty() else cargo
			target = spot
		var direction := target - player.global_position
		player.reset_placement()
		player.face_towards(target)
		follow.yaw = atan2(direction.x, direction.z) - PI
		player._gaze_target.global_position = player.global_position + Vector3.UP * 1.5 + player.visual.global_basis.z * 4.0
		for _step in 20:
			player._update_gaze(0.05)
			player.animation.skeleton.advance(0.05)
		# The player's own camera behind them, turned round the player (as a player would) when a set piece stands in the
		# way: the first turn that sees the target and the player, with the target's ground spot on screen. Its spring arm
		# collides only with walk collision, so it can sit inside a prop's mesh; then any turn that sees the target.
		var chosen := NAN
		var fallback := NAN
		for turn in [0.0, 35.0, -35.0, 70.0, -70.0, 105.0, -105.0]:
			await _place_follow(follow, direction, turn)
			var eye := follow.camera.global_position
			if not _in_sight(room, eye, target):
				continue
			if is_nan(fallback):
				fallback = turn
			var head_clear := not suit_lit or (
				follow.camera.unproject_position(spot).distance_to(follow.camera.unproject_position(player.global_position + Vector3.UP * 1.8)) > 48.0
				and follow.camera.unproject_position(spot).distance_to(follow.camera.unproject_position(player.global_position + Vector3.UP * 1.45)) > 48.0
			)
			if _in_sight(room, eye, player.global_position + Vector3.UP * 1.2) and _on_screen(follow.camera, spot) and head_clear:
				chosen = turn
				break
		if is_nan(chosen) and not is_nan(fallback):
			await _place_follow(follow, direction, fallback)
		print("%s approach %s: follow camera turned %s deg%s" % [tag, id, str(chosen if not is_nan(chosen) else fallback), "" if not is_nan(chosen) else " (the player is hidden from every turn that sees the target)"])
		# Work-area targets: measured without the crew so the room lights alone must make them readable. The rear
		# cargo rack uses the suit lamps. Save every view with the crew visible, as the player sees it.
		if not suit_lit:
			for body in crew:
				(body as Node3D).hide()
		var measured: Image = await _frame()
		var reading := _luma(measured, follow.camera, spot)
		var clipped := _clipped_share(measured)
		for body in crew:
			(body as Node3D).show()
		var image: Image = await _frame()
		var sources := "work lights and the suited crew's helmet lamps" if suit_lit else "work lights alone"
		print("%s approach %s: target screen luma %.3f (clipped %.3f) with %s, %.4f of the view clipped; %.4f with the crew and their helmet lamps in" % [tag, id, reading.x, reading.z, sources, clipped, _clipped_share(image)])
		_check(reading.x >= MIN_SCREEN_LUMA, "%s target %s is on screen and reads from its approach by %s (%.3f)" % [tag, id, sources, reading.x])
		_check(reading.z <= MAX_CLIPPED_SHARE and clipped <= MAX_FRAME_CLIPPED, "%s target %s and the view from its approach do not clip (%.3f of its window, %.2f %% of the view)" % [tag, id, reading.z, 100.0 * clipped])
		image.convert(Image.FORMAT_RGB8)
		image.resize(640, 360, Image.INTERPOLATE_LANCZOS)
		strip.blit_rect(image, Rect2i(0, 0, 640, 360), Vector2i(slot * 640, 0))
		slot += 1
	player.set_physics_process(true)
	_check(strip.save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/%s_approaches.png" % tag)) == OK, "capture %s_approaches" % tag)

## Puts the follow camera behind the player, turned by turn_deg round them from straight behind (direction: from the
## player to what they face), and lets it settle.
func _place_follow(follow: FollowCamera, direction: Vector3, turn_deg: float) -> void:
	follow.yaw = atan2(direction.x, direction.z) - PI + deg_to_rad(turn_deg)
	follow.pitch = -0.18
	follow.reset_placement()
	for frame in 10:
		follow.update_camera(1.0 / 60.0, atan2(direction.x, direction.z), 0.0)
		await process_frame

## True when a point is in front of the camera and inside the view, 40 px clear of its edges (base canvas).
func _on_screen(camera: Camera3D, point: Vector3) -> bool:
	if camera.is_position_behind(point):
		return false
	var at := camera.unproject_position(point)
	return root.get_visible_rect().grow(-40.0).has_point(at)

## True when nothing visible stands between the eye and a point (the occluders' ray layer).
func _in_sight(room: CampaignRoom, eye: Vector3, point: Vector3, mask: int = 1 << 19) -> bool:
	var ray := PhysicsRayQueryParameters3D.create(eye, point + (eye - point).normalized() * 0.3, mask)
	return room.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

## The lamps at work, side by side: the rover from above and behind, looking along its beams at the focus targets its
## floods are turned onto, and, at the shelf, a close-up of Kai's hand light, in the dark scene.
func _lamp_strip(room: CampaignRoom, camera: Camera3D, tag: String) -> void:
	var spec := Contract.work_lights(room.room_id)
	var rover := room.visual_root.get_node_or_null(String(spec.rover.prop)) as Node3D
	var views: Array = []
	if rover != null:
		var aimed := Vector3.ZERO
		for lamp in spec.rover.aim:
			aimed += (room.focus_root.get_node("Focus_" + String(spec.rover.aim[lamp])) as Node3D).global_position
		aimed /= float(spec.rover.aim.size())
		views.append([rover.global_transform * Vector3(-2.5, 6.0, -8.0), aimed, 55.0])
	for prop in spec.get("props", []):
		var hand := room.visual_root.get_node_or_null("%s/%s" % [WorkLights.ROOT_NAME, prop.id]) as Node3D
		if hand != null:
			views.append([hand.global_transform * Vector3(0.55, 0.35, 0.5), hand.global_transform * Vector3(0.06, 0.05, 0), 40.0])
	var strip := Image.create(800 * views.size(), 450, false, Image.FORMAT_RGB8)
	for slot in views.size():
		camera.fov = float(views[slot][2])
		camera.position = views[slot][0]
		camera.look_at(views[slot][1])
		camera.current = true
		var image: Image = await _frame()
		image.convert(Image.FORMAT_RGB8)
		image.resize(800, 450, Image.INTERPOLATE_LANCZOS)
		strip.blit_rect(image, Rect2i(0, 0, 800, 450), Vector2i(slot * 800, 0))
	_check(strip.save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/%s_lamps.png" % tag)) == OK, "capture %s_lamps" % tag)

## The ground under a point (10 cm up): where the player looks to find a target.
func _ground_spot(place: Dictionary, target: Vector3) -> Vector3:
	var seen := _seen_at(place, target.x, target.z)
	return Vector3(target.x, (seen if not is_nan(seen) else _ground_at(place, target.x, target.z)) + 0.1, target.z)

## Median and 95th-percentile frame time over 120 drawn frames with the lamps on (vsync on; a covered window is
## reported as not measured).
func _frame_time(camera: Camera3D, tag: String) -> void:
	camera.current = true
	_draws.clear()
	for frame in 400:
		await process_frame
		if _draws.size() > 120:
			break
	if _draws.size() <= 120:
		print("%s frame time not measured: the window drew %d frames in 400 (covered by another window)" % [tag, _draws.size()])
		return
	var times: Array[float] = []
	for index in range(1, 121):
		times.append(float(_draws[index] - _draws[index - 1]) / 1000.0)
	times.sort()
	print("%s frame time with the work lights: median %.2f ms, p95 %.2f ms (%s, 1600x900, vsync)" % [tag, times[60], times[113], RenderingServer.get_current_rendering_method()])

func _player_anchor(place: Dictionary) -> String:
	for key in place.anchors:
		if String(key).ends_with("_player"):
			return String(key)
	return ""

## Frames one view, saves it, and returns {"marks": the screen luma at each mark (_luma), "clipped": _clipped_share}.
func _shot(camera: Camera3D, from: Vector3, to: Vector3, fov: float, id: String, marks: Array) -> Dictionary:
	camera.fov = fov
	camera.position = from
	camera.look_at(to)
	camera.current = true
	var image: Image = await _frame()
	_check(image.save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/%s.png" % id)) == OK, "capture " + id)
	return {"marks": marks.map(func(mark): return _luma(image, camera, mark[1])), "clipped": _clipped_share(image)}

## The share of a frame's pixels (every 4th row and column) with a colour channel at CLIP_LEVEL or above.
func _clipped_share(image: Image) -> float:
	var clipped := 0
	var total := 0
	for y in range(0, image.get_height(), 4):
		for x in range(0, image.get_width(), 4):
			var color := image.get_pixel(x, y)
			total += 1
			if maxf(color.r, maxf(color.g, color.b)) >= CLIP_LEVEL:
				clipped += 1
	return float(clipped) / float(maxi(total, 1))

## One drawn frame (retried while the first frames after a shader compile come back black). It waits for 8 draws, or
## 40 process frames if the window is covered, and then forces a draw.
func _frame() -> Image:
	var image: Image
	for attempt in 4:
		var before := _draws.size()
		for frame in 40:
			await process_frame
			if _draws.size() >= before + 8:
				break
		if _draws.size() < before + 8:
			RenderingServer.force_draw(false)
		image = root.get_texture().get_image()
		if image.get_size().x > 0 and not image.is_invisible() and _mean_luma(image) > 0.0005:
			break
	return image

func _mean_luma(image: Image) -> float:
	var total := 0.0
	for y in range(0, image.get_height(), 16):
		for x in range(0, image.get_width(), 16):
			total += image.get_pixel(x, y).get_luminance()
	return total / float((image.get_height() / 16 + 1) * (image.get_width() / 16 + 1))

## The luma of a 31 px window round where a point lands in the saved frame (unproject answers in the base canvas, so
## scale to the image): (mean, 90th percentile, share of its pixels clipped: a channel at CLIP_LEVEL or above), or
## (-1, -1, -1) when it is behind the camera or off screen.
func _luma(image: Image, camera: Camera3D, point: Vector3) -> Vector3:
	if camera.is_position_behind(point):
		return Vector3(-1.0, -1.0, -1.0)
	var scale := Vector2(image.get_size()) / root.get_visible_rect().size
	var at := camera.unproject_position(point) * scale
	if at.x < 15 or at.y < 15 or at.x > image.get_width() - 16 or at.y > image.get_height() - 16:
		return Vector3(-1.0, -1.0, -1.0)
	var values: Array[float] = []
	var total := 0.0
	var clipped := 0
	for dy in range(-15, 16):
		for dx in range(-15, 16):
			var color := image.get_pixel(int(at.x) + dx, int(at.y) + dy)
			var value := color.get_luminance()
			values.append(value)
			total += value
			if maxf(color.r, maxf(color.g, color.b)) >= CLIP_LEVEL:
				clipped += 1
	values.sort()
	return Vector3(total / 961.0, values[864], float(clipped) / 961.0)
