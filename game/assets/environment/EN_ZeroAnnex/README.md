# Expedition Zero service annex pieces (LOC-07) — M3-3A

Sadman/night-fable (Claude Fable 5.1), 5 November 2026; fix round 2 by Sadman/night-claude2 (Claude Opus 5.5),
6 November 2026. Ten modular pieces for the 2034 annex that Chapter 3
opens (`EX-CH03-S06` the displaced floor cover and the N.R. hatch, `S07` the suited entry to the frozen trays,
`S08` the chart archive and the route sheet), built procedurally in Blender by
`production/tools/build_ch03_assets.py` (seed 20261103, no generation credits) in the habitat kit's conventions:
metres, +Y up, Godot -Z forward, pivots at the base centre, 1 m grid, wall faces on z = 0 facing -Z, two LODs
switching at 12 m, Godot collision nodes in the game LOD. The annex is 2034 generation hardware, older than
Aurora's quilted kit: riveted olive-grey aluminium panels, open steel grating, dead fixtures, and frost on the
cold side (ART_BIBLE §2: no fog, no haze; the frost is a surface, not an atmosphere).

`annex.json` is the catalogue in `kit.json`'s schema. `habitat_kit.gd` reads it as an extension, so
`Kit.place(room, "EN_ZeroAnnex_TrayBench", ...)`, `Kit.bounds()`, `Kit.screen_surfaces()` and the new
`Kit.set_part_open(node, part, fraction)` work on annex pieces exactly as on kit pieces.

## Pieces (metres; pivot at the base centre)

| Piece | Footprint | Moving parts and sockets |
|---|---|---|
| `EN_ZeroAnnex_FloorHatch` | 2 x 2 corridor deck module, mount y = -0.056 | `HatchLeaf` (hinge on the -X edge, `rotate z 100`), `Cover` (the 1.3 x 1.3 x 0.30 m service cover hood standing on the deck over the whole hatch, wheel and handles included; the quake pose slides it 1.18 m along the deck with a 14 deg yaw), `PortShutter` on the leaf over the camera port (`slide x 0.17`), `FeedValve` on the utility coupling (`rotate y 90`), `Socket_Camera` on the leaf; slots `Label_Nameplate` (N.R.), `Label` (feed status and the cover's plan reference) |
| `EN_ZeroAnnex_Ladder` | 0.55 x 0.2, 3.0 tall | stands against a wall at z = 0; rungs every 0.3 m; the corridor deck is 3.0 m above the annex floor |
| `EN_ZeroAnnex_Wall` | 1.0 x 0.15, 2.6 tall | riveted panel, rib at 1.3 m, conduit along the top |
| `EN_ZeroAnnex_Wall_Corner` | 0.65 x 0.65 | inside corner, two 0.5 m legs; the room lies towards -X and -Z |
| `EN_ZeroAnnex_Floor` | 1 x 1, mount y = -0.06 | steel grating deck |
| `EN_ZeroAnnex_Ceiling` | 1 x 1, mount y = 2.584 | hanging frosted panel: five stiffener ribs are its lowest face, the frosted face sits 16 mm above them and meets the 2.6 m wall tops |
| `EN_ZeroAnnex_CeilingLamp` | 1 x 1, mount y = 2.554 | the same panel with a dead 0.9 m linear 2034 luminaire under the ribs (`DeadLamp` diffuser slot: a material swap lights it in a fault or occupied state); place one every two or three metres, its panel lines up with the plain ones |
| `EN_ZeroAnnex_TrayBench` | 1.2 x 0.6, top at 0.9 | `Socket_Tray_A` and `_B` for `PL_ZeroSeedlingTray` (the two frozen 2034 trays: young unflowered seedlings only, canon), dead grow lamp, `Label` bench slot |
| `EN_ZeroAnnex_ChartArchive` | 1.0 x 0.45, 1.22 tall | `Document_Chart` (the growth chart whose last line stops at "Day 12. Leaves curling. Heat", doc 24 clue 12, drawn by the game), `Document_Route` under `SealedCover` (`rotate x -110`), `MapPouch` child (clue 13), `Document_Photo` (the legacy loop-valve photograph), `Label_ServiceTag` (the 2034 tag, clue 11) |
| `EN_ZeroAnnex_SupportStation` | 1.0 x 0.6, 1.1 tall | warm-side cart: `Screen` and `Screen_Gauge` live surfaces (the boundary reading), two local-radio handsets, `Socket_ToolTag` hook (the gear-wheel tag `PR_ToolTag_Gear`, M3-99, clue 12), `Socket_HandLight` bracket, `Label` status plate |

No surface carries text: every label, chart, nameplate and screen is a separate material slot named `Label*`,
`Document*` or `Screen*` for a live UI texture, as the handbook requires (the N.R. mark, the chart's handwritten
line, the 2034 date and the feed status all come from the campaign content).

## Layout the pieces expect (09_WORLD_AND_LEVEL_DESIGN.md LOC-07, 24_NARRATIVE_REVISION.md §2.3, §4)

The floor hatch module sits in the LOC-02 service corridor deck with the support station beside it (Kai and
Amara's warm side, local radio). The annex is a 10 x 6 m lower room 3.0 m below the corridor: the ladder stands
under the hatch, the frozen-tray bench and the chart archive along the far wall, `PR_AnnexDrum` as debris, and
eight dead fixture tiles in the ceiling, one every 3 m. The
sample assembly in `game/tools/test_ch03_assets.gd` (`_annex_sample()`) places all of it and proves with physics
rays that the closed cover and the closed leaf block the opening, that the open leaf clears it down to the annex
grating, and that the annex walls, ceiling and bench collide where the catalogue says. M3-3R (Chapter 3 rooms)
owns the real scene, navigation, lighting and the live-UI bindings.

## The frost

The cold side is a hoar-frost film on the 2034 paint: an even crystalline layer of millimetre crystals and small
feathered clumps, only gently thicker or thinner over tens of centimetres, with the paint faintly showing where it
is thin and a few crystal facets catching the headlamp. It is a surface, never an atmosphere (ART_BIBLE §2: no fog,
no haze). Fix round 2 replaced the first film, whose ±45 % blotches at 4–25 cm read as camouflage in the room.

## Textures are stored once and shared

Four PBR sets (frost 0.5 m, 2034 paint in five tints 0.5 m, grating 0.5 m, steel 0.25 m) live in `textures/`
(1024 px) and `textures/lod1/` (512 px); every GLB references them by uri (`glb_external_textures.py`), so Godot
imports each one time. The committed `*.png.import` files set VRAM compression and flag the normal maps; the
`*.glb.import` files use `gltf/embedded_image_handling=1` like the kit.

## Rebuild and verify

1. `python3 production/tools/heavy.py /opt/homebrew/bin/blender --background --factory-startup -t 4 --python production/tools/build_ch03_assets.py -- annex` (add `--no-render` to skip the Cycles previews).
2. `python3 production/tools/ch03_contact.py` writes the review sheets to `production/review/`.
3. `production/tools/godot_gated --headless --path game --import`, then `python3 production/tools/verify_gate.py` (specs in `production/manifest/ch03_assets.csv`).
4. `game/tools/run_tests.sh ch03_assets`; with a window, `production/qa/evidence/M3-3A_capture.sh` writes the Godot screenshots.
5. `python3 production/tools/build_registry.py --manifest ch03_assets` refreshes the registry rows.
