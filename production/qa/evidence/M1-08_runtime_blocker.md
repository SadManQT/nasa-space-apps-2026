# M1-08 runtime blocker ? 8 November 2026

**Blocked, no P-01 UI source published.** Owner request M1-95 is assigned to Atik. Main remains at the delivered runtime plus board/evidence only. The unaccepted candidate is retained locally in commit `afe0c747aa89f8d72bc99c3c2512b4b18bf97a04` on `ramim/m108-await-runtime-20261108`. Do not redo or merge it blindly: finish its known retry/prediction display concerns and verification after the runtime correction.

At source base `e64c998d6899b53be55e63a93093a92f4db8f786`, `Chapter1Campaign.nearby_target()` obtains only `route.current_flags()` and uses it for required_flags. Both EX-CH01-S04 plant targets require p01_scanned from S03. `Chapter1Route.p01_view` uses the complete authoritative context instead. Parent independently inspected these functions and gate definitions.

The real campaign test completed S03 calibration/scan, entered S04, positioned the real player by the planting target and attempted actual nearby USE with UI pause false. Diagnostic:

```text
PLANTING CONTRACT current_flags={  } p01_view missing=[] previous scan=true
FAIL fresh selection for plant_alo: Walk up to the next job and face it. Press H to see where it is. paused=false
P01 PANEL RESULT: FAIL (57 checks, 25 failures)
0/1 suites passed
```

The 25 planting assertions cascade from this blocked entry. The previous `p01_inputs` suite passed317 checks after the required new-modal dismissal; all original assertions were retained. No production flag injection, direct signal workaround, duplicate model, runtime edit, or changed numeric rule. Full failure log: [M1-08_runtime_blocker_log.txt](M1-08_runtime_blocker_log.txt). Run used the mandatory-setup `game/tools/run_tests.sh p01_panel` and Windows Godot4.7.2.

First setup reimport crashed139 before any suite; one unchanged retry completed setup and produced valid missing-panel RED. This is the existing M1-85 investigation, not a feature RED or a fixed cause. No native capture, full gate or source review ran. The final fixture-only HUD refresh cleanup in the parked commit has not been rerun; do not claim final candidate GREEN.

Atik acceptance: real previous-scene scan to nearby S04 planting request, unavailable/physical rejection retained, focused P01 and full runner; publish exact handoff for Ramim. Only then resume the local candidate, preserve failing expectations, finish actual screenshots/input/focus/scaling and independent review.
