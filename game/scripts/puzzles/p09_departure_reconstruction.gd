extends RefCounted
class_name P09DepartureReconstruction

## P-09 — Reconstruct the Departure (game-design/08 §P-09, 22 §7.1).
## Pure rule model: the player places four evidence cards in timestamp order,
## matches the two highlighted signatures, fixes the five-person forecast and
## commits only the conclusion the boarding evidence supports. The answers
## live in game/resources/campaign/content/p09_departure_reconstruction.json;
## the ledger (ExtendedPuzzleLedger) still checks the committed receipt.
## Reordering stays free; a wrong conclusion names the contradiction.

const DataScript = preload("res://scripts/puzzles/puzzle_data.gd")

var _placed: Array = []
var _signatures := {}
var _roster_occupants := 0
var _spare_stored := false
var _readings_done := false
var _conclusion := ""
var _committed := false
var _committed_payload := {}

static func data() -> Dictionary:
	return DataScript.data("P-09")

static func expected_order() -> Array:
	return (data().get("expected", {}).get("order", []) as Array).duplicate()

static func expected_conclusion() -> String:
	return String(data().get("expected", {}).get("conclusion", ""))

static func card_ids() -> Array:
	var result: Array = []
	for card in data().get("cards", []):
		result.append(String(card.get("card_id", "")))
	return result

## Place (or move) one evidence card on the chronology board. Cards are
## placed in the order the player chooses them; reordering stays free.
func place_card(card_id: String) -> Dictionary:
	if _committed:
		return _reject("The departure sequence is already committed.")
	if not card_ids().has(card_id):
		return _reject("That card is not part of the departure evidence.")
	_placed.erase(card_id)
	_placed.append(card_id)
	return _accept("Placed %s on the board, position %d of %d." % [_label(card_id), _placed.size(), card_ids().size()])

## Remove one card from the board (free reordering).
func remove_card(card_id: String) -> Dictionary:
	if _committed:
		return _reject("The departure sequence is already committed.")
	_placed.erase(card_id)
	return _accept("Removed %s from the board." % _label(card_id))

## Match a highlighted signature to a person. FER is Ferreira; N.R. is the
## gardener, known only by initials — a full name is never an option.
func match_signature(signature: String, person: String) -> Dictionary:
	if _committed:
		return _reject("The departure sequence is already committed.")
	var known := {}
	for entry in data().get("signatures", []):
		known[String(entry.get("signature", ""))] = String(entry.get("person", ""))
	if not known.has(signature):
		return _reject("That signature is not highlighted on the manifest.")
	if String(known[signature]) != person:
		return _reject("The manifest does not support that match. Check the boarding signatures again.")
	_signatures[signature] = person
	return _accept("Matched %s." % signature)

## Fix the occupancy forecast. Four keeps the old card; five counts Ferreira.
func verify_roster(occupants: int) -> Dictionary:
	if _committed:
		return _reject("The departure sequence is already committed.")
	if occupants == 5:
		_roster_occupants = 5
		return _accept("Five people. Air 1.25 and food 1.5 per shift now follow five people.")
	if occupants == 4:
		return _reject("The old card counted four. The preview shows the omitted demand: Ferreira still breathes and eats.")
	return _reject("The station holds four crew plus Ferreira. Count the people who are actually here.")

## What the forecast omits when it still counts four people instead of five.
func forecast(occupants: int) -> Dictionary:
	var numbers: Dictionary = data().get("numbers", {})
	var air := float(numbers.get("air_per_shift_five", 1.25)) if occupants == 5 else float(numbers.get("air_per_shift_four", 1.0))
	var food := float(numbers.get("food_per_shift_five", 1.5)) if occupants == 5 else float(numbers.get("food_per_shift_four", 1.2))
	return {
		"occupants": occupants,
		"air_per_shift": air,
		"food_per_shift": food,
		"omitted_air_per_shift": float(numbers.get("air_per_shift_five", 1.25)) - air,
		"omitted_food_per_shift": float(numbers.get("food_per_shift_five", 1.5)) - food,
	}

## Choose the conclusion. Wrong-but-reasonable answers are refused at once
## with the contradiction named, so the player can retry locally.
func select_conclusion(value: String) -> Dictionary:
	if _committed:
		return _reject("The departure sequence is already committed.")
	for option in data().get("choices", {}).get("conclusion", {}).get("options", []):
		if String(option.get("value", "")) == value:
			if bool(option.get("correct", false)):
				_conclusion = value
				return _accept(String(option.get("feedback", "")))
			return _reject(String(option.get("feedback", "That conclusion is not supported.")))
	return _reject("That conclusion is not on the board.")

func preview_commit() -> Dictionary:
	if _committed:
		return {"accepted": true, "duplicate": true, "reason": "The departure sequence is already committed.", "payload": _committed_payload.duplicate(true)}
	if _placed != expected_order():
		return _reject(String(data().get("feedback", {}).get("wrong_order", "This order contradicts a timestamp.")))
	if _signatures.size() != 2:
		return _reject(String(data().get("feedback", {}).get("boarding_not_checked", "Match both highlighted signatures first.")))
	if _roster_occupants != 5:
		return _reject(String(data().get("feedback", {}).get("roster_not_five", "The forecast still counts four people.")))
	if _conclusion != expected_conclusion():
		return _reject("Choose the conclusion the boarding evidence supports.")
	return {"accepted": true, "duplicate": false, "reason": "Four records in timestamp order, both signatures matched, five-person forecast, supported conclusion.", "payload": gate_payload()}

func commit_sequence() -> Dictionary:
	var check := preview_commit()
	if not bool(check.get("accepted", false)):
		return check
	if bool(check.get("duplicate", false)):
		return check
	_committed = true
	_committed_payload = (check.get("payload", {}) as Dictionary).duplicate(true)
	return {"accepted": true, "duplicate": false, "reason": "Departure sequence committed: all four returned.", "payload": _committed_payload.duplicate(true)}

func gate_payload() -> Dictionary:
	return {"order": expected_order(), "conclusion": expected_conclusion()}

func hint(tier: int) -> String:
	var hints: Array = data().get("hints", {}).get("sequence", [])
	if tier < 1 or tier > hints.size():
		return ""
	return String(hints[tier - 1])

## Return the working board to its fresh state. A committed sequence cannot
## be undone; the route's checkpoint retry is the way back from a commit.
func reset() -> Dictionary:
	if _committed:
		return _reject("A committed sequence cannot be undone here.")
	_placed = []
	_signatures = {}
	_roster_occupants = 0
	_spare_stored = false
	_readings_done = false
	_conclusion = ""
	return _accept("Choices cleared. The evidence has not changed.")

func preview_action(action: String, payload: Dictionary = {}) -> Dictionary:
	match action:
		"p09_check_lander_clearance":
			return _accept("Two landing-clear indicators must agree before the inner door opens.")
		"p09_check_seals":
			return _accept("Seal indication checked twice.")
		"p09_verify_five_person_roster":
			if int(payload.get("occupants", 0)) != 5:
				return _reject("The forecast still counts four people. Ferreira is the fifth person.")
			return _accept("Five-person roster verified.")
		"p09_store_spare_once":
			if _spare_stored:
				return {"accepted": true, "duplicate": true, "reason": "The spare controller is already stored once."}
			return _accept("The spare controller stores once, with its procedure local.")
		"p09_run_arrival_readings", "p09_reconcile_readings":
			return _accept("Arrival readings are ready.")
		"p09_commit_sequence":
			if payload.get("order", []) != expected_order() or String(payload.get("conclusion", "")) != expected_conclusion():
				return _reject("P-09 requires the timestamp order and supported all-returned conclusion.")
			return preview_commit()
	return _reject("Unknown P-09 action: " + action)

func commit_action(action: String, payload: Dictionary = {}) -> Dictionary:
	var check := preview_action(action, payload)
	if not bool(check.get("accepted", false)):
		return check
	if bool(check.get("duplicate", false)):
		return check
	match action:
		"p09_verify_five_person_roster":
			_roster_occupants = 5
		"p09_store_spare_once":
			_spare_stored = true
		"p09_run_arrival_readings", "p09_reconcile_readings":
			_readings_done = true
		"p09_commit_sequence":
			var done := commit_sequence()
			if not bool(done.get("accepted", false)):
				return done
			return done
	return _accept("P-09 action recorded once.")

func flags() -> Dictionary:
	return {
		"p09_cards_placed": _placed.size(),
		"p09_order_correct": _placed == expected_order(),
		"p09_signatures_matched": _signatures.size(),
		"p09_roster_five": _roster_occupants == 5,
		"p09_spare_stored": _spare_stored,
		"p09_readings_done": _readings_done,
		"p09_conclusion": _conclusion,
		"p09_complete": _committed,
		"zero_sequence_pending": _committed,
		"zero_all_returned": _committed and _conclusion == expected_conclusion(),
		"ferreira_admission_ready": _committed,
	}

func snapshot() -> Dictionary:
	return {"schema_version": 1, "placed": _placed.duplicate(), "signatures": _signatures.duplicate(true), "roster_occupants": _roster_occupants, "spare_stored": _spare_stored, "readings_done": _readings_done, "conclusion": _conclusion, "committed": _committed, "committed_payload": _committed_payload.duplicate(true)}

func restore(state: Dictionary) -> Dictionary:
	var version = state.get("schema_version", 1)
	if not (version is int or version is float) or float(version) != 1.0:
		return _reject("P-09 snapshot is incompatible.")
	if not state.get("placed", []) is Array or not state.get("signatures", {}) is Dictionary:
		return _reject("P-09 placed cards and signatures must be an array and a dictionary.")
	for card in state.get("placed", []):
		if not card is String or not card_ids().has(card):
			return _reject("P-09 placed cards must be known evidence cards.")
	for key in ["roster_occupants"]:
		if not (state.get(key, null) is int or state.get(key, null) is float):
			return _reject("P-09 roster count must be a number.")
	for key in ["spare_stored", "readings_done", "committed"]:
		if not state.get(key, null) is bool:
			return _reject("P-09 evidence must be boolean.")
	if not state.get("conclusion", "") is String or not state.get("committed_payload", {}) is Dictionary:
		return _reject("P-09 conclusion and payload must be a string and a dictionary.")
	_placed.assign(state.get("placed", []))
	_signatures = state.get("signatures", {}).duplicate(true)
	_roster_occupants = int(state.get("roster_occupants", 0))
	_spare_stored = bool(state.get("spare_stored", false))
	_readings_done = bool(state.get("readings_done", false))
	_conclusion = String(state.get("conclusion", ""))
	_committed = bool(state.get("committed", false))
	_committed_payload = state.get("committed_payload", {}).duplicate(true)
	return _accept("P-09 restored.")

func _label(card_id: String) -> String:
	for card in data().get("cards", []):
		if String(card.get("card_id", "")) == card_id:
			return String(card.get("label", card_id))
	return card_id

func _accept(reason: String) -> Dictionary:
	return {"accepted": true, "duplicate": false, "reason": reason}

func _reject(reason: String) -> Dictionary:
	return {"accepted": false, "duplicate": false, "reason": reason}
