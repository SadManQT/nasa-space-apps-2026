extends SceneTree

const CampaignScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const FieldSystemsScript = preload("res://scripts/campaign/campaign_field_systems.gd")
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
	campaign._start_extended("EX-CH08-S03")
	campaign._ui_paused = false
	campaign.field_systems.step(1.0)
	_check(campaign._is_scene_in_cold_shadow() and is_equal_approx(campaign.field_systems.hazards.heater_power_multiplier, 1.8), "Chapter 8 dark road steps the standard cold-shadow heater")
	var choices: Dictionary = campaign.director.snapshot()
	choices.upgrades.choices["4"] = "rover_lights_heater"
	campaign.director.restore_snapshot(choices)
	campaign.field_systems.rover.apply_preset("ch08_relay", choices.upgrades)
	campaign.field_systems.step(1.0)
	_check(is_equal_approx(campaign.field_systems.hazards.heater_power_multiplier, 1.45), "saved heater upgrade reaches the Chapter 8 dark road")
	_check(int(campaign.field_systems.hazards.issue_warning("cold_shadow").get("chapter", 0)) == 8, "Chapter 8 cold-shadow warning identifies the current chapter")
	_check(String(campaign.field_systems.hazards.issue_warning("cold_shadow").get("warning", "")).contains("1.45"), "Chapter 8 warning states the saved heater's actual draw")
	campaign._start_extended("EX-CH07-S05")
	choices = campaign.director.snapshot()
	choices.upgrades.choices["6"] = "storm_early_warning"
	campaign.director.restore_snapshot(choices)
	campaign._ui_paused = false
	campaign.field_systems._room_id = "LOC-01"
	campaign.field_systems.hazards.accumulated_outside_dose = 0.0
	campaign.field_systems.hazards.shelter_run_elapsed_s = 0.0
	var resources: Dictionary = campaign.director.snapshot().resources.duplicate(true)
	campaign.field_systems.step(20.0)
	_check(is_zero_approx(campaign.field_systems.hazards.accumulated_outside_dose), "saved early warning gives preparation before outside exposure")
	var restored_fields := FieldSystemsScript.new(campaign)
	restored_fields.restore(campaign.field_systems.snapshot())
	restored_fields.step(20.0)
	_check(is_equal_approx(restored_fields.hazards.accumulated_outside_dose, 0.8 / 6.0) and is_equal_approx(restored_fields.hazards.shelter_run_time_remaining_s(), 80.0), "save/resume preserves spent preparation instead of granting another 30 seconds")
	campaign.field_systems.step(20.0)
	_check(is_equal_approx(campaign.field_systems.hazards.accumulated_outside_dose, 0.8 / 6.0), "early warning grants one 30-second preparation opportunity, not one per step")
	_check(campaign.director.snapshot().resources == resources, "early warning does not change the puzzle ledger or invent solar income")
	campaign.free()
	await process_frame
	print("CAMPAIGN FIELD SYSTEMS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + message)
