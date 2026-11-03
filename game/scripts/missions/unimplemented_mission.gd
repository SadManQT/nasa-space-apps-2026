extends RefCounted
class_name UnimplementedMission

var mission_id := ""
var _definition := {}

func _init(id: String, definition: Dictionary) -> void:
	mission_id = id
	_definition = definition.duplicate(true)

func scene_ids() -> Array:
	return _definition.get("scene_ids", []).duplicate()

func status() -> Dictionary:
	var blocked: Array = []
	for scene_id in scene_ids():
		blocked.append({
			"scene_id": scene_id,
			"status": "blocked",
			"gate_id": "UNIMPLEMENTED:%s:physical_adapter" % String(scene_id),
			"reason": "No mission-owned physical adapter exists yet; dialogue or a cutscene cannot complete this scene.",
			"requires": ["world_interaction_adapter", "mission_gate_adapter", "chapter_state_integration"],
		})
	return {
		"mission_id": mission_id,
		"implemented": false,
		"status": "unimplemented",
		"scene_ids": scene_ids(),
		"blocked_gates": blocked,
		"can_complete": false,
		"dialogue_acknowledgement_completes": false,
	}

func begin() -> Dictionary:
	return {"accepted": false, "status": "unimplemented", "reason": "This mission is registered honestly but has no implementation adapter.", "blocked_gates": status().get("blocked_gates", [])}

func perform(_target_id: String, _payload: Dictionary = {}, _context: Dictionary = {}) -> Dictionary:
	return {"accepted": false, "status": "unimplemented", "reason": "No physical operation is available for " + mission_id + "."}

func complete() -> Dictionary:
	return {"accepted": false, "status": "unimplemented", "reason": "Mission completion is blocked until its physical gates are implemented."}
