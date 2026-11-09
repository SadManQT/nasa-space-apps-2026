## Godot --headless --path game --script res://tools/test_hazards.gd
## M3-65: Tests for readable lunar hazards (doc 25 §4.2, §6, and 08_PUZZLE_DESIGNS.md):
## 1. Moonquake shaking, loose items to secure, aftershock warning & pressure taps (CH03)
## 2. Cold shadow heater cost and equipment temperature limits (CH04)
## 3. Impact flashes two-telescope coincidence (6 genuine, 2 artifacts) & shield maintenance (CH05)
## 4. Eclipse darkness energy budget (7 spent of 14, 7 reserve) (CH06)
## 5. Solar-storm dosimeter & shelter run (CH07; untimed in Family/Story mode, dose still shown).
extends SceneTree

const HazardsScript = preload("res://scripts/hazards/lunar_hazards.gd")
const HazardHudScript = preload("res://scripts/hazards/hazard_hud.gd")
const UiDesignScript = preload("res://scripts/ui/ui_design.gd")

var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_ch03_moonquake()
	_test_ch04_cold_shadow()
	_test_ch05_impact_flashes_and_shields()
	_test_ch06_darkness_energy_budget()
	_test_ch07_solar_storm_dosimeter_and_family_mode()
	await _test_hud_and_capture()
	print("HAZARDS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_ch03_moonquake() -> void:
	var h := HazardsScript.new("Cadet", false)
	var warn := h.issue_warning("moonquake")
	_check(bool(warn.get("accepted", false)) and h.quake_warning_issued and h.aftershock_warning_issued, "CH03 moonquake warns before tremor and includes aftershock alert")
	var tremor := h.trigger_moonquake_tremor()
	_check(bool(tremor.get("warning_issued_first", false)) and int(tremor.get("unsecured_count", 0)) == 3, "CH03 quake tremor identifies 3 loose equipment items to secure")
	var p: Dictionary = tremor.get("pressures", {})
	_check(int(p.get("main", 0)) == 100 and int(p.get("garden", 0)) == 74 and int(p.get("return", 0)) == 100, "CH03 quake reproduces P-05 100/74/100 pressure witness")
	for item_id in h.items_to_secure.duplicate():
		h.secure_quake_item(String(item_id))
	_check(h.secured_items.size() == 3 and not h.quake_tremor_active, "securing all 3 items stabilizes the room before aftershock")

func _test_ch04_cold_shadow() -> void:
	var h := HazardsScript.new("Cadet", false)
	var warn := h.issue_warning("cold_shadow")
	_check(bool(warn.get("accepted", false)) and h.shadow_warning_issued, "CH04 cold shadow warns before entering permanent shadow")
	var base_shadow := h.step_cold_shadow(true, 20.0, false)
	_check(is_equal_approx(float(base_shadow.get("heater_power_multiplier", 0.0)), 1.8) and bool(base_shadow.get("within_equipment_limits", false)), "CH04 shadow increases heater draw to 1.8x and keeps equipment above -65 C limit")
	var upgraded_shadow := h.step_cold_shadow(true, 10.0, true)
	_check(float(upgraded_shadow.get("heater_power_multiplier", 2.0)) < 1.8, "rover_lights_heater upgrade reduces cold-shadow heater cost")

func _test_ch05_impact_flashes_and_shields() -> void:
	var h := HazardsScript.new("Cadet", false)
	var warn := h.issue_warning("impact_flashes")
	_check(bool(warn.get("accepted", false)) and h.flash_warning_issued, "CH05 meteoroid stream warns before observation window")
	var candidates := [
		{"telescope_a": true, "telescope_b": true, "persistent_hot_pixel": false},
		{"telescope_a": true, "telescope_b": true, "persistent_hot_pixel": false},
		{"telescope_a": true, "telescope_b": true, "persistent_hot_pixel": false},
		{"telescope_a": true, "telescope_b": true, "persistent_hot_pixel": false},
		{"telescope_a": true, "telescope_b": true, "persistent_hot_pixel": false},
		{"telescope_a": true, "telescope_b": true, "persistent_hot_pixel": false},
		{"telescope_a": true, "telescope_b": false, "persistent_hot_pixel": true},
		{"telescope_a": false, "telescope_b": true, "persistent_hot_pixel": true},
	]
	var unmaintained := h.evaluate_impact_observations(candidates, false, false)
	_check(not bool(unmaintained.get("accepted", true)) and int(unmaintained.get("genuine_flashes", 0)) == 6 and int(unmaintained.get("artifacts_rejected", 0)) == 2, "P-10 identifies 6 genuine flashes and 2 artifacts but requires panel dust and Whipple maintenance")
	h.panel_dust_cleared = true
	h.whipple_spur_patched = true
	var maintained := h.evaluate_impact_observations(candidates, false, false)
	_check(bool(maintained.get("accepted", false)), "P-10 accepts once panel dust is cleared and Whipple spur is patched")
	h.panel_dust_cleared = false
	h.whipple_spur_patched = false
	var upgraded := h.evaluate_impact_observations(candidates, true, true)
	_check(bool(upgraded.get("accepted", false)), "dust_shield and whipple_bumper upgrades satisfy CH05 maintenance automatically")

func _test_ch06_darkness_energy_budget() -> void:
	var h := HazardsScript.new("Cadet", false)
	var warn := h.issue_warning("darkness_budget")
	_check(bool(warn.get("accepted", false)) and h.darkness_warning_issued, "CH06 eclipse darkness warns before ingress")
	var bad_floods := h.evaluate_darkness_budget(5, true, true, true)
	_check(not bool(bad_floods.get("accepted", true)) and int(bad_floods.get("allocation_spent", 0)) == 10, "keeping decorative floods spends 10 and breaches the 7-unit eclipse allocation")
	var good_budget := h.evaluate_darkness_budget(5, true, true, false)
	_check(bool(good_budget.get("accepted", false)) and int(good_budget.get("allocation_spent", 0)) == 7 and int(good_budget.get("reserve_remaining", 0)) == 7, "P-11 5 essentials + 1 pump + 1 camera spends 7 of 14 and keeps 7 reserve")

func _test_ch07_solar_storm_dosimeter_and_family_mode() -> void:
	var timed_h := HazardsScript.new("Expedition", false)
	var warn := timed_h.issue_warning("solar_storm")
	_check(bool(warn.get("accepted", false)) and timed_h.storm_warning_issued, "CH07 solar storm warns before proton arrival")
	var step1 := timed_h.step_solar_storm_shelter_run(30.0, false, 4, 2, 0)
	_check(not bool(step1.get("untimed_family_mode", true)) and is_equal_approx(float(step1.get("time_remaining_s", 0.0)), 60.0) and float(step1.get("dosimeter_dose_shown", 0.0)) > 0.0, "outside shelter accumulates dose on dosimeter and counts down timer in Expedition mode")
	var sheltered := timed_h.step_solar_storm_shelter_run(30.0, true, 4, 2, 0)
	_check(int(sheltered.get("shelter_strength", 0)) == 6 and int(sheltered.get("six_step_shelter_dose", 99)) == 0 and bool(sheltered.get("within_exposure_limit", false)), "W4 + K2 = Shelter 6 gives 0 dose across all 6 P-14 storm steps")

	# Family / Story mode: untimed shelter run, dose still shown on dosimeter
	var family_h := HazardsScript.new("Story", true)
	var fam_step := family_h.step_solar_storm_shelter_run(45.0, false, 4, 2, 0)
	_check(bool(fam_step.get("untimed_family_mode", false)) and is_equal_approx(float(fam_step.get("time_remaining_s", 0.0)), 90.0) and float(fam_step.get("dosimeter_dose_shown", 0.0)) > 0.0, "Family/Story mode shelter run is untimed while still showing accumulated dose on the dosimeter")

func _test_hud_and_capture() -> void:
	root.size = Vector2i(1280, 720)
	var h := HazardsScript.new("Story", true)
	h.issue_warning("solar_storm")
	for item_id in h.items_to_secure.duplicate():
		h.secure_quake_item(String(item_id))
	h.annex_isolated_for_aftershock = true
	h.step_cold_shadow(true, 15.0, false)
	h.panel_dust_cleared = true
	h.whipple_spur_patched = true
	h.genuine_flashes_confirmed = 6
	h.artifacts_rejected = 2
	h.step_solar_storm_shelter_run(30.0, false, 4, 2, 0)

	var hud := HazardHudScript.new()
	root.add_child(hud)
	hud.bind_hazards(h)
	await process_frame
	await process_frame

	var problems := _scan_banned_ui_text(hud)
	_check(problems.is_empty(), "HazardHudPanel contains no banned developer tokens")

	if OS.get_cmdline_user_args().has("--capture"):
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		if img != null:
			var out_path := ProjectSettings.globalize_path("res://../production/qa/evidence/M3-65_hazards_hud.png")
			img.save_png(out_path)
			print("Saved capture: ", out_path)

	hud.queue_free()
	await process_frame

func _scan_banned_ui_text(node: Node) -> Array:
	var out: Array = []
	if node is Label:
		var t := (node as Label).text
		var found := UiDesignScript.banned_regex().search(t)
		if found != null:
			out.append(found.get_string() + " in " + t)
	for child in node.get_children():
		out.append_array(_scan_banned_ui_text(child))
	return out

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)
