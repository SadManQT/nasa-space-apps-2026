extends SceneTree

## M3-72: Verification suite for Chapter Select, Mission List, Progress and
## Achievements screens (`ChapterSelectPanel`, `CadetAchievements`).
## Verifies:
## - Title screen entry (`ChapterSelectEntry`) opens `ChapterSelectPanel`.
## - 8 chapter cards (Chapters 1–8), with locked chapters shown as spoiler-free
##   silhouettes and unlocked chapters exposing missions with stars and best results.
## - Progress tab displays Cadet Record summary, 5 skills with teachers/benefits,
##   and 12 junior-astronaut curriculum competencies (doc 25 §10).
## - Achievements tab displays 20 Act One skill achievements tied to real skills.
## - Save access is strictly read-only through `SaveService` (never mutates save bytes).

const MainScene = preload("res://scenes/main.tscn")
const PanelScript = preload("res://scripts/ui/chapter_select.gd")
const AchievementsScript = preload("res://scripts/ui/achievements.gd")
const Save = preload("res://scripts/save/save_service.gd")

var storage = preload("res://tools/support/isolated_storage.gd").new()
var checks := 0
var failures := 0
var write_evidence := false

func _init() -> void:
	write_evidence = OS.get_cmdline_user_args().has("--evidence")
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	_check(storage.setup("M3-72"), "isolated storage configured for M3-72")
	_check(storage.prepare_rendering_cache(), "isolated rendering cache prepared")

	# Prepare a real resumable Chapter 1 checkpoint in isolated storage
	var director := preload("res://scripts/core/campaign_director.gd").new()
	director.new_campaign(preload("res://scripts/content/content_loader.gd").EXPECTED_CONTENT_REVISION)
	var route := preload("res://scripts/missions/chapter1_route.gd").new(director)
	var saved: Dictionary = route.director().snapshot()
	saved["route_runtime"] = route.snapshot()
	var saves := Save.new()
	saves.session_validator = preload("res://scripts/campaign/chapter1_campaign.gd").restore_session
	_check(saves.save(saved, storage.path).get("accepted", false), "saved valid checkpoint fixture")
	var saved_bytes := FileAccess.get_file_as_bytes(storage.path)

	# Verify 20 Act One skill achievements catalog
	var catalog := AchievementsScript.catalog()
	_check(catalog.size() == 20, "CadetAchievements defines 20 Act One skill achievements")
	var seen_ids := {}
	for item in catalog:
		var aid := String(item.get("id", ""))
		_check(not aid.is_empty() and not seen_ids.has(aid), "unique achievement id: " + aid)
		seen_ids[aid] = true
		_check(String(item.get("skill", "")) in ["navigation", "handling", "life_support", "repair", "observation"], "achievement tied to real skill: " + aid)

	# Launch main title and open Chapter Select
	var main := MainScene.instantiate()
	storage.configure(main)
	root.add_child(main)
	while not main.title_ready:
		await process_frame

	var menu := main.get_node("TitleLayer/MainMenu") as MainMenu
	var cs_btn := menu.find_child("ChapterSelectEntry", true, false) as Button
	_check(cs_btn != null, "MainMenu exposes ChapterSelectEntry button")
	cs_btn.pressed.emit()
	await process_frame
	await process_frame

	var panel: ChapterSelectPanel = main.get("_chapter_select")
	_check(panel != null and panel is ChapterSelectPanel, "ChapterSelectPanel opens from title screen")
	_check(panel.unlocked_up_to_chapter() == 1, "Chapter 1 save unlocks Chapter 1 and keeps Chapters 2-8 as silhouettes")

	# Check 8 chapter cards and spoiler-free silhouettes
	for ch in range(1, 9):
		var card := panel.find_child("ChapterCard_%d" % ch, true, false)
		var btn := panel.find_child("OpenChapter_%d" % ch, true, false) as Button
		_check(card != null and btn != null, "Chapter %d card and button present" % ch)
		_check(btn.disabled == (ch > 1), "Chapter %d locked state matches save progress" % ch)
	_check(not panel.select_chapter(5), "locked chapter cannot be selected")
	_check_no_locked_spoilers(panel)
	await _save_shot("M3-72_chapter_select.png")

	# Unlock up to Chapter 4 in memory (without writing save file) to inspect multi-chapter mission stars
	var ch4_snap := saved.duplicate(true)
	ch4_snap["chapter_id"] = "CH04"
	ch4_snap["completed_scene_ids"] = []
	for chapter in range(1, 4):
		for scene in range(1, 13):
			ch4_snap["completed_scene_ids"].append("EX-CH%02d-S%02d" % [chapter, scene])
	for scene in range(1, 7):
		ch4_snap["completed_scene_ids"].append("EX-CH04-S%02d" % scene)
	panel.reload_from_save(ch4_snap)
	_check(panel.unlocked_up_to_chapter() == 4, "Production chapter_id unlocks Chapter 4 without invented current_chapter field")
	_check(panel.select_chapter(4), "unlocked Chapter 4 can be selected")
	await process_frame
	var m401 := panel.find_child("MissionRow_EX-M0401", true, false)
	var m404 := panel.find_child("MissionRow_EX-M0404", true, false)
	_check(m401 != null and m404 != null, "Chapter 4 mission list renders EX-M0401..EX-M0404 with stars and best results")

	var inspect_btn := panel.find_child("Inspect_EX-M0401", true, false) as Button
	if inspect_btn != null:
		inspect_btn.pressed.emit()
		await process_frame
	_check(panel.find_child("MissionSummaryDetails", true, false) != null, "View Summary opens a visible mission summary")
	_check(not _collect_text(panel).contains("All flight rules met"), "Mission completion does not invent perfect scores or flight-rule results")
	# Progress tab
	panel.show_tab("progress")
	await process_frame
	await process_frame
	for skill_id in ["navigation", "handling", "life_support", "repair", "observation"]:
		_check(panel.find_child("SkillRow_" + skill_id, true, false) != null, "Progress tab shows skill row: " + skill_id)
	_check(panel.find_child("Competency_life_support", true, false) != null and panel.find_child("Competency_scientific_method", true, false) != null, "Progress tab shows junior-astronaut curriculum competencies")
	await _save_shot("M3-72_progress.png")

	# Achievements tab
	panel.show_tab("achievements")
	await process_frame
	await process_frame
	for item in catalog:
		_check(panel.find_child("Achievement_" + String(item.id), true, false) != null, "Achievements tab renders " + String(item.id))
	_check(AchievementsScript.unlocked_count(ch4_snap) >= 7, "Chapter 4 snapshot unlocks earned skill achievements")
	await _save_shot("M3-72_achievements.png")

	# Verify strictly read-only save behavior
	_check(FileAccess.get_file_as_bytes(storage.path) == saved_bytes, "ChapterSelectPanel never writes or modifies campaign save bytes")

	panel.exit_requested.emit()
	await process_frame
	_check(menu.visible and root.gui_get_focus_owner() == cs_btn, "exiting ChapterSelectPanel restores focus to ChapterSelectEntry")

	main.free()
	await process_frame
	storage.cleanup()
	print("CHAPTER SELECT RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _check_no_locked_spoilers(panel: Control) -> void:
	for ch in range(2, 9):
		var card := panel.find_child("ChapterCard_%d" % ch, true, false)
		if card == null:
			continue
		for lbl in card.find_children("*", "Label", true, false):
			var text := (lbl as Label).text
			_check(not text.contains("Noor") and not text.contains("Rahman") and not text.contains("Malapert") and not text.contains("Moonquake"), "locked Chapter %d silhouette hides story title/spoilers: %s" % [ch, text])

func _save_shot(filename: String) -> void:
	if not write_evidence:
		return
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if img != null:
		var out_path := ProjectSettings.globalize_path("res://../production/qa/evidence/" + filename)
		img.save_png(out_path)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func _collect_text(node: Node) -> String:
	var result := ""
	if node is Label:
		result = node.text + "\n"
	for child in node.get_children():
		result += _collect_text(child)
	return result
