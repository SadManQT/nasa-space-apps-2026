extends Control
class_name CampaignPanels

## Shared, data-driven presentation panels.  This node reads a primitive query
## and emits primitive commands; it never owns campaign arithmetic or mutates a
## director/state object.

signal command_emitted(command: Dictionary)
signal panel_opened(panel_id: String)
signal panel_closed(panel_id: String)
signal accessibility_changed(settings: Dictionary)
signal outcome_retry_requested
signal outcome_continue_requested

const ScienceScript = preload("res://scripts/science/science_data.gd")
const ChartScript = preload("res://scripts/ui/data_chart.gd")
const OutcomeScene = preload("res://scenes/ui/chapter1_outcome.tscn")
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
]

const PANEL_DEFINITIONS := {
	"sources": {"title": "JOURNAL / SOURCES", "query_key": "sources", "description": "Offline NASA and partner evidence. Open a dataset to see what it means for Aurora."},
	"data_card": {"title": "DATA CARD", "query_key": "data_card", "description": "Observed evidence, computations and training assumptions are labelled separately."},
	"objective": {"title": "OBJECTIVE", "query_key": "objective", "description": "Current objective and evidence-backed next step."},
	"dialogue_captions": {"title": "DIALOGUE / CAPTIONS", "query_key": "dialogue_lines", "description": "Exact lines with speaker and origin labels."},
	"journal_discovery": {"title": "JOURNAL / DISCOVERY", "query_key": "journal_entries", "description": "Acquired evidence only; unrevealed knowledge stays hidden."},
	"mission_table": {"title": "MISSION TABLE", "query_key": "mission_table", "description": "Read-only mission plan and supplied forecast."},
	"puzzle": {"title": "PUZZLE", "query_key": "puzzle", "description": "A named interaction can preview or submit an explicit command."},
	"outcome": {"title": "OUTCOME", "query_key": "outcome", "description": "Review the changed readings, reserves and recorded evidence."},
	"pause": {"title": "PAUSE", "query_key": "pause", "description": "Reading and planning do not advance scenario time."},
	"settings_accessibility": {"title": "SETTINGS / ACCESSIBILITY", "query_key": "accessibility", "description": "Captions, large text, reduced motion and timer-free labels."},
	"credits": {"title": "CREDITS", "query_key": "credits", "description": "Project, source and media disclosure."},
}

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
var _outcome_navigation := {}
var _source_from_outcome := false
var _outcome_scroll_position := 0

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
	## Panels are currently presented synchronously. This contract lets a
	## future animated shell honor reduced motion without changing state flow.
	return 0.0 if is_reduced_motion() else 0.15

func open_panel(panel_id: String, data: Dictionary = {}) -> bool:
	if not PANEL_DEFINITIONS.has(panel_id):
		return false
	if panel_id == "outcome" and _active_panel not in ["data_card", "sources"]:
		_outcome_navigation = {}
		_source_from_outcome = false
		_outcome_scroll_position = 0
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
	_active_panel = panel_id
	_render_active_panel()
	if _body != null:
		(_body.get_parent() as ScrollContainer).set_deferred("scroll_vertical", _outcome_scroll_position if panel_id == "outcome" and _source_from_outcome else 0)
	_overlay.show()
	_panel.show()
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
	_overlay.hide()
	add_child(_overlay)
	_panel = _panel_style(Vector2(780, 540), Color(0.13, 0.72, 0.78, 0.84))
	_panel.minimum_size_changed.connect(_layout_panel.call_deferred)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.hide()
	add_child(_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_bottom", 24)
	_panel.add_child(margin)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 12)
	margin.add_child(page)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 26)
	_title.add_theme_color_override("font_color", MUSTARD)
	page.add_child(_title)
	_description = Label.new()
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description.add_theme_font_size_override("font_size", 14)
	_description.add_theme_color_override("font_color", CYAN)
	page.add_child(_description)
	var divider := HSeparator.new()
	divider.modulate = Color(0.32, 0.52, 0.72, 0.7)
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
	_close_button = _button("CLOSE PANEL")
	_close_button.pressed.connect(close_panel)
	footer.add_child(_close_button)

func _render_active_panel() -> void:
	if _active_panel.is_empty() or not PANEL_DEFINITIONS.has(_active_panel):
		return
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	var definition: Dictionary = PANEL_DEFINITIONS[_active_panel]
	_title.text = String(definition.get("title", _active_panel.to_upper()))
	_description.text = String(definition.get("description", ""))
	var query_key := String(definition.get("query_key", ""))
	var value = _query.get(query_key, {})
	if _active_panel == "settings_accessibility":
		_render_settings()
	elif _active_panel == "pause":
		_render_data("The expedition is paused. Close this panel to resume.")
	elif _active_panel == "dialogue_captions":
		_render_dialogue(value)
	elif _active_panel == "puzzle":
		_render_puzzle(value)
	elif _active_panel == "outcome":
		_render_outcome(value)
		if not value is Dictionary or not value.get("chapter1", false):
			_render_puzzle_sources(_query.get("source_puzzle_ids", []))
	elif _active_panel == "journal_discovery":
		_render_journal(value)
		_source_button("SOURCES · ALL DATASETS", func(): open_panel("sources", {"ids": []}))
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

func set_content_top(value: float) -> void:
	_safe_top = value
	_layout_panel()

func _layout_panel() -> void:
	if _panel == null or not is_inside_tree():
		return
	var view := get_viewport_rect().size
	var closure: bool = (_active_panel == "outcome" and bool(_query.get("outcome", {}).get("chapter1", false))) or (_source_from_outcome and _active_panel in ["data_card", "sources"])
	if _safe_top <= 0 and not closure:
		return
	var top := 20.0 if closure else _safe_top
	var width := minf(960 if closure else 780, view.x - 32)
	_panel.custom_minimum_size = Vector2.ZERO
	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_panel.position = Vector2((view.x - width) * 0.5, top)
	_panel.size = Vector2(width, maxf(300, view.y - top - 20))

func _render_data(value) -> void:
	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_font_size_override("font_size", 18 if bool(_settings.get("large_text", false)) else 16)
	body.add_theme_color_override("font_color", IVORY)
	body.text = _display_value(value)
	_body.add_child(body)
	if _active_panel == "pause":
		var note := Label.new()
		note.text = "CAPTIONS ON BY DEFAULT  ·  TIMER-FREE LABELS  ·  REDUCED MOTION AVAILABLE"
		note.add_theme_color_override("font_color", MUTED)
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_body.add_child(note)

func _render_dialogue(value) -> void:
	if not captions_visible():
		_render_data("Captions are hidden. Enable Captions on to read dialogue.")
		return
	var lines: Array = value if value is Array else []
	if lines.is_empty():
		_render_data("No acquired dialogue is ready.")
		return
	for raw_line in lines:
		if not raw_line is Dictionary:
			continue
		var line: Dictionary = raw_line
		var label := Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 18 if bool(_settings.get("large_text", false)) else 15)
		label.add_theme_color_override("font_color", IVORY)
		label.text = "%s  ·  %s\n%s" % [String(line.get("speaker", "")), String(line.get("origin_label", "")), String(line.get("text", ""))]
		_body.add_child(label)
		var acknowledge := _button("ACKNOWLEDGE LINE  ·  " + String(line.get("id", "")))
		acknowledge.pressed.connect(func() -> void:
			emit_command("acknowledge_line", String(line.get("id", "")), {"line_id": String(line.get("id", "")), "dialogue_only": true})
		)
		_body.add_child(acknowledge)

func _render_puzzle(value) -> void:
	var data: Dictionary = value if value is Dictionary else {}
	if data.has("choice_id"):
		_render_decision_review(data)
		return
	var prompt := Label.new()
	prompt.text = String(data.get("prompt", "Select a visible operation to request a preview."))
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt.add_theme_font_size_override("font_size", 18 if bool(_settings.get("large_text", false)) else 16)
	prompt.add_theme_color_override("font_color", IVORY)
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
	var forecast := Label.new()
	forecast.text = "FORECAST\n" + String(data.get("forecast", "The state owner supplies the forecast."))
	forecast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	forecast.add_theme_color_override("font_color", MUTED)
	_body.add_child(forecast)

func _render_decision_review(data: Dictionary) -> void:
	_title.text = "DECISION REVIEW"
	_description.text = "Preview an option, then confirm it for your expedition record."
	_card_text(String(data.get("prompt", "")))
	var recorded := String(data.get("recorded_option_id", ""))
	var locked := bool(data.get("locked", false))
	var selected := {"option_id": recorded}
	var group := ButtonGroup.new()
	var forecast := Label.new()
	forecast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	forecast.add_theme_color_override("font_color", MUTED)
	forecast.text = "Select an option to preview its consequence."
	var confirm := _button("CONFIRM CHOICE")
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
			forecast.text = "Preview: %s\n%s" % [label, consequence]
			confirm.disabled = option_id == recorded
			emit_command("preview_puzzle", option_id, {"choice_id": data.choice_id, "option_id": option_id})
		)
		_body.add_child(button)
	_body.add_child(forecast)
	_card_text("The scene exit has passed. This choice is locked." if locked else "Your confirmed choice can be revised until you pass this scene's exit. Physical operations keep their own safety checks.")
	confirm.pressed.connect(func() -> void:
		# Closing the reading panel resumes the director before the command is
		# committed. Pausing remains authoritative for every other operation.
		close_panel()
		emit_command("record_choice", String(data.choice_id), {"choice_id": data.choice_id, "option_id": selected.option_id})
	)
	_body.add_child(confirm)

func _render_settings() -> void:
	var intro := Label.new()
	intro.text = "Presentation settings are explicit and pause-safe. They do not alter resources, predicates or story access."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_color_override("font_color", IVORY)
	_body.add_child(intro)
	for key in ["captions", "large_text", "timer_free", "reduced_motion"]:
		var check := CheckButton.new()
		check.name = key
		check.text = _setting_label(key)
		check.add_theme_color_override("font_pressed_color", IVORY)
		check.add_theme_color_override("font_hover_pressed_color", IVORY)
		check.button_pressed = bool(_settings.get(key, false))
		check.focus_mode = Control.FOCUS_ALL
		check.pressed.connect(func() -> void:
			_set_settings({key: check.button_pressed}, true)
		)
		_body.add_child(check)
	# Volumes are per machine (user://audio_settings.cfg), not part of the expedition save.
	for bus in AudioSettings.BUSES:
		var row := HBoxContainer.new()
		var name_label := Label.new()
		name_label.text = String(AudioSettings.LABELS[bus])
		name_label.custom_minimum_size.x = 220
		name_label.add_theme_color_override("font_color", IVORY)
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
		var percent := Label.new()
		percent.custom_minimum_size.x = 56
		percent.text = "%d%%" % roundi(slider.value * 100.0)
		percent.add_theme_color_override("font_color", MUTED)
		slider.value_changed.connect(func(value: float) -> void:
			AudioSettings.set_volume(bus, value)
			percent.text = "%d%%" % roundi(value * 100.0)
		)
		row.add_child(slider)
		row.add_child(percent)
		_body.add_child(row)
	var labels := Label.new()
	labels.text = (
		"CAPTIONS: exact text remains available when voice is missing; essential sounds are captioned too.\n"
		+ ("TIMER-FREE: no reaction clock is required.\n" if is_timer_free() else "STANDARD TIMING: timing labels remain visible.\n")
		+ ("REDUCED MOTION: panel changes are instant.\n" if is_reduced_motion() else "REDUCED MOTION: available in this panel.\n")
		+ "These presentation settings never skip a safety predicate."
	)
	labels.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	labels.add_theme_color_override("font_color", MUTED)
	_body.add_child(labels)

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
			return "No data supplied by the campaign query."
		var rows: Array[String] = []
		for key in value.keys():
			rows.append("%s: %s" % [String(key), _display_value(value[key])])
		return "\n".join(rows)
	return str(value)

func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 44)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", IVORY)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_focus_color", IVORY)
	button.add_theme_stylebox_override("normal", _button_style(NAVY, IVORY, false))
	button.add_theme_stylebox_override("hover", _button_style(MUSTARD, INK, true))
	button.add_theme_stylebox_override("pressed", _button_style(Color("#D8A915"), INK, true))
	button.add_theme_stylebox_override("focus", _button_style(Color("#243B5A"), IVORY, true))
	return button

func _panel_style(size: Vector2, border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = -size * 0.5
	panel.size = size
	panel.z_index = 40
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.05, 0.10, 0.99)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = border
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _button_style(color: Color, text_color: Color, highlighted: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 12
	style.content_margin_right = 12
	if highlighted:
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = MUSTARD
	return style

func _apply_accessibility() -> void:
	if not is_inside_tree():
		return
	set_meta("accessibility_settings", _settings.duplicate(true))
	set_meta("presentation_transition_seconds", presentation_transition_seconds())
	_apply_text_scale(self)

func _apply_text_scale(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			var control := child as Control
			if not control.has_meta("lla_base_font_size"):
				var base_size := control.get_theme_font_size("font_size")
				if base_size > 0:
					control.set_meta("lla_base_font_size", base_size)
			if control.has_meta("lla_base_font_size"):
				control.add_theme_font_size_override("font_size", int(round(float(control.get_meta("lla_base_font_size")) * text_scale())))
		_apply_text_scale(child)

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

func _unhandled_input(event: InputEvent) -> void:
	# Godot sends controller cancel through this callback, not key_input.
	# Keyboard events retain their existing path and cannot close twice.
	if not event is InputEventKey:
		_unhandled_key_input(event)

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
		_source_button("DATA CARDS · EVIDENCE BEHIND THESE NUMBERS", func(): open_panel("sources", {"ids": ids}))

func _card_text(text: String, emphasis: bool = false) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", MUSTARD if emphasis else IVORY)
	_body.add_child(label)

func _render_card(value) -> void:
	if _source_from_outcome:
		_source_button("RETURN TO SCIENCE DEBRIEF", func(): open_panel("outcome"))
	var id := String(value.get("source_id", "")) if value is Dictionary else ""
	var card: Dictionary = science.card(id)
	_card_text("WHAT THIS MEANS FOR AURORA\n" + String(card.get("takeaway", "")), true)
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
		_card_text("EVIDENCE · " + String(card.get("evidence_label", "")) + "\n" + String(card.get("agency", "")) + "\nDataset: " + String(card.get("dataset_id", "")))
		_card_text("WHAT WAS MEASURED / SUPPLIED\n" + ScienceScript.describe(card.get("fields_used", [])) + "\n" + ScienceScript.describe(card.get("values", {})))
		_card_text("WHAT THE GAME COMPUTED\n" + ScienceScript.describe(card.get("derived", [])) + "\nGame resource units are training rules; the fixture does not validate every game number.")
		_card_text("LIMITS\n" + String(card.get("boundary", "")), true)
		_card_text("SOURCE\n" + String(card.get("url", "")) + "\n" + String(card.get("citation", "")) + "\nRetrieved: " + String(card.get("retrieved", "")) + "\nLicence: " + String(card.get("licence", "")))
	_source_button("BACK TO ALL SOURCES", func(): open_panel("sources", {"ids": []}))

func _render_journal(value) -> void:
	if not value is Array or value.is_empty():
		_card_text("New discoveries appear here after you complete their evidence operations.")
		return
	for entry in value:
		if not entry is Dictionary:
			continue
		_card_text(String(entry.get("title", "Acquired record")).to_upper(), true)
		_card_text(String(entry.get("evidence_label", "Recorded observation")))
		for observation in entry.get("observations", []):
			_card_text(String(observation.get("text", "")))

func _render_outcome(value) -> void:
	var data: Dictionary = value if value is Dictionary else {}
	if data.get("chapter1", false):
		_description.text = "Your decisions → your forecast → the result → the evidence. Reading is paused."
		var closure := OutcomeScene.instantiate() as Chapter1OutcomePanel
		_body.add_child(closure)
		closure.science = science
		closure.navigation_changed.connect(func(navigation: Dictionary): _outcome_navigation = navigation)
		closure.retry_requested.connect(func(): outcome_retry_requested.emit())
		closure.continue_requested.connect(func(): outcome_continue_requested.emit())
		closure.source_requested.connect(func(id: String):
			_outcome_scroll_position = (_body.get_parent() as ScrollContainer).scroll_vertical
			_source_from_outcome = true
			open_panel("data_card", {"source_id": id})
		)
		closure.setup(data, text_scale(), _outcome_navigation)
		return
	_card_text(String(data.get("result", "Complete an operation to review its readings.")), true)
	var labels := {"E": "Energy E", "A": "Air A", "H": "Garden health H", "C": "Crop condition C", "R": "Rations R (crew-days)", "Z": "Game exposure Z", "W": "Shelter water W", "K": "Crate shielding K"}
	for change in data.get("changes", []):
		if not change is Dictionary:
			continue
		var key := String(change.get("field", "")).trim_prefix("resources.")
		if labels.has(key):
			_card_text("%s: %s to %s" % [labels[key], _display_value(change.get("from")), _display_value(change.get("to"))])
	for note in data.get("notes", []):
		_card_text(str(note))
