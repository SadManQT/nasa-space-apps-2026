extends Control
class_name CadetRecordPanel

## M3-64, M3-4U, M3-6U, M3-8U: Cadet Record, Skills (5 skills × 3 ranks + crew
## lines), Gear Loadout (with weight limit), Chapter Upgrade Choice screen
## (before → after preview, mutually exclusive A/B), and Safe Room Bunk Rest
## summary in the doc 25 §2 dark-glass design system.

signal closed
signal upgrade_chosen(chapter: int, option: String)
signal rest_requested

var progression: CadetProgression
var active_tab: String = "skills"
var upgrade_chapter: int = 3

var _backdrop: ColorRect
var _panel: PanelContainer
var _title_label: Label
var _sub_label: Label
var _tabs_row: HBoxContainer
var _body: VBoxContainer
var _status_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()

func bind_progression(value: CadetProgression) -> void:
	progression = value
	refresh()

func open_tab(tab: String = "skills", chapter_for_upgrade: int = 3) -> void:
	active_tab = tab
	upgrade_chapter = chapter_for_upgrade
	visible = true
	refresh()

func _build() -> void:
	_backdrop = ColorRect.new()
	_backdrop.color = Color(0.02, 0.03, 0.06, 0.78)
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_backdrop)

	_panel = UiDesign.glass_panel(Color.TRANSPARENT, 24)
	_panel.name = "CadetRecordGlass"
	_panel.custom_minimum_size = Vector2(960, 580)
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -480
	_panel.offset_top = -290
	_panel.offset_right = 480
	_panel.offset_bottom = 290
	add_child(_panel)

	var root_col := VBoxContainer.new()
	root_col.add_theme_constant_override("separation", 12)
	_panel.add_child(root_col)

	var header := HBoxContainer.new()
	root_col.add_child(header)

	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titles)

	_title_label = UiDesign.label("Cadet Record & Loadout", "title", "ivory")
	_sub_label = UiDesign.label("Training grades, skills, suit gear loadout and Safe Room rest.", "caption", "muted")
	titles.add_child(_title_label)
	titles.add_child(_sub_label)

	var close_btn := UiDesign.button("Close (Esc)", 40)
	close_btn.name = "CloseCadetRecord"
	close_btn.pressed.connect(func() -> void:
		hide()
		closed.emit())
	header.add_child(close_btn)

	_tabs_row = HBoxContainer.new()
	_tabs_row.add_theme_constant_override("separation", 8)
	root_col.add_child(_tabs_row)

	for item in [
		{"id": "skills", "label": "Cadet Skills"},
		{"id": "loadout", "label": "Gear Loadout"},
		{"id": "reports", "label": "Report Cards"},
		{"id": "upgrades", "label": "Chapter Upgrades"},
		{"id": "rest", "label": "Safe Room Bunk"},
	]:
		var t_id := String(item.id)
		var btn := UiDesign.button(String(item.label), 38)
		btn.name = "Tab_" + t_id
		btn.pressed.connect(func() -> void:
			active_tab = t_id
			refresh())
		_tabs_row.add_child(btn)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_col.add_child(scroll)

	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 10)
	scroll.add_child(_body)

	_status_label = UiDesign.label("", "caption", "accent")
	root_col.add_child(_status_label)

func refresh() -> void:
	if _body == null:
		return
	for child in _body.get_children():
		child.free()
	if progression == null:
		progression = CadetProgression.new()

	match active_tab:
		"skills":
			_render_skills()
		"loadout":
			_render_loadout()
		"reports":
			_render_reports()
		"upgrades":
			_render_upgrades()
		"rest":
			_render_rest()
	UiDesign.apply_type(self, get_viewport_rect().size.y if is_inside_tree() else 720.0, 1.0)

func _render_skills() -> void:
	_title_label.text = "Cadet Skills"
	_sub_label.text = "Five field skills earned by doing sorties and station jobs (three ranks each)."
	for info in progression.all_skills_info():
		var card := UiDesign.glass_panel(Color.TRANSPARENT, 12)
		_body.add_child(card)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 4)
		card.add_child(col)
		var top := HBoxContainer.new()
		col.add_child(top)
		var name_lbl := UiDesign.label("%s · Rank %d of %d (%d pts)" % [
			String(info.label), int(info.rank), int(info.max_rank), int(info.points)
		], "heading", "accent" if int(info.rank) > 0 else "ivory")
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(name_lbl)
		var teacher_lbl := UiDesign.label("Mentor: %s" % String(info.teacher), "caption", "muted")
		top.add_child(teacher_lbl)
		col.add_child(UiDesign.label(String(info.benefit), "body", "ivory"))
		col.add_child(UiDesign.label(String(info.crew_line), "caption", "muted"))

func _render_loadout() -> void:
	_title_label.text = "Suit & Tool Loadout"
	var mass := progression.equipped_mass_kg()
	var max_mass := CadetProgression.max_gear_mass_kg()
	_sub_label.text = "Equipped: %d of %d slots · Weight: %s of %s kg limit." % [
		progression.equipped_gear.size(), CadetProgression.max_gear_slots(),
		UiDesign.number(mass), UiDesign.number(max_mass)
	]
	var earned := progression.available_gear()
	if earned.is_empty():
		_body.add_child(UiDesign.label("Complete a chapter upgrade choice to unlock equippable gear.", "body", "muted"))
		return
	for item in earned:
		var card := UiDesign.glass_panel(Color.TRANSPARENT, 12)
		_body.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(col)
		col.add_child(UiDesign.label("%s · %s kg (%s slot)" % [
			String(item.label), UiDesign.number(float(item.mass_kg)), String(item.slot)
		], "heading", "accent" if bool(item.equipped) else "ivory"))
		col.add_child(UiDesign.label(String(item.benefit), "body", "ivory"))
		var gear_id := String(item.id)
		var is_eq := bool(item.equipped)
		var btn := UiDesign.button("Unequip" if is_eq else "Equip", 38)
		btn.pressed.connect(func() -> void:
			var res := progression.unequip_gear(gear_id) if is_eq else progression.equip_gear(gear_id)
			_status_label.text = String(res.get("reason", ""))
			refresh())
		row.add_child(btn)

func _render_reports() -> void:
	_title_label.text = "Sortie & Job Report Cards"
	_sub_label.text = "Training feedback on time, payload condition, care, science and reserve kept (never locks story)."
	if progression.report_cards.is_empty():
		_body.add_child(UiDesign.label("No sorties or station jobs logged yet.", "body", "muted"))
		return
	for card_data in progression.report_cards:
		var card := UiDesign.glass_panel(Color.TRANSPARENT, 12)
		_body.add_child(card)
		var col := VBoxContainer.new()
		card.add_child(col)
		col.add_child(UiDesign.label("%s · Grade: %s (%s%%)" % [
			String(card_data.title), String(card_data.grade), UiDesign.number(float(card_data.average))
		], "heading", "accent"))
		col.add_child(UiDesign.label("Time %d%% · Payload condition %d%% · Care %d%% · Science %d%% · Reserve kept %d%%" % [
			int(card_data.time_score), int(card_data.condition_score), int(card_data.care_score),
			int(card_data.science_score), int(card_data.reserve_score)
		], "body", "ivory"))
		col.add_child(UiDesign.label(String(card_data.note), "caption", "muted"))

func _render_upgrades() -> void:
	var pair: Dictionary = CadetProgression.UPGRADE_PAIRS.get(upgrade_chapter, CadetProgression.UPGRADE_PAIRS[3])
	_title_label.text = String(pair.get("title", "Chapter Upgrade Choice"))
	_sub_label.text = String(pair.get("story_bridge", "Choose one mutually exclusive station upgrade."))

	var ch_row := HBoxContainer.new()
	ch_row.add_theme_constant_override("separation", 6)
	_body.add_child(ch_row)
	for ch in range(1, 8):
		var ch_btn := UiDesign.button("After Ch %d" % ch, 34)
		ch_btn.pressed.connect(func() -> void:
			upgrade_chapter = ch
			refresh())
		ch_row.add_child(ch_btn)

	var current_choice := String(progression.unlocked_upgrades.get(str(upgrade_chapter), ""))
	for opt_key in ["A", "B"]:
		var opt: Dictionary = pair[opt_key]
		var chosen: bool = current_choice == opt_key
		var card := UiDesign.glass_panel(UiDesign.colour("accent") if chosen else Color.TRANSPARENT, 14)
		_body.add_child(card)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 6)
		card.add_child(col)
		col.add_child(UiDesign.label("Option %s · %s%s" % [
			opt_key, String(opt.label), " (Selected)" if chosen else ""
		], "heading", "accent" if chosen else "ivory"))
		col.add_child(UiDesign.label(String(opt.summary), "body", "ivory"))
		col.add_child(UiDesign.label("Before → After: %s  →  %s" % [String(opt.before), String(opt.after)], "caption", "muted"))
		var select_btn := UiDesign.button("Locked in" if chosen else "Choose Option " + opt_key, 40)
		select_btn.name = "ChooseOption_" + opt_key
		select_btn.disabled = not current_choice.is_empty()
		select_btn.pressed.connect(func() -> void:
			var res := progression.choose_upgrade(upgrade_chapter, opt_key)
			_status_label.text = String(res.get("summary", res.get("reason", "")))
			if bool(res.get("accepted", false)):
				upgrade_chosen.emit(upgrade_chapter, opt_key)
			refresh())
		col.add_child(select_btn)

func _render_rest() -> void:
	_title_label.text = "Safe Room Bunk (LOC-04)"
	_sub_label.text = "Rest at the Safe Room bunks to save your checkpoint, check messages, review Alo and Tara photos, and inspect your cadet record."
	var card := UiDesign.glass_panel(Color.TRANSPARENT, 16)
	_body.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	card.add_child(col)
	col.add_child(UiDesign.label("Rest sessions logged: %d" % progression.rest_count, "heading", "accent"))
	col.add_child(UiDesign.label("• Save station checkpoint\n• Review crew Messages (M)\n• View dated Alo & Tara care-round photos\n• Review Cadet Skills & Report Cards", "body", "ivory"))
	var rest_btn := UiDesign.button("Rest & Save at Safe Room Bunk", 44)
	rest_btn.name = "RestAtBunkButton"
	rest_btn.pressed.connect(func() -> void:
		var res := progression.rest_at_bunk()
		_status_label.text = String(res.get("summary", ""))
		rest_requested.emit()
		refresh())
	col.add_child(rest_btn)
