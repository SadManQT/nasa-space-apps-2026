# M1-93: Intel Arc laptop, Chapter 1 at 1080p

8 November 2026 - Tanvir/codex. **Collection complete; this is not a chapter QA or stable-30-fps pass.**

## Machine and setup

- Intel Core Ultra 5 226V, 8 cores / 8 logical processors; 16 GB class RAM (16,659,689,472 bytes reported by Windows).
- Intel Arc 130V GPU (device name says 8GB), driver 32.0.101.9150. WMI AdapterRAM reports 4,293,918,720 bytes; it is retained raw and does not establish dedicated VRAM capacity.
- Windows 11 Home 64-bit, version 10.0.26300, build 26300; desktop 1920 x 1200 at 60 Hz. Power source/power mode were not recorded.
- Tanvir confirmed in this chat that this is the team's weakest available computer. No other Godot or Blender process was running before either capture.
- Godot 4.7.2 official ed1daf0bf; visible Windows rendering, OpenGL3 / gl_compatibility; actual probe window 1920 x 1080, vsync=1, max_fps=0, physics_ticks=60.
- Authored source: 660e01a44abf25fbdcd2d7ed8bb1453ccc67a800 (claim only after game source e0e1615). The probe SHA-256 and exact executable/arguments are in capture_retry.json. Setup refreshed the cache and generated import metadata locally; generated .import changes are excluded from the delivery.

## Attempts and retained artifacts

1. import.txt is the complete initial import log (exit 0). It contains file-access get_multiple_md5 errors; this setup is not described as engine-error-free.
2. compatibility.txt / capture.json retain the first attempt. It ended after 23.443 seconds with console exit 0 but no summaries, PERF RESULT marker, JSON or CSV. **Tanvir confirmed he closed that window.** This is an interrupted sample, not evidence of a crash or benchmark completion.
3. tests_performance_runtime.txt and test_logs/ retain the subsequent focused runner, including its setup and full failed-suite output.
4. compatibility_retry.json/.csv/.txt and capture_retry.json are the complete second attempt, a fresh process with retained caches. It exited 0 after 189.373 seconds, printed PERF RESULT: PASS (rendered samples recorded), and covered all four expected rooms. Neither sample duration nor any threshold, setting, asset or authored game script was edited.
5. Local .gitattributes preserves raw capture bytes across platform newline settings; hardware.json retains the OS hardware query; verification.json hashes the raw artifacts and cross-checks every sample count plus p95/max against the CSV.

## Rendered frame intervals

All values below are milliseconds. Each walk and panel sample lasts 20 seconds. No sample warmup frames are excluded; first-use stalls count.

| Room | Walk p95 | Walk max | Panels p95 | Panels max |
|---|---:|---:|---:|---:|
| Commons (LOC-01) | 18.946 | 161.334 | 17.823 | 35.876 |
| Safe Room (LOC-04) | 17.971 | 75.790 | 17.967 | 35.425 |
| Garden (LOC-03) | 18.082 | 34.956 | 17.859 | 35.741 |
| Services (LOC-02) | 17.955 | 42.281 | 17.807 | 35.420 |

All eight room p95 values fit the 33.333 ms interval corresponding to the task's 30 fps target. Maxima exceed that interval in every sample, so uninterrupted or stable 30 fps is **not** established. Walking Commons has a 161.334 ms maximum; Safe Room 75.790 ms. The raw over_33ms field counts intervals strictly above 33.0 ms, not above exactly 33.333 ms.

## Entry and transition hitches

Wall wait and a single process-frame interval are different quantities. These events include construction/loading and the first draw.

| Event | Wall wait (ms) | Maximum frame interval (ms) |
|---|---:|---:|
| title_build | 964.855 | 522.345 |
| new_campaign | 3349.349 | 1963.319 |
| room_enter_EX-CH01-S01 | 178.643 | 167.160 |
| room_enter_EX-CH01-S02 | 91.756 | 75.267 |
| room_enter_EX-CH01-S04 | 506.659 | 395.329 |
| room_enter_EX-CH01-S05 | 477.930 | 45.430 |

new_campaign is the first Commons entry; room_enter_EX-CH01-S01 revisits that already loaded room. The first campaign wall wait is 3349.349 ms with a 1963.319 ms maximum interval. Safe Room/Garden/Services entry values are above. This is a fresh process after retained caches, the interrupted attempt and the focused runner; it is not a cold-cache boot experiment. A 20-second title sample and background preparation precede entry.

## Verification and remaining work

- Complete capture metadata matches non-headless Compatibility / 1080p / 20 seconds. Four measured rooms equal the four expected rooms, with eight room distributions plus title. CSV counts and p95/max match all nine JSON summaries. Runtime warnings/errors are enumerated in verification.json rather than inferred from the console exit code.
- `game/tools/run_tests.sh performance_runtime`: **0/1 suites passed**, exit 1; 537 checks / 2 failures. Production title main-thread interval 265.969 ms and new campaign 108.546 ms violate the existing <50 ms assertions. Full output is retained; that focused suite also reports one leaked ObjectDB instance at exit, so clean teardown is not claimed. These are loading intervals, not FPS measurements. Existing Atik tasks M1-68/M1-92 remain the handoff for loading and native transition investigations. No passing full regression gate is claimed; the full suite was not rerun for this raw-evidence collection.
- PERF RESULT: PASS certifies collection/coverage only. These four representative states (S01/S02/S04/S05) do not cover every scene; automatic cutscene playback is disabled by the existing probe. CPU monitor repetition and zero/unsupported GPU timing values cannot establish independent CPU samples or zero GPU cost.
- Independent second-AI review recomputed p50/p95/p99/max, sample counts and >33.0 ms counts for all nine CSV distributions (10,629 rows); all 11 artifact hashes and probe identity matched. The reviewer's one request, recording the focused-suite ObjectDB leak, is included above.
- M1-93 delivers requested weak-laptop evidence, not the parent M1-23 performance fixes or a Chapter 1 gate. M1-65 still needs Tanvir's 20-30 minute unassisted run and 1-2 fresh-player sessions; no human playtest occurred here.
