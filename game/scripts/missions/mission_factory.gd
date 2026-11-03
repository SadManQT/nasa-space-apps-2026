extends RefCounted
class_name MissionFactory

const RegistryScript = preload("res://scripts/missions/mission_registry.gd")

static func create(mission_id: String, director: RefCounted = null, route: RefCounted = null):
	var registry := RegistryScript.new({}, director, route)
	return registry.create(mission_id, director, route)

static func create_registry(content: Dictionary = {}, director: RefCounted = null, route: RefCounted = null):
	return RegistryScript.new(content, director, route)
