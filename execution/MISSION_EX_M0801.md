# EX-M0801 — The Long Road

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Mandatory mission.**



## Assignment

Provision the full round trip, validate terrain and reach the failed marker. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.

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

Own this mission's scene composition/content bindings and targeted integration tests; proposed root `game/scenes/chapters/ch08/`. Shared state, simulation, UI and characters remain owned by their SYS/UI/ASSET tasks.

Prerequisite `EX-M0704`; SYS02..08; chapter puzzles P-15, P-16; owning location/asset/UI tasks. If a service is not ready, coordinate one contract-backed fixture and keep the real integration gate unverified.


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

Chapter 8:**The Lighthouse**; dates: 8–10 April 2047; chapter target: 120 minutes.

A complete round-trip budget and three-repeater road take Ferreira, Kai and Rafi to Malapert while Mei and Amara maintain Aurora. The crew replaces a compatible controller, independently verifies local and Earth legs, checks exact data and restores voices. Noor's first live answer follows proof of the connection. After a dated 24-hour return, all five see the renewing garden and cotton alive at first light.

Emotional arc:Separation → known-road confidence → parallel responsibility → exact repair → chosen reunion → shared homecoming..

This mission target: 30 active minutes. Predecessor:`EX-M0704`. Successor:`EX-M0802`. Chapter puzzle families: P-15, P-16; reuse their single shared implementations and map the actual relevant stages.

### EX-CH08-S01 — Before the Road
**Target:**10 minutes. **Location:**Aurora rover bay and departure board. **POV:**Rafi. **Story time:**8 April 2047,00: 00 departure. **Legacy provenance:**`SC-0801`.

The rover waits with three occupied seats and two people outside its sealed cabin. The player reads every name against a destination: Ferreira, Kai and Rafi travel; Mei and Amara keep Aurora. The separation is visible before the door closes. Nobody will appear at the summit simply because the story needs another speaker.

Rafi reads the journey card aloud. The surveyed route is about one hundred and twenty kilometres each way, with twenty-four hours outward, three for repair and twenty-four back. Independent provisions cover seventy-two hours. The player checks actual packed equipment against the signed preparation record: compatible controller, battery spare, service diagram and three repeater checkpoints.

Mei passes Kai a duplicate home-night checklist. He cannot operate her panel from the rover; he can understand what she is protecting. The player confirms departure only after both destination boards agree. A short time card starts the fictional travel clock while active play moves into the first route problem. The story has earned its journey through the work that put people and equipment here.

**Exact dialogue**

- `EX-CH08-S01-L01` **Rafi:** Twenty-four out. Three repair. Twenty-four back.
- `EX-CH08-S01-L02` **Amara:** Seventy-two hours of independent supplies.
- `EX-CH08-S01-L03` **Mei:** I have the garden.
- `EX-CH08-S01-L04` **Ferreira:** We have a road, not a heroic shortcut.

**Required player actions**

1. Assign exact three-and-two teams.
2. Compare packed hardware with the preparation manifest.
3. Verify seventy-two-hour provisions before departure.

**Decision study and planned feedback**

Which departure plan is complete?
- **Carry only enough for the outward leg:** The return and repair interval are missing; departure waits.
- **Provision the whole fifty-one-hour plan with margin:** The full route and repair interval fit within seventy-two hours.

**Convergence:**Correct teams, complete loadout and full-round-trip provisions verified..

**Learning loop**

- **Concept:** Whole-mission provisioning
- **Predict:** Does arrival mean the journey is complete?
- **Observe:** Compare outward, repair and return durations.
- **Explain:** Supplies must cover the whole supported operation.
- **Transfer:** Include getting home when planning an outward task.

**Mandatory exit condition:**Correct teams, complete loadout and full-round-trip provisions verified.
**Evidence boundary:**Fiction. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_08.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH08-S02 — The Return Is Already in the Battery
**Target:**10 minutes. **Location:**Rover route-planning console. **POV:**Kai. **Story time:**8 April, departure forecast before cruise. **Legacy provenance:**`SC-0801`.

The route screen offers a shorter-looking line across steeper terrain. Its lower displayed energy cost makes it an attractive mistake. Rafi brings the slope map over the same line, and the player tests both routes under the rover's operating limits. The shortcut's unsupported slope is a hard boundary, not a challenge for more skilful driving.

On the surveyed road, the baseline rover starts with fourteen game units. Five cover outward travel and planned work, five cover the return, leaving four above the two-unit minimum. An earned long-range battery changes the entry capacity once and visibly. It never turns an unsafe slope into a permitted road or replaces the return check.

The player marks reserve that must remain unavailable for decorative loads. Kai points out that saving energy means little if the vehicle cannot safely reach the place where it will be spent. The forecast keeps distance, terrain and reserve on the same page. Only after the player explains the rejected shortcut does cruise begin along the supported route.

**Exact dialogue**

- `EX-CH08-S02-L01` **Kai:** The shorter line looks cheaper.
- `EX-CH08-S02-L02` **Rafi:** Check what its slope permits.
- `EX-CH08-S02-L03` **Ferreira:** A reserve cannot rescue an impossible road.
- `EX-CH08-S02-L04` **Kai:** Then the return stays in the departure budget.

**Required player actions**

1. Compare surveyed and unsupported routes.
2. Reconcile baseline fourteen-minus-five-minus-five reserve.
3. Apply an earned battery modifier once if present.

**Decision study and planned feedback**

Which route can be committed?
- **Shorter steep shortcut:** Slope validation rejects it despite its attractive energy estimate.
- **Surveyed road with return reserve:** Terrain limits and the whole-mission budget both pass.

**Convergence:**Surveyed route and return reserve committed; unsafe shortcut rejected..

**Learning loop**

- **Concept:** Constraints and optimisation
- **Predict:** Is the cheapest estimate always a feasible solution?
- **Observe:** Compare slope validity and round-trip reserve.
- **Explain:** Optimisation operates inside safety and feasibility constraints.
- **Transfer:** Reject a low-cost plan that violates a hard requirement.

**Mandatory exit condition:**Surveyed route and return reserve committed; unsafe shortcut rejected.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_08.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH08-S03 — Markers in the Dark
**Target:**10 minutes. **Location:**Surveyed rover road, first repeater sector. **POV:**Rafi. **Story time:**8 April,00: 00–10: 00 represented by gated cruise. **Legacy provenance:**`SC-0802`.

The first cruise transition ends at a real decision point rather than an empty stretch of driving. Rafi asks the player to match the next marker with the surveyed map and the local bearing. The black sky and long shadows provide scale, but they are not treated as a reliable compass by themselves.

Marker one passes its adjacent-link test. The player sends a short local check-in to Aurora through the prepared chain. Mei's acknowledgement is local radio, not a repaired Earth connection. The packet includes a timestamp and position, so the home team can distinguish a new update from a stored one.

Ahead, marker two is dark. The console still shows a healthy surveyed pad, while an apparent bypass crosses an unsupported cliff route. Kai reaches toward the steering control and stops. The player compares the route record, the failed signal and the remaining reserve before braking at the service zone. The correct next action is a bounded repair on known ground. The crew's growth appears in that pause between seeing a shortcut and taking it.

**Exact dialogue**

- `EX-CH08-S03-L01` **Rafi:** Match the marker, not the silhouette.
- `EX-CH08-S03-L02` **Mei (Aurora local radio):** Position packet received.
- `EX-CH08-S03-L03` **Kai:** Marker two is dark.
- `EX-CH08-S03-L04` **Ferreira:** Stop at the surveyed pad.

**Required player actions**

1. Match map, marker and bearing.
2. Verify marker-one adjacent links.
3. Brake in marker-two's known service zone.

**Decision study and planned feedback**

What does a dark marker justify?
- **Leave the road for the visible bypass:** The terrain overlay shows an unsupported cliff route.
- **Inspect the known pad and local signal:** A stable service point permits a bounded diagnosis.

**Convergence:**Known marker-two pad reached with brake set; correct position packet saved..

**Learning loop**

- **Concept:** Navigation with independent references
- **Predict:** Can appearance alone prove a safe route?
- **Observe:** Compare surveyed map, bearing and marker condition.
- **Explain:** Multiple references constrain a navigation decision.
- **Transfer:** Pause when references disagree instead of inventing a shortcut.

**Mandatory exit condition:**Known marker-two pad reached with brake set; correct position packet saved.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_08.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.

### Cross-mission continuity
- Ferreira, Kai and Rafi rover; Mei and Amara Aurora.
- 120 kilometres each way,24 hours out+3 hours repair+24 hours back=51 hours; provisions 72 hours.
- Depart 8 April 00:00, summit 9 April 00:00, return 9 April 03:00, home 10 April 03:00, dawn 10 April 06:00.
- Base has two occupants for 33 dark hours, then five for 3 hours.
- Founder 30, retainedvault 11 and plantedcotton 1 remain distinct.
- First live Noor voice occurs only after verified dual-link checks.
- MARS is only a post-credit future-story image, with no additional playable task.

### Production constraints
- Explicit viewpoint cards prevent physical teleportation.
- Local rover packets do not imply Earth was repaired early.
- Scenario bearings remain labelled until geometry is verified.
- No real-time 24-hour drive, forced dexterity clock or penalty for assisted controls.
- Final garden exists before dawn; original Alo stays an archived petal and living lineage.

### Chapter bridge
The campaign is complete before any future-story image; Continue opens the safe final garden.


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
