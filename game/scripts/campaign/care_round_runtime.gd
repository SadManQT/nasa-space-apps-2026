extends RefCounted
class_name CareRoundRuntime

## Runtime wiring for the Chapter 1 Care Round (M1-49, doc 24 §7.2).
##
## The CareRoundPanel (M1-83 provider, scripts/ui/care_round_panel.gd) is
## presentation only: it never mutates gameplay. This runtime is its first
## consumer. It builds the panel view from the authoritative snapshot
## (RoomContract.care_round for the visit, PlantService stages as of the visit
## date, caller-supplied calibrated readings), validates every panel request
## (scene, date, individual, step order, daily photo rule) and commits the
## accepted ones through CampaignDirector plant_care commands, so a photo is
## apply_care(plant, "photo", date) and lands in the plant's dated receipts.
##
## Photo ledger: receipts are keyed care@date inside each plant's
## care_receipts (PlantService), so they travel with the snapshot and survive
## save/load with no schema change. The local image for a photo lives at
## photo_path(individual_id, date) under user://growth_record; the ledger
## derives the path from the receipt, so the previous photo's ghost is the
## latest receipt before the visit date. The capture producer (a Callable
## supplied by the scene layer, or make_viewport_capture) saves the real
## rendered frame; this runtime never invents a filename or an image.
##
## Step order within one visit (one plant, one date): observe -> measure ->
## photograph -> care -> record. Measure needs both calibrated readings;
## photograph needs the measure step; care needs the photograph; record needs
## a care or photo receipt for that plant and date. Repeating an earlier step
## is allowed. A second photo on the same date is refused with code
## duplicate_date and the unreferenced capture file is removed.
##
## Readings come from the caller (the P-01 calibrated probe: moisture in the
## 40-60 band, chamber temperature). A plant without finite readings is
## observe-only in the view, exactly like the provider's Tara fixture.

const RoomContract = preload("res://scripts/world/room_contract.gd")
const PlantServiceScript = preload("res://scripts/biology/plant_service.gd")

const PLANT_IDS := ["ALO-01", "TARA-01"]
const PLANT_NAMES := {"ALO-01": "Alo", "TARA-01": "Tara"}
## Doc 24 §7.2 reuse: the round returns in CH02-S05, CH03-S08/S12, CH05-S12,
## CH06-S12, CH07-S10 and CH08-S05 wherever RoomContract carries a visit.
const CARE_SCENES := ["EX-CH01-S04", "EX-CH01-S05", "EX-CH02-S05", "EX-CH03-S08", "EX-CH03-S12", "EX-CH05-S12", "EX-CH06-S12", "EX-CH07-S10", "EX-CH08-S05"]
## Canonical Chapter 1 visit dates (doc 24 §7.2 dated content; the journal's
## growth_photo entries): S04 plants on 11 Apr, S05 care visits 12 Apr
## (cotyledons) and 18 Apr (bud clusters). All before 25 Apr.
const VISIT_DATES := {"EX-CH01-S04": ["2046-04-11"], "EX-CH01-S05": ["2046-04-12", "2046-04-18"]}
const MOISTURE_MIN := 40.0
const MOISTURE_MAX := 60.0
const STEPS := ["observe", "measure", "photograph", "care", "record"]
const PHOTO_DIR := "user://growth_record"
const VISIT_TIME := "06:00 UTC"

var _director: RefCounted
var _panel: CareRoundPanel = null
var _scene_id := ""
var _date := ""
var _view: Dictionary = {}
var _progress: Dictionary = {}
var _measurements: Dictionary = {}
var _last_result: Dictionary = {}
var _open := false

func _init(director: RefCounted) -> void:
	_director = director

## The local file for one dated photo. Derived from the receipt, never stored.
static func photo_file_name(individual_id: String, date: String) -> String:
	return "%s_%s.png" % [individual_id, date.replace("-", "")]

static func photo_path(individual_id: String, date: String) -> String:
	return PHOTO_DIR.path_join(photo_file_name(individual_id, date))

## Dated photo entries for the whole snapshot, oldest first, from the plants'
## care_history (care_id "photo"). Each entry: {individual_id, date,
## scenario_datetime, path}.
static func photo_entries(snapshot: Dictionary) -> Array:
	var entries: Array = []
	for plant in snapshot.get("plants", []):
		if not plant is Dictionary:
			continue
		var individual_id := String(plant.get("individual_id", ""))
		for item in plant.get("care_history", []):
			if item is Dictionary and String(item.get("care_id", "")) == "photo":
				var when := String(item.get("scenario_datetime", ""))
				entries.append({"individual_id": individual_id, "date": when.substr(0, 10), "scenario_datetime": when, "path": photo_path(individual_id, when.substr(0, 10))})
	entries.sort_custom(func(a, b): return String(a.scenario_datetime) < String(b.scenario_datetime) if String(a.scenario_datetime) != String(b.scenario_datetime) else String(a.individual_id) < String(b.individual_id))
	return entries

static func photos_for(snapshot: Dictionary, individual_id: String, date: String = "") -> Array:
	var found: Array = []
	for entry in photo_entries(snapshot):
		if String(entry.get("individual_id", "")) == individual_id and (date.is_empty() or String(entry.get("date", "")) == date):
			found.append(entry)
	return found

static func has_photo(snapshot: Dictionary, individual_id: String, date: String) -> bool:
	return not photos_for(snapshot, individual_id, date).is_empty()

## The latest photo of one plant strictly before a date (the ghost overlay).
static func latest_photo_before(snapshot: Dictionary, individual_id: String, date: String) -> Dictionary:
	var latest: Dictionary = {}
	for entry in photos_for(snapshot, individual_id):
		if String(entry.get("date", "")) < date:
			latest = entry
	return latest

## True when both plants have at least one dated photo before the given date
## (M1-49 acceptance: Tara and Alo both have entries before 25 Apr).
static func both_plants_photographed_before(snapshot: Dictionary, date: String) -> bool:
	for individual_id in PLANT_IDS:
		var any_before := false
		for entry in photos_for(snapshot, individual_id):
			if String(entry.get("date", "")) < date:
				any_before = true
		if not any_before:
			return false
	return true

## {individual_id: [dates]} for the ledger, dates oldest first.
static func ledger_summary(snapshot: Dictionary) -> Dictionary:
	var summary := {}
	for individual_id in PLANT_IDS:
		summary[individual_id] = photos_for(snapshot, individual_id).map(func(entry): return String(entry.get("date", "")))
	return summary

static func visit_dates(scene_id: String) -> Array:
	return (VISIT_DATES.get(scene_id, []) as Array).duplicate()

## The one small care task per plant the round offers (doc 24 §7.2 step 4).
## The id is the care_id committed through apply_care; the label is what the
## player reads. "log" and "check" are observation care ids, "water" tops the
## moisture up to the calibrated band.
static func default_care_options() -> Dictionary:
	return {
		"ALO-01": [{"id": "water", "label": "Top up the moisture to the band"}, {"id": "log", "label": "Note a new leaf"}],
		"TARA-01": [{"id": "check", "label": "Check the service connection"}, {"id": "water", "label": "Top up the moisture to the band"}],
	}

## Builds the panel view for one visit. Returns {"accepted": bool, "reason",
## "view"}; the view is the exact dictionary CareRoundPanel.open expects.
## Readings: {individual_id: {"moisture": float, "temperature": float}} from
## the calibrated probe. care_options: {individual_id: [{id, label}]}.
static func build_view(snapshot: Dictionary, scene_id: String, date: String, readings: Dictionary, care_options: Dictionary, capture: Callable, family_mode: bool = false) -> Dictionary:
	var care: Dictionary = RoomContract.care_round(scene_id)
	if care.is_empty():
		return {"accepted": false, "reason": scene_id + " has no Care Round visit.", "view": {}}
	var service := PlantServiceScript.new()
	var plants: Array = []
	var allowed: Dictionary = {}
	var defaults: Dictionary = default_care_options()
	for individual_id in PLANT_IDS:
		if not care.has(individual_id):
			return {"accepted": false, "reason": scene_id + " Care Round does not visit " + individual_id + ".", "view": {}}
		var plant: Dictionary = {}
		for candidate in snapshot.get("plants", []):
			if candidate is Dictionary and String(candidate.get("individual_id", "")) == individual_id:
				plant = candidate
				break
		if plant.is_empty():
			return {"accepted": false, "reason": "No " + individual_id + " in the expedition.", "view": {}}
		var stage := String(plant.get("stage", "seed"))
		var as_of := service.advance_to(service.new_plant(individual_id, String(plant.get("lineage_id", "")), "seed", String(plant.get("planted_at", "2046-04-11 06:00 UTC"))), date + " " + VISIT_TIME)
		if bool(as_of.get("accepted", false)):
			stage = String(as_of["plant"].get("stage", stage))
		var entry: Dictionary = {"individual_id": individual_id, "name": String(PLANT_NAMES.get(individual_id, individual_id)), "stage": stage}
		var reading: Dictionary = readings.get(individual_id, {}) if readings.get(individual_id, {}) is Dictionary else {}
		var moisture: Variant = reading.get("moisture", null)
		var temperature: Variant = reading.get("temperature", null)
		var readable := (moisture is float or moisture is int) and is_finite(float(moisture)) and (temperature is float or temperature is int) and is_finite(float(temperature))
		if readable:
			entry["moisture"] = float(moisture)
			entry["temperature"] = float(temperature)
		var todays: Array = photos_for(snapshot, individual_id, date)
		entry["current_photo_path"] = String(todays[0].get("path", "")) if not todays.is_empty() else ""
		var previous: Dictionary = latest_photo_before(snapshot, individual_id, date)
		entry["previous_photo_path"] = String(previous.get("path", "")) if not previous.is_empty() else ""
		var options: Array = care_options.get(individual_id, []) if care_options.get(individual_id, []) is Array else []
		if options.is_empty():
			options = defaults.get(individual_id, [])
		entry["care_options"] = options
		plants.append(entry)
		allowed[individual_id] = STEPS.duplicate() if readable else ["observe"]
	return {"accepted": true, "reason": "", "view": {"scene_id": scene_id, "date": date, "plants": plants, "allowed_actions": allowed, "family_mode": family_mode, "capture_photo": capture}}

## A real capture producer for the scene layer: hides the panel, waits for a
## rendered world frame, saves it to the ledger path for the requested
## plant/date without overwriting an existing Growth Record image, and
## restores the panel before returning. Returns {"accepted", "photo_path"}
## or {"accepted": false, "message"}. It never calls apply_care and never
## invents a filename: the path is the ledger path for the request.
static func make_viewport_capture(tree_root: Window, panel: Control) -> Callable:
	return func(request: Dictionary) -> Dictionary:
		var individual_id := String(request.get("individual_id", ""))
		var date := String(request.get("date", ""))
		if individual_id.is_empty() or date.is_empty():
			return {"accepted": false, "message": "The camera needs a plant and a date."}
		var path := photo_path(individual_id, date)
		if FileAccess.file_exists(path):
			return {"accepted": false, "message": "A photograph already exists for this date."}
		if panel != null:
			panel.hide()
		# Two process frames are enough for the world to redraw; frame_post_draw
		# never fires on a headless run, so awaiting it would hang the round.
		await tree_root.get_tree().process_frame
		await tree_root.get_tree().process_frame
		var image: Image = tree_root.get_texture().get_image()
		if panel != null:
			panel.show()
		if image == null or image.is_empty():
			return {"accepted": false, "message": "The camera has no rendered frame yet. Try again."}
		var dir_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PHOTO_DIR))
		if dir_error != OK:
			return {"accepted": false, "message": "The Growth Record folder could not be opened."}
		if image.save_png(ProjectSettings.globalize_path(path)) != OK:
			return {"accepted": false, "message": "The photograph could not be saved."}
		return {"accepted": true, "photo_path": path}

func is_open() -> bool:
	return _open

func last_result() -> Dictionary:
	return _last_result.duplicate(true)

## Step reached for one plant on one visit date (0 observe .. 4 record, -1 none).
func progress(individual_id: String, date: String) -> int:
	return int(_progress.get(individual_id + "@" + date, -1))

## Opens the round on an already-built panel (added to the active UI tree by
## the scene layer). The panel emits action_requested; this runtime commits.
func open_round(panel: CareRoundPanel, scene_id: String, date: String, readings: Dictionary, care_options: Dictionary = {}, capture: Callable = Callable(), family_mode: bool = false) -> Dictionary:
	if _open:
		return {"accepted": false, "reason": "A Care Round is already open."}
	if _director == null:
		return {"accepted": false, "reason": "The Care Round has no expedition."}
	var built: Dictionary = build_view(_director.snapshot(), scene_id, date, readings, care_options, capture, family_mode)
	if not bool(built.get("accepted", false)):
		return {"accepted": false, "reason": String(built.get("reason", "The Care Round cannot open here."))}
	_panel = panel
	_scene_id = scene_id
	_date = date
	_view = built["view"]
	_progress = {}
	_measurements = {}
	var snapshot: Dictionary = _director.snapshot()
	var large_text := false
	if snapshot.get("accessibility", {}) is Dictionary:
		large_text = bool(snapshot["accessibility"].get("large_text", false))
	if panel.has_method("set_settings"):
		panel.set_settings({"large_text": large_text})
	panel.action_requested.connect(_on_action_requested)
	panel.closed.connect(_on_panel_closed)
	panel.open(_view)
	_open = true
	_last_result = {"accepted": true, "reason": "Care Round open for " + scene_id + " on " + date + "."}
	return _last_result.duplicate(true)

func close_round() -> void:
	if _panel != null and is_instance_valid(_panel):
		if _panel.action_requested.is_connected(_on_action_requested):
			_panel.action_requested.disconnect(_on_action_requested)
		if _panel.closed.is_connected(_on_panel_closed):
			_panel.closed.disconnect(_on_panel_closed)
		_panel.close()
	_panel = null
	_open = false
	_scene_id = ""
	_date = ""
	_view = {}
	_progress = {}
	_measurements = {}

func _on_panel_closed() -> void:
	if _panel != null and is_instance_valid(_panel):
		if _panel.action_requested.is_connected(_on_action_requested):
			_panel.action_requested.disconnect(_on_action_requested)
		if _panel.closed.is_connected(_on_panel_closed):
			_panel.closed.disconnect(_on_panel_closed)
	_panel = null
	_open = false

func _on_action_requested(action: String, payload: Dictionary) -> void:
	var result := _handle_action(action, payload)
	_last_result = result.duplicate(true)
	if not bool(result.get("accepted", false)) and action == "photograph":
		# A rejected photograph leaves an unreferenced capture file; the
		# runtime producer disposes of it (M1-83 provider contract).
		_remove_orphan(String(payload.get("photo_path", "")))
	if _panel != null and is_instance_valid(_panel) and _panel.has_method("render_result"):
		_panel.render_result(result)
	if bool(result.get("accepted", false)) and (action == "photograph" or action == "care"):
		_reopen_with_fresh_view()

func _handle_action(action: String, payload: Dictionary) -> Dictionary:
	if not _open or _panel == null:
		return {"accepted": false, "code": "no_round", "message": "No Care Round is open."}
	var individual_id := String(payload.get("individual_id", ""))
	var scene_id := String(payload.get("scene_id", ""))
	var date := String(payload.get("date", ""))
	if scene_id != _scene_id or date != _date:
		return {"accepted": false, "code": "wrong_visit", "message": "This Care Round is for " + _scene_id + " on " + _date + "."}
	if not individual_id in PLANT_IDS:
		return {"accepted": false, "code": "unknown_plant", "message": "That plant is not part of this Care Round."}
	if not STEPS.has(action):
		return {"accepted": false, "code": "unknown_action", "message": "That care action is not part of the round."}
	var name := String(PLANT_NAMES.get(individual_id, individual_id))
	var key := individual_id + "@" + date
	var step := STEPS.find(action)
	var reached := int(_progress.get(key, -1))
	if step > reached + 1:
		var needed: String = STEPS[reached + 1] if reached + 1 < STEPS.size() else ""
		return {"accepted": false, "code": "order", "message": "First " + needed + " for " + name + ", then " + action + "."}
	match action:
		"observe":
			_progress[key] = maxi(reached, 0)
			return {"accepted": true, "message": name + " observed on " + date + ": " + _stage_words(_view_stage(individual_id)) + "."}
		"measure":
			var values: Dictionary = payload.get("values", {}) if payload.get("values", {}) is Dictionary else {}
			if values.is_empty():
				return {"accepted": false, "code": "no_readings", "message": "Both calibrated readings are needed before measuring."}
			_measurements[individual_id] = values.duplicate(true)
			_progress[key] = maxi(reached, 1)
			var moisture := float(values.get("moisture", 0.0))
			var band := "inside the 40–60 band" if moisture >= MOISTURE_MIN and moisture <= MOISTURE_MAX else "outside the 40–60 band — top up the water"
			return {"accepted": true, "message": "%s: moisture %s (%s) · temperature %s°C." % [name, _number(values.get("moisture", 0.0)), band, _number(values.get("temperature", 0.0))]}
		"photograph":
			return _commit_photo(individual_id, name, date, String(payload.get("photo_path", "")))
		"care":
			return _commit_care(individual_id, name, date, String(payload.get("care_id", "")))
		"record":
			var snapshot: Dictionary = _director.snapshot()
			var has_entry := not photos_for(snapshot, individual_id, date).is_empty()
			if not has_entry:
				for item in _plant_from(snapshot, individual_id).get("care_history", []):
					if item is Dictionary and String(item.get("scenario_datetime", "")).substr(0, 10) == date and String(item.get("care_id", "")) != "photo":
						has_entry = true
			if not has_entry and reached < 3:
				return {"accepted": false, "code": "nothing_to_record", "message": "Take the photograph or finish a care task first — the dated entry needs something to record."}
			_progress[key] = maxi(reached, 4)
			return {"accepted": true, "message": "Mei wrote the dated entry for " + name + " on " + date + "."}
	return {"accepted": false, "code": "unknown_action", "message": "That care action is not part of the round."}

func _commit_photo(individual_id: String, name: String, date: String, photo_file: String) -> Dictionary:
	var snapshot: Dictionary = _director.snapshot()
	if has_photo(snapshot, individual_id, date):
		_remove_orphan(photo_file)
		return {"accepted": false, "code": "duplicate_date", "message": name + " already has a photograph for " + date + ". One photo per plant per day."}
	if photo_file.is_empty() or not FileAccess.file_exists(photo_file):
		return {"accepted": false, "code": "no_photo", "message": "No photograph file was captured. No photo was recorded."}
	var image := Image.new()
	if image.load(ProjectSettings.globalize_path(photo_file)) != OK or image.is_empty():
		_remove_orphan(photo_file)
		return {"accepted": false, "code": "unreadable_photo", "message": "The photograph could not be read. No photo was recorded."}
	var result := _commit_plant_care(individual_id, "photo", date, "care-round:photo:" + individual_id + ":" + date)
	if not bool(result.get("accepted", false)):
		_remove_orphan(photo_file)
		var reason := String(result.get("reason", "The photograph was not accepted."))
		var code := "duplicate_date" if String(result.get("reason", "")).contains("already recorded") or bool(result.get("duplicate", false)) else "rejected"
		return {"accepted": false, "code": code, "message": reason}
	_progress[individual_id + "@" + date] = 2
	return {"accepted": true, "message": "Photograph filed to the Growth Record for " + name + " on " + date + "."}

func _commit_care(individual_id: String, name: String, date: String, care_id: String) -> Dictionary:
	if care_id.is_empty():
		return {"accepted": false, "code": "no_care", "message": "Choose the care task for this plant."}
	var allowed_ids: Array = []
	for option in _view_option_list(individual_id):
		allowed_ids.append(String(option.get("id", "")))
	if not allowed_ids.has(care_id):
		return {"accepted": false, "code": "unknown_care", "message": "That care task is not offered for " + name + " on this visit."}
	var result := _commit_plant_care(individual_id, care_id, date, "care-round:" + care_id + ":" + individual_id + ":" + date)
	if not bool(result.get("accepted", false)):
		return {"accepted": false, "code": "rejected", "message": String(result.get("reason", "The care task was not accepted."))}
	_progress[individual_id + "@" + date] = 3
	var label := care_id
	for option in _view_option_list(individual_id):
		if String(option.get("id", "")) == care_id:
			label = String(option.get("label", care_id))
	return {"accepted": true, "message": name + ": " + label + " — recorded for " + date + "."}

func _commit_plant_care(individual_id: String, care_id: String, date: String, command_id: String) -> Dictionary:
	var query: Dictionary = _director.query()
	if String(query.get("scene_id", "")) != _scene_id:
		return {"accepted": false, "reason": "The expedition is in " + String(query.get("scene_id", "")) + ", not " + _scene_id + "."}
	var command := {
		"command_id": command_id,
		"issuer": "care_round_runtime",
		"owning_mission_id": String(query.get("mission_id", "")),
		"owning_scene_id": _scene_id,
		"expected_state_revision": int(query.get("state_revision", 0)),
		"target_id": individual_id,
		"verb": "plant_care",
		"payload": {"individual_id": individual_id, "care_id": care_id, "scenario_datetime": date + " " + VISIT_TIME},
	}
	return _director.commit(command)

func _reopen_with_fresh_view() -> void:
	if _panel == null or not is_instance_valid(_panel) or _director == null:
		return
	var readings: Dictionary = {}
	for individual_id in PLANT_IDS:
		if _measurements.has(individual_id):
			readings[individual_id] = _measurements[individual_id]
		else:
			readings[individual_id] = _view_readings(individual_id)
	var built: Dictionary = build_view(_director.snapshot(), _scene_id, _date, readings, {}, _view.get("capture_photo", Callable()), bool(_view.get("family_mode", false)))
	if bool(built.get("accepted", false)):
		_view = built["view"]
		_panel.open(_view)

func _view_readings(individual_id: String) -> Dictionary:
	for plant in _view.get("plants", []):
		if plant is Dictionary and String(plant.get("individual_id", "")) == individual_id:
			var reading := {}
			if plant.has("moisture"):
				reading["moisture"] = plant["moisture"]
			if plant.has("temperature"):
				reading["temperature"] = plant["temperature"]
			return reading
	return {}

func _view_stage(individual_id: String) -> String:
	for plant in _view.get("plants", []):
		if plant is Dictionary and String(plant.get("individual_id", "")) == individual_id:
			return String(plant.get("stage", "seed"))
	return "seed"

func _view_option_list(individual_id: String) -> Array:
	for plant in _view.get("plants", []):
		if plant is Dictionary and String(plant.get("individual_id", "")) == individual_id:
			return plant.get("care_options", [])
	return []

func _plant_from(snapshot: Dictionary, individual_id: String) -> Dictionary:
	for plant in snapshot.get("plants", []):
		if plant is Dictionary and String(plant.get("individual_id", "")) == individual_id:
			return plant
	return {}

func _stage_words(stage: String) -> String:
	return {"pod_bearing": "Growing pods", "mature_pods": "Mature pods", "mature_dry": "Dry pods", "naturally_dead": "Life cycle complete", "archived_petal": "Pressed petal", "archived_nameplate": "Nameplate kept"}.get(stage, stage.replace("_", " "))

func _number(value: Variant) -> String:
	var text := str(float(value))
	return text

func _remove_orphan(path: String) -> void:
	if path.is_empty():
		return
	if FileAccess.file_exists(path) and path.begins_with(PHOTO_DIR):
		DirAccess.remove_absolute(path)
