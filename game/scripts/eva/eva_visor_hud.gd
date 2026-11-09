extends Control
class_name EvaVisorHud

## M3-61: Diegetic EVA visor readout (bottom right suit budget ring with
## return-reserve tick, footing/load sway indicator, and scanner pulse overlay
## with slope band numbers + patterns so colour is never the only signal).
## Centre third of the screen stays clear while moving (doc 25 §2.1, §2.2, §4.2).

var suit: EvaSuit
var _card: PanelContainer
var _ring: RingGauge
var _ox_label: Label
var _pwr_label: Label
var _cool_label: Label
var _band_label: Label
var _status_label: Label
var _scanner_banner: PanelContainer
var _scanner_label: Label

class RingGauge extends Control:
	var oxygen_pct := 100
	var power_pct := 100
	var cooling_pct := 100
	var reserve_pct := 25
	var sway := 0.0
	var band_pattern := "solid"
	var band_number := 1

	func _init() -> void:
		custom_minimum_size = Vector2(92, 92)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var centre := size * 0.5
		var radii := [38.0, 30.0, 22.0]
		var values := [oxygen_pct, power_pct, cooling_pct]
		var tones := [
			UiDesign.colour("ivory"),
			UiDesign.colour("accent"),
			UiDesign.colour("good"),
		]
		for i in 3:
			var r: float = radii[i]
			var pct: int = clampi(values[i], 0, 100)
			draw_arc(centre, r, -PI * 0.5, PI * 1.5, 36, Color(1, 1, 1, 0.14), 4.0, true)
			var tone: Color = tones[i]
			if pct <= reserve_pct:
				tone = UiDesign.colour("caution")
			draw_arc(centre, r, -PI * 0.5, -PI * 0.5 + TAU * (float(pct) / 100.0), 36, tone, 4.0, true)
			# Return-reserve tick mark on each ring
			var tick_angle := -PI * 0.5 + TAU * (float(reserve_pct) / 100.0)
			var dir := Vector2.RIGHT.rotated(tick_angle)
			draw_line(centre + dir * (r - 3.5), centre + dir * (r + 3.5), UiDesign.colour("danger"), 2.0, true)

		# Balance / sway bar at the bottom of the gauge
		var bar_y := size.y - 6.0
		draw_line(Vector2(14, bar_y), Vector2(size.x - 14, bar_y), Color(1, 1, 1, 0.22), 3.0)
		var dot_x := lerpf(size.x * 0.5, size.x - 14.0 if sway >= 0.0 else 14.0, clampf(absf(sway), 0.0, 1.0))
		draw_circle(Vector2(dot_x, bar_y), 4.0, UiDesign.colour("caution" if absf(sway) > 0.6 else "accent"))

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()

func bind_suit(value: EvaSuit) -> void:
	suit = value
	refresh()

func _build() -> void:
	_card = UiDesign.glass_panel(Color.TRANSPARENT, 14)
	_card.name = "EvaVisorCard"
	_card.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_card.offset_left = -360
	_card.offset_top = -176
	_card.offset_right = -24
	_card.offset_bottom = -24
	add_child(_card)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	_card.add_child(row)

	_ring = RingGauge.new()
	row.add_child(_ring)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 4)
	row.add_child(col)

	_ox_label = UiDesign.label("Oxygen 100% · Reserve 25%", "caption", "ivory")
	_pwr_label = UiDesign.label("Suit power 100%", "caption", "ivory")
	_cool_label = UiDesign.label("Cooling 100%", "caption", "ivory")
	_band_label = UiDesign.label("Ground: Flat (1) · solid", "caption", "accent")
	_status_label = UiDesign.label("Suit nominal", "caption", "muted")
	col.add_child(_ox_label)
	col.add_child(_pwr_label)
	col.add_child(_cool_label)
	col.add_child(_band_label)
	col.add_child(_status_label)

	_scanner_banner = UiDesign.glass_panel(UiDesign.colour("accent"), 12)
	_scanner_banner.name = "ScannerPulseBanner"
	_scanner_banner.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_scanner_banner.offset_left = -420
	_scanner_banner.offset_top = 88
	_scanner_banner.offset_right = -24
	_scanner_banner.offset_bottom = 172
	_scanner_banner.visible = false
	add_child(_scanner_banner)

	_scanner_label = UiDesign.label("", "caption", "ivory")
	_scanner_banner.add_child(_scanner_label)

func refresh() -> void:
	if suit == null or _card == null:
		return
	var view := suit.visor_readout()
	_ring.oxygen_pct = int(view.oxygen_pct)
	_ring.power_pct = int(view.power_pct)
	_ring.cooling_pct = int(view.cooling_pct)
	_ring.reserve_pct = int(view.return_reserve_pct)
	_ring.sway = float(view.sway)
	var band: Dictionary = view.band
	_ring.band_pattern = String(band.get("pattern", "solid"))
	_ring.band_number = int(band.get("number", 1))
	_ring.queue_redraw()

	_ox_label.text = "Oxygen %d%% · Reserve %d%%" % [int(view.oxygen_pct), int(view.return_reserve_pct)]
	_pwr_label.text = "Suit power %d%%%s" % [int(view.power_pct), " · Headlamp" if bool(view.headlamp_on) else ""]
	_cool_label.text = "Cooling %d%%%s" % [int(view.cooling_pct), " · Load %s kg" % UiDesign.number(float(view.payload_mass_kg)) if float(view.payload_mass_kg) > 0.0 else ""]
	var tags: Array = view.get("surface_tags", [])
	var tag_suffix := (" · " + ", ".join(tags).replace("_", " ")) if not tags.is_empty() else ""
	_band_label.text = "Ground: %s%s" % [String(band.get("display", band.get("label", "Flat (1)"))), tag_suffix]
	_status_label.text = "%s mode · %s" % [String(view.assist_mode), String(view.status)]

	_scanner_banner.visible = bool(view.scanner_active)
	if _scanner_banner.visible:
		var summary := "Scanner pulse %s m · Band %s" % [
			UiDesign.number(float(view.scanner_radius_m)),
			String(band.get("display", "Flat (1)"))
		]
		if not suit.last_scan_samples.is_empty():
			var counts := {1: 0, 2: 0, 3: 0, 4: 0}
			var hazards: Array = []
			for sample in suit.last_scan_samples:
				var num := int(sample.band.get("number", 1))
				counts[num] = int(counts.get(num, 0)) + 1
				for tag in sample.get("tags", []):
					if not hazards.has(tag):
						hazards.append(String(tag).replace("_", " "))
			summary += "\nFlat(1): %d · Careful(2): %d · Steep(3): %d · No-go(4): %d" % [
				counts[1], counts[2], counts[3], counts[4]
			]
			if not hazards.is_empty():
				summary += "\nContacts: " + ", ".join(hazards)
		_scanner_label.text = summary
