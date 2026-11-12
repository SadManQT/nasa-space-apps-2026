# Atik — opening campaign blockers, 13 November 2026

M1-127 is the user’s explicit two-bug assignment. Baseline: 798b10aa; published reservations: 33fc0e83 and 24fe7b55. No other tasks, calibration thresholds, exterior slope limits, assets, local settings or player save files were changed.

## Doorway movement: reproduced cause and repair

The production Commons player walked into the Safe Room connector with real movement input. The passage guidance appeared, the campaign remained unpaused, and the player remained enabled. At x=11.11669, y=-0.026165, the floor-edge contact reported a 25.664743° normal. EvaSuit classified this indoor contact as lunar `no_go`, returning zero movement speed in every direction. Opposite input turned the character but left the position unchanged. This reproduces the user’s apparent popup freeze; the popup does not pause the game.

EvaSuit now treats indoor footing as station flooring and excludes exterior terrain tags. Collision remains active; the existing exterior24° no-go classification, suit drain, payload/load handling and slope limits are unchanged. The same actual-player test now enters the connector to x=12.12451 and returns to x=9.25615. A separate negative check retains zero speed on an exterior26° slope.

## Probe: reuse the model, connect the missing playable flow

The original ProbeCalibrationJob and its save format are reused unchanged. Previously the P01 route refused preview/commit until retrieve → place → observe completed, while only test fixtures called those operations. The HUD now launches a campaign-bound activity when the player uses the unfinished calibration target. The approved existing probe appears on its rack, in the player’s RIGHT hand and at the dry-reference cradle, following the model’s single ownership state.

E performs the next step only within3m and clear line of sight. Normal WASD/mouse movement continues. Esc returns a carried probe to its rack, preserves an already placed probe, restores the HUD and permits retry. Every accepted step saves through the normal campaign service. Continue reconstruction preserves mid-carry ownership. Reading zero opens the unchanged P01 choices; it does not silently commit or bypass dry10→0, wet110→100 and recheck0/100.

Exact game files: `game/scripts/eva/eva_suit.gd`, `game/scripts/ui/chapter1_campaign_hud.gd`, new `game/scripts/ui/probe_calibration_activity.gd` and its UID. New regression: `game/tools/test_opening_blockers.gd` and its UID. No change to Asif’s reserved `chapter1_campaign.gd`, provider tests, handbook or AI log. No generated assets or paid services.

## Verification

- Baseline mandatory runner:0/1; actual door retreat failed. Diagnostic confirms indoor no-go at25.664743°.
- Intermediate attempts are retained, including a test save-key typo (`route` versus existing `route_runtime`) and an omitted indoor test precondition. These are not counted as passing runs.
- Focused `game/tools/run_tests.sh opening_blockers`:29checks,0failures,1/1. Real E events open and operate the activity; no probe-transfer fixture is called. Includes reach rejection, carried/placed cancellation and retry, Continue reconstruction, original panel calibration and restored movement.
- Rendered Metal/Forward+ M4 run:29checks,0failures, normal exit; three actual campaign captures were inspected (door escape, carried probe, calibration completion). Temporary isolated saves only. This is scripted integration evidence, not human learner QA or performance certification.
- Full gate: pending; results will be added before closure. Full runner uses its default limits; no assertion or timing threshold is weakened.

Source work and tests are isolated in the existing Atik release worktree. The user’s44local editor/import modifications and UI concept images remain preserved in the main working folder. The gameplay save is untouched; automated checks use unique temporary user/save directories. The already-running editor/game process is not killed.
