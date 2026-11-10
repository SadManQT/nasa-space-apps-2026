extends PanelContainer
class_name HazardHudPanel

## M3-65: Readable hazards monitor & shelter-run dosimeter HUD (doc 25 §4.2, §6).
## Displays the pre-hazard warning banner, active hazard readouts (moonquake
## securing + pressure taps, cold shadow heater cost & equipment temperature,
## dual-telescope impact flash classifier + shield maintenance, eclipse darkness
## 7/14 battery budget, and solar-storm dosimeter & shelter run).

const Design = preload("res://scripts/ui/ui_design.gd")
const HazardsScript = preload("res://scripts/hazards/lunar_hazards.gd")

signal hazard_selected(hazard_id: String)
signal panel_closed()

var _hazards: RefCounted
var _warning_label: Label
var _cards_grid: GridContainer

func _init() -> void:
	name = "HazardHudPanel"
	custom_minimum_size = Vector2(960, 560)
	add_theme_stylebox_override("panel", Design.glass_style(Design.colour("warning", Color("#F2C230")), Color(0.04, 0.07, 0.13, 0.94), 20))
	_build_ui()

func bind_hazards(hazards: RefCounted) -> void:
	_hazards = hazards
	refresh_view()

func _build_ui() -> void:
	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 12)
	add_child(root_vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root_vbox.add_child(header)
	header.add_child(Design.LineIcon.new("radiation", Design.colour("accent")))
	var title := Design.label("Lunar Environmental Hazards & Dosimeter Readout", "heading", "accent")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_btn := Design.button("Close (Esc)", 38)
	close_btn.name = "CloseHazardHudButton"
	close_btn.pressed.connect(func(): panel_closed.emit())
	header.add_child(close_btn)

	var warn_card := Design.glass_panel(Design.colour("accent"), 12)
	root_vbox.add_child(warn_card)
	_warning_label = Design.label("", "body", "ivory")
	_warning_label.name = "HazardEarlyWarningBanner"
	warn_card.add_child(_warning_label)

	_cards_grid = GridContainer.new()
	_cards_grid.columns = 2
	_cards_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cards_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cards_grid.add_theme_constant_override("h_separation", 12)
	_cards_grid.add_theme_constant_override("v_separation", 12)
	root_vbox.add_child(_cards_grid)

func refresh_view() -> void:
	if _hazards == null:
		_hazards = HazardsScript.new()
	var w: Dictionary = _hazards.issue_warning(_hazards.active_hazard)
	_warning_label.text = "Early Warning: " + String(w.get("warning", ""))

	for c in _cards_grid.get_children():
		c.queue_free()

	# 1. CH03 Moonquake card
	_add_card(
		"Chapter 3 · Shallow Moonquake & Aftershock",
		"Secured equipment: %d of %d · Annex isolated: %s\nPressure taps: Main %d · Garden %d (falling) · Return %d" % [
			_hazards.secured_items.size(),
			_hazards.items_to_secure.size(),
			"Yes" if _hazards.annex_isolated_for_aftershock else "Pending",
			_hazards.main_trunk_pressure,
			_hazards.garden_branch_pressure,
			_hazards.return_trunk_pressure,
		],
		"safe" if _hazards.secured_items.size() == _hazards.items_to_secure.size() else "accent"
	)

	# 2. CH04 Cold shadow card
	_add_card(
		"Chapter %d · Cold Shadow (-210 °C)" % _hazards.cold_shadow_chapter,
		"Ambient: %d °C · Suit heater draw: %sx\nInstrument temp: %s °C (limit %d °C) · Vault carrier sealed <= %d °C" % [
			int(round(_hazards.ambient_temp_c)),
			String.num(_hazards.heater_power_multiplier, 2),
			String.num(_hazards.equipment_temp_c, 1),
			int(round(_hazards.equipment_min_limit_c)),
			int(round(_hazards.carrier_max_cold_limit_c)),
		],
		"safe"
	)

	# 3. CH05 Impact flashes & shield maintenance card
	_add_card(
		"Chapter 5 · Meteoroid Flashes & Shield Care",
		"Two-telescope matches: %d genuine flashes · %d single-camera artifacts rejected\nSolar array dusted: %s · Whipple bumper patched: %s" % [
			_hazards.genuine_flashes_confirmed,
			_hazards.artifacts_rejected,
			"Ready" if _hazards.panel_dust_cleared else "Needs sweep",
			"Ready" if _hazards.whipple_spur_patched else "Needs patch",
		],
		"safe"
	)

	# 4. CH06 Eclipse darkness energy budget card
	_add_card(
		"Chapter 6 · Red Ring Eclipse Darkness Budget",
		"Battery jar: %d units · Protected allocation: 7 units (5 essentials + 1 pump + 1 camera)\nRemaining reserve through totality: 7 units · Decorative floods shed" % [
			_hazards.eclipse_battery_jar,
		],
		"safe"
	)

	# 5. CH07 Solar storm dosimeter & shelter run card
	var storm_mode_str := "Untimed (Story / Family Mode — dose still shown)" if _hazards.is_shelter_run_untimed() else ("Timer: %s s" % String.num(_hazards.shelter_run_time_remaining_s(), 0))
	if _hazards.shelter_preparation_s > _hazards.shelter_run_elapsed_s:
		storm_mode_str += " · Preparation: %s s before exposure" % String.num(_hazards.shelter_preparation_s - _hazards.shelter_run_elapsed_s, 0)
	_add_card(
		"Chapter 7 · Solar Storm Dosimeter & Shelter Run",
		"Dosimeter outside dose: %s units (%s/min) · %s\nSafe Room shield: %d of 6 · 6-step storm dose: %d (limit %d)" % [
			String.num(_hazards.accumulated_outside_dose, 2),
			String.num(_hazards.dosimeter_rate_units_per_min, 1),
			storm_mode_str,
			_hazards.storm_shelter_strength,
			_hazards.storm_shelter_dose(),
			_hazards.storm_exposure_limit,
		],
		"accent"
	)

func _add_card(heading_text: String, body_text: String, edge_token: String) -> void:
	var card := Design.glass_panel(Design.colour(edge_token), 12)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)
	vbox.add_child(Design.label(heading_text, "body", edge_token))
	vbox.add_child(Design.label(body_text, "caption", "ivory"))
	_cards_grid.add_child(card)
