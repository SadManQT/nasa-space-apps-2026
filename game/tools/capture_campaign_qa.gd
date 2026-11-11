## QA sweep (M1-21, M3-2Q..M3-8Q, M3-92): plays the production campaign from a
## new expedition through all eight chapters with the supported inputs, and at
## each of the 96 scenes saves a start and an end screenshot and scans every
## visible HUD string for developer language (25 §8.1).
## Windowed: Godot --path game --resolution 1280x720 --script res://tools/capture_campaign_qa.gd -- [--chapters=1-8]
## Writes production/qa/evidence/qa_campaign/chNN/<scene>_{start,end}.png and report.json.
extends SceneTree

const CampaignScene: PackedScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const PlantInput = preload("res://tools/support/p01_input_fixture.gd")
const PlanFixture = preload("res://tools/support/p02_plan_fixture.gd")
const Witness2 = preload("res://tools/support/chapter2_witness.gd")
const Witness3 = preload("res://tools/support/chapter3_witness.gd")
const Witness4 = preload("res://tools/support/chapter4_witness.gd")
const Witness6 = preload("res://tools/support/chapter6_witness.gd")
const Witness8 = preload("res://tools/support/chapter8_witness.gd")
const PuzzleData = preload("res://scripts/puzzles/puzzle_data.gd")
const ACTIONS_CH1 := [
	["commission_route", "commission_result", "charter_card"],
	["classify_information", "roll_call", "practice_fault"],
	["calibrate_probe", "span_probe", "recheck_probe", "inspect_packet", "compare_atmosphere"],
	["plant_alo", "plant_tara", "water_alo", "water_tara", "label_alo", "label_tara", "seal_alo", "seal_tara", "record_paired_conditions", "confirm_services"],
	["test_hand_light", "care_montage", "confirm_date_transition"],
	["arrange_timeline", "ack_schedule"],
	["role_cards", "p02_shift1", "p02_stage_shift2"],
	["shelter_drill", "verify_drill_baseline", "p02_shift2"],
	["combine_cards", "ack_earth_set", "p02_shifts3_4"],
	["confirm_four_sheltered", "p02_shift5_alarm"],
	["verify_exposure_order", "return_water", "p02_shifts6_7", "review_outcome"],
	["verify_chamber", "open_shutter", "tag_bloom", "inspect_tara", "complete_debrief"],
]
const DEV_WORDS := ["commit", "committed", "stage", "acknowledge", "acknowledged", "role constraint", "operation", "operations"]

var storage = preload("res://tools/support/isolated_storage.gd").new()
var campaign: Chapter1Campaign
var out_dir := ""
var report := {"scenes": [], "failures": []}
var first_chapter := 1
var last_chapter := 8
var _dev_regex := RegEx.new()
var _id_regex := RegEx.new()

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--chapters="):
			var span := arg.trim_prefix("--chapters=").split("-")
			first_chapter = int(span[0])
			last_chapter = int(span[span.size() - 1])
	_dev_regex.compile("(?i)\\b(" + "|".join(DEV_WORDS) + ")\\b")
	_id_regex.compile("EX-CH\\d|\\bP-\\d\\d\\b|\\b[EAWKSZCRH] ?\\d+\\b")
	root.size = Vector2i(1280, 720)
	out_dir = ProjectSettings.globalize_path("res://../production/qa/evidence/qa_campaign")
	DirAccess.make_dir_recursive_absolute(out_dir)
	CampaignCutscenePlayer.autoplay = false
	if not storage.setup("campaign_qa"):
		quit(1)
		return
	storage.prepare_rendering_cache()
	campaign = CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	root.add_child(campaign)
	await _settle()
	PlanFixture.prepare(campaign.route)
	var chapter := 1
	while chapter <= last_chapter:
		var record := chapter >= first_chapter
		var done := await _play_chapter(chapter, record)
		if not done:
			break
		chapter += 1
	var file := FileAccess.open(out_dir.path_join("report.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	print("CAMPAIGN QA: %d scenes recorded, %d failures, %d developer-text hits" % [report.scenes.size(), report.failures.size(), report.scenes.reduce(func(total, scene): return total + (scene.dev_text as Array).size(), 0)])
	campaign.free()
	storage.cleanup()
	quit(0 if report.failures.is_empty() else 1)

func _play_chapter(chapter: int, record: bool) -> bool:
	for index in 12:
		var scene_id := String(campaign.route.current_scene_id())
		var expected := "EX-CH%02d-S%02d" % [chapter, index + 1]
		if scene_id != expected:
			_fail("expected %s but the campaign is at %s" % [expected, scene_id])
			return false
		var entry := {"scene_id": scene_id, "room_id": String(campaign.route.current_room_id()), "date": String(campaign.director.snapshot().get("scenario_datetime", "")), "dev_text": [], "targets": 0}
		if record:
			await _shot(chapter, scene_id + "_start")
			entry.dev_text = _scan_text()
		if chapter == 1:
			if not await _chapter1_scene(index, scene_id):
				return false
			entry.targets = ACTIONS_CH1[index].size()
		else:
			var targets: Array = campaign.route.targets_for_current_scene()
			for target in targets:
				if not await _use(target, chapter):
					return false
			entry.targets = targets.size()
		_close_panels()
		if record:
			await _shot(chapter, scene_id + "_end")
			for hit in _scan_text():
				if not (entry.dev_text as Array).has(hit):
					entry.dev_text.append(hit)
			report.scenes.append(entry)
		var advanced := campaign.advance_scene()
		await _settle()
		if not bool(advanced.get("accepted", false)) and not bool(advanced.get("upgrade_pending", false)):
			_fail("%s did not advance: %s" % [scene_id, String(advanced.get("reason", ""))])
			return false
		if index == 11:
			await _cross_boundary(chapter)
	return true

func _chapter1_scene(index: int, scene_id: String) -> bool:
	campaign.hud._decision_review.pressed.emit()
	var option := campaign.hud.panels.find_child(scene_id + "-OPT01", true, false) as Button
	var confirm := campaign.hud.panels.find_child("ConfirmChoice", true, false) as Button
	if option == null or confirm == null:
		_fail(scene_id + " decision review is missing")
		return false
	option.pressed.emit()
	confirm.pressed.emit()
	await process_frame
	for target_id in ACTIONS_CH1[index]:
		var target := campaign.physical_target(String(target_id))
		if target == null:
			_fail(scene_id + " has no physical target " + String(target_id))
			return false
		if String(target_id) == "calibrate_probe":
			PlantInput.complete_probe_transfer(campaign.route)
		campaign._player.global_position = Vector3(target.global_position.x, 0.0, target.global_position.z + 1.0)
		campaign._player.velocity = Vector3.ZERO
		await physics_frame
		var result := campaign.perform_target(String(target_id), PlantInput.payload(String(target_id)))
		if not bool(result.get("accepted", false)):
			_fail("%s %s: %s" % [scene_id, target_id, String(result.get("reason", ""))])
			return false
	return true

func _use(target: Dictionary, chapter: int) -> bool:
	var target_id := String(target.get("target_id", ""))
	await _stand_at(target_id)
	var payload: Dictionary
	if chapter == 2:
		payload = Witness2.payload(String(target.get("puzzle_action", "")))
	else:
		payload = (target.get("payload_defaults", {}) as Dictionary).duplicate(true) if target.get("payload_defaults", {}) is Dictionary else {}
		if payload.is_empty():
			payload = PuzzleData.gate_payload(String(target.get("puzzle_action", "")))
		var state: Dictionary = campaign.director.snapshot()
		payload = Witness3.payload(target_id, state, payload)
		payload = Witness4.payload(target_id, state, payload)
		payload = Witness6.payload(target_id, state, payload)
		payload = Witness8.payload(target_id, state, payload)
	_close_panels()
	var result := campaign.perform_target(target_id, payload)
	# A timed transition (an airlock equalising) plays first; wait as a player would.
	for wait in 15:
		if bool(result.get("accepted", false)) or not String(result.get("reason", "")).contains("SHOWN IN"):
			break
		for frame in 60:
			await process_frame
		await _stand_at(target_id)
		result = campaign.perform_target(target_id, payload)
	if not bool(result.get("accepted", false)):
		_fail("%s %s: %s" % [campaign.route.current_scene_id(), target_id, String(result.get("reason", ""))])
		return false
	return true

## Stands where a player would: the authored approach point, then a ring of
## spots around the prop, until this job is the one offered.
func _stand_at(target_id: String) -> void:
	var node := campaign.physical_target(target_id)
	if node == null:
		return
	var approach: Array = node.get_meta("approach_m", [])
	var spots: Array = [campaign._room.to_global(Vector3(float(approach[0]), float(approach[1]), float(approach[2]))) if approach.size() == 3 else node.global_position + Vector3(0, 0, 1)]
	for ring in [1.2, 2.0]:
		for step in 8:
			var angle := TAU * step / 8.0
			spots.append(Vector3(node.global_position.x + cos(angle) * ring, spots[0].y, node.global_position.z + sin(angle) * ring))
	for spot in spots:
		campaign._player.global_position = spot
		campaign._player.velocity = Vector3.ZERO
		for frame in 3:
			campaign._player.follow_camera.camera.look_at(node.global_position)
			await physics_frame
			if String(campaign.nearby_target().get("target_id", "")) == target_id:
				return

## Chapter end: close What you learned, take any earned upgrade, then the next
## chapter starts (choosing the upgrade starts it; otherwise advance once more).
func _cross_boundary(chapter: int) -> void:
	for attempt in 4:
		_close_panels()
		await _settle()
		var pending := campaign.available_upgrade_chapter()
		if pending > 0:
			campaign.choose_upgrade(pending, "A")
			await _settle()
			continue
		if chapter < 8 and String(campaign.route.current_scene_id()).begins_with("EX-CH%02d" % chapter):
			campaign.advance_scene()
			await _settle()
			continue
		break
	_close_panels()

func _close_panels() -> void:
	var hud = campaign.hud
	if hud == null:
		return
	if is_instance_valid(hud._family_panel):
		hud.close_family()
	for name in ["chapter2_panel", "chapter3_panel", "chapter4_panel", "chapter6_panel", "chapter8_panel", "mission_table", "p01_panel"]:
		var panel = hud.get(name)
		if panel != null and panel.has_method("is_open") and panel.is_open():
			panel.close()
	if not hud.panels.active_panel().is_empty():
		hud.panels.close_panel()

func _settle() -> void:
	for frame in 6:
		await physics_frame
	await campaign.wait_loading()
	if campaign.hud != null:
		campaign.hud.refresh_scene()
	for frame in 4:
		await process_frame

func _shot(chapter: int, name: String) -> void:
	var folder := out_dir.path_join("ch%02d" % chapter)
	DirAccess.make_dir_recursive_absolute(folder)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join(name + ".png"))

## Visible HUD strings that match developer language (25 §8.1).
func _scan_text() -> Array:
	var hits: Array = []
	if campaign.hud == null:
		return hits
	for node in campaign.hud.find_children("*", "Control", true, false):
		var control := node as Control
		if not control.is_visible_in_tree():
			continue
		var text := ""
		if control is Label:
			text = (control as Label).text
		elif control is RichTextLabel:
			text = (control as RichTextLabel).get_parsed_text()
		elif control is Button:
			text = (control as Button).text
		if text.strip_edges().is_empty():
			continue
		var found := _dev_regex.search(text)
		if found == null:
			found = _id_regex.search(text)
		if found != null:
			hits.append({"match": found.get_string(), "text": text.left(160), "node": String(control.name)})
	return hits

func _fail(message: String) -> void:
	report.failures.append(message)
	printerr("QA FAIL: " + message)
