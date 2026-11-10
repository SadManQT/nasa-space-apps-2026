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
const CampaignScene: PackedScene = preload("res://scenes/campaign/chapter1_campaign.tscn")

var checks := 0
var failures := 0
var capture_screenshots := false

func _init() -> void:
	CampaignCutscenePlayer.autoplay = false
	for arg in OS.get_cmdline_user_args():
		if arg == "--capture":
			capture_screenshots = true
	call_deferred("_run")

func _run() -> void:
	_test_slope_classification_and_heights()
	_test_budget_arithmetic_and_reserve()
	_test_estimate_route_reconciled_with_step()
	_test_scanner_pulse_and_features()
	_test_assisted_vs_manual_balance_and_slips()
	_test_ballistic_dust()
	await _test_visor_hud_and_capture()
	await _test_player_controller_and_campaign_eva_integration()
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
	_check(bool(inv.deliver("optics_crate", "mast").get("accepted", false)), "EVA scuffs cost condition and time without permanently blocking fragile-payload delivery")
	_check(exp_suit.payload_scuffs == 1 and bool(inv.item("optics_crate").condition.intact), "slip records a grading scuff while the fragile payload remains usable")

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

func _test_estimate_route_reconciled_with_step() -> void:
	# Verify estimate_route() matches step() across slope bands, surface tags, loads, shadow, and life_support_rank.
	var cases := [
		{"dist": 180.0, "slope": 3.0, "shadow": 0.0, "mass": 0.0, "tags": [], "rank": 0},
		{"dist": 260.0, "slope": 11.5, "shadow": 1.0, "mass": 9.5, "tags": ["soft_regolith", "cold_shadow"], "rank": 1},
		{"dist": 340.0, "slope": 18.0, "shadow": 0.0, "mass": 12.0, "tags": ["boulder", "soft_regolith"], "rank": 2},
		{"dist": 420.0, "slope": 14.0, "shadow": 1.0, "mass": 14.0, "tags": ["cold_shadow"], "rank": 3},
	]
	for idx in cases.size():
		var c: Dictionary = cases[idx]
		var suit := SuitScript.new("Cadet")
		suit.life_support_rank = int(c.rank)
		suit.payload_mass_kg = float(c.mass)
		suit.headlamp_on = float(c.shadow) > 0.1
		var est := suit.estimate_route(float(c.dist), float(c.slope), float(c.shadow), float(c.mass), c.tags)
		var walk_speed := float(est.get("walk_speed_m_s", 1.45))
		var total_s := float(est.get("round_trip_s", 0.0))
		# Simulate walking the round trip in 1.0 s steps
		var remaining_s := total_s
		while remaining_s > 0.0:
			var dt := minf(1.0, remaining_s)
			suit.step(dt, walk_speed, float(c.slope), 0.0, c.tags)
			remaining_s -= dt
		var ox_diff := absf(suit.oxygen - float(est.get("oxygen_after_exact", est.oxygen_after)))
		var pwr_diff := absf(suit.power - float(est.get("power_after_exact", est.power_after)))
		var cool_diff := absf(suit.cooling - float(est.get("cooling_after_exact", est.cooling_after)))
		_check(ox_diff < 0.05 and pwr_diff < 0.05 and cool_diff < 0.05, "case %d: estimate_route() oxygen/power/cooling matches step() within 0.05%%" % idx)
		var actual_lowest := minf(suit.oxygen, minf(suit.power, suit.cooling))
		if bool(est.reserve_ok):
			_check(actual_lowest >= suit.return_reserve_pct - 1e-4, "case %d: reserve_ok route never violates return_reserve_pct when walked via step()" % idx)

	# Boundary test right around the 25% reserve line: a route that drains to 24.7% in step() must NOT report reserve_ok!
	var border_suit := SuitScript.new("Cadet")
	border_suit.oxygen = 42.0
	border_suit.power = 42.0
	border_suit.cooling = 42.0
	border_suit.payload_mass_kg = 10.0
	var border_est := border_suit.estimate_route(290.0, 16.5, 0.0, 10.0, ["soft_regolith"])
	var border_s := float(border_est.get("round_trip_s", 0.0))
	var border_speed := float(border_est.get("walk_speed_m_s", 1.0))
	border_suit.step(border_s, border_speed, 16.5, 0.0, ["soft_regolith"])
	var border_lowest := minf(border_suit.oxygen, minf(border_suit.power, border_suit.cooling))
	_check(border_lowest < border_suit.return_reserve_pct and not bool(border_est.reserve_ok), "borderline route that violates reserve in step() is flagged reserve_ok == false in estimate_route()")

func _test_player_controller_and_campaign_eva_integration() -> void:
	var temp_save := "user://test_eva_campaign.save"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_save))
	var campaign := CampaignScene.instantiate() as Chapter1Campaign
	campaign.save_path = temp_save
	root.add_child(campaign)
	await process_frame
	await process_frame

	_check(campaign.eva_suit != null, "Chapter1Campaign initializes EvaSuit on session start")
	_check(campaign._player != null and campaign._player.eva_suit == campaign.eva_suit, "Campaign PlayerController is wired to campaign.eva_suit")
	_check(campaign.hud != null and campaign.hud.eva_visor != null and campaign.hud.eva_visor.suit == campaign.eva_suit, "Chapter1CampaignHUD binds EvaVisorHud to campaign.eva_suit")

	# Indoor room (LOC-01 in EX-CH01-S01): suit is indoor, visor is hidden, walking costs 0 budget
	_check(campaign.eva_suit.indoor, "In LOC-01 (pressurised), campaign.eva_suit.indoor is true")
	campaign.hud._process(0.05)
	_check(not campaign.hud.eva_visor.visible, "EvaVisorHud stays hidden indoors when scanner is inactive")
	campaign._player._physics_process(0.1)
	_check(is_equal_approx(campaign.eva_suit.oxygen, 100.0), "Walking indoors in campaign drains 0 oxygen")

	# Transition to exterior vacuum scene (EX-CH04-S04 in LOC-09 Ridge Route)
	campaign._start_extended("EX-CH04-S04")
	await process_frame
	_check(not campaign.eva_suit.indoor, "In LOC-09 (vacuum exterior), campaign.eva_suit.indoor is false")
	_check(is_equal_approx(campaign._player.gravity, SuitScript.MOON_G), "Campaign player switches to lunar gravity (1.62 m/s²) outdoors")
	campaign.hud._process(0.05)
	_check(campaign.hud.eva_visor.visible, "EvaVisorHud becomes visible on the campaign HUD during exterior EVA")

	# Hold F scanner pulse in campaign populates last_scan_samples via _step_campaign_eva(),
	# and releasing F clears scanner_holding so the scanner does not repeatedly re-trigger.
	if not InputMap.has_action("eva_scanner"):
		InputMap.add_action("eva_scanner")
	Input.action_press("eva_scanner")
	for _i in 10:
		campaign._player._physics_process(0.05)
		campaign._physics_process(0.05)
	_check(campaign.eva_suit.scanner_holding and campaign.eva_suit.scanner_pulse_active and campaign.eva_suit.last_scan_samples.size() == 48, "Holding F (eva_scanner) on campaign player fires scanner pulse and scans 48 surrounding terrain samples")
	Input.action_release("eva_scanner")
	campaign._player._physics_process(0.05)
	_check(not campaign.eva_suit.scanner_holding, "Releasing F (eva_scanner) immediately clears scanner_holding to false")
	for _i in 60:
		campaign._player._physics_process(0.05)
		campaign._physics_process(0.05)
	_check(not campaign.eva_suit.scanner_pulse_active and is_equal_approx(campaign.eva_suit.scanner_charge, 0.0), "After releasing F, scanner pulse finishes and does not re-trigger")
	_check(campaign.eva_suit.oxygen < 100.0 and campaign.eva_suit.power < 100.0, "Stepping outdoors in campaign drains suit oxygen and power")

	# Verify _scan_campaign_terrain uses real scene/terrain data (no coordinate-hash boulders or fake fallback hazards)
	var fallback_samples := campaign._scan_campaign_terrain(campaign._player.global_position)
	var fake_boulders_far := 0
	var fake_soft_regolith := 0
	var far_slope_sum := 0.0
	for s in fallback_samples:
		var spos: Vector3 = s.world
		var stags: Array = s.tags
		if stags.has("soft_regolith"):
			fake_soft_regolith += 1
		# Far from any authored obstacle on flat fallback floor, there must be no synthetic boulder or slope
		if spos.distance_to(campaign._player.global_position) > 8.0:
			far_slope_sum += float(s.slope_deg)
			if stags.has("boulder"):
				fake_boulders_far += 1
	_check(fake_soft_regolith == 0 and fake_boulders_far == 0 and is_equal_approx(far_slope_sum, 0.0), "Flat staging floor fallback reports 0 deg slope and zero synthetic boulder/soft_regolith hazards")

	# Place a real rock node in _room.visual_root and verify scanner detects it at its real position only
	var real_rock := Node3D.new()
	real_rock.name = "LunarBoulderTest"
	real_rock.set_meta("radius_m", 1.2)
	campaign._room.visual_root.add_child(real_rock)
	var rock_target_pos := campaign._player.global_position + Vector3(4.0, 0.0, 0.0)
	real_rock.global_position = rock_target_pos
	var rock_samples := campaign._scan_campaign_terrain(campaign._player.global_position)
	var detected_at_rock := false
	var detected_opposite := false
	for s in rock_samples:
		var spos: Vector3 = s.world
		var stags: Array = s.tags
		if Vector2(spos.x - rock_target_pos.x, spos.z - rock_target_pos.z).length() < 1.0 and stags.has("boulder"):
			detected_at_rock = true
		if Vector2(spos.x - (campaign._player.global_position.x - 12.0), spos.z - campaign._player.global_position.z).length() < 1.0 and stags.has("boulder"):
			detected_opposite = true
	_check(detected_at_rock and not detected_opposite, "Campaign terrain scanner detects boulder tag at real rock object position and not at empty opposite coordinates")
	real_rock.free()

	# Verify no_go slope (speed_scale == 0.0) prevents player movement (fixes 0.25 override)
	var player := campaign._player
	player.eva_slope_override_deg = 28.0 # No-go band (4) -> speed_scale == 0.0
	player._speed = 2.0
	var pos_before := player.global_position
	Input.action_press("move_forward")
	for _i in 5:
		player._physics_process(0.05)
	Input.action_release("move_forward")
	var horiz_moved := Vector2(player.global_position.x - pos_before.x, player.global_position.z - pos_before.z).length()
	_check(is_equal_approx(player.desired_speed, 0.0) and is_equal_approx(player._speed, 0.0) and horiz_moved < 0.001, "No-go slope (speed_scale=0) sets player desired_speed and _speed to 0 and prevents movement")

	campaign.free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_save))

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		print("  FAIL: ", message)
