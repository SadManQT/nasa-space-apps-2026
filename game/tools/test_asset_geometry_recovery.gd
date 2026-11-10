## M1-126 (owner delivery for M1-53): AssetGeometry.prepare() with real
## semaphore-held raw GLB jobs. Recovery must finish before the held worker is
## released, overlapping callers share one publication, the late request is
## consumed once, and a takeover at any publication yield keeps node lifetimes
## and the complete scene.
extends SceneTree

class HeldRaw extends "res://scripts/loading/raw_gltf_loader.gd":
	var gate := Semaphore.new()
	var hold := false
	var loads := 0
	func _load(path: String, original: String, threads: bool, cache: int) -> Variant:
		loads += 1
		if hold:
			gate.wait()
		return super._load(path, original, threads, cache)

const PROP_A := "res://assets/props/PR_AnnexDrum/PR_AnnexDrum.glb"
const PROP_B := "res://assets/props/PR_BatteryJar/PR_BatteryJar.glb"
const CAST := "res://assets/characters/CH_Kai/CH_Kai.glb"

var _checks := 0
var _failures := 0
var _held := HeldRaw.new()

func _init() -> void:
	_run.call_deferred()

func _check(value: bool, label: String) -> void:
	_checks += 1
	if not value:
		_failures += 1
		print("FAIL ", label)

func _prepare(path: String, results: Array) -> void:
	results.append(await AssetGeometry.prepare(path, self))

func _forget(path: String) -> void:
	AssetGeometry._scenes.erase(path)
	AssetGeometry._recent.erase(path)

func _reset() -> void:
	PreparationWatchdog.synchronous = false
	PreparationWatchdog.timeout_ms = 15000

func _clip_count(path: String) -> int:
	var instance := (AssetGeometry._scenes[path].scene as PackedScene).instantiate()
	var players := instance.find_children("*", "AnimationPlayer", true, false)
	var count := 0 if players.is_empty() else (players[0] as AnimationPlayer).get_animation_list().size()
	var meshes := instance.find_children("*", "MeshInstance3D", true, false).size()
	instance.free()
	return count * 1000 + meshes

func _run() -> void:
	# Install the held loader exactly where AssetGeometry installs the real one.
	AssetGeometry._image_extension = preload("res://scripts/loading/raw_gltf_images.gd").new()
	GLTFDocument.register_gltf_document_extension(AssetGeometry._image_extension, true)
	AssetGeometry._raw_loader = _held
	ResourceLoader.add_resource_format_loader(_held, true)
	await _test_shared_normal()
	await _test_failures()
	await _test_held_recovery()
	await _test_takeover_at_each_yield()
	_reset()
	_check(PreparationWatchdog._jobs.is_empty() and PreparationWatchdog._resources.is_empty(), "no abandoned work is left")
	_check(AssetGeometry._preparing.is_empty() and AssetGeometry._requests.is_empty(), "no raw ownership is left")
	_check(not paused, "fallback cards restore the pause state")
	print("ASSET GEOMETRY RECOVERY RESULT: %s (%d checks, %d failures)" % ["PASS" if _failures == 0 else "FAIL", _checks, _failures])
	quit(0 if _failures == 0 else 1)

func _test_shared_normal() -> void:
	_reset()
	var results: Array = []
	_prepare(PROP_A, results)
	_prepare(PROP_A, results)
	while results.size() < 2:
		await process_frame
	_check(results == [true, true] and AssetGeometry.is_prepared(PROP_A), "overlapping normal callers both get the prepared scene")
	_check(_held.loads == 1, "overlapping normal callers share one raw decode")
	_check(PreparationWatchdog.recoveries.is_empty() and not PreparationWatchdog.synchronous, "a normal load reports no recovery")

func _test_failures() -> void:
	_reset()
	var before := PreparationWatchdog.recoveries.size()
	_check(not await AssetGeometry.prepare("res://missing-recovery-model.glb", self), "a missing GLB fails")
	var broken := OS.get_temp_dir().path_join("lla-recovery-%d.glb" % OS.get_process_id())
	var file := FileAccess.open(broken, FileAccess.WRITE)
	file.store_string("not a glb")
	file.close()
	var results: Array = []
	_prepare(broken, results)
	_prepare(broken, results)
	while results.size() < 2:
		await process_frame
	DirAccess.remove_absolute(broken)
	_check(results == [false, false], "overlapping callers share a failed decode")
	_check(PreparationWatchdog.recoveries.size() == before and not PreparationWatchdog.synchronous and not paused, "plain failures show no card and trip no breaker")
	_check(AssetGeometry._preparing.is_empty() and AssetGeometry._requests.is_empty(), "failed loads release their ownership")

func _test_held_recovery() -> void:
	_reset()
	PreparationWatchdog.timeout_ms = 30
	_held.hold = true
	var loads_before := _held.loads
	var results: Array = []
	_prepare(PROP_B, results)
	_prepare(PROP_B, results)
	while results.size() < 2:
		await process_frame
	# The worker is still parked on the semaphore here.
	_check(results == [true, true] and AssetGeometry.is_prepared(PROP_B), "held raw job: both callers recover before the worker is released")
	_check(_held.loads == loads_before + 1, "held raw job: one request for two callers")
	_check(String(PreparationWatchdog.recoveries[-1].step).begins_with("raw_decode:") or String(PreparationWatchdog.recoveries[-1].step).begins_with("geometry_queue:"), "recovery names the stalled raw step")
	_check(PreparationWatchdog.resource_is_retired(PROP_B + ".lla_gltf") and AssetGeometry._requests.is_empty() and AssetGeometry._preparing.is_empty(), "the unfinished request is quarantined, not owned")
	_check(not paused, "recovery restores the pause state")
	# While quarantined, a fresh load must decode independently, never rejoin.
	_forget(PROP_B)
	PreparationWatchdog.synchronous = false
	_check(AssetGeometry.request(PROP_B) == ERR_UNAVAILABLE, "a quarantined path is never requested again")
	_check(await AssetGeometry.prepare(PROP_B, self) and _held.loads == loads_before + 1, "a quarantined path reloads without joining the held request")
	var recovered: PackedScene = AssetGeometry._scenes[PROP_B].scene
	_held.hold = false
	_held.gate.post()
	PreparationWatchdog.timeout_ms = 15000
	_check(await PreparationWatchdog.wait_until(self, "test_raw_cleanup", func(): return PreparationWatchdog._resources.is_empty()), "the late raw result is consumed exactly once")
	await process_frame
	_check(AssetGeometry._scenes[PROP_B].scene == recovered, "the late raw result does not overwrite the recovered scene")

func _test_takeover_at_each_yield() -> void:
	_reset()
	_check(await AssetGeometry.prepare(CAST, self), "reference cast load")
	var reference := _clip_count(CAST)
	_check(reference > 8000, "the cast model exercises the sliced animation path")
	var takeovers := 0
	for delay in 40:
		_forget(CAST)
		_reset()
		var owner: Array = []
		_prepare(CAST, owner)
		# The owner holds the decoded state once its request is consumed.
		while AssetGeometry._requests.has(CAST):
			await process_frame
		for frame in delay:
			await process_frame
		if not owner.is_empty() or AssetGeometry.is_prepared(CAST):
			# Published before a takeover could start; let the owner return.
			while owner.is_empty():
				await process_frame
			break
		PreparationWatchdog.timeout_ms = 0
		var follower: Array = []
		_prepare(CAST, follower)
		while owner.is_empty() or follower.is_empty():
			await process_frame
		takeovers += 1
		var published: PackedScene = AssetGeometry._scenes.get(CAST, {}).get("scene")
		_check(owner == [true] and follower == [true] and published != null, "takeover %d frames into publication: both callers succeed" % delay)
		_check(_clip_count(CAST) == reference, "takeover %d frames into publication: complete scene" % delay)
		for frame in 4:
			await process_frame
		_check(AssetGeometry._scenes[CAST].scene == published and AssetGeometry._preparing.is_empty(), "takeover %d frames into publication: the old coroutine publishes nothing" % delay)
	_check(takeovers >= 3, "takeover was exercised at several publication yields (%d)" % takeovers)
