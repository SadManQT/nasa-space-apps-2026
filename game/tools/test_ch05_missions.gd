## Godot --headless --path game --script res://tools/test_ch05_missions.gd
## Chapter 5 missions EX-M0501..EX-M0504 (M3-5M): physical play, crew and
## retry. Drives the shared extended route from Chapter 3 through Chapter 5,
## exercising the Chapter5Mission layer at every scene: canon dialogue,
## training decisions (22 §7.1–§7.4) with revise-and-retry, story choices
## D9/D10 (24 §5.2), bridge joins (24 §2.9), retry checkpoints, chapter
## boundaries, the Dust Shield / Whipple upgrade choice, and the M3-64
## report-card seam. Manual testing / screenshots are deferred by Judy's
## decision; this suite is the acceptance evidence.
extends SceneTree

const Witness3 = preload("res://tools/support/chapter3_witness.gd")
const Witness2 = preload("res://tools/support/chapter2_witness.gd")
const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const Chapter2RouteScript = preload("res://scripts/missions/chapter2_route.gd")
const Chapter2GateCatalog = preload("res://scripts/missions/chapter2_gate_catalog.gd")
const ExtendedRouteScript = preload("res://scripts/missions/extended_campaign_route.gd")
const ExtendedGateCatalog = preload("res://scripts/missions/extended_gate_catalog.gd")
const GateCatalog = preload("res://scripts/missions/chapter5_gate_catalog.gd")
const MissionScript = preload("res://scripts/missions/chapter5_mission.gd")
const RegistryScript = preload("res://scripts/missions/mission_registry.gd")
const PuzzleData = preload("res://scripts/puzzles/puzzle_data.gd")
const Witness4 = preload("res://tools/support/chapter4_witness.gd")
const Witness6 = preload("res://tools/support/chapter6_witness.gd")
const Witness = preload("res://tools/support/chapter8_witness.gd")

var checks := 0
var failures := 0

# Canon dialogue (execution/MISSION_EX_M0501..M0504.md): line id -> speaker, text.
const EXPECTED_DIALOGUE := {
	"EX-CH05-S01-L01": ["Rafi", "Name and seal indication, please."],
	"EX-CH05-S01-L02": ["Ferreira", "Ferreira. Seal indication checked twice."],
	"EX-CH05-S01-L03": ["Kai", "Your mug passed inspection."],
	"EX-CH05-S01-L04": ["Amara", "We are revising the occupancy ledger."],
	"EX-CH05-S02-L01": ["Ferreira", "A good watch can be quiet."],
	"EX-CH05-S02-L02": ["Amara", "Quiet still needs a record."],
	"EX-CH05-S02-L03": ["Rafi", "Controller serial matches the manifest."],
	"EX-CH05-S02-L04": ["Kai", "The instructions stay here without Earth."],
	"EX-CH05-S03-L01": ["Ferreira", "First the records. Then my memories."],
	"EX-CH05-S03-L02": ["Amara", "A condition is not the failure time."],
	"EX-CH05-S03-L03": ["Rafi", "Every name has a boarding mark."],
	"EX-CH05-S03-L04": ["Mei", "The garden was left. The gardener was not."],
	"EX-CH05-S04-L01": ["Mei", "I thought those shapes were flowers."],
	"EX-CH05-S04-L02": ["Amara", "Read the growth sheet beside the image."],
	"EX-CH05-S04-L03": ["Ferreira", "We left before reproduction."],
	"EX-CH05-S04-L04": ["Mei", "Then Alo finished a step they could not."],
	"EX-CH05-S05-L01": ["Ferreira", "I was the engineer who could not fix the radio."],
	"EX-CH05-S05-L02": ["Mei", "You could have told us."],
	"EX-CH05-S05-L03": ["Ferreira", "Yes. I was afraid of how it would sound."],
	"EX-CH05-S05-L04": ["Kai", "Then we can ask before we guess."],
	"EX-CH05-S06-L01": ["Kai", "Matching shape is not matching specification."],
	"EX-CH05-S06-L02": ["Rafi", "Read the connector and isolation points."],
	"EX-CH05-S06-L03": ["Mei", "Our other question needs permission."],
	"EX-CH05-S06-L04": ["Ferreira", "Both kinds of repair deserve care."],
	"EX-CH05-S07-L01": ["Kai", "No trails?"],
	"EX-CH05-S07-L02": ["Amara", "Not like meteors crossing Earth's air."],
	"EX-CH05-S07-L03": ["Rafi", "Check the frame before and after."],
	"EX-CH05-S07-L04": ["Mei", "A tiny flash can leave a mark."],
	"EX-CH05-S08-L01": ["Amara", "Two symptoms. Check their causes separately."],
	"EX-CH05-S08-L02": ["Kai", "The dust kept a diary."],
	"EX-CH05-S08-L03": ["Mei", "Read it after the pressure check."],
	"EX-CH05-S08-L04": ["Ferreira", "Protection changes the job, not the check."],
	"EX-CH05-S09-L01": ["Rafi", "Tonight's flashes do not date the old fault."],
	"EX-CH05-S09-L02": ["Amara", "That blank is an honest result."],
	"EX-CH05-S09-L03": ["Ferreira", "Leave it blank until we know."],
	"EX-CH05-S09-L04": ["Mei", "An initial leads us. A record finishes it."],
	"EX-CH05-S10-L01": ["Rao", "She gave permission to share the page."],
	"EX-CH05-S10-L02": ["Ferreira", "Dr. Noor Rahman. Our gardener, from Bangladesh."],
	"EX-CH05-S10-L03": ["Mei", "She read the reports we sent?"],
	"EX-CH05-S10-L04": ["Rao", "Every one that reached Earth."],
	"EX-CH05-S11-L01": ["Kai", "Should we send every graph?"],
	"EX-CH05-S11-L02": ["Amara", "Attachments can do that."],
	"EX-CH05-S11-L03": ["Mei", "The invitation should sound like one."],
	"EX-CH05-S11-L04": ["Ferreira", "Leave her room to answer."],
	"EX-CH05-S12-L01": ["Noor", "Thank you for asking. I would like to see what you grow next."],
	"EX-CH05-S12-L02": ["Amara", "Cotton planted. Eleven other vault specimens protected."],
	"EX-CH05-S12-L03": ["Rafi", "Founder reserve is a separate ledger."],
	"EX-CH05-S12-L04": ["Mei", "A new seed, not the old flower returning."],
}

# 22 §7 expected decision outcomes per option: "supported" | "revise" |
# "valid_alternative". The revise option is listed first for every scene
# where one exists.
const EXPECTED_OUTCOMES := {
	"EX-CH05-S01": {"EX-CH05-S01-OPT01": "revise", "EX-CH05-S01-OPT02": "supported"},
	"EX-CH05-S02": {"EX-CH05-S02-OPT01": "valid_alternative", "EX-CH05-S02-OPT02": "valid_alternative"},
	"EX-CH05-S03": {"EX-CH05-S03-OPT01": "supported", "EX-CH05-S03-OPT02": "revise"},
	"EX-CH05-S04": {"EX-CH05-S04-OPT01": "revise", "EX-CH05-S04-OPT02": "supported"},
	"EX-CH05-S05": {"EX-CH05-S05-OPT01": "valid_alternative", "EX-CH05-S05-OPT02": "valid_alternative"},
	"EX-CH05-S06": {"EX-CH05-S06-OPT01": "valid_alternative", "EX-CH05-S06-OPT02": "valid_alternative"},
	"EX-CH05-S07": {"EX-CH05-S07-OPT01": "revise", "EX-CH05-S07-OPT02": "supported"},
	"EX-CH05-S08": {"EX-CH05-S08-OPT01": "revise", "EX-CH05-S08-OPT02": "supported"},
	"EX-CH05-S09": {"EX-CH05-S09-OPT01": "valid_alternative", "EX-CH05-S09-OPT02": "valid_alternative"},
	"EX-CH05-S10": {"EX-CH05-S10-OPT01": "valid_alternative", "EX-CH05-S10-OPT02": "valid_alternative"},
	"EX-CH05-S11": {"EX-CH05-S11-OPT01": "valid_alternative", "EX-CH05-S11-OPT02": "valid_alternative"},
	"EX-CH05-S12": {"EX-CH05-S12-OPT01": "supported", "EX-CH05-S12-OPT02": "revise"},
}

const EXPECTED_MINUTES := {"EX-M0501": 20, "EX-M0502": 20, "EX-M0503": 25, "EX-M0504": 20}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_check_catalog()
	_check_registry()
	var director := DirectorScript.new()
	director.new_campaign(CampaignContentFull.EXPECTED_CONTENT_REVISION)
	var handoff: Dictionary = director.snapshot()
	handoff["chapter1_ready"] = true
	director.restore_snapshot(handoff)
	# Fresh-route guards: missions cannot start before their predecessor.
	var fresh_route := ExtendedRouteScript.new(director)
	var blocked_first := MissionScript.new("EX-M0501", fresh_route)
	_check(not bool(blocked_first.begin().get("accepted", false)) and String(blocked_first.begin().get("required_scene_id", "")) == "EX-CH04-S12", "EX-M0501 cannot begin before EX-CH04-S12")
	var blocked_second := MissionScript.new("EX-M0502", fresh_route)
	_check(not bool(blocked_second.begin().get("accepted", false)) and String(blocked_second.begin().get("required_scene_id", "")) == "EX-CH05-S01", "EX-M0502 cannot begin before EX-M0501")
	# Chapter 2 handoff, then drive Chapters 3–4 on the extended route.
	var pollination := Chapter2RouteScript.new(director)
	_check(bool(pollination.apply_entry_profile().get("accepted", false)), "P-03 entry profile is explicit")
	pollination.start_at("EX-CH02-S01")
	for scene_id in Chapter2GateCatalog.SCENE_ORDER:
		for target in pollination.targets_for_current_scene():
			var action: Dictionary = pollination.perform(String(target.get("target_id", "")), Witness2.payload(String(target.get("puzzle_action", ""))))
			_check(bool(action.get("accepted", false)), "dated Chapter 2 handoff operation " + String(target.get("target_id", "")))
		pollination.advance_scene()
	var route := ExtendedRouteScript.new(director)
	_check(bool(route.start_at("EX-CH03-S01").get("accepted", false)), "extended route starts at canonical Chapter 3")
	_drive_chapter(route, director, 3)
	_drive_chapter(route, director, 4)
	_check(route.current_scene_id() == "EX-CH05-S01", "route arrives at Chapter 5 entry")
	# Chapter 5, mission by mission, through the mission layer.
	var missions: Array = []
	for mission_id in ["EX-M0501", "EX-M0502", "EX-M0503", "EX-M0504"]:
		var mission = RegistryScript.new().create(mission_id, director, route)
		missions.append(mission)
		_check(bool(mission.begin().get("accepted", false)), mission_id + " begins after its predecessor")
		if mission_id == "EX-M0501":
			_check(bool(mission.chapter_entry().get("accepted", false)) and bool(mission.chapter_entry().get("predecessor_complete", false)), "Chapter 5 entry profile: EX-CH04-S12 complete, 12 December 2046")
		for scene_id in mission.scene_ids():
			_drive_mission_scene(mission, route, director, scene_id)
		_check(String(mission.status().get("status", "")) == "complete", mission_id + " reports complete")
		_check(bool(mission.report_card_payload(mission.scene_ids()[2]).get("decision", {}).has("id")), mission_id + " report payload carries its debrief decision")
		_check(not bool(mission.report_ready(mission.scene_ids()[2]).get("ready", false)) and String(mission.report_ready(mission.scene_ids()[2]).get("reason", "")).contains("M3-64"), mission_id + " rendered Report Card honestly waits on M3-64")
	var last_mission = missions[3]
	_check(bool(last_mission.chapter_complete()), "Chapter 5 reports complete after EX-CH05-S12")
	_verify_chapter_end(route, director, last_mission)
	_check(bool(route.start_at("EX-CH06-S01").get("accepted", false)), "route opens EX-CH06-S01 after the chapter boundary")
	_check_messages()
	_check_gate_map_json()
	print("CHAPTER 5 MISSIONS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)

func _check_catalog() -> void:
	_check(GateCatalog.scene_ids().size() == 12, "Chapter 5 catalog has twelve scenes")
	_check(GateCatalog.mission_ids().size() == 4, "Chapter 5 catalog has four missions")
	var minutes := 0
	for mission_id in GateCatalog.mission_ids():
		_check(GateCatalog.scenes_for_mission(mission_id).size() == 3, mission_id + " has three scenes")
		var scene_minutes := 0
		for scene_id in GateCatalog.scenes_for_mission(mission_id):
			scene_minutes += int(GateCatalog.gate(scene_id).get("minutes", 0))
		_check(scene_minutes == int(EXPECTED_MINUTES[mission_id]), mission_id + " first-time length is %d minutes" % int(EXPECTED_MINUTES[mission_id]))
		minutes += scene_minutes
		var shape := GateCatalog.mission_shape(mission_id)
		for stage in GateCatalog.mission_shape_stages():
			_check(shape.has(stage) and not (shape[stage] as Array).is_empty(), mission_id + " mission shape has a " + stage + " stage")
	_check(minutes == GateCatalog.CHAPTER_MINUTES, "Chapter 5 totals 85 first-time minutes")
	_check(GateCatalog.UPGRADE_PAIR == ["dust_shield", "whipple_bumper"], "Chapter 5 earned upgrade pair is Dust Shield / Whipple bumper")
	for scene_id in GateCatalog.scene_ids():
		var gate_data := GateCatalog.gate(scene_id)
		_check(String(gate_data.get("mission_id", "")).begins_with("EX-M05"), scene_id + " belongs to a Chapter 5 mission")
		_check(String(gate_data.get("predicate_id", "")) == "PRED-%s-EXIT" % scene_id, scene_id + " predicate id is canonical")
		_check(not (gate_data.get("required_physical", []) as Array).is_empty(), scene_id + " has physical requirements")
		_check((gate_data.get("player_actions", []) as Array).size() >= 2, scene_id + " lists its required player actions")
		_check(String(gate_data.get("exit_condition", "")).length() > 10, scene_id + " has an exit condition")
		var lines := GateCatalog.dialogue_lines(scene_id)
		_check(lines.size() == 4, scene_id + " has four canon dialogue lines")
		for line in lines:
			var expected: Array = EXPECTED_DIALOGUE.get(String(line.get("id", "")), [])
			_check(not expected.is_empty() and String(line.get("speaker", "")) == String(expected[0]) and String(line.get("text", "")) == String(expected[1]), String(line.get("id", "")) + " canon speaker and text match the mission docs")
		_check(String(lines[0].get("id", "")).ends_with("L01"), scene_id + " dialogue starts at L01")
		var decision := GateCatalog.training_decision(scene_id)
		_check((decision.get("options", []) as Array).size() == 2, scene_id + " training decision offers two real alternatives")
		_check((decision.get("hints", []) as Array).size() == 3, scene_id + " has three hint tiers")
		_check(not (decision.get("data_cards", []) as Array).is_empty(), scene_id + " names its Data Cards")
		for option_id in (EXPECTED_OUTCOMES[scene_id] as Dictionary).keys():
			var evaluated := GateCatalog.evaluate_option(scene_id, String(option_id))
			_check(bool(evaluated.get("accepted", false)) and String(evaluated.get("outcome", "")) == String((EXPECTED_OUTCOMES[scene_id] as Dictionary)[option_id]), scene_id + " option " + String(option_id) + " evaluates as " + String((EXPECTED_OUTCOMES[scene_id] as Dictionary)[option_id]))
			_check(String(evaluated.get("feedback", "")).length() > 10, scene_id + " option feedback is specific")
		var bad_option := GateCatalog.evaluate_option(scene_id, scene_id + "-OPT99")
		_check(not bool(bad_option.get("accepted", false)), scene_id + " rejects an unknown decision option")
		var hint2 := GateCatalog.hint(scene_id, 2)
		_check(bool(hint2.get("accepted", false)) and String(hint2.get("text", "")).length() > 5, scene_id + " hint tier 2 is defined")
		_check(not bool(GateCatalog.hint(scene_id, 4).get("accepted", false)), scene_id + " has no hint tier 4")
		var roster: Dictionary = GateCatalog.roster(scene_id)
		_check((roster.get("actors", {}) as Dictionary).size() == 5, scene_id + " places five people per the scene roster")
		_check((roster.get("actors", {}) as Dictionary).has("ferreira"), scene_id + " roster includes Ferreira")
		var time_card: Dictionary = GateCatalog.time_card(scene_id)
		_check(String(time_card.get("not_before", "")).begins_with("2046-12-"), scene_id + " dated time card is in December 2046")
		_check(String(time_card.get("story_time", "")).length() > 5, scene_id + " has a story time card")
	# 24 §2.9 bridge joins: thirteen rows, every Fix row built here.
	var joins := GateCatalog.bridge_joins()
	_check(joins.size() == 13, "Chapter 5 bridge list has thirteen joins")
	for join in joins:
		_check(String(join.get("carries", "")).length() > 5 and String(join.get("kinds", "")).length() > 0, String(join.get("join", "")) + " join names what it carries")
		if String(join.get("status", "")) == "Fix":
			_check(String(join.get("built_by", "")) == "chapter5_gate_catalog" and String(join.get("carried_object", "")).length() > 0, String(join.get("join", "")) + " Fix join is built with a named carried object")
	var sleeve := GateCatalog.bridge_join("EX-CH05-S02", "EX-CH05-S03")
	_check(String(sleeve.get("carried_object", "")) == "sealed_document_sleeve", "S02→S03 Fix join carries the sealed document sleeve to the 14 Dec table")
	var d9_join := GateCatalog.bridge_join("EX-CH05-S05", "EX-CH05-S06")
	_check(String(d9_join.get("carried_object", "")) == "d9_left_object", "S05→S06 join carries the D9 object Ferreira left on the table")
	# Ramim seams name the waiting tasks and the seam left for each.
	var seams := GateCatalog.ramim_seams()
	var seam_tasks: Array = []
	for seam in seams:
		seam_tasks.append(String(seam.get("ramim_task", "")))
		_check(String(seam.get("behaviour", "")).length() > 10 and String(seam.get("seam", "")).length() > 10, "Ramim seam names the waiting behaviour and the seam left")
	_check(seam_tasks.has("M3-64") and seam_tasks.has("M3-61") and seam_tasks.has("M3-65"), "Chapter 5 Ramim seams cover M3-61, M3-64 and M3-65")
	_check(not seam_tasks.has("M3-62"), "Chapter 5 has no rover seam (M3-62 belongs to Chapter 7)")

func _check_registry() -> void:
	var registry = RegistryScript.new()
	for mission_id in ["EX-M0501", "EX-M0502", "EX-M0503", "EX-M0504"]:
		_check(registry.is_implemented(mission_id), mission_id + " is registered as implemented")
		var created = registry.create(mission_id)
		_check(created is Chapter5Mission, mission_id + " creates a Chapter5Mission")
		_check(String(created.status().get("status", "")) == "ready", mission_id + " starts ready")
	var status: Dictionary = registry.registry_status()
	_check(int(status.get("implemented_count", 0)) >= 16, "registry counts Chapters 1, 2, 5 and 7 as implemented")
	var honesty: Dictionary = registry.validate_honesty()
	_check(bool(honesty.get("valid", false)), "registry honesty validation passes with Chapters 5 and 7 implemented")

func _drive_chapter(route: RefCounted, director: RefCounted, chapter: int) -> void:
	for order in range(1, 13):
		var scene_id := "EX-CH%02d-S%02d" % [chapter, order]
		_check(route.current_scene_id() == scene_id, "route is at " + scene_id)
		for target in route.targets_for_current_scene():
			var payload: Dictionary = (target.get("payload_defaults", {}) as Dictionary).duplicate(true) if target.get("payload_defaults", {}) is Dictionary else {}
			# The catalog no longer pre-fills puzzle answers (Ramim: Ch4/6/8
			# player decides in the panel; M3-5P/M3-7P: Ch5/7 answers live in
			# the puzzle data files). Supply them the way the extended route
			# walk does: puzzle data first, then the Chapter 4/6/8 witnesses.
			if payload.is_empty():
				payload = PuzzleData.gate_payload(String(target.get("puzzle_action", "")))
			payload = Witness3.payload(String(target.get("target_id", "")), director.snapshot(), payload)
			payload = Witness4.payload(String(target.get("target_id", "")), director.snapshot(), payload)
			payload = Witness6.payload(String(target.get("target_id", "")), director.snapshot(), payload)
			payload = Witness.payload(String(target.get("target_id", "")), director.snapshot(), payload)
			var result: Dictionary = route.perform(String(target.get("target_id", "")), payload)
			if not bool(result.get("accepted", false)):
				print("CH%02d DETAIL " % chapter, scene_id, " / ", target.get("target_id", ""), " -> ", result.get("reason", ""), " trace=", result.get("trace", {}))
			_check(bool(result.get("accepted", false)), scene_id + " commits " + String(target.get("target_id", "")))
		_check(bool(route.gate_status().get("ready", false)), scene_id + " physical gate is ready")
		var moved: Dictionary = route.advance_scene()
		if order == 12:
			_check(bool(moved.get("chapter_complete", false)), scene_id + " closes its chapter boundary")
			if chapter < 8:
				var next_scene := "EX-CH%02d-S01" % (chapter + 1)
				_check(bool(route.start_at(next_scene).get("accepted", false)), "route opens " + next_scene)
		else:
			_check(bool(moved.get("accepted", false)), scene_id + " advances in canonical order")

func _drive_mission_scene(mission: RefCounted, route: RefCounted, director: RefCounted, scene_id: String) -> void:
	_check(route.current_scene_id() == scene_id, "mission route is at " + scene_id)
	var gate_data := GateCatalog.gate(scene_id)
	_check(String(route.current_room_id()) == String(gate_data.get("room_id", "")), scene_id + " plays in its canonical room")
	# Dialogue: every canon line is acknowledged through the mission; a
	# second acknowledgement is idempotent, never a duplicated receipt.
	var lines: Array = mission.dialogue_lines(scene_id)
	for line in lines:
		var ack: Dictionary = mission.acknowledge_dialogue(String(line.get("id", "")))
		if not bool(ack.get("accepted", false)):
			print("DIALOGUE DETAIL ", scene_id, " / ", line.get("id", ""), " -> ", ack.get("reason", ""))
		_check(bool(ack.get("accepted", false)), scene_id + " acknowledges " + String(line.get("id", "")))
	var first_line: Dictionary = lines[0]
	var receipts_before := (director.snapshot().get("receipts", {}) as Dictionary).size()
	var dup: Dictionary = mission.acknowledge_dialogue(String(first_line.get("id", "")))
	_check(bool(dup.get("accepted", false)) and (director.snapshot().get("receipts", {}) as Dictionary).size() == receipts_before, scene_id + " duplicate acknowledgement adds no receipt")
	# Training decision: the revise option (where one exists) is refused with
	# feedback and a retry; the supported / valid-alternative option commits.
	# S05 records D9 as OPT01 (ascent manifest left on the table); S11
	# records D10 as OPT02 (we kept a place for your work).
	var decision: Dictionary = mission.training_decision(scene_id)
	var outcomes: Dictionary = decision.get("outcomes", {})
	var revise_option := ""
	var commit_option := ""
	for option_id in outcomes.keys():
		if String(outcomes[option_id]) == "revise":
			revise_option = String(option_id)
		elif commit_option.is_empty():
			commit_option = String(option_id)
	if scene_id == "EX-CH05-S05":
		commit_option = "EX-CH05-S05-OPT01"
	if scene_id == "EX-CH05-S11":
		commit_option = "EX-CH05-S11-OPT02"
	if not revise_option.is_empty():
		var refused: Dictionary = mission.confirm_decision(scene_id, revise_option)
		_check(not bool(refused.get("accepted", false)) and bool(refused.get("can_retry", false)), scene_id + " revise option is refused with a retry")
		_check(String(refused.get("feedback", "")) == String(GateCatalog.evaluate_option(scene_id, revise_option).get("feedback", "")), scene_id + " revise feedback is the canon consequence")
	var confirmed: Dictionary = mission.confirm_decision(scene_id, commit_option)
	_check(bool(confirmed.get("accepted", false)), scene_id + " commits decision option " + commit_option)
	var outcome: Dictionary = mission.decision_outcome(scene_id)
	_check(String(outcome.get("mission_outcome", "")) == ("partial" if not revise_option.is_empty() else "success"), scene_id + " decision outcome is " + String(outcome.get("mission_outcome", "")))
	if scene_id == "EX-CH05-S05":
		var choices: Dictionary = (director.snapshot().get("story_log", {}) as Dictionary).get("choices", {})
		_check(String((choices.get("EX-CH05-S05-CHOICE", {}) as Dictionary).get("option_id", "")) == "EX-CH05-S05-OPT01", "D9 recorded: Mei asks 'Why did you wait?' first")
		_check(String((decision.get("choice_objects", {}) as Dictionary).get("EX-CH05-S05-OPT01", "")) == "ascent_manifest", "D9 OPT01 leaves the ascent manifest at Ferreira's place")
	if scene_id == "EX-CH05-S11":
		var choices11: Dictionary = (director.snapshot().get("story_log", {}) as Dictionary).get("choices", {})
		_check(String((choices11.get("EX-CH05-S11-CHOICE", {}) as Dictionary).get("option_id", "")) == "EX-CH05-S11-OPT02", "D10 recorded: invitation opens 'We kept a place for your work.'")
	if scene_id == "EX-CH05-S02":
		var moment: Dictionary = mission.record_moment("CH05-HATCH-PAUSE")
		_check(bool(moment.get("accepted", false)), "CH05-HATCH-PAUSE moment recorded at the annex hatch")
		_check((director.snapshot().get("story_log", {}) as Dictionary).get("moments", []).has("CH05-HATCH-PAUSE"), "CH05-HATCH-PAUSE is in the story log")
	# Invalid play is refused: a target from another chapter, and a wrong
	# chronology order at S03.
	var wrong_scene: Dictionary = mission.perform("p14_commit_steps_1_2")
	_check(not bool(wrong_scene.get("accepted", false)), scene_id + " refuses a target from another chapter")
	if scene_id == "EX-CH05-S03":
		var wrong_order: Dictionary = mission.perform("p09_commit_sequence", {"order": ["boarding", "evacuation_order", "relay_fault", "seedling_chart"], "conclusion": "ALL_FOUR_RETURNED"})
		_check(not bool(wrong_order.get("accepted", false)), "S03 refuses a chronology in the wrong timestamp order")
	# Pause / resume through the route dispatcher.
	_check(bool(route.pause("mission_test").get("accepted", false)), scene_id + " pauses")
	_check(bool(route.resume().get("accepted", false)), scene_id + " resumes")
	# Physical play: every target commits, then the gate is ready.
	for target in route.targets_for_current_scene():
		var payload: Dictionary = (target.get("payload_defaults", {}) as Dictionary).duplicate(true) if target.get("payload_defaults", {}) is Dictionary else {}
		# The catalog no longer pre-fills puzzle answers (Ramim: Ch4/6/8
		# player decides in the panel; M3-5P/M3-7P: Ch5/7 answers live in
		# the puzzle data files). Supply them the way the extended route
		# walk does: puzzle data first, then the Chapter 4/6/8 witnesses.
		if payload.is_empty():
			payload = PuzzleData.gate_payload(String(target.get("puzzle_action", "")))
		payload = Witness3.payload(String(target.get("target_id", "")), director.snapshot(), payload)
		payload = Witness4.payload(String(target.get("target_id", "")), director.snapshot(), payload)
		payload = Witness6.payload(String(target.get("target_id", "")), director.snapshot(), payload)
		payload = Witness.payload(String(target.get("target_id", "")), director.snapshot(), payload)
		var before_state: Dictionary = {}
		var before_route: Dictionary = {}
		if scene_id == "EX-CH05-S08" and String(target.get("target_id", "")) == "p10_clean_panel":
			before_state = JSON.parse_string(JSON.stringify(director.snapshot()))
			before_route = JSON.parse_string(JSON.stringify(route.snapshot()))
		var result: Dictionary = mission.perform(String(target.get("target_id", "")), payload)
		if not bool(result.get("accepted", false)):
			print("CH05 DETAIL ", scene_id, " / ", target.get("target_id", ""), " -> ", result.get("reason", ""), " trace=", result.get("trace", {}))
		_check(bool(result.get("accepted", false)), scene_id + " commits " + String(target.get("target_id", "")))
		if not before_state.is_empty():
			_check_retry(route, director, before_state, before_route, scene_id)
	_check(bool(route.gate_status().get("ready", false)), scene_id + " physical gate is ready")
	if scene_id == "EX-CH05-S11":
		var at_s11: Dictionary = director.snapshot()
		_check(is_equal_approx(float((at_s11.get("resources", {}) as Dictionary).get("E", -1)), 16.0) and is_equal_approx(float((at_s11.get("resources", {}) as Dictionary).get("A", -1)), 4.25) and is_equal_approx(float((at_s11.get("resources", {}) as Dictionary).get("H", -1)), 6.0) and is_equal_approx(float((at_s11.get("resources", {}) as Dictionary).get("C", -1)), 8.0) and is_equal_approx(float((at_s11.get("resources", {}) as Dictionary).get("R", -1)), 13.5), "EX-CH05-S11 witness ends E16, A4.25, H6, C8, R13.5")
	var moved: Dictionary = mission.advance_scene()
	if scene_id == "EX-CH05-S12":
		_check(bool(moved.get("chapter_complete", false)), "EX-CH05-S12 closes the Chapter 5 boundary")
	else:
		_check(bool(moved.get("accepted", false)), scene_id + " advances in canonical order")
	# A recorded story choice locks once its scene exit has passed.
	if scene_id == "EX-CH05-S05":
		var locked: Dictionary = mission.confirm_decision(scene_id, "EX-CH05-S05-OPT02")
		_check(not bool(locked.get("accepted", false)), "D9 locks after the EX-CH05-S05 exit")

func _check_retry(route: RefCounted, director: RefCounted, before_state: Dictionary, before_route: Dictionary, scene_id: String) -> void:
	var copy_director := DirectorScript.new()
	copy_director.restore_snapshot(JSON.parse_string(JSON.stringify(director.snapshot())))
	var copy := ExtendedRouteScript.new(copy_director)
	_check(bool(copy.restore(JSON.parse_string(JSON.stringify(route.snapshot()))).get("accepted", false)), "B05 Chapter 5 retry checkpoint survives disk-shaped JSON at " + scene_id)
	var retried: Dictionary = copy.retry()
	var restored_local: Dictionary = JSON.parse_string(JSON.stringify(copy.snapshot()))
	var restored_state: Dictionary = JSON.parse_string(JSON.stringify(copy_director.snapshot()))
	_check(bool(retried.get("accepted", false)) and restored_local.ledger == before_route.ledger and restored_local.world == before_route.world and restored_local.scene_flags == before_route.scene_flags and restored_state.resources == before_state.resources and restored_state.receipts == before_state.receipts and restored_state.plants == before_state.plants and restored_state.inventories == before_state.inventories and restored_state.campaign_ledgers == before_state.campaign_ledgers and restored_state.scenario_datetime == before_state.scenario_datetime, "B05 retry restores the complete pre-operation checkpoint at " + scene_id)

func _verify_chapter_end(route: RefCounted, director: RefCounted, mission: RefCounted) -> void:
	var state: Dictionary = director.snapshot()
	_check(String(state.get("scenario_datetime", "")).begins_with("2046-12-15"), "Chapter 5 ends on 15 December 2046")
	var cotton: Dictionary = {}
	for plant in state.get("plants", []):
		if plant is Dictionary and String(plant.get("individual_id", "")) == "COTTON-01":
			cotton = plant
	_check(not cotton.is_empty() and String(cotton.get("planted_at", "")).begins_with("2046-12-15") and String(cotton.get("stage", "")) == "seed" and String(cotton.get("enclosure", "")) == "pressurised_reference_bay", "cotton is physically planted on December 15 in pressure")
	_check(int((state.get("inventories", {}) as Dictionary).get("vault12", {}).get("stored", -1)) == 11 and int((state.get("inventories", {}) as Dictionary).get("cotton_planted", -1)) == 1 and int((state.get("inventories", {}) as Dictionary).get("reserve30", -1)) == 30, "cotton uses one vault specimen, with eleven stored and founder thirty separate")
	var status: Dictionary = mission.chapter_status()
	_check(bool(status.get("complete", false)) and (status.get("completed_scene_ids", []) as Array).size() == 12, "chapter status lists all twelve Chapter 5 scenes complete")
	# Earned upgrade choice: applied once, then locked.
	_check(not bool(mission.choose_chapter_upgrade("storm_early_warning").get("accepted", false)), "Chapter 5 upgrade rejects an option from another chapter")
	var chosen: Dictionary = mission.choose_chapter_upgrade("dust_shield")
	_check(bool(chosen.get("accepted", false)) and String(chosen.get("upgrade_label", "")) == "Dust Shield", "Chapter 5 upgrade choice applies Dust Shield once")
	_check(String((director.snapshot().get("upgrades", {}) as Dictionary).get("choices", {}).get("5", "")) == "dust_shield" and int((director.snapshot().get("upgrades", {}) as Dictionary).get("acquisition_chapter", {}).get("5", -1)) == 5, "Dust Shield is recorded as acquired in Chapter 5")
	_check(not bool(mission.choose_chapter_upgrade("whipple_bumper").get("accepted", false)), "Chapter 5 upgrade cannot be chosen twice")
	# Route snapshot / restore round-trip at the chapter end.
	var snapshot: Dictionary = route.snapshot()
	var restored := ExtendedRouteScript.new(director)
	_check(bool(restored.restore(JSON.parse_string(JSON.stringify(snapshot))).get("accepted", false)), "Chapter 5 route restores at the chapter end")
	_check(restored.current_scene_id() == "EX-CH05-S12" and restored.completed_scene_ids().size() == 36, "restored route remains at EX-CH05-S12 with 36 completed scenes")
	# Mission decision state round-trips through its own snapshot.
	var mission_snapshot: Dictionary = mission.snapshot()
	var mission_copy = MissionScript.new("EX-M0504", route)
	_check(bool(mission_copy.restore(JSON.parse_string(JSON.stringify(mission_snapshot))).get("accepted", false)), "Chapter 5 mission decision state restores")
	_check(String(mission_copy.decision_outcome("EX-CH05-S12").get("mission_outcome", "")) == String(mission.decision_outcome("EX-CH05-S12").get("mission_outcome", "")), "restored mission keeps its S12 decision outcome")

func _check_messages() -> void:
	var file := FileAccess.open("res://resources/campaign/content/messages/ch05.json", FileAccess.READ)
	_check(file != null, "Chapter 5 message file exists")
	if file == null:
		return
	var parsed: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	var joins := {}
	for message in parsed.get("messages", []):
		var join := String(message.get("join", ""))
		if join.is_empty():
			continue
		joins[join] = int(joins.get(join, 0)) + 1
	# The CH04→CH05 chapter join lives in ch04.json; the eleven scene joins
	# and the CH05→CH06 join live here.
	for join in GateCatalog.bridge_joins():
		var label := String(join.get("join", ""))
		if String(join.get("from", "")) == "EX-CH04-S12":
			continue
		_check(int(joins.get(label, 0)) >= 2, "Chapter 5 join " + label + " carries at least 2 messages (25 §5)")
	# 25 §5: "Noor" and "Rahman" never appear before EX-CH05-S10. Messages
	# unlocked on the pre-reveal joins (through S09→S10) must not name her.
	var pre_reveal := ["CH05 S01→S02", "CH05 S02→S03", "CH05 S03→S04", "CH05 S04→S05", "CH05 S05→S06", "CH05 S06→S07", "CH05 S07→S08", "CH05 S08→S09", "CH05 S09→S10"]
	var noor_early := false
	for message in parsed.get("messages", []):
		if pre_reveal.has(String(message.get("join", ""))) and (String(message.get("body", "")).contains("Noor") or String(message.get("body", "")).contains("Rahman")):
			noor_early = true
	_check(not noor_early, "No pre-reveal Chapter 5 message names Noor (25 §5)")

func _check_gate_map_json() -> void:
	var file := FileAccess.open("res://resources/campaign/gates/ch05_gates.json", FileAccess.READ)
	_check(file != null, "Chapter 5 published gate map exists")
	if file == null:
		return
	var parsed: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	var gates: Array = parsed.get("gates", [])
	_check(gates.size() == 12, "published Chapter 5 gate map has twelve gates")
	var runtime := GateCatalog.gate_map()
	for index in range(gates.size()):
		var published: Dictionary = gates[index]
		var live: Dictionary = runtime[index]
		_check(String(published.get("scene_id", "")) == String(live.get("scene_id", "")) and String(published.get("predicate_id", "")) == String(live.get("predicate_id", "")) and (published.get("required_physical", []) as Array) == (live.get("required_physical", []) as Array) and String(published.get("decision_choice_id", "")) == String(live.get("decision_choice_id", "")), "published gate map matches the runtime catalog at " + String(published.get("scene_id", "")))
