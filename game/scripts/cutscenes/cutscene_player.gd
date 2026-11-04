## Full-screen cutscene presentation for the campaign. Plays a plan from
## CampaignCutsceneRuntime: the OGV (captions are burned into every film) or,
## when the file is missing, the scene's exact lines as a text card. Hold Esc,
## Enter, controller B or the on-screen button to skip; Space, P or Start pauses.
## Closing reports what was seen; it never completes a predicate, scene or puzzle.
extends CanvasLayer
class_name CampaignCutscenePlayer

signal closed(result: Dictionary)

## Off in headless runs (tests, CPU probes) and the export smoke check; the
## windowed perf probe turns it off too. Tests turn it on explicitly.
static var autoplay := DisplayServer.get_name() != "headless" and not OS.get_cmdline_user_args().has("--export-smoke")
var skip_hold_s := 1.0
var plan: Dictionary = {}
var video: VideoStreamPlayer
var held_s := 0.0
var _frame: AspectRatioContainer
var _fallback: PanelContainer
var _fallback_text: Label
var _hint: Label
var _hold_bar: ProgressBar
var _pause_button: Button
var _pointer_hold := false
var _armed := false

func _ready() -> void:
	layer = 200
	var shade := ColorRect.new()
	shade.color = Color.BLACK
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	_frame = AspectRatioContainer.new()
	_frame.ratio = 16.0 / 9.0
	_frame.stretch_mode = AspectRatioContainer.STRETCH_FIT
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.add_child(_frame)
	video = VideoStreamPlayer.new()
	video.expand = true
	video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(video)
	video.finished.connect(func() -> void: _close(false, true))
	_fallback = PanelContainer.new()
	_fallback.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_fallback.custom_minimum_size = Vector2(760, 0)
	_fallback.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_fallback.grow_vertical = Control.GROW_DIRECTION_BOTH
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#1F2A44")
	style.border_color = Color("#F2C230")
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(24)
	_fallback.add_theme_stylebox_override("panel", style)
	shade.add_child(_fallback)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	_fallback.add_child(box)
	_fallback_text = Label.new()
	_fallback_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fallback_text.add_theme_color_override("font_color", Color("#ECEEF0"))
	_fallback_text.add_theme_font_size_override("font_size", 18)
	box.add_child(_fallback_text)
	var go_on := _button("CONTINUE  ›")
	go_on.pressed.connect(func() -> void: _close(false))
	box.add_child(go_on)
	var bar := HBoxContainer.new()
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = 24
	bar.offset_top = 18
	bar.offset_right = -24
	bar.add_theme_constant_override("separation", 12)
	shade.add_child(bar)
	var skip := _button("HOLD TO SKIP")
	skip.button_down.connect(func() -> void: _pointer_hold = true)
	skip.button_up.connect(func() -> void: _pointer_hold = false)
	bar.add_child(skip)
	_pause_button = _button("PAUSE")
	_pause_button.pressed.connect(toggle_pause)
	bar.add_child(_pause_button)
	_hold_bar = ProgressBar.new()
	_hold_bar.custom_minimum_size = Vector2(120, 10)
	_hold_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_hold_bar.show_percentage = false
	_hold_bar.max_value = 1.0
	bar.add_child(_hold_bar)
	_hint = Label.new()
	_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.add_theme_color_override("font_color", Color("#A8B4C8"))
	_hint.add_theme_color_override("font_outline_color", Color("#05060A"))
	_hint.add_theme_constant_override("outline_size", 4)
	_hint.add_theme_font_size_override("font_size", 13)
	bar.add_child(_hint)
	hide()

## True while a film or its text card is on screen.
func is_active() -> bool:
	return visible

## Shows one plan: the OGV in "video" mode, else the exact-text card.
func play(next_plan: Dictionary) -> void:
	plan = next_plan.duplicate(true)
	held_s = 0.0
	_pointer_hold = false
	_armed = false
	var is_video := String(plan.get("mode", "")) == "video"
	_frame.visible = is_video
	_fallback.visible = not is_video
	_pause_button.visible = is_video
	show()
	if is_video:
		video.stream = load(String(plan.runtime_path)) as VideoStream
		video.paused = false
		video.play()
	else:
		var rows: Array = []
		for line in plan.get("captions", []):
			rows.append("%s  ·  %s\n%s" % [String(line.get("speaker", "")), String(line.get("origin_label", "")), String(line.get("text", ""))])
		_fallback_text.text = "%s  ·  %s\nThe film is not installed; the scene's exact lines follow.\n\n%s" % [String(plan.get("cutscene_id", "")), String(plan.get("title", "")), "\n\n".join(rows)]
	_update_hint()

## Pauses or resumes the film.
func toggle_pause() -> void:
	if visible and _frame.visible:
		video.paused = not video.paused
		_update_hint()

## Ends the film now as a skip (presentation only).
func skip() -> void:
	_close(true)

## Seconds of the film shown so far (0 for the text card).
func position_s() -> float:
	return video.stream_position if visible and _frame.visible else 0.0

func _process(delta: float) -> void:
	if not visible:
		return
	var holding := _pointer_hold or Input.is_physical_key_pressed(KEY_ESCAPE) or Input.is_physical_key_pressed(KEY_ENTER) or Input.is_joy_button_pressed(0, JOY_BUTTON_B)
	# A key still held from before the film started (e.g. Enter on ADVANCE) never counts.
	_armed = _armed or not holding
	held_s = held_s + delta if holding and _armed else 0.0
	_hold_bar.value = clampf(held_s / maxf(skip_hold_s, 0.01), 0.0, 1.0)
	if held_s >= skip_hold_s:
		skip()
		return
	var texture := video.get_video_texture()
	if _frame.visible and texture != null and texture.get_height() > 0:
		_frame.ratio = float(texture.get_width()) / texture.get_height()

## Every key and button press belongs to the film while it is up, so nothing
## underneath (USE, ADVANCE, pause panel) can be triggered through it.
func _input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey or event is InputEventJoypadButton):
		return
	get_viewport().set_input_as_handled()
	if not event.pressed or event.is_echo():
		return
	var key: int = event.physical_keycode if event is InputEventKey else -1
	var start: bool = event is InputEventJoypadButton and event.button_index == JOY_BUTTON_START
	if _frame.visible and (key in [KEY_SPACE, KEY_P] or start):
		toggle_pause()
	elif not _frame.visible and (key in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER] or start):
		_close(false)

func _close(skipped: bool, reached_end: bool = false) -> void:
	if not visible:
		return
	var position := INF if reached_end else position_s()
	var mode := String(plan.get("mode", ""))
	video.stop()
	video.stream = null
	hide()
	var result := {
		"cutscene_id": String(plan.get("cutscene_id", "")),
		"scene_id": String(plan.get("scene_id", "")),
		"mode": mode,
		"skipped": skipped,
		"position_s": position,
		"completes_predicate": false,
		"completes_scene": false,
		"completes_mission": false,
		"events": [{"type": "cutscene_skipped" if skipped else "cutscene_finished", "cutscene_id": String(plan.get("cutscene_id", ""))}],
	}
	plan = {}
	closed.emit(result)

func _update_hint() -> void:
	_pause_button.text = "RESUME" if video.paused else "PAUSE"
	if _frame.visible:
		_hint.text = ("PAUSED  ·  " if video.paused else "") + "%s  ·  Hold Esc / Enter to skip  ·  Space to pause" % String(plan.get("title", plan.get("cutscene_id", "")))
	else:
		_hint.text = "Space / Enter to continue  ·  Hold Esc to skip"

func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 34)
	button.add_theme_font_size_override("font_size", 13)
	return button
