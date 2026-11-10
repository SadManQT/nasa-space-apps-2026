extends RefCounted
class_name Chapter2GateCatalog

const SCENE_ORDER := [
	"EX-CH02-S01", "EX-CH02-S02", "EX-CH02-S03", "EX-CH02-S04", "EX-CH02-S05", "EX-CH02-S06",
	"EX-CH02-S07", "EX-CH02-S08", "EX-CH02-S09", "EX-CH02-S10", "EX-CH02-S11", "EX-CH02-S12",
]

const MISSION_SCENES := {
	"EX-M0201": ["EX-CH02-S01", "EX-CH02-S02", "EX-CH02-S03"],
	"EX-M0202": ["EX-CH02-S04", "EX-CH02-S05", "EX-CH02-S06"],
	"EX-M0203": ["EX-CH02-S07", "EX-CH02-S08", "EX-CH02-S09"],
	"EX-M0204": ["EX-CH02-S10", "EX-CH02-S11", "EX-CH02-S12"],
}

const _GATES := {
	"EX-CH02-S01": {"mission_id": "EX-M0201", "room_id": "LOC-03", "predicate_id": "PRED-EX-CH02-S01-EXIT", "required_physical": ["alo_identity_inspected", "tara_identity_inspected", "live_link_acknowledged", "pollination_protocol_opened"]},
	"EX-CH02-S02": {"mission_id": "EX-M0201", "room_id": "LOC-03", "predicate_id": "PRED-EX-CH02-S02-EXIT", "required_physical": ["anther_identified", "stigma_identified", "brush_directions_assigned", "practice_model_complete"]},
	"EX-CH02-S03": {"mission_id": "EX-M0201", "room_id": "LOC-05", "predicate_id": "PRED-EX-CH02-S03-EXIT", "required_physical": ["space_weather_checked", "carrier_prepared", "boundary_order_verified", "cycle_budget_previewed"]},
	"EX-CH02-S04": {"mission_id": "EX-M0202", "room_id": "LOC-05", "predicate_id": "PRED-EX-CH02-S04-EXIT", "required_physical": ["p03_run_1_complete"]},
	"EX-CH02-S05": {"mission_id": "EX-M0202", "room_id": "LOC-05", "predicate_id": "PRED-EX-CH02-S05-EXIT", "required_physical": ["p03_three_runs", "p03_seven_care_dates"]},
	"EX-CH02-S06": {"mission_id": "EX-M0202", "room_id": "LOC-03", "predicate_id": "PRED-EX-CH02-S06-EXIT", "required_physical": ["p03_prediction_recorded"]},
	"EX-CH02-S07": {"mission_id": "EX-M0203", "room_id": "LOC-01", "predicate_id": "PRED-EX-CH02-S07-EXIT", "required_physical": ["life_cycle_ordered", "current_evidence_separated", "recorder_identifier_linked"]},
	"EX-CH02-S08": {"mission_id": "EX-M0203", "room_id": "LOC-02", "predicate_id": "PRED-EX-CH02-S08-EXIT", "required_physical": ["serial_card_collected", "date_card_collected", "trial_stage_card_collected", "identity_claim_excluded"]},
	"EX-CH02-S09": {"mission_id": "EX-M0203", "room_id": "LOC-02", "predicate_id": "PRED-EX-CH02-S09-EXIT", "required_physical": ["p04_mapping_complete", "p04_checksum_verified", "p04_transcript_opened"]},
	"EX-CH02-S10": {"mission_id": "EX-M0204", "room_id": "LOC-02", "predicate_id": "PRED-EX-CH02-S10-EXIT", "required_physical": ["p04_engineer_played", "p04_n_clue_played", "p04_inference_classified"]},
	"EX-CH02-S11": {"mission_id": "EX-M0204", "room_id": "LOC-01", "predicate_id": "PRED-EX-CH02-S11-EXIT", "required_physical": ["p04_copy_sent", "handover_complete"]},
	"EX-CH02-S12": {"mission_id": "EX-M0204", "room_id": "LOC-01", "predicate_id": "PRED-EX-CH02-S12-EXIT", "required_physical": ["brace_reached", "four_accounted", "quake_beat_finished"]},
}

static func scene_ids() -> Array: return SCENE_ORDER.duplicate()
static func mission_ids() -> Array: return MISSION_SCENES.keys()
static func gate(scene_id: String) -> Dictionary: return (_GATES.get(scene_id, {}) as Dictionary).duplicate(true)
static func scenes_for_mission(mission_id: String) -> Array: return (MISSION_SCENES.get(mission_id, []) as Array).duplicate()
static func required_physical(scene_id: String) -> Array: return gate(scene_id).get("required_physical", []).duplicate()
static func dialogue_ids(scene_id: String) -> Array:
	var result: Array = []
	for line in range(1, 10):
		var id := "%s-L%02d" % [scene_id, line]
		result.append(id)
	return result

static func targets_for_scene(scene_id: String) -> Array:
	var gate_data := gate(scene_id)
	if gate_data.is_empty(): return []
	var mission_id := String(gate_data.get("mission_id", ""))
	var room_id := String(gate_data.get("room_id", "LOC-01"))
	match scene_id:
		"EX-CH02-S01": return [_target("inspect_alo_identity", room_id, "Inspect Alo identity card", "alo_identity_inspected", mission_id, scene_id), _target("inspect_tara_identity", room_id, "Inspect Tara identity card", "tara_identity_inspected", mission_id, scene_id), _target("ack_live_link", room_id, "Acknowledge the returned live Earth link", "live_link_acknowledged", mission_id, scene_id), _target("open_pollination_protocol", room_id, "Open compatible pollination protocol", "pollination_protocol_opened", mission_id, scene_id, ["alo_identity_inspected", "tara_identity_inspected", "live_link_acknowledged"])]
		"EX-CH02-S02": return [_target("identify_anther", room_id, "Identify pollen-bearing anthers", "anther_identified", mission_id, scene_id), _target("identify_stigma", room_id, "Identify receptive stigmas", "stigma_identified", mission_id, scene_id), _target("assign_brush_directions", room_id, "Assign clean brushes to both directions", "brush_directions_assigned", mission_id, scene_id, ["anther_identified", "stigma_identified"]), _target("practice_transfer_model", room_id, "Complete the nonliving transfer model", "practice_model_complete", mission_id, scene_id, ["brush_directions_assigned"])]
		"EX-CH02-S03": return [_target("check_space_weather", room_id, "Check space-weather status", "space_weather_checked", mission_id, scene_id), _target("prepare_closed_carrier", room_id, "Prepare the closed carrier", "carrier_prepared", mission_id, scene_id, ["space_weather_checked"]), _target("verify_transfer_boundaries", room_id, "Verify pressure-boundary order", "boundary_order_verified", mission_id, scene_id, ["carrier_prepared"]), _target("preview_cycle_budget", room_id, "Preview one complete reciprocal-cycle charge", "cycle_budget_previewed", mission_id, scene_id, ["boundary_order_verified"])]
		"EX-CH02-S04": return _p03_run_one(room_id, mission_id, scene_id)
		"EX-CH02-S05": return _p03_run_later(room_id, mission_id, scene_id)
		"EX-CH02-S06": return [_target("record_stem_prediction", room_id, "Record the purple/green stem prediction", "p03_prediction_recorded", mission_id, scene_id, ["p03_three_runs", "p03_seven_care_dates"], "P-03", "p03_record_prediction", "set_phase", "P-03")]
		"EX-CH02-S07": return [_target("order_lifecycle", room_id, "Order flower-to-harvest stages", "life_cycle_ordered", mission_id, scene_id), _target("separate_current_evidence", room_id, "Separate current evidence from reference images", "current_evidence_separated", mission_id, scene_id, ["life_cycle_ordered"]), _target("inspect_recorder_identifier", room_id, "Inspect the recorder equipment identifier", "recorder_identifier_linked", mission_id, scene_id, ["current_evidence_separated"])]
		"EX-CH02-S08": return [_target("collect_serial_card", room_id, "Photograph the serial plate", "serial_card_collected", mission_id, scene_id), _target("collect_date_card", room_id, "Photograph the maintenance date", "date_card_collected", mission_id, scene_id), _target("collect_trial_stage_card", room_id, "Photograph the trial-stage chart", "trial_stage_card_collected", mission_id, scene_id), _target("exclude_identity_claim", room_id, "Exclude unsupported identity claims", "identity_claim_excluded", mission_id, scene_id, ["serial_card_collected", "date_card_collected", "trial_stage_card_collected"])]
		"EX-CH02-S09": return [_p04_target("assign_date_token", room_id, "Assign the date token", "date", mission_id, scene_id), _p04_target("assign_device_token", room_id, "Assign the device token", "device", mission_id, scene_id), _p04_target("assign_channel_token", room_id, "Assign the channel token", "channel", mission_id, scene_id), _p04_action("verify_local_checksum", room_id, "Verify the reconstructed local checksum", "p04_checksum_verified", mission_id, scene_id, "p04_verify_checksum", ["p04_mapping_complete"]), _p04_action("open_reconstructed_transcript", room_id, "Open the intact reconstructed transcript", "p04_transcript_opened", mission_id, scene_id, "p04_open_transcript", ["p04_checksum_verified"])]
		"EX-CH02-S10": return [_p04_action("play_engineer_fragment", room_id, "Play the dated Engineer recording", "p04_engineer_played", mission_id, scene_id, "p04_play_engineer"), _p04_action("play_n_memory", room_id, "Read the mustard-fields memory", "p04_n_clue_played", mission_id, scene_id, "p04_play_n", ["p04_engineer_played"]), _p04_action("classify_voice_inference", room_id, "Classify voice resemblance as an inference", "p04_inference_classified", mission_id, scene_id, "p04_classify_inference", ["p04_engineer_played", "p04_n_clue_played"])]
		"EX-CH02-S11": return [_p04_action("send_fragment_copy", room_id, "Send the intact technical copy", "p04_copy_sent", mission_id, scene_id, "p04_send_copy"), _p04_action("acknowledge_handover", room_id, "Acknowledge the evening handover", "handover_complete", mission_id, scene_id, "p04_ack_handover", ["p04_copy_sent"])]
		"EX-CH02-S12": return [_target("reach_interior_brace", room_id, "Reach the marked interior brace", "brace_reached", mission_id, scene_id), _target("account_four_cadets", room_id, "Account for all four cadets", "four_accounted", mission_id, scene_id, ["brace_reached"]), _target("finish_quake_beat", room_id, "Finish the quake beat and preserve the record", "quake_beat_finished", mission_id, scene_id, ["four_accounted"])]
	return []

static func _p03_run_one(room_id: String, mission_id: String, scene_id: String) -> Array:
	return [
		_p03_action("scan_tara", room_id, "Scan Tara as donor", mission_id, scene_id, "p03_scan_tara"),
		_p03_action("collect_tara", room_id, "Collect Tara pollen with brush A", mission_id, scene_id, "p03_collect_tara_pollen", ["p03_scan_tara_done"]),
		_p03_action("seal_a", room_id, "Seal carrier A", mission_id, scene_id, "p03_seal_brush_a", ["p03_collect_tara_pollen_done"]),
		_p03_action("transfer_alo", room_id, "Transfer to Alo stigma", mission_id, scene_id, "p03_transfer_to_alo", ["p03_seal_brush_a_done"]),
		_p03_action("scan_alo", room_id, "Scan Alo as donor", mission_id, scene_id, "p03_scan_alo", ["p03_transfer_to_alo_done"]),
		_p03_action("collect_alo", room_id, "Collect Alo pollen with brush B", mission_id, scene_id, "p03_collect_alo_pollen", ["p03_scan_alo_done"]),
		_p03_action("seal_b", room_id, "Seal carrier B", mission_id, scene_id, "p03_seal_brush_b", ["p03_collect_alo_pollen_done"]),
		_p03_action("transfer_tara", room_id, "Transfer to Tara stigma", mission_id, scene_id, "p03_transfer_to_tara", ["p03_seal_brush_b_done"]),
		_p03_action("complete_run_1", room_id, "Commit reciprocal cycle one · E1/A1", mission_id, scene_id, "p03_complete_run_1", ["p03_transfer_to_tara_done"]),
	]

static func _p03_run_later(room_id: String, mission_id: String, scene_id: String) -> Array:
	var result: Array = []
	for day in range(2, 4):
		result.append(_p03_action("care_day_%d" % day, room_id, "Record dated care visit %d/7" % day, mission_id, scene_id, "p03_log_care_day_%d" % day, ["p03_run_1_complete"] if day == 2 else ["p03_log_care_day_%d_done" % (day - 1)]))
	result.append(_p03_action("run_2_forward", room_id, "Run two · Tara to Alo", mission_id, scene_id, "p03_run_2_forward", ["p03_run_1_complete", "p03_log_care_day_3_done"]))
	result.append(_p03_action("run_2_reverse", room_id, "Run two · Alo to Tara", mission_id, scene_id, "p03_run_2_reverse", ["p03_run_2_forward_done"]))
	result.append(_p03_action("complete_run_2", room_id, "Commit reciprocal cycle two · E1/A1", mission_id, scene_id, "p03_complete_run_2", ["p03_run_2_reverse_done"]))
	for day in range(4, 8):
		result.append(_p03_action("care_day_%d" % day, room_id, "Record dated care visit %d/7" % day, mission_id, scene_id, "p03_log_care_day_%d" % day, ["p03_run_2_complete"] if day == 4 else ["p03_log_care_day_%d_done" % (day - 1)]))
	result.append(_p03_action("run_3_forward", room_id, "Run three · Tara to Alo", mission_id, scene_id, "p03_run_3_forward", ["p03_run_2_complete", "p03_log_care_day_7_done"]))
	result.append(_p03_action("run_3_reverse", room_id, "Run three · Alo to Tara", mission_id, scene_id, "p03_run_3_reverse", ["p03_run_3_forward_done"]))
	result.append(_p03_action("complete_run_3", room_id, "Commit reciprocal cycle three · E1/A1", mission_id, scene_id, "p03_complete_run_3", ["p03_run_3_reverse_done"]))
	return result

static func _target(target_id: String, room_id: String, label: String, flag: String, mission_id: String, scene_id: String, required: Array = [], puzzle_id: String = "", action: String = "", command_verb: String = "set_phase", command_target: String = "WORLD_PHYSICAL", defaults: Dictionary = {}) -> Dictionary:
	var result := {"target_id": target_id, "room_id": room_id, "world_focus_id": _world_focus_id(target_id, room_id), "focus_label": label, "verb": "Use", "command_verb": "apply_delta" if command_verb == "ledger_delta" else command_verb, "command_target_id": command_target, "command_id": "physical:%s" % target_id, "owning_mission_id": mission_id, "owning_scene_id": scene_id, "physical_flag": flag, "required_flags": required, "unmet_reason": "Complete the preceding Chapter 2 evidence step first.", "readout": label, "range_m": 3.0, "line_of_sight_required": false}
	if not puzzle_id.is_empty(): result["puzzle_id"] = puzzle_id
	if not action.is_empty(): result["puzzle_action"] = action
	if not defaults.is_empty(): result["payload_defaults"] = defaults
	return result

static func _world_focus_id(target_id: String, room_id: String) -> String:
	match room_id:
		"LOC-01":
			if target_id in ["ack_live_link", "send_fragment_copy", "acknowledge_handover"]: return "commons_earth_screen"
			if target_id in ["record_stem_prediction", "order_lifecycle", "separate_current_evidence", "reach_interior_brace", "account_four_cadets", "finish_quake_beat"]: return "commons_mission_table"
			return "commons_charter"
		"LOC-02":
			if target_id.contains("recorder") or target_id.contains("serial") or target_id.contains("date") or target_id.contains("trial") or target_id.contains("mapping") or target_id.contains("transcript") or target_id.contains("engineer") or target_id.contains("n_memory") or target_id.contains("voice") or target_id.contains("fragment"): return "service_air_console"
			return "service_power_panel"
		"LOC-03":
			if target_id.contains("tara") or target_id.contains("prediction"): return "garden_tara_bay"
			return "garden_alo_glove_port"
		"LOC-05":
			if target_id.contains("scan") or target_id.contains("collect") or target_id.contains("microscope"): return "transfer_microscope"
			if target_id.contains("carrier") or target_id.contains("seal") or target_id.contains("run") or target_id.contains("cycle"): return "transfer_carrier"
			return "transfer_glove_ports"
	return ""

static func _p03_action(target_id: String, room_id: String, label: String, mission_id: String, scene_id: String, action: String, required: Array = [], command_verb: String = "set_phase", defaults: Dictionary = {}) -> Dictionary:
	return _target("p03_" + target_id, room_id, label, action + "_done", mission_id, scene_id, required, "P-03", action, command_verb, "P-03", defaults)

static func _p04_target(target_id: String, room_id: String, label: String, field: String, mission_id: String, scene_id: String, required: Array = []) -> Dictionary:
	var action := "p04_assign_" + field
	return _target(target_id, room_id, label, action + "_done", mission_id, scene_id, required, "P-04", action, "set_phase", "P-04")


static func _p04_action(target_id: String, room_id: String, label: String, flag: String, mission_id: String, scene_id: String, action: String, required: Array = []) -> Dictionary:
	return _target(target_id, room_id, label, flag, mission_id, scene_id, required, "P-04", action, "set_phase", "P-04")
