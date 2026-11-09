extends RefCounted
class_name RouteNavigation

## Pure route and pressure-boundary checks. It never changes campaign
## resources; WorldRoute owns the small mutable location/door snapshot.

const INTERNAL := "internal"
const AIRLOCK := "airlock"
const SHUTTER := "shutter"
const EXPOSURE_LOCK := "exposure_lock"

const _BOUNDARIES := {
	"door_commons_service": {"from": "LOC-01", "to": "LOC-02", "kind": INTERNAL, "default_open": true},
	"door_commons_garden": {"from": "LOC-01", "to": "LOC-03", "kind": INTERNAL, "default_open": true},
	"door_commons_safe": {"from": "LOC-01", "to": "LOC-04", "kind": INTERNAL, "default_open": true},
	"door_commons_airlock": {"from": "LOC-01", "to": "LOC-05", "kind": INTERNAL, "default_open": true},
	"door_commons_garage": {"from": "LOC-01", "to": "LOC-08", "kind": INTERNAL, "default_open": true},
	"door_service_garden": {"from": "LOC-02", "to": "LOC-03", "kind": INTERNAL, "default_open": true},
	"door_service_safe": {"from": "LOC-02", "to": "LOC-04", "kind": INTERNAL, "default_open": true},
	"door_service_annex": {"from": "LOC-02", "to": "LOC-07", "kind": INTERNAL, "default_open": true},
	"airlock_exterior": {
		"from": "LOC-01",
		"to": "LOC-06",
		"kind": AIRLOCK,
		"default_open": false,
		"requires_airlock_cycle": true,
		"requires_suit_check": true,
		"requires_exposure_clear": true,
	},
	"annex_hatch": {
		"from": "LOC-07",
		"to": "LOC-07_COLD",
		"kind": AIRLOCK,
		"default_open": false,
		"requires_airlock_cycle": true,
		"requires_suit_check": true,
		"requires_exposure_clear": true,
	},
	"garage_dock_hatch": {
		"from": "LOC-08",
		"to": "ROVER_CABIN",
		"kind": AIRLOCK,
		"default_open": false,
		"requires_airlock_cycle": true,
	},
	"rover_bay_door": {
		"from": "LOC-08",
		"to": "LOC-06",
		"kind": SHUTTER,
		"default_open": false,
	},
	"garden_viewing_shutter": {
		"from": "LOC-03",
		"to": "GARDEN_CHAMBER",
		"kind": SHUTTER,
		"default_open": false,
		"requires_chamber_safe": true,
	},
	"safe_room_exposure_lock": {
		"from": "LOC-04",
		"to": "LOC-01",
		"kind": EXPOSURE_LOCK,
		"default_open": true,
		"requires_exposure_clear": true,
	},
}

static func boundary_ids() -> Array:
	return _BOUNDARIES.keys()

static func boundary(boundary_id: String) -> Dictionary:
	return (_BOUNDARIES.get(boundary_id, {}) as Dictionary).duplicate(true)

static func default_boundary_state(boundary_id: String) -> Dictionary:
	var definition := boundary(boundary_id)
	if definition.is_empty():
		return {}
	return {
		"boundary_id": boundary_id,
		"open": bool(definition.get("default_open", false)),
		"airlock_ready": false,
		"suit_check": false,
		"exposure_lock": false,
		"chamber_safe": false,
		"pressure_state": "pressurised",
	}

static func can_traverse(from_room: String, to_room: String, state: Dictionary = {}, context: Dictionary = {}) -> Dictionary:
	if from_room == to_room:
		return {"accepted": true, "mode": "same_room", "boundary_id": ""}
	# Canonical scene cards may move the authored viewpoint between pressurised
	# base rooms without teleporting a free-roaming actor. Exterior transitions
	# remain governed by the physical airlock below.
	if bool(context.get("authored_viewpoint_cut", false)) and from_room != "LOC-06" and to_room != "LOC-06":
		return {"accepted": true, "mode": "authored_viewpoint_cut", "boundary_id": "", "warning": "Scene transition is an explicit labelled base-room viewpoint cut; no actor was silently teleported."}
	var matched_id := ""
	var definition: Dictionary = {}
	for boundary_id in _BOUNDARIES.keys():
		var candidate: Dictionary = _BOUNDARIES[boundary_id]
		if (String(candidate.get("from", "")) == from_room and String(candidate.get("to", "")) == to_room) or (String(candidate.get("from", "")) == to_room and String(candidate.get("to", "")) == from_room):
			matched_id = String(boundary_id)
			definition = candidate
			break
	if matched_id.is_empty():
		return {"accepted": false, "reason": "No direct physical route connects %s to %s." % [from_room, to_room], "boundary_id": ""}
	var boundary_state: Dictionary = state.get(matched_id, {}) if state.get(matched_id, {}) is Dictionary else {}
	var effective := boundary_state.duplicate(true)
	for key in context.keys():
		effective[key] = context[key]
	if bool(context.get("authored_viewpoint_cut", false)):
		if String(definition.get("kind", "")) == AIRLOCK:
			return {"accepted": false, "reason": "The exterior airlock requires an authored safe cycle; a viewpoint cut cannot bypass it.", "boundary_id": matched_id}
		return {"accepted": true, "mode": "authored_viewpoint_cut", "boundary_id": matched_id, "warning": "Scene transition is an explicit labelled viewpoint cut; no actor was silently teleported."}
	if not bool(effective.get("open", definition.get("default_open", false))):
		return {"accepted": false, "reason": "Boundary %s is closed." % matched_id, "boundary_id": matched_id}
	var kind := String(definition.get("kind", ""))
	if kind == AIRLOCK:
		if bool(definition.get("requires_airlock_cycle", false)) and not bool(effective.get("airlock_ready", false)):
			return {"accepted": false, "reason": "Airlock interlock is not cycled to a safe ready state.", "boundary_id": matched_id}
		if bool(definition.get("requires_suit_check", false)) and not bool(effective.get("suit_check", false)):
			return {"accepted": false, "reason": "Suit and exterior instrument check is incomplete.", "boundary_id": matched_id}
		if bool(definition.get("requires_exposure_clear", false)) and (bool(effective.get("exposure_lock", false)) or not bool(effective.get("exposure_clear", true))):
			return {"accepted": false, "reason": "Exterior route is locked during an active exposure condition.", "boundary_id": matched_id}
	if kind == SHUTTER and bool(definition.get("requires_chamber_safe", false)) and not bool(effective.get("chamber_safe", false)):
		return {"accepted": false, "reason": "The garden chamber has not returned a safe pressure/condition reading.", "boundary_id": matched_id}
	if kind == EXPOSURE_LOCK and bool(effective.get("exposure_lock", false)):
		return {"accepted": false, "reason": "Safe Room exposure lock keeps the return boundary closed.", "boundary_id": matched_id}
	return {"accepted": true, "mode": "physical_boundary", "boundary_id": matched_id}

static func room_bounds(room_id: String) -> Dictionary:
	var bounds := {
		"LOC-01": [22.0, 12.0],
		"LOC-02": [12.0, 6.0],
		"LOC-03": [12.0, 8.0],
		"LOC-04": [8.0, 6.0],
		"LOC-05": [8.0, 4.0],
		"LOC-06": [120.0, 120.0],
		"LOC-07": [8.0, 6.0],
		"LOC-08": [12.0, 9.0],
		"LOC-09": [30.0, 30.0],
		"LOC-10": [34.0, 34.0],
		"LOC-11": [200.0, 60.0],
		"LOC-12": [120.0, 120.0],
	}
	var value: Array = bounds.get(room_id, [])
	if value.size() != 2:
		return {}
	return {"width": float(value[0]), "depth": float(value[1]), "floor_y": 0.0}

static func point_inside_room(room_id: String, position: Vector3, margin: float = 0.35) -> bool:
	var bounds := room_bounds(room_id)
	if bounds.is_empty():
		return false
	return absf(position.x) <= float(bounds.width) * 0.5 - margin and absf(position.z) <= float(bounds.depth) * 0.5 - margin and position.y >= -0.05

static func validate_boundaries() -> Dictionary:
	var errors: Array[String] = []
	for boundary_id in _BOUNDARIES.keys():
		var definition: Dictionary = _BOUNDARIES[boundary_id]
		for key in ["from", "to", "kind", "default_open"]:
			if not definition.has(key):
				errors.append(String(boundary_id) + " missing " + key)
	return {"valid": errors.is_empty(), "errors": errors}
