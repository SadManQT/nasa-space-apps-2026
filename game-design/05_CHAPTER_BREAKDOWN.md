# Playable chapter breakdown

All missions are mandatory and sequential. Exploration and conversation within a mission are flexible. There is no optional quest necessary to understand the ending.

## CH01 — Night One

- **Purpose / story progression:** Care becomes a shared responsibility. Control begins behind Mei at the mission table; no menu lecture. The old gardener anticipated a future bloom but did not know when or whether one would occur.
- **Locations:** LOC-01, LOC-02, LOC-03, LOC-04; navigation and access in [world bible](09_WORLD_AND_LEVEL_DESIGN.md).
- **Main mission:** [M-0101 — A Drawer of Light](07_MISSION_DESIGNS/M-0101_A_Drawer_of_Light.md); Commission the habitat and plant the recovered pair.
- **Supporting continuation:** [M-0102 — Keep the Night](07_MISSION_DESIGNS/M-0102_Keep_the_Night.md); Prepare, survive and restore shared water before first light. This is required story play, not a detachable bonus minigame.
- **Cast:** Alo, Amara, Commander Ferreira, Kai, Mei, Dr. Noor Rahman, Rafi, Rao; voice/screen presence follows the timeline.
- **Challenges / puzzle solutions:** [P-01](08_PUZZLE_DESIGNS.md#p-01) and [P-02](08_PUZZLE_DESIGNS.md#p-02). Each puzzle has an explicit initial state, valid sequence, hints and fail/retry rules.
- **Scientific discovery:** pair_planted_pending; packet_initial_seen; unlock dated care montage. All factual boundaries are recorded in [science register](16_SCIENTIFIC_ACCURACY.md).
- **Dialogue / scenes:** SC-0101, SC-0102, SC-0103, SC-0104, SC-0105, SC-0106; [all exact scenes](06_SCENE_SCRIPTS/CHAPTER_01.md), [dialogue](11_DIALOGUE_MASTER.md).
- **Unlock:** `arrival_accepted=true`. No map label, cinematic skip or optional clue bypasses this flag.
- **Completion:** both missions COMPLETE and `first_bloom=true` after the final scene gate.
- **Reward / consequence:** First bloom, N.’s local message and Tara; choose Taller mast or Fuel-cell battery.
- **Pacing target:** 28 minutes active play, plus optional reading/exploration. A quiet reaction scene follows each major danger; no combat encounter is inserted.
- **Transition:** Apr 27 06:00; use [timeline](03_STORY_TIMELINE.md) to the next chapter's start, with explicit confirmation for time jumps. Next mission M-0201.

**Optional exploration:** inspect available plant photos, mug/locker labels and the current environmental monitoring page. These reuse the shared station and BARK-01–06. They award observations only, no critical tool or clue. The entire main path remains completable without them.

## CH02 — Be the Bee

- **Purpose / story progression:** The first bloom needs another living partner. Earth contact returns as the player looks at Tara. N. remembers yellow mustard fields, and the crew records its stem-colour prediction.
- **Locations:** LOC-01, LOC-02, LOC-03, LOC-05; navigation and access in [world bible](09_WORLD_AND_LEVEL_DESIGN.md).
- **Main mission:** [M-0201 — Borrow a Bee](07_MISSION_DESIGNS/M-0201_Borrow_a_Bee.md); Cross-pollinate Alo and Tara without breaking containment.
- **Supporting continuation:** [M-0202 — A Voice Before Us](07_MISSION_DESIGNS/M-0202_A_Voice_Before_Us.md); Recover the recorder context and recognise the earlier trial. This is required story play, not a detachable bonus minigame.
- **Cast:** Amara, Commander Ferreira, Kai, Mei, Rafi, Tara; voice/screen presence follows the timeline.
- **Challenges / puzzle solutions:** [P-03](08_PUZZLE_DESIGNS.md#p-03) and [P-04](08_PUZZLE_DESIGNS.md#p-04). Each puzzle has an explicit initial state, valid sequence, hints and fail/retry rules.
- **Scientific discovery:** pollen_shared_pending; lineage_parent_pair = Alo × Tara. All factual boundaries are recorded in [science register](16_SCIENTIFIC_ACCURACY.md).
- **Dialogue / scenes:** SC-0201, SC-0202, SC-0203, SC-0204, SC-0205, SC-0206; [all exact scenes](06_SCENE_SCRIPTS/CHAPTER_02.md), [dialogue](11_DIALOGUE_MASTER.md).
- **Unlock:** `first_bloom=true`. No map label, cinematic skip or optional clue bypasses this flag.
- **Completion:** both missions COMPLETE and `recorder_context=true` after the final scene gate.
- **Reward / consequence:** Seven-day pollination and stem prediction, N.’s yellow-fields clue; choose Red-blue LEDs or Insulation blankets.
- **Pacing target:** 23 minutes active play, plus optional reading/exploration. A quiet reaction scene follows each major danger; no combat encounter is inserted.
- **Transition:** May 6 22:00; use [timeline](03_STORY_TIMELINE.md) to the next chapter's start, with explicit confirmation for time jumps. Next mission M-0301.

**Optional exploration:** inspect available plant photos, mug/locker labels and the current environmental monitoring page. These reuse the shared station and BARK-01–06. They award observations only, no critical tool or clue. The entire main path remains completable without them.

## CH03 — Moonquake

- **Purpose / story progression:** Care includes uncertainty, loss and continuation. Alarm panel marks the oxygen tank red. The expedition becomes a family of plants; the mapped reserve expedition now has purpose.
- **Locations:** LOC-02, LOC-03, LOC-07; navigation and access in [world bible](09_WORLD_AND_LEVEL_DESIGN.md).
- **Main mission:** [M-0301 — Numbers That Disagree](07_MISSION_DESIGNS/M-0301_Numbers_That_Disagree.md); Find and repair the leak through independent observations.
- **Supporting continuation:** [M-0302 — Forty-Two](07_MISSION_DESIGNS/M-0302_Forty-Two.md); Make the annex safe, recover the map and harvest Alo’s legacy. This is required story play, not a detachable bonus minigame.
- **Cast:** Amara, Commander Ferreira, Kai, Mei, Rafi; voice/screen presence follows the timeline.
- **Challenges / puzzle solutions:** [P-05](08_PUZZLE_DESIGNS.md#p-05) and [P-06](08_PUZZLE_DESIGNS.md#p-06). Each puzzle has an explicit initial state, valid sequence, hints and fail/retry rules.
- **Scientific discovery:** leak_sealed_pending; manual_gauge_trusted. All factual boundaries are recorded in [science register](16_SCIENTIFIC_ACCURACY.md).
- **Dialogue / scenes:** SC-0301, SC-0302, SC-0303, SC-0304, SC-0305, SC-0306; [all exact scenes](06_SCENE_SCRIPTS/CHAPTER_03.md), [dialogue](11_DIALOGUE_MASTER.md).
- **Unlock:** `recorder_context=true`. No map label, cinematic skip or optional clue bypasses this flag.
- **Completion:** both missions COMPLETE and `seed_legacy=true` after the final scene gate.
- **Reward / consequence:** Alo’s forty-two-seed legacy, preserved petal and vault map; choose Moon-dirt shelter or Flexible seals.
- **Pacing target:** 25 minutes active play, plus optional reading/exploration. A quiet reaction scene follows each major danger; no combat encounter is inserted.
- **Transition:** May 21 → Oct 21; use [timeline](03_STORY_TIMELINE.md) to the next chapter's start, with explicit confirmation for time jumps. Next mission M-0401.

**Optional exploration:** inspect available plant photos, mug/locker labels and the current environmental monitoring page. These reuse the shared station and BARK-01–06. They award observations only, no critical tool or clue. The entire main path remains completable without them.

## CH04 — Into the Cold Trap

- **Purpose / story progression:** Caution becomes leadership beyond home. Rafi stands beside the pressurised rover checklist. The vault note directs the cadets to Ferreira; her silence prepares the confession.
- **Locations:** LOC-01, LOC-03, LOC-08, LOC-09, LOC-10; navigation and access in [world bible](09_WORLD_AND_LEVEL_DESIGN.md).
- **Main mission:** [M-0401 — Where the Sun Cannot Follow](07_MISSION_DESIGNS/M-0401_Where_the_Sun_Cannot_Follow.md); Plan the cold-trap route, survey ice and retain a return reserve.
- **Supporting continuation:** [M-0402 — Twelve in the Dark](07_MISSION_DESIGNS/M-0402_Twelve_in_the_Dark.md); Recover a sealed vault and stabilise its dry specimens at home. This is required story play, not a detachable bonus minigame.
- **Cast:** Amara, Commander Ferreira, Kai, Mei, Rafi; voice/screen presence follows the timeline.
- **Challenges / puzzle solutions:** [P-07](08_PUZZLE_DESIGNS.md#p-07) and [P-08](08_PUZZLE_DESIGNS.md#p-08). Each puzzle has an explicit initial state, valid sequence, hints and fail/retry rules.
- **Scientific discovery:** ice_survey_pending; return_route_B; sample_verified. Resource units are game abstractions. All factual boundaries are recorded in [science register](16_SCIENTIFIC_ACCURACY.md).
- **Dialogue / scenes:** SC-0401, SC-0402, SC-0403, SC-0404, SC-0405, SC-0406; [all exact scenes](06_SCENE_SCRIPTS/CHAPTER_04.md), [dialogue](11_DIALOGUE_MASTER.md).
- **Unlock:** `seed_legacy=true`. No map label, cinematic skip or optional clue bypasses this flag.
- **Completion:** both missions COMPLETE and `vault_recovered=true` after the final scene gate.
- **Reward / consequence:** Twelve distinct vault specimens and the ask-Ferreira inscription; choose Ice harvester or Rover lights/heater.
- **Pacing target:** 33 minutes active play, plus optional reading/exploration. A quiet reaction scene follows each major danger; no combat encounter is inserted.
- **Transition:** Oct 22 → Dec 12; use [timeline](03_STORY_TIMELINE.md) to the next chapter's start, with explicit confirmation for time jumps. Next mission M-0501.

**Optional exploration:** inspect available plant photos, mug/locker labels and the current environmental monitoring page. These reuse the shared station and BARK-01–06. They award observations only, no critical tool or clue. The entire main path remains completable without them.

## CH05 — Shooting Stars

- **Purpose / story progression:** Evidence makes room for an honest conversation. A scheduled lander arrives at the existing pad; the player waits behind the marked line. Cotton’s final survival is prepared months before the ending.
- **Locations:** LOC-01, LOC-03, LOC-08; navigation and access in [world bible](09_WORLD_AND_LEVEL_DESIGN.md).
- **Main mission:** [M-0501 — The Engineer Comes Home](07_MISSION_DESIGNS/M-0501_The_Engineer_Comes_Home.md); Welcome Ferreira and assemble a factual evacuation sequence.
- **Supporting continuation:** [M-0502 — Permission to Answer](07_MISSION_DESIGNS/M-0502_Permission_to_Answer.md); Observe impact flashes, identify Noor and invite her reply. This is required story play, not a detachable bonus minigame.
- **Cast:** Amara, Commander Ferreira, Kai, Mei, Dr. Noor Rahman, Rafi, Rao; voice/screen presence follows the timeline.
- **Challenges / puzzle solutions:** [P-09](08_PUZZLE_DESIGNS.md#p-09) and [P-10](08_PUZZLE_DESIGNS.md#p-10). Each puzzle has an explicit initial state, valid sequence, hints and fail/retry rules.
- **Scientific discovery:** zero_sequence_pending; zero_all_returned; ferreira_admission_ready. All factual boundaries are recorded in [science register](16_SCIENTIFIC_ACCURACY.md).
- **Dialogue / scenes:** SC-0501, SC-0502, SC-0503, SC-0504, SC-0505, SC-0506; [all exact scenes](06_SCENE_SCRIPTS/CHAPTER_05.md), [dialogue](11_DIALOGUE_MASTER.md).
- **Unlock:** `vault_recovered=true`. No map label, cinematic skip or optional clue bypasses this flag.
- **Completion:** both missions COMPLETE and `noor_known=true` after the final scene gate.
- **Reward / consequence:** Ferreira’s confession, Noor alive/Academy-founder reveal and cotton planting; choose Dust Shield or Whipple bumper.
- **Pacing target:** 25 minutes active play, plus optional reading/exploration. A quiet reaction scene follows each major danger; no combat encounter is inserted.
- **Transition:** Dec 15; use [timeline](03_STORY_TIMELINE.md) to the next chapter's start, with explicit confirmation for time jumps. Next mission M-0601.

**Optional exploration:** inspect available plant photos, mug/locker labels and the current environmental monitoring page. These reuse the shared station and BARK-01–06. They award observations only, no critical tool or clue. The entire main path remains completable without them.

## CH06 — The Red Ring

- **Purpose / story progression:** Courage is supported action while afraid. Kai takes the same hand light from its locker. January observation and February replay are separated by ongoing monitoring.
- **Locations:** LOC-01, LOC-02; navigation and access in [world bible](09_WORLD_AND_LEVEL_DESIGN.md).
- **Main mission:** [M-0601 — A Plan for Darkness](07_MISSION_DESIGNS/M-0601_A_Plan_for_Darkness.md); Prepare a protected bus and a verified eclipse power transfer.
- **Supporting continuation:** [M-0602 — All the Sunrises](07_MISSION_DESIGNS/M-0602_All_the_Sunrises.md); Use a camera to observe the eclipse and restore a feeder safely. This is required story play, not a detachable bonus minigame.
- **Cast:** Amara, Commander Ferreira, Kai, Mei, Dr. Noor Rahman, Rafi; voice/screen presence follows the timeline.
- **Challenges / puzzle solutions:** [P-11](08_PUZZLE_DESIGNS.md#p-11) and [P-12](08_PUZZLE_DESIGNS.md#p-12). Each puzzle has an explicit initial state, valid sequence, hints and fail/retry rules.
- **Scientific discovery:** eclipse_ready_pending; kai_plan_shared. All factual boundaries are recorded in [science register](16_SCIENTIFIC_ACCURACY.md).
- **Dialogue / scenes:** SC-0601, SC-0602, SC-0603, SC-0604, SC-0605, SC-0606; [all exact scenes](06_SCENE_SCRIPTS/CHAPTER_06.md), [dialogue](11_DIALOGUE_MASTER.md).
- **Unlock:** `noor_known=true`. No map label, cinematic skip or optional clue bypasses this flag.
- **Completion:** both missions COMPLETE and `kai_supported=true` after the final scene gate.
- **Reward / consequence:** Kai’s eclipse plan and family call, known Noor text; choose Storm early warning or Bigger Safe Room.
- **Pacing target:** 25 minutes active play, plus optional reading/exploration. A quiet reaction scene follows each major danger; no combat encounter is inserted.
- **Transition:** Jan 13 → Feb 14; use [timeline](03_STORY_TIMELINE.md) to the next chapter's start, with explicit confirmation for time jumps. Next mission M-0701.

**Optional exploration:** inspect available plant photos, mug/locker labels and the current environmental monitoring page. These reuse the shared station and BARK-01–06. They award observations only, no critical tool or clue. The entire main path remains completable without them.

## CH07 — The Great Storm

- **Purpose / story progression:** The entire expedition applies what it learned. The labelled historical counterfactual begins. There is no unassigned cadet or absent base operator in the finale.
- **Locations:** LOC-01, LOC-04; navigation and access in [world bible](09_WORLD_AND_LEVEL_DESIGN.md).
- **Main mission:** [M-0701 — Your Call, Cadets](07_MISSION_DESIGNS/M-0701_Your_Call_Cadets.md); Make the integrated three-wave survival plan.
- **Supporting continuation:** [M-0702 — What We Carry](07_MISSION_DESIGNS/M-0702_What_We_Carry.md); Execute the storm plan, save the reserve and diagnose the failed link. This is required story play, not a detachable bonus minigame.
- **Cast:** Amara, Commander Ferreira, Kai, Mei, Dr. Noor Rahman, Rafi, Rao; voice/screen presence follows the timeline.
- **Challenges / puzzle solutions:** [P-13](08_PUZZLE_DESIGNS.md#p-13) and [P-14](08_PUZZLE_DESIGNS.md#p-14). Each puzzle has an explicit initial state, valid sequence, hints and fail/retry rules.
- **Scientific discovery:** storm_prepared_pending; protected_founder_seeds30; plan hash recorded for P-14. All factual boundaries are recorded in [science register](16_SCIENTIFIC_ACCURACY.md).
- **Dialogue / scenes:** SC-0701, SC-0702, SC-0703, SC-0704, SC-0705, SC-0706; [all exact scenes](06_SCENE_SCRIPTS/CHAPTER_07.md), [dialogue](11_DIALOGUE_MASTER.md).
- **Unlock:** `kai_supported=true`. No map label, cinematic skip or optional clue bypasses this flag.
- **Completion:** both missions COMPLETE and `route_clear=true` after the final scene gate.
- **Reward / consequence:** Crew, garden and reserve safe; last log explains the Academy name; choose Relay parts kit or Long-range battery.
- **Pacing target:** 38 minutes active play, plus optional reading/exploration. A quiet reaction scene follows each major danger; no combat encounter is inserted.
- **Transition:** Feb 16 03:00; use [timeline](03_STORY_TIMELINE.md) to the next chapter's start, with explicit confirmation for time jumps. Next mission M-0801.

**Optional exploration:** inspect available plant photos, mug/locker labels and the current environmental monitoring page. These reuse the shared station and BARK-01–06. They award observations only, no critical tool or clue. The entire main path remains completable without them.

## CH08 — The Lighthouse

- **Purpose / story progression:** Bring the voices and the garden through darkness together. The rover cabin is lit while Aurora remains partly sunlit. First established seed-renewing garden survives the next seasonal night; every central mystery has an answer.
- **Locations:** LOC-03, LOC-08, LOC-11, LOC-12; navigation and access in [world bible](09_WORLD_AND_LEVEL_DESIGN.md).
- **Main mission:** [M-0801 — The Long Road](07_MISSION_DESIGNS/M-0801_The_Long_Road.md); Prepare two teams and traverse the relay route with verified reserves.
- **Supporting continuation:** [M-0802 — From Last Light to First Light](07_MISSION_DESIGNS/M-0802_From_Last_Light_to_First_Light.md); Restore both links, bring the team home and validate the living garden. This is required story play, not a detachable bonus minigame.
- **Cast:** Amara, Commander Ferreira, Kai, Mei, Dr. Noor Rahman, Rafi, Rao; voice/screen presence follows the timeline.
- **Challenges / puzzle solutions:** [P-15](08_PUZZLE_DESIGNS.md#p-15) and [P-16](08_PUZZLE_DESIGNS.md#p-16). Each puzzle has an explicit initial state, valid sequence, hints and fail/retry rules.
- **Scientific discovery:** summit_reached_pending; aurora_home_ready; repeater_chain_live; travellers_at_summit. All factual boundaries are recorded in [science register](16_SCIENTIFIC_ACCURACY.md).
- **Dialogue / scenes:** SC-0801, SC-0802, SC-0803, SC-0804, SC-0805, SC-0806; [all exact scenes](06_SCENE_SCRIPTS/CHAPTER_08.md), [dialogue](11_DIALOGUE_MASTER.md).
- **Unlock:** `route_clear=true`. No map label, cinematic skip or optional clue bypasses this flag.
- **Completion:** both missions COMPLETE and `campaign_complete=true` after the final scene gate.
- **Reward / consequence:** Relay, Noor rooftop call, returned crew and living garden/cotton; credits and optional MARS, then postgame.
- **Pacing target:** 43 minutes active play, plus optional reading/exploration. A quiet reaction scene follows each major danger; no combat encounter is inserted.
- **Transition:** Apr 10 06:00 and epilogue; use [timeline](03_STORY_TIMELINE.md) to the next chapter's start, with explicit confirmation for time jumps. Credits and final-garden free exploration; MARS tease optional.

**Optional exploration:** inspect available plant photos, mug/locker labels and the current environmental monitoring page. These reuse the shared station and BARK-01–06. They award observations only, no critical tool or clue. The entire main path remains completable without them.
