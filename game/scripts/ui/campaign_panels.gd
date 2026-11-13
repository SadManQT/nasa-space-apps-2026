extends Control
class_name CampaignPanels

## Shared, data-driven presentation panels in the one house style (doc 25 §2):
## one dark-glass panel over a blurred world, a title, one line of purpose, the
## body, and one exit key. This node reads a primitive query and emits primitive
## commands; it never owns campaign arithmetic or mutates a director/state object.

signal command_emitted(command: Dictionary)
signal panel_opened(panel_id: String)
signal panel_closed(panel_id: String)
signal accessibility_changed(settings: Dictionary)
signal ending_retry_requested
signal ending_continue_requested
## The Journal's Manual tab asks the HUD to open the Academy Manual.
signal manual_requested

const ScienceScript = preload("res://scripts/science/science_data.gd")
const Explainers = preload("res://scripts/ui/science_explainers.gd")
const ChartScript = preload("res://scripts/ui/data_chart.gd")
const Chapter1FeedbackScript = preload("res://scripts/feedback/chapter1_feedback.gd")
var science = ScienceScript.new()

const INK := Color("#05060A")
const NAVY := Color("#12151F")
const IVORY := Color("#ECEEF0")
const MUTED := Color("#A8B4C8")
const MUSTARD := Color("#3AA0FF")
const CYAN := Color("#FF6B9D")
const GREEN := Color("#4CAF50")

const PANEL_IDS := [
	"objective",
	"dialogue_captions",
	"journal_discovery",
	"mission_table",
	"puzzle",
	"outcome",
	"chapter1_outcome",
	"pause",
	"settings_accessibility",
	"credits",
	"sources",
	"data_card",
	"resume",
	"what_now",
]

## Titles and purpose lines are player words (doc 25 §1.1); ids stay as they are.
const PANEL_DEFINITIONS := {
	"sources": {"title": "Sources", "query_key": "sources", "description": "The NASA and partner data behind the game. Open one to see what it means for Aurora."},
	"data_card": {"title": "Data card", "query_key": "data_card", "description": "What was measured, what the game worked out, and where the limits are."},
	"objective": {"title": "Goal", "query_key": "objective", "description": "What to do next and why."},
	"dialogue_captions": {"title": "Dialogue", "query_key": "dialogue_lines", "description": "Every line of this scene, with who said it."},
	"journal_discovery": {"title": "Journal", "query_key": "journal_entries", "description": "What the crew has found so far. Up and down change tabs; right opens the page."},
	"resume": {"title": "Previously at Aurora", "query_key": "journal_entries", "description": "Where you were when you last saved. Reading does not move the clock."},
	"mission_table": {"title": "Mission Table", "query_key": "mission_table", "description": "The night plan and its forecast."},
	"puzzle": {"title": "Your choice", "query_key": "puzzle", "description": "Try an option to see what it would mean."},
	"chapter1_outcome": {"title": "First light", "query_key": "chapter1_outcome", "description": "Your night, your decisions, and the science behind them."},
	"outcome": {"title": "Last result", "query_key": "outcome", "description": "What the last job changed."},
	"pause": {"title": "Paused", "query_key": "pause", "description": "The game waits for you. Nothing changes until you press Resume."},
	"settings_accessibility": {"title": "Settings", "query_key": "accessibility", "description": "Captions, text size, reduced motion and timer-free play."},
	"credits": {"title": "Credits", "query_key": "credits", "description": "Who made this, and with what."},
	"what_now": {"title": "What now", "query_key": "what_now", "description": "Your goal, why it matters, where to go and a hint."},
}

const BLUR_SHADER := """
shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_lod = 2.5;
uniform vec4 tint : source_color = vec4(0.02, 0.024, 0.04, 0.72);
void fragment() {
	vec4 scene = textureLod(screen_texture, SCREEN_UV, blur_lod);
	COLOR = vec4(mix(scene.rgb, tint.rgb, tint.a), 1.0);
}
"""

var _query: Dictionary = {}
var _settings := {
	"captions": true,
	"large_text": false,
	"timer_free": true,
	"reduced_motion": false,
}
var _query_provider: Callable
var _command_sink: Callable
var _active_panel := ""
var _overlay: ColorRect
var _panel: PanelContainer
var _title: Label
var _description: Label
var _body: VBoxContainer
var _close_button: Button
var _safe_top := 0.0
var _last_focus: Control
var _columns: HBoxContainer
var _side: VBoxContainer
var _scroll: ScrollContainer
## Journal presentation state (never saved): the open tab, which "What now?"
## hints the player asked for per scene, and a one-tap Growth Record view swap.
var _journal_tab := "now"
var hint_player: HintPlayer
var _garden_layout_override := ""
var _ending_page := "summary"
var _replay_index := 0
var _lesson_index := 0
var _ending_answers := {}
var _assist_mode := "Cadet"
var _bindings: Dictionary = {
	"move": "W A S D",
	"look": "Mouse",
	"use": "E",
	"what_now": "H",
	"journal": "J",
	"pause": "Esc",
}
var _reset_confirm_pending := false
var _onboarding_notice := ""
const Debrief = preload("res://scripts/debrief/chapter1_debrief.gd")

const JOURNAL_TABS := [
	{"id": "now", "label": "Now"},
	{"id": "evidence", "label": "Evidence"},
	{"id": "garden", "label": "Garden"},
	{"id": "decisions", "label": "Decisions"},
	{"id": "people", "label": "People"},
	{"id": "science", "label": "Science"},
	{"id": "manual", "label": "Manual"},
]
const JOURNAL_PANEL_WIDTH := 1180.0
const PANEL_WIDTH := 960.0
const SIDE_WIDTH := 200.0
const STATUS_BADGES := {"OBSERVED": "• OBSERVED", "VERIFIED": "• VERIFIED", "INFERRED": "• INFERRED", "UNKNOWN": "• UNKNOWN", "LINKED": "• LINKED", "ARCHIVED": "• ARCHIVED"}
var _builders: Dictionary = {}
var _pause_actions: Array = []
var _tween: Tween

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	hint_player = preload("res://scripts/ui/hint_player.gd").new()
	add_child(hint_player)
	hint_player.opened.connect(func():
		_overlay.hide()
		_panel.hide()
		panel_opened.emit("hint"))
	hint_player.closed.connect(func():
		_overlay.visible = not _active_panel.is_empty()
		_panel.visible = not _active_panel.is_empty()
		panel_closed.emit("hint"))

func bind_query(query: Dictionary) -> void:
	_query = query.duplicate(true)
	var supplied = _query.get("accessibility", _query.get("settings", {}))
	if supplied is Dictionary:
		_set_settings(supplied, false)
	if not _active_panel.is_empty():
		_render_active_panel()

func bind_query_provider(provider: Callable) -> void:
	_query_provider = provider

func set_command_sink(sink: Callable) -> void:
	_command_sink = sink

## Lets an owner (the HUD) fill a panel's body itself. The callable receives the
## body container; children it marks with meta "lla_keep" are handed back, not freed.
func set_panel_builder(panel_id: String, builder: Callable) -> void:
	_builders[panel_id] = builder

## The pause menu entries, in order: [{"label": String, "action": Callable}].
## "Resume" is always first and closes the panel.
func set_pause_actions(actions: Array) -> void:
	_pause_actions = actions.duplicate()

func query_snapshot() -> Dictionary:
	return _query.duplicate(true)

func accessibility_settings() -> Dictionary:
	return _settings.merged({"assist_mode": _assist_mode, "bindings": _bindings.duplicate(true)}, true)

func set_accessibility(settings: Dictionary) -> void:
	_set_settings(settings, true)

func captions_visible() -> bool:
	return bool(_settings.get("captions", true))

func is_timer_free() -> bool:
	return bool(_settings.get("timer_free", true))

func is_reduced_motion() -> bool:
	return bool(_settings.get("reduced_motion", false))

func text_scale() -> float:
	return 1.5 if bool(_settings.get("large_text", false)) else 1.0

func presentation_transition_seconds() -> float:
	## Show and hide ease out in 150–250 ms; reduced motion makes them instant.
	return 0.0 if is_reduced_motion() else float(UiDesign.tokens().get("motion", {}).get("show_seconds", 0.2))

func open_panel(panel_id: String, data: Dictionary = {}) -> bool:
	if not PANEL_DEFINITIONS.has(panel_id):
		return false
	if _active_panel.is_empty():
		_last_focus = _focused_control()
	if _query_provider.is_valid():
		var supplied = _query_provider.call()
		if supplied is Dictionary:
			bind_query(supplied)
	if not data.is_empty():
		var next_query := _query.duplicate(true)
		next_query[String(PANEL_DEFINITIONS[panel_id].get("query_key", ""))] = data.duplicate(true)
		_query = next_query
	var was_open := not _active_panel.is_empty()
	_active_panel = panel_id
	_render_active_panel()
	_overlay.show()
	_panel.show()
	if not was_open:
		_animate_open()
	panel_opened.emit(panel_id)
	_close_button.grab_focus()
	if panel_id == "journal_discovery":
		_focus_journal_tab(_journal_tab)
	return true

## Opens the Expedition Journal on one tab ("now", "evidence", "garden" or
## "decisions" or "science"). An empty journal argument keeps the bound query's journal.
func open_journal(tab: String = "now", journal: Dictionary = {}) -> bool:
	if JOURNAL_TABS.any(func(item): return item.id == tab):
		_journal_tab = tab
	return open_panel("journal_discovery", journal)

func journal_tab() -> String:
	return _journal_tab

## Switches the open journal to another tab and keeps keyboard focus on it.
func select_journal_tab(tab: String) -> void:
	if not JOURNAL_TABS.any(func(item): return item.id == tab):
		return
	_journal_tab = tab
	if _active_panel == "journal_discovery":
		_render_active_panel()
		_focus_journal_tab(tab)

func close_panel() -> void:
	if hint_player.is_open():
		hint_player.close()
		return
	if _active_panel.is_empty():
		return
	var closed := _active_panel
	var return_focus := _last_focus
	_last_focus = null
	_active_panel = ""
	_garden_layout_override = ""
	_side.hide()
	_release_kept_children()
	_overlay.hide()
	_panel.hide()
	panel_closed.emit(closed)
	_restore_focus(return_focus)

func active_panel() -> String:
	return _active_panel

func command_for(verb: String, target_id: String = "", payload: Dictionary = {}, issuer: String = "ui") -> Dictionary:
	var state_revision := int(_query.get("state_revision", 0))
	var mission_id := String(_query.get("mission_id", ""))
	var scene_id := String(_query.get("scene_id", ""))
	var command_id := "ui:%s:%s:%s:%s" % [verb, target_id, scene_id, state_revision]
	return {
		"command_id": command_id,
		"issuer": issuer,
		"owning_mission_id": mission_id,
		"owning_scene_id": scene_id,
		"expected_state_revision": state_revision,
		"target_id": target_id,
		"verb": verb,
		"payload": payload.duplicate(true),
	}

func emit_command(verb: String, target_id: String = "", payload: Dictionary = {}, issuer: String = "ui") -> Dictionary:
	var command := command_for(verb, target_id, payload, issuer)
	command_emitted.emit(command.duplicate(true))
	if _command_sink.is_valid():
		_command_sink.call(command.duplicate(true))
	return command

func _build() -> void:
	var shell: Control = self
	if not has_node("Panel"):
		# Script-only callers receive the same authored composition as the editor scene.
		shell = load("res://scenes/ui/campaign_panels.tscn").instantiate()
		shell.set_script(null)
		add_child(shell)
	theme = UiKit.theme()
	_overlay = shell.get_node("Overlay")
	var shader := Shader.new()
	shader.code = BLUR_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	_overlay.material = material
	_overlay.hide()
	_panel = shell.get_node("Panel")
	_panel.add_theme_stylebox_override("panel", UiDesign.glass_style(Color.TRANSPARENT, Color.TRANSPARENT, 0))
	_panel.z_index = 40
	_panel.minimum_size_changed.connect(_layout_panel.call_deferred)
	_panel.hide()
	var page := shell.get_node("Panel/Margin/Page")
	_title = page.get_node("Title")
	_description = page.get_node("Description")
	_columns = page.get_node("Columns")
	_side = _columns.get_node("JournalTabs")
	_side.hide()
	_scroll = _columns.get_node("Scroll")
	_scroll.get_v_scroll_bar().focus_mode = Control.FOCUS_ALL
	_body = _scroll.get_node("Body")
	_close_button = page.get_node("Footer/Close")
	_close_button.pressed.connect(close_panel)

func _animate_open() -> void:
	var seconds := presentation_transition_seconds()
	if seconds <= 0.0 or not is_inside_tree():
		_panel.modulate.a = 1.0
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_panel.modulate.a = 0.0
	# Deep Space motion: a soft quintic fade (geometry stays put so layout and focus are exact from the first frame).
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	_tween.tween_property(_panel, "modulate:a", 1.0, maxf(seconds, 0.28))

## Hands body children an owner wants back (meta "lla_keep") to that owner
## instead of freeing them with the rest of the body.
func _release_kept_children() -> void:
	for child in _body.get_children():
		if child.has_meta("lla_keep"):
			_body.remove_child(child)
			var home = child.get_meta("lla_home") if child.has_meta("lla_home") else null
			if home is Node and is_instance_valid(home):
				home.add_child(child)

func _render_active_panel() -> void:
	if _active_panel.is_empty() or not PANEL_DEFINITIONS.has(_active_panel):
		return
	_release_kept_children()
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	var definition: Dictionary = PANEL_DEFINITIONS[_active_panel]
	_title.text = String(definition.get("title", _active_panel.capitalize()))
	_description.text = String(definition.get("description", ""))
	var query_key := String(definition.get("query_key", ""))
	var value = _query.get(query_key, {})
	if _builders.has(_active_panel) and (_builders[_active_panel] as Callable).is_valid():
		(_builders[_active_panel] as Callable).call(_body)
	elif _active_panel == "settings_accessibility":
		_render_settings()
	elif _active_panel == "pause":
		_render_pause()
	elif _active_panel == "resume":
		_render_resume_panel(value)
	elif _active_panel == "dialogue_captions":
		_render_dialogue(value)
	elif _active_panel == "puzzle":
		_render_puzzle(value)
	elif _active_panel == "chapter1_outcome":
		_render_chapter1_outcome(value)
	elif _active_panel == "outcome":
		_render_outcome(value)
		_render_puzzle_sources(_query.get("source_puzzle_ids", []))
	elif _active_panel == "journal_discovery":
		_render_journal(value)
		_source_button("Sources · all data cards", func(): open_panel("sources", {"ids": []}))
	elif _active_panel == "sources":
		_render_sources()
	elif _active_panel == "data_card":
		_render_card(value)
	elif _active_panel == "credits":
		_render_credits(value)
	else:
		_render_data(value)
		if _active_panel in ["outcome", "mission_table"]:
			_render_puzzle_sources(_query.get("source_puzzle_ids", []))
	if _active_panel != "journal_discovery":
		_side.hide()
	var hud_words: Dictionary = UiDesign.text().get("hud", {})
	_close_button.text = String(hud_words.get("continue", "Continue")) if _active_panel == "resume" else "%s · %s" % [String(hud_words.get("close", "Close")), String(hud_words.get("close_key", "Esc"))]
	_apply_accessibility()
	_layout_panel()

## Kept for callers; the panel now centres itself inside the safe margin.
func set_content_top(value: float) -> void:
	_safe_top = value
	_layout_panel()

func _layout_panel() -> void:
	if _panel == null or _safe_top <= 0 or not is_inside_tree():
		return
	var view := get_viewport_rect().size
	var margin := float(UiDesign.px(float(UiDesign.tokens().get("panel", {}).get("safe_margin", 64)), view.y))
	var width := minf(JOURNAL_PANEL_WIDTH if _active_panel == "journal_discovery" else PANEL_WIDTH, view.x - margin * 2)
	var top := margin
	var height := maxf(300, view.y - margin * 2)
	var needed := _panel.get_combined_minimum_size().y
	if needed > height:
		# Large text on a small window: use the margin rather than run off the bottom edge.
		height = minf(needed, view.y - 32)
		top = maxf(16, (view.y - height) * 0.5)
	_panel.z_index = 80 if top < margin else 40
	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_panel.position = Vector2((view.x - width) * 0.5, top)
	_panel.size = Vector2(width, height)

func _render_data(value) -> void:
	var body := UiDesign.label(_display_value(value), "body")
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_child(body)

const PAUSE_ICONS := {"WhatNow": "what_now", "Messages": "message", "Journal": "journal", "Settings": "settings", "Save": "save", "SaveAndQuit": "exit",
	"Open_save_slots": "save", "Open_cadet_record": "person", "Open_manual": "info", "Open_jobs": "goal", "Open_discovery": "leaf", "Open_greenhouse": "plant",
	"Open_coverage": "place", "Open_route_planner": "route", "Open_rover": "rover", "Open_hazards": "warning", "Open_field": "tank", "Open_credits": "people"}

## Pause (Instrument Light): Resume is the one gold action; the six everyday
## actions are icon tiles; station tools are a quieter icon grid below.
func _render_pause() -> void:
	var words: Dictionary = UiDesign.text().get("hud", {})
	var resume := UiDesign.make_primary(UiDesign.button(String(words.get("resume", "Resume")), 52, "arrow_right"))
	resume.name = "Resume"
	resume.pressed.connect(close_panel)
	_body.add_child(resume)
	var tiles := GridContainer.new()
	tiles.name = "PauseTiles"
	tiles.columns = 3
	tiles.add_theme_constant_override("h_separation", 10)
	tiles.add_theme_constant_override("v_separation", 10)
	var tools := GridContainer.new()
	tools.name = "StationTools"
	tools.columns = 3
	tools.add_theme_constant_override("h_separation", 8)
	tools.add_theme_constant_override("v_separation", 8)
	for raw in _pause_actions:
		if not raw is Dictionary:
			continue
		var entry: Dictionary = raw
		var name := String(entry.get("name", String(entry.get("label", "")).to_pascal_case()))
		var is_tool := name.begins_with("Open_")
		var button := UiDesign.button(String(entry.get("label", "")), 44 if is_tool else 84, String(PAUSE_ICONS.get(name, "")))
		button.name = name
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.clip_text = true
		if is_tool:
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		else:
			button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
			button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			button.add_theme_constant_override("icon_max_width", 28)
		var action: Callable = entry.get("action", Callable())
		if action.is_valid():
			button.pressed.connect(action)
		(tools if is_tool else tiles).add_child(button)
	_body.add_child(tiles)
	_render_resume_card(_journal_data())
	# Kid-friendly pause (13 Nov review): the twelve station tools are for curious
	# players, not the everyday loop, so they wait behind one quiet toggle.
	if tools.get_child_count() > 0:
		var more := UiDesign.button("More station tools  ▸", 44, "info")
		more.name = "MoreTools"
		more.toggle_mode = true
		more.alignment = HORIZONTAL_ALIGNMENT_LEFT
		more.tooltip_text = "Save slots, cadet record, greenhouse, rover and more."
		tools.visible = false
		more.toggled.connect(func(open: bool) -> void:
			tools.visible = open
			more.text = "Hide station tools  ▾" if open else "More station tools  ▸"
			if open and tools.get_child_count() > 0:
				_scroll.ensure_control_visible.call_deferred(tools.get_child(tools.get_child_count() - 1))
		)
		_body.add_child(more)
		_body.add_child(tools)
	else:
		tools.free()

func _render_dialogue(value) -> void:
	if not captions_visible():
		_render_data("Captions are off. Turn them on in Settings to read the lines.")
		return
	var lines: Array = value if value is Array else []
	if lines.is_empty():
		_render_data("No lines yet.")
		return
	var origins: Dictionary = UiDesign.text().get("dialogue", {}).get("origins", {})
	for raw_line in lines:
		if not raw_line is Dictionary:
			continue
		var line: Dictionary = raw_line
		var origin := String(origins.get(String(line.get("origin_label", "")), ""))
		var speaker := String(line.get("speaker", ""))
		if not origin.is_empty():
			speaker += " · " + origin
		var label := UiDesign.label("%s\n%s" % [speaker, String(line.get("text", ""))], "body")
		label.set_meta("verbatim", true)  # canon lines stay word for word (STORY_FULL.md)
		_body.add_child(label)
		var acknowledge := _button(String(UiDesign.text().get("hud", {}).get("next_line", "Next")))
		acknowledge.pressed.connect(func() -> void:
			emit_command("acknowledge_line", String(line.get("id", "")), {"line_id": String(line.get("id", "")), "dialogue_only": true})
		)
		_body.add_child(acknowledge)

func _render_puzzle(value) -> void:
	var data: Dictionary = value if value is Dictionary else {}
	if data.has("choice_id"):
		_render_decision_review(data)
		return
	var prompt := UiDesign.label(UiDesign.player_words(String(data.get("prompt", "Pick a job to see what it would change."))), "body")
	_body.add_child(prompt)
	var options: Array = data.get("options", [])
	for raw_option in options:
		if not raw_option is Dictionary:
			continue
		var option: Dictionary = raw_option
		var option_id := String(option.get("id", ""))
		var button := _button(String(option.get("label", option_id)))
		button.pressed.connect(func() -> void:
			emit_command("preview_puzzle", option_id, {"option_id": option_id})
		)
		_body.add_child(button)
	_render_puzzle_sources([data.get("puzzle_id", "")] if data.has("puzzle_id") else _query.get("source_puzzle_ids", []))
	var forecast := UiDesign.label("Forecast\n" + UiDesign.player_words(String(data.get("forecast", "Try an option to see its forecast."))), "caption", "muted")
	_body.add_child(forecast)

func _render_decision_review(data: Dictionary) -> void:
	_title.text = String(UiDesign.text().get("hud", {}).get("your_choice", "Your choice"))
	_description.text = "Try an option, then confirm it. You can change it until you leave this scene."
	_card_text(String(data.get("prompt", "")))
	var recorded := String(data.get("recorded_option_id", ""))
	var locked := bool(data.get("locked", false))
	var selected := {"option_id": recorded}
	var group := ButtonGroup.new()
	var forecast := UiDesign.label("Pick an option to see what it means.", "caption", "muted")
	var confirm := _button("Confirm choice")
	confirm.name = "ConfirmChoice"
	confirm.disabled = true
	for option in data.get("options", []):
		var option_id := String(option.get("id", ""))
		var label := String(option.get("label", option_id))
		var consequence := String(option.get("consequence", ""))
		var button := _button(label)
		button.name = option_id
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = option_id == recorded
		button.disabled = locked
		if option_id == recorded:
			forecast.text = "Recorded: %s\n%s" % [label, consequence]
		button.pressed.connect(func() -> void:
			selected.option_id = option_id
			forecast.text = "Try it: %s\n%s" % [label, consequence]
			confirm.disabled = option_id == recorded
			emit_command("preview_puzzle", option_id, {"choice_id": data.choice_id, "option_id": option_id})
		)
		_body.add_child(button)
	_body.add_child(forecast)
	_card_text("This scene is over, so the choice is locked." if locked else "You can change your mind until you leave this scene. Jobs keep their own safety checks.")
	confirm.pressed.connect(func() -> void:
		# Closing the reading panel resumes the director before the command is
		# committed. Pausing remains authoritative for every other operation.
		close_panel()
		emit_command("record_choice", String(data.choice_id), {"choice_id": data.choice_id, "option_id": selected.option_id})
	)
	_body.add_child(confirm)

func _render_settings() -> void:
	var intro := UiDesign.label("These change how the game looks and sounds. They never change the station or the story.", "caption", "muted")
	_body.add_child(intro)
	for key in ["captions", "large_text", "timer_free", "reduced_motion"]:
		var check := CheckButton.new()
		check.name = key
		check.text = _setting_label(key)
		check.add_theme_color_override("font_color", IVORY)
		check.add_theme_color_override("font_pressed_color", IVORY)
		check.add_theme_color_override("font_hover_pressed_color", IVORY)
		check.add_theme_color_override("font_hover_color", IVORY)
		check.button_pressed = bool(_settings.get(key, false))
		check.focus_mode = Control.FOCUS_ALL
		check.pressed.connect(func() -> void:
			_set_settings({key: check.button_pressed}, true)
		)
		_body.add_child(check)
	# Volumes are per machine (user://audio_settings.cfg), not part of the expedition save.
	for bus in AudioSettings.BUSES:
		var row := HBoxContainer.new()
		var name_label := UiDesign.label(String(AudioSettings.LABELS[bus]), "body")
		name_label.custom_minimum_size.x = 220
		row.add_child(name_label)
		var slider := HSlider.new()
		slider.name = "volume_" + bus
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.value = AudioSettings.volume(bus)
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		slider.focus_mode = Control.FOCUS_ALL
		slider.accessibility_name = name_label.text
		var percent := UiDesign.label("%d%%" % roundi(slider.value * 100.0), "caption", "muted")
		percent.custom_minimum_size.x = 56
		slider.value_changed.connect(func(value: float) -> void:
			AudioSettings.set_volume(bus, value)
			percent.text = "%d%%" % roundi(value * 100.0)
		)
		row.add_child(slider)
		row.add_child(percent)
		_body.add_child(row)
	var controls := UiDesign.label("Controls\nMove: %s · Look: %s\nUse: %s · What now: %s · Journal: %s · Pause: %s\nNext line: Space · Continue: Enter" % [
		String(_bindings.get("move", "W A S D")),
		String(_bindings.get("look", "Mouse")),
		String(_bindings.get("use", "E")),
		String(_bindings.get("what_now", "H")),
		String(_bindings.get("journal", "J")),
		String(_bindings.get("pause", "Esc")),
	], "caption", "ivory")
	controls.name = "Controls"
	_body.add_child(controls)
	var assist_btn := _button("Assist Mode: %s (Click to cycle Story / Cadet / Expedition)" % _assist_mode)
	assist_btn.name = "SettingsAssistMode"
	assist_btn.pressed.connect(func() -> void:
		var order := ["Story", "Cadet", "Expedition"]
		_assist_mode = order[(order.find(_assist_mode) + 1) % order.size()]
		_set_settings({"assist_mode": _assist_mode}, true)
		if _active_panel == "settings_accessibility":
			_render_active_panel()
	)
	_body.add_child(assist_btn)
	var replay_prompts_btn := _button("Replay first-time onboarding prompts (move, look, use, table, journal)")
	replay_prompts_btn.name = "ReplayFirstTimePrompts"
	replay_prompts_btn.pressed.connect(func() -> void:
		if hint_player != null:
			hint_player.reset_seen()
		_onboarding_notice = "First-time prompts reset — they will appear again on your next action."
		emit_command("reset_first_time_prompts", "onboarding", {}, "accessibility")
		if _active_panel == "settings_accessibility":
			_render_active_panel()
	)
	_body.add_child(replay_prompts_btn)
	var remap_btn := _button("Swap Use (%s) ↔ What now (%s) binding" % [String(_bindings.get("use", "E")), String(_bindings.get("what_now", "H"))])
	remap_btn.name = "SwapUseWhatNowBinding"
	remap_btn.pressed.connect(func() -> void:
		remap_binding("use", String(_bindings.get("what_now", "H")))
	)
	_body.add_child(remap_btn)
	var reset_btn := _button("Confirm Reset All Bindings & Settings" if _reset_confirm_pending else "Reset Bindings & Settings to Default")
	reset_btn.name = "ResetSettingsBindings"
	reset_btn.pressed.connect(func() -> void:
		if not _reset_confirm_pending:
			_reset_confirm_pending = true
			_onboarding_notice = "Press again to confirm resetting all bindings and settings to default."
			if _active_panel == "settings_accessibility":
				_render_active_panel()
		else:
			reset_bindings_and_settings(true)
	)
	_body.add_child(reset_btn)
	if not _onboarding_notice.is_empty():
		var notice_lbl := UiDesign.label(_onboarding_notice, "caption", "accent")
		notice_lbl.name = "SettingsOnboardingNotice"
		_body.add_child(notice_lbl)
	var notes := UiDesign.label(
		"Captions keep every line readable when a voice is missing, and caption the sounds that matter.\n"
		+ ("Timer-free: nothing needs a quick reaction.\n" if is_timer_free() else "Standard timing: timed tasks show their clock.\n")
		+ ("Reduced motion: panels change instantly.\n" if is_reduced_motion() else "Reduced motion is available here.\n")
		+ "None of these skip a safety check.",
		"caption", "muted")
	_body.add_child(notes)

func remap_binding(action_id: String, new_key: String) -> Dictionary:
	if action_id not in ["use", "what_now"] or new_key not in ["E", "H"]:
		return {"accepted": false, "reason": "This shortcut swaps Use and What now between E and H."}
	var old_key := String(_bindings[action_id])
	var swapped_with := ""
	for other_id in _bindings.keys():
		if other_id != action_id and String(_bindings[other_id]) == new_key:
			_bindings[other_id] = old_key
			swapped_with = String(other_id)
			break
	_bindings[action_id] = new_key
	_apply_bindings()
	_set_settings({}, true)
	_onboarding_notice = (
		"Remapped %s to %s (swapped conflict with %s → %s)." % [action_id, new_key, swapped_with, old_key]
		if not swapped_with.is_empty()
		else "Remapped %s to %s." % [action_id, new_key]
	)
	if _active_panel == "settings_accessibility":
		_render_active_panel()
	return {"accepted": true, "action_id": action_id, "new_key": new_key, "swapped_with": swapped_with}

func bindings_snapshot() -> Dictionary:
	return _bindings.duplicate(true)

func reset_bindings_and_settings(confirmed: bool = true) -> bool:
	if not confirmed:
		_reset_confirm_pending = true
		return false
	_reset_confirm_pending = false
	_assist_mode = "Cadet"
	_bindings = {
		"move": "W A S D",
		"look": "Mouse",
		"use": "E",
		"what_now": "H",
		"journal": "J",
		"pause": "Esc",
	}
	_apply_bindings()
	_onboarding_notice = "Bindings and accessibility settings restored to defaults."
	_set_settings({
		"captions": true,
		"large_text": false,
		"timer_free": true,
		"reduced_motion": false,
	}, true)
	return true

func _set_settings(settings: Dictionary, emit_change: bool) -> void:
	var focus_key := ""
	if emit_change and is_inside_tree():
		var focused := get_viewport().gui_get_focus_owner()
		if focused is CheckButton and _body.is_ancestor_of(focused):
			focus_key = String(focused.name)
	for key in _settings.keys():
		if settings.has(key):
			_settings[key] = bool(settings[key])
	if settings.get("assist_mode", "") in ["Story", "Cadet", "Expedition"]:
		_assist_mode = String(settings.assist_mode)
	var bindings = settings.get("bindings", {})
	if bindings is Dictionary and bindings.get("use", "") in ["E", "H"] and bindings.get("what_now", "") in ["E", "H"] and bindings.use != bindings.what_now:
		var changed: bool = _bindings.use != bindings.use or _bindings.what_now != bindings.what_now
		_bindings["use"] = bindings.use
		_bindings["what_now"] = bindings.what_now
		# An accessibility refresh must not undo full Settings keyboard remapping.
		if changed and not FileAccess.file_exists(GameSettings.DEFAULT_PATH):
			_apply_bindings()
	_apply_accessibility()
	if _active_panel == "journal_discovery":
		# Column stacking and photo strips depend on the text scale.
		var focused_tab := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
		var keep_tab: bool = focused_tab != null and String(focused_tab.name).begins_with("Tab_")
		_render_active_panel()
		if keep_tab:
			_focus_journal_tab(_journal_tab)
	if emit_change:
		var copy := accessibility_settings()
		accessibility_changed.emit(copy)
		emit_command("set_accessibility", "accessibility", copy, "accessibility")
		if _active_panel == "settings_accessibility":
			_render_active_panel()
			var next_focus := _body.get_node_or_null(focus_key) as Control if not focus_key.is_empty() else null
			if next_focus != null:
				next_focus.grab_focus()

func _apply_bindings() -> void:
	# Full remapping is M3-70; this existing shortcut changes only the supported E/H pair.
	for event in InputMap.action_get_events("interact"):
		if event is InputEventKey:
			InputMap.action_erase_event("interact", event)
	var event := InputEventKey.new()
	event.physical_keycode = KEY_H if _bindings.use == "H" else KEY_E
	InputMap.action_add_event("interact", event)

func _setting_label(key: String) -> String:
	return {
		"captions": "Captions on",
		"large_text": "Large text (150%)",
		"timer_free": "Timer-free alternatives",
		"reduced_motion": "Reduced motion",
	}.get(key, key)

func _display_value(value) -> String:
	if value is String:
		return value
	if value is Array:
		var rows: Array[String] = []
		for item in value:
			rows.append("• " + _display_value(item))
		return "\n".join(rows)
	if value is Dictionary:
		if value.is_empty():
			return "Nothing here yet."
		var rows: Array[String] = []
		for key in value.keys():
			rows.append("%s: %s" % [String(key).capitalize(), _display_value(value[key])])
		return "\n".join(rows)
	return str(value)

func _button(text: String) -> Button:
	var button := UiDesign.button(text, 44)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	return button

func _panel_style(size: Vector2, border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = -size * 0.5
	panel.size = size
	panel.z_index = 40
	panel.add_theme_stylebox_override("panel", UiDesign.glass_style(border, Color(0.03, 0.05, 0.10, 0.94), 0))
	return panel

func _button_style(color: Color, text_color: Color, highlighted: bool) -> StyleBoxFlat:
	return UiDesign.button_style(color, highlighted)

func _apply_accessibility() -> void:
	if not is_inside_tree():
		return
	set_meta("accessibility_settings", _settings.duplicate(true))
	set_meta("presentation_transition_seconds", presentation_transition_seconds())
	_apply_text_scale(self)
	# Keep the measured button inside the footer while containers await reflow.
	var width := _close_button.get_theme_font("font").get_string_size(_close_button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, _close_button.get_theme_font_size("font_size")).x + _close_button.get_theme_stylebox("normal").get_minimum_size().x
	_close_button.size.x = maxf(width, _close_button.get_combined_minimum_size().x)
	_close_button.position.x = maxf(0, _close_button.get_parent_control().size.x - _close_button.size.x)

func _apply_text_scale(node: Node) -> void:
	UiDesign.apply_type(node, get_viewport_rect().size.y, text_scale())

func _focused_control() -> Control:
	if get_viewport() == null:
		return null
	var focused := get_viewport().gui_get_focus_owner()
	if _can_restore_focus(focused) and not _is_panel_descendant(focused):
		return focused as Control
	return null

func _restore_focus(candidate: Control) -> void:
	if _can_restore_focus(candidate) and not _is_panel_descendant(candidate):
		candidate.grab_focus()
		return
	if _focused_control() != null:
		return
	if get_viewport() != null:
		get_viewport().gui_release_focus()

func _can_restore_focus(candidate: Control) -> bool:
	if not is_instance_valid(candidate) or not candidate.is_inside_tree() or not candidate.is_visible_in_tree():
		return false
	if candidate.focus_mode == Control.FOCUS_NONE:
		return false
	if candidate is BaseButton and (candidate as BaseButton).disabled:
		return false
	return true

func _is_panel_descendant(candidate: Control) -> bool:
	return is_instance_valid(candidate) and candidate != self and is_ancestor_of(candidate)

func _unhandled_key_input(event: InputEvent) -> void:
	if hint_player.is_open():
		return
	if event.is_action_pressed("ui_cancel") and not event.is_echo() and not _active_panel.is_empty():
		close_panel()
		get_viewport().set_input_as_handled()

func _source_button(text: String, action: Callable) -> void:
	var button := _button(text)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(action)
	_body.add_child(button)

func _render_sources() -> void:
	var mission_id := String(_query.get("mission_id", ""))
	var mission: Dictionary = science.mission_card(mission_id)
	if not mission.is_empty():
		var button := _button("Mission data card - " + String(mission.title))
		button.name = "MissionDataCard"
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(func(): open_panel("data_card", {"mission_id": mission_id}))
		_body.add_child(button)
	var filter: Array = _query.get("sources", {}).get("ids", [])
	for id in science.source_ids() if filter.is_empty() else filter:
		var card: Dictionary = science.card(String(id))
		_source_button(String(card.get("title", id)), func(): open_panel("data_card", {"source_id": id}))

func _render_puzzle_sources(puzzle_ids: Array) -> void:
	var ids: Array = []
	for puzzle_id in puzzle_ids:
		for card in science.cards_for_puzzle(String(puzzle_id)):
			if not ids.has(card.source_id):
				ids.append(card.source_id)
	if not ids.is_empty():
		_source_button("Data cards · the evidence behind these numbers", func(): open_panel("sources", {"ids": ids}))

## Card text in player words; `verbatim` (measured data quoted from a dataset) is shown exactly as published.
func _card_text(text: String, emphasis: bool = false, verbatim: bool = false) -> void:
	var label := UiDesign.label(text if verbatim else UiDesign.player_words(text), "body", "accent" if emphasis else "ivory")
	if verbatim:
		label.set_meta("verbatim", true)
	_body.add_child(label)

func _render_watch_buttons(entries: Array) -> void:
	for entry in entries:
		var button := _button("Watch: " + String(entry.title))
		button.name = "Watch_" + String(entry.id)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(func():
			hint_player.set_settings(_settings)
			hint_player.watch(String(entry.id)))
		_body.add_child(button)

func _render_mission_card(mission_id: String) -> void:
	var card: Dictionary = science.mission_card(mission_id)
	if card.is_empty():
		_card_text("Mission data card unavailable.")
		return
	_card_text(String(card.title), true)
	_render_watch_buttons(Explainers.matching([mission_id], card.get("source_ids", [])))
	_card_text(String(card.get("plain", "")))
	_card_text("What this means for Aurora\n" + String(card.get("for_aurora", {}).get("text", "")), true)
	_card_text("Your decision\n" + String(card.get("decision", "")))
	var visual: Dictionary = card.get("visual", {})
	if not visual.get("values", []).is_empty():
		var chart := ChartScript.new()
		chart.series = visual
		_body.add_child(chart)
		_card_text(" - ".join(visual.get("labels", [])) + "\n" + String(visual.get("note", "")))
	_card_text("Evidence - " + String(card.get("evidence", "")))
	_card_text("Limits\n" + String(card.get("limits", "")))
	_card_text("Sources\n" + "\n".join(card.get("source_lines", [])), false, true)
	for source_id in card.get("source_ids", []):
		_source_button("Full source - " + String(science.card(source_id).get("title", "Evidence")), func(): open_panel("data_card", {"source_id": source_id}))
	_source_button("Back to all sources", func(): open_panel("sources", {"ids": []}))

func _render_card(value) -> void:
	if value is Dictionary and value.has("mission_id"):
		_render_mission_card(String(value.mission_id))
		return
	var id := String(value.get("source_id", "")) if value is Dictionary else ""
	var card: Dictionary = science.card(id)
	_render_watch_buttons(Explainers.matching([], [id]))
	_card_text("What this means for Aurora\n" + String(card.get("takeaway", "")), true)
	if not bool(card.get("pending", true)):
		var visual: Dictionary = card.get("visual", {})
		# The card title names the chart; the fixture column name stays in the smaller line below it.
		var visual_title := String(card.get("title", String(visual.get("label", "")).replace("_", " ").capitalize()))
		if visual.get("kind") != "line":
			visual_title += " · %s %s" % [str(visual.get("values", [0])[0]), visual.get("unit", "")]
		_card_text(visual_title, true)
		var chart := ChartScript.new()
		chart.series = visual
		_body.add_child(chart)
		var values: Array = visual.get("values", [])
		_card_text("Data column: " + String(visual.get("label", "")).replace("_", " ") + " · " + String(visual.get("unit", "")) + "\n" + ("First %s · last %s · lowest %s · highest %s\n%s → %s" % [values[0], values[-1], values.min(), values.max(), visual.get("start", ""), visual.get("end", "")] if values.size() > 1 else str(values[0])) + "\n" + String(visual.get("axis", "")))
		_card_text(String(card.get("title", "")), true)
		_card_text("Evidence · " + String(card.get("evidence_label", "")) + "\n" + String(card.get("agency", "")) + "\nDataset: " + String(card.get("dataset_id", "")))
		_card_text("What was measured or supplied\n" + ScienceScript.describe(card.get("fields_used", [])) + "\n" + ScienceScript.describe(card.get("values", {})), false, true)
		# Keep formulas and caveats exact; only repository references and puzzle codes become player words.
		var computation := ScienceScript.describe(card.get("derived", [])).replace("game-design/08_PUZZLE_DESIGNS.md", "Mission model").replace("08_PUZZLE_DESIGNS.md", "Mission model").replace("08_PUZZLE_DESIGNS", "Mission model")
		_card_text(UiDesign.player_words("What the game computed\n" + computation + "\nGame resource units are training rules; the fixture does not validate every game number."), false, true)
		_card_text("Limits\n" + String(card.get("boundary", "")), true)
		_card_text("Source\n" + String(card.get("url", "")) + "\n" + String(card.get("citation", "")) + "\nRetrieved: " + String(card.get("retrieved", "")) + "\nLicence: " + String(card.get("licence", "")))
		var credit := String(card.get("credit_line", ""))
		if not credit.strip_edges().is_empty():
			_card_text("Credit\n" + credit, false, true)
	if value is Dictionary and bool(value.get("return_to_debrief", false)):
		_ending_button("Back to science debrief", "BackToDebrief", func(): open_panel("chapter1_outcome"))
	_source_button("Back to all sources", func(): open_panel("sources", {"ids": []}))

## ---------------------------------------------------------------------------
## Expedition Journal (M1-48/M1-72): five tabs over CampaignKnowledge.journal(), the
## "Previously at Aurora" resume card, and the What now? hint ladder. The
## panel only presents the pure view model; it never computes campaign state.
## ---------------------------------------------------------------------------

func _journal_data(value = null) -> Dictionary:
	var data = value if value != null else _query.get("journal_entries", {})
	return data if data is Dictionary else {}

func _render_journal(value) -> void:
	var journal := _journal_data(value)
	var tabs: Dictionary = journal.get("tabs", {}) if journal.get("tabs", {}) is Dictionary else {}
	if not JOURNAL_TABS.any(func(item): return item.id == _journal_tab):
		_journal_tab = "now"
	_render_journal_tabs(journal)
	var data: Dictionary = tabs.get(_journal_tab, {}) if tabs.get(_journal_tab, {}) is Dictionary else {}
	match _journal_tab:
		"now":
			_render_now_tab(data)
		"evidence":
			_render_evidence_tab(data)
		"garden":
			_render_garden_tab(data)
		"decisions":
			_render_decisions_tab(data)
		"people":
			_render_people_tab(data)
		"science":
			_render_science_tab(data)
		"manual":
			_render_manual_tab()

func _render_manual_tab() -> void:
	_section("ACADEMY MANUAL")
	_body.add_child(_card([
		_label("One plain page for each of the twelve things a junior astronaut learns here: the clips, the real data card and your own decisions. There is no quiz.", 15, IVORY),
	]))
	var open_button := _button("Open the Academy Manual")
	open_button.name = "OpenAcademyManual"
	open_button.pressed.connect(func() -> void: manual_requested.emit())
	_body.add_child(open_button)

func _render_people_tab(data: Dictionary) -> void:
	var people: Array = data.get("people", data.get("entries", [])) if data.get("people", data.get("entries", [])) is Array else []
	_section("PEOPLE AT AURORA")
	if people.is_empty():
		_body.add_child(_card([_label("Crew and mission contacts appear here as you meet them.", 15, MUTED)]))
		return
	for person in people:
		if not person is Dictionary:
			continue
		var rows: Array = []
		var title := _label(String(person.get("title", "")), 18, MUSTARD)
		title.name = "Person_" + String(person.get("id", ""))
		rows.append(title)
		var role_line := "• %s · %s" % [String(person.get("status", "VERIFIED")), String(person.get("role", ""))]
		rows.append(_label(role_line, 12, CYAN))
		if bool(person.get("updated", false)):
			var badge_text := String(person.get("badge", "UPDATED"))
			rows.append(_label(badge_text if not badge_text.is_empty() else "UPDATED", 12, MUSTARD))
		var facts: Array = person.get("facts", []) if person.get("facts", []) is Array else []
		if not facts.is_empty():
			rows.append(_label("WHAT WE KNOW", 11, MUSTARD))
			for fact in facts:
				if fact is Dictionary:
					rows.append(_label("• %s (%s)" % [String(fact.get("text", "")), String(fact.get("source", ""))], 14, IVORY))
		var moments: Array = person.get("moments", []) if person.get("moments", []) is Array else []
		if not moments.is_empty():
			rows.append(_label("MOMENTS", 11, MUSTARD))
			for moment in moments:
				if moment is Dictionary:
					rows.append(_label("• %s — %s" % [String(moment.get("title", "")), String(moment.get("body", ""))], 14, IVORY))
		var role_cards: Array = person.get("role_cards", []) if person.get("role_cards", []) is Array else []
		if not role_cards.is_empty():
			rows.append(_label("SPECIALIST NOTES", 11, MUSTARD))
			for rc in role_cards:
				if rc is Dictionary:
					rows.append(_label("%s · Shift %d · \"%s\"" % [String(rc.get("role", "")), int(rc.get("arrives_shift", 1)), String(rc.get("quote", ""))], 12, CYAN))
					for rf in rc.get("facts", []):
						rows.append(_label("• " + String(rf), 13, IVORY))
		var transcripts: Array = person.get("transcripts", []) if person.get("transcripts", []) is Array else []
		if not transcripts.is_empty():
			rows.append(_label("SPOKEN & STORED LINES", 11, MUSTARD))
			for line in transcripts:
				if line is Dictionary:
					var line_label := _label("[%s · %s] \"%s\"" % [String(line.get("origin_label", "IN ROOM")), String(line.get("scene_title", "")), String(line.get("text", ""))], 13, IVORY)
					line_label.set_meta("verbatim", true)
					rows.append(line_label)
		_body.add_child(_card(rows))

func _render_science_tab(data: Dictionary) -> void:
	var chapters: Array = data.get("chapters", [])
	if chapters.is_empty():
		_card_text("Science clips appear here as you reach their missions.")
	for chapter in chapters:
		_section("Chapter %d" % int(chapter.number))
		_render_watch_buttons(chapter.get("entries", []))
	var chips: Array = data.get("evidence_chips", []) if data.get("evidence_chips", []) is Array else []
	if not chips.is_empty():
		_section("EVIDENCE LABELS")
		for chip in chips:
			if chip is Dictionary:
				_body.add_child(_card([
					_label("• %s · %s" % [String(chip.get("id", "")).to_upper(), String(chip.get("label", ""))], 13, CYAN),
					_label(String(chip.get("meaning", "")), 14, IVORY),
				]))
	var data_cards: Array = data.get("data_cards", []) if data.get("data_cards", []) is Array else []
	if not data_cards.is_empty():
		_section("EARNED DATA CARDS")
		for card in data_cards:
			if not card is Dictionary:
				continue
			var mission_id := String(card.get("mission_id", ""))
			var btn := _button("Data card · %s (%s)" % [String(card.get("title", "")), String(card.get("evidence", "Simulated"))])
			btn.name = "JournalCard_" + mission_id
			btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			btn.pressed.connect(func(): open_panel("data_card", {"mission_id": mission_id}))
			_body.add_child(btn)
	var concepts: Array = data.get("concepts", []) if data.get("concepts", []) is Array else []
	if not concepts.is_empty():
		_section("CONCEPT CARDS")
		for concept in concepts:
			if not concept is Dictionary:
				continue
			var rows: Array = [
				_label(String(concept.get("title", "")), 16, MUSTARD),
				_label("• %s · %s · %s" % [String(concept.get("evidence_label", "Simulated")), String(concept.get("scene_title", "")), String(concept.get("date_label", ""))], 11, CYAN),
				_label(String(concept.get("summary", "")), 14, IVORY),
				_label("Predict: %s\nObserve: %s\nUse it next: %s" % [String(concept.get("predict", "")), String(concept.get("observe", "")), String(concept.get("transfer", ""))], 13, MUTED),
			]
			_body.add_child(_card(rows))

## Left tab column. The open tab is pressed and prefixed with "›", a cue that
## does not depend on colour; counts tell the player where new entries are.
func _render_journal_tabs(journal: Dictionary) -> void:
	for child in _side.get_children():
		_side.remove_child(child)
		child.queue_free()
	_side.show()
	var counts: Dictionary = journal.get("counts", {}) if journal.get("counts", {}) is Dictionary else {}
	var group := ButtonGroup.new()
	var buttons: Array[Button] = []
	for item in JOURNAL_TABS:
		var tab_id := String(item.id)
		var active := tab_id == _journal_tab
		var count := int(counts.get(tab_id, 0))
		var button := _button(("› " if active else "   ") + String(item.label) + (" · %d" % count if count > 0 else ""))
		button.name = "Tab_" + tab_id
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = active
		button.custom_minimum_size = Vector2(SIDE_WIDTH, 44)
		UiDesign.nav_item(button, active)
		button.accessibility_name = "%s tab%s" % [String(item.label).capitalize(), ", open" if active else ""]
		button.pressed.connect(func() -> void: select_journal_tab(tab_id))
		_side.add_child(button)
		buttons.append(button)
	for index in buttons.size():
		var button := buttons[index]
		button.focus_neighbor_top = buttons[(index - 1 + buttons.size()) % buttons.size()].get_path()
		button.focus_neighbor_bottom = buttons[(index + 1) % buttons.size()].get_path()
		button.focus_neighbor_right = _scroll.get_v_scroll_bar().get_path()

func _focus_journal_tab(tab: String) -> void:
	var button := _side.get_node_or_null("Tab_" + tab) as Button
	if button != null and button.is_inside_tree():
		button.grab_focus()

func _render_now_tab(data: Dictionary) -> void:
	var objective: Dictionary = data.get("objective", {}) if data.get("objective", {}) is Dictionary else {}
	_section("OBJECTIVE")
	if objective.is_empty():
		_body.add_child(_card([_label("Your current objective appears here once the expedition begins.", 15, MUTED)]))
	else:
		var complete := String(objective.get("state", "")) == "complete"
		var rows: Array = [
			_label(String(objective.get("scene_title", "")), 20, MUSTARD),
			_label(String(objective.get("objective_text", "")), 17, IVORY),
		]
		var why := String(objective.get("why", ""))
		if not why.is_empty() and why != String(objective.get("objective_text", "")):
			rows.append(_label(why, 14, MUTED))
		rows.append(_label("%s%s · %s" % ["• COMPLETE · " if complete else "", String(objective.get("mission", "")), String(objective.get("date_label", ""))], 12, CYAN if complete else MUTED))
		if complete:
			rows.append(_label("This scene is finished. Advance when the next chapter is ready.", 14, IVORY))
		_body.add_child(_card(rows))
	_section("DONE SO FAR")
	var completed: Array = data.get("completed", []) if data.get("completed", []) is Array else []
	if completed.is_empty():
		_body.add_child(_label("Nothing is finished yet. Start with the objective above.", 14, MUTED))
	for row in completed:
		if row is Dictionary:
			_body.add_child(_card([
				_label("• " + String(row.get("date_label", "")) + " · " + String(row.get("scene_title", "")), 12, CYAN),
				_label(String(row.get("completed_text", "")), 15, IVORY),
			]))
	_render_chapter_pages(data.get("chapter_pages", []) if data.get("chapter_pages", []) is Array else [])
	_render_hint_ladder(data.get("hints", {}) if data.get("hints", {}) is Dictionary else {})

func _render_chapter_pages(pages: Array) -> void:
	if pages.is_empty():
		return
	_section("CHAPTER PAGES")
	for page in pages:
		if not page is Dictionary:
			continue
		var rows: Array = [
			_label(String(page.get("title", "")), 17, MUSTARD),
			_label(String(page.get("subtitle", "")), 13, CYAN),
			_label("WHAT WE DID", 11, MUSTARD),
			_label(String(page.get("what_we_did", "")), 14, IVORY),
			_label("WHAT WE LEARNED", 11, MUSTARD),
		]
		for item in page.get("what_we_learned", []):
			rows.append(_label("• " + String(item), 13, IVORY))
		var questions: Array = page.get("open_questions", []) if page.get("open_questions", []) is Array else []
		if not questions.is_empty():
			rows.append(_label("OPEN QUESTIONS CARRIED FORWARD", 11, MUSTARD))
			for q in questions:
				rows.append(_label("• " + String(q), 13, IVORY))
		var card := _card(rows)
		card.name = "ChapterPage_" + String(page.get("chapter_id", ""))
		_body.add_child(card)

## What now? (doc 22 §2.3): H1 nudge, H2 direction, H3 worked example, one
## level per request. Hints never change an ending, a star or a reward.
func _render_hint_ladder(_hints: Dictionary) -> void:
	_section("WHAT NOW?")
	var reveal := _button("Hint - one step at a time")
	reveal.name = "RevealHint"
	reveal.pressed.connect(request_hint)
	_body.add_child(reveal)
	var how_to := _button("How to")
	how_to.name = "JournalHowTo"
	how_to.pressed.connect(func():
		hint_player.set_settings(_settings)
		hint_player.show_how_to(HowToCard.card_id(_query)))
	_body.add_child(how_to)
	# Journal → How to (doc 25 §7): replay any mechanic met so far, clip included.
	var scene_id := String(_query.get("scene_id", ""))
	var reached := HowToCard.reached(int(scene_id.substr(5, 2)) if scene_id.begins_with("EX-CH") else 1)
	if reached.is_empty():
		return
	_section("HOW TO")
	var replays := HFlowContainer.new()
	replays.name = "HowToReplays"
	replays.add_theme_constant_override("h_separation", 8)
	replays.add_theme_constant_override("v_separation", 8)
	_body.add_child(replays)
	for id in reached:
		var replay := _button(String(HowToCard.lesson(id).get("title", id)))
		replay.name = "HowTo_" + String(id)
		replay.pressed.connect(func():
			hint_player.set_settings(_settings)
			hint_player.show_how_to(String(id)))
		replays.add_child(replay)

func request_hint() -> void:
	hint_player.set_settings(_settings)
	var scene_id := String(_query.get("scene_id", "current"))
	var lesson := HowToCard.lesson(HowToCard.card_id(_query))
	var hints: Dictionary = _query.get("journal_entries", {}).get("tabs", {}).get("now", {}).get("hints", CampaignKnowledge.hints_for_scene(scene_id))
	var levels: Array = hints.get("levels", [])
	if not levels.is_empty() and not String(levels[0]).strip_edges().is_empty():
		lesson.nudge = String(levels[0])
	hint_player.request_hint(scene_id, lesson)

## Observed / Inferred / Unknown (doc 22 T2). Three columns side by side; at
## 150% text the columns stack so every card reflows at full width.
func _render_evidence_tab(data: Dictionary) -> void:
	var columns: Dictionary = data.get("columns", {}) if data.get("columns", {}) is Dictionary else {}
	_body.add_child(_label("Observed is what we saw. Inferred is what we think it means. Unknown is what we still have to ask. A clue moves columns only with a new source.", 13, MUTED))
	var stacked := text_scale() > 1.0
	var holder: BoxContainer = VBoxContainer.new() if stacked else HBoxContainer.new()
	holder.name = "EvidenceColumns"
	holder.add_theme_constant_override("separation", 14)
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for key in ["observed", "inferred", "unknown"]:
		var column := VBoxContainer.new()
		column.name = "Column_" + key
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.size_flags_stretch_ratio = 1.0
		column.add_theme_constant_override("separation", 8)
		var entries: Array = columns.get(key, []) if columns.get(key, []) is Array else []
		column.add_child(_label("• %s · %d" % [key.to_upper(), entries.size()], 13, CYAN))
		if entries.is_empty():
			column.add_child(_label("Nothing here yet.", 13, MUTED))
		for entry in entries:
			if entry is Dictionary:
				column.add_child(_entry_card(entry))
		holder.add_child(column)
	_body.add_child(holder)

## One clue, fact, interpretation, question or operation record. Status and
## type are words, never only colours; links name entries already shown.
func _entry_card(entry: Dictionary) -> PanelContainer:
	var rows: Array = []
	var is_superseded: bool = bool(entry.get("updated", false)) or bool(entry.get("superseded", false))
	var title := _label(String(entry.get("title", "")), 16, MUTED if is_superseded else IVORY)
	title.name = "Title"
	rows.append(title)
	var badge := "%s · %s" % [String(STATUS_BADGES.get(String(entry.get("status", "")), "• " + String(entry.get("status", "")))), String(entry.get("type", "")).replace("_", " ").to_upper()]
	var evidence_label := String(entry.get("evidence_label", ""))
	if not evidence_label.is_empty():
		badge += " · " + evidence_label
	rows.append(_label(badge, 11, CYAN))
	var body := String(entry.get("body", ""))
	if not body.is_empty():
		rows.append(_label(("— " + body + " —") if is_superseded else body, 14, MUTED if is_superseded else IVORY))
	var meta: Array[String] = []
	for key in ["source", "scene_title", "date_label"]:
		var piece := String(entry.get(key, ""))
		if not piece.is_empty():
			meta.append(piece)
	if not meta.is_empty():
		rows.append(_label(" · ".join(meta), 11, MUTED))
	var links: Array = entry.get("links", []) if entry.get("links", []) is Array else []
	if not links.is_empty():
		var names: Array[String] = []
		for link in links:
			if link is Dictionary:
				names.append("› " + String(link.get("title", "")))
		rows.append(_label("Linked: " + "   ".join(names), 12, CYAN))
	if is_superseded:
		rows.append(_label("UPDATED · SUPERSEDED · see " + String(entry.get("superseded_title", "")), 12, MUSTARD))
	return _card(rows)

## Growth Record (doc 24 §6.2): paired photographs or a paired conditions
## table, in the layout chosen at EX-CH01-S04, with the other view one tap away,
## then the life-cycle track with each plant's marker.
func _render_garden_tab(data: Dictionary) -> void:
	var plants: Array = data.get("plants", []) if data.get("plants", []) is Array else []
	var layouts: Array = data.get("layouts", []) if data.get("layouts", []) is Array else []
	var layout := _garden_layout_override if not _garden_layout_override.is_empty() else String(data.get("layout", "paired_photographs"))
	var layout_label := layout.replace("_", " ").to_upper()
	for candidate in layouts:
		if candidate is Dictionary and String(candidate.get("id", "")) == layout:
			layout_label = String(candidate.get("label", layout_label)).to_upper()
	_section("GROWTH RECORD · " + layout_label)
	_body.add_child(_label("Layout chosen at the notebook decision. The other view is one tap away." if bool(data.get("layout_chosen", false)) else "Default layout until the notebook decision is made.", 12, MUTED))
	if layouts.size() > 1:
		var other := ""
		var other_label := ""
		for candidate in layouts:
			if candidate is Dictionary and String(candidate.get("id", "")) != layout:
				other = String(candidate.get("id", ""))
				other_label = String(candidate.get("label", other)).to_upper()
		var toggle := _button("VIEW AS " + other_label)
		toggle.name = "GrowthLayoutToggle"
		toggle.pressed.connect(func() -> void:
			_garden_layout_override = other
			_render_active_panel()
			var again := _body.get_node_or_null("GrowthLayoutToggle") as Button
			if again != null:
				again.grab_focus()
		)
		_body.add_child(toggle)
	var records: Array = data.get("records", []) if data.get("records", []) is Array else []
	if plants.is_empty():
		_body.add_child(_card([_label("The Growth Record opens when Alo and Tara are planted.", 15, MUTED)]))
	elif layout == "paired_conditions":
		_render_growth_table(plants, records)
	else:
		_render_growth_photos(plants, records)
	if not plants.is_empty():
		_render_lifecycle_track(data.get("lifecycle", {}) if data.get("lifecycle", {}) is Dictionary else {}, plants)
	for line in data.get("ledger", []):
		_body.add_child(_label(String(line), 13, MUTED))

func _render_growth_photos(plants: Array, records: Array) -> void:
	if records.is_empty():
		_body.add_child(_label("No dated photograph yet.", 14, MUTED))
	var stacked := text_scale() > 1.0
	for record in records:
		if not record is Dictionary:
			continue
		_body.add_child(_label(String(record.get("date_label", "")), 13, CYAN))
		var strip: BoxContainer = VBoxContainer.new() if stacked else HBoxContainer.new()
		strip.add_theme_constant_override("separation", 12)
		strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var frames: Dictionary = record.get("frames", {}) if record.get("frames", {}) is Dictionary else {}
		for plant in plants:
			if not plant is Dictionary:
				continue
			var frame = frames.get(String(plant.get("id", "")), {})
			var tile := _photo_tile(String(plant.get("name", "")), String(frame.get("stage_id", "")).replace("_", " ") if frame is Dictionary and not frame.is_empty() else "")
			var caption := _label(String(frame.get("body", "")) if frame is Dictionary and not frame.is_empty() else "No photograph that day.", 13, IVORY if frame is Dictionary and not frame.is_empty() else MUTED)
			var card := _card([tile, _label("%s · %s" % [String(plant.get("name", "")).to_upper(), String(plant.get("chamber", ""))], 11, CYAN), caption])
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			card.size_flags_stretch_ratio = 1.0
			strip.add_child(card)
		_body.add_child(strip)

## A framed stage tile stands in for the chamber camera image.
func _photo_tile(plant_name: String, stage: String) -> PanelContainer:
	var tile := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.04, 0.08, 1.0)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.32, 0.52, 0.72, 0.6)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	tile.add_theme_stylebox_override("panel", style)
	tile.custom_minimum_size = Vector2(0, 64)
	var text := _label(("%s · %s" % [plant_name.to_upper(), stage.to_upper()]) if not stage.is_empty() else "NO IMAGE", 15, MUSTARD if not stage.is_empty() else MUTED)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tile.add_child(text)
	return tile

func _render_growth_table(plants: Array, records: Array) -> void:
	if records.is_empty():
		_body.add_child(_label("No dated row yet.", 14, MUTED))
		return
	var grid := GridContainer.new()
	grid.name = "GrowthTable"
	grid.columns = 1 + plants.size()
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(_label("DATE", 12, CYAN))
	for plant in plants:
		var header := _label("%s · %s" % [String(plant.get("name", "")).to_upper(), String(plant.get("chamber", ""))], 12, CYAN)
		header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(header)
	for record in records:
		if not record is Dictionary:
			continue
		var date := _label(String(record.get("date_label", "")), 13, IVORY)
		date.custom_minimum_size.x = 120
		grid.add_child(date)
		var frames: Dictionary = record.get("frames", {}) if record.get("frames", {}) is Dictionary else {}
		for plant in plants:
			var frame = frames.get(String(plant.get("id", "")), {})
			var has_frame: bool = frame is Dictionary and not frame.is_empty()
			var cell := _label(("%s · %s" % [String(frame.get("stage_id", "")).replace("_", " ").to_upper(), String(frame.get("body", ""))]) if has_frame else "No row that day.", 13, IVORY if has_frame else MUTED)
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			grid.add_child(cell)
	_body.add_child(grid)

## Seed → sprout → bud → flower → pods → ripe seeds, with each plant's name
## under its current stage (doc 24 §3.8: the far end reads "seeds" from day one).
func _render_lifecycle_track(lifecycle: Dictionary, plants: Array) -> void:
	_section("LIFE CYCLE")
	var stages: Array = lifecycle.get("stages", []) if lifecycle.get("stages", []) is Array else []
	var markers: Dictionary = lifecycle.get("markers", {}) if lifecycle.get("markers", {}) is Dictionary else {}
	var track := HFlowContainer.new()
	track.name = "LifecycleTrack"
	track.add_theme_constant_override("h_separation", 6)
	track.add_theme_constant_override("v_separation", 6)
	track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for index in stages.size():
		var stage: Dictionary = stages[index] if stages[index] is Dictionary else {}
		var names: Array[String] = []
		for plant in plants:
			if plant is Dictionary and int(markers.get(String(plant.get("id", "")), -1)) == index:
				names.append(String(plant.get("name", "")).to_upper())
		var cell := VBoxContainer.new()
		cell.custom_minimum_size.x = 150
		cell.add_theme_constant_override("separation", 2)
		var head := _label("%d · %s" % [index + 1, String(stage.get("label", ""))], 13, IVORY)
		head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(head)
		var marker := _label("› " + " + ".join(names) + " ‹" if not names.is_empty() else "·", 13, MUSTARD if not names.is_empty() else MUTED)
		marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(marker)
		track.add_child(_card([cell]))
	_body.add_child(track)
	for plant in plants:
		if not plant is Dictionary:
			continue
		var caption := String(plant.get("caption", ""))
		if not bool(plant.get("alive", true)):
			caption += " Her record is kept as it was written."
		_body.add_child(_label(caption, 13, MUTED))

## What we chose / what it did / where it showed up again (doc 24 §6.2). A
## "recorded" line means this is written down, never that it will matter.
func _render_decisions_tab(data: Dictionary) -> void:
	var outcome: Dictionary = data.get("outcome", {}) if data.get("outcome", {}) is Dictionary else {}
	if not outcome.is_empty():
		_section("NIGHT ONE OUTCOME")
		_body.add_child(_card([
			_label(String(outcome.get("title", "")), 18, MUSTARD),
			_label(String(outcome.get("summary", "")), 15, IVORY),
			_label("• RECORDED · " + String(outcome.get("date_label", "")), 11, CYAN),
		]))
	_section("DECISIONS")
	var entries: Array = data.get("entries", []) if data.get("entries", []) is Array else []
	if entries.is_empty():
		_body.add_child(_card([_label("Confirm a decision review to record your first choice. Previews are never recorded.", 15, MUTED)]))
	for entry in entries:
		if not entry is Dictionary:
			continue
		var rows: Array = [
			_label(String(entry.get("title", "")), 17, IVORY),
			_label("• RECORDED · %s · %s" % [String(entry.get("recorded_label", entry.get("date_label", ""))), String(entry.get("scene_title", ""))], 11, CYAN),
		]
		var prompt := String(entry.get("prompt", ""))
		if not prompt.is_empty():
			rows.append(_label(prompt, 13, MUTED))
		rows.append(_label("WHAT WE CHOSE", 11, MUSTARD))
		rows.append(_label(String(entry.get("chose", "")), 15, IVORY))
		rows.append(_label("WHAT IT DID", 11, MUSTARD))
		var did := String(entry.get("did", ""))
		var body := String(entry.get("body", ""))
		rows.append(_label((did + "\n" + body).strip_edges() if not did.is_empty() else body, 14, IVORY))
		var echoes: Array = entry.get("echoes", []) if entry.get("echoes", []) is Array else []
		if not echoes.is_empty():
			rows.append(_label("WHERE IT SHOWED UP AGAIN", 11, MUSTARD))
			for echo in echoes:
				if echo is Dictionary:
					rows.append(_label("%s · %s" % [String(echo.get("scene_title", "")), String(echo.get("text", ""))], 14, IVORY))
		_body.add_child(_card(rows))

## "Previously at Aurora" (doc 24 §6.6): at most six lines from the snapshot.
func _render_resume_card(journal: Dictionary, with_header: bool = true) -> void:
	var lines: Array = journal.get("resume", []) if journal.get("resume", []) is Array else []
	var rows: Array = []
	if with_header:
		rows.append(_label("PREVIOUSLY AT AURORA", 13, MUSTARD))
	if lines.is_empty():
		rows.append(_label("No saved progress to summarise yet.", 14, MUTED))
	for index in mini(lines.size(), 6):
		var line := _label(String(lines[index]), 16, IVORY)
		line.name = "ResumeLine%d" % (index + 1)
		rows.append(line)
	var card := _card(rows)
	card.name = "ResumeCard"
	_body.add_child(card)

func _render_resume_panel(value) -> void:
	var journal := _journal_data(value)
	_render_resume_card(journal, false)
	_source_button("OPEN THE JOURNAL · NOW", func(): open_journal("now"))

func _section(text: String) -> void:
	var header := _label(text, 13, MUSTARD)
	header.name = "Section_" + text.to_lower().replace(" ", "_")
	_body.add_child(header)

## Journal and resume text: written in player words at the source (journal_text.json); no automatic swaps.
func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func _card(rows: Array) -> PanelContainer:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.10, 0.17, 0.92)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.26, 0.40, 0.62, 0.55)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", style)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for row in rows:
		if row is Control:
			column.add_child(row)
	card.add_child(column)
	return card

func _render_outcome(value) -> void:
	var data: Dictionary = value if value is Dictionary else {}
	_card_text(UiDesign.player_words(String(data.get("result", UiDesign.text().get("hud", {}).get("no_result", "Nothing to show yet.")))), true)
	var fields: Dictionary = UiDesign.text().get("station", {}).get("fields", {})
	for change in data.get("changes", []):
		if not change is Dictionary:
			continue
		var key := String(change.get("field", "")).trim_prefix("resources.")
		if fields.has(key):
			var unit := String(fields[key].get("unit", ""))
			_card_text("%s: %s → %s%s" % [String(fields[key].get("word", key)), _display_value(change.get("from")), _display_value(change.get("to")), (" " + unit) if not unit.is_empty() else ""])
	for note in data.get("notes", []):
		_card_text(UiDesign.player_words(str(note)))

## The shared shell supplies scrolling, focus, pause, large text and source cards.
## These controls are created only when the player opens the ending review.
func open_chapter1_outcome(data: Dictionary, page: String = "summary") -> bool:
	_ending_page = page
	_replay_index = 0
	_lesson_index = 0
	var opened := open_panel("chapter1_outcome", data)
	_scroll.scroll_vertical = 0
	return opened

func _ending_button(text: String, node_name: String, action: Callable, disabled: bool = false) -> void:
	var button := _button(text)
	button.name = node_name
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.disabled = disabled
	button.pressed.connect(action)
	_body.add_child(button)

func _ending_go(page: String, focus_name: String) -> void:
	_ending_page = page
	_render_active_panel()
	_scroll.scroll_vertical = 0
	var focus := _body.find_child(focus_name, true, false) as Control
	if focus != null:
		focus.grab_focus()

func _render_chapter1_outcome(value) -> void:
	var data: Dictionary = value if value is Dictionary else {}
	if data.is_empty():
		_card_text("Finish the night to review its results.")
		return
	_title.text = MissionTablePanel.display_text(String(data.get("title", "First light")))
	var replay: Array = data.get("replay", [])
	if _ending_page == "summary":
		if bool(data.get("trainer", false)):
			var rating := UiDesign.label("%d of 3 stars" % int(data.star_count), "heading", "accent")
			rating.name = "TrainerStarRating"
			_body.add_child(rating)
			var save_status := UiDesign.label(String(data.get("trainer_save_status", "")), "body", "accent")
			save_status.name = "TrainerSaveStatus"
			_body.add_child(save_status)
		_card_text(String(data.get("summary", "")), true)
		var resources: Dictionary = data.resources
		_card_text("Crew \u00b7 " + ("The night is complete and the crew is safe." if data.safe_ending or data.ending == "ALO_LOST" else "Flight rules stopped this attempt at the safety limit."))
		_card_text("Base \u00b7 " + Debrief.readings(resources, ["E", "A", "C", "R"]))
		_card_text("Alo \u00b7 " + ("Alive. " if int(resources.H) > 0 else "Lost in this attempt. ") + Debrief.readings(resources, ["H"]))
		var stars: Dictionary = data.stars
		for item in [["safe_exposure", "Training radiation dose 3 or under"], ["no_blackout", "No blackout"], ["alo_alive", "Alo alive"]]:
			_card_text(("Met: " if stars.get(item[0], false) else "Not met: ") + item[1])
		_card_text(String(UiDesign.text().chapter1_debrief.golden_requirement))
		var reward := Chapter1FeedbackScript.outcome_reward_card(stars, int(resources.get("H", 0)), int(data.get("retry_shift", 5)), String(data.get("ending", "")))
		var posture := Chapter1FeedbackScript.alo_posture(int(resources.get("H", 0)), int(resources.get("W", 0)), 7 if bool(data.get("safe_ending", false)) else int(data.get("retry_shift", 1)), bool(data.get("safe_ending", false)))
		_card_text("%s\n%s\n%s" % [String(reward.get("title", "")), String(reward.get("celebration", "")), String(reward.get("retry_prompt", ""))])
		_card_text("Alo now: %s" % String(posture.get("plain", posture.get("posture_description", ""))))
		_ending_button("Review decisions \u00b7 shift by shift", "ReviewDecisions", func(): _ending_go("replay", "ReplayNext"), replay.is_empty())
		if replay.is_empty():
			_card_text("This older checkpoint has no shift receipts to replay.")
		_ending_actions(data)
	elif _ending_page == "replay":
		if replay.is_empty():
			_card_text("No shift receipts are available for this checkpoint.")
			_ending_button("Back to the result", "EndingSummary", func(): _ending_go("summary", "ReviewDecisions"))
			return
		_replay_index = clampi(_replay_index, 0, replay.size() - 1)
		var row: Dictionary = replay[_replay_index]
		_card_text("Shift %d of %d \u00b7 your decision" % [int(row.shift), replay.size()], true)
		var choice := UiDesign.label(String(row.choice), "body")
		choice.name = "ReplayChoice"
		_body.add_child(choice)
		_card_text("Replayed forecast\n" + Debrief.readings(row.forecast))
		_card_text("Recomputed from this shift's recorded starting resources and choices; the original forecast was not saved.")
		_card_text("What happened\n" + Debrief.readings(row.actual.after))
		_card_text("Why\n" + String(row.why))
		_ending_button("Previous shift" if _replay_index > 0 else "Back to the result", "ReplayPrevious", func():
			if _replay_index > 0:
				_replay_index -= 1
				_ending_go("replay", "ReplayPrevious")
			else:
				_ending_go("summary", "ReviewDecisions"))
		_ending_button("Next shift" if _replay_index < replay.size() - 1 else "Science debrief", "ReplayNext", func():
			if _replay_index < replay.size() - 1:
				_replay_index += 1
				_ending_go("replay", "ReplayNext")
			else:
				_ending_go("debrief", "Answer0"))
	else:
		var lesson: Dictionary = data.lessons[_lesson_index]
		_card_text("What you learned \u00b7 %d of 3\n%s" % [_lesson_index + 1, String(lesson.title)], true)
		_card_text("Predict\n" + String(lesson.question))
		_card_text("What happened\n" + Debrief.readings(data.resources, lesson.fields))
		_card_text("Why\n" + String(lesson.why))
		var question := UiDesign.label("Check your understanding \u00b7 " + String(lesson.question), "body", "accent")
		question.name = "DebriefQuestion"
		_body.add_child(question)
		for index in lesson.options.size():
			_ending_button(String(lesson.options[index]), "Answer%d" % index, func():
				_ending_answers[_lesson_index] = index
				_ending_go("debrief", "Answer%d" % index))
		var feedback := UiDesign.label("", "body")
		feedback.name = "AnswerFeedback"
		if _ending_answers.has(_lesson_index):
			feedback.text = ("Yes. " if int(_ending_answers[_lesson_index]) == int(lesson.correct) else "Try this explanation. ") + String(lesson.why)
		_body.add_child(feedback)
		_ending_button("NASA Data Card \u00b7 " + String(science.card(lesson.source).get("title", "Evidence")), "DebriefSource", func(): open_panel("data_card", {"source_id": lesson.source, "return_to_debrief": true}))
		_ending_button("Back to decision replay", "DebriefReplay", func(): _ending_go("replay", "ReplayNext"))
		if _lesson_index < data.lessons.size() - 1:
			_ending_button("Next thing learned", "DebriefNext", func():
				_lesson_index += 1
				_ending_go("debrief", "Answer0"))
		else:
			_ending_actions(data)

func _ending_actions(data: Dictionary) -> void:
	_ending_button("Retry from shift %d checkpoint" % int(data.retry_shift), "EndingRetry", func():
		ending_retry_requested.emit(), not bool(data.can_retry))
	if bool(data.get("trainer", false)):
		_ending_button("Back to training scenarios", "TrainerReportBack", func(): ending_continue_requested.emit())
		return
	if bool(data.safe_ending):
		var can_continue := bool(data.get("can_continue", false))
		_ending_button("Continue the story", "EndingContinue", func(): ending_continue_requested.emit(), not can_continue)
		if not can_continue:
			var reason := UiDesign.label(String(data.get("continue_reason", "Close this review and finish the jobs here to continue.")), "body", "accent")
			reason.name = "EndingContinueReason"
			_body.add_child(reason)
	else:
		_card_text("Review what happened, then retry the checkpoint to continue this expedition.")

func _render_credits(value = {}) -> void:
	var credits_script := preload("res://scripts/ui/credits_panel.gd")
	var credits := credits_script.new()
	credits.embedded = true
	credits.settings = accessibility_settings()
	_body.add_child(credits)
	credits.populate_into(_body)
	credits.return_to_garden_requested.connect(close_panel)
