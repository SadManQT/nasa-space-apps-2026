extends Control
class_name P01Panel

const PREDICTION_PROMPT := "Pick your numbers, then press Try it. Nothing real changes until you press Lock in."
const Chapter1FeedbackScript = preload("res://scripts/feedback/chapter1_feedback.gd")

## Local selections only. The campaign owns forecasts, validation and physical commits.
signal opened(target_id: String)
signal closed(target_id: String)
signal commit_requested(target_id: String, payload: Dictionary)
signal sources_requested

var hint_player: HintPlayer
var _campaign: Chapter1Campaign
var _target := ""
var _view: Dictionary = {}
var _choices: Dictionary = {}
var _prediction: Dictionary = {}
var _preview_context := ""
var _confirming := false
var _leaving := false
var _observed := false
var _notice := ""
var _settings: Dictionary = {}
var _frame: PanelContainer
var _equipment: VBoxContainer
var _footer: HFlowContainer
var _focus := ""
var _return_focus: Control
var _covered := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100
	theme = UiKit.theme()
	$Shade.color = UiDesign.colour("scrim")
	_frame = $Frame
	_frame.add_theme_stylebox_override("panel", UiDesign.glass_style())
	_equipment = %EquipmentInputs
	_footer = %ProbeFooter
	for card in [%ObservedCard, %PredictionCard]:
		card.add_theme_stylebox_override("panel", UiDesign.glass_style())
	for label in [%ProbeTitle, %ObservedHeading, %PredictionHeading]:
		UiDesign.style_label(label, "title" if label == %ProbeTitle else "heading")
	for label in [%ProbeSubtitle, %ProbeObserved, %ProbePrediction, %ProbeExplanation, %ProbePrerequisite, %ProbeNotice]:
		UiDesign.style_label(label, "body", "muted" if label == %ProbeSubtitle else "ivory")
	for label in [%StepDry, %StepWet, %StepCheck]:
		UiDesign.style_label(label, "body")
	get_viewport().size_changed.connect(_render)
	hide()

func open(campaign: Chapter1Campaign, target_id: String) -> bool:
	var value := campaign.p01_view(target_id)
	if not value.get("accepted", false):
		return false
	_return_focus = get_viewport().gui_get_focus_owner()
	_campaign = campaign
	_target = target_id
	_view = value
	_settings = campaign.query().get("accessibility", {})
	_choices = {}
	_prediction = {}
	_preview_context = ""
	_confirming = false
	_leaving = false
	_observed = false
	_notice = _do_this()
	show()
	opened.emit(_target)
	_render()
	return true

func is_open() -> bool:
	return visible

func set_covered(value: bool) -> void:
	_covered = value
	for child in get_children():
		(child as CanvasItem).visible = not value
	if not value:
		_restore_focus.call_deferred()

func selection() -> Dictionary:
	return _choices.duplicate(true)

func choose(field: String, value) -> void:
	if not visible or _observed:
		return
	_choices[field] = value
	_prediction = {}
	_preview_context = ""
	_confirming = false
	_notice = "Changed. Press Try it to see what would happen.\n" + _do_this()
	var notice := find_child("ProbeNotice", true, false) as Label
	if notice != null:
		notice.text = _notice
	var projected := find_child("ProbePrediction", true, false) as Label
	if projected != null:
		projected.text = PREDICTION_PROMPT

func undo() -> void:
	_choices.clear()
	_prediction.clear()
	_preview_context = ""
	_notice = "Cleared. Nothing real has changed."
	_render()

func _payload() -> Dictionary:
	var payload := _choices.duplicate(true)
	payload.erase("confirmed")
	return payload

func preview() -> Dictionary:
	PlaytestLog.event("try", {"puzzle": "P-01", "target": _target})
	if _choices.is_empty() or (_simple_action() and _choices.get("confirmed") != true):
		_prediction = {"accepted": false, "reason": "Pick something first, then press Try it."}
	else:
		_prediction = _campaign.forecast_target(_target, _payload())
	_preview_context = _context() if _prediction.get("accepted", false) else ""
	_notice = "That works. Press Lock in to do it for real." if _prediction.get("accepted", false) else "Try again: " + UiDesign.player_words(String(_prediction.get("reason", "Check your selection.")))
	_focus = "LockIn" if _prediction.get("accepted", false) else "TryIt"
	_render()
	return _prediction.duplicate(true)

func request_commit() -> Dictionary:
	if not visible or _observed or _preview_context.is_empty() or _preview_context != _context():
		_notice = "Press Try it again first. Something changed."
		_render()
		return {"accepted": false, "reason": _notice}
	_confirming = true
	_focus = "ConfirmChoice"
	_render()
	return {"accepted": true}

func confirm_commit() -> Dictionary:
	if not _confirming or not request_commit().accepted:
		return {"accepted": false}
	var payload := _payload()
	var target := _target
	discard()
	commit_requested.emit(target, payload)
	return {"accepted": true}

func cancel_confirm() -> void:
	_confirming = false
	_focus = "LockIn"
	_render()

func request_close() -> void:
	if not _choices.is_empty() and not _observed:
		_leaving = true
		_focus = "KeepChoosing"
		_render()
	else:
		discard()

func discard() -> void:
	if not visible:
		return
	hide()
	_confirming = false
	closed.emit(_target)
	if is_instance_valid(_return_focus) and _return_focus.is_visible_in_tree():
		_return_focus.grab_focus()

func show_result(result: Dictionary) -> void:
	_observed = bool(result.get("accepted", false))
	_confirming = false
	_prediction = {}
	_preview_context = ""
	_view = _campaign.p01_view(_target)
	_notice = "Observed: " + (_action_title() + " completed. " + _explanation() if _observed else UiDesign.player_words(String(result.get("reason", "Move back to the equipment and try again."))))
	_focus = "CloseProbe" if _observed else "TryIt"
	_render()

func teach_first_use() -> void:
	if hint_player != null and not hint_player.has_seen("probe"):
		hint_player.set_settings(_settings)
		hint_player.show_how_to("probe", true)

func reveal_hint() -> void:
	if hint_player == null:
		return
	var lesson := HowToCard.lesson("probe")
	lesson.nudge = "Test the meter before you trust it."
	lesson.relationship = "Use the dry cup and the wet cup. " + String(lesson.get("relationship", ""))
	lesson.example = "Dry must say 0. Wet must say 100. Then water both plants to 50. Anything from 40 to 60 is fine."
	hint_player.set_settings(_settings)
	hint_player.request_hint("p01", lesson)

## Plain step-by-step instruction for this job (kids asked "what do I do?").
## Expedition assist mode keeps the puzzle: it gets the short prompt only.
func _do_this() -> String:
	if String(_settings.get("assist_mode", "Cadet")) == "Expedition":
		return PREDICTION_PROMPT
	var profile: Dictionary = _view.get("profile", {})
	var refs: Dictionary = profile.get("references", {})
	var middle := int((float(profile.get("moisture_min", 40)) + float(profile.get("moisture_max", 60))) / 2.0)
	match String(_view.get("action", "")):
		"set_zero":
			return "Do this: pick Dry soil cup. Set The meter shows to %s and It should say to %s. Press Try it, then Lock in." % [refs.dry.raw, refs.dry.calibrated]
		"set_span":
			return "Do this: pick Wet soil cup. Set The meter shows to %s and It should say to %s. Press Try it, then Lock in." % [refs.wet.raw, refs.wet.calibrated]
		"recheck":
			return "Do this: set Dry cup now says to %s and Wet cup now says to %s. Press Try it, then Lock in." % [refs.dry.calibrated, refs.wet.calibrated]
		"plant_alo":
			return "Do this: pick Alo's box and set 1 seed. Press Try it, then Lock in."
		"plant_tara":
			return "Do this: pick Tara's box and set 1 seed. Press Try it, then Lock in."
		"water_alo", "water_tara":
			return "Do this: set the water to %d. Press Try it, then Lock in." % middle
		"label_alo_external":
			return "Do this: pick Outside test. Press Try it, then Lock in."
		"label_tara_indoor":
			return "Do this: pick Indoor. Press Try it, then Lock in."
	return "Do this: press the Select button. Press Try it, then Lock in."

func _context() -> String:
	var state := _campaign.director.snapshot()
	state.erase("presentation_resume")
	return JSON.stringify([_campaign.route.snapshot(), state, _choices])

func _simple_action() -> bool:
	return _view.get("action", "") in ["scan_packet", "seal_alo", "seal_tara"]

func _action_title() -> String:
	return {"set_zero": "Test in dry soil", "set_span": "Test in wet soil", "recheck": "Test both again", "scan_packet": "Look at the seed packet", "plant_alo": "Plant Alo's seed", "plant_tara": "Plant Tara's seed", "water_alo": "Water Alo", "water_tara": "Water Tara", "label_alo_external": "Label Alo's box", "label_tara_indoor": "Label Tara's box", "seal_alo": "Close Alo's lid", "seal_tara": "Close Tara's lid"}.get(_view.get("action", ""), "Check the equipment")

func _explanation() -> String:
	if _target in ["calibrate_probe", "span_probe", "recheck_probe"]:
		return "A meter can be wrong. Test it in dry soil and wet soil, then you can trust it with the plants."
	return "One seed in each box, the same water and clear labels make it a fair test."

func _render() -> void:
	if not visible or _campaign == null:
		return
	var focused := get_viewport().gui_get_focus_owner()
	if _focus.is_empty() and focused != null and is_ancestor_of(focused):
		_focus = String(focused.name)
	for host in [_equipment, _footer]:
		for child in host.get_children():
			host.remove_child(child)
			child.queue_free()
	%ProbeTitle.text = "Test the water meter" if _target in ["calibrate_probe", "span_probe", "recheck_probe"] else _action_title()
	%ProbeSubtitle.text = _action_title() + " · Try it first. Nothing changes until you lock in."
	%ProbeColumns.columns = 2 if get_viewport_rect().size.x >= 1100 and not _settings.get("large_text", false) else 1
	%ProbeArtwork.visible = _target in ["calibrate_probe", "span_probe", "recheck_probe"]
	%ArtworkCaption.visible = %ProbeArtwork.visible
	%ProbeObserved.text = _readings(_view)
	_render_steps()
	var equipment := _equipment
	if _leaving:
		_label(equipment, "Leave without locking in? Nothing will change.")
		_button(equipment, "Keep choosing", "KeepChoosing", func(): _leaving = false; _render())
		_button(equipment, "Leave without saving", "DiscardChoices", discard)
	elif _confirming:
		_label(equipment, "Do this for real?\n" + _selection_text())
		_button(equipment, "Yes, do it", "ConfirmChoice", confirm_commit)
		_button(equipment, "Go back", "BackToPrediction", cancel_confirm)
	elif _observed:
		_label(equipment, "Done. Press Close and follow the blue marker.")
		var p01_state: Dictionary = _view.get("state", {}) if _view.get("state", null) is Dictionary else {}
		var fb := Chapter1FeedbackScript.action_feedback(_target, p01_state)
		var fb_label := _label(equipment, "What changed: %s\nWhy: %s\nNext step: %s\n%s · %s: \"%s\"" % [
			String(fb.get("consequence", "")),
			String(fb.get("why", "")),
			String(fb.get("next_step", "")),
			String(fb.get("meter_tick", "")),
			String(fb.get("crew_speaker", "Crew")),
			String(fb.get("crew_reaction", "")),
		], "caption")
		fb_label.name = "ProbeActionFeedback"
	else:
		_render_inputs(equipment)
	%ProbePrediction.text = _readings(_prediction.p01) if _prediction.get("accepted", false) and _prediction.has("p01") else PREDICTION_PROMPT
	%ProbeExplanation.text = _explanation()
	var reason := String(_view.get("prerequisite_reason", ""))
	%ProbePrerequisite.text = reason
	%ProbePrerequisite.visible = not reason.is_empty()
	%ProbeNotice.text = _notice
	var footer := _footer
	if not _observed and not _confirming and not _leaving:
		_button(footer, "Start again", "UndoChoices", undo)
		_button(footer, "Try it", "TryIt", preview)
		_button(footer, "Lock in", "LockIn", request_commit)
	_button(footer, "Hint", "ProbeHint", reveal_hint)
	_button(footer, "Data cards", "ProbeSources", func(): sources_requested.emit())
	_button(footer, "Close", "CloseProbe", request_close)
	UiDesign.apply_type(_frame, get_viewport_rect().size.y, 1.5 if _settings.get("large_text", false) else 1.0)
	_restore_focus.call_deferred()

func _render_steps() -> void:
	var calibrating := _target in ["calibrate_probe", "span_probe", "recheck_probe"]
	var active := ["calibrate_probe", "span_probe", "recheck_probe"].find(_target) if calibrating else (2 if _confirming or _observed else (1 if not _prediction.is_empty() else 0))
	var labels := [%StepDry, %StepWet, %StepCheck]
	var words := ["Dry soil", "Wet soil", "Check both"] if calibrating else ["Choose", "Try it", "Confirm"]
	for index in labels.size():
		var label := labels[index] as Label
		label.text = "%d   %s" % [index + 1, words[index]]
		label.add_theme_color_override("font_color", UiDesign.colour("ink" if active == index else "muted"))
		label.add_theme_stylebox_override("normal", UiDesign.glass_style(UiDesign.colour("accent") if active == index else Color.TRANSPARENT, UiDesign.colour("accent") if active == index else UiDesign.colour("navy"), 10))

func _render_inputs(column: VBoxContainer) -> void:
	match String(_view.get("action", "")):
		"set_zero", "set_span":
			_options(column, "reference", [["dry", "Dry soil cup"], ["wet", "Wet soil cup"]])
			_number(column, "raw_reading", "The meter shows", 10)
			_number(column, "calibrated_reading", "It should say", 10)
		"recheck":
			_number(column, "dry_reading", "Dry cup now says", 10)
			_number(column, "wet_reading", "Wet cup now says", 10)
		"plant_alo", "plant_tara":
			_options(column, "cassette", [["alo", "Alo's box"], ["tara", "Tara's box"]])
			_number(column, "seed_count", "How many seeds", 1)
		"label_alo_external", "label_tara_indoor":
			_label(column, "Alo lives in the outside box. Tara lives indoors, so you can compare them.")
			_options(column, "label", [[_view.profile.labels.alo, "Outside test"], [_view.profile.labels.tara, "Indoor"]])
		"water_alo", "water_tara":
			_label(column, "Water from %s to %s out of 100 is safe. Extra water drains away." % [_view.profile.moisture_min, _view.profile.moisture_max])
			_number(column, "moisture", "Water out of 100", 10)
		_:
			_button(column, ("Selected: " if _choices.get("confirmed", false) else "Select: ") + _action_title(), "SelectAction", func(): choose("confirmed", true); _render())

func _options(column: VBoxContainer, field: String, options: Array) -> void:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 8)
	column.add_child(row)
	for option in options:
		var selected: bool = _choices.get(field) == option[0]
		var button := _button(row, ("Selected: " if selected else "") + option[1], "Choose_" + option[0], func(): choose(field, option[0]); _render())
		if selected:
			button.add_theme_stylebox_override("normal", UiDesign.button_style(UiDesign.colour("accent"), true))
			button.add_theme_color_override("font_color", UiDesign.colour("ink"))
			button.add_theme_color_override("font_focus_color", UiDesign.colour("ink"))
	var choices := row.get_children()
	for index in range(choices.size() - 1):
		var current := choices[index] as Button
		var next := choices[index + 1] as Button
		current.focus_neighbor_bottom = current.get_path_to(next)
		next.focus_neighbor_top = next.get_path_to(current)

func _number(column: VBoxContainer, field: String, title: String, step: float) -> void:
	_label(column, title)
	var row := HBoxContainer.new()
	column.add_child(row)
	_button(row, "−", "Minus_" + field, func(): _adjust(field, -step))
	var entry := LineEdit.new()
	entry.name = "Input_" + field
	entry.placeholder_text = "Tap a number below"
	entry.text = ""
	if _choices.has(field):
		entry.text = UiDesign.number(float(_choices[field])) if str(_choices[field]).is_valid_float() else str(_choices[field])
	entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry.custom_minimum_size = Vector2(90, 44)
	entry.add_theme_font_override("font", UiDesign.font("heading"))
	entry.add_theme_font_size_override("font_size", 26)
	entry.accessibility_name = title
	entry.tooltip_text = title + "; tap a number, slide, type, or use minus and plus."
	entry.text_changed.connect(func(text): choose(field, text.to_float() if text.is_valid_float() else text))
	row.add_child(entry)
	_button(row, "+", "Plus_" + field, func(): _adjust(field, step))
	# Kid-friendly picking (M1-129, 13 Nov review: "so difficult to choose"): the few numbers
	# that mean something here are one tap each and say what they are, and a slider shows
	# the number as a position. Typing and minus/plus still work.
	var picks := _quick_picks(field)
	if not picks.is_empty():
		var chips := HFlowContainer.new()
		chips.name = "Picks_" + field
		chips.add_theme_constant_override("h_separation", 8)
		chips.add_theme_constant_override("v_separation", 8)
		column.add_child(chips)
		for pick in picks:
			var value := float(pick[0])
			var chosen := _choices.has(field) and str(_choices[field]).is_valid_float() and is_equal_approx(float(_choices[field]), value)
			var chip := _button(chips, String(pick[1]), "Pick_%s_%s" % [field, UiDesign.number(value)], func() -> void:
				choose(field, value)
				_render())
			chip.tooltip_text = title + ": " + UiDesign.number(value)
			if chosen:
				chip.add_theme_stylebox_override("normal", UiDesign.button_style(UiDesign.colour("accent"), true))
				chip.add_theme_color_override("font_color", UiDesign.colour("ink"))
				chip.add_theme_color_override("font_focus_color", UiDesign.colour("ink"))
	var span := _slider_range(field)
	var slider := HSlider.new()
	slider.name = "Slider_" + field
	slider.min_value = float(span[0])
	slider.max_value = float(span[1])
	slider.step = float(span[2])
	slider.tick_count = int((float(span[1]) - float(span[0])) / float(span[2])) + 1
	slider.ticks_on_borders = true
	slider.custom_minimum_size = Vector2(0, 32)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.focus_mode = Control.FOCUS_ALL
	slider.accessibility_name = title + " slider"
	if _choices.has(field) and str(_choices[field]).is_valid_float():
		slider.value = clampf(float(_choices[field]), slider.min_value, slider.max_value)
	slider.value_changed.connect(func(value: float) -> void:
		choose(field, value)
		entry.text = UiDesign.number(value))
	slider.drag_ended.connect(func(changed: bool) -> void:
		if changed:
			_focus = slider.name
			_render())
	column.add_child(slider)

## The values that mean something for this field, with what they mean: the meter's real
## readings and what a correct meter says, one seed, and the safe watering band.
func _quick_picks(field: String) -> Array:
	var profile: Dictionary = _view.get("profile", {})
	var refs: Dictionary = profile.get("references", {})
	var dry: Dictionary = refs.get("dry", {})
	var wet: Dictionary = refs.get("wet", {})
	match field:
		"raw_reading":
			return [[dry.get("raw", 10), "Dry cup reads %s" % UiDesign.number(float(dry.get("raw", 10)))], [wet.get("raw", 110), "Wet cup reads %s" % UiDesign.number(float(wet.get("raw", 110)))]]
		"calibrated_reading":
			return [[dry.get("calibrated", 0), "Dry should say %s" % UiDesign.number(float(dry.get("calibrated", 0)))], [wet.get("calibrated", 100), "Wet should say %s" % UiDesign.number(float(wet.get("calibrated", 100)))]]
		"dry_reading":
			return [[dry.get("calibrated", 0), "Dry: %s" % UiDesign.number(float(dry.get("calibrated", 0)))], [dry.get("raw", 10), "Not fixed: %s" % UiDesign.number(float(dry.get("raw", 10)))]]
		"wet_reading":
			return [[wet.get("calibrated", 100), "Wet: %s" % UiDesign.number(float(wet.get("calibrated", 100)))], [wet.get("raw", 110), "Not fixed: %s" % UiDesign.number(float(wet.get("raw", 110)))]]
		"seed_count":
			return [[profile.get("seeds_per_cassette", 1), "%s seed" % UiDesign.number(float(profile.get("seeds_per_cassette", 1)))], [2, "2 seeds"]]
		"moisture":
			var low := float(profile.get("moisture_min", 40))
			var high := float(profile.get("moisture_max", 60))
			var middle := roundf((low + high) * 0.5)
			return [[low, "%s · just enough" % UiDesign.number(low)], [middle, "%s · right in the middle" % UiDesign.number(middle)], [high, "%s · plenty" % UiDesign.number(high)]]
	return []

## [min, max, step] for the field's slider.
func _slider_range(field: String) -> Array:
	match field:
		"raw_reading":
			return [0, 120, 10]
		"calibrated_reading", "dry_reading", "wet_reading":
			return [0, 100, 10]
		"seed_count":
			return [0, 3, 1]
		"moisture":
			return [0, 100, 5]
	return [0, 100, 10]

func _adjust(field: String, amount: float) -> void:
	var value = _choices.get(field)
	choose(field, float(value) + amount if value is float or value is int else 0.0)
	_render()

func _readings(view: Dictionary) -> String:
	var state: Dictionary = view.get("state", {})
	var profile: Dictionary = view.get("profile", _view.profile)
	var complete: Dictionary = view.get("completion", {})
	# Only the facts this step needs (less text on screen); the action decides which.
	var action := String(view.get("action", _view.get("action", "")))
	var lines: Array[String] = []
	if action in ["set_zero", "set_span", "recheck"] or _target in ["calibrate_probe", "span_probe", "recheck_probe"]:
		lines.append("In dry soil the meter shows %s. Dry should say %s.\nIn wet soil the meter shows %s. Wet should say %s." % [profile.references.dry.raw, profile.references.dry.calibrated, profile.references.wet.raw, profile.references.wet.calibrated])
		lines.append("Meter: " + ("tested twice, ready" if state.get("probe_rechecked", false) else ("wet test done" if state.get("probe_spanned", false) else ("dry test done" if state.get("probe_zeroed", false) else "not tested yet"))))
	elif action == "scan_packet":
		lines.append("Seed packet: " + ("looked at" if state.get("packet_scanned", false) else "not looked at yet"))
	else:
		lines.append("Alo: %s seed · water %s of 100 · label: %s · lid %s" % [state.get("cassette_alo_seed_count", 0), state.get("moisture_alo", 0), _label_text(String(state.get("alo_label", ""))), "closed" if state.get("alo_sealed", false) else "open"])
		lines.append("Tara: %s seed · water %s of 100 · label: %s · lid %s" % [state.get("cassette_tara_seed_count", 0), state.get("moisture_tara", 0), _label_text(String(state.get("tara_label", ""))), "closed" if state.get("tara_sealed", false) else "open"])
		lines.append("Both plants ready: " + ("yes" if complete.get("complete", false) else "not yet"))
	return "\n".join(lines)

func _label_text(value: String) -> String:
	return {"EXTERNAL_TEST": "Outside test", "INDOOR_REFERENCE": "Indoor"}.get(value, "no label yet")

func _selection_text() -> String:
	var lines: Array[String] = []
	for field in _choices:
		if field != "confirmed":
			lines.append(field.replace("_", " ").capitalize() + ": " + str(_choices[field]))
	return "\n".join(lines) if not lines.is_empty() else _action_title()

func _label(parent: Node, text: String, token: String = "body") -> Label:
	var label := UiDesign.label(text, token)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, id: String, action: Callable) -> Button:
	var button := UiDesign.button(text)
	button.name = id
	if id in ["TryIt", "ConfirmChoice"]:
		button.add_theme_stylebox_override("normal", UiDesign.button_style(UiDesign.colour("accent"), true))
		button.add_theme_color_override("font_color", UiDesign.colour("ink"))
		button.add_theme_color_override("font_focus_color", UiDesign.colour("ink"))
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _restore_focus() -> void:
	if not visible or _covered or (hint_player != null and hint_player.is_open()):
		return
	var target := find_child(_focus, true, false) as Control if not _focus.is_empty() else null
	if target == null and _focus.is_empty():
		var current := get_viewport().gui_get_focus_owner()
		if current != null and is_ancestor_of(current) and current.is_visible_in_tree():
			target = current
	if target == null:
		target = find_child("Choose_dry", true, false) as Control
	if target == null:
		target = find_child("TryIt", true, false) as Control
	if target == null:
		target = find_child("CloseProbe", true, false) as Control
	if target != null:
		target.grab_focus()
		var scroll_host := find_child("ProbeScroll", true, false) as ScrollContainer
		if scroll_host != null:
			# The chip rows and sliders change the column's height after this frame, so the
			# follow-focus scroll made now lands in the wrong place (the cup buttons ended up
			# hidden above the view). A fresh panel starts at the top; the focused control is
			# brought into view again once the layout is final.
			if String(target.name).begins_with("Choose_"):
				scroll_host.scroll_vertical = 0
			(func() -> void:
				if is_instance_valid(target) and is_instance_valid(scroll_host) and target.is_visible_in_tree():
					scroll_host.ensure_control_visible(target)).call_deferred()
	_focus = ""
	if bool(_prediction.get("accepted", false)) and not _confirming and not _leaving:
		var scroll := find_child("ProbeScroll", true, false) as ScrollContainer
		var projected := find_child("ProbePrediction", true, false) as Control
		if scroll != null and projected != null:
			scroll.ensure_control_visible(projected)

func _input(event: InputEvent) -> void:
	if not visible or _covered or (hint_player != null and hint_player.is_open()):
		return
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A:
		var focused := get_viewport().gui_get_focus_owner()
		if focused is Button and is_ancestor_of(focused) and not focused.disabled:
			focused.pressed.emit()
			get_viewport().set_input_as_handled()
		return
	var back: bool = (event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE) or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B)
	var confirm: bool = event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_Y
	if back:
		if _leaving:
			_leaving = false
			_render()
		elif _confirming:
			cancel_confirm()
		else:
			request_close()
	elif confirm:
		if _confirming:
			confirm_commit()
		else:
			request_commit()
	if back or confirm:
		get_viewport().set_input_as_handled()
