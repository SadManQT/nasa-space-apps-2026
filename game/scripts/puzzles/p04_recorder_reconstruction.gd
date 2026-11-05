extends RefCounted
class_name P04RecorderReconstruction

## Interactive rule and state model for Chapter 2 Puzzle P-04 (Recorder Reconstruction).
## All metadata tokens, photographed bench source cards, label/person rules,
## transcripts, Observed / Inferred / Unknown classification claims, clues, and
## progressive hints live in res://resources/campaign/content/p04_recorder_reconstruction.json.

const CONTENT_PATH := "res://resources/campaign/content/p04_recorder_reconstruction.json"

static var _content_cache: Dictionary = {}

var _mapping: Dictionary = {}
var _board_slots: Dictionary = {"date": "", "device": "", "channel": ""}
var _label_handling := "photograph_in_place"
var _person_slot := "blank_unknown"
var _classifications: Dictionary = {
	"retreat_2034": "",
	"voice_resembles_ferreira": "",
	"writer_n_identity": "",
}
var _checksum_verified := false
var _transcript_opened := false
var _engineer_played := false
var _n_clue_played := false
var _classified := false
var _copy_sent := false
var _handover_acknowledged := false
var _shared_clues: Array[String] = []
var _hint_tier: Dictionary = {"metadata": 0, "classification": 0}
var _last_feedback := ""
var _worked_plan_active := false

## Loads the P-04 interactive content definition from JSON.
static func data() -> Dictionary:
	if _content_cache.is_empty():
		var file := FileAccess.open(CONTENT_PATH, FileAccess.READ)
		if file != null:
			var parsed = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				_content_cache = parsed
	return _content_cache.duplicate(true)

## Returns true when `action` belongs to P-04.
static func is_p04_action(action: String) -> bool:
	return action.begins_with("p04_")

## Places a metadata token into `field` (`date`, `device`, or `channel`) on the Reconstruction Board.
## Wrong tokens remain placed and removable while reporting which photographed source card disagrees.
func set_slot_token(field: String, value: String) -> Dictionary:
	var key := field.strip_edges()
	var expected_map: Dictionary = data().get("expected_tokens", {})
	if not expected_map.has(key):
		return _reject("Unknown metadata slot field: " + key)
	var chosen := value.strip_edges()
	_board_slots[key] = chosen
	if _mapping.has(key) and chosen != String(expected_map.get(key, "")):
		_mapping.erase(key)
		_checksum_verified = false
		_transcript_opened = false
	var opt := _find_token_option(key, chosen)
	var expected_val := String(expected_map.get(key, ""))
	var is_valid := chosen == expected_val
	var source_disagrees := String(opt.get("source_disagrees", ""))
	if not is_valid and source_disagrees.is_empty():
		source_disagrees = _source_card_for_field(key)
	var feedback := String(opt.get("feedback", ""))
	if feedback.is_empty():
		feedback = (
			"Token %s verified against %s." % [chosen, _source_card_for_field(key)]
			if is_valid
			else "%s disagrees with token '%s'. Audio stays locked until all three match." % [source_disagrees, chosen]
		)
	_last_feedback = feedback
	return {
		"accepted": true,
		"field": key,
		"value": chosen,
		"valid_token": is_valid,
		"removable": not chosen.is_empty(),
		"source_disagrees": source_disagrees,
		"audio_locked": not _board_all_valid(),
		"reason": feedback,
		"scientific_puzzle": true,
	}

## Removes the current token from `field` (`date`, `device`, or `channel`) so the player can reassign it.
func remove_slot_token(field: String) -> Dictionary:
	var key := field.strip_edges()
	if not _board_slots.has(key):
		return _reject("Unknown metadata slot field: " + key)
	_board_slots[key] = ""
	if not _checksum_verified:
		_mapping.erase(key)
	_last_feedback = "Removed token from %s slot." % key
	return {
		"accepted": true,
		"field": key,
		"value": "",
		"removable": false,
		"audio_locked": true,
		"reason": _last_feedback,
		"scientific_puzzle": true,
	}

## Returns the status of a metadata slot (`date`, `device`, or `channel`), including any source disagreement.
func slot_status(field: String) -> Dictionary:
	var key := field.strip_edges()
	var expected_map: Dictionary = data().get("expected_tokens", {})
	var chosen := String(_board_slots.get(key, _mapping.get(key, "")))
	var expected_val := String(expected_map.get(key, ""))
	var is_valid := not chosen.is_empty() and chosen == expected_val
	var opt := _find_token_option(key, chosen)
	var source_disagrees := ""
	if not chosen.is_empty() and not is_valid:
		source_disagrees = String(opt.get("source_disagrees", _source_card_for_field(key)))
	return {
		"field": key,
		"value": chosen,
		"committed": _mapping.get(key, "") == expected_val and not expected_val.is_empty(),
		"valid_token": is_valid,
		"removable": not chosen.is_empty(),
		"source_disagrees": source_disagrees,
		"feedback": String(opt.get("feedback", "")),
	}

## Selects how physical bench labels are handled (`photograph_in_place` vs `peel_labels`).
func select_label_handling(mode_id: String) -> Dictionary:
	var chosen := mode_id.strip_edges()
	for item in data().get("label_handling_options", []):
		if item is Dictionary and String(item.get("id", "")) == chosen:
			_last_feedback = String(item.get("feedback", ""))
			if bool(item.get("valid", false)):
				_label_handling = chosen
				return {"accepted": true, "reason": _last_feedback, "label_handling": _label_handling, "scientific_puzzle": true}
			return {"accepted": false, "reason": _last_feedback, "label_handling": _label_handling, "scientific_puzzle": true}
	return _reject("Choose how to document the physical bench labels.")

## Selects how the archive Person slot is handled (`blank_unknown`, `guess_ferreira`, or `guess_noor_name`).
func select_person_slot(mode_id: String) -> Dictionary:
	var chosen := mode_id.strip_edges()
	for item in data().get("person_slot_options", []):
		if item is Dictionary and String(item.get("id", "")) == chosen:
			_person_slot = chosen
			_last_feedback = String(item.get("feedback", ""))
			return {
				"accepted": bool(item.get("valid", false)),
				"reason": _last_feedback,
				"person_slot": _person_slot,
				"scientific_puzzle": true,
			}
	return _reject("Select a valid Person-slot rule.")

## Places a statement (`retreat_2034`, `voice_resembles_ferreira`, `writer_n_identity`) into `observed`, `inferred`, or `unknown`.
func classify_claim(claim_id: String, column_id: String) -> Dictionary:
	var c_id := claim_id.strip_edges()
	var col := column_id.strip_edges().to_lower()
	if col not in ["observed", "inferred", "unknown"]:
		return _reject("Classify each statement into Observed, Inferred, or Unknown.")
	for item in data().get("classification_claims", []):
		if item is Dictionary and String(item.get("id", "")) == c_id:
			_classifications[c_id] = col
			var ok := col == String(item.get("expected", ""))
			_last_feedback = String(item.get("feedback_ok" if ok else "feedback_wrong", ""))
			return {
				"accepted": ok,
				"claim_id": c_id,
				"column_id": col,
				"valid_column": ok,
				"reason": _last_feedback,
				"scientific_puzzle": true,
			}
	return _reject("Unknown P-04 classification statement: " + c_id)

## Shares a crew clue card in Class mode (`P04-C1`..`P04-C4`).
func share_clue(clue_id: String) -> Dictionary:
	for item in data().get("clues", []):
		if item is Dictionary and String(item.get("id", "")) == clue_id:
			if not _shared_clues.has(clue_id):
				_shared_clues.append(clue_id)
			_last_feedback = "Shared clue %s (%s)." % [clue_id, item.get("label", "")]
			return {"accepted": true, "reason": _last_feedback, "shared_clues": _shared_clues.duplicate(), "scientific_puzzle": true}
	return _reject("Unknown P-04 clue ID.")

## Reveals the next progressive hint tier (1..3) for `metadata` or `classification` without solving the puzzle.
func next_hint(topic: String = "metadata") -> Dictionary:
	var key := "classification" if topic == "classification" else "metadata"
	var all_hints: Array = data().get("hints", {}).get(key, [])
	var tier := mini(int(_hint_tier.get(key, 0)) + 1, all_hints.size())
	_hint_tier[key] = tier
	var revealed := hints_for(key)
	var latest: String = String(revealed.back()) if not revealed.is_empty() else ""
	_last_feedback = "Hint %d/%d: %s" % [tier, all_hints.size(), latest]
	return {"accepted": true, "topic": key, "tier": tier, "max_tier": all_hints.size(), "hint": latest, "hints": revealed, "scientific_puzzle": true}

## Returns the currently revealed hints for `metadata` or `classification`.
func hints_for(topic: String = "metadata") -> Array:
	var key := "classification" if topic == "classification" else "metadata"
	var all_hints: Array = data().get("hints", {}).get(key, [])
	var tier := clampi(int(_hint_tier.get(key, 0)), 0, all_hints.size())
	return all_hints.slice(0, tier)

## Resets uncommitted board tokens or classification choices for the current step without losing completed steps.
func reset_current_step() -> Dictionary:
	_label_handling = "photograph_in_place"
	_person_slot = "blank_unknown"
	var expected_map: Dictionary = data().get("expected_tokens", {})
	for k in ["date", "device", "channel"]:
		if _mapping.get(k, "") != String(expected_map.get(k, "")):
			_board_slots[k] = ""
	if not _classified:
		for k in _classifications.keys():
			_classifications[k] = ""
	_worked_plan_active = false
	_last_feedback = "Current step choices reset; verified archive records remain intact."
	return {"accepted": true, "reason": _last_feedback, "scientific_puzzle": true}

## Configures the interactive board for a single P-04 action using the JSON specification.
func configure_for_action(action: String) -> Dictionary:
	var content := data()
	_label_handling = "photograph_in_place"
	_person_slot = "blank_unknown"
	if action in ["p04_assign_date", "p04_assign_device", "p04_assign_channel"]:
		var field := action.trim_prefix("p04_assign_")
		var expected_val := String(content.get("expected_tokens", {}).get(field, ""))
		_board_slots[field] = expected_val
		_last_feedback = "Placed verified %s token (%s)." % [field, expected_val]
		return {"accepted": true, "reason": _last_feedback, "payload": payload_for_action(action)}
	if action == "p04_classify_inference":
		for item in content.get("classification_claims", []):
			if item is Dictionary:
				_classifications[String(item.get("id", ""))] = String(item.get("expected", ""))
		_last_feedback = "Configured Observed, Inferred, and Unknown classifications."
		return {"accepted": true, "reason": _last_feedback, "payload": payload_for_action(action)}
	return {"accepted": true, "reason": "Ready for " + action, "payload": payload_for_action(action)}

## Applies the complete documented worked choices across all P-04 steps (used by headless route test fixtures).
func apply_worked_plan() -> Dictionary:
	_worked_plan_active = true
	_label_handling = "photograph_in_place"
	_person_slot = "blank_unknown"
	var expected_map: Dictionary = data().get("expected_tokens", {})
	for k in expected_map:
		_board_slots[String(k)] = String(expected_map[k])
	for item in data().get("classification_claims", []):
		if item is Dictionary:
			_classifications[String(item.get("id", ""))] = String(item.get("expected", ""))
	return {"accepted": true, "reason": "Applied P-04 worked metadata and classification plan."}

## Builds the action payload from the player's current interactive selections.
func payload_for_action(action: String) -> Dictionary:
	if action in ["p04_assign_date", "p04_assign_device", "p04_assign_channel"]:
		var field := action.trim_prefix("p04_assign_")
		var val := String(_board_slots.get(field, "")).strip_edges()
		var out := {"person_slot": _person_slot, "label_handling": _label_handling}
		if not val.is_empty():
			out["value"] = val
		return out
	if action == "p04_classify_inference":
		return {
			"classifications": _classifications.duplicate(true),
			"person_slot": _person_slot,
			"label_handling": _label_handling,
		}
	return {
		"person_slot": _person_slot,
		"label_handling": _label_handling,
	}

## Validates a P-04 action without mutating authoritative state.
func preview_action(action: String, payload: Dictionary = {}) -> Dictionary:
	var content := data()
	var expected_map: Dictionary = content.get("expected_tokens", {})
	var messages: Dictionary = content.get("feedback_messages", {})
	var effective := payload_for_action(action).merged(payload, true)

	if String(effective.get("label_handling", _label_handling)) == "peel_labels":
		for item in content.get("label_handling_options", []):
			if item is Dictionary and String(item.get("id", "")) == "peel_labels":
				return _reject(String(item.get("feedback", "Never peel archive labels; photograph them in place.")))

	if String(effective.get("person_slot", _person_slot)) != "blank_unknown":
		for item in content.get("person_slot_options", []):
			if item is Dictionary and String(item.get("id", "")) == String(effective.get("person_slot", _person_slot)):
				return _reject(String(item.get("feedback", "A device match is not a person's name; leave the Person slot blank.")))
		return _reject("A device match is not a person's name; leave the Person slot blank.")

	match action:
		"p04_assign_date", "p04_assign_device", "p04_assign_channel":
			var field := action.trim_prefix("p04_assign_")
			var chosen := String(effective.get("value", "")).strip_edges()
			var expected_val := String(expected_map.get(field, ""))
			if chosen.is_empty():
				return _reject("Select a verified %s token on the Recorder Reconstruction board before locking in." % field)
			if chosen != expected_val:
				var opt := _find_token_option(field, chosen)
				var source_disagrees := String(opt.get("source_disagrees", _source_card_for_field(field)))
				var reason := String(opt.get("feedback", "%s disagrees with token '%s'. Audio stays locked until all three match." % [source_disagrees, chosen]))
				var rejected := _reject(reason)
				rejected["source_disagrees"] = source_disagrees
				rejected["audio_locked"] = true
				return rejected
			return {"accepted": true, "reason": "%s token verified (%s)." % [field.capitalize(), chosen], "scientific_puzzle": true}
		"p04_verify_checksum":
			return (
				{"accepted": true, "reason": "Local checksum verified across all three fragments.", "scientific_puzzle": true}
				if _mapping_complete()
				else _reject(String(messages.get("premature_checksum", "Assign all three verified metadata tokens before checking the local checksum.")))
			)
		"p04_open_transcript":
			return (
				{"accepted": true, "reason": "Reconstructed transcript unlocked.", "scientific_puzzle": true}
				if _checksum_verified
				else _reject(String(messages.get("premature_transcript", "Verify the reconstructed local checksum before opening the transcript.")))
			)
		"p04_play_engineer":
			return (
				{"accepted": true, "reason": "Dated 2034 Engineer recording played.", "scientific_puzzle": true}
				if _transcript_opened
				else _reject(String(messages.get("premature_audio", "Open the verified transcript before playing the dated Engineer fragment.")))
			)
		"p04_play_n":
			return (
				{"accepted": true, "reason": "N.'s mustard-fields memory played.", "scientific_puzzle": true}
				if _engineer_played
				else _reject("Play the dated Engineer fragment before the personal N. fragment.")
			)
		"p04_classify_inference":
			if not (_engineer_played and _n_clue_played):
				return _reject("Listen to both reconstructed fragments before classifying the claims.")
			var cls: Dictionary = effective.get("classifications", _classifications) if effective.get("classifications") is Dictionary else _classifications
			for item in content.get("classification_claims", []):
				if not item is Dictionary:
					continue
				var c_id := String(item.get("id", ""))
				var chosen_col := String(cls.get(c_id, "")).strip_edges().to_lower()
				if chosen_col.is_empty():
					return _reject(String(messages.get("classification_incomplete", "Sort all three statements into Observed, Inferred, and Unknown before locking in.")))
				if chosen_col != String(item.get("expected", "")):
					return _reject(String(item.get("feedback_wrong", "Check whether that statement is directly Observed, Inferred, or Unknown.")))
			return {"accepted": true, "reason": "Observed, Inferred, and Unknown claims classified accurately.", "scientific_puzzle": true}
		"p04_send_copy":
			return (
				{"accepted": true, "reason": "Intact technical copy sent to Ferreira.", "scientific_puzzle": true}
				if _classified
				else _reject("Classify the voice resemblance as an inference before sending Ferreira the technical copy.")
			)
		"p04_ack_handover":
			return (
				{"accepted": true, "reason": "Evening handover acknowledged.", "scientific_puzzle": true}
				if _copy_sent
				else _reject("Send the intact technical copy before closing the handover.")
			)
	return _reject("Unknown P-04 recorder reconstruction action.")

## Commits a validated P-04 action and advances the puzzle state.
func commit_action(action: String, payload: Dictionary = {}) -> Dictionary:
	var check := preview_action(action, payload)
	if not bool(check.get("accepted", false)):
		_last_feedback = String(check.get("reason", "Recorder reconstruction step needs adjustment."))
		return check
	var effective := payload_for_action(action).merged(payload, true)
	match action:
		"p04_assign_date", "p04_assign_device", "p04_assign_channel":
			var field := action.trim_prefix("p04_assign_")
			var val := String(effective.get("value", "")).strip_edges()
			_mapping[field] = val
			_board_slots[field] = val
		"p04_verify_checksum":
			_checksum_verified = true
		"p04_open_transcript":
			_transcript_opened = true
		"p04_play_engineer":
			_engineer_played = true
		"p04_play_n":
			_n_clue_played = true
		"p04_classify_inference":
			var cls: Dictionary = effective.get("classifications", _classifications) if effective.get("classifications") is Dictionary else _classifications
			for k in cls:
				_classifications[String(k)] = String(cls[k]).strip_edges().to_lower()
			_classified = true
		"p04_send_copy":
			_copy_sent = true
		"p04_ack_handover":
			_handover_acknowledged = true
	_last_feedback = String(check.get("reason", "Step committed."))
	return {"accepted": true, "flags": flags(), "scientific_puzzle": true}

## Returns the authoritative P-04 completion flags.
func flags() -> Dictionary:
	var expected_map: Dictionary = data().get("expected_tokens", {})
	return {
		"p04_assign_date_done": _mapping.get("date", "") == String(expected_map.get("date", "2034-04")),
		"p04_assign_device_done": _mapping.get("device", "") == String(expected_map.get("device", "HORT-01")),
		"p04_assign_channel_done": _mapping.get("channel", "") == String(expected_map.get("channel", "ENGINEERING")),
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

## Returns a primitive, JSON-safe snapshot of P-04 state for save/load and retry checkpoints.
func snapshot() -> Dictionary:
	return {
		"mapping": _mapping.duplicate(true),
		"board_slots": _board_slots.duplicate(true),
		"label_handling": _label_handling,
		"person_slot": _person_slot,
		"classifications": _classifications.duplicate(true),
		"checksum_verified": _checksum_verified,
		"transcript_opened": _transcript_opened,
		"engineer_played": _engineer_played,
		"n_clue_played": _n_clue_played,
		"classified": _classified,
		"copy_sent": _copy_sent,
		"handover_acknowledged": _handover_acknowledged,
		"shared_clues": _shared_clues.duplicate(),
		"hint_tier": _hint_tier.duplicate(true),
		"last_feedback": _last_feedback,
		"worked_plan_active": _worked_plan_active,
	}

## Restores P-04 state from a primitive snapshot.
func restore(saved: Dictionary) -> Dictionary:
	for key in ["mapping", "checksum_verified", "transcript_opened", "engineer_played", "n_clue_played", "classified", "copy_sent", "handover_acknowledged"]:
		if not saved.has(key):
			return _reject("P-04 snapshot is missing " + key + ".")
	if not saved.mapping is Dictionary:
		return _reject("P-04 mapping must be a Dictionary.")
	_mapping = saved.get("mapping", {}).duplicate(true)
	_board_slots = {"date": "", "device": "", "channel": ""}
	if saved.get("board_slots") is Dictionary:
		for k in ["date", "device", "channel"]:
			_board_slots[k] = String(saved.board_slots.get(k, _mapping.get(k, "")))
	else:
		for k in ["date", "device", "channel"]:
			_board_slots[k] = String(_mapping.get(k, ""))
	_label_handling = String(saved.get("label_handling", "photograph_in_place"))
	_person_slot = String(saved.get("person_slot", "blank_unknown"))
	_classifications = {
		"retreat_2034": "",
		"voice_resembles_ferreira": "",
		"writer_n_identity": "",
	}
	if saved.get("classifications") is Dictionary:
		for k in _classifications.keys():
			_classifications[k] = String(saved.classifications.get(k, ""))
	_checksum_verified = bool(saved.get("checksum_verified", false))
	_transcript_opened = bool(saved.get("transcript_opened", false))
	_engineer_played = bool(saved.get("engineer_played", false))
	_n_clue_played = bool(saved.get("n_clue_played", false))
	_classified = bool(saved.get("classified", false))
	_copy_sent = bool(saved.get("copy_sent", false))
	_handover_acknowledged = bool(saved.get("handover_acknowledged", false))
	_shared_clues.clear()
	if saved.get("shared_clues") is Array:
		for c in saved.shared_clues:
			_shared_clues.append(String(c))
	_hint_tier = {"metadata": 0, "classification": 0}
	if saved.get("hint_tier") is Dictionary:
		for k in ["metadata", "classification"]:
			_hint_tier[k] = int(saved.hint_tier.get(k, 0))
	_last_feedback = String(saved.get("last_feedback", ""))
	_worked_plan_active = bool(saved.get("worked_plan_active", false))
	return {"accepted": true}

## Builds a complete view model for the ScientificPuzzlePanel UI.
func view_for_scene(scene_id: String, target_id: String = "") -> Dictionary:
	var content := data()
	var stage_id := "learn"
	if scene_id == "EX-CH02-S09":
		stage_id = "apply"
	elif scene_id in ["EX-CH02-S10", "EX-CH02-S11", "EX-CH02-S12"]:
		stage_id = "twist"
	var topic := "classification" if stage_id == "twist" else "metadata"
	var slots: Dictionary = {}
	for k in ["date", "device", "channel"]:
		slots[k] = slot_status(k)
	return {
		"puzzle_id": "P-04",
		"title": String(content.get("title", "Recorder Reconstruction")),
		"subtitle": String(content.get("subtitle", "")),
		"question": String(content.get("question", "")),
		"goal_one_line": String(content.get("goal_one_line", "")),
		"first_time_explainer": content.get("first_time_explainer", {}),
		"stage": content.get("stages", {}).get(stage_id, {}),
		"stage_id": stage_id,
		"scene_id": scene_id,
		"target_id": target_id,
		"files": content.get("files", []),
		"token_options": content.get("token_options", {}),
		"slots": slots,
		"audio_locked": not _transcript_opened,
		"label_handling": _label_handling,
		"label_handling_options": content.get("label_handling_options", []),
		"person_slot": _person_slot,
		"person_slot_options": content.get("person_slot_options", []),
		"transcripts": content.get("transcripts", {}),
		"classification_columns": content.get("classification_columns", []),
		"classification_claims": content.get("classification_claims", []),
		"classifications": _classifications.duplicate(true),
		"clues": content.get("clues", []),
		"shared_clues": _shared_clues.duplicate(),
		"hint_topic": topic,
		"hints_revealed": hints_for(topic),
		"hint_tier": int(_hint_tier.get(topic, 0)),
		"hint_max": content.get("hints", {}).get(topic, []).size(),
		"bridges": content.get("bridges", {}),
		"last_feedback": _last_feedback,
		"flags": flags(),
	}

func _mapping_complete() -> bool:
	var expected_map: Dictionary = data().get("expected_tokens", {})
	if expected_map.is_empty():
		return false
	for field in expected_map:
		if _mapping.get(field, "") != expected_map[field]:
			return false
	return true

func _board_all_valid() -> bool:
	var expected_map: Dictionary = data().get("expected_tokens", {})
	if expected_map.is_empty():
		return false
	for field in expected_map:
		var chosen := String(_board_slots.get(field, _mapping.get(field, "")))
		if chosen != String(expected_map[field]):
			return false
	return true

func _find_token_option(field: String, value: String) -> Dictionary:
	for item in data().get("token_options", {}).get(field, []):
		if item is Dictionary and String(item.get("value", "")) == value:
			return item
	return {}

func _source_card_for_field(field: String) -> String:
	for item in data().get("files", []):
		if item is Dictionary and String(item.get("field", "")) == field:
			return String(item.get("source_card", "Photographed bench evidence"))
	return "Photographed bench evidence"

static func _reject(reason: String) -> Dictionary:
	return {"accepted": false, "reason": reason, "scientific_puzzle": true}
