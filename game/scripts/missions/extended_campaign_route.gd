extends "res://scripts/missions/campaign_route.gd"
class_name ExtendedCampaignRoute

const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const DispatcherScript = preload("res://scripts/interactions/interaction_dispatcher.gd")
const WorldRouteScript = preload("res://scripts/world/world_route.gd")
const GateCatalog = preload("res://scripts/missions/extended_gate_catalog.gd")
const LedgerScript = preload("res://scripts/puzzles/extended_puzzle_ledger.gd")
const ResultScript = preload("res://scripts/core/command_result.gd")

var _ledger: RefCounted
var _scene_index := 0
var _scene_flags := {}
var _dialogue_acks := {}
var _completed_scene_ids: Array = []
var _last_result := {}

func _init(director: RefCounted = null) -> void:
	_gate_catalog = GateCatalog
	_director = director if director != null else DirectorScript.new()
	_world = WorldRouteScript.new(_director)
	_create_dispatcher(DispatcherScript)
	_ledger = LedgerScript.new()
	for scene_id in GateCatalog.scene_ids():
		_scene_flags[scene_id] = {}
		_dialogue_acks[scene_id] = []
	_set_current_scene(0)
	_retry_checkpoint = _checkpoint_snapshot()

func director() -> RefCounted:
	return _director

func world() -> RefCounted:
	return _world

func dispatcher() -> RefCounted:
	return _dispatcher

func current_scene_id() -> String:
	return String(GateCatalog.scene_ids()[_scene_index])

func current_mission_id() -> String:
	return String(GateCatalog.gate(current_scene_id()).get("mission_id", ""))

func current_room_id() -> String:
	return String(GateCatalog.gate(current_scene_id()).get("room_id", "LOC-01"))

func completed_scene_ids() -> Array:
	return _completed_scene_ids.duplicate()

func current_flags() -> Dictionary:
	return _context_flags()

func last_result() -> Dictionary:
	return _last_result.duplicate(true)

func start_at(scene_id: String) -> Dictionary:
	var index := GateCatalog.scene_ids().find(scene_id)
	if index < 0:
		return {"accepted": false, "reason": "Unknown extended campaign scene: " + scene_id}
	var result := _set_current_scene(index)
	_retry_checkpoint = _checkpoint_snapshot()
	return result

func focus(target_id: String, context: Dictionary = {}) -> Dictionary:
	_register_current_targets()
	return _dispatcher.focus(target_id, _context(context))

func inspect(context: Dictionary = {}) -> Dictionary:
	return _dispatcher.inspect(_context(context))

func use(payload: Dictionary = {}, context: Dictionary = {}) -> Dictionary:
	return _dispatcher.use(payload, _context(context))

func preview(payload_override: Dictionary = {}) -> Dictionary:
	return _dispatcher.preview(payload_override)

func confirm(command_id_override: String = "", payload_override: Dictionary = {}) -> Dictionary:
	var before := _checkpoint_snapshot()
	var result: Dictionary = _dispatcher.confirm(command_id_override, payload_override)
	if bool(result.get("accepted", false)):
		if not bool(result.get("duplicate", false)):
			_retry_checkpoint = before
		_apply_target_result(String(_dispatcher.state().get("focused_target_id", "")))
	_last_result = result.duplicate(true)
	return result

func perform(target_id: String, payload: Dictionary = {}, context: Dictionary = {}) -> Dictionary:
	_register_current_targets()
	var candidates: Array = targets_for_current_scene().filter(func(item): return String(item.get("target_id", "")) == target_id)
	if candidates.is_empty():
		return {"accepted": false, "reason": "Target %s is not part of %s." % [target_id, current_scene_id()]}
	var target: Dictionary = candidates[0]
	var prepared: Dictionary = _payload_for_target(target, payload)
	var trace := {}
	trace["focus"] = focus(target_id, context)
	if not bool(trace.focus.get("accepted", false)):
		return {"accepted": false, "trace": trace, "reason": trace.focus.get("reason", "Focus rejected.")}
	trace["inspect"] = inspect(context)
	if not bool(trace.inspect.get("accepted", false)):
		return {"accepted": false, "trace": trace, "reason": trace.inspect.get("reason", "Inspect rejected.")}
	trace["use"] = use(prepared, context)
	if not bool(trace.use.get("accepted", false)):
		return {"accepted": false, "trace": trace, "reason": trace.use.get("reason", "Use rejected.")}
	trace["preview"] = preview()
	if not bool(trace.preview.get("accepted", false)):
		return {"accepted": false, "trace": trace, "reason": trace.preview.get("reason", "Preview rejected.")}
	trace["confirm"] = confirm()
	var result: Dictionary = trace.confirm
	if not bool(result.get("accepted", false)):
		return {"accepted": false, "trace": trace, "result": result, "reason": result.get("reason", "Commit rejected.")}
	_last_result = {"accepted": true, "trace": trace, "result": result.duplicate(true), "gate": gate_status()}
	return _last_result.duplicate(true)

func acknowledge_dialogue(line_id: String) -> Dictionary:
	if not GateCatalog.dialogue_ids(current_scene_id()).has(line_id):
		return {"accepted": false, "reason": "Dialogue line is not part of the current campaign scene."}
	var command := {
		"command_id": "dialogue:%s" % line_id,
		"issuer": "extended_dialogue",
		"owning_mission_id": current_mission_id(),
		"owning_scene_id": current_scene_id(),
		"expected_state_revision": int(_director.query().get("state_revision", 0)),
		"target_id": line_id,
		"verb": "acknowledge_line",
		"payload": {"line_id": line_id, "dialogue_only": true},
	}
	var result: Dictionary = _director.commit(command)
	if bool(result.get("accepted", false)):
		var acknowledgements: Array = _dialogue_acks[current_scene_id()]
		if not acknowledgements.has(line_id):
			acknowledgements.append(line_id)
		_dialogue_acks[current_scene_id()] = acknowledgements
	return result

func gate_status(scene_id: String = "") -> Dictionary:
	var id := current_scene_id() if scene_id.is_empty() else scene_id
	var flags: Dictionary = _context_flags()
	var missing: Array[String] = []
	for required in GateCatalog.required_physical(id):
		if not bool(flags.get(String(required), false)):
			missing.append(String(required))
	return {
		"scene_id": id,
		"predicate_id": String(GateCatalog.gate(id).get("predicate_id", "")),
		"ready": missing.is_empty(),
		"missing": missing,
		"physical_flags": flags,
		"dialogue_acknowledged": _dialogue_acks.get(id, []).duplicate(),
		"dialogue_can_complete": false,
	}

func advance_scene() -> Dictionary:
	var status: Dictionary = gate_status()
	if not bool(status.get("ready", false)):
		return {"accepted": false, "reason": "Physical campaign scene gate is incomplete.", "missing": status.get("missing", [])}
	var scene_id := current_scene_id()
	var command := {
		"command_id": "scene-complete:%s" % scene_id,
		"issuer": "extended_campaign_route",
		"owning_mission_id": current_mission_id(),
		"owning_scene_id": scene_id,
		"expected_state_revision": int(_director.query().get("state_revision", 0)),
		"target_id": String(status.get("predicate_id", scene_id)),
		"verb": "set_phase",
		"payload": {"phase": "scene_complete:" + scene_id, "physical_gate": true},
	}
	var receipt: Dictionary = _director.commit(command)
	if not bool(receipt.get("accepted", false)):
		return receipt
	if not _completed_scene_ids.has(scene_id):
		_completed_scene_ids.append(scene_id)
	var chapter := int(scene_id.substr(5, 2))
	var order := int(scene_id.substr(9, 2))
	if order == 12:
		return {"accepted": true, "scene_completed": scene_id, "chapter_complete": true, "campaign_complete": chapter == 8, "completed_scene_ids": completed_scene_ids()}
	_scene_index += 1
	var moved: Dictionary = _set_current_scene(_scene_index)
	_retry_checkpoint = _checkpoint_snapshot()
	return {"accepted": true, "scene_completed": scene_id, "next_scene": current_scene_id(), "transition": moved, "completed_scene_ids": completed_scene_ids()}

func chapter_ready() -> Dictionary:
	var scene_id := current_scene_id()
	var chapter := int(scene_id.substr(5, 2))
	var complete := _completed_scene_ids.has(scene_id)
	return {
		"ready": complete,
		"ending": "CAMPAIGN_COMPLETE" if chapter == 8 and complete else "CHAPTER_%02d_COMPLETE" % chapter if complete else "",
		"completed_scene_count": _completed_scene_ids.size(),
		"reason": "This chapter requires every physical scene gate; dialogue acknowledgement never completes a gate.",
	}

func snapshot() -> Dictionary:
	return {
		"retry_checkpoint": _retry_checkpoint.duplicate(true),
		"schema_version": 1,
		"current_scene_id": current_scene_id(),
		"current_scene_index": _scene_index,
		"completed_scene_ids": _completed_scene_ids.duplicate(),
		"scene_flags": _scene_flags.duplicate(true),
		"dialogue_acks": _dialogue_acks.duplicate(true),
		"ledger": _ledger.snapshot(),
		"world": _world.snapshot(),
		"chapter_ready": chapter_ready(),
	}

func restore(data: Dictionary) -> Dictionary:
	var staged := _stage(data)
	if not bool(staged.get("accepted", false)):
		return staged
	var checkpoint: Dictionary = data.get("retry_checkpoint", {})
	if not checkpoint.is_empty():
		var nested := _stage(checkpoint.route)
		if not bool(nested.get("accepted", false)):
			return nested
	_world = staged.world
	_ledger = staged.ledger
	_scene_index = GateCatalog.scene_ids().find(data.current_scene_id)
	_completed_scene_ids = data.completed_scene_ids.duplicate()
	_scene_flags = data.scene_flags.duplicate(true)
	_dialogue_acks = data.dialogue_acks.duplicate(true)
	_retry_checkpoint = checkpoint.duplicate(true)
	_register_current_targets()
	return {"accepted": true, "reason": "Extended campaign route restored from primitive state."}

## Restores a snapshot into temporary world and ledger objects; live state is untouched.
func _stage(data: Dictionary) -> Dictionary:
	var fields := _validate_route_fields(data, GateCatalog.scene_ids())
	if not bool(fields.get("accepted", false)):
		return fields
	if not data.get("ledger", null) is Dictionary:
		return {"accepted": false, "reason": "Extended route snapshot requires its puzzle ledger."}
	var world: RefCounted = WorldRouteScript.new(_director)
	var ledger: RefCounted = LedgerScript.new()
	for restored in [world.restore(data.world), ledger.restore(data.ledger)]:
		if not bool(restored.get("accepted", false)):
			return restored
	return {"accepted": true, "world": world, "ledger": ledger}

func _set_current_scene(index: int) -> Dictionary:
	var scene_ids: Array = GateCatalog.scene_ids()
	_scene_index = clampi(index, 0, scene_ids.size() - 1)
	var result: Dictionary = _world.set_scene(current_scene_id(), {"authored_viewpoint_cut": true, "label": "CAMPAIGN SCENE CARD"})
	if not bool(result.get("accepted", false)):
		return result
	_register_current_targets()
	return result

func _register_current_targets() -> void:
	_dispatcher.clear_targets()
	_dispatcher.register_targets(targets_for_current_scene())

func _context(extra: Dictionary = {}) -> Dictionary:
	var context := {"room_id": _world.current_room_id(), "line_of_sight": true, "distance_m": 0.0, "flags": _context_flags()}
	for key in extra.keys():
		context[key] = extra[key]
	return context

func _context_flags() -> Dictionary:
	var result: Dictionary = {}
	for scene_flags in _scene_flags.values():
		if scene_flags is Dictionary:
			for flag in scene_flags.keys():
				if bool(scene_flags[flag]):
					result[String(flag)] = true
	for flag in _ledger.flags().keys():
		result[String(flag)] = _ledger.flags()[flag]
	return result

func _payload_for_target(target: Dictionary, override: Dictionary) -> Dictionary:
	var payload: Dictionary = target.get("payload_defaults", {}).duplicate(true) if target.get("payload_defaults", {}) is Dictionary else {}
	for key in override.keys():
		payload[key] = override[key]
	if target.has("puzzle_action"):
		payload["_puzzle_action"] = String(target.get("puzzle_action", ""))
	return payload

func _submit_command(command: Dictionary, preview_only: bool) -> Dictionary:
	var puzzle_id := String(command.get("target_id", ""))
	var payload: Dictionary = command.get("payload", {}) if command.get("payload", {}) is Dictionary else {}
	var action := String(payload.get("_puzzle_action", ""))
	var ledger_preview: Dictionary = _ledger.preview(puzzle_id, action, payload)
	if not bool(ledger_preview.get("accepted", false)):
		return _puzzle_reject(String(ledger_preview.get("reason", "Puzzle action rejected.")))
	if preview_only:
		return _director.preview(command)
	var committed: Dictionary = _director.commit(command)
	if not bool(committed.get("accepted", false)):
		return committed
	var ledger_commit: Dictionary = _ledger.commit(puzzle_id, action, payload)
	if not bool(ledger_commit.get("accepted", false)):
		return _puzzle_reject(String(ledger_commit.get("reason", "Puzzle receipt could not be recorded.")))
	return committed

func _apply_target_result(target_id: String) -> void:
	var targets: Array = targets_for_current_scene().filter(func(item): return String(item.get("target_id", "")) == target_id)
	if targets.is_empty():
		return
	var target: Dictionary = targets[0]
	var flag := String(target.get("physical_flag", ""))
	if flag.is_empty():
		return
	var flags: Dictionary = _scene_flags.get(current_scene_id(), {})
	flags[flag] = true
	_scene_flags[current_scene_id()] = flags

func _puzzle_reject(reason: String) -> Dictionary:
	var result: Dictionary = ResultScript.empty(int(_director.query().get("state_revision", 0)), "planning")
	result["reason"] = reason
	result["snapshot"] = _director.snapshot()
	return result
