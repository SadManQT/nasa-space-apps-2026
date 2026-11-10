extends RefCounted
class_name CadetAchievements

## M3-72: Act One skill achievements (20 total), each tied to a real operational
## skill, puzzle solution or field milestone across Chapters 1–8. Evaluated
## strictly read-only from a campaign save snapshot and/or CadetProgression state.

const ACHIEVEMENTS := [
	{
		"id": "ach_dark_shift_reserve",
		"title": "Night Watch Margin",
		"skill": "life_support",
		"chapter": 1,
		"description": "Completed all seven commissioning shifts without a blackout."
	},
	{
		"id": "ach_alo_commissioned",
		"title": "First True Leaf",
		"skill": "observation",
		"chapter": 1,
		"description": "Verified the zero, reference and probe chain on Chamber One and commissioned Alo without guessing."
	},
	{
		"id": "ach_shelter_wall_stacked",
		"title": "Water in the Wall",
		"skill": "handling",
		"chapter": 1,
		"description": "Stacked the Safe Room supplies and filled the water wall before the solar proton peak."
	},
	{
		"id": "ach_cross_pollination",
		"title": "Be the Bee",
		"skill": "handling",
		"chapter": 2,
		"description": "Cross-pollinated Alo and Tara with clean brush transfers and verified parent lineage."
	},
	{
		"id": "ach_recorder_reconstructed",
		"title": "Observed vs Inferred",
		"skill": "observation",
		"chapter": 2,
		"description": "Reconstructed the five-frame recorder strip in chronological order without mixing inference into observed facts."
	},
	{
		"id": "ach_pressure_isolated",
		"title": "Zero Trunk Loss",
		"skill": "repair",
		"chapter": 3,
		"description": "Isolated the moonquake manifold leak on Branch B while keeping the main habitat trunk pressurized."
	},
	{
		"id": "ach_founder_harvest_42",
		"title": "Forty-Two Founder Seeds",
		"skill": "life_support",
		"chapter": 3,
		"description": "Counted all 42 mature pods and split 30 into the vault reserve and 12 into the active planting tray."
	},
	{
		"id": "ach_viper_slope_route_b",
		"title": "Switchback Navigator",
		"skill": "navigation",
		"chapter": 4,
		"description": "Selected Route B into the cold trap within the 15° VIPER slope limit and kept 40 battery in reserve."
	},
	{
		"id": "ach_three_ridge_beacons",
		"title": "Line of Sight on the Ridge",
		"skill": "navigation",
		"chapter": 4,
		"description": "Placed all three Chapter 4 survey beacons along the Shackleton–de Gerlache ridge road."
	},
	{
		"id": "ach_cold_trap_warmup",
		"title": "Warm Before Opening",
		"skill": "handling",
		"chapter": 4,
		"description": "Warmed the −183 °C cold-trap vault canister to +18 °C before breaking the seal."
	},
	{
		"id": "ach_coincidence_126",
		"title": "Dual-Telescope Coincidence",
		"skill": "observation",
		"chapter": 5,
		"description": "Filtered single-detector glitches and confirmed real meteoroid impact flashes by two-telescope coincidence."
	},
	{
		"id": "ach_founder_reserve_30",
		"title": "Seed Steward",
		"skill": "life_support",
		"chapter": 5,
		"description": "Kept the 30-seed founder reserve untouched while allocating only the 12 active seeds across trays."
	},
	{
		"id": "ach_eclipse_reserve_7",
		"title": "Red-Ring Reserve",
		"skill": "life_support",
		"chapter": 6,
		"description": "Held the 7-unit post-eclipse recovery reserve intact across the 5-hour total lunar eclipse."
	},
	{
		"id": "ach_feeder_five_steps",
		"title": "Fault Isolated in Five",
		"skill": "repair",
		"chapter": 6,
		"description": "Isolated the rim-camera feeder fault and restored power in five safe steps."
	},
	{
		"id": "ach_storm_shelter_run",
		"title": "Proton Shelter Run",
		"skill": "life_support",
		"chapter": 7,
		"description": "Completed the solar-storm shelter checklist and kept crew radiation exposure at zero."
	},
	{
		"id": "ach_tara_relay_verified",
		"title": "Two Independent Hops",
		"skill": "repair",
		"chapter": 7,
		"description": "Restored the storm-damaged local relay chain and verified telemetry before transmitting."
	},
	{
		"id": "ach_malapert_road_4_reserve",
		"title": "The 120-Kilometre Road",
		"skill": "navigation",
		"chapter": 8,
		"description": "Planned the Malapert summit traverse over the surveyed beacons with at least 4 battery reserve remaining."
	},
	{
		"id": "ach_dual_link_alo42",
		"title": "ALO42 Live Link",
		"skill": "repair",
		"chapter": 8,
		"description": "Verified local bearing L2, Earth bearing E3 and echo code ALO42 before opening the live summit voice call."
	},
	{
		"id": "ach_all_five_skills",
		"title": "Well-Rounded Cadet",
		"skill": "navigation",
		"chapter": 4,
		"description": "Earned at least Rank 1 in Navigation, Handling, Life Support, Repair and Observation."
	},
	{
		"id": "ach_golden_bloom",
		"title": "Golden Bloom",
		"skill": "observation",
		"chapter": 8,
		"description": "Guided Alo, Tara and the first lunar cotton flower to open in the greenhouse."
	}
]

static func catalog() -> Array:
	return ACHIEVEMENTS.duplicate(true)

## Pure read-only evaluation of all 20 Act One skill achievements against a save snapshot.
static func evaluate(snapshot: Dictionary) -> Array:
	var unlocked := _unlocked_ids(snapshot)
	var rows: Array = []
	for item in ACHIEVEMENTS:
		var entry: Dictionary = item.duplicate(true)
		var aid := String(entry.get("id", ""))
		entry["unlocked"] = bool(unlocked.get(aid, false))
		rows.append(entry)
	return rows

static func unlocked_count(snapshot: Dictionary) -> int:
	var count := 0
	for row in evaluate(snapshot):
		if bool(row.get("unlocked", false)):
			count += 1
	return count

static func chapter_number(snapshot: Dictionary) -> int:
	return clampi(int(String(snapshot.get("chapter_id", "CH01")).trim_prefix("CH")), 1, 8)

static func _unlocked_ids(snapshot: Dictionary) -> Dictionary:
	var out := {}
	var completed: Array = snapshot.get("completed_scene_ids", [])
	# Every listed scene has an authoritative physical exit gate; merely entering a chapter earns nothing.
	var gates := {
		"ach_alo_commissioned": "EX-CH01-S04",
		"ach_shelter_wall_stacked": "EX-CH01-S10",
		"ach_cross_pollination": "EX-CH02-S05",
		"ach_recorder_reconstructed": "EX-CH02-S12",
		"ach_pressure_isolated": "EX-CH03-S03",
		"ach_founder_harvest_42": "EX-CH03-S10",
		"ach_viper_slope_route_b": "EX-CH04-S04",
		"ach_three_ridge_beacons": "EX-CH04-S02",
		"ach_cold_trap_warmup": "EX-CH04-S10",
		"ach_coincidence_126": "EX-CH05-S07",
		"ach_founder_reserve_30": "EX-CH05-S12",
		"ach_eclipse_reserve_7": "EX-CH06-S03",
		"ach_feeder_five_steps": "EX-CH06-S09",
		"ach_storm_shelter_run": "EX-CH07-S03",
		"ach_tara_relay_verified": "EX-CH07-S09",
		"ach_malapert_road_4_reserve": "EX-CH08-S04",
		"ach_dual_link_alo42": "EX-CH08-S09",
		"ach_golden_bloom": "EX-CH08-S12",
	}
	for achievement in gates:
		if completed.has(gates[achievement]):
			out[achievement] = true
	var night_complete := false
	var blackout := false
	for receipt in snapshot.get("receipts", {}).values():
		for trace in receipt.get("trace", []):
			blackout = blackout or bool(trace.get("blackout", false))
			night_complete = night_complete or int(trace.get("shift", 0)) == 7
	if night_complete and not blackout:
		out["ach_dark_shift_reserve"] = true
	var resume: Dictionary = snapshot.get("presentation_resume", {})
	var progression := CadetProgression.new()
	progression.restore(resume.get("cadet_progression", {}))
	var all_ranked := true
	for skill_id in ["navigation", "handling", "life_support", "repair", "observation"]:
		if progression.skill_rank(skill_id) < 1:
			all_ranked = false
	if all_ranked:
		out["ach_all_five_skills"] = true
	return out
