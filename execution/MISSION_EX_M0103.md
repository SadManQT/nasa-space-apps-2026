# EX-M0103 — Prepare While It Is Light

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Mandatory mission.**



## Assignment

Store air, rehearse shielding and compare the dark-shift plan. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.

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

Prerequisite `EX-M0102`; SYS02..08; chapter puzzles P-01, P-02; owning location/asset/UI tasks. If a service is not ready, coordinate one contract-backed fixture and keep the real integration gate unverified.


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

This mission target: 18 active minutes. Predecessor:`EX-M0102`. Successor:`EX-M0104`. Chapter puzzle families: P-01, P-02; reuse their single shared implementations and map the actual relevant stages.

### EX-CH01-S07 — Air Before the Jar Spills
**Target:**6 minutes. **Location:**Air console and mast status panel. **POV:**Amara. **Story time:**2046-04-25 daylight shifts 1-2 UTC. **Legacy provenance:**`SC-0104`.

The battery fills quickly in daylight, exactly as it did during commissioning. Amara asks Kai to watch the overflow arrow instead of admiring the full gauge. Her role card explains that useful air can be made now. Kai's card explains the dark interval the stored energy must support. Neither card solves the whole schedule alone.

The player compares two plans in the same preview. Both begin from the fixed April 25 survival state, not the earlier commissioning exercise. Production, storage cap and spending appear in their proper order. An animation follows energy into the air maker and then points to the oxygen store. Mei watches the lamp setting; a convenient air plan still affects the garden.

Each cadet gives a recommendation. In Solo, every role card is available; in Class, groups share private printed cards. No solution depends on another controller. The player commits daylight shift 1 and stages the shift 2 plan without advancing it. The shelter drill is still ahead of that second commitment. The night remains ahead, its reserves visible. Amara does not call the result perfect. She calls it a plan the team can explain and therefore revise. Kai writes the reason beside the setting, giving the next watch something more useful than a number.

**Exact dialogue**

- `EX-CH01-S07-L01` **Amara:** We can keep air we make now. We cannot keep overflow.
- `EX-CH01-S07-L02` **Kai:** Same full jar. Better destination.
- `EX-CH01-S07-L03` **Mei:** Read the lamp setting before calling it spare.
- `EX-CH01-S07-L04` **Rafi:** Four recommendations. One confirmed plan.

**Required player actions**

1. Share power and atmosphere role constraints.
2. Compare daylight plans in the unchanged P-02 preview.
3. Commit daylight shift 1 after role acknowledgement and stage, but do not yet commit, shift 2.

**Decision study and planned feedback**

How should available daylight energy be allocated in the forecast?
- **Increase stored-air preparation within the shared budget:** The forecast displays the changed air reserve together with competing lamp spending and any overflow under the same cap.
- **Prioritise the garden-lamp setting within the same budget:** The forecast displays plant benefit and the remaining air and energy requirements; the team must account for the entire night.

**Convergence:**The player can revise either candidate, then commit one supported whole shift 1 plan and stage shift 2. No combined best-case benefits are granted..

**Learning loop**

- **Concept:** A shared resource budget connects systems.
- **Predict:** Can one load change without affecting the forecast?
- **Observe:** Every setting uses the same shared budget.
- **Explain:** Compare whole plans rather than separate best cases.
- **Transfer:** Agree on a single shared budget before promising separate outcomes.

**Mandatory exit condition:**Daylight shift 1 committed with role acknowledgement; shift 2 forecast staged and paused before its drill.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_01.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH01-S08 — Borrowing Includes Returning
**Target:**6 minutes. **Location:**Safe Room practice interface. **POV:**Rafi. **Story time:**2046-04-25 within daylight shift 2, before 18: 00 UTC. **Legacy provenance:**`SC-0104`.

Rafi begins the drill by pointing to the doorway and asking everyone to count themselves in. The feed identifies the historical 2017 source of the storm warning. It is not a newly measured flare in 2046. With that distinction visible, the team practises the responses the scenario will test.

The player follows water from the garden reservoir into the shelter wall and back in a reversible demonstration. Another preview shows supplies positioned as shielding. Practice spends no survival resources and leaves no free permanent crate wall. Amara reads the post-drill state aloud, proving the exercise has not silently improved the actual baseline.

Mei asks why a wall that protects people can hurt a plant. Rafi points to the shared reservoir. The same water cannot occupy both places. Their problem is conservation and timing, not deciding whose life matters. Crew sheltering is mandatory. Inside that boundary, the player rehearses the controls and marks a return-water reminder. Kai draws its arrow like a returning road. The joke makes the obligation memorable. Each cadet demonstrates the same rule through a different view. Only after the drill does the player commit the staged second daylight shift; the date card reaches 18:00 and the masts approach sunset.

**Exact dialogue**

- `EX-CH01-S08-L01` **Rafi:** First rule: the crew goes inside.
- `EX-CH01-S08-L02` **Mei:** And the water comes home when the plan allows.
- `EX-CH01-S08-L03` **Amara:** Practice complete. Baseline unchanged.
- `EX-CH01-S08-L04` **Kai:** I drew the water a return ticket.

**Required player actions**

1. Rehearse shelter entry and roll call.
2. Trace water and compare canonical response previews.
3. Verify the unchanged pre-drill baseline, record the return reminder, then commit the staged daylight shift 2.

**Decision study and planned feedback**

How is water return shown?
- **Timeline marker:** The team sees the return gate.
- **Reservoir diagram:** The team sees what is borrowed.

**Convergence:**Both remain visible; the drill grants no free advantage..

**Learning loop**

- **Concept:** Conservation and sequence in protective systems.
- **Predict:** Can the same water be in both places?
- **Observe:** The diagram moves a conserved reservoir.
- **Explain:** Protection has secondary costs that need restoration.
- **Transfer:** Plan the return of shared equipment before borrowing it.

**Mandatory exit condition:**No-cost drill and roll call complete; unchanged pre-drill state verified; daylight shift 2 committed at 18:00.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_01.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH01-S09 — The Horizon Closes One Door
**Target:**6 minutes. **Location:**Mission table and Earth-facing view port. **POV:**Kai. **Story time:**2046-04-25 18: 00 onward; dark shifts 3-4 UTC. **Legacy provenance:**`SC-0105`.

The mast stops producing, and the station grows quieter without becoming dead. Fans continue. The hand light remains in its marked place. Kai lets the player inspect reserves before switching off a decorative lamp. He asks when light will return. Amara points to their schedule instead of promising he will stop being afraid.

Mei's role card arrives in the first dark shift. In this scenario, cold and thirst are Alo's immediate threats; borrowed shielding water affects irrigation. Rafi's warning and Kai's budget must now be read alongside it. The player compares two complete plans, including the later cost of returning water. Heat settings remain genuine options under the locked rules. The story does not manufacture one moral answer.

Earth contact ends at its separate shift gate. The crew reads back Ferreira's last available instruction before the channel greys out. Stored guidance is labelled beside the unavailable live-link button. No new Earth voice slips through. Kai reaches towards the familiar lamp, then opens the plan instead. The next shift is committed with the local crew present. This loss of contact matters, but it is a loss they prepared to understand.

**Exact dialogue**

- `EX-CH01-S09-L01` **Kai:** I want to know where the next light comes from.
- `EX-CH01-S09-L02` **Amara:** The plan. And that hand light. Both are here.
- `EX-CH01-S09-L03` **Mei:** Read my cold-and-thirst card with Rafi's warning.
- `EX-CH01-S09-L04` **Ferreira (Earth link before cutoff):** Local rules remain active. Read back the next safe action.

**Required player actions**

1. Combine Mei and Rafi observations with the power-and-air budget.
2. Compare complete night plans without changing P-02 rules.
3. Acknowledge Earth cutoff and resolve safe shifts.

**Decision study and planned feedback**

Where does plan comparison start?
- **Shelter timeline:** Protection and return are traced.
- **Heat-and-lamp timeline:** Living conditions and energy are traced.

**Convergence:**Both use the full forecast and mandatory crew sheltering..

**Learning loop**

- **Concept:** Information from different roles changes decisions.
- **Predict:** Which two facts affect the water plan?
- **Observe:** Storm risk and plant thirst share a reservoir.
- **Explain:** Good plans combine specialist observations.
- **Transfer:** Ask what another person knows before committing a shared plan.

**Mandatory exit condition:**Cards combined, Earth-set acknowledged and shifts 3-4 resolved safely.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_01.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.

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
