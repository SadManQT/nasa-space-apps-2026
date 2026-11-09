## Bounds asynchronous preparation without ever joining an unfinished task.
extends RefCounted
class_name PreparationWatchdog

# Technical recovery budget, independent of mission time and gameplay values.
static var timeout_ms := 15000
static var synchronous := false
static var recoveries: Array[Dictionary] = []
static var _jobs: Array[int] = []
static var _resources: Array[String] = []
static var _cover_depth := 0
static var _was_paused := false
static var _card: LoadingCard
static var _reaper_tree: WeakRef

## Polls across live frames; false means timeout or the caller's owner was freed.
static func wait_until(tree: SceneTree, step: String, ready: Callable) -> bool:
	var start := Time.get_ticks_msec()
	while ready.is_valid():
		if ready.call():
			return true
		if Time.get_ticks_msec() - start >= timeout_ms:
			recover(step, Time.get_ticks_msec() - start)
			return false
		await tree.process_frame
	return false

## Records recovery even outside profiling, and stops scheduling more pool work.
static func recover(step: String, elapsed_ms: int) -> void:
	synchronous = true
	var entry := {"step": step, "ms": elapsed_ms, "fallback": "synchronous"}
	recoveries.append(entry)
	print("PREPARATION WATCHDOG ", JSON.stringify(entry))
	if LoadTrace.enabled:
		LoadTrace.steps.append(entry)

## Draws the existing loading card before blocking recovery, including look-ahead.
## Restores the exact prior pause state; no mission clock advances under the card.
static func fallback(tree: SceneTree, action: Callable) -> Variant:
	if _cover_depth == 0:
		_card = LoadingCard.new()
		tree.root.add_child(_card)
		_was_paused = tree.paused
		tree.paused = true
	_cover_depth += 1
	await tree.process_frame
	await tree.process_frame
	var value: Variant = action.call() if action.is_valid() else null
	_cover_depth -= 1
	if _cover_depth == 0:
		tree.paused = _was_paused
		_card.queue_free()
		_card = null
	return value

## Retains an abandoned pool task until it can be reaped without blocking.
static func retire_job(tree: SceneTree, task: int) -> void:
	_jobs.append(task)
	_connect_reaper(tree)

## A timed-out ResourceLoader request cannot be cancelled. Consume it only once ready.
static func retire_resource(tree: SceneTree, path: String) -> void:
	if path not in _resources:
		_resources.append(path)
	_connect_reaper(tree)

## Cache owners must retain recovered resources while a legacy load could rejoin this path.
static func resource_is_retired(path: String) -> bool:
	return path in _resources

static func _connect_reaper(tree: SceneTree) -> void:
	_reaper_tree = weakref(tree)
	if not tree.process_frame.is_connected(reap):
		tree.process_frame.connect(reap)

## Releases late results without publishing them over an already recovered cache.
static func reap() -> void:
	for task in _jobs.duplicate():
		if WorkerThreadPool.is_task_completed(task):
			WorkerThreadPool.wait_for_task_completion(task)
			_jobs.erase(task)
	for path in _resources.duplicate():
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_LOADED or status == ResourceLoader.THREAD_LOAD_FAILED:
			ResourceLoader.load_threaded_get(path)
			_resources.erase(path)
	if _jobs.is_empty() and _resources.is_empty() and _reaper_tree != null:
		var tree := _reaper_tree.get_ref() as SceneTree
		if tree != null and tree.process_frame.is_connected(reap):
			tree.process_frame.disconnect(reap)
		_reaper_tree = null
