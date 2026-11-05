# Chapter 6 eclipse power props — M3-6A

Sadman/night-claude2 (Claude Opus 5.5, night shift), 6 November 2026. The props of PRODUCTION_HANDBOOK.md §8.4, CH06
(*The Red Ring*, EX-CH06-S01..S12; puzzles P-11 *Protect the Small Light* and P-12 *Observe, Isolate, Restore*).
Built procedurally in Blender 5.2 by `production/tools/build_eclipse_props.py` (no generation service, no credits) on the
M1-05 habitat kit's photoreal PBR sets, which every GLB references from `../../environment/kit/textures/` instead of
storing its own copy. No text, numbers or logos on any surface: every word is a `Label3D` on a blank plate or a live screen.

| Prop | Anchor, mount | What it is for |
|---|---|---|
| `PR_EclipseBoard` | wall, 1.10 m | S03/S04 allocation board: five segment card slots (precharge → recovery, left to right), four service rows (essentials, return pump, camera, decorative floods), a tag socket in each of the 20 cells, a warning lamp and state plate per segment, a live forecast strip |
| `PR_SegmentCard` | loose (board socket) | one rigid card, five variants with tinted bands and names |
| `PR_ServiceTag` | loose (board socket) | magnetic tag, four variants (essentials package, pump, camera, floods) |
| `PR_GuideLightBranch` | wall, 0.36 m | where the guide light leaves the protected bus: junction box, status lamp, branch label plate, conduit into the wall wrapped in **Kai's orange marker tape** (the CH05 → CH06 join), first 0.82 m of amber channel |
| `PR_GuideLightRun` | wall, 0.406 m | 1 m channel that continues the line on the kit grid (`EndCap` part for the last one) |
| `PR_DecorativeFlood` | wall, 2.0 m | S04's comfortable plan: finned wall flood on a tilt yoke aimed 25° down; `Socket_Light` carries its spot light |
| `PR_ProtectedBusPanel` (A-42) | floor, back on z = 0 | S05/S10 protected-bus test panel with camera feeder F2: mimic diagram, orange isolation boundary, four protected breakers under a sealed guard with a do-not-switch tag, test selector, F2 isolator, F2 breaker, fault lamp, test button, current readout, flood breaker, status screen |
| `PR_FilteredCamera` | floor (exterior) | S06/S07 remote camera: ballast foot, mast, F2 junction box and cable, pan, tilt, MLI-wrapped body, sun hood with a hinged solar filter (`in` = the protective configuration) |
| `PR_EclipseMonitor` | floor (desk) | S06–S11 monitor; `Screen_Main` shows `monitor/eclipse_monitor_screen.gd` |

Each prop has `<id>_LOD0.glb` (game LOD, Godot `-convcolonly` collision) and `<id>_LOD1.glb` (Compatibility LOD:
fewer segments, no screws, fins or clips, the kit's 512 px textures, no collision; every part, lamp and screen node
is kept so states show at any distance).

## Files

- `eclipse_props.json` — generated catalogue: LODs, triangles, size, anchor, mount height, and every part (pivot, axis,
  named positions), lamp, screen, label plate and socket. Rebuilt by the Blender script.
- `eclipse_props_content.json` — authored: label text, lamp words, card and tag variants, lights, and the visual state
  presets (`normal`, `eclipse_schedule`, `test_disconnected`, `f2_tripped` → `f2_isolated` → `f2_fault_cleared` →
  `f2_reset` → `f2_restored`; board `accepted_plan`; guide `taped` / `labelled_on` / `labelled_off`; camera
  `filter_in` / `filter_out` / `f2_lost`; monitor `live` / `held` / `no_signal`). Edit words here; no rebuild needed.
- `eclipse_props.gd` — the helper (see below).
- `monitor/eclipse_monitor_screen.gd`, `eclipse_camera_view.gdshader`, `eclipse_monitor_screen.json` — the camera
  picture and the labelled Earth-limb inset.

## Using them

```gdscript
const Props = preload("res://assets/props/eclipse_power/eclipse_props.gd")
var board := Props.place(room, "PR_EclipseBoard", Vector3(2.5, 0, 4))      # a kit wall's grid position; lifted to 1.10 m
Props.populate_board(board, "accepted_plan")                                  # five cards + the 08 P-11 accepted tags
var panel := Props.place(room, "PR_ProtectedBusPanel", Vector3(4.95, 0, 3.92))  # 8 cm off a wall with a handrail
Props.attach_text_screen(panel, "Main", "")                                   # status rows; presets fill the words
Props.apply_state(panel, "f2_tripped")                                        # lamps, levers, plates and screen agree
Props.set_part(panel, "F2Isolator", "isolated")                               # or any single part / lamp / label
var monitor := Props.place(desk, "PR_EclipseMonitor", Vector3(0, 0.76, 0.2))
var screen = Props.attach_monitor_screen(monitor)
screen.set_phase(0.5); screen.set_logged("ring", true); screen.set_mode("held")
```

States are only poses. The P-11 and P-12 puzzles own every rule, cost and transaction and call these functions; a
lamp's state always shows as a word on its bound plate (no colour-only information). The protected guard stays
sealed in every preset: the puzzle shows the survival-services warning instead of switching the protected bus.

**Monitor science:** the camera tracks the Sun; Earth's night-side disc is 3.5 times wider than the Sun as seen from
the Moon (12,742 km at 384,400 km ≈ 1.9°, against the Sun's ≈ 0.54° in January), crosses it on an offset path, and at
totality only the refracted, reddened rim is lit (brightest towards the hidden Sun) while auto exposure raises the
gain. Black sky, no stars, no glow around the Sun, no geography on Earth. The date line is read from
`res://resources/data/nasa/nasa_eclipse_2047_01_12.json`; Aurora's local timing and view are labelled as scenario.

## Rebuild and verify

1. `python3 production/tools/heavy.py /opt/homebrew/bin/blender --background --factory-startup -t 4 --python production/tools/build_eclipse_props.py` (`-- --no-render` skips the Cycles previews; `-- --only PR_X` re-renders one prop's previews without touching the published files).
2. `python3 production/tools/eclipse_props_contact.py` writes `production/qa/evidence/M3-6A_contact.png` and `_lods.png`.
3. Godot `--headless --path game --import`, then `python3 production/tools/verify_gate.py` (reads `production/manifest/eclipse_props.csv`).
4. `game/tools/run_tests.sh eclipse_props`; with a window, `production/qa/evidence/M3-6A_capture.sh` writes the Godot screenshots.
