extends RefCounted
class_name Chapter5Mission

## Mission adapter for one Chapter 5 mission (EX-M0501..EX-M0504), following
## the Chapter 1/2 mission pattern: it wraps the shared ExtendedCampaignRoute
## (which already runs the chapter's physical gates, snapshot/restore and the
## Chapter 1 retry_checkpoint pattern via CampaignRoute.retry), and adds the
## mission layer — canon dialogue, the 22 §7 training decisions with
## success/partial/revise outcomes and retry, story-choice recording (24 §5
## D9/D10) through the director, the 25 §6 mission shape, the 24 §2.9 bridge
## joins, the chapter-end upgrade choice, and the M3-64 report-card seam.
## Physical play, puzzle validation and resources stay with the extended
## route/ledger; this class never duplicates them.

const GateCatalog = preload("res://scripts/missions/chapter5_gate_catalog.gd")
const StateScript = preload("res://scripts/core/campaign_state.gd")

var mission_id := ""
var _route: RefCounted
var _scene_ids: Array = []
var _started := false
var _decision_attempts := {}

func _init(id: String, route: RefCounted) -> void:
	mission_id = id
	_route = route
	_scene_ids = GateCatalog.scenes_for_mission(id)

func scene_ids() -> Array:
	return _scene_ids.duplicate()

func begin() -> Dictionary:
	if _scene_ids.is_empty():
		return {"accepted": false, "status": "blocked", "reason": "Mission has no Chapter 5 scene composition."}
	var completed: Array = _route.completed_scene_ids()
	var required: Array = []
	if mission_id == "EX-M0501":
		required = [GateCatalog.PREDECESSOR_SCENE]
	else:
		var mission_index := GateCatalog.mission_ids().find(mission_id)
		if mission_index > 0:
			required = GateCatalog.scenes_for_mission(GateCatalog.mission_ids()[mission_index - 1])
	for scene_id in required:
		if not completed.has(scene_id):
			return {"accepted": false, "status": "blocked", "reason": "Previous Chapter 5 physical scene is incomplete.", "required_scene_id": scene_id}
	var started: Dictionary = _route.start_at(_scene_ids[0])
	_started = bool(started.get("accepted", false))
	return started

func status() -> Dictionary:
	var completed: Array = _route.completed_scene_ids()
	var missing: Array[String] = []
	for scene_id in _scene_ids:
		if not completed.has(scene_id):
			missing.append(String(scene_id))
	return {
		"mission_id": mission_id,
		"implemented": true,
		"status": "complete" if missing.is_empty() else ("active" if _started else "ready"),
		"scene_ids": scene_ids(),
		"missing_scene_ids": missing,
		"physical_gate_only": true,
		"dialogue_acknowledgement_completes": false,
		"title": GateCatalog.mission_title(mission_id),
	}

func gate_status() -> Dictionary:
	return _route.gate_status()

func perform(target_id: String, payload: Dictionary = {}, context: Dictionary = {}) -> Dictionary:
	return _route.perform(target_id, payload, context)

func acknowledge_dialogue(line_id: String) -> Dictionary:
	return _route.acknowledge_dialogue(line_id)

func advance_scene() -> Dictionary:
	return _route.advance_scene()

func route() -> RefCounted:
	return _route

func director() -> RefCounted:
	return _route.director()

## Chapter 1 retry_checkpoint pattern, extended to Chapter 5: restores the
## last pre-operation checkpoint (director + route + ledger + world) without
## duplicating any scene or dialogue receipt.
func retry() -> Dictionary:
	return _route.retry()

func dialogue_lines(scene_id: String) -> Array:
	return GateCatalog.dialogue_lines(scene_id)

func training_decision(scene_id: String) -> Dictionary:
	return GateCatalog.training_decision(scene_id)

## Preview evaluation of one training-decision option. Never mutates state.
func evaluate_decision(scene_id: String, option_id: String) -> Dictionary:
	return GateCatalog.evaluate_option(scene_id, option_id)

## Confirm a training-decision option. A "revise" option is rejected with its
## feedback and the player retries (a corrected pick is a "partial" outcome
## per 22 §7). A supported / valid-alternative option is accepted; when the
## scene owns a story choice (24 §5 D9/D10) it is recorded through the
## director, which enforces owning-scene and exit-lock rules.
func confirm_decision(scene_id: String, option_id: String) -> Dictionary:
	var evaluation := GateCatalog.evaluate_option(scene_id, option_id)
	if not bool(evaluation.get("accepted", false)):
		return evaluation
	if String(evaluation.get("outcome", "")) == "revise":
		_note_attempt(scene_id, option_id, "revise")
		return {"accepted": false, "outcome": "revise", "feedback": String(evaluation.get("feedback", "")), "can_retry": true, "reason": "That option is contradicted by the evidence; revise before committing."}
	var outcome := "success"
	var attempts: Array = _decision_attempts.get(scene_id, [])
	if not attempts.is_empty():
		outcome = "partial"
	var result := {"accepted": true, "scene_id": scene_id, "choice_id": String(evaluation.get("choice_id", "")), "option_id": option_id, "outcome": String(evaluation.get("outcome", "")), "mission_outcome": outcome, "feedback": String(evaluation.get("feedback", ""))}
	var story_choice := String(evaluation.get("story_choice", ""))
	if not story_choice.is_empty():
		var command := {
			"command_id": "choice:%s:%s" % [story_choice, option_id],
			"issuer": "chapter5_mission",
			"owning_mission_id": mission_id,
			"owning_scene_id": scene_id,
			"expected_state_revision": int(_route.director().query().get("state_revision", 0)),
			"target_id": story_choice,
			"verb": "record_choice",
			"payload": {"choice_id": story_choice, "option_id": option_id},
		}
		var recorded: Dictionary = _route.director().commit(command)
		if not bool(recorded.get("accepted", false)):
			return recorded
		result["story_choice_recorded"] = true
	_note_attempt(scene_id, option_id, String(evaluation.get("outcome", "")))
	return result

func decision_outcome(scene_id: String) -> Dictionary:
	var attempts: Array = _decision_attempts.get(scene_id, [])
	if attempts.is_empty():
		return {"scene_id": scene_id, "attempted": false, "mission_outcome": "not_attempted"}
	var last: Dictionary = attempts[attempts.size() - 1]
	var revised := attempts.any(func(attempt): return String(attempt.get("outcome", "")) == "revise")
	return {"scene_id": scene_id, "attempted": true, "attempts": attempts.size(), "mission_outcome": "partial" if revised else "success", "last_option_id": String(last.get("option_id", "")), "last_outcome": String(last.get("outcome", ""))}

func record_moment(moment_id: String) -> Dictionary:
	var command := {
		"command_id": "moment:%s" % moment_id,
		"issuer": "chapter5_mission",
		"owning_mission_id": mission_id,
		"owning_scene_id": _route.current_scene_id(),
		"expected_state_revision": int(_route.director().query().get("state_revision", 0)),
		"target_id": moment_id,
		"verb": "record_moment",
		"payload": {"moment_id": moment_id},
	}
	return _route.director().commit(command)

func hint(scene_id: String, tier: int) -> Dictionary:
	return GateCatalog.hint(scene_id, tier)

func mission_shape() -> Dictionary:
	return GateCatalog.mission_shape(mission_id)

func bridge_joins() -> Array:
	return GateCatalog.bridge_joins()

func ramim_seams() -> Array:
	return GateCatalog.ramim_seams()

## Chapter entry profile (cf. Chapter2Route.apply_entry_profile): the chapter
## opens only after its predecessor scene is complete and the story clock has
## reached the chapter start. Resources are whatever the previous chapter
## left; the chapter's own entry profile is applied by the simulation when
## the first P-10 scene projects (EX-CH05-S04).
func chapter_entry() -> Dictionary:
	var completed: Array = _route.completed_scene_ids()
	var state: Dictionary = _route.director().snapshot()
	return {
		"accepted": completed.has(GateCatalog.PREDECESSOR_SCENE),
		"predecessor_scene": GateCatalog.PREDECESSOR_SCENE,
		"predecessor_complete": completed.has(GateCatalog.PREDECESSOR_SCENE),
		"chapter_start": GateCatalog.CHAPTER_ENTRY_DATE,
		"scenario_datetime": String(state.get("scenario_datetime", "")),
		"reason": "Chapter 5 opens after EX-CH04-S12, on 12 December 2046." if completed.has(GateCatalog.PREDECESSOR_SCENE) else "Chapter 5 cannot open before EX-CH04-S12 is complete.",
	}

func chapter_complete() -> bool:
	var completed: Array = _route.completed_scene_ids()
	for scene_id in GateCatalog.scene_ids():
		if not completed.has(scene_id):
			return false
	return true

func chapter_status() -> Dictionary:
	var completed: Array = _route.completed_scene_ids()
	var done: Array[String] = []
	for scene_id in GateCatalog.scene_ids():
		if completed.has(scene_id):
			done.append(String(scene_id))
	return {"chapter": GateCatalog.CHAPTER, "title": GateCatalog.CHAPTER_TITLE, "dates": GateCatalog.CHAPTER_DATES, "minutes": GateCatalog.CHAPTER_MINUTES, "complete": chapter_complete(), "completed_scene_ids": done, "upgrade_pair": GateCatalog.UPGRADE_PAIR.duplicate(), "upgrade_chosen": String(_route.director().snapshot().get("upgrades", {}).get("choices", {}).get(str(GateCatalog.CHAPTER), ""))}

## Earned chapter-end upgrade choice (24 §5.1 D8): Dust Shield or Whipple
## bumper, applied once, after the chapter is complete. The choice is stored
## in upgrades.choices (the same store the simulation reads); there is no
## receipted director verb for upgrade choice yet, so the mission applies it
## through the authoritative snapshot and says so. That verb is a follow-up
## for the simulation owner, not a silent receipt.
func choose_chapter_upgrade(option_id: String) -> Dictionary:
	if not GateCatalog.UPGRADE_PAIR.has(option_id):
		return {"accepted": false, "reason": "Option %s is not one of Chapter 5's earned upgrade pair." % option_id}
	if not chapter_complete():
		return {"accepted": false, "reason": "The Chapter 5 upgrade is earned only after all twelve scenes are complete."}
	var snapshot: Dictionary = _route.director().snapshot()
	var choices: Dictionary = (snapshot.get("upgrades", {}) as Dictionary).get("choices", {})
	if choices.has(str(GateCatalog.CHAPTER)):
		return {"accepted": false, "reason": "Chapter 5's upgrade was already chosen: " + String(choices.get(str(GateCatalog.CHAPTER), ""))}
	var next: Dictionary = snapshot.duplicate(true)
	next["upgrades"]["choices"][str(GateCatalog.CHAPTER)] = option_id
	next["upgrades"]["acquisition_chapter"][str(GateCatalog.CHAPTER)] = GateCatalog.CHAPTER
	var restored: Dictionary = _route.director().restore_snapshot(next)
	if not bool(restored.get("accepted", false)):
		return restored
	return {"accepted": true, "chapter": GateCatalog.CHAPTER, "upgrade_id": option_id, "upgrade_label": String(GateCatalog.UPGRADE_LABELS.get(option_id, option_id)), "applied_once": true, "note": "Applied through the authoritative snapshot; no receipted choose_upgrade director verb exists yet."}

## Report stage (25 §6): the exact data M3-64 will render as the mission
## Report Card. The card itself waits on M3-64 — report_ready() stays false
## until then — but the payload is complete and honest here.
func report_card_payload(scene_id: String) -> Dictionary:
	var gate_data := GateCatalog.gate(scene_id)
	var state: Dictionary = _route.director().snapshot()
	var decision: Dictionary = GateCatalog.training_decision(scene_id)
	return {
		"scene_id": scene_id,
		"mission_id": mission_id,
		"title": String(gate_data.get("title", "")),
		"exit_condition": String(gate_data.get("exit_condition", "")),
		"decision": decision,
		"decision_outcome": decision_outcome(scene_id),
		"resources": (state.get("resources", {}) as Dictionary).duplicate(true),
		"inventories": (state.get("inventories", {}) as Dictionary).duplicate(true),
		"scenario_datetime": String(state.get("scenario_datetime", "")),
		"debrief_lines": _debrief_lines(scene_id),
		"rendered_by": "M3-64 (waiting)",
	}

func report_ready(_scene_id: String) -> Dictionary:
	return {"ready": false, "reason": "The rendered Report Card waits on M3-64; report_card_payload() carries the complete card data."}

func _debrief_lines(scene_id: String) -> Array:
	match scene_id:
		"EX-CH05-S03":
			return ["Supported sequence and all-crew-returned conclusion committed.", "The garden was left. The gardener was not."]
		"EX-CH05-S06":
			return ["Both kinds of repair deserve care.", "Spare unused; present radio working; procedure opens without Earth."]
		"EX-CH05-S09":
			return ["Complete report excludes the unsupported historical impact claim.", "That blank is an honest result."]
		"EX-CH05-S12":
			return ["Cotton planted Dec 15; eleven vault specimens and thirty founder seeds protected.", "A new seed, not the old flower returning."]
	return [String(GateCatalog.gate(scene_id).get("exit_condition", ""))]

func _note_attempt(scene_id: String, option_id: String, outcome: String) -> void:
	var attempts: Array = _decision_attempts.get(scene_id, [])
	attempts.append({"option_id": option_id, "outcome": outcome})
	_decision_attempts[scene_id] = attempts

func snapshot() -> Dictionary:
	return {"schema_version": 1, "mission_id": mission_id, "started": _started, "decision_attempts": _decision_attempts.duplicate(true)}

func restore(data: Dictionary) -> Dictionary:
	if not data.get("mission_id", "") == mission_id:
		return {"accepted": false, "reason": "Mission snapshot belongs to another mission."}
	_started = bool(data.get("started", false))
	_decision_attempts = (data.get("decision_attempts", {}) as Dictionary).duplicate(true)
	return {"accepted": true, "reason": "Chapter 5 mission decision state restored."}
