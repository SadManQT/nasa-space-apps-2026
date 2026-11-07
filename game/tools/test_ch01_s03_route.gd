## Godot --headless --path game --script res://tools/test_ch01_s03_route.gd
extends SceneTree
const PlantInput = preload("res://tools/support/p01_input_fixture.gd")

const RouteScript = preload("res://scripts/missions/chapter1_route.gd")
const DirectorScript = preload("res://scripts/core/campaign_director.gd")

var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var route := RouteScript.new(DirectorScript.new())
	_check(bool(route.start_at("EX-CH01-S03").get("accepted", false)), "S03 starts")
	for target_id in ["calibrate_probe", "span_probe", "recheck_probe", "inspect_packet", "compare_atmosphere"]:
		var result: Dictionary = route.perform(target_id, PlantInput.payload(target_id))
		_check(bool(result.get("accepted", false)), "S03 action commits: " + target_id)
	_check(bool(route.gate_status().get("ready", false)), "S03 physical gate is ready")
	print("CH01 S03 ROUTE RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)
