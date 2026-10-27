# EX-M0104 — Keep the Promise Until Dawn

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Mandatory mission.**



## Assignment

Respond, restore water and earn the first-bloom ending. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.

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

Own this mission's scene composition/content bindings and targeted integration tests; proposed root `game/scenes/chapters/ch01/`. Shared state, simulation, UI and characters remain owned by their SYS/UI/ASSET tasks.

Prerequisite `EX-M0103`; SYS02..08; chapter puzzles P-01, P-02; owning location/asset/UI tasks. If a service is not ready, coordinate one contract-backed fixture and keep the real integration gate unverified.


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

Chapter 1:**Night One**; dates: 11-27 April 2046; authored UTC chronology; chapter target: 75 minutes.

Commission Aurora, plant Alo and Tara, prepare for a 36-hour scenario night and survive a labelled historical storm replay. First bloom closes the night and opens the mystery of N.

Emotional arc:Curiosity -> shared care -> prepared fear -> controlled crisis -> earned relief..

This mission target: 21 active minutes. Predecessor:`EX-M0103`. Successor:`EX-M0201`. Chapter puzzle families: P-01, P-02; reuse their single shared implementations and map the actual relevant stages.

### EX-CH01-S10 — The Choice Inside the Rules
**Target:**7 minutes. **Location:**Safe Room and response controls. **POV:**Rafi. **Story time:**Dark shift 5; historical 2017 event replay UTC. **Legacy provenance:**`SC-0105`.

The alarm is a change in an instrument, not a wall of glowing projectiles outside. Its historical-replay label remains beside the trace. Rafi's voice loses its apologetic lift. He calls four names and waits for four answers before any exposed phase can be committed.

The response panel offers the canonical prepared WAIT, PUMP or STACK actions as allowed by the actual state. The player inspects the forecast, selects one response and confirms it. Clicking quickly cannot collect the full benefits of several exclusive actions. Assisted modes remove the action timer while preserving reasoning and outcomes. No reward requires tolerating a panic effect.

Kai reaches for a second switch. Mei asks him to read their chosen action back. That interruption turns frantic movement into a team decision. Inside the Safe Room, the player follows shared resources and the meter, hearing suit and cabin sounds rather than exterior wind. The exposure score is a game abstraction, not a medical radiation dose. The response resolves under the same rules used in rehearsal. The crew has not defeated the Sun. It has made a controlled decision inside a prepared safety system.

**Exact dialogue**

- `EX-CH01-S10-L01` **Rafi:** Four names. Four answers. Then we commit.
- `EX-CH01-S10-L02` **Kai:** I can do another action.
- `EX-CH01-S10-L03` **Mei:** Read this one back first.
- `EX-CH01-S10-L04` **Amara:** One exclusive response. Its cost is in the forecast.

**Required player actions**

1. Confirm all four sheltered.
2. Select one legal WAIT, PUMP or STACK response.
3. Resolve the alarm using available timer alternatives.

**Decision study and planned feedback**

Does the current protection forecast support waiting, or require intervention?
- **Use prepared WAIT when its forecast passes:** The already-prepared shelter is tested against the actual alarm state; no free extra water or crates are created.
- **Choose one legal PUMP or STACK intervention when needed:** The selected intervention changes the shared resource forecast and later recovery obligations; only one exclusive action resolves.

**Convergence:**All crew shelter first. The player confirms one available P-02 response with its actual predicted consequence; an unavailable or unsafe plan remains in preview..

**Learning loop**

- **Concept:** Preparation reduces emergency confusion.
- **Predict:** Does more frantic input always help?
- **Observe:** Only one exclusive response resolves.
- **Explain:** Resources and procedure determine a safe response.
- **Transfer:** Follow an agreed drill sequence rather than inventing simultaneous tasks.

**Mandatory exit condition:**Four sheltered, legal response resolved and safety limits respected.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_01.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH01-S11 — Send the Water Home
**Target:**7 minutes. **Location:**Garden service line and mission table. **POV:**Mei. **Story time:**Dark shifts 6-7 through 2046-04-27 06: 00 UTC. **Legacy provenance:**`SC-0105`.

The alarm eases, but the wall does not empty itself. Mei studies the garden line while Amara checks which exposure step has actually finished. The player must respect the rule ordering. Water cannot be drained before the exposure it was meant to shield resolves. Afterwards, keeping it forever would be another mistake.

The display shows the same reservoir and plant forecast discussed before Earth-set. The player checks the remaining plan, returns water at a valid gate and commits the final shifts. An animation follows flow back to the garden. Kai watches the battery approach a low value without narrating automatic failure. Exactly zero stored energy is distinct from an unpaid demand causing blackout. The system determines the result.

Alo lost and Mission stopped receive respectful closures and causal reviews. They never advance this expedition with an unexplained replacement flower. A local checkpoint restores the complete state for a supported retry. On the successful route, Mei records which choices kept the crew safe and which kept the bud alive. The last task before sunrise is not applause. It is confirming that opening the chamber's viewing shutter will be safe.

**Exact dialogue**

- `EX-CH01-S11-L01` **Mei:** Borrowing was the first half. This is the other half.
- `EX-CH01-S11-L02` **Amara:** Exposure resolves before drain. Read the gate.
- `EX-CH01-S11-L03` **Kai:** Low is not failed. What demand comes next?
- `EX-CH01-S11-L04` **Rafi:** Review the cause, not the person holding the control.

**Required player actions**

1. Check exposure-before-drain order and remaining forecasts.
2. Return water legally and resolve final dark shifts.
3. Review the earned outcome or restore the complete checkpoint.

**Decision study and planned feedback**

What leads the debrief?
- **Water-return timeline:** Irrigation recovery has a visible cause.
- **Demand-and-energy record:** Low reserves and unmet demand are distinguished.

**Convergence:**Both remain; safe crew and living Alo are required to advance this expedition..

**Learning loop**

- **Concept:** Recovery completes a safety plan.
- **Predict:** When can a protective resource return?
- **Observe:** Exposure, drainage and later plant effects occur in order.
- **Explain:** Interventions need explicit end conditions.
- **Transfer:** Check safe restoration after using emergency supplies.

**Mandatory exit condition:**P-02 reaches safe crew and living Alo; loss closures offer supported checkpoint retry.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_01.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH01-S12 — Alo Needs a Friend
**Target:**7 minutes. **Location:**Chamber shutter and Tara reference bay. **POV:**Mei. **Story time:**2046-04-27 06: 00 UTC. **Legacy provenance:**`SC-0106`.

The first strip of returning light meets a closed shutter. Mei asks the player to check chamber conditions before opening it. After all that waiting, the story gives this small safety action the same dignity as the alarm. Only then does a yellow mustard flower appear.

The player tags the bloom photograph. That event triggers a stored care message. The recorder has not predicted the future, and nobody is calling through the absent Earth link. A voice signed N. congratulates whoever is hearing it, then says Alo needs a friend. Mei looks towards the indoor bay. Tara's bud has been receiving its own care all along. Now its place becomes a new question.

The debrief separates historical storm records, scenario schedule and fictional station. It names the crew's actual decisions and earned Bloom or Golden Bloom result. Assistance receives the same ending access. Mei puts the image beside the packet without replacing its unknown initial with a guess. Outside, nothing has become easy. Inside, Aurora has become their station. A living flower and a complete first-night outcome give the player a reason to enter the next room.

**Exact dialogue**

- `EX-CH01-S12-L01` **Mei:** Chamber safe. Now we open it.
- `EX-CH01-S12-L02` **N. (stored recording):** If you are hearing this, Alo bloomed. Good. Now Alo needs a friend.
- `EX-CH01-S12-L03` **Kai:** Another plant was in the next room all along.
- `EX-CH01-S12-L04` **Amara:** And it has a name. Tara.

**Required player actions**

1. Verify chamber conditions and open the shutter.
2. Tag the image to trigger the labelled stored recording.
3. Inspect Tara and complete the decision-and-evidence debrief.

**Decision study and planned feedback**

What accompanies the bloom image?
- **Four role decisions:** The record foregrounds cooperation.
- **Care-and-recovery timeline:** The record foregrounds sustained work.

**Convergence:**Both retain the bloom, N. recording and Tara hook without identifying N..

**Learning loop**

- **Concept:** Evidence distinguishes stored media from live contact.
- **Predict:** Why does a message play while Earth is unavailable?
- **Observe:** The recorder shows its local origin and event trigger.
- **Explain:** A stored message can respond to a local event.
- **Transfer:** Distinguish recorded messages from live conversations.

**Mandatory exit condition:**Image tagged, recording heard or read, Tara inspected and chapter debrief complete.
**Evidence boundary:**Fiction. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_01.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.

### Cross-mission continuity
- Commissioning never changes the fixed April 25 P-02 initial state.
- Two daylight and five dark shifts;36-hour night is an authored scenario.
- Earth link ends at shift 4; local radios and stored guidance persist.
- N. remains anonymous and recorded; Tara is cared for from planting.
- Safe crew and living Alo advance the campaign; losses close locally with retry.

### Production constraints
- Maintain plant pressure enclosures; no exposure to vacuum.
- Use instrument traces and cabin/suit sound for the storm.
- Assistance preserves outcomes and rewards.
- This standalone 75-minute mandatory route supersedes the old 28-minute target only in this edition.

### Chapter bridge
Earth contact returns days later on April 30. Tara opens and the recorded request becomes a pollination problem.


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
