## Frame-cost A/B: loads the production campaign the way perf_probe.gd does,
## turns vsync off so frame time shows the real cost, and walks the same path
## in the Garden (EX-CH01-S04) and the Chapter 5 full cast (EX-CH05-S02) once
## per rendering variant. Prints avg / p50 / p95 ms per variant.
## Windowed only: Godot --path game --resolution 1280x720 --script res://tools/perf_ab.gd
extends SceneTree

const MAIN := preload("res://scenes/main.tscn")
const SECONDS := 8.0
var _storage = preload("res://tools/support/isolated_storage.gd").new()
var _main: Node
var _campaign: Node

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _storage.setup("perf_ab") or not _storage.prepare_rendering_cache():
		quit(2)
		return
	CampaignCutscenePlayer.autoplay = false
	_main = MAIN.instantiate()
	_main.save_path = _storage.path
	_main.legacy_save_path = _storage.legacy_path
	root.add_child(_main)
	while not _main.title_ready:
		await process_frame
	await _main._launch_campaign({})
	_campaign = _main._campaign
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	for scene in ["EX-CH01-S04", "EX-CH05-S02"]:
		if scene == "EX-CH01-S04":
			_campaign.route.start_at(scene)
			_campaign._sync_route_projection()
			_campaign._refresh_world()
		else:
			_campaign._start_extended(scene)
		_campaign.hud.refresh_scene()
		await _main.preparation.wait_idle()
		await _walk(1.0) # warm up materials before timing
		for variant in ["baseline", "taa_off", "omni_shadows_off", "sun_shadows_off", "lod_x4", "all_off", "baseline_again"]:
			_apply(variant, true)
			var times := await _walk(SECONDS)
			_apply(variant, false)
			times.sort()
			var avg: float = times.reduce(func(a, b): return a + b, 0.0) / times.size()
			print("PERF AB %s %-18s frames=%4d avg=%6.2f p50=%6.2f p95=%6.2f ms" % [scene, variant, times.size(), avg, times[times.size() / 2], times[int(times.size() * 0.95)]])
	_release()
	await _main.preparation.wait_idle()
	_main.free()
	_storage.cleanup()
	quit(0)

func _apply(variant: String, on: bool) -> void:
	var viewport := root.get_viewport()
	if variant in ["taa_off", "all_off"]:
		viewport.use_taa = not on
	if variant in ["lod_x4", "all_off"]:
		viewport.mesh_lod_threshold = 4.0 if on else 1.0
	for light in root.find_children("*", "Light3D", true, false):
		if light is OmniLight3D or light is SpotLight3D:
			if variant in ["omni_shadows_off", "all_off"]:
				if on:
					light.set_meta("ab_shadow", light.shadow_enabled)
					light.shadow_enabled = false
				elif light.has_meta("ab_shadow"):
					light.shadow_enabled = light.get_meta("ab_shadow")
		elif light is DirectionalLight3D and variant in ["sun_shadows_off", "all_off"]:
			if on:
				light.set_meta("ab_shadow", light.shadow_enabled)
				light.shadow_enabled = false
			elif light.has_meta("ab_shadow"):
				light.shadow_enabled = light.get_meta("ab_shadow")

func _walk(seconds: float) -> Array:
	var times: Array = []
	var start := Time.get_ticks_usec()
	var previous := start
	var step := -1
	while (Time.get_ticks_usec() - start) / 1000000.0 < seconds:
		await process_frame
		var now := Time.get_ticks_usec()
		times.append((now - previous) / 1000.0)
		previous = now
		var current := int((now - start) / 1000000.0)
		if current != step:
			step = current
			_release()
			Input.action_press(["move_left", "move_right", "move_forward", "move_back"][int(step / 2) % 4])
			_campaign._player.follow_camera.yaw += 0.35
	_release()
	return times

func _release() -> void:
	for action in ["move_left", "move_right", "move_forward", "move_back"]:
		Input.action_release(action)
