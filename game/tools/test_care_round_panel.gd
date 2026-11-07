extends SceneTree

const PANEL := "res://scripts/ui/care_round_panel.gd"
var checks := 0
var failures := 0
var requests: Array = []
var captured: Dictionary = {}
var photo_path := ""

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_check(ResourceLoader.exists(PANEL), "Care Round provider exists")
	if not ResourceLoader.exists(PANEL):
		_finish()
		return
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	photo_path = OS.get_cache_dir().path_join("m183-test-%d.png" % OS.get_process_id())
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.GREEN)
	_check(image.save_png(photo_path) == OK, "real local capture fixture written")
	var panel = load(PANEL).new()
	root.add_child(panel)
	panel.action_requested.connect(func(action, payload): requests.append({"action": action, "payload": payload}))
	var view := {"scene_id": "EX-CH01-S04", "date": "2046-04-12", "family_mode": false,
		"plants": [{"individual_id": "ALO-01", "name": "Alo", "stage": "sprout", "moisture": 40.25, "temperature": 21.0, "current_photo_path": photo_path, "previous_photo_path": photo_path, "care_options": [{"id": "note_leaf", "label": "Note a new leaf"}, {"id": "compare_roots", "label": "Compare roots"}]},
			{"individual_id": "TARA-01", "name": "Tara", "stage": "sprout", "current_photo_path": photo_path, "previous_photo_path": photo_path}],
		"allowed_actions": {"ALO-01": ["observe", "measure", "photograph", "care", "record"], "TARA-01": ["observe", "photograph"]}}
	var before := view.duplicate(true)
	panel.open(view)
	await process_frame
	await process_frame
	_check(root.gui_get_focus_owner() == panel._scroll and panel._scroll.scroll_vertical == 0, "entry focus starts at reading top without hiding the sequence")
	_check(view == before and requests.is_empty(), "opening and rendering never mutates input or requests gameplay")
	_check(panel.find_child("Readings_ALO-01", true, false).text.contains("40.25") and panel.find_child("Readings_TARA-01", true, false).text.contains("Unavailable"), "paired readings preserve fractions and missing values")
	_check(panel.find_child("Ghost_ALO-01", true, false).texture != null and panel.find_child("Ghost_TARA-01", true, false).texture != null, "both supplied previous images render as ghosts")
	_check(await panel.request_action("ALO-01", "measure") and requests[-1].payload.values == {"moisture": 40.25, "temperature": 21.0}, "measurement request carries only supplied readings")
	_check(not await panel.request_action("TARA-01", "measure"), "runtime disallowed action cannot emit")
	_check(not await panel.request_action("missing", "observe"), "unknown individual cannot emit")
	var count := requests.size()
	_check(not await panel.request_action("ALO-01", "photograph") and requests.size() == count, "absent capture producer cannot fabricate a photograph")
	view.capture_photo = func(request): captured = request; return {"accepted": false, "message": "Camera unavailable"}
	panel.open(view)
	_check(not await panel.request_action("ALO-01", "photograph") and requests.size() == count, "capture failure emits no photo request")
	view.capture_photo = func(_request): return {"accepted": true, "photo_path": photo_path + ".missing"}
	panel.open(view)
	_check(not await panel.request_action("ALO-01", "photograph") and requests.size() == count, "unreadable success path is refused")
	view.capture_photo = func(request): captured = request.duplicate(true); return {"accepted": true, "photo_path": photo_path}
	panel.open(view)
	panel.set_alignment("ALO-01", Vector2(0.31, 0))
	_check(not await panel.request_action("ALO-01", "photograph"), "outside generous alignment asks player to line up")
	panel.set_alignment("ALO-01", Vector2(0.3, -0.3))
	_check(await panel.request_action("ALO-01", "photograph") and requests[-1].payload.photo_path == photo_path and captured.alignment == {"x": 0.3, "y": -0.3}, "inclusive generous alignment reaches real capture producer and local path")
	view.family_mode = true
	panel.open(view)
	panel.set_alignment("TARA-01", Vector2(1, -1))
	_check(await panel.request_action("TARA-01", "photograph") and captured.individual_id == "TARA-01" and captured.alignment == {"x": 0.0, "y": 0.0}, "Family Mode snaps the selected plant before capture")
	count = requests.size()
	panel.render_result({"accepted": false, "code": "duplicate_date", "message": "Alo already has a photograph for this date."})
	_check(panel.find_child("CareFeedback", true, false).text.contains("already") and requests.size() == count, "runtime duplicate-date rejection stays visible and inert")
	view.capture_photo = _delayed_capture
	panel.open(view)
	(panel.find_child("photograph_ALO-01", true, false) as Button).pressed.emit()
	panel.close()
	panel.open(view)
	await process_frame
	await process_frame
	_check(requests.size() == count, "closing and reopening during asynchronous capture cancels stale photograph")
	_check(await panel.request_action("TARA-01", "photograph") and requests[-1].payload.photo_path == photo_path, "awaited producer supports a frame-render delay")
	panel.set_settings({"large_text": true})
	await process_frame
	await process_frame
	for id in ["ALO-01", "TARA-01"]:
		var card: Control = panel.find_child("Plant_" + id, true, false)
		_check(card.size.x <= 620 and card.size.x > 0, "150 percent paired card stays within viewport " + id)
		var button: Button = panel.find_child("observe_" + id, true, false)
		button.grab_focus()
		await _confirm(id == "TARA-01")
		_check(requests[-1].action == "observe" and requests[-1].payload.individual_id == id, "keyboard/controller confirm addresses selected individual " + id)
	var care: Button = panel.find_child("care_ALO-01", true, false)
	care.grab_focus()
	await _confirm(false)
	_check(requests[-1].payload.care_id == "note_leaf", "selected care option is emitted explicitly")
	var options: OptionButton = panel.find_child("CareOptions_ALO-01", true, false)
	options.grab_focus()
	await _confirm(true)
	await _pad(JOY_BUTTON_DPAD_DOWN)
	await _confirm(true)
	_check(options.selected == 1 and not options.get_popup().visible, "controller chooses another care task and confirms its popup")
	care.grab_focus()
	await _confirm(true)
	_check(requests[-1].payload.care_id == "compare_roots", "controller selected care value reaches the runtime request")
	panel.close()
	_check(not panel.visible and view.plants == before.plants, "close preserves caller plant state")
	panel.free()
	DirAccess.remove_absolute(photo_path)
	_finish()

func _delayed_capture(request: Dictionary) -> Dictionary:
	captured = request.duplicate(true)
	await process_frame
	return {"accepted": true, "photo_path": photo_path}

func _confirm(controller: bool) -> void:
	var event: InputEvent
	if controller:
		var pad := InputEventJoypadButton.new()
		pad.button_index = JOY_BUTTON_A
		event = pad
	else:
		var key := InputEventKey.new()
		key.keycode = KEY_ENTER
		key.physical_keycode = KEY_ENTER
		event = key
	event.pressed = true
	_input_viewport().push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	_input_viewport().push_input(event, true)
	await process_frame
	await process_frame

func _pad(button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	_input_viewport().push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	_input_viewport().push_input(event, true)
	await process_frame
	await process_frame

func _input_viewport() -> Viewport:
	for option in root.find_children("*", "OptionButton", true, false):
		if option.get_popup().visible:
			return option.get_popup()
	return root

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL " + message)

func _finish() -> void:
	print("CARE ROUND PANEL RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)
