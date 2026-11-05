extends RefCounted
class_name P01CommissionPlant

## Authoritative P-01 Commission & Plant physical validation and receipt state.
##
## Enforces two-point moisture probe calibration (dry 10 -> 0, wet 110 -> 100,
## recheck 0 and 100), sealed packet optical scan (ALO / N., 2 seeds), paired
## cassette planting (1 seed each in Alo and Tara), calibrated watering in the
## 40–60 band inclusive (50 nominal; flooding > 60 prompts draining excess water
## to waste without harming the seed), distinct labelling (EXTERNAL_TEST for Alo,
## INDOOR_REFERENCE for Tara), and cassette sealing. No default moisture or
## pre-filled answer is ever assumed when watering.

const INITIAL_OFFSET := 10
const DRY_RAW := 10
const WET_RAW := 110
const DRY_TARGET := 0
const WET_TARGET := 100
const MOISTURE_MIN := 40
const MOISTURE_MAX := 60
const MOISTURE_NOMINAL := 50

var _state := {}

func _init() -> void:
	reset_all()

func reset_all() -> void:
	_state = {
		"probe_offset": INITIAL_OFFSET,
		"dry_reference": DRY_RAW,
		"wet_reference": WET_RAW,
		"probe_zeroed": false,
		"probe_spanned": false,
		"probe_rechecked": false,
		"packet_scanned": false,
		"packet": {
			"seal_intact": true,
			"inscription": "ALO",
			"initial": "N.",
			"seed_count": 2,
		},
		"cassettes": {
			"alo": _new_cassette("ALO-01"),
			"tara": _new_cassette("TARA-01"),
		},
		"receipts": {},
	}

func snapshot() -> Dictionary:
	return _state.duplicate(true)

func restore(state: Dictionary) -> Dictionary:
	if not state is Dictionary:
		return _reject("P-01 state must be a Dictionary.")
	for key in ["probe_offset", "dry_reference", "wet_reference", "probe_zeroed", "probe_spanned", "probe_rechecked", "packet_scanned", "packet", "cassettes", "receipts"]:
		if not state.has(key):
			return _reject("P-01 snapshot is missing " + key)
	for number_key in ["probe_offset", "dry_reference", "wet_reference"]:
		var number_value = state.get(number_key, null)
		if not (number_value is int or number_value is float) or not is_finite(float(number_value)) or float(number_value) != floor(float(number_value)):
			return _reject("P-01 numeric field is invalid: " + number_key)
	for flag_key in ["probe_zeroed", "probe_spanned", "probe_rechecked", "packet_scanned"]:
		if not state.get(flag_key, null) is bool:
			return _reject("P-01 boolean field is invalid: " + flag_key)
	if not state.packet is Dictionary or not state.cassettes is Dictionary or not state.receipts is Dictionary:
		return _reject("P-01 nested state has an invalid container type.")
	if not state.packet.get("seal_intact", null) is bool or not state.packet.get("inscription", null) is String or not state.packet.get("initial", null) is String:
		return _reject("P-01 packet metadata is invalid.")
	var packet_seeds = state.packet.get("seed_count", null)
	if not (packet_seeds is int or packet_seeds is float) or not is_finite(float(packet_seeds)) or float(packet_seeds) != floor(float(packet_seeds)) or int(packet_seeds) < 0 or int(packet_seeds) > 2:
		return _reject("P-01 packet seed count is invalid.")
	for cassette_id in ["alo", "tara"]:
		var cassette = state.cassettes.get(cassette_id, null)
		if not cassette is Dictionary:
			return _reject("P-01 snapshot is missing cassette " + cassette_id)
		var expected_individual := "ALO-01" if cassette_id == "alo" else "TARA-01"
		if String(cassette.get("individual_id", "")) != expected_individual or not cassette.get("sealed", null) is bool or not cassette.get("label", null) is String:
			return _reject("P-01 cassette metadata is invalid: " + cassette_id)
		var seeds = cassette.get("seed_count", null)
		var moisture = cassette.get("moisture", null)
		if not (seeds is int or seeds is float) or not is_finite(float(seeds)) or float(seeds) != floor(float(seeds)) or int(seeds) < 0 or int(seeds) > 1:
			return _reject("P-01 cassette seed count is invalid: " + cassette_id)
		if not (moisture is int or moisture is float) or not is_finite(float(moisture)) or float(moisture) != floor(float(moisture)):
			return _reject("P-01 cassette moisture is invalid: " + cassette_id)
		var m := int(moisture)
		var flooded := bool(cassette.get("flooded", false))
		if m != 0 and not flooded and (m < MOISTURE_MIN or m > MOISTURE_MAX):
			return _reject("P-01 cassette moisture is outside the calibrated band: " + cassette_id)
		if flooded and (m <= MOISTURE_MAX or m > 100 or bool(cassette.get("sealed", false))):
			return _reject("P-01 flooded cassette state is invalid: " + cassette_id)
		var label := String(cassette.get("label", ""))
		var expected_label := "EXTERNAL_TEST" if cassette_id == "alo" else "INDOOR_REFERENCE"
		if not label.is_empty() and label != expected_label:
			return _reject("P-01 cassette label is invalid: " + cassette_id)
		if bool(cassette.get("sealed", false)) and (not bool(state.probe_rechecked) or int(seeds) != 1 or m < MOISTURE_MIN or m > MOISTURE_MAX or label != expected_label):
			return _reject("P-01 sealed cassette is incomplete: " + cassette_id)
	_state = state.duplicate(true)
	return {"accepted": true, "snapshot": snapshot()}

func preview(action: String, payload: Dictionary = {}) -> Dictionary:
	return _validate_action(action, payload)

func commit(action: String, command_id: String, payload: Dictionary = {}) -> Dictionary:
	if command_id.is_empty():
		return _reject("P-01 commit requires a command_id.")
	if _state.receipts.has(command_id):
		var receipt: Dictionary = _state.receipts[command_id].duplicate(true)
		receipt["duplicate"] = true
		receipt["snapshot"] = snapshot()
		return receipt
	var check := _validate_action(action, payload)
	if not bool(check.get("accepted", false)):
		if check.get("flooded", false) and check.has("cassette"):
			var cid := String(check.get("cassette", ""))
			if _state.cassettes.has(cid):
				_state.cassettes[cid]["moisture"] = int(check.get("moisture", 0))
				_state.cassettes[cid]["flooded"] = true
				check["snapshot"] = snapshot()
		return check
	match action:
		"set_zero":
			_state.probe_offset = 0
			_state.dry_reference = DRY_TARGET
			_state.wet_reference = WET_TARGET
			_state.probe_zeroed = true
		"set_span":
			_state.wet_reference = WET_TARGET
			_state.probe_spanned = true
		"recheck":
			_state.probe_rechecked = true
		"scan_packet":
			_state.packet_scanned = true
		"plant_alo":
			_state.cassettes.alo.seed_count = 1
		"plant_tara":
			_state.cassettes.tara.seed_count = 1
		"water_alo":
			_state.cassettes.alo.moisture = int(payload.get("moisture"))
			_state.cassettes.alo["flooded"] = false
		"water_tara":
			_state.cassettes.tara.moisture = int(payload.get("moisture"))
			_state.cassettes.tara["flooded"] = false
		"label_alo_external":
			_state.cassettes.alo.label = "EXTERNAL_TEST"
		"label_tara_indoor":
			_state.cassettes.tara.label = "INDOOR_REFERENCE"
		"seal_alo":
			_state.cassettes.alo.sealed = true
		"seal_tara":
			_state.cassettes.tara.sealed = true
	var result := {
		"accepted": true,
		"duplicate": false,
		"action": action,
		"command_id": command_id,
		"reason": String(check.get("reason", "P-01 action committed.")),
		"observe": String(check.get("observe", "")),
		"explain": String(check.get("explain", "")),
		"completion": completion(),
		"snapshot": snapshot(),
	}
	var stored := result.duplicate(true)
	stored.erase("snapshot")
	_state.receipts[command_id] = stored
	return result

## Drains excess water from a flooded cassette (`> 60`) into the waste line so
## moisture returns to `target_moisture` (`40..60`, default `50`) without
## harming the seed.
func drain_water(cassette_id: String, target_moisture: int = MOISTURE_NOMINAL) -> Dictionary:
	if not _state.cassettes.has(cassette_id):
		return _reject("Unknown cassette: " + cassette_id)
	var cassette: Dictionary = _state.cassettes[cassette_id]
	if bool(cassette.get("sealed", false)):
		return _reject("Cannot drain a sealed cassette.")
	var current := int(cassette.get("moisture", 0))
	var dest := clampi(target_moisture, MOISTURE_MIN, MOISTURE_MAX)
	cassette["moisture"] = dest
	cassette["flooded"] = false
	_state.cassettes[cassette_id] = cassette
	return {
		"accepted": true,
		"cassette": cassette_id,
		"drained_from": current,
		"moisture": dest,
		"reason": "Drained excess water from %s cassette to waste; moisture is now %d units and the seed is unharmed." % [cassette_id.capitalize(), dest],
		"snapshot": snapshot(),
	}

## Resets an unsealed cassette without destroying any seed, clearing unsettled
## receipts for that cassette so it can be re-commissioned cleanly.
func reset_cassette(cassette_id: String) -> Dictionary:
	if not _state.cassettes.has(cassette_id):
		return _reject("Unknown cassette: " + cassette_id)
	if bool(_state.cassettes[cassette_id].get("sealed", false)):
		return _reject("Sealed cassettes cannot be reset without breaking the sterile seal.")
	var individual_id := String(_state.cassettes[cassette_id].get("individual_id", ""))
	_state.cassettes[cassette_id] = _new_cassette(individual_id)
	for prefix in ["p01:plant_", "p01:water_", "p01:label_"]:
		_state.receipts.erase(prefix + cassette_id)
	return {
		"accepted": true,
		"cassette": cassette_id,
		"reason": "Unsealed %s cassette reset without losing a seed." % cassette_id.capitalize(),
		"snapshot": snapshot(),
	}

func completion() -> Dictionary:
	var alo: Dictionary = _state.cassettes.alo
	var tara: Dictionary = _state.cassettes.tara
	var calibrated := bool(_state.probe_zeroed) and bool(_state.probe_spanned) and bool(_state.probe_rechecked) and int(_state.dry_reference) == DRY_TARGET and int(_state.wet_reference) == WET_TARGET
	var seeds_ok := int(alo.seed_count) == 1 and int(tara.seed_count) == 1
	var moisture_ok := _moisture_in_band(int(alo.moisture)) and _moisture_in_band(int(tara.moisture)) and not bool(alo.get("flooded", false)) and not bool(tara.get("flooded", false))
	var labels_ok := String(alo.label) == "EXTERNAL_TEST" and String(tara.label) == "INDOOR_REFERENCE"
	var seals_ok := bool(alo.sealed) and bool(tara.sealed)
	return {
		"complete": calibrated and bool(_state.packet_scanned) and seeds_ok and moisture_ok and labels_ok and seals_ok,
		"calibrated": calibrated,
		"packet_scanned": bool(_state.packet_scanned),
		"seeds_ok": seeds_ok,
		"moisture_ok": moisture_ok,
		"labels_ok": labels_ok,
		"seals_ok": seals_ok,
	}

func _validate_action(action: String, payload: Dictionary) -> Dictionary:
	match action:
		"set_zero":
			if payload.has("reference_cup") and String(payload.get("reference_cup", "")).to_lower() != "dry":
				return _reject(
					"Zero calibration must use the dry reference cup (reading 10 -> 0), not the wet reference cup.",
					"Use the two reference cups: dip into the dry reference cup first and zero the +10 offset to 0."
				)
			if payload.has("zero_offset") and int(payload.get("zero_offset", 0)) != -INITIAL_OFFSET:
				var offset := int(payload.get("zero_offset", 0))
				var reading := DRY_RAW + offset
				return _reject(
					"Zero offset %+d leaves the dry reference cup reading %d units instead of 0. Set Zero Offset to -10 so the dry cup reads 0." % [offset, reading],
					"Check the instrument before trusting it: the probe has a +10 offset, so dry must read 0."
				)
			if payload.has("dry_reading") and int(payload.get("dry_reading", -1)) != DRY_TARGET:
				return _reject(
					"Dry reference cup still reads %d units. Adjust the zero offset to -10 so the dry cup reads 0." % int(payload.get("dry_reading", -1)),
					"Dry must read 0, wet 100, then fill both to 50."
				)
			return _accept(
				"Probe zero set on dry reference (10 -> 0).",
				"Dry reference cup reading drops from 10 to 0 displayed units.",
				"Zeroing removes the +10 additive offset at the bone-dry lower bound."
			)
		"set_span":
			if not bool(_state.probe_zeroed):
				return _reject(
					"Set dry reference zero (10 -> 0) before adjusting wet span.",
					"Check the instrument before trusting it: zero the dry reference cup to 0 first."
				)
			if payload.has("reference_cup") and String(payload.get("reference_cup", "")).to_lower() not in ["wet", "dry"]:
				return _reject("Select the wet reference cup to set the 100-unit span.", "Use the two reference cups.")
			if payload.has("span_target") and int(payload.get("span_target", 0)) != WET_TARGET:
				return _reject(
					"Wet reference span is set to %d units instead of 100. Adjust Wet Span to 100 on the wet reference cup." % int(payload.get("span_target", 0)),
					"Use the two reference cups: wet reference must read 100."
				)
			if payload.has("wet_reading") and int(payload.get("wet_reading", 0)) != WET_TARGET:
				return _reject(
					"Wet reference cup reads %d units instead of 100. Set the wet span to 100." % int(payload.get("wet_reading", 0)),
					"Dry must read 0, wet 100, then fill both to 50."
				)
			return _accept(
				"Probe span set on wet reference (110 -> 100).",
				"Wet reference cup reading settles at 100 displayed units.",
				"Span calibration anchors the saturated upper bound at 100 units."
			)
		"recheck":
			if not bool(_state.probe_zeroed) or not bool(_state.probe_spanned):
				return _reject(
					"Zero (dry = 0) and span (wet = 100) the probe before running the two-point recheck.",
					"Use the two reference cups: zero dry to 0 and span wet to 100 first."
				)
			if payload.has("both_cups_checked") and not bool(payload.get("both_cups_checked", false)):
				return _reject(
					"Two-point recheck incomplete: verify both the dry reference cup (0) and the wet reference cup (100).",
					"Use the two reference cups: check both dry = 0 and wet = 100."
				)
			if (payload.has("recheck_dry") and int(payload.get("recheck_dry", -1)) != DRY_TARGET) or (payload.has("recheck_wet") and int(payload.get("recheck_wet", -1)) != WET_TARGET):
				return _reject(
					"Recheck readings do not match dry = 0 and wet = 100. Verify both reference cups.",
					"Dry must read 0, wet 100, then fill both to 50."
				)
			return _accept(
				"Probe rechecked against dry = 0 and wet = 100.",
				"Dry cup holds 0 and wet cup holds 100 with zero drift.",
				"Two-point recheck confirms instrument repeatability before measuring live cassettes."
			)
		"scan_packet":
			if not bool(_state.probe_rechecked):
				return _reject(
					"Complete the two-point probe calibration recheck (dry = 0, wet = 100) before scanning the seed packet.",
					"Check the instrument before trusting it."
				)
			if payload.has("scan_mode"):
				var mode := String(payload.get("scan_mode", ""))
				if mode.is_empty():
					return _reject(
						"Select Optical Scan Through Intact Seal to inspect the seed packet and record its provenance.",
						"Scan the sealed packet optically to record ALO, N., and 2 seeds."
					)
				if mode == "unseal_on_bench":
					return _reject(
						"Do not break the packet seal on the open bench. Use Optical Scan Through Intact Seal to keep the 2 seeds protected.",
						"Keep the packet sealed until placing each seed into its cassette."
					)
				if mode != "sealed_optical":
					return _reject(
						"Incomplete packet scan: select Optical Scan Through Intact Seal so ALO, N., and 2 seeds are logged.",
						"Record the Latin inscription ALO and initial N. before planting."
					)
			if payload.has("inscription") and String(payload.get("inscription", "")) != "ALO":
				return _reject("Packet inscription must record ALO in Latin letters.", "Scan the sealed packet to log ALO and N.")
			return _accept(
				"Sealed packet scanned: ALO and N., 2 seeds.",
				"Optical scanner logs Latin inscription ALO, initial N., and 2 intact seeds.",
				"Non-destructive optical scanning preserves sterile containment until planting."
			)
		"plant_alo", "plant_tara":
			var id := "alo" if action == "plant_alo" else "tara"
			var other_id := "tara" if id == "alo" else "alo"
			if not bool(_state.packet_scanned):
				return _reject(
					"Scan the sealed packet (ALO / N., 2 seeds) before placing seeds.",
					"Complete the packet scan in Commons before planting."
				)
			if int(_state.cassettes[id].seed_count) >= 1:
				return _reject(
					"The %s cassette is already occupied (1 seed placed). Use the %s cassette for the remaining seed." % [id.capitalize(), other_id.capitalize()],
					"Place 1 seed in Alo and 1 seed in Tara."
				)
			if payload.has("target_cassette") and String(payload.get("target_cassette", "")) != id:
				var chosen := String(payload.get("target_cassette", ""))
				if chosen in ["alo", "tara"] and int(_state.cassettes[chosen].seed_count) >= 1:
					return _reject(
						"The %s cassette is already occupied (1 seed placed). Select the %s cassette for this operation." % [chosen.capitalize(), id.capitalize()],
						"Each cassette holds 1 seed: 1 in Alo and 1 in Tara."
					)
				return _reject(
					"This operation commissions the %s cassette. Select the %s cassette to place 1 seed." % [id.capitalize(), id.capitalize()],
					"Place 1 seed in Alo and 1 seed in Tara."
				)
			if payload.has("seeds"):
				var seeds := int(payload.get("seeds", 0))
				if seeds <= 0:
					return _reject(
						"Select 1 seed from the packet to place into the %s cassette." % id.capitalize(),
						"Place 1 seed in Alo and 1 seed in Tara."
					)
				if seeds > 1:
					return _reject(
						"Duplicate seed blocked: placing %d seeds in the %s cassette would overcrowd it and leave the %s cassette empty. Place 1 seed per cassette." % [seeds, id.capitalize(), other_id.capitalize()],
						"Each sealed cassette takes exactly 1 seed."
					)
			return _accept(
				"One seed placed in the %s cassette." % id.capitalize(),
				"1 Brassica rapa seed is seated in the %s cassette wicking pillow." % id.capitalize(),
				"Single-seed placement prevents root competition and preserves the paired reference."
			)
		"water_alo", "water_tara":
			var id := "alo" if action == "water_alo" else "tara"
			if not bool(_state.probe_rechecked):
				return _reject(
					"Calibrate and recheck the moisture probe (dry = 0, wet = 100) before watering.",
					"Check the instrument before trusting it."
				)
			if int(_state.cassettes[id].seed_count) != 1:
				return _reject(
					"Place one seed in the %s cassette before adding water." % id.capitalize(),
					"Plant 1 seed in each cassette before watering."
				)
			var raw_moisture = payload.get("moisture", null)
			if not (raw_moisture is int or raw_moisture is float) or not is_finite(float(raw_moisture)) or float(raw_moisture) != floor(float(raw_moisture)):
				return _reject(
					"Select a calibrated moisture level (40 to 60 units; 50 nominal) for the %s cassette before committing." % id.capitalize(),
					"Dry must read 0, wet 100, then fill both to 50."
				)
			var moisture := int(raw_moisture)
			if moisture < MOISTURE_MIN:
				return _reject(
					"Moisture %d is too dry for the %s cassette (calibrated band is 40 to 60 inclusive; 50 nominal). Add water to reach 40–60." % [moisture, id.capitalize()],
					"Dry must read 0, wet 100, then fill both to 50.",
					{"cassette": id, "moisture": moisture, "too_dry": true}
				)
			if moisture > MOISTURE_MAX:
				return _reject(
					"Moisture %d floods the %s cassette (above the 40 to 60 band). The seed is unharmed — drain excess water to waste to bring moisture into 40–60 (50 nominal) before sealing." % [moisture, id.capitalize()],
					"Flooding (> 60) does not kill the seed: use Drain Excess to Waste to return moisture to 40–60 (50 nominal).",
					{"cassette": id, "moisture": moisture, "flooded": true, "requires_drain": true}
				)
			return _accept(
				"%s cassette watered to %d (within the 40–60 calibrated band)." % [id.capitalize(), moisture],
				"Calibrated probe reads %d units in the %s cassette." % [moisture, id.capitalize()],
				"Maintaining 40–60 moisture (50 nominal) balances capillary water delivery and root aeration in 0.166 g.",
				{"cassette": id, "moisture": moisture}
			)
		"label_alo_external", "label_tara_indoor":
			var id := "alo" if action == "label_alo_external" else "tara"
			var other_id := "tara" if id == "alo" else "alo"
			var expected := "EXTERNAL_TEST" if id == "alo" else "INDOOR_REFERENCE"
			var expected_display := "EXTERNAL TEST" if id == "alo" else "INDOOR REFERENCE"
			var raw_label := String(payload.get("label", expected if not payload.has("label") else ""))
			var label := raw_label.strip_edges().to_upper().replace(" ", "_")
			if not bool(_state.probe_rechecked) or int(_state.cassettes[id].seed_count) != 1 or not _moisture_in_band(int(_state.cassettes[id].moisture)) or bool(_state.cassettes[id].get("flooded", false)):
				return _reject(
					"Complete calibration, 1-seed placement, and 40–60 calibrated watering before labelling the %s cassette." % id.capitalize(),
					"Dry must read 0, wet 100, then fill both to 50."
				)
			if label.is_empty():
				return _reject(
					"Select the %s label for the %s cassette before committing." % [expected_display, id.capitalize()],
					"Label Alo EXTERNAL TEST and Tara INDOOR REFERENCE."
				)
			if label != expected:
				var other_label := String(_state.cassettes[other_id].get("label", ""))
				var chosen_display := label.replace("_", " ")
				if other_label == label:
					return _reject(
						"Duplicate label blocked: the %s cassette already holds %s. Assign %s to the %s cassette so the paired experiment has one external test and one indoor reference." % [other_id.capitalize(), chosen_display, expected_display, id.capitalize()],
						"Each cassette needs a distinct label: Alo is EXTERNAL TEST and Tara is INDOOR REFERENCE."
					)
				return _reject(
					"%s must take the distinct label %s (not %s). The %s cassette is reserved for %s." % [id.capitalize(), expected_display, chosen_display, other_id.capitalize(), chosen_display],
					"Label Alo EXTERNAL TEST and Tara INDOOR REFERENCE."
				)
			return _accept(
				"%s cassette labelled %s." % [id.capitalize(), expected_display],
				"Cassette %s tag is locked as %s." % [id.capitalize(), expected_display],
				"Distinct labels prevent crew logs and telemetry from confusing the external test specimen with the indoor reference."
			)
		"seal_alo", "seal_tara":
			var id := "alo" if action == "seal_alo" else "tara"
			var expected_label := "EXTERNAL_TEST" if id == "alo" else "INDOOR_REFERENCE"
			var cassette: Dictionary = _state.cassettes[id]
			if not bool(_state.probe_rechecked):
				return _reject(
					"Cannot seal the %s cassette until the moisture probe is calibrated and rechecked (dry = 0, wet = 100)." % id.capitalize(),
					"Check the instrument before trusting it."
				)
			if int(cassette.seed_count) != 1:
				return _reject(
					"Cannot seal the %s cassette before placing 1 seed." % id.capitalize(),
					"Place 1 seed in each cassette before sealing."
				)
			if bool(cassette.get("flooded", false)) or int(cassette.moisture) > MOISTURE_MAX:
				return _reject(
					"Cannot seal the %s cassette while flooded (%d units > 60). Drain excess water to waste until moisture is in 40–60." % [id.capitalize(), int(cassette.moisture)],
					"Drain excess water to waste so moisture reads 40–60 (50 nominal) before sealing."
				)
			if not _moisture_in_band(int(cassette.moisture)):
				return _reject(
					"Cannot seal the %s cassette until moisture is within the calibrated 40–60 band (50 nominal)." % id.capitalize(),
					"Dry must read 0, wet 100, then fill both to 50."
				)
			if String(cassette.label) != expected_label:
				return _reject(
					"Cannot seal the %s cassette before assigning its distinct label (%s)." % [id.capitalize(), expected_label.replace("_", " ")],
					"Label Alo EXTERNAL TEST and Tara INDOOR REFERENCE before sealing."
				)
			if payload.has("seal_closed") and not bool(payload.get("seal_closed", false)):
				return _reject(
					"Switch the %s cassette seal to CLOSED & LOCKED before committing." % id.capitalize(),
					"Close both cassette seals to complete P-01."
				)
			return _accept(
				"%s cassette seal closed." % id.capitalize(),
				"%s cassette seal locks shut with 1 seed, %d moisture, and %s label." % [id.capitalize(), int(cassette.moisture), expected_label.replace("_", " ")],
				"Sealing locks the cassette's internal atmosphere and moisture loop for the chamber run."
			)
	return _reject("Unknown P-01 action: " + action)

func _moisture_in_band(value: int) -> bool:
	return value >= MOISTURE_MIN and value <= MOISTURE_MAX

func _new_cassette(individual_id: String) -> Dictionary:
	return {
		"individual_id": individual_id,
		"seed_count": 0,
		"moisture": 0,
		"flooded": false,
		"label": "",
		"sealed": false,
	}

func _accept(reason: String, observe: String = "", explain: String = "", extra: Dictionary = {}) -> Dictionary:
	var res := {
		"accepted": true,
		"reason": reason,
		"observe": observe,
		"explain": explain,
		"snapshot": snapshot(),
	}
	for k in extra.keys():
		res[k] = extra[k]
	return res

func _reject(reason: String, hint: String = "Check the instrument before trusting it.", extra: Dictionary = {}) -> Dictionary:
	var res := {
		"accepted": false,
		"reason": reason,
		"hint": hint,
		"snapshot": snapshot(),
	}
	for k in extra.keys():
		res[k] = extra[k]
	return res
