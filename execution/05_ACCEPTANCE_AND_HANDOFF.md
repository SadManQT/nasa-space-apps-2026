# Acceptance, review evidence and handoff

Apply [02_SHARED_CONTRACT.md](02_SHARED_CONTRACT.md) and [03_SYSTEM_INTERFACES.md](03_SYSTEM_INTERFACES.md) to every task. A task is complete when its deliverables integrate and its acceptance evidence exists, not when a script returns0or a generation finishes downloading.

## Before editing

- Record actual repo root, HEAD and status. Preserve unrelated modifications. Inspect the named inputs and exact current implementation.
- Declare ownership, dependency readiness, proposed outputs and whether the task touches approved assets or persistent state.
- Confirm source/engine/asset revisions. If a prompt snapshot is stale, reconcile it explicitly using current authority before execution.
- Check tools and permissions only as needed. Prepare reviewable concept art before requesting a required new-design approval; reuse existing approval for that exact scope.

## Implementation evidence

For code: include meaningful unit/transition tests and one integration fixture showing the module's real caller. Exercise successful, rejected, duplicate, paused/cancelled and save/reloaded operations where relevant. Show state revisions and exact owning IDs. Run the existing affected suites and preserve unrelated passes.

For assets: verify actual binary/import, scale/pivot, geometry/texture budgets, collision/parts/sockets and live screen slots. Review front/side/back and an in-engine contextual view in the correct anime lighting. Characters need motion, hands/feet/contact/face/hair evidence; plants need correct lifecycle/pressure/biology. A screenshot alone cannot prove smooth animation.

For scenes: start from a clean chapter entry and traverse all required gates in order, including meaningful failure/retry paths. Verify NPC locations, knowledge, radio origin, resource/inventory receipts, explicit date transitions, captions and assisted input. Record why a gate is still locked.

For audio/cutscenes: deliver sources plus supported runtime formats, exact line/scene/cue IDs, duration/loop markers, subtitle timing, origin treatment, clear speech and pause/skip/resume behaviour. Watch/listen to the result. A source URL, old master or file extension is not an integrated runtime playback test.

## Verification labels

Use precise evidence labels in the task report:

- `present`: a file/resource exists and was inspected.
- `structural-pass`: named schema/import/syntax/arithmetic checks ran.
- `functional-pass`: the module/scene ran with its caller and specified cases.
- `visual-pass`: the required images/motion were actually reviewed against current art/canon.
- `learner-pass`: documented junior-learner observations meet the task's comprehension criterion.
- `unverified`: a required check did not run; give its concrete reason and the next smallest action.

Do not promote one label to another. Report commands, tool versions, exit codes and concise outputs; distinguish a newly executed result from quoted historical evidence. Failed assumptions and counterexamples are useful evidence and must not be erased to obtain a green summary.

## Runtime acceptance baseline

1. No missing resource/import/script error on the agreed boot/export route.
2. A command is validated once and committed at most once. Preview has no side effects.
3. Pause/reading/caption backlog preserve resources and scenario time.
4. Save/load and retry preserve the authoritative checkpoint and do not duplicate items, upgrades, receipts, voices or timers.
5. Scene/mission progression reflects completed world predicates, not a watched film or clicked answer alone.
6. Keyboard/controller/assisted input reach the same story, information and rewards. Essential information survives mute and large text.
7. Knowledge, actor presence and radio-path labels are correct before/after relevant reveals and outages.
8. Every changed asset has current source/provenance, runtime output and state/interaction specification.
9. Existing approved assets and unaffected behaviours remain intact; changed pipeline tools get code review under the repository workflow.
10. No secret, raw generation junk, missing LFS object or unrelated file enters a commit/package. Commit/push only on explicit user request.

## Required handoff report

Create a concise report at a coordinator-agreed location such as `production/review/execution/<TASK-ID>.md`. That path is proposed; use an existing equivalent convention if the project establishes one. Include:

```text
Task ID / owner / date / source HEAD
Goal and exact ownership
Inputs inspected and their revisions
Files created/changed; generated sources/runtime exports
Public interfaces and example command/result
Dependencies consumed and next tasks unblocked
Executed tests: command, version, exit code, actual result
Visual/audio/learner evidence and what was reviewed
Pause, duplicate-input, cancel, failure, save/load behaviour
Canon, numeric, roster and inventory checks
AI generation/licensing log entries, if any
Known limitations and unexecuted checks
Manifest/handbook/handoff updates
Ready-for-integration decision and concrete next action
```

## Completion discipline

The coordinator updates a task board and the relevant production status after reviewing evidence. Use a reversible replacement procedure for an approved asset, preserving the known-good version until the new import and contextual review pass. Clean only exact owned temporary outputs. If a tool cannot run, report the limit and continue independent authorized work; do not claim a render, import, paid call or playtest occurred.
