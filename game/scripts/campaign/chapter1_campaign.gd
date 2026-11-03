extends Node3D
class_name Chapter1Campaign

signal exit_requested

const ContentScript = preload("res://scripts/content/content_loader.gd")
const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const SaveScript = preload("res://scripts/save/save_service.gd")
const RouteScript = preload("res://scripts/missions/chapter1_route.gd")
const Chapter2RouteScript = preload("res://scripts/missions/chapter2_route.gd")
const ExtendedRouteScript = preload("res://scripts/missions/extended_campaign_route.gd")
const RoomContract = preload("res://scripts/world/room_contract.gd")
const HUDScene: PackedScene = preload("res://scenes/ui/chapter1_campaign_hud.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")

@export var initial_snapshot: Dictionary = {}
@export var initial_accessibility: Dictionary = {}

var content: Dictionary = {}
var director: CampaignDirector
var route: RefCounted
var save_service: SaveService
var hud: Chapter1CampaignHUD
var _room: CampaignRoom
var _player: PlayerController
var _startup_error := ""
var _ui_paused := false

func _ready() -> void:
	content = ContentScript.load_full()
	var validation := ContentScript.validate_full(content)
	if not bool(validation.get("valid", false)):
		_fail_startup("Campaign content could not be verified.")
		return
	save_service = SaveScript.new()
	director = DirectorScript.new()
	if initial_snapshot.is_empty():
		director.new_campaign(ContentScript.EXPECTED_CONTENT_REVISION)
	else:
		if not initial_snapshot.get("route_runtime", {}) is Dictionary or initial_snapshot.get("route_runtime", {}).is_empty():
			_fail_startup("This checkpoint is missing its physical mission route.")
			return
		var state_snapshot := initial_snapshot.duplicate(true)
		state_snapshot.erase("route_runtime")
		var restored := director.restore_snapshot(state_snapshot, ContentScript.EXPECTED_CONTENT_REVISION)
		if not bool(restored.get("accepted", false)):
			_fail_startup(String(restored.get("reason", "The checkpoint could not be restored.")))
			return
	var presentation := director.snapshot()
	presentation["paused"] = false
	for key in initial_accessibility:
		presentation["accessibility"][key] = initial_accessibility[key]
	director.restore_snapshot(presentation)
	var saved_route: Dictionary = initial_snapshot.get("route_runtime", {}) if initial_snapshot.get("route_runtime", {}) is Dictionary else {}
	var saved_chapter := String(initial_snapshot.get("chapter_id", "CH01"))
	if saved_chapter == "CH02" or int(saved_route.get("chapter", 1)) == 2:
		route = Chapter2RouteScript.new(director)
	elif saved_chapter.begins_with("CH") and int(saved_chapter.trim_prefix("CH")) >= 3:
		route = ExtendedRouteScript.new(director)
	else:
		route = RouteScript.new(director)
	if initial_snapshot.get("route_runtime", {}) is Dictionary and not initial_snapshot.get("route_runtime", {}).is_empty():
		var route_restore: Dictionary = route.restore(initial_snapshot.get("route_runtime", {}))
		if not bool(route_restore.get("accepted", false)):
			_fail_startup(String(route_restore.get("reason", "The saved mission route could not be restored.")))
			return
	else:
		var saved_scene := String(director.snapshot().get("scene_id", "EX-CH01-S01"))
		if not saved_scene.is_empty():
			var started: Dictionary = route.start_at(saved_scene)
			if not bool(started.get("accepted", false)):
				_fail_startup(String(started.get("reason", "The saved scene is unavailable.")))
				return
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
	if route != null and route.has_method("targets_for_current_scene"):
		return route.targets_for_current_scene()
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
	if not _startup_error.is_empty() or route == null:
		return {"accepted": false, "reason": "The expedition is unavailable."}
	if is_chapter_complete():
		return {"accepted": false, "reason": "Chapter 1 is complete. Return to title to keep this checkpoint."}
	var target := physical_target(target_id)
	var result: Dictionary
	if target == null or _player == null:
		result = {"accepted": false, "reason": "This operation has no physical target in the current room."}
	else:
		var distance := _player.global_position.distance_to(target.global_position)
		var ray := PhysicsRayQueryParameters3D.create(_player.global_position + Vector3.UP * 1.4, target.global_position, _player.collision_mask, [_player.get_rid()])
		var clear := _player.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
		if not clear:
			result = {"accepted": false, "reason": "Move into clear view of " + String(target.get_meta("focus_label", "the target")) + "."}
		else:
			result = route.perform(target_id, payload, {"room_id": _room.room_id, "distance_m": distance, "line_of_sight": clear})
	_sync_world_boundaries()
	_save_campaign()
	if hud != null:
		hud.refresh_after_action(result)
	return result

func physical_target(target_id: String) -> Node3D:
	if _room == null or _room.focus_root == null:
		return null
	for spec in targets_for_current_scene():
		if String(spec.get("target_id", "")) == target_id:
			for node in _room.focus_root.get_children():
				if String(node.get_meta("target_id", "")) == String(spec.get("world_focus_id", "")):
					return node as Node3D
	return null

func target_completed(spec: Dictionary) -> bool:
	var id := String(spec.get("target_id", ""))
	if id == "p02_stage_shift2":
		return bool(route.gate_status().get("physical_flags", {}).get("shift2_preview_staged", false))
	if String(spec.get("puzzle_id", "")) == "P-01":
		return route.snapshot().get("p01", {}).get("receipts", {}).has("p01:" + id)
	var physical_flags: Dictionary = route.gate_status().get("physical_flags", {})
	if bool(physical_flags.get(String(spec.get("physical_flag", "")), false)):
		return true
	return director.snapshot().get("receipts", {}).has(String(spec.get("command_id", "")))

func interact_nearby() -> Dictionary:
	if _ui_paused or _player == null:
		return {"accepted": false, "reason": "Close the panel before using an operation."}
	var flags: Dictionary = route.gate_status().get("physical_flags", {})
	for spec in targets_for_current_scene():
		if target_completed(spec):
			continue
		var missing := false
		for flag in spec.get("required_flags", []):
			if not bool(flags.get(flag, false)):
				missing = true
		if missing:
			continue
		var node := physical_target(String(spec.get("target_id", "")))
		if node != null and _player.global_position.distance_to(node.global_position) <= float(spec.get("range_m", 3.0)):
			return perform_target(String(spec.get("target_id", "")))
	var result := {"accepted": false, "reason": "Move near an unfinished operation. Its location is listed beside USE."}
	if hud != null:
		hud.show_status(result.reason)
	return result

func is_chapter_complete() -> bool:
	if route == null:
		return false
	var scene_id: String = route.current_scene_id()
	return scene_id.ends_with("-S12") and route.completed_scene_ids().has(scene_id)

func is_campaign_complete() -> bool:
	if route == null:
		return false
	var scene_id: String = route.current_scene_id()
	return scene_id == "EX-CH08-S12" and route.completed_scene_ids().has(scene_id)

func set_ui_paused(value: bool) -> void:
	_ui_paused = value
	if route != null:
		route.pause("reading_panel") if value else route.resume()
	if _player != null:
		_player.process_mode = Node.PROCESS_MODE_DISABLED if value else Node.PROCESS_MODE_INHERIT
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func retry_checkpoint() -> Dictionary:
	if not route.has_method("retry"):
		return {"accepted": false, "reason": "This later campaign route has no retry checkpoint yet."}
	var result: Dictionary = route.retry()
	if bool(result.get("accepted", false)):
		_sync_route_projection()
		_refresh_world()
		_save_campaign()
	if hud != null:
		hud.refresh_scene(result)
		hud.show_status(String(result.get("reason", "Checkpoint restored.")))
	return result

func acknowledge_dialogue(line_id: String) -> Dictionary:
	var result: Dictionary = route.acknowledge_dialogue(line_id)
	if hud != null:
		hud.refresh_after_action(result)
	return result

func advance_scene() -> Dictionary:
	var result: Dictionary
	if is_chapter_complete():
		result = _transition_after_chapter()
	else:
		result = route.advance_scene()
	if bool(result.get("accepted", false)) and bool(result.get("chapter_complete", false)) and not bool(result.get("campaign_complete", false)):
		_sync_route_projection()
		result["next_chapter"] = _transition_after_chapter()
	elif bool(result.get("accepted", false)):
		_sync_route_projection()
		_refresh_world()
	_save_campaign()
	if hud != null:
		hud.refresh_scene(result)
	return result

func _start_chapter2() -> Dictionary:
	_sync_route_projection()
	route = Chapter2RouteScript.new(director)
	var started: Dictionary = route.start_at("EX-CH02-S01")
	_sync_route_projection()
	_refresh_world()
	started["chapter_started"] = "CH02"
	return started

func _transition_after_chapter() -> Dictionary:
	var chapter := _chapter_number()
	if chapter == 1:
		return _start_chapter2()
	if chapter == 2:
		return _start_extended("EX-CH03-S01")
	if chapter >= 3 and chapter < 8 and route.has_method("start_at"):
		return _start_extended("EX-CH%02d-S01" % (chapter + 1))
	return {"accepted": true, "chapter_complete": true, "campaign_complete": true, "reason": "The eight-chapter campaign is complete."}

func _start_extended(scene_id: String) -> Dictionary:
	_sync_route_projection()
	if not route is ExtendedCampaignRoute:
		route = ExtendedRouteScript.new(director)
	var started: Dictionary = route.start_at(scene_id)
	_sync_route_projection()
	_refresh_world()
	started["chapter_started"] = String(scene_id.substr(3, 4))
	return started

func save_campaign() -> Dictionary:
	var result := _save_campaign()
	if hud != null:
		hud.show_status(("CHECKPOINT SAVED · " if bool(result.get("accepted", false)) else "SAVE FAILED · ") + String(result.get("reason", "verified")))
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
		if hud != null:
			hud.apply_accessibility()
		return restored
	return {"accepted": false, "reason": "The campaign runtime does not own UI command " + verb}

func exit_to_title() -> void:
	if _startup_error.is_empty():
		_save_campaign()
	exit_requested.emit()

func _save_snapshot() -> Dictionary:
	var snapshot := director.snapshot()
	snapshot["paused"] = false
	snapshot["route_runtime"] = route.snapshot()
	snapshot["route_runtime"]["chapter"] = _chapter_number()
	return snapshot

func _chapter_number() -> int:
	if route == null:
		return 1
	var scene_id: String = route.current_scene_id()
	return int(scene_id.substr(5, 2)) if scene_id.length() >= 7 else 1

func _sync_route_projection() -> void:
	if director == null or route == null:
		return
	var next := director.snapshot()
	var chapter_number := _chapter_number()
	next["chapter_id"] = "CH%02d" % chapter_number
	next["mission_id"] = route.current_mission_id()
	next["scene_id"] = route.current_scene_id()
	next["checkpoint_id"] = route.current_scene_id() + "-CHECKPOINT"
	var campaign_completed: Array = next.get("completed_scene_ids", []).duplicate()
	for completed_scene_id in route.completed_scene_ids():
		if not campaign_completed.has(completed_scene_id):
			campaign_completed.append(completed_scene_id)
	next["completed_scene_ids"] = campaign_completed
	next["scene_phase"] = "chapter_complete" if is_chapter_complete() else "briefing"
	if chapter_number >= 2:
		next["chapter1_ready"] = true
	var result := director.restore_snapshot(next)
	if not bool(result.get("accepted", false)):
		push_warning("Unable to synchronize the saved campaign scene projection: " + String(result.get("reason", "unknown")))

func _save_campaign() -> Dictionary:
	if not _startup_error.is_empty():
		return {"accepted": false, "reason": _startup_error}
	return save_service.save(_save_snapshot())

func _fail_startup(reason: String) -> void:
	_startup_error = reason
	var layer := CanvasLayer.new()
	add_child(layer)
	var page := VBoxContainer.new()
	page.position = Vector2(80, 180)
	page.size = Vector2(960, 300)
	layer.add_child(page)
	var message := Label.new()
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.text = "CHECKPOINT COULD NOT BE OPENED\n" + reason + "\nYour saved files have been preserved."
	page.add_child(message)
	var back := Button.new()
	back.text = "RETURN TO TITLE"
	back.pressed.connect(func() -> void: exit_requested.emit())
	page.add_child(back)
	back.grab_focus()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	if _ui_paused or _player == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_player.follow_camera.look(event.screen_relative * _player.follow_camera.mouse_sensitivity)
	elif event.is_action_pressed("interact") and not event.is_echo():
		interact_nearby()
		get_viewport().set_input_as_handled()

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
	}.get(route.current_room_id(), "")
	if room_path.is_empty():
		_room = CampaignRoom.new()
		_room.room_id = route.current_room_id()
	else:
		_room = load(room_path).instantiate() as CampaignRoom
	_room.load_approved_assets = true
	add_child(_room)
	var anchors: Dictionary = RoomContract.anchors(route.current_room_id())
	var anchor_id: String = {"LOC-01": "commons_player", "LOC-02": "service_player", "LOC-03": "garden_player", "LOC-04": "safe_player", "LOC-06": "exterior_player"}.get(route.current_room_id(), "")
	var player_anchor: Array = anchors.get(anchor_id, [])
	if player_anchor.is_empty():
		for candidate in anchors.keys():
			if String(candidate).ends_with("_player"):
				player_anchor = anchors[candidate]
				break
	if player_anchor.is_empty():
		player_anchor = [0.0, 0.0, 2.0]
	_player = PLAYER_SCENE.instantiate() as PlayerController
	_player.gravity = 1.62
	var actor := String(current_scene_data().get("point_of_view", "Mei"))
	if actor not in ["Kai", "Amara", "Mei", "Rafi"]:
		actor = "Mei"
	_player.character_glb = "res://assets/characters/CH_%s/CH_%s.glb" % [actor, actor]
	_player.position = Vector3(float(player_anchor[0]), float(player_anchor[1]), float(player_anchor[2]))
	(_player.get_node("FollowCamera") as FollowCamera).capture_mouse = false
	_room.add_child(_player)
	_player.follow_camera.set_process_unhandled_input(false)
	_player.process_mode = Node.PROCESS_MODE_DISABLED if _ui_paused else Node.PROCESS_MODE_INHERIT
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_sync_world_boundaries()

func _sync_world_boundaries() -> void:
	if _room == null:
		return
	_room.apply_plant_state(director.snapshot().get("plants", []))
	for boundary_id in RoomContract.room(_room.room_id).get("boundary_ids", []):
		var state: Dictionary = route.world().boundary_state(String(boundary_id))
		_room.set_door_open(String(boundary_id), bool(state.get("open", false)) and not bool(state.get("exposure_lock", false)))

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "CampaignHUDLayer"
	add_child(layer)
	hud = HUDScene.instantiate() as Chapter1CampaignHUD
	layer.add_child(hud)
	hud.setup(self)
