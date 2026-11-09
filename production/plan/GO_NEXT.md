# Go next / continue — current implementation batch

## 0. Binding assignment

Read [CURRENT_BATCH.md](CURRENT_BATCH.md), [MASTER_PLAN.md](MASTER_PLAN.md) section7 and your named card in [team/](team/). `tasks.json` -> `implementation_batch.assignments` is the current user-approved allowlist. It overrides earlier member/folder/QA-role assignments for these tasks. Old parked-branch notes and historical reports do not undo this reassignment.

Members: **ramim, sadman, asif, atik, tanvir, shanto**. Never rename an existing member or treat Shanto as an unnamed reviewer slot. The approved allocation is20/11/10/4/3/2 tasks in that priority order. These are not measured token/time estimates.

Video creation, submission, manual QA and release packaging are deferred. Source-delivered acceptance rows are retained separately. Never choose those rows as new coding work. All mandatory automated tests and real integration checks still apply.

## 1. Synchronize and preserve work

Use your own verified GitHub identity. Safely synchronize before implementation and every push. Save local edits first without mixing another member's work; preserve imports/settings and existing source. Never force-push. If board changes conflict, retain all members' valid updates, regenerate BOARD.html and run `board.py check` before continuing.

## 2. Choose only an assigned task

```text
python production/plan/board.py list --member tanvir --phase implementation
python production/plan/board.py mine --by "Tanvir/codex"
python production/plan/board.py show M1-122
python production/plan/board.py claim M1-122 --by "Tanvir/codex"
```

Replace the member/ID with your own approved row. Inspect preserved claims and assignment_history first. Do not duplicate existing implementation or resume an excluded old claim. Pick prerequisites before their consumers and recheck blockers before each batch. Do not use general take/next to select extra work; the CLI is disabled while this batch is active, including older unattended night-shift pickers.

Claim one task you are actually starting; commit/push the claim immediately. If genuinely blocked, record task ID, reason, dependency/owner, saved branch/files/commit and the exact resume condition. Then choose another ready ID from your row. A previous owner label alone is not a blocker. If your ready queue is exhausted, report it; an unlisted task requires a new explicit assignment.

## 3. Reserve exact files before editing

The task's paths and integration_paths authorize only edits needed for its feature. Broad paths are permission boundaries, not exclusive ownership of every file. Historical team-card folder restrictions do not block a newly assigned task.

```text
python production/plan/board.py lock M1-123 --by "Tanvir/codex" --files game/scripts/player/player_controller.gd
python production/plan/board.py check
```

Commit/push this reservation and edit only after the push succeeds. If another reservation won, preserve it and do not touch that file. Arrange a saved-work handoff or use another ready task. Do not erase another task's locks. A reservation has no silent expiry; unpublished edits on another machine cannot be detected automatically.

Save and push your implementation/evidence before releasing files:

```text
python production/plan/board.py unlock M1-123 --by "Tanvir/codex"
```

Commit/push that release. Status commands also require your identity: `board.py done ID --by "Name/AI" --evidence "proof"`, `block ID --by "Name/AI" --reason "dependency/saved work/resume condition"`, or `release ID --by "Name/AI"`. Done/block/release also clears this task's reservations, so save unfinished work before using them. Shared campaign, HUD, player, save and test files follow exactly the same one-writer rule. Make small integration edits and release files promptly when no longer editing them.

## 4. Implement the actual feature

Read AGENTS.md, the task prompt/references and relevant handbook sections. Reuse existing APIs, data, assets, saved WIP and published providers. Preserve story canon and numeric contracts. Keep gameplay values in data. Complete callers, save/retry behavior and actual campaign/UI wiring. A standalone model, a test-only scene or a fixture screenshot is not a completed feature.

Source paths outside the task's explicit scope require an owner request and scope reconciliation first. Generation credits, new character/hero-prop sheet approval and all handbook gates remain unchanged. Do not change caches, thresholds or local renderer settings to make a failing check appear green.

## 5. Verify and record truthfully

Run `game/tools/run_tests.sh`, never rely on a bare Godot exit code. Run relevant tests while implementing and the task's required full gate before Done. Keep focused, native and full results separate. Player-facing changes need scripted native UI evidence, including accessibility where changed. Manual learner/playthrough qualification remains in the deferred pool.

Log AI use in production/AI_PROMPT_LOG.md. Record evidence, exact source/tests and unresolved failures. Update the handbook when status/decisions change. Do not mark Done before the prompt's acceptance is met. Source-delivered acceptance rows may be closed administratively only when their remaining required evidence actually passes; never claim/reimplement them just to change their status.

## 6. Commit, push and continue

Use Conventional Commits with task IDs and your own verified GitHub author; no AI co-author lines. Stage explicit task paths plus intentional board/log updates. Keep unrelated game changes, .import churn, caches, backups and local settings out of the commit. Safely synchronize before pushing; preserve everyone's changes and resolve actual conflicts without deleting valid work. Never promise that future conflicts are impossible.

After each task, report ID, done/blocked status, commit, verification and next assigned ready work. Continue inside your allowlist. Keep unfinished work saved; do not hold unused claims. `board.py check` validates task records and published exact-file reservations.

## 7. Historical work

All earlier tasks and evidence remain on the board. Use `board.py list --phase deferred` or `--phase acceptance` to inspect them read-only. Their old claimed status does not authorize resuming them during this implementation batch. BOARD.html opens on the implementation phase and keeps deferred/acceptance/history available separately.
