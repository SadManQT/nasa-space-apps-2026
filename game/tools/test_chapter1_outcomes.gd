extends SceneTree

const Panels = preload("res://scripts/ui/campaign_panels.gd")
const Simulation = preload("res://scripts/simulation/expedition_simulation.gd")
const Fixture = preload("res://tools/support/chapter1_outcome_fixture.gd")
const CampaignScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
var storage = preload("res://tools/support/isolated_storage.gd").new()
var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_check(Panels.PANEL_IDS.has("chapter1_outcome"), "Chapter 1 has an integrated closure and replay panel")
	if not ResourceLoader.exists("res://scripts/debrief/chapter1_debrief.gd"):
		_check(false, "read-only Chapter 1 debrief model exists")
		_finish()
		return
	var model = load("res://scripts/debrief/chapter1_debrief.gd")
	for ending in ["GOLDEN", "BLOOM", "ALO_LOST", "MISSION_STOPPED"]:
		var route: RefCounted = Fixture.play(ending)
		var before: Dictionary = route.director().snapshot()
		var local: Dictionary = route.snapshot()
		var view: Dictionary = model.view(before, local)
		_check(view.ending == ending, ending + " comes from the actual simulation")
		_check(view.safe_ending == (ending in ["BLOOM", "GOLDEN"]), ending + " story access follows the route")
		_check(model.readings(view.resources).contains("crew-days") and model.readings(view.resources).contains("of 20"), "readings include resource scales and food units")
		_check(model.readings(view.resources).contains("Water in the shelter wall %d of %d" % [int(view.resources.W), int(view.resources.water_capacity)]) and model.readings(view.resources).contains("Supplies in the shelter wall %d of %d" % [int(view.resources.K), int(view.resources.crate_capacity)]), "water and crates show their actual capacity scales")
		_check(not view.replay.is_empty(), ending + " has real shift receipts")
		for row in view.replay:
			_check(row.forecast == row.actual.after, "historical settings reproduce shift %d forecast" % row.shift)
		_check(route.director().snapshot() == before and route.snapshot() == local, "review is read-only")
		var saved: Dictionary = JSON.parse_string(JSON.stringify(before))
		var reloaded: Dictionary = model.view(saved, JSON.parse_string(JSON.stringify(local)))

		_check(JSON.parse_string(JSON.stringify(reloaded.replay)) == JSON.parse_string(JSON.stringify(view.replay)), "save/reload retains causal replay")
		var checkpoint: Dictionary = local.retry_checkpoint.director
		_check(bool(route.retry().accepted), ending + " retries its existing physical checkpoint")
		_check(route.director().snapshot().resources == checkpoint.resources, "retry restores the complete checkpoint resources")
		var retried: Dictionary = model.view(route.director().snapshot(), route.snapshot())
		_check(retried.is_empty(), "retry removes the abandoned ending")
	_test_boundaries()
	await _test_ui()
	_finish()

func _test_boundaries() -> void:
	var simulation := Simulation.new()
	var base := simulation.entry_profile()
	base.current_shift = 6
	base.resources.merge({"E": 5, "A": 4, "H": 4, "W": 0, "Z": 3}, true)
	var step := {"heat": "COZY", "air_production": 0, "light": "FULL", "transfer": "HOLD"}
	var result := simulation.preview(base, {"shift": step})
	_check(result.ending == "GOLDEN" and result.final_state.E == 0 and result.final_state.H == 5, "Golden includes H5, Z3 and exactly empty battery without blackout")
	base.resources.H = 3
	_check(simulation.preview(base, {"shift": step}).ending == "BLOOM", "living H4 is Bloom")
	base.resources.H = 1
	var dim_step := step.duplicate()
	dim_step.light = "DIM"
	_check(simulation.preview(base, {"shift": dim_step}).ending == "BLOOM", "H1 is a living Bloom at the safety boundary")
	base.resources.H = 0
	_check(simulation.preview(base, {"shift": step}).ending == "ALO_LOST", "safe H0 is Alo Lost and cannot resurrect")
	base.resources.A = 1
	_check(simulation.preview(base, {"shift": step}).ending == "MISSION_STOPPED", "A0 stops before plant-loss ending")
	base.resources.merge({"A": 4, "Z": 4}, true)
	_check(simulation.preview(base, {"shift": step}).ending == "MISSION_STOPPED", "exposure above 3 stops operations")
	base.resources.merge({"Z": 3, "H": 9, "E": 3}, true)
	_check(simulation.preview(base, {"shift": step}).ending == "BLOOM", "blackout disqualifies Golden even with living healthy Alo")

func _test_ui() -> void:
	storage.setup("M1-19-outcomes")
	CampaignCutscenePlayer.autoplay = false
	root.size = Vector2i(1280, 720)
	var route: RefCounted = Fixture.play("BLOOM")
	var snapshot: Dictionary = route.director().snapshot()
	snapshot["route_runtime"] = route.snapshot().merged({"chapter": 1})
	snapshot["scene_id"] = route.current_scene_id()
	snapshot["mission_id"] = route.current_mission_id()
	snapshot["completed_scene_ids"] = route.completed_scene_ids()
	var campaign := CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	campaign.initial_snapshot = snapshot
	root.add_child(campaign)
	await process_frame
	if campaign.director == null:
		_check(false, "production saved route restores: " + campaign._startup_error)
		campaign.free()
		return
	var before: Dictionary = campaign.director.snapshot()
	_check(bool(campaign.hud.call("show_chapter1_outcome")), "saved ending opens from the production HUD")
	var panels := campaign.hud.panels
	_check(panels.active_panel() == "chapter1_outcome" and campaign.director.query().paused, "outcome pauses the expedition")
	(panels.find_child("ReviewDecisions", true, false) as Button).pressed.emit()
	for index in range(1, 8):
		_check(panels.find_child("ReplayChoice", true, false) != null, "replay shows each real decision before the questions")
		(panels.find_child("ReplayNext", true, false) as Button).pressed.emit()
	_check(panels.find_child("DebriefQuestion", true, false) != null, "questions follow the shift replay")
	(panels.find_child("Answer0", true, false) as Button).pressed.emit()
	_check(not (panels.find_child("AnswerFeedback", true, false) as Label).text.is_empty(), "answer gives a causal explanation")
	(panels.find_child("DebriefSource", true, false) as Button).pressed.emit()
	_check(panels.active_panel() == "data_card", "debrief opens the real NASA Data Card")
	(panels.find_child("BackToDebrief", true, false) as Button).pressed.emit()
	_check(panels.active_panel() == "chapter1_outcome" and panels.find_child("DebriefQuestion", true, false) != null, "data card returns to the same question")
	panels.close_panel()
	var after: Dictionary = campaign.director.snapshot()
	before.paused = after.paused
	_check(before == after, "reading, replay and questions never change resources or receipts")
	bool(campaign.hud.call("show_chapter1_outcome"))
	panels.set_accessibility({"large_text": true})
	await process_frame
	await process_frame
	panels._scroll.scroll_vertical = 100
	bool(campaign.hud.call("show_chapter1_outcome"))
	_check(panels._scroll.scroll_vertical == 0, "reopened review starts at its heading rather than an old scroll position")
	panels.set_accessibility({"large_text": false})
	var original_scene: String = campaign.route.current_scene_id()
	(panels.find_child("EndingContinue", true, false) as Button).pressed.emit()
	_check(campaign.route.current_scene_id() == original_scene, "safe ending Continue still waits for physical review gate")
	bool(campaign.hud.call("show_chapter1_outcome"))
	(panels.find_child("EndingRetry", true, false) as Button).pressed.emit()
	_check(int(campaign.director.query().current_shift) == 5 and panels.active_panel().is_empty(), "UI retry restores pre-final-shifts checkpoint")
	campaign.free()
	for safe_ending in ["BLOOM", "GOLDEN"]:
		var safe_route: RefCounted = Fixture.play(safe_ending)
		var safe_state: Dictionary = safe_route.director().snapshot()
		safe_state.merge({"scene_id": safe_route.current_scene_id(), "mission_id": safe_route.current_mission_id(), "completed_scene_ids": safe_route.completed_scene_ids(), "route_runtime": safe_route.snapshot().merged({"chapter": 1})}, true)
		var safe_campaign := CampaignScene.instantiate() as Chapter1Campaign
		storage.configure(safe_campaign)
		safe_campaign.initial_snapshot = safe_state
		root.add_child(safe_campaign)
		await process_frame
		_test_blocked_continue(safe_campaign, safe_ending, "Review how the night ended")
		safe_campaign.route.perform("review_outcome")
		for large in [false, true]:
			safe_campaign.hud.panels.set_accessibility({"large_text": large})
			safe_campaign.hud.show_chapter1_outcome()
			_check(not (safe_campaign.hud.panels.find_child("EndingContinue", true, false) as Button).disabled, "%s ready physical gate enables Continue at large=%s" % [safe_ending, large])
		(safe_campaign.hud.panels.find_child("EndingContinue", true, false) as Button).pressed.emit()
		_check(safe_campaign.route.current_scene_id() == "EX-CH01-S12", safe_ending + " continues only into the final story scene")
		_test_blocked_continue(safe_campaign, safe_ending, "Check Alo's chamber at the glove port")
		for target_id in ["verify_chamber", "open_shutter", "tag_bloom", "inspect_tara", "complete_debrief"]:
			safe_campaign.hud.refresh_after_action(safe_campaign.route.perform(target_id))
		_check(safe_campaign.hud.panels.find_child("ReplayChoice", true, false) != null, "the physical science debrief opens with decision replay")
		safe_campaign.hud.panels.close_panel()
		for large in [false, true]:
			safe_campaign.hud.panels.set_accessibility({"large_text": large})
			safe_campaign.hud.show_chapter1_outcome()
			_check(not (safe_campaign.hud.panels.find_child("EndingContinue", true, false) as Button).disabled, "%s ready physical gate enables Continue at large=%s" % [safe_ending, large])
		(safe_campaign.hud.panels.find_child("EndingContinue", true, false) as Button).pressed.emit()
		_check(safe_campaign.route.current_scene_id() == "EX-CH02-S01", safe_ending + " Continue advances after all final gates")
		safe_campaign.free()
	for ending in ["ALO_LOST", "MISSION_STOPPED"]:
		var failure_route: RefCounted = Fixture.play(ending)
		var view: Dictionary = load("res://scripts/debrief/chapter1_debrief.gd").view(failure_route.director().snapshot(), failure_route.snapshot())
		var failure_panels := Panels.new()
		root.add_child(failure_panels)
		failure_panels.set_content_top(24)
		failure_panels.open_chapter1_outcome(view)
		_check(failure_panels.find_child("EndingContinue", true, false) == null, ending + " has no Continue action")
		_check(not bool(failure_route.advance_scene().accepted), ending + " cannot exit the real physical scene gate")
		failure_panels.free()
	storage.cleanup()

func _test_blocked_continue(campaign: Chapter1Campaign, ending: String, goal: String) -> void:
	var scene_id: String = campaign.route.current_scene_id()
	for large in [false, true]:
		campaign.hud.panels.set_accessibility({"large_text": large})
		campaign.hud.show_chapter1_outcome()
		var panels := campaign.hud.panels
		var button := panels.find_child("EndingContinue", true, false) as Button
		var reason := panels.find_child("EndingContinueReason", true, false) as Label
		_check(button != null and button.disabled, "%s incomplete physical task disables Continue at large=%s" % [ending, large])
		_check(reason != null and reason.is_visible_in_tree() and reason.text.contains(goal) and reason.text.contains("Close this review"), "%s explains the next physical task at large=%s" % [ending, large])
		# A stale queued signal must recheck the live route, even for a disabled button.
		panels.ending_continue_requested.emit()
		_check(campaign.route.current_scene_id() == scene_id and panels.active_panel() == "chapter1_outcome" and panels.find_child("EndingContinueReason", true, false) != null, "%s stale Continue keeps the explanation open at large=%s" % [ending, large])
	campaign.hud.panels.close_panel()
	campaign.hud.panels.set_accessibility({"large_text": false})

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL " + label)

func _finish() -> void:
	print("CHAPTER 1 OUTCOMES RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)
