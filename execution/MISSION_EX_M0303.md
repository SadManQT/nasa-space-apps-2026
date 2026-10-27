# EX-M0303 — Read What Was Unfinished

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Mandatory mission.**



## Assignment

Enter safely, establish seedling-stage history, verify map provenance and begin mature-pod drying. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.

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

Prerequisite `EX-M0302`; SYS02..08; chapter puzzles P-05, P-06; owning location/asset/UI tasks. If a service is not ready, coordinate one contract-backed fixture and keep the real integration gate unverified.


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

This mission target: 21 active minutes. Predecessor:`EX-M0302`. Successor:`EX-M0304`. Chapter puzzle families: P-05, P-06; reuse their single shared implementations and map the actual relevant stages.

### EX-CH03-S07 — The Garden That Never Opened
**Target:**7 minutes. **Location:**Cold annex and warm-side support station. **POV:**Mei. **Story time:**2046-05-08 after extended checks UTC. **Legacy provenance:**`SC-0304`.

The suited entry begins only after the continuing checks are complete. Mei and Rafi inspect from the cold side while Kai and Amara support the controlled operation from the warm-side station. Their local radios stay available. The player sees the boundary crossing rather than appearing inside through an unexplained cut.

The trays contain frozen seedlings. None has flowered. Mei first sees the shape she expected to find, then corrects it when the growth chart and curled seedling leaves agree. A first bloom in their fictional lunar history remains a real achievement even though earlier people tried. The old trial is a beginning interrupted, not a secretly completed garden that erases the current story.

The player records evidence without pulling the plants apart. A service tag dates the trial to 2034; the route sheet was filed before evacuation. No clue demands a perilous recovery at the last moment of a retreat. Rafi reads back their return condition before the scene lingers on the unfinished labels. Mei leaves the tray as it is. Respecting what cannot be repaired is a different kind of care from saving Alo, and the player has to perform it with the same attention.

**Exact dialogue**

- `EX-CH03-S07-L01` **Mei:** I mistook the curled leaves for flowers. They were young seedlings.
- `EX-CH03-S07-L02` **Amara (local link):** The growth chart agrees: seedling stage.
- `EX-CH03-S07-L03` **Rafi:** Record it. Leave the material undisturbed.
- `EX-CH03-S07-L04` **Kai (local link):** Return boundary ready when you are.

**Required player actions**

1. Complete cleared suited entry with local support.
2. Compare frozen material and growth chart.
3. Document the interrupted trial without disturbing biological remains.

**Decision study and planned feedback**

Which account fits the evidence?
- **An earlier flowering garden:** The chart and material reject this interpretation.
- **An interrupted seedling trial:** Both independent records support this description.

**Convergence:**The journal retains the supported seedling account and preserves Alo first-bloom continuity..

**Learning loop**

- **Concept:** Expectations can bias observation.
- **Predict:** Do the old trays show what Mei expected?
- **Observe:** The visible stage and dated chart agree against the first impression.
- **Explain:** Changing an interpretation when evidence differs is progress.
- **Transfer:** Describe what is present before writing what you expected to find.

**Mandatory exit condition:**Entry and exit checks complete, seedling-stage evidence saved undisturbed.
**Evidence boundary:**Fiction. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_03.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH03-S08 — A Map Is a Plan to Verify
**Target:**7 minutes. **Location:**Annex chart archive and habitat evidence table. **POV:**Rafi. **Story time:**2046-05-08 through May 16 care transition UTC. **Legacy provenance:**`SC-0304`.

Under a sealed cover lies a route sheet towards a permanently shadowed survey site. A marked storage deposit appears beside an old authorised traversal, with its date before the final evacuation. The player connects the map to the trial records and sees why the vault could have been placed safely on an earlier survey rather than by an impossible last-minute journey.

Kai asks whether they should leave immediately. Rafi brings up current duties, route uncertainty and the need for a prepared return. A map is evidence that somebody planned a journey; it is not certification that the present rover can repeat it unchanged. The player records which details need a future slope, reserve and communications check.

Back in the habitat, care takes priority. Dated visits from May 8 to May 16 show the current pollinated plants developing pods while the annex record is archived. The chapter advances through purposeful observations, not a blank wait. Mei compares actual pod development with the life-cycle sequence assembled earlier. The two investigations now support each other: the old map gives a future objective, and the living experiment teaches when patience is required before starting it.

**Exact dialogue**

- `EX-CH03-S08-L01` **Kai:** We have a map. Can we go now?
- `EX-CH03-S08-L02` **Rafi:** We have evidence for a route. We still need a verified return plan.
- `EX-CH03-S08-L03` **Amara:** The deposit date is earlier than the retreat.
- `EX-CH03-S08-L04` **Mei:** And first we finish caring for the garden we have.

**Required player actions**

1. Link deposit date, authorised survey and stored route.
2. Identify present-day route checks that the old map cannot satisfy.
3. Complete dated pod-development observations through May 16.

**Decision study and planned feedback**

What does the recovered map authorise?
- **Immediate departure:** The planning board rejects this because current slope, reserve and return evidence is missing.
- **A prepared future survey objective:** The map is retained while present-day verification tasks are created.

**Convergence:**The expedition stays home until Chapter 4 preparation; current plant care continues..

**Learning loop**

- **Concept:** Historical plans need present verification.
- **Predict:** Does an old route prove current safe passage?
- **Observe:** The board separates provenance from present operational requirements.
- **Explain:** Reliable records can still be insufficient for a new decision.
- **Transfer:** Check whether old instructions apply to today’s equipment and conditions.

**Mandatory exit condition:**Map provenance saved, future checks listed and maturity-care transition confirmed.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_03.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH03-S09 — The Pod Is Not Ready Because We Are
**Target:**7 minutes. **Location:**Garden maturity and drying bench. **POV:**Mei. **Story time:**2046-05-16 UTC. **Legacy provenance:**`SC-0305`.

Alo has changed while the crew repaired the room and read the annex. The flowers have given way to pods. Mei checks them against the maturity record instead of reaching for the harvest tray. Their experiment is succeeding, but success has made the plant less like the portrait everyone remembers.

The player compares maturity observations, checks the provided moisture profile and begins the canonical controlled dry-down. A preview contrasts opening the pods immediately with waiting for verified drying conditions. The premature path does not execute on the living plant; it shows why the planned sequence needs evidence. The five-day interval is named on the date card before the player accepts it.

Kai offers to change a lamp setting to make Alo look better. Amara distinguishes the end of a rapid plant's life cycle from a fault that can be repaired by more power. Mei does not need to understand every feeling before carrying out good care. She records the stage, approves the safe drying sequence and asks the others to remain nearby. The player completes the observation that allows the next step, learning that protecting a living process sometimes means allowing it to finish rather than trying to keep one image unchanged.

**Exact dialogue**

- `EX-CH03-S09-L01` **Mei:** The photograph was a flower. This is still Alo.
- `EX-CH03-S09-L02` **Kai:** Can we make the lamp help?
- `EX-CH03-S09-L03` **Amara:** This is maturity, not the old cold alarm.
- `EX-CH03-S09-L04` **Rafi:** We can stay while you do the checks.

**Required player actions**

1. Verify maturity observations and the P-06 moisture profile.
2. Compare immediate opening with evidence-based dry-down.
3. Confirm the explicit May 16-to May 21 drying transition.

**Decision study and planned feedback**

When should the pods be opened?
- **Immediately after the maturity inspection:** The paused comparison rejects harvesting before the drying criterion.
- **After the controlled five-day dry-down and final check:** The sequence preserves the canonical maturity-to-harvest order.

**Convergence:**Only the verified dry-down route reaches physical harvest; no real seeds are damaged by a study choice..

**Learning loop**

- **Concept:** Maturity, drying and harvest are distinct stages.
- **Predict:** Does a mature pod automatically mean harvest-ready material?
- **Observe:** The drying profile gives a separate readiness criterion.
- **Explain:** A process can be biologically complete but need another handling step.
- **Transfer:** Use readiness evidence instead of rushing to the next attractive task.

**Mandatory exit condition:**Maturity verified, dry-down configured and dated transition accepted.
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
