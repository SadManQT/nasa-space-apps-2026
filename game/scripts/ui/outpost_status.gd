extends HBoxContainer
class_name OutpostStatus

## A read-only view of CampaignDirector.query(), including its shared simulation
## shelter readout. Forecasts are primitive results, never a second live state.
const RULES_PATH := "res://resources/campaign/outpost_status.json"
const IVORY := Color("#ECEEF0")
const GOLD := Color("#F2C230")
const GREEN := Color("#68C78B")
const RED := Color("#F38C91")
var _rules: Dictionary
var _cards: Dictionary = {}
var _query: Dictionary = {}
var _forecast: Dictionary = {}

class StatusIcon extends Control:
	var kind := ""
	func _draw() -> void:
		var color := Color("#F2C230")
		if kind == "power":
			draw_rect(Rect2(2, 5, 17, 13), color, false, 2)
			draw_line(Vector2(21, 9), Vector2(21, 14), color, 2)
			draw_line(Vector2(6, 11), Vector2(15, 11), color, 2)
		elif kind == "shielding":
			draw_polyline(PackedVector2Array([Vector2(3, 3), Vector2(21, 3), Vector2(20, 15), Vector2(12, 22), Vector2(4, 15), Vector2(3, 3)]), color, 2)
		elif kind == "food":
			draw_arc(Vector2(12, 11), 9, PI, TAU, 20, color, 2)
			draw_line(Vector2(3, 11), Vector2(21, 11), color, 2)
			draw_line(Vector2(12, 11), Vector2(12, 23), color, 2)
		else:
			for y in [6, 12, 18]:
				draw_line(Vector2(3, y), Vector2(21, y), color, 2)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 10)
	_rules = JSON.parse_string(FileAccess.get_file_as_string(RULES_PATH))
	for group in _rules.get("groups", []):
		var panel := PanelContainer.new()
		panel.name = String(group.id)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#0C1424")
		style.border_color = Color("#43536D")
		style.set_border_width_all(1)
		style.set_corner_radius_all(8)
		style.content_margin_left = 12
		style.content_margin_right = 12
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		panel.add_theme_stylebox_override("panel", style)
		add_child(panel)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 3)
		panel.add_child(box)
		var header := HBoxContainer.new()
		box.add_child(header)
		var icon := StatusIcon.new()
		icon.kind = String(group.icon)
		icon.custom_minimum_size = Vector2(24, 24)
		header.add_child(icon)
		var title := _label(String(group.label), 16, 1)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(title)
		var status := _label("", 12, 1)
		status.custom_minimum_size.x = 72
		header.add_child(status)
		var values := _label("", 14)
		box.add_child(values)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size.y = 7
		box.add_child(bar)
		var forecast := _label("Select an operation", 12, 1)
		box.add_child(forecast)
		_cards[group.id] = {"panel": panel, "values": values, "bar": bar, "forecast": forecast, "status": status}

func bind_query(query: Dictionary, forecast: Dictionary = {}) -> void:
	_query = query.duplicate(true)
	_forecast = forecast.duplicate(true)
	if bool(_forecast.get("accepted", false)) and int(_forecast.get("input_revision", -1)) != int(query.get("state_revision", 0)):
		_forecast = {}
	for group in _rules.get("groups", []):
		var view := meter_view(String(group.id))
		var card: Dictionary = _cards[group.id]
		card.values.text = view.current_text
		card.status.text = view.status
		card.status.modulate = RED if view.status == "! LOW" or view.status == "! LIMIT" else GOLD if view.status == "! CHECK" else GREEN
		card.bar.max_value = view.capacity
		card.bar.value = view.value
		var fill := StyleBoxFlat.new()
		fill.bg_color = card.status.modulate
		card.bar.add_theme_stylebox_override("fill", fill)
		card.forecast.text = view.forecast_text
		card.panel.accessibility_name = view.accessibility_text
		card.bar.accessibility_name = view.accessibility_text
		card.panel.tooltip_text = String(_rules.get("scope", ""))

func meter_view(id: String) -> Dictionary:
	var group: Dictionary = {}
	for candidate in _rules.get("groups", []):
		if candidate.id == id:
			group = candidate
	if group.is_empty():
		return {}
	var resources := _resources(_query)
	var primary := String(group.primary)
	var value := float(resources.get(primary, 0))
	var cap := float(_query.get("resources", {}).get(group.capacity, _query.get("outpost", {}).get(group.capacity, 1)))
	var status := "OK"
	var thresholds: Dictionary = group.thresholds
	if value <= float(thresholds.critical_below_or_equal):
		status = "! LOW"
	elif value <= float(thresholds.warning_below_or_equal):
		status = "! CHECK"
	for field in group.get("additional_thresholds", {}):
		var limits: Dictionary = group.additional_thresholds[field]
		var amount := float(resources.get(field, 0))
		if limits.has("critical_below_or_equal") and amount <= float(limits.critical_below_or_equal):
			status = "! LOW"
		elif status == "OK" and ((limits.has("warning_below_or_equal") and amount <= float(limits.warning_below_or_equal)) or (limits.has("warning_at_or_above") and amount >= float(limits.warning_at_or_above)) or (limits.has("warning_above") and amount > float(limits.warning_above))):
			status = "! CHECK"
	if id == "shielding":
		var limit = group.exposure_limits.get(_query.get("chapter_id", ""))
		if limit != null and float(resources.get("Z", 0)) > float(limit):
			status = "! LIMIT"
	var text: Array[String] = []
	var spoken: Array[String] = []
	var changes: Array[String] = []
	var predicted := _resources(_forecast.get("query", {}))
	for key in group.fields:
		text.append("%s %s%s%s" % [group.display_fields[key], _number(float(resources.get(key, 0))), "/" + _number(cap) if key == primary else "", group.display_units.get(key, "")])
		spoken.append("%s %s" % [group.fields[key], _number(float(resources.get(key, 0)))])
		if bool(_forecast.get("accepted", false)):
			var delta := float(predicted.get(key, resources.get(key, 0))) - float(resources.get(key, 0))
			changes.append("%s -> %s%s" % [key, "+" if delta >= 0 else "", _number(delta)])
	var forecast_text := " · ".join(changes) if not changes.is_empty() else "Select an operation"
	if not _forecast.is_empty() and not bool(_forecast.get("accepted", false)):
		forecast_text = "Forecast unavailable"
	return {"value": value, "capacity": maxf(cap, 1), "status": status, "current_text": " · ".join(text), "forecast_text": forecast_text, "accessibility_text": String(group.label) + ": " + ", ".join(spoken) + ". " + status + ". " + forecast_text + ". " + String(group.description)}

static func _resources(query: Dictionary) -> Dictionary:
	var result: Dictionary = query.get("resources", {}).duplicate(true)
	result["S"] = query.get("outpost", {}).get("shelter_capacity", 0)
	return result

static func _number(value: float) -> String:
	return str(int(value)) if value == floor(value) else String.num(value, 2).rstrip("0").rstrip(".")

static func _label(text: String, size: int, lines: int = 2) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.max_lines_visible = lines
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("#ECEEF0"))
	return label
