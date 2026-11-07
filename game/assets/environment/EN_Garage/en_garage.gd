## M3-4A: the LOC-08 rover garage assembled from garage.json, the layout Sadman approved on 7 Nov 2026 ("Approve all
## 12", production/concept/chapter4_v1/README.md): a pressurised ready room on its sintered plinth (deck +1.40 m), the
## unpressurised rover bay with the EVA porch, VH_Rover docked at the telescoping tunnel, the regolith berm outside.
## Every piece is placed through habitat_kit.gd, which reads garage.json as an extension catalogue. This script owns the
## asset layout, the moving parts (dock collar and hatch, rover door, cargo-lock doors, relief-locker doors) and the
## practical lights; M3-4R owns the room's campaign hookup, navigation and staging, and added the dock's SEALED /
## EQUALISING / SAFE TO OPEN cycle (garage.json "dock"): the tunnel between the dock hatch and the rover's hatch is
## equalised to the cabin ("habitat") or pumped down ("vacuum"); the pump hum runs only while EQUALISING; the dock
## hatch opens only on SAFE TO OPEN; the panel shows the word, its lamp and, while it runs, the labelled time card.
extends Node3D

const Kit = preload("res://assets/environment/kit/habitat_kit.gd")
const CATALOG_PATH := "res://assets/environment/EN_Garage/garage.json"
const READY_LIGHT := Color(1.0, 0.82, 0.66)  # 3,500 K practicals in the ready room (ART_BIBLE section 4)
const BAY_LIGHT := Color(0.93, 0.95, 1.0)  # 5,000 K LED floods in the bay
const STATE_COLOUR := {"SEALED": Color(1.0, 0.22, 0.14), "EQUALISING": Color(1.0, 0.70, 0.18), "SAFE TO OPEN": Color(0.35, 1.0, 0.45)}
const STATE_LAMP := {"SEALED": "LampSealed", "EQUALISING": "LampEqualising", "SAFE TO OPEN": "LampSafe"}

## The dock panel's words changed (SEALED / EQUALISING / SAFE TO OPEN).
signal dock_state_changed(text: String)
## A requested tunnel cycle finished: the tunnel now matches this side ("habitat" or "vacuum").
signal dock_cycle_finished(side: String)

static var _catalog: Dictionary = {}

@export var build_on_ready := true
@export var with_rover := true
@export var with_lights := true
@export var with_berm := true

var nodes: Dictionary = {}  ## role -> placed piece (docking_port, cargo_lock, rover_door, route_board, departure_a, ...)
var rover: Node3D
var _lock_open := {"InnerDoor": false, "OuterDoor": false}
var _docked := false
var _hatch_open := false
var _tunnel_side := "habitat"
var _target_side := ""
var _cycling := false
var _equalising_left := 0.0
var _dock_label: Label3D
var _time_card: Label3D
var _pump: AudioStreamPlayer3D

## The whole garage catalogue: pieces, layout, dock rules, site and rover placement.
static func catalog() -> Dictionary:
	if _catalog.is_empty():
		_catalog = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	return _catalog

## The approved 12 x 9 m layout: placements (finished-floor positions), anchors, rover, connections.
static func layout() -> Dictionary:
	return catalog().layout

## An anchor of the layout (player, amara_handover, porch_eva...) in the garage's frame.
static func anchor(anchor_name: String) -> Vector3:
	var a: Array = layout().anchors.get(anchor_name, [0.0, 0.0, 0.0])
	return Vector3(a[0], a[1], a[2])

func _ready() -> void:
	if build_on_ready and nodes.is_empty():
		build()

## Places every piece, the docked rover and the lights; returns the role map.
func build() -> Dictionary:
	for p in layout().placements:
		var id := String(p.piece)
		if id == "EN_Garage_Berm" and not with_berm:
			continue
		var pos: Array = p.position
		var node := Kit.place(self, id, Vector3(pos[0], pos[1], pos[2]), float(p.yaw))
		if node != null and String(p.get("role", "")) != "":
			nodes[String(p.role)] = node
	if with_rover:
		var packed := load(String(catalog().rover.asset)) as PackedScene
		if packed != null:
			rover = packed.instantiate() as Node3D
			rover.name = "VH_Rover"
			var c: Array = layout().rover.centre
			rover.position = Vector3(c[0], c[1], c[2])
			rover.rotation_degrees.y = float(catalog().rover.yaw_degrees)
			add_child(rover)
	if with_lights:
		_add_lights()
	_tunnel_side = String(catalog().dock.get("start_side", "habitat"))
	_build_dock_panel()
	set_docked(rover != null)
	return nodes

## The dock rules from the data file: states, sides, equalise_seconds (on screen), real_seconds, pump_sfx, time_card.
static func dock() -> Dictionary:
	return catalog().dock

func _build_dock_panel() -> void:
	if not nodes.has("docking_port"):
		return
	var port: Node3D = nodes.docking_port
	var frame := Kit.surface_frame(port, "Screen")
	if not frame.is_empty():
		_dock_label = _panel_label(port, frame, 0.0, 44, Vector2(frame.size.x, frame.size.y * 0.6))
		_time_card = _panel_label(port, frame, -frame.size.y * 0.36, 20, Vector2(frame.size.x, frame.size.y * 0.3))
	var sfx := String(dock().get("pump_sfx", ""))
	if sfx != "" and ResourceLoader.exists(sfx):
		_pump = AudioStreamPlayer3D.new()
		_pump.name = "DockPump"
		_pump.stream = load(sfx)
		_pump.unit_size = 4.0
		_pump.position = port.position + Vector3(0.0, 2.0, -0.6)  # in the ready room: no airborne sound in the vacuum bay
		add_child(_pump)

func _panel_label(port: Node3D, frame: Dictionary, drop: float, font: int, area: Vector2) -> Label3D:
	var label := Label3D.new()
	label.name = "DockWords" if drop == 0.0 else "DockTimeCard"
	label.pixel_size = 0.0006
	label.font_size = font
	label.outline_size = 4
	label.double_sided = false
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.width = area.x / label.pixel_size
	var normal: Vector3 = frame.normal
	label.transform = Transform3D(Basis(frame.right, frame.up, normal), frame.centre + normal * 0.003 + frame.up * drop)
	port.add_child(label)
	return label

func _add_lights() -> void:
	var deck := float(layout().deck_y)
	for x in [1.5, 4.5, 7.5, 10.5]:
		var lamp := OmniLight3D.new()
		lamp.name = "ReadyLight"
		lamp.light_color = READY_LIGHT
		lamp.light_energy = 1.4
		lamp.omni_range = 4.5
		lamp.shadow_enabled = true
		lamp.position = Vector3(x, deck + 2.35, 1.5)
		add_child(lamp)
	var bay_z: Array = layout().bay.z
	var mid := (float(bay_z[0]) + float(bay_z[1])) / 2.0
	for x in [1.0, 3.0, 5.0, 7.0, 9.0, 11.0]:
		var flood := SpotLight3D.new()
		flood.name = "BayFlood"
		flood.light_color = BAY_LIGHT
		flood.light_energy = 6.0
		flood.spot_range = 8.0
		flood.spot_angle = 62.0
		flood.shadow_enabled = true
		flood.position = Vector3(x, float(layout().bay_clear_height_m) - 0.6, mid)
		flood.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
		add_child(flood)

## Extends the dock collar to the docked rover's hatch (true) or retracts it into its sleeve (false). Undocking
## needs the hatch shut and leaves the retracted tunnel open to the bay's vacuum.
func set_docked(docked: bool) -> Dictionary:
	if not docked and _hatch_open:
		return {"accepted": false, "reason": "Close the dock hatch before the rover undocks."}
	_docked = docked
	if not docked:
		_cycling = false
		_tunnel_side = "vacuum"
	if nodes.has("docking_port"):
		Kit.set_part_open(nodes.docking_port, "DockCollar", 0.0 if docked else 1.0)
	_apply_dock()
	return {"accepted": true}

func is_docked() -> bool:
	return _docked

## The words on the dock panel: EQUALISING while the pump runs, SAFE TO OPEN when the docked tunnel holds cabin
## pressure, otherwise SEALED.
func dock_state() -> String:
	if _cycling:
		return "EQUALISING"
	return "SAFE TO OPEN" if _docked and _tunnel_side == "habitat" else "SEALED"

func tunnel_side() -> String:
	return _tunnel_side

func is_dock_hatch_open() -> bool:
	return _hatch_open

## The labelled time card while a cycle runs ("" otherwise): the real duration the on-screen cycle stands for.
func time_card() -> String:
	if not _cycling:
		return ""
	return String(dock().get("time_card", "")).replace("{action}", "EQUALISING" if _target_side == "habitat" else "PUMPING DOWN")

## Equalises the docked tunnel to "habitat" (before the hatch opens) or pumps it down to "vacuum" (before the rover
## leaves). Refused with the hatch open or no rover docked; a repeat of the running request is a duplicate.
func request_dock_cycle(side: String) -> Dictionary:
	if not side in dock().get("sides", ["habitat", "vacuum"]):
		return {"accepted": false, "reason": "Unknown side."}
	if not _docked:
		return {"accepted": false, "reason": "No rover is docked at the tunnel."}
	if _hatch_open:
		return {"accepted": false, "reason": "Close the dock hatch before cycling the tunnel."}
	if _cycling:
		if side == _target_side:
			return {"accepted": true, "duplicate": true, "seconds_left": _equalising_left}
		return {"accepted": false, "reason": "A cycle to the other side is already running."}
	if side == _tunnel_side:
		return {"accepted": true, "duplicate": true, "seconds_left": 0.0}
	_target_side = side
	_equalising_left = float(dock().get("equalise_seconds", 8.0))
	_cycling = true
	_apply_dock()
	return {"accepted": true, "seconds_left": _equalising_left, "time_card": time_card()}

## Advances a running tunnel cycle by game seconds (from _process; tests call it directly).
func advance(seconds: float) -> void:
	if not _cycling:
		return
	_equalising_left = maxf(0.0, _equalising_left - seconds)
	if _equalising_left > 0.0:
		return
	_cycling = false
	_tunnel_side = _target_side
	_target_side = ""
	_apply_dock()
	dock_cycle_finished.emit(_tunnel_side)

func _process(delta: float) -> void:
	advance(delta)

## Swings the ready-room dock hatch open (into the room) or shut. It opens only on SAFE TO OPEN; closing is always
## allowed.
func set_dock_hatch_open(open: bool) -> Dictionary:
	if open == _hatch_open:
		return {"accepted": true, "duplicate": true}
	if open and dock_state() != "SAFE TO OPEN":
		return {"accepted": false, "reason": "The tunnel is not at cabin pressure (%s)." % dock_state()}
	_hatch_open = open
	if nodes.has("docking_port"):
		Kit.set_part_open(nodes.docking_port, "HatchLeaf", 1.0 if open else 0.0)
	return {"accepted": true}

## Everything the room owner saves: docked, tunnel side, running cycle and the hatch.
func dock_snapshot() -> Dictionary:
	return {"docked": _docked, "tunnel_side": _tunnel_side, "cycling": _cycling, "target_side": _target_side,
			"equalising_left": _equalising_left, "hatch_open": _hatch_open}

func dock_restore(data: Dictionary) -> void:
	_hatch_open = false
	set_docked(bool(data.get("docked", _docked)))
	_tunnel_side = String(data.get("tunnel_side", _tunnel_side))
	_cycling = bool(data.get("cycling", false))
	_target_side = String(data.get("target_side", ""))
	_equalising_left = float(data.get("equalising_left", 0.0))
	_hatch_open = bool(data.get("hatch_open", false)) and dock_state() == "SAFE TO OPEN"
	if nodes.has("docking_port"):
		Kit.set_part_open(nodes.docking_port, "HatchLeaf", 1.0 if _hatch_open else 0.0)
	_apply_dock()

func _apply_dock() -> void:
	var text := dock_state()
	if _pump != null and is_inside_tree():
		if _cycling and not _pump.playing:
			_pump.play()
		elif not _cycling and _pump.playing:
			_pump.stop()
	if not nodes.has("docking_port"):
		return
	for state in STATE_LAMP:
		_set_lamp(nodes.docking_port, String(STATE_LAMP[state]), state == text)
	if _time_card != null:
		_time_card.text = time_card()
	if _dock_label != null and _dock_label.text != text:
		_dock_label.text = text
		_dock_label.modulate = STATE_COLOUR[text]
		dock_state_changed.emit(text)

func _set_lamp(node: Node3D, material_name: String, lit: bool) -> void:
	for mesh in node.find_children("*", "MeshInstance3D", true, false):
		var instance_mesh := mesh as MeshInstance3D
		if instance_mesh.mesh == null:
			continue
		for surface in instance_mesh.mesh.get_surface_count():
			var material := instance_mesh.mesh.surface_get_material(surface)
			if material is StandardMaterial3D and material.resource_name == material_name:
				var lamp := (material as StandardMaterial3D).duplicate() as StandardMaterial3D
				lamp.emission_enabled = true
				lamp.emission_energy_multiplier = 4.0 if lit else 0.12
				instance_mesh.set_surface_override_material(surface, lamp)

## Coils the rover door up into its drum (true) or lowers it (false).
func set_rover_door_open(open: bool) -> void:
	if nodes.has("rover_door"):
		Kit.set_part_open(nodes.rover_door, "DoorPanel", 1.0 if open else 0.0)

## Opens or shuts one cargo-lock door ("InnerDoor" room side, "OuterDoor" porch side); never both open at once
## (decision 5). Returns false when the request is refused.
func set_lock_door(which: String, open: bool) -> bool:
	if not _lock_open.has(which) or not nodes.has("cargo_lock"):
		return false
	var other := "OuterDoor" if which == "InnerDoor" else "InnerDoor"
	if open and bool(_lock_open[other]):
		return false
	_lock_open[which] = open
	Kit.set_part_open(nodes.cargo_lock, which, 1.0 if open else 0.0)
	return true

func is_lock_door_open(which: String) -> bool:
	return bool(_lock_open.get(which, false))

## Opens or shuts both relief-locker doors.
func set_relief_locker_open(open: bool) -> void:
	if nodes.has("relief_locker"):
		for door in ["DoorL", "DoorR"]:
			Kit.set_part_open(nodes.relief_locker, door, 1.0 if open else 0.0)
