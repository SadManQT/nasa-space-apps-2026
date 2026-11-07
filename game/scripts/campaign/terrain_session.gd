extends Node3D

## Campaign-owned adoption of Sadman's surveyed room contract. The room keeps
## all target/door/pressure IDs; only an explicitly ready placement gets ground.
const Contract = preload("res://scripts/world/room_contract.gd")
const Stream = preload("res://scripts/terrain/terrain_stream.gd")
const EarthSky = preload("res://assets/environment/terrain/earth_sky.gd")
var stream: Node3D
var origin := Vector3.ZERO
var placement: Dictionary = {}
var earth_presented := false
var configured := false

func prepare(room_id: String, scene_id: String) -> Dictionary:
	if configured or not is_inside_tree():
		return {"accepted": false, "reason": "Terrain preparation needs a fresh campaign terrain session in the scene tree."}
	placement = Contract.terrain(room_id)
	if not placement.get("omit_staging_floor", false):
		return {"accepted": true, "enabled": false, "reason": placement.get("pending", "This room uses its existing floor.")}
	origin = _vector(placement.origin_m)
	var start := player_anchor(placement.anchors)
	var clear_areas: Array = placement.exclusions.map(func(area): return {"position": _vector(area.position), "radius_m": float(area.radius_m)})
	stream = Stream.new()
	stream.name = "SurveyedTerrain"
	stream.position = -origin
	add_child(stream)
	if not stream.configure(String(placement.region_id), origin + start, clear_areas):
		return _abort("The surveyed terrain could not be prepared.")
	var rig: Node3D = stream.lighting(scene_id)
	if rig == null:
		return _abort("The exterior has no dated lighting for this site and scene.")
	add_child(rig)
	var environments := rig.find_children("*", "WorldEnvironment", false, false)
	if not environments.is_empty():
		earth_presented = EarthSky.apply(environments[0].environment, Contract.earth(room_id, scene_id), float(stream.config.sun_energy))
	configured = true
	return {"accepted": true, "enabled": true, "player_anchor": start, "earth_presented": earth_presented}

func _abort(reason: String) -> Dictionary:
	if stream != null:
		remove_child(stream)
		stream.queue_free()
		stream = null
	placement = {}
	origin = Vector3.ZERO
	return {"accepted": false, "reason": reason}

func move_focus(room_local: Vector3) -> bool:
	return configured and stream.move_focus(origin + room_local)

static func player_anchor(anchors: Dictionary) -> Vector3:
	for key in anchors:
		if String(key).ends_with("_player"):
			return _vector(anchors[key])
	return Vector3.ZERO

static func _vector(value: Array) -> Vector3:
	return Vector3(float(value[0]), float(value[1]), float(value[2]))
