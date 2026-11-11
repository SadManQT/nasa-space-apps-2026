# M1-116 - original Intel Arc bounded exit acceptance

11 November 2026, Tanvir/codex. **Current bounded exit acceptance: PASS.** The user explicitly reassigned this ID; the earlier Atik collector and all historical evidence are preserved. No Game source change or runtime repair was needed for the successful current runs.

Source: `802624b12087011fdf4da5d450368fae4f3ba426` (reservation-only commit on main `fe52a2ee`). Exact Game tree and every selected source hash are in [provenance.json](provenance.json). The unchanged production input fixture, QA capture adapter and native collector run the actual campaign: real E, unset calibration UI, cancel/reopen, typed dry-reference values, preview/confirm, receipt and return to control. Published probe-transfer integration adds one assertion versus the original 44-check native evidence.

| Attempt | Fixture result | Native / runner exit | Duration | Raw diagnostics |
|---|---|---|---|---|
| Initial isolated editor refresh | No suite ran | Editor 0; runner 1 | 68.902s | **FAIL:** dummy-renderer `Parameter "t" is null` |
| Separate warm mandatory `run_tests.sh campaign_interaction_input` | 39 checks / 0 failures; 1/1 suites | 0 | 17.684s | None |
| Warm Forward+ / Vulkan, first native process | 45 checks / 0 failures | 0, normal | 28.208s | None |
| Warm Forward+ / Vulkan, second native process | 45 checks / 0 failures | 0, normal | 20.997s | None |
| Warm Compatibility / OpenGL, comparison | 45 checks / 0 failures | 0, normal | 16.829s | None |

Both Forward+ banners identify Vulkan1.4.359 / Intel Arc130V; there was no renderer fallback. PASS was first observed at26.646s and20.085s; process completion followed at the durations above, well inside the unchanged180s guard. No forced timeout/termination or live-hold dump was needed. Collector exit is checked separately from the printed result, and raw errors are independently rejected.

The separate Windows CIM lifecycle monitor captured launcher -> actual engine pairs `20948 -> 18076`, `26796 -> 21156` and comparison `24988 -> 22360`, with each exact path/command and all six observed absent afterward. The final query found no matching processes. Sampling times are observations, not exact kernel exit timestamps.

## Host, source and isolation

Windows11 Home10.0.26300 x64, Intel Core Ultra5 226V, Intel Arc130V8GB, driver32.0.101.9150, Godot4.7.2.stable.official.ed1daf0bf. Both console launcher and companion executable were hashed before collection. Requested window size1280x720; all15 captured PNGs are1920x1080 on this host. The five first-Forward screenshots were opened: commission before/after, dry-zero before, unset panel, completed result. The panel visibly starts with Not chosen values and later explains zero10->0 and the next wet-reference step.

[collect.py](collect.py) is the exact executed machine-local orchestration helper (SHA in provenance). It imports the unchanged published collector with ROOT/INPUT redirected to the byte-verified test copy and observes launcher PIDs; a separate monitor verifies the actual companion engines. The helper's optional launcher hold dump alone would not identify the engine cause. On recurrence, collect actual companion native stacks/modules before selecting a repair.

The first copy retained a prior warm M1-85 editor cache and then announced a1656-step reimport batch. Its error is a failed import-refresh qualification; no native attempt ran there. Its project/cache/profile remain at `.codex/m116-arc-20261111`, untouched by the continuation. The distinct `.codex/m116-arc-warm-20261111` project copied that post-import cache at a new path with a fresh isolated profile. All three successful native processes share this new warm project/cache/profile; they are not independent cold-cache trials.

Only editor-generated `project.godot` normalization differs in the test copies: section/key ordering and removal of the explicit web renderer default `gl_compatibility`. Its output SHA8b502616 matches the previously reviewed [M1-85 normalization](../../chapters/ch01/M1-85_cold_import_2026-11-10/resolution_20261111/current_complete/current_gate.json). The Windows original normalizes from CRLF to exactly the known canonical LF SHA cff48a51; no other setting value changed. The first helper's byte-only original-hash guard remains false in its saved record, with this explanation retained separately. All tracked Game sources in the editing worktree remain byte-identical to their pre-run state, and the actual player save SHA remained `d6ccd5e08f297a131f344bfad1286a24986de9fbde66aa7b6b6d67f30e34b702` across both attempts. Existing player saves were neither loaded into the fixture nor rewritten.

## Evidence, remaining limits and resume condition

[raw_logs.zip](raw_logs.zip) retains complete focused setup/suite logs and phase exits; each native engine/stdout log, manifest, five screenshots and trace; launcher observations; and `native_process_monitor.jsonl`. `initial_failed_setup/` retains the exact original helper, original failed provenance and its raw archive. [artifacts.json](artifacts.json) hashes all published files and every archive member. The original Nov9 native/Compatibility manifests retain hashes `df7896695130354f1a5d8fa76939447ea70a82a85ea80dcd68cad70a07713d37` / `ba913ef87d46a65d8fc4afa7f2f581ee3f3ac4097e56cf8a97c8cf47907181ea`.

[Independent review](review.md) recommends Done for the current original-host bounded-exit scope. The Nov9 post-PASS180.017s timeout remains real historical failed evidence; its cause is unknown and did not recur in the two current Vulkan runs. No driver, deadlock, movement or universal native-crash repair is inferred. The initial dummy-renderer import error is still a failed setup result.

Full-suite evidence remains separate: [M4-21](../M4-21/README.md) records the user's accepted134-suite split verification and its limits. No new full-suite invocation or clean global gate is claimed for this QA-only change. Prior M1-85 cold/raw-diagnostic limits remain. Manual QA, videos and release work remain deferred.

**M1-116 blocker:** none for current acceptance. **Saved work:** source-pinned helper, three native attempts as above, raw archive, preserved initial failed copy. **Dependency/owner if the timeout returns:** the engine/runtime investigator needs the same original Arc host and the exact live companion PID/command plus thread/module diagnostics. **Resume condition:** a fresh retained valid-PASS run followed by a live companion hold; preserve that failure and diagnose it before a cause-based repair.
