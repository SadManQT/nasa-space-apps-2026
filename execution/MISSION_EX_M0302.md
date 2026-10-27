# EX-M0302 — Repair Before Discovery

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Mandatory mission.**



## Assignment

Verify the service repair, reconcile records and inspect the known annex by camera. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.

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

Own this mission's scene composition/content bindings and targeted integration tests; proposed root `game/scenes/chapters/ch03/`. Shared state, simulation, UI and characters remain owned by their SYS/UI/ASSET tasks.

Prerequisite `EX-M0301`; SYS02..08; chapter puzzles P-05, P-06; owning location/asset/UI tasks. If a service is not ready, coordinate one contract-backed fixture and keep the real integration gate unverified.


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

Chapter 3:**Moon quake**; dates: 6 May-21 October 2046, with explicit repair, harvest and generation gates; chapter target: 85 minutes.

The crew localises and repairs a quake-damaged service spur, safely investigates an old seedling annex, verifies a future vault map and completes Alo harvest. Exactly 42 founder seeds become 12 planting plus 30 reserve, followed by a documented multi-generation care bridge.

Emotional arc:Alarm -> uncertainty admitted -> evidence-based control -> discovery -> grief -> continuation..

This mission target: 21 active minutes. Predecessor:`EX-M0301`. Successor:`EX-M0303`. Chapter puzzle families: P-05, P-06; reuse their single shared implementations and map the actual relevant stages.

### EX-CH03-S04 — The Clamp and the Read-Back
**Target:**7 minutes. **Location:**Garden service spur. **POV:**Kai. **Story time:**2046-05-06 night through May 07 early hours UTC. **Legacy provenance:**`SC-0302`.

Kai holds the approved sequence beside the physical labels. Amara reads each step back from the safe console while Rafi confirms that no one has crossed into the isolated work area. The player closes the garden spur, checks the mechanical pressure hold and seats the provided clamp through the authorised interface.

The repair has more than an installation animation. The player checks position, compares the gauge trend and reopens the line slowly under the scripted test profile. If the profile does not hold in the practice comparison, the interface returns to the diagnostic boundary rather than rewarding a completed hand movement. A clamp is useful because the verified system response changes.

Mei watches the plant-chamber record throughout. The chamber remained supported locally while the room branch was isolated, and its status is checked again before normal tending resumes. Kai wants to straighten a crooked label. Amara asks him to leave the evidence visible until the test is saved. For once, a slightly untidy room is a sign of careful work. The player restores the approved service configuration only after the hold check agrees with the independent gauge, and the crew can explain which part of the problem has actually been solved.

**Exact dialogue**

- `EX-CH03-S04-L01` **Kai:** Clamp seated. That is not the same as verified.
- `EX-CH03-S04-L02` **Amara:** Hold test first. Then controlled reopening.
- `EX-CH03-S04-L03` **Rafi:** Work boundary clear.
- `EX-CH03-S04-L04` **Mei:** Local chamber stable. I will check it again after service returns.

**Required player actions**

1. Execute supported isolation and clamp placement.
2. Run independent hold and controlled-reopening tests.
3. Verify both room service and local plant condition.

**Decision study and planned feedback**

Which evidence is sufficient to reopen?
- **The clamp animation completed:** The test rejects this as incomplete; position alone cannot prove a sealed line.
- **The mechanical hold and controlled trend agree:** The verified profile supports the approved reopening sequence.

**Convergence:**Both views require actual pressure evidence before service restoration..

**Learning loop**

- **Concept:** A completed action is not a verified repair.
- **Predict:** Can visual placement prove a seal?
- **Observe:** The hold test can distinguish seating from successful function.
- **Explain:** Verification measures the intended result.
- **Transfer:** After fixing a model or circuit, test its function rather than only its appearance.

**Mandatory exit condition:**P-05 repair sequence completes with independent hold and controlled reopening verified.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_03.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH03-S05 — Five Checks Before a Quiet Room
**Target:**7 minutes. **Location:**Atmosphere console and restored garden spur. **POV:**Amara. **Story time:**2046-05-07 before dawn UTC. **Legacy provenance:**`SC-0302`.

The repaired line produces an ordinary-looking graph. Amara refuses to call ordinary the same as unimportant. The player performs the five canonical checks, connecting each result to a service boundary or independent observation. The task is to show stability, not to keep clicking until a celebration appears.

Rafi asks another crew member to read the final sequence without Amara prompting. Kai finds a mismatch between a copied note and the current valve position. The player corrects the note, not the physical state that has already passed its test. This is a deliberate distinction between fixing documentation and undoing a sound repair. Mei records the garden's return to normal service.

The immediate repair is verified before the chapter moves into the following morning. Extended monitoring will continue into May 8, while nonhazardous camera investigation becomes possible on May 7. The handover grants camera-only annex inspection for May 7 and keeps suited entry pending the extended checks on May 8. When the warning clears, Amara leaves the independent gauge on its hook. She has learned a repeatable way to ask a good question, not a reason to distrust every screen forever.

**Exact dialogue**

- `EX-CH03-S05-L01` **Amara:** Five checks. We keep the evidence even after the warning clears.
- `EX-CH03-S05-L02` **Kai:** The note is wrong. The tested valve position is right.
- `EX-CH03-S05-L03` **Rafi:** Then correct the note. Do not create a new fault to match it.
- `EX-CH03-S05-L04` **Mei:** Garden service restored. Monitoring continues.

**Required player actions**

1. Complete five P-05 verification checks.
2. Reconcile documentation with the tested physical state.
3. Record immediate repair approval and continuing monitoring separately.

**Decision study and planned feedback**

What should change when the note conflicts with a passed test?
- **Change the valve to match the copied note:** The preview flags reversal of the supported safe state.
- **Correct the copied note using verified evidence:** The service state remains safe and the record becomes accurate.

**Convergence:**The tested configuration is retained; documentation is corrected and signed..

**Learning loop**

- **Concept:** Records and systems must agree with verified evidence.
- **Predict:** Should a copied note outrank a passed independent test?
- **Observe:** The mismatch has a traceable documentary cause.
- **Explain:** Documentation errors should be corrected without undoing a verified repair.
- **Transfer:** Check whether a mismatch is in the model, the record or the real system.

**Mandatory exit condition:**Five checks passed, records reconciled and monitoring handover saved.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_03.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH03-S06 — A Door We Knew Was There
**Target:**7 minutes. **Location:**Isolated annex viewing port. **POV:**Rafi. **Story time:**2046-05-07 morning UTC. **Legacy provenance:**`SC-0303`.

A displaced floor cover exposes the service hatch marked N.R. The annex was on the station's certified plan all along, isolated and nonessential. What the quake has revealed is an old access surface and its personal traces, not an entire unmapped room under a supposedly checked habitat.

The player matches the hatch to the supplied safety drawing, disconnects its utility feed and verifies the pressure boundary before opening a viewing port. A camera goes first. Physical entry is a separate later operation with suits and further clearance. The view shows tray silhouettes, a damaged growth chart and an old route marker under clear cover.

Ferreira provides technical context over the valid Earth path. An earlier trial ended before flowering, and the annex must be treated as an isolated service space. She does not yet confess her own role or identify the writer. Mei wants to move closer, but Rafi holds the camera steady until the required checks finish. His hands stay on the camera controls while the final boundary reading settles. Mei moves closer only when he turns the supported view towards her. The player saves the view and closes the port, knowing exactly what must happen before anyone may step through.

**Exact dialogue**

- `EX-CH03-S06-L01` **Mei:** N.R. The same mystery on a real door.
- `EX-CH03-S06-L02` **Rafi:** A viewing port first. Our feet can wait.
- `EX-CH03-S06-L03` **Ferreira (Earth link):** An isolated annex. Use the supplied boundary checks.
- `EX-CH03-S06-L04` **Amara:** Safe to inspect is not yet cleared to enter.

**Required player actions**

1. Match hatch to the known plan.
2. Isolate utility feed and confirm pressure boundary.
3. Use the camera port and save evidence without physical entry.

**Decision study and planned feedback**

How should the annex be investigated now?
- **Camera through the cleared viewing port:** The crew obtains evidence within the current safety clearance.
- **Immediate physical entry:** The gate refuses entry because the suited operation is not yet cleared.

**Convergence:**The camera record is saved; physical entry remains scheduled for May 8 after additional checks..

**Learning loop**

- **Concept:** Discovery does not replace access control.
- **Predict:** Does a visible room become safe to enter?
- **Observe:** Inspection and entry have different clearances.
- **Explain:** Knowledge of a hazard and permission to enter it are separate.
- **Transfer:** Use the least intrusive supported observation before disturbing an unfamiliar system.

**Mandatory exit condition:**Feed isolated, boundary verified and camera inspection saved; no physical entry yet.
**Evidence boundary:**Fiction. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_03.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.

### Cross-mission continuity
- Immediate repair passes by May 7 dawn; safe camera viewing follows May 7; extended checks precede suited entry May 8.
- Ferreira supplies safety information without a premature personal confession or identification of N.
- The 2034 annex contains young, unflowered seedlings with curled leaves only: no flower buds, flowers, pollination or seed production.
- Maturity is checked May 16, followed by a controlled five-day dry-down and May 21 harvest: exactly 42=12+30.
- The later garden contains descendants; the original Alo never revives.
- The May-to-Octobertransition explicitly covers care, repeated compatible pollination, generation changes, maintenance and scheduled supplies.

### Production constraints
- Use a paused diagnostic copy for contrasting hypotheses before physical intervention.
- Keep annex entry boundary and separate support positions visible.
- Treat natural plant maturity quietly; no collapse or resurrection spectacle.
- All 85 minutes are mandatory linked play. The May-to-Octoberbridge uses distinct observation and planning checks rather than idle waiting.

### Chapter bridge
On October 21 the current descendants are ready for the saved trait comparison, and Rafi must turn an old map into a safe two-person field mission.


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
