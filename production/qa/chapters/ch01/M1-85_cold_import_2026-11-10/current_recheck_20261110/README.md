# M1-85 - bounded frozen-source import recheck

10 November 2026, Tanvir. **Historical native crash remains unreproduced; task stays blocked.** No game, asset, font, renderer, engine, production-setting or test-threshold patch is made for this investigation.

This new experiment freezes source `daa014145922e2646027140f3bd34c53a0afe3cb`, game tree `1c3a0dd3517226d7c9c3a79138249593e4955d2a`. It contains3343 verified game files /1077145226 bytes, with local LFS payloads checked. Godot4.7.2 official.ed1daf0bf on Windows11/Core Ultra5 226V/Arc130V; exact hardware/driver, executable hash and source manifest are in [cold state](cold_matrix/repro_state.json). Each copy uses isolated app data and project import cache; OS filesystem cache is not evicted. The completed Windows full gate exited before any experiment engine started. [Sequencing and exact commands](collection.json).

Two direct editor invocations and six mandatory `game/tools/run_tests.sh hint_player` calls are bounded, with complete raw editor/setup/suite logs. Existing corrected collectors were reused unchanged; their exactly executed bytes are in [executed_scripts](executed_scripts/). Nested setup/suite logs are audited before cleanup or success decisions. No passing outer summary overrides an import error.

| Invocation | Seconds | Raw outer exit | Engine / script errors |
|---|---:|---:|---:|
| native_first / cold_editor | 300.296 | 0 | 0 / 0 |
| native_first / warm_editor | 5.859 | 0 | 0 / 0 |
| native_first / warm_runner | 14.399 | 0 | 0 / 0 |
| runner_first / cold_runner | 286.309 | 0 | 0 / 0 |
| runner_first / warm_runner | 14.313 | 0 | 0 / 0 |
| sidecar / warm control | 41.071 | 0 | 0 / 0 |
| sidecar / tracked sidecars restored | 338.881 | 0 | 285 / 0 |
| sidecar / unchanged retry | 17.404 | 0 | 0 / 0 |

All six hint calls report124/0 and1/1. All raw outer exits are0. The cold/warm matrix has zero engine/script errors. The restored-sidecar case is nevertheless **FAILED for import integrity**: its setup contains285 engine errors (133 Unrecognized UID,133 Can't find file,19 `f.is_null`), no script error and no native crash. The corrected collector records `all_runs_successful=false` and retains the project. [Full restored setup](sidecar_restore/restored_sidecars_runner_logs/setup.log), [complete invocation record](sidecar_restore/restored_sidecars_runner.json), [comparison state](sidecar_restore/state.json). The unchanged retry is clean; that does not erase the preceding failure.

The observed file-access boundary is `get_multiple_md5 (core/io/file_access.cpp:967)`. It is an import-integrity symptom, not the cause or reproduction of the historical exit139.

The comparison has a clean warm control. Restoring1190 tracked sidecars through Git checkout filters changes only one file beyond line endings: `T_Kit_Steel_Normal.png.import`. UID, compression/normal-map and mipmap metadata differ together; no single field is isolated. The earlier separate64a2d08 comparison had440 errors and two non-CRLF files. Keep those observations at their own frozen inputs; neither proves the native crash's cause. [Restoration hashes](sidecar_restore/restored_sidecars.json), [exact differing warm-input bytes](warm_input_sidecar_payloads.json).

## Preserved state and limits

The experiment directory remains local **after the unchanged retry**; it is not a separately frozen pre-error cache. The untouched QA source warm cache still matches all2493 copied-cache hashes, and all1190 input-sidecar hashes match. Those inputs reconstruct this experiment's precondition. Exact local paths, counts and verification are in [retained_input_validation.json](retained_input_validation.json). Only manifests/logs are committed; scratch caches and user profiles stay local.

The original198663-byte raw log, original cache and original native backtrace have not been identified in the checked diagnostic locations. Its expected SHA is `effac2b310a27c472845d20f7175dfd4ec35052c5f912919ffa433cf190f43ac`; the [published excerpt](../../../../evidence/M1-64_setup_failure.txt) still records the7November exit139. The original local046662c game object is unavailable here; reachable historical baselines are recorded in [source availability](historical_source_availability.json). No exact original-source equivalence is invented.

One pre-existing local Godot minidump has internal timestamp2026-09-11T10:39:33Z. No matching raw log/cache/source or stack links it to7November, so it remains an unlinked lead. [Metadata-only availability record](diagnostic_availability.json); memory-dump contents are not published. The last printed GochiHand font import is still not a cause diagnosis; the earlier [font identity evidence](../font_identity.json) remains valid at its recorded inputs.

The separate M1-123 supplemental10FPS native diagnostics each report79file-access errors at `_save_to_cache (drivers/gles3/shader_gles3.cpp:648)` despite54/0 movement checks and exit0. A fresh shorter profile gives the same79errors. Both remain failed for log integrity. This is a different observed boundary from get_multiple_md5 and is not linked to the original exit139. [Separate exact native diagnostics](../../../../evidence/M1-123/current_pilot_20261110/README.md). No renderer/cache setting was changed to clear them.

## Handoff

Task: **M1-85, Tanvir**. Saved work: five clean cold/warm observations, one285-error restored setup despite exit0, clean unchanged retry, exact executed collectors, complete raw logs and verified retained warm inputs. The corrected audit is now exercised on real new engine runs, including its negative path.

Precise blocker: no native failure/backtrace identifies the historical importer/engine boundary for an owned fix or an actionable native-crash case. Dependency/owner: the original reporting host/SDD-artifact holder (task filed by Ramim/codex), or a fresh failing native attempt with its source/cache and diagnostics; Tanvir owns this follow-up. Resume when those original artifacts or a new bounded native failure are available. Current UID/file-access evidence can support a separate narrowly controlled importer investigation, without claiming it explains exit139 or rewriting production metadata.

All three Tanvir tasks remain within their assignment. No extra task is claimed. Manual QA, videos, packaging and submission remain deferred. [Artifact hashes](artifacts.json).
