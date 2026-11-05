extends SceneTree

## Comprehensive test suite for M1-08: P-01 Commission & Plant interactive
## puzzle model, PuzzleHost integration, boundary/wrong/flood-drain validation,
## save/load/retry, and P01PuzzlePanel UI + Chapter1Campaign integration.

const DirectorScript = preload("res://scripts/core/campaign_director.gd")
const RouteScript = preload("res://scripts/missions/chapter1_route.gd")
const PuzzleScript = preload("res://scripts/puzzles/p01_commission_plant_puzzle.gd")
const PlantModelScript = preload("res://scripts/missions/p01_commission_plant.gd")
const HostScript = preload("res://scripts/puzzles/puzzle_host.gd")
const PanelScene: PackedScene = preload("res://scenes/ui/p01_puzzle_panel.tscn")
const CampaignScene: PackedScene = preload("res://scenes/campaign/chapter1_campaign.tscn")

var storage = preload("res://tools/support/isolated_storage.gd").new()
var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_data_and_canon()
	_test_no_prefilled_payloads()
	_test_s03_calibration_and_packet()
	_test_s04_planting_moisture_drain_labels_seals()
	_test_save_load_and_retry()
	await _test_ui_panel()
	await _test_campaign_integration()
	print("P01 COMMISSION PLANT RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_data_and_canon() -> void:
	var d: Dictionary = PuzzleScript.data()
	_check(not d.is_empty() and String(d.get("puzzle_id", "")) == "P-01", "P-01 data file loads with puzzle_id P-01")
	var probe: Dictionary = d.get("probe", {})
	_check(int(probe.get("initial_offset", 0)) == 10 and int(probe.get("uncalibrated_dry", 0)) == 10 and int(probe.get("uncalibrated_wet", 0)) == 110 and int(probe.get("target_dry", -1)) == 0 and int(probe.get("target_wet", 0)) == 100, "probe constants match 08_PUZZLE_DESIGNS.md (+10 offset, dry 10->0, wet 110->100)")
	var band: Dictionary = d.get("moisture_band", {})
	_check(int(band.get("min", 0)) == 40 and int(band.get("max", 0)) == 60 and int(band.get("nominal", 0)) == 50, "moisture band matches 08_PUZZLE_DESIGNS.md (40-60 inclusive, 50 nominal)")
	var packet: Dictionary = d.get("packet", {})
	_check(String(packet.get("inscription", "")) == "ALO" and String(packet.get("initial", "")) == "N." and int(packet.get("seed_count", 0)) == 2, "packet metadata records Latin ALO and N. with 2 seeds")
	var hints: Array = d.get("hints", [])
	_check(hints.size() == 3 and String(hints[0].get("text", "")) == "Check the instrument before trusting it." and String(hints[1].get("text", "")) == "Use the two reference cups." and String(hints[2].get("text", "")) == "Dry must read 0, wet 100, then fill both to 50.", "progressive hints H1-H3 match 08_PUZZLE_DESIGNS.md verbatim")
	var host := HostScript.new()
	host.bind(DirectorScript.new(), "P-01", "EX-M0101", "EX-CH01-S03")
	var cards: Array = host.data_cards()
	_check(cards.size() >= 3 and cards.any(func(c): return String(c.get("source_id", "")) == "change4_cotton"), "PuzzleHost exposes P-01 NASA Data Cards (M0-15)")

func _test_no_prefilled_payloads() -> void:
	var route := RouteScript.new(DirectorScript.new())
	route.start_at("EX-CH01-S03")
	for tid in ["calibrate_probe", "span_probe", "recheck_probe", "inspect_packet"]:
		var res: Dictionary = route.perform(tid)
		_check(not bool(res.get("accepted", false)), "unconfigured S03 gate %s is rejected without pre-filled answers" % tid)
	var model := PlantModelScript.new()
	model.commit("set_zero", "z1")
	model.commit("set_span", "s1")
	model.commit("recheck", "r1")
	model.commit("scan_packet", "p1")
	model.commit("plant_alo", "pa1")
	var empty_water: Dictionary = model.commit("water_alo", "wa-empty", {})
	_check(not bool(empty_water.get("accepted", false)), "P01CommissionPlant.commit(water_alo, {}) rejects empty payload instead of defaulting to 50")

func _test_s03_calibration_and_packet() -> void:
	var route := RouteScript.new(DirectorScript.new())
	route.start_at("EX-CH01-S03")
	var wb: RefCounted = route.p01_puzzle()

	# Predictions
	var pred_wrong: Dictionary = wb.select_prediction("EX-CH01-S03", "reads_0")
	_check(bool(pred_wrong.get("accepted", false)) and not bool(pred_wrong.get("correct", true)), "wrong S03 prediction gives non-punishing explanation")
	var pred_right: Dictionary = wb.select_prediction("EX-CH01-S03", "reads_10")
	_check(bool(pred_right.get("accepted", false)) and bool(pred_right.get("correct", false)), "correct S03 prediction confirms +10 offset reads 10")

	# Step 1: Zero probe
	wb.select_reference_cup("wet")
	wb.set_zero_offset(-10)
	var wrong_cup: Dictionary = route.perform("calibrate_probe")
	_check(not bool(wrong_cup.get("accepted", false)) and String(wrong_cup.get("reason", "")).contains("dry reference cup"), "zeroing in the wet reference cup is rejected with a helpful reason")
	wb.select_reference_cup("dry")
	for bad_offset in [0, -5, -15]:
		wb.set_zero_offset(bad_offset)
		var bad_zero: Dictionary = route.perform("calibrate_probe")
		_check(not bool(bad_zero.get("accepted", false)) and not String(bad_zero.get("trace", {}).get("preview", {}).get("hint", bad_zero.get("hint", ""))).is_empty(), "wrong zero offset %+d is rejected with a non-punishing hint" % bad_offset)
	wb.set_zero_offset(-10)
	_check(wb.displayed_dry_reading() == 0, "zero offset -10 sets displayed dry reading to 0")
	var zero_ok: Dictionary = route.perform("calibrate_probe")
	_check(bool(zero_ok.get("accepted", false)) and bool(route.p01_bench_view("calibrate_probe").p01.probe_zeroed), "calibrate_probe commits once dry cup is zeroed to 0")

	# Step 2: Span probe
	for bad_span in [110, 90, 120]:
		wb.set_wet_span(bad_span)
		var bad_span_res: Dictionary = route.perform("span_probe")
		_check(not bool(bad_span_res.get("accepted", false)), "wrong wet span %d is rejected" % bad_span)
	wb.set_wet_span(100)
	var span_ok: Dictionary = route.perform("span_probe")
	_check(bool(span_ok.get("accepted", false)) and bool(route.p01_bench_view("span_probe").p01.probe_spanned), "span_probe commits when wet span is set to 100")

	# Step 3: Two-point recheck
	wb.set_recheck_cup("dry", true)
	wb.set_recheck_cup("wet", false)
	_check(not bool(route.perform("recheck_probe").get("accepted", false)), "recheck_probe rejects when only one reference cup was verified")
	wb.set_recheck_cup("both", true)
	var recheck_ok: Dictionary = route.perform("recheck_probe")
	_check(bool(recheck_ok.get("accepted", false)) and bool(route.p01_bench_view("recheck_probe").p01.probe_rechecked), "recheck_probe commits when both dry=0 and wet=100 are verified")

	# Step 4: Packet scan
	wb.set_scan_mode("unseal_on_bench")
	var unseal_attempt: Dictionary = route.perform("inspect_packet")
	_check(not bool(unseal_attempt.get("accepted", false)) and String(unseal_attempt.get("reason", "")).contains("sealed"), "opening the packet on the bench is blocked to preserve containment")
	wb.set_scan_mode("unrecorded_glance")
	_check(not bool(route.perform("inspect_packet").get("accepted", false)), "skipping the provenance record is rejected")
	wb.set_scan_mode("sealed_optical")
	var scan_ok: Dictionary = route.perform("inspect_packet")
	_check(bool(scan_ok.get("accepted", false)) and bool(route.p01_bench_view("inspect_packet").p01.packet_scanned), "inspect_packet commits with sealed optical scan (ALO / N., 2 seeds)")
	_check(bool(route.perform("compare_atmosphere").get("accepted", false)) and bool(route.advance_scene().get("accepted", false)) and route.current_scene_id() == "EX-CH01-S04", "completed S03 advances into EX-CH01-S04")

func _test_s04_planting_moisture_drain_labels_seals() -> void:
	var route := RouteScript.new(DirectorScript.new())
	route.start_at("EX-CH01-S03")
	route.p01_puzzle().set_zero_offset(-10)
	route.p01_puzzle().set_wet_span(100)
	route.p01_puzzle().set_recheck_cup("both", true)
	route.p01_puzzle().set_scan_mode("sealed_optical")
	for tid in ["calibrate_probe", "span_probe", "recheck_probe", "inspect_packet", "compare_atmosphere"]:
		route.perform(tid)
	route.advance_scene()
	var wb: RefCounted = route.p01_puzzle()

	# Unconfigured S04 gates reject
	_check(not bool(route.perform("plant_alo").get("accepted", false)), "unconfigured plant_alo rejects (0 seeds staged)")

	# Duplicate / wrong seed count checks
	wb.set_cassette_seeds("alo", 2)
	var two_seeds: Dictionary = route.perform("plant_alo")
	_check(not bool(two_seeds.get("accepted", false)) and String(two_seeds.get("reason", "")).contains("1 seed"), "placing 2 seeds in Alo cassette is blocked")
	wb.set_cassette_seeds("alo", 1)
	_check(bool(route.perform("plant_alo").get("accepted", false)), "placing 1 seed in Alo cassette succeeds")

	# Occupied cassette check when planting Tara
	wb.set_cassette_seeds("tara", 1)
	wb.set_cassette_target("tara", "alo")
	var occupied_seed: Dictionary = route.perform("plant_tara")
	_check(not bool(occupied_seed.get("accepted", false)) and String(occupied_seed.get("reason", "")).contains("Alo cassette is already occupied"), "targeting an occupied cassette names the occupied Alo cassette")
	wb.set_cassette_target("tara", "tara")
	_check(bool(route.perform("plant_tara").get("accepted", false)), "placing 1 seed in Tara cassette succeeds")

	# Unwatered rejection (no pre-filled 50)
	_check(not bool(route.perform("water_alo").get("accepted", false)), "water_alo without choosing a moisture level is rejected")

	# Boundary < 40 (30 and 39)
	for dry_val in [30, 39]:
		wb.set_cassette_moisture("alo", dry_val)
		var too_dry: Dictionary = route.perform("water_alo")
		_check(not bool(too_dry.get("accepted", false)) and String(too_dry.get("reason", "")).contains("too dry"), "moisture %d (< 40) is rejected as too dry" % dry_val)

	# Boundary > 60 (61 and 75): flooding does NOT kill seed, prompts drain to waste
	for flood_val in [61, 75]:
		wb.set_cassette_moisture("alo", flood_val)
		var flooded_res: Dictionary = route.perform("water_alo")
		var p01_alo: Dictionary = route.p01_bench_view("water_alo").p01.cassettes.alo
		_check(not bool(flooded_res.get("accepted", false)) and String(flooded_res.get("reason", "")).contains("drain excess water to waste") and int(p01_alo.get("seed_count", 0)) == 1, "moisture %d (> 60) prompts draining excess water to waste without harming the seed" % flood_val)

	# Drain excess water to boundary 40 and commit
	var drain_res: Dictionary = route.drain_p01_cassette("alo", 40)
	_check(bool(drain_res.get("accepted", false)) and int(drain_res.get("moisture", 0)) == 40, "drain_p01_cassette drains flooded water down to 40")
	_check(bool(route.perform("water_alo").get("accepted", false)), "boundary moisture 40 is accepted for Alo")

	# Reset unsettled Alo cassette without losing seed or resetting Tara, then test boundary 60
	var reset_res: Dictionary = route.reset_p01_cassette("alo")
	var snap_after_reset: Dictionary = route.p01_bench_view("plant_alo").p01
	_check(bool(reset_res.get("accepted", false)) and int(snap_after_reset.cassettes.alo.seed_count) == 0 and int(snap_after_reset.cassettes.tara.seed_count) == 1, "reset_p01_cassette resets only the unsettled Alo cassette without harming Tara or losing a seed")
	wb.set_cassette_seeds("alo", 1)
	_check(bool(route.perform("plant_alo").get("accepted", false)), "Alo cassette can be re-planted after reset")
	wb.set_cassette_moisture("alo", 60)
	_check(bool(route.perform("water_alo").get("accepted", false)), "boundary moisture 60 is accepted for Alo")

	# Water Tara to nominal 50
	wb.set_cassette_moisture("tara", 50)
	_check(bool(route.perform("water_tara").get("accepted", false)), "nominal moisture 50 is accepted for Tara")

	# Distinct labels & duplicate label block naming occupied cassette
	wb.set_cassette_label("alo", "INDOOR_REFERENCE")
	_check(not bool(route.perform("label_alo").get("accepted", false)), "Alo rejects INDOOR REFERENCE label")
	wb.set_cassette_label("alo", "EXTERNAL_TEST")
	_check(bool(route.perform("label_alo").get("accepted", false)), "Alo accepts EXTERNAL TEST label")
	wb.set_cassette_label("tara", "EXTERNAL_TEST", route.p01_bench_view("label_tara").p01)
	var dup_label: Dictionary = route.perform("label_tara")
	_check(not bool(dup_label.get("accepted", false)) and String(dup_label.get("reason", "")).contains("Alo cassette already holds EXTERNAL TEST"), "duplicate EXTERNAL TEST label on Tara is blocked and names the occupied Alo cassette")
	wb.set_cassette_label("tara", "INDOOR_REFERENCE", route.p01_bench_view("label_tara").p01)
	_check(bool(route.perform("label_tara").get("accepted", false)), "Tara accepts INDOOR REFERENCE label")

	# Sealing checks
	wb.set_cassette_seal("alo", false)
	_check(not bool(route.perform("seal_alo").get("accepted", false)), "seal_alo rejects when seal is left open")
	wb.set_cassette_seal("alo", true)
	_check(bool(route.perform("seal_alo").get("accepted", false)), "seal_alo commits when seal is closed")
	_check(not bool(route.reset_p01_cassette("alo").get("accepted", false)), "sealed Alo cassette cannot be reset")
	wb.set_cassette_seal("tara", true)
	_check(bool(route.perform("seal_tara").get("accepted", false)), "seal_tara commits when seal is closed")
	var comp: Dictionary = route.p01_bench_view("seal_tara").completion
	_check(bool(comp.get("complete", false)) and bool(route.gate_status().get("physical_flags", {}).get("p01_complete", false)), "closing both seals completes P-01 and sets p01_complete")

func _test_save_load_and_retry() -> void:
	var route := RouteScript.new(DirectorScript.new())
	route.start_at("EX-CH01-S03")
	route.p01_puzzle().set_zero_offset(-10)
	route.p01_puzzle().set_wet_span(100)
	var h1: Dictionary = route.p01_puzzle().next_hint()
	var h2: Dictionary = route.p01_puzzle().next_hint()
	var h3: Dictionary = route.p01_puzzle().next_hint()
	_check(bool(h1.get("accepted", false)) and bool(h2.get("accepted", false)) and bool(h3.get("accepted", false)) and route.p01_puzzle().revealed_hints().size() == 3, "all 3 progressive hints reveal without penalty")
	route.perform("calibrate_probe")
	var saved: Dictionary = route.snapshot()
	var resumed := RouteScript.new(DirectorScript.new())
	_check(bool(resumed.restore(saved).get("accepted", false)) and resumed.p01_puzzle().displayed_dry_reading() == 0 and resumed.p01_puzzle().revealed_hints().size() == 3, "route restore preserves P-01 workbench settings and revealed hints")
	var before: Dictionary = resumed.snapshot()
	var bad_wb := saved.duplicate(true)
	bad_wb.p01_puzzle.zero_offset = 99
	_check(not bool(resumed.restore(bad_wb).get("accepted", false)) and resumed.snapshot() == before, "corrupt p01_puzzle snapshot is rejected without changing live route")
	var legacy := saved.duplicate(true)
	legacy.erase("p01_puzzle")
	_check(bool(resumed.restore(legacy).get("accepted", false)) and resumed.p01_puzzle().displayed_dry_reading() == 10, "legacy save without p01_puzzle resumes with raw +10 probe offset rather than an invented answer")
	var retried: Dictionary = route.retry()
	_check(bool(retried.get("accepted", false)) and route.p01_puzzle().displayed_dry_reading() == 0 and route.p01_puzzle().revealed_hints().size() == 3, "retry preserves player workbench choices and revealed hints")

func _test_ui_panel() -> void:
	root.size = Vector2i(1280, 720)
	var route := RouteScript.new(DirectorScript.new())
	route.start_at("EX-CH01-S03")
	var panel := PanelScene.instantiate() as P01PuzzlePanel
	root.add_child(panel)
	var emitted: Array = []
	var card_requests: Array = []
	panel.commit_requested.connect(func(tid: String, payload: Dictionary) -> void: emitted.append([tid, payload]))
	panel.data_cards_requested.connect(func(ids: Array) -> void: card_requests.append(ids))

	panel.open(route, "calibrate_probe", {"large_text": false, "timer_free": true})
	await process_frame
	var commit_btn := panel.find_child("Commit", true, false) as Button
	_check(commit_btn != null and commit_btn.disabled, "Commit button starts disabled on uncalibrated probe (dry = 10)")
	_check(not bool(panel.preview().get("accepted", false)) and emitted.is_empty(), "Preview on uncalibrated probe fails safely with a non-punishing hint")
	_check(not bool(panel.request_commit().get("accepted", false)) and emitted.is_empty(), "Space/request_commit cannot commit an uncalibrated probe")

	# Set valid zero offset (-10 -> dry reads 0)
	panel.choose_zero_offset(-10)
	await process_frame
	_check(String(panel.request_commit().get("reason", "")).contains("PREVIEW"), "Commit requires previewing the current bench setting first")
	var prev_ok: Dictionary = panel.preview()
	_check(bool(prev_ok.get("accepted", false)), "Preview succeeds once zero offset is set to -10 (dry = 0)")

	# Verify 44 px minimum button height
	var too_small: Array = []
	for node in panel.find_children("*", "Button", true, false):
		var b := node as Button
		if b.is_visible_in_tree() and b.size.y < 44.0:
			too_small.append(b.name)
	_check(too_small.is_empty(), "every visible P-01 bench button is at least 44 px tall " + str(too_small))

	# Keyboard Space -> Confirm -> Escape cancel -> Controller Y confirm
	var space := InputEventKey.new()
	space.pressed = true
	space.physical_keycode = KEY_SPACE
	panel._input(space)
	_check(panel.find_child("ConfirmCommit", true, false) != null and emitted.is_empty(), "Space opens commit confirmation without committing immediately")
	var esc := InputEventKey.new()
	esc.pressed = true
	esc.physical_keycode = KEY_ESCAPE
	panel._input(esc)
	_check(panel.find_child("ConfirmCommit", true, false) == null and panel.is_open(), "Esc cancels confirmation and returns to bench editing")
	var pad_y := InputEventJoypadButton.new()
	pad_y.pressed = true
	pad_y.button_index = JOY_BUTTON_Y
	panel._input(pad_y)
	_check(panel.find_child("ConfirmCommit", true, false) != null, "Controller Y opens commit confirmation")
	panel._input(pad_y)
	_check(emitted.size() == 1 and emitted[0][0] == "calibrate_probe" and int(emitted[0][1].get("dry_reading", -1)) == 0 and not panel.is_open(), "Controller Y / Space second press confirms once, emits payload, and closes panel")

	# Test S04 Flooding + Drain to Waste + 150% Large Text in UI
	route.p01_puzzle().apply_canonical_setup()
	for tid in ["calibrate_probe", "span_probe", "recheck_probe", "inspect_packet", "compare_atmosphere"]:
		route.perform(tid)
	route.advance_scene()
	route.perform("plant_alo")
	route.perform("plant_tara")
	panel.open(route, "water_alo", {"large_text": true, "timer_free": true})
	await process_frame
	var large_preview := panel.find_child("Preview", true, false) as Button
	_check(large_preview != null and large_preview.get_theme_font_size("font_size") >= 19, "large_text scales P-01 bench controls to 150%")
	panel.choose_cassette_moisture("alo", 75)
	var flood_prev: Dictionary = panel.preview()
	_check(not bool(flood_prev.get("accepted", false)) and String(flood_prev.get("reason", "")).contains("drain excess water to waste"), "UI preview on flooded 75 moisture prompts draining excess water to waste")
	var drained: Dictionary = panel.drain_excess_to_waste("alo", 50)
	_check(bool(drained.get("accepted", false)) and int(drained.get("moisture", 0)) == 50, "UI drain_excess_to_waste brings moisture to 50 nominal")
	_check(bool(panel.preview().get("accepted", false)), "UI preview succeeds after draining excess water to 50")
	panel.open_data_cards()
	_check(card_requests.size() == 1 and card_requests[0].has("change4_cotton"), "Data Cards button requests P-01 NASA evidence cards")
	panel.close()
	panel.free()

func _test_campaign_integration() -> void:
	if not storage.setup("test_p01_commission_plant"):
		_check(false, "isolated storage for P-01 campaign integration check")
		return
	var campaign := CampaignScene.instantiate() as Chapter1Campaign
	storage.configure(campaign)
	root.add_child(campaign)
	await process_frame
	campaign.route.start_at("EX-CH01-S03")
	campaign._sync_route_projection()
	campaign._refresh_world()
	await process_frame
	campaign.hud.refresh_scene()
	var target := campaign.physical_target("calibrate_probe")
	campaign._player.global_position = Vector3(target.global_position.x, 0.0, target.global_position.z + 1.0)
	await physics_frame
	await physics_frame

	var opened := campaign.hud.open_p01_panel("calibrate_probe")
	_check(opened and campaign.hud.p01_panel.is_open() and bool(campaign.director.query().paused), "opening the P-01 Commissioning Bench pauses scenario time")
	var bench := campaign.hud.p01_panel
	bench.select_cup("dry")
	bench.choose_zero_offset(-10)
	_check(bool(bench.preview().get("accepted", false)), "bench previews dry zero calibration")
	bench.request_commit()
	bench.confirm_commit()
	await process_frame
	_check(not bool(campaign.director.query().paused) and bool(campaign.route.p01_bench_view("calibrate_probe").p01.probe_zeroed), "confirming in bench resumes time and commits calibrate_probe through the physical station")
	campaign.free()
	storage.cleanup()

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)
