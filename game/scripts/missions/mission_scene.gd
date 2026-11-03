extends Node3D
class_name CampaignMissionScene

@export var mission_id := ""
@export var scene_ids: Array[String] = []
@export var route_room_ids: Array[String] = []

var runtime

func bind_runtime(mission_runtime) -> void:
	runtime = mission_runtime
	set_meta("mission_id", mission_id)
	set_meta("scene_ids", scene_ids.duplicate())
	set_meta("route_room_ids", route_room_ids.duplicate())

func contract() -> Dictionary:
	return {
		"mission_id": mission_id,
		"scene_ids": scene_ids.duplicate(),
		"route_room_ids": route_room_ids.duplicate(),
		"runtime_bound": runtime != null,
	}
