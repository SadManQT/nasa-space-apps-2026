# Godot --headless --path game --script res://tools/test_campaign_content.gd
extends SceneTree

var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var content := CampaignContent.load_slice()
	_check(not content.is_empty(), "commissioning content loads")
	var validation := CampaignContent.validate(content)
	_check(bool(validation.get("valid", false)), "commissioning content validates")
	var scenes: Array = content.get("scenes", [])
	_check(scenes.size() == 3, "slice contains three scenes")
	_check(scenes.map(func(scene: Dictionary) -> String: return String(scene.get("id", ""))) == ["EX-CH01-S01", "EX-CH01-S02", "EX-CH01-S03"], "canonical scene order")
	var line_count := 0
	for scene in scenes:
		line_count += scene.get("dialogue", []).size()
		_check(not scene.get("choice", {}).get("options", []).is_empty(), String(scene.get("id", "")) + " has explicit choices")
	_check(line_count == 13, "exact S01-S03 dialogue count")
	_check(String(content.get("source_sha256", "")) == CampaignContent.EXPECTED_SOURCE_SHA, "source revision fingerprint")
	print("CAMPAIGN CONTENT RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)
