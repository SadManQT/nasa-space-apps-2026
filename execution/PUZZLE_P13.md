# P-13 — One Integrated Storm Plan

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

## P-13 — One Integrated Storm Plan

- **Mission / reason:** [M-0701](../game-design/07_MISSION_DESIGNS/M-0701_Your_Call_Cadets.md) — Plan three counter factual storm waves and protect crew, garden and seed reserve.
- **Location / equipment:** LOC-04; E30/32, A10/10, H6, C8, R18, six shared water units, two crate-shield units, protected two-compartment seed case.
- **Initial state:** Chapter 7 logistics snapshot after preparation costs, not Chapter 1 carry over. Six dark 7.2 h steps, multipliers [1,1,2,2,1,1]. Five lunar occupants (including Ferreira) consume A1.25 and R1.5 crew-days per step. Three waves span steps 1–2, 3–4 and 5–6.
- **Player instructions and intermediate steps:** Two allowed preparation transfers put W4 in shelter; stage full K2 supply bundles and latch both founder-reserve compartments (15+15=30) before peak step 3. Schedule COZY heat, DIM light, O0 throughout. HOLD W in 1–5; DRAIN to W2 in step 6 after that step’s exposure. Isolate the exposed uplink before the peak. No free solar income during the storm.
- **Accepted solution:** W [4,4,4,4,4,2], K2 throughout exposure, COZY/DIM/O0 in all six steps. Shield S6 gives zero game dose even in peak steps. Costs 6*(1+2+1)=24, ending E6, A2.5, H1, C3, R9, Z0; seed reserve 30 stays protected. All five crew are sheltered.
- **Incorrect actions and feedback:** Early drain reduces shelter before a later exposure. Missing seed compartment prevents readiness. Alternative plans are accepted when they meet the same safety and living-garden goals; owned upgrades apply once.
- **Progressive hints H1 / H2 / H3:** Put the seeds inside before the peak. / Water and cargo share the shielding job. / Prepare W4 and K2; COZY/DIM throughout; drain in step 6 after exposure.
- **Difficulty, timing and retry:** Integrated planning; no irreversible cost during preview; Guided plan available.
- **Completion trigger:** Feasible six-step plan, both seed compartments latched, five-person roster acknowledged, uplink isolation scheduled.
- **Narrative consequence / flags:** storm_prepared_pending; protected_founder_seeds 30; plan snapshot passed to P-14.
- **Accessible input:** Select source → Select target → Confirm substitutes for drag/hold. No colour-only, audio-only or rapid-input requirement; hints and assistance do not reduce ending eligibility.

<a id="p-14"></a>

### Final-edition mapping

Use expansion chapter 7 and its four `EX-M` missions. Legacy SC/M identifiers inside the quoted source provide puzzle provenance only. Keep the full 96 scene/32 mission graph.

### Later-chapter execution and occupancy appendix

and upgrades

Use the Chapter 7 logistics profile, source dose table and six-step plan above. Before each exposure, apply any emergency action, then score shelter; ordinary drains follow exposure. Deduct basics/heat/air/light and apply plant effects. With five crew, breathing is 1.25 and food 1.5 per full shift. Seed readiness and radio isolation are boolean preparation checks, not recurring hidden costs. Local communications and the protected greenhouse circuit survive direct-uplink damage.

The persistent upgrades in [campaign systems](../game-design/10_GAMEPLAY_SYSTEMS.md#campaign-progression-and-optional-play) apply once: shielding capped at 6, separate ice water conserved, FULL-lamp discount, insulation and warning/bundle modifiers. A baseline path is arithmetic evidence for the unmodified scenario only; release requires testing all 128 reachable upgrade combinations. No all-path balance pass is claimed here.


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
