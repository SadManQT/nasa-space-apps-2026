extends RefCounted
class_name CampaignCommandResult

## Small, dependency-free helpers for the frozen command/result contract.
## Results are Dictionaries on purpose: they can be saved, inspected by UI,
## and handed across scene boundaries without carrying Nodes or Callables.

const RESULT_KEYS := [
	"accepted",
	"duplicate",
	"input_revision",
	"output_revision",
	"receipt_id",
	"deltas",
	"events",
	"warnings",
	"unsafe_predicates",
	"reason",
	"next_phase",
]

static func empty(input_revision: int = 0, next_phase: String = "") -> Dictionary:
	return {
		"accepted": false,
		"duplicate": false,
		"input_revision": input_revision,
		"output_revision": input_revision,
		"receipt_id": "",
		"deltas": [],
		"events": [],
		"warnings": [],
		"unsafe_predicates": [],
		"reason": "",
		"next_phase": next_phase,
	}

static func copy(result: Dictionary) -> Dictionary:
	return result.duplicate(true)

static func has_contract(result: Dictionary) -> bool:
	for key in RESULT_KEYS:
		if not result.has(key):
			return false
	return true

static func event(event_type: String, revision: int, state: Dictionary = {}) -> Dictionary:
	var value := {
		"type": event_type,
		"state_revision": revision,
	}
	for key in ["chapter_id", "mission_id", "scene_id"]:
		if state.has(key):
			value[key] = state[key]
	return value
