# Godot --headless --path game --script res://tools/test_ch01_commissioning.gd
extends SceneTree

var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var content := CampaignContent.load_slice()
	var state := SliceState.new_snapshot()
	var hud: SliceHUD = load("res://scenes/ui/slice_hud.tscn").instantiate()
	root.add_child(hud)
	var choices := ["store_air", "lead_rafi", "record_provenance"]
	for choice in choices:
		var preview := SliceRules.preview(state, int(state.state_revision), choice)
		_check(bool(preview.result.accepted), "preview " + choice)
		var command := "%s:%s:%d" % [String(state.scene_id), choice, int(state.state_revision)]
		var commit := SliceRules.commit(state, command, int(state.state_revision), choice)
		_check(bool(commit.result.accepted), "commit " + choice)
		state = commit.snapshot
		hud.show_result(commit.result, state)
		_check(hud._prompt.text.ends_with("REVISION %d" % int(state.state_revision)), "result HUD displays numeric revision after " + choice)
		if choice == "store_air":
			_check(hud._resource_summary.text.contains("ENERGY 13/20") and hud._resource_summary.text.contains("AIR 8/10"), "result HUD refreshes committed resources")
	_check(state.completed_scene_ids == ["EX-CH01-S01", "EX-CH01-S02", "EX-CH01-S03"], "three canonical scenes complete")
	_check(state.status == "commissioning_slice_complete", "slice has a truthful completion status")
	_check(state.mission_id == "EX-M0101", "mission ownership remains canonical")
	_check(state.knowledge.has("decision:record_provenance"), "knowledge receipt is acquired")
	_check(content.get("scope", "").contains("not a complete Chapter 1"), "scope does not overclaim Chapter 1")
	var scene := CampaignContent.scene_at(content, 2)
	_check(scene.get("id", "") == "EX-CH01-S03", "last scene remains final-source identified")
	hud.free()
	print("CHAPTER 1 COMMISSIONING RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)
