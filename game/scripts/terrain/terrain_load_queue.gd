extends Node

## Each successful threaded request needs exactly one get(), even if its scene
## closes before loading completes. This small root-owned drain outlives the
## terrain, polls without waiting, and releases abandoned results when ready.
var pending: Dictionary = {}
var completed: Dictionary = {}
var discarded: Dictionary = {}
var orphaned := false

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func request(path: String) -> bool:
	if orphaned or pending.has(path) or completed.has(path):
		return false
	if ResourceLoader.load_threaded_request(path) != OK:
		return false
	pending[path] = true
	return true

func has_result(path: String) -> bool:
	return completed.has(path)

func take(path: String) -> Resource:
	var result: Resource = completed.get(path)
	completed.erase(path)
	return result

func discard(path: String) -> void:
	completed.erase(path)
	if pending.has(path):
		discarded[path] = true

func release_owner() -> void:
	orphaned = true
	completed.clear()
	if pending.is_empty():
		queue_free()

func _process(_delta: float) -> void:
	for path in pending.keys():
		var status := ResourceLoader.load_threaded_get_status(String(path))
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			continue
		# A completed/failed request cannot wait. Consume its engine reference.
		var result := ResourceLoader.load_threaded_get(String(path))
		pending.erase(path)
		if not orphaned and not discarded.has(path):
			completed[path] = result
		discarded.erase(path)
	if orphaned and pending.is_empty():
		queue_free()
