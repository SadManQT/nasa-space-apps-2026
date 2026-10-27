# EX-M0703 — What We Carry

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Mandatory mission.**



## Assignment

Complete the remaining waves and diagnose the external failure. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.

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

Prerequisite `EX-M0702`; SYS02..08; chapter puzzles P-13, P-14; owning location/asset/UI tasks. If a service is not ready, coordinate one contract-backed fixture and keep the real integration gate unverified.


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

This mission target: 30 active minutes. Predecessor:`EX-M0702`. Successor:`EX-M0704`. Chapter puzzle families: P-13, P-14; reuse their single shared implementations and map the actual relevant stages.

### EX-CH07-S07 — The Last Log
**Target:**10 minutes. **Location:**Safe Room archive player and forecast table. **POV:**Mei. **Story time:**First-wave lull, after step 2. **Legacy provenance:**`SC-0704`.

In the lull, the player opens the final recovered recording. Its caption identifies a historical archive, already stored locally. Noor's voice does not cross the current storm or prove the Earth link is open. She is speaking from the old expedition's departure day.

She explains the name Alo: light left for someone who might bring it back. The Academy took its name from the last sunset she saw before leaving the Moon. The player places the log beside the first seed packet, the consented identity page and the current founder ledger. The mystery now has a complete chain, not one last invented password.

Mei holds Alo's pressed petal near its case without pretending it can hear. The reserve beside them contains descendants' possible futures, while the living garden contains present responsibilities. Kai asks what their own final report should say. The player selects a draft sentence, then supports it with an already checked action. Meaning cannot substitute for the remaining storm plan. When the log ends, the forecast still has four steps left, and the crew returns to them together.

**Exact dialogue**

- `EX-CH07-S07-L01` **Noor (historical recording):** I'm calling the seeds Alo, light.
- `EX-CH07-S07-L02` **Mei:** The name was a hope, not a prediction.
- `EX-CH07-S07-L03` **Kai:** Then our report needs more than a good line.
- `EX-CH07-S07-L04` **Amara:** It needs the next checked step.

**Required player actions**

1. Read or hear the labelled local archive.
2. Connect name, packet and Academy history.
3. Support a report sentence with checked evidence.

**Decision study and planned feedback**

Which draft claim can the crew support now?
- **We have already survived every wave:** The remaining four steps contradict that claim.
- **The first wave is complete and the reserve is protected:** The current ledger supports this bounded progress report.

**Convergence:**Final log understood; name and Academy origin resolved; bounded progress report saved..

**Learning loop**

- **Concept:** Progress claims and evidence
- **Predict:** When is a mission finished enough to call complete?
- **Observe:** Compare an inspiring sentence with the actual ledger.
- **Explain:** A meaningful story still needs accurate statements of progress.
- **Transfer:** Report the work completed, not the outcome hoped for.

**Mandatory exit condition:**Final log understood; name and Academy origin resolved; bounded progress report saved.
**Evidence boundary:**Fiction. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_07.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH07-S08 — The Highest Line on the Chart
**Target:**10 minutes. **Location:**Safe Room integrated control panel. **POV:**Kai. **Story time:**Steps 3–6; 14 February–16 February 01: 12. **Legacy provenance:**`SC-0704`.

The peak arrives in steps three and four. On the chart, the game exposure multiplier rises, but the prepared shielding still performs the job predicted for it. The player checks the complete effective shield rather than judging safety from a frightening graph shape. No glowing radiation animation tells the player to run outside.

Kai confirms each essential load before commitment. Amara updates five-person air and food draw. Mei checks the living crops and keeps the founder reserve separate. Rafi verifies that shielding cargo remains installed. A player who proposes an early drain sees its consequence in preview and can revise locally before the next step.

The tail occupies steps five and six. Only after the sixth exposure is sampled does the scheduled drain return water toward the garden. The baseline result matches the established chapter contract; earned modifiers, when present, are applied once and shown. No extra income appears in the dark. By the final line, the player can explain which earlier decisions mattered and why the same water could protect different needs at different times.

**Exact dialogue**

- `EX-CH07-S08-L01` **Rafi:** Peak on the chart. Check the shield.
- `EX-CH07-S08-L02` **Kai:** No new solar income.
- `EX-CH07-S08-L03` **Amara:** Five-person draw still applies.
- `EX-CH07-S08-L04` **Mei:** Final exposure first. Then return the water.

**Required player actions**

1. Forecast and execute steps three through six.
2. Check shield before each exposure.
3. Apply final drain after step-six sampling.

**Decision study and planned feedback**

The peak chart rises. Which action is supported?
- **Remove cargo to make room at the console:** The shield forecast shows the lost protection; revise before commitment.
- **Retain water and cargo through exposure:** The forecast preserves the established protection and return sequence.

**Convergence:**All six steps complete with crew, crops and founder 30 protected..

**Learning loop**

- **Concept:** Integrated execution under pressure
- **Predict:** Does a high hazard line prove a prepared shelter failed?
- **Observe:** Compare hazard, effective shield and resulting game exposure.
- **Explain:** Risk depends on protection and exposure, not hazard display alone.
- **Transfer:** Use the relevant model instead of reacting to visual alarm.

**Mandatory exit condition:**All six steps complete with crew, crops and founder 30 protected.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_07.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH07-S09 — A Different Silence
**Target:**10 minutes. **Location:**Aurora local network and uplink diagnostic. **POV:**Amara. **Story time:**16 February, after 01: 12 through the separated clearance-reading interval. **Legacy provenance:**`SC-0705`.

The storm steps end, but Rao does not answer. Kai hears Rafi clearly across the corridor, and the garden continues sending local data. The player must diagnose those facts before calling every radio broken. The failed path leads outward through the exposed Earth-uplink feedthrough.

The diagnostic compares local network pass, direct-dish path fail and feedthrough fail. A correct protected isolation did not guarantee that every exposed component would survive the authored incident. The game does not secretly blame the player for damage written into the chapter. Choosing a local-radio reset leaves the external failure unresolved; selecting the external branch directs the next test correctly.

Travel remains blocked until two below-threshold scenario readings, separated by the required interval, clear later exterior preparation. One reassuring sample is not enough. Amara records the second result and saves the relay-bypass diagram. The stable habitat retains local control, stored procedures and the reserve it needs for continued operation. Silence has a defined boundary. The player can now plan a repair without pretending an unanswered message reached Earth.

**Exact dialogue**

- `EX-CH07-S09-L01` **Kai:** I can hear Rafi. Earth cannot hear us.
- `EX-CH07-S09-L02` **Amara:** Local pass. External path failed.
- `EX-CH07-S09-L03` **Ferreira:** Correct isolation was still the right decision.
- `EX-CH07-S09-L04` **Rafi:** Two clear readings before outside preparation.

**Required player actions**

1. Compare local, dish and feedthrough tests.
2. Identify the external failed branch.
3. Obtain both required route-clear readings.

**Decision study and planned feedback**

Which fault hypothesis matches all observations?
- **The whole local network failed:** Local voice and garden telemetry contradict it.
- **The Earth-uplink feedthrough failed:** Independent branch tests support the diagnosis.

**Convergence:**External branch diagnosed; two route readings clear later work; no invented Earth reply..

**Learning loop**

- **Concept:** Localising faults through contrast
- **Predict:** Which failure explains both what works and what does not?
- **Observe:** Compare independent communication paths.
- **Explain:** A diagnosis must fit successful as well as failed tests.
- **Transfer:** Use unaffected systems to narrow a fault.

**Mandatory exit condition:**External branch diagnosed; two route readings clear later work; no invented Earth reply.
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
