# M1-85 - verified import protection and fresh native reproduction

11 November2026, Tanvir/codex. **Current-source full gate and final review remain in progress.** No native crash cause or universal crash repair is claimed. M1-122/M1-123 remain Done. Manual QA/videos are deferred.

The Game-scoped LF checkout rule preserves all2939 already-LF canonical sidecar blobs without asset/font/renderer/settings edits. Mandatory setup now rejects every ERROR diagnostic even when Godot exits0, retains raw setup/suite exits, and preserves existing script/native/timeout protections. [Actual-shell regressions](unit_runner.txt):11 methods total:10passed and one POSIX-only signal fixture skipped on Windows. [Policy audit](canonical_metadata.json), [current/replay audit](audit.json).

| Matched restoration | Metadata byte changes | Raw setup / runner exit | Result |
|---|---:|---|---|
| [Original checkout1](red1_restore/runner.json) |960CRLF-only|0 /1|Two get_multiple_md5 file-open ERRORs; guard correctly runs no suite|
| [LF checkout1](green1_restore/runner.json) |0|0 /0|Clean setup and font probe5/0|
| [Original checkout2](red2_restore/runner.json) |960CRLF-only|139 /139|Fresh native crash; no suite, ERROR or backtrace|
| [LF checkout2](green2_restore/runner.json) |0|0 /0|Clean setup and font probe5/0|

Both pairs start from SHA-matched warm project/cache/profile clones and have clean same-path controls. They derive from the same retained warm input, not independent cold-cache generations. The original [replay](replay_policy.py), [stopped state](run.json) and complete raw phase logs preserve the native failure as FAIL. `run.json.complete` intentionally remains false after its safety stop. After [read-only capture](native_capture.json), the separately recorded [green-only continuation](green_continuation.json) passed and reverified the failed red2 state unchanged. No red2 retry occurred.

The fresh native log is197474bytes. Final font progress messages cannot identify the failing importer. [Snapshot manifest](native_inputs.json) covers5359post-crash files and5352files in each matching input. The retained baseline is reconstructed pre-control input, not the exact pre-crash cache. The failed snapshot is post-crash. No linked native stack/dump was available in the [narrow host diagnostic search](native_system_events.json). This supplies actionable linked engine evidence; it does not establish the historical crash's identical cause.

Current-source checking uses [current_gate.py](current_gate.py), frozen revision/game-tree and full source/LFS manifest, a fresh project cache and isolated profile, and the unchanged mandatory `game/tools/run_tests.sh`. The fresh cold focused attempt FAILED: raw editor exit0, runner1, one dummy texture_2d_initialize ERROR and no suites. [Cold result](current_gate.json), [raw logs](current_full/raw_logs.zip). The editor also autosaved project.godot (section order and removal of the default-valued web renderer key), so its byte-source guard remains failed. A separate, explicitly qualified warm-copy133-suite run is being prepared; older comms/performance failures are not asserted as current. The collector separately records collection completion and exact full acceptance, checks every expected verdict/raw log/phase exit, preserves failed logs, and checks source/player-save integrity.

[Upstream handoff draft](upstream_report.md) includes historical raw/source recovery, the fresh failure, bounded replay, version-pinned engine boundary and exact missing native diagnostics. It has not been posted externally. The active M4-20 handbook reservation is respected; [saved handbook entry](handbook_handoff.md) awaits coordinated application.

Current integration collection correction: the first warm full attempt omitted six outside-Game test fixtures, so its showcase failure is a collector-input defect, not a game regression. It was intentionally stopped and retained with exact process/stop reason in current_warm/input_capture.json; acceptance stays false. The complete-input collector freezes those six files from the same revision, records their Git/SHA256 manifest and final integrity guards, creates only an empty capture-output folder, and restarts the whole133-suite gate in a new isolated copy.

Live complete-input gate checkpoint: 129/133 suites reported,0failures; all-profile suite and remaining final suites still running. The current_complete full_gate.txt/raw archive are an explicitly incomplete live snapshot; current_gate.full_pass remains false pending final coverage/source/save/preserved-state verification. Current comms45/0, performance548/0, Garden19/0+54/0 and player_text13038/0 pass; their old failures are not carried forward.
