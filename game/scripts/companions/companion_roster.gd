extends RefCounted
class_name CompanionRoster

## Physical presence is explicit and separate from dialogue/radio presence.
## The service returns primitive placement dictionaries; it never instantiates
## a character or changes campaign arithmetic.

const RoomContract = preload("res://scripts/world/room_contract.gd")
const ACTOR_IDS := ["kai", "amara", "mei", "rafi", "ferreira"]
const CADET_IDS := ["kai", "amara", "mei", "rafi"]

# Per-scene placements and the playable body are authored separately from
# prose and radio viewpoints. The data follows the handbook's locked teams.
const SCENE_ROSTERS = preload("res://resources/campaign/content/scene_rosters.json")

static func scene_roster(scene_id: String) -> Dictionary:
	var scene: Dictionary = SCENE_ROSTERS.data.scenes.get(scene_id, {})
	var result := {}
	for actor_id in scene.get("actors", {}):
		var row: Dictionary = scene.actors[actor_id]
		var location := String(row.location_id)
		var anchor: String = "ferreira_earth_screen" if location == "EARTH_SCREEN" else _room_prefix(location) + "_" + actor_id
		result[actor_id] = _scene_placement(actor_id, location, anchor, String(row.team_id), scene_id)
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
		if not roster[actor_id] is Dictionary:
			errors.append(actor_id + " placement must be a Dictionary")
			continue
		var row: Dictionary = roster[actor_id]
		for key in ["actor_id", "physical_location_id", "anchor_id", "team_id", "present"]:
			if not row.has(key):
				errors.append(actor_id + " placement is missing " + key)
			elif (key == "present" and not row[key] is bool) or (key != "present" and not row[key] is String):
				errors.append(actor_id + " placement has an invalid " + key)
		if not row.get("physical_location_id", null) is String:
			continue
		var location := String(row.physical_location_id)
		if RoomContract.room(location).is_empty() and not (actor_id == "ferreira" and location == "EARTH_SCREEN"):
			errors.append(actor_id + " has an invalid physical location")
	return {"valid": errors.is_empty(), "errors": errors}

## Structured physical viewpoint; prose/radio speaker names never choose a body.
static func playable_actor(scene_id: String) -> String:
	return String(SCENE_ROSTERS.data.scenes.get(scene_id, {}).get("playable_actor_id", ""))

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
