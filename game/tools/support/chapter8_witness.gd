extends RefCounted

## Test fixture: the 08_PUZZLE_DESIGNS.md P-15 / P-16 accepted solution as the
## payloads a player would build in the Chapter 8 puzzle panel. Gameplay never
## calls this; it replaces the gate catalog's old pre-filled payloads for suites
## that drive the extended route without opening the panel.

const SOLUTION := {
	"p15_confirm_teams": {"rover": ["ferreira", "kai", "rafi"], "home": ["mei", "amara"]},
	"p15_confirm_loadout": {"packed": ["controller", "battery_spare", "service_diagram", "repeater_checkpoints"]},
	"p15_confirm_roundtrip_provisions": {"hours": 72},
	"p15_choose_surveyed_route": {"route": "SURVEYED", "reserve": 4},
	"p15_confirm_return_reserve": {"reserve": 4, "energy": 14, "allowance": 5},
	"p15_reach_marker_two": {"bearing": 177.0},
	"p15_set_brake": {"action": "brake_on_pad"},
	"p15_save_position_packet": {"packet": "current"},
	"p15_restore_marker_2": {"sequence": ["isolate", "remove_battery", "compare_spec", "install_spare", "close_housing", "reconnect"]},
	"p15_test_repeater_chain": {"tested": ["1-2", "2-3"]},
	"p15_reach_approach": {},
	"p15_confirm_home_occupancy": {"segments": [[2, 33], [5, 3]]},
	"p15_confirm_segment_forecast": {"heat": "COOL", "light": "DIM", "water_return": "OPEN", "air_total": 2.8125},
	"p15_confirm_home_pressure": {"gauge": "independent"},
	"p15_confirm_home_checks": {"sequence": ["air", "temperature", "return_path", "acknowledge"]},
	"p15_confirm_summit": {"packet": "summit"},
	"p15_receive_summit_packet": {"packet": "current"},
	"p16_isolate_power": {"step": "isolate"},
	"p16_zero_test": {"reading": 0},
	"p16_install_controller": {"controller": "december_spare"},
	"p16_close_housing": {"housing": "closed"},
	"p16_restore_power": {"step": "reconnect"},
	"p16_local_bearing": {"bearing": "L2"},
	"p16_earth_bearing": {"bearing": "E3"},
	"p16_stable_lock": {"lock": "stable", "method": "tap"},
	"p16_checksum": {"value": "ALO42", "packet": "current"},
	"p16_confirm_path_records": {"records": ["local", "earth"]},
	"p16_voice_verification_ready": {"plan": "explicit"},
	"p16_noor_live_voice": {"voice_checks": ["Aurora", "Earth"]},
	"p16_confirm_telemetry": {"report": "both_teams"},
	"p16_start_return": {"departure": "2047-04-09 03:00 UTC"},
	"p16_confirm_return_24h": {"gates": ["gate3_return", "gate2_return", "gate1_return"]},
	"p16_confirm_five_at_aurora": {"arrivals": ["ferreira", "kai", "rafi", "pressure_procedure"]},
	"p16_update_occupancy": {"occupancy_change": "arrival"},
	"p16_save_final_records": {"checks": ["crew", "seeds", "pressure", "temperature", "cotton"]},
	"p16_save_photo": {"frame": "window"},
	"p16_save_dedication": {"dedication": "For every hand that kept the light"},
	"p16_make_credits_available": {},
}

## The witness payload for one operation, merged over `base`. With a director
## snapshot, the reserve arithmetic follows the actual rover battery (the earned
## long-range battery adds 4 once), so every upgrade path stays a witness.
static func payload(target_id: String, state: Dictionary = {}, base: Dictionary = {}) -> Dictionary:
	var result: Dictionary = base.duplicate(true)
	for key in SOLUTION.get(target_id, {}):
		var value = SOLUTION[target_id][key]
		result[key] = value.duplicate(true) if value is Array or value is Dictionary else value
	if not state.is_empty() and state.get("route", {}) is Dictionary and target_id in ["p15_choose_surveyed_route", "p15_confirm_return_reserve"]:
		var route: Dictionary = state.route
		var energy := float(route.get("capacity", route.get("energy", 14)))
		var allowance := float(route.get("allowance", 5))
		result["reserve"] = energy - 2.0 * allowance
		if target_id == "p15_confirm_return_reserve":
			result["energy"] = energy
			result["allowance"] = allowance
	return result

static func is_witnessed(target_id: String) -> bool:
	return SOLUTION.has(target_id)
