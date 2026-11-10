extends SceneTree

## M3-67: Verification suite for Moon Trainer (free training sorties on the real
## LOLA terrain from the title menu and Mission Trainer, with walking, scanner,
## carrying, survey markers, rover driving, low-gravity explainer, report cards,
## and zero story spoilers).

const MainScene = preload("res://scenes/main.tscn")
const MoonTrainerScript = preload("res://scripts/trainer/moon_trainer.gd")
const Save = preload("res://scripts/save/save_service.gd")
const Legacy = preload("res://scripts/save/legacy_save.gd")

var storage = preload("res://tools/support/isolated_storage.gd").new()
var checks := 0
var failures := 0
var canaries: Dictionary = {}
var write_evidence := false

func _init() -> void:
	write_evidence = OS.get_cmdline_user_args().has("--evidence")
	call_deferred("_run")

func _run() -> void:
	# Fast-forward without enlarging the physics step: the real locomotion and rover
	# controllers are tuned for 1/60 s steps, so tick rate scales with time scale.
	Engine.time_scale = 4.0
	Engine.physics_ticks_per_second = 240
	Engine.max_physics_steps_per_frame = 16
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	_check(storage.setup("M3-67"), "isolated storage configured for M3-67")
	_check(storage.prepare_rendering_cache(), "isolated rendering cache prepared")
	for path in [storage.path, storage.path + ".bak", storage.legacy_path, Save.DEFAULT_PATH, Save.DEFAULT_PATH + ".bak", Legacy.SAVE_PATH]:
		_write(path, "campaign canary " + path)
		canaries[path] = FileAccess.get_file_as_bytes(path)

	var main := MainScene.instantiate()
	storage.configure(main)
	main.moon_trainer_results_path = storage.directory.path_join("moon_results.json")
	root.add_child(main)
	while not main.title_ready:
		await process_frame

	var menu := main.get_node("TitleLayer/MainMenu") as MainMenu
	var moon_btn := menu.find_child("MoonTrainerEntry", true, false) as Button
	_check(moon_btn != null, "title menu exposes MoonTrainerEntry button")
	moon_btn.pressed.emit()
	await process_frame
	await process_frame

	var trainer: MoonTrainer = main.get("_moon_trainer")
	_check(trainer != null and trainer is MoonTrainer, "clicking MoonTrainerEntry opens MoonTrainer on real terrain")
	while not trainer.field_ready:
		await process_frame
	_check(trainer.region != null and trainer.region.active_sector == "aurora_ridge", "MoonTrainer loads real MoonRegion LOLA terrain")
	_check(MoonTrainerScript.SORTIES.size() == 5, "five free sorties cover walking, scanner, carrying, markers and rover")
	_check(trainer.get("player") is PlayerController, "Moon Trainer has a real controllable astronaut in its terrain viewport")
	var vehicle = trainer.get("vehicle")
	_check(vehicle is CharacterBody3D, "Moon Trainer has a physical rover body instead of model-only driving")
	trainer.start_sortie("sortie_carry")
	while not trainer.field_ready:
		await process_frame
	_check(trainer.complete_sortie().is_empty() and not trainer.results.has("sortie_carry"), "Unperformed field actions cannot produce a completed report card")
	_check_no_spoilers(trainer, "catalog")
	await _save_shot("M3-67_catalog.png")

	# Low-gravity science explainer (§7.1)
	_check(trainer.watch_explainer("sci_low_gravity"), "Moon trainer plays the sci_low_gravity science explainer (§7.1)")
	await process_frame
	await process_frame
	await _save_shot("M3-67_low_gravity_explainer.png")
	trainer.panels.hint_player.close()
	await process_frame

	# The existing player actually walks the real terrain and returns before grading.
	_check(trainer.start_sortie("sortie_walk"), "Sortie 1 starts")
	await _ready_field(trainer)
	trainer.enter_field()
	var walking_start := trainer.player.global_position
	await _walk_to(trainer, trainer.checkpoint_position)
	_check(trainer.player.global_position.distance_to(walking_start) > 20.0, "WASD moves the actual astronaut across real terrain")
	await _walk_to(trainer, trainer.start_position)
	trainer.eva_suit.oxygen = 10.0
	trainer.eva_suit.payload_scuffs = 1
	trainer.eva_suit.slip_count = 1
	var walk_report := trainer.complete_sortie()
	_check(not walk_report.is_empty() and int(walk_report.get("reserve_score", 100)) == 50 and int(walk_report.get("care_score", 100)) == 85, "Report preserves actual low reserve and slip/scuff penalties")

	_check(trainer.start_sortie("sortie_scanner"), "Scanner sortie starts")
	await _ready_field(trainer)
	trainer.enter_field()
	for fraction in [0.0, 0.5, 1.0]:
		await _walk_to(trainer, trainer.start_position.lerp(trainer.checkpoint_position, fraction))
		trainer._perform_scanner_pulse()
	_check(trainer._scanner_pulses == 3, "Three scanner readings come from three actual field positions")
	var real_samples := true
	for sample in trainer.eva_suit.last_scan_samples:
		real_samples = real_samples and is_equal_approx(sample.world.y, trainer.region.stream.field.height_at(sample.world.x, sample.world.z))
	_check(real_samples and not trainer.eva_suit.last_scan_samples.is_empty(), "Every scanner sample height equals the displayed LOLA heightfield")
	trainer._perform_scanner_pulse()
	_check(trainer._scanner_pulses == 3, "Repeated pulses in one position do not invent distinct readings")
	await _walk_to(trainer, trainer.start_position)
	_check(not trainer.complete_sortie().is_empty(), "Actual scanner circuit completes")

	_check(trainer.start_sortie("sortie_carry"), "Carry sortie starts")
	await _ready_field(trainer)
	trainer.enter_field()
	_press_key(trainer, KEY_E)
	_check(trainer.payload_inventory.personal_mass() == 6.5, "E picks up the real instrument case at the start")
	await _walk_to(trainer, trainer.checkpoint_position)
	_press_key(trainer, KEY_E)
	_check(trainer._payload_delivered, "E delivers the carried case only at its actual destination")
	await _walk_to(trainer, trainer.start_position)
	_check(not trainer.complete_sortie().is_empty(), "Physical cargo delivery and return complete the sortie")

	_check(trainer.start_sortie("sortie_markers"), "Marker sortie starts")
	await _ready_field(trainer)
	trainer.enter_field()
	_press_key(trainer, KEY_E)
	for site in trainer._marker_sites:
		await _walk_to(trainer, site)
		_press_key(trainer, KEY_M)
	await _walk_to(trainer, trainer.checkpoint_position)
	_press_key(trainer, KEY_M)
	trainer._perform_marker_and_map()
	_check(trainer.coverage_map.visible and trainer.network.all_placed().size() == 4 and trainer.payload_inventory.personal_mass() == 0.0, "Three markers and a fixed line consume the carried kit at real survey sites")
	trainer.coverage_map.hide()
	await _walk_to(trainer, trainer.start_position)
	_check(not trainer.complete_sortie().is_empty(), "Actual marker placement and return complete the sortie")

	_check(trainer.start_sortie("sortie_rover"), "Rover sortie starts")
	await _ready_field(trainer)
	_check(not trainer.rover.aboard, "A rover sortie begins on foot rather than silently boarding")
	trainer._open_rover_planner()
	var estimate := trainer.route_planner.confirm_selected_route()
	_check(bool(estimate.get("accepted", false)), "The canonical safe route confirms before boarding")
	await _save_shot("M3-67_rover_sortie.png")
	trainer.enter_field()
	_press_key(trainer, KEY_E)
	_check(trainer.rover.aboard and trainer.vehicle.driver == trainer.player, "E boards the physical rover beside the astronaut")
	var first_camera: Camera3D = trainer.vehicle.active_camera()
	_press_key(trainer, KEY_V)
	_check(trainer.vehicle.active_camera() != first_camera and trainer.vehicle.active_camera().current, "V switches the actual active cab/chase cameras")
	_press_key(trainer, KEY_L)
	var rover_start := trainer.vehicle.global_position
	await _drive_to(trainer, trainer.checkpoint_position)
	_check(trainer.vehicle.global_position.distance_to(rover_start) > 20.0 and trainer.rover.distance_driven_m > 20.0, "Driving inputs move the real vehicle and consume distance-based energy")
	await _drive_to(trainer, trainer.start_position)
	_press_key(trainer, KEY_E)
	_check(not trainer.rover.aboard and trainer.player.controlled, "E exits the stopped physical rover safely")
	var rover_report := trainer.complete_sortie()
	_check(not rover_report.is_empty() and trainer._page == "report", "The performed rover circuit produces its report")
	_check_no_spoilers(trainer, "report card")
	await process_frame
	await _save_shot("M3-67_report_card.png")

	# Verify separate persistence and untouched campaign save canaries
	_check(FileAccess.file_exists(main.moon_trainer_results_path), "Moon Trainer results saved to separate file")
	for path in canaries:
		_check(FileAccess.get_file_as_bytes(path) == canaries[path], "campaign save canary untouched: " + path.get_file())

	trainer.exit_requested.emit()
	await process_frame
	_check(menu.visible and root.gui_get_focus_owner() == moon_btn, "exiting MoonTrainer restores focus to MoonTrainerEntry on title")

	for path in canaries:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(main.moon_trainer_results_path)
	main.free()
	await process_frame
	storage.cleanup()
	print("MOON TRAINER RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _ready_field(trainer: MoonTrainer) -> void:
	while not trainer.field_ready:
		await process_frame
	await physics_frame

func _press_key(trainer: MoonTrainer, key: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = true
	trainer._unhandled_input(event)

func _walk_to(trainer: MoonTrainer, target: Vector3) -> void:
	Input.action_press("run")
	for frame in range(9000):
		var direction := target - trainer.player.global_position
		if Vector2(direction.x, direction.z).length() <= 1.5:
			break
		trainer.player.follow_camera.yaw = atan2(-direction.x, -direction.z)
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	Input.action_release("run")
	await physics_frame
	_check(MoonTrainer._distance_to(trainer.player.global_position, target) <= 3.0, "Astronaut reaches the marked field point using movement inputs")

func _drive_to(trainer: MoonTrainer, target: Vector3) -> void:
	for frame in range(14000):
		var direction := target - trainer.vehicle.global_position
		var distance := Vector2(direction.x, direction.z).length()
		if distance <= 2.0 and trainer.rover.speed_m_s < 0.15:
			break
		var desired := atan2(-direction.x, -direction.z)
		var turn := wrapf(desired - trainer.vehicle.rotation.y, -PI, PI)
		Input.action_release("move_left")
		Input.action_release("move_right")
		if absf(turn) > 0.05:
			Input.action_press("move_left" if turn > 0 else "move_right", minf(1.0, absf(turn)))
		if distance > maxf(2.0, trainer.rover.speed_m_s * trainer.rover.speed_m_s / (2.0 * 0.32 * 1.62) + 1.0):
			Input.action_press("move_forward", minf(1.0, distance / 15.0))
		else:
			Input.action_release("move_forward")
		await physics_frame
	for action in ["move_forward", "move_left", "move_right"]:
		Input.action_release(action)
	await physics_frame
	_check(MoonTrainer._distance_to(trainer.vehicle.global_position, target) <= 4.0, "Physical rover reaches the course point using throttle and steering")

func _check_no_spoilers(node: Node, context: String) -> void:
	var labels := node.find_children("*", "Label", true, false)
	for lbl in labels:
		var t := (lbl as Label).text
		_check(not t.contains("Noor") and not t.contains("Rahman"), context + " contains no story spoilers: " + t.substr(0, 32))

func _save_shot(filename: String) -> void:
	if not write_evidence:
		return
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if img != null:
		var out_path := ProjectSettings.globalize_path("res://../production/qa/evidence/" + filename)
		img.save_png(out_path)

func _write(path: String, value: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(value)
		file.close()

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)
