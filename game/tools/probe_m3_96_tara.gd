## Headless M3-96 evidence probe (no window needed):
## Godot --headless --path game --script res://tools/probe_m3_96_tara.gd
## Walks Tara's dated lifecycle through the plant service and the campaign ledger
## simulation, prints her record on each canonical date, the working-stock ledger,
## the founder ledger before and after, and the exact P-06 ledger lines the HUD shows
## as notes. Writes the same transcript to production/qa/evidence/M3-96_tara_lifecycle.txt.
## A Godot exit code alone is never accepted: the last line must read M3-96 PROBE RESULT: PASS.
extends SceneTree

const PlantScript = preload("res://scripts/biology/plant_service.gd")
const SimulationScript = preload("res://scripts/simulation/campaign_ledger_simulation.gd")
const StateScript = preload("res://scripts/core/campaign_state.gd")
const Clock = preload("res://resources/campaign/campaign_clock.json")

var _out: Array[String] = []
var _failures := 0
var _service = PlantScript.new()

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_line("M3-96 Tara lifecycle probe (doc 24 §3.9 / §7.6, approved 5 Nov 2026)")
	_line("")
	_line("== Plant service: Tara's record on each canonical date ==")
	var tara: Dictionary = _service.new_plant("TARA-01", "LINEAGE-ALO-TARA", "seed", "2046-04-11 06:00 UTC")
	_record("2046-04-11 planted", tara)
	tara = _service.advance_to(tara, "2046-04-30 06:00 UTC").plant
	_record("2046-04-30 bloom", tara)
	tara = _service.apply_care(tara, "pollinate", "2046-05-06 06:00 UTC").plant
	_record("2046-05-06 last reciprocal run", tara)
	tara = _service.advance_to(tara, "2046-05-08 06:00 UTC").plant
	_record("2046-05-08 pods observed", tara)
	tara = _service.advance_to(tara, "2046-05-21 06:00 UTC").plant
	_record("2046-05-21 (Alo's harvest day)", tara)
	_expect(tara.stage == "pod_bearing" and tara.alive, "on Alo's harvest day Tara is still growing in the cooler reference bay")
	tara = _service.advance_to(tara, "2046-05-26 06:00 UTC").plant
	_record("2046-05-26 mature pods (day 45)", tara)
	_expect(tara.stage == "mature_pods", "Tara reaches mature_pods on 26 May 2046")
	tara = _service.apply_care(tara, "maturity_check", "2046-05-26 06:00 UTC").plant
	tara = _service.apply_care(tara, "dry_down", "2046-05-26 06:00 UTC").plant
	_record("2046-05-26 watering stopped", tara)
	tara = _service.advance_to(tara, "2046-05-31 06:00 UTC").plant
	_record("2046-05-31 dry pods (day 50)", tara)
	var founder_before: Dictionary = _service.canonical_ledgers().founder_42
	var harvest: Dictionary = _service.harvest(tara, "2046-05-31 06:00 UTC")
	_record("2046-05-31 harvested", harvest.plant)
	_line("  harvest reason: " + String(harvest.reason))
	_line("  ledger_target=%s headline_count=%s seed_count=%s" % [String(harvest.ledger_target), str(harvest.headline_count), str(harvest.seed_count)])
	_line("  working_stock=" + JSON.stringify(harvest.working_stock))
	_line("  founder_42 before=" + JSON.stringify(founder_before))
	_line("  founder_42 after =" + JSON.stringify(harvest.ledgers.founder_42))
	_expect(harvest.accepted and harvest.plant.stage == "archived_nameplate", "the 31 May harvest archives Tara as archived_nameplate")
	_expect(String(harvest.ledger_target) == "working_stock" and harvest.ledgers.founder_42 == founder_before, "the working stock never enters founder_42")
	_line("")
	_line("== Campaign ledger simulation: 21 May -> first scene after 31 May ==")
	var snapshot: Dictionary = StateScript.new_snapshot()
	snapshot.scenario_datetime = "2046-05-21 00:00 UTC"
	var alo: Dictionary = _service.new_plant("ALO-01", "LINEAGE-ALO-TARA", "seed", "2046-04-11 06:00 UTC")
	alo = _service.apply_care(_service.advance_to(alo, "2046-04-27 06:00 UTC").plant, "pollinate", "2046-04-27 06:00 UTC").plant
	alo = _service.advance_to(alo, "2046-05-16 06:00 UTC").plant
	alo = _service.apply_care(_service.apply_care(alo, "maturity_check", "2046-05-16 06:00 UTC").plant, "dry_down", "2046-05-16 06:00 UTC").plant
	alo = _service.harvest(alo, "2046-05-21 00:00 UTC").plant
	var sim_tara: Dictionary = _service.new_plant("TARA-01", "LINEAGE-ALO-TARA", "seed", "2046-04-11 06:00 UTC")
	sim_tara = _service.apply_care(_service.advance_to(sim_tara, "2046-04-30 06:00 UTC").plant, "pollinate", "2046-05-06 06:00 UTC").plant
	sim_tara = _service.advance_to(sim_tara, "2046-05-21 00:00 UTC").plant
	snapshot.plants = [alo, sim_tara]
	snapshot.inventories.founder_seed42["sealed"] = true
	var simulation = SimulationScript.new()
	var scene_id := ""
	for candidate in ["EX-CH04-S02", "EX-CH04-S03"]:
		if String(Clock.data.scenes.get(candidate, {}).get("not_before", "")) > "2046-05-31 00:00 UTC":
			scene_id = candidate
			break
	var founder_snapshot_before := JSON.stringify(snapshot.inventories.founder_seed42)
	var later: Dictionary = simulation.project_scene(snapshot, scene_id)
	_line("  projected to %s at %s: accepted=%s" % [scene_id, String(later.snapshot.scenario_datetime), str(later.accepted)])
	for plant in later.snapshot.plants:
		if plant.individual_id == "TARA-01":
			_record("  Tara after the jump", plant)
			_expect(plant.stage == "archived_nameplate" and plant.harvested_at.begins_with("2046-05-31") and plant.dry_down_started_at.begins_with("2046-05-26"), "the simulation dates Tara's end on 26 and 31 May across a clock jump")
	_line("  inventories.working_stock=" + JSON.stringify(later.snapshot.inventories.get("working_stock", {})))
	_line("  inventories.founder_seed42 before=" + founder_snapshot_before)
	_line("  inventories.founder_seed42 after =" + JSON.stringify(later.snapshot.inventories.founder_seed42))
	_expect(JSON.stringify(later.snapshot.inventories.founder_seed42) == founder_snapshot_before, "founder_seed42 is byte-identical before and after")
	for entry in later.snapshot.campaign_ledgers.entries:
		if String(entry.get("kind", "")).begins_with("tara_"):
			_line("  ledger entry: " + JSON.stringify(entry))
	_line("")
	_line("== Player-visible text: P-06 ledger lines the HUD shows as notes ==")
	simulation._begin(later.snapshot)
	_line("  Alo line : " + "Alo: %s. Founder lot %s; planting allocation %s; protected reserve %s." % [String(alo.stage).replace("_", " "), later.snapshot.inventories.founder_seed42.get("total", 0), later.snapshot.inventories.allocated12, later.snapshot.inventories.reserve30])
	var tara_line: String = simulation._tara_summary()
	_line("  Tara line: " + tara_line)
	_expect(tara_line.begins_with("Tara: archived nameplate") and tara_line.contains("no headline count") and not tara_line.contains("seeds:"), "the Tara ledger line shows no count")
	_line("")
	_line("M3-96 PROBE RESULT: %s (%d failures)" % ["PASS" if _failures == 0 else "FAIL", _failures])
	var file := FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../production/qa/evidence/M3-96_tara_lifecycle.txt"), FileAccess.WRITE)
	if file != null:
		file.store_string("\n".join(_out) + "\n")
		file.close()
	quit(0 if _failures == 0 else 1)

func _record(label: String, plant: Dictionary) -> void:
	_line("  %-34s stage=%-18s alive=%-5s mature_days=%s confirmed=%s dry_from=%s harvested_at=%s seed_yield=%s" % [label, String(plant.stage), str(plant.alive), str(plant.mature_days), String(plant.maturity_confirmed_at).substr(0, 10), String(plant.dry_down_started_at).substr(0, 10), String(plant.harvested_at).substr(0, 10), str(plant.seed_yield)])

func _expect(condition: bool, message: String) -> void:
	if condition:
		_line("  ok   " + message)
	else:
		_failures += 1
		_line("  FAIL " + message)

func _line(text: String) -> void:
	_out.append(text)
	print(text)
