# EX-M0704 — The Days That Make a Journey

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Mandatory mission.**



## Assignment

Maintain stable local operations and physically prepare the relay bypass. Implement the exact three-scene route quoted below inside the shared campaign, with physical actions and learning evidence.

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

Prerequisite `EX-M0703`; SYS02..08; chapter puzzles P-13, P-14; owning location/asset/UI tasks. If a service is not ready, coordinate one contract-backed fixture and keep the real integration gate unverified.


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

This mission target: 25 active minutes. Predecessor:`EX-M0703`. Successor:`EX-M0801`. Chapter puzzle families: P-13, P-14; reuse their single shared implementations and map the actual relevant stages.

### EX-CH07-S10 — A Base That Can Wait Safely
**Target:**8 minutes. **Location:**Aurora maintenance and care planning desk. **POV:**Mei. **Story time:**16 February–March, dated stable-operation gates. **Legacy provenance:**`SC-0706`.

A radio repair cannot become an excuse to ignore the weeks before departure. Mei opens a required stable-operation board. The player must show how the station continues local care, planned food supply, atmosphere maintenance and scheduled observation while the direct Earth uplink remains unusable. This is not an unmentioned life-support emergency stretched across two months.

Dated records show which stores are available and which routine operations consume them. The long interval does not multiply April's seven-shift game recipe across every hour. It uses the campaign's explicit maintenance and ration ledger. The player rejects a draft that assumes an Earth reply delivered a missing instruction; that reply has never arrived. Stored procedures and local expertise supply the actual plan.

Cotton grows under its own recorded care. Current mustard plants carry generation labels rather than the original Alo's name alone. Amara checks the founder reserve without opening it, then compares the retained vault register. Three dated maintenance gates test changed observations before time advances. The player earns the calendar transition by accounting for stability, not by clicking through an unexplained montage.

**Exact dialogue**

- `EX-CH07-S10-L01` **Mei:** The garden needs ordinary days too.
- `EX-CH07-S10-L02` **Amara:** Account for the interval, not just the climax.
- `EX-CH07-S10-L03` **Kai:** No reply from Earth is in this plan.
- `EX-CH07-S10-L04` **Ferreira:** We have local procedures and stores.

**Required player actions**

1. Reconcile care, ration and maintenance ledgers.
2. Replace a plan that assumes missing Earth guidance.
3. Pass three dated stable-operation gates.

**Decision study and planned feedback**

What supports continued local operation?
- **Wait for an Earth reply before maintaining systems:** The failed uplink makes this dependency unsupported.
- **Use stored procedures and verified local supplies:** The ledger accounts for continued care while repair preparation proceeds.

**Convergence:**Local stability and supplies reconciled through dated February-to-March gates..

**Learning loop**

- **Concept:** Continuity and long-duration planning
- **Predict:** What must continue between major events?
- **Observe:** Check dated stores, operations and local instructions.
- **Explain:** An expedition needs a supported bridge between crises.
- **Transfer:** Account for intervals that a dramatic narrative might skip.

**Mandatory exit condition:**Local stability and supplies reconciled through dated February-to-March gates.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_07.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH07-S11 — Make the Road Hear Us
**Target:**9 minutes. **Location:**Local fabrication bench and surveyed-route simulator. **POV:**Rafi. **Story time:**March–7 April, authored preparation. **Legacy provenance:**`SC-0706`.

The spare controller from December comes out of its locker, still sealed and still carrying Kai's compatibility note. The player checks it against the Malapert service housing. A controller alone cannot connect a summit to a base hidden by terrain. The bypass needs an Aurora-to-summit path and a summit-to-Earth path.

Rafi lays three repeater sites along the surveyed road model. A straight line drawn over a ridge fails the simulator's obstruction check. The player adjusts the surveyed installation plan until neighbouring links are supported, while retaining the established safe road rather than inventing a shortcut. The final approach will test the actual chain again. A desktop plan is preparation, not proof of deployment.

At the bench, the player loads the spare battery, matches service connectors and runs a controlled known-content echo demonstration through the prepared local hardware. A wrong connector stays on the bench with an explanatory mismatch. Ferreira signs the isolation checklist; Kai labels the packed controller. The dated preparation ends with physical equipment and an intelligible route, so the finale will use things the player helped make ready.

**Exact dialogue**

- `EX-CH07-S11-L01` **Rafi:** A high dish still needs to hear Aurora.
- `EX-CH07-S11-L02` **Kai:** Every neighbouring link, not one magic line.
- `EX-CH07-S11-L03` **Ferreira:** Check the housing before packing the spare.
- `EX-CH07-S11-L04` **Amara:** A bench pass is not field verification.

**Required player actions**

1. Test terrain-obstructed repeater placements.
2. Verify controller and battery compatibility.
3. Run and save a bench known-content echo demonstration.

**Decision study and planned feedback**

Which topology can bypass the failed path?
- **Summit dish points only toward Earth:** Aurora's signal has no verified way to reach it.
- **Local repeater chain plus Earth dish:** The simulation can test each required leg separately.

**Convergence:**Compatible spare, battery, three-site route and bench-test record packed; field checks still required..

**Learning loop**

- **Concept:** Networks and line of sight
- **Predict:** Does a clear Earth view guarantee a base connection?
- **Observe:** Compare terrain-obstructed and supported two-leg paths.
- **Explain:** A relay needs verified connectivity at both ends.
- **Transfer:** Trace every link in a network before trusting its endpoint.

**Mandatory exit condition:**Compatible spare, battery, three-site route and bench-test record packed; field checks still required.
**Evidence boundary:**Simulated. Sources:`game-design/06_SCENE_SCRIPTS/CHAPTER_07.md`, `game-design/03_STORY_TIMELINE.md`, `game-design/08_PUZZLE_DESIGNS.md`.


### EX-CH07-S12 — Who Stays With the Garden
**Target:**8 minutes. **Location:**Aurora departure board and rover loadout. **POV:**Mei. **Story time:**7 April to 8 April 00: 00. **Legacy provenance:**`SC-0706`.

Five names face two destination boards. Ferreira, Kai and Rafi take the rover. Mei and Amara remain at Aurora. The player assigns no invisible extra operator and sends no cadet to two places at once. Rafi reads the planned journey: twenty-four hours outward, three for repair, twenty-four back, with seventy-two hours of independent provisions.

Amara opens the home-night ledger. For the first thirty-three dark hours, two people will breathe at the base. The three travellers return for the final three hours before dawn. The player checks that change before signing either team's plan. A flat four-person copy from April would count the wrong people twice.

Mei and Kai exchange duplicate route and shelter checklists. He asks for the small guide light, and she points to its existing place in the schedule. No promise requires wasteful brightness. The player confirms packed equipment, local check-in markers and the stable preparation record. The calendar reaches departure only after those checks. The two teams separate with a shared plan that can still be read when the Earth channel is silent.

**Exact dialogue**

- `EX-CH07-S12-L01` **Ferreira:** Kai and Rafi with me. Mei and Amara hold Aurora.
- `EX-CH07-S12-L02` **Amara:** Two at home, then five for the last three hours.
- `EX-CH07-S12-L03` **Kai:** Keep the small guide light.
- `EX-CH07-S12-L04` **Mei:** It is already in the plan.

**Required player actions**

1. Assign exact rover and home teams.
2. Reconcile fifty-one-hour travel with seventy-two-hour supplies.
3. Check the two-to-five home occupancy transition.

**Decision study and planned feedback**

Which home-night occupancy model fits the plan?
- **Four occupants for the whole night:** It disagrees with both departure and return rosters.
- **Two for 33 hours, then five for 3 hours:** The explicit transition matches the planned return before dawn.

**Convergence:**Team assignments, travel provisions, home occupancy and dated preparation all signed..

**Learning loop**

- **Concept:** Multiple teams and changing occupancy
- **Predict:** Who consumes each reserve at each time?
- **Observe:** Compare location roster and time segments.
- **Explain:** Resources follow actual people and transitions.
- **Transfer:** Split a budget when the system's occupancy changes.

**Mandatory exit condition:**Team assignments, travel provisions, home occupancy and dated preparation all signed.
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
