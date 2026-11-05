# MD Atik Khan — Gameplay runtime, Moon systems and builds

**Share:** 20% of the team's work · **Board id:** `atik` · Read with [MASTER_PLAN.md](../MASTER_PLAN.md) (your AI reads it; you do not have to).

You own the game's runtime: missions and routes, the campaign, the player, carrying, EVA, the rover, markers, hazards, saves, loading, terrain streaming, and builds and performance.

## How you work

Type **`continue(atik)`** to your AI. It pulls, claims your next ready tasks (`board.py take --by "<Name>/<AI>"`), does them one by one inside your folders, tests, reviews, commits under your GitHub account and pushes ([GO_NEXT.md](../GO_NEXT.md) §0). Say **`go next`** instead for exactly one task.

**Your AI:** Any strong coding AI (Codex at extra-high effort is a good fit for runtime work). Ask it to read the task's read-first files and the existing tests in `game/tools/` before changing a system.

## Your folders (only you edit these)

- `game/scripts/missions/`
- `game/scripts/campaign/`
- `game/scripts/player/`
- `game/scripts/eva/`
- `game/scripts/rover/`
- `game/scripts/network/`
- `game/scripts/hazards/`
- `game/scripts/payload/`
- `game/scripts/save/`
- `game/scripts/loading/`
- `game/scripts/terrain/`
- `game/shaders/terrain/`
- `game/resources/campaign/gates/`
- `game/resources/campaign/profiles/`
- `game/resources/campaign/care_round/`
- `game/resources/campaign/echoes/`
- `game/export_presets.cfg`
- `game/tools/run_tests.sh`
- `production/qa/builds/`
- `production/qa/perf/`

Everything else belongs to someone else (MASTER_PLAN.md §7). Need a change there? File a task for its owner with `board.py add` and carry on.

## Your rules

- Gameplay values live in data (`game/resources/campaign/profiles/`, gates), never in code; numbers come from `game-design/08_PUZZLE_DESIGNS.md`.
- Forecast and commit must agree: the simulation is pure functions; never add a second copy of a rule.
- You wire Ramim's puzzle panels into missions and gates (the chapter's M task). You do not edit `game/scripts/ui/` or `game/scripts/puzzles/` — file a task for Ramim.
- Register new input actions in code inside your system; do not edit `project.godot` (file a task for Sadman).
- Every system has its own test `game/tools/test_<system>.gd`; keep `run_tests.sh` green and fast.
- Commit under your own GitHub account, no AI co-author lines; log AI use in `production/AI_PROMPT_LOG.md` (one row per task; the file merges itself).

## Start here

The Chapter 1 care round (M1-49), the loading check (M1-53), save slots (M3-71), then terrain streaming (M1-36, once M1-34 lands) and EVA (M3-61). Builds (M1-20) wait for Sadman to publish the draft release.

## Your work (22 open tasks, 60 effort points)

The board decides the real order and shows what is ready; this is the overview on 5 Nov 2026.

| Task | Milestone | Priority | Effort | Title |
|---|---|---|---|---|
| M1-36 | M1 | P0 | 3 | Terrain in Godot: streaming, collision, lighting and performance |
| M1-20 | M1 | P0 | 1 | Export presets and release builds (Windows, macOS; web feasibility) |
| M1-49 | M1 | P0 | 3 | Chapter 1 Care Round: dated photos of Alo and Tara, the opening lines in play, and the scene bridges |
| M1-58 | M1 | P0 | 3 | Carrying payloads, and the shift-5 STACK as a real carry-and-place task |
| M1-23 | M1 | P1 | 2 | Performance and low-spec pass |
| M1-53 | M1 | P1 | 2 | Rule out a threaded-loading deadlock at full-cast entry |
| M3-2M | M3 | P1 | 3 | Chapter 2 missions EX-M0201 to EX-M0204: physical play, crew and retry |
| M3-3M | M3 | P1 | 3 | Chapter 3 missions EX-M0301 to EX-M0304: physical play, crew and retry |
| M3-4M | M3 | P1 | 3 | Chapter 4 missions EX-M0401 to EX-M0404: physical play, crew and retry |
| M3-95 | M3 | P1 | 3 | Story echoes and environmental clues for Chapters 2-8 (decisions D4-D13, the Noor and Ferreira clue objects) |
| M3-61 | M3 | P1 | 3 | EVA: suit budget, scanner pulse, footing with load, and assist modes |
| M3-62 | M3 | P1 | 3 | Things you build stay: markers, fixed lines, lights, repeaters and the coverage map |
| M3-63 | M3 | P1 | 5 | The rover and the route planner |
| M3-65 | M3 | P1 | 3 | Readable hazards: moonquake, cold, impact flashes, darkness, solar-storm shelter run |
| M3-71 | M3 | P1 | 2 | Save slots, autosave and versioned save migrations at Steam quality |
| M3-73 | M3 | P1 | 2 | Act One release candidate (Chapters 1-4): Windows and macOS builds, soak test, Steam-ready packaging |
| M3-5M | M4 | P1 | 3 | Chapter 5 missions EX-M0501 to EX-M0504: physical play, crew and retry |
| M3-6M | M4 | P1 | 3 | Chapter 6 missions EX-M0601 to EX-M0604: physical play, crew and retry |
| M3-7M | M4 | P1 | 3 | Chapter 7 missions EX-M0701 to EX-M0704: physical play, crew and retry |
| M3-8M | M4 | P1 | 3 | Chapter 8 missions EX-M0801 to EX-M0804: physical play, crew and retry |
| M3-93 | M4 | P1 | 2 | Full-game release builds and evidence package |
| M2-13 | M2 | P2 | 2 | Browser candidate: reduce the download and bundle missing UI glyphs |
