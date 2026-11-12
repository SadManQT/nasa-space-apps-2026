extends Control
class_name Chapter8PuzzlePanel

## The Chapter 8 puzzle panel: P-15 Two Teams, One Road and P-16 The Link and
## the Living Garden, one operation at a time.
##
## Left: what we know (the scene's clues with their canon lines, who holds
## each one, the mission data card). Centre: the decision, drawn for the step's
## kind (team boards, manifest, road and reserve, bearing dials, procedure
## card, home loop, five sunrise checks). Right: TRY IT before → after from the
## same route preview that commits, the held/accepted feedback sentence, the
## active flight rules, the risk card, the Go/No-Go poll and the hint ladder.
##
## The panel edits only the route's Chapter8Puzzles model and never changes
## resources: LOCK IN leaves through `commit_requested`, which the HUD sends to
## the physical operation. Space tries or locks in, Space again confirms, Esc
## steps back, H reveals a hint. Every control is a focusable button of at
## least 44 px, every state has a text cue as well as a colour, and nothing
## requires timing unless assistance is off (the 3-second lock hold).

signal commit_requested(target_id: String, payload: Dictionary)
signal opened(target_id: String)
signal closed(target_id: String)

const PuzzleScript = preload("res://scripts/puzzles/chapter8_puzzles.gd")
# Instrument Light palette (12 Nov AAA pass): the same tokens as the rest of the UI.
const INK := Color("#0A101C")
const NAVY := Color("#12151F")
const NAVY_DEEP := Color("#0A0C12")
const IVORY := Color("#EEF1F8")
const MUTED := Color("#9AA4BA")
const MUSTARD := Color("#3AA0FF")
const CYAN := Color("#FF6B9D")
const GREEN := Color("#3EE0A0")
const EDGE := Color("#252A3A")
var _rules_open := false
const RED := Color("#E56B6F")
const MIN_TARGET := 44.0
const STAGE_TEXT := {"learn": "LEARN · a guided example that cannot fail", "apply": "APPLY · real stakes", "twist": "TWIST · one new constraint"}
const HOME_ROWS := [["E", "Battery", "energy_capacity"], ["A", "Air", "air_capacity"], ["H", "Garden health", "health_capacity"], ["C", "Crop", "crop_capacity"], ["R", "Food (days)", ""]]

var _route: RefCounted
var hint_player: Control   # the HUD's shared player; first-time cards replay their how-to clip there
var _target_id := ""
var _settings := {"large_text": false, "timer_free": true, "class_mode": false}
var _view: Dictionary = {}
var _last_try: Dictionary = {}
var _tried_key := ""
var _confirming := false
var _notice := ""
var _notice_kind := "info"
var _focus_name := ""
var _selected_person := ""
var _holding := false
var _overlay: ColorRect
var _frame: PanelContainer
var _content: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100
	_overlay = ColorRect.new()
	_overlay.color = Color(0.0, 0.01, 0.03, 0.82)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)
	_frame = PanelContainer.new()
	_frame.add_theme_stylebox_override("panel", _box(Color(NAVY_DEEP, 0.97), EDGE, 8, 1))
	_frame.mouse_filter = Control.MOUSE_FILTER_STOP
	# Anchored, not sized: an autowrapped label reports a huge minimum height
	# on its first frame, and an anchored frame settles back to the viewport
	# once the real minimum is known, where an explicit size would stay grown.
	_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_frame)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	_frame.add_child(margin)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 10)
	margin.add_child(_content)
	hide()
	get_viewport().size_changed.connect(_layout)

## Opens the panel for one Chapter 8 operation. `settings` carries large_text,
## timer_free and class_mode.
func open(route: RefCounted, target_id: String, settings: Dictionary = {}) -> void:
	_route = route
	_target_id = target_id
	for key in settings:
		_settings[key] = settings[key]
	_confirming = false
	_notice = ""
	_notice_kind = "info"
	_last_try = {}
	_tried_key = ""
	_focus_name = ""
	_selected_person = ""
	_holding = false
	show()
	_layout()
	_render()
	opened.emit(target_id)
	_grab_first_focus()

## Closes without committing anything. A selection in progress stays in the
## model, so reopening resumes where the player left off.
func close() -> void:
	if not visible:
		return
	hide()
	_confirming = false
	_holding = false
	closed.emit(_target_id)

func is_open() -> bool:
	return visible

func target_id() -> String:
	return _target_id

## The latest view the panel rendered (for tests and evidence probes).
func view() -> Dictionary:
	return _view.duplicate(true)

## The latest TRY IT result (for tests and evidence probes).
func last_try() -> Dictionary:
	return _last_try.duplicate(true)

# --- Player actions (also called by tests) ---------------------------------

## Records one decision for the open step (field and value depend on its kind).
func choose(field: String, value) -> Dictionary:
	if _committed():
		return _hold("This step is already locked in. Retry the checkpoint to change it.")
	var result: Dictionary = _model().select(_target_id, field, value)
	_tried_key = ""
	_last_try = {}
	if bool(result.get("accepted", false)):
		_notice = ""
		_notice_kind = "info"
	else:
		_notice = String(result.get("reason", ""))
		_notice_kind = "held"
		_offer_first_hint()
	_focus_name = "Choice_%s_%s" % [field, str(value)]
	_render()
	return result

## Files one clue to the evidence board.
func inspect_clue(clue_id: String) -> Dictionary:
	var result: Dictionary = _model().find_clue(String(_view.get("scene", {}).get("id", "")), clue_id)
	_notice = String(result.get("reason", ""))
	_notice_kind = "info"
	_focus_name = "Clue_" + clue_id
	_render()
	return result

## Clears the current selection. Nothing committed changes.
func undo() -> void:
	if _committed():
		return
	_model().reset(_target_id)
	_selected_person = ""
	_tried_key = ""
	_last_try = {}
	_notice = "Selection cleared."
	_notice_kind = "info"
	_focus_name = "Undo"
	_render()

## Reveals the next hint tier. Hints never change the outcome.
func reveal_hint() -> Dictionary:
	var result: Dictionary = _model().reveal_hint(_target_id)
	_notice = String(result.get("text", result.get("reason", "")))
	_notice_kind = "info"
	_focus_name = "Hint"
	_render()
	return result

## One role signs the Go/No-Go poll (Class mode: each group signs its own).
func sign(role_id: String) -> Dictionary:
	var result: Dictionary = _model().sign_poll(_target_id, role_id)
	_focus_name = "Sign_" + role_id
	_render()
	return result

## Closes the first-time card for this puzzle.
func dismiss_first_time() -> void:
	_model().mark_first_time_seen(String(_view.get("puzzle_id", "")))
	_focus_name = "Try"
	_render()

## Tap-confirm for the lock step (the untimed equivalent of the 3-second hold).
func tap_lock() -> Dictionary:
	return choose("tap", true)

## TRY IT: builds the payload from the selection and runs the real read-only
## route preview. Nothing changes yet. LOCK IN requires an accepted try of the
## exact current selection.
func try_it() -> Dictionary:
	PlaytestLog.event("try", {"target": _target_id})
	if _committed():
		return _hold("This step is already locked in.")
	_refresh_view()
	var attempt: Dictionary = _view.get("attempt", {})
	if not bool(attempt.get("accepted", false)):
		_last_try = {"accepted": false, "reason": String(attempt.get("reason", "")), "incomplete": true}
		_notice = String(attempt.get("reason", "Finish the decision first."))
		_notice_kind = "held"
		_render()
		return _last_try
	var payload: Dictionary = attempt.get("payload", {})
	var result: Dictionary = _route.chapter8_preview(_target_id, payload)
	_last_try = result.duplicate(true)
	_last_try["payload"] = payload.duplicate(true)
	if bool(result.get("accepted", false)):
		_tried_key = _selection_key()
		var advisory: String = _model().advisory_for(_target_id, String(attempt.get("option_id", "")))
		_notice = ("Accepted with an advisory: " + advisory) if not advisory.is_empty() else "Accepted. Nothing has changed yet. Read the preview, then lock in with Space."
		_notice_kind = "advisory" if not advisory.is_empty() else "ok"
		_focus_name = "Commit"
	else:
		_tried_key = ""
		_model().count_attempt(_target_id)
		var reason := String(result.get("reason", "Held."))
		var feedback: String = _model().feedback_for(_target_id, String(attempt.get("option_id", "")), String(attempt.get("feedback_key", "")), reason)
		_notice = "Held · " + feedback + ("" if feedback == reason or bool(result.get("unmet", false)) else "  (" + reason + ")")
		_notice_kind = "held"
		_focus_name = "Try"
		_offer_first_hint()
	_render()
	return _last_try

## Opens the lock-in confirmation when the tried selection can be committed.
func request_commit() -> Dictionary:
	var reason := _commit_reason()
	if not reason.is_empty():
		_notice = reason
		_notice_kind = "held"
		_render()
		return {"accepted": false, "reason": reason}
	_confirming = true
	_focus_name = "ConfirmCommit"
	_render()
	return {"accepted": true, "reason": "Confirm to lock in."}

## Confirms the open confirmation: closes the panel and emits the payload once.
func confirm_commit() -> Dictionary:
	if not _confirming:
		return {"accepted": false, "reason": "Open the lock-in confirmation first."}
	var reason := _commit_reason()
	if not reason.is_empty():
		_confirming = false
		_notice = reason
		_notice_kind = "held"
		_render()
		return {"accepted": false, "reason": reason}
	var payload: Dictionary = _last_try.get("payload", {}).duplicate(true)
	var id := _target_id
	close()
	commit_requested.emit(id, payload)
	return {"accepted": true, "target_id": id, "payload": payload}

## Leaves the confirmation without committing.
func cancel_confirm() -> void:
	_confirming = false
	_focus_name = "Commit"
	_render()

# --- Input -----------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not visible:
		return
	var key_down: bool = event is InputEventKey and event.pressed and not event.echo
	var space: bool = key_down and event.physical_keycode == KEY_SPACE
	var pad_confirm: bool = event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_Y
	var back: bool = (key_down and event.physical_keycode == KEY_ESCAPE) or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B)
	var hint: bool = key_down and event.physical_keycode == KEY_H
	if space or pad_confirm:
		if _confirming:
			confirm_commit()
		elif _tried_key == _selection_key() and not _tried_key.is_empty():
			request_commit()
		else:
			try_it()
		get_viewport().set_input_as_handled()
	elif back:
		if _confirming:
			cancel_confirm()
		else:
			close()
		get_viewport().set_input_as_handled()
	elif hint and not _confirming:
		reveal_hint()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not visible or not _holding or _route == null:
		return
	var selection: Dictionary = _model().selection(_target_id)
	if bool(selection.get("locked", false)):
		_holding = false
		_render()
		return
	_model().select(_target_id, "progress", float(selection.get("progress", 0.0)) + delta)
	var progress := find_child("LockProgress", true, false) as Label
	var after: Dictionary = _model().selection(_target_id)
	if progress != null:
		progress.text = _lock_text(after)
	if bool(after.get("locked", false)):
		_holding = false
		_notice = "Lock held for 3 seconds. Both legs stable."
		_notice_kind = "ok"
		_render()

# --- Rendering -------------------------------------------------------------

func _render() -> void:
	if not visible or _route == null:
		return
	var focused := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	if _focus_name.is_empty() and focused != null and is_ancestor_of(focused):
		_focus_name = String(focused.name)
	_refresh_view()
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	if _view.is_empty():
		_content.add_child(_wrap("This operation has no puzzle card.", 16, RED))
		return
	_render_header()
	if _confirming:
		_render_confirmation()
	else:
		var columns := HBoxContainer.new()
		columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
		columns.add_theme_constant_override("separation", 14)
		_content.add_child(columns)
		columns.add_child(_scroll(_render_clues(), "CluesScroll"))
		columns.add_child(_scroll(_render_decision(), "DecisionScroll"))
		columns.add_child(_scroll(_render_preview(), "PreviewScroll"))
		_render_footer()
	_restore_focus()

func _render_header() -> void:
	var scene: Dictionary = _view.get("scene", {})
	var step: Dictionary = _view.get("step", {})
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	_content.add_child(row)
	row.add_child(_label(String(_view.get("puzzle", {}).get("title", "")).to_upper(), 20, MUSTARD))
	var stage := _label(" %s " % STAGE_TEXT.get(String(scene.get("stage", "")), "").to_upper(), 11, INK)
	stage.add_theme_stylebox_override("normal", _box(CYAN, Color(0, 0, 0, 0), 4, 0))
	row.add_child(stage)
	var title := _label(String(scene.get("title", "")), 15, IVORY)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(title)
	var meta := _wrap("%s · TIME PAUSED WHILE THIS CARD IS OPEN" % String(scene.get("story_date", _view.get("scenario_datetime", ""))), 12, MUTED)
	meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	meta.custom_minimum_size.x = 300
	row.add_child(meta)
	var goal := _wrap("GOAL · %s" % String(step.get("goal", "")), 16, IVORY)
	_content.add_child(goal)
	_content.add_child(_wrap("WHY · %s" % String(step.get("why", "")), 13, MUTED))

func _render_clues() -> Control:
	var column := _column("WHAT WE KNOW · INSPECT TO FILE EACH CLUE", 300)
	var found := 0
	for clue in _view.get("clues", []):
		var is_found := bool(clue.get("found", false))
		if is_found:
			found += 1
		var box := _card_box(is_found, true)
		var inner := VBoxContainer.new()
		inner.add_theme_constant_override("separation", 4)
		box.add_child(inner)
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 6)
		inner.add_child(head)
		var chip := _label(" %s " % String(clue.get("kind", "")).to_upper(), 10, INK)
		chip.add_theme_stylebox_override("normal", _box(MUSTARD if is_found else MUTED, Color(0, 0, 0, 0), 4, 0))
		head.add_child(chip)
		var where := _label(String(clue.get("where", "")), 12, MUTED)
		where.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		where.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(where)
		inner.add_child(_wrap(String(clue.get("text", "")), 13, IVORY))
		if not String(clue.get("line", "")).is_empty():
			inner.add_child(_wrap("%s: “%s”" % [String(clue.get("speaker", "")), String(clue.get("line", ""))], 13, CYAN))
		var holders: Array = clue.get("holder_names", [])
		var holder_text := "Held by %s" % " and ".join(holders) if not holders.is_empty() else ""
		if bool(_settings.get("class_mode", false)) and not holders.is_empty():
			holder_text += " · private role card: read it aloud before the poll"
		if not holder_text.is_empty():
			inner.add_child(_wrap(holder_text, 11, MUTED))
		if is_found:
			inner.add_child(_wrap("✓ ON THE EVIDENCE BOARD", 11, GREEN))
		else:
			var inspect := _button("INSPECT", "Clue_" + String(clue.get("id", "")))
			var clue_id := String(clue.get("id", ""))
			inspect.pressed.connect(func() -> void: inspect_clue(clue_id))
			inner.add_child(inspect)
		column.add_child(box)
	column.add_child(_wrap("%d of %d clues filed · sort them: observed, inferred, unknown" % [found, (_view.get("clues", []) as Array).size()], 11, MUTED))
	var card: Dictionary = _view.get("data_card", {})
	if not card.is_empty():
		column.add_child(HSeparator.new())
		column.add_child(_wrap("DATA CARD · %s · %s" % [String(card.get("title", "")).to_upper(), String(card.get("evidence", "")).to_upper()], 12, MUSTARD))
		column.add_child(_wrap(String(card.get("plain", "")), 12, IVORY))
		column.add_child(_wrap("For Aurora: " + String(card.get("for_aurora", {}).get("text", "")), 12, MUTED))
		column.add_child(_wrap("Limits: " + String(card.get("limits", "")), 11, MUTED))
	return column

func _render_decision() -> Control:
	var column := _column("YOUR DECISION", 0)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var step: Dictionary = _view.get("step", {})
	if bool(_view.get("first_time", false)):
		_render_first_time(column)
	if bool(_view.get("committed", false)):
		column.add_child(_wrap("✓ LOCKED IN · this step is already recorded. Retry the checkpoint to change it.", 14, GREEN))
	var prerequisite := String(_view.get("prerequisite_reason", ""))
	if not prerequisite.is_empty():
		column.add_child(_wrap("WAITING · " + prerequisite, 14, MUSTARD))
	column.add_child(_wrap(String(step.get("title", "")).to_upper(), 15, CYAN))
	var locked := bool(_view.get("committed", false))
	match String(step.get("kind", "")):
		"choice": _render_choice(column, step, locked)
		"assign": _render_assign(column, step, locked)
		"select_many": _render_select_many(column, step, locked)
		"number": _render_number(column, step, locked)
		"route": _render_route(column, step, locked)
		"dial": _render_dial(column, step, locked)
		"lock": _render_lock(column, step, locked)
		"procedure": _render_procedure(column, step, locked)
		"checks": _render_checks(column, step, locked)
		"settings": _render_settings(column, step, locked)
		"confirm": _render_confirm(column, step, locked)
	_render_poll(column)
	return column

func _render_first_time(column: VBoxContainer) -> void:
	var card: Dictionary = _view.get("puzzle", {}).get("first_time_card", {})
	if card.is_empty():
		return
	var box := _card_box(true, true)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 4)
	box.add_child(inner)
	inner.add_child(_wrap("FIRST TIME · " + String(card.get("title", "")).to_upper(), 14, MUSTARD))
	inner.add_child(_wrap(String(card.get("purpose", "")), 13, IVORY))
	var index := 1
	for line in card.get("steps", []):
		inner.add_child(_wrap("%d. %s" % [index, String(line)], 13, IVORY))
		index += 1
	var how_to := String(card.get("how_to", ""))
	if not how_to.is_empty() and hint_player != null:
		var watch := _button("WATCH HOW · " + String(HowToCard.lesson(how_to).get("title", "")).to_upper(), "WatchHowTo")
		watch.pressed.connect(func() -> void: hint_player.show_how_to(how_to))
		inner.add_child(watch)
	var got_it := _button("GOT IT", "FirstTime")
	got_it.pressed.connect(dismiss_first_time)
	inner.add_child(got_it)
	column.add_child(box)

func _render_choice(column: VBoxContainer, step: Dictionary, locked: bool) -> void:
	var chosen := String(_view.get("selection", {}).get("option", ""))
	if step.has("sent"):
		column.add_child(_wrap("SENT · %s" % " ".join(Array(String(step.sent).split(""))), 16, IVORY))
	for option in step.get("options", []):
		var id := String(option.get("id", ""))
		var text := "%s%s\n%s" % ["● " if chosen == id else "○ ", String(option.get("label", "")), String(option.get("detail", ""))]
		for field in option.get("fields", {}):
			text += "\n%s: %s" % [String(field), String(option.fields[field])]
		column.add_child(_option_button(text, "Choice_option_" + id, chosen == id, locked, func() -> void: choose("option", id)))

func _render_assign(column: VBoxContainer, step: Dictionary, locked: bool) -> void:
	var selection: Dictionary = _view.get("selection", {})
	column.add_child(_wrap("Select a name, then a board. Each name needs one board.", 12, MUTED))
	var names := HFlowContainer.new()
	names.add_theme_constant_override("h_separation", 6)
	names.add_theme_constant_override("v_separation", 6)
	column.add_child(names)
	for person in step.get("people", []):
		var id := String(person)
		var board := String(selection.get(id, ""))
		var role: Dictionary = PuzzleScript.role(id)
		var text := "%s%s\n%s" % ["▶ " if _selected_person == id else "", String(role.get("name", id)), ("on " + board) if not board.is_empty() else "no board yet"]
		names.add_child(_option_button(text, "Choice_person_" + id, _selected_person == id or not board.is_empty(), locked, func() -> void:
			_selected_person = id
			_focus_name = "Choice_person_" + id
			_render()))
	for board in step.get("boards", []):
		var board_id := String(board.get("id", ""))
		var box := _card_box(false, true)
		var inner := VBoxContainer.new()
		inner.add_theme_constant_override("separation", 4)
		box.add_child(inner)
		var seated: Array = []
		for person in selection:
			if String(selection[person]) == board_id:
				seated.append(String(PuzzleScript.role(String(person)).get("name", person)))
		inner.add_child(_wrap("%s · %d of %d seats · %s" % [String(board.get("label", "")), seated.size(), int(board.get("seats", 0)), ", ".join(seated) if not seated.is_empty() else "empty"], 13, IVORY))
		var place := _button("PLACE %s HERE" % (String(PuzzleScript.role(_selected_person).get("name", "")).to_upper() if not _selected_person.is_empty() else "THE SELECTED NAME"), "Choice_board_" + board_id)
		place.disabled = locked or _selected_person.is_empty()
		place.pressed.connect(func() -> void:
			var person := _selected_person
			_selected_person = ""
			choose(person, board_id))
		inner.add_child(place)
		column.add_child(box)
	if not selection.is_empty() and not locked:
		var clear := _button("TAKE A NAME OFF ITS BOARD", "Choice_unassign")
		clear.pressed.connect(func() -> void:
			if not _selected_person.is_empty():
				var person := _selected_person
				_selected_person = ""
				choose(person, ""))
		clear.disabled = _selected_person.is_empty()
		column.add_child(clear)

func _render_select_many(column: VBoxContainer, step: Dictionary, locked: bool) -> void:
	var selection: Dictionary = _view.get("selection", {})
	column.add_child(_wrap("Tick everything that belongs. Untick to change your mind.", 12, MUTED))
	for item in step.get("items", []):
		var id := String(item.get("id", ""))
		var ticked := bool(selection.get(id, false))
		var text := "%s %s\n%s" % ["☑" if ticked else "☐", String(item.get("label", "")), String(item.get("detail", ""))]
		column.add_child(_option_button(text, "Choice_%s_%s" % [id, str(not ticked)], ticked, locked, func() -> void: choose(id, not ticked)))

func _render_number(column: VBoxContainer, step: Dictionary, locked: bool) -> void:
	var number: Dictionary = step.get("number", {})
	var selection: Dictionary = _view.get("selection", {})
	var readings: Dictionary = _view.get("readings", {})
	column.add_child(_wrap("Departure battery %s · outward allowance %s · return allowance %s" % [_amount(readings.get("capacity", 0)), _amount(readings.get("allowance", 0)), _amount(readings.get("allowance", 0))], 13, IVORY))
	column.add_child(_wrap("Formula: " + String(step.get("formula", "")), 12, MUTED))
	_render_stepper(column, String(number.get("label", "")), "value", selection.get("value", null), number, String(number.get("unit", "")), locked)

func _render_route(column: VBoxContainer, step: Dictionary, locked: bool) -> void:
	var selection: Dictionary = _view.get("selection", {})
	var readings: Dictionary = _view.get("readings", {})
	var chosen := String(selection.get("route", ""))
	var battery := float(readings.get("capacity", 0))
	for route in step.get("routes", []):
		var id := String(route.get("id", ""))
		var allowance := float(route.get("allowance", 0))
		var after := battery - 2.0 * allowance
		var text := "%s%s · %d° · %s units each way\n%s\nBattery %s − %s − %s = %s%s" % ["● " if chosen == id else "○ ", String(route.get("label", "")), int(route.get("slope", 0)), _amount(allowance), String(route.get("detail", "")), _amount(battery), _amount(allowance), _amount(allowance), _amount(after), "" if int(route.get("slope", 0)) <= 15 else "  ·  slope above the 15° limit"]
		column.add_child(_option_button(text, "Choice_route_" + id, chosen == id, locked, func() -> void: choose("route", id)))
	if not chosen.is_empty():
		var reserve: Dictionary = step.get("reserve", {})
		_render_stepper(column, String(reserve.get("label", "")), "reserve", selection.get("reserve", null), reserve, "units", locked)
		column.add_child(_wrap("Minimum reserve: %s units. The return stays in the departure budget." % _amount(readings.get("return_reserve", 2)), 12, MUTED))

func _render_stepper(column: VBoxContainer, label: String, field: String, value, bounds: Dictionary, unit: String, locked: bool) -> void:
	column.add_child(_wrap(label, 13, CYAN))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	column.add_child(row)
	var step_size := float(bounds.get("step", 1))
	var current := float(value) if value != null else float(bounds.get("min", 0))
	var minus := _button("−%s" % _amount(step_size), "Choice_%s_%s" % [field, _amount(current - step_size)])
	minus.disabled = locked
	minus.pressed.connect(func() -> void: choose(field, current - step_size))
	row.add_child(minus)
	var shown := _label("%s %s" % [_amount(current) if value != null else "—", unit], 22, IVORY)
	shown.custom_minimum_size.x = 120
	shown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(shown)
	var plus := _button("+%s" % _amount(step_size), "Choice_%s_%s" % [field, _amount(current + step_size)])
	plus.disabled = locked
	plus.pressed.connect(func() -> void: choose(field, current + step_size))
	row.add_child(plus)
	if value == null:
		row.add_child(_label("SET IT", 11, MUSTARD))

func _render_dial(column: VBoxContainer, step: Dictionary, locked: bool) -> void:
	var dial: Dictionary = step.get("dial", {})
	var selection: Dictionary = _view.get("selection", {})
	var bearing := float(selection.get("bearing", 0.0))
	var has_bearing := selection.has("bearing")
	var reading: Dictionary = PuzzleScript.dial_reading(_target_id, bearing) if has_bearing else {"strength": "—", "obstruction": ""}
	column.add_child(_wrap(String(dial.get("label", "")) + " · " + String(dial.get("reading_label", "")), 12, MUTED))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	column.add_child(row)
	for delta in [-float(dial.get("coarse", 10)), -float(dial.get("fine", 1))]:
		var button := _button("%s%s" % [_amount(delta), String(dial.get("unit", "°"))], "Choice_bearing_%s" % _amount(bearing + delta))
		button.disabled = locked
		var d: float = float(delta)
		button.pressed.connect(func() -> void: choose("bearing", bearing + d))
		row.add_child(button)
	var shown := _label("%s%s" % [_amount(bearing) if has_bearing else "—", String(dial.get("unit", "°"))], 26, IVORY)
	shown.custom_minimum_size.x = 110
	shown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(shown)
	for delta in [float(dial.get("fine", 1)), float(dial.get("coarse", 10))]:
		var button := _button("+%s%s" % [_amount(delta), String(dial.get("unit", "°"))], "Choice_bearing_%s" % _amount(bearing + delta))
		button.disabled = locked
		var d: float = float(delta)
		button.pressed.connect(func() -> void: choose("bearing", bearing + d))
		row.add_child(button)
	var strength := String(reading.get("strength", ""))
	var obstruction := String(reading.get("obstruction", ""))
	var good := has_bearing and obstruction.is_empty() and strength not in ["no signal", "—"]
	column.add_child(_wrap("SIGNAL · %s%s" % [strength.to_upper(), " · NO OBSTRUCTION" if good else ""], 14, GREEN if good else (MUSTARD if has_bearing else MUTED)))
	if not obstruction.is_empty():
		column.add_child(_wrap("⚠ " + obstruction, 12, MUSTARD))
	column.add_child(_wrap("Presets (assisted alternative, rewarded equally):", 12, MUTED))
	var presets := HFlowContainer.new()
	presets.add_theme_constant_override("h_separation", 6)
	presets.add_theme_constant_override("v_separation", 6)
	column.add_child(presets)
	for preset in step.get("presets", []):
		var id := String(preset.get("id", ""))
		var selected := String(selection.get("preset", "")) == id
		presets.add_child(_option_button("%s%s\n%s%s" % ["● " if selected else "○ ", String(preset.get("label", "")), _amount(float(preset.get("bearing", 0))), String(dial.get("unit", "°"))], "Choice_preset_" + id, selected, locked, func() -> void: choose("preset", id)))

func _render_lock(column: VBoxContainer, step: Dictionary, locked: bool) -> void:
	var selection: Dictionary = _view.get("selection", {})
	var lock: Dictionary = step.get("lock", {})
	column.add_child(_wrap(String(lock.get("window_label", "")), 12, MUTED))
	var progress := _label(_lock_text(selection), 16, GREEN if bool(selection.get("locked", false)) else IVORY)
	progress.name = "LockProgress"
	column.add_child(progress)
	if bool(_settings.get("timer_free", true)):
		var tap := _button("TAP TO CONFIRM THE LOCK · ASSISTED", "Choice_tap_true")
		tap.disabled = locked or bool(selection.get("locked", false))
		tap.pressed.connect(func() -> void: tap_lock())
		column.add_child(tap)
	else:
		var hold := _button("HOLD TO LOCK · %d s" % int(lock.get("hold_seconds", 3)), "HoldLock")
		hold.disabled = locked or bool(selection.get("locked", false))
		hold.button_down.connect(func() -> void: _holding = true)
		hold.button_up.connect(func() -> void:
			_holding = false
			_model().select(_target_id, "release", true)
			_render())
		column.add_child(hold)
		column.add_child(_wrap("Assistance off: hold for the full count. Releasing early resets the count; nothing else is lost.", 11, MUTED))

func _lock_text(selection: Dictionary) -> String:
	if bool(selection.get("locked", false)):
		return "✓ STABLE LOCK · both legs held"
	return "Lock progress: %.1f of %d s" % [float(selection.get("progress", 0.0)), int(_view.get("step", {}).get("lock", {}).get("hold_seconds", 3))]

func _render_procedure(column: VBoxContainer, step: Dictionary, locked: bool) -> void:
	var order: Array = _view.get("selection", {}).get("sequence", [])
	column.add_child(_wrap("PROCEDURE CARD · Step → Action → ✓ VERIFY · tap the next step in order", 12, MUTED))
	var index := 0
	for entry in step.get("steps", []):
		var id := String(entry.get("id", ""))
		var done := index < order.size()
		var next := index == order.size()
		var mark := "✓" if done else ("▶" if next else "○")
		var text := "%s %d. %s\n    ✓ VERIFY: %s" % [mark, index + 1, String(entry.get("label", "")), String(entry.get("verify", ""))]
		var button := _option_button(text, "Choice_step_" + id, done, locked or done, func() -> void: choose("step", id))
		column.add_child(button)
		index += 1
	var distractors: Array = step.get("distractors", [])
	if not distractors.is_empty():
		column.add_child(_wrap("Other controls in reach:", 12, MUTED))
		for entry in distractors:
			var id := String(entry.get("id", ""))
			column.add_child(_option_button("◌ " + String(entry.get("label", "")), "Choice_step_" + id, false, locked, func() -> void: choose("step", id)))
	if not order.is_empty() and not locked:
		var restart := _button("START THE CARD AGAIN", "Choice_reset_true")
		restart.pressed.connect(func() -> void: choose("reset", true))
		column.add_child(restart)

func _render_checks(column: VBoxContainer, step: Dictionary, locked: bool) -> void:
	var selection: Dictionary = _view.get("selection", {})
	var readings: Dictionary = _view.get("readings", {})
	for check in step.get("checks", []):
		var id := String(check.get("id", ""))
		var ticked := bool(selection.get(id, false))
		var actual := _reading_text(String(check.get("reads", "")), readings)
		var text := "%s %s\n    reading: %s" % ["☑" if ticked else "☐", String(check.get("label", "")), actual]
		column.add_child(_option_button(text, "Choice_%s_%s" % [id, str(not ticked)], ticked, locked, func() -> void: choose(id, not ticked)))

func _reading_text(reads: String, readings: Dictionary) -> String:
	match reads:
		"crew_home": return "%d at Aurora" % int(readings.get("crew_home", 0))
		"seeds": return "founder reserve %d · vault specimens stored %d" % [int(readings.get("reserve30", 0)), int(readings.get("vault_stored", 0))]
		"pressure": return "independent gauge steady" if bool(readings.get("pressure", false)) else "not yet verified"
		"temperature": return "heat MIN holding, garden alive" if bool(readings.get("temperature", false)) else "garden not holding"
		"cotton": return "alive in Tara's bay" if bool(readings.get("cotton", false)) else "not alive"
	return str(readings.get(reads, ""))

func _render_settings(column: VBoxContainer, step: Dictionary, locked: bool) -> void:
	var selection: Dictionary = _view.get("selection", {})
	for entry in step.get("fields", []):
		var field := String(entry.get("id", ""))
		column.add_child(_wrap(String(entry.get("label", "")), 13, CYAN))
		var row := HFlowContainer.new()
		row.add_theme_constant_override("h_separation", 6)
		row.add_theme_constant_override("v_separation", 6)
		column.add_child(row)
		for option in entry.get("options", []):
			var value = option.get("value")
			var selected: bool = selection.has(field) and typeof(selection[field]) == typeof(value) and selection[field] == value
			if not selected and selection.has(field) and (value is int or value is float) and (selection[field] is int or selection[field] is float):
				selected = is_equal_approx(float(selection[field]), float(value))
			var picked = value
			var button := _option_button("%s%s\n%s" % ["● " if selected else "○ ", String(option.get("label", "")), String(option.get("cost", ""))], "Choice_%s_%s" % [field, str(value)], selected, locked, func() -> void: choose(field, picked))
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(button)
		if not selection.has(field):
			row.add_child(_label("CHOOSE", 11, MUSTARD))

func _render_confirm(column: VBoxContainer, step: Dictionary, locked: bool) -> void:
	var confirmed := bool(_view.get("selection", {}).get("confirmed", false))
	column.add_child(_wrap("READ-BACK · " + String(step.get("readback", "")), 14, IVORY))
	column.add_child(_option_button(("● " if confirmed else "○ ") + "READ BACK AND CONFIRMED", "Choice_confirmed_true", confirmed, locked or confirmed, func() -> void: choose("confirmed", true)))

func _render_poll(column: VBoxContainer) -> void:
	var step: Dictionary = _view.get("step", {})
	var roles: Array = step.get("poll", [])
	if roles.is_empty():
		return
	column.add_child(HSeparator.new())
	var accepted := bool(_last_try.get("accepted", false))
	var reason := String(_notice) if _notice_kind == "held" else ""
	var advisory := String(_notice.trim_prefix("Accepted with an advisory: ")) if _notice_kind == "advisory" else ""
	var statuses: Array = _model().poll_status(_target_id, accepted, reason, advisory)
	column.add_child(_wrap("GO / NO-GO POLL · %s" % ("each role signs its own station" if bool(_settings.get("class_mode", false)) else "summarised in one confirm"), 12, MUTED))
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 6)
	row.add_theme_constant_override("v_separation", 6)
	column.add_child(row)
	for status in statuses:
		var mark: String = {"GO": "✓", "ADVISORY": "▲", "NO-GO": "⬟", "HOLD": "…"}.get(String(status.status), "…")
		var color: Color = {"GO": GREEN, "ADVISORY": MUSTARD, "NO-GO": RED, "HOLD": MUTED}.get(String(status.status), MUTED)
		var text := "%s %s · %s%s" % [mark, String(status.name).to_upper(), String(status.status), " · signed" if bool(status.signed) else ""]
		if bool(_settings.get("class_mode", false)) and not bool(status.signed):
			var role_id := String(status.role_id)
			var button := _button(text + "\nSIGN", "Sign_" + role_id)
			button.pressed.connect(func() -> void: sign(role_id))
			row.add_child(button)
		else:
			var chip := _label(" %s " % text, 12, color)
			chip.add_theme_stylebox_override("normal", _box(NAVY, color, 6, 1))
			row.add_child(chip)
		if not String(status.note).is_empty():
			column.add_child(_wrap("%s: %s" % [String(status.name), String(status.note)], 11, color))

func _render_preview() -> Control:
	var column := _column("TRY IT · NOTHING CHANGES YET", 330)
	var scene: Dictionary = _view.get("scene", {})
	var before: Dictionary = _last_try.get("before", {})
	var after: Dictionary = _last_try.get("after", {})
	if _last_try.is_empty():
		column.add_child(_wrap("Set the decision, then TRY IT to see before → after from the same simulation that locks in.", 12, MUTED))
	elif bool(_last_try.get("accepted", false)):
		column.add_child(_wrap("✓ ACCEPTED · before → after", 14, GREEN))
	elif bool(_last_try.get("incomplete", false)):
		column.add_child(_wrap("… NOT YET · " + String(_last_try.get("reason", "")), 13, MUSTARD))
	else:
		column.add_child(_wrap("⚠ HELD · the preview stopped before anything changed", 14, MUSTARD))
	if not before.is_empty():
		_render_before_after(column, before, after)
	var summary: Array = _last_try.get("ledger_summary", [])
	for line in summary:
		column.add_child(_wrap(String(line), 11, IVORY))
	column.add_child(HSeparator.new())
	# Less text on screen: the rules, risk card and first idea sit behind one toggle, closed by default.
	var rules_toggle := _button(("▾ " if _rules_open else "▸ ") + "MISSION RULES AND RISK", "MissionRulesToggle")
	rules_toggle.pressed.connect(func() -> void:
		_rules_open = not _rules_open
		_render())
	column.add_child(rules_toggle)
	if _rules_open:
		for rule in scene.get("flight_rules", []):
			column.add_child(_wrap(String(rule), 11, IVORY))
		var risk: Dictionary = scene.get("risk", {})
		if not risk.is_empty():
			var level := String(risk.get("level", ""))
			column.add_child(_wrap("RISK CARD · %s · likelihood %d × consequence %d · %s" % [String(risk.get("title", "")), int(risk.get("likelihood", 0)), int(risk.get("consequence", 0)), level], 11, RED if level.begins_with("HIGH") else MUSTARD))
		column.add_child(_wrap("Reasonable first idea: " + String(scene.get("wrong_idea", "")), 11, MUTED))
	column.add_child(HSeparator.new())
	_render_hints(column)
	return column

func _render_before_after(column: VBoxContainer, before: Dictionary, after: Dictionary) -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	column.add_child(grid)
	var resources_before: Dictionary = before.get("resources", {})
	var resources_after: Dictionary = after.get("resources", {})
	for row in HOME_ROWS:
		var key := String(row[0])
		grid.add_child(_label(String(row[1]), 12, MUTED))
		var cap := "/%d" % int(resources_before.get(String(row[2]), 0)) if not String(row[2]).is_empty() and resources_before.has(String(row[2])) else ""
		var text := "%s%s" % [_amount(resources_before.get(key, 0)), cap]
		var color := IVORY
		if not resources_after.is_empty():
			var delta := float(resources_after.get(key, 0)) - float(resources_before.get(key, 0))
			text += "  →  %s%s  (%s)" % [_amount(resources_after.get(key, 0)), cap, _signed(delta)]
			color = IVORY if is_zero_approx(delta) else (GREEN if delta > 0 else MUSTARD)
		grid.add_child(_label(text, 12, color))
	var readings_before: Dictionary = before.get("readings", {})
	var readings_after: Dictionary = after.get("readings", {})
	for pair in [["energy", "Rover battery"], ["elapsed_hours", "Journey hours"], ["local_hops", "Repeater hops"], ["earth_leg", "Earth leg"], ["crew_home", "People at Aurora"]]:
		var key := String(pair[0])
		grid.add_child(_label(String(pair[1]), 12, MUTED))
		var text := _reading_value(readings_before.get(key, ""))
		if not readings_after.is_empty():
			text += "  →  " + _reading_value(readings_after.get(key, ""))
		grid.add_child(_label(text, 12, IVORY))

func _reading_value(value) -> String:
	if value is float or value is int:
		return _amount(value)
	return str(value)

func _render_hints(column: VBoxContainer) -> void:
	column.add_child(_wrap("HINTS · they never change your ending · H", 12, CYAN))
	for hint in _view.get("hints", []):
		column.add_child(_wrap("%s · %s" % [String(hint.label), String(hint.text)], 12, IVORY))
	var shown: int = (_view.get("hints", []) as Array).size()
	var total := int(_view.get("hints_total", 0))
	var hint := _button("SHOW NEXT HINT · %d OF %d" % [shown, total] if shown < total else "ALL HINTS SHOWN", "Hint")
	hint.disabled = shown >= total
	hint.pressed.connect(func() -> void: reveal_hint())
	column.add_child(hint)
	if shown >= total and total > 0:  # the aha is the answer: only after every hint
		column.add_child(_wrap("Aha: " + String(_view.get("scene", {}).get("aha", "")), 11, MUTED))

func _render_footer() -> void:
	var reason := _commit_reason()
	var color: Color = {"ok": GREEN, "advisory": MUSTARD, "held": MUSTARD, "info": MUTED}.get(_notice_kind, MUTED)
	var text := _notice if not _notice.is_empty() else (reason if not reason.is_empty() else "Ready. Space locks in, then Space again confirms.")
	var status := _wrap(("⚠ " if _notice_kind == "held" else "") + text, 14, color if not _notice.is_empty() else (MUSTARD if not reason.is_empty() else GREEN))
	status.name = "PanelStatus"
	_content.add_child(status)
	var row := HFlowContainer.new()
	row.alignment = FlowContainer.ALIGNMENT_END
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 6)
	_content.add_child(row)
	var undo_button := _button("UNDO", "Undo")
	undo_button.disabled = bool(_view.get("committed", false)) or (_view.get("selection", {}) as Dictionary).is_empty()
	undo_button.pressed.connect(func() -> void: undo())
	row.add_child(undo_button)
	var hint := _button("HINT · H", "HintFooter")
	hint.pressed.connect(func() -> void: reveal_hint())
	row.add_child(hint)
	var try_button := _button("TRY IT · NOTHING CHANGES YET", "Try")
	try_button.disabled = bool(_view.get("committed", false))
	try_button.pressed.connect(func() -> void: try_it())
	row.add_child(try_button)
	var commit := _button("LOCK IN · SPACE", "Commit")
	commit.disabled = not reason.is_empty()
	commit.tooltip_text = reason if not reason.is_empty() else "Opens the confirmation. Space or Enter confirms."
	commit.pressed.connect(func() -> void: request_commit())
	row.add_child(commit)
	var close_button := _button("CLOSE · ESC", "ClosePanel")
	close_button.pressed.connect(close)
	row.add_child(close_button)

func _render_confirmation() -> void:
	var step: Dictionary = _view.get("step", {})
	var box := _card_box(false, true)
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_child(box)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 8)
	box.add_child(inner)
	inner.add_child(_wrap("LOCK IN · " + String(step.get("title", "")).to_upper(), 20, MUSTARD))
	inner.add_child(_wrap("This records the decision for this attempt. RETRY restores the checkpoint before it.", 15, IVORY))
	inner.add_child(_wrap("Decision: " + _payload_sentence(_last_try.get("payload", {})), 14, CYAN))
	var before: Dictionary = _last_try.get("before", {})
	var after: Dictionary = _last_try.get("after", {})
	if not before.is_empty() and not after.is_empty():
		inner.add_child(_wrap("Home after: " + _summary(after.get("resources", {})) + "   (now " + _summary(before.get("resources", {})) + ")", 13, IVORY))
		inner.add_child(_wrap("Rover after: battery %s · journey %s h · hops %s · Earth leg %s" % [_amount(after.readings.get("energy", 0)), _amount(after.readings.get("elapsed_hours", 0)), str(after.readings.get("local_hops", 0)), String(after.readings.get("earth_leg", ""))], 13, IVORY))
	var statuses: Array = _model().poll_status(_target_id, true, "", String(_notice.trim_prefix("Accepted with an advisory: ")) if _notice_kind == "advisory" else "")
	var poll: Array = []
	for status in statuses:
		poll.append("%s: %s" % [String(status.name), String(status.status)])
	if not poll.is_empty():
		inner.add_child(_wrap("Poll · " + " · ".join(poll), 13, GREEN))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 8)
	_content.add_child(row)
	var back := _button("BACK · ESC", "CancelCommit")
	back.pressed.connect(cancel_confirm)
	row.add_child(back)
	var confirm := _button("CONFIRM · SPACE", "ConfirmCommit")
	confirm.pressed.connect(func() -> void: confirm_commit())
	row.add_child(confirm)

# --- Text helpers ------------------------------------------------------------

func _payload_sentence(payload: Dictionary) -> String:
	var parts: Array = []
	for key in payload:
		var value = payload[key]
		if value is Array:
			parts.append("%s: %s" % [String(key).replace("_", " "), ", ".join(value.map(func(item): return str(item)))])
		else:
			parts.append("%s: %s" % [String(key).replace("_", " "), str(value)])
	return " · ".join(parts) if not parts.is_empty() else "confirmed"

func _summary(values: Dictionary) -> String:
	return "battery %s · air %s · garden %s · crop %s · food %s" % [_amount(values.get("E", 0)), _amount(values.get("A", 0)), _amount(values.get("H", 0)), _amount(values.get("C", 0)), _amount(values.get("R", 0))]

func _amount(value) -> String:
	var number := float(value)
	if is_equal_approx(number, round(number)):
		return str(int(round(number)))
	return ("%.4f" % number).rstrip("0")

func _signed(value: float) -> String:
	if is_zero_approx(value):
		return "±0"
	return ("+" if value > 0 else "−") + _amount(absf(value))

# --- State helpers -------------------------------------------------------------

func _model() -> RefCounted:
	return _route.chapter8()

func _committed() -> bool:
	return bool(_view.get("committed", false))

func _refresh_view() -> void:
	_view = _route.chapter8_view(_target_id)

func _selection_key() -> String:
	return JSON.stringify(_model().selection(_target_id))

func _commit_reason() -> String:
	if _view.is_empty():
		_refresh_view()
	if bool(_view.get("committed", false)):
		return "This step is already locked in."
	var prerequisite := String(_view.get("prerequisite_reason", ""))
	if not prerequisite.is_empty():
		return prerequisite
	var attempt: Dictionary = _view.get("attempt", {})
	if not bool(attempt.get("accepted", false)):
		return String(attempt.get("reason", "Finish the decision first."))
	if _tried_key.is_empty() or _tried_key != _selection_key():
		return "Press TRY IT to check this decision before locking it in."
	if bool(_settings.get("class_mode", false)):
		for role_id in _view.get("step", {}).get("poll", []):
			if not (_view.get("signed", []) as Array).has(role_id):
				return "%s has not signed the poll yet." % String(PuzzleScript.role(String(role_id)).get("name", role_id))
	return ""

func _hold(reason: String) -> Dictionary:
	_notice = reason
	_notice_kind = "held"
	_render()
	return {"accepted": false, "reason": reason}

## Family mode: H1 is offered after a rejected try. The hint is shown, never applied.
func _offer_first_hint() -> void:
	if bool(_settings.get("timer_free", true)) and (_view.get("hints", []) as Array).is_empty() and _model().attempts(_target_id) >= 1:
		var hint: Dictionary = _model().reveal_hint(_target_id)
		if bool(hint.get("accepted", false)):
			_notice += "\nHint H1 · " + String(hint.get("text", ""))

func _restore_focus() -> void:
	var target: Control = null
	if not _focus_name.is_empty():
		target = find_child(_focus_name.validate_node_name(), true, false) as Control
	if target == null or not target.is_visible_in_tree() or (target is BaseButton and (target as BaseButton).disabled):
		target = find_child("Try", true, false) as Control
	if target == null:
		target = find_child("ConfirmCommit", true, false) as Control
	if target != null:
		_focus_later(target)
	_focus_name = ""

func _focus_later(target: Control) -> void:
	_apply_focus.call_deferred(target)

func _apply_focus(target: Control) -> void:
	if is_instance_valid(target) and target.is_inside_tree() and not target.is_queued_for_deletion() and visible:
		target.grab_focus()

func _grab_first_focus() -> void:
	var first := find_child("FirstTime", true, false) as Control
	if first == null:
		for clue in _view.get("clues", []):
			if not bool(clue.get("found", false)):
				first = find_child("Clue_" + String(clue.get("id", "")), true, false) as Control
				break
	if first == null:
		first = find_child("Try", true, false) as Control
	if first != null:
		_focus_later(first)

func _layout() -> void:
	if _frame == null or not is_inside_tree():
		return
	_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_frame.offset_left = 12
	_frame.offset_top = 12
	_frame.offset_right = -12
	_frame.offset_bottom = -12

func _scale() -> float:
	return 1.5 if bool(_settings.get("large_text", false)) else 1.0

func _fs(size: int) -> int:
	return int(round(size * _scale()))

# --- Widget helpers ------------------------------------------------------------

func _option_button(text: String, node_name: String, selected: bool, disabled: bool, action: Callable) -> Button:
	var button := _button(text, node_name)
	button.toggle_mode = true
	button.button_pressed = selected
	button.disabled = disabled
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 52 * _scale()
	button.add_theme_font_size_override("font_size", _fs(12))
	if selected:
		for state in ["normal", "pressed", "disabled"]:
			button.add_theme_stylebox_override(state, UiDesign.button_style(Color("#1A2738"), true))
	button.pressed.connect(action)
	return button

func _scroll(column: Control, node_name: String) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = node_name
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = column.size_flags_horizontal
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	scroll.custom_minimum_size.x = column.custom_minimum_size.x + 12
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	return scroll

func _column(title: String, width: float) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	if width > 0:
		column.custom_minimum_size.x = width
	column.add_child(_wrap(title, 13, MUSTARD))
	return column

func _card_box(highlight: bool, available: bool) -> PanelContainer:
	var box := PanelContainer.new()
	var border := GREEN if highlight else (EDGE if available else Color(EDGE, 0.5))
	var style := _box(NAVY if available else Color("#0E1018"), border, 9, 1)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	box.add_theme_stylebox_override("panel", style)
	return box

func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", _fs(size))
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_override("font", UiDesign.font("subhead" if size >= 15 else "body"))  # Saira for titles, Inter for reading
	return label

func _wrap(text: String, size: int, color: Color) -> Label:
	var label := _label(text, size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size.x = 120
	return label

func _button(text: String, node_name: String) -> Button:
	var button := Button.new()
	button.name = node_name.validate_node_name()
	button.text = text
	button.custom_minimum_size = Vector2(0, MIN_TARGET)
	button.focus_mode = Control.FOCUS_ALL
	UiDesign.style_button(button)  # the house button: hairline at rest, gold leading bar on hover
	button.add_theme_font_size_override("font_size", _fs(13))
	button.add_theme_stylebox_override("pressed", UiDesign.button_style(NAVY, true))
	button.add_theme_color_override("font_pressed_color", IVORY)
	return button

func _box(fill: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(mini(radius, 6))  # sharper house corners
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style
