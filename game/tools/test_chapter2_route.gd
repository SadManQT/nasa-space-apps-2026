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
	var golden_state := golden.new_campaign(CampaignContentFull.EXPECTED_CONTENT_REVISION)
	golden_state.resources.E = 0
	golden.restore_snapshot(golden_state)
	var golden_route := RouteScript.new(golden)
	_check(bool(golden_route.apply_entry_profile().get("accepted", false)) and golden.snapshot().resources.E == 14, "B03 zero-energy Golden carryover can fund the entry profile")
	var director := DirectorScript.new()
	director.new_campaign(CampaignContentFull.EXPECTED_CONTENT_REVISION)
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
			var payload: Dictionary = _chosen_input(target)
			if String(target.get("puzzle_id", "")) in ["P-03", "P-04"]:
				_check(not target.has("payload_defaults"), "Chapter 2 puzzle catalog does not prefill " + String(target.target_id))
				var view: Dictionary = route.puzzle_view(String(target.target_id))
				_check(bool(view.get("accepted", false)) and view.action == target.puzzle_action and view.input_revision == director.query().state_revision, "primitive puzzle view names current action and revision")
				view.progress.clear()
				_check(not route.puzzle_view(String(target.target_id)).progress.is_empty(), "puzzle view is a detached primitive copy")
			var previous_state: Dictionary = director.snapshot()
			var previous_route: Dictionary = route.snapshot()
			if String(target.get("target_id", "")) == "p03_scan_tara":
				_check(not route.perform(target.target_id, {"_command_id": "another-receipt"}).get("accepted", false), "P-03 chosen input cannot mint a different receipt identity")
				_check(not route.perform(target.target_id, {"phase": "physical:another-target"}).get("accepted", false), "P-03 chosen input cannot replace the physical phase")
				_check(director.snapshot() == previous_state and route.snapshot() == previous_route, "rejected P-03 control fields leave route and ledger unchanged")
			if String(target.get("target_id", "")) == "assign_date_token":
				_check(not route.perform(target.target_id, {"value": 42}).get("accepted", false), "P-04 token must be chosen as text")
				_check(not route.perform(target.target_id, {"value": "2035-04"}).get("accepted", false), "plausible wrong P-04 token is rejected")
				_check(not route.perform(target.target_id, {"value": "2034-04", "_command_id": "another-receipt"}).get("accepted", false), "P-04 chosen token cannot mint a different receipt identity")
				_check(director.snapshot() == previous_state and route.snapshot() == previous_route, "rejected P-04 choices leave route and ledger unchanged")
				_check(route.focus(target.target_id).get("accepted", false) and route.inspect().get("accepted", false) and route.use({"_puzzle_action": target.puzzle_action, "value": "2034-04"}).get("accepted", false), "token has a focused physical use target")
				_check(route.preview().get("accepted", false), "selected P-04 token previews")
				_check(not route.confirm("another-receipt").get("accepted", false), "accepted preview cannot change receipt identity at confirmation")
				_check(not route.preview({"value": 42}).get("accepted", false) and not route.confirm().get("accepted", false), "malformed later preview invalidates the earlier accepted preview")
				_check(director.snapshot() == previous_state and route.snapshot() == previous_route, "rejected preview and confirm are read only")
			if String(target.get("target_id", "")) == "record_stem_prediction":
				_check(route.focus(target.target_id).get("accepted", false) and route.inspect().get("accepted", false) and route.use(payload.merged({"_puzzle_action": target.puzzle_action})).get("accepted", false), "prediction has a focused physical use target")
				_check(route.preview().get("accepted", false), "explicit prediction previews")
				_check(not route.confirm("", {"prediction": "A different prediction"}).get("accepted", false), "prediction text cannot change after preview")
				_check(director.snapshot() == previous_state and route.snapshot() == previous_route, "changed prediction does not spend the background ledger")
			if not payload.is_empty():
				var missing: Dictionary = route.perform(String(target.target_id))
				_check(not bool(missing.get("accepted", false)) and director.snapshot() == previous_state and route.snapshot() == previous_route, "missing chosen input cannot commit " + String(target.target_id))
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

func _chosen_input(target: Dictionary) -> Dictionary:
	match String(target.get("puzzle_action", "")):
		"p03_record_prediction":
			return {"prediction": "Both visible colours may appear", "reason": "Alo has purple and Tara has green stems; the complete genotype is not established.", "future_test": "Compare descendant stem observations after seed harvest."}
		"p04_assign_date": return {"value": "2034-04"}
		"p04_assign_device": return {"value": "HORT-01"}
		"p04_assign_channel": return {"value": "ENGINEERING"}
	return target.get("payload_defaults", {}).duplicate(true) if target.get("payload_defaults", {}) is Dictionary else {}

func _check_retry(director: RefCounted, route: RefCounted, previous_state: Dictionary, previous_route: Dictionary) -> void:
	var copy_director := DirectorScript.new()
	copy_director.restore_snapshot(JSON.parse_string(JSON.stringify(director.snapshot())))
	var copy := RouteScript.new(copy_director)
	_check(bool(copy.restore(JSON.parse_string(JSON.stringify(route.snapshot()))).get("accepted", false)), "B05 Chapter 2 retry checkpoint survives disk-shaped JSON")
	var retried := copy.retry()
	var restored_local: Dictionary = JSON.parse_string(JSON.stringify(copy.snapshot()))
	var restored_state: Dictionary = JSON.parse_string(JSON.stringify(copy_director.snapshot()))
	var disk_route: Dictionary = JSON.parse_string(JSON.stringify(previous_route))
	var disk_state: Dictionary = JSON.parse_string(JSON.stringify(previous_state))
	_check(bool(retried.get("accepted", false)) and restored_local.p03 == disk_route.p03 and restored_local.world == disk_route.world and restored_state.resources == disk_state.resources and restored_state.receipts == disk_state.receipts, "B05 current pollen transfer retry restores puzzle, world, resources and receipts together")
