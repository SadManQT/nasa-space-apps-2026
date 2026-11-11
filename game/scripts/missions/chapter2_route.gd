extends "res://scripts/missions/campaign_route.gd"
class_name Chapter2Route

const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const DispatcherScript = preload("res://scripts/interactions/interaction_dispatcher.gd")
const WorldRouteScript = preload("res://scripts/world/world_route.gd")
const GateCatalog = preload("res://scripts/missions/chapter2_gate_catalog.gd")
const P03Script = preload("res://scripts/puzzles/p03_pollination.gd")
const P04Script = preload("res://scripts/puzzles/p04_recorder_reconstruction.gd")
const ResultScript = preload("res://scripts/core/command_result.gd")
const PuzzlesScript = preload("res://scripts/puzzles/chapter2_puzzles.gd")
const ContentScript = preload("res://scripts/content/content_loader.gd")
const ScienceScript = preload("res://scripts/science/science_data.gd")

var _p03: RefCounted
var _p04: RefCounted
var _puzzles: RefCounted
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
	_p03 = P03Script.new()
	_p04 = P04Script.new()
	_puzzles = PuzzlesScript.new()
	for scene_id in GateCatalog.scene_ids():
		_scene_flags[scene_id] = {}
		_dialogue_acks[scene_id] = []
	if not skip_initial_scene:
		_set_current_scene(0, false)
		_retry_checkpoint = _checkpoint_snapshot()

func director() -> RefCounted: return _director
func world() -> RefCounted: return _world
func dispatcher() -> RefCounted: return _dispatcher
func current_scene_id() -> String: return String(GateCatalog.SCENE_ORDER[_scene_index])
func current_mission_id() -> String: return String(GateCatalog.gate(current_scene_id()).get("mission_id", ""))
func current_room_id() -> String: return String(GateCatalog.gate(current_scene_id()).get("room_id", "LOC-01"))
func completed_scene_ids() -> Array: return _completed_scene_ids.duplicate()
func last_result() -> Dictionary: return _last_result.duplicate(true)
func current_flags() -> Dictionary: return _context_flags()

## Primitive, read-only handoff for the Chapter 2 decision panel. The route's
## private puzzle objects and their answer keys never cross this boundary.
func puzzle_view(target_id: String) -> Dictionary:
	var target: Dictionary = {}
	for candidate in GateCatalog.targets_for_scene(current_scene_id()):
		if String(candidate.get("target_id", "")) == target_id:
			target = candidate
			break
	var puzzle_id := String(target.get("puzzle_id", ""))
	if puzzle_id not in ["P-03", "P-04"]:
		return {"accepted": false, "reason": "This is not a Chapter 2 puzzle target in the current scene."}
	var action := String(target.get("puzzle_action", ""))
	var required_inputs := _required_inputs(action)
	var progress: Dictionary = _p03.snapshot() if puzzle_id == "P-03" else _p04.snapshot()
	return {"accepted": true, "puzzle_id": puzzle_id, "target_id": target_id,
		"action": action, "scene_id": current_scene_id(), "mission_id": current_mission_id(),
		"room_id": current_room_id(), "focus_label": String(target.get("focus_label", "")),
		"required_inputs": required_inputs, "progress": progress.duplicate(true),
		"gate": gate_status().duplicate(true),
		"input_revision": int(_director.query().get("state_revision", 0))}

func start_at(scene_id: String) -> Dictionary:
	var index := GateCatalog.SCENE_ORDER.find(scene_id)
	if index < 0: return {"accepted": false, "reason": "Unknown Chapter 2 scene: " + scene_id}
	_scene_index = index
	var result := _set_current_scene(index)
	_retry_checkpoint = _checkpoint_snapshot()
	return result

## Dated Chapter 1 -> 2 handoff (08_PUZZLE_DESIGNS P-03 entry): one receipted
## ledger entry moves the resources to the explicit entry profile and the date
## to the profile's morning, whatever the Chapter 1 ending left behind.
func apply_entry_profile() -> Dictionary:
	var profile: Dictionary = P03Script.profile()
	if profile.is_empty():
		return {"accepted": false, "reason": "The P-03 entry profile could not be verified."}
	var resources: Dictionary = _director.snapshot().get("resources", {})
	var deltas := {}
	for key in profile.resources:
		deltas[key] = float(profile.resources[key]) - float(resources.get(key, 0))
	var result: Dictionary = _director.commit({"command_id": "handoff:EX-CH02-entry", "issuer": "chapter2_route", "owning_mission_id": "EX-M0201", "owning_scene_id": "EX-CH02-S01", "expected_state_revision": int(_director.query().get("state_revision", 0)), "target_id": "P-03", "verb": "apply_delta", "payload": {"deltas": deltas, "scenario_datetime": String(profile.scenario_datetime), "ledger": "p03_entry_profile"}})
	if bool(result.get("accepted", false)):
		_retry_checkpoint = _checkpoint_snapshot()
	return result

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
	var frozen: Dictionary = _dispatcher.state()
	if not bool(frozen.get("last_preview", {}).get("accepted", false)):
		return _puzzle_reject("Confirm requires an accepted preview of these choices.")
	var command: Dictionary = frozen.get("last_command", {})
	if not command_id_override.is_empty() and command_id_override != String(command.get("command_id", "")):
		return _puzzle_reject("A Chapter 2 preview cannot change its receipt identity.")
	var preview_payload: Dictionary = command.get("payload", {})
	for key in payload_override:
		if not preview_payload.has(key) or payload_override[key] != preview_payload[key]:
			return _puzzle_reject("Preview these exact choices before confirming.")
	var before := _checkpoint_snapshot()
	var result: Dictionary = _dispatcher.confirm(command_id_override, payload_override)
	if bool(result.get("accepted", false)):
		if not bool(result.get("duplicate", false)):
			_retry_checkpoint = before
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
	_retry_checkpoint = _checkpoint_snapshot()
	return {"accepted": true, "scene_completed": scene_id, "next_scene": current_scene_id(), "transition": moved, "completed_scene_ids": completed_scene_ids()}

func chapter_ready() -> Dictionary:
	var complete := _completed_scene_ids.size() == GateCatalog.SCENE_ORDER.size() and bool(_p04.flags().get("p04_complete", false))
	return {"ready": complete, "completed_scene_count": _completed_scene_ids.size(), "reason": "Chapter 2 readiness requires all twelve physical scene gates, three reciprocal pollen runs, seven care dates and the reconstructed recorder copy."}

func snapshot() -> Dictionary:
	return {"retry_checkpoint": _retry_checkpoint.duplicate(true), "schema_version": 1, "current_scene_id": current_scene_id(), "current_scene_index": _scene_index, "completed_scene_ids": _completed_scene_ids.duplicate(), "scene_flags": _scene_flags.duplicate(true), "dialogue_acks": _dialogue_acks.duplicate(true), "p03": _p03.snapshot(), "p04": _p04.snapshot(), "puzzle_ui": _puzzles.snapshot(), "world": _world.snapshot(), "chapter_ready": chapter_ready()}

func restore(data: Dictionary) -> Dictionary:
	var staged := _stage(data)
	if not bool(staged.get("accepted", false)): return staged
	var checkpoint: Dictionary = data.get("retry_checkpoint", {})
	if not checkpoint.is_empty():
		var nested := _stage(checkpoint.route)
		if not bool(nested.get("accepted", false)): return nested
	_world = staged.world
	_p03 = staged.p03
	_p04 = staged.p04
	_puzzles = staged.puzzles
	_scene_index = GateCatalog.SCENE_ORDER.find(data.current_scene_id)
	_completed_scene_ids = data.completed_scene_ids.duplicate()
	_scene_flags = data.scene_flags.duplicate(true)
	_dialogue_acks = data.dialogue_acks.duplicate(true)
	_retry_checkpoint = checkpoint.duplicate(true)
	_register_current_targets()
	return {"accepted": true, "reason": "Chapter 2 route restored from primitive mission state."}

## Restores a snapshot into temporary world and puzzle objects; live state is untouched.
func _stage(data: Dictionary) -> Dictionary:
	var fields := _validate_route_fields(data, GateCatalog.SCENE_ORDER)
	if not bool(fields.get("accepted", false)): return fields
	if not data.get("p03", null) is Dictionary or not data.get("p04", null) is Dictionary: return {"accepted": false, "reason": "Chapter 2 snapshot requires P-03 and P-04 state."}
	var world: RefCounted = WorldRouteScript.new(_director)
	var p03: RefCounted = P03Script.new()
	var p04: RefCounted = P04Script.new()
	var puzzles: RefCounted = PuzzlesScript.new()
	# Saves made before M3-2P carry no panel state; they resume with a fresh card.
	if data.has("puzzle_ui"):
		if not data.puzzle_ui is Dictionary: return {"accepted": false, "reason": "Chapter 2 panel state must be a Dictionary."}
		var ui: Dictionary = puzzles.restore(data.puzzle_ui)
		if not bool(ui.get("accepted", false)): return ui
	for restored in [world.restore(data.world), p03.restore(data.p03), p04.restore(data.p04)]:
		if not bool(restored.get("accepted", false)): return restored
	return {"accepted": true, "world": world, "p03": p03, "p04": p04, "puzzles": puzzles}

func _set_current_scene(index: int, project_clock: bool = true) -> Dictionary:
	_scene_index = clampi(index, 0, GateCatalog.SCENE_ORDER.size() - 1)
	var result: Dictionary = _world.set_scene(current_scene_id(), {"authored_viewpoint_cut": true, "label": "CHAPTER 2 SCENE CARD"})
	if project_clock and bool(result.get("accepted", false)):
		result = _director.project_scene(current_scene_id())
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

## M3-2P: the panel's own state (selections, filed clues, hints, attempts).
func chapter2_puzzles() -> RefCounted:
	return _puzzles

## Everything the Chapter 2 decision panel renders for one physical step. The
## P-03/P-04 rule models and their answers stay behind this boundary.
func chapter2_view(target_id: String) -> Dictionary:
	var spec: Dictionary = _puzzles.step(target_id)
	if spec.is_empty():
		return {}
	var state: Dictionary = _director.snapshot()
	var scene_id := String(spec.get("scene", ""))
	var scene: Dictionary = _puzzles.scene(scene_id)
	var content: Dictionary = ContentScript.load_full()
	var found: Array = _puzzles.found_clues(scene_id)
	var clues: Array = []
	for raw in scene.get("clues", []):
		var clue: Dictionary = raw.duplicate(true)
		var line_id := String(clue.get("line_id", ""))
		if not line_id.is_empty():
			var line: Dictionary = ContentScript.dialogue_by_id(content, line_id)
			clue["speaker"] = String(line.get("speaker_label", line.get("speaker", "")))
			clue["line"] = String(line.get("text", ""))
		var holders: Array = []
		for holder in clue.get("holders", []):
			holders.append(_puzzles.role(String(holder)).get("name", String(holder)))
		clue["holder_names"] = holders
		clue["found"] = found.has(String(clue.get("id", "")))
		clues.append(clue)
	var puzzle_id: String = _puzzles.puzzle_id_for_step(target_id)
	if _science == null:
		_science = ScienceScript.new()
	var prerequisite := ""
	var current := false
	for target in GateCatalog.targets_for_scene(current_scene_id()):
		if String(target.get("target_id", "")) == target_id:
			current = true
			for flag in target.get("required_flags", []):
				if not bool(_context_flags().get(String(flag), false)):
					prerequisite = String(target.get("unmet_reason", "Complete the earlier step first."))
	if not current:
		prerequisite = "This step belongs to another Chapter 2 scene."
	return {
		"target_id": target_id, "step": spec, "scene": scene, "clues": clues,
		"puzzle_id": puzzle_id, "puzzle": _puzzles.puzzle(puzzle_id),
		"mission_id": String(scene.get("mission", current_mission_id())),
		"data_card": _science.mission_card(String(scene.get("mission", current_mission_id()))),
		"scenario_datetime": String(state.get("scenario_datetime", "")),
		"resources": state.get("resources", {}).duplicate(true),
		"selection": _puzzles.selection(target_id), "attempt": _puzzles.payload_for(target_id),
		"hints": _puzzles.revealed_hints(target_id), "hints_total": _puzzles.hint_ladder(target_id).size(),
		"attempts": _puzzles.attempts(target_id), "signed": [],
		"committed": _step_committed(scene_id, target_id),
		"prerequisite_reason": prerequisite,
		"first_time": not _puzzles.first_time_seen(puzzle_id),
	}

func _step_committed(scene_id: String, target_id: String) -> bool:
	for target in GateCatalog.targets_for_scene(scene_id):
		if String(target.get("target_id", "")) == target_id:
			var flag := String(target.get("physical_flag", ""))
			return bool(_scene_flags.get(scene_id, {}).get(flag, false)) or (scene_id == current_scene_id() and bool(_context_flags().get(flag, false)))
	return false

func _payload_for_target(target: Dictionary, override: Dictionary) -> Dictionary:
	# P-03 and P-04 must receive the player's chosen inputs. Catalog defaults
	# still serve ordinary non-puzzle physical operations in this route.
	var selected_puzzle := String(target.get("puzzle_id", "")) in ["P-03", "P-04"]
	var payload: Dictionary = {} if selected_puzzle else (target.get("payload_defaults", {}).duplicate(true) if target.get("payload_defaults", {}) is Dictionary else {})
	for key in override.keys(): payload[key] = override[key]
	if target.has("puzzle_action"): payload["_puzzle_action"] = String(target.get("puzzle_action", ""))
	if String(target.get("command_verb", "")) == "apply_delta" and (payload.has("E") or payload.has("A")):
		payload["deltas"] = {"E": int(payload.get("E", 0)), "A": int(payload.get("A", 0))}
	return payload

func _submit_command(command: Dictionary, preview_only: bool) -> Dictionary:
	var puzzle_id := String(command.get("target_id", ""))
	var payload: Dictionary = command.get("payload", {}) if command.get("payload", {}) is Dictionary else {}
	var action := String(payload.get("_puzzle_action", ""))
	if puzzle_id in ["P-03", "P-04"]:
		var input_check := _validate_puzzle_command(command, puzzle_id, payload, action)
		if not bool(input_check.get("accepted", false)):
			return _puzzle_reject(String(input_check.get("reason", "Invalid Chapter 2 input.")))
	if puzzle_id == "P-03":
		# Replays return the original receipt before advancing the local puzzle.
		if _director.snapshot().receipts.has(command.command_id):
			return _director.commit(command)
		var check: Dictionary = _p03.preview_action(action, payload)
		if not bool(check.get("accepted", false)): return _puzzle_reject(check.get("reason", "P-03 rejected."))
		command = _p03.ledger_command(command, _director.snapshot())
		if command.is_empty(): return _puzzle_reject("The P-03 resource profile could not be verified.")
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

func _required_inputs(action: String) -> Array[String]:
	var required: Array[String] = []
	if action == "p03_record_prediction":
		required.assign(["prediction", "reason", "future_test"])
	elif action.begins_with("p04_assign_"):
		required.assign(["value"])
	return required

## The dispatcher builds the command, but a caller can supply its payload.
## Bind that payload to the current physical target before either preview or
## commit, including receipt identity and the exact set of player inputs.
func _validate_puzzle_command(command: Dictionary, puzzle_id: String, payload: Dictionary, action: String) -> Dictionary:
	var target: Dictionary = {}
	for candidate in GateCatalog.targets_for_scene(current_scene_id()):
		if String(candidate.get("command_id", "")) == String(command.get("command_id", "")):
			target = candidate
			break
	if target.is_empty() or String(target.get("puzzle_id", "")) != puzzle_id or String(target.get("puzzle_action", "")) != action:
		return {"accepted": false, "reason": "This Chapter 2 command does not match the current physical target."}
	if String(command.get("owning_scene_id", "")) != current_scene_id() or String(command.get("owning_mission_id", "")) != current_mission_id():
		return {"accepted": false, "reason": "The Chapter 2 scene changed. Open this target again."}
	if String(payload.get("phase", "")) != "physical:" + String(target.get("target_id", "")):
		return {"accepted": false, "reason": "This Chapter 2 choice has an invalid physical phase."}
	var allowed: Array[String] = ["_puzzle_action", "phase"]
	for field in _required_inputs(action):
		allowed.append(field)
		if not payload.get(field, null) is String or String(payload[field]).strip_edges().is_empty():
			return {"accepted": false, "reason": "Choose %s before previewing." % field.replace("_", " ")}
	for key in payload.keys():
		if not allowed.has(String(key)):
			return {"accepted": false, "reason": "This Chapter 2 choice contains an unsupported input."}
	return {"accepted": true}

func _apply_target_result(target_id: String, _result: Dictionary) -> void:
	var targets := GateCatalog.targets_for_scene(current_scene_id()).filter(func(item): return String(item.get("target_id", "")) == target_id)
	if targets.is_empty(): return
	var target: Dictionary = targets[0]
	var flag := String(target.get("physical_flag", ""))
	if not flag.is_empty():
		var flags: Dictionary = _scene_flags.get(current_scene_id(), {})
		flags[flag] = true
		_scene_flags[current_scene_id()] = flags

func _puzzle_reject(reason: String) -> Dictionary:
	var result := ResultScript.empty(int(_director.query().get("state_revision", 0)), "planning")
	result["reason"] = String(reason)
	result["snapshot"] = _director.snapshot()
	return result
