# EX-M0301 — Find the Falling Line

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Mandatory mission.**



## Assignment

Compare independent instruments and approve the smallest supported isolation. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.

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

Own this mission's scene composition/content bindings and targeted integration tests; proposed root `game/scenes/chapters/ch03/`. Shared state, simulation, UI and characters remain owned by their SYS/UI/ASSET tasks.

Prerequisite `EX-M0204`; SYS02..08; chapter puzzles P-05, P-06; owning location/asset/UI tasks. If a service is not ready, coordinate one contract-backed fixture and keep the real integration gate unverified.


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

Chapter 3:**Moon quake**; dates: 6 May-21 October 2046, with explicit repair, harvest and generation gates; chapter target: 85 minutes.

The crew localises and repairs a quake-damaged service spur, safely investigates an old seedling annex, verifies a future vault map and completes Alo harvest. Exactly 42 founder seeds become 12 planting plus 30 reserve, followed by a documented multi-generation care bridge.

Emotional arc:Alarm -> uncertainty admitted -> evidence-based control -> discovery -> grief -> continuation..

This mission target: 20 active minutes. Predecessor:`EX-M0204`. Successor:`EX-M0302`. Chapter puzzle families: P-05, P-06; reuse their single shared implementations and map the actual relevant stages.

### EX-CH03-S01 — The Red Shape on the Screen
**Target:**6 minutes. **Location:**Atmosphere service corridor. **POV:**Amara. **Story time:**2046-05-06 22: 05 UTC. **Legacy provenance:**`SC-0301`.

The oxygen-tank symbol is red. Amara reads it once, then again, while the player hears the familiar fans continue. The quake has stopped, but a warning still needs a reason. Reaching for the most dramatic valve would turn an interpretation into an action before the evidence is ready.

Rafi retrieves the independent mechanical gauge. The player checks its reference position, compares the main display with the local instrument and records the disagreement. The station remains in a controlled local response state. Nobody removes a helmet or enters an unverified space to create a thrilling shortcut. Kai offers a guess; Amara writes it under hypothesis rather than fault.

Mei checks the garden's local sealed atmosphere and reports that its chamber is separate from the room feed. That observation narrows what a garden-line isolation could affect. The player puts a simplified piping diagram beside the two readings and marks the locations each instrument actually measures. For the first time, Amara says she does not yet trust her interpretation. The admission does not make her less useful. It gives the team a question precise enough to test, and a safe reason to leave the valve untouched for one more check.

**Exact dialogue**

- `EX-CH03-S01-L01` **Amara:** The panel says tank. I do not trust the diagnosis yet.
- `EX-CH03-S01-L02` **Kai:** Can we close the red thing?
- `EX-CH03-S01-L03` **Rafi:** Gauge first. A colour is not a pipe.
- `EX-CH03-S01-L04` **Mei:** The plants keep their own sealed atmosphere while we check the room feed.

**Required player actions**

1. Check gauge reference and compare independent readings.
2. Locate each sensor on the piping diagram.
3. Confirm local plant-chamber separation before proposing isolation.

**Decision study and planned feedback**

What does the warning establish?
- **The tank is definitely leaking:** The independent reading does not support that conclusion; the hypothesis remains rejected before action.
- **The displayed diagnosis needs localisation:** The player opens the comparison and tap test instead of closing an unverified valve.

**Convergence:**Both studies converge on collecting independent pressure evidence before intervention..

**Learning loop**

- **Concept:** A warning and its diagnosis are different claims.
- **Predict:** Does a red tank icon locate the leak?
- **Observe:** The independent gauge and panel can disagree.
- **Explain:** Investigating uncertainty is a scientific strength.
- **Transfer:** Check a surprising instrument claim against an independent reference.

**Mandatory exit condition:**Reference checked, warning recorded and sensor locations understood.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_03.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH03-S02 — Three Taps, One Falling Line
**Target:**7 minutes. **Location:**Atmosphere diagnostic taps. **POV:**Amara. **Story time:**2046-05-06 22: 10 UTC. **Legacy provenance:**`SC-0301`.

Three labelled taps connect the simplified diagram to real service points. The player takes readings in a controlled sequence, recording the same observation interval at each. The main tank holds while the garden spur falls. A third point helps confirm which side of the branch contains the change. These are game profiles, not instructions for repairing real pressure equipment.

Kai traces the lines with his finger and initially puts the fault upstream of the wrong junction. The player tests that drawing against all three readings. It explains one observation but fails another. Amara does not simply replace his answer with her own. She asks which predicted reading would distinguish the two locations.

The comparison turns a red symbol into a narrow fault region. Mei asks whether isolating the branch will remove the plants' atmosphere. Rafi reads back the local-chamber check completed earlier. The crew can now reason from the same diagram rather than from four separate fears. The player saves the three readings with their positions and marks the proposed isolation boundary. The next action will be justified by what changes on each side, not by who sounded most certain.

**Exact dialogue**

- `EX-CH03-S02-L01` **Kai:** If the fault is here, this tap should fall too.
- `EX-CH03-S02-L02` **Amara:** It does not. Keep that observation.
- `EX-CH03-S02-L03` **Mei:** And our chamber check still applies?
- `EX-CH03-S02-L04` **Rafi:** Yes. Local plant atmosphere remains isolated from this room spur.

**Required player actions**

1. Read all three taps under the same comparison conditions.
2. Test two fault locations against their predicted readings.
3. Mark the smallest supported isolation region.

**Decision study and planned feedback**

Which fault location explains all three taps?
- **Main tank upstream:** The predicted pressure pattern conflicts with the stable main-tank reading.
- **Garden service spur:** The falling branch and stable trunk match this localised hypothesis.

**Convergence:**The unsupported location is rejected in the paused diagnostic view before any valve is touched..

**Learning loop**

- **Concept:** A diagnostic hypothesis must explain all observations.
- **Predict:** Which tap should fall if the tank itself is leaking?
- **Observe:** Only the branch profile matches the recorded pattern.
- **Explain:** A theory that fits one reading may fail the rest.
- **Transfer:** Use several observations to distinguish competing explanations.

**Mandatory exit condition:**Three readings saved and supported fault region identified.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_03.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH03-S03 — Choose the Smallest Safe Boundary
**Target:**7 minutes. **Location:**Isolation preview board. **POV:**Rafi. **Story time:**2046-05-06 late evening UTC. **Legacy provenance:**`SC-0302`.

The player places the proposed isolation on a paused copy of the atmosphere diagram. One preview closes the habitat trunk. Another isolates the garden spur while leaving the main habitat supplied. Both drawings stop flow somewhere, but only one preserves the required services while targeting the supported fault.

Amara asks the player to predict the gauge pattern before running either preview. The simulation then shows the changed lines and the services affected. A mistaken plan is informative because it remains a preview; the crew does not pay for an educational comparison with real harm. Rafi marks the approved sequence and the rollback condition beside it.

Ferreira's Earth channel is available for this authored contact window. She sends the relevant technical repair diagram immediately. It contains no personal confession and no missing procedure withheld behind a story puzzle. Kai checks the diagram against the physical labels rather than assuming an old drawing must still match the room. The team finishes with an agreed isolation, a check that will prove it worked and a way to stop if it does not. Mystery has no priority over a service line that needs making safe.

**Exact dialogue**

- `EX-CH03-S03-L01` **Rafi:** Smallest supported boundary. Keep the habitat supplied.
- `EX-CH03-S03-L02` **Amara:** Predict the gauges before running the preview.
- `EX-CH03-S03-L03` **Ferreira (Earth link):** Repair diagram sent. Safety information does not wait.
- `EX-CH03-S03-L04` **Kai:** The labels match the actual branch. Ready for the controlled step.

**Required player actions**

1. Compare trunk and spur isolation in a paused preview.
2. Predict gauge changes and service consequences.
3. Verify current labels against supplied repair drawings and define rollback.

**Decision study and planned feedback**

Which isolation is justified?
- **Habitat trunk:** The preview removes required service more broadly than the evidence supports.
- **Garden spur:** The preview preserves the habitat while targeting the falling branch.

**Convergence:**Only the supported branch sequence is eligible for physical confirmation..

**Learning loop**

- **Concept:** An intervention should be justified and proportionate.
- **Predict:** Which services does each isolation remove?
- **Observe:** The preview distinguishes broad interruption from targeted isolation.
- **Explain:** A useful repair plan considers collateral effects and rollback.
- **Transfer:** When debugging a system, isolate the smallest supported cause before changing everything.

**Mandatory exit condition:**Supported branch isolation and rollback check approved.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_03.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.

### Cross-mission continuity
- Immediate repair passes by May 7 dawn; safe camera viewing follows May 7; extended checks precede suited entry May 8.
- Ferreira supplies safety information without a premature personal confession or identification of N.
- The 2034 annex contains young, unflowered seedlings with curled leaves only: no flower buds, flowers, pollination or seed production.
- Maturity is checked May 16, followed by a controlled five-day dry-down and May 21 harvest: exactly 42=12+30.
- The later garden contains descendants; the original Alo never revives.
- The May-to-Octobertransition explicitly covers care, repeated compatible pollination, generation changes, maintenance and scheduled supplies.

### Production constraints
- Use a paused diagnostic copy for contrasting hypotheses before physical intervention.
- Keep annex entry boundary and separate support positions visible.
- Treat natural plant maturity quietly; no collapse or resurrection spectacle.
- All 85 minutes are mandatory linked play. The May-to-Octoberbridge uses distinct observation and planning checks rather than idle waiting.

### Chapter bridge
On October 21 the current descendants are ready for the saved trait comparison, and Rafi must turn an old map into a safe two-person field mission.


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
