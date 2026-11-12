extends SceneTree

const Scene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const Gates = preload("res://scripts/missions/chapter1_gate_catalog.gd")
var storage = preload("res://tools/support/isolated_storage.gd").new()
var campaign: Chapter1Campaign
var checks := 0
var failures := 0

func _init() -> void:
	CampaignCutscenePlayer.autoplay = false
	storage.setup("opening_blockers")
	if OS.get_cmdline_user_args().has("--capture"):
		storage.prepare_rendering_cache()
	call_deferred("_run")

func _run() -> void:
	campaign = Scene.instantiate()
	storage.configure(campaign)
	root.add_child(campaign)
	await process_frame
	campaign.hud.panels.hint_player.seen_path = storage.directory.path_join("how-to.cfg")
	await _doors()
	await _probe()
	campaign.free()
	await process_frame
	storage.cleanup()
	print("OPENING BLOCKERS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _doors() -> void:
	var player := campaign._player
	player.follow_camera.yaw = 0.0
	player.follow_camera.recenter_delay = INF
	player.global_position = Vector3(9.5, 0.1, 1.5)
	player.face_towards(Vector3(15, 0, 1.5))
	player.velocity = Vector3.ZERO
	player.reset_placement()
	await _frames(12)
	Input.action_press("move_right")
	await _frames(150)
	Input.action_release("move_right")
	await _frames(10)
	print("DOOR ENTER ", player.global_position, " mode=", player.process_mode, " paused=", campaign._ui_paused, " status=", campaign.hud._status.text)
	_check(campaign.hud._status.text.begins_with("This passage leads"), "physical passage entry displays guidance")
	_check(not campaign._ui_paused and player.process_mode != Node.PROCESS_MODE_DISABLED, "passage guidance does not pause the actual player")
	var entered := player.global_position
	Input.action_press("move_left")
	for i in 150:
		await physics_frame
		if i % 30 == 0:
			print("ESCAPE ", i, " pos=", player.global_position, " yaw=", player._yaw, " camera=", player.follow_camera.yaw, " speed=", player.horizontal_speed, " desired=", player.desired_speed, " velocity=", player.velocity, " input=", Input.get_vector("move_left", "move_right", "move_forward", "move_back"))
			print("LOCK pivot=", player._pivoting, " action=", player.animation.action_name, " locked=", player.animation.movement_locked, " slope=", rad_to_deg(player.get_floor_angle()), " band=", player.eva_suit.current_band.id, " indoor=", player.eva_suit.indoor)
			for j in player.get_slide_collision_count():
				var hit := player.get_slide_collision(j)
				print("HIT ", hit.get_collider().get_path(), " normal=", hit.get_normal())
	Input.action_release("move_left")
	await _frames(10)
	print("DOOR EXIT ", player.global_position, " mode=", player.process_mode, " paused=", campaign._ui_paused)
	_check(player.global_position.x < entered.x - 1.5 and player.global_position.x < 10.0, "player can turn around and walk out of the Safe Room passage")
	await _capture("door_escape")

func _probe() -> void:
	campaign.route.start_at("EX-CH01-S03")
	campaign._sync_route_projection()
	campaign._refresh_world()
	campaign.hud.refresh_scene()
	var point := campaign.physical_target("calibrate_probe").global_position
	campaign._player.global_position = Vector3(point.x, 0.04, point.z + 1.0)
	campaign._player.velocity = Vector3.ZERO
	campaign._player.reset_placement()
	await _frames(8)
	campaign._player.follow_camera.camera.look_at(point)
	_check(String(campaign.nearby_target().get("target_id", "")) == "calibrate_probe", "probe target is reachable in the actual room")
	await _key(KEY_E)
	var activity = campaign.hud.probe_activity
	_check(is_instance_valid(activity) and activity.visible, "real E launches playable probe transfer without a fixture")
	if not is_instance_valid(activity):
		return
	_check(not campaign.hud.p01_panel.is_open(), "calibration choices wait for physical transfer")
	var approach := campaign._player.global_position
	campaign._player.global_position = Vector3(5, 0.04, 4)
	await _key(KEY_E)
	_check(campaign.route.probe_job().state() == "at_rack", "E outside physical reach cannot silently pick up the probe")
	campaign._player.global_position = approach
	await _key(KEY_E)
	_check(campaign.route.probe_job().held() and activity._held.prop != null and not activity._probe.visible, "real E takes one visible probe into the player's hand")
	await _capture("probe_in_hand")
	await _key(KEY_ESCAPE)
	_check(campaign.route.probe_job().state() == "at_rack" and campaign.hud.visible and not campaign._ui_paused, "cancel returns carried probe and restores playable HUD")
	await _key(KEY_E)
	activity = campaign.hud.probe_activity
	_check(is_instance_valid(activity), "real E can retry cancelled transfer")
	if not is_instance_valid(activity):
		return
	await _key(KEY_E)
	var saved: Dictionary = campaign._save_snapshot()
	_check(saved.has("route_runtime") and saved.route_runtime.probe_job.state == "held", "normal campaign save retains mid-carry probe ownership")
	var restored := Chapter1Campaign.restore_session(JSON.parse_string(JSON.stringify(saved)))
	_check(bool(restored.get("accepted", false)) and restored.route.probe_job().held(), "normal Continue reconstruction retains the carried probe")
	await _key(KEY_E)
	_check(campaign.route.probe_job().state() == "at_bench" and activity._probe.visible and activity._held.prop == null, "real E places the probe on the dry-reference cradle")
	await _key(KEY_ESCAPE)
	_check(campaign.route.probe_job().state() == "at_bench" and campaign.hud.visible, "cancelling after placement preserves the probe at the bench")
	await _key(KEY_E)
	_check(is_instance_valid(campaign.hud.probe_activity) and campaign.hud.probe_activity.job.state() == "at_bench", "reopening resumes at the placed probe")
	await _key(KEY_E)
	_check(campaign.route.probe_job().completed() and campaign.hud.p01_panel.is_open(), "real E reads dry zero and returns to calibration choices")
	if campaign.hud.panels.hint_player.is_open():
		campaign.hud.panels.hint_player.close()
	var panel := campaign.hud.p01_panel
	panel.choose("reference", "dry")
	panel.choose("raw_reading", 10)
	panel.choose("calibrated_reading", 0)
	_check(bool(panel.preview().get("accepted", false)), "physical dry reading now permits the original P01 preview")
	_check(bool(panel.request_commit().accepted) and bool(panel.confirm_commit().accepted), "original P01 confirmation commits after physical transfer")
	_check(campaign.route.snapshot().p01.probe_zeroed and campaign.route.snapshot().p01.receipts.size() == 1, "dry zero commits exactly once")
	panel.discard()
	_check(not campaign._ui_paused and campaign._player.process_mode != Node.PROCESS_MODE_DISABLED, "closing calibration restores actual player movement")
	await _calibrate("span_probe", {"reference": "wet", "raw_reading": 110, "calibrated_reading": 100})
	await _calibrate("recheck_probe", {"dry_reading": 0, "wet_reading": 100})
	_check(campaign.route.snapshot().p01.probe_rechecked, "physical opening flow reaches fully verified calibration")
	await _capture("calibration_complete")
	var suit := EvaSuit.new()
	suit.indoor = true
	var before := suit.oxygen
	_check(suit.step(1.0, 1.0, 26.0).speed_scale > 0.0 and suit.oxygen == before, "indoor doorway edge permits retreat without suit drain")
	suit.indoor = false
	_check(suit.step(1.0, 1.0, 26.0).speed_scale == 0.0 and suit.current_band.id == "no_go", "exterior no-go slope still stops movement")

func _calibrate(id: String, choices: Dictionary) -> void:
	await _key(KEY_E)
	if campaign.hud.panels.hint_player.is_open():
		campaign.hud.panels.hint_player.close()
	var panel := campaign.hud.p01_panel
	_check(panel.is_open() and panel._target == id, "real E reaches " + id)
	for field in choices:
		panel.choose(field, choices[field])
	_check(bool(panel.preview().get("accepted", false)), id + " preview accepts canonical references")
	_check(bool(panel.request_commit().accepted) and bool(panel.confirm_commit().accepted), id + " commits through the original panel")
	panel.discard()

func _key(code: int) -> void:
	for down in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = down
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await process_frame
		await _frames(3)

func _capture(label: String) -> void:
	if not OS.get_cmdline_user_args().has("--capture"):
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var dir := "/tmp/atik-opening-native-20261113"
	DirAccess.make_dir_recursive_absolute(dir)
	root.get_texture().get_image().save_png(dir.path_join(label + ".png"))

func _frames(count: int) -> void:
	for i in count:
		await physics_frame

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL ", message)
