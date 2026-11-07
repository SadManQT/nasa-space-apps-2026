## M3-4A: the LOC-08 rover garage assembled from garage.json, the layout Sadman approved on 7 Nov 2026 ("Approve all
## 12", production/concept/chapter4_v1/README.md): a pressurised ready room on its sintered plinth (deck +1.40 m), the
## unpressurised rover bay with the EVA porch, VH_Rover docked at the telescoping tunnel, the regolith berm outside.
## Every piece is placed through habitat_kit.gd, which reads garage.json as an extension catalogue. This script owns the
## asset layout, the moving parts (dock collar and hatch, rover door, cargo-lock doors, relief-locker doors) and the
## practical lights; M3-4R owns the room's campaign hookup, navigation, staging and the dock's SEALED / EQUALISING /
## SAFE TO OPEN cycle (garage.json "dock").
extends Node3D

const Kit = preload("res://assets/environment/kit/habitat_kit.gd")
const CATALOG_PATH := "res://assets/environment/EN_Garage/garage.json"
const READY_LIGHT := Color(1.0, 0.82, 0.66)  # 3,500 K practicals in the ready room (ART_BIBLE section 4)
const BAY_LIGHT := Color(0.93, 0.95, 1.0)  # 5,000 K LED floods in the bay

static var _catalog: Dictionary = {}

@export var build_on_ready := true
@export var with_rover := true
@export var with_lights := true
@export var with_berm := true

var nodes: Dictionary = {}  ## role -> placed piece (docking_port, cargo_lock, rover_door, route_board, departure_a, ...)
var rover: Node3D
var _lock_open := {"InnerDoor": false, "OuterDoor": false}

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
	set_docked(rover != null)
	return nodes

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

## Extends the dock collar to the docked rover's hatch (true) or retracts it into its sleeve (false).
func set_docked(docked: bool) -> void:
	if nodes.has("docking_port"):
		Kit.set_part_open(nodes.docking_port, "DockCollar", 0.0 if docked else 1.0)

## Swings the ready-room dock hatch open (into the room) or shut.
func set_dock_hatch_open(open: bool) -> void:
	if nodes.has("docking_port"):
		Kit.set_part_open(nodes.docking_port, "HatchLeaf", 1.0 if open else 0.0)

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
