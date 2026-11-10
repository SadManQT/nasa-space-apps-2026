extends RefCounted
class_name PuzzleData

## Data-file source of truth for the interactive Chapter 5 and Chapter 7
## puzzles (M3-5P / M3-7P). The answers used to live as pre-filled payloads
## in ExtendedGateCatalog._defaults(); they now live only in the JSON files
## under game/resources/campaign/content/, and the player must choose every
## value in a panel. Route-walking tests act as a player who made the
## decisions recorded here: they call gate_payload(action) instead of reading
## a pre-filled catalog payload.
##
## Every gate payload in a data file must agree with the matching puzzle
## model (game/scripts/puzzles/) and with ExtendedPuzzleLedger; the
## test_p09_p10_panels / test_p13_p14_panels suites assert all three agree.

const PATHS := {
	"P-09": "res://resources/campaign/content/p09_departure_reconstruction.json",
	"P-10": "res://resources/campaign/content/p10_flashes_signature.json",
	"P-13": "res://resources/campaign/content/p13_storm_plan.json",
	"P-14": "res://resources/campaign/content/p14_storm_execution.json",
}

const ACTION_PUZZLE := {
	"p09_commit_sequence": "P-09",
	"p10_verify_flashes": "P-10",
	"p13_commit_plan": "P-13",
	"p14_route_reading_1": "P-14",
	"p14_route_reading_2": "P-14",
}

static var _cache := {}

## Parsed data for one puzzle id ("P-09", "P-10", "P-13", "P-14").
## Returns {} (and reports why) when the file is missing or malformed.
static func data(puzzle_id: String) -> Dictionary:
	if _cache.has(puzzle_id):
		return (_cache[puzzle_id] as Dictionary).duplicate(true)
	var path: String = PATHS.get(puzzle_id, "")
	if path.is_empty():
		push_error("PuzzleData has no data file for " + puzzle_id)
		return {}
	if not FileAccess.file_exists(path):
		push_error("PuzzleData file is missing: " + path)
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("PuzzleData file does not parse: " + path)
		return {}
	if int(parsed.get("schema_version", 0)) != 1 or String(parsed.get("puzzle_id", "")) != puzzle_id:
		push_error("PuzzleData file has the wrong schema or puzzle id: " + path)
		return {}
	_cache[puzzle_id] = (parsed as Dictionary).duplicate(true)
	return (parsed as Dictionary).duplicate(true)

## The payload a player commits when they make the decisions recorded in the
## data file for one gate action. Empty when the action has no gate payload
## (most acknowledgement actions need no payload at all).
static func gate_payload(action: String) -> Dictionary:
	var puzzle_id: String = ACTION_PUZZLE.get(action, "")
	if puzzle_id.is_empty():
		return {}
	var payloads: Dictionary = data(puzzle_id).get("gate_payloads", {})
	var payload = payloads.get(action, {})
	return (payload as Dictionary).duplicate(true) if payload is Dictionary else {}
