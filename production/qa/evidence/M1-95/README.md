# M1-95 ? cross-scene nearby prerequisites

9 November 2026. Ramim executing Atik task under explicit user authorization.

Source b1b393c: nearby_target uses the route's existing authoritative context flags for prerequisites, while retaining scene-local flags for completion checks. No physical constraint, simulation, core or UI behavior was relaxed. All three production routes already expose this helper.

Valid behavioral RED:29 checks/4 failures, both planting targets unable to request inputs after the packet scan in the prior scene. GREEN:nearby29/0 and existing P01inputs317/0, `2/2 suites passed`. Normal S01->S02->S03 calibration/scan->S04; both targets request once without auto-solving; unmet prerequisite, distance, camera frustum, obstruction and already-completed targets still reject.

The runner does not reject C++ ERROR-only lines. Complete logs disclose existing detached HUD-marker transform errors in P01inputs (Ramim M1-101) and4 ObjectDB leak warnings per suite. These occurred before this fix; no clean-log or leak-fix claim. M1-101 is next during saved M1-08 integration. Initial invalid start_at save fixture and Tara camera-aim setup errors are retained privately; corrected final fixture aims after the physics camera update and follows the normal scene prefix.

Full integrated runner and visible P01 integration/native verification remain pending. No new visible screen in this runtime-only fix. Do not mark complete-game acceptance from the focused source checks. The saved nine-file M1-08 patch afe0c747 applies cleanly to current main; it must still be finished and verified, not blindly merged.
