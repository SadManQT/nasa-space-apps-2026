extends Control
class_name HintPlayer

## One presentation-only reader shared by the table, Journal and What now.
signal opened
signal closed
signal highlight_changed(active: bool)
const Card = preload("res://scripts/ui/how_to_card.gd")
const REGISTRY := "res://resources/campaign/content/explainers.json"
var seen_path := "user://how_to_seen.cfg"
var level := 0
var mode := "hint"
var highlight_target: Control
var video: VideoStreamPlayer
var caption: Label
var _shade: ColorRect
var _frame: PanelContainer
var _stack: VBoxContainer
var _body: VBoxContainer
var _scroll: ScrollContainer
var _highlight: Panel
var _levels := {}
var _context := ""
var _lesson: Dictionary = {}
var _settings := {"captions": true, "large_text": false, "reduced_motion": false}
var _last_focus: Control
var _entry: Dictionary = {}
var _first_time_id := ""
var _notice := ""
var _still_pending := false
var _still_wait := 0.0
var _still_sample := 0.0
var _still_target := 0.1

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 200
	theme = UiKit.theme()
	_shade = ColorRect.new()
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shade.color = Color(0, 0, 0, 0.55)
	_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_shade)
	_highlight = Panel.new()
	_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := UiDesign.glass_style(UiDesign.colour("accent"), Color.TRANSPARENT, 0)
	style.bg_color = Color.TRANSPARENT
	style.set_border_width_all(3)
	_highlight.add_theme_stylebox_override("panel", style)
	add_child(_highlight)
	_frame = UiDesign.glass_panel(UiDesign.colour("accent"))
	_frame.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_frame)
	_frame.minimum_size_changed.connect(_layout.call_deferred)
	get_viewport().size_changed.connect(_layout)
	hide()

func is_open() -> bool:
	return visible

func set_settings(settings: Dictionary) -> void:
	var reduced_before: bool = _settings.reduced_motion
	for key in _settings:
		if settings.get(key) is bool:
			_settings[key] = settings[key]
	if visible and reduced_before != _settings.reduced_motion:
		_render()
	var transcript := find_child("StillCaptions", true, false) as Control
	if transcript != null:
		transcript.visible = bool(_settings.captions)
	if is_instance_valid(caption):
		caption.visible = bool(_settings.captions)
	if visible:
		UiDesign.apply_type(_frame, get_viewport_rect().size.y, 1.5 if _settings.large_text else 1.0)
		_layout()

func request_hint(context: String, lesson: Dictionary, target: Control = null) -> void:
	if visible:
		return
	_context = context
	_lesson = lesson.duplicate(true)
	highlight_target = target
	level = mini(3, int(_levels.get(context, 0)) + 1)
	_levels[context] = level
	mode = "hint"
	_begin()

func show_how_to(id: String, first_time: bool = false, target: Control = null) -> void:
	if visible or Card.lesson(id).is_empty() or (first_time and has_seen(id)):
		return
	_lesson = Card.lesson(id)
	highlight_target = target
	_first_time_id = id if first_time else ""
	mode = "how_to"
	level = 0
	_begin()

func has_seen(id: String) -> bool:
	var config := _seen_config()
	return config != null and config.get_value("seen", id, false) == true

func _seen_config() -> ConfigFile:
	var config := ConfigFile.new()
	if not FileAccess.file_exists(seen_path):
		return config
	if config.load(seen_path) != OK:
		return null
	for section in config.get_sections():
		if section != "seen":
			return null
		for id in config.get_section_keys(section):
			if Card.lesson(id).is_empty() or not config.get_value(section, id) is bool:
				return null
	return config

func _remember(id: String) -> bool:
	var config := _seen_config()
	if config == null:
		return false
	config.set_value("seen", id, true)
	var pending := seen_path + ".tmp"
	if config.save(pending) != OK:
		return false
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(pending), ProjectSettings.globalize_path(seen_path)) != OK:
		DirAccess.remove_absolute(pending)
		return false
	return true

func _begin() -> void:
	_last_focus = get_viewport().gui_get_focus_owner()
	show()
	_render()
	opened.emit()
	highlight_changed.emit(mode == "hint" and level == 1)

func close() -> void:
	if not visible:
		return
	if not _first_time_id.is_empty():
		if not _remember(_first_time_id):
			_notice = "Teaching preference could not be saved; this card may appear again."
		_first_time_id = ""
	if is_instance_valid(video):
		video.stop()
	_still_pending = false
	hide()
	highlight_changed.emit(false)
	closed.emit()
	if is_instance_valid(_last_focus) and _last_focus.is_visible_in_tree() and not (_last_focus is BaseButton and _last_focus.disabled):
		_last_focus.grab_focus()
	_last_focus = null

func _render() -> void:
	video = null
	caption = null
	_entry = {}
	_still_pending = false
	for child in _frame.get_children():
		_frame.remove_child(child)
		child.queue_free()
	_stack = VBoxContainer.new()
	_stack.add_theme_constant_override("separation", 12)
	_frame.add_child(_stack)
	var heading := String(_lesson.get("title", "How to"))
	if mode == "concept":
		heading = "Concept - " + heading
	elif mode == "hint":
		heading = "Hint %d of 3 - %s" % [level, ["Nudge", "Explainer", "Worked method"][level - 1]]
	_stack.add_child(UiDesign.label(heading, "heading", "accent"))
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.follow_focus = true
	_stack.add_child(_scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 12)
	_scroll.add_child(_body)
	if mode == "how_to":
		var card := Card.new()
		_body.add_child(card)
		card.show_lesson(_lesson)
		card.clip_requested.connect(func():
			mode = "concept"
			_render())
	elif level == 1 and mode == "hint":
		_body.add_child(UiDesign.label(String(_lesson.get("nudge", "Compare the marked object with your goal."))))
	elif level == 2 or mode == "concept":
		_render_media()
	else:
		_body.add_child(UiDesign.label(String(_lesson.get("example", "Different example unavailable. Compare the evidence with the goal."))))
	if not _notice.is_empty():
		_stack.add_child(UiDesign.label(_notice, "caption", "accent"))
	_stack.add_child(UiDesign.label("Reading pauses the clock. Hints never change your ending or rewards.", "caption", "muted"))
	var actions := HFlowContainer.new()
	actions.add_theme_constant_override("h_separation", 8)
	actions.add_theme_constant_override("v_separation", 8)
	_stack.add_child(actions)
	if mode == "hint" and level < 3:
		_add_action(actions, "Request next hint", "NextHint", func():
			level += 1
			_levels[_context] = level
			_render()
			highlight_changed.emit(false))
	elif mode == "concept":
		_add_action(actions, "Back to How to", "BackToHowTo", func():
			mode = "how_to"
			_render())
	_add_action(actions, "Start planning" if not _first_time_id.is_empty() else "Close (Esc / B)", "CloseHint", close)
	UiDesign.apply_type(_frame, get_viewport_rect().size.y, 1.5 if _settings.large_text else 1.0)
	_layout()
	_trap_focus()
	(actions.get_child(0) as Control).grab_focus()

func _add_action(parent: Node, text: String, id: String, action: Callable) -> void:
	var button := UiDesign.button(text)
	button.name = id
	button.pressed.connect(action)
	parent.add_child(button)

func _render_media() -> void:
	var registry = JSON.parse_string(FileAccess.get_file_as_string(REGISTRY))
	for entry in registry.get("explainers", []) if registry is Dictionary else []:
		if entry is Dictionary and entry.get("id", "") == _lesson.get("clip", ""):
			_entry = entry
			break
	var path := String(_entry.get("path", ""))
	var stream = load(path) if path.begins_with("res://assets/explainers/") and ResourceLoader.exists(path) else null
	if not stream is VideoStream:
		_body.add_child(UiDesign.label("Clip unavailable - read the concept instead.", "body", "accent"))
		_body.add_child(UiDesign.label(String(_lesson.get("relationship", "Compare the evidence with your goal."))))
		video = VideoStreamPlayer.new()
		_body.add_child(video)
		return
	_body.add_child(UiDesign.label(String(_entry.get("title", "The concept")), "body"))
	var aspect := AspectRatioContainer.new()
	aspect.name = "Explainer16by9"
	aspect.ratio = 16.0 / 9.0
	aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	aspect.custom_minimum_size.y = 220
	aspect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_child(aspect)
	video = VideoStreamPlayer.new()
	video.name = "HintVideo"
	video.expand = true
	video.stream = stream
	aspect.add_child(video)
	caption = UiDesign.label("", "body")
	caption.name = "HintCaption"
	caption.visible = bool(_settings.captions)
	_body.add_child(caption)
	if bool(_settings.reduced_motion):
		# Decode muted off-screen to the first science caption, then expose a still.
		video.modulate.a = 0.0
		video.volume_db = -80
		_still_pending = true
		_still_wait = 0.0
		_still_sample = 0.0
		var captions: Array = _entry.get("captions", [])
		_still_target = maxf(0.1, float(captions[0].get("start", 0.1))) if not captions.is_empty() else 0.1
		video.play()
		var status := UiDesign.label("Preparing a still. Read the caption cards below.", "caption", "accent")
		status.name = "StillStatus"
		_body.add_child(status)
		var transcript := VBoxContainer.new()
		transcript.name = "StillCaptions"
		transcript.visible = bool(_settings.captions)
		_body.add_child(transcript)
		for item in _entry.get("captions", []):
			transcript.add_child(UiDesign.label(String(item.get("text", ""))))
	else:
		video.play()
		var controls := HFlowContainer.new()
		controls.add_theme_constant_override("h_separation", 8)
		_body.add_child(controls)
		_add_action(controls, "Pause", "PauseClip", toggle_pause)
		_add_action(controls, "Replay", "ReplayClip", replay)
	_body.add_child(UiDesign.label(String(_lesson.get("relationship", _entry.get("ends_on", "")))))

func toggle_pause() -> void:
	if is_instance_valid(video) and video.stream != null and not bool(_settings.reduced_motion):
		video.paused = not video.paused
		var button := find_child("PauseClip", true, false) as Button
		if button != null:
			button.text = "Play" if video.paused else "Pause"

func replay() -> void:
	if is_instance_valid(video) and video.stream != null and not bool(_settings.reduced_motion):
		video.stop()
		video.paused = false
		video.play()
		var button := find_child("PauseClip", true, false) as Button
		if button != null:
			button.text = "Pause"

func update_caption(time: float) -> void:
	if not is_instance_valid(caption):
		return
	caption.text = ""
	for item in _entry.get("captions", []):
		if time >= float(item.get("start", 0)) and time < float(item.get("end", 0)):
			caption.text = String(item.get("text", ""))
			break

func _process(delta: float) -> void:
	if not visible:
		return
	_highlight.visible = mode == "hint" and level == 1 and is_instance_valid(highlight_target) and highlight_target.is_visible_in_tree()
	if _highlight.visible:
		_highlight.position = highlight_target.get_global_rect().position - global_position - Vector2(4, 4)
		_highlight.size = highlight_target.size + Vector2(8, 8)
	if is_instance_valid(video) and video.stream != null:
		if _still_pending:
			_still_wait += delta
			_still_sample += delta
			if _still_sample >= 0.1:
				_still_sample = 0.0
				if _has_visible_frame():
					video.paused = true
					video.modulate.a = 1.0
					_still_pending = false
					(find_child("StillStatus", true, false) as Label).text = "Reduced motion - still from this clip. Read its caption cards."
			if _still_pending and (_still_wait >= 8.0 or DisplayServer.get_name() == "headless"):
				video.paused = true
				_still_pending = false
				video.get_parent().hide()
				(find_child("StillStatus", true, false) as Label).text = "Still unavailable - read the concept and caption cards instead."
		if not bool(_settings.reduced_motion):
			update_caption(video.stream_position)

func _has_visible_frame() -> bool:
	# An allocated video texture can still be blank before its first decoded frame.
	if DisplayServer.get_name() == "headless" or video.stream_position < _still_target:
		return false
	var texture := video.get_video_texture()
	if texture == null:
		return false
	var image := texture.get_image()
	if image == null or image.is_empty():
		return false
	image.resize(16, 9)
	var darkest := 1.0
	var lightest := 0.0
	for y in image.get_height():
		for x in image.get_width():
			var light := image.get_pixel(x, y).get_luminance()
			darkest = minf(darkest, light)
			lightest = maxf(lightest, light)
	return lightest > 0.08 and lightest - darkest > 0.05

func _layout() -> void:
	if not is_instance_valid(_frame):
		return
	var view := get_viewport_rect().size
	var nudge := mode == "hint" and level == 1
	_frame.size = Vector2(minf(840, view.x - 48), minf(320 if _settings.large_text else 260, view.y - 48) if nudge else minf(650, view.y - 48))
	_frame.position = Vector2((view.x - _frame.size.x) * 0.5, view.y - _frame.size.y - 24 if nudge else (view.y - _frame.size.y) * 0.5)

func _trap_focus() -> void:
	var buttons: Array = _frame.find_children("*", "Button", true, false)
	for index in buttons.size():
		var button: Control = buttons[index]
		var previous: Control = buttons[posmod(index - 1, buttons.size())]
		var next: Control = buttons[(index + 1) % buttons.size()]
		button.focus_previous = previous.get_path()
		button.focus_next = next.get_path()
		button.focus_neighbor_top = previous.get_path()
		button.focus_neighbor_left = previous.get_path()
		button.focus_neighbor_bottom = next.get_path()
		button.focus_neighbor_right = next.get_path()

func _input(event: InputEvent) -> void:
	if not visible or event.is_echo():
		return
	var key: bool = event is InputEventKey and event.pressed
	var pad: bool = event is InputEventJoypadButton and event.pressed
	if (key and event.physical_keycode == KEY_ESCAPE) or event.is_action_pressed("ui_cancel") or (pad and event.button_index == JOY_BUTTON_B):
		close()
		get_viewport().set_input_as_handled()
	elif (key and event.physical_keycode in [KEY_SPACE, KEY_H]) or (pad and event.button_index == JOY_BUTTON_Y):
		get_viewport().set_input_as_handled()
