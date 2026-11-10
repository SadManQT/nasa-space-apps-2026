# M1-123 - Real campaign Garden contact recovery

10 November 2026, Tanvir. **Source delivered; acceptance blocked on the global automated gate.** Published source630c9278 adds only test_garden_movement.gd and its UID. No runtime/controller edit was needed for the recorded cases; other members' reservations and newer gameplay changes are preserved.

The regression uses actual SaveService save/load in isolated storage, restores production CampaignScene at EX-CH01-S11/LOC-03 and lets the real PlayerController process keyboard and analog gamepad events. It separately asserts authoritative BLOOM versus MISSION_STOPPED ending and mission status, so the adverse variant cannot silently duplicate the safe one.

For each ending/input pair, one fixture placement starts outside furniture near the photographed corner. Injected input reaches a named tara_bay contact. Recovery changes only movement input: reverse away, steer around the outer side and clear front lane, return to the center. No transform, velocity, facing or animation is written during recovery. Normal camera recenter/steering/step-up, world+crew collision mask3 and capsule radius0.27m remain active. Each trial checks grounded arrival, unpaused/unlocked control and unchanged mission gates/resources.

## Current synchronized verification

Game tree `8edef085d1dcc51ee5c4b6974c31905cd6441da1`; current native manifests include before/after source hashes and bounded capture timestamps.

| Check | Result |
|---|---|
| Mandatory Garden runner | **2/2**, collision19/0 and movement54/0. [Runner](../M1-122/regression_post_sync/garden/runner.txt), [raw movement log](../M1-122/regression_post_sync/garden/logs/test_garden_movement.gd.log), [trace](../M1-122/regression_post_sync/garden/logs/movement_trace.json) |
| Mandatory habitat_rooms | **360/0**. [Runner](../M1-122/regression_post_sync/habitat_rooms/runner.txt) |
| Automated current native run | **62 checks,0 failures; exit0;8 PNGs**. [Manifest](native_post_sync/run.json), [input/contact/camera trace](native_post_sync/movement_trace.json), [raw log](native_post_sync/capture.txt) |
| Current continuous full attempt | **Incomplete at the separate40-minute collection cap**:89/115 reported;73 passed/16 failed. [Raw runner](../M1-122/regression_post_sync/full/runner.txt) |
| Separate continuation | **24/26 targets passed;2 failed**, separate invocations. [Verdicts](../M1-122/regression_post_sync/diagnostic_summary.json) |

All8 current PNGs were opened and inspected. [Stopped-mission controller contact](native_post_sync/M1-123_mission_stopped_controller_contact.png) and [return to center](native_post_sync/M1-123_mission_stopped_controller_returned.png) show actual dose6; equivalent keyboard and BLOOM pairs are retained. The avatar is standing and recovered to the center in each return image. Existing bright surfaces, translucent HUD and dialogue remain visible; no UI-quality fix is claimed. Godot4.7.2, Windows/Intel Arc130V, Compatibility1280x720; input is engine-injected, not physical hardware or human play. The current native log has0 ERROR/SCRIPT ERROR lines and15 existing UID/TAA warnings.

The original screenshot's exact transform/input/yaw was never recorded. These are labeled collision-free candidate starts, with actual subsequent contact, collider names, state and input recorded. This establishes recovery in those production campaign cases, not an exact historical replay or proof against every trap. Walking through the solid bench remains blocked. Broader habitat checks cover four story-room routes, navigation/door approaches and door-state collision; they do not claim input-driven crossings of every doorway. M1-122 corrects measured excess volumes; no separate runtime-controller cause has been established.

[Acceptance handoff](../M1-122/acceptance_blockers.md) lists all current global failures and exact resume condition. Both Garden suites also pass inside the broader attempt, but Done requires a complete passing mandatory full runner after owners repair its remaining failures. Manual QA, packaging, release, submission and video remain deferred. [Player-save guard](../M1-122/save_guard.json) confirms the original save hash is unchanged.

Earlier [native62/0](native/run.json) and [focused54/0](../M1-122/final_focused/runner.txt) are retained as pre-sync evidence, with their own older source hashes and25 native warnings. Independent review requested authoritative ending/status guards and accurate source/capture provenance; both are implemented and verified. [Review](review.md).
