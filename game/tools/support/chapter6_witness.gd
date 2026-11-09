extends RefCounted

## Test fixture: the 08_PUZZLE_DESIGNS.md P-11 / P-12 accepted solution as the
## payloads a player would build in the Chapter 6 puzzle panel. Gameplay never
## calls this; it replaces the gate catalog's old pre-filled payloads for suites
## that drive the extended route without opening the panel.

const SOLUTION := {
	"p11_charge_hand_light": {},
	"p11_assign_companion": {},
	"p11_check_locker": {},
	"p11_read_personal_log": {},
	"p11_identify_protected_path": {},
	"p11_identify_fault_method": {},
	"p11_commit_allocation": {"total": 7, "essentials": true, "pump": true, "camera": true, "floods": 0},
	"p11_remove_decorative_floods": {},
	"p11_protect_guide_light": {},
	"p11_protect_reserve": {},
	"p12_test_branch": {},
	"p12_verify_protected_services": {},
	"p12_record_rehearsal": {},
	"p12_check_four_roles": {},
	"p12_check_five_segments": {},
	"p12_ready_camera": {},
	"p12_log_ingress": {},
	"p12_log_ring": {},
	"p12_deliver_family_contact": {},
	"p12_preserve_observation_qualifications": {},
	"p12_store_known_noor_text": {},
	"p12_reserve_live_voice": {},
	"p12_reset_sequence": {"sequence": ["isolate", "zero", "reset", "reconnect", "camera_test"]},
	"p12_record_egress": {},
	"p12_reconcile_recovery_reserve": {},
	"p12_save_recovery": {},
	"p12_reconcile_monitoring": {},
	"p12_date_february_warning": {},
	"p12_confirm_care_ledger": {},
}

static func payload(target_id: String, _state: Dictionary = {}, base: Dictionary = {}) -> Dictionary:
	var result: Dictionary = base.duplicate(true)
	for key in SOLUTION.get(target_id, {}):
		var value = SOLUTION[target_id][key]
		result[key] = value.duplicate(true) if value is Array or value is Dictionary else value
	return result

static func is_witnessed(target_id: String) -> bool:
	return SOLUTION.has(target_id)
