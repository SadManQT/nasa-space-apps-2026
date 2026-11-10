extends RefCounted
class_name Chapter5GateCatalog

## Mission-level catalog for Chapter 5 — *Shooting Stars* (EX-M0501..EX-M0504).
##
## Physical targets, puzzle validation and resource transitions live in the
## shared extended gate catalog and puzzle ledger (the puzzles worker owns
## extended_gate_catalog.gd); this catalog adds the mission layer on top of
## them: canon dialogue (read from the campaign catalog, the single source of
## truth), the training decisions of game-design/22 §7.1–§7.4 with their
## success / partial / revise outcomes and hint tiers, scene rosters, dated
## time cards, the 25 §6 mission shape, the 24 §2.9 bridge joins (including
## the rows marked Fix, built here), and the seams where Ramim's systems
## (M3-61 EVA, M3-62 rover, M3-64 report cards/messages, M3-65 hazards/rover)
## plug in later. Nothing here edits a canon number or a line of dialogue.

const ExtendedCatalog = preload("res://scripts/missions/extended_gate_catalog.gd")
const ContentScript = preload("res://scripts/content/content_loader.gd")
const ClockData = preload("res://resources/campaign/campaign_clock.json")
const Roster = preload("res://scripts/companions/companion_roster.gd")

const CHAPTER := 5
const CHAPTER_TITLE := "Shooting Stars"
const CHAPTER_MINUTES := 85
const CHAPTER_DATES := "12–15 December 2046"
const PREDECESSOR_SCENE := "EX-CH04-S12"
const CHAPTER_ENTRY_DATE := "2046-12-12"
const UPGRADE_PAIR := ["dust_shield", "whipple_bumper"]
const UPGRADE_LABELS := {"dust_shield": "Dust Shield", "whipple_bumper": "Whipple bumper"}

const SCENE_ORDER := [
	"EX-CH05-S01", "EX-CH05-S02", "EX-CH05-S03", "EX-CH05-S04", "EX-CH05-S05", "EX-CH05-S06",
	"EX-CH05-S07", "EX-CH05-S08", "EX-CH05-S09", "EX-CH05-S10", "EX-CH05-S11", "EX-CH05-S12",
]

const MISSION_SCENES := {
	"EX-M0501": ["EX-CH05-S01", "EX-CH05-S02", "EX-CH05-S03"],
	"EX-M0502": ["EX-CH05-S04", "EX-CH05-S05", "EX-CH05-S06"],
	"EX-M0503": ["EX-CH05-S07", "EX-CH05-S08", "EX-CH05-S09"],
	"EX-M0504": ["EX-CH05-S10", "EX-CH05-S11", "EX-CH05-S12"],
}

const MISSION_TITLES := {
	"EX-M0501": "The Engineer Comes Home",
	"EX-M0502": "The Parts We Left Unsaid",
	"EX-M0503": "A Moon That Keeps Records",
	"EX-M0504": "Permission to Answer",
}

# 25 §6: every story mission has the same eight-stage shape. The scene each
# stage lives in, per mission. Report is the debrief stage whose rendered
# card waits on M3-64 (see ramim_seams()); the payload is built here.
const MISSION_SHAPE := {
	"EX-M0501": {"brief": ["EX-CH05-S01"], "prepare": ["EX-CH05-S01"], "go": ["EX-CH05-S01"], "investigate": ["EX-CH05-S02", "EX-CH05-S03"], "solve": ["EX-CH05-S03"], "consequence": ["EX-CH05-S03"], "report": ["EX-CH05-S03"], "bridge": ["EX-CH05-S03"]},
	"EX-M0502": {"brief": ["EX-CH05-S04"], "prepare": ["EX-CH05-S04"], "go": ["EX-CH05-S04"], "investigate": ["EX-CH05-S04", "EX-CH05-S05"], "solve": ["EX-CH05-S06"], "consequence": ["EX-CH05-S06"], "report": ["EX-CH05-S06"], "bridge": ["EX-CH05-S06"]},
	"EX-M0503": {"brief": ["EX-CH05-S07"], "prepare": ["EX-CH05-S07"], "go": ["EX-CH05-S07"], "investigate": ["EX-CH05-S07", "EX-CH05-S08"], "solve": ["EX-CH05-S08"], "consequence": ["EX-CH05-S09"], "report": ["EX-CH05-S09"], "bridge": ["EX-CH05-S09"]},
	"EX-M0504": {"brief": ["EX-CH05-S10"], "prepare": ["EX-CH05-S10"], "go": ["EX-CH05-S10"], "investigate": ["EX-CH05-S10"], "solve": ["EX-CH05-S11"], "consequence": ["EX-CH05-S12"], "report": ["EX-CH05-S12"], "bridge": ["EX-CH05-S12"]},
}

# 22 §7.1–§7.4 training-decision evaluation. The prompt, options and
# consequences come from the campaign catalog at runtime; this table adds the
# outcome of each option and the hint tiers. Outcomes:
#   "supported" — the option satisfies the scene convergence on first pick.
#   "revise" — wrong-but-reasonable; the feedback names the contradiction and
#     the player retries (a corrected first pick is a "partial" outcome).
#   "valid_alternative" — both options satisfy the convergence (a presentation
#     or relationship choice); either pick succeeds, and a story choice is
#     recorded in story_log when the scene owns one (24 §5.2 D9/D10).
const _DECISION_EVALUATION := {
	"EX-CH05-S01": {
		"outcomes": {"EX-CH05-S01-OPT01": "revise", "EX-CH05-S01-OPT02": "supported"},
		"hints": ["Who is in the station now?", "Air and food follow the number of people.", "Switch the forecast to five occupants and re-check air and food before committing."],
		"data_cards": ["change4_cotton", "bvad_2022_metabolic"],
		"outpost_note": "Occupancy changes from four to five; every forecast must be recomputed.",
	},
	"EX-CH05-S02": {
		"outcomes": {"EX-CH05-S02-OPT01": "valid_alternative", "EX-CH05-S02-OPT02": "valid_alternative"},
		"hints": ["The old number was wrong.", "A correction is useful when its reason is visible.", "Keep the date and reason beside the value."],
		"data_cards": ["change4_cotton", "bvad_2022_metabolic"],
		"outpost_note": "Spare stored once; procedure available locally; readings reconciled.",
	},
	"EX-CH05-S03": {
		"outcomes": {"EX-CH05-S03-OPT01": "supported", "EX-CH05-S03-OPT02": "revise"},
		"hints": ["Use the timestamps.", "Boarding happened after the retreat order.", "All four signatures boarded; the garden, not a person, was left behind."],
		"data_cards": ["change4_cotton", "bvad_2022_metabolic"],
		"outpost_note": "Chronology chart, fault, order, boarding with ALL FOUR RETURNED committed.",
	},
	"EX-CH05-S04": {
		"outcomes": {"EX-CH05-S04-OPT01": "revise", "EX-CH05-S04-OPT02": "supported"},
		"hints": ["Read the growth sheet beside the image.", "Curled leaves on a seedling are not petals.", "Caption: 'Young unflowered seedlings, 2034; trial stopped before flowering.'"],
		"data_cards": ["change4_cotton", "fast_plants_lifecycle"],
		"outpost_note": "Evidence Board holds the documented pre-flowering stage.",
	},
	"EX-CH05-S05": {
		"outcomes": {"EX-CH05-S05-OPT01": "valid_alternative", "EX-CH05-S05-OPT02": "valid_alternative"},
		"hints": ["Both questions lead to facts secured by the record.", "Ask about the retreat order or the saved seeds.", "Record responsibility without inventing abandonment."],
		"data_cards": ["change4_cotton", "fast_plants_lifecycle"],
		"outpost_note": "Both factual topics acknowledged; the disagreement stays visible.",
		"story_choice": "EX-CH05-S05-CHOICE",
		"choice_objects": {"EX-CH05-S05-OPT01": "ascent_manifest", "EX-CH05-S05-OPT02": "greenhouse_service_note"},
	},
	"EX-CH05-S06": {
		"outcomes": {"EX-CH05-S06-OPT01": "valid_alternative", "EX-CH05-S06-OPT02": "valid_alternative"},
		"hints": ["What makes two parts the same part?", "Check connector and rating, then isolation and mounting.", "Serial, connector, rating, isolation points, mounting checked: sign the note, keep the spare packed."],
		"data_cards": ["change4_cotton", "fast_plants_lifecycle"],
		"outpost_note": "Spare unused; present radio working; procedure opens without Earth.",
	},
	"EX-CH05-S07": {
		"outcomes": {"EX-CH05-S07-OPT01": "revise", "EX-CH05-S07-OPT02": "supported"},
		"hints": ["Compare more than one frame.", "A real flash changes; a detector fault stays.", "Verify six transients, clean and patch or verify the protective upgrade, then match the signed manifest."],
		"data_cards": ["meo_lunar_impact_flashes", "vsat_relocatable_array", "bvad_2022_metabolic"],
		"outpost_note": "Six genuine flashes verified; two detector artifacts rejected, with reasons.",
	},
	"EX-CH05-S08": {
		"outcomes": {"EX-CH05-S08-OPT01": "revise", "EX-CH05-S08-OPT02": "supported"},
		"hints": ["Two symptoms. Check their causes separately.", "Panel cleaning changes output but not the isolated leak.", "Isolate, patch and pressure-test the garden spur; verify each repair with its own measurement."],
		"data_cards": ["meo_lunar_impact_flashes", "vsat_relocatable_array", "bvad_2022_metabolic"],
		"outpost_note": "Dust lowers solar income from 8 to 6 until cleaned; the micro-leak costs air per unresolved phase.",
	},
	"EX-CH05-S09": {
		"outcomes": {"EX-CH05-S09-OPT01": "valid_alternative", "EX-CH05-S09-OPT02": "valid_alternative"},
		"hints": ["Does tonight's evidence say anything about 2034?", "A hazard that exists is not proof it caused this fault.", "File 'impact caused the 2034 fault' under Unsupported; keep 'impacts are a monitored hazard'."],
		"data_cards": ["meo_lunar_impact_flashes", "vsat_relocatable_array", "bvad_2022_metabolic"],
		"outpost_note": "Complete report excludes the unsupported historical impact claim; the blank stays visible.",
	},
	"EX-CH05-S10": {
		"outcomes": {"EX-CH05-S10-OPT01": "valid_alternative", "EX-CH05-S10-OPT02": "valid_alternative"},
		"hints": ["Match the signature against the recovered manifest.", "Compare creation times with delivery after contact returned.", "Only the signed, consented page expands N.R. into a name."],
		"data_cards": ["change4_cotton"],
		"outpost_note": "Noor identity, survival and founder role established with consented evidence.",
	},
	"EX-CH05-S11": {
		"outcomes": {"EX-CH05-S11-OPT01": "valid_alternative", "EX-CH05-S11-OPT02": "valid_alternative"},
		"hints": ["The invitation should sound like one.", "Attachments can carry the graphs; the invitation itself asks.", "Leave her room to answer."],
		"data_cards": ["change4_cotton"],
		"outpost_note": "Invitation delivered once; first live Noor voice remains reserved for Chapter 8.",
		"story_choice": "EX-CH05-S11-CHOICE",
	},
	"EX-CH05-S12": {
		"outcomes": {"EX-CH05-S12-OPT01": "supported", "EX-CH05-S12-OPT02": "revise"},
		"hints": ["Which items are seeds, and which are pages?", "The vault is twelve real specimens; the founders are a different box.", "Vault: 1 planted + 11 stored = 12. Founder reserve: 30, untouched. Album entries: not seeds."],
		"data_cards": ["change4_cotton"],
		"outpost_note": "Cotton planted Dec 15; eleven vault specimens and thirty founder seeds protected.",
	},
}

# 24 §2.9 bridge joins for this chapter. "Fix" rows are the joins this
# mission layer builds: the carried object/task/line/date is named here and
# verified by the mission tests. Kinds: O object, Q question, S sound,
# T task, L line, D dated time card, P place or person.
const _BRIDGES := [
	{"from": "EX-CH04-S12", "to": "EX-CH05-S01", "join": "CH04→CH05", "carries": "The fifth mug; the 8–12 Dec flight", "kinds": "O, D", "status": "Holds", "built_by": "canon"},
	{"from": "EX-CH05-S01", "to": "EX-CH05-S02", "join": "CH05 S01→S02", "carries": "The five-person roster; her mug carried to the table", "kinds": "O", "status": "Holds", "built_by": "canon"},
	{"from": "EX-CH05-S02", "to": "EX-CH05-S03", "join": "CH05 S02→S03", "carries": "Ferreira unpacks a sealed document sleeve from her cargo and leaves it on her shelf; on 14 Dec she brings it to the table", "kinds": "O, D", "status": "Fix", "built_by": "chapter5_gate_catalog", "carried_object": "sealed_document_sleeve"},
	{"from": "EX-CH05-S03", "to": "EX-CH05-S04", "join": "CH05 S03→S04", "carries": "The photograph of frozen trays", "kinds": "O", "status": "Holds", "built_by": "canon"},
	{"from": "EX-CH05-S04", "to": "EX-CH05-S05", "join": "CH05 S04→S05", "carries": "Mei's revised caption; Ferreira watching", "kinds": "O", "status": "Holds", "built_by": "canon"},
	{"from": "EX-CH05-S05", "to": "EX-CH05-S06", "join": "CH05 S05→S06", "carries": "The disagreement kept visible; the object Ferreira left on the table (24 §5 D9)", "kinds": "Q, O", "status": "Holds", "built_by": "chapter5_gate_catalog", "carried_object": "d9_left_object"},
	{"from": "EX-CH05-S06", "to": "EX-CH05-S07", "join": "CH05 S06→S07", "carries": "The repair procedure opens without Earth; the observation clock", "kinds": "T", "status": "Holds", "built_by": "canon"},
	{"from": "EX-CH05-S07", "to": "EX-CH05-S08", "join": "CH05 S07→S08", "carries": "The observation clock carried into maintenance", "kinds": "T", "status": "Holds", "built_by": "canon"},
	{"from": "EX-CH05-S08", "to": "EX-CH05-S09", "join": "CH05 S08→S09", "carries": "The completed report", "kinds": "O", "status": "Holds", "built_by": "canon"},
	{"from": "EX-CH05-S09", "to": "EX-CH05-S10", "join": "CH05 S09→S10", "carries": "Mei: 'An initial leads us. A record finishes it.' (EX-CH05-S09-L04); Rao's call brings a signed page", "kinds": "L, O", "status": "Holds", "built_by": "canon"},
	{"from": "EX-CH05-S10", "to": "EX-CH05-S11", "join": "CH05 S10→S11", "carries": "The journal expands N. into Noor's full name", "kinds": "O", "status": "Holds", "built_by": "canon"},
	{"from": "EX-CH05-S11", "to": "EX-CH05-S12", "join": "CH05 S11→S12", "carries": "Delivered; no immediate voice; a text the next day", "kinds": "Q, D", "status": "Holds", "built_by": "canon"},
	{"from": "EX-CH05-S12", "to": "EX-CH06-S01", "join": "CH05→CH06", "carries": "Kai's marker tape on the guide-light circuit", "kinds": "O", "status": "Holds", "built_by": "canon"},
]

# Behaviours that wait on Ramim's still-TODO tasks. Each entry names the
# mission behaviour, the Ramim task it waits on, and the seam this mission
# layer leaves for it. None of these behaviours is marked done.
const _RAMIM_SEAMS := [
	{"ramim_task": "M3-64", "behaviour": "Rendered mission Report Card at the end of each Chapter 5 mission (debrief outcome, ledger deltas, bounded conclusion)", "seam": "Chapter5Mission.report_card_payload(scene_id) builds the exact card data (outcome, deltas, debrief lines); report_ready() stays false until M3-64 renders it."},
	{"ramim_task": "M3-64", "behaviour": "Delivery and rendering of the Chapter 5 join messages (25 §5: at least 2 per join; game/resources/campaign/content/messages/ch05.json already carries 2 per join)", "seam": "Message data is verified read-only by the mission tests; delivery/rendering waits on M3-64. No message text is authored here."},
	{"ramim_task": "M3-61", "behaviour": "EVA dosimeter use and any outside preparation for the impact-flash observation (EX-CH05-S07)", "seam": "S07 is instrument-led from inside by design ('nobody must rush outside for a better view'); the mission records no EVA step. Physical EVA dosimeter use plugs into the S07 observation log when M3-61 lands."},
	{"ramim_task": "M3-65", "behaviour": "Shield-maintenance sortie and relief-cargo delivery runtime (25 §4.3 journey: unloading Ferreira's relief cargo as deliveries)", "seam": "Cargo is handled inside the chapter as physical targets (p09_check_seals, p09_store_spare_once); the delivery-system runtime and the sortie itself wait on M3-65."},
	{"ramim_task": "M3-65", "behaviour": "Shared hazard-system runtime hooks for the impact-flash hazard (hazard state, EVA exposure)", "seam": "The hazard is presented as the P-10 teaching sequence (instrument view, amplified flashes, no meteor trails); hazard-system state hooks wait on M3-65."},
]

static func scene_ids() -> Array:
	return SCENE_ORDER.duplicate()

static func mission_ids() -> Array:
	return MISSION_SCENES.keys()

static func scenes_for_mission(mission_id: String) -> Array:
	return (MISSION_SCENES.get(mission_id, []) as Array).duplicate()

static func mission_title(mission_id: String) -> String:
	return String(MISSION_TITLES.get(mission_id, ""))

static func mission_shape(mission_id: String) -> Dictionary:
	return (MISSION_SHAPE.get(mission_id, {}) as Dictionary).duplicate(true)

static func mission_shape_stages() -> Array:
	return ["brief", "prepare", "go", "investigate", "solve", "consequence", "report", "bridge"]

static func gate(scene_id: String) -> Dictionary:
	var base := ExtendedCatalog.gate(scene_id)
	if base.is_empty():
		return {}
	var content := ContentScript.scene_by_id(ContentScript.load_full(), scene_id)
	var result := base.duplicate(true)
	result["chapter_id"] = "CH05"
	result["title"] = String(content.get("title", ""))
	result["minutes"] = int(content.get("minutes", 0))
	result["point_of_view"] = String(content.get("point_of_view", ""))
	result["story_time"] = String(content.get("story_time", ""))
	result["location"] = String(content.get("location", ""))
	result["exit_condition"] = String(content.get("exit_condition", ""))
	result["learning"] = (content.get("learning", {}) as Dictionary).duplicate(true)
	result["player_actions"] = (content.get("actions", []) as Array).duplicate()
	result["dialogue"] = dialogue_lines(scene_id)
	result["decision"] = training_decision(scene_id)
	result["roster"] = roster(scene_id)
	result["time_card"] = time_card(scene_id)
	return result

static func required_physical(scene_id: String) -> Array:
	return ExtendedCatalog.required_physical(scene_id)

static func targets_for_scene(scene_id: String) -> Array:
	return ExtendedCatalog.targets_for_scene(scene_id)

static func dialogue_ids(scene_id: String) -> Array:
	var content := ContentScript.scene_by_id(ContentScript.load_full(), scene_id)
	return (content.get("dialogue_ids", []) as Array).duplicate()

static func dialogue_lines(scene_id: String) -> Array:
	var content := ContentScript.scene_by_id(ContentScript.load_full(), scene_id)
	var result: Array = []
	for line in content.get("dialogue", []):
		if line is Dictionary:
			result.append({"id": String(line.get("id", "")), "speaker": String(line.get("speaker", "")), "speaker_label": String(line.get("speaker_label", line.get("speaker", ""))), "text": String(line.get("text", "")), "origin_label": String(line.get("origin_label", ""))})
	return result

static func training_decision(scene_id: String) -> Dictionary:
	var content := ContentScript.scene_by_id(ContentScript.load_full(), scene_id)
	var choice: Dictionary = content.get("choice", {})
	if choice.is_empty():
		return {}
	var evaluation: Dictionary = _DECISION_EVALUATION.get(scene_id, {})
	var result := choice.duplicate(true)
	result["outcomes"] = (evaluation.get("outcomes", {}) as Dictionary).duplicate()
	result["hints"] = (evaluation.get("hints", []) as Array).duplicate()
	result["data_cards"] = (evaluation.get("data_cards", []) as Array).duplicate()
	result["outpost_note"] = String(evaluation.get("outpost_note", ""))
	if evaluation.has("story_choice"):
		result["story_choice"] = String(evaluation["story_choice"])
	if evaluation.has("choice_objects"):
		result["choice_objects"] = (evaluation["choice_objects"] as Dictionary).duplicate()
	return result

## Pure preview evaluation of one training-decision option. No state changes.
## Returns outcome "supported" | "revise" | "valid_alternative", the feedback
## (the option's canon consequence), whether the player may retry, and the
## mission-level outcome (success on first pick, partial after a correction).
static func evaluate_option(scene_id: String, option_id: String) -> Dictionary:
	var decision := training_decision(scene_id)
	if decision.is_empty():
		return {"accepted": false, "reason": "Scene %s has no training decision." % scene_id}
	var outcomes: Dictionary = decision.get("outcomes", {})
	if not outcomes.has(option_id):
		return {"accepted": false, "reason": "Option %s is not part of %s." % [option_id, String(decision.get("id", ""))]}
	var outcome := String(outcomes[option_id])
	var option := {}
	for candidate in decision.get("options", []):
		if String(candidate.get("id", "")) == option_id:
			option = candidate
	return {
		"accepted": true,
		"scene_id": scene_id,
		"choice_id": String(decision.get("id", "")),
		"option_id": option_id,
		"option_label": String(option.get("label", "")),
		"feedback": String(option.get("consequence", "")),
		"outcome": outcome,
		"can_retry": outcome == "revise",
		"mission_outcome": "success" if outcome != "revise" else "partial_after_correction",
		"convergence": String(decision.get("convergence", "")),
		"story_choice": String(decision.get("story_choice", "")),
	}

static func hint(scene_id: String, tier: int) -> Dictionary:
	var decision := training_decision(scene_id)
	var hints: Array = decision.get("hints", [])
	if tier < 1 or tier > hints.size():
		return {"accepted": false, "reason": "Hint tier %d is not defined for %s." % [tier, scene_id]}
	return {"accepted": true, "scene_id": scene_id, "tier": tier, "text": String(hints[tier - 1])}

static func roster(scene_id: String) -> Dictionary:
	var content := ContentScript.scene_by_id(ContentScript.load_full(), scene_id)
	var placed := Roster.scene_roster(scene_id)
	return {"point_of_view": String(content.get("point_of_view", "")), "actors": placed}

static func time_card(scene_id: String) -> Dictionary:
	var content := ContentScript.scene_by_id(ContentScript.load_full(), scene_id)
	var clock: Dictionary = ClockData.data.scenes.get(scene_id, {})
	return {"story_time": String(content.get("story_time", "")), "not_before": String(clock.get("not_before", "")), "precision": String(clock.get("precision", ""))}

static func bridge_joins() -> Array:
	return _BRIDGES.duplicate(true)

static func bridge_join(from_scene: String, to_scene: String) -> Dictionary:
	for join in _BRIDGES:
		if String(join.get("from", "")) == from_scene and String(join.get("to", "")) == to_scene:
			return (join as Dictionary).duplicate(true)
	return {}

static func ramim_seams() -> Array:
	return _RAMIM_SEAMS.duplicate(true)

## The published gate map (execution docs, work step 2): one row per scene with
## the predicate, physical flags, dialogue IDs, decision choice and supported
## option, exit condition, time card and roster POV. Mirrored in
## game/resources/campaign/gates/ch05_gates.json.
static func gate_map() -> Array:
	var result: Array = []
	for scene_id in SCENE_ORDER:
		var gate_data := gate(scene_id)
		var decision: Dictionary = gate_data.get("decision", {})
		var supported := ""
		for option_id in (decision.get("outcomes", {}) as Dictionary).keys():
			if String(decision.outcomes[option_id]) == "supported":
				supported = String(option_id)
		result.append({
			"scene_id": scene_id,
			"mission_id": String(gate_data.get("mission_id", "")),
			"room_id": String(gate_data.get("room_id", "")),
			"predicate_id": String(gate_data.get("predicate_id", "")),
			"required_physical": gate_data.get("required_physical", []).duplicate(),
			"dialogue_ids": dialogue_ids(scene_id),
			"decision_choice_id": String(decision.get("id", "")),
			"supported_option_id": supported,
			"exit_condition": String(gate_data.get("exit_condition", "")),
			"story_time": String(gate_data.get("story_time", "")),
			"point_of_view": String(gate_data.get("point_of_view", "")),
		})
	return result
