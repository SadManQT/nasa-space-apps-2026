# SYS12 — Collision, navigation, doors and safe traversable spaces

**Execution prompt · snapshot 27 October 2026 / `ca01433` · Shared runtime.**



## Assignment

Make assembled rooms and routes physically navigable with correct pressure/interlock boundaries.

Execute this bounded task, integrate it with the current project and produce the acceptance evidence below. First reconcile the snapshot with current files; reuse already approved work and complete the real remaining gap.


## Mandatory shared context

Read [02_SHARED_CONTRACT.md](02_SHARED_CONTRACT.md), [03_SYSTEM_INTERFACES.md](03_SYSTEM_INTERFACES.md), [04_CURRENT_STATE.md](04_CURRENT_STATE.md), [05_ACCEPTANCE_AND_HANDOFF.md](05_ACCEPTANCE_AND_HANDOFF.md). Also read the current [AGENTS.md](../AGENTS.md), [PRODUCTION_HANDBOOK.md](../PRODUCTION_HANDBOOK.md) and newest [HANDOFF.md](../HANDOFF.md) entries. Current locked English-only, faceless plants, anime cast and scientific boundaries override older source wording.


## Inputs to inspect

- [game/project.godot](../game/project.godot)
- [game-design/08_PUZZLE_DESIGNS.md](../game-design/08_PUZZLE_DESIGNS.md)
- [production/review/codex_readiness_report.md](../production/review/codex_readiness_report.md)
- [full-game-story/story-data.json](../full-game-story/story-data.json)
- Existing `game/scripts/`, `game/tools/` and `production/tools/` modules relevant to this task; verify exact names before editing.


## Ownership and dependencies

Own the shared service named in this prompt, its proposed resource/API contract and targeted tests. Preserve existing player/rendering APIs. Publish the interface handshake before UI, asset or mission owners implement callers.

Follow the Phase 0 order in `06_EXECUTION_BOARD.md`. Treat new module names in `03_SYSTEM_INTERFACES.md` as proposals until agreed; do not claim an unimplemented dependency already exists.


## Detailed work sequence

1. Measure modular pieces, actual character capsule/camera clearance, doorways and aisles against world budgets.
2. Add appropriate collision and navigation meshes/regions without relying on a visually present mesh to block movement.
3. Represent shutters, doors, rails, rover steps and repair pads with named movable parts and validated safe states.
4. Bind pressure/radiation route locks to shared predicates while preserving a readable return path and cancel/recovery.
5. Test all five character heights, keyboard/controller movement, camera occlusion, stairs/slopes, alternative motion route and companion anchors.
6. Check collision seams, room stream/save transitions and interaction reach in each Chapter 1 route, then later field locations.


## Task-specific source and implementation detail

### Baseline integration checkpoints

- Source content: 8 chapters/32 missions/96 scenes/385 lines.
- Existing game foundation: 49 GLBs, current five 44 clip characters, sixdev/player/look scenes, three anime OGVs.
- Main campaign and Chapter 1 rooms/UI are not automatically completed by the presence of those assets.
- Historical technical-blueprint 16 mission/48 scene structure is superseded; reuse its transaction ideas under the final IDs.
- Existing tests live under `game/tools/`; execute the affected suites with the installed Godot and `--headless --path game --script res://tools/<actual_test>.gd`. Inspect test fixture portability first; record a missing Mac scratch fixture rather than inventing a passing run.


## Required deliverables

- Editable source and actual runtime deliverables in the established project layout.
- A bounded integration fixture or owning-scene hookup, with exact resource/API paths and stable IDs.
- Meaningful task-specific checks, actual execution results and visual/audio evidence where required.
- Updated affected manifests/provenance, and a precise handoff for the next dependent owner.


## Acceptance — demonstrate every applicable item

- No fall through/soft lock/camera clipping on required routes.
- Closed pressure boundaries cannot be bypassed by movement or role switching.
- A nav/collision check is separately evidenced from a geometry import pass.
- Pause, cancellation, duplicate input and save/reload preserve a coherent authoritative state where this task is interactive.
- English captions/text, named icons and assisted input preserve all essential information and story access.
- No unlogged generation, unsupported measured claim, new paid tool, secret, unrelated change or unrequested commit/push.


## Completion report

Use `05_ACCEPTANCE_AND_HANDOFF.md`. Record current HEAD, exact files, input revisions, commands and actual outcomes; identify current versus historical evidence. Mark unexecuted checks explicitly. Update production status only after the concrete deliverables pass the applicable gate. Do not count this prompt file itself as completed implementation.
