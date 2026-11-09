extends RefCounted
class_name LunarHazards

## M3-65: Readable hazards (doc 25 §4.2, §6, and 08_PUZZLE_DESIGNS.md).
## Never combat; every hazard warns before it matters:
## 1. Moonquake (CH03, P-05): shallow quake shaking with loose items to secure,
##    aftershock warnings, and garden feedthrough pressure drop (82 -> 74 vs 100 trunk).
## 2. Cold shadow (CH04, P-07 / P-08): permanent shadow temperature (~-210 °C),
##    suit heater power cost, and equipment cold-limit checks (sealed cold carrier).
## 3. Impact flashes (CH05, P-10): dual-telescope meteoroid flash observations
##    (6 genuine coincident flashes vs 2 single-camera artifacts) + panel dust
##    and Whipple micrometeoroid shield maintenance.
## 4. Darkness energy budget (CH06, P-11 / P-12): total lunar eclipse ("red ring",
##    2047-01-12) darkness budget — 7 units protected allocation (5 essentials +
##    1 pump + 1 camera) out of 14 battery, keeping 7 reserve.
## 5. Solar storm shelter run & dosimeter (CH07, P-13 / P-14): proton-flux warning,
##    dosimeter reading outside shelter, shelter run to LOC-04 Safe Room (untimed
##    in Story / Family mode, dose still shown), and 6-step storm shelter profile
##    (S6 = W4 + K2 -> 0 dose; limit <= 3).

const HAZARD_ORDER := ["moonquake", "cold_shadow", "impact_flashes", "darkness_budget", "solar_storm"]

var active_hazard: String = "moonquake"
var family_mode: bool = false
var assist_mode: String = "Cadet"

# 1. Moonquake state (CH03)
var quake_warning_issued: bool = false
var quake_tremor_active: bool = false
var aftershock_warning_issued: bool = false
var items_to_secure: Array = ["garden_clamp_tray", "service_gauge_rack", "seed_vial_drawer"]
var secured_items: Array = []
var annex_isolated_for_aftershock: bool = false
var main_trunk_pressure: int = 100
var garden_branch_pressure: int = 82
var return_trunk_pressure: int = 100

# 2. Cold shadow state (CH04)
var shadow_warning_issued: bool = false
var in_permanent_shadow: bool = false
var ambient_temp_c: float = -45.0
var shadow_temp_c: float = -210.0
var equipment_temp_c: float = -25.0
var equipment_min_limit_c: float = -65.0
var carrier_max_cold_limit_c: float = -10.0
var heater_power_multiplier: float = 1.0

# 3. Impact flashes & shield maintenance state (CH05)
var flash_warning_issued: bool = false
var genuine_flashes_confirmed: int = 0
var artifacts_rejected: int = 0
var panel_dust_cleared: bool = false
var whipple_spur_patched: bool = false

# 4. Eclipse darkness energy budget state (CH06)
var darkness_warning_issued: bool = false
var eclipse_battery_jar: int = 14
var eclipse_essentials_cost: int = 5
var eclipse_pump_allocated: bool = true
var eclipse_camera_allocated: bool = true
var decorative_floods_shed: bool = true

# 5. Solar storm dosimeter & shelter run state (CH07)
var storm_warning_issued: bool = false
var outside_shelter: bool = true
var shelter_run_timer_s: float = 90.0
var shelter_run_elapsed_s: float = 0.0
var dosimeter_rate_units_per_min: float = 0.8
var accumulated_outside_dose: float = 0.0
var storm_shelter_strength: int = 6 # W4 + K2 = S6
var storm_step_multipliers: Array = [1, 2, 3, 2, 1, 1]
var storm_exposure_limit: int = 3

func _init(mode: String = "Cadet", is_family: bool = false) -> void:
	set_modes(mode, is_family)

func set_modes(mode: String = "Cadet", is_family: bool = false) -> void:
	var clean := mode.strip_edges().capitalize()
	assist_mode = clean if clean in ["Story", "Cadet", "Expedition"] else "Cadet"
	family_mode = is_family or (assist_mode == "Story")

func is_shelter_run_untimed() -> bool:
	return family_mode or assist_mode == "Story"

## Issues the pre-hazard warning before any hazard consequence matters (doc 25 prompt).
func issue_warning(hazard_id: String) -> Dictionary:
	active_hazard = hazard_id if hazard_id in HAZARD_ORDER else "moonquake"
	match active_hazard:
		"moonquake":
			quake_warning_issued = true
			aftershock_warning_issued = true
			return {
				"accepted": true,
				"hazard": "moonquake",
				"chapter": 3,
				"warning": "Seismometer alert: shallow moonquake tremor detected. Secure loose equipment and check the garden air branch (82 -> 74) before the aftershock.",
			}
		"cold_shadow":
			shadow_warning_issued = true
			return {
				"accepted": true,
				"hazard": "cold_shadow",
				"chapter": 4,
				"warning": "Cold-trap boundary ahead (-210 °C): suit heaters will draw 1.8x power. Keep instruments above -65 °C and the vault carrier sealed below -10 °C.",
			}
		"impact_flashes":
			flash_warning_issued = true
			return {
				"accepted": true,
				"hazard": "impact_flashes",
				"chapter": 5,
				"warning": "Meteoroid stream watch: confirm flashes on both telescopes (6 genuine, 2 single-camera artifacts) and maintain the solar panel and Whipple bumper.",
			}
		"darkness_budget":
			darkness_warning_issued = true
			return {
				"accepted": true,
				"hazard": "darkness_budget",
				"chapter": 6,
				"warning": "Total eclipse (Red Ring) ingress approaching: allocate 7 of 14 battery units (5 essentials + 1 pump + 1 camera) so 7 units stay in reserve.",
			}
		"solar_storm":
			storm_warning_issued = true
			return {
				"accepted": true,
				"hazard": "solar_storm",
				"chapter": 7,
				"warning": "Solar proton flux rising: watch your dosimeter, reach the Safe Room (W4 + K2 = Shelter 6), and latch the founder reserve case.",
			}
	return {"accepted": false, "reason": "Unknown hazard."}

# --- 1. Moonquake (CH03) ---

func trigger_moonquake_tremor() -> Dictionary:
	if not quake_warning_issued:
		issue_warning("moonquake")
	quake_tremor_active = true
	garden_branch_pressure = 74
	return {
		"accepted": true,
		"warning_issued_first": quake_warning_issued,
		"aftershock_warning": aftershock_warning_issued,
		"unsecured_count": items_to_secure.size() - secured_items.size(),
		"pressures": {"main": main_trunk_pressure, "garden": garden_branch_pressure, "return": return_trunk_pressure},
	}

func secure_quake_item(item_id: String) -> Dictionary:
	if not items_to_secure.has(item_id):
		return {"accepted": false, "reason": "Unknown item to secure."}
	if not secured_items.has(item_id):
		secured_items.append(item_id)
	var all_secured := secured_items.size() == items_to_secure.size()
	if all_secured:
		quake_tremor_active = false
	return {
		"accepted": true,
		"secured_count": secured_items.size(),
		"total_to_secure": items_to_secure.size(),
		"all_secured": all_secured,
	}

# --- 2. Cold shadow (CH04) ---

func step_cold_shadow(in_shadow: bool, duration_min: float, rover_heater_upgrade: bool = false) -> Dictionary:
	if not shadow_warning_issued:
		issue_warning("cold_shadow")
	in_permanent_shadow = in_shadow
	ambient_temp_c = shadow_temp_c if in_shadow else -45.0
	heater_power_multiplier = (1.45 if rover_heater_upgrade else 1.8) if in_shadow else 1.0
	var heater_drop_c := (2.2 if rover_heater_upgrade else 3.5) * (duration_min / 10.0) if in_shadow else -1.5 * (duration_min / 10.0)
	equipment_temp_c = clampf(equipment_temp_c - heater_drop_c, -60.0, 15.0)
	var within_equipment_limits := equipment_temp_c >= equipment_min_limit_c
	return {
		"accepted": true,
		"warning_issued_first": shadow_warning_issued,
		"in_shadow": in_permanent_shadow,
		"ambient_temp_c": ambient_temp_c,
		"heater_power_multiplier": snappedf(heater_power_multiplier, 0.01),
		"equipment_temp_c": snappedf(equipment_temp_c, 0.1),
		"equipment_min_limit_c": equipment_min_limit_c,
		"within_equipment_limits": within_equipment_limits,
	}

# --- 3. Impact flashes & shield maintenance (CH05) ---

func evaluate_impact_observations(candidates: Array, dust_shield_upgrade: bool = false, whipple_upgrade: bool = false) -> Dictionary:
	if not flash_warning_issued:
		issue_warning("impact_flashes")
	var genuine := 0
	var artifacts := 0
	for c in candidates:
		if c is Dictionary:
			var cam_a := bool(c.get("telescope_a", false))
			var cam_b := bool(c.get("telescope_b", false))
			var persistent_pixel := bool(c.get("persistent_hot_pixel", false))
			if cam_a and cam_b and not persistent_pixel:
				genuine += 1
			else:
				artifacts += 1
	genuine_flashes_confirmed = genuine
	artifacts_rejected = artifacts
	var panel_ready := panel_dust_cleared or dust_shield_upgrade
	var shield_ready := whipple_spur_patched or whipple_upgrade
	var matches_08_witness := (genuine == 6 and artifacts == 2 and panel_ready and shield_ready)
	return {
		"accepted": matches_08_witness,
		"warning_issued_first": flash_warning_issued,
		"genuine_flashes": genuine,
		"artifacts_rejected": artifacts,
		"panel_ready": panel_ready,
		"shield_ready": shield_ready,
	}

# --- 4. Darkness energy budget (CH06) ---

func evaluate_darkness_budget(essentials: int, include_pump: bool, include_camera: bool, include_decorative_floods: bool = false) -> Dictionary:
	if not darkness_warning_issued:
		issue_warning("darkness_budget")
	var spent := essentials + (1 if include_pump else 0) + (1 if include_camera else 0) + (3 if include_decorative_floods else 0)
	var remaining := eclipse_battery_jar - spent
	var accepted := (spent == 7 and remaining == 7 and essentials == 5 and include_pump and include_camera and not include_decorative_floods)
	return {
		"accepted": accepted,
		"warning_issued_first": darkness_warning_issued,
		"battery_before": eclipse_battery_jar,
		"allocation_spent": spent,
		"reserve_remaining": remaining,
		"essentials": essentials,
		"pump": include_pump,
		"camera": include_camera,
	}

# --- 5. Solar storm dosimeter & shelter run (CH07) ---

func step_solar_storm_shelter_run(delta_sec: float, reached_shelter: bool = false, water_units: int = 4, crate_units: int = 2, dirt_shelter_bonus: int = 0) -> Dictionary:
	if not storm_warning_issued:
		issue_warning("solar_storm")
	outside_shelter = not reached_shelter
	storm_shelter_strength = mini(6, water_units + crate_units + dirt_shelter_bonus)
	if outside_shelter and delta_sec > 0.0:
		shelter_run_elapsed_s += delta_sec
		# Dose accumulates outside shelter on the dosimeter even when untimed in Family/Story mode
		accumulated_outside_dose += (delta_sec / 60.0) * dosimeter_rate_units_per_min
	var untimed := is_shelter_run_untimed()
	var time_remaining_s := shelter_run_timer_s if untimed else maxf(0.0, shelter_run_timer_s - shelter_run_elapsed_s)
	var step_dose_in_shelter := 0 if storm_shelter_strength >= 6 else (1 if storm_shelter_strength >= 4 else (2 if storm_shelter_strength >= 2 else 3))
	var total_6step_shelter_dose := 0
	for mult in storm_step_multipliers:
		total_6step_shelter_dose += step_dose_in_shelter * int(mult)
	return {
		"accepted": true,
		"warning_issued_first": storm_warning_issued,
		"outside_shelter": outside_shelter,
		"untimed_family_mode": untimed,
		"time_remaining_s": snappedf(time_remaining_s, 0.1),
		"dosimeter_rate_per_min": dosimeter_rate_units_per_min,
		"dosimeter_dose_shown": snappedf(accumulated_outside_dose, 0.01),
		"shelter_strength": storm_shelter_strength,
		"six_step_shelter_dose": total_6step_shelter_dose,
		"within_exposure_limit": total_6step_shelter_dose <= storm_exposure_limit,
	}
