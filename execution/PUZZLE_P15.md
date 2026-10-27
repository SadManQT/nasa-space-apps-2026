# P-15 — Two Teams, One Road

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

## P-15 — Two Teams, One Road

- **Mission / reason:** [M-0801](../game-design/07_MISSION_DESIGNS/M-0801_The_Long_Road.md) — Prepare two teams and traverse the relay route with verified reserves.
- **Location / equipment:** LOC-11; Three-seat press uri sed rover, controller spare, three repeater buoys, home-system board.
- **Initial state:** Rover E14 (source units); independent supplies 72 h; 120 km each way; outbound travel/heat/repair allowance 5, return allowance 5; minimum reserve 2. Marker 2 battery dead. Home E20/cap 26, A8, H6, C8, R18, W0; 36 h COOL/DIM/basic demand is 5*(1+1+1)=E15. COOL costs H1 per 7.2 h without insulation; the five-shift night ends H1, so no unavailable upgrade is required. Air use is 0.5 per 7.2 h for the two home cadets for 33 h, then 1.25 per 7.2 h for all five for the final 3 h: total 2.8125.
- **Player instructions and intermediate steps:** Load controller, battery spare and 72 h supplies; assign FER/KAI/RAF rover and MEI/AMA home. Choose surveyed road (max 12°, allowance 5), not shortcut (22°, allowance 3.5). At marker 2 stop, brake, isolate buoy, replace battery, reconnect and test chain 1→2→3. At home set heat MIN (COOL), lamp DIM, return OPEN, verify independent pressure; acknowledge summit packet.
- **Accepted solution:** 14−5−5=4>=2; total journey 51 h<=72 h. Restore marker 2 before leaving. Home end E5, A5.1875, H1, C8, R14.625; all four checks valid. Travel sim advances 24 h outbound; local playable road length is intentionally compressed.
- **Incorrect actions and feedback:** Missing spare blocks departure; off-road slope barrier offers return to last marker; unbraked exterior repair cannot start; home return CLOSED prompts thirst forecast. No character switching across locations during free movement.
- **Progressive hints H1 / H2 / H3:** A return reserve belongs in the departure plan. / Marker 2 is part of the radio path. / Use surveyed route, restore buoy 2, home heat MIN/lamp DIM/return OPEN.
- **Difficulty, timing and retry:** Medium; guided cruise and station-view alternative; checkpoint each marker and home handover.
- **Completion trigger:** Loadout valid, three buoys link, summit arrival at Apr 9 00: 00, home checks verified.
- **Narrative consequence / flags:** summit_reached_pending; aurora_home_ready; repeater_chain_live; travellers_at_summit.
- **Accessible input:** Every drag or hold also has Select source → Select target → Confirm; every visual observation has a text-equivalent reading. No puzzle requires colour perception, audio frequency discrimination, fast repeated presses or pixel-perfect pointing. A hint does not penal is e the ending.

<a id="p-16"></a>

### Final-edition mapping

Use expansion chapter 8 and its four `EX-M` missions. Legacy SC/M identifiers inside the quoted source provide puzzle provenance only. Keep the full 96 scene/32 mission graph.

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
