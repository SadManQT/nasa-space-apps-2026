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

func _init() -> void:
	_run.call_deferred()

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
	_metadata = {"engine": Engine.get_version_info(), "display": DisplayServer.get_name(), "renderer": RenderingServer.get_current_rendering_method(), "driver": RenderingServer.get_current_rendering_driver_name(), "cpu_only": _cpu_only, "window": root.size, "seconds": _seconds, "vsync": DisplayServer.window_get_vsync_mode(), "max_fps": Engine.max_fps, "physics_ticks": Engine.physics_ticks_per_second}
	print("PERF metadata ", JSON.stringify(_metadata))
	_main = MAIN.instantiate()
	_main.save_path = _slot
	_main.legacy_save_path = _slot + ".legacy"
	_event("title_build", func(): root.add_child(_main))
	if not _cpu_only:
		await _sample("title", false, false)
	_event("new_campaign", func(): _main._launch_campaign({}))
	_campaign = _main._campaign
	await physics_frame
	if _campaign == null or _campaign._player == null:
		push_error("Campaign failed to start")
		quit(1)
		return
	if _cpu_only:
		await _cpu_samples("hub")
	else:
		await _sample("hub_walk", true, false)
		await _sample("hub_panels", false, true)
	_event("garden_enter", func():
		_campaign.route.start_at("EX-CH01-S04")
		_campaign._sync_route_projection()
		_campaign._refresh_world()
		_campaign.hud.refresh_scene()
	)
	await physics_frame
	if _cpu_only:
		await _cpu_samples("garden")
	else:
		await _sample("garden_walk", true, false)
		await _sample("garden_panels", false, true)
	# Visit the same room again: room/asset reloads must be visible in event timings.
	_event("garden_rebuild", func(): _campaign._refresh_world())
	_event("full_cast_enter", func():
		_campaign._start_extended("EX-CH05-S02")
		_campaign.hud.refresh_scene()
	)
	await physics_frame
	if _cpu_only:
		await _cpu_samples("full_cast")
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

func _event(label: String, action: Callable) -> void:
	var start := Time.get_ticks_usec()
	action.call()
	var elapsed := (Time.get_ticks_usec() - start) / 1000.0
	_events.append({"event": label, "cpu_ms": elapsed})
	print("PERF event ", label, " cpu_ms=", elapsed)

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
		await process_frame
		var now := Time.get_ticks_usec()
		var ms := (now - previous) / 1000.0
		previous = now
		values.append(ms)
		_frames.append([label, (now - start) / 1000.0, ms,
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
			Performance.get_monitor(Performance.OBJECT_COUNT),
			Performance.get_monitor(Performance.MEMORY_STATIC),
			Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),
			Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),
			Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED)])
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
	csv.store_csv_line(PackedStringArray(["sample", "elapsed_ms", "frame_ms", "process_ms", "physics_ms", "draw_calls", "primitives", "objects", "static_bytes", "video_bytes", "texture_bytes", "buffer_bytes"]))
	for row in _frames:
		var columns := PackedStringArray()
		for value in row:
			columns.append(str(value))
		csv.store_csv_line(columns)
	return true
