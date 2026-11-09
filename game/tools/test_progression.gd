extends SceneTree

## M3-64, M3-4U, M3-6U, M3-8U: Cadet record report cards, five cadet skills
## with three rank thresholds and crew lines, gear loadout weight & slot limits,
## 32 optional jobs across Chapters 1-8 (4 per chapter region) linked to
## Messages, Safe Room bunk rest, and post-chapter upgrade pairs (Ch 3, Ch 5,
## Ch 7) wired through the simulation modifier contract.

const ProgressionScript = preload("res://scripts/progression/cadet_progression.gd")
const RecordPanelScript = preload("res://scripts/ui/cadet_record.gd")
const JobsBoardScript = preload("res://scripts/ui/jobs_board.gd")
const SimulationScript = preload("res://scripts/simulation/expedition_simulation.gd")
const LedgerScript = preload("res://scripts/simulation/campaign_ledger_simulation.gd")
const StateScript = preload("res://scripts/core/campaign_state.gd")

var checks := 0
var failures := 0
var capture_screenshots := false

func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--capture":
			capture_screenshots = true
	call_deferred("_run")

func _run() -> void:
	_test_grading_and_skills()
	_test_jobs_catalog_and_unlocks()
	_test_upgrades_and_loadout_weight()
	_test_simulation_upgrade_modifiers()
	_test_rest_and_persistence()
	await _test_ui_panels_and_capture()
	print("PROGRESSION RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_grading_and_skills() -> void:
	var prog := ProgressionScript.new()
	var card_distinction := prog.record_sortie_report({
		"id": "SORTIE-01",
		"title": "Mast Courtyard Survey",
		"chapter": 1,
		"skill": "navigation",
		"xp": 1,
		"actual_minutes": 14.0,
		"planned_minutes": 15.0,
		"payload_intact": true,
		"care_score": 98,
		"science_score": 96,
		"reserve_kept_pct": 32.0,
	})
	_check(String(card_distinction.grade) == "Distinction" and float(card_distinction.average) >= 90.0, "on-time intact sortie with reserve intact earns Distinction")
	_check(prog.skill_rank("navigation") == 1, "1 XP reaches Rank 1 (threshold 1)")
	var nav_r1 := prog.skill_info("navigation")
	_check(String(nav_r1.crew_line).begins_with("Amara:") and not String(nav_r1.benefit).is_empty(), "Rank 1 exposes visible benefit and mentor crew line")

	prog.add_skill_xp("navigation", 2)
	_check(prog.skill_rank("navigation") == 2, "3 XP reaches Rank 2 (threshold 3)")
	prog.add_skill_xp("navigation", 3)
	_check(prog.skill_rank("navigation") == 3, "6 XP reaches Rank 3 (threshold 6)")

	var card_partial := prog.record_sortie_report({
		"id": "SORTIE-02",
		"title": "Late Slip Run",
		"chapter": 2,
		"skill": "handling",
		"xp": 1,
		"actual_minutes": 28.0,
		"planned_minutes": 15.0,
		"payload_intact": false,
		"care_score": 70,
		"science_score": 75,
		"reserve_kept_pct": 12.0,
	})
	_check(String(card_partial.grade) in ["Completed", "Merit"] and String(card_partial.note).contains("never locked"), "lower report card grade still completes and never locks story")
	_check(prog.all_skills_info().size() == 5, "all 5 cadet skills (navigation, handling, life_support, repair, observation) are defined")

func _test_jobs_catalog_and_unlocks() -> void:
	var prog := ProgressionScript.new()
	for ch in range(1, 9):
		var ch_jobs := prog.jobs_for_chapter(ch)
		_check(ch_jobs.size() >= 4, "chapter %d has at least 4 jobs in jobs.json (found %d)" % [ch, ch_jobs.size()])
		for job in ch_jobs:
			_check(not String(job.sender).is_empty() and not String(job.reason).is_empty() and String(job.message_id).begins_with("MSG-CH0%d-" % ch), "job %s has sender, reason and message_id" % String(job.id))

	# Cannot complete a Chapter 4 job when only Chapter 1 is unlocked
	var locked_res := prog.complete_job("JOB-CH04-01", 1)
	_check(not bool(locked_res.accepted), "future chapter job is refused before its chapter unlocks")

	var ok_res := prog.complete_job("JOB-CH01-01", 1)
	_check(bool(ok_res.accepted) and prog.skill_rank("repair") == 1, "completing JOB-CH01-01 awards repair XP and report card")
	var dup_res := prog.complete_job("JOB-CH01-01", 1)
	_check(not bool(dup_res.accepted), "completed job cannot be completed twice")

func _test_upgrades_and_loadout_weight() -> void:
	var prog := ProgressionScript.new()
	# Cannot pick an upgrade before completing its chapter when completed_chapters is supplied
	_check(not bool(prog.choose_upgrade(3, "A", [1, 2]).accepted), "After-Ch3 upgrade refused before Chapter 3 completion")
	var u3 := prog.choose_upgrade(3, "A", [1, 2, 3])
	_check(bool(u3.accepted) and String(u3.upgrade_id) == "moon_dirt_shelter", "M3-4U: After-Ch3 Option A selects moon_dirt_shelter")
	# Mutually exclusive: Option B after Option A is refused
	_check(not bool(prog.choose_upgrade(3, "B", [1, 2, 3]).accepted), "M3-4U: mutually exclusive choice refuses switching to B")
	# Idempotent repeat of Option A succeeds
	_check(bool(prog.choose_upgrade(3, "A", [1, 2, 3]).accepted), "M3-4U: repeat confirmation of chosen option is idempotent")

	var u5 := prog.choose_upgrade(5, "A", [1, 2, 3, 4, 5])
	_check(bool(u5.accepted) and String(u5.upgrade_id) == "dust_shield", "M3-6U: After-Ch5 Option A selects dust_shield")
	var u7 := prog.choose_upgrade(7, "B", [1, 2, 3, 4, 5, 6, 7])
	_check(bool(u7.accepted) and String(u7.upgrade_id) == "long_range_battery", "M3-8U: After-Ch7 Option B selects long_range_battery")

	# Unlock Ch 4 ice_harvester (5.0 kg) to test loadout weight limit (10.0 kg max)
	prog.choose_upgrade(4, "A")
	_check(bool(prog.equip_gear("moon_dirt_shelter").accepted), "equip moon_dirt_shelter (4.5 kg)")
	_check(bool(prog.equip_gear("ice_harvester").accepted), "equip ice_harvester (5.0 kg, total 9.5 kg <= 10.0 kg)")
	var overweight := prog.equip_gear("long_range_battery")
	_check(not bool(overweight.accepted) and String(overweight.reason).contains("weight limit"), "adding 4.5 kg long_range_battery at 9.5 kg is refused by the 10.0 kg weight limit")
	_check(not bool(prog.equip_gear("flexible_seals").accepted), "unearned upgrade option cannot be equipped")

func _test_simulation_upgrade_modifiers() -> void:
	var sim := SimulationScript.new()
	var base := sim.entry_profile("chapter1_base")
	# M3-4U: moon_dirt_shelter (+1 shelter, capped at 6)
	base["upgrades"] = {"choices": {3: "A", 5: "A", 7: "B"}}
	var readouts := sim.outpost_readouts(base)
	_check(int(readouts.get("shelter_capacity", 0)) == 1 and int(readouts.get("shelter_max", 0)) == 6, "M3-4U moon_dirt_shelter adds +1 permanent shelter capped at 6")

	# M3-8U: long_range_battery (+4 rover energy in P-15, 14 -> 18)
	var ledger := LedgerScript.new()
	var ch8_snap := StateScript.new_snapshot()
	ch8_snap["upgrades"] = {"choices": {3: "B", 5: "B", 7: "B"}, "acquisition_chapter": {}, "applied_profile_revision": "p02-base-v1"}
	var projected := ledger.project_scene(ch8_snap, "EX-CH08-S01")
	var route: Dictionary = projected.get("snapshot", {}).get("route", {})
	_check(int(route.get("energy", 0)) == 18 and int(route.get("capacity", 0)) == 18, "M3-8U long_range_battery raises Chapter 8 P-15 rover battery from 14 to 18")

func _test_rest_and_persistence() -> void:
	var prog := ProgressionScript.new()
	prog.choose_upgrade(1, "B")
	prog.equip_gear("fuel_cell")
	prog.complete_job("JOB-CH01-02", 1)
	var rest := prog.rest_at_bunk(3, 4)
	_check(bool(rest.accepted) and prog.rest_count == 1 and String(rest.summary).contains("Safe Room bunk"), "Safe Room bunk rest logs checkpoint, messages, photos and sorties")

	var saved := prog.snapshot()
	var restored := ProgressionScript.new()
	_check(restored.restore(saved), "restore accepts snapshot")
	_check(restored.rest_count == 1 and restored.equipped_gear.has("fuel_cell") and restored.completed_jobs.has("JOB-CH01-02"), "restored progression preserves rest count, equipped gear and completed jobs")

func _test_ui_panels_and_capture() -> void:
	var prog := ProgressionScript.new()
	for ch in range(1, 8):
		prog.choose_upgrade(ch, "A" if ch % 2 == 1 else "B")
	prog.equip_gear("taller_mast")
	prog.equip_gear("red_blue_leds")
	prog.equip_gear("dust_shield")
	prog.complete_job("JOB-CH01-01", 8)
	prog.complete_job("JOB-CH04-01", 8)
	prog.add_skill_xp("navigation", 3)
	prog.rest_at_bunk(2, 4)

	var record_panel := RecordPanelScript.new()
	root.add_child(record_panel)
	record_panel.bind_progression(prog)
	record_panel.open_tab("skills", 3)
	await process_frame
	await process_frame
	_check(record_panel._title_label.text == "Cadet Skills", "CadetRecordPanel renders skills tab")

	if capture_screenshots and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/M3-64_cadet_record_skills.png"))

	record_panel.open_tab("loadout", 3)
	await process_frame
	await process_frame
	if capture_screenshots and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/M3-64_gear_loadout.png"))

	for item in [
		{"ch": 3, "file": "M3-4U_upgrade_after_ch03.png"},
		{"ch": 5, "file": "M3-6U_upgrade_after_ch05.png"},
		{"ch": 7, "file": "M3-8U_upgrade_after_ch07.png"},
	]:
		record_panel.open_tab("upgrades", int(item.ch))
		await process_frame
		await process_frame
		_check(record_panel._title_label.text.contains("Chapter %d" % int(item.ch)), "Upgrade choice screen renders Chapter %d pair" % int(item.ch))
		if capture_screenshots and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/" + String(item.file)))

	record_panel.free()

	var jobs_panel := JobsBoardScript.new()
	root.add_child(jobs_panel)
	jobs_panel.bind_progression(prog, 8)
	await process_frame
	await process_frame
	_check(jobs_panel._list_box.get_child_count() == 4, "JobsBoardPanel renders 4 jobs for the active chapter")
	if capture_screenshots and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/M3-64_jobs_board.png"))
	jobs_panel.free()
	await process_frame

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		print("  FAIL: ", message)
