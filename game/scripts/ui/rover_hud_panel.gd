extends Control
class_name RoverHudPanel

## M3-90 (UI_11_ROVER.md): Rover screen/component connected to LunarRover.
## Exact contract:
## - Layout/content: Speed upper-left; next marker/distance centre; return
##   reserve and hours lower-left; local link lower-right.
## - Behaviour/feedback: Reserve warning names required margin; Cruise only at
##   validated stops.
## - Exit/edge case: Motion option (`reduced_motion`) hides direct driving and
##   exposes identical route/repair decisions.

signal cruise_to_stop_requested(stop_id: String)
signal route_decision_requested(route_id: String)
signal repair_decision_requested(stop_id: String)
signal disembark_requested
signal driving_requested
signal camera_toggle_requested
var campaign_bound := false

const RoverScript = preload("res://scripts/rover/lunar_rover.gd")

var rover: LunarRover
var next_marker_label := "Beacon 2 · Shadow Rim"
var next_marker_distance_m := 340.0
var local_link_status := "Repeater R1 · Line of Sight OK"
var at_validated_stop := true
var validated_stop_id := "stop_beacon_2"
var settings: Dictionary = {
	"captions": true,
	"large_text": false,
	"timer_free": true,
	"reduced_motion": false,
}

var _upper_left_card: PanelContainer
var _speed_label: Label
var _slope_label: Label
var _centre_card: PanelContainer
var _marker_label: Label
var _cruise_btn: Button
var _cruise_reason: Label
var _lower_left_card: PanelContainer
var _reserve_label: Label
var _hours_label: Label
var _warning_label: Label
var _lower_right_card: PanelContainer
var _link_label: Label
var _intercom_label: Label
var _direct_drive_bar: HBoxContainer
var _motion_decision_bar: HBoxContainer

func _ready() -> void:
	name = "RoverHudPanel"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UiKit.theme()
	if rover == null:
		rover = RoverScript.new("Cadet", "ch04_survey")
		rover.board_rover()
	_build_ui()
	refresh()

func bind_rover(value: LunarRover) -> void:
	rover = value
	refresh()

func set_accessibility(new_settings: Dictionary) -> void:
	for k in settings.keys():
		if new_settings.has(k):
			settings[k] = bool(new_settings[k])
	refresh()

func set_stop_state(validated: bool, stop_id: String = "stop_beacon_2", marker_name: String = "Beacon 2 · Shadow Rim", distance_m: float = 340.0) -> void:
	at_validated_stop = validated
	validated_stop_id = stop_id
	next_marker_label = marker_name
	next_marker_distance_m = distance_m
	refresh()

func _build_ui() -> void:
	# 1. Upper-left: Speed & Slope against 15° VIPER limit
	_upper_left_card = UiDesign.glass_panel()
	_upper_left_card.name = "UpperLeftSpeedCard"
	_upper_left_card.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_upper_left_card.offset_left = 32
	_upper_left_card.offset_top = 32
	_upper_left_card.offset_right = 372
	_upper_left_card.offset_bottom = 148
	add_child(_upper_left_card)
	var ul_box := VBoxContainer.new()
	ul_box.add_theme_constant_override("separation", 4)
	_upper_left_card.add_child(ul_box)
	_speed_label = UiDesign.label("Speed: 0.0 km/h (0.0 m/s)", "heading", "accent")
	_speed_label.name = "SpeedReadout"
	_slope_label = UiDesign.label("Slope: 0.0° · VIPER limit 15°", "body")
	_slope_label.name = "SlopeReadout"
	ul_box.add_child(_speed_label)
	ul_box.add_child(_slope_label)

	# 2. Top-Centre: Next marker / distance + Cruise at validated stops + Motion-safe route/repair decisions
	_centre_card = UiDesign.glass_panel(UiDesign.colour("accent"))
	_centre_card.name = "CentreMarkerCard"
	_centre_card.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_centre_card.offset_left = -260
	_centre_card.offset_top = 32
	_centre_card.offset_right = 260
	_centre_card.offset_bottom = 230
	add_child(_centre_card)
	var c_box := VBoxContainer.new()
	c_box.add_theme_constant_override("separation", 6)
	_centre_card.add_child(c_box)
	_marker_label = UiDesign.label("Next Marker: Beacon 2 · Shadow Rim (340 m)", "heading", "ivory")
	_marker_label.name = "NextMarkerReadout"
	c_box.add_child(_marker_label)

	_cruise_btn = UiDesign.button("Cruise to Validated Stop")
	_cruise_btn.name = "CruiseStopButton"
	_cruise_btn.pressed.connect(func() -> void:
		if at_validated_stop:
			cruise_to_stop_requested.emit(validated_stop_id)
	)
	c_box.add_child(_cruise_btn)

	_cruise_reason = UiDesign.label("", "caption", "muted")
	_cruise_reason.name = "CruiseGateReason"
	c_box.add_child(_cruise_reason)

	_direct_drive_bar = HBoxContainer.new()
	_direct_drive_bar.name = "DirectDrivingControls"
	_direct_drive_bar.add_theme_constant_override("separation", 8)
	c_box.add_child(_direct_drive_bar)
	var throttle_btn := UiDesign.button("Return to driving (W / S)" if campaign_bound else "Drive Forward (W)")
	throttle_btn.name = "DriveForwardButton"
	throttle_btn.pressed.connect(func() -> void:
		if campaign_bound:
			driving_requested.emit()
		elif rover != null:
			rover.step_drive(5.0, 0.85, 9.0, false)
			refresh()
	)
	_direct_drive_bar.add_child(throttle_btn)
	var view_btn := UiDesign.button("Toggle Cab / Chase (V)")
	view_btn.name = "ToggleViewButton"
	view_btn.pressed.connect(func() -> void:
		if campaign_bound:
			camera_toggle_requested.emit()
		elif rover != null:
			rover.toggle_camera_view()
			refresh()
	)
	_direct_drive_bar.add_child(view_btn)

	_motion_decision_bar = HBoxContainer.new()
	_motion_decision_bar.name = "MotionSafeDecisionControls"
	_motion_decision_bar.add_theme_constant_override("separation", 8)
	c_box.add_child(_motion_decision_bar)
	var route_btn := UiDesign.button("Confirm Route B Decision")
	route_btn.name = "RouteDecisionButton"
	route_btn.pressed.connect(func() -> void: route_decision_requested.emit(rover.planned_route_id if rover != null else "B"))
	_motion_decision_bar.add_child(route_btn)
	var repair_btn := UiDesign.button("Run Stop Inspection / Repair")
	repair_btn.name = "RepairDecisionButton"
	repair_btn.pressed.connect(func() -> void: repair_decision_requested.emit(validated_stop_id))
	_motion_decision_bar.add_child(repair_btn)

	# 3. Lower-left: Return reserve and hours + reserve warning naming required margin
	_lower_left_card = UiDesign.glass_panel()
	_lower_left_card.name = "LowerLeftReserveCard"
	_lower_left_card.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_lower_left_card.offset_left = 32
	_lower_left_card.offset_top = -188
	_lower_left_card.offset_right = 492
	_lower_left_card.offset_bottom = -32
	add_child(_lower_left_card)
	var ll_box := VBoxContainer.new()
	ll_box.add_theme_constant_override("separation", 4)
	_lower_left_card.add_child(ll_box)
	_reserve_label = UiDesign.label("Battery: 60.0 / 60.0 · Return Reserve: 30.0", "heading")
	_reserve_label.name = "ReserveReadout"
	_hours_label = UiDesign.label("Provisions remaining: 48.0 h", "body")
	_hours_label.name = "HoursReadout"
	_warning_label = UiDesign.label("Margin safe: +30.0 above required 30.0 return reserve.", "caption", "good")
	_warning_label.name = "ReserveWarningLabel"
	ll_box.add_child(_reserve_label)
	ll_box.add_child(_hours_label)
	ll_box.add_child(_warning_label)

	# 4. Lower-right: Local link & Crew Intercom
	_lower_right_card = UiDesign.glass_panel()
	_lower_right_card.name = "LowerRightLinkCard"
	_lower_right_card.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_lower_right_card.offset_left = -460
	_lower_right_card.offset_top = -188
	_lower_right_card.offset_right = -32
	_lower_right_card.offset_bottom = -32
	add_child(_lower_right_card)
	var lr_box := VBoxContainer.new()
	lr_box.add_theme_constant_override("separation", 4)
	_lower_right_card.add_child(lr_box)
	_link_label = UiDesign.label("Local Link: " + local_link_status, "heading", "accent")
	_link_label.name = "LocalLinkReadout"
	_intercom_label = UiDesign.label("", "caption", "ivory")
	_intercom_label.name = "IntercomReadout"
	lr_box.add_child(_link_label)
	lr_box.add_child(_intercom_label)

func refresh() -> void:
	if rover == null or _speed_label == null:
		return
	var dash := rover.dashboard_readout()
	_speed_label.text = "Speed: %.1f km/h (%.1f m/s) · View: %s" % [
		float(dash.get("speed_km_h", 0.0)),
		float(dash.get("speed_m_s", 0.0)),
		String(dash.get("camera_view", "cab")).to_upper()
	]
	_slope_label.text = "Slope: %.1f° · VIPER limit %.0f° (%s)" % [
		float(dash.get("slope_deg", 0.0)),
		float(dash.get("slope_limit_deg", 15.0)),
		"OK" if bool(dash.get("slope_within_limit", true)) else "ABOVE LIMIT"
	]
	_marker_label.text = "Next Marker: %s (%d m)" % [next_marker_label, int(round(next_marker_distance_m))]
	_cruise_btn.disabled = not at_validated_stop
	_cruise_reason.text = (
		"Validated stop ready: Cruise advances directly to %s." % next_marker_label
		if at_validated_stop
		else "Cruise unavailable: reach a validated survey stop before engaging Cruise."
	)

	# Motion option (reduced_motion) hides direct driving and exposes identical route/repair decisions
	var reduced := bool(settings.get("reduced_motion", false))
	_direct_drive_bar.visible = not reduced
	_motion_decision_bar.visible = true

	var bat := float(dash.get("battery", 60.0))
	var cap := float(dash.get("battery_capacity", 60.0))
	var req_res := float(dash.get("return_reserve", 30.0))
	var margin := float(dash.get("reserve_margin", 30.0))
	_reserve_label.text = "Battery: %.1f / %.1f · Return Reserve: %.1f" % [bat, cap, req_res]
	_hours_label.text = "Provisions remaining: %.1f h · Route %s" % [
		float(dash.get("provisions_remaining_h", 48.0)),
		String(dash.get("planned_route_id", "B"))
	]
	if bat < req_res:
		_warning_label.text = "RESERVE WARNING: Battery %.1f is %.1f below the required %.1f return reserve margin!" % [bat, absf(margin), req_res]
		_warning_label.add_theme_color_override("font_color", UiDesign.colour("danger"))
	else:
		_warning_label.text = "Reserve margin safe: +%.1f above required %.1f return reserve." % [margin, req_res]
		_warning_label.add_theme_color_override("font_color", UiDesign.colour("good"))

	_link_label.text = "Local Link: " + local_link_status
	_intercom_label.text = String(dash.get("intercom", ""))
	UiDesign.apply_type(self, get_viewport_rect().size.y, 1.5 if bool(settings.get("large_text", false)) else 1.0)
