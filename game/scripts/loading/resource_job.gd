## WorkerThreadPool owns the callable/result lifetime if the loading UI closes.
## Only resource/primitive work may be supplied; never pass live scene Nodes.
extends RefCounted
class_name PreparationJob

var result: Dictionary = {}
var task := -1
var _action: Callable
var _step := "worker_resources"

## Starts private resource work. The callable must be safe to repeat on main.
func start(action: Callable, step: String = "worker_resources") -> void:
	_action = action
	_step = step
	if not PreparationWatchdog.synchronous:
		task = WorkerThreadPool.add_task(_run.bind(action), false, step)

func _run(action: Callable) -> void:
	result = action.call()

## Publishes a completed result, or repeats private work without joining a stuck job.
func finish(tree: SceneTree) -> Dictionary:
	if task == -1:
		return await PreparationWatchdog.fallback(tree, _action)
	if not await PreparationWatchdog.wait_until(tree, _step, func(): return WorkerThreadPool.is_task_completed(task)):
		PreparationWatchdog.retire_job(tree, task)
		# Never share the result slot with a worker that may return later.
		return await PreparationWatchdog.fallback(tree, _action)
	WorkerThreadPool.wait_for_task_completion(task)
	return result
