extends RefCounted
class_name CampaignState

## Authoritative primitive state for the full campaign and its presentation.

const SCHEMA_VERSION := 3
const CONTENT_REVISION := "story-data-extended-02-systems-contract"
const PlantScript = preload("res://scripts/biology/plant_service.gd")
const ContentScript = preload("res://scripts/content/content_loader.gd")
# Reserved storage identity only; no proposed dedication text is introduced.
const EXTRA_STORY_CHOICES := {"EX-CH03-S11-DEDICATION": "EX-CH03-S11"}
# presentation_resume.messages (M1-89) is the inbox record: the message IDs
# delivered and read, each in arrival order. These are schema bounds, not
# tuning: the campaign ships about 400 messages with IDs like MSG-CH01-001.
const MESSAGE_FIELDS := ["delivered_ids", "read_ids"]
const MESSAGE_ID_MAX_LENGTH := 64
const MESSAGE_ID_LIMIT := 2048
# Session crew setup (M1-102), chosen once at New Expedition: mode -> the
# inclusive [min, max] player count. Saves without "crew" read as Solo/1.
const CREW_PLAYER_RANGE := {"solo": [1, 1], "class": [2, 4]}
const DEFAULT_CREW := {"mode": "solo", "players": 1}
static var _story_choices: Dictionary = {}

## Creates an independent, primitive snapshot in the current save schema.
static func new_snapshot(content_revision: String = "") -> Dictionary:
	var revision := content_revision if not content_revision.is_empty() else CONTENT_REVISION
	return {
		"schema_version": SCHEMA_VERSION,
		"content_revision": revision,
		"save_id": "aurora-expedition",
		"checkpoint_id": "EX-CH01-S04-CHECKPOINT",
		"state_revision": 0,
		"chapter_id": "CH01",
		"mission_id": "EX-M0102",
		"scene_id": "EX-CH01-S04",
		"scene_phase": "planning",
		"completed_scene_ids": ["EX-CH01-S01", "EX-CH01-S02", "EX-CH01-S03"],
		"mission_receipts": {},
		"interaction_receipts": {},
		"receipts": {},
		"acquired_evidence_ids": [],
		"knowledge_flags": ["aurora_commissioning", "p02_contract_loaded"],
		"knowledge": ["aurora_commissioning", "p02_contract_loaded"],
		"dialogue_cursor": 0,
		"acknowledged_line_ids": [],
		"story_log": {"choices": {}, "moments": []},
		"scenario_datetime": "2046-04-25 00:00 UTC",
		"current_shift": 0,
		"travel_segment": 0,
		"explicit_time_receipts": {},
		"actors": {
			"kai": {"physical_location_id": "LOC-01", "anchor_id": "commons_kai", "team_id": "base"},
			"amara": {"physical_location_id": "LOC-01", "anchor_id": "commons_amara", "team_id": "base"},
			"mei": {"physical_location_id": "LOC-01", "anchor_id": "commons_mei", "team_id": "base"},
			"rafi": {"physical_location_id": "LOC-01", "anchor_id": "commons_rafi", "team_id": "base"},
		},
		"resources": {
			"E": 14,
			"A": 6,
			"H": 6,
			"W": 0,
			"K": 0,
			"C": 8,
			"R": 12.0,
			"Z": 0,
			"energy_capacity": 20,
			"air_capacity": 10,
			"health_capacity": 10,
			"water_capacity": 6,
			"crate_capacity": 2,
			"crop_capacity": 10,
		},
		"plants": [],
		"inventories": {
			"founder_seed42": {"total": 42, "allocated": 12, "reserve": 30, "reserve_compartments": [15, 15]},
			"allocated12": 12,
			"reserve30": 30,
			"vault12": {"total": 12, "stored": 12, "cotton_planted": 0, "stored_after_cotton": 12},
			"cotton_planted": 0,
			"stored12": 12,
			"stored11": 0,
			"album16": {"entries": 0, "physical_seeds": 0},
		},
		"upgrades": {
			"acquisition_chapter": {},
			"choices": {},
			"applied_profile_revision": "p02-base-v1",
		},
		"route": {
			"trip_id": "",
			"roster": [],
			"local_hops": [],
			"earth_leg": "unverified",
			"provisions": 72,
			"departure": "",
			"elapsed_hours": 0,
			"return": "",
		},
		"settings_revision": 1,
		"accessibility": {
			"captions": true,
			"large_text": false,
			"timer_free": true,
			"reduced_motion": false,
		},
		"presentation_resume": {},
		"status": "active",
		"paused": false,
	}

static func copy_snapshot(snapshot: Dictionary) -> Dictionary:
	return snapshot.duplicate(true)

static func is_compatible(snapshot: Dictionary, content_revision: String = "") -> bool:
	if not bool(validate_snapshot(snapshot).get("valid", false)):
		return false
	if not content_revision.is_empty() and String(snapshot.get("content_revision", "")) != content_revision:
		return false
	return true

## Checks the current schema, including catalog identities and story metadata.
static func validate_snapshot(snapshot: Dictionary) -> Dictionary:
	var defaults := new_snapshot()
	for key in defaults:
		if not snapshot.has(key):
			return {"valid": false, "reason": "Campaign snapshot is missing " + key}
		var expected_type := typeof(defaults[key])
		var value = snapshot[key]
		if expected_type in [TYPE_INT, TYPE_FLOAT]:
			if not _finite_number(value) or float(value) != floor(float(value)) or float(value) < 0:
				return {"valid": false, "reason": "Campaign counter must be a nonnegative integer: " + key}
		elif typeof(value) != expected_type:
			return {"valid": false, "reason": "Campaign snapshot has an invalid type for " + key}
	if int(snapshot.schema_version) != SCHEMA_VERSION or int(snapshot.current_shift) > 7:
		return {"valid": false, "reason": "Campaign schema or shift is outside the supported contract."}
	if not is_scenario_datetime(snapshot.scenario_datetime):
		return {"valid": false, "reason": "Campaign scenario time must be a valid UTC date and minute."}
	var story_check := _validate_story_log(snapshot)
	if not story_check.valid:
		return story_check
	for key in defaults.resources:
		if not snapshot.resources.has(key) or not _finite_number(snapshot.resources[key]) or float(snapshot.resources[key]) < 0:
			return {"valid": false, "reason": "Campaign resource must be a finite nonnegative number: " + key}
	for key in ["receipts", "mission_receipts", "interaction_receipts"]:
		for receipt in snapshot[key].values():
			if not receipt is Dictionary:
				return {"valid": false, "reason": "Campaign receipts must contain Dictionaries."}
	for plant in snapshot.plants:
		if not plant is Dictionary:
			return {"valid": false, "reason": "Campaign plants must contain identified primitive plants."}
		var plant_check: Dictionary = PlantScript.new().validate_plant(plant)
		if not bool(plant_check.get("valid", false)):
			return plant_check
	for key in defaults.accessibility:
		if not snapshot.accessibility.get(key, null) is bool:
			return {"valid": false, "reason": "Campaign accessibility setting must be a boolean: " + key}
	# Saves written before M1-89 have no messages record; they read as empty.
	if snapshot.presentation_resume.has("messages"):
		var message_problem := message_metadata_problem(snapshot.presentation_resume.messages)
		if not message_problem.is_empty():
			return {"valid": false, "reason": message_problem}
	if snapshot.has("blackout_count") and (not _finite_number(snapshot.blackout_count) or float(snapshot.blackout_count) != floor(float(snapshot.blackout_count)) or float(snapshot.blackout_count) < 0):
		return {"valid": false, "reason": "Campaign blackout count must be a nonnegative integer."}
	if snapshot.has("crew"):
		var crew_check := crew_problem(snapshot.crew)
		if not crew_check.is_empty():
			return {"valid": false, "reason": crew_check}
	if snapshot.has("campaign_ledgers"):
		var book = snapshot.campaign_ledgers
		if not book is Dictionary:
			return {"valid": false, "reason": "Campaign ledgers must be a primitive Dictionary."}
		for field in ["profiles", "puzzles", "operations"]:
			if not book.get(field) is Dictionary:
				return {"valid": false, "reason": "Campaign ledger collection is invalid: " + field}
		if not book.get("entries") is Array or not _finite_number(book.get("food_sampled")) or float(book.food_sampled) < 0 or not book.get("food_period_start") is String or not is_scenario_datetime(book.food_period_start):
			return {"valid": false, "reason": "Campaign ledger entries or food interval is invalid."}
		for puzzle in book.puzzles.values():
			if not puzzle is Dictionary or not puzzle.get("operations") is Dictionary or not puzzle.get("samples") is Array or not _finite_number(puzzle.get("phase")) or float(puzzle.phase) < 0 or float(puzzle.phase) != floor(float(puzzle.phase)):
				return {"valid": false, "reason": "Campaign puzzle ledger shape is invalid."}
	return {"valid": true, "reason": "Campaign state shape is valid."}

## Returns an empty string when crew is exactly {"mode": String, "players":
## whole finite number} with mode in CREW_PLAYER_RANGE and players in its
## range (Solo 1, Class 2-4). Otherwise the rejection reason.
static func crew_problem(crew: Variant) -> String:
	if not crew is Dictionary or crew.size() != 2 or not crew.has("mode") or not crew.has("players"):
		return "Campaign crew must be exactly {mode, players}."
	if not crew.mode is String or not CREW_PLAYER_RANGE.has(crew.mode):
		return "Campaign crew mode must be solo or class."
	var players = crew.players
	if not _finite_number(players) or float(players) != floor(float(players)):
		return "Campaign crew players must be a whole number."
	var bounds: Array = CREW_PLAYER_RANGE[crew.mode]
	if float(players) < bounds[0] or float(players) > bounds[1]:
		return "Campaign crew players is out of range for %s: %d-%d." % [crew.mode, bounds[0], bounds[1]]
	return ""

## The snapshot's crew as {"mode": String, "players": int}; Solo/1 when the
## save predates the field. Call on validated snapshots only.
static func crew_of(snapshot: Dictionary) -> Dictionary:
	var crew = snapshot.get("crew", DEFAULT_CREW)
	return {"mode": String(crew.mode), "players": int(crew.players)}

## Returns a copy of presentation_resume.messages as
## {"delivered_ids": Array, "read_ids": Array}. A fresh New, or a save written
## before the record existed, reads as two empty arrays.
static func message_metadata(snapshot: Dictionary) -> Dictionary:
	var result := {"delivered_ids": [], "read_ids": []}
	var resume = snapshot.get("presentation_resume", {})
	var stored = resume.get("messages", {}) if resume is Dictionary else {}
	if stored is Dictionary:
		for field in MESSAGE_FIELDS:
			var ids = stored.get(field, [])
			if ids is Array:
				result[field] = ids.duplicate()
	return result

## Returns an empty string when a messages record follows the M1-89 schema:
## only delivered_ids and read_ids (either may be absent), each an Array of
## unique message IDs, and every read ID also delivered. Otherwise the reason.
static func message_metadata_problem(messages: Variant) -> String:
	if not messages is Dictionary:
		return "presentation_resume.messages must be a Dictionary."
	for key in messages:
		if not key is String or not MESSAGE_FIELDS.has(key):
			return "presentation_resume.messages has an unknown field: " + str(key)
	var delivered := {}
	for field in MESSAGE_FIELDS:
		var ids = messages.get(field, [])
		var problem := message_ids_problem(ids, field)
		if not problem.is_empty():
			return problem
		var seen := {}
		for id in ids:
			if seen.has(id):
				return "Message %s lists %s twice." % [field, id]
			seen[id] = true
			if field == "read_ids" and not delivered.has(id):
				return "Message %s is marked read but was never delivered." % id
		if field == "delivered_ids":
			delivered = seen
	return ""

## Returns an empty string when ids is an Array of at most MESSAGE_ID_LIMIT
## message IDs: nonempty Strings of at most MESSAGE_ID_MAX_LENGTH characters
## with no surrounding whitespace. Otherwise the rejection reason.
static func message_ids_problem(ids: Variant, field: String) -> String:
	if not ids is Array:
		return "Message %s must be an Array of message ID Strings." % field
	if ids.size() > MESSAGE_ID_LIMIT:
		return "Message %s holds more than %d IDs." % [field, MESSAGE_ID_LIMIT]
	for id in ids:
		if not id is String or String(id).is_empty() or String(id) != String(id).strip_edges() or String(id).length() > MESSAGE_ID_MAX_LENGTH:
			return "Message %s must hold nonempty ID Strings without surrounding spaces, at most %d characters." % [field, MESSAGE_ID_MAX_LENGTH]
	return ""

## Resolves a choice's owning scene from the existing campaign catalog.
static func story_choice_scene_id(choice_id: String) -> String:
	_load_story_choices()
	return String(_story_choices.get(choice_id, {}).get("scene_id", EXTRA_STORY_CHOICES.get(choice_id, "")))

## Returns a rejection reason, or an empty string for a supported option.
static func story_choice_problem(choice_id: String, option_id: String) -> String:
	_load_story_choices()
	if option_id.strip_edges().is_empty():
		return "A story choice requires a nonempty option_id."
	if _story_choices.has(choice_id):
		return "" if _story_choices[choice_id].options.has(option_id) else "Unknown option_id for story choice " + choice_id
	return "" if EXTRA_STORY_CHOICES.has(choice_id) else "Unknown story choice_id: " + choice_id

## Exit receipts lock immediately, including before the route changes scenes.
static func story_choice_locked(snapshot: Dictionary, choice_id: String) -> bool:
	var scene_id := story_choice_scene_id(choice_id)
	return not scene_id.is_empty() and (snapshot.get("completed_scene_ids", []).has(scene_id) or snapshot.get("receipts", {}).has("scene-complete:" + scene_id) or snapshot.get("scene_phase", "") == "scene_complete:" + scene_id)

static func _load_story_choices() -> void:
	if not _story_choices.is_empty():
		return
	for scene in ContentScript.load_full().get("scenes", []):
		var choice: Dictionary = scene.get("choice", {})
		var options: Array = []
		for option in choice.get("options", []):
			options.append(option.id)
		_story_choices[String(choice.get("id", ""))] = {"scene_id": scene.id, "options": options}

static func _validate_story_log(snapshot: Dictionary) -> Dictionary:
	var log: Dictionary = snapshot.story_log
	if not log.get("choices") is Dictionary or not log.get("moments") is Array:
		return {"valid": false, "reason": "story_log requires choices Dictionary and moments Array."}
	for choice_id in log.choices:
		if not choice_id is String or not log.choices[choice_id] is Dictionary:
			return {"valid": false, "reason": "Story choices must map String IDs to Dictionaries."}
		var entry: Dictionary = log.choices[choice_id]
		for field in ["option_id", "scene_id", "scenario_datetime"]:
			if not entry.get(field) is String:
				return {"valid": false, "reason": "Story choice requires a String for " + field}
		var problem := story_choice_problem(choice_id, entry.option_id)
		if not problem.is_empty():
			return {"valid": false, "reason": problem}
		if entry.scene_id != story_choice_scene_id(choice_id):
			return {"valid": false, "reason": "Story choice scene_id does not match its catalog owner."}
		if not is_scenario_datetime(entry.scenario_datetime) or entry.scenario_datetime > snapshot.scenario_datetime:
			return {"valid": false, "reason": "Story choice scenario_datetime must be valid and no later than the snapshot."}
		var revision = entry.get("state_revision")
		if not _finite_number(revision) or float(revision) < 0 or float(revision) != floor(float(revision)) or float(revision) > float(snapshot.state_revision):
			return {"valid": false, "reason": "Story choice state_revision must be a nonnegative integer no later than the snapshot."}
	var seen := {}
	for moment in log.moments:
		if not moment is String or moment.strip_edges().is_empty() or seen.has(moment):
			return {"valid": false, "reason": "Story moments must be unique nonempty Strings."}
		seen[moment] = true
	return {"valid": true}

static func _finite_number(value) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func is_scenario_datetime(value: String) -> bool:
	if value.length() != 20 or value[4] != "-" or value[7] != "-" or value[10] != " " or value[13] != ":" or not value.ends_with(" UTC"):
		return false
	for part in [value.substr(0, 4), value.substr(5, 2), value.substr(8, 2), value.substr(11, 2), value.substr(14, 2)]:
		if not part.is_valid_int() or part.begins_with("+") or part.begins_with("-"):
			return false
	var year := int(value.substr(0, 4))
	var month := int(value.substr(5, 2))
	var day := int(value.substr(8, 2))
	if year < 1 or month < 1 or month > 12 or int(value.substr(11, 2)) > 23 or int(value.substr(14, 2)) > 59:
		return false
	var month_days := [31, 29 if year % 4 == 0 and (year % 100 != 0 or year % 400 == 0) else 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	return day >= 1 and day <= int(month_days[month - 1])

static func from_slice_snapshot(slice: Dictionary) -> Dictionary:
	## Bounded compatibility adapter. It only reads the commissioning shape and
	## never writes to the retired commissioning save slot.
	var result := new_snapshot()
	result["save_id"] = String(slice.get("save_id", result["save_id"]))
	result["checkpoint_id"] = String(slice.get("checkpoint_id", result["checkpoint_id"]))
	result["state_revision"] = int(slice.get("state_revision", 0))
	result["chapter_id"] = String(slice.get("chapter_id", "CH01"))
	result["mission_id"] = String(slice.get("mission_id", "EX-M0101"))
	result["scene_id"] = String(slice.get("scene_id", "EX-CH01-S01"))
	result["scene_phase"] = String(slice.get("scene_phase", "briefing"))
	result["completed_scene_ids"] = slice.get("completed_scene_ids", []).duplicate(true)
	result["scenario_datetime"] = String(slice.get("scenario_datetime", result["scenario_datetime"]))
	result["receipts"] = slice.get("receipts", {}).duplicate(true)
	result["mission_receipts"] = result["receipts"].duplicate(true)
	result["knowledge"] = slice.get("knowledge", []).duplicate(true)
	result["knowledge_flags"] = result["knowledge"].duplicate(true)
	var source_resources: Dictionary = slice.get("resources", {})
	var resources: Dictionary = result["resources"]
	for pair in [["energy", "E"], ["air", "A"], ["alo_health", "H"], ["water_shielding", "W"], ["crate_shielding", "K"], ["crop_condition", "C"], ["rations", "R"], ["exposure", "Z"]]:
		if source_resources.has(pair[0]):
			resources[pair[1]] = source_resources[pair[0]]
	result["resources"] = resources
	return result

static func to_slice_like(snapshot: Dictionary) -> Dictionary:
	## Read-only view for a future bounded adapter. No scene or Node references.
	var resources: Dictionary = snapshot.get("resources", {})
	return {
		"schema_version": 1,
		"content_revision": String(snapshot.get("content_revision", CONTENT_REVISION)),
		"save_id": String(snapshot.get("save_id", "aurora-expedition")),
		"state_revision": int(snapshot.get("state_revision", 0)),
		"checkpoint_id": String(snapshot.get("checkpoint_id", "")),
		"chapter_id": String(snapshot.get("chapter_id", "CH01")),
		"mission_id": String(snapshot.get("mission_id", "EX-M0102")),
		"scene_id": String(snapshot.get("scene_id", "")),
		"scene_phase": String(snapshot.get("scene_phase", "")),
		"completed_scene_ids": snapshot.get("completed_scene_ids", []).duplicate(true),
		"receipts": snapshot.get("receipts", {}).duplicate(true),
		"knowledge": snapshot.get("knowledge", []).duplicate(true),
		"dialogue_cursor": int(snapshot.get("dialogue_cursor", 0)),
		"scenario_datetime": String(snapshot.get("scenario_datetime", "")),
		"resources": {
			"energy": resources.get("E", 0),
			"energy_capacity": resources.get("energy_capacity", 20),
			"air": resources.get("A", 0),
			"air_capacity": resources.get("air_capacity", 10),
			"alo_health": resources.get("H", 0),
			"water_shielding": resources.get("W", 0),
			"crate_shielding": resources.get("K", 0),
			"crop_condition": resources.get("C", 0),
			"rations": resources.get("R", 0),
			"exposure": resources.get("Z", 0),
		},
		"settings": snapshot.get("accessibility", {}).duplicate(true),
		"status": String(snapshot.get("status", "active")),
	}
