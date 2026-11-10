## Godot --headless --path game --script res://tools/test_rover.gd
## M3-63: Tests for LunarRover and RoverRoutePlanner:
## - VIPER 15° slope limit loaded from `res://resources/data/nasa/viper_slope_limit.json`
## - Battery with return reserve arithmetic (CH04 60/30/10 and CH08 14/2/5 + long_range_battery)
## - Trailer payloads via PayloadInventory
## - Boarding (E), camera view toggle (V: cab/chase), headlights, crew intercom, safe disembark
## - Low-gravity handling (suspension travel, ballistic dust, longer braking distance than Earth)
## - Assisted driving (Story/Cadet stays inside 15° limit) vs Expedition mode warning
## - Route planner estimates (waypoints, slope profile, distance, time, battery, reserve).
extends SceneTree

const RoverScript = preload("res://scripts/rover/lunar_rover.gd")
const PlannerScript = preload("res://scripts/rover/rover_route_planner.gd")
const PayloadInventoryScript = preload("res://scripts/payload/payload_inventory.gd")
const UiDesignScript = preload("res://scripts/ui/ui_design.gd")

var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_viper_slope_limit_and_assist_modes()
	_test_battery_and_return_reserve_arithmetic()
	_test_controls_intercom_and_low_g_handling()
	_test_live_journey_matches_forecast()
	_test_trailer_payloads()
	await _test_route_planner_ui_and_capture()
	print("ROVER RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_viper_slope_limit_and_assist_modes() -> void:
	var rover := RoverScript.new("Cadet", "ch04_survey")
	_check(is_equal_approx(rover.max_incline_deg, 15.0), "VIPER slope limit is 15 degrees from viper_slope_limit.json")
	rover.board_rover()
	var cadet_step := rover.step_drive(1.0, 1.0, 19.0, false)
	_check(bool(cadet_step.get("slope_warning_active", false)) and is_equal_approx(float(cadet_step.get("slope_deg", 0.0)), 19.0) and is_zero_approx(rover.distance_driven_m), "Cadet assistance reports the real 19-degree slope and prevents unsafe travel")

	var story_rover := RoverScript.new("Story", "ch04_survey")
	story_rover.board_rover()
	var story_step := story_rover.step_drive(1.0, 1.0, 21.0, false)
	_check(is_equal_approx(float(story_step.get("slope_deg", 0.0)), 21.0) and is_zero_approx(story_rover.distance_driven_m), "Story assistance reports the real unsafe slope without driving onto it")

	var exp_rover := RoverScript.new("Expedition", "ch04_survey")
	exp_rover.board_rover()
	var exp_step := exp_rover.step_drive(1.0, 1.0, 19.0, false)
	_check(bool(exp_step.get("slope_warning_active", false)) and is_equal_approx(float(exp_step.get("slope_deg", 0.0)), 19.0) and not bool(exp_step.get("slope_within_limit", true)), "Expedition mode only warns on >15-degree slope without clamping")
	_check(not bool(exp_rover.disembark_rover().get("accepted", true)), "cannot disembark on an unsafe >15-degree slope")
	exp_rover.step_drive(5.0, 0.0, 8.0, false)
	_check(bool(exp_rover.disembark_rover().get("accepted", false)), "can disembark anywhere safe (<=15 degrees)")

func _test_battery_and_return_reserve_arithmetic() -> void:
	var ch4_rover := RoverScript.new("Cadet", "ch04_survey")
	var planner := PlannerScript.new()
	planner.bind_rover(ch4_rover)

	var route_a := planner.evaluate_route("A")
	_check(not bool(route_a.get("accepted", true)) and not bool(route_a.get("slope_ok", true)), "CH04 Route A rejected because 19-degree chute exceeds 15-degree VIPER limit")

	var route_c := planner.evaluate_route("C")
	_check(not bool(route_c.get("accepted", true)) and not bool(route_c.get("reserve_ok", true)) and is_equal_approx(float(route_c.get("battery_after_round_trip", 0.0)), 20.0), "CH04 Route C rejected because 20 remaining battery breaches 30 return reserve")

	_check(is_equal_approx(ch4_rover.battery_capacity, 100.0), "CH04 starts with the canonical 100-unit rover resource")
	var route_b := planner.evaluate_route("B")
	_check(bool(route_b.get("accepted", false)) and is_equal_approx(float(route_b.get("max_slope_deg", 0.0)), 12.0) and is_equal_approx(float(route_b.get("battery_after_round_trip", 0.0)), 40.0), "CH04 Route B accepted with 12-degree max slope and 40 remaining battery (>= 30 reserve)")

	# Chapter 8 P-15 reserve arithmetic with and without long_range_battery
	var ch8_rover := RoverScript.new("Cadet", "ch08_relay")
	planner.bind_rover(ch8_rover)
	var ch8_surveyed := planner.evaluate_route("SURVEYED")
	_check(bool(ch8_surveyed.get("accepted", false)) and is_equal_approx(float(ch8_surveyed.get("battery_after_round_trip", 0.0)), 4.0) and is_equal_approx(float(ch8_surveyed.get("return_reserve", 0.0)), 2.0), "CH08 Surveyed route keeps 4 of 14 battery (>= 2 reserve)")

	var ch8_detour := planner.evaluate_route("LOW_VALLEY_DETOUR")
	_check(not bool(ch8_detour.get("accepted", true)) and is_equal_approx(float(ch8_detour.get("battery_after_round_trip", 0.0)), 1.0), "CH08 Low Valley Detour rejected because 1 remaining battery breaches 2 reserve")

	ch8_rover.apply_preset("ch08_relay", {"long_range_battery": true})
	planner.bind_rover(ch8_rover)
	var ch8_upgraded := planner.evaluate_route("SURVEYED")
	_check(bool(ch8_upgraded.get("accepted", false)) and is_equal_approx(float(ch8_upgraded.get("battery_capacity", 0.0)), 18.0) and is_equal_approx(float(ch8_upgraded.get("battery_after_round_trip", 0.0)), 8.0), "CH08 with long_range_battery upgrade starts at 18 and keeps 8 after round trip")
	planner.free()

func _test_live_journey_matches_forecast() -> void:
	var rover := RoverScript.new("Cadet", "ch04_survey")
	var planner := PlannerScript.new()
	planner.bind_rover(rover)
	rover.battery = 75.0
	var depleted := planner.evaluate_route("B")
	_check(not bool(depleted.get("accepted", true)) and is_equal_approx(float(depleted.get("battery_after_round_trip", 0.0)), 15.0), "Route B reserve forecast uses current charge instead of full capacity")
	rover.battery = rover.battery_capacity
	planner.select_route("B")
	var estimate := planner.confirm_selected_route()
	rover.board_rover()
	var distance_m := float(estimate.get("distance_km", 0.0)) * 2000.0
	var target_speed := rover.max_speed_m_s * (1.0 - 12.0 / 30.0)
	while rover.distance_driven_m < distance_m - 0.0001:
		var remaining := distance_m - rover.distance_driven_m
		rover.speed_m_s = target_speed
		rover.step_drive(minf(1.0, remaining / target_speed), 1.0, 12.0, true)
	_check(is_equal_approx(rover.battery, float(estimate.get("battery_after_round_trip", -1.0))), "Driving the planned round-trip distance consumes the exact forecast battery budget")
	rover.battery = 0.0
	var before := rover.distance_driven_m
	rover.step_drive(1.0, 1.0, 0.0, false)
	_check(is_zero_approx(rover.speed_m_s) and is_equal_approx(before, rover.distance_driven_m), "An empty rover battery cannot drive farther")
	planner.free()

func _test_controls_intercom_and_low_g_handling() -> void:
	var rover := RoverScript.new("Cadet", "ch04_survey")
	var boarded := rover.board_rover()
	_check(bool(boarded.get("accepted", false)) and rover.aboard and not rover.brake_set, "pressing E boards rover and releases parking brake")
	_check(rover.toggle_camera_view() == "chase" and rover.toggle_camera_view() == "cab", "pressing V toggles between cab view and third-person chase camera")
	_check(rover.toggle_headlights() == true and rover.headlights_on, "headlights toggle on for shadow driving")
	_check(not rover.last_intercom_line.is_empty() and rover.passengers.size() >= 2, "crew ride along as passengers and speak on the intercom")

	var handling := rover.low_gravity_handling_profile(3.5)
	_check(bool(handling.get("ballistic_dust", false)) and not bool(handling.get("dust_hang_cloud", true)), "wheels spray dust in ballistic arcs with no hanging dust cloud")
	_check(float(handling.get("lunar_braking_distance_m", 0.0)) > float(handling.get("earth_braking_distance_m", 0.0)) * 5.0, "lunar braking distance at 1.62 m/s^2 is ~6x longer than on Earth")

func _test_trailer_payloads() -> void:
	var rover := RoverScript.new("Cadet", "ch04_survey")
	var inv := PayloadInventoryScript.new(4, ["sled", "trailer"])
	var vault_case := {
		"id": "vault_carrier",
		"label": "Sealed Cold-Trap Carrier",
		"size": "large",
		"mass_kg": 18.0,
		"handling": ["sealed", "keep_cold"],
		"max_temperature_c": -15.0,
		"destination": "LOC-02",
	}
	_check(bool(inv.register_payload(vault_case).get("accepted", false)), "register keep-cold vault carrier payload")
	_check(bool(inv.pickup("vault_carrier", "trailer").get("accepted", false)), "rover trailer accepts large 18 kg keep-cold payload")
	var dash := rover.dashboard_readout(inv)
	_check(int(dash.get("trailer_count", 0)) == 1 and is_equal_approx(float(dash.get("trailer_mass_kg", 0.0)), 18.0), "cab dashboard displays trailer payload count and mass")

func _test_route_planner_ui_and_capture() -> void:
	root.size = Vector2i(1280, 720)
	var rover := RoverScript.new("Cadet", "ch04_survey")
	rover.board_rover()
	rover.toggle_headlights()
	rover.step_drive(2.0, 0.8, 11.0, true)

	var planner := PlannerScript.new()
	root.add_child(planner)
	planner.bind_rover(rover)
	planner.select_route("B")
	var confirmed := planner.confirm_selected_route()
	_check(bool(confirmed.get("accepted", false)) and rover.planned_route_id == "B", "confirming Route B updates rover planned_route_id and waypoints")
	await process_frame
	await process_frame

	var problems := _scan_banned_ui_text(planner)
	_check(problems.is_empty(), "RoverRoutePlanner contains no banned developer tokens")

	if OS.get_cmdline_user_args().has("--capture"):
		await RenderingServer.frame_post_draw
		var img1 := root.get_texture().get_image()
		if img1 != null:
			var path1 := ProjectSettings.globalize_path("res://../production/qa/evidence/M3-63_route_planner.png")
			img1.save_png(path1)
			print("Saved capture: ", path1)
		rover.apply_preset("ch08_relay", {"long_range_battery": true})
		rover.board_rover()
		planner.bind_rover(rover)
		planner.select_route("SURVEYED")
		planner.confirm_selected_route()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var img2 := root.get_texture().get_image()
		if img2 != null:
			var path2 := ProjectSettings.globalize_path("res://../production/qa/evidence/M3-63_rover_cab.png")
			img2.save_png(path2)
			print("Saved capture: ", path2)

	planner.queue_free()
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
