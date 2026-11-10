extends SceneTree

const CampaignScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const Progression = preload("res://scripts/progression/cadet_progression.gd")
var checks := 0
var failures := 0
var storage = preload("res://tools/support/isolated_storage.gd").new()

func _init() -> void:
	if not storage.setup("campaign_progression"):
		quit(1)
		return
	CampaignCutscenePlayer.autoplay = false
	call_deferred("_run")

func _run() -> void:
	var unearned = Progression.new()
	_check(not bool(unearned.choose_upgrade(7, "A").get("accepted", false)), "A future upgrade cannot be granted without chapter-completion evidence")
	var campaign = CampaignScene.instantiate()
	storage.configure(campaign)
	root.add_child(campaign)
	await process_frame
	await process_frame
	_check(campaign.get("progression") != null, "Real campaign owns CadetProgression")
	_check(campaign.has_method("choose_upgrade"), "Real chapter transition exposes authoritative upgrade acquisition")
	if campaign.has_method("choose_upgrade"):
		var before: Dictionary = campaign.director.snapshot()
		var rejected: Dictionary = campaign.choose_upgrade(7, "A")
		_check(not bool(rejected.get("accepted", false)) and before == campaign.director.snapshot(), "Future upgrade rejection preserves authoritative state")
		var job: Dictionary = campaign.complete_job("CH01-DELIVERY", {})
		_check(not bool(job.get("accepted", false)), "A Jobs Board click without completed field work cannot grant a report or XP")
		_check(not bool(campaign.rest_at_bunk().get("accepted", false)), "Rest cannot claim a Safe Room save while standing in the Commons")
	var snapshot: Dictionary = campaign._save_snapshot()
	_check(snapshot.get("presentation_resume", {}).get("cadet_progression", null) is Dictionary, "Campaign checkpoints persist real cadet progression through the save API")
	await _test_physical_delivery(campaign)
	campaign.free()
	await process_frame
	storage.cleanup()
	print("CAMPAIGN PROGRESSION RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_physical_delivery(campaign: Node) -> void:
	var flow = campaign.get("progression_flow")
	_check(flow != null and flow.has_method("interact_job"), "the live campaign offers a physical optional-job lifecycle")
	if flow == null or not flow.has_method("interact_job"):
		return
	var began: Dictionary = campaign.call("begin_job", "JOB-CH01-03")
	_check(bool(began.get("accepted", false)), "the ration delivery starts at the Commons pickup fixture")
	if not bool(began.get("accepted", false)):
		return
	var forged: Dictionary = campaign.call("complete_job", "JOB-CH01-03", {"complete": true, "care_score": 100, "elapsed_seconds": 1})
	_check(not bool(forged.get("accepted", false)), "client-supplied completion and grades cannot replace field work")
	var target: Node3D = flow.job_target()
	_check(target != null, "an accepted delivery has a visible physical pickup marker")
	if target == null:
		return
	var player: Node3D = campaign.get("_player")
	player.global_position = target.global_position + Vector3(12, 0, 0)
	_check(not bool(flow.interact_job().get("accepted", false)), "the job refuses pickup outside physical interaction range")
	player.global_position = target.global_position + Vector3(0, 0, 1)
	var picked: Dictionary = flow.interact_job()
	_check(bool(picked.get("accepted", false)) and String(campaign.get("field_systems").inventory.item("job:JOB-CH01-03").get("place", "")) == "hands", "nearby pickup moves the real optional payload into the carry inventory")
	_check(not bool(campaign.call("job_metrics", "JOB-CH01-03").get("complete", false)), "pickup alone cannot finish delivery")
	for target_id in ["commission_route", "commission_result", "charter_card"]:
		var station: Node3D = campaign.call("physical_target", target_id)
		player.global_position = station.global_position + Vector3(0, 0, 1)
		var result: Dictionary = campaign.call("perform_target", target_id)
		_check(bool(result.get("accepted", false)), "delivery route preserves mandatory campaign action " + target_id)
	var advanced: Dictionary = campaign.call("advance_scene")
	_check(bool(advanced.get("accepted", false)), "the real campaign reaches the Safe Room while carrying the optional payload")
	await campaign.call("wait_loading")
	flow.step(1.0)
	target = flow.job_target()
	_check(target != null, "the delivery marker rebuilds at the Safe Room destination")
	if target == null:
		return
	player = campaign.get("_player")
	player.global_position = target.global_position + Vector3(0, 0, 1)
	_check(bool(flow.interact_job().get("accepted", false)), "the destination accepts the physically carried payload")
	var metrics: Dictionary = campaign.call("job_metrics", "JOB-CH01-03")
	var filed: Dictionary = campaign.call("complete_job", "JOB-CH01-03", metrics)
	_check(bool(metrics.get("complete", false)) and bool(filed.get("accepted", false)), "only completed field delivery can file the report and earn XP")
	_check(not bool(campaign.call("complete_job", "JOB-CH01-03", metrics).get("accepted", false)), "filing the same delivery twice cannot duplicate XP")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: " + message)
