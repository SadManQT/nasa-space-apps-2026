# P-14 — Three Waves and a Broken Link

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

## P-14 — Three Waves and a Broken Link

- **Mission / reason:** [M-0702](../game-design/07_MISSION_DESIGNS/M-0702_What_We_Carry.md) — Execute the storm plan, protect living crops and seeds, then diagnose the failed uplink.
- **Location / equipment:** LOC-04; P-13 plan, local telemetry, stored log, external branch test and route dosimeter.
- **Initial state:** Six storm steps; game multipliers [1,1,2,2,1,1]. Use P-02 energy, plant and shelter rules, Chapter 7 reserves and five-person air/food rates. Chapter 7’s Z<=6 limit overrides Chapter 1’s Z<=3 limit; its six storm multipliers are explicit. K remains installed through step 6 and is cleared only after the storm; P-02’s shift-7 removal belongs to Chapter 1.
- **Player instructions and intermediate steps:** Confirm five occupants. Execute all six steps; dose is sampled before an ordinary transfer, using the P-02 shelter table times the current multiplier. Play Noor’s last log after step 2 in the lull; it explains Alo and the Last Light Academy name. Keep hatch closed during exposure. After step 6 verify local network PASS, direct dish path FAIL and external feed through FAIL; select F-EXT. Two route readings below the game threshold 1, ten scenario minutes apart, clear later exterior preparation.
- **Accepted solution:** P-13 witness ends E6, A2.5, H1, C3, R9, Z0, W2, K2, reserve 30 safe. Diagnose the external feed through; safe readings 0.4 then 0.3 clear the route. A 1.2 reading does not. The February-to-April preparation montage maintains the stable base before the final trip.
- **Incorrect actions and feedback:** The hatch interlock prevents storm EVA. Unsafe committed dose/air or lost mandatory garden/seed objectives offer a pre-step retry. One safe reading is insufficient. The direct uplink failure is a scripted incident, not a hidden penalty for a correct plan.
- **Progressive hints H1 / H2 / H3:** Finish all three waves before going outside. / A working local radio isolates the failure to the Earth path. / Keep the six-step witness, select F-EXT and record two below-threshold readings.
- **Difficulty, timing and retry:** Forecast available throughout; safe wait can be compressed. Checkpoint before every step.
- **Completion trigger:** Six steps complete, A>0, Z<=6, H>0, C>0, founder reserve 30 safe, F-EXT identified and two clear readings.
- **Narrative consequence / flags:** route_clear_pending; radio_external_failed; final_log_heard; all_crew_safe.
- **Accessible input:** Select source → Select target → Confirm substitutes for drag/hold. No colour-only, audio-only or rapid-input requirement; hints and assistance do not reduce ending eligibility.

<a id="p-15"></a>

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
