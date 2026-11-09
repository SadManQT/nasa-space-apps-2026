# M1-99 source review

Range: `8ed4678034a43859d8ad235382ff4cee6718bc17..d0c32b81a1a47de6afe8fdb106ba6f8fad3bcadd`
Scope: `CampaignRoute.retry()` message preservation and its new Chapter 1 route test. Read-only review of source, connected route/Director/PuzzleHost code, and recorded test artifacts.

## Strengths

- `game/scripts/missions/campaign_route.gd:71-73` makes the requested two-line product change: it captures the live bounded message record after route validation and before Director restore, then merges it back through the existing Director API. The API also mirrors that record into the Director retry checkpoint. Gameplay state, receipts, and revision still come from the route checkpoint.
- `game/tools/test_route_messages.gd:13-44` uses real `Chapter1Route`, `PuzzleHost.preview()` and `commit()`, then tests two retries in both paused and unpaused states, full snapshot equality apart from message metadata, shift/receipt rollback, retained Director checkpoint metadata, duplicate delivery, and empty-record retry.
- Recorded `run_tests.sh` artifacts show behavioral RED `31 checks, 10 failures` at the base game tree, followed by GREEN `31 checks, 0 failures`; the unchanged `test_director_message_metadata.gd` records `76 checks, 0 failures`. `git diff --check` is clean.

## Issues

### Critical

None found.

### Important

None found.

### Minor

None found.

## Declined to judge

- Campaign save and public message bridge (`M1-69`): separate task, absent from this range.
- Messages screen, arrivals, and unlocks (`M1-56`): separate task, absent from this range.
- Full integrated runner: pending by the task handoff; the recorded runs cover only the route and Director metadata suites.
- Fresh execution of Godot suites: this review was instructed not to run engines; test assessment uses the saved `run_tests.sh` logs.

## Assessment

**Source ready to merge: Yes.** The change matches the board's precise requested delta, and the focused test covers the regression with real route and puzzle behavior. **Full acceptance remains pending** the integrated runner; this review does not certify it.
