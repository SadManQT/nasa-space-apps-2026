# Chapter 1 room assembly (M1-06)

`LOC-01.json` through `LOC-04.json` are the single layout authority. The five existing
campaign room scenes retain `CampaignRoom` and all public roots/target IDs. There
is no parallel world service or new campaign state. The 5 November realism lock
supersedes the older toon-room prompt: kit and equipment retain PBR materials;
`PlayerController` and `CampaignCrew` retain the installed cel-shaded cast.

| Location | Footprint and assembly | Runtime scene |
|---|---|---|
| LOC-01 | 22 × 12 m; central table, four seats/mugs, west lockers, east galley, north Earth screen, south garden view, storage drawer | `commons.tscn` |
| LOC-02 | Two adjacent 6 × 5 m work bays plus a 3 m shared service aisle (12 × 8 m overall); glass divider/protected trunk, power west/air east; three kit corridor segments behind the Commons portal | `service_rooms.tscn` |
| LOC-03 | 12 × 8 m; Tara reference bay, care bench/glovebox, seed archive; Alo cassette behind south pressure glazing (seedling in view at the glass front, chamber unit behind it, magenta-white growth lamps) and a separate shutter | `garden.tscn` |
| LOC-04 | 8 × 6 m; five seats at 1.04 m pitch (≈1.5 m aisles at both ends), perimeter water panels, four indexed bundle rails, seed latch, roll-call board, hatch flush on the west wall | `safe_room.tscn` |
| LOC-06 | Existing 120 × 120 m greybox retained; no LOLA/dated-horizon claim until M1-34/M1-36 | `exterior.tscn` |

All interiors use the kit's 2.6 m finished ceiling. `portals` replace three wall
slots, with a genuine 1.2 × 2.1 m opening. `HabitatPressureDoor` mirrors
`WorldRoute` into the same collision proxy and both imported DoorLeaf LODs;
no whole wall remains across an open door. Short pressure connectors end at a
closed destination door: campaign location changes still use the existing
explicit route/dated-viewpoint transitions. They are not a continuous global map.
The exterior boundary still requires the existing suit/pressure/exposure checks.

`obstacles` are the shared metre-space furniture collision and navigation
footprints. Walkable cells exclude these footprints plus the authored 0.30 m
agent clearance; each staged room owns a navigation map so local coordinates
do not merge with preloaded rooms. `walk_probe` exercises the real player body.
Repeated kit geometry uses MultiMesh batches and shared source meshes/materials;
it does not create one scene tree per floor/ceiling tile. Lighting is static,
with four practical clusters and two shadow-casting local lights per room. The
shadowed practicals use dual-paraboloid shadows with the seam at fixture height
(two passes instead of a cube's six): the Chapter 1 campaign with HUD and cast
went from 18.3 to 16.7 ms p50 on the target Mac. Connector lights and
`local_lights` (growth lamps) have no shadows. Fog is disabled. No paid
generation occurred.

Optional per-room keys: `fixtures[].finish` (`screen` = dark anti-glare display,
`satin` = smooth untextured board) replaces the kit paint on display surfaces;
other fixtures keep the kit paint (texture-driven roughness, as on the walls),
mapped triplanar at the kit walls' texel density. `local_lights` lists unshadowed
practicals inside an enclosure (`id`, `position`, `color`, `energy`, `range_m`). `signs[].yaw` turns a sign;
every sign and door destination plate is single-sided, so a sign authored the
wrong way disappears instead of reading mirrored. `review_views` are the
evidence camera positions.

The story joins retain their physical carriers: Commons emergency card, shelter
roll-call board, seed packet/drawer, paired garden bays, Mission Table and shelter
water wall. `set_scene_context()` gives the shared inventory lamp one pulse at
CH01 S02→S03; world refreshes do not restart it. The viewing shutter changes only
the view; pressure glazing and the cassette remain closed. Narrative timing,
dialogue, resource arithmetic, sounds and scene-exit receipts retain their owners.

Run `game/tools/run_tests.sh habitat_rooms` for player traversal, solid walls and
furniture, open/closed door rays, navigation paths, the doc 09 clearances (1 m
reachable approach at every door), signs readable from the walkable side, props
resting on the deck or a surface inside the footprint, collision under every
large floor-standing prop, source assembly and counts.
Run `production/qa/evidence/M1-06_capture.sh` (windowed; the night-shift Claude
session can open a window) for fresh room/player/chamber PNGs and windowed frame
timings in `M1-06_runtime.txt`. A blank (shader-compile) frame is retried and a
still-blank capture fails the run.
