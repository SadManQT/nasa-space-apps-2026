# M1-92 on Sadman's Mac (11 Nov 2026)

Apple M4 Mac, macOS, Godot 4.7.2, Forward+/Metal, 1280x720, windowed `perf_probe.gd --perf-seconds=1.0`, same source for every run.

| Run | Shader caches | Title build (ms / longest frame) | First campaign (ms / longest frame) |
|---|---|---|---|
| `warm_official` | project `shader_cache` and Metal cache present | 2338 / 1266 | 9972 / 482 |
| `cold_official` | both moved aside first | 25340 / **24178** | 41898 / **11491** |
| `cold_symbols` (debug-symbol 4.7.2 build, same commit ed1daf0bf) | cold | 126129 / 100175 | 38322 / 13964 |

## Cause
The long single frames happen only with cold caches, so they are first-use Metal shader compilation.
- **Title freeze (`cold_symbols/sample_title.txt`):** the main thread waits in `CAMetalLayer nextDrawable` inside `RenderingDevice::screen_prepare_for_drawing` while 11 `MTLCompilerConnectionQueue` threads talk to Apple's shader compiler. Godot's own worker threads are idle.
- **Campaign entry (`cold_symbols/sample_campaign.txt`):** the same stall, plus a synchronous `GLTFDocument::append_from_file` PNG decode on the main thread. That second part appears only because the long title stall tripped the loading watchdog (`PREPARATION WATCHDOG ... raw_decode:PR_BatteryJar`), which switches later loads to synchronous by design.

## Fix
Godot's shader baker (`shader_baker/enabled` in the export preset) precompiles these shaders at export time. On macOS, baking full Metal libraries needs Apple's Metal toolchain (`xcrun metal`), which ships with Xcode. This Mac has only the Command Line Tools, and the export reported "Metal shader baking limited to SPIR-V". Xcode (~40 GB to install) does not fit in the 19 GB free. Baking was therefore not enabled, and no timing improvement is claimed.

## Found on the way: exported builds were broken
The `runtime_assets` export plugin skipped every imported `.glb` scene, but eight room and rover scenes still load `.glb` files as scenes. Any exported build failed to load the Commons and Garden rooms (`export_smoke/unfixed_smoke.log`). The plugin now keeps the imported scene for every `.glb` that a `.tscn`/`.tres` references. The built-in `--export-smoke` check passes on the fixed macOS export (`export_smoke/fixed_smoke.log`: `EXPORT SMOKE RESULT: PASS (10 checks, 0 failures)`; screenshot `production/qa/evidence/M1-92_export_fixed_chapter1.png`).
