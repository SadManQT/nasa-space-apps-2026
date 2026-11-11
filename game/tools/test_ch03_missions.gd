## Godot --headless --path game --script res://tools/test_ch03_missions.gd
## Windowed evidence: Godot --path game --resolution 1280x720 --script res://tools/test_ch03_missions.gd -- --evidence
## M3-3M: Chapter 3 missions EX-M0301..EX-M0304 (EX-CH03-S01..S12) played at
## their props in the production campaign. Every target is used through real
## nearby USE; P-05 and P-06 steps go through their decision cards with the
## supported choice or instrument reading. Checks rooms, rosters, dated time
## cards, retry and the boundary into Chapter 4.
extends SceneTree

const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const Chapter2Route = preload("res://scripts/missions/chapter2_route.gd")
const Chapter2Catalog = preload("res://scripts/missions/chapter2_gate_catalog.gd")
const RouteScript = preload("res://scripts/missions/extended_campaign_route.gd")
const GateCatalog = preload("res://scripts/missions/extended_gate_catalog.gd")
const RoomContract = preload("res://scripts/world/room_contract.gd")
const RosterScript = preload("res://scripts/companions/companion_roster.gd")
const Witness2 = preload("res://tools/support/chapter2_witness.gd")
const Witness3 = preload("res://tools/support/chapter3_witness.gd")
const CampaignScene: PackedScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const MISSIONS := ["EX-M0301", "EX-M0302", "EX-M0303", "EX-M0304"]
const EVIDENCE_AT := ["EX-CH03-S01", "EX-CH03-S04", "EX-CH03-S08", "EX-CH03-S12"]

var checks := 0
var failures := 0
var storage = preload("res://tools/support/isolated_storage.gd").new()
var retried_missions := {}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_structure()
	await _test_physical_play()
	print("CH03 MISSIONS RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _scenes() -> Array:
	return GateCatalog.scene_ids().filter(func(id): return String(id).begins_with("EX-CH03"))

func _test_structure() -> void:
	_check(_scenes().size() == 12, "Chapter 3 has twelve scenes")
	for scene_id in _scenes():
		var room_id := RoomContract.room_for_scene(scene_id)
		_check(not room_id.is_empty() and String(GateCatalog.gate(scene_id).get("room_id", room_id)) == room_id, scene_id + " plays in " + room_id)
		_check(MISSIONS.has(String(GateCatalog.gate(scene_id).get("mission_id", ""))), scene_id + " belongs to a Chapter 3 mission")
		var roster := RosterScript.scene_roster(scene_id)
		var playable := RosterScript.playable_actor(scene_id)
		_check(roster.has(playable) and String(roster[playable].physical_location_id) == room_id and bool(roster[playable].present), scene_id + " places playable " + playable + " in " + room_id)
		_check(GateCatalog.targets_for_scene(scene_id).size() >= 1, scene_id + " has physical targets")

func _test_physical_play() -> void:
	if not storage.setup("M3-3M-test"):
		_check(false, "isolated storage setup")
		return
	storage.prepare_rendering_cache()
	CampaignCutscenePlayer.autoplay = false
	var campaign := CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	campaign.initial_snapshot = _entry_snapshot()
	root.add_child(campaign)
	for i in 6:
		await physics_frame
	await campaign.wait_loading()
	campaign.hud.refresh_scene()
	await process_frame
	_check(campaign._startup_error.is_empty() and campaign.route.current_scene_id() == "EX-CH03-S01", "campaign boots at EX-CH03-S01")
	var evidence := OS.get_cmdline_user_args().has("--evidence") and DisplayServer.get_name() != "headless"
	if evidence:
		root.size = Vector2i(1280, 720)
	var last_date := ""
	for scene_id in _scenes():
		var room_id := RoomContract.room_for_scene(scene_id)
		_check(campaign.route.current_scene_id() == scene_id and campaign.route.current_room_id() == room_id, "campaign at %s in %s" % [scene_id, room_id])
		var date := String(campaign.director.snapshot().get("scenario_datetime", ""))
		_check(not date.is_empty() and date >= last_date, "%s time card %s does not run backwards" % [scene_id, date])
		last_date = date
		for target in GateCatalog.targets_for_scene(scene_id):
			var target_id := String(target.target_id)
			if not await _use(campaign, target):
				continue
			var mission_id := String(GateCatalog.gate(scene_id).get("mission_id", ""))
			if not retried_missions.has(mission_id):
				retried_missions[mission_id] = true
				var retried := campaign.retry_checkpoint()
				await campaign.wait_loading()
				_check(bool(retried.get("accepted", false)) and not _done(campaign, target), scene_id + " retry restores the state before " + target_id)
				_check(await _use(campaign, target), scene_id + " " + target_id + " commits again after retry")
		_close_cards(campaign)
		if evidence and EVIDENCE_AT.has(scene_id):
			for frame in 4:
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/M3-3M_%s.png" % scene_id))
		_check(bool(campaign.route.gate_status().get("ready", false)), scene_id + " gate ready after physical operations (missing %s)" % str(campaign.route.gate_status().get("missing", [])))
		await process_frame
		var moved := campaign.advance_scene()
		await campaign.wait_loading()
		if scene_id == "EX-CH03-S12":
			_check(bool(moved.get("chapter_complete", false)), "EX-CH03-S12 completes Chapter 3 (%s)" % JSON.stringify(moved).left(300))
		else:
			_check(bool(moved.get("accepted", false)), scene_id + " advances to the next scene (%s)" % JSON.stringify(moved).left(300))
		campaign.hud.refresh_scene()
		await process_frame
	_check(retried_missions.size() == 4, "retry was exercised once in each Chapter 3 mission")
	_close_cards(campaign)
	var offered: Array = []
	while campaign.available_upgrade_chapter() > 0 and offered.size() < 4:
		offered.append(campaign.available_upgrade_chapter())
		campaign.choose_upgrade(offered[-1], "A")
	await campaign.wait_loading()
	_check(offered.has(3) and campaign.available_upgrade_chapter() == 0, "the after-Chapter-3 upgrade is offered and chosen (%s)" % str(offered))
	_check(campaign.route.current_scene_id() == "EX-CH04-S01", "Chapter 4 starts at EX-CH04-S01 (at %s)" % campaign.route.current_scene_id())
	campaign.free()
	await process_frame
	storage.cleanup()

func _done(campaign: Chapter1Campaign, target: Dictionary) -> bool:
	return bool(campaign.director.snapshot().receipts.has(String(target.get("command_id", "physical:" + String(target.target_id)))))

## Uses one target through real nearby USE. P-05/P-06 targets open their card,
## where the supported option or reading is tried and locked in.
func _use(campaign: Chapter1Campaign, target: Dictionary) -> bool:
	var target_id := String(target.target_id)
	_close_cards(campaign)
	await _stand_at(campaign, target_id)
	var receipts := (campaign.director.snapshot().receipts as Dictionary).size()
	var used: Dictionary = campaign.interact_nearby()
	await process_frame
	if bool(used.get("chapter3_panel", false)):
		var panel: Chapter3PuzzlePanel = campaign.hud.chapter3_panel
		_check(panel.is_open() and panel.target_id() == target_id, target_id + " opens its decision card")
		_choose_supported(panel, target_id, Witness3.payload(target_id, campaign.director.snapshot()))
		var tried: Dictionary = panel.try_it()
		_check(bool(tried.get("accepted", false)), target_id + " supported choice previews (%s)" % String(panel._notice))
		panel.request_commit()
		var confirmed := panel.confirm_commit()
		await process_frame
		used = {"accepted": bool(confirmed.get("accepted", false))}
	var committed := bool(used.get("accepted", false)) and (campaign.director.snapshot().receipts as Dictionary).size() == receipts + 1
	_check(committed, target_id + " commits once at its prop" + ("" if committed else " -- " + String(used.get("reason", ""))))
	return committed

## `answer` is the supported payload (the witness adds the inspection phase the
## player must pick from the committed inspections).
func _choose_supported(panel: Chapter3PuzzlePanel, target_id: String, answer: Dictionary) -> void:
	var model: RefCounted = panel._model()
	var spec: Dictionary = model.step(target_id)
	match String(spec.get("kind", "")):
		"choice":
			for option in spec.get("options", []):
				var payload: Dictionary = option.get("payload", {})
				var matches := true
				for key in answer:
					if not payload.has(key) or not _same(payload[key], answer[key]):
						matches = false
				if matches:
					panel.choose("option", String(option.id))
					return
		"number":
			panel.choose("value", answer.get(String(spec.get("payload_key", "reading")), 0))
		"confirm":
			panel.choose("confirmed", true)

## JSON numbers parse as floats; compare values, not their text.
func _same(a, b) -> bool:
	if (a is int or a is float) and (b is int or b is float):
		return float(a) == float(b)
	if a is Array and b is Array:
		return a.size() == b.size() and range(a.size()).all(func(i): return _same(a[i], b[i]))
	return a == b

func _close_cards(campaign: Chapter1Campaign) -> void:
	if campaign.hud.chapter3_panel.is_open():
		campaign.hud.chapter3_panel.close()
	if not campaign.hud.panels.active_panel().is_empty():
		campaign.hud.panels.close_panel()

## Stands where a player would: the authored approach point first, then a ring
## of spots around the prop, until this job is the one offered.
func _stand_at(campaign: Chapter1Campaign, target_id: String) -> void:
	var target: Node3D = campaign.physical_target(target_id)
	if target == null:
		_check(false, "physical target exists: " + target_id)
		return
	var approach: Array = target.get_meta("approach_m", [])
	var spots: Array = [campaign._room.to_global(Vector3(float(approach[0]), float(approach[1]), float(approach[2]))) if approach.size() == 3 else target.global_position + Vector3(0, 0, 1)]
	for ring in [1.2, 2.0]:
		for step in 8:
			var angle := TAU * step / 8.0
			spots.append(Vector3(target.global_position.x + cos(angle) * ring, spots[0].y, target.global_position.z + sin(angle) * ring))
	for spot in spots:
		campaign._player.global_position = spot
		campaign._player.velocity = Vector3.ZERO
		for frame in 3:
			campaign._player.follow_camera.camera.look_at(target.global_position)
			await physics_frame
			if String(campaign.nearby_target().get("target_id", "")) == target_id:
				return
	_check(false, "nearby target selected: %s (got %s)" % [target_id, String(campaign.nearby_target().get("target_id", ""))])

func _entry_snapshot() -> Dictionary:
	var director := DirectorScript.new()
	director.new_campaign(CampaignContentFull.EXPECTED_CONTENT_REVISION)
	var handoff: Dictionary = director.snapshot()
	handoff["chapter1_ready"] = true
	director.restore_snapshot(handoff)
	var pollination := Chapter2Route.new(director)
	pollination.apply_entry_profile()
	pollination.start_at("EX-CH02-S01")
	for scene_id in Chapter2Catalog.SCENE_ORDER:
		for target in pollination.targets_for_current_scene():
			pollination.perform(target.target_id, Witness2.payload(String(target.get("puzzle_action", ""))))
		pollination.advance_scene()
	var route := RouteScript.new(director)
	route.start_at("EX-CH03-S01")
	var state: Dictionary = director.snapshot()
	state["route_runtime"] = route.snapshot()
	state.route_runtime["chapter"] = 3
	return JSON.parse_string(JSON.stringify(state))

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("  FAIL: " + message)
