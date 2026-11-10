extends Control
class_name JobsBoardPanel

## M3-64: Station Jobs Board (doc 25 §4.6). Shows optional deliveries, surveys,
## maintenance and science runs per chapter region, each with a crew sender and
## reason in Messages, paying in cadet skill progress and crew notes (never
## locking story progress).

signal closed
signal job_completed(result: Dictionary)
signal job_started(result: Dictionary)
var _runtime: Node
var settings: Dictionary = {}

var progression: CadetProgression
var selected_chapter: int = 1
var max_unlocked_chapter: int = 8

var _backdrop: ColorRect
var _panel: PanelContainer
var _chapter_row: HBoxContainer
var _list_box: VBoxContainer
var _status_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()

func bind_progression(value: CadetProgression, unlocked_up_to: int = 8) -> void:
	progression = value
	max_unlocked_chapter = clampi(unlocked_up_to, 1, 8)
	selected_chapter = mini(selected_chapter, max_unlocked_chapter)
	refresh()

func bind_runtime(runtime: Node) -> void:
	_runtime = runtime
	var query: Dictionary = runtime.call("query")
	settings = query.get("accessibility", {})
	selected_chapter = clampi(int(String(query.get("chapter_id", "CH01")).trim_prefix("CH")), 1, 8)
	bind_progression(runtime.get("progression"), selected_chapter)

func _build() -> void:
	_backdrop = ColorRect.new()
	_backdrop.color = Color(0.02, 0.03, 0.06, 0.78)
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_backdrop)

	_panel = UiDesign.glass_panel(Color.TRANSPARENT, 24)
	_panel.name = "JobsBoardGlass"
	_panel.custom_minimum_size = Vector2.ZERO
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.offset_left = 24
	_panel.offset_top = 24
	_panel.offset_right = -24
	_panel.offset_bottom = -24
	add_child(_panel)

	var root_col := VBoxContainer.new()
	root_col.add_theme_constant_override("separation", 12)
	_panel.add_child(root_col)

	var header := HBoxContainer.new()
	root_col.add_child(header)

	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titles)
	titles.add_child(UiDesign.label("Station Jobs Board", "title", "ivory"))
	titles.add_child(UiDesign.label("Optional deliveries, surveys, maintenance and science runs from the crew (pays in skill progress, never locks story).", "caption", "muted"))

	var close_btn := UiDesign.button("Close (Esc)", 40)
	close_btn.pressed.connect(func() -> void:
		hide()
		closed.emit())
	header.add_child(close_btn)

	_chapter_row = HBoxContainer.new()
	_chapter_row.add_theme_constant_override("separation", 6)
	root_col.add_child(_chapter_row)

	var scroll := ScrollContainer.new()
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_col.add_child(scroll)

	_list_box = VBoxContainer.new()
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_box.add_theme_constant_override("separation", 10)
	scroll.add_child(_list_box)

	_status_label = UiDesign.label("", "caption", "accent")
	root_col.add_child(_status_label)

func refresh() -> void:
	if _list_box == null:
		return
	if progression == null:
		progression = CadetProgression.new()
	for child in _chapter_row.get_children():
		child.free()
	for ch in range(1, max_unlocked_chapter + 1):
		var btn := UiDesign.button("Ch %d" % ch, 36)
		btn.pressed.connect(func() -> void:
			selected_chapter = ch
			refresh())
		_chapter_row.add_child(btn)

	for child in _list_box.get_children():
		child.free()

	for job in progression.jobs_for_chapter(selected_chapter):
		var done := bool(job.get("completed", false))
		var card := UiDesign.glass_panel(UiDesign.colour("good") if done else Color.TRANSPARENT, 14)
		_list_box.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		card.add_child(row)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 4)
		row.add_child(col)
		col.add_child(UiDesign.label("%s · %s (%s)" % [
			String(job.title), String(job.kind).capitalize(), "Completed" if done else "Available"
		], "heading", "accent" if done else "ivory"))
		col.add_child(UiDesign.label("From %s · %s" % [String(job.sender), String(job.reason)], "body", "ivory"))
		col.add_child(UiDesign.label("Trains: %s (+%d XP) · %s" % [
			String(job.skill).replace("_", " ").capitalize(), int(job.xp), String(job.crew_note)
		], "caption", "muted"))
		var job_id := String(job.id)
		var metrics: Dictionary = _runtime.call("job_metrics", job_id) if _runtime != null else {}
		var ready := bool(metrics.get("complete", metrics.get("ready", false)))
		var btn := UiDesign.button("Done" if done else ("File Report" if ready else "Begin Job"), 44)
		btn.name = "Job_" + job_id
		btn.disabled = done
		btn.pressed.connect(func() -> void:
			var res: Dictionary
			if _runtime == null:
				res = progression.complete_job(job_id, max_unlocked_chapter)
			elif ready:
				res = _runtime.call("complete_job", job_id, _runtime.call("job_metrics", job_id))
			else:
				res = _runtime.call("begin_job", job_id)
				if res.get("accepted", false):
					job_started.emit(res)
			_status_label.text = String(res.get("crew_note", res.get("reason", "")))
			if bool(res.get("accepted", false)) and (_runtime == null or ready):
				job_completed.emit(res)
			refresh())
		row.add_child(btn)
	UiDesign.apply_type(self, get_viewport_rect().size.y if is_inside_tree() else 720.0, 1.5 if settings.get("large_text", false) else 1.0)
