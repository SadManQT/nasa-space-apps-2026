## Godot --headless --path game --script res://tools/test_extended_campaign_route.gd
## Traverses the authored physical gates for Chapters 3–8 and verifies puzzle receipt persistence.
extends SceneTree

const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const RouteScript = preload("res://scripts/missions/extended_campaign_route.gd")
const GateCatalog = preload("res://scripts/missions/extended_gate_catalog.gd")

var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var director := DirectorScript.new()
	director.new_campaign("campaign-content-1-3e003a55fa46e38f")
	var handoff: Dictionary = director.snapshot()
	handoff["chapter1_ready"] = true
	handoff["chapter_id"] = "CH03"
	handoff["mission_id"] = "EX-M0301"
	handoff["scene_id"] = "EX-CH03-S01"
	handoff["scenario_datetime"] = "2046-05-06 22:05 UTC"
	var restored: Dictionary = director.restore_snapshot(handoff)
	_check(bool(restored.get("accepted", false)), "extended route accepts the Chapter 2 handoff state")
	var route := RouteScript.new(director)
	_check(bool(route.start_at("EX-CH03-S01").get("accepted", false)), "extended route starts at canonical Chapter 3")
	var expected_scene_count := GateCatalog.scene_ids().size()
	_check(expected_scene_count == 72, "extended route contains all 72 Chapter 3–8 scenes")
	for scene_id in GateCatalog.scene_ids():
		_check(route.current_scene_id() == scene_id, "route is at " + scene_id)
		for target in GateCatalog.targets_for_scene(scene_id):
			var payload: Dictionary = target.get("payload_defaults", {}).duplicate(true) if target.get("payload_defaults", {}) is Dictionary else {}
			var result: Dictionary = route.perform(String(target.get("target_id", "")), payload)
			if not bool(result.get("accepted", false)):
				print("EXTENDED DETAIL ", scene_id, " / ", target.get("target_id", ""), " -> ", result)
			_check(bool(result.get("accepted", false)), scene_id + " commits " + String(target.get("target_id", "")))
		_check(bool(route.gate_status().get("ready", false)), scene_id + " physical gate is ready")
		var moved: Dictionary = route.advance_scene()
		var order := int(scene_id.substr(9, 2))
		if order == 12:
			_check(bool(moved.get("chapter_complete", false)), scene_id + " closes its chapter boundary")
			if scene_id == "EX-CH08-S12":
				_check(bool(moved.get("campaign_complete", false)), "EX-CH08-S12 closes the full campaign")
			else:
				var next_scene := "EX-CH%02d-S01" % (int(scene_id.substr(5, 2)) + 1)
				var next_result: Dictionary = route.start_at(next_scene)
				if not bool(next_result.get("accepted", false)):
					print("EXTENDED TRANSITION DETAIL ", next_scene, " -> ", next_result)
				_check(bool(next_result.get("accepted", false)), "route opens " + next_scene)
		else:
			_check(bool(moved.get("accepted", false)), scene_id + " advances in canonical order")
	_check(route.completed_scene_ids().size() == 72, "all 72 extended scenes retain physical completion receipts")
	_check(bool(route.chapter_ready().get("ready", false)), "final extended route reports campaign readiness")
	var snapshot: Dictionary = route.snapshot()
	var restored_route := RouteScript.new(director)
	var restore_result: Dictionary = restored_route.restore(snapshot)
	if not bool(restore_result.get("accepted", false)):
		print("EXTENDED RESTORE DETAIL ", restore_result)
	_check(bool(restore_result.get("accepted", false)), "extended route restores world and puzzle ledger state")
	_check(restored_route.current_scene_id() == "EX-CH08-S12" and restored_route.completed_scene_ids().size() == 72, "restored route remains at final campaign scene")
	print("EXTENDED CAMPAIGN ROUTE RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)
