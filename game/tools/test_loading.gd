## Real semaphore-held workers prove recovery before the stuck work is released.
extends SceneTree

class HeldResource extends ResourceFormatLoader:
	var gate := Semaphore.new()
	func _get_recognized_extensions() -> PackedStringArray:
		return PackedStringArray(["m153"])
	func _get_resource_type(_path: String) -> String:
		return "Resource"
	func _handles_type(type: StringName) -> bool:
		return type == &"Resource"
	func _exists(_path: String) -> bool:
		return true
	func _load(_path: String, _original: String, _threads: bool, _cache: int) -> Variant:
		var worker := WorkerThreadPool.get_caller_task_id() != -1
		if worker:
			gate.wait()
		var value := Resource.new()
		value.set_meta("worker", worker)
		return value

class WaitOwner extends Node:
	## An intentionally pending predicate whose owner will be destroyed.
	func pending() -> bool:
		return false
	## Reproduces the self-bound lambda used by resource and room polling.
	func predicate() -> Callable:
		return func(): return pending()

var _checks := 0
var _failures := 0

func _init() -> void:
	_run.call_deferred()

func _check(value: bool, label: String) -> void:
	_checks += 1
	if not value:
		_failures += 1
		print("FAIL ", label)

func _run() -> void:
	await _test_job()
	await _test_cover()
	await _test_cancelled_owner()
	await _test_resource()
	await _test_campaign()
	print("LOADING WATCHDOG RESULT: %s (%d checks, %d failures)" % ["PASS" if _failures == 0 else "FAIL", _checks, _failures])
	quit(0 if _failures == 0 else 1)

func _test_job() -> void:
	PreparationWatchdog.timeout_ms = 30
	PreparationWatchdog.synchronous = false
	var gate := Semaphore.new()
	# Emergency release keeps a regression failure from stranding engine shutdown.
	create_timer(5.0).timeout.connect(gate.post)
	var job := PreparationJob.new()
	job.start(func():
		if WorkerThreadPool.get_caller_task_id() != -1:
			gate.wait()
		return {"worker": WorkerThreadPool.get_caller_task_id() != -1}, "forced_stuck_job")
	var result := await job.finish(self)
	_capture("fallback")
	_check(not result.worker, "stuck job completes on main before releasing worker")
	_check(PreparationWatchdog.synchronous, "timeout opens session circuit breaker")
	_check(PreparationWatchdog.recoveries[-1].step == "forced_stuck_job", "recovery names the stalled step")
	_check(PreparationWatchdog._jobs.has(job.task), "unfinished task is quarantined instead of joined")
	gate.post()
	PreparationWatchdog.timeout_ms = 15000
	_check(await PreparationWatchdog.wait_until(self, "test_job_cleanup", func(): return PreparationWatchdog._jobs.is_empty()), "late task reaped without blocking")
	_check(not result.worker, "late worker cannot overwrite fallback result")
	var skipped := PreparationJob.new()
	skipped.start(func(): return {"ok": true}, "circuit_breaker")
	_check(skipped.task == -1 and (await skipped.finish(self)).ok, "recovered session schedules no further pool work")
	_check(not paused, "fallback restores the prior unpaused tree")

func _fetch(preparation: LoadPreparation, path: String, results: Array) -> void:
	results.append(await preparation.resource(path))

func _covered(results: Array) -> void:
	results.append(await PreparationWatchdog.fallback(self, func(): return true))

func _test_cover() -> void:
	var results: Array = []
	_covered(results)
	_covered(results)
	_check(paused, "concurrent recoveries pause the tree under one card")
	while results.size() < 2:
		await process_frame
	_check(not paused and PreparationWatchdog._cover_depth == 0, "last overlapping recovery restores the original pause state")
	paused = true
	await PreparationWatchdog.fallback(self, func(): return true)
	_check(paused, "a previously paused tree stays paused after recovery")
	paused = false

func _wait_for_owner(ready: Callable, results: Array) -> void:
	results.append(await PreparationWatchdog.wait_until(self, "cancelled_owner", ready))

func _test_cancelled_owner() -> void:
	var owner := WaitOwner.new()
	root.add_child(owner)
	var results: Array = []
	var prior_recoveries := PreparationWatchdog.recoveries.size()
	_wait_for_owner(owner.predicate(), results)
	owner.free()
	while results.is_empty():
		await process_frame
	_check(results == [false], "freed wait owner cancels without calling an invalid lambda")
	_check(PreparationWatchdog.recoveries.size() == prior_recoveries, "normal cancellation does not report a timeout")

func _test_resource() -> void:
	PreparationWatchdog.synchronous = false
	PreparationWatchdog.timeout_ms = 15000
	var held := HeldResource.new()
	create_timer(5.0).timeout.connect(held.gate.post)
	ResourceLoader.add_resource_format_loader(held, true)
	var preparation := LoadPreparation.new()
	root.add_child(preparation)
	var results: Array = []
	_fetch(preparation, "res://resources/ui/lla_theme.tres", results)
	_fetch(preparation, "res://resources/ui/lla_theme.tres", results)
	while results.size() < 2:
		await process_frame
	_check(results[0] != null and results[0] == results[1], "normal duplicate requests share one resource")
	results.clear()
	PreparationWatchdog.synchronous = false
	PreparationWatchdog.timeout_ms = 30
	_fetch(preparation, "res://forced_stuck.m153", results)
	_fetch(preparation, "res://forced_stuck.m153", results)
	# Both requests start together, exercising foreground/prefetch coalescing.
	while results.size() < 2:
		await process_frame
	_check(results[0] != null and results[0] == results[1], "overlapping requests share the recovered resource")
	_check(not results[0].get_meta("worker"), "deep-ignore fallback bypasses the still-held ResourceLoader job")
	_check(preparation._resource_pending.is_empty(), "all native request ownership is released")
	var recovered: Resource = results[0]
	for index in 80:
		preparation._remember_resource("test-cache-%d" % index, Resource.new())
	_check(preparation.resources.size() == 64, "recovered sessions keep the normal resource cache bound")
	_check(preparation.resources.get("res://forced_stuck.m153") == recovered, "quarantined path stays pinned while other cached resources are evicted")
	held.gate.post()
	PreparationWatchdog.timeout_ms = 15000
	_check(await PreparationWatchdog.wait_until(self, "test_resource_cleanup", func(): return PreparationWatchdog._resources.is_empty()), "late native request consumed exactly once")
	_check(preparation.resources["res://forced_stuck.m153"] == recovered, "late native result cannot overwrite recovery")
	ResourceLoader.remove_resource_format_loader(held)
	preparation.free()

func _test_campaign() -> void:
	# A lost room owner must not hold the foreground queue forever either.
	var preparation := LoadPreparation.new()
	root.add_child(preparation)
	preparation._room_busy = true
	PreparationWatchdog.timeout_ms = 30
	_check(not await preparation.prepare_room("LOC-01"), "room queue timeout returns instead of waiting forever")
	_check(preparation._room_busy and not preparation.failed.is_empty(), "timeout preserves the original raw importer ownership")
	preparation._room_busy = false
	preparation.free()
	PreparationWatchdog.timeout_ms = 15000
	# Exercise the entire production title/launch/full-cast path after recovery.
	var main := preload("res://scenes/main.tscn").instantiate()
	var slot := OS.get_temp_dir().path_join("lla-watchdog-%d.json" % OS.get_process_id())
	main.save_path = slot
	main.legacy_save_path = slot + ".legacy"
	CampaignCutscenePlayer.autoplay = false
	root.add_child(main)
	while not main.title_ready:
		await process_frame
	await main._launch_campaign({})
	var campaign := main._campaign as Chapter1Campaign
	_check(campaign != null and not campaign.loading, "production launch completes after fallback")
	campaign._start_extended("EX-CH05-S02")
	await campaign.wait_loading()
	_check(campaign._crew.local_ids.size() == 5, "recovered full-cast entry places all five actors")
	_check(campaign._startup_error.is_empty() and main.preparation.failed.is_empty(), "recovered campaign remains playable")
	_check(await PreparationWatchdog.wait_until(self, "test_prefetch_cleanup", func():
		return not main.preparation._room_busy and main.preparation._resource_pending.is_empty() and PreparationWatchdog._cover_depth == 0), "background room and media recovery finish before teardown")
	await process_frame
	await process_frame
	_capture("recovered_full_cast")
	main.free()
	# Audio playback is retired by the mixing thread after its nodes are freed.
	# Let that cleanup finish before this short fixture shuts down the engine.
	await create_timer(0.1).timeout
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(slot + suffix):
			DirAccess.remove_absolute(slot + suffix)
	_check(PreparationWatchdog._jobs.is_empty() and PreparationWatchdog._resources.is_empty(), "no abandoned work left after forced-stall tests")
	_check(not paused, "overlapping fallback cards restore tree pause state")

func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--watchdog-capture-prefix="):
			var path := arg.trim_prefix("--watchdog-capture-prefix=") + "_" + label + ".png"
			_check(root.get_texture().get_image().save_png(path) == OK, "screenshot written: " + label)
