extends RefCounted
class_name CampaignLedgerSimulation

const Economy = preload("res://scripts/simulation/expedition_simulation.gd")
const Plants = preload("res://scripts/biology/plant_service.gd")
const Gates = preload("res://scripts/missions/extended_gate_catalog.gd")
const Answers = preload("res://scripts/puzzles/extended_puzzle_ledger.gd")
const Clock = preload("res://resources/campaign/campaign_clock.json")
const Rules = preload("res://resources/campaign/profiles/campaign_rules.json")
static var _profiles: Dictionary = {}
var _economy := Economy.new()
var _plants := Plants.new()
var _work: Dictionary
var _book: Dictionary
var _error := ""
var _summary: Array
var _trace: Array

func _begin(snapshot: Dictionary) -> void:
	_work = snapshot.duplicate(true)
	if not _work.has("campaign_ledgers"):
		_work["campaign_ledgers"] = {"profiles": {}, "puzzles": {}, "operations": {}, "entries": [], "food_sampled": 0.0, "food_period_start": _work.scenario_datetime}
	_book = _work.campaign_ledgers
	_error = ""
	_trace = []
	_summary = []

func project_scene(snapshot: Dictionary, scene_id: String) -> Dictionary:
	_begin(snapshot)
	var entry: Dictionary = Clock.data.scenes.get(scene_id, {})
	if not entry.is_empty():
		_date(String(entry.not_before))
		_work["scenario_time_precision"] = entry.precision
	var entry_profiles := {"EX-CH03-S01": "p05", "EX-CH04-S01": "p07", "EX-CH05-S04": "p10", "EX-CH06-S01": "p11", "EX-CH07-S01": "p13", "EX-CH08-S01": "p15"}
	if entry_profiles.has(scene_id):
		_enter_profile(entry_profiles[scene_id])
	if _work.scene_id != scene_id:
		_work.scene_phase = "briefing"
	_work.chapter_id = scene_id.substr(3, 4)
	_work.scene_id = scene_id
	_work.mission_id = Gates.gate(scene_id).get("mission_id", _work.mission_id) if int(scene_id.substr(5, 2)) >= 3 else "EX-M02%02d" % (int((int(scene_id.substr(9, 2)) - 1) / 3) + 1)
	_work.explicit_time_receipts["scene:" + scene_id] = _work.scenario_datetime
	return _result(snapshot)

func transition(snapshot: Dictionary, command: Dictionary) -> Dictionary:
	_begin(snapshot)
	var payload: Dictionary = command.get("payload", {})
	var action := String(payload.get("_puzzle_action", ""))
	var puzzle_id := String(command.get("target_id", ""))
	var owning_scene := String(command.get("owning_scene_id", ""))
	var targets: Array = Gates.targets_for_scene(owning_scene)
	if not targets.any(func(target): return target.target_id == action and target.command_id == command.get("command_id")):
		_error = "This operation does not belong to the current physical scene."
		return _result(snapshot)
	var check := Answers.new().preview(puzzle_id, action, payload)
	if not check.accepted:
		_error = check.reason
		return _result(snapshot)
	var profile_key: String = {"P-05": "p05", "P-07": "p07", "P-10": "p10", "P-11": "p11", "P-13": "p13", "P-14": "p13", "P-15": "p15"}.get(puzzle_id, "")
	if not profile_key.is_empty():
		_enter_profile(profile_key)
		var entry_summary: String = _book.profiles.get(profile_key, {}).get("summary", "")
		if not entry_summary.is_empty() and not _summary.has(entry_summary):
			_summary.append(entry_summary)
	if not _error.is_empty():
		return _result(snapshot)
	if Clock.data.operations.has(action):
		_date(String(Clock.data.operations[action]))
	var puzzle := _puzzle(puzzle_id)
	_run(action, payload, puzzle)
	if not _error.is_empty():
		return _result(snapshot)
	_puzzle(puzzle_id).operations[action] = payload.duplicate(true)
	_book.operations[action] = {"scene_id": owning_scene, "when": _work.scenario_datetime}
	if puzzle_id == "P-06":
		_summary.append("Alo: %s. Founder lot %s; planting allocation %s; protected reserve %s." % [String(_plant("ALO-01").get("stage", "not recorded")).replace("_", " "), _work.inventories.founder_seed42.get("total", 0), _work.inventories.allocated12, _work.inventories.reserve30])
		var tara_line := _tara_summary()
		if not tara_line.is_empty():
			_summary.append(tara_line)
	if action.begins_with("p10_") and _work.inventories.get("cotton_planted", 0) > 0:
		_summary.append("Cotton planted 15 December; eleven vault specimens remain stored. Founder reserve stays separate.")
	if action == "p16_save_final_records":
		_summary.append("Home night complete: E %s; A %s; H %s; C %s; R %s crew-days." % [_work.resources.E, _work.resources.A, _work.resources.H, _work.resources.C, _work.resources.R])
	if _work.route.get("trip_id") == "p15":
		_summary.append("Rover: E %s; journey %s/%s h; home night %s/36 h. Rover supplies are separate from home air and food." % [_work.route.energy, _work.route.elapsed_hours, _work.route.provisions, _work.route.home_elapsed_hours])
	_work.scene_phase = "operation:" + action
	_book.entries.append({"kind": "physical_operation", "action": action, "scenario_datetime": _work.scenario_datetime, "before": snapshot.resources.duplicate(true), "after": _work.resources.duplicate(true), "samples": _trace.duplicate(true)})
	return _result(snapshot)

func _result(original: Dictionary) -> Dictionary:
	if not _error.is_empty():
		return {"accepted": false, "reason": _error, "snapshot": original.duplicate(true), "trace": _trace.duplicate(true)}
	var deltas: Array = []
	for key in _work.resources:
		if _work.resources[key] != original.resources.get(key):
			deltas.append({"field": "resources." + key, "from": original.resources.get(key), "to": _work.resources[key]})
	return {"accepted": true, "reason": "Operation recorded. Review the updated readings.", "ledger_summary": _summary.duplicate(), "snapshot": _work.duplicate(true), "deltas": deltas, "trace": _trace.duplicate(true), "events": [{"type": "campaign_ledger_transition"}], "warnings": [], "unsafe_predicates": [], "next_phase": _work.scene_phase}

func _puzzle(id: String) -> Dictionary:
	if not _book.puzzles.has(id):
		_book.puzzles[id] = {"operations": {}, "phase": 0, "samples": []}
	return _book.puzzles[id]

func _profile(key: String) -> Dictionary:
	if not _profiles.has(key):
		_profiles[key] = Economy.load_profile(key + "_campaign")
	return _profiles[key].duplicate(true)

func _enter_profile(key: String) -> void:
	if _book.profiles.has(key):
		return
	var profile := _profile(key)
	if profile.is_empty():
		_error = "Campaign resource profile is unavailable."
		return
	var before: Dictionary = _work.resources.duplicate(true)
	var food_before := float(before.R)
	var target_food := float(profile.resources.get("R", food_before))
	var start := String(_book.food_period_start)
	var end := String(_work.scenario_datetime)
	var relief := String(Rules.data.logistics.relief_date)
	var before_relief := maxf(0, (_seconds(mini_string(end, relief)) - _seconds(start)) / 86400.0) if start < relief else 0.0
	var after_relief := maxf(0, (_seconds(end) - _seconds(maxi_string(start, relief))) / 86400.0) if end > relief else 0.0
	var calendar_food := before_relief * float(Rules.data.logistics.crew_before_relief) + after_relief * float(Rules.data.logistics.crew_after_relief)
	var unsampled := maxf(0, calendar_food - float(_book.food_sampled))
	var crop_yield := 0.0
	if profile.get("scheduled_mature_crop", false):
		# A scheduled, observed mature batch in the explicit continuity ledger;
		# no invented elapsed growth rate or automatic one-shift harvest.
		crop_yield = snappedf(float(Rules.data.logistics.crop_yield_scale) * float(before.C) / float(before.crop_capacity), 0.1)
	var supply := maxf(0, target_food - food_before + unsampled - crop_yield)
	var remaining := food_before + supply + crop_yield - unsampled
	for field in profile.get("capacities", {}):
		_work.resources[field] = profile.capacities[field]
	for field in profile.resources:
		_work.resources[field] = profile.resources[field]
	_work.resources.R = remaining
	var modifiers := _economy.campaign_modifiers(_work)
	if modifiers.fuel_cell:
		_work.resources.energy_capacity = maxf(_work.resources.energy_capacity, Rules.data.upgrade.fuel_cell_capacity)
		_work.resources.E = minf(_work.resources.energy_capacity, float(_work.resources.E) + Rules.data.upgrade.fuel_cell_entry)
	_book.entries.append({"kind": "authored_entry_logistics", "profile": key, "from_datetime": start, "to_datetime": end, "before": before, "after": _work.resources.duplicate(true), "food": {"calendar_consumption": calendar_food, "sampled_already_charged": _book.food_sampled, "unsampled_consumption": unsampled, "scheduled_mature_harvest": crop_yield, "new_batch_condition": profile.resources.get("C", before.C), "scheduled_supply": supply, "supply_basis": "Derived balance of authored entry stock and explicit stable-operation interval; not free food from exploration."}})
	if profile.get("scheduled_mature_crop", false):
		_refresh_replacement_cohort()
	_summary.append("Dated station ledger: R %s + scheduled supply %s + mature crop harvest %s - background consumption %s = %s crew-days. Sampled consumption is counted once." % [food_before, supply, crop_yield, unsampled, remaining])
	_book.food_period_start = end
	_book.food_sampled = 0.0
	_book.profiles[key] = {"entered_at": end, "modifiers": modifiers.duplicate(true), "summary": _summary.back()}
	if key == "p07" or key == "p15":
		_work.route = {"trip_id": key, "roster": ["kai", "rafi"] if key == "p07" else ["ferreira", "kai", "rafi"], "home_roster": ["mei", "amara"], "energy": profile.rover_energy, "capacity": profile.rover_energy, "return_reserve": profile.rover_reserve, "allowance": profile.rover_allowance, "provisions": profile.rover_provisions, "elapsed_hours": 0.0, "departure": "", "return": "", "local_hops": [], "earth_leg": "unverified", "home_elapsed_hours": 0.0}
		if key == "p15" and modifiers.long_range_battery:
			_work.route.energy += Rules.data.upgrade.long_range_battery
			_work.route.capacity += Rules.data.upgrade.long_range_battery

func _sample(id: String, settings: Dictionary) -> void:
	if not _error.is_empty():
		return
	var result := _economy.sampled_phase(_work, settings)
	if not result.accepted:
		_error = result.reason
		_trace.append({"unsafe_projection": result.get("projected_resources", {})})
		return
	# Rebind dictionary references after the pure sample returns a new snapshot.
	_work = result.snapshot
	_book = _work.campaign_ledgers
	var puzzle := _puzzle(id)
	puzzle.phase += 1
	puzzle.samples.append(result.trace)
	_trace.append(result.trace)
	_summary.append("Sample %d: E %s to %s; A %s to %s; R %s to %s; shelter during exposure S%d; game exposure +%s." % [puzzle.phase, result.trace.before.E, result.trace.after.E, result.trace.before.A, result.trace.after.A, result.trace.before.R, result.trace.after.R, result.trace.shelter, result.trace.dose])
	if id == "P-05":
		_summary.append("P-05 phases are a resource budget. Story time follows the dated scene cards.")
	_book.food_sampled = float(_book.food_sampled) + float(settings.get("food_consumption", 0.0)) * float(settings.get("fraction", 1))

func _date(when: String) -> void:
	if when > String(_work.scenario_datetime):
		_work.scenario_datetime = when
		_work.explicit_time_receipts["ledger:" + when] = when
		_tara_lifecycle(when)
		for index in _work.plants.size():
			var plant: Dictionary = _work.plants[index]
			if plant.alive:
				var advanced := _plants.advance_to(plant, when)
				if advanced.accepted:
					_work.plants[index] = advanced.plant
	_home_to(when)
	_trip_clock(when)

func _trip_clock(when: String) -> void:
	if _work.route.get("trip_id") != "p15" or _work.route.get("departure", "").is_empty():
		return
	var profile := _profile("p15")
	var elapsed := minf(float(profile.journey_hours), maxf(0, (_seconds(when) - _seconds(_work.route.departure)) / 3600.0))
	_work.route.elapsed_hours = elapsed
	_work.route["provisions_remaining"] = float(_work.route.provisions) - elapsed
	if elapsed > float(_work.route.provisions):
		_error = "The dated journey exceeds its independent rover provisions."
	if when >= String(profile.return_home) and not _work.route.get("return_cost_paid", false):
		_work.route.energy -= _work.route.allowance
		_work.route["return_cost_paid"] = true
		_work.route["return"] = profile.return_home
		if float(_work.route.energy) < float(_work.route.return_reserve):
			_error = "The rover return would breach its mandatory reserve."

func _home_to(when: String) -> void:
	if _work.route.get("trip_id") != "p15" or _work.route.get("departure", "").is_empty():
		return
	var profile := _profile("p15")
	var elapsed := clampf((_seconds(when) - _seconds(profile.night_start)) / 3600.0, 0, profile.home_hours)
	var previous := float(_work.route.home_elapsed_hours)
	if elapsed <= previous:
		return
	# Split the interval at the actual return: two home occupants for 33 h,
	# five for the last 3 h. No rover air/food is charged to home.
	for group in [0, 1]:
		var start := previous if group == 0 else maxf(previous, profile.home_two_crew_hours)
		var finish := minf(elapsed, profile.home_two_crew_hours) if group == 0 else elapsed
		if finish <= start:
			continue
		var settings := profile.duplicate(true)
		settings["fraction"] = (finish - start) / float(profile.shift_hours)
		settings["breathing_air"] = profile.breathing_air if group == 0 else profile.returned_breathing_air
		settings["food_consumption"] = profile.food_consumption if group == 0 else profile.returned_food_consumption
		_sample("P-15", settings)
		if not _error.is_empty():
			return
	_work.route.home_elapsed_hours = elapsed

func _run(action: String, payload: Dictionary, puzzle: Dictionary) -> void:
	var bio: Dictionary = Rules.data.biology
	match action:
		"p05_read_main_t0", "p05_read_main_t10", "p05_read_garden_t0", "p05_read_garden_t10", "p05_read_return_t0", "p05_read_return_t10":
			puzzle[action] = payload.reading
			_summary.append("Independent pressure gauge: %s = %s relative test units." % [action.trim_prefix("p05_read_").replace("_", " ").to_upper(), float(payload.reading)])
		"p05_inspect_tank", "p05_inspect_habitat", "p05_inspect_garden", "p05_inspect_return", "p05_inspect_airlock", "p05_inspect_annex":
			var candidates: Array = puzzle.get("candidates", [])
			if not candidates.has(action):
				candidates.append(action)
			puzzle["candidates"] = candidates
			if candidates.size() % int(_profile("p05").max_inspections_per_phase) == 0:
				var settings := _profile("p05")
				settings["day_warm"] = true
				settings["extra_air"] = settings.unresolved_leak_air * (Rules.data.upgrade.flexible_seal_factor if _economy.campaign_modifiers(_work).flexible_seals else 1.0)
				_sample("P-05", settings)
		"p05_verify_annex_isolation": puzzle["annex_isolated"] = true
		"p05_isolate_garden": puzzle["garden_isolated"] = true
		"p05_verify_main_hold":
			_require(puzzle.get("garden_isolated", false) and puzzle.get("p05_read_main_t10") == 100, "Isolate GARDEN and independently verify the MAIN pressure hold.")
			puzzle["main_hold"] = true
		"p05_apply_garden_clamp":
			_require(puzzle.get("garden_isolated", false) and puzzle.get("main_hold", false), "The clamp needs an isolated garden connection and a verified trunk hold.")
			puzzle["leak_sealed"] = true
		"p05_reopen_garden_slow":
			_require(puzzle.get("leak_sealed", false) and puzzle.get("annex_isolated", false), "Verify the clamp and the aftershock annex isolation before reopening.")
			puzzle["garden_reopened"] = true
		"p05_stable_read_1", "p05_stable_read_2", "p05_stable_read_3", "p05_stable_read_4", "p05_stable_read_5":
			var number := int(action.right(1))
			_require(puzzle.get("garden_reopened", false) and int(puzzle.get("stable_checks", 0)) == number - 1, "Five independent stable readings must follow verified reopening in order.")
			puzzle["stable_checks"] = number
			if number == 5:
				var settings := _profile("p05")
				settings["day_warm"] = true
				_sample("P-05", settings)
		"p06_confirm_maturity": _care("ALO-01", "maturity_check")
		"p06_configure_drydown":
			_care("ALO-01", "dry_down")
			puzzle["moisture"] = bio.moisture_wet
		"p06_drydown_five_days":
			_require(_plant("ALO-01").get("stage") == "mature_dry", "The dated five-day dry-down has not completed.")
			puzzle["moisture"] = bio.moisture_dry
		"p06_open_six_pods":
			var index := _plant_index("ALO-01")
			var harvest := _plants.harvest(_plant("ALO-01"), _work.scenario_datetime)
			_require(harvest.accepted and puzzle.get("moisture", bio.moisture_wet) <= bio.moisture_dry, "Maturity and dry pods are required before harvesting.")
			if harvest.accepted and index >= 0:
				_work.plants[index] = harvest.plant
				_work.inventories.founder_seed42 = {"total": harvest.seed_count, "allocated": 0, "reserve": 0, "unallocated": harvest.seed_count, "reserve_compartments": []}
		"p06_count_42": _require(_work.inventories.founder_seed42.total == bio.founder_total, "Count the actual harvested seed lot before allocating it.")
		"p06_allocate_12_30":
			_require(_work.inventories.founder_seed42.total == bio.founder_total, "The founder allocation needs the actual mature harvest.")
			_work.inventories.founder_seed42 = {"total": bio.founder_total, "allocated": bio.founder_planting, "reserve": bio.founder_reserve, "unallocated": 0, "reserve_compartments": bio.reserve_compartments.duplicate()}
			_work.inventories.allocated12 = bio.founder_planting
			_work.inventories.reserve30 = bio.founder_reserve
		"p06_sleeve_petal": puzzle["petal_archived"] = not _plant("ALO-01").get("alive", true)
		"p06_plant_12_positions":
			_require(_work.inventories.allocated12 == bio.founder_planting, "Only the allocated founder seeds can fill the twelve positions.")
			for index in int(bio.founder_planting):
				var id := "DESC-FOUNDER-%02d" % (index + 1)
				if _plant(id).is_empty():
					_work.plants.append(_plants.new_plant(id, Plants.ALO_TARA_LINEAGE, "seed", _work.scenario_datetime, {"parents": [Plants.ALO_ID, Plants.TARA_ID], "founder_allocation": true}))
		"p06_seal_reserve_30":
			_require(_work.inventories.reserve30 == bio.founder_reserve, "Keep all thirty founder seeds in the separate reserve.")
			_work.inventories.founder_seed42["sealed"] = true
		"p06_confirm_descendant_survey": _continuity_descendants()
		"p07_inspect_twelve_descendants":
			_require(_living_descendants().size() == int(bio.descendant_sample), "The October comparison requires twelve current descendants, separately from the founder reserve.")
		"p07_prepare_departure":
			_require(float(_work.route.energy) - 2 * float(_work.route.allowance) >= float(_work.route.return_reserve), "The surveyed round trip must retain its return reserve.")
			_work.route.energy -= _work.route.allowance
			_work.route.departure = _work.scenario_datetime
			var settings := _profile("p07")
			settings["day_warm"] = true
			_sample("P-07", settings)
		"p07_commit_return_route":
			var settings := _profile("p07")
			settings["day_warm"] = true
			_sample("P-07", settings)
		"p08_return_to_base":
			_require(_work.route.get("trip_id") == "p07", "Return the surveyed rover with its own independent provision manifest.")
			if not _error.is_empty():
				return
			_work.route.energy -= _work.route.allowance
			_work.route["return"] = _work.scenario_datetime
			_work.route.elapsed_hours = (_seconds(_work.scenario_datetime) - _seconds(_work.route.departure)) / 3600.0
			_require(_work.route.energy >= _work.route.return_reserve and _work.route.elapsed_hours <= _work.route.provisions, "The survey return exceeds energy or independent consumable reserves.")
		"p08_warm_cold": puzzle["temperature_stage"] = "cold"
		"p08_warm_cool":
			_require(puzzle.get("temperature_stage") == "cold", "Start sealed warm-up at cold.")
			puzzle.temperature_stage = "cool"
		"p08_warm_room":
			_require(puzzle.get("temperature_stage") == "cool", "Confirm the cool stage before room-temperature handling.")
			puzzle.temperature_stage = "room"
		"p08_check_condensation":
			_require(puzzle.get("temperature_stage") == "room", "Complete sealed warm-up before the condensation check.")
			puzzle["dry_verified"] = true
		"p08_open_inner_seal": _require(puzzle.get("dry_verified", false), "Keep the inner seal closed until dry warm-up passes at home.")
		"p08_inventory_12":
			_require(puzzle.get("dry_verified", false), "The twelve specimen labels are inventoried after sealed dry warm-up.")
			_work.inventories.vault12 = {"total": bio.vault_total, "stored": bio.vault_total, "cotton_planted": 0, "stored_after_cotton": bio.vault_total, "viability": "pending", "distinct_specimen_ids": []}
			for index in int(bio.vault_total):
				_work.inventories.vault12.distinct_specimen_ids.append("VAULT-%02d" % (index + 1))
			_work.inventories.stored12 = bio.vault_total
		"p09_store_spare_once": _work.inventories["relay_controllers"] = Rules.data.relay.controller_count
		"p09_commit_sequence": puzzle["departure_evidence"] = payload.duplicate(true)
		"p10_clean_panel": _puzzle("P-10")["dust_cleared"] = true
		"p10_patch_dome_spur": _puzzle("P-10")["leak_sealed"] = true
		"p10_verify_pressure", "p10_save_report", "p10_send_invitation":
			var state := _puzzle("P-10")
			var modifiers := _economy.campaign_modifiers(_work)
			_require(state.get("dust_cleared", false) or modifiers.dust_shield, "Clean the panel or verify its protective shield before the observation sample.")
			_require(state.get("leak_sealed", false) or modifiers.whipple_bumper, "Patch the micro-leak or verify its bumper before the sample.")
			var settings := _profile("p10")
			_sample("P-10", settings)
		"p10_plant_cotton":
			_require(_work.inventories.vault12.get("stored", 0) == bio.vault_total, "Cotton needs its actual recovered specimen; keep album records separate.")
			var planted := _plants.record_cotton_plant(_work.inventories.vault12, _work.scenario_datetime)
			_require(planted.accepted, planted.reason)
			if planted.accepted:
				_work.inventories.vault12 = planted.ledger
				_work.inventories.cotton_planted = bio.cotton_planted
				_work.inventories.stored11 = bio.vault_stored
				_work.inventories.stored12 = bio.vault_stored
				_work.plants.append(_plants.new_plant(Plants.COTTON_ID, Plants.COTTON_LINEAGE, "seed", _work.scenario_datetime, {"plant_type": "cotton", "cultivar": "Vault cotton reference"}))
		"p10_protect_eleven_vault": _require(_work.inventories.vault12.get("stored", 0) == bio.vault_stored, "One planted cotton specimen leaves eleven stored vault specimens.")
		"p11_commit_allocation":
			var amount: float = _profile("p11").allocation
			_require(float(_work.resources.E) >= amount, "The protected eclipse allocation exceeds the actual jar.")
			_work.resources.E -= amount
			puzzle["allocation_spent"] = amount
		"p12_reset_sequence": puzzle["camera_branch"] = "verified_restored"
		"p12_record_egress": _require(puzzle.get("camera_branch") == "verified_restored", "Restore and independently test F2 before logging egress.")
		"p13_commit_plan":
			var profile := _profile("p13")
			_require(_work.inventories.reserve30 == bio.founder_reserve, "The storm plan needs the actual protected founder reserve.")
			_work.resources.W = payload.water
			_work.resources.K = payload.crate
			puzzle["plan"] = profile.duplicate(true)
		"p13_latch_founder_reserve":
			_require(_work.inventories.founder_seed42.get("sealed", false), "Latch both actual founder-reserve compartments before storm exposure.")
			puzzle["case_latched"] = true
		"p14_commit_steps_1_2": _storm_steps(2)
		"p14_commit_steps_3_6": _storm_steps(4)
		"p14_diagnose_external_branch":
			_require(int(_puzzle("P-14").phase) == int(_profile("p13").phases), "Complete all six storm samples before the external-path diagnosis.")
			puzzle["local_network"] = "PASS"
			puzzle["direct_earth_path"] = "FAIL"
			puzzle["external_feedthrough"] = "F-EXT"
		"p14_route_reading_1":
			puzzle["clearance_readings"] = [{"when": _work.scenario_datetime, "reading": payload.reading}]
		"p14_route_reading_2":
			var readings: Array = puzzle.get("clearance_readings", [])
			_require(readings.size() == 1, "Keep the first safe reading and wait ten scenario minutes.")
			_date(_plus_seconds(_work.scenario_datetime, Rules.data.relay.reading_interval_seconds))
			readings.append({"when": _work.scenario_datetime, "reading": payload.reading})
			puzzle["clearance_readings"] = readings
		"p14_pack_controller": _require(_work.inventories.get("relay_controllers", 0) == Rules.data.relay.controller_count, "Pack the actual compatible controller delivered by relief.")
		"p14_pack_battery": _work.inventories["repeater_spare_batteries"] = Rules.data.relay.repeater_spares
		"p15_confirm_loadout": _require(_work.inventories.get("relay_controllers", 0) == Rules.data.relay.controller_count and _work.inventories.get("repeater_spare_batteries", 0) == Rules.data.relay.repeater_spares, "The rover loadout needs the delivered controller and its packed repeater battery spare.")
		"p15_set_brake": _work.route["brake_set"] = true
		"p15_confirm_roundtrip_provisions":
			_require(_work.route.provisions >= _profile("p15").journey_hours, "Carry independent provisions for the complete fifty-one-hour trip.")
		"p15_choose_surveyed_route":
			_require(_work.route.energy - 2 * _work.route.allowance >= _work.route.return_reserve, "The surveyed round-trip forecast must retain two units of reserve.")
			_require(float(_work.route.energy) - 2.0 * float(_work.route.allowance) >= float(payload.get("reserve", _work.route.return_reserve)), "The declared return reserve exceeds the actual surveyed-route forecast.")
			_work.route.departure = _profile("p15").departure
			_work.route.energy -= _work.route.allowance
			_work.route["surface_route"] = "SURVEYED"
			_trip_clock(_work.scenario_datetime)
		"p15_restore_marker_2":
			_require(_work.route.get("brake_set", false) and _work.inventories.get("repeater_spare_batteries", 0) == Rules.data.relay.repeater_spares, "Set the brake and use the actual packed spare before reconnecting marker two.")
			_work.inventories["repeater_spare_batteries"] = 0
			_work.route["marker_two_battery"] = "SPARE_INSTALLED"
		"p15_test_repeater_chain":
			_require(_work.route.get("marker_two_battery") == "SPARE_INSTALLED", "Replace marker two's failed battery before testing the three-repeaters/four-hop path.")
			_work.route.local_hops = ["Aurora-R1", "R1-R2", "R2-R3", "R3-summit"]
		"p15_confirm_segment_forecast":
			var projection: Dictionary = get_script().new().project_scene(_work, "EX-CH08-S12")
			_require(projection.accepted, "The home plan cannot preserve the required reserves through the 33+3-hour night.")
			if projection.accepted:
				_work.route["home_forecast"] = projection.snapshot.resources.duplicate(true)
				var home: Dictionary = _work.route.home_forecast
				_summary.append("Home-night forecast: E %s; A %s; H %s; C %s; R %s crew-days. Confirming this forecast does not spend those reserves now." % [home.E, home.A, home.H, home.C, home.R])
		"p15_confirm_home_pressure": _work["garden_pressure_stable"] = true
		"p16_isolate_power": puzzle["isolated"] = true
		"p16_zero_test":
			_require(puzzle.get("isolated", false), "Isolate relay power before the zero-current check.")
			puzzle["zero_verified"] = true
		"p16_install_controller":
			_require(puzzle.get("zero_verified", false) and _work.inventories.get("relay_controllers", 0) == Rules.data.relay.controller_count, "A verified zero and the delivered compatible controller are required.")
			puzzle["controller_installed"] = true
			_work.inventories.relay_controllers = 0
		"p16_close_housing": puzzle["housing_closed"] = puzzle.get("controller_installed", false)
		"p16_restore_power":
			_require(puzzle.get("housing_closed", false), "Close the installed controller housing before restoring power.")
			puzzle["powered"] = true
		"p16_local_bearing", "p16_earth_bearing":
			_require(puzzle.get("powered", false), "Restore the physical relay before testing its two independent bearings.")
			puzzle["local_bearing" if action == "p16_local_bearing" else "earth_bearing"] = payload.bearing
		"p16_stable_lock":
			_require(puzzle.get("local_bearing") == Rules.data.relay.local_bearing and puzzle.get("earth_bearing") == Rules.data.relay.earth_bearing, "Verify the local and Earth bearings separately.")
			puzzle["stable_lock"] = true
		"p16_checksum":
			_require(puzzle.get("stable_lock", false), "The known-content echo needs both stable paths.")
			puzzle["known_content_echo"] = payload.value
		"p16_confirm_path_records":
			_require(puzzle.get("known_content_echo") == Rules.data.relay.known_echo and _work.route.get("local_hops", []).size() == 4, "Save both verified paths and the exact current known-content echo.")
			puzzle["local_verified"] = true
			puzzle["earth_verified"] = true
			_work.route.earth_leg = "verified"
		"p16_noor_live_voice":
			_require(puzzle.get("local_verified", false) and puzzle.get("earth_verified", false), "The first live Earth voice requires both verified paths.")
			puzzle["voice_checks"] = ["Aurora", "Earth"]
		"p16_confirm_five_at_aurora":
			_require(_work.route.get("return", "") == _profile("p15").return_home, "Confirm the dated twenty-four-hour return before the five-person roll call.")
			_work.route["crew_home"] = 5
		"p16_save_final_records":
			_require(_work.inventories.reserve30 == bio.founder_reserve and _work.inventories.vault12.get("stored") == bio.vault_stored and _plant(Plants.COTTON_ID).get("alive", false) and _work.route.get("crew_home", 0) == 5 and _work.get("garden_pressure_stable", false) and _work.resources.H > 0 and _work.resources.C > 0, "The final record needs the five actual crew, living pressurised garden, cotton, founder thirty and eleven stored vault specimens.")
			puzzle["final_indicators"] = {"crew": 5, "founder_reserve": bio.founder_reserve, "vault_stored": bio.vault_stored, "cotton_alive": true, "garden_stable": true}

func _storm_steps(count: int) -> void:
	var p13 := _puzzle("P-13")
	_require(p13.get("case_latched", false) and p13.has("plan"), "Latch the actual reserve case and commit the integrated six-step plan first.")
	if not _error.is_empty():
		return
	var profile: Dictionary = p13.plan
	for index in count:
		var phase := int(_puzzle("P-14").phase)
		if phase >= int(profile.phases):
			_error = "The storm cannot run beyond its six samples."
			return
		var settings := profile.duplicate(true)
		settings["exposure_multiplier"] = profile.multipliers[phase]
		settings["water_after_exposure"] = profile.drain_to if phase == int(profile.phases) - 1 else _work.resources.W
		_sample("P-14", settings)
		_date(_plus_seconds(String(profile.storm_start), int(profile.shift_hours * 3600) * (phase + 1)))

func _continuity_descendants() -> void:
	var bio: Dictionary = Rules.data.biology
	_require(_work.inventories.reserve30 == bio.founder_reserve and _plant("ALO-01").get("harvested", false), "Continuity must start from the harvested founder lot and its protected reserve.")
	var previous_cohort := _living_descendants()
	var interval_start := String(previous_cohort[0].planted_at) if not previous_cohort.is_empty() else String(bio.harvest_date)
	var october_sample := String(_work.scenario_datetime).begins_with("2046-10-21")
	for plant in _work.plants:
		if plant.plant_type == "mustard":
			plant.alive = false
			plant.natural_death = true
			# Harvested individuals keep their archive (Alo's petal, Tara's nameplate);
			# only unharvested annuals are closed as naturally dead here.
			if not bool(plant.get("harvested", false)) and not _plants.is_terminal_stage(String(plant.get("stage", ""))):
				plant.stage = "naturally_dead"
				plant.death_reason = "completed_annual_life"
	for index in int(bio.descendant_sample):
		var id := "DESC-CURRENT-%s-%02d" % [_work.scenario_datetime.substr(0, 10), index + 1]
		if _plant(id).is_empty():
			_work.plants.append(_plants.new_plant(id, Plants.ALO_TARA_LINEAGE, "young", _work.scenario_datetime, {"record_start_is_observation": true, "planting_date_unknown": true, "generation": "later replacement cohort; exact count not asserted", "founder_ancestors": [Plants.ALO_ID, Plants.TARA_ID], "stem_colour": ("purple" if index < int(bio.purple) else "green") if october_sample else "not_resampled"}))
	_book.entries.append({"kind": "dated_replacement_generations", "from": interval_start, "observed_at": _work.scenario_datetime, "founder_reserve": bio.founder_reserve, "later_harvest_totals": "not fixed by the story", "current_descendants": bio.descendant_sample, "purple": bio.purple if october_sample else "not_resampled", "green": bio.green if october_sample else "not_resampled", "basis": "STORY_FULL EX-CH03-S12 / EX-CH04-S01; observation baseline is not an invented planting date"})

## Tara's dated end (doc 24 §3.9 and §7.6, approved 5 Nov 2026). These are authored
## story events, not player puzzle operations: when the ledger clock passes 26 May
## 2046 her mature pods are confirmed and her watering stops that day; when it passes
## 31 May her dry pods are harvested into the separate working stock (Tara x Alo, no
## headline count) and she is archived as `archived_nameplate`. Each step is dated
## on its canonical day even when the clock jumps past both at once, so a save from
## any earlier date reaches the same record. Tara that was never pollinated sets no
## seed, is never harvested and completes her annual life as before. The founder
## ledger (42 = 12 + 30) and the vault ledgers are never read or written here.
func _tara_lifecycle(when: String) -> void:
	var index := _plant_index(Plants.TARA_ID)
	if index < 0:
		return
	var tara: Dictionary = _work.plants[index]
	if not bool(tara.get("alive", false)) or bool(tara.get("harvested", false)):
		return
	var schedule: Dictionary = _plants.tara_schedule()
	var maturity_date := String(schedule.maturity_date)
	var harvest_date := String(schedule.harvest_date)
	if when >= maturity_date and String(tara.get("maturity_confirmed_at", "")).is_empty():
		var matured := _plants.advance_to(tara, maturity_date)
		if matured.accepted and String(matured.plant.get("stage", "")) == "mature_pods":
			var confirmed := _plants.apply_care(matured.plant, "maturity_check", maturity_date)
			var dried := _plants.apply_care(confirmed.plant, "dry_down", maturity_date) if confirmed.accepted else confirmed
			if dried.accepted:
				_work.plants[index] = dried.plant
				tara = dried.plant
				_book.entries.append({"kind": "tara_watering_stopped", "individual_id": Plants.TARA_ID, "when": maturity_date, "stage": "mature_pods", "basis": "STORY_FULL EX-CH03-S12 (approved 5 Nov 2026): mature pods in the cooler indoor reference bay 20 days after the last pollination run; five-day dry-down like Alo's"})
	if when >= harvest_date and not String(tara.get("dry_down_started_at", "")).is_empty() and not bool(tara.get("harvested", false)):
		var harvest := _plants.harvest(tara, harvest_date)
		if harvest.accepted and String(harvest.get("ledger_target", "")) == Plants.LEDGER_WORKING_STOCK:
			_work.plants[index] = harvest.plant
			_work.inventories[Plants.LEDGER_WORKING_STOCK] = (harvest.working_stock as Dictionary).duplicate(true)
			_book.entries.append({"kind": "tara_working_stock", "individual_id": Plants.TARA_ID, "when": harvest_date, "stage": String(harvest.plant.get("stage", "")), "ledger": Plants.LEDGER_WORKING_STOCK, "lineage": String(harvest.working_stock.get("cross", "")), "headline_count": String(harvest.working_stock.get("headline_count", "")), "founder_ledger_touched": false, "basis": "STORY_FULL EX-CH03-S12 (approved 5 Nov 2026): Tara's seeds are the working stock the garden uses, so Alo's thirty stay sealed; her nameplate goes to the lineage board"})

## One summary line for the P-06 ledger once Tara's record exists; empty before 26 May.
func _tara_summary() -> String:
	var tara := _plant(Plants.TARA_ID)
	if tara.is_empty():
		return ""
	var stock: Dictionary = _work.inventories.get(Plants.LEDGER_WORKING_STOCK, {})
	if bool(tara.get("harvested", false)) and not stock.is_empty():
		return "Tara: archived nameplate on the lineage board. Working stock %s sealed %s; no headline count. Founder reserve untouched." % [String(stock.get("cross", "Tara x Alo")), String(stock.get("harvested_at", "")).substr(0, 10)]
	if not String(tara.get("dry_down_started_at", "")).is_empty():
		return "Tara: %s; watering stopped %s for her five-day dry-down." % [String(tara.get("stage", "")).replace("_", " "), String(tara.get("dry_down_started_at", "")).substr(0, 10)]
	return ""

func _refresh_replacement_cohort() -> void:
	var current := _living_descendants()
	if current.is_empty():
		return
	var baseline := String(current[0].planted_at)
	if (_seconds(_work.scenario_datetime) - _seconds(baseline)) / 86400.0 > float(Rules.data.biology.annual_completion_days):
		_continuity_descendants()

func _plant(id: String) -> Dictionary:
	var index := _plant_index(id)
	return _work.plants[index] if index >= 0 else {}

func _plant_index(id: String) -> int:
	for index in _work.plants.size():
		if _work.plants[index].individual_id == id:
			return index
	return -1

func _care(id: String, kind: String) -> void:
	var index := _plant_index(id)
	if index < 0:
		_error = "Plant individual is missing from the authoritative state."
		return
	var care := _plants.apply_care(_plant(id), kind, _work.scenario_datetime)
	_require(care.accepted, care.reason)
	if care.accepted:
		_work.plants[index] = care.plant

func _living_descendants() -> Array:
	return _work.plants.filter(func(plant): return String(plant.individual_id).begins_with("DESC-CURRENT") and plant.alive)

func _require(condition: bool, reason: String) -> void:
	if not condition and _error.is_empty():
		_error = reason

static func _seconds(when: String) -> float:
	return float(Time.get_unix_time_from_datetime_string(when.trim_suffix(" UTC").replace(" ", "T") + ":00"))

static func _plus_seconds(when: String, seconds: int) -> String:
	return Time.get_datetime_string_from_unix_time(int(_seconds(when)) + seconds, true).substr(0, 16) + " UTC"

static func mini_string(left: String, right: String) -> String:
	return left if left < right else right

static func maxi_string(left: String, right: String) -> String:
	return left if left > right else right

func chapter2_biology(snapshot: Dictionary, command: Dictionary) -> Dictionary:
	_begin(snapshot)
	var action := String(command.get("payload", {}).get("_puzzle_action", ""))
	var run := 0
	if action.contains("run_2"):
		run = 1
	elif action.contains("run_3"):
		run = 2
	var transfers := {"p03_transfer_to_alo": Plants.ALO_ID, "p03_transfer_to_tara": Plants.TARA_ID, "p03_run_2_forward": Plants.ALO_ID, "p03_run_2_reverse": Plants.TARA_ID, "p03_run_3_forward": Plants.ALO_ID, "p03_run_3_reverse": Plants.TARA_ID}
	if transfers.has(action):
		_date(String(Economy.load_profile("p03_pollination").sampled.dates[run]))
		_care(transfers[action], "pollinate")
	if action == "p03_complete_run_1" or action.begins_with("p03_log_care_day_"):
		var when := String(Clock.data.operations[action])
		_date(when)
		_care(Plants.ALO_ID, "observe")
		_care(Plants.TARA_ID, "observe")
	if action.begins_with("p03_complete_run_"):
		_book.food_sampled = float(_book.food_sampled) + float(Economy.load_profile("p03_pollination").sampled.food_consumption)
	elif action == "p03_record_prediction":
		var profile := Economy.load_profile("p03_pollination")
		_book.food_sampled = float(_book.food_sampled) + float(profile.background.total_consumption) - float(profile.sampled.food_consumption) * profile.sampled.dates.size()
	return _result(snapshot)

func state_predicates(scene_id: String, snapshot: Dictionary) -> Array:
	var missing: Array = []
	var book: Dictionary = snapshot.get("campaign_ledgers", {})
	var puzzles: Dictionary = book.get("puzzles", {})
	var resources: Dictionary = snapshot.resources
	match scene_id:
		"EX-CH03-S02":
			if puzzles.get("P-05", {}).get("candidates", []).size() != 6: missing.append("six independently inspected candidates")
		"EX-CH03-S04", "EX-CH03-S05":
			var leak: Dictionary = puzzles.get("P-05", {})
			if int(leak.get("phase", 0)) != 4 or int(leak.get("stable_checks", 0)) != 5 or not leak.get("leak_sealed", false): missing.append("four budget phases and five stable repair readings")
		"EX-CH03-S09":
			if snapshot.plants.filter(func(plant): return plant.individual_id == Plants.ALO_ID and plant.stage == "mature_pods" and not plant.dry_down_started_at.is_empty()).is_empty(): missing.append("dated mature pods and controlled irrigation stop")
		"EX-CH03-S10":
			if snapshot.inventories.founder_seed42.get("total", 0) != Rules.data.biology.founder_total or snapshot.plants.filter(func(plant): return plant.individual_id == Plants.ALO_ID and plant.harvested and not plant.alive).is_empty(): missing.append("actual dry founder harvest and archived original")
		"EX-CH03-S11":
			if snapshot.inventories.get("reserve30", 0) != Rules.data.biology.founder_reserve or not snapshot.inventories.founder_seed42.get("sealed", false): missing.append("sealed founder reserve and planted allocation")
		"EX-CH04-S08":
			if snapshot.inventories.vault12.get("distinct_specimen_ids", []).size() != Rules.data.biology.vault_total: missing.append("twelve distinct recovered vault specimens")
		"EX-CH05-S11":
			if puzzles.get("P-10", {}).get("phase", 0) != 3: missing.append("three maintained observation samples")
		"EX-CH05-S12":
			if snapshot.inventories.get("cotton_planted", 0) != 1 or snapshot.inventories.vault12.get("stored", 0) != 11: missing.append("dated cotton planting and eleven stored specimens")
		"EX-CH06-S11":
			if puzzles.get("P-11", {}).get("allocation_spent", 0) != _profile("p11").allocation or puzzles.get("P-12", {}).get("camera_branch") != "verified_restored": missing.append("protected allocation and verified camera recovery")
		"EX-CH07-S08", "EX-CH07-S09":
			if puzzles.get("P-14", {}).get("phase", 0) != 6 or resources.A <= 0 or resources.H <= 0 or resources.C <= 0 or resources.Z > _profile("p13").exposure_limit: missing.append("six safe storm samples with living garden")
			if scene_id.ends_with("S09") and puzzles.get("P-14", {}).get("clearance_readings", []).size() != 2: missing.append("two separated safe route readings")
		"EX-CH08-S09":
			if not puzzles.get("P-16", {}).get("local_verified", false) or not puzzles.get("P-16", {}).get("earth_verified", false): missing.append("independently verified local and Earth paths")
		"EX-CH08-S11":
			if snapshot.route.get("crew_home", 0) != 5 or snapshot.route.get("elapsed_hours", 0) != _profile("p15").journey_hours: missing.append("dated round-trip return and five crew home")
		"EX-CH08-S12":
			if puzzles.get("P-16", {}).get("final_indicators", {}).size() != 5 or not is_equal_approx(float(snapshot.route.get("home_elapsed_hours", 0)), float(_profile("p15").home_hours)): missing.append("final living-garden, crew, inventory and home-night indicators")
	return missing
