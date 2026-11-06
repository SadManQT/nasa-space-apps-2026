## M3-2A: the EN_Airlock catalogue (five kit-extension pieces built on the M1-05 conventions), the LOC-05
## double-interlock vestibule assembled from airlock.json, and the pressure interlock that drives both hatches,
## both panels (lamps and the live words SEALED / EQUALISING / SAFE TO OPEN), the pump sound and the sealed
## carrier pass-through lids. Every kit piece comes from habitat_kit.gd; M1-06 (rooms) decides where the room sits
## and owns navigation and the campaign hookup. Gameplay values (equalise time, states, sides) live in airlock.json.
extends Node3D

const Kit = preload("res://assets/environment/kit/habitat_kit.gd")
const CATALOG_PATH := "res://assets/environment/EN_Airlock/airlock.json"
const HATCH_SIDE := {"inner": "habitat", "outer": "surface"}
const HATCH_ROLE := {"inner": "inner_hatch", "outer": "outer_hatch"}
const PANEL_HATCH := {"vestibule_panel": "inner", "chamber_panel": "outer"}
const STATE_COLOUR := {"SEALED": Color(1.0, 0.22, 0.14), "EQUALISING": Color(1.0, 0.70, 0.18), "SAFE TO OPEN": Color(0.35, 1.0, 0.45)}
const WARM_WHITE := Color(1.0, 0.81, 0.65)  # 4000 K practicals in the vestibule (ART_BIBLE section 4)
const SERVICE_WHITE := Color(1.0, 0.89, 0.81)  # 5000 K work light in the chamber

## The hatch state words changed on a panel: which hatch ("inner" or "outer") and its new text.
signal state_changed(which: String, text: String)
## A requested cycle finished: the chamber now matches this side ("habitat" or "surface").
signal cycle_finished(side: String)
## A hatch leaf moved.
signal hatch_changed(which: String, open: bool)

static var _catalog: Dictionary = {}

@export var build_on_ready := true
@export var with_lights := true

var nodes: Dictionary = {}  ## role -> the placed Node3D (inner_door, inner_hatch, outer_hatch, vestibule_panel, chamber_panel, pass_through, glove_ports, bench, locker_<name>)
var _hatch_open := {"inner": false, "outer": false}
var _lid_open := {"LidA": false, "LidB": false}
var _chamber_side := "habitat"
var _target_side := ""
var _cycling := false
var _equalising_left := 0.0
var _labels: Dictionary = {}
var _pump: AudioStreamPlayer3D
var _built := false

# ----------------------------------------------------------------------------------------------- catalogue

## The whole airlock catalogue: conventions, pieces, props, interlock and pass-through rules, cadets, vestibule layout.
static func catalog() -> Dictionary:
	if _catalog.is_empty():
		_catalog = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	return _catalog

## Every airlock piece id in catalogue order.
static func ids() -> PackedStringArray:
	var out := PackedStringArray()
	for entry in catalog().pieces:
		out.append(entry.id)
	return out

## The catalogue entry for one airlock piece, or an empty dictionary.
static func piece(id: String) -> Dictionary:
	for entry in catalog().pieces:
		if entry.id == id:
			return entry
	return {}

## The catalogue entry for one Chapter 2 prop (PR_PaperBee, PR_SeedTray), or an empty dictionary.
static func prop(id: String) -> Dictionary:
	for entry in catalog().props:
		if entry.id == id:
			return entry
	return {}

## The interlock rules from the data file: states, sides, equalise_seconds, pump_sfx.
static func interlock() -> Dictionary:
	return catalog().interlock

## Builds an airlock piece as a two-LOD group (kit ids are passed through to the kit).
static func instance(id: String, with_collision: bool = true, max_lod: int = 1) -> Node3D:
	if id.begins_with("EN_Kit_"):
		return Kit.instance(id, with_collision, max_lod)
	var entry := piece(id)
	if entry.is_empty():
		push_error("EnAirlock: unknown piece " + id)
		return null
	return Kit.instance_entry(entry, with_collision, max_lod)

## Instances a piece (kit or airlock) under parent at a grid position with a yaw in degrees; mount offsets applied.
static func place(parent: Node3D, id: String, position: Vector3, yaw_degrees: float = 0.0, with_collision: bool = true, max_lod: int = 1) -> Node3D:
	if id.begins_with("EN_Kit_"):
		return Kit.place(parent, id, position, yaw_degrees, with_collision, max_lod)
	var node := instance(id, with_collision, max_lod)
	if node == null:
		return null
	node.position = position + Vector3(0.0, float(piece(id).get("mount_y", 0.0)), 0.0)
	node.rotation_degrees = Vector3(0.0, yaw_degrees, 0.0)
	parent.add_child(node)
	return node

## Every surface of a node whose material name starts with the prefix ("Lamp", "RoleTab", "Screen"...).
static func surfaces_named(node: Node3D, prefix: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for mesh in node.find_children("*", "MeshInstance3D", true, false):
		var instance_mesh := mesh as MeshInstance3D
		if instance_mesh.mesh == null:
			continue
		for surface in instance_mesh.mesh.get_surface_count():
			var material := instance_mesh.get_active_material(surface)
			if material != null and material.resource_name.begins_with(prefix):
				out.append({"mesh": instance_mesh, "surface": surface, "material": material})
	return out

# ----------------------------------------------------------------------------------------------- assembly

func _ready() -> void:
	if build_on_ready:
		build()

## Assembles the vestibule from airlock.json under this node: kit walls, floor, ceiling, lights, the airlock pieces,
## the five lockers in the cadets' role colours, the screen labels, the pump and the interlock's starting state.
func build() -> Dictionary:
	if _built:
		return {"accepted": true, "duplicate": true}
	var layout: Dictionary = catalog().vestibule
	var strip_y := Kit.mount_y("EN_Kit_LightStrip")
	for placement in layout.placements:
		var at := Vector3(placement.position[0], placement.position[1], placement.position[2])
		var node := place(self, placement.piece, at, float(placement.yaw))
		if node == null:
			continue
		var role := String(placement.get("role", ""))
		if role != "":
			nodes[role] = node
		if placement.has("role_tab"):
			_tint(node, "RoleTab", Color(String(placement.role_tab)))
		if placement.piece == "EN_Kit_LightStrip" and with_lights:
			var lamp := SpotLight3D.new()
			lamp.position = at + Vector3(0.0, strip_y - 0.015, 0.0)
			lamp.rotation_degrees = Vector3(-90, 0, 0)
			lamp.light_color = WARM_WHITE if at.x < float(layout.zones.vestibule.x[1]) else SERVICE_WHITE
			lamp.light_energy = 2.4 if at.x < float(layout.zones.vestibule.x[1]) else 1.8
			lamp.light_size = 0.08
			lamp.spot_range = 4.5
			lamp.spot_angle = 82.0
			lamp.spot_angle_attenuation = 0.7
			lamp.shadow_enabled = true
			add_child(lamp)
	for panel_role in PANEL_HATCH:
		if nodes.has(panel_role):
			_labels[panel_role] = _screen_label(nodes[panel_role])
	var sfx := String(interlock().get("pump_sfx", ""))
	if sfx != "" and ResourceLoader.exists(sfx) and nodes.has("chamber_panel"):
		_pump = AudioStreamPlayer3D.new()
		_pump.stream = load(sfx)
		_pump.unit_size = 6.0
		_pump.position = (nodes.chamber_panel as Node3D).position + Vector3(-0.3, 0.8, 0.0)
		add_child(_pump)
	_chamber_side = String(interlock().get("start_side", "habitat"))
	_built = true
	_apply_state()
	return {"accepted": true, "placements": layout.placements.size(), "roles": nodes.keys()}

func _tint(node: Node3D, prefix: String, colour: Color) -> void:
	for slot in surfaces_named(node, prefix):
		var material := (slot.material as StandardMaterial3D).duplicate() as StandardMaterial3D
		material.albedo_color = colour
		(slot.mesh as MeshInstance3D).set_surface_override_material(slot.surface, material)

func _screen_label(panel: Node3D) -> Label3D:
	var sockets: Dictionary = piece("EN_Airlock_InterlockPanel").sockets
	var label := Label3D.new()
	label.position = Vector3(sockets.screen_centre[0], sockets.screen_centre[1], float(sockets.screen_centre[2]) - 0.004)
	label.rotation_degrees = Vector3(0, 180, 0)
	label.font_size = 54
	label.outline_size = 6
	label.pixel_size = 0.0008
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.width = float(sockets.screen_size[0]) / label.pixel_size
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	panel.add_child(label)
	return label

# ----------------------------------------------------------------------------------------------- interlock

## The words on the panel beside a hatch ("inner" or "outer"): one of the three states in airlock.json.
func state_text(which: String = "inner") -> String:
	if _cycling:
		return "EQUALISING"
	return "SAFE TO OPEN" if _chamber_side == HATCH_SIDE.get(which, "") else "SEALED"

## Which side the chamber's pressure currently matches ("habitat" or "surface").
func chamber_side() -> String:
	return _chamber_side

func is_cycling() -> bool:
	return _cycling

func is_hatch_open(which: String) -> bool:
	return bool(_hatch_open.get(which, false))

func is_lid_open(which: String) -> bool:
	return bool(_lid_open.get(which, false))

## Asks the interlock to equalise the chamber to a side. Refused while either hatch is open; a repeat of the running
## request is accepted as a duplicate (no restart); a request for the side the chamber already matches is a no-op.
func request_cycle(side: String) -> Dictionary:
	if not (side in interlock().sides):
		return {"accepted": false, "reason": "Unknown side."}
	if _hatch_open.inner or _hatch_open.outer:
		return {"accepted": false, "reason": "Close both hatches before cycling."}
	if _cycling:
		if _target_side == side:
			return {"accepted": true, "duplicate": true, "seconds_left": _equalising_left}
		return {"accepted": false, "reason": "A cycle to the other side is already running."}
	if side == _chamber_side:
		return {"accepted": true, "duplicate": true, "seconds_left": 0.0}
	_target_side = side
	_equalising_left = float(interlock().equalise_seconds)
	_cycling = true
	if _pump != null:
		_pump.play()
	_apply_state()
	return {"accepted": true, "seconds_left": _equalising_left}

## Advances the running cycle by game seconds (called from _process; tests and a paused game call it directly).
func advance(seconds: float) -> void:
	if not _cycling:
		return
	_equalising_left = maxf(0.0, _equalising_left - seconds)
	if _equalising_left > 0.0:
		return
	_cycling = false
	_chamber_side = _target_side
	_target_side = ""
	if _pump != null:
		_pump.stop()
	_apply_state()
	cycle_finished.emit(_chamber_side)

func _process(delta: float) -> void:
	advance(delta)

## Opens or closes a hatch ("inner" or "outer"). A hatch opens only when its panel reads SAFE TO OPEN and the other
## hatch is closed; closing is always allowed. Repeating the current position is a duplicate, not a change.
func set_hatch(which: String, open: bool) -> Dictionary:
	if not HATCH_SIDE.has(which):
		return {"accepted": false, "reason": "Unknown hatch."}
	if open == _hatch_open[which]:
		return {"accepted": true, "duplicate": true}
	if open:
		if state_text(which) != "SAFE TO OPEN":
			return {"accepted": false, "reason": "The chamber is not equalised to this side (%s)." % state_text(which)}
		for other in HATCH_SIDE:
			if other != which and _hatch_open[other]:
				return {"accepted": false, "reason": "Only one hatch may be open at a time."}
	_hatch_open[which] = open
	if nodes.has(HATCH_ROLE[which]):
		Kit.set_hatch_open(nodes[HATCH_ROLE[which]], 1.0 if open else 0.0)
	hatch_changed.emit(which, open)
	return {"accepted": true}

## Opens or closes a pass-through lid ("LidA" room side, "LidB" far side); only one lid may be open at a time.
func set_lid(which: String, open: bool) -> Dictionary:
	if not _lid_open.has(which):
		return {"accepted": false, "reason": "Unknown lid."}
	if open == _lid_open[which]:
		return {"accepted": true, "duplicate": true}
	if open:
		for other in _lid_open:
			if other != which and _lid_open[other]:
				return {"accepted": false, "reason": "Close the other lid first: the pass-through stays sealed."}
	_apply_lid(which, open)
	return {"accepted": true}

func _apply_lid(which: String, open: bool) -> void:
	_lid_open[which] = open
	if nodes.has("pass_through"):
		var angle := float(piece("EN_Airlock_PassThrough").sockets.lids[which].open_rotation_deg_y)
		for leaf in (nodes.pass_through as Node3D).find_children(which, "Node3D", true, false):
			(leaf as Node3D).rotation_degrees.y = angle if open else 0.0
		_set_lamp(nodes.pass_through, "LampSafe", not (_lid_open.LidA or _lid_open.LidB))

## Everything the room owner must save: chamber side, running cycle, hatches and lids.
func snapshot() -> Dictionary:
	return {"chamber_side": _chamber_side, "cycling": _cycling, "target_side": _target_side,
			"equalising_left": _equalising_left, "hatches": _hatch_open.duplicate(), "lids": _lid_open.duplicate()}

## Restores a snapshot onto a built airlock (leaves, lamps, labels and the pump follow).
func restore(data: Dictionary) -> void:
	_chamber_side = String(data.get("chamber_side", _chamber_side))
	_cycling = bool(data.get("cycling", false))
	_target_side = String(data.get("target_side", ""))
	_equalising_left = float(data.get("equalising_left", 0.0))
	for which in HATCH_SIDE:
		_hatch_open[which] = bool(data.get("hatches", {}).get(which, false))
		if nodes.has(HATCH_ROLE[which]):
			Kit.set_hatch_open(nodes[HATCH_ROLE[which]], 1.0 if _hatch_open[which] else 0.0)
	for which in _lid_open:
		_apply_lid(which, false)
	for which in _lid_open:
		if bool(data.get("lids", {}).get(which, false)):
			_apply_lid(which, true)
	if _pump != null:
		if _cycling and not _pump.playing:
			_pump.play()
		elif not _cycling and _pump.playing:
			_pump.stop()
	_apply_state()

func _apply_state() -> void:
	for panel_role in PANEL_HATCH:
		if not nodes.has(panel_role):
			continue
		var which: String = PANEL_HATCH[panel_role]
		var text := state_text(which)
		var panel: Node3D = nodes[panel_role]
		var lamps: Dictionary = piece("EN_Airlock_InterlockPanel").sockets.lamps
		for state in lamps:
			_set_lamp(panel, String(lamps[state]), state == text)
		if _labels.has(panel_role):
			var label: Label3D = _labels[panel_role]
			if label.text != text:
				label.text = text
				label.modulate = STATE_COLOUR[text]
				state_changed.emit(which, text)
		for slot in Kit.screen_surfaces(panel):
			var screen := (slot.mesh as MeshInstance3D).get_active_material(slot.surface) as StandardMaterial3D
			if screen == null:
				continue
			var tinted := screen.duplicate() as StandardMaterial3D
			tinted.emission_enabled = true
			tinted.emission = STATE_COLOUR[text] * 0.18
			tinted.emission_energy_multiplier = 1.0
			(slot.mesh as MeshInstance3D).set_surface_override_material(slot.surface, tinted)

func _set_lamp(node: Node3D, material_name: String, lit: bool) -> void:
	for slot in surfaces_named(node, material_name):
		var material := (slot.material as StandardMaterial3D).duplicate() as StandardMaterial3D
		material.emission_enabled = true
		material.emission_energy_multiplier = 4.0 if lit else 0.12
		(slot.mesh as MeshInstance3D).set_surface_override_material(slot.surface, material)
