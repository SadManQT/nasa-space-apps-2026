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
		"summary": "Commissioned on Night One; cross-pollinated with Tara; 42 founder pods harvested and archived."
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
		"summary": "Twelve active G1 seedlings growing alongside the 30-seed cold-trap vault reserve."
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

var _tab_bar: HBoxContainer
var _scroll: ScrollContainer
var _body: VBoxContainer
var _feedback_label: Label

func _ready() -> void:
	name = "GreenhousePanel"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiKit.theme()
	_build_ui()
	show_tab(active_tab)

func set_plant_maturity(plant_id: String, is_mature: bool, stage_label: String = "") -> void:
	for p in plants:
		if String(p.get("id", "")) == plant_id:
			p["mature"] = is_mature
			if not stage_label.is_empty():
				p["stage"] = stage_label
	show_tab(active_tab)

func _build_ui() -> void:
	var glass := UiDesign.glass_panel()
	glass.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(glass)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	glass.add_child(stack)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	stack.add_child(header)
	var title := UiDesign.label("Greenhouse Chambers & Lineage Comparison", "title")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close_btn := UiDesign.button("Close (Esc)")
	close_btn.name = "CloseGreenhousePanel"
	close_btn.pressed.connect(func() -> void: panel_closed.emit())
	header.add_child(close_btn)

	stack.add_child(UiDesign.label(date_label + " · Plants are botanical specimens (never faces or eyes).", "caption", "accent"))

	_tab_bar = HBoxContainer.new()
	_tab_bar.name = "GreenhouseTabs"
	_tab_bar.add_theme_constant_override("separation", 8)
	stack.add_child(_tab_bar)
	for spec in [["chambers", "Chambers & Care Actions"], ["comparison", "Lineage & Stage Comparison"]]:
		var tid: String = spec[0]
		var btn := UiDesign.button(spec[1])
		btn.name = "Tab_" + tid
		btn.pressed.connect(func() -> void: show_tab(tid))
		_tab_bar.add_child(btn)

	_feedback_label = UiDesign.label("Select a care action or inspect pod readiness.", "body", "good")
	_feedback_label.name = "GreenhouseFeedback"
	stack.add_child(_feedback_label)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	stack.add_child(_scroll)

	_body = VBoxContainer.new()
	_body.name = "GreenhouseBody"
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 10)
	_scroll.add_child(_body)

func show_tab(tab_id: String) -> void:
	active_tab = tab_id if ["chambers", "comparison"].has(tab_id) else "chambers"
	if _body == null:
		return
	for c in _body.get_children():
		_body.remove_child(c)
		c.queue_free()
	if active_tab == "comparison":
		_render_comparison_tab()
	else:
		_render_chambers_tab()
	UiDesign.apply_type(self, get_viewport_rect().size.y, 1.5 if bool(settings.get("large_text", false)) else 1.0)

func _render_chambers_tab() -> void:
	for p in plants:
		var pid := String(p.get("id", ""))
		var is_archive := bool(p.get("is_archived_founder", false))
		var is_mature := bool(p.get("mature", false))
		var stress := String(p.get("stress_cause", ""))
		var card_border := UiDesign.colour("accent" if is_archive else ("caution" if not stress.is_empty() else "border"))
		var card := UiDesign.glass_panel(card_border)
		card.name = "PlantCard_" + pid
		_body.add_child(card)

		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 6)
		card.add_child(box)

		var badge_prefix := "[MATURE FOUNDER ARCHIVE]  " if is_archive else "[ACTIVE DESCENDANT / CHAMBER]  "
		var heading := UiDesign.label(badge_prefix + String(p.get("name", "")) + " · " + String(p.get("stage", "")), "heading", "accent" if is_archive else "ivory")
		heading.name = "Heading_" + pid
		box.add_child(heading)

		box.add_child(UiDesign.label("Lineage: " + String(p.get("lineage", "")), "body"))
		box.add_child(UiDesign.label(
			"Conditions: %.1f °C · Moisture %d%% · Date: %s" % [
				float(p.get("temperature_c", 22.0)),
				int(p.get("moisture_pct", 65)),
				date_label.split("·")[0].strip_edges()
			],
			"caption",
			"muted"
		))

		if not stress.is_empty():
			var stress_lbl := UiDesign.label("⚠ STRESS CAUSE: " + stress, "body", "caution")
			stress_lbl.name = "Stress_" + pid
			box.add_child(stress_lbl)
		else:
			var nominal_lbl := UiDesign.label("● Nominal turgor and leaf posture (no stress).", "caption", "good")
			nominal_lbl.name = "Stress_" + pid
			box.add_child(nominal_lbl)

		box.add_child(UiDesign.label(String(p.get("summary", "")), "caption", "muted"))

		var actions := HBoxContainer.new()
		actions.add_theme_constant_override("separation", 8)
		box.add_child(actions)

		var mist_btn := UiDesign.button("Mist & Balance Moisture")
		mist_btn.name = "CareMist_" + pid
		mist_btn.pressed.connect(func() -> void:
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
	_body.add_child(UiDesign.label("Mature Alo archive is kept visibly distinct from G1 descendants and the 2034 vault cotton specimen.", "caption", "muted"))

	var grid := GridContainer.new()
	grid.name = "GreenhouseComparisonGrid"
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 8)
	_body.add_child(grid)

	for col_title in ["SPECIMEN", "RECORD KIND", "LINEAGE", "STAGE", "TEMP / MOISTURE"]:
		grid.add_child(UiDesign.label(col_title, "caption", "accent"))

	for p in plants:
		var is_archive := bool(p.get("is_archived_founder", false))
		grid.add_child(UiDesign.label(String(p.get("name", "")), "body", "accent" if is_archive else "ivory"))
		grid.add_child(UiDesign.label("FOUNDER ARCHIVE" if is_archive else "ACTIVE CHAMBER", "caption", "good" if is_archive else "ivory"))
		grid.add_child(UiDesign.label(String(p.get("lineage", "")), "caption"))
		grid.add_child(UiDesign.label(String(p.get("stage", "")), "caption"))
		grid.add_child(UiDesign.label("%.1f °C · %d%%" % [float(p.get("temperature_c", 22.0)), int(p.get("moisture_pct", 65))], "caption", "muted"))
