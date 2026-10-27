# P-07 — Survey and Return

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Scientific puzzle.**



## Assignment

Implement this canonical puzzle as an interactive, deterministic component of the main campaign. Preserve the exact rules, hints, result criteria and safe retries below.

Execute this bounded task, integrate it with the current project and produce the acceptance evidence below. First reconcile the snapshot with current files; reuse already approved work and complete the real remaining gap.


## Mandatory shared context

Read [02_SHARED_CONTRACT.md](02_SHARED_CONTRACT.md), [03_SYSTEM_INTERFACES.md](03_SYSTEM_INTERFACES.md), [04_CURRENT_STATE.md](04_CURRENT_STATE.md), [05_ACCEPTANCE_AND_HANDOFF.md](05_ACCEPTANCE_AND_HANDOFF.md). Also read the current [AGENTS.md](../AGENTS.md), [PRODUCTION_HANDBOOK.md](../PRODUCTION_HANDBOOK.md) and newest [HANDOFF.md](../HANDOFF.md) entries. Current locked English-only, faceless plants, anime cast and scientific boundaries override older source wording.


## Inputs to inspect

- [game-design/08_PUZZLE_DESIGNS.md](../game-design/08_PUZZLE_DESIGNS.md)
- [docs/GAMEPLAY_DESIGN_FINAL.md](../docs/GAMEPLAY_DESIGN_FINAL.md)
- [full-game-story/story-data.json](../full-game-story/story-data.json)
- [game-design/10_GAMEPLAY_SYSTEMS.md](../game-design/10_GAMEPLAY_SYSTEMS.md)


## Ownership and dependencies

Own one puzzle model/controller and focused tests. Reuse SYS04 simulation for shared arithmetic, SYS05 transactions, SYS06 dialogue and the appropriate UI panel; do not fork them.

SYS02 content, SYS03 state, SYS04 simulation, SYS05 interactions, SYS07 checkpoints, appropriate room/prop/UI tasks and its owning expansion missions.


## Detailed work sequence

1. Translate source initial state, legal inputs, subchecks and completion predicate into typed data and explicit testable transitions.
2. Agree which shared state/profile fields the puzzle reads/writes; proposed root `game/scripts/puzzles/`. Keep presentation separate from the pure rule model.
3. Build observable equipment/diagram/UI feedback for correct, incorrect, partial and blocked actions, including the documented progressive hints.
4. Implement the real action sequence with keyboard/controller/tap alternatives and timer assistance; no motor precision penalty changes story access.
5. Use the same rule function in preview and commit; protect idempotent costs/evidence and current knowledge.
6. Create source witness/boundary tests, including reset/cancel/paused/reloaded/duplicate input cases. When the source gives numbers, assert exact results, not just non-null states.
7. Embed the puzzle at its actual expansion mission gates and verify the actor/location/time/pressure/inventory implications.
8. Document the versioned inputs, accepted result receipt and next consumer; report any source counterexample without quietly changing rules.


## Task-specific source and implementation detail

## P-07 — Survey and Return

- **Mission / reason:** [M-0401](../game-design/07_MISSION_DESIGNS/M-0401_Where_the_Sun_Cannot_Follow.md) — Plan the cold-trap route, survey ice and retain a return reserve.
- **Location / equipment:** LOC-09; Press uri sed rover, route chart, slope scan, sample cup, calibrated ice scanner.
- **Initial state:** Base E14/20, A8/10, H6, C8, R18; two daylight base shifts use DIM/O0, cost E2 each and breathe A0.5 for two home cadets, ending E18, A7, H6, C8, R16.8. The two rover occupants have an independent 48-hour consumables manifest covering the dated round trip; never charge them again at base. Rover resource 100, mandatory return reserve 30. Routes: A short 8 km cost 35 each way, slope 24°; B ridge 12 km cost 30 each way, max 12°; C shadow 10 km cost 40 each way, slope 18°. Rover design limit 15°.
- **Player instructions and intermediate steps:** Inspect route cards; choose a route satisfying slope AND roundtrip reserve. Use the base-only slope card and rover-only headlight card to agree on the route. Place/test three beacons before blind corners. Drive three 100 m playable segments separated by labelled cruise. On route B stop at reference and sample points: dry reference signal 2; samples 2, 18, 19. Set threshold reference+10=12 and tag the two above threshold; collect one sealed sample.
- **Accepted solution:** B is the only valid route: 100−30−30=40>=30 and 12°<=15°. Calibrate at 2, threshold 12; tag 18 and 19; retain 2 as negative control; collect one positive sample.
- **Incorrect actions and feedback:** Route A fails slope regardless of energy; C fails slope and reserve. Uncalibrated positive reports are marked unverified. Off-road driving stops at a warning boundary, never tumbles into an unwin n able pit.
- **Progressive hints H1 / H2 / H3:** A short road may be too steep. / Check both the return cost and slope. / Choose B, use dry 2, then tag 18 and 19.
- **Difficulty, timing and retry:** Medium; rover checkpoints at each surveyed beacon; samples persist only after sealed save.
- **Completion trigger:** Valid route chosen, three beacons linked, three stops reached, reference recorded, two positives tagged, one sample sealed, return reserve forecast>=30.
- **Narrative consequence / flags:** ice_survey_pending; return_route_B; sample_verified. Resource units are game abstractions.
- **Accessible input:** Every drag or hold also has Select source → Select target → Confirm; every visual observation has a text-equivalent reading. No puzzle requires colour perception, audio frequency discrimination, fast repeated presses or pixel-perfect pointing. A hint does not penal is e the ending.

<a id="p-08"></a>

### Final-edition mapping

Use expansion chapter 4 and its four `EX-M` missions. Legacy SC/M identifiers inside the quoted source provide puzzle provenance only. Keep the full 96 scene/32 mission graph.


## Required deliverables

- Editable source and actual runtime deliverables in the established project layout.
- A bounded integration fixture or owning-scene hookup, with exact resource/API paths and stable IDs.
- Meaningful task-specific checks, actual execution results and visual/audio evidence where required.
- Updated affected manifests/provenance, and a precise handoff for the next dependent owner.


## Acceptance — demonstrate every applicable item

- Every source completion conjunct is tested and driven by actual validated actions.
- Shared numeric contracts, resource caps/order and dated biological/logistical effects remain unchanged.
- Wrong hypotheses produce explanatory feedback and a local supported retry.
- Assistance and captions preserve the same accepted result and ending eligibility.
- Pause, cancellation, duplicate input and save/reload preserve a coherent authoritative state where this task is interactive.
- English captions/text, named icons and assisted input preserve all essential information and story access.
- No unlogged generation, unsupported measured claim, new paid tool, secret, unrelated change or unrequested commit/push.


## Completion report

Use `05_ACCEPTANCE_AND_HANDOFF.md`. Record current HEAD, exact files, input revisions, commands and actual outcomes; identify current versus historical evidence. Mark unexecuted checks explicitly. Update production status only after the concrete deliverables pass the applicable gate. Do not count this prompt file itself as completed implementation.
