## Chapter 4 puzzles P-07 and P-08 as interactive panels (M3-4P): the answers
## live in data, the gate catalog pre-fills nothing, the model builds the
## player's payload, the ledger accepts the 08 witness and rejects wrong and
## boundary inputs, the whole chapter plays through the model with the real
## route preview and commit, state survives save/reload and retry, and the
## panel's controls, focus, layout and commit flow behave headlessly.
## Windowed evidence: Godot --path game --windowed --resolution 1280x720 --script res://tools/test_chapter4_puzzles.gd -- --evidence
extends SceneTree

const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const RouteScript = preload("res://scripts/missions/extended_campaign_route.gd")
const GateCatalog = preload("res://scripts/missions/extended_gate_catalog.gd")
const LedgerScript = preload("res://scripts/puzzles/extended_puzzle_ledger.gd")
const PuzzleScript = preload("res://scripts/puzzles/chapter4_puzzles.gd")
const Witness = preload("res://tools/support/chapter4_witness.gd")
const ContentScript = preload("res://scripts/content/content_loader.gd")
const PanelScene: PackedScene = preload("res://scenes/ui/chapter4_puzzle_panel.tscn")
const CampaignScene: PackedScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const CH04_SCENES := ["EX-CH04-S01", "EX-CH04-S02", "EX-CH04-S03", "EX-CH04-S04", "EX-CH04-S05", "EX-CH04-S06", "EX-CH04-S07", "EX-CH04-S08", "EX-CH04-S09", "EX-CH04-S10", "EX-CH04-S11", "EX-CH04-S12"]

var storage = preload("res://tools/support/isolated_storage.gd").new()
var checks := 0
var failures := 0
var _entry_state: Dictionary = {}

func _init() -> void:
	if not storage.setup("test_chapter4_puzzles"):
		push_error("Unable to isolate test storage.")
		quit(1)
		return
	storage.prepare_rendering_cache()
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
	print("CHAPTER 4 PUZZLES RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_data_and_catalog() -> void:
	var data := PuzzleScript.data()
	_check(not data.is_empty() and PuzzleScript.rules().get("valid_route", "") == "B" and int(PuzzleScript.rules().get("scanner_threshold", 0)) == 12, "content and answer keys load from data files")
	var catalog_actions: Array = []
	for order in range(1, 13):
		for action in GateCatalog._actions(4, order):
			catalog_actions.append(String(action))
	var step_ids: Array = []
	for k in data.steps.keys():
		step_ids.append(String(k))
	step_ids.sort()
	var expected := catalog_actions.duplicate()
	expected.sort()
	_check(step_ids == expected and step_ids.size() == 45, "every one of the 45 Chapter 4 operations has a step card")
	var content := ContentScript.load_full()
	var kinds_ok := true
	var lines_ok := true
	var polls_ok := true
	for id in data.steps:
		var step: Dictionary = data.steps[id]
		kinds_ok = kinds_ok and PuzzleScript.KINDS.has(String(step.kind)) and data.scenes.has(String(step.scene))
		if step.has("poll") and step.has("no_go_role"):
			polls_ok = polls_ok and (step.poll as Array).has(step.no_go_role)
	for scene_id in data.scenes:
		for clue in data.scenes[scene_id].clues:
			if clue.has("line_id"):
				var line := ContentScript.dialogue_by_id(content, String(clue.line_id))
				lines_ok = lines_ok and not line.is_empty() and String(line.get("scene_id", "")) == scene_id
	_check(kinds_ok, "every step uses a supported kind and names its scene")
	_check(lines_ok, "every clue line id is a canon line of its own scene")
	_check(polls_ok, "every NO-GO role is on its step's poll")
	var defaults_empty := true
	var labels_plain := true
	for scene_id in CH04_SCENES:
		for target in GateCatalog.targets_for_scene(scene_id):
			defaults_empty = defaults_empty and (target.get("payload_defaults", {}) as Dictionary).is_empty()
			labels_plain = labels_plain and not String(target.get("focus_label", "")).begins_with("P0")
	_check(defaults_empty, "the gate catalog pre-fills nothing for Chapter 4")
	_check(labels_plain, "Chapter 4 targets carry plain-words labels")

func _test_validation_witness_wrong_boundary() -> void:
	var all_ok := true
	for id in Witness.SOLUTION:
		var reason := PuzzleScript.validate(String(id), Witness.payload(String(id)))
		if not reason.is_empty():
			print("WITNESS DETAIL ", id, " -> ", reason)
		all_ok = all_ok and reason.is_empty()
	_check(all_ok, "the 08 witness is accepted for all 45 Chapter 4 operations")
	var ledger := LedgerScript.new()
	_check(bool(ledger.preview("P-07", "p07_choose_route_b", {"route": "B"}).accepted), "ledger accepts Route B")
	_check(not bool(ledger.preview("P-07", "p07_choose_route_b", {"route": "A"}).accepted), "ledger rejects Route A")
	_check(not bool(ledger.preview("P-07", "p07_choose_route_b", {"route": "C"}).accepted), "ledger rejects Route C")
	_check(not bool(ledger.preview("P-07", "p07_choose_route_b", {}).accepted), "ledger rejects empty payload")
	var wrong := {
		"p07_choose_route_b": {"route": "A"},
		"p07_verify_slope": {"slope": 19},
		"p07_verify_return_reserve": {"reserve": 24},
		"p07_set_threshold_12": {"reference": 2, "threshold": 10},
		"p07_tag_positive_18": {"reading": 9},
		"p07_tag_positive_19": {"reading": 2},
		"p07_retain_negative_2": {"reading": 18},
		"p08_warm_cold": {"stage": "room"},
		"p08_warm_room": {"stage": "cold"},
		"p08_inventory_12": {"count": 11},
	}
	var wrong_ok := true
	for id in wrong:
		var reason := PuzzleScript.validate(String(id), wrong[id])
		wrong_ok = wrong_ok and not reason.is_empty()
	_check(wrong_ok, "every wrong-but-reasonable answer is rejected with a plain reason")
	_check(PuzzleScript.validate("p07_verify_slope", {"slope": 12}) == "" and PuzzleScript.validate("p07_verify_slope", {"slope": 0}) != "" and PuzzleScript.validate("p07_verify_slope", {"slope": 15}) != "", "the measured Route B slope is 12 degrees, not any value below the design limit")
	_check(PuzzleScript.validate("p07_verify_return_reserve", {"reserve": 40}) == "" and PuzzleScript.validate("p07_verify_return_reserve", {"reserve": 30}) != "" and PuzzleScript.validate("p07_verify_return_reserve", {"reserve": 100}) != "", "the calculated Route B reserve is 40, not any value above the safety minimum")
	_check(not bool(ledger.preview("P-07", "p07_tag_positive_18", {"reading": 19}).accepted) and not bool(ledger.preview("P-07", "p07_tag_positive_19", {"reading": 18}).accepted), "each positive sample must retain its own reading so the survey cannot tag the same reading twice")
	_check(PuzzleScript.validate("p08_inventory_12", {"count": 12}) == "" and PuzzleScript.validate("p08_inventory_12", {"count": 11}) != "", "inventory boundary: 12 specimens accepted, 11 rejected")

func _test_model_selections() -> void:
	var model := PuzzleScript.new()
	_check(not bool(model.payload_for("p07_choose_route_b").accepted), "empty route choice has no payload")
	model.select("p07_choose_route_b", "option", "B")
	_check(bool(model.payload_for("p07_choose_route_b").accepted) and String(model.payload_for("p07_choose_route_b").payload.route) == "B", "selecting Route B builds exact payload")
	model.select("p07_set_threshold_12", "option", "calibrated_12")
	_check(int(model.payload_for("p07_set_threshold_12").payload.threshold) == 12, "threshold 12 builds reference 2 + 10 = 12")
	model.select("p08_inventory_12", "value", 12)
	_check(int(model.payload_for("p08_inventory_12").payload.count) == 12, "number stepper builds inventory count 12")
	var hints: Array = []
	for index in 4:
		hints.append(model.reveal_hint("p07_choose_route_b"))
	_check(bool(hints[0].accepted) and bool(hints[1].accepted) and bool(hints[2].accepted) and not bool(hints[3].accepted), "P-07 hint ladder has 3 tiers and stops")
	_check(bool(model.find_clue("EX-CH04-S03", "c1").accepted) and bool(model.find_clue("EX-CH04-S03", "c1").duplicate), "clues file once")
	_check(bool(model.sign_poll("p07_choose_route_b", "kai").accepted) and not bool(model.sign_poll("p07_choose_route_b", "noor").accepted), "only polled roles can sign")

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
		if scene_id.begins_with("EX-CH04"):
			break
		for target in GateCatalog.targets_for_scene(scene_id):
			var result: Dictionary = route.perform(target.target_id, target.get("payload_defaults", {}))
			ok = ok and bool(result.get("accepted", false))
		var moved: Dictionary = route.advance_scene()
		if bool(moved.get("chapter_complete", false)):
			route.start_at("EX-CH%02d-S01" % (int(scene_id.substr(5, 2)) + 1))
	_check(ok and route.current_scene_id() == "EX-CH04-S01", "the campaign reaches Chapter 4 S01")
	if ok:
		var state: Dictionary = director.snapshot()
		state["route_runtime"] = route.snapshot()
		state["route_runtime"]["chapter"] = 4
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

func _play(route: RefCounted, target_id: String) -> Dictionary:
	var model: RefCounted = route.chapter4()
	_select_witness(model, target_id)
	var attempt: Dictionary = model.payload_for(target_id, route.chapter8_context())
	if not bool(attempt.get("accepted", false)):
		return {"accepted": false, "reason": "model: " + String(attempt.get("reason", ""))}
	var preview: Dictionary = route.chapter4_preview(target_id, attempt.payload)
	if not bool(preview.get("accepted", false)):
		return {"accepted": false, "reason": "preview: " + String(preview.get("reason", ""))}
	var result: Dictionary = route.perform(target_id, attempt.payload)
	result["preview"] = preview
	return result

func _select_witness(model: RefCounted, target_id: String) -> void:
	var step: Dictionary = PuzzleScript.step(target_id)
	var witness: Dictionary = Witness.SOLUTION.get(target_id, {})
	match String(step.kind):
		"choice":
			for option in step.get("options", []):
				if _loose_equal(option.get("payload", {}), witness):
					model.select(target_id, "option", String(option.id))
					return
			if not step.get("options", []).is_empty():
				model.select(target_id, "option", String(step.options[0].id))
		"number":
			var key := String(step.get("payload_key", "value"))
			model.select(target_id, "value", witness.get(key, witness.get("count", 12)))
		"confirm":
			model.select(target_id, "confirmed", true)

func _test_play_through_model() -> void:
	var session := _session()
	var route: RefCounted = session.route
	var director: RefCounted = session.director
	var model: RefCounted = route.chapter4()
	route.start_at("EX-CH04-S03")
	var before: Dictionary = JSON.parse_string(JSON.stringify(director.snapshot()))
	model.select("p07_choose_route_b", "option", "A")
	var route_a_preview: Dictionary = route.chapter4_preview("p07_choose_route_b", model.payload_for("p07_choose_route_b").payload)
	_check(not bool(route_a_preview.accepted) and JSON.parse_string(JSON.stringify(director.snapshot())) == before, "Route A is held by the real preview and the world is unchanged")
	model.reset("p07_choose_route_b")
	route.start_at("EX-CH04-S01")
	var all_ok := true
	var previews_match := true
	for scene_id in CH04_SCENES:
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
				var view: Dictionary = route.chapter4_view(String(target.target_id))
				all_ok = all_ok and bool(view.committed)
		_check(bool(route.gate_status().ready), scene_id + " physical gate is ready from the player's own decisions")
		var moved: Dictionary = route.advance_scene()
		if scene_id == "EX-CH04-S12":
			_check(bool(moved.get("chapter_complete", false)), "Chapter 4 completes from decided payloads")
	_check(all_ok, "every Chapter 4 operation commits from the player's selection")
	_check(previews_match, "every TRY IT preview equals its committed result")
	var state: Dictionary = director.snapshot()
	_check(int(state.route.energy) == 40 and int(state.route.provisions) == 48 and int(state.inventories.vault12.stored) == 12, "the 08 endpoint holds: rover energy 40, provisions 48, vault12 stored 12")

func _test_persistence_and_retry() -> void:
	var session := _session()
	var route: RefCounted = session.route
	var director: RefCounted = session.director
	var model: RefCounted = route.chapter4()
	model.select("p07_compare_prediction", "confirmed", true)
	model.find_clue("EX-CH04-S01", "c1")
	model.reveal_hint("p07_compare_prediction")
	var snapshot: Dictionary = JSON.parse_string(JSON.stringify(route.snapshot()))
	var copy := RouteScript.new(director, true)
	_check(bool(copy.restore(snapshot).accepted) and copy.chapter4().found_clues("EX-CH04-S01") == ["c1"] and copy.chapter4().revealed_hints("p07_compare_prediction").size() == 1, "selections, found clues and hints survive a route save and reload")
	var played := _play(route, "p07_compare_prediction")
	_check(bool(played.accepted), "the first step commits")
	var after_commit: Dictionary = JSON.parse_string(JSON.stringify(director.snapshot()))
	_play(route, "p07_inspect_twelve_descendants")
	var retried: Dictionary = route.retry()
	_check(bool(retried.accepted) and JSON.parse_string(JSON.stringify(director.snapshot())) == after_commit and not route.chapter4_view("p07_inspect_twelve_descendants").committed and route.chapter4_view("p07_compare_prediction").committed, "retry restores the checkpoint before the last lock-in and keeps earlier receipts")

func _test_panel() -> void:
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	var want_evidence := OS.get_cmdline_user_args().has("--evidence")
	var session := _session()
	var route: RefCounted = session.route
	route.start_at("EX-CH04-S03")
	var panel := PanelScene.instantiate() as Chapter4PuzzlePanel
	root.add_child(panel)
	await process_frame
	var committed: Array = []
	panel.commit_requested.connect(func(target_id: String, payload: Dictionary) -> void: committed.append({"target_id": target_id, "payload": payload}))
	panel.open(route, "p07_choose_route_b", {"large_text": false, "timer_free": true})
	await process_frame
	await process_frame
	_check(panel.is_open() and (panel.find_child("Commit", true, false) as Button).disabled, "the panel opens with LOCK IN disabled until a decision is tried")
	panel.dismiss_first_time()
	panel.inspect_clue("c1")
	_check(bool(panel.view().clues[0].found), "INSPECT files a clue to the evidence board")
	panel.choose("option", "A")
	var held := panel.try_it()
	_check(not bool(held.accepted) and (panel.find_child("Commit", true, false) as Button).disabled, "Route A is held and LOCK IN stays disabled")
	if want_evidence:
		await _save_evidence("M3-4P_p07_held.png")
	panel.choose("option", "B")
	var tried := panel.try_it()
	await process_frame
	_check(bool(tried.accepted) and not (panel.find_child("Commit", true, false) as Button).disabled, "Route B accepted try enables LOCK IN")
	if want_evidence:
		await _save_evidence("M3-4P_p07_route_b_100.png")
	panel.request_commit()
	var confirmed := panel.confirm_commit()
	_check(bool(confirmed.accepted) and committed.size() == 1 and committed[0].payload == {"route": "B"} and not panel.is_open(), "CONFIRM emits Route B payload once and closes")

	# Test P-08 warm-up & inventory at 150% large text
	route.start_at("EX-CH04-S08")
	panel.open(route, "p08_warm_cold", {"large_text": true, "timer_free": true})
	for index in 4:
		await process_frame
	var commit := panel.find_child("Commit", true, false) as Control
	_check(commit != null and panel.get_viewport_rect().encloses(commit.get_global_rect()), "the panel and LOCK IN stay on screen at 150% text")
	if want_evidence:
		await _save_evidence("M3-4P_p08_warmup_150.png")
	panel.close()
	panel.free()
	await process_frame

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
	_check(runtime._startup_error.is_empty() and runtime.route.current_scene_id() == "EX-CH04-S01", "the campaign runtime restores at Chapter 4 S01")
	_check(runtime.hud.open_chapter4_panel("p07_compare_prediction"), "the HUD opens the Chapter 4 decision card")
	var panel: Chapter4PuzzlePanel = runtime.hud.chapter4_panel
	_select_witness(runtime.route.chapter4(), "p07_compare_prediction")
	panel.try_it()
	panel.request_commit()
	var target: Node3D = runtime.physical_target("p07_compare_prediction")
	if target != null and runtime._player != null:
		runtime._player.global_position = Vector3(target.global_position.x, 0.0, target.global_position.z + 1.0)
		runtime._player.velocity = Vector3.ZERO
		await physics_frame
		await physics_frame
	panel.confirm_commit()
	await process_frame
	_check(runtime.route.chapter4_view("p07_compare_prediction").committed, "a confirmed card commits the physical operation through the runtime")
	runtime.hud.panels.close_panel()
	runtime.free()
	await process_frame

func _save_evidence(filename: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/" + filename))

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
