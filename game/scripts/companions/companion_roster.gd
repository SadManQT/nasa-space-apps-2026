extends RefCounted
class_name CompanionRoster

## Physical presence is explicit and separate from dialogue/radio presence.
## The service returns primitive placement dictionaries; it never instantiates
## a character or changes campaign arithmetic.

const ACTOR_IDS := ["kai", "amara", "mei", "rafi", "ferreira"]
const CADET_IDS := ["kai", "amara", "mei", "rafi"]

const _SCENE_LAYOUTS := {
	"EX-CH01-S01": {"kai": ["LOC-01", "commons_kai", "base"], "amara": ["LOC-01", "commons_amara", "base"], "mei": ["LOC-01", "commons_mei", "base"], "rafi": ["LOC-01", "commons_rafi", "base"], "ferreira": ["EARTH_SCREEN", "ferreira_earth_screen", "remote"]},
	"EX-CH01-S02": {"kai": ["LOC-04", "safe_kai", "base"], "amara": ["LOC-04", "safe_amara", "base"], "mei": ["LOC-04", "safe_mei", "base"], "rafi": ["LOC-04", "safe_rafi", "base"], "ferreira": ["EARTH_SCREEN", "ferreira_earth_screen", "remote"]},
	"EX-CH01-S03": {"kai": ["LOC-01", "commons_kai", "base"], "amara": ["LOC-01", "commons_amara", "base"], "mei": ["LOC-01", "commons_mei", "base"], "rafi": ["LOC-01", "commons_rafi", "base"], "ferreira": ["EARTH_SCREEN", "ferreira_earth_screen", "remote"]},
	"EX-CH01-S04": {"kai": ["LOC-03", "garden_kai", "base"], "amara": ["LOC-03", "garden_amara", "base"], "mei": ["LOC-03", "garden_mei", "base"], "rafi": ["LOC-03", "garden_rafi", "base"], "ferreira": ["EARTH_SCREEN", "ferreira_earth_screen", "remote"]},
	"EX-CH01-S05": {"kai": ["LOC-02", "service_kai", "base"], "amara": ["LOC-02", "service_amara", "base"], "mei": ["LOC-03", "garden_mei", "base"], "rafi": ["LOC-02", "service_rafi", "base"], "ferreira": ["EARTH_SCREEN", "ferreira_earth_screen", "remote"]},
	"EX-CH01-S06": {"kai": ["LOC-01", "commons_kai", "base"], "amara": ["LOC-01", "commons_amara", "base"], "mei": ["LOC-01", "commons_mei", "base"], "rafi": ["LOC-01", "commons_rafi", "base"], "ferreira": ["EARTH_SCREEN", "ferreira_earth_screen", "remote"]},
	"EX-CH01-S07": {"kai": ["LOC-02", "service_kai", "base"], "amara": ["LOC-02", "service_amara", "base"], "mei": ["LOC-03", "garden_mei", "base"], "rafi": ["LOC-02", "service_rafi", "base"], "ferreira": ["EARTH_SCREEN", "ferreira_earth_screen", "remote"]},
	"EX-CH01-S08": {"kai": ["LOC-04", "safe_kai", "base"], "amara": ["LOC-04", "safe_amara", "base"], "mei": ["LOC-04", "safe_mei", "base"], "rafi": ["LOC-04", "safe_rafi", "base"], "ferreira": ["EARTH_SCREEN", "ferreira_earth_screen", "remote"]},
	"EX-CH01-S09": {"kai": ["LOC-01", "commons_kai", "base"], "amara": ["LOC-01", "commons_amara", "base"], "mei": ["LOC-01", "commons_mei", "base"], "rafi": ["LOC-01", "commons_rafi", "base"], "ferreira": ["EARTH_SCREEN", "ferreira_earth_screen", "remote"]},
	"EX-CH01-S10": {"kai": ["LOC-04", "safe_kai", "base"], "amara": ["LOC-04", "safe_amara", "base"], "mei": ["LOC-04", "safe_mei", "base"], "rafi": ["LOC-04", "safe_rafi", "base"], "ferreira": ["EARTH_SCREEN", "ferreira_earth_screen", "remote"]},
	"EX-CH01-S11": {"kai": ["LOC-01", "commons_kai", "base"], "amara": ["LOC-03", "garden_amara", "base"], "mei": ["LOC-03", "garden_mei", "base"], "rafi": ["LOC-01", "commons_rafi", "base"], "ferreira": ["EARTH_SCREEN", "ferreira_earth_screen", "remote"]},
	"EX-CH01-S12": {"kai": ["LOC-03", "garden_kai", "base"], "amara": ["LOC-03", "garden_amara", "base"], "mei": ["LOC-03", "garden_mei", "base"], "rafi": ["LOC-03", "garden_rafi", "base"], "ferreira": ["EARTH_SCREEN", "ferreira_earth_screen", "remote"]},
}

static func scene_roster(scene_id: String) -> Dictionary:
	var source: Dictionary = _SCENE_LAYOUTS.get(scene_id, _SCENE_LAYOUTS["EX-CH01-S01"])
	var result := {}
	for actor_id in source.keys():
		var row: Array = source[actor_id]
		result[actor_id] = {
			"actor_id": actor_id,
			"physical_location_id": String(row[0]),
			"anchor_id": String(row[1]),
			"team_id": String(row[2]),
			"present": true,
			"scene_id": scene_id,
		}
	return result

static func chapter_roster(chapter_id: String, scene_id: String = "") -> Dictionary:
	if chapter_id == "CH01":
		return scene_roster(scene_id if not scene_id.is_empty() else "EX-CH01-S01")
	if chapter_id == "CH04":
		return {
			"kai": _placement("kai", "LOC-09", "rover_kai", "field"),
			"rafi": _placement("rafi", "LOC-09", "rover_rafi", "field"),
			"mei": _placement("mei", "LOC-01", "commons_mei", "base"),
			"amara": _placement("amara", "LOC-01", "commons_amara", "base"),
			"ferreira": _placement("ferreira", "EARTH_SCREEN", "ferreira_earth_screen", "remote"),
		}
	if chapter_id == "CH08":
		return {
			"ferreira": _placement("ferreira", "LOC-11", "rover_ferreira", "rover"),
			"kai": _placement("kai", "LOC-11", "rover_kai", "rover"),
			"rafi": _placement("rafi", "LOC-11", "rover_rafi", "rover"),
			"mei": _placement("mei", "LOC-01", "commons_mei", "home"),
			"amara": _placement("amara", "LOC-01", "commons_amara", "home"),
		}
	return {}

static func can_switch(roster: Dictionary, current_actor: String, target_actor: String) -> Dictionary:
	var current: Dictionary = roster.get(current_actor, {}) if roster.get(current_actor, {}) is Dictionary else {}
	var target: Dictionary = roster.get(target_actor, {}) if roster.get(target_actor, {}) is Dictionary else {}
	if current.is_empty() or target.is_empty():
		return {"accepted": false, "reason": "Both cadets must be physically present before switching viewpoint."}
	if not bool(current.get("present", false)) or not bool(target.get("present", false)):
		return {"accepted": false, "reason": "A remote or absent actor cannot be selected as a free-movement viewpoint."}
	if String(current.get("physical_location_id", "")) != String(target.get("physical_location_id", "")):
		return {"accepted": false, "reason": "Free role switching is limited to co-located actors; use the authored viewpoint card for split teams."}
	return {"accepted": true, "reason": "Actors share a physical location.", "location_id": String(current.get("physical_location_id", ""))}

static func validate_roster(roster: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	for actor_id in ACTOR_IDS:
		if not roster.has(actor_id):
			errors.append("roster is missing " + actor_id)
			continue
		var row: Dictionary = roster[actor_id]
		for key in ["actor_id", "physical_location_id", "anchor_id", "team_id", "present"]:
			if not row.has(key):
				errors.append(actor_id + " placement is missing " + key)
		if actor_id == "ferreira" and String(row.get("physical_location_id", "")) not in ["EARTH_SCREEN", "LOC-01", "LOC-11"]:
			errors.append("Ferreira has an invalid physical location")
	return {"valid": errors.is_empty(), "errors": errors}

static func actor_locations(roster: Dictionary) -> Dictionary:
	var result := {}
	for actor_id in roster.keys():
		var row: Dictionary = roster[actor_id]
		result[actor_id] = {"physical_location_id": row.get("physical_location_id", ""), "anchor_id": row.get("anchor_id", ""), "team_id": row.get("team_id", "")}
	return result

static func _placement(actor_id: String, location_id: String, anchor_id: String, team_id: String) -> Dictionary:
	return {"actor_id": actor_id, "physical_location_id": location_id, "anchor_id": anchor_id, "team_id": team_id, "present": true}
