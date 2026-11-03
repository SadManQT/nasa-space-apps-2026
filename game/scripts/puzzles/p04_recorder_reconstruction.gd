extends RefCounted
class_name P04RecorderReconstruction

const EXPECTED := {"date": "2034-04", "device": "HORT-01", "channel": "ENGINEERING"}

var _mapping := {}
var _checksum_verified := false
var _transcript_opened := false
var _engineer_played := false
var _n_clue_played := false
var _classified := false
var _copy_sent := false
var _handover_acknowledged := false

func preview_action(action: String, payload: Dictionary = {}) -> Dictionary:
	match action:
		"p04_assign_date", "p04_assign_device", "p04_assign_channel":
			var field := action.trim_prefix("p04_assign_")
			var value := String(payload.get("value", ""))
			if value != String(EXPECTED[field]):
				return _reject("The %s token does not match its source label." % field)
			return _accept("Verified %s token is ready." % field)
		"p04_verify_checksum":
			if not _mapping_complete(): return _reject("Match date, device and channel before checking the local copy.")
		"p04_open_transcript":
			if not _mapping_complete(): return _reject("The transcript stays locked until the metadata mapping is complete.")
		"p04_play_engineer":
			if not _mapping_complete() or not _checksum_verified or not _transcript_opened: return _reject("Verify and open the reconstructed local copy first.")
		"p04_play_n":
			if not _engineer_played: return _reject("Read the dated engineering fragment before the paired memory note.")
		"p04_classify_inference":
			if not _engineer_played or not _n_clue_played: return _reject("Hear both source-labelled fragments before classifying the inference.")
		"p04_send_copy":
			if not _classified: return _reject("Keep voice resemblance as an inference before sending the evidence.")
		"p04_ack_handover":
			if not _copy_sent: return _reject("Send the intact copy before acknowledging the handover.")
	return _accept("P-04 action is ready.")

func commit_action(action: String, payload: Dictionary = {}) -> Dictionary:
	var check := preview_action(action, payload)
	if not bool(check.get("accepted", false)): return check
	match action:
		"p04_assign_date", "p04_assign_device", "p04_assign_channel": _mapping[action.trim_prefix("p04_assign_")] = String(payload.get("value", ""))
		"p04_verify_checksum": _checksum_verified = true
		"p04_open_transcript": _transcript_opened = true
		"p04_play_engineer": _engineer_played = true
		"p04_play_n": _n_clue_played = true
		"p04_classify_inference": _classified = true
		"p04_send_copy": _copy_sent = true
		"p04_ack_handover": _handover_acknowledged = true
	return _accept("P-04 action recorded once.")

func flags() -> Dictionary:
	return {
		"p04_mapping_complete": _mapping_complete(),
		"p04_checksum_verified": _checksum_verified,
		"p04_transcript_opened": _transcript_opened,
		"p04_engineer_played": _engineer_played,
		"p04_n_clue_played": _n_clue_played,
		"p04_inference_classified": _classified,
		"p04_copy_sent": _copy_sent,
		"p04_handover_acknowledged": _handover_acknowledged,
		"p04_complete": _mapping_complete() and _checksum_verified and _transcript_opened and _engineer_played and _n_clue_played and _classified and _copy_sent and _handover_acknowledged,
	}

func snapshot() -> Dictionary:
	return {"schema_version": 1, "mapping": _mapping.duplicate(true), "checksum_verified": _checksum_verified, "transcript_opened": _transcript_opened, "engineer_played": _engineer_played, "n_clue_played": _n_clue_played, "classified": _classified, "copy_sent": _copy_sent, "handover_acknowledged": _handover_acknowledged}

func restore(data: Dictionary) -> Dictionary:
	if not data is Dictionary or int(data.get("schema_version", 1)) != 1: return {"accepted": false, "reason": "P-04 snapshot is incompatible."}
	_mapping = data.get("mapping", {}).duplicate(true)
	_checksum_verified = bool(data.get("checksum_verified", false))
	_transcript_opened = bool(data.get("transcript_opened", false))
	_engineer_played = bool(data.get("engineer_played", false))
	_n_clue_played = bool(data.get("n_clue_played", false))
	_classified = bool(data.get("classified", false))
	_copy_sent = bool(data.get("copy_sent", false))
	_handover_acknowledged = bool(data.get("handover_acknowledged", false))
	return {"accepted": true, "reason": "P-04 restored."}

func _mapping_complete() -> bool:
	for key in EXPECTED.keys():
		if String(_mapping.get(key, "")) != String(EXPECTED[key]): return false
	return true

func _accept(reason: String) -> Dictionary: return {"accepted": true, "duplicate": false, "reason": reason}
func _reject(reason: String) -> Dictionary: return {"accepted": false, "duplicate": false, "reason": reason}
