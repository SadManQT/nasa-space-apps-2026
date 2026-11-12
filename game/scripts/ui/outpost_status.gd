extends PanelContainer
class_name OutpostStatus

## The compact station strip (doc 25 §2.2): a read-only view of
## CampaignDirector.query() in player words ("Battery 14 of 20", never "E 14/20").
## It appears only when a value changes, when a value that matters now runs low,
## or while a job's forecast is shown, and hides again after a few seconds.
## Thresholds stay in outpost_status.json; display words live in ui_text.json.
## Forecasts are primitive results, never a second live state.
const RULES_PATH := "res://resources/campaign/outpost_status.json"
const GateCatalog = preload("res://scripts/missions/chapter1_gate_catalog.gd")

var _rules: Dictionary
var _cards: Dictionary = {}
var _query: Dictionary = {}
var _baseline: Dictionary = {}  # the values the player has already seen; a change is measured against these
var _content := ""  # what the strip shows now, so a refresh that changes nothing keeps its timer
var _forecast: Dictionary = {}
var _settings: Dictionary = {}
var _rows: VBoxContainer
var _title: Label
var _timer := 0.0
var _sticky := false
var _tween: Tween
var _ever_bound := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", UiDesign.scrim_style(0.66))  # floats like the rest of the in-play HUD
	_rules = JSON.parse_string(FileAccess.get_file_as_string(RULES_PATH))
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 6)
	add_child(_rows)
	_title = UiDesign.label("Station", "caption", "muted")
	_title.visible = false  # Instrument Light: the icons name each row; no heading needed
	_rows.add_child(_title)
	for group in _rules.get("groups", []):
		var panel := VBoxContainer.new()
		panel.name = String(group.id)
		panel.add_theme_constant_override("separation", 2)
		_rows.add_child(panel)
		var header := HBoxContainer.new()
		header.add_theme_constant_override("separation", 8)
		panel.add_child(header)
		var icon := UiDesign.LineIcon.new(String(group.icon), UiDesign.colour("accent"))
		header.add_child(icon)
		var values := UiDesign.label("", "body")
		values.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(values)
		var status := UiDesign.label("", "caption", "muted")
		status.visible = false
		panel.add_child(status)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size.y = 4
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var track := StyleBoxFlat.new()
		track.bg_color = Color(1, 1, 1, 0.12)
		track.set_corner_radius_all(2)
		bar.add_theme_stylebox_override("background", track)
		panel.add_child(bar)
		var forecast := UiDesign.label("", "caption", "accent")
		forecast.visible = false
		panel.add_child(forecast)
		panel.visible = false
		_cards[group.id] = {"panel": panel, "values": values, "bar": bar, "forecast": forecast, "status": status, "icon": icon}
	visible = false
	modulate.a = 0.0
	set_process(true)

## Accessibility settings (reduced motion) for the show and hide tweens.
func set_settings(settings: Dictionary) -> void:
	_settings = settings.duplicate(true)

## Binds the live query and an optional forecast of the job in reach. The strip
## shows the groups whose values changed, run low or would change.
func bind_query(query: Dictionary, forecast: Dictionary = {}) -> void:
	_query = query.duplicate(true)
	_forecast = forecast.duplicate(true)
	if bool(_forecast.get("accepted", false)) and int(_forecast.get("input_revision", -1)) != int(query.get("state_revision", 0)):
		_forecast = {}
	var current := _resources(_query)
	if not _ever_bound:
		_baseline = current
	var before := _baseline
	var predicted := _resources(_forecast.get("query", {})) if bool(_forecast.get("accepted", false)) else {}
	var show_groups := 0
	var sticky := false
	var changed_any := false
	for group in _rules.get("groups", []):
		var view := meter_view(String(group.id))
		var card: Dictionary = _cards[group.id]
		var changed := false
		var forecast_changes := false
		for key in group.fields:
			if float(current.get(key, 0)) != float(before.get(key, 0)):
				changed = true
			if not predicted.is_empty() and float(predicted.get(key, current.get(key, 0))) != float(current.get(key, 0)):
				forecast_changes = true
		var low: bool = view.status != "OK" and view.matters_now
		var show: bool = changed or forecast_changes or low
		card.values.text = view.current_text
		card.status.text = view.status_word
		card.status.visible = low and not view.status_word.is_empty()  # a warning only where it matters now
		var tone := _tone(view.status) if low else UiDesign.colour("good")
		card.status.add_theme_color_override("font_color", tone)
		card.values.add_theme_color_override("font_color", UiDesign.colour("ivory"))  # the status line and icon carry the warning
		card.icon.colour = tone if low else UiDesign.colour("accent")
		card.icon.queue_redraw()
		card.bar.max_value = view.capacity
		card.bar.visible = view.has_capacity
		var fill := StyleBoxFlat.new()
		fill.bg_color = tone
		fill.set_corner_radius_all(2)
		card.bar.add_theme_stylebox_override("fill", fill)
		_animate_bar(card.bar, float(view.value), changed)
		card.forecast.text = view.forecast_text
		card.forecast.visible = forecast_changes and not view.forecast_text.is_empty()
		card.panel.accessibility_name = view.accessibility_text
		card.bar.accessibility_name = view.accessibility_text
		card.panel.visible = show
		if show:
			show_groups += 1
		changed_any = changed_any or changed or forecast_changes
		sticky = sticky or (low and not changed and not forecast_changes)
	_ever_bound = true
	tooltip_text = String(_rules.get("scope", ""))
	if show_groups > 0:
		_sticky = sticky and not changed_any
		var content := str([current, predicted, _cards.keys().filter(func(id) -> bool: return _cards[id].panel.visible)])
		if content != _content or not visible:
			_timer = float(UiDesign.tokens().get("motion", {}).get("strip_seconds", 6.0))
		_content = content
		if not predicted.is_empty():
			_timer = INF
		_show()
	elif visible:
		_timer = minf(_timer, 0.4)

## Hides the strip at once, with no fade (a panel takes the screen).
func hide_now() -> void:
	_timer = 0.0
	_sticky = false
	_content = ""
	if _tween != null and _tween.is_valid():
		_tween.kill()
	modulate.a = 0.0
	visible = false

## True while the strip is showing or fading in.
func is_showing() -> bool:
	return visible and modulate.a > 0.01

func _process(delta: float) -> void:
	if not visible or _timer == INF:
		return
	_timer -= delta
	if _timer <= 0.0 and not _sticky:
		_baseline = _resources(_query)  # the change has been on screen long enough: it is now seen
		_content = ""
		_fade(false)

func _show() -> void:
	if not visible or modulate.a < 0.99:
		_fade(true)

func _fade(shown: bool) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	var seconds := UiDesign.motion_seconds("show_seconds" if shown else "hide_seconds", _settings)
	if shown:
		visible = true
	if seconds <= 0.0 or not is_inside_tree():
		modulate.a = 1.0 if shown else 0.0
		visible = shown
		return
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(self, "modulate:a", 1.0 if shown else 0.0, seconds)
	if not shown:
		_tween.tween_callback(func() -> void: visible = false)

func _animate_bar(bar: ProgressBar, value: float, changed: bool) -> void:
	var seconds := UiDesign.motion_seconds("count_seconds", _settings)
	if not changed or seconds <= 0.0 or not is_inside_tree():
		bar.value = value
		return
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(bar, "value", value, seconds)

func _tone(status: String) -> Color:
	match status:
		"! LOW", "! LIMIT":
			return UiDesign.colour("danger")
		"! CHECK":
			return UiDesign.colour("caution")
	return UiDesign.colour("good")

## One group's view in player words: value, capacity, status code, the text
## shown, the forecast line and the screen-reader sentence.
func meter_view(id: String) -> Dictionary:
	var group: Dictionary = {}
	for candidate in _rules.get("groups", []):
		if candidate.id == id:
			group = candidate
	if group.is_empty():
		return {}
	var fields: Dictionary = UiDesign.text().get("station", {}).get("fields", {})
	var resources := _resources(_query)
	var primary := String(group.primary)
	var value := float(resources.get(primary, 0))
	var primary_field: Dictionary = fields.get(primary, {})
	var cap := _capacity(String(primary_field.get("capacity", group.get("capacity", ""))))
	var status := "OK"
	var thresholds: Dictionary = group.thresholds
	if value <= float(thresholds.critical_below_or_equal):
		status = "! LOW"
	elif value <= float(thresholds.warning_below_or_equal):
		status = "! CHECK"
	for field in group.get("additional_thresholds", {}):
		var limits: Dictionary = group.additional_thresholds[field]
		var amount := float(resources.get(field, 0))
		if field == "W":
			amount = maxf(0, amount - float(_query.get("outpost", {}).get("separate_shelter_water", 0)))
		if limits.has("critical_below_or_equal") and amount <= float(limits.critical_below_or_equal):
			status = "! LOW"
		elif status == "OK" and ((limits.has("warning_below_or_equal") and amount <= float(limits.warning_below_or_equal)) or (limits.has("warning_at_or_above") and amount >= float(limits.warning_at_or_above)) or (limits.has("warning_above") and amount > float(limits.warning_above))):
			status = "! CHECK"
	if id == "shielding":
		var limit = group.exposure_limits.get(_query.get("chapter_id", ""))
		if limit != null and float(resources.get("Z", 0)) > float(limit):
			status = "! LIMIT"
	var status_words: Dictionary = UiDesign.text().get("station", {}).get("status_words", {})
	var status_word := String(status_words.get(status, ""))
	var lines: Array[String] = []
	var spoken: Array[String] = []
	var changes: Array[String] = []
	var predicted := _resources(_forecast.get("query", {}))
	var matters := false
	for key in group.fields:
		var field: Dictionary = fields.get(key, {})
		var word := String(field.get("word", group.fields[key]))
		var amount := float(resources.get(key, 0))
		var field_cap := _capacity(String(field.get("capacity", "")))
		var line := "%s %s" % [word, UiDesign.number(snappedf(amount, 0.1))]  # the strip reads at a glance: one decimal
		if field_cap > 0:
			line += " %s %s" % [String(field.get("scale", "of")), UiDesign.number(field_cap)]
		if field.has("unit"):
			line += " " + String(field.unit)
		lines.append(line)
		spoken.append(line)
		matters = matters or (_matters_now(String(field.get("matters_from", ""))) and _matters_here(field))
		if bool(_forecast.get("accepted", false)):
			var next := float(predicted.get(key, amount))
			if next != amount:
				var delta := next - amount
				changes.append("%s %s → %s (%s%s)" % [word, UiDesign.number(amount), UiDesign.number(next), "+" if delta >= 0 else "−", UiDesign.number(absf(delta))])
	var low_meaning := ""
	if status != "OK":
		low_meaning = String(primary_field.get("low", ""))
		for key in group.fields:
			if key != primary and status != "OK" and low_meaning.is_empty():
				low_meaning = String(fields.get(key, {}).get("low", ""))
	var forecast_text := " · ".join(changes)
	if not forecast_text.is_empty():
		forecast_text += " " + String(UiDesign.text().get("station", {}).get("forecast_word", ""))
	var shown_status := status_word
	if not low_meaning.is_empty() and not status_word.is_empty():
		shown_status = "%s · %s" % [status_word.capitalize(), low_meaning]
	return {
		"value": value,
		"capacity": maxf(cap, 1),
		"has_capacity": cap > 0,
		"status": status,
		"status_word": shown_status,
		"matters_now": matters,
		"current_text": "\n".join(lines),
		"forecast_text": forecast_text.strip_edges(),
		"accessibility_text": String(group.label) + ": " + ", ".join(spoken) + ". " + (status_word if not status_word.is_empty() else "fine") + ". " + (forecast_text if not forecast_text.is_empty() else "") + " " + String(group.description),
	}

func _capacity(key: String) -> float:
	if key.is_empty():
		return 0.0
	return float(_query.get("resources", {}).get(key, _query.get("outpost", {}).get(key, 0)))

## A field with "matters_in" (scene id prefixes) only warns there: the storm
## shelter matters during storms, not as a red line through calm chapters.
func _matters_here(field: Dictionary) -> bool:
	var places: Array = field.get("matters_in", [])
	if places.is_empty():
		return true
	var current := String(_query.get("scene_id", ""))
	return places.any(func(prefix): return current.begins_with(String(prefix)))

func _matters_now(scene_from: String) -> bool:
	if scene_from.is_empty():
		return true
	var current := String(_query.get("scene_id", ""))
	if not GateCatalog.SCENE_ORDER.has(current) or not GateCatalog.SCENE_ORDER.has(scene_from):
		return true
	return GateCatalog.SCENE_ORDER.find(current) >= GateCatalog.SCENE_ORDER.find(scene_from)

static func _resources(query: Dictionary) -> Dictionary:
	var result: Dictionary = query.get("resources", {}).duplicate(true)
	result["S"] = query.get("outpost", {}).get("shelter_capacity", 0)
	return result
