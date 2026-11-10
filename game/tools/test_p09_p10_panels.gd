## P-09 / P-10 interactive panels (M3-5P): the data files parse and agree
## with 08/22/24, the gate catalog no longer pre-fills these two puzzles,
## the models accept correct play and reject wrong and boundary inputs with
## the contradiction named, the ledger agrees with the models, and both
## panels drive a full open / Try it / Lock in / observed-result flow.
extends SceneTree

const GateCatalog = preload("res://scripts/missions/extended_gate_catalog.gd")
const PuzzleData = preload("res://scripts/puzzles/puzzle_data.gd")
const P09Script = preload("res://scripts/puzzles/p09_departure_reconstruction.gd")
const P10Script = preload("res://scripts/puzzles/p10_flashes_signature.gd")
const LedgerScript = preload("res://scripts/puzzles/extended_puzzle_ledger.gd")
const P09PanelScene: PackedScene = preload("res://scenes/ui/puzzle_p09_panel.tscn")
const P10PanelScene: PackedScene = preload("res://scenes/ui/puzzle_p10_panel.tscn")
const P09_PATH := "res://resources/campaign/content/p09_departure_reconstruction.json"
const P10_PATH := "res://resources/campaign/content/p10_flashes_signature.json"
const CATALOG_PATH := "res://resources/campaign/content/campaign_catalog.json"
const CARDS_PATH := "res://resources/campaign/content/mission_data_cards.json"
const SOURCES_PATH := "res://resources/data/nasa/puzzle_sources.json"
const DESIGN_PATH := "res://../game-design/08_PUZZLE_DESIGNS.md"

var checks := 0
var failures := 0
var lines := {}
var design := ""
var _captured: Dictionary = {}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for line in _json(CATALOG_PATH).get("dialogue", []):
		lines[String(line.id)] = String(line.text)
	design = FileAccess.get_file_as_string(ProjectSettings.globalize_path(DESIGN_PATH))
	_check(design.contains("## P-09") and design.contains("## P-10"), "08 puzzle design is readable")
	var p09 := _json(P09_PATH)
	var p10 := _json(P10_PATH)
	_common(p09)
	_common(p10)
	_p09(p09)
	_p10(p10)
	_model_p09()
	_model_p10()
	_ledger_agreement()
	root.size = Vector2i(1280, 720)
	await process_frame
	await _panel_p09()
	await _panel_p10()
	print("P09 P10 PANELS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _common(data: Dictionary) -> void:
	var puzzle := String(data.get("puzzle_id", ""))
	_check(int(data.get("schema_version", 0)) == 1, puzzle + " schema_version 1")
	var allowed: Array = _json(SOURCES_PATH).puzzles.get(puzzle, []).duplicate()
	var cards: Dictionary = _json(CARDS_PATH).missions
	for scene in data.scenes:
		allowed.append_array(cards.get(scene.mission_id, {}).get("source_ids", []))
	for id in data.source_ids:
		_check(allowed.has(id) and FileAccess.file_exists("res://resources/data/nasa/%s.json" % id), "%s source %s is registered" % [puzzle, id])
	var scene_ids := []
	for scene in data.scenes:
		var gate := GateCatalog.gate(scene.scene_id)
		_check(not gate.is_empty() and gate.mission_id == scene.mission_id and gate.room_id == scene.room_id, "%s scene %s matches gate catalog" % [puzzle, scene.scene_id])
		scene_ids.append(scene.scene_id)
	for stage in ["learn", "apply", "twist"]:
		var block: Dictionary = data.stages.get(stage, {})
		_check(not block.is_empty() and not String(block.get("goal", "")).is_empty(), "%s has %s stage" % [puzzle, stage])
		for id in block.get("scenes", []):
			_check(scene_ids.has(id), "%s %s scene %s listed" % [puzzle, stage, id])
	var clue_ids := []
	for clue in data.clues:
		clue_ids.append(clue.id)
		_check(scene_ids.has(clue.scene_id), "%s clue %s scene" % [puzzle, clue.id])
		match String(clue.kind):
			"line": _check(lines.get(clue.get("line_id", ""), "") == clue.text, "%s clue %s quotes catalog line" % [puzzle, clue.id])
			"data_card": _check(data.source_ids.has(clue.get("source_id", "")), "%s clue %s cites a listed source" % [puzzle, clue.id])
			"object": _check(not String(clue.text).is_empty(), "%s clue %s has text" % [puzzle, clue.id])
			_: _check(false, "%s clue %s kind" % [puzzle, clue.id])
	for step in data.investigation:
		var targets := []
		for target in GateCatalog.targets_for_scene(step.scene_id):
			targets.append(target.target_id)
		_check(targets.has(step.target_id), "%s investigation target %s exists" % [puzzle, step.target_id])
		for id in step.clue_ids:
			_check(clue_ids.has(id), "%s investigation clue %s exists" % [puzzle, step.clue_ids])
		if step.has("choice_id"):
			_check(data.choices.has(step.choice_id), "%s choice %s exists" % [puzzle, step.choice_id])
	for choice in data.choices.values():
		if not choice is Dictionary or not choice.has("options"):
			continue
		var right := 0
		for option in choice.options:
			_check(not String(option.get("feedback", "")).is_empty() or bool(option.correct), "%s option %s has feedback" % [puzzle, option.value])
			right += 1 if bool(option.correct) else 0
		_check(right >= 1, "%s choice has a correct option" % puzzle)
	for tier in data.hints.values():
		_check(tier.size() == 3, puzzle + " hints have three tiers")
	var raw := JSON.stringify(data)
	var bangla := false
	for i in raw.length():
		bangla = bangla or (raw.unicode_at(i) >= 0x0980 and raw.unicode_at(i) <= 0x09FF)
	_check(not bangla, puzzle + " has no Bangla script")

func _p09(data: Dictionary) -> void:
	_check(data.expected.order == P09Script.expected_order(), "P-09 expected order matches the script")
	_check(String(data.expected.conclusion) == P09Script.expected_conclusion(), "P-09 expected conclusion matches the script")
	_check(data.gate_payloads["p09_commit_sequence"] == {"order": data.expected.order, "conclusion": data.expected.conclusion}, "P-09 gate payload is the expected answer")
	var has_defaults := false
	for target in GateCatalog.targets_for_scene("EX-CH05-S03"):
		if target.get("puzzle_action", "") == "p09_commit_sequence":
			has_defaults = not (target.get("payload_defaults", {}) as Dictionary).is_empty()
	_check(not has_defaults, "P-09 commit no longer comes pre-filled from the catalog")
	_check(PuzzleData.gate_payload("p09_commit_sequence") == data.gate_payloads["p09_commit_sequence"], "P-09 data payload is the route-walk payload")
	for stamp in ["Apr 3", "Apr 4 12:00", "12:10", "12:40"]:
		_check(design.contains(stamp), "08 P-09 states " + stamp)
	for hint in data.hints.sequence:
		_check(design.contains(hint), "P-09 hint is 08 text: " + hint)
	_check(int(data.numbers.crew_departed) == 4 and int(data.numbers.crew_boarded) == 4, "P-09 crew counts are four and four")
	_check(is_equal_approx(float(data.numbers.air_per_shift_five), 1.25) and is_equal_approx(float(data.numbers.food_per_shift_five), 1.5), "P-09 five-person rates are 1.25 air and 1.5 food")
	_check(data.choices.chronology.correct_order == data.expected.order, "P-09 chronology choice order is the expected order")

func _p10(data: Dictionary) -> void:
	_check(data.candidates.size() == 10, "P-10 has ten candidates")
	_check(data.candidates.filter(func(c): return bool(c.genuine)).size() == 8, "P-10 has eight genuine flashes")
	_check(data.candidates.filter(func(c): return not bool(c.genuine)).size() == 2, "P-10 has two persistent artifacts")
	var expected: Dictionary = data.expected
	_check(int(expected.get("artifacts_rejected", -1)) == 2 and int(expected.get("genuine_min", -1)) == 6 and int(expected.get("genuine_total", -1)) == 8 and String(expected.get("identity", "")) == "Dr. Noor Rahman", "P-10 expected values match the design")
	var gate: Dictionary = data.gate_payloads["p10_verify_flashes"]
	_check(int(gate.get("genuine", -1)) == 6 and int(gate.get("artifacts_rejected", -1)) == 2, "P-10 gate payload is six verified and both rejected")
	var has_defaults := false
	for target in GateCatalog.targets_for_scene("EX-CH05-S07"):
		if target.get("puzzle_action", "") == "p10_verify_flashes":
			has_defaults = not (target.get("payload_defaults", {}) as Dictionary).is_empty()
	_check(not has_defaults, "P-10 verify no longer comes pre-filled from the catalog")
	_check(PuzzleData.gate_payload("p10_verify_flashes") == data.gate_payloads["p10_verify_flashes"], "P-10 data payload is the route-walk payload")
	for hint in data.hints.observation:
		_check(design.contains(hint), "P-10 hint is 08 text: " + hint)
	var n: Dictionary = data.numbers
	_check(int(n.entry.E) == 14 and int(n.entry.A) == 8 and int(n.entry.H) == 6 and int(n.entry.C) == 8 and int(n.entry.R) == 18, "P-10 entry matches 08")
	_check(is_equal_approx(float(n.witness.E), 16) and is_equal_approx(float(n.witness.A), 4.25) and is_equal_approx(float(n.witness.R), 13.5), "P-10 witness is E16 A4.25 R13.5")
	var profile: Dictionary = P10Script.profile()
	_check(not profile.is_empty(), "P-10 profile loads")
	_check(int(profile.resources.E) == int(n.entry.E) and int(profile.resources.A) == int(n.entry.A), "P-10 profile entry matches data")
	_check(int(profile.phases) == 3 and is_equal_approx(float(profile.daylight_energy), 8) and is_equal_approx(float(profile.dust_energy), 6), "P-10 profile phases and income match 08")

func _model_p09() -> void:
	var model := P09Script.new()
	_check(not model.preview_commit().accepted, "P-09 empty board cannot commit")
	_check(not model.place_card("not_a_card").accepted, "P-09 unknown card rejected")
	_check(not model.match_signature("FER", "gardener").accepted, "P-09 wrong signature match rejected")
	_check(not model.verify_roster(4).accepted, "P-09 four-person forecast rejected")
	var forecast: Dictionary = model.forecast(4)
	_check(is_equal_approx(float(forecast.get("omitted_air_per_shift", 0)), 0.25) and is_equal_approx(float(forecast.get("omitted_food_per_shift", 0)), 0.3), "P-09 four-person forecast shows the omitted demand")
	_check(model.verify_roster(5).accepted, "P-09 five-person roster accepted")
	_check(model.match_signature("FER", "ferreira").accepted and model.match_signature("N.R.", "gardener").accepted, "P-09 signatures match")
	_check(not model.select_conclusion("GARDENER_ABANDONED").accepted, "P-09 abandoned-gardener conclusion names the boarding contradiction")
	_check(not model.select_conclusion("NAME_THE_GARDENER").accepted, "P-09 gardener name guess refused")
	model.place_card("relay_fault")
	model.place_card("seedling_chart")
	model.place_card("evacuation_order")
	model.place_card("boarding")
	_check(not model.preview_commit().accepted, "P-09 swapped first two cards rejected")
	model.remove_card("relay_fault")
	model.place_card("relay_fault")
	_check(not model.preview_commit().accepted, "P-09 moved card still out of order until fixed")
	model.reset()
	for card in ["seedling_chart", "relay_fault", "evacuation_order", "boarding"]:
		model.place_card(card)
	model.verify_roster(5)
	model.match_signature("FER", "ferreira")
	model.match_signature("N.R.", "gardener")
	model.select_conclusion("ALL_FOUR_RETURNED")
	var preview := model.preview_commit()
	_check(preview.accepted and preview.payload == model.gate_payload(), "P-09 correct board predicts the gate payload")
	_check(not model.preview_action("p09_commit_sequence", {"order": ["boarding"], "conclusion": "ALL_FOUR_RETURNED"}).accepted, "P-09 wrong order payload rejected by the action check")
	_check(model.preview_action("p09_commit_sequence", model.gate_payload()).accepted, "P-09 gate payload passes the action check")
	var done := model.commit_sequence()
	_check(done.accepted and done.payload == model.gate_payload(), "P-09 correct board commits once")
	_check(bool(model.commit_sequence().get("duplicate", false)), "P-09 duplicate commit returns the receipt")
	_check(bool(model.flags().get("zero_all_returned", false)) and bool(model.flags().get("ferreira_admission_ready", false)), "P-09 flags mark all returned and admission ready")
	var copy := P09Script.new()
	_check(copy.restore(JSON.parse_string(JSON.stringify(model.snapshot()))).accepted and bool(copy.flags().get("p09_complete", false)), "P-09 snapshot restores the committed board")
	_check(not copy.restore({"schema_version": 2}).accepted, "P-09 bad snapshot version rejected")

func _model_p10() -> void:
	var model := P10Script.new()
	_check(not model.preview_action("p10_verify_flashes", {"genuine": 0, "artifacts_rejected": 0}).accepted, "P-10 empty board cannot verify")
	_check(not model.tag_candidate("F11", "flash").accepted, "P-10 unknown candidate rejected")
	model.tag_candidate("F1", "flash")
	model.tag_candidate("A1", "flash")
	_check(int(model.counts().get("false_reports", 0)) == 1, "P-10 artifact tagged flash is a false report")
	_check(not model.verify_flashes().accepted, "P-10 false report blocks verification")
	model.tag_candidate("A1", "artifact")
	for id in ["F2", "F3", "F4", "F5"]:
		model.tag_candidate(id, "flash")
	_check(not model.verify_flashes().accepted, "P-10 five genuine flashes rejected")
	model.tag_candidate("F6", "flash")
	model.tag_candidate("A2", "artifact")
	var six := model.verify_flashes()
	_check(six.accepted and not model.golden(), "P-10 six genuine flashes verify, not Golden")
	_check(not model.commit_action("p10_verify_pressure", {}).accepted, "P-10 pressure before repairs rejected")
	_check(model.commit_action("p10_clean_panel", {"repair": "clean"}).accepted, "P-10 panel cleaning commits")
	_check(model.commit_action("p10_patch_dome_spur", {"repair": "patch"}).accepted, "P-10 dome spur patch commits")
	_check(model.maintenance_passed(), "P-10 maintenance passes after both repairs")
	var pressure := model.commit_action("p10_verify_pressure", {})
	_check(pressure.accepted and int(model.snapshot().get("phases_done", 0)) == 1, "P-10 pressure test samples phase one")
	var resources: Dictionary = model.snapshot().get("resources", {})
	_check(is_equal_approx(float(resources.get("E", 0)), 16) and is_equal_approx(float(resources.get("A", 0)), 6.75) and is_equal_approx(float(resources.get("R", 0)), 16.5), "P-10 phase one reads E16 A6.75 R16.5")
	_check(not model.commit_action("p10_save_report", {}).accepted, "P-10 save report needs the filed claim first")
	_check(not model.match_identity("NOOR_BY_NATIONALITY").accepted, "P-10 nationality inference refused")
	_check(not model.match_identity("Dr. Noor Rahman").accepted, "P-10 identity before the filed report refused")
	_check(model.commit_action("p10_exclude_unsupported_impact_claim", {"claim": "impact_2034_fault", "column": "unsupported"}).accepted, "P-10 unsupported claim files")
	_check(model.commit_action("p10_save_report", {}).accepted, "P-10 report saves after the claim")
	_check(model.match_identity("Dr. Noor Rahman").accepted, "P-10 signed identity matches after the evidence pass")
	_check(model.commit_action("p10_record_consent", {}).accepted, "P-10 consent records")
	_check(model.commit_action("p10_confirm_founder_role", {}).accepted, "P-10 founder role confirms")
	_check(not model.commit_action("p10_send_invitation", {"invitation": "NOPE"}).accepted, "P-10 unknown invitation rejected")
	var sent := model.commit_action("p10_send_invitation", {"invitation": "INVITE_SEE_WHAT_GROWS"})
	_check(sent.accepted and int(model.snapshot().get("phases_done", 0)) == 3, "P-10 invitation sends and samples phase three")
	var end: Dictionary = model.snapshot().get("resources", {})
	_check(is_equal_approx(float(end.get("E", 0)), 16) and is_equal_approx(float(end.get("A", 0)), 4.25) and is_equal_approx(float(end.get("H", 0)), 6) and is_equal_approx(float(end.get("C", 0)), 8) and is_equal_approx(float(end.get("R", 0)), 13.5), "P-10 three phases end at the 08 witness E16 A4.25 H6 C8 R13.5")
	_check(bool(model.flags().get("p10_complete", false)), "P-10 flags mark the puzzle complete")
	var copy := P10Script.new()
	_check(copy.restore(JSON.parse_string(JSON.stringify(model.snapshot()))).accepted and int(copy.snapshot().get("phases_done", 0)) == 3, "P-10 snapshot restores three phases")
	_check(bool(model.commit_action("p10_clean_panel", {"repair": "clean"}).get("duplicate", false)), "P-10 duplicate repair returns the receipt")
	var golden := P10Script.new()
	for id in ["F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8"]:
		golden.tag_candidate(id, "flash")
	for id in ["A1", "A2"]:
		golden.tag_candidate(id, "artifact")
	_check(golden.verify_flashes().accepted and golden.golden(), "P-10 all eight flashes with no false report is Golden")
	var forecast: Dictionary = golden.forecast(false)
	var delayed: Dictionary = golden.forecast(true)
	_check(is_equal_approx(float(forecast.get("E", 0)), 16) and is_equal_approx(float(forecast.get("A", 0)), 4.25) and is_equal_approx(float(forecast.get("R", 0)), 13.5), "P-10 immediate forecast is the witness")
	_check(is_equal_approx(float(delayed.get("A", 0)), 3.25), "P-10 one-phase-late maintenance costs one air")

func _ledger_agreement() -> void:
	var ledger := LedgerScript.new()
	var p09 := P09Script.new()
	_check(ledger.preview("P-09", "p09_commit_sequence", p09.gate_payload()).accepted, "ledger accepts the P-09 gate payload")
	_check(not ledger.preview("P-09", "p09_commit_sequence", {"order": ["boarding"], "conclusion": "ALL_FOUR_RETURNED"}).accepted, "ledger rejects the wrong P-09 order")
	var p10 := P10Script.new()
	_check(ledger.preview("P-10", "p10_verify_flashes", {"genuine": 6, "artifacts_rejected": 2}).accepted, "ledger accepts six verified flashes")
	_check(ledger.preview("P-10", "p10_verify_flashes", {"genuine": 8, "artifacts_rejected": 2}).accepted, "ledger accepts the Golden eight")
	_check(not ledger.preview("P-10", "p10_verify_flashes", {"genuine": 5, "artifacts_rejected": 2}).accepted, "ledger rejects five verified flashes")
	_check(not ledger.preview("P-10", "p10_verify_flashes", {"genuine": 9, "artifacts_rejected": 2}).accepted, "ledger rejects nine claimed flashes")
	_check(not ledger.preview("P-10", "p10_verify_flashes", {"genuine": 6, "artifacts_rejected": 1}).accepted, "ledger rejects one unrejected artifact")
	var committed := ledger.commit("P-09", "p09_commit_sequence", p09.gate_payload())
	_check(committed.accepted and bool(ledger.commit("P-09", "p09_commit_sequence", p09.gate_payload()).get("duplicate", false)), "ledger records the P-09 receipt once")

func _panel_p09() -> void:
	_check(ResourceLoader.exists("res://scenes/ui/puzzle_p09_panel.tscn"), "P-09 panel scene exists")
	var model := P09Script.new()
	var panel = P09PanelScene.instantiate()
	root.add_child(panel)
	await process_frame
	_check(panel.open(model, "p09_commit_sequence"), "P-09 panel opens")
	_press(panel, "Conclusion_GARDENER_ABANDONED")
	_check(String((panel.find_child("PuzzleNotice", true, false) as Label).text).contains("boarding list contradicts"), "P-09 panel shows the boarding contradiction for the abandoned conclusion")
	_check(String(model.snapshot().get("conclusion", "")) == "", "P-09 panel wrong conclusion changes nothing")
	_press(panel, "Place_relay_fault")
	_press(panel, "Place_seedling_chart")
	_press(panel, "Place_evacuation_order")
	_press(panel, "Place_boarding")
	_check(not panel.preview().accepted, "P-09 panel swapped order cannot predict")
	_press(panel, "UndoChoices")
	_check((model.snapshot().get("placed", []) as Array).is_empty(), "P-09 panel undo clears the board")
	for id in ["seedling_chart", "relay_fault", "evacuation_order", "boarding"]:
		_press(panel, "Place_" + id)
	_press(panel, "Sign_FER")
	_press(panel, "Sign_NR")
	_press(panel, "Roster_4")
	_check(String((panel.find_child("PuzzleNotice", true, false) as Label).text).contains("old card counted four"), "P-09 panel shows the omitted demand for four people")
	_press(panel, "Roster_5")
	_press(panel, "Conclusion_ALL_FOUR_RETURNED")
	_check(panel.preview().accepted, "P-09 panel correct board predicts")
	_check(panel.request_commit().accepted, "P-09 panel lock-in opens confirmation")
	panel.cancel_confirm()
	_check(panel.request_commit().accepted, "P-09 panel lock-in recovers after backing out")
	_captured = {}
	panel.commit_requested.connect(func(target: String, payload: Dictionary): _captured = {"target": target, "payload": payload})
	_check(panel.confirm_commit().accepted, "P-09 panel confirmation dispatches")
	_check(_captured.get("target", "") == "p09_commit_sequence" and _captured.get("payload", {}) == model.gate_payload(), "P-09 panel emits the gate payload")
	_check(not panel.is_open(), "P-09 panel closes on confirmation like P-01")
	var result: Dictionary = model.commit_action("p09_commit_sequence", _captured.get("payload", {}))
	panel.open(model, "p09_commit_sequence")
	panel.committed(result)
	_check(panel.is_open() and String((panel.find_child("PuzzleNotice", true, false) as Label).text).contains("All four returned"), "P-09 panel shows the observed result after the route commits")
	_check(not panel.confirm_commit().accepted, "P-09 panel duplicate confirmation never submits twice")
	panel.discard()
	var fresh := P09Script.new()
	panel.open(fresh, "p09_commit_sequence")
	_press(panel, "Place_seedling_chart")
	panel.request_close()
	_check(panel.is_open(), "P-09 panel dirty leave asks before discarding")
	panel.discard()
	_check(not panel.is_open(), "P-09 panel discard closes")
	panel.open(fresh, "p09_commit_sequence")
	panel.reveal_hint()
	_check(String((panel.find_child("PuzzleNotice", true, false) as Label).text).begins_with("Hint 1 of 3: Use the timestamps."), "P-09 panel hint one is the 08 H1")
	panel.reveal_hint()
	_check(String((panel.find_child("PuzzleNotice", true, false) as Label).text).begins_with("Hint 2 of 3: Boarding happened"), "P-09 panel hint two is the 08 H2")
	panel.discard()
	panel.free()
	await process_frame

func _panel_p10() -> void:
	_check(ResourceLoader.exists("res://scenes/ui/puzzle_p10_panel.tscn"), "P-10 panel scene exists")
	var model := P10Script.new()
	var panel = P10PanelScene.instantiate()
	root.add_child(panel)
	await process_frame
	_check(panel.open(model, "p10_verify_flashes"), "P-10 panel opens for verification")
	_press(panel, "TagFlash_F1")
	_press(panel, "TagFlash_A1")
	_check(String((panel.find_child("PuzzleNotice", true, false) as Label).text).contains("same detector pixel"), "P-10 panel names the fixed-pixel contradiction for a mistag")
	_check(not panel.preview().accepted, "P-10 panel false report cannot predict")
	_press(panel, "TagArtifact_A1")
	for id in ["F2", "F3", "F4", "F5", "F6"]:
		_press(panel, "TagFlash_" + id)
	_press(panel, "TagArtifact_A2")
	_check(panel.preview().accepted, "P-10 panel six flashes predict")
	_check(panel.request_commit().accepted, "P-10 panel lock-in opens confirmation")
	_captured = {}
	panel.commit_requested.connect(func(target: String, payload: Dictionary): _captured = {"target": target, "payload": payload})
	_check(panel.confirm_commit().accepted, "P-10 panel confirmation dispatches")
	_check(_captured.get("target", "") == "p10_verify_flashes" and _captured.get("payload", {}) == {"genuine": 6, "artifacts_rejected": 2}, "P-10 panel emits six verified and both rejected")
	var result: Dictionary = model.commit_action("p10_verify_flashes", _captured.get("payload", {}))
	panel.open(model, "p10_verify_flashes")
	panel.committed(result)
	_check(panel.is_open() and String((panel.find_child("PuzzleNotice", true, false) as Label).text).contains("Six genuine flashes"), "P-10 panel shows the observed verification")
	panel.discard()
	var repairs := P10Script.new()
	var repair_panel = P10PanelScene.instantiate()
	root.add_child(repair_panel)
	await process_frame
	_check(repair_panel.open(repairs, "p10_clean_panel"), "P-10 panel opens for the panel repair")
	_check(not repair_panel.preview().accepted, "P-10 panel repair needs a choice first")
	_press(repair_panel, "Repair_clean")
	_check(repair_panel.preview().accepted, "P-10 panel cleaning choice predicts")
	_captured = {}
	repair_panel.commit_requested.connect(func(target: String, payload: Dictionary): _captured = {"target": target, "payload": payload})
	repair_panel.request_commit()
	_check(repair_panel.confirm_commit().accepted, "P-10 panel repair confirmation dispatches")
	_check(_captured.get("payload", {}) == {"repair": "clean"}, "P-10 panel emits the cleaning choice")
	_check(repairs.commit_action("p10_clean_panel", _captured.get("payload", {})).accepted and bool(repairs.snapshot().get("cleaned", false)), "P-10 panel cleaning commits through the model")
	repair_panel.discard()
	repair_panel.free()
	panel.free()
	await process_frame

func _press(panel: Control, button_name: String) -> void:
	var button := panel.find_child(button_name, true, false) as Button
	_check(button != null, "panel has button " + button_name)
	if button != null:
		button.pressed.emit()

func _json(path: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	_check(parsed is Dictionary, "parses " + path)
	return parsed if parsed is Dictionary else {}

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL " + label)
