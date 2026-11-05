extends SceneTree

## M1-58 production capture. Use -- --probe-only for headless layout probes;
## screenshots are taken only from the on-top, windowed campaign viewport.
const Campaign = preload("res://scenes/campaign/chapter1_campaign.tscn")
const Gates = preload("res://scripts/missions/chapter1_gate_catalog.gd")
var storage = preload("res://tools/support/isolated_storage.gd").new()
var campaign: Chapter1Campaign
var probes: Dictionary = {}
var failures := 0
var probe_only := false

func _init() -> void:
	probe_only = OS.get_cmdline_user_args().has("--probe-only")
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	if not probe_only:
		root.always_on_top = true
		root.grab_focus()
	_expect(storage.setup("M1-58-capture"), "isolated_storage")
	CampaignCutscenePlayer.autoplay = false
	campaign = Campaign.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	root.add_child(campaign)
	campaign.route.mission_table().apply_worked_plan("golden")
	for role_id in ["kai", "amara", "rafi", "mei"]:
		campaign.route.mission_table().share(role_id, 3)
	while campaign.route.current_scene_id() != "EX-CH01-S10":
		var current: String = campaign.route.current_scene_id()
		var ids: Array = ["calibrate_probe", "span_probe", "recheck_probe", "inspect_packet", "compare_atmosphere"] if current == "EX-CH01-S03" else Gates.targets_for_scene(current).map(func(spec): return String(spec.target_id))
		for id in ids:
			campaign.route.perform(id)
		if not bool(campaign.route.advance_scene().get("accepted", false)):
			_expect(false, "reach_alarm_from_" + current)
			_finish()
			return
	campaign._sync_route_projection()
	campaign._refresh_world()
	campaign.hud.refresh_scene()
	campaign.route.perform("confirm_four_sheltered")
	var state := campaign.director.snapshot()
	state.accessibility.timer_free = false
	campaign.director.restore_snapshot(state)
	_expect(campaign.hud.open_mission_table("p02_shift5_alarm"), "open_actual_response_controls")
	await _capture("mission_table_launch")
	var before: Dictionary = campaign.director.snapshot().resources.duplicate(true)
	var activity := _open_activity()
	await _capture("briefing")
	_expect(activity.task.table.alarm_state().state == "idle", "briefing_does_not_start_timer")
	_expect(bool(activity.begin(false).accepted), "manual_carry_starts")
	activity.set_physics_process(false) # Stable scripted frames, independent of render-machine load.
	_expect(activity.task.time_left == 30.0 and not activity._assistance, "manual_30_seconds")
	campaign._player.global_position = Vector3(1.15, 0, -1.4)
	_expect(bool(activity.pickup_bundle(0).accepted), "physical_pickup_in_reach")
	_expect(activity._held.prop != null, "held_prop_attached")
	# Straight behind the cadet the body hides the case; look from the front-right
	# three-quarter (55 degrees off the facing, inside the room) so the HeldProp
	# BOX pose is in frame. The follow camera only re-centres while walking.
	var player := campaign._player
	var camera := player.follow_camera
	camera.yaw = player.visual.global_rotation.y - PI - deg_to_rad(125.0)
	camera.pitch = -0.2
	camera.reset_placement()
	activity._update_camera(1.0)
	await process_frame
	var to_camera: Vector3 = camera.camera.global_position - player.global_position
	to_camera.y = 0.0
	var front: Vector3 = player.visual.global_basis.z
	front.y = 0.0
	_expect(front.normalized().dot(to_camera.normalized()) > 0.25, "carrying_camera_sees_front")
	_expect(camera.camera.is_position_in_frustum(activity._held.prop.global_position), "carrying_case_in_frame")
	await _capture("carrying")
	campaign._player.global_position = Vector3(-1.35, 0, -0.15)
	_expect(bool(activity.place_bundle(0).accepted), "physical_slot_delivery")
	campaign._player.global_position = Vector3(1.75, 0, -1.4)
	activity.pickup_bundle(1)
	campaign._player.global_position = Vector3(-1.35, 0, 0.5)
	activity.place_bundle(1)
	# Back behind the cadet, who faces the bunks: both placed cases and the empty
	# outlined slots must be in frame.
	camera.yaw = player.visual.global_rotation.y - PI
	camera.pitch = -0.12
	camera.reset_placement()
	activity._update_camera(1.0)
	await process_frame
	_expect(camera.camera.is_position_in_frustum(activity._slots[0].global_position) and camera.camera.is_position_in_frustum(activity._slots[1].global_position), "bunk_slots_placed_cases_in_frame")
	await _capture("bunk_slots")
	activity.pause_task()
	await _capture("paused")
	activity.finish_task()
	await _capture("partial_report")
	_expect(activity.task.table.alarm_progress() == 2, "partial_is_two_deliveries")
	activity.return_to_plan()
	await process_frame
	var table := campaign.hud.mission_table
	_expect(int(table.preview().forecast.final_state.K) == 1, "partial_forecast_K1")

	_reset()
	activity = _open_activity()
	activity.begin(false)
	activity.set_physics_process(false)
	activity.task.advance(30.0)
	activity._physics_process(0.0)
	await _capture("empty_report")
	activity.return_to_plan()
	await process_frame
	_expect(int(table.preview().forecast.final_state.K) == 0, "empty_forecast_K0")

	_reset()
	activity = _open_activity()
	activity.begin(true)
	activity.set_physics_process(false)
	await _capture("assisted_select")
	for index in 4:
		activity.pickup_bundle(index)
		activity.place_bundle(index)
	await _capture("full_report")
	_expect(campaign.director.snapshot().resources == before, "no_hidden_resource_cost")
	activity.return_to_plan()
	await process_frame
	table.preview()
	await _capture("full_forecast")
	_expect(int(table.view().gate_preview.final_state.K) == 2, "full_forecast_K2")
	# Keep the proven full result, inspect 150% UI on a new temporary attempt.
	var full_table_snapshot: Dictionary = campaign.route.mission_table().snapshot()
	_reset()
	table._settings.large_text = true
	activity = _open_activity()
	await _capture("large_text_briefing")
	activity.begin(true)
	activity.set_physics_process(false)
	await _capture("large_text_assisted")
	_expect(activity.task.assisted and activity.task.time_left == 0, "assisted_untimed")
	activity.finish_task()
	activity.return_to_plan()
	await process_frame
	campaign.route.mission_table().restore(full_table_snapshot)
	table._settings.large_text = false
	table.refresh_payload_result()
	table.preview()
	table.request_commit()
	table.confirm_commit()
	_expect(int(campaign.director.query().current_shift) == 5 and int(campaign.director.snapshot().resources.K) == 2, "real_shift_commit_K2")
	_expect(bool(campaign.advance_scene().accepted) and campaign.route.current_scene_id() == "EX-CH01-S11", "alarm_to_water_return_join")
	_expect(bool(campaign.route.perform("verify_exposure_order").accepted) and bool(campaign.route.perform("return_water").accepted), "water_return_available")
	_finish()

func _open_activity() -> PayloadStackActivity:
	campaign.hud.mission_table.start_task()
	return campaign.hud.payload_activity

func _reset() -> void:
	campaign.route.mission_table().reset_alarm_task()
	campaign.hud.mission_table.refresh_payload_result()

func _capture(label: String) -> void:
	for frame in 8:
		await process_frame
	var activity := campaign.hud.payload_activity
	if activity != null:
		var viewport := activity._ui.get_viewport_rect()
		var visible_panels: Array[Control] = []
		for panel in activity._ui.get_children():
			if panel is Control and panel.visible:
				_expect(viewport.encloses(panel.get_rect()), label + "_" + String(panel.name) + "_fits")
				if panel.name != "ReadingCard":
					visible_panels.append(panel)
					for control in panel.find_children("*", "Control", true, false):
						# Scrollable assistance deliberately exceeds its visible
						# height; its own viewport is the clipping boundary.
						if panel.name != "AssistedInput":
							_expect(panel.get_global_rect().encloses(control.get_global_rect()), label + "_" + String(panel.name) + "_content_" + str(control.get_index()) + "_fits")
		for i in visible_panels.size():
			for j in range(i + 1, visible_panels.size()):
				_expect(not visible_panels[i].get_rect().intersects(visible_panels[j].get_rect()), label + "_panels_%d_%d_separate" % [i, j])
		if not activity._paused:
			var centre := Rect2(Vector2(viewport.size.x / 3, viewport.size.y / 3), viewport.size / 3)
			for panel in visible_panels:
				if panel.name != "Goal":
					_expect(not panel.get_rect().intersects(centre), label + "_" + String(panel.name) + "_clear_centre")
		for button in activity._ui.find_children("*", "Button", true, false):
			if button.is_visible_in_tree():
				_expect(button.size.y >= 44, label + "_" + String(button.name) + "_target_size")
	if probe_only:
		return
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../production/qa/evidence/M1-58_%s.png" % label)
	_expect(root.get_texture().get_image().save_png(path) == OK, "screenshot_" + label)
	print("M1-58 screenshot: " + path)

func _expect(condition: bool, label: String) -> void:
	probes[label] = condition
	if not condition:
		failures += 1
		push_error("FAIL " + label)

func _finish() -> void:
	if is_instance_valid(campaign):
		campaign.free()
	# Flush queued activity deletion and container layout callbacks before
	# the engine checks resource ownership at shutdown.
	await process_frame
	await process_frame
	storage.cleanup()
	var path := ProjectSettings.globalize_path("res://../production/qa/evidence/M1-58_%s.json" % ("headless_probes" if probe_only else "capture_probes"))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(probes, "  ") + "\n")
	else:
		failures += 1
	print("PAYLOAD CAPTURE RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
