extends Control
class_name ChapterSelectPanel

## M3-72: Chapter select, mission list, progress and achievements screens.
## Reachable from the title screen; reads saves strictly through SaveService
## (M3-71) and never writes or mutates campaign state. Locked chapters render as
## silhouettes with zero story spoilers. Styled and animated with UiDesign.

signal exit_requested
signal chapter_mission_inspected(chapter_num: int, mission_id: String)

const SaveScript = preload("res://scripts/save/save_service.gd")
const CampaignScript = preload("res://scripts/campaign/chapter1_campaign.gd")
const AchievementsScript = preload("res://scripts/ui/achievements.gd")
const ContentScript = preload("res://scripts/content/content_loader.gd")
const ProgressionScript = preload("res://scripts/progression/cadet_progression.gd")
const ShellScene = preload("res://scenes/ui/chapter_select/chapter_select.tscn")

const CHAPTER_CATALOG := [
	{
		"chapter": 1,
		"title": "Chapter 1 · Night One",
		"subtitle": "36-hour south-polar commissioning night",
		"silhouette_hint": "Locked Chapter 1",
		"missions": [
			{"id": "EX-M0101", "title": "First True Leaf (Chamber One Calibration)"},
			{"id": "EX-M0102", "title": "Daylight Shifts & Crew Notes"},
			{"id": "EX-M0103", "title": "Safe Room Stack & Water Wall"},
			{"id": "EX-M0104", "title": "Dawn Debrief & Seven Shifts"}
		]
	},
	{
		"chapter": 2,
		"title": "Chapter 2 · Be the Bee",
		"subtitle": "Cross-pollination and the five-frame recorder strip",
		"silhouette_hint": "Complete Chapter 1 to reveal Chapter 2",
		"missions": [
			{"id": "EX-M0201", "title": "Morning in the Greenhouse"},
			{"id": "EX-M0202", "title": "Be the Bee (Cross-Pollination)"},
			{"id": "EX-M0203", "title": "Annex Threshold"},
			{"id": "EX-M0204", "title": "Five Frames in Order"}
		]
	},
	{
		"chapter": 3,
		"title": "Chapter 3 · Moonquake",
		"subtitle": "Shallow tremor fault isolation and 42 founder seeds",
		"silhouette_hint": "Complete Chapter 2 to reveal Chapter 3",
		"missions": [
			{"id": "EX-M0301", "title": "Seismic Ringing"},
			{"id": "EX-M0302", "title": "Isolate the Manifold Leak"},
			{"id": "EX-M0303", "title": "Pod Count in the Dome"},
			{"id": "EX-M0304", "title": "Thirty for the Vault, Twelve for the Tray"}
		]
	},
	{
		"chapter": 4,
		"title": "Chapter 4 · Into the Cold Trap",
		"subtitle": "Ridge survey beacons, VIPER slope route and the −183 °C vault",
		"silhouette_hint": "Complete Chapter 3 to reveal Chapter 4",
		"missions": [
			{"id": "EX-M0401", "title": "Three Beacons on the Ridge"},
			{"id": "EX-M0402", "title": "Switchback Route to the Cold Trap"},
			{"id": "EX-M0403", "title": "Into Permanent Shadow"},
			{"id": "EX-M0404", "title": "Warm Before Opening"}
		]
	},
	{
		"chapter": 5,
		"title": "Chapter 5 · Shooting Stars",
		"subtitle": "Two-telescope flash coincidence and founder seed stewardship",
		"silhouette_hint": "Complete Chapter 4 to reveal Chapter 5",
		"missions": [
			{"id": "EX-M0501", "title": "Night Watch Cameras"},
			{"id": "EX-M0502", "title": "Coincidence Filter"},
			{"id": "EX-M0503", "title": "Founder Reserve Audit"},
			{"id": "EX-M0504", "title": "Planting the Next Generation"}
		]
	},
	{
		"chapter": 6,
		"title": "Chapter 6 · The Red Ring",
		"subtitle": "Five-hour total lunar eclipse budget and feeder fault isolation",
		"silhouette_hint": "Complete Chapter 5 to reveal Chapter 6",
		"missions": [
			{"id": "EX-M0601", "title": "Earth's Shadow Approaches"},
			{"id": "EX-M0602", "title": "Five-Hour Eclipse Budget"},
			{"id": "EX-M0603", "title": "Copper Light on the Ridge"},
			{"id": "EX-M0604", "title": "Rim Camera Feeder Fault"}
		]
	},
	{
		"chapter": 7,
		"title": "Chapter 7 · The Great Storm",
		"subtitle": "Solar particle shelter run and two-hop relay restoration",
		"silhouette_hint": "Complete Chapter 6 to reveal Chapter 7",
		"missions": [
			{"id": "EX-M0701", "title": "Proton Flux Alert"},
			{"id": "EX-M0702", "title": "Safe Room Shelter Run"},
			{"id": "EX-M0703", "title": "After the Storm"},
			{"id": "EX-M0704", "title": "Restore the Local Relay"}
		]
	},
	{
		"chapter": 8,
		"title": "Chapter 8 · Mons Malapert",
		"subtitle": "The 120 km relay road and dual-link summit transmission",
		"silhouette_hint": "Complete Chapter 7 to reveal Chapter 8",
		"missions": [
			{"id": "EX-M0801", "title": "Pack for the Long Road"},
			{"id": "EX-M0802", "title": "Four Repeater Hops"},
			{"id": "EX-M0803", "title": "Dual-Link Verification on the Summit"},
			{"id": "EX-M0804", "title": "First Flower on the Moon"}
		]
	}
]

const CURRICULUM_COMPETENCIES := [
	{"id": "life_support", "title": "Life support", "learned": "Air, water and food margins; leaks and thermal limits.", "proved": "Keeping air and food above the line through a dark night."},
	{"id": "power", "title": "Power", "learned": "Solar generation, battery storage, overflow and darkness budgets.", "proved": "A blackout-free plan through known darkness and eclipse."},
	{"id": "thermal", "title": "Thermal control", "learned": "Heat in the habitat, cold shadow outside (−183 °C).", "proved": "Equipment and vault canisters kept inside safe temperature limits."},
	{"id": "radiation", "title": "Radiation & space weather", "learned": "Proton dose, water/crate shielding, ALARA and real storm profiles.", "proved": "Sheltering in time from the measured GOES proton profile."},
	{"id": "plant_science", "title": "Food & plant science", "learned": "Growth stages, hand pollination, seed-to-seed and Chang'e-4 cotton.", "proved": "Alo and Tara's lineage carried to harvest."},
	{"id": "eva", "title": "EVA & suit operations", "learned": "Suit budget, 25% return reserve, checklists and buddy checks.", "proved": "A sortie home with the return reserve intact."},
	{"id": "navigation", "title": "Navigation", "learned": "Slopes from real LOLA elevation data; Sun and Earth bearings.", "proved": "A planned route that matches the ground."},
	{"id": "rover", "title": "Rover operations", "learned": "15° VIPER slope limit, energy per metre and payload care.", "proved": "A drive within the slope limit and battery reserve."},
	{"id": "communication", "title": "Communication", "learned": "Line of sight, relay hops, link windows and light-time delay.", "proved": "Both local and Earth links verified before the summit call."},
	{"id": "lunar_science", "title": "Lunar science", "learned": "Regolith, cold-trap ice, moonquakes, impact flashes and eclipses.", "proved": "Each measurement checked against a reference."},
	{"id": "teamwork", "title": "Teamwork & systems engineering", "learned": "Trade studies, flight rules, Go/No-Go polls and blame-free debriefs.", "proved": "Plans that follow the agreed flight rules."},
	{"id": "scientific_method", "title": "The scientific method", "learned": "Observed, inferred and unknown; a wrong theory is information.", "proved": "Claims filed in the right column with sources."}
]

var save_path: String = SaveScript.DEFAULT_PATH
var settings: Dictionary = {
	"captions": true,
	"large_text": false,
	"timer_free": true,
	"reduced_motion": false,
}
var active_tab := "chapters"
var selected_chapter := 1
var _snapshot: Dictionary = {}
var _tab_bar: HBoxContainer
var _scroll: ScrollContainer
var _body: VBoxContainer
var _status_label: Label
var _catalog: Dictionary = ContentScript.load_full()
var _selected_mission := ""
var _route_bar: Control
var _chapter_cards: GridContainer
var _locked_art: Texture2D
var _selection_title: Label
var _selection_description: Label
var _selection_button: Button

func _ready() -> void:
	name = "ChapterSelectPanel"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiKit.theme()
	reload_from_save()
	_build_ui()
	show_tab(active_tab)

## Reads the current save snapshot strictly read-only through SaveService.
func reload_from_save(override_snapshot: Variant = null) -> Dictionary:
	if override_snapshot is Dictionary:
		_snapshot = (override_snapshot as Dictionary).duplicate(true)
		return _snapshot
	var service := SaveScript.new()
	service.session_validator = func(snap: Dictionary) -> Dictionary: return CampaignScript.restore_session(snap)
	var loaded: Dictionary = service.load(save_path)
	if bool(loaded.get("accepted", false)) and loaded.get("snapshot") is Dictionary:
		_snapshot = (loaded.get("snapshot") as Dictionary).duplicate(true)
	else:
		_snapshot = {}
	return _snapshot

func unlocked_up_to_chapter() -> int:
	if _snapshot.is_empty():
		return 1
	return AchievementsScript.chapter_number(_snapshot)

func _build_ui() -> void:
	var shell := ShellScene.instantiate()
	add_child(shell)
	_tab_bar = shell.find_child("ChapterSelectTabs", true, false) as HBoxContainer
	_scroll = shell.find_child("ChapterSelectScroll", true, false) as ScrollContainer
	_body = shell.find_child("ChapterSelectBody", true, false) as VBoxContainer
	_status_label = shell.find_child("ChapterSelectStatus", true, false) as Label
	_route_bar = shell.find_child("ChapterRoute", true, false) as Control
	_chapter_cards = shell.find_child("ChapterCardsGrid", true, false) as GridContainer
	_locked_art = _chapter_cards.get_node("ChapterCard_8/Art").texture
	_route_bar.resized.connect(func() -> void:
		(_route_bar.get_node("TimelineCurve") as Line2D).scale.x = _route_bar.size.x / 1208.0)
	for number in range(1, 9):
		var step := _route_bar.get_node("ChapterStep_%d" % number) as Button
		step.pressed.connect(func() -> void: select_chapter(number))
		var card := _chapter_cards.get_node("ChapterCard_%d" % number)
		(card.find_child("OpenChapter_%d" % number, true, false) as Button).pressed.connect(func() -> void: select_chapter(number))
	_selection_title = shell.find_child("SelectionTitle", true, false) as Label
	_selection_description = shell.find_child("SelectionDescription", true, false) as Label
	_selection_button = shell.find_child("InspectSelectedChapter", true, false) as Button
	_selection_button.pressed.connect(func() -> void:
		show_tab("chapters")
		var missions := find_child("SelectedChapterMissions", true, false) as Control
		_scroll.ensure_control_visible.call_deferred(missions))
	(shell.find_child("ChapterSelectExit", true, false) as Button).pressed.connect(func() -> void: exit_requested.emit())
	for tid in ["chapters", "progress", "achievements"]:
		var btn := _tab_bar.get_node("Tab_" + tid) as Button
		btn.pressed.connect(func() -> void: show_tab(tid))
	for label_node in shell.find_children("*", "Label", true, false):
		var label := label_node as Label
		UiDesign.style_label(label, String(label.get_meta("lla_type", "body")), "muted" if label.get_meta("muted", false) else "ivory")
	get_viewport().size_changed.connect(_scale)

func _summary_line() -> String:
	var max_ch := unlocked_up_to_chapter()
	var ach_count := AchievementsScript.unlocked_count(_snapshot)
	if _snapshot.is_empty():
		return "Your expedition begins with Chapter 1  ·  %d of 20 achievements earned" % ach_count
	return "Reached Chapter %d of 8  ·  %d of 20 achievements earned" % [max_ch, ach_count]

func show_tab(tab_id: String) -> void:
	active_tab = tab_id if ["chapters", "progress", "achievements"].has(tab_id) else "chapters"
	selected_chapter = clampi(selected_chapter, 1, unlocked_up_to_chapter())
	if _status_label != null:
		_status_label.text = _summary_line()
	for tab_node in _tab_bar.get_children():
		var tab := tab_node as Button
		var selected: bool = tab.name == "Tab_" + active_tab
		tab.button_pressed = selected
		UiDesign.nav_item(tab, selected)  # Deep Space sidebar: leading bar, no solid block
	_route_bar.visible = active_tab == "chapters"
	_chapter_cards.visible = active_tab == "chapters"
	_selection_button.visible = active_tab == "chapters"
	_selection_title.text = String(_chapter_spec(selected_chapter).title)
	_selection_description.text = String(_chapter_spec(selected_chapter).subtitle) if active_tab == "chapters" else ("Your training record and twelve science competencies." if active_tab == "progress" else "Skills earned through real decisions in your expedition.")
	if active_tab != "chapters":
		_selection_title.text = "Cadet progress" if active_tab == "progress" else "Skill achievements"
	_clear()
	match active_tab:
		"chapters":
			_render_chapters_tab()
		"progress":
			_render_progress_tab()
		"achievements":
			_render_achievements_tab()
	_finish_page()

func select_chapter(chapter_num: int) -> bool:
	var max_ch := unlocked_up_to_chapter()
	if chapter_num < 1 or chapter_num > max_ch:
		return false
	selected_chapter = chapter_num
	_selected_mission = ""
	if active_tab == "chapters":
		show_tab("chapters")
	return true

func _render_chapters_tab() -> void:
	var max_ch := unlocked_up_to_chapter()
	selected_chapter = clampi(selected_chapter, 1, max_ch)
	for number in range(1, 9):
		var row := _chapter_spec(number)
		var unlocked := number <= max_ch
		var selected := unlocked and number == selected_chapter
		var step := _route_bar.get_node("ChapterStep_%d" % number) as Button
		step.disabled = not unlocked
		step.button_pressed = selected
		step.tooltip_text = String(row.title) if unlocked else String(row.silhouette_hint)
		var card := _chapter_cards.get_node("ChapterCard_%d" % number) as PanelContainer
		var frame := card.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		frame.border_color = UiDesign.colour("accent" if selected else "glass_edge")
		frame.set_border_width_all(3 if selected else 1)
		card.add_theme_stylebox_override("panel", frame)
		var art := card.get_node("Art") as TextureRect
		art.texture = art.get_meta("unlocked_art") as Texture2D if unlocked else _locked_art
		art.modulate = Color.WHITE if unlocked else Color(0.22, 0.26, 0.34, 1.0)
		var title := card.find_child("Title", true, false) as Label
		title.text = String(row.title).trim_prefix("Chapter %d - " % number).trim_prefix("Chapter %d · " % number) if unlocked else "Locked"
		var subtitle := card.find_child("Subtitle", true, false) as Label
		subtitle.text = String(row.subtitle) if unlocked else String(row.silhouette_hint)
		var open_btn := card.find_child("OpenChapter_%d" % number, true, false) as Button
		open_btn.text = "View missions" if unlocked else "Locked - Complete earlier chapters"
		open_btn.disabled = not unlocked

	# Selected chapter mission list with stars and best results
	var chosen_spec := _chapter_spec(selected_chapter)
	var missions_panel := UiDesign.glass_panel(UiDesign.colour("accent"))
	missions_panel.name = "SelectedChapterMissions"
	_body.add_child(missions_panel)

	var m_box := VBoxContainer.new()
	m_box.add_theme_constant_override("separation", 8)
	missions_panel.add_child(m_box)
	m_box.add_child(UiDesign.label("Missions in " + String(chosen_spec.title), "heading", "accent"))

	for m_row in chosen_spec.missions:
		var mid := String(m_row.id)
		var is_done := _mission_complete(m_row)
		var score := _mission_score(mid)
		var star_glyphs := "Score %d/3" % score if score >= 0 else ("Completed" if is_done else "Not complete")
		var best_text := "Recorded result: %d of 3 stars" % score if score >= 0 else ("Completed - No star score recorded for this mission" if is_done else "Not yet completed in this save")
		var row_card := UiDesign.glass_panel()
		row_card.name = "MissionRow_" + mid
		m_box.add_child(row_card)
		var r_box := HBoxContainer.new()
		r_box.add_theme_constant_override("separation", 12)
		row_card.add_child(r_box)
		var left := VBoxContainer.new()
		left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r_box.add_child(left)
		left.add_child(UiDesign.label("%s  ·  %s" % [star_glyphs, String(m_row.title)], "body", "good" if is_done else "ivory"))
		left.add_child(UiDesign.label(best_text, "caption", "muted"))
		var inspect_btn := UiDesign.button("View Summary")
		inspect_btn.name = "Inspect_" + mid
		inspect_btn.pressed.connect(func() -> void:
			_selected_mission = mid
			show_tab("chapters")
			chapter_mission_inspected.emit(selected_chapter, mid))
		r_box.add_child(inspect_btn)


	if not _selected_mission.is_empty():
		for mission in chosen_spec.missions:
			if mission.id == _selected_mission:
				var details := UiDesign.glass_panel(UiDesign.colour("accent"))
				details.name = "MissionSummaryDetails"
				_body.add_child(details)
				var summary := VBoxContainer.new()
				details.add_child(summary)
				summary.add_child(UiDesign.label(String(mission.title), "heading"))
				summary.add_child(UiDesign.label(String(mission.get("goal", "")), "body"))
				summary.add_child(UiDesign.label("Completed" if _mission_complete(mission) else "Still ahead in this expedition", "caption", "accent"))
				_scroll.ensure_control_visible.call_deferred(details)

func _chapter_spec(number: int) -> Dictionary:
	var row: Dictionary = CHAPTER_CATALOG[number - 1].duplicate(true)
	for chapter in _catalog.get("chapters", []):
		if int(chapter.number) == number:
			row.title = "Chapter %d - %s" % [number, chapter.title]
			row.subtitle = chapter.subtitle
	row.missions = []
	for mission in _catalog.get("missions", []):
		if int(mission.chapter_number) == number:
			row.missions.append(mission)
	return row

func _mission_complete(mission: Dictionary) -> bool:
	var scenes: Array = mission.get("scene_ids", [])
	var completed: Array = _snapshot.get("completed_scene_ids", [])
	return not scenes.is_empty() and scenes.all(func(id): return completed.has(id))

func _mission_score(mission_id: String) -> int:
	if mission_id != "EX-M0104":
		return -1
	var final := {}
	var blackout := false
	for receipt in _snapshot.get("receipts", {}).values():
		for trace in receipt.get("trace", []):
			blackout = blackout or bool(trace.get("blackout", false))
			if int(trace.get("shift", 0)) == 7:
				final = trace.get("after", {})
	if final.is_empty():
		return -1
	return int(int(final.get("Z", 0)) <= 3) + int(not blackout) + int(int(final.get("H", 0)) > 0)

func _render_progress_tab() -> void:
	_body.add_child(UiDesign.label("Cadet Record Summary & Operational Skills", "heading"))
	var resume: Dictionary = _snapshot.get("presentation_resume", {}) if _snapshot.get("presentation_resume") is Dictionary else {}
	var prog_dict: Dictionary = resume.get("cadet_progression", {}) if resume.get("cadet_progression") is Dictionary else {}
	var prog := ProgressionScript.new()
	prog.restore(prog_dict)

	var summary_card := UiDesign.glass_panel()
	summary_card.name = "CadetRecordSummaryCard"
	_body.add_child(summary_card)
	var s_box := VBoxContainer.new()
	s_box.add_theme_constant_override("separation", 6)
	summary_card.add_child(s_box)
	s_box.add_child(UiDesign.label("Sorties & Jobs Logged: %d report cards · Rest shifts taken: %d" % [prog.report_cards.size(), prog.rest_count], "body", "accent"))
	s_box.add_child(UiDesign.label("Training grades and skill ranks give helpful field bonuses and never lock the story.", "caption", "muted"))

	for skill_id in ["navigation", "handling", "life_support", "repair", "observation"]:
		var info := prog.skill_info(skill_id)
		var sk_card := UiDesign.glass_panel()
		sk_card.name = "SkillRow_" + skill_id
		_body.add_child(sk_card)
		var sk_box := VBoxContainer.new()
		sk_box.add_theme_constant_override("separation", 4)
		sk_card.add_child(sk_box)
		sk_box.add_child(UiDesign.label(
			"%s · Rank %d of 3 (Teacher: %s)" % [String(info.get("label", skill_id.capitalize())), int(info.get("rank", 0)), String(info.get("teacher", "Crew"))],
			"heading"
		))
		sk_box.add_child(UiDesign.label(String(info.get("benefit", "")), "body", "good"))
		sk_box.add_child(UiDesign.label(String(info.get("crew_line", "")), "caption", "muted"))

	_body.add_child(UiDesign.label("Junior-Astronaut Curriculum Competencies (12 Areas · Doc 25 §10)", "heading"))
	for comp in CURRICULUM_COMPETENCIES:
		var c_card := UiDesign.glass_panel()
		c_card.name = "Competency_" + String(comp.id)
		_body.add_child(c_card)
		var c_box := VBoxContainer.new()
		c_box.add_theme_constant_override("separation", 4)
		c_card.add_child(c_box)
		c_box.add_child(UiDesign.label(String(comp.title), "body", "accent"))
		c_box.add_child(UiDesign.label("What you learn: " + String(comp.learned), "caption"))
		c_box.add_child(UiDesign.label("Proved in play by: " + String(comp.proved), "caption", "muted"))

func _render_achievements_tab() -> void:
	var evaluated := AchievementsScript.evaluate(_snapshot)
	var earned := AchievementsScript.unlocked_count(_snapshot)
	_body.add_child(UiDesign.label("Act One Skill Achievements (%d of %d Unlocked)" % [earned, evaluated.size()], "heading"))
	_body.add_child(UiDesign.label("Every achievement is tied to a real operational skill or verified field decision.", "caption", "muted"))

	for row in evaluated:
		var unlocked := bool(row.get("unlocked", false))
		var card := UiDesign.glass_panel(UiDesign.colour("good" if unlocked else "border"))
		card.name = "Achievement_" + String(row.id)
		_body.add_child(card)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 4)
		card.add_child(box)
		var badge := "UNLOCKED ★" if unlocked else "LOCKED ☆"
		box.add_child(UiDesign.label(
			"%s  ·  %s  (Skill: %s)" % [badge, String(row.title), String(row.skill).replace("_", " ").capitalize()],
			"body",
			"good" if unlocked else "ivory"
		))
		box.add_child(UiDesign.label(String(row.description), "caption", "muted"))

func _unhandled_input(event: InputEvent) -> void:
	var back_pad: bool = event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B
	if (event.is_action_pressed("ui_cancel") or back_pad) and not event.is_echo():
		exit_requested.emit()
		get_viewport().set_input_as_handled()

func _clear() -> void:
	if _body == null:
		return
	for child in _body.get_children():
		if child == _chapter_cards:
			continue
		_body.remove_child(child)
		child.queue_free()
	if _scroll != null:
		_scroll.scroll_vertical = 0

func _finish_page() -> void:
	for button_node in _body.find_children("*", "Button", true, false):
		var button := button_node as Button
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_scale()
	_restore_page_focus.call_deferred()

func _scale() -> void:
	if not is_inside_tree():
		return
	var compact := bool(settings.get("large_text", false)) or get_viewport_rect().size.x < 1000.0
	if _chapter_cards != null:
		_chapter_cards.columns = 2 if compact else 3
	(find_child("Tagline", true, false) as Control).visible = false  # Instrument Light: no brand copy inside menus
	(find_child("ChapterRange", true, false) as Control).visible = not compact
	(find_child("SelectionRule", true, false) as Control).visible = not compact
	UiDesign.apply_type(self, get_viewport_rect().size.y, 1.5 if bool(settings.get("large_text", false)) else 1.0)

func _restore_page_focus() -> void:
	if is_queued_for_deletion() or _tab_bar == null:
		return
	var tab_btn := _tab_bar.find_child("Tab_" + active_tab, true, false) as Button
	if tab_btn != null:
		tab_btn.grab_focus()
