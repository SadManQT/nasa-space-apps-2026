## Performance changes must preserve boot contact, gait cycles and independent actors.
extends SceneTree

const Meter = preload("res://scripts/review/foot_slide.gd")
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
	await _test_threaded_geometry()
	for id in ["Kai", "Amara", "Mei", "Rafi", "Ferreira"]:
		var path := "res://assets/characters/CH_%s/CH_%s.glb" % [id, id]
		var actor := AssetGeometry.load_glb(path)
		var copy := AssetGeometry.load_glb(path)
		_check(actor != null and copy != null and actor != copy, id + " cached actors are distinct")
		root.add_child(actor)
		root.add_child(copy)
		_check(actor.find_children("*", "MeshInstance3D", true, false).size() == copy.find_children("*", "MeshInstance3D", true, false).size(), id + " cache retains all meshes")
		var player := actor.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
		var rig := actor.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
		var copy_player := copy.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
		var copy_rig := copy.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
		player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		copy_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		_check(rig != copy_rig, id + " independent skeleton")
		var reference := LocomotionClips.new()
		_check(reference.prepare(player, rig), id + " reference gait analysis")
		_check(not copy_player.has_animation_library("motion"), id + " cached source has no instance's prepared library")
		var baked := LocomotionClips.new()
		_check(baked.prepare(copy_player, copy_rig, path), id + " baked preparation")
		_check(baked._surface_meter == null, id + " validated bake skips runtime analysis")
		for gait in reference.gaits:
			for key in ["speed", "period", "start", "source_length"]:
				_check(absf(reference.measurements[gait][key] - baked.measurements[gait][key]) < 0.000001, id + " " + gait + " " + key)
			var expected := player.get_animation("motion/" + gait + "_cycle")
			var actual := copy_player.get_animation("motion/" + gait + "_cycle")
			_check(expected.get_track_count() == actual.get_track_count(), id + " cycle retains all tracks")
			var same := true
			var max_error := 0.0
			for track in expected.get_track_count():
				if expected.track_get_path(track) != actual.track_get_path(track) or expected.track_get_key_count(track) != actual.track_get_key_count(track):
					same = false
					continue
				for key in range(0, expected.track_get_key_count(track), 30):
					var a = expected.track_get_key_value(track, key)
					var b = actual.track_get_key_value(track, key)
					if a is Quaternion:
						var error := Vector4(a.x, a.y, a.z, a.w).distance_to(Vector4(b.x, b.y, b.z, b.w))
						max_error = maxf(max_error, error)
						same = same and error < 0.000001
					else:
						max_error = maxf(max_error, a.distance_to(b))
						same = same and a.distance_to(b) < 0.000001
			_check(same, id + " " + gait + " baked cycle matches reference (max error %.9f)" % max_error)
		var meter := Meter.new()
		meter.setup(actor, rig)
		# Translation/yaw/pitch verify world-space Y, rather than ankle or bind height.
		actor.transform = Transform3D(Basis.from_euler(Vector3(0.07, 0.4, -0.03)), Vector3(2, 1.3, -3))
		for clip in ["Walk_loop", "Run_loop", "Sprint_loop", "Idle_loop"]:
			player.play("motion/" + clip)
			for phase in [0.0, 0.2, 0.5, 0.8]:
				player.seek(player.current_animation_length * phase, true)
				var full := meter.sample(1.0 / 60.0)
				var heights := meter.sample_heights()
				for side in ["left", "right"]:
					_check(absf(full[side].height - heights[side].height) < 0.00001, id + " exact " + clip + " " + side + " boot height")
		actor.free()
		copy.free()
	_check(AssetGeometry._scenes.size() <= AssetGeometry.CACHE_LIMIT, "parsed-scene cache is bounded")
	# A mismatched model never uses another revision's calibration.
	var invalid_path := OS.get_temp_dir().path_join("lla-perf-stale-%d" % OS.get_process_id())
	DirAccess.make_dir_absolute(invalid_path)
	var invalid_glb := invalid_path.path_join("CH_Kai.glb")
	var invalid := FileAccess.open(invalid_glb, FileAccess.WRITE)
	invalid.store_string("different source revision")
	invalid.close()
	var stale := LocomotionClips.new()
	stale.gaits = ["Walk_loop", "Run_loop", "Sprint_loop"]
	_check(stale._baked_measurements(invalid_glb).is_empty(), "stale source hash falls back to analysis")
	DirAccess.remove_absolute(invalid_glb)
	DirAccess.remove_absolute(invalid_path)
	await _test_loading_transitions()
	if _retain_trace:
		_check_retained_trace()
	print("PERFORMANCE RUNTIME RESULT: %s (%d checks, %d failures)" % ["PASS" if _failures == 0 else "FAIL", _checks, _failures])
	quit(0 if _failures == 0 else 1)

var _last_tick := 0
var _longest_tick := 0.0
var _tick_count := 0
var _retain_trace := OS.get_environment("LLA_RETAIN_LOAD_TRACE") == "1"
var _trace_windows: Array = []
var _window_start := 0
var _first_step := 0
var _trace_enabled := false

func _heartbeat() -> void:
	if _last_tick == 0:
		return
	var now := Time.get_ticks_usec()
	_longest_tick = maxf(_longest_tick, (now - _last_tick) / 1000.0)
	_last_tick = now
	_tick_count += 1

func _start_monitor() -> void:
	if _retain_trace:
		_first_step = LoadTrace.steps.size()
		_trace_enabled = LoadTrace.enabled
	_last_tick = Time.get_ticks_usec()
	_window_start = _last_tick
	_longest_tick = 0.0
	_tick_count = 0

func _stop_monitor(label: String) -> void:
	_last_tick = 0
	var end := Time.get_ticks_usec() if _retain_trace else 0
	_check(_tick_count > 1, label + " yields moving loading frames")
	_check(_longest_tick < 50.0, label + " main-thread interval <50 ms (%.3f)" % _longest_tick)
	if _retain_trace:
		_trace_windows.append({"label": label, "start_usec": _window_start, "end_usec": end, "frames": _tick_count, "max_interval_ms": _longest_tick, "trace_enabled": _trace_enabled, "first_step": _first_step, "end_step": LoadTrace.steps.size()})

func _test_threaded_geometry() -> void:
	process_frame.connect(_heartbeat)
	for id in ["Kai", "Amara", "Mei", "Rafi", "Ferreira", "PR_MissionTable"]:
		var path := "res://assets/characters/CH_%s/CH_%s.glb" % [id, id] if not id.begins_with("PR_") else "res://assets/props/%s/%s.glb" % [id, id]
		_start_monitor()
		_check(await AssetGeometry.prepare(path, self), id + " threaded raw preparation succeeds")
		await process_frame
		_stop_monitor(id + " raw load")
		var threaded := AssetGeometry.load_glb(path)
		# Independent original decoder catches omitted mesh-conversion extensions,
		# transforms, skeletons, face layers or clip tracks, not just cached copies.
		var document := GLTFDocument.new()
		var state := GLTFState.new()
		state.handle_binary_image = GLTFState.HANDLE_BINARY_EMBED_AS_UNCOMPRESSED
		_check(document.append_from_file(path, state) == OK, id + " original raw decoder")
		var original := document.generate_scene(state)
		var meshes := threaded.find_children("*", "MeshInstance3D", true, false)
		var reference := original.find_children("*", "MeshInstance3D", true, false)
		_check(meshes.size() == reference.size() and not meshes.is_empty(), id + " every original mesh retained")
		for index in mini(meshes.size(), reference.size()):
			var a := meshes[index] as MeshInstance3D
			var b := reference[index] as MeshInstance3D
			_check(a.name == b.name and a.transform.is_equal_approx(b.transform), id + " mesh transform " + a.name)
			_check(a.mesh.get_surface_count() == b.mesh.get_surface_count(), id + " mesh surfaces " + a.name)
			for surface in a.mesh.get_surface_count():
				_check(a.mesh.surface_get_arrays(surface).hash() == b.mesh.surface_get_arrays(surface).hash(), id + " exact vertices/indices/weights " + a.name)
				var source := a.mesh.surface_get_material(surface) as StandardMaterial3D
				var expected := b.mesh.surface_get_material(surface) as StandardMaterial3D
				if source != null and expected != null and source.albedo_texture != null:
					_check(source.albedo_texture.get_size() == expected.albedo_texture.get_size(), id + " full texture resolution " + a.name)
					_check(source.albedo_texture.get_image().get_data().slice(0, expected.albedo_texture.get_image().get_data().size()) == expected.albedo_texture.get_image().get_data(), id + " unchanged base pixels " + a.name)
		if not id.begins_with("PR_"):
			_start_monitor()
			_check(await LocomotionClips.prewarm(threaded, path, self), id + " gait worker succeeds")
			await process_frame
			_stop_monitor(id + " gait worker")
		threaded.free()
		original.free()

func _test_loading_transitions() -> void:
	_check(not await AssetGeometry.prepare("res://missing-perf-model.glb", self), "missing threaded GLB fails without blocking")
	LoadTrace.enabled = true
	LoadTrace.steps.clear()
	var main := preload("res://scenes/main.tscn").instantiate()
	var slot := OS.get_temp_dir().path_join("lla-perf-runtime-%d.json" % OS.get_process_id())
	main.save_path = slot
	main.legacy_save_path = slot + ".legacy"
	_start_monitor()
	root.add_child(main)
	while not main.title_ready:
		await process_frame
	_stop_monitor("production title")
	_start_monitor()
	await main._launch_campaign({})
	await process_frame
	_stop_monitor("production new campaign")
	var campaign := main._campaign as Chapter1Campaign
	_check(campaign.incremental_loading and not campaign.loading, "production uses incremental loader and completes")
	_check(campaign._crew.bodies.size() == 5, "title prepares all five cast actors")
	for id in campaign._crew.bodies:
		_check(campaign._crew.bodies[id].character.find_children("*", "MeshInstance3D", true, false).size() > 0, id + " prepared body has visible geometry")
	while main.preparation._room_busy:
		await process_frame
	_evict_room("LOC-03")
	_start_monitor()
	campaign.route.start_at("EX-CH01-S04")
	campaign._sync_route_projection()
	campaign._refresh_world()
	await campaign.wait_loading()
	await process_frame
	_stop_monitor("production garden entry")
	_check(campaign._room.room_id == "LOC-03" and campaign._player.character != null, "garden transition keeps room/player ready")
	_evict_room("LOC-02")
	_start_monitor()
	campaign._start_extended("EX-CH05-S02")
	await campaign.wait_loading()
	await process_frame
	_stop_monitor("production full cast entry")
	_check(campaign._crew.local_ids.size() == 5, "full cast is placed exactly once")
	# A lamp must advance under the same frame pump used while workers load.
	var card := LoadingCard.new()
	root.add_child(card)
	for frame in 4:
		await process_frame
	_check(card.ticks >= 3, "loading lamp keeps processing")
	card.free()
	# Finish optional look-ahead before tearing down this test's world.
	while main.preparation._room_busy:
		await process_frame
	var sync_decode := false
	for step in LoadTrace.steps:
		sync_decode = sync_decode or String(step.step).begins_with("glb_decode:")
	_check(not sync_decode, "production transitions never escape to synchronous GLB decode")
	# M3-100: advancing the garden from 27 Apr to 31 May swaps plant stage models without decoding on the main thread.
	while main.preparation._room_busy:
		await process_frame
	var garden_traced := LoadTrace.steps.size()
	for stage in ["bloom", "pod_bearing", "mature_pods", "mature_dry"]:
		var snap := campaign.director.snapshot()
		for p in snap.get("plants", []):
			if p is Dictionary and String(p.get("individual_id", "")) in ["ALO-01", "TARA-01"]:
				p["stage"] = stage
		campaign.director.restore_snapshot(snap)
		await main.preparation.prepare_room("LOC-03", "EX-CH03-S12", snap.get("plants", []))
		if campaign._room.room_id != "LOC-03":
			campaign._start_extended("EX-CH03-S09")
			await campaign.wait_loading()
		else:
			campaign._room.apply_plant_state(snap.get("plants", []))
		await process_frame
	var garden_sync := false
	for step in LoadTrace.steps.slice(garden_traced):
		garden_sync = garden_sync or String(step.step).begins_with("glb_decode:")
	_check(not garden_sync, "garden dated stage swaps (27 Apr to 31 May) never decode on the main thread")
	# M1-36: a ready exterior (LOC-10, EX-CH04-S06 under its verified work lights) enters on the LOLA terrain
	# through the same card, its heightfield, tiles and suited EVA bodies prepared off the main thread.
	while main.preparation._room_busy:
		await process_frame
	var traced := LoadTrace.steps.size()
	_start_monitor()
	campaign._start_extended("EX-CH04-S06")
	await campaign.wait_loading()
	await process_frame
	_stop_monitor("production terrain exterior entry")
	_check(campaign._room.room_id == "LOC-10" and campaign._room.on_terrain() and campaign._terrain != null, "LOC-10 stands on the streamed LOLA terrain")
	_check(campaign._terrain != null and campaign._terrain.stream.settled() and campaign._terrain.stream.rocks.size() > 0, "terrain rocks and LOD settled before the card closes")
	var ground := PhysicsRayQueryParameters3D.create(campaign._player.global_position + Vector3.UP * 5.0, campaign._player.global_position + Vector3.DOWN * 5.0, 1)
	_check(not campaign._player.get_world_3d().direct_space_state.intersect_ray(ground).is_empty(), "player stands over terrain collision")
	var terrain_sync := false
	for step in LoadTrace.steps.slice(traced):
		terrain_sync = terrain_sync or String(step.step).begins_with("glb_decode:")
	_check(not terrain_sync, "terrain exterior entry never escapes to synchronous GLB decode")
	# Every timed entry is complete. Drain existing optional look-ahead before
	# destroying its owner; do not move or prewarm any measured entry work.
	_check(await main.preparation.wait_idle(), "optional preparation drains before test teardown")
	LoadTrace.enabled = false
	if _retain_trace:
		# Serialize only after every measurement and optional look-ahead has finished.
		var report := {"schema": 1, "process_id": OS.get_process_id(), "window_clock": "Time.get_ticks_usec; process-relative", "window_context": "SceneTree main-thread heartbeat", "stage_context": "Original LoadTrace records have names/ms only; stage timestamps and thread IDs are unavailable. Ranges group records appended during each window; nested/background stages are not additive frame costs.", "windows": _trace_windows, "steps": LoadTrace.steps}
		var directory := OS.get_environment("TEST_LOG_DIR")
		if not directory.is_empty():
			var file := FileAccess.open(directory.path_join("loading_trace.json"), FileAccess.WRITE)
			if file != null:
				file.store_string(JSON.stringify(report, "\t", true, true) + "\n")
				file.close()
	main.free()
	# Outside every measurement: let AudioServer retire freed playback handles.
	await create_timer(0.1).timeout
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(slot + suffix):
			DirAccess.remove_absolute(slot + suffix)

func _evict_room(room_id: String) -> void:
	for path in LoadPreparation.room_paths(room_id):
		AssetGeometry._scenes.erase(path)
		AssetGeometry._recent.erase(path)

func _check_retained_trace() -> void:
	var directory := OS.get_environment("TEST_LOG_DIR")
	_check(not directory.is_empty(), "retained trace requires TEST_LOG_DIR")
	if directory.is_empty():
		return
	var path := directory.path_join("loading_trace.json")
	_check(FileAccess.file_exists(path), "opt-in loading trace is retained beside complete suite logs")
	if not FileAccess.file_exists(path):
		return
	var report = JSON.parse_string(FileAccess.get_file_as_string(path))
	_check(report is Dictionary and report.get("windows") is Array and report.get("steps") is Array, "retained loading trace is structured JSON")
	if not report is Dictionary or not report.get("windows") is Array or not report.get("steps") is Array:
		return
	var complete: bool = report.steps.size() == LoadTrace.steps.size()
	for index in mini(report.steps.size(), LoadTrace.steps.size()):
		var saved: Dictionary = report.steps[index]
		var original: Dictionary = LoadTrace.steps[index]
		# JSON parsing can round by one ULP; 1e-9 ms is below the timer's 0.001 ms resolution.
		complete = complete and saved.size() == original.size() and saved.step == original.step and absf(float(saved.ms) - float(original.ms)) < 0.000000001
	_check(complete, "retained trace keeps every original stage at timer precision without invented fields")
	var expected: Array = []
	for id in ["Kai", "Amara", "Mei", "Rafi", "Ferreira", "PR_MissionTable"]:
		expected.append(id + " raw load")
		if not id.begins_with("PR_"):
			expected.append(id + " gait worker")
	expected.append_array(["production title", "production new campaign", "production garden entry", "production full cast entry", "production terrain exterior entry"])
	_check(report.windows.map(func(window): return window.label) == expected, "all sixteen actual measurements are retained in order")
	var previous_end := 0
	for window in report.windows:
		_check(window.start_usec > previous_end and window.end_usec >= window.start_usec and window.frames > 1 and window.max_interval_ms > 0.0, "measurement clock/frame data retained: " + String(window.label))
		previous_end = int(window.end_usec)
		var first := int(window.first_step)
		var end := int(window.end_step)
		_check(first >= 0 and first <= end and end <= report.steps.size() and (end > first if window.trace_enabled else first == end), "actual stage range linked: " + String(window.label))
