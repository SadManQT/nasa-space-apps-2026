## UI_Kit suite (M1-07): every icon kind has an SVG that imports at 2x and a word,
## every kind the HUD, Outpost Status and Mission Table ask for exists, the
## palette pairs the kit uses meet WCAG contrast, meters clamp and name their
## level in a word, source chips cover every dialogue origin, role markers carry
## the role colours, targets are at least 44 px, the saved Theme matches the
## tokens, and the kit reflows at 150 % text in a 1280x720 window.
##   Godot --headless --path game --script res://tools/test_ui_kit.gd
extends SceneTree

const CONTENT_DIR := "res://resources/campaign/content/"
const HUD_KINDS := ["goal", "place", "message", "what_now", "journal", "settings", "save", "pause"]

var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_check_icons()
	_check_screen_kinds()
	_check_words()
	_check_contrast()
	_check_meters()
	_check_sources()
	_check_roles_and_states()
	_check_targets_and_theme()
	await _check_reflow()
	print("UI KIT RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _check_icons() -> void:
	var kinds := UiKit.icon_kinds()
	_check(kinds.size() >= 30, "the kit holds a full icon set (%d kinds)" % kinds.size())
	for kind in kinds:
		var texture := UiKit.icon_texture(String(kind))
		_check(texture != null, "icon %s imports from the SVG set" % kind)
		if texture != null:
			_check(texture.get_width() == 48 and texture.get_height() == 48, "icon %s is rasterised at 2x (48 px): %dx%d" % [kind, texture.get_width(), texture.get_height()])
		var control := UiKit.icon(String(kind))
		_check(control is TextureRect, "UiKit.icon(%s) uses the SVG, not the drawn fallback" % kind)
		_check(control.custom_minimum_size == Vector2(24, 24), "icon %s is 24 px on screen" % kind)
		var legacy := UiDesign.LineIcon.new(String(kind))
		_check(UiDesign.kit_icon(String(kind)) != null, "UiDesign.LineIcon(%s) now draws the kit SVG" % kind)
		legacy.free()
		control.free()
	_check(UiKit.icon("no_such_icon") is UiDesign.LineIcon, "an unknown kind falls back to the drawn glyph")

func _check_screen_kinds() -> void:
	var wanted := {}
	for kind in HUD_KINDS:
		wanted[kind] = "the HUD and pause menu"
	for name in DirAccess.get_files_at(CONTENT_DIR):
		if not name.ends_with(".json"):
			continue
		var text := FileAccess.get_file_as_string(CONTENT_DIR + name)
		var regex := RegEx.new()
		regex.compile("\"icon\"\\s*:\\s*\"([A-Za-z_]+)\"")
		for found in regex.search_all(text):
			var kind := found.get_string(1)
			if kind == kind.to_upper():
				kind = String(UiKit.kit().get("mission_table_icons", {}).get(kind, ""))
				_check(not kind.is_empty(), "Mission Table icon id %s maps to a kit kind (%s)" % [found.get_string(1), name])
			wanted[kind] = name
	for kind in wanted:
		_check(UiKit.icon_texture(String(kind)) != null, "kind '%s' asked for by %s is in the kit" % [kind, wanted[kind]])

func _check_words() -> void:
	var banned := UiDesign.banned_regex()
	for kind in UiKit.icon_kinds():
		var word := UiKit.icon_word(String(kind))
		_check(not word.is_empty(), "icon %s has a word" % kind)
		_check(banned.search(word) == null, "icon word '%s' is player language" % word)
		_check(word == word.capitalize() or word[0] == word[0].to_upper(), "icon word '%s' is sentence case" % word)
		var row := UiKit.icon_label(String(kind))
		var label := row.get_node_or_null("Word") as Label
		_check(label != null and label.text == word, "icon_label(%s) pairs the icon with its word" % kind)
		row.free()
	for state in UiKit.kit().get("states", {}):
		var word := String(UiKit.kit().states[state].word)
		_check(banned.search(word) == null and not word.is_empty(), "state word '%s' is player language" % word)
	for role in UiKit.kit().get("roles", {}):
		var role_word := String(UiKit.kit().roles[role].role)
		_check(banned.search(role_word) == null, "role word '%s' is player language" % role_word)

func _check_contrast() -> void:
	var ink := UiDesign.colour("ink")
	var glass := UiKit.composite(UiDesign.colour("glass"), ink)
	var pairs := [
		["ivory on navy", UiDesign.colour("ivory"), UiDesign.colour("navy"), 4.5],
		["ivory on glass over space black", UiDesign.colour("ivory"), glass, 4.5],
		["muted on glass", UiDesign.colour("muted"), glass, 4.5],
		["accent on glass", UiDesign.colour("accent"), glass, 4.5],
		["ink on accent (hover button)", ink, UiDesign.colour("accent"), 4.5],
		["caution on glass", UiDesign.colour("caution"), glass, 3.0],
		["danger on glass", UiDesign.colour("danger"), glass, 3.0],
		["good on glass", UiDesign.colour("good"), glass, 3.0],
	]
	for pair in pairs:
		var ratio := UiKit.contrast_ratio(pair[1], pair[2])
		_check(ratio >= float(pair[3]), "%s contrast %.1f:1 (needs %.1f)" % [pair[0], ratio, pair[3]])
	_check(absf(UiKit.contrast_ratio(Color.WHITE, Color.BLACK) - 21.0) < 0.01, "contrast formula: white on black is 21:1")

func _check_meters() -> void:
	var cases := [[72.0, 100.0, "good", "OK"], [40.0, 100.0, "caution", "Low"], [10.0, 100.0, "danger", "Critical"], [250.0, 100.0, "good", "OK"], [-5.0, 100.0, "danger", "Critical"], [3.0, 0.0, "danger", "Critical"]]
	for item in cases:
		var meter := UiKit.meter("water", float(item[0]), float(item[1]), "%")
		var level := meter.get_node_or_null("IconLabel_water/Level") as Label
		var bar := meter.get_node_or_null("Bar") as ProgressBar
		_check(String(meter.get_meta("level")) == String(item[2]), "meter %s/%s is level %s (%s)" % [item[0], item[1], item[2], meter.get_meta("level")])
		_check(level != null and level.text == String(item[3]), "meter %s/%s says its level in a word: %s" % [item[0], item[1], level.text if level else "missing"])
		_check(bar != null and bar.value >= 0.0 and bar.value <= 1.0, "meter bar stays within 0..1 for %s/%s" % [item[0], item[1]])
		var word := meter.get_node_or_null("IconLabel_water/Word") as Label
		_check(word != null and word.text == "Water", "meter names its resource in a word")
		meter.free()
	var full := UiKit.meter("power", 100.0, 100.0, "%")
	_check(absf(float(full.get_meta("fraction")) - 1.0) < 0.001, "a full meter is 1.0")
	full.free()

func _check_sources() -> void:
	var origins: Dictionary = UiDesign.text().get("dialogue", {}).get("origins", {})
	_check(origins.size() >= 5, "ui_text.json lists the dialogue origins")
	for origin in origins:
		var chip := UiKit.source_chip(String(origin))
		var word := String(origins[origin])
		if word.is_empty():
			_check(chip == null, "%s (local live speech) has no chip" % origin)
			continue
		_check(chip != null, "%s has a source chip" % origin)
		if chip == null:
			continue
		_check(String(chip.get_meta("source_word")) == word, "%s chip says '%s'" % [origin, word])
		_check(chip.find_child("Icon_*", true, false) != null, "%s chip carries its icon" % origin)
		chip.free()
	var lower := UiKit.source_chip("earth link")
	_check(lower != null and String(lower.get_meta("source_word")) == "Earth link", "origin labels match in any case")
	if lower:
		lower.free()

func _check_roles_and_states() -> void:
	for role in ["kai", "amara", "rafi", "mei", "ferreira", "rao"]:
		var marker := UiKit.role_marker(role)
		var dot := marker.get_node_or_null("Dot") as Panel
		var name_label := marker.get_node_or_null("Name") as Label
		var style := dot.get_theme_stylebox("panel") as StyleBoxFlat if dot else null
		var expected := UiDesign.colour(String(UiKit.kit().roles[role].colour))
		_check(style != null and style.bg_color.is_equal_approx(expected), "%s marker uses the ART_BIBLE role colour" % role)
		_check(name_label != null and name_label.text == String(UiKit.kit().roles[role].name), "%s marker names the person" % role)
		_check((marker.get_node_or_null("RoleWord") as Label).text != "", "%s marker names the role in a word" % role)
		marker.free()
	for state in ["empty", "error", "loading", "disabled", "unknown"]:
		var card := UiKit.state_card(state, "detail line")
		var word := card.find_child("Word", true, false) as Label
		_check(word != null and not word.text.is_empty(), "state card '%s' says its state in words: %s" % [state, word.text if word else ""])
		_check(card.find_child("Detail", true, false) != null, "state card '%s' shows the detail line" % state)
		card.free()

func _check_targets_and_theme() -> void:
	var key := UiKit.key_glyph("E")
	_check(key.custom_minimum_size.x >= 44 and key.custom_minimum_size.y >= 44, "key glyph is at least 44 px")
	key.free()
	var button := UiDesign.button("Continue")
	_check(button.custom_minimum_size.y >= 44, "kit buttons are at least 44 px tall")
	button.free()
	var theme := UiKit.theme()
	var normal := theme.get_stylebox("normal", "Button") as StyleBoxFlat
	_check(normal != null and normal.bg_color.is_equal_approx(UiDesign.colour("navy")), "theme Button normal is the navy token")
	var hover := theme.get_stylebox("hover", "Button") as StyleBoxFlat
	_check(hover != null and hover.bg_color.is_equal_approx(UiDesign.colour("accent")), "theme Button hover is the accent token")
	_check(theme.get_color("font_color", "Label").is_equal_approx(UiDesign.colour("ivory")), "theme Label colour is ivory")
	_check(theme.default_font_size == int(UiDesign.tokens().type.body), "theme default font size is the body token")
	for kind in ["PanelContainer/panel", "ProgressBar/fill", "HSlider/grabber_area", "LineEdit/normal", "HSeparator/separator"]:
		var parts := String(kind).split("/")
		_check(theme.has_stylebox(parts[1], parts[0]), "theme styles %s" % kind)
	_check(ResourceLoader.exists(UiKit.THEME_PATH), "the Theme resource is saved at " + UiKit.THEME_PATH)
	var saved := load(UiKit.THEME_PATH) as Theme
	var saved_normal := saved.get_stylebox("normal", "Button") as StyleBoxFlat if saved else null
	_check(saved_normal != null and saved_normal.bg_color.is_equal_approx(UiDesign.colour("navy")), "saved lla_theme.tres matches the token navy (rebuild with build_ui_theme.gd)")
	_check(saved != null and saved.default_font_size == theme.default_font_size, "saved lla_theme.tres has the token body size")

func _check_reflow() -> void:
	var host := Control.new()
	host.size = Vector2(1280, 720)
	root.add_child(host)
	var panel := UiDesign.glass_panel()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	for kind in ["power", "life", "water", "shielding"]:
		column.add_child(UiKit.meter(kind, 72.0, 100.0, "%"))
	var chips := HBoxContainer.new()
	for origin in ["EARTH LINK", "LOCAL RADIO", "STORED RECORDING", "QUEUED TEXT"]:
		chips.add_child(UiKit.source_chip(origin))
	column.add_child(chips)
	column.add_child(UiKit.role_marker("rafi"))
	column.add_child(UiKit.state_card("error", "The station could not read the gauge. Try again from the panel."))
	column.add_child(UiDesign.button("Continue"))
	host.add_child(panel)
	var safe := 1280.0 - 2.0 * UiDesign.px(64.0, 720.0)
	# Wrapping labels size their height from the width they get, so give the panel the safe width first.
	panel.size = Vector2(safe, 0)
	for scale in [1.0, 1.5]:
		UiDesign.apply_type(panel, 720.0, float(scale))
		await process_frame
		await process_frame
		var needed := panel.get_combined_minimum_size()
		_check(needed.x <= safe, "kit sample fits the 720p safe width at %d%% text (%.0f of %.0f px)" % [int(scale * 100), needed.x, safe])
		_check(needed.y <= 720.0 - 2.0 * UiDesign.px(64.0, 720.0), "kit sample fits the 720p safe height at %d%% text (%.0f px)" % [int(scale * 100), needed.y])
		var want_icon := UiDesign.px(float(UiKit.icon_px()) * float(scale), 720.0)
		for node in panel.find_children("Icon_*", "TextureRect", true, false):
			_check((node as Control).custom_minimum_size == Vector2(want_icon, want_icon), "icon %s grows with the text: %d px at %d%% text" % [node.name, want_icon, int(scale * 100)])
	for node in panel.find_children("*", "Label", true, false):
		var label := node as Label
		_check(label.size.x > 8.0 or label.text.is_empty(), "label '%s' keeps its width in a row (%.0f px), never one character per line" % [label.text, label.size.x])
	for node in panel.find_children("*", "Button", true, false):
		_check((node as Control).get_combined_minimum_size().y >= 44, "button keeps a 44 px target at 150%% text (%.0f)" % (node as Control).get_combined_minimum_size().y)
	host.free()
	await process_frame

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL " + message)
