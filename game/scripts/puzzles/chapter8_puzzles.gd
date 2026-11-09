extends RefCounted
class_name Chapter8Puzzles

## P-15 Two Teams, One Road and P-16 The Link and the Living Garden: the
## player's decisions behind every Chapter 8 operation.
##
## Holds only what the player has chosen, found and read: per-step selections
## (team boards, packed crates, routes, dial bearings, procedure order, ticks),
## found clues, revealed hints, Go/No-Go signatures and the lock timer. It does
## no resource arithmetic: `payload_for` turns a selection into the exact
## payload the extended puzzle ledger validates and the campaign ledger
## simulation commits, so preview and commit share one rule path.
##
## Step content (clues, options, feedback, hints) lives in
## res://resources/campaign/content/chapter8_puzzles.json; the answer keys live
## in res://resources/campaign/profiles/campaign_rules.json (`chapter8`, `relay`).

const DATA_PATH := "res://resources/campaign/content/chapter8_puzzles.json"
const RULES_PATH := "res://resources/campaign/profiles/campaign_rules.json"
const SCHEMA_VERSION := 1
const KINDS := ["choice", "assign", "select_many", "number", "route", "dial", "lock", "procedure", "checks", "confirm", "settings"]

static var _data_cache: Dictionary = {}
static var _rules_cache: Dictionary = {}

var _selections := {}
var _found := {}
var _hints := {}
var _polls := {}
var _attempts := {}
var _first_time_seen := {}

# --- Static data access --------------------------------------------------------

## The parsed content file. Cached; returns {} and reports why if it is missing or invalid.
static func data() -> Dictionary:
	if _data_cache.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH)) if FileAccess.file_exists(DATA_PATH) else null
		if parsed is Dictionary and int(parsed.get("schema_version", 0)) == SCHEMA_VERSION and parsed.get("steps", null) is Dictionary and parsed.get("scenes", null) is Dictionary:
			_data_cache = parsed
		else:
			push_error("Chapter 8 puzzle content is missing or invalid: " + DATA_PATH)
	return _data_cache

## The answer keys: campaign_rules.json `chapter8` merged with the three `relay` keys.
static func rules() -> Dictionary:
	if _rules_cache.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(RULES_PATH)) if FileAccess.file_exists(RULES_PATH) else null
		if parsed is Dictionary and parsed.get("chapter8", null) is Dictionary and parsed.get("relay", null) is Dictionary:
			var merged: Dictionary = parsed.chapter8.duplicate(true)
			merged["local_bearing"] = String(parsed.relay.get("local_bearing", ""))
			merged["earth_bearing"] = String(parsed.relay.get("earth_bearing", ""))
			merged["known_echo"] = String(parsed.relay.get("known_echo", ""))
			_rules_cache = merged
		else:
			push_error("Chapter 8 answer keys are missing from " + RULES_PATH)
	return _rules_cache

## True when `target_id` is one of the 38 Chapter 8 puzzle operations.
static func is_step(target_id: String) -> bool:
	return data().get("steps", {}).has(target_id)

static func step(target_id: String) -> Dictionary:
	return data().get("steps", {}).get(target_id, {}).duplicate(true)

static func scene(scene_id: String) -> Dictionary:
	return data().get("scenes", {}).get(scene_id, {}).duplicate(true)

static func puzzle(puzzle_id: String) -> Dictionary:
	return data().get("puzzles", {}).get(puzzle_id, {}).duplicate(true)

static func role(role_id: String) -> Dictionary:
	return data().get("roles", {}).get(role_id, {"name": role_id.capitalize(), "letter": role_id.left(1).to_upper()}).duplicate(true)

## Plain-words label for the HUD and the world prompt ("Two boards, five names").
static func focus_label(target_id: String) -> String:
	return String(step(target_id).get("title", ""))

static func step_ids_for_scene(scene_id: String) -> Array:
	var result: Array = []
	for id in data().get("steps", {}):
		if String(data().steps[id].get("scene", "")) == scene_id:
			result.append(String(id))
	return result

static func puzzle_id_for_step(target_id: String) -> String:
	return "P-15" if target_id.begins_with("p15_") else ("P-16" if target_id.begins_with("p16_") else "")

## The hint ladder for one step: the puzzle's three 08 hints, then the scene's
## own hints where 22 §10 adds them. Hints never pre-fill a control.
static func hint_ladder(target_id: String) -> Array:
	var ladder: Array = puzzle(puzzle_id_for_step(target_id)).get("hints", []).duplicate()
	ladder.append_array(scene(String(step(target_id).get("scene", ""))).get("new_hints", []))
	return ladder

# --- Answer validation (stateless; shared by the ledger) ---------------------

## Checks one payload against the data-driven answer key. Returns "" when the
## payload is accepted, otherwise the plain-words reason. Steps with no
## decision (confirm) accept any payload.
static func validate(action: String, payload: Dictionary) -> String:
	var key := rules()
	if key.is_empty():
		return "Chapter 8 answer keys are unavailable."
	match action:
		"p15_confirm_teams":
			if _sorted(payload.get("rover", [])) != _sorted(key.rover_team) or _sorted(payload.get("home", [])) != _sorted(key.home_team):
				return "Three travel and two keep Aurora: Ferreira, Kai and Rafi in the rover; Mei and Amara at home."
		"p15_confirm_loadout":
			var packed: Array = payload.get("packed", []) if payload.get("packed", []) is Array else []
			for item in key.manifest_required:
				if not packed.has(item):
					return "The signed manifest lists the compatible controller, the battery spare, the service diagram and three repeater checkpoints. A missing spare blocks departure."
			for item in key.manifest_forbidden:
				if packed.has(item):
					return "Only manifest items ride. A damaged unit or a decorative load spends the return reserve for nothing."
		"p15_confirm_roundtrip_provisions":
			var hours := float(payload.get("hours", -1))
			if hours < float(key.provisions_min_hours) or hours > float(key.provisions_max_hours):
				return "Independent supplies must cover the whole trip: 24 out, 3 repair, 24 back is 51 hours, within the 72 carried."
		"p15_choose_surveyed_route":
			if String(payload.get("route", "")) != String(key.surveyed_route):
				return "Slope validation rejects the shortcut: 22° is above the 15° limit. Use the surveyed road."
			if float(payload.get("reserve", -1)) < float(key.min_reserve):
				return "The surveyed round trip must keep at least %d units of return reserve." % int(key.min_reserve)
		"p15_confirm_return_reserve":
			var expected := float(payload.get("energy", 0)) - 2.0 * float(payload.get("allowance", 0))
			if not payload.has("energy") or not payload.has("allowance") or not is_equal_approx(float(payload.get("reserve", -1)), expected):
				return "Battery minus the outward allowance minus the return allowance is the reserve. That is not what the battery holds."
			if expected < float(key.min_reserve):
				return "The reserve is below the %d-unit minimum; the departure plan is not safe." % int(key.min_reserve)
		"p15_reach_marker_two":
			if absf(_bearing_delta(float(payload.get("bearing", -999)), float(key.marker_two_bearing))) > float(key.bearing_tolerance):
				return "Match the marker, not the silhouette. The surveyed map and the marker agree at one bearing."
		"p15_set_brake":
			if String(payload.get("action", "")) != String(key.brake_action):
				return "Off-road driving meets a slope barrier. Stop at the surveyed pad and set the brake."
		"p15_save_position_packet", "p15_receive_summit_packet":
			if String(payload.get("packet", "")) != String(key.packet_rule):
				return "A stored packet says where you were. Send the packet with the current sender, position and time."
		"p15_restore_marker_2":
			if payload.get("sequence", []) != key.repair_sequence:
				return "Isolate, remove the dead battery, compare the spare with the specification, install it, close the housing, then reconnect."
		"p15_test_repeater_chain":
			var tested: Array = payload.get("tested", []) if payload.get("tested", []) is Array else []
			for test in key.chain_tests:
				if not tested.has(test):
					return "Lit means powered. Test both neighbours: one to two, and two to three."
			if tested.has("lit"):
				return "A light is not yet a link. Only the two adjacent-link tests verify the chain."
		"p15_confirm_home_occupancy":
			if _segments(payload.get("segments", [])) != _segments(key.home_segments):
				return "Two at home for 33 hours, then five for the last three hours."
		"p15_confirm_segment_forecast":
			for field in key.home_loop:
				if String(payload.get(field, "")) != String(key.home_loop[field]):
					return "The home loop is heat MIN, lamp DIM and water return OPEN."
			if not is_equal_approx(float(payload.get("air_total", -1)), float(key.home_air_total)):
				return "Air follows the people: 0.5 per shift for 33 hours, then 1.25 for 3 hours, is %s units." % str(key.home_air_total)
		"p15_confirm_home_pressure":
			if String(payload.get("gauge", "")) != String(key.gauge):
				return "Verify pressure on the independent gauge, not the panel's diagnosis."
		"p15_confirm_home_checks":
			if payload.get("sequence", []) != key.home_check_order:
				return "Home checks first: air, temperature, open return path. Then acknowledge."
		"p15_confirm_summit":
			if String(payload.get("packet", "")) != String(key.summit_packet):
				return "Only the new summit packet matches the planned 24-hour arrival in sender, position and time."
		"p16_isolate_power":
			if String(payload.get("step", "")) != String(key.controller_first_step):
				return "Removal stays blocked until power is isolated and zero is verified."
		"p16_zero_test":
			if not is_equal_approx(float(payload.get("reading", -1)), float(key.zero_reading)):
				return "Verify zero at the point of work before touching the controller."
		"p16_install_controller":
			if String(payload.get("controller", "")) != String(key.controller_choice):
				return "Only the December spare matches this housing's serial and connector."
		"p16_close_housing":
			if String(payload.get("housing", "")) != String(key.housing):
				return "Reconnecting with the housing open is blocked. Close and latch it first."
		"p16_restore_power":
			if payload.has("step") and String(payload.get("step", "")) != String(key.power_step):
				return "Restore power only by closing the isolator after the housing is latched."
		"p16_local_bearing":
			if String(payload.get("bearing", "")) != key.local_bearing:
				return "The local leg must read good with no obstruction before it counts. Try another bearing."
		"p16_earth_bearing":
			if String(payload.get("bearing", "")) != key.earth_bearing:
				return "Strength is not enough while the path is obstructed. Check obstruction too."
		"p16_stable_lock":
			if String(payload.get("lock", "")) != String(key.stable_lock):
				return "Hold both locks for %d seconds, or tap to confirm with assistance on." % int(key.lock_hold_seconds)
		"p16_checksum":
			if String(payload.get("value", "")) != key.known_echo:
				return "The reply differs from the sent phrase. Strong is not the same as correct."
			if String(payload.get("packet", "")) != String(key.checksum_packet):
				return "That reply belongs to an older test. Exact and current, or not at all."
		"p16_confirm_path_records":
			var records: Array = payload.get("records", []) if payload.get("records", []) is Array else []
			for record in key.path_records:
				if not records.has(record):
					return "Save both path records: the local chain and the Earth leg."
		"p16_voice_verification_ready":
			if String(payload.get("plan", "")) != String(key.voice_plan):
				return "A data echo does not stand in for a conversation. Keep both voice checks explicit."
		"p16_noor_live_voice":
			if payload.get("voice_checks", []) != key.voice_checks:
				return "Confirm Aurora's voice, then Earth's, before the channel opens."
		"p16_confirm_telemetry":
			if String(payload.get("report", "")) != String(key.report):
				return "The checked record credits preparation, repair and ongoing care. The garden has more than one gardener."
		"p16_start_return":
			if String(payload.get("departure", "")) != String(key.return_departure):
				return "Return starts at 03:00 on 9 April, as the journey card says."
		"p16_confirm_return_24h":
			var gates: Array = payload.get("gates", []) if payload.get("gates", []) is Array else []
			var current := 0
			for gate in gates:
				if String(gate).ends_with("_outward"):
					return "That timestamp is from the outward leg. Same road, new timestamps."
				if String(gate).ends_with("_return"):
					current += 1
			if current < int(key.return_gate_count):
				return "Confirm the current return packet at all three route gates."
		"p16_confirm_five_at_aurora":
			var arrivals: Array = payload.get("arrivals", []) if payload.get("arrivals", []) is Array else []
			for name in key.arrivals:
				if not arrivals.has(name):
					return "Three arrivals expected and checked: Ferreira, Kai and Rafi."
			if not arrivals.has("pressure_procedure"):
				return "Equalise before opening. The airlock waits for the pressure procedure."
			for name in arrivals:
				if not key.arrivals.has(name) and name != "pressure_procedure":
					return "Only the three travellers come through the airlock tonight."
		"p16_update_occupancy":
			if String(payload.get("occupancy_change", "")) != String(key.occupancy_change):
				return "Home consumption rises when the three physically return at 03:00, not when the rover leaves the summit."
		"p16_save_final_records":
			var checks: Array = payload.get("checks", []) if payload.get("checks", []) is Array else []
			for check in key.final_checks:
				if not checks.has(check):
					return "The shutter waits for all five checks: crew, seeds, pressure, temperature and the cotton."
		"p16_save_dedication":
			if not key.dedications.has(String(payload.get("dedication", ""))):
				return "Choose one of the two dedications the completed evidence supports."
	return ""

# --- Player actions -----------------------------------------------------------

## Records one player choice for one step. `field` and `value` depend on the
## step kind (see the panel). Committed steps are read-only through the route.
## Returns {accepted, reason, feedback_key}.
func select(target_id: String, field: String, value) -> Dictionary:
	var spec := step(target_id)
	if spec.is_empty():
		return _reject("Unknown Chapter 8 step: " + target_id)
	var kind := String(spec.get("kind", ""))
	var current: Dictionary = _selections.get(target_id, {}).duplicate(true)
	match kind:
		"assign":
			var boards: Array = spec.get("boards", [])
			if not (spec.get("people", []) as Array).has(field):
				return _reject("That name is not on the departure board.")
			var board_ids: Array = boards.map(func(board): return String(board.id))
			if not String(value).is_empty() and not board_ids.has(String(value)):
				return _reject("Choose the rover board or the home board.")
			var seats := 0
			for board in boards:
				if String(board.id) == String(value):
					seats = int(board.seats)
			var occupied := 0
			for person in current:
				if person != field and String(current[person]) == String(value):
					occupied += 1
			if not String(value).is_empty() and occupied >= seats:
				return _reject(String(spec.get("feedback", {}).get("seats", "That board is full.")), "seats")
			if String(value).is_empty():
				current.erase(field)
			else:
				current[field] = String(value)
		"select_many", "checks":
			var ids: Array = (spec.get("items", spec.get("checks", [])) as Array).map(func(item): return String(item.id))
			if not ids.has(field):
				return _reject("That item is not on this card.")
			current[field] = bool(value)
		"choice":
			if field != "option":
				return _reject("Choose one option.")
			var ids: Array = (spec.get("options", []) as Array).map(func(option): return String(option.id))
			if not ids.has(String(value)):
				return _reject("That option is not on this card.")
			current["option"] = String(value)
		"number":
			if field != "value" or not (value is int or value is float) or not is_finite(float(value)):
				return _reject("Enter a number.")
			var number: Dictionary = spec.get("number", {})
			current["value"] = clampf(float(value), float(number.get("min", 0)), float(number.get("max", 99)))
		"route":
			if field == "route":
				var ids: Array = (spec.get("routes", []) as Array).map(func(route): return String(route.id))
				if not ids.has(String(value)):
					return _reject("That road is not on the console.")
				current["route"] = String(value)
			elif field == "reserve":
				if not (value is int or value is float) or not is_finite(float(value)):
					return _reject("Enter a number.")
				var reserve: Dictionary = spec.get("reserve", {})
				current["reserve"] = clampf(float(value), float(reserve.get("min", 0)), float(reserve.get("max", 99)))
			else:
				return _reject("Set the road or the reserve.")
		"dial":
			var dial: Dictionary = spec.get("dial", {})
			if field == "bearing":
				if not (value is int or value is float) or not is_finite(float(value)):
					return _reject("Turn the dial to a bearing.")
				current["bearing"] = wrapf(float(value), float(dial.get("min", 0)), float(dial.get("max", 360)))
				current["preset"] = ""
			elif field == "preset":
				var found := false
				for preset in spec.get("presets", []):
					if String(preset.id) == String(value):
						current["bearing"] = float(preset.bearing)
						current["preset"] = String(value)
						found = true
				if not found:
					return _reject("That preset is not on this control.")
			else:
				return _reject("Turn the dial or pick a preset.")
		"lock":
			if field == "progress":
				current["progress"] = maxf(0.0, float(value))
				if current.progress >= float(spec.get("lock", {}).get("hold_seconds", 3)):
					current["locked"] = true
					current["method"] = "hold"
			elif field == "tap":
				current["locked"] = bool(value)
				current["method"] = "tap"
			elif field == "release":
				if not bool(current.get("locked", false)):
					current["progress"] = 0.0
			else:
				return _reject("Hold the lock or tap to confirm.")
		"procedure":
			if field == "reset":
				current = {}
			elif field == "step":
				var order: Array = current.get("sequence", []).duplicate()
				for distractor in spec.get("distractors", []):
					if String(distractor.id) == String(value):
						_count_attempt(target_id)
						return _reject(String(distractor.get("feedback", "Held.")), "distractor")
				var steps: Array = spec.get("steps", [])
				var expected := String(steps[order.size()].id) if order.size() < steps.size() else ""
				if expected.is_empty():
					return _reject("Every step of this procedure is done.")
				if String(value) != expected:
					_count_attempt(target_id)
					return _reject(String(spec.get("feedback", {}).get("order", "Do the previous step first.")), "order")
				order.append(String(value))
				current["sequence"] = order
			else:
				return _reject("Tap the next step.")
		"settings":
			var fields: Array = spec.get("fields", [])
			var matched := false
			for entry in fields:
				if String(entry.id) == field:
					for option in entry.get("options", []):
						if _same(option.value, value):
							matched = true
					if not matched:
						return _reject("That setting is not available.")
			if not matched:
				return _reject("That setting is not on this panel.")
			current[field] = value
		"confirm":
			current["confirmed"] = bool(value)
		_:
			return _reject("This step has no decision to record.")
	_selections[target_id] = current
	return {"accepted": true, "reason": "", "selection": current.duplicate(true)}

## Clears the step's selection (Undo). Nothing committed changes.
func reset(target_id: String) -> void:
	_selections.erase(target_id)

func selection(target_id: String) -> Dictionary:
	return _selections.get(target_id, {}).duplicate(true)

## Builds the exact payload for the ledger from the current selection.
## `context` supplies live readings the payload must carry: the departure
## battery `capacity` and the `allowance` for the reserve arithmetic. Returns {accepted, reason, payload,
## feedback_key, option_id}; an incomplete selection is rejected with what is missing.
func payload_for(target_id: String, context: Dictionary = {}) -> Dictionary:
	var spec := step(target_id)
	if spec.is_empty():
		return _reject("Unknown Chapter 8 step: " + target_id)
	var current: Dictionary = _selections.get(target_id, {})
	var kind := String(spec.get("kind", ""))
	var key := String(spec.get("payload_key", ""))
	var payload := {}
	var option_id := ""
	match kind:
		"assign":
			for board in spec.get("boards", []):
				payload[String(board.id)] = []
			for person in current:
				payload[String(current[person])].append(String(person))
			for board in spec.get("boards", []):
				if payload[String(board.id)].size() != int(board.seats):
					return _reject("Every name needs a board: %d on the rover, %d at home." % [int(spec.boards[0].seats), int(spec.boards[1].seats)], "incomplete")
			var feedback: Dictionary = spec.get("feedback", {})
			for person in current:
				var feedback_key := "%s_on_%s" % [String(person), String(current[person])]
				if feedback.has(feedback_key):
					return {"accepted": true, "reason": "", "payload": payload, "feedback_key": feedback_key, "option_id": ""}
		"select_many", "checks":
			var chosen: Array = []
			for item in spec.get("items", spec.get("checks", [])):
				if bool(current.get(String(item.id), false)):
					chosen.append(String(item.id))
			if chosen.is_empty():
				return _reject("Tick at least one item before trying it.", "incomplete")
			payload[key] = chosen
		"choice":
			option_id = String(current.get("option", ""))
			if option_id.is_empty():
				return _reject("Choose one option first.", "incomplete")
			for option in spec.get("options", []):
				if String(option.id) == option_id:
					payload = option.get("payload", {}).duplicate(true)
		"number":
			if not current.has("value"):
				return _reject("Enter the number first.", "incomplete")
			payload[key] = current.value
			if target_id == "p15_confirm_return_reserve":
				# The departure battery (14, or 18 with the earned long-range battery),
				# not the battery after the outward allowance was spent.
				payload["energy"] = float(context.get("capacity", context.get("energy", 0)))
				payload["allowance"] = float(context.get("allowance", 0))
		"route":
			if not current.has("route"):
				return _reject("Choose a road first.", "incomplete")
			if not current.has("reserve"):
				return _reject("Mark the battery that must stay unavailable.", "incomplete")
			option_id = String(current.route)
			payload = {"route": current.route, "reserve": current.reserve}
		"dial":
			if not current.has("bearing"):
				return _reject("Turn the dial first.", "incomplete")
			var preset := _preset_at(spec, float(current.bearing))
			option_id = String(preset.get("id", ""))
			if target_id == "p15_reach_marker_two":
				payload = {"bearing": float(current.bearing)}
			else:
				payload = {"bearing": option_id}
		"lock":
			if not bool(current.get("locked", false)):
				return _reject("Hold the lock, or tap to confirm.", "incomplete")
			payload = {"lock": "stable", "method": String(current.get("method", "hold"))}
		"procedure":
			var order: Array = current.get("sequence", [])
			if order.size() < (spec.get("steps", []) as Array).size():
				return _reject("Finish every step of the procedure card first.", "incomplete")
			payload[key] = order.duplicate()
		"settings":
			for entry in spec.get("fields", []):
				if not current.has(String(entry.id)):
					return _reject("Set %s first." % String(entry.label).to_lower(), "incomplete")
				payload[String(entry.id)] = current[String(entry.id)]
		"confirm":
			if not bool(current.get("confirmed", false)):
				return _reject("Read the line, then confirm it.", "incomplete")
			payload = spec.get("payload", {}).duplicate(true)
	return {"accepted": true, "reason": "", "payload": payload, "feedback_key": "", "option_id": option_id}

## The teaching sentence for a rejected attempt, from the step's own data:
## the chosen option's feedback, or the kind-level feedback for the reason.
func feedback_for(target_id: String, option_id: String, feedback_key: String, ledger_reason: String) -> String:
	var spec := step(target_id)
	var feedback: Dictionary = spec.get("feedback", {})
	if not feedback_key.is_empty() and feedback.has(feedback_key):
		return String(feedback[feedback_key])
	for option in spec.get("options", []) + spec.get("routes", []):
		if String(option.id) == option_id and not String(option.get("feedback", "")).is_empty():
			return String(option.feedback)
	for preset in spec.get("presets", []):
		if String(preset.id) == option_id and not String(preset.get("obstruction", "")).is_empty():
			return String(preset.obstruction)
	match String(spec.get("kind", "")):
		"select_many", "checks":
			var low := ledger_reason.to_lower()
			if feedback.has("forbidden") and (low.contains("only") or low.contains("not yet") or low.contains("outward") or low.contains("noor")):
				return String(feedback.forbidden)
			return String(feedback.get("missing", ledger_reason))
		"number":
			return String(feedback.get("low" if ledger_reason.contains("minimum") else "wrong", ledger_reason))
		"route":
			return String(feedback.get("reserve_low", ledger_reason)) if ledger_reason.contains("reserve") else ledger_reason
		"dial":
			return String(feedback.get("off", ledger_reason))
		"settings":
			var key := rules()
			for field in key.get("home_loop", {}):
				if String(_selections.get(target_id, {}).get(field, "")) != String(key.home_loop[field]) and feedback.has(field):
					return String(feedback[field])
			return String(feedback.get("air_total", ledger_reason))
	return ledger_reason

## The advisory (amber) text for an accepted choice, when the data names one.
func advisory_for(target_id: String, option_id: String) -> String:
	for option in step(target_id).get("options", []):
		if String(option.id) == option_id:
			return String(option.get("advisory", ""))
	return ""

## Records a rejected preview; Family mode offers H1 after the first one.
func count_attempt(target_id: String) -> int:
	return _count_attempt(target_id)

func attempts(target_id: String) -> int:
	return int(_attempts.get(target_id, 0))

## Marks a clue as inspected. Required clues are never hidden; this records reading.
func find_clue(scene_id: String, clue_id: String) -> Dictionary:
	var ids: Array = (scene(scene_id).get("clues", []) as Array).map(func(entry): return String(entry.id))
	if not ids.has(clue_id):
		return _reject("That clue is not in this scene.")
	var found: Array = _found.get(scene_id, []).duplicate()
	if found.has(clue_id):
		return {"accepted": true, "duplicate": true, "reason": "Already on the evidence board."}
	found.append(clue_id)
	_found[scene_id] = found
	return {"accepted": true, "duplicate": false, "reason": "Filed to the evidence board."}

func found_clues(scene_id: String) -> Array:
	return _found.get(scene_id, []).duplicate()

## Reveals the next hint tier for a step. Hints never change an outcome.
func reveal_hint(target_id: String) -> Dictionary:
	var ladder := hint_ladder(target_id)
	var level := int(_hints.get(target_id, 0))
	if level >= ladder.size():
		return _reject("Every hint for this step is already shown.")
	_hints[target_id] = level + 1
	return {"accepted": true, "level": level + 1, "label": "H%d" % (level + 1), "text": String(ladder[level])}

func revealed_hints(target_id: String) -> Array:
	var ladder := hint_ladder(target_id)
	var result: Array = []
	for index in mini(int(_hints.get(target_id, 0)), ladder.size()):
		result.append({"label": "H%d" % (index + 1), "text": String(ladder[index])})
	return result

## One role signs the Go/No-Go poll for a step (Class mode: each group signs its own).
func sign_poll(target_id: String, role_id: String) -> Dictionary:
	var roles: Array = step(target_id).get("poll", [])
	if not roles.has(role_id):
		return _reject("That role is not polled for this decision.")
	var signed: Array = _polls.get(target_id, []).duplicate()
	if not signed.has(role_id):
		signed.append(role_id)
	_polls[target_id] = signed
	return {"accepted": true, "reason": "%s signed." % String(role(role_id).get("name", role_id))}

func signed_roles(target_id: String) -> Array:
	return _polls.get(target_id, []).duplicate()

## The poll bar: GO / ADVISORY / NO-GO per polled role from the latest check.
func poll_status(target_id: String, accepted: bool, reason: String, advisory: String) -> Array:
	var spec := step(target_id)
	var result: Array = []
	for role_id in spec.get("poll", []):
		var status := "GO"
		var note := ""
		if not accepted and String(spec.get("no_go_role", "")) == String(role_id):
			status = "NO-GO"
			note = reason
		elif not accepted:
			status = "HOLD"
			note = "Waiting for the check."
		elif not advisory.is_empty():
			status = "ADVISORY"
			note = advisory
		result.append({"role_id": role_id, "name": String(role(role_id).get("name", role_id)), "status": status, "note": note, "signed": signed_roles(target_id).has(role_id)})
	return result

func mark_first_time_seen(puzzle_id: String) -> void:
	_first_time_seen[puzzle_id] = true

func first_time_seen(puzzle_id: String) -> bool:
	return bool(_first_time_seen.get(puzzle_id, false))

func flags() -> Dictionary:
	var result := {}
	for target_id in _selections:
		if String(target_id) == "p16_save_dedication":
			result["chapter8_dedication_chosen"] = _selections[target_id].has("option")
	return result

# --- Persistence ---------------------------------------------------------------

func snapshot() -> Dictionary:
	return {"schema_version": SCHEMA_VERSION, "selections": _selections.duplicate(true), "found": _found.duplicate(true), "hints": _hints.duplicate(true), "polls": _polls.duplicate(true), "attempts": _attempts.duplicate(true), "first_time_seen": _first_time_seen.duplicate(true)}

func restore(data_in: Dictionary) -> Dictionary:
	var version = data_in.get("schema_version", 0)
	if not (version is int or version is float) or float(version) != float(SCHEMA_VERSION):
		return _reject("Chapter 8 puzzle snapshot is incompatible.")
	for key in ["selections", "found", "hints", "polls", "attempts", "first_time_seen"]:
		if not data_in.get(key, null) is Dictionary:
			return _reject("Chapter 8 puzzle snapshot requires a Dictionary for " + key + ".")
	for target_id in data_in.selections:
		if not is_step(String(target_id)) or not data_in.selections[target_id] is Dictionary:
			return _reject("Chapter 8 selections name an unknown step.")
	for scene_id in data_in.found:
		if not data_in.found[scene_id] is Array:
			return _reject("Chapter 8 found clues must be arrays.")
	for target_id in data_in.hints:
		var level = data_in.hints[target_id]
		if not (level is int or level is float) or float(level) < 0 or float(level) > hint_ladder(String(target_id)).size():
			return _reject("Chapter 8 hint levels are outside the ladder.")
	_selections = data_in.selections.duplicate(true)
	_found = data_in.found.duplicate(true)
	_hints = data_in.hints.duplicate(true)
	_polls = data_in.polls.duplicate(true)
	_attempts = data_in.attempts.duplicate(true)
	_first_time_seen = data_in.first_time_seen.duplicate(true)
	return {"accepted": true, "reason": "Chapter 8 puzzle state restored."}

# --- Helpers -------------------------------------------------------------------

## The preset whose bearing lies within the dial's tolerance of `bearing`, or {}.
static func _preset_at(spec: Dictionary, bearing: float) -> Dictionary:
	var tolerance := float(rules().get("bearing_tolerance", 2.0))
	var best := {}
	var best_delta := INF
	for preset in spec.get("presets", []):
		var delta := absf(_bearing_delta(bearing, float(preset.bearing)))
		if delta <= tolerance and delta < best_delta:
			best = preset
			best_delta = delta
	return best

## The signal reading for the dial's current bearing: strength and obstruction text.
static func dial_reading(target_id: String, bearing: float) -> Dictionary:
	var spec := step(target_id)
	var preset := _preset_at(spec, bearing)
	if preset.is_empty():
		return {"preset": "", "label": "", "strength": "no signal", "obstruction": String(spec.get("feedback", {}).get("off", ""))}
	return {"preset": String(preset.id), "label": String(preset.label), "strength": String(preset.strength), "obstruction": String(preset.get("obstruction", ""))}

static func _bearing_delta(a: float, b: float) -> float:
	return wrapf(a - b, -180.0, 180.0)

static func _sorted(values) -> Array:
	var result: Array = []
	if values is Array:
		for value in values:
			result.append(String(value))
	result.sort()
	return result

static func _segments(values) -> Array:
	var result: Array = []
	if values is Array:
		for pair in values:
			if pair is Array and pair.size() == 2:
				result.append([int(pair[0]), int(pair[1])])
	return result

static func _same(a, b) -> bool:
	if (a is int or a is float) and (b is int or b is float):
		return is_equal_approx(float(a), float(b))
	return typeof(a) == typeof(b) and a == b

func _count_attempt(target_id: String) -> int:
	_attempts[target_id] = int(_attempts.get(target_id, 0)) + 1
	return int(_attempts[target_id])

func _reject(reason: String, feedback_key: String = "") -> Dictionary:
	return {"accepted": false, "reason": reason, "feedback_key": feedback_key, "payload": {}, "option_id": ""}
