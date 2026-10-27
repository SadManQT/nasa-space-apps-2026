# EX-M0102 — Two Plants, One Night Plan

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Mandatory mission.**



## Assignment

Plant, sustain dated care and understand the night timeline. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.

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

Prerequisite `EX-M0101`; SYS02..08; chapter puzzles P-01, P-02; owning location/asset/UI tasks. If a service is not ready, coordinate one contract-backed fixture and keep the real integration gate unverified.


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

This mission target: 18 active minutes. Predecessor:`EX-M0101`. Successor:`EX-M0103`. Chapter puzzle families: P-01, P-02; reuse their single shared implementations and map the actual relevant stages.

### EX-CH01-S04 — Two Places for a Beginning
**Target:**6 minutes. **Location:**Garden glove ports and indoor reference bay. **POV:**Mei. **Story time:**2046-04-11 late morning UTC. **Legacy provenance:**`SC-0102`.

Mei guides the first seed into its cassette through the glove ports. The movement is small enough that the player can take their time. Kai holds the work light steady instead of helping twice. Amara reads the label back, and Rafi confirms the transfer lid is latched before the next seal opens. The sequence never asks a learner to imitate an unsafe vacuum experiment.

The player plants Alo in the exterior test chamber and Tara in the indoor reference bay, one compatible plant per cassette. Their cards record the same seed lot and different environments. A notebook asks what the team will observe. The task is not to declare which plant is better, but to keep observations and conditions together. Temperature, moisture and lighting accompany each photograph.

When Mei presses both names onto their holders, two empty circles become responsibilities. Tara receives her own close view, not a spare-plant thumbnail. The player checks both service connections and sees that both depend on the same careful crew. The packet returns to protected storage. Its unanswered initial can wait; the next care visit cannot.

**Exact dialogue**

- `EX-CH01-S04-L01` **Mei:** Alo outside. Tara inside. A star beside our light.
- `EX-CH01-S04-L02` **Amara:** A reference is a plant we care for, not one we ignore.
- `EX-CH01-S04-L03` **Kai:** One lamp held still. I can manage that.
- `EX-CH01-S04-L04` **Rafi:** Transfer sealed. Two names, two records.

**Required player actions**

1. Plant one seed per labelled cassette through sealed interfaces.
2. Record conditions and photographs for both.
3. Check service connections and archive the packet.

**Decision study and planned feedback**

How is the notebook organised?
- **Paired photographs:** Differences are easy to inspect.
- **Paired conditions table:** The context is easy to compare.

**Convergence:**Both retain individual identities and dated care records..

**Learning loop**

- **Concept:** Comparisons retain their conditions.
- **Predict:** Is a single photograph enough?
- **Observe:** Dates and environment records accompany each image.
- **Explain:** Outcomes need context to be interpreted.
- **Transfer:** Record light and watering in a classroom growing comparison.

**Mandatory exit condition:**Both seeds planted, labelled and recorded; services confirmed.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_01.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH01-S05 — An Important Scientific Lamp
**Target:**6 minutes. **Location:**Aurora corridor and care station. **POV:**Kai. **Story time:**2046-04-11 evening through April 24 UTC. **Legacy provenance:**`SC-0103`.

Kai checks the corridor switch once, then again. Mei notices the second click but leaves space before asking. He describes the lamp as important scientific equipment. Rafi considers this, retrieves a hand light and hangs it handle-out beside the locker. He does not make Kai explain a fear in front of the whole team.

The player tests the light, marks its home on the equipment board and begins a dated care sequence. Each visit brings a task: compare a root photograph, inspect a connection, record chamber conditions or notice a new leaf. The transitions show actual care days. Buds do not appear because a button was held for fourteen seconds. Time advances only at explicit date cards, after the required work is recorded.

As the corridor becomes familiar, the crew's objects acquire places. Amara's stylus returns to its clip. Mei's pencil stays near both plant records. The spare light remains where Kai can find it without asking. Beside the latest photograph the player places the first. The difference is earned by the intervening record: care has a rhythm before it has a crisis.

**Exact dialogue**

- `EX-CH01-S05-L01` **Mei:** You checked that switch already.
- `EX-CH01-S05-L02` **Kai:** Important scientific lamp.
- `EX-CH01-S05-L03` **Rafi:** Then it gets a backup. Here.
- `EX-CH01-S05-L04` **Amara:** Fourteen dated care entries. A bud is a useful result.

**Required player actions**

1. Test and hang the hand light.
2. Complete distinct observations across the dated growth montage.
3. Compare initial and latest images with care records.

**Decision study and planned feedback**

What sits beside the latest image?
- **The first photograph:** Growth becomes visible.
- **The conditions record:** The work behind growth becomes visible.

**Convergence:**Both stay in the dated notebook; neither advances time alone..

**Learning loop**

- **Concept:** Growth takes time and sustained care.
- **Predict:** What happens between seed and bud?
- **Observe:** Dated maintenance is retained in the montage.
- **Explain:** Time compression need not imply instant biology.
- **Transfer:** Keep records of ordinary days in a growing experiment.

**Mandatory exit condition:**Lamp installed, care visits complete and date transition confirmed.
**Evidence boundary:**Fiction. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_01.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH01-S06 — The Night Has a Shape
**Target:**6 minutes. **Location:**Mission table and horizon display. **POV:**Amara. **Story time:**2046-04-25 03: 36 UTC. **Legacy provenance:**`SC-0103`.

Amara unfolds the training schedule across the table. Two daylight work shifts stand before five dark shifts. The display calls the coming thirty-six-hour interval a scenario based on polar science. It does not claim the crew has already computed Aurora's exact sky. A source tab separates the published illumination map from the authored schedule.

The player arranges Sun, Earth-link and station-system cards on separate tracks. A dark array does not mean Earth has already disappeared. An Earth outage does not switch off the local air maker. Once the cards align, Kai can describe the night without treating it as one enormous blackout. There will be named stages, stored reserves and people on each watch.

Mei adds the garden's needs. Rafi adds shelter access and the familiar hand light. Amara asks everyone to explain one dependency from another role. This reveals a mistake while it is still a drawing: protecting the shelter for too long can leave irrigation unavailable. The player corrects the schedule before any resource changes are committed. The low Sun is still present. Preparation has time to be an action.

**Exact dialogue**

- `EX-CH01-S06-L01` **Amara:** Sunlight, Earth visibility and our switches are separate tracks.
- `EX-CH01-S06-L02` **Kai:** So darkness can have a timetable.
- `EX-CH01-S06-L03` **Mei:** Put the garden on it. The shelter borrows from us.
- `EX-CH01-S06-L04` **Rafi:** Put returning the water on it too.

**Required player actions**

1. Arrange independent Sun, link and system tracks.
2. Distinguish sourced map from authored scenario.
3. Explain another role dependency and correct the schedule.

**Decision study and planned feedback**

Which shelter-and-irrigation schedule should be tested?
- **Keep borrowed water in the wall for the remaining night:** The paused forecast shows continued shielding together with the garden thirst and irrigation consequences of the same unavailable reservoir.
- **Schedule return after the required exposure resolves:** The forecast shows reduced later shielding and recovered irrigation; the player checks that both the exposure and later plant limits remain safe.

**Convergence:**The player compares both complete plans and stages a legal schedule. The April 25 baseline and P-02 numerical rules are unchanged..

**Learning loop**

- **Concept:** Independent systems have linked schedules.
- **Predict:** Does sunset end everything simultaneously?
- **Observe:** The tracks change at separate gates.
- **Explain:** Timelines expose dependencies without conflating events.
- **Transfer:** Separate deadlines, communications and resources in a project plan.

**Mandatory exit condition:**Timelines correct and shared preparation schedule acknowledged.
**Evidence boundary:**Computed-pending. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_01.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.

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
