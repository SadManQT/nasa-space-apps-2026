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
const SHELL_SCENE := preload("res://scenes/trainer/moon_trainer.tscn")
const VisorHudScript := preload("res://scripts/eva/eva_visor_hud.gd")
const CoverageMapScript := preload("res://scripts/network/coverage_map_panel.gd")
const RoutePlannerScript := preload("res://scripts/rover/rover_route_planner.gd")
const VehicleScript := preload("res://scripts/rover/rover_vehicle.gd")
const PlayerScene := preload("res://scenes/player/player.tscn")
const Scatter := preload("res://assets/environment/terrain/lunar_scatter.gd")

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
			"Read the measured slopes and authored terrain hazards on the LOLA heightfield.",
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
			"Cross the marked terrain; use Q/E (or Story/Cadet assisted balance) to steady payload sway.",
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

var player: PlayerController
var vehicle: CharacterBody3D
var field_ready := false
var field_active := false
var start_position := Vector3.ZERO
var checkpoint_position := Vector3.ZERO
var elapsed_s := 0.0
var _console: Control
var _field_help: Label
var _field_bar: Control
var _course_root: Node3D
var _setup_generation := 0
var _last_player_position := Vector3.ZERO
var _walk_distance := 0.0
var _checkpoint_reached := false
var _field_entered := false
var _map_viewed := false
var _line_placed := false
var _camera_switched := false
var _scan_origins: Array[Vector3] = []
var _marker_sites: Array[Vector3] = []
var _last_scanner_active := false

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
	_prepare_initial_field.call_deferred()

func _prepare_initial_field() -> void:
	await region.configure_sector("aurora_ridge", "EX-CH04-S02")
	if _active_sortie.is_empty():
		field_ready = true
		_camera.position = Vector3(20.0, _field_height(20.0, 29.0) + 8.0, 29.0)
		_camera.look_at(Vector3(0.0, _field_height(0.0, 5.0) + 1.0, 5.0), Vector3.UP)
		_scroll.scroll_vertical = 0

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
	_sub_viewport.own_world_3d = true
	_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport_container.add_child(_sub_viewport)

	region = MoonRegion.new()
	region.name = "MoonRegion"
	_sub_viewport.add_child(region)

	_camera = Camera3D.new()
	_camera.name = "TrainerCamera3D"
	_camera.position = Vector3(0.0, 3.2, 12.0)
	_camera.fov = 50.0
	_camera.current = true
	_sub_viewport.add_child(_camera)
	_camera.look_at(Vector3(0.0, 0.8, 0.0), Vector3.UP)
	player = PlayerScene.instantiate() as PlayerController
	player.name = "TrainerAstronaut"
	player.character_glb = "res://assets/characters/CH_Kai_EVA/CH_Kai_EVA.glb"
	player.tuning = load("res://resources/player/ch_kai.tres") as LocomotionTuning
	player.controlled = false
	player.gravity = EvaSuit.MOON_G
	player.generic_interaction_input = false
	var player_camera := player.get_node("FollowCamera") as FollowCamera
	player_camera.active = false
	player_camera.capture_mouse = false
	_sub_viewport.add_child(player)
	player.eva_suit = eva_suit
	vehicle = VehicleScript.new()
	vehicle.name = "TrainerRover"
	_sub_viewport.add_child(vehicle)
	vehicle.bind_model(rover)
	vehicle.controls_enabled = false
	_course_root = Node3D.new()
	_course_root.name = "TrainingCourse"
	_sub_viewport.add_child(_course_root)

	var shell := SHELL_SCENE.instantiate() as Control
	_console = shell
	add_child(shell)
	_notice = shell.find_child("MoonTrainerNotice", true, false) as Label
	_assist_selector = shell.find_child("AssistModeBar", true, false) as HBoxContainer
	_scroll = shell.find_child("MoonTrainerScroll", true, false) as ScrollContainer
	_body = shell.find_child("MoonTrainerBody", true, false) as VBoxContainer
	for label_node in shell.find_children("*", "Label", true, false):
		var label := label_node as Label
		UiDesign.style_label(label, String(label.get_meta("lla_type", "body")), "muted" if label.get_meta("muted", false) else "ivory")
	_rebuild_assist_bar()

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
	_field_bar = UiDesign.glass_panel()
	_field_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_field_bar.offset_left = 24
	_field_bar.offset_right = -24
	_field_bar.offset_top = 24
	_field_bar.offset_bottom = 140
	add_child(_field_bar)
	var field_bar := HBoxContainer.new()
	_field_bar.add_child(field_bar)
	_field_bar.hide()
	_field_help = UiDesign.label("", "body", "ivory")
	_field_help.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field_bar.add_child(_field_help)
	var console_button := UiDesign.button("Field / Console (Tab)")
	console_button.name = "ToggleFieldConsole"
	console_button.pressed.connect(func() -> void: leave_field() if field_active else enter_field())
	field_bar.add_child(console_button)

	get_viewport().size_changed.connect(_scale)

func _rebuild_assist_bar() -> void:
	if _assist_selector == null:
		return
	for child in _assist_selector.get_children():
		_assist_selector.remove_child(child)
		child.queue_free()
	var current: String = String(settings.get("assist_mode", "Cadet")).capitalize()
	var label := UiDesign.label("Assist mode:", "caption", "muted")
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_assist_selector.add_child(label)
	for mode_id: String in ["Story", "Cadet", "Expedition"]:
		var is_active: bool = current == mode_id
		var label_text: String = mode_id + (" (Active)" if is_active else "")
		var btn := UiDesign.button(label_text)
		btn.name = "Assist_" + mode_id.to_lower()
		btn.custom_minimum_size = Vector2(120, 44)
		btn.add_theme_stylebox_override("normal", UiDesign.button_style(UiDesign.colour("accent" if is_active else "navy"), is_active))
		btn.add_theme_color_override("font_color", UiDesign.colour("ink" if is_active else "ivory"))
		btn.add_theme_color_override("font_focus_color", UiDesign.colour("ink" if is_active else "ivory"))
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
	_scale()
	(_assist_selector.get_node("Assist_" + clean.to_lower()) as Button).grab_focus.call_deferred()
	if visor_hud != null and visor_hud.visible:
		visor_hud.refresh()

func show_catalog() -> void:
	leave_field()
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
		var card := UiDesign.glass_panel()
		card.name = "SortieCard_" + sid
		_body.add_child(card)
		var contents := VBoxContainer.new()
		contents.add_theme_constant_override("separation", 10)
		card.add_child(contents)
		contents.add_child(UiDesign.label(String(row.title), "heading"))
		contents.add_child(UiDesign.label(String(row.summary), "caption", "muted"))
		var title_line := "Start sortie"
		if not saved.is_empty():
			title_line += " · %s (%d%% avg)" % [String(saved.get("grade", "Distinction")), int(round(float(saved.get("average", 96.0))))]
		var btn := UiDesign.button(title_line)
		btn.name = "Sortie_" + sid
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(func() -> void: start_sortie(sid))
		contents.add_child(btn)

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
		field_ready = false
		elapsed_s = 0.0
		_walk_distance = 0.0
		_checkpoint_reached = false
		_field_entered = false
		_map_viewed = false
		_line_placed = false
		_camera_switched = false
		_scan_origins.clear()
		_last_scanner_active = false
		_scanner_pulses = 0
		_markers_placed = 0
		_payload_delivered = false
		_rover_route_confirmed = false
		_configure_sortie_simulation(_active_sortie)
		_render_active_sortie()
		return true
	return false

func _configure_sortie_simulation(sortie: Dictionary) -> void:
	leave_field()
	_setup_generation += 1
	var generation := _setup_generation
	var sector := String(sortie.get("sector", "aurora_ridge"))
	await region.configure_sector(sector, "EX-CH04-S06" if sector == "cold_trap" else "EX-CH04-S02")
	if generation != _setup_generation or _active_sortie.is_empty():
		return
	eva_suit.reset_budget()
	eva_suit.set_assist_mode(String(settings.get("assist_mode", "Cadet")))
	eva_suit.indoor = false
	eva_suit.headlamp_on = false
	eva_suit.slip_count = 0
	eva_suit.payload_scuffs = 0
	network = LunarNetwork.new(1)
	payload_inventory = PayloadInventory.new(4, ["sled", "trailer"])
	payload_inventory.register_payload({"id": "trainer_instrument_case", "label": "Field Instrument Case", "size": "medium", "mass_kg": 6.5, "handling": ["fragile", "sealed"], "destination": "training_delivery"})
	for index in range(3):
		payload_inventory.register_payload(LunarNetwork.make_payload_definition("trainer_marker_%d" % index, "marker", "training_marker_%d" % index))
	payload_inventory.register_payload(LunarNetwork.make_payload_definition("trainer_line", "fixed_line", "training_line"))
	rover.apply_preset("ch04_survey")
	rover.aboard = false
	vehicle.driver = null
	vehicle.bind_model(rover, region.stream.field)
	vehicle.controls_enabled = false
	start_position = Vector3(0.0, 0.0, 5.0)
	start_position.y = _field_height(start_position.x, start_position.z) + 0.2
	var half_distance := float(sortie.get("distance_m", 220.0)) * 0.5
	# Let freshly staged structures reach the physics broadphase before the course is checked against them.
	await get_tree().physics_frame
	if generation != _setup_generation or _active_sortie.is_empty():
		return
	var best_slope := INF
	var best_blocked := INF
	var direction := Vector3.FORWARD
	var rock_cache: Dictionary = {}
	var sid := String(sortie.get("id", ""))
	var course_origin := start_position + Vector3(3.0, 0.0, 0.0) if sid == "sortie_rover" else start_position
	var samples := maxi(4, int(ceil(half_distance / 1.0)))
	for step_deg in range(0, 360, 1):
		var candidate := Vector3.FORWARD.rotated(Vector3.UP, deg_to_rad(float(step_deg)))
		var worst := 0.0
		for index in range(samples + 1):
			var point: Vector3 = course_origin + candidate * half_distance * float(index) / float(samples)
			worst = maxf(worst, region.stream.field.slope_deg_at(point.x, point.z))
			if sid == "sortie_rover":
				var ret_point: Vector3 = start_position + candidate * half_distance * float(index) / float(samples)
				worst = maxf(worst, region.stream.field.slope_deg_at(ret_point.x, ret_point.z))
		# A course that walks into a building, a closed hatch or a collidable boulder is not a course.
		var blocked := _course_obstructions(course_origin, candidate, half_distance, rock_cache, sid == "sortie_rover")
		if worst >= 14.0:
			blocked += 10000 + int(round(worst * 10.0))
		if blocked < best_blocked or (blocked == best_blocked and worst < best_slope):
			best_blocked = blocked
			best_slope = worst
			direction = candidate
	checkpoint_position = course_origin + direction * half_distance
	checkpoint_position.y = _field_height(checkpoint_position.x, checkpoint_position.z) + 0.15
	_clear_course_scatter(start_position, checkpoint_position, 5.0 if sid == "sortie_rover" else 2.2)
	_active_sortie["slope_deg"] = best_slope
	var lighting := TerrainHeightfield.scene_lighting(region.active_scene, region.active_segment)
	_active_sortie["in_shadow"] = String(lighting.get("sun_state", "")) == "dark"
	_marker_sites.clear()
	for fraction in [0.3, 0.6, 0.9]:
		var point: Vector3 = start_position.lerp(checkpoint_position, float(fraction))
		point.y = _field_height(point.x, point.z)
		_marker_sites.append(point)
	for child in _course_root.get_children():
		child.free()
	_course_marker(start_position, "Return point")
	_course_marker(checkpoint_position, "Delivery / turn point")
	for index in range(_marker_sites.size()):
		_course_marker(_marker_sites[index], "Survey site %d" % (index + 1))
	player.global_position = start_position
	player.collision_layer = 2
	player.show()
	player.reset_placement()
	_last_player_position = player.global_position
	vehicle.global_position = start_position + Vector3(3.0, 0.0, 0.0)
	vehicle.global_position.y = _field_height(vehicle.global_position.x, vehicle.global_position.z) + 0.1
	vehicle.velocity = Vector3.ZERO
	vehicle.rotation.y = atan2(-direction.x, -direction.z)
	field_ready = true
	_render_active_sortie()
	_notice.text = "Field ready. Enter the field, follow the marked course, and return here to finish."
	if visor_hud != null:
		visor_hud.show()
		visor_hud.refresh()

func _field_height(wx: float, wz: float) -> float:
	return region.stream.field.height_at(wx, wz) if region != null and region.stream != null and region.stream.field != null else 0.0

func _clear_course_scatter(from_pos: Vector3, to_pos: Vector3, radius_m: float) -> void:
	if region == null or region.stream == null or region.stream.field == null:
		return
	var dist := _distance_to(from_pos, to_pos)
	var steps := maxi(1, int(ceil(dist / maxf(1.5, radius_m * 0.75))))
	for index in range(steps + 1):
		var pt := from_pos.lerp(to_pos, float(index) / float(steps))
		pt.y = _field_height(pt.x, pt.z)
		region.stream.exclusions.append({"position": pt, "radius_m": radius_m})
	for group in region.stream.rocks.values():
		if is_instance_valid(group):
			(group as Node).queue_free()
	region.stream.rocks.clear()
	region.stream._rock_queue.clear()
	region.stream.move_focus(from_pos, true)

## Counts what physically stands on a straight out-and-back course: staged structures and doors (physics rays a
## metre above the LOLA ground, ignoring the terrain collision itself) and the collidable boulders the terrain stream
## will scatter there (TerrainStream.rock_records is deterministic, so chunks not yet built are checked too). The
## corridor is wide enough for the rover parked beside the start.
func _course_obstructions(origin: Vector3, direction: Vector3, length: float, rock_cache: Dictionary, rover_course: bool = false) -> int:
	var hits := 0
	var corridor := 3.6 if rover_course else 1.2
	var exclude: Array[RID] = [player.get_rid(), vehicle.get_rid()]
	for body in region.stream.collisions.values():
		exclude.append((body as CollisionObject3D).get_rid())
	for group in region.stream.rocks.values():
		for body in (group as Node).find_children("*", "CollisionObject3D", true, false):
			exclude.append((body as CollisionObject3D).get_rid())
	var space := region.get_world_3d().direct_space_state
	var step := 4.0
	var count := maxi(1, int(ceil(length / step)))
	var side := direction.cross(Vector3.UP).normalized()
	for lane in [-corridor * 0.5, 0.0, corridor * 0.5]:
		for index in range(count):
			for lift in [0.35, 1.2]:
				var a: Vector3 = origin + side * float(lane) + direction * length * float(index) / float(count)
				var b: Vector3 = origin + side * float(lane) + direction * length * float(index + 1) / float(count)
				a.y = _field_height(a.x, a.z) + float(lift)
				b.y = _field_height(b.x, b.z) + float(lift)
				var query := PhysicsRayQueryParameters3D.create(a, b, 1, exclude)
				if not space.intersect_ray(query).is_empty():
					hits += 1000
	var end := origin + direction * length
	var flat_a := Vector2(origin.x, origin.z)
	var flat_b := Vector2(end.x, end.z)
	# The region's authored clear areas mark every staged location and landmark (masts, annex, garage, lookout
	# plaques). Only the one the course starts in is crossed, and its structures are covered by the rays above.
	for area in region._sector_exclusions(region.active_sector):
		var centre := Vector2(area.position.x, area.position.z)
		var radius := float(area.radius_m)
		if centre.distance_to(flat_a) < radius:
			continue
		if centre.distance_to(Geometry2D.get_closest_point_to_segment(centre, flat_a, flat_b)) < radius + corridor * 0.5:
			hits += 1000
	var min_size := float(Scatter.rules().get("collision_min_size_m", 0.0))
	var chunk := float(region.stream.config.get("rock_chunk_m", 32.0))
	var cells: Dictionary = {}
	for index in range(int(ceil(length / (chunk * 0.5))) + 1):
		var p: Vector3 = origin.lerp(end, minf(1.0, float(index) * chunk * 0.5 / maxf(length, 0.001)))
		for dx in [-1, 0, 1]:
			for dz in [-1, 0, 1]:
				cells[Vector2i(floori(p.x / chunk) + dx, floori(p.z / chunk) + dz)] = true
	for cell in cells:
		if not rock_cache.has(cell):
			rock_cache[cell] = region.stream.rock_records(cell)
		for record in rock_cache[cell]:
			if float(record.size_m) < min_size:
				continue
			var at := Vector2(record.position.x, record.position.z)
			var nearest := Geometry2D.get_closest_point_to_segment(at, flat_a, flat_b)
			if at.distance_to(nearest) < float(record.size_m) * 0.6 + corridor * 0.5 + 0.6:
				hits += 1
	return hits

func _course_marker(at: Vector3, label_text: String) -> void:
	var marker := MeshInstance3D.new()
	var pole := CylinderMesh.new()
	pole.top_radius = 0.05
	pole.bottom_radius = 0.05
	pole.height = 1.4
	marker.mesh = pole
	marker.position = at + Vector3.UP * 0.7
	_course_root.add_child(marker)
	var label := Label3D.new()
	label.text = label_text
	label.position = at + Vector3.UP * 1.9
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 40
	_course_root.add_child(label)

func enter_field() -> void:
	if not field_ready or _active_sortie.is_empty():
		return
	field_active = true
	_field_entered = true
	_console.hide()
	_field_bar.show()
	player.set_controlled(not rover.aboard)
	player.follow_camera.set_process_unhandled_input(not rover.aboard)
	vehicle.controls_enabled = rover.aboard
	if rover.aboard:
		vehicle.active_camera().make_current()
	else:
		player.follow_camera.camera.make_current()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if FollowCamera.may_capture_pointer() else Input.MOUSE_MODE_VISIBLE

func leave_field() -> void:
	var was_active := field_active
	field_active = false
	if _console != null:
		_console.show()
	if _field_bar != null:
		_field_bar.hide()
	if player != null:
		player.set_controlled(false)
		player.follow_camera.set_process_unhandled_input(false)
	if vehicle != null:
		vehicle.controls_enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if was_active and _page == "sortie" and _body != null:
		_render_active_sortie()

func _physics_process(delta: float) -> void:
	if not field_active or not field_ready or _active_sortie.is_empty():
		return
	elapsed_s += delta
	var position_now: Vector3 = vehicle.global_position if rover.aboard else player.global_position
	if not rover.aboard:
		_walk_distance += Vector2(position_now.x - _last_player_position.x, position_now.z - _last_player_position.z).length()
	_last_player_position = position_now
	if _distance_to(position_now, checkpoint_position) <= 3.0:
		_checkpoint_reached = true
	var row := TerrainHeightfield.scene_lighting(region.active_scene, region.active_segment)
	var dark := String(row.get("sun_state", "")) == "dark"
	player.eva_surface_tags = ["cold_shadow"] if dark else []
	player.eva_slope_override_deg = region.stream.field.slope_deg_at(position_now.x, position_now.z)
	eva_suit.payload_mass_kg = payload_inventory.personal_mass()
	vehicle.in_shadow = dark
	if rover.aboard:
		eva_suit.step(delta, 0.0, 0.0, 0.0, player.eva_surface_tags)
	region.move_focus(position_now)
	if eva_suit.scanner_pulse_active and not _last_scanner_active:
		_record_scan()
	_last_scanner_active = eva_suit.scanner_pulse_active
	_update_objectives()
	_field_help.text = "WASD move/drive | F scan | E pick up/deliver/board/exit | M deploy | V cab/chase | L lights | Tab console\nTurn point %.0f m | Return %.0f m | Steps %d/3 | Rover %.0f/%.0f | %s" % [_distance_to(position_now, checkpoint_position), _distance_to(position_now, start_position), _step_index, rover.battery, rover.battery_capacity, rover.last_intercom_line]
	if visor_hud != null:
		visor_hud.refresh()

static func _distance_to(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()

func _update_objectives() -> void:
	var sid := String(_active_sortie.get("id", ""))
	var back := _checkpoint_reached and _distance_to(player.global_position, start_position) <= 6.0
	match sid:
		"sortie_walk": _step_index = int(_field_entered) + int(_checkpoint_reached) + int(back)
		"sortie_scanner": _step_index = int(_scanner_pulses > 0) + int(_scanner_pulses >= 3) + int(back and _scanner_pulses >= 3)
		"sortie_carry": _step_index = int(payload_inventory.item("trainer_instrument_case").place != "ground") + int(_payload_delivered) + int(back and _payload_delivered)
		"sortie_markers": _step_index = int(_markers_placed >= 3) + int(_line_placed) + int(back and _map_viewed and _line_placed)
		"sortie_rover": _step_index = int(_rover_route_confirmed) + int(_camera_switched and rover.headlights_on) + int(back and not rover.aboard and rover.distance_driven_m >= float(_active_sortie.get("distance_m", 860.0)) * 0.9)

func interact_field() -> Dictionary:
	if not field_ready:
		return {"accepted": false, "reason": "The field is preparing."}
	var sid := String(_active_sortie.get("id", ""))
	var result := {"accepted": false, "reason": "Follow the course to the marked pickup or delivery point."}
	if sid == "sortie_rover":
		result = vehicle.exit_vehicle() if rover.aboard else vehicle.board(player)
		vehicle.controls_enabled = field_active and rover.aboard
	elif sid == "sortie_carry":
		if payload_inventory.item("trainer_instrument_case").place == "ground" and _distance_to(player.global_position, start_position) <= 4.0:
			result = payload_inventory.pickup("trainer_instrument_case", "hands")
		elif _distance_to(player.global_position, checkpoint_position) <= 3.0:
			result = payload_inventory.deliver("trainer_instrument_case", "training_delivery")
			_payload_delivered = bool(result.get("accepted", false))
	elif sid == "sortie_markers":
		if _distance_to(player.global_position, start_position) <= 4.0:
			for index in range(3):
				payload_inventory.pickup("trainer_marker_%d" % index, "back")
			result = payload_inventory.pickup("trainer_line", "hands")
		else:
			return _place_next_structure()
	evaluate_notice(result)
	_update_objectives()
	return result

func evaluate_notice(result: Dictionary) -> void:
	_notice.text = String(result.get("reason", "Field action complete."))
	_field_help.text = _notice.text

func _place_next_structure() -> Dictionary:
	var index := _markers_placed
	var line := index >= 3
	var target := checkpoint_position if line else _marker_sites[index]
	if _distance_to(player.global_position, target) > 3.0:
		var denied := {"accepted": false, "reason": "Reach the next marked survey site before deploying."}
		evaluate_notice(denied)
		return denied
	var id := "trainer_line" if line else "trainer_marker_%d" % index
	var result := network.place_from_payload(id, "fixed_line" if line else "marker", "training_line" if line else "training_marker_%d" % index, [target.x, target.z], 1, "Training fixed line" if line else "Training survey marker %d" % (index + 1), payload_inventory, id)
	if bool(result.get("accepted", false)):
		if line:
			_line_placed = true
		else:
			_markers_placed += 1
		_course_marker(target, "Fixed line anchored" if line else "Survey marker placed")
	evaluate_notice(result)
	_update_objectives()
	return result

func _render_active_sortie() -> void:
	_clear()
	var sid := String(_active_sortie.get("id", ""))
	_text(String(_active_sortie.get("title", "")), "heading")
	_text(String(_active_sortie.get("summary", "")))

	var estimate := eva_suit.estimate_route(
		float(_active_sortie.get("distance_m", 200.0)) * 0.5,
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

	var step_btn := UiDesign.button("Enter Field (WASD / controller)")
	step_btn.name = "ExecuteSortieStep"
	step_btn.pressed.connect(enter_field)
	action_row.add_child(step_btn)

	if sid == "sortie_scanner" or sid == "sortie_walk":
		var scan_btn := UiDesign.button("Pulse Ground Scanner (Hold F)")
		scan_btn.name = "PulseScannerAction"
		scan_btn.pressed.connect(_perform_scanner_pulse)
		action_row.add_child(scan_btn)

	if sid == "sortie_carry":
		var lean_btn := UiDesign.button("Pick Up / Deliver Payload (E)")
		lean_btn.name = "DeliverPayloadAction"
		lean_btn.pressed.connect(_perform_payload_delivery)
		action_row.add_child(lean_btn)

	if sid == "sortie_markers":
		var map_btn := UiDesign.button("Open Coverage Map (E picks up kit; M deploys)")
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
			vehicle.toggle_camera_view()
			_camera_switched = true
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
	if not field_ready or _active_sortie.is_empty():
		return
	eva_suit.trigger_scanner_pulse()
	_record_scan()
	_last_scanner_active = true
	if visor_hud != null:
		visor_hud.refresh()

func _record_scan() -> void:
	var origin := player.global_position
	eva_suit.scan_grid(origin, _field_height, _surface_tags)
	var distinct := true
	for previous in _scan_origins:
		if _distance_to(origin, previous) < 2.0:
			distinct = false
	if distinct:
		_scan_origins.append(origin)
		_scanner_pulses += 1
	_notice.text = "Scanner: %d real terrain samples; %d distinct reading positions. Move at least 2 m between readings." % [eva_suit.last_scan_samples.size(), _scanner_pulses]
	_update_objectives()

func _surface_tags(wx: float, wz: float) -> Array:
	var tags: Array = []
	var row := TerrainHeightfield.scene_lighting(region.active_scene, region.active_segment)
	if String(row.get("sun_state", "")) == "dark":
		tags.append("cold_shadow")
	for obstacle in region.find_children("*", "Node3D", true, false):
		if "boulder" in String(obstacle.name).to_lower() and _distance_to(Vector3(wx, 0, wz), obstacle.global_position) <= float(obstacle.get_meta("radius_m", 1.5)):
			tags.append("boulder")
			break
	return tags

func _perform_payload_delivery() -> void:
	interact_field()
	if visor_hud != null:
		visor_hud.refresh()

func _perform_marker_and_map() -> void:
	if not field_ready:
		return
	coverage_map.bind_network(network)
	coverage_map.show()
	_map_viewed = true
	_update_objectives()
	_notice.text = "Coverage Map shows only structures you carried and placed in this sortie. E picks up the kit; M deploys at each marked site."

func _open_rover_planner() -> void:
	if route_planner != null:
		route_planner.bind_rover(rover)
		route_planner.bind_network(network)
		route_planner.show()
	_notice.text = "Choose a safe route, then walk up to the rover and press E."

func _on_route_confirmed(route_id: String, estimate: Dictionary) -> void:
	if not bool(estimate.get("accepted", false)):
		return
	_rover_route_confirmed = true
	rover.planned_route_id = route_id
	if route_planner != null:
		route_planner.hide()
	_notice.text = "Route %s confirmed. Walk up to the rover and press E to board." % route_id
	_update_objectives()

func advance_sortie_step() -> void:
	enter_field()

func complete_sortie() -> Dictionary:
	if _active_sortie.is_empty():
		return {}
	_update_objectives()
	if not field_ready or _step_index < 3:
		_notice.text = "Finish the field actions and return to the marked start before completing this sortie."
		return {}
	var sid := String(_active_sortie.get("id", "sortie_walk"))
	var lowest_suit := minf(eva_suit.oxygen, minf(eva_suit.power, eva_suit.cooling))
	var payload_ok := bool(payload_inventory.item("trainer_instrument_case").condition.intact)
	var report := progression.record_sortie_report({
		"id": sid, "title": String(_active_sortie.get("title", sid)), "chapter": 1,
		"actual_minutes": elapsed_s / 60.0, "planned_minutes": float(_active_sortie.get("planned_minutes", 15.0)),
		"payload_intact": payload_ok, "care_score": maxi(0, 100 - eva_suit.payload_scuffs * 10 - eva_suit.slip_count * 5),
		"science_score": mini(100, _scanner_pulses * 34) if sid == "sortie_scanner" else 100,
		"reserve_kept_pct": 100.0 * rover.battery / rover.battery_capacity if sid == "sortie_rover" else lowest_suit,
		"reserve_target_pct": 100.0 * rover.return_reserve / rover.battery_capacity if sid == "sortie_rover" else eva_suit.return_reserve_pct,
		"skill": String(_active_sortie.get("skill", "navigation")), "xp": 1,
	})
	_last_report = report.duplicate(true)
	results[sid] = _last_report.duplicate(true)
	var saved := _save_results()
	_notice.text = "Moon Trainer report card saved separately from your expedition." if saved.accepted else String(saved.reason)
	leave_field()
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
	if field_active and event.is_action_pressed("interact") and not event.is_echo():
		interact_field()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventJoypadButton and event.pressed and not _active_sortie.is_empty():
		var handled := true
		if event.button_index == JOY_BUTTON_START:
			leave_field() if field_active else enter_field()
		elif field_active and event.button_index == JOY_BUTTON_X and String(_active_sortie.get("id", "")) == "sortie_markers":
			_place_next_structure()
		elif field_active and event.button_index == JOY_BUTTON_Y and rover.aboard:
			vehicle.toggle_camera_view()
			_camera_switched = true
		else:
			handled = false
		if handled:
			get_viewport().set_input_as_handled()
			return
	if event is InputEventKey and event.pressed and not event.echo and not _active_sortie.is_empty():
		var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		var handled := true
		if key == KEY_TAB:
			leave_field() if field_active else enter_field()
		elif field_active and key == KEY_E:
			interact_field()
		elif field_active and key == KEY_M and String(_active_sortie.get("id", "")) == "sortie_markers":
			_place_next_structure()
		elif field_active and key == KEY_V and rover.aboard:
			vehicle.toggle_camera_view()
			_camera_switched = true
		elif field_active and key == KEY_L:
			rover.toggle_headlights() if rover.aboard else eva_suit.set("headlamp_on", not eva_suit.headlamp_on)
		else:
			handled = false
		if handled:
			get_viewport().set_input_as_handled()
			return
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
		if field_active:
			leave_field()
		elif _page == "catalog":
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
			if _page == "catalog":
				_scroll.scroll_vertical = 0
			return
