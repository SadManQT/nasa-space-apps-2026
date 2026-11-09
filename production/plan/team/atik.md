# MD Atik Khan — current implementation assignment

**Board ID:** `atik`. **Approved task allocation:** 4. **Priority rank:** 4/6.

Loading, performance and exit stability. Read [CURRENT_BATCH.md](../CURRENT_BATCH.md) and [GO_NEXT.md](../GO_NEXT.md) first. This batch supersedes the older role/folder card for its explicit task scopes.

## Tasks

| ID | Feature |
|---|---|
| `M1-68` | Investigate and fix reproduced Windows loading performance gate failures |
| `M1-53` | Rule out a threaded-loading deadlock at full-cast entry |
| `M1-92` | Profile and remove native first campaign draw hitch on M4 |
| `M1-116` | Investigate post-result Forward+ exit timeout on Intel Arc laptop |

Run `python production/plan/board.py list --member atik --phase implementation`, then inspect/claim a ready ID from this list. Finish existing assigned WIP before duplicating it.

## File permission and handoff

Only edit files needed for the task, inside its paths/integration_paths, after publishing exact-file reservations. These scopes replace historical folder restrictions for this batch; they do not grant blanket folder ownership. Read task assignment_history and preserve other agents' work. If a file is actually reserved, switch to another ready task or arrange a saved-work handoff. A former owner label alone is not a blocker.

## Verification and delivery

Implement actual campaign behavior, run the required automated/scripted checks, and record real results. Do not rebuild source already delivered or mark a fixture-only prototype Done. Claim no IDs outside this list; submission/video/manual QA are deferred. Commit/push verified work under your own GitHub account, safely synchronizing and preserving other work first. Never stage unrelated imports/settings or force-push.
