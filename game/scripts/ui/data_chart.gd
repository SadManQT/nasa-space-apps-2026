extends Control
class_name DataChart

## Text summary accompanies the visual so no information relies on colour.
var series: Dictionary = {}

func _ready() -> void:
	custom_minimum_size = Vector2(0, 100)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var values: Array = series.get("values", [])
	if values.is_empty():
		return
	var low := minf(0.0, float(values.min()))
	var high := maxf(0.0, float(values.max()))
	var span := maxf(high - low, 0.0001)
	var area := Rect2(4, 8, maxf(size.x - 8, 1), size.y - 16)
	draw_rect(area, Color("#1F2A44"))
	var baseline := area.end.y - (0.0 - low) / span * area.size.y
	draw_line(Vector2(area.position.x, baseline), Vector2(area.end.x, baseline), Color("#A8B4C8"), 1)
	if series.get("kind") == "line" and values.size() > 1:
		var points := PackedVector2Array()
		for i in values.size():
			points.append(Vector2(area.position.x + float(i) / (values.size() - 1) * area.size.x, area.end.y - (float(values[i]) - low) / span * area.size.y))
		draw_polyline(points, Color("#F2C230"), 3, true)
	else:
		var y := area.end.y - (float(values[0]) - low) / span * area.size.y
		draw_rect(Rect2(area.position.x + area.size.x * 0.35, minf(y, baseline), area.size.x * 0.3, maxf(absf(baseline - y), 3)), Color("#20B8C9"))
