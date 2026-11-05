extends Control
class_name P01PuzzlePanel

## Interactive P-01 Commissioning & Planting Bench UI for EX-CH01-S03 and S04.
##
## Follows `execution/PUZZLE_P01.md` and `execution/UI_09_SCIENTIFIC_PUZZLE.md`:
## - Left column: Observed Data & Reference Bench (raw +10 probe offset, dry/wet
##   reference cups, sealed packet ALO / N. provenance, paired Alo & Tara
##   cassette readouts, and Predict -> Test -> Observe -> Explain card).
## - Centre column: Interactive Workbench Controls (reference cup selector,
##   zero offset, wet span, two-point recheck, optical packet scanner, seed
##   placement, calibrated moisture 40–60 with Drain Excess to Waste when
##   flooded > 60, distinct EXTERNAL TEST / INDOOR REFERENCE labels, and seals).
## - Right column: Result Preview, non-punishing diagnostic feedback, progressive
##   hints (H1/H2/H3 verbatim from `08_PUZZLE_DESIGNS.md`), and NASA Data Cards.
## - Footer bar: Reset Unsettled Cassette, Hint, Data Cards, Preview, Commit
##   (Space opens confirmation; Space again confirms), and Close (Esc).

signal commit_requested(target_id: String, payload: Dictionary)
signal data_cards_requested(card_ids: Array)
signal opened(target_id: String)
signal closed(target_id: String)

const PuzzleScript = preload("res://scripts/puzzles/p01_commission_plant_puzzle.gd")
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

var _route: RefCounted
var _target_id := ""
var _settings := {"large_text": false, "timer_free": true}
var _view: Dictionary = {}
var _previewed_key := ""
var _confirming := false
var _notice := ""
var _focus_name := ""
var _overlay: ColorRect
var _frame: PanelContainer
var _content: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100
	_overlay = ColorRect.new()
	_overlay.color = Color(0.0, 0.01, 0.03, 0.84)
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

## Opens the P-01 Commissioning & Planting Bench for `target_id`.
func open(route: RefCounted, target_id: String, settings: Dictionary = {}) -> void:
	_route = route
	_target_id = target_id
	for key in settings:
		_settings[key] = settings[key]
	_confirming = false
	_notice = ""
	_previewed_key = ""
	_focus_name = ""
	show()
	_layout()
	_render()
	opened.emit(_target_id)
	_grab_first_focus()

## Closes the bench without committing an unconfirmed step.
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

## Latest rendered bench view dictionary (for tests and evidence probes).
func view() -> Dictionary:
	return _view.duplicate(true)

## Switches the active P-01 gate step inside the current scene.
func select_gate(next_target_id: String) -> Dictionary:
	if not PuzzleScript.is_gate(next_target_id):
		return {"accepted": false, "reason": "Unknown P-01 gate: " + next_target_id}
	_target_id = next_target_id
	_confirming = false
	_previewed_key = ""
	_notice = "Selected step: " + String(PuzzleScript.gate_info(next_target_id).get("title", next_target_id))
	_focus_name = "GateTab_" + next_target_id
	_render()
	return {"accepted": true, "target_id": _target_id}

# --- Player actions (also called directly by tests) ------------------------

## Selects which reference cup (`"dry"` or `"wet"`) the moisture probe is in.
func select_cup(cup: String) -> Dictionary:
	var result: Dictionary = _puzzle().select_reference_cup(cup)
	_after_action(result, "Cup_" + cup)
	return result

## Sets the probe zero offset (`0`, `-5`, `-10`, `-15`).
func choose_zero_offset(offset: int) -> Dictionary:
	var result: Dictionary = _puzzle().set_zero_offset(offset)
	_after_action(result, "Zero_%d" % offset)
	return result

## Sets the probe wet span (`90`, `100`, `110`, `120`).
func choose_wet_span(span: int) -> Dictionary:
	var result: Dictionary = _puzzle().set_wet_span(span)
	_after_action(result, "Span_%d" % span)
	return result

## Verifies `"dry"`, `"wet"`, or `"both"` reference cups during two-point recheck.
func verify_recheck_cup(cup: String, verified: bool = true) -> Dictionary:
	var result: Dictionary = _puzzle().set_recheck_cup(cup, verified)
	_after_action(result, "Recheck_" + cup)
	return result

## Chooses the seed packet inspection mode (`"sealed_optical"`, `"unrecorded_glance"`, `"unseal_on_bench"`).
func choose_scan_mode(mode: String) -> Dictionary:
	var result: Dictionary = _puzzle().set_scan_mode(mode)
	_after_action(result, "Scan_" + mode)
	return result

## Records the player's scientific prediction choice for the current scene.
func choose_prediction(option_id: String) -> Dictionary:
	var scene_id := String(_view.get("scene_id", _route.current_scene_id() if _route != null else "EX-CH01-S03"))
	var result: Dictionary = _puzzle().select_prediction(scene_id, option_id)
	_after_action(result, "Predict_" + option_id)
	return result

## Selects which cassette (`"alo"` or `"tara"`) a planting step targets.
func choose_cassette_target(cassette_id: String, target_cassette: String) -> Dictionary:
	var result: Dictionary = _puzzle().set_cassette_target(cassette_id, target_cassette)
	_after_action(result, "Target_%s_%s" % [cassette_id, target_cassette])
	return result

## Selects how many seeds (`0`, `1`, `2`) to place in `cassette_id`.
func choose_cassette_seeds(cassette_id: String, seeds: int) -> Dictionary:
	var result: Dictionary = _puzzle().set_cassette_seeds(cassette_id, seeds)
	_after_action(result, "Seeds_%s_%d" % [cassette_id, seeds])
	return result

## Sets the calibrated water/moisture level (`0..100`) for `cassette_id`.
func choose_cassette_moisture(cassette_id: String, moisture: int) -> Dictionary:
	var result: Dictionary = _puzzle().set_cassette_moisture(cassette_id, moisture)
	_after_action(result, "Moisture_%s_%d" % [cassette_id, moisture])
	return result

## Adjusts `cassette_id` moisture by `delta` units.
func adjust_cassette_moisture(cassette_id: String, delta: int) -> Dictionary:
	var result: Dictionary = _puzzle().adjust_cassette_moisture(cassette_id, delta)
	_after_action(result, "WaterDelta_%s_%+d" % [cassette_id, delta])
	return result

## Drains excess water from a flooded (`> 60`) cassette to waste without harming the seed.
func drain_excess_to_waste(cassette_id: String, target_moisture: int = 50) -> Dictionary:
	var result: Dictionary = _route.drain_p01_cassette(cassette_id, target_moisture) if _route != null and _route.has_method("drain_p01_cassette") else _puzzle().drain_excess_water(cassette_id, target_moisture)
	_after_action(result, "DrainWaste_" + cassette_id)
	return result

## Assigns `"EXTERNAL_TEST"` or `"INDOOR_REFERENCE"` to `cassette_id`.
func choose_cassette_label(cassette_id: String, label: String) -> Dictionary:
	var committed_p01: Dictionary = _view.get("p01", {})
	var result: Dictionary = _puzzle().set_cassette_label(cassette_id, label, committed_p01)
	_after_action(result, "Label_%s_%s" % [cassette_id, PuzzleScript.normalize_label(label)])
	return result

## Sets the seal state (`true` = closed & locked, `false` = open) for `cassette_id`.
func choose_cassette_seal(cassette_id: String, closed_state: bool) -> Dictionary:
	var result: Dictionary = _puzzle().set_cassette_seal(cassette_id, closed_state)
	_after_action(result, "Seal_%s_%s" % [cassette_id, "closed" if closed_state else "open"])
	return result

## Resets an unsettled (unsealed) cassette without destroying any seed.
func reset_cassette(cassette_id: String = "") -> Dictionary:
	var cid := cassette_id if not cassette_id.is_empty() else _active_cassette_id()
	if _route == null:
		return {"accepted": false, "reason": "No active route."}
	var result: Dictionary = _route.reset_p01_cassette(cid)
	_previewed_key = ""
	_confirming = false
	_notice = String(result.get("reason", ""))
	_focus_name = "ResetCassette"
	_render()
	return result

## Reveals the next progressive hint (`H1`, `H2`, `H3`).
func reveal_hint() -> Dictionary:
	var result: Dictionary = _puzzle().next_hint()
	_after_action(result, "Hint")
	return result

## Emits `data_cards_requested` with the P-01 NASA Data Card IDs.
func open_data_cards() -> Dictionary:
	_refresh_view()
	var ids: Array = []
	for card in _view.get("data_cards", []):
		if card is Dictionary and card.has("source_id"):
			ids.append(String(card.get("source_id", "")))
	data_cards_requested.emit(ids)
	_notice = "Opened P-01 NASA Data Cards (%d cards)." % ids.size()
	_focus_name = "DataCards"
	_render()
	return {"accepted": true, "card_ids": ids}

## Previews the player's current workbench selection for `_target_id`.
## If the selection is invalid or incomplete, records a non-punishing attempt
## and displays the diagnostic reason + hint.
func preview() -> Dictionary:
	_refresh_view()
	var prereq := String(_view.get("prerequisite_reason", ""))
	if not prereq.is_empty():
		_notice = prereq
		_render()
		return {"accepted": false, "reason": prereq, "hint": "Complete the steps in sequence."}
	var gate_preview: Dictionary = _view.get("gate_preview", {})
	_puzzle().record_attempt(gate_preview)
	if not bool(gate_preview.get("accepted", false)):
		var reason := String(gate_preview.get("reason", "Adjust the bench controls before committing."))
		var hint := String(gate_preview.get("hint", "Check the instrument before trusting it."))
		_notice = "%s  ·  Hint: %s" % [reason, hint]
		_render()
		return {"accepted": false, "reason": reason, "hint": hint, "forecast": gate_preview}
	_previewed_key = _selection_key()
	_notice = "Preview verified: %s Press Space or Commit to lock in this step." % String(gate_preview.get("reason", ""))
	_focus_name = "Commit"
	_render()
	return {"accepted": true, "reason": _notice, "forecast": gate_preview}

## Opens the two-step commit confirmation when the step has been previewed and
## is valid; otherwise displays a helpful non-punishing diagnostic.
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

## Confirms the open confirmation: closes the bench (resuming time) and emits
## `commit_requested` with the player's workbench payload for `_target_id`.
func confirm_commit() -> Dictionary:
	if not _confirming:
		return {"accepted": false, "reason": "Open the commit confirmation first."}
	var reason := _commit_reason()
	if not reason.is_empty():
		_confirming = false
		_notice = reason
		_render()
		return {"accepted": false, "reason": reason}
	var payload: Dictionary = _puzzle().payload_for_gate(_target_id)
	var id := _target_id
	close()
	commit_requested.emit(id, payload)
	return {"accepted": true, "target_id": id, "payload": payload}

## Cancels the confirmation step without closing the bench.
func cancel_confirm() -> void:
	_confirming = false
	_focus_name = "Commit"
	_render()

# --- Input -----------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not visible:
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
	_render_step_tabs()
	if _confirming:
		_render_confirmation()
	else:
		var columns := HBoxContainer.new()
		columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
		columns.add_theme_constant_override("separation", 14)
		_content.add_child(columns)
		columns.add_child(_scroll(_render_observed_data(), "BenchDataScroll"))
		columns.add_child(_scroll(_render_workbench_controls(), "ControlsScroll"))
		columns.add_child(_scroll(_render_preview_and_science(), "PreviewScroll"))
		_render_footer()
	_restore_focus()

func _render_header() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	_content.add_child(row)
	var title := _label("COMMISSIONING & PLANTING BENCH", 20, MUSTARD)
	row.add_child(title)
	var gate: Dictionary = _view.get("gate", {})
	var gate_label := _label("P-01 · " + String(gate.get("title", _target_id)).to_upper(), 14, IVORY)
	gate_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gate_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(gate_label)
	var meta := _wrap("%s · TIME PAUSED WHILE BENCH IS OPEN · NO TIMER IN FAMILY MODE" % String(_view.get("scenario_datetime", "")), 11, MUTED)
	meta.custom_minimum_size.x = 280
	meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(meta)

func _render_step_tabs() -> void:
	var scene_gates: Array = _view.get("scene_gates", [])
	var completed: Array = _view.get("completed_gates", [])
	if scene_gates.is_empty():
		return
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	_content.add_child(flow)
	for idx in scene_gates.size():
		var gid := String(scene_gates[idx])
		var ginfo := PuzzleScript.gate_info(gid)
		var is_done := completed.has(gid)
		var is_active := gid == _target_id
		var status_tag := "[DONE]" if is_done else ("[ACTIVE]" if is_active else "[STEP %d]" % (idx + 1))
		var short_label := String(ginfo.get("label", gid))
		var btn := _button("%s %s" % [status_tag, short_label], is_active, false, "GateTab_" + gid)
		btn.pressed.connect(func() -> void: select_gate(gid))
		flow.add_child(btn)

func _render_observed_data() -> Control:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	col.add_child(_label("OBSERVED DATA & REFERENCE BENCH", 15, CYAN))

	var p01: Dictionary = _view.get("p01", {})
	var wb: Dictionary = _view.get("workbench", {})
	var dry_val := int(_view.get("displayed_dry", 10))
	var wet_val := int(_view.get("displayed_wet", 110))
	var zeroed := bool(p01.get("probe_zeroed", false))
	var spanned := bool(p01.get("probe_spanned", false))
	var rechecked := bool(p01.get("probe_rechecked", false))

	var probe_card := _card(Color(0.13, 0.72, 0.78, 0.65) if rechecked else Color(0.28, 0.39, 0.58, 0.55))
	col.add_child(probe_card)
	var pbox := _card_box(probe_card)
	pbox.add_child(_label("MOISTURE PROBE & REFERENCE CUPS", 13, MUSTARD))
	pbox.add_child(_wrap("Initial instrument offset: +10 displayed units (uncalibrated dry = 10, wet = 110).", 12, MUTED))
	pbox.add_child(_wrap("Active probe dip: %s Reference Cup" % String(wb.get("reference_cup", "dry")).to_upper(), 12, IVORY))
	pbox.add_child(_wrap(
		"Dry Reference Cup: %d units (Target: 0 · %s)" % [dry_val, "COMMITTED ZERO" if zeroed else ("STAGED 0" if dry_val == 0 else "UNCALIBRATED +10 OFFSET")],
		12,
		GREEN if dry_val == 0 else MUSTARD
	))
	pbox.add_child(_wrap(
		"Wet Reference Cup: %d units (Target: 100 · %s)" % [wet_val, "COMMITTED SPAN" if spanned else ("STAGED 100" if wet_val == 100 else "UNCALIBRATED 110")],
		12,
		GREEN if wet_val == 100 else MUSTARD
	))
	pbox.add_child(_wrap(
		"Two-Point Recheck: %s" % ("VERIFIED (Dry = 0, Wet = 100)" if rechecked else ("STAGED (Dry = 0, Wet = 100)" if (bool(wb.get("recheck_dry_verified", false)) and bool(wb.get("recheck_wet_verified", false))) else "PENDING VERIFICATION")),
		12,
		GREEN if (rechecked or (bool(wb.get("recheck_dry_verified", false)) and bool(wb.get("recheck_wet_verified", false)))) else MUTED
	))

	var scanned := bool(p01.get("packet_scanned", false))
	var scan_mode := String(wb.get("scan_mode", ""))
	var packet_card := _card(Color(0.28, 0.39, 0.58, 0.55))
	col.add_child(packet_card)
	var pkbox := _card_box(packet_card)
	pkbox.add_child(_label("SEALED SEED PACKET PROVENANCE", 13, MUSTARD))
	pkbox.add_child(_wrap(
		"Packet Status: %s" % ("SCANNED & LOGGED · Inscription 'ALO' · Initial 'N.' (Latin letters) · 2 Seeds · Seal INTACT" if (scanned or scan_mode == "sealed_optical") else "UNSCANNED · Keep packet sealed and run Optical Scan"),
		12,
		GREEN if (scanned or scan_mode == "sealed_optical") else IVORY
	))

	var cassettes_card := _card(Color(0.28, 0.39, 0.58, 0.55))
	col.add_child(cassettes_card)
	var cbox := _card_box(cassettes_card)
	cbox.add_child(_label("PAIRED PLANTING CASSETTES (ALO & TARA)", 13, MUSTARD))
	for cid in ["alo", "tara"]:
		var c_comm: Dictionary = p01.get("cassettes", {}).get(cid, {})
		var c_wb: Dictionary = wb.get("cassettes", {}).get(cid, {})
		var title := "Cassette A — Alo (External Test)" if cid == "alo" else "Cassette B — Tara (Indoor Reference)"
		var seeds := int(c_comm.get("seed_count", 0)) if int(c_comm.get("seed_count", 0)) > 0 else int(c_wb.get("seeds", 0))
		var moist_comm := int(c_comm.get("moisture", 0))
		var moist_wb := int(c_wb.get("moisture", -1))
		var moist := moist_wb if moist_wb >= 0 else (moist_comm if moist_comm > 0 else -1)
		var flooded := bool(c_wb.get("flooded", false)) or bool(c_comm.get("flooded", false)) or moist > 60
		var moist_text := "Unwatered (choose 40–60, 50 nominal)"
		if moist >= 0:
			if flooded or moist > 60:
				moist_text = "%d units [! FLOODED > 60 · DRAIN EXCESS TO WASTE]" % moist
			elif moist < 40:
				moist_text = "%d units [! TOO DRY < 40 · ADD WATER]" % moist
			else:
				moist_text = "%d units [OK · IN 40–60 BAND]" % moist
		var lbl_raw := String(c_comm.get("label", "")) if not String(c_comm.get("label", "")).is_empty() else String(c_wb.get("label", ""))
		var lbl_text := PuzzleScript.display_label(lbl_raw)
		var sealed := bool(c_comm.get("sealed", false)) or bool(c_wb.get("seal_closed", false))
		var seal_text := "COMMITTED SEALED" if bool(c_comm.get("sealed", false)) else ("STAGED CLOSED" if sealed else "OPEN")
		cbox.add_child(_label(title, 12, CYAN))
		cbox.add_child(_wrap("  Seed: %d / 1  ·  Moisture: %s\n  Label: %s  ·  Seal: %s" % [seeds, moist_text, lbl_text, seal_text], 12, RED if flooded else IVORY))

	var gate: Dictionary = _view.get("gate", {})
	var method_card := _card(Color(0.20, 0.55, 0.65, 0.55))
	col.add_child(method_card)
	var mbox := _card_box(method_card)
	mbox.add_child(_label("SCIENTIFIC METHOD · PREDICT -> TEST -> OBSERVE -> EXPLAIN", 13, CYAN))
	mbox.add_child(_wrap("PREDICT: " + String(gate.get("predict", "")), 12, IVORY))
	mbox.add_child(_wrap("TEST: " + String(gate.get("test", "")), 12, IVORY))
	mbox.add_child(_wrap("OBSERVE: " + String(gate.get("observe", "")), 12, GREEN))
	mbox.add_child(_wrap("EXPLAIN: " + String(gate.get("explain", "")), 12, MUTED))
	return col

func _render_workbench_controls() -> Control:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	var gate: Dictionary = _view.get("gate", {})
	var scene_id := String(_view.get("scene_id", "EX-CH01-S03"))
	var wb: Dictionary = _view.get("workbench", {})
	var p01: Dictionary = _view.get("p01", {})

	col.add_child(_label("INTERACTIVE WORKBENCH CONTROLS", 15, CYAN))
	var inst_card := _card(Color(0.95, 0.76, 0.19, 0.75))
	col.add_child(inst_card)
	var ibox := _card_box(inst_card)
	ibox.add_child(_label(String(gate.get("title", _target_id)), 14, MUSTARD))
	ibox.add_child(_wrap(String(gate.get("instruction", "")), 13, IVORY))
	var prereq := String(_view.get("prerequisite_reason", ""))
	if not prereq.is_empty():
		ibox.add_child(_wrap("! PREREQUISITE: " + prereq, 12, MUSTARD))

	_render_prediction_card(col, scene_id, wb)

	if scene_id == "EX-CH01-S03":
		_render_s03_controls(col, wb, p01)
	else:
		_render_s04_controls(col, wb, p01)
	return col

func _render_prediction_card(col: VBoxContainer, scene_id: String, wb: Dictionary) -> void:
	var pred_spec: Dictionary = PuzzleScript.data().get("predictions", {}).get(scene_id, {})
	if pred_spec.is_empty():
		return
	var chosen := String(wb.get("predictions", {}).get(scene_id, ""))
	var card := _card(Color(0.28, 0.39, 0.58, 0.55))
	col.add_child(card)
	var box := _card_box(card)
	box.add_child(_label("HYPOTHESIS CHECK (NON-PUNISHING)", 12, MUSTARD))
	box.add_child(_wrap(String(pred_spec.get("question", "")), 12, IVORY))
	for opt in pred_spec.get("options", []):
		var oid := String(opt.get("id", ""))
		var selected := chosen == oid
		var prefix := "[SELECTED] " if selected else ""
		var btn := _button(prefix + String(opt.get("label", oid)), selected, false, "Predict_" + oid)
		btn.pressed.connect(func() -> void: choose_prediction(oid))
		box.add_child(btn)
		if selected:
			var is_right := oid == String(pred_spec.get("correct_option", ""))
			box.add_child(_wrap(String(opt.get("feedback", "")), 12, GREEN if is_right else MUSTARD))

func _render_s03_controls(col: VBoxContainer, wb: Dictionary, _p01: Dictionary) -> void:
	var probe_spec: Dictionary = PuzzleScript.data().get("probe", {})
	var cup := String(wb.get("reference_cup", "dry"))
	var zero_offset := int(wb.get("zero_offset", 0))
	var span_target := int(wb.get("span_target", 110))
	var recheck_dry := bool(wb.get("recheck_dry_verified", false))
	var recheck_wet := bool(wb.get("recheck_wet_verified", false))
	var scan_mode := String(wb.get("scan_mode", ""))

	# Reference cup selector
	var cup_card := _card(Color(0.28, 0.39, 0.58, 0.55))
	col.add_child(cup_card)
	var cup_box := _card_box(cup_card)
	cup_box.add_child(_label("1. SELECT REFERENCE CUP FOR PROBE", 13, MUSTARD))
	var cup_row := HFlowContainer.new()
	cup_row.add_theme_constant_override("h_separation", 8)
	cup_row.add_theme_constant_override("v_separation", 8)
	cup_box.add_child(cup_row)
	var dry_btn := _button(("✓ " if cup == "dry" else "") + "Dry Reference Cup (Target: 0)", cup == "dry", false, "Cup_dry")
	dry_btn.pressed.connect(func() -> void: select_cup("dry"))
	cup_row.add_child(dry_btn)
	var wet_btn := _button(("✓ " if cup == "wet" else "") + "Wet Reference Cup (Target: 100)", cup == "wet", false, "Cup_wet")
	wet_btn.pressed.connect(func() -> void: select_cup("wet"))
	cup_row.add_child(wet_btn)

	# Step 1: Zero Offset
	var zero_card := _card(Color(0.13, 0.72, 0.78, 0.75) if _target_id == "calibrate_probe" else Color(0.28, 0.39, 0.58, 0.55))
	col.add_child(zero_card)
	var zbox := _card_box(zero_card)
	zbox.add_child(_label("2. DRY REFERENCE ZERO ADJUSTMENT (10 -> 0)", 13, MUSTARD))
	zbox.add_child(_wrap("Current Zero Offset: %+d  ·  Displayed Dry Reading: %d units" % [zero_offset, int(_view.get("displayed_dry", 10))], 12, IVORY))
	for item in probe_spec.get("zero_offset_options", []):
		var off := int(item.get("offset", 0))
		var active := zero_offset == off
		var btn := _button(("✓ " if active else "") + String(item.get("label", str(off))), active, false, "Zero_%d" % off)
		btn.pressed.connect(func() -> void: choose_zero_offset(off))
		zbox.add_child(btn)

	# Step 2: Wet Span
	var span_card := _card(Color(0.13, 0.72, 0.78, 0.75) if _target_id == "span_probe" else Color(0.28, 0.39, 0.58, 0.55))
	col.add_child(span_card)
	var sbox := _card_box(span_card)
	sbox.add_child(_label("3. WET REFERENCE SPAN ADJUSTMENT (110 -> 100)", 13, MUSTARD))
	sbox.add_child(_wrap("Current Wet Span: %d  ·  Displayed Wet Reading: %d units" % [span_target, int(_view.get("displayed_wet", 110))], 12, IVORY))
	for item in probe_spec.get("wet_span_options", []):
		var sp := int(item.get("span", 110))
		var active := span_target == sp
		var btn := _button(("✓ " if active else "") + String(item.get("label", str(sp))), active, false, "Span_%d" % sp)
		btn.pressed.connect(func() -> void: choose_wet_span(sp))
		sbox.add_child(btn)

	# Step 3: Two-Point Recheck
	var recheck_card := _card(Color(0.13, 0.72, 0.78, 0.75) if _target_id == "recheck_probe" else Color(0.28, 0.39, 0.58, 0.55))
	col.add_child(recheck_card)
	var rbox := _card_box(recheck_card)
	rbox.add_child(_label("4. TWO-POINT CALIBRATION RECHECK (DRY = 0, WET = 100)", 13, MUSTARD))
	var r_dry := _button(("✓ " if recheck_dry else "") + "Verify Dry Reference Cup Reads 0", recheck_dry, false, "Recheck_dry")
	r_dry.pressed.connect(func() -> void: verify_recheck_cup("dry", true))
	rbox.add_child(r_dry)
	var r_wet := _button(("✓ " if recheck_wet else "") + "Verify Wet Reference Cup Reads 100", recheck_wet, false, "Recheck_wet")
	r_wet.pressed.connect(func() -> void: verify_recheck_cup("wet", true))
	rbox.add_child(r_wet)
	var r_both := _button(("✓ " if (recheck_dry and recheck_wet) else "") + "Verify Both Cups Together (Dry = 0 & Wet = 100)", recheck_dry and recheck_wet, false, "Recheck_both")
	r_both.pressed.connect(func() -> void: verify_recheck_cup("both", true))
	rbox.add_child(r_both)

	# Step 4: Optical Packet Scan
	var scan_card := _card(Color(0.13, 0.72, 0.78, 0.75) if _target_id == "inspect_packet" else Color(0.28, 0.39, 0.58, 0.55))
	col.add_child(scan_card)
	var scbox := _card_box(scan_card)
	scbox.add_child(_label("5. SEALED SEED PACKET OPTICAL SCAN (ALO / N.)", 13, MUSTARD))
	for mode_item in PuzzleScript.data().get("packet", {}).get("scan_modes", []):
		var mid := String(mode_item.get("id", ""))
		var active := scan_mode == mid
		var btn := _button(("✓ " if active else "") + String(mode_item.get("label", mid)), active, false, "Scan_" + mid)
		btn.pressed.connect(func() -> void: choose_scan_mode(mid))
		scbox.add_child(btn)

func _render_s04_controls(col: VBoxContainer, wb: Dictionary, p01: Dictionary) -> void:
	var cid := _active_cassette_id()
	var c_wb: Dictionary = wb.get("cassettes", {}).get(cid, {})
	var c_comm: Dictionary = p01.get("cassettes", {}).get(cid, {})
	var c_spec: Dictionary = PuzzleScript.data().get("cassettes", {}).get(cid, {})
	var title := String(c_spec.get("title", cid.capitalize()))
	var role := String(c_spec.get("role", ""))

	var header_card := _card(Color(0.13, 0.72, 0.78, 0.75))
	col.add_child(header_card)
	var hbox := _card_box(header_card)
	hbox.add_child(_label("ACTIVE CASSETTE BENCH · " + title.to_upper(), 13, MUSTARD))
	hbox.add_child(_wrap(role, 12, MUTED))

	# 1. Seed placement
	var seed_card := _card(Color(0.13, 0.72, 0.78, 0.75) if _target_id in ["plant_alo", "plant_tara"] else Color(0.28, 0.39, 0.58, 0.55))
	col.add_child(seed_card)
	var sbox := _card_box(seed_card)
	sbox.add_child(_label("1. SEED PLACEMENT (%s)" % title.to_upper(), 13, MUSTARD))
	var target_c := String(c_wb.get("target_cassette", cid))
	var t_row := HFlowContainer.new()
	t_row.add_theme_constant_override("h_separation", 8)
	t_row.add_theme_constant_override("v_separation", 8)
	sbox.add_child(t_row)
	for dest in ["alo", "tara"]:
		var active_t := target_c == dest
		var t_btn := _button(("✓ " if active_t else "") + "Target: %s Cassette" % dest.capitalize(), active_t, false, "Target_%s_%s" % [cid, dest])
		t_btn.pressed.connect(func() -> void: choose_cassette_target(cid, dest))
		t_row.add_child(t_btn)
	var seeds_staged := int(c_wb.get("seeds", 0))
	var s_row := HFlowContainer.new()
	s_row.add_theme_constant_override("h_separation", 8)
	s_row.add_theme_constant_override("v_separation", 8)
	sbox.add_child(s_row)
	for s_count in [0, 1, 2]:
		var active_s := seeds_staged == s_count
		var desc := "0 Seeds (Empty)" if s_count == 0 else ("1 Seed (Standard)" if s_count == 1 else "2 Seeds (Duplicate)")
		var s_btn := _button(("✓ " if active_s else "") + desc, active_s, false, "Seeds_%s_%d" % [cid, s_count])
		s_btn.pressed.connect(func() -> void: choose_cassette_seeds(cid, s_count))
		s_row.add_child(s_btn)

	# 2. Calibrated Watering & Drain-to-Waste
	var moist := int(c_wb.get("moisture", -1))
	var flooded := bool(c_wb.get("flooded", false)) or moist > 60
	var water_card := _card(Color(0.90, 0.42, 0.44, 0.85) if flooded else (Color(0.13, 0.72, 0.78, 0.75) if _target_id in ["water_alo", "water_tara"] else Color(0.28, 0.39, 0.58, 0.55)))
	col.add_child(water_card)
	var wbox := _card_box(water_card)
	wbox.add_child(_label("2. CALIBRATED MOISTURE & DRAIN-TO-WASTE (%s)" % title.to_upper(), 13, MUSTARD))
	var moist_summary := "Unset — choose a calibrated moisture value (40 to 60 inclusive; 50 nominal)." if moist < 0 else "Staged Moisture: %d units (Accepted Band: 40–60 · Nominal: 50)" % moist
	wbox.add_child(_wrap(moist_summary, 12, RED if flooded else (GREEN if (moist >= 40 and moist <= 60) else MUSTARD)))
	if flooded:
		wbox.add_child(_wrap("! CASSETTE FLOODED (> 60 UNITS): The seed is safe and unharmed. Drain excess water to the waste line before sealing!", 12, MUSTARD))
	var preset_flow := HFlowContainer.new()
	preset_flow.add_theme_constant_override("h_separation", 6)
	preset_flow.add_theme_constant_override("v_separation", 6)
	wbox.add_child(preset_flow)
	for preset in PuzzleScript.data().get("moisture_band", {}).get("preset_options", []):
		var m_val := int(preset.get("moisture", 50))
		var active_m := moist == m_val
		var m_btn := _button(("✓ " if active_m else "") + String(preset.get("label", str(m_val))), active_m, false, "Moisture_%s_%d" % [cid, m_val])
		m_btn.pressed.connect(func() -> void: choose_cassette_moisture(cid, m_val))
		preset_flow.add_child(m_btn)
	var delta_flow := HFlowContainer.new()
	delta_flow.add_theme_constant_override("h_separation", 6)
	delta_flow.add_theme_constant_override("v_separation", 6)
	wbox.add_child(delta_flow)
	for delta in [-10, -5, -1, 1, 5, 10]:
		var d_btn := _button("%+d units" % delta, false, false, "WaterDelta_%s_%+d" % [cid, delta])
		d_btn.pressed.connect(func() -> void: adjust_cassette_moisture(cid, delta))
		delta_flow.add_child(d_btn)
	var drain_btn := _button("DRAIN EXCESS WATER TO WASTE (RETURN TO 50 NOMINAL · SEED SAFE)", flooded, false, "DrainWaste_" + cid)
	drain_btn.pressed.connect(func() -> void: drain_excess_to_waste(cid, 50))
	wbox.add_child(drain_btn)

	# 3. Distinct Cassette Label
	var label_card := _card(Color(0.13, 0.72, 0.78, 0.75) if _target_id in ["label_alo", "label_tara"] else Color(0.28, 0.39, 0.58, 0.55))
	col.add_child(label_card)
	var lbox := _card_box(label_card)
	lbox.add_child(_label("3. DISTINCT CASSETTE LABEL (%s)" % title.to_upper(), 13, MUSTARD))
	var current_lbl := String(c_wb.get("label", ""))
	var l_row := HFlowContainer.new()
	l_row.add_theme_constant_override("h_separation", 8)
	l_row.add_theme_constant_override("v_separation", 8)
	lbox.add_child(l_row)
	for lbl_item in PuzzleScript.data().get("labels", []):
		var lid := String(lbl_item.get("id", ""))
		var ldisp := String(lbl_item.get("display", lid))
		var active_l := current_lbl == lid
		var l_btn := _button(("✓ " if active_l else "") + ldisp, active_l, false, "Label_%s_%s" % [cid, lid])
		l_btn.pressed.connect(func() -> void: choose_cassette_label(cid, lid))
		l_row.add_child(l_btn)

	# 4. Cassette Seal
	var seal_card := _card(Color(0.13, 0.72, 0.78, 0.75) if _target_id in ["seal_alo", "seal_tara"] else Color(0.28, 0.39, 0.58, 0.55))
	col.add_child(seal_card)
	var slbox := _card_box(seal_card)
	slbox.add_child(_label("4. CASSETTE CONTAINMENT SEAL (%s)" % title.to_upper(), 13, MUSTARD))
	var seal_closed := bool(c_wb.get("seal_closed", false)) or bool(c_comm.get("sealed", false))
	var sl_row := HFlowContainer.new()
	sl_row.add_theme_constant_override("h_separation", 8)
	sl_row.add_theme_constant_override("v_separation", 8)
	slbox.add_child(sl_row)
	var close_seal_btn := _button(("✓ " if seal_closed else "") + "CLOSE & LOCK SEAL", seal_closed, false, "Seal_%s_closed" % cid)
	close_seal_btn.pressed.connect(func() -> void: choose_cassette_seal(cid, true))
	sl_row.add_child(close_seal_btn)
	var open_seal_btn := _button(("✓ " if not seal_closed else "") + "LEAVE SEAL OPEN", not seal_closed, false, "Seal_%s_open" % cid)
	open_seal_btn.pressed.connect(func() -> void: choose_cassette_seal(cid, false))
	sl_row.add_child(open_seal_btn)

func _render_preview_and_science() -> Control:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	col.add_child(_label("RESULT PREVIEW, HINTS & NASA EVIDENCE", 15, CYAN))

	var gate_preview: Dictionary = _view.get("gate_preview", {})
	var prereq := String(_view.get("prerequisite_reason", ""))
	var accepted := prereq.is_empty() and bool(gate_preview.get("accepted", false))
	var diag_card := _card(Color(0.30, 0.69, 0.31, 0.75) if accepted else Color(0.95, 0.76, 0.19, 0.75))
	col.add_child(diag_card)
	var dbox := _card_box(diag_card)
	dbox.add_child(_label(
		"STEP DIAGNOSTIC · " + ("READY TO PREVIEW & COMMIT" if accepted else "ADJUSTMENT REQUIRED"),
		13,
		GREEN if accepted else MUSTARD
	))
	var main_msg := prereq if not prereq.is_empty() else String(gate_preview.get("reason", ""))
	dbox.add_child(_wrap(main_msg, 12, IVORY))
	if not String(gate_preview.get("observe", "")).is_empty():
		dbox.add_child(_wrap("OBSERVE: " + String(gate_preview.get("observe", "")), 12, GREEN))
	if not String(gate_preview.get("explain", "")).is_empty():
		dbox.add_child(_wrap("EXPLAIN: " + String(gate_preview.get("explain", "")), 12, MUTED))
	if not accepted and not String(gate_preview.get("hint", "")).is_empty():
		dbox.add_child(_wrap("HELPFUL HINT (NON-PUNISHING): " + String(gate_preview.get("hint", "")), 12, MUSTARD))

	# Commissioning Checklist
	var p01: Dictionary = _view.get("p01", {})
	var comp: Dictionary = _view.get("completion", {})
	var check_card := _card(Color(0.28, 0.39, 0.58, 0.55))
	col.add_child(check_card)
	var ckbox := _card_box(check_card)
	ckbox.add_child(_label("P-01 COMMISSIONING CHECKLIST", 13, MUSTARD))
	var items := [
		[bool(p01.get("probe_zeroed", false)), "Dry reference zeroed (10 -> 0)"],
		[bool(p01.get("probe_spanned", false)), "Wet reference spanned (110 -> 100)"],
		[bool(p01.get("probe_rechecked", false)), "Two-point recheck verified (0 / 100)"],
		[bool(p01.get("packet_scanned", false)), "Seed packet scanned intact (ALO / N., 2 seeds)"],
		[bool(comp.get("seeds_ok", false)), "1 seed placed in Alo + 1 seed in Tara"],
		[bool(comp.get("moisture_ok", false)), "Both cassettes watered to 40–60 band (50 nominal)"],
		[bool(comp.get("labels_ok", false)), "Distinct labels (EXTERNAL TEST & INDOOR REFERENCE)"],
		[bool(comp.get("seals_ok", false)), "Both cassette seals closed & locked"],
	]
	for entry in items:
		var done := bool(entry[0])
		ckbox.add_child(_wrap("%s %s" % ["[DONE]" if done else "[TODO]", String(entry[1])], 12, GREEN if done else MUTED))

	# Progressive Hints (SYS_22)
	var hints: Array = _view.get("hints", [])
	var hint_card := _card(Color(0.28, 0.39, 0.58, 0.55))
	col.add_child(hint_card)
	var hbox := _card_box(hint_card)
	hbox.add_child(_label("PROGRESSIVE HINTS (%d / 3 REVEALED · NO PENALTY)" % hints.size(), 13, MUSTARD))
	if hints.is_empty():
		hbox.add_child(_wrap("Need guidance? Click SHOW NEXT HINT below. Hints never reduce your score or ending.", 12, MUTED))
	else:
		for h in hints:
			hbox.add_child(_wrap("• %s: %s" % [String(h.get("title", h.get("id", "Hint"))), String(h.get("text", ""))], 12, IVORY))

	# NASA Science & Data Cards (M0-15)
	var cards: Array = _view.get("data_cards", [])
	var sc_card := _card(Color(0.13, 0.72, 0.78, 0.65))
	col.add_child(sc_card)
	var scbox := _card_box(sc_card)
	scbox.add_child(_label("NASA SCIENCE & DATA CARDS (P-01 EVIDENCE)", 13, CYAN))
	for card in cards:
		if card is Dictionary:
			scbox.add_child(_wrap("• %s (%s): %s" % [String(card.get("title", "")), String(card.get("evidence_tag", "Real")), String(card.get("gameplay_use", ""))], 11, IVORY))
	var dc_btn := _button("OPEN NASA DATA CARDS (%d)" % cards.size(), false, false, "DataCardsCardBtn")
	dc_btn.pressed.connect(func() -> void: open_data_cards())
	scbox.add_child(dc_btn)
	return col

func _render_confirmation() -> void:
	var gate: Dictionary = _view.get("gate", {})
	var gate_preview: Dictionary = _view.get("gate_preview", {})
	var card := _card(Color(0.95, 0.76, 0.19, 0.90))
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_child(card)
	var box := _card_box(card)
	box.add_child(_label("CONFIRM P-01 OPERATION", 18, MUSTARD))
	box.add_child(_wrap("About to commit: %s (%s)." % [String(gate.get("title", _target_id)), String(gate.get("label", _target_id))], 14, IVORY))
	box.add_child(_wrap("Preview summary: " + String(gate_preview.get("reason", "")), 13, GREEN))
	if not String(gate_preview.get("observe", "")).is_empty():
		box.add_child(_wrap("Observe: " + String(gate_preview.get("observe", "")), 13, IVORY))
	box.add_child(_wrap("Press SPACE or click CONFIRM & COMMIT to record this step, or press ESC to keep editing.", 13, MUTED))
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 10)
	row.add_theme_constant_override("v_separation", 10)
	box.add_child(row)
	var confirm_btn := _button("CONFIRM & COMMIT · SPACE", true, false, "ConfirmCommit")
	confirm_btn.pressed.connect(func() -> void: confirm_commit())
	row.add_child(confirm_btn)
	var cancel_btn := _button("KEEP EDITING · ESC", false, false, "CancelConfirm")
	cancel_btn.pressed.connect(func() -> void: cancel_confirm())
	row.add_child(cancel_btn)

func _render_footer() -> void:
	var footer := VBoxContainer.new()
	footer.add_theme_constant_override("separation", 6)
	_content.add_child(footer)
	var default_notice := String(_view.get("block_reason", ""))
	if default_notice.is_empty():
		default_notice = "Step settings are valid. Click PREVIEW STEP, then COMMIT · SPACE."
	var notice_text := _notice if not _notice.is_empty() else default_notice
	var notice_lbl := _wrap(notice_text, 12, GREEN if _previewed_key == _selection_key() and not _previewed_key.is_empty() else MUSTARD)
	notice_lbl.name = "BenchNotice"
	footer.add_child(notice_lbl)

	var bar := HFlowContainer.new()
	bar.add_theme_constant_override("h_separation", 8)
	bar.add_theme_constant_override("v_separation", 8)
	footer.add_child(bar)

	if String(_view.get("scene_id", "")) == "EX-CH01-S04":
		var cid := _active_cassette_id()
		var reset_btn := _button("RESET %s CASSETTE" % cid.to_upper(), false, false, "ResetCassette")
		reset_btn.pressed.connect(func() -> void: reset_cassette(cid))
		bar.add_child(reset_btn)

	var hints_shown: int = _view.get("hints", []).size()
	var hint_btn := _button("SHOW NEXT HINT (%d/3)" % hints_shown, false, false, "Hint")
	hint_btn.pressed.connect(func() -> void: reveal_hint())
	bar.add_child(hint_btn)

	var cards_btn := _button("DATA CARDS", false, false, "DataCards")
	cards_btn.pressed.connect(func() -> void: open_data_cards())
	bar.add_child(cards_btn)

	var preview_btn := _button("PREVIEW STEP", _previewed_key == _selection_key() and not _previewed_key.is_empty(), false, "Preview")
	preview_btn.pressed.connect(func() -> void: preview())
	bar.add_child(preview_btn)

	var commit_reason := _commit_reason()
	var commit_btn := _button("COMMIT · SPACE", commit_reason.is_empty(), not commit_reason.is_empty(), "Commit")
	commit_btn.tooltip_text = commit_reason if not commit_reason.is_empty() else "Open commit confirmation (Space)."
	commit_btn.pressed.connect(func() -> void: request_commit())
	bar.add_child(commit_btn)

	var close_btn := _button("CLOSE · ESC", false, false, "Close")
	close_btn.pressed.connect(func() -> void: close())
	bar.add_child(close_btn)

# --- Helpers ---------------------------------------------------------------

func _puzzle() -> RefCounted:
	return _route.p01_puzzle()

func _refresh_view() -> void:
	if _route != null:
		_view = _route.p01_bench_view(_target_id)

func _active_cassette_id() -> String:
	var ginfo: Dictionary = _view.get("gate", PuzzleScript.gate_info(_target_id))
	var cid := String(ginfo.get("cassette", ""))
	if cid in ["alo", "tara"]:
		return cid
	return "tara" if _target_id.contains("tara") else "alo"

func _selection_key() -> String:
	if _route == null:
		return ""
	return "%s:%s" % [_target_id, JSON.stringify(_puzzle().payload_for_gate(_target_id))]

func _commit_reason() -> String:
	_refresh_view()
	var prereq := String(_view.get("prerequisite_reason", ""))
	if not prereq.is_empty():
		return prereq
	var block := String(_view.get("block_reason", ""))
	if not block.is_empty():
		var hint := String(_view.get("gate_preview", {}).get("hint", ""))
		return "%s  ·  Hint: %s" % [block, hint] if not hint.is_empty() else block
	if _previewed_key.is_empty() or _previewed_key != _selection_key():
		return "Click PREVIEW STEP to verify the current bench settings before committing."
	return ""

func _after_action(result: Dictionary, focus_control: String) -> void:
	_previewed_key = ""
	_confirming = false
	var reason := String(result.get("reason", ""))
	var hint := String(result.get("hint", ""))
	_notice = "%s  ·  Hint: %s" % [reason, hint] if (not bool(result.get("accepted", true)) and not hint.is_empty()) else reason
	_focus_name = focus_control
	_render()

func _layout() -> void:
	if _frame == null:
		return
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0 or viewport_size.y <= 0:
		viewport_size = Vector2(1280, 720)
	var pad := Vector2(20, 16)
	_frame.position = pad
	_frame.size = viewport_size - pad * 2.0

func _grab_first_focus() -> void:
	for name in ["Cup_dry", "Zero_-10", "Span_100", "Recheck_both", "Scan_sealed_optical", "Seeds_alo_1", "Seeds_tara_1", "Moisture_alo_50", "Moisture_tara_50", "Preview", "Close"]:
		var btn := find_child(name, true, false) as Control
		if btn != null and btn.is_visible_in_tree():
			btn.grab_focus()
			return

func _restore_focus() -> void:
	if not is_inside_tree() or _focus_name.is_empty():
		return
	var target := find_child(_focus_name, true, false) as Control
	if target != null and target.is_visible_in_tree() and target.focus_mode != Control.FOCUS_NONE:
		target.grab_focus()

func _scroll(child: Control, scroll_name: String) -> ScrollContainer:
	var sc := ScrollContainer.new()
	sc.name = scroll_name
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.follow_focus = true
	sc.get_v_scroll_bar().focus_mode = Control.FOCUS_ALL
	sc.add_child(child)
	return sc

func _card(border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _box(Color(0.06, 0.10, 0.18, 0.94), border, 10, 1))
	return panel

func _card_box(card: PanelContainer) -> VBoxContainer:
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	card.add_child(margin)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 5)
	margin.add_child(box)
	return box

func _label(text: String, size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", _fs(size))
	lbl.add_theme_color_override("font_color", color)
	return lbl

func _wrap(text: String, size: int, color: Color) -> Label:
	var lbl := _label(text, size, color)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return lbl

func _button(text: String, selected: bool = false, disabled_state: bool = false, button_name: String = "") -> Button:
	var btn := Button.new()
	if not button_name.is_empty():
		btn.name = button_name
	btn.text = text
	btn.disabled = disabled_state
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.custom_minimum_size = Vector2(110, MIN_TARGET)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.focus_mode = Control.FOCUS_ALL
	btn.add_theme_font_size_override("font_size", _fs(13))
	var fill := Color("#233B5E") if selected else NAVY
	var border := MUSTARD if selected else Color(0.28, 0.42, 0.64, 0.85)
	btn.add_theme_color_override("font_color", MUSTARD if selected else IVORY)
	btn.add_theme_color_override("font_hover_color", INK)
	btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.60, 0.68, 0.75))
	btn.add_theme_stylebox_override("normal", _box(fill, border, 8, 2 if selected else 1))
	btn.add_theme_stylebox_override("hover", _box(MUSTARD, MUSTARD, 8, 2))
	btn.add_theme_stylebox_override("focus", _box(Color("#28466E"), MUSTARD, 8, 2))
	btn.add_theme_stylebox_override("disabled", _box(Color(0.08, 0.11, 0.18, 0.65), Color(0.22, 0.28, 0.38, 0.5), 8, 1))
	return btn

func _box(bg: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	for side in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		style.set("corner_radius_" + side, radius)
	for side in ["left", "right", "top", "bottom"]:
		style.set("border_width_" + side, border_width)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

func _fs(base: int) -> int:
	var factor := 1.5 if bool(_settings.get("large_text", false)) else 1.0
	return int(round(float(base) * factor))
