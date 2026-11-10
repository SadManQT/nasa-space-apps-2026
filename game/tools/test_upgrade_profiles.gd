## Godot --headless --path game --script res://tools/test_upgrade_profiles.gd
## M3-91: Route/balance coverage of all 96 scenes under all 2^7 profiles.
## Checks operation/exit gates, earned acquisition order, numeric endpoints,
## conserved inventories and the living-garden ending. UI acquisition is separate.
extends SceneTree

const PuzzleData = preload("res://scripts/puzzles/puzzle_data.gd")

const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const SimulationScript = preload("res://scripts/simulation/expedition_simulation.gd")
const Chapter1RouteScript = preload("res://scripts/missions/chapter1_route.gd")
const PlantInput = preload("res://tools/support/p01_input_fixture.gd")
const PlanFixture = preload("res://tools/support/p02_plan_fixture.gd")
const Chapter2RouteScript = preload("res://scripts/missions/chapter2_route.gd")
const ExtendedRouteScript = preload("res://scripts/missions/extended_campaign_route.gd")
const ExtendedGateCatalog = preload("res://scripts/missions/extended_gate_catalog.gd")
const Chapter4Witness = preload("res://tools/support/chapter4_witness.gd")
const Chapter6Witness = preload("res://tools/support/chapter6_witness.gd")
const Chapter8Witness = preload("res://tools/support/chapter8_witness.gd")

var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		var valid := args.size() == 3 and args[0] == "--profile-batch" and args[1].is_valid_int() and args[2].is_valid_int()
		valid = valid and int(args[1]) >= 0 and int(args[1]) < int(args[2]) and int(args[2]) <= 128
		_check(valid, "child profile range is bounded and nonempty")
		if valid:
			var completed := 0
			for mask in range(int(args[1]), int(args[2])):
				if _play_upgrade_profile(mask):
					completed += 1
			print("UPGRADE PROFILE BATCH: " + JSON.stringify({"first": int(args[1]), "end": int(args[2]), "completed": completed, "checks": checks, "failures": failures}))
	else:
		_test_baseline_witnesses()
		await _test_all_128_upgrade_profiles()
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
	# Independent engine processes keep mutable model/static caches isolated.
	var workers := mini(8, maxi(1, OS.get_processor_count()))
	var batch_size := ceili(128.0 / workers)
	var batches: Array = []
	for first in range(0, 128, batch_size):
		var end := mini(first + batch_size, 128)
		var thread := Thread.new()
		var started := thread.start(_run_profile_batch.bind(first, end, ProjectSettings.globalize_path("res://")))
		_check(started == OK, "profile worker starts for %d..%d" % [first, end - 1])
		if started == OK:
			batches.append({"first": first, "end": end, "thread": thread})
	while batches.any(func(batch): return batch.thread.is_alive()):
		await process_frame
	var complete_profiles := 0
	for batch in batches:
		var result: Dictionary = batch.thread.wait_to_finish()
		var output := String(result.get("output", ""))
		print(output)
		var report: Dictionary = {}
		for line in output.split("\n"):
			if line.begins_with("UPGRADE PROFILE BATCH: "):
				var parsed = JSON.parse_string(line.trim_prefix("UPGRADE PROFILE BATCH: "))
				if parsed is Dictionary:
					report = parsed
		var valid := int(result.get("exit", -1)) == 0 and not output.contains("SCRIPT ERROR") and not output.contains("Parse Error") and not output.contains("Could not find type") and not output.contains("Failed to load script")
		valid = valid and report.get("first", -1) == batch.first and report.get("end", -1) == batch.end and report.get("completed", 0) == batch.end - batch.first and report.get("checks", 0) > 0 and report.get("failures", -1) == 0
		_check(valid, "all real scene checks complete in profile range %d..%d" % [batch.first, batch.end - 1])
		checks += int(report.get("checks", 0))
		failures += maxi(0, int(report.get("failures", 0)))
		if valid:
			complete_profiles += int(report.completed)
	_check(complete_profiles == 128, "all 128 profiles complete all 96 route scenes, with upgrades acquired only after their chapters")

static func _run_profile_batch(first: int, end: int, project_path: String) -> Dictionary:
	var output: Array = []
	var args := PackedStringArray(["--headless", "--path", project_path, "--script", "res://tools/test_upgrade_profiles.gd", "--", "--profile-batch", str(first), str(end)])
	var exit_code := OS.execute(OS.get_executable_path(), args, output, true)
	return {"exit": exit_code, "output": "\n".join(output)}

## Route/balance coverage: input fixtures stand in for player selections, not
## for any route action, scene gate or upgrade acquisition UI.
func _play_upgrade_profile(mask: int) -> bool:
	var director := DirectorScript.new()
	director.new_campaign(CampaignContentFull.EXPECTED_CONTENT_REVISION)
	var route: RefCounted = Chapter1RouteScript.new(director)
	PlanFixture.prepare(route)
	var completed := 0
	for chapter in range(1, 9):
		if chapter == 2:
			route = Chapter2RouteScript.new(director)
			if not _profile_check(bool(route.apply_entry_profile().get("accepted", false)), mask, "Chapter 2 entry profile"):
				return false
			if not _profile_check(bool(route.begin().get("accepted", false)), mask, "Chapter 2 start"):
				return false
		elif chapter >= 3:
			if chapter == 3:
				route = ExtendedRouteScript.new(director)
			if not _profile_check(bool(route.start_at("EX-CH%02d-S01" % chapter).get("accepted", false)), mask, "Chapter %d start" % chapter):
				return false
		for order in range(1, 13):
			var scene_id := "EX-CH%02d-S%02d" % [chapter, order]
			if not _profile_check(route.current_scene_id() == scene_id, mask, "route enters " + scene_id):
				return false
			var state: Dictionary = director.snapshot()
			if not _profile_check(state.upgrades.choices.size() == mini(chapter - 1, 7), mask, scene_id + " has only earned upgrades"):
				return false
			var premature: Dictionary = route.advance_scene()
			if not _profile_check(not bool(premature.get("accepted", false)) and director.snapshot() == state and route.current_scene_id() == scene_id, mask, scene_id + " rejects exit before mandatory work without mutation"):
				return false
			var targets: Array = route.targets_for_current_scene()
			if scene_id == "EX-CH01-S03":
				var calibration_order := ["calibrate_probe", "span_probe", "recheck_probe", "inspect_packet", "compare_atmosphere"]
				targets.sort_custom(func(left, right): return calibration_order.find(String(left.target_id)) < calibration_order.find(String(right.target_id)))
			if targets.size() > 1 and not (targets.back().get("required_flags", []) as Array).is_empty():
				var skipped: Dictionary = route.perform(String(targets.back().target_id), _profile_payload(targets.back(), state))
				if not _profile_check(not bool(skipped.get("accepted", false)) and director.snapshot() == state, mask, scene_id + " refuses an operation before its prerequisites"):
					return false
			for target in targets:
				if String(target.target_id) == "calibrate_probe":
					if not _profile_check(bool(PlantInput.complete_probe_transfer(route).get("accepted", false)), mask, "opening probe transfer before calibration"):
						return false
				var result: Dictionary = route.perform(String(target.target_id), _profile_payload(target, director.snapshot()))
				if not _profile_check(bool(result.get("accepted", false)), mask, scene_id + " / " + String(target.target_id) + ": " + String(result.get("reason", ""))):
					return false
			if not _verify_profile_scene(scene_id, director.snapshot(), mask):
				return false
			if not _profile_check(bool(route.gate_status().get("ready", false)), mask, scene_id + " physical gate ready"):
				return false
			var moved: Dictionary = route.advance_scene()
			if not _profile_check(bool(moved.get("accepted", false)) and bool(moved.get("transition", {"accepted": true}).get("accepted", false)), mask, scene_id + " actual scene advance"):
				return false
			completed += 1
			if order == 12:
				if not _profile_check(bool(moved.get("chapter_complete", false)) and route.completed_scene_ids().has(scene_id), mask, scene_id + " chapter completion receipt"):
					return false
				if chapter == 8 and not _profile_check(bool(moved.get("campaign_complete", false)), mask, "campaign completion receipt"):
					return false
		if chapter == 1:
			if not _profile_check(bool(route.chapter_ready().get("ready", false)), mask, "all Chapter 1 gates and living Bloom ending"):
				return false
			var handoff: Dictionary = director.snapshot()
			handoff["chapter1_ready"] = true
			if not _profile_check(bool(director.restore_snapshot(handoff).get("accepted", false)), mask, "proven Chapter 1 readiness handoff"):
				return false
		if chapter < 8 and not _acquire_profile_upgrade(director, chapter, mask):
			return false
	return _profile_check(completed == 96 and director.snapshot().upgrades.acquisition_chapter.keys() == ["1", "2", "3", "4", "5", "6", "7"], mask, "96 completed scenes and seven acquisitions in order")

func _profile_payload(target: Dictionary, state: Dictionary) -> Dictionary:
	var target_id := String(target.target_id)
	var payload: Dictionary = target.get("payload_defaults", {}).duplicate(true)
	if payload.is_empty():
		payload = PuzzleData.gate_payload(String(target.get("puzzle_action", "")))
	payload.merge(PlantInput.payload(target_id), true)
	payload = Chapter4Witness.payload(target_id, state, payload)
	payload = Chapter6Witness.payload(target_id, state, payload)
	return Chapter8Witness.payload(target_id, state, payload)

## The route suite supplies the selected pair at an already verified chapter
## boundary. Runtime acquisition and its save/UI binding have separate tests.
func _acquire_profile_upgrade(director: RefCounted, chapter: int, mask: int) -> bool:
	var state: Dictionary = director.snapshot()
	var option := "A" if (mask & (1 << (chapter - 1))) != 0 else "B"
	var upgrade_id := String(SimulationScript.UPGRADE_IDS[chapter][option])
	state.upgrades.choices[str(chapter)] = upgrade_id
	state.upgrades.acquisition_chapter[str(chapter)] = upgrade_id
	return _profile_check(bool(director.restore_snapshot(state).get("accepted", false)), mask, "persist selected upgrade after Chapter %d" % chapter)

func _verify_profile_scene(scene_id: String, state: Dictionary, mask: int) -> bool:
	var ok := true
	match scene_id:
		"EX-CH01-S12":
			ok = state.upgrades.choices.is_empty() and int(state.current_shift) == 7 and float(state.resources.E) >= 0 and float(state.resources.A) > 0 and float(state.resources.H) > 0 and float(state.resources.C) > 0 and float(state.resources.Z) <= 3
		"EX-CH02-S12":
			ok = float(state.resources.E) >= 0 and float(state.resources.A) > 0 and String(state.scenario_datetime).begins_with("2046-05-06")
		"EX-CH03-S12":
			var founder: Dictionary = state.inventories.founder_seed42
			ok = float(state.resources.E) >= 18 and int(founder.total) == 42 and int(founder.allocated) == 12 and int(founder.reserve) == 30 and bool(founder.sealed) and founder.reserve_compartments.size() == 2 and int(founder.reserve_compartments[0]) == 15 and int(founder.reserve_compartments[1]) == 15 and int(state.inventories.reserve30) == 30
		"EX-CH04-S12":
			ok = float(state.resources.E) >= 18 and is_equal_approx(float(state.resources.A), 7) and int(state.route.energy) == 40 and int(state.route.provisions) == 48 and int(state.inventories.vault12.stored) == 12
		"EX-CH05-S12":
			ok = int(state.inventories.vault12.stored) == 11 and int(state.inventories.cotton_planted) == 1 and int(state.inventories.reserve30) == 30
		"EX-CH06-S12":
			ok = float(state.resources.E) >= 7
		"EX-CH07-S08":
			var samples: Array = state.campaign_ledgers.puzzles.get("P-14", {}).get("samples", [])
			ok = samples.size() == 6 and float(state.resources.E) >= 6 and is_equal_approx(float(state.resources.A), 2.5) and int(state.resources.Z) == 0
			for sample in samples:
				var water: Dictionary = sample.get("water_conservation", {})
				ok = ok and is_equal_approx(float(water.get("garden_usable", 0)) + float(water.get("shield_water", 0)) + float(water.get("separate_reserve_unallocated", 0)), float(water.get("total", -1)))
		"EX-CH08-S12":
			var expected_rover_e := 8 if String(state.upgrades.choices["7"]) == "long_range_battery" else 4
			ok = int(state.route.energy) == expected_rover_e and int(state.route.elapsed_hours) == 51 and int(state.route.provisions) == 72 and int(state.route.provisions_remaining) == 21 and int(state.route.home_elapsed_hours) == 36 and int(state.route.crew_home) == 5 and is_equal_approx(float(state.resources.A), 5.1875) and float(state.resources.E) >= 5 and float(state.resources.H) > 0 and float(state.resources.C) > 0 and int(state.inventories.reserve30) == 30 and int(state.inventories.vault12.stored) == 11 and state.route.local_hops.size() == 4 and String(state.route.earth_leg) == "verified"
			ok = ok and state.plants.any(func(plant): return plant.individual_id == "COTTON-01" and bool(plant.alive)) and state.plants.any(func(plant): return plant.individual_id == "ALO-01" and not bool(plant.alive) and bool(plant.harvested))
	return _profile_check(ok, mask, scene_id + " numeric, conservation and ending contracts")

func _profile_check(condition: bool, mask: int, message: String) -> bool:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL PROFILE %d: %s" % [mask, message])
	return condition

func _test_boundary_and_deterministic_replay() -> void:
	# Verify flexible_seals vs moon_dirt_shelter directly on P-05
	for choice in ["moon_dirt_shelter", "flexible_seals"]:
		var director := DirectorScript.new()
		director.new_campaign(CampaignContentFull.EXPECTED_CONTENT_REVISION)
		var state := director.snapshot()
		state["upgrades"]["choices"] = {"1": "taller_mast", "2": "red_blue_leds", "3": choice}
		director.restore_snapshot(state)
		var route := ExtendedRouteScript.new(director)
		_check(bool(route.start_at("EX-CH03-S01").get("accepted", false)), "modifier fixture starts Chapter 3")
		for scene_id in ["EX-CH03-S01", "EX-CH03-S02", "EX-CH03-S03", "EX-CH03-S04"]:
			for target in ExtendedGateCatalog.targets_for_scene(scene_id):
				var result: Dictionary = route.perform(String(target.get("target_id", "")), target.get("payload_defaults", {}))
				_check(bool(result.get("accepted", false)), "modifier fixture operation " + String(target.target_id))
			if scene_id != "EX-CH03-S04":
				_check(bool(route.advance_scene().get("accepted", false)), "modifier fixture advances " + scene_id)
		var after := director.snapshot()
		var expected_a := 4.5 if choice == "flexible_seals" else 3.0
		_check(is_equal_approx(float(after.resources.get("A", 0)), expected_a), "P-05 air with pre-applied %s equals %.1f" % [choice, expected_a])

	# Verify deterministic replay: running identical upgrade profile twice produces identical state hashes
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
		_check(bool(route.start_at("EX-CH08-S01").get("accepted", false)), "replay fixture starts Chapter 8")
		for scene_id in ["EX-CH08-S01", "EX-CH08-S02", "EX-CH08-S03", "EX-CH08-S04", "EX-CH08-S05"]:
			for target in ExtendedGateCatalog.targets_for_scene(scene_id):
				var tid := String(target.get("target_id", ""))
				var result: Dictionary = route.perform(tid, Chapter8Witness.payload(tid, director.snapshot(), target.get("payload_defaults", {})))
				_check(bool(result.get("accepted", false)), "replay fixture operation " + tid)
			if scene_id != "EX-CH08-S05":
				_check(bool(route.advance_scene().get("accepted", false)), "replay fixture advances " + scene_id)
		hashes.append(JSON.stringify(director.snapshot().resources) + "|" + JSON.stringify(director.snapshot().route))
	_check(hashes[0] == hashes[1], "identical upgrade profile and input trace produce bit-identical state hashes")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)
