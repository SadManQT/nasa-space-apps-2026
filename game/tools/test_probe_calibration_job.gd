## Godot --headless --path game --script res://tools/test_probe_calibration_job.gd
## M1-108: one opening retrieve-and-place job (probe dry zero at the bench,
## EX-CH01-S03). The transfer must gate the existing calibrate_probe
## completion exactly once; ownership must survive cancel/save/retry; the
## world, held and destination representations must stay consistent.
extends SceneTree

const Job = preload("res://scripts/payload/probe_calibration_job.gd")
const RouteScript = preload("res://scripts/missions/chapter1_route.gd")
const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const PlantInput = preload("res://tools/support/p01_input_fixture.gd")

var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_job_lifecycle()
	_job_cancel_and_retry()
	_job_snapshot_restore()
	_route_gate()
	_route_save_compat()
	print("PROBE CALIBRATION JOB RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _job_lifecycle() -> void:
	var job := Job.new()
	_check(job.state() == "at_rack" and not job.completed() and job.probe_place() == "ground" and not job.held(), "fresh probe waits on its rack")
	_check(float(job.reading().raw_reading) == 10.0 and job.reading().calibrated_reading == null, "uncalibrated probe shows the raw dry offset 10, no calibrated zero yet")
	_check(job.set_zero_payload().is_empty(), "no set_zero payload exists before the transfer")
	_check(not bool(job.place_at_bench().accepted) and job.state() == "at_rack", "cannot place a probe that was never retrieved")
	_check(not bool(job.observe_zero().accepted) and not job.completed(), "cannot observe a zero before the probe is at the bench")
	var ui_text: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/campaign/content/ui_text.json"))
	var canon: Dictionary = ui_text.targets.calibrate_probe
	var brief: Dictionary = job.brief()
	_check(brief.goal == canon.goal and brief.why == canon.why and brief.prompt == canon.prompt and brief.result == canon.result and brief.hint == canon.hint, "brief reuses the canonical calibrate_probe teaching text")
	_check(String(job.view().source) == "rack" and String(job.view().destination) == "bench" and String(job.view().prop_scene_path).ends_with("PR_VaultProbe.glb"), "view names the rack source, bench destination and existing probe prop")
	_check(int(job.hold_pose()) == int(PlayerAnimation.Hold.RIGHT), "held probe uses the single-hand RIGHT grip, not the two-handed case pose")
	var profile: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/campaign/profiles/p01_commission_plant.json"))
	_check(float(profile.references.dry.raw) == 10.0 and float(profile.references.dry.calibrated) == 0.0, "canon dry reference is raw 10 to calibrated 0")
	var retrieved: Dictionary = job.retrieve()
	_check(bool(retrieved.accepted) and job.state() == "held" and job.probe_place() == "hands" and job.held(), "retrieve takes the probe from the rack into the hands")
	_check(not bool(job.retrieve().accepted) and job.state() == "held" and job.probe_place() == "hands", "second retrieve cannot duplicate the carried probe")
	_check(not bool(job.observe_zero().accepted) and not job.completed(), "zero cannot be observed while the probe is still carried")
	var placed: Dictionary = job.place_at_bench()
	_check(bool(placed.accepted) and job.state() == "at_bench" and job.probe_place() == "delivered" and not job.held(), "place sets the probe in the bench cradle and frees the hands")
	_check(not bool(job.place_at_bench().accepted) and job.probe_place() == "delivered", "placed probe cannot be placed again")
	var observed: Dictionary = job.observe_zero()
	_check(bool(observed.accepted) and job.completed() and job.state() == "zeroed", "observing at the bench completes the dry zero exactly once")
	_check(float(job.reading().calibrated_reading) == 0.0 and float(job.reading().raw_reading) == 10.0, "completed reading shows raw 10 settled to calibrated 0")
	_check(job.set_zero_payload() == {"reference": "dry", "raw_reading": 10, "calibrated_reading": 0}, "completed job mints the exact P-01 set_zero payload")
	_check(job.set_zero_payload() == PlantInput.payload("calibrate_probe"), "job payload matches the documented set_zero witness input")
	_check(not bool(job.observe_zero().accepted) and not bool(job.retrieve().accepted) and not bool(job.place_at_bench().accepted) and job.completed(), "completion cannot be repeated or restarted")
	_check(not bool(job.cancel().accepted) and job.completed(), "a completed calibration cannot be cancelled away")
	var detached: Dictionary = job.inventory.item("probe")
	detached.place = "ground"
	_check(job.probe_place() == "delivered", "detached inventory readouts cannot mutate probe ownership")

func _job_cancel_and_retry() -> void:
	var job := Job.new()
	_check(not bool(job.cancel().accepted) and job.state() == "at_rack", "cancel with the probe on its rack changes nothing")
	job.retrieve()
	var cancelled: Dictionary = job.cancel()
	_check(bool(cancelled.accepted) and job.state() == "at_rack" and job.probe_place() == "ground", "cancel while carried returns the probe to its rack")
	_check(bool(job.retrieve().accepted) and bool(job.place_at_bench().accepted), "retry after cancel reaches the bench again")
	var kept: Dictionary = job.cancel()
	_check(bool(kept.accepted) and job.state() == "at_bench" and job.probe_place() == "delivered", "cancel after placement keeps the probe in the bench cradle")
	_check(bool(job.observe_zero().accepted) and job.completed(), "a kept placement still completes on observation")

func _job_snapshot_restore() -> void:
	for stage in ["at_rack", "held", "at_bench", "zeroed"]:
		var job := Job.new()
		if stage in ["held", "at_bench", "zeroed"]:
			job.retrieve()
		if stage in ["at_bench", "zeroed"]:
			job.place_at_bench()
		if stage == "zeroed":
			job.observe_zero()
		var saved: Dictionary = job.snapshot()
		var round_tripped: Dictionary = JSON.parse_string(JSON.stringify(saved))
		var restored := Job.new()
		_check(bool(restored.restore(round_tripped).accepted) and restored.snapshot() == saved and restored.state() == stage and restored.probe_place() == job.probe_place() and restored.completed() == job.completed(), "snapshot restores the " + stage + " stage through JSON")
		var before: Dictionary = job.snapshot()
		for bad in [
			{"state": "on_the_moon", "probe_place": "ground", "completed": false},
			{"state": "held", "probe_place": "ground", "completed": false},
			{"state": "at_bench", "probe_place": "hands", "completed": false},
			{"state": "zeroed", "probe_place": "delivered", "completed": false},
			{"state": "at_rack", "probe_place": "ground", "completed": true},
			{"state": "held", "probe_place": "hands"},
			{"probe_place": "ground", "completed": false},
		]:
			_check(not bool(job.restore(bad).accepted) and job.snapshot() == before, "malformed snapshot refuses without changing the job: " + str(bad))
		_check(not bool(job.restore("not a dictionary").accepted) and job.snapshot() == before, "non-dictionary snapshot refuses without changing the job")
	var legacy := Job.new()
	_check(bool(legacy.restore_legacy_zero(true).accepted) and legacy.completed() and legacy.probe_place() == "delivered", "pre-job save with the zero already set adopts the completed transfer")
	var fresh_legacy := Job.new()
	_check(bool(fresh_legacy.restore_legacy_zero(false).accepted) and not fresh_legacy.completed() and fresh_legacy.state() == "at_rack", "pre-job save without the zero starts at the rack")

func _route_gate() -> void:
	var route := RouteScript.new(DirectorScript.new())
	_check(bool(route.start_at("EX-CH01-S03").get("accepted", false)), "route starts at the calibration scene")
	var view: Dictionary = route.p01_view("calibrate_probe")
	_check(bool(view.get("accepted", false)) and bool(view.has("probe_job")) and not bool(view.probe_job.completed) and String(view.probe_job.state) == "at_rack", "panel query exposes the unfinished probe transfer")
	var before: Dictionary = route.snapshot()
	var refused: Dictionary = route.perform("calibrate_probe", PlantInput.payload("calibrate_probe"))
	_check(not bool(refused.accepted) and String(refused.get("reason", "")).contains("rack") and String(refused.get("reason", "")).contains("bench"), "set_zero refuses before the transfer with a plain-language reason")
	_check(route.snapshot() == before, "refused calibration leaves route, flags and receipts untouched")
	_check(not bool(route.p01_view("calibrate_probe").probe_job.completed), "refusal does not advance the job")
	var transferred: Dictionary = PlantInput.complete_probe_transfer(route)
	_check(bool(transferred.accepted) and route.probe_job().completed() and route.probe_job().probe_place() == "delivered", "fixture transfer completes the physical job on the route")
	var committed: Dictionary = route.perform("calibrate_probe", PlantInput.payload("calibrate_probe"))
	_check(bool(committed.accepted) and bool(route.snapshot().p01.probe_zeroed) and int(route.snapshot().p01.receipts.size()) == 1, "transfer gates exactly one set_zero commit with one receipt")
	_check(bool(route.current_flags().get("probe_zero_observed", false)), "completed transfer marks the observed-zero evidence flag")
	var duplicate: Dictionary = route.perform("calibrate_probe", PlantInput.payload("calibrate_probe"))
	_check(bool(duplicate.accepted) and int(route.snapshot().p01.receipts.size()) == 1 and route.probe_job().completed(), "duplicate calibration replays the one receipt and never re-runs the transfer")
	_check(bool(route.perform("span_probe", PlantInput.payload("span_probe")).accepted), "span follows the gated zero in the canonical order")
	_check(bool(route.perform("recheck_probe", PlantInput.payload("recheck_probe")).accepted) and bool(route.perform("inspect_packet", PlantInput.payload("inspect_packet")).accepted) and bool(route.perform("compare_atmosphere", PlantInput.payload("compare_atmosphere")).accepted), "rest of the scene still completes after the gated zero")
	_check(bool(route.gate_status().get("ready", false)), "scene gate is ready after the gated calibration chain")
	# Mid-transfer save/retry: the carried probe survives a route restore.
	var held_route := RouteScript.new(DirectorScript.new())
	held_route.start_at("EX-CH01-S03")
	held_route.probe_job().retrieve()
	var held_snapshot: Dictionary = JSON.parse_string(JSON.stringify(held_route.snapshot()))
	var resumed := RouteScript.new(DirectorScript.new())
	_check(bool(resumed.restore(held_snapshot).accepted), "route restores a mid-transfer snapshot")
	_check(resumed.probe_job().state() == "held" and resumed.probe_job().probe_place() == "hands" and not resumed.probe_job().completed(), "restored job still holds the carried probe")
	_check(not bool(resumed.perform("calibrate_probe", PlantInput.payload("calibrate_probe")).accepted), "a merely carried probe still cannot set the zero after restore")
	_check(bool(PlantInput.complete_probe_transfer(resumed).accepted) and bool(resumed.perform("calibrate_probe", PlantInput.payload("calibrate_probe")).accepted), "retry after restore finishes the transfer and commits once")

func _route_save_compat() -> void:
	var route := RouteScript.new(DirectorScript.new())
	route.start_at("EX-CH01-S03")
	PlantInput.complete_probe_transfer(route)
	route.perform("calibrate_probe", PlantInput.payload("calibrate_probe"))
	var saved: Dictionary = JSON.parse_string(JSON.stringify(route.snapshot()))
	_check(bool(saved.has("probe_job")), "new saves record the probe transfer")
	saved.erase("probe_job")
	var legacy := RouteScript.new(DirectorScript.new())
	_check(bool(legacy.restore(saved).accepted) and legacy.probe_job().completed(), "pre-job save with the zero set restores with the transfer adopted as done")
	var fresh := RouteScript.new(DirectorScript.new())
	fresh.start_at("EX-CH01-S03")
	var fresh_saved: Dictionary = JSON.parse_string(JSON.stringify(fresh.snapshot()))
	fresh_saved.erase("probe_job")
	var legacy_fresh := RouteScript.new(DirectorScript.new())
	_check(bool(legacy_fresh.restore(fresh_saved).accepted) and not legacy_fresh.probe_job().completed() and legacy_fresh.probe_job().state() == "at_rack", "pre-job save without the zero restores at the rack")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)
