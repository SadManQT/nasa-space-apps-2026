extends RefCounted
class_name Chapter1Route

const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const DispatcherScript = preload("res://scripts/interactions/interaction_dispatcher.gd")
const WorldRouteScript = preload("res://scripts/world/world_route.gd")
const GateCatalog = preload("res://scripts/missions/chapter1_gate_catalog.gd")
const P01Script = preload("res://scripts/missions/p01_commission_plant.gd")
const PuzzleHostScript = preload("res://scripts/puzzles/puzzle_host.gd")
const StateScript = preload("res://scripts/core/campaign_state.gd")

## Chapter 1 mission composition and physical-gate adapter.
##
## The route has one scene order and one interaction dispatcher. Physical
## actions produce frozen commands; only accepted CampaignDirector results can
## mark a physical flag. Dialogue acknowledgements are recorded separately and
## never satisfy a scene gate.

var _director: RefCounted
var _world: RefCounted
var _dispatcher: RefCounted
var _p01: RefCounted
var _scene_index := 0
var _scene_flags := {}
var _dialogue_acks := {}
var _completed_scene_ids: Array = []
var _p02_hosts := {}
var _last_result := {}
var _ending := ""
var _retry_checkpoint := {}

func _init(director: RefCounted = null) -> void:
	_director = director if director != null else DirectorScript.new()
	_world = WorldRouteScript.new(_director)
	_dispatcher = DispatcherScript.new(_director, Callable(self, "_submit_command"))
	_p01 = P01Script.new()
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
	return String(GateCatalog.SCENE_ORDER[_scene_index])

func current_mission_id() -> String:
	return String(GateCatalog.gate(current_scene_id()).get("mission_id", ""))

func current_room_id() -> String:
	return String(GateCatalog.gate(current_scene_id()).get("room_id", "LOC-01"))

func completed_scene_ids() -> Array:
	return _completed_scene_ids.duplicate()

func current_flags() -> Dictionary:
	return _scene_flags.get(current_scene_id(), {}).duplicate(true)

func last_result() -> Dictionary:
	return _last_result.duplicate(true)

func start_at(scene_id: String) -> Dictionary:
	var index := GateCatalog.SCENE_ORDER.find(scene_id)
	if index < 0:
		return {"accepted": false, "reason": "Unknown Chapter 1 scene: " + scene_id}
	_scene_index = index
	_set_current_scene(_scene_index)
	return {"accepted": true, "scene_id": scene_id, "room_id": current_room_id()}

func focus(target_id: String, context: Dictionary = {}) -> Dictionary:
	_register_current_targets()
	return _dispatcher.focus(target_id, _context(context))

func inspect(context: Dictionary = {}) -> Dictionary:
	return _dispatcher.inspect(_context(context))

func use(payload: Dictionary = {}, context: Dictionary = {}) -> Dictionary:
	var target: Dictionary = _dispatcher.target(String(_dispatcher.state().get("focused_target_id", "")))
	return _dispatcher.use(_payload_for_target(target, payload), _context(context))

func preview(payload_override: Dictionary = {}) -> Dictionary:
	return _dispatcher.preview(payload_override)

func confirm(command_id_override: String = "", payload_override: Dictionary = {}) -> Dictionary:
	var before := _checkpoint_snapshot()
	var target_id := String(_dispatcher.state().get("focused_target_id", ""))
	var result: Dictionary = _dispatcher.confirm(command_id_override, payload_override)
	if bool(result.get("accepted", false)):
		if not bool(result.get("duplicate", false)) and (target_id.begins_with("p02_") or int(before.director.get("current_shift", 0)) == 0):
			_retry_checkpoint = before
		var frozen: Dictionary = _dispatcher.state().get("last_command", {}).get("payload", {}).duplicate(true)
		for key in payload_override:
			frozen[key] = payload_override[key]
		_apply_target_result(target_id, frozen, result)
	_last_result = result.duplicate(true)
	return result

func perform(target_id: String, payload: Dictionary = {}, context: Dictionary = {}) -> Dictionary:
	_register_current_targets()
	var spec := GateCatalog.targets_for_scene(current_scene_id()).filter(func(item): return String(item.get("target_id", "")) == target_id)
	if spec.is_empty():
		return {"accepted": false, "reason": "Target %s is not part of %s." % [target_id, current_scene_id()]}
	var target: Dictionary = spec[0]
	var special_check := _special_target_prerequisite(target_id)
	if not bool(special_check.get("accepted", false)):
		return special_check
	var prepared := _payload_for_target(target, payload)
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
	if target_id == "p02_stage_shift2":
		trace["preview"] = preview({})
		if bool(trace.preview.get("accepted", false)):
			_mark_flag("shift2_preview_staged")
			var pause_result: Dictionary = _dispatcher.pause("shift-2-preview-read")
			_mark_flag("paused_before_drill") if bool(pause_result.get("accepted", false)) else null
			_dispatcher.resume()
			_dispatcher.cancel("preview staged; no shift committed")
			trace["pause"] = pause_result
			_last_result = {"accepted": bool(trace.preview.get("accepted", false)), "preview": trace.preview, "trace": trace, "physical_commit": false}
			return _last_result.duplicate(true)
		return {"accepted": false, "trace": trace, "reason": trace.preview.get("reason", "Shift 2 forecast rejected.")}
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
	var allowed: Array = GateCatalog.dialogue_ids(current_scene_id())
	if not allowed.has(line_id):
		return {"accepted": false, "reason": "Dialogue line is not part of the current scene."}
	var command := {
		"command_id": "dialogue:%s" % line_id,
		"issuer": "campaign_dialogue",
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
		result["completes_predicate"] = false
		result["physical_gate_changed"] = false
	return result

func gate_status(scene_id: String = "") -> Dictionary:
	var id := current_scene_id() if scene_id.is_empty() else scene_id
	var required: Array = GateCatalog.required_physical(id)
	var missing: Array[String] = []
	for flag in required:
		if not _flag_is_set(String(flag)):
			missing.append(String(flag))
	if id in ["EX-CH01-S11", "EX-CH01-S12"] and not bool(chapter_ready().get("safe_ending", false)):
		missing.append("safe_night_completed")
	return {
		"scene_id": id,
		"predicate_id": String(GateCatalog.gate(id).get("predicate_id", "")),
		"ready": missing.is_empty(),
		"missing": missing,
		"physical_flags": _context_flags(),
		"dialogue_acknowledged": _dialogue_acks.get(id, []).duplicate(),
		"dialogue_can_complete": false,
	}

func advance_scene() -> Dictionary:
	var status := gate_status()
	if not bool(status.get("ready", false)):
		return {"accepted": false, "reason": "Physical scene gate is incomplete.", "missing": status.get("missing", [])}
	var scene_id := current_scene_id()
	var before := _checkpoint_snapshot()
	var completion_command := {
		"command_id": "scene-complete:%s" % scene_id,
		"issuer": "chapter1_route",
		"owning_mission_id": current_mission_id(),
		"owning_scene_id": scene_id,
		"expected_state_revision": int(_director.query().get("state_revision", 0)),
		"target_id": String(status.get("predicate_id", scene_id)),
		"verb": "set_phase",
		"payload": {"phase": "scene_complete:" + scene_id, "physical_gate": true},
	}
	var next_dates := {"EX-CH01-S01": "2046-04-11 07:00 UTC", "EX-CH01-S02": "2046-04-11 10:00 UTC"}
	if next_dates.has(scene_id):
		completion_command.payload["scenario_datetime"] = next_dates[scene_id]
	var receipt: Dictionary = _director.commit(completion_command)
	if not bool(receipt.get("accepted", false)):
		return receipt
	if int(before.director.get("current_shift", 0)) == 0 and not bool(receipt.get("duplicate", false)):
		_retry_checkpoint = before
	if not _completed_scene_ids.has(scene_id):
		_completed_scene_ids.append(scene_id)
	if _scene_index >= GateCatalog.SCENE_ORDER.size() - 1:
		return {"accepted": true, "scene_completed": scene_id, "chapter_complete": true, "completed_scene_ids": completed_scene_ids()}
	_scene_index += 1
	var moved := _set_current_scene(_scene_index)
	return {"accepted": true, "scene_completed": scene_id, "next_scene": current_scene_id(), "transition": moved, "completed_scene_ids": completed_scene_ids()}

func retry() -> Dictionary:
	if _retry_checkpoint.is_empty():
		return {"accepted": false, "reason": "No physical retry checkpoint is available."}
	var director_result: Dictionary = _director.restore_snapshot(_retry_checkpoint.director)
	if not bool(director_result.get("accepted", false)):
		return director_result
	_restore_local(_retry_checkpoint.route)
	_p02_hosts.clear()
	return {"accepted": true, "director": director_result, "route": snapshot(), "reason": "Last physical checkpoint restored; no scene/dialogue receipt was duplicated."}

func pause(reason: String = "route_pause") -> Dictionary:
	return _dispatcher.pause(reason)

func resume() -> Dictionary:
	return _dispatcher.resume()

func cancel_interaction(reason: String = "user") -> Dictionary:
	return _dispatcher.cancel(reason)

func chapter_ready() -> Dictionary:
	var resources: Dictionary = _director.snapshot().get("resources", {})
	var safe_ending := _ending in ["BLOOM", "GOLDEN"] and int(resources.get("H", 0)) > 0 and int(resources.get("A", 0)) > 0 and int(resources.get("Z", 0)) <= 3 and String(_director.query().get("status", "")) != "mission_stopped" and int(_director.query().get("current_shift", 0)) == 7
	var complete := _completed_scene_ids.size() == GateCatalog.SCENE_ORDER.size() and safe_ending and bool(_scene_flags["EX-CH01-S12"].get("debrief_complete", false))
	return {"ready": complete, "ending": _ending, "safe_ending": safe_ending, "completed_scene_count": _completed_scene_ids.size(), "reason": "CH02 readiness requires all twelve physical scene gates and a living Alo Bloom/Golden result."}

func snapshot() -> Dictionary:
	var result := _local_snapshot()
	result["schema_version"] = 1
	result["chapter_ready"] = chapter_ready()
	result["retry_checkpoint"] = _retry_checkpoint.duplicate(true)
	return result

func restore(snapshot_data: Dictionary) -> Dictionary:
	var valid := _validate_local_snapshot(snapshot_data)
	if not bool(valid.get("accepted", false)):
		return valid
	var retry_value = snapshot_data.get("retry_checkpoint", {})
	if not retry_value is Dictionary:
		return {"accepted": false, "reason": "Route retry checkpoint must be a Dictionary."}
	if not retry_value.is_empty():
		if not retry_value.get("director", null) is Dictionary or not retry_value.get("route", null) is Dictionary or not StateScript.is_compatible(retry_value.director):
			return {"accepted": false, "reason": "Route retry checkpoint has an invalid campaign state."}
		valid = _validate_local_snapshot(retry_value.route)
		if not bool(valid.get("accepted", false)):
			return valid
	_restore_local(snapshot_data)
	_retry_checkpoint = retry_value.duplicate(true) if not retry_value.is_empty() else _checkpoint_snapshot()
	_p02_hosts.clear()
	return {"accepted": true, "reason": "Chapter 1 route restored from primitive room/mission state."}

func _set_current_scene(index: int) -> Dictionary:
	_scene_index = clampi(index, 0, GateCatalog.SCENE_ORDER.size() - 1)
	var scene_id := current_scene_id()
	var route_result: Dictionary = _world.set_scene(scene_id, {"authored_viewpoint_cut": true, "label": "CHAPTER 1 SCENE CARD"})
	_register_current_targets()
	return route_result

func _register_current_targets() -> void:
	_dispatcher.clear_targets()
	_dispatcher.register_targets(GateCatalog.targets_for_scene(current_scene_id()))

func _context(extra: Dictionary = {}) -> Dictionary:
	var context := {
		"room_id": _world.current_room_id(),
		"line_of_sight": true,
		"distance_m": 0.0,
		"flags": _context_flags(),
		"airlock_ready": bool(_world.boundary_state("airlock_exterior").get("airlock_ready", false)),
		"suit_check": bool(_world.boundary_state("airlock_exterior").get("suit_check", false)),
	}
	for key in extra.keys():
		if key != "flags":
			context[key] = extra[key]
	return context

func _context_flags() -> Dictionary:
	var result: Dictionary = {}
	# Physical evidence remains valid after its owning scene is complete. S08
	# intentionally reuses the S02 roll-call receipt.
	for scene_flags in _scene_flags.values():
		if scene_flags is Dictionary:
			for flag in scene_flags.keys():
				if bool(scene_flags[flag]):
					result[String(flag)] = true
	var p01_state: Dictionary = _p01.snapshot()
	result["p01_zeroed"] = bool(p01_state.get("probe_zeroed", false))
	result["p01_spanned"] = bool(p01_state.get("probe_spanned", false))
	result["p01_rechecked"] = bool(p01_state.get("probe_rechecked", false))
	result["p01_scanned"] = bool(p01_state.get("packet_scanned", false))
	result["p01_complete"] = bool(_p01.completion().get("complete", false))
	return result

func _flag_is_set(flag: String) -> bool:
	return bool(_context_flags().get(flag, false))

func _payload_for_target(target: Dictionary, payload: Dictionary) -> Dictionary:
	var result := payload.duplicate(true)
	if target.has("puzzle_action"):
		result["_puzzle_action"] = String(target.get("puzzle_action", ""))
	if target.has("puzzle_id") and String(target.get("puzzle_id", "")) == "P-02" and not result.has("plan"):
		result["plan"] = _default_plan(String(target.get("command_id", "")))
	return result

func _special_target_prerequisite(target_id: String) -> Dictionary:
	var requirements := {
		"p02_shift1": ["role_acknowledged"],
		"p02_stage_shift2": ["shift1_committed"],
		"p02_shift2": ["shelter_drill_complete", "pre_drill_baseline_verified"],
		"p02_shifts3_4": ["shift2_committed_at_18", "cards_combined", "earth_set_acknowledged"],
		"p02_shift5_alarm": ["shifts3_4_resolved", "four_sheltered"],
		"p02_shifts6_7": ["alarm_response_committed", "exposure_before_drain_verified", "water_returned"],
	}
	for required in requirements.get(target_id, []):
		if not _flag_is_set(String(required)):
			return {"accepted": false, "reason": "Complete physical prerequisite: " + String(required)}
	return {"accepted": true}

func _submit_command(command: Dictionary, preview_only: bool) -> Dictionary:
	var target_id := String(_dispatcher.state().get("focused_target_id", ""))
	var target: Dictionary = _dispatcher.target(target_id)
	var prerequisite := _special_target_prerequisite(target_id)
	if not bool(prerequisite.get("accepted", false)):
		return prerequisite
	var command_id := String(command.get("command_id", ""))
	var previous: Dictionary = _director.snapshot().get("receipts", {})
	if previous.has(command_id):
		if not preview_only:
			return _director.commit(command)
		var duplicate: Dictionary = previous[command_id].duplicate(true)
		duplicate["duplicate"] = true
		duplicate["snapshot"] = _director.snapshot()
		return duplicate
	var payload: Dictionary = command.get("payload", {}) if command.get("payload", {}) is Dictionary else {}
	if target.has("puzzle_action"):
		var plant_check: Dictionary = _p01.preview(String(target.puzzle_action), payload)
		if not bool(plant_check.get("accepted", false)):
			return plant_check
	if target_id == "confirm_date_transition":
		command = command.duplicate(true)
		command["verb"] = "advance_time"
		command["payload"] = {"scenario_datetime": "2046-04-25 03:36 UTC"}
	if String(command.get("target_id", "")) == "P-02":
		if target_id == "p02_stage_shift2" and not preview_only:
			return {"accepted": false, "reason": "The staged shift is preview-only; commit after the shelter drill."}
		var plan: Dictionary = payload.get("plan", payload) if payload.get("plan", payload) is Dictionary else {}
		var phase_check := _validate_shift_phase(target_id, plan)
		if not bool(phase_check.get("accepted", false)):
			return phase_check
		var host = _p02_hosts.get(command_id, null)
		if host == null:
			host = PuzzleHostScript.new()
			host.bind(_director, "P-02", String(command.get("owning_mission_id", current_mission_id())), String(command.get("owning_scene_id", current_scene_id())))
			_p02_hosts[command_id] = host
		if preview_only:
			return host.preview(plan)
		return host.commit(command_id, plan)
	return _director.preview(command) if preview_only else _director.commit(command)

func _validate_shift_phase(target_id: String, plan: Dictionary) -> Dictionary:
	var phases := {"p02_shift1": [0, 1], "p02_stage_shift2": [1, 1], "p02_shift2": [1, 1], "p02_shifts3_4": [2, 2], "p02_shift5_alarm": [4, 1], "p02_shifts6_7": [5, 2]}
	if not phases.has(target_id):
		return {"accepted": false, "reason": "Unknown Chapter 1 shift target."}
	var expected: Array = phases[target_id]
	var count := 0
	if plan.get("shifts", null) is Array:
		count = plan.shifts.size()
	elif plan.get("shift", plan.get("step", null)) is Dictionary:
		count = 1
	if int(_director.query().get("current_shift", 0)) != int(expected[0]) or count != int(expected[1]):
		return {"accepted": false, "reason": "This physical gate must resolve its exact shifts in order."}
	return {"accepted": true}

func _apply_target_result(target_id: String, payload: Dictionary, result: Dictionary) -> void:
	if not bool(result.get("accepted", false)):
		return
	var target_list: Array = GateCatalog.targets_for_scene(current_scene_id()).filter(func(item): return String(item.get("target_id", "")) == target_id)
	var target: Dictionary = target_list[0] if not target_list.is_empty() else {}
	if target.has("puzzle_action"):
		var action := String(target.get("puzzle_action", ""))
		var p01_payload := payload.duplicate(true)
		p01_payload.erase("_puzzle_action")
		if action in ["water_alo", "water_tara"] and not p01_payload.has("moisture"):
			p01_payload["moisture"] = 50
		var p01_result: Dictionary = _p01.commit(action, "p01:" + target_id, p01_payload)
		if bool(p01_result.get("accepted", false)) or bool(p01_result.get("duplicate", false)):
			_apply_p01_flag(action)
			if action == "plant_alo" and bool(p01_result.get("accepted", false)):
				_commit_plant_care("ALO-01", target.get("owning_scene_id", current_scene_id()))
			if action == "plant_tara" and bool(p01_result.get("accepted", false)):
				_commit_plant_care("TARA-01", target.get("owning_scene_id", current_scene_id()))
			if bool(_p01.completion().get("complete", false)):
				_mark_flag("p01_complete")
			_last_result["p01"] = p01_result
		return
	if target.has("puzzle_id") and String(target.get("puzzle_id", "")) == "P-02":
		if not String(result.get("ending", "")).is_empty():
			_ending = String(result.ending)
		if _ending == "MISSION_STOPPED":
			if target_id == "p02_shifts6_7":
				_mark_flag("final_shifts_resolved")
			return
		match target_id:
			"p02_shift1": _mark_flag("shift1_committed")
			"p02_shift2": _mark_flag("shift2_committed_at_18")
			"p02_shifts3_4": _mark_flag("shifts3_4_resolved")
			"p02_shift5_alarm":
				_mark_flag("alarm_response_committed")
				_world.set_safe_room_exposure_lock(true)
			"p02_shifts6_7":
				_mark_flag("final_shifts_resolved")
				_ending = String(result.get("ending", ""))
		return
	var physical_flag := String(target.get("physical_flag", ""))
	if not physical_flag.is_empty():
		_mark_flag(physical_flag)
	match target_id:
		"verify_chamber":
			_world.set_boundary_state("garden_viewing_shutter", {"chamber_safe": true})
		"open_shutter":
			if bool(_world.open_garden_shutter(true).get("accepted", false)):
				_mark_flag("shutter_opened")
		"confirm_four_sheltered":
			_world.set_safe_room_exposure_lock(true)
		"return_water":
			_mark_flag("water_returned")

func _apply_p01_flag(action: String) -> void:
	match action:
		"set_zero": pass
		"set_span": pass
		"recheck": _mark_flag("probe_calibrated")
		"scan_packet": _mark_flag("packet_inspected")
		"plant_alo": _mark_flag("alo_planted")
		"plant_tara": _mark_flag("tara_planted")
		"water_alo": _mark_flag("alo_watered")
		"water_tara": _mark_flag("tara_watered")
		"label_alo_external": _mark_flag("alo_labelled")
		"label_tara_indoor": _mark_flag("tara_labelled")
		"seal_alo", "seal_tara": pass

func _commit_plant_care(individual_id: String, scene_id: String) -> void:
	var command_id := "p01-plant-care:" + individual_id
	var query: Dictionary = _director.query()
	var command := {
		"command_id": command_id,
		"issuer": "p01_commission_plant",
		"owning_mission_id": current_mission_id(),
		"owning_scene_id": scene_id,
		"expected_state_revision": int(query.get("state_revision", 0)),
		"target_id": individual_id,
		"verb": "plant_care",
		"payload": {"individual_id": individual_id, "care_id": "label", "scenario_datetime": String(query.get("scenario_datetime", "2046-04-25 00:00 UTC"))},
	}
	_director.commit(command)

func _mark_flag(flag: String) -> void:
	if flag.is_empty():
		return
	var flags: Dictionary = _scene_flags.get(current_scene_id(), {})
	flags[flag] = true
	_scene_flags[current_scene_id()] = flags

func _default_plan(command_id: String) -> Dictionary:
	match command_id:
		"p02-shift-1": return {"shift": _step("DAY", 2, "FULL", "HOLD")}
		"p02-stage-shift-2": return {"shift": _step("DAY", 0, "FULL", "HOLD")}
		"p02-shift-2": return {"shift": _step("DAY", 0, "FULL", "HOLD")}
		"p02-shifts-3-4": return {"shifts": [_step("COZY", 0, "OFF", "FILL"), _step("COZY", 0, "OFF", "FILL")]}
		"p02-shift-5": return {"shift": _step("COZY", 0, "OFF", "WAIT")}
		"p02-shifts-6-7": return {"shifts": [_step("COZY", 0, "OFF", "DRAIN"), _step("COZY", 0, "OFF", "DRAIN")]}
	return {"shift": _step("DAY", 0, "OFF", "HOLD")}

func _step(heat, oxygen: int, light, transfer: String) -> Dictionary:
	return {"heat": heat, "air_production": oxygen, "light": light, "transfer": transfer}

func _local_snapshot() -> Dictionary:
	return {
		"current_scene_id": current_scene_id(),
		"current_scene_index": _scene_index,
		"completed_scene_ids": _completed_scene_ids.duplicate(),
		"scene_flags": _scene_flags.duplicate(true),
		"dialogue_acks": _dialogue_acks.duplicate(true),
		"p01": _p01.snapshot(),
		"ending": _ending,
		"world": _world.snapshot(),
	}

func _checkpoint_snapshot() -> Dictionary:
	var state: Dictionary = _director.snapshot()
	# The campaign controller persists the route separately; nesting it here
	# would copy previous retry checkpoints into every later save.
	state.erase("route_runtime")
	return {"director": state, "route": _local_snapshot()}

func _validate_local_snapshot(data: Dictionary) -> Dictionary:
	if data.has("schema_version") and (not (data.schema_version is int or data.schema_version is float) or float(data.schema_version) != 1.0):
		return {"accepted": false, "reason": "Unsupported Chapter 1 route schema."}
	if not data.get("current_scene_id", null) is String:
		return {"accepted": false, "reason": "Chapter 1 scene ID must be a String."}
	var raw_index = data.get("current_scene_index", null)
	if not (raw_index is int or raw_index is float) or not is_finite(float(raw_index)) or float(raw_index) != floor(float(raw_index)):
		return {"accepted": false, "reason": "Chapter 1 scene index must be an integer."}
	var scene_id := String(data.get("current_scene_id", ""))
	var index := GateCatalog.SCENE_ORDER.find(scene_id)
	if index < 0 or int(data.get("current_scene_index", -1)) != index:
		return {"accepted": false, "reason": "Chapter 1 snapshot names an invalid scene/index."}
	for key in ["scene_flags", "dialogue_acks", "p01", "world"]:
		if not data.get(key, null) is Dictionary:
			return {"accepted": false, "reason": "Chapter 1 snapshot requires a Dictionary for " + key}
	if not data.get("completed_scene_ids", null) is Array or not data.get("ending", null) is String:
		return {"accepted": false, "reason": "Chapter 1 completion state has an invalid type."}
	var seen := []
	for completed in data.completed_scene_ids:
		if not completed is String or not GateCatalog.SCENE_ORDER.has(completed) or seen.has(completed):
			return {"accepted": false, "reason": "Chapter 1 completed scenes are invalid or duplicated."}
		seen.append(completed)
	var completed_count: int = data.completed_scene_ids.size()
	var max_completed := index + (1 if index == GateCatalog.SCENE_ORDER.size() - 1 else 0)
	if completed_count > max_completed or data.completed_scene_ids != GateCatalog.SCENE_ORDER.slice(0, completed_count):
		return {"accepted": false, "reason": "Completed Chapter 1 scenes must be a canonical prefix before the current scene."}
	for id in GateCatalog.scene_ids():
		if not data.scene_flags.get(id, null) is Dictionary or not data.dialogue_acks.get(id, null) is Array:
			return {"accepted": false, "reason": "Chapter 1 snapshot is missing scene evidence maps."}
		for flag in data.scene_flags[id].values():
			if not flag is bool:
				return {"accepted": false, "reason": "Chapter 1 physical evidence must be boolean."}
		for line_id in data.dialogue_acks[id]:
			if not line_id is String or not GateCatalog.dialogue_ids(id).has(line_id):
				return {"accepted": false, "reason": "Chapter 1 dialogue receipt is outside its scene."}
	var plant_check: Dictionary = P01Script.new().restore(data.p01)
	if not bool(plant_check.get("accepted", false)):
		return plant_check
	for key in ["boundaries", "roster", "last_viewpoint_cut"]:
		if not data.world.get(key, null) is Dictionary:
			return {"accepted": false, "reason": "World snapshot requires a Dictionary for " + key}
	var world_defaults: Dictionary = WorldRouteScript.new(_director).snapshot()
	for boundary_id in world_defaults.boundaries:
		var boundary_value = data.world.boundaries.get(boundary_id, null)
		if not boundary_value is Dictionary:
			return {"accepted": false, "reason": "World boundary state must be a Dictionary."}
		for key in world_defaults.boundaries[boundary_id]:
			if typeof(boundary_value.get(key, null)) != typeof(world_defaults.boundaries[boundary_id][key]):
				return {"accepted": false, "reason": "World boundary state has an invalid field: " + key}
	for actor_id in world_defaults.roster:
		var actor_value = data.world.roster.get(actor_id, null)
		if not actor_value is Dictionary:
			return {"accepted": false, "reason": "World roster placement must be a Dictionary."}
		for key in world_defaults.roster[actor_id]:
			if typeof(actor_value.get(key, null)) != typeof(world_defaults.roster[actor_id][key]):
				return {"accepted": false, "reason": "World roster placement has an invalid field: " + key}
	if not data.world.get("current_scene_id", null) is String or not data.world.get("current_room_id", null) is String:
		return {"accepted": false, "reason": "World scene and room IDs must be Strings."}
	if not data.world.get("history", null) is Array or data.world.current_scene_id != scene_id or data.world.current_room_id != String(GateCatalog.gate(scene_id).room_id):
		return {"accepted": false, "reason": "World snapshot does not match the Chapter 1 scene."}
	return WorldRouteScript.new(_director).restore(data.world)

func _restore_local(snapshot_data: Dictionary) -> void:
	_scene_index = int(snapshot_data.get("current_scene_index", _scene_index))
	_completed_scene_ids = snapshot_data.get("completed_scene_ids", []).duplicate()
	_scene_flags = snapshot_data.get("scene_flags", {}).duplicate(true)
	_dialogue_acks = snapshot_data.get("dialogue_acks", {}).duplicate(true)
	_ending = String(snapshot_data.get("ending", ""))
	_p01.restore(snapshot_data.get("p01", {}))
	_world.restore(snapshot_data.get("world", {}))
	_register_current_targets()
