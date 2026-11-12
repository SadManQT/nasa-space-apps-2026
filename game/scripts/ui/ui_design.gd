extends RefCounted
class_name UiDesign

## The one look for every screen (doc 25 §2.1): design tokens from
## res://resources/ui/ui_design.json, the player-word table and toast rewrites
## from res://resources/campaign/content/ui_text.json, and small helpers that
## build glass panels, buttons, typed labels and line icons from them.
## Everything here is presentation; nothing reads or writes campaign state.

const TOKENS_PATH := "res://resources/ui/ui_design.json"
const TEXT_PATH := "res://resources/campaign/content/ui_text.json"

static var _tokens: Dictionary = {}
static var _text: Dictionary = {}
static var _icon_textures: Dictionary = {}
static var _word_rules: Array = []
static var _banned: RegEx

## A 24 px line icon drawn from the design palette; `kind` names the glyph.
class LineIcon extends Control:
	var kind := ""
	var colour := Color("#F2C230")
	func _init(icon_kind: String = "", icon_colour: Color = Color("#F2C230")) -> void:
		kind = icon_kind
		colour = icon_colour
		custom_minimum_size = Vector2(24, 24)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var c := colour
		# The UI kit's SVG of this kind (M1-07) when it exists; the drawn glyph below is the fallback.
		var kit_texture := UiDesign.kit_icon(kind)
		if kit_texture != null:
			draw_texture_rect(kit_texture, Rect2(Vector2.ZERO, size if size.x > 0 else custom_minimum_size), false, c)
			return
		match kind:
			"power":
				draw_rect(Rect2(2, 6, 16, 12), c, false, 2)
				draw_line(Vector2(20, 10), Vector2(20, 14), c, 2)
				draw_line(Vector2(6, 12), Vector2(14, 12), c, 2)
			"life":
				for y in [6, 12, 18]:
					draw_line(Vector2(3, y), Vector2(21, y), c, 2)
			"water":
				draw_polyline(PackedVector2Array([Vector2(12, 3), Vector2(5, 13), Vector2(7, 20), Vector2(17, 20), Vector2(19, 13), Vector2(12, 3)]), c, 2)
			"shielding":
				draw_polyline(PackedVector2Array([Vector2(3, 3), Vector2(21, 3), Vector2(20, 15), Vector2(12, 22), Vector2(4, 15), Vector2(3, 3)]), c, 2)
			"radiation":
				draw_arc(Vector2(12, 12), 8, 0, TAU, 24, c, 2)
				draw_circle(Vector2(12, 12), 2, c)
				for angle in [PI * 0.5, PI * 1.17, PI * 1.83]:
					draw_line(Vector2(12, 12) + Vector2.RIGHT.rotated(angle) * 4, Vector2(12, 12) + Vector2.RIGHT.rotated(angle) * 8, c, 2)
			"plant":
				draw_line(Vector2(12, 21), Vector2(12, 8), c, 2)
				draw_arc(Vector2(7, 9), 5, -PI * 0.5, PI * 0.5, 10, c, 2)
				draw_arc(Vector2(17, 13), 5, PI * 0.5, PI * 1.5, 10, c, 2)
			"food":
				draw_arc(Vector2(12, 11), 9, PI, TAU, 20, c, 2)
				draw_line(Vector2(3, 11), Vector2(21, 11), c, 2)
				draw_line(Vector2(12, 11), Vector2(12, 22), c, 2)
			"goal":
				draw_polyline(PackedVector2Array([Vector2(12, 2), Vector2(22, 12), Vector2(12, 22), Vector2(2, 12), Vector2(12, 2)]), c, 2)
				draw_circle(Vector2(12, 12), 2.5, c)
			"message":
				draw_rect(Rect2(3, 5, 18, 13), c, false, 2)
				draw_line(Vector2(3, 5), Vector2(12, 13), c, 2)
				draw_line(Vector2(21, 5), Vector2(12, 13), c, 2)
			"place":
				draw_arc(Vector2(12, 10), 6, 0, TAU, 20, c, 2)
				draw_line(Vector2(12, 16), Vector2(12, 22), c, 2)
			_:
				draw_arc(Vector2(12, 12), 8, 0, TAU, 24, c, 2)

## The kit's SVG icon for `kind` (res://assets/ui/kit/icons/<kind>.svg), or null when there is none.
static func kit_icon(kind: String) -> Texture2D:
	if not _icon_textures.has(kind):
		var path := "res://assets/ui/kit/icons/%s.svg" % kind
		_icon_textures[kind] = load(path) if ResourceLoader.exists(path) else null
	return _icon_textures[kind]

## Design tokens (sizes at 1080p, colours, panel, motion, keys).
static func tokens() -> Dictionary:
	if _tokens.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(TOKENS_PATH))
		_tokens = parsed if parsed is Dictionary else {}
	return _tokens

## Player-facing strings: goals, why lines, prompts, results, hints, station words.
static func text() -> Dictionary:
	if _text.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(TEXT_PATH))
		_text = parsed if parsed is Dictionary else {}
	return _text

## A palette colour by token name ("accent", "danger", "kai"...).
static func colour(name: String, fallback: Color = Color("#ECEEF0")) -> Color:
	var value = tokens().get("colour", {}).get(name, "")
	return Color(String(value)) if value is String and not String(value).is_empty() else fallback

## One of the four type sizes ("title", "heading", "body", "caption") in canvas
## pixels for a canvas of `viewport_height`, times the large-text scale.
static var _fonts: Dictionary = {}

## The house faces (Instrument Light, AAA pass): Saira Semi Condensed for titles,
## headings and buttons with a little tracking; Inter for reading text.
static func font(token: String = "body") -> Font:
	if _fonts.has(token):
		return _fonts[token]
	var faces: Dictionary = tokens().get("font", {})
	var key := token if faces.has(token) else ("heading" if token == "title" else "body")
	var base := load(String(faces.get(key, faces.get("body", "res://addons/gohud/assets/fonts/roboto/Roboto.ttf")))) as Font
	var tracking := int(tokens().get("tracking", {}).get(token, 0))
	var result: Font = base
	if base != null and tracking != 0:
		var variation := FontVariation.new()
		variation.base_font = base
		variation.spacing_glyph = tracking
		result = variation
	_fonts[token] = result
	return result

static func font_px(token: String, viewport_height: float, scale: float = 1.0) -> int:
	var type: Dictionary = tokens().get("type", {})
	var base := float(type.get(token, type.get("body", 20)))
	var reference := float(tokens().get("reference_height", 1080))
	var size := ceili(base * viewport_height / reference * scale)
	var floor_px := ceili(12.0 * viewport_height / 720.0 * scale)
	return maxi(size, floor_px)

## A 1080p design measurement in canvas pixels for `viewport_height`.
static func px(value: float, viewport_height: float) -> int:
	return roundi(value * viewport_height / float(tokens().get("reference_height", 1080)))

## Dark glass: deep navy, 10 px radius, one quiet edge, soft shadow (doc 25 §2.1, Instrument Light).
static func glass_style(edge: Color = Color.TRANSPARENT, fill: Color = Color.TRANSPARENT, padding: int = -1) -> StyleBoxFlat:
	var panel: Dictionary = tokens().get("panel", {})
	var style := StyleBoxFlat.new()
	style.bg_color = colour("glass", Color(0.05, 0.08, 0.14, 0.8)) if fill == Color.TRANSPARENT else fill
	style.set_corner_radius_all(int(panel.get("radius", 12)))
	style.set_border_width_all(int(panel.get("edge_width", 1)))
	style.border_color = colour("glass_edge", Color(1, 1, 1, 0.18)) if edge == Color.TRANSPARENT else edge
	style.anti_aliasing = true
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 4)
	var pad := int(panel.get("padding", 16)) if padding < 0 else padding
	style.content_margin_left = pad
	style.content_margin_right = pad
	style.content_margin_top = pad
	style.content_margin_bottom = pad
	return style

## In-play HUD surface (AAA pass): no box, a soft dark ellipse behind floating
## text that dissolves before any edge. The ellipse is drawn `bleed` px beyond
## the content so the text sits in its dense middle.
static func scrim_style(strength: float = 0.62, pad: int = 18, bleed: int = 56) -> StyleBoxTexture:
	var gradient := Gradient.new()
	var ground := Color("#05080E")
	gradient.set_color(0, Color(ground, strength))
	gradient.set_color(1, Color(ground, 0.0))
	gradient.add_point(0.6, Color(ground, strength * 0.7))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)  # radius 0.5 in UV: the ellipse touches the edges at zero
	texture.width = 256
	texture.height = 256
	var style := StyleBoxTexture.new()
	style.texture = texture
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_content_margin(side, pad)
		style.set_expand_margin(side, bleed)
	return style

## Floating HUD text keeps contrast over any scene: a soft dark shadow round each glyph.
static func float_label(label: Label) -> Label:
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_constant_override("shadow_outline_size", 6)
	return label

## A glass PanelContainer ready for children.
static func glass_panel(edge: Color = Color.TRANSPARENT, padding: int = -1) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", glass_style(edge, Color.TRANSPARENT, padding))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel

## A button in the one house style (Instrument Light): quiet glass at rest, a gold
## edge on hover, gold fill only when pressed or selected. `icon_kind` adds a kit icon.
static func button(label: String, min_height: int = 44, icon_kind: String = "") -> Button:
	var result := Button.new()
	result.text = label
	result.custom_minimum_size = Vector2(0, min_height)
	result.focus_mode = Control.FOCUS_ALL
	style_button(result)
	if not icon_kind.is_empty():
		set_button_icon(result, icon_kind)
	return result

## Applies the house button states to any Button (also used by scene-authored buttons).
static func style_button(result: Button) -> void:
	result.add_theme_font_override("font", font("button"))
	result.add_theme_color_override("font_color", colour("ivory"))
	result.add_theme_color_override("font_hover_color", colour("ivory"))
	result.add_theme_color_override("font_pressed_color", colour("ink"))
	result.add_theme_color_override("font_hover_pressed_color", colour("ink"))
	result.add_theme_color_override("font_focus_color", colour("ivory"))
	result.add_theme_color_override("font_disabled_color", colour("muted", Color("#A8B4C8")).darkened(0.25))
	result.add_theme_color_override("icon_normal_color", colour("accent"))
	result.add_theme_color_override("icon_hover_color", colour("accent"))
	result.add_theme_color_override("icon_focus_color", colour("accent"))
	result.add_theme_color_override("icon_pressed_color", colour("ink"))
	result.add_theme_color_override("icon_hover_pressed_color", colour("ink"))
	result.add_theme_stylebox_override("normal", button_style(colour("navy"), false))
	result.add_theme_stylebox_override("hover", button_style(colour("surface_hover", Color("#26354B")), true))
	result.add_theme_stylebox_override("pressed", button_style(colour("accent"), true))
	result.add_theme_stylebox_override("hover_pressed", button_style(colour("accent").lightened(0.08), true))
	result.add_theme_stylebox_override("focus", focus_style())
	result.add_theme_stylebox_override("disabled", button_style(colour("navy").darkened(0.35), false))

## The one gold action of a screen ("Try it", "Resume", "New expedition").
static func make_primary(result: Button) -> Button:
	result.add_theme_stylebox_override("normal", button_style(colour("accent"), false, colour("accent")))
	result.add_theme_stylebox_override("hover", button_style(colour("accent").lightened(0.12), true))
	result.add_theme_stylebox_override("pressed", button_style(colour("accent").darkened(0.1), true))
	for key in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color", "icon_normal_color", "icon_hover_color", "icon_focus_color", "icon_pressed_color"]:
		result.add_theme_color_override(key, colour("ink"))
	result.set_meta("lla_primary", true)
	return result

## A kit icon on a button, sized with the text.
static func set_button_icon(result: Button, icon_kind: String) -> void:
	var texture := kit_icon(icon_kind)
	if texture == null:
		return
	result.icon = texture
	result.expand_icon = false
	result.add_theme_constant_override("icon_max_width", 22)
	result.add_theme_constant_override("h_separation", 10)

static func button_style(fill: Color, highlighted: bool, edge: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(4)
	style.set_border_width_all(1)
	style.border_color = colour("glass_edge") if edge == Color.TRANSPARENT else edge
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 4  # Saira's tall line box already gives the label air; keeps rows at 44 px
	style.content_margin_bottom = 4
	style.anti_aliasing = true
	if highlighted:
		# AAA list selection: a gold bar on the leading edge, a soft gold hairline round the rest.
		style.border_color = colour("accent")
		if fill.a > 0.0 and fill.get_luminance() < 0.4:  # dark rows only; gold fills stay solid
			style.border_width_left = 3
			style.border_color = colour("accent")
			style.shadow_color = Color(colour("accent"), 0.18)
			style.shadow_size = 10
	return style

## Marks a label with a type token and colour; `apply_type` sizes it later.
static func focus_style() -> StyleBoxFlat:
	var style := button_style(Color.TRANSPARENT, true)
	style.draw_center = false
	style.set_border_width_all(2)  # keyboard focus stays a clear 2 px ring
	style.border_color = colour("accent")
	style.expand_margin_left = 2
	style.expand_margin_right = 2
	style.expand_margin_top = 2
	style.expand_margin_bottom = 2
	return style

static func style_label(label: Label, token: String, colour_name: String = "ivory") -> Label:
	label.set_meta("lla_type", token)
	label.add_theme_font_override("font", font(token))
	label.add_theme_color_override("font_color", colour(colour_name))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

## A new label with a type token.
static func label(text_value: String, token: String = "body", colour_name: String = "ivory") -> Label:
	var result := Label.new()
	result.text = text_value
	return style_label(result, token, colour_name)

## Sizes every typed label, button and kit icon under `node` for the canvas
## height and text scale; subtrees listed in `skip` are left alone.
static func apply_type(node: Node, viewport_height: float, scale: float, skip: Array = []) -> void:
	for child in node.get_children():
		if skip.has(child):
			continue
		if child is Control:
			var control := child as Control
			if control.has_meta("lla_icon_px"):
				# Kit icons (UiKit.icon) grow with the text beside them, so 150 % text keeps icon and word in proportion.
				var icon_side := px(float(control.get_meta("lla_icon_px")) * scale, viewport_height)
				control.custom_minimum_size = Vector2(icon_side, icon_side)
			if control.has_meta("lla_type"):
				control.add_theme_font_override("font", font(String(control.get_meta("lla_type"))))
				control.add_theme_font_size_override("font_size", font_px(String(control.get_meta("lla_type")), viewport_height, scale))
			elif control is Button or control is CheckButton:
				control.add_theme_font_size_override("font_size", font_px("button", viewport_height, scale))
			else:
				# Text sized by its own owner (the M1-48 journal cards): keep that size and scale it for large text.
				if not control.has_meta("lla_base_font_size") and control.get_theme_font_size("font_size") > 0:
					control.set_meta("lla_base_font_size", control.get_theme_font_size("font_size"))
				if control.has_meta("lla_base_font_size"):
					control.add_theme_font_size_override("font_size", roundi(float(control.get_meta("lla_base_font_size")) * scale))
		apply_type(child, viewport_height, scale, skip)

## True when the player asked for reduced motion.
static func reduced_motion(settings: Dictionary) -> bool:
	return bool(settings.get("reduced_motion", false))

## Seconds for a show or hide transition, honouring reduced motion.
static func motion_seconds(key: String, settings: Dictionary) -> float:
	if reduced_motion(settings):
		return 0.0
	return float(tokens().get("motion", {}).get(key, 0.2))

## Replaces developer words with player words (doc 25 §1.1), whole words only,
## keeping a leading capital. Story text never passes through here.
static func player_words(value: String) -> String:
	if value.is_empty():
		return value
	if _word_rules.is_empty():
		var words: Dictionary = text().get("words", {})
		var keys := words.keys()
		keys.sort_custom(func(a, b): return String(a).length() > String(b).length())
		for key in keys:
			var regex := RegEx.new()
			regex.compile("(?i)\\b" + _escape(String(key)) + "\\b")
			_word_rules.append({"regex": regex, "text": String(words[key])})
	var result := value
	for rule in _word_rules:
		result = _replace_all(result, rule.regex, rule.text)
	return result.replace("  ", " ").strip_edges()

static func _replace_all(value: String, regex: RegEx, replacement: String) -> String:
	var out := ""
	var offset := 0
	for found in regex.search_all(value):
		out += value.substr(offset, found.get_start() - offset)
		var matched := found.get_string()
		var piece := replacement
		if not piece.is_empty() and matched.length() > 0 and matched[0] == matched[0].to_upper() and matched[0] != matched[0].to_lower():
			piece = piece[0].to_upper() + piece.substr(1)
		out += piece
		offset = found.get_end()
	return out + value.substr(offset)

static func _escape(value: String) -> String:
	var out := ""
	for character in value:
		out += ("\\" + character) if "\\^$.|?*+()[]{}-".contains(character) else character
	return out

## The §8.1 developer-language detector used by tests and the debug overlay.
static func banned_regex() -> RegEx:
	if _banned == null:
		_banned = RegEx.new()
		var patterns: Array = text().get("banned_patterns", [])
		_banned.compile("(?i)(" + "|".join(patterns.map(func(p): return String(p))) + ")")
	return _banned

## Rewrites a runtime reason into a toast: {"text", "kind", "flag"}.
## `flag` is set for "do this first" reasons so the HUD can name the job.
static func toast_rewrite(reason: String) -> Dictionary:
	var result := {"text": reason, "kind": "info", "flag": ""}
	for raw_rule in text().get("rewrites", []):
		if not raw_rule is Dictionary:
			continue
		var rule: Dictionary = raw_rule
		var hit := false
		if rule.has("equals"):
			hit = reason == String(rule.equals)
		elif rule.has("starts_with"):
			hit = reason.begins_with(String(rule.starts_with))
		elif rule.has("contains"):
			hit = reason.contains(String(rule.contains))
		if not hit:
			continue
		result.kind = String(rule.get("kind", "info"))
		if rule.has("flag_goal"):
			result.flag = reason.trim_prefix(String(rule.starts_with)).strip_edges()
			result.text = String(rule.flag_goal)
		elif rule.has("text"):
			result.text = String(rule.text)
		return result
	result.text = player_words(reason)
	return result

## A number without a trailing ".0".
static func number(value: float) -> String:
	return str(int(value)) if value == floor(value) else String.num(value, 2).rstrip("0").rstrip(".")

## Distance text for a world marker ("12 m", or "here" within a metre).
static func distance_text(metres: float) -> String:
	var hud: Dictionary = text().get("hud", {})
	if metres < 1.0:
		return String(hud.get("here", "here"))
	return String(hud.get("distance", "%d m")) % int(round(metres))
