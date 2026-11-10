extends SceneTree
const Director = preload("res://scripts/core/campaign_director.gd")
const State = preload("res://scripts/core/campaign_state.gd")
const Route = preload("res://scripts/missions/extended_campaign_route.gd")
const Gate = preload("res://scripts/missions/extended_gate_catalog.gd")
const Economy = preload("res://scripts/simulation/expedition_simulation.gd")
const PuzzleData = preload("res://scripts/puzzles/puzzle_data.gd")
var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var safe_paths := 0
	for mask in 128:
		var director := Director.new()
		var state := State.new_snapshot()
		state.scenario_datetime = "2047-02-14 00:00 UTC"
		state.inventories.founder_seed42["sealed"] = true
		state.upgrades.choices = {}
		for chapter in range(1, 8):
			state.upgrades.choices[str(chapter)] = "A" if mask & (1 << (chapter - 1)) else "B"
		director.restore_snapshot(state)
		var route := Route.new(director)
		var accepted := true
		for scene_id in ["EX-CH07-S03", "EX-CH07-S04", "EX-CH07-S06", "EX-CH07-S08"]:
			route.start_at(scene_id)
			for target in Gate.targets_for_scene(scene_id):
				var input := director.snapshot()
				# M3-7P: the storm plan answers no longer come pre-filled
				# from the catalog; the walk uses the recorded data payload.
				var payload: Dictionary = target.get("payload_defaults", {}).duplicate(true) if target.get("payload_defaults", {}) is Dictionary else {}
				if payload.is_empty():
					payload = PuzzleData.gate_payload(String(target.get("puzzle_action", "")))
				var result: Dictionary = route.perform(target.target_id, payload)
				accepted = accepted and result.accepted
				if not result.accepted:
					print("UPGRADE DETAIL ", mask, " ", target.target_id, " ", result.get("reason", ""))
		var final := director.snapshot()
		if accepted and final.resources.A > 0 and final.resources.H > 0 and final.resources.C > 0 and final.resources.Z == 0 and final.inventories.reserve30 == 30:
			safe_paths += 1
		_check(accepted and final.resources.E >= 6 and final.resources.A == 2.5 and final.resources.R == 9 and final.resources.W == 2 and final.resources.K == 2, "storm source witness remains safe for upgrade combination " + str(mask))
		var water_conserved := true
		for sample in final.campaign_ledgers.puzzles["P-14"].samples:
			var water: Dictionary = sample.water_conservation
			water_conserved = water_conserved and is_equal_approx(water.garden_usable + water.shield_water + water.separate_reserve_unallocated, water.total)
		_check(water_conserved, "normal and separate ice water remain conserved " + str(mask))
		var before := director.snapshot()
		route.perform("p14_commit_steps_3_6")
		_check(director.snapshot() == before, "duplicate sample does not reapply costs or modifiers " + str(mask))
	_check(safe_paths == 128, "all 128 inherited upgrade combinations retain a safe six-step storm witness")
	var sim := Economy.new()
	var source := State.new_snapshot()
	source.resources.E = 2
	var before := source.duplicate(true)
	var empty := sim.sampled_phase(source, {"basic_energy": 1, "heat": 0, "light": 1, "day_warm": true})
	_check(empty.accepted and empty.snapshot.resources.E == 0 and source == before, "exactly zero energy is allowed and the pure sample leaves input unchanged")
	source.resources.E = 1
	var negative := sim.sampled_phase(source, {"basic_energy": 1, "heat": 0, "light": 1, "day_warm": true})
	_check(not negative.accepted and negative.snapshot == source, "negative demand rejects without a partial authoritative mutation")
	var unshielded := State.new_snapshot()
	unshielded.resources.W = 0
	unshielded.resources.K = 0
	var unsafe := sim.sampled_phase(unshielded, {"basic_energy": 1, "heat": 2, "light": 1, "exposure_multiplier": 2, "exposure_limit": 3})
	_check(not unsafe.accepted and unsafe.snapshot == unshielded and unsafe.projected_resources.Z == 6, "unsafe dose is shown in the forecast while preserving the pre-step checkpoint")
	print("LATER NUMERIC RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + message)
