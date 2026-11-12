extends RefCounted
class_name ProbeCalibrationJob

## M1-108 opening physical job: one retrieve-and-place transfer that makes
## the EX-CH01-S03 dry-zero calibration physically understandable in 3D.
##
## Staging (decided by Sadman from canon; see the M1-108 brief):
## - Source: the probe storage rack at the bench in LOC-01 (EX-CH01-S03).
## - Item: the existing moisture probe (prop `PR_VaultProbe`). No invented
##   "Zero" object: zero is the calibration baseline, not a payload.
## - Destination: the bench dry-reference cradle, where the probe reads the
##   dry reference.
## - Observable result: the probe's display changes from its raw dry reading
##   to a calibrated 0. That reading is the P-01 `set_zero` payload, so the
##   transfer gates the existing `calibrate_probe` completion exactly once.
##
## Canon numbers (08 P-01; `p01_commission_plant.json` references.dry):
## the uncalibrated probe reads raw 10 on the dry reference; after zeroing
## it reads calibrated 0. The probe mass below is handling tuning only, in
## the same sense as `payload_rules.json` ("training tuning, not engineering
## specifications").
##
## Ownership reuses M1-58 `PayloadInventory`: the probe is a registered
## payload whose `place` is the single source of truth (`ground` = on the
## rack, `hands` = carried, `delivered` = placed at the bench cradle).
## No timing or dexterity gate: retrieve, place and observe are deliberate
## steps, never a countdown. The 3D presentation (HeldProp RIGHT grip with
## the existing probe prop) is offered through `hold_pose()` and
## `prop_scene_path()`; the activity/panel launch that calls these steps
## lives in Ramim-owned UI and is a follow-up, not part of this job.

const Inventory = preload("res://scripts/payload/payload_inventory.gd")

const PROBE_ID := "probe"
const PROBE_LABEL := "Moisture probe"
const PROBE_MASS_KG := 0.4
const SOURCE := "rack"
const DESTINATION := "bench"
const SCENE_ID := "EX-CH01-S03"
const ROOM_ID := "LOC-01"
const PROP_SCENE_PATH := "res://assets/props/PR_VaultProbe/PR_VaultProbe.glb"

## Canon dry reference (P-01 profile references.dry; 08: probe offset +10).
const RAW_DRY := 10
const CALIBRATED_DRY := 0

## Teaching text, single-sourced in words from ui_text.json
## `targets.calibrate_probe` (tests assert the match).
const BRIEF_GOAL := "Test the water meter in dry soil"
const BRIEF_WHY := "A meter must be tested before you trust it"
const BRIEF_PROMPT := "Test in dry soil"
const BRIEF_RESULT := "Dry test done."
const BRIEF_HINT := "Dry soil first. Wet soil comes next."

const STATES := ["at_rack", "held", "at_bench", "zeroed"]

var inventory: PayloadInventory
var _state := "at_rack"

func _init() -> void:
	inventory = Inventory.new()
	inventory.register_payload({
		"id": PROBE_ID,
		"label": PROBE_LABEL,
		"mass_kg": PROBE_MASS_KG,
		"size": "small",
		"handling": [],
		"destination": DESTINATION,
	})

## Current transfer state: at_rack, held, at_bench, or zeroed (complete).
func state() -> String:
	return _state

## True only after the dry zero has been observed at the bench, once.
func completed() -> bool:
	return _state == "zeroed"

## Where the inventory says the probe is: ground (rack), hands, delivered (bench).
func probe_place() -> String:
	return String(inventory.item(PROBE_ID).get("place", ""))

## True while the probe is carried; the 3D HeldProp is shown exactly then.
func held() -> bool:
	return _state == "held"

## The probe's displayed dry reading. Before zeroing it shows the raw
## offset; after zeroing it shows the calibrated baseline.
func reading() -> Dictionary:
	return {
		"reference": "dry",
		"raw_reading": RAW_DRY,
		"calibrated_reading": CALIBRATED_DRY if completed() else null,
	}

## The exact P-01 `set_zero` payload the observed reading produces, or {}
## until the transfer is complete. Nothing else can mint this payload.
func set_zero_payload() -> Dictionary:
	if not completed():
		return {}
	return {"reference": "dry", "raw_reading": RAW_DRY, "calibrated_reading": CALIBRATED_DRY}

## Single-hand power grip, as HeldProp renders it; the probe is a hand tool,
## not a two-handed case (BOX is the supply-bundle pose).
static func hold_pose() -> int:
	return PlayerAnimation.Hold.RIGHT

## Plain-language brief for the job: need, why, steps and result.
func brief() -> Dictionary:
	return {
		"goal": BRIEF_GOAL,
		"why": BRIEF_WHY,
		"prompt": BRIEF_PROMPT,
		"result": BRIEF_RESULT,
		"hint": BRIEF_HINT,
		"source": "Probe rack at the bench (LOC-01)",
		"destination": "Bench dry-reference cradle",
		"steps": [
			"Take the moisture probe from its rack at the bench.",
			"Carry it to the bench cradle.",
			"Place it on the dry reference and read the display.",
			"The dry test is done when the display reads 0.",
		],
	}

## What the player should do next, in the current state.
func prompt() -> String:
	match _state:
		"at_rack":
			return "Take the moisture probe from its rack at the bench."
		"held":
			return "Carry the probe to the bench cradle."
		"at_bench":
			return "Read the dry reference: the display should settle at 0."
		"zeroed":
			return "Dry zero set. The probe now reads from zero."
	return ""

## Everything a panel or activity needs to show the job, detached.
func view() -> Dictionary:
	return {
		"scene_id": SCENE_ID,
		"room_id": ROOM_ID,
		"state": _state,
		"completed": completed(),
		"source": SOURCE,
		"destination": DESTINATION,
		"probe_place": probe_place(),
		"held": held(),
		"reading": reading(),
		"prompt": prompt(),
		"brief": brief(),
		"prop_scene_path": PROP_SCENE_PATH,
		"hold_pose": hold_pose(),
	}

## Retrieve the probe from its rack into the player's hands.
func retrieve() -> Dictionary:
	if completed():
		return _reject("Dry zero is already set; the probe stays calibrated.")
	if _state != "at_rack":
		return _reject("The probe is already carried or placed.")
	var result: Dictionary = inventory.pickup(PROBE_ID, "hands")
	if bool(result.get("accepted", false)):
		_state = "held"
		return {"accepted": true, "reason": "Probe in hand. Carry it to the bench cradle.", "state": _state, "probe_place": probe_place()}
	return result

## Place the carried probe in the bench dry-reference cradle.
func place_at_bench() -> Dictionary:
	if completed():
		return _reject("Dry zero is already set; the probe stays calibrated.")
	if _state != "held":
		return _reject("Carry the probe from its rack first.")
	var result: Dictionary = inventory.deliver(PROBE_ID, DESTINATION)
	if bool(result.get("accepted", false)):
		_state = "at_bench"
		return {"accepted": true, "reason": "Probe placed on the dry reference. Read the display.", "state": _state, "probe_place": probe_place()}
	return result

## Observe the dry-zero reading and complete the job exactly once. The
## display changes from the raw offset to the calibrated baseline.
func observe_zero() -> Dictionary:
	if completed():
		return _reject("Dry zero is already set; it cannot be set twice.")
	if _state != "at_bench":
		return _reject("Place the probe on the dry reference at the bench first.")
	_state = "zeroed"
	return {
		"accepted": true,
		"reason": "Dry zero set: the probe read 10 on the dry reference and now reads 0. Later readings are measured from this zero.",
		"state": _state,
		"probe_place": probe_place(),
		"reading": reading(),
		"set_zero_payload": set_zero_payload(),
	}

## Give up the transfer without losing the probe. A carried probe goes back
## on its rack; a placed probe stays in the bench cradle so the reading can
## still be taken. A completed calibration stands and cannot be cancelled.
func cancel() -> Dictionary:
	match _state:
		"at_rack":
			return _reject("Nothing to put back: the probe is already on its rack.")
		"held":
			var result: Dictionary = inventory.set_down(PROBE_ID)
			if bool(result.get("accepted", false)):
				_state = "at_rack"
				return {"accepted": true, "reason": "Probe back on its rack. Nothing is lost; start again when ready.", "state": _state, "probe_place": probe_place()}
			return result
		"at_bench":
			return {"accepted": true, "reason": "Probe stays in the bench cradle. Read the dry test when ready.", "state": _state, "probe_place": probe_place()}
		"zeroed":
			return _reject("Dry zero is already set; the calibration stands.")
	return _reject("Unknown probe state.")

## Plain-data snapshot for saves and retries. The inventory place is stored
## alongside the state so a restore can prove they agree.
func snapshot() -> Dictionary:
	return {"state": _state, "probe_place": probe_place(), "completed": completed()}

## Restores a snapshot atomically: any mismatch refuses and changes nothing.
func restore(data) -> Dictionary:
	if not data is Dictionary:
		return _reject("Probe job snapshot must be a Dictionary.")
	var next_state := String(data.get("state", ""))
	if not next_state in STATES:
		return _reject("Probe job state is unknown.")
	if not data.get("completed", null) is bool or bool(data.get("completed", false)) != (next_state == "zeroed"):
		return _reject("Probe job completion must match its state.")
	var expected_place: String = {"at_rack": "ground", "held": "hands", "at_bench": "delivered", "zeroed": "delivered"}[next_state]
	if String(data.get("probe_place", "")) != expected_place:
		return _reject("Probe job place does not match its state.")
	var rebuilt := ProbeCalibrationJob.new()
	if next_state in ["held", "at_bench", "zeroed"]:
		var carried: Dictionary = rebuilt.inventory.pickup(PROBE_ID, "hands")
		if not bool(carried.get("accepted", false)):
			return _reject("Probe job could not restore the carried probe.")
	if next_state in ["at_bench", "zeroed"]:
		var placed: Dictionary = rebuilt.inventory.deliver(PROBE_ID, DESTINATION)
		if not bool(placed.get("accepted", false)):
			return _reject("Probe job could not restore the placed probe.")
	inventory = rebuilt.inventory
	_state = next_state
	return {"accepted": true, "snapshot": snapshot()}

## Pre-M1-108 saves have no probe-job record. If such a save already has
## the dry zero set in P-01, the transfer is adopted as done rather than
## forcing the player to repeat a calibration they already finished.
func restore_legacy_zero(zeroed: bool) -> Dictionary:
	if _state != "at_rack":
		return _reject("Probe job already started; legacy zero does not apply.")
	if not zeroed:
		return {"accepted": true, "snapshot": snapshot()}
	var carried: Dictionary = inventory.pickup(PROBE_ID, "hands")
	if not bool(carried.get("accepted", false)):
		return carried
	var placed: Dictionary = inventory.deliver(PROBE_ID, DESTINATION)
	if not bool(placed.get("accepted", false)):
		return placed
	_state = "zeroed"
	return {"accepted": true, "snapshot": snapshot()}

static func _reject(reason: String) -> Dictionary:
	return {"accepted": false, "reason": reason}
