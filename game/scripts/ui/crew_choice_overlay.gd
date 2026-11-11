extends Control
class_name CrewChoiceOverlay

## New Expedition's "who is playing?" step (M1-37): Solo or Class with 2, 3
## or 4 players on this one machine. Main shows it after the title's briefing
## and passes the chosen crew to `_start_new_expedition(crew)`; the title
## scene itself is unchanged. Every word and seat plan comes from
## crew_modes.json. Space/Enter presses the focused choice, Esc goes back.

signal chosen(crew: Dictionary)
signal cancelled

const CrewScript = preload("res://scripts/classmode/crew_modes.gd")
const MIN_TARGET := 44.0

var settings := {"large_text": false}
var _frame: PanelContainer
var _column: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiKit.theme()
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.0, 0.01, 0.03, 0.9)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)
	_frame = PanelContainer.new()
	_frame.name = "CrewChoiceFrame"
	var style := StyleBoxFlat.new()
	style.bg_color = UiDesign.colour("glass")
	style.border_color = UiDesign.colour("accent")
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(26)
	_frame.add_theme_stylebox_override("panel", style)
	add_child(_frame)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	_frame.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 10)
	scroll.add_child(column)
	_column = column
	column.add_child(_label(CrewScript.text("menu", "heading"), 26, UiDesign.colour("accent")))
	column.add_child(_label(CrewScript.text("menu", "intro"), 15, UiDesign.colour("ivory")))
	var choices: Array = [{"mode": CrewScript.SOLO, "players": 1}]
	var class_info := CrewScript.mode_info(CrewScript.CLASS)
	for count in range(int(class_info.get("players_min", 2)), int(class_info.get("players_max", 4)) + 1):
		choices.append({"mode": CrewScript.CLASS, "players": count})
	for crew in choices:
		var solo: bool = crew.mode == CrewScript.SOLO
		var button := Button.new()
		button.name = "Crew_%s_%d" % [crew.mode, crew.players]
		button.text = CrewScript.text("menu", "solo_button") if solo else CrewScript.text("menu", "class_button", {"players": str(crew.players)})
		button.custom_minimum_size.y = MIN_TARGET * _scale()
		button.add_theme_font_size_override("font_size", _fs(16))
		var picked: Dictionary = crew
		button.pressed.connect(func() -> void: chosen.emit(picked.duplicate()))
		column.add_child(button)
		var line := String(CrewScript.mode_info(crew.mode).get("summary", "")) if solo else CrewScript.text("menu", "seat_plan_prefix") + CrewScript.seat_plan_text(crew)
		column.add_child(_label(line, 13, UiDesign.colour("muted")))
	column.add_child(_label(String(CrewScript.mode_info(CrewScript.CLASS).get("summary", "")), 13, UiDesign.colour("muted")))
	column.add_child(_label(CrewScript.text("menu", "print_hint"), 13, UiDesign.colour("muted")))
	var back := Button.new()
	back.name = "CrewBack"
	back.text = CrewScript.text("menu", "cancel_button")
	back.custom_minimum_size.y = MIN_TARGET * _scale()
	back.add_theme_font_size_override("font_size", _fs(14))
	back.pressed.connect(func() -> void: cancelled.emit())
	column.add_child(back)
	get_viewport().size_changed.connect(_layout)
	_layout.call_deferred()
	(find_child("Crew_solo_1", true, false) as Control).grab_focus.call_deferred()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		cancelled.emit()

func _layout() -> void:
	var view := get_viewport_rect().size
	var width := minf(720.0 * _scale(), view.x - 40.0)
	# Wrapped labels know their height only once the width is laid out, so
	# fit the frame a frame later. The scroll keeps every choice reachable
	# at 150% text on a 720 p screen.
	_frame.size = Vector2(width, view.y - 40.0)
	await get_tree().process_frame
	if not is_inside_tree():
		return
	var height := minf(_column.get_combined_minimum_size().y + 54.0, view.y - 40.0)
	_frame.size = Vector2(width, height)
	_frame.position = Vector2((view.x - width) * 0.5, (view.y - height) * 0.5)

func _scale() -> float:
	return 1.5 if bool(settings.get("large_text", false)) else 1.0

func _fs(size: int) -> int:
	return int(round(size * _scale()))

func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", _fs(size))
	label.add_theme_color_override("font_color", color)
	return label
