extends RefCounted
class_name CampaignRoute

## Interface shared by every production route (Chapters 1, 2 and 3-8):
## current-scene targets, pause/resume through the dispatcher, and the
## pre-operation retry checkpoint that restores director, puzzle and world
## state together.

var _director: RefCounted
var _world: RefCounted
var _dispatcher: RefCounted
var _retry_checkpoint := {}
var _gate_catalog: GDScript

func _create_dispatcher(script: GDScript) -> void:
	# Save validation stages short-lived routes. A callable bound to self would
	# keep route -> dispatcher -> route alive after every autosave.
	_dispatcher = script.new(_director, _submit_weak.bind(weakref(self)))

static func _submit_weak(command: Dictionary, preview_only: bool, target: WeakRef) -> Dictionary:
	var route = target.get_ref()
	if route == null:
		return {"accepted": false, "reason": "The campaign route is no longer active."}
	return route._submit_command(command, preview_only)

func targets_for_current_scene() -> Array:
	return _gate_catalog.targets_for_scene(current_scene_id())

func current_scene_id() -> String:
	return ""

func current_mission_id() -> String:
	return ""

func pause(reason: String = "route_pause") -> Dictionary:
	return _dispatcher.pause(reason)

func resume() -> Dictionary:
	return _dispatcher.resume()

func snapshot() -> Dictionary:
	return {}

func restore(_data: Dictionary) -> Dictionary:
	return {"accepted": false, "reason": "Route restore is not implemented."}

func _checkpoint_snapshot() -> Dictionary:
	var state: Dictionary = _director.snapshot()
	state.erase("route_runtime")
	state["scene_id"] = current_scene_id()
	state["chapter_id"] = current_scene_id().substr(3, 4)
	state["mission_id"] = current_mission_id()
	var local := snapshot()
	local.erase("retry_checkpoint")
	return {"director": state, "route": local}

func retry() -> Dictionary:
	if _retry_checkpoint.is_empty():
		return {"accepted": false, "reason": "No physical retry checkpoint is available."}
	var checkpoint := _retry_checkpoint.duplicate(true)
	if not checkpoint.get("route", null) is Dictionary or not checkpoint.get("director", null) is Dictionary:
		return {"accepted": false, "reason": "The retry checkpoint is incomplete."}
	var was_paused := bool(_director.query().get("paused", false))
	var local: Dictionary = checkpoint.route.duplicate(true)
	local["retry_checkpoint"] = checkpoint
	# restore() validates the route and the checkpoint's director state before
	# changing anything, so the director restore below cannot fail halfway.
	var restored := restore(local)
	if not bool(restored.get("accepted", false)):
		return restored
	_director.restore_snapshot(checkpoint.director)
	if was_paused:
		pause()
	else:
		resume()
	return {"accepted": true, "reason": "Last physical checkpoint restored; no scene or dialogue receipt was duplicated.", "route": snapshot()}

## Type-checks the fields Chapter 2-8 route snapshots share, before any live
## state changes. Puzzle and world contents are checked by the caller.
static func _validate_route_fields(data: Dictionary, scene_order: Array) -> Dictionary:
	var version = data.get("schema_version", 0)
	if not (version is int or version is float) or float(version) != 1.0:
		return {"accepted": false, "reason": "Unsupported campaign route schema."}
	var scene_id = data.get("current_scene_id", null)
	if not scene_id is String or not scene_order.has(scene_id):
		return {"accepted": false, "reason": "Route snapshot names an unknown scene."}
	for key in ["scene_flags", "dialogue_acks", "world"]:
		if not data.get(key, null) is Dictionary:
			return {"accepted": false, "reason": "Route snapshot requires a Dictionary for " + key + "."}
	for id in scene_order:
		if not data.scene_flags.get(id, null) is Dictionary or not data.dialogue_acks.get(id, null) is Array:
			return {"accepted": false, "reason": "Route snapshot is missing scene evidence maps."}
	if str(data.world.get("current_scene_id", "")) != scene_id or str(data.world.get("current_room_id", "")) != preload("res://scripts/world/room_contract.gd").room_for_scene(scene_id):
		return {"accepted": false, "reason": "World snapshot does not match the route scene."}
	if not data.get("completed_scene_ids", null) is Array:
		return {"accepted": false, "reason": "Route completed scenes must be an Array."}
	for completed in data.completed_scene_ids:
		if not completed is String or not scene_order.has(completed):
			return {"accepted": false, "reason": "Route completed scenes are outside this route."}
	for flags in data.scene_flags.values():
		if not flags is Dictionary:
			return {"accepted": false, "reason": "Route scene evidence must be Dictionaries."}
		for value in flags.values():
			if not value is bool:
				return {"accepted": false, "reason": "Route physical evidence must be boolean."}
	for lines in data.dialogue_acks.values():
		if not lines is Array:
			return {"accepted": false, "reason": "Route dialogue receipts must be Arrays."}
		for line_id in lines:
			if not line_id is String:
				return {"accepted": false, "reason": "Route dialogue receipts must be line IDs."}
	var checkpoint = data.get("retry_checkpoint", {})
	if not checkpoint is Dictionary:
		return {"accepted": false, "reason": "Route retry checkpoint must be a Dictionary."}
	if not checkpoint.is_empty() and (not checkpoint.get("director", null) is Dictionary or not checkpoint.get("route", null) is Dictionary or not preload("res://scripts/core/campaign_state.gd").is_compatible(checkpoint.director)):
		return {"accepted": false, "reason": "Route retry checkpoint has an invalid campaign state."}
	return {"accepted": true}
