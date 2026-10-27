# P-05 — Find the Falling Pressure

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

## P-05 — Find the Falling Pressure

- **Mission / reason:** [M-0301](../game-design/07_MISSION_DESIGNS/M-0301_Numbers_That_Disagree.md) — Find and repair the leak through independent observations.
- **Location / equipment:** LOC-02; Independent mechanical gauge, taps MAIN/GARDEN/RETURN, isolation valves, captive clamp.
- **Initial state:** Entry E14/20, A10/10, H6, C8, R18. Four daylight investigation phases of 7.2h use DIM/O0, with basic E1 and light E1. Normal breathing A1 per phase; unresolved leak A1 in phases 1–3, sealed before phase 4 consumption. Witness ends E18, A3, H6, C8, R13.2. At most two location inspections per phase. Six candidates: main tank, habitat trunk, garden feed through, return line, airlock seal, annex branch. Initial panel uncertainty means location labels are candidates, not proof. At phase 2 an aftershock opens the annex branch; its automatic isolation must be verified before reopening the garden. Mechanical readings at t 0/t 10: MAIN 100/100, GARDEN 82/74, RETURN 100/100, relative test units.
- **Player instructions and intermediate steps:** Compare all six candidates using the three trunk taps and two location checks per phase; verify the aftershock annex isolation. Read all taps; close GARDEN isolation valve; recheck MAIN remains 100 and isolated GARDEN stays 74; fit clamp to GARDEN feed through from press uri sed safe side; reopen slowly; run five 2-second checks.
- **Accepted solution:** Compare the six candidates within four investigation phases, verify the aftershock annex isolation, then isolate GARDEN only → verify stable trunk → apply clamp → open GARDEN slowly → five readings 100/100/100. Clamp cannot seat on a press uri sed leaking connection.
- **Incorrect actions and feedback:** Closing MAIN produces a protected reserve warning and can be reopened immediately; wrong clamp location cannot latch; recheck explains remaining pressure fall.
- **Progressive hints H1 / H2 / H3:** Which reading changes over time? / Compare the manual garden reading. / Close GARDEN, clamp its feed through, reopen and verify five steady readings.
- **Difficulty, timing and retry:** Medium; planning pauses leakage. A committed unsafe trunk isolation safes and retries from gauge checkpoint.
- **Completion trigger:** Six candidates investigated within four phases, aftershock annex isolation verified, and five consecutive stable readings after correct clamp and reopening.
- **Narrative consequence / flags:** leak_sealed_pending; manual_gauge_trusted.
- **Accessible input:** Every drag or hold also has Select source → Select target → Confirm; every visual observation has a text-equivalent reading. No puzzle requires colour perception, audio frequency discrimination, fast repeated presses or pixel-perfect pointing. A hint does not penal is e the ending.

<a id="p-06"></a>

### Final-edition mapping

Use expansion chapter 3 and its four `EX-M` missions. Legacy SC/M identifiers inside the quoted source provide puzzle provenance only. Keep the full 96 scene/32 mission graph.


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
