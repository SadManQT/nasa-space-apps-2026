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
	_check(trainer.region != null and trainer.region.active_sector == "aurora_ridge", "MoonTrainer loads real MoonRegion LOLA terrain")
	_check(MoonTrainerScript.SORTIES.size() == 5, "five free sorties cover walking, scanner, carrying, markers and rover")
	_check_no_spoilers(trainer, "catalog")
	await _save_shot("M3-67_catalog.png")

	# Low-gravity science explainer (§7.1)
	_check(trainer.watch_explainer("sci_low_gravity"), "Moon trainer plays the sci_low_gravity science explainer (§7.1)")
	await process_frame
	await process_frame
	await _save_shot("M3-67_low_gravity_explainer.png")
	trainer.panels.hint_player.close()
	await process_frame

	# Sortie 1: Walking & suit budget
	_check(trainer.start_sortie("sortie_walk"), "Sortie 1 (walking & suit budget) starts")
	_check(trainer.visor_hud.visible, "EVA visor HUD visible during sortie")
	trainer.set_assist_mode("Story")
	_check(trainer.eva_suit.assist_mode == "Story", "assist mode switches to Story")
	trainer.set_assist_mode("Cadet")
	var walk_report := trainer.complete_sortie()
	_check(String(walk_report.get("grade", "")) == "Distinction", "Sortie 1 produces a distinction report card")

	# Sortie 2: Scanner pulse
	_check(trainer.start_sortie("sortie_scanner"), "Sortie 2 (scanner pulse) starts")
	var scan_btn := trainer.find_child("PulseScannerAction", true, false) as Button
	_check(scan_btn != null, "Sortie 2 exposes PulseScannerAction")
	scan_btn.pressed.emit()
	_check(trainer.eva_suit.scanner_pulse_active and not trainer.eva_suit.last_scan_samples.is_empty(), "scanner pulse populates numbered slope bands 1-4 and terrain features")
	trainer.complete_sortie()

	# Sortie 3: Carrying payloads
	_check(trainer.start_sortie("sortie_carry"), "Sortie 3 (carrying payloads) starts")
	var carry_btn := trainer.find_child("DeliverPayloadAction", true, false) as Button
	_check(carry_btn != null, "Sortie 3 exposes DeliverPayloadAction")
	carry_btn.pressed.emit()
	_check(trainer._payload_delivered, "payload delivered intact after Careful slope balance")
	trainer.complete_sortie()

	# Sortie 4: Survey markers & fixed lines
	_check(trainer.start_sortie("sortie_markers"), "Sortie 4 (survey markers & fixed lines) starts")
	var map_btn := trainer.find_child("OpenCoverageMapAction", true, false) as Button
	_check(map_btn != null, "Sortie 4 exposes OpenCoverageMapAction")
	map_btn.pressed.emit()
	_check(trainer.coverage_map.visible and trainer.network.ch04_beacon_layer().size() == 3, "survey markers and fixed line appear on Coverage Map")
	trainer.coverage_map.hide()
	trainer.complete_sortie()

	# Sortie 5: Rover & Route Planner
	_check(trainer.start_sortie("sortie_rover"), "Sortie 5 (rover & route planner) starts on cold_trap sector")
	_check(trainer.region.active_sector == "cold_trap" and trainer.rover.aboard, "Sortie 5 switches MoonRegion to cold_trap and boards rover")
	var planner_btn := trainer.find_child("OpenRoutePlannerAction", true, false) as Button
	_check(planner_btn != null, "Sortie 5 exposes OpenRoutePlannerAction")
	planner_btn.pressed.emit()
	await process_frame
	_check(trainer.route_planner.visible, "RoverRoutePlanner opens in MoonTrainer")
	var eval_b := trainer.route_planner.evaluate_route("B")
	_check(bool(eval_b.get("accepted", false)), "Route B stays inside 15 deg VIPER slope limit and 30 battery reserve")
	await _save_shot("M3-67_rover_sortie.png")
	trainer._on_route_confirmed("B", eval_b)
	var rover_report := trainer.complete_sortie()
	_check(not rover_report.is_empty() and trainer._page == "report", "Sortie 5 completes and displays report card")
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
