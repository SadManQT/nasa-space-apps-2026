## Clean chapter-entry representatives, using the text walk's real witnesses.
## Run after run_tests.sh: Godot --path game --windowed --script
## res://tools/capture_goals_m162.gd -- --capture
extends "res://tools/test_player_text.gd"

var _captures := {}

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var campaign := CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	root.add_child(campaign)
	await campaign.wait_loading()
	await _clean_chapter(campaign)
	PlanFixture.prepare(campaign.route)
	_reach_route(campaign.route, "EX-CH01-S12")
	for target in campaign.targets_for_current_scene():
		_check(campaign.route.perform(String(target.target_id)).get("accepted", false), "clean capture Chapter1 final witness " + String(target.target_id))
	_check(campaign.route.advance_scene().get("accepted", false), "clean capture Chapter1 closes")
	campaign._sync_route_projection()
	var chosen := campaign.choose_upgrade(1, "A")
	_check(chosen.get("accepted", false) and chosen.get("persisted", false) and campaign.route.current_scene_id() == "EX-CH02-S01", "clean capture enters Chapter2 after saving its earned upgrade")
	for scene_id in Chapter2Gates.scene_ids() + LaterGates.scene_ids():
		if campaign.loading:
			await campaign.wait_loading()
		_check(campaign.route.current_scene_id() == scene_id, "clean capture reaches " + String(scene_id))
		if String(scene_id).ends_with("S01"):
			await _clean_chapter(campaign)
		for target in campaign.targets_for_current_scene():
			if target.target_id == "inspect_alo_identity":
				await _job_nudge(campaign)
			if target.target_id == "p05_equip_gauge":
				campaign.hud.refresh_scene()
			var result: Dictionary = campaign.route.perform(String(target.target_id), _player_payload(target, campaign.director.snapshot()))
			_check(result.get("accepted", false), "clean capture real witness " + String(target.target_id) + ": " + String(result.get("reason", "")))
			if target.target_id == "p05_equip_gauge":
				campaign.hud.refresh_after_action(result.get("result", result))
				await _last_result(campaign)
		var advanced: Dictionary = campaign.route.advance_scene()
		_check(advanced.get("accepted", false), "clean capture advances " + String(scene_id))
		if advanced.get("chapter_complete", false) and not advanced.get("campaign_complete", false):
			var chapter := int(String(scene_id).substr(5, 2))
			campaign._sync_route_projection()
			chosen = campaign.choose_upgrade(chapter, "A")
			_check(chosen.get("accepted", false) and chosen.get("persisted", false) and campaign.route.current_scene_id() == "EX-CH%02d-S01" % (chapter + 1), "clean capture opens next chapter after saving its earned upgrade")
		else:
			campaign._sync_route_projection()
	var hashes := {}
	for path in ["resources/campaign/content/ui_text.json", "scripts/ui/chapter1_campaign_hud.gd", "scripts/ui/campaign_panels.gd", "tools/test_player_text.gd", "tools/test_science_data.gd", "tools/capture_goals_m162.gd"]:
		hashes[path] = FileAccess.get_sha256("res://" + path)
	var file := FileAccess.open("res://../production/qa/evidence/M1-62_clean_probes.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"scope": "Clean actual chapter-entry rooms and HUD; scripted catalog witnesses, not physical traversal. No injected prerequisite toast or target teleport.", "engine": Engine.get_version_info(), "source_sha256": hashes, "captures": _captures, "representative_bounds": _goal_bounds, "checks": checks, "failures": failures}, " "))
	file.close()
	campaign.free()
	storage.cleanup()
	print("M1-62 CLEAN CAPTURE RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _clean_chapter(campaign: Chapter1Campaign) -> void:
	var hud := campaign.hud
	for line in campaign.current_dialogue():
		campaign.route.acknowledge_dialogue(String(line.id))
	hud.refresh_scene()
	await create_timer(0.4).timeout
	# This pass never injects diagnostic status, so no real warning is removed.
	for large in [false, true]:
		_set_text_scale(campaign, large)
		await process_frame
		await process_frame
		var name: String = "clean_" + campaign.route.current_scene_id().substr(3, 4) + ("_150" if large else "_normal")
		_check_goal_bounds(hud, name)
		await _capture_goal(hud, name)
		var card := hud.get_node("GoalCard") as Control
		_captures["M1-62_" + name + ".png"] = {"scene": campaign.route.current_scene_id(), "target": hud._goal_info.target_id, "goal": hud._title.text, "why": hud._why.text, "large_text": large, "viewport": [root.size.x, root.size.y], "card": [card.position.x, card.position.y, card.size.x, card.size.y], "title": [hud._title.position.x, hud._title.position.y, hud._title.size.x, hud._title.size.y], "why_bounds": [hud._why.position.x, hud._why.position.y, hud._why.size.x, hud._why.size.y], "captured_utc": Time.get_datetime_string_from_system(true)}
	_set_text_scale(campaign, false)

func _job_nudge(campaign: Chapter1Campaign) -> void:
	var hud := campaign.hud
	hud.panels.open_panel("what_now")
	(hud.find_child("WhatNowHint", true, false) as Button).pressed.emit()
	for large in [false, true]:
		hud.panels.hint_player.set_settings({"large_text": large})
		var texts: Array[String] = []
		_visible_text(hud.panels.hint_player, texts)
		_check(texts.has(String(UiDesign.text().targets.inspect_alo_identity.hint)), "clean H1 contains actual authored job nudge")
		await _modal_capture(campaign, "job_nudge" + ("_150" if large else "_normal"), large, texts)
	hud.panels.hint_player.close()
	hud.panels.close_panel()

func _last_result(campaign: Chapter1Campaign) -> void:
	var hud := campaign.hud
	hud.panels.open_panel("outcome")
	for large in [false, true]:
		hud.panels.set_accessibility({"large_text": large})
		await process_frame
		await process_frame
		var texts: Array[String] = []
		_visible_text(hud.panels, texts)
		_check(texts.has(String(UiDesign.text().targets.p05_equip_gauge.result)), "clean Last result contains actual accepted gauge result")
		_check(hud.panels._panel.get_global_rect().encloses(hud.panels._close_button.get_global_rect().grow(2)), "clean Last result Close and focus border fit at both scales")
		await _modal_capture(campaign, "last_result" + ("_150" if large else "_normal"), large, texts)
	hud.panels.close_panel()
	_set_text_scale(campaign, false)

func _modal_capture(campaign: Chapter1Campaign, name: String, large: bool, texts: Array[String]) -> void:
	await _capture_goal(campaign.hud, name)
	var file_name := "M1-62_" + name + ".png"
	var close: Rect2 = campaign.hud.panels._close_button.get_global_rect()
	_captures[file_name] = {"scene": campaign.route.current_scene_id(), "large_text": large, "visible_text": texts, "close": [close.position.x, close.position.y, close.size.x, close.size.y], "captured_utc": Time.get_datetime_string_from_system(true), "png_sha256": FileAccess.get_sha256("res://../production/qa/evidence/" + file_name)}
