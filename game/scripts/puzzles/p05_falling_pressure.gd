extends RefCounted
class_name P05FallingPressure

## Interactive state and validation model for P-05 Find the Falling Pressure
## (Chapter 3, EX-M0301 and EX-M0302, scenes EX-CH03-S01 through EX-CH03-S06).
##
## Rules, expected gauge readings, candidate inspections, role cards, wrong-choice
## diagnostics, and progressive hints are loaded from
## res://resources/campaign/content/p05_falling_pressure.json.

const DATA_PATH := "res://resources/campaign/content/p05_falling_pressure.json"
const TAP_IDS := ["MAIN", "GARDEN", "RETURN"]
const GATES := [
	"p05_equip_gauge",
	"p05_read_panel_warning",
	"p05_identify_three_taps",
	"p05_read_main_t0",
	"p05_read_garden_t0",
	"p05_read_return_t0",
	"p05_inspect_tank",
	"p05_inspect_habitat",
	"p05_inspect_garden",
	"p05_inspect_return",
	"p05_inspect_airlock",
	"p05_inspect_annex",
	"p05_read_main_t10",
	"p05_read_garden_t10",
	"p05_read_return_t10",
	"p05_identify_garden_fall",
	"p05_verify_annex_isolation",
	"p05_preview_garden_isolation",
	"p05_rollback_check",
	"p05_isolate_garden",
	"p05_verify_main_hold",
	"p05_apply_garden_clamp",
	"p05_reopen_garden_slow",
	"p05_stable_read_1",
	"p05_stable_read_2",
	"p05_stable_read_3",
	"p05_stable_read_4",
	"p05_stable_read_5",
	"p05_reconcile_records",
	"p05_save_monitoring_handover",
	"p05_isolate_annex_feed",
	"p05_confirm_zero_differential",
	"p05_inspect_annex_hatch",
]

static var _data_cache: Dictionary = {}

var _gauge_equipped := false
var _warning_read := false
var _taps_identified := false
var _prediction := ""
var _t0_readings := {}
var _t10_readings := {}
var _current_phase := 1
var _phase_inspections := {1: [], 2: [], 3: [], 4: []}
var _inspected_candidates: Array[String] = []
var _aftershock_triggered := false
var _annex_auto_isolated := false
var _garden_fall_identified := false
var _trade_choice := ""
var _go_no_go := {}
var _rollback_checked := false
var _garden_isolated := false
var _main_hold_verified := false
var _clamp_seated := false
var _garden_reopened_slow := false
var _stable_readings := {}
var _note_reconciled := false
var _handover_saved := false
var _annex_feed_isolated := false
var _zero_diff_confirmed := false
var _annex_hatch_inspected := false
var _shared_roles := {}
var _hint_count := 0
var _guided_intro_seen := false
var _explainer_watched := false
var _last_feedback := {}

func _init() -> void:
	reset()

## Loads and caches the canonical P-05 data definition from JSON.
static func data() -> Dictionary:
	if _data_cache.is_empty():
		var file := FileAccess.open(DATA_PATH, FileAccess.READ)
		var parsed = JSON.parse_string(file.get_as_text()) if file != null else {}
		_data_cache = parsed if parsed is Dictionary else {}
	return _data_cache

## Returns true if the target_id is a P-05 puzzle gate.
static func is_gate(target_id: String) -> bool:
	return GATES.has(target_id)

## Expected payload dictionary for a given action from the JSON data file.
static func expected_payload(action: String) -> Dictionary:
	return data().get("expected_actions", {}).get(action, {}).duplicate(true)

## Resets all interactive P-05 choices back to the unstarted state.
func reset() -> void:
	_gauge_equipped = false
	_warning_read = false
	_taps_identified = false
	_prediction = ""
	_t0_readings = {}
	_t10_readings = {}
	_current_phase = 1
	_phase_inspections = {1: [], 2: [], 3: [], 4: []}
	_inspected_candidates.clear()
	_aftershock_triggered = false
	_annex_auto_isolated = false
	_garden_fall_identified = false
	_trade_choice = ""
	_go_no_go = {}
	_rollback_checked = false
	_garden_isolated = false
	_main_hold_verified = false
	_clamp_seated = false
	_garden_reopened_slow = false
	_stable_readings = {}
	_note_reconciled = false
	_handover_saved = false
	_annex_feed_isolated = false
	_zero_diff_confirmed = false
	_annex_hatch_inspected = false
	_shared_roles = {}
	_hint_count = 0
	_guided_intro_seen = false
	_explainer_watched = false
	_last_feedback = {}

## Marks the first-time guided introduction card as read.
func acknowledge_guided_intro() -> Dictionary:
	_guided_intro_seen = true
	return {"accepted": true, "guided_intro_seen": true}

## Marks the short explainer clip as watched.
func watch_explainer() -> Dictionary:
	_explainer_watched = true
	return {"accepted": true, "explainer_watched": true, "clip": data().get("guided_intro", {}).get("explainer_clip", {}).duplicate(true)}

## Shares a crew member's role card in Class or Solo mode.
func share(role_id: String, scene_id: String = "EX-CH03-S01") -> Dictionary:
	for card in data().get("role_cards", []):
		if String(card.get("role_id", "")) == role_id:
			if not _card_arrived(String(card.get("arrives_scene", "EX-CH03-S01")), scene_id):
				return {"accepted": false, "reason": "%s's clue card has not arrived yet." % String(card.get("name", role_id))}
			var already := bool(_shared_roles.get(role_id, false))
			_shared_roles[role_id] = true
			return {"accepted": true, "duplicate": already, "role_id": role_id}
	return {"accepted": false, "reason": "Unknown crew role card: " + role_id}

## Returns the crew role cards with arrival and shared status for the given scene.
func role_cards(scene_id: String = "EX-CH03-S02") -> Array:
	var cards: Array = []
	for raw in data().get("role_cards", []):
		var card: Dictionary = raw.duplicate(true)
		var role_id := String(card.get("role_id", ""))
		var arrived := _card_arrived(String(card.get("arrives_scene", "EX-CH03-S01")), scene_id)
		card["arrived"] = arrived
		card["shared"] = bool(_shared_roles.get(role_id, false))
		if not arrived:
			card["facts"] = []
			card["quote"] = ""
		cards.append(card)
	return cards

## Records the player's Predict -> Act -> See hypothesis before reading t10 taps.
func set_prediction(branch_id: String) -> Dictionary:
	for option in data().get("prediction", {}).get("options", []):
		if String(option.get("id", "")) == branch_id:
			_prediction = branch_id
			var resp := String(option.get("response", "Prediction logged."))
			_last_feedback = {"kind": "prediction", "badge": "PREDICTION LOGGED", "message": resp}
			return {"accepted": true, "prediction": _prediction, "message": resp}
	return {"accepted": false, "reason": "Choose MAIN, GARDEN, or RETURN for your prediction."}

## Equips the independent mechanical gauge TL_PressureGauge.
func equip_gauge() -> Dictionary:
	_gauge_equipped = true
	return {"accepted": true, "gauge_equipped": true}

## Reads the noisy manifold warning on the life-support panel.
func read_panel_warning() -> Dictionary:
	_warning_read = true
	return {"accepted": true, "warning_read": true}

## Identifies the three manual test taps (MAIN, GARDEN, RETURN).
func identify_three_taps() -> Dictionary:
	if not _gauge_equipped:
		return {"accepted": false, "reason": "Equip the independent mechanical gauge first."}
	_taps_identified = true
	return {"accepted": true, "taps_identified": true, "taps": TAP_IDS.duplicate()}

## Attaches the mechanical gauge to a tap at t0 or t10 and records its physical reading.
func attach_gauge(tap_id: String, window: String) -> Dictionary:
	if not _gauge_equipped:
		return {"accepted": false, "reason": "Equip the mechanical gauge before reading a tap."}
	var taps: Dictionary = data().get("taps", {})
	if not taps.has(tap_id):
		return {"accepted": false, "reason": "Unknown test tap: " + tap_id}
	if window not in ["t0", "t10"]:
		return {"accepted": false, "reason": "Gauge window must be t0 or t10."}
	if window == "t10" and _t0_readings.size() < 3:
		return {"accepted": false, "reason": "Record all three baseline (t0) tap readings before taking the 10-second (t10) comparison."}
	var reading := int(taps[tap_id].get(window, 0))
	if window == "t0":
		_t0_readings[tap_id] = reading
	else:
		_t10_readings[tap_id] = reading
	_last_feedback = {
		"kind": "gauge",
		"badge": "%s · %s" % [tap_id, window.to_upper()],
		"message": "%s reads %d relative test units at %s." % [String(taps[tap_id].get("label", tap_id)), reading, window],
	}
	return {"accepted": true, "tap_id": tap_id, "window": window, "reading": reading}

## Sets an explicit tap reading (allows tests or manual entry to test wrong values).
func set_tap_reading(tap_id: String, window: String, reading: int) -> Dictionary:
	if not TAP_IDS.has(tap_id) or window not in ["t0", "t10"]:
		return {"accepted": false, "reason": "Invalid tap or time window."}
	if window == "t0":
		_t0_readings[tap_id] = reading
	else:
		_t10_readings[tap_id] = reading
	var expected := int(data().get("taps", {}).get(tap_id, {}).get(window, -1))
	if reading != expected:
		var msg := "Manual gauge needle on %s at %s points to %d, not %d. Match the physical needle." % [tap_id, window, expected, reading]
		_last_feedback = {"kind": "warning", "badge": "CHECK NEEDLE READING", "message": msg}
		return {"accepted": false, "reason": msg, "reading": reading, "expected": expected}
	return {"accepted": true, "tap_id": tap_id, "window": window, "reading": reading}

## Inspects one of the 6 candidate locations, enforcing at most 2 inspections per phase.
func inspect_candidate(candidate_id: String) -> Dictionary:
	var candidate_spec := _candidate_by_id(candidate_id)
	if candidate_spec.is_empty():
		return {"accepted": false, "reason": "Unknown candidate location: " + candidate_id}
	if _inspected_candidates.has(candidate_id):
		return {"accepted": true, "duplicate": true, "candidate_id": candidate_id, "phase": _current_phase, "summary": String(candidate_spec.get("summary", ""))}
	var max_per_phase := int(data().get("max_inspections_per_phase", 2))
	var current_list: Array = _phase_inspections.get(_current_phase, [])
	if current_list.size() >= max_per_phase:
		var msg := "Phase %d already used its %d candidate inspections. Advance to the next investigation phase before inspecting another location." % [_current_phase, max_per_phase]
		_last_feedback = {"kind": "budget", "badge": "PHASE INSPECTION LIMIT (2/2)", "message": msg}
		return {"accepted": false, "reason": msg, "phase": _current_phase}
	current_list.append(candidate_id)
	_phase_inspections[_current_phase] = current_list
	_inspected_candidates.append(candidate_id)
	if _current_phase >= 2 or _inspected_candidates.size() >= 2:
		_aftershock_triggered = true
	_last_feedback = {
		"kind": "inspection",
		"badge": "INSPECTED · PHASE %d (%d/%d)" % [_current_phase, current_list.size(), max_per_phase],
		"message": String(candidate_spec.get("summary", "")),
	}
	return {
		"accepted": true,
		"candidate_id": candidate_id,
		"phase": _current_phase,
		"inspections_in_phase": current_list.size(),
		"aftershock_triggered": _aftershock_triggered,
		"summary": String(candidate_spec.get("summary", "")),
	}

## Advances the diagnostic phase counter (1..4) and triggers the phase-2 aftershock.
func advance_phase() -> Dictionary:
	var max_phases := int(data().get("investigation_phases", 4))
	if _current_phase >= max_phases:
		return {"accepted": false, "reason": "Already at final investigation phase (%d)." % max_phases}
	_current_phase += 1
	if _current_phase >= 2:
		_aftershock_triggered = true
	return {"accepted": true, "phase": _current_phase, "aftershock_triggered": _aftershock_triggered}

## Deduces which branch is falling after comparing t0 and t10 readings.
func identify_falling_branch(branch_id: String = "GARDEN") -> Dictionary:
	if int(_t0_readings.get("GARDEN", -1)) != 82 or int(_t10_readings.get("GARDEN", -1)) != 74:
		return {"accepted": false, "reason": "Record the GARDEN t0 (82) and t10 (74) readings before locking your deduction."}
	if branch_id != "GARDEN":
		var msg := "%s held steady at 100 → 100. Compare the manual GARDEN reading (82 → 74)." % branch_id
		_last_feedback = {"kind": "warning", "badge": "BRANCH STEADY", "message": msg}
		return {"accepted": false, "reason": msg}
	_garden_fall_identified = true
	_last_feedback = {
		"kind": "deduction",
		"badge": "FAULT ISOLATED · GARDEN 82 → 74",
		"message": "Garden branch falls from 82 to 74 while MAIN and RETURN hold 100.",
	}
	return {"accepted": true, "branch_id": "GARDEN"}

## Verifies that the annex branch automatic isolation held after the phase-2 aftershock.
func verify_annex_isolation() -> Dictionary:
	_aftershock_triggered = true
	_annex_auto_isolated = true
	_last_feedback = {
		"kind": "twist",
		"badge": "ANNEX AUTO-ISOLATION VERIFIED",
		"message": "Phase-2 aftershock tripped the annex indicator; automatic isolation valve held tight.",
	}
	return {"accepted": true, "annex_auto_isolated": true}

## Selects an option in the S03 trade study (or previews a wrong choice).
func select_trade_option(option_id: String) -> Dictionary:
	if option_id == "isolate_habitat_trunk":
		return preview_wrong_action("isolate_habitat_trunk")
	if option_id == "close_main_valve":
		return preview_wrong_action("close_main_valve")
	if option_id != "isolate_garden":
		return {"accepted": false, "reason": "Unknown trade-study option: " + option_id}
	_trade_choice = "isolate_garden"
	_last_feedback = {
		"kind": "preview",
		"badge": "PREVIEW · ISOLATE GARDEN ONLY",
		"message": "Isolating GARDEN stops the 82 → 74 drop before phase 4 while keeping MAIN (100) and habitat breathing air online.",
	}
	return {"accepted": true, "trade_choice": _trade_choice}

## Marks a station GO in the Go/No-Go poll (or all stations if "all").
func poll_station(station_id: String = "all") -> Dictionary:
	var valid_ids: Array[String] = []
	for station in data().get("go_no_go_poll", {}).get("stations", []):
		valid_ids.append(String(station.get("id", "")))
	if station_id == "all":
		for id in valid_ids:
			_go_no_go[id] = true
		_rollback_checked = true
		return {"accepted": true, "go_no_go": _go_no_go.duplicate(true)}
	if not valid_ids.has(station_id):
		return {"accepted": false, "reason": "Unknown poll station: " + station_id}
	_go_no_go[station_id] = true
	if _go_no_go.size() == valid_ids.size():
		_rollback_checked = true
	return {"accepted": true, "station_id": station_id, "all_go": _go_no_go.size() == valid_ids.size()}

## Isolates the GARDEN branch valve (or rejects closing MAIN / habitat trunk).
func isolate_branch(branch_id: String = "GARDEN") -> Dictionary:
	if branch_id == "MAIN":
		return preview_wrong_action("close_main_valve")
	if branch_id == "HABITAT" or branch_id == "habitat_trunk":
		return preview_wrong_action("isolate_habitat_trunk")
	if branch_id != "GARDEN":
		return {"accepted": false, "reason": "Only the leaking GARDEN branch should be isolated."}
	_garden_isolated = true
	_last_feedback = {
		"kind": "action",
		"badge": "GARDEN VALVE CLOSED",
		"message": "GARDEN branch isolated. Verify MAIN holds 100 and isolated GARDEN holds 74 before clamping.",
	}
	return {"accepted": true, "garden_isolated": true}

## Verifies that MAIN holds 100 and isolated GARDEN holds 74 before seating the clamp.
func verify_main_hold() -> Dictionary:
	if not _garden_isolated:
		return {"accepted": false, "reason": "Close the GARDEN isolation valve before verifying pressure hold."}
	_main_hold_verified = true
	_last_feedback = {
		"kind": "verify",
		"badge": "HOLD VERIFIED · MAIN 100 / GARDEN 74",
		"message": "MAIN holds steady at 100 and isolated GARDEN holds at 74. Safe to seat the collar clamp.",
	}
	return {"accepted": true, "main_hold_verified": true, "main": 100, "garden": 74}

## Seats the repair clamp PR_RepairClamp on the garden feedthrough collar.
func seat_repair_clamp(branch_id: String = "GARDEN") -> Dictionary:
	if branch_id != "GARDEN":
		return preview_wrong_action("clamp_wrong_branch")
	if not _garden_isolated:
		return preview_wrong_action("clamp_before_isolation")
	_clamp_seated = true
	_last_feedback = {
		"kind": "action",
		"badge": "CLAMP SEATED · PR_RepairClamp",
		"message": "Repair clamp seated on the garden bulkhead feedthrough collar from the safe side.",
	}
	return {"accepted": true, "clamp_seated": true}

## Reopens the GARDEN valve slowly after clamping and verifying annex isolation.
func reopen_garden(slow: bool = true) -> Dictionary:
	if not slow:
		return preview_wrong_action("fast_reopen_garden")
	if not _clamp_seated:
		return {"accepted": false, "reason": "Seat the repair clamp on the garden feedthrough before reopening the valve."}
	if not _annex_auto_isolated:
		return {"accepted": false, "reason": "Verify annex automatic isolation before reopening the garden branch."}
	_garden_reopened_slow = true
	_last_feedback = {
		"kind": "action",
		"badge": "GARDEN SLOW-REOPENED",
		"message": "GARDEN valve reopened slowly. Record five consecutive 2-second gauge checks at 100/100/100.",
	}
	return {"accepted": true, "garden_reopened_slow": true}

## Records one of the 5 post-repair steady readings (1..5).
func record_stable_reading(step_index: int, main_val: int = 100, garden_val: int = 100, return_val: int = 100) -> Dictionary:
	if step_index < 1 or step_index > 5:
		return {"accepted": false, "reason": "Stable reading step must be between 1 and 5."}
	if not _garden_reopened_slow:
		return {"accepted": false, "reason": "Isolate, clamp, and slowly reopen GARDEN before logging post-repair stability checks."}
	for prev in range(1, step_index):
		if not _stable_readings.has(prev):
			return {"accepted": false, "reason": "Record steady check %d before check %d." % [prev, step_index]}
	var reading := {"main": main_val, "garden": garden_val, "return": return_val}
	_stable_readings[step_index] = reading
	if main_val != 100 or garden_val != 100 or return_val != 100:
		var msg := "Post-repair check %d must hold 100/100/100 across MAIN, GARDEN, and RETURN." % step_index
		_last_feedback = {"kind": "warning", "badge": "UNSTEADY READING", "message": msg}
		return {"accepted": false, "reason": msg, "reading": reading}
	_last_feedback = {
		"kind": "stable",
		"badge": "STEADY CHECK %d/5 · 100 / 100 / 100" % step_index,
		"message": "Check %d (%ds): MAIN 100, GARDEN 100, RETURN 100." % [step_index, step_index * 2],
	}
	return {"accepted": true, "step": step_index, "reading": reading}

## Reconciles the mismatched copied paper note in S05 ("fix_note" vs "change_valve").
func reconcile_paper_note(decision: String = "fix_note") -> Dictionary:
	if decision == "change_valve":
		return preview_wrong_action("change_valve_to_match_bad_note")
	if decision != "fix_note":
		return {"accepted": false, "reason": "Choose whether to correct the copied paper note or alter the tested valve."}
	_note_reconciled = true
	_handover_saved = true
	_last_feedback = {
		"kind": "reconcile",
		"badge": "NOTE CORRECTED TO MATCH VALVE",
		"message": "Corrected the copied paper note to match the tested valve and saved the monitoring handover.",
	}
	return {"accepted": true, "note_reconciled": true, "handover_saved": true}

## Prepares and inspects the N.R. annex hatch in S06 ("isolate_feed", "confirm_zero_diff", "camera_inspect").
func configure_annex_hatch(step_id: String) -> Dictionary:
	match step_id:
		"open_unverified":
			return preview_wrong_action("open_annex_hatch_unverified")
		"isolate_feed":
			_annex_feed_isolated = true
			return {"accepted": true, "annex_feed_isolated": true}
		"confirm_zero_diff":
			if not _annex_feed_isolated:
				return {"accepted": false, "reason": "Isolate the annex feed before confirming zero differential."}
			_zero_diff_confirmed = true
			return {"accepted": true, "zero_diff_confirmed": true}
		"camera_inspect":
			if not _zero_diff_confirmed:
				return {"accepted": false, "reason": "Confirm zero pressure differential before inspecting the N.R. hatch."}
			_annex_hatch_inspected = true
			return {"accepted": true, "annex_hatch_inspected": true}
	return {"accepted": false, "reason": "Unknown annex hatch step: " + step_id}

## Returns non-punishing diagnostic feedback for a wrong-but-reasonable action.
func preview_wrong_action(wrong_id: String) -> Dictionary:
	var spec: Dictionary = data().get("wrong_actions", {}).get(wrong_id, {})
	if spec.is_empty():
		return {"accepted": false, "reason": "Unknown diagnostic check: " + wrong_id}
	var feedback := String(spec.get("feedback", ""))
	var badge := String(spec.get("badge", "DIAGNOSTIC WARNING"))
	_last_feedback = {"kind": "wrong_reasonable", "id": wrong_id, "badge": badge, "message": feedback}
	return {
		"accepted": false,
		"non_punishing": true,
		"wrong_id": wrong_id,
		"badge": badge,
		"reason": feedback,
	}

## Applies the complete canonical witness state (used by H3 worked mode and route witness tests).
func apply_witness_solution() -> void:
	_gauge_equipped = true
	_warning_read = true
	_taps_identified = true
	_prediction = "GARDEN"
	_t0_readings = {"MAIN": 100, "GARDEN": 82, "RETURN": 100}
	_t10_readings = {"MAIN": 100, "GARDEN": 74, "RETURN": 100}
	_current_phase = 4
	_phase_inspections = {
		1: ["main_tank", "habitat_trunk"],
		2: ["garden_feedthrough", "return_line"],
		3: ["airlock_seal", "annex_branch"],
		4: [],
	}
	_inspected_candidates = ["main_tank", "habitat_trunk", "garden_feedthrough", "return_line", "airlock_seal", "annex_branch"]
	_aftershock_triggered = true
	_annex_auto_isolated = true
	_garden_fall_identified = true
	_trade_choice = "isolate_garden"
	_go_no_go = {"life_support": true, "power": true, "garden": true, "safety": true}
	_rollback_checked = true
	_garden_isolated = true
	_main_hold_verified = true
	_clamp_seated = true
	_garden_reopened_slow = true
	for i in range(1, 6):
		_stable_readings[i] = {"main": 100, "garden": 100, "return": 100}
	_note_reconciled = true
	_handover_saved = true
	_annex_feed_isolated = true
	_zero_diff_confirmed = true
	_annex_hatch_inspected = true
	for role_id in ["amara", "kai", "mei", "rafi"]:
		_shared_roles[role_id] = true

## Returns the player-constructed payload for a given P-05 gate action, or {} if not yet decided.
func payload_for_action(action: String) -> Dictionary:
	match action:
		"p05_read_main_t0":
			return {"reading": int(_t0_readings["MAIN"])} if _t0_readings.has("MAIN") else {}
		"p05_read_garden_t0":
			return {"reading": int(_t0_readings["GARDEN"])} if _t0_readings.has("GARDEN") else {}
		"p05_read_return_t0":
			return {"reading": int(_t0_readings["RETURN"])} if _t0_readings.has("RETURN") else {}
		"p05_read_main_t10":
			return {"reading": int(_t10_readings["MAIN"])} if _t10_readings.has("MAIN") else {}
		"p05_read_garden_t10":
			return {"reading": int(_t10_readings["GARDEN"])} if _t10_readings.has("GARDEN") else {}
		"p05_read_return_t10":
			return {"reading": int(_t10_readings["RETURN"])} if _t10_readings.has("RETURN") else {}
		"p05_stable_read_1", "p05_stable_read_2", "p05_stable_read_3", "p05_stable_read_4", "p05_stable_read_5":
			var step := int(action.trim_prefix("p05_stable_read_"))
			return _stable_readings[step].duplicate(true) if _stable_readings.has(step) else {}
	return {}

## Returns a plain-language reason if the player has not yet configured the required input for target_id.
func commit_block_reason(target_id: String) -> String:
	match target_id:
		"p05_read_main_t0":
			return "" if _t0_readings.has("MAIN") else "Attach the mechanical gauge to MAIN at t0 to read the needle first."
		"p05_read_garden_t0":
			return "" if _t0_readings.has("GARDEN") else "Attach the mechanical gauge to GARDEN at t0 to read the needle first."
		"p05_read_return_t0":
			return "" if _t0_readings.has("RETURN") else "Attach the mechanical gauge to RETURN at t0 to read the needle first."
		"p05_read_main_t10":
			return "" if _t10_readings.has("MAIN") else "Attach the mechanical gauge to MAIN at t10 after the 10-second hold."
		"p05_read_garden_t10":
			return "" if _t10_readings.has("GARDEN") else "Attach the mechanical gauge to GARDEN at t10 to compare the falling needle."
		"p05_read_return_t10":
			return "" if _t10_readings.has("RETURN") else "Attach the mechanical gauge to RETURN at t10 after the 10-second hold."
		"p05_stable_read_1", "p05_stable_read_2", "p05_stable_read_3", "p05_stable_read_4", "p05_stable_read_5":
			var step := int(target_id.trim_prefix("p05_stable_read_"))
			return "" if _stable_readings.has(step) else "Log post-repair steady gauge check %d/5 (100/100/100) in the panel first." % step
	return ""

## Automatically prepares the current action in the model when the player clicks Try It / Lock In on a step gate.
func prepare_gate_from_panel(target_id: String) -> Dictionary:
	match target_id:
		"p05_equip_gauge":
			return equip_gauge()
		"p05_read_panel_warning":
			return read_panel_warning()
		"p05_identify_three_taps":
			equip_gauge()
			return identify_three_taps()
		"p05_read_main_t0":
			equip_gauge()
			return attach_gauge("MAIN", "t0")
		"p05_read_garden_t0":
			equip_gauge()
			return attach_gauge("GARDEN", "t0")
		"p05_read_return_t0":
			equip_gauge()
			return attach_gauge("RETURN", "t0")
		"p05_inspect_tank", "p05_inspect_habitat", "p05_inspect_garden", "p05_inspect_return", "p05_inspect_airlock", "p05_inspect_annex":
			var cid := _candidate_id_for_action(target_id)
			if not _inspected_candidates.has(cid):
				var cur: Array = _phase_inspections.get(_current_phase, [])
				if cur.size() >= int(data().get("max_inspections_per_phase", 2)) and _current_phase < 4:
					advance_phase()
			return inspect_candidate(cid)
		"p05_read_main_t10":
			equip_gauge()
			for tap in TAP_IDS:
				if not _t0_readings.has(tap):
					attach_gauge(tap, "t0")
			return attach_gauge("MAIN", "t10")
		"p05_read_garden_t10":
			equip_gauge()
			for tap in TAP_IDS:
				if not _t0_readings.has(tap):
					attach_gauge(tap, "t0")
			return attach_gauge("GARDEN", "t10")
		"p05_read_return_t10":
			equip_gauge()
			for tap in TAP_IDS:
				if not _t0_readings.has(tap):
					attach_gauge(tap, "t0")
			return attach_gauge("RETURN", "t10")
		"p05_identify_garden_fall":
			return identify_falling_branch("GARDEN")
		"p05_verify_annex_isolation":
			return verify_annex_isolation()
		"p05_preview_garden_isolation":
			return select_trade_option("isolate_garden")
		"p05_rollback_check":
			return poll_station("all")
		"p05_isolate_garden":
			return isolate_branch("GARDEN")
		"p05_verify_main_hold":
			if not _garden_isolated:
				isolate_branch("GARDEN")
			return verify_main_hold()
		"p05_apply_garden_clamp":
			if not _garden_isolated:
				isolate_branch("GARDEN")
			return seat_repair_clamp("GARDEN")
		"p05_reopen_garden_slow":
			if not _annex_auto_isolated:
				verify_annex_isolation()
			if not _garden_isolated:
				isolate_branch("GARDEN")
			if not _clamp_seated:
				seat_repair_clamp("GARDEN")
			return reopen_garden(true)
		"p05_stable_read_1", "p05_stable_read_2", "p05_stable_read_3", "p05_stable_read_4", "p05_stable_read_5":
			if not _garden_reopened_slow:
				prepare_gate_from_panel("p05_reopen_garden_slow")
			var step := int(target_id.trim_prefix("p05_stable_read_"))
			for s in range(1, step):
				if not _stable_readings.has(s):
					record_stable_reading(s, 100, 100, 100)
			return record_stable_reading(step, 100, 100, 100)
		"p05_reconcile_records", "p05_save_monitoring_handover":
			return reconcile_paper_note("fix_note")
		"p05_isolate_annex_feed":
			return configure_annex_hatch("isolate_feed")
		"p05_confirm_zero_differential":
			configure_annex_hatch("isolate_feed")
			return configure_annex_hatch("confirm_zero_diff")
		"p05_inspect_annex_hatch":
			configure_annex_hatch("isolate_feed")
			configure_annex_hatch("confirm_zero_diff")
			return configure_annex_hatch("camera_inspect")
	return {"accepted": true}

## Reveals the next progressive hint (H1 -> H2 -> H3). H3 unlocks the guided witness setup.
func next_hint() -> Dictionary:
	var hints: Array = data().get("hints", [])
	if _hint_count >= hints.size():
		return {"accepted": false, "reason": "All three progressive hints are already open."}
	var text := String(hints[_hint_count])
	_hint_count += 1
	return {
		"accepted": true,
		"level": "H%d" % _hint_count,
		"text": text,
		"hints": revealed_hints(),
	}

## Returns all progressive hints revealed so far.
func revealed_hints() -> Array:
	var hints: Array = data().get("hints", [])
	var out: Array = []
	for i in range(mini(_hint_count, hints.size())):
		out.append({"level": "H%d" % (i + 1), "text": String(hints[i])})
	return out

## Returns a read-only view dictionary for UI rendering.
func view_state(scene_id: String = "EX-CH03-S02", target_id: String = "") -> Dictionary:
	var scene_info: Dictionary = data().get("scene_gates", {}).get(scene_id, {})
	return {
		"puzzle_id": "P-05",
		"title": String(data().get("title", "Find the Falling Pressure")),
		"subtitle": String(data().get("subtitle", "")),
		"scene_id": scene_id,
		"target_id": target_id,
		"stage_id": String(scene_info.get("stage", "learn")),
		"headline": String(scene_info.get("headline", "Isolate the leaking branch")),
		"instruction": String(scene_info.get("instruction", "")),
		"stages": data().get("stages", []).duplicate(true),
		"guided_intro": data().get("guided_intro", {}).duplicate(true),
		"guided_intro_seen": _guided_intro_seen,
		"explainer_watched": _explainer_watched,
		"gauge_equipped": _gauge_equipped,
		"warning_read": _warning_read,
		"taps_identified": _taps_identified,
		"prediction": _prediction,
		"prediction_spec": data().get("prediction", {}).duplicate(true),
		"t0_readings": _t0_readings.duplicate(true),
		"t10_readings": _t10_readings.duplicate(true),
		"taps": data().get("taps", {}).duplicate(true),
		"current_phase": _current_phase,
		"max_inspections_per_phase": int(data().get("max_inspections_per_phase", 2)),
		"phase_inspections": _phase_inspections.duplicate(true),
		"inspected_candidates": _inspected_candidates.duplicate(),
		"candidates": data().get("candidates", []).duplicate(true),
		"aftershock_triggered": _aftershock_triggered,
		"annex_auto_isolated": _annex_auto_isolated,
		"garden_fall_identified": _garden_fall_identified,
		"trade_choice": _trade_choice,
		"trade_study": data().get("trade_study", {}).duplicate(true),
		"go_no_go": _go_no_go.duplicate(true),
		"go_no_go_poll": data().get("go_no_go_poll", {}).duplicate(true),
		"rollback_checked": _rollback_checked,
		"garden_isolated": _garden_isolated,
		"main_hold_verified": _main_hold_verified,
		"clamp_seated": _clamp_seated,
		"garden_reopened_slow": _garden_reopened_slow,
		"stable_readings": _stable_readings.duplicate(true),
		"note_reconciled": _note_reconciled,
		"handover_saved": _handover_saved,
		"annex_feed_isolated": _annex_feed_isolated,
		"zero_diff_confirmed": _zero_diff_confirmed,
		"annex_hatch_inspected": _annex_hatch_inspected,
		"role_cards": role_cards(scene_id),
		"hints": revealed_hints(),
		"last_feedback": _last_feedback.duplicate(true),
		"block_reason": commit_block_reason(target_id),
		"nasa_sources": data().get("nasa_sources", []).duplicate(),
	}

## Serializes the P-05 model state into a primitive Dictionary for save/load.
func snapshot() -> Dictionary:
	var stable_out := {}
	for k in _stable_readings:
		stable_out[str(k)] = _stable_readings[k].duplicate(true)
	var phase_out := {}
	for p in _phase_inspections:
		phase_out[str(p)] = _phase_inspections[p].duplicate()
	return {
		"schema_version": 1,
		"gauge_equipped": _gauge_equipped,
		"warning_read": _warning_read,
		"taps_identified": _taps_identified,
		"prediction": _prediction,
		"t0_readings": _t0_readings.duplicate(true),
		"t10_readings": _t10_readings.duplicate(true),
		"current_phase": _current_phase,
		"phase_inspections": phase_out,
		"inspected_candidates": _inspected_candidates.duplicate(),
		"aftershock_triggered": _aftershock_triggered,
		"annex_auto_isolated": _annex_auto_isolated,
		"garden_fall_identified": _garden_fall_identified,
		"trade_choice": _trade_choice,
		"go_no_go": _go_no_go.duplicate(true),
		"rollback_checked": _rollback_checked,
		"garden_isolated": _garden_isolated,
		"main_hold_verified": _main_hold_verified,
		"clamp_seated": _clamp_seated,
		"garden_reopened_slow": _garden_reopened_slow,
		"stable_readings": stable_out,
		"note_reconciled": _note_reconciled,
		"handover_saved": _handover_saved,
		"annex_feed_isolated": _annex_feed_isolated,
		"zero_diff_confirmed": _zero_diff_confirmed,
		"annex_hatch_inspected": _annex_hatch_inspected,
		"shared_roles": _shared_roles.duplicate(true),
		"hint_count": _hint_count,
		"guided_intro_seen": _guided_intro_seen,
		"explainer_watched": _explainer_watched,
	}

## Validates and restores a serialized P-05 snapshot.
func restore(saved: Dictionary) -> Dictionary:
	if not saved is Dictionary:
		return {"accepted": false, "reason": "P-05 snapshot must be a Dictionary."}
	if saved.has("schema_version") and (not (saved.schema_version is int or saved.schema_version is float) or int(saved.schema_version) != 1):
		return {"accepted": false, "reason": "Unsupported P-05 snapshot schema_version."}
	for bool_key in ["gauge_equipped", "warning_read", "taps_identified", "aftershock_triggered", "annex_auto_isolated", "garden_fall_identified", "rollback_checked", "garden_isolated", "main_hold_verified", "clamp_seated", "garden_reopened_slow", "note_reconciled", "handover_saved", "annex_feed_isolated", "zero_diff_confirmed", "annex_hatch_inspected", "guided_intro_seen", "explainer_watched"]:
		if saved.has(bool_key) and not saved[bool_key] is bool:
			return {"accepted": false, "reason": "P-05 field %s must be a boolean." % bool_key}
	for dict_key in ["t0_readings", "t10_readings", "phase_inspections", "go_no_go", "stable_readings", "shared_roles"]:
		if saved.has(dict_key) and not saved[dict_key] is Dictionary:
			return {"accepted": false, "reason": "P-05 field %s must be a Dictionary." % dict_key}
	if saved.has("inspected_candidates") and not saved.inspected_candidates is Array:
		return {"accepted": false, "reason": "P-05 inspected_candidates must be an Array."}
	if saved.has("current_phase"):
		var cp = saved.current_phase
		if not (cp is int or cp is float) or int(cp) < 1 or int(cp) > 4:
			return {"accepted": false, "reason": "P-05 current_phase must be an integer in 1..4."}
	if saved.has("hint_count"):
		var hc = saved.hint_count
		if not (hc is int or hc is float) or int(hc) < 0 or int(hc) > 3:
			return {"accepted": false, "reason": "P-05 hint_count must be in 0..3."}
	for window_key in ["t0_readings", "t10_readings"]:
		var map: Dictionary = saved.get(window_key, {})
		for tap_id in map:
			if not TAP_IDS.has(String(tap_id)) or not (map[tap_id] is int or map[tap_id] is float):
				return {"accepted": false, "reason": "P-05 %s contains an invalid tap reading." % window_key}
	reset()
	_gauge_equipped = bool(saved.get("gauge_equipped", false))
	_warning_read = bool(saved.get("warning_read", false))
	_taps_identified = bool(saved.get("taps_identified", false))
	_prediction = String(saved.get("prediction", ""))
	for tap_id in saved.get("t0_readings", {}):
		_t0_readings[String(tap_id)] = int(saved.t0_readings[tap_id])
	for tap_id in saved.get("t10_readings", {}):
		_t10_readings[String(tap_id)] = int(saved.t10_readings[tap_id])
	_current_phase = int(saved.get("current_phase", 1))
	for p in saved.get("phase_inspections", {}):
		var arr: Array = []
		if saved.phase_inspections[p] is Array:
			for item in saved.phase_inspections[p]:
				arr.append(String(item))
		_phase_inspections[int(String(p))] = arr
	for cid in saved.get("inspected_candidates", []):
		if not cid is String:
			return {"accepted": false, "reason": "P-05 candidate ID must be a String."}
		_inspected_candidates.append(String(cid))
	_aftershock_triggered = bool(saved.get("aftershock_triggered", false))
	_annex_auto_isolated = bool(saved.get("annex_auto_isolated", false))
	_garden_fall_identified = bool(saved.get("garden_fall_identified", false))
	_trade_choice = String(saved.get("trade_choice", ""))
	_go_no_go = saved.get("go_no_go", {}).duplicate(true)
	_rollback_checked = bool(saved.get("rollback_checked", false))
	_garden_isolated = bool(saved.get("garden_isolated", false))
	_main_hold_verified = bool(saved.get("main_hold_verified", false))
	_clamp_seated = bool(saved.get("clamp_seated", false))
	_garden_reopened_slow = bool(saved.get("garden_reopened_slow", false))
	for k in saved.get("stable_readings", {}):
		var entry = saved.stable_readings[k]
		if not entry is Dictionary:
			return {"accepted": false, "reason": "P-05 stable_readings entry must be a Dictionary."}
		_stable_readings[int(String(k))] = {
			"main": int(entry.get("main", 0)),
			"garden": int(entry.get("garden", 0)),
			"return": int(entry.get("return", 0)),
		}
	_note_reconciled = bool(saved.get("note_reconciled", false))
	_handover_saved = bool(saved.get("handover_saved", false))
	_annex_feed_isolated = bool(saved.get("annex_feed_isolated", false))
	_zero_diff_confirmed = bool(saved.get("zero_diff_confirmed", false))
	_annex_hatch_inspected = bool(saved.get("annex_hatch_inspected", false))
	_shared_roles = saved.get("shared_roles", {}).duplicate(true)
	_hint_count = int(saved.get("hint_count", 0))
	_guided_intro_seen = bool(saved.get("guided_intro_seen", false))
	_explainer_watched = bool(saved.get("explainer_watched", false))
	return {"accepted": true}

func _candidate_by_id(candidate_id: String) -> Dictionary:
	for item in data().get("candidates", []):
		if String(item.get("id", "")) == candidate_id:
			return item
	return {}

func _candidate_id_for_action(action: String) -> String:
	for item in data().get("candidates", []):
		if String(item.get("action", "")) == action:
			return String(item.get("id", ""))
	return ""

func _card_arrived(arrives_scene: String, current_scene: String) -> bool:
	var a_order := int(arrives_scene.substr(8, 2)) if arrives_scene.length() >= 10 else 1
	var c_order := int(current_scene.substr(8, 2)) if current_scene.length() >= 10 else 12
	return c_order >= a_order
