# EX-M0701 — Your Call, Cadets

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Mandatory mission.**



## Assignment

Distinguish source evidence and integrate the five-person forecast. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.

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

Prerequisite `EX-M0604`; SYS02..08; chapter puzzles P-13, P-14; owning location/asset/UI tasks. If a service is not ready, coordinate one contract-backed fixture and keep the real integration gate unverified.


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

This mission target: 25 active minutes. Predecessor:`EX-M0604`. Successor:`EX-M0702`. Chapter puzzle families: P-13, P-14; reuse their single shared implementations and map the actual relevant stages.

### EX-CH07-S01 — A Warning We Share
**Target:**8 minutes. **Location:**Aurora mission table. **POV:**Rafi. **Story time:**14 February 2047, before 06: 00. **Legacy provenance:**`SC-0701`.

Breakfast stops when the new warning arrives. This time Rafi does not soften it with a joke or an apology. He puts the observations where everyone can see them and asks each specialist to read the part the others need. The player opens the source label before opening the forecast.

The chapter uses a clearly identified counterfactual replay: what if the powerful July 2012 solar event had struck the Moon? Its historical measurements inform the scenario; the fictional expedition date, three playable waves and game exposure are not presented as observed lunar damage. Rafi sets the warning beside the breakfast bowls. His hand is steady as he asks the others what the new evidence changes.

Rao confirms the last pre-isolation packet through a working Earth link. Ferreira then moves her chair away from the head of the table. She assigns operational planning to the cadets while retaining command responsibility. Kai asks for every observation before touching a setting. The player's first decision is what the evidence justifies, not how dramatic the warning sounds.

**Exact dialogue**

- `EX-CH07-S01-L01` **Rafi:** New observations. Everyone needs them.
- `EX-CH07-S01-L02` **Rao (live Earth link):** Historical source received and labelled.
- `EX-CH07-S01-L03` **Ferreira:** Your plan, cadets. I retain command responsibility.
- `EX-CH07-S01-L04` **Kai:** Read every observation before we set anything.

**Required player actions**

1. Read source and counterfactual label.
2. Share four specialist observations.
3. State what the forecast can and cannot claim.

**Decision study and planned feedback**

Which statement belongs in the mission brief?
- **A measured 2012 storm hit Aurora in 2047:** The source/date mismatch is flagged; lunar damage is authored fiction.
- **Historical measurements inform a fictional Moon-strike scenario:** The brief distinguishes source evidence from game events.

**Convergence:**All current observations shared and counterfactual source correctly described..

**Learning loop**

- **Concept:** Counterfactual modelling
- **Predict:** Can a historical source prove a future fictional strike?
- **Observe:** Compare source date, scenario date and authored wave model.
- **Explain:** Models can explore consequences without turning them into observations.
- **Transfer:** Separate an evidence source from the situation built around it.

**Mandatory exit condition:**All current observations shared and counterfactual source correctly described.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_07.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH07-S02 — The Fifth Seat Changes the Sum
**Target:**8 minutes. **Location:**Life-support board and shelter roster. **POV:**Amara. **Story time:**14 February, forecast preparation. **Legacy provenance:**`SC-0701`.

The old first-night card still lists four crew. Amara places it beside the present shelter roster, where Ferreira's name makes five. The player is asked to reuse only the rules that remain applicable. Keeping the old breathing total would be a smaller number, but it would no longer describe this expedition.

A paused comparison forecast shows the difference across six equal scenario steps. Air and food draw follow the five-person profile. The plant chamber does not become an oxygen generator just because its leaves look healthy. Stored air, powered scrubbers and edible supplies remain explicit systems. Cotton and the current mustard generation need care; they do not replace a balanced crew ledger.

Rafi places five seat markers on the shelter diagram. A missing marker leaves the readiness board incomplete even if the energy arithmetic looks attractive. The player reconciles the occupancy and resource totals before moving to shielding. Amara repeats the correction without embarrassment. The record from April was useful for its own conditions. Good engineering means knowing when those conditions have changed.

**Exact dialogue**

- `EX-CH07-S02-L01` **Amara:** April's card counted four.
- `EX-CH07-S02-L02` **Ferreira:** Today it must count me.
- `EX-CH07-S02-L03` **Mei:** Plants are not our whole life-support system.
- `EX-CH07-S02-L04` **Rafi:** Five names. Five places inside.

**Required player actions**

1. Compare four- and five-person forecasts.
2. Apply current air and food rates.
3. Match all five occupants to shelter positions.

**Decision study and planned feedback**

Which consumption profile should be tested?
- **Reuse the four-person profile:** The comparison exposes omitted fifth-person consumption.
- **Apply the five-person profile:** Air and food demand reconcile with the present roster.

**Convergence:**Five-person profile and complete shelter roster verified..

**Learning loop**

- **Concept:** Changing boundary conditions
- **Predict:** Which old values stop applying after the roster changes?
- **Observe:** Compare identical plans under two occupancies.
- **Explain:** A valid model must match the system it describes.
- **Transfer:** Recheck assumptions when people or conditions change.

**Mandatory exit condition:**Five-person profile and complete shelter roster verified.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_07.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH07-S03 — One Plan, Not Four Good Intentions
**Target:**9 minutes. **Location:**Integrated storm planning table. **POV:**Kai. **Story time:**14 February, uncommitted six-step forecast. **Legacy provenance:**`SC-0702`.

Four proposed plans arrive at once. Kai wants power margin, Amara wants uninterrupted circulation, Mei wants warm roots, and Rafi wants complete shielding. Each sounds sensible alone. The player overlays them and finds the conflict: water borrowed for the shelter is water unavailable to the garden until the return operation.

The forecast shows six dark steps and no invented solar income. Current entry reserves belong to this chapter, after preparation costs; they are not April's old end-state copied forward. The player assembles one schedule using the established water, cargo and temperature rules. A complete baseline can protect five people, living crops and the thirty-seed reserve without an earned upgrade being a mandatory key.

Each proposed change updates a specific forecast: dose before transfer, plant stress after care, or remaining energy. The player must explain a rejected alternative before committing the integrated version. Ferreira asks whose objective was left outside. The answer has to be nobody's. Their plan is ready only when every role can trace its own dependency through the same six steps.

**Exact dialogue**

- `EX-CH07-S03-L01` **Kai:** Four good ideas can still collide.
- `EX-CH07-S03-L02` **Mei:** Say when the borrowed water returns.
- `EX-CH07-S03-L03` **Amara:** And keep circulation running meanwhile.
- `EX-CH07-S03-L04` **Rafi:** One schedule. Every dependency.

**Required player actions**

1. Overlay the four role plans.
2. Forecast six dark steps without solar income.
3. Compare a safe baseline with one changed allocation.

**Decision study and planned feedback**

What must be fixed in the combined forecast?
- **Drain shielding water before a later exposure:** The forecast shows reduced protection at the next sample.
- **Keep protection until its final exposure check:** The return operation follows exposure and preserves safety.

**Convergence:**One feasible six-step plan preserves crew, garden, circulation and reserve..

**Learning loop**

- **Concept:** Systems trade-offs and event order
- **Predict:** Could individually good plans conflict?
- **Observe:** Compare combined demand and exposure-before-transfer order.
- **Explain:** Shared resources connect decisions across systems and time.
- **Transfer:** Test a whole plan rather than isolated intentions.

**Mandatory exit condition:**One feasible six-step plan preserves crew, garden, circulation and reserve.
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
