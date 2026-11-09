# M1-95 source review

Range: `14b28f8b39fc962bc582b743f48125f065c06a09..b1b393c`
Scope: cross-scene prerequisite eligibility in `Chapter1Campaign.nearby_target()` and the new real-campaign test.

## Strengths

- `game/scripts/campaign/chapter1_campaign.gd:315-329` uses the route's existing `_context_flags()` for required flags. `target_completed()` still receives `current_flags()`, and the room, range, frustum, line-of-sight, and receipt checks remain unchanged. Chapter 1, Chapter 2, and extended production routes all provide `_context_flags()`; the fallback keeps the prior behavior for other routes.
- `game/tools/test_p01_nearby.gd:17-77` advances normally through S01-S03, commits explicit P-01 calibration and scan inputs, then verifies both S04 plants are eligible for nearby USE. It checks one panel request without gameplay mutation, unmet prerequisites, range, frustum, obstruction, and completed-target exclusion.
- Recorded `run_tests.sh` artifacts show valid RED `29 checks, 4 failures` at the base game tree, then GREEN `test_p01_nearby` 29/0 and unchanged `test_p01_inputs` 317/0 (`2/2 suites passed`). `git diff --check` is clean.

## Issues

### Critical

None found.

### Important

None found.

### Minor

None found.

## Declined to judge

- M1-08 UI integration and native player input: separate parked work, absent from this range.
- Full integrated runner and native acceptance: pending with M1-08; focused suites alone do not certify these gates.
- Existing detached-marker HUD errors in `test_p01_inputs` and four ObjectDB leak warnings in both focused suites: recorded pre-existing M1-101/runner noise, outside this two-line product change. No Script or Parse Error was recorded.
- Fresh Godot execution: prohibited for this read-only review; test assessment uses the saved runner logs.

## Assessment

**Source ready to merge: Yes.** The change corrects the prerequisite source without changing completion or physical validation, and the focused regression reproduces the original failure before passing. Full and native acceptance remain pending.
