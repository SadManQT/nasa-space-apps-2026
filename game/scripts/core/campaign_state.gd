extends RefCounted
class_name CampaignState

## Authoritative primitive state for the full campaign and its presentation.

const SCHEMA_VERSION := 2
const CONTENT_REVISION := "story-data-extended-02-systems-contract"
const PlantScript = preload("res://scripts/biology/plant_service.gd")

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
	if snapshot.has("blackout_count") and (not _finite_number(snapshot.blackout_count) or float(snapshot.blackout_count) != floor(float(snapshot.blackout_count)) or float(snapshot.blackout_count) < 0):
		return {"valid": false, "reason": "Campaign blackout count must be a nonnegative integer."}
	return {"valid": true, "reason": "Campaign state shape is valid."}

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
