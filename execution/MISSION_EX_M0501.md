# EX-M0501 — The Engineer Comes Home

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Mandatory mission.**



## Assignment

Welcome Ferreira and reconstruct the evacuation. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.

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

Own this mission's scene composition/content bindings and targeted integration tests; proposed root `game/scenes/chapters/ch05/`. Shared state, simulation, UI and characters remain owned by their SYS/UI/ASSET tasks.

Prerequisite `EX-M0404`; SYS02..08; chapter puzzles P-09, P-10; owning location/asset/UI tasks. If a service is not ready, coordinate one contract-backed fixture and keep the real integration gate unverified.


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

Chapter 5:**Shooting Stars**; dates: 12–15 December 2046; chapter target: 85 minutes.

A physical handover leads to an investigation of Expedition Zero, accountable conversation, impact observation and maintenance. Consented records identify Noor as the living Academy founder. A respectful invitation leads to cotton planting and carefully separated seed ledgers.

Emotional arc:Anticipation → discomfort → accountability → wonder → connection..

This mission target: 20 active minutes. Predecessor:`EX-M0404`. Successor:`EX-M0502`. Chapter puzzle families: P-09, P-10; reuse their single shared implementations and map the actual relevant stages.

### EX-CH05-S01 — The Fifth Mug
**Target:**6 minutes. **Location:**Landing camera and airlock. **POV:**Rafi. **Story time:**12 December 2046, scheduled arrival. **Legacy provenance:**`SC-0501`.

The fifth mug has spent months clipped above the table. Kai polished it once and denied doing so. Now its owner is a small moving shape on the landing camera, waiting beside relief cargo until the pad is declared clear. The player stands with Rafi at the inner airlock control. A greeting is ready, but the open command waits for two agreeing checks.

Ferreira gives her name as if this were any other handover. Rafi asks her to repeat the seal indication. She does, without a joke about rank. Beyond the camera frame, the lander's dust has settled; nothing outside billows like smoke. Cargo passes through the transfer procedure before anyone removes a glove.

Inside, Ferreira reaches for a chair, sees the four cadets waiting, and takes the corridor watch instead. The player carries her mug to the table. The commander who used to be a voice has weight, tired shoulders and a place to sleep. Aurora must now support five people, and its next ledger must say so.

**Exact dialogue**

- `EX-CH05-S01-L01` **Rafi:** Name and seal indication, please.
- `EX-CH05-S01-L02` **Ferreira:** Ferreira. Seal indication checked twice.
- `EX-CH05-S01-L03` **Kai:** Your mug passed inspection.
- `EX-CH05-S01-L04` **Amara:** We are revising the occupancy ledger.

**Required player actions**

1. Compare landing-clear indicators.
2. Verify cargo seals before entry.
3. Add Ferreira to the five-person roster.

**Decision study and planned feedback**

Which occupancy forecast can safely be committed after Ferreira arrives?
- **Keep the four-person forecast:** The preview shows the fifth person's demand omitted; revise before committing.
- **Recompute for five occupants:** The forecast includes the new occupant and passes the roster check.

**Convergence:**Five-person demand must reconcile before the entry handover is committed..

**Learning loop**

- **Concept:** Handover and occupancy
- **Predict:** What changes with a fifth person?
- **Observe:** Compare the two occupancy ledgers.
- **Explain:** More people change consumption even in an unchanged habitat.
- **Transfer:** Count people before budgeting shared supplies.

**Mandatory exit condition:**Clearance, seals and five-person roster verified.
**Evidence boundary:**Fiction. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_05.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH05-S02 — The Watch She Takes
**Target:**7 minutes. **Location:**Aurora corridor and atmosphere panel. **POV:**Amara. **Story time:**12 December, after arrival. **Legacy provenance:**`SC-0501`.

Ferreira's first watch is uneventful, which makes Amara suspicious. On Earth, the commander always seemed to arrive at the moment a warning sounded. Here she checks a label, writes the time and waits for the next reading. The player follows her through the corridor that felt unfamiliar in April.

A replacement relay controller sits in a sealed crate. Rafi reads its serial against the received manifest; Kai checks that the service diagram is stored locally. The spare does not fix anything simply by arriving. It needs a compatible housing, an isolation procedure and a crew who know where it is. They put those facts on the inventory board.

At the atmosphere panel, Amara finds a handwritten correction she made months earlier. Ferreira asks why it remains visible. Amara says the old number was wrong. The player compares the second gauge and signs the current reading. The panel becomes evidence of a checked mistake rather than embarrassment. Their meal begins after the handover, not after an invented emergency.

**Exact dialogue**

- `EX-CH05-S02-L01` **Ferreira:** A good watch can be quiet.
- `EX-CH05-S02-L02` **Amara:** Quiet still needs a record.
- `EX-CH05-S02-L03` **Rafi:** Controller serial matches the manifest.
- `EX-CH05-S02-L04` **Kai:** The instructions stay here without Earth.

**Required player actions**

1. Match controller serial and service specification.
2. Save its procedure locally.
3. Reconcile independent atmosphere readings.

**Decision study and planned feedback**

How should the corrected label look?
- **Keep the correction visible:** Its date and reason remain beside the value.
- **Use a dated overlay:** The earlier reading remains in the log.

**Convergence:**Spare stored once, procedure available locally, readings reconciled..

**Learning loop**

- **Concept:** Traceable correction
- **Predict:** Would a confident label prove correctness?
- **Observe:** Compare two readings and a dated revision.
- **Explain:** A correction is useful when its reason is visible.
- **Transfer:** Keep an audit trail when changing a shared plan.

**Mandatory exit condition:**Spare stored once, procedure available locally, readings reconciled.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_05.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH05-S03 — The Order We Left In
**Target:**7 minutes. **Location:**Aurora mission table. **POV:**Amara. **Story time:**14 December, afternoon. **Legacy provenance:**`SC-0502`.

Four records wait under transparent weights: a relay fault report, a greenhouse service note, an evacuation order and an ascent manifest. Ferreira puts them down without arranging them. She asks the player to reconstruct the order before asking what she remembers. The task begins with timestamps and signatures, not an accusation.

One note describes a power connector already degraded. Another records the relay failure. The player distinguishes a condition from the moment it became dangerous. A photograph of frozen trays supplies a consequence but cannot date the original fault. Wrong placements remain visible long enough for their contradiction to be understood; correcting them costs no survival resource.

The ascent manifest supplies the final check. Every listed crew member boarded. The player compares the roster with the boarding record instead of inferring a death from a sad photograph. Rafi exhales before anyone speaks. An unanswered question about the seeds remains, but it has changed shape. The mystery concerns what people carried home and what they hoped someone might find later.

**Exact dialogue**

- `EX-CH05-S03-L01` **Ferreira:** First the records. Then my memories.
- `EX-CH05-S03-L02` **Amara:** A condition is not the failure time.
- `EX-CH05-S03-L03` **Rafi:** Every name has a boarding mark.
- `EX-CH05-S03-L04` **Mei:** The garden was left. The gardener was not.

**Required player actions**

1. Order the four primary records.
2. Separate earlier degradation from the incident.
3. Match roster and boarding signatures.

**Decision study and planned feedback**

What settles the boarding question?
- **Compare manifest and roster:** Every crew member is accounted for directly.
- **Read the departure summary:** Its conclusion is checked against the same roster.

**Convergence:**Supported sequence and all-crew-returned conclusion committed..

**Learning loop**

- **Concept:** Chronology and evidence
- **Predict:** Does damage reveal its own date?
- **Observe:** Compare timestamps and boarding records.
- **Explain:** Sequence constrains an explanation without proving every cause.
- **Transfer:** Use records before making a dramatic inference.

**Mandatory exit condition:**Supported sequence and all-crew-returned conclusion committed.
**Evidence boundary:**Fiction. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_05.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.

### Cross-mission continuity
- Ferreira arrives Dec 12; Rao and Noor remain on Earth.
- Noor is identified here; no live Noor voice before CH08.
- Cotton 1 planted +11 vault specimens retained; founder reserve 30 separate.
- Alo remains a petal and lineage, never resurrected.
- Dust Shield/Whipple pair is earned only after CH05; the chapter's cleaning and patching remain mandatory.
- The 2034 trays contain young unflowered seedlings and curled leaves only; no flower buds or reproductive development.

### Production constraints
- Camera-monitored safe landing.
- Amplified impact flashes without meteor trails.
- Correct stale source count to eleven retained specimens.
- All twelve scenes are required; each has a player evidence gate.
- The impact classification sequence is authored teaching content; do not label its individual flashes as imported historical observations without an actual dataset.

### Chapter bridge
Dated cotton care and a five-person handover lead to January's eclipse.


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
