## Windowed rendering benchmark (opt-in, never attached to normal gameplay).
## Godot --path game --rendering-method forward_plus --rendering-driver metal \
##   --script res://tools/perf_probe.gd -- --perf-probe --perf-output=/tmp/lla-before
## CPU fallback: --headless --fixed-fps 60 ... -- --perf-probe --perf-cpu-only
##   --perf-output=/tmp/lla-cpu (simulation CPU only, never rendered FPS).
extends SceneTree

const MAIN := preload("res://scenes/main.tscn")
const PANELS := ["objective", "journal_discovery", "puzzle", "dialogue_captions", "sources", "pause"]
var _main: Node3D
var _campaign: Chapter1Campaign
var _seconds := 20.0
var _output := "/tmp/lla-perf"
var _cpu_only := false
var _frames: Array = []
var _events: Array = []
var _summaries: Array = []
var _slot := ""
var _metadata: Dictionary = {}
var _physics_stamp := 0
var _event_last := 0
var _event_max := 0.0
var _event_frames := 0

func _init() -> void:
	_run.call_deferred()

## First physics tick of the current frame (physics_frame precedes node physics).
func _stamp_physics() -> void:
	if _physics_stamp == 0:
		_physics_stamp = Time.get_ticks_usec()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.has("--perf-probe"):
		push_error("Explicit --perf-probe required")
		quit(2)
		return
	for arg in args:
		if arg.begins_with("--perf-seconds="):
			_seconds = maxf(1.0, float(arg.get_slice("=", 1)))
		if arg.begins_with("--perf-output="):
			_output = arg.trim_prefix("--perf-output=")
	_cpu_only = args.has("--perf-cpu-only")
	if DisplayServer.get_name() == "headless" and not _cpu_only:
		push_error("NO RENDER DATA: run windowed, or explicitly select --perf-cpu-only")
		quit(2)
		return
	_slot = OS.get_temp_dir().path_join("lla-perf-%d.json" % OS.get_process_id())
	_metadata = {"engine": Engine.get_version_info(), "display": DisplayServer.get_name(), "renderer": RenderingServer.get_current_rendering_method(), "driver": RenderingServer.get_current_rendering_driver_name(), "cpu_only": _cpu_only, "window": root.size, "transition_schema": 3, "seconds": _seconds, "vsync": DisplayServer.window_get_vsync_mode(), "max_fps": Engine.max_fps, "physics_ticks": Engine.physics_ticks_per_second}
	print("PERF metadata ", JSON.stringify(_metadata))
	physics_frame.connect(_stamp_physics)
	if not _cpu_only:
		RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	LoadTrace.enabled = true
	# The probe drives its own walk and video samples; scene cutscenes would cover them.
	CampaignCutscenePlayer.autoplay = false
	process_frame.connect(_event_heartbeat)
	_main = MAIN.instantiate()
	_main.save_path = _slot
	_main.legacy_save_path = _slot + ".legacy"
	await _transition_event("title_build", func():
		root.add_child(_main)
		while not _main.title_ready:
			await process_frame
	)
	if not _cpu_only:
		await _sample("title", false, false)
	await _transition_event("new_campaign", func(): await _main._launch_campaign({}))
	_campaign = _main._campaign
	await physics_frame
	if _campaign == null or _campaign._player == null:
		push_error("Campaign failed to start")
		quit(1)
		return
	if _cpu_only:
		await _cpu_samples("hub")
		await _cpu_walk("hub")
	else:
		await _sample("hub_walk", true, false)
		await _sample("hub_panels", false, true)
	await _transition_event("garden_enter", func():
		_campaign.route.start_at("EX-CH01-S04")
		_campaign._sync_route_projection()
		_campaign._refresh_world()
		_campaign.hud.refresh_scene()
	)
	await physics_frame
	if _cpu_only:
		await _cpu_samples("garden")
		await _cpu_walk("garden")
	else:
		await _sample("garden_walk", true, false)
		await _sample("garden_panels", false, true)
	# Visit the same room again: room/asset reloads must be visible in event timings.
	await _transition_event("garden_rebuild", func(): _campaign._refresh_world())
	await _transition_event("full_cast_enter", func():
		_campaign._start_extended("EX-CH05-S02")
		_campaign.hud.refresh_scene()
	)
	await physics_frame
	if _cpu_only:
		await _cpu_samples("full_cast")
		await _cpu_walk("full_cast")
	else:
		await _sample("full_cast_walk", true, false)
		await _sample("full_cast_panels", false, true)
		await _sample_cutscenes()
	_release_input()
	_main.free()
	await process_frame
	# Only our isolated checkpoint and backup, never a user's saved expedition.
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(_slot + suffix):
			DirAccess.remove_absolute(_slot + suffix)
	if not _write_results():
		quit(1)
		return
	print("PERF RESULT: PASS (", "CPU OPERATIONS ONLY; rendered frame times NOT ASSESSED" if _cpu_only else "rendered samples recorded", ")")
	quit()

func _event_heartbeat() -> void:
	if _event_last == 0:
		return
	var now := Time.get_ticks_usec()
	_event_max = maxf(_event_max, (now - _event_last) / 1000.0)
	_event_last = now
	_event_frames += 1

## Includes the first draw after construction; total latency is not a frame time.
func _transition_event(label: String, action: Callable) -> void:
	await process_frame
	LoadTrace.steps.clear()
	_event_last = Time.get_ticks_usec()
	_event_max = 0.0
	_event_frames = 0
	var start := _event_last
	await action.call()
	if is_instance_valid(_campaign):
		await _campaign.wait_loading()
	await process_frame
	await process_frame
	var elapsed := (Time.get_ticks_usec() - start) / 1000.0
	_event_last = 0
	var event := {"event": label, "duration_ms": elapsed, "max_frame_interval_ms": _event_max, "transition_frames": _event_frames, "steps": LoadTrace.steps.duplicate(true)}
	_events.append(event)
	print("PERF transition ", JSON.stringify(event))

func _event(label: String, action: Callable) -> void:
	var start := Time.get_ticks_usec()
	action.call()
	var elapsed := (Time.get_ticks_usec() - start) / 1000.0
	_events.append({"event": label, "cpu_ms": elapsed})
	print("PERF event ", label, " cpu_ms=", elapsed)

## Walking CPU sweep: the same input/camera schedule as the rendered walk
## sample, keyed to fixed-60 ticks. Per tick: wall interval, the physics part
## (physics_frame -> process_frame: node physics callbacks, skeleton modifiers,
## physics server step) and the remainder (node _process + dummy render).
func _cpu_walk(label: String) -> void:
	var ticks := int(_seconds * 60.0)
	var intervals: Array = []
	var physics: Array = []
	var remainder: Array = []
	await process_frame
	var previous := Time.get_ticks_usec()
	for index in ticks:
		if index % 60 == 0:
			_walk_step(index / 60)
		await physics_frame
		var physics_start := Time.get_ticks_usec()
		await process_frame
		var now := Time.get_ticks_usec()
		var interval := (now - previous) / 1000.0
		var physics_ms := (now - physics_start) / 1000.0
		intervals.append(interval)
		physics.append(physics_ms)
		remainder.append(maxf(0.0, interval - physics_ms))
		_frames.append([label + "_walk_cpu", index, interval, interval - physics_ms, physics_ms, 0, 0, Performance.get_monitor(Performance.OBJECT_COUNT), Performance.get_monitor(Performance.MEMORY_STATIC), 0, 0, 0, physics_ms, 0, 0])
		previous = now
	_summarize(label + "_walk_tick_cpu", intervals)
	_summarize(label + "_walk_physics_cpu", physics)
	_summarize(label + "_walk_process_cpu", remainder)
	await _cpu_breakdown(label)
	_release_input()

func _walk_step(step: int) -> void:
	_release_input()
	Input.action_press(["move_left", "move_right", "move_forward", "move_back"][int(step / 2) % 4])
	_campaign._player.follow_camera.yaw += 0.35

## Per-system cost while walking, each called directly N times in the current
## (moving) state. Sums are over every visible character in the room.
func _cpu_breakdown(label: String) -> void:
	var dt := 1.0 / 60.0
	var bodies: Array = []
	for id in _campaign._crew.local_ids:
		bodies.append(_campaign._crew.bodies[id])
	var player: PlayerController = _campaign._player
	var systems := {
		"animation_tree_advance": _each.bind(bodies, func(b): b.animation.advance(dt, b.horizontal_speed)),
		"skeleton_advance_all_modifiers": _each.bind(bodies, func(b): b.animation.skeleton.advance(dt)),
		"locomotion_pose_gd": _each.bind(bodies, func(b): b.pose_modifier._process_modification_with_delta(dt)),
		"boot_sample_heights_x2": _each.bind(bodies, func(b): return [b.pose_modifier._surface_meter.sample_heights(), b.pose_modifier._surface_meter.sample_heights()]),
		"foot_orientation_gd": _each.bind(bodies, func(b): _modifier(b, "FootOrientation")._process_modification_with_delta(dt)),
		"nearest_interactable": _each.bind(bodies, func(b): b.nearest_interactable()),
		"update_gaze": _each.bind(bodies, func(b): b._update_gaze(dt)),
		"face_atlas_process": _each.bind(bodies, func(b): _face(b)._process(dt)),
		"face_light_update": _each.bind(bodies, func(b): _face(b)._update_face_light()),
		"player_camera_update": func(): player.follow_camera.update_camera(dt, player._yaw, player.horizontal_speed),
		"player_step_up": func(): player._step_up(dt),
		"campaign_nearby_target": func(): _campaign.nearby_target(),
		"campaign_physics_process": func(): _campaign._physics_process(dt),
		"director_query": func(): _campaign.director.query(),
		"director_snapshot": func(): _campaign.director.snapshot(),
		"route_gate_status": func(): _campaign.route.gate_status(),
		"targets_for_scene": func(): _campaign.targets_for_current_scene(),
	}
	# Native modifiers: time skeleton.advance with only that modifier active.
	for kind in ["TwoBoneIK3D", "LookAtModifier3D", "SpringBoneSimulator3D"]:
		systems["native_" + kind] = _native_modifier_cost.bind(bodies, kind, dt)
	var targets: Array = _campaign.targets_for_current_scene()
	if not targets.is_empty():
		var target_id := String(targets[0].get("target_id", ""))
		systems["forecast_target_on_change"] = func(): _campaign.forecast_target(target_id)
		systems["campaign_query_on_change"] = func(): _campaign.query()
		systems["outpost_bind_query_on_change"] = func(): _campaign.hud.outpost.bind_query(_campaign.query())
	var report := {}
	for system in systems:
		var values: Array = []
		for repeat in 40:
			var start := Time.get_ticks_usec()
			var extra = systems[system].call()
			var spent := (Time.get_ticks_usec() - start) / 1000.0
			values.append(float(extra) if extra is float else spent)
		values.sort()
		report[system] = {"p50_ms": _percentile(values, 0.5), "p95_ms": _percentile(values, 0.95), "max_ms": values[-1]}
	_events.append({"event": label + "_breakdown", "characters": bodies.size(), "systems": report})
	print("PERF breakdown ", label, " characters=", bodies.size())
	for system in report:
		print("  %-34s p50 %7.3f  p95 %7.3f  max %7.3f ms" % [system, report[system].p50_ms, report[system].p95_ms, report[system].max_ms])
	await physics_frame

func _each(bodies: Array, action: Callable) -> void:
	for body in bodies:
		action.call(body)

func _modifier(body: PlayerController, node_name: String) -> Node:
	return body.animation.skeleton.get_node(node_name)

func _face(body: PlayerController) -> FaceAtlas:
	return body.character.get_node("FaceAtlas") as FaceAtlas

## Returns the measured cost of the native modifiers of one class across bodies.
func _native_modifier_cost(bodies: Array, kind: String, dt: float) -> float:
	var total := 0.0
	for b in bodies:
		var rig: Skeleton3D = b.animation.skeleton
		var saved := {}
		for child in rig.get_children():
			if child is SkeletonModifier3D:
				saved[child] = child.active
				child.active = false
		var start := Time.get_ticks_usec()
		rig.advance(dt)
		var bare := Time.get_ticks_usec() - start
		for child in saved:
			child.active = child.is_class(kind) and saved[child]
		start = Time.get_ticks_usec()
		rig.advance(dt)
		total += maxf(0.0, (Time.get_ticks_usec() - start) - bare) / 1000.0
		for child in saved:
			child.active = saved[child]
	return total

func _cpu_samples(label: String) -> void:
	var values: Array = []
	# TIME_* monitors update periodically, so their repeated values are not
	# independent per-tick CPU samples. Time consecutive fixed-60 simulation
	# ticks directly here; the dummy renderer means these are NEVER GPU/FPS data.
	await process_frame
	var previous := Time.get_ticks_usec()
	for index in 120:
		await physics_frame
		await process_frame
		var now := Time.get_ticks_usec()
		values.append((now - previous) / 1000.0)
		previous = now
	_summarize(label + "_headless_tick_cpu", values)
	# Isolate the surface skinning used twice per character, per physics tick.
	values = []
	for index in 120:
		var start := Time.get_ticks_usec()
		var meter = _campaign._player.pose_modifier._surface_meter
		if meter.has_method("sample_heights"):
			meter.sample_heights()
		else:
			meter.sample(1.0 / 60.0)
		values.append((Time.get_ticks_usec() - start) / 1000.0)
	_summarize(label + "_boot_skinning_cpu", values)
	for panel in PANELS:
		_event(label + "_panel_" + panel, func():
			_campaign.hud.panels.open_panel(panel)
			_campaign.hud.panels.close_panel()
		)

func _sample(label: String, walking: bool, panels: bool) -> void:
	var values: Array = []
	var start := Time.get_ticks_usec()
	var previous := start
	var previous_step := -1
	# No warmup exclusion: first-use pipeline/texture/panel stalls count.
	while (Time.get_ticks_usec() - start) / 1000000.0 < _seconds:
		_physics_stamp = 0
		await process_frame
		var now := Time.get_ticks_usec()
		var ms := (now - previous) / 1000.0
		var physics_segment := (now - _physics_stamp) / 1000.0 if _physics_stamp > previous else 0.0
		previous = now
		values.append(ms)
		var viewport := root.get_viewport_rid()
		_frames.append([label, (now - start) / 1000.0, ms,
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
			Performance.get_monitor(Performance.OBJECT_COUNT),
			Performance.get_monitor(Performance.MEMORY_STATIC),
			Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),
			Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),
			Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED),
			physics_segment,
			RenderingServer.viewport_get_measured_render_time_cpu(viewport) + RenderingServer.get_frame_setup_time_cpu(),
			RenderingServer.viewport_get_measured_render_time_gpu(viewport)])
		var step := int((now - start) / 1000000.0)
		if step != previous_step:
			previous_step = step
			if walking:
				_release_input()
				Input.action_press(["move_left", "move_right", "move_forward", "move_back"][int(step / 2) % 4])
				# Sweep around the real player so previously hidden materials render.
				_campaign._player.follow_camera.yaw += 0.35
			if panels:
				_campaign.hud.panels.close_panel()
				if step % 2 == 0:
					_campaign.hud.panels.open_panel(PANELS[int(step / 2) % PANELS.size()])
	_release_input()
	if _campaign != null:
		_campaign.hud.panels.close_panel()
	_summarize(label, values)

func _release_input() -> void:
	for action in ["move_left", "move_right", "move_forward", "move_back"]:
		Input.action_release(action)

## Production campaign currently presents captions; the showcase owns native
## video playback. Exercise that same Theora/VideoStreamPlayer path over the
## populated room, without instantiating the entire development asset hall.
func _sample_cutscenes() -> void:
	var media := CampaignCutsceneRuntime.new(_campaign.content)
	var layer := CanvasLayer.new()
	layer.layer = 200
	root.add_child(layer)
	var background := ColorRect.new()
	background.color = Color.BLACK
	layer.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var frame := AspectRatioContainer.new()
	frame.ratio = 16.0 / 9.0
	frame.stretch_mode = AspectRatioContainer.STRETCH_FIT
	background.add_child(frame)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var video := VideoStreamPlayer.new()
	video.expand = true
	video.volume_db = -80.0 # Diagnostic playback need not play sound in the workspace.
	video.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	video.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(video)
	for item in media.available_cutscenes():
		if not item.media_present:
			continue
		_campaign.set_ui_paused(true)
		_event("video_open_" + item.id, func():
			var stream := VideoStreamTheora.new()
			stream.file = item.runtime_path
			video.stream = stream
			video.play()
		)
		await _sample("video_" + item.id, false, false)
		_events.append({"event": "video_position_" + item.id, "seconds": video.stream_position})
		video.stop()
		video.stream = null
	layer.free()
	_campaign.set_ui_paused(false)

func _summarize(label: String, values: Array) -> void:
	values.sort()
	var over := 0
	for value in values:
		if value > 33.0:
			over += 1
	var result := {"sample": label, "frames_or_calls": values.size(), "p50_ms": _percentile(values, 0.5), "p95_ms": _percentile(values, 0.95), "p99_ms": _percentile(values, 0.99), "max_ms": values[-1], "over_33ms": over}
	_summaries.append(result)
	print("PERF summary ", JSON.stringify(result))

func _percentile(values: Array, quantile: float) -> float:
	return values[clampi(int(ceil(values.size() * quantile)) - 1, 0, values.size() - 1)]

func _write_results() -> bool:
	var json := FileAccess.open(_output + ".json", FileAccess.WRITE)
	if json == null:
		push_error("Cannot write probe output: " + _output)
		return false
	json.store_string(JSON.stringify({"metadata": _metadata, "cpu_only": _cpu_only, "summaries": _summaries, "events": _events}, "\t"))
	var csv := FileAccess.open(_output + ".csv", FileAccess.WRITE)
	if csv == null:
		push_error("Cannot write probe CSV: " + _output)
		return false
	csv.store_csv_line(PackedStringArray(["sample", "elapsed_ms", "frame_ms", "process_ms", "physics_ms", "draw_calls", "primitives", "objects", "static_bytes", "video_bytes", "texture_bytes", "buffer_bytes", "physics_segment_ms", "render_cpu_ms", "render_gpu_ms"]))
	for row in _frames:
		var columns := PackedStringArray()
		for value in row:
			columns.append(str(value))
		csv.store_csv_line(columns)
	return true
