extends Control
class_name MissionTablePanel

## The P-02 Mission Table: four role cards, the station summary, the plan for
## the shifts this gate resolves, a live forecast and Preview / Commit.
##
## The panel edits only the route's P02MissionTable (the player's plan) and
## reads `route.mission_table_view`, whose forecasts come from the same
## ExpeditionSimulation function that commits. It never changes resources:
## a confirmed commit leaves through `commit_requested`, which the HUD sends to
## the physical P-02 operation. Space opens the commit confirmation and Space
## again confirms; Esc steps back. Every control is a focusable button of at
## least 44 px, and every state has a text cue as well as a colour.
##
## Crew modes (CrewModes): in Solo the four cards are public to the one
## player. In Class the cards column shows only who holds each note and
## whether it was read privately or shared; the facts appear only on the
## privacy hand-off (RoleCardHandoff) or a printed card, sharing requires a
## private read first, and the commit confirmation becomes the team plan:
## every role signs the exact plan before the operator locks it in.

signal commit_requested(target_id: String, plan: Dictionary)
signal opened(target_id: String)
signal closed(target_id: String)

const TableScript = preload("res://scripts/puzzles/p02_mission_table.gd")
const CrewScript = preload("res://scripts/crew/crew_modes.gd")
const HANDOFF_SCENE: PackedScene = preload("res://scenes/ui/role_card_handoff.tscn")
const INK := Color("#05060A")
const NAVY := Color("#1F2A44")
const NAVY_DEEP := Color("#0B1426")
const IVORY := Color("#ECEEF0")
const MUTED := Color("#A8B4C8")
const MUSTARD := Color("#F2C230")
const CYAN := Color("#20B8C9")
const GREEN := Color("#4CAF50")
const RED := Color("#E56B6F")
const MIN_TARGET := 44.0
const RESOURCE_ROWS := [
	["E", "Battery", "energy_capacity"],
	["A", "Air", "air_capacity"],
	["H", "Alo", "health_capacity"],
	["C", "Crop", "crop_capacity"],
	["W", "Water wall", "water_capacity"],
	["K", "Crates", "crate_capacity"],
	["Z", "Exposure", ""],
	["R", "Rations", ""],
]

var _route: RefCounted
var _target_id := ""
var _settings := {"large_text": false, "timer_free": true}
var _crew: Dictionary = {}
var _handoff: RoleCardHandoff
var _view: Dictionary = {}
var _previewed_key := ""
var _pinned: Dictionary = {}
var _confirming := false
var _notice := ""
var _task_time_left := 0.0
var _focus_name := ""
var _overlay: ColorRect
var _frame: PanelContainer
var _content: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Above the HUD's outpost readout (z 70): the table carries its own summary.
	z_index = 100
	_overlay = ColorRect.new()
	_overlay.color = Color(0.0, 0.01, 0.03, 0.82)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)
	_frame = PanelContainer.new()
	_frame.add_theme_stylebox_override("panel", _box(NAVY_DEEP, Color(0.13, 0.72, 0.78, 0.84), 14, 1))
	_frame.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_frame)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	_frame.add_child(margin)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 10)
	margin.add_child(_content)
	_handoff = HANDOFF_SCENE.instantiate() as RoleCardHandoff
	_handoff.name = "RoleCardHandoff"
	add_child(_handoff)
	_handoff.card_read.connect(_on_card_read)
	_handoff.finished.connect(_on_handoff_closed)
	_handoff.cancelled.connect(func() -> void: _on_handoff_closed([]))
	hide()
	get_viewport().size_changed.connect(_layout)

## Opens the table for one P-02 gate. `settings` carries large_text and
## timer_free from the accessibility settings and `crew` (CrewModes setting;
## Solo when absent).
func open(route: RefCounted, target_id: String, settings: Dictionary = {}) -> void:
	_route = route
	_target_id = target_id
	for key in settings:
		_settings[key] = settings[key]
	_crew = CrewScript.normalise(_settings.get("crew", {}))
	_confirming = false
	_notice = ""
	_previewed_key = ""
	_focus_name = ""
	show()
	_layout()
	_render()
	opened.emit(target_id)
	_grab_first_focus()

## Closes without committing anything.
func close() -> void:
	if not visible:
		return
	if _handoff != null and _handoff.is_open():
		_handoff.cancel()
	hide()
	_confirming = false
	closed.emit(_target_id)

func is_open() -> bool:
	return visible

func target_id() -> String:
	return _target_id

## The latest view the panel rendered (for tests and evidence probes).
func view() -> Dictionary:
	return _view.duplicate(true)

# --- Player actions (also called by tests) ---------------------------------

## Sets one plan field for one shift.
func choose(shift: int, field: String, value) -> Dictionary:
	var result: Dictionary = _table().set_choice(shift, field, value, _committed())
	_after_action(result, "Choice_%d_%s_%s" % [shift, field, str(value)])
	return result

## Shares one delivered role card with the crew. In Class mode the role's
## player must have read the note privately first.
func share_card(role_id: String) -> Dictionary:
	var result: Dictionary = _table().share(role_id, _committed(), _class_mode())
	if not bool(result.get("accepted", false)) and _class_mode() and not _card(role_id).get("read", false) and bool(_card(role_id).get("arrived", false)):
		result["reason"] = CrewScript.text("table", "share_requires_read", CrewScript.role_tokens(_crew, role_id))
	_after_action(result, "Share_" + role_id if not bool(result.get("accepted", false)) else "Read_" + role_id)
	return result

## Class mode: opens the privacy hand-off for one delivered note. The read
## receipt is recorded when the holder reveals it.
func read_card(role_id: String) -> bool:
	var card := _card(role_id)
	if card.is_empty() or not bool(card.get("arrived", false)):
		_notice = "%s's note arrives at shift %d." % [String(card.get("name", role_id)), int(card.get("arrives_shift", 1))] if not card.is_empty() else "Unknown role card: " + role_id
		_render()
		return false
	return _handoff.open([card], _crew, _settings)

## Class mode: passes every delivered note round, one holder at a time.
func read_all_cards() -> bool:
	var cards: Array = []
	for card in _view.get("cards", []):
		if bool(card.get("arrived", false)):
			cards.append(card)
	return _handoff.open(cards, _crew, _settings)

## The hand-off screen this table owns (for the HUD, tests and captures).
func handoff() -> RoleCardHandoff:
	return _handoff

## Class mode: one role signs the exact plan on the table.
func sign_off(role_id: String) -> Dictionary:
	var result: Dictionary = _table().sign_off(role_id, _target_id, _committed())
	if bool(result.get("accepted", false)):
		var next := _unsigned_roles_after(role_id)
		_after_action(result, "SignOff_" + String(next[0]) if not next.is_empty() else "ConfirmCommit")
	else:
		_after_action(result, "SignOff_" + role_id)
	return result

## Roles whose signature matches the plan on the table right now.
func signed_roles() -> Array:
	return _table().signed_roles(_target_id, _committed())

func crew() -> Dictionary:
	return _crew.duplicate(true)

## Runs the current plan through the shared simulation and records that this
## exact plan was previewed, which Commit requires.
func preview() -> Dictionary:
	_refresh_view()
	var forecast: Dictionary = _view.get("gate_preview", {})
	if forecast.is_empty():
		var reason := String(_view.get("block_reason", "Set every field before previewing."))
		_notice = reason if not reason.is_empty() else "Set every field before previewing."
		_render()
		return {"accepted": false, "reason": _notice}
	if not bool(forecast.get("accepted", false)):
		_notice = "Preview rejected: " + String(forecast.get("reason", ""))
		_render()
		return {"accepted": false, "reason": _notice}
	_previewed_key = _plan_key()
	_notice = "Preview ready. Read the forecast, then commit with Space."
	_focus_name = "Commit"
	_render()
	return {"accepted": true, "reason": _notice, "forecast": forecast}

## Opens the commit confirmation when the plan can be committed.
func request_commit() -> Dictionary:
	var reason := _commit_reason()
	if not reason.is_empty():
		_notice = reason
		_render()
		return {"accepted": false, "reason": reason}
	_confirming = true
	var unsigned := _unsigned_roles()
	_focus_name = "SignOff_" + String(unsigned[0]) if _class_mode() and not unsigned.is_empty() else "ConfirmCommit"
	_render()
	return {"accepted": true, "reason": "Confirm to commit." if not _class_mode() else CrewScript.text("team_plan", "instruction")}

## Confirms the open confirmation: closes the table (resuming the expedition)
## and emits the plan once.
func confirm_commit() -> Dictionary:
	if not _confirming:
		return {"accepted": false, "reason": "Open the commit confirmation first."}
	var reason := _commit_reason()
	if not reason.is_empty():
		_confirming = false
		_notice = reason
		_render()
		return {"accepted": false, "reason": reason}
	if _class_mode():
		var unsigned := _unsigned_roles()
		if not unsigned.is_empty():
			_notice = CrewScript.text("team_plan", "operator_blocked", {"signed": str(CrewScript.ROLE_ORDER.size() - unsigned.size()), "total": str(CrewScript.ROLE_ORDER.size())})
			_focus_name = "SignOff_" + String(unsigned[0])
			_render()
			return {"accepted": false, "reason": _notice}
	var plan: Dictionary = _table().plan_for_gate(_target_id)
	var id := _target_id
	close()
	commit_requested.emit(id, plan)
	return {"accepted": true, "target_id": id, "plan": plan}

## Leaves the confirmation without committing.
func cancel_confirm() -> void:
	_confirming = false
	_focus_name = "Commit"
	_render()

## Reveals the next progressive hint.
func reveal_hint() -> Dictionary:
	var result: Dictionary = _table().next_hint()
	_after_action(result, "Hint")
	return result

## Copies an unlocked worked plan into the uncommitted shifts.
func use_worked_plan(plan_id: String) -> Dictionary:
	if not _table().unlocked_worked_plans().has(plan_id):
		return {"accepted": false, "reason": "Reveal the hints that unlock this worked plan first."}
	var result: Dictionary = _table().apply_worked_plan(plan_id, _committed())
	_after_action(result, "Worked_" + plan_id)
	return result

## Keeps the current whole-night projection as Plan A for side-by-side review.
func pin_plan_a() -> void:
	var projection: Dictionary = _view.get("night_projection", {})
	if projection.is_empty() or not bool(projection.get("accepted", false)):
		_notice = "Plan at least the next shift before pinning a comparison."
	else:
		_pinned = {"final": projection.get("final_state", {}).duplicate(), "through": int(_view.get("planned_through", 0)), "ending": String(projection.get("ending", "")), "blackouts": int(projection.get("snapshot", {}).get("blackout_count", 0))}
		_notice = "Plan A pinned. Change the plan to compare it with Plan B."
	_focus_name = "PinPlanA"
	_render()

## Starts the PUMP or STACK task; timed unless timer-free assistance is on.
func start_task() -> Dictionary:
	var result: Dictionary = _table().start_alarm_task(bool(_settings.get("timer_free", true)))
	if bool(result.get("accepted", false)):
		_task_time_left = float(result.get("timer_seconds", 0))
	_after_action(result, "TaskStep_0")
	return result

## Confirms one valve or bundle step of the running task.
func task_step(step_index: int) -> Dictionary:
	var result: Dictionary = _table().task_step(step_index)
	_after_action(result, "TaskStep_%d" % (step_index + 1))
	return result

## Ends the running task with its current progress.
func end_task() -> Dictionary:
	var result: Dictionary = _table().resolve_alarm_task()
	_task_time_left = 0.0
	_after_action(result, "Preview")
	return result

# --- Input -----------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not visible or (_handoff != null and _handoff.is_open()):
		return
	var commit_key: bool = event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_SPACE
	var commit_pad: bool = event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_Y
	var back_key: bool = event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE
	var back_pad: bool = event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B
	if commit_key or commit_pad:
		if _confirming:
			confirm_commit()
		else:
			request_commit()
		get_viewport().set_input_as_handled()
	elif back_key or back_pad:
		if _confirming:
			cancel_confirm()
		else:
			close()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not visible or _task_time_left <= 0.0:
		return
	var alarm: Dictionary = _table().alarm_state()
	if String(alarm.get("state", "")) != TableScript.TASK_RUNNING or bool(alarm.get("assisted", true)):
		_task_time_left = 0.0
		return
	var previous := ceili(_task_time_left)
	_task_time_left = maxf(0.0, _task_time_left - delta)
	if _task_time_left <= 0.0:
		var result: Dictionary = _table().resolve_alarm_task()
		_notice = "Time. " + String(result.get("reason", ""))
		_render()
	elif ceili(_task_time_left) != previous:
		var timer := find_child("TaskTimer", true, false) as Label
		if timer != null:
			timer.text = "%d s left · the task resolves with the steps done" % ceili(_task_time_left)

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
	_render_header()
	if _confirming and _class_mode():
		_render_team_plan()
	elif _confirming:
		_render_confirmation()
	else:
		# Each column scrolls on its own, so focusing a card never scrolls the
		# plan or the forecast out of view.
		var columns := HBoxContainer.new()
		columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
		columns.add_theme_constant_override("separation", 14)
		_content.add_child(columns)
		columns.add_child(_scroll(_render_cards(), "CardsScroll"))
		columns.add_child(_scroll(_render_plan(), "PlanScroll"))
		columns.add_child(_scroll(_render_forecast(), "ForecastScroll"))
		_render_footer()
	_restore_focus()

func _render_header() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	_content.add_child(row)
	var title := _label("MISSION TABLE", 22, MUSTARD)
	row.add_child(title)
	var gate: Dictionary = _view.get("gate", {})
	var gate_label := _label("P-02 SEVEN SHIFTS · " + String(gate.get("label", "")).to_upper(), 15, IVORY)
	gate_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gate_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(gate_label)
	var committed := _committed()
	if _class_mode():
		var mode_chip := _label(" %s " % CrewScript.mode_label(_crew), 11, INK)
		mode_chip.name = "CrewModeChip"
		mode_chip.add_theme_stylebox_override("normal", _box(CYAN, Color(0, 0, 0, 0), 4, 0))
		mode_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(mode_chip)
	var meta := _wrap("%s · %d OF 7 SHIFTS COMMITTED · 7.2 h EACH · TIME PAUSED WHILE THE TABLE IS OPEN" % [String(_view.get("scenario_datetime", "")), committed], 12, MUTED)
	meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	meta.size_flags_horizontal = Control.SIZE_FILL
	meta.custom_minimum_size.x = 300
	row.add_child(meta)

func _render_cards() -> Control:
	if _class_mode():
		return _render_private_cards()
	var column := _column("CREW CARDS · SHARE WHAT EACH ROLE KNOWS", 300)
	for card in _view.get("cards", []):
		var box := _card_box(bool(card.get("shared", false)), bool(card.get("arrived", false)))
		var inner := VBoxContainer.new()
		inner.add_theme_constant_override("separation", 4)
		box.add_child(inner)
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 8)
		inner.add_child(head)
		var chip := _label(" %s " % String(card.get("role", "")), 11, INK)
		chip.add_theme_stylebox_override("normal", _box(MUSTARD if bool(card.arrived) else MUTED, Color(0, 0, 0, 0), 4, 0))
		head.add_child(chip)
		head.add_child(_label(String(card.get("name", "")), 16, IVORY))
		if not bool(card.get("arrived", false)):
			inner.add_child(_wrap("Arrives at shift %d. Not yet available." % int(card.get("arrives_shift", 1)), 13, MUTED))
		else:
			if not String(card.get("quote", "")).is_empty():
				inner.add_child(_wrap("“%s”" % String(card.quote), 13, CYAN))
			for fact in card.get("facts", []):
				inner.add_child(_wrap("• " + String(fact), 13, IVORY))
			if bool(card.get("shared", false)):
				inner.add_child(_wrap("✓ SHARED · READ BY THE CREW", 12, GREEN))
			else:
				var share := _button("SHARE %s'S CARD" % String(card.get("name", "")).to_upper(), "Share_" + String(card.get("role_id", "")))
				var role_id := String(card.get("role_id", ""))
				share.pressed.connect(func() -> void: share_card(role_id))
				inner.add_child(share)
		column.add_child(box)
	return column

## Class mode: who holds each note and its receipts, never its facts.
func _render_private_cards() -> Control:
	var column := _column(CrewScript.text("table", "cards_title_class"), 300)
	for card in _view.get("cards", []):
		var role_id := String(card.get("role_id", ""))
		var arrived := bool(card.get("arrived", false))
		var read := bool(card.get("read", false))
		var shared := bool(card.get("shared", false))
		var tokens := CrewScript.role_tokens(_crew, role_id, {"shift": str(int(card.get("arrives_shift", 1)))})
		var box := _card_box(shared, arrived)
		var inner := VBoxContainer.new()
		inner.add_theme_constant_override("separation", 4)
		box.add_child(inner)
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 8)
		inner.add_child(head)
		var chip := _label(" %s " % String(card.get("role", "")), 11, INK)
		chip.add_theme_stylebox_override("normal", _box(CrewScript.role_color(role_id) if arrived else MUTED, Color(0, 0, 0, 0), 4, 0))
		head.add_child(chip)
		head.add_child(_label(String(card.get("name", "")), 16, IVORY))
		inner.add_child(_wrap(CrewScript.text("table", "holder_line", tokens).to_upper(), 12, MUTED))
		if not arrived:
			inner.add_child(_wrap("Arrives at shift %d. Not yet available." % int(card.get("arrives_shift", 1)), 13, MUTED))
		else:
			var status_key := "status_shared" if shared else ("status_read" if read else "status_unread")
			var status := _wrap(CrewScript.text("table", status_key, tokens), 12, GREEN if shared else (CYAN if read else MUSTARD))
			status.name = "Status_" + role_id
			inner.add_child(status)
			var read_button := _button(CrewScript.text("table", "reread_button" if read else "read_button", tokens), "Read_" + role_id)
			read_button.pressed.connect(func() -> void: read_card(role_id))
			inner.add_child(read_button)
			if shared:
				inner.add_child(_wrap(CrewScript.text("table", "shared_hint", tokens), 12, MUTED))
			elif read:
				var share := _button(CrewScript.text("table", "share_button", tokens), "Share_" + role_id)
				share.pressed.connect(func() -> void: share_card(role_id))
				inner.add_child(share)
		column.add_child(box)
	return column

func _render_plan() -> Control:
	var column := _column("YOUR PLAN", 0)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var committed := _committed()
	var prerequisite := String(_view.get("prerequisite_reason", ""))
	if not prerequisite.is_empty():
		column.add_child(_wrap("BLOCKED · " + prerequisite, 14, MUSTARD))
	for raw_shift in _view.get("shifts", []):
		var shift := int(raw_shift)
		var day := TableScript.is_day_shift(shift)
		var heading := "SHIFT %d · %s" % [shift, "DAYLIGHT · battery +8 · heat automatic" if day else ("PARTICLE ALARM · one exclusive response" if TableScript.is_alarm_shift(shift) else "DARK · no solar income")]
		if shift <= committed:
			heading += " · COMMITTED"
		column.add_child(_wrap(heading, 15, CYAN))
		var current: Dictionary = _view.get("selections", {}).get(shift, {})
		var stacked := TableScript.is_alarm_shift(shift) and String(current.get("action", "")) == "STACK"
		for field in TableScript.fields_for_shift(shift):
			var forced: bool = stacked and field != "action"
			column.add_child(_field_row(shift, String(field), current, shift <= committed or forced))
			if forced and field == "heat":
				column.add_child(_wrap("STACK sets heat COOL, air maker OFF and light OFF for this shift.", 12, MUTED))
		if TableScript.is_alarm_shift(shift):
			_render_task(column, current)
	_render_hints(column)
	return column

func _field_row(shift: int, field: String, current: Dictionary, locked: bool) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var name_label := _label(TableScript.field_label(field), 12, MUTED)
	name_label.custom_minimum_size.x = 96 * (1.25 if _scale() > 1.0 else 1.0)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(name_label)
	var chosen = current.get(field, null)
	for option in TableScript.field_options(field):
		var value = TableScript._normalise(field, option.get("value"))
		var selected: bool = chosen != null and typeof(chosen) == typeof(value) and chosen == value
		var text := "%s%s\n%s" % ["● " if selected else "", String(option.get("label", "")), String(option.get("cost", ""))]
		var button := _button(text, "Choice_%d_%s_%s" % [shift, field, str(value)])
		button.toggle_mode = true
		button.button_pressed = selected
		button.disabled = locked
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size.y = 52 * _scale()
		button.add_theme_font_size_override("font_size", _fs(12))
		button.tooltip_text = "%s %s for shift %d: %s" % [TableScript.field_label(field), String(option.get("label", "")), shift, String(option.get("cost", ""))]
		if selected:
			button.add_theme_stylebox_override("normal", _box(Color("#2C3D63"), MUSTARD, 7, 2))
			button.add_theme_stylebox_override("pressed", _box(Color("#2C3D63"), MUSTARD, 7, 2))
			button.add_theme_stylebox_override("disabled", _box(Color("#2C3D63"), MUSTARD, 7, 2))
		var picked = value
		button.pressed.connect(func() -> void: choose(shift, field, picked))
		row.add_child(button)
	if chosen == null:
		var missing := _label("CHOOSE", 11, MUSTARD)
		row.add_child(missing)
	return row

func _render_task(column: VBoxContainer, current: Dictionary) -> void:
	var action := String(current.get("action", ""))
	if not action in ["PUMP", "STACK"]:
		if action == "WAIT":
			column.add_child(_wrap("WAIT has no task. The shelter you prepared is what protects the crew.", 13, MUTED))
		return
	var alarm: Dictionary = _view.get("alarm", {})
	var steps := int(alarm.get("steps", 0))
	var progress := int(alarm.get("progress", 0))
	var state := String(alarm.get("state", "idle"))
	var assisted := bool(_settings.get("timer_free", true))
	var box := _card_box(state == "resolved", true)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 5)
	box.add_child(inner)
	var title := "PUMP · confirm the three valves in order" if action == "PUMP" else "STACK · place the four supply bundles in the outlined bunk slots"
	inner.add_child(_wrap(title, 13, IVORY))
	var outcome := ""
	if action == "PUMP":
		outcome = "Water wall +2 when all three valves are confirmed; +1 if partial."
	else:
		outcome = "Crates 2 when all four bundles are placed; 1 if partial."
	inner.add_child(_wrap(outcome, 12, MUTED))
	if state == "idle":
		var start := _button("START %s TASK%s" % [action, " · NO TIMER (ASSISTED)" if assisted else " · %d s" % int(alarm.get("timer_seconds", 0))], "TaskStep_0")
		start.pressed.connect(func() -> void: start_task())
		inner.add_child(start)
	else:
		var labels: Array = alarm.get("step_labels", [])
		var done: Array = alarm.get("done", [])
		var grid := GridContainer.new()
		grid.columns = 2 if action == "STACK" else 1
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 6)
		inner.add_child(grid)
		for index in steps:
			var is_done := done.has(index) or done.has(float(index))
			var text := "%s %d. %s" % ["✓" if is_done else "○", index + 1, String(labels[index]) if index < labels.size() else "STEP"]
			var step := _button(text, "TaskStep_%d" % (index + 1))
			step.disabled = is_done or state != "running"
			step.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var step_index := index
			step.pressed.connect(func() -> void: task_step(step_index))
			grid.add_child(step)
		inner.add_child(_wrap("PROGRESS %d / %d%s" % [progress, steps, " · RESOLVED" if state == "resolved" else ""], 13, GREEN if state == "resolved" else MUSTARD))
		if state == "running":
			if not bool(alarm.get("assisted", true)):
				var timer := _label("%d s left · the task resolves with the steps done" % ceili(_task_time_left), 12, MUSTARD)
				timer.name = "TaskTimer"
				inner.add_child(timer)
			var end := _button("END TASK WITH %d / %d" % [progress, steps], "EndTask")
			end.pressed.connect(func() -> void: end_task())
			inner.add_child(end)
	column.add_child(box)

func _render_hints(column: VBoxContainer) -> void:
	column.add_child(_wrap("HINTS · they never change your ending", 13, CYAN))
	for hint in _view.get("hints", []):
		column.add_child(_wrap("%s · %s" % [String(hint.level), String(hint.text)], 13, IVORY))
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 6)
	row.add_theme_constant_override("v_separation", 6)
	column.add_child(row)
	var hint := _button("SHOW NEXT HINT", "Hint")
	hint.pressed.connect(func() -> void: reveal_hint())
	row.add_child(hint)
	for plan_id in _view.get("worked_plans", []):
		var worked := _button("OPEN WORKED %s PLAN" % String(plan_id).to_upper(), "Worked_" + String(plan_id))
		var id := String(plan_id)
		worked.pressed.connect(func() -> void: use_worked_plan(id))
		row.add_child(worked)

func _render_forecast() -> Control:
	var column := _column("STATION NOW → FORECAST", 330)
	var resources: Dictionary = _view.get("resources", {})
	var gate_preview: Dictionary = _view.get("gate_preview", {})
	var after: Dictionary = gate_preview.get("final_state", {}) if bool(gate_preview.get("accepted", false)) else {}
	var shifts: Array = _view.get("shifts", [])
	var last_shift := int(shifts.back()) if not shifts.is_empty() else 0
	column.add_child(_wrap("NOW%s" % ("  →  AFTER SHIFT %d" % last_shift if not after.is_empty() else ""), 12, MUTED))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	column.add_child(grid)
	for row in RESOURCE_ROWS:
		var key := String(row[0])
		grid.add_child(_label(String(row[1]), 13, MUTED))
		var cap := "/%d" % int(resources.get(String(row[2]), 0)) if not String(row[2]).is_empty() and resources.has(String(row[2])) else ""
		var text := "%s%s" % [_amount(resources.get(key, 0)), cap]
		var color := IVORY
		if not after.is_empty():
			var delta := float(after.get(key, 0)) - float(resources.get(key, 0))
			text += "  →  %s%s  (%s)" % [_amount(after.get(key, 0)), cap, _signed(delta)]
			color = IVORY if is_zero_approx(delta) else (GREEN if (delta > 0) != (key in ["Z"]) else MUSTARD)
		grid.add_child(_label(text, 13, color))
	if not after.is_empty():
		for record in gate_preview.get("trace", []):
			column.add_child(_wrap(_trace_text(record), 12, RED if bool(record.get("blackout", false)) else IVORY))
		for warning in gate_preview.get("warnings", []):
			if not String(warning).begins_with("PREVIEW ONLY"):
				column.add_child(_wrap("! " + String(warning), 12, MUSTARD))
		for predicate in gate_preview.get("unsafe_predicates", []):
			column.add_child(_wrap("STOP · " + _predicate_text(String(predicate)), 13, RED))
	elif not String(_view.get("block_reason", "")).is_empty():
		column.add_child(_wrap("Forecast appears when every choice for this commit is set.", 12, MUTED))
	column.add_child(HSeparator.new())
	_render_projection(column)
	return column

func _render_projection(column: VBoxContainer) -> void:
	var through := int(_view.get("planned_through", 0))
	var projection: Dictionary = _view.get("night_projection", {})
	column.add_child(_wrap("WHOLE NIGHT · PLANNED THROUGH SHIFT %d OF 7" % through, 13, CYAN))
	if projection.is_empty() or not bool(projection.get("accepted", false)):
		column.add_child(_wrap("Plan later shifts to project the rest of the night.", 12, MUTED))
	else:
		var final_state: Dictionary = projection.get("final_state", {})
		column.add_child(_wrap("Plan B (current): " + _summary(final_state), 12, IVORY))
		if not _pinned.is_empty():
			column.add_child(_wrap("Plan A (pinned): " + _summary(_pinned.get("final", {})) + " · through %d" % int(_pinned.get("through", 0)), 12, MUTED))
		var report: Dictionary = _view.get("ending_report", {})
		if not report.is_empty():
			var stars: Dictionary = report.get("stars", {})
			column.add_child(_wrap("PROJECTED: " + String(report.get("title", report.get("ending", ""))), 14, GREEN if bool(report.get("unlocks_chapter2", false)) else RED))
			column.add_child(_wrap("%s Crew exposure ≤ 3   %s No blackout   %s Alo alive" % [_star(stars.get("safe_exposure", false)), _star(stars.get("no_blackout", false)), _star(stars.get("alo_alive", false))], 12, IVORY))
			for predicate in report.get("unsafe_predicates", []):
				column.add_child(_wrap("Cause: " + _predicate_text(String(predicate)), 12, RED))
		elif through < 7:
			column.add_child(_wrap("Shifts %d–7 are not planned yet." % (through + 1), 12, MUTED))
	column.add_child(_wrap(_known_events_text(), 12, MUTED))

func _render_footer() -> void:
	var reason := _commit_reason()
	var status := _wrap(_notice if not _notice.is_empty() else (reason if not reason.is_empty() else "Ready. Press Space to commit, then Space again to confirm."), 14, MUSTARD if not reason.is_empty() else GREEN)
	status.name = "TableStatus"
	_content.add_child(status)
	var row := HFlowContainer.new()
	row.alignment = FlowContainer.ALIGNMENT_END
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 6)
	_content.add_child(row)
	var pin := _button("PIN AS PLAN A", "PinPlanA")
	pin.pressed.connect(pin_plan_a)
	row.add_child(pin)
	var preview_button := _button("PREVIEW", "Preview")
	preview_button.pressed.connect(func() -> void: preview())
	row.add_child(preview_button)
	var gate: Dictionary = _view.get("gate", {})
	var commit := _button(String(gate.get("commit_label", "COMMIT")) + " · SPACE", "Commit")
	commit.disabled = not reason.is_empty()
	commit.tooltip_text = reason if not reason.is_empty() else "Opens the confirmation. Space or Enter confirms."
	commit.pressed.connect(func() -> void: request_commit())
	row.add_child(commit)
	var close_button := _button("CLOSE · ESC", "CloseTable")
	close_button.pressed.connect(close)
	row.add_child(close_button)

func _render_confirmation() -> void:
	var gate: Dictionary = _view.get("gate", {})
	var forecast: Dictionary = _view.get("gate_preview", {})
	var box := _card_box(false, true)
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_child(box)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 8)
	box.add_child(inner)
	inner.add_child(_wrap("CONFIRM · " + String(gate.get("commit_label", "COMMIT")), 20, MUSTARD))
	if bool(gate.get("preview_only", false)):
		inner.add_child(_wrap("This stages the shift 2 forecast for the drill. Nothing is committed and no time passes.", 15, IVORY))
	else:
		inner.add_child(_wrap("These consequences are final for this attempt. RETRY restores the checkpoint before this commit.", 15, IVORY))
	for record in forecast.get("trace", []):
		inner.add_child(_wrap(_trace_text(record), 14, RED if bool(record.get("blackout", false)) else IVORY))
	var resources: Dictionary = _view.get("resources", {})
	var final_state: Dictionary = forecast.get("final_state", {})
	inner.add_child(_wrap("Station after: " + _summary(final_state) + "   (now " + _summary(resources) + ")", 14, CYAN))
	for predicate in forecast.get("unsafe_predicates", []):
		inner.add_child(_wrap("FLIGHT RULES STOP THE MISSION · " + _predicate_text(String(predicate)), 15, RED))
	var report := TableScript.ending_report(forecast)
	if not report.is_empty():
		inner.add_child(_wrap("SUNRISE RESULT · %s · %s" % [String(report.get("title", "")), String(report.get("summary", ""))], 15, GREEN if bool(report.get("unlocks_chapter2", false)) else RED))
	var solo_note := _wrap(CrewScript.text("team_plan", "solo_note"), 12, MUTED)
	solo_note.name = "SoloNote"
	inner.add_child(solo_note)
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

## Class mode confirmation: the exact plan, its forecast and one signature
## row per role. The operator's lock-in is enabled only when all four signed
## this plan.
func _render_team_plan() -> void:
	var gate: Dictionary = _view.get("gate", {})
	var forecast: Dictionary = _view.get("gate_preview", {})
	var box := _card_box(false, true)
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_child(box)
	var scroll := ScrollContainer.new()
	scroll.name = "TeamPlanScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	box.add_child(scroll)
	var inner := VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 8)
	scroll.add_child(inner)
	inner.add_child(_wrap("%s · %s" % [CrewScript.text("team_plan", "title"), String(gate.get("commit_label", "COMMIT"))], 20, MUSTARD))
	inner.add_child(_wrap("%s: “%s”" % [CrewScript.text("team_plan", "intro_speaker"), CrewScript.text("team_plan", "intro")], 14, CYAN))
	inner.add_child(_wrap(CrewScript.text("team_plan", "instruction"), 14, IVORY))
	if bool(gate.get("preview_only", false)):
		inner.add_child(_wrap("This stages the shift 2 forecast for the drill. Nothing is committed and no time passes.", 13, MUTED))
	else:
		inner.add_child(_wrap("These consequences are final for this attempt. RETRY restores the checkpoint before this commit.", 13, MUTED))
	for raw_shift in _view.get("shifts", []):
		var shift := int(raw_shift)
		var line := _wrap("SHIFT %d · %s" % [shift, _plan_summary(shift)], 14, IVORY)
		line.name = "PlanLine_%d" % shift
		inner.add_child(line)
	for record in forecast.get("trace", []):
		inner.add_child(_wrap(_trace_text(record), 13, RED if bool(record.get("blackout", false)) else IVORY))
	inner.add_child(_wrap("Station after: " + _summary(forecast.get("final_state", {})) + "   (now " + _summary(_view.get("resources", {})) + ")", 14, CYAN))
	for predicate in forecast.get("unsafe_predicates", []):
		inner.add_child(_wrap("FLIGHT RULES STOP THE MISSION · " + _predicate_text(String(predicate)), 15, RED))
	var report := TableScript.ending_report(forecast)
	if not report.is_empty():
		inner.add_child(_wrap("SUNRISE RESULT · %s · %s" % [String(report.get("title", "")), String(report.get("summary", ""))], 14, GREEN if bool(report.get("unlocks_chapter2", false)) else RED))
	inner.add_child(HSeparator.new())
	var signed: Array = _view.get("signed_roles", [])
	var stale: Array = _view.get("stale_sign_offs", [])
	var grid := GridContainer.new()
	grid.name = "SignOffs"
	grid.columns = 1 if _scale() > 1.0 else 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	inner.add_child(grid)
	for role_id in CrewScript.ROLE_ORDER:
		var tokens := CrewScript.role_tokens(_crew, String(role_id))
		var is_signed: bool = signed.has(role_id)
		var cell := _card_box(is_signed, true)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cell_inner := VBoxContainer.new()
		cell_inner.add_theme_constant_override("separation", 4)
		cell.add_child(cell_inner)
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 8)
		cell_inner.add_child(head)
		var chip := _label(" %s " % String(tokens.get("name", role_id)).to_upper(), 11, INK)
		chip.add_theme_stylebox_override("normal", _box(CrewScript.role_color(String(role_id)), Color(0, 0, 0, 0), 4, 0))
		head.add_child(chip)
		head.add_child(_label(CrewScript.text("table", "holder_line", tokens).to_upper(), 12, MUTED))
		var status_key := "signed" if is_signed else ("stale" if stale.has(role_id) else "waiting")
		var status := _wrap(CrewScript.text("team_plan", status_key, tokens), 12, GREEN if is_signed else (RED if status_key == "stale" else MUSTARD))
		status.name = "SignStatus_" + String(role_id)
		cell_inner.add_child(status)
		var sign := _button(CrewScript.text("team_plan", "sign_button", tokens), "SignOff_" + String(role_id))
		sign.disabled = is_signed
		var id := String(role_id)
		sign.pressed.connect(func() -> void: sign_off(id))
		cell_inner.add_child(sign)
		grid.add_child(cell)
	var unsigned := _unsigned_roles()
	var gate_line := _wrap(CrewScript.text("team_plan", "operator_blocked", {"signed": str(CrewScript.ROLE_ORDER.size() - unsigned.size()), "total": str(CrewScript.ROLE_ORDER.size())}) if not unsigned.is_empty() else "All four roles signed this plan. The operator may lock it in.", 13, MUSTARD if not unsigned.is_empty() else GREEN)
	gate_line.name = "TeamPlanGate"
	_content.add_child(gate_line)
	var row := HFlowContainer.new()
	row.alignment = FlowContainer.ALIGNMENT_END
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 6)
	_content.add_child(row)
	var back := _button(CrewScript.text("team_plan", "back_button"), "CancelCommit")
	back.pressed.connect(cancel_confirm)
	row.add_child(back)
	var confirm := _button(CrewScript.text("team_plan", "operator_button"), "ConfirmCommit")
	confirm.disabled = not unsigned.is_empty()
	confirm.tooltip_text = String(gate_line.text)
	confirm.pressed.connect(func() -> void: confirm_commit())
	row.add_child(confirm)

## "HEAT COZY · AIR MAKER +2 · GARDEN LIGHT FULL · WATER WALL HOLD" for one shift.
func _plan_summary(shift: int) -> String:
	var current: Dictionary = _view.get("selections", {}).get(shift, {})
	var parts: Array = []
	for field in TableScript.fields_for_shift(shift):
		if current.has(field):
			parts.append("%s %s" % [TableScript.field_label(String(field)), TableScript._value_label(String(field), current[field])])
	if TableScript.is_day_shift(shift):
		parts.push_front("HEAT DAY")
	return " · ".join(parts)

# --- Text helpers ------------------------------------------------------------

func _trace_text(record: Dictionary) -> String:
	var parts: Array = []
	var shift := int(record.get("shift", 0))
	var before: Dictionary = record.get("before", {})
	var after: Dictionary = record.get("after", {})
	parts.append("Shift %d — battery %s→%s" % [shift, _amount(before.get("E", 0)), _amount(after.get("E", 0))])
	if int(record.get("overflow", 0)) > 0:
		parts.append("%d sunlight lost to overflow" % int(record.overflow))
	parts.append("air %s→%s" % [_amount(before.get("A", 0)), _amount(after.get("A", 0))])
	parts.append("Alo %s→%s" % [_amount(before.get("H", 0)), _amount(after.get("H", 0))])
	parts.append("wall %s→%s" % [_amount(before.get("W", 0)), _amount(after.get("W", 0))])
	if int(record.get("dose", 0)) > 0 or shift in [5, 6]:
		parts.append("shelter %d, dose %d" % [int(record.get("shelter", 0)), int(record.get("dose", 0))])
	if String(record.get("action", "")) in ["PUMP", "STACK"]:
		parts.append("%s %d step%s%s" % [String(record.action), int(record.get("action_progress", 0)), "" if int(record.get("action_progress", 0)) == 1 else "s", "" if bool(record.get("action_success", false)) else " (partial)"])
	if bool(record.get("crates_removed", false)):
		parts.append("crates removed")
	if bool(record.get("blackout", false)):
		parts.append("BLACKOUT: demand went below zero; air, Alo and crop −2")
	elif int(after.get("E", 1)) == 0:
		parts.append("battery empty (exactly 0 is not a blackout)")
	return " · ".join(parts)

func _predicate_text(predicate: String) -> String:
	if predicate.begins_with("air_depleted"):
		return "air reached 0 in shift %s" % predicate.get_slice("_", predicate.get_slice_count("_") - 1)
	if predicate.begins_with("exposure_limit"):
		return "crew exposure went above 3 in shift %s" % predicate.get_slice("_", predicate.get_slice_count("_") - 1)
	if predicate.begins_with("crew_shelter_breach"):
		return "the crew was outside the shelter during the storm"
	if predicate.begins_with("resupply_required"):
		return "rations ran short; resupply is required"
	return predicate.replace("_", " ")

func _known_events_text() -> String:
	var lines: Array = ["KNOWN AHEAD:"]
	if _committed() < 4:
		lines.append("Shift 4 · Earth-link cutoff (training event). Local radios keep working.")
	var rafi_known := false
	for card in _view.get("cards", []):
		if String(card.get("role_id", "")) == "rafi" and bool(card.get("arrived", false)):
			rafi_known = true
	if rafi_known and _committed() < 6:
		lines.append("Shifts 5–6 · particle event forecast window (Rafi).")
	elif not rafi_known:
		lines.append("Space-weather outlook not yet received. Later events can change this projection.")
	lines.append("Sunrise after shift 7.")
	return "\n".join(lines)

func _summary(values: Dictionary) -> String:
	return "E%s A%s H%s C%s W%s K%s Z%s R%s" % [_amount(values.get("E", 0)), _amount(values.get("A", 0)), _amount(values.get("H", 0)), _amount(values.get("C", 0)), _amount(values.get("W", 0)), _amount(values.get("K", 0)), _amount(values.get("Z", 0)), _amount(values.get("R", 0))]

func _amount(value) -> String:
	var number := float(value)
	return str(int(number)) if is_equal_approx(number, round(number)) else "%.1f" % number

func _signed(value: float) -> String:
	if is_zero_approx(value):
		return "±0"
	return ("+" if value > 0 else "−") + _amount(absf(value))

func _star(value) -> String:
	return "★" if bool(value) else "☆"

# --- State helpers -------------------------------------------------------------

func _table() -> RefCounted:
	return _route.mission_table()

func _class_mode() -> bool:
	return CrewScript.is_class(_crew)

func _card(role_id: String) -> Dictionary:
	for card in _view.get("cards", []):
		if String(card.get("role_id", "")) == role_id:
			return card
	return {}

## Roles that have not signed the plan currently on the table, in card order.
func _unsigned_roles() -> Array:
	var signed: Array = signed_roles() if _route != null else []
	var result: Array = []
	for role_id in CrewScript.ROLE_ORDER:
		if not signed.has(role_id):
			result.append(role_id)
	return result

func _unsigned_roles_after(role_id: String) -> Array:
	var remaining := _unsigned_roles()
	remaining.erase(role_id)
	return remaining

func _on_card_read(role_id: String) -> void:
	if _route != null:
		_table().mark_read(role_id, _committed())

func _on_handoff_closed(read: Array) -> void:
	if not visible:
		return
	_notice = ""
	_focus_name = "Share_" + String(read.back()) if not read.is_empty() else ""
	_render()

func _committed() -> int:
	return int(_view.get("committed_shift", 0)) if not _view.is_empty() else int(_route.director().query().get("current_shift", 0))

func _refresh_view() -> void:
	_view = _route.mission_table_view(_target_id)
	_view["crew"] = _crew.duplicate(true)
	_view["signed_roles"] = _table().signed_roles(_target_id, int(_view.get("committed_shift", 0)))
	_view["stale_sign_offs"] = _table().stale_sign_offs(_target_id, int(_view.get("committed_shift", 0)))

func _plan_key() -> String:
	return _table().plan_key(_target_id, _committed())

func _commit_reason() -> String:
	if _view.is_empty():
		_refresh_view()
	var prerequisite := String(_view.get("prerequisite_reason", ""))
	if not prerequisite.is_empty():
		return prerequisite
	var reason := String(_view.get("block_reason", ""))
	if not reason.is_empty():
		return reason
	var forecast: Dictionary = _view.get("gate_preview", {})
	if not bool(forecast.get("accepted", false)):
		return "The forecast rejected this plan: " + String(forecast.get("reason", ""))
	if _previewed_key != _plan_key():
		return "Press PREVIEW to read this plan's forecast before committing."
	return ""

func _after_action(result: Dictionary, focus_name: String) -> void:
	_notice = String(result.get("reason", ""))
	_focus_name = focus_name
	_render()

func _restore_focus() -> void:
	var target: Control = null
	if not _focus_name.is_empty():
		target = find_child(_focus_name, true, false) as Control
	if target == null or not target.is_visible_in_tree() or (target is BaseButton and (target as BaseButton).disabled):
		target = find_child("Preview", true, false) as Control
	if target == null:
		target = find_child("ConfirmCommit", true, false) as Control
	if target != null:
		_focus_later(target)
	_focus_name = ""

# Focus is applied after layout. A later re-render may already have replaced
# the control, so only a control still in the tree takes focus.
func _focus_later(target: Control) -> void:
	_apply_focus.call_deferred(target)

func _apply_focus(target: Control) -> void:
	if is_instance_valid(target) and target.is_inside_tree() and not target.is_queued_for_deletion() and visible:
		target.grab_focus()

func _grab_first_focus() -> void:
	for card in _view.get("cards", []):
		if bool(card.get("arrived", false)) and not bool(card.get("shared", false)):
			var control_name := "Share_" + String(card.role_id)
			if _class_mode() and not bool(card.get("read", false)):
				control_name = "Read_" + String(card.role_id)
			var share := find_child(control_name, true, false) as Control
			if share != null:
				_focus_later(share)
				return
	var preview_button := find_child("Preview", true, false) as Control
	if preview_button != null:
		_focus_later(preview_button)

func _layout() -> void:
	if _frame == null or not is_inside_tree():
		return
	var size_now := get_viewport_rect().size
	_frame.position = Vector2(12, 12)
	_frame.size = Vector2(size_now.x - 24, size_now.y - 24)

func _scale() -> float:
	return 1.5 if bool(_settings.get("large_text", false)) else 1.0

func _fs(size: int) -> int:
	return int(round(size * _scale()))

# --- Widget helpers ------------------------------------------------------------

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
	var border := GREEN if highlight else (Color(0.26, 0.40, 0.62, 0.8) if available else Color(0.3, 0.33, 0.4, 0.6))
	var style := _box(NAVY if available else Color("#141B2B"), border, 9, 1)
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
	button.add_theme_font_size_override("font_size", _fs(13))
	button.add_theme_color_override("font_color", IVORY)
	button.add_theme_color_override("font_pressed_color", IVORY)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_focus_color", IVORY)
	button.add_theme_color_override("font_disabled_color", Color(0.66, 0.71, 0.78, 0.75))
	button.add_theme_stylebox_override("normal", _box(NAVY, Color(0.32, 0.45, 0.66, 0.9), 7, 1))
	button.add_theme_stylebox_override("pressed", _box(NAVY, Color(0.32, 0.45, 0.66, 0.9), 7, 1))
	button.add_theme_stylebox_override("hover", _box(MUSTARD, INK, 7, 2))
	button.add_theme_stylebox_override("focus", _box(Color(0, 0, 0, 0), IVORY, 7, 3))
	button.add_theme_stylebox_override("disabled", _box(Color("#151C2C"), Color(0.25, 0.28, 0.36, 0.8), 7, 1))
	return button

func _box(fill: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style
