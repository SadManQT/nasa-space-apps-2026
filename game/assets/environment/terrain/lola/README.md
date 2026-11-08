# LOLA south-pole terrain — M1-34

Real Moon under every exterior: NASA Lunar Reconnaissance Orbiter LOLA elevation models,
cropped around the story sites by `production/tools/make_terrain.py`, turned into Godot tiles by
`production/tools/build_terrain_tiles.py` (Blender 5.2), lit by JPL Horizons. Provenance, DOIs and
checksums: [production/terrain/provenance.json](../../../../production/terrain/provenance.json).
Credit line (Data Card, credits, every video that shows the terrain): `lola_terrain.json`
`credit_line` / `credit_line_short`, or `TerrainHeightfield.credit_line()`.

| Region | Kind | Site | Grid | Window | Story |
|---|---|---|---|---|---|
| `aurora_ridge` | hero | Aurora, Shackleton–de Gerlache connecting ridge | 5 m (PGDA Site01) | 8 × 8 km | LOC-06, Chapters 1–8 at Aurora |
| `aurora_vista` | vista | Aurora | 40 m | 64 × 64 km, 8 km hole | horizon: Shackleton, de Gerlache, the pole |
| `cold_trap` | hero | Chapter 4 permanently shadowed basin | 10 m (LDEM_83S) | 8 × 8 km | LOC-09 / LOC-10 |
| `relay_road` | corridor | Aurora → Malapert summit | 80 m | 58 × 169 km | LOC-11 overview (playable segments are M1-36) |
| `malapert_summit` | hero | highest point of Mons Malapert | 5 m (PGDA Site23) | 8 × 8 km | LOC-12 |
| `malapert_vista` | vista | Malapert summit | 40 m | 64 × 64 km, 8 km hole | horizon toward Earth |

Each region folder holds `heightmap_<mpp>m.r16` + `.json` (16-bit LOLA heights, untouched),
for hero regions `heightmap_<mpp>m_detail.r16` (the authored sub-resolution crater layer, 15–60 m,
Trask/Gault equilibrium law, seeded; use it for collision so it matches the tiles),
`T_Terrain_<Region>_Normal.png` (object-space normal map in the region's Godot frame) and
`T_Terrain_<Region>_AO.png` (Cycles bake; darkens ambient only), `tiles/*.glb` and `tiles.json`.

**Frame.** The story site is the origin: X along the map columns (toward 90° E), Z along the rows,
Y up = height − site height − (X² + Z²) / (2 R). Every mesh follows the Moon's sphere, so a Sun or
Earth given by its Horizons elevation above the site's horizontal lights and hides the far terrain
as on the real Moon. Azimuth 0 = local north (away from the pole), 90 = east.

**Tiles and LODs.** Hero regions: 16 tiles of 2 km; LOD0 10 m spacing on the central 2 × 2 tiles
(0–1.5 km), LOD1 20 m (to 4 km), LOD2 40 m (to 9 km), LOD3 80 m beyond. Vistas and the corridor:
one mesh per LOD at 200 / 400 / 800 m (0–12 km, to 30 km, beyond). All have 25 m skirts, UV1 =
region 0..1 (normal and AO maps), UV2 = metres / 4 (the M1-35 regolith detail, one repeat per 4 m).

**Use.**

```gdscript
const LolaRegion = preload("res://assets/environment/terrain/lola/lola_region.gd")
const Heightfield = preload("res://assets/environment/terrain/lola/terrain_heightfield.gd")
add_child(LolaRegion.build("aurora_ridge", {"collision": true}))   # LODs, material, HeightMapShape3D
add_child(LolaRegion.build("aurora_vista"))
var hf := Heightfield.load_region("aurora_ridge", true)             # heights, slopes, Sun directions
var sun := Heightfield.scene_lighting("EX-CH01-S07")               # JPL Horizons row for a story scene
light.transform.basis = hf.sun_light_basis(sun.sun_az_deg, sun.sun_el_deg)
```

`sun_positions.json` holds hourly Sun and Earth azimuth/elevation for every story window, the
360-azimuth terrain horizon of each site and a `scene_lighting` row per exterior scene (lit, dark or
partial against the real horizon; a scene staged away from its ephemeris site carries `horizon_from`, the point whose terrain horizon it was checked against, e.g. the Chapter 4 ridge 146 m above the cold-trap floor). Every exterior scene in the room scene map has a row (M1-88 added five, with the hours Sadman chose on 7 Nov 2026). A scene played in segments has one more row per segment with its `segment` id and the terrain horizon where that segment stands (M3-106: EX-CH04-S04 at the beacon corners B1 and B2, sunlit from the Aurora rows, and B3, in shadow from the cold-trap rows); `scene_lighting(scene_id, segment)` returns it, and `""` the scene's own row. Never clamp the Sun above the horizon: at Aurora in April 2046 it
sits at −1.5°, and the ridge is lit only because the terrain falls away toward it.

Rules: one hard Sun, black sky, no ambient except Earthshine (Art Bible §2); `terrain_lola.gdshader`
uses McEwen's lunar-Lambert photometry and never multiplies the Sun by AO. Streaming, the playable
road segments and scene integration are M1-36. Tests: `game/tools/test_terrain_lola.gd`;
captures: `game/tools/capture_terrain_m134.gd` via `production/qa/evidence/M1-34_capture.sh`.
