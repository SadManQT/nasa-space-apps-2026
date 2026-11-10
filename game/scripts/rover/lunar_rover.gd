extends RefCounted
class_name LunarRover

## M3-63: The rover and the route planner (doc 25 §4.5, viper_slope_limit.json).
## Implements:
## - VIPER-class 15° slope limit loaded from `res://resources/data/nasa/viper_slope_limit.json`
## - Battery with mandatory return reserve (Ch 4 P-07: 100 cap / 30 reserve / 30 allowance;
##   Ch 8 P-15: 14 cap (+4 with long_range_battery) / 2 reserve / 5 allowance)
## - Trailer payloads via PayloadInventory (`trailer` hook)
## - Player driving: climb in with E (`board_rover`), third-person chase camera
##   and cab view toggled with V (`toggle_camera_view`), crew ride along as
##   passengers talking on the intercom, headlights (`toggle_headlights`), climb
##   out anywhere safe (`disembark_rover`)
## - Low-gravity handling (1.62 m/s²): long suspension travel, wheels that spray
##   dust in ballistic arcs (no billowing clouds), gentle drifts on loose regolith,
##   and braking distances longer than on Earth
## - Assisted driving (Story / Cadet) stays inside the 15° slope limit;
##   Expedition mode only warns.

const VIPER_FIXTURE_PATH := "res://resources/data/nasa/viper_slope_limit.json"
const MOON_G := 1.62
const EARTH_G := 9.8

const PRESETS := {
	"ch04_survey": {
		"trip_id": "p07",
		"label": "Chapter 4 Cold-Trap Survey",
		"battery_capacity": 100.0,
		"return_reserve": 30.0,
		"one_way_allowance": 30.0,
		"provisions_hours": 48.0,
		"roster": ["kai", "rafi"],
	},
	"ch08_relay": {
		"trip_id": "p15",
		"label": "Chapter 8 Malapert Relay Road",
		"battery_capacity": 14.0,
		"return_reserve": 2.0,
		"one_way_allowance": 5.0,
		"provisions_hours": 72.0,
		"roster": ["ferreira", "kai", "rafi"],
	},
	"trainer": {
		"trip_id": "trainer",
		"label": "Moon Trainer Sortie",
		"battery_capacity": 40.0,
		"return_reserve": 12.0,
		"one_way_allowance": 8.0,
		"provisions_hours": 24.0,
		"roster": ["kai", "rafi"],
	},
}

const INTERCOM_LINES := {
	"board": "Rafi (Intercom): Strap in. Trailer latch is green and the battery reserve line is set.",
	"camera_cab": "Kai (Intercom): Cab view active — watch the inclinometer and reserve bar on the dash.",
	"camera_chase": "Kai (Intercom): External chase camera active — keep an eye on wheel dust and trailer clearance.",
	"slope_warn": "Rafi (Intercom): Easy on the throttle! VIPER limit is 15 degrees — loose regolith slips above that.",
	"slope_clamp": "Rafi (Intercom): Assisted steering held us inside the 15-degree slope limit.",
	"headlights": "Mei (Intercom): Rover headlights set. Long shadows hide shallow craters ahead.",
	"disembark": "Rafi (Intercom): Parking brake set. Safe to climb out.",
}

static var _viper_cache: Dictionary = {}

var max_incline_deg: float = 15.0
var assist_mode: String = "Cadet"
var preset_id: String = "ch04_survey"

var battery_capacity: float = 100.0
var battery: float = 100.0
var return_reserve: float = 30.0
var one_way_allowance: float = 30.0
var provisions_hours: float = 48.0
var elapsed_hours: float = 0.0

var aboard: bool = false
var brake_set: bool = true
var camera_view: String = "cab" # "cab" or "chase"
var headlights_on: bool = false
var heater_upgrade: bool = false
var long_range_battery_upgrade: bool = false

var speed_m_s: float = 0.0
var max_speed_m_s: float = 4.2
var current_slope_deg: float = 0.0
var distance_driven_m: float = 0.0
var planned_route_id: String = "B"
var planned_waypoints: Array = []
var planned_one_way_distance_m: float = 12000.0
var planned_one_way_energy: float = 30.0
var passengers: Array = ["kai", "rafi"]
var last_intercom_line: String = INTERCOM_LINES.board
var slope_warning_active: bool = false

func _init(mode: String = "Cadet", preset: String = "ch04_survey") -> void:
	max_incline_deg = load_viper_slope_limit_deg()
	set_assist_mode(mode)
	apply_preset(preset)

## Reads the published 15° slope limit from `res://resources/data/nasa/viper_slope_limit.json`.
static func load_viper_slope_limit_deg() -> float:
	if _viper_cache.is_empty() and FileAccess.file_exists(VIPER_FIXTURE_PATH):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(VIPER_FIXTURE_PATH))
		if parsed is Dictionary:
			_viper_cache = parsed
	var val = _viper_cache.get("values", {}).get("max_incline_deg", 15.0)
	return float(val)

func set_assist_mode(mode: String) -> void:
	var clean := mode.strip_edges().capitalize()
	if clean in ["Story", "Cadet", "Expedition"]:
		assist_mode = clean
	else:
		assist_mode = "Cadet"

func is_assisted_driving() -> bool:
	return assist_mode in ["Story", "Cadet"]

func apply_preset(preset: String, upgrades: Dictionary = {}) -> void:
	preset_id = preset if PRESETS.has(preset) else "ch04_survey"
	var spec: Dictionary = PRESETS[preset_id]
	battery_capacity = float(spec.battery_capacity)
	return_reserve = float(spec.return_reserve)
	one_way_allowance = float(spec.one_way_allowance)
	provisions_hours = float(spec.provisions_hours)
	passengers = (spec.roster as Array).duplicate()
	# The campaign passes director.snapshot().upgrades ({"choices": {"4": id}});
	# tests and the trainer pass flat flags. Read both.
	var chosen: Array = upgrades.get("choices", {}).values() if upgrades.get("choices") is Dictionary else []
	long_range_battery_upgrade = bool(upgrades.get("long_range_battery", false)) or chosen.has("long_range_battery")
	heater_upgrade = bool(upgrades.get("rover_lights_heater", false)) or chosen.has("rover_lights_heater")
	if preset_id == "ch08_relay" and long_range_battery_upgrade:
		battery_capacity += 4.0
	battery = battery_capacity
	planned_one_way_distance_m = 120000.0 if preset_id == "ch08_relay" else 12000.0
	planned_one_way_energy = one_way_allowance
	planned_route_id = "SURVEYED" if preset_id == "ch08_relay" else "B"
	planned_waypoints.clear()
	elapsed_hours = 0.0
	speed_m_s = 0.0
	distance_driven_m = 0.0
	brake_set = true

## Player walks up and presses E to climb in (doc 25 §4.5).
func board_rover() -> Dictionary:
	aboard = true
	brake_set = false
	last_intercom_line = INTERCOM_LINES.board
	return {"accepted": true, "aboard": true, "camera_view": camera_view, "intercom": last_intercom_line}

## Toggles between third-person chase camera and cab view with V (doc 25 §4.5).
func toggle_camera_view() -> String:
	camera_view = "chase" if camera_view == "cab" else "cab"
	last_intercom_line = INTERCOM_LINES.camera_chase if camera_view == "chase" else INTERCOM_LINES.camera_cab
	return camera_view

func toggle_headlights() -> bool:
	headlights_on = not headlights_on
	last_intercom_line = INTERCOM_LINES.headlights
	return headlights_on

## Climb out anywhere safe (slope <= max_incline_deg and speed near zero).
func disembark_rover() -> Dictionary:
	if speed_m_s > 0.15:
		return {"accepted": false, "reason": "Stop the rover before climbing out."}
	if current_slope_deg > max_incline_deg:
		return {"accepted": false, "reason": "Slope %d° exceeds the %d° safe parking limit. Reach flatter ground before climbing out." % [int(round(current_slope_deg)), int(round(max_incline_deg))]}
	speed_m_s = 0.0
	brake_set = true
	aboard = false
	last_intercom_line = INTERCOM_LINES.disembark
	return {"accepted": true, "aboard": false, "brake_set": true, "intercom": last_intercom_line}

## Low-gravity handling parameters (doc 25 §4.5):
## - Long suspension travel
## - Wheels spray dust in ballistic arcs (parabolic trajectory, no air hang)
## - Gentle drift on loose regolith
## - Longer braking distance than on Earth (proportional to EARTH_G / MOON_G).
func low_gravity_handling_profile(current_speed: float = 3.0) -> Dictionary:
	var friction_coeff := 0.32
	var earth_braking_m := (current_speed * current_speed) / (2.0 * friction_coeff * EARTH_G)
	var lunar_braking_m := (current_speed * current_speed) / (2.0 * friction_coeff * MOON_G)
	return {
		"gravity_m_s2": MOON_G,
		"suspension_travel_m": 0.42,
		"ballistic_dust": true,
		"dust_hang_cloud": false,
		"regolith_drift_factor": 1.35,
		"earth_braking_distance_m": snappedf(earth_braking_m, 0.01),
		"lunar_braking_distance_m": snappedf(lunar_braking_m, 0.01),
		"braking_ratio_vs_earth": snappedf(lunar_braking_m / maxf(0.01, earth_braking_m), 0.1),
	}

## Steps rover driving physics and battery consumption over `delta` seconds.
## Assisted driving (Story/Cadet) stops before slopes above `max_incline_deg`;
## Expedition mode allows attempting the slope and raises an explicit warning.
func step_drive(delta: float, throttle: float, terrain_slope_deg: float, in_shadow: bool = false) -> Dictionary:
	var raw_slope := maxf(0.0, terrain_slope_deg)
	slope_warning_active = raw_slope > max_incline_deg
	current_slope_deg = raw_slope
	if slope_warning_active:
		last_intercom_line = INTERCOM_LINES.slope_clamp if is_assisted_driving() else INTERCOM_LINES.slope_warn
	if battery <= 0.0 or (slope_warning_active and is_assisted_driving()):
		speed_m_s = 0.0
		return dashboard_readout()

	if brake_set or not aboard:
		speed_m_s = move_toward(speed_m_s, 0.0, delta * 2.5)
		return dashboard_readout()

	var target_speed := clampf(throttle, 0.0, 1.0) * max_speed_m_s
	var slope_penalty := clampf(1.0 - (current_slope_deg / 30.0), 0.35, 1.0)
	speed_m_s = move_toward(speed_m_s, target_speed * slope_penalty, delta * (1.8 if target_speed * slope_penalty > speed_m_s else 0.32 * MOON_G))
	var energy_per_m := planned_one_way_energy / maxf(1.0, planned_one_way_distance_m)
	var step_dist := minf(speed_m_s * delta, battery / maxf(0.000001, energy_per_m))
	distance_driven_m += step_dist
	elapsed_hours += delta / 3600.0

	battery = maxf(0.0, battery - step_dist * energy_per_m)
	if battery <= 0.000001:
		battery = 0.0
		speed_m_s = 0.0

	return dashboard_readout()

## Canonical route costs already include the authored travel, heat and repair allowance.
func estimate_journey(one_way_distance_m: float, one_way_energy: float, round_trip_hours: float) -> Dictionary:
	var cost := maxf(0.0, one_way_energy) * 2.0
	var after := battery - cost
	return {
		"round_trip_energy": cost,
		"battery_after_round_trip": after,
		"reserve_ok": after >= return_reserve,
		"provisions_ok": round_trip_hours <= maxf(0.0, provisions_hours - elapsed_hours),
		"energy_per_m": maxf(0.0, one_way_energy) / maxf(1.0, one_way_distance_m),
	}

## Cab dashboard readouts (doc 25 §2.2, §4.5): speed, slope against the 15° limit,
## battery against the return reserve, and the planned route.
func dashboard_readout(trailer_inventory: RefCounted = null) -> Dictionary:
	var trailer_mass := 0.0
	var trailer_count := 0
	if trailer_inventory != null and trailer_inventory.has_method("load_view"):
		var t_view: Dictionary = trailer_inventory.load_view("trailer")
		trailer_mass = float(t_view.get("mass_kg", 0.0))
		trailer_count = int(t_view.get("count", 0))
	var reserve_margin := battery - return_reserve
	return {
		"aboard": aboard,
		"camera_view": camera_view,
		"headlights_on": headlights_on,
		"brake_set": brake_set,
		"speed_m_s": snappedf(speed_m_s, 0.1),
		"speed_km_h": snappedf(speed_m_s * 3.6, 0.1),
		"slope_deg": snappedf(current_slope_deg, 0.1),
		"slope_limit_deg": max_incline_deg,
		"slope_within_limit": current_slope_deg <= max_incline_deg,
		"slope_warning_active": slope_warning_active,
		"battery": snappedf(battery, 0.1),
		"battery_capacity": battery_capacity,
		"return_reserve": return_reserve,
		"reserve_margin": snappedf(reserve_margin, 0.1),
		"reserve_safe": battery >= return_reserve,
		"provisions_remaining_h": snappedf(maxf(0.0, provisions_hours - elapsed_hours), 0.1),
		"planned_route_id": planned_route_id,
		"trailer_count": trailer_count,
		"trailer_mass_kg": snappedf(trailer_mass, 0.1),
		"passengers": passengers.duplicate(),
		"intercom": last_intercom_line,
	}
