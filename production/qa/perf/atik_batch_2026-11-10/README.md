# Atik implementation batch — saved work and verification

10 November 2026. Work was limited to M1-68, M1-53, M1-92 and M1-116.
**No task is marked Done.** Partial source, diagnostics and exact resume conditions
are saved and pushed; existing local imports/settings and teammates' changes are
preserved. The user explicitly left the raw AssetGeometry patch for Sadman.

## Saved work / blockers

| ID | Saved result | Remaining acceptance |
|---|---|---|
| [M1-53](M1-53.md) | 072c9c7 owned worker/resource/draw watchdog; real held jobs recover; actual production title/Chapter 5 cast reached; 29/0. Raw patch remains unapplied. | Sadman's reviewed raw request/publication recovery, held-raw-job tests, ten full consecutive windowed probes and complete required gate. |
| [M1-68](M1-68.md) | Existing M1-120 batching reused. M4 baseline581/0; later full performance544/0; current two fresh582/0 runs. All timing limits unchanged. | Timing cause remains unassigned: a post-integration run failed three intervals before the two passes. Original Windows post-M1-120 focused/full verification still required. |
| [M1-92](M1-92.md) | Complete native JSON/CSV/logs and title stack sample, including a failed300s attempt. Completed short probe has campaign max6607.878ms. | Matching native profile/symbols, measured scoped first-draw fix, controlled comparison, loading screenshots and independent review. No native performance fix claimed. |
| [M1-116](M1-116.md) | bd51096 native exit collector; M4 real input44/0, five PNGs, normal exit0 in9.225s; collector4 tests/6 distinct conditions pass. | Repeat on original Windows11 IntelArc130V; identify/fix any reproduced post-result teardown cause and prove bounded native termination. |

The unapplied raw-loader candidate requires owner review before use. In
particular, its takeover cleanup must check `is_instance_valid(root)` rather than
only `root != null` where a prior publication path may already have freed that
node. The parked held-raw-job tests and publication-yield tests must validate
this path; the candidate is not production-approved.

## Full runner and focused follow-ups — separate results

The complete required runner finished **86/89 suites passed**, exit1. All89 ran;
complete setup, runner and per-suite logs are in [full/](full/). Runtime source and
follow-up provenance are recorded in [full/source.json](full/source.json). This is
a frozen earlier checkpoint, not a clean-worktree or latest95-suite full pass.
The three failing attempts remain intact:

1. `test_comms.gd`: all45 assertions passed but its success line was not recognized
   by the mandatory runner. Corrected only that reporting line to `COMMS RESULT`;
   mandatory focused rerun **45/0**,1/1, and current-source rerun also45/0.
2. `test_p01_inputs.gd`: **317 checks/1 snapshot-comparison failure** (also reproduced
   once in a fresh process). Its fixture jumps to calibration without the normal
   HUD scene refresh. Adding that refresh before its baseline delivers scene
   presentation metadata; the exact same317 assertions, including full live-state
   equality across forecast, now pass. No production forecast or puzzle rule changed.
3. `test_player_text.gd`: default300s process timeout after reaching Chapter8.
   Mandatory focused rerun with only `SUITE_TIMEOUT=1500` finishes **13072/0**,
   exit0 in392.734s. No assertion, scene, text scale or loading budget was changed.
   Both attempts are retained.

Four team suites arrived after the original shell glob expanded; their separate
mandatory runs pass: hazards19/0, network35/0, rover23/0, upgrade profiles16/0.
Those results and all six original follow-ups (including the failed P01 retry)
are retained in `focused_results.json` and the corresponding `focused_*` folders.
The later successful P01 baseline correction is in `focused_p01_refreshed/`.

Team commit56cd30a subsequently added/integrated Chapter8 code and two more suite
files; it was merged without discarding either person's work. **No complete
95-suite result is claimed.** Focused validation at that56cd30a checkpoint:

| Check | Result | Evidence |
|---|---|---|
| Loading forced-stall regression | 29/0,1/1 | `final_loading_cleanup/` |
| P01 input regression | 317/0,1/1 | `final_p01/` |
| Comms regression/reporting | 45/0,1/1 | `final_comms/` |
| Performance initial attempt | 582/3,0/1 | `final_performance/` |
| Performance fresh process1 | 582/0,1/1 | `current_rechecks/run-1/` |
| Performance fresh process2 | 582/0,1/1 | `current_rechecks/run-2/` |

The failed timing intervals are Ferreira raw101.426ms, campaign105.416ms and
terrain89.746ms against the unchanged50ms limit. Recorded named main stages do
not establish their cause (campaign_ui39.306ms; original stage records lack exact
clock correlation). The fresh-process passes preserve existing caches and do not
prove a repair. Production campaign maxima on those two runs:40.428/41.353ms;
terrain27.003/25.587ms. All16 measured windows/37 retention checks remain.

## Teardown diagnostics and limited test cleanup

The frozen full run retained12 ObjectDB/4 resource exit warnings in the loading
fixture, and one ObjectDB warning in performance. A verbose focused reproduction
identifies the loading objects as Ogg audio streams/playback handles. After freeing
the test world, the fixtures now give AudioServer100ms to retire playback; the
performance fixture also asserts optional look-ahead has drained before freeing
its owner. These changes occur **after every measured entry**, without rescheduling
or prewarming measured work. The extra drain assertion makes the current opt-in
performance total582 rather than581.

The subsequent focused loading/performance logs have no leaked-instance/resource-
still-in-use exit diagnostics. The original warning logs and verbose reproduction
are retained (`full/`, `final_loading_verbose/`), including existing glTF stride
warnings. This test cleanup is not an Intel Arc or production teardown fix.

No remaining assertion failure was observed in the listed corrected focused runs.
The intermittent timing failure, original-host checks, native hitch, raw-loader
integration and a fresh full gate at the final integrated source remain unresolved.

## Reproduction

Use `game/tools/run_tests.sh` for Godot tests, with a new absolute TEST_LOG_DIR.
`M1-68.md` gives the original Windows loading collector command; `M1-116.md` gives
the Arc native exit command. The new native collector refuses existing evidence
folders and treats timeout/nonzero exit as failure even after a valid PASS marker.
All native fixtures use isolated saves. No manual QA, video, release packaging,
asset generation, credits or new tasks outside Atik's list were performed.


## Later saved-work merge and final smoke checks

Frozen checkpointd1f9a7a is published on `work/atik-loading-20261110`.
Fourteen subsequent team commits through7662115 were merged in63e40e7. Both
handbook entries were retained, and the P01 fixture retains the new physical
probe-transfer setup together with its normal HUD refresh. Teammates' source,
board updates and evidence were preserved.

Post-merge mandatory focused runs pass: **P01 inputs319/0**, **loading29/0**,
and **performance582/0**. All three process exits are0; complete setup/runner/suite
logs, retained timing trace and exact source hashes are in `merged_7662115/`.
The extra P01 checks come from the team's newly integrated calibration job.
These are scoped smoke checks, not a fresh integrated full run of the expanding
team source. The earlier full86/89 and its separate successful follow-ups remain
reported at their original revisions. No task is marked Done.
