## Godot --headless --path game --script res://tools/test_ch07_missions.gd
## Chapter 7 missions EX-M0701..EX-M0704 (M3-7M): physical play, crew and
## retry. Drives the shared extended route from Chapter 3 through Chapter 7,
## exercising the Chapter7Mission layer at every scene: canon dialogue,
## training decisions (22 §9.1–§9.4) with revise-and-retry, bridge joins
## (24 §2.9), retry checkpoints, chapter boundaries, the relay-parts-kit /
## long-range-battery upgrade choice, and the M3-64 report-card seam.
## Manual testing / screenshots are deferred by Judy's decision; this suite
## is the acceptance evidence.
extends SceneTree

const Witness3 = preload("res://tools/support/chapter3_witness.gd")
const Witness2 = preload("res://tools/support/chapter2_witness.gd")
const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const Chapter2RouteScript = preload("res://scripts/missions/chapter2_route.gd")
const Chapter2GateCatalog = preload("res://scripts/missions/chapter2_gate_catalog.gd")
const ExtendedRouteScript = preload("res://scripts/missions/extended_campaign_route.gd")
const GateCatalog = preload("res://scripts/missions/chapter7_gate_catalog.gd")
const MissionScript = preload("res://scripts/missions/chapter7_mission.gd")
const RegistryScript = preload("res://scripts/missions/mission_registry.gd")
const PuzzleData = preload("res://scripts/puzzles/puzzle_data.gd")
const Witness4 = preload("res://tools/support/chapter4_witness.gd")
const Witness6 = preload("res://tools/support/chapter6_witness.gd")
const Witness = preload("res://tools/support/chapter8_witness.gd")

var checks := 0
var failures := 0

# Canon dialogue (execution/MISSION_EX_M0701..M0704.md): line id -> speaker, text.
const EXPECTED_DIALOGUE := {
	"EX-CH07-S01-L01": ["Rafi", "New observations. Everyone needs them."],
	"EX-CH07-S01-L02": ["Rao", "Historical source received and labelled."],
	"EX-CH07-S01-L03": ["Ferreira", "Your plan, cadets. I retain command responsibility."],
	"EX-CH07-S01-L04": ["Kai", "Read every observation before we set anything."],
	"EX-CH07-S02-L01": ["Amara", "April's card counted four."],
	"EX-CH07-S02-L02": ["Ferreira", "Today it must count me."],
	"EX-CH07-S02-L03": ["Mei", "Plants are not our whole life-support system."],
	"EX-CH07-S02-L04": ["Rafi", "Five names. Five places inside."],
	"EX-CH07-S03-L01": ["Kai", "Four good ideas can still collide."],
	"EX-CH07-S03-L02": ["Mei", "Say when the borrowed water returns."],
	"EX-CH07-S03-L03": ["Amara", "And keep circulation running meanwhile."],
	"EX-CH07-S03-L04": ["Rafi", "One schedule. Every dependency."],
	"EX-CH07-S04-L01": ["Mei", "Fifteen and fifteen. Thirty founders."],
	"EX-CH07-S04-L02": ["Rafi", "Bundles stay through the last exposure."],
	"EX-CH07-S04-L03": ["Amara", "Return after the sample, not before."],
	"EX-CH07-S04-L04": ["Ferreira", "Name the valve, then touch it."],
	"EX-CH07-S05-L01": ["Rafi", "Kai?"],
	"EX-CH07-S05-L02": ["Kai", "Here. Protected branch checked."],
	"EX-CH07-S05-L03": ["Amara", "Atmosphere checked. Mei is here."],
	"EX-CH07-S05-L04": ["Ferreira", "Ferreira here. Fifth position confirmed."],
	"EX-CH07-S06-L01": ["Amara", "Compare the result with the forecast."],
	"EX-CH07-S06-L02": ["Kai", "Protected branch matches."],
	"EX-CH07-S06-L03": ["Mei", "Living garden still on local telemetry."],
	"EX-CH07-S06-L04": ["Rafi", "First wave checked, not merely endured."],
	"EX-CH07-S07-L01": ["Noor", "I'm calling the seeds Alo, light."],
	"EX-CH07-S07-L02": ["Mei", "The name was a hope, not a prediction."],
	"EX-CH07-S07-L03": ["Kai", "Then our report needs more than a good line."],
	"EX-CH07-S07-L04": ["Amara", "It needs the next checked step."],
	"EX-CH07-S08-L01": ["Rafi", "Peak on the chart. Check the shield."],
	"EX-CH07-S08-L02": ["Kai", "No new solar income."],
	"EX-CH07-S08-L03": ["Amara", "Five-person draw still applies."],
	"EX-CH07-S08-L04": ["Mei", "Final exposure first. Then return the water."],
	"EX-CH07-S09-L01": ["Kai", "I can hear Rafi. Earth cannot hear us."],
	"EX-CH07-S09-L02": ["Amara", "Local pass. External path failed."],
	"EX-CH07-S09-L03": ["Ferreira", "Correct isolation was still the right decision."],
	"EX-CH07-S09-L04": ["Rafi", "Two clear readings before outside preparation."],
	"EX-CH07-S10-L01": ["Mei", "The garden needs ordinary days too."],
	"EX-CH07-S10-L02": ["Amara", "Account for the interval, not just the climax."],
	"EX-CH07-S10-L03": ["Kai", "No reply from Earth is in this plan."],
	"EX-CH07-S10-L04": ["Ferreira", "We have local procedures and stores."],
	"EX-CH07-S11-L01": ["Rafi", "A high dish still needs to hear Aurora."],
	"EX-CH07-S11-L02": ["Kai", "Every neighbouring link, not one magic line."],
	"EX-CH07-S11-L03": ["Ferreira", "Check the housing before packing the spare."],
	"EX-CH07-S11-L04": ["Amara", "A bench pass is not field verification."],
	"EX-CH07-S12-L01": ["Ferreira", "Kai and Rafi with me. Mei and Amara hold Aurora."],
	"EX-CH07-S12-L02": ["Amara", "Two at home, then five for the last three hours."],
	"EX-CH07-S12-L03": ["Kai", "Keep the small guide light."],
	"EX-CH07-S12-L04": ["Mei", "It is already in the plan."],
}

# 22 §9 expected decision outcomes per option.
const EXPECTED_OUTCOMES := {
	"EX-CH07-S01": {"EX-CH07-S01-OPT01": "revise", "EX-CH07-S01-OPT02": "supported"},
	"EX-CH07-S02": {"EX-CH07-S02-OPT01": "revise", "EX-CH07-S02-OPT02": "supported"},
	"EX-CH07-S03": {"EX-CH07-S03-OPT01": "revise", "EX-CH07-S03-OPT02": "supported"},
	"EX-CH07-S04": {"EX-CH07-S04-OPT01": "revise", "EX-CH07-S04-OPT02": "supported"},
	"EX-CH07-S05": {"EX-CH07-S05-OPT01": "revise", "EX-CH07-S05-OPT02": "supported"},
	"EX-CH07-S06": {"EX-CH07-S06-OPT01": "revise", "EX-CH07-S06-OPT02": "supported"},
	"EX-CH07-S07": {"EX-CH07-S07-OPT01": "revise", "EX-CH07-S07-OPT02": "supported"},
	"EX-CH07-S08": {"EX-CH07-S08-OPT01": "revise", "EX-CH07-S08-OPT02": "supported"},
	"EX-CH07-S09": {"EX-CH07-S09-OPT01": "revise", "EX-CH07-S09-OPT02": "supported"},
	"EX-CH07-S10": {"EX-CH07-S10-OPT01": "revise", "EX-CH07-S10-OPT02": "supported"},
	"EX-CH07-S11": {"EX-CH07-S11-OPT01": "revise", "EX-CH07-S11-OPT02": "supported"},
	"EX-CH07-S12": {"EX-CH07-S12-OPT01": "revise", "EX-CH07-S12-OPT02": "supported"},
}

const EXPECTED_MINUTES := {"EX-M0701": 25, "EX-M0702": 25, "EX-M0703": 30, "EX-M0704": 25}

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
	var blocked_first := MissionScript.new("EX-M0701", fresh_route)
	_check(not bool(blocked_first.begin().get("accepted", false)) and String(blocked_first.begin().get("required_scene_id", "")) == "EX-CH06-S12", "EX-M0701 cannot begin before EX-CH06-S12")
	var blocked_second := MissionScript.new("EX-M0702", fresh_route)
	_check(not bool(blocked_second.begin().get("accepted", false)) and String(blocked_second.begin().get("required_scene_id", "")) == "EX-CH07-S01", "EX-M0702 cannot begin before EX-M0701")
	# Chapter 2 handoff, then drive Chapters 3–6 on the extended route.
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
	_drive_chapter(route, director, 5)
	_drive_chapter(route, director, 6)
	_check(route.current_scene_id() == "EX-CH07-S01", "route arrives at Chapter 7 entry")
	# Chapter 7, mission by mission, through the mission layer.
	var missions: Array = []
	for mission_id in ["EX-M0701", "EX-M0702", "EX-M0703", "EX-M0704"]:
		var mission = RegistryScript.new().create(mission_id, director, route)
		missions.append(mission)
		_check(bool(mission.begin().get("accepted", false)), mission_id + " begins after its predecessor")
		if mission_id == "EX-M0701":
			_check(bool(mission.chapter_entry().get("accepted", false)) and bool(mission.chapter_entry().get("predecessor_complete", false)), "Chapter 7 entry profile: EX-CH06-S12 complete, 14 February 2047")
		for scene_id in mission.scene_ids():
			_drive_mission_scene(mission, route, director, scene_id)
		_check(String(mission.status().get("status", "")) == "complete", mission_id + " reports complete")
		_check(bool(mission.report_card_payload(mission.scene_ids()[2]).get("decision", {}).has("id")), mission_id + " report payload carries its debrief decision")
		_check(not bool(mission.report_ready(mission.scene_ids()[2]).get("ready", false)) and String(mission.report_ready(mission.scene_ids()[2]).get("reason", "")).contains("M3-64"), mission_id + " rendered Report Card honestly waits on M3-64")
	var last_mission = missions[3]
	_check(bool(last_mission.chapter_complete()), "Chapter 7 reports complete after EX-CH07-S12")
	_verify_chapter_end(route, director, last_mission)
	_check(bool(route.start_at("EX-CH08-S01").get("accepted", false)), "route opens EX-CH08-S01 after the chapter boundary")
	_check_messages()
	_check_gate_map_json()
	print("CHAPTER 7 MISSIONS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)

func _check_catalog() -> void:
	_check(GateCatalog.scene_ids().size() == 12, "Chapter 7 catalog has twelve scenes")
	_check(GateCatalog.mission_ids().size() == 4, "Chapter 7 catalog has four missions")
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
	_check(minutes == GateCatalog.CHAPTER_MINUTES, "Chapter 7 totals 105 first-time minutes")
	_check(GateCatalog.UPGRADE_PAIR == ["relay_parts_kit", "long_range_battery"], "Chapter 7 earned upgrade pair is relay parts kit / long-range battery")
	for scene_id in GateCatalog.scene_ids():
		var gate_data := GateCatalog.gate(scene_id)
		_check(String(gate_data.get("mission_id", "")).begins_with("EX-M07"), scene_id + " belongs to a Chapter 7 mission")
		_check(String(gate_data.get("predicate_id", "")) == "PRED-%s-EXIT" % scene_id, scene_id + " predicate id is canonical")
		_check(not (gate_data.get("required_physical", []) as Array).is_empty(), scene_id + " has physical requirements")
		_check((gate_data.get("player_actions", []) as Array).size() >= 2, scene_id + " lists its required player actions")
		_check(String(gate_data.get("exit_condition", "")).length() > 10, scene_id + " has an exit condition")
		var lines := GateCatalog.dialogue_lines(scene_id)
		_check(lines.size() == 4, scene_id + " has four canon dialogue lines")
		for line in lines:
			var expected: Array = EXPECTED_DIALOGUE.get(String(line.get("id", "")), [])
			_check(not expected.is_empty() and String(line.get("speaker", "")) == String(expected[0]) and String(line.get("text", "")) == String(expected[1]), String(line.get("id", "")) + " canon speaker and text match the mission docs")
		# Origins: Rao is live Earth link, Noor in S07 is a stored recording
		# (no live Noor voice before Chapter 8).
		if scene_id == "EX-CH07-S07":
			_check(String(lines[0].get("origin_label", "")) == "STORED RECORDING", "EX-CH07-S07-L01 is a stored historical recording, not a live link")
		var decision := GateCatalog.training_decision(scene_id)
		_check((decision.get("options", []) as Array).size() == 2, scene_id + " training decision offers two real alternatives")
		_check((decision.get("hints", []) as Array).size() == 3, scene_id + " has three hint tiers")
		_check(not (decision.get("data_cards", []) as Array).is_empty(), scene_id + " names its Data Cards")
		_check(String(decision.get("story_choice", "")).is_empty(), scene_id + " has no story choice of its own (D9/D10 belong to Chapter 5)")
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
		_check(String(time_card.get("not_before", "")).begins_with("2047-"), scene_id + " dated time card is in 2047")
		_check(String(time_card.get("story_time", "")).length() > 5, scene_id + " has a story time card")
	# 24 §2.9 bridge joins: thirteen rows, every Fix row built here.
	var joins := GateCatalog.bridge_joins()
	_check(joins.size() == 13, "Chapter 7 bridge list has thirteen joins")
	for join in joins:
		_check(String(join.get("carries", "")).length() > 5 and String(join.get("kinds", "")).length() > 0, String(join.get("join", "")) + " join names what it carries")
		if String(join.get("status", "")) == "Fix":
			_check(String(join.get("built_by", "")) == "chapter7_gate_catalog" and String(join.get("carried_object", "")).length() > 0, String(join.get("join", "")) + " Fix join is built with a named carried object")
	var hook := GateCatalog.bridge_join("EX-CH06-S12", "EX-CH07-S01")
	_check(String(hook.get("carried_object", "")) == "january_active_region_image", "CH06→CH07 Fix join carries Rafi's pinned January active-region image")
	# Ramim seams name the waiting tasks and the seam left for each.
	var seams := GateCatalog.ramim_seams()
	var seam_tasks: Array = []
	for seam in seams:
		seam_tasks.append(String(seam.get("ramim_task", "")))
		_check(String(seam.get("behaviour", "")).length() > 10 and String(seam.get("seam", "")).length() > 10, "Ramim seam names the waiting behaviour and the seam left")
	_check(seam_tasks.has("M3-64") and seam_tasks.has("M3-61") and seam_tasks.has("M3-62") and seam_tasks.has("M3-65"), "Chapter 7 Ramim seams cover M3-61, M3-62, M3-64 and M3-65")

func _check_registry() -> void:
	var registry = RegistryScript.new()
	for mission_id in ["EX-M0701", "EX-M0702", "EX-M0703", "EX-M0704"]:
		_check(registry.is_implemented(mission_id), mission_id + " is registered as implemented")
		var created = registry.create(mission_id)
		_check(created is Chapter7Mission, mission_id + " creates a Chapter7Mission")
		_check(String(created.status().get("status", "")) == "ready", mission_id + " starts ready")

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
	# Training decision: the revise option is refused with feedback and a
	# retry; the supported option commits.
	var decision: Dictionary = mission.training_decision(scene_id)
	var outcomes: Dictionary = decision.get("outcomes", {})
	var revise_option := ""
	var commit_option := ""
	for option_id in outcomes.keys():
		if String(outcomes[option_id]) == "revise":
			revise_option = String(option_id)
		elif commit_option.is_empty():
			commit_option = String(option_id)
	if not revise_option.is_empty():
		var refused: Dictionary = mission.confirm_decision(scene_id, revise_option)
		_check(not bool(refused.get("accepted", false)) and bool(refused.get("can_retry", false)), scene_id + " revise option is refused with a retry")
		_check(String(refused.get("feedback", "")) == String(GateCatalog.evaluate_option(scene_id, revise_option).get("feedback", "")), scene_id + " revise feedback is the canon consequence")
	var confirmed: Dictionary = mission.confirm_decision(scene_id, commit_option)
	_check(bool(confirmed.get("accepted", false)), scene_id + " commits decision option " + commit_option)
	var outcome: Dictionary = mission.decision_outcome(scene_id)
	_check(String(outcome.get("mission_outcome", "")) == "partial", scene_id + " decision outcome is partial after the corrected first pick")
	# Invalid play is refused: a target from another chapter, and an early
	# drain at S04 (protection must stay through exposure).
	var wrong_scene: Dictionary = mission.perform("p16_install_controller")
	_check(not bool(wrong_scene.get("accepted", false)), scene_id + " refuses a target from another chapter")
	if scene_id == "EX-CH07-S04":
		var early_drain: Dictionary = mission.perform("p13_verify_drain_order", {})
		_check(not bool(early_drain.get("accepted", false)), "S04 refuses the drain-order check before the case is latched and shielding verified")
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
		if scene_id == "EX-CH07-S08" and String(target.get("target_id", "")) == "p14_commit_steps_3_6":
			before_state = JSON.parse_string(JSON.stringify(director.snapshot()))
			before_route = JSON.parse_string(JSON.stringify(route.snapshot()))
		var result: Dictionary = mission.perform(String(target.get("target_id", "")), payload)
		if not bool(result.get("accepted", false)):
			print("CH07 DETAIL ", scene_id, " / ", target.get("target_id", ""), " -> ", result.get("reason", ""), " trace=", result.get("trace", {}))
		_check(bool(result.get("accepted", false)), scene_id + " commits " + String(target.get("target_id", "")))
		if not before_state.is_empty():
			_check_retry(route, director, before_state, before_route, scene_id)
	_check(bool(route.gate_status().get("ready", false)), scene_id + " physical gate is ready")
	if scene_id == "EX-CH07-S08":
		_verify_storm_end(director)
	if scene_id == "EX-CH07-S09":
		_verify_diagnosis(director)
	var moved: Dictionary = mission.advance_scene()
	if scene_id == "EX-CH07-S12":
		_check(bool(moved.get("chapter_complete", false)), "EX-CH07-S12 closes the Chapter 7 boundary")
	else:
		_check(bool(moved.get("accepted", false)), scene_id + " advances in canonical order")

func _verify_storm_end(director: RefCounted) -> void:
	var state: Dictionary = director.snapshot()
	_check(String(state.get("scenario_datetime", "")) == "2047-02-16 01:12 UTC", "six storm steps reach February 16 01:12 exactly")
	var resources: Dictionary = state.get("resources", {})
	_check(is_equal_approx(float(resources.get("E", -1)), 6.0) and is_equal_approx(float(resources.get("A", -1)), 2.5) and is_equal_approx(float(resources.get("H", -1)), 1.0) and is_equal_approx(float(resources.get("C", -1)), 3.0) and is_equal_approx(float(resources.get("R", -1)), 9.0) and is_equal_approx(float(resources.get("Z", -1)), 0.0), "storm witness ends E6, A2.5, H1, C3, R9, Z0")
	var samples: Array = (state.get("campaign_ledgers", {}) as Dictionary).get("puzzles", {}).get("P-14", {}).get("samples", [])
	_check(samples.size() == 6 and int((samples[5] as Dictionary).get("shelter", -1)) == 6 and is_equal_approx(float(((samples[5] as Dictionary).get("after", {}) as Dictionary).get("W", -1)), 2.0) and is_equal_approx(float(((samples[5] as Dictionary).get("before", {}) as Dictionary).get("W", -1)), 4.0), "final drain follows exposure and crates remain installed")
	_check(int((state.get("inventories", {}) as Dictionary).get("reserve30", -1)) == 30, "founder 30 stays protected through the storm")

func _verify_diagnosis(director: RefCounted) -> void:
	var state: Dictionary = director.snapshot()
	var p14: Dictionary = (state.get("campaign_ledgers", {}) as Dictionary).get("puzzles", {}).get("P-14", {})
	_check(String(p14.get("local_network", "")) == "PASS" and String(p14.get("direct_earth_path", "")) == "FAIL" and String(p14.get("external_feedthrough", "")) == "F-EXT", "uplink diagnosis is local PASS, dish FAIL, feedthrough F-EXT")
	var readings: Array = p14.get("clearance_readings", [])
	_check(readings.size() == 2, "two route-clear readings recorded")
	if readings.size() == 2:
		_check(float((readings[1] as Dictionary).get("reading", -1)) < 1.0 and float((readings[0] as Dictionary).get("reading", -1)) < 1.0, "both route readings are below threshold 1")

func _check_retry(route: RefCounted, director: RefCounted, before_state: Dictionary, before_route: Dictionary, scene_id: String) -> void:
	var copy_director := DirectorScript.new()
	copy_director.restore_snapshot(JSON.parse_string(JSON.stringify(director.snapshot())))
	var copy := ExtendedRouteScript.new(copy_director)
	_check(bool(copy.restore(JSON.parse_string(JSON.stringify(route.snapshot()))).get("accepted", false)), "B05 Chapter 7 retry checkpoint survives disk-shaped JSON at " + scene_id)
	var retried: Dictionary = copy.retry()
	var restored_local: Dictionary = JSON.parse_string(JSON.stringify(copy.snapshot()))
	var restored_state: Dictionary = JSON.parse_string(JSON.stringify(copy_director.snapshot()))
	_check(bool(retried.get("accepted", false)) and restored_local.ledger == before_route.ledger and restored_local.world == before_route.world and restored_local.scene_flags == before_route.scene_flags and restored_state.resources == before_state.resources and restored_state.receipts == before_state.receipts and restored_state.plants == before_state.plants and restored_state.inventories == before_state.inventories and restored_state.campaign_ledgers == before_state.campaign_ledgers and restored_state.scenario_datetime == before_state.scenario_datetime, "B05 retry restores the complete pre-operation checkpoint at " + scene_id)

func _verify_chapter_end(route: RefCounted, director: RefCounted, mission: RefCounted) -> void:
	var state: Dictionary = director.snapshot()
	# p14_sign_departure_prep advances the clock to 8 April 00:00 UTC, which is
	# the end of the S12 story window ("7 April to 8 April 00:00").
	_check(String(state.get("scenario_datetime", "")) == "2047-04-08 00:00 UTC", "Chapter 7 ends 8 April 2047 00:00 UTC, departure preparation signed")
	var operations: Dictionary = (state.get("campaign_ledgers", {}) as Dictionary).get("operations", {})
	_check(operations.has("p14_assign_field_team") and operations.has("p14_assign_home_team") and operations.has("p14_sign_departure_prep"), "rover and home teams assigned and departure preparation signed")
	_check(int((state.get("inventories", {}) as Dictionary).get("repeater_spare_batteries", -1)) > 0, "packed repeater spare batteries are in inventory")
	# The rover route itself is entered by the Chapter 8 p15 operations, so at
	# the Chapter 7 end the live route is still the p07 one (48 h). What Chapter 7
	# signs is the departure preparation; the 72 h / 51 h numbers live in the
	# authored p15 journey profile that Chapter 8 enforces via
	# p15_confirm_roundtrip_provisions (24 h out + 3 h repair + 24 h back = 51 h).
	var profile_file := FileAccess.open("res://resources/campaign/profiles/p15_campaign.json", FileAccess.READ)
	var profile: Dictionary = JSON.parse_string(profile_file.get_as_text())
	_check(int(profile.get("rover_provisions", -1)) == 72 and int(profile.get("journey_hours", -1)) == 51 and int(profile.get("rover_out_hours", -1)) + int(profile.get("rover_repair_hours", -1)) + int(profile.get("rover_return_hours", -1)) == 51, "p15 journey profile carries 72 h independent provisions for the 51 h journey (24 out + 3 repair + 24 back)")
	var status: Dictionary = mission.chapter_status()
	_check(bool(status.get("complete", false)) and (status.get("completed_scene_ids", []) as Array).size() == 12, "chapter status lists all twelve Chapter 7 scenes complete")
	# Earned upgrade choice: applied once, then locked.
	_check(not bool(mission.choose_chapter_upgrade("dust_shield").get("accepted", false)), "Chapter 7 upgrade rejects an option from another chapter")
	var chosen: Dictionary = mission.choose_chapter_upgrade("relay_parts_kit")
	_check(bool(chosen.get("accepted", false)) and String(chosen.get("upgrade_label", "")) == "Relay parts kit", "Chapter 7 upgrade choice applies the relay parts kit once")
	_check(String((director.snapshot().get("upgrades", {}) as Dictionary).get("choices", {}).get("7", "")) == "relay_parts_kit" and int((director.snapshot().get("upgrades", {}) as Dictionary).get("acquisition_chapter", {}).get("7", -1)) == 7, "relay parts kit is recorded as acquired in Chapter 7")
	_check(not bool(mission.choose_chapter_upgrade("long_range_battery").get("accepted", false)), "Chapter 7 upgrade cannot be chosen twice")
	# Route snapshot / restore round-trip at the chapter end.
	var snapshot: Dictionary = route.snapshot()
	var restored := ExtendedRouteScript.new(director)
	_check(bool(restored.restore(JSON.parse_string(JSON.stringify(snapshot))).get("accepted", false)), "Chapter 7 route restores at the chapter end")
	_check(restored.current_scene_id() == "EX-CH07-S12" and restored.completed_scene_ids().size() == 60, "restored route remains at EX-CH07-S12 with 60 completed scenes")
	# Mission decision state round-trips through its own snapshot.
	var mission_snapshot: Dictionary = mission.snapshot()
	var mission_copy = MissionScript.new("EX-M0704", route)
	_check(bool(mission_copy.restore(JSON.parse_string(JSON.stringify(mission_snapshot))).get("accepted", false)), "Chapter 7 mission decision state restores")
	_check(String(mission_copy.decision_outcome("EX-CH07-S12").get("mission_outcome", "")) == String(mission.decision_outcome("EX-CH07-S12").get("mission_outcome", "")), "restored mission keeps its S12 decision outcome")

func _check_messages() -> void:
	var file := FileAccess.open("res://resources/campaign/content/messages/ch07.json", FileAccess.READ)
	_check(file != null, "Chapter 7 message file exists")
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
	# The CH06→CH07 chapter join lives in ch06.json; the eleven scene joins
	# and the CH07→CH08 join live here.
	for join in GateCatalog.bridge_joins():
		var label := String(join.get("join", ""))
		if String(join.get("from", "")) == "EX-CH06-S12":
			continue
		_check(int(joins.get(label, 0)) >= 2, "Chapter 7 join " + label + " carries at least 2 messages (25 §5)")

func _check_gate_map_json() -> void:
	var file := FileAccess.open("res://resources/campaign/gates/ch07_gates.json", FileAccess.READ)
	_check(file != null, "Chapter 7 published gate map exists")
	if file == null:
		return
	var parsed: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	var gates: Array = parsed.get("gates", [])
	_check(gates.size() == 12, "published Chapter 7 gate map has twelve gates")
	var runtime := GateCatalog.gate_map()
	for index in range(gates.size()):
		var published: Dictionary = gates[index]
		var live: Dictionary = runtime[index]
		_check(String(published.get("scene_id", "")) == String(live.get("scene_id", "")) and String(published.get("predicate_id", "")) == String(live.get("predicate_id", "")) and (published.get("required_physical", []) as Array) == (live.get("required_physical", []) as Array) and String(published.get("decision_choice_id", "")) == String(live.get("decision_choice_id", "")), "published gate map matches the runtime catalog at " + String(published.get("scene_id", "")))
