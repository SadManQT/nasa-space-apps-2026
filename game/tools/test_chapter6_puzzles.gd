## Chapter 6 puzzles P-11 and P-12 as interactive panels (M3-6P): the answers
## live in data, the gate catalog pre-fills nothing, the model builds the
## player's payload, the ledger accepts the 08 witness and rejects wrong and
## boundary inputs, the whole chapter plays through the model with the real
## route preview and commit, state survives save/reload and retry, and the
## panel's controls, focus, layout and commit flow behave headlessly.
## Windowed evidence: Godot --path game --windowed --resolution 1280x720 --script res://tools/test_chapter6_puzzles.gd -- --evidence
extends SceneTree

const PuzzleData = preload("res://scripts/puzzles/puzzle_data.gd")

const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const RouteScript = preload("res://scripts/missions/extended_campaign_route.gd")
const GateCatalog = preload("res://scripts/missions/extended_gate_catalog.gd")
const LedgerScript = preload("res://scripts/puzzles/extended_puzzle_ledger.gd")
const PuzzleScript = preload("res://scripts/puzzles/chapter6_puzzles.gd")
const Witness4 = preload("res://tools/support/chapter4_witness.gd")
const Witness = preload("res://tools/support/chapter6_witness.gd")
const ContentScript = preload("res://scripts/content/content_loader.gd")
const PanelScene: PackedScene = preload("res://scenes/ui/chapter6_puzzle_panel.tscn")
const CampaignScene: PackedScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const CH06_SCENES := ["EX-CH06-S01", "EX-CH06-S02", "EX-CH06-S03", "EX-CH06-S04", "EX-CH06-S05", "EX-CH06-S06", "EX-CH06-S07", "EX-CH06-S08", "EX-CH06-S09", "EX-CH06-S10", "EX-CH06-S11", "EX-CH06-S12"]

var storage = preload("res://tools/support/isolated_storage.gd").new()
var checks := 0
var failures := 0
var _entry_state: Dictionary = {}

func _init() -> void:
	if not storage.setup("test_chapter6_puzzles"):
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
	print("CHAPTER 6 PUZZLES RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_data_and_catalog() -> void:
	var data := PuzzleScript.data()
	_check(not data.is_empty() and int(PuzzleScript.rules().get("eclipse_allocation_limit", 0)) == 7 and (PuzzleScript.rules().get("feeder_reset_sequence", []) as Array).size() == 5, "content and answer keys load from data files")
	var catalog_actions: Array = []
	for order in range(1, 13):
		for action in GateCatalog._actions(6, order):
			catalog_actions.append(String(action))
	var step_ids: Array = []
	for k in data.steps.keys():
		step_ids.append(String(k))
	step_ids.sort()
	var expected := catalog_actions.duplicate()
	expected.sort()
	_check(step_ids == expected and step_ids.size() == 29, "every one of the 29 Chapter 6 operations has a step card")
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
	for scene_id in CH06_SCENES:
		for target in GateCatalog.targets_for_scene(scene_id):
			defaults_empty = defaults_empty and (target.get("payload_defaults", {}) as Dictionary).is_empty()
			labels_plain = labels_plain and not String(target.get("focus_label", "")).begins_with("P1")
	_check(defaults_empty, "the gate catalog pre-fills nothing for Chapter 6")
	_check(labels_plain, "Chapter 6 targets carry plain-words labels")

func _test_validation_witness_wrong_boundary() -> void:
	var all_ok := true
	for id in Witness.SOLUTION:
		var reason := PuzzleScript.validate(String(id), Witness.payload(String(id)))
		if not reason.is_empty():
			print("WITNESS DETAIL ", id, " -> ", reason)
		all_ok = all_ok and reason.is_empty()
	_check(all_ok, "the 08 witness is accepted for all 29 Chapter 6 operations")
	var ledger := LedgerScript.new()
	_check(bool(ledger.preview("P-11", "p11_commit_allocation", {"total": 7, "essentials": true, "pump": true, "camera": true}).accepted), "ledger accepts 7-unit eclipse allocation")
	_check(not bool(ledger.preview("P-11", "p11_commit_allocation", {"total": 9, "essentials": true, "pump": true, "camera": true, "floods": true}).accepted), "ledger rejects 9-unit allocation with decorative floods")
	_check(not bool(ledger.preview("P-12", "p12_reset_sequence", {"sequence": ["reset", "isolate", "zero", "reconnect", "camera_test"]}).accepted), "ledger rejects live reset before isolation")
	_check(not bool(ledger.preview("P-11", "p11_commit_allocation", {}).accepted), "ledger rejects empty allocation payload")

func _test_model_selections() -> void:
	var model := PuzzleScript.new()
	_check(not bool(model.payload_for("p11_commit_allocation").accepted), "empty allocation has no payload")
	model.select("p11_commit_allocation", "option", "protected_seven")
	_check(bool(model.payload_for("p11_commit_allocation").accepted) and int(model.payload_for("p11_commit_allocation").payload.total) == 7, "selecting 7-unit allocation builds exact payload")
	_check(not bool(model.select("p12_reset_sequence", "step", "reset").accepted) and not bool(model.select("p12_reset_sequence", "step", "trip_main_bus").accepted) and model.attempts("p12_reset_sequence") == 2, "P-12 procedure card holds out-of-order steps and distractors")
	for step_id in ["isolate", "zero", "reset", "reconnect", "camera_test"]:
		model.select("p12_reset_sequence", "step", step_id)
	_check(model.payload_for("p12_reset_sequence").payload.sequence == ["isolate", "zero", "reset", "reconnect", "camera_test"], "completed P-12 sequence matches 5-step reset")
	var hints: Array = []
	for index in 4:
		hints.append(model.reveal_hint("p11_commit_allocation"))
	_check(bool(hints[0].accepted) and bool(hints[1].accepted) and bool(hints[2].accepted) and not bool(hints[3].accepted), "P-11 hint ladder has 3 tiers and stops")

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
		if scene_id.begins_with("EX-CH06"):
			break
		for target in GateCatalog.targets_for_scene(scene_id):
			var payload: Dictionary = target.get("payload_defaults", {}).duplicate(true) if target.get("payload_defaults", {}) is Dictionary else {}
			if payload.is_empty():
				payload = PuzzleData.gate_payload(String(target.get("puzzle_action", "")))
			payload = Witness4.payload(String(target.target_id), director.snapshot(), payload)
			var result: Dictionary = route.perform(target.target_id, payload)
			ok = ok and bool(result.get("accepted", false))
		var moved: Dictionary = route.advance_scene()
		if bool(moved.get("chapter_complete", false)):
			route.start_at("EX-CH%02d-S01" % (int(scene_id.substr(5, 2)) + 1))
	_check(ok and route.current_scene_id() == "EX-CH06-S01", "the campaign reaches Chapter 6 S01")
	if ok:
		var state: Dictionary = director.snapshot()
		state["route_runtime"] = route.snapshot()
		state["route_runtime"]["chapter"] = 6
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
	var model: RefCounted = route.chapter6()
	_select_witness(model, target_id)
	var attempt: Dictionary = model.payload_for(target_id, route.chapter8_context())
	if not bool(attempt.get("accepted", false)):
		return {"accepted": false, "reason": "model: " + String(attempt.get("reason", ""))}
	var preview: Dictionary = route.chapter6_preview(target_id, attempt.payload)
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
		"procedure":
			for id in witness.get("sequence", []):
				model.select(target_id, "step", String(id))
		"confirm":
			model.select(target_id, "confirmed", true)

func _test_play_through_model() -> void:
	var session := _session()
	var route: RefCounted = session.route
	var director: RefCounted = session.director
	var model: RefCounted = route.chapter6()
	route.start_at("EX-CH06-S03")
	var before: Dictionary = JSON.parse_string(JSON.stringify(director.snapshot()))
	model.select("p11_commit_allocation", "option", "floods_overspend")
	var held_preview: Dictionary = route.chapter6_preview("p11_commit_allocation", model.payload_for("p11_commit_allocation").payload)
	_check(not bool(held_preview.accepted) and JSON.parse_string(JSON.stringify(director.snapshot())) == before, "10-unit flood allocation is held by the real preview and the world is unchanged")
	model.reset("p11_commit_allocation")
	route.start_at("EX-CH06-S01")
	var all_ok := true
	var previews_match := true
	for scene_id in CH06_SCENES:
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
				var view: Dictionary = route.chapter6_view(String(target.target_id))
				all_ok = all_ok and bool(view.committed)
		_check(bool(route.gate_status().ready), scene_id + " physical gate is ready from the player's own decisions")
		var moved: Dictionary = route.advance_scene()
		if scene_id == "EX-CH06-S12":
			_check(bool(moved.get("chapter_complete", false)), "Chapter 6 completes from decided payloads")
	_check(all_ok, "every Chapter 6 operation commits from the player's selection")
	_check(previews_match, "every TRY IT preview equals its committed result")
	var state: Dictionary = director.snapshot()
	_check(is_equal_approx(float(state.resources.E), 7.0), "the 08 endpoint holds: post-eclipse battery reserve E = 7")

func _test_persistence_and_retry() -> void:
	var session := _session()
	var route: RefCounted = session.route
	var director: RefCounted = session.director
	var model: RefCounted = route.chapter6()
	model.select("p11_charge_hand_light", "confirmed", true)
	model.find_clue("EX-CH06-S01", "c1")
	model.reveal_hint("p11_charge_hand_light")
	var snapshot: Dictionary = JSON.parse_string(JSON.stringify(route.snapshot()))
	var copy := RouteScript.new(director, true)
	_check(bool(copy.restore(snapshot).accepted) and copy.chapter6().found_clues("EX-CH06-S01") == ["c1"] and copy.chapter6().revealed_hints("p11_charge_hand_light").size() == 1, "selections, found clues and hints survive a route save and reload")
	var played := _play(route, "p11_charge_hand_light")
	_check(bool(played.accepted), "the first step commits")
	var after_commit: Dictionary = JSON.parse_string(JSON.stringify(director.snapshot()))
	_play(route, "p11_assign_companion")
	var retried: Dictionary = route.retry()
	_check(bool(retried.accepted) and JSON.parse_string(JSON.stringify(director.snapshot())) == after_commit and not route.chapter6_view("p11_assign_companion").committed and route.chapter6_view("p11_charge_hand_light").committed, "retry restores the checkpoint before the last lock-in and keeps earlier receipts")

func _test_panel() -> void:
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	var want_evidence := OS.get_cmdline_user_args().has("--evidence")
	var session := _session()
	var route: RefCounted = session.route
	route.start_at("EX-CH06-S03")
	var panel := PanelScene.instantiate() as Chapter6PuzzlePanel
	root.add_child(panel)
	await process_frame
	var committed: Array = []
	panel.commit_requested.connect(func(target_id: String, payload: Dictionary) -> void: committed.append({"target_id": target_id, "payload": payload}))
	panel.open(route, "p11_commit_allocation", {"large_text": false, "timer_free": true})
	await process_frame
	await process_frame
	_check(panel.is_open() and (panel.find_child("Commit", true, false) as Button).disabled, "the panel opens with LOCK IN disabled until a decision is tried")
	panel.dismiss_first_time()
	panel.inspect_clue("c1")
	_check(bool(panel.view().clues[0].found), "INSPECT files a clue to the evidence board")
	panel.choose("option", "floods_overspend")
	var held := panel.try_it()
	_check(not bool(held.accepted) and (panel.find_child("Commit", true, false) as Button).disabled, "10-unit flood allocation is held and LOCK IN stays disabled")
	if want_evidence:
		await _save_evidence("M3-6P_p11_held.png")
	panel.choose("option", "protected_seven")
	var tried := panel.try_it()
	await process_frame
	_check(bool(tried.accepted) and not (panel.find_child("Commit", true, false) as Button).disabled, "7-unit allocation accepted try enables LOCK IN")
	if want_evidence:
		await _save_evidence("M3-6P_p11_alloc7_100.png")
	panel.request_commit()
	var confirmed := panel.confirm_commit()
	_check(bool(confirmed.accepted) and committed.size() == 1 and int(committed[0].payload.get("total", 0)) == 7 and not panel.is_open(), "CONFIRM emits 7-unit allocation payload once and closes")

	# Test P-12 reset sequence at 150% large text
	route.start_at("EX-CH06-S10")
	panel.open(route, "p12_reset_sequence", {"large_text": true, "timer_free": true})
	for index in 4:
		await process_frame
	var commit := panel.find_child("Commit", true, false) as Control
	_check(commit != null and panel.get_viewport_rect().encloses(commit.get_global_rect()), "the panel and LOCK IN stay on screen at 150% text")
	if want_evidence:
		await _save_evidence("M3-6P_p12_reset_150.png")
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
	_check(runtime._startup_error.is_empty() and runtime.route.current_scene_id() == "EX-CH06-S01", "the campaign runtime restores at Chapter 6 S01")
	_check(runtime.hud.open_chapter6_panel("p11_charge_hand_light"), "the HUD opens the Chapter 6 decision card")
	var panel: Chapter6PuzzlePanel = runtime.hud.chapter6_panel
	_select_witness(runtime.route.chapter6(), "p11_charge_hand_light")
	panel.try_it()
	panel.request_commit()
	var target: Node3D = runtime.physical_target("p11_charge_hand_light")
	if target != null and runtime._player != null:
		runtime._player.global_position = Vector3(target.global_position.x, 0.0, target.global_position.z + 1.0)
		runtime._player.velocity = Vector3.ZERO
		await physics_frame
		await physics_frame
	panel.confirm_commit()
	await process_frame
	_check(runtime.route.chapter6_view("p11_charge_hand_light").committed, "a confirmed card commits the physical operation through the runtime")
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
