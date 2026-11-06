## Full-screen cutscene presentation for the campaign. Plays a plan from
## CampaignCutsceneRuntime: the OGV (captions are burned into every film) or,
## when the file is missing, the scene's exact lines as a text card. Hold Esc,
## Enter, controller B or the on-screen button to skip; Space, P or Start pauses.
## A plan's choice_card (CS-18's D13 dedication) puts the chosen option's words
## small at the bottom of the closing black, holding the silent black past the
## film's end until the card's hide time.
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
## Returns the campaign snapshot this player reads (never writes) for a
## save-dependent card: story_log.choices and accessibility. Unset, the player
## asks the node it was added to for its `director` (the campaign has one).
var snapshot_source: Callable
## The plan's choice_card when the save recorded its option, else {}.
var choice_card: Dictionary = {}
var _card: Label
var _card_scale := 1.0
var _card_reduced_motion := false
var _card_shown := false
var _film_ended := false
var _film_s := 0.0
var _end_position_s := 0.0
var _hold_s := 0.0
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
	video.finished.connect(_on_film_finished)
	# Sits in the film's own 16:9 box, where the burned captions sit.
	var card_box := Control.new()
	card_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(card_box)
	_card = UiDesign.label("", "body", "ivory")
	_card.name = "ChoiceCard"
	_card.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_card.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_card.visible = false
	card_box.add_child(_card)
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
	_film_ended = false
	_film_s = 0.0
	_end_position_s = 0.0
	_hold_s = 0.0
	_card_shown = false
	choice_card = _chosen_card(plan)
	_card.visible = false
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
		if not choice_card.is_empty():
			rows.append(String(choice_card.text))
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

## Seconds of the film shown so far (0 for the text card); past the film's end
## it keeps counting through a choice card's silent hold.
func position_s() -> float:
	if not visible or not _frame.visible:
		return 0.0
	return _end_position_s + _hold_s if _film_ended else video.stream_position

## The choice card's words while they are on screen, else "".
func choice_card_text() -> String:
	return _card.text if _card.visible else ""

## Opacity of a choice card at film time `t`: 0 before show_at_s and from
## hide_at_s, rising and falling over fade_s (a cut when motion is reduced).
static func card_alpha(card: Dictionary, t: float, reduced_motion: bool = false) -> float:
	if card.is_empty():
		return 0.0
	var show_at := float(card.get("show_at_s", 0.0))
	var hide_at := float(card.get("hide_at_s", 0.0))
	if t < show_at or t >= hide_at:
		return 0.0
	var fade := 0.0 if reduced_motion else float(card.get("fade_s", 0.0))
	if fade <= 0.0:
		return 1.0
	return clampf(minf(t - show_at, hide_at - t) / fade, 0.0, 1.0)

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
	if _film_ended and not video.paused:
		_hold_s += delta
	elif _frame.visible and not _film_ended:
		_film_s = maxf(_film_s, video.stream_position)
	_update_card()
	if _film_ended and position_s() >= float(choice_card.get("hide_at_s", 0.0)):
		_close(false, true)

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

## The film's last frame: close, unless a choice card still needs the black.
func _on_film_finished() -> void:
	if not visible:
		return
	# The playback clock resets to 0 at the end; keep the film's own time.
	var at := maxf(_film_s, video.get_stream_length())
	if choice_card.is_empty() or at >= float(choice_card.get("hide_at_s", 0.0)):
		_close(false, true)
		return
	_film_ended = true
	_end_position_s = at

func _chosen_card(next_plan: Dictionary) -> Dictionary:
	var card: Variant = next_plan.get("choice_card", {})
	if not card is Dictionary or (card as Dictionary).is_empty():
		return {}
	var snapshot := _campaign_snapshot()
	var story_log: Variant = snapshot.get("story_log", {})
	var choices: Variant = (story_log as Dictionary).get("choices", {}) if story_log is Dictionary else {}
	var entry: Variant = (choices as Dictionary).get(String((card as Dictionary).get("choice_id", "")), {}) if choices is Dictionary else {}
	var recorded := String((entry as Dictionary).get("option_id", "")) if entry is Dictionary else ""
	if recorded.is_empty() or recorded != String((card as Dictionary).get("option_id", "")):
		return {}
	var settings: Variant = snapshot.get("accessibility", {})
	var accessibility: Dictionary = settings if settings is Dictionary else {}
	_card_scale = float(UiDesign.tokens().get("type", {}).get("large_text_scale", 1.5)) if bool(accessibility.get("large_text", false)) else 1.0
	_card_reduced_motion = UiDesign.reduced_motion(accessibility)
	return (card as Dictionary).duplicate(true)

func _campaign_snapshot() -> Dictionary:
	var value: Variant = null
	if snapshot_source.is_valid():
		value = snapshot_source.call()
	else:
		var host := get_parent()
		var director: Object = host.get("director") as Object if host != null and "director" in host else null
		if director != null and director.has_method("snapshot"):
			value = director.call("snapshot")
	return value if value is Dictionary else {}

func _update_card() -> void:
	var alpha := card_alpha(choice_card, position_s(), _card_reduced_motion) if _frame.visible else 0.0
	_card.visible = alpha > 0.0
	if not _card.visible:
		return
	if _card.text != String(choice_card.text):
		_card.text = String(choice_card.text)
		UiDesign.style_label(_card, String(choice_card.get("type", "body")), String(choice_card.get("colour", "ivory")))
	var height := _frame.size.y if _frame.size.y > 0.0 else get_viewport().get_visible_rect().size.y
	_card.add_theme_font_size_override("font_size", UiDesign.font_px(String(choice_card.get("type", "body")), height, _card_scale))
	var margin := float(UiDesign.px(float(UiDesign.tokens().get("panel", {}).get("safe_margin", 64)), height))
	_card.offset_left = margin
	_card.offset_right = -margin
	_card.offset_bottom = -margin
	_card.offset_top = -margin
	_card.modulate.a = alpha
	_card_shown = true

func _close(skipped: bool, reached_end: bool = false) -> void:
	if not visible:
		return
	var position := INF if reached_end else position_s()
	var mode := String(plan.get("mode", ""))
	var card_text := String(choice_card.get("text", "")) if _card_shown else ""
	video.stop()
	video.stream = null
	choice_card = {}
	_film_ended = false
	_card.visible = false
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
		"choice_card": card_text,
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
