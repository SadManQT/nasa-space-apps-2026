# P-10 — Flashes and a Signature

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

## P-10 — Flashes and a Signature

- **Mission / reason:** [M-0502](../game-design/07_MISSION_DESIGNS/M-0502_Permission_to_Answer.md) — Observe impact flashes, maintain the station and identify Noor.
- **Location / equipment:** LOC-01/02/03; archived camera candidates, hot-pixel comparison, panel cleaner, safe-side dome patch and signed manifest.
- **Initial state:** Three observation/maintenance phases; E14/20, A8/10, H6, C8, R18. Eight genuine transient examples and two persistent detector artifacts; six verified flashes satisfy the mission. Dust reduces solar income from 8 to 6 until cleaned; a micro-leak consumes 1 extra air per unresolved phase (0.5 with flexible seals). Dust Shield/Whipple bumper prevent the respective event and supply a verification task instead.
- **Player instructions and intermediate steps:** Compare candidate frames; mark six genuine flashes and reject both fixed artifacts. First maintenance opportunity: clean the affected panel and clamp/patch the isolated dome spur from its safe side, then verify pressure. Run three phases with COZY heat, DIM light, O0; five-person breathing is 1.25 per full 7.2 h phase. With immediate maintenance, daylight income is 8 for all three phases. After evidence pass, match N.R. to Dr. Noor Rahman on the signed manifest and send any of the three invitations.
- **Accepted solution:** Six genuine events, both artifacts rejected; dust removed/prevented, leak sealed/prevented and pressure verified; signed identity matched and invitation sent. Witness E16, A4.25, H6, C8, R13.5, Z0 after three phases. All eight verified flashes with no false report satisfy the observation Golden criterion.
- **Incorrect actions and feedback:** A hot pixel remains fixed across frames. Mistags can be corrected without reaction speed scoring. Unrepaired faults stay visible in the next forecast. Noor’s connection is not inferred from nationality; the signed record supplies it.
- **Progressive hints H1 / H2 / H3:** Compare more than one frame. / A real flash changes; a detector fault stays. / Verify six transients, clean and patch or verify the protective upgrade, then match the signed manifest.
- **Difficulty, timing and retry:** Untimed candidate review and select-confirm repairs; checkpoint before each observation/maintenance phase.
- **Completion trigger:** At least six verified flashes, both artifacts rejected, maintenance passed/protected, A>0, H>0, signed identity matched and invitation sent; set noor_identity_revealed.
- **Narrative consequence / flags:** noor_known_pending; noor_identity_revealed; noor_contact_consented; Noor alive and Academy founder; cotton planting follows.
- **Accessible input:** Select source → Select target → Confirm substitutes for drag/hold. No colour-only, audio-only or rapid-input requirement; hints and assistance do not reduce ending eligibility.

<a id="p-11"></a>

### Final-edition mapping

Use expansion chapter 5 and its four `EX-M` missions. Legacy SC/M identifiers inside the quoted source provide puzzle provenance only. Keep the full 96 scene/32 mission graph.


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
