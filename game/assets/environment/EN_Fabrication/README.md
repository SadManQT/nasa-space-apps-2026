# EN_Fabrication — the local fabrication bench and the surveyed-route simulator (M3-7A)

Sadman/night-claude2 (Claude Opus 5.5), 6 November 2026. EX-CH07-S11 "Make the Road Hear Us" (March to 7 April 2047):
"Local fabrication bench and surveyed-route simulator". Two floor pieces built procedurally in Blender 5.2 by
`production/tools/build_chapter7_assets.py` (seed 20261106, no generation service, no credits) on the approved habitat
kit's materials and conventions (`../kit/README.md`); the room around them (walls, lights, navigation) is M3-7R's.
Both are described with the Chapter 7 props in `game/assets/props/chapter7_assets.json` and driven by
`game/assets/props/chapter7_assets.gd`. No text on any surface, no logos.

| Piece | Size | What it carries |
|---|---|---|
| `EN_Fabrication_Bench` | 1.80 x 0.75 m, worktop 0.903 m, tool board and shelf to 1.95 m | controller cradle (`Socket_Controller`, where `PR_RelayController`, the December spare with Kai's note, is checked against the Malapert housing); child **`SpareBattery`** on its cradle (`Socket_Battery`, `Lamp_Battery`); connector tray with **`Connector_A/_B/_C`** (round bayonet, matching) and **`Connector_Wrong`** (rectangular D-shell: the mismatch shows in the shape, not only the colour); echo test unit (`Screen_Echo`, `Lamp_Echo`); child **`Checklist`** (clipboard, `Screen_Checklist` is a paper sheet for the isolation checklist Ferreira signs); vise, drawers, ESD mat, tool board with shadowed tools, shelf with bins and a task light; `Stand_Operator` |
| `EN_Fabrication_RouteSimulator` | 2.00 x 0.82 m table, monitor to 1.61 m | a relief of the real corridor from Aurora to the Malapert summit, milled from the NASA LRO LOLA 80 m heightmap of M1-34 at 1:90,000 with a stated vertical exaggeration of 2; the computed surveyed road inlaid in orange; Aurora's mast and the summit dish as end markers (`Site_Aurora`, `Site_Summit`); children **`RepeaterPin_1..3`** parked at `PinPark_1..3`; computed pads `Pad_R1..3` (high ground beside the road) and their road-level alternatives `Pad_R1..3_Road`; `Screen_Route` on a monitor tilted toward the operator |

Each piece has `<id>_LOD0.glb` (game LOD with `-convcolonly` collision boxes) and `<id>_LOD1.glb` (Compatibility LOD,
512 px kit textures, the relief at half density with 1024 px maps, no collision). The kit's PBR sets are referenced
by uri from `../kit/textures` (stored once); the relief's own maps live in `textures/` (normal and ORM 2048 x 620,
LOD1 1024 x 310, with committed VRAM-compressed `.png.import` settings).

## The route simulator is real data, not a picture

`production/tools/route_simulator_data.py` reads `../terrain/lola/relay_road/heightmap_80m.r16` and the computed
`routes.relay_road` (make_terrain.py) and writes the `route_simulator` block of `chapter7_assets.json`:

- the transform from map metres to the table and back, so a puzzle can test any line the player draws;
- line of sight in **true scale** (never on the exaggerated table): the chord between two antenna tips over the
  bilinear LOLA heights every 40 m, with the lunar curvature's sagitta s(d - s)/2R (R = 1,737.4 km) subtracted;
- three pads that make Aurora -> R1 -> R2 -> R3 -> summit four clear links (three sites, four hops: STORY_FULL CH07
  production handoff), each on the highest LOLA pixel within 2.5 km of the road;
- the S11 lesson in real terrain: moved down to the road, R1 and R2 are blocked by the next ridge (48 and 69 m below
  the terrain), and straight road-level lines over a ridge fail by 600 to 1,600 m;
- the NASA credit line from handbook section 5, which must stay with the relief wherever it is shown.

**Finding for review:** on this grid Aurora's ridge-top mast and the Malapert summit see each other directly
(about 28 m clearance). STORY_FULL EX-CH07-S11 says the base is "hidden by terrain"; the story is unchanged here and
the finding is filed for the science reviewer (`direct_aurora_summit` in the catalogue). The computed road is 198 km
on the 80 m grid; the game's travel numbers stay 120 km each way (08 P-15, M1-34 decision).

## Rebuild and verify

1. `python3 production/tools/heavy.py /opt/homebrew/bin/blender --background --factory-startup -t 4 --python production/tools/build_chapter7_assets.py`
   (`-- --no-render` skips the Cycles previews; `-- --only EN_Fabrication_Bench` re-renders one asset's previews only).
2. `python3 production/tools/chapter7_contact.py` writes the review sheets `production/qa/evidence/M3-7A_contact.png`, `_states.png` and `_lods.png`.
3. Godot import, then `python3 production/tools/verify_gate.py` (specs in `production/manifest/chapter7_assets.csv`).
4. `game/tools/run_tests.sh chapter7_assets`; with a window, `production/qa/evidence/M3-7A_capture.sh` writes the
   Godot screenshots `production/qa/evidence/M3-7A_godot_*.png`.
