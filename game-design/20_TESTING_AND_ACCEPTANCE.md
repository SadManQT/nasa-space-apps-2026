# Testing and acceptance matrix

## What is verified now versus later

This package receives document/link/ID/dependency/solution-arithmetic checks and a narrative consistency review. Gameplay performance, input behavior, save resilience, rendering and VO timing require an implemented game and are explicitly future acceptance tests, not tests passed here. No game tests or prototype were created.

## Universal release tests

| Test | Procedure | Pass condition |
|---|---|---|
| QA-01 Whole story | New Expedition→credits using only mandatory interactions |8 chapters, 16 missions, 48 scene gates; no debug action or optional collectible required |
| QA-02 Checkpoint reload | Save/reload before and after every EV gate and risky commit | Exact resources/date/location/dialogue restored; no duplicate rewards |
| QA-03 Failure recovery | Deliberately choose each unsafe action then retry | Cause explained; safe checkpoint available; story remains reachable |
| QA-04 Skip/caption | Skip every cinematic; play all speech as text only | All essential facts readable; physical puzzles still required; no early knowledge |
| QA-05 Input | Complete path keyboard-only and controller-only | Every interaction reachable; no hold/drag-only required task |
| QA-06 Accessibility | TimersOFF,shakeOFF,horizon lock, 150%text,muted audio | Same objectives/rewards; no missing clue or clipped required control |
| QA-07 Knowledge | Inspect every pre-CH05 screen and journal title | No Noor name/portrait leaked; all old crew survival facts truthful |
| QA-08 Seed ledger | Track every grant/move/harvest through finale | Founder42=12 planted+30 reserve; vault12=1 cotton planted+11 distinct specimens retained; album16=2 founders+12 vault types+2 optional entries |
| QA-09 People and time | Track physical occupants through all travel | Ferreira remote→transit→Aurora→rover→Aurora; Mei/Amara stay home in finale; correct 24 h trips |
| QA-10 Atmosphere and science | Review every exterior/plant/storm/eclipse shot | Pressure boundaries, vacuum sound, no plant immunity, historical-replay/counterfactual labels, no unsupported sky claim |
| QA-11 Interface |1280×720 and 1080p, 150%text, EN/BN, focus navigation | No overlap/clipping; puzzle numbers and source text readable; current objective always recoverable |
| QA-12 Offline | Disconnect network before New Expedition and finish | No API/account/CDN requirement; local source summaries and assets present |
| QA-13 Save interruption | Interrupt a write, reopen last session | Valid previous snapshot survives; no corrupt seed/mission transaction |
| QA-14 Outcome coverage | Execute all published winning witnesses and unsafe threshold cases | Golden/Bloom/PUMP/STACK/WAIT valid; emergency outcomes truthful; no silent campaign continuation after Alo Lost |
| QA-15 Performance | Profile agreed low-end reference device across every chapter | Target30fps720p or agreed documented release adjustment, no input lag at puzzles; results recorded honestly |
| QA-16 Localization | Native Bangla review plus automated missing-string scan | All required strings translated, names consistent, text shaping and numerals legible |
| QA-17 Final resolution | Complete relay and final garden, then skip credits/reload Continue | Photo/dedication persist, all five back, Noor answered, cotton alive, MARS optional |

## Mission traceability and solution tests


### QA-M-0101 — A Drawer of Light

- **Prerequisite / result:** arrival_accepted → pair_planted.
- **Scene coverage:** SC-0101, SC-0102, SC-0103; verify each scene's EV conjunct, dialogue and transition.
- **Puzzle / witness:** P-01. Order: dry zero → wet span → recheck → packet scan → one seed each → water 50 → distinct labels → seals. Accept any final moisture 40–60 inclusive; extra water can be removed to waste before sealing.
- **Negative test:** Sealing is blocked until calibration; duplicate seed/label assignment is blocked with the occupied cassette named. Flooding prompts drain rather than kills the seed.
- **Expected pass:** Both calibrated moisture values in band, seed count 1+1, labels distinct, seals closed.
- **Required assets:** A-01,A-02,A-03,A-04,A-05,A-06,A-10,A-11,A-12,A-14,A-15,A-20; common A-48–A-61.
- **Required systems:** SYS-01,SYS-02,SYS-03,SYS-05,SYS-07; common SYS-08/10/11/12.
- **Retry/save:** Repeat negative action, load pre-commit checkpoint, run witness, verify next mission unlocks once and inventory/date remain exact.

### QA-M-0102 — Keep the Night

- **Prerequisite / result:** pair_planted → first_bloom.
- **Scene coverage:** SC-0104, SC-0105, SC-0106; verify each scene's EV conjunct, dialogue and transition.
- **Puzzle / witness:** P-02. The all-COZY Bloom witness in the numeric contract ends E2,A1,H1,W0,K0,C3,R3.6,Z2 with no blackout. The Golden witness ends E0,A1,H5,W0,K0,C9,R3.6,Z2 with no blackout. Exactly E0 is not a blackout. Additional PUMP and STACK witnesses are listed there.
- **Negative test:** A negative energy balance causes the published blackout penalties; it is not an automatic mission stop. A<=0 or unsafe exposure stops operations; H0 gives Alo lost if the crew completes safely. Show the cause and offer the complete last-shift checkpoint. Invalid transfer directions do not create water.
- **Expected pass:** Complete seven shifts with A>0, Z<=3, all four crew sheltered during exposure, and H>0. Golden requires all three stars (safe exposure, no blackout, living Alo) plus H>=5. Other safe/loss outcomes remain viewable without unlocking Chapter 2.
- **Required assets:** A-01,A-02,A-03,A-04,A-05,A-06,A-10,A-11,A-12,A-13,A-14,A-15,A-16,A-21,A-22,A-23,A-24,A-29; common A-48–A-61.
- **Required systems:** SYS-01,SYS-02,SYS-03,SYS-04,SYS-05,SYS-07,SYS-09; common SYS-08/10/11/12.
- **Retry/save:** Repeat negative action, load pre-commit checkpoint, run witness, verify next mission unlocks once and inventory/date remain exact.

### P-02 contract test suite (GAME-02)

To be built as the headless `P02Sim` suite on 13 November ([build plan](18_TECHNICAL_BLUEPRINT.md#hackathon-build-plan-from-13-november-game-01020308)). Every expected value below was traced by hand from the [P-02 contract](08_PUZZLE_DESIGNS.md#p-02-numeric-execution-contract); none comes from an executed program. If code and this table disagree, stop and check the arithmetic before changing either. Plans use the witness notation `heat/O/L/transfer` (heat 0/1/2 = COLD/COOL/COZY, light 0/1/2 = OFF/DIM/FULL); state is E/A/H/W/K/C/R/Z.

**Reference plans and expected endings (also the GAME-01 manual test inputs):**

| Plan | Shifts 1–7 | Final state | Ending |
|---|---|---|---|
| Bloom / WAIT | DAY/2/2/HOLD · DAY/0/2/HOLD · 2/0/0/FILL · 2/0/0/FILL · 2/0/0/WAIT · 2/0/0/DRAIN · 2/0/0/DRAIN | 2/1/1/0/0/3/3.6/2 | Bloom |
| Golden | published witness | 0/1/5/0/0/9/3.6/2 | Golden Bloom |
| PUMP | published witness | 0/1/1/6/0/7/3.6/2 | Bloom |
| STACK | published witness | 0/3/1/0/0/6/3.6/2 | Bloom |
| Alo lost | DAY/2/0/HOLD · DAY/2/0/HOLD · 0/0/0/FILL · 0/0/0/FILL · 0/0/0/WAIT · 0/0/0/HOLD · 0/0/0/DRAIN | 12/3/0/2/0/0/3.6/2 | Alo lost (crew safe) |
| No shelter | as Bloom, but HOLD in shifts 3, 4, 6 and 7 | stops after shift 6: 5/2/4/0/0/6/4.8/6 | Mission stopped (exposure) |

**Shift-by-shift trace, Bloom / WAIT** (E,A,H,W,K,C after each shift): (15,7,7,0,0,9) · (17,6,8,0,0,10) · (14,5,7,2,0,9) · (11,4,5,4,0,7) · (8,3,3,4,0,5) · (5,2,2,2,0,4) · (2,1,1,0,0,3). Overflow 2 in shift 1 and 3 in shift 2. A wrong step order fails this trace.

**Ordering and boundary cases:**

| Case | Start → input | Expected |
|---|---|---|
| Income clamps before spending | E18, shift 1, O0 L OFF | overflow 6, E19 |
| Air clamps before breathing | A10, shift 1, O2 | A9 |
| Shift-6 dose uses pre-drain shelter | W4 Z1, shift 6, DRAIN | shelter 4, dose 1, W2 |
| Shift-5 dose uses post-alarm shelter | W2, shift 5, PUMP | W4, dose 1 |
| Thirst uses post-transfer water | W2 H6, shift 3, COZY OFF FILL | H4 |
| Exactly zero is not a blackout | E3, shift 3, COZY OFF | E0, no blackout |
| Blackout penalties | E2 A6 H6 C8, shift 3, COZY OFF | blackout, E0 A3 H3 C5 |
| STACK forces COOL/O0/OFF | start state, shift 5, STACK with COZY/O2/FULL requested | E12 A5 H4 K2 Z2 |
| Partial alarm actions | shift 5 | PUMP partial W+1; STACK partial K1 |
| Crates leave before shift 7 | K2, shift 7 | K0 |
| Dead Alo stays dead | H0, FULL light | H0 |
| Water clamps 0–6 | FILL at W6; DRAIN at W0; PUMP at W6 | 6; 0; 6 |
| Forbidden actions | PUMP/STACK/WAIT outside shift 5; FILL/HOLD/DRAIN in shift 5; O=3; six shifts | rejected with a reason, state unchanged |
| Crew not sheltered in a storm shift | Bloom plan, unsheltered at shift 5 | Mission stopped after shift 5 |
| Determinism and retry | run any plan twice; restore pre-shift-4 checkpoint and replay | identical records; same final state as the uninterrupted run |
| UI matches simulation | after every commit | every gauge equals the record's after-state |

**Release record (GAME-08):** for each run of this suite and of QA-14, record the build version or commit, date, platform and result. A pass is not claimed without that record.

### QA-M-0201 — Borrow a Bee

- **Prerequisite / result:** first_bloom → pollen_shared.
- **Scene coverage:** SC-0201, SC-0202, SC-0203; verify each scene's EV conjunct, dialogue and transition.
- **Puzzle / witness:** P-03. Tara anther → sealed A → Alo stigma; Alo anther → sealed B → Tara stigma; confirm donor≠recipient each way; repeat for three reciprocal runs across seven dated days; record the stem prediction.
- **Negative test:** Touching petal shows no transfer; using own pollen explains cultivar incompatibility; dirty brush prompts replace tip. No drag precision score.
- **Expected pass:** Three reciprocal runs valid, each charged E1/A1 once; seals passed, seven care visits and stem prediction logged.
- **Required assets:** A-03,A-05,A-06,A-11,A-14,A-15,A-17,A-18; common A-48–A-61.
- **Required systems:** SYS-01,SYS-02,SYS-03,SYS-05,SYS-07,SYS-09; common SYS-08/10/11/12.
- **Retry/save:** Repeat negative action, load pre-commit checkpoint, run witness, verify next mission unlocks once and inventory/date remain exact.

### QA-M-0202 — A Voice Before Us

- **Prerequisite / result:** pollen_shared → recorder_context.
- **Scene coverage:** SC-0204, SC-0205, SC-0206; verify each scene's EV conjunct, dialogue and transition.
- **Puzzle / witness:** P-04. A.DATE=2034-04; B.DEVICE=HORT-01; C.CHANNEL=ENGINEERING. There are three unique token shapes with readable text; no combinatorial guessing requirement.
- **Negative test:** Wrong token remains removable and displays which source disagrees; audio stays locked until all three match.
- **Expected pass:** All three matches correct, fragment transcript opened and N.’s mustard-fields clue heard/read.
- **Required assets:** A-01,A-02,A-03,A-04,A-07,A-10,A-11,A-19; common A-48–A-61.
- **Required systems:** SYS-01,SYS-02,SYS-03,SYS-05,SYS-07; common SYS-08/10/11/12.
- **Retry/save:** Repeat negative action, load pre-commit checkpoint, run witness, verify next mission unlocks once and inventory/date remain exact.

### QA-M-0301 — Numbers That Disagree

- **Prerequisite / result:** recorder_context → leak_sealed.
- **Scene coverage:** SC-0301, SC-0302, SC-0303; verify each scene's EV conjunct, dialogue and transition.
- **Puzzle / witness:** P-05. Compare the six candidates within four investigation phases, verify the aftershock annex isolation, then isolate GARDEN only → verify stable trunk → apply clamp → open GARDEN slowly → five readings 100/100/100. Clamp cannot seat on a pressurised leaking connection.
- **Negative test:** Closing MAIN produces a protected reserve warning and can be reopened immediately; wrong clamp location cannot latch; recheck explains remaining pressure fall.
- **Expected pass:** Six candidates investigated within four phases, aftershock annex isolation verified, and five consecutive stable readings after correct clamp and reopening.
- **Required assets:** A-01,A-02,A-03,A-04,A-07,A-10,A-11,A-25,A-26; common A-48–A-61.
- **Required systems:** SYS-01,SYS-02,SYS-03,SYS-04,SYS-05,SYS-07; common SYS-08/10/11/12.
- **Retry/save:** Repeat negative action, load pre-commit checkpoint, run witness, verify next mission unlocks once and inventory/date remain exact.

### QA-M-0302 — Forty-Two

- **Prerequisite / result:** leak_sealed → seed_legacy.
- **Scene coverage:** SC-0304, SC-0305, SC-0306; verify each scene's EV conjunct, dialogue and transition.
- **Puzzle / witness:** P-06. Maturity confirmed → irrigation OFF for mature Alo → dry to<=20 → six×7=42 → planting 12/reserve 30 → seal and lineage label. Two allocation buttons can directly choose 12/30; arithmetic dragging not required.
- **Negative test:** Early irrigation stop is blocked before maturity; selecting Tara’s live irrigation displays wrong plant and leaves it unchanged. A miscount reopens that well. Seeds are never lost by cursor error.
- **Expected pass:** 42 total, 12 allocated, 30 sealed reserve, map scanned and petal stored.
- **Required assets:** A-01,A-02,A-03,A-04,A-05,A-06,A-07,A-14,A-15,A-19,A-27,A-28,A-30; common A-48–A-61.
- **Required systems:** SYS-01,SYS-02,SYS-03,SYS-05,SYS-07,SYS-09; common SYS-08/10/11/12.
- **Retry/save:** Repeat negative action, load pre-commit checkpoint, run witness, verify next mission unlocks once and inventory/date remain exact.

### QA-M-0401 — Where the Sun Cannot Follow

- **Prerequisite / result:** seed_legacy → ice_survey.
- **Scene coverage:** SC-0401, SC-0402, SC-0403; verify each scene's EV conjunct, dialogue and transition.
- **Puzzle / witness:** P-07. B is the only valid route:100−30−30=40>=30 and 12°<=15°. Calibrate at 2, threshold 12; tag 18 and 19; retain 2 as negative control; collect one positive sample.
- **Negative test:** Route A fails slope regardless of energy; C fails slope and reserve. Uncalibrated positive reports are marked unverified. Off-road driving stops at a warning boundary, never tumbles into an unwinnable pit.
- **Expected pass:** Valid route chosen, three beacons linked, three stops reached, reference recorded, two positives tagged, one sample sealed, return reserve forecast>=30.
- **Required assets:** A-01,A-03,A-04,A-08,A-14,A-31,A-32,A-33,A-34,A-35,A-36; common A-48–A-61.
- **Required systems:** SYS-01,SYS-02,SYS-03,SYS-05,SYS-06,SYS-07; common SYS-08/10/11/12.
- **Retry/save:** Repeat negative action, load pre-commit checkpoint, run witness, verify next mission unlocks once and inventory/date remain exact.

### QA-M-0402 — Twelve in the Dark

- **Prerequisite / result:** ice_survey → vault_recovered.
- **Scene coverage:** SC-0404, SC-0405, SC-0406; verify each scene's EV conjunct, dialogue and transition.
- **Puzzle / witness:** P-08. Probe→sleeve→cradle→mount→return→dry glovebox→three-stage sealed warm-up→condensation check→open→12 labels.
- **Negative test:** Open command outside or before dry warm-up is blocked with condensation explanation. Wrong label can be corrected; a damaged-outer-case false alarm does not destroy specimens.
- **Expected pass:** Twelve distinct specimens recorded; lid scanned; quarantine status set pending viability evaluation, not assumed healthy.
- **Required assets:** A-01,A-02,A-03,A-04,A-08,A-11,A-14,A-31,A-33,A-34,A-37,A-38; common A-48–A-61.
- **Required systems:** SYS-01,SYS-02,SYS-03,SYS-05,SYS-06,SYS-07,SYS-09; common SYS-08/10/11/12.
- **Retry/save:** Repeat negative action, load pre-commit checkpoint, run witness, verify next mission unlocks once and inventory/date remain exact.

### QA-M-0501 — The Engineer Comes Home

- **Prerequisite / result:** vault_recovered → zero_sequence.
- **Scene coverage:** SC-0501, SC-0502, SC-0503; verify each scene's EV conjunct, dialogue and transition.
- **Puzzle / witness:** P-09. Chronological order chart/fault/order/boarding; supported conclusion ALL FOUR RETURNED. Do not identify the gardener’s full name from initials alone.
- **Negative test:** Abandoned gardener conclusion highlights contradictory boarding evidence. Reordering remains free; no antagonist accusation score.
- **Expected pass:** Four cards in timestamp order and supported conclusion selected.
- **Required assets:** A-01,A-02,A-03,A-04,A-07,A-08,A-09,A-10,A-11,A-19,A-38,A-39; common A-48–A-61.
- **Required systems:** SYS-01,SYS-02,SYS-03,SYS-05,SYS-07; common SYS-08/10/11/12.
- **Retry/save:** Repeat negative action, load pre-commit checkpoint, run witness, verify next mission unlocks once and inventory/date remain exact.

### QA-M-0502 — Permission to Answer

- **Prerequisite / result:** zero_sequence → noor_known.
- **Scene coverage:** SC-0504, SC-0505, SC-0506; verify each scene's EV conjunct, dialogue and transition.
- **Puzzle / witness:** P-10. Six genuine events, both artifacts rejected; dust removed/prevented, leak sealed/prevented and pressure verified; signed identity matched and invitation sent. Witness E16,A4.25,H6,C8,R13.5,Z0 after three phases. All eight verified flashes with no false report satisfy the observation Golden criterion.
- **Negative test:** A hot pixel remains fixed across frames. Mistags can be corrected without reaction speed scoring. Unrepaired faults stay visible in the next forecast. Noor’s connection is not inferred from nationality; the signed record supplies it.
- **Expected pass:** At least six verified flashes, both artifacts rejected, maintenance passed/protected, A>0, H>0, signed identity matched and invitation sent; set noor_identity_revealed.
- **Required assets:** A-01,A-02,A-03,A-04,A-07,A-09,A-10,A-11,A-14,A-38,A-40,A-41; common A-48–A-61.
- **Required systems:** SYS-01,SYS-02,SYS-03,SYS-05,SYS-07,SYS-09; common SYS-08/10/11/12.
- **Retry/save:** Repeat negative action, load pre-commit checkpoint, run witness, verify next mission unlocks once and inventory/date remain exact.

### QA-M-0601 — A Plan for Darkness

- **Prerequisite / result:** noor_known → eclipse_ready.
- **Scene coverage:** SC-0601, SC-0602, SC-0603; verify each scene's EV conjunct, dialogue and transition.
- **Puzzle / witness:** P-11. Essentials [1,1,1,1,1], pump [1,0,0,0,0], camera [0,1,0,0,0], floods all OFF; total 7 and E7 at recovery. Equivalent pump/camera placements before their deadlines are accepted. The verified-data release replaces this fallback with demand scaled by segment-hours/7.2 as specified in the source gameplay document and rebalances the forecast.
- **Negative test:** Omitting essentials identifies the affected service. Spending more than the seven-unit protected allocation warns about the reserved recovery margin. Edit freely before commitment.
- **Expected pass:** All five essential packages scheduled, pump/camera each once before deadlines, allocation<=7 and five segment acknowledgements saved.
- **Required assets:** A-01,A-02,A-04,A-07,A-10,A-11,A-12,A-42; common A-48–A-61.
- **Required systems:** SYS-01,SYS-02,SYS-03,SYS-04,SYS-05,SYS-07; common SYS-08/10/11/12.
- **Retry/save:** Repeat negative action, load pre-commit checkpoint, run witness, verify next mission unlocks once and inventory/date remain exact.

### QA-M-0602 — All the Sunrises

- **Prerequisite / result:** eclipse_ready → kai_supported.
- **Scene coverage:** SC-0604, SC-0605, SC-0606; verify each scene's EV conjunct, dialogue and transition.
- **Puzzle / witness:** P-12. Isolate→zero/fault check→reset→reconnect→camera test; three observation records include the restored egress.
- **Negative test:** Reset before isolation is interlocked and explained; choosing protected main bus displays survival services warning and does not switch it. Egress waits for authored restoration, not real-time solar timing.
- **Expected pass:** F2 tested, ingress/ring/egress recorded, support call acknowledged.
- **Required assets:** A-01,A-02,A-03,A-04,A-07,A-09,A-10,A-11,A-12,A-40,A-42; common A-48–A-61.
- **Required systems:** SYS-01,SYS-02,SYS-03,SYS-04,SYS-05,SYS-07; common SYS-08/10/11/12.
- **Retry/save:** Repeat negative action, load pre-commit checkpoint, run witness, verify next mission unlocks once and inventory/date remain exact.

### QA-M-0701 — Your Call, Cadets

- **Prerequisite / result:** kai_supported → storm_prepared.
- **Scene coverage:** SC-0701, SC-0702, SC-0703; verify each scene's EV conjunct, dialogue and transition.
- **Puzzle / witness:** P-13. W [4,4,4,4,4,2], K2 throughout exposure, COZY/DIM/O0 in all six steps. Shield S6 gives zero game dose even in peak steps. Costs 6*(1+2+1)=24, ending E6,A2.5,H1,C3,R9,Z0; seed reserve30 stays protected. All five crew are sheltered.
- **Negative test:** Early drain reduces shelter before a later exposure. Missing seed compartment prevents readiness. Alternative plans are accepted when they meet the same safety and living-garden goals; owned upgrades apply once.
- **Expected pass:** Feasible six-step plan, both seed compartments latched, five-person roster acknowledged, uplink isolation scheduled.
- **Required assets:** A-01,A-02,A-03,A-04,A-07,A-10,A-11,A-12,A-13,A-14,A-16,A-22,A-23,A-28,A-29,A-42; common A-48–A-61.
- **Required systems:** SYS-01,SYS-02,SYS-03,SYS-04,SYS-05,SYS-07,SYS-09; common SYS-08/10/11/12.
- **Retry/save:** Repeat negative action, load pre-commit checkpoint, run witness, verify next mission unlocks once and inventory/date remain exact.

### QA-M-0702 — What We Carry

- **Prerequisite / result:** storm_prepared → route_clear.
- **Scene coverage:** SC-0704, SC-0705, SC-0706; verify each scene's EV conjunct, dialogue and transition.
- **Puzzle / witness:** P-14. P-13 witness ends E6,A2.5,H1,C3,R9,Z0,W2,K2, reserve30 safe. Diagnose the external feedthrough; safe readings 0.4 then 0.3 clear the route. A 1.2 reading does not. The February-to-April preparation montage maintains the stable base before the final trip.
- **Negative test:** The hatch interlock prevents storm EVA. Unsafe committed dose/air or lost mandatory garden/seed objectives offer a pre-step retry. One safe reading is insufficient. The direct uplink failure is a scripted incident, not a hidden penalty for a correct plan.
- **Expected pass:** Six steps complete, A>0,Z<=6,H>0,C>0,founder reserve30 safe,F-EXT identified and two clear readings.
- **Required assets:** A-01,A-02,A-03,A-04,A-07,A-10,A-11,A-19,A-22,A-23,A-28,A-29,A-42,A-43; common A-48–A-61.
- **Required systems:** SYS-01,SYS-02,SYS-03,SYS-04,SYS-05,SYS-07,SYS-09; common SYS-08/10/11/12.
- **Retry/save:** Repeat negative action, load pre-commit checkpoint, run witness, verify next mission unlocks once and inventory/date remain exact.

### QA-M-0801 — The Long Road

- **Prerequisite / result:** route_clear → summit_reached.
- **Scene coverage:** SC-0801, SC-0802, SC-0803; verify each scene's EV conjunct, dialogue and transition.
- **Puzzle / witness:** P-15. 14−5−5=4>=2; total journey 51 h<=72 h. Restore marker 2 before leaving. Home end E5,A5.1875,H1,C8,R14.625; all four checks valid. Travel sim advances 24 h outbound; local playable road length is intentionally compressed.
- **Negative test:** Missing spare blocks departure; off-road slope barrier offers return to last marker; unbraked exterior repair cannot start; home returnCLOSED prompts thirst forecast. No character switching across locations during free movement.
- **Expected pass:** Loadout valid, three buoys link, summit arrival at Apr 9 00:00, home checks verified.
- **Required assets:** A-01,A-02,A-03,A-04,A-07,A-10,A-11,A-12,A-14,A-28,A-31,A-33,A-34,A-42,A-44,A-45; common A-48–A-61.
- **Required systems:** SYS-01,SYS-02,SYS-03,SYS-04,SYS-05,SYS-06,SYS-07,SYS-09; common SYS-08/10/11/12.
- **Retry/save:** Repeat negative action, load pre-commit checkpoint, run witness, verify next mission unlocks once and inventory/date remain exact.

### QA-M-0802 — From Last Light to First Light

- **Prerequisite / result:** summit_reached → campaign_complete.
- **Scene coverage:** SC-0804, SC-0805, SC-0806; verify each scene's EV conjunct, dialogue and transition.
- **Puzzle / witness:** P-16. Isolation→zero→replace→close→power; L2 thenE3; checksumALO42 match; voice Aurora+Earth; return; five final indicators; photo and any dedication.
- **Negative test:** Wrong preset gives strength/obstruction text and can be changed; reconnect with housing open blocked. Link lost during call reuses checkpoint and transcript; final shutter waits for safety checks. No biological miracle or instant travel.
- **Expected pass:** Both links pass, voice checks logged, return confirmed, final five indicators pass, shared photo and dedication saved.
- **Required assets:** A-01,A-02,A-03,A-04,A-07,A-09,A-10,A-11,A-14,A-28,A-30,A-31,A-33,A-38,A-41,A-44,A-45,A-46,A-47; common A-48–A-61.
- **Required systems:** SYS-01,SYS-02,SYS-03,SYS-04,SYS-05,SYS-06,SYS-07,SYS-09,SYS-10; common SYS-08/10/11/12.
- **Retry/save:** Repeat negative action, load pre-commit checkpoint, run witness, verify next mission unlocks once and inventory/date remain exact.

## Boundary values and acceptance severity

P-02: exactly E0 is not a blackout; E<0 clamps to0 and applies A/H/C-2. A1 safe, A0 stops; Z3 safe, Z4 unsafe. H1 lives, H0 remains terminal within that attempt; crop C0 cannot revive without a new dated planting. G/frost/thirst counters from the superseded adaptation are not used. Cap E/A before consumption. At shift6 score dose before the ordinary drain. K clears before shift7. Test partial PUMP +1/full +2 and partial STACK K1/full K2; one alarm action resolves once. No free daytime crate rail. R ends3.6 crew-days in all seven-shift witnesses. Simultaneous crew and plant failure prioritises the safe mission stop.
P-05: a falling reading requires two time-separated samples; opening repaired line without verification cannot complete. P-07: slope 15° allowed, greater rejected; reserve 30 allowed, 29 rejected. P-08: inner seal cannot open outside dry quarantine. P-10: hot pixel across all frames rejected; identity waits for consent packet. P-11: fallback allocation7 allowed,8 rejected; all five segments acknowledged. P-14: route threshold reading<1; exactly 1 does not pass; two samples required. P-15: reserve2 allowed, less than2 rejected; journey 51 h within 72 h. P-16: local-only lock cannot start final voice call; voice call cannot set crew_returned.

P0 blocker: unreachable mission, unsolvable mandatory puzzle, irreversible critical loss, corrupt save, identity spoiler that breaks mystery, missing chapter/ending, captionless essential fact, untranslated mandatory release text. P1 major: broken optional choice, misleading science label, unreadable high-scale screen, mandatory tool/animation state absent, inaccessible alternative. P2 polish: nonblocking minor clipping, optional bark timing, cosmetic seam. Release requires no P0 and documented resolution of allP1 affecting the main path.

Acceptance evidence must record build ID, test platform, settings, route/choices, observed result and screenshot/log where useful. A document saying a future test should pass is not a passing execution result.

## Additional campaign release cases

- QA-18: Play each of the five modes; four role facts arrive at shifts1/1/2/3, Earth-set at4, drill at2 and alarm at5. Private Class/Family cards remain private until voluntarily shared; Solo receives all. Skipping a message does not fabricate a failure or block all play.
- QA-19: Check the source 25–30/20–25/25/30–35/25/25/35–40/35–45-minute chapter ranges; the working16-mission budget totals240minutes, excluding optional reading. Verify the10–14-hour complete-collection target through playtests.
- QA-20: Exercise all128 upgrade combinations. Check source caps, separate water conservation and both ending safety ledgers. No branch requires an unavailable upgrade; dust/impact upgrades replace maintenance with verification.
- QA-21: Collect24 logs,32 cards,16 cultivar entries,12 patches,8 postcards,24 stars and8 Golden Blooms. Recovery logs survive retries; practice can unlock them. Replay merges profile rewards once without editing campaign inventory or progress.
- QA-22: Finish all8 optional side stories, Station Days and postgame; none bypasses main missions. Offline core/Live Sky range fallback works; Storm Watch is opt-in and source-labelled, with no notifications or account requirement.
- QA-23: Noor’s name/founder connection and Ferreira’s confession occur inCH05; the CH02 anonymous gardener recalls yellow fields, and the final log explains the Academy name. Recovered vault types never become an invented6+6 inventory.
- QA-24: Final base air accounts for two occupants for33h and five for3h; rover provisions cover51h with72h supply. At E20/A8/H6 entry, E15 COOL/DIM/basic demand leaves E5/H1; A use2.8125 leaves A5.1875 and R18-3.375=14.625. Controller/azimuth/elevation/dual-link checks precede Noor’s live call at the authored Earth-set handover.
- QA-25: Inspect each “measured/computed” release claim against its bundled source, units and transformation. Missing data uses the specific [E]/[G] fallback; a citation alone is not proof of an imported curve.
