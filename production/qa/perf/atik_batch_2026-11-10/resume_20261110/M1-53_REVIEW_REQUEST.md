# M1-53 — reviewed raw-loading change requested from Sadman

10 November 2026. Status: **open owner request, not accepted/delivered**.
The user explicitly instructs: "The recorded owner handoff leaves the raw
AssetGeometry change to Sadman; request the reviewed change instead of editing
his scope." Atik has not edited or applied the raw change.

## Target and preserved source

Exact target: `game/scripts/asset_geometry.gd`, current committed blob
17cb725681c9074ac8b66f64ed34df73e105bc1c. `AssetGeometry.prepare()` still has an unbounded
`THREAD_LOAD_IN_PROGRESS` loop. Preserve the current eight-animation batches,
full geometry/materials/rig/face/gait behavior and existing cache policy.

References to review, not apply blindly:
- `../M1-53_asset_geometry_owner.patch` (saved candidate, deliberately unapplied).
- `origin/night/M1-53` (`f6285e4`), including the parked held-raw regressions.
- Existing `PreparationWatchdog`, `PreparationJob`, `LoadPreparation` and current
  `game/tools/test_loading.gd`; the owned component regression passes29/0.

## Requested reviewed behavior

1. Keep one owner per raw path from threaded request through final PackedScene
   publication; overlapping foreground/look-ahead callers share its outcome.
2. Bound raw polling with the existing watchdog. On expiry, show the existing
   loading card and decode independently without joining the unfinished virtual
   ResourceLoader request. Quarantine and consume a late request exactly once.
3. An old coroutine must stop publishing once recovery takes ownership, including
   after each animation-slice, pack/cache and final-yield boundary. A late result
   must not overwrite the recovered scene or clear another owner's pending entry.
4. Fix the candidate's node-lifetime guard: `root != null` is insufficient after
   `root.free()`. Use valid-instance checks/clear ownership so takeover after
   publication cannot free a dead node twice. Cover failed and cancelled paths.
5. Do not change the50ms gate, mask first-use work, clear/change caches or simplify
   assets. Do not spend credits or change user imports/settings.

## Requested delivery / Atik continuation

Publish the exact reviewed commit or branch and focused diagnostics, preserving
other active file reservations. This request does not grant or clear a competing
reservation and does not claim an extra board ID.

Required owner proof: real semaphore-held raw jobs must recover **before** their
worker is released; duplicate callers must share one publication, each late result
must be reaped once, and takeover at every publication yield must retain correct
node lifetimes and complete approved scene data.

After the reviewed change lands, Atik will safely integrate it, run the held-raw
regressions through `game/tools/run_tests.sh`, and run ten consecutive full
windowed probes on a fixed source, with complete logs/JSON/CSV/screenshots and
no missing or hidden failed attempt, followed by the required full gate. The
short earlier native probe is not this ten-run acceptance. A script watchdog
also cannot preempt a blocked native main-thread call (M1-92 is separate).

No reviewed raw change has landed as of this request. The current full collection
is an earlier fixed source and cannot certify a future owner patch.
