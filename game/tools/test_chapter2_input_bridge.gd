## M1-105: real nearby USE, read-only preview and explicit Chapter 2 commit.
extends SceneTree

const CampaignScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const RouteScript = preload("res://scripts/missions/chapter2_route.gd")
const SaveScript = preload("res://scripts/save/save_service.gd")
var storage = preload("res://tools/support/isolated_storage.gd").new()
var checks := 0
var failures := 0

func _init() -> void:
	CampaignCutscenePlayer.autoplay = false
	if not storage.setup("chapter2_input_bridge"):
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var campaign := await _spawn("EX-CH02-S04")
	if campaign == null:
		_finish()
		return
	var id := "p03_scan_tara"
	await _near(campaign, id)
	var before: Dictionary = campaign.director.snapshot()
	var route_before: Dictionary = campaign.route.snapshot()
	var absent: Dictionary = campaign.interact_nearby()
	_check(not absent.get("accepted", false) and String(absent.get("reason", "")).contains("unavailable"), "missing panel provider fails clearly and cannot auto-commit")
	_check(campaign.director.snapshot() == before and campaign.route.snapshot() == route_before, "missing provider does not change state")
	var requests: Array = []
	campaign.chapter2_panel_requested.connect(func(view): requests.append(view))
	var opened: Dictionary = campaign.interact_nearby()
	_check(bool(opened.get("chapter2_panel_requested", false)) and requests.size() == 1 and requests[0].target_id == id, "real nearby USE requests P-03 panel")
	_check(requests[0].action == "p03_scan_tara" and requests[0].progress is Dictionary and requests[0].input_revision == before.state_revision, "provider receives current primitive view")
	_check(campaign.director.snapshot() == before and campaign.route.snapshot() == route_before, "opening is read only")
	_check(not campaign.preview_chapter2_choice(id, {}).get("accepted", false), "preview requires open paused modal")
	campaign.set_ui_paused(true)
	var forecast: Dictionary = campaign.preview_chapter2_choice(id, {})
	_check(bool(forecast.get("accepted", false)) and forecast.input_revision == before.state_revision, "paused modal previews through the real restored route")
	_check(campaign.director.snapshot().receipts == before.receipts and campaign.route.snapshot() == route_before, "preview has no live receipt or puzzle progress")
	var approach_position: Vector3 = campaign._player.global_position
	campaign._player.global_position += Vector3(0, 0, 20)
	await physics_frame
	_check(not campaign.preview_chapter2_choice(id, {}).get("accepted", false) and campaign._chapter2_pending.get("previewed", "stale") == null, "moving away during a paused panel invalidates its preview")
	campaign._player.global_position = approach_position
	await physics_frame
	var camera: Camera3D = campaign._player.follow_camera.camera
	var target_node: Node3D = campaign.physical_target(id)
	camera.look_at(camera.global_position + (camera.global_position - target_node.global_position))
	await process_frame
	_check(not campaign.preview_chapter2_choice(id, {}).get("accepted", false), "looking away during a paused panel cannot preview the target")
	camera.look_at(target_node.global_position)
	await process_frame
	_check(bool(campaign.preview_chapter2_choice(id, {}).get("accepted", false)), "returning to the same physical target requires a fresh preview")
	_check(not campaign.confirm_chapter2_choice(id, {}).get("accepted", false), "paused modal cannot commit")
	campaign.set_ui_paused(false)
	campaign._player.global_position += Vector3(0, 0, 20)
	_check(not campaign.confirm_chapter2_choice(id, {}).get("accepted", false), "moving out of range invalidates confirmation")
	await _near(campaign, id)
	var committed: Dictionary = campaign.confirm_chapter2_choice(id, {})
	_check(bool(committed.get("accepted", false)) and campaign.route.current_flags().get("p03_scan_tara_done", false), "same chosen input commits at the real physical target")
	var receipts: Dictionary = campaign.director.snapshot().receipts.duplicate(true)
	_check(receipts.size() == before.receipts.size() + 1, "chosen commit charges one receipt")
	_check(not campaign.confirm_chapter2_choice(id, {}).get("accepted", false) and campaign.director.snapshot().receipts == receipts, "repeat confirmation cannot charge again")
	var saved: Dictionary = campaign.save_campaign()
	_check(bool(saved.get("accepted", false)), "chosen-input state saves")
	var loaded: Dictionary = SaveScript.new().load(storage.path)
	_check(bool(loaded.get("accepted", false)) and bool(loaded.snapshot.route_runtime.p03.completed_actions.has("p03_scan_tara")), "save contains authoritative P-03 progress")
	campaign.free()
	await process_frame
	var resumed := CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(resumed)
	resumed.initial_snapshot = loaded.get("snapshot", {})
	root.add_child(resumed)
	await process_frame
	_check(bool(resumed.route.current_flags().get("p03_scan_tara_done", false)) and resumed._chapter2_pending.is_empty(), "Continue restores progress without a pending modal")
	resumed.free()
	await process_frame

	var recorder := await _spawn("EX-CH02-S09")
	if recorder == null:
		_finish()
		return
	var token_id := "assign_date_token"
	await _near(recorder, token_id)
	var token_requests: Array = []
	recorder.chapter2_panel_requested.connect(func(view): token_requests.append(view))
	_check(bool(recorder.interact_nearby().get("chapter2_panel_requested", false)) and token_requests.size() == 1 and token_requests[0].required_inputs == ["value"], "P-04 token asks for selected value")
	recorder.set_ui_paused(true)
	var token_before: Dictionary = recorder.director.snapshot()
	_check(not recorder.preview_chapter2_choice(token_id, {}).get("accepted", false), "missing token is held")
	_check(not recorder.preview_chapter2_choice(token_id, {"value": "2035-04"}).get("accepted", false), "wrong plausible token is held")
	_check(recorder.director.snapshot() == token_before, "wrong and missing previews do not mutate")
	_check(bool(recorder.preview_chapter2_choice(token_id, {"value": "2034-04"}).get("accepted", false)), "source-supported token previews")
	_check(not recorder.preview_chapter2_choice(token_id, {"value": 42}).get("accepted", false), "malformed later choice is rejected")
	recorder.set_ui_paused(false)
	_check(not recorder.confirm_chapter2_choice(token_id, {"value": "2034-04"}).get("accepted", false), "malformed later choice clears the earlier accepted preview")
	recorder.set_ui_paused(true)
	_check(bool(recorder.preview_chapter2_choice(token_id, {"value": "2034-04"}).get("accepted", false)), "correct token must be previewed again after malformed input")
	recorder.set_ui_paused(false)
	_check(not recorder.confirm_chapter2_choice(token_id, {"value": "HORT-01"}).get("accepted", false), "changed choice cannot reuse a preview")
	_check(bool(recorder.confirm_chapter2_choice(token_id, {"value": "2034-04"}).get("accepted", false)), "correct explicit token commits")
	_check(recorder.route.snapshot().p04.mapping.get("date", "") == "2034-04", "P-04 authoritative mapping receives selected token")
	_check(bool(recorder.retry_checkpoint().get("accepted", false)) and recorder.route.snapshot().p04.mapping.is_empty(), "retry restores token and receipt atomically")
	await _near(recorder, token_id)
	recorder.interact_nearby()
	recorder.set_ui_paused(true)
	recorder.preview_chapter2_choice(token_id, {"value": "2034-04"})
	recorder.cancel_chapter2_choice()
	recorder.set_ui_paused(false)
	_check(not recorder.confirm_chapter2_choice(token_id, {"value": "2034-04"}).get("accepted", false) and recorder.route.snapshot().p04.mapping.is_empty(), "cancel leaves puzzle unsolved")
	recorder.free()
	await process_frame
	_finish()

func _spawn(scene_id: String) -> Chapter1Campaign:
	var director := DirectorScript.new()
	director.new_campaign(CampaignContentFull.EXPECTED_CONTENT_REVISION)
	var route := RouteScript.new(director)
	var moved: Dictionary = route.start_at(scene_id)
	_check(bool(moved.get("accepted", false)), "fixture projects into " + scene_id)
	if not bool(moved.get("accepted", false)):
		return null
	var state: Dictionary = director.snapshot()
	state["route_runtime"] = route.snapshot()
	state.route_runtime["chapter"] = 2
	var campaign := CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	campaign.initial_snapshot = state
	root.add_child(campaign)
	await process_frame
	_check(campaign.route != null and campaign.route.current_scene_id() == scene_id and campaign.hud != null, "production campaign opens " + scene_id)
	# This suite drives the campaign protocol itself; the HUD card has its own
	# wiring test (test_chapter2_panel_wiring.gd), so detach it here.
	for connection in campaign.chapter2_panel_requested.get_connections():
		campaign.chapter2_panel_requested.disconnect(connection.callable)
	return campaign

func _near(campaign: Chapter1Campaign, id: String) -> void:
	var target: Node3D = campaign.physical_target(id)
	_check(target != null, "physical target exists: " + id)
	if target == null:
		return
	var approach: Array = target.get_meta("approach_m", [])
	campaign._player.global_position = campaign._room.to_global(Vector3(float(approach[0]), float(approach[1]), float(approach[2]))) if approach.size() == 3 else target.global_position + Vector3(0, 0, 1)
	campaign._player.velocity = Vector3.ZERO
	await physics_frame
	campaign._player.follow_camera.camera.look_at(target.global_position)
	_check(campaign.nearby_target().get("target_id", "") == id, "nearby target selected: " + id)

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func _finish() -> void:
	storage.cleanup()
	print("CHAPTER 2 INPUT BRIDGE RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)
