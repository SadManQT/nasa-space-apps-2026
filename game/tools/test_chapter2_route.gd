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
	var director := DirectorScript.new()
	director.new_campaign("campaign-content-1-3e003a55fa46e38f")
	var handoff := director.snapshot()
	handoff["chapter1_ready"] = true
	handoff["chapter_id"] = "CH02"
	handoff["mission_id"] = "EX-M0201"
	handoff["scene_id"] = "EX-CH02-S01"
	handoff["scenario_datetime"] = "2046-04-30 06:00 UTC"
	handoff["resources"]["A"] = 10
	director.restore_snapshot(handoff)
	var route := RouteScript.new(director)
	_check(bool(route.start_at("EX-CH02-S01").get("accepted", false)), "Chapter 2 starts at the canonical first scene")
	for scene_id in GateCatalog.SCENE_ORDER:
		_check(route.current_scene_id() == scene_id, "route is at " + scene_id)
		for target in GateCatalog.targets_for_scene(scene_id):
			var payload: Dictionary = target.get("payload_defaults", {}).duplicate(true) if target.get("payload_defaults", {}) is Dictionary else {}
			var result: Dictionary = route.perform(String(target.get("target_id", "")), payload)
			if not bool(result.get("accepted", false)):
				print("CH02 DETAIL ", scene_id, " / ", target.get("target_id", ""), " -> ", result)
			_check(bool(result.get("accepted", false)), scene_id + " commits " + String(target.get("target_id", "")))
		_check(bool(route.gate_status().get("ready", false)), scene_id + " physical gate is ready")
		var moved := route.advance_scene()
		if scene_id == "EX-CH02-S12":
			_check(bool(moved.get("chapter_complete", false)), "Chapter 2 closes only after all twelve physical gates")
		else:
			_check(bool(moved.get("accepted", false)), scene_id + " advances in canonical order")
	var snapshot := route.snapshot()
	_check(bool(route.chapter_ready().get("ready", false)), "Chapter 2 readiness requires P-03 and P-04 evidence")
	var restored := RouteScript.new(director)
	_check(bool(restored.restore(snapshot).get("accepted", false)), "Chapter 2 route restores primitive puzzle state")
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
