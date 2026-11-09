extends PanelContainer
class_name RoverRoutePlanner

## M3-63: Rover cab dashboard and map route planner (doc 25 §2.2, §4.5).
## Kept inside `game/scripts/rover/` and styled with `UiDesign`.
## Shows:
## - Cab dashboard readouts: speed, slope against the 15° VIPER limit, battery
##   against the return reserve, trailer payloads, camera mode (Cab / Chase V),
##   headlights, and crew intercom line.
## - Route planner on the map: candidate routes & waypoints, slope profile,
##   distance, time, battery cost and return reserve before confirming.
## - Also renders the Chapter 4 survey beacon layer on the Chapter 8 map when
##   bound to a `LunarNetwork` instance.

const Design = preload("res://scripts/ui/ui_design.gd")
const RoverScript = preload("res://scripts/rover/lunar_rover.gd")

signal route_confirmed(route_id: String, estimate: Dictionary)
signal panel_closed()

const CANDIDATE_ROUTES := {
	"ch04_survey": [
		{
			"id": "A",
			"label": "Route A · Direct Crater Rim",
			"waypoints": ["Aurora Garage", "North Rim Crest", "Steep Chute (19°)", "Vault Shelf"],
			"slope_profile_deg": [6.0, 14.0, 19.0, 11.0],
			"max_slope_deg": 19.0,
			"distance_km": 8.4,
			"round_trip_hours": 14.0,
			"one_way_energy": 9.0,
			"summary": "Shorter direct path, but the 19° chute exceeds the 15° VIPER slope limit.",
		},
		{
			"id": "B",
			"label": "Route B · Surveyed Ridge Switchback",
			"waypoints": ["Aurora Garage", "Beacon 1 · Ridge Saddle", "Beacon 2 · Shadow Rim", "Beacon 3 · Cold-Trap Shelf"],
			"slope_profile_deg": [5.0, 9.0, 11.0, 12.0],
			"max_slope_deg": 12.0,
			"distance_km": 11.2,
			"round_trip_hours": 18.0,
			"one_way_energy": 10.0,
			"summary": "Follows the 12° surveyed switchback; keeps 40 of 60 battery (above the 30 reserve).",
		},
		{
			"id": "C",
			"label": "Route C · Wide South Detour",
			"waypoints": ["Aurora Garage", "South Apron", "Long Basin Floor", "Cold-Trap Shelf"],
			"slope_profile_deg": [4.0, 7.0, 8.0, 10.0],
			"max_slope_deg": 10.0,
			"distance_km": 19.5,
			"round_trip_hours": 32.0,
			"one_way_energy": 17.0,
			"summary": "Gentle slopes, but round-trip cost (34) leaves only 26 battery (below the 30 reserve).",
		},
	],
	"ch08_relay": [
		{
			"id": "SURVEYED",
			"label": "Surveyed Relay Road (CH04 Beacons -> Malapert)",
			"waypoints": ["Aurora Garage", "Repeater R1 (Beacon 1)", "Repeater R2 (Marker Two)", "Repeater R3 (Approach)", "Malapert Summit"],
			"slope_profile_deg": [6.0, 9.0, 11.0, 12.0],
			"max_slope_deg": 12.0,
			"distance_km": 120.0,
			"round_trip_hours": 51.0,
			"one_way_energy": 5.0,
			"summary": "Follows the Chapter 4 beacons up the 12° ridge road; round trip uses 10 battery, keeping 4 reserve (8 with Long-Range Battery).",
		},
		{
			"id": "UNSURVEYED_SHORTCUT",
			"label": "Unsurveyed East Scarp Shortcut",
			"waypoints": ["Aurora Garage", "East Scarp Wall (18°)", "Malapert Summit"],
			"slope_profile_deg": [8.0, 18.0, 16.0],
			"max_slope_deg": 18.0,
			"distance_km": 92.0,
			"round_trip_hours": 44.0,
			"one_way_energy": 5.0,
			"summary": "Crosses an 18° scarp above the 15° VIPER limit and bypasses Marker Two.",
		},
		{
			"id": "LOW_VALLEY_DETOUR",
			"label": "Low Valley Detour",
			"waypoints": ["Aurora Garage", "Shadow Basin", "South Spur", "Malapert Summit"],
			"slope_profile_deg": [5.0, 9.0, 11.0, 11.0],
			"max_slope_deg": 11.0,
			"distance_km": 148.0,
			"round_trip_hours": 58.0,
			"one_way_energy": 6.5,
			"summary": "Round trip spends 13 battery, leaving only 1 unit (below the mandatory 2-unit reserve).",
		},
	],
}

var _rover: RefCounted
var _selected_route_id: String = "B"
var _cab_status_label: Label
var _intercom_label: Label
var _route_details_label: Label
var _confirm_feedback_label: Label
var _route_buttons_box: VBoxContainer
var _slope_canvas: Control

func _init() -> void:
	name = "RoverRoutePlanner"
	custom_minimum_size = Vector2(980, 600)
	add_theme_stylebox_override("panel", Design.glass_style(Design.colour("accent"), Color(0.04, 0.07, 0.13, 0.94), 20))
	_build_ui()

func bind_rover(rover: RefCounted) -> void:
	_rover = rover
	if _rover != null:
		_selected_route_id = "SURVEYED" if String(_rover.preset_id) == "ch08_relay" else "B"
	refresh_view()

## Pure route evaluation against VIPER 15° slope limit, battery return reserve, and provisions.
func evaluate_route(route_id: String) -> Dictionary:
	if _rover == null:
		_rover = RoverScript.new()
	var group_key := "ch08_relay" if String(_rover.preset_id) == "ch08_relay" else "ch04_survey"
	var list: Array = CANDIDATE_ROUTES.get(group_key, CANDIDATE_ROUTES.ch04_survey)
	var chosen := {}
	for item in list:
		if String(item.id) == route_id:
			chosen = item
			break
	if chosen.is_empty():
		chosen = list[0]
	var max_slope := float(chosen.get("max_slope_deg", 0.0))
	var limit_deg := float(_rover.max_incline_deg)
	var slope_ok := max_slope <= limit_deg
	var one_way := float(chosen.get("one_way_energy", _rover.one_way_allowance))
	var round_trip_cost := one_way * 2.0
	var remaining_battery := float(_rover.battery_capacity) - round_trip_cost
	var reserve_needed := float(_rover.return_reserve)
	var reserve_ok := remaining_battery >= reserve_needed
	var hours := float(chosen.get("round_trip_hours", 18.0))
	var provisions_ok := hours <= float(_rover.provisions_hours)
	var accepted := slope_ok and reserve_ok and provisions_ok

	var reason := ""
	if not slope_ok:
		reason = "Slope %d° exceeds the %d° VIPER rover limit." % [int(round(max_slope)), int(round(limit_deg))]
	elif not reserve_ok:
		reason = "Round trip leaves %s battery, below the %s return reserve." % [String.num(remaining_battery, 1), String.num(reserve_needed, 1)]
	elif not provisions_ok:
		reason = "Round trip takes %d h, exceeding %d h provisions." % [int(round(hours)), int(round(_rover.provisions_hours))]
	else:
		reason = "Route safe: max slope %d° (limit %d°) · %s battery left after round trip (reserve %s)." % [
			int(round(max_slope)),
			int(round(limit_deg)),
			String.num(remaining_battery, 1),
			String.num(reserve_needed, 1),
		]

	return {
		"accepted": accepted,
		"route_id": String(chosen.get("id", "")),
		"label": String(chosen.get("label", "")),
		"waypoints": (chosen.get("waypoints", []) as Array).duplicate(),
		"slope_profile_deg": (chosen.get("slope_profile_deg", []) as Array).duplicate(),
		"max_slope_deg": max_slope,
		"slope_limit_deg": limit_deg,
		"slope_ok": slope_ok,
		"distance_km": float(chosen.get("distance_km", 0.0)),
		"round_trip_hours": hours,
		"one_way_energy": one_way,
		"round_trip_energy": round_trip_cost,
		"battery_capacity": float(_rover.battery_capacity),
		"battery_after_round_trip": remaining_battery,
		"return_reserve": reserve_needed,
		"reserve_ok": reserve_ok,
		"provisions_ok": provisions_ok,
		"summary": String(chosen.get("summary", "")),
		"reason": reason,
	}

func select_route(route_id: String) -> Dictionary:
	_selected_route_id = route_id
	var est := evaluate_route(route_id)
	refresh_view()
	return est

func confirm_selected_route() -> Dictionary:
	var est := evaluate_route(_selected_route_id)
	if bool(est.get("accepted", false)) and _rover != null:
		_rover.planned_route_id = String(est.get("route_id", _selected_route_id))
		_rover.planned_waypoints = est.get("waypoints", []).duplicate()
		_confirm_feedback_label.text = "Confirmed: " + String(est.get("reason", ""))
		route_confirmed.emit(_selected_route_id, est)
	else:
		_confirm_feedback_label.text = "Cannot confirm route: " + String(est.get("reason", ""))
	return est

func _build_ui() -> void:
	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 12)
	add_child(root_vbox)

	# Top: Cab Dashboard strip
	var cab_card := Design.glass_panel(Design.colour("safe"), 12)
	root_vbox.add_child(cab_card)
	var cab_vbox := VBoxContainer.new()
	cab_vbox.add_theme_constant_override("separation", 4)
	cab_card.add_child(cab_vbox)

	var cab_top := HBoxContainer.new()
	cab_top.add_theme_constant_override("separation", 12)
	cab_vbox.add_child(cab_top)
	cab_top.add_child(Design.LineIcon.new("power", Design.colour("safe")))
	var cab_title := Design.label("Rover Cab Dashboard & Route Planner", "heading", "accent")
	cab_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab_top.add_child(cab_title)

	var cam_btn := Design.button("Toggle View (V)", 38)
	cam_btn.name = "ToggleRoverCameraButton"
	cam_btn.pressed.connect(func():
		if _rover != null:
			_rover.toggle_camera_view()
			refresh_view()
	)
	cab_top.add_child(cam_btn)

	var light_btn := Design.button("Headlights", 38)
	light_btn.name = "ToggleHeadlightsButton"
	light_btn.pressed.connect(func():
		if _rover != null:
			_rover.toggle_headlights()
			refresh_view()
	)
	cab_top.add_child(light_btn)

	var close_btn := Design.button("Close (Esc)", 38)
	close_btn.name = "CloseRoverPlannerButton"
	close_btn.pressed.connect(func(): panel_closed.emit())
	cab_top.add_child(close_btn)

	_cab_status_label = Design.label("", "body", "ivory")
	_cab_status_label.name = "CabDashboardReadoutLabel"
	cab_vbox.add_child(_cab_status_label)

	_intercom_label = Design.label("", "caption", "accent")
	_intercom_label.name = "CabIntercomLabel"
	cab_vbox.add_child(_intercom_label)

	# Middle: Route candidates + Slope profile chart
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	root_vbox.add_child(body)

	var left_card := Design.glass_panel(Design.colour("glass_edge"), 12)
	left_card.custom_minimum_size = Vector2(390, 0)
	body.add_child(left_card)
	var left_vbox := VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 8)
	left_card.add_child(left_vbox)
	left_vbox.add_child(Design.label("Candidate Routes (Select to Preview)", "body", "accent"))
	_route_buttons_box = VBoxContainer.new()
	_route_buttons_box.add_theme_constant_override("separation", 6)
	left_vbox.add_child(_route_buttons_box)

	var right_card := Design.glass_panel(Design.colour("accent"), 12)
	right_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(right_card)
	var right_vbox := VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_theme_constant_override("separation", 8)
	right_card.add_child(right_vbox)

	right_vbox.add_child(Design.label("Slope Profile vs VIPER 15° Limit & Return Reserve", "body", "accent"))
	_slope_canvas = SlopeProfileCanvas.new()
	_slope_canvas.custom_minimum_size = Vector2(460, 190)
	_slope_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slope_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(_slope_canvas)

	_route_details_label = Design.label("", "caption", "ivory")
	_route_details_label.name = "RouteEstimateDetailsLabel"
	right_vbox.add_child(_route_details_label)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 12)
	right_vbox.add_child(action_row)
	var confirm_btn := Design.button("Confirm Planned Route", 42)
	confirm_btn.name = "ConfirmPlannedRouteButton"
	confirm_btn.pressed.connect(func(): confirm_selected_route())
	action_row.add_child(confirm_btn)

	_confirm_feedback_label = Design.label("Pick a route that stays inside 15° and keeps the return reserve.", "caption", "muted")
	_confirm_feedback_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(_confirm_feedback_label)

func refresh_view() -> void:
	if _rover == null:
		_rover = RoverScript.new()
	var dash: Dictionary = _rover.dashboard_readout()
	_cab_status_label.text = "Speed: %s km/h · Slope: %s° / %d° VIPER limit · Battery: %s / %s (Return reserve %s) · View: %s · Headlights: %s" % [
		String.num(float(dash.speed_km_h), 1),
		String.num(float(dash.slope_deg), 1),
		int(round(float(dash.slope_limit_deg))),
		String.num(float(dash.battery), 1),
		String.num(float(dash.battery_capacity), 0),
		String.num(float(dash.return_reserve), 0),
		String(dash.camera_view).capitalize(),
		"On" if bool(dash.headlights_on) else "Off",
	]
	_intercom_label.text = String(dash.intercom)

	for c in _route_buttons_box.get_children():
		c.queue_free()
	var group_key := "ch08_relay" if String(_rover.preset_id) == "ch08_relay" else "ch04_survey"
	var list: Array = CANDIDATE_ROUTES.get(group_key, CANDIDATE_ROUTES.ch04_survey)
	for item in list:
		var rid := String(item.id)
		var btn := Design.button(String(item.label), 40)
		btn.pressed.connect(func(): select_route(rid))
		_route_buttons_box.add_child(btn)

	var est := evaluate_route(_selected_route_id)
	if _slope_canvas is SlopeProfileCanvas:
		(_slope_canvas as SlopeProfileCanvas).estimate = est
		_slope_canvas.queue_redraw()

	var wp_text := " -> ".join(est.get("waypoints", []))
	_route_details_label.text = "%s\nWaypoints: %s\nDistance: %s km · Time: %d h · Round-trip battery cost: %s · Remaining: %s (Reserve line: %s)\n%s" % [
		String(est.get("label", "")),
		wp_text,
		String.num(float(est.get("distance_km", 0.0)), 1),
		int(round(float(est.get("round_trip_hours", 0.0)))),
		String.num(float(est.get("round_trip_energy", 0.0)), 1),
		String.num(float(est.get("battery_after_round_trip", 0.0)), 1),
		String.num(float(est.get("return_reserve", 0.0)), 1),
		String(est.get("reason", "")),
	]


class SlopeProfileCanvas extends Control:
	var estimate: Dictionary = {}

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size if size.x > 40 else Vector2(460, 190))
		draw_rect(rect, Color(0.03, 0.05, 0.09, 0.95), true)
		draw_rect(rect, Color(1, 1, 1, 0.14), false, 1.0)

		var limit_deg := float(estimate.get("slope_limit_deg", 15.0))
		var max_scale_deg := 24.0
		var limit_y := rect.size.y * (1.0 - (limit_deg / max_scale_deg))
		# Draw 15 deg VIPER limit line
		draw_line(Vector2(12, limit_y), Vector2(rect.size.x - 12, limit_y), Color("#F2C230"), 2.0)

		var profile: Array = estimate.get("slope_profile_deg", [])
		if profile.is_empty():
			return
		var pts := PackedVector2Array()
		for i in range(profile.size()):
			var t := float(i) / float(maxi(1, profile.size() - 1))
			var x := lerpf(28.0, rect.size.x - 28.0, t)
			var deg := float(profile[i])
			var y := rect.size.y * (1.0 - clampf(deg / max_scale_deg, 0.05, 0.95))
			pts.append(Vector2(x, y))
		var col := Color("#50D890") if bool(estimate.get("accepted", false)) else Color("#FF6B6B")
		if pts.size() >= 2:
			draw_polyline(pts, col, 3.0, true)
		for pt in pts:
			draw_circle(pt, 5.0, col)
