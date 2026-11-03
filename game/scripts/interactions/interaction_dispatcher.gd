extends RefCounted
class_name InteractionDispatcher

## Focus/inspect/use/preview/confirm adapter.
## It owns presentation/transaction shape only. CampaignDirector or the
## injected submit callback owns every authoritative state transition.

signal focus_changed(target: Dictionary)
signal interaction_result(result: Dictionary)

var _director: RefCounted
var _submit_command: Callable
var _targets := {}
var _focus_id := ""
var _focus_context := {}
var _active_target := {}
var _active_payload := {}
var _last_command := {}
var _last_preview := {}
var _last_result := {}
var _cancelled := false

func _init(director: RefCounted = null, submit_command: Callable = Callable()) -> void:
	_director = director
	_submit_command = submit_command

func bind(director: RefCounted, submit_command: Callable = Callable()) -> void:
	_director = director
	_submit_command = submit_command

func clear_targets() -> void:
	_targets.clear()
	clear()

func register_target(spec: Dictionary) -> Dictionary:
	var target := spec.duplicate(true)
	var target_id := String(target.get("target_id", ""))
	if target_id.is_empty():
		return _reject("An interaction target needs a stable target_id.")
	for required in ["room_id", "focus_label", "verb"]:
		if not target.has(required):
			return _reject("Interaction target %s is missing %s." % [target_id, required])
	target["range_m"] = float(target.get("range_m", 2.0))
	target["line_of_sight_required"] = bool(target.get("line_of_sight_required", true))
	target["command_verb"] = String(target.get("command_verb", "set_phase"))
	target["target_id"] = target_id
	_targets[target_id] = target
	return {"accepted": true, "target": target.duplicate(true)}

func register_targets(specs: Array) -> Dictionary:
	var errors: Array[String] = []
	for spec in specs:
		if not spec is Dictionary:
			errors.append("target entry is not a Dictionary")
			continue
		var result := register_target(spec)
		if not bool(result.get("accepted", false)):
			errors.append(String(result.get("reason", "target rejected")))
	return {"accepted": errors.is_empty(), "errors": errors, "count": _targets.size()}

func target(target_id: String) -> Dictionary:
	return (_targets.get(target_id, {}) as Dictionary).duplicate(true)

func targets() -> Array:
	var result: Array = []
	for value in _targets.values():
		result.append((value as Dictionary).duplicate(true))
	return result

func focus(target_id: String, context: Dictionary = {}) -> Dictionary:
	var target_data := target(target_id)
	if target_data.is_empty():
		return _reject("Unknown focus target: " + target_id)
	var check := _check_target(target_data, context)
	if not bool(check.get("accepted", false)):
		return check
	_focus_id = target_id
	_focus_context = context.duplicate(true)
	_active_target = target_data
	_active_payload = {}
	_last_command = {}
	_last_preview = {}
	_last_result = {}
	_cancelled = false
	focus_changed.emit(target_data.duplicate(true))
	return {"accepted": true, "focused": true, "target": target_data.duplicate(true)}

func inspect(context: Dictionary = {}) -> Dictionary:
	if _active_target.is_empty() or _cancelled:
		return _reject("Inspect requires an active focus target.")
	var merged := _focus_context.duplicate(true)
	for key in context.keys():
		merged[key] = context[key]
	var check := _check_target(_active_target, merged)
	if not bool(check.get("accepted", false)):
		return check
	return {
		"accepted": true,
		"phase": "inspect",
		"target_id": _focus_id,
		"label": String(_active_target.get("focus_label", _focus_id)),
		"readout": String(_active_target.get("readout", _active_target.get("focus_label", _focus_id))),
		"evidence_tag": String(_active_target.get("evidence_tag", "Simulated")),
		"command_emitted": false,
	}

func use(payload: Dictionary = {}, context: Dictionary = {}) -> Dictionary:
	if _active_target.is_empty() or _cancelled:
		return _reject("Use requires an active focus target.")
	var merged := _focus_context.duplicate(true)
	for key in context.keys():
		merged[key] = context[key]
	var check := _check_target(_active_target, merged)
	if not bool(check.get("accepted", false)):
		return check
	_active_payload = payload.duplicate(true)
	return {
		"accepted": true,
		"phase": "use",
		"target_id": _focus_id,
		"payload": _active_payload.duplicate(true),
		"next": "preview",
		"command_emitted": false,
	}

func preview(payload_override: Dictionary = {}) -> Dictionary:
	if _active_target.is_empty() or _cancelled:
		return _reject("Preview requires an active use target.")
	var payload := _active_payload.duplicate(true)
	for key in payload_override.keys():
		payload[key] = payload_override[key]
	var command := _build_command(payload)
	if command.is_empty():
		return _reject("Unable to construct a frozen command for the focused target.")
	var result := _dispatch(command, true)
	_last_command = command.duplicate(true)
	_last_preview = result.duplicate(true)
	_last_result = {}
	interaction_result.emit(result.duplicate(true))
	return result

func confirm(command_id_override: String = "", payload_override: Dictionary = {}) -> Dictionary:
	if _last_command.is_empty() or _last_preview.is_empty() or _cancelled:
		return _reject("Confirm requires an accepted preview and cannot run after cancel.")
	var command := _last_command.duplicate(true)
	if not command_id_override.is_empty():
		command["command_id"] = command_id_override
	if not payload_override.is_empty():
		var payload: Dictionary = command.get("payload", {}).duplicate(true)
		for key in payload_override.keys():
			payload[key] = payload_override[key]
		command["payload"] = payload
	var result := _dispatch(command, false)
	_last_result = result.duplicate(true)
	interaction_result.emit(result.duplicate(true))
	return result

func cancel(reason: String = "user") -> Dictionary:
	_cancelled = true
	_active_target = {}
	_active_payload = {}
	_last_command = {}
	_last_preview = {}
	_last_result = {}
	return {"accepted": true, "cancelled": true, "reason": reason, "command_emitted": false}

func clear() -> void:
	_focus_id = ""
	_focus_context = {}
	_active_target = {}
	_active_payload = {}
	_last_command = {}
	_last_preview = {}
	_last_result = {}
	_cancelled = false

func pause(reason: String = "interaction_pause") -> Dictionary:
	if _director == null or not _director.has_method("pause"):
		return _reject("Pause requires the authoritative CampaignDirector.")
	return _director.pause(reason)

func resume() -> Dictionary:
	if _director == null or not _director.has_method("resume"):
		return _reject("Resume requires the authoritative CampaignDirector.")
	return _director.resume()

func state() -> Dictionary:
	return {
		"focused_target_id": _focus_id,
		"active": not _active_target.is_empty() and not _cancelled,
		"cancelled": _cancelled,
		"last_command": _last_command.duplicate(true),
		"last_preview": _last_preview.duplicate(true),
		"last_result": _last_result.duplicate(true),
	}

func _build_command(payload: Dictionary) -> Dictionary:
	if _director == null or not _director.has_method("query"):
		return {}
	var query: Dictionary = _director.query()
	var command_payload := payload.duplicate(true)
	var command_id := String(command_payload.get("_command_id", _active_target.get("command_id", "")))
	command_payload.erase("_command_id")
	if command_id.is_empty():
		command_id = "interaction:%s" % _focus_id
	var target_id := String(_active_target.get("command_target_id", _active_target.get("target_id", _focus_id)))
	var verb := String(_active_target.get("command_verb", "set_phase"))
	if verb == "set_phase" and not command_payload.has("phase"):
		command_payload["phase"] = "physical:" + _focus_id
	return {
		"command_id": command_id,
		"issuer": String(_active_target.get("issuer", "interaction_dispatcher")),
		"owning_mission_id": String(_active_target.get("owning_mission_id", "")),
		"owning_scene_id": String(_active_target.get("owning_scene_id", "")),
		"expected_state_revision": int(query.get("state_revision", 0)),
		"target_id": target_id,
		"verb": verb,
		"payload": command_payload,
	}

func _dispatch(command: Dictionary, preview_only: bool) -> Dictionary:
	if _submit_command.is_valid():
		var callback_result = _submit_command.call(command, preview_only)
		return callback_result if callback_result is Dictionary else _reject("Interaction command callback returned a non-Dictionary result.")
	if _director == null:
		return _reject("Interaction dispatcher has no CampaignDirector or command callback.")
	return _director.preview(command) if preview_only else _director.commit(command)

func _check_target(target_data: Dictionary, context: Dictionary) -> Dictionary:
	if String(context.get("room_id", target_data.get("room_id", ""))) != String(target_data.get("room_id", "")):
		return _reject("Target is not in the current physical room.")
	var distance := float(context.get("distance_m", 0.0))
	if distance > float(target_data.get("range_m", 2.0)):
		return _reject("Move within interaction range of " + String(target_data.get("focus_label", "target")) + ".")
	if bool(target_data.get("line_of_sight_required", true)) and not bool(context.get("line_of_sight", true)):
		return _reject("Line of sight to the target is blocked.")
	var flags: Dictionary = context.get("flags", {}) if context.get("flags", {}) is Dictionary else {}
	for required in target_data.get("required_flags", []):
		if not bool(flags.get(String(required), false)):
			return _reject(String(target_data.get("unmet_reason", "Required physical check is incomplete.")))
	var required_room := String(target_data.get("requires_room", ""))
	if not required_room.is_empty() and required_room != String(context.get("room_id", "")):
		return _reject("This operation requires room " + required_room + ".")
	if bool(target_data.get("requires_airlock_ready", false)) and not bool(context.get("airlock_ready", false)):
		return _reject("The airlock is not in a safe ready state.")
	if bool(target_data.get("requires_suit_check", false)) and not bool(context.get("suit_check", false)):
		return _reject("Suit and instrument checks are required first.")
	return {"accepted": true}

func _reject(reason: String) -> Dictionary:
	return {
		"accepted": false,
		"duplicate": false,
		"reason": reason,
		"command_emitted": false,
	}
