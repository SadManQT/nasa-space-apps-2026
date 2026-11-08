extends SceneTree

## Real title buttons and input dispatch; -- --capture adds native pixel checks/PNGs.
var storage = preload("res://tools/support/isolated_storage.gd").new()
var capture := false
var checks := 0
var failures := 0

func _init() -> void:
	capture = OS.get_cmdline_user_args().has("--capture")
	if not storage.setup("main-menu-contrast"):
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	for large in [false, true]:
		var menu: MainMenu = load("res://scenes/ui/main_menu.tscn").instantiate()
		root.add_child(menu)
		menu.setup({})
		menu.set_accessibility({"large_text": large, "reduced_motion": large})
		await process_frame
		await process_frame
		var suffix := "150" if large else "100"
		_mouse(Vector2(1, 1))
		await process_frame
		await _states(menu._begin_button, "title_" + suffix)
		_key(KEY_TAB)
		await process_frame
		_check(root.gui_get_focus_owner() != menu._begin_button, "Tab advances from New Expedition " + suffix)
		print("M1-75 TAB: %s text=%s disabled=%s focus_mode=%s" % [suffix, root.gui_get_focus_owner().text, root.gui_get_focus_owner().disabled, root.gui_get_focus_owner().focus_mode])
		_key(KEY_TAB, true)
		await process_frame
		_check(root.gui_get_focus_owner() == menu._begin_button, "Shift Tab returns to New Expedition " + suffix)
		_key(KEY_ENTER)
		await process_frame
		_check(menu._briefing.visible and root.gui_get_focus_owner() == menu._briefing_start_button, "Enter opens briefing and focuses Enter Aurora " + suffix)
		_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(menu._briefing_start_button.get_global_rect()), "full Enter Aurora action fits viewport " + suffix)
		await _states(menu._briefing_start_button, "briefing_" + suffix)
		if large:
			var scroll: ScrollContainer = menu._briefing.find_children("*", "ScrollContainer", true, false)[0]
			var action_rect := menu._briefing_start_button.get_global_rect()
			_mouse(scroll.get_global_rect().get_center())
			for step in 8:
				var wheel := InputEventMouseButton.new()
				wheel.position = scroll.get_global_rect().get_center()
				wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
				wheel.pressed = true
				Input.parse_input_event(wheel)
				Input.flush_buffered_events()
			await process_frame
			_check(scroll.scroll_vertical > 0 and menu._briefing_start_button.get_global_rect() == action_rect, "150% briefing body scrolls while primary action stays fixed")
			_mouse(Vector2(1, 1))
			await process_frame
			await _contrast(menu._briefing_start_button, "normal", "briefing_150_scrolled_focus", true)
		_key(KEY_TAB)
		await process_frame
		_check(root.gui_get_focus_owner().text == "CANCEL", "briefing Tab stays inside modal " + suffix)
		_key(KEY_TAB)
		await process_frame
		_check(root.gui_get_focus_owner() == menu._briefing_start_button, "briefing Tab returns to primary action " + suffix)
		var launches: Array = []
		menu.new_expedition_requested.connect(func(): launches.append(true))
		_key(KEY_ENTER)
		await process_frame
		_check(launches.size() == 1 and not menu._briefing.visible and root.gui_get_focus_owner() == menu._begin_button, "Enter Aurora launches once and restores title focus " + suffix)
		menu.open_panel("settings_accessibility")
		await process_frame
		_key(KEY_ESCAPE)
		await process_frame
		_check(menu._panels.active_panel().is_empty() and root.gui_get_focus_owner() == menu._begin_button, "Esc from settings restores New Expedition focus " + suffix)
		await _contrast(menu._begin_button, "normal", "restored_" + suffix, true)
		var secondary := menu.find_child("MissionTrainerEntry", true, false) as Button
		await _states(secondary, "secondary_" + suffix)
		menu.free()
		await process_frame
	storage.cleanup()
	print("MAIN MENU CONTRAST RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _states(button: Button, label: String) -> void:
	_mouse(Vector2(1, 1))
	button.release_focus()
	await process_frame
	await _contrast(button, "normal", label + "_normal", false)
	button.grab_focus()
	await process_frame
	await _contrast(button, "normal", label + "_focus", true)
	var focus := button.get_theme_stylebox("focus") as StyleBoxFlat
	_check(not focus.draw_center or focus.bg_color.a == 0.0, label + " focus outline leaves state fill visible")
	_check(focus.border_width_left >= 2 and focus.border_color.a == 1.0, label + " has a separate visible focus outline")
	var point := button.get_global_rect().get_center()
	_mouse(point)
	await process_frame
	print("M1-75 GEOMETRY: ", label, " ", button.get_global_rect(), " mode ", button.get_draw_mode())
	_check(button.get_draw_mode() == BaseButton.DRAW_HOVER, label + " actual hovered state")
	await _contrast(button, "hover", label + "_hover", true)
	_mouse_button(point, true)
	await process_frame
	_check(button.get_draw_mode() == BaseButton.DRAW_PRESSED, label + " actual pressed state")
	await _contrast(button, "pressed", label + "_pressed", true)
	_mouse(Vector2(1, 1))
	_mouse_button(Vector2(1, 1), false)
	await process_frame

func _contrast(button: Button, state: String, label: String, focused: bool) -> void:
	var background := Color("#05060A")
	var parents: Array[Control] = []
	var parent := button.get_parent_control()
	while parent != null:
		parents.push_front(parent)
		parent = parent.get_parent_control()
	for control in parents:
		if control is PanelContainer:
			var panel := control.get_theme_stylebox("panel") as StyleBoxFlat
			background = background.blend(panel.bg_color)
	var style := button.get_theme_stylebox(state) as StyleBoxFlat
	background = background.blend(style.bg_color)
	if focused:
		var focus := button.get_theme_stylebox("focus") as StyleBoxFlat
		if focus.draw_center:
			background = background.blend(focus.bg_color)
	var font_key := "font_color" if state == "normal" else "font_" + state + "_color"
	if focused and state == "normal":
		font_key = "font_focus_color"
	var ink := button.get_theme_color(font_key)
	var ratio := _ratio(ink, background)
	_check(ratio >= 4.5, "%s text/composite contrast %.2f >= 4.5" % [label, ratio])
	if focused and button.get_theme_color("font_color") == Color("#05060A"):
		var focus := button.get_theme_stylebox("focus") as StyleBoxFlat
		_check(_ratio(focus.border_color, background) >= 3.0, label + " primary focus outline contrasts with fill")
	if capture:
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var rect := button.get_global_rect()
		var point := rect.position + Vector2(rect.size.x - 20, rect.size.y / 2)
		_check(Rect2(Vector2.ZERO, Vector2(root.size)).has_point(point), label + " native sample is inside viewport")
		var pixel := image.get_pixelv(Vector2i(point)) if Rect2(Vector2.ZERO, Vector2(root.size)).has_point(point) else Color.BLACK
		_check(_ratio(ink, pixel) >= 4.5, "%s native fill/text contrast %.2f >= 4.5" % [label, _ratio(ink, pixel)])
		print("M1-75 STATE: %s font=%s pixel=%s ratio=%.2f" % [label, ink.to_html(), pixel.to_html(), _ratio(ink, pixel)])
		if label.ends_with("_focus") or label.begins_with("restored_"):
			_check(image.save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/M1-75_%s.png" % label)) == OK, "saved " + label)

func _ratio(a: Color, b: Color) -> float:
	var x := a.srgb_to_linear().get_luminance()
	var y := b.srgb_to_linear().get_luminance()
	return (maxf(x, y) + 0.05) / (minf(x, y) + 0.05)

func _key(key: Key, shift := false) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = key
		event.physical_keycode = key
		event.shift_pressed = shift
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()

func _mouse(position: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = position
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _mouse_button(position: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("FAIL: " + label)
