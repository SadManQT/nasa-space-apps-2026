extends RefCounted
class_name CampaignDirector

const StateScript = preload("res://scripts/core/campaign_state.gd")
const ResultScript = preload("res://scripts/core/command_result.gd")
const SimulationScript = preload("res://scripts/simulation/expedition_simulation.gd")
const PlantServiceScript = preload("res://scripts/biology/plant_service.gd")

## Authoritative state/command coordinator. It is deliberately not an
## autoload: the supervisor can construct one per expedition and explicitly
## inject it into scenes, tests, or a save/load session.

var _state: Dictionary
var _checkpoint: Dictionary
var _simulation: RefCounted
var _plant_service: RefCounted

func _init() -> void:
	_simulation = SimulationScript.new()
	_plant_service = PlantServiceScript.new()
	_state = StateScript.new_snapshot()
	_seed_initial_biology()
	_checkpoint = _state.duplicate(true)

func new_campaign(content_revision: String = "") -> Dictionary:
	_state = StateScript.new_snapshot(content_revision)
	_state["checkpoint_id"] = "EX-CH01-S01-CHECKPOINT"
	_state["chapter_id"] = "CH01"
	_state["mission_id"] = "EX-M0101"
	_state["scene_id"] = "EX-CH01-S01"
	_state["scene_phase"] = "briefing"
	_state["completed_scene_ids"] = []
	_state["scenario_datetime"] = "2046-04-11 06:00 UTC"
	_state["status"] = "active"
	_seed_initial_biology()
	# The production route starts on April 11. The bounded systems fixture keeps
	# the April 25 entry profile in CampaignState.new_snapshot(); this method is
	# the explicit full-campaign constructor.
	for plant in _state.get("plants", []):
		plant["last_advanced_at"] = "2046-04-11 06:00 UTC"
		plant["stage"] = "seed"
	_checkpoint = _state.duplicate(true)
	return _state.duplicate(true)

func restore_snapshot(snapshot: Dictionary) -> Dictionary:
	if not StateScript.is_compatible(snapshot):
		return _reject("Campaign snapshot is incompatible with the current state schema.")
	_state = snapshot.duplicate(true)
	_checkpoint = _state.duplicate(true)
	return {
		"accepted": true,
		"reason": "Campaign snapshot restored.",
		"snapshot": _state.duplicate(true),
	}

func snapshot() -> Dictionary:
	return _state.duplicate(true)

func query() -> Dictionary:
	var resources: Dictionary = _state.get("resources", {})
	return {
		"schema_version": int(_state.get("schema_version", StateScript.SCHEMA_VERSION)),
		"content_revision": String(_state.get("content_revision", "")),
		"state_revision": int(_state.get("state_revision", 0)),
		"chapter_id": String(_state.get("chapter_id", "")),
		"mission_id": String(_state.get("mission_id", "")),
		"scene_id": String(_state.get("scene_id", "")),
		"scene_phase": String(_state.get("scene_phase", "")),
		"scenario_datetime": String(_state.get("scenario_datetime", "")),
		"current_shift": int(_state.get("current_shift", 0)),
		"resources": resources.duplicate(true),
		"status": String(_state.get("status", "active")),
		"paused": bool(_state.get("paused", false)),
		"can_retry": not _checkpoint.is_empty(),
	}

func preview(command: Dictionary) -> Dictionary:
	var shape := _validate_command(command, false)
	if not bool(shape.get("accepted", false)):
		return shape
	var verb := String(command.get("verb", ""))
	if bool(_state.get("paused", false)) and verb not in ["resume", "pause"]:
		return _reject("The expedition is paused; resume before previewing an operation.")
	if int(command.get("expected_state_revision", -1)) != int(_state.get("state_revision", 0)):
		return _reject("This command preview is stale; read the current snapshot first.")
	return _transition(command, false)

func commit(command: Dictionary) -> Dictionary:
	var shape := _validate_command(command, true)
	if not bool(shape.get("accepted", false)):
		return shape
	var command_id := String(command.get("command_id", ""))
	var receipts: Dictionary = _state.get("receipts", {})
	if receipts.has(command_id):
		var duplicate: Dictionary = receipts[command_id].duplicate(true)
		duplicate["duplicate"] = true
		duplicate["snapshot"] = _state.duplicate(true)
		return duplicate
	var verb := String(command.get("verb", ""))
	if verb == "pause":
		var pause_payload = command.get("payload", {})
		if not pause_payload is Dictionary:
			return _reject("Pause command payload must be a primitive Dictionary.")
		return pause(String(pause_payload.get("reason", "command")))
	if verb == "resume":
		return resume()
	if bool(_state.get("paused", false)):
		return _reject("The expedition is paused; resume before committing an operation.")
	var current_revision := int(_state.get("state_revision", 0))
	if int(command.get("expected_state_revision", -1)) != current_revision:
		return _reject("This command is stale; no resource or world state changed.")
	_checkpoint = _state.duplicate(true)
	var result := _transition(command, true)
	if not bool(result.get("accepted", false)):
		return result
	var next: Dictionary = result.get("snapshot", _state).duplicate(true)
	next["state_revision"] = current_revision + 1
	var receipt_id := String(result.get("receipt_id", ""))
	if receipt_id.is_empty():
		receipt_id = "%s:%d" % [command_id, current_revision + 1]
	result["receipt_id"] = receipt_id
	result["input_revision"] = current_revision
	result["output_revision"] = current_revision + 1
	result["snapshot"] = next.duplicate(true)
	result["events"] = result.get("events", []).duplicate(true)
	result["events"].append(ResultScript.event("command_committed", current_revision + 1, next))
	var receipt := result.duplicate(true)
	# Do not nest a complete snapshot inside a receipt. The snapshot already owns
	# the receipt map, so retaining it here causes exponential deep-copy growth.
	receipt.erase("snapshot")
	next["receipts"][command_id] = receipt.duplicate(true)
	next["mission_receipts"][command_id] = receipt.duplicate(true)
	_state = next
	return result.duplicate(true)

func restore_checkpoint() -> Dictionary:
	var input_revision := int(_state.get("state_revision", 0))
	if _checkpoint.is_empty():
		return _reject("No safe checkpoint is available for retry.")
	_state = _checkpoint.duplicate(true)
	return {
		"accepted": true,
		"duplicate": false,
		"input_revision": input_revision,
		"output_revision": int(_state.get("state_revision", 0)),
		"receipt_id": "",
		"deltas": [],
		"events": [ResultScript.event("checkpoint_restored", int(_state.get("state_revision", 0)), _state)],
		"warnings": ["Retry restored the complete pre-commit checkpoint."],
		"unsafe_predicates": [],
		"reason": "Safe checkpoint restored.",
		"next_phase": String(_state.get("scene_phase", "planning")),
		"snapshot": _state.duplicate(true),
	}

func pause(reason: String = "user") -> Dictionary:
	var revision := int(_state.get("state_revision", 0))
	_state["paused"] = true
	return {
		"accepted": true,
		"duplicate": false,
		"input_revision": revision,
		"output_revision": revision,
		"receipt_id": "",
		"deltas": [],
		"events": [ResultScript.event("expedition_paused", revision, _state)],
		"warnings": ["Reading and pause do not consume resources or scenario time."],
		"unsafe_predicates": [],
		"reason": reason,
		"next_phase": "paused",
		"snapshot": _state.duplicate(true),
	}

func resume() -> Dictionary:
	var revision := int(_state.get("state_revision", 0))
	_state["paused"] = false
	return {
		"accepted": true,
		"duplicate": false,
		"input_revision": revision,
		"output_revision": revision,
		"receipt_id": "",
		"deltas": [],
		"events": [ResultScript.event("expedition_resumed", revision, _state)],
		"warnings": [],
		"unsafe_predicates": [],
		"reason": "Expedition resumed.",
		"next_phase": String(_state.get("scene_phase", "planning")),
		"snapshot": _state.duplicate(true),
	}

func _transition(command: Dictionary, should_commit: bool) -> Dictionary:
	var revision := int(_state.get("state_revision", 0))
	var verb := String(command.get("verb", ""))
	var payload: Dictionary = command.get("payload", {}) if command.get("payload", {}) is Dictionary else {}
	if verb == "commit_shift":
		var plan: Dictionary = payload.get("plan", payload) if payload.get("plan", payload) is Dictionary else {}
		var simulation_result: Dictionary
		if should_commit:
			simulation_result = _simulation.commit(_state, String(command.get("command_id", "")), revision, plan)
		else:
			simulation_result = _simulation.preview(_state, plan)
		if not bool(simulation_result.get("accepted", false)):
			return simulation_result
		var next: Dictionary = simulation_result.get("snapshot", _state).duplicate(true)
		if not should_commit:
			next = _state.duplicate(true)
		var result := simulation_result.duplicate(true)
		result["input_revision"] = revision
		result["output_revision"] = revision if not should_commit else revision + 1
		result["receipt_id"] = "" if not should_commit else String(result.get("receipt_id", ""))
		result["events"] = [{"type": "simulation_preview" if not should_commit else "shift_committed", "state_revision": result["output_revision"], "chapter_id": String(_state.get("chapter_id", "")), "mission_id": String(_state.get("mission_id", "")), "scene_id": String(_state.get("scene_id", ""))}]
		if not should_commit:
			result["warnings"].append("DIRECTOR PREVIEW ONLY · no authoritative state mutation")
		else:
			next["scene_phase"] = String(result.get("next_phase", "planning"))
			next["status"] = "mission_stopped" if String(result.get("ending", "")) == "MISSION_STOPPED" else ("complete" if int(next.get("current_shift", 0)) >= 7 else "active")
		result["snapshot"] = next
		return result
	if verb == "acknowledge_line":
		var line_id := String(payload.get("line_id", ""))
		if line_id.is_empty():
			return _reject("Acknowledging a line requires a stable line_id.")
		var result := _generic_result(revision, should_commit, "dialogue_acknowledged")
		result["deltas"] = [{"field": "acknowledged_line_ids", "value": line_id}]
		result["next_phase"] = String(_state.get("scene_phase", "planning"))
		if should_commit:
			var next := _state.duplicate(true)
			if not next["acknowledged_line_ids"].has(line_id):
				next["acknowledged_line_ids"].append(line_id)
				next["dialogue_cursor"] = int(next.get("dialogue_cursor", 0)) + 1
			result["snapshot"] = next
		return result
	if verb == "advance_time":
		var target_date := String(payload.get("scenario_datetime", ""))
		if target_date.is_empty() or target_date <= String(_state.get("scenario_datetime", "")):
			return _reject("Dated transitions must move scenario time forward explicitly.")
		var result := _generic_result(revision, should_commit, "time_advanced")
		result["deltas"] = [{"field": "scenario_datetime", "from": String(_state.get("scenario_datetime", "")), "to": target_date}]
		if should_commit:
			var next := _state.duplicate(true)
			next["scenario_datetime"] = target_date
			next["explicit_time_receipts"][String(command.get("command_id", ""))] = target_date
			result["snapshot"] = next
		return result
	if verb == "set_phase":
		var phase := String(payload.get("phase", ""))
		if phase.is_empty():
			return _reject("A scene phase cannot be empty.")
		var result := _generic_result(revision, should_commit, "scene_phase_changed")
		result["next_phase"] = phase
		if should_commit:
			var next := _state.duplicate(true)
			next["scene_phase"] = phase
			result["snapshot"] = next
		return result
	if verb == "plant_care" or verb == "harvest_plant":
		return _plant_transition(command, payload, should_commit)
	return _reject("Unknown campaign command verb: " + verb)

func _plant_transition(command: Dictionary, payload: Dictionary, should_commit: bool) -> Dictionary:
	var individual_id := String(payload.get("individual_id", ""))
	var when := String(payload.get("scenario_datetime", _state.get("scenario_datetime", "")))
	var plants: Array = _state.get("plants", [])
	var index := -1
	var plant: Dictionary = {}
	for i in range(plants.size()):
		if String(plants[i].get("individual_id", "")) == individual_id:
			index = i
			plant = plants[i].duplicate(true)
			break
	if index < 0:
		return _reject("Unknown plant individual; no ledger was changed.")
	var operation: Dictionary
	if String(command.get("verb", "")) == "plant_care":
		operation = _plant_service.apply_care(plant, String(payload.get("care_id", "")), when)
	else:
		operation = _plant_service.harvest(plant, when)
	if not bool(operation.get("accepted", false)):
		var rejected := _reject(String(operation.get("reason", "Plant operation rejected.")))
		rejected["plant_operation"] = operation.duplicate(true)
		return rejected
	var result := _generic_result(int(_state.get("state_revision", 0)), should_commit, "plant_operation")
	result["deltas"] = [{"field": "plants.%s" % individual_id, "from": plant, "to": operation.get("plant", plant)}]
	result["plant_operation"] = operation.duplicate(true)
	if should_commit:
		var next := _state.duplicate(true)
		next["plants"][index] = operation.get("plant", plant).duplicate(true)
		if operation.has("ledgers"):
			next["inventories"]["biology_ledgers"] = operation["ledgers"].duplicate(true)
		result["snapshot"] = next
	return result

func _generic_result(revision: int, should_commit: bool, event_type: String) -> Dictionary:
	var result := ResultScript.empty(revision, String(_state.get("scene_phase", "planning")))
	result["accepted"] = true
	result["reason"] = "Command preview ready." if not should_commit else "Command committed once."
	result["events"] = [{"type": event_type, "state_revision": revision}]
	if not should_commit:
		result["warnings"].append("PREVIEW ONLY · no authoritative state mutation")
	result["snapshot"] = _state.duplicate(true)
	return result

func _validate_command(command: Dictionary, committing: bool) -> Dictionary:
	if command.is_empty():
		return _reject("A command must be a primitive Dictionary.")
	for key in ["command_id", "issuer", "owning_mission_id", "owning_scene_id", "expected_state_revision", "target_id", "verb", "payload"]:
		if not command.has(key):
			return _reject("Command is missing frozen field: " + key)
	if committing and String(command.get("command_id", "")).is_empty():
		return _reject("A committed command requires command_id.")
	var verb := String(command.get("verb", ""))
	if verb in ["pause", "resume"] and not command.get("payload", {}) is Dictionary:
		return _reject("Pause and resume command payloads must be primitive Dictionaries.")
	return {"accepted": true}

func _reject(reason: String) -> Dictionary:
	var result := ResultScript.empty(int(_state.get("state_revision", 0)), String(_state.get("scene_phase", "planning")))
	result["reason"] = reason
	result["snapshot"] = _state.duplicate(true)
	return result

func _seed_initial_biology() -> void:
	var alo: Dictionary = _plant_service.new_plant("ALO-01", "LINEAGE-ALO-TARA", "seed", "2046-04-11 06:00 UTC")
	var tara: Dictionary = _plant_service.new_plant("TARA-01", "LINEAGE-ALO-TARA", "seed", "2046-04-11 06:00 UTC")
	var alo_at_entry: Dictionary = _plant_service.advance_to(alo, "2046-04-25 00:00 UTC")
	var tara_at_entry: Dictionary = _plant_service.advance_to(tara, "2046-04-25 00:00 UTC")
	_state["plants"] = [alo_at_entry.get("plant", alo), tara_at_entry.get("plant", tara)]
	_state["inventories"]["biology_ledgers"] = _plant_service.canonical_ledgers()
