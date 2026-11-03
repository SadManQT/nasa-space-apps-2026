# Godot --headless --path game --script res://tools/test_campaign_boot.gd
extends SceneTree

var checks := 0
var failures := 0
var _root: Node

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://scenes/main.tscn") as PackedScene
	_check(scene != null, "main scene resource loads")
	if scene == null:
		quit(1)
		return
	_root = scene.instantiate()
	root.add_child(_root)
	await process_frame
	_check(_root.get_node_or_null("TitleLayer") != null, "cold boot creates title layer")
	_check(_root.get_node_or_null("TitleLayer/MainMenu") != null, "cold boot creates main menu")
	_check(ProjectSettings.get_setting("application/run/main_scene", "") == "res://scenes/main.tscn", "project points at production boot scene")
	_root.free()
	await process_frame
	print("CAMPAIGN BOOT RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)
