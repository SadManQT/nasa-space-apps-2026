# EX-M0503 — A Moon That Keeps Records

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Mandatory mission.**



## Assignment

Verify observations, maintain systems and bound claims. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.

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

Prerequisite `EX-M0502`; SYS02..08; chapter puzzles P-09, P-10; owning location/asset/UI tasks. If a service is not ready, coordinate one contract-backed fixture and keep the real integration gate unverified.


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

This mission target: 25 active minutes. Predecessor:`EX-M0502`. Successor:`EX-M0504`. Chapter puzzle families: P-09, P-10; reuse their single shared implementations and map the actual relevant stages.

### EX-CH05-S07 — Stars Without Streaks
**Target:**8 minutes. **Location:**Aurora impact-camera monitor. **POV:**Rafi. **Story time:**14 December, night observation. **Legacy provenance:**`SC-0504`.

Kai asks where the shooting stars are. The monitor shows a dark plain and small flashes enlarged for inspection. There are no atmospheric trails above the surface. Rafi hands the player a frame-based observation log. Nobody must rush outside for a better view.

The first candidate stays at the same detector coordinate across several frames. Another appears briefly at a mapped surface location with a distinct onset. The player inspects neighbouring frames before classifying either. Amara requests a reason beside every accepted event; a lucky click cannot become a scientific report. Six genuine flashes must be verified in the teaching sequence, while two fixed artifacts are rejected.

As the list grows, the plain seems less empty. Mei says the Moon keeps marks too small to notice from their window. Ferreira reminds her that this is an amplified instrument view, not naked-eye fireworks. The player saves the sixth supported event and carries the observation clock into maintenance. Wonder has supplied a reason to look carefully, not permission to overstate what appeared.

**Exact dialogue**

- `EX-CH05-S07-L01` **Kai:** No trails?
- `EX-CH05-S07-L02` **Amara:** Not like meteors crossing Earth's air.
- `EX-CH05-S07-L03` **Rafi:** Check the frame before and after.
- `EX-CH05-S07-L04` **Mei:** A tiny flash can leave a mark.

**Required player actions**

1. Inspect candidate frames.
2. Reject two detector artifacts.
3. Log six supported genuine flashes.

**Decision study and planned feedback**

Which candidate belongs in the confirmed impact count?
- **The persistent detector-coordinate point:** Neighbouring frames expose a fixed artifact; it is rejected from the count.
- **The transient mapped-surface flash:** Onset and adjacent frames support an event; confirm it with the recorded evidence.

**Convergence:**Six genuine flashes and two rejected artifacts are needed, with reasons..

**Learning loop**

- **Concept:** Observation and artifacts
- **Predict:** Is every bright pixel an impact?
- **Observe:** Compare onset, persistence and position.
- **Explain:** Instrument artifacts can resemble real events.
- **Transfer:** Keep uncertain observations distinct from confirmed ones.

**Mandatory exit condition:**Six genuine flashes verified and both artifacts rejected.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_05.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH05-S08 — Dust Has a Cost
**Target:**9 minutes. **Location:**Maintenance console and isolated garden spur. **POV:**Amara. **Story time:**14 December, scheduled maintenance. **Legacy provenance:**`SC-0504`.

The observation report is ready, but Amara does not let a completed screen become a completed watch. A panel trend shows less output than its reference. A separate pressure trace suggests a small isolated branch leak. The player separates the observations first; one convenient explanation cannot account for every change.

Neither of the protective upgrades offered after this chapter has been earned yet. Scheduled cleaning must restore the panel's teaching profile, and the player must isolate and patch the damaged garden spur. A pressure-safe procedure keeps the living enclosure closed. The player predicts which trace each repair should change, then compares independent before-and-after records. A correct patch cannot be credited for an unrelated energy improvement.

Mei watches through the sealed enclosure. Nobody opens a greenhouse to vacuum to wipe a leaf. Kai jokes about dust keeping a diary, then labels the trends correctly. The crew earns a later choice of Dust Shield or Whipple protection because it now understands both failure mechanisms. Future equipment will change future maintenance; it cannot retroactively perform today's work.

**Exact dialogue**

- `EX-CH05-S08-L01` **Amara:** Two symptoms. Check their causes separately.
- `EX-CH05-S08-L02` **Kai:** The dust kept a diary.
- `EX-CH05-S08-L03` **Mei:** Read it after the pressure check.
- `EX-CH05-S08-L04` **Ferreira:** Protection changes the job, not the check.

**Required player actions**

1. Predict which fault explains each independent trace.
2. Carry out the scheduled safe panel-cleaning procedure.
3. Isolate, patch and pressure-test the garden spur.

**Decision study and planned feedback**

Which explanation should be tested for the pressure trend?
- **Dust on the panel reduces pressure:** Panel cleaning changes output but not the isolated leak; the separate branch test is required.
- **The isolated spur has a small leak:** The branch test localises the leak; patch and retest it before committing.

**Convergence:**Both cleaning and isolated patch must pass their independent measurements..

**Learning loop**

- **Concept:** Controlled maintenance comparison
- **Predict:** Could one fault explain both trends?
- **Observe:** Compare independent before-and-after records.
- **Explain:** A repair needs a measurement relevant to its purpose.
- **Transfer:** Check what a maintenance action actually changed.

**Mandatory exit condition:**Both repairs verified by relevant measurements; protection upgrade not owned until chapter completion.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_05.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH05-S09 — What the Flashes Cannot Prove
**Target:**8 minutes. **Location:**Aurora evidence table. **POV:**Rafi. **Story time:**14 December, after maintenance. **Legacy provenance:**`SC-0504`.

Rafi places tonight's observation record beside Expedition Zero's damage report. Their dates differ, and he leaves them that way. It is tempting to make an impressive flash explain the broken relay twelve years earlier. The player can draw a line only where the evidence supports one.

The same kind of hazard explains why impact monitoring matters. It cannot establish that a specific old fault was caused by an impact, particularly when the original report describes relay failure and degraded power hardware without a verified strike. The player moves that strong claim to unsupported. Its correction stays visible in the debrief so the missing connection has a reason.

Ferreira smiles at a report containing a blank. It is the first empty space all evening that makes her feel better. Rafi saves the report without apology. Candidate frames, maintenance traces and archive chronology now form one complete investigation: observe, test, explain the limits. The player carries that discipline into the identity question. A familiar initial can be a clue. A signed page must finish the proof.

**Exact dialogue**

- `EX-CH05-S09-L01` **Rafi:** Tonight's flashes do not date the old fault.
- `EX-CH05-S09-L02` **Amara:** That blank is an honest result.
- `EX-CH05-S09-L03` **Ferreira:** Leave it blank until we know.
- `EX-CH05-S09-L04` **Mei:** An initial leads us. A record finishes it.

**Required player actions**

1. Separate direct and contextual evidence.
2. Reject the unsupported old-impact claim.
3. Save an explicitly bounded conclusion.

**Decision study and planned feedback**

Choose a supported report conclusion.
- **Impacts are monitored hazards:** It explains today's instrument work.
- **The old fault needs its own evidence:** It protects the archive from a false cause.

**Convergence:**Complete report excludes the unsupported historical impact claim..

**Learning loop**

- **Concept:** Causation and context
- **Predict:** Does a similar hazard establish a past cause?
- **Observe:** Compare original reports and distinct dates.
- **Explain:** Plausible mechanisms do not replace case-specific evidence.
- **Transfer:** Avoid making a coincidence into a confident cause.

**Mandatory exit condition:**Complete report excludes the unsupported historical impact claim.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_05.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.

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
