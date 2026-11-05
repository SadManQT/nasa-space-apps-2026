## M3-7A: the Chapter 7 (The Great Storm) shelter and uplink props and EN_Fabrication.
## Reads chapter7_assets.json next to this script (written by production/tools/build_chapter7_assets.py), builds an asset
## as a two-LOD node with Godot visibility ranges and the collision the game-LOD GLB already carries, applies its mount
## height, and drives its moving parts, lamps and live screens. Rooms (M1-06, M3-7R) own placement; puzzles (M3-7P)
## and missions own the rules and call these helpers to show state. Nothing here mutates campaign state.
extends RefCounted

const CATALOG_PATH := "res://assets/props/chapter7_assets.json"
const LOD1_SUFFIX := "_LOD1"
static var _catalog: Dictionary = {}
static var _scenes: Dictionary = {}
static var _lamp_cache: Dictionary = {}

## The whole catalogue: conventions, assets (id, lods, triangles, size, mount, sockets, moving parts, screens, lamps,
## states) and the route-simulator science block.
static func catalog() -> Dictionary:
	if _catalog.is_empty():
		_catalog = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	return _catalog

## Every asset id in catalogue order.
static func ids() -> PackedStringArray:
	var out := PackedStringArray()
	for item in catalog().assets:
		out.append(item.id)
	return out

## The catalogue entry for one asset, or an empty dictionary for an unknown id.
static func entry(id: String) -> Dictionary:
	for item in catalog().assets:
		if item.id == id:
			return item
	return {}

## The route simulator's data: transform, road, sites, pads, hop table, blocked lines and the direct-line finding.
static func route() -> Dictionary:
	return catalog().get("route_simulator", {})

## The height a wall piece's base is mounted at (0 for floor and table pieces).
static func mount_y(id: String) -> float:
	return float(entry(id).get("mount_y", 0.0))

## A socket's position in the asset's own space (the same in every LOD), or Vector3.INF for an unknown socket.
static func socket_position(id: String, socket: String) -> Vector3:
	var sockets: Dictionary = entry(id).get("sockets", {})
	if not sockets.has(socket):
		return Vector3.INF
	var p: Array = sockets[socket]
	return Vector3(float(p[0]), float(p[1]), float(p[2]))

static func _scene(path: String) -> PackedScene:
	if not _scenes.has(path):
		_scenes[path] = load(path)
	return _scenes[path]

## Builds an asset: a Node3D named after the id holding one child per LOD ("LOD0", "LOD1"). LOD0 keeps the GLB's
## StaticBody3D collision unless with_collision is false; LOD1 is visual only and takes over beyond lod_distance_m.
## max_lod 0 forces the game LOD everywhere (close-up inspection). Every part starts in its rest state (markers parked,
## case closed and latched, cells empty, buttons out, tag hidden, pins parked).
static func instance(id: String, with_collision: bool = true, max_lod: int = 1) -> Node3D:
	var item := entry(id)
	if item.is_empty():
		push_error("Chapter7Assets: unknown asset " + id)
		return null
	var node := Node3D.new()
	node.name = id
	node.set_meta("chapter7_id", id)
	var switch := float(item.get("lod_distance_m", 8.0))
	var lods: Array = item.lods
	var last := mini(max_lod, lods.size() - 1)
	for lod in range(last + 1):
		var packed := _scene(lods[lod])
		if packed == null:
			push_error("Chapter7Assets: missing " + String(lods[lod]))
			continue
		var child := packed.instantiate() as Node3D
		child.name = "LOD%d" % lod
		for mesh in child.find_children("*", "MeshInstance3D", true, false):
			var geometry := mesh as GeometryInstance3D
			geometry.visibility_range_begin = switch if lod > 0 else 0.0
			geometry.visibility_range_end = switch if (lod == 0 and last > 0) else 0.0
			geometry.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		if lod > 0 or not with_collision:
			for body in child.find_children("*", "StaticBody3D", true, false):
				body.get_parent().remove_child(body)
				body.free()
		node.add_child(child)
	set_water_units(node, 0)
	set_diagnosed(node, false)
	return node

## Instances an asset under parent with its base at position (the mount height is added for wall pieces) and a yaw in
## degrees. A wall piece shares its kit wall's position and yaw: its back face is the wall's face plane.
static func place(parent: Node3D, id: String, position: Vector3, yaw_degrees: float = 0.0, with_collision: bool = true, max_lod: int = 1) -> Node3D:
	var node := instance(id, with_collision, max_lod)
	if node == null:
		return null
	node.position = position + Vector3(0.0, mount_y(id), 0.0)
	node.rotation_degrees = Vector3(0.0, yaw_degrees, 0.0)
	parent.add_child(node)
	return node

## The named moving part (a child pivot node) in every LOD of a built asset.
static func parts(node: Node3D, part: String) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for found in node.find_children(part, "Node3D", true, false):
		out.append(found as Node3D)
	return out

static func _id(node: Node3D) -> String:
	return String(node.get_meta("chapter7_id", node.name))

static func _move(node: Node3D, part: String, position: Vector3) -> bool:
	var found := parts(node, part)
	for p in found:
		p.position = position
	return not found.is_empty()

static func _turn(node: Node3D, part: String, axis: String, degrees: float) -> bool:
	var found := parts(node, part)
	for p in found:
		var r := Vector3.ZERO
		r[{"x": 0, "y": 1, "z": 2}[axis]] = degrees
		p.rotation_degrees = r
	return not found.is_empty()

## PR_ShelterDiagram: snaps a role's seat marker (Kai, Amara, Mei, Rafi, Ferreira) to a slot: "Seat_1".."Seat_5" on the
## plan or "Park_1".."Park_5" on the strip. Returns false for an unknown role or slot. A marker is a position, not proof:
## the roster gate still needs the name and the answer (EX-CH07-S05).
static func set_marker(node: Node3D, role: String, slot: String) -> bool:
	var at := socket_position(_id(node), slot)
	if at == Vector3.INF:
		return false
	return _move(node, "SeatMarker_" + role, at)

## PR_SeedCase: lid opening (0 closed .. 1 fully open) and the draw latch. The rules (no opening during exposure,
## latch both compartments before the peak) belong to the puzzle; this only shows the state.
static func set_case(node: Node3D, lid_open: float, latched: bool) -> void:
	var states: Dictionary = entry(_id(node)).states
	_turn(node, "Lid", "x", float(states.lid.open_deg) * clampf(lid_open, 0.0, 1.0))
	_turn(node, "Latch", "x", 0.0 if latched else float(states.latch.released_deg))

## PR_SeedCase: one compartment's inner seal lid ("A" or "B"), 0 sealed .. 1 open.
static func set_compartment(node: Node3D, compartment: String, open: float) -> void:
	var states: Dictionary = entry(_id(node)).states
	var c: Dictionary = states.compartments.get(compartment, {})
	if not c.is_empty():
		_turn(node, String(c.node), "x", float(c.open_deg) * clampf(open, 0.0, 1.0))

## PR_SeedCase (LOD0): how many seeds the model physically holds, counted from its seed geometry (must be 30).
static func count_seeds(node: Node3D) -> int:
	var states: Dictionary = entry(_id(node)).get("states", {})
	var per_seed := int(states.get("seed_triangles_lod0", 0))
	var group := node.get_node_or_null("LOD0")
	if per_seed <= 0 or group == null:
		return 0
	var triangles := 0
	for mesh in group.find_children("*", "MeshInstance3D", true, false):
		var m := (mesh as MeshInstance3D).mesh
		for s in m.get_surface_count():
			var mat := m.surface_get_material(s)
			if mat != null and mat.resource_name == String(states.seed_material):
				triangles += m.surface_get_array_index_len(s) / 3
	return triangles / per_seed

## PR_ValveDiagram: shows W, the water units in the shelter wall (0..6): cells 1..units are filled.
static func set_water_units(node: Node3D, units: int) -> void:
	for k in range(1, 7):
		for cell in parts(node, "WaterCell_%d" % k):
			cell.visible = k <= units

## PR_ValveDiagram: the return-time selector, "early" (drain before the exposure sample) or "after" (canon order).
static func set_return_selector(node: Node3D, choice: String) -> void:
	var sel: Dictionary = entry(_id(node)).states.selector
	_turn(node, String(sel.node), "z", float(sel.after_deg) if choice == "after" else float(sel.early_deg))

## Lights a lamp material ("Lamp_Local", "Lamp_SealA", "Lamp_E", ...) in every LOD: "off", "idle", "pass", "fail",
## "warn" or "on" (colours in the catalogue). Lamps never carry meaning alone: the screens say it in words.
static func set_lamp(node: Node3D, lamp: String, state: String) -> int:
	var palette: Dictionary = catalog().conventions.lamp_states
	if not palette.has(state):
		return 0
	if not _lamp_cache.has(state):
		var c: Array = palette[state]
		var mat := StandardMaterial3D.new()
		mat.resource_name = "LampState_" + state
		mat.albedo_color = Color(float(c[0]), float(c[1]), float(c[2]))
		mat.roughness = 0.25
		mat.emission_enabled = float(c[3]) > 0.0
		mat.emission = Color(float(c[0]), float(c[1]), float(c[2]))
		mat.emission_energy_multiplier = float(c[3])
		_lamp_cache[state] = mat
	var changed := 0
	for slot in _surfaces(node, lamp):
		(slot.mesh as MeshInstance3D).set_surface_override_material(int(slot.surface), _lamp_cache[state])
		changed += 1
	return changed

## The live-UI surfaces of an asset: [{mesh, surface, name}] for every surface whose material is a Screen_* slot
## (any LOD). Assign a ViewportTexture material with mesh.set_surface_override_material(surface, material).
static func screen_surfaces(node: Node3D, screen: String = "") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for slot in _surfaces(node, screen if screen != "" else "Screen_", screen == ""):
		out.append(slot)
	return out

static func _surfaces(node: Node3D, material_name: String, prefix: bool = false) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for mesh in node.find_children("*", "MeshInstance3D", true, false):
		var mi := mesh as MeshInstance3D
		if mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(s)
			if mat == null:
				continue
			var n := String(mat.resource_name)
			var base := n.trim_suffix(LOD1_SUFFIX)
			if (prefix and n.begins_with(material_name)) or base == material_name:
				out.append({"mesh": mi, "surface": s, "name": base})
	return out

## PR_NetworkDiagnostic: presses ("Local", "Dish" or "Feed") a branch test button in or releases it.
static func press_test(node: Node3D, branch: String, pressed: bool) -> void:
	var b: Dictionary = entry(_id(node)).states.branches.get(branch, {})
	if b.is_empty():
		return
	var pivot: Array = entry(_id(node)).moving_parts[String(b.button)]
	for p in parts(node, String(b.button)):
		p.position.z = float(pivot[2]) + (float(b.press_m) if pressed else 0.0)

## PR_NetworkDiagnostic: the isolation key turned to isolated (exposed radio hardware off) or back, with its lamp.
static func set_isolated(node: Node3D, isolated: bool) -> void:
	var iso: Dictionary = entry(_id(node)).states.isolation
	_turn(node, String(iso.node), "z", float(iso.isolated_deg) if isolated else 0.0)
	set_lamp(node, String(iso.lamp), "warn" if isolated else "off")

## PR_NetworkDiagnostic: the DataCard pulled out (it carries the saved relay-bypass diagram to EX-CH07-S10) or seated.
## PR_ArchivePlayer: the ArchiveCard ejected or seated.
static func set_card_out(node: Node3D, out: bool) -> void:
	var states: Dictionary = entry(_id(node)).get("states", {})
	var card: Dictionary = states.get("data_card", states.get("card", {}))
	if card.is_empty():
		return
	var pivot: Array = entry(_id(node)).moving_parts[String(card.node)]
	var at := Vector3(float(pivot[0]), float(pivot[1]), float(pivot[2]))
	var amount := float(card.get("pull_m", card.get("eject_m", 0.0))) if out else 0.0
	at[{"x": 0, "y": 1, "z": 2}[String(card.axis)]] += amount
	_move(node, String(card.node), at)

## PR_UplinkFeedthrough: the lockout tag shows once the external feedthrough (F-EXT) is diagnosed.
static func set_diagnosed(node: Node3D, diagnosed: bool) -> void:
	for tag in parts(node, "DiagnosedTag"):
		tag.visible = diagnosed

## EN_Fabrication_RouteSimulator: puts repeater pin 1..3 on a socket ("Pad_R1", "Pad_R2_Road", "PinPark_3", ...).
static func place_pin(node: Node3D, pin: int, socket: String) -> bool:
	var at := socket_position(_id(node), socket)
	if at == Vector3.INF:
		return false
	return _move(node, "RepeaterPin_%d" % pin, at)

## EN_Fabrication_Bench: moves a bench part (SpareBattery, Connector_*, Checklist) to a socket or a local position.
static func move_part(node: Node3D, part: String, socket: String) -> bool:
	var at := socket_position(_id(node), socket)
	if at == Vector3.INF:
		return false
	return _move(node, part, at)

## The hop record between two route nodes ("Aurora", "R1".."R3", "Summit") from the line-of-sight table, or {}.
static func hop(frm: String, to: String) -> Dictionary:
	for h in route().get("hops", []):
		if (h.frm == frm and h.to == to) or (h.frm == to and h.to == frm):
			return h
	return {}
