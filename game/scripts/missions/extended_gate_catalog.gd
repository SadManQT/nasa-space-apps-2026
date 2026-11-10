extends RefCounted
class_name ExtendedGateCatalog

const Chapter2Catalog = preload("res://scripts/missions/chapter2_gate_catalog.gd")
const RoomContract = preload("res://scripts/world/room_contract.gd")
const P05 = preload("res://scripts/puzzles/p05_falling_pressure.gd")
const P06 = preload("res://scripts/puzzles/p06_harvest_future.gd")
const Chapter4 = preload("res://scripts/puzzles/chapter4_puzzles.gd")
const Chapter6 = preload("res://scripts/puzzles/chapter6_puzzles.gd")
const Chapter8 = preload("res://scripts/puzzles/chapter8_puzzles.gd")

static func scene_ids() -> Array:
	var result: Array = []
	for chapter in range(3, 9):
		for order in range(1, 13):
			result.append("EX-CH%02d-S%02d" % [chapter, order])
	return result

static func mission_ids() -> Array:
	var result: Array = []
	for chapter in range(3, 9):
		for mission in range(1, 5):
			result.append("EX-M%02d%02d" % [chapter, mission])
	return result

static func scenes_for_mission(mission_id: String) -> Array:
	var chapter := int(mission_id.substr(4, 2))
	var mission := int(mission_id.substr(6, 2))
	var first := (mission - 1) * 3 + 1
	var result: Array = []
	for order in range(first, first + 3):
		result.append("EX-CH%02d-S%02d" % [chapter, order])
	return result

static func gate(scene_id: String) -> Dictionary:
	var parts := scene_id.split("-")
	if parts.size() != 3: return {}
	var chapter := int(String(parts[1]).trim_prefix("CH"))
	if chapter == 2:
		return Chapter2Catalog.gate(scene_id)
	var order := int(String(parts[2]).trim_prefix("S"))
	var mission_id := "EX-M%02d%02d" % [chapter, int((order - 1) / 3) + 1]
	var actions: Array = _actions(chapter, order)
	var required: Array = []
	for action in actions:
		required.append(String(action) + "_done")
	return {"mission_id": mission_id, "room_id": RoomContract.room_for_scene(scene_id), "predicate_id": "PRED-%s-EXIT" % scene_id, "required_physical": required, "puzzle_id": _puzzle_id(chapter, order)}

static func required_physical(scene_id: String) -> Array:
	return gate(scene_id).get("required_physical", []).duplicate()

static func dialogue_ids(scene_id: String) -> Array:
	var result: Array = []
	for line in range(1, 10): result.append("%s-L%02d" % [scene_id, line])
	return result

static func targets_for_scene(scene_id: String) -> Array:
	if scene_id.begins_with("EX-CH02-"):
		return Chapter2Catalog.targets_for_scene(scene_id)
	var gate_data := gate(scene_id)
	if gate_data.is_empty(): return []
	var chapter := int(scene_id.substr(5, 2))
	var order := int(scene_id.substr(9, 2))
	var puzzle_id := String(gate_data.get("puzzle_id", ""))
	var mission_id := String(gate_data.get("mission_id", ""))
	var room_id := String(gate_data.get("room_id", "LOC-01"))
	var previous := _previous_actions(scene_id)
	var result: Array = []
	for action in _actions(chapter, order):
		var required: Array = previous.duplicate()
		if chapter == 3 and order == 2 and String(action).begins_with("p05_inspect_"):
			# The six candidates can be inspected in any order. Phase capacity is
			# checked by the ledger; all six remain required before the t10 taps.
			required.append("p05_read_return_t0_done")
		else:
			for prior in result:
				required.append(String(prior.get("physical_flag", "")))
		result.append(_target(String(action), room_id, String(action).replace("_", " ").capitalize(), mission_id, scene_id, puzzle_id, required, _defaults(String(action))))
	return result

static func _target(action: String, room_id: String, label: String, mission_id: String, scene_id: String, puzzle_id: String, required: Array, defaults: Dictionary) -> Dictionary:
	if action.begins_with("p05_"):
		label = P05.new().focus_label(action)
	if action.begins_with("p06_"):
		label = P06.new().focus_label(action)
	if Chapter4.is_step(action) and not Chapter4.focus_label(action).is_empty():
		label = Chapter4.focus_label(action)
	if Chapter6.is_step(action) and not Chapter6.focus_label(action).is_empty():
		label = Chapter6.focus_label(action)
	if Chapter8.is_step(action) and not Chapter8.focus_label(action).is_empty():
		label = Chapter8.focus_label(action)
	return {"target_id": action, "room_id": room_id, "world_focus_id": _world_focus_id(action, room_id), "focus_label": label, "verb": "Use", "command_verb": "campaign_operation", "command_target_id": puzzle_id, "command_id": "extended:%s" % action, "owning_mission_id": mission_id, "owning_scene_id": scene_id, "physical_flag": action + "_done", "required_flags": required.filter(func(value): return not String(value).is_empty()), "unmet_reason": "Complete the preceding evidence step before using this target.", "readout": label, "range_m": 3.0, "line_of_sight_required": false, "puzzle_id": puzzle_id, "puzzle_action": action, "payload_defaults": defaults}

static func _world_focus_id(action: String, room_id: String) -> String:
	match room_id:
		"LOC-01":
			if action.contains("log") or action.contains("voice") or action.contains("family") or action.contains("report"):
				return "commons_earth_screen"
			return "commons_mission_table"
		"LOC-02":
			if action.begins_with("p05_inspect_") or action.begins_with("p05_read_"):
				return "service_garden_valve" if action.contains("garden") or action.contains("annex") else "service_air_console"
			if action.contains("air") or action.contains("pressure") or action.contains("oxygen"):
				return "service_air_console"
			return "service_power_panel"
		"LOC-03":
			if action.contains("alo") or action.contains("garden") or action.contains("crop") or action.contains("plant") or action.contains("flower"):
				return "garden_alo_glove_port"
			return "garden_probe"
		"LOC-04":
			if action.contains("water") or action.contains("shelter") or action.contains("occup"):
				return "safe_water_wall"
			return "safe_response_controls"
		"LOC-07":
			if action.contains("hatch") or action.contains("annex"):
				return "annex_hatch_view"
			return "annex_zero_gauge"
		"LOC-08":
			if action.contains("rover") or action.contains("route") or action.contains("loadout"):
				return "rover_loadout"
			return "base_handover"
		"LOC-09":
			if action.contains("beacon") or action.contains("repeater"):
				return "ridge_beacon_pad"
			return "ice_scanner"
		"LOC-10":
			if action.contains("sleeve") or action.contains("case") or action.contains("vault"):
				return "vault_case"
			return "vault_probe"
		"LOC-11":
			if action.contains("relay") or action.contains("controller"):
				return "relay_controller"
			return "repeater_chain"
		"LOC-12":
			if action.contains("bearing") or action.contains("checksum"):
				return "relay_earth_bearing"
			return "relay_isolator"
	return ""

static func _puzzle_id(chapter: int, order: int) -> String:
	return "P-%02d" % (chapter * 2 - 1 if order <= 6 else chapter * 2)

static func _previous_actions(scene_id: String) -> Array:
	# Chapter progression is checked by the route; interaction prerequisites are
	# intentionally limited to the current scene's ordered operations.
	return []

static func _actions(chapter: int, order: int) -> Array:
	match chapter:
		3:
			return [
				["p05_equip_gauge", "p05_read_panel_warning", "p05_identify_three_taps"],
				["p05_read_main_t0", "p05_read_garden_t0", "p05_read_return_t0", "p05_inspect_tank", "p05_inspect_habitat", "p05_inspect_garden", "p05_inspect_return", "p05_inspect_airlock", "p05_inspect_annex", "p05_read_main_t10", "p05_read_garden_t10", "p05_read_return_t10", "p05_identify_garden_fall"],
				["p05_verify_annex_isolation", "p05_preview_garden_isolation", "p05_rollback_check"],
				["p05_isolate_garden", "p05_verify_main_hold", "p05_apply_garden_clamp", "p05_reopen_garden_slow", "p05_stable_read_1", "p05_stable_read_2", "p05_stable_read_3", "p05_stable_read_4", "p05_stable_read_5"],
				["p05_reconcile_records", "p05_save_monitoring_handover"],
				["p05_isolate_annex_feed", "p05_confirm_zero_differential", "p05_inspect_annex_hatch"],
				["p06_scan_growth_chart", "p06_scan_vault_map", "p06_exit_suit_check", "p06_accept_maturity_montage"],
				["p06_save_map_provenance", "p06_record_future_checks", "p06_confirm_care_transition"],
				["p06_confirm_maturity", "p06_configure_drydown"],
				["p06_drydown_five_days", "p06_open_six_pods", "p06_count_42", "p06_allocate_12_30", "p06_sleeve_petal"],
				["p06_plant_12_positions", "p06_seal_reserve_30", "p06_preserve_lineage"],
				["p06_reconcile_continuity", "p06_confirm_descendant_survey"],
			][order - 1]
		4:
			return [
				["p07_compare_prediction", "p07_inspect_twelve_descendants", "p07_record_trait_limits"],
				["p07_check_rover_seal", "p07_check_scanner", "p07_check_closed_carrier", "p07_complete_base_handover"],
				["p07_choose_route_b", "p07_verify_slope", "p07_verify_return_reserve", "p07_prepare_departure"],
				["p07_place_beacon_1", "p07_place_beacon_2", "p07_place_beacon_3"],
				["p07_record_dry_reference", "p07_set_threshold_12", "p07_tag_positive_18", "p07_tag_positive_19", "p07_retain_negative_2"],
				["p07_seal_sample", "p07_commit_return_route"],
				["p08_read_external_probe", "p08_fit_sleeve", "p08_latch_cradle", "p08_secure_mount"],
				["p08_return_to_base", "p08_dock_dry_glovebox", "p08_warm_cold", "p08_warm_cool", "p08_warm_room", "p08_check_condensation", "p08_open_inner_seal", "p08_inventory_12"],
				["p08_scan_lid", "p08_save_viability_pending", "p08_transfer_case"],
				["p08_manifest_reconciled", "p08_personnel_home", "p08_quarantine_complete"],
				["p08_send_manifest", "p08_record_ferreira_question", "p08_leave_identity_open"],
				["p08_check_relief_flight", "p08_prepare_locker", "p08_confirm_december_transition"],
			][order - 1]
		5:
			return [
				["p09_check_lander_clearance", "p09_check_seals", "p09_verify_five_person_roster"],
				["p09_store_spare_once", "p09_run_arrival_readings", "p09_reconcile_readings"],
				["p09_commit_sequence"],
				["p10_document_young_trial", "p10_exclude_flower_claim", "p10_save_source_scope"],
				["p10_acknowledge_ferreira_facts", "p10_acknowledge_personal_question", "p10_preserve_safety_facts"],
				["p10_compare_dust_repair", "p10_compare_leak_repair", "p10_keep_spare_present"],
				["p10_verify_flashes"],
				["p10_clean_panel", "p10_patch_dome_spur", "p10_verify_pressure"],
				["p10_exclude_unsupported_impact_claim", "p10_save_report"],
				["p10_match_noor_identity", "p10_record_consent", "p10_confirm_founder_role"],
				["p10_send_invitation"],
				["p10_plant_cotton", "p10_protect_eleven_vault", "p10_protect_founder_reserve"],
			][order - 1]
		6:
			return [
				["p11_charge_hand_light", "p11_assign_companion", "p11_check_locker"],
				["p11_read_personal_log", "p11_identify_protected_path", "p11_identify_fault_method"],
				["p11_commit_allocation"],
				["p11_remove_decorative_floods", "p11_protect_guide_light", "p11_protect_reserve"],
				["p12_test_branch", "p12_verify_protected_services", "p12_record_rehearsal"],
				["p12_check_four_roles", "p12_check_five_segments", "p12_ready_camera"],
				["p12_log_ingress", "p12_log_ring"],
				["p12_deliver_family_contact", "p12_preserve_observation_qualifications"],
				["p12_store_known_noor_text", "p12_reserve_live_voice"],
				["p12_reset_sequence"],
				["p12_record_egress", "p12_reconcile_recovery_reserve", "p12_save_recovery"],
				["p12_reconcile_monitoring", "p12_date_february_warning", "p12_confirm_care_ledger"],
			][order - 1]
		7:
			return [
				["p13_share_observations", "p13_label_counterfactual", "p13_record_current_state"],
				["p13_confirm_five_person_profile", "p13_confirm_shelter_roster", "p13_confirm_shared_resources"],
				["p13_commit_plan"],
				["p13_latch_founder_reserve", "p13_verify_water_shield", "p13_verify_crate_shield", "p13_verify_drain_order"],
				["p14_confirm_five_occupants", "p14_check_hatch_one", "p14_check_hatch_two"],
				["p14_commit_steps_1_2", "p14_save_forecast_comparison", "p14_confirm_case_sealed"],
				["p14_read_final_log", "p14_record_academy_name", "p14_save_progress_report"],
				["p14_commit_steps_3_6", "p14_confirm_crops_safe", "p14_confirm_reserve_30"],
				["p14_diagnose_external_branch", "p14_route_reading_1", "p14_route_reading_2"],
				["p14_reconcile_local_stability", "p14_reconcile_supplies", "p14_date_march_gate"],
				["p14_pack_controller", "p14_pack_battery", "p14_pack_three_site_route", "p14_bench_test"],
				["p14_assign_field_team", "p14_assign_home_team", "p14_sign_departure_prep"],
			][order - 1]
		8:
			return [
				["p15_confirm_teams", "p15_confirm_loadout", "p15_confirm_roundtrip_provisions"],
				["p15_choose_surveyed_route", "p15_confirm_return_reserve"],
				["p15_reach_marker_two", "p15_set_brake", "p15_save_position_packet"],
				["p15_restore_marker_2", "p15_test_repeater_chain", "p15_reach_approach"],
				["p15_confirm_home_occupancy", "p15_confirm_segment_forecast", "p15_confirm_home_pressure"],
				["p15_confirm_summit", "p15_confirm_home_checks", "p15_receive_summit_packet"],
				["p16_isolate_power", "p16_zero_test", "p16_install_controller", "p16_close_housing", "p16_restore_power"],
				["p16_local_bearing", "p16_earth_bearing", "p16_stable_lock"],
				["p16_checksum", "p16_confirm_path_records", "p16_voice_verification_ready"],
				["p16_noor_live_voice", "p16_confirm_telemetry", "p16_start_return"],
				["p16_confirm_return_24h", "p16_confirm_five_at_aurora", "p16_update_occupancy"],
				["p16_save_final_records", "p16_save_photo", "p16_save_dedication", "p16_make_credits_available"],
			][order - 1]
	return []

## Pre-filled witness payloads for Chapters 3, 5 and 7 receipt gates. P-07, P-08
## (Chapter 4), P-11, P-12 (Chapter 6), and P-15, P-16 (Chapter 8) have none:
## the player decides every value in the puzzle panel.
static func _defaults(action: String) -> Dictionary:
	if Chapter4.is_step(action) or Chapter6.is_step(action) or Chapter8.is_step(action):
		return {}
	if action.begins_with("p05_") or action.begins_with("p06_"):
		return {}
	match action:
		"p07_choose_route_b": return {"route": "B"}
		"p07_verify_slope": return {"slope": 12}
		"p07_verify_return_reserve": return {"reserve": 40}
		"p07_set_threshold_12": return {"reference": 2, "threshold": 12}
		"p07_tag_positive_18": return {"reading": 18}
		"p07_tag_positive_19": return {"reading": 19}
		"p07_retain_negative_2": return {"reading": 2}
		"p08_warm_cold": return {"stage": "cool"}
		"p08_warm_room": return {"stage": "room"}
		"p08_inventory_12": return {"count": 12}
		"p11_commit_allocation": return {"total": 7, "essentials": true, "pump": true, "camera": true}
		"p12_reset_sequence": return {"sequence": ["isolate", "zero", "reset", "reconnect", "camera_test"]}
	return {}
