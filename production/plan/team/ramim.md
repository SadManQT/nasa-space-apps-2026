# Nafis Mohtasim Ramim — current implementation assignment

**Board ID:** `ramim`. **Approved task allocation:** 20. **Priority rank:** 1/6.

Shared gameplay; Chapters 4/6/8; opening and progression UI. Read [CURRENT_BATCH.md](../CURRENT_BATCH.md) and [GO_NEXT.md](../GO_NEXT.md) first. This batch supersedes the older role/folder card for its explicit task scopes.

## Tasks

| ID | Feature |
|---|---|
| `M3-61` | EVA: suit budget, scanner pulse, footing with load, and assist modes |
| `M3-64` | The RPG layer: cadet record, skills, gear loadout, jobs board and rest |
| `M3-62` | Things you build stay: markers, fixed lines, lights, repeaters and the coverage map |
| `M3-63` | The rover and the route planner |
| `M3-65` | Readable hazards: moonquake, cold, impact flashes, darkness, solar-storm shelter run |
| `M3-4P` | Chapter 4 puzzles P-07 and P-08 as real interactive panels |
| `M3-4U` | Upgrade choice after Chapter 3 |
| `M3-4M` | Chapter 4 missions EX-M0401 to EX-M0404: physical play, crew and retry |
| `M3-6P` | Chapter 6 puzzles P-11 and P-12 as real interactive panels |
| `M3-6U` | Upgrade choice after Chapter 5 |
| `M3-6M` | Chapter 6 missions EX-M0601 to EX-M0604: physical play, crew and retry |
| `M3-8P` | Chapter 8 puzzles P-15 and P-16 as real interactive panels |
| `M3-8U` | Upgrade choice after Chapter 7 |
| `M3-8M` | Chapter 8 missions EX-M0801 to EX-M0804: physical play, crew and retry |
| `M1-18` | First five minutes: title screen, onboarding and UX polish |
| `M1-31` | Make it fun: Chapter 1 game-feel and reward pass |
| `M3-67` | Moon trainer: free training sorties on the real terrain from the title menu |
| `M3-72` | Chapter select, mission list, progress and achievements screens |
| `M3-90` | Remaining UI families: journal, discovery log, rover, greenhouse, credits |
| `M3-91` | All 128 upgrade profiles complete the campaign |

Run `python production/plan/board.py list --member ramim --phase implementation`, then inspect/claim a ready ID from this list. Finish existing assigned WIP before duplicating it.

## File permission and handoff

Only edit files needed for the task, inside its paths/integration_paths, after publishing exact-file reservations. These scopes replace historical folder restrictions for this batch; they do not grant blanket folder ownership. Read task assignment_history and preserve other agents' work. If a file is actually reserved, switch to another ready task or arrange a saved-work handoff. A former owner label alone is not a blocker.

## Verification and delivery

Implement actual campaign behavior, run the required automated/scripted checks, and record real results. Do not rebuild source already delivered or mark a fixture-only prototype Done. Claim no IDs outside this list; submission/video/manual QA are deferred. Commit/push verified work under your own GitHub account, safely synchronizing and preserving other work first. Never stage unrelated imports/settings or force-push.
