extends Control
class_name Chapter1CampaignHUD

const PANELS_SCENE: PackedScene = preload("res://scenes/ui/campaign_panels.tscn")
const IVORY := Color("#ECEEF0")
const MUTED := Color("#A8B4C8")
const CYAN := Color("#20B8C9")
const MUSTARD := Color("#F2C230")
const GREEN := Color("#4CAF50")
const RED := Color("#E56B6F")

var runtime: Chapter1Campaign
var panels: CampaignPanels
var _title: Label
var _meta: Label
var _objective: Label
var _caption_speaker: Label
var _caption_line: Label
var _status: Label
var _targets: VBoxContainer
var _next_line: Button
var _advance: Button
var _dialogue_index := 0
var _scene_id := ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()

func setup(value: Chapter1Campaign) -> void:
	runtime = value
	panels = PANELS_SCENE.instantiate() as CampaignPanels
	add_child(panels)
	panels.set_command_sink(Callable(runtime, "handle_ui_command"))
	_refresh_query()
	refresh_scene({})

func refresh_scene(_result: Dictionary = {}) -> void:
	if runtime == null:
		return
	var scene := runtime.current_scene_data()
	var next_scene := String(scene.get("id", ""))
	if next_scene != _scene_id:
		_scene_id = next_scene
		_dialogue_index = 0
	_title.text = String(scene.get("title", "Chapter 1"))
	_meta.text = "%s  ·  %s  ·  %s" % [next_scene, String(scene.get("location", "")), String(scene.get("storyTime", scene.get("story_time", "")))]
	_objective.text = "OBJECTIVE\n" + "\n".join(scene.get("playerActions", scene.get("player_actions", [])))
	_render_caption()
	_build_targets()
	_refresh_query()

func refresh_after_action(result: Dictionary) -> void:
	if result.has("reason"):
		show_status(String(result.get("reason", "")))
	if runtime != null:
		_render_caption()
		_build_targets()
		_refresh_query()

func show_status(text: String) -> void:
	if _status != null:
		_status.text = text
		_status.modulate = GREEN if text.contains("SAVED") or text.contains("committed") else MUTED

func _build() -> void:
	var top := _panel(Color(0.03, 0.06, 0.12, 0.96), 0, Color(0.26, 0.40, 0.62, 0.7))
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 86
	add_child(top)
	var top_margin := MarginContainer.new()
	top_margin.add_theme_constant_override("margin_left", 24)
	top_margin.add_theme_constant_override("margin_right", 24)
	top_margin.add_theme_constant_override("margin_top", 12)
	top_margin.add_theme_constant_override("margin_bottom", 10)
	top.add_child(top_margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	top_margin.add_child(row)
	var brand := Label.new()
	brand.text = "LAST LIGHT / AURORA"
	brand.add_theme_color_override("font_color", MUSTARD)
	brand.add_theme_font_size_override("font_size", 14)
	row.add_child(brand)
	_title = Label.new()
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.add_theme_color_override("font_color", IVORY)
	_title.add_theme_font_size_override("font_size", 21)
	row.add_child(_stack(_title))
	_meta = Label.new()
	_meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_meta.add_theme_color_override("font_color", MUTED)
	_meta.add_theme_font_size_override("font_size", 11)
	row.add_child(_stack(_meta))

	_objective = Label.new()
	_objective.position = Vector2(24, 108)
	_objective.size = Vector2(370, 125)
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective.add_theme_color_override("font_color", CYAN)
	_objective.add_theme_font_size_override("font_size", 14)
	add_child(_objective)

	var caption := _panel(Color(0.03, 0.05, 0.10, 0.95), 14, Color(0.26, 0.40, 0.62, 0.65))
	caption.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	caption.offset_top = -190
	caption.offset_bottom = -28
	add_child(caption)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	caption.add_child(margin)
	var caption_box := VBoxContainer.new()
	caption_box.add_theme_constant_override("separation", 5)
	margin.add_child(caption_box)
	_caption_speaker = Label.new()
	_caption_speaker.add_theme_color_override("font_color", MUSTARD)
	_caption_speaker.add_theme_font_size_override("font_size", 13)
	caption_box.add_child(_caption_speaker)
	_caption_line = Label.new()
	_caption_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption_line.add_theme_color_override("font_color", IVORY)
	_caption_line.add_theme_font_size_override("font_size", 20)
	_caption_line.size_flags_vertical = Control.SIZE_EXPAND_FILL
	caption_box.add_child(_caption_line)
	_next_line = _button("ACKNOWLEDGE LINE  ›")
	_next_line.pressed.connect(_on_next_line)
	caption_box.add_child(_next_line)

	var target_panel := _panel(Color(0.05, 0.08, 0.14, 0.92), 14, Color(0.13, 0.72, 0.78, 0.55))
	target_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	target_panel.offset_left = -400
	target_panel.offset_right = -30
	target_panel.offset_top = 110
	target_panel.offset_bottom = 540
	add_child(target_panel)
	var target_margin := MarginContainer.new()
	target_margin.add_theme_constant_override("margin_left", 18)
	target_margin.add_theme_constant_override("margin_right", 18)
	target_margin.add_theme_constant_override("margin_top", 18)
	target_margin.add_theme_constant_override("margin_bottom", 18)
	target_panel.add_child(target_margin)
	var target_box := VBoxContainer.new()
	target_box.add_theme_constant_override("separation", 8)
	target_margin.add_child(target_box)
	var target_title := Label.new()
	target_title.text = "PHYSICAL OPERATIONS"
	target_title.add_theme_color_override("font_color", CYAN)
	target_title.add_theme_font_size_override("font_size", 14)
	target_box.add_child(target_title)
	_targets = VBoxContainer.new()
	_targets.add_theme_constant_override("separation", 7)
	_targets.size_flags_vertical = Control.SIZE_EXPAND_FILL
	target_box.add_child(_targets)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_color_override("font_color", MUTED)
	target_box.add_child(_status)
	_advance = _button("ADVANCE AFTER PHYSICAL GATE  ›")
	_advance.pressed.connect(_on_advance_pressed)
	target_box.add_child(_advance)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	target_box.add_child(actions)
	var journal := _button("JOURNAL")
	journal.pressed.connect(_on_journal_pressed)
	actions.add_child(journal)
	var save := _button("SAVE")
	save.pressed.connect(_on_save_pressed)
	actions.add_child(save)
	var exit := _button("TITLE")
	exit.pressed.connect(_on_exit_pressed)
	actions.add_child(exit)

func _build_targets() -> void:
	if _targets == null or runtime == null:
		return
	for child in _targets.get_children():
		child.queue_free()
	var gate := runtime.route.gate_status()
	for raw_target in runtime.targets_for_current_scene():
		if not raw_target is Dictionary:
			continue
		var target: Dictionary = raw_target
		var button := _button("USE · " + String(target.get("focus_label", target.get("target_id", "operation"))))
		button.pressed.connect(func() -> void: runtime.perform_target(String(target.get("target_id", ""))))
		_targets.add_child(button)
	_advance.disabled = not bool(gate.get("ready", false))
	if bool(gate.get("ready", false)):
		_status.text = "ALL PHYSICAL PREDICATES READY · advance explicitly."
		_status.modulate = GREEN
	else:
		_status.text = "Missing: " + ", ".join(gate.get("missing", []))
		_status.modulate = MUTED

func _render_caption() -> void:
	if runtime == null:
		return
	var lines := runtime.current_dialogue()
	if lines.is_empty():
		_caption_speaker.text = "AURORA / TRAINING SCENARIO"
		_caption_line.text = "Complete the physical operation; dialogue acknowledgement never completes a gate."
		_next_line.disabled = true
		return
	_dialogue_index = clampi(_dialogue_index, 0, lines.size() - 1)
	var line: Dictionary = lines[_dialogue_index]
	_caption_speaker.text = "%s  ·  %s" % [String(line.get("speaker", "CREW")), String(line.get("origin_label", line.get("delivery", "LOCAL RADIO")))]
	_caption_line.text = String(line.get("text", line.get("line", "")))
	_next_line.disabled = false
	_next_line.text = "ACKNOWLEDGE LINE  ·  %d/%d" % [_dialogue_index + 1, lines.size()]

func _on_next_line() -> void:
	if runtime == null:
		return
	var lines := runtime.current_dialogue()
	if lines.is_empty():
		return
	runtime.acknowledge_dialogue(String(lines[_dialogue_index].get("id", "")))
	if _dialogue_index < lines.size() - 1:
		_dialogue_index += 1
	_render_caption()

func _on_advance_pressed() -> void:
	if runtime != null:
		runtime.advance_scene()

func _on_journal_pressed() -> void:
	if runtime != null and panels != null:
		panels.open_panel("journal_discovery", {"entries": runtime.query().get("journal_entries", [])})

func _on_save_pressed() -> void:
	if runtime != null:
		runtime.save_campaign()

func _on_exit_pressed() -> void:
	if runtime != null:
		runtime.exit_to_title()

func _refresh_query() -> void:
	if panels != null and runtime != null:
		panels.bind_query(runtime.query())

func _stack(control: Control) -> Control:
	var box := VBoxContainer.new()
	box.add_child(control)
	return box

func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 38)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_color_override("font_color", IVORY)
	button.add_theme_color_override("font_hover_color", Color("#05060A"))
	button.add_theme_stylebox_override("normal", _button_style(Color("#1F2A44"), IVORY, false))
	button.add_theme_stylebox_override("hover", _button_style(MUSTARD, Color("#05060A"), true))
	button.add_theme_stylebox_override("focus", _button_style(Color("#243B5A"), IVORY, true))
	return button

func _button_style(fill: Color, text_color: Color, highlighted: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	style.content_margin_left = 10
	style.content_margin_right = 10
	if highlighted:
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = MUSTARD
	return style

func _panel(color: Color, radius: int, border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = border
	panel.add_theme_stylebox_override("panel", style)
	return panel
