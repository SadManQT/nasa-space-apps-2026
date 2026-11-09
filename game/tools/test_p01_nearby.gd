extends SceneTree

const Scene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const Inputs = preload("res://tools/support/p01_input_fixture.gd")
const Gates = preload("res://scripts/missions/chapter1_gate_catalog.gd")
var storage = preload("res://tools/support/isolated_storage.gd").new()
var checks := 0
var failures := 0

func _init() -> void:
	CampaignCutscenePlayer.autoplay = false
	call_deferred("_run")

func _run() -> void:
	_check(storage.setup("p01_nearby"), "isolated player storage")
	root.size = Vector2i(1280, 720)
	var campaign = Scene.instantiate()
	storage.configure(campaign)
	root.add_child(campaign)
	await process_frame
	for scene in ["EX-CH01-S01", "EX-CH01-S02"]:
		for spec in Gates.targets_for_scene(scene):
			_check(bool(campaign.route.perform(String(spec.target_id)).get("accepted", false)), "reach calibration via " + String(spec.target_id))
		_check(bool(campaign.route.advance_scene().get("accepted", false)), "normal opening scene advance")
	await _refresh(campaign)
	await _near(campaign, "span_probe")
	_check(campaign.p01_view("span_probe").missing_flags == ["p01_zeroed"], "unset dry zero cannot satisfy the wet-span prerequisite")
	_check(campaign.nearby_target().get("target_id", "") != "span_probe", "unsatisfied prerequisites keep the next step unavailable")
	for id in ["calibrate_probe", "span_probe", "recheck_probe", "inspect_packet", "compare_atmosphere"]:
		_check(bool(campaign.route.perform(id, Inputs.payload(id)).get("accepted", false)), "real calibration/scan " + id)
	_check(bool(campaign.route.advance_scene().get("accepted", false)), "normal route advance reaches planting")
	await _refresh(campaign)
	_check(campaign.route.current_flags().is_empty() and campaign.p01_view("plant_alo").missing_flags.is_empty(), "previous-scene scan is authoritative without local planting flags")
	var requests: Array = []
	campaign.p01_panel_requested.connect(func(view): requests.append(view))
	for id in ["plant_alo", "plant_tara"]:
		await _near(campaign, id)
		var before: Dictionary = campaign.route.snapshot()
		var state: Dictionary = campaign.director.snapshot()
		_check(campaign.nearby_target().get("target_id", "") == id, "previous-scene scan makes nearby planting eligible: " + id)
		var count := requests.size()
		var result: Dictionary = campaign.interact_nearby()
		_check(bool(result.get("p01_panel_requested", false)) and requests.size() == count + 1 and requests.back().target_id == id, "nearby USE requests the chosen-input panel exactly once: " + id)
		_check(campaign.route.snapshot() == before and campaign.director.snapshot() == state, "USE does not auto-plant or spend a receipt")
		# The UI may be present in future integration; close it before geometry checks.
		var panel = campaign.hud.get("p01_panel")
		if panel != null and panel.is_open():
			panel.discard()
		if campaign.hud.panels.hint_player.is_open():
			campaign.hud.panels.hint_player.close()
	var target: Node3D = campaign.physical_target("plant_alo")
	await _near(campaign, "plant_alo")
	campaign._player.global_position += Vector3(0, 0, 20)
	_check(campaign.nearby_target().get("target_id", "") != "plant_alo", "out-of-range planting rejects")
	await _near(campaign, "plant_alo")
	var camera: Camera3D = campaign._player.follow_camera.camera
	camera.look_at(camera.global_position + (camera.global_position - target.global_position))
	_check(campaign.nearby_target().get("target_id", "") != "plant_alo", "planting behind the camera rejects")
	await _near(campaign, "plant_alo")
	var obstacle := StaticBody3D.new()
	obstacle.collision_layer = campaign._player.collision_mask
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.6, 0.6, 0.6)
	collision.shape = box
	obstacle.add_child(collision)
	campaign.add_child(obstacle)
	obstacle.global_position = (campaign._player.global_position + Vector3.UP * 1.4 + target.global_position) * 0.5
	await physics_frame
	_check(campaign.nearby_target().get("target_id", "") != "plant_alo", "blocked line of sight rejects")
	obstacle.free()
	await physics_frame
	await _near(campaign, "plant_alo")
	_check(bool(campaign.perform_target("plant_alo", Inputs.payload("plant_alo")).get("accepted", false)), "explicit chosen input still commits through physical validation")
	_check(campaign.nearby_target().get("target_id", "") != "plant_alo", "completed target is not offered again")
	campaign.free()
	await process_frame
	storage.cleanup()
	print("P01 NEARBY RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _refresh(campaign) -> void:
	campaign._sync_route_projection()
	campaign._refresh_world()
	campaign.hud.refresh_scene()
	await physics_frame

func _near(campaign, id: String) -> void:
	var target: Node3D = campaign.physical_target(id)
	campaign._player.global_position = target.global_position + Vector3(0, 0, 1)
	campaign._player.velocity = Vector3.ZERO
	await physics_frame
	campaign._player.follow_camera.camera.look_at(target.global_position)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)
