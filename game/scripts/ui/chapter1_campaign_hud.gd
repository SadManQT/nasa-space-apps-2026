extends Control
class_name Chapter1CampaignHUD

const Outpost = preload("res://scripts/ui/outpost_status.gd")
const PANELS_SCENE: PackedScene = preload("res://scenes/ui/campaign_panels.tscn")
const MISSION_TABLE_SCENE: PackedScene = preload("res://scenes/ui/mission_table_panel.tscn")
const MissionTableScript = preload("res://scripts/puzzles/p02_mission_table.gd")
const IVORY := Color("#ECEEF0")
const MUTED := Color("#A8B4C8")
const CYAN := Color("#20B8C9")
const MUSTARD := Color("#F2C230")
const GREEN := Color("#4CAF50")
const RED := Color("#E56B6F")

var runtime: Chapter1Campaign
var panels: CampaignPanels
var mission_table: MissionTablePanel
var _title: Label
var _meta: Label
var _objective: Label
var _caption_speaker: Label
var _caption_line: Label
var _status: Label
var _targets: VBoxContainer
var _next_line: Button
var _advance: Button
var _retry: Button
var _last_outcome: Dictionary = {}
var outpost: OutpostStatus
var _forecast: Dictionary = {}
var _forecast_key := ""
var _forecast_source := ""
var _pointer_preview := false
var _focus_preview := false
var _target_panel: PanelContainer
var _controls: Label
var _objective_scroll: ScrollContainer
var _operations_scroll: ScrollContainer
var _modal_button_states := {}
var _dialogue_index := 0
var _scene_id := ""
var _decision_review: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()

func setup(value: Chapter1Campaign) -> void:
	runtime = value
	panels = PANELS_SCENE.instantiate() as CampaignPanels
	add_child(panels)
	panels.set_command_sink(Callable(runtime, "handle_ui_command"))
	panels.panel_opened.connect(_on_panel_opened)
	panels.panel_closed.connect(_on_panel_closed)
	panels.outcome_retry_requested.connect(func() -> void:
		panels.close_panel()
		runtime.retry_checkpoint()
	)
	panels.outcome_continue_requested.connect(func() -> void:
		# Continue returns to the shutter/message/Tara gates. Only the route
		# can advance the chapter after all required physical evidence exists.
		panels.close_panel()
	)
	mission_table = MISSION_TABLE_SCENE.instantiate() as MissionTablePanel
	add_child(mission_table)
	mission_table.opened.connect(func(_target: String) -> void: _on_panel_opened("mission_table"))
	mission_table.closed.connect(func(_target: String) -> void: _on_panel_closed("mission_table"))
	mission_table.commit_requested.connect(_on_mission_table_commit)
	_refresh_query()
	refresh_scene({})

func refresh_scene(_result: Dictionary = {}, during_loading: bool = false) -> void:
	if runtime == null or (runtime.loading and not during_loading):
		return
	var scene := runtime.current_scene_data()
	var next_scene := String(scene.get("id", ""))
	if next_scene != _scene_id:
		_scene_id = next_scene
		_forecast = {}
		_forecast_key = ""
	_dialogue_index = _first_unacknowledged_line()
	_title.text = String(scene.get("title", "Chapter 1"))
	_meta.text = "%s  ·  %s  ·  %s" % [next_scene, String(scene.get("location", "")), String(scene.get("storyTime", scene.get("story_time", "")))]
	_decision_review.visible = next_scene.begins_with("EX-CH01-")
	_objective.text = "OBJECTIVE\n" + "\n".join(scene.get("playerActions", scene.get("player_actions", [])))
	_render_caption()
	_build_targets()
	_refresh_query()
	_last_outcome = {}
	apply_accessibility()

func refresh_after_action(result: Dictionary) -> void:
	_forecast = {}
	_forecast_key = ""
	if runtime != null:
		_dialogue_index = _first_unacknowledged_line()
		_render_caption()
		_build_targets()
		_refresh_query()
	if result.get("accepted", false):
		var committed: Dictionary = result.get("result", result)
		if runtime.route.has_method("outcome_view") and not String(committed.get("ending", "")).is_empty():
			open_outcome()
			return
		if not _last_outcome.get("chapter1", false):
			_last_outcome = {"result": result.get("reason", "Operation completed."), "changes": result.get("deltas", []), "notes": result.get("warnings", []) + result.get("ledger_summary", [])}
		panels.bind_query(runtime.query().merged({"outcome": _last_outcome}, true))
	if result.has("reason"):
		show_status(String(result.get("reason", "")))

func show_status(text: String) -> void:
	if _status != null:
		_status.text = text
		_status.modulate = GREEN if text.contains("SAVED") or text.contains("committed") else MUTED

func _build() -> void:
	var top := _panel(Color(0.03, 0.06, 0.12, 0.96), 0, Color(0.26, 0.40, 0.62, 0.7))
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 86
	add_child(top)
	var top_margin := MarginContainer.new()
	top_margin.add_theme_constant_override("margin_left", 24)
	top_margin.add_theme_constant_override("margin_right", 24)
	top_margin.add_theme_constant_override("margin_top", 12)
	top_margin.add_theme_constant_override("margin_bottom", 10)
	top.add_child(top_margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	top_margin.add_child(row)
	var brand := Label.new()
	brand.text = "LAST LIGHT / AURORA"
	brand.add_theme_color_override("font_color", MUSTARD)
	brand.add_theme_font_size_override("font_size", 14)
	row.add_child(brand)
	_title = Label.new()
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.add_theme_color_override("font_color", IVORY)
	_title.add_theme_font_size_override("font_size", 21)
	row.add_child(_stack(_title))
	_meta = Label.new()
	_meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_meta.custom_minimum_size.x = 300
	_meta.add_theme_color_override("font_color", MUTED)
	_meta.add_theme_font_size_override("font_size", 11)
	row.add_child(_stack(_meta))

	_objective = Label.new()
	_objective.position = Vector2(24, 108)
	_objective.size = Vector2(370, 125)
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective.add_theme_color_override("font_color", CYAN)
	_objective.add_theme_font_size_override("font_size", 14)
	_objective.add_theme_color_override("font_outline_color", Color("#05060A"))
	_objective.add_theme_constant_override("outline_size", 5)
	_objective_scroll = ScrollContainer.new()
	_objective_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_objective_scroll.follow_focus = true
	_objective_scroll.get_v_scroll_bar().focus_mode = Control.FOCUS_ALL
	_objective_scroll.accessibility_name = "Current objective"
	_objective.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_objective.position = Vector2.ZERO
	_objective_scroll.add_child(_objective)
	add_child(_objective_scroll)

	var caption := _panel(Color(0.03, 0.05, 0.10, 0.95), 14, Color(0.26, 0.40, 0.62, 0.65))
	caption.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	caption.offset_top = -190
	caption.offset_bottom = -28
	add_child(caption)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	caption.add_child(margin)
	var caption_box := VBoxContainer.new()
	caption_box.add_theme_constant_override("separation", 5)
	margin.add_child(caption_box)
	_caption_speaker = Label.new()
	_caption_speaker.add_theme_color_override("font_color", MUSTARD)
	_caption_speaker.add_theme_font_size_override("font_size", 13)
	caption_box.add_child(_caption_speaker)
	_caption_line = Label.new()
	_caption_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption_line.add_theme_color_override("font_color", IVORY)
	_caption_line.add_theme_font_size_override("font_size", 20)
	_caption_line.size_flags_vertical = Control.SIZE_EXPAND_FILL
	caption_box.add_child(_caption_line)
	_next_line = _button("ACKNOWLEDGE LINE  ›")
	_next_line.pressed.connect(_on_next_line)
	caption_box.add_child(_next_line)

	var target_panel := _panel(Color(0.05, 0.08, 0.14, 0.92), 14, Color(0.13, 0.72, 0.78, 0.55))
	_target_panel = target_panel
	target_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	target_panel.offset_left = -464
	target_panel.offset_right = -24
	target_panel.offset_top = 110
	target_panel.offset_bottom = -212
	add_child(target_panel)
	var target_margin := MarginContainer.new()
	target_margin.add_theme_constant_override("margin_left", 18)
	target_margin.add_theme_constant_override("margin_right", 18)
	target_margin.add_theme_constant_override("margin_top", 18)
	target_margin.add_theme_constant_override("margin_bottom", 18)
	target_panel.add_child(target_margin)
	var target_box := VBoxContainer.new()
	target_box.add_theme_constant_override("separation", 8)
	var operations_scroll := ScrollContainer.new()
	_operations_scroll = operations_scroll
	operations_scroll.get_v_scroll_bar().focus_mode = Control.FOCUS_ALL
	operations_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	operations_scroll.follow_focus = true
	target_margin.add_child(operations_scroll)
	target_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	operations_scroll.add_child(target_box)
	var target_title := Label.new()
	target_title.text = "PHYSICAL OPERATIONS"
	target_title.add_theme_color_override("font_color", CYAN)
	target_title.add_theme_font_size_override("font_size", 14)
	target_box.add_child(target_title)
	_targets = VBoxContainer.new()
	_targets.add_theme_constant_override("separation", 7)
	_targets.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_box.add_child(_targets)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_color_override("font_color", MUTED)
	target_box.add_child(_status)
	_advance = _button("ADVANCE SCENE  ›")
	_advance.pressed.connect(_on_advance_pressed)
	target_box.add_child(_advance)
	var actions := HFlowContainer.new()
	actions.alignment = FlowContainer.ALIGNMENT_END
	target_box.add_child(actions)
	var journal := _button("JOURNAL")
	journal.pressed.connect(_on_journal_pressed)
	actions.add_child(journal)
	var save := _button("SAVE")
	save.pressed.connect(_on_save_pressed)
	actions.add_child(save)
	var exit := _button("TITLE")
	exit.pressed.connect(_on_exit_pressed)
	actions.add_child(exit)
	var data_cards := _button("DATA CARDS")
	data_cards.pressed.connect(func() -> void:
		var ids: Array = []
		for puzzle_id in runtime.query().get("source_puzzle_ids", []):
			for card in panels.science.cards_for_puzzle(puzzle_id):
				if not ids.has(card.source_id):
					ids.append(card.source_id)
		panels.open_panel("sources", {"ids": ids})
	)
	actions.add_child(data_cards)
	var tools := HFlowContainer.new()
	tools.add_theme_constant_override("separation", 6)
	target_box.add_child(tools)
	var decision := _button("DECISION REVIEW")
	_decision_review = decision
	decision.pressed.connect(func() -> void: panels.open_panel("puzzle"))
	tools.add_child(decision)
	decision.name = "DecisionReview"
	var pause := _button("PAUSE")
	pause.pressed.connect(func() -> void: panels.open_panel("pause"))
	tools.add_child(pause)
	var settings := _button("SETTINGS")
	settings.pressed.connect(func() -> void: panels.open_panel("settings_accessibility"))
	tools.add_child(settings)
	_retry = _button("RETRY")
	_retry.pressed.connect(func() -> void: runtime.retry_checkpoint())
	tools.add_child(_retry)
	var outcome := _button("OUTCOME")
	outcome.name = "OutcomeReview"
	outcome.pressed.connect(open_outcome)
	tools.add_child(outcome)
	var controls := Label.new()
	_controls = controls
	controls.text = "WASD move · Hold RMB to look · E use nearby\nEsc pause · Tab / arrows / Enter select controls"
	controls.add_theme_color_override("font_outline_color", Color("#05060A"))
	controls.add_theme_constant_override("outline_size", 5)
	controls.position = Vector2(24, 248)
	controls.add_theme_font_size_override("font_size", 13)
	controls.add_theme_color_override("font_color", MUTED)
	add_child(controls)
	outpost = Outpost.new()
	outpost.name = "OutpostStatus"
	outpost.set_anchors_preset(Control.PRESET_TOP_WIDE)
	outpost.offset_left = 24
	outpost.offset_right = -24
	outpost.offset_top = 100
	outpost.z_index = 70
	add_child(outpost)
	outpost.minimum_size_changed.connect(_layout_outpost.call_deferred)

func _build_targets() -> void:
	if _targets == null or runtime == null:
		return
	for child in _targets.get_children():
		_targets.remove_child(child)
		child.queue_free()
	var gate: Dictionary = runtime.route.gate_status()
	var complete := runtime.is_chapter_complete()
	for raw_target in runtime.targets_for_current_scene():
		if not raw_target is Dictionary:
			continue
		var target: Dictionary = raw_target
		var node := runtime.physical_target(String(target.get("target_id", "")))
		var label := String(node.get_meta("focus_label", "")) if node != null else "unavailable"
		var button := _button("USE · " + String(target.get("focus_label", target.get("target_id", "operation"))) + "\nAT " + label)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.disabled = complete or runtime.target_completed(target)
		button.mouse_entered.connect(func() -> void:
			_pointer_preview = true
			show_target_forecast(String(target.target_id))
		)
		button.mouse_exited.connect(func() -> void:
			_pointer_preview = false
			_clear_unselected_forecast()
		)
		button.focus_entered.connect(func() -> void:
			_focus_preview = true
			show_target_forecast(String(target.target_id))
		)
		button.focus_exited.connect(func() -> void:
			_focus_preview = false
			_clear_unselected_forecast()
		)
		var target_id := String(target.get("target_id", ""))
		if MissionTableScript.is_gate(target_id):
			button.text = "PLAN AT MISSION TABLE · " + String(target.get("focus_label", target_id)) + "\nAT " + label
			button.pressed.connect(func() -> void: open_mission_table(target_id))
		else:
			button.pressed.connect(func() -> void: runtime.perform_target(target_id))
		_targets.add_child(button)
	_advance.disabled = complete or not bool(gate.get("ready", false))
	_retry.disabled = complete or runtime.route.snapshot().get("retry_checkpoint", {}).is_empty()
	if complete:
		var chapter_number := str(int(String(runtime.query().get("chapter_id", "CH01")).trim_prefix("CH")))
		_status.text = "CHAPTER %s COMPLETE · %s\nCheckpoint kept. Advance when the next chapter is ready." % [chapter_number, String(runtime.route.chapter_ready().get("ending", ""))]
		_status.modulate = GREEN
	elif bool(gate.get("ready", false)):
		_status.text = "ALL OPERATIONS READY · advance when ready."
		_status.modulate = GREEN
	else:
		_status.text = "%d operations remain. Complete the listed steps, then advance." % gate.get("missing", []).size()
		_status.modulate = MUTED
	if panels != null and not panels.active_panel().is_empty():
		_set_modal_buttons(true)
	apply_accessibility()

## Opens the P-02 Mission Table for one shift gate. Reading and planning pause
## the expedition; the physical commit happens only after the table closes.
func open_mission_table(target_id: String) -> bool:
	if runtime == null or mission_table == null or runtime.is_chapter_complete() or not MissionTableScript.is_gate(target_id):
		return false
	if runtime.is_cutscene_active() or mission_table.is_open():
		return false
	if panels != null and not panels.active_panel().is_empty():
		return false
	mission_table.open(runtime.route, target_id, runtime.query().get("accessibility", {}))
	return true

func _on_mission_table_commit(target_id: String, plan: Dictionary) -> void:
	if runtime == null:
		return
	runtime.perform_target(target_id, {"plan": plan})

## Rebuild an ending from saved route evidence, including after load/retry.
## A generic operation result remains available before an ending is earned.
func open_outcome() -> void:
	if runtime == null or panels == null:
		return
	if runtime.route.has_method("outcome_view"):
		var closure: Dictionary = runtime.route.outcome_view()
		if not closure.is_empty():
			_last_outcome = closure
	panels.open_panel("outcome", _last_outcome if not _last_outcome.is_empty() else {"result": "Complete an operation to review its result."})

func _render_caption() -> void:
	if runtime == null:
		return
	var lines := runtime.current_dialogue()
	runtime.present_dialogue(lines[_dialogue_index] if _dialogue_index < lines.size() else {})
	if lines.is_empty():
		_caption_speaker.text = "AURORA / TRAINING SCENARIO"
		_caption_line.text = "Complete the physical operation; dialogue acknowledgement never completes a gate."
		_next_line.disabled = true
		return
	if _dialogue_index >= lines.size():
		_caption_speaker.text = "AURORA"
		_caption_line.text = "All scene dialogue acknowledged."
		_next_line.text = "DIALOGUE COMPLETE"
		_next_line.disabled = true
		return
	_dialogue_index = clampi(_dialogue_index, 0, lines.size() - 1)
	var line: Dictionary = lines[_dialogue_index]
	_caption_speaker.text = "%s  ·  %s" % [String(line.get("speaker", "CREW")), String(line.get("origin_label", line.get("delivery", "LOCAL RADIO")))]
	_caption_line.text = String(line.get("text", line.get("line", "")))
	_next_line.disabled = false
	_next_line.text = "ACKNOWLEDGE LINE  ·  %d/%d" % [_dialogue_index + 1, lines.size()]

## Resumes the caption where the saved acknowledgements stopped, so a reload
## does not replay lines the player already acknowledged.
func _first_unacknowledged_line() -> int:
	var acknowledged: Array = runtime.route.gate_status().get("dialogue_acknowledged", [])
	var lines := runtime.current_dialogue()
	for index in lines.size():
		if not acknowledged.has(String(lines[index].get("id", ""))):
			return index
	return lines.size()

func _on_next_line() -> void:
	if runtime == null:
		return
	var lines := runtime.current_dialogue()
	if lines.is_empty() or _dialogue_index >= lines.size():
		return
	var result := runtime.acknowledge_dialogue(String(lines[_dialogue_index].get("id", "")))
	if bool(result.get("accepted", false)):
		_dialogue_index = _first_unacknowledged_line()
	_render_caption()

func _on_advance_pressed() -> void:
	if runtime != null:
		runtime.advance_scene()

func _on_journal_pressed() -> void:
	if runtime != null and panels != null:
		panels.open_panel("journal_discovery", {"entries": runtime.query().get("journal_entries", [])})

func _on_save_pressed() -> void:
	if runtime != null:
		runtime.save_campaign()

func _on_exit_pressed() -> void:
	if runtime != null:
		runtime.exit_to_title()

func _refresh_query() -> void:
	if panels != null and runtime != null:
		var query := runtime.query()
		panels.bind_query(query)
		if outpost != null:
			outpost.bind_query(query, _forecast)

func apply_accessibility() -> void:
	if runtime == null:
		return
	var settings: Dictionary = runtime.query().get("accessibility", {})
	_caption_speaker.visible = bool(settings.get("captions", true))
	_caption_line.visible = bool(settings.get("captions", true))
	var large := bool(settings.get("large_text", false))
	_scale_text(self, 1.5 if large else 1.0)
	_layout_outpost()

func _layout_outpost() -> void:
	if outpost == null or runtime == null:
		return
	var large := bool(runtime.query().get("accessibility", {}).get("large_text", false))
	outpost.offset_bottom = 254 if large else 210
	var below := maxf(outpost.offset_bottom, outpost.get_global_rect().end.y) + 16
	_objective_scroll.position = Vector2(24, below)
	_objective_scroll.size = Vector2(740, 125)
	_controls.position = Vector2(24, below + 128)
	_target_panel.offset_top = below
	if panels != null:
		panels.set_content_top(below)

func _scale_text(node: Node, scale_factor: float) -> void:
	for child in node.get_children():
		if child == panels or child == mission_table:
			continue
		if child is Control:
			if not child.has_meta("lla_base_font_size"):
				child.set_meta("lla_base_font_size", child.get_theme_font_size("font_size"))
			child.add_theme_font_size_override("font_size", int(round(float(child.get_meta("lla_base_font_size")) * scale_factor)))
		_scale_text(child, scale_factor)

func _on_panel_opened(_panel_id: String) -> void:
	_operations_scroll.get_v_scroll_bar().focus_mode = Control.FOCUS_NONE
	_objective_scroll.get_v_scroll_bar().focus_mode = Control.FOCUS_NONE
	runtime.set_ui_paused(true)
	_set_modal_buttons(true)

func _on_panel_closed(_panel_id: String) -> void:
	_operations_scroll.get_v_scroll_bar().focus_mode = Control.FOCUS_ALL
	_objective_scroll.get_v_scroll_bar().focus_mode = Control.FOCUS_ALL
	runtime.set_ui_paused(false)
	_set_modal_buttons(false)

func _set_modal_buttons(disabled: bool, node: Node = self) -> void:
	if not disabled:
		for button in _modal_button_states:
			if is_instance_valid(button):
				button.disabled = bool(_modal_button_states[button])
		_modal_button_states.clear()
		return
	for child in node.get_children():
		if child == panels or child == mission_table:
			continue
		if child is BaseButton:
			if not _modal_button_states.has(child):
				_modal_button_states[child] = child.disabled
			child.disabled = true
		_set_modal_buttons(true, child)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		if panels != null and panels.active_panel().is_empty() and (mission_table == null or not mission_table.is_open()):
			panels.open_panel("pause")
			get_viewport().set_input_as_handled()

func _stack(control: Control) -> Control:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(control)
	return box

func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 38)
	button.add_theme_font_size_override("font_size", 14)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_color_override("font_color", IVORY)
	button.add_theme_color_override("font_hover_color", Color("#05060A"))
	button.add_theme_stylebox_override("normal", _button_style(Color("#1F2A44"), IVORY, false))
	button.add_theme_stylebox_override("hover", _button_style(MUSTARD, Color("#05060A"), true))
	button.add_theme_stylebox_override("focus", _button_style(Color("#243B5A"), IVORY, true))
	return button

func _button_style(fill: Color, text_color: Color, highlighted: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	style.content_margin_left = 10
	style.content_margin_right = 10
	if highlighted:
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = MUSTARD
	return style

func _panel(color: Color, radius: int, border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = border
	panel.add_theme_stylebox_override("panel", style)
	return panel

func show_target_forecast(target_id: String, source: String = "ui") -> void:
	if runtime == null or target_id.is_empty():
		return
	var key := "%s:%s:%s" % [runtime.route.current_scene_id(), target_id, runtime.director.query().state_revision]
	if key == _forecast_key:
		return
	_forecast_key = key
	_forecast_source = source
	_forecast = runtime.forecast_target(target_id)
	outpost.bind_query(runtime.query(), _forecast)
	outpost.tooltip_text = "Forecast of the selected operation. Live resources stay unchanged until you confirm." if bool(_forecast.get("accepted", false)) else String(_forecast.get("reason", "Complete the preceding operations to see this forecast."))

func show_nearby_forecast(target_id: String) -> void:
	if _pointer_preview or _focus_preview:
		return
	if not target_id.is_empty():
		show_target_forecast(target_id, "nearby")
	elif _forecast_source == "nearby":
		_clear_unselected_forecast()

func _clear_unselected_forecast() -> void:
	if _pointer_preview or _focus_preview or runtime == null:
		return
	_forecast = {}
	_forecast_key = ""
	_forecast_source = ""
	outpost.bind_query(runtime.query())
