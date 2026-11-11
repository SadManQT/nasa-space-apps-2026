## M1-103: the reusable Class provider guards actual physical P-04 commits.
## Uses the real scene, route, dispatcher and isolated save/Continue boundary.
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
	if not storage.setup("class_campaign_guard"):
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	var campaign := await _spawn({"mode": "class", "players": 2})
	var id := "assign_date_token"
	var payload := {"value": "2034-04"}
	await _near(campaign, id)
	var before: Dictionary = campaign.director.snapshot()
	var held: Dictionary = campaign.perform_target(id, payload)
	_check(bool(held.get("class_team_plan_required", false)) and String(held.get("reason", "")).contains("unavailable"), "missing Class UI fails clearly at the actual physical target")
	_check(campaign.director.snapshot() == before, "an unsigned physical choice changes no live state")
	var requests: Array = []
	campaign.class_team_plan_requested.connect(func(view): requests.append(view))
	held = campaign.perform_target(id, payload)
	_check(bool(held.get("class_team_plan_required", false)) and requests.size() == 1, "physical commit requests the registered Class review provider")
	var review: Dictionary = requests[0]
	_check(review.required_roles.size() == 4 and review.crew.players == 2 and review.puzzle_id == "P-04", "two players still hold all four canonical roles")
	_check(not campaign.sign_class_team_plan("kai", id, payload, []).get("accepted", false), "malformed reviewed selection cannot sign")
	_check(not campaign.sign_class_team_plan("unknown", id, payload, review.selection).get("accepted", false), "an unknown role cannot sign")
	var changed: Dictionary = review.selection.duplicate(true)
	changed.forecast["reason"] = "A different forecast"
	_check(not campaign.sign_class_team_plan("kai", id, payload, changed).get("accepted", false), "changing a reviewed forecast invalidates the signature")
	_check(bool(campaign.sign_class_team_plan("kai", id, payload, review.selection).get("accepted", false)), "one current role can sign")
	var copy: Dictionary = campaign.class_team_plan_view(id, payload)
	copy.selection.payload["value"] = "HORT-01"
	copy.signed_roles.clear()
	_check(campaign.class_team_plan_view(id, payload).signed_roles == ["kai"], "mutating the primitive public view cannot change stored signatures")
	_check(not campaign.perform_target(id, payload).get("accepted", false), "one signature cannot authorize a physical commit")
	for role_id in ["amara", "mei", "rafi"]:
		_check(bool(campaign.sign_class_team_plan(role_id, id, payload, review.selection).get("accepted", false)), role_id + " signs the same live forecast")
	_check(bool(campaign.sign_class_team_plan("kai", id, payload, review.selection).get("duplicate", false)), "repeat signature is idempotent")
	campaign._player.global_position += Vector3(0, 0, 20)
	_check(not campaign.perform_target(id, payload).get("accepted", false), "four signatures never bypass physical range")
	await _near(campaign, id)
	campaign.cancel_class_team_plan()
	_check(campaign.class_team_plan_view(id, payload).signed_roles.is_empty(), "cancel invalidates every signature")
	await _sign_all(campaign, id, payload)
	var committed: Dictionary = campaign.perform_target(id, payload)
	_check(bool(committed.get("accepted", false)) and campaign.route.snapshot().p04.mapping.get("date", "") == "2034-04", "four current signatures commit the chosen token through the real route")
	_check(campaign.director.snapshot().receipts.size() == before.receipts.size() + 1, "the signed physical action charges exactly one receipt")
	_check(campaign._class_team_signoffs.is_empty(), "successful commit consumes all signatures")
	_check(not campaign.perform_target(id, payload).get("accepted", false) and campaign.director.snapshot().receipts.size() == before.receipts.size() + 1, "repeat physical commit cannot charge again")
	_check(bool(campaign.retry_checkpoint().get("accepted", false)) and campaign.route.snapshot().p04.mapping.is_empty(), "retry restores token progress and keeps the Class crew")
	_check(campaign.query().crew == {"mode": "class", "players": 2} and campaign._class_team_signoffs.is_empty(), "retry retains crew and clears ephemeral signatures")
	await _near(campaign, id)
	var stale_review: Dictionary = campaign.class_team_plan_view(id, payload)
	await _sign_all(campaign, id, payload)
	var other_id := "assign_device_token"
	var other_payload := {"value": "HORT-01"}
	var other: Dictionary = campaign.class_team_plan_view(other_id, other_payload)
	_check(other.signed_roles.is_empty() and other.stale_roles.size() == 4, "a different physical choice cannot reuse another target's signatures")
	# Another owner-side route command can change the revision while this
	# review is open. Drive that real command rather than injecting a snapshot.
	_check(bool(campaign.route.perform(other_id, other_payload).get("accepted", false)), "an authoritative intervening route command changes the live revision")
	await _near(campaign, id)
	_check(not campaign.sign_class_team_plan("kai", id, payload, stale_review.selection).get("accepted", false), "an actual intervening commit invalidates the old revision")
	await _sign_all(campaign, id, payload)
	_check(bool(campaign.save_campaign().get("accepted", false)), "pending signed choice saves through production storage")
	var loaded: Dictionary = SaveScript.new().load(storage.path)
	_check(bool(loaded.get("accepted", false)), "Continue can load the signed choice's checkpoint")
	var prior_selection: Dictionary = campaign.class_team_plan_view(id, payload).selection
	campaign.free()
	await process_frame
	if bool(loaded.get("accepted", false)):
		campaign = CampaignScene.instantiate() as Chapter1Campaign
		storage.configure(campaign)
		campaign.initial_snapshot = loaded.snapshot
		root.add_child(campaign)
		await process_frame
		_check(campaign.query().crew == {"mode": "class", "players": 2} and campaign._class_team_signoffs.is_empty(), "Continue restores the fixed crew without ephemeral signatures")
		campaign.free()
		await process_frame
	campaign = await _spawn({"mode": "class", "players": 3})
	_check(not campaign.sign_class_team_plan("kai", id, payload, prior_selection).get("accepted", false), "another fresh crew cannot reuse a previous crew's review")
	campaign.free()
	await process_frame
	campaign = await _spawn({"mode": "solo", "players": 1})
	await _near(campaign, id)
	_check(bool(campaign.perform_target(id, payload).get("accepted", false)), "Solo physical commits keep working without Class signatures")
	campaign.free()
	await process_frame
	storage.cleanup()
	print("CLASS CAMPAIGN GUARD RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _spawn(crew: Dictionary) -> Chapter1Campaign:
	var director := DirectorScript.new()
	director.new_campaign(CampaignContentFull.EXPECTED_CONTENT_REVISION, crew)
	var route := RouteScript.new(director)
	_check(bool(route.start_at("EX-CH02-S09").get("accepted", false)), "fixture enters the production P-04 scene")
	var state: Dictionary = director.snapshot()
	state["route_runtime"] = route.snapshot()
	state.route_runtime["chapter"] = 2
	var campaign := CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	campaign.initial_snapshot = state
	root.add_child(campaign)
	await process_frame
	_check(campaign.route != null and campaign.hud != null, "actual campaign creates its physical room and HUD")
	return campaign

func _sign_all(campaign: Chapter1Campaign, id: String, payload: Dictionary) -> void:
	var view: Dictionary = campaign.class_team_plan_view(id, payload)
	_check(bool(view.get("accepted", false)), "the real route provides a read-only Class forecast")
	if not bool(view.get("accepted", false)):
		return
	for role_id in view.required_roles:
		_check(bool(campaign.sign_class_team_plan(role_id, id, payload, view.selection).get("accepted", false)), role_id + " reviews the exact current choice")

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
	_check(campaign.nearby_target().get("target_id", "") == id, "physical selection matches " + id)

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)
