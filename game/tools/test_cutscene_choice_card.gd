# Godot --headless --path game --script res://tools/test_cutscene_choice_card.gd
## M4-03: CS-18 closes on the D13 dedication (doc 24 §7.7 beat 3). With
## "For the gardens we leave for others" (EX-CH08-S12-OPT02) in story_log.choices
## the catalog label sits small at the bottom of the black from 7.0 s to 9.0 s and
## the silent black holds one second past the 8.0 s film; with OPT01 or no choice
## nothing is drawn and the film ends at 8.0 s. Plays the real OGV.
extends SceneTree

const CampaignScene: PackedScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const CATALOG_PATH := "res://resources/campaign/content/campaign_catalog.json"
const CHOICE_ID := "EX-CH08-S12-CHOICE"
const FILM_S := 8.0

## Stands in for the campaign node: the player asks its parent for `director`.
class Host extends Node:
	var director: CampaignDirector

var checks := 0
var failures := 0
var label := ""

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	label = _catalog_label("EX-CH08-S12-OPT02")
	var runtime := CampaignCutsceneRuntime.new()
	var plans := runtime.plans_for_scene("EX-CH08-S12", "campaign_complete")
	_check(plans.size() == 1 and String(plans[0].get("cutscene_id", "")) == "CS-18" and String(plans[0].get("mode", "")) == "video", "CS-18 is the one film on campaign completion and plays as video")
	var plan: Dictionary = plans[0] if plans.size() == 1 else {}
	_test_card_data(runtime, plan)
	_test_alpha()
	await _test_campaign_host(plan)
	await _test_skip_and_fallback(plan)
	await _test_playback(plan)
	print("CUTSCENE CHOICE CARD RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_card_data(runtime: CampaignCutsceneRuntime, plan: Dictionary) -> void:
	var card: Dictionary = plan.get("choice_card", {})
	_check(label == "For the gardens we leave for others", "the D13 OPT02 catalog label is the canon dedication")
	_check(String(card.get("text", "")) == label, "the card's words are the catalog label, read not retyped (got %s)" % card.get("text", ""))
	_check(String(card.get("choice_id", "")) == CHOICE_ID and String(card.get("option_id", "")) == "EX-CH08-S12-OPT02", "the card is keyed to D13 OPT02")
	_check(CampaignState.story_choice_problem(CHOICE_ID, String(card.get("option_id", ""))).is_empty(), "the save validator knows the card's choice and option ids")
	_check(is_equal_approx(float(card.get("show_at_s", -1.0)), 7.0) and is_equal_approx(float(card.get("hide_at_s", -1.0)), 9.0), "the words fade in at 7.0 s (picture fully black) and leave at 9.0 s")
	_check(not card.has("note"), "the manifest note stays out of the plan")
	_check(runtime.choice_card("CS-18") == card, "the runtime's CS-18 card is the one its plan carries")
	var english := RegEx.create_from_string("^[A-Za-z ,.'-]+$")
	_check(english.search(String(card.get("text", ""))) != null, "the words are English in Latin letters only")
	for cutscene_id in ["CS-01", "CS-03", "CS-17"]:
		_check(runtime.playback_plan(cutscene_id).get("choice_card", {}).is_empty(), cutscene_id + " carries no choice card")

func _test_alpha() -> void:
	var card := {"show_at_s": 7.0, "hide_at_s": 9.0, "fade_s": 0.4}
	var expected := [[6.99, 0.0], [7.0, 0.0], [7.2, 0.5], [7.4, 1.0], [7.5, 1.0], [8.5, 1.0], [8.8, 0.5], [9.0, 0.0], [9.5, 0.0]]
	for row in expected:
		_check(absf(CampaignCutscenePlayer.card_alpha(card, float(row[0])) - float(row[1])) < 0.001, "card opacity %.2f at %.2f s" % [row[1], row[0]])
	_check(CampaignCutscenePlayer.card_alpha(card, 7.0, true) == 1.0 and CampaignCutscenePlayer.card_alpha(card, 9.0, true) == 0.0, "reduced motion cuts the words in and out instead of fading")
	_check(CampaignCutscenePlayer.card_alpha({}, 7.5) == 0.0, "no card, nothing drawn")

## The real campaign node is the player's host: its director's story log decides.
func _test_campaign_host(plan: Dictionary) -> void:
	var campaign := CampaignScene.instantiate() as Chapter1Campaign
	campaign.director = _director("EX-CH08-S12-OPT02")
	var player := CampaignCutscenePlayer.new()
	campaign.add_child(player)
	_check(_snapshot_ok, "a save holding D13 OPT02 passes the real director's validation")
	_check(String(player._chosen_card(plan).get("text", "")) == label, "inside the campaign the player reads D13 from the campaign's director")
	campaign.director = _director("EX-CH08-S12-OPT01")
	_check(player._chosen_card(plan).is_empty(), "OPT01 in the campaign's director: no card")
	campaign.director = _director("")
	_check(player._chosen_card(plan).is_empty(), "no D13 choice in the campaign's director: no card")
	campaign.free()

func _test_skip_and_fallback(plan: Dictionary) -> void:
	var host := Host.new()
	host.director = _director("EX-CH08-S12-OPT02")
	root.add_child(host)
	var player := CampaignCutscenePlayer.new()
	host.add_child(player)
	await process_frame
	var results: Array = []
	player.closed.connect(func(result: Dictionary) -> void: results.append(result))
	player.play(plan)
	_check(player.choice_card.get("text", "") == label and player.choice_card_text().is_empty(), "OPT02 arms the card, unseen at 0 s")
	await process_frame
	player.skip()
	_check(results.size() == 1 and bool(results[0].skipped) and String(results[0].choice_card).is_empty() and not bool(results[0].completes_predicate) and not bool(results[0].completes_scene), "a skip before 7 s reports no card and completes nothing")
	var fallback := plan.duplicate(true)
	fallback["mode"] = "text_fallback"
	fallback["captions"] = []
	player.play(fallback)
	await process_frame
	_check(player._fallback_text.text.ends_with(label) and player.choice_card_text().is_empty(), "the text card (film missing) ends with the chosen words")
	player.skip()
	host.free()

## Four players run the real CS-18 film at once: OPT02, OPT01, no choice, and
## OPT02 with large text paused for 0.5 s in the hold.
func _test_playback(plan: Dictionary) -> void:
	var cases := {
		"opt02": {"option": "EX-CH08-S12-OPT02"},
		"opt01": {"option": "EX-CH08-S12-OPT01"},
		"none": {"option": ""},
		"paused": {"option": "EX-CH08-S12-OPT02", "large_text": true},
	}
	var host := Node.new()
	root.add_child(host)
	for key in cases:
		var state: Dictionary = cases[key]
		var snapshot := _director(String(state.option), bool(state.get("large_text", false))).snapshot()
		var player := CampaignCutscenePlayer.new()
		player.snapshot_source = func() -> Dictionary: return snapshot
		host.add_child(player)
		state["player"] = player
		state["first_card_s"] = INF
		state["last_card_s"] = -INF
		state["peak_alpha"] = 0.0
		state["alpha_7_5"] = -1.0
		state["alpha_8_5"] = -1.0
		state["last_position_s"] = 0.0
		state["ended_ms"] = -1
		state["closed_ms"] = -1
		state["result"] = {}
		state["pause_ok"] = true
		player.closed.connect(func(result: Dictionary) -> void:
			state.result = result
			state.closed_ms = Time.get_ticks_msec())
	await process_frame
	var start_ms := Time.get_ticks_msec()
	for key in cases:
		(cases[key].player as CampaignCutscenePlayer).play(plan)
	var paused_until_ms := -1
	var paused_position := -1.0
	while Time.get_ticks_msec() - start_ms < 14000:
		await process_frame
		var open := 0
		for key in cases:
			var state: Dictionary = cases[key]
			var player: CampaignCutscenePlayer = state.player
			if not player.is_active():
				continue
			open += 1
			var at := player.position_s()
			state.last_position_s = at
			if player._film_ended and int(state.ended_ms) < 0:
				state.ended_ms = Time.get_ticks_msec()
				if key == "paused":
					player.toggle_pause()
					paused_until_ms = Time.get_ticks_msec() + 500
					paused_position = at
			if key == "paused" and paused_until_ms > 0:
				if Time.get_ticks_msec() < paused_until_ms:
					state.pause_ok = bool(state.pause_ok) and absf(at - paused_position) < 0.001
				else:
					paused_until_ms = 0
					player.toggle_pause()
			var shown := player.choice_card_text()
			if not shown.is_empty():
				state.first_card_s = minf(float(state.first_card_s), at)
				state.last_card_s = maxf(float(state.last_card_s), at)
				state.peak_alpha = maxf(float(state.peak_alpha), player._card.modulate.a)
				state["text"] = shown
				state["font_px"] = player._card.get_theme_font_size("font_size")
				state["rect"] = player._card.get_global_rect()
			if absf(at - 7.5) < 0.05:
				state.alpha_7_5 = player._card.modulate.a if player._card.visible else 0.0
			if absf(at - 8.5) < 0.05:
				state.alpha_8_5 = player._card.modulate.a if player._card.visible else 0.0
		if open == 0:
			break
	for key in ["opt01", "none"]:
		var state: Dictionary = cases[key]
		var close_s := (int(state.closed_ms) - start_ms) / 1000.0
		_check(float(state.first_card_s) == INF and float(state.peak_alpha) == 0.0, "%s: nothing drawn on the black" % key)
		_check(int(state.closed_ms) > 0 and absf(close_s - FILM_S) < 0.35 and float(state.last_position_s) <= FILM_S + 0.05, "%s: the film ends at 8.0 s as before (closed at %.2f s, last frame %.2f s)" % [key, close_s, state.last_position_s])
		_check(not (state.result as Dictionary).is_empty() and not bool(state.result.skipped) and String(state.result.choice_card).is_empty(), "%s: finishes unskipped with no card reported" % key)
	var opt02: Dictionary = cases.opt02
	var close_s := (int(opt02.closed_ms) - start_ms) / 1000.0
	var hold_s := (int(opt02.closed_ms) - int(opt02.ended_ms)) / 1000.0
	_check(String(opt02.get("text", "")) == label, "OPT02: the words on the black are the catalog label")
	_check(float(opt02.first_card_s) >= 7.0 and float(opt02.first_card_s) < 7.1, "OPT02: the words appear at 7.0 s, not over the picture (first at %.3f s)" % opt02.first_card_s)
	_check(float(opt02.alpha_7_5) > 0.99 and float(opt02.alpha_8_5) > 0.99, "OPT02: fully shown at 7.5 s and 8.5 s (%.2f, %.2f)" % [opt02.alpha_7_5, opt02.alpha_8_5])
	_check(float(opt02.last_card_s) > 8.8 and float(opt02.last_card_s) < 9.0, "OPT02: still on screen in the hold, gone by 9.0 s (last at %.3f s)" % opt02.last_card_s)
	_check(int(opt02.ended_ms) > 0 and absf((int(opt02.ended_ms) - start_ms) / 1000.0 - FILM_S) < 0.35, "OPT02: the film itself still ends at 8.0 s")
	_check(absf(hold_s - 1.0) < 0.2 and absf(close_s - 9.0) < 0.4, "OPT02: one second of silent black after the film; closes at %.2f s (hold %.2f s)" % [close_s, hold_s])
	var result: Dictionary = opt02.result
	_check(not result.is_empty() and not bool(result.skipped) and String(result.choice_card) == label and float(result.position_s) == INF and not bool(result.completes_scene), "OPT02: finishes unskipped, reports its card, completes nothing")
	var rect: Rect2 = opt02.get("rect", Rect2())
	var margin := UiDesign.px(64.0, 720.0)
	_check(int(opt02.get("font_px", 0)) == UiDesign.font_px("body", 720.0, 1.0), "OPT02: small, in the UiDesign body size (%s px)" % opt02.get("font_px", 0))
	_check(absf(rect.end.y - (720.0 - margin)) < 2.0 and absf(rect.get_center().x - 640.0) < 2.0 and rect.position.y > 600.0, "OPT02: centred near the bottom of the black (%s)" % rect)
	var paused: Dictionary = cases.paused
	var paused_hold := (int(paused.closed_ms) - int(paused.ended_ms)) / 1000.0
	_check(bool(paused.pause_ok) and absf(paused_hold - 1.5) < 0.25, "pausing in the hold stops its clock (hold %.2f s with 0.5 s paused)" % paused_hold)
	_check(int(paused.get("font_px", 0)) == UiDesign.font_px("body", 720.0, 1.5), "large text scales the words 150%% (%s px)" % paused.get("font_px", 0))
	host.free()
	await process_frame

var _snapshot_ok := true

## A real director whose save holds the given D13 option (none when empty).
func _director(option_id: String, large_text: bool = false) -> CampaignDirector:
	var director := CampaignDirector.new()
	director.new_campaign()
	var snapshot := director.snapshot()
	if not option_id.is_empty():
		snapshot.story_log.choices[CHOICE_ID] = {"option_id": option_id, "scene_id": "EX-CH08-S12", "scenario_datetime": snapshot.scenario_datetime, "state_revision": snapshot.state_revision}
	snapshot.accessibility.large_text = large_text
	var restored := director.restore_snapshot(snapshot)
	_snapshot_ok = _snapshot_ok and bool(restored.get("accepted", false))
	return director

func _catalog_label(option_id: String) -> String:
	var catalog: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	for scene in (catalog as Dictionary).get("scenes", []):
		for option in (scene as Dictionary).get("choice", {}).get("options", []):
			if String(option.get("id", "")) == option_id:
				return String(option.get("label", ""))
	return ""

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)
