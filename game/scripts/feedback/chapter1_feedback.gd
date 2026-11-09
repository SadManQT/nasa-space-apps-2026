extends RefCounted
class_name Chapter1Feedback

## M1-31 — Make it fun: Chapter 1 game-feel, investigation clues, night-shift
## tension, botanical posture (never a face), and reward pass (`22_PUZZLE_CLUE_DESIGN.md` §3).
##
## Every player action produces:
##   1. An observable equipment, item or process consequence
##   2. A plain-English explanation of why
##   3. A meaningful next step
##   4. A subtle meter tick and a short crew reaction line

const MISSION_INVESTIGATIONS := {
	"EX-M0101": {
		"title": "Give the Station a Crew",
		"scenes": ["EX-CH01-S01", "EX-CH01-S02", "EX-CH01-S03"],
		"puzzle_id": "P-01",
		"clues": [
			{"id": "M0101-C1", "kind": "INS", "holder": "K", "where": "Mission table (S01)", "text": "The battery display's gold band is at the top while the mast panel still shows production; an overflow arrow points off the jar."},
			{"id": "M0101-C2", "kind": "DLG", "holder": "A", "where": "S01", "text": "EX-CH01-S01-L02 Amara: \"Only if we notice what spills.\""},
			{"id": "M0101-C3", "kind": "OBJ", "holder": "All", "where": "Mission table (S01)", "text": "Four mugs with no names on the table."},
			{"id": "M0101-C4", "kind": "OBJ+DLG", "holder": "R", "where": "Safe Room doorway (S02)", "text": "Four name tokens on the Safe Room board; EX-CH01-S02-L01 Rafi: \"These are names. We do not spend them.\""},
			{"id": "M0101-C5", "kind": "INS", "holder": "A", "where": "S02", "text": "A disconnected practice panel whose three readouts are tagged LOCAL SENSOR, STORED GUIDANCE, LIVE LINK."},
			{"id": "M0101-C6", "kind": "LOG", "holder": "M", "where": "Dry-storage drawer (S03)", "text": "The sealed dry packet: two seeds, 'ALO' and 'N.' in Latin letters, storage record."},
			{"id": "M0101-C7", "kind": "INS", "holder": "A", "where": "Calibration bench (S03)", "text": "The moisture probe reads 10 in the dry reference cup and 110 in the wet one (offset +10)."},
			{"id": "M0101-C8", "kind": "CARD", "holder": "M", "where": "S03", "text": "Historical card: cotton germinated in China's sealed Chang'e-4 experiment in 2019 (change4_cotton [M])."},
		],
		"aha": "The dry cup reads 10, so every number this probe shows is 10 too high until we set its zero.",
		"wrong_but_reasonable": "Trusting the uncalibrated probe or leaving overflowing battery energy untouched — the seal step stays locked with 'UNCALIBRATED — Check reference first' (FR-06) and nothing is lost.",
		"escalation": "S01 has no wrong answer, only waste → S02 the tokens are people, and the practice fault must be solved without the live link → S03 the first irreplaceable object: two old seeds that cannot be retried.",
		"set_piece": "The inventory lamp blinks, the drawer slides, the music thins to one held note, and the packet fills the frame as Mei reads EX-CH01-S03-L01 ('Alo means light. Someone named the packet before us.').",
		"hints": [
			"Check the instrument before trusting it.",
			"Use the two reference cups.",
			"Dry must read 0, wet 100, then fill both to 50.",
		],
	},
	"EX-M0102": {
		"title": "Two Plants, One Night Plan",
		"scenes": ["EX-CH01-S04", "EX-CH01-S05", "EX-CH01-S06"],
		"puzzle_id": "P-01",
		"clues": [
			{"id": "M0102-C1", "kind": "INS", "holder": "M", "where": "Glove ports (S04)", "text": "Calibrated probe in both cassettes; target band 40–60, nominal 50."},
			{"id": "M0102-C2", "kind": "OBJ+DLG", "holder": "A", "where": "S04", "text": "Two cassette labels EXTERNAL TEST (Alo) and INDOOR REFERENCE (Tara); EX-CH01-S04-L02 Amara: \"A reference is a plant we care for, not one we ignore.\""},
			{"id": "M0102-C3", "kind": "INS", "holder": "R", "where": "S04", "text": "Transfer-lid latch indicator, word plus icon; EX-CH01-S04-L04 Rafi: \"Transfer sealed. Two names, two records.\""},
			{"id": "M0102-C4", "kind": "OBJ", "holder": "K", "where": "Corridor (S05)", "text": "The hand light hung handle-out beside the locker; EX-CH01-S05-L03 Rafi: \"Then it gets a backup. Here.\""},
			{"id": "M0102-C5", "kind": "LOG", "holder": "A", "where": "Care station (S05)", "text": "The dated care notebook; EX-CH01-S05-L04 Amara: \"Fourteen dated care entries. A bud is a useful result.\""},
			{"id": "M0102-C6", "kind": "INS+CARD", "holder": "A", "where": "Mission table (S06)", "text": "Three separate tracks on the horizon display: Sun, Earth link, station systems."},
			{"id": "M0102-C7", "kind": "DLG", "holder": "M, R", "where": "S06", "text": "EX-CH01-S06-L03 Mei: \"Put the garden on it. The shelter borrows from us.\" and EX-CH01-S06-L04 Rafi: \"Put returning the water on it too.\""},
		],
		"aha": "Shielding the crew and watering the garden draw on the same tank, so borrowing must come with a return time.",
		"wrong_but_reasonable": "Keeping the borrowed water in the wall for the rest of the night — the paused forecast shows continued shielding beside the garden thirst it causes (W >= 4), and nothing is spent.",
		"escalation": "S04 delicate hands and one-of-a-kind seeds → S05 the rhythm of care and the first sign of Kai's fear → S06 the coming night drawn on the table, where a mistake is found while it is still a drawing.",
		"set_piece": "S05's dated montage ends with the first photograph laid beside the latest one, and S06 ends with the low Sun still visible on the horizon strip ('Preparation has time to be an action').",
		"hints": [
			"Which room does the shelter water come from?",
			"Put the water's return on the same timeline as the storm.",
			"Compare two whole nights: wall full until dawn, or water returned after the exposure resolves. Read the garden line in both.",
		],
	},
	"EX-M0103": {
		"title": "Prepare While It Is Light",
		"scenes": ["EX-CH01-S07", "EX-CH01-S08", "EX-CH01-S09"],
		"puzzle_id": "P-02",
		"clues": [
			{"id": "M0103-C1", "kind": "LOG", "holder": "A", "where": "Air console (S07)", "text": "Role card, shift 1: 'Make air during daylight before excess jar income spills.'"},
			{"id": "M0103-C2", "kind": "LOG", "holder": "K", "where": "Mast panel (S07)", "text": "Role card, shift 1: 'Five dark shifts, about 36 h; heat spends the finite night reserve.'"},
			{"id": "M0103-C3", "kind": "INS", "holder": "All", "where": "Mission Table", "text": "Day income +8 in shifts 1–2, cap 20; breathing −1 per shift."},
			{"id": "M0103-C4", "kind": "LOG+CARD", "holder": "R", "where": "Safe Room feed (S08)", "text": "Role card, shift 2: 'Labelled 2017 replay feed: sunspot 2673 fired a large flare; more activity is possible.'"},
			{"id": "M0103-C5", "kind": "INS+DLG", "holder": "A", "where": "Safe Room interface (S08)", "text": "The drill: water traced from garden reservoir to wall and back; EX-CH01-S08-L03 Amara: \"Practice complete. Baseline unchanged.\""},
			{"id": "M0103-C6", "kind": "LOG", "holder": "M", "where": "Garden panel (S09)", "text": "Role card, shift 3: 'This scenario's direct plant threats are cold near or below freezing and thirst; shielding borrows the garden reservoir.'"},
			{"id": "M0103-C7", "kind": "DLG", "holder": "All", "where": "Earth console (S09)", "text": "EX-CH01-S09-L04 Ferreira (Earth link before cutoff): \"Local rules remain active. Read back the next safe action.\""},
		],
		"aha": "Sunlight will overflow the jar anyway, so the air we make now is almost free — and we fill the shelter wall before the alarm, not during it.",
		"wrong_but_reasonable": "Leaving air at 6/10 or filling the shelter wall to 6 immediately in shift 1 — the preview shows breathing (−1/shift) or garden thirst (W >= 4) before anything is committed.",
		"escalation": "S07 abundance (where should overflow go?) → S08 a safe rehearsal of the coming danger → S09 sunset and the loss of Earth's voice.",
		"set_piece": "The mast stops producing, CUE-03 'Last Light' plays, the crew reads back Ferreira's instruction, SFX_RADIO_EARTH_LOST closes the channel and the Earth button greys out with a STORED GUIDANCE label.",
		"hints": [
			"Store air while sunlight would overflow.",
			"Prepare shielding before the alarm, then return the water.",
			"Open the worked Bloom plan or Guided plan.",
		],
	},
	"EX-M0104": {
		"title": "Keep the Promise Until Dawn",
		"scenes": ["EX-CH01-S10", "EX-CH01-S11", "EX-CH01-S12"],
		"puzzle_id": "P-02",
		"clues": [
			{"id": "M0104-C1", "kind": "INS+CARD", "holder": "R", "where": "Safe Room (S10)", "text": "Particle alarm with its replay label (10 Sep 2017 · historical replay), an instrument trace, not projectiles."},
			{"id": "M0104-C2", "kind": "INS", "holder": "All", "where": "Response panel", "text": "Shelter readout S = W + K against the dose table: S 0–1 → 3, 2–3 → 2, 4–5 → 1, 6 → 0 per storm shift."},
			{"id": "M0104-C3", "kind": "DLG", "holder": "A", "where": "S10", "text": "EX-CH01-S10-L04 Amara: \"One exclusive response. Its cost is in the forecast.\""},
			{"id": "M0104-C4", "kind": "DLG+INS", "holder": "A", "where": "Garden line (S11)", "text": "EX-CH01-S11-L02 Amara: \"Exposure resolves before drain. Read the gate.\""},
			{"id": "M0104-C5", "kind": "INS+DLG", "holder": "K", "where": "Mission table (S11)", "text": "Battery approaching zero; EX-CH01-S11-L03 Kai: \"Low is not failed. What demand comes next?\" (exactly E0 is not a blackout)."},
			{"id": "M0104-C6", "kind": "INS+LOG", "holder": "M, then All", "where": "Shutter and bay (S12)", "text": "Chamber conditions panel before the shutter; then N.'s stored recording, EX-CH01-S12-L02: \"If you are hearing this, Alo bloomed. Good. Now Alo needs a friend.\""},
		],
		"aha": "Our preparation already did the work; waiting is a decision, not doing nothing — and the water may only come home after the exposure it was shielding.",
		"wrong_but_reasonable": "Draining shelter water at the start of shift 6 to rescue the garden early — the preview shows shift 6 scored with the smaller shield before the drain is committed.",
		"escalation": "S10 the crisis inside the rules → S11 recovery on a nearly empty battery, where 'low' must not be read as 'failed' → S12 dawn, where the last task is a safety check, not applause.",
		"set_piece": "After the chamber check SFX_SHUTTER_OPEN reveals the yellow flower, CUE-04 'First Flower' plays, and tagging the photograph starts N.'s recording with SFX_RECORDER_AGED.",
		"hints": [
			"Store air while sunlight would overflow.",
			"Prepare shielding before the alarm, then return the water.",
			"Open the worked Bloom plan or Guided plan.",
		],
		"golden_hints": [
			"Golden needs Alo at 5 or more with no blackout, so every drop must reach the garden at exactly the right time.",
			"Open the worked Golden plan.",
		],
	},
}

const ACTION_FEEDBACK_CATALOG := {
	"route_spare_power": {
		"consequence": "Spare mast current flows into the O₂ electrolyser instead of spilling past the full 20-unit battery jar.",
		"why": "A full battery store cannot hold extra daylight charge, so routing surplus power into air production banks breathable O₂ for the 36-hour night.",
		"next_step": "Inspect the Safe Room board and confirm the four-cadet roll call.",
		"meter_tick": "Power E: 20/20 (0 spilled) · Air A: +2 stored",
		"crew_speaker": "Amara",
		"crew_reaction": "Surplus line locked to the air tank. Nothing spilled on our watch.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	},
	"calibrate_probe": {
		"consequence": "The moisture probe's +10 offset is zeroed on the dry cup (0) and spanned on the wet reference cup (100).",
		"why": "Two-point reference calibration removes systematic instrument error before touching an irreplaceable seed cassette.",
		"next_step": "Fill Alo's external test cassette and Tara's indoor reference cassette to 50 moisture.",
		"meter_tick": "Calibration: Dry 10→0 · Wet 110→100 (Verified)",
		"crew_speaker": "Rafi",
		"crew_reaction": "Zero and span checked against both cups. Now we can trust the 50 mark.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	},
	"plant_and_seal_cassettes": {
		"consequence": "One seed each is placed into Alo (EXTERNAL TEST) and Tara (INDOOR REFERENCE) at 50 moisture with latched transfer seals.",
		"why": "Pairing an external test chamber with an indoor reference plant lets the crew separate station-wide changes from chamber-specific stress.",
		"next_step": "Open the Mission Table to preview the 7-shift night schedule.",
		"meter_tick": "Food H: 6/10 · Crop C: 8/10 · Water W: 0/6 (Garden full)",
		"crew_speaker": "Mei",
		"crew_reaction": "Two cassettes sealed, two records started. Alo and Tara have a home.",
		"sfx": "SFX_GLOVE_PORT",
	},
	"stage_shelter_water": {
		"consequence": "Four water units transfer from the garden reservoir into the Safe Room bladder wall (W=4, Shielding S=6 with K=2).",
		"why": "Water and stowage mass absorb solar energetic protons (20 g/cm² at S=6), cutting storm shift dose to 0 while borrowing garden moisture temporarily.",
		"next_step": "Hold the crew in the Safe Room through the storm peak, then return the water after shift 6 exposure resolves.",
		"meter_tick": "Shielding S: 6/6 (Dose +0) · Water W: 4/6 (Garden thirst advisory)",
		"crew_speaker": "Rafi",
		"crew_reaction": "Bladder wall is full and crates are latched. Everyone inside before the proton flux peaks.",
		"sfx": "SFX_WATER_TRANSFER",
	},
	"return_garden_water": {
		"consequence": "After shift-6 storm exposure resolves, the borrowed water drains back from the Safe Room wall to Alo's garden reservoir (W=0).",
		"why": "Returning the water immediately after the radiation gate clears relieves garden thirst before dawn.",
		"next_step": "Verify chamber conditions at dawn and open the shutter for Alo's first flower.",
		"meter_tick": "Water W: 4→0 (Garden reservoir restored) · Alo H: 6/10",
		"crew_speaker": "Mei",
		"crew_reaction": "Water is back in the root tray — look at Alo's leaves lifting toward the lamp!",
		"sfx": "SFX_SHUTTER_OPEN",
	},
}

static func mission_investigation(mission_id: String) -> Dictionary:
	return MISSION_INVESTIGATIONS.get(mission_id, {}).duplicate(true)

static func all_mission_ids() -> Array[String]:
	return ["EX-M0101", "EX-M0102", "EX-M0103", "EX-M0104"]

static func action_feedback(action_id: String) -> Dictionary:
	if ACTION_FEEDBACK_CATALOG.has(action_id):
		return ACTION_FEEDBACK_CATALOG[action_id].duplicate(true)
	return {
		"consequence": "Station instrumentation updated for " + action_id + ".",
		"why": "Every committed step updates the shared station ledger.",
		"next_step": "Check the Outpost Status bar and Mission Table forecast.",
		"meter_tick": "Ledger updated",
		"crew_speaker": "Kai",
		"crew_reaction": "Readout confirmed on the board.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	}

static func night_shift_tension(shift_index: int) -> Dictionary:
	var s := clampi(shift_index, 1, 7)
	var dark_shifts_left := maxi(0, 7 - s)
	var hours_to_dawn := float(dark_shifts_left) * 7.2
	var is_dark := s >= 3
	var is_storm := s == 5 or s == 6
	return {
		"shift": s,
		"is_dark": is_dark,
		"is_storm": is_storm,
		"hours_to_dawn": hours_to_dawn,
		"countdown_label": "Dawn in %d shift%s (%.1f h)" % [dark_shifts_left, "" if dark_shifts_left == 1 else "s", hours_to_dawn] if dark_shifts_left > 0 else "Dawnlight on the mast array (0.0 h)",
		"lights_state": "Warm amber storm-shelter dim (35%)" if is_storm else ("Night conservation dim (60%)" if is_dark else "Full daylight array lamp (100%)"),
		"fans_state": "SFX_FAN_LOWPOWER · Quiet night circulation (low pitch)" if is_dark else "SFX_FAN_NORMAL · Nominal daylight airflow",
		"earth_link_state": "STORED GUIDANCE (Earth below horizon)" if s >= 4 else "LIVE LINK · Ferreira on console",
	}

static func alo_posture(alo_health: int, water_in_wall: int, shift_index: int, bloomed: bool = false) -> Dictionary:
	## Canon rule: Alo's progress is felt through botanical posture and growth — NEVER a face or eyes.
	var stage := "Seedling"
	var posture := "Upright hypocotyl stem, cotyledons level under the chamber lamp."
	if bloomed or shift_index >= 7 and alo_health >= 5:
		stage = "Golden Four-Petal Bloom"
		posture = "Sturdy upright stem leaning into the warm lamp; four bright yellow Brassica rapa petals open wide above turgid true leaves."
	elif bloomed or (shift_index >= 7 and alo_health > 0):
		stage = "First Open Flower"
		posture = "Stem upright; yellow flower petals open at dawn with slight lower-leaf curl from the long night."
	elif water_in_wall >= 4 or alo_health <= 3:
		stage = "Thirst / Cold Curl"
		posture = "Petiole angle droops 18° and leaf margins curl inward to conserve moisture while the shelter borrows the reservoir."
	elif shift_index >= 4:
		stage = "Closed Night Bud"
		posture = "Compact green floral bud held tight at the apex; leaves angled toward the dim chamber LED."
	return {
		"stage": stage,
		"posture_description": posture,
		"has_face_or_eyes": false,
		"botanical_note": "Observed through stem angle, leaf turgor, and floral bud opening (never anthropomorphic).",
	}

static func outcome_reward_card(stars: Dictionary, alo_health: int, retry_shift: int = 5) -> Dictionary:
	var safe_exp := bool(stars.get("safe_exposure", false))
	var no_blackout := bool(stars.get("no_blackout", false))
	var alo_alive := bool(stars.get("alo_alive", alo_health > 0))
	var star_count := (1 if safe_exp else 0) + (1 if no_blackout else 0) + (1 if alo_alive else 0)
	var is_golden := star_count == 3 and alo_health >= 5
	if is_golden:
		return {
			"tier": "GOLDEN_BLOOM",
			"title": "★ ★ ★  GOLDEN BLOOM  ·  COMMISSIONING MASTERED",
			"star_count": 3,
			"golden_bloom": true,
			"celebration": "All three stars earned with Alo at H=%d (>=5)! The shutter opens to a bright yellow four-petal flower, CUE-04 'First Flower' resolves in warm white light, and N.'s 2034 recording unlocks." % alo_health,
			"retry_prompt": "Replay any shift from the Mission Trainer to test an alternate trade study.",
			"sfx": "SFX_UI_SHIFT_COMMIT",
		}
	elif alo_alive and star_count >= 1:
		return {
			"tier": "BLOOM",
			"title": "★".repeat(star_count) + "☆".repeat(3 - star_count) + "  FIRST FLOWER AT DAWN",
			"star_count": star_count,
			"golden_bloom": false,
			"celebration": "The crew is safe and Alo opens her first yellow flower at dawn (H=%d). Check the causal review to see how to reach Golden Bloom (3 stars and H >= 5)." % alo_health,
			"retry_prompt": "Want Golden Bloom? Retry from Shift %d checkpoint with zero lost story progress." % retry_shift,
			"sfx": "SFX_UI_SHIFT_COMMIT",
		}
	return {
		"tier": "RETRY_INVITATION",
		"title": "FLIGHT RULE CHECKPOINT  ·  SAFE TO TRY AGAIN",
		"star_count": star_count,
		"golden_bloom": false,
		"celebration": "A mistake is information, not punishment (SFX_UI_SOFT_ERROR). The paused forecast names the exact demand that ran short so you can adjust the schedule.",
		"retry_prompt": "Retry immediately from Shift %d checkpoint — your earlier discoveries stay saved." % retry_shift,
		"sfx": "SFX_UI_SOFT_ERROR",
	}

static func build_feedback_banner(parent: Control, action_id: String, shift_index: int = 5, alo_health: int = 6, water_in_wall: int = 0, bloomed: bool = false) -> PanelContainer:
	var fb := action_feedback(action_id)
	var tension := night_shift_tension(shift_index)
	var plant := alo_posture(alo_health, water_in_wall, shift_index, bloomed)

	var card := UiDesign.glass_panel(UiDesign.colour("accent"))
	card.name = "Chapter1FeelBanner"
	if parent != null:
		parent.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)

	box.add_child(UiDesign.label("CAUSE & EFFECT  ·  " + String(fb.get("meter_tick", "")), "heading", "accent"))
	box.add_child(UiDesign.label("What changed: " + String(fb.get("consequence", "")), "body"))
	box.add_child(UiDesign.label("Why: " + String(fb.get("why", "")), "caption", "ivory"))
	box.add_child(UiDesign.label("Next step: " + String(fb.get("next_step", "")), "caption", "good"))
	box.add_child(UiDesign.label("%s: \"%s\"" % [String(fb.get("crew_speaker", "Crew")), String(fb.get("crew_reaction", ""))], "body", "accent"))
	box.add_child(UiDesign.label("Night Shift %d Atmosphere · %s · %s · %s" % [
		int(tension.get("shift", 1)),
		String(tension.get("countdown_label", "")),
		String(tension.get("lights_state", "")),
		String(tension.get("fans_state", "")),
	], "caption", "muted"))
	box.add_child(UiDesign.label("Alo Botanical Posture (%s): %s" % [
		String(plant.get("stage", "")),
		String(plant.get("posture_description", "")),
	], "caption", "good"))
	return card
