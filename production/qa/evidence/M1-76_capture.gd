## M1-76: real opening campaign, active renderer and rendered shadow contributions.
## Run through M1-76_capture.sh on a desktop; --probe-only checks configuration headless.
extends SceneTree

const CAMPAIGN = preload("res://scenes/campaign/chapter1_campaign.tscn")
const Contract = preload("res://scripts/world/room_contract.gd")
const Presentation = preload("res://scripts/world/room_presentation.gd")
var storage = preload("res://tools/support/isolated_storage.gd").new()
var campaign: Chapter1Campaign
var checks := 0
var failures := 0
var renderer := ""
var report: Dictionary = {}

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	renderer = RenderingServer.get_current_rendering_method()
	var probe_only := OS.get_cmdline_user_args().has("--probe-only")
	report = {"renderer": renderer, "driver": RenderingServer.get_current_rendering_driver_name(),
		"display": DisplayServer.get_name(), "rendered": not probe_only, "lights": [],
		"capture_started_at_utc": Time.get_datetime_string_from_system(true) + "Z",
		"capture_runner": OS.get_environment("M1_76_CAPTURE_RUN_BY")}
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--expect-renderer="):
			_check(renderer == arg.trim_prefix("--expect-renderer="), "requested renderer is active (no silent fallback)")
	if not probe_only and DisplayServer.get_name() == "headless":
		_check(false, "rendered evidence requires a window")
		_finish()
		return
	if not storage.setup("M1-76-shadow-capture"):
		_check(false, "isolated save storage")
		_finish()
		return
	CampaignCutscenePlayer.autoplay = false
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	if not probe_only:
		root.always_on_top = true
		root.grab_focus()
	campaign = CAMPAIGN.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	root.add_child(campaign)
	_check(campaign._startup_error.is_empty() and campaign._room != null, "real campaign opens")
	if campaign._room == null:
		_finish()
		return
	var layout := Contract.layout("LOC-01")
	var lights := campaign._room.get_node("RoomLighting")
	var practicals := lights.find_children("Practical_*", "OmniLight3D", false, false)
	_check(practicals.size() == layout.ceiling_strips.size(), "all authored practicals exist")
	var shadow_count := 0
	for index in practicals.size():
		var light := practicals[index] as OmniLight3D
		shadow_count += int(light.shadow_enabled)
		_check(light.shadow_enabled == (index < int(layout.lighting.shadow_lights)), "authored shadow budget " + light.name)
		_check(is_equal_approx(light.light_energy, float(layout.lighting.practical_energy))
			and is_equal_approx(light.omni_range, float(layout.lighting.practical_range_m)), "authored lighting " + light.name)
		if renderer == "gl_compatibility":
			_check(light.omni_shadow_mode == OmniLight3D.SHADOW_CUBE, "Compatibility uses cubemap " + light.name)
		elif renderer == "forward_plus":
			_check(light.omni_shadow_mode == OmniLight3D.SHADOW_DUAL_PARABOLOID, "Forward+ retains two-pass shadows " + light.name)
		report.lights.append({"name": light.name, "shadow_mode": light.omni_shadow_mode,
			"shadow_enabled": light.shadow_enabled, "energy": light.light_energy, "range_m": light.omni_range})
	_check(shadow_count == int(layout.lighting.shadow_lights), "authored number of shadow-casting lights")
	if not probe_only:
		for frame in 120:
			await process_frame
		await _image("opening")
		# Freeze the production cast and camera so the comparisons change shadow casting alone.
		campaign.process_mode = Node.PROCESS_MODE_DISABLED
		campaign.hud.hide()
		var camera := Camera3D.new()
		root.add_child(camera)
		var view: Dictionary = layout.review_views.overview
		camera.position = Presentation.vector(view.from)
		camera.look_at(Presentation.vector(view.to))
		camera.current = true
		var baseline: Image = await _image("shadows")
		var control: Image = await _image("")
		var drift := _brighter_pixels(baseline, control)
		report["control_brighter_pixels"] = drift
		var cast := _casters(campaign._crew)
		var furniture: Array[GeometryInstance3D] = []
		for spec in layout.props:
			var node := campaign._room.visual_root.get_node_or_null(String(spec.id))
			if node != null:
				furniture.append_array(_casters(node))
		for group in [{"id": "character", "meshes": cast}, {"id": "furniture", "meshes": furniture}]:
			var saved: Array[int] = []
			for mesh in group.meshes:
				saved.append(mesh.cast_shadow)
				mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var without: Image = await _image(group.id + "_shadows_off")
			var changed := _brighter_pixels(baseline, without)
			report[group.id] = {"caster_count": saved.size(), "brighter_pixels": changed}
			_check(not saved.is_empty(), group.id + " has visible shadow casters")
			_check(changed > maxi(32, drift * 2), group.id + " shadows darken rendered pixels above frozen-frame noise")
			for index in saved.size():
				group.meshes[index].cast_shadow = saved[index]
			await _image("")
		camera.free()
	_finish()

func _casters(node: Node) -> Array[GeometryInstance3D]:
	var result: Array[GeometryInstance3D] = []
	var candidates := node.find_children("*", "GeometryInstance3D", true, false)
	if node is GeometryInstance3D:
		candidates.append(node)
	for candidate in candidates:
		if candidate.is_visible_in_tree() and candidate.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			result.append(candidate)
	return result

func _image(label: String) -> Image:
	for frame in 16:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_check(image != null and not image.is_empty(), "rendered image available")
	if not label.is_empty():
		_check(image.save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/M1-76_%s_%s.png" % [renderer, label])) == OK, "save " + label)
	return image

func _brighter_pixels(before: Image, after: Image) -> int:
	var count := 0
	# Two 8-bit levels reject quantisation noise; sample every other pixel in the room's lower half.
	for y in range(before.get_height() / 2, before.get_height(), 2):
		for x in range(0, before.get_width(), 2):
			if after.get_pixel(x, y).get_luminance() - before.get_pixel(x, y).get_luminance() > 2.0 / 255.0:
				count += 1
	return count

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL " + message)

func _finish() -> void:
	if is_instance_valid(campaign):
		campaign.free()
	if not storage.directory.is_empty():
		storage.cleanup()
	report["checks"] = checks
	report["failures"] = failures
	report["capture_finished_at_utc"] = Time.get_datetime_string_from_system(true) + "Z"
	var file := FileAccess.open("res://../production/qa/evidence/M1-76_%s_%s.json" % [renderer, "probe" if report.get("rendered", false) else "headless"], FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "\t") + "\n")
		file.close()
	else:
		_check(false, "write probe report")
	print("M1-76 %s RESULT: %s (%d checks, %d failures)" % ["CAPTURE" if report.get("rendered", false) else "CONFIG", "PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)
