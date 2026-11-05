## Godot --headless --path game --script res://tools/test_tara_lifecycle.gd
## Tara's dated end (doc 24 §3.9, approved 5 Nov 2026, board M3-96): mature pods on
## 26 May 2046, harvest on 31 May into the working stock (Tara x Alo, no headline
## count), archived as a nameplate; the founder ledger 42 = 12 + 30 never changes;
## Alo's vigil photos stay allowed through 21 May; a save from before the change loads.
extends SceneTree

const PlantScript = preload("res://scripts/biology/plant_service.gd")
const SimulationScript = preload("res://scripts/simulation/campaign_ledger_simulation.gd")
const StateScript = preload("res://scripts/core/campaign_state.gd")
const SaveScript = preload("res://scripts/save/save_service.gd")
const Clock = preload("res://resources/campaign/campaign_clock.json")
const Rules = preload("res://resources/campaign/profiles/campaign_rules.json")

const FOUNDER_LEDGER := {"total": 42, "allocated": 12, "reserve": 30, "reserve_compartments": [15, 15]}
const COUNT_KEYS := ["total", "count", "seeds", "seed_count", "seed_yield", "unallocated", "allocated", "reserve"]

var checks := 0
var failures := 0
var service = PlantScript.new()

func _init() -> void:
	_test_rules()
	_test_tara_service_lifecycle()
	_test_unpollinated_tara()
	_test_alo_vigil_photos()
	_test_simulation_working_stock()
	_test_save_from_before_the_change()
	print("TARA LIFECYCLE RESULT: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  ok ", message)
	else:
		failures += 1
		push_error("FAIL " + message)
		print("  FAIL ", message)

func _has_count(record: Dictionary) -> bool:
	for key in COUNT_KEYS:
		if record.has(key):
			return true
	return false

func _test_rules() -> void:
	var bio: Dictionary = Rules.data.biology
	_check(int(bio.tara_mature_days) == 45 and String(bio.tara_maturity_date).begins_with("2046-05-26") and String(bio.tara_harvest_date).begins_with("2046-05-31") and int(bio.dry_down_days) == 5, "rules hold Tara's dated schedule: day 45 (26 May), five-day dry-down, 31 May harvest")
	_check(int(bio.founder_total) == 42 and int(bio.founder_planting) == 12 and int(bio.founder_reserve) == 30 and bio.reserve_compartments.size() == 2 and int(bio.reserve_compartments[0]) == 15 and int(bio.reserve_compartments[1]) == 15, "rules keep founder 42 = 12 + 30, compartments 15 + 15")
	var stock: Dictionary = bio.working_stock
	_check(String(stock.cross) == "Tara x Alo" and String(stock.lineage_id) == "LINEAGE-TARA-ALO" and not _has_count(stock), "rules describe the working stock as Tara x Alo with no count")
	_check(service.STAGES.has("archived_nameplate") and service.STAGES.has("archived_petal") and service.is_terminal_stage("archived_nameplate"), "archived_nameplate is a terminal stage parallel to archived_petal")

func _pollinated_tara() -> Dictionary:
	var tara: Dictionary = service.new_plant("TARA-01", "LINEAGE-ALO-TARA", "seed", "2046-04-11 06:00 UTC")
	_check(int(tara.mature_days) == 45 and int(tara.bloom_days) == 19, "Tara is created with mature_days 45 from the rules and her 30 April bloom")
	var bloom := service.advance_to(tara, "2046-04-30 06:00 UTC")
	_check(bloom.accepted and bloom.plant.stage == "bloom", "Tara blooms on 30 April")
	var pollinated := service.apply_care(bloom.plant, "pollinate", "2046-05-06 06:00 UTC")
	_check(pollinated.accepted and pollinated.plant.stage == "pollinated", "the 6 May reciprocal run pollinates Tara")
	return pollinated.plant

func _test_tara_service_lifecycle() -> void:
	var founder_before: Dictionary = service.canonical_ledgers().founder_42.duplicate(true)
	var tara := _pollinated_tara()
	var pods := service.advance_to(tara, "2046-05-08 06:00 UTC")
	_check(pods.accepted and pods.plant.stage == "pod_bearing", "Tara shows pods from 8 May")
	var not_yet := service.advance_to(pods.plant, "2046-05-25 06:00 UTC")
	_check(not_yet.accepted and not_yet.plant.stage == "pod_bearing" and not_yet.plant.alive, "on 25 May Tara is still pod bearing (Alo's day-35 maturity does not apply to her)")
	var mature := service.advance_to(not_yet.plant, "2046-05-26 06:00 UTC")
	_check(mature.accepted and mature.plant.stage == "mature_pods", "Tara reaches mature_pods on 26 May 2046 (day 45)")
	var early_harvest := service.harvest(mature.plant, "2046-05-26 06:00 UTC")
	_check(not early_harvest.accepted and early_harvest.plant == mature.plant, "harvest before Tara's confirmation and dry-down is rejected without change")
	var confirmed := service.apply_care(mature.plant, "maturity_check", "2046-05-26 06:00 UTC")
	var dry := service.apply_care(confirmed.plant, "dry_down", "2046-05-26 06:00 UTC")
	_check(confirmed.accepted and dry.accepted and dry.plant.dry_down_started_at.begins_with("2046-05-26"), "Tara's watering stops on 26 May, the 20th day after the last pollination run")
	var still_drying := service.advance_to(dry.plant, "2046-05-30 06:00 UTC")
	_check(still_drying.accepted and still_drying.plant.stage == "mature_pods" and still_drying.plant.alive, "on 30 May Tara is still drying and alive")
	var premature := service.harvest(still_drying.plant, "2046-05-30 06:00 UTC")
	_check(not premature.accepted and premature.plant == still_drying.plant, "a 30 May harvest is premature and leaves Tara unchanged")
	var dried := service.advance_to(still_drying.plant, "2046-05-31 06:00 UTC")
	_check(dried.accepted and dried.plant.stage == "mature_dry" and dried.plant.alive, "Tara's pods are dry on 31 May (day 50) and she is still alive for her last photo")
	var photo := service.apply_care(dried.plant, "photo", "2046-05-31 06:00 UTC")
	_check(photo.accepted and photo.plant.stage == "mature_dry", "Tara's last photo on 31 May is a dated observation")
	var harvest := service.harvest(photo.plant, "2046-05-31 06:00 UTC")
	_check(harvest.accepted and harvest.plant.stage == "archived_nameplate" and not harvest.plant.alive and harvest.plant.harvested and harvest.plant.harvested_at.begins_with("2046-05-31"), "the 31 May harvest archives Tara as a nameplate")
	_check(String(harvest.ledger_target) == "working_stock" and harvest.headline_count == false, "Tara's harvest books to the working stock, not the founder ledger, with no headline count")
	var stock: Dictionary = harvest.get("working_stock", {})
	_check(String(stock.get("cross", "")) == "Tara x Alo" and String(stock.get("lineage_id", "")) == "LINEAGE-TARA-ALO" and bool(stock.get("sealed", false)) and String(stock.get("harvested_at", "")).begins_with("2046-05-31"), "the working stock record is Tara x Alo, sealed on 31 May")
	_check(not _has_count(stock) and int(harvest.seed_count) == 0 and int(harvest.plant.seed_yield) == 0, "the working stock carries no seed count anywhere")
	_check(harvest.ledgers.founder_42 == founder_before and harvest.ledgers.founder_42.total == 42 and harvest.ledgers.founder_42.allocated12 == 12 and harvest.ledgers.founder_42.reserve30 == 30 and harvest.ledgers.founder_42.reserve_compartments == [15, 15], "founder 42 = 12 + 30 (15 + 15) is identical before and after Tara's harvest")
	_check(harvest.ledgers.vault_12 == service.canonical_ledgers().vault_12, "the vault ledger is untouched by Tara's harvest")
	_check(harvest.lineage_record.individual_id == "TARA-01" and harvest.lineage_record.parents == ["ALO-01", "TARA-01"], "Tara's lineage record keeps the reciprocal parents")
	var repeated := service.harvest(harvest.plant, "2046-06-01 06:00 UTC")
	_check(repeated.duplicate and not repeated.accepted and repeated.plant.stage == "archived_nameplate", "a second Tara harvest is a duplicate and changes nothing")
	var revival := service.advance_to(harvest.plant, "2046-10-21 06:00 UTC")
	_check(not revival.accepted and revival.plant.stage == "archived_nameplate", "the archived nameplate is terminal and never revived")
	var late_care := service.apply_care(harvest.plant, "photo", "2046-06-01 06:00 UTC")
	_check(not late_care.accepted, "no care is accepted after Tara's archive")
	var validation: Dictionary = service.validate_plant(harvest.plant)
	_check(bool(validation.valid), "the archived Tara record validates")
	var alo: Dictionary = service.new_plant("ALO-01", "LINEAGE-ALO-TARA", "seed", "2046-04-11 06:00 UTC")
	_check(int(alo.mature_days) == 35 and int(alo.seed_yield) == 42, "Alo keeps day-35 maturity and the founder 42")

func _test_unpollinated_tara() -> void:
	var tara: Dictionary = service.new_plant("TARA-01", "LINEAGE-ALO-TARA", "seed", "2046-04-11 06:00 UTC")
	var last_day := service.advance_to(tara, "2046-05-31 06:00 UTC")
	_check(last_day.accepted and last_day.plant.stage == "bloom" and last_day.plant.alive, "an unpollinated Tara sets no pods and is still alive on 31 May")
	var ended := service.advance_to(last_day.plant, "2046-06-01 06:00 UTC")
	_check(ended.accepted and ended.plant.stage == "naturally_dead" and not ended.plant.alive and not ended.plant.harvested, "an unpollinated Tara completes her annual life on 1 June (day 51) with no harvest")
	var dried_unharvested := _pollinated_tara()
	var mature := service.advance_to(dried_unharvested, "2046-05-26 06:00 UTC")
	var dry := service.apply_care(service.apply_care(mature.plant, "maturity_check", "2046-05-26 06:00 UTC").plant, "dry_down", "2046-05-26 06:00 UTC")
	var missed := service.advance_to(dry.plant, "2046-06-01 06:00 UTC")
	_check(missed.accepted and missed.plant.stage == "naturally_dead" and not missed.plant.alive, "a dry Tara nobody harvested by 1 June ends naturally, as Alo does on 22 May")

func _test_alo_vigil_photos() -> void:
	var alo: Dictionary = service.new_plant("ALO-01", "LINEAGE-ALO-TARA", "seed", "2046-04-11 06:00 UTC")
	var pollinated := service.apply_care(service.advance_to(alo, "2046-04-27 06:00 UTC").plant, "pollinate", "2046-04-27 06:00 UTC")
	var mature := service.advance_to(pollinated.plant, "2046-05-16 06:00 UTC")
	var dry := service.apply_care(service.apply_care(mature.plant, "maturity_check", "2046-05-16 06:00 UTC").plant, "dry_down", "2046-05-16 06:00 UTC")
	_check(mature.plant.stage == "mature_pods" and dry.accepted, "Alo is mature on 16 May and his watering stops")
	var plant: Dictionary = dry.plant
	var vigil_days := ["2046-05-16", "2046-05-17", "2046-05-18", "2046-05-19", "2046-05-20", "2046-05-21"]
	var accepted_photos := 0
	for day in vigil_days:
		var photo := service.apply_care(plant, "photo", day + " 06:00 UTC")
		if photo.accepted:
			accepted_photos += 1
			plant = photo.plant
	_check(accepted_photos == 6 and plant.stage == "mature_dry" and plant.alive, "Alo's vigil photos are accepted on every day from 16 through 21 May")
	var second_same_day := service.apply_care(plant, "photo", "2046-05-21 08:00 UTC")
	_check(second_same_day.duplicate and not second_same_day.accepted, "a second photo on the same day is refused")
	var harvested := service.harvest(plant, "2046-05-21 10:00 UTC")
	_check(harvested.accepted and harvested.seed_count == 42 and String(harvested.ledger_target) == "founder_42" and harvested.plant.stage == "archived_petal", "Alo's 21 May harvest still books 42 to the founder ledger as the petal archive")
	var after := service.apply_care(harvested.plant, "photo", "2046-05-22 06:00 UTC")
	_check(not after.accepted, "no photo after Alo's archive")
	var unharvested_late := service.apply_care(plant, "photo", "2046-05-22 06:00 UTC")
	_check(not unharvested_late.accepted, "an unharvested Alo has completed his life by 22 May, so no later photo")

func _scene_after_tara() -> String:
	for scene_id in ["EX-CH04-S02", "EX-CH04-S03", "EX-CH03-S12"]:
		var entry: Dictionary = Clock.data.scenes.get(scene_id, {})
		if String(entry.get("not_before", "")) > "2046-05-31 00:00 UTC":
			return scene_id
	return ""

func _snapshot_on_21_may() -> Dictionary:
	var snapshot: Dictionary = StateScript.new_snapshot()
	snapshot.scenario_datetime = "2046-05-21 00:00 UTC"
	var alo: Dictionary = service.new_plant("ALO-01", "LINEAGE-ALO-TARA", "seed", "2046-04-11 06:00 UTC")
	var alo_dry := service.apply_care(service.apply_care(service.advance_to(service.apply_care(service.advance_to(alo, "2046-04-27 06:00 UTC").plant, "pollinate", "2046-04-27 06:00 UTC").plant, "2046-05-16 06:00 UTC").plant, "maturity_check", "2046-05-16 06:00 UTC").plant, "dry_down", "2046-05-16 06:00 UTC")
	var alo_harvest := service.harvest(alo_dry.plant, "2046-05-21 00:00 UTC")
	_check(alo_harvest.accepted and alo_harvest.seed_count == 42, "fixture: Alo harvested on 21 May")
	var tara := service.advance_to(_pollinated_tara(), "2046-05-21 00:00 UTC")
	_check(tara.accepted and tara.plant.stage == "pod_bearing", "fixture: Tara is pod bearing on 21 May")
	snapshot.plants = [alo_harvest.plant, tara.plant]
	snapshot.inventories.founder_seed42 = FOUNDER_LEDGER.duplicate(true)
	snapshot.inventories.founder_seed42["sealed"] = true
	return snapshot

## JSON round trip (as a save file does) so int/float typing never masks a difference.
func _json(value) -> Variant:
	return JSON.parse_string(JSON.stringify(value))

func _tara_of(snapshot: Dictionary) -> Dictionary:
	for plant in snapshot.plants:
		if plant.individual_id == "TARA-01":
			return plant
	return {}

func _test_simulation_working_stock() -> void:
	var scene_id := _scene_after_tara()
	_check(not scene_id.is_empty(), "the campaign clock has a scene dated after 31 May 2046")
	var simulation = SimulationScript.new()
	var snapshot := _snapshot_on_21_may()
	var founder_before: Dictionary = snapshot.inventories.founder_seed42.duplicate(true)
	var same_day = simulation.project_scene(snapshot, "EX-CH03-S12")
	_check(same_day.accepted and _tara_of(same_day.snapshot).stage == "pod_bearing" and not same_day.snapshot.inventories.has("working_stock"), "entering CH03-S12 on 21 May leaves Tara growing and no working stock yet")
	var later = simulation.project_scene(same_day.snapshot, scene_id)
	_check(later.accepted, "the ledger clock can jump from 21 May past Tara's harvest (" + scene_id + ")")
	var tara := _tara_of(later.snapshot)
	_check(tara.stage == "archived_nameplate" and not tara.alive and tara.harvested and tara.harvested_at.begins_with("2046-05-31"), "the simulation harvests Tara on 31 May and archives her nameplate")
	_check(tara.maturity_confirmed_at.begins_with("2046-05-26") and tara.dry_down_started_at.begins_with("2046-05-26"), "the simulation dates Tara's maturity and watering stop on 26 May even across a clock jump")
	var stock: Dictionary = later.snapshot.inventories.get("working_stock", {})
	_check(not stock.is_empty() and String(stock.get("cross", "")) == "Tara x Alo" and bool(stock.get("sealed", false)) and not _has_count(stock), "the inventories hold a sealed Tara x Alo working stock with no headline count")
	_check(later.snapshot.inventories.founder_seed42 == founder_before and later.snapshot.inventories.allocated12 == 12 and later.snapshot.inventories.reserve30 == 30, "founder 42 = 12 + 30 is identical before and after the working stock is booked")
	_check(later.snapshot.inventories.vault12 == snapshot.inventories.vault12, "the vault ledger is identical before and after")
	var entries: Array = later.snapshot.campaign_ledgers.entries.filter(func(entry): return String(entry.get("kind", "")) in ["tara_watering_stopped", "tara_working_stock"])
	_check(entries.size() == 2 and entries[0].when.begins_with("2046-05-26") and entries[1].when.begins_with("2046-05-31") and entries[1].founder_ledger_touched == false, "the ledger book records the 26 May watering stop and the 31 May working-stock harvest")
	var validation: Dictionary = StateScript.validate_snapshot(later.snapshot)
	_check(bool(validation.valid), "the snapshot with the working stock validates")
	var again = simulation.project_scene(later.snapshot, scene_id)
	_check(again.accepted and _tara_of(again.snapshot) == tara and again.snapshot.inventories.working_stock == stock, "re-entering the scene never harvests Tara twice")
	var midway = simulation.project_scene(_snapshot_on_21_may(), "EX-CH03-S12")
	midway.snapshot.scenario_datetime = "2046-05-21 00:00 UTC"
	var unpollinated := _snapshot_on_21_may()
	var fresh_tara: Dictionary = service.new_plant("TARA-01", "LINEAGE-ALO-TARA", "seed", "2046-04-11 06:00 UTC")
	unpollinated.plants[1] = service.advance_to(fresh_tara, "2046-05-21 00:00 UTC").plant
	var no_seed = simulation.project_scene(unpollinated, scene_id)
	_check(no_seed.accepted and _tara_of(no_seed.snapshot).stage == "naturally_dead" and not no_seed.snapshot.inventories.has("working_stock"), "a Tara that was never pollinated sets no working stock and ends naturally")

func _test_save_from_before_the_change() -> void:
	# The shape the code produced before M3-96: Tara naturally dead on 22 May with
	# mature_days 35 and seed_yield 0, and no working-stock ledger.
	var old_tara: Dictionary = service.new_plant("TARA-01", "LINEAGE-ALO-TARA", "seed", "2046-04-11 06:00 UTC")
	old_tara.mature_days = 35
	old_tara.stage = "naturally_dead"
	old_tara.alive = false
	old_tara.natural_death = true
	old_tara.death_reason = "completed_annual_life"
	old_tara.last_advanced_at = "2046-05-22 06:00 UTC"
	var snapshot := _snapshot_on_21_may()
	snapshot.plants[1] = old_tara
	snapshot.scenario_datetime = "2046-06-10 00:00 UTC"
	snapshot.scene_id = "EX-CH03-S12"
	snapshot.inventories.erase("working_stock")
	var save = SaveScript.new()
	var migration: Dictionary = save.migrate(snapshot)
	_check(bool(migration.accepted) and not bool(migration.migrated), "a pre-change save with a naturally dead Tara still passes migration")
	var path := OS.get_temp_dir().path_join("lla-m3-96-%d-%d.json" % [OS.get_process_id(), Time.get_ticks_usec()])
	var written: Dictionary = save.save(snapshot, path)
	var loaded: Dictionary = save.load(path)
	_check(bool(written.accepted) and bool(loaded.accepted) and _json(_tara_of(loaded.snapshot)) == _json(old_tara) and not loaded.snapshot.inventories.has("working_stock"), "a pre-change save writes and loads with Tara unchanged and no working stock")
	save.clear(path)
	var simulation = SimulationScript.new()
	var later = simulation.project_scene(loaded.snapshot, _scene_after_tara())
	_check(later.accepted and _json(_tara_of(later.snapshot)) == _json(old_tara) and not later.snapshot.inventories.has("working_stock") and _json(later.snapshot.inventories.founder_seed42) == _json(snapshot.inventories.founder_seed42), "advancing a pre-change save never invents a harvest for a Tara who already ended")
