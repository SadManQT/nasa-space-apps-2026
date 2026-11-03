## Godot --headless --path game --script res://tools/test_worker_a_systems.gd
extends SceneTree

const SimulationScript = preload("res://scripts/simulation/expedition_simulation.gd")
const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const SaveScript = preload("res://scripts/save/save_service.gd")
const PlantScript = preload("res://scripts/biology/plant_service.gd")
const HostScript = preload("res://scripts/puzzles/puzzle_host.gd")
const StateScript = preload("res://scripts/core/campaign_state.gd")

var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_bugfix_contracts()
	_test_simulation_witnesses()
	_test_simulation_boundaries()
	_test_upgrade_combinations()
	_test_director_and_host()
	_test_save_service()
	_test_plants()
	print("WORKER A SYSTEMS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_simulation_witnesses() -> void:
	var sim = SimulationScript.new()
	var witnesses := {
		"Bloom": _bloom_plan(),
		"Golden": _golden_plan(),
		"PUMP": _pump_plan(),
		"STACK": _stack_plan(),
	}
	var expected := {
		"Bloom": [2, 1, 1, 0, 0, 3, 3.6, 2],
		"Golden": [0, 1, 5, 0, 0, 9, 3.6, 2],
		"PUMP": [0, 1, 1, 6, 0, 7, 3.6, 2],
		"STACK": [0, 3, 1, 0, 0, 6, 3.6, 2],
	}
	for name in witnesses.keys():
		var profile: Dictionary = sim.entry_profile()
		profile["state_revision"] = 0
		var before := profile.duplicate(true)
		var result: Dictionary = sim.preview(profile, {"shifts": witnesses[name]})
		_check(bool(result.get("accepted", false)), name + " preview accepts the published witness")
		_check(profile == before, name + " preview is pure")
		var actual := _resource_vector(result.get("final_state", {}))
		_check(_vector_near(actual, expected[name]), name + " final E/A/H/W/K/C/R/Z matches the numeric appendix")
		var committed: Dictionary = sim.commit(profile, "worker-a-" + name, 0, {"shifts": witnesses[name]})
		_check(bool(committed.get("accepted", false)), name + " pure commit accepts once")
		_check(int(committed.get("output_revision", -1)) == 1, name + " commit advances the returned revision")
		_check(_resource_vector(committed.get("snapshot", {}).get("resources", {})) == actual, name + " commit returns the preview state")
		var simulation_duplicate: Dictionary = sim.commit(committed.get("snapshot", {}), "worker-a-" + name, 1, {"shifts": witnesses[name]})
		_check(bool(simulation_duplicate.get("duplicate", false)), name + " direct simulation commit is idempotent from its returned snapshot")
		_check(String(simulation_duplicate.get("receipt_id", "")) == String(committed.get("receipt_id", "")) and simulation_duplicate.get("reason", "") == committed.get("reason", "") and simulation_duplicate.get("deltas", []) == committed.get("deltas", []), name + " direct simulation duplicate returns the original receipt/result")
		_check(simulation_duplicate.get("snapshot", {}).get("state_revision", -1) == 1, name + " direct duplicate reconstructs a current snapshot without nested receipts")
	var bloom: Dictionary = sim.preview(sim.entry_profile(), {"shifts": _bloom_plan()})
	var trace: Array = bloom.get("trace", [])
	var expected_trace := [[15, 7, 7, 0, 0, 9], [17, 6, 8, 0, 0, 10], [14, 5, 7, 2, 0, 9], [11, 4, 5, 4, 0, 7], [8, 3, 3, 4, 0, 5], [5, 2, 2, 2, 0, 4], [2, 1, 1, 0, 0, 3]]
	var trace_ok := true
	for i in range(mini(trace.size(), expected_trace.size())):
		var row: Dictionary = trace[i]
		var values: Array = [row.after.E, row.after.A, row.after.H, row.after.W, row.after.K, row.after.C]
		if values != expected_trace[i]:
			trace_ok = false
	_check(trace_ok and trace.size() == 7, "Bloom shift trace preserves exposure-before-drain and all intermediate values")
	_check(int(trace[0].overflow) == 2 and int(trace[1].overflow) == 3, "daylight income overflow is recorded before spending")

func _test_simulation_boundaries() -> void:
	var sim = SimulationScript.new()
	var profile: Dictionary
	var result: Dictionary
	profile = sim.entry_profile(); profile.resources.E = 18
	result = sim.preview(profile, {"shifts": [_step("DAY", 0, "OFF", "HOLD")]})
	_check(result.trace[0].overflow == 6 and result.final_state.E == 19, "energy income clamps before spending")
	profile = sim.entry_profile(); profile.resources.A = 10
	result = sim.preview(profile, {"shifts": [_step("DAY", 2, "OFF", "HOLD")]})
	_check(result.final_state.A == 9, "air production clamps before breathing")
	profile = sim.entry_profile(); profile.current_shift = 5; profile.resources.W = 4
	result = sim.preview(profile, {"shifts": [_step("COZY", 0, "OFF", "DRAIN")]})
	_check(result.trace[0].shelter == 4 and result.trace[0].dose == 1 and result.final_state.W == 2, "shift-six exposure is scored before ordinary drain")
	profile = sim.entry_profile(); profile.current_shift = 4; profile.resources.W = 2
	result = sim.preview(profile, {"shifts": [_step("COZY", 0, "OFF", "PUMP")]})
	_check(result.trace[0].shelter == 4 and result.trace[0].dose == 1 and result.final_state.W == 4, "shift-five exposure uses post-alarm shelter")
	profile = sim.entry_profile(); profile.current_shift = 2; profile.resources.H = 6; profile.resources.W = 2
	result = sim.preview(profile, {"shifts": [_step("COZY", 0, "OFF", "FILL")]})
	_check(result.final_state.H == 4, "thirst is evaluated using post-transfer water")
	profile = sim.entry_profile(); profile.current_shift = 2; profile.resources.E = 3
	result = sim.preview(profile, {"shifts": [_step("COZY", 0, "OFF", "HOLD")]})
	_check(result.final_state.E == 0 and result.trace[0].blackout == false, "exactly zero energy is not a blackout")
	profile = sim.entry_profile(); profile.current_shift = 2; profile.resources.E = 2
	result = sim.preview(profile, {"shifts": [_step("COZY", 0, "OFF", "HOLD")]})
	_check(result.final_state.E == 0 and result.trace[0].blackout and result.final_state.A == 3 and result.final_state.H == 3 and result.final_state.C == 5, "negative energy demand applies blackout penalties")
	profile = sim.entry_profile(); profile.current_shift = 4
	result = sim.preview(profile, {"shifts": [{"heat": "COZY", "air_production": 2, "light": "FULL", "transfer": "STACK", "stack_slots": 4}]})
	_check(result.final_state.E == 12 and result.final_state.A == 5 and result.final_state.H == 4 and result.final_state.K == 2 and result.final_state.Z == 2, "STACK forces COOL/O0/OFF before exposure and spending")
	profile = sim.entry_profile(); profile.current_shift = 4
	result = sim.preview(profile, {"shifts": [{"heat": "COZY", "air_production": 0, "light": "OFF", "transfer": "PUMP", "pump_confirmations": 1}]})
	_check(result.final_state.W == 1, "partial PUMP transfers exactly one water unit")
	profile = sim.entry_profile(); profile.current_shift = 4
	result = sim.preview(profile, {"shifts": [{"heat": "COZY", "air_production": 0, "light": "OFF", "transfer": "STACK", "stack_slots": 1}]})
	_check(result.final_state.K == 1, "partial STACK grants one crate shield")
	profile = sim.entry_profile(); profile.current_shift = 6; profile.resources.K = 2
	result = sim.preview(profile, {"shifts": [_step("COZY", 0, "OFF", "HOLD")]})
	_check(result.final_state.K == 0 and result.trace[0].crates_removed, "crate shielding is removed before shift seven")
	profile = sim.entry_profile(); profile.current_shift = 2; profile.resources.W = 6
	result = sim.preview(profile, {"shifts": [_step("COZY", 0, "OFF", "FILL")]})
	_check(result.final_state.W == 6, "water FILL clamps at six")
	profile = sim.entry_profile(); profile.current_shift = 2; profile.resources.W = 0
	result = sim.preview(profile, {"shifts": [_step("COZY", 0, "OFF", "DRAIN")]})
	_check(result.final_state.W == 0, "water DRAIN clamps at zero")
	profile = sim.entry_profile(); profile.current_shift = 4; profile.resources.W = 6
	result = sim.preview(profile, {"shifts": [_step("COZY", 0, "OFF", "PUMP")]})
	_check(result.final_state.W == 6, "PUMP respects the water cap")
	profile = sim.entry_profile(); profile.current_shift = 2
	result = sim.preview(profile, {"shifts": [_step("COZY", 0, "OFF", "PUMP")]})
	_check(not bool(result.accepted), "PUMP outside shift five is rejected")
	result = sim.preview(profile, {"shifts": [_step("COZY", 0, "OFF", "WAIT")]})
	_check(not bool(result.accepted), "WAIT outside shift five is rejected")
	result = sim.preview(profile, {"shifts": [{"heat": "COZY", "air_production": 3, "light": "OFF", "transfer": "HOLD"}]})
	_check(not bool(result.accepted), "air production three is rejected")
	profile = sim.entry_profile(); profile.current_shift = 4
	result = sim.preview(profile, {"shifts": [{"heat": "COZY", "air_production": 0, "light": "OFF", "transfer": "WAIT", "sheltered": false}]})
	_check(result.ending == "MISSION_STOPPED" and result.final_state.Z == 3, "an unsheltered storm shift stops safely after recording exposure")

func _test_upgrade_combinations() -> void:
	var sim = SimulationScript.new()
	var pass_count := 0
	var modifier_effect_count := 0
	for mask in range(128):
		var choices := {}
		for chapter in range(1, 8):
			choices[str(chapter)] = "A" if (mask & (1 << (chapter - 1))) == 0 else "B"
		var profile: Dictionary = sim.entry_profile()
		profile["state_revision"] = 0
		var result: Dictionary = sim.preview(profile, {"shifts": _bloom_plan(), "upgrades": {"choices": choices}})
		if bool(result.get("accepted", false)) and result.get("final_state", {}).has("E"):
			pass_count += 1
		# Bloom is deliberately a COZY witness, so exercise every mask against a
		# controlled COOL shift as well. Chapter 2-B must remove exactly the Alo
		# cold point while leaving the other resources unchanged.
		var cool_profile: Dictionary = sim.entry_profile()
		cool_profile["current_shift"] = 2
		var cool_result: Dictionary = sim.preview(cool_profile, {"shifts": [_step("COOL", 0, "DIM", "HOLD")], "upgrades": {"choices": choices}})
		var expected_health := 6 if (mask & (1 << 1)) != 0 else 5
		if bool(cool_result.get("accepted", false)) and int(cool_result.get("final_state", {}).get("H", -1)) == expected_health and int(cool_result.get("final_state", {}).get("C", -1)) == 8:
			modifier_effect_count += 1
	_check(pass_count == 128 and modifier_effect_count == 128, "all 128 upgrade combinations execute deterministically and prove Chapter 2 insulation changes COOL plant damage")
	_check(_resource_vector(sim.preview(sim.entry_profile(), {"shifts": _bloom_plan(), "upgrades": {"choices": {"1": "B"}}}).final_state).size() == 8, "fuel-cell upgrade retains the P-02 resource schema")
	var first_upgrades := {"choices": {"1": "A", "2": "B"}}
	var first_commit: Dictionary = sim.commit(sim.entry_profile(), "upgrade-order-1", 0, {"shifts": [_step("DAY", 0, "OFF", "HOLD")], "upgrades": first_upgrades})
	var second_upgrades := {"choices": {"2": "A", "3": "A"}}
	var second_commit: Dictionary = sim.commit(first_commit.get("snapshot", {}), "upgrade-order-2", 1, {"shifts": [_step("DAY", 0, "OFF", "HOLD")], "upgrades": second_upgrades})
	var merged_upgrades: Dictionary = second_commit.get("snapshot", {}).get("upgrades", {})
	_check(bool(first_commit.get("accepted", false)) and bool(second_commit.get("accepted", false)) and merged_upgrades.get("choices", {}).get("1", "") == "A" and merged_upgrades.get("choices", {}).get("2", "") == "B" and merged_upgrades.get("choices", {}).get("3", "") == "A" and merged_upgrades.get("acquisition_chapter", {}).keys() == ["1", "2", "3"], "persistent partial upgrade plans merge without overwriting choices or acquisition order")

func _test_director_and_host() -> void:
	var director = DirectorScript.new()
	var initial_campaign: Dictionary = director.new_campaign()
	_check(initial_campaign.get("inventories", {}).get("vault12", {}).get("stored", 0) == 12 and initial_campaign.get("inventories", {}).get("vault12", {}).get("cotton_planted", 1) == 0 and initial_campaign.get("inventories", {}).get("stored12", 0) == 12 and initial_campaign.get("inventories", {}).get("stored11", -1) == 0 and initial_campaign.get("inventories", {}).get("reserve30", 0) == 30, "CampaignState starts with twelve unplanted vault specimens and the separate thirty-seed founder reserve")
	var command := _command("director-shift-1", int(director.query().state_revision), {"shifts": [_bloom_plan()[0]]})
	var before: Dictionary = director.snapshot()
	var preview: Dictionary = director.preview(command)
	_check(bool(preview.get("accepted", false)) and director.snapshot() == before, "CampaignDirector preview is pure")
	_check(preview.has("accepted") and preview.has("duplicate") and preview.has("input_revision") and preview.has("output_revision") and preview.has("receipt_id") and preview.has("deltas") and preview.has("events") and preview.has("warnings") and preview.has("unsafe_predicates") and preview.has("reason") and preview.has("next_phase"), "director result publishes every frozen result field")
	var committed: Dictionary = director.commit(command)
	_check(bool(committed.get("accepted", false)) and director.snapshot().state_revision == 1, "CampaignDirector commits exactly once")
	var duplicate: Dictionary = director.commit(command)
	_check(bool(duplicate.get("duplicate", false)) and director.snapshot().state_revision == 1, "duplicate command returns its receipt without charging twice")
	var stale_command := _command("director-stale", 0, {"shifts": [_bloom_plan()[1]]})
	var stale: Dictionary = director.commit(stale_command)
	_check(not bool(stale.get("accepted", false)) and director.snapshot().state_revision == 1, "stale command is rejected without mutation")
	var paused := director.pause("test pause")
	var paused_attempt := director.commit(_command("paused", 1, {"shifts": [_bloom_plan()[1]]}))
	_check(bool(paused.accepted) and not bool(paused_attempt.accepted) and director.snapshot().current_shift == 1, "pause blocks commits without consuming a shift")
	director.resume()
	var invalid_pause := _command("invalid-pause", 1, {"shifts": [_bloom_plan()[1]]})
	invalid_pause["verb"] = "pause"
	invalid_pause["payload"] = "invalid-payload"
	var invalid_pause_result: Dictionary = director.commit(invalid_pause)
	_check(not bool(invalid_pause_result.get("accepted", false)) and director.snapshot().state_revision == 1, "pause rejects a non-Dictionary payload before reading reason")
	var restored := director.restore_checkpoint()
	_check(bool(restored.accepted) and director.snapshot().state_revision == 0 and director.snapshot().current_shift == 0, "retry restores the complete pre-commit checkpoint")
	var host = HostScript.new()
	host.bind(director, "P-02", "EX-M0102", "EX-CH01-S05")
	var host_preview: Dictionary = host.preview({"shifts": [_bloom_plan()[0]]})
	_check(bool(host_preview.accepted) and host.snapshot().lifecycle == HostScript.PREVIEWED, "PuzzleHost exposes the preview lifecycle")
	var host_pause := host.pause()
	var host_block := host.commit("host-blocked", {"shifts": [_bloom_plan()[0]]})
	_check(bool(host_pause.accepted) and not bool(host_block.accepted), "PuzzleHost pause blocks a commit")
	host.resume()
	var host_commit: Dictionary = host.commit("host-commit", {"shifts": [_bloom_plan()[0]]})
	_check(bool(host_commit.accepted), "PuzzleHost delegates a confirmed command")
	var host_duplicate: Dictionary = host.commit("host-commit", {"shifts": [_bloom_plan()[0]]})
	_check(bool(host_duplicate.duplicate), "PuzzleHost retry/input replay receives the director receipt")
	var host_retry: Dictionary = host.retry()
	_check(bool(host_retry.accepted) and director.snapshot().current_shift == 0, "PuzzleHost retry delegates checkpoint restoration")
	var stale_preview: Dictionary = host.preview({"shifts": [_bloom_plan()[0]]})
	var external_command := _command("external-state-change", int(director.query().get("state_revision", 0)), {"shifts": [_bloom_plan()[0]]})
	var external_commit: Dictionary = director.commit(external_command)
	var stale_host_commit: Dictionary = host.commit("stale-preview", {"shifts": [_bloom_plan()[0]]})
	_check(bool(stale_preview.get("accepted", false)) and bool(external_commit.get("accepted", false)) and not bool(stale_host_commit.get("accepted", false)) and String(stale_host_commit.get("reason", "")).find("stale") >= 0, "PuzzleHost uses the preview revision and rejects a preview made stale by another state change")

func _test_save_service() -> void:
	var save = SaveScript.new()
	var path := OS.get_temp_dir().path_join("worker_a_systems_%d.json" % Time.get_ticks_usec())
	var snapshot: Dictionary = StateScript.new_snapshot()
	var first := save.save(snapshot, path)
	_check(bool(first.accepted), "versioned save writes a validated primitive snapshot")
	snapshot["state_revision"] = 4
	var second := save.save(snapshot, path)
	_check(bool(second.accepted) and second.schema_version == SaveScript.SCHEMA_VERSION, "second save keeps the schema revision and backup")
	var corrupt := FileAccess.open(path, FileAccess.WRITE)
	if corrupt == null:
		_check(false, "save fixture opens its temporary file")
		return
	corrupt.store_string("{not valid json")
	corrupt.close()
	var recovered: Dictionary = save.load(path)
	_check(bool(recovered.accepted) and bool(recovered.recovered) and recovered.snapshot.state_revision == 0, "corrupt primary recovers the last valid backup")
	var corrupt_again := FileAccess.open(path, FileAccess.WRITE)
	if corrupt_again == null:
		_check(false, "save fixture reopens its temporary file")
		return
	corrupt_again.store_string("{corrupt again")
	corrupt_again.close()
	var recovered_again: Dictionary = save.load(path)
	_check(bool(recovered_again.accepted) and bool(recovered_again.recovered) and recovered_again.snapshot.state_revision == 0, "a second corrupt primary recovers from the same valid backup without backup churn")
	var migrated_source := {"schema_version": 1, "save_id": "legacy", "resources": {"energy": 14, "air": 6, "alo_health": 6, "water_shielding": 0, "crate_shielding": 0, "crop_condition": 8, "rations": 12.0, "exposure": 0}}
	var migrated := save.migrate(migrated_source)
	_check(bool(migrated.accepted) and migrated.snapshot.schema_version == SaveScript.SCHEMA_VERSION and migrated.snapshot.resources.E == 14, "schema one snapshots migrate to the current primitive contract")
	_check(save.clear(path), "save test removes primary, temporary and backup files")

func _test_plants() -> void:
	var service = PlantScript.new()
	var alo: Dictionary = service.new_plant("ALO-01", "LINEAGE-ALO-TARA", "seed", "2046-04-11 06:00 UTC")
	var sprout := service.advance_to(alo, "2046-04-12 06:00 UTC")
	_check(bool(sprout.accepted) and sprout.plant.stage == "sprout", "Alo reaches sprout only after a dated transition")
	var bloom := service.advance_to(sprout.plant, "2046-04-27 06:00 UTC")
	_check(bool(bloom.accepted) and bloom.plant.stage == "bloom", "Alo blooms on the canonical 27 April date")
	var pollinated := service.apply_care(bloom.plant, "pollinate", "2046-04-27 06:00 UTC")
	_check(bool(pollinated.accepted) and pollinated.plant.stage == "pollinated", "pollination records the Alo/Tara lineage")
	var repeated_pollination := service.apply_care(pollinated.plant, "pollinate", "2046-04-27 06:00 UTC")
	_check(bool(repeated_pollination.duplicate) and not bool(repeated_pollination.accepted), "repeated care on one date is idempotent")
	var mature := service.advance_to(pollinated.plant, "2046-05-16 06:00 UTC")
	_check(bool(mature.accepted) and mature.plant.stage == "mature_pods", "Alo reaches mature pods on 16 May")
	var backdated_advance := service.advance_to(mature.plant, "2046-05-15 06:00 UTC")
	_check(not bool(backdated_advance.accepted) and backdated_advance.plant == mature.plant, "backdated lifecycle advance is rejected without changing the plant")
	var dry_without_maturity := service.apply_care(mature.plant, "dry_down", "2046-05-16 06:00 UTC")
	_check(not bool(dry_without_maturity.accepted) and dry_without_maturity.plant == mature.plant, "dry-down requires maturity confirmation and is side-effect free when rejected")
	var early := service.harvest(mature.plant, "2046-05-15 06:00 UTC")
	_check(not bool(early.accepted) and early.plant == mature.plant, "premature harvest is rejected without changing the plant")
	var harvest_without_maturity := service.harvest(mature.plant, "2046-05-21 06:00 UTC")
	_check(not bool(harvest_without_maturity.accepted) and harvest_without_maturity.plant == mature.plant, "harvest requires maturity and dry-down and remains side-effect free when rejected")
	var maturity_check := service.apply_care(mature.plant, "maturity_check", "2046-05-16 06:00 UTC")
	var dry := service.apply_care(maturity_check.plant, "dry_down", "2046-05-16 06:00 UTC")
	_check(bool(maturity_check.accepted) and bool(dry.accepted), "maturity confirmation and dry-down are separate dated actions")
	var dry_stage := service.advance_to(dry.plant, "2046-05-21 06:00 UTC")
	_check(bool(dry_stage.accepted) and dry_stage.plant.stage == "mature_dry", "five-day dry-down reaches mature_dry on harvest day")
	var harvested := service.harvest(dry_stage.plant, "2046-05-21 06:00 UTC")
	_check(bool(harvested.accepted) and harvested.seed_count == 42 and harvested.plant.stage == "archived_petal" and not harvested.plant.alive, "Alo harvest records 42 seeds and natural death")
	_check(harvested.ledgers.founder_42.allocated12 == 12 and harvested.ledgers.founder_42.reserve30 == 30 and harvested.ledgers.founder_42.reserve_compartments == [15, 15], "founder ledger reconciles 42 as 12 plus 30")
	var repeated_harvest := service.harvest(harvested.plant, "2046-05-22 06:00 UTC")
	_check(bool(repeated_harvest.duplicate) and not bool(repeated_harvest.accepted), "repeated harvest cannot duplicate seeds")
	var no_revival := service.advance_to(harvested.plant, "2046-06-01 06:00 UTC")
	_check(not bool(no_revival.accepted) and no_revival.plant.stage == "archived_petal", "natural death is terminal and never revived")
	var late_life := service.advance_to(dry_stage.plant, "2046-05-22 06:00 UTC")
	_check(bool(late_life.accepted) and late_life.plant.stage == "naturally_dead" and not late_life.plant.alive, "an unharvested annual plant reaches natural death on a later dated transition")
	var tara := service.new_plant("TARA-01", "LINEAGE-ALO-TARA", "seed", "2046-04-11 06:00 UTC")
	var tara_bloom := service.advance_to(tara, "2046-04-30 06:00 UTC")
	_check(bool(tara_bloom.accepted) and tara_bloom.plant.stage == "bloom", "Tara keeps the canonical 30 April bloom date")
	var invalid_alo := service.new_plant("ALO-01", "LINEAGE-ALO-TARA", "seed", "2046-04-12 06:00 UTC")
	var invalid_tara := service.new_plant("TARA-01", "LINEAGE-ALO-TARA", "seed", "2046-04-12 06:00 UTC")
	var invalid_cotton := service.new_plant("COTTON-01", "LINEAGE-VAULT-COTTON", "seed", "2046-12-14 06:00 UTC", {"plant_type": "cotton"})
	_check(not bool(service.advance_to(invalid_alo, "2046-04-13 06:00 UTC").accepted) and not bool(service.advance_to(invalid_tara, "2046-04-13 06:00 UTC").accepted) and not bool(service.advance_to(invalid_cotton, "2046-12-16 06:00 UTC").accepted), "Alo, Tara and Cotton require their canonical identities and planting dates")
	var cotton := service.new_plant("COTTON-01", "LINEAGE-VAULT-COTTON", "seed", "2046-12-15 06:00 UTC", {"plant_type": "cotton"})
	var cotton_later := service.advance_to(cotton, "2047-01-10 06:00 UTC")
	_check(bool(cotton_later.accepted) and cotton_later.plant.stage == "alive", "cotton uses a dated living reference lifecycle without a forced boll")
	var ledgers: Dictionary = service.canonical_ledgers()
	_check(ledgers.vault_12.total == 12 and ledgers.vault_12.stored == 12 and ledgers.vault_12.cotton_planted == 0 and ledgers.vault_12.stored_after_cotton == 12 and ledgers.founder_42.reserve30 == 30 and ledgers.founder_42.reserve_compartments == [15, 15], "initial vault ledger is twelve unplanted specimens and founder reserve remains separate")
	var vault_result := service.record_cotton_plant(ledgers.vault_12, "2046-12-15 06:00 UTC")
	_check(bool(vault_result.accepted) and vault_result.ledger.cotton_planted == 1 and vault_result.ledger.stored_after_cotton == 11, "cotton ledger records one planted and eleven stored vault specimens")

func _step(heat, oxygen: int, light, transfer: String) -> Dictionary:
	return {"heat": heat, "air_production": oxygen, "light": light, "transfer": transfer}

func _bloom_plan() -> Array:
	return [
		_step("DAY", 2, "FULL", "HOLD"),
		_step("DAY", 0, "FULL", "HOLD"),
		_step("COZY", 0, "OFF", "FILL"),
		_step("COZY", 0, "OFF", "FILL"),
		_step("COZY", 0, "OFF", "WAIT"),
		_step("COZY", 0, "OFF", "DRAIN"),
		_step("COZY", 0, "OFF", "DRAIN"),
	]

func _golden_plan() -> Array:
	return [
		_step("DAY", 2, "FULL", "HOLD"),
		_step("DAY", 0, "FULL", "DRAIN"),
		_step("COOL", 0, "FULL", "DRAIN"),
		_step("COOL", 0, "FULL", "FILL"),
		_step("COOL", 0, "OFF", "STACK"),
		_step("COZY", 0, "OFF", "HOLD"),
		_step("COOL", 0, "FULL", "DRAIN"),
	]

func _pump_plan() -> Array:
	return [
		_step("DAY", 1, "FULL", "DRAIN"),
		_step("DAY", 1, "FULL", "DRAIN"),
		_step("COOL", 0, "OFF", "HOLD"),
		_step("COOL", 0, "OFF", "FILL"),
		_step("COZY", 0, "DIM", "PUMP"),
		_step("COOL", 0, "FULL", "HOLD"),
		_step("COOL", 0, "FULL", "FILL"),
	]

func _stack_plan() -> Array:
	return [
		_step("DAY", 2, "OFF", "FILL"),
		_step("DAY", 2, "DIM", "DRAIN"),
		_step("COOL", 0, "DIM", "DRAIN"),
		_step("COOL", 0, "FULL", "FILL"),
		_step("COOL", 0, "OFF", "STACK"),
		_step("COZY", 0, "OFF", "HOLD"),
		_step("COZY", 0, "DIM", "DRAIN"),
	]

func _resource_vector(resources: Dictionary) -> Array:
	return [resources.get("E", -999), resources.get("A", -999), resources.get("H", -999), resources.get("W", -999), resources.get("K", -999), resources.get("C", -999), resources.get("R", -999), resources.get("Z", -999)]

func _vector_near(actual: Array, expected: Array) -> bool:
	if actual.size() != expected.size():
		return false
	for i in range(actual.size()):
		if actual[i] is float or expected[i] is float:
			if abs(float(actual[i]) - float(expected[i])) > 0.001:
				return false
		elif actual[i] != expected[i]:
			return false
	return true

func _command(command_id: String, revision: int, plan: Dictionary) -> Dictionary:
	return {"command_id": command_id, "issuer": "worker_a_test", "owning_mission_id": "EX-M0102", "owning_scene_id": "EX-CH01-S05", "expected_state_revision": revision, "target_id": "P-02", "verb": "commit_shift", "payload": {"plan": plan}}

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)

func _test_bugfix_contracts() -> void:
	var director := DirectorScript.new()
	var state := director.new_campaign()
	var sim := SimulationScript.new()
	_check(state.resources == sim.entry_profile().resources, "B18 production initialization uses the same external profile as simulation")
	var custom: Dictionary = sim.entry_profile()
	custom.resources.energy_capacity = 32
	custom.resources.E = 30
	custom.resources.health_capacity = 12
	custom.resources.H = 11
	var plan := {"shifts": [_step("DAY", 0, "FULL", "HOLD")]}
	var forecast: Dictionary = sim.preview(custom, plan)
	_check(bool(forecast.accepted) and forecast.final_state.E == 29 and forecast.final_state.energy_capacity == 32 and forecast.final_state.H == 12, "B18 supplied energy and health capacities survive normalization and modifiers")
	plan["upgrades"] = {"choices": {"1": "B"}}
	_check(sim.preview(custom, plan).final_state.energy_capacity == 32, "B18 fuel cell never lowers an existing capacity")
	var bad_profile = JSON.parse_string(FileAccess.get_file_as_string("res://resources/campaign/profiles/chapter1_base.json"))
	bad_profile.capacities.erase("air_capacity")
	_check(not SimulationScript.base_profile_problem(bad_profile).is_empty(), "B18 incomplete profiles fail validation instead of using hardcoded fallback numbers")
	var command := _command("fractional-air", 0, {})
	command.verb = "apply_delta"
	command.payload = {"deltas": {"A": -1.25}}
	var committed: Dictionary = director.commit(command)
	_check(bool(committed.accepted) and is_equal_approx(director.snapshot().resources.A, 4.75), "B11 resource deltas preserve fractional breathing")
	_check(committed.snapshot == director.snapshot() and committed.snapshot.receipts.has("fractional-air") and not committed.snapshot.receipts["fractional-air"].has("snapshot"), "B12 returned snapshot contains the new receipt without nesting snapshots")
	var restored := DirectorScript.new()
	restored.restore_snapshot(JSON.parse_string(JSON.stringify(committed.snapshot)))
	command.expected_state_revision = restored.query().state_revision
	_check(bool(restored.commit(command).get("duplicate", false)) and is_equal_approx(restored.snapshot().resources.A, 4.75), "B12 JSON restore of the returned snapshot cannot charge a duplicate command")
