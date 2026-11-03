extends Node3D
class_name Chapter1Campaign

signal exit_requested

const ContentScript = preload("res://scripts/content/content_loader.gd")
const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const SaveScript = preload("res://scripts/save/save_service.gd")
const RouteScript = preload("res://scripts/missions/chapter1_route.gd")
const RoomContract = preload("res://scripts/world/room_contract.gd")
const HUDScene: PackedScene = preload("res://scenes/ui/chapter1_campaign_hud.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")

@export var initial_snapshot: Dictionary = {}

var content: Dictionary = {}
var director: CampaignDirector
var route: Chapter1Route
var save_service: SaveService
var hud: Chapter1CampaignHUD
var _room: CampaignRoom
var _player: PlayerController

func _ready() -> void:
	content = ContentScript.load_full()
	var validation := ContentScript.validate_full(content)
	if not bool(validation.get("valid", false)):
		push_error("Full campaign content validation failed: " + "; ".join(validation.get("errors", [])))
	save_service = SaveScript.new()
	director = DirectorScript.new()
	if initial_snapshot.is_empty():
		director.new_campaign(ContentScript.EXPECTED_CONTENT_REVISION)
	else:
		var restored := director.restore_snapshot(initial_snapshot)
		if not bool(restored.get("accepted", false)):
			director.new_campaign(ContentScript.EXPECTED_CONTENT_REVISION)
	route = RouteScript.new(director)
	if initial_snapshot.get("route_runtime", {}) is Dictionary and not initial_snapshot.get("route_runtime", {}).is_empty():
		var route_restore := route.restore(initial_snapshot.get("route_runtime", {}))
		if not bool(route_restore.get("accepted", false)):
			push_warning("Route save could not be restored; starting at the saved campaign scene.")
	else:
		var saved_scene := String(director.snapshot().get("scene_id", "EX-CH01-S01"))
		if not saved_scene.is_empty():
			route.start_at(saved_scene)
	_sync_route_projection()
	_build_stage()
	_refresh_world()
	_build_hud()
	_save_campaign()

func current_scene_data() -> Dictionary:
	return ContentScript.scene_by_id(content, route.current_scene_id())

func current_dialogue() -> Array:
	return current_scene_data().get("dialogue", [])

func targets_for_current_scene() -> Array:
	return _targets_for_scene()

func _targets_for_scene() -> Array:
	var gate_script = load("res://scripts/missions/chapter1_gate_catalog.gd")
	return gate_script.targets_for_scene(route.current_scene_id())

func query() -> Dictionary:
	var result := director.query()
	result["scene_id"] = route.current_scene_id()
	result["mission_id"] = route.current_mission_id()
	result["room_id"] = route.current_room_id()
	result["objective"] = current_scene_data().get("playerActions", [])
	result["dialogue_lines"] = current_dialogue()
	result["journal_entries"] = director.snapshot().get("knowledge", [])
	result["accessibility"] = director.snapshot().get("accessibility", {})
	result["mission_table"] = {"title": current_scene_data().get("title", ""), "status": route.gate_status()}
	return result

func perform_target(target_id: String, payload: Dictionary = {}) -> Dictionary:
	var result := route.perform(target_id, payload)
	_save_campaign()
	if hud != null:
		hud.refresh_after_action(result)
	return result

func acknowledge_dialogue(line_id: String) -> Dictionary:
	var result := route.acknowledge_dialogue(line_id)
	if hud != null:
		hud.refresh_after_action(result)
	return result

func advance_scene() -> Dictionary:
	var result := route.advance_scene()
	if bool(result.get("accepted", false)) and not bool(result.get("chapter_complete", false)):
		_sync_route_projection()
		_refresh_world()
	elif bool(result.get("chapter_complete", false)):
		_sync_route_projection()
	_save_campaign()
	if hud != null:
		hud.refresh_scene(result)
	return result

func save_campaign() -> Dictionary:
	var result := _save_campaign()
	if hud != null:
		hud.show_status("CHECKPOINT SAVED · " + String(result.get("reason", "verified")))
	return result

func handle_ui_command(command: Dictionary, _preview_only: bool = false) -> Dictionary:
	var verb := String(command.get("verb", ""))
	var payload: Dictionary = command.get("payload", {}) if command.get("payload", {}) is Dictionary else {}
	if verb == "acknowledge_line":
		return acknowledge_dialogue(String(payload.get("line_id", command.get("target_id", ""))))
	if verb == "set_accessibility":
		var next := director.snapshot()
		next["accessibility"] = payload.duplicate(true)
		var restored := director.restore_snapshot(next)
		_save_campaign()
		return restored
	return {"accepted": false, "reason": "The campaign runtime does not own UI command " + verb}

func exit_to_title() -> void:
	_save_campaign()
	exit_requested.emit()

func _save_snapshot() -> Dictionary:
	var snapshot := director.snapshot()
	snapshot["route_runtime"] = route.snapshot()
	return snapshot

func _sync_route_projection() -> void:
	if director == null or route == null:
		return
	var next := director.snapshot()
	next["chapter_id"] = "CH01"
	next["mission_id"] = route.current_mission_id()
	next["scene_id"] = route.current_scene_id()
	next["checkpoint_id"] = route.current_scene_id() + "-CHECKPOINT"
	next["completed_scene_ids"] = route.completed_scene_ids()
	next["scene_phase"] = "briefing"
	var result := director.restore_snapshot(next)
	if not bool(result.get("accepted", false)):
		push_warning("Unable to synchronize the saved campaign scene projection: " + String(result.get("reason", "unknown")))

func _save_campaign() -> Dictionary:
	return save_service.save(_save_snapshot())

func _build_stage() -> void:
	var environment := WorldEnvironment.new()
	environment.environment = load("res://environments/look/character_look.tres") as Environment
	add_child(environment)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-52, -32, 0)
	key.light_color = Color("#FFE5B5")
	key.light_energy = 1.65
	key.shadow_enabled = true
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-28, 145, 0)
	fill.light_color = Color("#85B7FF")
	fill.light_energy = 0.55
	add_child(fill)

func _refresh_world() -> void:
	if _room != null and is_instance_valid(_room):
		_room.queue_free()
		_room = null
	if _player != null and is_instance_valid(_player):
		_player.queue_free()
		_player = null
	var room_path: String = {
		"LOC-01": "res://scenes/campaign/rooms/commons.tscn",
		"LOC-02": "res://scenes/campaign/rooms/service_rooms.tscn",
		"LOC-03": "res://scenes/campaign/rooms/garden.tscn",
		"LOC-04": "res://scenes/campaign/rooms/safe_room.tscn",
		"LOC-06": "res://scenes/campaign/rooms/exterior.tscn",
	}.get(route.current_room_id(), "res://scenes/campaign/rooms/commons.tscn")
	_room = load(room_path).instantiate() as CampaignRoom
	_room.load_approved_assets = true
	add_child(_room)
	var anchors := RoomContract.anchors(route.current_room_id())
	var player_anchor: Array = anchors.get("garden_player" if route.current_room_id() == "LOC-03" else "commons_player", [0.0, 0.0, 2.0])
	_player = PLAYER_SCENE.instantiate() as PlayerController
	_player.character_glb = "res://assets/characters/CH_Mei/CH_Mei.glb"
	_player.position = Vector3(float(player_anchor[0]), float(player_anchor[1]), float(player_anchor[2]))
	_room.add_child(_player)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "CampaignHUDLayer"
	add_child(layer)
	hud = HUDScene.instantiate() as Chapter1CampaignHUD
	layer.add_child(hud)
	hud.setup(self)
