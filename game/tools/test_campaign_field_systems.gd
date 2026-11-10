extends SceneTree

const CampaignScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
var checks := 0
var failures := 0

func _init() -> void:
	CampaignCutscenePlayer.autoplay = false
	call_deferred("_run")

func _run() -> void:
	var campaign = CampaignScene.instantiate()
	campaign.save_path = "user://ramim_field_audit_%s.json" % OS.get_process_id()
	root.add_child(campaign)
	await process_frame
	await process_frame
	campaign._start_extended("EX-CH04-S05")
	campaign.eva_suit.in_cold_shadow = true
	_check(campaign._is_scene_in_cold_shadow(), "Cold-trap scene reports current darkness")
	campaign._start_extended("EX-CH04-S09")
	_check(not campaign._is_scene_in_cold_shadow(), "Returning to lit CH04-S09 clears prior cold-shadow state")
	campaign.eva_suit.oxygen = 63.5
	campaign.eva_suit.power = 48.25
	campaign.eva_suit.cooling = 72.0
	var saved: Dictionary = campaign._save_snapshot()
	var field: Dictionary = saved.get("presentation_resume", {}).get("field_systems", {})
	_check(is_equal_approx(float(field.get("eva_suit", {}).get("oxygen", -1.0)), 63.5), "Actual campaign checkpoint preserves partially used EVA oxygen")
	_check(campaign.get("field_systems") != null, "Campaign owns its live network, rover and hazards")
	if campaign.get("field_systems") != null:
		var systems = campaign.get("field_systems")
		_check(systems.network != null and systems.rover != null and systems.hazards != null, "Field tools bind the same live campaign models")
		var resumed = CampaignScene.instantiate()
		resumed.save_path = campaign.save_path + "_resumed"
		resumed.initial_snapshot = saved
		root.add_child(resumed)
		await process_frame
		await process_frame
		_check(is_equal_approx(resumed.eva_suit.oxygen, 63.5), "Continue restores remaining EVA oxygen without refilling")
		resumed.free()
	campaign.free()
	await process_frame
	print("CAMPAIGN FIELD SYSTEMS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + message)
