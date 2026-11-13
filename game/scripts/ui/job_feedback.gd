extends Control
class_name JobFeedback

## The "job done" moment for young players (M1-129, 13 Nov review: "the user cannot even know what is
## happening" after pressing E). A finished job gets one clear card in the upper centre: a green tick,
## the job's own result line, what changed and what comes next. After a hands-on job the card offers an
## optional star challenge: a needle sweeps a gauge and a click (or controller X) while it is in the green
## band earns a cadet star. The challenge never blocks the story, never pauses the clock and never uses E,
## so the next job is always one E away. Stars are a separate per-player tally, not campaign state.

signal star_earned(total: int)
signal challenge_finished(hit: bool)

const STARS_PATH := "user://lla_cadet_stars.json"
const CARD_SECONDS := 4.5
const CHALLENGE_SECONDS := 7.0
const TIMER_FREE_CHALLENGE_SECONDS := 14.0
const RESULT_SECONDS := 1.6
const SWEEP_SECONDS := 1.7
const REDUCED_MOTION_SWEEP_SECONDS := 2.6
const ZONE_WIDTH := 0.22
const GAUGE_SIZE := Vector2(380, 22)

var settings: Dictionary = {}
var _card: PanelContainer
var _headline: Label
var _result: Label
var _changed: Label
var _next: Label
var _challenge_box: HBoxContainer
## Set by the HUD layout: the banner sits in the top gap between the goal card (left) and the
## toast/status column (right), at the same top margin as both.
var reserve_left := 0.0
var reserve_right := 0.0
var top_margin := 0.0
var below_cards := 0.0
var _challenge_label: Label
var _gauge: Gauge
var _outcome: Label
var _time_left := 0.0
var _challenge_active := false
var _needle_time := 0.0
var _tween: Tween
var _rng := RandomNumberGenerator.new()

## The sweeping needle and its green band, drawn in the house palette.
class Gauge extends Control:
	var needle := 0.0
	var zone_start := 0.4
	var zone_width := ZONE_WIDTH
	var result := 0  # 0 still playing, 1 hit, -1 miss
	func _init() -> void:
		custom_minimum_size = GAUGE_SIZE
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		draw_style_box(_box(Color(UiDesign.colour("ink"), 0.85), UiDesign.colour("glass_edge")), rect)
		var zone := Rect2(Vector2(size.x * zone_start, 3), Vector2(size.x * zone_width, size.y - 6))
		draw_style_box(_box(Color(UiDesign.colour("good"), 0.85 if result >= 0 else 0.35), Color.TRANSPARENT), zone)
		var x := clampf(needle, 0.0, 1.0) * size.x
		var tone := UiDesign.colour("ivory")
		if result == 1:
			tone = UiDesign.colour("good")
		elif result == -1:
			tone = UiDesign.colour("caution")
		draw_rect(Rect2(Vector2(x - 2.5, -5), Vector2(5, size.y + 10)), tone)
	func _box(fill: Color, edge: Color) -> StyleBoxFlat:
		var style := StyleBoxFlat.new()
		style.bg_color = fill
		style.set_corner_radius_all(6)
		if edge.a > 0.0:
			style.set_border_width_all(1)
			style.border_color = edge
		return style

func _ready() -> void:
	name = "JobFeedback"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rng.randomize()
	_build()
	hide_now()

func _build() -> void:
	_card = PanelContainer.new()
	_card.name = "JobDoneCard"
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.z_index = 30  # above the first-scenes controls strip and the world marker
	# Wrapped labels report their true height only after the first sort; shrink to it.
	_card.minimum_size_changed.connect(func() -> void: _card.reset_size.call_deferred())
	_card.add_theme_stylebox_override("panel", UiDesign.glass_style(UiDesign.colour("good"), Color(UiDesign.colour("glass"), 0.94), 14))
	add_child(_card)
	# A compact banner (doc 25 §8.2: nothing but the prompt and marker may reach the centre third
	# while the player walks): headline and result on one row, then next, then the challenge row.
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(box)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(top)
	var tick := UiDesign.LineIcon.new("check", UiDesign.colour("good"))
	tick.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top.add_child(tick)
	_headline = UiDesign.float_label(UiDesign.label("Job done!", "subhead", "good"))
	_headline.name = "Headline"
	_headline.autowrap_mode = TextServer.AUTOWRAP_OFF  # a two-word headline never wraps letter by letter
	_headline.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top.add_child(_headline)
	_result = UiDesign.float_label(UiDesign.label("", "body", "ivory"))
	_result.name = "Result"
	_result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_result)
	_next = UiDesign.label("", "caption", "accent")
	_next.name = "Next"
	box.add_child(_next)
	_changed = UiDesign.label("", "caption", "muted")
	_changed.name = "Changed"
	box.add_child(_changed)
	_challenge_box = HBoxContainer.new()
	_challenge_box.name = "StarChallenge"
	_challenge_box.add_theme_constant_override("separation", 12)
	_challenge_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_challenge_box)
	_challenge_label = UiDesign.label("", "caption", "caution")
	_challenge_label.name = "ChallengeLabel"
	_challenge_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_challenge_box.add_child(_challenge_label)
	_gauge = Gauge.new()
	_gauge.name = "Gauge"
	_gauge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_challenge_box.add_child(_gauge)
	# The outcome replaces the instruction on the same row once the player has pressed.
	_outcome = _challenge_label

## New accessibility settings; a banner already on screen re-applies its size rules at once
## (switching to 150 % text while it shows must not push it into the centre third).
func set_settings(value: Dictionary) -> void:
	settings = value
	if is_showing():
		_apply_size_rules()
		_layout()

## At 150 % text the banner keeps to its first row (result at most two lines) and the challenge.
func _apply_size_rules() -> void:
	var large := bool(settings.get("large_text", false))
	_changed.visible = not _changed.text.is_empty() and not large
	_next.visible = not _next.text.is_empty() and not large
	_result.max_lines_visible = 2 if large else -1
	_result.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS if large else TextServer.OVERRUN_NO_TRIMMING
	if _challenge_active:
		_challenge_label.text = "★ Click in the green!" if large else "★ Click when the needle is in the green!"

## Shows the card for a finished job. `challenge_name` is the job's own action ("Switch on the power
## path"); empty means no star challenge (puzzle decisions and chapter ends).
func show_done(result_line: String, changed: String = "", next_goal: String = "", challenge_name: String = "") -> void:
	_result.text = result_line if not result_line.is_empty() else "Well done."
	# Meter lines come from the feedback ledger and some use crew shorthand ("Acknowledged",
	# "staged"); only a line in player words is shown (doc 25 §8.1, the same rule as all HUD text).
	var meter := plain_meter(changed)
	var plain := not meter.is_empty() and UiDesign.banned_regex().search(meter) == null
	# At 150 % text the banner keeps to its first row and the challenge, so it stays out of the
	# centre third; the goal card already shows the next job.
	_changed.text = meter if plain else ""
	_next.text = ("Next ▸ " + next_goal) if not next_goal.is_empty() else ""
	_challenge_active = not challenge_name.is_empty()
	_challenge_box.visible = _challenge_active
	_outcome.remove_theme_color_override("font_color")
	_outcome.add_theme_color_override("font_color", UiDesign.colour("caution"))
	if _challenge_active:
		_challenge_label.text = "★ Click when the needle is in the green!"
		_challenge_label.tooltip_text = challenge_name
		_gauge.zone_start = _rng.randf_range(0.12, 0.88 - ZONE_WIDTH)
		_gauge.result = 0
		_needle_time = _rng.randf_range(0.0, SWEEP_SECONDS)
		_gauge.needle = _needle_at(_needle_time)
		_time_left = TIMER_FREE_CHALLENGE_SECONDS if bool(settings.get("timer_free", true)) else CHALLENGE_SECONDS
	else:
		_time_left = CARD_SECONDS
	_apply_size_rules()
	_layout()
	visible = true
	_card.visible = true
	_pop_in()

func is_showing() -> bool:
	return visible and _card.visible

func is_challenge_active() -> bool:
	return is_showing() and _challenge_active

## Resolves the star challenge with the needle where it is now (a click, or controller X).
func try_star() -> bool:
	if not is_challenge_active():
		return false
	return _resolve(_gauge.needle)

## The same resolution at an explicit needle position (0..1): tests and replays.
func resolve_at(position: float) -> bool:
	if not is_challenge_active():
		return false
	_gauge.needle = clampf(position, 0.0, 1.0)
	return _resolve(_gauge.needle)

func zone() -> Vector2:
	return Vector2(_gauge.zone_start, _gauge.zone_start + _gauge.zone_width)

func hide_now() -> void:
	_challenge_active = false
	_time_left = 0.0
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if _card != null:
		_card.visible = false
		_card.modulate.a = 1.0
	visible = false

func _resolve(position: float) -> bool:
	var hit := position >= _gauge.zone_start and position <= _gauge.zone_start + _gauge.zone_width
	_challenge_active = false
	_gauge.result = 1 if hit else -1
	_gauge.queue_redraw()
	if hit:
		var total := stars() + 1
		save_stars(total)
		_outcome.text = "★ +1 star! Great timing. You have %d %s." % [total, "star" if total == 1 else "stars"]
		_outcome.add_theme_color_override("font_color", UiDesign.colour("good"))
		star_earned.emit(total)
	else:
		_outcome.text = "So close! Try again on the next job."
		_outcome.add_theme_color_override("font_color", UiDesign.colour("caution"))
	_time_left = RESULT_SECONDS
	challenge_finished.emit(hit)
	return hit

func _input(event: InputEvent) -> void:
	if not is_challenge_active():
		return
	var click: bool = event is InputEventMouseButton and event.is_pressed() and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT
	var pad: bool = event is InputEventJoypadButton and event.is_pressed() and (event as InputEventJoypadButton).button_index == JOY_BUTTON_X
	if click or pad:
		try_star()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not is_showing():
		return
	if _challenge_active:
		_needle_time += delta
		_gauge.needle = _needle_at(_needle_time)
		_gauge.queue_redraw()
	_time_left -= delta
	if _time_left <= 0.0:
		if _challenge_active:
			_challenge_active = false
			_outcome.text = "The star waits for the next job."
			_time_left = RESULT_SECONDS
			challenge_finished.emit(false)
			return
		_fade_out()

## Ping-pong sweep, eased at the ends so the needle is readable.
func _needle_at(seconds: float) -> float:
	var period := REDUCED_MOTION_SWEEP_SECONDS if UiDesign.reduced_motion(settings) else SWEEP_SECONDS
	return 0.5 - 0.5 * cos(TAU * seconds / (2.0 * period))

func _layout() -> void:
	var view := get_viewport_rect().size
	var margin := top_margin if top_margin > 0.0 else float(UiDesign.px(64, view.y))
	var left := maxf(reserve_left, margin)
	var right := maxf(reserve_right, margin)
	var available := view.x - left - right
	var width := minf(float(UiDesign.px(760, view.y)), available)
	var x := left + (available - width) * 0.5
	var y := margin
	if width < float(UiDesign.px(420, view.y)):
		# A narrow window leaves no gap between the cards: centre the banner under the goal card.
		width = minf(float(UiDesign.px(680, view.y)), view.x - margin * 2.0)
		x = (view.x - width) * 0.5
		y = maxf(margin, below_cards)
	_card.custom_minimum_size = Vector2(width, 0)
	_card.size = Vector2(width, 0)
	_card.reset_size()
	_card.position = Vector2(x, y)
	_gauge.custom_minimum_size = Vector2(float(UiDesign.px(220, view.y)), float(UiDesign.px(20, view.y)))

## The banner's rectangle while it shows (the HUD keeps projected prompts clear of it).
func card_rect() -> Rect2:
	return Rect2(_card.position, _card.size) if is_showing() else Rect2()

func _pop_in() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if UiDesign.reduced_motion(settings) or not is_inside_tree():
		_card.modulate.a = 1.0
		_card.scale = Vector2.ONE
		return
	_card.pivot_offset = _card.size * 0.5
	_card.modulate.a = 0.0
	_card.scale = Vector2(0.92, 0.92)
	_tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_tween.tween_property(_card, "modulate:a", 1.0, 0.22)
	_tween.tween_property(_card, "scale", Vector2.ONE, 0.32)

func _fade_out() -> void:
	if UiDesign.reduced_motion(settings) or not is_inside_tree():
		hide_now()
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_time_left = 0.0
	_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(_card, "modulate:a", 0.0, 0.25)
	_tween.tween_callback(hide_now)

## A meter line in player words: station letters before a value ("Battery E:14") become the
## station's word and number ("Battery 14"), and a repeated word is said once.
static func plain_meter(line: String) -> String:
	var out := line
	var fields: Dictionary = UiDesign.text().get("station", {}).get("fields", {})
	for key in fields:
		var word := String(fields[key].get("word", key))
		var regex := RegEx.new()
		regex.compile("(?:\\b" + word + "\\s+)?\\b" + String(key) + "\\s*:\\s*(\\d+)")
		out = regex.sub(out, word + " $1", true)
	return out.replace(" - ", " · ")

## The player's star tally (separate from the campaign save, so no save-format change).
## Read from disk once per process; the goal card asks for it on every scene refresh.
static var _stars_cache := -1
static func stars() -> int:
	if _stars_cache >= 0:
		return _stars_cache
	_stars_cache = 0
	if FileAccess.file_exists(STARS_PATH):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(STARS_PATH))
		_stars_cache = maxi(0, int(parsed.get("stars", 0))) if parsed is Dictionary else 0
	return _stars_cache

static func save_stars(total: int) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(STARS_PATH.get_base_dir()))
	var file := FileAccess.open(STARS_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"stars": maxi(0, total)}))
	file.close()
	_stars_cache = maxi(0, total)
	return true

## "Job 2 of 3" with filled and open dots, plus the star tally once there is one.
static func progress_text(done: int, total: int, star_total: int = 0) -> String:
	var parts: Array[String] = []
	if total >= 2:
		var current := clampi(done + 1, 1, total)
		parts.append("%s  Job %d of %d" % ["●".repeat(clampi(done, 0, total)) + "○".repeat(total - clampi(done, 0, total)), current, total])
	if star_total > 0:
		parts.append("★ %d" % star_total)
	return "   ".join(parts)
