# Scientific puzzles — complete rules and solutions

All units below are bounded game units unless explicitly identified as a real measurement. Values are design constants, not engineering procedures. Timers measure player pressure only; scientific time advances at explicit commits. Each heading is a stable cross-reference anchor.

<a id="p-01"></a>
## P-01 — Commission and Plant

- **Mission / reason:** [M-0101](07_MISSION_DESIGNS/M-0101_A_Drawer_of_Light.md) — Commission the habitat and plant the recovered pair.
- **Location / equipment:** LOC-03; Probe, dry/wet references, two sealed planting cassettes, scanner.
- **Initial state:** Both cassettes empty; probe offset +10 displayed units; references read dry=10, wet=110.
- **Player instructions and intermediate steps:** Set zero using dry reference, span using wet reference; recheck dry=0 and wet=100. Scan packet seal, place one seed in each cassette, add water until 40–60 on the calibrated scale, select EXTERNAL TEST for Alo and INDOOR REFERENCE for Tara, close both seals.
- **Accepted solution:** Order: dry zero → wet span → recheck → packet scan → one seed each → water 50 → distinct labels → seals. Accept any final moisture 40–60 inclusive; extra water can be removed to waste before sealing.
- **Incorrect actions and feedback:** Sealing is blocked until calibration; duplicate seed/label assignment is blocked with the occupied cassette named. Flooding prompts drain rather than kills the seed.
- **Progressive hints H1 / H2 / H3:** Check the instrument before trusting it. / Use the two reference cups. / Dry must read 0, wet 100, then fill both to 50.
- **Difficulty, timing and retry:** Easy; 5–7 minutes. Reset only the unsettled cassette; no specimen is destroyed.
- **Completion trigger:** Both calibrated moisture values in band, seed count 1+1, labels distinct, seals closed.
- **Narrative consequence / flags:** pair_planted_pending; packet_initial_seen; unlock dated care montage.
- **Accessible input:** Every drag or hold also has Select source → Select target → Confirm; every visual observation has a text-equivalent reading. No puzzle requires colour perception, audio frequency discrimination, fast repeated presses or pixel-perfect pointing. A hint does not penalise the ending.

<a id="p-02"></a>
## P-02 — Seven Shifts, One Night

- **Mission / reason:** [M-0102](07_MISSION_DESIGNS/M-0102_Keep_the_Night.md) — Prepare, survive and restore shared water before first light.
- **Location / equipment:** LOC-01; four room consoles, battery jar, air tank, garden manifold, shelter and supply bundles.
- **Initial state:** E14/20, A6/10, Alo H6/10, W0/6, K0/2, crop C8/10, rations R12 crew-days, exposure Z0. Shifts 1–2 daylight (+8 each); 3–7 dark. Each shift is 7.2 h, so darkness totals 36 h.
- **Player instructions and intermediate steps:** Deliver the four role facts at their specified shifts; inspect, discuss, preview, choose physical actions and commit once. Drill at shift 2, Earth-set at shift 4, alarm at shift 5. PUMP, STACK or WAIT is one exclusive alarm choice. Resolve exposure before the shift-6 ordinary drain.
- **Accepted solution:** The all-COZY Bloom witness in the numeric contract ends E2,A1,H1,W0,K0,C3,R3.6,Z2 with no blackout. The Golden witness ends E0,A1,H5,W0,K0,C9,R3.6,Z2 with no blackout. Exactly E0 is not a blackout. Additional PUMP and STACK witnesses are listed there.
- **Incorrect actions and feedback:** A negative energy balance causes the published blackout penalties; it is not an automatic mission stop. A<=0 or unsafe exposure stops operations; H0 gives Alo lost if the crew completes safely. Show the cause and offer the complete last-shift checkpoint. Invalid transfer directions do not create water.
- **Progressive hints H1 / H2 / H3:** Store air while sunlight would overflow. / Prepare shielding before the alarm, then return the water. / Open the worked Bloom plan or Guided plan.
- **Golden hints G1 / G2 (unlock only after a first Bloom):** Golden needs Alo at 5 or more with no blackout, so every drop must reach the garden at exactly the right time. / Open the worked Golden plan.
- **Difficulty, timing and retry:** Main night portion approximately 20 minutes; action pressure optional. Reading and preview pause time. Retry restores pre-shift resources, actions and evidence.
- **Completion trigger:** Complete seven shifts with A>0, Z<=3, all four crew sheltered during exposure, and H>0. Golden requires all three stars (safe exposure, no blackout, living Alo) plus H>=5. Other safe/loss outcomes remain viewable without unlocking Chapter 2.
- **Narrative consequence / flags:** first_bloom_pending; ending/mastery record; first_bloom committed after SC-0106 and its old recording.
- **Accessible input:** Select source → Select target → Confirm substitutes for drag/hold. No colour-only, audio-only or rapid-input requirement; hints and assistance do not reduce ending eligibility.

<a id="p-03"></a>
## P-03 — Alo Meets Tara

- **Mission / reason:** [M-0201](07_MISSION_DESIGNS/M-0201_Borrow_a_Bee.md) — Cross-pollinate Alo and Tara without breaking containment.
- **Location / equipment:** LOC-05; Two compatible Fast Plant individuals, clean brushes A/B, sealed carrier, glove ports and microscope.
- **Initial state:** Flowers open; brush A and B clean; carrier empty; donor and recipient fields unset. Entry E14/20,A10/10,H6,C8,R18. Three sampled daylight operations use FULL/O0 and E1/A1 per reciprocal run, with ordinary basic1 and breathing1: after the three sampled operations E16,A4,H9,C10,R14.4. The dated background ledger separately covers unsampled care/consumption; planned food supply of at least14 crew-days over the seven-day interval leaves4 after total crew consumption28. No hidden refill occurs during a bee run.
- **Player instructions and intermediate steps:** Scan donor Tara; collect yellow grains from anthers with brush A using select/confirm; seal carrier; transfer through pressure interlock; scan recipient Alo; touch its receptive stigma through glove ports. Reverse using clean brush B from Alo to Tara. Make three reciprocal runs on days 1, 4 and 7 (April 30–May 6), with seven dated care visits. Check space weather before every run; charge E1/A1 once per whole reciprocal cycle, including its four airlock transitions. Record Alo’s purple/Tara’s green stem prediction; show the result in Chapter 4 without promising a genotype ratio.
- **Accepted solution:** Tara anther → sealed A → Alo stigma; Alo anther → sealed B → Tara stigma; confirm donor≠recipient each way; repeat for three reciprocal runs across seven dated days; record the stem prediction.
- **Incorrect actions and feedback:** Touching petal shows no transfer; using own pollen explains cultivar incompatibility; dirty brush prompts replace tip. No drag precision score.
- **Progressive hints H1 / H2 / H3:** A flower needs pollen from its partner. / Take pollen from the anther to the other plant’s stigma. / Use A for Tara→Alo and clean B for Alo→Tara.
- **Difficulty, timing and retry:** Easy; unlimited clean tips. Retry affects the current transfer only.
- **Completion trigger:** Three reciprocal runs valid, each charged E1/A1 once; seals passed, seven care visits and stem prediction logged.
- **Narrative consequence / flags:** pollen_shared_pending; lineage_parent_pair = Alo × Tara.
- **Accessible input:** Every drag or hold also has Select source → Select target → Confirm; every visual observation has a text-equivalent reading. No puzzle requires colour perception, audio frequency discrimination, fast repeated presses or pixel-perfect pointing. A hint does not penalise the ending.

<a id="p-04"></a>
## P-04 — Recorder Reconstruction

- **Mission / reason:** [M-0202](07_MISSION_DESIGNS/M-0202_A_Voice_Before_Us.md) — Recover the recorder context and recognise the earlier trial.
- **Location / equipment:** LOC-02; Three photographed labels; reconstruction board; recorder.
- **Initial state:** File A lacks date, file B lacks device, file C lacks channel; N.’s mustard-fields log is stored alongside them; source labels show 2034-04, HORT-01, ENGINEERING.
- **Player instructions and intermediate steps:** Assign each verified metadata token to its empty slot; inspect the chart showing reproductive stage not reached; play the matched fragment and N.’s yellow-mustard-fields memory, then send the technical fragment to Ferreira. Her engineer-voice resemblance is a suspicion only.
- **Accepted solution:** A.DATE=2034-04; B.DEVICE=HORT-01; C.CHANNEL=ENGINEERING. There are three unique token shapes with readable text; no combinatorial guessing requirement.
- **Incorrect actions and feedback:** Wrong token remains removable and displays which source disagrees; audio stays locked until all three match.
- **Progressive hints H1 / H2 / H3:** Find the original equipment plate. / Dates, devices and channels are different fields. / 2034-04, HORT-01, ENGINEERING.
- **Difficulty, timing and retry:** Easy; tokens reversible; reset preserves collected evidence.
- **Completion trigger:** All three matches correct, fragment transcript opened and N.’s mustard-fields clue heard/read.
- **Narrative consequence / flags:** recorder_context_pending; engineer_voice_heard. Identity of N remains unknown.
- **Accessible input:** Every drag or hold also has Select source → Select target → Confirm; every visual observation has a text-equivalent reading. No puzzle requires colour perception, audio frequency discrimination, fast repeated presses or pixel-perfect pointing. A hint does not penalise the ending.

<a id="p-05"></a>
## P-05 — Find the Falling Pressure

- **Mission / reason:** [M-0301](07_MISSION_DESIGNS/M-0301_Numbers_That_Disagree.md) — Find and repair the leak through independent observations.
- **Location / equipment:** LOC-02; Independent mechanical gauge, taps MAIN/GARDEN/RETURN, isolation valves, captive clamp.
- **Initial state:** Entry E14/20,A10/10,H6,C8,R18. Four daylight investigation phases of7.2h use DIM/O0, with basic E1 and light E1. Normal breathing A1 per phase; unresolved leak A1 in phases1–3, sealed before phase4 consumption. Witness ends E18,A3,H6,C8,R13.2. At most two location inspections per phase. Six candidates: main tank, habitat trunk, garden feedthrough, return line, airlock seal, annex branch. Initial panel uncertainty means location labels are candidates, not proof. At phase 2 an aftershock opens the annex branch; its automatic isolation must be verified before reopening the garden. Mechanical readings at t0/t10: MAIN 100/100, GARDEN 82/74, RETURN 100/100, relative test units.
- **Player instructions and intermediate steps:** Compare all six candidates using the three trunk taps and two location checks per phase; verify the aftershock annex isolation. Read all taps; close GARDEN isolation valve; recheck MAIN remains 100 and isolated GARDEN stays 74; fit clamp to GARDEN feedthrough from pressurised safe side; reopen slowly; run five 2-second checks.
- **Accepted solution:** Compare the six candidates within four investigation phases, verify the aftershock annex isolation, then isolate GARDEN only → verify stable trunk → apply clamp → open GARDEN slowly → five readings 100/100/100. Clamp cannot seat on a pressurised leaking connection.
- **Incorrect actions and feedback:** Closing MAIN produces a protected reserve warning and can be reopened immediately; wrong clamp location cannot latch; recheck explains remaining pressure fall.
- **Progressive hints H1 / H2 / H3:** Which reading changes over time? / Compare the manual garden reading. / Close GARDEN, clamp its feedthrough, reopen and verify five steady readings.
- **Difficulty, timing and retry:** Medium; planning pauses leakage. A committed unsafe trunk isolation safes and retries from gauge checkpoint.
- **Completion trigger:** Six candidates investigated within four phases, aftershock annex isolation verified, and five consecutive stable readings after correct clamp and reopening.
- **Narrative consequence / flags:** leak_sealed_pending; manual_gauge_trusted.
- **Accessible input:** Every drag or hold also has Select source → Select target → Confirm; every visual observation has a text-equivalent reading. No puzzle requires colour perception, audio frequency discrimination, fast repeated presses or pixel-perfect pointing. A hint does not penalise the ending.

<a id="p-06"></a>
## P-06 — A Harvest With a Future

- **Mission / reason:** [M-0302](07_MISSION_DESIGNS/M-0302_Forty-Two.md) — Make the annex safe, recover the map and harvest Alo’s legacy.
- **Location / equipment:** LOC-03; Maturity camera, substrate sensor, drying valve, pods, six counting wells, reserve container and map scanner.
- **Initial state:** On May 16 (plant day 35) pods mature; initial moisture 70; drying valve open; 42 seeds in six pods of 7. Hatch map has been scanned in preceding scene.
- **Player instructions and intermediate steps:** Confirm brown mature pods on camera and maturity chart; close irrigation to Alo only, never the whole greenhouse; run the dated May 16–21 dry-down to moisture 20; open six pods into six wells; count 7 each; allocate two wells (14), move two seeds back so planting 12 and reserve 30; sleeve petal and seal.
- **Accepted solution:** Maturity confirmed → irrigation OFF for mature Alo → dry to<=20 → six×7=42 → planting 12/reserve 30 → seal and lineage label. Two allocation buttons can directly choose 12/30; arithmetic dragging not required.
- **Incorrect actions and feedback:** Early irrigation stop is blocked before maturity; selecting Tara’s live irrigation displays wrong plant and leaves it unchanged. A miscount reopens that well. Seeds are never lost by cursor error.
- **Progressive hints H1 / H2 / H3:** Harvest after the pods mature. / Keep twelve for planting and thirty protected. / Six wells of seven total 42; allocate 12 and 30.
- **Difficulty, timing and retry:** Medium emotional pacing; no timer. Reset current counting step only.
- **Completion trigger:** 42 total, 12 allocated, 30 sealed reserve, map scanned and petal stored.
- **Narrative consequence / flags:** seed_legacy_pending; old_garden_seedling_only; vault_route_known; founder_reserve=30.
- **Accessible input:** Every drag or hold also has Select source → Select target → Confirm; every visual observation has a text-equivalent reading. No puzzle requires colour perception, audio frequency discrimination, fast repeated presses or pixel-perfect pointing. A hint does not penalise the ending.

<a id="p-07"></a>
## P-07 — Survey and Return

- **Mission / reason:** [M-0401](07_MISSION_DESIGNS/M-0401_Where_the_Sun_Cannot_Follow.md) — Plan the cold-trap route, survey ice and retain a return reserve.
- **Location / equipment:** LOC-09; Pressurised rover, route chart, slope scan, sample cup, calibrated ice scanner.
- **Initial state:** Base E14/20,A8/10,H6,C8,R18; two daylight base shifts use DIM/O0, cost E2 each and breathe A0.5 for two home cadets, ending E18,A7,H6,C8,R16.8. The two rover occupants have an independent 48-hour consumables manifest covering the dated round trip; never charge them again at base. Rover resource 100, mandatory return reserve 30. Routes: A short 8 km cost 35 each way, slope 24°; B ridge 12 km cost 30 each way, max 12°; C shadow 10 km cost 40 each way, slope 18°. Rover design limit 15°.
- **Player instructions and intermediate steps:** Inspect route cards; choose a route satisfying slope AND roundtrip reserve. Use the base-only slope card and rover-only headlight card to agree on the route. Place/test three beacons before blind corners. Drive three 100 m playable segments separated by labelled cruise. On route B stop at reference and sample points: dry reference signal 2; samples 2, 18, 19. Set threshold reference+10=12 and tag the two above threshold; collect one sealed sample.
- **Accepted solution:** B is the only valid route:100−30−30=40>=30 and 12°<=15°. Calibrate at 2, threshold 12; tag 18 and 19; retain 2 as negative control; collect one positive sample.
- **Incorrect actions and feedback:** Route A fails slope regardless of energy; C fails slope and reserve. Uncalibrated positive reports are marked unverified. Off-road driving stops at a warning boundary, never tumbles into an unwinnable pit.
- **Progressive hints H1 / H2 / H3:** A short road may be too steep. / Check both the return cost and slope. / Choose B, use dry 2, then tag 18 and 19.
- **Difficulty, timing and retry:** Medium; rover checkpoints at each surveyed beacon; samples persist only after sealed save.
- **Completion trigger:** Valid route chosen, three beacons linked, three stops reached, reference recorded, two positives tagged, one sample sealed, return reserve forecast>=30.
- **Narrative consequence / flags:** ice_survey_pending; return_route_B; sample_verified. Resource units are game abstractions.
- **Accessible input:** Every drag or hold also has Select source → Select target → Confirm; every visual observation has a text-equivalent reading. No puzzle requires colour perception, audio frequency discrimination, fast repeated presses or pixel-perfect pointing. A hint does not penalise the ending.

<a id="p-08"></a>
## P-08 — Recover Without Ruining

- **Mission / reason:** [M-0402](07_MISSION_DESIGNS/M-0402_Twelve_in_the_Dark.md) — Recover a sealed vault and stabilise its dry specimens at home.
- **Location / equipment:** LOC-10; External probe, insulated sleeve, cradle, rover cargo mount, quarantine glovebox.
- **Initial state:** Outer case cold; biological inner seal intact. Handling order unverified; inner seed temperature history recorded in insulated vault, not equal to lunar soil temperature.
- **Player instructions and intermediate steps:** Outside: read probe, fit sleeve, latch cradle, secure rover mount. At base: dock sealed case in dry glovebox, run warm-up from cold→cool→room as three confirmed stages, verify no condensation, open inner seal, inventory twelve distinct specimen labels from the vault ledger in 18, scan lid.
- **Accepted solution:** Probe→sleeve→cradle→mount→return→dry glovebox→three-stage sealed warm-up→condensation check→open→12 labels.
- **Incorrect actions and feedback:** Open command outside or before dry warm-up is blocked with condensation explanation. Wrong label can be corrected; a damaged-outer-case false alarm does not destroy specimens.
- **Progressive hints H1 / H2 / H3:** Keep it sealed until home. / Warm dry seeds in their closed container. / Complete sleeve/cradle, then three warm-up stages in the glovebox before opening.
- **Difficulty, timing and retry:** Medium; no timer; checkpoint field-secured and home-docked.
- **Completion trigger:** Twelve distinct specimens recorded; lid scanned; quarantine status set pending viability evaluation, not assumed healthy.
- **Narrative consequence / flags:** vault_recovered_pending; vault_specimens12; vault_cotton1; vault_note_seen.
- **Accessible input:** Every drag or hold also has Select source → Select target → Confirm; every visual observation has a text-equivalent reading. No puzzle requires colour perception, audio frequency discrimination, fast repeated presses or pixel-perfect pointing. A hint does not penalise the ending.

<a id="p-09"></a>
## P-09 — Reconstruct the Departure

- **Mission / reason:** [M-0501](07_MISSION_DESIGNS/M-0501_The_Engineer_Comes_Home.md) — Welcome Ferreira and assemble a factual evacuation sequence.
- **Location / equipment:** LOC-01; Four evidence cards, public report, boarding signatures, chronology board.
- **Initial state:** Cards unplaced: seedling chart Apr 3, relay/power fault Apr 4 12:00, evacuation order 12:10, all crew boarding 12:40.
- **Player instructions and intermediate steps:** Place chart→fault→order→boarding; match the two highlighted personal signatures to FER and gardener N.R.; compare entire crew count 4 departed/4 boarded; select all crew returned, trial stopped before flowers.
- **Accepted solution:** Chronological order chart/fault/order/boarding; supported conclusion ALL FOUR RETURNED. Do not identify the gardener’s full name from initials alone.
- **Incorrect actions and feedback:** Abandoned gardener conclusion highlights contradictory boarding evidence. Reordering remains free; no antagonist accusation score.
- **Progressive hints H1 / H2 / H3:** Use the timestamps. / Boarding happened after the retreat order. / All four signatures boarded; the garden, not a person, was left behind.
- **Difficulty, timing and retry:** Easy-medium; no loss; all evidence remains available.
- **Completion trigger:** Four cards in timestamp order and supported conclusion selected.
- **Narrative consequence / flags:** zero_sequence_pending; zero_all_returned; ferreira_admission_ready.
- **Accessible input:** Every drag or hold also has Select source → Select target → Confirm; every visual observation has a text-equivalent reading. No puzzle requires colour perception, audio frequency discrimination, fast repeated presses or pixel-perfect pointing. A hint does not penalise the ending.

<a id="p-10"></a>
## P-10 — Flashes and a Signature

- **Mission / reason:** [M-0502](07_MISSION_DESIGNS/M-0502_Permission_to_Answer.md) — Observe impact flashes, maintain the station and identify Noor.
- **Location / equipment:** LOC-01/02/03; archived camera candidates, hot-pixel comparison, panel cleaner, safe-side dome patch and signed manifest.
- **Initial state:** Three observation/maintenance phases; E14/20,A8/10,H6,C8,R18. Eight genuine transient examples and two persistent detector artifacts; six verified flashes satisfy the mission. Dust reduces solar income from 8 to 6 until cleaned; a micro-leak consumes 1 extra air per unresolved phase (0.5 with flexible seals). Dust Shield/Whipple bumper prevent the respective event and supply a verification task instead.
- **Player instructions and intermediate steps:** Compare candidate frames; mark six genuine flashes and reject both fixed artifacts. First maintenance opportunity: clean the affected panel and clamp/patch the isolated dome spur from its safe side, then verify pressure. Run three phases with COZY heat, DIM light, O0; five-person breathing is 1.25 per full 7.2 h phase. With immediate maintenance, daylight income is 8 for all three phases. After evidence pass, match N.R. to Dr. Noor Rahman on the signed manifest and send any of the three invitations.
- **Accepted solution:** Six genuine events, both artifacts rejected; dust removed/prevented, leak sealed/prevented and pressure verified; signed identity matched and invitation sent. Witness E16,A4.25,H6,C8,R13.5,Z0 after three phases. All eight verified flashes with no false report satisfy the observation Golden criterion.
- **Incorrect actions and feedback:** A hot pixel remains fixed across frames. Mistags can be corrected without reaction speed scoring. Unrepaired faults stay visible in the next forecast. Noor’s connection is not inferred from nationality; the signed record supplies it.
- **Progressive hints H1 / H2 / H3:** Compare more than one frame. / A real flash changes; a detector fault stays. / Verify six transients, clean and patch or verify the protective upgrade, then match the signed manifest.
- **Difficulty, timing and retry:** Untimed candidate review and select-confirm repairs; checkpoint before each observation/maintenance phase.
- **Completion trigger:** At least six verified flashes, both artifacts rejected, maintenance passed/protected, A>0, H>0, signed identity matched and invitation sent; set noor_identity_revealed.
- **Narrative consequence / flags:** noor_known_pending; noor_identity_revealed; noor_contact_consented; Noor alive and Academy founder; cotton planting follows.
- **Accessible input:** Select source → Select target → Confirm substitutes for drag/hold. No colour-only, audio-only or rapid-input requirement; hints and assistance do not reduce ending eligibility.

<a id="p-11"></a>
## P-11 — Protect the Small Light

- **Mission / reason:** [M-0601](07_MISSION_DESIGNS/M-0601_A_Plan_for_Darkness.md) — Plan the eclipse while keeping life support and the garden warm.
- **Location / equipment:** LOC-02; main E14/20 jar, protected-services schedule, pump, camera and optional floodlights.
- **Initial state:** Five labelled teaching segments: precharge, ingress, totality, egress, recovery. Until a verified illumination/duration curve is integrated, use a disclosed [G] seven-unit allocation from the 14-unit jar. Essential package (circulation, minimum heat, dim grow light and guide light) costs 1 per segment, pump/camera readiness each 1 once; decorative floods 3 each activation. These totals replace elapsed-time demand in this fallback; never charge them on top of a second duration model.
- **Player instructions and intermediate steps:** Essentials ON in all five segments; prepare return pump in segment 1, camera in segment 2, floods OFF. Acknowledge all five segments and the return reserve. The main eclipse feed and family call occur during valid Earth contact, and egress is recorded after P-12 restoration.
- **Accepted solution:** Essentials [1,1,1,1,1], pump [1,0,0,0,0], camera [0,1,0,0,0], floods all OFF; total 7 and E7 at recovery. Equivalent pump/camera placements before their deadlines are accepted. The verified-data release replaces this fallback with demand scaled by segment-hours/7.2 as specified in the source gameplay document and rebalances the forecast.
- **Incorrect actions and feedback:** Omitting essentials identifies the affected service. Spending more than the seven-unit protected allocation warns about the reserved recovery margin. Edit freely before commitment.
- **Progressive hints H1 / H2 / H3:** Protect essential services throughout. / Five essentials plus one pump and one camera equal seven. / Keep essentials ON, prepare pump in 1 and camera in 2, with floodlights OFF.
- **Difficulty, timing and retry:** Untimed planning; reversible individual settings.
- **Completion trigger:** All five essential packages scheduled, pump/camera each once before deadlines, allocation<=7 and five segment acknowledgements saved.
- **Narrative consequence / flags:** eclipse_ready_pending; kai_plan_shared.
- **Accessible input:** Select source → Select target → Confirm substitutes for drag/hold. No colour-only, audio-only or rapid-input requirement; hints and assistance do not reduce ending eligibility.

<a id="p-12"></a>
## P-12 — Observe, Isolate, Restore

- **Mission / reason:** [M-0602](07_MISSION_DESIGNS/M-0602_All_the_Sunrises.md) — Use a camera to observe the eclipse and restore a feeder safely.
- **Location / equipment:** LOC-02; Filtered remote camera, feeder F2, isolate/reset/test controls, manual fault indicator.
- **Initial state:** Camera filtered; protected bus normal; F2 trips during ring observation. Camera and view-screen branch only; habitat services unaffected.
- **Player instructions and intermediate steps:** Log ingress and ring, inspect conceptual atmosphere diagram; on trip isolate F2, confirm current=0 and FAULT CLEARED, reset breaker, close isolation, test camera branch only, log egress. Acknowledge companion’s radio support.
- **Accepted solution:** Isolate→zero/fault check→reset→reconnect→camera test; three observation records include the restored egress.
- **Incorrect actions and feedback:** Reset before isolation is interlocked and explained; choosing protected main bus displays survival services warning and does not switch it. Egress waits for authored restoration, not real-time solar timing.
- **Progressive hints H1 / H2 / H3:** Keep the protected bus untouched. / Isolate the failed feeder before reset. / F2 off, confirm 0, reset, reconnect, camera test.
- **Difficulty, timing and retry:** Medium; untimed or 90-second optional pressure with pause. Retry from feeder-trip checkpoint.
- **Completion trigger:** F2 tested, ingress/ring/egress recorded, support call acknowledged.
- **Narrative consequence / flags:** kai_supported_pending; eclipse_observed.
- **Accessible input:** Every drag or hold also has Select source → Select target → Confirm; every visual observation has a text-equivalent reading. No puzzle requires colour perception, audio frequency discrimination, fast repeated presses or pixel-perfect pointing. A hint does not penalise the ending.

<a id="p-13"></a>
## P-13 — One Integrated Storm Plan

- **Mission / reason:** [M-0701](07_MISSION_DESIGNS/M-0701_Your_Call_Cadets.md) — Plan three counterfactual storm waves and protect crew, garden and seed reserve.
- **Location / equipment:** LOC-04; E30/32,A10/10,H6,C8,R18, six shared water units, two crate-shield units, protected two-compartment seed case.
- **Initial state:** Chapter 7 logistics snapshot after preparation costs, not Chapter 1 carryover. Six dark 7.2 h steps, multipliers [1,1,2,2,1,1]. Five lunar occupants (including Ferreira) consume A1.25 and R1.5 crew-days per step. Three waves span steps 1–2, 3–4 and 5–6.
- **Player instructions and intermediate steps:** Two allowed preparation transfers put W4 in shelter; stage full K2 supply bundles and latch both founder-reserve compartments (15+15=30) before peak step 3. Schedule COZY heat, DIM light, O0 throughout. HOLD W in 1–5; DRAIN to W2 in step 6 after that step’s exposure. Isolate the exposed uplink before the peak. No free solar income during the storm.
- **Accepted solution:** W [4,4,4,4,4,2], K2 throughout exposure, COZY/DIM/O0 in all six steps. Shield S6 gives zero game dose even in peak steps. Costs 6*(1+2+1)=24, ending E6,A2.5,H1,C3,R9,Z0; seed reserve30 stays protected. All five crew are sheltered.
- **Incorrect actions and feedback:** Early drain reduces shelter before a later exposure. Missing seed compartment prevents readiness. Alternative plans are accepted when they meet the same safety and living-garden goals; owned upgrades apply once.
- **Progressive hints H1 / H2 / H3:** Put the seeds inside before the peak. / Water and cargo share the shielding job. / Prepare W4 and K2; COZY/DIM throughout; drain in step 6 after exposure.
- **Difficulty, timing and retry:** Integrated planning; no irreversible cost during preview; Guided plan available.
- **Completion trigger:** Feasible six-step plan, both seed compartments latched, five-person roster acknowledged, uplink isolation scheduled.
- **Narrative consequence / flags:** storm_prepared_pending; protected_founder_seeds30; plan snapshot passed to P-14.
- **Accessible input:** Select source → Select target → Confirm substitutes for drag/hold. No colour-only, audio-only or rapid-input requirement; hints and assistance do not reduce ending eligibility.

<a id="p-14"></a>
## P-14 — Three Waves and a Broken Link

- **Mission / reason:** [M-0702](07_MISSION_DESIGNS/M-0702_What_We_Carry.md) — Execute the storm plan, protect living crops and seeds, then diagnose the failed uplink.
- **Location / equipment:** LOC-04; P-13 plan, local telemetry, stored log, external branch test and route dosimeter.
- **Initial state:** Six storm steps; game multipliers [1,1,2,2,1,1]. Use P-02 energy, plant and shelter rules, Chapter 7 reserves and five-person air/food rates. Chapter 7’s Z<=6 limit overrides Chapter 1’s Z<=3 limit; its six storm multipliers are explicit. K remains installed through step 6 and is cleared only after the storm; P-02’s shift-7 removal belongs to Chapter 1.
- **Player instructions and intermediate steps:** Confirm five occupants. Execute all six steps; dose is sampled before an ordinary transfer, using the P-02 shelter table times the current multiplier. Play Noor’s last log after step 2 in the lull; it explains Alo and the Last Light Academy name. Keep hatch closed during exposure. After step 6 verify local network PASS, direct dish path FAIL and external feedthrough FAIL; select F-EXT. Two route readings below the game threshold 1, ten scenario minutes apart, clear later exterior preparation.
- **Accepted solution:** P-13 witness ends E6,A2.5,H1,C3,R9,Z0,W2,K2, reserve30 safe. Diagnose the external feedthrough; safe readings 0.4 then 0.3 clear the route. A 1.2 reading does not. The February-to-April preparation montage maintains the stable base before the final trip.
- **Incorrect actions and feedback:** The hatch interlock prevents storm EVA. Unsafe committed dose/air or lost mandatory garden/seed objectives offer a pre-step retry. One safe reading is insufficient. The direct uplink failure is a scripted incident, not a hidden penalty for a correct plan.
- **Progressive hints H1 / H2 / H3:** Finish all three waves before going outside. / A working local radio isolates the failure to the Earth path. / Keep the six-step witness, select F-EXT and record two below-threshold readings.
- **Difficulty, timing and retry:** Forecast available throughout; safe wait can be compressed. Checkpoint before every step.
- **Completion trigger:** Six steps complete, A>0,Z<=6,H>0,C>0,founder reserve30 safe,F-EXT identified and two clear readings.
- **Narrative consequence / flags:** route_clear_pending; radio_external_failed; final_log_heard; all_crew_safe.
- **Accessible input:** Select source → Select target → Confirm substitutes for drag/hold. No colour-only, audio-only or rapid-input requirement; hints and assistance do not reduce ending eligibility.

<a id="p-15"></a>
## P-15 — Two Teams, One Road

- **Mission / reason:** [M-0801](07_MISSION_DESIGNS/M-0801_The_Long_Road.md) — Prepare two teams and traverse the relay route with verified reserves.
- **Location / equipment:** LOC-11; Three-seat pressurised rover, controller spare, three repeater buoys, home-system board.
- **Initial state:** Rover E14 (source units); independent supplies 72 h; 120 km each way; outbound travel/heat/repair allowance 5, return allowance 5; minimum reserve 2. Marker2 battery dead. Home E20/cap26,A8,H6,C8,R18,W0; 36 h COOL/DIM/basic demand is 5*(1+1+1)=E15. COOL costs H1 per 7.2 h without insulation; the five-shift night ends H1, so no unavailable upgrade is required. Air use is 0.5 per 7.2 h for the two home cadets for 33 h, then 1.25 per 7.2 h for all five for the final 3 h: total 2.8125.
- **Player instructions and intermediate steps:** Load controller, battery spare and 72 h supplies; assign FER/KAI/RAF rover and MEI/AMA home. Choose surveyed road (max 12°, allowance 5), not shortcut (22°, allowance 3.5). At marker 2 stop, brake, isolate buoy, replace battery, reconnect and test chain 1→2→3. At home set heatMIN (COOL), lampDIM, returnOPEN, verify independent pressure; acknowledge summit packet.
- **Accepted solution:** 14−5−5=4>=2; total journey 51 h<=72 h. Restore marker 2 before leaving. Home end E5,A5.1875,H1,C8,R14.625; all four checks valid. Travel sim advances 24 h outbound; local playable road length is intentionally compressed.
- **Incorrect actions and feedback:** Missing spare blocks departure; off-road slope barrier offers return to last marker; unbraked exterior repair cannot start; home returnCLOSED prompts thirst forecast. No character switching across locations during free movement.
- **Progressive hints H1 / H2 / H3:** A return reserve belongs in the departure plan. / Marker2 is part of the radio path. / Use surveyed route, restore buoy 2, home heatMIN/lampDIM/returnOPEN.
- **Difficulty, timing and retry:** Medium; guided cruise and station-view alternative; checkpoint each marker and home handover.
- **Completion trigger:** Loadout valid, three buoys link, summit arrival at Apr 9 00:00, home checks verified.
- **Narrative consequence / flags:** summit_reached_pending; aurora_home_ready; repeater_chain_live; travellers_at_summit.
- **Accessible input:** Every drag or hold also has Select source → Select target → Confirm; every visual observation has a text-equivalent reading. No puzzle requires colour perception, audio frequency discrimination, fast repeated presses or pixel-perfect pointing. A hint does not penalise the ending.

<a id="p-16"></a>
## P-16 — The Link and the Living Garden

- **Mission / reason:** [M-0802](07_MISSION_DESIGNS/M-0802_From_Last_Light_to_First_Light.md) — Restore both links, bring the team home and validate the living garden.
- **Location / equipment:** LOC-12; Replacement controller, isolator, two antenna channels, signal meter, checksum, final garden panel.
- **Initial state:** Relay dark; housing damaged controller. Local bearing presets L1=poor,L2=good,L3=blocked; Earth presets E1=poor,E2=blocked,E3=good. First checksum incomplete until both links lock. The upcoming Aurora Earth-set handover window is displayed; both locks must be ready before its authored deadline, with an untimed equivalent.
- **Player instructions and intermediate steps:** Isolate power, test zero, remove controller, install matching spare, close housing, reconnect. Use azimuth/elevation dials to match the displayed local bearing L2 and the Earth bearing E3; hold a stable lock for 3 s or tap-confirm in accessible mode. L/E presets provide an equally rewarded assisted alternative. Bearings come from bundled geometry when verified; until then label them scenario bearings. Send checksum ALO42 and receive exact match from Aurora; perform both voice checks. Return journey 24 h. At sunrise verify crew 5 safe, founder reserve 30 and eleven unplanted vault specimens protected, garden pressure stable, temperature stable, cotton alive; open shutter and save photo/dedication.
- **Accepted solution:** Isolation→zero→replace→close→power; L2 thenE3; checksumALO42 match; voice Aurora+Earth; return; five final indicators; photo and any dedication.
- **Incorrect actions and feedback:** Wrong preset gives strength/obstruction text and can be changed; reconnect with housing open blocked. Link lost during call reuses checkpoint and transcript; final shutter waits for safety checks. No biological miracle or instant travel.
- **Progressive hints H1 / H2 / H3:** A relay needs both ends. / Connect Aurora’s repeater chain before Earth. / L2 thenE3, checksumALO42, verify both voices; return and open the safe shutter.
- **Difficulty, timing and retry:** Medium; no dexterity timer; all steps checkpointed after closed housing and link validation.
- **Completion trigger:** Both links pass, voice checks logged, return confirmed, final five indicators pass, shared photo and dedication saved.
- **Narrative consequence / flags:** campaign_complete_pending; relay_live; crew_returned; final_garden_validated; credits_available. MARS drawer optional.
- **Accessible input:** Every drag or hold also has Select source → Select target → Confirm; every visual observation has a text-equivalent reading. No puzzle requires colour perception, audio frequency discrimination, fast repeated presses or pixel-perfect pointing. A hint does not penalise the ending.

## P-02 numeric execution contract

This contract is reproduced from [the existing 3D gameplay design, section 6](../docs/GAMEPLAY_DESIGN_FINAL.md#6-chapter-1-numerical-contract). It replaces this folder’s incompatible B/O/G/frost/thirst model and free daytime crate staging. E=energy, A=air, H=Alo health, W=water shielding, K=crate shielding, C=edible-crop condition, R=crew-day rations, Z=game exposure. Changes must update both documents and the mission/test summaries together.


The original energy, air, Alo, light, heat and shelter values are retained. Costs and thresholds are [G], with real-unit context from the science document. A new crop/ration layer reuses the garden's existing circuit and reservoir; it does not add another allocation console or energy currency.

| State/control | Cadet baseline |
|---|---|
| Energy E | Start 14; cap 20; day income 8 in shifts 1–2 |
| Air A | Start 6; cap 10; normal breathing costs 1 per shift |
| Alo health H | Start 6; cap 10; zero is terminal within that attempt |
| Water wall W | Start 0; cap 6; garden usable water = 6-W |
| Crate shielding K | Start 0; cap 2; separate from water; removed before shift 7 |
| Heat | Day automatically warm; night COZY cost 2 / damage 0; COOL cost 1 / Alo damage 1; COLD cost 0 / Alo damage 2 |
| Air production O | 0, 1 or 2 energy, adding the same air amount |
| Garden light L | OFF cost 0 / plant change -1; DIM cost 1 / change 0; FULL cost 2 / change +1 |
| Basics | Cost 1 energy every shift; always scheduled |
| Ordinary transfer | FILL +2 W; HOLD; DRAIN -2 W; one command in shifts other than 5 |
| Thirst | W >= 4 after transfers causes Alo -1 |
| Crop condition C | Start 8; cap 10; shares L and water manifold; light change as above, thirst -1, COLD -1, COOL/COZY 0 |
| Stored food R | Start 12 crew-days; use 1.2 crew-days per 7.2-hour shift for four crew; no harvest during Chapter 1 |
| Exposure Z | Sum of two storm-shift game doses; never presented as sieverts |

**Food production:** the indoor rack contains an already growing edible crop batch. Planting-to-harvest takes its documented crop life cycle, not one shift. Light/cold/water decisions change C and its later yield. The forecast shows the projected next harvest. At a scheduled mature harvest after a story time transition, yield is `round(4*C/10, 1)` crew-days [G], then a newly planted batch starts at C=8. This is a small dietary supplement, not a claim that one rack feeds the whole crew indefinitely. A dead batch yields zero; stored supplies bridge the interval. During chapter-to-chapter time jumps, a labelled station ledger records resupply, consumption, mature harvest and new planting rather than silently resetting food. The educational question is whether saving power now damages later food production.

**Alarm choices, shift 5:**

- **PUMP:** one transfer of up to +2 W; ordinary systems use the chosen settings. A 15-second guided valve task starts only after the player chooses it. Three broad, ordered valve confirmations unlock the full +2. Each accepted confirmation counts once. Family/assisted mode completes the same confirmations without a timer. Incomplete pumping moves only +1; the preview then recalculates.
- **STACK:** a 30-second snap-placement task. Four supply bundles fill outlined bunk slots; complete placement gives K=2, partial placement gives K=1. W does not change. Set heat COOL, O=0 and L=OFF for this shift; show that cost before selection. No detailed water-fluid or falling-crate simulation is required.
- **WAIT:** no minigame or extra shelter; keep the chosen settings. Waiting is a legitimate strategy if preparation is adequate. The shelter warning shows what is known.

PUMP, STACK and WAIT are mutually exclusive. At timer expiry resolve the selected action once, with completed progress. A human can always choose assisted input before starting; motor speed is not the learning outcome.

**Exact shift order:**

1. Save the pre-shift checkpoint; validate settings and one allowed transfer/alarm command. For shift 5, complete/resolve the alarm action before the economic update. For shift 7, remove K.
2. Add daylight income and clamp E to 20 **before** spending; record overflow. Add O and clamp A to 10 **before** breathing.
3. Exposure in shift 5 uses shelter after the alarm; exposure in shift 6 uses shelter at the start of that shift, before its ordinary transfer. Effective shelter S=min(6,W+K). Dose per storm shift: S 0–1 gives 3; 2–3 gives 2; 4–5 gives 1; 6 gives 0.
4. Apply the permitted ordinary W transfer (except shift 5); cap W to 0–6. Transfers conserve total water. Crates do not remove garden water.
5. Subtract basics + heat + O + L from E. Day heat costs 0. If the result is **below 0**, mark a blackout, set E=0, apply A-2, H-2 and C-2 [G]. Exactly E=0 is an empty battery warning, not that shift's blackout; the next unpaid demand can cause one. Oxygen production/plant growth are a deliberately simplified shift model, not second-by-second electrolysis under a failed power bus.
6. Subtract breathing A-1; apply light, cold and thirst to H/C using post-transfer W. Combine changes, then clamp to 0–10. Dead H/C do not resurrect within an attempt. Consume R by elapsed scenario days, with no new crop harvest during these shifts.
7. If A<=0 stop the mission and offer retry. If food would run out, trigger an early resupply/abort requirement instead of depicting immediate starvation; Chapter 1's starting stock covers the night. H=0 means Alo lost, but safe crew operation can continue to the ending.
8. Record before/after values, causes, event source and action success. Render the same state to all consoles, HUD and actors. Evaluate the sunrise result after shift 7.

**Endings and progress:** retain three mastery stars: crew exposure Z<=3; no blackout; Alo alive. Golden Bloom requires all three and H>=5. Bloom requires a completed mission with safe crew and H>0. Alo lost means safe crew completes the night with H=0. Mission stopped covers air failure or a crew exposure safety breach; pre-loaded flight rules initiate the abort while Earth is down. Ferreira's live response appears only in a later Earth-visible epilogue. Retry restores the complete last checkpoint. Food condition gets a visible harvest forecast and garden-care badge; it does not replace these canonical endings. Story progression requires safe completion and a living Alo; mastery stars do not gate the next chapter.

**Balance honesty:** the previous claim that COZY every night necessarily causes a blackout is not retained. Under these base values, a valid all-COZY plan has day O=[2,0], L=[FULL,FULL], night L=OFF, W fills in shifts 3–4, WAIT in 5, drain in 6–7. Final E=2, A=1, H=1, W=0, Z=2; it earns three stars. There is no unpublished guarantee about 923 states or random-win rates. Re-run balance after implementation, food calibration or any parameter change; publish the actual version and results. The lesson is informed trade-offs, not a forced single solution.

## Executed Chapter 1 arithmetic witnesses

Each row is `heat / air production / light / ordinary water transfer`; heat is ignored in daylight. Numeric heat 0/1/2 = COLD/COOL/COZY, light 0/1/2 = OFF/DIM/FULL. At shift 5 the alarm action replaces the ordinary transfer. STACK forces COOL/O0/OFF regardless of previous settings. Exactly E0 counts as no blackout; negative demand causes a blackout.

| Plan | Shift 1 | Shift 2 | Shift 3 | Shift 4 | Shift 5 | Shift 6 | Shift 7 | Result E/A/H/W/K/C/R/Z |
|---|---|---|---|---|---|---|---|---|
| Bloom / WAIT | DAY/2/2/HOLD | DAY/0/2/HOLD | 2/0/0/FILL | 2/0/0/FILL | 2/0/0/WAIT | 2/0/0/DRAIN | 2/0/0/DRAIN | 2 / 1 / 1 / 0 / 0 / 3 / 3.6 / 2 |
| Golden | DAY/2/2/HOLD | DAY/0/2/DRAIN | 1/0/2/DRAIN | 1/0/2/FILL | 1/0/0/STACK | 2/0/0/HOLD | 1/0/2/DRAIN | 0 / 1 / 5 / 0 / 0 / 9 / 3.6 / 2 |
| PUMP | DAY/1/2/DRAIN | DAY/1/2/DRAIN | 1/0/0/HOLD | 1/0/0/FILL | 2/0/1/PUMP | 1/0/2/HOLD | 1/0/2/FILL | 0 / 1 / 1 / 6 / 0 / 7 / 3.6 / 2 |
| STACK | DAY/2/0/FILL | DAY/2/1/DRAIN | 1/0/1/DRAIN | 1/0/2/FILL | 1/0/0/STACK | 2/0/0/HOLD | 2/0/1/DRAIN | 0 / 3 / 1 / 0 / 0 / 6 / 3.6 / 2 |

**Golden Bloom difficulty: decided 24 Oct 2026.** Golden Bloom is a deliberately rare expert goal, as the story says ("Rare: the expert goal"). Under the locked values it is expected to be very narrow, possibly only reachable with Alo ending at exactly H=5. No number changes. Support is added instead: the G1/G2 hints and a worked Golden plan (the witness above) unlock after the player's first Bloom, and Bloom, not Golden, is what unlocks the story. **On 13 Nov:** count every possible plan with the implemented simulation and record how many reach each ending and Golden's final-H range. **Pre-agreed fallback:** if no playtester reaches Golden unaided within three attempts after a Bloom, lower the threshold to H>=4. That only happens after re-running the full P-02 test suite and balance count, and updating this contract, GAMEPLAY_DESIGN_FINAL §6 and the mission/test summaries together.

These worked paths were recalculated for this review, without a game runtime. The PUMP example deliberately leaves W6 after scoring to exercise conservation; a post-night return command empties the wall without changing the scored ending. A player need not execute a drain when no water is borrowed. Full/partial alarm actions follow the source rules; no extra pump, free daylight STACK or second crate rail is awarded.

## P-13 / P-14 execution and upgrades

Use the Chapter 7 logistics profile, source dose table and six-step plan above. Before each exposure, apply any emergency action, then score shelter; ordinary drains follow exposure. Deduct basics/heat/air/light and apply plant effects. With five crew, breathing is 1.25 and food 1.5 per full shift. Seed readiness and radio isolation are boolean preparation checks, not recurring hidden costs. Local communications and the protected greenhouse circuit survive direct-uplink damage.

The persistent upgrades in [campaign systems](10_GAMEPLAY_SYSTEMS.md#campaign-progression-and-optional-play) apply once: shielding capped at 6, separate ice water conserved, FULL-lamp discount, insulation and warning/bundle modifiers. A baseline path is arithmetic evidence for the unmodified scenario only; release requires testing all 128 reachable upgrade combinations. No all-path balance pass is claimed here.

## Presentation constraints

Use plain observations in feedback: identify the reserve shortfall or unverified sample. The air maker represents protected electrolysis feedstock; the garden does not instantly feed or oxygenate the crew. Game exposure is not mSv. Canonical historical storm dates are displayed on replay feeds; story dates remain fictional. Never present illustrative sky or radiation curves as imported measurements.
