extends RefCounted
class_name P06HarvestFuture

## Interactive state and validation model for P-06 A Harvest With a Future
## (Chapter 3, EX-M0303 and EX-M0304, scenes EX-CH03-S07 through EX-CH03-S12).
##
## All lifecycle numbers, dry-down vigil steps, pod/well counts, 12 + 30 seed
## allocations, dedication options, Tara's 31 May farewell beat, wrong-choice
## diagnostics, and progressive hints are loaded from
## res://resources/campaign/content/p06_harvest_future.json.

const DATA_PATH := "res://resources/campaign/content/p06_harvest_future.json"
const GATES := [
	"p06_scan_growth_chart",
	"p06_scan_vault_map",
	"p06_exit_suit_check",
	"p06_accept_maturity_montage",
	"p06_save_map_provenance",
	"p06_record_future_checks",
	"p06_confirm_care_transition",
	"p06_confirm_maturity",
	"p06_configure_drydown",
	"p06_drydown_five_days",
	"p06_open_six_pods",
	"p06_count_42",
	"p06_allocate_12_30",
	"p06_sleeve_petal",
	"p06_plant_12_positions",
	"p06_seal_reserve_30",
	"p06_preserve_lineage",
	"p06_reconcile_continuity",
	"p06_confirm_descendant_survey",
]

static var _data_cache: Dictionary = {}

var _growth_chart_scanned := false
var _vault_map_scanned := false
var _suit_checked := false
var _maturity_montage_accepted := false
var _map_provenance_saved := false
var _future_checks_logged := false
var _care_transition_confirmed := false
var _pod_maturity_confirmed := false
var _alo_irrigation_open := true
var _tara_irrigation_open := true
var _substrate_moisture := 70
var _vigil_day := 0
var _pods_opened := false
var _well_counts := {}
var _explicit_count_payload := {}
var _allocated_planted := -1
var _allocated_reserve := -1
var _petal_sleeved := false
var _planted_12_positions := false
var _reserve_30_sealed := false
var _lineage_preserved := false
var _dedication_option := "light_and_star"
var _tara_farewell_recorded := false
var _continuity_reconciled := false
var _descendant_survey_confirmed := false
var _prediction := ""
var _shared_roles := {}
var _hint_count := 0
var _guided_intro_seen := false
var _explainer_watched := false
var _last_feedback := {}

func _init() -> void:
	reset()

## Loads and caches the canonical P-06 data definition from JSON.
static func data() -> Dictionary:
	if _data_cache.is_empty():
		var file := FileAccess.open(DATA_PATH, FileAccess.READ)
		var parsed = JSON.parse_string(file.get_as_text()) if file != null else {}
		_data_cache = parsed if parsed is Dictionary else {}
	return _data_cache

## Returns true if target_id is a P-06 puzzle gate.
static func is_gate(target_id: String) -> bool:
	return GATES.has(target_id)

## Expected payload dictionary for a given action from the JSON data file.
static func expected_payload(action: String) -> Dictionary:
	return data().get("expected_actions", {}).get(action, {}).duplicate(true)

## Resets all interactive P-06 choices back to the unstarted state.
func reset() -> void:
	_growth_chart_scanned = false
	_vault_map_scanned = false
	_suit_checked = false
	_maturity_montage_accepted = false
	_map_provenance_saved = false
	_future_checks_logged = false
	_care_transition_confirmed = false
	_pod_maturity_confirmed = false
	_alo_irrigation_open = true
	_tara_irrigation_open = true
	_substrate_moisture = int(data().get("initial_moisture", 70))
	_vigil_day = 0
	_pods_opened = false
	_well_counts = {}
	_explicit_count_payload = {}
	_allocated_planted = -1
	_allocated_reserve = -1
	_petal_sleeved = false
	_planted_12_positions = false
	_reserve_30_sealed = false
	_lineage_preserved = false
	_dedication_option = "light_and_star"
	_tara_farewell_recorded = false
	_continuity_reconciled = false
	_descendant_survey_confirmed = false
	_prediction = ""
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
func share(role_id: String, scene_id: String = "EX-CH03-S07") -> Dictionary:
	for card in data().get("role_cards", []):
		if String(card.get("role_id", "")) == role_id:
			if not _card_arrived(String(card.get("arrives_scene", "EX-CH03-S07")), scene_id):
				return {"accepted": false, "reason": "%s's clue card has not arrived yet." % String(card.get("name", role_id))}
			var already := bool(_shared_roles.get(role_id, false))
			_shared_roles[role_id] = true
			return {"accepted": true, "duplicate": already, "role_id": role_id}
	return {"accepted": false, "reason": "Unknown crew role card: " + role_id}

## Returns the crew role cards with arrival and shared status for the given scene.
func role_cards(scene_id: String = "EX-CH03-S09") -> Array:
	var cards: Array = []
	for raw in data().get("role_cards", []):
		var card: Dictionary = raw.duplicate(true)
		var role_id := String(card.get("role_id", ""))
		var arrived := _card_arrived(String(card.get("arrives_scene", "EX-CH03-S07")), scene_id)
		card["arrived"] = arrived
		card["shared"] = bool(_shared_roles.get(role_id, false))
		if not arrived:
			card["facts"] = []
			card["quote"] = ""
		cards.append(card)
	return cards

## Records the player's Predict -> Act -> See hypothesis before counting the 6 pods.
func set_prediction(option_id: String) -> Dictionary:
	for option in data().get("prediction", {}).get("options", []):
		if String(option.get("id", "")) == option_id:
			_prediction = option_id
			var resp := String(option.get("response", "Prediction logged."))
			_last_feedback = {"kind": "prediction", "badge": "PREDICTION LOGGED", "message": resp}
			return {"accepted": true, "prediction": _prediction, "message": resp}
	return {"accepted": false, "reason": "Choose 30, 24, or 42 for your reserve prediction."}

## Records an annex investigation step in S07/S08.
func record_annex_step(step_id: String) -> Dictionary:
	match step_id:
		"treat_map_as_cleared":
			return preview_wrong_action("treat_annex_map_as_cleared_route")
		"growth_chart":
			_growth_chart_scanned = true
			_last_feedback = {"kind": "clue", "badge": "ANNEX GROWTH CHART", "message": "Logged Day-12 cold annex note: 'Day 12. Leaves curling. Heat'."}
			return {"accepted": true, "growth_chart_scanned": true}
		"vault_map":
			_vault_map_scanned = true
			_last_feedback = {"kind": "clue", "badge": "HAND-DRAWN VAULT MAP", "message": "Scanned N.R. tool tag (gear-wheel emblem) and hand-drawn southern vault map."}
			return {"accepted": true, "vault_map_scanned": true}
		"suit_check":
			_suit_checked = true
			return {"accepted": true, "suit_checked": true}
		"maturity_montage":
			_maturity_montage_accepted = true
			return {"accepted": true, "maturity_montage_accepted": true}
		"save_map_provenance":
			_map_provenance_saved = true
			_last_feedback = {"kind": "provenance", "badge": "PROVENANCE LOGGED", "message": "Saved N.R. map as an unverified historical clue, separate from cleared routes."}
			return {"accepted": true, "map_provenance_saved": true}
		"record_future_checks":
			if not _map_provenance_saved:
				return {"accepted": false, "reason": "Save the vault map provenance before logging the three required present-day checks."}
			_future_checks_logged = true
			_last_feedback = {"kind": "checks", "badge": "3 PRESENT-DAY CHECKS LOGGED", "message": "Required before any Chapter 4 rover trip: slope limit, return reserve, and relay link chain."}
			return {"accepted": true, "future_checks_logged": true}
		"confirm_care_transition":
			_care_transition_confirmed = true
			return {"accepted": true, "care_transition_confirmed": true}
	return {"accepted": false, "reason": "Unknown annex step: " + step_id}

## Confirms Day-35 pod maturity on Alo (plump brown pods + yellowing leaves = completion).
func confirm_pod_maturity(assessment: String = "mature_completion") -> Dictionary:
	if assessment == "cold_alarm":
		return preview_wrong_action("treat_alo_yellowing_as_cold_alarm")
	if assessment != "mature_completion":
		return {"accepted": false, "reason": "Compare the maturity camera and growth chart to classify Alo's Day-35 state."}
	_pod_maturity_confirmed = true
	_last_feedback = {
		"kind": "maturity",
		"badge": "DAY 35 · MATURE PODS CONFIRMED",
		"message": "Alo isn't failing. She's finishing: six plump brown seed pods are ready for the five-day dry-down.",
	}
	return {"accepted": true, "pod_maturity_confirmed": true}

## Sets an irrigation valve in S09. Only Alo's valve may be closed; Tara's stays open.
func set_irrigation_valve(plant_id: String, open: bool) -> Dictionary:
	var id := plant_id.to_lower()
	if id == "tara":
		if not open:
			return preview_wrong_action("close_tara_irrigation_in_s09")
		_tara_irrigation_open = true
		return {"accepted": true, "tara_irrigation_open": true}
	if id != "alo":
		return {"accepted": false, "reason": "Unknown plant irrigation line: " + plant_id}
	if not open and not _pod_maturity_confirmed:
		return preview_wrong_action("stop_irrigation_before_maturity")
	_alo_irrigation_open = open
	if not open:
		_last_feedback = {
			"kind": "drydown",
			"badge": "ALO IRRIGATION CLOSED · TARA OPEN",
			"message": "Closed irrigation to Alo only (substrate moisture 70). Tara's indoor line remains open.",
		}
	return {"accepted": true, "alo_irrigation_open": _alo_irrigation_open, "tara_irrigation_open": _tara_irrigation_open}

## Advances the 5-day dry-down vigil by one day or completes all 5 days to moisture 20.
func advance_drydown(complete_all: bool = false) -> Dictionary:
	if _alo_irrigation_open:
		return {"accepted": false, "reason": "Close Alo's irrigation valve before starting the five-day dry-down."}
	var vigil: Array = data().get("vigil_days", [])
	if complete_all:
		_vigil_day = vigil.size()
		_substrate_moisture = int(data().get("drydown_target_moisture", 20))
	else:
		if _vigil_day < vigil.size():
			_vigil_day += 1
			_substrate_moisture = int(vigil[_vigil_day - 1].get("moisture", 20))
	var current_entry: Dictionary = vigil[clampi(_vigil_day - 1, 0, vigil.size() - 1)] if not vigil.is_empty() else {}
	_last_feedback = {
		"kind": "vigil",
		"badge": "VIGIL DAY %d/5 · MOISTURE %d" % [_vigil_day, _substrate_moisture],
		"message": String(current_entry.get("caption", "Substrate dried to %d." % _substrate_moisture)),
	}
	return {
		"accepted": true,
		"vigil_day": _vigil_day,
		"moisture": _substrate_moisture,
		"drydown_complete": _substrate_moisture <= int(data().get("drydown_target_moisture", 20)),
	}

## Sets an explicit moisture reading (used to test boundary moisture 21 vs 20).
func set_moisture_for_test(moisture: int) -> void:
	_substrate_moisture = moisture
	_vigil_day = 5 if moisture <= 20 else 4

## Opens the 6 dry pods into the 6 counting wells once substrate moisture is <= 20.
func open_six_pods() -> Dictionary:
	var target_moisture := int(data().get("drydown_target_moisture", 20))
	if _substrate_moisture > target_moisture:
		return preview_wrong_action("open_pods_wet")
	_pods_opened = true
	_last_feedback = {
		"kind": "pods",
		"badge": "SIX PODS OPENED INTO WELLS 1–6",
		"message": "Six dry pods opened cleanly into the six counting wells. Count 7 seeds in each well.",
	}
	return {"accepted": true, "pods_opened": true, "moisture": _substrate_moisture}

## Counts seeds in one counting well (0..5) or all 6 wells in Family auto-group mode.
func count_well(well_index: int, seeds: int = 7, auto_group_all: bool = false) -> Dictionary:
	if not _pods_opened:
		return {"accepted": false, "reason": "Complete the 5-day dry-down to moisture 20 and open the 6 pods before counting wells."}
	var expected_per_well := int(data().get("seeds_per_well", 7))
	var wells_total := int(data().get("wells_count", 6))
	if auto_group_all:
		for idx in range(wells_total):
			_well_counts[idx] = expected_per_well
		_explicit_count_payload = {"total": total_counted(), "wells": wells_counted()}
		_last_feedback = {
			"kind": "count",
			"badge": "6 WELLS × 7 SEEDS = 42 TOTAL",
			"message": "All six wells verified at 7 seeds each: 42 founder seeds ready for allocation.",
		}
		return {"accepted": true, "total": 42, "wells": 6}
	if well_index < 0 or well_index >= wells_total:
		return {"accepted": false, "reason": "Well index must be between 0 and %d." % (wells_total - 1)}
	if seeds != expected_per_well:
		_well_counts.erase(well_index)
		_explicit_count_payload = {"total": total_counted(), "wells": wells_counted()}
		var msg := "Well %d holds %d seeds, not %d. The well reopens so you can recount cleanly." % [well_index + 1, expected_per_well, seeds]
		_last_feedback = {"kind": "warning", "badge": "WELL %d REOPENED FOR RECOUNT" % (well_index + 1), "message": msg}
		return {"accepted": false, "reason": msg, "well_reopened": well_index}
	_well_counts[well_index] = seeds
	_explicit_count_payload = {"total": total_counted(), "wells": wells_counted()}
	_last_feedback = {
		"kind": "count",
		"badge": "WELL %d VERIFIED · %d/42 SEEDS" % [well_index + 1, total_counted()],
		"message": "Well %d counted at 7 seeds (%d/%d wells complete, %d total seeds)." % [well_index + 1, wells_counted(), wells_total, total_counted()],
	}
	return {"accepted": true, "well_index": well_index, "seeds": seeds, "total": total_counted(), "wells": wells_counted()}

## Sets an explicit count payload (allows boundary/wrong tests to test submitting wrong totals/wells).
func set_count_override(total: int, wells: int) -> Dictionary:
	_explicit_count_payload = {"total": total, "wells": wells}
	if total != int(data().get("total_seeds", 42)) or wells != int(data().get("wells_count", 6)):
		return {"accepted": false, "reason": "Six wells of seven total 42 seeds (got %d across %d wells)." % [total, wells]}
	return {"accepted": true, "total": total, "wells": wells}

## Returns total seeds counted across verified wells.
func total_counted() -> int:
	var sum := 0
	for k in _well_counts:
		sum += int(_well_counts[k])
	return sum

## Returns the number of verified wells.
func wells_counted() -> int:
	return _well_counts.size()

## Allocates the 42 counted seeds between active planting (12) and sealed founder reserve (30).
func set_allocation(planted: int, reserve: int) -> Dictionary:
	var expected_total := int(data().get("total_seeds", 42))
	var expected_planted := int(data().get("planted_allocation", 12))
	var expected_reserve := int(data().get("reserve_allocation", 30))
	if total_counted() != expected_total or wells_counted() != int(data().get("wells_count", 6)):
		return {"accepted": false, "reason": "Count all 6 wells of 7 seeds (42 total) before allocating."}
	_allocated_planted = planted
	_allocated_reserve = reserve
	if planted == expected_total and reserve == 0:
		return preview_wrong_action("plant_all_42_seeds")
	if planted + reserve > expected_total:
		var msg := "Cannot allocate %d + %d = %d seeds: you cannot double-count beyond the 42 harvested seeds." % [planted, reserve, planted + reserve]
		_last_feedback = {"kind": "warning", "badge": "DOUBLE-COUNT BLOCKED", "message": msg}
		return {"accepted": false, "reason": msg}
	if planted > expected_planted:
		var msg := "The two descendant cassettes hold 6 positions each (12 planted seeds maximum, not %d)." % planted
		_last_feedback = {"kind": "warning", "badge": "CASSETTE CAPACITY (12 MAX)", "message": msg}
		return {"accepted": false, "reason": msg}
	if planted != expected_planted or reserve != expected_reserve:
		var msg := "Keep 12 seeds for planting and 30 seeds protected in the two-compartment reserve (got %d and %d)." % [planted, reserve]
		_last_feedback = {"kind": "warning", "badge": "CHECK 12 + 30 SPLIT", "message": msg}
		return {"accepted": false, "reason": msg}
	_last_feedback = {
		"kind": "allocation",
		"badge": "ALLOCATED · 12 PLANTED + 30 RESERVE",
		"message": "12 seeds staged for Cassettes 1 & 2; 30 seeds staged for the two 15-seed founder reserve compartments.",
	}
	return {"accepted": true, "planted": _allocated_planted, "reserve": _allocated_reserve}

## Direct button helper: sets the canonical 12 planted + 30 reserve allocation without dragging.
func allocate_12_and_30() -> Dictionary:
	return set_allocation(12, 30)

## Sleeves Alo's last pressed petal and mounts her nameplate on the lineage board.
func sleeve_petal() -> Dictionary:
	_petal_sleeved = true
	_last_feedback = {
		"kind": "moment",
		"badge": "ALO PETAL SLEEVED",
		"message": "Sleeved Alo's pressed golden petal and mounted her nameplate on the garden lineage board.",
	}
	return {"accepted": true, "petal_sleeved": true}

## Selects the descendant tray dedication option for EX-CH03-S11-DEDICATION.
func choose_dedication(option_id: String) -> Dictionary:
	for opt in data().get("dedication_choice", {}).get("options", []):
		if String(opt.get("id", "")) == option_id:
			_dedication_option = option_id
			_last_feedback = {
				"kind": "dedication",
				"badge": "DEDICATION · " + String(opt.get("label", "")).to_upper(),
				"message": String(opt.get("description", "")),
			}
			return {"accepted": true, "option_id": _dedication_option, "label": String(opt.get("label", ""))}
	return {"accepted": false, "reason": "Unknown dedication option: " + option_id}

## Completes the S11 planting and reserve sealing steps.
func record_s11_step(step_id: String) -> Dictionary:
	match step_id:
		"plant_12":
			_planted_12_positions = true
			return {"accepted": true, "planted_12_positions": true}
		"seal_30":
			_reserve_30_sealed = true
			return {"accepted": true, "reserve_30_sealed": true, "compartments": [15, 15]}
		"preserve_lineage":
			_lineage_preserved = true
			return {"accepted": true, "lineage_preserved": true, "dedication_option": _dedication_option}
	return {"accepted": false, "reason": "Unknown S11 step: " + step_id}

## Records Tara's 31 May farewell beat and October continuity ledger in S12.
func record_s12_continuity(action_id: String) -> Dictionary:
	if action_id == "merge_tara_into_founder_42":
		return preview_wrong_action("merge_tara_into_founder_42")
	match action_id:
		"tara_farewell", "reconcile_continuity":
			_tara_farewell_recorded = true
			_continuity_reconciled = true
			_last_feedback = {
				"kind": "continuity",
				"badge": "31 MAY TARA FAREWELL & OCT CONTINUITY",
				"message": "Tara's 31 May pods sealed as 'Working stock — Tara × Alo', her nameplate placed level with Alo's petal, and five months of logs reconciled.",
			}
			return {"accepted": true, "tara_farewell_recorded": true, "continuity_reconciled": true}
		"confirm_descendant_survey":
			_tara_farewell_recorded = true
			_continuity_reconciled = true
			_descendant_survey_confirmed = true
			_last_feedback = {
				"kind": "continuity",
				"badge": "21 OCT · 12 DESCENDANTS (7 PURPLE, 5 GREEN)",
				"message": "Confirmed 12 October descendants (7 purple stems, 5 green stems) and linked the saved May prediction for Chapter 4.",
			}
			return {"accepted": true, "descendant_survey_confirmed": true, "purple_stems": 7, "green_stems": 5}
	return {"accepted": false, "reason": "Unknown S12 step: " + action_id}

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
	_growth_chart_scanned = true
	_vault_map_scanned = true
	_suit_checked = true
	_maturity_montage_accepted = true
	_map_provenance_saved = true
	_future_checks_logged = true
	_care_transition_confirmed = true
	_pod_maturity_confirmed = true
	_alo_irrigation_open = false
	_tara_irrigation_open = true
	_substrate_moisture = 20
	_vigil_day = 5
	_pods_opened = true
	_well_counts = {0: 7, 1: 7, 2: 7, 3: 7, 4: 7, 5: 7}
	_explicit_count_payload = {"total": 42, "wells": 6}
	_allocated_planted = 12
	_allocated_reserve = 30
	_petal_sleeved = true
	_planted_12_positions = true
	_reserve_30_sealed = true
	_lineage_preserved = true
	_dedication_option = "light_and_star"
	_tara_farewell_recorded = true
	_continuity_reconciled = true
	_descendant_survey_confirmed = true
	_prediction = "30"
	for role_id in ["mei", "amara", "kai", "rafi"]:
		_shared_roles[role_id] = true

## Returns the player-constructed payload for a given P-06 gate action, or {} if not yet decided.
func payload_for_action(action: String) -> Dictionary:
	match action:
		"p06_count_42":
			if not _explicit_count_payload.is_empty():
				return _explicit_count_payload.duplicate(true)
			if wells_counted() > 0:
				return {"total": total_counted(), "wells": wells_counted()}
			return {}
		"p06_allocate_12_30":
			if _allocated_planted >= 0 and _allocated_reserve >= 0:
				return {"planted": _allocated_planted, "reserve": _allocated_reserve}
			return {}
	return {}

## Returns a plain-language reason if the player has not yet configured the required input for target_id.
func commit_block_reason(target_id: String) -> String:
	match target_id:
		"p06_count_42":
			return "" if (not _explicit_count_payload.is_empty() or wells_counted() == 6) else "Open all 6 pods into the 6 counting wells and verify 7 seeds per well (42 total) first."
		"p06_allocate_12_30":
			return "" if (_allocated_planted >= 0 and _allocated_reserve >= 0) else "Allocate the 42 seeds into 12 for planting and 30 for the sealed founder reserve first."
	return ""

## Automatically prepares the current action in the model when the player clicks Try It / Lock In on a step gate.
func prepare_gate_from_panel(target_id: String) -> Dictionary:
	match target_id:
		"p06_scan_growth_chart":
			return record_annex_step("growth_chart")
		"p06_scan_vault_map":
			return record_annex_step("vault_map")
		"p06_exit_suit_check":
			return record_annex_step("suit_check")
		"p06_accept_maturity_montage":
			return record_annex_step("maturity_montage")
		"p06_save_map_provenance":
			return record_annex_step("save_map_provenance")
		"p06_record_future_checks":
			record_annex_step("save_map_provenance")
			return record_annex_step("record_future_checks")
		"p06_confirm_care_transition":
			return record_annex_step("confirm_care_transition")
		"p06_confirm_maturity":
			return confirm_pod_maturity("mature_completion")
		"p06_configure_drydown":
			confirm_pod_maturity("mature_completion")
			return set_irrigation_valve("alo", false)
		"p06_drydown_five_days":
			confirm_pod_maturity("mature_completion")
			set_irrigation_valve("alo", false)
			return advance_drydown(true)
		"p06_open_six_pods":
			if _substrate_moisture > 20:
				prepare_gate_from_panel("p06_drydown_five_days")
			return open_six_pods()
		"p06_count_42":
			if not _pods_opened:
				prepare_gate_from_panel("p06_open_six_pods")
			return count_well(0, 7, true)
		"p06_allocate_12_30":
			if total_counted() != 42:
				prepare_gate_from_panel("p06_count_42")
			return allocate_12_and_30()
		"p06_sleeve_petal":
			return sleeve_petal()
		"p06_plant_12_positions":
			return record_s11_step("plant_12")
		"p06_seal_reserve_30":
			return record_s11_step("seal_30")
		"p06_preserve_lineage":
			return record_s11_step("preserve_lineage")
		"p06_reconcile_continuity":
			return record_s12_continuity("reconcile_continuity")
		"p06_confirm_descendant_survey":
			return record_s12_continuity("confirm_descendant_survey")
	return {"accepted": true}

## Reveals the next progressive hint (H1 -> H2 -> H3).
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
func view_state(scene_id: String = "EX-CH03-S10", target_id: String = "") -> Dictionary:
	var scene_info: Dictionary = data().get("scene_gates", {}).get(scene_id, {})
	return {
		"puzzle_id": "P-06",
		"title": String(data().get("title", "A Harvest With a Future")),
		"subtitle": String(data().get("subtitle", "")),
		"scene_id": scene_id,
		"target_id": target_id,
		"stage_id": String(scene_info.get("stage", "apply")),
		"headline": String(scene_info.get("headline", "Harvest and allocate founder seeds")),
		"instruction": String(scene_info.get("instruction", "")),
		"stages": data().get("stages", []).duplicate(true),
		"guided_intro": data().get("guided_intro", {}).duplicate(true),
		"guided_intro_seen": _guided_intro_seen,
		"explainer_watched": _explainer_watched,
		"prediction": _prediction,
		"prediction_spec": data().get("prediction", {}).duplicate(true),
		"growth_chart_scanned": _growth_chart_scanned,
		"vault_map_scanned": _vault_map_scanned,
		"suit_checked": _suit_checked,
		"maturity_montage_accepted": _maturity_montage_accepted,
		"map_provenance_saved": _map_provenance_saved,
		"future_checks_logged": _future_checks_logged,
		"care_transition_confirmed": _care_transition_confirmed,
		"pod_maturity_confirmed": _pod_maturity_confirmed,
		"alo_irrigation_open": _alo_irrigation_open,
		"tara_irrigation_open": _tara_irrigation_open,
		"substrate_moisture": _substrate_moisture,
		"vigil_day": _vigil_day,
		"vigil_days": data().get("vigil_days", []).duplicate(true),
		"pods_opened": _pods_opened,
		"well_counts": _well_counts.duplicate(true),
		"total_counted": total_counted(),
		"wells_counted": wells_counted(),
		"allocated_planted": _allocated_planted,
		"allocated_reserve": _allocated_reserve,
		"petal_sleeved": _petal_sleeved,
		"planted_12_positions": _planted_12_positions,
		"reserve_30_sealed": _reserve_30_sealed,
		"lineage_preserved": _lineage_preserved,
		"dedication_option": _dedication_option,
		"dedication_choice": data().get("dedication_choice", {}).duplicate(true),
		"tara_farewell": data().get("tara_farewell", {}).duplicate(true),
		"tara_farewell_recorded": _tara_farewell_recorded,
		"continuity_reconciled": _continuity_reconciled,
		"descendant_survey_confirmed": _descendant_survey_confirmed,
		"role_cards": role_cards(scene_id),
		"hints": revealed_hints(),
		"last_feedback": _last_feedback.duplicate(true),
		"block_reason": commit_block_reason(target_id),
		"nasa_sources": data().get("nasa_sources", []).duplicate(),
	}

## Serializes the P-06 model state into a primitive Dictionary for save/load.
func snapshot() -> Dictionary:
	var wells_out := {}
	for k in _well_counts:
		wells_out[str(k)] = int(_well_counts[k])
	return {
		"schema_version": 1,
		"growth_chart_scanned": _growth_chart_scanned,
		"vault_map_scanned": _vault_map_scanned,
		"suit_checked": _suit_checked,
		"maturity_montage_accepted": _maturity_montage_accepted,
		"map_provenance_saved": _map_provenance_saved,
		"future_checks_logged": _future_checks_logged,
		"care_transition_confirmed": _care_transition_confirmed,
		"pod_maturity_confirmed": _pod_maturity_confirmed,
		"alo_irrigation_open": _alo_irrigation_open,
		"tara_irrigation_open": _tara_irrigation_open,
		"substrate_moisture": _substrate_moisture,
		"vigil_day": _vigil_day,
		"pods_opened": _pods_opened,
		"well_counts": wells_out,
		"explicit_count_payload": _explicit_count_payload.duplicate(true),
		"allocated_planted": _allocated_planted,
		"allocated_reserve": _allocated_reserve,
		"petal_sleeved": _petal_sleeved,
		"planted_12_positions": _planted_12_positions,
		"reserve_30_sealed": _reserve_30_sealed,
		"lineage_preserved": _lineage_preserved,
		"dedication_option": _dedication_option,
		"tara_farewell_recorded": _tara_farewell_recorded,
		"continuity_reconciled": _continuity_reconciled,
		"descendant_survey_confirmed": _descendant_survey_confirmed,
		"prediction": _prediction,
		"shared_roles": _shared_roles.duplicate(true),
		"hint_count": _hint_count,
		"guided_intro_seen": _guided_intro_seen,
		"explainer_watched": _explainer_watched,
	}

## Validates and restores a serialized P-06 snapshot.
func restore(saved: Dictionary) -> Dictionary:
	if not saved is Dictionary:
		return {"accepted": false, "reason": "P-06 snapshot must be a Dictionary."}
	if saved.has("schema_version") and (not (saved.schema_version is int or saved.schema_version is float) or int(saved.schema_version) != 1):
		return {"accepted": false, "reason": "Unsupported P-06 snapshot schema_version."}
	for bool_key in ["growth_chart_scanned", "vault_map_scanned", "suit_checked", "maturity_montage_accepted", "map_provenance_saved", "future_checks_logged", "care_transition_confirmed", "pod_maturity_confirmed", "alo_irrigation_open", "tara_irrigation_open", "pods_opened", "petal_sleeved", "planted_12_positions", "reserve_30_sealed", "lineage_preserved", "tara_farewell_recorded", "continuity_reconciled", "descendant_survey_confirmed", "guided_intro_seen", "explainer_watched"]:
		if saved.has(bool_key) and not saved[bool_key] is bool:
			return {"accepted": false, "reason": "P-06 field %s must be a boolean." % bool_key}
	for dict_key in ["well_counts", "explicit_count_payload", "shared_roles"]:
		if saved.has(dict_key) and not saved[dict_key] is Dictionary:
			return {"accepted": false, "reason": "P-06 field %s must be a Dictionary." % dict_key}
	for int_key in ["substrate_moisture", "vigil_day", "allocated_planted", "allocated_reserve", "hint_count"]:
		if saved.has(int_key) and not (saved[int_key] is int or saved[int_key] is float):
			return {"accepted": false, "reason": "P-06 field %s must be a number." % int_key}
	if saved.has("dedication_option") and not saved.dedication_option is String:
		return {"accepted": false, "reason": "P-06 dedication_option must be a String."}
	for k in saved.get("well_counts", {}):
		var v = saved.well_counts[k]
		if not (v is int or v is float) or int(String(k)) < 0 or int(String(k)) >= 6:
			return {"accepted": false, "reason": "P-06 well_counts entry is invalid."}
	reset()
	_growth_chart_scanned = bool(saved.get("growth_chart_scanned", false))
	_vault_map_scanned = bool(saved.get("vault_map_scanned", false))
	_suit_checked = bool(saved.get("suit_checked", false))
	_maturity_montage_accepted = bool(saved.get("maturity_montage_accepted", false))
	_map_provenance_saved = bool(saved.get("map_provenance_saved", false))
	_future_checks_logged = bool(saved.get("future_checks_logged", false))
	_care_transition_confirmed = bool(saved.get("care_transition_confirmed", false))
	_pod_maturity_confirmed = bool(saved.get("pod_maturity_confirmed", false))
	_alo_irrigation_open = bool(saved.get("alo_irrigation_open", true))
	_tara_irrigation_open = bool(saved.get("tara_irrigation_open", true))
	_substrate_moisture = int(saved.get("substrate_moisture", 70))
	_vigil_day = int(saved.get("vigil_day", 0))
	_pods_opened = bool(saved.get("pods_opened", false))
	for k in saved.get("well_counts", {}):
		_well_counts[int(String(k))] = int(saved.well_counts[k])
	var raw_count: Dictionary = saved.get("explicit_count_payload", {})
	_explicit_count_payload = {}
	for k in raw_count:
		_explicit_count_payload[String(k)] = int(raw_count[k])
	_allocated_planted = int(saved.get("allocated_planted", -1))
	_allocated_reserve = int(saved.get("allocated_reserve", -1))
	_petal_sleeved = bool(saved.get("petal_sleeved", false))
	_planted_12_positions = bool(saved.get("planted_12_positions", false))
	_reserve_30_sealed = bool(saved.get("reserve_30_sealed", false))
	_lineage_preserved = bool(saved.get("lineage_preserved", false))
	_dedication_option = String(saved.get("dedication_option", "light_and_star"))
	_tara_farewell_recorded = bool(saved.get("tara_farewell_recorded", false))
	_continuity_reconciled = bool(saved.get("continuity_reconciled", false))
	_descendant_survey_confirmed = bool(saved.get("descendant_survey_confirmed", false))
	_prediction = String(saved.get("prediction", ""))
	_shared_roles = saved.get("shared_roles", {}).duplicate(true)
	_hint_count = int(saved.get("hint_count", 0))
	_guided_intro_seen = bool(saved.get("guided_intro_seen", false))
	_explainer_watched = bool(saved.get("explainer_watched", false))
	return {"accepted": true}

func _card_arrived(arrives_scene: String, current_scene: String) -> bool:
	var a_order := int(arrives_scene.substr(8, 2)) if arrives_scene.length() >= 10 else 7
	var c_order := int(current_scene.substr(8, 2)) if current_scene.length() >= 10 else 12
	return c_order >= a_order
