# M1-53 acceptance: ten consecutive windowed probes, zero stalls

Collected 11 Nov 2026 on Sadman's Mac (macOS, Metal, Forward+, 1280x720 window, always on top,
Mac idle) by `bash production/qa/evidence/M1-53_capture.sh`, one fixed source (the harness refuses a
series if the runtime source hash changes).

| Check | Result |
|---|---|
| Full 20-second windowed `perf_probe` runs | 10 of 10 PASS, each about 511 s wall time (runs 01 to 10) |
| Stalls / preparation recoveries | 0 in every run (`preparation_recoveries` empty) |
| `full_cast_enter` (the stage that hung on 5 Nov) | 1471 to 1646 ms in all ten runs |
| Rendered evidence per run | log, JSON, CSV, five screenshots (title, new campaign, garden enter, garden rebuild, full cast enter); hashes in `M1-53_capture_progress.json` |
| Forced stuck-job test | `LOADING WATCHDOG RESULT: PASS (29 checks, 0 failures)` (`M1-53_forced_stall.log`) |
| Held raw-job recovery | `ASSET GEOMETRY RECOVERY RESULT: PASS` (`M1-53_forced_geometry.log`; 53 checks in the committed suite) |
| Integrated gate | already accepted (119-suite gate, see `M1-125_117_gate_2026-11-10/` and `M1-103.md`) |

Large files (per-run CSV, engine logs) are gitignored; their SHA-256 are in the progress JSON.

## Limits, stated plainly

- Collected on a Mac, not the original Windows machine of the 5 Nov hang. A script watchdog cannot
  preempt a blocked native main-thread call; that case is M1-92 (needs xctrace/Windows tooling).
- The 1920x1080 screenshots from Shanto's display setting are accepted by the relaxed validator
  (16:9, at least 1280x720); no other validator rule changed.
- The Godot editor rewrote `game/project.godot` while the series ran; the committed file was restored
  before `--verify-only`, which then validated 10/10.
