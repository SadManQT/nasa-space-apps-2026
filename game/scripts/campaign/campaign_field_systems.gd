extends RefCounted
class_name CampaignFieldSystems

const Network = preload("res://scripts/network/lunar_network.gd")
const Rover = preload("res://scripts/rover/lunar_rover.gd")
const Hazards = preload("res://scripts/hazards/lunar_hazards.gd")
const Inventory = preload("res://scripts/payload/payload_inventory.gd")
const Vehicle = preload("res://scripts/rover/rover_vehicle.gd")
const EVA_FIELDS = ["oxygen", "power", "cooling", "indoor", "payload_mass_kg", "payload_tall", "headlamp_on", "slip_count", "slip_time_cost_s", "payload_scuffs"]
const ROVER_FIELDS = ["battery", "elapsed_hours", "distance_driven_m", "planned_route_id", "planned_waypoints", "planned_one_way_distance_m", "planned_one_way_energy", "headlights_on", "camera_view"]
const HAZARD_FIELDS = ["equipment_temp_c", "accumulated_outside_dose", "shelter_run_elapsed_s", "secured_items", "annex_isolated_for_aftershock", "genuine_flashes_confirmed", "artifacts_rejected", "panel_dust_cleared", "whipple_spur_patched"]

var network: RefCounted = Network.new()
var rover: RefCounted = Rover.new()
var hazards: RefCounted = Hazards.new()
var inventory: RefCounted = Inventory.new(8, ["sled", "trailer"])
var vehicle: CharacterBody3D
var _runtime: Node
var _room_id := ""
var _chapter := 0
var _structures: Node3D
var _placed_rooms := {}
var _supplies_used := {}
var _carried_supplies := {}
var _pending_vehicle_position: Array = []

func _init(runtime: Node) -> void:
	_runtime = runtime

func restore(state: Dictionary) -> void:
	network.from_dict(state.get("network", {}))
	_chapter = clampi(int(state.get("chapter", 0)), 0, 8)
	rover.apply_preset("ch08_relay" if _chapter >= 8 else "ch04_survey", _runtime.director.snapshot().get("upgrades", {}))
	_restore_fields(rover, state.get("rover", {}), ROVER_FIELDS)
	_restore_fields(hazards, state.get("hazards", {}), HAZARD_FIELDS)
	_restore_fields(_runtime.eva_suit, state.get("eva_suit", {}), EVA_FIELDS)
	_runtime._last_eva_room_id = String(state.get("room_id", ""))
	_room_id = String(state.get("room_id", ""))
	_placed_rooms = state.get("placed_rooms", {}).duplicate(true)
	_supplies_used = state.get("supplies_used", {}).duplicate(true)
	_carried_supplies = state.get("carried_supplies", {}).duplicate(true)
	for kind in _carried_supplies:
		if Network.STRUCTURE_TYPES.has(kind):
			var id := String(_carried_supplies[kind])
			inventory.register_payload(Network.make_payload_definition(id, kind, "deploy_" + kind))
			inventory.pickup(id, "hands")
	var pos = state.get("vehicle_position", [])
	if pos is Array and pos.size() == 3:
		_pending_vehicle_position = pos

func snapshot() -> Dictionary:
	var pos: Array = []
	if is_instance_valid(vehicle):
		pos = [vehicle.global_position.x, vehicle.global_position.y, vehicle.global_position.z]
	return {"schema_version": 1, "chapter": _runtime._chapter_number(), "room_id": _room_id,
		"eva_suit": _fields(_runtime.eva_suit, EVA_FIELDS), "rover": _fields(rover, ROVER_FIELDS),
		"hazards": _fields(hazards, HAZARD_FIELDS), "network": network.to_dict(),
		"placed_rooms": _placed_rooms.duplicate(true), "supplies_used": _supplies_used.duplicate(true),
		"carried_supplies": _carried_supplies.duplicate(true), "vehicle_position": pos}

func bind_scene() -> void:
	if _runtime._room == null or _runtime._player == null:
		return
	var chapter: int = _runtime._chapter_number()
	var room: String = _runtime._room.room_id
	var chapter_changed := chapter != _chapter
	if chapter_changed:
		if chapter >= 4:
			rover.apply_preset("ch08_relay" if chapter >= 8 else "ch04_survey", _runtime.director.snapshot().get("upgrades", {}))
		_chapter = chapter
	var mode := String(_runtime.director.snapshot().get("accessibility", {}).get("assist_mode", "Cadet"))
	rover.set_assist_mode(mode)
	hazards.set_modes(mode, bool(_runtime.director.snapshot().get("accessibility", {}).get("family_mode", false)))
	if chapter >= 4 and (not _runtime.eva_suit.indoor or room == "LOC-08"):
		if not is_instance_valid(vehicle):
			vehicle = Vehicle.new()
			vehicle.name = "ExpeditionRover"
			_runtime.add_child(vehicle)
			vehicle.bind_model(rover, _terrain_field())
			vehicle.global_position = _runtime._player.global_position + Vector3(3.5, 0.2, 0.0)
			if not _pending_vehicle_position.is_empty() and room == _room_id:
				vehicle.global_position = Vector3(float(_pending_vehicle_position[0]), float(_pending_vehicle_position[1]), float(_pending_vehicle_position[2]))
			_pending_vehicle_position = []
		elif room != _room_id:
			if rover.aboard:
				vehicle.exit_vehicle()
			vehicle.global_position = _runtime._player.global_position + Vector3(3.5, 0.2, 0.0)
		vehicle.field = _terrain_field()
		vehicle.visible = true
	elif is_instance_valid(vehicle):
		if rover.aboard:
			vehicle.exit_vehicle()
		vehicle.visible = false
	_room_id = room
	if is_instance_valid(_structures):
		_structures.queue_free()
	_structures = Node3D.new()
	_structures.name = "PlayerBuiltNetwork"
	_runtime._room.add_child(_structures)
	for record in network.all_placed():
		if String(_placed_rooms.get(String(record.id), "")) == room:
			_render_structure(record)
	sync_route()

func sync_route() -> void:
	if _runtime.route == null:
		return
	var snap: Dictionary = _runtime.director.snapshot()
	var receipts: Dictionary = _runtime.route.snapshot().get("ledger", {}).get("receipts", {})
	for index in range(1, 4):
		if receipts.has("p07_place_beacon_%d" % index):
			network.record_ch04_beacons(index)
	for hop in snap.get("route", {}).get("local_hops", []):
		network.activate_hop(String(hop), _runtime.director)
	if String(snap.get("route", {}).get("earth_leg", "")) == "verified" and network.is_local_chain_complete():
		network.verify_finale_voice_network("L2", "E3", "ALO42")

func step(delta: float) -> void:
	if _runtime.eva_suit == null:
		return
	var suit = _runtime.eva_suit
	if _runtime.progression != null:
		suit.life_support_rank = _runtime.progression.skill_rank("life_support")
		suit.handling_rank = _runtime.progression.skill_rank("handling")
		suit.observation_rank = _runtime.progression.skill_rank("observation")
		network.navigation_rank = _runtime.progression.skill_rank("navigation")
		suit.payload_mass_kg = inventory.personal_mass() + _runtime.progression.equipped_mass_kg()
	if is_instance_valid(vehicle):
		vehicle.controls_enabled = not _runtime._ui_paused and not _runtime.is_cutscene_active() and vehicle.visible
		vehicle.in_shadow = _runtime._is_scene_in_cold_shadow()
	if _runtime._ui_paused or _runtime.is_cutscene_active():
		return
	if _chapter == 4 or _chapter == 8:
		hazards.step_cold_shadow(_runtime._is_scene_in_cold_shadow(), delta / 60.0, rover.heater_upgrade, _chapter)
	elif _chapter == 7:
		var scene: String = _runtime.route.current_scene_id()
		if scene >= "EX-CH07-S05" and scene <= "EX-CH07-S09":
			var snap: Dictionary = _runtime.director.snapshot()
			var res: Dictionary = snap.get("resources", {})
			var chosen: Array = snap.get("upgrades", {}).get("choices", {}).values()
			hazards.step_solar_storm_shelter_run(delta, _room_id == "LOC-04", int(res.get("W", 0)), int(res.get("K", 0)), int(chosen.has("moon_dirt_shelter")), chosen.has("storm_early_warning"))

func command(verb: String, payload: Dictionary) -> Dictionary:
	if _runtime._player == null:
		return {"accepted": false, "reason": "The field is not ready."}
	match verb:
		"board_rover":
			if not is_instance_valid(vehicle) or not vehicle.visible or _runtime._player.global_position.distance_to(vehicle.global_position) > 5.0:
				return {"accepted": false, "reason": "Walk up to the rover to board."}
			return vehicle.board(_runtime._player)
		"exit_rover":
			return vehicle.exit_vehicle() if is_instance_valid(vehicle) else {"accepted": false, "reason": "No rover here."}
		"toggle_rover_camera":
			if not is_instance_valid(vehicle) or not rover.aboard:
				return {"accepted": false, "reason": "Board the rover first."}
			return {"accepted": true, "view": vehicle.toggle_camera_view()}
		"toggle_headlights":
			return {"accepted": true, "headlights_on": rover.toggle_headlights()}
		"pickup_supply":
			return _pickup_supply(String(payload.get("kind", "marker")))
		"place_structure":
			return _place_structure(String(payload.get("kind", "marker")))
		"secure_item":
			if _chapter != 3:
				return {"accepted": false, "reason": "No moonquake securing task in this chapter."}
			return hazards.secure_quake_item(String(payload.get("item_id", "")))
	return {"accepted": false, "reason": "Unknown field command."}

func _pickup_supply(kind: String) -> Dictionary:
	if not Network.STRUCTURE_TYPES.has(kind) or _chapter < 4:
		return {"accepted": false, "reason": "Reach the survey sortie before collecting field supplies."}
	if _room_id != "LOC-08" and (not is_instance_valid(vehicle) or _runtime._player.global_position.distance_to(vehicle.global_position) > 5.0):
		return {"accepted": false, "reason": "Collect carried supplies from the garage or rover cargo bay."}
	if _carried_supplies.has(kind):
		return {"accepted": false, "reason": "Place the item you are already carrying first."}
	var used := int(_supplies_used.get(kind, 0))
	if used >= int(Network.STRUCTURE_TYPES[kind].get("base_cap", 4)):
		return {"accepted": false, "reason": "That field supply stock is used up."}
	var id := "FIELD-%s-%d" % [kind, used + 1]
	var registered: Dictionary = inventory.register_payload(Network.make_payload_definition(id, kind, "deploy_" + kind))
	if not bool(registered.get("accepted", false)):
		return registered
	var picked: Dictionary = inventory.pickup(id, "hands")
	if bool(picked.get("accepted", false)):
		_carried_supplies[kind] = id
		_supplies_used[kind] = used + 1
	return picked

func _place_structure(kind: String) -> Dictionary:
	if not _carried_supplies.has(kind) or _runtime.eva_suit.indoor or rover.aboard:
		return {"accepted": false, "reason": "Carry the supply outside and leave the rover before placing it."}
	var id := String(_carried_supplies[kind])
	var pos: Vector3 = _runtime._player.global_position
	var result: Dictionary = network.place_from_payload(id, kind, "deploy_" + kind, [pos.x, pos.z], _chapter, "", inventory, id)
	if bool(result.get("accepted", false)):
		_carried_supplies.erase(kind)
		_placed_rooms[id] = _room_id
		_render_structure(result.item)
	return result

func _render_structure(record: Dictionary) -> void:
	if not is_instance_valid(_structures):
		return
	var node := MeshInstance3D.new()
	node.name = String(record.id)
	var pole := CylinderMesh.new()
	pole.top_radius = 0.05
	pole.bottom_radius = 0.07
	pole.height = 1.2
	node.mesh = pole
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("5FCED4") if String(record.kind) != "path_light" else Color("FFD66A")
	node.material_override = material
	_structures.add_child(node)
	var position_m: Array = record.get("position_m", [0.0, 0.0])
	var x := float(position_m[0])
	var z := float(position_m[1])
	var y: float = float(_runtime._sample_world_floor_height(x, z, _runtime._player.global_position.y))
	node.global_position = Vector3(x, y + 0.6, z)
	if String(record.kind) == "path_light":
		var lamp := OmniLight3D.new()
		lamp.omni_range = 5.0
		lamp.light_energy = 0.7
		node.add_child(lamp)

func _terrain_field() -> TerrainHeightfield:
	var terrain = _runtime._terrain
	return terrain.stream.field if terrain != null and terrain.get("stream") != null and terrain.stream.get("field") != null else null

static func _fields(object: Object, keys: Array) -> Dictionary:
	var result := {}
	for key in keys:
		result[key] = object.get(key)
	return result

static func _restore_fields(object: Object, values: Dictionary, keys: Array) -> void:
	for key in keys:
		if not values.has(key):
			continue
		var current = object.get(key)
		var value = values[key]
		if typeof(value) == typeof(current):
			if value is float and not is_finite(value):
				continue
			object.set(key, value)
		elif (value is int or value is float) and (current is int or current is float) and is_finite(float(value)):
			object.set(key, int(value) if current is int else float(value))
