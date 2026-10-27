# EX-M0204 — Hear, Ask and Re prior it is e

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Mandatory mission.**



## Assignment

Interpret the archive honestly, send evidence and respond safely to the quake. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.

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

Prerequisite `EX-M0203`; SYS02..08; chapter puzzles P-03, P-04; owning location/asset/UI tasks. If a service is not ready, coordinate one contract-backed fixture and keep the real integration gate unverified.


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

This mission target: 21 active minutes. Predecessor:`EX-M0203`. Successor:`EX-M0301`. Chapter puzzle families: P-03, P-04; reuse their single shared implementations and map the actual relevant stages.

### EX-CH02-S10 — A Voice With Younger Edges
**Target:**7 minutes. **Location:**Recorder playback station. **POV:**Mei. **Story time:**2046-05-06 evening UTC. **Legacy provenance:**`SC-0205`.

The restored engineering voice orders a safe retreat from an earlier trial. It sounds younger than Ferreira, but its clipped care with instructions is familiar. Kai turns towards the Earth screen. The player can replay the passage or read its transcript, and the date remains visible above both.

Another channel contains the gardener's memory of yellow mustard fields in Bangladesh. The signature is N. The recording speaks of bringing some of that light to the Moon. Mei looks at the packet word again and hears an intention become personal, without yet receiving the writer's full identity.

The evidence board offers observations, inferences and unanswered questions as separate spaces. The player places voice resemblance under inference. The safe-retreat instruction belongs under recorded fact. Nobody announces a death, a disappearance or a secret betrayal. The old story concerns an unfinished trial whose people had procedures and choices. Mei asks for the copy to be sent respectfully to Ferreira. The player keeps the original labels on both voices. What makes the scene intimate is not an instant reveal, but the discovery that somebody once cared about the same small yellow flower before these cadets knew it existed.

**Exact dialogue**

- `EX-CH02-S10-L01` **Engineer (stored 2034 recording):** Biological trial suspended. Crew retreat is mandatory.
- `EX-CH02-S10-L02` **Kai:** That sounds like Ferreira. Younger, maybe.
- `EX-CH02-S10-L03` **N. (stored 2034 recording):** My grandmother’s mustard fields turned yellow every winter. I wanted some of that light here.
- `EX-CH02-S10-L04` **Mei:** Send the evidence. We are not solving a person by guessing.

**Required player actions**

1. Read or replay both source-labelled archive channels.
2. Classify recorded fact, voice inference and unanswered identity.
3. Prepare a respectful evidence request rather than a public accusation.

**Decision study and planned feedback**

How should the familiar engineering voice be classified?
- **Treat resemblance as complete proof of identity and history:** The evidence board flags that sound resemblance alone cannot establish a full personal account.
- **Retain voice resemblance as an inference needing verification:** The observation is preserved with its date and source; a respectful evidence request becomes the justified next step.

**Convergence:**The crew sends the same reliable fragment and question; no full personal identification or invented death occurs before Chapter 5..

**Learning loop**

- **Concept:** Inference differs from observation.
- **Predict:** Does a familiar voice prove a full personal history?
- **Observe:** Resemblance is retained as an inference, not an identification.
- **Explain:** A plausible explanation can remain unconfirmed.
- **Transfer:** Separate what a recording says from what you infer about its speaker.

**Mandatory exit condition:**Both fragments heard or read and knowledge categories correctly recorded.
**Evidence boundary:**Fiction. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_02.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH02-S11 — Send a Copy, Keep the Question
**Target:**7 minutes. **Location:**Aurora Earth-link console. **POV:**Rafi. **Story time:**2046-05-06 before 22: 00 UTC. **Legacy provenance:**`SC-0205`.

The Earth path is available, but the transmit queue does not make every question urgent. Rafi assembles a small evidence package: the intact reconstructed copy, its source photographs, the checksum and the transcript. Mei removes a line that guesses the gardener's name. The report becomes shorter and more honest.

The player checks which files were actually sent and which are merely saved locally. A receipt confirms delivery of the package. It is not a live answer from Ferreira and does not prove she agrees with the team's interpretation. Amara makes the distinction visible by placing the receipt in a separate column from future replies.

Kai wants to sit in front of the screen until somebody answers. Rafi suggests finishing the ordinary evening handover instead. The player verifies that the living plants have their care record and the tools have returned to their places. The mystery can wait without making the crew careless. A cup is placed at the mission table beside the pending reply indicator. Aurora has enough quiet for anticipation. Then the cup begins to tremble, and the ordinary object that made the room feel like home becomes the first observation of a new problem.

**Exact dialogue**

- `EX-CH02-S11-L01` **Rafi:** Copy, source images, checksum, transcript. No invented answers.
- `EX-CH02-S11-L02` **Mei:** Leave the name as a question.
- `EX-CH02-S11-L03` **Amara:** Delivered is not the same as answered.
- `EX-CH02-S11-L04` **Kai:** We can wait after the evening checks. I know.

**Required player actions**

1. Assemble evidence package without unsupported identity.
2. Verify sent files and distinguish receipt from reply.
3. Complete the normal plant-and-tool evening handover.

**Decision study and planned feedback**

How is the pending request organised?
- **Evidence by claim:** Ferreira can see the support for each question.
- **Evidence by source object:** Ferreira can inspect the original context.

**Convergence:**Both transmit the same complete, unaltered evidence package..

**Learning loop**

- **Concept:** Communication has states and evidence.
- **Predict:** Does a delivery receipt answer a question?
- **Observe:** Sent, received and answered are distinct columns.
- **Explain:** A communication system can confirm transport without confirming meaning.
- **Transfer:** Check whether a message was delivered, acknowledged or actually answered.

**Mandatory exit condition:**Package delivery acknowledged and evening handover complete before the quake.
**Evidence boundary:**Fiction. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_02.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH02-S12 — The Floor Answers First
**Target:**7 minutes. **Location:**Interior brace zone beside mission table. **POV:**Rafi. **Story time:**2046-05-06 22: 00 UTC. **Legacy provenance:**`SC-0206`.

The cup rattles again. Rafi looks down before he looks towards the screen. The shaking belongs to the station, not the recorder's speakers. A local structural alarm identifies the event as part of the fictional expedition scenario. The player moves each crew token to the marked interior brace zone and confirms four names.

No dexterity timer asks the learner to prove courage. The objective is to recognise the changing situation and use the prepared local response. Loose items are represented by clear prompts, while the game prevents a detour back to the garden controls during the active shaking. The plants remain in their serviced chambers; the crew does not run into another hazard to rescue a pot.

When the movement stops, Amara compares the atmosphere panel with its previous state. One indicator has turned red. Rafi holds the roll call until everyone answers and Kai points out a newly displaced service cover. Mei looks once at the pending Earth reply, then closes that panel. The older story remains unfinished, but the current problem takes priority. Chapter 2 ends with all four crew accounted for and the next action already understandable: trust the alarm enough to investigate, then test what it claims before touching a valve.

**Exact dialogue**

- `EX-CH02-S12-L01` **Rafi:** Brace zone. Four names, please.
- `EX-CH02-S12-L02` **Kai:** Here. The service cover moved.
- `EX-CH02-S12-L03` **Mei:** Here. Garden controls can wait.
- `EX-CH02-S12-L04` **Amara:** Here. Pressure warning changed. We verify the reading next.

**Required player actions**

1. Recognise the local shaking and enter the marked brace zone.
2. Account for all four crew without dexterity pressure.
3. Record the new warning and displaced cover for the immediate investigation.

**Decision study and planned feedback**

How is roll call confirmed?
- **Name-and-response list:** The player acknowledges each person in order.
- **Four labelled position tokens:** The player confirms the same occupants spatially.

**Convergence:**Both require all four and enter Chapter 3 without a time jump..

**Learning loop**

- **Concept:** Situation changes require reprioritising.
- **Predict:** Should a pending mystery reply remain the first task?
- **Observe:** A local alarm changes the immediate objective.
- **Explain:** Prepared teams can pause one investigation to respond to a new hazard.
- **Transfer:** When conditions change, stop and reassess the next safe task.

**Mandatory exit condition:**All four braced and accounted for; quake beat finishes and Chapter 3 begins immediately.
**Evidence boundary:**Fiction. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_02.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.

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
