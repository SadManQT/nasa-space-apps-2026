extends RefCounted
class_name PlantService

## Dated, faceless plant lifecycle and inventory ledger.
## Operations return a new primitive plant dictionary; the input plant is
## never mutated. Renderers should consume only the returned stage/status.

const CampaignRules = preload("res://resources/campaign/profiles/campaign_rules.json")
const SCHEMA_VERSION := 1
const FOUNDER_TOTAL := 42
const FOUNDER_ALLOCATED := 12
const FOUNDER_RESERVE := 30
const VAULT_TOTAL := 12
const COTTON_PLANTED := 1
const COTTON_STORED_AFTER_PLANTING := 11
const ALO_ID := "ALO-01"
const TARA_ID := "TARA-01"
const COTTON_ID := "COTTON-01"
const ALO_TARA_LINEAGE := "LINEAGE-ALO-TARA"
## Lineage of the working stock: Tara as seed parent of her own line (Tara x Alo),
## recorded beside the founders' Alo x Tara. Approved 5 Nov 2026 (doc 24 §3.9).
const TARA_ALO_LINEAGE := "LINEAGE-TARA-ALO"
const COTTON_LINEAGE := "LINEAGE-VAULT-COTTON"
## Where a harvest's seeds are booked. Only Alo's 42 ever enter the founder ledger.
const LEDGER_FOUNDER := "founder_42"
const LEDGER_WORKING_STOCK := "working_stock"
## Default lifecycle lengths (days after planting) when the rules block omits them.
const DEFAULT_MATURE_DAYS := 35
const DEFAULT_TARA_MATURE_DAYS := 45
const DEFAULT_DRY_DOWN_DAYS := 5
const ALO_PLANTED_DATE := "2046-04-11"
const TARA_PLANTED_DATE := "2046-04-11"
const COTTON_PLANTED_DATE := "2046-12-15"

const STAGES := [
	"seed",
	"sprout",
	"bud",
	"bloom",
	"pollinated",
	"pod_bearing",
	"mature_pods",
	"mature_dry",
	"young",
	"alive",
	"naturally_dead",
	"lost",
	"archived_petal",
	"archived_nameplate",
]

## Stages a plant never leaves. Alo is archived as a pressed petal, Tara as the
## nameplate carried to the lineage board (doc 24 §7.6 beat 4).
const TERMINAL_STAGES := ["naturally_dead", "lost", "archived_petal", "archived_nameplate"]
const ARCHIVED_STAGES := ["archived_petal", "archived_nameplate"]
## Observations that change no biological state but are still dated once per day.
const OBSERVATION_CARE_IDS := ["inspect", "observe", "log", "label", "check", "photo"]

func new_plant(individual_id: String, lineage_id: String, stage: String, planted_at: String, attributes: Dictionary = {}) -> Dictionary:
	var normalized_stage := stage.to_lower()
	if normalized_stage.is_empty():
		normalized_stage = "seed"
	var plant := {
		"schema_version": SCHEMA_VERSION,
		"individual_id": individual_id,
		"lineage_id": lineage_id,
		"parents": attributes.get("parents", []).duplicate(true),
		"cultivar": String(attributes.get("cultivar", "Brassica rapa")),
		"plant_type": String(attributes.get("plant_type", "mustard")),
		"stage": normalized_stage,
		"planted_at": planted_at,
		"last_care_at": "",
		"last_advanced_at": planted_at,
		"care_receipts": {},
		"care_history": [],
		"stress": {"thirst": 0, "cold": 0, "water": 0},
		"alive": normalized_stage not in TERMINAL_STAGES,
		"natural_death": false,
		"harvested": false,
		"harvested_at": "",
		"death_reason": "",
		"dry_down_started_at": "",
		"maturity_confirmed_at": "",
		"seed_yield": int(attributes.get("seed_yield", 0)),
		"enclosure": String(attributes.get("enclosure", "pressurised_garden")),
		"bloom_days": int(attributes.get("bloom_days", 16)),
		"mature_days": int(attributes.get("mature_days", DEFAULT_MATURE_DAYS)),
		"attributes": attributes.duplicate(true),
	}
	if individual_id == ALO_ID:
		plant["lineage_id"] = lineage_id if not lineage_id.is_empty() else ALO_TARA_LINEAGE
		plant["seed_yield"] = 42
		plant["bloom_days"] = 16
		plant["mature_days"] = 35
	if individual_id == TARA_ID:
		plant["lineage_id"] = lineage_id if not lineage_id.is_empty() else ALO_TARA_LINEAGE
		plant["bloom_days"] = 19
		# Tara's pods develop in the cooler indoor reference bay: mature pods on day 45
		# (26 May 2046), watering stops that day, dry pods and harvest on day 50 (31 May).
		plant["mature_days"] = int(_biology().get("tara_mature_days", DEFAULT_TARA_MATURE_DAYS))
	if individual_id == COTTON_ID or String(attributes.get("plant_type", "")) == "cotton":
		plant["plant_type"] = "cotton"
		if individual_id == COTTON_ID and lineage_id.is_empty():
			plant["lineage_id"] = COTTON_LINEAGE
		plant["stage"] = normalized_stage if normalized_stage in ["seed", "sprout", "young", "alive"] else "seed"
		plant["enclosure"] = "pressurised_reference_bay"
	return plant

func apply_care(plant: Dictionary, care_id: String, scenario_datetime: String) -> Dictionary:
	var base := plant.duplicate(true)
	var result := _operation("care", base, scenario_datetime)
	if not bool(result.get("accepted", false)):
		return result
	if not bool(base.get("alive", true)):
		result["accepted"] = false
		result["reason"] = "A naturally completed plant cannot receive later care."
		return result
	var progressed := advance_to(base, scenario_datetime)
	if bool(progressed.get("accepted", false)):
		base = progressed["plant"].duplicate(true)
		if not bool(base.get("alive", true)):
			result["accepted"] = false
			result["reason"] = "The plant completed its natural life before this care action."
			result["plant"] = plant.duplicate(true)
			return result
	elif not bool(progressed.get("accepted", false)):
		result["accepted"] = false
		result["reason"] = String(progressed.get("reason", "The dated care transition was rejected."))
		result["plant"] = plant.duplicate(true)
		return result
	var date_key := _date_key(scenario_datetime)
	var care_key := care_id.to_lower()
	var receipts: Dictionary = base.get("care_receipts", {})
	var receipt_key := "%s@%s" % [care_key, date_key]
	if receipts.has(receipt_key):
		result["accepted"] = false
		result["duplicate"] = true
		result["reason"] = "This care action was already recorded for that date."
		return result
	if care_key in ["water", "moisture", "irrigate"]:
		base["stress"]["water"] = maxi(0, int(base["stress"].get("water", 0)) - 1)
	elif care_key in ["warm", "temperature", "heat"]:
		base["stress"]["cold"] = maxi(0, int(base["stress"].get("cold", 0)) - 1)
	elif care_key in ["pollinate", "pollination"]:
		if String(base.get("plant_type", "mustard")) == "cotton":
			result["accepted"] = false
			result["reason"] = "Cotton is a reference specimen in this campaign and is not a pollen partner."
			return result
		if String(base.get("stage", "")) not in ["bloom", "pollinated"]:
			result["accepted"] = false
			result["reason"] = "Pollination requires an open bloom; the plant has not reached that dated stage."
			return result
		base["stage"] = "pollinated"
		if (base.get("parents", []) as Array).is_empty():
			base["parents"] = ["ALO-01", "TARA-01"]
	elif care_key in ["maturity_check", "inspect_maturity", "maturity"]:
		if String(base.get("stage", "")) != "mature_pods":
			result["accepted"] = false
			result["reason"] = "Maturity can only be confirmed when the dated pods are mature."
			return result
		base["maturity_confirmed_at"] = scenario_datetime
	elif care_key in ["dry", "dry_down", "drydown"]:
		if String(base.get("stage", "")) != "mature_pods":
			result["accepted"] = false
			result["reason"] = "Dry-down begins only after mature pods have been confirmed."
			return result
		var maturity_confirmed_at := String(base.get("maturity_confirmed_at", ""))
		if maturity_confirmed_at.is_empty() or _datetime_before(scenario_datetime, maturity_confirmed_at):
			result["accepted"] = false
			result["reason"] = "Dry-down requires a prior dated maturity confirmation."
			return result
		if not String(base.get("dry_down_started_at", "")).is_empty():
			result["accepted"] = false
			result["reason"] = "Dry-down has already started for this individual."
			return result
		base["dry_down_started_at"] = scenario_datetime
	else:
		# Inspect, log and label are valid no-resource observations. Unknown care
		# IDs remain rejected so UI typos cannot become silent biology changes.
		if care_key not in OBSERVATION_CARE_IDS:
			result["accepted"] = false
			result["reason"] = "Unknown care action; no biological state was changed."
			return result
	receipts[receipt_key] = {"care_id": care_key, "scenario_datetime": scenario_datetime}
	base["care_receipts"] = receipts
	base["care_history"].append({"care_id": care_key, "scenario_datetime": scenario_datetime})
	base["last_care_at"] = scenario_datetime
	result["accepted"] = true
	result["plant"] = base
	result["events"].append({"type": "plant_care_recorded", "individual_id": String(base.get("individual_id", "")), "care_id": care_key})
	result["reason"] = "Dated care recorded once."
	return result

func validate_plant(plant: Dictionary) -> Dictionary:
	var defaults := new_plant("validation", "", "seed", "2046-04-11 06:00 UTC")
	for key in defaults:
		var value = plant.get(key, null)
		if defaults[key] is int:
			if not (value is int or value is float) or not is_finite(float(value)) or float(value) != floor(float(value)) or float(value) < 0:
				return {"valid": false, "reason": "Plant numeric state is invalid: " + key}
		elif typeof(value) != typeof(defaults[key]):
			return {"valid": false, "reason": "Plant state has an invalid type for " + key}
	if int(plant.schema_version) != SCHEMA_VERSION or plant.individual_id.is_empty() or not STAGES.has(plant.stage):
		return {"valid": false, "reason": "Plant schema, identity or stage is invalid."}
	for key in defaults.stress:
		var value = plant.stress.get(key, null)
		if not (value is int or value is float) or not is_finite(float(value)) or float(value) < 0:
			return {"valid": false, "reason": "Plant stress must be a finite nonnegative number."}
	for entry in plant.care_history:
		if not entry is Dictionary or not entry.get("care_id", null) is String or not entry.get("scenario_datetime", null) is String:
			return {"valid": false, "reason": "Plant care history must contain dated care records."}
	for receipt in plant.care_receipts.values():
		if not receipt is Dictionary:
			return {"valid": false, "reason": "Plant care receipts must contain Dictionaries."}
	var canonical_reason := _canonical_identity_reason(plant)
	return {"valid": canonical_reason.is_empty(), "reason": canonical_reason}

## Visible form of an Alo or Tara plant before its bud, from the plant's own dates (never a playback timer):
## "seed" on the sowing day, "cotyledon" (two seed leaves) from day 1 and "true_leaf" from
## `biology.true_leaf_day` (Fast Plants life cycle; doc 24 §3.8). Returns "" for later stages and for cotton,
## which has its own art. The day counted is `last_advanced_at`, the date the service last evaluated.
func seedling_form(plant: Dictionary) -> String:
	if String(plant.get("plant_type", "mustard")) != "mustard":
		return ""
	var stage := String(plant.get("stage", ""))
	if stage == "seed":
		return "seed"
	if stage != "sprout":
		return ""
	var planted := _day_number(String(plant.get("planted_at", "")))
	var evaluated := _day_number(String(plant.get("last_advanced_at", plant.get("planted_at", ""))))
	return "true_leaf" if evaluated - planted >= int(CampaignRules.data.biology.true_leaf_day) else "cotyledon"

func advance_to(plant: Dictionary, scenario_datetime: String) -> Dictionary:
	var base := plant.duplicate(true)
	var result := _operation("advance", base, scenario_datetime)
	if not bool(result.get("accepted", false)):
		return result
	if not bool(base.get("alive", true)):
		result["accepted"] = false
		result["reason"] = "A naturally completed plant cannot be revived by a later date."
		return result
	var planted_day := _day_number(String(base.get("planted_at", "")))
	var target_day := _day_number(scenario_datetime)
	var elapsed := target_day - planted_day
	var kind := String(base.get("plant_type", "mustard"))
	var current := String(base.get("stage", "seed"))
	if kind == "cotton":
		if elapsed >= 1 and current == "seed":
			current = "sprout"
		if elapsed >= 7 and current == "sprout":
			current = "young"
		if elapsed >= 21 and current == "young":
			current = "alive"
	else:
		if elapsed >= 1 and current == "seed":
			current = "sprout"
		if elapsed >= 7 and current == "sprout":
			current = "bud"
		if elapsed >= int(base.get("bloom_days", 16)) and current in ["seed", "sprout", "bud"]:
			current = "bloom"
		if current == "pollinated" and String(base.individual_id) in [ALO_ID, TARA_ID] and scenario_datetime.substr(0, 10) >= String(CampaignRules.data.biology.pod_observation_date):
			current = "pod_bearing"
		var mature_days := int(base.get("mature_days", DEFAULT_MATURE_DAYS))
		var dry_down_days := int(_biology().get("dry_down_days", DEFAULT_DRY_DOWN_DAYS))
		if current in ["pollinated", "pod_bearing"] and elapsed >= mature_days:
			current = "mature_pods"
		if current == "mature_pods" and not String(base.get("dry_down_started_at", "")).is_empty():
			if _day_number(String(base.get("dry_down_started_at", ""))) + dry_down_days <= target_day:
				current = "mature_dry"
		if elapsed > mature_days + dry_down_days and String(base.individual_id) in [ALO_ID, TARA_ID]:
			current = "naturally_dead"
			base["alive"] = false
			base["natural_death"] = true
			base["death_reason"] = "completed_annual_life"
	base["stage"] = current
	base["last_advanced_at"] = scenario_datetime
	result["accepted"] = true
	result["plant"] = base
	result["events"].append({"type": "plant_stage_advanced", "individual_id": String(base.get("individual_id", "")), "stage": current, "scenario_datetime": scenario_datetime})
	result["reason"] = "Dated lifecycle evaluated without skipping biological stages."
	return result

## Records the one dated harvest of a mature, dried individual and archives it.
## Alo's harvest is the founder lot (42 = 12 + 30, `ledger_target` "founder_42").
## Tara's harvest (31 May 2046) goes to the separate working stock, lineage
## Tara x Alo, with no headline count (`ledger_target` "working_stock",
## `working_stock` holds the record) and archives her as `archived_nameplate`.
## Any other individual also books to the working stock, never to the founder ledger.
func harvest(plant: Dictionary, scenario_datetime: String) -> Dictionary:
	var original := plant.duplicate(true)
	var base := original.duplicate(true)
	var result := _operation("harvest", base, scenario_datetime)
	if not bool(result.get("accepted", false)):
		result["plant"] = original.duplicate(true)
		return result
	if bool(base.get("harvested", false)) or String(base.get("stage", "")) in ARCHIVED_STAGES:
		result["accepted"] = false
		result["duplicate"] = true
		result["reason"] = "This individual has already completed its harvest record."
		result["plant"] = original.duplicate(true)
		return result
	var matured := advance_to(base, scenario_datetime)
	if bool(matured.get("accepted", false)):
		base = matured["plant"].duplicate(true)
	else:
		result["accepted"] = false
		result["reason"] = String(matured.get("reason", "The dated harvest transition was rejected."))
		result["plant"] = original.duplicate(true)
		return result
	var stage := String(base.get("stage", ""))
	var dry_started := String(base.get("dry_down_started_at", ""))
	var maturity_confirmed_at := String(base.get("maturity_confirmed_at", ""))
	if maturity_confirmed_at.is_empty() or _datetime_before(scenario_datetime, maturity_confirmed_at):
		result["accepted"] = false
		result["reason"] = "Harvest requires a prior dated maturity confirmation."
		result["plant"] = original.duplicate(true)
		return result
	if stage != "mature_dry" or dry_started.is_empty():
		result["accepted"] = false
		result["reason"] = "Pods are not dry-harvest ready; premature harvest is rejected."
		result["plant"] = original.duplicate(true)
		return result
	var individual_id := String(base.get("individual_id", ""))
	var yield_count := int(base.get("seed_yield", 0))
	var ledger_target := LEDGER_WORKING_STOCK
	var archived_stage := "archived_petal"
	if individual_id == ALO_ID:
		yield_count = FOUNDER_TOTAL
		ledger_target = LEDGER_FOUNDER
	elif individual_id == TARA_ID:
		# The working stock is recorded without a headline count (doc 24 §3.9):
		# the plant keeps no seed number and the ledger record carries none.
		yield_count = 0
		archived_stage = "archived_nameplate"
	base["seed_yield"] = yield_count
	base["harvested"] = true
	base["harvested_at"] = scenario_datetime
	base["alive"] = false
	base["natural_death"] = true
	base["death_reason"] = "completed_annual_life"
	base["stage"] = archived_stage
	result["accepted"] = true
	result["plant"] = base
	result["seed_count"] = yield_count
	result["ledger_target"] = ledger_target
	result["headline_count"] = ledger_target == LEDGER_FOUNDER
	if individual_id == TARA_ID:
		result["working_stock"] = working_stock_record(scenario_datetime)
	result["lineage_record"] = {
		"individual_id": String(base.get("individual_id", "")),
		"lineage_id": String(base.get("lineage_id", "")),
		"parents": base.get("parents", []).duplicate(true),
		"natural_death": true,
	}
	result["ledgers"] = canonical_ledgers()
	result["events"].append({"type": "plant_naturally_completed", "individual_id": String(base.get("individual_id", "")), "seed_count": yield_count, "ledger_target": ledger_target})
	if individual_id == TARA_ID:
		result["reason"] = "Harvest recorded after dated dry-down into the sealed working stock (Tara x Alo, no headline count); the founder ledger is untouched and Tara's nameplate is archived on the lineage board."
	else:
		result["reason"] = "Harvest recorded after dated dry-down; the original individual is archived and never revived."
	return result

## The working-stock ledger record written by Tara's harvest: lineage Tara x Alo,
## sealed, deliberately without any seed count, and never part of founder_42.
## `harvested_at` is the dated harvest (canon 31 May 2046).
func working_stock_record(harvested_at: String) -> Dictionary:
	var rules: Dictionary = _biology().get("working_stock", {})
	return {
		"lineage_id": String(rules.get("lineage_id", TARA_ALO_LINEAGE)),
		"cross": String(rules.get("cross", "Tara x Alo")),
		"label": String(rules.get("label", "Working stock: Tara x Alo")),
		"source_individual": String(rules.get("source_individual", TARA_ID)),
		"parents": (rules.get("parents", [TARA_ID, ALO_ID]) as Array).duplicate(true),
		"harvested_at": harvested_at,
		"sealed": true,
		"headline_count": String(rules.get("headline_count", "not recorded")),
		"separate_from_founder": true,
		"founder_ledger": LEDGER_FOUNDER,
	}

## Tara's dated schedule from the rules block: the day her pods are mature and her
## watering stops (26 May 2046) and her dry-pod harvest day (31 May 2046).
func tara_schedule() -> Dictionary:
	var biology := _biology()
	return {
		"mature_days": int(biology.get("tara_mature_days", DEFAULT_TARA_MATURE_DAYS)),
		"dry_down_days": int(biology.get("dry_down_days", DEFAULT_DRY_DOWN_DAYS)),
		"maturity_date": String(biology.get("tara_maturity_date", "2046-05-26 00:00 UTC")),
		"harvest_date": String(biology.get("tara_harvest_date", "2046-05-31 00:00 UTC")),
	}

## True when the stage is one a plant never leaves (dead, lost or archived).
func is_terminal_stage(stage: String) -> bool:
	return stage in TERMINAL_STAGES

func _biology() -> Dictionary:
	var data = CampaignRules.data
	return data.get("biology", {}) if data is Dictionary else {}

func record_cotton_plant(vault_ledger: Dictionary, scenario_datetime: String) -> Dictionary:
	var ledger := vault_ledger.duplicate(true)
	if String(ledger.get("planted_at", "")).is_empty() and int(ledger.get("total", 0)) == 0:
		ledger = canonical_ledgers()["vault_12"].duplicate(true)
	if String(scenario_datetime).substr(0, 10) != "2046-12-15":
		return {"accepted": false, "duplicate": false, "reason": "Cotton is canonically planted on 2046-12-15; use an explicit dated transition.", "ledger": ledger}
	if int(ledger.get("cotton_planted", 0)) >= 1:
		return {"accepted": false, "duplicate": true, "reason": "Cotton has already been planted from the vault ledger.", "ledger": ledger}
	ledger["cotton_planted"] = 1
	ledger["stored"] = 11
	ledger["stored_after_cotton"] = 11
	ledger["planted_at"] = scenario_datetime
	return {"accepted": true, "duplicate": false, "reason": "One cotton specimen planted; eleven distinct vault specimens remain stored.", "ledger": ledger}

func canonical_ledgers() -> Dictionary:
	return {
		"founder_42": {
			"total": FOUNDER_TOTAL,
			"allocated12": FOUNDER_ALLOCATED,
			"reserve30": FOUNDER_RESERVE,
			"reserve_compartments": [15, 15],
			"reconciled": true,
		},
		"vault_12": {
			"total": VAULT_TOTAL,
			"distinct_specimens": VAULT_TOTAL,
			"stored": VAULT_TOTAL,
			"cotton_planted": 0,
			"stored_after_cotton": VAULT_TOTAL,
		},
		"cotton_1_11": {
			"cotton_planted": COTTON_PLANTED,
			"vault_stored": COTTON_STORED_AFTER_PLANTING,
			"planted_at": "2046-12-15",
		},
	}

func _operation(operation: String, plant: Dictionary, scenario_datetime: String) -> Dictionary:
	var result := {
		"schema_version": SCHEMA_VERSION,
		"operation": operation,
		"accepted": false,
		"duplicate": false,
		"reason": "",
		"events": [],
		"plant": plant.duplicate(true),
		"scenario_datetime": scenario_datetime,
	}
	var validation := validate_plant(plant)
	if not bool(validation.get("valid", false)):
		result["reason"] = validation.get("reason", "Malformed plant state.")
		return result
	if String(plant.get("individual_id", "")).is_empty() or String(plant.get("planted_at", "")).is_empty():
		result["reason"] = "Plant identity and planted_at are required primitive fields."
		return result
	if _day_number(scenario_datetime) < _day_number(String(plant.get("planted_at", ""))):
		result["reason"] = "A dated care or lifecycle transition cannot occur before planting."
		return result
	var canonical_reason := _canonical_identity_reason(plant)
	if not canonical_reason.is_empty():
		result["reason"] = canonical_reason
		return result
	if not String(plant.get("last_advanced_at", "")).is_empty() and _datetime_before(scenario_datetime, String(plant.get("last_advanced_at", ""))):
		result["reason"] = "A lifecycle transition cannot move backward before the last advanced date."
		return result
	if not STAGES.has(String(plant.get("stage", ""))):
		result["reason"] = "Unknown plant stage."
		return result
	if String(plant.get("enclosure", "pressurised_garden")) not in ["pressurised_garden", "pressurised_reference_bay", "pressurised_annex"]:
		result["reason"] = "Plants must remain inside a pressurised enclosure."
		return result
	result["accepted"] = true
	return result

func _date_key(value: String) -> String:
	return value.substr(0, 10)

func _datetime_before(left: String, right: String) -> bool:
	var left_day := _day_number(left)
	var right_day := _day_number(right)
	if left_day != right_day:
		return left_day < right_day
	return left < right

func _canonical_identity_reason(plant: Dictionary) -> String:
	var individual_id := String(plant.get("individual_id", ""))
	var plant_type := String(plant.get("plant_type", "mustard")).to_lower()
	var planted_date := _date_key(String(plant.get("planted_at", "")))
	var lineage_id := String(plant.get("lineage_id", ""))
	if individual_id == ALO_ID:
		if planted_date != ALO_PLANTED_DATE:
			return "Alo ALO-01 must be planted on 2046-04-11."
		if plant_type != "mustard" or lineage_id != ALO_TARA_LINEAGE:
			return "Alo ALO-01 must retain its canonical mustard identity and lineage."
	if individual_id == TARA_ID:
		if planted_date != TARA_PLANTED_DATE:
			return "Tara TARA-01 must be planted on 2046-04-11."
		if plant_type != "mustard" or lineage_id != ALO_TARA_LINEAGE:
			return "Tara TARA-01 must retain its canonical mustard identity and lineage."
	if individual_id == COTTON_ID:
		if planted_date != COTTON_PLANTED_DATE:
			return "Cotton COTTON-01 must be planted on 2046-12-15."
		if plant_type != "cotton" or lineage_id != COTTON_LINEAGE:
			return "Cotton COTTON-01 must retain its canonical reference identity and lineage."
	if plant_type == "cotton" and individual_id != COTTON_ID:
		return "Only canonical Cotton COTTON-01 may use the cotton plant identity."
	return ""

func _day_number(value: String) -> int:
	var date := _date_key(value).split("-")
	if date.size() != 3:
		return -999999
	var year := int(date[0])
	var month := int(date[1])
	var day := int(date[2])
	# Civil-date serial (proleptic Gregorian), sufficient for authored dates.
	var adjusted_year := year - (1 if month <= 2 else 0)
	var era := floori(adjusted_year / 400.0)
	var year_of_era := adjusted_year - era * 400
	var month_prime := month + (-3 if month > 2 else 9)
	var day_of_year := floori((153 * month_prime + 2) / 5.0) + day - 1
	var day_of_era := year_of_era * 365 + floori(year_of_era / 4.0) - floori(year_of_era / 100.0) + day_of_year
	return era * 146097 + day_of_era
