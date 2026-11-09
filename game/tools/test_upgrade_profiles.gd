## Godot --headless --path game --script res://tools/test_upgrade_profiles.gd
## M3-91: Runs the campaign under all 2^7 = 128 upgrade combinations and checks
## every numeric contract and ending predicate per QA_02_NUMERIC_AND_UPGRADES.md.
extends SceneTree

const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const StateScript = preload("res://scripts/core/campaign_state.gd")
const SimulationScript = preload("res://scripts/simulation/expedition_simulation.gd")
const CampaignLedgerScript = preload("res://scripts/simulation/campaign_ledger_simulation.gd")
const Chapter2RouteScript = preload("res://scripts/missions/chapter2_route.gd")
const Chapter2GateCatalog = preload("res://scripts/missions/chapter2_gate_catalog.gd")
const ExtendedRouteScript = preload("res://scripts/missions/extended_campaign_route.gd")
const ExtendedGateCatalog = preload("res://scripts/missions/extended_gate_catalog.gd")
const ProgressionScript = preload("res://scripts/progression/cadet_progression.gd")

var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_baseline_witnesses()
	_test_all_128_upgrade_profiles()
	_test_boundary_and_deterministic_replay()
	print("UPGRADE PROFILES RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_baseline_witnesses() -> void:
	var sim := SimulationScript.new()
	var base := sim.entry_profile()
	var bloom_shifts := [
		{"heat": "DAY", "air_production": 2, "light": "FULL", "transfer": "HOLD"},
		{"heat": "DAY", "air_production": 0, "light": "FULL", "transfer": "HOLD"},
		{"heat": "COZY", "air_production": 0, "light": "OFF", "transfer": "FILL"},
		{"heat": "COZY", "air_production": 0, "light": "OFF", "transfer": "FILL"},
		{"heat": "COZY", "air_production": 0, "light": "OFF", "transfer": "WAIT"},
		{"heat": "COZY", "air_production": 0, "light": "OFF", "transfer": "DRAIN"},
		{"heat": "COZY", "air_production": 0, "light": "OFF", "transfer": "DRAIN"},
	]
	var golden_shifts := [
		{"heat": "DAY", "air_production": 2, "light": "FULL", "transfer": "HOLD"},
		{"heat": "DAY", "air_production": 0, "light": "FULL", "transfer": "DRAIN"},
		{"heat": "COOL", "air_production": 0, "light": "FULL", "transfer": "DRAIN"},
		{"heat": "COOL", "air_production": 0, "light": "FULL", "transfer": "FILL"},
		{"heat": "COOL", "air_production": 0, "light": "OFF", "transfer": "STACK"},
		{"heat": "COZY", "air_production": 0, "light": "OFF", "transfer": "HOLD"},
		{"heat": "COOL", "air_production": 0, "light": "FULL", "transfer": "DRAIN"},
	]
	var before := base.duplicate(true)
	var bloom_preview := sim.preview(base, {"shifts": bloom_shifts})
	var golden_preview := sim.preview(base, {"shifts": golden_shifts})
	_check(bloom_preview.accepted and bloom_preview.ending == "BLOOM" and base == before, "baseline Bloom witness is accepted and pure")
	_check(golden_preview.accepted and golden_preview.ending == "GOLDEN" and base == before, "baseline Golden witness is accepted and pure")

func _test_all_128_upgrade_profiles() -> void:
	var sim := SimulationScript.new()
	var ledger_sim := CampaignLedgerScript.new()
	var bloom_shifts := [
		{"heat": "DAY", "air_production": 2, "light": "FULL", "transfer": "HOLD"},
		{"heat": "DAY", "air_production": 0, "light": "FULL", "transfer": "HOLD"},
		{"heat": "COZY", "air_production": 0, "light": "OFF", "transfer": "FILL"},
		{"heat": "COZY", "air_production": 0, "light": "OFF", "transfer": "FILL"},
		{"heat": "COZY", "air_production": 0, "light": "OFF", "transfer": "WAIT"},
		{"heat": "COZY", "air_production": 0, "light": "OFF", "transfer": "DRAIN"},
		{"heat": "COZY", "air_production": 0, "light": "OFF", "transfer": "DRAIN"},
	]

	var base_director := DirectorScript.new()
	base_director.new_campaign(CampaignContentFull.EXPECTED_CONTENT_REVISION)
	var handoff: Dictionary = base_director.snapshot()
	handoff["chapter1_ready"] = true
	base_director.restore_snapshot(handoff)
	var ch2 := Chapter2RouteScript.new(base_director)
	_check(bool(ch2.apply_entry_profile().get("accepted", false)), "Chapter 2 pollination entry profile is ready")
	ch2.start_at("EX-CH02-S01")
	for scene_id in Chapter2GateCatalog.SCENE_ORDER:
		for target in ch2.targets_for_current_scene():
			ch2.perform(String(target.get("target_id", "")))
		ch2.advance_scene()
	var post_ch2_base: Dictionary = base_director.snapshot()
	# Strip receipt dictionaries accumulated during Ch2 so each of the 128 runs stays O(1) to clone
	post_ch2_base["receipts"] = {}
	post_ch2_base["mission_receipts"] = {}
	post_ch2_base["interaction_receipts"] = {}

	# Only include operations that CampaignLedgerSimulation._run actually executes
	var active_ops := {
		"EX-CH03-S02": ["p05_read_main_t0", "p05_inspect_tank", "p05_inspect_habitat", "p05_inspect_garden", "p05_inspect_return", "p05_inspect_airlock", "p05_inspect_annex", "p05_read_main_t10"],
		"EX-CH03-S03": ["p05_verify_annex_isolation"],
		"EX-CH03-S04": ["p05_isolate_garden", "p05_verify_main_hold", "p05_apply_garden_clamp", "p05_reopen_garden_slow", "p05_stable_read_1", "p05_stable_read_2", "p05_stable_read_3", "p05_stable_read_4", "p05_stable_read_5"],
		"EX-CH03-S09": ["p06_confirm_maturity", "p06_configure_drydown"],
		"EX-CH03-S10": ["p06_drydown_five_days", "p06_open_six_pods", "p06_count_42", "p06_allocate_12_30", "p06_sleeve_petal"],
		"EX-CH03-S11": ["p06_plant_12_positions", "p06_seal_reserve_30"],
		"EX-CH03-S12": ["p06_confirm_descendant_survey"],
		"EX-CH04-S01": ["p07_inspect_twelve_descendants"],
		"EX-CH04-S03": ["p07_prepare_departure"],
		"EX-CH04-S06": ["p07_commit_return_route"],
		"EX-CH04-S08": ["p08_return_to_base", "p08_warm_cold", "p08_warm_cool", "p08_warm_room", "p08_check_condensation", "p08_open_inner_seal", "p08_inventory_12"],
		"EX-CH05-S02": ["p09_store_spare_once"],
		"EX-CH05-S03": ["p09_commit_sequence"],
		"EX-CH05-S04": ["p10_document_young_trial"],
		"EX-CH05-S08": ["p10_clean_panel", "p10_patch_dome_spur", "p10_verify_pressure"],
		"EX-CH05-S09": ["p10_save_report"],
		"EX-CH05-S11": ["p10_send_invitation"],
		"EX-CH05-S12": ["p10_plant_cotton", "p10_protect_eleven_vault"],
		"EX-CH06-S01": ["p11_charge_hand_light"],
		"EX-CH06-S03": ["p11_commit_allocation"],
		"EX-CH06-S10": ["p12_reset_sequence"],
		"EX-CH06-S11": ["p12_record_egress"],
		"EX-CH07-S01": ["p13_share_observations"],
		"EX-CH07-S03": ["p13_commit_plan"],
		"EX-CH07-S04": ["p13_latch_founder_reserve"],
		"EX-CH07-S06": ["p14_commit_steps_1_2"],
		"EX-CH07-S08": ["p14_commit_steps_3_6"],
		"EX-CH07-S09": ["p14_diagnose_external_branch", "p14_route_reading_1", "p14_route_reading_2"],
		"EX-CH07-S11": ["p14_pack_controller", "p14_pack_battery"],
		"EX-CH08-S01": ["p15_confirm_loadout", "p15_confirm_roundtrip_provisions"],
		"EX-CH08-S02": ["p15_choose_surveyed_route"],
		"EX-CH08-S03": ["p15_set_brake"],
		"EX-CH08-S04": ["p15_restore_marker_2", "p15_test_repeater_chain"],
		"EX-CH08-S05": ["p15_confirm_segment_forecast", "p15_confirm_home_pressure"],
		"EX-CH08-S07": ["p16_isolate_power", "p16_zero_test", "p16_install_controller", "p16_close_housing", "p16_restore_power"],
		"EX-CH08-S08": ["p16_local_bearing", "p16_earth_bearing", "p16_stable_lock"],
		"EX-CH08-S09": ["p16_checksum", "p16_confirm_path_records"],
		"EX-CH08-S10": ["p16_noor_live_voice"],
		"EX-CH08-S11": ["p16_confirm_five_at_aurora"],
		"EX-CH08-S12": ["p16_save_final_records"],
	}
	var active_scenes: Array = active_ops.keys()
	var cached_targets: Dictionary = {}
	for scene_id in active_scenes:
		var wanted: Array = active_ops[scene_id]
		var cmds: Array = []
		for target in ExtendedGateCatalog.targets_for_scene(scene_id):
			var action_id := String(target.get("target_id", ""))
			if not wanted.has(action_id):
				continue
			var payload: Dictionary = target.get("payload_defaults", {}).duplicate(true) if target.get("payload_defaults", {}) is Dictionary else {}
			payload["_puzzle_action"] = action_id
			cmds.append({
				"command_id": String(target.get("command_id", "")),
				"owning_scene_id": scene_id,
				"target_id": String(target.get("command_target_id", action_id)),
				"verb": "campaign_operation",
				"payload": payload,
			})
		cached_targets[scene_id] = cmds

	var ch1_safe_count := 0
	var ch3_leak_count := 0
	var ch4_survey_count := 0
	var ch5_cotton_count := 0
	var ch6_eclipse_count := 0
	var ch7_storm_count := 0
	var ch8_finale_count := 0
	var complete_profiles := 0

	for mask in range(128):
		var choices := {}
		var acquisition := {}
		for ch in range(1, 8):
			var letter := "A" if (mask & (1 << (ch - 1))) != 0 else "B"
			var upgrade_id := String(SimulationScript.UPGRADE_IDS[ch][letter])
			choices[str(ch)] = upgrade_id
			acquisition[str(ch)] = upgrade_id

		# 1. Chapter 1 seven-shift survival under this upgrade profile
		var ch1_entry := sim.entry_profile()
		ch1_entry["upgrades"] = {"choices": choices.duplicate(true), "acquisition_chapter": acquisition.duplicate(true)}
		var ch1_result := sim.preview(ch1_entry, {"shifts": bloom_shifts})
		var ch1_final: Dictionary = ch1_result.get("final_state", {})
		var ch1_ok := bool(ch1_result.get("accepted", false)) and String(ch1_result.get("ending", "")) in ["BLOOM", "GOLDEN"] and float(ch1_final.get("E", -1)) >= 0.0 and float(ch1_final.get("A", 0)) > 0.0 and float(ch1_final.get("H", 0)) > 0.0 and float(ch1_final.get("C", 0)) > 0.0 and float(ch1_final.get("Z", 99)) <= 3.0
		if ch1_ok:
			ch1_safe_count += 1

		# 2. Chapters 3–8 through CampaignLedgerSimulation with incremental acquisition order (Ch 1..7)
		var state: Dictionary = post_ch2_base.duplicate(true)
		state["upgrades"] = {
			"choices": {"1": choices["1"], "2": choices["2"]},
			"acquisition_chapter": {"1": acquisition["1"], "2": acquisition["2"]},
			"applied_profile_revision": "p02-base-v1",
		}
		var ext_ok := true
		var ch3_ok := false
		var ch4_ok := false
		var ch5_ok := false
		var ch6_ok := false
		var ch7_ok := false
		var ch8_ok := false

		for scene_id in active_scenes:
			var projected := ledger_sim.project_scene(state, scene_id)
			if not bool(projected.get("accepted", false)):
				ext_ok = false
				break
			state = projected.snapshot
			for cmd in cached_targets[scene_id]:
				var step_res := ledger_sim.transition(state, cmd)
				if not bool(step_res.get("accepted", false)):
					ext_ok = false
					print("FAIL PROFILE mask=", mask, " scene=", scene_id, " action=", cmd.payload.get("_puzzle_action", ""), " reason=", step_res.get("reason", ""))
					break
				state = step_res.snapshot
				# Trim verbose trace log entries so 128 runs don't accumulate deep arrays
				state.campaign_ledgers["entries"] = []

			if not ext_ok:
				break
			if not ledger_sim.state_predicates(scene_id, state).is_empty():
				ext_ok = false
				break

			match scene_id:
				"EX-CH03-S12":
					ch3_ok = float(state.resources.get("E", -1)) >= 18.0 and int(state.inventories.get("reserve30", 0)) == 30 and int(state.inventories.founder_seed42.get("total", 0)) == 42 and bool(state.inventories.founder_seed42.get("sealed", false))
					state["upgrades"]["choices"]["3"] = choices["3"]
					state["upgrades"]["acquisition_chapter"]["3"] = acquisition["3"]
				"EX-CH04-S08":
					ch4_ok = int(state.route.get("energy", 0)) == 40 and int(state.route.get("provisions", 0)) == 48 and int(state.inventories.vault12.get("stored", 0)) == 12
					state["upgrades"]["choices"]["4"] = choices["4"]
					state["upgrades"]["acquisition_chapter"]["4"] = acquisition["4"]
				"EX-CH05-S12":
					ch5_ok = int(state.inventories.vault12.get("stored", 0)) == 11 and int(state.inventories.get("cotton_planted", 0)) == 1 and int(state.inventories.get("reserve30", 0)) == 30
					state["upgrades"]["choices"]["5"] = choices["5"]
					state["upgrades"]["acquisition_chapter"]["5"] = acquisition["5"]
				"EX-CH06-S11":
					ch6_ok = float(state.resources.get("E", -1)) >= 7.0
					state["upgrades"]["choices"]["6"] = choices["6"]
					state["upgrades"]["acquisition_chapter"]["6"] = acquisition["6"]
				"EX-CH07-S08":
					var samples: Array = state.campaign_ledgers.puzzles.get("P-14", {}).get("samples", [])
					var water_ok := samples.size() == 6
					for s in samples:
						var w: Dictionary = s.get("water_conservation", {})
						water_ok = water_ok and is_equal_approx(float(w.get("garden_usable", 0)) + float(w.get("shield_water", 0)) + float(w.get("separate_reserve_unallocated", 0)), float(w.get("total", -1)))
					ch7_ok = water_ok and float(state.resources.get("E", -1)) >= 6.0 and is_equal_approx(float(state.resources.get("A", 0)), 2.5) and int(state.resources.get("Z", 99)) == 0
				"EX-CH07-S11":
					state["upgrades"]["choices"]["7"] = choices["7"]
					state["upgrades"]["acquisition_chapter"]["7"] = acquisition["7"]
				"EX-CH08-S12":
					var expected_rover_e := 8 if choices["7"] == "long_range_battery" else 4
					var cotton_alive: bool = state.plants.any(func(p): return String(p.get("individual_id", "")) == "COTTON-01" and bool(p.get("alive", false)))
					var alo_archived: bool = state.plants.any(func(p): return String(p.get("individual_id", "")) == "ALO-01" and not bool(p.get("alive", true)) and bool(p.get("harvested", false)))
					ch8_ok = (
						int(state.route.get("energy", -1)) == expected_rover_e
						and int(state.route.get("elapsed_hours", 0)) == 51
						and int(state.route.get("provisions", 0)) == 72
						and int(state.route.get("provisions_remaining", 0)) == 21
						and int(state.route.get("home_elapsed_hours", 0)) == 36
						and int(state.route.get("crew_home", 0)) == 5
						and is_equal_approx(float(state.resources.get("A", 0)), 5.1875)
						and float(state.resources.get("E", -1)) >= 5.0
						and float(state.resources.get("H", 0)) > 0.0
						and float(state.resources.get("C", 0)) > 0.0
						and int(state.inventories.get("reserve30", 0)) == 30
						and int(state.inventories.vault12.get("stored", 0)) == 11
						and cotton_alive
						and alo_archived
						and state.route.get("local_hops", []).size() == 4
						and String(state.route.get("earth_leg", "")) == "verified"
					)

		if ch3_ok:
			ch3_leak_count += 1
		if ch4_ok:
			ch4_survey_count += 1
		if ch5_ok:
			ch5_cotton_count += 1
		if ch6_ok:
			ch6_eclipse_count += 1
		if ch7_ok:
			ch7_storm_count += 1
		if ch8_ok:
			ch8_finale_count += 1
		var acq_keys: Array = state.get("upgrades", {}).get("acquisition_chapter", {}).keys()
		if ch1_ok and ext_ok and ch3_ok and ch4_ok and ch5_ok and ch6_ok and ch7_ok and ch8_ok and acq_keys == ["1", "2", "3", "4", "5", "6", "7"]:
			complete_profiles += 1

	_check(ch1_safe_count == 128, "all 128 upgrade profiles complete Chapter 1 safely")
	_check(ch3_leak_count == 128, "all 128 upgrade profiles satisfy Chapter 3 P-05/P-06 numeric and founder 42=12+30 contracts")
	_check(ch4_survey_count == 128, "all 128 upgrade profiles conserve Chapter 4 rover energy, provisions and 12 vault specimens")
	_check(ch5_cotton_count == 128, "all 128 upgrade profiles satisfy Chapter 5 shield/dust maintenance and 11+1 cotton vault split")
	_check(ch6_eclipse_count == 128, "all 128 upgrade profiles preserve Chapter 6 eclipse reserve")
	_check(ch7_storm_count == 128, "all 128 upgrade profiles survive Chapter 7 6-step solar storm with conserved water")
	_check(ch8_finale_count == 128, "all 128 upgrade profiles satisfy Chapter 8 5.1875 air normalisation, rover reserve, and ending predicates")
	_check(complete_profiles == 128, "all 128 upgrade combinations complete the entire campaign in acquisition order")

func _test_boundary_and_deterministic_replay() -> void:
	# 1. Verify ExtendedCampaignRoute finale scenes (CH08-S01..S12) on both all-A (mask 127) and all-B (mask 0)
	for mask in [0, 127]:
		var director := DirectorScript.new()
		director.new_campaign(CampaignContentFull.EXPECTED_CONTENT_REVISION)
		var state := director.snapshot()
		state["chapter1_ready"] = true
		state["inventories"]["founder_seed42"] = {"total": 42, "allocated": 12, "reserve": 30, "unallocated": 0, "reserve_compartments": [15, 15], "sealed": true}
		state["inventories"]["allocated12"] = 12
		state["inventories"]["reserve30"] = 30
		state["inventories"]["vault12"] = {"total": 12, "stored": 11, "cotton_planted": 1, "stored_after_cotton": 11}
		state["inventories"]["cotton_planted"] = 1
		state["inventories"]["stored11"] = 11
		state["inventories"]["stored12"] = 11
		state["inventories"]["relay_controllers"] = 1
		state["inventories"]["repeater_spare_batteries"] = 1
		var plant_service := preload("res://scripts/biology/plant_service.gd").new()
		state["plants"].append(plant_service.new_plant("COTTON-01", "LINEAGE-VAULT-COTTON", "alive", "2046-12-15 06:00 UTC", {"plant_type": "cotton", "cultivar": "Vault cotton reference"}))
		for p in state["plants"]:
			if String(p.get("individual_id", "")) == "ALO-01":
				p["alive"] = false
				p["harvested"] = true
				p["stage"] = "archived_petal"
		for ch in range(1, 8):
			var letter := "A" if (mask & (1 << (ch - 1))) != 0 else "B"
			state["upgrades"]["choices"][str(ch)] = String(SimulationScript.UPGRADE_IDS[ch][letter])
			state["upgrades"]["acquisition_chapter"][str(ch)] = String(SimulationScript.UPGRADE_IDS[ch][letter])
		director.restore_snapshot(state)
		var route := ExtendedRouteScript.new(director)
		route.start_at("EX-CH08-S01")
		for order in range(1, 13):
			var scene_id := "EX-CH08-S%02d" % order
			for target in ExtendedGateCatalog.targets_for_scene(scene_id):
				route.perform(String(target.get("target_id", "")), target.get("payload_defaults", {}))
			var moved := route.advance_scene()
			if scene_id == "EX-CH08-S12":
				_check(bool(moved.get("campaign_complete", false)), "ExtendedCampaignRoute closes campaign at EX-CH08-S12 for mask " + str(mask))

	# 2. Verify flexible_seals vs moon_dirt_shelter directly on P-05
	for choice in ["moon_dirt_shelter", "flexible_seals"]:
		var director := DirectorScript.new()
		director.new_campaign(CampaignContentFull.EXPECTED_CONTENT_REVISION)
		var state := director.snapshot()
		state["upgrades"]["choices"] = {"1": "taller_mast", "2": "red_blue_leds", "3": choice}
		director.restore_snapshot(state)
		var route := ExtendedRouteScript.new(director)
		route.start_at("EX-CH03-S01")
		for scene_id in ["EX-CH03-S01", "EX-CH03-S02", "EX-CH03-S03", "EX-CH03-S04"]:
			for target in ExtendedGateCatalog.targets_for_scene(scene_id):
				route.perform(String(target.get("target_id", "")), target.get("payload_defaults", {}))
			if scene_id != "EX-CH03-S04":
				route.advance_scene()
		var after := director.snapshot()
		var expected_a := 4.5 if choice == "flexible_seals" else 3.0
		_check(is_equal_approx(float(after.resources.get("A", 0)), expected_a), "P-05 air with pre-applied %s equals %.1f" % [choice, expected_a])

	# 3. Verify deterministic replay: running identical upgrade profile twice produces identical state hashes
	var hashes: Array[String] = []
	for attempt in range(2):
		var director := DirectorScript.new()
		director.new_campaign(CampaignContentFull.EXPECTED_CONTENT_REVISION)
		var state := director.snapshot()
		state["inventories"]["relay_controllers"] = 1
		state["inventories"]["repeater_spare_batteries"] = 1
		state["upgrades"]["choices"] = {"1": "fuel_cell", "2": "insulation_blankets", "3": "flexible_seals", "4": "ice_harvester", "5": "dust_shield", "6": "bigger_safe_room", "7": "long_range_battery"}
		director.restore_snapshot(state)
		var route := ExtendedRouteScript.new(director)
		route.start_at("EX-CH08-S01")
		for scene_id in ["EX-CH08-S01", "EX-CH08-S02", "EX-CH08-S03", "EX-CH08-S04", "EX-CH08-S05"]:
			for target in ExtendedGateCatalog.targets_for_scene(scene_id):
				route.perform(String(target.get("target_id", "")), target.get("payload_defaults", {}))
			if scene_id != "EX-CH08-S05":
				route.advance_scene()
		hashes.append(JSON.stringify(director.snapshot().resources) + "|" + JSON.stringify(director.snapshot().route))
	_check(hashes[0] == hashes[1], "identical upgrade profile and input trace produce bit-identical state hashes")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)
