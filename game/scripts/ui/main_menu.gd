extends Control
class_name MainMenu

signal new_expedition_requested
signal continue_requested
signal science_requested
signal showcase_requested
signal command_emitted(command: Dictionary)
signal accessibility_requested

const NAVY := Color("#1F2A44")
const INK := Color("#05060A")
const IVORY := Color("#ECEEF0")
const MUTED := Color("#A8B4C8")
const MUSTARD := Color("#F2C230")
const ORANGE := Color("#F26B21")
const CYAN := Color("#20B8C9")
const GREEN := Color("#4CAF50")
const PURPLE := Color("#8E5CC2")
const PANELS_SCENE: PackedScene = preload("res://scenes/ui/campaign_panels.tscn")
const CrewScript = preload("res://scripts/crew/crew_modes.gd")

var _continue_button: Button
var _begin_button: Button
var _briefing_start_button: Button
var _save_note: Label
var _briefing: PanelContainer
var _science: PanelContainer
var _large_text := false
var _query: Dictionary = {}
var _command_sink: Callable
var _panels: CampaignPanels
var _modal_focus: Control
var _modal_states: Dictionary = {}
var _accessibility := {
	"captions": true,
	"large_text": false,
	"timer_free": true,
	"reduced_motion": false,
}
var _footer_status: Label
## Crew chosen in the briefing: Solo (one player, all roles) or Class 2–4.
var _crew: Dictionary = {}
var _crew_buttons: Dictionary = {}
var _crew_summary: Label
var _crew_seats: Label

func _ready() -> void:
	var loaded_theme := load("res://resources/ui/lla_theme.tres") as Theme
	if loaded_theme != null:
		theme = loaded_theme
	_build()

func setup(save_state: Dictionary) -> void:
	_query = save_state.duplicate(true)
	var supplied = _query.get("accessibility", _query.get("settings", {}))
	if supplied is Dictionary:
		_set_accessibility_local(supplied as Dictionary)
	if _continue_button == null:
		return
	var has_save := not save_state.is_empty()
	_continue_button.disabled = not has_save
	_continue_button.text = "CONTINUE EXPEDITION" if has_save else "CONTINUE · NO CHECKPOINT"
	_save_note.text = "Verified checkpoint: %s" % String(save_state.get("checkpoint_id", "Chapter 1")) if has_save else "No saved expedition yet. New Expedition is always safe to start."
	_save_note.modulate = IVORY if has_save else MUTED
	if _panels != null:
		_panels.bind_query(_query)
	_apply_accessibility()

func bind_query(query: Dictionary) -> void:
	_query = query.duplicate(true)
	var supplied = _query.get("accessibility", _query.get("settings", {}))
	if supplied is Dictionary:
		_set_accessibility_local(supplied as Dictionary)
	if _panels != null:
		_panels.bind_query(_query)
	_apply_accessibility()

func set_command_sink(sink: Callable) -> void:
	_command_sink = sink
	if _panels != null:
		_panels.set_command_sink(sink)

func query_snapshot() -> Dictionary:
	return _query.duplicate(true)

func accessibility_settings() -> Dictionary:
	return _accessibility.duplicate(true)

## The crew setting New Expedition starts with ({"mode", "players"}).
func crew_settings() -> Dictionary:
	return CrewScript.normalise(_crew)

## Chooses the crew for the next expedition; invalid input falls back to Solo.
func set_crew(crew: Dictionary) -> void:
	_crew = CrewScript.normalise(crew)
	_refresh_crew_choice()

func captions_visible() -> bool:
	return bool(_accessibility.get("captions", true))

func is_timer_free() -> bool:
	return bool(_accessibility.get("timer_free", true))

func is_reduced_motion() -> bool:
	return bool(_accessibility.get("reduced_motion", false))

func text_scale() -> float:
	return 1.5 if bool(_accessibility.get("large_text", false)) else 1.0

func presentation_transition_seconds() -> float:
	return 0.0 if is_reduced_motion() else 0.15

func set_accessibility(settings: Dictionary) -> void:
	_set_accessibility_local(settings)
	if _panels != null:
		_panels.set_accessibility(settings)
	_apply_accessibility()

func open_panel(panel_id: String, data: Dictionary = {}) -> bool:
	if _panels == null:
		return false
	return _panels.open_panel(panel_id, data)

func command_for(verb: String, target_id: String = "", payload: Dictionary = {}) -> Dictionary:
	var revision := int(_query.get("state_revision", 0))
	return {
		"command_id": "menu:%s:%s:%d" % [verb, target_id, revision],
		"issuer": "main_menu",
		"owning_mission_id": String(_query.get("mission_id", "")),
		"owning_scene_id": String(_query.get("scene_id", "")),
		"expected_state_revision": revision,
		"target_id": target_id,
		"verb": verb,
		"payload": payload.duplicate(true),
	}

func emit_command(verb: String, target_id: String = "", payload: Dictionary = {}) -> Dictionary:
	var command := command_for(verb, target_id, payload)
	command_emitted.emit(command.duplicate(true))
	if _command_sink.is_valid():
		_command_sink.call(command.duplicate(true))
	return command

func open_science() -> void:
	_capture_modal_focus()
	_science.show()
	_set_buttons_enabled(false, _science)
	var close := _science.get_node_or_null("Margin/Content/BackToTitle") as Button
	if close != null:
		close.grab_focus()

func close_science() -> void:
	_science.hide()
	_set_buttons_enabled(true)
	_restore_modal_focus()

func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = INK
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	# Quiet geometry makes the title feel like a mission console without adding unapproved art.
	_add_glow_panel(Vector2(0.66, 0.0), Vector2(1.0, 0.92), Color(0.10, 0.16, 0.27, 0.62))
	_add_glow_panel(Vector2(0.0, 0.86), Vector2(1.0, 1.0), Color(0.12, 0.08, 0.17, 0.9))

	var margins := MarginContainer.new()
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margins.add_theme_constant_override("margin_left", 58)
	margins.add_theme_constant_override("margin_right", 58)
	margins.add_theme_constant_override("margin_top", 34)
	margins.add_theme_constant_override("margin_bottom", 30)
	add_child(margins)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 20)
	margins.add_child(page)
	page.add_child(_build_header())
	var scroll := ScrollContainer.new()
	scroll.name = "TitleContentScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	page.add_child(scroll)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 26)
	scroll.add_child(body)
	body.add_child(_build_command_panel())
	body.add_child(_build_diorama_panel())
	page.add_child(_build_footer())

	_build_briefing()
	_build_science()
	_panels = PANELS_SCENE.instantiate() as CampaignPanels
	_panels.name = "CampaignPanels"
	_panels.bind_query(_query)
	add_child(_panels)
	_panels.panel_opened.connect(_on_panel_opened)
	_panels.panel_closed.connect(_on_panel_closed)
	_panels.accessibility_changed.connect(_on_accessibility_changed)
	_apply_accessibility()

func _build_header() -> Control:
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 72
	header.add_theme_constant_override("separation", 16)
	var mark := Label.new()
	mark.text = "◒"
	mark.modulate = MUSTARD
	mark.add_theme_font_size_override("font_size", 38)
	header.add_child(mark)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 0)
	header.add_child(stack)
	var title := Label.new()
	title.text = "LAST LIGHT ACADEMY"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", IVORY)
	stack.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "AURORA STATION  /  SOUTH-POLAR TRAINING SCENARIO"
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", CYAN)
	stack.add_child(subtitle)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var tag := Label.new()
	tag.text = "SPACE APPS 2026\nJUNIOR ASTRONAUT MISSION TRAINER"
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tag.add_theme_font_size_override("font_size", 13)
	tag.add_theme_color_override("font_color", MUSTARD)
	header.add_child(tag)
	return header

func _build_command_panel() -> Control:
	var panel := _panel(Color(0.08, 0.12, 0.20, 0.96), 18, Color(0.32, 0.43, 0.60, 0.55))
	panel.custom_minimum_size = Vector2(480, 0)
	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 14)
	margin.add_child(content)
	var eyebrow := Label.new()
	eyebrow.text = "MISSION CONTROL / OFFLINE READY"
	eyebrow.add_theme_font_size_override("font_size", 13)
	eyebrow.add_theme_color_override("font_color", CYAN)
	content.add_child(eyebrow)
	var heading := Label.new()
	heading.text = "Run a real\nmission decision."
	heading.add_theme_font_size_override("font_size", 32)
	heading.add_theme_color_override("font_color", IVORY)
	content.add_child(heading)
	var copy := Label.new()
	copy.text = "Observe → discuss → preview → commit → learn.\nYour first choice changes what the crew can see next."
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_theme_font_size_override("font_size", 17)
	copy.add_theme_color_override("font_color", MUTED)
	content.add_child(copy)
	var divider := HSeparator.new()
	divider.modulate = Color(0.40, 0.52, 0.72, 0.45)
	content.add_child(divider)
	_begin_button = _button("NEW EXPEDITION  ›", MUSTARD, INK)
	_begin_button.pressed.connect(_show_briefing)
	content.add_child(_begin_button)
	_continue_button = _button("CONTINUE · NO CHECKPOINT", Color(0.15, 0.20, 0.31), IVORY)
	_continue_button.pressed.connect(func() -> void:
		emit_command("continue_campaign", "campaign")
		continue_requested.emit()
	)
	content.add_child(_continue_button)
	_save_note = Label.new()
	_save_note.text = "No saved expedition yet. New Expedition is always safe to start."
	_save_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_save_note.add_theme_font_size_override("font_size", 13)
	_save_note.add_theme_color_override("font_color", MUTED)
	content.add_child(_save_note)
	var lower_spacer := Control.new()
	lower_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(lower_spacer)
	var science_button := _button("SCIENCE + SOURCES", Color(0.12, 0.18, 0.28), IVORY)
	science_button.pressed.connect(func() -> void: science_requested.emit())
	content.add_child(science_button)
	# Developer tool: offered only in debug/editor builds, never to players.
	if OS.is_debug_build():
		var showcase_button := _button("DEVELOPER ASSET SHOWCASE", Color(0.10, 0.14, 0.22), MUTED)
		showcase_button.pressed.connect(func() -> void: showcase_requested.emit())
		content.add_child(showcase_button)
	var settings_button := _button("SETTINGS / ACCESSIBILITY", Color(0.10, 0.14, 0.22), IVORY)
	settings_button.pressed.connect(func() -> void:
		emit_command("open_panel", "settings_accessibility")
		accessibility_requested.emit()
		open_panel("settings_accessibility")
	)
	content.add_child(settings_button)
	var credits_button := _button("CREDITS", Color(0.10, 0.14, 0.22), MUTED)
	credits_button.pressed.connect(func() -> void:
		emit_command("open_panel", "credits")
		open_panel("credits")
	)
	content.add_child(credits_button)
	return panel

func _build_diorama_panel() -> Control:
	var panel := _panel(Color(0.06, 0.08, 0.14, 0.74), 18, Color(0.95, 0.76, 0.22, 0.38))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	margin.add_child(content)
	var label := Label.new()
	label.text = "THE TRAINING QUESTION"
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", MUSTARD)
	content.add_child(label)
	var quote := Label.new()
	quote.text = "How do you keep people safe\nwhen power, air, shielding\nand a living garden share\none small station?"
	quote.add_theme_font_size_override("font_size", 26)
	quote.add_theme_color_override("font_color", IVORY)
	quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(quote)
	var diagram := HBoxContainer.new()
	diagram.add_theme_constant_override("separation", 8)
	content.add_child(diagram)
	for item in [["POWER", ORANGE], ["AIR", CYAN], ["CARE", GREEN], ["SAFETY", PURPLE]]:
		var card := _mini_card(item[0], item[1])
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		diagram.add_child(card)
	var line := Label.new()
	line.text = "Chapter 1: twelve caption-first scenes\nfor judges, classrooms and families."
	line.add_theme_font_size_override("font_size", 16)
	line.add_theme_color_override("font_color", MUTED)
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(line)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer)
	var disclosure := Label.new()
	disclosure.text = "SIMULATED · Aurora Station, cadets and 2046 timeline are fictional.\nScience displays identify observed, computed and simulated content."
	disclosure.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	disclosure.add_theme_font_size_override("font_size", 13)
	disclosure.add_theme_color_override("font_color", Color(0.72, 0.80, 0.91, 1))
	content.add_child(disclosure)
	return panel

func _build_footer() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var left := Label.new()
	_footer_status = left
	left.text = _accessibility_footer()
	left.add_theme_font_size_override("font_size", 12)
	left.add_theme_color_override("font_color", MUTED)
	row.add_child(left)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	var right := Label.new()
	right.text = "INDEPENDENT TEAM PROJECT  ·  NOT NASA-ENDORSED"
	right.add_theme_font_size_override("font_size", 12)
	right.add_theme_color_override("font_color", Color(0.64, 0.72, 0.84, 1))
	row.add_child(right)
	return row

func _build_briefing() -> void:
	_briefing = _panel(Color(0.03, 0.05, 0.10, 0.98), 18, Color(0.95, 0.76, 0.22, 0.75))
	_briefing.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_briefing.position = Vector2(-390, -320)
	_briefing.size = Vector2(780, 640)
	_briefing.hide()
	add_child(_briefing)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	_briefing.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)
	var title := Label.new()
	title.text = "MISSION BRIEFING  /  CHAPTER 1"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", MUSTARD)
	content.add_child(title)
	var copy := Label.new()
	copy.text = "Aurora Station is preparing for a 36-hour training scenario at the Moon's south pole.\n\nKeep the crew safe.\nKeep the station running.\nCare for Alo inside a pressurised chamber."
	copy.add_theme_font_size_override("font_size", 18)
	copy.add_theme_color_override("font_color", IVORY)
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(copy)
	var loop := Label.new()
	loop.text = "OBSERVE  →  DISCUSS  →  CHOOSE  →  EXECUTE  →  SEE IMPACT  →  DEBRIEF"
	loop.add_theme_font_size_override("font_size", 14)
	loop.add_theme_color_override("font_color", CYAN)
	loop.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(loop)
	var roles := GridContainer.new()
	roles.columns = 2
	roles.add_theme_constant_override("h_separation", 10)
	roles.add_theme_constant_override("v_separation", 10)
	content.add_child(roles)
	for item in [["KAI", "POWER & HEAT", ORANGE], ["AMARA", "AIR & MEASUREMENT", CYAN], ["MEI", "GARDEN & PLANT CARE", GREEN], ["RAFI", "SAFETY & FIELD OPERATIONS", PURPLE]]:
		roles.add_child(_role_card(item[0], item[1], item[2]))
	content.add_child(_build_crew_choice())
	var qualifier := Label.new()
	qualifier.text = "SIMULATED · Training scenario\nThe station, cadets, 2046 dates and game resources are fictional."
	qualifier.add_theme_font_size_override("font_size", 13)
	qualifier.add_theme_color_override("font_color", MUTED)
	content.add_child(qualifier)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 10)
	content.add_child(actions)
	var cancel := _button("CANCEL", Color(0.12, 0.16, 0.24), MUTED)
	cancel.pressed.connect(_hide_briefing)
	actions.add_child(cancel)
	_briefing_start_button = _button("ENTER AURORA  ›", MUSTARD, INK)
	_briefing_start_button.pressed.connect(func() -> void:
		_hide_briefing()
		emit_command("new_campaign", "campaign", {"crew": crew_settings()})
		new_expedition_requested.emit()
	)
	actions.add_child(_briefing_start_button)

## Solo or Class (2–4 players on this machine). Every word and the seat plans
## come from crew_modes.json; the choice travels with the new expedition.
func _build_crew_choice() -> Control:
	var box := VBoxContainer.new()
	box.name = "CrewChoice"
	box.add_theme_constant_override("separation", 6)
	var heading := Label.new()
	heading.text = CrewScript.text("menu", "heading")
	heading.add_theme_font_size_override("font_size", 13)
	heading.add_theme_color_override("font_color", CYAN)
	box.add_child(heading)
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 6)
	box.add_child(row)
	var options: Array = [{"mode": CrewScript.SOLO, "players": 1, "label": CrewScript.text("menu", "solo_button")}]
	var class_info := CrewScript.mode_info(CrewScript.CLASS)
	for count in range(int(class_info.get("players_min", 2)), int(class_info.get("players_max", 4)) + 1):
		options.append({"mode": CrewScript.CLASS, "players": count, "label": CrewScript.text("menu", "class_button", {"players": str(count)})})
	for option in options:
		var button := _button(String(option.label), Color(0.12, 0.18, 0.28), IVORY)
		button.name = "Crew_%s_%d" % [String(option.mode), int(option.players)]
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(0, 44)
		button.add_theme_font_size_override("font_size", 13)
		var choice := {"mode": String(option.mode), "players": int(option.players)}
		button.pressed.connect(func() -> void:
			set_crew(choice)
			button.grab_focus()
		)
		row.add_child(button)
		_crew_buttons[button.name] = button
	_crew_summary = Label.new()
	_crew_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_crew_summary.add_theme_font_size_override("font_size", 13)
	_crew_summary.add_theme_color_override("font_color", IVORY)
	box.add_child(_crew_summary)
	_crew_seats = Label.new()
	_crew_seats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_crew_seats.add_theme_font_size_override("font_size", 12)
	_crew_seats.add_theme_color_override("font_color", MUTED)
	box.add_child(_crew_seats)
	_crew = CrewScript.default_crew()
	_refresh_crew_choice()
	return box

func _refresh_crew_choice() -> void:
	if _crew_summary == null:
		return
	var crew := crew_settings()
	for name in _crew_buttons:
		var button := _crew_buttons[name] as Button
		var selected: bool = name == "Crew_%s_%d" % [String(crew.mode), int(crew.players)]
		button.button_pressed = selected
		button.text = ("● " if selected else "") + String(button.get_meta("lla_label", button.text.trim_prefix("● ")))
		button.set_meta("lla_label", button.text.trim_prefix("● "))
		if selected:
			button.add_theme_stylebox_override("normal", _button_style(Color("#2C3D63"), 1.0, MUSTARD))
			button.add_theme_stylebox_override("pressed", _button_style(Color("#2C3D63"), 1.0, MUSTARD))
		else:
			button.add_theme_stylebox_override("normal", _button_style(Color(0.12, 0.18, 0.28), 0.88))
			button.add_theme_stylebox_override("pressed", _button_style(Color("#D8A915"), 1.0))
	_crew_summary.text = String(CrewScript.mode_info(String(crew.mode)).get("summary", ""))
	if CrewScript.is_class(crew):
		_crew_seats.text = CrewScript.text("menu", "seat_plan_prefix") + CrewScript.seat_plan_text(crew) + "\n" + CrewScript.text("menu", "print_hint")
	else:
		_crew_seats.text = CrewScript.text("menu", "print_hint")

func _build_science() -> void:
	_science = _panel(Color(0.03, 0.05, 0.10, 0.99), 18, Color(0.13, 0.72, 0.78, 0.68))
	_science.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_science.position = Vector2(-480, -320)
	_science.size = Vector2(960, 640)
	_science.hide()
	add_child(_science)
	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	_science.add_child(margin)
	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)
	var title := Label.new()
	title.text = "SCIENCE + SOURCES"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", CYAN)
	content.add_child(title)
	var intro := Label.new()
	intro.text = "Every decision is labelled by what the player can responsibly know.\nThis demo keeps the Aurora scenario fictional and does not hide an unbundled NASA data claim."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_font_size_override("font_size", 16)
	intro.add_theme_color_override("font_color", IVORY)
	content.add_child(intro)
	# Rows and disclosure scroll, so BACK TO TITLE stays on screen at 1.5x text.
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	var cards := VBoxContainer.new()
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override("separation", 8)
	scroll.add_child(cards)
	cards.add_child(_source_row("SIMULATED", "Aurora Station / 2046 mission", "Fictional station, cadets, dates and game resources. Used for the training scenario."))
	cards.add_child(_source_row("TRAINING SCENARIO", "36-hour night and Earth-link cutoff", "The night is sized to a published Shackleton-rim site (Mazarico et al. 2011). In the computed April 2046 sky (JPL Horizons), Earth is below the exact pole's horizon and rising all night, so the shift-4 Earth-link cutoff is an authored training event."))
	cards.add_child(_source_row("OBSERVED + COMPUTED", "Chapter 1 sources (each Data Card shows its dataset ID and link)", "NASA JPL Horizons (Sun and Earth positions) · NASA DONKI and NOAA GOES-13 (the 10 Sep 2017 storm) · LRO LOLA illumination study, Mazarico et al. 2011 · NASA BVAD 2022 (air and food) · NASA 10 kW solar array study · Townsend et al. 1988 and Clowdsley 2021, NASA Langley (water shielding) · NASA OSDR and Wisconsin Fast Plants (Brassica rapa)."))
	cards.add_child(_source_row("DOCUMENTED", "NASA Space Apps Challenge 2026", "Made by an independent team for the challenge. No NASA endorsement is implied."))
	var disclosure := Label.new()
	disclosure.text = "AI disclosure: AI tools made this game's 3D models and animation, cutscene images and video, and all voices, music and sound effects, and wrote the game code to the team's specifications. The story, dialogue, puzzle rules, numbers and science mapping are the team's. Every generation is logged in production/AI_PROMPT_LOG.md (summary: docs/AI_USE.md).\nAccessibility: captions, readable text, pause-safe decisions and timer-free progression are the default route."
	disclosure.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	disclosure.add_theme_font_size_override("font_size", 13)
	disclosure.add_theme_color_override("font_color", MUTED)
	cards.add_child(disclosure)
	var close := _button("BACK TO TITLE", Color(0.12, 0.18, 0.28), IVORY)
	close.name = "BackToTitle"
	close.pressed.connect(close_science)
	content.add_child(close)

func _show_briefing() -> void:
	_capture_modal_focus()
	_briefing.show()
	_set_buttons_enabled(false, _briefing)
	_briefing_start_button.grab_focus()

func _hide_briefing() -> void:
	_briefing.hide()
	_set_buttons_enabled(true)
	_restore_modal_focus()

func _on_panel_opened(_panel_id: String) -> void:
	if _briefing.visible or _science.visible:
		return
	_capture_modal_focus()
	_set_buttons_enabled(false, _panels)

func _on_panel_closed(_panel_id: String) -> void:
	if _briefing.visible or _science.visible:
		return
	_set_buttons_enabled(true)
	# CampaignPanels restores its own captured focus. This fallback handles a
	# caller that closes after the original control was removed.
	_restore_modal_focus()

func _capture_modal_focus() -> void:
	_modal_focus = null
	if get_viewport() == null:
		return
	var focused := get_viewport().gui_get_focus_owner()
	if _can_restore_focus(focused):
		_modal_focus = focused as Control

func _restore_modal_focus() -> void:
	var candidate := _modal_focus
	_modal_focus = null
	if _can_restore_focus(candidate):
		candidate.grab_focus()
		return
	if _can_restore_focus(_begin_button):
		_begin_button.grab_focus()

func _set_buttons_enabled(enabled: bool, modal: Control = null) -> void:
	if enabled:
		for control in _modal_states.keys():
			if not is_instance_valid(control):
				continue
			var state: Dictionary = _modal_states[control]
			if control is BaseButton:
				(control as BaseButton).disabled = bool(state.get("disabled", false))
			control.focus_mode = int(state.get("focus_mode", Control.FOCUS_NONE))
			control.mouse_filter = int(state.get("mouse_filter", Control.MOUSE_FILTER_IGNORE))
		_modal_states.clear()
		return
	_modal_states.clear()
	_set_controls_enabled(self, modal)

func _set_controls_enabled(node: Node, modal: Control) -> void:
	if node is Control and node != self:
		var control := node as Control
		if modal != null and (control == modal or modal.is_ancestor_of(control)):
			return
		_modal_states[control] = {
			"disabled": (control as BaseButton).disabled if control is BaseButton else false,
			"focus_mode": control.focus_mode,
			"mouse_filter": control.mouse_filter,
		}
		if control is BaseButton:
			(control as BaseButton).disabled = true
		control.focus_mode = Control.FOCUS_NONE
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_controls_enabled(child, modal)

func _can_restore_focus(candidate: Control) -> bool:
	if not is_instance_valid(candidate) or not candidate.is_inside_tree() or not candidate.is_visible_in_tree():
		return false
	if candidate.focus_mode == Control.FOCUS_NONE:
		return false
	if candidate is BaseButton and (candidate as BaseButton).disabled:
		return false
	return true

func _on_accessibility_changed(settings: Dictionary) -> void:
	_set_accessibility_local(settings)
	_apply_accessibility()

func _set_accessibility_local(settings: Dictionary) -> void:
	for key in _accessibility.keys():
		if settings.has(key):
			_accessibility[key] = bool(settings[key])

func _accessibility_footer() -> String:
	var captions := "CAPTIONS ON" if captions_visible() else "CAPTIONS OFF"
	var timing := "TIMER-FREE" if is_timer_free() else "STANDARD TIMING"
	return captions + "  •  " + timing + "  •  ENGLISH UI"

func _apply_accessibility() -> void:
	if not is_inside_tree():
		return
	if _footer_status != null:
		_footer_status.text = _accessibility_footer()
	set_meta("accessibility_settings", _accessibility.duplicate(true))
	set_meta("presentation_transition_seconds", presentation_transition_seconds())
	_apply_text_scale(self)

func _apply_text_scale(node: Node) -> void:
	for child in node.get_children():
		if child == _panels or (_panels != null and _panels.is_ancestor_of(child)):
			continue
		if child is Control:
			var control := child as Control
			if not control.has_meta("lla_base_font_size"):
				var base_size := control.get_theme_font_size("font_size")
				if base_size > 0:
					control.set_meta("lla_base_font_size", base_size)
			if control.has_meta("lla_base_font_size"):
				control.add_theme_font_size_override("font_size", int(round(float(control.get_meta("lla_base_font_size")) * text_scale())))
		_apply_text_scale(child)

func _add_glow_panel(anchor: Vector2, end_anchor: Vector2, color: Color) -> void:
	var panel := ColorRect.new()
	panel.color = color
	panel.anchor_left = anchor.x
	panel.anchor_top = anchor.y
	panel.anchor_right = end_anchor.x
	panel.anchor_bottom = end_anchor.y
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	move_child(panel, 1)

func _panel(color: Color, radius: int, border: Color = Color.TRANSPARENT) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	if border.a > 0.0:
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = border
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _button(text: String, fill: Color, text_color: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 48)
	button.focus_mode = Control.FOCUS_ALL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	button.add_theme_stylebox_override("normal", _button_style(fill, 0.88))
	button.add_theme_stylebox_override("hover", _button_style(MUSTARD if fill != MUSTARD else Color("#FFD95A"), 1.0))
	button.add_theme_stylebox_override("pressed", _button_style(Color("#D8A915"), 1.0))
	button.add_theme_stylebox_override("focus", _button_style(Color(fill, 1.0), 1.0, MUSTARD))
	button.add_theme_stylebox_override("disabled", _button_style(Color(0.12, 0.16, 0.24, 0.55), 0.55))
	return button

func _button_style(color: Color, alpha: float, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color, alpha)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 16
	style.content_margin_right = 16
	if border.a > 0.0:
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = border
	return style

func _mini_card(label: String, color: Color) -> PanelContainer:
	var panel := _panel(Color(color, 0.18), 10, Color(color, 0.58))
	var text := Label.new()
	text.text = "●\n" + label
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.custom_minimum_size = Vector2(0, 70)
	text.add_theme_font_size_override("font_size", 14)
	text.add_theme_color_override("font_color", color)
	panel.add_child(text)
	return panel

func _role_card(name: String, role: String, color: Color) -> PanelContainer:
	var panel := _panel(Color(color, 0.13), 8, Color(color, 0.45))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var text := Label.new()
	text.text = name + "  /  " + role
	text.add_theme_font_size_override("font_size", 13)
	text.add_theme_color_override("font_color", IVORY)
	margin.add_child(text)
	return panel

func _source_row(kind: String, title: String, body: String) -> Control:
	var panel := _panel(Color(0.09, 0.14, 0.23, 0.9), 8, Color(0.25, 0.37, 0.55, 0.55))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var text := Label.new()
	text.text = kind + "  ·  " + title + "\n" + body
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size", 13)
	text.add_theme_color_override("font_color", IVORY)
	margin.add_child(text)
	return panel
