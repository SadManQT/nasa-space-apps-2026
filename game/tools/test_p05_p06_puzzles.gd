## Chapter 3 interactive puzzles P-05 (Find the Falling Pressure) and P-06
## (A Harvest With a Future) test suite (M3-3P).
extends SceneTree

const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const RouteScript = preload("res://scripts/missions/extended_campaign_route.gd")
const GateCatalog = preload("res://scripts/missions/extended_gate_catalog.gd")
const LedgerScript = preload("res://scripts/puzzles/extended_puzzle_ledger.gd")
const P05Script = preload("res://scripts/puzzles/p05_falling_pressure.gd")
const P06Script = preload("res://scripts/puzzles/p06_harvest_future.gd")
const PanelScene: PackedScene = preload("res://scenes/ui/scientific_puzzle_panel.tscn")
const CampaignScene: PackedScene = preload("res://scenes/campaign/chapter1_campaign.tscn")

var storage = preload("res://tools/support/isolated_storage.gd").new()
var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_no_prefilled_defaults_for_p05_p06()
	_test_p05_model_and_boundaries()
	_test_p06_model_and_boundaries()
	_test_chapter3_route_witness_and_persistence()
	await _test_scientific_puzzle_panel_ui()
	await _test_campaign_hud_integration()
	print("P05 P06 PUZZLES RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_no_prefilled_defaults_for_p05_p06() -> void:
	var ch3_defaults_empty := true
	for order in range(1, 13):
		var scene_id := "EX-CH03-S%02d" % order
		for target in GateCatalog.targets_for_scene(scene_id):
			var defaults: Dictionary = target.get("payload_defaults", {})
			if not defaults.is_empty():
				ch3_defaults_empty = false
	_check(ch3_defaults_empty, "ExtendedGateCatalog has no pre-filled payload_defaults for any P-05 or P-06 action")

	var p07_targets: Array = GateCatalog.targets_for_scene("EX-CH04-S03")
	_check(not p07_targets.is_empty() and not (p07_targets[0].get("payload_defaults", {}) as Dictionary).is_empty(), "P-07+ defaults remain intact in ExtendedGateCatalog")

	var ledger_src := FileAccess.get_file_as_string("res://scripts/puzzles/extended_puzzle_ledger.gd")
	_check(not ledger_src.contains("!= 82") and not ledger_src.contains("!= 74") and not ledger_src.contains("!= 42"), "P-05 and P-06 numeric answers are moved out of extended_puzzle_ledger.gd into JSON data")

	var director := DirectorScript.new()
	director.new_campaign()
	var route := RouteScript.new(director)
	route.start_at("EX-CH03-S02")
	var rejected_p05: Dictionary = route.perform("p05_read_garden_t0")
	_check(not bool(rejected_p05.get("accepted", false)) and bool(rejected_p05.get("scientific_puzzle", false)), "unplanned P-05 gauge reading refuses to commit without player input")

	route.start_at("EX-CH03-S10")
	var rejected_p06_count: Dictionary = route.perform("p06_count_42")
	var rejected_p06_alloc: Dictionary = route.perform("p06_allocate_12_30")
	_check(not bool(rejected_p06_count.get("accepted", false)) and not bool(rejected_p06_alloc.get("accepted", false)), "unplanned P-06 count and allocation refuse to commit without player input")

func _test_p05_model_and_boundaries() -> void:
	var p05 := P05Script.new()
	_check(p05.payload_for_action("p05_read_garden_t0").is_empty(), "fresh P-05 model has no hidden tap readings")
	_check(not bool(p05.attach_gauge("MAIN", "t0").get("accepted", false)), "cannot read a tap before equipping the mechanical gauge")
	_check(bool(p05.equip_gauge().get("accepted", false)) and bool(p05.identify_three_taps().get("accepted", false)), "equipping mechanical gauge unlocks the three manual taps")
	_check(not bool(p05.attach_gauge("GARDEN", "t10").get("accepted", false)), "cannot take t10 comparison before all three t0 baseline readings")

	# Wrong and boundary manual readings.
	_check(not bool(p05.set_tap_reading("GARDEN", "t0", 81).get("accepted", false)), "boundary wrong reading 81 at GARDEN t0 is rejected")
	_check(not bool(p05.set_tap_reading("GARDEN", "t0", 83).get("accepted", false)), "boundary wrong reading 83 at GARDEN t0 is rejected")
	_check(bool(p05.attach_gauge("MAIN", "t0").get("accepted", false)) and bool(p05.attach_gauge("GARDEN", "t0").get("accepted", false)) and bool(p05.attach_gauge("RETURN", "t0").get("accepted", false)), "t0 baseline readings record 100, 82, 100")
	_check(not bool(p05.set_tap_reading("GARDEN", "t10", 75).get("accepted", false)), "boundary wrong reading 75 at GARDEN t10 is rejected")
	_check(bool(p05.attach_gauge("MAIN", "t10").get("accepted", false)) and bool(p05.attach_gauge("GARDEN", "t10").get("accepted", false)) and bool(p05.attach_gauge("RETURN", "t10").get("accepted", false)), "t10 comparison readings record 100, 74, 100")

	# 2-inspections-per-phase boundary across 6 candidates.
	_check(bool(p05.inspect_candidate("main_tank").get("accepted", false)) and bool(p05.inspect_candidate("habitat_trunk").get("accepted", false)), "phase 1 allows 2 candidate inspections")
	var over_budget: Dictionary = p05.inspect_candidate("garden_feedthrough")
	_check(not bool(over_budget.get("accepted", false)) and String(over_budget.get("reason", "")).contains("2"), "3rd candidate inspection in phase 1 is blocked by the 2-per-phase limit")
	var phase2: Dictionary = p05.advance_phase()
	_check(bool(phase2.get("accepted", false)) and int(phase2.get("phase", 0)) == 2 and bool(phase2.get("aftershock_triggered", false)), "advancing to phase 2 resets per-phase budget and triggers the aftershock")
	_check(bool(p05.inspect_candidate("garden_feedthrough").get("accepted", false)) and bool(p05.inspect_candidate("return_line").get("accepted", false)), "phase 2 allows 2 more candidate inspections")

	# Deduction & wrong-but-reasonable actions.
	_check(not bool(p05.identify_falling_branch("MAIN").get("accepted", false)), "identifying MAIN as falling is rejected because MAIN held 100 -> 100")
	_check(bool(p05.identify_falling_branch("GARDEN").get("accepted", false)), "identifying GARDEN as falling (82 -> 74) is accepted")

	var wrong_main: Dictionary = p05.isolate_branch("MAIN")
	_check(not bool(wrong_main.get("accepted", false)) and bool(wrong_main.get("non_punishing", false)) and String(wrong_main.get("badge", "")).contains("FR-02"), "closing MAIN triggers Protected Reserve Warning FR-02")
	var wrong_hab: Dictionary = p05.select_trade_option("isolate_habitat_trunk")
	_check(not bool(wrong_hab.get("accepted", false)) and String(wrong_hab.get("reason", "")).contains("habitat's air supply too"), "isolating habitat trunk warns that it cuts crew breathing air too")
	var wrong_clamp_early: Dictionary = p05.seat_repair_clamp("GARDEN")
	_check(not bool(wrong_clamp_early.get("accepted", false)) and String(wrong_clamp_early.get("badge", "")).contains("PRESSURISED"), "clamping before isolating GARDEN is rejected")
	var wrong_clamp_branch: Dictionary = p05.seat_repair_clamp("RETURN")
	_check(not bool(wrong_clamp_branch.get("accepted", false)), "clamping RETURN is rejected")

	# Correct isolation, clamp, slow reopen & 5 steady readings.
	_check(bool(p05.isolate_branch("GARDEN").get("accepted", false)) and bool(p05.verify_main_hold().get("accepted", false)), "isolating GARDEN and verifying MAIN 100 / GARDEN 74 hold succeeds")
	_check(bool(p05.seat_repair_clamp("GARDEN").get("accepted", false)), "seating collar clamp after isolation succeeds")
	_check(not bool(p05.reopen_garden(true).get("accepted", false)), "cannot reopen GARDEN before verifying annex automatic isolation")
	_check(bool(p05.verify_annex_isolation().get("accepted", false)), "verifying annex automatic isolation succeeds")
	_check(not bool(p05.reopen_garden(false).get("accepted", false)), "fast reopen is rejected due to pressure surge risk")
	_check(bool(p05.reopen_garden(true).get("accepted", false)), "slow reopen succeeds after clamp and annex check")
	_check(not bool(p05.record_stable_reading(2, 100, 100, 100).get("accepted", false)), "post-repair check 2 cannot be logged before check 1")
	_check(not bool(p05.record_stable_reading(1, 100, 99, 100).get("accepted", false)), "post-repair check with 99 is rejected")
	for step in range(1, 6):
		_check(bool(p05.record_stable_reading(step, 100, 100, 100).get("accepted", false)), "post-repair steady check %d/5 (100/100/100) accepted" % step)

	# S05 note reconciliation & S06 annex hatch.
	_check(not bool(p05.reconcile_paper_note("change_valve").get("accepted", false)), "changing the tested valve to match a bad copied note is rejected")
	_check(bool(p05.reconcile_paper_note("fix_note").get("accepted", false)), "correcting the copied paper note to match the tested valve is accepted")
	_check(not bool(p05.configure_annex_hatch("open_unverified").get("accepted", false)), "opening N.R. annex hatch unverified is blocked")
	_check(bool(p05.configure_annex_hatch("isolate_feed").get("accepted", false)) and bool(p05.configure_annex_hatch("confirm_zero_diff").get("accepted", false)) and bool(p05.configure_annex_hatch("camera_inspect").get("accepted", false)), "annex hatch zero-differential camera inspection sequence succeeds")

	# Canonical hint ladder (verbatim from 08_PUZZLE_DESIGNS.md).
	var hints: Array = [
		String(p05.next_hint().get("text", "")),
		String(p05.next_hint().get("text", "")),
		String(p05.next_hint().get("text", "")),
	]
	_check(hints == [
		"Which reading changes over time?",
		"Compare the manual garden reading.",
		"Close GARDEN, clamp its feedthrough, reopen and verify five steady readings.",
	], "P-05 H1-H3 match 08_PUZZLE_DESIGNS.md verbatim")

func _test_p06_model_and_boundaries() -> void:
	var p06 := P06Script.new()
	_check(p06.payload_for_action("p06_count_42").is_empty() and p06.payload_for_action("p06_allocate_12_30").is_empty(), "fresh P-06 model has no hidden seed counts or allocations")

	# Annex provenance & maturity check.
	_check(not bool(p06.record_annex_step("treat_map_as_cleared").get("accepted", false)), "treating hand-drawn N.R. vault map as a cleared route is rejected")
	_check(bool(p06.record_annex_step("save_map_provenance").get("accepted", false)) and bool(p06.record_annex_step("record_future_checks").get("accepted", false)), "saving vault map provenance with 3 present-day safety checks succeeds")
	_check(not bool(p06.set_irrigation_valve("alo", false).get("accepted", false)), "closing Alo's irrigation before confirming pod maturity is rejected")
	_check(not bool(p06.confirm_pod_maturity("cold_alarm").get("accepted", false)), "treating Alo's Day-35 yellowing as a cold alarm is rejected")
	_check(bool(p06.confirm_pod_maturity("mature_completion").get("accepted", false)), "confirming Day-35 pod maturity ('Alo isn't failing. She's finishing.') succeeds")

	# Irrigation valves & 5-day dry-down vigil boundary (moisture 21 vs 20).
	var wrong_tara: Dictionary = p06.set_irrigation_valve("tara", false)
	_check(not bool(wrong_tara.get("accepted", false)) and String(wrong_tara.get("badge", "")).contains("WRONG PLANT") and bool(p06.view_state().get("tara_irrigation_open", false)), "selecting Tara's live irrigation valve warns WRONG PLANT and leaves Tara open")
	_check(bool(p06.set_irrigation_valve("alo", false).get("accepted", false)), "closing Alo's irrigation valve after maturity succeeds")
	for day in range(1, 5):
		p06.advance_drydown(false)
	_check(int(p06.view_state().get("substrate_moisture", 0)) == 26, "day 4 of dry-down vigil reaches moisture 26")
	p06.set_moisture_for_test(21)
	_check(not bool(p06.open_six_pods().get("accepted", false)), "boundary moisture 21 (> 20) blocks opening pods")
	p06.advance_drydown(true)
	_check(int(p06.view_state().get("substrate_moisture", 0)) == 20 and bool(p06.open_six_pods().get("accepted", false)), "boundary moisture 20 unlocks opening the 6 dry pods")

	# Counting 6 wells of 7 seeds = 42.
	var miscount: Dictionary = p06.count_well(0, 6, false)
	_check(not bool(miscount.get("accepted", false)) and int(miscount.get("well_reopened", -1)) == 0, "miscounting a well at 6 seeds reopens that well for recount")
	for well_idx in range(6):
		_check(bool(p06.count_well(well_idx, 7, false).get("accepted", false)), "well %d counted at 7 seeds" % (well_idx + 1))
	_check(p06.total_counted() == 42 and p06.wells_counted() == 6 and p06.payload_for_action("p06_count_42") == {"total": 42, "wells": 6}, "six wells of 7 produce the exact 42-seed payload")

	# Allocation boundaries (double-counting, 13th seed, all 42, 12 + 30).
	_check(not bool(p06.set_allocation(42, 0).get("accepted", false)), "planting all 42 seeds with 0 reserve is rejected")
	_check(not bool(p06.set_allocation(12, 31).get("accepted", false)), "double-counting 12 + 31 = 43 seeds is rejected")
	_check(not bool(p06.set_allocation(13, 29).get("accepted", false)), "planting a 13th seed beyond the two 6-cell cassettes is rejected")
	_check(not bool(p06.set_allocation(11, 31).get("accepted", false)), "11 + 31 split is rejected")
	_check(bool(p06.allocate_12_and_30().get("accepted", false)) and p06.payload_for_action("p06_allocate_12_30") == {"planted": 12, "reserve": 30}, "direct 12 planted + 30 reserve allocation succeeds")

	# Dedication & S12 Tara farewell / ledger separation.
	_check(not bool(p06.choose_dedication("unknown_plaque").get("accepted", false)), "unknown dedication option is rejected")
	_check(bool(p06.choose_dedication("for_alo_and_tara").get("accepted", false)), "choosing 'For Alo and Tara' dedication succeeds")
	_check(not bool(p06.record_s12_continuity("merge_tara_into_founder_42").get("accepted", false)), "merging Tara's 31 May harvest into the 42 founder ledger is rejected")
	_check(bool(p06.record_s12_continuity("confirm_descendant_survey").get("accepted", false)), "recording Tara's separate working stock and 12 October descendants succeeds")

	# Canonical hint ladder (verbatim from 08_PUZZLE_DESIGNS.md).
	var hints: Array = [
		String(p06.next_hint().get("text", "")),
		String(p06.next_hint().get("text", "")),
		String(p06.next_hint().get("text", "")),
	]
	_check(hints == [
		"Harvest after the pods mature.",
		"Keep twelve for planting and thirty protected.",
		"Six wells of seven total 42; allocate 12 and 30.",
	], "P-06 H1-H3 match 08_PUZZLE_DESIGNS.md verbatim")

func _test_chapter3_route_witness_and_persistence() -> void:
	var director := DirectorScript.new()
	director.new_campaign(CampaignContentFull.EXPECTED_CONTENT_REVISION)
	var handoff: Dictionary = director.snapshot()
	handoff["chapter1_ready"] = true
	director.restore_snapshot(handoff)
	var ch2 := preload("res://scripts/missions/chapter2_route.gd").new(director)
	ch2.apply_entry_profile()
	ch2.start_at("EX-CH02-S01")
	for scene_id in preload("res://scripts/missions/chapter2_gate_catalog.gd").SCENE_ORDER:
		for target in ch2.targets_for_current_scene():
			ch2.perform(target.target_id)
		ch2.advance_scene()

	var route := RouteScript.new(director)
	route.start_at("EX-CH03-S01")
	for order in range(1, 13):
		var scene_id := "EX-CH03-S%02d" % order
		for target in route.targets_for_current_scene():
			var tid := String(target.get("target_id", ""))
			if P05Script.is_gate(tid):
				route.p05().prepare_gate_from_panel(tid)
			elif P06Script.is_gate(tid):
				route.p06().prepare_gate_from_panel(tid)
			var res: Dictionary = route.perform(tid)
			_check(bool(res.get("accepted", false)), "%s interactive panel state commits %s" % [scene_id, tid])
		if order == 4:
			var r4: Dictionary = director.snapshot().get("resources", {})
			_check(int(r4.E) == 18 and int(r4.A) == 3 and int(r4.H) == 6 and int(r4.C) == 8 and is_equal_approx(float(r4.R), 13.2), "P-05 witness reaches E18, A3, H6, C8, R13.2 at EX-CH03-S04")
		if order == 10:
			var inv10: Dictionary = director.snapshot().get("inventories", {})
			_check(int(inv10.founder_seed42.total) == 42 and int(inv10.allocated12) == 12 and int(inv10.reserve30) == 30, "P-06 witness reaches 42 = 12 + 30 at EX-CH03-S10")
		if order < 12:
			_check(bool(route.advance_scene().get("accepted", false)), "%s advances to next Chapter 3 scene" % scene_id)
		else:
			var done_ch3: Dictionary = route.advance_scene()
			_check(bool(done_ch3.get("chapter_complete", false)), "EX-CH03-S12 completes Chapter 3")

	# Persistence and malformed snapshot rejection.
	var saved: Dictionary = JSON.parse_string(JSON.stringify(route.snapshot()))
	var resumed := RouteScript.new(director)
	_check(bool(resumed.restore(saved).get("accepted", false)) and resumed.p05().snapshot() == route.p05().snapshot() and resumed.p06().snapshot() == route.p06().snapshot(), "P-05 and P-06 states survive JSON save and restore")

	var broken_p05 := saved.duplicate(true)
	broken_p05.p05.current_phase = 99
	_check(not bool(resumed.restore(broken_p05).get("accepted", false)), "malformed P-05 phase is rejected on restore")

	var broken_p06 := saved.duplicate(true)
	broken_p06.p06.well_counts = "invalid"
	_check(not bool(resumed.restore(broken_p06).get("accepted", false)), "malformed P-06 well_counts is rejected on restore")

func _test_scientific_puzzle_panel_ui() -> void:
	root.size = Vector2i(1280, 720)
	var director := DirectorScript.new()
	director.new_campaign()
	var route := RouteScript.new(director)
	route.start_at("EX-CH03-S02")
	route.p05().prepare_gate_from_panel("p05_read_main_t0")
	route.perform("p05_read_main_t0")

	var panel := PanelScene.instantiate() as ScientificPuzzlePanel
	root.add_child(panel)
	var emitted: Array = []
	panel.commit_requested.connect(func(tid: String, payload: Dictionary) -> void: emitted.append([tid, payload]))

	panel.open(route, "p05_read_garden_t0", {"large_text": false, "timer_free": true})
	await process_frame

	# Check button heights >= 44 px and absence of developer jargon on visible labels/buttons.
	var too_small: Array = []
	var jargon_found: Array = []
	for node in panel.find_children("*", "Control", true, false):
		if node is Button and (node as Button).is_visible_in_tree():
			if (node as Button).size.y < 44.0:
				too_small.append(node.name)
			var btxt := (node as Button).text
			if btxt.contains("EX-CH03") or btxt.contains("TL_PressureGauge") or btxt.contains("PR_RepairClamp"):
				jargon_found.append(btxt)
		elif node is Label and (node as Label).is_visible_in_tree():
			var ltxt := (node as Label).text
			if ltxt.contains("EX-CH03") or ltxt.contains("TL_PressureGauge") or ltxt.contains("PR_RepairClamp"):
				jargon_found.append(ltxt)
	_check(too_small.is_empty(), "every visible P-05 panel button is at least 44 px tall " + str(too_small))
	_check(jargon_found.is_empty(), "visible P-05 panel text contains no raw developer IDs " + str(jargon_found))

	# Unplanned commit is blocked until gauge reading and preview.
	_check(not bool(panel.request_commit().get("accepted", false)), "Lock In is blocked before reading the tap and previewing")
	panel.select_prediction("GARDEN")
	_check(not bool(panel.request_close().get("accepted", false)) and panel.find_child("LeaveConfirmBanner", true, false) != null, "stepping back with uncommitted changes prompts for confirmation")
	panel.undo_changes()
	_check(route.p05().view_state().get("prediction", "") == "", "Undo reverts uncommitted workbench changes")

	var prev: Dictionary = panel.preview()
	_check(bool(prev.get("accepted", false)) and prev.get("payload", {}) == {"reading": 82}, "Try It (Preview) prepares and previews the 82 garden tap reading")

	var space := InputEventKey.new()
	space.pressed = true
	space.physical_keycode = KEY_SPACE
	panel._input(space)
	_check(panel.find_child("ConfirmCommit", true, false) != null and emitted.is_empty(), "Space opens the Lock In confirmation banner first")
	panel._input(space)
	_check(emitted.size() == 1 and emitted[0][0] == "p05_read_garden_t0" and emitted[0][1] == {"reading": 82} and not panel.is_open(), "Space again confirms once, emits the 82 reading payload, and closes")
	_check(not bool(panel.confirm_commit().get("accepted", false)) and emitted.size() == 1, "duplicate confirm_commit emits nothing")

	# Test P-06 panel in 150% large-text mode.
	route.start_at("EX-CH03-S10")
	for prior in ["p06_drydown_five_days", "p06_open_six_pods", "p06_count_42"]:
		route.p06().prepare_gate_from_panel(prior)
		route.perform(prior)
	panel.open(route, "p06_allocate_12_30", {"large_text": true, "timer_free": true})
	await process_frame
	var large_preview := panel.find_child("Preview", true, false) as Button
	_check(large_preview != null and large_preview.get_theme_font_size("font_size") >= 19, "150% large text scales ScientificPuzzlePanel controls cleanly")
	var p06_prev: Dictionary = panel.preview()
	_check(bool(p06_prev.get("accepted", false)) and p06_prev.get("payload", {}) == {"planted": 12, "reserve": 30}, "P-06 panel preview prepares and previews the 12 + 30 split")
	panel.close()
	panel.free()

func _test_campaign_hud_integration() -> void:
	if not storage.setup("test_p05_p06_puzzles"):
		_check(false, "isolated storage for Chapter 3 HUD integration check")
		return
	var campaign := CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	root.add_child(campaign)
	await process_frame
	campaign._start_extended("EX-CH03-S01")
	await process_frame
	campaign.hud.refresh_scene()
	var opened := campaign.hud.open_scientific_puzzle("p05_equip_gauge")
	_check(opened and campaign.hud.scientific_puzzle.is_open() and bool(campaign.director.query().paused), "opening ScientificPuzzlePanel from HUD pauses scenario time")
	var target := campaign.physical_target("p05_equip_gauge")
	if target != null and campaign._player != null:
		campaign._player.global_position = Vector3(target.global_position.x, 0.0, target.global_position.z + 1.0)
	await physics_frame
	await physics_frame
	campaign.hud.scientific_puzzle.preview()
	campaign.hud.scientific_puzzle.request_commit()
	campaign.hud.scientific_puzzle.confirm_commit()
	await process_frame
	_check(not bool(campaign.director.query().paused) and bool(campaign.route.current_flags().get("p05_equip_gauge_done", false)), "confirming in ScientificPuzzlePanel resumes scenario time and commits the physical gate")
	campaign.free()
	storage.cleanup()

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)
