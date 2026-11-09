extends SceneTree
const Director = preload("res://scripts/core/campaign_director.gd")
const Route = preload("res://scripts/missions/chapter1_route.gd")
const Inputs = preload("res://tools/support/p01_input_fixture.gd")
const CampaignScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
var checks := 0
var failures := 0
var storage = preload("res://tools/support/isolated_storage.gd").new()

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var route := _fresh()
	var view: Dictionary = route.p01_view("calibrate_probe")
	_check(view.accepted and view.profile.references.dry.raw == 10 and view.profile.references.wet.raw == 110, "query exposes documented references")
	view.state.probe_zeroed = true
	_check(not route.snapshot().p01.probe_zeroed, "query returns detached state")
	_check(not route.p01_view("plant_alo").accepted, "query rejects target from another scene")
	_check(route.p01_view("span_probe").missing_flags == ["p01_zeroed"] and not route.p01_view("span_probe").prerequisite_reason.is_empty(), "panel query explains missing zero")
	_check(route.p01_view("recheck_probe").missing_flags == ["p01_spanned"], "panel query explains missing span")
	for target in ["calibrate_probe", "span_probe", "recheck_probe"]:
		var valid := Inputs.payload(target)
		var spoofed := valid.duplicate()
		spoofed["_command_id"] = "physical:calibrate_probe" if target != "calibrate_probe" else "unrelated-command"
		_rejected_unchanged(route, target, spoofed)
		_rejected_unchanged(route, target, {})
		for field in valid:
			var missing := valid.duplicate()
			missing.erase(field)
			_rejected_unchanged(route, target, missing)
			if field == "reference":
				var wrong := valid.duplicate()
				wrong[field] = "wet" if target == "calibrate_probe" else "dry"
				_rejected_unchanged(route, target, wrong)
				continue
			for value in [-1, 7, INF, -INF, NAN, "0", true, {}, null]:
				var invalid := valid.duplicate()
				invalid[field] = value
				_rejected_unchanged(route, target, invalid)
		_preview_cancel(route, target, valid)
		_check(route.perform(target, valid).accepted, "explicit reference commits " + target)
		_duplicate(route, target, valid)
		_check(route.p01_view(target).missing_flags.is_empty(), "reopened query has no stale prerequisite " + target)
	_check(route.perform("inspect_packet").accepted, "packet can be scanned after explicit recheck")
	_check(route.perform("compare_atmosphere").accepted and route.advance_scene().accepted, "real gate enters planting scene")
	for target in ["plant_alo", "plant_tara"]:
		for payload in [{}, {"seed_count": 1}, {"cassette": "wrong", "seed_count": 1}, {"cassette": target.trim_prefix("plant_"), "seed_count": 2}, {"cassette": target.trim_prefix("plant_"), "seed_count": 1.5}, {"cassette": target.trim_prefix("plant_"), "seed_count": INF}]:
			_rejected_unchanged(route, target, payload)
		_check(route.perform(target, Inputs.payload(target)).accepted, "explicit single seed commits " + target)
		_duplicate(route, target, Inputs.payload(target))
	for target in ["water_alo", "water_tara"]:
		_rejected_unchanged(route, target, {})
		for value in [39, 39.99, 60.01, 61, INF, -INF, NAN, "50", true, {}, null]:
			_rejected_unchanged(route, target, {"moisture": value})
		var value := 40 if target == "water_alo" else 60
		_preview_cancel(route, target, {"moisture": value})
		_check(route.perform(target, {"moisture": value}).accepted, "inclusive watering boundary " + str(value))
		_duplicate(route, target, {"moisture": value})
	for target in ["label_alo", "label_tara", "seal_alo", "seal_tara"]:
		_check(route.perform(target, Inputs.payload(target)).accepted, "explicit label/seal action " + target)
	_check(route.snapshot().p01.receipts.size() == 12 and route.p01_view("seal_tara").completion.complete, "exactly twelve P-01 receipts complete the puzzle")
	var resumed := _fresh()
	_check(resumed.director().restore_snapshot(JSON.parse_string(JSON.stringify(route.director().snapshot()))).accepted, "director JSON round trip")
	_check(resumed.restore(JSON.parse_string(JSON.stringify(route.snapshot()))).accepted, "route JSON round trip")
	_check(resumed.snapshot().p01 == route.snapshot().p01, "all calibration/seeds/moisture/receipts survive reload")
	_duplicate(resumed, "seal_tara", {})
	var fractional = preload("res://scripts/missions/p01_commission_plant.gd").new()
	for action in ["set_zero", "set_span", "recheck", "scan_packet", "plant_alo", "plant_tara"]:
		_check(fractional.commit(action, action, Inputs.payload(action)).accepted, "fractional fixture " + action)
	_check(fractional.commit("water_alo", "fractional", {"moisture": 40.5}).accepted and fractional.snapshot().moisture_alo == 40.5, "fractional in-band reading is not truncated")
	_check(fractional.restore(JSON.parse_string(JSON.stringify(fractional.snapshot()))).accepted, "fractional state survives JSON restore")
	await _physical_use()
	storage.cleanup()
	print("P01 INPUTS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _fresh() -> RefCounted:
	var director := Director.new()
	director.new_campaign()
	var route := Route.new(director)
	_reach_calibration(route)
	return route

func _reach_calibration(route: RefCounted) -> void:
	for scene in ["EX-CH01-S01", "EX-CH01-S02"]:
		for spec in preload("res://scripts/missions/chapter1_gate_catalog.gd").targets_for_scene(scene):
			_check(route.perform(String(spec.target_id)).accepted, "reach calibration via " + String(spec.target_id))
		_check(route.advance_scene().accepted, "advance fixture " + scene)

func _rejected_unchanged(route: RefCounted, target: String, payload: Dictionary) -> void:
	var before: Dictionary = route.snapshot()
	var state: Dictionary = route.director().snapshot()
	var result: Dictionary = route.perform(target, payload)
	_check(not result.accepted and not String(result.get("reason", "")).is_empty(), "invalid input gives retry feedback " + target)
	_check(route.snapshot() == before and route.director().snapshot() == state, "rejection preserves route, costs, flags and receipts " + target)

func _preview_cancel(route: RefCounted, target: String, payload: Dictionary) -> void:
	var before: Dictionary = route.snapshot()
	var state: Dictionary = route.director().snapshot()
	route.focus(target)
	route.use(payload)
	_check(route.preview().accepted, "explicit preview accepted " + target)
	route.cancel_interaction()
	_check(not route.confirm().accepted, "cancel prevents confirmation " + target)
	_check(route.snapshot() == before and route.director().snapshot() == state, "preview/cancel preserve authoritative state " + target)
	route.focus(target)
	route.use(payload)
	_check(route.preview().accepted, "reopened preview accepted " + target)
	_check(not route.confirm("foreign-receipt").accepted and route.snapshot() == before and route.director().snapshot() == state, "confirm cannot override P-01 receipt identity " + target)
	route.cancel_interaction()

func _duplicate(route: RefCounted, target: String, payload: Dictionary) -> void:
	var before: Dictionary = route.snapshot()
	var state: Dictionary = route.director().snapshot()
	_check(route.perform(target, payload).accepted, "duplicate returns existing result " + target)
	_check(route.snapshot() == before and route.director().snapshot() == state, "duplicate adds no action/cost/receipt " + target)

func _physical_use() -> void:
	_check(storage.setup("p01_inputs"), "isolated save storage")
	var campaign = CampaignScene.instantiate()
	storage.configure(campaign)
	root.add_child(campaign)
	await process_frame
	_reach_calibration(campaign.route)
	campaign._sync_route_projection()
	campaign._refresh_world()
	await physics_frame
	var target: Node3D = campaign.physical_target("calibrate_probe")
	campaign._player.global_position = target.global_position + Vector3(0, 0, 1)
	campaign._player.velocity = Vector3.ZERO
	var camera: Camera3D = campaign._player.get_viewport().get_camera_3d()
	camera.look_at(target.global_position)
	await physics_frame
	var requests: Array = []
	campaign.p01_panel_requested.connect(func(view): requests.append(view))
	var before: Dictionary = campaign.route.snapshot()
	var state: Dictionary = campaign.director.snapshot()
	var result: Dictionary = campaign.interact_nearby()
	_check(result.get("p01_panel_requested", false) and requests.size() == 1, "physical USE requests P-01 panel")
	_check(campaign.route.snapshot() == before and campaign.director.snapshot() == state, "physical USE never solves calibration")
	_check(not campaign.perform_target("calibrate_probe").accepted, "physical commit without inputs rejects")
	var forecast: Dictionary = campaign.forecast_target("calibrate_probe", Inputs.payload("calibrate_probe"))
	_check(forecast.accepted and forecast.get("p01", {}).get("state", {}).get("probe_zeroed", false), "campaign forecast exposes projected P-01 state: " + str(forecast))
	_check(campaign.route.snapshot() == before and campaign.director.snapshot() == state, "campaign forecast has no live mutation")
	_check(campaign.perform_target("calibrate_probe", Inputs.payload("calibrate_probe")).accepted, "physical input commits through existing proximity checks")
	campaign.free()
	await process_frame

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL " + message)
