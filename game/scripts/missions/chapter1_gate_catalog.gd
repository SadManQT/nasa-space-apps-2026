extends RefCounted
class_name Chapter1GateCatalog

const SCENE_ORDER := [
	"EX-CH01-S01", "EX-CH01-S02", "EX-CH01-S03",
	"EX-CH01-S04", "EX-CH01-S05", "EX-CH01-S06",
	"EX-CH01-S07", "EX-CH01-S08", "EX-CH01-S09",
	"EX-CH01-S10", "EX-CH01-S11", "EX-CH01-S12",
]

const MISSION_SCENES := {
	"EX-M0101": ["EX-CH01-S01", "EX-CH01-S02", "EX-CH01-S03"],
	"EX-M0102": ["EX-CH01-S04", "EX-CH01-S05", "EX-CH01-S06"],
	"EX-M0103": ["EX-CH01-S07", "EX-CH01-S08", "EX-CH01-S09"],
	"EX-M0104": ["EX-CH01-S10", "EX-CH01-S11", "EX-CH01-S12"],
}

const _GATES := {
	"EX-CH01-S01": {
		"mission_id": "EX-M0101", "room_id": "LOC-01", "predicate_id": "PRED-EX-CH01-S01-EXIT", "evidence_tag": "Simulated",
		"required_physical": ["commission_route_confirmed", "commission_result_inspected", "charter_acknowledged"],
		"dialogue_ids": ["EX-CH01-S01-L01", "EX-CH01-S01-L02", "EX-CH01-S01-L03", "EX-CH01-S01-L04"],
	},
	"EX-CH01-S02": {
		"mission_id": "EX-M0101", "room_id": "LOC-04", "predicate_id": "PRED-EX-CH01-S02-EXIT", "evidence_tag": "Simulated",
		"required_physical": ["information_classified", "roll_call_complete", "practice_fault_resolved"],
		"dialogue_ids": ["EX-CH01-S02-L01", "EX-CH01-S02-L02", "EX-CH01-S02-L03", "EX-CH01-S02-L04"],
	},
	"EX-CH01-S03": {
		"mission_id": "EX-M0101", "room_id": "LOC-01", "predicate_id": "PRED-EX-CH01-S03-EXIT", "evidence_tag": "Simulated",
		"required_physical": ["packet_inspected", "probe_calibrated", "atmosphere_compared"],
		"dialogue_ids": ["EX-CH01-S03-L01", "EX-CH01-S03-L02", "EX-CH01-S03-L03", "EX-CH01-S03-L04", "EX-CH01-S03-L05"],
	},
	"EX-CH01-S04": {
		"mission_id": "EX-M0102", "room_id": "LOC-03", "predicate_id": "PRED-EX-CH01-S04-EXIT", "evidence_tag": "Simulated",
		"required_physical": ["alo_planted", "tara_planted", "paired_records", "services_confirmed"],
		"dialogue_ids": ["EX-CH01-S04-L01", "EX-CH01-S04-L02", "EX-CH01-S04-L03", "EX-CH01-S04-L04"],
	},
	"EX-CH01-S05": {
		"mission_id": "EX-M0102", "room_id": "LOC-02", "predicate_id": "PRED-EX-CH01-S05-EXIT", "evidence_tag": "Fiction",
		"required_physical": ["lamp_installed", "care_visits_complete", "date_transition_confirmed"],
		"dialogue_ids": ["EX-CH01-S05-L01", "EX-CH01-S05-L02", "EX-CH01-S05-L03", "EX-CH01-S05-L04"],
	},
	"EX-CH01-S06": {
		"mission_id": "EX-M0102", "room_id": "LOC-01", "predicate_id": "PRED-EX-CH01-S06-EXIT", "evidence_tag": "Computed-pending",
		"required_physical": ["timelines_correct", "schedule_acknowledged"],
		"dialogue_ids": ["EX-CH01-S06-L01", "EX-CH01-S06-L02", "EX-CH01-S06-L03", "EX-CH01-S06-L04"],
	},
	"EX-CH01-S07": {
		"mission_id": "EX-M0103", "room_id": "LOC-02", "predicate_id": "PRED-EX-CH01-S07-EXIT", "evidence_tag": "Simulated",
		"required_physical": ["role_acknowledged", "shift1_committed", "shift2_preview_staged", "paused_before_drill"],
		"dialogue_ids": ["EX-CH01-S07-L01", "EX-CH01-S07-L02", "EX-CH01-S07-L03", "EX-CH01-S07-L04"],
	},
	"EX-CH01-S08": {
		"mission_id": "EX-M0103", "room_id": "LOC-04", "predicate_id": "PRED-EX-CH01-S08-EXIT", "evidence_tag": "Simulated",
		"required_physical": ["shelter_drill_complete", "roll_call_complete", "pre_drill_baseline_verified", "shift2_committed_at_18"],
		"dialogue_ids": ["EX-CH01-S08-L01", "EX-CH01-S08-L02", "EX-CH01-S08-L03", "EX-CH01-S08-L04"],
	},
	"EX-CH01-S09": {
		"mission_id": "EX-M0103", "room_id": "LOC-01", "predicate_id": "PRED-EX-CH01-S09-EXIT", "evidence_tag": "Simulated",
		"required_physical": ["cards_combined", "earth_set_acknowledged", "shifts3_4_resolved"],
		"dialogue_ids": ["EX-CH01-S09-L01", "EX-CH01-S09-L02", "EX-CH01-S09-L03", "EX-CH01-S09-L04"],
	},
	"EX-CH01-S10": {
		"mission_id": "EX-M0104", "room_id": "LOC-04", "predicate_id": "PRED-EX-CH01-S10-EXIT", "evidence_tag": "Simulated",
		"required_physical": ["four_sheltered", "alarm_response_committed"],
		"dialogue_ids": ["EX-CH01-S10-L01", "EX-CH01-S10-L02", "EX-CH01-S10-L03", "EX-CH01-S10-L04"],
	},
	"EX-CH01-S11": {
		"mission_id": "EX-M0104", "room_id": "LOC-03", "predicate_id": "PRED-EX-CH01-S11-EXIT", "evidence_tag": "Simulated",
		"required_physical": ["exposure_before_drain_verified", "water_returned", "final_shifts_resolved", "outcome_reviewed"],
		"dialogue_ids": ["EX-CH01-S11-L01", "EX-CH01-S11-L02", "EX-CH01-S11-L03", "EX-CH01-S11-L04"],
	},
	"EX-CH01-S12": {
		"mission_id": "EX-M0104", "room_id": "LOC-03", "predicate_id": "PRED-EX-CH01-S12-EXIT", "evidence_tag": "Fiction",
		"required_physical": ["chamber_conditions_verified", "shutter_opened", "bloom_image_tagged", "tara_inspected", "debrief_complete"],
		"dialogue_ids": ["EX-CH01-S12-L01", "EX-CH01-S12-L02", "EX-CH01-S12-L03", "EX-CH01-S12-L04"],
	},
}

static func scene_ids() -> Array:
	return SCENE_ORDER.duplicate()

static func mission_ids() -> Array:
	return ["EX-M0101", "EX-M0102", "EX-M0103", "EX-M0104"]

static func gate(scene_id: String) -> Dictionary:
	return (_GATES.get(scene_id, {}) as Dictionary).duplicate(true)

static func scenes_for_mission(mission_id: String) -> Array:
	return (MISSION_SCENES.get(mission_id, []) as Array).duplicate()

static func is_chapter1_scene(scene_id: String) -> bool:
	return SCENE_ORDER.has(scene_id)

static func required_physical(scene_id: String) -> Array:
	return gate(scene_id).get("required_physical", []).duplicate()

static func dialogue_ids(scene_id: String) -> Array:
	return gate(scene_id).get("dialogue_ids", []).duplicate()

static func targets_for_scene(scene_id: String) -> Array:
	var gate_data := gate(scene_id)
	if gate_data.is_empty():
		return []
	var mission_id := String(gate_data.get("mission_id", ""))
	var room_id := String(gate_data.get("room_id", "LOC-01"))
	var targets: Array = []
	match scene_id:
		"EX-CH01-S01":
			targets.append(_target("commission_route", room_id, "Trace production, storage and overflow", "commission_route_confirmed", mission_id, scene_id))
			targets.append(_target("commission_result", room_id, "Inspect commissioning result", "commission_result_inspected", mission_id, scene_id, ["commission_route_confirmed"]))
			targets.append(_target("charter_card", room_id, "Acknowledge charter and emergency limits", "charter_acknowledged", mission_id, scene_id))
		"EX-CH01-S02":
			targets.append(_target("classify_information", room_id, "Classify local, stored and live-link information", "information_classified", mission_id, scene_id))
			targets.append(_target("roll_call", room_id, "Complete four-person roll call", "roll_call_complete", mission_id, scene_id))
			targets.append(_target("practice_fault", room_id, "Resolve disconnected practice fault", "practice_fault_resolved", mission_id, scene_id, ["information_classified"]))
		"EX-CH01-S03":
			targets.append(_p01_target("inspect_packet", room_id, "Inspect sealed packet and record", "scan_packet", mission_id, scene_id, ["p01_rechecked"]))
			targets.append(_p01_target("calibrate_probe", room_id, "Calibrate dry and wet references", "set_zero", mission_id, scene_id))
			targets.append(_p01_target("span_probe", room_id, "Set wet reference span", "set_span", mission_id, scene_id, ["p01_zeroed"]))
			targets.append(_p01_target("recheck_probe", room_id, "Recheck dry zero and wet span", "recheck", mission_id, scene_id, ["p01_spanned"]))
			targets.append(_target("compare_atmosphere", room_id, "Compare both pressurised chamber diagrams", "atmosphere_compared", mission_id, scene_id, ["p01_scanned"]))
		"EX-CH01-S04":
			targets.append(_p01_target("plant_alo", room_id, "Plant one seed in the sealed Alo cassette", "plant_alo", mission_id, scene_id, ["p01_scanned"]))
			targets.append(_p01_target("plant_tara", room_id, "Plant one seed in the sealed Tara cassette", "plant_tara", mission_id, scene_id, ["p01_scanned"]))
			targets.append(_p01_target("water_alo", room_id, "Set Alo moisture to the calibrated band", "water_alo", mission_id, scene_id, ["alo_planted", "tara_planted"]))
			targets.append(_p01_target("water_tara", room_id, "Set Tara moisture to the calibrated band", "water_tara", mission_id, scene_id, ["alo_planted", "tara_planted"]))
			targets.append(_p01_target("label_alo", room_id, "Label Alo EXTERNAL TEST", "label_alo_external", mission_id, scene_id, ["alo_watered", "tara_watered"]))
			targets.append(_p01_target("label_tara", room_id, "Label Tara INDOOR REFERENCE", "label_tara_indoor", mission_id, scene_id, ["alo_watered", "tara_watered"]))
			targets.append(_p01_target("seal_alo", room_id, "Close Alo cassette seal", "seal_alo", mission_id, scene_id, ["alo_labelled", "tara_labelled"]))
			targets.append(_p01_target("seal_tara", room_id, "Close Tara cassette seal", "seal_tara", mission_id, scene_id, ["alo_labelled", "tara_labelled"]))
			targets.append(_target("record_paired_conditions", room_id, "Record paired conditions and photographs", "paired_records", mission_id, scene_id, ["p01_complete"]))
			targets.append(_target("confirm_services", room_id, "Confirm both chamber service connections", "services_confirmed", mission_id, scene_id, ["paired_records"]))
		"EX-CH01-S05":
			targets.append(_target("test_hand_light", room_id, "Test and hang the hand light", "lamp_installed", mission_id, scene_id))
			targets.append(_target("care_montage", room_id, "Complete the dated care observations", "care_visits_complete", mission_id, scene_id, ["lamp_installed"]))
			targets.append(_target("confirm_date_transition", room_id, "Confirm the explicit dated transition", "date_transition_confirmed", mission_id, scene_id, ["care_visits_complete"]))
		"EX-CH01-S06":
			targets.append(_target("arrange_timeline", room_id, "Arrange independent Sun, link and station tracks", "timelines_correct", mission_id, scene_id))
			targets.append(_target("ack_schedule", room_id, "Acknowledge the shared preparation schedule", "schedule_acknowledged", mission_id, scene_id, ["timelines_correct"]))
		"EX-CH01-S07":
			targets.append(_target("role_cards", room_id, "Read and acknowledge the four role constraints", "role_acknowledged", mission_id, scene_id))
			targets.append(_p02_target("p02_shift1", room_id, "Preview and commit daylight shift 1", mission_id, scene_id, "p02-shift-1"))
			targets.append(_p02_target("p02_stage_shift2", room_id, "Stage shift 2 forecast before the drill", mission_id, scene_id, "p02-stage-shift-2"))
		"EX-CH01-S08":
			targets.append(_target("shelter_drill", room_id, "Rehearse shelter entry and roll call", "shelter_drill_complete", mission_id, scene_id))
			targets.append(_target("verify_drill_baseline", room_id, "Verify the unchanged pre-drill baseline", "pre_drill_baseline_verified", mission_id, scene_id, ["shelter_drill_complete"]))
			targets.append(_p02_target("p02_shift2", room_id, "Commit daylight shift 2 at the dated gate", mission_id, scene_id, "p02-shift-2"))
		"EX-CH01-S09":
			targets.append(_target("combine_cards", room_id, "Combine Mei and Rafi observations", "cards_combined", mission_id, scene_id))
			targets.append(_target("ack_earth_set", room_id, "Acknowledge the Earth-set cutoff", "earth_set_acknowledged", mission_id, scene_id, ["cards_combined"]))
			targets.append(_p02_target("p02_shifts3_4", room_id, "Resolve dark shifts 3 and 4", mission_id, scene_id, "p02-shifts-3-4"))
		"EX-CH01-S10":
			targets.append(_target("confirm_four_sheltered", room_id, "Confirm all four cadets sheltered", "four_sheltered", mission_id, scene_id))
			targets.append(_p02_target("p02_shift5_alarm", room_id, "Select and resolve one exclusive alarm response", mission_id, scene_id, "p02-shift-5"))
		"EX-CH01-S11":
			targets.append(_target("verify_exposure_order", room_id, "Verify exposure before the water drain", "exposure_before_drain_verified", mission_id, scene_id))
			targets.append(_target("return_water", room_id, "Return the borrowed water at the legal gate", "water_returned", mission_id, scene_id, ["exposure_before_drain_verified"]))
			targets.append(_p02_target("p02_shifts6_7", room_id, "Resolve final dark shifts 6 and 7", mission_id, scene_id, "p02-shifts-6-7"))
			targets.append(_target("review_outcome", room_id, "Review the causal outcome and retry option", "outcome_reviewed", mission_id, scene_id, ["final_shifts_resolved"]))
		"EX-CH01-S12":
			targets.append(_target("verify_chamber", room_id, "Verify chamber pressure and conditions", "chamber_conditions_verified", mission_id, scene_id, ["outcome_reviewed"]))
			targets.append(_target("open_shutter", room_id, "Open the safe viewing shutter", "shutter_opened", mission_id, scene_id, ["chamber_conditions_verified"]))
			targets.append(_target("tag_bloom", room_id, "Tag the first-bloom image", "bloom_image_tagged", mission_id, scene_id, ["shutter_opened"]))
			targets.append(_target("inspect_tara", room_id, "Inspect Tara in the reference bay", "tara_inspected", mission_id, scene_id, ["bloom_image_tagged"]))
			targets.append(_target("complete_debrief", room_id, "Complete the decision and evidence debrief", "debrief_complete", mission_id, scene_id, ["tara_inspected"]))
	return targets

static func _target(target_id: String, room_id: String, label: String, physical_flag: String, mission_id: String, scene_id: String, required_flags: Array = []) -> Dictionary:
	return {
		"target_id": target_id,
		"room_id": room_id,
		"focus_label": label,
		"world_focus_id": _world_focus_id(target_id, room_id),
		"verb": "Inspect" if physical_flag.ends_with("inspected") or physical_flag in ["commission_result_inspected", "packet_inspected"] else "Use",
		"command_verb": "set_phase",
		"command_target_id": "WORLD_PHYSICAL",
		"command_id": "physical:%s" % target_id,
		"owning_mission_id": mission_id,
		"owning_scene_id": scene_id,
		"physical_flag": physical_flag,
		"required_flags": required_flags,
		"unmet_reason": "Complete the preceding physical check before using this target.",
		"readout": label,
		"range_m": 3.0,
		"line_of_sight_required": false,
	}

static func _world_focus_id(target_id: String, room_id: String) -> String:
	match room_id:
		"LOC-01":
			if target_id == "charter_card": return "commons_charter"
			if target_id == "ack_earth_set": return "commons_earth_screen"
			return "commons_mission_table"
		"LOC-02":
			if target_id == "test_hand_light": return "service_hand_light"
			if target_id == "care_montage": return "service_air_console"
			return "service_power_panel"
		"LOC-03":
			if target_id.contains("tara"): return "garden_tara_bay"
			if target_id == "open_shutter": return "garden_shutter"
			if target_id in ["verify_exposure_order", "return_water", "p02_shifts6_7", "review_outcome", "record_paired_conditions", "confirm_services", "complete_debrief"]: return "garden_probe"
			return "garden_alo_glove_port"
		"LOC-04":
			if target_id in ["roll_call", "shelter_drill", "confirm_four_sheltered"]: return "safe_roll_call_board"
			return "safe_response_controls"
	return ""

static func _p01_target(target_id: String, room_id: String, label: String, action: String, mission_id: String, scene_id: String, required_flags: Array = []) -> Dictionary:
	var result := _target(target_id, room_id, label, "", mission_id, scene_id, required_flags)
	result["puzzle_id"] = "P-01"
	result["puzzle_action"] = action
	result["verb"] = "Use"
	return result

static func _p02_target(target_id: String, room_id: String, label: String, mission_id: String, scene_id: String, command_id: String) -> Dictionary:
	var result := _target(target_id, room_id, label, "", mission_id, scene_id)
	result["puzzle_id"] = "P-02"
	result["command_verb"] = "commit_shift"
	result["command_target_id"] = "P-02"
	result["command_id"] = command_id
	result["verb"] = "Use"
	return result
