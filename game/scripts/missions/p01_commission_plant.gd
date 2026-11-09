extends RefCounted
class_name P01CommissionPlant

## P-01 physical sequence adapter. The authoritative campaign command is
## emitted by InteractionDispatcher; this object only validates the reversible
## order and stores primitive contact/progress state.

const ORDER := [
	"set_zero",
	"set_span",
	"recheck",
	"scan_packet",
	"plant_alo",
	"plant_tara",
	"water_alo",
	"water_tara",
	"label_alo_external",
	"label_tara_indoor",
	"seal_alo",
	"seal_tara",
]

const PROFILE_PATH := "res://resources/campaign/profiles/p01_commission_plant.json"
var _profile: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PROFILE_PATH))

func view() -> Dictionary:
	return {"contract_version": _profile.contract_version, "profile": _profile.duplicate(true), "state": snapshot(), "completion": completion()}

var _state := {
	"probe_zeroed": false,
	"probe_spanned": false,
	"probe_rechecked": false,
	"packet_scanned": false,
	"cassette_alo_seed_count": 0,
	"cassette_tara_seed_count": 0,
	"moisture_alo": 0.0,
	"moisture_tara": 0.0,
	"alo_label": "",
	"tara_label": "",
	"alo_sealed": false,
	"tara_sealed": false,
	"receipts": {},
}

func snapshot() -> Dictionary:
	return _state.duplicate(true)

func restore(snapshot_data: Dictionary) -> Dictionary:
	for key in _state:
		if not snapshot_data.has(key):
			return {"accepted": false, "reason": "P-01 snapshot is missing " + key}
		var value = snapshot_data[key]
		if key in ["moisture_alo", "moisture_tara", "cassette_alo_seed_count", "cassette_tara_seed_count"]:
			if not _finite_number(value) or float(value) < float(_profile.scale_min):
				return {"accepted": false, "reason": "P-01 numeric state is invalid."}
			if key.begins_with("cassette_") and float(value) != floor(float(value)):
				return {"accepted": false, "reason": "P-01 seed counts must be whole numbers."}
		elif typeof(value) != typeof(_state[key]):
			return {"accepted": false, "reason": "P-01 snapshot has an invalid type for " + key}
	if float(snapshot_data.cassette_alo_seed_count) > float(_profile.seeds_per_cassette) or float(snapshot_data.cassette_tara_seed_count) > float(_profile.seeds_per_cassette) or float(snapshot_data.moisture_alo) > float(_profile.scale_max) or float(snapshot_data.moisture_tara) > float(_profile.scale_max):
		return {"accepted": false, "reason": "P-01 cassette values are outside their bounds."}
	for receipt in snapshot_data.receipts.values():
		if not receipt is Dictionary:
			return {"accepted": false, "reason": "P-01 receipts must contain Dictionaries."}
	_state = snapshot_data.duplicate(true)
	for key in ["cassette_alo_seed_count", "cassette_tara_seed_count"]:
		_state[key] = int(_state[key])
	for key in ["moisture_alo", "moisture_tara"]:
		_state[key] = float(_state[key])
	for receipt in _state.receipts.values():
		receipt.erase("state")
	return {"accepted": true, "snapshot": snapshot()}

func preview(action: String, payload: Dictionary = {}) -> Dictionary:
	var check := _validate(action, payload)
	if not bool(check.get("accepted", false)):
		return check
	var projected := _state.duplicate(true)
	_apply_to(projected, action, payload)
	return {
		"accepted": true,
		"duplicate": false,
		"action": action,
		"state": projected,
		"completion": _is_complete(projected),
		"warnings": ["P-01 PREVIEW ONLY · no cassette or plant state changed"],
	}

func commit(action: String, command_id: String, payload: Dictionary = {}) -> Dictionary:
	if command_id.is_empty():
		return {"accepted": false, "duplicate": false, "reason": "P-01 requires a stable command_id."}
	var receipts: Dictionary = _state.get("receipts", {})
	if receipts.has(command_id):
		var duplicate: Dictionary = receipts[command_id].duplicate(true)
		duplicate["duplicate"] = true
		duplicate["state"] = snapshot()
		return duplicate
	var check := _validate(action, payload)
	if not bool(check.get("accepted", false)):
		return check
	var next := _state.duplicate(true)
	_apply_to(next, action, payload)
	var result := {
		"accepted": true,
		"duplicate": false,
		"command_id": command_id,
		"action": action,
		"completion": _is_complete(next),
		"state": next.duplicate(true),
		"reason": "P-01 physical step committed once.",
	}
	var receipt := result.duplicate(true)
	receipt.erase("state")
	next["receipts"][command_id] = receipt
	_state = next
	return result.duplicate(true)

func completion() -> Dictionary:
	return {
		"complete": _is_complete(_state),
		"calibrated": bool(_state.probe_rechecked),
		"seeds": int(_state.cassette_alo_seed_count) == 1 and int(_state.cassette_tara_seed_count) == 1,
		"moisture_in_band": _in_band(float(_state.moisture_alo)) and _in_band(float(_state.moisture_tara)),
		"labels_distinct": String(_state.alo_label) == "EXTERNAL_TEST" and String(_state.tara_label) == "INDOOR_REFERENCE",
		"sealed": bool(_state.alo_sealed) and bool(_state.tara_sealed),
	}

func _validate(action: String, payload: Dictionary) -> Dictionary:
	if not ORDER.has(action):
		return _reject("Unknown P-01 action; no planting state changed.")
	if _state.get("receipts", {}).values().size() > 0 and _is_action_done(action):
		return _reject("P-01 action already completed; duplicate input cannot spend or plant twice.")
	match action:
		"set_zero":
			if bool(_state.probe_zeroed): return _reject("Dry reference zero is already set.")
			if not _reference_matches(payload, "dry"): return _reject("Select the dry reference: raw 10 must read 0 after zeroing.")
		"set_span":
			if not bool(_state.probe_zeroed): return _reject("Set zero with the dry reference before wet span.")
			if not _reference_matches(payload, "wet"): return _reject("Select the wet reference: raw 110 must read 100 after setting span.")
		"recheck":
			if not bool(_state.probe_spanned): return _reject("Set wet span before rechecking both references.")
			if not _number_matches(payload.get("dry_reading"), _profile.references.dry.calibrated) or not _number_matches(payload.get("wet_reading"), _profile.references.wet.calibrated): return _reject("Explicitly recheck both references: dry 0 and wet 100.")
		"scan_packet":
			if not bool(_state.probe_rechecked): return _reject("Recheck dry=0 and wet=100 before scanning the packet.")
		"plant_alo":
			if not bool(_state.packet_scanned): return _reject("Scan the sealed seed packet before placing Alo.")
			if int(_state.cassette_alo_seed_count) >= 1: return _reject("The Alo cassette is already occupied.")
			if payload.get("cassette") != "alo" or not _number_matches(payload.get("seed_count"), _profile.seeds_per_cassette): return _reject("Select the Alo cassette and place exactly one seed.")
		"plant_tara":
			if not bool(_state.packet_scanned): return _reject("Scan the sealed seed packet before placing Tara.")
			if int(_state.cassette_tara_seed_count) >= 1: return _reject("The Tara cassette is already occupied.")
			if payload.get("cassette") != "tara" or not _number_matches(payload.get("seed_count"), _profile.seeds_per_cassette): return _reject("Select the Tara cassette and place exactly one seed.")
		"water_alo", "water_tara":
			if not _finite_number(payload.get("moisture")): return _reject("Choose a finite calibrated moisture reading before adding water.")
			var moisture := float(payload.moisture)
			if not _in_band(moisture): return _reject("Calibrated moisture must be between 40 and 60; drain excess to waste and retry.")
			if action == "water_alo" and int(_state.cassette_alo_seed_count) != 1: return _reject("Place one seed in the Alo cassette first.")
			if action == "water_tara" and int(_state.cassette_tara_seed_count) != 1: return _reject("Place one seed in the Tara cassette first.")
		"label_alo_external":
			if int(_state.cassette_alo_seed_count) != 1 or not _in_band(float(_state.moisture_alo)): return _reject("Alo must have one seed and calibrated moisture before labeling.")
			if not payload.get("label") is String or payload.label != _profile.labels.alo: return _reject("Alo grows in the outer chamber. Choose the External test label.")
			if not String(_state.alo_label).is_empty(): return _reject("The Alo cassette already has a label.")
		"label_tara_indoor":
			if int(_state.cassette_tara_seed_count) != 1 or not _in_band(float(_state.moisture_tara)): return _reject("Tara must have one seed and calibrated moisture before labeling.")
			if not payload.get("label") is String or payload.label != _profile.labels.tara: return _reject("Tara stays indoors for comparison. Choose the Indoor reference label.")
			if not String(_state.tara_label).is_empty(): return _reject("The Tara cassette already has a label.")
		"seal_alo":
			if String(_state.alo_label) != _profile.labels.alo: return _reject("Label Alo EXTERNAL TEST before sealing.")
			if bool(_state.alo_sealed): return _reject("The Alo seal is already closed.")
		"seal_tara":
			if String(_state.tara_label) != _profile.labels.tara: return _reject("Label Tara INDOOR REFERENCE before sealing.")
			if bool(_state.tara_sealed): return _reject("The Tara seal is already closed.")
	return {"accepted": true}

func _apply_to(target: Dictionary, action: String, payload: Dictionary) -> void:
	match action:
		"set_zero": target["probe_zeroed"] = true
		"set_span": target["probe_spanned"] = true
		"recheck": target["probe_rechecked"] = true
		"scan_packet": target["packet_scanned"] = true
		"plant_alo": target["cassette_alo_seed_count"] = 1
		"plant_tara": target["cassette_tara_seed_count"] = 1
		"water_alo": target["moisture_alo"] = float(payload.moisture)
		"water_tara": target["moisture_tara"] = float(payload.moisture)
		"label_alo_external": target["alo_label"] = String(payload.label)
		"label_tara_indoor": target["tara_label"] = String(payload.label)
		"seal_alo": target["alo_sealed"] = true
		"seal_tara": target["tara_sealed"] = true

func _is_action_done(action: String) -> bool:
	match action:
		"set_zero": return bool(_state.probe_zeroed)
		"set_span": return bool(_state.probe_spanned)
		"recheck": return bool(_state.probe_rechecked)
		"scan_packet": return bool(_state.packet_scanned)
		"plant_alo": return int(_state.cassette_alo_seed_count) == 1
		"plant_tara": return int(_state.cassette_tara_seed_count) == 1
		"water_alo": return int(_state.moisture_alo) > 0
		"water_tara": return int(_state.moisture_tara) > 0
		"label_alo_external": return not String(_state.alo_label).is_empty()
		"label_tara_indoor": return not String(_state.tara_label).is_empty()
		"seal_alo": return bool(_state.alo_sealed)
		"seal_tara": return bool(_state.tara_sealed)
	return false

func _is_complete(state: Dictionary) -> bool:
	return bool(state.get("probe_rechecked", false)) and bool(state.get("packet_scanned", false)) and int(state.get("cassette_alo_seed_count", 0)) == 1 and int(state.get("cassette_tara_seed_count", 0)) == 1 and _in_band(float(state.get("moisture_alo", 0))) and _in_band(float(state.get("moisture_tara", 0))) and String(state.get("alo_label", "")) == _profile.labels.alo and String(state.get("tara_label", "")) == _profile.labels.tara and bool(state.get("alo_sealed", false)) and bool(state.get("tara_sealed", false))

func _in_band(value: float) -> bool:
	return value >= float(_profile.moisture_min) and value <= float(_profile.moisture_max)

func _finite_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

func _number_matches(value: Variant, expected: Variant) -> bool:
	return _finite_number(value) and float(value) == float(expected)

func _reference_matches(payload: Dictionary, reference: String) -> bool:
	var reading: Dictionary = _profile.references[reference]
	return payload.get("reference") == reference and _number_matches(payload.get("raw_reading"), reading.raw) and _number_matches(payload.get("calibrated_reading"), reading.calibrated)

func _reject(reason: String) -> Dictionary:
	return {"accepted": false, "duplicate": false, "reason": reason, "state": snapshot()}
