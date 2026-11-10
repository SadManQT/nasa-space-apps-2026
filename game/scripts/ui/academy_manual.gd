extends Control
class_name AcademyManualPanel

## M3-69: Journal -> Manual and chapter-end "What you learned" presentation.
## This panel receives an immutable campaign snapshot and emits only requests to
## open existing science cards/clips. It never writes progress or save state.

signal closed
signal data_card_requested(source_id: String)
signal explainer_requested(explainer_id: String)

const CurriculumModel = preload("res://scripts/progression/curriculum.gd")

var _snapshot: Dictionary = {}
var _settings: Dictionary = {}
var _page_kind := "index"
var _page_id := ""
var _body: VBoxContainer
var _scroll: ScrollContainer
var _heading: Label
var _subtitle: Label

func _ready() -> void:
	name = "AcademyManual"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	visible = false
	get_viewport().size_changed.connect(_scale)

func bind_snapshot(snapshot: Dictionary) -> void:
	_snapshot = snapshot.duplicate(true)
	if _body != null:
		_render()

func set_accessibility(settings: Dictionary) -> void:
	_settings = settings.duplicate(true)
	_scale()

func open_index() -> void:
	_page_kind = "index"
	_page_id = ""
	visible = true
	_render()

func open_competency(id: String) -> bool:
	if CurriculumModel.competency(id).is_empty():
		return false
	_page_kind = "competency"
	_page_id = id
	visible = true
	_render()
	return true

func open_chapter(chapter: int) -> bool:
	if CurriculumModel.chapter_learning(chapter, _snapshot).is_empty():
		return false
	_page_kind = "chapter"
	_page_id = str(chapter)
	visible = true
	_render()
	return true

func close_manual() -> void:
	visible = false
	closed.emit()

func current_page() -> Dictionary:
	return {"kind": _page_kind, "id": _page_id}

func _build() -> void:
	var shade := ColorRect.new()
	shade.name = "ManualBackdrop"
	shade.color = Color(0.02, 0.03, 0.06, 0.84)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var glass := UiDesign.glass_panel(UiDesign.colour("accent"), 20)
	glass.name = "ManualGlass"
	glass.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glass.offset_left = 24
	glass.offset_top = 24
	glass.offset_right = -24
	glass.offset_bottom = -24
	add_child(glass)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 12)
	glass.add_child(stack)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	stack.add_child(header)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titles)
	_heading = UiDesign.label("Academy Manual", "title", "accent")
	titles.add_child(_heading)
	_subtitle = UiDesign.label("The things you learned by keeping Aurora alive.", "caption", "muted")
	titles.add_child(_subtitle)
	var close_button := UiDesign.button("Close (Esc)", 42)
	close_button.name = "CloseAcademyManual"
	close_button.pressed.connect(close_manual)
	header.add_child(close_button)

	_scroll = ScrollContainer.new()
	_scroll.name = "ManualScroll"
	_scroll.follow_focus = true
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(_scroll)
	_body = VBoxContainer.new()
	_body.name = "ManualBody"
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 10)
	_scroll.add_child(_body)
	_render()

func _render() -> void:
	if _body == null:
		return
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	_scroll.scroll_vertical = 0
	match _page_kind:
		"competency":
			_render_competency(CurriculumModel.manual_page(_page_id, _snapshot))
		"chapter":
			var page := CurriculumModel.chapter_learning(int(_page_id), _snapshot)
			if page.is_empty():
				_page_kind = "index"
				_render_index()
			else:
				_render_chapter(page)
		_:
			_render_index()
	_scale()
	_focus_first.call_deferred()

func _render_index() -> void:
	_heading.text = "Academy Manual"
	_subtitle.text = "Twelve field skills. The pages fill in as you play; nothing here is a test."
	_body.add_child(UiDesign.label("What the crew has learned", "heading", "ivory"))
	for status in CurriculumModel.progress(_snapshot):
		var id := String(status.id)
		var card := _card("ManualCompetency_" + id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		card.add_child(row)
		var text_col := VBoxContainer.new()
		text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text_col)
		text_col.add_child(UiDesign.label(String(status.title), "body", "ivory"))
		text_col.add_child(UiDesign.label(String(status.label), "caption", "good" if int(status.level) == 3 else "muted"))
		var open_btn := UiDesign.button("Open page" if int(status.level) > 0 else "Ahead", 38)
		open_btn.name = "OpenCompetency_" + id
		open_btn.disabled = int(status.level) == 0
		open_btn.pressed.connect(func() -> void: open_competency(id))
		row.add_child(open_btn)
	_body.add_child(UiDesign.label("What you learned at each chapter end", "heading", "ivory"))
	var completed := CurriculumModel.completed_chapter_learning(_snapshot)
	if completed.is_empty():
		_body.add_child(UiDesign.label("Your first chapter page opens after the Night One debrief.", "body", "muted"))
	for page in completed:
		var number := int(page.chapter)
		var button := UiDesign.button(String(page.title), 42)
		button.name = "ManualChapter_%d" % number
		button.pressed.connect(func() -> void: open_chapter(number))
		_body.add_child(button)

func _render_competency(page: Dictionary) -> void:
	if page.is_empty():
		_render_index()
		return
	_heading.text = String(page.title)
	_subtitle.text = "Academy Manual · %s" % String(page.status.label)
	_back_button()
	_body.add_child(UiDesign.label(String(page.plain), "body", "ivory"))
	if not bool(page.unlocked):
		return
	for stage in CurriculumModel.STAGES:
		var events: Array = page.status.moments[stage]
		var title: String = String(stage).capitalize()
		_body.add_child(UiDesign.label(title, "heading", "accent" if not events.is_empty() else "muted"))
		if events.is_empty():
			_body.add_child(UiDesign.label("Still ahead in the expedition.", "caption", "muted"))
		for event in events:
			var card := _card("Moment_" + String(event.id).replace(":", "_"))
			card.add_child(_stacked_labels(String(event.mission_title), String(event.evidence)))
	_body.add_child(UiDesign.label("Real data behind this skill", "heading", "accent"))
	for card_data in page.data_cards:
		var source_id := String(card_data.id)
		var card := _card("ManualData_" + source_id)
		var col := _stacked_labels(String(card_data.title), String(card_data.takeaway))
		card.add_child(col)
		var button := UiDesign.button("Open data card", 38)
		button.name = "OpenData_" + source_id
		button.pressed.connect(func() -> void: data_card_requested.emit(source_id))
		col.add_child(button)
	_body.add_child(UiDesign.label("Science clips", "heading", "accent"))
	for clip in page.explainers:
		var clip_id := String(clip.id)
		var button := UiDesign.button("Watch: " + String(clip.title), 42)
		button.name = "ManualWatch_" + clip_id
		button.pressed.connect(func() -> void: explainer_requested.emit(clip_id))
		_body.add_child(button)
	_body.add_child(UiDesign.label("Your decisions", "heading", "accent"))
	if page.decisions.is_empty():
		_body.add_child(UiDesign.label("No choice from this skill is recorded in this save yet.", "body", "muted"))
	for decision in page.decisions:
		var card := _card("ManualChoice_" + String(decision.scene_id))
		card.add_child(_stacked_labels(String(decision.prompt), "You chose: %s\n%s" % [String(decision.choice), String(decision.consequence)]))

func _render_chapter(page: Dictionary) -> void:
	_heading.text = "What you learned"
	_subtitle.text = String(page.title)
	_back_button()
	_body.add_child(UiDesign.label("Three things you can now do", "heading", "accent"))
	var index := 0
	for thing in page.things:
		var source_id := String(thing.source_id)
		var card := _card("ChapterTakeaway_%d" % index)
		var col := _stacked_labels("%d. %s" % [index + 1, String(thing.text)], "Real data: %s\n%s" % [String(thing.source_title), String(thing.source_takeaway)])
		card.add_child(col)
		var source_button := UiDesign.button("Open data card", 38)
		source_button.name = "ChapterData_%d" % index
		source_button.pressed.connect(func() -> void: data_card_requested.emit(source_id))
		col.add_child(source_button)
		index += 1
	_body.add_child(UiDesign.label("One decision you made", "heading", "accent"))
	var decision: Dictionary = page.decision
	if decision.is_empty():
		_body.add_child(UiDesign.label("No choice from this chapter is recorded in this save.", "body", "muted"))
	else:
		var card := _card("ChapterDecisionReplay")
		card.add_child(_stacked_labels(String(decision.prompt), "You chose: %s\n%s" % [String(decision.choice), String(decision.consequence)]))

func _card(node_name: String) -> PanelContainer:
	var card := UiDesign.glass_panel(Color.TRANSPARENT, 12)
	card.name = node_name
	_body.add_child(card)
	return card

func _stacked_labels(heading: String, detail: String) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.add_child(UiDesign.label(heading, "body", "ivory"))
	col.add_child(UiDesign.label(detail, "caption", "muted"))
	return col

func _back_button() -> void:
	var button := UiDesign.button("Back to Manual", 38)
	button.name = "ManualBack"
	button.pressed.connect(open_index)
	_body.add_child(button)

func _scale() -> void:
	if is_inside_tree():
		UiDesign.apply_type(self, get_viewport_rect().size.y, 1.5 if bool(_settings.get("large_text", false)) else 1.0)

func _focus_first() -> void:
	if not is_inside_tree() or not visible:
		return
	# Start at the top of every page. The index opens on Close so the first
	# enabled row below the fold does not scroll the list away from its start.
	var candidate := _body.find_child("ManualBack", true, false) as Button
	if candidate == null:
		candidate = find_child("CloseAcademyManual", true, false) as Button
	if candidate != null and not candidate.disabled:
		candidate.grab_focus()
	_scroll.scroll_vertical = 0

func _unhandled_key_input(event: InputEvent) -> void:
	if not visible:
		return
	var back_pad: bool = event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B
	if (event.is_action_pressed("ui_cancel") or back_pad) and not event.is_echo():
		if _page_kind == "index":
			close_manual()
		else:
			open_index()
		get_viewport().set_input_as_handled()
