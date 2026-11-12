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

const TARGET_ALIAS_MAP := {
	"commission_route": "route_spare_power",
	"commission_result": "commission_result",
	"charter_card": "charter_card",
	"classify_information": "classify_information",
	"roll_call": "roll_call",
	"practice_fault": "practice_fault",
	"calibrate_probe": "set_zero",
	"set_zero": "set_zero",
	"span_probe": "set_span",
	"set_span": "set_span",
	"recheck_probe": "recheck",
	"recheck": "recheck",
	"inspect_packet": "scan_packet",
	"scan_packet": "scan_packet",
	"compare_atmosphere": "compare_atmosphere",
	"plant_alo": "plant_alo",
	"plant_tara": "plant_tara",
	"water_alo": "water_alo",
	"water_tara": "water_tara",
	"label_alo": "label_alo",
	"label_alo_external": "label_alo",
	"label_tara": "label_tara",
	"label_tara_indoor": "label_tara",
	"seal_alo": "seal_alo",
	"seal_tara": "seal_tara",
	"record_paired_conditions": "record_paired_conditions",
	"confirm_services": "confirm_services",
	"test_hand_light": "test_hand_light",
	"care_montage": "care_montage",
	"confirm_date_transition": "confirm_date_transition",
	"arrange_timeline": "arrange_timeline",
	"ack_schedule": "ack_schedule",
	"role_cards": "role_cards",
	"p02_shift1": "p02_shift1",
	"p02_stage_shift2": "p02_stage_shift2",
	"shelter_drill": "shelter_drill",
	"verify_drill_baseline": "verify_drill_baseline",
	"p02_shift2": "p02_shift2",
	"combine_cards": "combine_cards",
	"ack_earth_set": "ack_earth_set",
	"p02_shifts3_4": "p02_shifts3_4",
	"confirm_four_sheltered": "confirm_four_sheltered",
	"p02_shift5_alarm": "p02_shift5_alarm",
	"verify_exposure_order": "verify_exposure_order",
	"return_water": "return_garden_water",
	"p02_shifts6_7": "p02_shifts6_7",
	"review_outcome": "review_outcome",
	"verify_chamber": "verify_chamber",
	"open_shutter": "open_shutter",
	"tag_bloom": "tag_bloom",
	"inspect_tara": "inspect_tara",
	"complete_debrief": "complete_debrief",
}

const ACTION_FEEDBACK_CATALOG := {
	"route_spare_power": {
		"consequence": "The commissioning diagram is traced from the mast, through battery storage, to the air tank.",
		"why": "Tracing the diagram shows where surplus daylight power could make air. This introductory check leaves the fixed night reserves unchanged.",
		"next_step": "Inspect the commissioning result on the Mission Table.",
		"meter_tick": "Commissioning flow checked - Night reserves unchanged",
		"crew_speaker": "Amara",
		"crew_reaction": "Flow traced. Read the real reserves before planning the night.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	},
	"commission_result": {
		"consequence": "The commissioning diagram and its storage limits have been inspected.",
		"why": "Checking the diagram separates a possible resource route from the real reserves used in the night plan.",
		"next_step": "Read and acknowledge the station charter and emergency limits card.",
		"meter_tick": "Commissioning diagram inspected - Night reserves unchanged",
		"crew_speaker": "Kai",
		"crew_reaction": "Diagram checked. The night plan will show its actual resource changes.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	},
	"charter_card": {
		"consequence": "The Aurora charter and flight-rule card are logged on the Commons board, with four unnamed mugs waiting on the table.",
		"why": "Every crew member shares the same non-negotiable life-support and shelter limits before taking over the station.",
		"next_step": "Proceed to the Safe Room in Scene 2 to classify station feeds and complete roll call.",
		"meter_tick": "Charter & Flight Rules: Acknowledged",
		"crew_speaker": "Amara",
		"crew_reaction": "Rules on the wall, names on the board next. Let's check the Safe Room.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	},
	"classify_information": {
		"consequence": "The Safe Room practice panel tags each feed as LOCAL SENSOR, STORED GUIDANCE, or LIVE LINK.",
		"why": "Knowing which instruments work without Earth's live radio prevents confusion when the horizon blocks communications.",
		"next_step": "Complete the four-person roll call on the Safe Room board.",
		"meter_tick": "Autonomy: Local Sensor + Stored Guidance verified",
		"crew_speaker": "Amara",
		"crew_reaction": "Local sensors and stored rules stay with us even when Earth sets.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	},
	"roll_call": {
		"consequence": "All four name tokens (Amara, Mei, Rafi, Kai) are latched on the Safe Room board.",
		"why": "Every shelter procedure accounts for all four crew members before any valve or hatch is operated.",
		"next_step": "Resolve the disconnected practice fault using local sensor and stored guidance.",
		"meter_tick": "Crew Roll Call: 4/4 accounted for",
		"crew_speaker": "Rafi",
		"crew_reaction": "These are names. We do not spend them.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	},
	"practice_fault": {
		"consequence": "The practice fault clears using local sensor readings and stored flight rules while the live link stays disconnected.",
		"why": "Practising autonomous fault recovery during daylight prepares the crew for the Earth-set window in Shift 4.",
		"next_step": "Move to the calibration bench in the Commons and zero the moisture probe on the dry reference cup.",
		"meter_tick": "Drill Status: Autonomous recovery verified",
		"crew_speaker": "Kai",
		"crew_reaction": "Local sensor plus stored rule — we didn't need to wait for Earth.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	},
	"set_zero": {
		"consequence": "Dry reference zero set: the moisture probe reading in the dry cup shifts from 10 to 0.",
		"why": "Zeroing the dry reference removes the +10 baseline offset before checking the upper end of the scale.",
		"next_step": "Set the wet reference span so the wet reference cup reads 100 instead of 110.",
		"meter_tick": "Calibration 1/3: Dry 10→0 (Zero set · Wet span pending)",
		"crew_speaker": "Rafi",
		"crew_reaction": "Dry cup zeroed at 0. Next we set the wet reference span to 100.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	},
	"set_span": {
		"consequence": "Wet reference span set: the moisture probe reading in the wet cup shifts from 110 to 100.",
		"why": "Setting the upper span after dry zero aligns the full 0–100 scale across both reference cups.",
		"next_step": "Recheck both the dry (0) and wet (100) reference cups to verify the calibration holds.",
		"meter_tick": "Calibration 2/3: Dry 0 · Wet 110→100 (Span set · Recheck pending)",
		"crew_speaker": "Rafi",
		"crew_reaction": "Wet cup reads 100. One two-point recheck across both cups before we trust it.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	},
	"recheck": {
		"consequence": "Two-point recheck verified: the moisture probe holds 0 in the dry cup and 100 in the wet reference cup.",
		"why": "Verifying both endpoints confirms the +10 offset is gone and the probe can be trusted on live seed cassettes.",
		"next_step": "Inspect the sealed dry-storage seed packet and its storage record.",
		"meter_tick": "Calibration 3/3: Dry 0 · Wet 100 (Verified)",
		"crew_speaker": "Rafi",
		"crew_reaction": "Zero and span checked against both cups. Now we can trust the 50 mark.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	},
	"scan_packet": {
		"consequence": "The sealed dry-storage packet is scanned: two Brassica rapa seeds labelled 'ALO' and 'N.' in Latin letters with their 2034 record.",
		"why": "Logging the packet provenance before opening dry storage preserves the chain of custody for both irreplaceable seeds.",
		"next_step": "Compare the external test chamber and indoor reference bay atmosphere diagrams.",
		"meter_tick": "Seed Packet: 2 seeds verified (Alo & Tara) · Provenance logged",
		"crew_speaker": "Mei",
		"crew_reaction": "Alo means light. Someone named the packet before us.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	},
	"compare_atmosphere": {
		"consequence": "Both pressurised chamber diagrams are compared side by side: external test chamber for Alo and indoor reference bay for Tara.",
		"why": "Confirming identical baseline pressure and gas composition ensures any difference between Alo and Tara comes from their chamber location.",
		"next_step": "Enter the Garden in Scene 4 and place one seed each in Alo's and Tara's cassettes.",
		"meter_tick": "Chamber Comparison: External Test vs Indoor Reference verified",
		"crew_speaker": "Amara",
		"crew_reaction": "Two chambers, one shared baseline. Let's take the packet to the Garden.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	},
	"plant_alo": {
		"consequence": "One Brassica rapa seed is placed into Alo's external test cassette through the glove port.",
		"why": "Placing exactly one seed per cassette prevents crowding and keeps the paired comparison with Tara fair.",
		"next_step": "Place one seed in Tara's indoor reference cassette.",
		"meter_tick": "Alo Cassette: 1 seed placed · Moisture pending",
		"crew_speaker": "Mei",
		"crew_reaction": "Alo's seed is in the cradle. Easy with the forceps.",
		"sfx": "SFX_GLOVE_PORT",
	},
	"plant_tara": {
		"consequence": "One Brassica rapa seed is placed into Tara's indoor reference cassette.",
		"why": "A cared-for indoor reference plant lets the crew distinguish station-wide conditions from external chamber stress.",
		"next_step": "Water both Alo and Tara cassettes to the calibrated 40–60 moisture band (50 nominal).",
		"meter_tick": "Tara Cassette: 1 seed placed · Both seeds sown",
		"crew_speaker": "Amara",
		"crew_reaction": "A reference is a plant we care for, not one we ignore.",
		"sfx": "SFX_GLOVE_PORT",
	},
	"water_alo": {
		"consequence": "Alo's cassette is watered into the calibrated 40–60 moisture band using the verified probe.",
		"why": "Calibrated moisture gives the seed enough water to imbibe and germinate without waterlogging the root zone.",
		"next_step": "Water Tara's indoor reference cassette into the calibrated 40–60 moisture band.",
		"meter_tick": "Alo Moisture: Calibrated in 40–60 band",
		"crew_speaker": "Mei",
		"crew_reaction": "Alo's wick is taking up water cleanly.",
		"sfx": "SFX_WATER_TRANSFER",
	},
	"water_tara": {
		"consequence": "Tara's cassette is watered into the calibrated 40–60 moisture band to match Alo's starting hydration.",
		"why": "Matching calibrated moisture across both cassettes keeps water availability constant between the test and reference plants.",
		"next_step": "Label Alo EXTERNAL TEST and Tara INDOOR REFERENCE.",
		"meter_tick": "Tara Moisture: Calibrated in 40–60 band",
		"crew_speaker": "Rafi",
		"crew_reaction": "Both wicks are hydrated inside the safe band. Ready for labels.",
		"sfx": "SFX_WATER_TRANSFER",
	},
	"label_alo": {
		"consequence": "Alo's cassette is tagged EXTERNAL TEST on the outer chamber mount.",
		"why": "Clear specimen labelling prevents sample mix-ups across the 14-day care log.",
		"next_step": "Label Tara's cassette INDOOR REFERENCE.",
		"meter_tick": "Alo Label: EXTERNAL TEST attached",
		"crew_speaker": "Mei",
		"crew_reaction": "Alo is marked for the outer test chamber.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	},
	"label_tara": {
		"consequence": "Tara's cassette is tagged INDOOR REFERENCE in the indoor bay.",
		"why": "Distinct EXTERNAL TEST and INDOOR REFERENCE labels lock the experimental control pair before sealing.",
		"next_step": "Close the transfer seals on both Alo's and Tara's cassettes.",
		"meter_tick": "Tara Label: INDOOR REFERENCE attached",
		"crew_speaker": "Amara",
		"crew_reaction": "Both labels are distinct and logged.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	},
	"seal_alo": {
		"consequence": "Alo's transfer-lid latch closes and locks the external test cassette.",
		"why": "Sealing the cassette maintains chamber pressure and humidity around the germinating seed.",
		"next_step": "Close Tara's cassette transfer seal to complete the paired planting.",
		"meter_tick": "Alo Seal: Latched",
		"crew_speaker": "Rafi",
		"crew_reaction": "Alo's transfer lid is sealed.",
		"sfx": "SFX_GLOVE_PORT",
	},
	"seal_tara": {
		"consequence": "Tara's transfer-lid latch closes and locks the indoor reference cassette.",
		"why": "Sealing both cassettes under identical starting conditions completes the paired experimental setup.",
		"next_step": "Record the paired baseline conditions and first photographs.",
		"meter_tick": "Tara Seal: Latched · Paired planting complete",
		"crew_speaker": "Rafi",
		"crew_reaction": "Transfer sealed. Two names, two records.",
		"sfx": "SFX_GLOVE_PORT",
	},
	"record_paired_conditions": {
		"consequence": "Baseline temperature, calibrated moisture, and day-1 photographs are recorded for both Alo and Tara.",
		"why": "A dated baseline record lets the crew measure real growth across the 14-day care window.",
		"next_step": "Confirm both chamber service connections before leaving the Garden.",
		"meter_tick": "Baseline Log: Day-1 paired records & photos saved",
		"crew_speaker": "Mei",
		"crew_reaction": "Two names, two baseline records. Now we watch them grow.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	},
	"confirm_services": {
		"consequence": "Power, air, and water spur connections to both the external chamber and indoor bay are verified.",
		"why": "Checking the service spurs ensures neither chamber loses heat or moisture between care visits.",
		"next_step": "Move to the Service Corridor in Scene 5 to test the backup hand light and log the care observations.",
		"meter_tick": "Garden Services: Power, Air & Water spurs verified",
		"crew_speaker": "Kai",
		"crew_reaction": "All three service lines are green to both bays.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	},
	"test_hand_light": {
		"consequence": "The backup hand light is tested and hung handle-out beside the corridor locker.",
		"why": "Hanging the backup lamp handle-out ensures anyone can grab it by touch if station lighting dims during the lunar night.",
		"next_step": "Complete the 14 dated care observations at the care station.",
		"meter_tick": "Emergency Prep: Backup hand light staged handle-out",
		"crew_speaker": "Rafi",
		"crew_reaction": "Then it gets a backup. Here — handle out so you don't have to look for it.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	},
	"care_montage": {
		"consequence": "Fourteen dated care entries and leaf-posture photographs are logged from sprout to closed floral bud.",
		"why": "Consistent daily care brings Alo to a healthy closed bud (H=6) right as the 36-hour night approaches.",
		"next_step": "Confirm the dated transition to 25 April 2046 before the sunset planning session.",
		"meter_tick": "Care Log: 14 dated entries · Alo Stage: Closed Floral Bud (H: 6/10)",
		"crew_speaker": "Amara",
		"crew_reaction": "Fourteen dated care entries. A bud is a useful result.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	},
	"confirm_date_transition": {
		"consequence": "The station clock advances to 2046-04-25 03:36 UTC as the low Sun approaches the horizon.",
		"why": "Marking the exact date transition anchors the 7-shift lunar night schedule against the real solar ephemeris.",
		"next_step": "Return to the Mission Table in Scene 6 to align the Sun, Earth-link, and station timelines.",
		"meter_tick": "Date: 2046-04-25 03:36 UTC · Sunset approaching",
		"crew_speaker": "Kai",
		"crew_reaction": "Fourteen days gone that fast. The Sun is getting low on the ridge.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	},
	"arrange_timeline": {
		"consequence": "The Sun, Earth-link, and station water/power tracks are aligned across all 7 shifts on the Mission Table.",
		"why": "Laying all three tracks on one timeline reveals that borrowing garden water for the shelter wall requires a scheduled return time.",
		"next_step": "Acknowledge the shared 7-shift preparation schedule with the crew.",
		"meter_tick": "Night Timeline: Sun, Earth & Station tracks aligned",
		"crew_speaker": "Mei",
		"crew_reaction": "Put the garden on it. The shelter borrows from us.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	},
	"ack_schedule": {
		"consequence": "The crew signs off on the shared 7-shift timeline, including both the shelter water fill and its post-storm return.",
		"why": "Agreeing on when borrowed water returns prevents the garden from staying dry through the final dark shifts.",
		"next_step": "Move to the Service Rooms in Scene 7 to read the role cards and commit Daylight Shift 1.",
		"meter_tick": "Schedule: 7-shift night plan & water return acknowledged",
		"crew_speaker": "Rafi",
		"crew_reaction": "Put returning the water on it too. Preparation has time to be an action.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	},
	"role_cards": {
		"consequence": "All four Shift 1 role cards are read and pinned to the Mission Table constraints strip.",
		"why": "Combining air generation (+8 daylight income vs cap 20) and 36-hour night reserve rules shows that making air in Shift 1 uses power that would otherwise overflow.",
		"next_step": "Open the Mission Table to preview and commit Daylight Shift 1.",
		"meter_tick": "Role Constraints: 4/4 shift rules active",
		"crew_speaker": "Amara",
		"crew_reaction": "Make air during daylight before excess jar income spills.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	},
	"p02_shift1": {
		"consequence": "Daylight Shift 1 committed: the electrolyser banks breathable O₂ while the solar mast refills the battery jar to 20/20.",
		"why": "Generating air while sunlight is abundant converts would-be battery overflow into breathable reserve for the five dark shifts ahead.",
		"next_step": "Stage the Shift 2 forecast on the Mission Table before running the Safe Room drill.",
		"meter_tick": "Shift 1 Committed · Power E: 20/20 · Air A: banked for night",
		"crew_speaker": "Amara",
		"crew_reaction": "Shift 1 locked. The jar is full and our air reserve is climbing.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	},
	"p02_stage_shift2": {
		"consequence": "Shift 2 forecast staged and paused on the Mission Table without spending resources yet.",
		"why": "Staging the Shift 2 plan before the physical drill lets the crew verify the Safe Room water transfer first.",
		"next_step": "Enter the Safe Room in Scene 8 to rehearse the shelter entry and water-wall drill.",
		"meter_tick": "Shift 2: Forecast staged (Paused before drill)",
		"crew_speaker": "Kai",
		"crew_reaction": "Forecast looks clean on the board. Let's run the Safe Room drill before committing.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	},
	"shelter_drill": {
		"consequence": "The crew rehearses Safe Room entry, roll call, and traces the water path from the garden reservoir to the bladder wall and back.",
		"why": "A dry-run drill confirms every valve and latch works before the solar storm arrives.",
		"next_step": "Verify that the pre-drill station resource baseline is unchanged.",
		"meter_tick": "Safe Room Drill: Rehearsed (Practice only)",
		"crew_speaker": "Rafi",
		"crew_reaction": "Everyone in, valves traced from garden to wall and back.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	},
	"verify_drill_baseline": {
		"consequence": "The station ledger confirms the practice drill left battery, air, and garden water baselines unchanged.",
		"why": "Separating practice drills from live resource commits ensures no water or power is spent prematurely.",
		"next_step": "Commit Daylight Shift 2 at the 18:00 UTC gate on the Mission Table.",
		"meter_tick": "Baseline Check: Unchanged after practice drill",
		"crew_speaker": "Amara",
		"crew_reaction": "Practice complete. Baseline unchanged.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	},
	"p02_shift2": {
		"consequence": "Daylight Shift 2 committed at the last sunlit gate: final daylight power and air preparations lock in before sunset.",
		"why": "Shift 2 is the final sunlit window (+8 solar income) before five consecutive dark shifts begin.",
		"next_step": "Move to the Commons in Scene 9 to combine Mei and Rafi's cards and handle Earth-link cutoff.",
		"meter_tick": "Shift 2 Committed · Final daylight charge banked",
		"crew_speaker": "Kai",
		"crew_reaction": "Last daylight shift locked in. Five dark shifts ahead.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	},
	"combine_cards": {
		"consequence": "Mei's garden threat card (cold and thirst at W>=4) is combined with Rafi's 2017 flare replay card on the table.",
		"why": "Joining the plant thirst rule with the solar proton forecast shows why the shelter wall should be filled right before the storm and drained after exposure resolves.",
		"next_step": "Acknowledge the Earth-link cutoff on the communications console.",
		"meter_tick": "Combined Clues: Shielding S=W+K vs Garden Thirst (W>=4) linked",
		"crew_speaker": "Mei",
		"crew_reaction": "Shielding borrows the garden reservoir — so we stage it before the storm and return it right after.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	},
	"ack_earth_set": {
		"consequence": "Ferreira's final instruction is read back as Earth drops below the lunar horizon and the console switches to STORED GUIDANCE.",
		"why": "Once line-of-sight to Earth is blocked by the ridge, the crew operates autonomously using local sensors and stored flight rules.",
		"next_step": "Open the Mission Table to resolve Dark Shifts 3 and 4, staging the shelter wall before Shift 5.",
		"meter_tick": "Earth Link: STORED GUIDANCE active (Autonomous mode)",
		"crew_speaker": "Amara",
		"crew_reaction": "Local rules remain active. We have our timeline — let's resolve Shifts 3 and 4.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	},
	"p02_shifts3_4": {
		"consequence": "Dark Shifts 3 and 4 resolved: station heat and air hold steady while water transfers into the Safe Room bladder wall ahead of the Shift 5 storm.",
		"why": "Filling the water wall and latching stowage mass before the proton flux peaks brings shielding to S=6 (0 dose) when the alarm sounds.",
		"next_step": "Enter the Safe Room in Scene 10 and confirm all four cadets are sheltered.",
		"meter_tick": "Shifts 3–4 Resolved · Shielding staged for Shift 5 storm",
		"crew_speaker": "Rafi",
		"crew_reaction": "Bladder wall is staged and crates are latched before the alarm.",
		"sfx": "SFX_WATER_TRANSFER",
	},
	"confirm_four_sheltered": {
		"consequence": "All four cadets are confirmed inside the Safe Room behind the water bladder wall and stowage mass as the exposure lock engages.",
		"why": "Closing the Safe Room exposure lock with all four crew inside ensures nobody takes unshielded proton dose during Shift 5.",
		"next_step": "Select and commit the exclusive Shift 5 storm alarm response on the response panel.",
		"meter_tick": "Safe Room Lock: 4/4 crew sheltered behind S=W+K",
		"crew_speaker": "Rafi",
		"crew_reaction": "Four tokens on the board, four people inside the wall.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	},
	"p02_shift5_alarm": {
		"consequence": "Shift 5 storm peak resolved: the exclusive alarm response holds the crew behind S=W+K shielding while the solar proton flux peaks.",
		"why": "At S=6 (W=4 water wall + K=2 stowage), 20 g/cm² of mass reduces storm shift radiation dose to 0 while the garden temporarily waits for its water.",
		"next_step": "Move to the Garden in Scene 11 to verify the exposure gate and return the borrowed water.",
		"meter_tick": "Shift 5 Storm Resolved · Crew Dose: within safe limit",
		"crew_speaker": "Amara",
		"crew_reaction": "Our preparation did the work. Wait for the exposure gate to clear before touching the drain valve.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	},
	"verify_exposure_order": {
		"consequence": "The radiation gate readout confirms storm exposure has resolved before the Safe Room water-wall drain valve is unlocked.",
		"why": "Exposure resolves before drain: draining the water wall too early would score the storm shift with reduced shielding.",
		"next_step": "Open the return valve to drain the borrowed water back to Alo's garden reservoir.",
		"meter_tick": "Flight Rule Gate: Exposure resolved before water drain",
		"crew_speaker": "Amara",
		"crew_reaction": "Exposure resolves before drain. Read the gate — now it's safe to return the water.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	},
	"p02_shifts6_7": {
		"consequence": "Final Dark Shifts 6 and 7 resolved: with water returned to the garden, Alo recovers turgor and the station reaches dawn without a blackout.",
		"why": "A final battery reading of E>=0 (even E=0) is a legal conservation margin, not a blackout, and returning water restores Alo's health before sunrise.",
		"next_step": "Review the causal 7-shift night outcome on the Mission Table.",
		"meter_tick": "Shifts 6–7 Resolved · Dawn reached",
		"crew_speaker": "Kai",
		"crew_reaction": "Low is not failed! The sun is back on the mast array!",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	},
	"review_outcome": {
		"consequence": "The 7-shift causal ledger is reviewed, confirming crew exposure, battery margin, and Alo's survival through the 36-hour night.",
		"why": "Reviewing the shift-by-shift ledger shows how daylight air banking, pre-storm water staging, and post-storm water return worked together.",
		"next_step": "Proceed to Scene 12 in the Garden to verify chamber conditions and open the viewing shutter.",
		"meter_tick": "Night Outcome: Causal ledger verified",
		"crew_speaker": "Amara",
		"crew_reaction": "Every shift accounted for. Let's check Alo's chamber before opening the shutter.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	},
	"verify_chamber": {
		"consequence": "Alo's external chamber pressure, temperature, and calibrated moisture pass pre-shutter safety verification.",
		"why": "Checking chamber telemetry before opening the viewing shutter ensures the thermal cover only moves when the chamber is stable.",
		"next_step": "Open the safe viewing shutter to inspect Alo at dawn.",
		"meter_tick": "Chamber Safety: Pressure & moisture nominal · Shutter unlocked",
		"crew_speaker": "Mei",
		"crew_reaction": "Chamber pressure and moisture are steady. Unlocking the viewing shutter.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	},
	"open_shutter": {
		"consequence": "The viewing shutter slides open, revealing Alo's bright yellow four-petal Brassica rapa flower leaning into the warm chamber lamp.",
		"why": "Timely water return and steady night heating allowed the closed floral bud to open into Aurora's first flower at dawn.",
		"next_step": "Tag the first-bloom photograph in the observation log.",
		"meter_tick": "Viewing Shutter: OPEN · Alo: First Open Flower",
		"crew_speaker": "Mei",
		"crew_reaction": "Four yellow petals facing the lamp — Alo bloomed!",
		"sfx": "SFX_SHUTTER_OPEN",
	},
	"tag_bloom": {
		"consequence": "The first-bloom photograph is tagged in the station archive, unlocking N.'s 2034 voice recording ('If you are hearing this, Alo bloomed. Good. Now Alo needs a friend.').",
		"why": "Logging the bloom photograph links Aurora's 2046 harvest to Expedition Zero's 2034 seed archive.",
		"next_step": "Inspect Tara in the indoor reference bay to complete the paired comparison.",
		"meter_tick": "Archive: First-bloom image tagged · 2034 audio unlocked",
		"crew_speaker": "Mei",
		"crew_reaction": "She left a message for whoever brought Alo to bloom.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	},
	"inspect_tara": {
		"consequence": "Tara is inspected in the indoor reference bay, healthy and intact beside Alo's external chamber record.",
		"why": "Comparing the healthy indoor reference plant with Alo completes the paired scientific control started in Scene 4.",
		"next_step": "Complete the Chapter 1 decision and evidence debrief.",
		"meter_tick": "Paired Control: Alo (External Bloom) & Tara (Indoor Reference) verified",
		"crew_speaker": "Amara",
		"crew_reaction": "Both cassettes cared for, both records complete. That's a real experiment.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	},
	"complete_debrief": {
		"consequence": "Chapter 1 commissioning and night-survival debrief completed with all four crew mugs named at the Mission Table.",
		"why": "Closing the commissioning loop turns four cadets into Aurora's active crew ready for Chapter 2 pollination.",
		"next_step": "Review the Chapter 1 outcome summary and continue to Chapter 2.",
		"meter_tick": "Chapter 1 Debrief: Complete · Ready for Chapter 2",
		"crew_speaker": "Amara",
		"crew_reaction": "Aurora has a crew, and Alo has a flower. On to Chapter 2.",
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
	"care_and_night_schedule": {
		"consequence": "The backup hand light is hung handle-out, 14 dated care entries are logged, and the Sun/Earth/Station tracks align on the Mission Table.",
		"why": "Laying the solar, radio, and water timelines side by side reveals that shelter water must have a scheduled return time.",
		"next_step": "Open Shift 1 on the Mission Table to bank daylight air before sunset.",
		"meter_tick": "Care Log: 14 entries · Night Timeline: 7 shifts mapped",
		"crew_speaker": "Mei",
		"crew_reaction": "Fourteen dated care entries, and the water return is on the same timeline as the storm.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
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
		"consequence": "The water-return instruction is acknowledged. The real drain resolves with the confirmed shift plan, after storm exposure.",
		"why": "Exposure must resolve before ordinary drain; the shift forecast shows whether and when garden water returns.",
		"next_step": "Resolve final dark shifts 6 and 7 on the Mission Table, then verify chamber conditions at dawn.",
		"meter_tick": "Water-return instruction acknowledged - Read the committed shift for actual transfer",
		"crew_speaker": "Mei",
		"crew_reaction": "Return instruction logged. Check exposure and the drain in the final shift forecast.",
		"sfx": "SFX_SHUTTER_OPEN",
	},
	"dawn_bloom_payoff": {
		"consequence": "Chamber pressure and moisture pass verification, the viewing shutter opens to Alo's bright yellow four-petal flower, and N.'s 2034 recording plays.",
		"why": "Verifying chamber safety before opening the shutter protects the plant and completes the paired scientific record with Tara.",
		"next_step": "Review the Chapter 1 debrief and continue to Chapter 2.",
		"meter_tick": "Alo: First Open Flower · Tara: Reference Intact",
		"crew_speaker": "Mei",
		"crew_reaction": "Four yellow petals facing the lamp — Alo made it through the night!",
		"sfx": "SFX_SHUTTER_OPEN",
	},
}

static func mission_investigation(mission_id: String) -> Dictionary:
	return MISSION_INVESTIGATIONS.get(mission_id, {}).duplicate(true)

static func all_mission_ids() -> Array[String]:
	return ["EX-M0101", "EX-M0102", "EX-M0103", "EX-M0104"]

static func action_feedback(action_id: String, state: Dictionary = {}) -> Dictionary:
	var canonical := String(TARGET_ALIAS_MAP.get(action_id, action_id))
	if ACTION_FEEDBACK_CATALOG.has(canonical):
		var out: Dictionary = ACTION_FEEDBACK_CATALOG[canonical].duplicate(true)
		out["action_id"] = action_id
		out["canonical_id"] = canonical
		_apply_live_state_feedback(canonical, out, state)
		return out
	return {
		"action_id": action_id,
		"canonical_id": canonical,
		"consequence": "Station instrumentation updated for " + action_id + ".",
		"why": "Every committed step updates the shared station ledger.",
		"next_step": "Check the Outpost Status bar and Mission Table forecast.",
		"meter_tick": "Ledger updated",
		"crew_speaker": "Kai",
		"crew_reaction": "Readout confirmed on the board.",
		"sfx": "SFX_UI_SHIFT_COMMIT",
	}

static func _apply_live_state_feedback(canonical: String, out: Dictionary, state: Dictionary) -> void:
	if state.is_empty():
		return
	var p01: Dictionary = state.get("p01", state) if state.get("p01", null) is Dictionary else state
	var has_p01 := p01.has("probe_zeroed") or p01.has("cassette_alo_seed_count") or p01.has("moisture_alo")
	if has_p01:
		var zeroed := bool(p01.get("probe_zeroed", false))
		var spanned := bool(p01.get("probe_spanned", false))
		var rechecked := bool(p01.get("probe_rechecked", false))
		var scanned := bool(p01.get("packet_scanned", false))
		var alo_seeds := int(p01.get("cassette_alo_seed_count", 0))
		var tara_seeds := int(p01.get("cassette_tara_seed_count", 0))
		var m_alo := float(p01.get("moisture_alo", 0.0))
		var m_tara := float(p01.get("moisture_tara", 0.0))
		var alo_watered := m_alo >= 40.0 and m_alo <= 60.0
		var tara_watered := m_tara >= 40.0 and m_tara <= 60.0
		var alo_lbl := String(p01.get("alo_label", ""))
		var tara_lbl := String(p01.get("tara_label", ""))
		var alo_sealed := bool(p01.get("alo_sealed", false))
		var tara_sealed := bool(p01.get("tara_sealed", false))

		match canonical:
			"set_zero":
				out["meter_tick"] = "Calibration 1/3: Dry 10→0 (Zero set · Wet span %s)" % ("set" if spanned else "pending")
				if not spanned:
					out["next_step"] = "Set the wet reference span so the wet reference cup reads 100 instead of 110."
				elif not rechecked:
					out["next_step"] = "Recheck both the dry (0) and wet (100) reference cups."
			"set_span":
				out["meter_tick"] = "Calibration 2/3: Dry %s · Wet 110→100 (Recheck %s)" % ["0" if zeroed else "10", "done" if rechecked else "pending"]
				out["next_step"] = "Recheck both the dry (0) and wet (100) reference cups to verify calibration holds." if not rechecked else "Inspect the sealed dry-storage seed packet and its storage record."
			"recheck":
				out["meter_tick"] = "Calibration 3/3: Dry 0 · Wet 100 (Verified)"
				out["next_step"] = "Inspect the sealed dry-storage seed packet and its storage record." if not scanned else "Compare the external test chamber and indoor reference bay atmosphere diagrams."
			"scan_packet":
				out["next_step"] = "Compare the external test chamber and indoor reference bay atmosphere diagrams."
			"plant_alo":
				out["meter_tick"] = "Seeds Sown: Alo %d/1 · Tara %d/1" % [alo_seeds, tara_seeds]
				out["next_step"] = "Place one seed in Tara's indoor reference cassette." if tara_seeds < 1 else "Water Alo and Tara cassettes into the calibrated 40–60 moisture band."
			"plant_tara":
				out["meter_tick"] = "Seeds Sown: Alo %d/1 · Tara %d/1" % [alo_seeds, tara_seeds]
				out["next_step"] = "Place one seed in Alo's external test cassette." if alo_seeds < 1 else "Water Alo and Tara cassettes into the calibrated 40–60 moisture band."
			"water_alo":
				out["consequence"] = "Alo's cassette is watered to %d/100 inside the calibrated 40–60 moisture band." % int(round(m_alo))
				out["meter_tick"] = "Moisture: Alo %d/100 · Tara %d/100" % [int(round(m_alo)), int(round(m_tara))]
				out["next_step"] = "Water Tara's indoor reference cassette into the calibrated 40–60 moisture band." if not tara_watered else "Label Alo EXTERNAL TEST and Tara INDOOR REFERENCE."
			"water_tara":
				out["consequence"] = "Tara's cassette is watered to %d/100 inside the calibrated 40–60 moisture band." % int(round(m_tara))
				out["meter_tick"] = "Moisture: Alo %d/100 · Tara %d/100" % [int(round(m_alo)), int(round(m_tara))]
				out["next_step"] = "Water Alo's external test cassette into the calibrated 40–60 moisture band." if not alo_watered else "Label Alo EXTERNAL TEST and Tara INDOOR REFERENCE."
			"label_alo":
				out["meter_tick"] = "Labels: Alo=%s · Tara=%s" % [alo_lbl if not alo_lbl.is_empty() else "pending", tara_lbl if not tara_lbl.is_empty() else "pending"]
				out["next_step"] = "Label Tara's cassette INDOOR REFERENCE." if tara_lbl.is_empty() else "Close the transfer seals on both Alo's and Tara's cassettes."
			"label_tara":
				out["meter_tick"] = "Labels: Alo=%s · Tara=%s" % [alo_lbl if not alo_lbl.is_empty() else "pending", tara_lbl if not tara_lbl.is_empty() else "pending"]
				out["next_step"] = "Label Alo's cassette EXTERNAL TEST." if alo_lbl.is_empty() else "Close the transfer seals on both Alo's and Tara's cassettes."
			"seal_alo":
				out["meter_tick"] = "Seals: Alo %s · Tara %s" % ["Sealed" if alo_sealed else "Open", "Sealed" if tara_sealed else "Open"]
				out["next_step"] = "Close Tara's cassette transfer seal to complete the paired planting." if not tara_sealed else "Record the paired baseline conditions and first photographs."
			"seal_tara":
				out["meter_tick"] = "Seals: Alo %s · Tara %s" % ["Sealed" if alo_sealed else "Open", "Sealed" if tara_sealed else "Open"]
				out["next_step"] = "Close Alo's cassette transfer seal to complete the paired planting." if not alo_sealed else "Record the paired baseline conditions and first photographs."

	var res: Dictionary = state.get("resources", {}) if state.get("resources", null) is Dictionary else {}
	if not res.is_empty() and canonical in ["route_spare_power", "commission_result"]:
		out["meter_tick"] = "Reserves unchanged: Battery E:%d - Air A:%d" % [int(res.get("E", 0)), int(res.get("A", 0))]
	if not res.is_empty() and canonical in ["p02_shift1", "p02_shift2", "p02_shifts3_4", "p02_shift5_alarm", "p02_shifts6_7", "return_garden_water"]:
		out["meter_tick"] = "Power E:%d · Air A:%d · Water Wall W:%d · Alo H:%d · Dose Z:%d" % [
			int(res.get("E", 0)),
			int(res.get("A", 0)),
			int(res.get("W", 0)),
			int(res.get("H", 0)),
			int(res.get("Z", 0)),
		]

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
		"fans_sfx": "SFX_FAN_LOWPOWER" if is_dark else "SFX_FAN_NORMAL",
		"fans_state": "Fans slowed for the night" if is_dark else "Fans at normal daytime speed",
		"earth_link_state": "STORED GUIDANCE (Earth below horizon)" if s >= 4 else "LIVE LINK · Ferreira on console",
	}

static func alo_posture(alo_health: int, water_in_wall: int, shift_index: int, bloomed: bool = false) -> Dictionary:
	## Canon rule: Alo's progress is felt through botanical posture and growth — NEVER a face or eyes.
	var stage := "Seedling"
	var posture := "Upright hypocotyl stem, cotyledons level under the chamber lamp."
	if (bloomed or shift_index >= 7) and alo_health >= 5:
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

static func outcome_reward_card(stars: Dictionary, alo_health: int, retry_shift: int = 5, ending: String = "") -> Dictionary:
	var safe_exp := bool(stars.get("safe_exposure", false))
	var no_blackout := bool(stars.get("no_blackout", false))
	var alo_alive := bool(stars.get("alo_alive", alo_health > 0))
	var star_count := (1 if safe_exp else 0) + (1 if no_blackout else 0) + (1 if alo_alive else 0)
	var stopped := ending in ["MISSION_STOPPED", "ALO_LOST"] or not safe_exp
	var is_golden := not stopped and star_count == 3 and alo_health >= 5
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
	elif not stopped and alo_alive and star_count >= 1:
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
