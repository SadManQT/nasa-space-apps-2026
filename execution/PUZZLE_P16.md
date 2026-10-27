# P-16 — The Link and the Living Garden

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

## P-16 — The Link and the Living Garden

- **Mission / reason:** [M-0802](../game-design/07_MISSION_DESIGNS/M-0802_From_Last_Light_to_First_Light.md) — Restore both links, bring the team home and validate the living garden.
- **Location / equipment:** LOC-12; Replacement controller, isola tor, two antenna channels, signal meter, checksum, final garden panel.
- **Initial state:** Relay dark; housing damaged controller. Local bearing presets L1=poor, L2=good, L3=blocked; Earth presets E1=poor, E2=blocked, E3=good. First checksum incomplete until both links lock. The upcoming Aurora Earth-set handover window is displayed; both locks must be ready before its authored deadline, with an untimed equivalent.
- **Player instructions and intermediate steps:** Isolate power, test zero, remove controller, install matching spare, close housing, reconnect. Use azimuth/elevation dials to match the displayed local bearing L2 and the Earth bearing E3; hold a stable lock for 3 s or tap-confirm in accessible mode. L/E presets provide an equally rewarded assisted alternative. Bearings come from bundled geometry when verified; until then label them scenario bearings. Send checksum ALO42 and receive exact match from Aurora; perform both voice checks. Return journey 24 h. At sunrise verify crew 5 safe, founder reserve 30 and eleven unplanted vault specimens protected, garden pressure stable, temperature stable, cotton alive; open shutter and save photo/dedication.
- **Accepted solution:** Isolation→zero→replace→close→power; L2 then E3; checksum ALO42 match; voice Aurora+Earth; return; five final indicators; photo and any dedication.
- **Incorrect actions and feedback:** Wrong preset gives strength/obstruction text and can be changed; reconnect with housing open blocked. Link lost during call reuses checkpoint and transcript; final shutter waits for safety checks. No biological miracle or instant travel.
- **Progressive hints H1 / H2 / H3:** A relay needs both ends. / Connect Aurora’s repeater chain before Earth. / L2 then E3, checksum ALO42, verify both voices; return and open the safe shutter.
- **Difficulty, timing and retry:** Medium; no dexterity timer; all steps check pointed after closed housing and link validation.
- **Completion trigger:** Both links pass, voice checks logged, return confirmed, final five indicators pass, shared photo and dedication saved.
- **Narrative consequence / flags:** campaign_complete_pending; relay_live; crew_returned; final_garden_validated; credits_available. MARS drawer optional.
- **Accessible input:** Every drag or hold also has Select source → Select target → Confirm; every visual observation has a text-equivalent reading. No puzzle requires colour perception, audio frequency discrimination, fast repeated presses or pixel-perfect pointing. A hint does not penal is e the ending.

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
