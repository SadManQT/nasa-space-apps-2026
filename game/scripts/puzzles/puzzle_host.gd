extends RefCounted
class_name PuzzleHost

## Reusable lifecycle adapter between mission/UI presentation and a
## CampaignDirector. It owns only reversible presentation state; arithmetic
## and receipts remain in the director/simulation.

const ScienceScript = preload("res://scripts/science/science_data.gd")
var science = ScienceScript.new()

const IDLE := "idle"
const ACTIVE := "active"
const PREVIEWED := "previewed"
const PAUSED := "paused"
const COMMITTED := "committed"
const FAILED := "failed"
const COMPLETED := "completed"
const CANCELLED := "cancelled"

var _director: RefCounted
var _puzzle_id := ""
var _mission_id := ""
var _scene_id := ""
var _state := IDLE
var _last_preview: Dictionary = {}
var _last_result: Dictionary = {}
var _preview_expected_revision := -1
var _paused_from := ACTIVE
var _revealed_hints: Array = []

func bind(director: RefCounted, puzzle_id: String, mission_id: String, scene_id: String) -> Dictionary:
	_director = director
	_puzzle_id = puzzle_id
	_mission_id = mission_id
	_scene_id = scene_id
	_state = ACTIVE
	_last_preview = {}
	_last_result = {}
	_preview_expected_revision = -1
	return snapshot()

func begin(director: RefCounted, puzzle_id: String, mission_id: String, scene_id: String) -> Dictionary:
	return bind(director, puzzle_id, mission_id, scene_id)

func snapshot() -> Dictionary:
	return {
		"source_cards": data_cards(),
		"puzzle_id": _puzzle_id,
		"mission_id": _mission_id,
		"scene_id": _scene_id,
		"lifecycle": _state,
		"paused": _state == PAUSED,
		"revealed_hints": _revealed_hints.duplicate(true),
		"last_preview": _last_preview.duplicate(true),
		"last_result": _last_result.duplicate(true),
	}

## Previews an arbitrary frozen command through the bound CampaignDirector while
## tracking PuzzleHost lifecycle and expected state revision.
func preview_command(command: Dictionary, validation: Dictionary = {}) -> Dictionary:
	if _director == null:
		return _host_reject("PuzzleHost is not bound to a CampaignDirector.")
	if _state in [IDLE, CANCELLED, COMPLETED] or _state == PAUSED:
		return _host_reject("Puzzle preview is unavailable in lifecycle state " + _state + ".")
	if not validation.is_empty() and not bool(validation.get("accepted", false)):
		_last_preview = validation.duplicate(true)
		_preview_expected_revision = -1
		_state = FAILED
		return _last_preview.duplicate(true)
	var result: Dictionary = _director.preview(command)
	if not validation.is_empty() and bool(result.get("accepted", false)):
		for key in ["observe", "explain", "hint", "predict", "test", "cassette", "moisture"]:
			if validation.has(key):
				result[key] = validation[key]
	_last_preview = result.duplicate(true)
	_preview_expected_revision = int(command.get("expected_state_revision", -1)) if bool(result.get("accepted", false)) else -1
	_state = PREVIEWED if bool(result.get("accepted", false)) else FAILED
	return result

## Commits an arbitrary frozen command after an accepted preview on the bound
## CampaignDirector.
func commit_command(command_id: String, command: Dictionary, complete_puzzle: bool = false) -> Dictionary:
	if _director == null:
		return _host_reject("PuzzleHost is not bound to a CampaignDirector.")
	if _state in [IDLE, CANCELLED, COMPLETED, PAUSED]:
		return _host_reject("Puzzle commit is unavailable in lifecycle state " + _state + ".")
	if _preview_expected_revision < 0:
		return _host_reject("Puzzle commit requires an accepted preview of the current plan.")
	var prepared := command.duplicate(true)
	prepared["command_id"] = command_id
	prepared["expected_state_revision"] = _preview_expected_revision
	var result: Dictionary = _director.commit(prepared)
	_last_result = result.duplicate(true)
	if bool(result.get("accepted", false)):
		_state = COMPLETED if (complete_puzzle or String(result.get("next_phase", "")) in ["sunrise", "complete", "completed"]) else COMMITTED
	else:
		_state = FAILED
	return result

## Records a non-punishing validation failure on the host without mutating
## authoritative CampaignDirector state.
func record_failure(failure: Dictionary) -> Dictionary:
	_last_preview = failure.duplicate(true)
	_preview_expected_revision = -1
	_state = FAILED
	return _last_preview.duplicate(true)

## Records a revealed progressive hint (H1, H2, H3) on the host. Hints never
## penalise endings or mastery.
func record_hint(hint: Dictionary) -> Dictionary:
	var id := String(hint.get("id", ""))
	if not id.is_empty() and not _revealed_hints.any(func(item): return String(item.get("id", "")) == id):
		_revealed_hints.append(hint.duplicate(true))
	return {"accepted": true, "hint": hint.duplicate(true), "revealed_hints": _revealed_hints.duplicate(true)}

func revealed_hints() -> Array:
	return _revealed_hints.duplicate(true)

func preview(plan: Dictionary) -> Dictionary:
	if _director == null:
		return _host_reject("PuzzleHost is not bound to a CampaignDirector.")
	if _state in [IDLE, CANCELLED, COMPLETED] or _state == PAUSED:
		return _host_reject("Puzzle preview is unavailable in lifecycle state " + _state + ".")
	var command := _command("preview:%s" % _puzzle_id, int(_director.query().get("state_revision", 0)), plan)
	var result: Dictionary = _director.preview(command)
	_last_preview = result.duplicate(true)
	_preview_expected_revision = int(command.get("expected_state_revision", -1)) if bool(result.get("accepted", false)) else -1
	_state = PREVIEWED if bool(result.get("accepted", false)) else FAILED
	return result

func commit(command_id: String, plan: Dictionary) -> Dictionary:
	if _director == null:
		return _host_reject("PuzzleHost is not bound to a CampaignDirector.")
	if _state in [IDLE, CANCELLED, COMPLETED, PAUSED]:
		return _host_reject("Puzzle commit is unavailable in lifecycle state " + _state + ".")
	if _preview_expected_revision < 0:
		return _host_reject("Puzzle commit requires an accepted preview of the current plan.")
	# Keep the revision captured by preview. Passing the director's current
	# revision here would let a changed world silently commit an old preview.
	# The director also checks receipts first, so replaying the same command_id
	# still returns its original receipt after the first commit.
	var command := _command(command_id, _preview_expected_revision, plan)
	var result: Dictionary = _director.commit(command)
	_last_result = result.duplicate(true)
	if bool(result.get("accepted", false)):
		_state = COMPLETED if String(result.get("next_phase", "")) in ["sunrise", "complete", "completed"] else COMMITTED
	else:
		_state = FAILED
	return result

func pause(reason: String = "user") -> Dictionary:
	if _director == null:
		return _host_reject("PuzzleHost is not bound to a CampaignDirector.")
	if _state in [IDLE, CANCELLED, COMPLETED, PAUSED]:
		return _host_reject("Puzzle is not active.")
	_paused_from = _state
	_state = PAUSED
	return _director.pause(reason)

func resume() -> Dictionary:
	if _director == null or _state != PAUSED:
		return _host_reject("Puzzle is not paused.")
	var result: Dictionary = _director.resume()
	_state = _paused_from
	return result

func cancel() -> Dictionary:
	if _state == COMPLETED:
		return _host_reject("A completed puzzle cannot be cancelled retroactively.")
	_state = CANCELLED
	return {"accepted": true, "duplicate": false, "reason": "Puzzle presentation cancelled; no campaign command was committed.", "lifecycle": _state}

func retry() -> Dictionary:
	if _director == null:
		return _host_reject("PuzzleHost is not bound to a CampaignDirector.")
	var result: Dictionary = _director.restore_checkpoint()
	if bool(result.get("accepted", false)):
		_state = ACTIVE
		_last_preview = {}
		_preview_expected_revision = -1
		_last_result = result.duplicate(true)
	return result

func complete(result: Dictionary = {}) -> Dictionary:
	_state = COMPLETED
	_last_result = result.duplicate(true)
	return snapshot()

func _command(command_id: String, revision: int, plan: Dictionary) -> Dictionary:
	return {
		"command_id": command_id,
		"issuer": "puzzle_host",
		"owning_mission_id": _mission_id,
		"owning_scene_id": _scene_id,
		"expected_state_revision": revision,
		"target_id": _puzzle_id,
		"verb": "commit_shift",
		"payload": {"plan": plan.duplicate(true)},
	}

func _host_reject(reason: String) -> Dictionary:
	return {"accepted": false, "duplicate": false, "reason": reason, "lifecycle": _state}

func data_cards() -> Array:
	return science.cards_for_puzzle(_puzzle_id)
