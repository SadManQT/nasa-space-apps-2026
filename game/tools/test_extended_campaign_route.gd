## Godot --headless --path game --script res://tools/test_extended_campaign_route.gd
## Traverses the authored physical gates for Chapters 3–8 and verifies puzzle receipt persistence.
extends SceneTree

const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const RouteScript = preload("res://scripts/missions/extended_campaign_route.gd")
const GateCatalog = preload("res://scripts/missions/extended_gate_catalog.gd")
const PuzzleData = preload("res://scripts/puzzles/puzzle_data.gd")
const Witness3 = preload("res://tools/support/chapter3_witness.gd")
const Witness4 = preload("res://tools/support/chapter4_witness.gd")
const Witness6 = preload("res://tools/support/chapter6_witness.gd")
const Witness = preload("res://tools/support/chapter8_witness.gd")
const P03_CONTENT := "res://resources/campaign/content/p03_pollination.json"
const P04_CONTENT := "res://resources/campaign/content/p04_recorder_reconstruction.json"

var checks := 0
var failures := 0
var _evidence_snapshots: Dictionary = {}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var director := DirectorScript.new()
	director.new_campaign(CampaignContentFull.EXPECTED_CONTENT_REVISION)
	var handoff: Dictionary = director.snapshot()
	handoff["chapter1_ready"] = true
	director.restore_snapshot(handoff)
	var pollination := preload("res://scripts/missions/chapter2_route.gd").new(director)
	var p03_content := _chapter2_content(P03_CONTENT)
	var p04_content := _chapter2_content(P04_CONTENT)
	_check(pollination.apply_entry_profile().accepted, "P-03 entry profile is explicit")
	pollination.start_at("EX-CH02-S01")
	for scene_id in preload("res://scripts/missions/chapter2_gate_catalog.gd").SCENE_ORDER:
		for target in pollination.targets_for_current_scene():
			var run_preview := {}
			if String(target.get("puzzle_action", "")).begins_with("p03_complete_run_"):
				var before_preview := director.snapshot()
				pollination.focus(target.target_id)
				pollination.inspect()
				pollination.use({"_puzzle_action": target.puzzle_action})
				run_preview = pollination.preview()
				_check(run_preview.accepted and director.snapshot() == before_preview, "pollination run preview preserves authoritative state")
			var selected: Dictionary = _chapter2_selected_input(String(target.get("puzzle_action", "")), p03_content, p04_content)
			var action := pollination.perform(target.target_id, selected)
			if not run_preview.is_empty() and run_preview.accepted:
				_check(run_preview.snapshot.resources == director.snapshot().resources and run_preview.snapshot.plants == director.snapshot().plants, "pollination run preview returns the actual projected resources and biology")
			if not action.accepted:
				print("CH2 BIO DETAIL ", target.target_id, " ", action.get("reason", ""), " current=", director.query().scenario_datetime)
			_check(action.accepted, "dated Chapter 2 handoff operation " + target.target_id)
		pollination.advance_scene()
	var route := RouteScript.new(director)
	_check(bool(route.start_at("EX-CH03-S01").get("accepted", false)), "extended route starts at canonical Chapter 3")
	var expected_scene_count := GateCatalog.scene_ids().size()
	_check(expected_scene_count == 72, "extended route contains all 72 Chapter 3–8 scenes")
	for scene_id in GateCatalog.scene_ids():
		_check(route.current_scene_id() == scene_id, "route is at " + scene_id)
		for target in GateCatalog.targets_for_scene(scene_id):
			var payload: Dictionary = target.get("payload_defaults", {}).duplicate(true) if target.get("payload_defaults", {}) is Dictionary else {}
			# M3-5P/M3-7P: the Chapter 5/7 puzzle answers no longer come
			# pre-filled from the catalog. The walk acts as a player who made
			# the decisions recorded in the puzzle data files.
			if payload.is_empty():
				payload = PuzzleData.gate_payload(String(target.get("puzzle_action", "")))
			payload = Witness3.payload(String(target.get("target_id", "")), director.snapshot(), payload)
			payload = Witness4.payload(String(target.get("target_id", "")), director.snapshot(), payload)
			payload = Witness6.payload(String(target.get("target_id", "")), director.snapshot(), payload)
			payload = Witness.payload(String(target.get("target_id", "")), director.snapshot(), payload)
			var previous_state: Dictionary = JSON.parse_string(JSON.stringify(director.snapshot()))
			var previous_route: Dictionary = JSON.parse_string(JSON.stringify(route.snapshot()))
			var projected := {}
			if target.target_id in ["p05_inspect_habitat", "p05_stable_read_5", "p06_configure_drydown", "p06_open_six_pods", "p06_plant_12_positions", "p08_inventory_12", "p10_verify_pressure", "p10_plant_cotton", "p11_commit_allocation", "p13_commit_plan", "p14_commit_steps_1_2", "p14_commit_steps_3_6", "p15_choose_surveyed_route", "p16_install_controller"]:
				route.focus(target.target_id)
				route.inspect()
				route.use(payload.merged({"_puzzle_action": target.puzzle_action}))
				projected = route.preview()
				_check(projected.accepted and JSON.parse_string(JSON.stringify(director.snapshot())) == previous_state, "read-only real preview " + target.target_id)
			var result: Dictionary = route.perform(String(target.get("target_id", "")), payload)
			if not projected.is_empty() and projected.accepted:
				var actual: Dictionary = director.snapshot()
				_check(projected.snapshot.resources == actual.resources and projected.snapshot.plants == actual.plants and projected.snapshot.inventories == actual.inventories and projected.snapshot.route == actual.route, "real preview/commit equality " + target.target_id)
			if target.target_id == "p14_commit_steps_3_6":
				var summary := str(result.get("result", {}).get("ledger_summary", []))
				_check(not summary.contains("%g") and not summary.contains("%s"), "player ledger notes contain actual numeric readings")
			if not bool(result.get("accepted", false)):
				print("EXTENDED DETAIL ", scene_id, " / ", target.get("target_id", ""), " -> ", result.get("reason", ""), " trace=", result.get("trace", {}).get("preview", {}).get("trace", []))
			_check(bool(result.get("accepted", false)), scene_id + " commits " + String(target.get("target_id", "")))
			if scene_id in ["EX-CH03-S01", "EX-CH04-S04", "EX-CH05-S01", "EX-CH06-S01", "EX-CH07-S05", "EX-CH08-S03"]:
				var copy_director := DirectorScript.new()
				copy_director.restore_snapshot(JSON.parse_string(JSON.stringify(director.snapshot())))
				var copy := RouteScript.new(copy_director)
				_check(bool(copy.restore(JSON.parse_string(JSON.stringify(route.snapshot()))).get("accepted", false)), "B05 later checkpoint persists at " + scene_id)
				var retried := copy.retry()
				var restored_local: Dictionary = JSON.parse_string(JSON.stringify(copy.snapshot()))
				var restored_state: Dictionary = JSON.parse_string(JSON.stringify(copy_director.snapshot()))
				_check(bool(retried.get("accepted", false)) and restored_local.ledger == previous_route.ledger and restored_local.world == previous_route.world and restored_local.scene_flags == previous_route.scene_flags and restored_state.resources == previous_state.resources and restored_state.receipts == previous_state.receipts and restored_state.plants == previous_state.plants and restored_state.inventories == previous_state.inventories and restored_state.campaign_ledgers == previous_state.campaign_ledgers and restored_state.scenario_datetime == previous_state.scenario_datetime, "B05 retry restores complete operation checkpoint at " + scene_id)

		_verify_scene(scene_id, director.snapshot())
		if OS.get_cmdline_user_args().has("--evidence") and scene_id in ["EX-CH03-S04", "EX-CH03-S10", "EX-CH05-S12", "EX-CH07-S08", "EX-CH08-S12"]:
			var captured := director.snapshot()
			captured["route_runtime"] = route.snapshot()
			captured.route_runtime["chapter"] = int(scene_id.substr(5, 2))
			_evidence_snapshots[scene_id] = captured
		if scene_id == "EX-CH07-S08":
			var valid := director.snapshot()
			var broken := valid.duplicate(true)
			broken.resources.A = 0
			director.restore_snapshot(broken)
			_check(not route.gate_status().ready, "storm scene cannot complete from receipts when authoritative air is unsafe")
			director.restore_snapshot(valid)
		_check(bool(route.gate_status().get("ready", false)), scene_id + " physical gate is ready")
		var moved: Dictionary = route.advance_scene()
		var order := int(scene_id.substr(9, 2))
		if order == 12:
			_check(bool(moved.get("chapter_complete", false)), scene_id + " closes its chapter boundary")
			if scene_id == "EX-CH08-S12":
				_check(bool(moved.get("campaign_complete", false)), "EX-CH08-S12 closes the full campaign")
			else:
				var next_scene := "EX-CH%02d-S01" % (int(scene_id.substr(5, 2)) + 1)
				var next_result: Dictionary = route.start_at(next_scene)
				if not bool(next_result.get("accepted", false)):
					print("EXTENDED TRANSITION DETAIL ", next_scene, " -> ", next_result)
				_check(bool(next_result.get("accepted", false)), "route opens " + next_scene)
		else:
			_check(bool(moved.get("accepted", false)), scene_id + " advances in canonical order")
	_check(route.completed_scene_ids().size() == 72, "all 72 extended scenes retain physical completion receipts")
	_check(bool(route.chapter_ready().get("ready", false)), "final extended route reports campaign readiness")
	var snapshot: Dictionary = route.snapshot()
	var restored_route := RouteScript.new(director)
	var restore_result: Dictionary = restored_route.restore(snapshot)
	if not bool(restore_result.get("accepted", false)):
		print("EXTENDED RESTORE DETAIL ", restore_result)
	_check(bool(restore_result.get("accepted", false)), "extended route restores world and puzzle ledger state")
	_check(restored_route.current_scene_id() == "EX-CH08-S12" and restored_route.completed_scene_ids().size() == 72, "restored route remains at final campaign scene")
	if OS.get_cmdline_user_args().has("--evidence"):
		await _render_evidence()
	print("EXTENDED CAMPAIGN ROUTE RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)

func _chapter2_content(path: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

func _chapter2_selected_input(action: String, p03_content: Dictionary, p04_content: Dictionary) -> Dictionary:
	if action == "p03_record_prediction":
		var fields: Dictionary = p03_content.get("choices", {}).get("prediction", {}).get("fields", {})
		var chosen := {}
		for field in ["prediction", "reason", "future_test"]:
			for option in fields.get(field, []):
				if bool(option.get("correct", false)):
					chosen[field] = String(option.get("value", ""))
					break
		return chosen
	var expected: Dictionary = p04_content.get("expected", {})
	match action:
		"p04_assign_date": return {"value": String(expected.get("date", ""))}
		"p04_assign_device": return {"value": String(expected.get("device", ""))}
		"p04_assign_channel": return {"value": String(expected.get("channel", ""))}
	return {}

func _verify_scene(id: String, state: Dictionary) -> void:
	var expected := {}
	match id:
		"EX-CH03-S04":
			expected = {"E": 18, "A": 3, "H": 6, "C": 8, "R": 13.2}
			_check(state.scenario_datetime.begins_with("2046-05-07"), "P-05 budget phases preserve the approved story date")
		"EX-CH03-S09":
			var alo: Dictionary = state.plants.filter(func(plant): return plant.individual_id == "ALO-01")[0]
			_check(alo.stage == "mature_pods" and alo.maturity_confirmed_at.begins_with("2046-05-16") and alo.dry_down_started_at.begins_with("2046-05-16"), "May 16 maturity and irrigation stop are real biology")
		"EX-CH03-S10":
			var alo: Dictionary = state.plants.filter(func(plant): return plant.individual_id == "ALO-01")[0]
			_check(alo.harvested and not alo.alive and alo.stage == "archived_petal" and alo.harvested_at.begins_with("2046-05-21"), "May 21 harvest archives the original, without revival")
			_check(state.inventories.founder_seed42.total == 42 and state.inventories.allocated12 == 12 and state.inventories.reserve30 == 30, "physical founder harvest conserves forty-two as twelve plus thirty")
		"EX-CH03-S12":
			var descendants: Array = state.plants.filter(func(plant): return String(plant.individual_id).begins_with("DESC-CURRENT") and plant.alive)
			_check(descendants.size() == 12 and descendants.filter(func(plant): return plant.attributes.stem_colour == "purple").size() == 7 and descendants.filter(func(plant): return plant.attributes.stem_colour == "green").size() == 5, "October sample has twelve replacement descendants, seven purple and five green")
			_check(state.scenario_datetime.begins_with("2046-10-21") and state.inventories.reserve30 == 30, "dated descendant bridge never spends protected founder seeds")
			var tara: Dictionary = state.plants.filter(func(plant): return plant.individual_id == "TARA-01")[0]
			_check(tara.maturity_confirmed_at.begins_with("2046-05-26") and tara.dry_down_started_at.begins_with("2046-05-26"), "Tara's pods are mature and her watering stops on 26 May")
			_check(tara.harvested and not tara.alive and tara.stage == "archived_nameplate" and tara.harvested_at.begins_with("2046-05-31") and tara.seed_yield == 0, "Tara's 31 May harvest archives her nameplate with no headline count")
			var stock: Dictionary = state.inventories.get("working_stock", {})
			_check(String(stock.get("cross", "")) == "Tara x Alo" and bool(stock.get("sealed", false)) and not stock.has("total") and not stock.has("count"), "the working stock is Tara x Alo, sealed, with no count")
			_check(state.inventories.founder_seed42.total == 42 and state.inventories.founder_seed42.allocated == 12 and state.inventories.founder_seed42.reserve == 30 and state.inventories.founder_seed42.reserve_compartments.size() == 2 and int(state.inventories.founder_seed42.reserve_compartments[0]) == 15 and int(state.inventories.founder_seed42.reserve_compartments[1]) == 15 and state.inventories.allocated12 == 12, "founder 42 = 12 + 30 (15 + 15) is unchanged after Tara's harvest")
		"EX-CH04-S10":   # canon order: return in S09, dry warm-up and the twelve-specimen count in S10
			expected = {"E": 18, "A": 7, "H": 6, "C": 8, "R": 16.8}
			_check(state.route.energy == 40 and state.route.provisions == 48 and state.inventories.vault12.stored == 12, "survey return conserves rover and twelve distinct specimens")
		"EX-CH05-S11": expected = {"E": 16, "A": 4.25, "H": 6, "C": 8, "R": 13.5}
		"EX-CH05-S12":
			var cotton: Dictionary = state.plants.filter(func(plant): return plant.individual_id == "COTTON-01")[0]
			_check(cotton.planted_at.begins_with("2046-12-15") and cotton.stage == "seed" and cotton.enclosure == "pressurised_reference_bay", "cotton is physically planted on December 15 in pressure")
			_check(state.inventories.vault12.stored == 11 and state.inventories.cotton_planted == 1 and state.inventories.reserve30 == 30, "cotton uses one vault specimen, with eleven stored and founder thirty separate")
		"EX-CH06-S11": expected = {"E": 7}
		"EX-CH07-S08":
			expected = {"E": 6, "A": 2.5, "H": 1, "C": 3, "R": 9, "Z": 0, "W": 2, "K": 2}
			_check(state.scenario_datetime == "2047-02-16 01:12 UTC", "six storm steps reach February 16 01:12 exactly")
			var samples: Array = state.campaign_ledgers.puzzles["P-14"].samples
			_check(samples.size() == 6 and samples[5].shelter == 6 and samples[5].after.W == 2 and samples[5].before.W == 4, "final drain follows exposure and crates remain installed")
		"EX-CH07-S09":
			var readings: Array = state.campaign_ledgers.puzzles["P-14"].clearance_readings
			_check(readings.size() == 2 and CampaignLedgerSimulation._seconds(readings[1].when) - CampaignLedgerSimulation._seconds(readings[0].when) == 600, "route readings are separated by ten scenario minutes")
		"EX-CH08-S05":
			_check(state.resources.E == 20 and state.resources.A == 8 and state.resources.H == 6 and state.resources.C == 8 and state.resources.R == 18, "confirming the home forecast preserves current reserves")
			for key in {"E": 5, "A": 5.1875, "H": 1, "C": 8, "R": 14.625}:
				var source: Dictionary = {"E": 5, "A": 5.1875, "H": 1, "C": 8, "R": 14.625}
				_check(is_equal_approx(float(state.route.home_forecast[key]), float(source[key])), "home preview forecasts the source endpoint " + key)
		"EX-CH08-S12":
			expected = {"E": 5, "A": 5.1875, "H": 1, "C": 8, "R": 14.625}
			_check(state.route.energy == 4 and state.route.elapsed_hours == 51 and state.route.provisions == 72 and state.route.provisions_remaining == 21, "actual rover return is fourteen minus five minus five with fifty-one of seventy-two hours consumed")
			_check(state.route.home_elapsed_hours == 36 and state.route.crew_home == 5 and state.scenario_datetime == "2047-04-10 06:00 UTC", "home occupancy and final dawn follow the dated 33+3-hour night")
			_check(state.route.local_hops.size() == 4 and state.route.earth_leg == "verified", "three repeaters and Earth leg retain independent verified state")
			_check(state.plants.any(func(plant): return plant.individual_id == "COTTON-01" and plant.alive) and not state.plants.filter(func(plant): return plant.individual_id == "ALO-01")[0].alive, "final cotton lives while original Alo stays archived")
	for key in expected:
		_check(is_equal_approx(float(state.resources[key]), float(expected[key])), id + " source endpoint " + key + " = " + str(expected[key]))

func _render_evidence() -> void:
	var storage = preload("res://tools/support/isolated_storage.gd").new()
	storage.setup("later-ledger-evidence")
	root.size = Vector2i(1280, 720)
	var selected := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-only="):
			selected = arg.trim_prefix("--evidence-only=")
	for id in _evidence_snapshots:
		if not selected.is_empty() and id != selected:
			continue
		var state: Dictionary = _evidence_snapshots[id]
		var runtime := preload("res://scenes/campaign/chapter1_campaign.tscn").instantiate() as Chapter1Campaign
		storage.configure(runtime)
		runtime.initial_snapshot = state
		root.add_child(runtime)
		for i in 12:
			await physics_frame
		_check(runtime._startup_error.is_empty(), "evidence restores the actual campaign " + id)
		var last_action := ""
		for key in state.receipts:
			if String(key).begins_with("extended:"):
				last_action = key
		last_action = {"EX-CH03-S04": "extended:p05_stable_read_5", "EX-CH03-S10": "extended:p06_sleeve_petal", "EX-CH05-S12": "extended:p10_protect_eleven_vault", "EX-CH07-S08": "extended:p14_commit_steps_3_6", "EX-CH08-S12": "extended:p16_save_final_records"}.get(id, last_action)
		var receipt: Dictionary = state.receipts.get(last_action, {})
		var outcome := {"result": receipt.get("reason", "Recorded operation"), "changes": receipt.get("deltas", []), "notes": receipt.get("ledger_summary", [])}
		runtime.hud.panels.bind_query(runtime.query().merged({"outcome": outcome}, true))
		runtime.hud.panels.open_panel("outcome")
		for i in 8:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/M3-80_" + id + ".png"))
		runtime.hud.panels.close_panel()
		runtime.free()
		await process_frame
	storage.cleanup()
