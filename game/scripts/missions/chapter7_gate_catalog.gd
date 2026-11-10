extends RefCounted
class_name Chapter7GateCatalog

## Mission-level catalog for Chapter 7 — *The Great Storm* (EX-M0701..EX-M0704).
##
## Same layering as Chapter5GateCatalog: physical targets, puzzle validation
## and resource transitions live in the shared extended gate catalog and
## puzzle ledger (the puzzles worker owns extended_gate_catalog.gd); this
## catalog adds the mission layer: canon dialogue (read from the campaign
## catalog), the training decisions of game-design/22 §9.1–§9.4 with their
## success / partial / revise outcomes and hint tiers, scene rosters, dated
## time cards, the 25 §6 mission shape, the 24 §2.9 bridge joins (including
## the row marked Fix, built here), and the seams where Ramim's systems
## (M3-61 EVA, M3-62 rover, M3-64 report cards/messages, M3-65 hazards/rover)
## plug in later. Nothing here edits a canon number or a line of dialogue.

const ExtendedCatalog = preload("res://scripts/missions/extended_gate_catalog.gd")
const ContentScript = preload("res://scripts/content/content_loader.gd")
const ClockData = preload("res://resources/campaign/campaign_clock.json")
const Roster = preload("res://scripts/companions/companion_roster.gd")

const CHAPTER := 7
const CHAPTER_TITLE := "The Great Storm"
const CHAPTER_MINUTES := 105
const CHAPTER_DATES := "14 February–8 April 2047"
const PREDECESSOR_SCENE := "EX-CH06-S12"
const CHAPTER_ENTRY_DATE := "2047-02-14"
const UPGRADE_PAIR := ["relay_parts_kit", "long_range_battery"]
const UPGRADE_LABELS := {"relay_parts_kit": "Relay parts kit", "long_range_battery": "Long-range battery"}

const SCENE_ORDER := [
	"EX-CH07-S01", "EX-CH07-S02", "EX-CH07-S03", "EX-CH07-S04", "EX-CH07-S05", "EX-CH07-S06",
	"EX-CH07-S07", "EX-CH07-S08", "EX-CH07-S09", "EX-CH07-S10", "EX-CH07-S11", "EX-CH07-S12",
]

const MISSION_SCENES := {
	"EX-M0701": ["EX-CH07-S01", "EX-CH07-S02", "EX-CH07-S03"],
	"EX-M0702": ["EX-CH07-S04", "EX-CH07-S05", "EX-CH07-S06"],
	"EX-M0703": ["EX-CH07-S07", "EX-CH07-S08", "EX-CH07-S09"],
	"EX-M0704": ["EX-CH07-S10", "EX-CH07-S11", "EX-CH07-S12"],
}

const MISSION_TITLES := {
	"EX-M0701": "Your Call, Cadets",
	"EX-M0702": "What Gets the Last Drop",
	"EX-M0703": "What We Carry",
	"EX-M0704": "The Days That Make a Journey",
}

# 25 §6 mission shape, per mission. Report is the debrief stage whose rendered
# card waits on M3-64 (see ramim_seams()); the payload is built here.
const MISSION_SHAPE := {
	"EX-M0701": {"brief": ["EX-CH07-S01"], "prepare": ["EX-CH07-S01"], "go": ["EX-CH07-S01"], "investigate": ["EX-CH07-S01", "EX-CH07-S02"], "solve": ["EX-CH07-S03"], "consequence": ["EX-CH07-S03"], "report": ["EX-CH07-S03"], "bridge": ["EX-CH07-S03"]},
	"EX-M0702": {"brief": ["EX-CH07-S04"], "prepare": ["EX-CH07-S04"], "go": ["EX-CH07-S04"], "investigate": ["EX-CH07-S04", "EX-CH07-S05"], "solve": ["EX-CH07-S06"], "consequence": ["EX-CH07-S06"], "report": ["EX-CH07-S06"], "bridge": ["EX-CH07-S06"]},
	"EX-M0703": {"brief": ["EX-CH07-S07"], "prepare": ["EX-CH07-S07"], "go": ["EX-CH07-S07"], "investigate": ["EX-CH07-S07", "EX-CH07-S09"], "solve": ["EX-CH07-S08"], "consequence": ["EX-CH07-S09"], "report": ["EX-CH07-S09"], "bridge": ["EX-CH07-S09"]},
	"EX-M0704": {"brief": ["EX-CH07-S10"], "prepare": ["EX-CH07-S10"], "go": ["EX-CH07-S11"], "investigate": ["EX-CH07-S10", "EX-CH07-S11"], "solve": ["EX-CH07-S11"], "consequence": ["EX-CH07-S12"], "report": ["EX-CH07-S12"], "bridge": ["EX-CH07-S12"]},
}

# 22 §9.1–§9.4 training-decision evaluation. Prompt, options and consequences
# come from the campaign catalog at runtime; this table adds each option's
# outcome and the hint tiers. Outcomes: "supported", "revise",
# "valid_alternative" (see Chapter5GateCatalog for the definitions).
const _DECISION_EVALUATION := {
	"EX-CH07-S01": {
		"outcomes": {"EX-CH07-S01-OPT01": "revise", "EX-CH07-S01-OPT02": "supported"},
		"hints": ["Put the seeds inside before the peak.", "Water and cargo share the shielding job.", "Prepare W4 and K2; COZY/DIM throughout; drain in step 6 after exposure."],
		"data_cards": ["donki_2012_07", "stereo_a_het_2012_07", "crater_dose_2012_07", "clowdsley_2021_shielding", "bvad_2022_metabolic"],
		"outpost_note": "Labelled 2012 counterfactual source; six dark 7.2 h steps, multipliers [1,1,2,2,1,1], no solar income.",
	},
	"EX-CH07-S02": {
		"outcomes": {"EX-CH07-S02-OPT01": "revise", "EX-CH07-S02-OPT02": "supported"},
		"hints": ["April's card counted four.", "Air and food follow the number of people.", "Apply the five-person profile and match all five seat markers."],
		"data_cards": ["donki_2012_07", "stereo_a_het_2012_07", "crater_dose_2012_07", "clowdsley_2021_shielding", "bvad_2022_metabolic"],
		"outpost_note": "Five-person rates A1.25 and R1.5 per step; plants are not the life-support system.",
	},
	"EX-CH07-S03": {
		"outcomes": {"EX-CH07-S03-OPT01": "revise", "EX-CH07-S03-OPT02": "supported"},
		"hints": ["Put the seeds inside before the peak.", "Water and cargo share the shielding job.", "Prepare W4 and K2; COZY/DIM throughout; drain in step 6 after exposure."],
		"data_cards": ["donki_2012_07", "stereo_a_het_2012_07", "crater_dose_2012_07", "clowdsley_2021_shielding", "bvad_2022_metabolic"],
		"outpost_note": "One feasible six-step plan preserves crew, garden, circulation and reserve 30.",
	},
	"EX-CH07-S04": {
		"outcomes": {"EX-CH07-S04-OPT01": "revise", "EX-CH07-S04-OPT02": "supported"},
		"hints": ["Put the seeds inside before the peak.", "Water and cargo share the shielding job.", "Sample exposure, then drain; the garden only has to lend four, not six."],
		"data_cards": ["clowdsley_2021_shielding", "bvad_2022_metabolic", "stereo_a_het_2012_07"],
		"outpost_note": "Founder 30 latched as 15 + 15; shielding and after-exposure return order verified.",
	},
	"EX-CH07-S05": {
		"outcomes": {"EX-CH07-S05-OPT01": "revise", "EX-CH07-S05-OPT02": "supported"},
		"hints": ["Is a green chair the same as a person answering?", "Name, position and answer must agree.", "Call each name, hear each answer, confirm each seat, then commit."],
		"data_cards": ["clowdsley_2021_shielding", "bvad_2022_metabolic", "stereo_a_het_2012_07"],
		"outpost_note": "Five occupants confirmed, both hatch indications agree, first step ready.",
	},
	"EX-CH07-S06": {
		"outcomes": {"EX-CH07-S06-OPT01": "revise", "EX-CH07-S06-OPT02": "supported"},
		"hints": ["Finish all three waves before going outside.", "A working local radio isolates the failure to the Earth path.", "Keep the six-step witness, select F-EXT and record two below-threshold readings."],
		"data_cards": ["clowdsley_2021_shielding", "bvad_2022_metabolic", "stereo_a_het_2012_07"],
		"outpost_note": "Steps 1–2 committed, forecast comparison saved, founder case sealed.",
	},
	"EX-CH07-S07": {
		"outcomes": {"EX-CH07-S07-OPT01": "revise", "EX-CH07-S07-OPT02": "supported"},
		"hints": ["How many steps are left?", "Claim only what the ledger already shows.", "'The first wave is complete and the reserve is protected.'"],
		"data_cards": ["stereo_a_het_2012_07", "change4_lnd_surface_dose", "clowdsley_2021_shielding"],
		"outpost_note": "Final log understood; name and Academy origin resolved; bounded progress report saved.",
	},
	"EX-CH07-S08": {
		"outcomes": {"EX-CH07-S08-OPT01": "revise", "EX-CH07-S08-OPT02": "supported"},
		"hints": ["Finish all three waves before going outside.", "Judge safety by the shield, not by the frightening shape of the graph.", "Retain water and cargo through exposure; drain only after step six is sampled."],
		"data_cards": ["stereo_a_het_2012_07", "change4_lnd_surface_dose", "clowdsley_2021_shielding"],
		"outpost_note": "All six steps complete with crew, crops and founder 30 protected; witness E6, A2.5, H1, C3, R9, Z0.",
	},
	"EX-CH07-S09": {
		"outcomes": {"EX-CH07-S09-OPT01": "revise", "EX-CH07-S09-OPT02": "supported"},
		"hints": ["Finish all three waves before going outside.", "A working local radio isolates the failure to the Earth path.", "Keep the six-step witness, select F-EXT and record two below-threshold readings."],
		"data_cards": ["stereo_a_het_2012_07", "change4_lnd_surface_dose", "clowdsley_2021_shielding"],
		"outpost_note": "External branch diagnosed; two route readings clear later work; no invented Earth reply.",
	},
	"EX-CH07-S10": {
		"outcomes": {"EX-CH07-S10-OPT01": "revise", "EX-CH07-S10-OPT02": "supported"},
		"hints": ["Account for the interval, not just the climax.", "No reply from Earth is in this plan.", "Use stored procedures and verified local supplies."],
		"data_cards": ["esa_moonlight_relay", "usgs_gazetteer_south_pole", "jpl_ipn_42_176_dte", "bvad_2022_metabolic"],
		"outpost_note": "Local stability and supplies reconciled through dated February-to-March gates.",
	},
	"EX-CH07-S11": {
		"outcomes": {"EX-CH07-S11-OPT01": "revise", "EX-CH07-S11-OPT02": "supported"},
		"hints": ["Who must be able to hear the summit?", "Draw both legs: Aurora to summit, summit to Earth.", "Three repeater sites along the surveyed road, each in sight of its neighbours, plus the Earth dish."],
		"data_cards": ["esa_moonlight_relay", "usgs_gazetteer_south_pole", "jpl_ipn_42_176_dte", "bvad_2022_metabolic"],
		"outpost_note": "Compatible spare, battery, three-site route and bench-test record packed; field checks still required.",
	},
	"EX-CH07-S12": {
		"outcomes": {"EX-CH07-S12-OPT01": "revise", "EX-CH07-S12-OPT02": "supported"},
		"hints": ["A return reserve belongs in the departure plan.", "Two at home for 33 hours, then five for the last three.", "51 hours of travel fits inside 72 hours of provisions."],
		"data_cards": ["esa_moonlight_relay", "usgs_gazetteer_south_pole", "jpl_ipn_42_176_dte", "bvad_2022_metabolic"],
		"outpost_note": "Rover team Ferreira, Kai, Rafi; home team Mei, Amara; home night 2 for 33 h, then 5 for 3 h.",
	},
}

# 24 §2.9 bridge joins for this chapter. The "Fix" row is built by this
# mission layer: the carried object is named here and verified by the tests.
const _BRIDGES := [
	{"from": "EX-CH06-S12", "to": "EX-CH07-S01", "join": "CH06→CH07", "carries": "The active-region image Rafi pinned in January; he stands up from breakfast without a joke", "kinds": "O, P", "status": "Fix", "built_by": "chapter7_gate_catalog", "carried_object": "january_active_region_image"},
	{"from": "EX-CH07-S01", "to": "EX-CH07-S02", "join": "CH07 S01→S02", "carries": "The labelled source and the shared observations", "kinds": "T", "status": "Holds", "built_by": "canon"},
	{"from": "EX-CH07-S02", "to": "EX-CH07-S03", "join": "CH07 S02→S03", "carries": "Five seat markers on the shelter diagram", "kinds": "O", "status": "Holds", "built_by": "canon"},
	{"from": "EX-CH07-S03", "to": "EX-CH07-S04", "join": "CH07 S03→S04", "carries": "The return-water time in the plan", "kinds": "T", "status": "Holds", "built_by": "canon"},
	{"from": "EX-CH07-S04", "to": "EX-CH07-S05", "join": "CH07 S04→S05", "carries": "The latched 15 + 15 seed case", "kinds": "O", "status": "Holds", "built_by": "canon"},
	{"from": "EX-CH07-S05", "to": "EX-CH07-S06", "join": "CH07 S05→S06", "carries": "Both hatch indications agree", "kinds": "T", "status": "Holds", "built_by": "canon"},
	{"from": "EX-CH07-S06", "to": "EX-CH07-S07", "join": "CH07 S06→S07", "carries": "The first wave ends; the lull", "kinds": "D", "status": "Holds", "built_by": "canon"},
	{"from": "EX-CH07-S07", "to": "EX-CH07-S08", "join": "CH07 S07→S08", "carries": "'Four steps left'", "kinds": "T", "status": "Holds", "built_by": "canon"},
	{"from": "EX-CH07-S08", "to": "EX-CH07-S09", "join": "CH07 S08→S09", "carries": "The final line on the chart; Rao does not answer", "kinds": "S", "status": "Holds", "built_by": "canon"},
	{"from": "EX-CH07-S09", "to": "EX-CH07-S10", "join": "CH07 S09→S10", "carries": "The saved relay-bypass diagram", "kinds": "O", "status": "Holds", "built_by": "canon"},
	{"from": "EX-CH07-S10", "to": "EX-CH07-S11", "join": "CH07 S10→S11", "carries": "The spare controller from December, Kai's note still clipped inside", "kinds": "O", "status": "Holds", "built_by": "canon"},
	{"from": "EX-CH07-S11", "to": "EX-CH07-S12", "join": "CH07 S11→S12", "carries": "The packed equipment and the route", "kinds": "O", "status": "Holds", "built_by": "canon"},
	{"from": "EX-CH07-S12", "to": "EX-CH08-S01", "join": "CH07→CH08", "carries": "The duplicate checklists; 8 Apr 00:00", "kinds": "O, D", "status": "Holds", "built_by": "canon"},
]

# Behaviours that wait on Ramim's still-TODO tasks. None is marked done.
const _RAMIM_SEAMS := [
	{"ramim_task": "M3-64", "behaviour": "Rendered mission Report Card at the end of each Chapter 7 mission (debrief outcome, six-step ledger, bounded conclusion)", "seam": "Chapter7Mission.report_card_payload(scene_id) builds the exact card data (outcome, deltas, debrief lines); report_ready() stays false until M3-64 renders it."},
	{"ramim_task": "M3-64", "behaviour": "Delivery and rendering of the Chapter 7 join messages (25 §5: at least 2 per join; game/resources/campaign/content/messages/ch07.json already carries 2 per join)", "seam": "Message data is verified read-only by the mission tests; delivery/rendering waits on M3-64. No message text is authored here."},
	{"ramim_task": "M3-61", "behaviour": "EVA dosimeter use and outside preparation for the route-clear readings (EX-CH07-S09) and repeater field placement (EX-CH07-S11)", "seam": "S09 readings are recorded as dosimeter ledger values (0.4, then 0.3, ten scenario minutes apart) via P-14; S11 placement is a surveyed-route simulator plan only. Physical EVA use plugs into these ledger actions when M3-61 lands."},
	{"ramim_task": "M3-62", "behaviour": "Rover drive, physical repeater placement and field chain test (EX-CH07-S11), and the rover loadout drive in EX-CH07-S12", "seam": "S11 is a bench + simulator plan ('a bench pass is not field verification'); S12 is a checked loadout list. The rover itself and field verification wait on M3-62."},
	{"ramim_task": "M3-65", "behaviour": "Shared hazard-system runtime hooks for the storm (hazard state, EVA/rover exposure) and the shelter-run EVA systems (25 §4.3–§4.4, dosimeter, repeaters placed for the uplink)", "seam": "Storm hazard multipliers live in the P-13/P-14 simulation profiles and the storm is presented instrument-led (no visible radiation projectiles); hazard-system runtime state waits on M3-65."},
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
	result["chapter_id"] = "CH07"
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

## The published gate map (execution docs, work step 2). Mirrored in
## game/resources/campaign/gates/ch07_gates.json.
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
