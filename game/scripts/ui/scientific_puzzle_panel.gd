extends Control
class_name ScientificPuzzlePanel

## Interactive scientific puzzle panel for Chapter 2 puzzles P-03 (Alo Meets Tara)
## and P-04 (Recorder Reconstruction), implementing execution/UI_09_SCIENTIFIC_PUZZLE.md
## and game-design/25_PLAYER_CLARITY_AND_MOON_JOURNEY.md (§1, §2, §6).
##
## Left column: First-time Learn card, Observed data & Class-mode crew clues,
## scene continuity bridge, and offline NASA Data Cards viewer.
## Centre column: Interactive equipment, flower/brush workbench, 7-day care log,
## stem-colour prediction options (P-03), or bench provenance rules, metadata
## token slots with removable tokens, audio transcripts, and Observed / Inferred /
## Unknown classification board (P-04).
## Right column: Plain-language Before -> After station & plant preview from the
## authoritative route simulation, plus specific non-punishing scientific feedback.
## Bottom bar: Reset Step, Progressive Hint (H1/H2/H3), Try It (Preview), and
## Lock In (Space to stage confirmation, Space again to commit; Esc to step back).

signal commit_requested(target_id: String, payload: Dictionary)
signal opened(target_id: String)
signal closed(target_id: String)

const ScienceScript = preload("res://scripts/science/science_data.gd")
const P03Script = preload("res://scripts/puzzles/p03_pollination.gd")
const P04Script = preload("res://scripts/puzzles/p04_recorder_reconstruction.gd")

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
	{"key": "E", "name": "Battery", "cap": "20"},
	{"key": "A", "name": "Air", "cap": "10"},
	{"key": "C", "name": "Alo & Tara condition", "cap": "10"},
	{"key": "H", "name": "Garden health", "cap": "10"},
	{"key": "R", "name": "Food (days)", "cap": ""},
]

var _science := ScienceScript.new()
var _route: RefCounted
var _target_id := ""
var _view: Dictionary = {}
var _settings := {
	"captions": true,
	"large_text": false,
	"timer_free": true,
	"reduced_motion": false,
}
var _confirm_open := false
var _close_confirm_open := false
var _data_cards_open := false
var _dirty_since_open := false
var _status_message := ""
var _status_ok := true

var _backdrop: PanelContainer
var _title_label: Label
var _stage_badge: Label
var _question_label: Label
var _close_button: Button
var _left_column: VBoxContainer
var _centre_column: VBoxContainer
var _right_column: VBoxContainer
var _reset_button: Button
var _hint_button: Button
var _preview_button: Button
var _commit_button: Button
var _confirm_bar: PanelContainer
var _confirm_label: Label
var _confirm_yes: Button
var _confirm_no: Button

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_build_shell()

## Opens the scientific puzzle panel for a Chapter 2 route and target ID.
func open(route: RefCounted, target_id: String = "", settings: Dictionary = {}) -> bool:
	if route == null or not route.has_method("puzzle_view"):
		return false
	_route = route
	for key in settings.keys():
		_settings[key] = settings[key]
	var initial_view: Dictionary = _route.puzzle_view(target_id)
	_target_id = String(initial_view.get("target_id", target_id))
	_confirm_open = false
	_close_confirm_open = false
	_dirty_since_open = false
	_status_message = ""
	_status_ok = true
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_refresh()
	opened.emit(_target_id)
	return true

## Closes the scientific puzzle panel, optionally checking for uncommitted changes.
func close(force: bool = false) -> void:
	if not visible:
		return
	if not force and _dirty_since_open and not _close_confirm_open:
		_close_confirm_open = true
		_confirm_open = false
		_status_ok = false
		_status_message = "You have uncommitted selections on the workbench. Confirm Close to step away, or Keep Working."
		_refresh_confirm_bar()
		return
	var previous := _target_id
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_confirm_open = false
	_close_confirm_open = false
	_dirty_since_open = false
	closed.emit(previous)

## Returns true when the scientific puzzle panel is visible.
func is_open() -> bool:
	return visible

## Returns the active target ID being configured in the panel.
func active_target_id() -> String:
	return _target_id

## Returns the latest rendered view dictionary for tests and inspection.
func current_view() -> Dictionary:
	return _view.duplicate(true)

## Updates accessibility settings (including 150% `large_text` mode) and re-renders.
func set_accessibility(settings: Dictionary) -> void:
	for key in settings.keys():
		_settings[key] = settings[key]
	if visible:
		_refresh()

## Toggles the inline NASA Data Cards drawer in the left column.
func toggle_data_cards(open_state: bool = true) -> void:
	_data_cards_open = open_state
	if visible:
		_refresh()

## Returns true when the NASA Data Cards drawer is expanded.
func is_data_cards_open() -> bool:
	return _data_cards_open

## Returns true when the commit confirmation bar is open.
func is_confirm_open() -> bool:
	return _confirm_open

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		if _confirm_open or _close_confirm_open:
			_confirm_open = false
			_close_confirm_open = false
			_refresh_confirm_bar()
		else:
			close(false)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		if _close_confirm_open:
			close(true)
			get_viewport().set_input_as_handled()
		elif _confirm_open:
			_confirm_commit()
			get_viewport().set_input_as_handled()
		else:
			_request_commit_stage()
			get_viewport().set_input_as_handled()

func _build_shell() -> void:
	_backdrop = PanelContainer.new()
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.offset_left = 18.0
	_backdrop.offset_top = 14.0
	_backdrop.offset_right = -18.0
	_backdrop.offset_bottom = -14.0
	_backdrop.add_theme_stylebox_override("panel", _box(INK, MUSTARD, 2, 16))
	add_child(_backdrop)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 8)
	_backdrop.add_child(root_vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root_vbox.add_child(header)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 2)
	header.add_child(title_box)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 10)
	title_box.add_child(top_row)

	_title_label = _label("", 18, MUSTARD)
	top_row.add_child(_title_label)

	_stage_badge = _label("", 13, CYAN)
	top_row.add_child(_stage_badge)

	_question_label = _label("", 13, IVORY, true)
	title_box.add_child(_question_label)

	_close_button = _button("Close (Esc)", func() -> void: close(false))
	_close_button.custom_minimum_size = Vector2(128.0, MIN_TARGET)
	header.add_child(_close_button)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	root_vbox.add_child(body)

	_left_column = _scrollable_column(body, 0.95)
	_centre_column = _scrollable_column(body, 1.45)
	_right_column = _scrollable_column(body, 1.0)

	_confirm_bar = PanelContainer.new()
	_confirm_bar.visible = false
	_confirm_bar.add_theme_stylebox_override("panel", _box(NAVY_DEEP, MUSTARD, 2, 10))
	root_vbox.add_child(_confirm_bar)

	var confirm_row := HBoxContainer.new()
	confirm_row.add_theme_constant_override("separation", 10)
	_confirm_bar.add_child(confirm_row)

	_confirm_label = _label("", 13, IVORY, true)
	_confirm_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm_row.add_child(_confirm_label)

	_confirm_yes = _button("Confirm Lock In (Space)", _on_confirm_yes)
	_confirm_yes.add_theme_stylebox_override("normal", _box(NAVY, GREEN, 2, 8))
	confirm_row.add_child(_confirm_yes)

	_confirm_no = _button("Step Back (Esc)", _on_confirm_no)
	confirm_row.add_child(_confirm_no)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	root_vbox.add_child(footer)

	_reset_button = _button("Reset Step", _on_reset_pressed)
	footer.add_child(_reset_button)

	_hint_button = _button("Hint (0/3)", _on_hint_pressed)
	footer.add_child(_hint_button)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)

	_preview_button = _button("Try It (Preview)", _on_preview_pressed)
	_preview_button.add_theme_stylebox_override("normal", _box(NAVY_DEEP, CYAN, 2, 8))
	footer.add_child(_preview_button)

	_commit_button = _button("Lock In Step (Space)", _request_commit_stage)
	_commit_button.add_theme_stylebox_override("normal", _box(NAVY, MUSTARD, 2, 8))
	footer.add_child(_commit_button)

func _scrollable_column(parent: Control, ratio: float) -> VBoxContainer:
	var frame := PanelContainer.new()
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.size_flags_stretch_ratio = ratio
	frame.add_theme_stylebox_override("panel", _box(NAVY_DEEP, NAVY, 1, 10))
	parent.add_child(frame)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	frame.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox)
	return vbox

func _refresh() -> void:
	if _route == null:
		return
	_view = _route.puzzle_view(_target_id)
	_target_id = String(_view.get("target_id", _target_id))
	var puzzle_id := String(_view.get("puzzle_id", "P-03"))
	var stage: Dictionary = _view.get("stage", {})
	_title_label.text = "%s · %s" % [puzzle_id, String(_view.get("title", "")).to_upper()]
	_title_label.add_theme_font_size_override("font_size", _scaled(18))
	_stage_badge.text = "[%s]" % String(stage.get("label", "Interactive Workbench"))
	_stage_badge.add_theme_font_size_override("font_size", _scaled(13))
	_question_label.text = "%s — %s" % [String(_view.get("question", "")), String(_view.get("goal_one_line", ""))]
	_question_label.add_theme_font_size_override("font_size", _scaled(12))
	_close_button.add_theme_font_size_override("font_size", _scaled(13))

	_build_left_column(puzzle_id)
	if puzzle_id == "P-04":
		_build_p04_centre()
	else:
		_build_p03_centre()
	_build_right_column(puzzle_id)

	var hint_tier := int(_view.get("hint_tier", 0))
	var hint_max := int(_view.get("hint_max", 3))
	_hint_button.text = "Hint (%d/%d)" % [hint_tier, hint_max]
	for btn in [_reset_button, _hint_button, _preview_button, _commit_button]:
		btn.add_theme_font_size_override("font_size", _scaled(13))
	_refresh_confirm_bar()

func _build_left_column(puzzle_id: String) -> void:
	_clear(_left_column)
	_left_column.add_child(_section_header("1. OBSERVED CLUES & DATA CARDS"))

	var explainer: Dictionary = _view.get("first_time_explainer", {})
	if not explainer.is_empty():
		var learn_card := _card_box(NAVY, CYAN)
		_left_column.add_child(learn_card)
		var lv := VBoxContainer.new()
		lv.add_theme_constant_override("separation", 4)
		learn_card.add_child(lv)
		lv.add_child(_label("LEARN · " + String(explainer.get("title", "")), 13, CYAN, true))
		lv.add_child(_label(String(explainer.get("summary", "")), 12, IVORY, true))

	var stage: Dictionary = _view.get("stage", {})
	if not stage.is_empty():
		var stage_card := _card_box(INK, NAVY)
		_left_column.add_child(stage_card)
		var sv := VBoxContainer.new()
		sv.add_theme_constant_override("separation", 3)
		stage_card.add_child(sv)
		sv.add_child(_label(String(stage.get("label", "")), 12, MUSTARD, true))
		sv.add_child(_label(String(stage.get("summary", "")), 12, MUTED, true))

	var shared: Array = _view.get("shared_clues", [])
	for clue in _view.get("clues", []):
		if not clue is Dictionary:
			continue
		var clue_id := String(clue.get("id", ""))
		var is_shared := shared.has(clue_id)
		var card := _card_box(INK, GREEN if is_shared else NAVY)
		_left_column.add_child(card)
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 4)
		card.add_child(cv)
		cv.add_child(_label("[%s · %s] %s" % [String(clue.get("holder", "")), String(clue.get("holder_name", "")), String(clue.get("label", ""))], 12, MUSTARD, true))
		cv.add_child(_label(String(clue.get("text", "")), 12, IVORY, true))
		var share_btn := _button(
			"[SHARED WITH CREW] " + clue_id if is_shared else "Share Clue With Crew (" + clue_id + ")",
			func() -> void: _on_share_clue(puzzle_id, clue_id)
		)
		cv.add_child(share_btn)

	var bridges: Dictionary = _view.get("bridges", {})
	if not bridges.is_empty():
		var bridge_card := _card_box(INK, NAVY)
		_left_column.add_child(bridge_card)
		var bv := VBoxContainer.new()
		bv.add_theme_constant_override("separation", 3)
		bridge_card.add_child(bv)
		bv.add_child(_label("CONTINUITY & BENCH NOTES", 12, CYAN, true))
		for key in bridges.keys():
			bv.add_child(_label("• " + String(bridges[key]), 11, MUTED, true))

	var toggle_cards_btn := _button(
		"Hide NASA Data Cards" if _data_cards_open else "Open NASA Data Cards (%s)" % puzzle_id,
		func() -> void: toggle_data_cards(not _data_cards_open)
	)
	toggle_cards_btn.add_theme_stylebox_override("normal", _box(NAVY, CYAN, 2, 8))
	_left_column.add_child(toggle_cards_btn)

	if _data_cards_open:
		for card_data in _science.cards_for_puzzle(puzzle_id):
			if not card_data is Dictionary:
				continue
			var dcard := _card_box(NAVY_DEEP, CYAN)
			_left_column.add_child(dcard)
			var dv := VBoxContainer.new()
			dv.add_theme_constant_override("separation", 3)
			dcard.add_child(dv)
			dv.add_child(_label("%s · %s" % [String(card_data.get("agency", "NASA")), String(card_data.get("title", ""))], 12, CYAN, true))
			dv.add_child(_label("Evidence: %s" % String(card_data.get("evidence_label", "")), 11, MUSTARD, true))
			dv.add_child(_label("Takeaway: %s" % String(card_data.get("takeaway", "")), 12, IVORY, true))
			dv.add_child(_label("Boundary: %s" % String(card_data.get("boundary", "")), 11, MUTED, true))

func _build_p03_centre() -> void:
	_clear(_centre_column)
	_centre_column.add_child(_section_header("2. RECIPROCAL POLLINATION WORKBENCH (P-03)"))
	_build_scene_step_selector()

	var p03: RefCounted = _route.p03()
	var scene_id := String(_view.get("scene_id", ""))
	var stage_id := String(_view.get("stage_id", "apply"))

	if stage_id == "twist" or scene_id == "EX-CH02-S06":
		_build_p03_prediction_section(p03)
		return

	var quick_card := _card_box(NAVY, MUSTARD)
	_centre_column.add_child(quick_card)
	var qv := VBoxContainer.new()
	qv.add_theme_constant_override("separation", 4)
	quick_card.add_child(qv)
	var active_action := _active_puzzle_action()
	qv.add_child(_label("ACTIVE STEP · %s" % _active_target_label(), 13, MUSTARD, true))
	if not active_action.is_empty():
		var cfg_btn := _button(
			"Configure Verified Protocol Choices For Current Step",
			func() -> void:
				_dirty_since_open = true
				var res: Dictionary = p03.configure_for_action(active_action)
				_status_ok = bool(res.get("accepted", false))
				_status_message = String(res.get("reason", ""))
				_refresh()
		)
		cfg_btn.add_theme_stylebox_override("normal", _box(NAVY_DEEP, GREEN, 2, 8))
		qv.add_child(cfg_btn)

	# 1. Space Weather & Carrier Isolation
	var env_card := _card_box(INK, NAVY)
	_centre_column.add_child(env_card)
	var ev := VBoxContainer.new()
	ev.add_theme_constant_override("separation", 4)
	env_card.add_child(ev)
	ev.add_child(_label("A. SPACE-WEATHER CHECK & PRESSURE BOUNDARY ORDER", 12, CYAN, true))
	var current_weather := String(_view.get("weather_mode", ""))
	for w_opt in _view.get("weather_modes", []):
		if not w_opt is Dictionary:
			continue
		var w_id := String(w_opt.get("id", ""))
		var selected: bool = current_weather == w_id
		ev.add_child(_choice_button(
			"%s %s" % ["[SELECTED]" if selected else "[SELECT]", String(w_opt.get("label", w_id))],
			selected,
			bool(w_opt.get("valid", false)),
			func() -> void:
				_dirty_since_open = true
				var res: Dictionary = p03.select_weather_mode(w_id)
				_status_ok = bool(res.get("accepted", false))
				_status_message = String(res.get("reason", ""))
				_refresh()
		))

	var current_carrier := String(_view.get("carrier_mode", ""))
	for c_opt in _view.get("carrier_modes", []):
		if not c_opt is Dictionary:
			continue
		var c_id := String(c_opt.get("id", ""))
		var selected: bool = current_carrier == c_id
		ev.add_child(_choice_button(
			"%s %s" % ["[SELECTED]" if selected else "[SELECT]", String(c_opt.get("label", c_id))],
			selected,
			bool(c_opt.get("valid", false)),
			func() -> void:
				_dirty_since_open = true
				var res: Dictionary = p03.select_carrier_mode(c_id)
				_status_ok = bool(res.get("accepted", false))
				_status_message = String(res.get("reason", ""))
				_refresh()
		))

	# 2. Donor Plant & Source Flower Structure
	var donor_card := _card_box(INK, NAVY)
	_centre_column.add_child(donor_card)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 4)
	donor_card.add_child(dv)
	dv.add_child(_label("B. DONOR PLANT & POLLEN SOURCE STRUCTURE", 12, CYAN, true))
	var current_donor := String(_view.get("donor_id", ""))
	var plants: Dictionary = _view.get("plants", {})
	for p_id: String in ["TARA-01", "ALO-01"]:
		var p_info: Dictionary = plants.get(p_id, {})
		var selected: bool = current_donor == p_id
		dv.add_child(_choice_button(
			"%s Donor: %s (%s · %s)" % ["[SELECTED]" if selected else "[SELECT]", String(p_info.get("label", p_id)), String(p_info.get("chamber", "")), String(p_info.get("stem_colour", ""))],
			selected,
			true,
			func() -> void:
				_dirty_since_open = true
				var res: Dictionary = p03.select_donor(p_id)
				_status_ok = bool(res.get("accepted", false))
				_status_message = String(res.get("reason", ""))
				_refresh()
		))

	var current_source := String(_view.get("source_structure", ""))
	for s_opt in _view.get("structures", []):
		if not s_opt is Dictionary:
			continue
		var s_id := String(s_opt.get("id", ""))
		var selected: bool = current_source == s_id
		dv.add_child(_choice_button(
			"%s Source Structure: %s" % ["[SELECTED]" if selected else "[SELECT]", String(s_opt.get("label", s_id))],
			selected,
			bool(s_opt.get("valid_collect", false)),
			func() -> void:
				_dirty_since_open = true
				var res: Dictionary = p03.select_source_structure(s_id)
				_status_ok = bool(res.get("accepted", false))
				_status_message = String(res.get("reason", ""))
				_refresh()
		))

	# 3. Brush Selection & Sterile Tip Replacement
	var brush_card := _card_box(INK, NAVY)
	_centre_column.add_child(brush_card)
	var bv := VBoxContainer.new()
	bv.add_theme_constant_override("separation", 4)
	brush_card.add_child(bv)
	bv.add_child(_label("C. DEDICATED POLLINATION BRUSH & STERILE TIPS", 12, CYAN, true))
	var current_brush := String(_view.get("brush_id", ""))
	var dirty_map: Dictionary = _view.get("brush_dirty", {})
	for b_opt in _view.get("brushes", []):
		if not b_opt is Dictionary:
			continue
		var b_id := String(b_opt.get("id", ""))
		var is_dirty := bool(dirty_map.get(b_id, false))
		var selected: bool = current_brush == b_id
		var suffix := " [DIRTY TIP — REPLACE BEFORE COLLECTING]" if is_dirty else ""
		bv.add_child(_choice_button(
			"%s %s%s" % ["[SELECTED]" if selected else "[SELECT]", String(b_opt.get("label", b_id)), suffix],
			selected,
			bool(b_opt.get("valid", false)) and not is_dirty,
			func() -> void:
				_dirty_since_open = true
				var res: Dictionary = p03.select_brush(b_id)
				_status_ok = bool(res.get("accepted", false))
				_status_message = String(res.get("reason", ""))
				_refresh()
		))
	var clean_row := HBoxContainer.new()
	clean_row.add_theme_constant_override("separation", 8)
	bv.add_child(clean_row)
	for b_clean: String in ["A", "B"]:
		var replace_btn := _button(
			"Replace Brush %s Tip (Clean Sterile Tip)" % b_clean,
			func() -> void:
				_dirty_since_open = true
				var res: Dictionary = p03.replace_brush_tip(b_clean)
				_status_ok = bool(res.get("accepted", false))
				_status_message = String(res.get("reason", ""))
				_refresh()
		)
		replace_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		clean_row.add_child(replace_btn)

	# 4. Recipient Plant & Target Flower Structure
	var rec_card := _card_box(INK, NAVY)
	_centre_column.add_child(rec_card)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 4)
	rec_card.add_child(rv)
	rv.add_child(_label("D. RECIPIENT PARTNER PLANT & TARGET STRUCTURE", 12, CYAN, true))
	var current_rec := String(_view.get("recipient_id", ""))
	for r_id: String in ["ALO-01", "TARA-01"]:
		var r_info: Dictionary = plants.get(r_id, {})
		var selected: bool = current_rec == r_id
		rv.add_child(_choice_button(
			"%s Recipient: %s (%s)" % ["[SELECTED]" if selected else "[SELECT]", String(r_info.get("label", r_id)), String(r_info.get("chamber", ""))],
			selected,
			r_id != current_donor or current_donor.is_empty(),
			func() -> void:
				_dirty_since_open = true
				var res: Dictionary = p03.select_recipient(r_id)
				_status_ok = bool(res.get("accepted", false))
				_status_message = String(res.get("reason", ""))
				_refresh()
		))

	var current_target := String(_view.get("target_structure", ""))
	for t_opt in _view.get("structures", []):
		if not t_opt is Dictionary:
			continue
		var t_id := String(t_opt.get("id", ""))
		var selected: bool = current_target == t_id
		rv.add_child(_choice_button(
			"%s Target Structure: %s" % ["[SELECTED]" if selected else "[SELECT]", String(t_opt.get("label", t_id))],
			selected,
			bool(t_opt.get("valid_transfer", false)),
			func() -> void:
				_dirty_since_open = true
				var res: Dictionary = p03.select_target_structure(t_id)
				_status_ok = bool(res.get("accepted", false))
				_status_message = String(res.get("reason", ""))
				_refresh()
		))

	# 5. Seven-Day Care Logbook (EX-CH02-S05)
	if scene_id == "EX-CH02-S05":
		var care_card := _card_box(INK, MUSTARD)
		_centre_column.add_child(care_card)
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 4)
		care_card.add_child(cv)
		cv.add_child(_label("E. SEVEN-DAY CARE LOGBOOK (30 APR – 06 MAY)", 12, MUSTARD, true))
		var logged_days: Array = _view.get("care_dates", [])
		var draft_days: Dictionary = _view.get("care_draft", {})
		for entry in _view.get("care_schedule", []):
			if not entry is Dictionary:
				continue
			var day := int(entry.get("day", 1))
			var is_logged := logged_days.has(day)
			var is_checked := is_logged or bool(draft_days.get(str(day), false))
			var status_tag := "[COMMITTED]" if is_logged else ("[CHECKED]" if is_checked else "[CHECK CARE VISIT]")
			var btn := _choice_button(
				"%s %s (%s)" % [status_tag, String(entry.get("label", "")), String(entry.get("date", ""))],
				is_checked,
				true,
				func() -> void:
					if is_logged:
						return
					_dirty_since_open = true
					var res: Dictionary = p03.toggle_care_day(day, not is_checked)
					_status_ok = bool(res.get("accepted", false))
					_status_message = String(res.get("reason", ""))
					_refresh()
			)
			cv.add_child(btn)

func _build_p03_prediction_section(p03: RefCounted) -> void:
	var pred_card := _card_box(INK, MUSTARD)
	_centre_column.add_child(pred_card)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 6)
	pred_card.add_child(pv)
	pv.add_child(_label("TWIST · PRE-REGISTERED STEM-COLOUR PREDICTION (EX-CH02-S06)", 13, MUSTARD, true))
	pv.add_child(_label("Alo has a purple stem and Tara has a green stem. Select your expectation, scientific reason, and future test before harvesting seeds.", 12, IVORY, true))

	var draft: Dictionary = _view.get("draft_prediction", {})
	var opts: Dictionary = _view.get("prediction_options", {})
	var sections := [
		{"field": "prediction", "group": "expectations", "title": "1. Expected Stem Colours in First-Generation Seedlings"},
		{"field": "reason", "group": "reasons", "title": "2. Scientific Basis (What Two Parent Stems Can and Cannot Prove)"},
		{"field": "future_test", "group": "future_tests", "title": "3. Future Test & Surprise Criterion After Harvest"},
	]
	for sec in sections:
		var field: String = sec.field
		var group: String = sec.group
		pv.add_child(_label(String(sec.title), 12, CYAN, true))
		var current_val := String(draft.get(field, ""))
		for item in opts.get(group, []):
			if not item is Dictionary:
				continue
			var val := String(item.get("value", ""))
			var selected: bool = current_val == val
			pv.add_child(_choice_button(
				"%s %s" % ["[SELECTED]" if selected else "[SELECT]", String(item.get("label", val))],
				selected,
				bool(item.get("valid", false)),
				func() -> void:
					_dirty_since_open = true
					var res: Dictionary = p03.select_prediction_field(field, val)
					_status_ok = bool(res.get("accepted", false))
					_status_message = String(res.get("reason", ""))
					_refresh()
			))

func _build_p04_centre() -> void:
	_clear(_centre_column)
	_centre_column.add_child(_section_header("2. RECORDER RECONSTRUCTION BOARD (P-04)"))
	_build_scene_step_selector()

	var p04: RefCounted = _route.p04()
	var scene_id := String(_view.get("scene_id", ""))
	var stage_id := String(_view.get("stage_id", "apply"))

	# Bench Evidence & Person Slot Rules (always visible for P-04 so player can test/verify rules)
	var rules_card := _card_box(INK, NAVY)
	_centre_column.add_child(rules_card)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 4)
	rules_card.add_child(rv)
	rv.add_child(_label("A. BENCH EVIDENCE HANDLING & PERSON SLOT DISCIPLINE", 12, CYAN, true))
	var current_label_mode := String(_view.get("label_handling", "photograph_in_place"))
	for l_opt in _view.get("label_handling_options", []):
		if not l_opt is Dictionary:
			continue
		var l_id := String(l_opt.get("id", ""))
		var selected: bool = current_label_mode == l_id
		rv.add_child(_choice_button(
			"%s %s" % ["[SELECTED]" if selected else "[SELECT]", String(l_opt.get("label", l_id))],
			selected,
			bool(l_opt.get("valid", false)),
			func() -> void:
				_dirty_since_open = true
				var res: Dictionary = p04.select_label_handling(l_id)
				_status_ok = bool(res.get("accepted", false))
				_status_message = String(res.get("reason", ""))
				_refresh()
		))

	var current_person_mode := String(_view.get("person_slot", "blank_unknown"))
	for p_opt in _view.get("person_slot_options", []):
		if not p_opt is Dictionary:
			continue
		var p_id := String(p_opt.get("id", ""))
		var selected: bool = current_person_mode == p_id
		rv.add_child(_choice_button(
			"%s %s" % ["[SELECTED]" if selected else "[SELECT]", String(p_opt.get("label", p_id))],
			selected,
			bool(p_opt.get("valid", false)),
			func() -> void:
				_dirty_since_open = true
				var res: Dictionary = p04.select_person_slot(p_id)
				_status_ok = bool(res.get("accepted", false))
				_status_message = String(res.get("reason", ""))
				_refresh()
		))

	# Metadata Token Matching Board (Apply stage S09 or Learn S07..S08)
	if stage_id in ["learn", "apply"] or scene_id in ["EX-CH02-S07", "EX-CH02-S08", "EX-CH02-S09"]:
		_build_p04_token_board(p04)

	# Transcripts & Observed / Inferred / Unknown Board (Twist stage S10..S11 or when unlocked)
	if stage_id == "twist" or scene_id in ["EX-CH02-S10", "EX-CH02-S11"] or not bool(_view.get("audio_locked", true)):
		_build_p04_classification_board(p04)

func _build_p04_token_board(p04: RefCounted) -> void:
	var board_card := _card_box(INK, MUSTARD)
	_centre_column.add_child(board_card)
	var bv := VBoxContainer.new()
	bv.add_theme_constant_override("separation", 6)
	board_card.add_child(bv)
	var audio_locked := bool(_view.get("audio_locked", true))
	bv.add_child(_label(
		"B. METADATA TOKEN MATCHING BOARD · %s" % ("[AUDIO LOCKED UNTIL ALL 3 MATCH]" if audio_locked else "[CHECKSUM & TRANSCRIPT UNLOCKED]"),
		12,
		MUSTARD if audio_locked else GREEN,
		true
	))

	var slots: Dictionary = _view.get("slots", {})
	var token_opts: Dictionary = _view.get("token_options", {})
	for file_info in _view.get("files", []):
		if not file_info is Dictionary:
			continue
		var field := String(file_info.get("field", ""))
		var slot: Dictionary = slots.get(field, {})
		var placed := String(slot.get("value", ""))
		var valid_token := bool(slot.get("valid_token", false))
		var disagrees := String(slot.get("source_disagrees", ""))

		var slot_box := _card_box(NAVY_DEEP, GREEN if valid_token else (RED if not placed.is_empty() else NAVY))
		bv.add_child(slot_box)
		var sv := VBoxContainer.new()
		sv.add_theme_constant_override("separation", 4)
		slot_box.add_child(sv)
		sv.add_child(_label("%s %s · Source: %s" % [String(file_info.get("label", "")), String(file_info.get("shape_badge", "")), String(file_info.get("source_card", ""))], 12, CYAN, true))
		sv.add_child(_label(String(file_info.get("description", "")), 11, MUTED, true))

		var status_line := "Slot empty — choose a token below."
		var status_color := MUTED
		if not placed.is_empty():
			if valid_token:
				status_line = "Placed token: %s [MATCHES %s]" % [placed, String(file_info.get("source_card", ""))]
				status_color = GREEN
			else:
				status_line = "Placed token: %s [SOURCE DISAGREES: %s — AUDIO LOCKED]" % [placed, disagrees]
				status_color = RED
		sv.add_child(_label(status_line, 12, status_color, true))

		for opt in token_opts.get(field, []):
			if not opt is Dictionary:
				continue
			var val := String(opt.get("value", ""))
			var selected: bool = placed == val
			sv.add_child(_choice_button(
				"%s %s %s" % ["[PLACED]" if selected else "[PLACE TOKEN]", String(opt.get("badge", "")), String(opt.get("label", val))],
				selected,
				bool(opt.get("valid", false)),
				func() -> void:
					_dirty_since_open = true
					var res: Dictionary = p04.set_slot_token(field, val)
					_status_ok = bool(res.get("valid_token", false))
					_status_message = String(res.get("reason", ""))
					_refresh()
			))

		if not placed.is_empty():
			var rem_btn := _button(
				"Remove Token From %s (%s)" % [String(file_info.get("file_id", field)), placed],
				func() -> void:
					_dirty_since_open = true
					var res: Dictionary = p04.remove_slot_token(field)
					_status_ok = true
					_status_message = String(res.get("reason", ""))
					_refresh()
			)
			sv.add_child(rem_btn)

func _build_p04_classification_board(p04: RefCounted) -> void:
	var transcripts: Dictionary = _view.get("transcripts", {})
	var tr_card := _card_box(INK, CYAN)
	_centre_column.add_child(tr_card)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 5)
	tr_card.add_child(tv)
	tv.add_child(_label("C. RECONSTRUCTED AUDIO TRANSCRIPTS (2034-04 · HORT-01 · ENGINEERING)", 12, CYAN, true))
	for t_key: String in ["engineer_2034", "n_memory"]:
		var item: Dictionary = transcripts.get(t_key, {})
		if item.is_empty():
			continue
		tv.add_child(_label("%s (%s):" % [String(item.get("speaker", "")), String(item.get("header", ""))], 12, MUSTARD, true))
		tv.add_child(_label("\"%s\"" % String(item.get("text", "")), 12, IVORY, true))

	var cls_card := _card_box(INK, MUSTARD)
	_centre_column.add_child(cls_card)
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 6)
	cls_card.add_child(cv)
	cv.add_child(_label("D. OBSERVED / INFERRED / UNKNOWN CLASSIFICATION BOARD", 12, MUSTARD, true))
	cv.add_child(_label("Separate what the physical records directly state (Observed) from voice-similarity guesses (Inferred) and unrecorded names (Unknown).", 11, MUTED, true))

	var current_cls: Dictionary = _view.get("classifications", {})
	for claim in _view.get("classification_claims", []):
		if not claim is Dictionary:
			continue
		var c_id := String(claim.get("id", ""))
		var chosen := String(current_cls.get(c_id, ""))
		var expected := String(claim.get("expected", ""))
		var claim_box := _card_box(NAVY_DEEP, GREEN if (not chosen.is_empty() and chosen == expected) else (RED if not chosen.is_empty() else NAVY))
		cv.add_child(claim_box)
		var item_v := VBoxContainer.new()
		item_v.add_theme_constant_override("separation", 4)
		claim_box.add_child(item_v)
		item_v.add_child(_label("Statement: %s" % String(claim.get("statement", "")), 12, IVORY, true))

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		item_v.add_child(row)
		for col_id: String in ["observed", "inferred", "unknown"]:
			var selected: bool = chosen == col_id
			var btn := _choice_button(
				"%s %s" % ["[SELECTED]" if selected else "Classify:", col_id.capitalize()],
				selected,
				col_id == expected,
				func() -> void:
					_dirty_since_open = true
					var res: Dictionary = p04.classify_claim(c_id, col_id)
					_status_ok = bool(res.get("accepted", false))
					_status_message = String(res.get("reason", ""))
					_refresh()
			)
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(btn)

func _build_scene_step_selector() -> void:
	var targets: Array = _view.get("scene_targets", [])
	if targets.is_empty():
		return
	var step_card := _card_box(NAVY_DEEP, NAVY)
	_centre_column.add_child(step_card)
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 4)
	step_card.add_child(sv)
	sv.add_child(_label("SCENE OPERATIONS & PUZZLE STEPS (%s)" % String(_view.get("scene_id", "")), 12, MUTED, true))
	for item in targets:
		if not item is Dictionary:
			continue
		var tid := String(item.get("target_id", ""))
		var done := bool(item.get("completed", false))
		var active := tid == _target_id
		var prefix := "[DONE]" if done else ("[ACTIVE STEP]" if active else "[STEP]")
		var btn := _choice_button(
			"%s %s" % [prefix, String(item.get("focus_label", tid))],
			active,
			done or active,
			func() -> void:
				_target_id = tid
				_confirm_open = false
				_refresh()
		)
		sv.add_child(btn)

func _build_right_column(_puzzle_id: String) -> void:
	_clear(_right_column)
	_right_column.add_child(_section_header("3. LIVE FORECAST & SCIENTIFIC FEEDBACK"))

	var preview: Dictionary = _view.get("target_preview", {})
	var accepted := bool(preview.get("accepted", false))
	var feedback_text := _status_message if not _status_message.is_empty() else String(_view.get("last_feedback", ""))
	if feedback_text.is_empty():
		feedback_text = String(preview.get("reason", "Configure your choices in the centre column and press Try It (Preview)."))

	var status_card := _card_box(NAVY_DEEP, GREEN if accepted else MUSTARD)
	_right_column.add_child(status_card)
	var st_v := VBoxContainer.new()
	st_v.add_theme_constant_override("separation", 4)
	status_card.add_child(st_v)
	st_v.add_child(_label(
		"STEP STATUS · %s" % ("[READY TO LOCK IN]" if accepted else "[NEEDS PLAYER SELECTION / ADJUSTMENT]"),
		13,
		GREEN if accepted else MUSTARD,
		true
	))
	st_v.add_child(_label("Active Target: %s" % _active_target_label(), 12, CYAN, true))
	st_v.add_child(_label("Step Check: %s" % String(preview.get("reason", "")), 12, IVORY, true))
	if not feedback_text.is_empty() and feedback_text != String(preview.get("reason", "")):
		st_v.add_child(_label("Workbench Note: %s" % feedback_text, 12, GREEN if _status_ok else RED, true))

	# Before -> After Resource & Plant Forecast
	var res_card := _card_box(INK, NAVY)
	_right_column.add_child(res_card)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 4)
	res_card.add_child(rv)
	rv.add_child(_label("STATION READINGS · BEFORE -> AFTER STEP", 12, CYAN, true))

	var before_res: Dictionary = _view.get("before_resources", {})
	var after_snap: Dictionary = preview.get("snapshot", {}) if preview.get("snapshot") is Dictionary else {}
	var after_res: Dictionary = after_snap.get("resources", before_res) if after_snap.get("resources") is Dictionary else before_res
	var before_dt := String(_view.get("before_datetime", ""))
	var after_dt := String(after_snap.get("scenario_datetime", before_dt))
	rv.add_child(_label("Clock: %s -> %s" % [before_dt, after_dt], 11, MUTED, true))

	for row_def in RESOURCE_ROWS:
		var k: String = row_def.key
		var b_val := float(before_res.get(k, 0.0))
		var a_val := float(after_res.get(k, b_val))
		var cap: String = row_def.cap
		var b_str := ("%.1f" % b_val) if k == "R" else ("%d%s" % [int(round(b_val)), ("/" + cap) if not cap.is_empty() else ""])
		var a_str := ("%.1f" % a_val) if k == "R" else ("%d%s" % [int(round(a_val)), ("/" + cap) if not cap.is_empty() else ""])
		var changed := not is_equal_approx(b_val, a_val)
		rv.add_child(_label(
			"%s: %s -> %s%s" % [String(row_def.name), b_str, a_str, " [CHANGED]" if changed else ""],
			12,
			MUSTARD if changed else IVORY,
			true
		))

	var before_plants: Array = _view.get("before_plants", [])
	var after_plants: Array = after_snap.get("plants", before_plants) if after_snap.get("plants") is Array else before_plants
	for idx in range(before_plants.size()):
		var bp: Dictionary = before_plants[idx] if before_plants[idx] is Dictionary else {}
		var ap: Dictionary = after_plants[idx] if idx < after_plants.size() and after_plants[idx] is Dictionary else bp
		var p_name := "Alo (Greenhouse)" if String(bp.get("individual_id", "")) == "ALO-01" else "Tara (Bay 2)"
		rv.add_child(_label(
			"%s: stage %s -> %s (pollinated: %s)" % [
				p_name,
				String(bp.get("stage", "flowering")),
				String(ap.get("stage", bp.get("stage", "flowering"))),
				"Yes" if bool(ap.get("pollinated", false)) else "No",
			],
			11,
			IVORY,
			true
		))

	# Progressive Hints Box
	var hints: Array = _view.get("hints_revealed", [])
	var hint_card := _card_box(INK, MUSTARD if not hints.is_empty() else NAVY)
	_right_column.add_child(hint_card)
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 4)
	hint_card.add_child(hv)
	hv.add_child(_label("PROGRESSIVE HINTS (%d/%d)" % [int(_view.get("hint_tier", 0)), int(_view.get("hint_max", 3))], 12, MUSTARD, true))
	if hints.is_empty():
		hv.add_child(_label("Need a nudge? Press Hint below for a progressive clue (never auto-solves).", 11, MUTED, true))
	else:
		for h_idx in range(hints.size()):
			hv.add_child(_label("Hint %d: %s" % [h_idx + 1, String(hints[h_idx])], 12, IVORY, true))

func _refresh_confirm_bar() -> void:
	if _close_confirm_open:
		_confirm_bar.visible = true
		_confirm_label.text = _status_message
		_confirm_yes.text = "Confirm Close"
		_confirm_no.text = "Keep Working (Esc)"
		_confirm_label.add_theme_font_size_override("font_size", _scaled(12))
		_confirm_yes.add_theme_font_size_override("font_size", _scaled(12))
		_confirm_no.add_theme_font_size_override("font_size", _scaled(12))
		return
	if not _confirm_open:
		_confirm_bar.visible = false
		return
	_confirm_bar.visible = true
	_confirm_label.text = "Lock in '%s' with your current workbench selections? Press Space or Confirm Lock In." % _active_target_label()
	_confirm_yes.text = "Confirm Lock In (Space)"
	_confirm_no.text = "Step Back (Esc)"
	_confirm_label.add_theme_font_size_override("font_size", _scaled(12))
	_confirm_yes.add_theme_font_size_override("font_size", _scaled(12))
	_confirm_no.add_theme_font_size_override("font_size", _scaled(12))

func _on_share_clue(puzzle_id: String, clue_id: String) -> void:
	if _route == null:
		return
	var res: Dictionary = _route.p04().share_clue(clue_id) if puzzle_id == "P-04" else _route.p03().share_clue(clue_id)
	_status_ok = bool(res.get("accepted", false))
	_status_message = String(res.get("reason", ""))
	_refresh()

func _on_reset_pressed() -> void:
	if _route == null:
		return
	var puzzle_id := String(_view.get("puzzle_id", "P-03"))
	var res: Dictionary = _route.p04().reset_current_step() if puzzle_id == "P-04" else _route.p03().reset_current_step()
	_dirty_since_open = false
	_confirm_open = false
	_close_confirm_open = false
	_status_ok = true
	_status_message = String(res.get("reason", "Current step reset."))
	_refresh()

func _on_hint_pressed() -> void:
	if _route == null:
		return
	var puzzle_id := String(_view.get("puzzle_id", "P-03"))
	var topic := String(_view.get("hint_topic", "pollination"))
	var res: Dictionary = _route.p04().next_hint(topic) if puzzle_id == "P-04" else _route.p03().next_hint(topic)
	_status_ok = true
	_status_message = String(res.get("reason", ""))
	_refresh()

func _on_preview_pressed() -> void:
	if _route == null:
		return
	_view = _route.puzzle_view(_target_id)
	var preview: Dictionary = _view.get("target_preview", {})
	_status_ok = bool(preview.get("accepted", false))
	_status_message = String(preview.get("reason", ""))
	_refresh()

func _request_commit_stage() -> void:
	if _route == null:
		return
	_view = _route.puzzle_view(_target_id)
	var preview: Dictionary = _view.get("target_preview", {})
	if not bool(preview.get("accepted", false)):
		_status_ok = false
		_status_message = String(preview.get("reason", "Complete the required workbench selection before locking in."))
		_confirm_open = false
		_refresh()
		return
	_close_confirm_open = false
	_confirm_open = true
	_refresh_confirm_bar()

func _on_confirm_yes() -> void:
	if _close_confirm_open:
		close(true)
		return
	_confirm_commit()

func _on_confirm_no() -> void:
	_confirm_open = false
	_close_confirm_open = false
	_refresh_confirm_bar()

func _confirm_commit() -> void:
	if _route == null:
		return
	var puzzle_id := String(_view.get("puzzle_id", "P-03"))
	var action := _active_puzzle_action()
	var payload: Dictionary = (
		_route.p04().payload_for_action(action)
		if puzzle_id == "P-04"
		else _route.p03().payload_for_action(action)
	)
	_confirm_open = false
	_dirty_since_open = false
	var committed_target := _target_id
	commit_requested.emit(committed_target, payload)
	if visible and _route != null:
		_view = _route.puzzle_view("")
		var next_tid := String(_view.get("target_id", ""))
		if next_tid.is_empty() or bool(_route.gate_status().get("ready", false)):
			close(true)
		else:
			_target_id = next_tid
			_refresh()

func _active_target_label() -> String:
	for item in _view.get("scene_targets", []):
		if item is Dictionary and String(item.get("target_id", "")) == _target_id:
			return String(item.get("focus_label", _target_id))
	return _target_id

func _active_puzzle_action() -> String:
	for item in _view.get("scene_targets", []):
		if item is Dictionary and String(item.get("target_id", "")) == _target_id:
			return String(item.get("puzzle_action", ""))
	return ""

func _section_header(text: String) -> Label:
	return _label(text, 13, MUSTARD, true)

func _label(text: String, size: int, color: Color, wrap: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", _scaled(size))
	label.add_theme_color_override("font_color", color)
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _button(text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0.0, MIN_TARGET)
	btn.focus_mode = Control.FOCUS_ALL
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.add_theme_font_size_override("font_size", _scaled(12))
	btn.add_theme_color_override("font_color", IVORY)
	btn.add_theme_stylebox_override("normal", _box(NAVY, MUTED, 1, 8))
	btn.add_theme_stylebox_override("hover", _box(NAVY, CYAN, 2, 8))
	btn.add_theme_stylebox_override("pressed", _box(INK, MUSTARD, 2, 8))
	btn.add_theme_stylebox_override("focus", _box(NAVY, MUSTARD, 2, 8))
	btn.pressed.connect(callback)
	return btn

func _choice_button(text: String, selected: bool, valid_choice: bool, callback: Callable) -> Button:
	var btn := _button(text, callback)
	if selected:
		var border := GREEN if valid_choice else RED
		btn.add_theme_stylebox_override("normal", _box(INK, border, 2, 8))
		btn.add_theme_color_override("font_color", MUSTARD if valid_choice else RED)
	return btn

func _card_box(bg: Color, border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(bg, border, 1, 8))
	return panel

func _box(bg: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 10.0
	box.content_margin_right = 10.0
	box.content_margin_top = 8.0
	box.content_margin_bottom = 8.0
	return box

func _scaled(base_size: int) -> int:
	var factor := 1.5 if bool(_settings.get("large_text", false)) else 1.0
	return int(round(float(base_size) * factor))

func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
