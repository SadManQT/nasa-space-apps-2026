extends "res://scripts/missions/campaign_route.gd"
class_name ExtendedCampaignRoute

const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const DispatcherScript = preload("res://scripts/interactions/interaction_dispatcher.gd")
const WorldRouteScript = preload("res://scripts/world/world_route.gd")
const GateCatalog = preload("res://scripts/missions/extended_gate_catalog.gd")
const LedgerScript = preload("res://scripts/puzzles/extended_puzzle_ledger.gd")
const ResultScript = preload("res://scripts/core/command_result.gd")
const Chapter8Script = preload("res://scripts/puzzles/chapter8_puzzles.gd")
const ContentScript = preload("res://scripts/content/content_loader.gd")
const ScienceScript = preload("res://scripts/science/science_data.gd")

var _ledger: RefCounted
var _chapter8: RefCounted
var _science: RefCounted
var _scene_index := 0
var _scene_flags := {}
var _dialogue_acks := {}
var _completed_scene_ids: Array = []
var _last_result := {}

func _init(director: RefCounted = null, skip_initial_scene: bool = false) -> void:
	_gate_catalog = GateCatalog
	_director = director if director != null else DirectorScript.new()
	_world = WorldRouteScript.new(_director)
	_create_dispatcher(DispatcherScript)
	_ledger = LedgerScript.new()
	_chapter8 = Chapter8Script.new()
	for scene_id in GateCatalog.scene_ids():
		_scene_flags[scene_id] = {}
		_dialogue_acks[scene_id] = []
	if not skip_initial_scene:
		_set_current_scene(0, false)
		_retry_checkpoint = _checkpoint_snapshot()

func director() -> RefCounted:
	return _director

func world() -> RefCounted:
	return _world

func dispatcher() -> RefCounted:
	return _dispatcher

## The Chapter 8 puzzle model (P-15 and P-16): the player's selections, found
## clues, hints and poll signatures. Presentation reads it; commits go through perform().
func chapter8() -> RefCounted:
	return _chapter8

## Everything the Chapter 8 puzzle panel renders for one operation: the step
## and scene content with canon lines resolved from the dialogue catalog, the
## current selection and its payload attempt, live readings, hints, the poll,
## the mission's data card and whether the step is already committed or
## still waits for an earlier step.
func chapter8_view(target_id: String) -> Dictionary:
	var spec: Dictionary = Chapter8Script.step(target_id)
	if spec.is_empty():
		return {}
	var state: Dictionary = _director.snapshot()
	var scene_id := String(spec.get("scene", ""))
	var scene: Dictionary = Chapter8Script.scene(scene_id)
	var content: Dictionary = ContentScript.load_full()
	var found: Array = _chapter8.found_clues(scene_id)
	var clues: Array = []
	for raw in scene.get("clues", []):
		var clue: Dictionary = raw.duplicate(true)
		var line_id := String(clue.get("line_id", ""))
		if not line_id.is_empty():
			var line: Dictionary = ContentScript.dialogue_by_id(content, line_id)
			clue["speaker"] = String(line.get("speaker_label", line.get("speaker", "")))
			clue["line"] = String(line.get("text", ""))
			clue["origin"] = String(line.get("origin_label", ""))
		var holders: Array = []
		for holder in clue.get("holders", []):
			holders.append(Chapter8Script.role(String(holder)).get("name", String(holder)))
		clue["holder_names"] = holders
		clue["found"] = found.has(String(clue.get("id", "")))
		clues.append(clue)
	var context := chapter8_context(state)
	var attempt: Dictionary = _chapter8.payload_for(target_id, context)
	var puzzle_id := Chapter8Script.puzzle_id_for_step(target_id)
	var mission_id := String(scene.get("mission", current_mission_id()))
	if _science == null:
		_science = ScienceScript.new()
	var prerequisite := ""
	for target in targets_for_current_scene():
		if String(target.get("target_id", "")) == target_id:
			for flag in target.get("required_flags", []):
				if not bool(_context_flags().get(String(flag), false)):
					prerequisite = String(spec.get("prerequisite_text", "Complete the earlier step on this card first."))
	return {
		"target_id": target_id,
		"step": spec,
		"scene": scene,
		"clues": clues,
		"puzzle_id": puzzle_id,
		"puzzle": Chapter8Script.puzzle(puzzle_id),
		"mission_id": mission_id,
		"data_card": _science.mission_card(mission_id),
		"scenario_datetime": String(state.get("scenario_datetime", "")),
		"resources": state.get("resources", {}).duplicate(true),
		"route": state.get("route", {}).duplicate(true),
		"readings": context,
		"selection": _chapter8.selection(target_id),
		"attempt": attempt,
		"hints": _chapter8.revealed_hints(target_id),
		"hints_total": Chapter8Script.hint_ladder(target_id).size(),
		"attempts": _chapter8.attempts(target_id),
		"signed": _chapter8.signed_roles(target_id),
		"committed": _ledger.has_receipt(target_id),
		"prerequisite_reason": prerequisite,
		"first_time": not _chapter8.first_time_seen(puzzle_id),
	}

## Live readings the Chapter 8 panel shows beside the decision and that some
## payloads must carry (rover energy and allowance for the reserve arithmetic).
func chapter8_context(state: Dictionary = {}) -> Dictionary:
	if state.is_empty():
		state = _director.snapshot()
	var route: Dictionary = state.get("route", {})
	var inventories: Dictionary = state.get("inventories", {})
	var resources: Dictionary = state.get("resources", {})
	var cotton_alive := false
	for plant in state.get("plants", []):
		if plant is Dictionary and String(plant.get("individual_id", "")) == "COTTON-01":
			cotton_alive = bool(plant.get("alive", false))
	return {
		"energy": float(route.get("energy", 0)),
		"capacity": float(route.get("capacity", route.get("energy", 0))),
		"allowance": float(route.get("allowance", 0)),
		"return_reserve": float(route.get("return_reserve", 0)),
		"provisions": float(route.get("provisions", 0)),
		"elapsed_hours": float(route.get("elapsed_hours", 0)),
		"local_hops": (route.get("local_hops", []) as Array).size(),
		"earth_leg": String(route.get("earth_leg", "unverified")),
		"brake_set": bool(route.get("brake_set", false)),
		"crew_home": int(route.get("crew_home", 2)),
		"reserve30": int(inventories.get("reserve30", 0)),
		"vault_stored": int(inventories.get("vault12", {}).get("stored", 0)),
		"pressure": bool(state.get("garden_pressure_stable", false)),
		"temperature": float(resources.get("H", 0)) > 0 and float(resources.get("C", 0)) > 0,
		"cotton": cotton_alive,
		"seeds": int(inventories.get("reserve30", 0)) == 30 and int(inventories.get("vault12", {}).get("stored", 0)) == 11,
	}

## Runs the real read-only preview for a Chapter 8 operation with the player's
## payload: the same ledger check and campaign simulation that commit uses.
## Returns the dispatcher preview plus before/after readings the panel shows.
func chapter8_preview(target_id: String, payload: Dictionary) -> Dictionary:
	if bool(_director.query().get("paused", false)):
		# The HUD pauses the expedition while a card is open. Project on a
		# restored copy instead, exactly as the runtime's forecast does.
		var state: Dictionary = _director.snapshot()
		state["paused"] = false
		var copy_director: RefCounted = DirectorScript.new()
		var restored: Dictionary = copy_director.restore_snapshot(state)
		if not bool(restored.get("accepted", false)):
			return {"accepted": false, "reason": String(restored.get("reason", "Forecast unavailable."))}
		var copy: RefCounted = get_script().new(copy_director, true)
		var local: Dictionary = snapshot()
		local["retry_checkpoint"] = {}
		var route_restored: Dictionary = copy.restore(local)
		if not bool(route_restored.get("accepted", false)):
			return {"accepted": false, "reason": String(route_restored.get("reason", "Forecast unavailable."))}
		return copy.chapter8_preview(target_id, payload)
	_register_current_targets()
	var candidates: Array = targets_for_current_scene().filter(func(item): return String(item.get("target_id", "")) == target_id)
	if candidates.is_empty():
		return {"accepted": false, "reason": "This operation is not part of the current scene."}
	var before: Dictionary = _director.snapshot()
	var focused := focus(target_id)
	if not bool(focused.get("accepted", false)):
		return {"accepted": false, "reason": String(focused.get("reason", "Focus rejected.")), "unmet": true}
	var inspected := inspect()
	if not bool(inspected.get("accepted", false)):
		return {"accepted": false, "reason": String(inspected.get("reason", "Inspect rejected.")), "unmet": true}
	var used := use(_payload_for_target(candidates[0], payload))
	if not bool(used.get("accepted", false)):
		return {"accepted": false, "reason": String(used.get("reason", "Use rejected.")), "unmet": true}
	var result: Dictionary = preview()
	var projected: Dictionary = result.get("snapshot", {}) if result.get("snapshot", {}) is Dictionary else {}
	result["before"] = {"resources": before.get("resources", {}).duplicate(true), "route": before.get("route", {}).duplicate(true), "readings": chapter8_context(before)}
	if bool(result.get("accepted", false)) and projected.has("resources"):
		result["after"] = {"resources": projected.get("resources", {}).duplicate(true), "route": projected.get("route", {}).duplicate(true), "readings": chapter8_context(projected)}
	return result

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
	missing.append_array(_director.campaign_state_predicates(id))
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
		"chapter8": _chapter8.snapshot(),
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
	_chapter8 = staged.chapter8
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
	var chapter8: RefCounted = Chapter8Script.new()
	var restores: Array = [world.restore(data.world), ledger.restore(data.ledger)]
	# Saves written before the Chapter 8 panel existed carry no puzzle state.
	if data.get("chapter8", null) is Dictionary:
		restores.append(chapter8.restore(data.chapter8))
	for restored in restores:
		if not bool(restored.get("accepted", false)):
			return restored
	return {"accepted": true, "world": world, "ledger": ledger, "chapter8": chapter8}

func _set_current_scene(index: int, project_clock: bool = true) -> Dictionary:
	var scene_ids: Array = GateCatalog.scene_ids()
	_scene_index = clampi(index, 0, scene_ids.size() - 1)
	var result: Dictionary = _world.set_scene(current_scene_id(), {"authored_viewpoint_cut": true, "label": "CAMPAIGN SCENE CARD"})
	if not bool(result.get("accepted", false)):
		return result
	if project_clock and bool(result.get("accepted", false)):
		result = _director.project_scene(current_scene_id())
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
	for flag in _chapter8.flags().keys():
		result[String(flag)] = _chapter8.flags()[flag]
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
