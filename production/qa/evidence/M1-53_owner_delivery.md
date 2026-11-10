# M1-53 owner delivery: bounded raw loading in AssetGeometry (M1-126)

10 November 2026, Sadman (Claude Code). Answers
`production/qa/perf/atik_batch_2026-11-10/resume_20261110/M1-53_REVIEW_REQUEST.md`.
Target: `game/scripts/asset_geometry.gd`, previous blob `17cb725681c9074ac8b66f64ed34df73e105bc1c`.
The saved candidate `M1-53_asset_geometry_owner.patch` was reviewed and reworked, not applied as is.

## What changed, by requested point

1. **One owner per raw path.** `_preparing[path]` holds one `{done, success, recovering}`
   record from the threaded request to PackedScene publication. Overlapping callers wait on it
   and share its outcome (one raw decode for two callers).
2. **Bounded polling.** The `THREAD_LOAD_IN_PROGRESS` loop is now
   `PreparationWatchdog.wait_until("raw_decode:<path>")`. On expiry `_recover()` shows the existing
   loading card (`PreparationWatchdog.fallback`) and decodes with `load_glb()`, a direct
   GLTFDocument decode that never joins the `.lla_gltf` request. The unfinished request goes to
   `PreparationWatchdog.retire_resource` and is reaped once. `request()` returns `ERR_UNAVAILABLE`
   while a path is quarantined or the session breaker is open, so it is never requested again.
3. **Old coroutine stops publishing.** After every yield (first main-thread frame, each
   animation slice, before pack, after pack, final yield) the owner checks `pending.recovering`,
   frees its half-built root and returns the recovery's result. `_finish()` only clears
   `_preparing[path]` when it still holds the same record (`is_same`).
4. **Node lifetimes.** `_superseded()` frees only through `is_instance_valid`, and the root is set
   to `null` after its normal free, so a takeover after publication cannot free twice.
5. **Unchanged.** 50 ms gate, `ANIM_BATCH_SIZE` 8, `CACHE_LIMIT` 28, `_remember()` policy,
   assets, imports and settings. No credits.

## Differences from the candidate

- Missing files and failed decodes still return `false` with no card and no breaker (the
  candidate sent them through recovery; `test_performance_runtime` expects "fails without blocking").
- A caller waiting on a recovery in progress waits for `done` instead of a second timed wait, so a
  short timeout cannot make it return `false` while the recovery is still decoding.
- The quarantine check in `request()` and the `is_same` guard in `_finish()` are new.

## Proof (all through `game/tools/run_tests.sh`, macOS, headless, source = this commit)

- `test_asset_geometry_recovery.gd`: PASS, 49 checks, 0 failures. Real semaphore-held raw job:
  both callers recover before `gate.post()`; one request for two callers; quarantined path reloads
  without rejoining; late result reaped once and does not replace the recovered scene; takeover
  forced at 9 successive publication frames of CH_Kai (sliced animations), each with both callers
  true, identical clip and mesh counts, and no later publication. Before the change the suite did
  not load (`_preparing` missing).
- `test_loading.gd`: PASS, 29 checks, 0 failures.
- `test_performance_runtime.gd`: PASS, 545 checks, 0 failures, 50 ms limit unchanged.
- `test_habitat_rooms.gd` 360/0, `test_room_presentation.gd` 155/0.

## Not done here (Atik's continuation of M1-53)

The ten consecutive windowed probes on a fixed source, the Windows host runs and the full
117-suite gate were not run. A script watchdog still cannot preempt a blocked native main-thread
call (M1-92 is separate).
