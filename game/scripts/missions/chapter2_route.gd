extends RefCounted
class_name Chapter2Route

const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const DispatcherScript = preload("res://scripts/interactions/interaction_dispatcher.gd")
const WorldRouteScript = preload("res://scripts/world/world_route.gd")
const GateCatalog = preload("res://scripts/missions/chapter2_gate_catalog.gd")
const P03Script = preload("res://scripts/puzzles/p03_pollination.gd")
const P04Script = preload("res://scripts/puzzles/p04_recorder_reconstruction.gd")
const ResultScript = preload("res://scripts/core/command_result.gd")

var _director: RefCounted
var _world: RefCounted
var _dispatcher: RefCounted
var _p03: RefCounted
var _p04: RefCounted
var _scene_index := 0
var _scene_flags := {}
var _dialogue_acks := {}
var _completed_scene_ids: Array = []
var _last_result := {}

func _init(director: RefCounted = null) -> void:
	_director = director if director != null else DirectorScript.new()
	_world = WorldRouteScript.new(_director)
	_dispatcher = DispatcherScript.new(_director, Callable(self, "_submit_command"))
	_p03 = P03Script.new()
	_p04 = P04Script.new()
	for scene_id in GateCatalog.scene_ids():
		_scene_flags[scene_id] = {}
		_dialogue_acks[scene_id] = []
	_set_current_scene(0)

func director() -> RefCounted: return _director
func world() -> RefCounted: return _world
func dispatcher() -> RefCounted: return _dispatcher
func current_scene_id() -> String: return String(GateCatalog.SCENE_ORDER[_scene_index])
func current_mission_id() -> String: return String(GateCatalog.gate(current_scene_id()).get("mission_id", ""))
func current_room_id() -> String: return String(GateCatalog.gate(current_scene_id()).get("room_id", "LOC-01"))
func completed_scene_ids() -> Array: return _completed_scene_ids.duplicate()
func last_result() -> Dictionary: return _last_result.duplicate(true)
func current_flags() -> Dictionary: return _context_flags()

func start_at(scene_id: String) -> Dictionary:
	var index := GateCatalog.SCENE_ORDER.find(scene_id)
	if index < 0: return {"accepted": false, "reason": "Unknown Chapter 2 scene: " + scene_id}
	_scene_index = index
	return _set_current_scene(index)

func begin() -> Dictionary:
	if _completed_scene_ids.is_empty() and not bool(_director.snapshot().get("chapter1_ready", false)):
		return {"accepted": false, "status": "blocked", "reason": "Chapter 1 Bloom/Golden readiness is required before Chapter 2."}
	return start_at("EX-CH02-S01")

func focus(target_id: String, context: Dictionary = {}) -> Dictionary:
	_register_current_targets()
	return _dispatcher.focus(target_id, _context(context))

func inspect(context: Dictionary = {}) -> Dictionary: return _dispatcher.inspect(_context(context))
func use(payload: Dictionary = {}, context: Dictionary = {}) -> Dictionary: return _dispatcher.use(payload, _context(context))
func preview(payload_override: Dictionary = {}) -> Dictionary: return _dispatcher.preview(payload_override)

func confirm(command_id_override: String = "", payload_override: Dictionary = {}) -> Dictionary:
	var result: Dictionary = _dispatcher.confirm(command_id_override, payload_override)
	if bool(result.get("accepted", false)):
		_apply_target_result(String(_dispatcher.state().get("focused_target_id", "")), result)
	_last_result = result.duplicate(true)
	return result

func perform(target_id: String, payload: Dictionary = {}, context: Dictionary = {}) -> Dictionary:
	_register_current_targets()
	var candidates: Array = GateCatalog.targets_for_scene(current_scene_id()).filter(func(item): return String(item.get("target_id", "")) == target_id)
	if candidates.is_empty(): return {"accepted": false, "reason": "Target %s is not part of %s." % [target_id, current_scene_id()]}
	var target: Dictionary = candidates[0]
	var prepared := _payload_for_target(target, payload)
	var trace := {}
	trace["focus"] = focus(target_id, context)
	if not bool(trace.focus.get("accepted", false)): return {"accepted": false, "trace": trace, "reason": trace.focus.get("reason", "Focus rejected.")}
	trace["inspect"] = inspect(context)
	if not bool(trace.inspect.get("accepted", false)): return {"accepted": false, "trace": trace, "reason": trace.inspect.get("reason", "Inspect rejected.")}
	trace["use"] = use(prepared, context)
	if not bool(trace.use.get("accepted", false)): return {"accepted": false, "trace": trace, "reason": trace.use.get("reason", "Use rejected.")}
	trace["preview"] = preview()
	if not bool(trace.preview.get("accepted", false)): return {"accepted": false, "trace": trace, "reason": trace.preview.get("reason", "Preview rejected.")}
	trace["confirm"] = confirm()
	var result: Dictionary = trace.confirm
	if not bool(result.get("accepted", false)): return {"accepted": false, "trace": trace, "result": result, "reason": result.get("reason", "Commit rejected.")}
	_last_result = {"accepted": true, "trace": trace, "result": result.duplicate(true), "gate": gate_status()}
	return _last_result.duplicate(true)

func acknowledge_dialogue(line_id: String) -> Dictionary:
	if not GateCatalog.dialogue_ids(current_scene_id()).has(line_id): return {"accepted": false, "reason": "Dialogue line is not part of the current Chapter 2 scene."}
	var command := {"command_id": "dialogue:%s" % line_id, "issuer": "chapter2_dialogue", "owning_mission_id": current_mission_id(), "owning_scene_id": current_scene_id(), "expected_state_revision": int(_director.query().get("state_revision", 0)), "target_id": line_id, "verb": "acknowledge_line", "payload": {"line_id": line_id, "dialogue_only": true}}
	var result: Dictionary = _director.commit(command)
	if bool(result.get("accepted", false)):
		var acknowledgements: Array = _dialogue_acks[current_scene_id()]
		if not acknowledgements.has(line_id): acknowledgements.append(line_id)
		_dialogue_acks[current_scene_id()] = acknowledgements
	return result

func gate_status(scene_id: String = "") -> Dictionary:
	var id := current_scene_id() if scene_id.is_empty() else scene_id
	var missing: Array[String] = []
	var flags := _context_flags()
	for required in GateCatalog.required_physical(id):
		if not bool(flags.get(String(required), false)): missing.append(String(required))
	return {"scene_id": id, "predicate_id": String(GateCatalog.gate(id).get("predicate_id", "")), "ready": missing.is_empty(), "missing": missing, "physical_flags": flags, "dialogue_acknowledged": _dialogue_acks.get(id, []).duplicate(), "dialogue_can_complete": false}

func advance_scene() -> Dictionary:
	var status := gate_status()
	if not bool(status.get("ready", false)): return {"accepted": false, "reason": "Physical Chapter 2 scene gate is incomplete.", "missing": status.get("missing", [])}
	var scene_id := current_scene_id()
	var command := {"command_id": "scene-complete:%s" % scene_id, "issuer": "chapter2_route", "owning_mission_id": current_mission_id(), "owning_scene_id": scene_id, "expected_state_revision": int(_director.query().get("state_revision", 0)), "target_id": String(status.get("predicate_id", scene_id)), "verb": "set_phase", "payload": {"phase": "scene_complete:" + scene_id, "physical_gate": true}}
	var receipt: Dictionary = _director.commit(command)
	if not bool(receipt.get("accepted", false)): return receipt
	if not _completed_scene_ids.has(scene_id): _completed_scene_ids.append(scene_id)
	if _scene_index >= GateCatalog.SCENE_ORDER.size() - 1: return {"accepted": true, "scene_completed": scene_id, "chapter_complete": true, "completed_scene_ids": completed_scene_ids()}
	_scene_index += 1
	var moved: Dictionary = _set_current_scene(_scene_index)
	return {"accepted": true, "scene_completed": scene_id, "next_scene": current_scene_id(), "transition": moved, "completed_scene_ids": completed_scene_ids()}

func chapter_ready() -> Dictionary:
	var complete := _completed_scene_ids.size() == GateCatalog.SCENE_ORDER.size() and bool(_p04.flags().get("p04_complete", false))
	return {"ready": complete, "completed_scene_count": _completed_scene_ids.size(), "reason": "Chapter 2 readiness requires all twelve physical scene gates, three reciprocal pollen runs, seven care dates and the reconstructed recorder copy."}

func snapshot() -> Dictionary:
	return {"schema_version": 1, "current_scene_id": current_scene_id(), "current_scene_index": _scene_index, "completed_scene_ids": _completed_scene_ids.duplicate(), "scene_flags": _scene_flags.duplicate(true), "dialogue_acks": _dialogue_acks.duplicate(true), "p03": _p03.snapshot(), "p04": _p04.snapshot(), "world": _world.snapshot(), "chapter_ready": chapter_ready()}

func restore(data: Dictionary) -> Dictionary:
	if not data is Dictionary: return {"accepted": false, "reason": "Chapter 2 route snapshot must be primitive."}
	var scene_id := String(data.get("current_scene_id", ""))
	var index := GateCatalog.SCENE_ORDER.find(scene_id)
	if index < 0: return {"accepted": false, "reason": "Chapter 2 route snapshot names an unknown scene."}
	var world_result: Dictionary = _world.restore(data.get("world", {}))
	if not bool(world_result.get("accepted", false)): return world_result
	_scene_index = index
	_completed_scene_ids = data.get("completed_scene_ids", []).duplicate()
	_scene_flags = data.get("scene_flags", {}).duplicate(true)
	_dialogue_acks = data.get("dialogue_acks", {}).duplicate(true)
	var p03_result: Dictionary = _p03.restore(data.get("p03", {}))
	if not bool(p03_result.get("accepted", false)): return p03_result
	var p04_result: Dictionary = _p04.restore(data.get("p04", {}))
	if not bool(p04_result.get("accepted", false)): return p04_result
	_register_current_targets()
	return {"accepted": true, "reason": "Chapter 2 route restored from primitive mission state."}

func _set_current_scene(index: int) -> Dictionary:
	_scene_index = clampi(index, 0, GateCatalog.SCENE_ORDER.size() - 1)
	var result: Dictionary = _world.set_scene(current_scene_id(), {"authored_viewpoint_cut": true, "label": "CHAPTER 2 SCENE CARD"})
	_register_current_targets()
	return result

func _register_current_targets() -> void:
	_dispatcher.clear_targets()
	_dispatcher.register_targets(GateCatalog.targets_for_scene(current_scene_id()))

func _context(extra: Dictionary = {}) -> Dictionary:
	var context := {"room_id": _world.current_room_id(), "line_of_sight": true, "distance_m": 0.0, "flags": _context_flags()}
	for key in extra.keys(): context[key] = extra[key]
	return context

func _context_flags() -> Dictionary:
	var result: Dictionary = {}
	for scene_flags in _scene_flags.values():
		if scene_flags is Dictionary:
			for flag in scene_flags.keys():
				if bool(scene_flags[flag]): result[String(flag)] = true
	for flag in _p03.flags().keys(): result[String(flag)] = _p03.flags()[flag]
	for flag in _p04.flags().keys(): result[String(flag)] = _p04.flags()[flag]
	return result

func _payload_for_target(target: Dictionary, override: Dictionary) -> Dictionary:
	var payload: Dictionary = target.get("payload_defaults", {}).duplicate(true) if target.get("payload_defaults", {}) is Dictionary else {}
	for key in override.keys(): payload[key] = override[key]
	if target.has("puzzle_action"): payload["_puzzle_action"] = String(target.get("puzzle_action", ""))
	if String(target.get("command_verb", "")) == "apply_delta" and (payload.has("E") or payload.has("A")):
		payload["deltas"] = {"E": int(payload.get("E", 0)), "A": int(payload.get("A", 0))}
	return payload

func _submit_command(command: Dictionary, preview_only: bool) -> Dictionary:
	var puzzle_id := String(command.get("target_id", ""))
	var payload: Dictionary = command.get("payload", {}) if command.get("payload", {}) is Dictionary else {}
	var action := String(payload.get("_puzzle_action", ""))
	if puzzle_id == "P-03":
		var check: Dictionary = _p03.preview_action(action, payload)
		if not bool(check.get("accepted", false)): return _puzzle_reject(check.get("reason", "P-03 rejected."))
		if preview_only: return _director.preview(command)
		var committed: Dictionary = _director.commit(command)
		if bool(committed.get("accepted", false)):
			var applied: Dictionary = _p03.commit_action(action, payload)
			if not bool(applied.get("accepted", false)): return _puzzle_reject(applied.get("reason", "P-03 action could not commit."))
		return committed
	if puzzle_id == "P-04":
		var p04_check: Dictionary = _p04.preview_action(action, payload)
		if not bool(p04_check.get("accepted", false)): return _puzzle_reject(p04_check.get("reason", "P-04 rejected."))
		if preview_only: return _director.preview(command)
		var p04_committed: Dictionary = _director.commit(command)
		if bool(p04_committed.get("accepted", false)):
			var p04_applied: Dictionary = _p04.commit_action(action, payload)
			if not bool(p04_applied.get("accepted", false)): return _puzzle_reject(p04_applied.get("reason", "P-04 action could not commit."))
		return p04_committed
	return _director.preview(command) if preview_only else _director.commit(command)

func _apply_target_result(target_id: String, _result: Dictionary) -> void:
	var targets := GateCatalog.targets_for_scene(current_scene_id()).filter(func(item): return String(item.get("target_id", "")) == target_id)
	if targets.is_empty(): return
	var target: Dictionary = targets[0]
	var flag := String(target.get("physical_flag", ""))
	if not flag.is_empty():
		var flags: Dictionary = _scene_flags.get(current_scene_id(), {})
		flags[flag] = true
		_scene_flags[current_scene_id()] = flags

func _preview_result(reason: String) -> Dictionary:
	var revision := int(_director.query().get("state_revision", 0))
	return {"accepted": true, "duplicate": false, "input_revision": revision, "output_revision": revision, "receipt_id": "", "deltas": [], "events": [{"type": "puzzle_preview", "state_revision": revision}], "warnings": [reason + " · no authoritative state mutation"], "unsafe_predicates": [], "reason": reason, "next_phase": "planning", "snapshot": _director.snapshot()}

func _puzzle_reject(reason: String) -> Dictionary:
	var result := ResultScript.empty(int(_director.query().get("state_revision", 0)), "planning")
	result["reason"] = String(reason)
	result["snapshot"] = _director.snapshot()
	return result
