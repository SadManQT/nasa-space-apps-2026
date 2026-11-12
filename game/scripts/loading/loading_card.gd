## Input shield and independently processed station lamp during preparation.
extends CanvasLayer
class_name LoadingCard

var lamp: Label
var ticks := 0
var _clock := 0.0

func _ready() -> void:
	layer = 300
	process_mode = Node.PROCESS_MODE_ALWAYS
	var shade := ColorRect.new()
	shade.color = Color("#05060A")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.add_child(center)
	var card := PanelContainer.new()
	card.theme = preload("res://resources/ui/lla_theme.tres")
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#12151F")
	style.border_color = Color("#3AA0FF")
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	card.add_theme_stylebox_override("panel", style)
	center.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)
	lamp = Label.new()
	lamp.text = "●"
	lamp.add_theme_color_override("font_color", Color("#3AA0FF"))
	row.add_child(lamp)
	var label := Label.new()
	label.text = "Preparing Aurora…"
	label.add_theme_color_override("font_color", Color("#ECEEF0"))
	row.add_child(label)

func _process(delta: float) -> void:
	_clock += delta
	ticks += 1
	lamp.modulate.a = 0.4 + 0.6 * (0.5 + 0.5 * sin(_clock * TAU))
