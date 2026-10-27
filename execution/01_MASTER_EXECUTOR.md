# MASTER — complete the Last Light Academy game

## Assignment

You own delivery of the existing Godot game from its current asset/player foundation to a complete, tested eight-chapter campaign. Use the individual prompts in this folder as work packages. Produce playable deliverables and evidence at each milestone. Keep the current approved anime characters, story and mathematical contracts consistent throughout production.

Read [00_START_HERE.md](00_START_HERE.md), [02_SHARED_CONTRACT.md](02_SHARED_CONTRACT.md), [03_SYSTEM_INTERFACES.md](03_SYSTEM_INTERFACES.md), [04_CURRENT_STATE.md](04_CURRENT_STATE.md), [05_ACCEPTANCE_AND_HANDOFF.md](05_ACCEPTANCE_AND_HANDOFF.md), [06_EXECUTION_BOARD.md](06_EXECUTION_BOARD.md) and [99_COVERAGE_MATRIX.md](99_COVERAGE_MATRIX.md), then inspect the repository's current `AGENTS.md`, handbook and newest handoff entries. Respect user instructions that supersede an older document.

## Outcome

- One Godot 4.7.2 project, using the established Forward+ pipeline and current player/character implementation.
- Eight ordered chapters, 32 mandatory missions and 96 final scenes; target 720 active minutes, range 600–840 for the same complete main route.
- Finished characters, environments, plants, vehicles and interactable props with coherent scale, art, collision, state variants and sockets.
- Deterministic P-01 through P-16 puzzle implementations, a single prediction/commit model, and conserved resources across scene/save transitions.
- Working dialogue, readable English captions, acquired-only journal, science labels, role sharing, assistance, save/load and complete ending.
- Integrated cutscenes/audio, with captions preserving complete access when a voice asset is absent.
- Evidence-backed release candidate and reproducible package. Do not equate a player demo or asset showcase with a completed chapter.

## Before assigning implementation

1. Record current HEAD, working-tree changes, host OS, Godot/Blender/audio tools and which runtime media are actual binaries rather than LFS pointers. Preserve user work.
2. Compare actual files with `04_CURRENT_STATE.md`. The snapshot's registry contains historical data; inspect current models/manifests before replacing anything.
3. Declare owners for campaign state, simulation, interactions, dialogue/journal, save/load, UI, character runtime, world assembly, production assets and QA. Their ownership is technical scope, not a new fictional character role.
4. Use `03_SYSTEM_INTERFACES.md` to establish shared data fields and event semantics. Propose concrete GDScript APIs against the existing code; freeze the interface note before parallel implementation.
5. Build a dependency board containing task ID, owner, prerequisite tasks, files owned, acceptance evidence and state. A task can be `ready`, `running`, `blocked`, `review`, or `verified`; mark verified only after its checks.

## Milestone A — launchable foundation

Complete the SYS tasks needed to boot, load canonical content, track state, interact, show dialogue/UI and save safely. Reuse `game/scenes/player/player.tscn`, the current player controller and rendering stack. Make the actual application main scene launch into New Expedition or Continue; keep the dev showcase available separately.

Exit evidence: clean import/start, no missing resources, one real interaction traversing the full input → validation → transaction → presentation route, a save/load round trip, and unchanged existing player/face/hold tests.

## Milestone B — complete Chapter 1 vertical slice

Use the four `MISSION_EX_M01xx.md` files, `PUZZLE_P01.md`, `PUZZLE_P02.md` and their required environment/asset/UI tasks. Assemble Commons, Power/Atmosphere, Garden, Safe Room, connecting routes and the exterior context. Complete commissioning, two-seed planting, dated care, daylight preparation, shift-2 drill, Earth-set, alarm response, water return, bloom and stored message.

Demonstrate Bloom and supported loss/retry closures. Show PUMP, STACK and WAIT as valid, exclusive choices under the unchanged numerical contract. Hints, timer assistance and captions retain equal ending access. Ferreira remains an Earth-screen presence. Confirm four physical cadets and no early Noor identity. Integrate the existing CS-01/02/03 anime OGVs with skip semantics that never fabricate puzzle completion.

Exit evidence: an uninterrupted New Expedition → CH01 ending → CH02 readiness run, explicit checkpoint retries and save/load at representative puzzle/dialogue/cinematic boundaries. Capture timings and learner confusion; do not inflate duration with forced waiting.

## Milestone C — the full expedition

Build Chapters 2–8 in dependency order. Each mission owner consumes the shared state and has exactly three scene gates. Require setup/payoff receipts between chapters: pollen → mature seeds; annex map → safe survey; vault inscription → consented confession; December spare → February preparation → final compatible repair. Preserve the corrected biological timeline, travel roster, site-specific science labels and radio-link limits.

At each chapter boundary, review actual physical presence, knowledge, inventory, date and resource ledger before unlocking the next chapter. Do not reset resources to convenient values without the source's explicit chapter entry/logistics record.

## Milestone D — art, audio and interaction finish

Finish the asset prompts with a reuse-first pass. Current character GLBs are already delivered: preserve their identities, heights, 44 clips, face layers and hand poses. Convert the rest of the game into the same anime presentation, then rebuild only geometry or interactive subparts that fail the concrete task gate. Complete natural plant stages, screen contents, movable parts, vehicle/repair contacts and physics-safe level routes.

Integrate each cutscene, voice group, music cue and SFX task. Check output formats actually supported by the installed runtime. Reuse the existing Theora OGV workflow or a verified alternative; do not declare conversion impossible merely because one FFmpeg build lacks an encoder. Costs and account balances are checked live only when execution reaches a required generation, never copied from a historical note.

## Milestone E — independent acceptance and release

Run the QA prompts after feature integration. Cover all 32 mission gates, all 96 scene transitions, complete ending, loss recovery, save/load, accessibility, source labels, upgrade combinations and performance on the agreed target hardware. A headless pass is insufficient for appearance and contact approval; obtain visual evidence and junior-learner observations.

Require a clean, reproducible export and a credits/source manifest. Assemble a final status table with deliverable paths, test outputs, measured limits and unresolved blockers. Update the handbook and handoff in the same change as a status/decision update. Commit or push only when the user asks, using the identity and attribution policy in `AGENTS.md`.

## Stop conditions and recovery

Continue independent ready work if one task lacks an input. Record the exact blocked dependency and its smallest actionable remedy. Never invent a successful tool call, existing file, imported dataset, approval, playtest result or asset verification. If a canonical number or story fact appears impossible, produce a small reproducible counterexample and escalate that specific contract; do not silently rewrite it to make a test pass.

## Final handoff

Use the template in `05_ACCEPTANCE_AND_HANDOFF.md`. Include source/engine versions, exact task statuses, commands and outcomes, screenshots/clips where required, the complete route's timing evidence, remaining risks and a one-page next-actions list. The final executable and its gameplay evidence are the deliverables; this prompt pack is the execution specification.
