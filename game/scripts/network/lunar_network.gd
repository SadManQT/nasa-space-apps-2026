extends RefCounted
class_name LunarNetwork

## M3-62: Things you build stay (the lunar network, doc 25 §4.4, doc 24 N1).
## Placeable survey markers, fixed lines, path lights and relay repeaters made
## from carried payloads; saved inside `presentation_resume.lunar_network` and
## shown on later trips, the coverage map and the route planner.
## Chapter 4 survey beacons (B1, B2, B3) return as a persistent layer on the
## Chapter 8 route map. New links on the coverage map can unlock messages (the
## Earth desk, the archive), and the Chapter 8 finale voice (P-16) travels over
## the verified dual-link network (Aurora-R1-R2-R3-Summit + Summit-Earth).

const PayloadInventoryScript = preload("res://scripts/payload/payload_inventory.gd")

const STRUCTURE_TYPES := {
	"marker": {
		"kind": "marker",
		"label": "Survey marker",
		"payload_size": "small",
		"payload_mass_kg": 2.0,
		"base_cap": 6,
		"nav_bonus_per_rank": 1,
		"description": "Marks a safe waypoint and bearing on the ridge and cold-trap road.",
	},
	"fixed_line": {
		"kind": "fixed_line",
		"label": "Fixed line",
		"payload_size": "medium",
		"payload_mass_kg": 4.5,
		"base_cap": 4,
		"nav_bonus_per_rank": 0,
		"description": "Anchors a safety line along a careful or steep slope stretch.",
	},
	"path_light": {
		"kind": "path_light",
		"label": "Path light",
		"payload_size": "small",
		"payload_mass_kg": 2.5,
		"base_cap": 6,
		"nav_bonus_per_rank": 0,
		"description": "Lights a shadow boundary or ridge trail for low-Sun sorties.",
	},
	"repeater": {
		"kind": "repeater",
		"label": "Relay repeater",
		"payload_size": "medium",
		"payload_mass_kg": 6.0,
		"base_cap": 4,
		"nav_bonus_per_rank": 0,
		"description": "Extends the radio line-of-sight hop chain between Aurora and Malapert.",
	},
}

## Canonical Chapter 4 survey beacons (B1, B2, B3) that return on the Chapter 8
## route map (doc 24 N1, doc 25 §4.4).
const CH04_CANON_BEACONS := [
	{
		"id": "CH04-BEACON-1",
		"kind": "marker",
		"label": "Beacon 1 · Ridge saddle",
		"chapter": 4,
		"site_id": "site_beacon_1",
		"position_m": [320.0, 140.0],
		"slope_deg": 9.0,
		"canon_beacon": true,
	},
	{
		"id": "CH04-BEACON-2",
		"kind": "marker",
		"label": "Beacon 2 · Shadow rim",
		"chapter": 4,
		"site_id": "site_beacon_2",
		"position_m": [680.0, 290.0],
		"slope_deg": 11.0,
		"canon_beacon": true,
	},
	{
		"id": "CH04-BEACON-3",
		"kind": "marker",
		"label": "Beacon 3 · Cold-trap shelf",
		"chapter": 4,
		"site_id": "site_beacon_3",
		"position_m": [1040.0, 460.0],
		"slope_deg": 12.0,
		"canon_beacon": true,
	},
]

## Canonical repeater hops for the 120 km Malapert relay road (P-15 / P-16).
const CANON_RELAY_HOPS := [
	{
		"hop_id": "Aurora-R1",
		"from_node": "Aurora Base",
		"to_node": "Repeater One (Ridge)",
		"from_pos": [120.0, 360.0],
		"to_pos": [310.0, 310.0],
		"unlock_message_id": "MSG-NET-R1",
		"unlock_sender": "Rao",
		"unlock_subject": "First ridge hop online",
	},
	{
		"hop_id": "R1-R2",
		"from_node": "Repeater One (Ridge)",
		"to_node": "Repeater Two (Marker Two)",
		"from_pos": [310.0, 310.0],
		"to_pos": [520.0, 250.0],
		"unlock_message_id": "MSG-NET-R2",
		"unlock_sender": "Archive",
		"unlock_subject": "Marker Two relay log recovered",
	},
	{
		"hop_id": "R2-R3",
		"from_node": "Repeater Two (Marker Two)",
		"to_node": "Repeater Three (Approach)",
		"from_pos": [520.0, 250.0],
		"to_pos": [740.0, 185.0],
		"unlock_message_id": "MSG-NET-R3",
		"unlock_sender": "Rafi",
		"unlock_subject": "Approach hop locked",
	},
	{
		"hop_id": "R3-summit",
		"from_node": "Repeater Three (Approach)",
		"to_node": "Malapert Summit",
		"from_pos": [740.0, 185.0],
		"to_pos": [940.0, 110.0],
		"unlock_message_id": "MSG-NET-SUMMIT",
		"unlock_sender": "Mei",
		"unlock_subject": "Local chain reaches the summit",
	},
]

var navigation_rank: int = 0
var _placed: Array = []
var _active_hops: Array = []
var _earth_leg_verified: bool = false
var _local_bearing: String = ""
var _earth_bearing: String = ""
var _echo_code: String = ""
var _unlocked_message_ids: Array = []

func _init(nav_rank: int = 0) -> void:
	navigation_rank = clampi(nav_rank, 0, 3)

func marker_capacity() -> int:
	return int(STRUCTURE_TYPES.marker.base_cap) + clampi(navigation_rank, 0, 3) * int(STRUCTURE_TYPES.marker.nav_bonus_per_rank)

func count_by_kind(kind: String) -> int:
	var n := 0
	for item in _placed:
		if String(item.get("kind", "")) == kind:
			n += 1
	return n

## Creates a standard payload definition for a buildable structure so the player
## carries it via PayloadInventory before placing it on the terrain.
static func make_payload_definition(id: String, kind: String, site_id: String, label_override: String = "") -> Dictionary:
	if not STRUCTURE_TYPES.has(kind):
		return {}
	var spec: Dictionary = STRUCTURE_TYPES[kind]
	var text_label := label_override if not label_override.is_empty() else "%s (%s)" % [spec.label, site_id]
	return {
		"id": id,
		"label": text_label,
		"size": String(spec.payload_size),
		"mass_kg": float(spec.payload_mass_kg),
		"handling": [],
		"destination": site_id,
		"network_kind": kind,
	}

## Places a marker, fixed line, path light or repeater from a carried payload
## (or directly when `inventory == null` in a restored/canon step).
func place_from_payload(id: String, kind: String, site_id: String, position_m: Array, chapter: int = 4, label: String = "", inventory: RefCounted = null, payload_id: String = "") -> Dictionary:
	if not STRUCTURE_TYPES.has(kind):
		return {"accepted": false, "reason": "Unknown network item type."}
	for existing in _placed:
		if String(existing.get("id", "")) == id:
			return {"accepted": false, "duplicate": true, "reason": "That structure is already placed."}
	if kind == "marker" and count_by_kind("marker") >= marker_capacity():
		return {"accepted": false, "reason": "Marker capacity reached (%d). Raise Navigation rank to carry more markers." % marker_capacity()}
	if inventory != null and not payload_id.is_empty():
		var delivered: Dictionary = inventory.deliver(payload_id, site_id)
		if not bool(delivered.get("accepted", false)):
			return delivered
	var spec: Dictionary = STRUCTURE_TYPES[kind]
	var pos := [
		float(position_m[0]) if position_m.size() > 0 else 0.0,
		float(position_m[1]) if position_m.size() > 1 else 0.0,
	]
	var record := {
		"id": id,
		"kind": kind,
		"label": label if not label.is_empty() else "%s · %s" % [spec.label, site_id],
		"site_id": site_id,
		"position_m": pos,
		"chapter": chapter,
		"canon_beacon": id.begins_with("CH04-BEACON-"),
	}
	_placed.append(record)
	return {"accepted": true, "item": record.duplicate(true), "reason": "%s placed at %s." % [record.label, site_id]}

## Records the three canonical Chapter 4 survey beacons (B1, B2, B3) so they
## appear on later trips and as a persistent layer on the Chapter 8 route map.
func record_ch04_beacons(up_to_count: int = 3) -> Array:
	var added: Array = []
	var count := clampi(up_to_count, 0, CH04_CANON_BEACONS.size())
	for idx in range(count):
		var beacon: Dictionary = CH04_CANON_BEACONS[idx]
		var res := place_from_payload(
			String(beacon.id),
			"marker",
			String(beacon.site_id),
			beacon.position_m,
			4,
			String(beacon.label)
		)
		if bool(res.get("accepted", false)):
			added.append(beacon.id)
	return added

## Returns the Chapter 4 beacon layer for the Chapter 8 route planner & map (doc 24 N1).
func ch04_beacon_layer() -> Array:
	var out: Array = []
	for item in _placed:
		if bool(item.get("canon_beacon", false)) or (int(item.get("chapter", 0)) == 4 and String(item.get("kind", "")) == "marker"):
			out.append(item.duplicate(true))
	return out

## Activates a repeater hop on the coverage map and unlocks its associated message.
func activate_hop(hop_id: String, director: RefCounted = null) -> Dictionary:
	var found_spec := {}
	for hop in CANON_RELAY_HOPS:
		if String(hop.hop_id) == hop_id:
			found_spec = hop
			break
	if found_spec.is_empty():
		return {"accepted": false, "reason": "Unknown relay hop: " + hop_id}
	if not _active_hops.has(hop_id):
		_active_hops.append(hop_id)
	var msg_id := String(found_spec.get("unlock_message_id", ""))
	var newly_unlocked := false
	if not msg_id.is_empty() and not _unlocked_message_ids.has(msg_id):
		_unlocked_message_ids.append(msg_id)
		newly_unlocked = true
		if director != null and director.has_method("update_message_metadata"):
			director.update_message_metadata({"delivered_ids": [msg_id]})
	return {
		"accepted": true,
		"hop_id": hop_id,
		"newly_unlocked_message_id": msg_id if newly_unlocked else "",
		"active_hops": _active_hops.duplicate(),
		"local_chain_complete": is_local_chain_complete(),
	}

## Activates all four local repeater hops (Aurora-R1, R1-R2, R2-R3, R3-summit).
func activate_full_local_chain(director: RefCounted = null) -> Dictionary:
	var unlocked: Array = []
	for hop in CANON_RELAY_HOPS:
		var res := activate_hop(String(hop.hop_id), director)
		var msg := String(res.get("newly_unlocked_message_id", ""))
		if not msg.is_empty():
			unlocked.append(msg)
	return {
		"accepted": true,
		"active_hops": _active_hops.duplicate(),
		"unlocked_message_ids": unlocked,
		"local_chain_complete": is_local_chain_complete(),
	}

func is_local_chain_complete() -> bool:
	for hop in CANON_RELAY_HOPS:
		if not _active_hops.has(String(hop.hop_id)):
			return false
	return true

## Verifies the Chapter 8 dual-link (local chain + Earth leg with L2, E3, ALO42)
## so the finale's live voice arrives over the player-built network (P-16).
func verify_finale_voice_network(local_bearing: String, earth_bearing: String, echo_code: String) -> Dictionary:
	_local_bearing = local_bearing.strip_edges().to_upper()
	_earth_bearing = earth_bearing.strip_edges().to_upper()
	_echo_code = echo_code.strip_edges().to_upper()
	if not is_local_chain_complete():
		return {"accepted": false, "reason": "Complete all four local repeater hops from Aurora to the summit first."}
	if _local_bearing != "L2":
		return {"accepted": false, "reason": "Local repeater dish needs bearing L2."}
	if _earth_bearing != "E3":
		return {"accepted": false, "reason": "Earth dish needs bearing E3."}
	if _echo_code != "ALO42":
		return {"accepted": false, "reason": "Enter the known-content echo code ALO42 before opening live voice."}
	_earth_leg_verified = true
	return {
		"accepted": true,
		"voice_ready": true,
		"voice_path": ["Aurora Base", "Repeater R1", "Repeater R2", "Repeater R3", "Malapert Summit", "Earth Desk"],
		"reason": "Local 4-hop chain and Earth leg verified. Live voice from Noor is travelling over your network.",
	}

func is_voice_ready() -> bool:
	return is_local_chain_complete() and _earth_leg_verified and _local_bearing == "L2" and _earth_bearing == "E3" and _echo_code == "ALO42"

## Synchronizes from a campaign snapshot's `route` and `campaign_ledgers` if present,
## and reads/writes `presentation_resume.lunar_network` for save persistence.
func sync_from_campaign_snapshot(snapshot: Dictionary) -> void:
	var resume: Dictionary = snapshot.get("presentation_resume", {}) if snapshot.get("presentation_resume", {}) is Dictionary else {}
	if resume.get("lunar_network", null) is Dictionary:
		from_dict(resume["lunar_network"])
	var book: Dictionary = snapshot.get("campaign_ledgers", {}) if snapshot.get("campaign_ledgers", {}) is Dictionary else {}
	var ops: Dictionary = book.get("operations", {}) if book.get("operations", {}) is Dictionary else {}
	for idx in range(1, 4):
		if ops.has("p07_place_beacon_%d" % idx):
			var b: Dictionary = CH04_CANON_BEACONS[idx - 1]
			place_from_payload(String(b.id), "marker", String(b.site_id), b.position_m, 4, String(b.label))
	var route_data: Dictionary = snapshot.get("route", {}) if snapshot.get("route", {}) is Dictionary else {}
	for hop_id in route_data.get("local_hops", []):
		activate_hop(String(hop_id))
	if String(route_data.get("earth_leg", "")) == "verified":
		verify_finale_voice_network("L2", "E3", "ALO42")

func write_to_campaign_snapshot(snapshot: Dictionary) -> Dictionary:
	var out := snapshot.duplicate(true)
	if not out.get("presentation_resume", null) is Dictionary:
		out["presentation_resume"] = {}
	out["presentation_resume"]["lunar_network"] = to_dict()
	return out

func all_placed() -> Array:
	return _placed.duplicate(true)

func active_hops() -> Array:
	return _active_hops.duplicate()

func unlocked_message_ids() -> Array:
	return _unlocked_message_ids.duplicate()

func to_dict() -> Dictionary:
	return {
		"navigation_rank": navigation_rank,
		"placed": _placed.duplicate(true),
		"active_hops": _active_hops.duplicate(),
		"earth_leg_verified": _earth_leg_verified,
		"local_bearing": _local_bearing,
		"earth_bearing": _earth_bearing,
		"echo_code": _echo_code,
		"unlocked_message_ids": _unlocked_message_ids.duplicate(),
	}

func from_dict(data: Dictionary) -> void:
	if not data is Dictionary:
		return
	navigation_rank = clampi(int(data.get("navigation_rank", navigation_rank)), 0, 3)
	_placed = []
	for item in data.get("placed", []):
		if item is Dictionary:
			_placed.append(item.duplicate(true))
	_active_hops = []
	for h in data.get("active_hops", []):
		var hop_str := String(h)
		if not _active_hops.has(hop_str):
			_active_hops.append(hop_str)
	_earth_leg_verified = bool(data.get("earth_leg_verified", false))
	_local_bearing = String(data.get("local_bearing", ""))
	_earth_bearing = String(data.get("earth_bearing", ""))
	_echo_code = String(data.get("echo_code", ""))
	_unlocked_message_ids = []
	for m in data.get("unlocked_message_ids", []):
		var m_str := String(m)
		if not _unlocked_message_ids.has(m_str):
			_unlocked_message_ids.append(m_str)
