extends RefCounted
class_name CrewModes

## Crew modes for one shared machine.
##
## Solo: one player holds all four roles and every crew note is public to that
## player. Class: two to four players share the machine; each role's note is
## private (read one player at a time, or printed), the crew discusses, and
## every role signs the team plan before the operator locks it in. No network
## play exists or is implied. Every player-facing word, the seat plans and the
## role accents come from res://resources/campaign/content/crew_modes.json;
## the role facts themselves stay in p02_mission_table.json.

const DATA_PATH := "res://resources/campaign/content/crew_modes.json"
const SCHEMA_VERSION := 1
const SOLO := "solo"
const CLASS := "class"
const ROLE_ORDER := ["kai", "amara", "mei", "rafi"]

static var _cache: Dictionary = {}

## The parsed data file. Cached; {} when the file is missing or invalid.
static func data() -> Dictionary:
	if _cache.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH)) if FileAccess.file_exists(DATA_PATH) else null
		if parsed is Dictionary and int(parsed.get("schema_version", 0)) == SCHEMA_VERSION:
			_cache = parsed
		else:
			push_error("Crew modes data is missing or invalid: " + DATA_PATH)
	return _cache

## The crew every expedition starts with unless New Expedition chose another.
static func default_crew() -> Dictionary:
	return {"mode": String(data().get("default_mode", SOLO)), "players": 1}

## Why `crew` is not a valid crew setting, or "" when it is. A valid crew is
## {"mode": "solo"|"class", "players": int within the mode's bounds}.
static func problem(crew) -> String:
	if not crew is Dictionary:
		return "Crew settings must be a Dictionary."
	var mode = crew.get("mode", null)
	if not mode is String or not data().get("modes", {}).has(mode):
		return "Unknown crew mode: " + str(mode)
	var info: Dictionary = data().modes[mode]
	var players = crew.get("players", null)
	if not (players is int or players is float) or not is_finite(float(players)) or float(players) != floor(float(players)):
		return "Crew players must be a whole number."
	if int(players) < int(info.get("players_min", 1)) or int(players) > int(info.get("players_max", 1)):
		return "%s mode takes %d to %d players." % [String(info.get("label", mode)), int(info.get("players_min", 1)), int(info.get("players_max", 1))]
	if String(mode) == CLASS and not data().get("seat_plans", {}).has(str(int(players))):
		return "No seat plan exists for %d players." % int(players)
	return ""

## A complete, valid crew: unknown or invalid input falls back to the default,
## and a valid mode with a missing player count takes the mode's minimum.
static func normalise(crew) -> Dictionary:
	if not crew is Dictionary:
		return default_crew()
	var mode := String(crew.get("mode", data().get("default_mode", SOLO)))
	if not data().get("modes", {}).has(mode):
		return default_crew()
	var info: Dictionary = data().modes[mode]
	var players = crew.get("players", info.get("players_min", 1))
	var count := int(players) if (players is int or players is float) and is_finite(float(players)) else int(info.get("players_min", 1))
	count = clampi(count, int(info.get("players_min", 1)), int(info.get("players_max", 1)))
	var result := {"mode": mode, "players": count}
	return result if problem(result).is_empty() else default_crew()

static func is_class(crew) -> bool:
	return String(normalise(crew).get("mode", SOLO)) == CLASS

## Mode metadata (label, summary, player bounds, sign_off policy).
static func mode_info(mode: String) -> Dictionary:
	return data().get("modes", {}).get(mode, {}).duplicate(true)

## Seats for this crew: [{seat, label, role_ids}]. Solo has one seat holding
## every role; Class follows the data file's seat plan for the player count.
static func seats(crew) -> Array:
	var normal := normalise(crew)
	var result: Array = []
	if String(normal.mode) == SOLO:
		result.append({"seat": 1, "label": String(data().get("solo_holder", "You")), "role_ids": ROLE_ORDER.duplicate()})
		return result
	for raw in data().get("seat_plans", {}).get(str(int(normal.players)), []):
		var seat := int(raw.get("seat", result.size() + 1))
		var role_ids: Array = []
		for role_id in raw.get("role_ids", []):
			role_ids.append(String(role_id))
		result.append({"seat": seat, "label": seat_label(seat), "role_ids": role_ids})
	return result

## The seat that holds `role_id`, or {} when the crew has no such seat.
static func seat_for_role(crew, role_id: String) -> Dictionary:
	for seat in seats(crew):
		if seat.role_ids.has(role_id):
			return seat
	return {}

## Who holds a role on this crew: "Player 2" in Class, "You" in Solo.
static func holder_label(crew, role_id: String) -> String:
	var seat := seat_for_role(crew, role_id)
	return String(seat.get("label", data().get("solo_holder", "You")))

static func seat_label(seat: int) -> String:
	return String(data().get("seat_label", "Player {seat}")).replace("{seat}", str(seat))

## Name, duty and accent colour for one role.
static func role_info(role_id: String) -> Dictionary:
	var info: Dictionary = data().get("roles", {}).get(role_id, {}).duplicate(true)
	if not info.has("name"):
		info["name"] = role_id.capitalize()
	info["role_id"] = role_id
	return info

static func role_color(role_id: String) -> Color:
	var value := String(role_info(role_id).get("color", "#F2C230"))
	return Color.html(value) if Color.html_is_valid(value) else Color("#F2C230")

## "SOLO" or "CLASS · 4 PLAYERS", for chips and headers.
static func mode_label(crew) -> String:
	var normal := normalise(crew)
	var label := String(mode_info(String(normal.mode)).get("label", String(normal.mode).to_upper()))
	if String(normal.mode) == SOLO:
		return label
	return text("table", "mode_chip", {"mode": label, "players": str(int(normal.players))})

## One seat plan line, e.g. "Player 1: Kai and Mei · Player 2: Amara and Rafi".
static func seat_plan_text(crew) -> String:
	var parts: Array = []
	var joiner := String(data().get("menu", {}).get("seat_plan_joiner", " and "))
	for seat in seats(crew):
		var names: Array = []
		for role_id in seat.role_ids:
			names.append(String(role_info(String(role_id)).get("name", role_id)))
		parts.append("%s: %s" % [String(seat.label), joiner.join(names)])
	return " · ".join(parts)

## Player-facing copy from one section of the data file with {token}
## substitutions; {TOKEN} in upper case gives the upper-cased value.
static func text(section: String, key: String, substitutions: Dictionary = {}) -> String:
	var value := String(data().get(section, {}).get(key, ""))
	for token in substitutions:
		var replacement := str(substitutions[token])
		value = value.replace("{%s}" % String(token), replacement)
		value = value.replace("{%s}" % String(token).to_upper(), replacement.to_upper())
	return value

## Substitutions every copy line about one role may use.
static func role_tokens(crew, role_id: String, extra: Dictionary = {}) -> Dictionary:
	var info := role_info(role_id)
	var tokens := {"name": String(info.get("name", role_id)), "duty": String(info.get("duty", "")), "holder": holder_label(crew, role_id)}
	for key in extra:
		tokens[key] = extra[key]
	return tokens
