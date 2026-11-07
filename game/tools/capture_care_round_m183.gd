## Native provider evidence using Sadman's real M1-84 room photographs.
## No campaign/PlantService is instantiated; these are explicitly fixture dates/readings.
extends SceneTree

const CarePanel = preload("res://scripts/ui/care_round_panel.gd")
var panel: CareRoundPanel
var failures := 0
var probes: Array[String] = []
var actions: Array = []
var temp_directory := ""
var output := ""
var view: Dictionary = {}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	root.title = "M1-83 Care Round provider fixture"
	root.always_on_top = true
	root.grab_focus()
	output = ProjectSettings.globalize_path("res://../production/qa/evidence/")
	temp_directory = OS.get_cache_dir().path_join("m183-native-%d" % OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(temp_directory)
	var background := ColorRect.new()
	background.color = UiDesign.colour("navy")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	var prior := UiDesign.button("Return to garden")
	root.add_child(prior)
	prior.grab_focus()
	panel = CarePanel.new()
	root.add_child(panel)
	panel.action_requested.connect(func(action, payload): actions.append({"action": action, "payload": payload}))
	view = {"scene_id": "EX-CH01-S05", "date": "2046-04-16", "family_mode": false,
		"plants": [], "allowed_actions": {}, "capture_photo": _capture_fixture}
	for plant in [{"individual_id": "ALO-01", "name": "Alo", "file": "alo", "moisture": 40.25, "temperature": 21.0}, {"individual_id": "TARA-01", "name": "Tara", "file": "tara", "moisture": 59.75, "temperature": 22.0}]:
		var entry: Dictionary = plant.duplicate(true)
		entry.stage = "sprout"
		entry.current_photo_path = output.path_join("M1-84_care_%s_0416.png" % plant.file)
		entry.previous_photo_path = output.path_join("M1-84_care_%s_0412.png" % plant.file)
		entry.care_options = [{"id": "note_leaf", "label": "Note a new leaf"}, {"id": "compare_roots", "label": "Compare root photographs"}]
		view.plants.append(entry)
		view.allowed_actions[plant.individual_id] = ["observe", "measure", "photograph", "care", "record"]
	panel.open(view)
	await _settle()
	await _probe("normal")
	await _save("paired_ghost")
	var align: Button = panel.find_child("Align_→_ALO-01", true, false)
	align.grab_focus()
	await _key(KEY_ENTER)
	_expect(panel.find_child("Current_ALO-01", true, false).position.x > 0, "keyboard moves actual current image relative to previous ghost")
	var photo: Button = panel.find_child("photograph_ALO-01", true, false)
	photo.grab_focus()
	await _key(KEY_ENTER)
	_expect(actions.size() == 1 and actions[-1].action == "photograph" and FileAccess.file_exists(actions[-1].payload.photo_path), "keyboard confirms Alo photo after asynchronous real local image save")
	await _save("alo_aligned")
	view.family_mode = true
	panel.open(view)
	panel.set_alignment("TARA-01", Vector2(1, 1))
	await _settle()
	photo = panel.find_child("photograph_TARA-01", true, false)
	photo.grab_focus()
	await _pad(JOY_BUTTON_A)
	_expect(actions.size() == 2 and actions[-1].payload.individual_id == "TARA-01" and actions[-1].payload.alignment == {"x": 0.0, "y": 0.0}, "controller A photographs Tara with Family snap")
	panel.render_result({"accepted": false, "code": "duplicate_date", "message": "Tara already has a photograph for 16 Apr. Choose the next care day."})
	await _save("tara_family_duplicate")
	panel.set_settings({"large_text": true})
	await _save("tara_family_duplicate_150")
	panel.open(view)
	await _settle()
	await _probe("150")
	await _save("paired_ghost_150")
	var options: OptionButton = panel.find_child("CareOptions_TARA-01", true, false)
	options.grab_focus()
	await _pad(JOY_BUTTON_A)
	await _pad(JOY_BUTTON_DPAD_DOWN)
	await _pad(JOY_BUTTON_A)
	_expect(options.selected == 1 and not options.get_popup().visible, "native controller chooses Compare root photographs through real popup")
	var care: Button = panel.find_child("care_TARA-01", true, false)
	care.grab_focus()
	await _pad(JOY_BUTTON_A)
	_expect(actions[-1].payload.get("care_id") == "compare_roots", "native selected care option request preserves selected value")
	var last: Button = panel.find_child("CareClose", true, false)
	last.grab_focus()
	await _settle()
	_expect(panel._scroll.get_global_rect().intersects(last.get_global_rect()), "150 percent final Close button reachable by focus scrolling")
	await _save("actions_150")
	await _pad(JOY_BUTTON_DPAD_DOWN)
	_expect(root.gui_get_focus_owner() != last and panel.is_ancestor_of(root.gui_get_focus_owner()), "controller D-pad cycles within panel")
	await _pad(JOY_BUTTON_B)
	_expect(not panel.visible and root.gui_get_focus_owner() == prior, "controller Back restores exact prior focus")
	for file in DirAccess.get_files_at(temp_directory):
		DirAccess.remove_absolute(temp_directory.path_join(file))
	DirAccess.remove_absolute(temp_directory)
	var log := FileAccess.open(output.path_join("M1-83_capture_probe.txt"), FileAccess.WRITE)
	log.store_string("Provider fixture only: real M1-84 room images, explicit fixture readings/dates; no campaign progress.\n" + "\n".join(probes) + "\nFailures: %d\n" % failures)
	log.close()
	print("CARE ROUND CAPTURE RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)

func _capture_fixture(request: Dictionary) -> Dictionary:
	# Fixture producer saves a real provided image; runtime must capture its real aligned world frame.
	await RenderingServer.frame_post_draw
	var plant: Dictionary = view.plants[0] if request.individual_id == "ALO-01" else view.plants[1]
	var image := Image.load_from_file(plant.current_photo_path)
	if image == null:
		return {"accepted": false, "message": "Fixture source image unavailable"}
	var path := temp_directory.path_join(request.individual_id + ".png")
	return {"accepted": image.save_png(path) == OK, "photo_path": path}

func _probe(context: String) -> void:
	_expect(root.get_visible_rect().encloses(panel._frame.get_global_rect()), context + " frame within 1280x720")
	_expect(panel._scroll.scroll_vertical == 0 and root.gui_get_focus_owner() == panel._scroll, context + " fresh-open reading focus starts at top")
	for name in ["CareTitle", "CareSequence"]:
		var label: Label = panel.find_child(name, true, false)
		_expect(panel._scroll.get_global_rect().encloses(label.get_global_rect()), context + " fresh-open title/date/sequence fully visible " + name)
	for id in ["ALO-01", "TARA-01"]:
		var card: Control = panel.find_child("Plant_" + id, true, false)
		_expect(card.size.x <= 610 and card.size.x > 0, context + " paired card fits width " + id)
		_expect((panel.find_child("Ghost_" + id, true, false) as TextureRect).texture != null, context + " supplied ghost loaded " + id)
	for node in panel._body.find_children("*", "Control", true, false):
		if node is Label or node is Button:
			_expect(node.get_global_rect().position.x >= panel._scroll.global_position.x - 1 and node.get_global_rect().end.x <= panel._scroll.get_global_rect().end.x + 1, context + " horizontal text/control bounds " + node.name)
			if node is Button:
				_expect(node.size.y >= 44, context + " 44px control target " + node.name)

func _save(suffix: String) -> void:
	await _settle()
	await RenderingServer.frame_post_draw
	var frame := panel._frame.get_global_rect()
	var title: Label = panel.find_child("CareTitle", true, false)
	var sequence: Label = panel.find_child("CareSequence", true, false)
	probes.append("CAPTURE %s frame=%s scroll=%d title=%s sequence=%s" % [suffix, frame, panel._scroll.scroll_vertical, title.get_global_rect(), sequence.get_global_rect()])
	_expect(root.get_visible_rect().encloses(frame), "capture-time frame bounds " + suffix)
	if suffix in ["paired_ghost", "paired_ghost_150"]:
		_expect(panel._scroll.scroll_vertical == 0 and frame.encloses(title.get_global_rect()) and panel._scroll.get_global_rect().encloses(sequence.get_global_rect()), "capture-time fresh title/date/sequence remain within frame " + suffix)
	_expect(root.get_texture().get_image().save_png(output.path_join("M1-83_" + suffix + ".png")) == OK, "saved native screenshot " + suffix)

func _settle() -> void:
	for i in 4:
		await process_frame

func _key(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	_input_viewport().push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	_input_viewport().push_input(event, true)
	await _settle()

func _pad(button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	_input_viewport().push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	_input_viewport().push_input(event, true)
	await _settle()

func _input_viewport() -> Viewport:
	for option in panel.find_children("*", "OptionButton", true, false):
		if option.get_popup().visible:
			return option.get_popup()
	return root

func _expect(condition: bool, message: String) -> void:
	probes.append(("PASS " if condition else "FAIL ") + message)
	if not condition:
		failures += 1
		push_error("FAIL " + message)
