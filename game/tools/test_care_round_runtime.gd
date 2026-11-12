## M1-49: Care Round runtime wiring (doc 24 §7.2). The panel is presentation
## only; this suite drives the real CareRoundPanel through CareRoundRuntime
## and asserts the director commits, the dated photo ledger, the step order,
## the duplicate-date refusal, save/load of the ledger, and the Chapter 1
## route seams (S02 lamp cue, S04/S05 visit spec, S12 mugs moment).
## Capture here is a test fixture (a real saved PNG, the same pattern as
## test_care_round_panel.gd); the production capture is
## CareRoundRuntime.make_viewport_capture, a real rendered frame.
##   Godot --headless --path game --script res://tools/test_care_round_runtime.gd
extends SceneTree

const Director = preload("res://scripts/core/campaign_director.gd")
const Runtime = preload("res://scripts/campaign/care_round_runtime.gd")
const Route = preload("res://scripts/missions/chapter1_route.gd")
const PanelScript = preload("res://scripts/ui/care_round_panel.gd")
const Saves = preload("res://scripts/save/save_service.gd")

const READINGS := {"ALO-01": {"moisture": 52.5, "temperature": 21.0}, "TARA-01": {"moisture": 48.0, "temperature": 22.0}}

var checks := 0
var failures := 0
var director: RefCounted
var runtime: RefCounted
var panel: CareRoundPanel
var save_path := ""
var retry_path := ""

func _init() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL ", message)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	save_path = OS.get_temp_dir().path_join("lla-care-round-%d.json" % OS.get_process_id())
	director = Director.new()
	director.new_campaign()
	runtime = Runtime.new(director)
	panel = PanelScript.new()
	root.add_child(panel)
	await _test_view_builds_from_snapshot()
	await _test_full_loop_two_dates()
	await _test_duplicate_photo_refused()
	await _test_order_enforced()
	await _test_save_round_trip()
	await _test_route_seams()
	await _test_viewport_capture_never_fabricates()
	_cleanup()
	print("CARE ROUND RUNTIME RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _move_to(scene_id: String, mission_id: String, completed: Array) -> void:
	var next: Dictionary = director.snapshot()
	next["scene_id"] = scene_id
	next["mission_id"] = mission_id
	next["completed_scene_ids"] = completed.duplicate()
	var restored: Dictionary = director.restore_snapshot(next)
	_check(bool(restored.get("accepted", false)), "director moves to " + scene_id + ": " + String(restored.get("reason", "")))

func _test_view_builds_from_snapshot() -> void:
	_move_to("EX-CH01-S04", "EX-M0102", ["EX-CH01-S01", "EX-CH01-S02", "EX-CH01-S03"])
	var snapshot: Dictionary = director.snapshot()
	var built: Dictionary = Runtime.build_view(snapshot, "EX-CH01-S04", "2046-04-11", READINGS, {}, Callable())
	_check(bool(built.get("accepted", false)), "S04 builds a Care Round view")
	var view: Dictionary = built.get("view", {})
	_check(view.get("plants", []).size() == 2, "S04 view visits both plants")
	_check(String(view["plants"][0].get("stage", "")) == "seed" and String(view["plants"][1].get("stage", "")) == "seed", "11 Apr plants are seed, as planted")
	_check(view["plants"][0].get("moisture") == 52.5 and view["plants"][1].get("temperature") == 22.0, "calibrated moisture and temperature sit side by side")
	_check(view["allowed_actions"]["ALO-01"] == ["observe", "measure", "photograph", "care", "record"] and view["allowed_actions"]["TARA-01"] == ["observe", "measure", "photograph", "care", "record"], "both plants get the full loop")
	_check(String(view["plants"][0].get("current_photo_path", "")) == "" and String(view["plants"][0].get("previous_photo_path", "")) == "", "no photos yet, so no ghost")
	var no_round: Dictionary = Runtime.build_view(snapshot, "EX-CH01-S03", "2046-04-11", READINGS, {}, Callable())
	_check(not bool(no_round.get("accepted", false)), "S03 has no Care Round")
	var partial: Dictionary = Runtime.build_view(snapshot, "EX-CH01-S04", "2046-04-11", {"ALO-01": READINGS["ALO-01"]}, {}, Callable())
	_check(bool(partial.get("accepted", false)) and partial["view"]["allowed_actions"]["TARA-01"] == ["observe"], "a plant without readings is observe-only")

func _fixture_capture(request: Dictionary) -> Dictionary:
	var path := Runtime.photo_path(String(request.get("individual_id", "")), String(request.get("date", "")))
	return _save_fixture_image(path)

func _retry_capture(request: Dictionary) -> Dictionary:
	retry_path = "user://growth_record/%s_%s.retry.png" % [String(request.get("individual_id", "")), String(request.get("date", "")).replace("-", "")]
	return _save_fixture_image(retry_path)

func _save_fixture_image(path: String) -> Dictionary:
	var image := Image.create(48, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.35, 0.55, 0.25))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://growth_record"))
	if image.save_png(ProjectSettings.globalize_path(path)) != OK:
		return {"accepted": false, "message": "Fixture capture could not be saved."}
	return {"accepted": true, "photo_path": path}

func _test_full_loop_two_dates() -> void:
	_move_to("EX-CH01-S05", "EX-M0102", ["EX-CH01-S01", "EX-CH01-S02", "EX-CH01-S03", "EX-CH01-S04"])
	for date in ["2046-04-12", "2046-04-18"]:
		var opened: Dictionary = runtime.open_round(panel, "EX-CH01-S05", date, READINGS, {}, _fixture_capture, false)
		_check(bool(opened.get("accepted", false)), date + " Care Round opens: " + String(opened.get("reason", "")))
		for individual_id in ["ALO-01", "TARA-01"]:
			_check(await panel.request_action(individual_id, "observe") and bool(runtime.last_result().get("accepted", false)), date + " " + individual_id + " observes")
			_check(await panel.request_action(individual_id, "measure") and bool(runtime.last_result().get("accepted", false)), date + " " + individual_id + " measures")
			_check(String(runtime.last_result().get("message", "")).contains("moisture"), date + " " + individual_id + " measure reports both readings")
			_check(await panel.request_action(individual_id, "photograph") and bool(runtime.last_result().get("accepted", false)), date + " " + individual_id + " photographs: " + String(runtime.last_result().get("message", "")))
			_check(Runtime.has_photo(director.snapshot(), individual_id, date), date + " " + individual_id + " photo is in the ledger")
			var options: OptionButton = panel.find_child("CareOptions_" + individual_id, true, false) as OptionButton
			options.select(0)
			_check(await panel.request_action(individual_id, "care") and bool(runtime.last_result().get("accepted", false)), date + " " + individual_id + " does its care task")
			_check(await panel.request_action(individual_id, "record") and bool(runtime.last_result().get("accepted", false)), date + " " + individual_id + " records the dated entry")
		runtime.close_round()
		_check(not panel.visible, date + " round closes")
	var summary: Dictionary = Runtime.ledger_summary(director.snapshot())
	_check(summary["ALO-01"] == ["2046-04-12", "2046-04-18"] and summary["TARA-01"] == ["2046-04-12", "2046-04-18"], "two photos on two dates for each plant: " + str(summary))
	_check(Runtime.both_plants_photographed_before(director.snapshot(), "2046-04-25"), "Tara and Alo both have entries before 25 Apr")
	_check(not Runtime.both_plants_photographed_before(director.snapshot(), "2046-04-12"), "nothing is counted before the first photo date")
	load("res://scenes/ui/chapter1_campaign_hud.tscn")  # the scene first: the HUD script preloads scenes that point back at it
	var hud_script: GDScript = load("res://scripts/ui/chapter1_campaign_hud.gd")
	var card: Control = hud_script.build_photo_card(director.snapshot(), "25 April 2046", "2046-04-25", 720.0)
	_check(card != null and card.find_child("Photo_ALO-01", true, false) is TextureRect and card.find_child("Photo_TARA-01", true, false) is TextureRect, "25 Apr date card shows the player's latest Alo and Tara photos (doc 24 §2.9)")
	if card != null:
		card.free()
	_check(hud_script.build_photo_card(director.snapshot(), "", "2046-04-12", 720.0) == null, "no date card before the first photo")

func _test_duplicate_photo_refused() -> void:
	var before: Dictionary = director.snapshot()
	var before_count := Runtime.photo_entries(before).size()
	var opened: Dictionary = runtime.open_round(panel, "EX-CH01-S05", "2046-04-12", READINGS, {}, _retry_capture, false)
	_check(bool(opened.get("accepted", false)), "12 Apr round reopens for the duplicate check")
	_check(await panel.request_action("ALO-01", "observe"), "duplicate check observes first")
	_check(await panel.request_action("ALO-01", "measure"), "duplicate check measures first")
	var emitted := await panel.request_action("ALO-01", "photograph")
	_check(emitted, "the duplicate capture still reaches the runtime")
	var result: Dictionary = runtime.last_result()
	_check(not bool(result.get("accepted", false)) and String(result.get("code", "")) == "duplicate_date", "second photo on the same date is refused with duplicate_date: " + str(result))
	_check(String(result.get("message", "")).contains("already"), "duplicate refusal is in player words")
	_check(Runtime.photo_entries(director.snapshot()).size() == before_count, "no second receipt is written")
	_check(not FileAccess.file_exists(retry_path), "the unreferenced retry capture is removed")
	runtime.close_round()

func _test_order_enforced() -> void:
	var fresh: RefCounted = Director.new()
	fresh.new_campaign()
	var fresh_runtime: RefCounted = Runtime.new(fresh)
	_move_director_to(fresh, "EX-CH01-S05", "EX-M0102", ["EX-CH01-S01", "EX-CH01-S02", "EX-CH01-S03", "EX-CH01-S04"])
	# A different visit date from the main loop, so this test's fixture files
	# never touch the 12/18 Apr Growth Record photos.
	var opened: Dictionary = fresh_runtime.open_round(panel, "EX-CH01-S05", "2046-04-13", READINGS, {}, _fixture_capture, false)
	_check(bool(opened.get("accepted", false)), "fresh 13 Apr round opens for the order check")
	var emitted := await panel.request_action("ALO-01", "photograph")
	_check(emitted, "a photograph before measuring still reaches the runtime")
	var result: Dictionary = fresh_runtime.last_result()
	_check(not bool(result.get("accepted", false)) and String(result.get("code", "")) == "order", "photograph before measure is refused for order: " + str(result))
	_check(not Runtime.has_photo(fresh.snapshot(), "ALO-01", "2046-04-13"), "no photo is recorded out of order")
	_check(not FileAccess.file_exists(Runtime.photo_path("ALO-01", "2046-04-13")), "the out-of-order capture file is removed")
	_check(await panel.request_action("ALO-01", "observe") and await panel.request_action("ALO-01", "measure"), "observe and measure then pass")
	emitted = await panel.request_action("ALO-01", "record")
	_check(emitted, "a record before the care task still reaches the runtime")
	result = fresh_runtime.last_result()
	_check(not bool(result.get("accepted", false)) and String(result.get("code", "")) == "order", "record before photograph and care is refused for order")
	fresh_runtime.close_round()

func _move_director_to(target: RefCounted, scene_id: String, mission_id: String, completed: Array) -> void:
	var next: Dictionary = target.snapshot()
	next["scene_id"] = scene_id
	next["mission_id"] = mission_id
	next["completed_scene_ids"] = completed.duplicate()
	var restored: Dictionary = target.restore_snapshot(next)
	_check(bool(restored.get("accepted", false)), "fresh director moves to " + scene_id)

func _test_save_round_trip() -> void:
	var snapshot: Dictionary = director.snapshot()
	_check(Saves.new().save(snapshot, save_path).accepted, "Care Round snapshot saves")
	var loaded: Dictionary = Saves.new().load(save_path)
	_check(bool(loaded.get("accepted", false)), "Care Round snapshot loads")
	var restored: Dictionary = loaded.get("snapshot", {})
	_check(Runtime.ledger_summary(restored) == Runtime.ledger_summary(snapshot), "the photo ledger survives save and load")
	_check(Runtime.both_plants_photographed_before(restored, "2046-04-25"), "loaded ledger still has both plants before 25 Apr")
	Saves.new().clear(save_path)

func _test_route_seams() -> void:
	var route: RefCounted = Route.new(director)
	_check(route.current_scene_id() == "EX-CH01-S01", "route starts in S01")
	_check(route.care_round_visit("EX-CH01-S04").is_empty(), "no visit spec away from the visit scene")
	_check(route.request_inventory_lamp_blink().is_empty(), "no lamp cue outside S02")
	_check(route.mugs_named_moment_command().is_empty(), "no mugs moment outside S12")
	route.start_at("EX-CH01-S02")
	_check(route.request_inventory_lamp_blink().is_empty(), "no lamp cue before the roll call")
	route._mark_flag("roll_call_complete")
	var blink: Dictionary = route.request_inventory_lamp_blink()
	_check(blink.get("cue_id", "") == "inventory_lamp" and blink.get("sfx_id", "") == "SFX_INVENTORY_LAMP_TICK" and blink.get("scene_id", "") == "EX-CH01-S02", "the roll call returns the lamp cue with its tick: " + str(blink))
	_check(route.request_inventory_lamp_blink().is_empty(), "the lamp cue is requested only once")
	route.start_at("EX-CH01-S04")
	var visit: Dictionary = route.care_round_visit("EX-CH01-S04")
	_check(bool(visit.get("accepted", false)) and visit.get("dates", []) == ["2046-04-11"], "S04 visit spec carries its date")
	_check(visit.get("care_round", {}).has("ALO-01") and visit.get("care_round", {}).has("TARA-01"), "S04 visit spec carries both plants")
	_check((visit.get("moisture", {}) as Dictionary).has("ALO-01") and (visit.get("temperature", {}) as Dictionary).is_empty(), "visit moisture comes from the P-01 probe; temperature is left to the live chamber reading, never invented")
	route.start_at("EX-CH01-S05")
	_check(route.care_round_photographed("EX-CH01-S05", "2046-04-12"), "route sees the 12 Apr photos for both plants")
	_check(route.care_round_photographed("EX-CH01-S05", "2046-04-18"), "route sees the 18 Apr photos for both plants")
	_check(not route.care_round_photographed("EX-CH01-S05", "2046-04-13"), "route sees no photo on a date with none")
	route.start_at("EX-CH01-S12")
	var moment: Dictionary = route.mugs_named_moment_command()
	_check(String(moment.get("verb", "")) == "record_moment" and String(moment.get("payload", {}).get("moment_id", "")) == "CH01-MUGS-NAMED", "S12 builds the mugs moment command")
	_move_to("EX-CH01-S12", "EX-M0104", ["EX-CH01-S01", "EX-CH01-S02", "EX-CH01-S03", "EX-CH01-S04", "EX-CH01-S05", "EX-CH01-S06", "EX-CH01-S07", "EX-CH01-S08", "EX-CH01-S09", "EX-CH01-S10", "EX-CH01-S11"])
	var recorded: Dictionary = director.commit(moment)
	_check(bool(recorded.get("accepted", false)), "the mugs moment records: " + String(recorded.get("reason", "")))
	_check(director.snapshot().get("story_log", {}).get("moments", []).has("CH01-MUGS-NAMED"), "CH01-MUGS-NAMED is in story_log.moments")
	var again: Dictionary = director.commit(moment)
	_check(bool(again.get("accepted", false)) and bool(again.get("duplicate", false)), "repeating the moment command adds nothing")

func _test_viewport_capture_never_fabricates() -> void:
	var capture: Callable = Runtime.make_viewport_capture(root, null)
	var fresh_id := "ALO-01"
	var fresh_date := "2046-04-20"
	var path := Runtime.photo_path(fresh_id, fresh_date)
	DirAccess.remove_absolute(path)
	var result: Dictionary = await capture.call({"individual_id": fresh_id, "date": fresh_date, "scene_id": "EX-CH01-S05", "alignment": {"x": 0.0, "y": 0.0}})
	_check(result.has("accepted"), "viewport capture answers with a result dictionary")
	if DisplayServer.get_name() == "headless":
		_check(not result.accepted and String(result.get("message", "")).contains("rendered frame"), "headless capture refuses before accessing an unavailable render texture")
	if bool(result.get("accepted", false)):
		_check(FileAccess.file_exists(String(result.get("photo_path", ""))), "an accepted viewport capture saved a real file")
		DirAccess.remove_absolute(String(result.get("photo_path", "")))
	else:
		_check(not FileAccess.file_exists(path), "a refused viewport capture leaves no invented file")

func _cleanup() -> void:
	if is_instance_valid(panel):
		panel.free()
	for entry in Runtime.photo_entries(director.snapshot()):
		DirAccess.remove_absolute(String(entry.get("path", "")))
	if not retry_path.is_empty():
		DirAccess.remove_absolute(retry_path)
