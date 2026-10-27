# EX-M0203 — Make an Old Record Useful

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Mandatory mission.**



## Assignment

Respect biological timing, collect provenance and reconstruct the recorder copy. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.

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

Own this mission's scene composition/content bindings and targeted integration tests; proposed root `game/scenes/chapters/ch02/`. Shared state, simulation, UI and characters remain owned by their SYS/UI/ASSET tasks.

Prerequisite `EX-M0202`; SYS02..08; chapter puzzles P-03, P-04; owning location/asset/UI tasks. If a service is not ready, coordinate one contract-backed fixture and keep the real integration gate unverified.


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

Chapter 2:**Be the Bee**; dates: 30 April-6 May 2046; authored UTC chronology; chapter target: 75 minutes.

Tara flowers as Earth contact returns. The crew carries out three sealed reciprocal pollen runs across seven care days, records a testable inheritance prediction and reconstructs an older horticulture recording. The evening ends with a quake.

Emotional arc:Recognition -> patient precision -> curiosity -> tentative personal connection -> decisive reprioritising..

This mission target: 18 active minutes. Predecessor:`EX-M0202`. Successor:`EX-M0204`. Chapter puzzle families: P-03, P-04; reuse their single shared implementations and map the actual relevant stages.

### EX-CH02-S07 — Not Tomorrow's Seeds
**Target:**6 minutes. **Location:**Aurora mission table. **POV:**Mei. **Story time:**2046-05-06 afternoon UTC. **Legacy provenance:**`SC-0203`.

Kai puts a clean seed tray beside the care strip and asks whether tomorrow is harvest day. Amara says no before he finishes drawing the label. Mei brings up the growth sequence: flowers, developing pods, mature pods, drying and harvest. The player matches each stage to an observation instead of moving a calendar slider until the answer appears.

One image shows a young, unflowered seedling with curled leaves from the old trial. Another shows their current pollinated flower. A third is a reference illustration of mature pods. The task is to explain which image belongs to which stage and which evidence the crew does not yet possess. The sequence gives a practical reason to continue care without turning waiting into compulsory idle play.

Rafi places the paper bee beside the finished record. Its folded wing brushes the horticulture recorder and exposes a familiar equipment number. The player notices that the recorder and an old trial card share an identifier. This is a physical link, not a guess about a person's initials. Mei saves the life-cycle entry before opening the service label. Their next investigation begins because they have learned to look closely at their ordinary tools, while the living experiment continues at its own pace.

**Exact dialogue**

- `EX-CH02-S07-L01` **Kai:** Seeds tomorrow?
- `EX-CH02-S07-L02` **Amara:** No. Not the day after either.
- `EX-CH02-S07-L03` **Mei:** We keep caring. We do not pull a plant into the future.
- `EX-CH02-S07-L04` **Rafi:** This equipment number matches the old trial card.

**Required player actions**

1. Order flower-to-harvest stages using observations.
2. Mark which evidence is current and which is only a reference illustration.
3. Inspect the recorder identifier and save the pollination entry.

**Decision study and planned feedback**

How is the life cycle explained?
- **Arrange stage images:** Visible changes establish the order.
- **Arrange evidence statements:** The player explains why each stage is supported.

**Convergence:**Both keep harvest later than pod maturity and dry-down..

**Learning loop**

- **Concept:** Biological stages cannot be skipped by a successful interaction.
- **Predict:** Does pollination prove harvest is ready?
- **Observe:** Current flowers differ from mature and dry pods.
- **Explain:** Processes have observable stages and limits.
- **Transfer:** Check maturity evidence rather than assuming a fixed task completion means readiness.

**Mandatory exit condition:**Life-cycle entry complete and recorder identifier linked to the trial card.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_02.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH02-S08 — A Label Under a Label
**Target:**6 minutes. **Location:**Recorder service bench. **POV:**Kai. **Story time:**2046-05-06 late afternoon UTC. **Legacy provenance:**`SC-0204`.

A lifted corner on the recorder's newer service sticker reveals part of an older plate. Kai almost peels it back. Mei hands him the camera instead. They need the information without destroying the original surface, because a good mystery can survive careful handling.

The player photographs the serial plate, maintenance date and trial-stage chart, then places copies on the evidence board. Each card carries its source object and uncertainty. The older chart states that the reproductive stage was not reached. Alo's bloom therefore does not become a false achievement when an earlier plant trial is discovered. The old experiment had seedlings; their own experiment has flowers.

Amara asks the team to separate three questions: which device is this, when was it used, and what stage did the trial reach? Matching a number answers the first, not all three. The player can inspect a tempting unsupported card naming a possible owner, but it remains excluded until evidence exists. The final board leaves a clean empty space where a person might later belong. The mystery grows stronger because the team knows exactly what it knows and has not filled the rest with a confident story.

**Exact dialogue**

- `EX-CH02-S08-L01` **Kai:** Someone put the newer label over the older one.
- `EX-CH02-S08-L02` **Mei:** Photograph it. Do not peel the only original.
- `EX-CH02-S08-L03` **Amara:** A device match is not a person’s name.
- `EX-CH02-S08-L04` **Rafi:** And a seedling record is not a previous flower.

**Required player actions**

1. Photograph serial plate, date and trial chart.
2. Attach each evidence copy to its source.
3. Separate supported device and trial claims from unsupported identity claims.

**Decision study and planned feedback**

What conclusion is supported by the old trial-stage chart?
- **An earlier flowering garden makes Alo first bloom false:** The chart and young-seedling record contradict this claim; the player must narrow the interpretation.
- **An earlier trial stopped before flowering:** The chart supports the limited seedling-stage account without erasing Alo and Tara current achievement.

**Convergence:**The reconstruction board accepts only the evidence-supported stage and leaves personal identity unanswered..

**Learning loop**

- **Concept:** Provenance constrains interpretation.
- **Predict:** Does one matching detail prove the whole story?
- **Observe:** Device, date and trial-stage claims require separate evidence.
- **Explain:** Evidence has a scope; related claims can remain unknown.
- **Transfer:** When researching, keep a source attached to each claim.

**Mandatory exit condition:**Three source cards collected without damage and unsupported identity excluded.
**Evidence boundary:**Fiction. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_02.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH02-S09 — The File That Belongs Here
**Target:**6 minutes. **Location:**Local evidence reconstruction board. **POV:**Amara. **Story time:**2046-05-06 early evening UTC. **Legacy provenance:**`SC-0205`.

Three recorder files have fields in the wrong places: date, device identifier and voice channel. Amara asks the player to reconstruct the mapping using the physical evidence just collected. Nothing requires guessing a password or recognising a face the player has never seen.

The correct date connects the record to 2034. The correct identifier connects it to the horticulture recorder. The channel assignment separates an engineering instruction from a gardener's personal note. A checksum confirmation tests that the restored copy is internally intact; it does not certify every historical interpretation. The original remains untouched while the player works on a local copy.

Kai proposes naming the file after the person he thinks he hears. Mei chooses the equipment label instead. The anonymous voices will be heard once the mapping is supported, not once the team invents the most dramatic explanation. Rafi reads the reconstruction steps aloud so a second crew member could repeat them. When the playback button becomes available, the player has earned access by making evidence usable. The reward is not a solved identity. It is a reliable fragment with a date, a source and a clear limit on what it can tell them.

**Exact dialogue**

- `EX-CH02-S09-L01` **Amara:** Date, device, channel. Each gets one supported match.
- `EX-CH02-S09-L02` **Kai:** Can I name the file after my guess?
- `EX-CH02-S09-L03` **Mei:** Name it after the evidence first.
- `EX-CH02-S09-L04` **Rafi:** I can repeat these steps. That is a good sign.

**Required player actions**

1. Match date, device and channel using source cards.
2. Check the reconstructed copy while preserving the original.
3. Write an evidence-based file label and replayable reconstruction steps.

**Decision study and planned feedback**

Which reconstruction view is used?
- **Card matching:** Relationships are shown spatially.
- **Accessible table:** The same relationships are read row by row.

**Convergence:**Both produce the identical verified local copy..

**Learning loop**

- **Concept:** Reconstruction should be repeatable and bounded.
- **Predict:** What does an intact file prove?
- **Observe:** It supports reliable playback, not automatic identity.
- **Explain:** Technical validation and interpretation are separate claims.
- **Transfer:** Keep original data and explain transformations when analysing a file.

**Mandatory exit condition:**P-04 metadata mapping validated and intact local copy ready.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_02.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.

### Cross-mission continuity
- Earth contact returns April 30, not at the earlier first bloom.
- Three reciprocal cycles occur April 30,May 3,May 6; all seven care dates are logged.
- Whole-cycle route costs apply once; sealed transfers never expose flowers to vacuum.
- Stem prediction is retained for the Chapter 4 observation, without promised genotype ratio.
- N. remains anonymous; engineer resemblance is an inference; no death is invented.
- Quake at May 6 22:00 leads directly to Chapter 3.

### Production constraints
- Give Tara equal visual and record status.
- Use magnification, labels and shapes together for flower structures.
- Keep original media provenance visible in archive playback.
- All 75 minutes are required authored play, with dates advanced explicitly rather than by idle waiting.

### Chapter bridge
No date jump follows the quake. The four accounted-for cadets begin testing the changed pressure warning at 22:05.


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
