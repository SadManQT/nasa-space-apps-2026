# Tanvir acceptance handoff - current scoped state

10 November2026. Work remains only M1-122,M1-123,M1-85. No extra claim; all three remain blocked. Source collisione5ed6178 and movement630c9278 are preserved. The new user-approved driver edit is confined to test_garden_movement.gd and does not change runtime/controller/capsule/solids or acceptance limits.

## Latest required dependency check

At sourcef328c0c5 (game base5da9f5ea1a308313e5e0411ad3411c37e8f3301f) plus the recorded approved driver diff, mandatory Garden passes2/2 (19/0,54/0). Loading fails615/5: title52.109,campaign80.204,Garden64.977,fullcast59.503,terrain56.240ms against unchanged<50ms. Setup/suite logs have0engine/script errors; source/save guards pass. [Current commands/guards](current_acceptance_20261110/post_sync_f328/run.json), [raw timing log](current_acceptance_20261110/post_sync_f328/performance/runner_logs/test_performance_runtime.gd.log). These are fresh measurements after the HUD-splitting repair, not the old nine intervals automatically carried forward.

Dependency/owner: Ramim/M1-125 has the active measured loading/content-query work and exact reservations; Atik/M1-68 owns the timing investigation. Preserve Asif's main/route and Ramim's campaign/progression/room reservations. A current full gate becomes ready after the required loading check is green. Resume with a safe sync, focused retest of published changes, then the complete mandatory immutable-source runner. Historical folder-owner names are not blockers.

## M1-123 saved source and verification

[Approved driver and native handoff](../M1-123/current_pilot_20261110/README.md) records unchanged360sampling/25cm bounds, two fresh ordinary mandatory54/0 movement passes, ordinary native62/0 with8inspected PNGs, and a further current-source54/0 pass. It preserves an earlier54/2braking observation and62/1native input-loss failure. All16new native PNGs were inspected. The later runs recorded0key-resync events, so no lost-input producer/focus cause is claimed. The original screenshot pose/input/yaw remain unknown.

Both supplemental10FPS runs have54/0 movement assertions and2corrective arrivals, but79GLES3shader-cache errors each despite exit0. They remain failed for log integrity; shorter paths did not establish a cause. This is separate from ordinary native success, production rendering qualification and the historical cold-import crash.

## Full-run evidence and superseded blockers

The complete frozen Windows invocation atdaa01414/game1c3a0dd3 reports97/117, exit1, all117unique verdicts. Its one already-script-failed UI child has an explicitly recorded external300s guard. A separate10800s outer cap was not reached. Sixty-two engine-generated import sidecars changed bytewise; no gameplay/test/project source changed. Original save unchanged. [Full report and complete raw evidence](current_acceptance_20261110/README.md).

Newer published repairs include chapter prerequisites, UI probe fixtures/focus, props/room staging, gravity/handoff, earned-upgrade text routes and bounded complete-profile batches. Their exact source/host qualifications are linked from the report. Do not repeat older failures as current solely from the frozen list. Comms45/0 and P01inputs319/0 pass inside the frozen full, and their original marker/baseline blockers are cleared.

The older8edef source retains its separate native20/3RED to20/0GREEN and62/0movement evidence,89/115reported incomplete full attempt and24/26separate continuation. [Older diagnostic summary](regression_post_sync/diagnostic_summary.json). Those separate invocations are not a complete full pass and do not replace the later117-suite evidence.

## M1-85

[New bounded import report](../../chapters/ch01/M1-85_cold_import_2026-11-10/current_recheck_20261110/README.md): five clean cold/warm observations,285restored-sidecar errors despite outer exit0, clean retry, original native crash unreproduced. Exact blocker: original198663-byte raw log/cache/backtrace or a new failing native attempt is required to identify a supported importer/native boundary and an owned fix/upstream case. Dependency/owner: original reporting host/SDD-artifact holder; Tanvir owns the follow-up. Verified retained inputs and exact executed scripts are saved; no asset/settings/crash fix is invented.

M1-122/M1-123 resume after measured loading repair and a complete current green required gate. M1-85 resumes on original/fresh native diagnostics. Manual QA, videos, submission and release packaging remain deferred; they are not invented blockers. The locked shared handbook is preserved; a proposed progress paragraph is saved with the pilot evidence for its active writer.
