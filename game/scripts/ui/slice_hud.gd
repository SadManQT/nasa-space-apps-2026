extends Control
class_name SliceHUD

signal choice_selected(choice_id: String)
signal preview_requested
signal confirm_requested
signal retry_requested
signal exit_requested
signal advance_requested
signal command_emitted(command: Dictionary)
signal panel_requested(panel_id: String)

const INK := Color("#05060A")
const NAVY := Color("#1F2A44")
const IVORY := Color("#ECEEF0")
const MUTED := Color("#A8B4C8")
const MUSTARD := Color("#F2C230")
const CYAN := Color("#20B8C9")
const GREEN := Color("#4CAF50")
const RED := Color("#E56B6F")
const PANELS_SCENE: PackedScene = preload("res://scenes/ui/campaign_panels.tscn")

var _scene: Dictionary = {}
var _state: Dictionary = {}
var _dialogue: Array = []
var _line_index := 0
var _selected_choice := ""
var _selected_button: Button
var _choice_buttons: Array[Button] = []
var _preview_button: Button
var _confirm_button: Button
var _next_button: Button
var _feedback: Label
var _choice_panel: PanelContainer
var _result_panel: PanelContainer
var _pause_panel: PanelContainer
var _journal_panel: PanelContainer
var _caption_speaker: Label
var _caption_line: Label
var _scene_title: Label
var _scene_meta: Label
var _objective: Label
var _resource_summary: Label
var _prompt: Label
var _showing_result := false
var _completion := false
var _query: Dictionary = {}
var _command_sink: Callable
var _panels: CampaignPanels
var _caption_panel: PanelContainer
var _accessibility := {
	"captions": true,
	"large_text": false,
	"timer_free": true,
	"reduced_motion": false,
}
var _pause_focus: Control
var _journal_focus: Control
var _prompt_text := ""

func _ready() -> void:
	var loaded_theme := load("res://resources/ui/lla_theme.tres") as Theme
	if loaded_theme != null:
		theme = loaded_theme
	_build()

func show_scene(scene: Dictionary, state: Dictionary) -> void:
	_scene = scene
	_state = state
	bind_query(state)
	_dialogue = scene.get("dialogue", [])
	_line_index = 0
	_selected_choice = ""
	_showing_result = false
	_completion = false
	_populate_choices()
	_choice_panel.hide()
	_result_panel.hide()
	_pause_panel.hide()
	_journal_panel.hide()
	_next_button.show()
	_next_button.text = "NEXT LINE  ›"
	_scene_title.text = String(scene.get("title", "Commissioning"))
	_scene_meta.text = "%s  ·  %s  ·  %s" % [String(scene.get("id", "")), String(scene.get("location", "")), String(scene.get("story_time", ""))]
	_objective.text = "CURRENT OBJECTIVE\n" + String(scene.get("player_actions", ["Review the station briefing."])[0])
	_show_line()
	_update_resources(state)
	_set_prompt("E  INSPECT MISSION TABLE     ·     P  PAUSE     ·     J  JOURNAL")
	_set_player_modal(false)
	_apply_accessibility()

func bind_query(query: Dictionary) -> void:
	_query = query.duplicate(true)
	var supplied = _query.get("accessibility", _query.get("settings", {}))
	if supplied is Dictionary:
		_set_accessibility_local(supplied as Dictionary)
	if _panels != null:
		_panels.bind_query(_query)

func set_command_sink(sink: Callable) -> void:
	_command_sink = sink
	if _panels != null:
		_panels.set_command_sink(sink)

func query_snapshot() -> Dictionary:
	return _query.duplicate(true)

func accessibility_settings() -> Dictionary:
	return _accessibility.duplicate(true)

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
	panel_requested.emit(panel_id)
	return _panels.open_panel(panel_id, data)

func command_for(verb: String, target_id: String = "", payload: Dictionary = {}) -> Dictionary:
	var revision := int(_query.get("state_revision", _state.get("state_revision", 0)))
	return {
		"command_id": "hud:%s:%s:%s:%d" % [verb, target_id, String(_query.get("scene_id", _scene.get("id", ""))), revision],
		"issuer": "campaign_hud",
		"owning_mission_id": String(_query.get("mission_id", _scene.get("mission_id", ""))),
		"owning_scene_id": String(_query.get("scene_id", _scene.get("id", ""))),
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

func show_decision() -> void:
	_showing_result = false
	_completion = false
	_populate_choices()
	_choice_panel.show()
	_result_panel.hide()
	_feedback.text = "Select one route. Compare the forecast before you commit."
	_feedback.modulate = MUTED
	_preview_button.disabled = true
	_confirm_button.disabled = true
	_selected_choice = ""
	_selected_button = null
	_set_player_modal(true)
	if not _choice_buttons.is_empty():
		_choice_buttons[0].grab_focus()
	_apply_accessibility()

func select_choice(choice_id: String) -> void:
	_selected_choice = choice_id
	for button in _choice_buttons:
		var active := String(button.get_meta("choice_id", "")) == choice_id
		button.add_theme_stylebox_override("normal", _button_style(MUSTARD if active else Color(0.10, 0.16, 0.26, 0.96), INK if active else IVORY, active))
		if active:
			_selected_button = button
	_preview_button.disabled = choice_id.is_empty()
	_confirm_button.disabled = true
	_feedback.text = String(SliceRules.option_details(choice_id).get("consequence", "Decision selected."))
	_feedback.modulate = IVORY

func show_preview(result: Dictionary) -> void:
	if not bool(result.get("accepted", false)):
		_feedback.text = String(result.get("reason", "Preview unavailable."))
		_feedback.modulate = RED
		return
	var text := "FORECAST · " + String(result.get("deltas", ["No visible change."])[0])
	text += _resource_change_text(result)
	if not result.get("warnings", []).is_empty():
		text += "\n" + String(result.warnings[0])
	_feedback.text = text
	_feedback.modulate = CYAN
	_confirm_button.disabled = false

func show_result(result: Dictionary, state: Dictionary) -> void:
	_state = state
	bind_query(state)
	_update_resources(state)
	_showing_result = true
	_completion = false
	_choice_panel.hide()
	_result_panel.show()
	_set_player_modal(true)
	var accepted := bool(result.get("accepted", false))
	var heading: Label = _result_panel.get_node("Margin/Content/Heading")
	var body: Label = _result_panel.get_node("Margin/Content/Body")
	heading.text = "DECISION RECORDED" if accepted else "DECISION NOT RECORDED"
	heading.add_theme_color_override("font_color", GREEN if accepted else RED)
	var deltas: Array = result.get("deltas", [])
	var result_text := String(deltas[0]) if not deltas.is_empty() else String(result.get("reason", "Please try again."))
	result_text += _resource_change_text(result)
	body.text = (result_text +
		"\n\nThe checkpoint is safe. The next scene opens only after this receipt.") if accepted else String(result.get("reason", "Please try again."))
	_next_button.text = "CONTINUE TO NEXT SCENE  ›" if String(result.get("next_phase", "")) == "next_scene" else "FINISH COMMISSIONING SLICE  ›"
	_next_button.show()
	_next_button.grab_focus()
	_set_prompt("RECEIPT %s  ·  REVISION %s" % [result.get("receipt_id", ""), state.get("state_revision", 0)])
	_apply_accessibility()

func show_completion(state: Dictionary) -> void:
	_state = state
	bind_query(state)
	_update_resources(state)
	_showing_result = false
	_completion = true
	_choice_panel.hide()
	_result_panel.show()
	_set_player_modal(true)
	var heading: Label = _result_panel.get_node("Margin/Content/Heading")
	var body: Label = _result_panel.get_node("Margin/Content/Body")
	heading.text = "COMMISSIONING SLICE COMPLETE"
	heading.add_theme_color_override("font_color", MUSTARD)
	body.text = "Aurora has a crew, a local safety rule and a traceable measurement habit.\n\nThis is the implemented EX-CH01-S01 → EX-CH01-S03 demo slice. The full 12-scene Chapter 1 night, P-01/P-02 simulation and later chapters remain separate work."
	_next_button.text = "RETURN TO TITLE"
	_next_button.show()
	_next_button.grab_focus()
	_set_prompt("DEMO CHECKPOINT SAVED  ·  CH01 COMMISSIONING")
	_apply_accessibility()

func show_pause() -> void:
	_pause_focus = _focus_owner_outside(_pause_panel)
	_pause_panel.show()
	_set_player_modal(true)
	var resume := _pause_panel.get_node_or_null("Margin/Content/Resume") as Button
	if resume != null:
		resume.grab_focus()

func hide_pause() -> void:
	_pause_panel.hide()
	_set_player_modal(false)
	_restore_focus(_pause_focus, _next_button)
	_pause_focus = null

func show_journal() -> void:
	_journal_focus = _focus_owner_outside(_journal_panel)
	_journal_panel.show()
	_set_player_modal(true)
	var body: Label = _journal_panel.get_node("Margin/Content/Body")
	body.text = "ACQUIRED KNOWLEDGE\n\n• Aurora commissioning is a shared responsibility.\n• Local procedures still work when Earth is unavailable.\n• A reading needs a reference.\n\nSOURCE STATUS\nSIMULATED · station, cadets and 2046 timeline\nTRAINING SCENARIO · polar-night exercise\n\nNo future identity, outcome or unrevealed evidence is shown."
	var close := _journal_panel.get_node_or_null("Margin/Content/CloseJournal") as Button
	if close != null:
		close.grab_focus()

func hide_journal() -> void:
	_journal_panel.hide()
	_set_player_modal(false)
	_restore_focus(_journal_focus, _next_button)
	_journal_focus = null

func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var top := _panel(Color(0.03, 0.06, 0.12, 0.96), 0, Color(0.26, 0.40, 0.62, 0.7))
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 92
	add_child(top)
	var top_margin := MarginContainer.new()
	top_margin.add_theme_constant_override("margin_left", 28)
	top_margin.add_theme_constant_override("margin_right", 28)
	top_margin.add_theme_constant_override("margin_top", 14)
	top_margin.add_theme_constant_override("margin_bottom", 12)
	top.add_child(top_margin)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 18)
	top_margin.add_child(top_row)
	var brand := Label.new()
	brand.text = "LAST LIGHT / AURORA"
	brand.add_theme_font_size_override("font_size", 14)
	brand.add_theme_color_override("font_color", MUSTARD)
	top_row.add_child(brand)
	_scene_title = Label.new()
	_scene_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scene_title.add_theme_font_size_override("font_size", 22)
	_scene_title.add_theme_color_override("font_color", IVORY)
	top_row.add_child(_stack([_scene_title]))
	_scene_meta = Label.new()
	_scene_meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_scene_meta.add_theme_font_size_override("font_size", 12)
	_scene_meta.add_theme_color_override("font_color", MUTED)
	top_row.add_child(_stack([_scene_meta]))
	var journal := _small_button("J  JOURNAL")
	journal.pressed.connect(show_journal)
	top_row.add_child(journal)
	var pause := _small_button("P  PAUSE")
	pause.pressed.connect(show_pause)
	top_row.add_child(pause)

	_objective = Label.new()
	_objective.position = Vector2(28, 120)
	_objective.size = Vector2(360, 82)
	_objective.add_theme_font_size_override("font_size", 14)
	_objective.add_theme_color_override("font_color", CYAN)
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_objective)
	_resource_summary = Label.new()
	_resource_summary.position = Vector2(850, 120)
	_resource_summary.size = Vector2(390, 100)
	_resource_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_resource_summary.add_theme_font_size_override("font_size", 14)
	_resource_summary.add_theme_color_override("font_color", IVORY)
	_resource_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_resource_summary)

	_caption_panel = _panel(Color(0.03, 0.05, 0.10, 0.94), 14, Color(0.26, 0.40, 0.62, 0.65))
	var caption := _caption_panel
	caption.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	caption.offset_top = -172
	caption.offset_bottom = -28
	add_child(caption)
	var caption_margin := MarginContainer.new()
	caption_margin.add_theme_constant_override("margin_left", 24)
	caption_margin.add_theme_constant_override("margin_right", 24)
	caption_margin.add_theme_constant_override("margin_top", 16)
	caption_margin.add_theme_constant_override("margin_bottom", 14)
	caption.add_child(caption_margin)
	var caption_content := VBoxContainer.new()
	caption_content.add_theme_constant_override("separation", 5)
	caption_margin.add_child(caption_content)
	_caption_speaker = Label.new()
	_caption_speaker.add_theme_font_size_override("font_size", 13)
	_caption_speaker.add_theme_color_override("font_color", MUSTARD)
	caption_content.add_child(_caption_speaker)
	_caption_line = Label.new()
	_caption_line.add_theme_font_size_override("font_size", 22)
	_caption_line.add_theme_color_override("font_color", IVORY)
	_caption_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption_line.size_flags_vertical = Control.SIZE_EXPAND_FILL
	caption_content.add_child(_caption_line)
	var caption_hint := Label.new()
	caption_hint.text = "CAPTIONS  /  STORED OR LIVE ORIGIN SHOWN EXPLICITLY"
	caption_hint.add_theme_font_size_override("font_size", 11)
	caption_hint.add_theme_color_override("font_color", MUTED)
	caption_content.add_child(caption_hint)

	_prompt = Label.new()
	_prompt.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_prompt.position = Vector2(-500, -22)
	_prompt.size = Vector2(470, 22)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_prompt.add_theme_font_size_override("font_size", 12)
	_prompt.add_theme_color_override("font_color", MUTED)
	add_child(_prompt)
	_next_button = _small_button("NEXT LINE  ›")
	_next_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_next_button.position = Vector2(-238, -112)
	_next_button.size = Vector2(210, 48)
	_next_button.pressed.connect(_advance_dialogue)
	add_child(_next_button)

	_choice_panel = _build_choice_panel()
	_result_panel = _build_result_panel()
	_pause_panel = _build_pause_panel()
	_journal_panel = _build_journal_panel()
	add_child(_choice_panel)
	add_child(_result_panel)
	add_child(_pause_panel)
	add_child(_journal_panel)
	_choice_panel.hide()
	_result_panel.hide()
	_pause_panel.hide()
	_journal_panel.hide()
	_panels = PANELS_SCENE.instantiate() as CampaignPanels
	_panels.name = "CampaignPanels"
	_panels.bind_query(_query)
	add_child(_panels)
	_panels.accessibility_changed.connect(_on_accessibility_changed)
	_apply_accessibility()

func _build_choice_panel() -> PanelContainer:
	var panel := _modal_panel(Vector2(600, 390), Color(0.95, 0.76, 0.22, 0.72))
	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)
	var eyebrow := Label.new()
	eyebrow.text = "MISSION TABLE / DECISION"
	eyebrow.add_theme_font_size_override("font_size", 13)
	eyebrow.add_theme_color_override("font_color", CYAN)
	content.add_child(eyebrow)
	var prompt := Label.new()
	prompt.name = "Prompt"
	prompt.text = "Choose a route"
	prompt.add_theme_font_size_override("font_size", 24)
	prompt.add_theme_color_override("font_color", IVORY)
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(prompt)
	var options := VBoxContainer.new()
	options.name = "Options"
	options.add_theme_constant_override("separation", 8)
	content.add_child(options)
	var forecast := Label.new()
	forecast.name = "Forecast"
	forecast.text = "SELECT A ROUTE TO SEE ITS FORECAST."
	forecast.add_theme_font_size_override("font_size", 13)
	forecast.add_theme_color_override("font_color", MUTED)
	content.add_child(forecast)
	_feedback = Label.new()
	_feedback.name = "Feedback"
	_feedback.text = "Select one route. Compare the forecast before you commit."
	_feedback.add_theme_font_size_override("font_size", 14)
	_feedback.add_theme_color_override("font_color", MUTED)
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_feedback)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 8)
	content.add_child(actions)
	_preview_button = _small_button("COMPARE PREVIEW")
	_preview_button.disabled = true
	_preview_button.pressed.connect(func() -> void:
		emit_command("preview_choice", _selected_choice, {"choice_id": _selected_choice})
		preview_requested.emit()
	)
	actions.add_child(_preview_button)
	_confirm_button = _small_button("CONFIRM PLAN  ✓")
	_confirm_button.disabled = true
	_confirm_button.pressed.connect(func() -> void:
		emit_command("commit_choice", _selected_choice, {"choice_id": _selected_choice})
		confirm_requested.emit()
	)
	actions.add_child(_confirm_button)
	return panel

func _build_result_panel() -> PanelContainer:
	var panel := _modal_panel(Vector2(600, 330), Color(0.22, 0.73, 0.55, 0.75))
	panel.name = "ResultPanel"
	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 14)
	margin.add_child(content)
	var heading := Label.new()
	heading.name = "Heading"
	heading.text = "DECISION RECORDED"
	heading.add_theme_font_size_override("font_size", 25)
	content.add_child(heading)
	var body := Label.new()
	body.name = "Body"
	body.text = "The checkpoint is safe."
	body.add_theme_font_size_override("font_size", 17)
	body.add_theme_color_override("font_color", IVORY)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(body)
	return panel

func _build_pause_panel() -> PanelContainer:
	var panel := _modal_panel(Vector2(420, 260), Color(0.08, 0.12, 0.20, 0.98), Color(0.32, 0.43, 0.60, 0.8))
	panel.name = "PausePanel"
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)
	var title := Label.new()
	title.text = "EXPEDITION PAUSED"
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override("font_color", MUSTARD)
	content.add_child(title)
	var note := Label.new()
	note.text = "Reading and planning do not advance scenario time."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_color_override("font_color", MUTED)
	content.add_child(note)
	var resume := _small_button("RESUME")
	resume.name = "Resume"
	resume.pressed.connect(hide_pause)
	content.add_child(resume)
	var retry := _small_button("RETRY VERIFIED CHECKPOINT")
	retry.pressed.connect(func() -> void: retry_requested.emit())
	content.add_child(retry)
	var exit := _small_button("RETURN TO TITLE")
	exit.pressed.connect(func() -> void: exit_requested.emit())
	content.add_child(exit)
	return panel

func _build_journal_panel() -> PanelContainer:
	var panel := _modal_panel(Vector2(560, 420), Color(0.04, 0.08, 0.14, 0.98), Color(0.13, 0.72, 0.78, 0.8))
	panel.name = "JournalPanel"
	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)
	var title := Label.new()
	title.text = "EXPEDITION JOURNAL"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", CYAN)
	content.add_child(title)
	var body := Label.new()
	body.name = "Body"
	body.add_theme_font_size_override("font_size", 16)
	body.add_theme_color_override("font_color", IVORY)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(body)
	var close := _small_button("CLOSE JOURNAL")
	close.name = "CloseJournal"
	close.pressed.connect(hide_journal)
	content.add_child(close)
	return panel

func _advance_dialogue() -> void:
	if _completion:
		exit_requested.emit()
		return
	if _showing_result:
		advance_requested.emit()
		return
	if _dialogue.is_empty():
		show_decision()
		return
	if _line_index < _dialogue.size():
		var current_line: Dictionary = _dialogue[_line_index]
		emit_command("acknowledge_line", String(current_line.get("id", "")), {"line_id": String(current_line.get("id", "")), "dialogue_only": true})
	if _line_index < _dialogue.size() - 1:
		_line_index += 1
		_show_line()
	else:
		show_decision()

func _show_line() -> void:
	if _dialogue.is_empty():
		_caption_speaker.text = "AURORA / BRIEFING"
		_caption_line.text = "Review the station plan before you commit a decision."
		return
	var line: Dictionary = _dialogue[_line_index]
	var origin := String(line.get("origin_label", ""))
	if origin.is_empty():
		origin = "EARTH LINK" if String(line.get("speaker", "")).contains("Earth") else "LOCAL RADIO"
	_caption_speaker.text = "%s  ·  %s" % [String(line.get("speaker_label", line.get("speaker", "CREW"))), origin]
	_caption_line.text = String(line.get("text", line.get("line", "")))
	_next_button.text = "NEXT LINE  ›" if _line_index < _dialogue.size() - 1 else "OPEN DECISION PANEL  ›"

func _update_resources(state: Dictionary) -> void:
	var resources: Dictionary = state.get("resources", {})
	_resource_summary.text = "AURORA  ·  %s\nENERGY %s/%s   AIR %s/%s\nALO HEALTH %s/10   STATUS %s" % [String(state.get("scenario_datetime", "2046-04-11")), resources.get("energy", "—"), resources.get("energy_capacity", "—"), resources.get("air", "—"), resources.get("air_capacity", "—"), resources.get("alo_health", "—"), String(state.get("status", "commissioning")).to_upper()]

func _resource_change_text(result: Dictionary) -> String:
	var changes: Array = result.get("resource_changes", [])
	if changes.is_empty():
		return ""
	var labels: Array[String] = []
	for change in changes:
		var delta := int(change.get("delta", 0))
		var sign := "+" if delta > 0 else ""
		labels.append("%s %s%d" % [String(change.get("resource_id", "resource")).to_upper(), sign, delta])
	return "\nRESOURCE EFFECT · " + "   ".join(labels)

func _set_player_modal(modal: bool) -> void:
	var owner: Node = self
	var player: Node
	while owner != null:
		player = owner.get_node_or_null("Player")
		if player != null:
			break
		owner = owner.get_parent()
	if player == null:
		return
	player.process_mode = Node.PROCESS_MODE_DISABLED if modal else Node.PROCESS_MODE_INHERIT
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if modal else Input.MOUSE_MODE_CAPTURED
	if not modal:
		player.set_process_input(true)

func _on_accessibility_changed(settings: Dictionary) -> void:
	_set_accessibility_local(settings)
	_apply_accessibility()

func _set_accessibility_local(settings: Dictionary) -> void:
	for key in _accessibility.keys():
		if settings.has(key):
			_accessibility[key] = bool(settings[key])

func _apply_accessibility() -> void:
	if not is_inside_tree():
		return
	if _caption_panel != null:
		_caption_panel.visible = bool(_accessibility.get("captions", true))
	set_meta("accessibility_settings", _accessibility.duplicate(true))
	set_meta("timer_behavior", "timer_free" if is_timer_free() else "standard_timing")
	set_meta("presentation_transition_seconds", presentation_transition_seconds())
	_set_prompt(_prompt_text)
	_apply_text_scale(self)

func _set_prompt(text: String) -> void:
	_prompt_text = text
	if _prompt == null:
		return
	var timing_label := "TIMER-FREE" if bool(_accessibility.get("timer_free", true)) else "STANDARD TIMING"
	_prompt.text = timing_label + "  ·  " + text

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

func _focus_owner_outside(modal: Control) -> Control:
	if get_viewport() == null:
		return null
	var focused := get_viewport().gui_get_focus_owner()
	if _can_restore_focus(focused) and (modal == null or not modal.is_ancestor_of(focused)):
		return focused as Control
	return null

func _restore_focus(candidate: Control, fallback: Control) -> void:
	if _can_restore_focus(candidate):
		candidate.grab_focus()
	elif _can_restore_focus(fallback):
		fallback.grab_focus()
	else:
		get_viewport().gui_release_focus()

func _can_restore_focus(candidate: Control) -> bool:
	if not is_instance_valid(candidate) or not candidate.is_inside_tree() or not candidate.is_visible_in_tree():
		return false
	if candidate.focus_mode == Control.FOCUS_NONE:
		return false
	if candidate is BaseButton and (candidate as BaseButton).disabled:
		return false
	return true

func _modal_panel(size: Vector2, border: Color, border_override: Color = Color.TRANSPARENT) -> PanelContainer:
	var panel := _panel(Color(0.03, 0.05, 0.10, 0.98), 18, border_override if border_override.a > 0.0 else border)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = -size * 0.5
	panel.size = size
	panel.z_index = 20
	return panel

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

func _small_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 42)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", IVORY)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	button.add_theme_stylebox_override("normal", _button_style(Color(0.10, 0.16, 0.26, 0.96), IVORY, false))
	button.add_theme_stylebox_override("hover", _button_style(MUSTARD, INK, true))
	button.add_theme_stylebox_override("pressed", _button_style(Color("#D8A915"), INK, true))
	button.add_theme_stylebox_override("focus", _button_style(Color(0.13, 0.22, 0.34, 1.0), IVORY, true))
	return button

func _populate_choices() -> void:
	if _choice_panel == null or _scene.is_empty():
		return
	var options_box: VBoxContainer = _choice_panel.get_node("Margin/Content/Options")
	for child in options_box.get_children():
		child.free()
	_choice_buttons.clear()
	var choice: Dictionary = _scene.get("choice", {})
	var prompt: Label = _choice_panel.get_node("Margin/Content/Prompt")
	prompt.text = String(choice.get("prompt", "Choose the next safe step."))
	for option in choice.get("options", []):
		var option_data: Dictionary = option
		var button := _small_button(String(option_data.get("label", "OPTION")))
		button.set_meta("choice_id", String(option_data.get("id", "")))
		button.pressed.connect(func() -> void:
			emit_command("select_choice", String(option_data.get("id", "")), {"choice_id": String(option_data.get("id", ""))})
			choice_selected.emit(String(option_data.get("id", "")))
		)
		options_box.add_child(button)
		_choice_buttons.append(button)

func _button_style(color: Color, text_color: Color, highlighted: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 12
	style.content_margin_right = 12
	if highlighted:
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = MUSTARD
	return style

func _stack(children: Array[Control]) -> Control:
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for child in children:
		stack.add_child(child)
	return stack
