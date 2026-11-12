extends Control
class_name MainMenu

signal new_expedition_requested
signal continue_requested
signal slot_continue_requested(snapshot: Dictionary)
signal science_requested
signal showcase_requested
signal trainer_requested
signal moon_trainer_requested
signal chapter_select_requested
signal command_emitted(command: Dictionary)
signal accessibility_requested

const NAVY := Color("#12151F")
const INK := Color("#0A101C")
const IVORY := Color("#F2EFE7")
const MUTED := Color("#B8C4D6")
const MUSTARD := Color("#3AA0FF")
const ORANGE := Color("#F26B21")
const CYAN := Color("#FF6B9D")
const GREEN := Color("#4CAF50")
const PURPLE := Color("#8E5CC2")
const PANELS_SCENE: PackedScene = preload("res://scenes/ui/campaign_panels.tscn")

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
var defer_panels := false
var _modal_focus: Control
var _modal_states: Dictionary = {}
var _accessibility := {
	"captions": true,
	"large_text": false,
	"timer_free": true,
	"reduced_motion": false,
}
var _assist_mode := "Cadet"
var _assist_summary: Label
var _footer_status: Label
var _settings_menu: SettingsMenu
var save_path := SaveService.DEFAULT_PATH
var _profile_accessibility: Dictionary = {}

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
	var continue_focus := Control.FOCUS_ALL if has_save else Control.FOCUS_NONE
	if _modal_states.has(_continue_button):
		var state: Dictionary = _modal_states[_continue_button]
		state["disabled"] = not has_save
		state["focus_mode"] = continue_focus
	else:
		if not has_save and _continue_button.has_focus() and _can_restore_focus(_begin_button):
			_begin_button.grab_focus()
		_continue_button.disabled = not has_save
		_continue_button.focus_mode = continue_focus
	_continue_button.text = "Continue expedition" if has_save else "Continue - no checkpoint"
	_save_note.text = "Checkpoint: %s" % String(save_state.get("checkpoint_id", "Chapter 1")) if has_save else "A new expedition awaits. Your progress saves as you play."
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
	var copy := _profile_accessibility.merged(_accessibility, true)
	copy["assist_mode"] = _assist_mode
	# Full Settings owns its key map; an old checkpoint's E/H shortcut is not an override.
	copy["bindings"] = {} if not _profile_accessibility.is_empty() else (_panels.bindings_snapshot() if _panels != null else {})
	return copy

func assist_mode() -> String:
	return _assist_mode

func set_assist_mode(mode_id: String) -> void:
	if not ["Story", "Cadet", "Expedition"].has(mode_id):
		return
	_assist_mode = mode_id
	if _assist_summary != null:
		var descs := {
			"Story": "Story Mode: Gentle guidance, early hints, and stress-free exploration.",
			"Cadet": "Cadet Mode (Default): Standard guidance, 3-step hint ladder, and full science feedback.",
			"Expedition": "Expedition Mode: Minimal automatic nudges; full instrumentation and manual checks.",
		}
		_assist_summary.text = String(descs.get(mode_id, ""))

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
	_begin_button = %NewExpedition
	_continue_button = %Continue
	_save_note = %SaveNote
	_footer_status = %AccessibilityStatus
	_begin_button.pressed.connect(_show_briefing)
	_continue_button.pressed.connect(func() -> void:
		emit_command("continue_campaign", "campaign")
		continue_requested.emit()
	)
	%MissionTrainerEntry.pressed.connect(func(): trainer_requested.emit())
	%MoonTrainerEntry.pressed.connect(func(): moon_trainer_requested.emit())
	%ChapterSelectEntry.pressed.connect(func(): chapter_select_requested.emit())
	%DeveloperShowcaseEntry.visible = OS.has_feature("editor")
	%DeveloperShowcaseEntry.pressed.connect(func(): showcase_requested.emit())
	%ScienceEntry.pressed.connect(func(): science_requested.emit())
	%SettingsEntry.pressed.connect(func() -> void:
		accessibility_requested.emit()
		open_settings()
	)
	%CreditsEntry.pressed.connect(func() -> void:
		emit_command("open_panel", "credits")
		open_panel("credits")
	)
	for button in [_begin_button, _continue_button, %MissionTrainerEntry, %MoonTrainerEntry, %ChapterSelectEntry, %ScienceEntry, %SettingsEntry, %CreditsEntry, %DeveloperShowcaseEntry]:
		button.add_theme_stylebox_override("normal", _button_style(MUSTARD if button == _begin_button else UiDesign.colour("navy"), 1.0 if button == _begin_button else 0.0))
		button.add_theme_stylebox_override("hover", _button_style(Color("#6FB8FF"), 1.0))
		button.add_theme_stylebox_override("pressed", _button_style(Color("#2A82D6"), 1.0))
		button.add_theme_stylebox_override("focus", _button_style(Color.TRANSPARENT, 0.0, INK if button == _begin_button else MUSTARD))
		button.add_theme_stylebox_override("disabled", _button_style(Color.TRANSPARENT, 0.0))
		button.add_theme_color_override("font_color", INK if button == _begin_button else IVORY)
		button.add_theme_color_override("font_focus_color", INK if button == _begin_button else IVORY)
		button.add_theme_color_override("font_hover_color", INK)
		button.add_theme_color_override("font_pressed_color", INK)
	_build_briefing()
	_build_science()
	if not defer_panels:
		attach_panels()
	_apply_accessibility()

func open_settings() -> void:
	if is_instance_valid(_settings_menu):
		return
	_capture_modal_focus()
	_settings_menu = SettingsMenu.new(null, SaveSlots.new(save_path, Chapter1Campaign.restore_session))
	set_accessibility(_settings_menu.game_settings.accessibility_for_campaign())
	_settings_menu.closed.connect(_close_settings)
	_settings_menu.onboarding_reset_requested.connect(func() -> void:
		if _panels == null:
			attach_panels()
		_panels.hint_player.reset_seen())
	_settings_menu.settings_changed.connect(func(snapshot: Dictionary) -> void:
		set_accessibility(snapshot.get("accessibility", {})))
	_settings_menu.slot_loaded.connect(func(_slot_id: String, snapshot: Dictionary) -> void:
		_close_settings()
		slot_continue_requested.emit(snapshot))
	add_child(_settings_menu)
	_set_buttons_enabled(false, _settings_menu)

func _close_settings() -> void:
	if not is_instance_valid(_settings_menu):
		return
	_settings_menu.hide()
	_settings_menu.queue_free()
	_settings_menu = null
	_set_buttons_enabled(true)
	_restore_modal_focus()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _briefing != null and _briefing.visible:
		_hide_briefing()
		get_viewport().set_input_as_handled()
	elif _science != null and _science.visible:
		close_science()
		get_viewport().set_input_as_handled()

func attach_panels() -> void:
	if _panels != null:
		return
	_panels = PANELS_SCENE.instantiate() as CampaignPanels
	_panels.name = "CampaignPanels"
	_panels.bind_query(_query)
	add_child(_panels)
	_panels.panel_opened.connect(_on_panel_opened)
	_panels.panel_closed.connect(_on_panel_closed)
	_panels.accessibility_changed.connect(_on_accessibility_changed)
	_apply_accessibility()

func _build_briefing() -> void:
	_briefing = _panel(Color(0.03, 0.05, 0.10, 0.98), 18, Color(0.227, 0.627, 1.0, 0.75))
	_briefing.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_briefing.position = Vector2(-390, -270)
	_briefing.size = Vector2(780, 540)
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
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	scroll.add_child(body)
	var copy := Label.new()
	copy.text = "Aurora Station is preparing for a 36-hour training scenario at the Moon's south pole.\n\nKeep the crew safe.\nKeep the station running.\nCare for Alo inside a pressurised chamber."
	copy.add_theme_font_size_override("font_size", 18)
	copy.add_theme_color_override("font_color", IVORY)
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(copy)
	var loop := Label.new()
	loop.text = "OBSERVE  →  DISCUSS  →  CHOOSE  →  EXECUTE  →  SEE IMPACT  →  DEBRIEF"
	loop.add_theme_font_size_override("font_size", 14)
	loop.add_theme_color_override("font_color", CYAN)
	loop.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(loop)
	var roles := GridContainer.new()
	roles.columns = 2
	roles.add_theme_constant_override("h_separation", 10)
	roles.add_theme_constant_override("v_separation", 10)
	body.add_child(roles)
	for item in [["KAI", "POWER & HEAT", ORANGE], ["AMARA", "AIR & MEASUREMENT", CYAN], ["MEI", "GARDEN & PLANT CARE", GREEN], ["RAFI", "SPACE WEATHER", PURPLE]]:
		roles.add_child(_role_card(item[0], item[1], item[2]))
	var assist_header := Label.new()
	assist_header.text = "ASSIST MODE  ·  CHANGE ANYTIME IN SETTINGS"
	assist_header.add_theme_font_size_override("font_size", 13)
	assist_header.add_theme_color_override("font_color", MUSTARD)
	body.add_child(assist_header)
	var assist_row := HBoxContainer.new()
	assist_row.name = "AssistModeRow"
	assist_row.add_theme_constant_override("separation", 8)
	body.add_child(assist_row)
	_assist_summary = Label.new()
	_assist_summary.name = "AssistModeSummary"
	_assist_summary.text = "Cadet Mode (Default): Standard guidance, 3-step hint ladder, and full science feedback."
	_assist_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_assist_summary.add_theme_font_size_override("font_size", 13)
	_assist_summary.add_theme_color_override("font_color", IVORY)
	for mode_spec in [
		["Story", "Story Mode: Gentle guidance, early hints, and stress-free exploration."],
		["Cadet", "Cadet Mode (Default): Standard guidance, 3-step hint ladder, and full science feedback."],
		["Expedition", "Expedition Mode: Minimal automatic nudges; full instrumentation and manual checks."],
	]:
		var m_id: String = mode_spec[0]
		var m_desc: String = mode_spec[1]
		var m_btn := _button(m_id.to_upper(), Color(0.14, 0.20, 0.32), IVORY)
		m_btn.name = "AssistMode_" + m_id
		m_btn.focus_mode = Control.FOCUS_ALL
		m_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		m_btn.pressed.connect(func() -> void:
			set_assist_mode(m_id)
			if _panels != null:
				_panels.set_accessibility({"assist_mode": m_id})
		)
		assist_row.add_child(m_btn)
	body.add_child(_assist_summary)
	var qualifier := Label.new()
	qualifier.text = "SIMULATED · Training scenario\nThe station, cadets, 2046 dates and game resources are fictional."
	qualifier.add_theme_font_size_override("font_size", 13)
	qualifier.add_theme_color_override("font_color", MUTED)
	body.add_child(qualifier)
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
		emit_command("new_campaign", "campaign")
		new_expedition_requested.emit()
	)
	actions.add_child(_briefing_start_button)

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
	for key in ["subtitle_size", "subtitle_scale", "session_mode", "family_mode", "class_mode"]:
		if settings.has(key):
			_profile_accessibility[key] = settings[key]
	if not _profile_accessibility.is_empty() and settings.has("large_text") and not settings.has("subtitle_scale"):
		_profile_accessibility["subtitle_scale"] = 1.5 if settings.large_text else 1.0
		_profile_accessibility["subtitle_size"] = "Extra Large" if settings.large_text else "Medium"
	if settings.get("assist_mode", "") in ["Story", "Cadet", "Expedition"]:
		set_assist_mode(String(settings.assist_mode))
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
		if child == _panels or child == _settings_menu or (_panels != null and _panels.is_ancestor_of(child)):
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

func _panel(color: Color, _radius: int, border: Color = Color.TRANSPARENT) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
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
	if fill == MUSTARD:
		button.add_theme_color_override("font_focus_color", INK)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	button.add_theme_stylebox_override("normal", _button_style(fill, 0.88))
	button.add_theme_stylebox_override("hover", _button_style(MUSTARD if fill != MUSTARD else Color("#6FB8FF"), 1.0))
	button.add_theme_stylebox_override("pressed", _button_style(Color("#2A82D6"), 1.0))
	button.add_theme_stylebox_override("focus", _button_style(Color.TRANSPARENT, 0.0, INK if fill == MUSTARD else MUSTARD))
	button.add_theme_stylebox_override("disabled", _button_style(Color(0.12, 0.16, 0.24, 0.55), 0.55))
	return button

func _button_style(color: Color, alpha: float, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color, alpha)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 16
	style.content_margin_right = 16
	if border.a > 0.0:
		style.draw_center = false
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = border
	return style

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
