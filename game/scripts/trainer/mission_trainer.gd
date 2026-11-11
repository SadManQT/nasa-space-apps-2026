extends Control

signal exit_requested
const Adapter = preload("res://scripts/trainer/p02_trainer.gd")
const Results = preload("res://scripts/trainer/trainer_results.gd")
const Science = preload("res://scripts/science/science_data.gd")
const Chart = preload("res://scripts/ui/data_chart.gd")
const TABLE_SCENE = preload("res://scenes/ui/mission_table_panel.tscn")
const PANELS_SCENE = preload("res://scenes/ui/campaign_panels.tscn")
const SHELL_SCENE = preload("res://scenes/trainer/mission_trainer.tscn")
var results_path := Results.DEFAULT_PATH
var settings: Dictionary = {}
var catalog: Dictionary = {}
var exercise: RefCounted
var table: MissionTablePanel
var panels: CampaignPanels
var store := Results.new()
var _body: VBoxContainer
var _scroll: ScrollContainer
var _notice: Label
var _entry: Dictionary = {}
var _page := "catalog"
var _revision := 0
var _opening := false
var _guide: Control
var _back_button: Button
var moon_trainer: Control
var moon_trainer_results_path := "user://moon_trainer_results.json"

func _open_moon_trainer() -> void:
	if is_instance_valid(moon_trainer):
		return
	var script := load("res://scripts/trainer/moon_trainer.gd")
	moon_trainer = script.new()
	moon_trainer.set("settings", settings.duplicate(true))
	moon_trainer.set("results_path", moon_trainer_results_path)
	_set_page_enabled(false)
	moon_trainer.connect("exit_requested", _close_moon_trainer)
	add_child(moon_trainer)

func _close_moon_trainer() -> void:
	if is_instance_valid(moon_trainer):
		moon_trainer.queue_free()
		moon_trainer = null
	_set_page_enabled(true)
	var entry := find_child("OpenMoonTrainer", true, false) as Button
	if entry != null:
		entry.grab_focus()
	else:
		_restore_page_focus()

func _ready() -> void:
	name = "MissionTrainer"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiKit.theme()
	catalog = JSON.parse_string(FileAccess.get_file_as_string("res://resources/trainer/scenarios.json"))
	store.path = results_path
	var loaded := store.load_results()
	var shell := SHELL_SCENE.instantiate()
	add_child(shell)
	_notice = shell.find_child("TrainerNotice", true, false) as Label
	_scroll = shell.find_child("TrainerScroll", true, false) as ScrollContainer
	_body = shell.find_child("TrainerBody", true, false) as VBoxContainer
	_guide = shell.find_child("PracticeGuide", true, false) as Control
	_back_button = shell.find_child("TrainerExit", true, false) as Button
	_back_button.pressed.connect(func() -> void: exit_requested.emit() if _page == "catalog" else show_catalog())
	for label_node in shell.find_children("*", "Label", true, false):
		var label := label_node as Label
		UiDesign.style_label(label, String(label.get_meta("lla_type", "body")), "muted" if label.get_meta("muted", false) else "ivory")
	table = TABLE_SCENE.instantiate()
	add_child(table)
	table.commit_requested.connect(_commit)
	table.opened.connect(func(_id): _set_page_enabled(false))
	table.closed.connect(func(_id):
		_set_page_enabled(true)
		if not _opening:
			call_deferred("_decision_home"))
	panels = PANELS_SCENE.instantiate()
	add_child(panels)
	panels.set_accessibility(settings)
	table.hint_player = panels.hint_player
	panels.ending_retry_requested.connect(_retry)
	panels.ending_continue_requested.connect(show_catalog)
	panels.panel_opened.connect(func(_id): _set_page_enabled(false))
	panels.panel_closed.connect(func(_id):
		_set_page_enabled(not table.is_open() and not panels.hint_player.is_open())
		call_deferred("_restore_page_focus"))
	get_viewport().size_changed.connect(_scale)
	show_catalog()
	if not loaded.accepted:
		_notice.text = loaded.reason

func show_catalog() -> void:
	_opening = true
	table.close()
	panels.close_panel()
	_opening = false
	_page = "catalog"
	exercise = null
	_entry = {}
	_clear()
	_text("Choose a training scenario", "heading")
	_text("Available scenarios open in one click. Others are coming soon.")
	_catalog_card("Open Moon Trainer", "Free surface sorties & rover · Available", "OpenMoonTrainer", "moon", _open_moon_trainer)
	for group in catalog.groups:
		_text(catalog.groups[group], "heading")
		for row in catalog.scenarios:
			if row.demand != group:
				continue
			var available: bool = row.get("adapter", "") == "p02"
			var saved: Dictionary = store.results.get(row.id, {})
			var detail: String = "Available · Start practice" if available else "Coming soon"
			if not saved.is_empty():
				detail += " · Last result: %d of 3 stars" % int(saved.star_count)
			_catalog_card(row.title, detail, "Scenario_" + row.id, "power" if group == "power" else ("plant" if group == "food" else ("shielding" if group == "shielding" else "life")), func(): select_scenario(row.id), not available)
	_finish_page()

func _catalog_card(title: String, detail: String, id: String, icon_kind: String, action: Callable, disabled: bool = false) -> void:
	var button := UiDesign.button(title + "\n" + detail, 96)
	button.name = id
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.disabled = disabled
	button.pressed.connect(action)
	for state in ["normal", "disabled", "hover", "pressed"]:
		var highlighted: bool = state == "hover" or state == "pressed"
		var style := UiDesign.button_style(UiDesign.colour("accent" if highlighted else "navy").darkened(0.15 if disabled else 0.0), highlighted)
		style.content_margin_left = 62
		style.content_margin_right = 20
		style.content_margin_top = 16
		style.content_margin_bottom = 16
		button.add_theme_stylebox_override(state, style)
	var icon := UiKit.icon(icon_kind, "muted" if disabled else "accent", 28)
	icon.position = Vector2(18, 32)
	button.add_child(icon)
	_body.add_child(button)

func select_scenario(id: String) -> bool:
	for row in catalog.scenarios:
		if row.id != id or row.get("adapter", "") != "p02":
			continue
		exercise = Adapter.new()
		var result: Dictionary = exercise.begin(row)
		if not result.accepted:
			_notice.text = result.reason
			return false
		_entry = row.duplicate(true)
		_show_brief()
		return true
	return false

func _show_brief() -> void:
	_page = "brief"
	_clear()
	var data := Science.new().mission_card(_entry.brief_mission)
	_text(_entry.title, "heading")
	_text("Keep the crew and garden safe until dawn.")
	_text("Store daylight power before the long darkness.")
	_text(_entry.estimate)
	_text("NASA data briefing · about 20 seconds to read", "heading")
	_text(data.plain)
	var chart := Chart.new()
	chart.series = data.visual
	chart.custom_minimum_size.y = 100
	_body.add_child(chart)
	_text("\n".join(data.visual.labels))
	_text(data.limits)
	_button("Science and source", "BriefSource", func(): panels.open_panel("data_card", {"source_id": data.source_ids[0]}))
	_button("Make the night plan", "BeginTraining", open_decision)
	_button("Back to training scenarios", "TrainerCatalog", show_catalog)
	_finish_page()

func open_decision() -> void:
	_page = "decision"
	_clear()
	_text(_entry.title, "heading")
	_text("Plan the next shift at the table.")
	_text("Your choices keep air, warmth and water available.")
	_button("Resume the night plan", "ResumeTraining", open_decision)
	_button("Back to training scenarios", "TrainerCatalog", show_catalog)
	_finish_page()
	_revision = int(exercise.director().query().state_revision)
	table.open(exercise, exercise.current_gate(), settings)
	table.teach_first_use()

func _decision_home() -> void:
	if _page == "decision" and not table.is_open():
		_restore_page_focus()

func _commit(target_id: String, plan: Dictionary) -> void:
	var result: Dictionary = exercise.commit_gate(target_id, plan, _revision)
	if not result.accepted:
		_notice.text = UiDesign.player_words(result.reason)
		open_decision()
		return
	var outcome: Dictionary = exercise.outcome()
	if outcome.is_empty():
		open_decision()
		return
	_page = "outcome"
	_clear()
	_text("Review your night and its science", "heading")
	_button("Open training report", "ReopenReport", _show_outcome)
	_button("Back to training scenarios", "TrainerCatalog", show_catalog)
	_finish_page()
	var saved := store.record(_entry.id, outcome)
	_notice.text = "Training result saved separately from your expedition." if saved.accepted else saved.reason
	_show_outcome()

func _show_outcome() -> void:
	var data: Dictionary = exercise.outcome()
	data["trainer_save_status"] = _notice.text
	panels.open_chapter1_outcome(data)

func _retry() -> void:
	var result: Dictionary = exercise.retry()
	if result.accepted:
		panels.close_panel()
		open_decision()
	else:
		_notice.text = result.reason

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(moon_trainer):
		return
	var back_pad: bool = event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B
	if (event.is_action_pressed("ui_cancel") or back_pad) and not event.is_echo():
		if table.is_open() or panels.hint_player.is_open():
			return
		if not panels.active_panel().is_empty():
			panels.close_panel()
			get_viewport().set_input_as_handled()
			return
		if _page == "catalog":
			exit_requested.emit()
		else:
			show_catalog()
		get_viewport().set_input_as_handled()

func _clear() -> void:
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	_scroll.scroll_vertical = 0

func _text(value: String, token: String = "body") -> void:
	_body.add_child(UiDesign.label(value, token))

func _button(value: String, id: String, action: Callable, disabled: bool = false) -> void:
	var button := UiDesign.button(value)
	button.name = id
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.disabled = disabled
	button.pressed.connect(action)
	_body.add_child(button)

func _finish_page() -> void:
	_scroll.focus_mode = Control.FOCUS_ALL if _page == "brief" else Control.FOCUS_NONE
	_scale()
	_restore_page_focus.call_deferred(_page == "brief")

func _scale() -> void:
	_guide.visible = _page == "catalog" and not bool(settings.get("large_text", false)) and get_viewport_rect().size.x >= 1100
	UiDesign.apply_type(self, get_viewport_rect().size.y, 1.5 if settings.get("large_text", false) else 1.0, [table, panels])

func _restore_page_focus(reading_start: bool = false) -> void:
	if is_queued_for_deletion() or table.is_open() or not panels.active_panel().is_empty():
		return
	if reading_start:
		_scroll.grab_focus()
		_scroll.scroll_vertical = 0
		return
	for child in _body.get_children():
		if child is Button and not child.disabled:
			child.grab_focus()
			_scroll.scroll_vertical = 0
			return

func _set_page_enabled(enabled: bool) -> void:
	_back_button.disabled = not enabled
	for child in _body.get_children():
		if child is Button:
			if not enabled and not child.has_meta("trainer_disabled"):
				child.set_meta("trainer_disabled", child.disabled)
				child.disabled = true
			elif enabled and child.has_meta("trainer_disabled"):
				child.disabled = child.get_meta("trainer_disabled")
				child.remove_meta("trainer_disabled")
