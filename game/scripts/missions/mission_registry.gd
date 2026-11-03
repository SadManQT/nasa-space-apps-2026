extends RefCounted
class_name MissionRegistry

const ContentScript = preload("res://scripts/content/content_loader.gd")
const Chapter1RouteScript = preload("res://scripts/missions/chapter1_route.gd")
const Chapter1MissionScript = preload("res://scripts/missions/chapter1_mission.gd")
const Chapter2RouteScript = preload("res://scripts/missions/chapter2_route.gd")
const Chapter2MissionScript = preload("res://scripts/missions/chapter2_mission.gd")
const UnimplementedMissionScript = preload("res://scripts/missions/unimplemented_mission.gd")
const GateCatalog = preload("res://scripts/missions/chapter1_gate_catalog.gd")
const Chapter2GateCatalog = preload("res://scripts/missions/chapter2_gate_catalog.gd")

var _content := {}
var _route: RefCounted
var _director: RefCounted

func _init(content: Dictionary = {}, director: RefCounted = null, route: RefCounted = null) -> void:
	_content = content.duplicate(true) if not content.is_empty() else ContentScript.load_full()
	_director = director
	_route = route

func all_mission_ids() -> Array:
	var ids: Array = []
	for mission in _content.get("missions", []):
		if mission is Dictionary:
			ids.append(String(mission.get("id", "")))
	return ids

func definition(mission_id: String) -> Dictionary:
	return ContentScript.mission_by_id(_content, mission_id)

func is_implemented(mission_id: String) -> bool:
	return GateCatalog.mission_ids().has(mission_id) or Chapter2GateCatalog.mission_ids().has(mission_id)

func create(mission_id: String, director: RefCounted = null, route: RefCounted = null):
	var selected_director := director if director != null else _director
	var selected_route := route if route != null else _route
	if GateCatalog.mission_ids().has(mission_id):
		if selected_route == null:
			selected_route = Chapter1RouteScript.new(selected_director)
		return Chapter1MissionScript.new(mission_id, selected_route)
	if Chapter2GateCatalog.mission_ids().has(mission_id):
		if selected_route == null:
			selected_route = Chapter2RouteScript.new(selected_director)
		return Chapter2MissionScript.new(mission_id, selected_route)
	var mission_definition := definition(mission_id)
	return UnimplementedMissionScript.new(mission_id, mission_definition)

func registry_status() -> Dictionary:
	var rows: Array = []
	for mission_id in all_mission_ids():
		var implemented := is_implemented(String(mission_id))
		rows.append({
			"mission_id": String(mission_id),
			"implemented": implemented,
			"status": "implemented" if implemented else "unimplemented",
			"scene_ids": definition(String(mission_id)).get("scene_ids", []).duplicate(),
		})
	return {
		"mission_count": rows.size(),
		"implemented_count": rows.filter(func(row): return bool(row.get("implemented", false))).size(),
		"unimplemented_count": rows.filter(func(row): return not bool(row.get("implemented", false))).size(),
		"missions": rows,
	}

func validate_honesty() -> Dictionary:
	var errors: Array[String] = []
	var ids := all_mission_ids()
	if ids.size() != 32:
		errors.append("registry must load all 32 canonical missions")
	for mission_id in ids:
		var instance = create(String(mission_id))
		var status: Dictionary = instance.status()
		if not is_implemented(String(mission_id)):
			if String(status.get("status", "")) != "unimplemented" or bool(status.get("can_complete", true)):
				errors.append(String(mission_id) + " is not explicit about its unimplemented blocked gates")
			if status.get("blocked_gates", []).size() != 3:
				errors.append(String(mission_id) + " must expose three blocked scene gates")
	return {"valid": errors.is_empty(), "errors": errors, "status": registry_status()}
