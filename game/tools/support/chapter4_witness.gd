extends RefCounted

## Test fixture: the 08_PUZZLE_DESIGNS.md P-07 / P-08 accepted solution as the
## payloads a player would build in the Chapter 4 puzzle panel. Gameplay never
## calls this; it replaces the gate catalog's old pre-filled payloads for suites
## that drive the extended route without opening the panel.

const SOLUTION := {
	"p07_compare_prediction": {},
	"p07_inspect_twelve_descendants": {},
	"p07_record_trait_limits": {},
	"p07_check_rover_seal": {},
	"p07_check_scanner": {},
	"p07_check_closed_carrier": {},
	"p07_complete_base_handover": {},
	"p07_choose_route_b": {"route": "B"},
	"p07_verify_slope": {"slope": 12},
	"p07_verify_return_reserve": {"reserve": 40},
	"p07_prepare_departure": {},
	"p07_place_beacon_1": {},
	"p07_place_beacon_2": {},
	"p07_place_beacon_3": {},
	"p07_record_dry_reference": {},
	"p07_set_threshold_12": {"reference": 2, "threshold": 12},
	"p07_tag_positive_18": {"reading": 18},
	"p07_tag_positive_19": {"reading": 19},
	"p07_retain_negative_2": {"reading": 2},
	"p07_seal_sample": {},
	"p07_commit_return_route": {},
	"p08_read_external_probe": {},
	"p08_fit_sleeve": {},
	"p08_latch_cradle": {},
	"p08_secure_mount": {},
	"p08_return_to_base": {},
	"p08_dock_dry_glovebox": {},
	"p08_warm_cold": {"stage": "cool"},
	"p08_warm_cool": {},
	"p08_warm_room": {"stage": "room"},
	"p08_check_condensation": {},
	"p08_open_inner_seal": {},
	"p08_inventory_12": {"count": 12},
	"p08_scan_lid": {},
	"p08_save_viability_pending": {},
	"p08_transfer_case": {},
	"p08_manifest_reconciled": {},
	"p08_personnel_home": {},
	"p08_quarantine_complete": {},
	"p08_send_manifest": {},
	"p08_record_ferreira_question": {},
	"p08_leave_identity_open": {},
	"p08_check_relief_flight": {},
	"p08_prepare_locker": {},
	"p08_confirm_december_transition": {},
}

static func payload(target_id: String, _state: Dictionary = {}, base: Dictionary = {}) -> Dictionary:
	var result: Dictionary = base.duplicate(true)
	for key in SOLUTION.get(target_id, {}):
		var value = SOLUTION[target_id][key]
		result[key] = value.duplicate(true) if value is Array or value is Dictionary else value
	return result

static func is_witnessed(target_id: String) -> bool:
	return SOLUTION.has(target_id)
