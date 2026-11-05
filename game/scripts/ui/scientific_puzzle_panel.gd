extends Control
class_name ScientificPuzzlePanel

## Interactive Scientific Puzzle Panel (execution/UI_09_SCIENTIFIC_PUZZLE.md)
## for Chapter 3 puzzles:
## - Find the Falling Pressure (mechanical gauge, 6 candidates, 4 phases, collar clamp)
## - A Harvest With a Future (maturity check, 5-day dry-down vigil, 6 wells of 7, 12 + 30 split)
##
## This panel edits the route's P05FallingPressure / P06HarvestFuture model,
## shows read-only before -> after previews and non-punishing diagnostic feedback,
## and emits commit_requested(target_id, payload) only after explicit confirmation.

signal commit_requested(target_id: String, payload: Dictionary)
signal panel_closed()

const ScienceScript = preload("res://scripts/science/science_data.gd")
const P05Script = preload("res://scripts/puzzles/p05_falling_pressure.gd")
const P06Script = preload("res://scripts/puzzles/p06_harvest_future.gd")

const BG_SCRIM := Color(0.02, 0.03, 0.06, 0.88)
const PANEL_BG := Color("#0B101B")
const CARD_BG := Color("#121A2B")
const CARD_ALT := Color("#172238")
const BORDER_CYAN := Color("#20B8C9")
const MUSTARD := Color("#F2C230")
const IVORY := Color("#ECEEF0")
const MUTED := Color("#A8B4C8")
const GREEN := Color("#4CAF50")
const AMBER := Color("#FFB300")
const CORAL := Color("#FF7043")

var _science := ScienceScript.new()
var _route: RefCounted
var _target_id := ""
var _puzzle_id := "P-05"
var _settings := {"large_text": false, "timer_free": true, "reduced_motion": false}
var _mode := "cadet"
var _previewed := false
var _last_preview := {}
var _confirm_open := false
var _leave_confirm_open := false
var _data_card_open := false
var _dirty := false
var _initial_model_snapshot := {}
var _commit_sent := false

var _scrim: ColorRect
var _shell: PanelContainer
var _root_vbox: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	hide()
	_build_chrome()

## Returns true when the Scientific Puzzle Panel is currently visible.
func is_open() -> bool:
	return visible and _route != null

## Opens the interactive panel for a Chapter 3 puzzle gate.
func open(route: RefCounted, target_id: String = "", settings: Dictionary = {}) -> void:
	_route = route
	_target_id = target_id
	for k in settings:
		_settings[k] = settings[k]
	if _route != null:
		var view: Dictionary = _route.puzzle_view(_target_id)
		_puzzle_id = String(view.get("puzzle_id", "P-05"))
		_target_id = String(view.get("target_id", _target_id))
		_initial_model_snapshot = _active_model().snapshot()
	_previewed = false
	_last_preview = {}
	_confirm_open = false
	_leave_confirm_open = false
	_data_card_open = false
	_dirty = false
	_commit_sent = false
	show()
	_render()

## Closes the panel immediately and emits panel_closed.
func close() -> void:
	if not visible:
		return
	_confirm_open = false
	_leave_confirm_open = false
	_data_card_open = false
	hide()
	panel_closed.emit()

## Requests to step back from the panel; prompts for confirmation if uncommitted changes exist.
func request_close() -> Dictionary:
	if _dirty and not _leave_confirm_open:
		_leave_confirm_open = true
		_render()
		return {"accepted": false, "confirm_required": true, "reason": "You have uncommitted changes on the workbench. Confirm leaving or keep working."}
	close()
	return {"accepted": true}

## Discards uncommitted edits made since opening the panel and closes it.
func confirm_discard_and_close() -> Dictionary:
	undo_changes()
	close()
	return {"accepted": true}

## Reverts all uncommitted changes made in the panel back to the state when opened.
func undo_changes() -> Dictionary:
	if _route == null:
		return {"accepted": false, "reason": "No active route."}
	_active_model().restore(_initial_model_snapshot)
	_dirty = false
	_previewed = false
	_last_preview = {}
	_confirm_open = false
	_leave_confirm_open = false
	_render()
	return {"accepted": true}

## Switches between Family ("family"), Cadet ("cadet"), and Engineer ("engineer") assistance modes.
func set_mode(mode_id: String) -> Dictionary:
	if mode_id not in ["family", "cadet", "engineer"]:
		return {"accepted": false, "reason": "Unknown mode: " + mode_id}
	_mode = mode_id
	_render()
	return {"accepted": true, "mode": _mode}

## Shares a crew member's clue card in Class or Solo mode.
func share_card(role_id: String) -> Dictionary:
	if _route == null:
		return {"accepted": false, "reason": "No active route."}
	var res: Dictionary = _active_model().share(role_id, _route.current_scene_id())
	_mark_changed(false)
	return res

## Records the player's Predict -> Act -> See hypothesis.
func select_prediction(option_id: String) -> Dictionary:
	if _route == null:
		return {"accepted": false, "reason": "No active route."}
	var res: Dictionary = _active_model().set_prediction(option_id)
	_mark_changed(true)
	return res

## Reveals the next progressive hint (H1 -> H2 -> H3).
func request_hint() -> Dictionary:
	if _route == null:
		return {"accepted": false, "reason": "No active route."}
	var res: Dictionary = _active_model().next_hint()
	_render()
	return res

## Toggles the offline NASA Data Card drawer.
func toggle_data_card() -> Dictionary:
	_data_card_open = not _data_card_open
	_render()
	return {"accepted": true, "data_card_open": _data_card_open}

## Runs a read-only preview of the current workbench state ("Try it").
func preview() -> Dictionary:
	if _route == null:
		return {"accepted": false, "reason": "No active route."}
	var model := _active_model()
	var block: String = model.commit_block_reason(_target_id)
	if not block.is_empty():
		model.prepare_gate_from_panel(_target_id)
		block = model.commit_block_reason(_target_id)
	if not block.is_empty():
		_previewed = false
		_last_preview = {"accepted": false, "reason": block}
		_render()
		return _last_preview.duplicate(true)
	var payload: Dictionary = model.payload_for_action(_target_id)
	var before_state: Dictionary = _route.director().snapshot()
	_route.focus(_target_id)
	_route.inspect()
	_route.use(payload)
	var sim_preview: Dictionary = _route.preview()
	_route.cancel_interaction("panel_preview_only") if _route.has_method("cancel_interaction") else _route.dispatcher().cancel("panel_preview_only")
	_previewed = bool(sim_preview.get("accepted", false))
	_last_preview = {
		"accepted": _previewed,
		"target_id": _target_id,
		"payload": payload.duplicate(true),
		"before_resources": before_state.get("resources", {}).duplicate(true),
		"after_resources": sim_preview.get("snapshot", before_state).get("resources", {}).duplicate(true),
		"before_inventories": before_state.get("inventories", {}).duplicate(true),
		"after_inventories": sim_preview.get("snapshot", before_state).get("inventories", {}).duplicate(true),
		"reason": String(sim_preview.get("reason", "Preview ready.")),
	}
	_render()
	return _last_preview.duplicate(true)

## Opens the Lock In confirmation dialog after verifying the current state was previewed.
func request_commit() -> Dictionary:
	if _route == null:
		return {"accepted": false, "reason": "No active route."}
	var block: String = _active_model().commit_block_reason(_target_id)
	if not block.is_empty():
		return {"accepted": false, "reason": block}
	if not _previewed:
		return {"accepted": false, "reason": "Press TRY IT (PREVIEW) first to inspect the before and after readings before locking in."}
	_confirm_open = true
	_render()
	return {"accepted": true, "confirm_open": true}

## Confirms Lock In once, emits commit_requested(target_id, payload), and closes the panel.
func confirm_commit() -> Dictionary:
	if _commit_sent or not _confirm_open or not _previewed or _route == null:
		return {"accepted": false, "reason": "Preview and request Lock In before confirming."}
	var block: String = _active_model().commit_block_reason(_target_id)
	if not block.is_empty():
		return {"accepted": false, "reason": block}
	_commit_sent = true
	_dirty = false
	var payload: Dictionary = _active_model().payload_for_action(_target_id)
	close()
	commit_requested.emit(_target_id, payload)
	return {"accepted": true, "target_id": _target_id, "payload": payload}

func _input(event: InputEvent) -> void:
	if not is_open() or not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	if key.physical_keycode == KEY_SPACE:
		if _confirm_open:
			confirm_commit()
			get_viewport().set_input_as_handled()
		elif _previewed:
			request_commit()
			get_viewport().set_input_as_handled()
	elif key.physical_keycode == KEY_ESCAPE:
		if _confirm_open:
			_confirm_open = false
			_render()
		else:
			request_close()
		get_viewport().set_input_as_handled()

func _active_model() -> RefCounted:
	if _route == null:
		return P05Script.new()
	return _route.p06() if _puzzle_id == "P-06" else _route.p05()

func _mark_changed(invalidate_preview: bool = true) -> void:
	_dirty = true
	if invalidate_preview:
		_previewed = false
		_confirm_open = false
	_render()

func _scale() -> float:
	return 1.5 if bool(_settings.get("large_text", false)) else 1.0

func _font_px(base: int) -> int:
	return int(round(float(base) * _scale()))

func _build_chrome() -> void:
	_scrim = ColorRect.new()
	_scrim.color = BG_SCRIM
	_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_scrim)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	_shell = PanelContainer.new()
	_shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_shell.add_theme_stylebox_override("panel", _box_style(PANEL_BG, BORDER_CYAN, 2, 10, 18))
	margin.add_child(_shell)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	_shell.add_child(scroll)

	_root_vbox = VBoxContainer.new()
	_root_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root_vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(_root_vbox)

func _render() -> void:
	if _root_vbox == null or _route == null:
		return
	for child in _root_vbox.get_children():
		_root_vbox.remove_child(child)
		child.queue_free()

	var view: Dictionary = _route.puzzle_view(_target_id)
	_puzzle_id = String(view.get("puzzle_id", _puzzle_id))

	_render_header(view)
	if not bool(view.get("guided_intro_seen", false)):
		_render_guided_intro(view)
	if _leave_confirm_open:
		_render_leave_confirm()
	if _confirm_open:
		_render_commit_confirm(view)
	if _data_card_open:
		_render_data_cards(view)

	var columns := HBoxContainer.new()
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 14)
	_root_vbox.add_child(columns)

	var left := _column_card("Observed Readings & Crew Notes", 310)
	columns.add_child(left.panel)
	_render_left_column(left.body, view)

	var centre := _column_card("Interactive Workbench", 480, true)
	columns.add_child(centre.panel)
	if _puzzle_id == "P-06":
		_render_p06_workbench(centre.body, view)
	else:
		_render_p05_workbench(centre.body, view)

	var right := _column_card("Before → After Forecast & Guidance", 320)
	columns.add_child(right.panel)
	_render_right_column(right.body, view)

	_render_footer(view)

func _render_header(view: Dictionary) -> void:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	_root_vbox.add_child(header)

	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", 4)
	header.add_child(titles)

	var title_lbl := _label(String(view.get("title", "Scientific Workbench")), _font_px(22), MUSTARD)
	titles.add_child(title_lbl)
	var sub_lbl := _label(String(view.get("headline", view.get("subtitle", ""))), _font_px(14), CYAN_COLOR())
	titles.add_child(sub_lbl)

	var stage_bar := HBoxContainer.new()
	stage_bar.add_theme_constant_override("separation", 6)
	titles.add_child(stage_bar)
	var current_stage := String(view.get("stage_id", "learn"))
	for stage in view.get("stages", []):
		var sid := String(stage.get("id", ""))
		var active := sid == current_stage
		var pill := _label(
			("%s %s" % ["●" if active else "○", String(stage.get("title", sid))]),
			_font_px(12),
			MUSTARD if active else MUTED
		)
		stage_bar.add_child(pill)

	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 6)
	header.add_child(mode_row)
	for pair in [["family", "Family"], ["cadet", "Cadet"], ["engineer", "Engineer"]]:
		var btn := _action_button(pair[1], "Mode_" + pair[0], _mode == pair[0])
		btn.pressed.connect(func(): set_mode(pair[0]))
		mode_row.add_child(btn)

	var card_btn := _action_button("Data Card", "DataCardButton", _data_card_open)
	card_btn.pressed.connect(toggle_data_card)
	header.add_child(card_btn)

	var close_btn := _action_button("Step Back", "StepBackButton")
	close_btn.pressed.connect(request_close)
	header.add_child(close_btn)

func _render_guided_intro(view: Dictionary) -> void:
	var intro: Dictionary = view.get("guided_intro", {})
	if intro.is_empty():
		return
	var card := PanelContainer.new()
	card.name = "GuidedFirstUseCard"
	card.add_theme_stylebox_override("panel", _box_style(CARD_ALT, MUSTARD, 1, 8, 12))
	_root_vbox.add_child(card)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)

	box.add_child(_label("FIRST-TIME GUIDE · " + String(intro.get("headline", "")).to_upper(), _font_px(14), MUSTARD))
	box.add_child(_label(String(intro.get("why_now", "")), _font_px(13), IVORY))
	box.add_child(_label("First step: " + String(intro.get("first_step", "")), _font_px(13), CYAN_COLOR()))

	var clip: Dictionary = intro.get("explainer_clip", {})
	if bool(view.get("explainer_watched", false)) and not clip.is_empty():
		for step_text in clip.get("steps", []):
			box.add_child(_label("  • " + String(step_text), _font_px(12), GREEN))

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	box.add_child(actions)

	var watch_btn := _action_button("Watch 12s Explainer", "WatchExplainer")
	watch_btn.pressed.connect(func():
		_active_model().watch_explainer()
		_render()
	)
	actions.add_child(watch_btn)

	var got_it := _action_button("Got It · Start Working", "DismissGuide")
	got_it.pressed.connect(func():
		_active_model().acknowledge_guided_intro()
		_render()
	)
	actions.add_child(got_it)

func _render_leave_confirm() -> void:
	var bar := PanelContainer.new()
	bar.name = "LeaveConfirmBanner"
	bar.add_theme_stylebox_override("panel", _box_style(CARD_ALT, AMBER, 2, 8, 12))
	_root_vbox.add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	bar.add_child(row)
	var lbl := _label("You have uncommitted changes on the workbench. Discard them and step back, or keep working?", _font_px(13), AMBER)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)
	var keep_btn := _action_button("Keep Working", "KeepWorking")
	keep_btn.pressed.connect(func():
		_leave_confirm_open = false
		_render()
	)
	row.add_child(keep_btn)
	var discard_btn := _action_button("Discard & Leave", "DiscardAndLeave")
	discard_btn.pressed.connect(confirm_discard_and_close)
	row.add_child(discard_btn)

func _render_commit_confirm(view: Dictionary) -> void:
	var bar := PanelContainer.new()
	bar.name = "ConfirmCommitBanner"
	bar.add_theme_stylebox_override("panel", _box_style(CARD_ALT, GREEN, 2, 8, 12))
	_root_vbox.add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	bar.add_child(row)
	var lbl := _label("Ready to lock in '%s'? Press Space or click Confirm Lock In." % _clean_text(String(view.get("headline", "this step"))), _font_px(14), GREEN)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)
	var confirm_btn := _action_button("Confirm Lock In", "ConfirmCommit", true)
	confirm_btn.pressed.connect(confirm_commit)
	row.add_child(confirm_btn)
	var cancel_btn := _action_button("Cancel", "CancelCommit")
	cancel_btn.pressed.connect(func():
		_confirm_open = false
		_render()
	)
	row.add_child(cancel_btn)

func _render_data_cards(view: Dictionary) -> void:
	var drawer := PanelContainer.new()
	drawer.name = "DataCardDrawer"
	drawer.add_theme_stylebox_override("panel", _box_style(CARD_ALT, BORDER_CYAN, 1, 8, 12))
	_root_vbox.add_child(drawer)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	drawer.add_child(box)
	box.add_child(_label("SCIENCE DATA CARDS · REAL REFERENCE EVIDENCE", _font_px(14), MUSTARD))
	for card in _science.cards_for_puzzle(_puzzle_id):
		var title := String(card.get("title", "Reference Dataset"))
		var agency := String(card.get("agency", ""))
		var takeaway := String(card.get("takeaway", ""))
		var boundary := String(card.get("boundary", ""))
		box.add_child(_label("• %s (%s): %s" % [title, agency, takeaway], _font_px(13), IVORY))
		if _mode == "engineer" and not boundary.is_empty():
			box.add_child(_label("  Scope note: " + boundary, _font_px(12), MUTED))

func _render_left_column(body: VBoxContainer, view: Dictionary) -> void:
	# Station readings in plain words (no single-letter codes).
	var res: Dictionary = view.get("resources", {})
	var meter_text := "Battery: %s/%s   ·   Air: %s/%s\nAlo health: %s   ·   Garden health: %s   ·   Food (days): %s" % [
		str(res.get("E", 14)), str(res.get("energy_capacity", 20)),
		str(res.get("A", 10)), str(res.get("air_capacity", 10)),
		str(res.get("H", 6)), str(res.get("C", 8)), str(res.get("R", 18.0)),
	]
	body.add_child(_label(meter_text, _font_px(13), IVORY))

	# Predict -> Act -> See hypothesis step.
	var pred_spec: Dictionary = view.get("prediction_spec", {})
	if not pred_spec.is_empty():
		body.add_child(HSeparator.new())
		body.add_child(_label("1. Predict Before Testing", _font_px(14), MUSTARD))
		body.add_child(_label(String(pred_spec.get("prompt", "")), _font_px(12), MUTED))
		var current_pred := String(view.get("prediction", ""))
		for opt in pred_spec.get("options", []):
			var oid := String(opt.get("id", ""))
			var active := current_pred == oid
			var btn := _action_button(
				("%s %s" % ["✓" if active else "○", String(opt.get("label", oid))]),
				"Predict_" + oid,
				active
			)
			btn.pressed.connect(func(): select_prediction(oid))
			body.add_child(btn)

	# Crew role cards (Class / Solo mode).
	body.add_child(HSeparator.new())
	body.add_child(_label("2. Crew Notes & Clues", _font_px(14), MUSTARD))
	for card in view.get("role_cards", []):
		var role_id := String(card.get("role_id", ""))
		var arrived := bool(card.get("arrived", true))
		var shared := bool(card.get("shared", false))
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 4)
		body.add_child(box)
		box.add_child(_label("%s · %s" % [String(card.get("name", "")), String(card.get("role", ""))], _font_px(13), CYAN_COLOR()))
		if arrived:
			for fact in card.get("facts", []):
				box.add_child(_label("• " + _clean_text(String(fact)), _font_px(12), IVORY))
			var share_btn := _action_button(
				"Shared With Crew ✓" if shared else ("Share %s's Note" % String(card.get("name", ""))),
				"Share_" + role_id,
				shared
			)
			share_btn.pressed.connect(func(): share_card(role_id))
			box.add_child(share_btn)
		else:
			box.add_child(_label("Arrives in the next scene.", _font_px(12), MUTED))

func _render_p05_workbench(body: VBoxContainer, view: Dictionary) -> void:
	body.add_child(_label(_clean_text(String(view.get("instruction", ""))), _font_px(13), IVORY))

	# Custom-drawn piping & manual gauge visual schematic.
	var canvas := _PipingSchematicControl.new(view)
	canvas.custom_minimum_size = Vector2(420, 150)
	body.add_child(canvas)

	# Step 1: Gauge & Three Taps.
	body.add_child(_label("Mechanical Gauge & Manual Test Taps (Relative Test Units)", _font_px(14), MUSTARD))
	var equip_row := HBoxContainer.new()
	equip_row.add_theme_constant_override("separation", 8)
	body.add_child(equip_row)
	var eq_btn := _action_button(
		"Gauge Equipped ✓" if bool(view.get("gauge_equipped", false)) else "Equip Mechanical Gauge",
		"EquipGauge",
		bool(view.get("gauge_equipped", false))
	)
	eq_btn.pressed.connect(func():
		_route.p05().equip_gauge()
		_route.p05().read_panel_warning()
		_route.p05().identify_three_taps()
		_mark_changed(true)
	)
	equip_row.add_child(eq_btn)

	var t0_map: Dictionary = view.get("t0_readings", {})
	var t10_map: Dictionary = view.get("t10_readings", {})
	var tap_row := HBoxContainer.new()
	tap_row.add_theme_constant_override("separation", 8)
	body.add_child(tap_row)
	for tap_id in ["MAIN", "GARDEN", "RETURN"]:
		var t0_txt := str(t0_map[tap_id]) if t0_map.has(tap_id) else "—"
		var t10_txt := str(t10_map[tap_id]) if t10_map.has(tap_id) else "—"
		var btn := _action_button(
			"%s: t0=%s → t10=%s" % [tap_id, t0_txt, t10_txt],
			"ReadTap_" + tap_id,
			t0_map.has(tap_id) and t10_map.has(tap_id)
		)
		btn.pressed.connect(func():
			_route.p05().equip_gauge()
			if not _route.p05().view_state().t0_readings.has(tap_id):
				_route.p05().attach_gauge(tap_id, "t0")
			else:
				for other in ["MAIN", "GARDEN", "RETURN"]:
					if not _route.p05().view_state().t0_readings.has(other):
						_route.p05().attach_gauge(other, "t0")
				_route.p05().attach_gauge(tap_id, "t10")
			_mark_changed(true)
		)
		tap_row.add_child(btn)

	# Step 2: Six Candidate Inspections (2 per phase budget).
	var phase := int(view.get("current_phase", 1))
	var phase_list: Array = view.get("phase_inspections", {}).get(phase, [])
	body.add_child(_label("Candidate Inspections · Phase %d of 4 (%d/2 checks used this phase)" % [phase, phase_list.size()], _font_px(14), MUSTARD))
	var cand_grid := GridContainer.new()
	cand_grid.columns = 2
	cand_grid.add_theme_constant_override("h_separation", 8)
	cand_grid.add_theme_constant_override("v_separation", 6)
	body.add_child(cand_grid)
	var inspected: Array = view.get("inspected_candidates", [])
	for cand in view.get("candidates", []):
		var cid := String(cand.get("id", ""))
		var done := inspected.has(cid)
		var cbtn := _action_button(
			("%s %s" % ["✓" if done else "Inspect:", String(cand.get("label", cid))]),
			"Inspect_" + cid,
			done
		)
		cbtn.pressed.connect(func():
			_route.p05().inspect_candidate(cid)
			_mark_changed(true)
		)
		cand_grid.add_child(cbtn)

	var phase_row := HBoxContainer.new()
	phase_row.add_theme_constant_override("separation", 8)
	body.add_child(phase_row)
	var next_phase_btn := _action_button("Advance to Next Diagnostic Phase", "AdvancePhase", phase >= 4)
	next_phase_btn.pressed.connect(func():
		_route.p05().advance_phase()
		_mark_changed(false)
	)
	phase_row.add_child(next_phase_btn)

	var deduce_btn := _action_button(
		"Garden Drop Confirmed (82 → 74) ✓" if bool(view.get("garden_fall_identified", false)) else "Confirm Garden Branch Is Falling",
		"ConfirmGardenFall",
		bool(view.get("garden_fall_identified", false))
	)
	deduce_btn.pressed.connect(func():
		_route.p05().identify_falling_branch("GARDEN")
		_mark_changed(true)
	)
	phase_row.add_child(deduce_btn)

	# Step 3: Isolation, Collar Clamp, 5 Steady Readings & Note Reconciliation.
	body.add_child(_label("Isolation, Collar Clamp & Five Steady Verification Checks", _font_px(14), MUSTARD))
	var repair_grid := GridContainer.new()
	repair_grid.columns = 2
	repair_grid.add_theme_constant_override("h_separation", 8)
	repair_grid.add_theme_constant_override("v_separation", 6)
	body.add_child(repair_grid)

	var annex_btn := _action_button(
		"Annex Auto-Isolation Verified ✓" if bool(view.get("annex_auto_isolated", false)) else "1. Verify Annex Auto-Isolation",
		"VerifyAnnexIsolation",
		bool(view.get("annex_auto_isolated", false))
	)
	annex_btn.pressed.connect(func():
		_route.p05().verify_annex_isolation()
		_route.p05().poll_station("all")
		_mark_changed(true)
	)
	repair_grid.add_child(annex_btn)

	var iso_btn := _action_button(
		"Garden Branch Isolated ✓" if bool(view.get("garden_isolated", false)) else "2. Close Garden Branch Valve Only",
		"IsolateGardenValve",
		bool(view.get("garden_isolated", false))
	)
	iso_btn.pressed.connect(func():
		_route.p05().select_trade_option("isolate_garden")
		_route.p05().isolate_branch("GARDEN")
		_route.p05().verify_main_hold()
		_mark_changed(true)
	)
	repair_grid.add_child(iso_btn)

	var clamp_btn := _action_button(
		"Collar Clamp Seated ✓" if bool(view.get("clamp_seated", false)) else "3. Seat Collar Repair Clamp",
		"SeatCollarClamp",
		bool(view.get("clamp_seated", false))
	)
	clamp_btn.pressed.connect(func():
		_route.p05().seat_repair_clamp("GARDEN")
		_mark_changed(true)
	)
	repair_grid.add_child(clamp_btn)

	var reopen_btn := _action_button(
		"Slow Reopen & 5 Checks Complete ✓" if (view.get("stable_readings", {}) as Dictionary).size() == 5 else "4. Slow-Reopen & Log 5 Steady Checks",
		"SlowReopenAndVerify",
		(view.get("stable_readings", {}) as Dictionary).size() == 5
	)
	reopen_btn.pressed.connect(func():
		_route.p05().reopen_garden(true)
		for step in range(1, 6):
			_route.p05().record_stable_reading(step, 100, 100, 100)
		_route.p05().reconcile_paper_note("fix_note")
		_route.p05().configure_annex_hatch("isolate_feed")
		_route.p05().configure_annex_hatch("confirm_zero_diff")
		_route.p05().configure_annex_hatch("camera_inspect")
		_mark_changed(true)
	)
	repair_grid.add_child(reopen_btn)

	# Wrong-but-reasonable diagnostic checks (safe to test).
	body.add_child(_label("What-If Safety Checks (Test Why Other Choices Fail)", _font_px(13), CYAN_COLOR()))
	var wrong_row := HBoxContainer.new()
	wrong_row.add_theme_constant_override("separation", 6)
	body.add_child(wrong_row)
	for pair in [["isolate_habitat_trunk", "Test: Isolate Habitat Trunk"], ["close_main_valve", "Test: Close Main Reserve"], ["change_valve_to_match_bad_note", "Test: Trust Bad Paper Note"]]:
		var wbtn := _action_button(pair[1], "Wrong_" + pair[0])
		wbtn.pressed.connect(func():
			_route.p05().preview_wrong_action(pair[0])
			_render()
		)
		wrong_row.add_child(wbtn)

func _render_p06_workbench(body: VBoxContainer, view: Dictionary) -> void:
	body.add_child(_label(_clean_text(String(view.get("instruction", ""))), _font_px(13), IVORY))

	# Custom-drawn harvest & dry-down board.
	var canvas := _HarvestTrayControl.new(view)
	canvas.custom_minimum_size = Vector2(420, 150)
	body.add_child(canvas)

	# Step 1: Maturity Comparison & Irrigation Valve.
	body.add_child(_label("Day-35 Pod Maturity & Alo-Only Dry-Down Valve", _font_px(14), MUSTARD))
	var mat_row := HBoxContainer.new()
	mat_row.add_theme_constant_override("separation", 8)
	body.add_child(mat_row)

	var mat_btn := _action_button(
		"Mature Brown Pods Confirmed ✓" if bool(view.get("pod_maturity_confirmed", false)) else "1. Confirm Day-35 Pod Maturity",
		"ConfirmPodMaturity",
		bool(view.get("pod_maturity_confirmed", false))
	)
	mat_btn.pressed.connect(func():
		_route.p06().record_annex_step("growth_chart")
		_route.p06().record_annex_step("vault_map")
		_route.p06().record_annex_step("suit_check")
		_route.p06().record_annex_step("maturity_montage")
		_route.p06().record_annex_step("save_map_provenance")
		_route.p06().record_annex_step("record_future_checks")
		_route.p06().record_annex_step("confirm_care_transition")
		_route.p06().confirm_pod_maturity("mature_completion")
		_mark_changed(true)
	)
	mat_row.add_child(mat_btn)

	var alo_closed := not bool(view.get("alo_irrigation_open", true))
	var valve_btn := _action_button(
		"Alo Valve Closed (Tara Open) ✓" if alo_closed else "2. Close Irrigation to Alo Only",
		"CloseAloIrrigation",
		alo_closed
	)
	valve_btn.pressed.connect(func():
		_route.p06().confirm_pod_maturity("mature_completion")
		_route.p06().set_irrigation_valve("alo", false)
		_mark_changed(true)
	)
	mat_row.add_child(valve_btn)

	# Step 2: Five-Day Dry-Down Vigil Strip (moisture 70 -> 20).
	var moisture := int(view.get("substrate_moisture", 70))
	var vday := int(view.get("vigil_day", 0))
	body.add_child(_label("Five-Day Dry-Down Vigil · Day %d/5 · Substrate Moisture %d (Target ≤ 20)" % [vday, moisture], _font_px(14), MUSTARD))
	var vigil_row := HBoxContainer.new()
	vigil_row.add_theme_constant_override("separation", 8)
	body.add_child(vigil_row)

	var step_day_btn := _action_button("Advance Dry-Down (+1 Day)", "AdvanceVigilDay", moisture <= 20)
	step_day_btn.pressed.connect(func():
		_route.p06().confirm_pod_maturity("mature_completion")
		_route.p06().set_irrigation_valve("alo", false)
		_route.p06().advance_drydown(false)
		_mark_changed(true)
	)
	vigil_row.add_child(step_day_btn)

	var all_days_btn := _action_button(
		"5-Day Dry-Down Complete (Moisture 20) ✓" if moisture <= 20 else "Complete 5-Day Vigil to Moisture 20",
		"CompleteDrydownVigil",
		moisture <= 20
	)
	all_days_btn.pressed.connect(func():
		_route.p06().confirm_pod_maturity("mature_completion")
		_route.p06().set_irrigation_valve("alo", false)
		_route.p06().advance_drydown(true)
		_mark_changed(true)
	)
	vigil_row.add_child(all_days_btn)

	# Step 3: Six Pods -> Six Counting Wells (7 seeds each = 42).
	var counted_total := int(view.get("total_counted", 0))
	var counted_wells := int(view.get("wells_counted", 0))
	body.add_child(_label("Six Counting Wells · %d/6 Wells Verified · %d/42 Founder Seeds" % [counted_wells, counted_total], _font_px(14), MUSTARD))
	var well_grid := GridContainer.new()
	well_grid.columns = 3
	well_grid.add_theme_constant_override("h_separation", 8)
	well_grid.add_theme_constant_override("v_separation", 6)
	body.add_child(well_grid)
	var well_counts: Dictionary = view.get("well_counts", {})
	for idx in range(6):
		var has_w := well_counts.has(idx)
		var wbtn := _action_button(
			"Well %d: 7 Seeds ✓" % (idx + 1) if has_w else "Count Pod %d → Well %d (7)" % [idx + 1, idx + 1],
			"CountWell_%d" % (idx + 1),
			has_w
		)
		wbtn.pressed.connect(func():
			if int(_route.p06().view_state().substrate_moisture) > 20:
				_route.p06().confirm_pod_maturity("mature_completion")
				_route.p06().set_irrigation_valve("alo", false)
				_route.p06().advance_drydown(true)
			_route.p06().open_six_pods()
			_route.p06().count_well(idx, 7, _mode == "family")
			_mark_changed(true)
		)
		well_grid.add_child(wbtn)

	# Step 4: Two Direct Allocation Buttons (12 Planted + 30 Reserve) & Tray Dedication.
	body.add_child(_label("Founder Seed Split (12 Planted + 30 Sealed Reserve) & Lineage Board", _font_px(14), MUSTARD))
	var alloc_row := HBoxContainer.new()
	alloc_row.add_theme_constant_override("separation", 8)
	body.add_child(alloc_row)
	var split_done := int(view.get("allocated_planted", -1)) == 12 and int(view.get("allocated_reserve", -1)) == 30
	var split_btn := _action_button(
		"Allocated: 12 Planted + 30 Reserve ✓" if split_done else "Allocate 12 Planted (2×6) + 30 Reserve (15+15)",
		"Allocate12And30",
		split_done
	)
	split_btn.pressed.connect(func():
		if _route.p06().total_counted() != 42:
			_route.p06().prepare_gate_from_panel("p06_count_42")
		_route.p06().allocate_12_and_30()
		_route.p06().sleeve_petal()
		_route.p06().record_s11_step("plant_12")
		_route.p06().record_s11_step("seal_30")
		_route.p06().record_s11_step("preserve_lineage")
		_route.p06().record_s12_continuity("confirm_descendant_survey")
		_mark_changed(true)
	)
	alloc_row.add_child(split_btn)

	# Dedication choice buttons.
	var ded_spec: Dictionary = view.get("dedication_choice", {})
	var cur_ded := String(view.get("dedication_option", "light_and_star"))
	var ded_row := HBoxContainer.new()
	ded_row.add_theme_constant_override("separation", 6)
	body.add_child(ded_row)
	for opt in ded_spec.get("options", []):
		var oid := String(opt.get("id", ""))
		var dbtn := _action_button(
			"Plaque: " + String(opt.get("label", oid)),
			"Dedication_" + oid,
			cur_ded == oid
		)
		dbtn.pressed.connect(func():
			_route.p06().choose_dedication(oid)
			_mark_changed(false)
		)
		ded_row.add_child(dbtn)

	# Wrong-but-reasonable diagnostic checks.
	body.add_child(_label("What-If Safety Checks (Test Why Other Choices Fail)", _font_px(13), CYAN_COLOR()))
	var wrong_row := HBoxContainer.new()
	wrong_row.add_theme_constant_override("separation", 6)
	body.add_child(wrong_row)
	for pair in [["close_tara_irrigation_in_s09", "Test: Shut Off Tara's Line"], ["open_pods_wet", "Test: Crack Damp Pods"], ["plant_all_42_seeds", "Test: Plant All 42 Seeds"]]:
		var wbtn := _action_button(pair[1], "Wrong_" + pair[0])
		wbtn.pressed.connect(func():
			_route.p06().preview_wrong_action(pair[0])
			_render()
		)
		wrong_row.add_child(wbtn)

func _render_right_column(body: VBoxContainer, view: Dictionary) -> void:
	# Last diagnostic feedback banner (wrong-but-reasonable or verified action).
	var fb: Dictionary = view.get("last_feedback", {})
	if not fb.is_empty():
		var is_warn := String(fb.get("kind", "")) in ["wrong_reasonable", "warning", "budget"]
		var badge_color := AMBER if is_warn else GREEN
		var fb_card := PanelContainer.new()
		fb_card.name = "DiagnosticFeedbackCard"
		fb_card.add_theme_stylebox_override("panel", _box_style(CARD_ALT, badge_color, 1, 6, 10))
		body.add_child(fb_card)
		var fbox := VBoxContainer.new()
		fbox.add_theme_constant_override("separation", 4)
		fb_card.add_child(fbox)
		fbox.add_child(_label(_clean_text(String(fb.get("badge", "FEEDBACK"))), _font_px(13), badge_color))
		fbox.add_child(_label(_clean_text(String(fb.get("message", ""))), _font_px(12), IVORY))

	# Before -> After Forecast comparison.
	body.add_child(_label("Before → After Result Forecast", _font_px(14), MUSTARD))
	if _previewed and not _last_preview.is_empty():
		var b_res: Dictionary = _last_preview.get("before_resources", {})
		var a_res: Dictionary = _last_preview.get("after_resources", {})
		body.add_child(_label("Preview verified · Ready to Lock In:", _font_px(13), GREEN))
		body.add_child(_label("• Battery: %s → %s" % [str(b_res.get("E", 14)), str(a_res.get("E", 14))], _font_px(12), IVORY))
		body.add_child(_label("• Air: %s → %s" % [str(b_res.get("A", 10)), str(a_res.get("A", 10))], _font_px(12), IVORY))
		body.add_child(_label("• Alo health: %s → %s" % [str(b_res.get("H", 6)), str(a_res.get("H", 6))], _font_px(12), IVORY))
		body.add_child(_label("• Food (days): %s → %s" % [str(b_res.get("R", 18.0)), str(a_res.get("R", 18.0))], _font_px(12), IVORY))
		if _puzzle_id == "P-06":
			body.add_child(_label("• Founder seeds: 42 total → 12 planted + 30 sealed reserve (15 + 15)", _font_px(12), CYAN_COLOR()))
			body.add_child(_label("• 31 May Tara harvest: Working stock — Tara × Alo (kept separate)", _font_px(12), MUTED))
	else:
		var block := String(view.get("block_reason", ""))
		if not block.is_empty():
			body.add_child(_label("Next required step: " + _clean_text(block), _font_px(12), AMBER))
		else:
			body.add_child(_label("Press 'Try it (Preview)' below to check the before and after readings before locking in.", _font_px(12), MUTED))

	# Progressive Hints (H1 -> H2 -> H3).
	body.add_child(HSeparator.new())
	body.add_child(_label("Progressive Hints (What Now?)", _font_px(14), MUSTARD))
	var hints: Array = view.get("hints", [])
	if hints.is_empty():
		body.add_child(_label("Stuck? Click 'What now? (Hint)' below for a gentle nudge.", _font_px(12), MUTED))
	else:
		for h in hints:
			body.add_child(_label("• %s: %s" % [String(h.get("level", "H1")), String(h.get("text", ""))], _font_px(12), CYAN_COLOR()))

func _render_footer(view: Dictionary) -> void:
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation", 10)
	_root_vbox.add_child(footer)

	var undo_btn := _action_button("Undo", "Undo")
	undo_btn.pressed.connect(undo_changes)
	footer.add_child(undo_btn)

	var hint_btn := _action_button("What now? (Hint)", "Hint")
	hint_btn.pressed.connect(request_hint)
	footer.add_child(hint_btn)

	var preview_btn := _action_button("Try it (Preview)", "Preview", _previewed)
	preview_btn.pressed.connect(preview)
	footer.add_child(preview_btn)

	var block := String(view.get("block_reason", ""))
	var commit_btn := _action_button("Lock in", "Commit", _confirm_open)
	commit_btn.disabled = not block.is_empty() or not _previewed
	if not block.is_empty():
		commit_btn.tooltip_text = block
	elif not _previewed:
		commit_btn.tooltip_text = "Press TRY IT (PREVIEW) first."
	else:
		commit_btn.tooltip_text = "Lock in this operation (Space)."
	commit_btn.pressed.connect(request_commit)
	footer.add_child(commit_btn)

func _column_card(heading: String, min_w: float, expand: bool = false) -> Dictionary:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = min_w
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL if expand else Control.SIZE_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _box_style(CARD_BG, Color(0.2, 0.35, 0.5, 0.55), 1, 8, 12))
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	vbox.add_child(_label(heading, _font_px(15), MUSTARD))
	return {"panel": panel, "body": vbox}

func _action_button(text: String, node_name: String, highlighted: bool = false) -> Button:
	var btn := Button.new()
	btn.name = node_name
	btn.text = _clean_text(text)
	btn.custom_minimum_size = Vector2(0, 44)
	btn.focus_mode = Control.FOCUS_ALL
	btn.add_theme_font_size_override("font_size", _font_px(13))
	btn.add_theme_color_override("font_color", MUSTARD if highlighted else IVORY)
	var bg := Color("#1E3352") if highlighted else Color("#162236")
	var border := MUSTARD if highlighted else BORDER_CYAN
	btn.add_theme_stylebox_override("normal", _box_style(bg, border, 1, 6, 10))
	btn.add_theme_stylebox_override("hover", _box_style(bg.lightened(0.12), MUSTARD, 1, 6, 10))
	btn.add_theme_stylebox_override("pressed", _box_style(bg.darkened(0.1), MUSTARD, 2, 6, 10))
	btn.add_theme_stylebox_override("focus", _box_style(bg.lightened(0.08), MUSTARD, 2, 6, 10))
	return btn

func _label(text: String, size_px: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = _clean_text(text)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", size_px)
	lbl.add_theme_color_override("font_color", color)
	return lbl

static func _clean_text(raw: String) -> String:
	return raw.replace("PR_RepairClamp", "Collar Clamp").replace("TL_PressureGauge", "Mechanical Gauge").replace("PL_ZeroSeedlings", "Annex Seedlings").replace("P-05", "Pressure Check").replace("P-06", "Seed Harvest")

static func _box_style(bg: Color, border: Color, border_w: int, radius: int, pad: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(border_w)
	box.set_corner_radius_all(radius)
	box.content_margin_left = pad
	box.content_margin_right = pad
	box.content_margin_top = pad
	box.content_margin_bottom = pad
	return box

static func CYAN_COLOR() -> Color:
	return Color("#20B8C9")


class _PipingSchematicControl extends Control:
	var _view: Dictionary = {}

	func _init(view: Dictionary = {}) -> void:
		_view = view

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		draw_rect(rect, Color("#080D16"), true)
		draw_rect(rect, Color("#20B8C9"), false, 1.5)
		var font := ThemeDB.fallback_font
		var t0_map: Dictionary = _view.get("t0_readings", {})
		var t10_map: Dictionary = _view.get("t10_readings", {})
		var isolated := bool(_view.get("garden_isolated", false))
		var clamped := bool(_view.get("clamp_seated", false))
		var stable_count: int = (_view.get("stable_readings", {}) as Dictionary).size()

		# Draw three horizontal branch lines: MAIN, GARDEN, RETURN.
		var y_positions := [34.0, 76.0, 118.0]
		var names := ["MAIN", "GARDEN", "RETURN"]
		for i in range(3):
			var y: float = y_positions[i]
			var bname: String = names[i]
			var is_garden := bname == "GARDEN"
			var line_col := Color("#4CAF50") if (not is_garden or clamped) else (Color("#FFB300") if isolated else Color("#FF7043"))
			draw_line(Vector2(24, y), Vector2(size.x - 150, y), line_col, 4.0)
			draw_circle(Vector2(140, y), 7.0, line_col)
			var r0 := str(t0_map.get(bname, "—"))
			var r10 := str(t10_map.get(bname, "—"))
			var status_txt := "%s TAP · t0: %s → t10: %s" % [bname, r0, r10]
			if is_garden and clamped:
				status_txt += " [CLAMPED · 100]"
			elif is_garden and isolated:
				status_txt += " [VALVE CLOSED · 74]"
			draw_string(font, Vector2(28, y - 10), status_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#ECEEF0"))

		# Draw mechanical gauge dial on the right.
		var center := Vector2(size.x - 72, 76)
		draw_circle(center, 44.0, Color("#121A2B"))
		draw_arc(center, 44.0, 0.0, TAU, 36, Color("#F2C230"), 2.0)
		var needle_val := 100.0
		if stable_count == 5 or clamped:
			needle_val = 100.0
		elif t10_map.has("GARDEN"):
			needle_val = float(t10_map["GARDEN"])
		elif t0_map.has("GARDEN"):
			needle_val = float(t0_map["GARDEN"])
		var angle := deg_to_rad(lerpf(-140.0, 40.0, clampf((needle_val - 50.0) / 60.0, 0.0, 1.0)))
		draw_line(center, center + Vector2(cos(angle), sin(angle)) * 32.0, Color("#F2C230"), 3.0)
		draw_string(font, center + Vector2(-26, 26), "%d units" % int(needle_val), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#F2C230"))


class _HarvestTrayControl extends Control:
	var _view: Dictionary = {}

	func _init(view: Dictionary = {}) -> void:
		_view = view

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		draw_rect(rect, Color("#080D16"), true)
		draw_rect(rect, Color("#20B8C9"), false, 1.5)
		var font := ThemeDB.fallback_font
		var moisture := int(_view.get("substrate_moisture", 70))
		var well_counts: Dictionary = _view.get("well_counts", {})
		var planted := int(_view.get("allocated_planted", -1))
		var reserve := int(_view.get("allocated_reserve", -1))

		# Draw moisture dry-down bar on top.
		draw_string(font, Vector2(18, 24), "5-Day Dry-Down Moisture: %d (Harvest Ready ≤ 20)" % moisture, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#ECEEF0"))
		var bar_w := clampf(float(moisture) / 70.0, 0.0, 1.0) * 180.0
		draw_rect(Rect2(Vector2(18, 32), Vector2(180, 10)), Color("#172238"), true)
		draw_rect(Rect2(Vector2(18, 32), Vector2(bar_w, 10)), Color("#4CAF50") if moisture <= 20 else Color("#20B8C9"), true)

		# Draw 6 counting wells in the middle.
		for i in range(6):
			var cx := 38.0 + float(i) * 58.0
			var cy := 88.0
			var counted := well_counts.has(i)
			draw_circle(Vector2(cx, cy), 20.0, Color("#1B2B44") if counted else Color("#121A2B"))
			draw_arc(Vector2(cx, cy), 20.0, 0.0, TAU, 28, Color("#F2C230") if counted else Color("#A8B4C8"), 2.0)
			draw_string(font, Vector2(cx - 12, cy + 5), "7/7" if counted else "W%d" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#F2C230") if counted else Color("#A8B4C8"))

		# Draw allocation summary on bottom/right.
		var split_txt := "Planted Cassettes: %s/12   ·   Founder Reserve: %s/30 (15 + 15)" % [
			str(planted) if planted >= 0 else "—",
			str(reserve) if reserve >= 0 else "—",
		]
		draw_string(font, Vector2(18, 136), split_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#4CAF50") if (planted == 12 and reserve == 30) else Color("#F2C230"))
