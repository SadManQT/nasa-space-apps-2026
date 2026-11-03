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
	if scene_id.begins_with("EX-CH02-"):
		var order := int(scene_id.substr(9, 2))
		var location: String = ["LOC-03", "LOC-03", "LOC-05", "LOC-05", "LOC-05", "LOC-03", "LOC-01", "LOC-02", "LOC-02", "LOC-02", "LOC-01", "LOC-01"][order - 1]
		var prefix := "commons"
		match location:
			"LOC-03": prefix = "garden"
			"LOC-05": prefix = "transfer"
			"LOC-02": prefix = "service"
		return {
			"kai": {"actor_id": "kai", "physical_location_id": location, "anchor_id": prefix + "_kai", "team_id": "base", "present": true, "scene_id": scene_id},
			"amara": {"actor_id": "amara", "physical_location_id": location, "anchor_id": prefix + "_amara", "team_id": "base", "present": true, "scene_id": scene_id},
			"mei": {"actor_id": "mei", "physical_location_id": location, "anchor_id": prefix + "_mei", "team_id": "base", "present": true, "scene_id": scene_id},
			"rafi": {"actor_id": "rafi", "physical_location_id": location, "anchor_id": prefix + "_rafi", "team_id": "base", "present": true, "scene_id": scene_id},
			"ferreira": {"actor_id": "ferreira", "physical_location_id": "EARTH_SCREEN", "anchor_id": "ferreira_earth_screen", "team_id": "remote", "present": true, "scene_id": scene_id},
		}
	if scene_id.begins_with("EX-CH") and int(scene_id.substr(5, 2)) >= 3:
		var parts := scene_id.split("-")
		var chapter := int(String(parts[1]).trim_prefix("CH"))
		var order := int(String(parts[2]).trim_prefix("S"))
		var location: String = {
			3: ["LOC-02", "LOC-02", "LOC-02", "LOC-02", "LOC-02", "LOC-07", "LOC-07", "LOC-07", "LOC-03", "LOC-03", "LOC-03", "LOC-01"],
			4: ["LOC-08", "LOC-08", "LOC-08", "LOC-09", "LOC-09", "LOC-10", "LOC-10", "LOC-10", "LOC-08", "LOC-03", "LOC-01", "LOC-01"],
			5: ["LOC-08", "LOC-01", "LOC-01", "LOC-01", "LOC-01", "LOC-01", "LOC-01", "LOC-02", "LOC-01", "LOC-01", "LOC-01", "LOC-03"],
			6: ["LOC-02", "LOC-02", "LOC-02", "LOC-02", "LOC-02", "LOC-01", "LOC-02", "LOC-01", "LOC-01", "LOC-02", "LOC-01", "LOC-03"],
			7: ["LOC-01", "LOC-04", "LOC-04", "LOC-04", "LOC-04", "LOC-04", "LOC-04", "LOC-04", "LOC-01", "LOC-01", "LOC-02", "LOC-01"],
			8: ["LOC-08", "LOC-08", "LOC-11", "LOC-11", "LOC-03", "LOC-08", "LOC-12", "LOC-12", "LOC-12", "LOC-11", "LOC-08", "LOC-03"],
		}.get(chapter, ["LOC-01"])[order - 1]
		var prefix := _room_prefix(location)
		var team := "base"
		var ferreira_location := "EARTH_SCREEN"
		var ferreira_anchor := "ferreira_earth_screen"
		if chapter == 8:
			ferreira_location = "LOC-11"
			ferreira_anchor = "relay_ferreira"
			team = "rover"
		return {
			"kai": _scene_placement("kai", location, prefix + "_kai", team, scene_id),
			"amara": _scene_placement("amara", location, prefix + "_amara", team, scene_id),
			"mei": _scene_placement("mei", location, prefix + "_mei", team, scene_id),
			"rafi": _scene_placement("rafi", location, prefix + "_rafi", team, scene_id),
			"ferreira": _scene_placement("ferreira", ferreira_location, ferreira_anchor, "remote" if chapter < 8 else "rover", scene_id),
		}
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

static func _scene_placement(actor_id: String, location_id: String, anchor_id: String, team_id: String, scene_id: String) -> Dictionary:
	return {"actor_id": actor_id, "physical_location_id": location_id, "anchor_id": anchor_id, "team_id": team_id, "present": true, "scene_id": scene_id}

static func _room_prefix(room_id: String) -> String:
	return {
		"LOC-01": "commons", "LOC-02": "service", "LOC-03": "garden", "LOC-04": "safe",
		"LOC-05": "transfer", "LOC-06": "exterior", "LOC-07": "annex", "LOC-08": "rover",
		"LOC-09": "ridge", "LOC-10": "vault", "LOC-11": "relay", "LOC-12": "relay_service",
	}.get(room_id, "commons")
