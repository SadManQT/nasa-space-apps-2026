extends SceneTree
const Knowledge = preload("res://scripts/dialogue/knowledge_service.gd")
const Content = preload("res://scripts/content/content_loader.gd")
const Director = preload("res://scripts/core/campaign_director.gd")
const State = preload("res://scripts/core/campaign_state.gd")
const Chapter2 = preload("res://scripts/missions/chapter2_route.gd")
const Extended = preload("res://scripts/missions/extended_campaign_route.gd")
const Gate2 = preload("res://scripts/missions/chapter2_gate_catalog.gd")
const Gates = preload("res://scripts/missions/extended_gate_catalog.gd")
const Explainers = preload("res://scripts/ui/science_explainers.gd")
const SNAPSHOTS := "res://../production/qa/evidence/M1-72_profile_snapshots.json"
var failures := 0

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var snapshots: Dictionary = {}
	var accepted := 0
	if FileAccess.file_exists(SNAPSHOTS):
		snapshots = JSON.parse_string(FileAccess.get_file_as_string(SNAPSHOTS))
	else:
		var director := Director.new()
		director.new_campaign(Content.EXPECTED_CONTENT_REVISION)
		snapshots.early = director.snapshot()
		var handoff: Dictionary = director.snapshot()
		handoff.chapter1_ready = true
		_guard(director.restore_snapshot(handoff).accepted, "chapter 1 entry handoff")
		var chapter2 := Chapter2.new(director)
		_guard(chapter2.apply_entry_profile().accepted, "chapter 2 entry profile")
		_guard(chapter2.start_at("EX-CH02-S01").accepted, "chapter 2 start")
		for scene_id in Gate2.SCENE_ORDER:
			for target in chapter2.targets_for_current_scene():
				var result: Dictionary = chapter2.perform(target.target_id)
				_guard(result.accepted, "chapter 2 operation " + target.target_id)
				accepted += int(result.accepted)
			_guard(chapter2.advance_scene().accepted, "chapter 2 advance " + scene_id)
		var route := Extended.new(director)
		_guard(route.start_at("EX-CH03-S01").accepted, "extended route start")
		for scene_id in Gates.scene_ids():
			for target in Gates.targets_for_scene(scene_id):
				var result: Dictionary = route.perform(target.target_id, target.get("payload_defaults", {}))
				_guard(result.accepted, "extended operation " + target.target_id)
				accepted += int(result.accepted)
			var moved: Dictionary = route.advance_scene()
			_guard(moved.accepted, "extended advance " + scene_id)
			if moved.get("chapter_complete", false) and scene_id != "EX-CH08-S12":
				var next_scene := "EX-CH%02d-S01" % (int(scene_id.substr(5, 2)) + 1)
				_guard(route.start_at(next_scene).accepted, "next chapter " + next_scene)
		if failures > 0:
			print("PROFILE FIXTURE FAILED: ", failures)
			quit(2)
			return
		snapshots.late = director.snapshot()
		var file := FileAccess.open(SNAPSHOTS, FileAccess.WRITE)
		file.store_string(JSON.stringify(snapshots))
		file.close()
	print("PROFILE SNAPSHOTS: accepted operations=", accepted, " early=", snapshots.early.scene_id, " late=", snapshots.late.scene_id, " late completed=", snapshots.late.completed_scene_ids.size())
	var report := {"source": OS.get_environment("M172_PROFILE_SOURCE"), "registry_sha256": FileAccess.get_file_as_string("res://scripts/ui/science_explainers.gd").sha256_text(), "mode": "cached CPU timing; not suite acceptance or rendered FPS", "samples": 100, "warmups": 8, "snapshots_sha256": FileAccess.get_file_as_string(SNAPSHOTS).sha256_text(), "results": {}}
	for label in ["early", "late"]:
		var snapshot: Dictionary = snapshots[label]
		_guard(State.is_compatible(snapshot), label + " uses compatible actual director snapshot")
		var before := snapshot.duplicate(true)
		var journal: Dictionary = Knowledge.journal(snapshot)
		var ctx: Dictionary = Knowledge._context(snapshot)
		var full: Array = []
		var science: Array = []
		var matching: Array = []
		for sample in 108:
			var start := Time.get_ticks_usec()
			Knowledge.journal(snapshot)
			var full_us := Time.get_ticks_usec() - start
			start = Time.get_ticks_usec()
			Knowledge._science_tab(ctx)
			var science_us := Time.get_ticks_usec() - start
			start = Time.get_ticks_usec()
			Explainers.matching(["EX-M0801", "P-15"])
			var matching_us := Time.get_ticks_usec() - start
			if sample >= 8:
				full.append(full_us / 1000.0)
				science.append(science_us / 1000.0)
				matching.append(matching_us / 1000.0)
		var unchanged: bool = snapshot == before
		_guard(unchanged, label + " snapshot immutable")
		report.results[label] = {"scene_id": snapshot.scene_id, "completed": snapshot.completed_scene_ids.size(), "clips": journal.counts.science, "unchanged": unchanged, "journal_ms": _stats(full), "science_ms": _stats(science), "matching_ms": _stats(matching)}
	report.failures = failures
	var out := "res://../production/qa/evidence/" + OS.get_environment("M172_PROFILE_LABEL") + ".json"
	var file := FileAccess.open(out, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	print("M1-72 PROFILE: ", JSON.stringify(report))
	quit(0 if failures == 0 else 1)

func _stats(samples: Array) -> Dictionary:
	samples.sort()
	return {"median": samples[50], "p95": samples[94], "max": samples[99]}

func _guard(valid: bool, label: String) -> void:
	if not valid:
		failures += 1
		print("PROFILE ERROR: ", label)
