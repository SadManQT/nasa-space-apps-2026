# EX-M0702 — What Gets the Last Drop

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Mandatory mission.**



## Assignment

Protect founder stock, verify occupants and execute the first wave. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.

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

Own this mission's scene composition/content bindings and targeted integration tests; proposed root `game/scenes/chapters/ch07/`. Shared state, simulation, UI and characters remain owned by their SYS/UI/ASSET tasks.

Prerequisite `EX-M0701`; SYS02..08; chapter puzzles P-13, P-14; owning location/asset/UI tasks. If a service is not ready, coordinate one contract-backed fixture and keep the real integration gate unverified.


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

Chapter 7:**The Great Storm**; dates: 14 February–8 April 2047; chapter target: 105 minutes.

A labelled 2012 counterfactual source informs an integrated five-person storm plan. The crew executes six checked steps, protects living crops and founder seeds, and hears the local historical log explaining the Academy's name. An external uplink failure is diagnosed without destroying local communications. Required stable-operation, fabrication and route tests bridge February to April before the teams separate.

Emotional arc:Shared warning → systems conflict → practiced sheltering → meaning → bounded loss → prepared resolve..

This mission target: 25 active minutes. Predecessor:`EX-M0701`. Successor:`EX-M0703`. Chapter puzzle families: P-13, P-14; reuse their single shared implementations and map the actual relevant stages.

### EX-CH07-S04 — What Gets the Last Drop
**Target:**8 minutes. **Location:**Shelter water wall and seed case. **POV:**Mei. **Story time:**14 February, final preparation. **Legacy provenance:**`SC-0702`.

Mei carries the protected case to the shelter with both hands. Inside are two founder-reserve compartments of fifteen seeds each. The twelve planted from Alo's first harvest are already part of the garden's lineage. Neither the vault collection nor an album page belongs in this count. The player checks the seals against the thirty-seed record before latching the case.

At the wall, the forecast compares two water-return times. Draining early eases garden thirst but weakens a later exposure. Holding through the final sample preserves shielding, then returning the scheduled water protects the living plants. The player traces the order on a physical valve diagram before using the controls. Cargo bundles remain installed through the last exposure instead of disappearing under April's different shift schedule.

Rafi checks that every tool has a secured place. Mei touches the case once, then closes it. Protecting dry seeds and caring for living plants are related jobs with different conditions. The plan must do both. The player confirms the return-pump priority while the shelter remains open and preparation is still safe.

**Exact dialogue**

- `EX-CH07-S04-L01` **Mei:** Fifteen and fifteen. Thirty founders.
- `EX-CH07-S04-L02` **Rafi:** Bundles stay through the last exposure.
- `EX-CH07-S04-L03` **Amara:** Return after the sample, not before.
- `EX-CH07-S04-L04` **Ferreira:** Name the valve, then touch it.

**Required player actions**

1. Reconcile both fifteen-seed compartments.
2. Compare early and after-exposure return schedules.
3. Latch case and secure shielding cargo.

**Decision study and planned feedback**

Choose the final-step operation order.
- **Drain, then sample exposure:** The preview shows protection removed before it is needed.
- **Sample exposure, then drain:** The preview retains protection before scheduled garden return.

**Convergence:**Founder 30 latched; shielding and after-exposure return order verified..

**Learning loop**

- **Concept:** Sequence and conservation
- **Predict:** Why can identical actions in a different order change safety?
- **Observe:** Compare the same water transfer before and after exposure.
- **Explain:** Resources retain quantity while their location changes their function.
- **Transfer:** Check event order as well as totals.

**Mandatory exit condition:**Founder 30 latched; shielding and after-exposure return order verified.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_07.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH07-S05 — Everyone Inside
**Target:**9 minutes. **Location:**Aurora Safe Room. **POV:**Rafi. **Story time:**14 February, first-wave readiness. **Legacy provenance:**`SC-0703`.

The readiness panel reaches its preparation threshold. Rafi stops discussing plans and begins the roll call. The player locates five people in the shelter and confirms each response through the local channel. A chair icon alone is not proof that someone reached it; the name, position and answer must agree.

Mei checks the sealed founder case while Amara verifies the atmosphere indicator. Kai confirms the protected electrical branch and the scheduled isolation of exposed radio hardware. Ferreira answers her own roll-call entry like everyone else. She does not remain outside for a heroic last photograph. The garden's instruments continue reporting through the local network; their pressure-safe enclosure is not opened.

The player closes the hatch and compares its two indications. A mismatch holds the step clock while the relevant check is repeated. Reading, caption hold and assisted input do not spend hidden oxygen. Once the compartment and roster agree, the first forecast becomes the first committed step. The shelter is a place where preparation becomes observable behaviour, and all five people remain visibly part of that behaviour.

**Exact dialogue**

- `EX-CH07-S05-L01` **Rafi:** Kai?
- `EX-CH07-S05-L02` **Kai:** Here. Protected branch checked.
- `EX-CH07-S05-L03` **Amara:** Atmosphere checked. Mei is here.
- `EX-CH07-S05-L04` **Ferreira:** Ferreira here. Fifth position confirmed.

**Required player actions**

1. Reconcile names, positions and answers.
2. Verify both hatch indications.
3. Commit only after all five are sheltered.

**Decision study and planned feedback**

A seat indicator and roster disagree. What next?
- **Advance because the seat icon is green:** The readiness gate identifies the missing human confirmation.
- **Resolve the name and position:** The checkback confirms the actual occupant before time advances.

**Convergence:**Five occupants confirmed, both hatch checks agree, first step ready..

**Learning loop**

- **Concept:** Verification of people and states
- **Predict:** Is a favourable icon enough to prove readiness?
- **Observe:** Compare position, roster and direct response.
- **Explain:** Different evidence channels should agree before commitment.
- **Transfer:** Resolve a mismatch instead of ignoring the inconvenient reading.

**Mandatory exit condition:**Five occupants confirmed, both hatch checks agree, first step ready.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_07.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH07-S06 — The First Wave Has a Ledger
**Target:**8 minutes. **Location:**Safe Room local telemetry. **POV:**Amara. **Story time:**14 February 06: 00 onward, steps 1–2. **Legacy provenance:**`SC-0704`.

The first committed step changes the ledger exactly as previewed. The player checks energy, atmosphere, food and the garden's local telemetry against the forecast, then states which differences would require intervention. The storm is not shown as luminous stones flying into the greenhouse. Its danger is communicated by instruments, procedure and the room's restrained sound.

A second step follows only after the player acknowledges the first. The chapter's six steps each represent seven-point-two scenario hours; the active gameplay does not ask anyone to sit still for that duration. A time card and changed system values communicate the interval. The main route spends its time on prediction, comparison and decision, not on an empty countdown.

The protected seed case remains sealed. One compartment indicator briefly invites inspection of its recorded sensor value, not opening it during exposure. Mei checks the local garden trace while Kai confirms the isolated exposed branch. Their reports meet at the same table. When the first wave ends, the player has a supported explanation for why the plan is holding.

**Exact dialogue**

- `EX-CH07-S06-L01` **Amara:** Compare the result with the forecast.
- `EX-CH07-S06-L02` **Kai:** Protected branch matches.
- `EX-CH07-S06-L03` **Mei:** Living garden still on local telemetry.
- `EX-CH07-S06-L04` **Rafi:** First wave checked, not merely endured.

**Required player actions**

1. Predict and commit steps one and two.
2. Compare actual scenario state with forecast.
3. Keep reserve sealed while inspecting telemetry.

**Decision study and planned feedback**

Which response fits a normal first-step result?
- **Open the seed case to inspect it:** The interlock explains why sealed telemetry is the safe check.
- **Compare its sensor and seal records:** The protected stock stays closed while evidence is checked.

**Convergence:**Steps 1–2 committed, forecast comparison saved, founder case sealed..

**Learning loop**

- **Concept:** Prediction and feedback
- **Predict:** Which readings would show that the model missed something?
- **Observe:** Compare predicted and resulting state per step.
- **Explain:** Execution should test a plan rather than replace observation.
- **Transfer:** Check outcomes after acting, even when the plan was good.

**Mandatory exit condition:**Steps 1–2 committed, forecast comparison saved, founder case sealed.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_07.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.

### Cross-mission continuity
- Five lunar occupants in every storm phase.
- Six 7.2-hour steps=43.2 scenario hours; source 2012 counterfactual is not a measured 2047 Moon storm.
- Founder 30 protected as 15+15; water and cargo retained through final exposure.
- No live Earth response after uplink failure; local voices and telemetry survive.
- Feb 16–Apr 7 includes required dated care, supply, fabrication and route work.
- Finale team 3 rover/2 home; no unaccounted operator.

### Production constraints
- Instrument-led storm presentation; no visible radiation projectiles.
- Role sharing never hides a safety warning.
- Use one chapter entry profile and apply earned modifiers only once.
- Bench tests and route simulation remain distinct from actual field verification.
- Three physical road repeaters create four surface hops: Aurora→R1→R2→R3→summit. Count sites separately from links.

### Chapter bridge
The checked home and rover ledgers carry the expedition into the 51-hour relay journey.


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
