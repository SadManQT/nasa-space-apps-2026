## Godot --headless --path game --script res://tools/test_chapter2_route.gd
extends SceneTree

const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const RouteScript = preload("res://scripts/missions/chapter2_route.gd")
const GateCatalog = preload("res://scripts/missions/chapter2_gate_catalog.gd")

var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var golden := DirectorScript.new()
	var golden_state := golden.new_campaign("campaign-content-1-3e003a55fa46e38f")
	golden_state.resources.E = 0
	golden.restore_snapshot(golden_state)
	var golden_route := RouteScript.new(golden)
	_check(bool(golden_route.apply_entry_profile().get("accepted", false)) and golden.snapshot().resources.E == 14, "B03 zero-energy Golden carryover can fund the entry profile")
	var director := DirectorScript.new()
	director.new_campaign("campaign-content-1-3e003a55fa46e38f")
	var handoff := director.snapshot()
	handoff["chapter1_ready"] = true
	handoff["chapter_id"] = "CH02"
	handoff["mission_id"] = "EX-M0201"
	handoff["scene_id"] = "EX-CH02-S01"
	handoff["scenario_datetime"] = "2046-04-30 06:00 UTC"
	handoff["resources"]["E"] = 2
	handoff["resources"]["A"] = 1  # Bloom carryover; the production handoff is covered by test_chapter1_campaign_flow.
	director.restore_snapshot(handoff)
	var route := RouteScript.new(director)
	_check(bool(route.apply_entry_profile().get("accepted", false)), "B03 installs the dated P-03 entry profile")
	_check(bool(route.start_at("EX-CH02-S01").get("accepted", false)), "Chapter 2 starts at the canonical first scene")
	for scene_id in GateCatalog.SCENE_ORDER:
		_check(route.current_scene_id() == scene_id, "route is at " + scene_id)
		for target in route.targets_for_current_scene():
			var payload: Dictionary = target.get("payload_defaults", {}).duplicate(true) if target.get("payload_defaults", {}) is Dictionary else {}
			var previous_state: Dictionary = JSON.parse_string(JSON.stringify(director.snapshot()))
			var previous_route: Dictionary = JSON.parse_string(JSON.stringify(route.snapshot()))
			var result: Dictionary = route.perform(String(target.get("target_id", "")), payload)
			if not bool(result.get("accepted", false)):
				print("CH02 DETAIL ", scene_id, " / ", target.get("target_id", ""), " -> ", result)
			_check(bool(result.get("accepted", false)), scene_id + " commits " + String(target.get("target_id", "")))
			if String(target.get("target_id", "")).begins_with("p03_complete_run_"):
				var after: Dictionary = director.snapshot()
				var duplicate: Dictionary = route.confirm()
				_check(bool(duplicate.get("duplicate", false)) and director.snapshot() == after, "B03 a reciprocal run is charged exactly once")

			if String(target.get("target_id", "")) == "p03_transfer_alo":
				_check_retry(director, route, previous_state, previous_route)

		_check(bool(route.gate_status().get("ready", false)), scene_id + " physical gate is ready")
		var moved := route.advance_scene()
		if scene_id == "EX-CH02-S12":
			_check(bool(moved.get("chapter_complete", false)), "Chapter 2 closes only after all twelve physical gates")
		else:
			_check(bool(moved.get("accepted", false)), scene_id + " advances in canonical order")
	var snapshot := route.snapshot()
	_check(not snapshot.retry_checkpoint.route.has("retry_checkpoint") and not snapshot.retry_checkpoint.director.has("route_runtime"), "B05 persisted checkpoints never recursively contain older checkpoints")
	var p03 = preload("res://scripts/puzzles/p03_pollination.gd").new()
	_check(bool(p03.restore(JSON.parse_string(JSON.stringify(snapshot.p03))).get("accepted", false)), "B02 P-03 restores JSON arrays into its typed lists")
	var before: Dictionary = p03.snapshot()
	var bad: Dictionary = JSON.parse_string(JSON.stringify(before))
	bad.completed_actions.append(42)
	_check(not bool(p03.restore(bad).get("accepted", false)) and p03.snapshot() == before, "B02 malformed typed elements reject atomically")
	_check(bool(route.chapter_ready().get("ready", false)), "Chapter 2 readiness requires P-03 and P-04 evidence")
	var restored := RouteScript.new(director)
	_check(bool(restored.restore(JSON.parse_string(JSON.stringify(snapshot))).get("accepted", false)), "Chapter 2 route restores primitive puzzle state")
	_check(restored.current_scene_id() == "EX-CH02-S12" and restored.completed_scene_ids().size() == 12, "restored Chapter 2 remains at its final canonical scene")
	print("CHAPTER 2 ROUTE RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)

func _check_retry(director: RefCounted, route: RefCounted, previous_state: Dictionary, previous_route: Dictionary) -> void:
	var copy_director := DirectorScript.new()
	copy_director.restore_snapshot(JSON.parse_string(JSON.stringify(director.snapshot())))
	var copy := RouteScript.new(copy_director)
	_check(bool(copy.restore(JSON.parse_string(JSON.stringify(route.snapshot()))).get("accepted", false)), "B05 Chapter 2 retry checkpoint survives disk-shaped JSON")
	var retried := copy.retry()
	var restored_local: Dictionary = JSON.parse_string(JSON.stringify(copy.snapshot()))
	var restored_state: Dictionary = JSON.parse_string(JSON.stringify(copy_director.snapshot()))
	_check(bool(retried.get("accepted", false)) and restored_local.p03 == previous_route.p03 and restored_local.world == previous_route.world and restored_state.resources == previous_state.resources and restored_state.receipts == previous_state.receipts, "B05 current pollen transfer retry restores puzzle, world, resources and receipts together")
