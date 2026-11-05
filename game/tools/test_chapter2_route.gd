## Godot --headless --path game --script res://tools/test_chapter2_route.gd
extends SceneTree

const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const Chapter2RouteScript = preload("res://scripts/missions/chapter2_route.gd")
const GateCatalog = preload("res://scripts/missions/chapter2_gate_catalog.gd")
const P03Script = preload("res://scripts/puzzles/p03_pollination.gd")
const P04Script = preload("res://scripts/puzzles/p04_recorder_reconstruction.gd")
const LedgerScript = preload("res://scripts/puzzles/extended_puzzle_ledger.gd")
const PanelScene: PackedScene = preload("res://scenes/ui/scientific_puzzle_panel.tscn")
const CampaignScene: PackedScene = preload("res://scenes/campaign/chapter1_campaign.tscn")

var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_no_prefilled_defaults()
	_test_p03_interactive_rules_and_boundaries()
	_test_p04_interactive_rules_and_boundaries()
	await _test_scientific_puzzle_panel_ui()
	await _test_campaign_hud_integration()

	var director := DirectorScript.new()
	director.new_campaign(CampaignContentFull.EXPECTED_CONTENT_REVISION)
	var route := Chapter2RouteScript.new(director)
	_check(not bool(route.begin().get("accepted", false)), "Chapter 2 refuses to begin before Chapter 1 readiness")

	var ready_state: Dictionary = director.snapshot()
	ready_state["chapter1_ready"] = true
	ready_state["resources"] = {"E": 20, "E_max": 20, "A": 7, "A_max": 10, "H": 10, "C": 9, "R": 21.0}
	ready_state["scenario_datetime"] = "2046-04-29 18:00 UTC"
	director.restore_snapshot(ready_state)
	var handoff: Dictionary = route.apply_entry_profile()
	var after_handoff: Dictionary = director.query()
	_check(
		bool(handoff.get("accepted", false))
		and int(after_handoff.resources.E) == 14
		and int(after_handoff.resources.A) == 10
		and int(after_handoff.resources.H) == 6
		and int(after_handoff.resources.C) == 8
		and is_equal_approx(float(after_handoff.resources.R), 18.0)
		and String(after_handoff.scenario_datetime) == "2046-04-30 06:00 UTC",
		"Chapter 1 -> 2 handoff sets canonical P-03 entry profile (E14/20, A10/10, H6, C8, R18 at 2046-04-30 06:00 UTC)"
	)
	_check(bool(route.begin().get("accepted", false)), "Chapter 2 begins at EX-CH02-S01 when Chapter 1 is ready")

	for scene_id in GateCatalog.SCENE_ORDER:
		_check(route.current_scene_id() == scene_id, "route is at " + scene_id)
		for line_id in GateCatalog.dialogue_ids(scene_id):
			_check(bool(route.acknowledge_dialogue(line_id).get("accepted", false)), "acknowledged " + line_id)
		_check(not bool(route.gate_status().get("ready", false)), "dialogue never completes " + scene_id)

		for target in route.targets_for_current_scene():
			var tid := String(target.get("target_id", ""))
			var pid := String(target.get("puzzle_id", ""))
			var pact := String(target.get("puzzle_action", ""))
			if pid == "P-03":
				route.p03().reset_current_step()
				if pact in ["p03_scan_tara", "p03_collect_tara_pollen", "p03_transfer_to_alo", "p03_record_prediction"] or pact.begins_with("p03_log_care_day_"):
					var unplanned := route.perform(tid)
					_check(not bool(unplanned.get("accepted", false)) and bool(unplanned.get("scientific_puzzle", false)), "unconfigured P-03 step refuses to commit: " + tid)
				route.p03().configure_for_action(pact)
			elif pid == "P-04":
				route.p04().reset_current_step()
				if pact in ["p04_assign_date", "p04_assign_device", "p04_assign_channel", "p04_classify_inference"]:
					var unplanned_p04 := route.perform(tid)
					_check(not bool(unplanned_p04.get("accepted", false)) and bool(unplanned_p04.get("scientific_puzzle", false)), "unconfigured P-04 step refuses to commit: " + tid)
				route.p04().configure_for_action(pact)

			if tid.begins_with("p03_complete_run_"):
				var stale := route.SnapshotScript.decode(route.SnapshotScript.encode(director.snapshot())).data
				var stale_route := route.SnapshotScript.decode(route.SnapshotScript.encode(route.snapshot())).data
				var action: Dictionary = route.perform(tid)
				_check(bool(action.get("accepted", false)), "completed " + tid + " in " + scene_id)
				var retried: Dictionary = route.retry()
				_check(
					bool(retried.get("accepted", false))
					and route.snapshot().p03 == stale_route.p03
					and director.snapshot().resources == stale.resources
					and director.snapshot().receipts == stale.receipts
					and director.snapshot().plants == stale.plants,
					"Chapter 2 retry restores authoritative state and P-03 progress before " + tid
				)
				route.p03().configure_for_action(pact)
			if tid == "p03_transfer_alo":
				var before_transfer := director.snapshot()
				var transfer_action: Dictionary = route.perform(tid)
				_check(bool(transfer_action.get("accepted", false)), "completed " + tid + " in " + scene_id)
				_check(director.snapshot().plants != before_transfer.plants, "pollination transfer mutates plant state")
				var transfer_retry: Dictionary = route.retry()
				_check(
					bool(transfer_retry.get("accepted", false))
					and director.snapshot().plants == before_transfer.plants
					and route.p03().flags().get("p03_transfer_to_alo_done", false) == false,
					"Chapter 2 retry restores plant state on non-run pollination transfer"
				)
				route.p03().configure_for_action(pact)
			var committed_action: Dictionary = route.perform(tid)
			_check(bool(committed_action.get("accepted", false)), "completed " + tid + " in " + scene_id)

		if scene_id == "EX-CH02-S05":
			var after_sampled: Dictionary = director.query()
			_check(
				int(after_sampled.resources.E) == 16
				and int(after_sampled.resources.A) == 4
				and int(after_sampled.resources.H) == 9
				and int(after_sampled.resources.C) == 10
				and is_equal_approx(float(after_sampled.resources.R), 14.4)
				and String(after_sampled.scenario_datetime) == "2046-05-06 12:00 UTC",
				"P-03 sampled pollination runs leave E16, A4, H9, C10, R14.4 on 2046-05-06"
			)
		if scene_id == "EX-CH02-S06":
			var after_background: Dictionary = director.query()
			_check(
				int(after_background.resources.E) == 16
				and int(after_background.resources.A) == 4
				and int(after_background.resources.H) == 9
				and int(after_background.resources.C) == 10
				and is_equal_approx(float(after_background.resources.R), 4.0)
				and String(after_background.scenario_datetime) == "2046-05-06 12:00 UTC",
				"P-03 background 7-day food ledger leaves E16, A4, H9, C10, R4.0 at 2046-05-06 12:00 UTC"
			)
		_check(bool(route.gate_status().get("ready", false)), "physical gate ready for " + scene_id)
		_check(bool(route.advance_scene().get("accepted", false)), "advanced from " + scene_id)

	var saved: Dictionary = route.snapshot()
	var copy := Chapter2RouteScript.new(director)
	_check(bool(copy.restore(saved).get("accepted", false)) and bool(copy.chapter_ready().get("ready", false)), "Chapter 2 route snapshot restores complete P-03/P-04 state")

	var bad_director := director.snapshot()
	bad_director["resources"] = "corrupt"
	_check(not bool(director.restore_snapshot(bad_director).get("accepted", false)) and int(director.query().resources.E) == 16, "director rejects malformed resource snapshot without mutating live state")

	var bad_route := saved.duplicate(true)
	bad_route["p04"] = {"mapping": "corrupt"}
	_check(not bool(copy.restore(bad_route).get("accepted", false)) and bool(copy.chapter_ready().get("ready", false)), "Chapter 2 route rejects partial puzzle restore without mutating live state")

	print("CHAPTER 2 ROUTE RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_no_prefilled_defaults() -> void:
	for scene_id in GateCatalog.SCENE_ORDER:
		for target in GateCatalog.targets_for_scene(scene_id):
			var pid := String(target.get("puzzle_id", ""))
			if pid in ["P-03", "P-04"]:
				_check(not target.has("payload_defaults") or target.get("payload_defaults", {}).is_empty(), "no pre-filled payload_defaults on %s (%s)" % [String(target.get("target_id", "")), pid])

func _test_p03_interactive_rules_and_boundaries() -> void:
	var p03 := P03Script.new()
	var data := P03Script.data()
	_check(not data.is_empty() and String(data.get("puzzle_id", "")) == "P-03", "P-03 content JSON loads with clues, options, and hints")

	# Hints H1..H3 for pollination and prediction
	var h1 := p03.next_hint("pollination")
	var h2 := p03.next_hint("pollination")
	var h3 := p03.next_hint("pollination")
	_check(int(h1.get("tier", 0)) == 1 and String(h1.get("hint", "")).contains("partner"), "P-03 pollination Hint 1 matches canonical text")
	_check(int(h2.get("tier", 0)) == 2 and String(h2.get("hint", "")).contains("anther"), "P-03 pollination Hint 2 matches canonical text")
	_check(int(h3.get("tier", 0)) == 3 and String(h3.get("hint", "")).contains("Tara→Alo"), "P-03 pollination Hint 3 matches canonical text")
	var ph1 := p03.next_hint("prediction")
	var ph3 := p03.next_hint("prediction")
	ph3 = p03.next_hint("prediction")
	_check(int(ph1.get("tier", 0)) == 1 and int(ph3.get("tier", 0)) == 3 and String(ph3.get("hint", "")).contains("Both colours may appear"), "P-03 prediction Hints 1-3 match canonical text")

	# Clue sharing in Class mode
	var share := p03.share_clue("P03-C1")
	_check(bool(share.get("accepted", false)) and p03.snapshot().shared_clues.has("P03-C1"), "P-03 shares crew clue card in Class mode")

	# Boundary & wrong-but-reasonable tries on P-03
	_check(not bool(p03.preview_action("p03_collect_tara_pollen").get("accepted", false)), "P-03 rejects collecting pollen before scanning donor")
	var skip_weather := p03.select_weather_mode("skip_check")
	p03.select_donor("TARA-01")
	_check(not bool(skip_weather.get("accepted", false)) and not bool(p03.preview_action("p03_scan_tara").get("accepted", false)), "P-03 rejects transfer when space-weather check is skipped")

	p03.select_weather_mode("go_checked")
	p03.select_donor("ALO-01")
	_check(not bool(p03.preview_action("p03_scan_tara").get("accepted", false)), "P-03 rejects scanning wrong donor for Tara step")
	p03.select_donor("TARA-01")
	_check(bool(p03.commit_action("p03_scan_tara").get("accepted", false)), "P-03 commits Tara donor scan after weather GO and Tara selection")

	# Petal touch vs anther
	var petal_try := p03.select_source_structure("petal")
	_check(not bool(petal_try.get("accepted", false)) and String(petal_try.get("reason", "")).contains("no pollen"), "P-03 explains that touching a petal transfers no pollen")
	p03.select_source_structure("anther")

	# Unlabelled single brush & wrong brush B for Tara->Alo
	var unlabelled := p03.select_brush("UNLABELLED")
	_check(not bool(unlabelled.get("accepted", false)) and String(unlabelled.get("reason", "")).contains("one brush"), "P-03 rejects single unlabelled brush with contamination explanation")
	p03.select_brush("B")
	_check(not bool(p03.preview_action("p03_collect_tara_pollen").get("accepted", false)), "P-03 rejects Brush B for Tara->Alo collection")

	# Dirty brush requires replace_brush_tip
	p03.mark_brush_dirty("A")
	var dirty_try := p03.select_brush("A")
	_check(not bool(dirty_try.get("accepted", false)) and not bool(p03.preview_action("p03_collect_tara_pollen").get("accepted", false)), "P-03 blocks collection with a dirty brush tip")
	var replaced := p03.replace_brush_tip("A")
	_check(bool(replaced.get("accepted", false)) and bool(p03.select_brush("A").get("accepted", false)), "P-03 replace_brush_tip provides a fresh sterile tip")
	_check(bool(p03.commit_action("p03_collect_tara_pollen").get("accepted", false)), "P-03 collects Tara pollen from anther with clean Brush A")

	# Unsealed carrier & joining chambers
	var open_carrier := p03.select_carrier_mode("open_carrier")
	_check(not bool(open_carrier.get("accepted", false)) and not bool(p03.preview_action("p03_seal_brush_a").get("accepted", false)), "P-03 rejects open brush carrier across corridor")
	var join_chambers := p03.select_carrier_mode("join_chambers")
	_check(not bool(join_chambers.get("accepted", false)) and String(join_chambers.get("reason", "")).contains("isolation"), "P-03 rejects joining both chambers together")
	p03.select_carrier_mode("sealed_interlock")
	_check(bool(p03.commit_action("p03_seal_brush_a").get("accepted", false)), "P-03 seals Brush A in closed carrier with single-boundary order")

	# Self-pollination (Tara -> Tara) & petal target
	var self_pol := p03.select_recipient("TARA-01")
	_check(not bool(self_pol.get("accepted", false)) and String(self_pol.get("reason", "")).contains("self-incompatibility"), "P-03 explains cultivar self-incompatibility when transferring to same plant")
	p03.select_recipient("ALO-01")
	var target_petal := p03.select_target_structure("petal")
	_check(not bool(target_petal.get("accepted", false)), "P-03 rejects touching recipient petal instead of stigma")
	p03.select_target_structure("stigma")
	_check(bool(p03.commit_action("p03_transfer_to_alo").get("accepted", false)), "P-03 transfers Tara pollen to Alo stigma")

	# Complete remaining Run 1..3 steps and care days to test Twist prediction boundaries
	for act in ["p03_scan_alo", "p03_collect_alo_pollen", "p03_seal_brush_b", "p03_transfer_to_tara", "p03_complete_run_1"]:
		p03.configure_for_action(act)
		_check(bool(p03.commit_action(act).get("accepted", false)), "P-03 Run 1 step: " + act)

	_check(not bool(p03.preview_action("p03_log_care_day_3", {"care_confirmed": true}).get("accepted", false)), "P-03 rejects out-of-order care day 3 before day 2")
	_check(not bool(p03.preview_action("p03_log_care_day_2", {"care_confirmed": false}).get("accepted", false)), "P-03 rejects care day when not checked in logbook")
	for act in ["p03_log_care_day_2", "p03_log_care_day_3", "p03_run_2_forward", "p03_run_2_reverse", "p03_complete_run_2", "p03_log_care_day_4", "p03_log_care_day_5", "p03_log_care_day_6", "p03_log_care_day_7", "p03_run_3_forward", "p03_run_3_reverse", "p03_complete_run_3"]:
		p03.configure_for_action(act)
		_check(bool(p03.commit_action(act).get("accepted", false)), "P-03 Run 2/3 & care step: " + act)

	# Twist stage: Stem-colour prediction wrong-but-reasonable options
	p03.reset_current_step()
	_check(not bool(p03.preview_action("p03_record_prediction").get("accepted", false)), "P-03 rejects empty stem prediction")
	var fixed_ratio := p03.select_prediction_field("prediction", "Every seedling will follow a guaranteed fixed ratio")
	_check(not bool(fixed_ratio.get("accepted", false)) and String(fixed_ratio.get("reason", "")).contains("genotype"), "P-03 rejects fixed-ratio guarantee with genotype explanation")
	var clone_reason := p03.select_prediction_field("reason", "Seeds only copy the mother plant's stem colour.")
	_check(not bool(clone_reason.get("accepted", false)), "P-03 rejects maternal-clone reasoning")
	var skip_test := p03.select_prediction_field("future_test", "Decide now without counting future seedlings.")
	_check(not bool(skip_test.get("accepted", false)), "P-03 rejects skipping descendant observation")

	p03.configure_for_action("p03_record_prediction")
	_check(bool(p03.commit_action("p03_record_prediction").get("accepted", false)) and bool(p03.flags().get("p03_complete", false)) and bool(p03.flags().get("p03_uncontaminated", false)), "P-03 records valid stem prediction and marks Golden uncontaminated mastery")

func _test_p04_interactive_rules_and_boundaries() -> void:
	var p04 := P04Script.new()
	var data := P04Script.data()
	_check(not data.is_empty() and String(data.get("puzzle_id", "")) == "P-04", "P-04 content JSON loads with tokens, transcripts, claims, and hints")

	# Hints H1..H3 for metadata and classification
	var mh1 := p04.next_hint("metadata")
	var mh2 := p04.next_hint("metadata")
	var mh3 := p04.next_hint("metadata")
	_check(int(mh1.get("tier", 0)) == 1 and String(mh1.get("hint", "")).contains("equipment plate"), "P-04 metadata Hint 1 matches canonical text")
	_check(int(mh2.get("tier", 0)) == 2 and String(mh2.get("hint", "")).contains("different fields"), "P-04 metadata Hint 2 matches canonical text")
	_check(int(mh3.get("tier", 0)) == 3 and String(mh3.get("hint", "")).contains("2034-04, HORT-01, ENGINEERING"), "P-04 metadata Hint 3 matches canonical text")
	var ch1 := p04.next_hint("classification")
	var ch2 := p04.next_hint("classification")
	var ch3 := p04.next_hint("classification")
	_check(int(ch1.get("tier", 0)) == 1 and int(ch2.get("tier", 0)) == 2 and String(ch3.get("hint", "")).contains("Voice resembles Ferreira"), "P-04 classification Hints 1-3 match canonical text")

	# Bench label peeling & unsupported Person-slot identity claims
	var peel := p04.select_label_handling("peel_labels")
	_check(not bool(peel.get("accepted", false)) and String(peel.get("reason", "")).contains("peel"), "P-04 forbids peeling physical bench labels")
	var guess_f := p04.select_person_slot("guess_ferreira")
	_check(not bool(guess_f.get("accepted", false)) and not bool(p04.preview_action("p04_assign_date", {"value": "2034-04"}).get("accepted", false)), "P-04 blocks archive actions while an unsupported name is in the Person slot")
	p04.select_person_slot("blank_unknown")

	# Wrong token placement: remains removable, names disagreeing source card, keeps audio locked
	var wrong_date := p04.set_slot_token("date", "2046-05")
	_check(
		bool(wrong_date.get("accepted", false))
		and not bool(wrong_date.get("valid_token", true))
		and bool(wrong_date.get("removable", false))
		and String(wrong_date.get("source_disagrees", "")).contains("2034-04")
		and bool(wrong_date.get("audio_locked", false)),
		"P-04 wrong token stays in slot, is removable, names disagreeing source card, and locks audio"
	)
	_check(not bool(p04.preview_action("p04_assign_date").get("accepted", false)), "P-04 refuses to commit wrong date token")
	var removed := p04.remove_slot_token("date")
	_check(bool(removed.get("accepted", false)) and String(p04.slot_status("date").get("value", "")) == "", "P-04 removes wrong token cleanly")

	# Cross-slot field mismatch (putting HORT-01 into date slot)
	var cross_slot := p04.set_slot_token("date", "HORT-01")
	_check(not bool(cross_slot.get("valid_token", true)) and not bool(p04.preview_action("p04_assign_date").get("accepted", false)), "P-04 rejects cross-slot Device ID in Date field")

	# Premature checksum & transcript
	_check(not bool(p04.preview_action("p04_verify_checksum").get("accepted", false)), "P-04 blocks checksum verification before all three tokens match")
	_check(not bool(p04.preview_action("p04_open_transcript").get("accepted", false)), "P-04 blocks transcript before checksum verification")
	_check(not bool(p04.preview_action("p04_play_engineer").get("accepted", false)), "P-04 keeps audio locked before transcript is opened")

	# Assign valid tokens & unlock transcript
	p04.set_slot_token("date", "2034-04")
	p04.set_slot_token("device", "HORT-01")
	p04.set_slot_token("channel", "ENGINEERING")
	_check(bool(p04.commit_action("p04_assign_date").get("accepted", false)), "P-04 commits verified Date token 2034-04")
	_check(bool(p04.commit_action("p04_assign_device").get("accepted", false)), "P-04 commits verified Device token HORT-01")
	_check(bool(p04.commit_action("p04_assign_channel").get("accepted", false)), "P-04 commits verified Channel token ENGINEERING")
	_check(bool(p04.commit_action("p04_verify_checksum").get("accepted", false)), "P-04 verifies local checksum once all three tokens match")
	_check(bool(p04.commit_action("p04_open_transcript").get("accepted", false)), "P-04 opens reconstructed transcript")
	_check(bool(p04.commit_action("p04_play_engineer").get("accepted", false)), "P-04 plays 2034 Engineer fragment")
	_check(bool(p04.commit_action("p04_play_n").get("accepted", false)), "P-04 plays N.'s mustard-fields memory")

	# Observed / Inferred / Unknown classification board
	_check(not bool(p04.preview_action("p04_classify_inference").get("accepted", false)), "P-04 rejects empty classification board")
	var wrong_voice := p04.classify_claim("voice_resembles_ferreira", "observed")
	p04.classify_claim("retreat_2034", "observed")
	p04.classify_claim("writer_n_identity", "unknown")
	_check(not bool(wrong_voice.get("accepted", false)) and not bool(p04.preview_action("p04_classify_inference").get("accepted", false)), "P-04 rejects filing voice resemblance under Observed")

	var right_voice := p04.classify_claim("voice_resembles_ferreira", "inferred")
	_check(bool(right_voice.get("accepted", false)) and bool(p04.commit_action("p04_classify_inference").get("accepted", false)), "P-04 accepts Observed/Inferred/Unknown classification when voice resemblance is Inferred")
	_check(bool(p04.commit_action("p04_send_copy").get("accepted", false)), "P-04 sends technical copy to Ferreira")
	_check(bool(p04.commit_action("p04_ack_handover").get("accepted", false)) and bool(p04.flags().get("p04_complete", false)), "P-04 completes evening handover")

	# Verify ExtendedPuzzleLedger delegates P-03 and P-04
	var ledger := LedgerScript.new()
	_check(not bool(ledger.preview("P-04", "p04_assign_date", {"value": "2046-05"}).get("accepted", false)), "ExtendedPuzzleLedger delegates P-04 validation")
	_check(bool(ledger.preview("P-04", "p04_assign_date", {"value": "2034-04"}).get("accepted", false)), "ExtendedPuzzleLedger accepts valid P-04 token")

func _test_scientific_puzzle_panel_ui() -> void:
	var director := DirectorScript.new()
	director.new_campaign(CampaignContentFull.EXPECTED_CONTENT_REVISION)
	var ready: Dictionary = director.snapshot()
	ready["chapter1_ready"] = true
	director.restore_snapshot(ready)
	var route := Chapter2RouteScript.new(director)
	route.apply_entry_profile()
	route.start_at("EX-CH02-S04")

	var panel := PanelScene.instantiate() as ScientificPuzzlePanel
	panel.size = Vector2(1280, 800)
	root.add_child(panel)
	await process_frame

	var emitted: Array = []
	panel.commit_requested.connect(func(tid: String, payload: Dictionary) -> void: emitted.append([tid, payload]))

	_check(panel.open(route, "p03_scan_tara", {"large_text": false}) and panel.is_open(), "ScientificPuzzlePanel opens for P-03 EX-CH02-S04")
	panel.toggle_data_cards(true)
	await process_frame
	_check(panel.is_data_cards_open(), "ScientificPuzzlePanel opens offline NASA Data Cards for P-03")
	_check(_all_buttons_meet_min_height(panel, 44.0), "all P-03 ScientificPuzzlePanel buttons are at least 44 px tall")

	# Pressing Space before configuring choices should NOT open confirm bar
	_send_action(panel, "ui_accept")
	_check(not panel.is_confirm_open() and emitted.is_empty(), "Space does not stage commit when P-03 step choices are incomplete")

	# Configure valid choices for p03_scan_tara, then test dirty-close guard, then Space -> Esc -> Space -> Space commit
	route.p03().select_weather_mode("go_checked")
	route.p03().select_donor("TARA-01")
	panel._dirty_since_open = true
	panel.close(false)
	_check(panel.is_open() and panel._close_confirm_open, "closing with uncommitted selections prompts confirmation")
	_send_action(panel, "ui_cancel")
	_check(not panel._close_confirm_open and panel.is_open(), "Esc cancels close confirmation and keeps working")

	_send_action(panel, "ui_accept")
	_check(panel.is_confirm_open() and emitted.is_empty(), "Space opens commit confirmation bar when step choices are valid")
	_send_action(panel, "ui_cancel")
	_check(not panel.is_confirm_open() and emitted.is_empty(), "Esc steps back from commit confirmation bar")
	_send_action(panel, "ui_accept")
	_send_action(panel, "ui_accept")
	_check(emitted.size() == 1 and emitted[0][0] == "p03_scan_tara", "second Space confirms once and emits commit_requested for p03_scan_tara")

	# Test P-04 panel in EX-CH02-S09 at 150% large_text
	route.start_at("EX-CH02-S09")
	_check(panel.open(route, "assign_date_token", {"large_text": true}) and panel.is_open(), "ScientificPuzzlePanel opens for P-04 EX-CH02-S09 at 150% large text")
	await process_frame
	_check(_all_buttons_meet_min_height(panel, 44.0), "all P-04 ScientificPuzzlePanel buttons are at least 44 px tall at 150% text")

	panel.free()
	await process_frame

func _test_campaign_hud_integration() -> void:
	var storage = preload("res://tools/support/isolated_storage.gd").new()
	if not storage.setup("test_chapter2_puzzles_hud"):
		_check(false, "isolated storage setup for Chapter 2 HUD test")
		return
	var director := DirectorScript.new()
	director.new_campaign(CampaignContentFull.EXPECTED_CONTENT_REVISION)
	var route := Chapter2RouteScript.new(director)
	var ready: Dictionary = director.snapshot()
	ready["chapter1_ready"] = true
	director.restore_snapshot(ready)
	route.apply_entry_profile()
	route.start_at("EX-CH02-S04")
	var state: Dictionary = director.snapshot()
	state["chapter1_ready"] = true
	state["chapter_id"] = "CH02"
	state["mission_id"] = "EX-M0202"
	state["scene_id"] = "EX-CH02-S04"
	state["route_runtime"] = route.snapshot()

	var campaign := CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	campaign.initial_snapshot = state
	root.add_child(campaign)
	await process_frame

	var opened := campaign.hud.open_scientific_puzzle("p03_scan_tara")
	_check(opened and campaign.hud.scientific_puzzle.is_open() and bool(campaign.director.query().paused), "HUD opens ScientificPuzzlePanel for P-03 and pauses scenario time")
	campaign.route.p03().configure_for_action("p03_scan_tara")
	campaign.hud.scientific_puzzle._refresh()
	campaign.hud.scientific_puzzle._request_commit_stage()
	campaign.hud.scientific_puzzle._confirm_commit()
	_check(bool(campaign.route.current_flags().get("p03_scan_tara_done", false)), "confirming in ScientificPuzzlePanel commits physical P-03 target through HUD")
	campaign.hud.scientific_puzzle.close(true)
	_check(not campaign.hud.scientific_puzzle.is_open() and not bool(campaign.director.query().paused), "closing ScientificPuzzlePanel resumes scenario time")

	campaign.free()
	await process_frame
	storage.cleanup()

func _send_action(node: Node, action_name: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action_name
	ev.pressed = true
	node._unhandled_input(ev)

func _all_buttons_meet_min_height(node: Node, min_h: float) -> bool:
	if node is Button:
		var btn := node as Button
		if btn.visible and maxf(btn.size.y, btn.custom_minimum_size.y) < min_h:
			return false
	for child in node.get_children():
		if not _all_buttons_meet_min_height(child, min_h):
			return false
	return true

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)
