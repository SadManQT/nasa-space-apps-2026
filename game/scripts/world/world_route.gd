extends RefCounted
class_name WorldRoute

const RoomContract = preload("res://scripts/world/room_contract.gd")
const NavigationContract = preload("res://scripts/navigation/route_navigation.gd")
const RosterContract = preload("res://scripts/companions/companion_roster.gd")

signal route_changed(snapshot: Dictionary)

var _director: RefCounted
var _current_room := "LOC-01"
var _current_scene := "EX-CH01-S01"
var _boundaries := {}
var _roster := {}
var _history: Array = []
var _last_viewpoint_cut := {}

func _init(director: RefCounted = null) -> void:
	_director = director
	for boundary_id in NavigationContract.boundary_ids():
		_boundaries[boundary_id] = NavigationContract.default_boundary_state(String(boundary_id))
	_roster = RosterContract.scene_roster(_current_scene)

func current_room_id() -> String:
	return _current_room

func current_scene_id() -> String:
	return _current_scene

func room_contract(room_id: String = "") -> Dictionary:
	return RoomContract.room(_current_room if room_id.is_empty() else room_id)

func boundary_state(boundary_id: String) -> Dictionary:
	return (_boundaries.get(boundary_id, {}) as Dictionary).duplicate(true)

func roster() -> Dictionary:
	return _roster.duplicate(true)

func history() -> Array:
	return _history.duplicate(true)

func snapshot() -> Dictionary:
	return {
		"schema_version": 1,
		"current_room_id": _current_room,
		"current_scene_id": _current_scene,
		"boundaries": _boundaries.duplicate(true),
		"roster": _roster.duplicate(true),
		"history": _history.duplicate(true),
		"last_viewpoint_cut": _last_viewpoint_cut.duplicate(true),
	}

func restore(snapshot_data: Dictionary) -> Dictionary:
	if not snapshot_data is Dictionary:
		return {"accepted": false, "reason": "World route snapshot must be a primitive Dictionary."}
	var room_id := String(snapshot_data.get("current_room_id", ""))
	if RoomContract.room(room_id).is_empty():
		return {"accepted": false, "reason": "World route snapshot names an unknown room."}
	var roster_value = snapshot_data.get("roster", {})
	if not roster_value is Dictionary or not bool(RosterContract.validate_roster(roster_value).get("valid", false)):
		return {"accepted": false, "reason": "World route snapshot has an invalid physical roster."}
	_current_room = room_id
	_current_scene = String(snapshot_data.get("current_scene_id", "EX-CH01-S01"))
	_boundaries = snapshot_data.get("boundaries", {}).duplicate(true)
	_roster = roster_value.duplicate(true)
	_history = snapshot_data.get("history", []).duplicate(true)
	_last_viewpoint_cut = snapshot_data.get("last_viewpoint_cut", {}).duplicate(true)
	_emit_changed()
	return {"accepted": true, "reason": "World route restored without teleporting an actor."}

func transition_to(room_id: String, context: Dictionary = {}) -> Dictionary:
	if RoomContract.room(room_id).is_empty():
		return {"accepted": false, "reason": "Unknown room contract: " + room_id}
	var result := NavigationContract.can_traverse(_current_room, room_id, _boundaries, context)
	if not bool(result.get("accepted", false)):
		return result
	var previous := _current_room
	_current_room = room_id
	if String(result.get("mode", "")) == "authored_viewpoint_cut":
		_last_viewpoint_cut = {"from": previous, "to": room_id, "scene_id": String(context.get("scene_id", _current_scene)), "label": String(context.get("label", "AUTHORED VIEWPOINT"))}
		_history.append({"from": previous, "to": room_id, "mode": "authored_viewpoint_cut", "scene_id": String(context.get("scene_id", _current_scene))})
	else:
		_history.append({"from": previous, "to": room_id, "mode": "physical_boundary", "boundary_id": String(result.get("boundary_id", ""))})
	_emit_changed()
	return result

func set_scene(scene_id: String, context: Dictionary = {}) -> Dictionary:
	var target_room := RoomContract.room_for_scene(scene_id)
	var transition_context := context.duplicate(true)
	transition_context["scene_id"] = scene_id
	if target_room != _current_room and not transition_context.has("authored_viewpoint_cut"):
		transition_context["authored_viewpoint_cut"] = true
		transition_context["label"] = "AUTHORED SCENE VIEWPOINT"
	var result := transition_to(target_room, transition_context)
	if not bool(result.get("accepted", false)):
		return result
	_current_scene = scene_id
	_roster = RosterContract.scene_roster(scene_id)
	var valid := RosterContract.validate_roster(_roster)
	if not bool(valid.get("valid", false)):
		return {"accepted": false, "reason": "Scene roster failed validation: " + "; ".join(valid.get("errors", []))}
	_emit_changed()
	return {"accepted": true, "room_id": target_room, "scene_id": scene_id, "roster": _roster.duplicate(true), "transition": result}

func set_boundary_state(boundary_id: String, changes: Dictionary) -> Dictionary:
	if not _boundaries.has(boundary_id):
		return {"accepted": false, "reason": "Unknown pressure boundary: " + boundary_id}
	if not changes is Dictionary:
		return {"accepted": false, "reason": "Boundary changes must be primitive."}
	var next: Dictionary = _boundaries[boundary_id].duplicate(true)
	for key in changes.keys():
		if key in ["open", "airlock_ready", "suit_check", "exposure_lock", "chamber_safe", "pressure_state", "exposure_clear"]:
			next[key] = changes[key]
	_boundaries[boundary_id] = next
	_emit_changed()
	return {"accepted": true, "boundary_id": boundary_id, "state": next.duplicate(true)}

func prepare_airlock(suit_check: bool, exposure_clear: bool = true) -> Dictionary:
	var boundary := boundary_state("airlock_exterior")
	if boundary.is_empty():
		return {"accepted": false, "reason": "Exterior airlock contract is missing."}
	if not suit_check:
		return {"accepted": false, "reason": "Suit and exterior instrument check is required before cycling the airlock."}
	return set_boundary_state("airlock_exterior", {"airlock_ready": true, "suit_check": true, "exposure_clear": exposure_clear, "open": true})

func close_airlock() -> Dictionary:
	return set_boundary_state("airlock_exterior", {"open": false, "airlock_ready": false})

func set_safe_room_exposure_lock(is_locked: bool) -> Dictionary:
	return set_boundary_state("safe_room_exposure_lock", {"exposure_lock": is_locked, "open": not is_locked})

func open_garden_shutter(chamber_safe: bool) -> Dictionary:
	if not chamber_safe:
		return {"accepted": false, "reason": "The chamber must report safe pressure and conditions before the shutter opens."}
	return set_boundary_state("garden_viewing_shutter", {"chamber_safe": true, "open": true, "pressure_state": "pressurised"})

func can_switch(current_actor: String, target_actor: String) -> Dictionary:
	return RosterContract.can_switch(_roster, current_actor, target_actor)

func can_traverse_to(room_id: String, context: Dictionary = {}) -> Dictionary:
	return NavigationContract.can_traverse(_current_room, room_id, _boundaries, context)

func _emit_changed() -> void:
	route_changed.emit(snapshot())
