## M3-6A: the filtered remote-camera monitor screen (EX-CH06-S06..S11), drawn into the monitor's Screen_Main by
## eclipse_props.gd attach_monitor_screen(). The camera tracks the Sun, so the Sun stays centred while Earth's dark
## disc (3.5 times wider, seen from the Moon) crosses it; at totality only Earth's refracted red rim remains. A
## labelled conceptual inset explains the rim (light through Earth's atmospheric limb) and is not a map of Earth;
## the date line comes from the NASA fixture and Aurora's local view stays labelled as scenario (EX-CH06-S07).
## Driven by the puzzle that owns P-12: set_phase, set_mode, set_filter, set_logged, show_inset. Design size 1152x648.
extends Control

const DATA_PATH := "res://assets/props/eclipse_power/monitor/eclipse_monitor_screen.json"
const SHADER_PATH := "res://assets/props/eclipse_power/monitor/eclipse_camera_view.gdshader"
const DESIGN_SIZE := Vector2(1152, 648)
const MONTHS := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
const INK := Color("#e6ebf2")
const DIM_INK := Color("#a9b4c6")
const PANEL := Color(0.043, 0.07, 0.125, 0.86)
const GOLD := Color("#f2c230")
const CYAN := Color("#20b8c9")

var data: Dictionary = {}
var phase := 0.0
var mode := "live"
var filter_in := true
var logged: Dictionary = {}
var _material: ShaderMaterial
var _view: ColorRect
var _overlay: Control
var _inset: Panel
var _no_signal: ColorRect
var _held: Label
var _filter_label: Label
var _chips: Dictionary = {}
var _date_label: Label
var _time := 0.0

func _init() -> void:
	data = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	size = DESIGN_SIZE
	custom_minimum_size = DESIGN_SIZE
	clip_contents = true
	_build()
	set_phase(0.0)

# ----------------------------------------------------------------------------------------------- public API

## Moves the eclipse along the authored path: 0 just before first contact, 0.5 mid-totality, 1 just after last
## contact. Updates the picture and the auto-exposure gain.
func set_phase(value: float) -> void:
	phase = clampf(value, 0.0, 1.0)
	var g := geometry(phase)
	_material.set_shader_parameter("sun_center", g.sun)
	_material.set_shader_parameter("sun_radius", g.rs)
	_material.set_shader_parameter("earth_center", g.earth)
	_material.set_shader_parameter("earth_radius", g.re)
	_material.set_shader_parameter("ring_width", float(g.re) * float(data.science.ring_width_of_earth_radius))
	_material.set_shader_parameter("gain", exposure_gain(phase))
	# M4-16 / M4-01: the red rim exists only at totality; gate the shader rim to ring_visible(phase)
	# so ingress and egress show no red atmospheric ring. Both PR_EclipseMonitor LODs share this
	# one live screen, so the gate covers both.
	_material.set_shader_parameter("rim_visible", 1.0 if ring_visible(phase) else 0.0)
	if _overlay:
		_overlay.queue_redraw()

## live (picture updating), held (frame frozen for inspection) or no_signal (feeder F2 has dropped).
func set_mode(value: String) -> void:
	mode = value
	_view.visible = mode != "no_signal"
	_overlay.visible = mode != "no_signal"
	_no_signal.visible = mode == "no_signal"
	_held.visible = mode == "held"

## The protective configuration: the solar filter in front of the lens (EX-CH06-S06).
func set_filter(value: bool) -> void:
	filter_in = value
	_material.set_shader_parameter("filter_in", value)
	_filter_label.text = data.text.filter_in if value else data.text.filter_out

## Marks an observation (ingress, ring, egress) as logged or not; the chip says it in words.
func set_logged(event_id: String, value: bool) -> void:
	logged[event_id] = value
	var chip: Label = _chips.get(event_id)
	if chip == null:
		return
	chip.text = "%s  -  %s" % [chip.get_meta("event_text"), data.text.logged if value else data.text.not_logged]
	var style := (chip.get_parent() as PanelContainer).get_theme_stylebox("panel") as StyleBoxFlat
	style.border_color = CYAN if value else Color(0.45, 0.5, 0.58)

## Shows or hides the labelled Earth-limb inset (the player may hold the frame and open it, EX-CH06-S07).
func show_inset(value: bool) -> void:
	_inset.visible = value

## Whether the screen shows the conceptual inset.
func inset_visible() -> bool:
	return _inset.visible

## Fraction of the Sun's disc not hidden by Earth at a phase (1 before contact, 0 in totality).
func visible_fraction(at_phase: float) -> float:
	var g := geometry(at_phase)
	var gap: Vector2 = g.earth - g.sun
	var rs: float = g.rs
	var overlap := circle_overlap(gap.length(), rs, float(g.re))
	return clampf(1.0 - overlap / (PI * rs * rs), 0.0, 1.0)

## True while the Sun is completely behind Earth: the red rim is the only light in the picture.
func ring_visible(at_phase: float) -> bool:
	return visible_fraction(at_phase) <= 0.0

## Auto exposure: the camera's gain rises as the visible Sun shrinks, capped at 12x in totality.
func exposure_gain(at_phase: float) -> float:
	return clampf(pow(1.0 / maxf(visible_fraction(at_phase), 0.0005), 0.45), 1.0, 12.0)

## The authored geometry in frame units (frame height 1, origin at the centre, y down): the Sun at the centre, Earth
## 3.5 times wider (data science.earth_to_sun_width_ratio) moving left to right on a path offset from centre, so
## totality is not central.
func geometry(at_phase: float) -> Dictionary:
	var sci: Dictionary = data.science
	var re := float(sci.earth_radius_frame)
	var rs := re / float(sci.earth_to_sun_width_ratio)
	var reach := (re + rs) * 1.06
	var direction := Vector2(1.0, 0.16).normalized()
	var across := Vector2(-direction.y, direction.x)
	var along := lerpf(-reach, reach, clampf(at_phase, 0.0, 1.0))
	var earth := direction * along + across * (re - rs) * float(sci.path_offset_of_radius_gap)
	return {"sun": Vector2.ZERO, "rs": rs, "earth": earth, "re": re}

## Area shared by two circles of radii r1 and r2 whose centres are d apart.
static func circle_overlap(d: float, r1: float, r2: float) -> float:
	if d >= r1 + r2:
		return 0.0
	if d <= absf(r1 - r2):
		return PI * pow(minf(r1, r2), 2)
	var a1 := r1 * r1 * acos(clampf((d * d + r1 * r1 - r2 * r2) / (2.0 * d * r1), -1.0, 1.0))
	var a2 := r2 * r2 * acos(clampf((d * d + r2 * r2 - r1 * r1) / (2.0 * d * r2), -1.0, 1.0))
	var k := (-d + r1 + r2) * (d + r1 - r2) * (d - r1 + r2) * (d + r1 + r2)
	return a1 + a2 - 0.5 * sqrt(maxf(k, 0.0))

## The eclipse date as checked in the NASA fixture (greatest eclipse, UTC), e.g. "12 Jan 2047".
func eclipse_date() -> String:
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(data.fixture))
	for item in fixture.get("derived", []):
		if item.name == "greatest_eclipse_ut":
			var day := String(item.value).substr(0, 10).split("-")
			return "%d %s %s" % [int(day[2]), MONTHS[int(day[1]) - 1], day[0]]
	return ""

## Every word on the screen, for the text-equivalent and English-only checks.
func all_text() -> PackedStringArray:
	var out := PackedStringArray()
	for label in find_children("*", "Label", true, false):
		out.append((label as Label).text)
	return out

func _process(delta: float) -> void:
	if mode == "live":
		_time += delta
		_material.set_shader_parameter("noise_time", _time)

# ----------------------------------------------------------------------------------------------- layout

func _label(parent: Control, text: String, at: Vector2, font_size: int, color: Color = INK, width: float = 0.0) -> Label:
	var l := Label.new()
	if width > 0.0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(width, 0)
	l.text = text
	l.position = at
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	if width > 0.0:
		l.size = Vector2(width, l.get_combined_minimum_size().y)
	return l

func _strip(parent: Control, rect: Rect2, color: Color) -> ColorRect:
	var strip := ColorRect.new()
	strip.position = rect.position
	strip.size = rect.size
	strip.color = color
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(strip)
	return strip

func _build() -> void:
	var text: Dictionary = data.text
	_view = ColorRect.new()
	_view.name = "CameraView"
	_view.size = DESIGN_SIZE
	_material = ShaderMaterial.new()
	_material.shader = load(SHADER_PATH)
	_material.set_shader_parameter("frame_size", DESIGN_SIZE)
	_view.material = _material
	add_child(_view)
	_overlay = Control.new()
	_overlay.name = "Overlay"
	_overlay.size = DESIGN_SIZE
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)
	# top bar: what the picture is, where it comes from, the filter and exposure state
	_strip(self, Rect2(0, 0, DESIGN_SIZE.x, 46), PANEL)
	_label(self, text.title, Vector2(18, 10), 20)
	_label(self, text.feed, Vector2(290, 12), 17, DIM_INK)
	_filter_label = _label(self, text.filter_in, Vector2(640, 12), 17, GOLD)
	_label(self, text.exposure, Vector2(860, 12), 17, DIM_INK)
	_held = _label(self, text.held, Vector2(18, 58), 18, Color("#1b1d21"))
	var held_back := StyleBoxFlat.new()
	held_back.bg_color = Color("#ffb020")
	held_back.set_content_margin_all(6)
	_held.add_theme_stylebox_override("normal", held_back)
	_held.visible = false
	# observation chips: each says logged or not in words, not by colour alone
	var x := 18.0
	for event in text.events:
		var chip_box := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = PANEL
		style.border_color = Color(0.45, 0.5, 0.58)
		style.set_border_width_all(2)
		style.set_corner_radius_all(4)
		style.content_margin_left = 12
		style.content_margin_right = 12
		style.content_margin_top = 5
		style.content_margin_bottom = 5
		chip_box.add_theme_stylebox_override("panel", style)
		chip_box.position = Vector2(x, 512)
		add_child(chip_box)
		var chip := _label(chip_box, "", Vector2.ZERO, 16)
		chip.set_meta("event_text", event.text)
		_chips[event.id] = chip
		set_logged(event.id, false)
		x += 238.0
	# evidence lines: the checked date and the scenario boundary
	_strip(self, Rect2(0, 556, DESIGN_SIZE.x, 92), PANEL)
	_date_label = _label(self, String(text.date_line).format({"date": eclipse_date()}), Vector2(18, 566), 17)
	_label(self, text.geometry_line, Vector2(18, 596), 17, GOLD)
	_label(self, text.instrument, Vector2(DESIGN_SIZE.x - 330, 596), 15, DIM_INK)
	_build_inset(text.inset)
	_no_signal = ColorRect.new()
	_no_signal.name = "NoSignal"
	_no_signal.size = Vector2(DESIGN_SIZE.x, 556 - 46)
	_no_signal.position = Vector2(0, 46)
	_no_signal.color = Color("#05070b")
	add_child(_no_signal)
	_label(_no_signal, text.no_signal, Vector2(0, 190), 54, INK, DESIGN_SIZE.x).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label(_no_signal, text.no_signal_detail, Vector2(0, 268), 20, DIM_INK, DESIGN_SIZE.x).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_no_signal.visible = false

## The labelled conceptual inset: Sun, Earth with its atmospheric shell, grazing rays bent and reddened into the
## shadow, the Moon with Aurora's camera, and the not-to-scale / not-a-map footer.
func _build_inset(words: Dictionary) -> void:
	_inset = Panel.new()
	_inset.name = "EarthLimbInset"
	_inset.position = Vector2(DESIGN_SIZE.x - 16 - 430, 58)
	_inset.size = Vector2(430, 318)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.1, 0.17, 0.94)
	style.border_color = Color("#6c7a96")
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	_inset.add_theme_stylebox_override("panel", style)
	add_child(_inset)
	var diagram := Control.new()
	diagram.name = "Diagram"
	diagram.size = _inset.size
	diagram.mouse_filter = Control.MOUSE_FILTER_IGNORE
	diagram.draw.connect(_draw_inset.bind(diagram))
	_inset.add_child(diagram)
	_label(_inset, words.title, Vector2(14, 8), 18, GOLD)
	_label(_inset, words.atmosphere, Vector2(150, 40), 13, Color("#9cc7ff"), 270)
	_label(_inset, words.sun, Vector2(30, 182), 14, INK)
	_label(_inset, words.earth, Vector2(150, 214), 14, INK)
	_label(_inset, words.moon, Vector2(318, 182), 13, INK, 104)
	_label(_inset, words.rays, Vector2(14, 240), 13, Color("#ffb08a"), 402)
	_label(_inset, words.footer, Vector2(14, 288), 12, DIM_INK, 402)

func _draw_inset(canvas: Control) -> void:
	var yc := 142.0
	var sun := Vector2(52, yc)
	var earth := Vector2(222, yc)
	var moon := Vector2(368, yc)
	var re := 50.0
	# Earth's shadow cone towards the Moon
	canvas.draw_colored_polygon(PackedVector2Array([earth + Vector2(0, -re), Vector2(424, yc - 14), Vector2(424, yc + 14), earth + Vector2(0, re)]), Color(0, 0, 0, 0.42))
	# straight rays that hit Earth
	for dy: float in [-30.0, -12.0, 12.0, 30.0]:
		var hit := earth.x - sqrt(maxf(re * re - dy * dy, 0.0))
		canvas.draw_line(Vector2(sun.x + 24, yc + dy), Vector2(hit, yc + dy), Color(GOLD, 0.75), 2.0)
	# grazing rays through the atmospheric shell, bent and reddened into the shadow; blue scattered aside
	for side: float in [-1.0, 1.0]:
		var y_in := yc + side * (re + 5.0)
		canvas.draw_line(Vector2(sun.x + 22, y_in), Vector2(earth.x, y_in), Color(GOLD, 0.95), 2.0)
		canvas.draw_line(Vector2(earth.x, y_in), moon + Vector2(-16, side * 5.0), Color("#ff5a2a"), 2.5)
		canvas.draw_line(Vector2(earth.x - 4, y_in), Vector2(earth.x - 18, y_in + side * 16.0), Color(0.45, 0.65, 1.0, 0.9), 1.5)
		canvas.draw_line(Vector2(earth.x + 4, y_in), Vector2(earth.x + 12, y_in + side * 18.0), Color(0.45, 0.65, 1.0, 0.9), 1.5)
		var tip := moon + Vector2(-16, side * 5.0)
		var back := (tip - Vector2(earth.x, y_in)).normalized()
		canvas.draw_colored_polygon(PackedVector2Array([tip, tip - back * 9 + back.orthogonal() * 4, tip - back * 9 - back.orthogonal() * 4]), Color("#ff5a2a"))
	# bodies: Sun, Earth's night side with its thin atmospheric shell, the Moon with the camera on its limb
	canvas.draw_circle(sun, 24.0, GOLD)
	canvas.draw_circle(earth, re, Color("#24344d"))
	canvas.draw_arc(earth, re + 4.0, 0.0, TAU, 64, Color(0.36, 0.62, 0.95, 0.75), 6.0)
	canvas.draw_line(Vector2(earth.x + 10, yc - re - 8), Vector2(214, 74), Color("#9cc7ff"), 1.0)
	canvas.draw_circle(moon, 15.0, Color("#9a9894"))
	canvas.draw_rect(Rect2(moon + Vector2(-19, -4), Vector2(8, 8)), INK)

## Tracking brackets around the Sun's position: the camera follows the Sun.
func _draw_overlay() -> void:
	var g := geometry(phase)
	var sun: Vector2 = g.sun
	var centre: Vector2 = DESIGN_SIZE / 2.0 + sun * DESIGN_SIZE.y
	var half: float = float(g.rs) * DESIGN_SIZE.y + 22.0
	var arm := 16.0
	var c := Color(0.85, 0.9, 1.0, 0.55)
	for sx: float in [-1.0, 1.0]:
		for sy: float in [-1.0, 1.0]:
			var corner := centre + Vector2(sx * half, sy * half)
			_overlay.draw_line(corner, corner - Vector2(sx * arm, 0), c, 1.5)
			_overlay.draw_line(corner, corner - Vector2(0, sy * arm), c, 1.5)
