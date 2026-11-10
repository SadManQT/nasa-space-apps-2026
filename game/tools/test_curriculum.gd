extends SceneTree

## M3-69: real mission coverage, save-derived learning moments, actual recorded
## decisions, spoiler gates and the read-only Academy Manual presentation.

const CurriculumModel = preload("res://scripts/progression/curriculum.gd")
const ManualPanel = preload("res://scripts/ui/academy_manual.gd")
const CampaignStateScript = preload("res://scripts/core/campaign_state.gd")
const Content = preload("res://scripts/content/content_loader.gd")

var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_authored_coverage()
	_test_moment_gates_and_replay()
	_test_all_chapter_debriefs()
	await _test_manual_ui()
	print("CURRICULUM RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_authored_coverage() -> void:
	var validation: Dictionary = CurriculumModel.validate()
	_check(bool(validation.valid), "curriculum validates against campaign, science fixtures and clips: " + str(validation.errors))
	var pack: Dictionary = CurriculumModel.catalog()
	_check(pack.competencies.size() == 12 and pack.chapter_debriefs.size() == 8, "12 manual pages and 8 chapter pages are authored")
	var campaign: Dictionary = Content.load_full()
	for mission in campaign.missions:
		var events: Array = CurriculumModel.moment_events_for_mission(String(mission.id))
		_check(not events.is_empty(), String(mission.id) + " has a teach, practise or prove moment")
		for event in events:
			_check(String(event.id) == "%s:%s:%s" % [event.competency_id, event.stage, event.mission_id], "stable moment ID for " + String(mission.id))
	var exported: Dictionary = CurriculumModel.catalog()
	exported.competencies.clear()
	_check(CurriculumModel.catalog().competencies.size() == 12, "callers cannot mutate the cached curriculum pack")

func _test_moment_gates_and_replay() -> void:
	var snapshot: Dictionary = CampaignStateScript.new_snapshot()
	snapshot.completed_scene_ids = []
	var before := JSON.stringify(snapshot)
	_check(not CurriculumModel.mission_complete("EX-M0101", snapshot), "an untouched mission is incomplete")
	_check(CurriculumModel.manual_page("power", snapshot).unlocked == false, "future manual text remains locked")
	_check(CurriculumModel.manual_page("power", snapshot).data_cards.is_empty(), "future data cards do not leak")
	snapshot.completed_scene_ids = ["EX-CH01-S01", "EX-CH01-S02"]
	_check(not CurriculumModel.mission_complete("EX-M0101", snapshot), "partial scene progress cannot earn a mission moment")
	_check(CurriculumModel.progress_for("power", snapshot).level == 0, "partial mission cannot unlock a competency")
	snapshot.completed_scene_ids.append("EX-CH01-S03")
	_check(CurriculumModel.mission_complete("EX-M0101", snapshot), "all three scenes complete the first mission")
	var status: Dictionary = CurriculumModel.progress_for("power", snapshot)
	_check(status.level == 1 and status.moments.learned.size() == 1 and status.moments.practised.is_empty(), "the first mission records learned only")
	var skipped: Dictionary = snapshot.duplicate(true)
	for scene_id in _mission("EX-M0602").get("scene_ids", []):
		skipped.completed_scene_ids.append(scene_id)
	var skipped_status: Dictionary = CurriculumModel.progress_for("power", skipped)
	_check(skipped_status.level == 1 and skipped_status.label == "Learned", "a proof without practice cannot skip a learning rank")
	var page: Dictionary = CurriculumModel.manual_page("power", snapshot)
	_check(page.unlocked and page.data_cards.size() >= 1 and page.explainers.size() >= 1, "learned page exposes linked real data and clips")
	_check(page.decisions.is_empty(), "the manual does not invent a choice for an unrecorded save")
	var first_scene: Dictionary = _scene("EX-CH01-S01")
	var choice: Dictionary = first_scene.choice
	var selected: Dictionary = choice.options[1]
	snapshot.story_log.choices[String(choice.id)] = {"option_id": String(selected.id), "scene_id": String(first_scene.id), "scenario_datetime": "2046-04-11 00:00 UTC", "state_revision": 1}
	page = CurriculumModel.manual_page("power", snapshot)
	_check(page.decisions.size() == 1 and page.decisions[0].choice == selected.label, "manual replays the cadet's recorded option rather than a fixed answer")
	_check(page.decisions[0].prompt == choice.prompt, "replay includes the actual story choice prompt")
	_check(CurriculumModel.moment_events_for_mission("EX-M0101") == CurriculumModel.moment_events_for_mission("EX-M0101"), "mission hook events are stable on retry")
	var observed_before := JSON.stringify(snapshot)
	CurriculumModel.progress(snapshot)
	CurriculumModel.manual_page("power", snapshot)
	_check(JSON.stringify(snapshot) == observed_before and before != observed_before, "read-only views never change the campaign snapshot")
	var all_scene_ids: Array = campaign_scene_ids()
	snapshot.completed_scene_ids = all_scene_ids
	for comp in CurriculumModel.competencies():
		var reached: Dictionary = CurriculumModel.progress_for(String(comp.id), snapshot)
		_check(reached.level == 3 and not reached.moments.learned.is_empty() and not reached.moments.practised.is_empty() and not reached.moments.proved.is_empty(), String(comp.id) + " can be learned, practised and proved in the real campaign")

func _test_all_chapter_debriefs() -> void:
	var snapshot: Dictionary = CampaignStateScript.new_snapshot()
	snapshot.completed_scene_ids = []
	for chapter in range(1, 9):
		var scene_id := "EX-CH%02d-S12" % chapter
		_check(CurriculumModel.chapter_learning(chapter, snapshot).is_empty(), "Chapter %d debrief is gated before S12" % chapter)
		snapshot.completed_scene_ids.append(scene_id)
		var chapter_page: Dictionary = CurriculumModel.chapter_learning(chapter, snapshot)
		_check(chapter_page.things.size() == 3, "Chapter %d has exactly three takeaways" % chapter)
		for thing in chapter_page.things:
			_check(not String(thing.source_title).is_empty() and not String(thing.source_takeaway).is_empty(), "Chapter %d takeaway links to a real source card" % chapter)
		_check(chapter_page.decision.is_empty(), "Chapter %d does not fabricate an absent decision" % chapter)
		var decision_scene: Dictionary = _scene(String(chapter_page.decision_scene))
		var selected: Dictionary = decision_scene.choice.options[0]
		snapshot.story_log.choices[String(decision_scene.choice.id)] = {"option_id": String(selected.id), "scene_id": String(decision_scene.id), "scenario_datetime": "2046-04-11 00:00 UTC", "state_revision": chapter}
		chapter_page = CurriculumModel.chapter_learning(chapter, snapshot)
		_check(chapter_page.decision.choice == selected.label, "Chapter %d replays a saved story choice" % chapter)
	_check(CurriculumModel.completed_chapter_learning(snapshot).size() == 8, "all eight completed chapter pages appear in the Manual")

func _test_manual_ui() -> void:
	var snapshot: Dictionary = CampaignStateScript.new_snapshot()
	snapshot.completed_scene_ids = ["EX-CH01-S01", "EX-CH01-S02", "EX-CH01-S03", "EX-CH01-S12"]
	var decision_scene: Dictionary = _scene("EX-CH01-S10")
	snapshot.story_log.choices[String(decision_scene.choice.id)] = {"option_id": String(decision_scene.choice.options[0].id), "scene_id": "EX-CH01-S10", "scenario_datetime": "2046-04-11 00:00 UTC", "state_revision": 1}
	var original := JSON.stringify(snapshot)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(root)
	var manual := ManualPanel.new()
	root.add_child(manual)
	manual.bind_snapshot(snapshot)
	manual.open_index()
	await process_frame
	_check(manual.find_child("ManualCompetency_life_support", true, false) != null and manual.find_child("ManualCompetency_scientific_method", true, false) != null, "Manual index renders all twelve competencies")
	_check(manual.find_child("ManualChapter_1", true, false) != null and manual.find_child("ManualChapter_2", true, false) == null, "only completed chapter pages appear")
	_check((manual.find_child("OpenCompetency_rover", true, false) as Button).disabled, "unearned future page is locked")
	_check(not (manual.find_child("OpenCompetency_power", true, false) as Button).disabled, "earned page can open")
	var source_requested := [""]
	var clip_requested := [""]
	manual.data_card_requested.connect(func(id: String) -> void: source_requested[0] = id)
	manual.explainer_requested.connect(func(id: String) -> void: clip_requested[0] = id)
	manual.open_competency("power")
	await process_frame
	_check(manual.find_child("ManualData_lro_mazarico_2011_illumination", true, false) != null, "Manual page renders its linked science card")
	_check(manual.find_child("Moment_power_learned_EX-M0101", true, false) != null, "Manual page renders the earned mission moment")
	_check(manual.find_child("Moment_power_proved_EX-M0602", true, false) == null, "future proved moment stays out of the page")
	(manual.find_child("OpenData_lro_mazarico_2011_illumination", true, false) as Button).pressed.emit()
	(manual.find_child("ManualWatch_sci_polar_sun", true, false) as Button).pressed.emit()
	_check(source_requested[0] == "lro_mazarico_2011_illumination" and clip_requested[0] == "sci_polar_sun", "Manual requests the existing data-card and clip routes")
	var back_button := manual.find_child("ManualBack", true, false) as Button
	var regular_size := back_button.get_theme_font_size("font_size")
	manual.set_accessibility({"large_text": true})
	_check(back_button.get_theme_font_size("font_size") > regular_size, "large text scales Manual controls")
	_check(manual.open_chapter(1) and not manual.open_chapter(2), "only completed chapter end views can open")
	await process_frame
	_check(manual.find_child("ChapterTakeaway_0", true, false) != null and manual.find_child("ChapterTakeaway_2", true, false) != null, "chapter view presents all three things")
	var takeaway_card := manual.find_child("ChapterTakeaway_0", true, false)
	var takeaway_text := ""
	for label in takeaway_card.find_children("*", "Label", true, false):
		takeaway_text += (label as Label).text
	_check(takeaway_text.contains(String(CurriculumModel.chapter_learning(1, snapshot).things[0].source_takeaway)), "chapter takeaway shows the real data behind the lesson")
	_check(manual.find_child("ChapterDecisionReplay", true, false) != null, "chapter view presents the saved decision replay")
	_check(JSON.stringify(snapshot) == original, "Manual navigation, accessibility and data actions leave the save untouched")
	root.queue_free()
	await process_frame

func campaign_scene_ids() -> Array:
	var ids: Array = []
	for scene in Content.load_full().get("scenes", []):
		ids.append(String(scene.id))
	return ids

func _scene(scene_id: String) -> Dictionary:
	for scene in Content.load_full().get("scenes", []):
		if String(scene.id) == scene_id:
			return scene
	return {}

func _mission(mission_id: String) -> Dictionary:
	for mission in Content.load_full().get("missions", []):
		if String(mission.id) == mission_id:
			return mission
	return {}

func _check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + description)
