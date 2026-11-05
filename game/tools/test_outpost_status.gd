extends SceneTree

const Gates = preload("res://scripts/missions/chapter1_gate_catalog.gd")
const PlanFixture = preload("res://tools/support/p02_plan_fixture.gd")
var storage = preload("res://tools/support/isolated_storage.gd").new()
var checks := 0
var failures := 0

func _init() -> void:
	if not storage.setup("outpost"):
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var runtime = load("res://scenes/campaign/chapter1_campaign.tscn").instantiate()
	storage.configure(runtime)
	root.add_child(runtime)
	await process_frame
	var hud = runtime.hud
	var query: Dictionary = runtime.query()
	query.resources.R = 0
	hud.outpost.bind_query(query)
	_check(hud.outpost.meter_view("food").status == "! LOW", "empty rations remain visible even with healthy crops")
	query = runtime.query()
	query.resources.W = 4
	hud.outpost.bind_query(query)
	_check(hud.outpost.meter_view("life").status == "! CHECK", "borrowed garden water triggers its data-backed thirst warning")
	query.outpost["separate_shelter_water"] = 2
	hud.outpost.bind_query(query)
	_check(hud.outpost.meter_view("life").status == "OK", "separate ice-water shielding does not falsely report four borrowed garden units")
	hud.outpost.bind_query(runtime.query())
	var original: Dictionary = runtime.director.snapshot()
	_check(hud.outpost._cards.size() == 4, "all four competing demands have visible meters")
	_check(hud.outpost.meter_view("power").current_text.contains("14/20"), "power reads the authoritative E and capacity")
	_check(hud.outpost.meter_view("life").current_text.contains("water"), "life support labels the actual wall-water allocation")
	_check(hud.outpost.meter_view("food").accessibility_text.contains("crew-days"), "rations expose their unit to assistive technology")
	var preview: Dictionary = runtime.forecast_target("commission_route")
	_check(preview.accepted and runtime.director.snapshot() == original, "forecast runs the real route without changing live state")
	for large in [false, true]:
		var state: Dictionary = runtime.director.snapshot()
		state.accessibility.large_text = large
		runtime.director.restore_snapshot(state)
		hud.refresh_scene()
		hud.show_target_forecast("commission_route")
		await process_frame
		await process_frame
		for id in ["power", "life", "shielding", "food"]:
			var card: Dictionary = hud.outpost._cards[id]
			_check(root.get_visible_rect().encloses(card.panel.get_global_rect()), "meter fits viewport, large=%s: %s" % [large, id])
			_check(card.panel.get_global_rect().encloses(card.forecast.get_global_rect()), "forecast fits its card, large=%s: %s" % [large, id])
			_check(card.values.get_line_count() <= 2 and card.forecast.get_line_count() <= 2, "readout wraps without hiding numeric text: " + id)
			_check(not card.panel.accessibility_name.is_empty(), "screen reader gets plain-language values: " + id)
		if OS.get_cmdline_user_args().has("--evidence"):
			await _capture("M1-28_status_" + ("150" if large else "100"))
		hud.panels.open_panel("settings_accessibility")
		await process_frame
		await process_frame
		_check(root.get_visible_rect().encloses(hud.panels._close_button.get_global_rect()), "modal Close fits below status row")
		_check(hud.panels._panel.get_global_rect().position.y >= hud.outpost.get_global_rect().end.y, "modal keeps all four meters uncovered")
		if large and OS.get_cmdline_user_args().has("--evidence"):
			await _capture("M1-28_settings_150")
		hud.panels.close_panel()
		if large and OS.get_cmdline_user_args().has("--evidence"):
			hud.panels.open_panel("data_card", {"source_id": "bvad_2022_metabolic"})
			await process_frame
			await process_frame
			await _capture("M1-28_data_card_status")
			hud.panels.close_panel()
	# Arrange the production route's first six scenes without fabricating resources.
	PlanFixture.prepare_p01(runtime.route)
	for scene_id in Gates.SCENE_ORDER.slice(0, 6):
		var targets: Array = Gates.targets_for_scene(scene_id)
		if scene_id == "EX-CH01-S03":
			targets.push_back(targets.pop_front())
			var comparison = targets.pop_at(3)
			targets.push_back(comparison)
		for target in targets:
			_check(runtime.route.perform(target.target_id).get("accepted", false), "setup follows real prerequisite: " + target.target_id)
		_check(runtime.route.advance_scene().get("accepted", false), "setup advances real scene: " + scene_id)
	var first = Gates.targets_for_scene("EX-CH01-S07")[0]
	_check(runtime.route.perform(first.target_id).get("accepted", false), "read the shift role facts before forecasting")
	PlanFixture.prepare(runtime.route)
	runtime.call("_sync_route_projection")
	runtime.call("_refresh_world")
	hud.refresh_scene()
	var before: Dictionary = runtime.director.snapshot()
	preview = runtime.forecast_target("p02_shift1")
	_check(preview.accepted and runtime.director.snapshot() == before, "P-02 forecast preserves resources, receipts, time and biology")
	hud.show_target_forecast("p02_shift1")
	_check(hud.outpost.meter_view("power").forecast_text.contains("E -> +"), "power preview includes an arrow and signed delta")
	_check(hud.outpost.meter_view("food").forecast_text.contains("R -> -"), "food preview shows the real ration cost")
	if OS.get_cmdline_user_args().has("--evidence"):
		await _capture("M1-28_shift_forecast")
	var committed: Dictionary = runtime.route.perform("p02_shift1")
	_check(committed.get("accepted", false) and runtime.director.query().resources == preview.query.resources, "forecast and the real commit agree for every resource")
	var after: Dictionary = runtime.director.snapshot()
	var simulation = preload("res://scripts/simulation/expedition_simulation.gd").new()
	_check(simulation.outpost_readouts({}).is_empty(), "missing state never invents a shelter reading")
	after.resources.W = 1
	after.resources.K = 1
	after.upgrades.choices["3"] = "moon_dirt_shelter"
	_check(simulation.outpost_readouts(after).shelter_capacity == 3, "shelter readout includes the existing upgrade calculation")
	after.resources.W = 6
	after.resources.K = 2
	_check(simulation.outpost_readouts(after).shelter_capacity == 6, "shelter readout uses the canonical cap")
	hud.outpost.bind_query(runtime.query(), preview)
	_check(hud.outpost.meter_view("power").forecast_text.contains("Select"), "a changed state revision invalidates the old forecast")
	runtime.free()
	storage.cleanup()
	print("OUTPOST STATUS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/" + name + ".png"))

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL " + message)
