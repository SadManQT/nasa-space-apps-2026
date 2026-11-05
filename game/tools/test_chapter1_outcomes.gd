extends SceneTree

## Ending boundaries, actual-route replay/save/retry, and the same Control the
## production HUD opens. Assertions inspect state/results, not source strings.
const Simulation = preload("res://scripts/simulation/expedition_simulation.gd")
const Model = preload("res://scripts/missions/chapter1_outcome.gd")
const Fixture = preload("res://tools/support/chapter1_outcome_fixture.gd")
const Campaign = preload("res://scripts/campaign/chapter1_campaign.gd")
const Panels = preload("res://scenes/ui/campaign_panels.tscn")
var checks := 0
var failures := 0
var storage = preload("res://tools/support/isolated_storage.gd").new()

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var capture_script: GDScript = load("res://tools/capture_chapter1_outcomes.gd")
	_check(capture_script != null and capture_script.can_instantiate(), "windowed evidence script parses and compiles")
	_test_boundaries()
	for ending in ["GOLDEN", "BLOOM", "ALO_LOST", "MISSION_STOPPED"]:
		var route: RefCounted = Fixture.play(ending)
		_test_route(route, ending)
		await _test_panel(route, ending)
	await _test_hud()
	print("CHAPTER 1 OUTCOMES RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_boundaries() -> void:
	var simulation := Simulation.new()
	for row in [
		[0, 2, 3, 0, "ALO_LOST"], [1, 2, 3, 0, "BLOOM"],
		[4, 2, 3, 0, "BLOOM"], [5, 2, 3, 0, "GOLDEN"],
		[5, 2, 3, 1, "BLOOM"], [5, 1, 3, 0, "MISSION_STOPPED"],
		[5, 0, 3, 0, "MISSION_STOPPED"], [5, 2, 4, 0, "MISSION_STOPPED"],
		[0, 1, 4, 0, "MISSION_STOPPED"],
	]:
		var state := simulation.entry_profile()
		state.current_shift = 6
		state.resources.merge({"E": 4, "H": row[0], "A": row[1], "Z": row[2]}, true)
		state.blackout_count = row[3]
		var result: Dictionary = simulation.preview(state, {"shift": {"heat": "COZY", "air_production": 0, "light": "DIM", "transfer": "HOLD"}})
		_check(result.get("ending") == row[4], "boundary H%s A%s Z%s blackouts%s → %s" % row)
		_check(int(result.final_state.E) == 0 and not result.trace[0].blackout, "exactly E0 is not a blackout at ending evaluation")

func _test_route(route: RefCounted, ending: String) -> void:
	var view: Dictionary = route.outcome_view()
	_check(view.get("ending") == ending, "actual route earns " + ending)
	_check(bool(view.safe_ending) == (ending in ["GOLDEN", "BLOOM"]) and not route.chapter_ready().ready, ending + ": completion still requires final story gates")
	var state: Dictionary = route.director().snapshot()
	var history: Dictionary = route.snapshot().outcome_history
	_check(Model.validate(JSON.parse_string(JSON.stringify(history))), ending + ": replay survives JSON with its real forecasts")
	_check(view.replay.size() == int(state.current_shift), ending + ": one row per actually committed shift, including early stop")
	var matches := true
	for row in view.replay:
		matches = matches and row.matches and not String(row.choice).is_empty() and not String(row.why).is_empty()
	_check(matches, ending + ": every captured forecast matches the committed readings and has a causal explanation")
	var duplicate_history: Dictionary = history.duplicate(true)
	Model.record(duplicate_history, {}, {}, {"accepted": true, "duplicate": true}, {}, [])
	_check(duplicate_history == history, ending + ": duplicate receipts cannot add replay rows")
	var snapshot: Dictionary = state.duplicate(true)
	snapshot.scene_id = route.current_scene_id()
	snapshot.mission_id = route.current_mission_id()
	snapshot.route_runtime = route.snapshot()
	var restored: Dictionary = Campaign.restore_session(JSON.parse_string(JSON.stringify(snapshot)))
	_check(restored.get("accepted", false), ending + ": a production session restores the ending and replay: " + String(restored.get("reason", "")))
	if restored.get("accepted", false):
		_check(JSON.parse_string(JSON.stringify(restored.route.outcome_view().replay)) == JSON.parse_string(JSON.stringify(view.replay)), ending + ": restored replay is unchanged")
	var malformed: Dictionary = route.snapshot()
	malformed.outcome_history.shifts[0].actual.after.H = "not a reading"
	var saved: Dictionary = route.snapshot()
	_check(not route.restore(malformed).accepted and route.snapshot() == saved, ending + ": corrupt replay rejects atomically")
	for field in ["heat", "light", "shift", "blackout", "causes"]:
		var broken: Dictionary = saved.duplicate(true)
		broken.outcome_history.shifts[0].actual[field] = "invalid"
		_check(not route.restore(broken).accepted and route.snapshot() == saved, ending + ": invalid trace " + field + " rejects before rendering")
	var invalid_cards: Dictionary = saved.duplicate(true)
	invalid_cards.outcome_history.shifts[0].cards = ["invalid"]
	_check(not route.restore(invalid_cards).accepted and route.snapshot() == saved, ending + ": invalid saved card rejects before rendering")
	var legacy: Dictionary = route.snapshot()
	legacy.erase("outcome_history")
	var old_route = preload("res://scripts/missions/chapter1_route.gd").new(route.director())
	_check(old_route.restore(legacy).accepted, ending + ": older route saves remain compatible")
	var old_view: Dictionary = old_route.outcome_view()
	_check(not old_view.replay.is_empty() and old_view.replay.all(func(row): return row.forecast.is_empty()), ending + ": old receipts never invent a forecast")
	var mixed: Dictionary = history.duplicate(true)
	mixed.shifts = mixed.shifts.slice(2)
	mixed.initial.current_shift = 2
	var mixed_view: Dictionary = Model.view(state, ending, mixed, saved.retry_checkpoint, bool(view.safe_ending), route.mission_table())
	_check(mixed_view.replay.size() == int(state.current_shift) and mixed_view.replay[0].forecast.is_empty() and not mixed_view.replay[-1].forecast.is_empty(), ending + ": resuming an old save retains earlier actuals alongside newly captured forecasts")
	if not view.comparison.is_empty():
		_check(view.comparison.ending in ["BLOOM", "GOLDEN"] and int(view.comparison.health_gain) > 0 and int(view.comparison.alternative.Z) <= 3 and int(view.comparison.alternative.A) > 0, ending + ": suggested one-change alternative preserves safe completion")
	var checkpoint: Dictionary = route.snapshot().retry_checkpoint
	_check(route.retry().accepted, ending + ": physical checkpoint retry succeeds")
	_check(route.director().snapshot().resources == checkpoint.director.resources and route.current_scene_id() == checkpoint.route.current_scene_id and route.snapshot().outcome_history == checkpoint.route.outcome_history, ending + ": retry restores resources, room and replay together")
	_check(route.outcome_view().is_empty(), ending + ": retry removes the abandoned ending")
	# Return the fixture to its saved ending for the UI checks.
	route.director().restore_snapshot(state)
	route.restore(saved)

func _test_panel(route: RefCounted, ending: String) -> void:
	var panel = Panels.instantiate()
	root.add_child(panel)
	var before: Dictionary = route.director().snapshot()
	panel.bind_query({"outcome": route.outcome_view()})
	panel.open_panel("outcome")
	_check(panel.find_child("OutcomeContinue", true, false) == null and panel.find_child("ReviewReplay", true, false) != null, ending + ": replay comes before debrief and questions")
	panel.find_child("ReviewReplay", true, false).pressed.emit()
	for row in range(1, route.outcome_view().replay.size()):
		panel.find_child("NextShift", true, false).pressed.emit()
	panel.find_child("ReadDebrief", true, false).pressed.emit()
	var continuing = panel.find_child("OutcomeContinue", true, false)
	_check((continuing != null) == (ending in ["BLOOM", "GOLDEN"]), ending + ": only living safe outcomes offer Continue")
	var source = panel.find_child("Source_clowdsley_2021_shielding", true, false)
	_check(source != null, ending + ": water trade-off links its existing NASA Data Card")
	source.pressed.emit()
	_check(panel.active_panel() == "data_card" and panel.query_snapshot().data_card.source_id == "clowdsley_2021_shielding", ending + ": the link opens the correct bundled evidence")
	# Return uses the real source button, retaining the reading position.
	for button in panel._body.get_children():
		if button is Button and button.text == "RETURN TO SCIENCE DEBRIEF":
			button.pressed.emit()
			break
	_check(panel.find_child("DebriefQuestions", true, false) != null, ending + ": returning from evidence restores the debrief")
	panel.find_child("DebriefQuestions", true, false).pressed.emit()
	panel.find_child("Answer_day_air_2", true, false).pressed.emit()
	_check(not String(panel.find_child("Feedback_day_air", true, false).text).is_empty(), ending + ": a different answer gets calm explanatory feedback")
	_check(route.director().snapshot() == before, ending + ": reading, comparing and answering never mutate expedition state")
	for resolution in [Vector2i(1280, 720), Vector2i(640, 480)]:
		root.content_scale_size = resolution
		root.size = resolution
		for large in [false, true]:
			panel.set_accessibility({"large_text": large})
			panel.bind_query({"outcome": route.outcome_view(), "accessibility": {"large_text": large}})
			for frame in 5:
				await process_frame
			_check(panel.get_viewport_rect().encloses(panel._panel.get_global_rect()) and panel.get_viewport_rect().encloses(panel._close_button.get_global_rect()), "%s: %s large=%s shell and close stay visible" % [ending, resolution, large])
			var retry := panel.find_child("OutcomeRetry", true, false) as Button
			retry.grab_focus()
			for frame in 8:
				await process_frame
			_check(retry.has_focus() and panel.get_viewport_rect().encloses(retry.get_global_rect()) and retry.size.y >= 44, ending + ": keyboard focus scrolls the retry target fully into view")
	var cancel := InputEventAction.new()
	cancel.action = "ui_cancel"
	cancel.pressed = true
	panel._unhandled_input(cancel)
	_check(panel.active_panel().is_empty(), ending + ": controller/action cancel closes the reading panel")
	panel.free()
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)

func _test_hud() -> void:
	_check(storage.setup("M1-19-tests"), "isolated production save storage")
	var route: RefCounted = Fixture.play("GOLDEN")
	var state: Dictionary = route.director().snapshot()
	state.scene_id = route.current_scene_id()
	state.mission_id = route.current_mission_id()
	state.route_runtime = route.snapshot()
	var campaign = preload("res://scenes/campaign/chapter1_campaign.tscn").instantiate()
	storage.configure(campaign)
	campaign.initial_snapshot = state
	root.add_child(campaign)
	await process_frame
	var before: Dictionary = campaign.director.snapshot()
	campaign.hud.open_outcome()
	_check(campaign.hud.panels.active_panel() == "outcome" and campaign.director.query().paused, "production HUD opens saved ending and pauses operations")
	_check(campaign.save_campaign().accepted, "ending panel can save through the production service")
	var loaded: Dictionary = preload("res://scripts/save/save_service.gd").new().load(storage.path)
	_check(loaded.accepted and loaded.snapshot.route_runtime.outcome_history.shifts.size() == 7, "disk save/load retains all seven actual predictions and decisions")
	var before_count: int = campaign.director.snapshot().receipts.size()
	campaign.hud.panels.find_child("OutcomeRetry", true, false).pressed.emit()
	_check(not campaign.director.query().paused and int(campaign.director.query().current_shift) == 5 and campaign.route.outcome_view().is_empty(), "outcome Retry closes modal and restores the correct pre-shifts-6–7 checkpoint")
	_check(campaign.director.snapshot().receipts.size() < before_count and campaign.director.snapshot().inventories == before.inventories, "retry discards future receipts without duplicating inventory")
	campaign.free()
	storage.cleanup()

func _check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("FAIL " + message)
