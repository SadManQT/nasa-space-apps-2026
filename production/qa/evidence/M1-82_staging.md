# M1-82 — surveyed exterior staging and the dated Earth (for Atik's M1-36)

7 Nov 2026 · Sadman/claude (Claude Opus 5.5) · room data, room code and terrain-art files only; `terrain_stream.gd`,
campaign, loading and routes untouched; no generation, no credits. Tests: `game/tools/test_exterior_terrain.gd`.
Capture: `M1-82_capture.sh`. Data: `game/resources/campaign/rooms/exterior_terrain.json` (format in the rooms README).

## Placements (owner-approved, authored; everything else derived from the detail heightfields)

| Room | Region · origin (site frame) | Why there | Ground (room-local) | Max lane slope | Earth |
|---|---|---|---|---|---|
| LOC-06 mast courtyard | `aurora_ridge` · [0, 0, 0] | Aurora's own site (highest LOLA pixel on the connecting ridge), where the Horizons rows and the terrain horizon were computed | −6.93 … 0.00 m over 120 × 120 m | 4.4° | rows where Earth clears the horizon |
| LOC-09 surveyed ridge | `cold_trap` · [−620, 145.80, −1000] | the computed cold_trap_road's last bend before the basin (map −4,850 / −10,970), S04's corner | −2.23 … 2.95 m | 7.2° | never (no horizon computed there) |
| LOC-10 vault approach | `cold_trap` · [0, 1.27, 0] | the cold-trap site: lowest pixel of the 1.86 km² PSR | −0.35 … 2.13 m | 6.8° | its S05/S06 rows: below the horizon |
| LOC-11 relay route | `relay_road` · [−24227.5, −76912.5] | relay_road_mid (the EX-CH08-S03 row) | — | — | **pending** (board M1-87) |

LOC-11 keeps its flat staging (`omit_staging_floor: false`, `pending`): the relay road is only the 80 m corridor grid
with a 200 m visual mesh, so anything placed on it would float or sink by metres. M1-87 (mine) cuts the 10 m patch.
LOC-12 (Malapert relay service bay) and LOC-08 (rover bay) are pressurised interiors with no open sky; not covered.

Every ready room publishes `origin_m`, `anchors`, `focus_targets`, `focus_approaches`, `detours`, `props`, `fixtures`,
`doors`, `bury_m`, `footprint_m`, `exclusions` (site frame), `max_walk_slope_deg`, `ground_y_range_m`. Nothing floats
(every prop, fixture and door rests at the lowest ground under its base); the deepest corners are LOC-06 EN_SolarMast
0.58 m and LOC-09 EN_SolarMast 0.64 m (9.1 m and 7.6 m bases: under 10 % of the diagonal), everything else ≤ 0.38 m.
One detour: LOC-10 `vault_probe` goes round the two greybox boundary doors at (−3, 0) and (−2, 0) via [−1, 0.02, −1].

## API for M1-36 (Atik wires it in campaign/loading; nothing here needs editing)

1. `var place := RoomContract.terrain(room_id)`; use it only if `place.get("omit_staging_floor", false)`.
2. Before the room enters the tree: `room.terrain_ground = true` (the explicit flag). The room then builds no staging
   floor (`FloorCollision`), apron rails, flat navigation or greybox `RoomLighting`, and stands anchors, focus targets,
   props, fixtures and doors on the published spots. Ids, door boundary ids, pressure markers, RoomContract targets and
   scene ids are unchanged; `room.on_terrain()` is true.
3. Keep the room at the campaign origin. `stream.position = -Vector3(place.origin_m)`;
   `stream.configure(place.region_id, origin_m + player_anchor, exclusions)` with each exclusion as
   `{"position": Vector3(e.position), "radius_m": e.radius_m}`; every frame `stream.move_focus(player.position + origin_m)`.
4. Player start: `place.anchors["<room>_player"]` (e.g. `exterior_player`), not the flat `RoomContract.anchors` value.
   `CampaignCrew.place()` already uses `room.terrain_anchors()` for everyone else.
5. Lighting: `stream.lighting(scene_id)` as today. Earth: `EarthSky.apply(rig_world_environment.environment,
   RoomContract.earth(room_id, scene_id), stream.config.sun_energy)` (`game/assets/environment/terrain/earth_sky.gd`);
   on a hidden date it returns false and leaves the black sky. `EarthSky.clear(environment)` restores it.
6. The provider supplies ground, collision and (if the cast needs it) navigation. Route bounds: the room-local floor is
   no longer y = 0 (`RouteNavigation.point_inside_room` tests y ≥ −0.05); `ground_y_range_m` gives the span.
7. Camera far plane: the vista and Earth need ≥ 64 km (the capture uses 70 km); Earth is in the sky pass, so it needs no
   far plane of its own.

Rows without a scene_lighting entry get no rig and no Earth: EX-CH04-S04, S07, S08, EX-CH08-S04, S10 (board M1-88).

## Earth (RoomContract.earth)

True size: 1.899° (2 atan(6,371 / 384,400 km); 1.80–2.07° over the orbit; the bundled rows carry no range). Direction
and Sun direction come from the row's az/el at its site (the same function as the dated Sun rig). The disc is drawn by
the sky pass (`sky_env_earth.gdshader`), lit by the dated Sun, so the terrain in front hides it and its phase follows the
Sun–Earth elongation. Black sky elsewhere; ocean and cloud bands only (no invented continents at ~30 px).

| Scene (LOC-06, Aurora) | UTC | Earth el | Above terrain | Shown | Lit fraction |
|---|---|---|---|---|---|
| EX-CH01-S01 | 2046-04-11 06:00 | 4.76° | yes | yes | 0.79 |
| EX-CH01-S12 | 2046-04-27 06:00 | −1.85° (horizon −2.74°) | yes | yes | 0.43 |
| EX-CH04-S02 | 2046-10-21 06:00 | 1.78° | yes | yes | 0.33 |
| EX-CH04-S09 | 2046-10-22 06:00 | 0.33° | yes | yes (captured) | 0.44 |
| EX-CH05-S01 | 2046-12-12 12:00 | 4.24° | yes | yes | 0.01 |
| EX-CH06-S07 | 2047-01-12 01:00 | −0.16° | yes | **no**: Earth over the Sun (eclipse; canon only through the filtered camera) | — |
| EX-CH01-S07, S09; EX-CH07-S05; EX-CH08-S01, S11 | | below | no | no | — |

LOC-09, LOC-10 and LOC-11 never show Earth; no scene without a row, no other site's row and no interior ever does.
In the capture the rendered disc measured within 0.2° of 1.90° (line printed in `M1-82_capture.txt`).

## Checks

`test_exterior_terrain.gd` (headless 363, windowed 375 checks): every vacuum room and every exterior scene's room has a
placement; footprints inside the heightfield; ephemeris site within 2 km and horizon site at the room; published numbers
re-derived from the heightfield (2 mm tolerance; `-- --write` regenerates); lanes ≤ 15°; nothing floats; every anchor,
approach, prop and door inside a rock exclusion; approaches within 3 m of their targets; flat rooms unchanged (floor,
rails, lights, navigation, y = 0 anchors); terrain rooms without them and with identical ids; LOC-11 stays flat even when
asked; the EX-CH04-S04 cast (Kai, Rafi) stand at their terrain anchors; a real PlayerController stands on Atik's TerrainStream
collision at each player anchor and walks to every approach and crew anchor (following the detour); the Earth table
above; EarthSky leaves hidden dates black and draws the shown ones at the dated direction and true radius.

Screenshots (dated Sun rig from `TerrainStream.lighting`): `M1-82_LOC06_CH04S09_{wide,ground,ground_toward_earth,
earth_close}.png`, `M1-82_LOC09_CH04S05_{wide,ground}.png`, `M1-82_LOC10_CH04S06_{wide,ground}.png` (LOC-10 adds a
labelled evidence work light: the PSR floor is black under its true Sun). Not claimed: M1-36 completion, full-game or
supported-machine performance, final visual approval of the terrain LOD seams (Atik's provider).
