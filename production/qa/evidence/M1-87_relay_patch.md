# M1-87 — the walkable 10 m relay-road patch: LOC-11 stands on the LOLA terrain

7 Nov 2026 · Sadman/night-claude2 (Claude Opus 5.5, night shift) · terrain data, terrain tools, room placement and two
terrain tests; `terrain_stream.gd`, its profile, campaign and loading untouched; no generation, no credits (NASA PGDA
and JPL Horizons are free public services).

## What was built

| Item | Where | What |
|---|---|---|
| Hero region `relay_road_mid` | `production/terrain/regions.json` | kind hero, **site `relay_road_mid`** (the computed relay road's midpoint by length, `routes.json`), 8 × 8 km, 10 m, source `pgda90_10mpp` (LDEM_83S_10MPP_ADJ, PGDA product 90, which covers 83–90° S; the site is at −87.569°) |
| Heightmap | `game/assets/environment/terrain/lola/relay_road_mid/heightmap_10m.r16` + `.json` | 800 × 800 px, z −1,382.2 … −138.6 m, no NaN; cut with `make_terrain.py heightmaps --region relay_road_mid` (9 new 512 px tiles fetched by HTTP range request) |
| Detail layer, maps, tiles | same folder: `heightmap_10m_detail.r16`, `T_Terrain_RelayRoadMid_{Normal,AO}.png`, `tiles/*.glb` (52), `tiles.json` | `build_terrain_tiles.py -- --region relay_road_mid` (Blender 5.2 via `heavy.py`, `--threads 4`, AO 24 samples): 2,237 seeded sub-60 m craters, object-space normal map 2048², AO 1024² (orientation check 0.174 vs 0.000 flipped), 16 tiles of 2 km, LOD0 on the central four. Structure identical to `cold_trap` (same extent, LOD triangle counts 81,600 / 20,800 / 5,400 / 1,450). Imports use the cold-trap import settings (normal map uncompressed-as-normal, no tangents, no generated LODs) |
| Sun/Earth rows | `game/assets/environment/terrain/lola/sun_positions.json` | `make_terrain.py sun` re-run (offline from the Horizons cache): only `relay_road_mid`'s terrain horizon changed, now including the 10 m hero leg like every other hero site (azimuths 149–255° rise by up to 0.8°). Every scene row, Sun state and Earth flag is unchanged |
| Manifest, Data Card, provenance | `lola_terrain.json`, `game/resources/data/nasa/lro_lola_south_pole_terrain.json`, `production/terrain/provenance.json` | `make_terrain.py fixture`: the new region and the `relay_road_mid` site added; nothing else changed |
| LOC-11 placement | `game/resources/campaign/rooms/exterior_terrain.json` | `region_id relay_road_mid`, `origin_xz_m [0, 0]` (the site itself), `omit_staging_floor true`, `pending` removed; everything else derived by `test_exterior_terrain.gd -- --write` (LOC-06, LOC-09 and LOC-10 byte-for-byte unchanged) |
| Pipeline | `production/tools/make_terrain.py` | `all_sites()` (sites.json plus the road midpoint) used by `heightmaps`, `sun`, `fixture`, `check`; `--region <id>` for `heightmaps` and `preview` so one region can be cut without rewriting the others |

Why a new hero region and not a crop of `relay_road`: the corridor's frame, origin and curvature belong to Aurora
(the site is 80.6 km from Aurora in a straight line, 99 km along the road; the curvature drop r²/2R over those
80.6 km is 1.87 km, and with the site 2,603 m lower than Aurora the surface there lies about 4.5 km below Aurora's
horizontal), and `TerrainStream.lighting()` accepts only Horizons rows whose site equals the field's site. In its own frame the patch is lit by the EX-CH08-S03 and
S04 rows exactly as the M1-34 regions are by theirs (for Atik: no TerrainStream change needed).

## LOC-11 on the patch

Room-local, metres (from `exterior_terrain.json`). Site height on the 10 m grid −644.22 m vs the road profile's
−643.70 m (0.52 m; the check allows 5 m when a site was pinned on another grid). The computed road runs through the
room toward Malapert (room −Z) at about 6.6°; see `M1-87_relay_patch_map.png`.

| | |
|---|---|
| origin_m (site frame) | [0, −0.511, 0] (detail-field height at the site) |
| ground over the 60 × 20 m room | −1.05 … +2.92 m |
| walk lanes from the player anchor | max **6.27°** (limit 15°, the VIPER design incline) |
| deepest base corners | VH_Rover 0.45 m into the slope (limit 0.61 m for its 6.1 m base), PR_SurveyBeacon 0.10 m, everything else ≤ 0.07 m; nothing floats |
| rock exclusions | 27 (anchors, approaches, targets, props, doors, 2 m lanes) |
| detours | none |

## Light and Earth (JPL Horizons rows at the site, LOLA horizon with the new 10 m leg)

| Scene | UTC | Sun el | Terrain horizon toward the Sun | Sun state | Earth el | Earth shown |
|---|---|---|---|---|---|---|
| EX-CH08-S03 | 2047-04-08 06:00 | −0.13° | +4.87° | dark | −3.47° | no (below the horizon) |
| EX-CH08-S04 | 2047-04-08 10:00 | −0.06° | +5.14° | dark | −3.63° | no |

EX-CH08-S10 ("Hello, Aurora", 9 Apr 02:15–03:00) is also staged in LOC-11 by `RoomContract.room_for_scene`, but the
canon puts it in the pressurised relay rover cabin at the Malapert summit, 65.6 km from this sector in a straight line
(99 km along the computed road). Its row is at `malapert_summit` (02:00 UTC: Sun +2.31°, lit; Earth −2.32°, above the
summit's horizon), so on this patch `TerrainStream.lighting("EX-CH08-S10")` returns null and `RoomContract.earth`
hides Earth: on the terrain the call would play unlit in the road valley. LOC-11's placement therefore lists it in
`flat_scenes` (with that reason): S10 keeps the flat greybox room it had before this task. Its own summit location,
and `RoomContract.terrain_for_scene` so the campaign cannot set `terrain_ground` for a flat scene, are board M4-05
(Sadman; `room_contract.gd` is outside this task's folders).

The valley floor stays dark for all 97 hours of the 7–11 April window; the scan-line cast shadow on the new 10 m grid
agrees with the horizon mask for both rows (`make_terrain.py check`: OK, 7 regions). This matches the canon scene title
"Markers in the Dark" (STORY_FULL EX-CH08-S03); the story's "long shadows" fall on sunward slopes beyond the valley. The
capture therefore adds the same labelled evidence work light as LOC-10; the game's lamps on the rover and markers are
M3-8R's. Within 4 km toward the Sun's azimuth (55°) the terrain already rises 3.4° above the site, so the 8 km patch
shadows the room correctly on its own; the higher ridges that make the full 4.9° horizon lie 8–9 km out, beyond the
patch, so far sunward slopes in a wide view may catch light that the real horizon would still block.

## Checks

- `test_exterior_terrain.gd`: PASS headless (483 checks) and windowed with the capture (498 checks; LOC-06's rendered
  Earth 1.840° vs the true 1.899°). LOC-11 placement re-derived within 2 mm; lanes walkable; every anchor, approach, prop
  and door inside a rock exclusion; terrain-mode LOC-11 omits the staging floor and keeps every id; **a real
  PlayerController stands on TerrainStream collision at `relay_player` and walks to every approach and crew anchor**;
  no exterior is pending; LOC-11's region site equals its Horizons site. Every scene the room map stages in a terrain
  room has a Horizons row at that room's `ephemeris_site` or a `flat_scenes` entry (an entry must still be staged there
  and must lack a row at the site), and the configured `TerrainStream.lighting()` gives the dated Sun rig for every
  staged scene except the flat ones (LOC-09: S04, S05; LOC-10: S06–S08; LOC-11: S03, S04; S10 refused). Before the
  `flat_scenes` entry the check failed for exactly S10 (`EXTERIOR TERRAIN RESULT: FAIL (480 checks, 2 failures)`).
- `test_terrain_lola.gd`: the manifest must list `relay_road_mid`; its heightfield, collision, curvature, UV1, normal
  map, AO orientation, LOD meshes and crater layer are checked like every region; its site has a 360-azimuth horizon
  and a preview scene; EX-CH08-S03 and S04 are dark with Earth below the horizon.
- `make_terrain.py check`: OK (7 regions, 9 sun windows, 4 sites).

## Evidence

- `M1-82_LOC11_CH08S03_wide.png`, `M1-82_LOC11_CH08S03_ground.png` (windowed `M1-82_capture.sh`, LOC-11 added to
  `SHOTS`; dated EX-CH08-S03 Sun rig from `TerrainStream.lighting`, plus the labelled evidence work light).
- `M1-87_relay_patch_map.png`: the patch's collision field (hillshade 45/45), the computed relay road, the site and the
  LOC-11 room with its props, crew anchors and focus targets.
- `production/terrain/preview/relay_road_mid_*.png`: our 45/45 hillshade beside NASA's own 20 m hillshade crop (same
  craters and ridges, same orientation), the story-Sun hillshade and the PSR crop.

## Notes

- The capture's `_shot` now renders with `RenderingServer.force_draw` any frame the window did not draw (macOS skips a
  covered or locked-screen window and `frame_post_draw` then never fires). The first night run sat idle with its main
  thread asleep and was stopped; in the rerun the window drew every frame (2,679 drawn, 0 forced), so the fallback is
  a guard, and the printed `capture frames:` line says which path made each run's shots.
- LOC-11's props stand in the generic later-chapter slots of `campaign_room.gd` (`_asset_position`): the uplink
  feedthrough's slot (−2.4, 0.7) lies inside the 6 m rover's footprint, visible in `M1-82_LOC11_CH08S03_ground.png`.
  The flat room has the same overlap. Filed as board M4-06 (Sadman): a LOC-11 layout with prop transforms, then
  `test_exterior_terrain.gd -- --write` and the capture.
- The eight JPL Horizons responses M1-88 fetched (its four new times × Sun and Earth) were never committed, so `sun`
  could not re-run offline here; they were copied from the main checkout, verified to reproduce all 42 committed scene
  values exactly, and are now tracked with the nine new 10 m tiles and the four 20 m hillshade/PSR tiles.
- When M3-8R lays the Chapter 8 room out it must re-run `test_exterior_terrain.gd -- --write` (the test fails until it
  does, as for every terrain room).

## Fix round (7 Nov 2026, night shift): ported onto current main

The first attempt was parked on `night/M1-87` and no longer merged: main had since added a night-shift status line to
the handbook and changed the board view. Every task file was ported unchanged from the parked branch (LFS content
smudged), the handbook gained this task's status line above main's, and the board view was regenerated by `board.py`.
Main's newer commits touch only `night_shift.py`, its test and the board, so no game or terrain file differed.

Re-verified in this checkout, not trusted from the park:

- `make_terrain.py heightmaps --region relay_road_mid`, `sun`, `preview --region relay_road_mid` and `fixture`, run
  offline from the tracked cache, rewrote every output byte-identical (sha-256 compared over 834 files: every file
  this task changes plus every tracked terrain, manifest and NASA fixture file); `make_terrain.py check` OK (7 regions, 9 sun windows, 4 sites); `test_make_terrain.py`
  OK.
- `build_terrain_tiles.py`'s own numpy code (crater layer, seed from the region id, object-space normal map) re-derives
  `heightmap_10m_detail.r16` (2,237 craters) and `T_Terrain_RelayRoadMid_Normal.png` byte-identical, so the tiles and
  collision are built from the current heightmap.
- `M1-82_capture.sh` re-run windowed: `EXTERIOR TERRAIN RESULT: PASS (479 checks, 0 failures)`, 2,637 frames drawn by
  the window, 0 forced; LOC-06's Earth 1.840° vs 1.899°. All ten `M1-82_*.png` shots are from this run.
- The 21 cache files the outputs were built from (eight Horizons responses, nine 10 m tiles, four 20 m hillshade/PSR
  tiles) are force-added, since `production/terrain/cache/` is gitignored.

## Second fix round (7 Nov 2026, night shift): review findings

1. **EX-CH08-S10 on LOC-11.** The room map stages S10 (the summit rover cabin) in LOC-11, but its Horizons row is at
   `malapert_summit`, so on the relay-road patch it would have had no Sun rig and no Earth. LOC-11's placement now
   lists it in `flat_scenes` with the reason (S10 keeps the flat room it had before M1-87); `exterior_terrain.json`'s
   `about`, the rooms README (table row, contract paragraph, test list) and the handbook line say so instead of "every
   exterior is ready". New checks in `test_exterior_terrain.gd`: every scene the room map stages in a terrain room has
   a row at that room's `ephemeris_site` or a `flat_scenes` entry (an entry must still be staged there, lack a row at
   the site and say why), and the configured `TerrainStream.lighting()` gives a rig for every staged terrain scene and
   none for a flat one. Red first: `FAIL (480 checks, 2 failures)`, exactly S10; green after the entry. `-- --write`
   reproduces `exterior_terrain.json` byte for byte. Follow-up for the rooms owner: **M4-05** (Sadman): S10's own
   summit location and `RoomContract.terrain_for_scene(room_id, scene_id)`, so the campaign (Atik's terrain wiring)
   cannot set `terrain_ground` for a flat scene; the test fails until the S10 entry is removed with it.
2. **Capture script mode.** `M1-82_capture.sh` is executable again (100755, as on `night/M1-87` and in HEAD).
3. **Curvature figure.** The site is 80.6 km from Aurora in a straight line: the curvature drop is 1.87 km (r²/2R,
   `terrain_heightfield.gd` `curvature_drop`), not 2.8 km (that used the 99 km road length); with the site 2,603 m
   lower, its surface lies about 4.5 km below Aurora's horizontal.
4. **Prop overlap.** The uplink feedthrough inside the rover (generic `_asset_position` slot) is filed as **M4-06**
   (Sadman): a LOC-11 layout with prop transforms, then `-- --write` and the capture.

Re-verified: `M1-82_capture.sh` windowed `EXTERIOR TERRAIN RESULT: PASS (498 checks, 0 failures)`, 2,635 frames drawn
by the window, 0 forced, LOC-06's Earth 1.840° vs 1.899°; all ten `M1-82_*.png` re-shot (LOC-11 unchanged in content).

