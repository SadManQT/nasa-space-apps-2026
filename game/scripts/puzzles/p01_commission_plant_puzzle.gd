extends RefCounted
class_name P01CommissionPlantPuzzle

## Player-authored workbench state for P-01 (Commission & Plant).
##
## Owns the interactive calibration, packet-scan, and paired-cassette controls
## shown on the Commissioning & Planting Bench UI in EX-CH01-S03 and EX-CH01-S04.
## Numbers and hints come exclusively from `p01_commission_plant.json`
## (`game-design/08_PUZZLE_DESIGNS.md`). No pre-filled answers are ever supplied:
## the workbench starts with the raw +10 probe offset (dry = 10, wet = 110) and
## empty, unwatered, unlabelled, unsealed cassettes.

const DATA_PATH := "res://resources/campaign/content/p01_commission_plant.json"
const GATES_S03 := ["calibrate_probe", "span_probe", "recheck_probe", "inspect_packet"]
const GATES_S04 := ["plant_alo", "plant_tara", "water_alo", "water_tara", "label_alo", "label_tara", "seal_alo", "seal_tara"]
const ALL_GATES := [
	"calibrate_probe", "span_probe", "recheck_probe", "inspect_packet",
	"plant_alo", "plant_tara", "water_alo", "water_tara",
	"label_alo", "label_tara", "seal_alo", "seal_tara",
]

static var _cached_data: Dictionary = {}

var _reference_cup := "dry"
var _zero_offset := 0
var _span_target := 110
var _recheck_dry_verified := false
var _recheck_wet_verified := false
var _scan_mode := ""
var _predictions := {"EX-CH01-S03": "", "EX-CH01-S04": ""}
var _cassettes := {}
var _hints_revealed := 0
var _attempt_count := 0
var _last_feedback := {}

func _init() -> void:
	reset_all()

## Loads and caches the canonical P-01 data file.
static func data() -> Dictionary:
	if _cached_data.is_empty():
		var file := FileAccess.open(DATA_PATH, FileAccess.READ)
		if file != null:
			var parsed = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				_cached_data = parsed
	return _cached_data

## True when `target_id` is one of the twelve P-01 commissioning/planting gates.
static func is_gate(target_id: String) -> bool:
	return ALL_GATES.has(target_id)

## Ordered P-01 gate IDs belonging to `scene_id`.
static func gates_for_scene(scene_id: String) -> Array:
	if scene_id == "EX-CH01-S03":
		return GATES_S03.duplicate()
	if scene_id == "EX-CH01-S04":
		return GATES_S04.duplicate()
	return []

## Metadata dictionary for one P-01 gate from `p01_commission_plant.json`.
static func gate_info(target_id: String) -> Dictionary:
	return data().get("gates", {}).get(target_id, {}).duplicate(true)

## Normalizes player-facing or internal label strings.
static func normalize_label(raw_label: String) -> String:
	var cleaned := raw_label.strip_edges().to_upper().replace(" ", "_")
	if cleaned in ["EXTERNAL_TEST", "INDOOR_REFERENCE"]:
		return cleaned
	return raw_label.strip_edges()

## Human-readable label text for UI display.
static func display_label(raw_label: String) -> String:
	var normalized := normalize_label(raw_label)
	match normalized:
		"EXTERNAL_TEST":
			return "EXTERNAL TEST"
		"INDOOR_REFERENCE":
			return "INDOOR REFERENCE"
		"":
			return "UNLABELLED"
		_:
			return raw_label

## Resets the entire workbench to the uncalibrated, unplanted initial state.
func reset_all() -> void:
	var probe_spec: Dictionary = data().get("probe", {})
	_reference_cup = "dry"
	_zero_offset = 0
	_span_target = int(probe_spec.get("uncalibrated_wet", 110))
	_recheck_dry_verified = false
	_recheck_wet_verified = false
	_scan_mode = ""
	_predictions = {"EX-CH01-S03": "", "EX-CH01-S04": ""}
	_cassettes = {
		"alo": _new_cassette_choice("alo"),
		"tara": _new_cassette_choice("tara"),
	}
	_hints_revealed = 0
	_attempt_count = 0
	_last_feedback = {}

func _new_cassette_choice(cassette_id: String) -> Dictionary:
	return {
		"target_cassette": cassette_id,
		"seeds": 0,
		"moisture": -1,
		"flooded": false,
		"drained_to_waste": 0,
		"label": "",
		"seal_closed": false,
	}

## Current displayed reading on the dry reference cup given `_zero_offset`.
func displayed_dry_reading() -> int:
	var initial_offset := int(data().get("probe", {}).get("uncalibrated_dry", 10))
	return initial_offset + _zero_offset

## Current displayed reading on the wet reference cup given `_zero_offset` and `_span_target`.
func displayed_wet_reading() -> int:
	return _span_target

## Selects which reference cup (`"dry"` or `"wet"`) the probe is dipped into.
func select_reference_cup(cup: String) -> Dictionary:
	var cleaned := cup.strip_edges().to_lower()
	if cleaned not in ["dry", "wet"]:
		return _reject("Select either the dry or the wet reference cup.")
	_reference_cup = cleaned
	return _ok("Probe placed in the %s reference cup." % cleaned)

## Adjusts the probe's zero offset (target `-10` so the `+10` dry cup reads `0`).
func set_zero_offset(offset: int) -> Dictionary:
	if offset < -20 or offset > 20:
		return _reject("Zero offset must stay within -20 to +20 displayed units.")
	_zero_offset = offset
	var dry_now := displayed_dry_reading()
	if dry_now != 0:
		_recheck_dry_verified = false
	var msg := "Zero offset set to %+d; dry reference cup now reads %d." % [_zero_offset, dry_now]
	if dry_now == 0:
		msg += " Dry zero matches the 0 reference target."
	return _ok(msg, {"zero_offset": _zero_offset, "dry_reading": dry_now})

## Adjusts the probe's wet span reading (target `100` on the wet reference cup).
func set_wet_span(span: int) -> Dictionary:
	if span < 50 or span > 150:
		return _reject("Wet span must stay within 50 to 150 displayed units.")
	_span_target = span
	if _span_target != 100:
		_recheck_wet_verified = false
	var msg := "Wet span set to %d; wet reference cup now reads %d." % [_span_target, _span_target]
	if _span_target == 100:
		msg += " Wet span matches the 100 reference target."
	return _ok(msg, {"span_target": _span_target, "wet_reading": _span_target})

## Verifies one or both reference cups during the two-point recheck step.
func set_recheck_cup(cup: String, verified: bool = true) -> Dictionary:
	var cleaned := cup.strip_edges().to_lower()
	if cleaned not in ["dry", "wet", "both"]:
		return _reject("Recheck requires the dry cup, the wet cup, or both cups.")
	if cleaned in ["dry", "both"]:
		if verified and displayed_dry_reading() != 0:
			_recheck_dry_verified = false
			return _reject("Dry reference cup currently reads %d, not 0. Zero the probe to -10 offset first." % displayed_dry_reading())
		_recheck_dry_verified = verified
	if cleaned in ["wet", "both"]:
		if verified and displayed_wet_reading() != 100:
			_recheck_wet_verified = false
			return _reject("Wet reference cup currently reads %d, not 100. Set the wet span to 100 first." % displayed_wet_reading())
		_recheck_wet_verified = verified
	var status := "Dry = %s, Wet = %s." % [
		"0 verified" if _recheck_dry_verified else "unverified",
		"100 verified" if _recheck_wet_verified else "unverified",
	]
	return _ok("Two-point recheck updated: " + status)

## Selects the packet inspection mode (`"sealed_optical"`, `"unrecorded_glance"`, `"unseal_on_bench"`).
func set_scan_mode(mode: String) -> Dictionary:
	var valid_ids: Array = data().get("packet", {}).get("scan_modes", []).map(func(item): return String(item.get("id", "")))
	if not valid_ids.has(mode):
		return _reject("Unknown packet inspection mode: " + mode)
	_scan_mode = mode
	if mode == "unseal_on_bench":
		return _feedback(false, "Keep the packet sealed on the open bench. Use Optical Scan Through Intact Seal to log ALO and N. (2 seeds) without exposing the seeds.", "Check the instrument before trusting it.")
	if mode == "unrecorded_glance":
		return _feedback(false, "A visual glance skips the provenance log. Run the Optical Scan Through Intact Seal so ALO, N., and 2 seeds are recorded.", "Check the instrument before trusting it.")
	return _ok("Optical scan staged: sealed packet reads ALO and N. (2 seeds), seal intact.")

## Records the player's scientific prediction choice for S03 or S04.
func select_prediction(scene_id: String, option_id: String) -> Dictionary:
	var spec: Dictionary = data().get("predictions", {}).get(scene_id, {})
	if spec.is_empty():
		return _reject("No prediction prompt is defined for " + scene_id + ".")
	var found: Dictionary = {}
	for opt in spec.get("options", []):
		if String(opt.get("id", "")) == option_id:
			found = opt
			break
	if found.is_empty():
		return _reject("Unknown prediction option: " + option_id)
	_predictions[scene_id] = option_id
	var is_correct := option_id == String(spec.get("correct_option", ""))
	return {
		"accepted": true,
		"correct": is_correct,
		"option_id": option_id,
		"reason": String(found.get("feedback", "")),
	}

## Sets which cassette (`"alo"` or `"tara"`) a planting operation targets.
func set_cassette_target(cassette_id: String, target_cassette: String) -> Dictionary:
	if not _cassettes.has(cassette_id) or target_cassette not in ["alo", "tara"]:
		return _reject("Select either the Alo or the Tara cassette.")
	_cassettes[cassette_id]["target_cassette"] = target_cassette
	if target_cassette != cassette_id:
		var other_title := "Alo" if target_cassette == "alo" else "Tara"
		return _feedback(false, "The %s cassette belongs to the paired station. Select the %s cassette for this slot so each cassette receives 1 seed." % [other_title, cassette_id.capitalize()], "Each sealed cassette holds 1 seed: 1 in Alo and 1 in Tara.")
	return _ok("Target cassette set to %s." % cassette_id.capitalize())

## Sets the number of seeds staged for `cassette_id` (`0`, `1`, or `2`).
func set_cassette_seeds(cassette_id: String, seeds: int) -> Dictionary:
	if not _cassettes.has(cassette_id):
		return _reject("Unknown cassette: " + cassette_id)
	if seeds < 0 or seeds > 2:
		return _reject("Seed count must be 0, 1, or 2.")
	_cassettes[cassette_id]["seeds"] = seeds
	_cassettes[cassette_id]["target_cassette"] = cassette_id
	if seeds == 0:
		return _feedback(false, "No seed placed in the %s cassette yet. Select 1 seed from the packet." % cassette_id.capitalize(), "Place 1 seed in Alo and 1 seed in Tara.")
	if seeds > 1:
		var other := "Tara" if cassette_id == "alo" else "Alo"
		return _feedback(false, "Placing %d seeds in the %s cassette would overcrowd it and leave the %s cassette empty. Place 1 seed in each cassette." % [seeds, cassette_id.capitalize(), other], "Place 1 seed in Alo and 1 seed in Tara.")
	return _ok("1 seed staged for the %s cassette." % cassette_id.capitalize())

## Sets the calibrated water/moisture level (`0..100`) for `cassette_id`.
## Flooding (`> 60`) never kills the seed; it marks the cassette `flooded` and
## prompts draining excess water to waste.
func set_cassette_moisture(cassette_id: String, moisture: int) -> Dictionary:
	if not _cassettes.has(cassette_id):
		return _reject("Unknown cassette: " + cassette_id)
	var clamped := clampi(moisture, 0, 100)
	_cassettes[cassette_id]["moisture"] = clamped
	_cassettes[cassette_id]["flooded"] = clamped > 60
	if clamped < 40:
		return _feedback(
			false,
			"Moisture %d is below the 40–60 germination band (50 nominal) for the %s cassette. Add water to reach 40–60." % [clamped, cassette_id.capitalize()],
			"Dry must read 0, wet 100, then fill both to 50."
		)
	if clamped > 60:
		return _feedback(
			false,
			"Cassette %s is flooded at %d units (> 60 max). The seed is unharmed — use Drain Excess to Waste to bring moisture into the 40–60 band (50 nominal) before sealing." % [cassette_id.capitalize(), clamped],
			"Flooding (> 60) does not harm the seed. Drain excess water to waste until moisture reads 40–60 (50 nominal)."
		)
	return _ok("Cassette %s moisture set to %d units (within the 40–60 calibrated band; 50 nominal)." % [cassette_id.capitalize(), clamped])

## Adjusts `cassette_id` moisture by `delta` units (defaulting from `0` if unset).
func adjust_cassette_moisture(cassette_id: String, delta: int) -> Dictionary:
	if not _cassettes.has(cassette_id):
		return _reject("Unknown cassette: " + cassette_id)
	var current := int(_cassettes[cassette_id].get("moisture", -1))
	if current < 0:
		current = 0
	return set_cassette_moisture(cassette_id, clampi(current + delta, 0, 100))

## Drains excess water from a flooded (`> 60`) or over-watered cassette into the
## waste line without harming the seed.
func drain_excess_water(cassette_id: String, target_moisture: int = 50) -> Dictionary:
	if not _cassettes.has(cassette_id):
		return _reject("Unknown cassette: " + cassette_id)
	var current := int(_cassettes[cassette_id].get("moisture", -1))
	if current <= 0:
		return _reject("Cassette %s has no water to drain." % cassette_id.capitalize())
	var destination := clampi(target_moisture, 40, 60)
	if current <= destination:
		destination = maxi(0, current - int(data().get("moisture_band", {}).get("drain_step", 10)))
	var drained := maxi(0, current - destination)
	_cassettes[cassette_id]["moisture"] = destination
	_cassettes[cassette_id]["flooded"] = destination > 60
	_cassettes[cassette_id]["drained_to_waste"] = int(_cassettes[cassette_id].get("drained_to_waste", 0)) + drained
	return _ok(
		"Drained %d excess units from %s cassette to waste; moisture now reads %d units (seed intact)." % [drained, cassette_id.capitalize(), destination],
		{"drained": drained, "moisture": destination}
	)

## Assigns a label (`"EXTERNAL_TEST"` or `"INDOOR_REFERENCE"`) to `cassette_id`.
func set_cassette_label(cassette_id: String, raw_label: String, committed_p01: Dictionary = {}) -> Dictionary:
	if not _cassettes.has(cassette_id):
		return _reject("Unknown cassette: " + cassette_id)
	var normalized := normalize_label(raw_label)
	if normalized not in ["EXTERNAL_TEST", "INDOOR_REFERENCE"]:
		return _reject("Choose either EXTERNAL TEST or INDOOR REFERENCE.")
	_cassettes[cassette_id]["label"] = normalized
	var other_id := "tara" if cassette_id == "alo" else "alo"
	var other_label := String(_cassettes[other_id].get("label", ""))
	if committed_p01.has("cassettes") and committed_p01.cassettes is Dictionary:
		var committed_other := String(committed_p01.cassettes.get(other_id, {}).get("label", ""))
		if not committed_other.is_empty():
			other_label = committed_other
	var expected := "EXTERNAL_TEST" if cassette_id == "alo" else "INDOOR_REFERENCE"
	if normalized != expected:
		if other_label == normalized:
			return _feedback(
				false,
				"Duplicate label blocked: the %s cassette already holds %s. Assign %s to %s so the paired experiment has one external test and one indoor reference." % [other_id.capitalize(), display_label(normalized), display_label(expected), cassette_id.capitalize()],
				"Alo takes EXTERNAL TEST and Tara takes INDOOR REFERENCE."
			)
		return _feedback(
			false,
			"Label mismatch: %s is the %s specimen and requires %s (not %s)." % [
				cassette_id.capitalize(),
				"external test" if cassette_id == "alo" else "indoor reference",
				display_label(expected),
				display_label(normalized),
			],
			"Alo takes EXTERNAL TEST and Tara takes INDOOR REFERENCE."
		)
	return _ok("Label %s staged for %s cassette." % [display_label(normalized), cassette_id.capitalize()])

## Stages the seal state (`true` = closed & locked) for `cassette_id`.
func set_cassette_seal(cassette_id: String, closed: bool) -> Dictionary:
	if not _cassettes.has(cassette_id):
		return _reject("Unknown cassette: " + cassette_id)
	_cassettes[cassette_id]["seal_closed"] = closed
	if not closed:
		return _feedback(false, "Cassette %s seal is still open. Close and lock the seal after seeding, watering (40–60), and labelling." % cassette_id.capitalize(), "Both cassette seals must be closed to complete P-01.")
	return _ok("Cassette %s seal staged to CLOSED & LOCKED." % cassette_id.capitalize())

## Resets an unsettled (unsealed) cassette on the workbench without destroying
## any seed or affecting the other cassette.
func reset_cassette(cassette_id: String, committed_p01: Dictionary = {}) -> Dictionary:
	if not _cassettes.has(cassette_id):
		return _reject("Unknown cassette: " + cassette_id)
	var already_sealed := bool(committed_p01.get("cassettes", {}).get(cassette_id, {}).get("sealed", false))
	if already_sealed:
		return _reject("A sealed cassette cannot be reset without breaking containment.")
	_cassettes[cassette_id] = _new_cassette_choice(cassette_id)
	return _ok("Unsettled %s cassette reset; seed returned safely to the sterile tray." % cassette_id.capitalize())

## Reveals the next progressive hint (`H1` -> `H2` -> `H3`) from `08_PUZZLE_DESIGNS.md`.
## Revealing hints never penalises the player's ending or mastery.
func next_hint() -> Dictionary:
	var all_hints: Array = data().get("hints", [])
	if _hints_revealed < all_hints.size():
		_hints_revealed += 1
	var revealed := revealed_hints()
	var latest: Dictionary = revealed.back() if not revealed.is_empty() else {}
	return {
		"accepted": true,
		"hints_revealed": _hints_revealed,
		"total_hints": all_hints.size(),
		"hint": latest,
		"reason": "%s: %s" % [String(latest.get("title", "Hint")), String(latest.get("text", ""))],
	}

## All progressive hints revealed so far.
func revealed_hints() -> Array:
	var all_hints: Array = data().get("hints", [])
	return all_hints.slice(0, clampi(_hints_revealed, 0, all_hints.size())).duplicate(true)

## Builds the frozen payload for `target_id` from the player's workbench choices,
## merged with any explicit `override_payload` keys. Never invents right answers!
func payload_for_gate(target_id: String, override_payload: Dictionary = {}) -> Dictionary:
	var base: Dictionary = {}
	match target_id:
		"calibrate_probe":
			base = {
				"reference_cup": _reference_cup,
				"zero_offset": _zero_offset,
				"dry_reading": displayed_dry_reading(),
			}
		"span_probe":
			base = {
				"reference_cup": _reference_cup,
				"span_target": _span_target,
				"wet_reading": displayed_wet_reading(),
			}
		"recheck_probe":
			base = {
				"both_cups_checked": _recheck_dry_verified and _recheck_wet_verified,
				"recheck_dry": displayed_dry_reading() if _recheck_dry_verified else -1,
				"recheck_wet": displayed_wet_reading() if _recheck_wet_verified else -1,
			}
		"inspect_packet":
			base = {
				"scan_mode": _scan_mode,
				"inscription": "ALO" if _scan_mode == "sealed_optical" else "",
				"initial": "N." if _scan_mode == "sealed_optical" else "",
				"seed_count": 2 if _scan_mode == "sealed_optical" else 0,
			}
		"plant_alo":
			base = {
				"target_cassette": String(_cassettes.alo.get("target_cassette", "alo")),
				"seeds": int(_cassettes.alo.get("seeds", 0)),
			}
		"plant_tara":
			base = {
				"target_cassette": String(_cassettes.tara.get("target_cassette", "tara")),
				"seeds": int(_cassettes.tara.get("seeds", 0)),
			}
		"water_alo":
			if int(_cassettes.alo.get("moisture", -1)) >= 0:
				base["moisture"] = int(_cassettes.alo.get("moisture", -1))
		"water_tara":
			if int(_cassettes.tara.get("moisture", -1)) >= 0:
				base["moisture"] = int(_cassettes.tara.get("moisture", -1))
		"label_alo":
			base = {"label": String(_cassettes.alo.get("label", ""))}
		"label_tara":
			base = {"label": String(_cassettes.tara.get("label", ""))}
		"seal_alo":
			base = {"seal_closed": bool(_cassettes.alo.get("seal_closed", false))}
		"seal_tara":
			base = {"seal_closed": bool(_cassettes.tara.get("seal_closed", false))}
	for key in override_payload.keys():
		base[key] = override_payload[key]
	return base

## Configures the workbench with valid canonical choices (used by test fixtures
## that traverse Chapter 1 to test later systems).
func apply_canonical_setup() -> void:
	_reference_cup = "dry"
	_zero_offset = -10
	_span_target = 100
	_recheck_dry_verified = true
	_recheck_wet_verified = true
	_scan_mode = "sealed_optical"
	_predictions = {"EX-CH01-S03": "reads_10", "EX-CH01-S04": "paired_control"}
	_cassettes["alo"] = {
		"target_cassette": "alo",
		"seeds": 1,
		"moisture": 50,
		"flooded": false,
		"drained_to_waste": 0,
		"label": "EXTERNAL_TEST",
		"seal_closed": true,
	}
	_cassettes["tara"] = {
		"target_cassette": "tara",
		"seeds": 1,
		"moisture": 50,
		"flooded": false,
		"drained_to_waste": 0,
		"label": "INDOOR_REFERENCE",
		"seal_closed": true,
	}

## Synchronises workbench fields forward when an action is committed with an
## explicit payload (so the UI reflects committed state accurately).
func sync_from_committed(action: String, payload: Dictionary, committed_p01: Dictionary) -> void:
	match action:
		"set_zero":
			_zero_offset = -10
		"set_span":
			_span_target = 100
		"recheck":
			_zero_offset = -10
			_span_target = 100
			_recheck_dry_verified = true
			_recheck_wet_verified = true
		"scan_packet":
			_scan_mode = "sealed_optical"
		"plant_alo":
			_cassettes.alo.target_cassette = "alo"
			_cassettes.alo.seeds = 1
		"plant_tara":
			_cassettes.tara.target_cassette = "tara"
			_cassettes.tara.seeds = 1
		"water_alo":
			var m := int(payload.get("moisture", committed_p01.get("cassettes", {}).get("alo", {}).get("moisture", 50)))
			_cassettes.alo.moisture = m
			_cassettes.alo.flooded = false
		"water_tara":
			var m := int(payload.get("moisture", committed_p01.get("cassettes", {}).get("tara", {}).get("moisture", 50)))
			_cassettes.tara.moisture = m
			_cassettes.tara.flooded = false
		"label_alo_external":
			_cassettes.alo.label = "EXTERNAL_TEST"
		"label_tara_indoor":
			_cassettes.tara.label = "INDOOR_REFERENCE"
		"seal_alo":
			_cassettes.alo.seal_closed = true
		"seal_tara":
			_cassettes.tara.seal_closed = true

func record_attempt(validation: Dictionary) -> void:
	_attempt_count += 1
	_last_feedback = validation.duplicate(true)

func snapshot() -> Dictionary:
	return {
		"reference_cup": _reference_cup,
		"zero_offset": _zero_offset,
		"span_target": _span_target,
		"recheck_dry_verified": _recheck_dry_verified,
		"recheck_wet_verified": _recheck_wet_verified,
		"scan_mode": _scan_mode,
		"predictions": _predictions.duplicate(true),
		"cassettes": _cassettes.duplicate(true),
		"hints_revealed": _hints_revealed,
		"attempt_count": _attempt_count,
		"last_feedback": _last_feedback.duplicate(true),
	}

func restore(state: Dictionary) -> Dictionary:
	if not state is Dictionary:
		return _reject("P-01 workbench snapshot must be a Dictionary.")
	var cup := String(state.get("reference_cup", "dry"))
	if cup not in ["dry", "wet"]:
		return _reject("P-01 workbench snapshot has an invalid reference_cup.")
	var zero_raw = state.get("zero_offset", 0)
	var span_raw = state.get("span_target", 110)
	var hints_raw = state.get("hints_revealed", 0)
	var attempts_raw = state.get("attempt_count", 0)
	for num in [zero_raw, span_raw, hints_raw, attempts_raw]:
		if not (num is int or num is float) or not is_finite(float(num)) or float(num) != floor(float(num)):
			return _reject("P-01 workbench numeric fields must be integers.")
	if int(zero_raw) < -20 or int(zero_raw) > 20 or int(span_raw) < 50 or int(span_raw) > 150:
		return _reject("P-01 workbench calibration values are out of bounds.")
	if int(hints_raw) < 0 or int(hints_raw) > 3 or int(attempts_raw) < 0:
		return _reject("P-01 workbench hint or attempt counter is out of bounds.")
	if not state.get("recheck_dry_verified", false) is bool or not state.get("recheck_wet_verified", false) is bool:
		return _reject("P-01 workbench recheck flags must be booleans.")
	var scan := String(state.get("scan_mode", ""))
	if not scan.is_empty() and scan not in ["sealed_optical", "unrecorded_glance", "unseal_on_bench"]:
		return _reject("P-01 workbench scan_mode is invalid.")
	var preds = state.get("predictions", {})
	if not preds is Dictionary:
		return _reject("P-01 workbench predictions must be a Dictionary.")
	var cassettes_raw = state.get("cassettes", {})
	if not cassettes_raw is Dictionary:
		return _reject("P-01 workbench cassettes must be a Dictionary.")
	var restored_cassettes := {}
	for cid in ["alo", "tara"]:
		var item = cassettes_raw.get(cid, _new_cassette_choice(cid))
		if not item is Dictionary:
			return _reject("P-01 workbench cassette %s must be a Dictionary." % cid)
		var target_c := String(item.get("target_cassette", cid))
		var seeds_val = item.get("seeds", 0)
		var moisture_val = item.get("moisture", -1)
		var drained_val = item.get("drained_to_waste", 0)
		var flooded_val = item.get("flooded", false)
		var seal_val = item.get("seal_closed", false)
		var label_val := String(item.get("label", ""))
		if target_c not in ["alo", "tara"]:
			return _reject("P-01 workbench cassette target_cassette is invalid.")
		for v in [seeds_val, moisture_val, drained_val]:
			if not (v is int or v is float) or not is_finite(float(v)) or float(v) != floor(float(v)):
				return _reject("P-01 workbench cassette numeric field must be an integer.")
		if int(seeds_val) < 0 or int(seeds_val) > 2:
			return _reject("P-01 workbench cassette seeds out of range.")
		if int(moisture_val) < -1 or int(moisture_val) > 100:
			return _reject("P-01 workbench cassette moisture out of range.")
		if int(drained_val) < 0:
			return _reject("P-01 workbench drained_to_waste cannot be negative.")
		if not flooded_val is bool or not seal_val is bool:
			return _reject("P-01 workbench cassette boolean field is invalid.")
		if not label_val.is_empty() and normalize_label(label_val) not in ["EXTERNAL_TEST", "INDOOR_REFERENCE"]:
			return _reject("P-01 workbench cassette label is invalid.")
		restored_cassettes[cid] = {
			"target_cassette": target_c,
			"seeds": int(seeds_val),
			"moisture": int(moisture_val),
			"flooded": bool(flooded_val),
			"drained_to_waste": int(drained_val),
			"label": normalize_label(label_val) if not label_val.is_empty() else "",
			"seal_closed": bool(seal_val),
		}
	_reference_cup = cup
	_zero_offset = int(zero_raw)
	_span_target = int(span_raw)
	_recheck_dry_verified = bool(state.get("recheck_dry_verified", false))
	_recheck_wet_verified = bool(state.get("recheck_wet_verified", false))
	_scan_mode = scan
	_predictions = {
		"EX-CH01-S03": String(preds.get("EX-CH01-S03", "")),
		"EX-CH01-S04": String(preds.get("EX-CH01-S04", "")),
	}
	_cassettes = restored_cassettes
	_hints_revealed = int(hints_raw)
	_attempt_count = int(attempts_raw)
	_last_feedback = state.get("last_feedback", {}).duplicate(true) if state.get("last_feedback", {}) is Dictionary else {}
	return {"accepted": true, "snapshot": snapshot()}

func _ok(reason: String, extra: Dictionary = {}) -> Dictionary:
	var res := {"accepted": true, "reason": reason}
	for k in extra.keys():
		res[k] = extra[k]
	_last_feedback = res.duplicate(true)
	return res

func _feedback(accepted: bool, reason: String, hint_text: String, extra: Dictionary = {}) -> Dictionary:
	var res := {"accepted": accepted, "reason": reason, "hint": hint_text}
	for k in extra.keys():
		res[k] = extra[k]
	_last_feedback = res.duplicate(true)
	return res

func _reject(reason: String) -> Dictionary:
	return _feedback(false, reason, "Check the instrument before trusting it.")
