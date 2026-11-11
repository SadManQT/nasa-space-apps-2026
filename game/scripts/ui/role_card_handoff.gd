extends Control
class_name RoleCardHandoff

## The privacy hand-off for Class mode: one role's crew note shown to one
## player at a time on the shared machine.
##
## Two stages per role. COVER names the holder ("Pass this screen to Player 2")
## and shows nothing of the note; REVEAL shows the note's quote and facts over
## an opaque backdrop so nothing behind it is readable. HIDE returns to the
## next role's cover or finishes. The control never touches the Mission Table:
## it emits `card_read` for each revealed note and the caller records the
## receipt. Space or Enter is the primary action, Esc steps back (cancel on a
## cover, hide on a revealed note). Every button is at least 44 px tall and
## every state has a text cue.

signal card_read(role_id: String)
signal finished(read_role_ids: Array)
signal cancelled

const CrewScript = preload("res://scripts/classmode/crew_modes.gd")
const INK := Color("#05060A")
const NAVY_DEEP := Color("#0B1426")
const NAVY := Color("#1F2A44")
const IVORY := Color("#ECEEF0")
const MUTED := Color("#A8B4C8")
const MUSTARD := Color("#F2C230")
const CYAN := Color("#20B8C9")
const MIN_TARGET := 44.0
const STAGE_COVER := "cover"
const STAGE_REVEAL := "reveal"

var _cards: Array = []
var _crew: Dictionary = {}
var _settings := {"large_text": false}
var _index := 0
var _stage := STAGE_COVER
var _read_ids: Array = []
var _backdrop: ColorRect
var _frame: PanelContainer
var _content: VBoxContainer
var _focus_name := ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Above the Mission Table (z 100): the note must cover everything behind it.
	z_index = 120
	_backdrop = ColorRect.new()
	_backdrop.name = "PrivacyBackdrop"
	_backdrop.color = Color(0.0, 0.01, 0.03, 0.985)
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_backdrop)
	_frame = PanelContainer.new()
	_frame.name = "HandoffFrame"
	_frame.add_theme_stylebox_override("panel", _box(NAVY_DEEP, Color(0.95, 0.76, 0.22, 0.8), 14, 1))
	_frame.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_frame)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 26)
	_frame.add_child(margin)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 12)
	margin.add_child(_content)
	hide()
	get_viewport().size_changed.connect(_layout)

## Shows the hand-off for `cards` (delivered role cards with their facts, in
## the order to pass them round) on `crew`. Returns false when there is
## nothing to show. `settings` carries large_text.
func open(cards: Array, crew: Dictionary, settings: Dictionary = {}) -> bool:
	_cards = []
	for card in cards:
		if card is Dictionary and bool(card.get("arrived", true)):
			_cards.append((card as Dictionary).duplicate(true))
	if _cards.is_empty():
		return false
	_crew = CrewScript.normalise(crew)
	for key in settings:
		_settings[key] = settings[key]
	_index = 0
	_stage = STAGE_COVER
	_read_ids = []
	_focus_name = "Reveal"
	show()
	_layout()
	_render()
	return true

func is_open() -> bool:
	return visible

## The current role, stage and position for tests and probes.
func state() -> Dictionary:
	var card: Dictionary = _cards[_index] if _index < _cards.size() else {}
	return {"role_id": String(card.get("role_id", "")), "stage": _stage, "index": _index, "total": _cards.size(), "read": _read_ids.duplicate()}

## The holder presses this alone: the note appears and a read receipt is emitted.
func reveal() -> Dictionary:
	if not visible or _stage != STAGE_COVER or _index >= _cards.size():
		return {"accepted": false, "reason": "No cover is open."}
	_stage = STAGE_REVEAL
	var role_id := String(_cards[_index].get("role_id", ""))
	if not _read_ids.has(role_id):
		_read_ids.append(role_id)
	card_read.emit(role_id)
	_focus_name = "Hide"
	_render()
	return {"accepted": true, "role_id": role_id}

## Hides the note and moves to the next role's cover, or finishes after the last.
func hide_card() -> Dictionary:
	if not visible or _stage != STAGE_REVEAL:
		return {"accepted": false, "reason": "No note is shown."}
	_index += 1
	_stage = STAGE_COVER
	if _index >= _cards.size():
		var read := _read_ids.duplicate()
		hide()
		finished.emit(read)
		return {"accepted": true, "finished": true, "read": read}
	_focus_name = "Reveal"
	_render()
	return {"accepted": true, "finished": false}

## Leaves without revealing the current note. Notes already read stay read.
func cancel() -> void:
	if not visible:
		return
	var read := _read_ids.duplicate()
	hide()
	if read.is_empty():
		cancelled.emit()
	else:
		finished.emit(read)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	var primary: bool = (event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]) or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A)
	var back: bool = (event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE) or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B)
	if primary:
		if _stage == STAGE_COVER:
			reveal()
		else:
			hide_card()
		get_viewport().set_input_as_handled()
	elif back:
		if _stage == STAGE_REVEAL:
			hide_card()
		else:
			cancel()
		get_viewport().set_input_as_handled()

# --- Rendering -----------------------------------------------------------------

func _render() -> void:
	if not visible or _index >= _cards.size():
		return
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	var card: Dictionary = _cards[_index]
	var role_id := String(card.get("role_id", ""))
	var tokens := CrewScript.role_tokens(_crew, role_id, {"index": str(_index + 1), "total": str(_cards.size()), "shift": str(int(card.get("arrives_shift", 1)))})
	var accent := CrewScript.role_color(role_id)
	_content.add_child(_label(CrewScript.text("handoff", "eyebrow", tokens), 13, CYAN))
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	_content.add_child(head)
	var chip := _label(" %s " % String(card.get("role", "")).to_upper(), 12, INK)
	chip.add_theme_stylebox_override("normal", _box(accent, Color(0, 0, 0, 0), 4, 0))
	head.add_child(chip)
	head.add_child(_label(String(card.get("name", "")).to_upper(), 24, IVORY))
	var holder := _label(CrewScript.text("table", "holder_line", tokens).to_upper(), 13, MUTED)
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(holder)
	if _stage == STAGE_COVER:
		_render_cover(tokens)
	else:
		_render_reveal(card, tokens)
	_restore_focus()

func _render_cover(tokens: Dictionary) -> void:
	_content.add_child(_wrap(CrewScript.text("handoff", "cover_title", tokens), 30, MUSTARD))
	_content.add_child(_wrap(CrewScript.text("handoff", "cover_line", tokens), 17, IVORY))
	_content.add_child(_wrap(CrewScript.text("handoff", "cover_hint", tokens), 14, MUTED))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_child(spacer)
	var row := HFlowContainer.new()
	row.alignment = FlowContainer.ALIGNMENT_END
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 6)
	_content.add_child(row)
	var not_now := _button(CrewScript.text("handoff", "cancel_button", tokens) + " · ESC", "Cancel")
	not_now.pressed.connect(cancel)
	row.add_child(not_now)
	var reveal_button := _button(CrewScript.text("handoff", "reveal_button", tokens) + " · SPACE", "Reveal")
	reveal_button.pressed.connect(func() -> void: reveal())
	row.add_child(reveal_button)

func _render_reveal(card: Dictionary, tokens: Dictionary) -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "NoteScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	_content.add_child(scroll)
	var note := VBoxContainer.new()
	note.name = "Note"
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note.add_theme_constant_override("separation", 8)
	scroll.add_child(note)
	if not String(card.get("quote", "")).is_empty():
		note.add_child(_wrap("“%s”" % String(card.quote), 18, CYAN))
	for fact in card.get("facts", []):
		var line := _wrap("• " + String(fact), 16, IVORY)
		line.name = "Fact"
		note.add_child(line)
	_content.add_child(_wrap(CrewScript.text("handoff", "read_footer", tokens), 13, MUTED))
	var row := HFlowContainer.new()
	row.alignment = FlowContainer.ALIGNMENT_END
	row.add_theme_constant_override("h_separation", 8)
	_content.add_child(row)
	var last := _index >= _cards.size() - 1
	var hide_button := _button(CrewScript.text("handoff", "hide_last_button" if last else "hide_button", tokens) + " · SPACE", "Hide")
	hide_button.pressed.connect(func() -> void: hide_card())
	row.add_child(hide_button)

func _restore_focus() -> void:
	var target := find_child(_focus_name, true, false) as Control if not _focus_name.is_empty() else null
	if target != null:
		_apply_focus.call_deferred(target)

func _apply_focus(target: Control) -> void:
	if is_instance_valid(target) and target.is_inside_tree() and visible:
		target.grab_focus()

func _layout() -> void:
	if _frame == null or not is_inside_tree():
		return
	var view := get_viewport_rect().size
	var width := minf(760.0 * _scale(), view.x - 40.0)
	var height := minf(520.0 * _scale(), view.y - 40.0)
	_frame.position = Vector2((view.x - width) * 0.5, (view.y - height) * 0.5)
	_frame.size = Vector2(width, height)

func _scale() -> float:
	return 1.5 if bool(_settings.get("large_text", false)) else 1.0

func _fs(size: int) -> int:
	return int(round(size * _scale()))

# --- Widget helpers --------------------------------------------------------------

func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", _fs(size))
	label.add_theme_color_override("font_color", color)
	return label

func _wrap(text: String, size: int, color: Color) -> Label:
	var label := _label(text, size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size.x = 200
	return label

func _button(text: String, node_name: String) -> Button:
	var button := Button.new()
	button.name = node_name.validate_node_name()
	button.text = text
	button.custom_minimum_size = Vector2(0, MIN_TARGET)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", _fs(14))
	button.add_theme_color_override("font_color", IVORY)
	button.add_theme_color_override("font_pressed_color", IVORY)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_focus_color", IVORY)
	button.add_theme_stylebox_override("normal", _box(NAVY, Color(0.32, 0.45, 0.66, 0.9), 7, 1))
	button.add_theme_stylebox_override("pressed", _box(NAVY, Color(0.32, 0.45, 0.66, 0.9), 7, 1))
	button.add_theme_stylebox_override("hover", _box(MUSTARD, INK, 7, 2))
	button.add_theme_stylebox_override("focus", _box(Color(0, 0, 0, 0), IVORY, 7, 3))
	return button

func _box(fill: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style
