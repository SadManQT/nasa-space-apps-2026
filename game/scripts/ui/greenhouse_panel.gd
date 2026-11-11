extends Control
class_name GreenhousePanel

## M3-90 (UI_12_GREENHOUSE.md): Greenhouse screen/component connected to the
## shared campaign.
## Exact contract:
## - Layout/content: Plant name/lineage/stage, date, temperature/moisture, care
##   actions and comparison tab.
## - Behaviour/feedback: Stress icon includes cause; mature Alo archive visibly
##   distinct from descendants.
## - Exit/edge case: Harvest disabled until mature; shows "Pods are not ready".

signal panel_closed
signal care_action_emitted(plant_id: String, action_id: String)
signal harvest_requested(plant_id: String)

var _campaign
var active_tab := "chambers"
var date_label := "2046-04-18 · Aurora Greenhouse Dome (LOC-02)"
var settings: Dictionary = {
	"captions": true,
	"large_text": false,
	"timer_free": true,
	"reduced_motion": false,
}

var plants: Array = [
	{
		"id": "alo",
		"name": "Alo",
		"lineage": "Founder Generation G0 · Brassica rapa (Chamber One)",
		"stage": "Mature Pods (Archived Founder)",
		"mature": true,
		"is_archived_founder": true,
		"temperature_c": 22.0,
		"moisture_pct": 68,
		"stress_cause": "",
		"summary": "Commissioned on Night One; cross-pollinated with Tara; 42 seeds harvested: 12 planted and 30 held in the founder reserve."
	},
	{
		"id": "tara",
		"name": "Tara",
		"lineage": "Founder Partner G0 · Brassica rapa (Chamber Two)",
		"stage": "Flowering",
		"mature": false,
		"is_archived_founder": false,
		"temperature_c": 21.8,
		"moisture_pct": 64,
		"stress_cause": "",
		"summary": "Opened during Commissioning Night; pollen donor and recipient for the G1 seed line."
	},
	{
		"id": "g1_descendants",
		"name": "Alo × Tara Descendants (Tray B)",
		"lineage": "Generation G1 · 12 Active Seeds from Alo × Tara",
		"stage": "Budding",
		"mature": false,
		"is_archived_founder": false,
		"temperature_c": 18.4,
		"moisture_pct": 52,
		"stress_cause": "Cool night air (18.4 °C) and low root moisture (52%) — warm chamber to 22 °C and mist roots",
		"summary": "Twelve active G1 seedlings; the 30-seed founder reserve stays sealed."
	},
	{
		"id": "cotton_2034",
		"name": "2034 Vault Cotton",
		"lineage": "Gossypium hirsutum · Expedition Zero Cold-Trap Packet",
		"stage": "First Flower Bud",
		"mature": false,
		"is_archived_founder": false,
		"temperature_c": 23.0,
		"moisture_pct": 70,
		"stress_cause": "",
		"summary": "Recovered from the −183 °C vault shelf and warmed to +18 °C before planting in Aurora's dome."
	}
]

var _tab_bar: HFlowContainer
var _scroll: ScrollContainer
var _body: VBoxContainer
var _feedback_label: Label
var _shell: Control

func _ready() -> void:
	name = "GreenhousePanel"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiKit.theme()
	_build_ui()
	show_tab(active_tab)
	get_viewport().size_changed.connect(func(): show_tab(active_tab))

func bind_campaign(campaign: Node) -> void:
	_campaign = campaign
	var query: Dictionary = campaign.call("query")
	settings = query.get("accessibility", {}).duplicate(true)
	date_label = String(query.get("scenario_datetime", ""))
	plants = []
	for specimen in query.get("plants", []):
		var id := String(specimen.get("individual_id", ""))
		var stage := String(specimen.get("stage", "seed"))
		var stress: Dictionary = specimen.get("stress", {})
		var causes: Array[String] = []
		for cause in stress:
			if int(stress[cause]) > 0:
				causes.append(String(cause).capitalize() + ": " + str(stress[cause]))
		plants.append({"id": id, "name": {"ALO-01": "Alo", "TARA-01": "Tara", "COTTON-01": "Cotton"}.get(id, id),
			"lineage": String(specimen.get("lineage_id", "")).trim_prefix("LINEAGE-").replace("-", " x "),
			"stage": stage.replace("_", " ").capitalize(), "mature": stage == "mature_dry" and not bool(specimen.get("harvested", false)),
			"is_archived_founder": stage in ["archived_petal", "archived_nameplate"], "alive": specimen.get("alive", false),
			"stress_cause": "; ".join(causes), "conditions": "Dated plant record - Instrument temperature/moisture readings are not recorded here.",
			"summary": "Planted: %s - Last care: %s" % [specimen.get("planted_at", ""), specimen.get("last_care_at", "Not yet recorded")]})
	show_tab(active_tab)

func _submit(verb: String, plant_id: String, extra: Dictionary = {}) -> void:
	var command: Dictionary = _campaign.hud.panels.command_for(verb, plant_id, extra.merged({"individual_id": plant_id}, true))
	var result: Dictionary = _campaign.handle_ui_command(command)
	bind_campaign(_campaign)
	_feedback_label.text = String(result.get("reason", "Care recorded." if result.get("accepted", false) else "This care action is unavailable."))

func set_plant_maturity(plant_id: String, is_mature: bool, stage_label: String = "") -> void:
	for p in plants:
		if String(p.get("id", "")) == plant_id:
			p["mature"] = is_mature
			if not stage_label.is_empty():
				p["stage"] = stage_label
	show_tab(active_tab)

func _build_ui() -> void:
	_shell = self
	# Script constructors used by older HUDs share the same authored scene.
	if not has_node("Frame"):
		_shell = load("res://scenes/ui/greenhouse_panel.tscn").instantiate()
		_shell.set_script(null)
		add_child(_shell)
	var frame := _shell.get_node("Frame") as PanelContainer
	frame.add_theme_stylebox_override("panel", UiDesign.glass_style())
	_tab_bar = _shell.get_node("%GreenhouseTabs")
	_scroll = _shell.get_node("%GreenhouseScroll")
	_body = _shell.get_node("%GreenhouseBody")
	_feedback_label = _shell.get_node("%GreenhouseFeedback")
	UiDesign.style_label(_shell.get_node("%GardenTitle"), "title")
	UiDesign.style_label(_shell.get_node("%GardenSubtitle"), "body", "muted")
	UiDesign.style_label(_shell.get_node("%GardenDate"), "caption", "muted")
	UiDesign.style_label(_feedback_label, "body", "good")
	(_shell.get_node("%CloseGreenhousePanel") as Button).pressed.connect(func() -> void: panel_closed.emit())
	for tid in ["chambers", "comparison"]:
		var tab_id: String = tid
		(_shell.get_node("%Tab_" + tid) as Button).pressed.connect(func() -> void: show_tab(tab_id))

func show_tab(tab_id: String) -> void:
	active_tab = tab_id if ["chambers", "comparison"].has(tab_id) else "chambers"
	if _body == null:
		return
	var focused := get_viewport().gui_get_focus_owner()
	var focus_name := String(focused.name) if focused != null and is_ancestor_of(focused) else ""
	(_shell.get_node("%GardenDate") as Label).text = date_label
	for tid in ["chambers", "comparison"]:
		var button := _shell.get_node("%Tab_" + tid) as Button
		button.add_theme_stylebox_override("normal", UiDesign.button_style(UiDesign.colour("accent" if tid == active_tab else "navy"), tid == active_tab))
		button.add_theme_color_override("font_color", UiDesign.colour("ink" if tid == active_tab else "ivory"))
		button.add_theme_color_override("font_focus_color", UiDesign.colour("ink" if tid == active_tab else "ivory"))
	for c in _body.get_children():
		_body.remove_child(c)
		c.queue_free()
	if active_tab == "comparison":
		_render_comparison_tab()
	else:
		_render_chambers_tab()
	UiDesign.apply_type(self, get_viewport_rect().size.y, 1.5 if bool(settings.get("large_text", false)) else 1.0)
	var target := find_child(focus_name, true, false) as Control if not focus_name.is_empty() else null
	if target != null:
		target.grab_focus.call_deferred()

func _render_chambers_tab() -> void:
	var cards := GridContainer.new()
	cards.columns = 2 if get_viewport_rect().size.x >= 1100 and not bool(settings.get("large_text", false)) else 1
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override("h_separation", 20)
	cards.add_theme_constant_override("v_separation", 20)
	_body.add_child(cards)
	for p in plants:
		var pid := String(p.get("id", ""))
		var is_archive := bool(p.get("is_archived_founder", false))
		var is_mature := bool(p.get("mature", false))
		var stress := String(p.get("stress_cause", ""))
		var card_border := UiDesign.colour("accent" if is_archive else ("caution" if not stress.is_empty() else "border"))
		var card := UiDesign.glass_panel(card_border)
		card.name = "PlantCard_" + pid
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cards.add_child(card)

		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 12)
		card.add_child(box)

		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 12)
		box.add_child(head)
		head.add_child(UiKit.icon("plant", "accent" if is_archive else "mei", 44))
		var badge_prefix := "[MATURE FOUNDER ARCHIVE]  " if is_archive else ""
		var heading := UiDesign.label(badge_prefix + String(p.get("name", "")), "heading", "accent" if is_archive else "ivory")
		heading.name = "Heading_" + pid
		heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(heading)
		box.add_child(UiDesign.label(String(p.get("stage", "")), "heading"))

		box.add_child(UiDesign.label("Lineage: " + String(p.get("lineage", "")), "body"))
		var conditions := String(p.get("conditions", ""))
		if conditions.is_empty():
			conditions = "Conditions: %.1f C - Moisture %d%% - Date: %s" % [float(p.get("temperature_c", 22.0)), int(p.get("moisture_pct", 65)), date_label]
		box.add_child(UiDesign.label(conditions, "caption", "muted"))

		if not stress.is_empty():
			var stress_lbl := UiDesign.label("⚠ STRESS CAUSE: " + stress, "body", "caution")
			stress_lbl.name = "Stress_" + pid
			box.add_child(stress_lbl)
		else:
			var nominal_lbl := UiDesign.label("● Nominal turgor and leaf posture (no stress).", "caption", "good")
			nominal_lbl.name = "Stress_" + pid
			box.add_child(nominal_lbl)

		box.add_child(UiDesign.label(String(p.get("summary", "")), "caption", "muted"))

		var actions := HFlowContainer.new()
		actions.add_theme_constant_override("h_separation", 8)
		actions.add_theme_constant_override("v_separation", 8)
		box.add_child(actions)

		var mist_btn := UiDesign.button("Record Water Care" if _campaign != null else "Mist & Balance Moisture")
		mist_btn.disabled = _campaign != null and not bool(p.get("alive", false))
		mist_btn.name = "CareMist_" + pid
		mist_btn.add_theme_stylebox_override("normal", UiDesign.button_style(UiDesign.colour("accent"), true))
		mist_btn.add_theme_color_override("font_color", UiDesign.colour("ink"))
		mist_btn.add_theme_color_override("font_focus_color", UiDesign.colour("ink"))
		mist_btn.pressed.connect(func() -> void:
			if _campaign != null:
				_submit("plant_care", pid, {"care_id": "water"})
				return
			p["moisture_pct"] = 66
			p["temperature_c"] = 22.0
			p["stress_cause"] = ""
			_feedback_label.text = "%s cared for: chamber set to 22.0 °C and 66%% root moisture." % String(p.get("name", ""))
			care_action_emitted.emit(pid, "mist_and_warm")
			show_tab("chambers")
		)
		actions.add_child(mist_btn)

		var harvest_btn := UiDesign.button("Harvest Mature Pods" if is_mature else "Harvest (Pods are not ready)")
		harvest_btn.name = "Harvest_" + pid
		harvest_btn.disabled = not is_mature
		harvest_btn.pressed.connect(func() -> void:
			if is_mature:
				if _campaign != null:
					_submit("harvest_plant", pid)
					return
				_feedback_label.text = "Harvested mature pods from %s." % String(p.get("name", ""))
				harvest_requested.emit(pid)
		)
		actions.add_child(harvest_btn)

		var gate_note := UiDesign.label(
			"Ready for seed harvest." if is_mature else "Pods are not ready — harvest stays disabled until pods mature.",
			"caption",
			"good" if is_mature else "caution"
		)
		gate_note.name = "HarvestReason_" + pid
		box.add_child(gate_note)

func _render_comparison_tab() -> void:
	_body.add_child(UiDesign.label("Founder Archive vs Descendant Lineages", "heading"))
	_body.add_child(UiDesign.label("Compare the specimens recorded at this point in the expedition." if _campaign != null else "Mature Alo archive is kept visibly distinct from G1 descendants and the 2034 vault cotton specimen.", "caption", "muted"))

	var grid := GridContainer.new()
	grid.name = "GreenhouseComparisonGrid"
	grid.columns = 2 if get_viewport_rect().size.x >= 1100 and not bool(settings.get("large_text", false)) else 1
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 8)
	_body.add_child(grid)

	for p in plants:
		var is_archive := bool(p.get("is_archived_founder", false))
		var card := UiDesign.glass_panel(UiDesign.colour("accent") if is_archive else Color.TRANSPARENT)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(card)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 10)
		card.add_child(column)
		column.add_child(UiDesign.label(String(p.get("name", "")), "heading", "accent" if is_archive else "ivory"))
		column.add_child(UiDesign.label("FOUNDER ARCHIVE" if is_archive else "ACTIVE CHAMBER", "caption", "good" if is_archive else "ivory"))
		column.add_child(UiDesign.label("Lineage: " + String(p.get("lineage", "")), "body"))
		column.add_child(UiDesign.label("Stage: " + String(p.get("stage", "")), "body"))
		column.add_child(UiDesign.label("No instrument record" if p.has("conditions") else "%.1f C - %d%%" % [float(p.get("temperature_c", 22.0)), int(p.get("moisture_pct", 65))], "caption", "muted"))

func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_cancel") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B)) and not event.is_echo():
		panel_closed.emit()
		get_viewport().set_input_as_handled()
