# M1-90 — complete original Windows loading diagnostics

Ramim/codex · 2026-11-08 local host date · collector start `2026-11-07T19:30:24.577058+00:00`.

Both requested sequential runs completed through the real mandatory-setup runner and reproduced the original host's timing failures. This is complete diagnostic evidence, **not an M1-68 fix**. No timing assertion, collector, runner, loader, source, project setting, asset, import sidecar, cache policy or player save was edited for this task. The runner performed its existing editor/class-cache setup and the suite used its own process-specific temporary save path.

## Invocation and environment

Explicit working directory for every command: `C:/Users/User/.codex/worktrees/nasa-ramim-20261106`.

```powershell
python production/qa/perf/collect_loading.py --godot 'C:/Users/User/AppData/Local/Temp/opencode/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe' --bash 'C:/Git/bin/bash.exe' --output 'production/qa/evidence/M1-68_windows/2026-11-08_0130_ramim' --hardware-note 'Original failing Windows host. AMD Ryzen 7 7700 8-Core; NVIDIA GeForce RTX 4060 plus AMD Radeon integrated graphics; 33397133312 RAM bytes. Normal desktop apps retained: ChatGPT/Codex, VS Code, Chrome, Edge/WebView and OneDrive. No other Godot/Blender/Tripo/render process found at launch; exclusive engine/measurement and filesystem-mutation lease held. Existing Windows import metadata and import/OS caches retained; not an entirely idle desktop or cold-cache claim.'
```

`--runs` omitted: the existing collector default is **two sequential fresh suite processes**, each preceded by mandatory editor/class-cache setup. Collector exit **1**. No retries, extra engine runs, native rendering, full-run gate or new tests were performed. Each recorded runner command was `C:/Git/bin/bash.exe game/tools/run_tests.sh performance_runtime` with the collector's absolute `GODOT` and run-specific `TEST_LOG_DIR`.

Collector-measured hardware: AMD Ryzen 7 7700 8-Core Processor; AMD Radeon(TM) Graphics and NVIDIA GeForce RTX 4060; 33,397,133,312 RAM bytes; 16 logical CPUs; Windows 11 build 26200; Python 3.13.7; Godot `4.7.2.stable.official.ed1daf0bf`. Git Bash was selected explicitly, not WSL Bash. GPU inventory does not establish which device a rendered application would use; these are headless measurements.

Preflight found zero Godot/Blender/Tripo/render processes. The controller held other source mutations and engine/render jobs during measurement. ChatGPT/Codex, VS Code, Chrome, Edge/WebView and OneDrive remained running; background desktop/scheduling activity was not eliminated or measured. Postflight also found zero such engine/render processes. Existing import/OS caches and cache-matched Windows sidecars were retained: **no cold-cache claim**.

## Complete results

| Run | Mandatory setup | Suite result | Runner exit | Elapsed collector time |
|---|---|---|---|---|
| 1 | Completed; no setup failure/parse marker; suite reached | FAIL, 537 checks / 2 failures; 0/1 suites passed | 1 | 22.419314300000224 s |
| 2 | Completed; no setup failure/parse marker; suite reached | FAIL, 537 checks / 1 failure; 0/1 suites passed | 1 | 22.305949100000362 s |

The runner aborts before suites on any nonzero setup exit or its parse markers, so reaching each suite establishes successful mandatory setup. The existing collector does not separately serialize successful setup exit codes. Both complete setup logs are retained. No startup139, suite timeout, parse error, script error, warning or other error was present in these two runs.

**Every assertion failure in the raw suite logs:**

```text
run-1:
FAIL production title main-thread interval <50 ms (51.869)
FAIL production new campaign main-thread interval <50 ms (66.577)
PERFORMANCE RUNTIME RESULT: FAIL (537 checks, 2 failures)

run-2:
FAIL production new campaign main-thread interval <50 ms (69.960)
PERFORMANCE RUNTIME RESULT: FAIL (537 checks, 1 failures)
```

There were only these three assertion failures; none beyond the first five was discarded. Both complete suite logs retain all engine/ROOT/STRIDE output as collected. The current suite checks LoadTrace in memory but does not print per-stage trace durations; these logs establish failing intervals without attributing them to decode, generation, packing or scheduling. No measured root-cause claim is made. Atik owns the M1-68 investigation and any next measured change; no other owner's path was edited.

## Source stability

Source HEAD at launch: `9e642476877cf875a20f4413b84112d4a3fa191f`; tracked game tree: `3a4d0a2e5133fc8a96b0a9cf6411638238db8c67`.

The index was empty before and after collection. Preflight and postflight each had **1,129 unstaged tracked `.import` sidecars** and no other tracked change. Those are pre-existing, cache-matched Windows-generated metadata. Git's content-normalized diff names only three sidecars: `T_Kit_Paint_ORM.png.import`, `T_Kit_Steel_Normal.png.import`, `T_Kit_Steel_ORM.png.import` under `game/assets/environment/kit/textures/`; the remaining reported metadata reflects retained Windows file/line-ending state. None was restored, cleaned, staged or hand-edited. The manifest preserves the actual complete working-status output.

Both raw-byte fingerprints below matched exactly before and after the collector, including the sidecars. Fingerprint algorithm: sort tracked `game/` paths from `git ls-files -z game`; feed UTF-8 path, NUL, then the binary SHA-256 digest of that file's bytes to an aggregate SHA-256.

| Files | Count | Aggregate SHA-256, identical before/after |
|---|---:|---|
| All tracked game files, including sidecars | 2,959 | `388b4670d3bf30006079382b4cb411db9e06a04b208176912b2ee0f552d48617` |
| Tracked game files excluding `.import` | 1,830 | `9b169f6ab9250f7f5d807d0433cfcd04e62813b14f4070ea82c805a12cacd2a7` |

## Required raw artifacts

All seven required files are present, untruncated, and committed with their collected bytes. SHA-256 below applies to raw file bytes; staging used command-local `core.autocrlf=false` to preserve the logs exactly.

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| `manifest.json` | 84,772 | `09d902b8bf9e52f5a3317aed9dafce7184c29d45450fad07cf69f8f2d774336b` |
| `run-1/runner.txt` | 332 | `fc0b43e27fbdbe5534b169a3794bd2c88f833089bc3fc39d5f9a0739d8e5d9f1` |
| `run-1/setup.log` | 1,033 | `b728de0c23f24d9aa31bc7608b177d7ca13857d7c3aca862a08506d00675123b` |
| `run-1/test_performance_runtime.gd.log` | 11,544 | `20d853fb0b15313bf22e9e2b80b4b7507b2e0a6aa94da4486dfa1250c77cee4a` |
| `run-2/runner.txt` | 266 | `bcf27e5b3ab3d193beae49371ff1f7b995da0342f22026eaf898fc99ffe9c54d` |
| `run-2/setup.log` | 1,033 | `b728de0c23f24d9aa31bc7608b177d7ca13857d7c3aca862a08506d00675123b` |
| `run-2/test_performance_runtime.gd.log` | 11,484 | `9380c1f02b927a6514c58805c9efd8f5508a7496c61e83c1756c665cc85c96cb` |

Raw artifacts were checked for both expected result counts and every failure line, setup/parse/startup139/timeout markers, file presence, and byte-for-byte staged equality. No screenshots or separate artifact were fabricated. M1-68 remains open; this task supplies its requested original-host evidence only. General hardware, native rendered performance and the separate prior cold-import startup139 concern remain unverified.
