# Abu Sayem Mohammed Tanvir — current implementation assignment

**Board ID:** `tanvir`. **Approved task allocation:** 3. **Priority rank:** 5/6.

Garden collision/controller fixes and cold-import investigation. Read [CURRENT_BATCH.md](../CURRENT_BATCH.md) and [GO_NEXT.md](../GO_NEXT.md) first. This batch supersedes the older role/folder card for its explicit task scopes.

## Tasks

| ID | Feature |
|---|---|
| `M1-122` | Match garden collision to visible furniture and check return-lane clearance |
| `M1-123` | Reproduce garden return-to-center stop with the real player controller |
| `M1-85` | Investigate Windows cold editor-import crash captured before UI tests |

Run `python production/plan/board.py list --member tanvir --phase implementation`, then inspect/claim a ready ID from this list. Finish existing assigned WIP before duplicating it.

## File permission and handoff

Only edit files needed for the task, inside its paths/integration_paths, after publishing exact-file reservations. These scopes replace historical folder restrictions for this batch; they do not grant blanket folder ownership. Read task assignment_history and preserve other agents' work. If a file is actually reserved, switch to another ready task or arrange a saved-work handoff. A former owner label alone is not a blocker.

## Verification and delivery

Implement actual campaign behavior, run the required automated/scripted checks, and record real results. Do not rebuild source already delivered or mark a fixture-only prototype Done. Claim no IDs outside this list; submission/video/manual QA are deferred. Commit/push verified work under your own GitHub account, safely synchronizing and preserving other work first. Never stage unrelated imports/settings or force-push.

M1-122, M1-123 and M1-85 are your implementation tasks now. Do not resume M1-65 or wait for Sadman/Atik merely because older collision reports name them.
