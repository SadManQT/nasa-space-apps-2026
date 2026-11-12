# Atik export and qualification handoff — 12 November 2026

Owner: Atik/codex (`atikdevx`, verified GitHub email). Requested IDs: M1-20, M1-23, M1-92, M3-93, M3-73. M1-53 and M1-116 were already closed by their delivered owner evidence; neither was reopened. M1-68 remains Done. M2-13 stays deferred outside the resumed IDs.

Work is isolated in `/Users/atik130/Desktop/Hackathon/NASA/atik-release-20261112`; the original working folder’s local settings/import edits, UID files, concept images and prior logs were preserved. No gameplay rule, UI feature, asset, rendering quality or frame threshold changed. The sole game-source change is the existing opt-in `--export-smoke` diagnostic in Main: it now requires loading/look-ahead to settle before passing and capturing. Normal play does not enter that branch.

## Frozen candidate and package checks

Selected source: **817a6eea2919440530c619614c7c8b87190bde1b**, official Godot 4.7.2 ed1daf0bf. [Final native CI run](https://github.com/SadManQT/nasa-space-apps-2026/actions/runs/43237871699): fresh Windows and macOS 15 machines, real exported executables outside the project, **11/0 checks each**, both jobs successful. Checks cover title, raw GLB/terrain/runtime resources, Chapter 1, first physical operation, settled loading, save and cleanup. These are headless platform startup results, not GPU/FPS or human acceptance.

| Candidate ZIP | Bytes | SHA-256 |
|---|---:|---|
| last-light-academy-0.1.0-windows.zip | 1093690361 | a0f6532244e1a3fa8a19b6fcec63f5e026a3fcf1cf467c5c0b5419f2f61335d3 |
| last-light-academy-0.1.0-macos.zip | 1115758023 | 3592787930db95e3c2450206a05a54845e6b6e6c3b1bbd6b9e1b19ef83228c4c |

The archive validator checks CRC, executable/game pack, launch instructions and supplied notices. Saira/Inter OFL notices, gohud MIT/third-party notices and its four bundled font notices now ship unchanged; CREDITS names the current UI dependencies. Complete source, package and native-file digests accompany the release. Six Python package/publisher contract tests pass, including missing runtime/notices, path escape, wrong source and digest rejection. Existing builds are never overwritten; publication preserves older releases/assets and creates a dated judging pre-release.

## Native graphical evidence

`native_export_final/` is a local macOS 27.0.1 / M4 /16GiB windowed run from the same source: **11/0**, normal exit 0, no reported errors or watchdog recovery. Both title and actual Commons/mission interaction images were inspected. The window was explicitly foreground/always-on-top; caches were retained. Both arm64 and x86_64 slices are present; only arm64 was executed locally. CI and local ZIP bytes are separately identified; no byte-identical claim is made without comparing the individual native digests.

Earlier background captures in `native_export/` and `background_capture_817a/` display a loading card despite passing logical checks. They are retained in `logs.zip` as visually inconclusive controls. Neither the shorter foreground run nor these different cache/focus conditions establish a rendering-hitch cause or fix. M1-92 remains open. `--evidence` now writes into the unique candidate output folder and keeps the window visible.

## Automated results — separate qualifications

- Initial clean-import full attempt: **setup FAIL, zero suites run**, engine exit 0 with dummy-renderer texture/RID diagnostics. Raw setup and runner output retained. No cold-import certification claimed.
- Complete retry using retained imports: **136/138 suites**, exit 1. Failures: media snapshot equality; player-text process timeout at the default 300 s. All 128 upgrade profiles pass **130308/0** over the 96 route scenes. Runtime performance **548/0**, watchdog **29/0**, held-raw **53/0**. Full results predate the export-only diagnostic hardening; no combined/fresh138/138 result is invented.
- Focused `game/tools/run_tests.sh campaign_session` after Main’s diagnostic change: **15/15**, **1/1**, exit 0. The earlier `production_session` filter matched no current suite; its no-result0/1 attempt is retained and is not a game defect.
- Focused `PLAYER_TEXT_TIMEOUT=1500 game/tools/run_tests.sh player_text`: **13048/0**, **1/1**, exit 0,519.809s. This is the documented process guard; assertions and performance limits are unchanged. The earlier full timeout stays failed.
- Focused media runner: **115/0**,1/1; diagnostic pass and eight subsequent forensic attempts retained. The eighth reproduced **115/1** with only `slot_metadata.saved_at_utc` changing by one UTC second. No gameplay state changed in that reproduction. See `media_handoff.md`; proposed owner patch is unapplied/unverified. More passing attempts are not a repair.
- Current 1080p rendered room sweeps: both processes exit 0 and all18 CSV distributions cross-check. Metal room p95 **18.122–20.964ms** misses16.667ms; Garden entry contains a **3112.104ms** frame. OpenGL p95 on this M4 fits33.333ms, with longer maxima. Source/driver/cache conditions differ from old reports, so no controlled optimization claim is made. Full details: `../../perf/atik_20261112/M1-23.md`.

## Remaining task blockers and saved work

- **M1-23:** current measured frame-budget misses and first-use stalls; no reachable current weakest Windows laptop. Original Arc timing evidence is historical; the newer M1-116 teardown pass is not FPS qualification. Budgets and quality are unchanged.
- **M1-92:** this original M4 lacks metal, metallib and xctrace (each exit 72); matching native campaign profiling and controlled measured repair remain unavailable. Historical symbolicated profiles and raw-loader work are preserved. See `../../perf/atik_20261112/M1-92.md` and host_tools.json.
- **M3-93:** the judging candidate can be published, but final release qualification still depends on Asif’s M3-92 full-campaign QA, learner/controller/freeze work, and a new full green gate after the media fixture owner reviews/delivers the saved correction. Publication does not waive these dependencies.
- **M3-73:** post-release Steam pack depends on M3-93/M3-74; two-hour soak, manual controller and the complete chapter-start/settings/save checklist are unperformed. Portable package layout and hashes are available from M1-20, not a completed Steam qualification.

Media QA/freeze handoff is to Sadman’s existing M1-24 scope; no canonical test or foreign runtime file was edited. Asif’s live campaign/provider, handbook and AI-log reservations remain intact. No new generated assets or paid tools were used. `logs.zip`, CI ZIPs, JSON manifests, foreground captures and the exact saved owner patch provide reviewable evidence. Publication status and immutable release metadata follow after the release job completes.
