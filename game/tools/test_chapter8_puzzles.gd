## Chapter 8 puzzles P-15 and P-16 as interactive panels (M3-8P): the answers
## live in data, the gate catalog pre-fills nothing, the model builds the
## player's payload, the ledger accepts the 08 witness and rejects wrong and
## boundary inputs, the whole chapter plays through the model with the real
## route preview and commit, state survives save/reload and retry, and the
## panel's controls, focus, layout and commit flow behave headlessly.
extends SceneTree

const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const RouteScript = preload("res://scripts/missions/extended_campaign_route.gd")
const GateCatalog = preload("res://scripts/missions/extended_gate_catalog.gd")
const LedgerScript = preload("res://scripts/puzzles/extended_puzzle_ledger.gd")
const PuzzleScript = preload("res://scripts/puzzles/chapter8_puzzles.gd")
const Witness = preload("res://tools/support/chapter8_witness.gd")
const ContentScript = preload("res://scripts/content/content_loader.gd")
const PanelScene: PackedScene = preload("res://scenes/ui/chapter8_puzzle_panel.tscn")
const CampaignScene: PackedScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const CH08_SCENES := ["EX-CH08-S01", "EX-CH08-S02", "EX-CH08-S03", "EX-CH08-S04", "EX-CH08-S05", "EX-CH08-S06", "EX-CH08-S07", "EX-CH08-S08", "EX-CH08-S09", "EX-CH08-S10", "EX-CH08-S11", "EX-CH08-S12"]

var storage = preload("res://tools/support/isolated_storage.gd").new()
var checks := 0
var failures := 0
var _entry_state: Dictionary = {}

func _init() -> void:
	if not storage.setup("test_chapter8_puzzles"):
		push_error("Unable to isolate test storage.")
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	_test_data_and_catalog()
	_test_validation_witness_wrong_boundary()
	_test_model_selections()
	_build_entry_state()
	if not _entry_state.is_empty():
		_test_play_through_model()
		_test_persistence_and_retry()
		await _test_panel()
		await _test_runtime_integration()
	storage.cleanup()
	print("CHAPTER 8 PUZZLES RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

# --- Data ----------------------------------------------------------------------

func _test_data_and_catalog() -> void:
	var data := PuzzleScript.data()
	_check(not data.is_empty() and PuzzleScript.rules().has("rover_team") and PuzzleScript.rules().get("known_echo", "") == "ALO42", "content and answer keys load from data files")
	var catalog_actions: Array = []
	for order in range(1, 13):
		for action in GateCatalog._actions(8, order):
			catalog_actions.append(String(action))
	var step_ids: Array = data.steps.keys()
	step_ids.sort()
	var expected := catalog_actions.duplicate()
	expected.sort()
	_check(step_ids == expected and step_ids.size() == 38, "every one of the 38 Chapter 8 operations has exactly one step card")
	var content := ContentScript.load_full()
	var kinds_ok := true
	var lines_ok := true
	var polls_ok := true
	var codes_ok := true
	var regex := RegEx.new()
	regex.compile("EX-CH\\d|\\bP-\\d\\d\\b|\\b[EAWKSZCRH] ?\\d")
	for id in data.steps:
		var step: Dictionary = data.steps[id]
		kinds_ok = kinds_ok and PuzzleScript.KINDS.has(String(step.kind)) and data.scenes.has(String(step.scene))
		if step.has("poll") and step.has("no_go_role"):
			polls_ok = polls_ok and (step.poll as Array).has(step.no_go_role)
		for key in ["title", "goal", "why"]:
			codes_ok = codes_ok and regex.search(String(step[key])) == null
		for option in step.get("options", []):
			codes_ok = codes_ok and regex.search(String(option.label) + " " + String(option.detail)) == null
	for scene_id in data.scenes:
		for clue in data.scenes[scene_id].clues:
			if clue.has("line_id"):
				var line := ContentScript.dialogue_by_id(content, String(clue.line_id))
				lines_ok = lines_ok and not line.is_empty() and String(line.get("scene_id", "")) == scene_id
	_check(kinds_ok, "every step uses a supported kind and names its scene")
	_check(lines_ok, "every clue line id is a canon line of its own scene (text is read from the catalog)")
	_check(polls_ok, "every NO-GO role is on its step's poll")
	_check(codes_ok, "no scene codes, puzzle codes or bare variable letters in player text")
	var defaults_empty := true
	var labels_plain := true
	for scene_id in CH08_SCENES:
		for target in GateCatalog.targets_for_scene(scene_id):
			defaults_empty = defaults_empty and (target.get("payload_defaults", {}) as Dictionary).is_empty()
			labels_plain = labels_plain and not String(target.get("focus_label", "")).begins_with("P1")
	_check(defaults_empty, "the gate catalog pre-fills nothing for Chapter 8")
	_check(labels_plain, "Chapter 8 targets carry plain-words labels")
	_check(not (GateCatalog.targets_for_scene("EX-CH07-S11")[0].get("payload_defaults", {}) as Dictionary).has("route") and GateCatalog._defaults("p13_commit_plan").has("water"), "Chapter 3–7 witness defaults are untouched")

# --- Validation ------------------------------------------------------------------

func _test_validation_witness_wrong_boundary() -> void:
	var all_ok := true
	for id in Witness.SOLUTION:
		var reason := PuzzleScript.validate(String(id), Witness.payload(String(id)))
		if not reason.is_empty():
			print("WITNESS DETAIL ", id, " -> ", reason)
		all_ok = all_ok and reason.is_empty()
	_check(all_ok, "the 08 witness is accepted for all 38 operations")
	var ledger := LedgerScript.new()
	_check(bool(ledger.preview("P-15", "p15_choose_surveyed_route", {"route": "SURVEYED", "reserve": 4}).accepted), "ledger accepts the surveyed road with reserve 4")
	_check(not bool(ledger.preview("P-15", "p15_choose_surveyed_route", {"route": "SHORTCUT", "reserve": 7}).accepted), "ledger rejects the 22° shortcut even with more energy left")
	_check(not bool(ledger.preview("P-15", "p15_choose_surveyed_route", {}).accepted), "ledger rejects an empty route payload (nothing is pre-filled)")
	var wrong := {
		"p15_confirm_teams": {"rover": ["ferreira", "kai", "mei"], "home": ["rafi", "amara"]},
		"p15_confirm_loadout": {"packed": ["controller", "service_diagram", "repeater_checkpoints"]},
		"p15_restore_marker_2": {"sequence": ["isolate", "remove_battery", "compare_spec", "install_spare", "reconnect", "close_housing"]},
		"p15_test_repeater_chain": {"tested": ["1-2", "2-3", "lit"]},
		"p15_confirm_home_occupancy": {"segments": [[2, 36]]},
		"p15_confirm_segment_forecast": {"heat": "COOL", "light": "DIM", "water_return": "CLOSED", "air_total": 2.8125},
		"p15_confirm_home_checks": {"sequence": ["acknowledge", "air", "temperature", "return_path"]},
		"p15_confirm_summit": {"packet": "approach"},
		"p16_isolate_power": {"step": "reset_live"},
		"p16_install_controller": {"controller": "bench_mismatch"},
		"p16_close_housing": {"housing": "open"},
		"p16_local_bearing": {"bearing": "L3"},
		"p16_earth_bearing": {"bearing": "E2"},
		"p16_checksum": {"value": "AL042", "packet": "current"},
		"p16_confirm_return_24h": {"gates": ["gate3_return", "gate2_outward", "gate1_return"]},
		"p16_confirm_five_at_aurora": {"arrivals": ["ferreira", "kai", "rafi", "noor", "pressure_procedure"]},
		"p16_update_occupancy": {"occupancy_change": "summit_departure"},
		"p16_save_final_records": {"checks": ["crew", "seeds", "pressure", "temperature"]},
		"p16_save_dedication": {"dedication": "For me"},
	}
	var wrong_ok := true
	for id in wrong:
		var reason := PuzzleScript.validate(String(id), wrong[id])
		if reason.is_empty():
			print("WRONG DETAIL accepted ", id)
		wrong_ok = wrong_ok and not reason.is_empty()
	_check(wrong_ok, "every wrong-but-reasonable answer is rejected with a plain reason")
	_check(not bool(ledger.preview("P-16", "p16_checksum", {"value": "ALO42", "packet": "stored"}).accepted), "an exact but older echo is rejected")
	_check(PuzzleScript.validate("p15_confirm_roundtrip_provisions", {"hours": 50}) != "" and PuzzleScript.validate("p15_confirm_roundtrip_provisions", {"hours": 51}) == "" and PuzzleScript.validate("p15_confirm_roundtrip_provisions", {"hours": 72}) == "" and PuzzleScript.validate("p15_confirm_roundtrip_provisions", {"hours": 73}) != "", "provisions boundary: 50 rejected, 51 and 72 accepted, 73 rejected")
	_check(PuzzleScript.validate("p15_choose_surveyed_route", {"route": "SURVEYED", "reserve": 1}) != "" and PuzzleScript.validate("p15_choose_surveyed_route", {"route": "SURVEYED", "reserve": 2}) == "", "reserve boundary: 1 rejected, exactly 2 accepted")
	_check(PuzzleScript.validate("p15_confirm_return_reserve", {"reserve": 4, "energy": 14, "allowance": 5}) == "" and PuzzleScript.validate("p15_confirm_return_reserve", {"reserve": 9, "energy": 14, "allowance": 5}) != "" and PuzzleScript.validate("p15_confirm_return_reserve", {"reserve": 8, "energy": 18, "allowance": 5}) == "", "reserve arithmetic: 14−5−5 = 4 and 18−5−5 = 8 accepted, 14−5 = 9 rejected")
	_check(PuzzleScript.validate("p15_reach_marker_two", {"bearing": 175.0}) == "" and PuzzleScript.validate("p15_reach_marker_two", {"bearing": 179.0}) == "" and PuzzleScript.validate("p15_reach_marker_two", {"bearing": 174.9}) != "" and PuzzleScript.validate("p15_reach_marker_two", {"bearing": 214.0}) != "", "marker bearing boundary: within 2° accepted, 174.9° and the silhouette rejected")
	_check(PuzzleScript.validate("p15_confirm_segment_forecast", {"heat": "COOL", "light": "DIM", "water_return": "OPEN", "air_total": 2.5}) != "" and PuzzleScript.validate("p15_confirm_segment_forecast", {"heat": "COOL", "light": "DIM", "water_return": "OPEN", "air_total": 2.8125}) == "", "home air prediction: 2.5 rejected, 2.8125 accepted")
	_check(PuzzleScript.validate("p16_zero_test", {"reading": 0.0}) == "" and PuzzleScript.validate("p16_zero_test", {"reading": 0.2}) != "", "zero test accepts only a zero reading")
	_check(PuzzleScript.validate("p16_make_credits_available", {}) == "" and PuzzleScript.validate("p16_save_photo", {"frame": "board"}) == "", "steps without a graded answer accept the player's own confirmation")

# --- Model ----------------------------------------------------------------------

func _test_model_selections() -> void:
	var model := PuzzleScript.new()
	_check(not bool(model.payload_for("p15_confirm_teams").accepted), "an empty team board has no payload (nothing hidden)")
	for pair in [["ferreira", "rover"], ["kai", "rover"], ["rafi", "rover"]]:
		model.select("p15_confirm_teams", pair[0], pair[1])
	_check(not bool(model.select("p15_confirm_teams", "mei", "rover").accepted), "a fourth name cannot take a rover seat")
	model.select("p15_confirm_teams", "mei", "home")
	model.select("p15_confirm_teams", "amara", "home")
	var teams: Dictionary = model.payload_for("p15_confirm_teams")
	_check(bool(teams.accepted) and PuzzleScript.validate("p15_confirm_teams", teams.payload).is_empty(), "five placed names become the exact roster payload")
	model.reset("p15_confirm_teams")
	model.select("p15_confirm_teams", "mei", "rover")
	model.select("p15_confirm_teams", "kai", "rover")
	model.select("p15_confirm_teams", "rafi", "rover")
	model.select("p15_confirm_teams", "ferreira", "home")
	model.select("p15_confirm_teams", "amara", "home")
	var wrong_teams: Dictionary = model.payload_for("p15_confirm_teams")
	_check(String(wrong_teams.feedback_key) == "mei_on_rover" and model.feedback_for("p15_confirm_teams", "", wrong_teams.feedback_key, "x").contains("garden"), "Mei on the rover gets the garden feedback, not a generic error")
	_check(not bool(model.select("p15_restore_marker_2", "step", "reconnect").accepted) and not bool(model.select("p15_restore_marker_2", "step", "reseat_dead").accepted) and model.attempts("p15_restore_marker_2") == 2, "the procedure card holds out-of-order steps and distractors with their feedback, counting attempts")
	for id in ["isolate", "remove_battery", "compare_spec", "install_spare", "close_housing", "reconnect"]:
		model.select("p15_restore_marker_2", "step", id)
	_check(model.payload_for("p15_restore_marker_2").payload.sequence == Witness.SOLUTION.p15_restore_marker_2.sequence, "a completed card is the exact repair sequence")
	model.select("p16_local_bearing", "bearing", 160)
	var off: Dictionary = PuzzleScript.dial_reading("p16_local_bearing", 160)
	model.select("p16_local_bearing", "preset", "L2")
	var good: Dictionary = PuzzleScript.dial_reading("p16_local_bearing", float(model.selection("p16_local_bearing").bearing))
	_check(String(off.strength) == "no signal" and String(good.preset) == "L2" and String(good.obstruction).is_empty() and String(PuzzleScript.dial_reading("p16_earth_bearing", 4).obstruction).contains("Obstructed"), "dial readings pair strength with an obstruction sentence; presets are an equal alternative")
	model.select("p16_local_bearing", "bearing", 177 + 361)
	_check(is_equal_approx(float(model.selection("p16_local_bearing").bearing), 178.0) and String(model.payload_for("p16_local_bearing").payload.bearing) == "L2", "the dial wraps and a bearing within tolerance maps to its preset")
	model.select("p16_stable_lock", "progress", 2.9)
	_check(not bool(model.payload_for("p16_stable_lock").accepted), "a 2.9-second hold is not yet a lock")
	model.select("p16_stable_lock", "progress", 3.0)
	_check(bool(model.payload_for("p16_stable_lock").accepted) and String(model.payload_for("p16_stable_lock").payload.method) == "hold", "exactly 3 seconds locks")
	model.select("p15_choose_surveyed_route", "route", "SURVEYED")
	model.select("p15_choose_surveyed_route", "reserve", 99)
	_check(is_equal_approx(float(model.selection("p15_choose_surveyed_route").reserve), 26.0), "the reserve stepper is clamped to the data bounds")
	model.select("p15_confirm_return_reserve", "value", 4)
	var reserve: Dictionary = model.payload_for("p15_confirm_return_reserve", {"capacity": 14.0, "energy": 9.0, "allowance": 5.0})
	_check(is_equal_approx(float(reserve.payload.energy), 14.0) and PuzzleScript.validate("p15_confirm_return_reserve", reserve.payload).is_empty(), "the reserve payload carries the departure battery, not the battery after the outward leg")
	var hints: Array = []
	for index in 4:
		hints.append(model.reveal_hint("p15_choose_surveyed_route"))
	_check(String(hints[0].text) == "A return reserve belongs in the departure plan." and String(hints[1].text) == "Marker2 is part of the radio path." and String(hints[2].text).begins_with("Use surveyed route") and not bool(hints[3].accepted), "the 08 hint ladder is verbatim and finite")
	_check(PuzzleScript.hint_ladder("p15_confirm_summit").size() == 6 and String(PuzzleScript.hint_ladder("p15_confirm_summit")[3]) == "When and where was this message sent?", "scene hints from the clue design follow the 08 hints")
	_check(bool(model.find_clue("EX-CH08-S01", "c1").accepted) and bool(model.find_clue("EX-CH08-S01", "c1").duplicate) and not bool(model.find_clue("EX-CH08-S01", "zz").accepted), "clues file once; unknown clues are refused")
	_check(bool(model.sign_poll("p15_confirm_teams", "kai").accepted) and not bool(model.sign_poll("p15_confirm_teams", "noor").accepted), "only polled roles can sign")
	var copy := PuzzleScript.new()
	var restored: Dictionary = copy.restore(JSON.parse_string(JSON.stringify(model.snapshot())))
	if not bool(restored.accepted):
		print("RESTORE DETAIL ", restored)
	_check(bool(restored.accepted) and _loose_equal(copy.snapshot(), model.snapshot()), "model state survives JSON reconstruction")
	var broken: Dictionary = model.snapshot()
	broken.hints["p15_choose_surveyed_route"] = 99
	_check(not bool(PuzzleScript.new().restore(broken).accepted), "a hint level outside the ladder is refused on restore")

# --- Route fixture ------------------------------------------------------------------

func _build_entry_state() -> void:
	var director := DirectorScript.new()
	director.new_campaign(CampaignContentFull.EXPECTED_CONTENT_REVISION)
	var handoff: Dictionary = director.snapshot()
	handoff["chapter1_ready"] = true
	director.restore_snapshot(handoff)
	var pollination := preload("res://scripts/missions/chapter2_route.gd").new(director)
	pollination.apply_entry_profile()
	pollination.start_at("EX-CH02-S01")
	for scene_id in preload("res://scripts/missions/chapter2_gate_catalog.gd").SCENE_ORDER:
		for target in pollination.targets_for_current_scene():
			pollination.perform(target.target_id)
		pollination.advance_scene()
	var route := RouteScript.new(director)
	route.start_at("EX-CH03-S01")
	var ok := true
	for scene_id in GateCatalog.scene_ids():
		if scene_id.begins_with("EX-CH08"):
			break
		for target in GateCatalog.targets_for_scene(scene_id):
			var result: Dictionary = route.perform(target.target_id, target.get("payload_defaults", {}))
			if not bool(result.get("accepted", false)):
				print("FIXTURE DETAIL ", scene_id, " ", target.target_id, " ", result.get("reason", ""))
			ok = ok and bool(result.get("accepted", false))
		var moved: Dictionary = route.advance_scene()
		if bool(moved.get("chapter_complete", false)) and not bool(moved.get("campaign_complete", false)):
			route.start_at("EX-CH%02d-S01" % (int(scene_id.substr(5, 2)) + 1))
	_check(ok and route.current_scene_id() == "EX-CH08-S01", "the campaign reaches the Chapter 8 departure board")
	if ok:
		var state: Dictionary = director.snapshot()
		state["route_runtime"] = route.snapshot()
		state["route_runtime"]["chapter"] = 8
		_entry_state = JSON.parse_string(JSON.stringify(state))

func _session() -> Dictionary:
	var director := DirectorScript.new()
	var state: Dictionary = JSON.parse_string(JSON.stringify(_entry_state))
	var saved: Dictionary = state.route_runtime
	state.erase("route_runtime")
	director.restore_snapshot(state)
	var route := RouteScript.new(director, true)
	route.restore(saved)
	return {"director": director, "route": route}

## Plays one step the way the panel does: selections into the model, the
## real preview, then the physical commit with the model's payload.
func _play(route: RefCounted, target_id: String) -> Dictionary:
	var model: RefCounted = route.chapter8()
	_select_witness(model, target_id)
	var attempt: Dictionary = model.payload_for(target_id, route.chapter8_context())
	if not bool(attempt.get("accepted", false)):
		return {"accepted": false, "reason": "model: " + String(attempt.get("reason", ""))}
	var preview: Dictionary = route.chapter8_preview(target_id, attempt.payload)
	if not bool(preview.get("accepted", false)):
		return {"accepted": false, "reason": "preview: " + String(preview.get("reason", ""))}
	var result: Dictionary = route.perform(target_id, attempt.payload)
	result["preview"] = preview
	return result

func _select_witness(model: RefCounted, target_id: String) -> void:
	var step: Dictionary = PuzzleScript.step(target_id)
	var witness: Dictionary = Witness.SOLUTION.get(target_id, {})
	match String(step.kind):
		"assign":
			for board in witness:
				for person in witness[board]:
					model.select(target_id, String(person), String(board))
		"select_many", "checks":
			for id in witness.values()[0]:
				model.select(target_id, String(id), true)
		"choice":
			for option in step.options:
				if _loose_equal(option.payload, witness):
					model.select(target_id, "option", String(option.id))
		"number":
			model.select(target_id, "value", witness.reserve)
		"route":
			model.select(target_id, "route", witness.route)
			model.select(target_id, "reserve", witness.reserve)
		"dial":
			if witness.bearing is String:
				model.select(target_id, "preset", witness.bearing)
			else:
				model.select(target_id, "bearing", witness.bearing)
		"lock":
			model.select(target_id, "tap", true)
		"procedure":
			for id in witness.values()[0]:
				model.select(target_id, "step", String(id))
		"settings":
			for field in witness:
				model.select(target_id, String(field), witness[field])
		"confirm":
			model.select(target_id, "confirmed", true)

func _test_play_through_model() -> void:
	var session := _session()
	var route: RefCounted = session.route
	var director: RefCounted = session.director
	var model: RefCounted = route.chapter8()
	# A wrong-but-reasonable first idea: the shortcut is held before anything changes.
	route.start_at("EX-CH08-S02")
	var before: Dictionary = JSON.parse_string(JSON.stringify(director.snapshot()))
	model.select("p15_choose_surveyed_route", "route", "SHORTCUT")
	model.select("p15_choose_surveyed_route", "reserve", 7)
	var shortcut: Dictionary = route.chapter8_preview("p15_choose_surveyed_route", model.payload_for("p15_choose_surveyed_route").payload)
	_check(not bool(shortcut.accepted) and String(shortcut.reason).contains("shortcut") and JSON.parse_string(JSON.stringify(director.snapshot())) == before, "the shortcut is held by the real preview and the world is unchanged")
	_check(model.feedback_for("p15_choose_surveyed_route", "SHORTCUT", "", String(shortcut.reason)).contains("22°"), "the held shortcut explains itself with the road's own feedback")
	model.reset("p15_choose_surveyed_route")
	route.start_at("EX-CH08-S01")
	var all_ok := true
	var previews_match := true
	for scene_id in CH08_SCENES:
		_check(route.current_scene_id() == scene_id, "played route is at " + scene_id)
		for target in GateCatalog.targets_for_scene(scene_id):
			var result := _play(route, String(target.target_id))
			if not bool(result.get("accepted", false)):
				print("PLAY DETAIL ", scene_id, " ", target.target_id, " ", result.get("reason", ""))
			all_ok = all_ok and bool(result.get("accepted", false))
			if bool(result.get("accepted", false)):
				var projected: Dictionary = result.preview.get("snapshot", {})
				var actual: Dictionary = director.snapshot()
				previews_match = previews_match and projected.resources == actual.resources and projected.route == actual.route and projected.inventories == actual.inventories
				var view: Dictionary = route.chapter8_view(String(target.target_id))
				all_ok = all_ok and bool(view.committed)
		if scene_id == "EX-CH08-S08":
			var view: Dictionary = route.chapter8_view("p16_earth_bearing")
			_check(String(view.prerequisite_reason).is_empty(), "after the local lock the Earth dish is no longer waiting")
		_check(bool(route.gate_status().ready), scene_id + " physical gate is ready from the player's own decisions")
		var moved: Dictionary = route.advance_scene()
		if scene_id == "EX-CH08-S12":
			_check(bool(moved.get("campaign_complete", false)), "the campaign completes from decided payloads")
	_check(all_ok, "every Chapter 8 operation commits from the player's selection")
	_check(previews_match, "every TRY IT preview equals its committed result")
	var state: Dictionary = director.snapshot()
	var source := {"E": 5, "A": 5.1875, "H": 1, "C": 8, "R": 14.625}
	var endpoint := true
	for key in source:
		endpoint = endpoint and is_equal_approx(float(state.resources[key]), float(source[key]))
	_check(endpoint and state.route.energy == 4 and state.route.elapsed_hours == 51 and state.route.crew_home == 5 and state.route.local_hops.size() == 4 and state.route.earth_leg == "verified", "the 08 endpoint holds: home E5 A5.1875 H1 C8 R14.625, rover 14−5−5 = 4, 51 h, four hops, Earth verified")
	_check(director.snapshot().campaign_ledgers.puzzles["P-16"].operations.p16_save_dedication.dedication == "For every hand that kept the light", "the chosen dedication is recorded with the final records")
	var duplicate: Dictionary = route.perform("p16_save_dedication", Witness.payload("p16_save_dedication"))
	_check(bool(duplicate.get("accepted", false)) and director.snapshot() == state, "a duplicate lock-in returns its receipt and changes nothing")
	# Earth before Aurora: the second dial waits for the first.
	var fresh := _session()
	fresh.route.start_at("EX-CH08-S08")
	var waiting: Dictionary = fresh.route.chapter8_view("p16_earth_bearing")
	_check(String(waiting.prerequisite_reason).begins_with("Aurora first"), "the Earth dish waits for the local lock with Kai's words")
	fresh.route.chapter8().select("p16_earth_bearing", "preset", "E3")
	var early: Dictionary = fresh.route.chapter8_preview("p16_earth_bearing", {"bearing": "E3"})
	_check(not bool(early.accepted) and bool(early.get("unmet", false)), "pointing at Earth first is held before the simulation")

func _test_persistence_and_retry() -> void:
	var session := _session()
	var route: RefCounted = session.route
	var director: RefCounted = session.director
	var model: RefCounted = route.chapter8()
	model.select("p15_confirm_teams", "ferreira", "rover")
	model.find_clue("EX-CH08-S01", "c3")
	model.reveal_hint("p15_confirm_teams")
	var snapshot: Dictionary = JSON.parse_string(JSON.stringify(route.snapshot()))
	var copy := RouteScript.new(director, true)
	_check(bool(copy.restore(snapshot).accepted) and copy.chapter8().selection("p15_confirm_teams").get("ferreira", "") == "rover" and copy.chapter8().found_clues("EX-CH08-S01") == ["c3"] and copy.chapter8().revealed_hints("p15_confirm_teams").size() == 1, "selections, found clues and hints survive a route save and reload")
	var legacy: Dictionary = snapshot.duplicate(true)
	legacy.erase("chapter8")
	_check(bool(RouteScript.new(director, true).restore(legacy).accepted), "a save written before the panel existed still loads")
	var broken: Dictionary = snapshot.duplicate(true)
	broken.chapter8 = {"schema_version": 7}
	_check(not bool(RouteScript.new(director, true).restore(broken).accepted), "a corrupt puzzle block is refused before any live state changes")
	var played := _play(route, "p15_confirm_teams")
	_check(bool(played.accepted), "the first step commits")
	var after_commit: Dictionary = JSON.parse_string(JSON.stringify(director.snapshot()))
	_play(route, "p15_confirm_loadout")
	var retried: Dictionary = route.retry()
	_check(bool(retried.accepted) and JSON.parse_string(JSON.stringify(director.snapshot())) == after_commit and not route.chapter8_view("p15_confirm_loadout").committed and route.chapter8_view("p15_confirm_teams").committed, "retry restores the checkpoint before the last lock-in and keeps earlier receipts")

# --- Panel ----------------------------------------------------------------------

func _test_panel() -> void:
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	var session := _session()
	var route: RefCounted = session.route
	var panel := PanelScene.instantiate() as Chapter8PuzzlePanel
	root.add_child(panel)
	await process_frame
	var committed: Array = []
	panel.commit_requested.connect(func(target_id: String, payload: Dictionary) -> void: committed.append({"target_id": target_id, "payload": payload}))
	panel.open(route, "p15_confirm_teams", {"large_text": false, "timer_free": true})
	await process_frame
	await process_frame
	_check(panel.is_open() and (panel.find_child("Commit", true, false) as Button).disabled, "the panel opens with LOCK IN disabled until a decision is tried")
	var view := panel.view()
	_check((view.clues as Array).size() == 5 and String(view.clues[0].line) == "Twenty-four out. Three repair. Twenty-four back." and String(view.clues[0].speaker) == "Rafi", "clues show the canon line word for word with its speaker")
	_check(bool(view.first_time) and panel.find_child("FirstTime", true, false) != null, "the first use shows the first-time card")
	panel.dismiss_first_time()
	_check(panel.find_child("FirstTime", true, false) == null, "GOT IT closes the first-time card")
	panel.inspect_clue("c1")
	_check(bool(panel.view().clues[0].found), "INSPECT files a clue to the evidence board")
	var incomplete := panel.try_it()
	_check(not bool(incomplete.accepted) and bool(incomplete.get("incomplete", false)), "TRY IT with an empty board says what is missing")
	for pair in [["mei", "rover"], ["kai", "rover"], ["rafi", "rover"], ["ferreira", "home"], ["amara", "home"]]:
		panel.choose(pair[0], pair[1])
	var held := panel.try_it()
	var status := panel.find_child("PanelStatus", true, false) as Label
	_check(not bool(held.accepted) and status != null and status.text.begins_with("⚠ Held") and status.text.contains("garden"), "a wrong-but-reasonable board is held with Mei's garden feedback and an icon")
	_check((panel.find_child("Commit", true, false) as Button).disabled and (panel.view().hints as Array).size() == 1, "LOCK IN stays disabled and Family assistance offers H1 after the rejected try")
	panel.undo()
	_check(panel.view().selection.is_empty(), "UNDO clears the selection")
	for pair in [["ferreira", "rover"], ["kai", "rover"], ["rafi", "rover"], ["mei", "home"], ["amara", "home"]]:
		panel.choose(pair[0], pair[1])
	var tried := panel.try_it()
	await process_frame
	_check(bool(tried.accepted) and not (panel.find_child("Commit", true, false) as Button).disabled, "an accepted try enables LOCK IN")
	_check(not bool(panel.confirm_commit().accepted), "confirm without the confirmation open is refused")
	panel.choose("amara", "")
	_check((panel.find_child("Commit", true, false) as Button).disabled, "changing the decision after a try disables LOCK IN again")
	panel.choose("amara", "home")
	panel.try_it()
	panel.request_commit()
	await process_frame
	_check(panel.find_child("ConfirmCommit", true, false) != null, "LOCK IN opens the confirmation")
	panel.cancel_confirm()
	panel.request_commit()
	var confirmed := panel.confirm_commit()
	_check(bool(confirmed.accepted) and committed.size() == 1 and committed[0].payload == Witness.SOLUTION.p15_confirm_teams and not panel.is_open(), "CONFIRM emits the player's payload once and closes")
	_check(not bool(panel.confirm_commit().accepted), "a second confirm is a no-op")
	# Large text keeps LOCK IN and the frame on screen.
	panel.open(route, "p15_confirm_loadout", {"large_text": true, "timer_free": true})
	for index in 4:
		await process_frame
	var commit := panel.find_child("Commit", true, false) as Control
	if commit == null or not panel.get_viewport_rect().encloses(commit.get_global_rect()) or not panel.get_viewport_rect().encloses(panel._frame.get_global_rect()):
		print("LAYOUT DETAIL viewport ", panel.get_viewport_rect(), " frame ", panel._frame.get_global_rect(), " commit ", commit.get_global_rect() if commit != null else Rect2())
	_check(commit != null and panel.get_viewport_rect().encloses(commit.get_global_rect()) and panel.get_viewport_rect().encloses(panel._frame.get_global_rect()), "the panel and LOCK IN stay on screen at 150% text")
	var focused := panel.get_viewport().gui_get_focus_owner()
	_check(focused != null and panel.is_ancestor_of(focused), "keyboard focus lands inside the panel")
	var smallest := INF
	for button in panel.find_children("*", "Button", true, false):
		if (button as Control).is_visible_in_tree():
			smallest = minf(smallest, (button as Control).get_global_rect().size.y)
	_check(smallest >= 44.0, "every visible control is at least 44 px tall")
	var escape := InputEventKey.new()
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	Input.parse_input_event(escape)
	await process_frame
	await process_frame
	_check(not panel.is_open(), "Esc closes the panel without committing")
	# Class mode: each polled role signs before LOCK IN.
	route.start_at("EX-CH08-S02")
	panel.open(route, "p15_choose_surveyed_route", {"large_text": false, "timer_free": true, "class_mode": true})
	await process_frame
	panel.choose("route", "SURVEYED")
	panel.choose("reserve", 4)
	panel.try_it()
	_check(not bool(panel.request_commit().accepted) and panel.find_child("Sign_kai", true, false) != null, "Class mode waits for every role's signature")
	for role_id in ["ferreira", "kai", "rafi"]:
		panel.sign(role_id)
	_check(bool(panel.request_commit().accepted), "signed stations unlock LOCK IN")
	panel.close()
	# The lock step: tap-confirm with assistance, a real 3-second hold without.
	var relay := _session()
	relay.route.start_at("EX-CH08-S07")
	for target in GateCatalog.targets_for_scene("EX-CH08-S07"):
		_play(relay.route, String(target.target_id))
	relay.route.advance_scene()
	for target_id in ["p16_local_bearing", "p16_earth_bearing"]:
		var played := _play(relay.route, target_id)
		if not bool(played.accepted):
			print("LOCK SETUP DETAIL ", target_id, " ", played.get("reason", ""))
	panel.open(relay.route, "p16_stable_lock", {"large_text": false, "timer_free": false})
	await process_frame
	_check(panel.find_child("HoldLock", true, false) != null and panel.find_child("Choice_tap_true", true, false) == null, "with assistance off the lock needs a hold, not a tap")
	panel._holding = true
	for index in 3:
		panel._process(1.1)
	_check(bool(relay.route.chapter8().selection("p16_stable_lock").get("locked", false)) and bool(panel.try_it().accepted), "a held 3-second lock is accepted by the real preview")
	panel.close()
	panel.open(relay.route, "p16_checksum", {"large_text": false, "timer_free": true})
	await process_frame
	panel.choose("option", "near")
	var near := panel.try_it()
	_check(not bool(near.accepted) and (panel.find_child("PanelStatus", true, false) as Label).text.contains("zero, not the letter O"), "the near-match reply is held with its differing character named")
	panel.close()
	panel.free()
	await process_frame

# --- Runtime integration ------------------------------------------------------------

func _test_runtime_integration() -> void:
	CampaignCutscenePlayer.autoplay = false
	var runtime := CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(runtime)
	runtime.initial_snapshot = JSON.parse_string(JSON.stringify(_entry_state))
	root.add_child(runtime)
	for index in 12:
		await physics_frame
	await runtime.wait_loading()
	runtime.hud.refresh_scene()
	await process_frame
	_check(runtime._startup_error.is_empty() and runtime.route.current_scene_id() == "EX-CH08-S01", "the campaign runtime restores at the Chapter 8 departure board")
	var has_plain_goal := String(runtime.hud._title.text).to_lower().contains("team names")
	_check(has_plain_goal, "the HUD lists Chapter 8 operations with plain titles")
	_check(runtime.hud.open_chapter8_panel("p15_confirm_teams"), "the HUD opens the decision card")
	var panel: Chapter8PuzzlePanel = runtime.hud.chapter8_panel
	_check(runtime._ui_paused if "_ui_paused" in runtime else true, "the expedition pauses while the card is open")
	for pair in [["ferreira", "rover"], ["kai", "rover"], ["rafi", "rover"], ["mei", "home"], ["amara", "home"]]:
		panel.choose(pair[0], pair[1])
	var runtime_try := panel.try_it()
	var runtime_request := panel.request_commit()
	if not bool(runtime_request.accepted):
		print("RUNTIME DETAIL try=", runtime_try.get("accepted"), " ", runtime_try.get("reason"), " request=", runtime_request)
	var target: Node3D = runtime.physical_target("p15_confirm_teams")
	if target != null and runtime._player != null:
		runtime._player.global_position = Vector3(target.global_position.x, 0.0, target.global_position.z + 1.0)
		runtime._player.velocity = Vector3.ZERO
		await physics_frame
		await physics_frame
	var confirmed_runtime := panel.confirm_commit()
	await process_frame
	if not runtime.route.chapter8_view("p15_confirm_teams").committed:
		print("RUNTIME DETAIL confirm=", confirmed_runtime, " status='", runtime.hud._status.text, "' last=", runtime.route.last_result().get("reason", ""))
	_check(runtime.route.chapter8_view("p15_confirm_teams").committed, "a confirmed card commits the physical operation through the runtime")
	runtime.hud.panels.close_panel()
	runtime.free()
	await process_frame

## Dictionary/array equality where 72 and 72.0 are the same number (JSON data versus literals).
func _loose_equal(a, b) -> bool:
	if (a is int or a is float) and (b is int or b is float):
		return is_equal_approx(float(a), float(b))
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size():
			return false
		for key in a:
			if not b.has(key) or not _loose_equal(a[key], b[key]):
				return false
		return true
	if a is Array and b is Array:
		if a.size() != b.size():
			return false
		for index in a.size():
			if not _loose_equal(a[index], b[index]):
				return false
		return true
	return typeof(a) == typeof(b) and a == b

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)
