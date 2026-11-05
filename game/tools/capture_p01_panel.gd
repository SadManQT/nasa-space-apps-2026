## Windowed M1-08 evidence: the P-01 Commissioning & Planting Bench in the real campaign.
## Run after run_tests.sh has imported assets:
##   python3 production/tools/heavy.py /Users/sadmansakib/nasa-space-apps-2026/production/tools/godot_gated --path game --windowed --script res://tools/capture_p01_panel.gd
## Writes production/qa/evidence/M1-08_*.png and M1-08_capture_probe.txt.
extends SceneTree

const CampaignScene = preload("res://scenes/campaign/chapter1_campaign.tscn")
const GateCatalog = preload("res://scripts/missions/chapter1_gate_catalog.gd")

var storage = preload("res://tools/support/isolated_storage.gd").new()
var campaign: Chapter1Campaign
var failures := 0
var probe: Array = []

func _init() -> void:
	if not storage.setup("M1-08-capture"):
		quit(1)
		return
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.always_on_top = true
	root.grab_focus()
	CampaignCutscenePlayer.autoplay = false
	campaign = CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	root.add_child(campaign)
	await process_frame
	await _goto("EX-CH01-S03")
	await _capture("s03_hud_bench_buttons")

	var bench := campaign.hud.p01_panel
	_expect(campaign.hud.open_p01_panel("calibrate_probe"), "HUD opens P-01 Commissioning Bench for calibrate_probe")
	_expect((bench.find_child("Commit", true, false) as Button).disabled, "Commit starts disabled on uncalibrated +10 probe")
	await _capture("s03_calibration_bench")

	bench.choose_prediction("reads_10")
	bench.select_cup("dry")
	bench.choose_zero_offset(-10)
	var zero_prev: Dictionary = bench.preview()
	_expect(bool(zero_prev.get("accepted", false)), "Zero offset -10 (dry = 0) preview accepted")
	bench.request_commit()
	await _capture("s03_zero_preview_confirm")
	await _stand_at("calibrate_probe")
	bench.confirm_commit()
	await process_frame
	_expect(bool(campaign.route.p01_bench_view("calibrate_probe").p01.probe_zeroed), "calibrate_probe committed through physical station")

	# Step 2 (Span) & Step 3 (Recheck) & Step 4 (Packet Scan)
	_expect(campaign.hud.open_p01_panel("span_probe"), "HUD opens bench for span_probe")
	bench.select_cup("wet")
	bench.choose_wet_span(100)
	bench.preview()
	bench.request_commit()
	await _stand_at("span_probe")
	bench.confirm_commit()
	await process_frame

	_expect(campaign.hud.open_p01_panel("recheck_probe"), "HUD opens bench for recheck_probe")
	bench.verify_recheck_cup("both", true)
	bench.preview()
	bench.request_commit()
	await _stand_at("recheck_probe")
	bench.confirm_commit()
	await process_frame

	_expect(campaign.hud.open_p01_panel("inspect_packet"), "HUD opens bench for inspect_packet")
	bench.choose_scan_mode("sealed_optical")
	bench.preview()
	await _capture("s03_recheck_and_packet")
	bench.request_commit()
	await _stand_at("inspect_packet")
	bench.confirm_commit()
	await process_frame

	await _stand_at("compare_atmosphere")
	campaign.perform_target("compare_atmosphere")
	campaign.advance_scene()
	await campaign.wait_loading()
	campaign.hud.refresh_scene()
	await process_frame

	# EX-CH01-S04: Plant Alo & Tara, then show Flooding (>60) + Hints + Drain to Waste
	_expect(campaign.route.current_scene_id() == "EX-CH01-S04", "advanced to EX-CH01-S04")
	campaign.hud.open_p01_panel("plant_alo")
	bench.choose_prediction("paired_control")
	bench.choose_cassette_seeds("alo", 1)
	bench.preview()
	bench.request_commit()
	await _stand_at("plant_alo")
	bench.confirm_commit()
	await process_frame

	campaign.hud.open_p01_panel("plant_tara")
	bench.choose_cassette_seeds("tara", 1)
	bench.preview()
	bench.request_commit()
	await _stand_at("plant_tara")
	bench.confirm_commit()
	await process_frame

	_expect(campaign.hud.open_p01_panel("water_alo"), "HUD opens bench for water_alo")
	bench.choose_cassette_moisture("alo", 75)
	bench.reveal_hint()
	bench.reveal_hint()
	bench.reveal_hint()
	var flood_prev: Dictionary = bench.preview()
	_expect(not bool(flood_prev.get("accepted", false)) and String(flood_prev.get("reason", "")).contains("drain excess water to waste"), "flooded 75 moisture prompts draining excess water to waste without killing seed")
	await _capture("s04_flood_and_drain_hint")

	var drained: Dictionary = bench.drain_excess_to_waste("alo", 50)
	_expect(bool(drained.get("accepted", false)) and int(drained.get("moisture", 0)) == 50, "drained excess water from 75 to 50 nominal")
	bench.choose_cassette_label("alo", "EXTERNAL_TEST")
	bench.choose_cassette_seal("alo", true)
	bench.preview()
	await _capture("s04_calibrated_band_and_labels")

	# 150% large text check
	bench.close()
	_set_large_text(true)
	_expect(campaign.hud.open_p01_panel("water_alo"), "bench reopens at 150% large text")
	bench.preview()
	await _capture("s04_large_text")
	var commit := bench.find_child("Commit", true, false) as Control
	probe.append("large text: viewport %s, frame %s, commit %s" % [str(campaign.hud.get_viewport_rect()), str(bench._frame.get_global_rect()), str(commit.get_global_rect() if commit != null else Rect2())])
	_expect(commit != null and campaign.hud.get_viewport_rect().encloses(commit.get_global_rect()) and campaign.hud.get_viewport_rect().encloses(bench._frame.get_global_rect()), "P-01 bench and Commit stay inside viewport at 150% text")
	bench.close()
	_set_large_text(false)

	# Open NASA Data Cards from bench
	campaign.hud.open_p01_panel("water_alo")
	bench.open_data_cards()
	await process_frame
	_expect(campaign.hud.panels.active_panel() == "sources", "Data Cards button opens P-01 NASA sources panel")
	await _capture("data_cards")
	campaign.hud.panels.close_panel()

	campaign.free()
	storage.cleanup()
	probe.append("RESULT %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	var file := FileAccess.open(ProjectSettings.globalize_path("res://../production/qa/evidence/M1-08_capture_probe.txt"), FileAccess.WRITE)
	if file != null:
		file.store_string("\n".join(probe) + "\n")
	print("M1-08 P01 BENCH CAPTURE RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)

func _goto(scene_id: String) -> void:
	while campaign.route.current_scene_id() != scene_id:
		var current: String = campaign.route.current_scene_id()
		for spec in GateCatalog.targets_for_scene(current):
			campaign.route.perform(String(spec.get("target_id", "")))
		if not bool(campaign.route.advance_scene().get("accepted", false)):
			_expect(false, "reach " + scene_id + " (stuck at " + current + ")")
			return
	campaign._sync_route_projection()
	campaign._refresh_world()
	await campaign.wait_loading()
	campaign.hud.refresh_scene()
	await process_frame

func _set_large_text(value: bool) -> void:
	var state: Dictionary = campaign.director.snapshot()
	state.accessibility.large_text = value
	campaign.director.restore_snapshot(state)
	campaign.hud.apply_accessibility()

func _stand_at(target_id: String) -> void:
	var target := campaign.physical_target(target_id)
	if target == null:
		_expect(false, "physical target " + target_id)
		return
	campaign._player.global_position = Vector3(target.global_position.x, 0.0, target.global_position.z + 1.0)
	campaign._player.velocity = Vector3.ZERO
	await physics_frame
	await physics_frame

func _expect(condition: bool, message: String) -> void:
	probe.append(("ok   " if condition else "FAIL ") + message)
	if not condition:
		failures += 1
		push_error("FAIL " + message)

func _capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../production/qa/evidence/M1-08_%s.png" % label)
	var error := root.get_texture().get_image().save_png(path)
	if error != OK:
		failures += 1
	probe.append("screenshot %s (%s)" % [path.get_file(), "saved" if error == OK else "error %d" % error])
	print("M1-08 evidence: ", path, " (", error, ")")
