# P-03 — Alo Meets Tara

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

## P-03 — Alo Meets Tara

- **Mission / reason:** [M-0201](../game-design/07_MISSION_DESIGNS/M-0201_Borrow_a_Bee.md) — Cross-pollinate Alo and Tara without breaking containment.
- **Location / equipment:** LOC-05; Two compatible Fast Plant individuals, clean brushes A/B, sealed carrier, glove ports and microscope.
- **Initial state:** Flowers open; brush A and B clean; carrier empty; donor and recipient fields unset. Entry E14/20, A10/10, H6, C8, R18. Three sampled daylight operations use FULL/O0 and E1/A1 per reciprocal run, with ordinary basic 1 and breathing 1: after the three sampled operations E16, A4, H9, C10, R14.4. The dated background ledger separately covers unsampled care/consumption; planned food supply of at least 14 crew-days over the seven-day interval leaves 4 after total crew consumption 28. No hidden refill occurs during a bee run.
- **Player instructions and intermediate steps:** Scan donor Tara; collect yellow grains from anthers with brush A using select/confirm; seal carrier; transfer through pressure interlock; scan recipient Alo; touch its receptive stigma through glove ports. Reverse using clean brush B from Alo to Tara. Make three reciprocal runs on days 1, 4 and 7 (April 30–May 6), with seven dated care visits. Check space weather before every run; charge E1/A1 once per whole reciprocal cycle, including its four airlock transitions. Record Alo’s purple/Tara’s green stem prediction; show the result in Chapter 4 without promising a genotype ratio.
- **Accepted solution:** Tara anther → sealed A → Alo stigma; Alo anther → sealed B → Tara stigma; confirm donor≠recipient each way; repeat for three reciprocal runs across seven dated days; record the stem prediction.
- **Incorrect actions and feedback:** Touching petal shows no transfer; using own pollen explains cultivar incompatibility; dirty brush prompts replace tip. No drag precision score.
- **Progressive hints H1 / H2 / H3:** A flower needs pollen from its partner. / Take pollen from the anther to the other plant’s stigma. / Use A for Tara→Alo and clean B for Alo→Tara.
- **Difficulty, timing and retry:** Easy; unlimited clean tips. Retry affects the current transfer only.
- **Completion trigger:** Three reciprocal runs valid, each charged E1/A1 once; seals passed, seven care visits and stem prediction logged.
- **Narrative consequence / flags:** pollen_shared_pending; lineage_parent_pair = Alo × Tara.
- **Accessible input:** Every drag or hold also has Select source → Select target → Confirm; every visual observation has a text-equivalent reading. No puzzle requires colour perception, audio frequency discrimination, fast repeated presses or pixel-perfect pointing. A hint does not penal is e the ending.

<a id="p-04"></a>

### Final-edition mapping

Use expansion chapter 2 and its four `EX-M` missions. Legacy SC/M identifiers inside the quoted source provide puzzle provenance only. Keep the full 96 scene/32 mission graph.


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
