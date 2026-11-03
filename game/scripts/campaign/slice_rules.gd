extends RefCounted
class_name SliceRules

const SCENE_CHOICES := {
	"EX-CH01-S01": ["store_air", "light_bay"],
	"EX-CH01-S02": ["lead_rafi", "lead_amara"],
	"EX-CH01-S03": ["record_provenance", "calibrate_probe"]
}

const OPTION_DETAILS := {
	"store_air": {"label": "STORE AIR", "consequence": "The air gauge rises in this exercise.", "marker": "air_routed", "resource_deltas": {"air": 2, "energy": -1}},
	"light_bay": {"label": "LIGHT THE PLANTING BAY", "consequence": "The planting bench receives warm light.", "marker": "planting_bay_lit", "resource_deltas": {"crop_condition": 1, "energy": -2}},
	"lead_rafi": {"label": "RAFI", "consequence": "His checklist establishes the order.", "marker": "rafi_rehearsal_lead", "resource_deltas": {"water_shielding": 1, "energy": -1}},
	"lead_amara": {"label": "AMARA", "consequence": "Her read-back tests a second user of the procedure.", "marker": "amara_rehearsal_lead", "resource_deltas": {"air": 1, "energy": -1}},
	"record_provenance": {"label": "PACKET PROVENANCE", "consequence": "Seed handling becomes traceable.", "marker": "packet_provenance_recorded", "resource_deltas": {}},
	"calibrate_probe": {"label": "CALIBRATION RESULT", "consequence": "Measurement becomes traceable.", "marker": "calibration_result_recorded", "resource_deltas": {"energy": -1}}
}

static func preview(snapshot: Dictionary, expected_revision: int, choice_id: String) -> Dictionary:
	return _transition(snapshot, "preview:%s:%d" % [choice_id, expected_revision], expected_revision, choice_id, false)

static func commit(snapshot: Dictionary, command_id: String, expected_revision: int, choice_id: String) -> Dictionary:
	return _transition(snapshot, command_id, expected_revision, choice_id, true)

static func _transition(snapshot: Dictionary, command_id: String, expected_revision: int, choice_id: String, should_commit: bool) -> Dictionary:
	var current_revision: int = int(snapshot.get("state_revision", -1))
	var scene_id := String(snapshot.get("scene_id", ""))
	var result := {
		"accepted": false,
		"duplicate": false,
		"input_revision": current_revision,
		"output_revision": current_revision,
		"receipt_id": "",
		"deltas": [],
		"events": [],
		"warnings": [],
		"reason": "",
		"next_phase": String(snapshot.get("scene_phase", "briefing"))
	}
	if not SliceState.is_compatible(snapshot):
		result.reason = "This expedition save is not compatible with the current content revision."
		return {"snapshot": SliceState.copy_snapshot(snapshot), "result": result}
	if not should_commit:
		result.warnings.append("PREVIEW ONLY · no state, receipt, date or inventory changes")
	if should_commit and command_id.is_empty():
		result.reason = "A committed decision needs a command id."
		return {"snapshot": SliceState.copy_snapshot(snapshot), "result": result}
	if should_commit and snapshot.get("receipts", {}).has(command_id):
		var prior: Dictionary = snapshot.receipts[command_id].duplicate(true)
		prior["duplicate"] = true
		return {"snapshot": SliceState.copy_snapshot(snapshot), "result": prior}
	if expected_revision != current_revision:
		result.reason = "This screen is out of date. Review the latest verified checkpoint before committing."
		return {"snapshot": SliceState.copy_snapshot(snapshot), "result": result}
	if not SCENE_CHOICES.has(scene_id) or not SCENE_CHOICES[scene_id].has(choice_id):
		result.reason = "Choose one of the visible options before confirming."
		return {"snapshot": SliceState.copy_snapshot(snapshot), "result": result}

	var detail: Dictionary = OPTION_DETAILS.get(choice_id, {})
	result.accepted = true
	result.receipt_id = "%s:%s:%d" % [scene_id, choice_id, current_revision + 1]
	result.deltas = [String(detail.get("consequence", "Decision recorded."))]
	result.resource_changes = _resource_changes(snapshot, detail)
	result.events = ["decision_preview" if not should_commit else "decision_committed"]
	result.reason = "Preview ready. Commit is explicit." if not should_commit else "Decision recorded once."
	if not should_commit:
		return {"snapshot": SliceState.copy_snapshot(snapshot), "result": result}

	var next := SliceState.copy_snapshot(snapshot)
	_apply_resource_deltas(next, detail)
	next.state_revision = current_revision + 1
	next.scene_phase = "result"
	next.dialogue_cursor = 0
	next.commissioning_markers[detail.marker] = true
	next.history.append({"scene_id": scene_id, "choice_id": choice_id, "receipt_id": result.receipt_id})
	next.receipts[command_id] = result.duplicate(true)
	if not next.completed_scene_ids.has(scene_id):
		next.completed_scene_ids.append(scene_id)
	if not next.knowledge.has("decision:" + choice_id):
		next.knowledge.append("decision:" + choice_id)
	if int(next.scene_index) < 2:
		next.scene_index = int(next.scene_index) + 1
		next.scene_id = "EX-CH01-S0%d" % (int(next.scene_index) + 1)
		next.checkpoint_id = scene_id + "-CHECKPOINT"
		next.scenario_datetime = ["2046-04-11 06:00 UTC", "2046-04-11 07:00 UTC", "2046-04-11 10:00 UTC"][int(snapshot.scene_index)]
		if int(next.scene_index) < 2:
			next.scene_phase = "briefing"
		result.next_phase = "next_scene"
	else:
		next.scene_id = scene_id
		next.scene_phase = "slice_complete"
		next.status = "commissioning_slice_complete"
		result.next_phase = "commissioning_slice_complete"
	result.output_revision = int(next.state_revision)
	result.events.append("scene_completed")
	if int(next.scene_index) >= 2:
		result.events.append("commissioning_slice_complete")
	return {"snapshot": next, "result": result}

static func option_details(choice_id: String) -> Dictionary:
	return OPTION_DETAILS.get(choice_id, {}).duplicate(true)

static func _resource_changes(snapshot: Dictionary, detail: Dictionary) -> Array:
	var resources: Dictionary = snapshot.get("resources", {})
	var changes: Array = []
	for key in detail.get("resource_deltas", {}).keys():
		var resource_id := String(key)
		var before := int(resources.get(resource_id, 0))
		var after := _bounded_resource(resources, resource_id, before + int(detail.resource_deltas[key]))
		if before != after:
			changes.append({"resource_id": resource_id, "before": before, "after": after, "delta": after - before})
	return changes

static func _apply_resource_deltas(snapshot: Dictionary, detail: Dictionary) -> void:
	var resources: Dictionary = snapshot.get("resources", {})
	for change in _resource_changes(snapshot, detail):
		resources[String(change.resource_id)] = int(change.after)
	snapshot["resources"] = resources

static func _bounded_resource(resources: Dictionary, resource_id: String, value: int) -> int:
	var maximum := 999
	if resource_id == "alo_health" or resource_id == "crop_condition":
		maximum = 10
	elif resource_id == "energy":
		maximum = int(resources.get("energy_capacity", maximum))
	elif resource_id == "air":
		maximum = int(resources.get("air_capacity", maximum))
	return clampi(value, 0, maximum)
