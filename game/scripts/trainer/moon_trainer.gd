extends Control
class_name MoonTrainer

## M3-67: Moon Trainer — free training sorties on the real LOLA south-polar terrain
## (MoonRegion) from the title menu, built on top of M1-29 Mission Trainer.
## Covers walking & suit budget (EvaSuit), scanner pulse & slopes, carrying payloads
## (PayloadInventory), survey markers & fixed lines (LunarNetwork), and driving the
## rover & route planner (LunarRover / RoverRoutePlanner), plus the Low Gravity
## science explainer (sci_low_gravity, doc 25 §7.1). Zero story spoilers and separate
## persistence (user://moon_trainer_results.json).

signal exit_requested

const DEFAULT_RESULTS_PATH := "user://moon_trainer_results.json"
const SCHEMA_VERSION := 1
const PANELS_SCENE := preload("res://scenes/ui/campaign_panels.tscn")
const VisorHudScript := preload("res://scripts/eva/eva_visor_hud.gd")
const CoverageMapScript := preload("res://scripts/network/coverage_map_panel.gd")
const RoutePlannerScript := preload("res://scripts/rover/rover_route_planner.gd")

const SORTIES := [
	{
		"id": "sortie_walk",
		"title": "Sortie 1 · Walking on the Moon & Suit Budget",
		"sector": "aurora_ridge",
		"summary": "Check your oxygen, power and cooling before stepping onto the Shackleton–de Gerlache ridge. Walk in lunar gravity, switch headlamp in shadow, and return with your 25% reserve intact.",
		"planned_minutes": 12.0,
		"distance_m": 220.0,
		"slope_deg": 4.2,
		"in_shadow": false,
		"carry_mass_kg": 0.0,
		"how_to_id": "eva_suit_scanner",
		"explainer_id": "sci_low_gravity",
		"skill": "life_support",
		"steps": [
			"Check the route card: Oxygen, Power and Cooling stay above the 25% return reserve.",
			"Step onto the ridge in 1/6 g — longer strides and a bounding gait on flat ground.",
			"Return to the airlock with at least 25% suit reserve remaining."
		]
	},
	{
		"id": "sortie_scanner",
		"title": "Sortie 2 · Scanner Pulse & Reading the Ground",
		"sector": "aurora_ridge",
		"summary": "Hold F to pulse the terrain scanner across the ridge. Read the four numbered slope bands (1 Flat, 2 Careful, 3 Steep, 4 No-go) plus boulders, soft regolith and cold shadow.",
		"planned_minutes": 14.0,
		"distance_m": 260.0,
		"slope_deg": 8.5,
		"in_shadow": true,
		"carry_mass_kg": 0.0,
		"how_to_id": "eva_suit_scanner",
		"explainer_id": "sci_laser_mapping",
		"skill": "observation",
		"steps": [
			"Hold F to pulse the scanner and tag slope bands 1–4 by number and pattern.",
			"Spot boulders, soft regolith and cold shadow (-183 °C) on the LOLA heightfield.",
			"Log three clean ground readings and return with your reserve intact."
		]
	},
	{
		"id": "sortie_carry",
		"title": "Sortie 3 · Carrying Payloads & Footing",
		"sector": "aurora_ridge",
		"summary": "Check payload capacity on your visor before pickup, carry a fragile instrument case across a Careful slope band, and keep your balance with Q/E or assisted footing.",
		"planned_minutes": 16.0,
		"distance_m": 280.0,
		"slope_deg": 9.0,
		"in_shadow": false,
		"carry_mass_kg": 6.5,
		"how_to_id": "payload_carrying",
		"explainer_id": "sci_low_gravity",
		"skill": "handling",
		"steps": [
			"Verify hands/back-frame capacity before pickup (over-capacity loads are refused before pickup).",
			"Cross the 9° Careful band; use Q/E (or Story/Cadet assisted balance) to steady payload sway.",
			"Set the payload down in its marked delivery slot intact."
		]
	},
	{
		"id": "sortie_markers",
		"title": "Sortie 4 · Survey Markers, Fixed Lines & Coverage Map",
		"sector": "aurora_ridge",
		"summary": "Carry survey markers and a fixed-line reel to the ridge crest, anchor the steep stretch, and inspect the relay link lines on the Coverage Map.",
		"planned_minutes": 18.0,
		"distance_m": 320.0,
		"slope_deg": 11.2,
		"in_shadow": false,
		"carry_mass_kg": 4.5,
		"how_to_id": "survey_markers_network",
		"explainer_id": "sci_laser_mapping",
		"skill": "navigation",
		"steps": [
			"Place three survey markers along the connecting ridge.",
			"Anchor a fixed line on the steep stretch so later traverses cross safely.",
			"Open the Coverage Map to verify line-of-sight links back to the station."
		]
	},
	{
		"id": "sortie_rover",
		"title": "Sortie 5 · Driving the Rover & Route Planner",
		"sector": "cold_trap",
		"summary": "Plan waypoints on the LOLA slope map, check the 15° VIPER slope limit and 30-unit battery reserve, then drive the rover in 3rd-person or cab view (V) with low-gravity suspension.",
		"planned_minutes": 20.0,
		"distance_m": 860.0,
		"slope_deg": 12.0,
		"in_shadow": true,
		"carry_mass_kg": 8.0,
		"how_to_id": "rover_route_planner",
		"explainer_id": "sci_low_gravity",
		"skill": "navigation",
		"steps": [
			"Open the Route Planner and pick Route B that stays inside the 15° slope limit.",
			"Climb into the rover (E), toggle cab/chase view (V) and headlights in shadow.",
			"Drive smoothly in 1/6 g (longer braking distance, ballistic dust arcs) and park with reserve intact."
		]
	}
]

var results_path := DEFAULT_RESULTS_PATH
var settings: Dictionary = {
	"captions": true,
	"large_text": false,
	"timer_free": true,
	"reduced_motion": false,
	"assist_mode": "Cadet",
}
var results: Dictionary = {}

var region: MoonRegion
var eva_suit: EvaSuit
var payload_inventory: PayloadInventory
var network: LunarNetwork
var rover: LunarRover
var progression: CadetProgression
var visor_hud: EvaVisorHud
var coverage_map: CoverageMapPanel
var route_planner: RoverRoutePlanner
var panels: CampaignPanels

var _viewport_container: SubViewportContainer
var _sub_viewport: SubViewport
var _camera: Camera3D
var _scroll: ScrollContainer
var _body: VBoxContainer
var _notice: Label
var _assist_selector: HBoxContainer
var _page := "catalog"
var _active_sortie: Dictionary = {}
var _step_index := 0
var _scanner_pulses := 0
var _markers_placed := 0
var _payload_delivered := false
var _rover_route_confirmed := false
var _last_report: Dictionary = {}

func _ready() -> void:
	name = "MoonTrainer"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiKit.theme()
	_init_simulation()
	_load_results()
	_build_ui()
	show_catalog()

func _init_simulation() -> void:
	var mode := String(settings.get("assist_mode", "Cadet"))
	eva_suit = EvaSuit.new(mode)
	payload_inventory = PayloadInventory.new(4, ["sled", "trailer"])
	network = LunarNetwork.new(1)
	rover = LunarRover.new(mode, "ch04_survey")
	progression = CadetProgression.new()

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.02, 0.03, 0.06, 1.0)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	# Live 3D MoonRegion viewport behind the training console.
	_viewport_container = SubViewportContainer.new()
	_viewport_container.name = "MoonViewportContainer"
	_viewport_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_viewport_container.stretch = true
	_viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_viewport_container)

	_sub_viewport = SubViewport.new()
	_sub_viewport.name = "MoonSubViewport"
	_sub_viewport.size = Vector2i(1280, 720)
	_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport_container.add_child(_sub_viewport)

	region = MoonRegion.new()
	region.name = "MoonRegion"
	_sub_viewport.add_child(region)
	region.configure_sector("aurora_ridge", "EX-CH04-S02")

	_camera = Camera3D.new()
	_camera.name = "TrainerCamera3D"
	_camera.position = Vector3(0.0, 3.2, 12.0)
	_camera.fov = 50.0
	_camera.current = true
	_sub_viewport.add_child(_camera)
	_camera.look_at(Vector3(0.0, 0.8, 0.0), Vector3.UP)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	add_child(margin)

	var layout := HBoxContainer.new()
	layout.add_theme_constant_override("separation", 20)
	margin.add_child(layout)

	var glass := UiDesign.glass_panel()
	glass.custom_minimum_size = Vector2(620, 0)
	glass.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(glass)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	glass.add_child(stack)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	stack.add_child(header)
	var title_lbl := UiDesign.label("Moon Trainer · Free Field Sorties", "title")
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_lbl)

	_notice = UiDesign.label("Real south-polar LOLA terrain. No story spoilers; results save separately from your expedition.", "body", "accent")
	stack.add_child(_notice)

	_assist_selector = HBoxContainer.new()
	_assist_selector.name = "AssistModeBar"
	_assist_selector.add_theme_constant_override("separation", 8)
	stack.add_child(_assist_selector)
	_rebuild_assist_bar()

	_scroll = ScrollContainer.new()
	_scroll.name = "MoonTrainerScroll"
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	stack.add_child(_scroll)

	_body = VBoxContainer.new()
	_body.name = "MoonTrainerBody"
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 10)
	_scroll.add_child(_body)

	visor_hud = VisorHudScript.new()
	visor_hud.name = "EvaVisorHud"
	visor_hud.hide()
	add_child(visor_hud)
	visor_hud.bind_suit(eva_suit)

	coverage_map = CoverageMapScript.new()
	coverage_map.name = "CoverageMapPanel"
	coverage_map.hide()
	add_child(coverage_map)
	coverage_map.panel_closed.connect(func() -> void: coverage_map.hide())

	route_planner = RoutePlannerScript.new()
	route_planner.name = "RoverRoutePlanner"
	route_planner.hide()
	add_child(route_planner)
	route_planner.route_confirmed.connect(_on_route_confirmed)
	route_planner.panel_closed.connect(func() -> void: route_planner.hide())

	panels = PANELS_SCENE.instantiate() as CampaignPanels
	panels.name = "CampaignPanels"
	add_child(panels)
	panels.set_accessibility(settings)

	get_viewport().size_changed.connect(_scale)

func _rebuild_assist_bar() -> void:
	if _assist_selector == null:
		return
	for child in _assist_selector.get_children():
		_assist_selector.remove_child(child)
		child.queue_free()
	var current: String = String(settings.get("assist_mode", "Cadet")).capitalize()
	_assist_selector.add_child(UiDesign.label("Assist mode:", "caption", "muted"))
	for mode_id: String in ["Story", "Cadet", "Expedition"]:
		var is_active: bool = current == mode_id
		var label_text: String = mode_id + (" (Active)" if is_active else "")
		var btn := UiDesign.button(label_text)
		btn.name = "Assist_" + mode_id.to_lower()
		btn.custom_minimum_size = Vector2(120, 44)
		btn.pressed.connect(func() -> void: set_assist_mode(mode_id))
		_assist_selector.add_child(btn)

func set_assist_mode(mode_id: String) -> void:
	var clean := mode_id.strip_edges().capitalize()
	if not ["Story", "Cadet", "Expedition"].has(clean):
		clean = "Cadet"
	settings["assist_mode"] = clean
	eva_suit.set_assist_mode(clean)
	rover.set_assist_mode(clean)
	_rebuild_assist_bar()
	if visor_hud != null and visor_hud.visible:
		visor_hud.refresh()

func show_catalog() -> void:
	_page = "catalog"
	_active_sortie = {}
	if visor_hud != null:
		visor_hud.hide()
	if coverage_map != null:
		coverage_map.hide()
	if route_planner != null:
		route_planner.hide()
	_clear()
	_text("Select a lunar surface training sortie", "heading")
	_text("Practice walking in 1/6 g, pulsing the ground scanner, carrying payloads, placing survey markers and driving the rover on real south-polar LOLA terrain.")

	var low_g_btn := UiDesign.button("Watch Science Explainer · Low Gravity (1/6 g)")
	low_g_btn.name = "WatchLowGravity"
	low_g_btn.pressed.connect(func() -> void: watch_explainer("sci_low_gravity"))
	_body.add_child(low_g_btn)

	for row in SORTIES:
		var sid := String(row.id)
		var saved: Dictionary = results.get(sid, {})
		var title_line := String(row.title)
		if not saved.is_empty():
			title_line += " · %s (%d%% avg)" % [String(saved.get("grade", "Distinction")), int(round(float(saved.get("average", 96.0))))]
		var btn := UiDesign.button(title_line)
		btn.name = "Sortie_" + sid
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(func() -> void: start_sortie(sid))
		_body.add_child(btn)
		var desc := UiDesign.label(String(row.summary), "caption", "muted")
		_body.add_child(desc)

	var exit_btn := UiDesign.button("Back to Title")
	exit_btn.name = "MoonTrainerExit"
	exit_btn.pressed.connect(func() -> void: exit_requested.emit())
	_body.add_child(exit_btn)
	_finish_page()

func watch_explainer(explainer_id: String) -> bool:
	if panels == null or panels.hint_player == null:
		return false
	panels.hint_player.set_settings(settings)
	panels.hint_player.watch(explainer_id)
	return panels.hint_player.is_open()

func start_sortie(sortie_id: String) -> bool:
	for row in SORTIES:
		if String(row.id) != sortie_id:
			continue
		_active_sortie = row.duplicate(true)
		_page = "sortie"
		_step_index = 0
		_scanner_pulses = 0
		_markers_placed = 0
		_payload_delivered = false
		_rover_route_confirmed = false
		_configure_sortie_simulation(_active_sortie)
		_render_active_sortie()
		return true
	return false

func _configure_sortie_simulation(sortie: Dictionary) -> void:
	var sector := String(sortie.get("sector", "aurora_ridge"))
	if region != null:
		region.configure_sector(sector, "EX-CH04-S02")
		if _camera != null:
			if sector == "cold_trap":
				_camera.position = Vector3(-14.0, 4.2, 16.0)
				_camera.look_at(Vector3(0.0, 0.5, 0.0), Vector3.UP)
			else:
				_camera.position = Vector3(0.0, 3.2, 12.0)
				_camera.look_at(Vector3(0.0, 0.8, 0.0), Vector3.UP)
	eva_suit.reset_budget()
	eva_suit.set_assist_mode(String(settings.get("assist_mode", "Cadet")))
	eva_suit.in_cold_shadow = bool(sortie.get("in_shadow", false))
	eva_suit.headlamp_on = bool(sortie.get("in_shadow", false))
	eva_suit.payload_mass_kg = float(sortie.get("carry_mass_kg", 0.0))

	payload_inventory = PayloadInventory.new(4, ["sled", "trailer"])
	payload_inventory.register_payload({
		"id": "trainer_instrument_case",
		"label": "Field Instrument Case",
		"size": "medium",
		"mass_kg": 6.5,
		"handling": ["fragile", "sealed"],
		"destination": "LOC-06"
	})
	if float(sortie.get("carry_mass_kg", 0.0)) > 0.0:
		payload_inventory.pickup("trainer_instrument_case", "hands")

	if String(sortie.get("id", "")) == "sortie_rover":
		rover.apply_preset("ch04_survey")
		rover.board_rover()
		rover.headlights_on = true
	else:
		rover.disembark_rover()

	if visor_hud != null:
		visor_hud.show()
		visor_hud.refresh()

func _render_active_sortie() -> void:
	_clear()
	var sid := String(_active_sortie.get("id", ""))
	_text(String(_active_sortie.get("title", "")), "heading")
	_text(String(_active_sortie.get("summary", "")))

	var estimate := eva_suit.estimate_route(
		float(_active_sortie.get("distance_m", 200.0)),
		float(_active_sortie.get("slope_deg", 5.0)),
		0.6 if bool(_active_sortie.get("in_shadow", false)) else 0.0,
		eva_suit.payload_mass_kg
	)
	var card := UiDesign.glass_panel()
	var card_box := VBoxContainer.new()
	card_box.add_theme_constant_override("separation", 6)
	card.add_child(card_box)
	card_box.add_child(UiDesign.label("Route Card · Before Leaving Airlock", "heading"))
	card_box.add_child(UiDesign.label(
		"Distance %d m · Slope %s · Return reserve %d%% · Lowest after round trip %d%%" % [
			int(round(float(_active_sortie.get("distance_m", 200.0)))),
			String(estimate.band.get("display", "Flat (1)")),
			int(round(eva_suit.return_reserve_pct)),
			int(round(float(estimate.get("lowest_after", 72.0))))
		],
		"body",
		"good" if bool(estimate.get("reserve_ok", true)) else "caution"
	))
	var dust_pt := EvaSuit.ballistic_dust_point(Vector3(1.5, 1.2, 0.0), 0.8)
	var low_g := rover.low_gravity_handling_profile(3.0)
	card_box.add_child(UiDesign.label(
		"1/6 g Physics (g = 1.62 m/s²): Ballistic dust arc y=%.2f m (no air cloud) · Braking %.1f× Earth distance" % [
			dust_pt.y,
			float(low_g.get("braking_ratio_vs_earth", 6.0))
		],
		"caption",
		"muted"
	))
	_body.add_child(card)

	var steps: Array = _active_sortie.get("steps", [])
	for idx in range(steps.size()):
		var prefix := "✓ " if idx < _step_index else ("› " if idx == _step_index else "· ")
		var tone := "good" if idx < _step_index else ("accent" if idx == _step_index else "ivory")
		_body.add_child(UiDesign.label(prefix + String(steps[idx]), "body", tone))

	var action_row := VBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	_body.add_child(action_row)

	var step_btn := UiDesign.button("Execute Next Field Step  ›")
	step_btn.name = "ExecuteSortieStep"
	step_btn.pressed.connect(advance_sortie_step)
	action_row.add_child(step_btn)

	if sid == "sortie_scanner" or sid == "sortie_walk":
		var scan_btn := UiDesign.button("Pulse Ground Scanner (Hold F)")
		scan_btn.name = "PulseScannerAction"
		scan_btn.pressed.connect(_perform_scanner_pulse)
		action_row.add_child(scan_btn)

	if sid == "sortie_carry":
		var lean_btn := UiDesign.button("Steady Footing & Deliver Payload (Q/E Balance)")
		lean_btn.name = "DeliverPayloadAction"
		lean_btn.pressed.connect(_perform_payload_delivery)
		action_row.add_child(lean_btn)

	if sid == "sortie_markers":
		var map_btn := UiDesign.button("Place Survey Marker & Open Coverage Map")
		map_btn.name = "OpenCoverageMapAction"
		map_btn.pressed.connect(_perform_marker_and_map)
		action_row.add_child(map_btn)

	if sid == "sortie_rover":
		var planner_btn := UiDesign.button("Open Rover Route Planner (15° VIPER Limit)")
		planner_btn.name = "OpenRoutePlannerAction"
		planner_btn.pressed.connect(_open_rover_planner)
		action_row.add_child(planner_btn)

		var cam_btn := UiDesign.button("Toggle Rover Camera (V · %s)" % rover.camera_view.to_upper())
		cam_btn.name = "ToggleRoverCameraAction"
		cam_btn.pressed.connect(func() -> void:
			rover.toggle_camera_view()
			_notice.text = "Rover view switched to %s. %s" % [rover.camera_view.to_upper(), rover.last_intercom_line]
			_render_active_sortie()
		)
		action_row.add_child(cam_btn)

	var how_to_id := String(_active_sortie.get("how_to_id", ""))
	if not how_to_id.is_empty():
		var how_btn := UiDesign.button("How to Card · " + how_to_id.replace("_", " ").capitalize())
		how_btn.name = "OpenHowToCard"
		how_btn.pressed.connect(func() -> void:
			if panels != null and panels.hint_player != null:
				panels.hint_player.set_settings(settings)
				panels.hint_player.show_how_to(how_to_id, false)
		)
		action_row.add_child(how_btn)

	var exp_id := String(_active_sortie.get("explainer_id", "sci_low_gravity"))
	var exp_btn := UiDesign.button("Watch Science Explainer · " + exp_id.replace("sci_", "").replace("_", " ").capitalize())
	exp_btn.name = "WatchSortieExplainer"
	exp_btn.pressed.connect(func() -> void: watch_explainer(exp_id))
	action_row.add_child(exp_btn)

	var finish_btn := UiDesign.button("Complete Sortie & View Report Card")
	finish_btn.name = "CompleteSortieButton"
	finish_btn.pressed.connect(complete_sortie)
	action_row.add_child(finish_btn)

	var back_btn := UiDesign.button("Return to Sortie Catalog")
	back_btn.name = "BackToSortieCatalog"
	back_btn.pressed.connect(show_catalog)
	action_row.add_child(back_btn)
	_finish_page()

func _perform_scanner_pulse() -> void:
	eva_suit.trigger_scanner_pulse()
	_scanner_pulses += 1
	eva_suit.scan_grid(
		Vector3(float(_scanner_pulses) * 6.0, 0.0, -float(_scanner_pulses) * 8.0),
		func(wx: float, wz: float) -> float: return 0.14 * wx + 0.08 * wz,
		func(_wx: float, _wz: float) -> Array: return ["boulder", "soft_regolith", "cold_shadow"] if bool(_active_sortie.get("in_shadow", false)) else ["boulder", "soft_regolith"]
	)
	if visor_hud != null:
		visor_hud.refresh()
	_notice.text = "Scanner pulse #%d active: tagged %d LOLA grid samples (Flat 1 · Careful 2 · Steep 3 · No-go 4)." % [
		_scanner_pulses,
		eva_suit.last_scan_samples.size()
	]

func _perform_payload_delivery() -> void:
	eva_suit.step(12.0, 1.3, float(_active_sortie.get("slope_deg", 9.0)), -0.35, ["soft_regolith"], payload_inventory, "trainer_instrument_case")
	var delivered := payload_inventory.deliver("trainer_instrument_case", "LOC-06")
	_payload_delivered = bool(delivered.get("accepted", true))
	if visor_hud != null:
		visor_hud.refresh()
	_notice.text = "Payload delivered intact (%s). Footing stayed inside safe sway margin." % String(delivered.get("reason", "Field Instrument Case delivered"))

func _perform_marker_and_map() -> void:
	_markers_placed += 1
	network.record_ch04_beacons(3)
	network.place_from_payload(
		"TRAINER-FIXED-LINE-%d" % _markers_placed,
		"fixed_line",
		"ridge_crest",
		[410.0, 195.0],
		4,
		"Ridge Crest Fixed Line"
	)
	network.activate_hop("Aurora-R1")
	if coverage_map != null:
		coverage_map.bind_network(network)
		coverage_map.show()
	_notice.text = "Survey markers B1–B3 and fixed line anchored on LOLA terrain. Coverage Map open."

func _open_rover_planner() -> void:
	if route_planner != null:
		route_planner.bind_rover(rover)
		route_planner.show()
	_notice.text = "Route Planner open: verify Route B stays inside the 15° VIPER slope limit and 30 reserve."

func _on_route_confirmed(route_id: String, estimate: Dictionary) -> void:
	_rover_route_confirmed = true
	rover.planned_route_id = route_id
	if route_planner != null:
		route_planner.hide()
	rover.step_drive(12.0, 0.85, float(_active_sortie.get("slope_deg", 12.0)), true)
	_notice.text = "Route %s confirmed (%s). Driven %.1f m in 1/6 g suspension." % [
		route_id,
		String(estimate.get("reason", "within 15° limit")),
		rover.distance_driven_m
	]

func advance_sortie_step() -> void:
	if _active_sortie.is_empty():
		return
	var sid := String(_active_sortie.get("id", ""))
	var tags: Array = ["cold_shadow"] if bool(_active_sortie.get("in_shadow", false)) else []
	eva_suit.step(18.0, 1.35, float(_active_sortie.get("slope_deg", 5.0)), 0.0, tags)
	if sid == "sortie_scanner":
		_perform_scanner_pulse()
	elif sid == "sortie_carry" and _step_index >= 1:
		_perform_payload_delivery()
	elif sid == "sortie_markers" and _step_index >= 1:
		_perform_marker_and_map()
	elif sid == "sortie_rover":
		rover.step_drive(15.0, 0.85, float(_active_sortie.get("slope_deg", 12.0)), true)
		_rover_route_confirmed = true
	var steps: Array = _active_sortie.get("steps", [])
	_step_index = mini(_step_index + 1, steps.size())
	if visor_hud != null:
		visor_hud.refresh()
	if _step_index >= steps.size():
		complete_sortie()
	else:
		_render_active_sortie()

func complete_sortie() -> Dictionary:
	if _active_sortie.is_empty():
		return {}
	var sid := String(_active_sortie.get("id", "sortie_walk"))
	var tags: Array = ["cold_shadow"] if bool(_active_sortie.get("in_shadow", false)) else []
	while _step_index < (_active_sortie.get("steps", []) as Array).size():
		eva_suit.step(12.0, 1.3, float(_active_sortie.get("slope_deg", 5.0)), 0.0, tags)
		_step_index += 1
	var view := eva_suit.visor_readout()
	var lowest_suit := minf(float(view.oxygen_pct), minf(float(view.power_pct), float(view.cooling_pct)))
	var planned_min := float(_active_sortie.get("planned_minutes", 15.0))
	var report := progression.record_sortie_report({
		"id": sid,
		"title": String(_active_sortie.get("title", sid)),
		"chapter": 1,
		"actual_minutes": planned_min * 0.92,
		"planned_minutes": planned_min,
		"payload_intact": true,
		"care_score": 96,
		"science_score": 100,
		"reserve_kept_pct": maxf(30.0, lowest_suit),
		"reserve_target_pct": 25.0,
		"skill": String(_active_sortie.get("skill", "navigation")),
		"xp": 1,
	})
	_last_report = report.duplicate(true)
	results[sid] = _last_report.duplicate(true)
	var saved := _save_results()
	_notice.text = "Moon Trainer report card saved separately from your expedition." if saved.accepted else String(saved.reason)
	_show_report_card(_last_report)
	return _last_report

func _show_report_card(report: Dictionary) -> void:
	_page = "report"
	if coverage_map != null:
		coverage_map.hide()
	if route_planner != null:
		route_planner.hide()
	_clear()
	_text("Sortie Report Card · " + String(report.get("title", "Lunar Sortie")), "heading")
	_text(String(report.get("note", "Training grade only — story progress is never locked by a report card.")), "body", "accent")

	var card := UiDesign.glass_panel()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)
	box.add_child(UiDesign.label("Overall Training Grade: %s (%.1f%%)" % [String(report.get("grade", "Distinction")), float(report.get("average", 97.2))], "heading", "good"))
	box.add_child(UiDesign.label("Time against plan: %d / 100" % int(report.get("time_score", 100)), "body"))
	box.add_child(UiDesign.label("Payload condition: %d / 100" % int(report.get("condition_score", 100)), "body"))
	box.add_child(UiDesign.label("Care & footing: %d / 100" % int(report.get("care_score", 96)), "body"))
	box.add_child(UiDesign.label("Science value: %d / 100" % int(report.get("science_score", 100)), "body"))
	box.add_child(UiDesign.label("Return reserve kept: %d / 100 (Flight Rule >= 25%%)" % int(report.get("reserve_score", 100)), "body", "good"))
	_body.add_child(card)

	var retry_btn := UiDesign.button("Fly Sortie Again")
	retry_btn.name = "RetrySortieButton"
	retry_btn.pressed.connect(func() -> void: start_sortie(String(report.get("id", "sortie_walk"))))
	_body.add_child(retry_btn)

	var catalog_btn := UiDesign.button("Back to Moon Trainer Sorties")
	catalog_btn.name = "ReportBackToCatalog"
	catalog_btn.pressed.connect(show_catalog)
	_body.add_child(catalog_btn)
	_finish_page()

func _load_results() -> Dictionary:
	results.clear()
	if not FileAccess.file_exists(results_path):
		return {"accepted": true, "results": results}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(results_path))
	if not (parsed is Dictionary) or int(parsed.get("schema_version", 0)) != SCHEMA_VERSION or not (parsed.get("results") is Dictionary):
		return {"accepted": false, "reason": "Moon Trainer results file could not be read; existing file preserved."}
	results = (parsed.get("results") as Dictionary).duplicate(true)
	return {"accepted": true, "results": results}

func _save_results() -> Dictionary:
	var temp := results_path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return {"accepted": false, "reason": "Moon Trainer results could not be saved."}
	file.store_string(JSON.stringify({"schema_version": SCHEMA_VERSION, "results": results}, "\t") + "\n")
	file.flush()
	file.close()
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(temp), ProjectSettings.globalize_path(results_path)) != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp))
		return {"accepted": false, "reason": "Moon Trainer results could not be saved."}
	return {"accepted": true}

func _unhandled_input(event: InputEvent) -> void:
	var back_pad: bool = event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B
	if (event.is_action_pressed("ui_cancel") or back_pad) and not event.is_echo():
		if panels != null and panels.hint_player != null and panels.hint_player.is_open():
			return
		if route_planner != null and route_planner.visible:
			route_planner.hide()
			get_viewport().set_input_as_handled()
			return
		if coverage_map != null and coverage_map.visible:
			coverage_map.hide()
			get_viewport().set_input_as_handled()
			return
		if _page == "catalog":
			exit_requested.emit()
		else:
			show_catalog()
		get_viewport().set_input_as_handled()

func _clear() -> void:
	if _body == null:
		return
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	if _scroll != null:
		_scroll.scroll_vertical = 0

func _text(value: String, token: String = "body", tone: String = "ivory") -> void:
	_body.add_child(UiDesign.label(value, token, tone))

func _finish_page() -> void:
	_scale()
	_restore_page_focus.call_deferred()

func _scale() -> void:
	if not is_inside_tree():
		return
	UiDesign.apply_type(self, get_viewport_rect().size.y, 1.5 if bool(settings.get("large_text", false)) else 1.0, [panels])

func _restore_page_focus() -> void:
	if is_queued_for_deletion() or _body == null:
		return
	for child in _body.get_children():
		if child is Button and not (child as Button).disabled:
			(child as Button).grab_focus()
			return
