extends RefCounted
class_name Chapter1Mission

const GateCatalog = preload("res://scripts/missions/chapter1_gate_catalog.gd")

var mission_id := ""
var _route: RefCounted
var _scene_ids: Array = []
var _started := false

func _init(id: String, route: RefCounted) -> void:
	mission_id = id
	_route = route
	_scene_ids = GateCatalog.scenes_for_mission(id)

func scene_ids() -> Array:
	return _scene_ids.duplicate()

func begin() -> Dictionary:
	if _scene_ids.is_empty():
		return {"accepted": false, "status": "blocked", "reason": "Mission has no Chapter 1 scene composition."}
	var completed: Array = _route.completed_scene_ids()
	var first_index := GateCatalog.SCENE_ORDER.find(_scene_ids[0])
	for predecessor_index in range(first_index):
		if not completed.has(GateCatalog.SCENE_ORDER[predecessor_index]):
			return {"accepted": false, "status": "blocked", "reason": "Previous Chapter 1 physical scene is incomplete.", "required_scene_id": GateCatalog.SCENE_ORDER[predecessor_index]}
	var started: Dictionary = _route.start_at(_scene_ids[0])
	_started = bool(started.get("accepted", false))
	return started

func status() -> Dictionary:
	var completed: Array = _route.completed_scene_ids()
	var mission_complete := true
	var missing: Array[String] = []
	for scene_id in _scene_ids:
		if not completed.has(scene_id):
			mission_complete = false
			missing.append(String(scene_id))
	return {
		"mission_id": mission_id,
		"implemented": true,
		"status": "complete" if mission_complete else ("active" if _started else "ready"),
		"scene_ids": scene_ids(),
		"missing_scene_ids": missing,
		"physical_gate_only": true,
		"dialogue_acknowledgement_completes": false,
	}

func gate_status() -> Dictionary:
	return _route.gate_status()

func perform(target_id: String, payload: Dictionary = {}, context: Dictionary = {}) -> Dictionary:
	return _route.perform(target_id, payload, context)

func acknowledge_dialogue(line_id: String) -> Dictionary:
	return _route.acknowledge_dialogue(line_id)

func advance_scene() -> Dictionary:
	return _route.advance_scene()

func route() -> RefCounted:
	return _route
