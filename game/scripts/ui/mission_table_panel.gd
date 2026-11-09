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

signal commit_requested(target_id: String, plan: Dictionary)
signal opened(target_id: String)
signal closed(target_id: String)

const TableScript = preload("res://scripts/puzzles/p02_mission_table.gd")
var INK := UiDesign.colour("ink")
var NAVY := UiDesign.colour("navy")
var NAVY_DEEP := UiDesign.colour("glass")
var IVORY := UiDesign.colour("ivory")
var MUTED := UiDesign.colour("muted")
var MUSTARD := UiDesign.colour("accent")
var CYAN := UiDesign.colour("amara")
var GREEN := UiDesign.colour("good")
var RED := UiDesign.colour("danger")
const MIN_TARGET := 44.0
var hint_player: HintPlayer
var _route: RefCounted
var _target_id := ""
var _settings := {"large_text": false, "timer_free": true}
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
var _body: VBoxContainer
var _more := false
var _card_more := {}
var _portraits := {}
var _portrait_loading := {}
const Simulation = preload("res://scripts/simulation/expedition_simulation.gd")
const Debrief = preload("res://scripts/debrief/chapter1_debrief.gd")

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Above the HUD's outpost readout (z 70): the table carries its own summary.
	z_index = 100
	theme = UiKit.theme()
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
	hide()
	get_viewport().size_changed.connect(_layout)

## Opens the table for one P-02 gate. `settings` carries large_text and
## timer_free from the accessibility settings.
func open(route: RefCounted, target_id: String, settings: Dictionary = {}) -> void:
	_route = route
	_target_id = target_id
	for key in settings:
		_settings[key] = settings[key]
	_confirming = false
	_notice = ""
	_previewed_key = ""
	_focus_name = ""
	_more = false
	_refresh_view()
	if _target_id == "p02_shift1" and not _table().selection(1).has("transfer"):
		_table().set_choice(1, "transfer", "HOLD", _committed())
	show()
	_layout()
	_render()
	opened.emit(target_id)
	_grab_first_focus()

## Closes without committing anything.
func close() -> void:
	if not visible:
		return
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
	if result.get("accepted", false):
		for option in TableScript.field_options(field):
			if TableScript._normalise(field, option.value) == _table().selection(shift).get(field):
				result.reason = "Shift %d: %s set to %s: %s." % [shift, _field_word(field), _option_word(field, option.value, option.label), _option_cost(option.cost)]
				break
	_after_action(result, "Choice_1_light_OFF" if shift == 1 and field == "air_production" and not _table().selection(1).has("light") else "Choice_%d_%s_%s" % [shift, field, str(value)])
	return result

func _option_cost(cost: String) -> String:
	if cost.begins_with("E"):
		var energy := cost.get_slice(" ", 0)
		return cost.replace(energy, "Battery cost " + energy.trim_prefix("E") + " per shift")
	return cost

func _field_word(field: String) -> String:
	return _sentence_case(TableScript.field_label(field))

func _sentence_case(value: String) -> String:
	var label := value.to_lower()
	return label.left(1).to_upper() + label.substr(1)

func _option_word(field: String, value, label: String) -> String:
	if field == "action":
		return {"PUMP": "Pump water", "STACK": "Stack supplies", "WAIT": "Wait"}.get(String(value), label)
	return ["Off", "Low", "High"][int(value)] if field == "air_production" else label.capitalize()

## Shares one delivered role card with the crew.
func share_card(role_id: String) -> Dictionary:
	var result: Dictionary = _table().share(role_id, _committed())
	_after_action(result, "Share_" + role_id)
	return result

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
	_notice = "Forecast ready. Nothing changed. Lock in shift when you are ready."
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
	_focus_name = "ConfirmCommit"
	_render()
	return {"accepted": true, "reason": "Confirm to commit."}

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
	if hint_player == null:
		return {"accepted": false, "reason": "Hint reader is unavailable."}
	hint_player.set_settings(_settings)
	hint_player.request_hint("mission_table", HowToCard.lesson("mission_table"), _hint_target())
	return {"accepted": true, "reason": "Hint opened."}

func teach_first_use() -> void:
	if hint_player != null and not hint_player.is_open() and not hint_player.has_seen("mission_table"):
		hint_player.set_settings(_settings)
		hint_player.show_how_to("mission_table", true, _hint_target())
		# Teaching can outlast the initial focus requests queued by open().
		hint_player.closed.connect(_grab_first_focus, CONNECT_ONE_SHOT)

func _hint_target() -> Control:
	for shift in _view.get("shifts", []):
		var row := find_child("Row_%d_air_production" % int(shift), true, false) as Control
		if row != null:
			return row
	return find_child("Preview", true, false) as Control


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
	if not visible or (hint_player != null and hint_player.is_open()):
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
	if not visible or _task_time_left <= 0.0 or (hint_player != null and hint_player.is_open()):
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
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 14)
	var scroll := _scroll(_body, "TableBodyScroll")
	_content.add_child(scroll)
	if _confirming:
		_render_confirmation()
	else:
		var columns := GridContainer.new()
		columns.columns = 2 if get_viewport_rect().size.x >= 1100 and _scale() == 1.0 else 1
		columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		columns.add_theme_constant_override("h_separation", 24)
		columns.add_theme_constant_override("v_separation", 18)
		_body.add_child(columns)
		columns.add_child(_render_plan())
		columns.add_child(_render_forecast())
		_body.add_child(_render_cards())
		if _more:
			var more := _column("More about this plan", 0)
			more.name = "MoreDetails"
			_body.add_child(more)
			var pin := _button("Save as Plan A", "PinPlanA")
			pin.pressed.connect(pin_plan_a)
			more.add_child(pin)
			_render_projection(more)
		_render_footer()
	_layout()
	_restore_focus()

func _render_header() -> void:
	var title := _wrap("Mission Table · Seven Shifts", 22, MUSTARD)
	_content.add_child(title)
	var strip := GridContainer.new()
	strip.name = "NightStrip"
	strip.columns = 7 if get_viewport_rect().size.x >= 1000 else 4
	strip.add_theme_constant_override("h_separation", 6)
	_content.add_child(strip)
	for shift in range(1, 8):
		var cell := VBoxContainer.new()
		cell.name = "NightShift%d" % shift
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var head := HBoxContainer.new()
		head.add_child(UiKit.icon("sun" if shift <= 2 else "moon", "accent", 18))
		head.add_child(_label("%d · %s" % [shift, "Sun" if shift <= 2 else "Dark"], 12, MUTED if shift <= _committed() else IVORY))
		cell.add_child(head)
		var event: String = {2: "Drill", 4: "Earth link ends", 7: "Sunrise after"}.get(shift, "")
		if shift in [5, 6] and _arrived("rafi"):
			event = "Storm outlook"
		cell.add_child(_wrap(event, 11, MUTED))
		strip.add_child(cell)

func _render_cards() -> Control:
	var column := _column("Crew notes · share what you know", 0)
	for card in _view.get("cards", []):
		if not bool(card.get("arrived", false)):
			continue
		var id := String(card.role_id)
		var box := _card_box(false, true)
		box.name = "Crew_" + id
		column.add_child(box)
		var inner := VBoxContainer.new()
		box.add_child(inner)
		var head := HBoxContainer.new()
		inner.add_child(head)
		var portrait := TextureRect.new()
		portrait.name = "Portrait_" + id
		portrait.custom_minimum_size = Vector2(72, 84)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.texture = _portraits.get(id)
		head.add_child(portrait)
		if not _portraits.has(id) and not _portrait_loading.has(id) and DisplayServer.get_name() != "headless":
			_portrait_loading[id] = true
			_prepare_portrait.call_deferred(id)
		var words := VBoxContainer.new()
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(words)
		words.add_child(_wrap("%s · %s" % [card.name, _sentence_case(String(card.role))], 16, IVORY))
		var facts: Array = card.get("facts", [])
		if not facts.is_empty():
			words.add_child(_wrap(String(facts[0]), 14, IVORY))
		var actions := HFlowContainer.new()
		inner.add_child(actions)
		var share := _button("Shared" if card.shared else "Share " + String(card.name) + "’s note", "Share_" + id)
		share.disabled = bool(card.shared)
		share.pressed.connect(func() -> void: share_card(id))
		actions.add_child(share)
		var more := _button("Less" if _card_more.get(id, false) else "More", "More_" + id)
		more.pressed.connect(func() -> void:
			_card_more[id] = not bool(_card_more.get(id, false))
			_focus_name = "More_" + id
			_render())
		actions.add_child(more)
		if _card_more.get(id, false):
			inner.add_child(_wrap(String(card.get("quote", "")), 14, CYAN))
			for fact in facts.slice(1):
				inner.add_child(_wrap(String(fact), 14, IVORY))
	return column

func _render_plan() -> Control:
	var column := _column("Choose this shift’s settings", 0)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var guide := _guide_step()
	if guide > 0:
		var instruction := _wrap(["1 of 3 · Set the air maker", "2 of 3 · Set the garden light", "3 of 3 · Try it, then lock in shift"][guide - 1], 18, MUSTARD)
		instruction.name = "GuideStep%d" % guide
		column.add_child(instruction)
		column.add_child(_wrap(["The crew uses 1 air each shift; making air spends battery.", "The light uses battery and changes Alo and the garden each shift.", "Try it shows the real consequences. Water stays in place unless your saved plan says otherwise."][guide - 1], 14, IVORY))
	for raw_shift in _view.get("shifts", []):
		var shift := int(raw_shift)
		column.add_child(_wrap("Shift %d · %s" % [shift, "Sunlight adds 8 battery units before spending" if TableScript.is_day_shift(shift) else "Dark · no solar charging"], 15, CYAN))
		var current: Dictionary = _view.get("selections", {}).get(shift, {})
		var stacked := shift == 5 and String(current.get("action", "")) == "STACK"
		for field in TableScript.fields_for_shift(shift):
			if field == "transfer" and not _arrived("rafi"):
				continue
			if guide == 1 and field != "air_production":
				continue
			column.add_child(_field_row(shift, String(field), current, shift <= _committed() or (stacked and field != "action")))
		if stacked:
			column.add_child(_wrap("Stacking sets heat to Cool, air maker Off and light Off.", 14, MUTED))
		if shift == 5:
			_render_task(column, current)
	return column

func _field_row(shift: int, field: String, current: Dictionary, locked: bool) -> Control:
	var active := (_guide_step() == 1 and field == "air_production") or (_guide_step() == 2 and field == "light")
	var box := _card_box(false, true)
	if active:
		box.add_theme_stylebox_override("panel", _box(NAVY, MUSTARD, 9, 2))
	box.name = "Row_%d_%s" % [shift, field]
	var column := VBoxContainer.new()
	box.add_child(column)
	var heading := HBoxContainer.new()
	heading.add_child(UiKit.icon(String({"air_production": "life", "light": "plant", "heat": "power", "transfer": "water", "action": "shielding"}.get(field, "goal"))))
	heading.add_child(_label(("Next · " if active else "") + _field_word(field), 14, MUSTARD if active else IVORY))
	column.add_child(heading)
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 6)
	row.add_theme_constant_override("v_separation", 6)
	column.add_child(row)
	for option in TableScript.field_options(field):
		var value = TableScript._normalise(field, option.get("value"))
		var selected: bool = current.has(field) and current[field] == value
		var word := _option_word(field, value, option.label)
		var button := _button(("✓ " if selected else "") + word, "Choice_%d_%s_%s" % [shift, field, str(value)])
		button.toggle_mode = true
		button.button_pressed = selected
		button.disabled = locked
		button.tooltip_text = display_text(_option_cost(option.cost))
		if selected:
			button.add_theme_stylebox_override("normal", _box(NAVY, MUSTARD, 7, 2))
			button.add_theme_stylebox_override("pressed", _box(NAVY, MUSTARD, 7, 2))
		var picked = value
		button.pressed.connect(func() -> void: choose(shift, field, picked))
		row.add_child(button)
		if selected and (active or _guide_step() == 0):
			column.add_child(_wrap(_option_cost(option.cost), 13, MUTED))
	return box

func _render_task(column: VBoxContainer, current: Dictionary) -> void:
	var action := String(current.get("action", ""))
	if not action in ["PUMP", "STACK"]:
		if action == "WAIT":
			column.add_child(_wrap("Waiting has no task. The shelter you prepared is what protects the crew.", 13, MUTED))
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
	var title := "Pump water · confirm the three valves in order" if action == "PUMP" else "Stack supplies · place the four bundles in the outlined bunk slots"
	inner.add_child(_wrap(title, 13, IVORY))
	var outcome := ""
	if action == "PUMP":
		outcome = "Water wall +2 when all three valves are confirmed; +1 if partial."
	else:
		outcome = "Crates 2 when all four bundles are placed; 1 if partial."
	inner.add_child(_wrap(outcome, 12, MUTED))
	if state == "idle":
		var start := _button("Start %s%s" % ["pumping water" if action == "PUMP" else "placing supplies", " · no timer (assisted)" if assisted else " · %d seconds" % int(alarm.get("timer_seconds", 0))], "TaskStep_0")
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
			var text := "%s %d. %s" % ["✓" if is_done else "○", index + 1, _sentence_case(String(labels[index])) if index < labels.size() else "Step"]
			var step := _button(text, "TaskStep_%d" % (index + 1))
			step.disabled = is_done or state != "running"
			step.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var step_index := index
			step.pressed.connect(func() -> void: task_step(step_index))
			grid.add_child(step)
		inner.add_child(_wrap("Steps complete: %d of %d%s" % [progress, steps, " · finished" if state == "resolved" else ""], 13, GREEN if state == "resolved" else MUSTARD))
		if state == "running":
			if not bool(alarm.get("assisted", true)):
				var timer := _label("%d s left · the task resolves with the steps done" % ceili(_task_time_left), 12, MUSTARD)
				timer.name = "TaskTimer"
				inner.add_child(timer)
			var end := _button("Finish with %d of %d steps" % [progress, steps], "EndTask")
			end.pressed.connect(func() -> void: end_task())
			inner.add_child(end)
	column.add_child(box)


func _render_forecast() -> Control:
	var shifts: Array = _view.get("shifts", [])
	var heading := "Now → after this plan" if shifts.is_empty() else "Now → after shift %d" % int(shifts.back())
	if shifts.size() > 1:
		heading = "Now → after shifts %d to %d" % [int(shifts.front()), int(shifts.back())]
	var column := _column(heading, 0)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var resources: Dictionary = _view.get("resources", {})
	var forecast: Dictionary = _view.get("gate_preview", {})
	var after: Dictionary = forecast.get("final_state", {}) if forecast.get("accepted", false) else {}
	for row in [["E", "Battery", "energy_capacity", "battery units"], ["A", "Air", "air_capacity", "air units"], ["H", "Alo", "health_capacity", "health"], ["C", "Garden", "crop_capacity", "condition"]]:
		_forecast_bar(column, row[1], float(resources.get(row[0], 0)), float(after.get(row[0], resources.get(row[0], 0))), float(resources.get(row[2], 10)), row[3], not after.is_empty())
	var tara := _tara_status(_route.director().snapshot())
	var tara_row := _column("Tara · current reference", 0)
	tara_row.name = "Forecast_Tara"
	tara_row.add_child(_wrap(tara + " → unchanged by this shift model", 14, IVORY))
	var reference := ProgressBar.new()
	reference.show_percentage = false
	reference.max_value = 1
	reference.value = 1 if tara.begins_with("Alive") else 0
	reference.tooltip_text = "Current alive status only; this model has no numeric Tara health forecast."
	reference.custom_minimum_size.y = 8
	tara_row.add_child(reference)
	column.add_child(tara_row)
	var sim := Simulation.new()
	var now: Dictionary = sim.outpost_readouts(_route.director().snapshot())
	var later: Dictionary = sim.outpost_readouts(forecast.snapshot) if not after.is_empty() else now
	_forecast_bar(column, "Shelter", now.shelter_capacity, later.shelter_capacity, now.shelter_max, "shielding units", not after.is_empty(), "Storm shelter")
	_forecast_bar(column, "Radiation", float(resources.get("Z", 0)), float(after.get("Z", resources.get("Z", 0))), 3, "training units · safe limit 3", not after.is_empty(), "Radiation dose")
	column.add_child(_wrap("Water in wall: %s of %s → %s · Supplies: %s of %s → %s" % [_amount(resources.get("W", 0)), _amount(resources.get("water_capacity", 0)), _amount(after.get("W", resources.get("W", 0))), _amount(resources.get("K", 0)), _amount(resources.get("crate_capacity", 0)), _amount(after.get("K", resources.get("K", 0)))], 13, MUTED))

	if not after.is_empty():
		var consequence := _wrap(_consequence(forecast), 15, RED if not forecast.get("unsafe_predicates", []).is_empty() else MUSTARD)
		consequence.name = "ForecastConsequence"
		column.add_child(consequence)
		if _more:
			for record in forecast.get("trace", []):
				column.add_child(_wrap(_trace_text(record), 13, IVORY))
	else:
		column.add_child(_wrap("Choose the missing settings to see their forecast. Nothing changes until you lock in.", 14, MUTED))
	return column

func _render_projection(column: VBoxContainer) -> void:
	var through := int(_view.get("planned_through", 0))
	var projection: Dictionary = _view.get("night_projection", {})
	column.add_child(_wrap("Whole night · planned through shift %d of 7" % through, 13, CYAN))
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
			column.add_child(_wrap("Projected: " + String(report.get("title", report.get("ending", ""))), 14, GREEN if bool(report.get("unlocks_chapter2", false)) else RED))
			column.add_child(_wrap("%s Crew exposure ≤ 3   %s No blackout   %s Alo alive" % [_star(stars.get("safe_exposure", false)), _star(stars.get("no_blackout", false)), _star(stars.get("alo_alive", false))], 12, IVORY))
			for predicate in report.get("unsafe_predicates", []):
				column.add_child(_wrap("Cause: " + _predicate_text(String(predicate)), 12, RED))
		elif through < 7:
			column.add_child(_wrap("Shifts %d–7 are not planned yet." % (through + 1), 12, MUTED))
	column.add_child(_wrap(_known_events_text(), 12, MUTED))

func _render_footer() -> void:
	var reason := _commit_reason()
	var status := _wrap(_notice if not _notice.is_empty() else (reason if not reason.is_empty() else "Ready. Lock in shift, then confirm. Nothing changes before confirmation."), 13, MUSTARD if not reason.is_empty() else GREEN)
	status.name = "TableStatus"
	_content.add_child(status)
	var row := HFlowContainer.new()
	row.name = "TableFooter"
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 6)
	_content.add_child(row)
	var try_button := _button("Try it", "Preview")
	try_button.pressed.connect(func() -> void: preview())
	if _guide_step() == 3:
		try_button.add_theme_stylebox_override("normal", _box(NAVY, MUSTARD, 7, 2))
	row.add_child(try_button)
	var commit := _button("Prepare shift (Space)" if _view.get("gate", {}).get("preview_only", false) else "Lock in shift (Space)", "Commit")
	commit.disabled = not reason.is_empty()
	commit.tooltip_text = display_text(reason) if not reason.is_empty() else "Opens the confirmation. Space or controller Y confirms."
	commit.pressed.connect(func() -> void: request_commit())
	row.add_child(commit)
	var close_button := _button("Close (Esc)", "CloseTable")
	close_button.pressed.connect(close)
	row.add_child(close_button)
	var more := _button("Less" if _more else "More", "TableMore")
	more.pressed.connect(func() -> void:
		_more = not _more
		_focus_name = "TableMore"
		_render())
	row.add_child(more)
	var hint := _button("Hint", "Hint")
	hint.pressed.connect(reveal_hint)
	row.add_child(hint)
	if hint_player != null:
		var how_to := _button("How to", "TableHowTo")
		how_to.pressed.connect(func():
			hint_player.set_settings(_settings)
			hint_player.show_how_to("mission_table", false, _hint_target()))
		row.add_child(how_to)

func _render_confirmation() -> void:
	_body.add_child(_wrap("Lock in this plan?", 22, MUSTARD))
	_body.add_child(_wrap("This prepares shift 2 for the drill. No time passes." if _view.get("gate", {}).get("preview_only", false) else "These choices will change the station. Retry can restore the checkpoint before this shift.", 16, IVORY))
	_body.add_child(_render_forecast())
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 8)
	_content.add_child(row)
	var back := _button("Back (Esc)", "CancelCommit")
	back.pressed.connect(cancel_confirm)
	row.add_child(back)
	var confirm := _button("Confirm (Space)", "ConfirmCommit")
	confirm.pressed.connect(func() -> void: confirm_commit())
	row.add_child(confirm)

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
		parts.append("storm shelter %d shielding units, radiation dose %d training units" % [int(record.get("shelter", 0)), int(record.get("dose", 0))])
	if String(record.get("action", "")) in ["PUMP", "STACK"]:
		parts.append("%s: %d step%s%s" % [_option_word("action", record.action, record.action), int(record.get("action_progress", 0)), "" if int(record.get("action_progress", 0)) == 1 else "s", "" if bool(record.get("action_success", false)) else " (partly finished)"])
	if bool(record.get("crates_removed", false)):
		parts.append("crates removed")
	if bool(record.get("blackout", false)):
		parts.append("Blackout: demand exceeded available battery; air, Alo and garden health −2")
	elif int(after.get("E", 1)) == 0:
		parts.append("battery empty (exactly 0 is not a blackout)")
	return " · ".join(parts)

func _predicate_text(predicate: String) -> String:
	return display_text(predicate)

func _known_events_text() -> String:
	var lines: Array = ["Known ahead:"]
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
	return Debrief.readings(values)

func _amount(value) -> String:
	var number := float(value)
	return str(int(number)) if is_equal_approx(number, round(number)) else "%.1f" % number

func _star(value) -> String:
	return "★" if bool(value) else "☆"

# --- State helpers -------------------------------------------------------------

func _table() -> RefCounted:
	return _route.mission_table()

func _committed() -> int:
	return int(_view.get("committed_shift", 0)) if not _view.is_empty() else int(_route.director().query().get("current_shift", 0))

func _refresh_view() -> void:
	_view = _route.mission_table_view(_target_id)

func _plan_key() -> String:
	return JSON.stringify(_table().plan_for_gate(_target_id)) + "@" + str(_committed())

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
	if hint_player != null and hint_player.is_open():
		return
	if is_instance_valid(target) and target.is_inside_tree() and not target.is_queued_for_deletion() and visible:
		target.grab_focus()
		if _guide_step() > 0 and String(target.name).begins_with("Choice_1_"):
			var scroll := find_child("TableBodyScroll", true, false) as ScrollContainer
			# Follow-focus can scroll before the rebuilt rows have their final size.
			if scroll != null:
				_scroll_after_layout(get_tree(), weakref(scroll))

# A static continuation can outlive the panel without resuming a freed instance.
static func _scroll_after_layout(tree: SceneTree, weak_scroll: WeakRef) -> void:
	await tree.process_frame
	await tree.process_frame
	var scroll := weak_scroll.get_ref() as ScrollContainer
	if is_instance_valid(scroll) and scroll.is_inside_tree():
		scroll.scroll_vertical = 0

func _grab_first_focus() -> void:
	if _guide_step() > 0:
		var choice := find_child("Choice_1_air_production_0" if _guide_step() == 1 else "Choice_1_light_OFF", true, false) as Control
		if choice != null:
			_focus_later(choice)
			return
	for card in _view.get("cards", []):
		if bool(card.get("arrived", false)) and not bool(card.get("shared", false)):
			var share := find_child("Share_" + String(card.role_id), true, false) as Control
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
	return int(round(maxi(12, size) * _scale()))

# --- Widget helpers ------------------------------------------------------------

func _scroll(column: Control, node_name: String) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = node_name
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
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
	var style := _box(NAVY if available else NAVY_DEEP, border, 9, 1)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	box.add_theme_stylebox_override("panel", style)
	return box

func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = display_text(text)
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
	button.text = display_text(text)
	button.custom_minimum_size = Vector2(0, maxf(MIN_TARGET, 32 * _scale()))
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", _fs(14))
	button.add_theme_color_override("font_color", IVORY)
	button.add_theme_color_override("font_pressed_color", IVORY)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_focus_color", IVORY)
	button.add_theme_color_override("font_disabled_color", Color(0.66, 0.71, 0.78, 0.75))
	button.add_theme_stylebox_override("normal", _box(NAVY, Color(0.32, 0.45, 0.66, 0.9), 7, 1))
	button.add_theme_stylebox_override("pressed", _box(NAVY, Color(0.32, 0.45, 0.66, 0.9), 7, 1))
	button.add_theme_stylebox_override("hover", _box(MUSTARD, INK, 7, 2))
	button.add_theme_stylebox_override("focus", _box(Color(0, 0, 0, 0), IVORY, 7, 3))
	button.add_theme_stylebox_override("disabled", _box(NAVY_DEEP, MUTED, 7, 1))
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

func _arrived(id: String) -> bool:
	for card in _view.get("cards", []):
		if card.role_id == id:
			return bool(card.arrived)
	return false

func _guide_step() -> int:
	if _target_id != "p02_shift1" or _committed() > 0:
		return 0
	var choice: Dictionary = _table().selection(1)
	return 1 if not choice.has("air_production") else (2 if not choice.has("light") else 3)

func _forecast_bar(column: VBoxContainer, id: String, before: float, after: float, maximum: float, unit: String, predicted: bool, word: String = "") -> void:
	var row := VBoxContainer.new()
	row.name = "Forecast_" + id
	column.add_child(row)
	row.add_child(_wrap("%s · %s of %s → %s · %s" % [id if word.is_empty() else word, _amount(before), _amount(maximum), _amount(after) if predicted else "choose settings", unit], 14, IVORY))
	var bars := HBoxContainer.new()
	row.add_child(bars)
	for value in [before, after]:
		var bar := ProgressBar.new()
		bar.max_value = maximum
		bar.value = value
		bar.show_percentage = false
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.custom_minimum_size.y = 8
		bar.add_theme_stylebox_override("fill", _box(MUTED if bars.get_child_count() == 0 else CYAN, Color.TRANSPARENT, 3, 0))
		bars.add_child(bar)

func _tara_status(state: Dictionary) -> String:
	for plant in state.get("plants", []):
		if String(plant.get("individual_id", "")) == "TARA-01":
			var stress: Dictionary = plant.get("stress", {})
			var concerns: Array[String] = []
			for key in stress:
				if float(stress[key]) > 0:
					concerns.append(String(key).replace("_", " "))
			return "%s · %s · %s" % ["Alive" if plant.get("alive", false) else "Not alive", String(plant.get("stage", "unknown")).replace("_", " "), "No stress recorded" if concerns.is_empty() else "Stress: " + ", ".join(concerns)]
	return "Not yet recorded"

func _consequence(forecast: Dictionary) -> String:
	var unsafe: Array = forecast.get("unsafe_predicates", [])
	if not unsafe.is_empty():
		return _predicate_text(String(unsafe[0])).capitalize() + ". Retry is available after locking in."
	for record in forecast.get("trace", []):
		if record.get("blackout", false):
			return "Demand exceeds the battery: a blackout reduces air, Alo and garden health."
		if int(record.get("dose", 0)) > 0:
			return "Storm shelter %d gives +%d training radiation units this shift, before any ordinary water return." % [int(record.shelter), int(record.dose)]
	var before: Dictionary = _view.get("resources", {})
	var after: Dictionary = forecast.get("final_state", {})
	var biggest := -1.0
	var message := "The displayed readings stay unchanged."
	for spec in [["E", "Battery", "energy_capacity"], ["A", "Air", "air_capacity"], ["H", "Alo health", "health_capacity"], ["C", "Garden health", "crop_capacity"]]:
		var change := float(after.get(spec[0], 0)) - float(before.get(spec[0], 0))
		var fraction := absf(change) / maxf(1, float(before.get(spec[2], 10)))
		if fraction > biggest:
			biggest = fraction
			message = "%s %s to %s of %s after this plan." % [spec[1], "rises" if change > 0 else ("drops" if change < 0 else "stays"), _amount(after.get(spec[0], 0)), _amount(before.get(spec[2], 10))]
	return message

## One display mapper for the table and the HUD's failed-plan result.
static func display_text(value: String) -> String:
	var result := value
	var task_words := {
		"Run the STACK task and finish or end it before committing.": "Place the supplies, then finish the task before locking in.",
		"Run the PUMP task and finish or end it before committing.": "Confirm the valves, then finish the task before locking in.",
		"bundle task": "Place supplies", "valve task": "Confirm valves",
		"forces COOL, air OFF, light OFF": "sets heat to Cool, air maker Off and garden light Off",
		"STACK task": "Supply placement", "PUMP task": "Water pumping",
		"already resolved": "already finished", "Task resolved": "Task finished",
	}
	for phrase in task_words:
		result = result.replace(phrase, task_words[phrase])
	for spec in [["crates ([0-9]+) \\(partial ([0-9]+)\\)", "$1 supply bundles ($2 if partly finished)"], ["wall ([+][0-9]+) \\(partial ([+][0-9]+)\\)", "shelter water $1 ($2 if partly finished)"]]:
		var task_cost := RegEx.new()
		task_cost.compile(spec[0])
		result = task_cost.sub(result, spec[1], true)
	var unsafe := RegEx.new()
	unsafe.compile("(air_depleted|exposure_limit_exceeded|crew_shelter_breach|resupply_required)_shift_([0-9]+)")
	for hit in unsafe.search_all(result):
		var cause: String = {"air_depleted": "Air reached zero", "exposure_limit_exceeded": "Radiation dose exceeded the safe limit of 3 training units", "crew_shelter_breach": "The crew was outside the storm shelter", "resupply_required": "Food ran short; resupply is required"}[hit.get_string(1)]
		result = result.replace(hit.get_string(), cause + " in shift " + hit.get_string(2))
	result = result.replace("MISSION_STOPPED", "Attempt stopped safely").replace("MISSION STOPPED", "Attempt stopped safely")
	var units := RegEx.new()
	units.compile("\\b([EAWHKCSZR])([0-9]+)\\b")
	for hit in units.search_all(result):
		result = result.replace(hit.get_string(), String({"E": "Battery ", "A": "Air ", "H": "Alo health ", "C": "Garden health ", "W": "Shelter water ", "K": "Shelter supplies ", "S": "Storm shelter ", "Z": "Radiation dose ", "R": "Food "}[hit.get_string(1)]) + hit.get_string(2))
	result = result.replace("Shelter S =", "Storm shelter =").replace("S 0", "Storm shelter 0")
	return UiDesign.player_words(result)

## Prepare approved cast art only after the table opens; title preparation stays unchanged.
func _prepare_portrait(id: String) -> void:
	var person := "CH_" + id.capitalize()
	var path := "res://assets/characters/%s/%s.glb" % [person, person]
	if not await AssetGeometry.prepare(path, get_tree()) or not is_inside_tree():
		return
	var view := SubViewport.new()
	view.size = Vector2i(144, 168)
	view.own_world_3d = true
	view.transparent_bg = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(view)
	var actor := AssetGeometry.load_glb(path)
	view.add_child(actor)
	var bounds := AssetGeometry.bounds(actor)
	var camera := Camera3D.new()
	view.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = bounds.size.y * 0.48
	var face := Vector3(bounds.get_center().x, bounds.position.y + bounds.size.y * 0.82, bounds.get_center().z)
	camera.position = face + Vector3(0, 0, bounds.size.y)
	camera.look_at(face)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-25, -25, 0)
	light.light_energy = 1.5
	view.add_child(light)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.7
	view.add_child(environment)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	_portraits[id] = ImageTexture.create_from_image(view.get_texture().get_image())
	view.queue_free()
	var portrait := find_child("Portrait_" + id, true, false) as TextureRect
	if portrait != null:
		portrait.texture = _portraits[id]
