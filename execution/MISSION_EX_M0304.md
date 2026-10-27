# EX-M0304 — Let the Garden Continue

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Mandatory mission.**



## Assignment

Harvest and allocate 42 seeds, plant 12 and protect 30, then account for care and descendants through October. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.

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

Prerequisite `EX-M0303`; SYS02..08; chapter puzzles P-05, P-06; owning location/asset/UI tasks. If a service is not ready, coordinate one contract-backed fixture and keep the real integration gate unverified.


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

This mission target: 23 active minutes. Predecessor:`EX-M0303`. Successor:`EX-M0401`. Chapter puzzle families: P-05, P-06; reuse their single shared implementations and map the actual relevant stages.

### EX-CH03-S10 — Forty-Two Sounds on a Tray
**Target:**7 minutes. **Location:**Dry-harvest bench. **POV:**Mei. **Story time:**2046-05-21 UTC. **Legacy provenance:**`SC-0305`.

A dry petal rests against the chamber wall. The player verifies the final drying condition, then opens the mature pods over a contained tray. Small seed sounds replace the music for a moment. Alo has naturally finished her life; the scene does not revive her or present ordinary maturity as a preventable failure.

The player groups and counts the harvest, then cross-checks the total against the collected record. Forty-two seeds become two allocations: twelve for planting and thirty for the protected founder reserve. A test layout that double-counts one group fails the reconciliation before anything is sealed. Counting is a shared responsibility, not a trick about fast clicking.

Mei says she thought good care would mean longer. Amara answers that it allowed the plant to finish. Kai asks whether they should wait; Mei asks them to stay. The player sleeves the pressed petal and places its label beside the lineage record. The emotional outcome and the numerical ledger belong in the same scene. Alo is gone as one plant, but the work has produced a future that would not exist without her and Tara. The final total is read aloud before either seed container leaves the bench.

**Exact dialogue**

- `EX-CH03-S10-L01` **Mei:** I thought keeping her alive meant longer.
- `EX-CH03-S10-L02` **Amara:** It meant she could finish.
- `EX-CH03-S10-L03` **Kai:** Do you want us to wait?
- `EX-CH03-S10-L04` **Mei:** Stay. Then help me count.

**Required player actions**

1. Verify dry-down and harvest into the contained tray.
2. Reconcile exactly 42 seeds into 12 planting  and 30 reserve.
3. Archive the petal and Alo-times-Tara lineage record.

**Decision study and planned feedback**

Which allocation can be sealed?
- **Twelve planting plus thirty reserve:** The groups reconcile exactly with the observed harvest.
- **Twelve planting plus a duplicate counted group in reserve:** The ledger rejects the mismatch and asks for recount before sealing.

**Convergence:**All physical containers leave with exactly 42=12+30; no seed is created or lost through the study..

**Learning loop**

- **Concept:** Conservation applies to inventories and biological continuity.
- **Predict:** Does every grouped layout match the same physical harvest?
- **Observe:** The reconciliation detects duplicated counting.
- **Explain:** A ledger must account for each physical item exactly once.
- **Transfer:** Reconcile totals before distributing shared materials.

**Mandatory exit condition:**Harvest verified,42=12+30 reconciled and petal archived.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_03.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH03-S11 — The Next Small Thing
**Target:**8 minutes. **Location:**Garden planting rack and reserve store. **POV:**Mei. **Story time:**2046-05-21 after harvest UTC. **Legacy provenance:**`SC-0306`.

Twelve labelled positions wait on the next tray. Mei sets the first allocated seed into a cassette while Amara reads the parent line: Alo times Tara. The old flower's name does not erase the partner that helped make the harvest. Rafi holds the thirty-seed reserve container beside its seal record until the player confirms it has not been drawn from.

Planting twelve is an allocation already made, not a new reward generated by revisiting the bench. The player matches each planted position to the inventory and checks the separate protected reserve. A prediction view shows how removing another founder seed would change the ledger, so the crew can distinguish current planting from future descendants.

Kai asks what they will call the new plants. Mei lets everyone choose a dedication for the tray after the scientific labels are complete. A warm name can coexist with a precise lineage. The first new seed receives the same close framing as Alo's original planting, then the view widens to show all four cadets. The work feels less like replacing a lost mascot and more like taking responsibility together. The player finishes by putting the pressed petal somewhere it can be seen without being mistaken for a living original plant.

**Exact dialogue**

- `EX-CH03-S11-L01` **Amara:** Parent line first: Alo times Tara.
- `EX-CH03-S11-L02` **Rafi:** Thirty founder seeds remain sealed.
- `EX-CH03-S11-L03` **Kai:** May one plant be Very Important Scientific Plant?
- `EX-CH03-S11-L04` **Mei:** After its lineage label. Then yes.

**Required player actions**

1. Plant the allocated 12 founder seeds into 12 labelled positions.
2. Verify the separate 30 seed reserve and seal record.
3. Add a tray dedication without replacing scientific identity.

**Decision study and planned feedback**

Which planting request fits the ledger?
- **Plant only the allocated twelve:** The reserve remains 30 and every planted slot has a source.
- **Plant a thirteenth founder seed without updating allocation:** The preview exposes the reserve mismatch and refuses the unrecorded draw.

**Convergence:**The canonical twelve are planted and thirty protected; dedication choices do not alter quantities..

**Learning loop**

- **Concept:** A name, an album and a physical inventory are different records.
- **Predict:** Does naming a plant create another seed?
- **Observe:** Only physical allocations change the inventory.
- **Explain:** Identity and narrative rewards must not corrupt conservation.
- **Transfer:** Keep labels, photographs and counted objects distinct in a project.

**Mandatory exit condition:**Twelve positions planted, thirty reserve sealed and lineage preserved.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_03.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH03-S12 — Five Months Are Made of Days
**Target:**8 minutes. **Location:**Aurora dated maintenance and lineage board. **POV:**Amara. **Story time:**2046-05-21 through October 21 UTC. **Legacy provenance:**`SC-0306`.

The calendar does not jump from one bright tray to another without an account. The player prepares a maintenance handover covering crop care, repeated compatible pollination, stored procedures, resupply planning and the safe operation of the habitat. Each dated chapter of the montage contains an observation or planning check that belongs to the intervening work.

The family tree shows several generations replacing annual plants. Twelve current descendants in October are not the twelve original seedlings kept unchanged for five months. The founder reserve remains its own protected record, while later harvests and care appear as ordinary generation records without invented fixed totals. Scheduled supplies and approved maintenance keep the crew supported; one mustard plant never becomes its food or oxygen system.

Mei places the pressed petal beside the first lineage photograph. Amara opens the saved stem-colour prediction and leaves it attached to a future October comparison. The old vault map moves from a mystery page to a prepared survey board, with current route and return checks still required. When the final date card settles on October 21, the garden is larger and the corridor familiar. The crew has not escaped the ordinary work between adventures. That work is what makes the next expedition possible.

**Exact dialogue**

- `EX-CH03-S12-L01` **Kai:** October already?
- `EX-CH03-S12-L02` **Amara:** Not already. Here are the days in between.
- `EX-CH03-S12-L03` **Mei:** These are descendants. Alo is in their lineage, not hiding in a pot.
- `EX-CH03-S12-L04` **Rafi:** And the map now has a preparation list, not a departure stamp.

**Required player actions**

1. Complete dated care, generation and habitat-maintenance handovers.
2. Reconcile founder reserve separately from descendant records and scheduled supplies.
3. Carry the stem prediction and current route-verification tasks into October.

**Decision study and planned feedback**

Which continuity account is supported?
- **The same annual plants simply stay unchanged for five months:** The lineage and care records reject this account.
- **Dated replacement generations with repeated care and planned supplies:** The records explain the October descendants and supported crew.

**Convergence:**The October garden is a continuing lineage; no original Alo is restored and no instant food system is implied..

**Learning loop**

- **Concept:** Long transitions need physical and biological continuity.
- **Predict:** What must be explained across several months?
- **Observe:** Care, generation changes, resupply and maintenance remain recorded.
- **Explain:** A believable outcome includes the work connecting its dates.
- **Transfer:** For a long project, plan handovers and resource continuity between milestones.

**Mandatory exit condition:**Dated continuity ledger complete;October 21 current descendants and survey preparation established.
**Evidence boundary:**Fiction. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_03.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.

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
