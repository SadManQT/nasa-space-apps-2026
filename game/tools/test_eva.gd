extends SceneTree

## M3-61: EVA suit budget arithmetic, return reserve warnings, slope
## classification from LOLA heights and synthetic ramps, scanner pulse (hold F)
## with band numbers + patterns, assisted vs manual balance (Story/Cadet vs
## Expedition), slip penalties (time + fragile scuff, never lethal/mission-ending),
## lunar ballistic dust, and visor HUD clear-centre presentation.

const SuitScript = preload("res://scripts/eva/eva_suit.gd")
const VisorScript = preload("res://scripts/eva/eva_visor_hud.gd")
const InventoryScript = preload("res://scripts/payload/payload_inventory.gd")
const HeightfieldScript = preload("res://assets/environment/terrain/lola/terrain_heightfield.gd")

var checks := 0
var failures := 0
var capture_screenshots := false

func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--capture":
			capture_screenshots = true
	call_deferred("_run")

func _run() -> void:
	_test_slope_classification_and_heights()
	_test_budget_arithmetic_and_reserve()
	_test_scanner_pulse_and_features()
	_test_assisted_vs_manual_balance_and_slips()
	_test_ballistic_dust()
	await _test_visor_hud_and_capture()
	print("EVA RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_slope_classification_and_heights() -> void:
	# Slope from heights
	var deg_0 := SuitScript.slope_deg_from_heights(10.0, 10.0, 5.0)
	_check(is_equal_approx(deg_0, 0.0), "flat heights yield 0 deg slope")
	var deg_45 := SuitScript.slope_deg_from_heights(0.0, 10.0, 10.0)
	_check(is_equal_approx(deg_45, 45.0), "equal rise and run yield 45 deg slope")

	var b1 := SuitScript.classify_slope(3.5)
	_check(String(b1.id) == "flat" and int(b1.number) == 1 and String(b1.pattern) == "solid" and is_equal_approx(float(b1.speed_scale), 1.0), "band 1 flat carries number 1 and solid pattern")
	var b2 := SuitScript.classify_slope(11.0)
	_check(String(b2.id) == "careful" and int(b2.number) == 2 and String(b2.pattern) == "dashed" and float(b2.speed_scale) < 1.0, "band 2 careful carries number 2, dashed pattern, and slows walking")
	var b3 := SuitScript.classify_slope(18.5)
	_check(String(b3.id) == "steep" and int(b3.number) == 3 and String(b3.pattern) == "chevron" and float(b3.speed_scale) < float(b2.speed_scale), "band 3 steep carries number 3 and chevron pattern")
	var b4 := SuitScript.classify_slope(28.0)
	_check(String(b4.id) == "no_go" and int(b4.number) == 4 and String(b4.pattern) == "crosshatch" and is_equal_approx(float(b4.speed_scale), 0.0), "band 4 no-go carries number 4 and crosshatch pattern")

	# Real LOLA terrain heightfield sample check (M3-60 / M1-36)
	var field := HeightfieldScript.load_region("aurora_ridge", true)
	_check(field != null, "LOLA aurora_ridge heightfield loads for EVA slope classification")
	if field != null:
		var h_origin := field.height_at(0.0, 0.0)
		var h_step := field.height_at(10.0, 0.0)
		var lola_slope := SuitScript.slope_deg_from_heights(h_origin, h_step, 10.0)
		var lola_band := SuitScript.classify_slope(lola_slope)
		_check(int(lola_band.number) >= 1 and int(lola_band.number) <= 4, "LOLA height sample classifies into a valid numbered slope band")

func _test_budget_arithmetic_and_reserve() -> void:
	var suit := SuitScript.new("Cadet")
	_check(suit.oxygen == 100.0 and suit.power == 100.0 and suit.cooling == 100.0 and suit.return_reserve_pct == 25.0, "suit starts at 100% with 25% return reserve")

	# Walking inside the station costs nothing (doc 25 §4.2)
	suit.indoor = true
	suit.step(60.0, 1.5, 0.0)
	_check(suit.oxygen == 100.0 and suit.power == 100.0 and suit.cooling == 100.0, "walking indoors costs zero suit budget")

	# Outdoor EVA drains oxygen, power and cooling
	suit.indoor = false
	suit.step(60.0, 1.5, 5.0)
	_check(suit.oxygen < 100.0 and suit.power < 100.0 and suit.cooling < 100.0, "outdoor EVA drains oxygen, power and cooling")

	# Cold shadow increases power burn (heaters) and reduces cooling load
	var sunlit_suit := SuitScript.new("Cadet")
	sunlit_suit.step(60.0, 1.4, 4.0, 0.0, [])
	var shadow_suit := SuitScript.new("Cadet")
	shadow_suit.step(60.0, 1.4, 4.0, 0.0, ["cold_shadow"])
	_check(shadow_suit.power < sunlit_suit.power, "cold shadow increases heater power draw")
	_check(shadow_suit.cooling > sunlit_suit.cooling, "cold shadow reduces sublimator cooling draw")

	# Pre-departure route estimate and return reserve check
	suit.reset_budget()
	var short_est := suit.estimate_route(120.0, 5.0, 0.1, 4.0)
	_check(bool(short_est.reserve_ok) and float(short_est.lowest_after) >= 25.0, "short gentle route stays safely above the 25% return reserve")
	var long_est := suit.estimate_route(3200.0, 16.0, 0.8, 12.0)
	_check(not bool(long_est.reserve_ok) and String(long_est.warning).contains("Return reserve warning"), "over-budget sortie warns before leaving")
	var nogo_est := suit.estimate_route(100.0, 27.0, 0.0, 0.0)
	_check(not bool(nogo_est.reserve_ok) and String(nogo_est.warning).contains("No-go"), "no-go slope warns before leaving")

	# Reserve warning flag when live level reaches return_reserve_pct
	suit.oxygen = 24.5
	_check(suit.has_reserve_warning() and bool(suit.visor_readout().reserve_warning), "visor flags reserve warning at <= 25%")

func _test_scanner_pulse_and_features() -> void:
	var suit := SuitScript.new("Cadet")
	suit.scanner_holding = true
	for _i in 10:
		suit.step(0.05, 0.0, 0.0)
	_check(suit.scanner_pulse_active and suit.scanner_pulse_radius_m > 0.0, "holding F charges and fires the scanner pulse")
	var samples := suit.scan_grid(
		Vector3.ZERO,
		func(x: float, z: float) -> float: return x * 0.22 + z * 0.05,
		func(x: float, _z: float) -> Array: return ["boulder", "cold_shadow"] if x > 4.0 else ["soft_regolith"]
	)
	_check(samples.size() == 48, "scanner grid samples surrounding terrain")
	var has_boulder := false
	for s in samples:
		if (s.tags as Array).has("boulder"):
			has_boulder = true
	_check(has_boulder and int(samples[0].band.number) >= 2, "scanner pulse identifies slope bands and boulder/soft_regolith/cold_shadow tags")

func _test_assisted_vs_manual_balance_and_slips() -> void:
	var inv := InventoryScript.new()
	inv.register_payload({
		"id": "optics_crate",
		"label": "Optics crate",
		"mass_kg": 8.0,
		"size": "medium",
		"handling": ["fragile"],
		"destination": "mast",
	})
	inv.pickup("optics_crate", "hands")

	# Story / Cadet assisted balance prevents slips automatically
	var cadet_suit := SuitScript.new("Cadet")
	cadet_suit.payload_mass_kg = 8.0
	cadet_suit.payload_tall = true
	for _i in 60:
		cadet_suit.step(0.1, 1.4, 14.0, 0.0, ["soft_regolith"], inv, "optics_crate")
	_check(cadet_suit.slip_count == 0 and bool(inv.item("optics_crate").condition.intact), "Cadet assisted balance keeps heavy load upright without slipping")

	var story_suit := SuitScript.new("Story")
	_check(story_suit.is_assisted_balance() and story_suit.is_untimed(), "Story mode enables assisted balance and untimed play")

	# Expedition mode requires manual Q/E counter-lean; un-countered sway slips
	var exp_suit := SuitScript.new("Expedition")
	_check(not exp_suit.is_assisted_balance(), "Expedition mode uses manual balance")
	exp_suit.payload_mass_kg = 8.0
	exp_suit.payload_tall = true
	var slipped := false
	for _i in 40:
		var res := exp_suit.step(0.1, 1.5, 16.0, 0.0, ["boulder"], inv, "optics_crate")
		if bool(res.slipped):
			slipped = true
			break
	_check(slipped and exp_suit.slip_count == 1 and exp_suit.slip_time_cost_s >= 3.0, "un-countered sway in Expedition mode causes a non-lethal slip that costs time")
	_check(not bool(inv.item("optics_crate").condition.intact), "slip scuffs fragile payload condition without ending the mission")

	# Counter-leaning with Q/E in Expedition mode prevents the slip
	var exp_lean := SuitScript.new("Expedition")
	exp_lean.payload_mass_kg = 8.0
	for _i in 40:
		var lean := -0.7 if exp_lean.sway >= 0.0 else 0.7
		exp_lean.step(0.1, 1.4, 12.0, lean, [])
	_check(exp_lean.slip_count == 0, "Q/E counter-lean in Expedition mode keeps balance")

func _test_ballistic_dust() -> void:
	var p0 := SuitScript.ballistic_dust_point(Vector3(1.0, 1.62, 0.0), 0.0)
	var p1 := SuitScript.ballistic_dust_point(Vector3(1.0, 1.62, 0.0), 1.0)
	var p2 := SuitScript.ballistic_dust_point(Vector3(1.0, 1.62, 0.0), 2.0)
	_check(p0.y == 0.0 and p1.y > 0.7 and is_equal_approx(p2.y, 0.0), "ballistic dust rises and falls straight back down under lunar gravity (1.62 m/s²)")

func _test_visor_hud_and_capture() -> void:
	var suit := SuitScript.new("Cadet")
	suit.oxygen = 76.0
	suit.power = 68.0
	suit.cooling = 82.0
	suit.payload_mass_kg = 6.5
	suit.headlamp_on = true
	suit.scanner_holding = true
	for _i in 10:
		suit.step(0.05, 1.3, 11.5, 0.0, ["cold_shadow"])
	suit.scan_grid(
		Vector3.ZERO,
		func(x: float, z: float) -> float: return x * 0.18 + z * 0.08,
		func(x: float, _z: float) -> Array: return ["boulder", "cold_shadow"] if x > 0.0 else ["soft_regolith"]
	)

	var visor := VisorScript.new()
	root.add_child(visor)
	visor.bind_suit(suit)
	await process_frame
	await process_frame

	var centre_rect := Rect2(root.size.x / 3.0, root.size.y / 3.0, root.size.x / 3.0, root.size.y / 3.0)
	var card_rect := visor._card.get_global_rect()
	_check(not centre_rect.intersects(card_rect), "EVA visor card keeps the centre third of the screen clear")
	_check(visor._ox_label.text.contains("Reserve 25%") and visor._band_label.text.contains("Careful (2)"), "visor displays reserve and numbered slope band")

	if capture_screenshots and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		if img != null:
			img.save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/M3-61_eva_visor_scanner.png"))
	visor.free()
	await process_frame

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		print("  FAIL: ", message)
