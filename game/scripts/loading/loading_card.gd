## Input shield and independently processed loading screen (M1-129, 13 Nov review:
## "make the loading scene animated and professional"). A sunlit Moon horizon
## line, an orbit ring with a travelling dot, a progress arc that fills as
## preparation goes on, a rotating step line and one short tip for young players.
## Everything is drawn in code from the design palette: no textures to load while
## the game is loading. `lamp` and `ticks` stay for the loading watchdog tests.
extends CanvasLayer
class_name LoadingCard

const STEPS := ["Preparing Aurora…", "Waking the crew…", "Warming the garden…", "Checking the air…", "Charging the battery…", "Lighting the Commons…"]
const TIPS := [
	"Follow the blue ◇ marker. It always points to your next job.",
	"Press H any time to see what to do next.",
	"Press E when you stand near a job and see the E prompt.",
	"The Sun sets for 36 hours. No Sun means no new power.",
	"Alo is a small mustard plant. Keep Alo alive until sunrise.",
	"Try a plan first. Nothing real changes until you lock it in.",
	"After a job, click when the needle is in the green to earn a star.",
	"Press Esc to pause. The game waits for you.",
]
const STEP_SECONDS := 1.6
const TIP_SECONDS := 4.5

var lamp: Label
var ticks := 0
var _clock := 0.0
var _orbit: Orbit
var _step: Label
var _tip: Label
var _tip_index := 0
var _tip_tween: Tween

## The drawn centrepiece: horizon, orbit ring, travelling dot and the progress arc.
class Orbit extends Control:
	var clock := 0.0
	var accent := Color("#3AA0FF")
	var rose := Color("#FF4F8B")
	var good := Color("#3EE0A0")
	var ivory := Color("#EEF1F8")
	func _init() -> void:
		custom_minimum_size = Vector2(260, 260)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var centre := size * 0.5
		var radius := minf(size.x, size.y) * 0.36
		# The Moon: a dark disc with a thin sunlit rim on the side the Sun is.
		draw_circle(centre, radius * 0.55, Color("#12151F"))
		draw_arc(centre, radius * 0.55, PI * 1.05, PI * 1.95, 40, Color(ivory, 0.75), 2.0, true)
		# A slow crater shimmer: three faint discs that breathe.
		for i in 3:
			var a := 0.08 + 0.05 * sin(clock * 1.3 + i * 2.1)
			var p := centre + Vector2(cos(i * 2.2 + 0.4), sin(i * 2.2 + 0.4)) * radius * (0.18 + 0.08 * i)
			draw_circle(p, radius * (0.07 + 0.02 * i), Color(ivory, a))
		# Orbit ring, tilted like a planet's ring, and the travelling dot.
		var points := PackedVector2Array()
		for i in 73:
			var t := TAU * i / 72.0
			points.append(centre + Vector2(cos(t) * radius, sin(t) * radius * 0.42))
		draw_polyline(points, Color(accent, 0.35), 1.5, true)
		var phase := fmod(clock * 0.9, TAU)
		var dot := centre + Vector2(cos(phase) * radius, sin(phase) * radius * 0.42)
		var front := sin(phase) > 0.0  # in front of the Moon on the lower half
		var dot_colour := accent if front else Color(accent, 0.45)
		draw_circle(dot, 5.0 if front else 3.5, dot_colour)
		draw_circle(dot, 11.0, Color(accent, 0.12 if front else 0.05))
		# Progress arc: eases toward full over the first seconds, then keeps a gentle sweep,
		# so a long load still looks alive and a short one never looks stuck.
		var fill := 1.0 - exp(-clock / 6.0)
		var start := -PI * 0.5
		draw_arc(centre, radius * 0.78, 0.0, TAU, 72, Color(ivory, 0.08), 3.0, true)
		draw_arc(centre, radius * 0.78, start, start + TAU * fill, 72, accent, 3.0, true)
		var sweep := fmod(clock * 1.6, TAU)
		draw_arc(centre, radius * 0.78, start + sweep, start + sweep + 0.5, 16, Color(rose, 0.9), 3.0, true)

func _ready() -> void:
	layer = 300
	process_mode = Node.PROCESS_MODE_ALWAYS
	var shade := ColorRect.new()
	shade.name = "Shade"
	shade.color = Color("#05060A")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.add_child(centre)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 12)
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	centre.add_child(stack)
	var theme: Theme = load("res://resources/ui/lla_theme.tres")
	stack.theme = theme
	_orbit = Orbit.new()
	_orbit.name = "Orbit"
	_orbit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(_orbit)
	var title := Label.new()
	title.name = "Title"
	title.text = "LAST LIGHT ACADEMY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load("res://addons/gohud/assets/fonts/cinzel/Cinzel.ttf"))
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("#EEF1F8"))
	stack.add_child(title)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	stack.add_child(row)
	lamp = Label.new()
	lamp.name = "Lamp"
	lamp.text = "●"
	lamp.add_theme_color_override("font_color", Color("#3AA0FF"))
	row.add_child(lamp)
	_step = Label.new()
	_step.name = "Step"
	_step.text = STEPS[0]
	_step.add_theme_font_size_override("font_size", 20)
	_step.add_theme_color_override("font_color", Color("#EEF1F8"))
	row.add_child(_step)
	_tip = Label.new()
	_tip.name = "Tip"
	_tip.text = TIPS[0]
	_tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip.custom_minimum_size = Vector2(520, 0)
	_tip.add_theme_font_size_override("font_size", 17)
	_tip.add_theme_color_override("font_color", Color("#9AA4BA"))
	stack.add_child(_tip)

func _process(delta: float) -> void:
	_clock += delta
	ticks += 1
	lamp.modulate.a = 0.4 + 0.6 * (0.5 + 0.5 * sin(_clock * TAU))
	_orbit.clock = _clock
	_orbit.queue_redraw()
	var step_index := int(_clock / STEP_SECONDS) % STEPS.size()
	if _step.text != STEPS[step_index]:
		_step.text = STEPS[step_index]
	var tip_index := int(_clock / TIP_SECONDS) % TIPS.size()
	if tip_index != _tip_index:
		_tip_index = tip_index
		_show_tip(TIPS[tip_index])

func _show_tip(text: String) -> void:
	if _tip_tween != null and _tip_tween.is_valid():
		_tip_tween.kill()
	if not is_inside_tree():
		_tip.text = text
		return
	_tip_tween = create_tween()
	_tip_tween.tween_property(_tip, "modulate:a", 0.0, 0.25)
	_tip_tween.tween_callback(func() -> void: _tip.text = text)
	_tip_tween.tween_property(_tip, "modulate:a", 1.0, 0.35)

## The tip currently shown (tests).
func current_tip() -> String:
	return _tip.text if _tip != null else ""
