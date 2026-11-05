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

const ScienceScript = preload("res://scripts/science/science_data.gd")
const ChartScript = preload("res://scripts/ui/data_chart.gd")
var science = ScienceScript.new()

const INK := Color("#05060A")
const NAVY := Color("#1F2A44")
const IVORY := Color("#ECEEF0")
const MUTED := Color("#A8B4C8")
const MUSTARD := Color("#F2C230")
const CYAN := Color("#20B8C9")
const GREEN := Color("#4CAF50")

const PANEL_IDS := [
	"objective",
	"dialogue_captions",
	"journal_discovery",
	"mission_table",
	"puzzle",
	"outcome",
	"pause",
	"settings_accessibility",
	"credits",
	"sources",
	"data_card",
	"what_now",
]

## Titles and purpose lines are player words (doc 25 §1.1); ids stay as they are.
const PANEL_DEFINITIONS := {
	"sources": {"title": "Sources", "query_key": "sources", "description": "The NASA and partner data behind the game. Open one to see what it means for Aurora."},
	"data_card": {"title": "Data card", "query_key": "data_card", "description": "What was measured, what the game worked out, and where the limits are."},
	"objective": {"title": "Goal", "query_key": "objective", "description": "What to do next and why."},
	"dialogue_captions": {"title": "Dialogue", "query_key": "dialogue_lines", "description": "Every line of this scene, with who said it."},
	"journal_discovery": {"title": "Journal", "query_key": "journal_entries", "description": "What the crew has found so far."},
	"mission_table": {"title": "Mission Table", "query_key": "mission_table", "description": "The night plan and its forecast."},
	"puzzle": {"title": "Your choice", "query_key": "puzzle", "description": "Try an option to see what it would mean."},
	"outcome": {"title": "Last result", "query_key": "outcome", "description": "What the last job changed."},
	"pause": {"title": "Paused", "query_key": "pause", "description": "The clock stops while you read and plan."},
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
var _builders: Dictionary = {}
var _pause_actions: Array = []
var _tween: Tween

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()

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
	return _settings.duplicate(true)

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
	return true

func close_panel() -> void:
	if _active_panel.is_empty():
		return
	var closed := _active_panel
	var return_focus := _last_focus
	_last_focus = null
	_active_panel = ""
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
	_overlay = ColorRect.new()
	_overlay.color = Color(0.0, 0.01, 0.03, 0.74)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var shader := Shader.new()
	shader.code = BLUR_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	_overlay.material = material
	_overlay.hide()
	add_child(_overlay)
	_panel = _panel_style(Vector2(780, 540), UiDesign.colour("glass_edge", Color(1, 1, 1, 0.18)))
	_panel.minimum_size_changed.connect(_layout_panel.call_deferred)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.hide()
	add_child(_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 20)
	_panel.add_child(margin)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 10)
	margin.add_child(page)
	_title = UiDesign.label("", "heading", "accent")
	page.add_child(_title)
	_description = UiDesign.label("", "caption", "muted")
	page.add_child(_description)
	var divider := HSeparator.new()
	divider.modulate = Color(1, 1, 1, 0.18)
	page.add_child(divider)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	scroll.get_v_scroll_bar().focus_mode = Control.FOCUS_ALL
	page.add_child(scroll)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 9)
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_body)
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation", 8)
	page.add_child(footer)
	var hud_words: Dictionary = UiDesign.text().get("hud", {})
	_close_button = _button("%s · %s" % [String(hud_words.get("close", "Close")), String(hud_words.get("close_key", "Esc"))])
	_close_button.pressed.connect(close_panel)
	footer.add_child(_close_button)

func _animate_open() -> void:
	var seconds := presentation_transition_seconds()
	if seconds <= 0.0 or not is_inside_tree():
		_panel.modulate.a = 1.0
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_panel.modulate.a = 0.0
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(_panel, "modulate:a", 1.0, seconds)

## Hands body children an owner wants back (meta "lla_keep") to that owner
## instead of freeing them with the rest of the body.
func _release_kept_children() -> void:
	for child in _body.get_children():
		if child.has_meta("lla_keep"):
			_body.remove_child(child)
			var home = child.get_meta("lla_home", null)
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
	elif _active_panel == "dialogue_captions":
		_render_dialogue(value)
	elif _active_panel == "puzzle":
		_render_puzzle(value)
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
	else:
		_render_data(value)
		if _active_panel in ["outcome", "mission_table"]:
			_render_puzzle_sources(_query.get("source_puzzle_ids", []))
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
	var width := minf(780, view.x - margin * 2)
	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_panel.position = Vector2((view.x - width) * 0.5, margin)
	_panel.size = Vector2(width, maxf(300, view.y - margin * 2))

func _render_data(value) -> void:
	var body := UiDesign.label(_display_value(value), "body")
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_child(body)

func _render_pause() -> void:
	var words: Dictionary = UiDesign.text().get("hud", {})
	var resume := _button(String(words.get("resume", "Resume")))
	resume.name = "Resume"
	resume.pressed.connect(close_panel)
	_body.add_child(resume)
	for raw in _pause_actions:
		if not raw is Dictionary:
			continue
		var entry: Dictionary = raw
		var button := _button(String(entry.get("label", "")))
		button.name = String(entry.get("name", String(entry.get("label", "")).to_pascal_case()))
		var action: Callable = entry.get("action", Callable())
		if action.is_valid():
			button.pressed.connect(action)
		_body.add_child(button)

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
	var notes := UiDesign.label(
		"Captions keep every line readable when a voice is missing, and caption the sounds that matter.\n"
		+ ("Timer-free: nothing needs a quick reaction.\n" if is_timer_free() else "Standard timing: timed tasks show their clock.\n")
		+ ("Reduced motion: panels change instantly.\n" if is_reduced_motion() else "Reduced motion is available here.\n")
		+ "None of these skip a safety check.",
		"caption", "muted")
	_body.add_child(notes)

func _set_settings(settings: Dictionary, emit_change: bool) -> void:
	var focus_key := ""
	if emit_change and is_inside_tree():
		var focused := get_viewport().gui_get_focus_owner()
		if focused is CheckButton and _body.is_ancestor_of(focused):
			focus_key = String(focused.name)
	for key in _settings.keys():
		if settings.has(key):
			_settings[key] = bool(settings[key])
	_apply_accessibility()
	if emit_change:
		var copy := _settings.duplicate(true)
		accessibility_changed.emit(copy)
		emit_command("set_accessibility", "accessibility", copy, "accessibility")
		if _active_panel == "settings_accessibility":
			_render_active_panel()
			var next_focus := _body.get_node_or_null(focus_key) as Control if not focus_key.is_empty() else null
			if next_focus != null:
				next_focus.grab_focus()

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
	if event.is_action_pressed("ui_cancel") and not event.is_echo() and not _active_panel.is_empty():
		close_panel()
		get_viewport().set_input_as_handled()

func _source_button(text: String, action: Callable) -> void:
	var button := _button(text)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(action)
	_body.add_child(button)

func _render_sources() -> void:
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

func _card_text(text: String, emphasis: bool = false) -> void:
	var label := UiDesign.label(text, "body", "accent" if emphasis else "ivory")
	_body.add_child(label)

func _render_card(value) -> void:
	var id := String(value.get("source_id", "")) if value is Dictionary else ""
	var card: Dictionary = science.card(id)
	_card_text("What this means for Aurora\n" + String(card.get("takeaway", "")), true)
	if not bool(card.get("pending", true)):
		var visual: Dictionary = card.get("visual", {})
		var visual_title := String(visual.get("label", "")).replace("_", " ").capitalize()
		if visual.get("kind") != "line":
			visual_title += " · %s %s" % [str(visual.get("values", [0])[0]), visual.get("unit", "")]
		_card_text(visual_title, true)
		var chart := ChartScript.new()
		chart.series = visual
		_body.add_child(chart)
		var values: Array = visual.get("values", [])
		_card_text(String(visual.get("label", "")).replace("_", " ") + " · " + String(visual.get("unit", "")) + "\n" + ("First %s · last %s · min %s · max %s\n%s → %s" % [values[0], values[-1], values.min(), values.max(), visual.get("start", ""), visual.get("end", "")] if values.size() > 1 else str(values[0])) + "\n" + String(visual.get("axis", "")))
		_card_text(String(card.get("title", "")), true)
		_card_text("Evidence · " + String(card.get("evidence_label", "")) + "\n" + String(card.get("agency", "")) + "\nDataset: " + String(card.get("dataset_id", "")))
		_card_text("What was measured or supplied\n" + ScienceScript.describe(card.get("fields_used", [])) + "\n" + ScienceScript.describe(card.get("values", {})))
		_card_text("What the game computed\n" + ScienceScript.describe(card.get("derived", [])) + "\nGame resource units are training rules; the fixture does not validate every game number.")
		_card_text("Limits\n" + String(card.get("boundary", "")), true)
		_card_text("Source\n" + String(card.get("url", "")) + "\n" + String(card.get("citation", "")) + "\nRetrieved: " + String(card.get("retrieved", "")) + "\nLicence: " + String(card.get("licence", "")))
	_source_button("Back to all sources", func(): open_panel("sources", {"ids": []}))

func _render_journal(value) -> void:
	if not value is Array or value.is_empty():
		_card_text("New discoveries appear here after you finish the jobs that find them.")
		return
	for entry in value:
		if not entry is Dictionary:
			continue
		_card_text(String(entry.get("title", "Record")), true)
		_card_text(String(entry.get("evidence_label", "Recorded observation")))
		for observation in entry.get("observations", []):
			_card_text(String(observation.get("text", "")))

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
