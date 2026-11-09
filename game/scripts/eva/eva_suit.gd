extends RefCounted
class_name EvaSuit

## M3-61: EVA suit budget (oxygen, power, cooling), slope classification from
## LOLA heights or direct inclines, scanner pulse (hold F) with slope bands +
## boulders, soft regolith and cold shadow, footing and payload sway (Q/E lean
## vs Story/Cadet assisted balance), lunar gait / ballistic dust parameters,
## and pre-departure route-card estimates with return reserve (doc 25 §2.3, §4.2).

const MOON_G := 1.62
const EARTH_G := 9.8

const ASSIST_MODES := ["Story", "Cadet", "Expedition"]

## Slope bands (doc 25 §4.2): each band carries a number, a label and a visual
## pattern (solid, dashed, chevron, crosshatch) so colour is never the only signal.
const SLOPE_BANDS := [
	{
		"id": "flat",
		"number": 1,
		"label": "Flat (1)",
		"pattern": "solid",
		"min_deg": 0.0,
		"max_deg": 8.0,
		"speed_scale": 1.0,
		"sway_rate": 0.0,
		"oxygen_mult": 1.0,
	},
	{
		"id": "careful",
		"number": 2,
		"label": "Careful (2)",
		"pattern": "dashed",
		"min_deg": 8.0,
		"max_deg": 15.0,
		"speed_scale": 0.72,
		"sway_rate": 0.35,
		"oxygen_mult": 1.25,
	},
	{
		"id": "steep",
		"number": 3,
		"label": "Steep (3)",
		"pattern": "chevron",
		"min_deg": 15.0,
		"max_deg": 24.0,
		"speed_scale": 0.48,
		"sway_rate": 0.75,
		"oxygen_mult": 1.6,
	},
	{
		"id": "no_go",
		"number": 4,
		"label": "No-go (4)",
		"pattern": "crosshatch",
		"min_deg": 24.0,
		"max_deg": 90.0,
		"speed_scale": 0.0,
		"sway_rate": 1.2,
		"oxygen_mult": 2.0,
	},
]

const TERRAIN_FEATURES := {
	"boulder": {"id": "boulder", "label": "Boulder hazard", "pattern": "triangle", "speed_scale": 0.65, "sway_bonus": 0.25},
	"soft_regolith": {"id": "soft_regolith", "label": "Soft regolith", "pattern": "dots", "speed_scale": 0.78, "sway_bonus": 0.2},
	"cold_shadow": {"id": "cold_shadow", "label": "Cold shadow", "pattern": "stripes", "speed_scale": 0.92, "sway_bonus": 0.1, "heater_mult": 1.8},
}

var assist_mode: String = "Cadet"
var indoor: bool = false

# Suit capacities and current levels (0..100%)
var oxygen_max: float = 100.0
var power_max: float = 100.0
var cooling_max: float = 100.0
var return_reserve_pct: float = 25.0

var oxygen: float = 100.0
var power: float = 100.0
var cooling: float = 100.0

# Rates per minute of EVA activity
var base_oxygen_per_min: float = 1.8
var base_power_per_min: float = 1.5
var base_cooling_per_min: float = 1.4
var headlamp_on: bool = false
var in_cold_shadow: bool = false

# Scanner pulse state (hold F)
var scanner_holding: bool = false
var scanner_charge: float = 0.0
var scanner_pulse_active: bool = false
var scanner_pulse_radius_m: float = 0.0
var scanner_max_radius_m: float = 28.0
var scanner_timer: float = 0.0
var last_scan_samples: Array = []

# Footing, load and sway state
var payload_mass_kg: float = 0.0
var payload_tall: bool = false
var current_slope_deg: float = 0.0
var current_band: Dictionary = SLOPE_BANDS[0]
var current_surface_tags: Array = []
var sway: float = 0.0
var lean_input: float = 0.0
var slip_cooldown: float = 0.0
var slip_count: int = 0
var slip_time_cost_s: float = 0.0
var payload_scuffs: int = 0
var last_slip_reason: String = ""

# Life support skill rank bonus (0..3 from M3-64, reduces suit burn slightly)
var life_support_rank: int = 0
var handling_rank: int = 0
var observation_rank: int = 0

func _init(mode: String = "Cadet") -> void:
	set_assist_mode(mode)
	reset_budget()

func set_assist_mode(mode: String) -> void:
	var clean := mode.strip_edges().capitalize()
	if clean in ASSIST_MODES:
		assist_mode = clean
	else:
		assist_mode = "Cadet"

func is_assisted_balance() -> bool:
	return assist_mode in ["Story", "Cadet"]

func is_untimed() -> bool:
	return assist_mode == "Story"

func reset_budget() -> void:
	oxygen = oxygen_max
	power = power_max
	cooling = cooling_max
	sway = 0.0
	slip_cooldown = 0.0
	scanner_pulse_active = false
	scanner_pulse_radius_m = 0.0

## Computes slope angle in degrees from two (x, z, height) points or horizontal distance + height delta.
static func slope_deg_from_heights(h_a: float, h_b: float, horizontal_distance_m: float) -> float:
	if horizontal_distance_m <= 0.0001:
		return 0.0
	return rad_to_deg(atan(absf(h_b - h_a) / horizontal_distance_m))

## Classifies a slope angle in degrees into one of the 4 doc 25 §4.2 bands.
static func classify_slope(slope_deg: float) -> Dictionary:
	var clamped := maxf(0.0, slope_deg)
	for band in SLOPE_BANDS:
		if clamped < float(band.max_deg) or band.id == "no_go":
			var out: Dictionary = band.duplicate(true)
			out["slope_deg"] = clamped
			out["display"] = "%s · %d° (%s)" % [band.label, int(round(clamped)), band.pattern]
			return out
	return SLOPE_BANDS.back().duplicate(true)

## Pre-departure suit budget estimate and return reserve check (doc 25 §4.2, 22 T4).
func estimate_route(distance_m: float, avg_slope_deg: float = 4.0, shadow_fraction: float = 0.0, carried_kg: float = 0.0) -> Dictionary:
	var band := classify_slope(avg_slope_deg)
	var walk_speed_m_s := 1.45 * maxf(0.35, float(band.speed_scale))
	if carried_kg > 8.0:
		walk_speed_m_s *= 0.85
	var one_way_min := (maxf(0.0, distance_m) / walk_speed_m_s) / 60.0
	var round_trip_min := one_way_min * 2.0
	var skill_scale := 1.0 - 0.05 * float(clampi(life_support_rank, 0, 3))
	var load_mult := 1.0 + clampf(carried_kg / 24.0, 0.0, 0.45)
	var ox_cost := round_trip_min * base_oxygen_per_min * float(band.oxygen_mult) * load_mult * skill_scale
	var shadow_clamped := clampf(shadow_fraction, 0.0, 1.0)
	var pwr_mult := 1.0 + shadow_clamped * 0.85 + (0.25 if headlamp_on or shadow_clamped > 0.1 else 0.0)
	var pwr_cost := round_trip_min * base_power_per_min * pwr_mult * skill_scale
	var cool_mult := (1.0 - shadow_clamped * 0.35) * load_mult
	var cool_cost := round_trip_min * base_cooling_per_min * maxf(0.5, cool_mult) * skill_scale

	var ox_after := maxf(0.0, oxygen - ox_cost)
	var pwr_after := maxf(0.0, power - pwr_cost)
	var cool_after := maxf(0.0, cooling - cool_cost)
	var lowest_after := minf(ox_after, minf(pwr_after, cool_after))
	var band_id := String(band.get("id", "flat"))
	var reserve_ok: bool = lowest_after >= return_reserve_pct and band_id != "no_go"
	var warning := ""
	if band_id == "no_go":
		warning = "Slope %d° is in the No-go band (4). Pick a gentler route." % int(round(avg_slope_deg))
	elif not reserve_ok:
		warning = "Return reserve warning: projected lowest level is %d%% (need %d%% reserve)." % [int(round(lowest_after)), int(round(return_reserve_pct))]
	else:
		warning = "Return reserve safe: %d%% remaining after round trip (reserve line %d%%)." % [int(round(lowest_after)), int(round(return_reserve_pct))]

	return {
		"distance_m": distance_m,
		"round_trip_min": snappedf(round_trip_min, 0.1),
		"band": band,
		"oxygen_cost": snappedf(ox_cost, 0.1),
		"power_cost": snappedf(pwr_cost, 0.1),
		"cooling_cost": snappedf(cool_cost, 0.1),
		"oxygen_after": snappedf(ox_after, 0.1),
		"power_after": snappedf(pwr_after, 0.1),
		"cooling_after": snappedf(cool_after, 0.1),
		"lowest_after": snappedf(lowest_after, 0.1),
		"return_reserve_pct": return_reserve_pct,
		"reserve_ok": reserve_ok,
		"warning": warning,
	}

## Updates suit budget, scanner pulse and footing for `delta` seconds.
## Walking inside the station (`indoor == true`) costs nothing (doc 25 §4.2).
func step(delta: float, moving_speed: float = 0.0, slope_deg: float = 0.0, lean_axis: float = 0.0, surface_tags: Array = [], payload_inventory: RefCounted = null, payload_id: String = "") -> Dictionary:
	current_slope_deg = maxf(0.0, slope_deg)
	current_band = classify_slope(current_slope_deg)
	current_surface_tags = surface_tags.duplicate()
	in_cold_shadow = current_surface_tags.has("cold_shadow")
	lean_input = clampf(lean_axis, -1.0, 1.0)

	# 1. Scanner pulse (hold F)
	var max_range := scanner_max_radius_m + float(clampi(observation_rank, 0, 3)) * 4.0
	if scanner_holding:
		scanner_charge = minf(1.0, scanner_charge + delta / 0.35)
		if scanner_charge >= 1.0 and not scanner_pulse_active:
			trigger_scanner_pulse()
	else:
		scanner_charge = maxf(0.0, scanner_charge - delta * 2.0)
	if scanner_pulse_active:
		scanner_timer += delta
		scanner_pulse_radius_m = minf(max_range, scanner_timer * 32.0)
		if scanner_timer >= 2.5:
			scanner_pulse_active = false
			scanner_pulse_radius_m = 0.0
			scanner_timer = 0.0

	# 2. Suit budget drain (0 indoors)
	if not indoor and delta > 0.0:
		var minutes := delta / 60.0
		var effort := 0.45 + clampf(moving_speed / 2.2, 0.0, 1.2)
		var load_mult := 1.0 + clampf(payload_mass_kg / 24.0, 0.0, 0.45)
		var skill_scale := 1.0 - 0.05 * float(clampi(life_support_rank, 0, 3))
		var ox_drain := minutes * base_oxygen_per_min * effort * float(current_band.oxygen_mult) * load_mult * skill_scale
		var pwr_mult := 1.0 + (0.8 if in_cold_shadow else 0.0) + (0.25 if headlamp_on else 0.0) + (0.15 if scanner_pulse_active else 0.0)
		var pwr_drain := minutes * base_power_per_min * pwr_mult * skill_scale
		var cool_mult := (0.65 if in_cold_shadow else 1.15) * effort * load_mult
		var cool_drain := minutes * base_cooling_per_min * cool_mult * skill_scale
		oxygen = maxf(0.0, oxygen - ox_drain)
		power = maxf(0.0, power - pwr_drain)
		cooling = maxf(0.0, cooling - cool_drain)

	# 3. Footing, speed scale and payload sway
	if slip_cooldown > 0.0:
		slip_cooldown = maxf(0.0, slip_cooldown - delta)

	var speed_scale := float(current_band.speed_scale)
	var extra_sway := 0.0
	for tag in current_surface_tags:
		if TERRAIN_FEATURES.has(tag):
			speed_scale *= float(TERRAIN_FEATURES[tag].get("speed_scale", 1.0))
			extra_sway += float(TERRAIN_FEATURES[tag].get("sway_bonus", 0.0))

	if slip_cooldown > 0.0:
		speed_scale *= 0.4

	var heavy_or_tall := payload_mass_kg >= 6.0 or payload_tall
	var handling_scale := 1.0 - 0.12 * float(clampi(handling_rank, 0, 3))
	var slipped := false
	if moving_speed > 0.08 and (heavy_or_tall or current_band.id in ["careful", "steep", "no_go"] or extra_sway > 0.0):
		var raw_drive := (float(current_band.sway_rate) + extra_sway + (0.35 if heavy_or_tall else 0.1)) * handling_scale
		var direction_sign := 1.0 if sway >= 0.0 else -1.0
		if is_assisted_balance():
			# Story and Cadet automatically counter-lean to keep sway safe
			var auto_counter := -sway * 3.2
			sway = clampf(sway + (raw_drive * 0.25 * direction_sign + auto_counter + lean_input * 0.8) * delta, -0.65, 0.65)
		else:
			# Expedition mode: player must counter-lean with Q/E (lean_input)
			sway = sway + (raw_drive * direction_sign + lean_input * 1.65) * delta
			if absf(sway) >= 1.0 and slip_cooldown <= 0.0:
				slipped = true
				_register_slip(payload_inventory, payload_id)
	else:
		sway = move_toward(sway, 0.0, delta * 1.8)

	return {
		"speed_scale": speed_scale,
		"band": current_band,
		"sway": sway,
		"slipped": slipped,
		"slip_cooldown": slip_cooldown,
		"reserve_warning": has_reserve_warning(),
		"visor": visor_readout(),
	}

func _register_slip(payload_inventory: RefCounted = null, payload_id: String = "") -> void:
	sway = 0.0
	slip_cooldown = 1.6
	slip_count += 1
	slip_time_cost_s += 3.0
	if payload_mass_kg > 0.0:
		payload_scuffs += 1
		if payload_inventory != null and not payload_id.is_empty() and payload_inventory.has_method("update_condition"):
			# A slip scuffs fragile payloads; never kills the cadet or ends the mission.
			var item: Dictionary = payload_inventory.call("item", payload_id)
			var handling: Array = item.get("definition", {}).get("handling", [])
			if handling.has("fragile"):
				payload_inventory.call("update_condition", payload_id, {"intact": false})
	last_slip_reason = "Footing slip on %s: +3 s recovery%s. Mission continues." % [
		current_band.label,
		", payload scuffed" if payload_mass_kg > 0.0 else ""
	]

func trigger_scanner_pulse() -> void:
	scanner_pulse_active = true
	scanner_timer = 0.01
	scanner_pulse_radius_m = 2.0

## Samples a heightfield or synthetic callback around `(origin_x, origin_z)` into
## band-classified grid points with numbers and patterns for the scanner overlay.
func scan_grid(origin: Vector3, sample_height: Callable, feature_At: Callable = Callable()) -> Array:
	last_scan_samples.clear()
	var step_m := 4.0
	for gx in range(-3, 4):
		for gz in range(-3, 4):
			if gx == 0 and gz == 0:
				continue
			var wx := origin.x + float(gx) * step_m
			var wz := origin.z + float(gz) * step_m
			var h0 := float(sample_height.call(wx, wz))
			var hx := float(sample_height.call(wx + 2.0, wz))
			var hz := float(sample_height.call(wx, wz + 2.0))
			var sx := slope_deg_from_heights(h0, hx, 2.0)
			var sz := slope_deg_from_heights(h0, hz, 2.0)
			var slope := sqrt(sx * sx + sz * sz)
			var band := classify_slope(slope)
			var tags: Array = []
			if feature_At.is_valid():
				var res = feature_At.call(wx, wz)
				if res is Array:
					tags = res
			last_scan_samples.append({
				"world": Vector3(wx, h0, wz),
				"slope_deg": snappedf(slope, 0.1),
				"band": band,
				"tags": tags,
			})
	return last_scan_samples

func has_reserve_warning() -> bool:
	return minf(oxygen, minf(power, cooling)) <= return_reserve_pct

## Compute ballistic dust trajectory height at time `t` seconds after kick-up:
## on the Moon (g = 1.62 m/s², vacuum), dust follows a clean parabola and falls
## straight back down without billowing clouds (ART_BIBLE §2, doc 25 §4.2).
static func ballistic_dust_point(initial_velocity: Vector3, t: float) -> Vector3:
	var clamped_t := maxf(0.0, t)
	return Vector3(
		initial_velocity.x * clamped_t,
		maxf(0.0, initial_velocity.y * clamped_t - 0.5 * MOON_G * clamped_t * clamped_t),
		initial_velocity.z * clamped_t
	)

func visor_readout() -> Dictionary:
	var lowest := minf(oxygen, minf(power, cooling))
	var status := "Nominal"
	if lowest <= return_reserve_pct:
		status = "Return reserve reached — head back to the airlock"
	elif current_band.id == "no_go":
		status = "No-go slope ahead (4) — choose a flatter line"
	elif current_band.id == "steep":
		status = "Steep ground (3) — watch footing"
	elif in_cold_shadow:
		status = "Cold shadow — suit heaters active"
	return {
		"assist_mode": assist_mode,
		"oxygen_pct": int(round(oxygen)),
		"power_pct": int(round(power)),
		"cooling_pct": int(round(cooling)),
		"return_reserve_pct": int(round(return_reserve_pct)),
		"reserve_warning": lowest <= return_reserve_pct,
		"band": current_band,
		"surface_tags": current_surface_tags.duplicate(),
		"sway": snappedf(sway, 0.01),
		"payload_mass_kg": snappedf(payload_mass_kg, 0.1),
		"headlamp_on": headlamp_on,
		"in_cold_shadow": in_cold_shadow,
		"scanner_active": scanner_pulse_active,
		"scanner_radius_m": snappedf(scanner_pulse_radius_m, 0.1),
		"slip_count": slip_count,
		"slip_time_cost_s": snappedf(slip_time_cost_s, 0.1),
		"status": status,
	}
