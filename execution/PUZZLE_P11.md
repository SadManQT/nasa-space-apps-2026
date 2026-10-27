# P-11 — Protect the Small Light

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

## P-11 — Protect the Small Light

- **Mission / reason:** [M-0601](../game-design/07_MISSION_DESIGNS/M-0601_A_Plan_for_Darkness.md) — Plan the eclipse while keeping life support and the garden warm.
- **Location / equipment:** LOC-02; main E14/20 jar, protected-services schedule, pump, camera and optional floodlights.
- **Initial state:** Five labelled teaching segments: pre charge, ingress, totality, egress, recovery. Until a verified illumination/duration curve is integrated, use a disclosed [G] seven-unit allocation from the 14-unit jar. Essential package (circulation, minimum heat, dim grow light and guide light) costs 1 per segment, pump/camera readiness each 1 once; decorative floods 3 each activation. These totals replace elapsed-time demand in this fallback; never charge them on top of a second duration model.
- **Player instructions and intermediate steps:** Essentials ON in all five segments; prepare return pump in segment 1, camera in segment 2, floods OFF. Acknowledge all five segments and the return reserve. The main eclipse feed and family call occur during valid Earth contact, and egress is recorded after P-12 restoration.
- **Accepted solution:** Essentials [1,1,1,1,1], pump [1,0,0,0,0], camera [0,1,0,0,0], floods all OFF; total 7 and E7 at recovery. Equivalent pump/camera placements before their deadlines are accepted. The verified-data release replaces this fallback with demand scaled by segment-hours/7.2 as specified in the source gameplay document and re balances the forecast.
- **Incorrect actions and feedback:** Omitting essentials identifies the affected service. Spending more than the seven-unit protected allocation warns about the reserved recovery margin. Edit freely before commitment.
- **Progressive hints H1 / H2 / H3:** Protect essential services throughout. / Five essentials plus one pump and one camera equal seven. / Keep essentials ON, prepare pump in 1 and camera in 2, with floodlights OFF.
- **Difficulty, timing and retry:** Untimed planning; reversible individual settings.
- **Completion trigger:** All five essential packages scheduled, pump/camera each once before deadlines, allocation<=7 and five segment acknowledgements saved.
- **Narrative consequence / flags:** eclipse_ready_pending; kai_plan_shared.
- **Accessible input:** Select source → Select target → Confirm substitutes for drag/hold. No colour-only, audio-only or rapid-input requirement; hints and assistance do not reduce ending eligibility.

<a id="p-12"></a>

### Final-edition mapping

Use expansion chapter 6 and its four `EX-M` missions. Legacy SC/M identifiers inside the quoted source provide puzzle provenance only. Keep the full 96 scene/32 mission graph.


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
