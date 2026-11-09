## Windowed M3-8P evidence: the Chapter 8 puzzle panel (P-15 / P-16) in the
## real campaign. Run after run_tests.sh has imported assets:
##   Godot --path game --windowed --resolution 1280x720 --script res://tools/capture_chapter8_puzzles.gd
## Writes production/qa/evidence/M3-8P_*.png and M3-8P_capture_probe.txt.
extends SceneTree

const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const RouteScript = preload("res://scripts/missions/extended_campaign_route.gd")
const GateCatalog = preload("res://scripts/missions/extended_gate_catalog.gd")
const PuzzleScript = preload("res://scripts/puzzles/chapter8_puzzles.gd")
const Witness = preload("res://tools/support/chapter8_witness.gd")
const CampaignScene: PackedScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
var storage = preload("res://tools/support/isolated_storage.gd").new()
var campaign: Chapter1Campaign
var failures := 0
var probe: Array = []

func _init() -> void:
	if not storage.setup("M3-8P-capture"):
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.always_on_top = true
	root.grab_focus()
	CampaignCutscenePlayer.autoplay = false
	var entry := _entry_state()
	if entry.is_empty():
		_finish()
		return
	campaign = CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	campaign.initial_snapshot = entry
	root.add_child(campaign)
	for index in 12:
		await physics_frame
	await campaign.wait_loading()
	campaign.hud.refresh_scene()
	await process_frame
	_expect(campaign._startup_error.is_empty() and campaign.route.current_scene_id() == "EX-CH08-S01", "the campaign restores at the Chapter 8 departure board")
	await _capture("hud_decide_cards")
	var panel: Chapter8PuzzlePanel = campaign.hud.chapter8_panel
	# S01 · teams: first-time card, then a wrong-but-reasonable board held with Mei's feedback.
	_expect(campaign.hud.open_chapter8_panel("p15_confirm_teams"), "the HUD opens the team boards card")
	await _capture("s01_teams_first_time")
	panel.dismiss_first_time()
	panel.inspect_clue("c1")
	panel.inspect_clue("c3")
	for pair in [["mei", "rover"], ["kai", "rover"], ["rafi", "rover"], ["ferreira", "home"], ["amara", "home"]]:
		panel.choose(pair[0], pair[1])
	var held: Dictionary = panel.try_it()
	_expect(not bool(held.accepted), "Mei on the rover is held before anything changes")
	await _capture("s01_teams_held")
	panel.undo()
	for pair in [["ferreira", "rover"], ["kai", "rover"], ["rafi", "rover"], ["mei", "home"], ["amara", "home"]]:
		panel.choose(pair[0], pair[1])
	_expect(bool(panel.try_it().accepted), "the correct boards are accepted by the real preview")
	await _capture("s01_teams_preview")
	panel.request_commit()
	await _capture("s01_teams_confirm")
	await _lock_in(panel, "p15_confirm_teams")
	await _capture("s01_teams_outcome")
	campaign.hud.panels.close_panel()
	await _play_scene_rest("EX-CH08-S01", ["p15_confirm_teams"])
	# S02 · the road: shortcut held by the flight rule, surveyed road with the reserve.
	await _advance_to("EX-CH08-S02")
	_expect(campaign.hud.open_chapter8_panel("p15_choose_surveyed_route"), "the HUD opens the route card")
	panel.choose("route", "SHORTCUT")
	panel.choose("reserve", 7)
	_expect(not bool(panel.try_it().accepted), "the 22° shortcut is held by the flight rule")
	await _capture("s02_shortcut_held")
	panel.undo()
	panel.choose("route", "SURVEYED")
	panel.choose("reserve", 4)
	panel.reveal_hint()
	_expect(bool(panel.try_it().accepted), "the surveyed road with reserve 4 is accepted")
	await _capture("s02_surveyed_preview")
	panel.request_commit()
	await _lock_in(panel, "p15_choose_surveyed_route")
	campaign.hud.panels.close_panel()
	await _play_scene_rest("EX-CH08-S02", ["p15_choose_surveyed_route"])
	# S04 · the repeater procedure card and the chain test.
	await _advance_to("EX-CH08-S03")
	await _play_scene_rest("EX-CH08-S03", [])
	await _advance_to("EX-CH08-S04")
	_expect(campaign.hud.open_chapter8_panel("p15_restore_marker_2"), "the HUD opens the repeater procedure card")
	panel.choose("step", "reconnect")
	await _capture("s04_procedure_held")
	for id in ["isolate", "remove_battery", "compare_spec", "install_spare", "close_housing", "reconnect"]:
		panel.choose("step", id)
	_expect(bool(panel.try_it().accepted), "the completed procedure card is accepted")
	await _capture("s04_procedure_complete")
	panel.request_commit()
	await _lock_in(panel, "p15_restore_marker_2")
	campaign.hud.panels.close_panel()
	await _play_scene_rest("EX-CH08-S04", ["p15_restore_marker_2"])
	# S05 · the home loop: return CLOSED prompts the thirst forecast.
	await _advance_to("EX-CH08-S05")
	await _play_targets(["p15_confirm_home_occupancy"])
	_expect(campaign.hud.open_chapter8_panel("p15_confirm_segment_forecast"), "the HUD opens the home loop card")
	panel.choose("heat", "COOL")
	panel.choose("light", "DIM")
	panel.choose("water_return", "CLOSED")
	panel.choose("air_total", 2.8125)
	_expect(not bool(panel.try_it().accepted), "return CLOSED is held with the thirst forecast")
	await _capture("s05_home_loop_thirst")
	panel.choose("water_return", "OPEN")
	_expect(bool(panel.try_it().accepted), "the home loop and the air prediction are accepted")
	await _capture("s05_home_loop_preview")
	panel.request_commit()
	await _lock_in(panel, "p15_confirm_segment_forecast")
	campaign.hud.panels.close_panel()
	await _play_scene_rest("EX-CH08-S05", ["p15_confirm_home_occupancy", "p15_confirm_segment_forecast"])
	# S06 and S07 straight through; S08 · both dials.
	await _advance_to("EX-CH08-S06")
	await _play_scene_rest("EX-CH08-S06", [])
	await _advance_to("EX-CH08-S07")
	_expect(campaign.hud.open_chapter8_panel("p16_isolate_power"), "the HUD opens the controller card")
	panel.choose("option", "reset_live")
	_expect(not bool(panel.try_it().accepted), "the live reset is held")
	await _capture("s07_reset_held")
	panel.close()
	await _play_scene_rest("EX-CH08-S07", [])
	await _advance_to("EX-CH08-S08")
	_expect(campaign.hud.open_chapter8_panel("p16_earth_bearing"), "the Earth dish card opens while waiting")
	await _capture("s08_earth_waiting")
	panel.close()
	_expect(campaign.hud.open_chapter8_panel("p16_local_bearing"), "the HUD opens the local dial")
	panel.choose("bearing", 186)
	_expect(not bool(panel.try_it().accepted), "the obstructed preset is held with its obstruction text")
	await _capture("s08_local_obstructed")
	panel.choose("preset", "L2")
	_expect(bool(panel.try_it().accepted), "preset 2 locks the road chain")
	await _capture("s08_local_locked")
	panel.request_commit()
	await _lock_in(panel, "p16_local_bearing")
	campaign.hud.panels.close_panel()
	_expect(campaign.hud.open_chapter8_panel("p16_earth_bearing"), "the HUD opens the Earth dish")
	panel.choose("bearing", 4)
	_expect(not bool(panel.try_it().accepted), "strong but obstructed is held")
	await _capture("s08_earth_obstructed")
	panel.choose("preset", "E3")
	panel.try_it()
	panel.request_commit()
	await _lock_in(panel, "p16_earth_bearing")
	campaign.hud.panels.close_panel()
	await _play_scene_rest("EX-CH08-S08", ["p16_local_bearing", "p16_earth_bearing"])
	# S09 · ALO42 near match.
	await _advance_to("EX-CH08-S09")
	_expect(campaign.hud.open_chapter8_panel("p16_checksum"), "the HUD opens the checksum card")
	panel.choose("option", "near")
	_expect(not bool(panel.try_it().accepted), "the near match is held")
	await _capture("s09_checksum_near_match")
	panel.choose("option", "exact")
	_expect(bool(panel.try_it().accepted), "the exact current echo is accepted")
	await _capture("s09_checksum_exact")
	panel.request_commit()
	await _lock_in(panel, "p16_checksum")
	campaign.hud.panels.close_panel()
	await _play_scene_rest("EX-CH08-S09", ["p16_checksum"])
	for scene_id in ["EX-CH08-S10", "EX-CH08-S11"]:
		await _advance_to(scene_id)
		await _play_scene_rest(scene_id, [])
	# S12 · the five checks and the dedication, at 150% text.
	await _advance_to("EX-CH08-S12")
	_set_large_text(true)
	_expect(campaign.hud.open_chapter8_panel("p16_save_final_records"), "the HUD opens the five checks at 150% text")
	for id in ["crew", "seeds", "pressure", "temperature", "cotton"]:
		panel.choose(id, true)
	_expect(bool(panel.try_it().accepted), "the five checks pass against their readings")
	await _capture("s12_five_checks_large_text")
	var commit := panel.find_child("Commit", true, false) as Control
	probe.append("large text: viewport %s, frame %s, commit %s" % [str(campaign.hud.get_viewport_rect()), str(panel._frame.get_global_rect()), str(commit.get_global_rect() if commit != null else Rect2())])
	_expect(commit != null and campaign.hud.get_viewport_rect().encloses(commit.get_global_rect()) and campaign.hud.get_viewport_rect().encloses(panel._frame.get_global_rect()), "the panel and LOCK IN stay on screen at 150% text")
	panel.request_commit()
	await _lock_in(panel, "p16_save_final_records")
	campaign.hud.panels.close_panel()
	_set_large_text(false)
	await _play_targets(["p16_save_photo"])
	_expect(campaign.hud.open_chapter8_panel("p16_save_dedication"), "the HUD opens the dedication card")
	panel.choose("option", "hands")
	panel.try_it()
	await _capture("s12_dedication")
	panel.request_commit()
	await _lock_in(panel, "p16_save_dedication")
	campaign.hud.panels.close_panel()
	await _play_targets(["p16_make_credits_available"])
	var moved: Dictionary = campaign.advance_scene()
	_expect(bool(moved.get("campaign_complete", false)) or campaign.is_campaign_complete(), "the campaign completes from the player's decisions")
	await _capture("s12_campaign_complete")
	_finish()

func _entry_state() -> Dictionary:
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
	for scene_id in GateCatalog.scene_ids():
		if scene_id.begins_with("EX-CH08"):
			break
		for target in GateCatalog.targets_for_scene(scene_id):
			if not bool(route.perform(target.target_id, target.get("payload_defaults", {})).get("accepted", false)):
				_expect(false, "fixture reaches Chapter 8 (stuck at %s / %s)" % [scene_id, target.target_id])
				return {}
		var moved: Dictionary = route.advance_scene()
		if bool(moved.get("chapter_complete", false)):
			route.start_at("EX-CH%02d-S01" % (int(scene_id.substr(5, 2)) + 1))
	var state: Dictionary = director.snapshot()
	state["route_runtime"] = route.snapshot()
	state["route_runtime"]["chapter"] = 8
	return JSON.parse_string(JSON.stringify(state))

## Confirms the open confirmation with the player standing at the target.
func _lock_in(panel: Chapter8PuzzlePanel, target_id: String) -> void:
	await _stand_at(target_id)
	var result: Dictionary = panel.confirm_commit()
	await process_frame
	await process_frame
	_expect(bool(result.get("accepted", false)) and campaign.route.chapter8_view(target_id).committed, "%s locks in through the HUD" % target_id)

## Plays the remaining operations of a scene with the witness, as a player would.
func _play_scene_rest(scene_id: String, done: Array) -> void:
	var ids: Array = []
	for target in GateCatalog.targets_for_scene(scene_id):
		if not done.has(String(target.target_id)):
			ids.append(String(target.target_id))
	await _play_targets(ids)

func _play_targets(ids: Array) -> void:
	for target_id in ids:
		await _stand_at(target_id)
		var result: Dictionary = campaign.perform_target(target_id, Witness.payload(target_id, campaign.director.snapshot()))
		_expect(bool(result.get("accepted", false)), "%s plays with the witness (%s)" % [target_id, String(result.get("reason", ""))])
		if campaign.hud.panels.active_panel() != "":
			campaign.hud.panels.close_panel()

func _advance_to(scene_id: String) -> void:
	var moved: Dictionary = campaign.advance_scene()
	_expect(bool(moved.get("accepted", false)) and campaign.route.current_scene_id() == scene_id, "advance to " + scene_id)
	await campaign.wait_loading()
	campaign.hud.refresh_scene()
	await process_frame
	await process_frame

func _set_large_text(value: bool) -> void:
	var state: Dictionary = campaign.director.snapshot()
	state.accessibility.large_text = value
	campaign.director.restore_snapshot(state)
	campaign.hud.apply_accessibility()

func _stand_at(target_id: String) -> void:
	var target: Node3D = campaign.physical_target(target_id)
	if target == null:
		_expect(false, "physical target " + target_id)
		return
	var approach: Array = target.get_meta("approach_m", []) if target.has_meta("approach_m") else []
	if approach.size() >= 3:
		campaign._player.global_position = Vector3(float(approach[0]), float(approach[1]), float(approach[2]))
	else:
		campaign._player.global_position = Vector3(target.global_position.x, 0.0, target.global_position.z + 1.0)
	campaign._player.velocity = Vector3.ZERO
	await physics_frame
	await physics_frame

func _expect(condition: bool, message: String) -> void:
	probe.append(("ok   " if condition else "FAIL ") + message)
	if not condition:
		failures += 1
		push_error("FAIL " + message)

func _capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../production/qa/evidence/M3-8P_%s.png" % label)
	var error := root.get_texture().get_image().save_png(path)
	if error != OK:
		failures += 1
	probe.append("screenshot %s (%s)" % [path.get_file(), "saved" if error == OK else "error %d" % error])
	print("M3-8P evidence: ", path, " (", error, ")")

func _finish() -> void:
	if campaign != null:
		campaign.free()
	storage.cleanup()
	probe.append("RESULT %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	var file := FileAccess.open(ProjectSettings.globalize_path("res://../production/qa/evidence/M3-8P_capture_probe.txt"), FileAccess.WRITE)
	if file != null:
		file.store_string("\n".join(probe) + "\n")
	print("M3-8P CHAPTER 8 PUZZLE CAPTURE RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
