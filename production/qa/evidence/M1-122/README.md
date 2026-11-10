# M1-122 - Garden furniture collision correction

## Accepted integration closure - 10 November 2026

**M1-122 acceptance is verified; final board reconciliation pending.** [Current acceptance record](acceptance_20261110_unblocked/README.md) combines the existing source/focused/native evidence with the explicitly accepted119-suite coverage on the identical current game tree. Two original-Windows performance checks now pass618/0; the earlier615/5/comms/full-gate blockers are superseded. No game source was changed for this closure. Exact-pose, native-snapshot, peer-report and failed sparse-diagnostic limits remain documented. M1-85 remains separately blocked on original/fresh native-crash diagnostics.

## Historical source-specific handoffs (preserved)

The reports below describe their recorded snapshots and earlier blocked status; they do not override the current acceptance record above.

10 November2026 - latest scoped handoff: collision sourcee5ed6178 is preserved. Current post-sync sourcef328c0c5 plus the approved M1-123 pilot refinement passes mandatory Garden2/2 (19/0,54/0). The fresh loading dependency check fails615/5 after the HUD repair: title52.109,campaign80.204,Garden64.977,fullcast59.503,terrain56.240ms against unchanged<50ms. No current full pass is claimed. [Latest/frozen results and newer owner repairs](current_acceptance_20261110/README.md), [exact current commands](current_acceptance_20261110/post_sync_f328/run.json), [pilot/native handoff](../M1-123/current_pilot_20261110/README.md).

The complete frozen Windows run atdaa01414 is97/117, not the older incomplete115-suite attempt. Subsequent published UI/chapter/room/handoff/text/profile repairs supersede corresponding older failures; comms45/0 and P01inputs319/0 are confirmed passes. M1-122 remains blocked on the measured loading repair and a complete green current gate, not on old comms reporting or historical folder ownership.

## Earlier delivered source and evidence

10 November 2026, Tanvir. **Source delivered; acceptance blocked on the global automated gate.** Published source: e5ed6178. Explicit user reassignment authorizes only LOC-03.json, the new collision regression/UID and this evidence; other members' source and newer care/narrative props are preserved.

Tara's full-width upper-air box is replaced by its solid 0.8m-high bench and a separate conservative 0.8m enclosure box. The crop-rack proxy is 0.73 x 2.01 x 1.46m, covering the measured visible bounds with a small margin instead of extending about12.7cm beyond each end. The adjacent Seed Archive proxy already matches its visible dimensions. This task changes no art, story, puzzle numbers, global capsule or controller/runtime code.

The regression restores an actual EX-CH01-S11 production CampaignScene checkpoint. It checks empty upper air, positive collision on the elevated enclosure, rack-front capsule clearance, solid bench/rack, the return lane and deliberately blocked bench diagonal, all four Garden navigation approaches, both pressure doors open/closed, and unchanged gates/resources. Geometry assertions pause automatic player physics and move its real body directly; M1-123 separately tests actual input and steering.

The habitat suite covers all four Chapter1 story rooms using scripted PlayerController-body traversal, navigation to interaction/door approaches and open/closed pressure-door rays. It does not claim full-capsule or input-driven crossings of every doorway. Actual input, camera and contact recovery are exercised at the Garden corner by M1-123.

## Earlier d143 synchronization check

After later teammate integration, the latest tested game tree is `d1436027711ea9bf1721ac7dd4bf4f01564ef197` (source bf19dff7, containing the final upstream sync plus evidence-only commits). A fresh mandatory Garden runner passes **2/2: collision19/0, movement54/0**. The fresh comms runner still fails **0/1** because its45/0 assertion output lacks the recognized result marker. [Latest commands/source](final_sync/run.json), [Garden](final_sync/garden/runner.txt), [comms](final_sync/comms/runner.txt).

The native and broader diagnostics below deliberately remain tied to their recorded **8edef** snapshot. They do not claim full/native verification of the later34-file upstream repair. Some older failures may have been repaired there; the latest comms blocker and absence of a complete current full pass still prevent Done.

## Recorded 8edef verification

Game tree `8edef085d1dcc51ee5c4b6974c31905cd6441da1`; source2b848e34, with status-only HEAD76621158 at capture time. [Commands, local metadata and isolated profile](regression_post_sync/run.json).

| Check | Result |
|---|---|
| Mandatory focused Garden runner | **2/2 suites passed**: collision19/0, movement54/0. [Runner](regression_post_sync/garden/runner.txt), [raw logs/traces](regression_post_sync/garden/logs/) |
| Mandatory habitat_rooms | **360 checks, 0 failures; 1/1**. [Runner](regression_post_sync/habitat_rooms/runner.txt) |
| Paired current-campaign native baseline | **Expected RED:20 checks,3 failures; exit1**. Only original room obstacle data from7f5bbb33 substituted; newer staging preserved. [Source/timestamps](before_native_post_sync/run.json), [before PNG](before_native_post_sync/M1-122_garden.png) |
| Paired corrected native run | **20 checks,0 failures; exit0**. [Source/timestamps](native_post_sync/run.json), [after PNG](native_post_sync/M1-122_garden.png) |
| Native actual-input companion | **62/0**, four ending/input pairs,8 PNGs. [M1-123](../M1-123/README.md) |
| Current continuous full attempt | **Incomplete at the separate40-minute collection cap**:89/115 reported,73 passed/16 failed; no full summary. [Raw runner](regression_post_sync/full/runner.txt) |
| Separate unreported-suite continuation | **24/26 targets passed;2 failed**. Separate mandatory invocations, not a full-run pass. [State](regression_post_sync/continuation/state.json), [exact target verdicts](regression_post_sync/diagnostic_summary.json) |

Both current before/after PNGs were opened and inspected. They show the real campaign near Archive/Tara; a collision-data correction intentionally has the same visible art. Godot4.7.2, Windows/Intel Arc130V, Compatibility1280x720. Native manifests verify source hashes before **and after** each child and require PNG mtimes inside its start/end interval. Baseline room substitution restores exact fixed bytes in `finally`; the production room has no residual diff. Both paired logs have0 ERROR/SCRIPT ERROR lines and12 warnings (TAA and existing kit UID fallback); warning-free rendering is not claimed. Existing bright surfaces, translucent HUD and dialogue overlay remain visible; this is not a UI-quality fix.

[Original player-save guard](save_guard.json) confirms its SHA-256 is unchanged after all runs. Automated profiles isolate saves; no raw player save is published. Manual QA is deferred by the user.

## Acceptance blocker and history

[Complete blocker handoff](acceptance_blockers.md) separates current failures, the continuous-attempt cap, all26 continuation targets and the earlier source. Recorded failures cover calibration/UI/fixture integration, Chapter6/8 mission entry, visible narrative/puzzle staging, gravity, comms marker, performance, player-text timeout and upgrade-profile witnesses. Any remaining failures need owner repair, and a complete current mandatory full runner must pass before Done. No test, setup guard, physics mask, pressure solid or timing limit was weakened.

Earlier retained evidence is explicitly **pre-sync**, not the current campaign fingerprint: [headless RED19/3](final_red/runner.txt), [Garden2/2](final_focused/runner.txt), [older baseline native19/2](before_native/run.json), [older corrected native20/0](native/run.json), and [older full91/95](regression/run.json). The baseline19/2 predates the review-added positive enclosure assertion. The old full spans a [large wall-clock gap](regression/clock_observation.json); aggregate duration is not a controlled benchmark.

Independent review requested the positive enclosure assertion and M1-123's authoritative ending/status assertions; both are implemented and pass. It reviewed exact scope, route/door coverage and native-capture safety/provenance. The historical screenshot's exact pose/input/yaw was not recorded. These results establish the measured geometry correction and selected live recovery cases, not an exact historical deadlock replay or a general proof against every movement trap. [Review](review.md).
