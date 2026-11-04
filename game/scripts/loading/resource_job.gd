## WorkerThreadPool owns the callable/result lifetime if the loading UI closes.
## Only resource/primitive work may be supplied; never pass live scene Nodes.
extends RefCounted
class_name PreparationJob

var result: Dictionary = {}
var task := -1

func start(action: Callable) -> void:
	task = WorkerThreadPool.add_task(_run.bind(action))

func _run(action: Callable) -> void:
	result = action.call()

func finish(tree: SceneTree) -> Dictionary:
	while not WorkerThreadPool.is_task_completed(task):
		await tree.process_frame
	WorkerThreadPool.wait_for_task_completion(task)
	return result
