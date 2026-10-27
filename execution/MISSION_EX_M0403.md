# EX-M0403 — Recover Without Ruining

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Mandatory mission.**



## Assignment

Keep the biological seal intact, secure cargo and return with supported reserves. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.

Execute this bounded task, integrate it with the current project and produce the acceptance evidence below. First reconcile the snapshot with current files; reuse already approved work and complete the real remaining gap.


## Mandatory shared context

Read [02_SHARED_CONTRACT.md](02_SHARED_CONTRACT.md), [03_SYSTEM_INTERFACES.md](03_SYSTEM_INTERFACES.md), [04_CURRENT_STATE.md](04_CURRENT_STATE.md), [05_ACCEPTANCE_AND_HANDOFF.md](05_ACCEPTANCE_AND_HANDOFF.md). Also read the current [AGENTS.md](../AGENTS.md), [PRODUCTION_HANDBOOK.md](../PRODUCTION_HANDBOOK.md) and newest [HANDOFF.md](../HANDOFF.md) entries. Current locked English-only, faceless plants, anime cast and scientific boundaries override older source wording.


## Inputs to inspect

- [full-game-story/story-data.json](../full-game-story/story-data.json)
- [full-game-story/STORY_FULL.md](../full-game-story/STORY_FULL.md)
- [production/manifest/scene_index.csv](../production/manifest/scene_index.csv)
- [production/audio/vo_lines.csv](../production/audio/vo_lines.csv)
- [game-design/08_PUZZLE_DESIGNS.md](../game-design/08_PUZZLE_DESIGNS.md)
- [game-design/09_WORLD_AND_LEVEL_DESIGN.md](../game-design/09_WORLD_AND_LEVEL_DESIGN.md)


## Ownership and dependencies

Own this mission's scene composition/content bindings and targeted integration tests; proposed root `game/scenes/chapters/ch04/`. Shared state, simulation, UI and characters remain owned by their SYS/UI/ASSET tasks.

Prerequisite `EX-M0402`; SYS02..08; chapter puzzles P-07, P-08; owning location/asset/UI tasks. If a service is not ready, coordinate one contract-backed fixture and keep the real integration gate unverified.


## Detailed work sequence

1. Verify predecessor, chapter entry profile, roster, location, time and acquired knowledge before constructing this mission scene/data.
2. Map every listed player action and exit conjunct to an explicit predicate/interaction/evidence owner. Publish this gate map before wiring visuals.
3. Assemble the required rooms/props with current assets, stable anchors and correct physical positions; use shared dialogue/UI/audio services.
4. Implement the three scenes in order; use the relevant shared puzzle stages rather than a second numerical model. A response/inspection choice may converge while its feedback remains distinct.
5. Keep active interaction time substantive through observation, setup, hypothesis-testing, consequences and team communication; fictional days/cruise advance only at accepted gates.
6. Wire exact line IDs, origin/speaker labels, acquired evidence, source boundaries, captions and optional assistance. Apply current English-only/natural plant overrides to any older source label.
7. Test invalid action, partial response, cancel, repeat input, pause, save/load, retry and boundary hand off; preserve authoritative receipts/inventories/actor locations.
8. Run through this mission from its actual predecessor and into its successor, producing a short trace with all gate predicates and the resulting snapshot.


## Task-specific source and implementation detail

### Chapter contract

Chapter 4:**Into the Cold Trap**; dates: 21 October-12 December 2046, with dated return and relief-flight gates; chapter target: 90 minutes.

The crew tests the old trait prediction, sends Rafi and Kai on a safely budgeted ridge expedition and keeps Mei and Amara at base. Calibrated ice evidence leads to a sealed vault recovery. Twelve distinct specimens and a handwritten instruction connect the investigation to Ferreira, whose scheduled arrival sets up the next chapter.

Emotional arc:Curiosity tested -> caution recognised -> field confidence -> preserved discovery -> personal anticipation..

This mission target: 22 active minutes. Predecessor:`EX-M0402`. Successor:`EX-M0404`. Chapter puzzle families: P-07, P-08; reuse their single shared implementations and map the actual relevant stages.

### EX-CH04-S07 — The Lid Can Wait
**Target:**7 minutes. **Location:**Vault recovery work boundary. **POV:**Rafi. **Story time:**2046-10-21 late morning UTC. **Legacy provenance:**`SC-0404`.

Kai can see lettering beneath the lid and asks whether a quick look would save work later. Mei answers from the warm base that the lid can wait. The player checks the outer shell with the provided probe and compares the handling band with the carrier specification. The case's exterior temperature does not reveal the full history of its insulated inner specimens.

The paused recovery study contrasts opening the inner seal now with keeping it closed through insulated transport and sealed warming. Feedback shows why recovery must manage both temperature change and contamination. The game does not teach that every seed can survive any lunar soil temperature. It treats the fictional case as a protected experiment whose viability still needs assessment.

Rafi arranges the probe, sleeve and cradle in the approved sequence. Kai moves the light to make the actual labels readable instead of trying to see hidden text early. The player verifies the equipment before either astronaut lifts. A mystery that began with a drawer now depends on resisting the same impulse to open everything immediately. The crew can bring the question home intact, which is a better achievement than answering it badly in the cold.

**Exact dialogue**

- `EX-CH04-S07-L01` **Kai:** The message is under the lid.
- `EX-CH04-S07-L02` **Mei (local link):** Then the lid can wait.
- `EX-CH04-S07-L03` **Rafi:** Probe, sleeve, cradle. Inner seal stays closed.
- `EX-CH04-S07-L04` **Amara (local link):** Shell temperature is not a complete seed-history record.

**Required player actions**

1. Measure outer case against the carrier handling band.
2. Compare open-now and sealed-recovery handling in the paused study.
3. Prepare the verified probe-sleeve-cradle sequence.

**Decision study and planned feedback**

Which recovery protects the next investigation?
- **Open the biological seal in the field:** The study flags uncontrolled exposure and missing quarantine conditions.
- **Transport closed and warm sealed under controlled conditions:** The next assessment retains the specimen context and contamination boundary.

**Convergence:**Only the sealed recovery sequence is authorised for physical execution..

**Learning loop**

- **Concept:** Handling conditions affect evidence and specimens.
- **Predict:** Does extreme outside cold prove the inner seed history?
- **Observe:** The case insulation record and shell reading answer different questions.
- **Explain:** Do not infer a specimen history from one exterior measurement.
- **Transfer:** Transport a sample in a suitable labelled container before assessing it.

**Mandatory exit condition:**Handling band checked and sealed recovery sequence approved.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_04.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH04-S08 — The Whole Box Comes Home
**Target:**7 minutes. **Location:**Vault cradle, rover cargo mount and local link. **POV:**Kai. **Story time:**2046-10-21 late morning UTC. **Legacy provenance:**`SC-0404`.

The player seats the insulated sleeve before beginning the lift. Rafi and Kai each take the indicated support point, with the carrier tethered and the rover cradle ready. The scene shows the object moving continuously from its deposit position to its secured cargo mount. Kai keeps the handle within the lit work area until the cradle carries its weight and Rafi confirms the restraint.

A latch indicates position with a word and symbol. A second check verifies that the mount is actually locked. The player compares those two results and records the sealed specimen carrier separately from the geological sample. Each object has its own handling needs, even though both will travel in the same vehicle.

Mei asks for the final exterior photograph before the team departs. It records what was removed and what was left undisturbed. Amara checks the revised cargo-and-return forecast, with the two rover occupants still on their own manifest. Kai looks at the closed lid once more, then clips the last tether. They have not been rewarded with a name. They have performed the part of the investigation that makes a trustworthy answer possible later. Rafi calls the base to confirm that the case is travelling home, not that the mystery has been solved.

**Exact dialogue**

- `EX-CH04-S08-L01` **Rafi:** Two supports. Sleeve seated before lift.
- `EX-CH04-S08-L02` **Kai:** Mount shows closed. Testing locked now.
- `EX-CH04-S08-L03` **Mei (local link):** One last context photo, please.
- `EX-CH04-S08-L04` **Amara (local link):** Cargo and return forecast checked. Inner seal remains intact.

**Required player actions**

1. Carry out sleeve, supported lift and continuous cradle transfer.
2. Distinguish latch position from verified locking.
3. Update separate cargo records and return forecast.

**Decision study and planned feedback**

Which cargo result is sufficient for departure?
- **The latch looks closed:** The gate waits for the independent lock check.
- **Latch position and lock test both pass:** The carrier is accepted in the return configuration.

**Convergence:**Departure requires verified restraint, intact inner seal and the supported return forecast..

**Learning loop**

- **Concept:** Indications need functional verification.
- **Predict:** Does a closed-looking latch prove secured cargo?
- **Observe:** Position and lock test provide different evidence.
- **Explain:** A status indication should be checked against its intended function.
- **Transfer:** Test a fastening before relying on its appearance.

**Mandatory exit condition:**Case secured, seal intact, context image saved and return manifest checked.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_04.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH04-S09 — Bring Back the Evidence and the People
**Target:**8 minutes. **Location:**Ridge return route and Aurora airlock. **POV:**Rafi. **Story time:**2046-10-21 through October 22 UTC. **Legacy provenance:**`SC-0404`.

The return uses the same approved ridge, and the player checks the beacon chain from the other direction. A route that worked outbound still needs its return observations. The game selects short meaningful segments around link and reserve checks, with labelled cruise between them rather than empty kilometres of driving.

At each handover, the base team receives a status report containing occupants, cargo, pressure and remaining reserve. Kai notices how much less he has to remember when the report has the same structure every time. Rafi asks Amara to predict the final reserve from the current reading before the last segment resolves. The result is compared with the forecast, not silently overwritten to make the story work.

Aurora receives two returning cadets, a sealed sample and a sealed case on October 22. The forty-eight-hour rover consumables manifest covers this dated round trip. The player finishes the airlock sequence and transfers the vault to the dry quarantine glovebox while the inner seal remains shut. Only now do all four cadets share the same physical room again. Mei rests her hand near the case without touching its lid. Home has made the next question safe to ask.

**Exact dialogue**

- `EX-CH04-S09-L01` **Rafi:** Two returning crew. Two sealed cargo records. Reserve check.
- `EX-CH04-S09-L02` **Kai:** Same report shape. I can remember that.
- `EX-CH04-S09-L03` **Amara (local link):** Prediction saved. Now compare the actual final reading.
- `EX-CH04-S09-L04` **Mei:** Welcome home. The glovebox is ready.

**Required player actions**

1. Verify return beacon chain and supported reserve.
2. Compare predicted and resolved return readings without overwriting evidence.
3. Complete airlock and quarantine transfer within the independent provisions manifest.

**Decision study and planned feedback**

How is a forecast mismatch handled?
- **Replace the prediction with the final reading:** The review rejects loss of the original comparison.
- **Retain prediction and record the resolved value beside it:** The crew can investigate any difference honestly.

**Convergence:**Both studies finish with a supported reserve and unchanged provenance before quarantine handling..

**Learning loop**

- **Concept:** Predictions and actual results must remain distinguishable.
- **Predict:** Should a forecast be rewritten after success?
- **Observe:** The review retains both forecast and result.
- **Explain:** A successful return still provides evidence for improving the model.
- **Transfer:** Keep estimated and actual project use in separate columns.

**Mandatory exit condition:**Both cadets home, return reserve passes and sealed case transferred to dry quarantine.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_04.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.

### Cross-mission continuity
- The Octobertrait sample pays off the May prediction without a guaranteed genetic ratio.
- Rafi and Kai occupy the rover; Mei and Amara stay at base; Ferreira is remote until December 12.
- Canonical route B returns 40 against a required 30; all three beacons are tested before blind corners.
- Scanner reference 2, threshold 12 and sample signals 2/18/19 are explicitly tagged game-profile values.
- The vault remains sealed through transport and controlled warming. Its 12 specimens are physical inventory, distinct from album entries.
- Cotton is identified but not planted here; its December 15 planting leaves 11 other vault specimens stored.
- No identification of N., survival announcement or Academy-founder reveal occurs before Chapter 5.
- October-to-December care, scheduled resupply and the December 8-12 flight are explicit.

### Production constraints
- Use hard black shadows and cabin, suit or contact audio; no airborne vacuum wind or fog.
- Maintain separate base and field viewpoints and occupant ledgers.
- Show continuous case handling and readable labels, with no unexplained object relocation.
- All 90 minutes are mandatory investigation, planning, field checks and recovery; cruise is transitioned rather than padded.

### Chapter bridge
Ferreira arrives December 12 on her planned relief flight. Chapter 5 can reveal an identity and history after the evidence-supported personal inquiry.


## Required deliverables

- Editable source and actual runtime deliverables in the established project layout.
- A bounded integration fixture or owning-scene hookup, with exact resource/API paths and stable IDs.
- Meaningful task-specific checks, actual execution results and visual/audio evidence where required.
- Updated affected manifests/provenance, and a precise handoff for the next dependent owner.


## Acceptance — demonstrate every applicable item

- Exactly the quoted three final scene IDs complete once before the next mission unlocks.
- Every required action has actual gameplay and observable feedback; a film/dialogue click does not replace it.
- Exit predicates, learning evidence, roster, time, knowledge and numeric state agree with canon.
- The mission integrates with the previous/next mission under a validated save/checkpoint, not a disconnected devdemo.
- Pause, cancellation, duplicate input and save/reload preserve a coherent authoritative state where this task is interactive.
- English captions/text, named icons and assisted input preserve all essential information and story access.
- No unlogged generation, unsupported measured claim, new paid tool, secret, unrelated change or unrequested commit/push.


## Completion report

Use `05_ACCEPTANCE_AND_HANDOFF.md`. Record current HEAD, exact files, input revisions, commands and actual outcomes; identify current versus historical evidence. Mark unexecuted checks explicitly. Update production status only after the concrete deliverables pass the applicable gate. Do not count this prompt file itself as completed implementation.
