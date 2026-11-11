extends RefCounted
class_name UiKit

## The shared UI kit (UI_Kit, M1-07): the one line-icon set as SVG files, each
## icon with its word, and the small reusable widgets every screen composes
## from the UiDesign tokens: meters, source chips, role markers, key glyphs,
## state cards and a Theme resource. Words and levels come from
## res://resources/ui/ui_kit.json; nothing here reads or writes campaign state.

const KIT_PATH := "res://resources/ui/ui_kit.json"
const ICON_DIR := "res://assets/ui/kit/icons/"
const THEME_PATH := "res://resources/ui/lla_theme.tres"

static var _kit: Dictionary = {}
static var _theme: Theme
static var _textures: Dictionary = {}

## The kit data (icons and their words, sources, states, meter levels, roles).
static func kit() -> Dictionary:
	if _kit.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(KIT_PATH))
		_kit = parsed if parsed is Dictionary else {}
	return _kit

## Every icon kind in the set.
static func icon_kinds() -> Array:
	return kit().get("icons", {}).keys()

## The word shown with an icon kind ("Goal", "Earth link"); "" for an unknown kind.
static func icon_word(kind: String) -> String:
	return String(kit().get("icons", {}).get(kind, ""))

## The 2x rasterised SVG for a kind, or null when the kit has no such file.
static func icon_texture(kind: String) -> Texture2D:
	var path := ICON_DIR + kind + ".svg"
	if not _textures.has(path):
		_textures[path] = load(path) if ResourceLoader.exists(path) else null
	return _textures[path]

## Icon size in canvas pixels (24 at the reference height).
static func icon_px() -> int:
	return int(kit().get("icon_px", 24))

## The smallest interaction target (44 px).
static func min_interaction_px() -> int:
	return int(kit().get("min_interaction_px", 44))

## A tinted icon control; falls back to the code-drawn glyph when the SVG is missing.
static func icon(kind: String, colour_name: String = "accent", size_px: int = -1) -> Control:
	var px := icon_px() if size_px < 0 else size_px
	var texture := icon_texture(kind)
	if texture == null:
		var drawn := UiDesign.LineIcon.new(kind, UiDesign.colour(colour_name))
		drawn.custom_minimum_size = Vector2(px, px)
		return drawn
	var rect := TextureRect.new()
	rect.name = "Icon_" + kind
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	rect.custom_minimum_size = Vector2(px, px)
	rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rect.modulate = UiDesign.colour(colour_name)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_meta("icon_kind", kind)
	rect.set_meta("lla_icon_px", px)  # 1080p size; UiDesign.apply_type scales it with the canvas and text size
	return rect

## An icon beside its word: the only way the kit shows an icon.
static func icon_label(kind: String, word: String = "", token: String = "body", colour_name: String = "ivory", icon_colour: String = "accent") -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "IconLabel_" + kind
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon(kind, icon_colour))
	var label := UiDesign.label(word if not word.is_empty() else icon_word(kind), token, colour_name)
	label.name = "Word"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(label)
	return row

## The meter level for a fraction of full: {"id", "word", "colour", "from"}.
static func meter_level(fraction: float) -> Dictionary:
	var levels: Array = kit().get("meter", {}).get("levels", [])
	for level in levels:
		if fraction >= float(level.get("from", 0.0)):
			return level
	return levels.back() if not levels.is_empty() else {"id": "good", "word": "OK", "colour": "good", "from": 0.0}

## A resource meter: icon and word, the value with its unit, the level in a word
## (OK / Low / Critical) and a bar coloured by level. Never colour alone.
static func meter(kind: String, value: float, maximum: float, unit: String = "", word: String = "") -> VBoxContainer:
	var box := VBoxContainer.new()
	box.name = "Meter_" + kind
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var clamped := clampf(value, 0.0, maxf(maximum, 0.0))
	var fraction := clamped / maximum if maximum > 0.0 else 0.0
	var level := meter_level(fraction)
	var head := icon_label(kind, word)
	var amount := UiDesign.label((UiDesign.number(clamped) + " " + unit).strip_edges(), "body")
	amount.name = "Value"
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	amount.autowrap_mode = TextServer.AUTOWRAP_OFF
	head.add_child(amount)
	var state := UiDesign.label(String(level.get("word", "")), "caption", String(level.get("colour", "good")))
	state.name = "Level"
	state.custom_minimum_size.x = 72
	state.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	state.autowrap_mode = TextServer.AUTOWRAP_OFF
	head.add_child(state)
	box.add_child(head)
	var bar := ProgressBar.new()
	bar.name = "Bar"
	bar.show_percentage = false
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.value = fraction
	bar.custom_minimum_size.y = int(kit().get("meter", {}).get("bar_px", 10))
	bar.add_theme_stylebox_override("background", _bar_style(UiDesign.colour("navy").darkened(0.3)))
	bar.add_theme_stylebox_override("fill", _bar_style(UiDesign.colour(String(level.get("colour", "good")))))
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(bar)
	box.set_meta("level", String(level.get("id", "")))
	box.set_meta("fraction", fraction)
	return box

## A source chip for a dialogue origin ("EARTH LINK" -> Earth link with the
## link icon). Local live speech has no chip, so this returns null for it.
static func source_chip(origin_label: String) -> PanelContainer:
	var key := origin_label.strip_edges().to_upper()
	var word := String(UiDesign.text().get("dialogue", {}).get("origins", {}).get(key, key.capitalize()))
	var kind := String(kit().get("sources", {}).get(key, ""))
	if word.is_empty() or kind.is_empty():
		return null
	var chip := PanelContainer.new()
	chip.name = "Source_" + kind
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := UiDesign.glass_style(UiDesign.colour("glass_edge", Color(1, 1, 1, 0.18)), UiDesign.colour("navy"), 6)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 12
	chip.add_theme_stylebox_override("panel", style)
	var row := icon_label(kind, word, "caption", "ivory", "accent")
	row.add_theme_constant_override("separation", 6)
	chip.add_child(row)
	chip.set_meta("source_word", word)
	return chip

## The role marker: role colour dot, role icon, name and role word (ART_BIBLE §3).
static func role_marker(role_id: String) -> HBoxContainer:
	var role: Dictionary = kit().get("roles", {}).get(role_id.to_lower(), {})
	var row := HBoxContainer.new()
	row.name = "Role_" + role_id.to_lower()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dot := Panel.new()
	dot.name = "Dot"
	dot.custom_minimum_size = Vector2(12, 12)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var style := StyleBoxFlat.new()
	style.bg_color = UiDesign.colour(String(role.get("colour", "muted")))
	style.set_corner_radius_all(6)
	style.anti_aliasing = true
	dot.add_theme_stylebox_override("panel", style)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(dot)
	row.add_child(icon(String(role.get("icon", "person")), String(role.get("colour", "muted"))))
	var name_label := UiDesign.label(String(role.get("name", role_id.capitalize())), "body")
	name_label.name = "Name"
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(name_label)
	var role_label := UiDesign.label(String(role.get("role", "")), "caption", "muted")
	role_label.name = "RoleWord"
	role_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	role_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(role_label)
	return row

## A key cap ("E", "Esc") at least 44 px square, for prompts that name a key.
static func key_glyph(key: String) -> PanelContainer:
	var cap := PanelContainer.new()
	cap.name = "Key_" + key
	var px := min_interaction_px()
	cap.custom_minimum_size = Vector2(px, px)
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := UiDesign.glass_style(UiDesign.colour("ivory").darkened(0.35), UiDesign.colour("navy"), 6)
	style.set_corner_radius_all(8)
	style.set_border_width_all(2)
	cap.add_theme_stylebox_override("panel", style)
	var label := UiDesign.label(key, "body", "ivory")
	label.name = "Key"
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cap.add_child(label)
	return cap

## A state card for an empty, error, loading or disabled panel: icon, the state
## in words and an optional detail line. Unknown states read as "empty".
static func state_card(state: String, detail: String = "") -> PanelContainer:
	var states: Dictionary = kit().get("states", {})
	var entry: Dictionary = states.get(state, states.get("empty", {"icon": "info", "word": "Nothing here yet", "colour": "muted"}))
	var card := UiDesign.glass_panel()
	card.name = "State_" + state
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(row)
	row.add_child(icon(String(entry.get("icon", "info")), String(entry.get("colour", "muted"))))
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(column)
	var word := UiDesign.label(String(entry.get("word", "")), "body", "ivory")
	word.name = "Word"
	column.add_child(word)
	if not detail.is_empty():
		var detail_label := UiDesign.label(detail, "caption", "muted")
		detail_label.name = "Detail"
		column.add_child(detail_label)
	card.set_meta("state", state)
	return card

## One Theme built from the design tokens: buttons, labels, glass panels,
## progress bars, check buttons, sliders, line edits and separators. Saved
## to res://resources/ui/lla_theme.tres by game/tools/build_ui_theme.gd so the
## editor and scenes see the same look the runtime builds.
static func theme() -> Theme:
	if _theme != null:
		return _theme
	# One preset at boot keeps Gohud components consistent with the house kit.
	GoUi.use_preset(GoThemePresets.SCIFI_DARK)
	GoUi.config.color_overrides = {GoTheme.ACCENT: UiDesign.colour("accent"), GoTheme.ACCENT_FILL: UiDesign.colour("accent"), GoTheme.ON_ACCENT: UiDesign.colour("ink"), GoTheme.TEXT: UiDesign.colour("ivory"), GoTheme.MUTED: UiDesign.colour("muted"), GoTheme.SURFACE: UiDesign.colour("navy")}
	GoUi.config.metric_overrides = {GoTheme.RADIUS: 8, GoTheme.RADIUS_SMALL: 6, GoTheme.RADIUS_LARGE: 10}
	GoUi.refresh()
	var result := Theme.new()
	# The approved proposals use quiet curved surfaces rather than industrial corners.
	var hero := UiDesign.glass_style()
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		hero.set_content_margin(side, 0.0)
	result.set_type_variation("HeroPanel", "PanelContainer")
	result.set_stylebox("panel", "HeroPanel", hero)
	result.default_font = UiDesign.font()
	result.set_type_variation("TitleLabel", "Label")
	result.set_font("font", "TitleLabel", UiDesign.font("heading"))
	var body_px := int(UiDesign.tokens().get("type", {}).get("body", 20))
	result.default_font_size = body_px
	result.set_color("font_color", "Label", UiDesign.colour("ivory"))
	result.set_stylebox("normal", "Button", UiDesign.button_style(UiDesign.colour("navy"), false))
	result.set_stylebox("hover", "Button", UiDesign.button_style(UiDesign.colour("accent"), true))
	result.set_stylebox("pressed", "Button", UiDesign.button_style(UiDesign.colour("accent").darkened(0.12), true))
	result.set_stylebox("focus", "Button", UiDesign.focus_style())
	result.set_stylebox("disabled", "Button", UiDesign.button_style(UiDesign.colour("navy").darkened(0.35), false))
	result.set_color("font_color", "Button", UiDesign.colour("ivory"))
	result.set_color("font_hover_color", "Button", UiDesign.colour("ink"))
	result.set_color("font_pressed_color", "Button", UiDesign.colour("ink"))
	result.set_color("font_hover_pressed_color", "Button", UiDesign.colour("ink"))
	result.set_color("font_focus_color", "Button", UiDesign.colour("ivory"))
	result.set_color("font_disabled_color", "Button", UiDesign.colour("muted", Color("#A8B4C8")).darkened(0.25))
	result.set_constant("h_separation", "Button", 8)
	for kind in ["CheckButton", "CheckBox"]:
		# Checked rows keep dark backing for panels with explicit ivory label overrides.
		result.set_stylebox("normal", kind, UiDesign.button_style(UiDesign.colour("navy"), false))
		result.set_stylebox("hover", kind, UiDesign.button_style(UiDesign.colour("navy").lightened(0.08), true))
		result.set_stylebox("pressed", kind, UiDesign.button_style(UiDesign.colour("navy").lightened(0.08), true))
		result.set_stylebox("hover_pressed", kind, UiDesign.button_style(UiDesign.colour("navy").lightened(0.12), true))
		result.set_stylebox("focus", kind, UiDesign.focus_style())
		result.set_color("font_color", kind, UiDesign.colour("ivory"))
		result.set_color("font_hover_color", kind, UiDesign.colour("accent"))
		result.set_color("font_focus_color", kind, UiDesign.colour("accent"))
		result.set_color("font_pressed_color", kind, UiDesign.colour("accent"))
		result.set_color("font_disabled_color", kind, UiDesign.colour("muted").darkened(0.25))
	result.set_stylebox("panel", "PanelContainer", UiDesign.glass_style())
	result.set_stylebox("background", "ProgressBar", _bar_style(UiDesign.colour("navy").darkened(0.3)))
	result.set_stylebox("fill", "ProgressBar", _bar_style(UiDesign.colour("accent")))
	result.set_stylebox("slider", "HSlider", _bar_style(UiDesign.colour("navy").darkened(0.3)))
	result.set_stylebox("grabber_area", "HSlider", _bar_style(UiDesign.colour("accent")))
	result.set_stylebox("grabber_area_highlight", "HSlider", _bar_style(UiDesign.colour("accent").lightened(0.15)))
	var edit := UiDesign.button_style(UiDesign.colour("navy").darkened(0.2), false)
	result.set_stylebox("normal", "LineEdit", edit)
	result.set_stylebox("focus", "LineEdit", UiDesign.button_style(UiDesign.colour("navy").darkened(0.2), true))
	result.set_color("font_color", "LineEdit", UiDesign.colour("ivory"))
	result.set_color("font_placeholder_color", "LineEdit", UiDesign.colour("muted"))
	result.set_color("caret_color", "LineEdit", UiDesign.colour("accent"))
	var line := StyleBoxLine.new()
	line.color = UiDesign.colour("glass_edge", Color(1, 1, 1, 0.18))
	line.thickness = 1
	result.set_stylebox("separator", "HSeparator", line)
	_theme = result
	return result

## WCAG 2 contrast ratio between two opaque colours (1 to 21).
static func contrast_ratio(a: Color, b: Color) -> float:
	var la := _luminance(a) + 0.05
	var lb := _luminance(b) + 0.05
	return la / lb if la > lb else lb / la

## `foreground` over `background` with alpha, flattened onto `base` first.
static func composite(foreground: Color, background: Color) -> Color:
	var alpha := foreground.a
	return Color(foreground.r * alpha + background.r * (1.0 - alpha), foreground.g * alpha + background.g * (1.0 - alpha), foreground.b * alpha + background.b * (1.0 - alpha), 1.0)

static func _luminance(c: Color) -> float:
	return 0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b)

static func _channel(v: float) -> float:
	return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)

static func _bar_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(2)
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	style.anti_aliasing = true
	return style
