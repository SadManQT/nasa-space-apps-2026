extends Control
class_name ReviewLipOverlay

var waveform: PackedFloat32Array = PackedFloat32Array()
var cues: Array[Dictionary] = []
var playhead: float = 0.0
var duration: float = 0.0
var weights: Dictionary = {}

func set_data(new_waveform: PackedFloat32Array, new_cues: Array[Dictionary], new_duration: float) -> void:
	waveform = new_waveform
	cues = new_cues
	duration = maxf(new_duration, 0.001)
	queue_redraw()

func set_playhead(value: float, new_weights: Dictionary) -> void:
	playhead = clampf(value, 0.0, duration)
	weights = new_weights
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color("#161c22"), true)
	draw_rect(rect, Color("#5b6875"), false, 1.0)
	var font := ThemeDB.fallback_font
	var width := maxf(size.x, 1.0)
	var height := maxf(size.y, 1.0)
	var waveform_height := height * 0.22
	var waveform_mid := waveform_height * 0.5
	draw_line(Vector2(0.0, waveform_mid), Vector2(width, waveform_mid), Color("#394852"), 1.0)
	if waveform.size() > 1:
		var points := PackedVector2Array()
		for i in waveform.size():
			var x := float(i) / float(waveform.size() - 1) * width
			var y := waveform_mid - waveform[i] * waveform_height * 0.45
			points.append(Vector2(x, y))
		draw_polyline(points, Color("#6fd3ef"), 1.5)
	else:
		draw_string(font, Vector2(8.0, 16.0), "no audio waveform", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color("#8a99a6"))
	for cue in cues:
		var t := float(cue.get("t", 0.0))
		var x := t / duration * width
		var next_t := duration
		var index := cues.find(cue)
		if index >= 0 and index + 1 < cues.size():
			next_t = float(cues[index + 1].get("t", duration))
		var cue_width := maxf((next_t - t) / duration * width, 2.0)
		draw_rect(Rect2(x, waveform_height + 2.0, cue_width, 20.0), Color("#344d66"), true)
		draw_string(font, Vector2(x + 3.0, waveform_height + 16.0), String(cue.get("shape", "?")), HORIZONTAL_ALIGNMENT_LEFT, cue_width - 4.0, 9, Color("#d8edf6"))
	var play_x := playhead / duration * width
	draw_line(Vector2(play_x, 0.0), Vector2(play_x, waveform_height + 24.0), Color("#ffbd54"), 2.0)
	var bar_top := waveform_height + 31.0
	var rows := maxi(1, int(ceil(weights.size() / 2.0)))
	var row_height := maxf((height - bar_top - 4.0) / rows, 10.0)
	var column_width := width / 2.0
	var shown := 0
	for shape in weights:
		var value := clampf(float(weights.get(shape, 0.0)), 0.0, 1.0)
		var x := (shown / rows) * column_width
		var y := bar_top + (shown % rows) * row_height
		draw_string(font, Vector2(x + 6.0, y + 9.0), String(shape), HORIZONTAL_ALIGNMENT_LEFT, 80.0, 9, Color("#c0cbd5"))
		var bar_width := maxf(column_width - 125.0, 4.0)
		draw_rect(Rect2(x + 88.0, y + 2.0, bar_width, 7.0), Color("#26323b"), true)
		draw_rect(Rect2(x + 88.0, y + 2.0, bar_width * value, 7.0), Color("#8bd7a8"), true)
		draw_string(font, Vector2(x + column_width - 32.0, y + 9.0), "%.2f" % value, HORIZONTAL_ALIGNMENT_LEFT, 30.0, 9, Color("#c0cbd5"))
		shown += 1
