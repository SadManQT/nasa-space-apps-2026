extends RefCounted
class_name CadetProgression

## M3-64: The RPG layer (doc 25 §4.6) and post-chapter upgrade pairs (M3-4U,
## M3-6U, M3-8U):
## - Report cards after every sortie and job (time against plan, payload
##   condition, care, science value, reserve kept — training grades, never
##   story gates).
## - Five cadet skills (navigation, handling, life_support, repair,
##   observation) with 3 ranks each, small visible benefits, and a crew line
##   per rank from the crew member who taught it.
## - Gear loadout slots equipped from earned chapter upgrades with a weight
##   limit (real trade-offs).
## - Jobs board with 32 optional jobs across all 8 chapters (4 per chapter
##   region), each linked to a sender and reason in Messages.
## - Rest at the Safe Room bunks (save, messages, photos, cadet record).

const JOBS_PATH := "res://resources/campaign/content/jobs.json"

const UPGRADE_PAIRS := {
	1: {
		"after_chapter": 1,
		"title": "After Chapter 1 · Night One",
		"story_bridge": "Sunrise warms the ridge. Choose one station improvement before the pollination window opens.",
		"A": {"id": "taller_mast", "label": "Taller solar mast", "summary": "+2 daylight battery income in solar planning (cap 20).", "before": "Daylight income: +8 battery per shift", "after": "Daylight income: +10 battery per shift (capped at 20)"},
		"B": {"id": "fuel_cell", "label": "Auxiliary fuel cell", "summary": "+4 starting battery and capacity raised from 20 to 22.", "before": "Battery start 14 / capacity 20", "after": "Battery start 18 / capacity 22"},
	},
	2: {
		"after_chapter": 2,
		"title": "After Chapter 2 · Be the Bee",
		"story_bridge": "Alo and Tara's cross-pollination is complete, and a shallow tremor just shook the ridge.",
		"A": {"id": "red_blue_leds", "label": "Red-blue LED bar", "summary": "Full garden light costs 1 battery instead of 2.", "before": "Full lamp: 2 battery per shift", "after": "Full lamp: 1 battery per shift"},
		"B": {"id": "insulation_blankets", "label": "Chamber insulation blanket", "summary": "Cool night heat no longer harms Alo (-0 instead of -1).", "before": "Cool heat: Alo -1 health", "after": "Cool heat: Alo -0 health"},
	},
	3: {
		"after_chapter": 3,
		"title": "After Chapter 3 · Moonquake",
		"story_bridge": "Forty-two founder seeds are counted, twelve are planted, and Expedition Zero's cold-trap map lies open.",
		"A": {"id": "moon_dirt_shelter", "label": "Moon-dirt shelter bags", "summary": "+1 permanent effective storm shielding (total shelter capped at 6).", "before": "Base permanent shelter bonus: +0 (cap 6)", "after": "Permanent shelter bonus: +1 (cap 6)"},
		"B": {"id": "flexible_seals", "label": "Flexible manifold seals", "summary": "Unresolved air leak loss halved from 1.0 to 0.5 air per phase.", "before": "Unresolved leak loss: 1.0 air per phase", "after": "Unresolved leak loss: 0.5 air per phase"},
	},
	4: {
		"after_chapter": 4,
		"title": "After Chapter 4 · Into the Cold Trap",
		"story_bridge": "The cold-trap vault is home and twelve seeds are safe in the annex.",
		"A": {"id": "ice_harvester", "label": "Cold-trap ice harvester", "summary": "+2 dedicated shelter water without borrowing garden water.", "before": "Separate shelter water: 0", "after": "Separate shelter water: +2"},
		"B": {"id": "rover_lights_heater", "label": "Rover lamps & cabin heater", "summary": "Warm cab readout and clearer dark-slope visibility on traverses.", "before": "Standard rover headlamps", "after": "High-beam lamps & heated cab"},
	},
	5: {
		"after_chapter": 5,
		"title": "After Chapter 5 · Shooting Stars",
		"story_bridge": "Noor's name is known, the cotton seed is planted, and the January total eclipse approaches.",
		"A": {"id": "dust_shield", "label": "Electrostatic dust shield", "summary": "Prevents solar dust income loss; verify the clean surface instead.", "before": "Dust event: -2 daylight battery until cleaned", "after": "Dust event prevented (0 loss; verify clean surface)"},
		"B": {"id": "whipple_bumper", "label": "Whipple dome bumper", "summary": "Prevents small-impact dome micro-leak; verify pressure instead.", "before": "Micro-impact: -1 air per phase until patched", "after": "Micro-leak prevented (0 loss; verify pressure)"},
	},
	6: {
		"after_chapter": 6,
		"title": "After Chapter 6 · The Red Ring",
		"story_bridge": " Aurora rode out the five-hour red-ring eclipse; space-weather monitors now watch for the major storm.",
		"A": {"id": "storm_early_warning", "label": "Particle early-warning sensor", "summary": "Earlier proton-flux trend alert before storm shelter runs.", "before": "Standard storm lead time", "after": "Early proton-flux warning"},
		"B": {"id": "bigger_safe_room", "label": "Expanded Safe Room rack", "summary": "Full supply stack adds 3 crate shielding instead of 2 (cap 3).", "before": "Full supply stack: crates 2 (K2)", "after": "Full supply stack: crates 3 (K3)"},
	},
	7: {
		"after_chapter": 7,
		"title": "After Chapter 7 · The Great Storm",
		"story_bridge": "The crew and the cotton bud survived the storm. Only the 120 km Malapert relay road remains.",
		"A": {"id": "relay_parts_kit", "label": "Relay connector kit", "summary": "Skips one connector diagnosis stage on the summit; bearings still verified.", "before": "Full 3-stage connector diagnosis", "after": "Skips 1 connector stage (bearings still verified)"},
		"B": {"id": "long_range_battery", "label": "Long-range rover battery", "summary": "Rover battery capacity and entry charge +4 (from 14 to 18 in Chapter 8).", "before": "Chapter 8 rover battery: 14 / 14 (reserve 4)", "after": "Chapter 8 rover battery: 18 / 18 (reserve 4)"},
	},
}

static var _catalog: Dictionary = {}

var skill_points: Dictionary = {
	"navigation": 0,
	"handling": 0,
	"life_support": 0,
	"repair": 0,
	"observation": 0,
}
var completed_jobs: Dictionary = {}
var report_cards: Array = []
var equipped_gear: Array = []
var unlocked_upgrades: Dictionary = {}
var rest_count: int = 0

static func catalog() -> Dictionary:
	if _catalog.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(JOBS_PATH))
		_catalog = parsed if parsed is Dictionary else {}
	return _catalog

static func max_gear_slots() -> int:
	return int(catalog().get("max_gear_slots", 3))

static func max_gear_mass_kg() -> float:
	return float(catalog().get("max_gear_mass_kg", 10.0))

## Evaluates a sortie or job into a training report card (never locks story).
func record_sortie_report(entry: Dictionary) -> Dictionary:
	if entry.has("measured_metrics") and entry.measured_metrics is Dictionary:
		var measured_card := {
			"id": String(entry.get("id", "SORTIE-%02d" % (report_cards.size() + 1))),
			"title": String(entry.get("title", "Field Sortie")),
			"chapter": int(entry.get("chapter", 1)),
			"grade": "Completed",
			"measured_metrics": (entry.measured_metrics as Dictionary).duplicate(true),
			"note": "Training grade only — story progress is never locked by a report card.",
		}
		report_cards.append(measured_card)
		var measured_skill := String(entry.get("skill", ""))
		if skill_points.has(measured_skill):
			add_skill_xp(measured_skill, int(entry.get("xp", 1)))
		return measured_card
	var time_ratio := float(entry.get("actual_minutes", 15.0)) / maxf(1.0, float(entry.get("planned_minutes", 15.0)))
	var time_score := 100 if time_ratio <= 1.15 else (80 if time_ratio <= 1.4 else 60)
	var condition_score := 100 if bool(entry.get("payload_intact", true)) else 65
	var care_score := clampi(int(entry.get("care_score", 95)), 0, 100)
	var science_score := clampi(int(entry.get("science_score", 90)), 0, 100)
	var reserve_pct := float(entry.get("reserve_kept_pct", 30.0))
	var reserve_target := float(entry.get("reserve_target_pct", 25.0))
	var reserve_score := 100 if reserve_pct >= reserve_target else (75 if reserve_pct >= reserve_target * 0.6 else 50)

	var average := (float(time_score + condition_score + care_score + science_score + reserve_score)) / 5.0
	var grade := "Distinction" if average >= 90.0 else ("Merit" if average >= 75.0 else "Completed")
	var card := {
		"id": String(entry.get("id", "SORTIE-%02d" % (report_cards.size() + 1))),
		"title": String(entry.get("title", "Field Sortie")),
		"chapter": int(entry.get("chapter", 1)),
		"time_score": time_score,
		"condition_score": condition_score,
		"care_score": care_score,
		"science_score": science_score,
		"reserve_score": reserve_score,
		"average": snappedf(average, 0.1),
		"grade": grade,
		"note": "Training grade only — story progress is never locked by a report card.",
	}
	report_cards.append(card)
	var skill_id := String(entry.get("skill", ""))
	if skill_points.has(skill_id):
		add_skill_xp(skill_id, int(entry.get("xp", 1)))
	return card

func add_skill_xp(skill_id: String, amount: int = 1) -> Dictionary:
	if not skill_points.has(skill_id) or amount <= 0:
		return {"accepted": false, "reason": "Unknown skill or non-positive XP."}
	var before_rank := skill_rank(skill_id)
	skill_points[skill_id] = int(skill_points.get(skill_id, 0)) + amount
	var after_rank := skill_rank(skill_id)
	return {
		"accepted": true,
		"skill": skill_id,
		"points": int(skill_points[skill_id]),
		"before_rank": before_rank,
		"after_rank": after_rank,
		"ranked_up": after_rank > before_rank,
		"info": skill_info(skill_id),
	}

func skill_rank(skill_id: String) -> int:
	var pts := int(skill_points.get(skill_id, 0))
	var spec := _skill_spec(skill_id)
	var thresholds: Array = spec.get("thresholds", [1, 3, 6])
	var r := 0
	for i in thresholds.size():
		if pts >= int(thresholds[i]):
			r = i + 1
	return r

func skill_info(skill_id: String) -> Dictionary:
	var spec := _skill_spec(skill_id)
	if spec.is_empty():
		return {}
	var r := skill_rank(skill_id)
	var pts := int(skill_points.get(skill_id, 0))
	var thresholds: Array = spec.get("thresholds", [1, 3, 6])
	var next_threshold := int(thresholds[r]) if r < thresholds.size() else int(thresholds.back())
	var benefit := "Practice this skill in sorties and station jobs to earn Rank 1."
	var crew_line := "%s: Ready when you are." % String(spec.get("teacher", "Crew"))
	var ranks: Array = spec.get("ranks", [])
	if r > 0 and r <= ranks.size():
		var rk: Dictionary = ranks[r - 1]
		benefit = String(rk.get("benefit", benefit))
		crew_line = String(rk.get("crew_line", crew_line))
	return {
		"id": skill_id,
		"label": String(spec.get("label", skill_id.capitalize())),
		"teacher": String(spec.get("teacher", "")),
		"rank": r,
		"max_rank": thresholds.size(),
		"points": pts,
		"next_threshold": next_threshold,
		"benefit": benefit,
		"crew_line": crew_line,
	}

func all_skills_info() -> Array:
	var out: Array = []
	for spec in catalog().get("skills", []):
		out.append(skill_info(String(spec.get("id", ""))))
	return out

func _skill_spec(skill_id: String) -> Dictionary:
	for spec in catalog().get("skills", []):
		if String(spec.get("id", "")) == skill_id:
			return spec
	return {}

## Unlocks a chapter's upgrade choice ("A" or "B") after that chapter completes.
## Mutually exclusive per chapter; idempotent on repeat calls with the same option.
func choose_upgrade(after_chapter: int, option: String, completed_chapters: Array = []) -> Dictionary:
	if not UPGRADE_PAIRS.has(after_chapter):
		return {"accepted": false, "reason": "No upgrade pair exists after chapter %d." % after_chapter}
	var clean := option.strip_edges().to_upper()
	if not clean in ["A", "B"]:
		return {"accepted": false, "reason": "Choose Option A or Option B."}
	if not completed_chapters.has(after_chapter) and not unlocked_upgrades.has(str(after_chapter)):
		return {"accepted": false, "reason": "Complete Chapter %d before choosing its upgrade." % after_chapter}
	var key := str(after_chapter)
	if unlocked_upgrades.has(key) and String(unlocked_upgrades[key]) != clean:
		return {"accepted": false, "reason": "Chapter %d upgrade is already locked to Option %s." % [after_chapter, String(unlocked_upgrades[key])]}
	unlocked_upgrades[key] = clean
	var pair: Dictionary = UPGRADE_PAIRS[after_chapter]
	var chosen: Dictionary = pair[clean]
	return {
		"accepted": true,
		"chapter": after_chapter,
		"option": clean,
		"upgrade_id": String(chosen.id),
		"label": String(chosen.label),
		"summary": String(chosen.summary),
	}

## Syncs unlocked upgrades from a campaign state's `upgrades.choices` dictionary.
func sync_upgrades_from_snapshot(snapshot: Dictionary) -> void:
	var choices: Dictionary = snapshot.get("upgrades", {}).get("choices", {})
	for k in choices:
		var ch := int(str(k).trim_prefix("CH0").trim_prefix("ch0").trim_prefix("after_ch"))
		if ch >= 1 and ch <= 7:
			var val := String(choices[k]).strip_edges().to_upper()
			if val in ["A", "B"]:
				unlocked_upgrades[str(ch)] = val
			else:
				for opt in ["A", "B"]:
					if String(UPGRADE_PAIRS[ch][opt].id) == String(choices[k]):
						unlocked_upgrades[str(ch)] = opt

## Exports `upgrades.choices` in the format `ExpeditionSimulation` expects.
func export_upgrade_choices() -> Dictionary:
	var out: Dictionary = {}
	for k in unlocked_upgrades:
		out[int(k)] = String(unlocked_upgrades[k])
	return out

func available_gear() -> Array:
	var earned_ids: Array = []
	for k in unlocked_upgrades:
		var ch := int(k)
		var opt := String(unlocked_upgrades[k])
		if UPGRADE_PAIRS.has(ch) and UPGRADE_PAIRS[ch].has(opt):
			earned_ids.append(String(UPGRADE_PAIRS[ch][opt].id))
	var out: Array = []
	for item in catalog().get("gear_catalog", []):
		var id := String(item.get("id", ""))
		if earned_ids.has(id):
			var copy: Dictionary = item.duplicate(true)
			copy["equipped"] = equipped_gear.has(id)
			out.append(copy)
	return out

func equipped_mass_kg() -> float:
	var total := 0.0
	for item in catalog().get("gear_catalog", []):
		if equipped_gear.has(String(item.get("id", ""))):
			total += float(item.get("mass_kg", 0.0))
	return snappedf(total, 0.1)

func equip_gear(gear_id: String) -> Dictionary:
	if equipped_gear.has(gear_id):
		return {"accepted": true, "reason": "Already equipped.", "mass_kg": equipped_mass_kg()}
	var spec := _gear_spec(gear_id)
	if spec.is_empty():
		return {"accepted": false, "reason": "Unknown gear item."}
	var earned := false
	for g in available_gear():
		if String(g.id) == gear_id:
			earned = true
			break
	if not earned:
		return {"accepted": false, "reason": "Earn %s at its chapter upgrade choice first." % String(spec.get("label", gear_id))}
	if equipped_gear.size() >= max_gear_slots():
		return {"accepted": false, "reason": "All %d gear slots are full. Unequip an item first." % max_gear_slots()}
	var next_mass := equipped_mass_kg() + float(spec.get("mass_kg", 0.0))
	if next_mass > max_gear_mass_kg():
		return {"accepted": false, "reason": "Loadout weight limit is %s kg; adding %s would reach %s kg." % [
			UiDesign.number(max_gear_mass_kg()),
			String(spec.get("label", gear_id)),
			UiDesign.number(next_mass)
		]}
	equipped_gear.append(gear_id)
	return {
		"accepted": true,
		"reason": "Equipped %s (%s kg)." % [String(spec.get("label", gear_id)), UiDesign.number(float(spec.get("mass_kg", 0.0)))],
		"mass_kg": equipped_mass_kg(),
	}

func unequip_gear(gear_id: String) -> Dictionary:
	if not equipped_gear.has(gear_id):
		return {"accepted": false, "reason": "Item is not equipped."}
	equipped_gear.erase(gear_id)
	return {"accepted": true, "reason": "Unequipped item.", "mass_kg": equipped_mass_kg()}

func _gear_spec(gear_id: String) -> Dictionary:
	for item in catalog().get("gear_catalog", []):
		if String(item.get("id", "")) == gear_id:
			return item
	return {}

## Jobs board: returns all jobs unlocked up to `max_chapter`.
func jobs_for_chapter(chapter: int) -> Array:
	var out: Array = []
	for job in catalog().get("jobs", []):
		if int(job.get("chapter", 1)) == chapter:
			var copy: Dictionary = job.duplicate(true)
			copy["completed"] = completed_jobs.has(String(job.get("id", "")))
			out.append(copy)
	return out

func all_jobs_up_to(max_chapter: int) -> Array:
	var out: Array = []
	for job in catalog().get("jobs", []):
		if int(job.get("chapter", 1)) <= max_chapter:
			var copy: Dictionary = job.duplicate(true)
			copy["completed"] = completed_jobs.has(String(job.get("id", "")))
			out.append(copy)
	return out

func complete_job(job_id: String, max_unlocked_chapter: int = 8, performance: Dictionary = {}) -> Dictionary:
	var spec := _job_spec(job_id)
	if spec.is_empty():
		return {"accepted": false, "reason": "Unknown job: " + job_id}
	var ch := int(spec.get("chapter", 1))
	if ch > max_unlocked_chapter:
		return {"accepted": false, "reason": "Reach Chapter %d to unlock %s." % [ch, String(spec.get("title", job_id))]}
	if completed_jobs.has(job_id):
		return {"accepted": false, "reason": "Job already completed."}
	var skill_id := String(spec.get("skill", "observation"))
	var xp := int(spec.get("xp", 1))
	var report_entry := {
		"id": job_id,
		"title": String(spec.get("title", job_id)),
		"chapter": ch,
		"skill": skill_id,
		"xp": xp,
		"actual_minutes": float(performance.get("actual_minutes", 12.0)),
		"planned_minutes": float(performance.get("planned_minutes", 12.0)),
		"payload_intact": bool(performance.get("payload_intact", true)),
		"care_score": int(performance.get("care_score", 96)),
		"science_score": int(performance.get("science_score", 94)),
		"reserve_kept_pct": float(performance.get("reserve_kept_pct", 32.0)),
	}
	if performance.has("measured_metrics") and performance.measured_metrics is Dictionary:
		report_entry["measured_metrics"] = (performance.measured_metrics as Dictionary).duplicate(true)
	var report := record_sortie_report(report_entry)
	completed_jobs[job_id] = {
		"completed_at": String(performance.get("when", "2046-04-25T12:00Z")),
		"grade": String(report.grade),
		"crew_note": String(spec.get("crew_note", "")),
	}
	return {
		"accepted": true,
		"job_id": job_id,
		"title": String(spec.get("title", "")),
		"sender": String(spec.get("sender", "")),
		"message_id": String(spec.get("message_id", "")),
		"crew_note": String(spec.get("crew_note", "")),
		"skill": skill_info(skill_id),
		"report_card": report,
	}

func _job_spec(job_id: String) -> Dictionary:
	for job in catalog().get("jobs", []):
		if String(job.get("id", "")) == job_id:
			return job
	return {}

## Safe Room bunk rest (LOC-04): increments rest log, returns summary of save,
## unread messages, Alo/Tara photos and cadet record.
func rest_at_bunk(unread_messages: int = 0, photo_count: int = 2) -> Dictionary:
	rest_count += 1
	return {
		"accepted": true,
		"rest_count": rest_count,
		"location_id": "LOC-04",
		"summary": "Rested at Safe Room bunk · Checkpoint saved · %d unread messages · %d plant photos · %d sorties logged." % [
			unread_messages, photo_count, report_cards.size()
		],
	}

func snapshot() -> Dictionary:
	return {
		"schema_version": 1,
		"skill_points": skill_points.duplicate(true),
		"completed_jobs": completed_jobs.duplicate(true),
		"report_cards": report_cards.duplicate(true),
		"equipped_gear": equipped_gear.duplicate(true),
		"unlocked_upgrades": unlocked_upgrades.duplicate(true),
		"rest_count": rest_count,
	}

func restore(state: Dictionary) -> bool:
	if not state is Dictionary:
		return false
	if state.get("skill_points") is Dictionary:
		for k in skill_points.keys():
			skill_points[k] = maxi(0, int(state.skill_points.get(k, 0)))
	if state.get("completed_jobs") is Dictionary:
		completed_jobs = state.completed_jobs.duplicate(true)
	if state.get("report_cards") is Array:
		report_cards = state.report_cards.duplicate(true)
	if state.get("unlocked_upgrades") is Dictionary:
		unlocked_upgrades = state.unlocked_upgrades.duplicate(true)
	if state.get("equipped_gear") is Array:
		equipped_gear.clear()
		for g in state.equipped_gear:
			equip_gear(String(g))
	rest_count = maxi(0, int(state.get("rest_count", 0)))
	return true
