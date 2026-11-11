## M3-2P: P-03 and P-04 are real decision cards in the production campaign.
## Real nearby USE opens the card; wrong knowledge checks, a promised ratio and
## a wrong recorder token are held with their content feedback and change
## nothing; the supported choice previews read-only and locks in once; the
## card's selections and hints survive save and load.
## Run with `-- --capture` in a window to save the screens.
extends SceneTree

const CampaignScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const RouteScript = preload("res://scripts/missions/chapter2_route.gd")
const PuzzlesScript = preload("res://scripts/puzzles/chapter2_puzzles.gd")
var storage = preload("res://tools/support/isolated_storage.gd").new()
var checks := 0
var failures := 0
var capture := false

func _init() -> void:
	CampaignCutscenePlayer.autoplay = false
	if not storage.setup("chapter2_panel_wiring"):
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	capture = OS.get_cmdline_user_args().has("--capture") and DisplayServer.get_name() != "headless"
	_test_content_cards()
	var campaign := await _spawn("EX-CH02-S04")
	if campaign != null:
		await _test_knowledge_check(campaign)
		campaign.free()
		await process_frame
	campaign = await _spawn("EX-CH02-S09")
	if campaign != null:
		await _test_token(campaign)
		campaign.free()
		await process_frame
	# Earlier puzzle progress, as the P-03/P-04 models save it after S05 and S09.
	var runs_done := {"p03": {"schema_version": 1, "run_index": 3, "step_index": 0, "care_dates": ["2046-04-30", "2046-05-01", "2046-05-02", "2046-05-03", "2046-05-04", "2046-05-05", "2046-05-06"], "prediction": {}, "completed_actions": []}}
	var copy_ready := {"p04": {"schema_version": 1, "mapping": {"date": "2034-04", "device": "HORT-01", "channel": "ENGINEERING"}, "checksum_verified": true, "transcript_opened": true, "engineer_played": false, "n_clue_played": false, "classified": false, "copy_sent": false, "handover_acknowledged": false}}
	campaign = await _spawn("EX-CH02-S06", runs_done)
	if campaign != null:
		await _test_prediction(campaign)
		campaign.free()
		await process_frame
	campaign = await _spawn("EX-CH02-S10", copy_ready)
	if campaign != null:
		await _test_classification(campaign)
		campaign.free()
		await process_frame
	_finish()

## Every P-03/P-04 physical step has a card; answers come from the content.
func _test_content_cards() -> void:
	var model := PuzzlesScript.new()
	var steps: Dictionary = model.data().get("steps", {})
	_check(steps.size() == 32, "every P-03 and P-04 physical step has a card (%d)" % steps.size())
	for target_id in steps:
		var spec: Dictionary = steps[target_id]
		var kind := String(spec.get("kind", ""))
		_check(kind in ["choice", "fields", "confirm"] and not String(spec.get("goal", "")).is_empty(), "%s has a goal and a supported control" % target_id)
		if kind == "choice":
			var correct: Array = (spec.options as Array).filter(func(option): return bool(option.correct))
			_check(correct.size() == 1 and spec.options.size() >= 2, "%s offers one supported option and a reasonable alternative" % target_id)
		_check(model.hint_ladder(target_id).size() == 3, "%s has three hint tiers" % target_id)
	var restored := PuzzlesScript.new()
	model.select("record_stem_prediction", "prediction", "Both visible colours may appear")
	model.reveal_hint("record_stem_prediction")
	model.mark_first_time_seen("P-03")
	_check(bool(restored.restore(model.snapshot()).get("accepted", false)) and restored.selection("record_stem_prediction") == {"prediction": "Both visible colours may appear"} and restored.revealed_hints("record_stem_prediction").size() == 1 and restored.first_time_seen("P-03"), "card selections, hints and first-use survive save and load")
	var tampered: Dictionary = model.snapshot()
	tampered.selections["record_stem_prediction"] = {"prediction": "Every seed is purple, guaranteed"}
	_check(not bool(PuzzlesScript.new().restore(tampered).get("accepted", false)), "a tampered save line is refused")

func _test_knowledge_check(campaign: Chapter1Campaign) -> void:
	var panel: Chapter2PuzzlePanel = await _open(campaign, "p03_scan_tara")
	if panel == null:
		return
	var before: Dictionary = campaign.director.snapshot()
	_check(not panel.request_commit().get("accepted", false), "locking in without a choice is refused")
	panel.choose("option", "own_pollen")
	var held: Dictionary = panel.try_it()
	_check(not bool(held.get("accepted", false)) and String(held.get("reason", "")).contains("self-incompatible"), "own-pollen route is held with the self-incompatibility feedback")
	_check(panel.view().get("hints", []).size() == 1, "a held try offers hint H1")
	_check(campaign.director.snapshot().receipts == before.receipts, "the held check changes nothing")
	panel.choose("option", "reciprocal")
	var tried: Dictionary = panel.try_it()
	_check(bool(tried.get("accepted", false)) and not tried.get("after", {}).get("resources", {}).is_empty(), "the supported route previews with a before and after")
	_check(campaign.director.snapshot().receipts == before.receipts, "the preview is read only")
	await _shot("M3-2P_p03_route_card.png")
	await _lock(campaign, panel, "p03_scan_tara_done", before)

func _test_token(campaign: Chapter1Campaign) -> void:
	var panel: Chapter2PuzzlePanel = await _open(campaign, "assign_date_token")
	if panel == null:
		return
	var before: Dictionary = campaign.director.snapshot()
	panel.choose("option", "HORT-01")
	var held: Dictionary = panel.try_it()
	_check(not bool(held.get("accepted", false)) and String(panel._notice).contains("different fields"), "a wrong token is held by the P-04 model and names the disagreeing field")
	_check(campaign.route.snapshot().p04.mapping.is_empty(), "the wrong token is not recorded")
	panel.choose("option", "2034-04")
	_check(bool(panel.try_it().get("accepted", false)), "the source-supported date previews")
	await _shot("M3-2P_p04_token_card.png")
	await _lock(campaign, panel, "p04_assign_date_done", before)
	_check(campaign.route.snapshot().p04.mapping.get("date", "") == "2034-04", "the P-04 model records the chosen date")

func _test_prediction(campaign: Chapter1Campaign) -> void:
	var panel: Chapter2PuzzlePanel = await _open(campaign, "record_stem_prediction")
	if panel == null:
		return
	var before: Dictionary = campaign.director.snapshot()
	panel.choose("prediction", "Exactly three purple to one green")
	_check(not bool(panel.try_it().get("accepted", false)) and String(panel._notice).contains("Choose a line"), "an incomplete prediction is held")
	panel.choose("reason", "Alo has purple and Tara has green stems; the complete genotype is not established.")
	panel.choose("future_test", "Compare descendant stem observations after seed harvest.")
	var held: Dictionary = panel.try_it()
	_check(not bool(held.get("accepted", false)) and String(panel._notice).contains("ratio"), "a promised ratio is held by the P-03 model with its feedback")
	_check(campaign.director.snapshot().receipts == before.receipts, "the held prediction changes nothing")
	panel.choose("prediction", "Both visible colours may appear")
	_check(bool(panel.try_it().get("accepted", false)), "a supported prediction previews")
	await _shot("M3-2P_p03_prediction_card.png")
	await _lock(campaign, panel, "p03_prediction_recorded", before)

func _test_classification(campaign: Chapter1Campaign) -> void:
	for id in ["play_engineer_fragment", "play_n_memory"]:
		var step_panel: Chapter2PuzzlePanel = await _open(campaign, id)
		if step_panel == null:
			return
		step_panel.choose("confirmed", true)
		_check(bool(step_panel.try_it().get("accepted", false)), "%s read-back previews (%s)" % [id, step_panel._notice])
		await _lock(campaign, step_panel, "", campaign.director.snapshot())
	var panel: Chapter2PuzzlePanel = await _open(campaign, "classify_voice_inference")
	if panel == null:
		return
	var before: Dictionary = campaign.director.snapshot()
	for pair in [["retreat_ordered", "observed"], ["n_memory", "observed"], ["voice_resembles", "observed"], ["writer_name", "unknown"]]:
		panel.choose(pair[0], pair[1])
	_check(not bool(panel.try_it().get("accepted", false)) and String(panel._notice).contains("inference"), "filing the voice resemblance as observed is held")
	panel.choose("voice_resembles", "inferred")
	_check(bool(panel.try_it().get("accepted", false)), "the supported sort previews")
	await _shot("M3-2P_p04_classification_card.png")
	await _lock(campaign, panel, "p04_inference_classified", before)

func _open(campaign: Chapter1Campaign, id: String) -> Chapter2PuzzlePanel:
	await _near(campaign, id)
	var opened: Dictionary = campaign.interact_nearby()
	await process_frame
	var panel: Chapter2PuzzlePanel = campaign.hud.chapter2_panel
	_check(bool(opened.get("chapter2_panel_requested", false)) and panel.is_open() and panel.target_id() == id, "real nearby USE opens the %s card" % id)
	return panel if panel.is_open() else null

func _lock(campaign: Chapter1Campaign, panel: Chapter2PuzzlePanel, flag: String, before: Dictionary) -> void:
	_check(bool(panel.request_commit().get("accepted", false)), "%s asks for lock-in confirmation" % panel.target_id())
	var id := panel.target_id()
	var confirmed: Dictionary = panel.confirm_commit()
	await process_frame
	_check(bool(confirmed.get("accepted", false)) and not panel.is_open(), "%s confirms and closes" % id)
	_check(campaign.director.snapshot().receipts.size() == before.receipts.size() + 1, "%s charges exactly one receipt" % id)
	if not flag.is_empty():
		_check(bool(campaign.route.current_flags().get(flag, false)), "%s sets %s" % [id, flag])
	campaign.hud.panels.close_panel()
	await process_frame

func _spawn(scene_id: String, progress: Dictionary = {}) -> Chapter1Campaign:
	var director := DirectorScript.new()
	director.new_campaign(CampaignContentFull.EXPECTED_CONTENT_REVISION)
	var route := RouteScript.new(director)
	var moved: Dictionary = route.start_at(scene_id)
	_check(bool(moved.get("accepted", false)), "fixture projects into " + scene_id)
	if not bool(moved.get("accepted", false)):
		return null
	var state: Dictionary = director.snapshot()
	state["route_runtime"] = route.snapshot()
	state.route_runtime["chapter"] = 2
	for key in progress:
		state.route_runtime[key] = progress[key]
	var campaign := CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	campaign.initial_snapshot = state
	root.add_child(campaign)
	await process_frame
	await process_frame
	_check(campaign.route != null and campaign.route.current_scene_id() == scene_id and campaign.hud != null and campaign.hud.chapter2_panel != null, "production campaign opens %s with a Chapter 2 card" % scene_id)
	return campaign

func _near(campaign: Chapter1Campaign, id: String) -> void:
	var target: Node3D = campaign.physical_target(id)
	_check(target != null, "physical target exists: " + id)
	if target == null:
		return
	var approach: Array = target.get_meta("approach_m", [])
	campaign._player.global_position = campaign._room.to_global(Vector3(float(approach[0]), float(approach[1]), float(approach[2]))) if approach.size() == 3 else target.global_position + Vector3(0, 0, 1)
	campaign._player.velocity = Vector3.ZERO
	await physics_frame
	campaign._player.follow_camera.camera.look_at(target.global_position)
	_check(campaign.nearby_target().get("target_id", "") == id, "nearby target selected: " + id)

func _shot(file: String) -> void:
	if not capture:
		return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/" + file))

func _finish() -> void:
	storage.cleanup()
	print("CHAPTER 2 PANEL WIRING RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)
