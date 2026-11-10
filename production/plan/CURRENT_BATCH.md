# Current implementation batch — 10 November 2026

This is the user's approved current assignment. `tasks.json` -> `implementation_batch` is the machine-readable allowlist. It overrides older member/folder mappings, team cards, parked-branch notes and QA reports for these tasks only. The story, science, credit, test and asset-approval rules remain binding.

## What is active

50 original implementation tasks plus the subsequent user-authorized M1-125 integration repair (51 active IDs). Workload priority: Ramim > Sadman > Asif > Atik > Tanvir > Shanto. Counts below are the approved task allocation, not a token/time estimate; preserve later completed statuses and never rebuild valid work to fill a quota.

| Member | Tasks | IDs |
|---|---:|---|
| Ramim | 21 | `M3-61`, `M3-64`, `M3-62`, `M3-63`, `M3-65`, `M3-4P`, `M3-4U`, `M3-4M`, `M3-6P`, `M3-6U`, `M3-6M`, `M3-8P`, `M3-8U`, `M3-8M`, `M1-18`, `M1-31`, `M3-67`, `M3-72`, `M3-90`, `M3-91`, `M1-125` |
| Sadman | 11 | `M4-16`, `M1-108`, `M1-49`, `M3-95`, `M3-101`, `M3-5P`, `M3-5U`, `M3-5M`, `M3-7P`, `M3-7U`, `M3-7M` |
| Asif | 10 | `M1-105`, `M3-2P`, `M3-2U`, `M3-2M`, `M1-103`, `M1-37`, `M3-3P`, `M3-3U`, `M3-3M`, `M3-69` |
| Atik | 4 | `M1-68`, `M1-53`, `M1-92`, `M1-116` |
| Tanvir | 3 | `M1-122`, `M1-123`, `M1-85` |
| Shanto | 2 | `M3-71`, `M3-70` |

## Start without waiting for a former owner

- Ramim: repair/integrate M3-61 first, then M3-64; independent panel/data work remains available.
- Sadman: M4-16, M1-108 and the Chapter 5/7 panels; use the published CareRound provider for M1-49, then M3-95/M3-101.
- Asif: M3-3P while preserving/handing off M1-103 and M1-105 WIP; finish each public contract before its Class/Chapter 2 consumer. The old M3-75 review is deferred.
- Atik: M1-68/M1-53, then M1-92/M1-116. M1-120's source and retained diagnostics already exist; old owner requests are not a reason to wait.
- Tanvir: M1-122/M1-123, then M1-85. These are implementation assignments, not the deferred M1-65 playtest. Do not wait solely because an old report calls Sadman/Atik their owners.
- Shanto: M3-71 save interfaces and M3-70 settings. Shanto is a registered board member; no free-slot lookup/rename is needed.

Only claim an exact ID from your own row. If genuinely blocked, record the dependency, owner, saved work and resume condition, then choose another ready ID in your row. Recheck blockers before each batch. A task-scoped reassignment does not erase real technical dependencies. When your ready queue is exhausted, report it; taking an unlisted task requires an explicit new reassignment.

## Scope and one writer per file

The task's `paths` plus `integration_paths` authorize only changes needed for that feature. A broad path is a permission boundary, not ownership of every file in that folder. Read the rest of the repository freely; do not modify unrelated code. User-approved task scope takes priority over historical QA-only or folder-only roles.

1. Sync safely and inspect local changes, the task's assignment_history, current code and saved WIP. Never overwrite an active worker or restart its implementation from zero.
2. Inspect/claim the exact task. Read-only planning does not reserve files.
3. Before editing, reserve the actual filenames, then commit/push that reservation. Example (after claiming M1-123):

   `python production/plan/board.py lock M1-123 --by "Tanvir/codex" --files game/scripts/player/player_controller.gd`

4. Only after the reservation push succeeds may you edit those files. Rejected pushes must preserve both people's board updates; rerun `board.py check`. If another reservation won, do not edit that file: hand off saved work or use another ready task. Locks have no silent expiry. Never delete another task's lock.
5. Shared campaign/player/HUD/save/test files follow the same rule. Cooperate by making small integration edits and saving/pushing them promptly; do not hold a file for the entire feature when it is no longer being edited. Independent work in other files may continue.
6. After saving and pushing code/evidence, release your files with `board.py unlock ID --by "Name/AI"`, commit/push the release. Done/block/release also clears that task's reservations; save WIP before using those commands.

`board.py check` validates published exact-file reservations. It cannot detect unpublished changes on another machine; synchronization and a real WIP handoff remain necessary. Existing in-progress claims are preserved/transferred with their previous actor in assignment_history; a transferred claim is not evidence that its files are idle.

## Deferred and source-delivered work

The 31 `deferred_ids` cover video creation, submission preparation, manual playthrough/science/learner QA, release packaging and low-spec qualification. Do not claim or resume them during this batch. Saved claims, reports and evidence remain intact; deferral does not mean completion.

The 15 `acceptance_ids` already have reviewed source; do not reimplement them as new coding work. Their remaining requirements still apply. Once the relevant automated/full gate passes, record truthful closure evidence as board administration; never invent a pass, remove a dependency or weaken a threshold just to unblock another task. Manual qualification remains deferred.

Automated tests, real campaign integration and scripted UI verification are part of each implementation task now. Use `game/tools/run_tests.sh`; distinguish focused, native and full results. A test-only model or fixture screenshot is not a playable feature. Never mark Done before the task's acceptance is met.

## Commands

Status changes require an explicit `--by Name/AI`; another member cannot clear your reservation through done/block/release. Acceptance-only closure is permitted only for its recorded assigned member with real evidence.

- `python production/plan/board.py list --member tanvir --phase implementation`
- `python production/plan/board.py mine --by "Tanvir/codex"`
- `python production/plan/board.py show M1-122`
- `python production/plan/board.py claim M1-122 --by "Tanvir/codex"`
- `python production/plan/board.py lock M1-122 --by "Tanvir/codex" --files game/scripts/world/room_contract.gd`
- `python production/plan/board.py done M1-123 --by "Tanvir/codex" --evidence "actual required results and evidence paths"`
- `python production/plan/board.py block M1-123 --by "Tanvir/codex" --reason "dependency, saved work and resume condition"`
- `python production/plan/board.py release M1-123 --by "Tanvir/codex"`
- `python production/plan/board.py check`

General take/next CLI selection is disabled during this batch. This also prevents older unattended night-shift pickers from starting workers under their outdated commit/ownership workflow. Use named agent sessions with explicit claims and published reservations; the row above is the binding assignment. Old role/folder names do not justify choosing an excluded task.

Commit verified work under your own verified GitHub identity. Sync before implementation and each push, preserve local settings/imports and teammates' changes, use explicit staging paths, and never force-push. Keep unfinished work saved and disclosed.

## Subsequent user override: integrated 117-suite gate

On 10 November the user explicitly authorized Ramim to override task/folder ownership as needed to make all 117 existing suites pass. M1-125 is the additional Ramim integration task (51 active IDs total). Preserve other owners' published and unfinished work, record exact-file transfers/reservations, and merge against current main before publishing. Existing assignments and deferred video/submission/manual QA remain; no threshold relaxation or unverified completion is authorized.
