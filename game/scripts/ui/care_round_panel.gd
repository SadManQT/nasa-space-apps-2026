extends Control
class_name CareRoundPanel

class PopupPadInput extends Node:
	var handle: Callable
	func _input(event: InputEvent) -> void:
		handle.call(event)

## Presentation only. Runtime owns all care/date/order validation and ledger writes.
signal action_requested(action: String, payload: Dictionary)
signal closed

const ACTIONS := ["observe", "measure", "photograph", "care", "record"]
const ALIGNMENT_TOLERANCE := 0.3
const STAGE_WORDS := {"pod_bearing": "Growing pods", "mature_pods": "Mature pods", "mature_dry": "Dry pods", "naturally_dead": "Life cycle complete", "archived_petal": "Pressed petal", "archived_nameplate": "Nameplate kept"}
var _view: Dictionary = {}
var _alignment: Dictionary = {}
var _settings := {"large_text": false}
var _last_focus: Control
var _frame: PanelContainer
var _scroll: ScrollContainer
var _body: VBoxContainer
var _feedback: Label
var _buttons: Array[Button] = []
var _busy := false
var _generation := 0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 180
	theme = UiKit.theme()
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0, 0, 0, 0.7)
	add_child(shade)
	_frame = UiDesign.glass_panel(UiDesign.colour("accent"))
	_frame.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_frame)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	_scroll.focus_mode = Control.FOCUS_ALL
	_frame.add_child(_scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 12)
	_scroll.add_child(_body)
	get_viewport().size_changed.connect(_layout)
	hide()

func open(view: Dictionary) -> void:
	if not visible:
		_last_focus = get_viewport().gui_get_focus_owner()
	_view = view.duplicate(true)
	_generation += 1
	_busy = false
	_alignment.clear()
	show()
	_render()

func close() -> void:
	_generation += 1
	_busy = false
	hide()
	if is_instance_valid(_last_focus) and _last_focus.is_visible_in_tree():
		_last_focus.grab_focus()
	_last_focus = null
	closed.emit()

func set_settings(settings: Dictionary) -> void:
	_settings.large_text = settings.get("large_text", false) == true
	if visible:
		_layout()

func render_result(result: Dictionary) -> void:
	var message := String(result.get("message", ""))
	if message.is_empty():
		message = "Recorded." if result.get("accepted", false) == true else "This action was not accepted. Check the care instructions."
	_feedback.text = message
	_feedback.add_theme_color_override("font_color", UiDesign.colour("ivory" if result.get("accepted", false) == true else "accent"))

func set_alignment(individual_id: String, offset: Vector2) -> void:
	if _plant(individual_id).is_empty() or not offset.is_finite():
		return
	_alignment[individual_id] = offset.clamp(Vector2(-1, -1), Vector2.ONE)
	var current := find_child("Current_" + individual_id, true, false) as TextureRect
	if current != null:
		current.position = _alignment[individual_id] * 48.0
	var hint := find_child("Alignment_" + individual_id, true, false) as Label
	if hint != null:
		hint.text = "Frame aligned. Ready to photograph." if _aligned(individual_id) else "Move the frame towards the faint previous photo."

func request_action(individual_id: String, action: String) -> bool:
	var plant := _plant(individual_id)
	if not visible or _busy or plant.is_empty() or not ACTIONS.has(action) or not _view.get("allowed_actions", {}).get(individual_id, []).has(action):
		return false
	var payload := {"individual_id": individual_id, "scene_id": String(_view.get("scene_id", "")), "date": String(_view.get("date", ""))}
	if action == "measure":
		var values := {}
		for key in ["moisture", "temperature"]:
			if (plant.get(key) is float or plant.get(key) is int) and is_finite(float(plant[key])):
				values[key] = plant[key]
		if values.size() != 2:
			_feedback.text = "Both calibrated readings are needed. Ask for the missing measurement."
			return false
		payload.values = values
	elif action == "care":
		var options := find_child("CareOptions_" + individual_id, true, false) as OptionButton
		if options == null or options.selected < 0:
			_feedback.text = "Choose the care task for this plant."
			return false
		payload.care_id = options.get_item_metadata(options.selected)
	elif action == "photograph":
		if _view.get("family_mode", false) == true:
			set_alignment(individual_id, Vector2.ZERO)
		if not _aligned(individual_id):
			_feedback.text = "Line up the frame first. A close match is enough."
			return false
		var capture: Variant = _view.get("capture_photo")
		if not capture is Callable or not capture.is_valid():
			_feedback.text = "Camera unavailable. No photograph was recorded."
			return false
		var offset: Vector2 = _alignment.get(individual_id, Vector2.ZERO)
		var request := payload.duplicate(true)
		request.alignment = {"x": snappedf(offset.x, 0.001), "y": snappedf(offset.y, 0.001)}
		var generation := _generation
		_busy = true
		var result: Variant = await capture.call(request)
		if generation != _generation or not visible:
			return false
		_busy = false
		if not result is Dictionary or result.get("accepted", false) != true or _image(String(result.get("photo_path", ""))) == null:
			_feedback.text = String(result.get("message", "Capture failed. No photograph was recorded.")) if result is Dictionary else "Capture failed. No photograph was recorded."
			return false
		payload.photo_path = String(result.photo_path)
		payload.alignment = request.alignment
	_feedback.text = "Waiting for care confirmation."
	action_requested.emit(action, payload)
	return true

func _plant(individual_id: String) -> Dictionary:
	for plant in _view.get("plants", []):
		if plant is Dictionary and plant.get("individual_id", "") == individual_id:
			return plant
	return {}

func _aligned(individual_id: String) -> bool:
	var offset: Vector2 = _alignment.get(individual_id, Vector2.ZERO)
	return snappedf(maxf(absf(offset.x), absf(offset.y)), 0.001) <= ALIGNMENT_TOLERANCE

func _image(path: String) -> Texture2D:
	if path.is_empty() or path.begins_with("http") or not FileAccess.file_exists(path):
		return null
	var image := Image.new()
	if image.load(ProjectSettings.globalize_path(path)) != OK or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)

func _render() -> void:
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	_buttons.clear()
	var title := UiDesign.label("Care Round · " + String(_view.get("date", "Date unavailable")), "heading")
	title.name = "CareTitle"
	_body.add_child(title)
	var sequence := UiDesign.label("Observe → Measure → Photograph → Care → Record", "body", "accent")
	sequence.name = "CareSequence"
	_body.add_child(sequence)
	_body.add_child(UiDesign.label("Compare both plants. Moisture reference: 40–60. " + ("Family Mode: the photo frame snaps into place." if _view.get("family_mode", false) == true else "A close photo alignment is enough."), "caption"))
	_feedback = UiDesign.label("Choose an available action. Your care guide confirms each step.")
	_feedback.name = "CareFeedback"
	_body.add_child(_feedback)
	var pair := HBoxContainer.new()
	pair.add_theme_constant_override("separation", 16)
	_body.add_child(pair)
	for plant in _view.get("plants", []):
		if plant is Dictionary:
			_add_plant(pair, plant)
	var back := _button("Close", "CareClose", close)
	_body.add_child(back)
	_layout()
	_scroll.scroll_vertical = 0
	var active: Array[Button] = []
	for button in _buttons:
		if not button.disabled:
			active.append(button)
	for i in active.size():
		var previous := active[(i - 1 + active.size()) % active.size()].get_path()
		var next := active[(i + 1) % active.size()].get_path()
		active[i].focus_previous = previous
		active[i].focus_next = next
		active[i].focus_neighbor_top = previous
		active[i].focus_neighbor_left = previous
		active[i].focus_neighbor_bottom = next
		active[i].focus_neighbor_right = next
	if not active.is_empty():
		_scroll.focus_next = active[0].get_path()
		_scroll.focus_previous = active[-1].get_path()
		active[0].focus_previous = _scroll.get_path()
		active[-1].focus_next = _scroll.get_path()
		_focus_entry.call_deferred(_generation)

func _focus_entry(generation: int) -> void:
	if generation == _generation and visible:
		_scroll.grab_focus()
		_scroll.scroll_vertical = 0

func _add_plant(pair: HBoxContainer, plant: Dictionary) -> void:
	var id := String(plant.get("individual_id", ""))
	var card := UiDesign.glass_panel()
	card.name = "Plant_" + id
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pair.add_child(card)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	card.add_child(stack)
	var stage := String(plant.get("stage", "Growth unavailable"))
	stack.add_child(UiDesign.label(String(plant.get("name", "Plant")) + " · " + String(STAGE_WORDS.get(stage, stage.replace("_", " "))), "heading"))
	var readings := UiDesign.label("Moisture: %s\nTemperature: %s" % [_reading(plant, "moisture", ""), _reading(plant, "temperature", " °C")])
	readings.name = "Readings_" + id
	stack.add_child(readings)
	var preview := Control.new()
	preview.custom_minimum_size = Vector2(0, 180)
	preview.clip_contents = true
	stack.add_child(preview)
	var current := _photo(preview, String(plant.get("current_photo_path", "")), "Current_" + id)
	var ghost := _photo(preview, String(plant.get("previous_photo_path", "")), "Ghost_" + id)
	ghost.modulate.a = 0.28
	if current.texture == null and ghost.texture == null:
		# A viewfinder, not an error: nothing has been photographed on this date yet.
		var frame := Panel.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(1, 1, 1, 0.03)
		style.border_color = Color(UiDesign.colour("accent"), 0.55)
		style.set_border_width_all(1)
		style.set_corner_radius_all(6)
		frame.add_theme_stylebox_override("panel", style)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview.add_child(frame)
		frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var empty := VBoxContainer.new()
		empty.alignment = BoxContainer.ALIGNMENT_CENTER
		empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(empty)
		empty.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var icon := UiKit.icon("plant", "accent", 40)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		empty.add_child(icon)
		var note := UiDesign.label("No photo yet today: take one to compare growth", "caption", "muted")
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_child(note)
	elif ghost.texture != null:
		stack.add_child(UiDesign.label("Faint overlay: previous photo.", "caption", "muted"))
	var hint := UiDesign.label("Frame aligned. Ready to photograph.", "caption")
	hint.name = "Alignment_" + id
	stack.add_child(hint)
	var moves := HFlowContainer.new()
	stack.add_child(moves)
	for movement in [{"label": "←", "offset": Vector2(-0.1, 0)}, {"label": "→", "offset": Vector2(0.1, 0)}, {"label": "↑", "offset": Vector2(0, -0.1)}, {"label": "↓", "offset": Vector2(0, 0.1)}, {"label": "Center", "offset": Vector2.ZERO}]:
		var button := _button(movement.label, "Align_" + movement.label + "_" + id, func(): set_alignment(id, Vector2.ZERO if movement.offset == Vector2.ZERO else _alignment.get(id, Vector2.ZERO) + movement.offset))
		button.tooltip_text = "Move photo frame " + movement.label
		moves.add_child(button)
	var options := OptionButton.new()
	options.name = "CareOptions_" + id
	options.custom_minimum_size.y = 44
	options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options.fit_to_longest_item = false
	for option in plant.get("care_options", []):
		if option is Dictionary and option.has("id") and option.has("label"):
			options.add_item(String(option.label))
			options.set_item_metadata(options.item_count - 1, String(option.id))
	if options.item_count == 0:
		options.add_item("No care task supplied")
		options.disabled = true
	stack.add_child(options)
	_buttons.append(options)
	var pad_input := PopupPadInput.new()
	pad_input.handle = _popup_input.bind(options)
	options.get_popup().add_child(pad_input)
	var actions := HFlowContainer.new()
	stack.add_child(actions)
	for action in ACTIONS:
		var button := _button(action.capitalize(), action + "_" + id, func(): await request_action(id, action))
		button.disabled = not _view.get("allowed_actions", {}).get(id, []).has(action) or (action == "care" and options.disabled)
		actions.add_child(button)

func _reading(plant: Dictionary, key: String, suffix: String) -> String:
	var value: Variant = plant.get(key)
	return UiDesign.number(float(value)) + suffix if (value is float or value is int) and is_finite(float(value)) else "Not measured yet"

func _photo(parent: Control, path: String, node_name: String) -> TextureRect:
	var photo := TextureRect.new()
	photo.name = node_name
	photo.texture = _image(path)
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(photo)
	photo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return photo

func _button(text_value: String, node_name: String, callback: Callable) -> Button:
	var button := UiDesign.button(text_value)
	button.name = node_name
	button.pressed.connect(callback)
	_buttons.append(button)
	return button

func _layout() -> void:
	if _frame == null:
		return
	_frame.position = Vector2(24, 20)
	_frame.size = (get_viewport_rect().size - Vector2(48, 40)).max(Vector2(1, 1))
	UiDesign.apply_type(_body, get_viewport_rect().size.y, 1.5 if _settings.large_text else 1.0)

func _popup_input(event: InputEvent, options: OptionButton) -> void:
	if not options.get_popup().visible or not event is InputEventJoypadButton or not event.pressed:
		return
	var popup := options.get_popup()
	if event.button_index in [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN]:
		var direction := -1 if event.button_index == JOY_BUTTON_DPAD_UP else 1
		popup.set_focused_item(posmod(popup.get_focused_item() + direction, options.item_count))
	elif event.button_index == JOY_BUTTON_A:
		var selected := popup.get_focused_item()
		if selected >= 0:
			options.select(selected)
		popup.hide()
	elif event.button_index == JOY_BUTTON_B:
		popup.hide()
	else:
		return
	popup.set_input_as_handled()

func _input(event: InputEvent) -> void:
	if not visible or event.is_echo():
		return
	var pad: bool = event is InputEventJoypadButton and event.pressed
	if event.is_action_pressed("ui_cancel") or (pad and event.button_index == JOY_BUTTON_B):
		close()
		get_viewport().set_input_as_handled()
	elif pad:
		var focus := get_viewport().gui_get_focus_owner()
		if focus == null or not _frame.is_ancestor_of(focus):
			return
		if event.button_index == JOY_BUTTON_A and focus is Button and not focus.disabled:
			if focus is OptionButton:
				focus.show_popup()
				focus.get_popup().set_focused_item(focus.selected)
			else:
				focus.pressed.emit()
			get_viewport().set_input_as_handled()
		elif event.button_index in [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_RIGHT]:
			var path: NodePath = focus.focus_previous if event.button_index in [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_LEFT] else focus.focus_next
			if not path.is_empty():
				focus.get_node(path).grab_focus()
				get_viewport().set_input_as_handled()
