extends RefCounted
class_name CampaignDirector

const CampaignSimulation = preload("res://scripts/simulation/campaign_ledger_simulation.gd")
const Knowledge = preload("res://scripts/dialogue/knowledge_service.gd")
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
var _campaign_sim := CampaignSimulation.new()

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
	# Production starts from the validated chapter1_base profile, the same data
	# the P-02 simulation reads, rather than CampaignState's schema defaults.
	var profile: Dictionary = _simulation.entry_profile()
	if profile.is_empty():
		return {}
	for key in profile.resources:
		_state.resources[key] = profile.resources[key]
	_state.upgrades["applied_profile_revision"] = String(profile.get("profile_revision", _state.upgrades.applied_profile_revision))
	_seed_initial_biology()
	# The production route starts on April 11. The bounded systems fixture keeps
	# the April 25 entry profile in CampaignState.new_snapshot(); this method is
	# the explicit full-campaign constructor.
	for plant in _state.get("plants", []):
		plant["last_advanced_at"] = "2046-04-11 06:00 UTC"
		plant["stage"] = "seed"
	_state.inventories.founder_seed42 = {"total": 0, "allocated": 0, "reserve": 0, "unallocated": 0, "reserve_compartments": []}
	_state.inventories.allocated12 = 0
	_state.inventories.reserve30 = 0
	_state.inventories.vault12 = {"total": 0, "stored": 0, "cotton_planted": 0, "stored_after_cotton": 0}
	_state.inventories.stored12 = 0
	_state.inventories.stored11 = 0
	_state.inventories.biology_ledgers = {}
	_checkpoint = _state.duplicate(true)
	return _state.duplicate(true)

func restore_snapshot(snapshot: Dictionary, expected_content_revision: String = "") -> Dictionary:
	if not StateScript.is_compatible(snapshot, expected_content_revision):
		return _reject("Campaign snapshot is incompatible with the current state schema.")
	_state = snapshot.duplicate(true)
	_state.erase("route_runtime")
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
		"outpost": _simulation.outpost_readouts(_state),
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
	var result := _transition(command, false)
	if result.get("accepted", false) and String(command.get("payload", {}).get("_puzzle_action", "")).begins_with("p03_"):
		var biology := _campaign_sim.chapter2_biology(result.get("snapshot", _state), command)
		if not biology.accepted:
			return biology
		result["snapshot"] = biology.snapshot
	return result

## Applies one revision and receipt per command_id; rejected commands are inert.
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
	var result := _transition(command, true)
	if not bool(result.get("accepted", false)):
		return result
	var next: Dictionary = result.get("snapshot", _state).duplicate(true)
	if String(command.get("payload", {}).get("_puzzle_action", "")).begins_with("p03_"):
		var biology := _campaign_sim.chapter2_biology(next, command)
		if not biology.accepted:
			return biology
		next = biology.snapshot
	_checkpoint = _state.duplicate(true)
	for event in Knowledge.grant_operation(next, command):
		event["state_revision"] = current_revision + 1
		event["scene_id"] = command.owning_scene_id
		result["events"].append(event)
	next["state_revision"] = current_revision + 1
	var receipt_id := String(result.get("receipt_id", ""))
	if receipt_id.is_empty():
		receipt_id = "%s:%d" % [command_id, current_revision + 1]
	result["receipt_id"] = receipt_id
	result["input_revision"] = current_revision
	result["output_revision"] = current_revision + 1
	result["events"] = result.get("events", []).duplicate(true)
	result["events"].append(ResultScript.event("command_committed", current_revision + 1, next))
	var receipt := result.duplicate(true)
	# Do not nest a complete snapshot inside a receipt. The snapshot already owns
	# the receipt map, so retaining it here causes exponential deep-copy growth.
	receipt.erase("snapshot")
	next["receipts"][command_id] = receipt.duplicate(true)
	next["mission_receipts"][command_id] = receipt.duplicate(true)
	_state = next
	# Copied after the receipt is stored, so restoring it keeps deduplication.
	result["snapshot"] = next.duplicate(true)
	return result.duplicate(true)

## Restores the complete state from before the last commit. Message metadata
## recorded since then is kept: update_message_metadata() mirrors it into the
## checkpoint, so a gameplay retry never un-delivers or un-reads a message.
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

## Records message deliveries and reads in presentation_resume.messages
## without a gameplay command (M1-89 contract, execution/03_SYSTEM_INTERFACES.md).
##
## metadata holds delivered_ids, read_ids or both, each an Array (or
## PackedStringArray) of message IDs; any other key is rejected. IDs are
## appended in the order given. An ID already recorded, or repeated in the
## call, is a harmless no-op; a read ID must be delivered before or in the same
## call. Any malformed field rejects the whole call with nothing changed.
##
## Presentation only: state_revision, receipts, resources, flags, dialogue and
## phase never change, so an accepted PuzzleHost preview stays committable. The
## retry checkpoint keeps its gameplay state and receives only the merged
## record, so delivered and read messages survive restore_checkpoint(). It is
## accepted while paused, because the inbox is read from the pause menu.
##
## Returns the command-result contract plus "messages" (the merged record) and
## "snapshot"; "duplicate" is true when nothing new was recorded.
func update_message_metadata(metadata: Dictionary) -> Dictionary:
	if metadata.is_empty():
		return _reject("Message metadata needs delivered_ids or read_ids.")
	var additions := {}
	for key in metadata:
		var field: String = String(key) if key is String or key is StringName else ""
		if not StateScript.MESSAGE_FIELDS.has(field):
			return _reject("Message metadata accepts only delivered_ids and read_ids, not " + str(key) + ".")
		var ids = metadata[key]
		if ids is PackedStringArray:
			ids = Array(ids)
		var shape_problem := StateScript.message_ids_problem(ids, field)
		if not shape_problem.is_empty():
			return _reject(shape_problem)
		additions[field] = ids
	var merged := StateScript.message_metadata(_state)
	var added := {"delivered_ids": [], "read_ids": []}
	for field in StateScript.MESSAGE_FIELDS:
		var known := {}
		for id in merged[field]:
			known[id] = true
		for id in additions.get(field, []):
			if not known.has(id):
				known[id] = true
				merged[field].append(id)
				added[field].append(id)
	var problem := StateScript.message_metadata_problem(merged)
	if not problem.is_empty():
		return _reject(problem)
	var revision := int(_state.get("state_revision", 0))
	var result := ResultScript.empty(revision, String(_state.get("scene_phase", "planning")))
	result["accepted"] = true
	result["warnings"] = ["Presentation only: the gameplay revision, receipts and the retry checkpoint's gameplay state are unchanged."]
	result["messages"] = merged.duplicate(true)
	if added.delivered_ids.is_empty() and added.read_ids.is_empty():
		result["duplicate"] = true
		result["reason"] = "Message metadata was already recorded; nothing changed."
		result["snapshot"] = _state.duplicate(true)
		return result
	_state = _with_messages(_state, merged)
	if not _checkpoint.is_empty():
		_checkpoint = _with_messages(_checkpoint, merged)
	for field in StateScript.MESSAGE_FIELDS:
		if not added[field].is_empty():
			result["deltas"].append({"field": "presentation_resume.messages." + field, "added": added[field].duplicate()})
	result["events"] = [ResultScript.event("message_metadata_updated", revision, _state)]
	result["reason"] = "Message metadata recorded."
	result["snapshot"] = _state.duplicate(true)
	return result

## Returns a copy of presentation_resume.messages:
## {"delivered_ids": [...], "read_ids": [...]}, both empty for a fresh New or
## a save written before M1-89.
func message_metadata() -> Dictionary:
	return StateScript.message_metadata(_state)

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
	if verb in ["record_choice", "record_moment"]:
		return _story_transition(command, payload, should_commit)
	if verb == "campaign_operation":
		return _campaign_sim.transition(_state, command)
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
			_advance_plants(next)
		result["snapshot"] = next
		return result
	if verb == "acknowledge_line":
		var line_id := String(payload.get("line_id", ""))
		if not Knowledge.line_allowed(line_id, _state.knowledge_flags, String(command.get("owning_scene_id", ""))):
			return _reject("This caption is unavailable until its owning evidence has been acquired.")
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
		if not StateScript.is_scenario_datetime(target_date) or target_date <= String(_state.get("scenario_datetime", "")):
			return _reject("Dated transitions must move scenario time forward explicitly.")
		var result := _generic_result(revision, should_commit, "time_advanced")
		result["deltas"] = [{"field": "scenario_datetime", "from": String(_state.get("scenario_datetime", "")), "to": target_date}]
		if should_commit:
			var next := _state.duplicate(true)
			next["scenario_datetime"] = target_date
			next["explicit_time_receipts"][String(command.get("command_id", ""))] = target_date
			_advance_plants(next)
			result["snapshot"] = next
		return result
	if verb == "apply_delta":
		var requested = payload.get("deltas", {})
		if not requested is Dictionary:
			return _reject("Resource deltas must be a primitive Dictionary.")
		var ledger_date := String(payload.get("scenario_datetime", ""))
		if payload.has("scenario_datetime") and (not StateScript.is_scenario_datetime(ledger_date) or ledger_date < String(_state.get("scenario_datetime", ""))):
			return _reject("A dated resource ledger needs a valid UTC date and minute that does not move time backwards.")
		var resources: Dictionary = _state.get("resources", {})
		var next_resources := resources.duplicate(true)
		var deltas: Array = []
		for field in requested.keys():
			var key := String(field)
			if not next_resources.has(key) or not (requested[field] is float or requested[field] is int) or not is_finite(float(requested[field])):
				return _reject("Unknown or non-numeric resource delta: " + key)
			var before := float(next_resources[key])
			var after := before + float(requested[field])
			if not is_finite(after):
				return _reject("Resource delta overflowed " + key)
			var capacity_key: String = {"E": "energy_capacity", "A": "air_capacity", "H": "health_capacity", "W": "water_capacity", "K": "crate_capacity", "C": "crop_capacity"}.get(key, "")
			if not capacity_key.is_empty():
				after = minf(after, float(next_resources.get(capacity_key, after)))
			if after < 0.0:
				return _reject("Resource delta would make %s negative." % key)
			var whole: bool = after == floor(after)
			# Crates, water units and capacities are discrete; air, food,
			# energy and exposure may carry fractions.
			if not whole and (key in ["W", "K"] or key.ends_with("_capacity")):
				return _reject("Resource %s only changes in whole units." % key)
			next_resources[key] = after if key == "R" or not whole else int(after)
			deltas.append({"field": "resources." + key, "from": before, "to": after})
		var result := _generic_result(revision, should_commit, "resource_delta")
		result["deltas"] = deltas
		# A preview returns the same projected resources/date on a copy. Only
		# commit replaces _state and stores a receipt in the coordinator.
		var next := _state.duplicate(true)
		next["resources"] = next_resources
		if ledger_date > String(next.get("scenario_datetime", "")):
			next["scenario_datetime"] = ledger_date
			next["explicit_time_receipts"][String(command.command_id)] = ledger_date
			_advance_plants(next)
		result["snapshot"] = next
		return result
	if verb == "set_phase":
		var phase := String(payload.get("phase", ""))
		if phase.is_empty():
			return _reject("A scene phase cannot be empty.")
		if payload.has("scenario_datetime") and not StateScript.is_scenario_datetime(String(payload.scenario_datetime)):
			return _reject("A dated scene phase requires a valid UTC date and minute.")
		var result := _generic_result(revision, should_commit, "scene_phase_changed")
		result["next_phase"] = phase
		if should_commit:
			var next := _state.duplicate(true)
			next["scene_phase"] = phase
			# Persist the passed exit before the route projects the next scene.
			# Direct routes and resumed sessions therefore share the same lock.
			var completed_scene := String(command.get("owning_scene_id", ""))
			if bool(payload.get("physical_gate", false)) and phase == "scene_complete:" + completed_scene and not next.completed_scene_ids.has(completed_scene):
				next.completed_scene_ids.append(completed_scene)
			var target_date := String(payload.get("scenario_datetime", ""))
			if target_date > String(next.get("scenario_datetime", "")):
				next["scenario_datetime"] = target_date
				_advance_plants(next)
			result["snapshot"] = next
		return result
	if verb == "plant_care" or verb == "harvest_plant":
		return _plant_transition(command, payload, should_commit)
	return _reject("Unknown campaign command verb: " + verb)

func _story_transition(command: Dictionary, payload: Dictionary, should_commit: bool) -> Dictionary:
	if not command.get("payload") is Dictionary:
		return _reject("Story command payload must be a Dictionary.")
	var choice: bool = command.verb == "record_choice"
	var id_field := "choice_id" if choice else "moment_id"
	if not payload.get(id_field) is String or String(payload[id_field]).strip_edges().is_empty():
		return _reject("Story command requires a nonempty String " + id_field + ".")
	var id: String = payload[id_field]
	if choice:
		if not payload.get("option_id") is String:
			return _reject("Story choice requires a String option_id.")
		var problem := StateScript.story_choice_problem(id, payload.option_id)
		if not problem.is_empty():
			return _reject(problem)
		if StateScript.story_choice_locked(_state, id):
			return _reject("This story choice is locked because its scene exit has passed.")
		if StateScript.story_choice_scene_id(id) != _state.scene_id:
			return _reject("A story choice can only be confirmed in its owning scene.")
	if command.get("owning_scene_id") != _state.scene_id or command.get("owning_mission_id") != _state.mission_id:
		return _reject("Story command ownership does not match the current scene and mission.")
	var revision := int(_state.state_revision)
	var event_type := "story_choice_recorded" if choice else "story_moment_recorded"
	if not should_commit:
		event_type = "story_choice_preview" if choice else "story_moment_preview"
	var result := _generic_result(revision, should_commit, event_type)
	# Story previews return the original log even on the projected snapshot.
	if should_commit:
		var next := _state.duplicate(true)
		if choice:
			var entry := {"option_id": payload.option_id, "scene_id": _state.scene_id, "scenario_datetime": _state.scenario_datetime, "state_revision": revision + 1}
			next.story_log.choices[id] = entry
			result["deltas"] = [{"field": "story_log.choices." + id, "value": entry.duplicate(true)}]
		else:
			if not next.story_log.moments.has(id):
				next.story_log.moments.append(id)
				result["deltas"] = [{"field": "story_log.moments", "value": id}]
		result["events"][0][id_field] = id
		result["events"][0]["state_revision"] = revision + 1
		result["reason"] = "Choice recorded." if choice else "Moment recorded."
		result["snapshot"] = next
	return result

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

# Copies, never edits in place: project_scene() hands its caller the live state.
static func _with_messages(source: Dictionary, messages: Dictionary) -> Dictionary:
	var next := source.duplicate(true)
	var resume = next.get("presentation_resume", {})
	if not resume is Dictionary:
		resume = {}
	resume["messages"] = messages.duplicate(true)
	next["presentation_resume"] = resume
	return next

func _seed_initial_biology() -> void:
	var alo: Dictionary = _plant_service.new_plant("ALO-01", "LINEAGE-ALO-TARA", "seed", "2046-04-11 06:00 UTC")
	var tara: Dictionary = _plant_service.new_plant("TARA-01", "LINEAGE-ALO-TARA", "seed", "2046-04-11 06:00 UTC")
	var alo_at_entry: Dictionary = _plant_service.advance_to(alo, "2046-04-25 00:00 UTC")
	var tara_at_entry: Dictionary = _plant_service.advance_to(tara, "2046-04-25 00:00 UTC")
	_state["plants"] = [alo_at_entry.get("plant", alo), tara_at_entry.get("plant", tara)]
	_state["inventories"]["biology_ledgers"] = _plant_service.canonical_ledgers()

func _advance_plants(next: Dictionary) -> void:
	for index in range(next.get("plants", []).size()):
		var plant: Dictionary = next.plants[index]
		if String(plant.get("individual_id", "")) == "ALO-01" and bool(plant.get("alive", true)) and int(next.resources.get("H", 0)) <= 0:
			plant["stage"] = "lost"
			plant["alive"] = false
			plant["death_reason"] = "survival_attempt_failed"
		elif bool(plant.get("alive", true)):
			var advanced: Dictionary = _plant_service.advance_to(plant, String(next.scenario_datetime))
			if bool(advanced.get("accepted", false)):
				next.plants[index] = advanced.plant

## Authored cuts advance the explicit story clock, never reading or wall time.
func project_scene(scene_id: String) -> Dictionary:
	var result := _campaign_sim.project_scene(_state, scene_id)
	if result.accepted:
		var changed: bool = result.snapshot != _state
		_state = result.snapshot
		if changed:
			_state.state_revision = int(_state.state_revision) + 1
	return result

func campaign_state_predicates(scene_id: String) -> Array:
	return _campaign_sim.state_predicates(scene_id, _state)
