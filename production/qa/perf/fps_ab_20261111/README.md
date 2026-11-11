# Frame rate on Sadman's Mac (Apple M4, Forward+/Metal, 1280x720 window), 11 Nov 2026

`game/tools/perf_ab.gd`: production campaign, an 8-second walk on a fixed path after a 1-second warm-up, quiet machine (no other Godot jobs).

| Scene | Variant | avg ms | p50 ms | p95 ms |
|---|---|---|---|---|
| Garden EX-CH01-S04 | baseline | 16.67 | 16.64 | 18.76 |
| | TAA off / lamp shadows off / sun shadows off / LOD ×4 / all off | 16.66–16.73 | 16.61–16.67 | 18.13–18.86 |
| Chapter 5 full cast EX-CH05-S02 | baseline | 16.70 | 16.61 | 19.97 |
| | TAA off / lamp shadows off / sun shadows off / LOD ×4 / all off | 16.66–16.77 | 16.58–16.66 | 17.81–19.28 |

The display's 60 Hz sync still applied, so these are delivered frames, not GPU cost. Every variant holds 60 fps, and turning off shadows, TAA or detail changes nothing measurable. The game is not GPU- or CPU-bound on this Mac.

The lag seen during the campaign QA sweep came from that tool, which teleports through targets and loads a room every few seconds, while a second Godot instance rendered Movie Maker clips. Normal play does not do either.

Not covered here: first-use shader compilation with cold caches (M1-92) and weaker Windows laptops (M1-23).
