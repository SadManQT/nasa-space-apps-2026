extends VBoxContainer
class_name Chapter1OutcomePanel

## Accessible, pause-safe presentation of a supplied Chapter 1 closure. All
## outgoing actions are requests; this Control owns no campaign arithmetic.
signal retry_requested
signal continue_requested
signal source_requested(source_id: String)
signal navigation_changed(value: Dictionary)

const Model = preload("res://scripts/missions/chapter1_outcome.gd")
const IVORY := Color("#ECEEF0")
const GOLD := Color("#F2C230")
const CYAN := Color("#20B8C9")
const NAVY := Color("#1F2A44")
var _data := {}
var _page := 0
var _shift := 0
var _scale := 1.0
var _answers := {}
var science: RefCounted

## Bind isolated presentation data and optional navigation restored after a
## Data Card visit. No timer, sound or animation is needed to read the result.
func setup(data: Dictionary, scale_factor: float, navigation: Dictionary = {}) -> void:
	_data = data.duplicate(true)
	_scale = scale_factor
	_page = clampi(int(navigation.get("page", 0)), 0, 3)
	_shift = clampi(int(navigation.get("shift", 0)), 0, maxi(0, _data.get("replay", []).size() - 1))
	_answers = navigation.get("answers", {}).duplicate(true)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 12)
	_render()

## Current reading location, retained while viewing the linked science cards.
func navigation() -> Dictionary:
	return {"page": _page, "shift": _shift, "answers": _answers.duplicate(true)}

func _render() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	match _page:
		0: _summary()
		1: _replay()
		2: _debrief()
		3: _questions()
	navigation_changed.emit(navigation())

func _text(value: String, emphasis: bool = false, small: bool = false) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", roundi((16 if small else 21) * _scale))
	label.add_theme_color_override("font_color", GOLD if emphasis else IVORY)
	# The shared shell also scales its children; record the unscaled size once.
	label.set_meta("lla_base_font_size", 16 if small else 21)
	add_child(label)
	return label

func _button(title: String, id: String, action: Callable) -> Button:
	var button := Button.new()
	button.name = id
	button.text = title
	button.accessibility_name = title
	button.custom_minimum_size.y = 48
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", roundi(18 * _scale))
	button.set_meta("lla_base_font_size", 18)
	button.add_theme_color_override("font_color", IVORY)
	button.add_theme_color_override("font_hover_color", IVORY)
	for kind in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = NAVY if kind == "normal" else Color("#243B5A")
		style.set_content_margin_all(12)
		style.set_corner_radius_all(8)
		if kind != "normal":
			style.set_border_width_all(2)
			style.border_color = GOLD
		button.add_theme_stylebox_override(kind, style)
	button.pressed.connect(action)
	add_child(button)
	return button

func _go(page: int, shift: int = 0) -> void:
	_page = page
	_shift = shift
	_render()
	# Start each reading page at the beginning. Focusing its bottom action
	# would otherwise scroll the newly presented explanation out of view.
	var scroll := get_parent().get_parent() as ScrollContainer
	if scroll != null:
		scroll.get_v_scroll_bar().grab_focus()
		scroll.set_deferred("scroll_vertical", 0)

func _summary() -> void:
	_text(String(_data.title), true)
	_text(String(_data.summary))
	var resources: Dictionary = _data.resources
	_text("CREW · %s\nSTATION · %s\nALO · %s" % ["Safe completion" if _data.safe_ending or _data.ending == "ALO_LOST" else "Operations stopped by flight rules", "No blackout" if _data.stars.no_blackout else "Blackout recorded", "Alive · health %s" % str(resources.H) if _data.stars.alo_alive else "Lost within this attempt"], true)
	_text(Model.readings(resources), false, true)
	_text("E Energy · A Air · H Alo health · W Wall water · K Crates\nC Crop condition · R Rations (crew-days) · Z Game exposure", false, true)
	_text("Mastery · Exposure: %s · No blackout: %s · Alo alive: %s" % ["met" if _data.stars.safe_exposure else "not met", "met" if _data.stars.no_blackout else "not met", "met" if _data.stars.alo_alive else "not met"], false, true)
	_button("REVIEW DECISIONS · shift by shift", "ReviewReplay", func(): _go(1))
	_text("Review your forecast and what happened before the science debrief. Assistance preserves the same ending access.", false, true)
	_actions(false)

func _replay() -> void:
	var rows: Array = _data.get("replay", [])
	if rows.is_empty():
		_text("No shift records are available in this checkpoint.")
		_button("READ THE SCIENCE DEBRIEF", "ReadDebrief", func(): _go(2))
		return
	var row: Dictionary = rows[_shift]
	_text("Decision replay · Shift %d of %d recorded" % [int(row.shift), rows.size()], true)
	_text("YOU CHOSE\n" + String(row.choice))
	_text("PREDICT · the forecast before commit", true)
	_text(Model.readings(row.forecast) if not row.forecast.is_empty() else "This older checkpoint did not record a forecast. Only its actual readings are available.", false, true)
	_text("WHAT HAPPENED · committed readings", true)
	_text(Model.readings(row.actual.after), false, true)
	if not row.forecast.is_empty():
		_text("The readings match the forecast." if row.matches else "The readings differed from the captured forecast; review the changed settings and task progress.", false, true)
	_text("WHY\n" + String(row.why))
	var shared: Array[String] = []
	for card in row.cards:
		if card.get("arrived", false):
			shared.append("%s: %s" % [String(card.name), "shared" if card.shared else "arrived, not marked shared"])
	_text("WHO KNEW WHAT\n" + (" · ".join(shared) if not shared.is_empty() else "Card-sharing history was not captured for this older checkpoint."), false, true)
	if _shift > 0:
		_button("PREVIOUS SHIFT", "PreviousShift", func(): _go(1, _shift - 1))
	if _shift + 1 < rows.size():
		_button("NEXT SHIFT", "NextShift", func(): _go(1, _shift + 1))
	else:
		_button("READ THE SCIENCE DEBRIEF", "ReadDebrief", func(): _go(2))
	_button("BACK TO OUTCOME", "BackOutcome", func(): _go(0))

func _debrief() -> void:
	_text("Science debrief", true)
	_text(String(_data.content.boundary), false, true)
	var comparison: Dictionary = _data.get("comparison", {})
	_text("ONE CHANGE TO COMPARE", true)
	if not _data.get("comparison_available", false):
		_text("A safe whole-night comparison needs all seven recorded shifts. This checkpoint has an incomplete decision record; no unplayed choices or task results have been invented.")
	elif comparison.is_empty():
		_text("No single recorded setting change produced a healthier Alo with a safely completed night. Review the timeline and plan at the checkpoint; no unsafe shortcut is suggested.")
	else:
		_text("Shift %d · %s: %s → %s would leave Alo +%d health." % [int(comparison.shift), String(comparison.field).replace("_", " ").capitalize(), str(comparison.from), str(comparison.to), int(comparison.health_gain)])
		_text("COUNTERFACTUAL · one setting changed, using the same simulation\nActual: " + Model.readings(comparison.actual) + "\nAlternative: " + Model.readings(comparison.alternative), false, true)
		_text("Crew shelter and safe completion are preserved. This comparison changes no saved decision or resource.", false, true)
	for tradeoff in _data.content.tradeoffs:
		_text(String(tradeoff.title), true)
		_text("PREDICT · " + String(tradeoff.predict))
		var values: Array[String] = []
		for key in tradeoff.fields:
			values.append("%s %s" % [String(key), str(_data.resources.get(key, "—"))])
		_text("WHAT HAPPENED · final readings\n" + " · ".join(values), false, true)
		_text("WHY · " + String(tradeoff.why))
		for source_id in tradeoff.sources:
			var id := String(source_id)
			var card: Dictionary = science.card(id)
			_button("DATA CARD · " + String(card.get("title", id)), "Source_" + id, func(): source_requested.emit(id))
	_button("OPTIONAL QUESTIONS · no score or ending penalty", "DebriefQuestions", func(): _go(3))
	_button("BACK TO DECISION REPLAY", "BackReplay", func(): _go(1, maxi(0, _data.replay.size() - 1)))
	_actions(true)

func _questions() -> void:
	_text("Try explaining it", true)
	_text("These questions are optional. You can change an answer or continue at any time; your ending is already earned.")
	for question in _data.content.questions:
		_text(String(question.prompt), true)
		var feedback := Label.new()
		feedback.name = "Feedback_" + String(question.id)
		feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		feedback.add_theme_color_override("font_color", CYAN)
		feedback.add_theme_font_size_override("font_size", roundi(18 * _scale))
		feedback.set_meta("lla_base_font_size", 18)
		for index in question.options.size():
			_button(String(question.options[index]), "Answer_%s_%d" % [question.id, index], func():
				_answers[question.id] = index
				feedback.text = ("That matches the evidence. " if index == int(question.correct) else "Compare with the evidence: ") + String(question.explanation)
				navigation_changed.emit(navigation())
			)
		if _answers.has(question.id):
			feedback.text = String(question.explanation)
		add_child(feedback)
	_button("BACK TO SCIENCE DEBRIEF", "BackDebrief", func(): _go(2))
	_actions(true)

func _actions(allow_continue: bool) -> void:
	if _data.safe_ending and allow_continue:
		_button("CONTINUE · finish the chapter's required operations", "OutcomeContinue", func(): continue_requested.emit())
	elif not _data.safe_ending:
		_text("This attempt cannot advance the expedition. Review the cause and restore the checkpoint to try again.", false, true)
	if _data.get("can_retry", false):
		_button("RETRY CHECKPOINT · before shift %d" % int(_data.retry_shift), "OutcomeRetry", func(): retry_requested.emit())
		_text("Retry restores resources, the room and committed actions. Your written plan, shared cards and hints are kept. Earlier damage may require changing an earlier plan in a new expedition.", false, true)
