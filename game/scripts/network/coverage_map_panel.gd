extends PanelContainer
class_name CoverageMapPanel

## M3-62: Coverage map UI showing placed survey markers (including Chapter 4
## beacons returning on the Chapter 8 map), fixed lines, path lights, relay
## repeaters, active line-of-sight hops, unlocked message notifications, and
## P-16 dual-link finale voice status. Styled with UiDesign (doc 25 §2.1, §4.4).

const Design = preload("res://scripts/ui/ui_design.gd")
const NetworkScript = preload("res://scripts/network/lunar_network.gd")

signal panel_closed()
signal hop_toggled(hop_id: String)

var _network: RefCounted
var _canvas: Control
var _summary_label: Label
var _voice_label: Label
var _beacons_list: VBoxContainer
var _hops_list: VBoxContainer

func _init() -> void:
	name = "CoverageMapPanel"
	custom_minimum_size = Vector2(960, 580)
	add_theme_stylebox_override("panel", Design.glass_style(Design.colour("accent"), Color(0.04, 0.07, 0.13, 0.94), 20))
	_build_ui()

func bind_network(network: RefCounted) -> void:
	_network = network
	refresh_view()

func _build_ui() -> void:
	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 12)
	add_child(root_vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root_vbox.add_child(header)

	var icon := Design.LineIcon.new("place", Design.colour("accent"))
	header.add_child(icon)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)
	title_box.add_child(Design.label("Lunar Ridge & Malapert Coverage Map", "heading", "accent"))
	_summary_label = Design.label("Survey markers, fixed lines, path lights and relay repeaters built on your sorties stay on the map.", "caption", "muted")
	title_box.add_child(_summary_label)

	var close_btn := Design.button("Close (Esc)", 40)
	close_btn.name = "CloseCoverageMapButton"
	close_btn.pressed.connect(func(): panel_closed.emit())
	header.add_child(close_btn)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	root_vbox.add_child(body)

	# Left: Map schematic canvas
	var map_card := Design.glass_panel(Design.colour("glass_edge"), 12)
	map_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_card.custom_minimum_size = Vector2(540, 420)
	body.add_child(map_card)

	_canvas = MapCanvas.new()
	_canvas.name = "CoverageDiagramCanvas"
	_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_card.add_child(_canvas)

	# Right: Chapter 4 beacon layer + Relay hops & message unlocks + Voice status
	var side_col := VBoxContainer.new()
	side_col.custom_minimum_size = Vector2(360, 0)
	side_col.add_theme_constant_override("separation", 10)
	body.add_child(side_col)

	var beacon_card := Design.glass_panel(Design.colour("safe"), 12)
	side_col.add_child(beacon_card)
	var beacon_vbox := VBoxContainer.new()
	beacon_vbox.add_theme_constant_override("separation", 6)
	beacon_card.add_child(beacon_vbox)
	beacon_vbox.add_child(Design.label("Chapter 4 Beacons & Placed Markers", "body", "safe"))
	_beacons_list = VBoxContainer.new()
	_beacons_list.add_theme_constant_override("separation", 4)
	beacon_vbox.add_child(_beacons_list)

	var hops_card := Design.glass_panel(Design.colour("accent"), 12)
	hops_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_col.add_child(hops_card)
	var hops_vbox := VBoxContainer.new()
	hops_vbox.add_theme_constant_override("separation", 6)
	hops_card.add_child(hops_vbox)
	hops_vbox.add_child(Design.label("Relay Hops & Message Links", "body", "accent"))
	_hops_list = VBoxContainer.new()
	_hops_list.add_theme_constant_override("separation", 6)
	hops_vbox.add_child(_hops_list)

	var voice_card := Design.glass_panel(Design.colour("Mei"), 12)
	side_col.add_child(voice_card)
	_voice_label = Design.label("Summit Earth link: waiting for 4 local hops and bearings Local Two / Earth Three.", "caption", "ivory")
	_voice_label.name = "VoiceNetworkStatusLabel"
	voice_card.add_child(_voice_label)

func refresh_view() -> void:
	if _network == null:
		_network = NetworkScript.new()
	if _canvas is MapCanvas:
		(_canvas as MapCanvas).network = _network
		_canvas.queue_redraw()

	var placed: Array = _network.all_placed()
	var active_hops: Array = _network.active_hops()
	_summary_label.text = "Placed on Moon: %d structures (%d of %d markers) · Active relay hops: %d of 4 · Messages unlocked: %d" % [
		placed.size(),
		_network.count_by_kind("marker"),
		_network.marker_capacity(),
		active_hops.size(),
		_network.unlocked_message_ids().size(),
	]

	for c in _beacons_list.get_children():
		c.queue_free()
	if placed.is_empty():
		_beacons_list.add_child(Design.label("No survey markers or lines placed yet.", "caption", "muted"))
	else:
		for item in placed:
			var tag := "[Ch 4 Beacon Layer]" if bool(item.get("canon_beacon", false)) else ("[%s]" % String(item.get("kind", "marker")).replace("_", " ").capitalize())
			var row_lbl := Design.label("%s %s" % [tag, String(item.get("label", ""))], "caption", "ivory")
			_beacons_list.add_child(row_lbl)

	for c in _hops_list.get_children():
		c.queue_free()
	for hop in NetworkScript.CANON_RELAY_HOPS:
		var hop_id := String(hop.hop_id)
		var is_on := active_hops.has(hop_id)
		var status_word := "ONLINE" if is_on else "OFFLINE"
		var colour_name := "safe" if is_on else "muted"
		var line_text := "%s -> %s · %s" % [String(hop.from_node), String(hop.to_node), status_word]
		var lbl := Design.label(line_text, "caption", colour_name)
		_hops_list.add_child(lbl)
		if is_on:
			var msg_note := Design.label("  Unlocked message · %s: %s" % [String(hop.unlock_sender), String(hop.unlock_subject)], "caption", "accent")
			_hops_list.add_child(msg_note)

	if _network.is_voice_ready():
		_voice_label.text = "Dual link verified (Local Two + Earth Three · Echo ALO42): Noor's live voice travels over your 4-hop repeater road."
	else:
		_voice_label.text = "Summit Earth link: complete all 4 local hops and verify bearings Local Two and Earth Three (Echo ALO42) for live voice."


class MapCanvas extends Control:
	var network: RefCounted

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size if size.x > 40 else Vector2(520, 400))
		draw_rect(rect, Color(0.03, 0.05, 0.09, 0.95), true)
		draw_rect(rect, Color(1, 1, 1, 0.14), false, 1.0)

		# Grid lines
		for gx in range(1, 6):
			var x := rect.size.x * float(gx) / 6.0
			draw_line(Vector2(x, 0), Vector2(x, rect.size.y), Color(1, 1, 1, 0.05), 1.0)
		for gy in range(1, 5):
			var y := rect.size.y * float(gy) / 5.0
			draw_line(Vector2(0, y), Vector2(rect.size.x, y), Color(1, 1, 1, 0.05), 1.0)

		if network == null:
			return

		var active_hops: Array = network.active_hops()
		# Draw relay hops
		for hop in LunarNetwork.CANON_RELAY_HOPS:
			var p0 := _map_pt(hop.from_pos, rect.size)
			var p1 := _map_pt(hop.to_pos, rect.size)
			var is_on: bool = active_hops.has(String(hop.hop_id))
			var col := Color("#50D890") if is_on else Color(0.55, 0.62, 0.72, 0.35)
			draw_line(p0, p1, col, 3.0 if is_on else 1.5, true)
			draw_circle(p0, 6.0, col)
			draw_circle(p1, 6.0, col)

		# Draw Earth link ray from summit when voice ready
		var summit_pt := _map_pt([940.0, 110.0], rect.size)
		var earth_pt := Vector2(rect.size.x - 28.0, 28.0)
		var voice_ok: bool = network.is_voice_ready()
		draw_line(summit_pt, earth_pt, Color("#3AA0FF") if voice_ok else Color(0.8, 0.7, 0.3, 0.25), 3.0 if voice_ok else 1.5, true)
		draw_circle(earth_pt, 8.0, Color("#4CA8FF") if voice_ok else Color(0.3, 0.5, 0.7, 0.4))

		# Draw placed markers, fixed lines, path lights, repeaters
		for item in network.all_placed():
			var pt := _map_pt(item.get("position_m", [200.0, 200.0]), rect.size)
			var kind := String(item.get("kind", "marker"))
			var is_beacon := bool(item.get("canon_beacon", false))
			var col := Color("#3AA0FF") if is_beacon else Color("#6EC6FF")
			if kind == "fixed_line":
				draw_line(pt - Vector2(12, -8), pt + Vector2(12, -8), Color("#FF9F43"), 2.5)
			elif kind == "path_light":
				draw_circle(pt, 9.0, Color(1.0, 0.92, 0.45, 0.28))
				draw_circle(pt, 4.0, Color("#FFEAA7"))
			else:
				draw_arc(pt, 7.0, 0.0, TAU, 16, col, 2.0)
				draw_circle(pt, 3.0, col)

	func _map_pt(pos_m: Array, canvas_size: Vector2) -> Vector2:
		var mx := float(pos_m[0]) if pos_m.size() > 0 else 0.0
		var my := float(pos_m[1]) if pos_m.size() > 1 else 0.0
		return Vector2(
			clampf(mx / 1100.0, 0.06, 0.94) * canvas_size.x,
			clampf(my / 520.0, 0.08, 0.92) * canvas_size.y
		)
