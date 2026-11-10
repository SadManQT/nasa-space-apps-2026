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
		"description": "Kept the battery above the dark-shift reserve every shift during the 36-hour Commissioning Night."
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

static func _unlocked_ids(snapshot: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	if snapshot.is_empty():
		return out
	var chapter := int(snapshot.get("current_chapter", snapshot.get("chapter", 1)))
	var completed_missions: Array = []
	if snapshot.get("completed_missions") is Array:
		completed_missions = snapshot.get("completed_missions")
	var book: Dictionary = snapshot.get("campaign_ledgers", {}) if snapshot.get("campaign_ledgers") is Dictionary else {}
	var puzzles: Dictionary = book.get("puzzles", {}) if book.get("puzzles") is Dictionary else {}
	var ops: Dictionary = book.get("operations", {}) if book.get("operations") is Dictionary else {}
	var route: Dictionary = snapshot.get("route", {}) if snapshot.get("route") is Dictionary else {}
	var resources: Dictionary = snapshot.get("resources", {}) if snapshot.get("resources") is Dictionary else {}

	# Chapter 1 checks
	if chapter > 1 or completed_missions.has("EX-M0101") or puzzles.has("P-01"):
		out["ach_alo_commissioned"] = true
	if chapter > 1 or completed_missions.has("EX-M0103") or float(resources.get("S", 0.0)) >= 4.0:
		out["ach_shelter_wall_stacked"] = true
	if chapter > 1 or (completed_missions.has("EX-M0104") and float(resources.get("E", 0.0)) >= 4.0):
		out["ach_dark_shift_reserve"] = true

	# Chapter 2 checks
	if chapter > 2 or puzzles.has("P-03") or completed_missions.has("EX-M0202"):
		out["ach_cross_pollination"] = true
	if chapter > 2 or puzzles.has("P-04") or completed_missions.has("EX-M0204"):
		out["ach_recorder_reconstructed"] = true

	# Chapter 3 checks
	if chapter > 3 or puzzles.has("P-05") or completed_missions.has("EX-M0302"):
		out["ach_pressure_isolated"] = true
	if chapter > 3 or puzzles.has("P-06") or completed_missions.has("EX-M0304"):
		out["ach_founder_harvest_42"] = true

	# Chapter 4 checks
	if chapter > 4 or puzzles.has("P-07") or String(route.get("ch04_route", "")) == "B":
		out["ach_viper_slope_route_b"] = true
	if chapter > 4 or (ops.has("p07_place_beacon_1") and ops.has("p07_place_beacon_2") and ops.has("p07_place_beacon_3")):
		out["ach_three_ridge_beacons"] = true
	if chapter > 4 or puzzles.has("P-08") or completed_missions.has("EX-M0404"):
		out["ach_cold_trap_warmup"] = true

	# Chapter 5 checks
	if chapter > 5 or puzzles.has("P-09") or completed_missions.has("EX-M0502"):
		out["ach_coincidence_126"] = true
	if chapter > 5 or puzzles.has("P-10") or completed_missions.has("EX-M0504"):
		out["ach_founder_reserve_30"] = true

	# Chapter 6 checks
	if chapter > 6 or puzzles.has("P-11") or completed_missions.has("EX-M0602"):
		out["ach_eclipse_reserve_7"] = true
	if chapter > 6 or puzzles.has("P-12") or completed_missions.has("EX-M0604"):
		out["ach_feeder_five_steps"] = true

	# Chapter 7 checks
	if chapter > 7 or puzzles.has("P-13") or completed_missions.has("EX-M0702"):
		out["ach_storm_shelter_run"] = true
	if chapter > 7 or puzzles.has("P-14") or completed_missions.has("EX-M0704"):
		out["ach_tara_relay_verified"] = true

	# Chapter 8 checks
	if puzzles.has("P-15") or completed_missions.has("EX-M0801") or String(route.get("ch08_route", "")) == "SURVEYED":
		out["ach_malapert_road_4_reserve"] = true
	if puzzles.has("P-16") or completed_missions.has("EX-M0803") or String(route.get("earth_leg", "")) == "verified":
		out["ach_dual_link_alo42"] = true
	if completed_missions.has("EX-M0804") or String(snapshot.get("ending", "")) in ["BLOOM", "GOLDEN"]:
		out["ach_golden_bloom"] = true

	# Skill progression check
	var resume: Dictionary = snapshot.get("presentation_resume", {}) if snapshot.get("presentation_resume") is Dictionary else {}
	var prog_dict: Dictionary = resume.get("cadet_progression", {}) if resume.get("cadet_progression") is Dictionary else {}
	var prog := CadetProgression.new()
	prog.restore(prog_dict)
	var all_ranked := true
	for skill_id in ["navigation", "handling", "life_support", "repair", "observation"]:
		if prog.skill_rank(skill_id) < 1 and chapter < 6:
			all_ranked = false
	if all_ranked:
		out["ach_all_five_skills"] = true

	return out
