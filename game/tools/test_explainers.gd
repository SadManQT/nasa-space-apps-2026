# Godot --headless --path game --script res://tools/test_explainers.gd
## M1-63: every clip in explainers.json loads, plays in a VideoStreamPlayer for its registered length, keeps its
## captions inside the clip, and names only NASA fixtures the game bundles.
extends SceneTree

const REGISTRY := "res://resources/campaign/content/explainers.json"
const LEVELS := ["concept", "explainer", "method"]
const LABELS := ["measured", "model", "diagram"]

var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var registry: Variant = JSON.parse_string(FileAccess.get_file_as_string(REGISTRY))
	_check(registry is Dictionary and registry.get("explainers", []) is Array, "explainers.json parses")
	var entries: Array = registry.get("explainers", []) if registry is Dictionary else []
	_check(entries.size() >= 2, "at least the two M1-63 sample clips are registered")
	var ids := {}
	for entry: Dictionary in entries:
		var id := String(entry.get("id", ""))
		_check(not ids.has(id), "%s: id is unique" % id)
		ids[id] = true
		_check(LEVELS.has(entry.get("level")), "%s: level is concept, explainer or method" % id)
		for label in entry.get("labels", []):
			_check(LABELS.has(label), "%s: honest label %s" % [id, label])
		for source in entry.get("sources", []):
			_check(FileAccess.file_exists("res://resources/data/nasa/%s.json" % source), "%s: source %s is a bundled fixture" % [id, source])
		var length := float(entry.get("length_s", 0.0))
		_check(length >= 8.0 and length <= 45.5, "%s: 8-45 s long" % id)
		var last := 0.0
		for caption: Dictionary in entry.get("captions", []):
			var start := float(caption.get("start", -1.0))
			var end := float(caption.get("end", -1.0))
			_check(start >= last and end > start and end <= length and String(caption.get("text", "")) != "", "%s: caption at %.1f s sits inside the clip" % [id, start])
			last = end
		await _test_plays(id, String(entry.get("path", "")), length)
	print("EXPLAINERS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_plays(id: String, path: String, length: float) -> void:
	_check(ResourceLoader.exists(path), "%s: %s exists" % [id, path])
	var stream := load(path) as VideoStream
	_check(stream != null, "%s: loads as a video stream" % id)
	if stream == null:
		return
	var player := VideoStreamPlayer.new()
	player.stream = stream
	player.volume_db = -80.0
	root.add_child(player)
	player.play()
	for i in 30:
		await process_frame
	_check(player.is_playing(), "%s: plays" % id)
	_check(absf(player.get_stream_length() - length) < 0.5, "%s: plays for its registered %.1f s (got %.2f s)" % [id, length, player.get_stream_length()])
	player.stop()
	player.free()

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL ", label)
