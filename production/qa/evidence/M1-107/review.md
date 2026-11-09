# M1-107 source review

Range: `b2948145f0b35d5b3d976ea8aae51ea171aa9a63..ca08e72`
Scope: campaign ownership of E input and real campaign/standalone regression test.

## Strengths

- `game/scripts/player/player_controller.gd:18,242` leaves generic E enabled by default and keeps the explicit `interact()` API. `game/scripts/campaign/chapter1_campaign.gd:671-672` disables only that poll on the actor returned by the shared `_place_crew()` path, which both normal and incremental room placement use. No animation or gameplay rule changed.
- `game/tools/test_campaign_interaction_input.gd:18-100` injects E into a real CampaignScene, checks the S01 station and actual P-01 panel, cancels without solving, enters chosen values, and checks the standalone legacy console. The recorded mandatory-runner RED is 26/1 for the station's duplicate Inspect; headless GREEN is 26/0. `git diff --check` is clean.
- The windowed trace identifies Mei and `motion/Idle_loop` in the campaign and does not show Sit/SitIdle or generic Inspect there. It does not establish the cause of the player's reported low pose.

## Issues

### Critical

None found in the two-line product change.

### Important

1. **Windowed input acceptance fails.** `game/tools/test_campaign_interaction_input.gd:78-87,101-109,138-143` — the frozen `ca08e72` native run ended **FAIL 31 checks, 5 failures**. Typed `10`/`0` did not populate the panel (the captured `dry_zero_observed` image still shows both fields as “Not chosen”), so forecast, confirmation, receipt, and return-to-control assertions failed. The separate legacy console assertion also failed while its actor remained in `TurnIdleL`. Diagnose the windowed event/focus and animation timing, make this test demonstrate the actual input path, and rerun it before claiming native acceptance.
2. **Clip-only assertion can miss a duplicate generic request.** `game/tools/test_campaign_interaction_input.gd:115-130` — `_has_inspect()` observes only accepted or pending Inspect clips. `PlayerAnimation.request_action()` rejects a request while another action is active; the native campaign samples stayed in `TurnIdleL`, so this assertion alone cannot prove `PlayerController.interact()` was not called. The headless RED does prove the original defect under its timing. Keep that regression and add a direct observable request count or a settled animation state if the native test must establish no second consumer.

### Minor

None found.

## Declined to judge

- Human-reported low/seated pose cause: not reproduced; the recorded trace does not show Sit/SitIdle.
- Full integrated runner: pending for the combined batch, outside this focused review.
- Hardware keyboard/controller and human playtest: the test injects engine events; these were not observed.
- Fresh Godot execution: prohibited for this read-only review; assessment uses saved runner/native logs and captures.

## Assessment

**Ready to merge: With fixes.** The product guard is narrow and the headless regression passes, but the required native real-input acceptance failed on the frozen source. Resolve the native test failures and prove the duplicate-consumer assertion under windowed timing before publishing a native pass.
