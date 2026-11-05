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

# Chapter staging (M3-6R, first used for Chapter 6)

The base layout above stays the Chapter 1 room. A room JSON's `staging` array holds dated layers that
`RoomContract.staging()` resolves for a scene and `CampaignRoom.set_scene_context()` builds
(`game/scripts/world/room_staging.gd`); `CampaignCrew.place()` stages the room before anyone stands in it.
Doc 09's revisit rule applies: props accumulate between chapters; only mission-specific controls change.

- A layer, and any item in it, is active from `from` to `until` (inclusive scene ids, either optional).
  `by_scene` overrides fields for one scene or an inclusive `"FROM..UNTIL"` range (later keys win).
- `choice` / `unless` (`{"choice_id", "option_id"}`) gate a story-echo layer on `story_log.choices`
  (doc 24 §5.2), passed as `CampaignCrew.place(..., choices)` or `CampaignRoom.set_story_choices()`.
- Additions: `props` (GLBs through AssetGeometry), `fixtures`, `signs` (`line` fills `{line}` with a canon
  catalog line word for word; `pitch`, `wrap_m`, `color`, `outline`), `eclipse_props` (M3-6A props through
  `eclipse_props.gd`: `state`, `board`, `screens`, `parts_visible`, `monitor` with `phase`/`track`/`mode`/
  `logged`), `prints` (`solar_image`, `eclipse_frame`), `local_lights`, `obstacles` (collision and the
  rebuilt navigation map), `focus_targets` (stations).
- Changes: `hide` (base node ids, including their obstacles), `hide_signs` (base sign texts),
  `focus_labels`, `anchors` (merged by key; later layers win), `lighting` (`practical_scale`,
  `strip_scale`, `ambient_energy`), `carried` (an object on a cast member's bone, e.g. Kai's lamp).
- `stations` maps each scene action to the focus target it happens at; `RoomContract.station_focus()`
  answers it for the mission catalogue.

| Scenes | Room | What the staging shows |
|---|---|---|
| EX-CH06-S01..S05, S10, S11 | LOC-02 | Guide light leaving the protected supply at Kai's taped junction box (CH05 → CH06) and running low along the aisle to the Commons door; protected-bus test panel with F2 (A-42) beside that door; two decorative floods (shed in S10–S11); allocation board above the guide line (five cards from S01, the P-11 accepted plan and 7-unit forecast from S04); camera repeater desk with Kai's dated log; the lamp in its clip in the wall locker (S01, and from S12), on Kai's hip S02–S11; per-scene crew anchors (Ferreira in the Commons doorway; D11 companion at Kai's shoulder in S10); practicals at 18 % in S10 (the amber guide line is the only warm light), 55 % in S11 |
| EX-CH05-S01 on | LOC-01 | Five seats and five mugs; Ferreira's chair at the head until EX-CH07-S01 moves it |
| EX-CH05-S06..CH07-S12 | LOC-01 | D9: the ascent manifest or greenhouse service note at her place, under her mug |
| EX-CH05-S12 on | LOC-01 | D10 (OPT02): the seed-label holder marked "N." |
| EX-CH06-S06..S09 | LOC-01 | Eclipse desk with the filtered monitor (S06 protected, S07 ingress → ring, S08–S09 ring logged) and the message log (Noor's text in S09); Commons practicals at 35 % while the eclipse lasts |
| EX-CH06-S08 on | LOC-01 | Pin board: the held ring frame; from S10 Noor's note indexed as personal recollection, date unspecified |
| EX-CH06-S01 on | LOC-03 | Cotton in Tara's bay (Alo and Tara archived), the bay sign and focus renamed |
| EX-CH06-S12..CH07-S12 | LOC-03 | Monitoring calendar with the 13 Jan routine solar image (CH06 → CH07 join) |

Run `game/tools/run_tests.sh chapter6_rooms` (mapping, rosters, stations, navigation, collision, resting
props, readable signs, every §2.9 join, echoes, re-staging back to Chapter 1, cast placement), and
`production/qa/evidence/M3-6R_capture.sh` for the windowed screenshots and frame timings.
