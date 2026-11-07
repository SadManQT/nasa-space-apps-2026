# Chapter 1 room assembly (M1-06)

`LOC-01.json` through `LOC-04.json` are the single layout authority. The five existing
campaign room scenes retain `CampaignRoom` and all public roots/target IDs. There
is no parallel world service or new campaign state. The 5 November realism lock
supersedes the older toon-room prompt: kit and equipment retain PBR materials;
`PlayerController` and `CampaignCrew` retain the installed cel-shaded cast.

| Location | Footprint and assembly | Runtime scene |
|---|---|---|
| LOC-01 | 22 × 12 m; central table, four seats/mugs, west lockers, east galley, north Earth screen with the AURORA / COMMONS name plate to its right (cable tray along the ceiling line, clear of the screen), south garden view, storage drawer | `commons.tscn` |
| LOC-02 | Two adjacent 6 × 5 m work bays plus a 3 m shared service aisle (12 × 8 m overall); glass divider/protected trunk, power west/air east; three kit corridor segments behind the Commons portal | `service_rooms.tscn` |
| LOC-03 | 12 × 8 m; Tara reference bay, care bench/glovebox, seed archive; Alo cassette behind south pressure glazing (seedling in view at the glass front, chamber unit behind it, magenta-white growth lamps) and a separate shutter | `garden.tscn` |
| LOC-04 | 8 × 6 m; five seats at 1.04 m pitch (≈1.5 m aisles at both ends), perimeter water panels, four indexed bundle rails, seed latch, roll-call board, hatch flush on the west wall | `safe_room.tscn` |
| LOC-05 | 8 × 4 m approved M3-2A double interlock; suit-up vestibule, isolated cycle chamber, glove-port access to Alo and sealed sample pass-through to Tara | `airlock.tscn` (M3-2R) |
| LOC-06 | Existing 120 × 120 m greybox retained as the flat staging; on the LOLA terrain it stands at Aurora's site (exterior terrain below, M1-82) | `exterior.tscn` |

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
wrong way disappears instead of reading mirrored. `signs[].font_size` (default 40; letters are
`font_size` × `size` metres) and `signs[].reads_from` (an anchor id): such a sign must face that anchor, show
every corner of its text to a 1.6 m eye there past furniture, fixtures, kit runs and every staging layer's
fixtures and obstacles, and cover at least 14 px of em height in a 1080-line FollowCamera frame (M1-79: the
commons name once hung behind the Earth screen in 0.1 m letters). No kit run may cross a display fixture.
`review_views` are the evidence camera positions.

The story joins retain their physical carriers: Commons emergency card, shelter
roll-call board, seed packet/drawer, paired garden bays, Mission Table and shelter
water wall. The inventory lamp pulses once per scene at the CH01 S02→S03 join (campaign hooks below);
re-staging the same scene does not restart it. The viewing shutter changes only
the view; pressure glazing and the cassette remain closed. Narrative timing,
dialogue, resource arithmetic, sounds and scene-exit receipts retain their owners.

## Campaign hooks for Chapter 1 (M1-84, for Atik's M1-49 Care Round)

Presentation only; the campaign owns when each is called and records every receipt and moment through the Director.

- **Inventory lamp.** A fixture `cue` runs automatically `delay_s` after `set_scene_context(scene)`, or only when the
  campaign asks, for scenes listed in `on_request`. `CampaignRoom.trigger_cue("inventory_lamp") -> Dictionary` gives one
  pulse now (`{"accepted", "fixture_id", "scene_id", "sfx_id"}`); a second request in the same staged scene, or a scene
  the cue does not list, is refused (`duplicate` / `reason`). `signal cue_lit(fixture_id, sfx_id)` fires as the lamp
  lights; connect it to `CampaignAudioDirector.play_effect(sfx_id)` for `SFX_INVENTORY_LAMP_TICK`. EX-CH01-S02 (LOC-04,
  the lamp at the roll-call board) is `on_request`: call it at the roll-call beat. EX-CH01-S03 (LOC-01, the lamp on
  the dry-storage drawer) opens on its automatic pulse 1.5 s after staging. One pulse per scene, never restarted.
- **Care Round.** `RoomContract.care_round(scene_id)` (EX-CH01-S04 and S05; `{}` otherwise) maps `ALO-01` and `TARA-01`
  to `focus_target` (`garden_alo_glove_port`, `garden_tara_bay`), `plant_anchor` (`plant_positions`), `stand` (the
  focus approach, reachable on the garden's navigation), `photo_view` (`from`/`to`, the same frame every visit for the
  ghost overlay), `reach` (`glove_ports` / `direct`) and, for Alo, `view_boundary: garden_viewing_shutter` (the photo
  is taken through the pressure glazing). The care always happens in LOC-03: S05's corridor scene stays in LOC-02, so
  the campaign stages a garden room with `set_scene_context("EX-CH01-S05")` for its care visits (layer
  `ch01_care_round`).
- **Named mugs.** Layer `ch01_named_mugs` (LOC-01, from EX-CH01-S12, gated by `"moment": "CH01-MUGS-NAMED"`) swaps the
  four Chapter 1 mugs for M3-99 `PR_Mug_Named` at the same spots (`commons_mug_kai`, `_amara`, `_mei`, `_rafi`; names
  facing the commons). Pass `story_log.moments` with `CampaignRoom.set_story_choices(choices, moments)` or
  `CampaignCrew.place(scene, room, at, choices, moments)`: recording the moment re-stages the room in place. Any layer
  may carry `"moment"` (shown only once it is recorded) or `"unless_moment"` (shown only while it is not); staging
  props may carry `"variant"` (an M3-99 narrative prop variant). In EX-CH02-S11..S12 the cup by the pending-reply
  indicator is Amara's named mug moved there (`by_scene` in this layer), or the nameless mug (`ch02_reply_cup`,
  `"unless_moment"`), never both.

Run `game/tools/run_tests.sh ch01_room_hooks`; `production/qa/evidence/M1-84_capture.sh` (windowed) re-takes the blink,
mug and Care Round frames.

Run `game/tools/run_tests.sh habitat_rooms` for player traversal, solid walls and
furniture, open/closed door rays, navigation paths, the doc 09 clearances (1 m
reachable approach at every door), signs readable from the walkable side (and from their
`reads_from` anchor), kit runs clear of displays, props
resting on the deck or a surface inside the footprint, collision under every
large floor-standing prop, source assembly and counts.
Run `production/qa/evidence/M1-06_capture.sh` (windowed; the night-shift Claude
session can open a window) for fresh room/player/chamber PNGs and windowed frame
timings in `M1-06_runtime.txt`. A blank (shader-compile) frame is retried and a
still-blank capture fails the run.
`production/qa/evidence/M1-79_capture.sh` (windowed) re-takes the commons name plate from the
commons_player anchor in Chapters 1, 6 and 7 and reports how much of its text box rendered as letters.

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
  `logged`), `chapter7_props` (M3-7A props through `chapter7_assets.gd`, added by M3-7R: `markers` role -> slot with
  each name beside its marker, `case` lid/latch, `water_units`, `selector`, `lamps`, `isolated`, `card_out`, `pins`,
  `attach` (a GLB seated in one of its sockets) and `screens`, plain words on a `Screen_*` slot; `line` quotes a catalog
  line), `prints` (`solar_image`, `eclipse_frame`; M3-2R adds `plant_photo`, image `texture` and labelled
  `flower_diagram`, with `pitch`, `roll`, photographic `border` and optional `caption`), `models` (the nonliving
  mustard-flower practice model: four petals, four long and two short stamens), `local_lights`, `obstacles` (collision and the rebuilt
  navigation map), `focus_targets` (stations).
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
| EX-CH07-S01 | LOC-01 | Rafi's shared warning on the Mission Table with its labelled source (the 23 July 2012 storm measured by STEREO-A, a counterfactual replay, game doses) and the four role-colour observation cards (S01 → S02); Rao confirms the source live on the main display, word for word; Ferreira's chair still at the head |
| EX-CH07-S02 on | LOC-01 | Ferreira's chair among the cadets' on the east side; her mug and the D9 record move with her (canon S01); the head stays empty |
| EX-CH07-S01 on | LOC-01 | Local network diagnostic (M3-7A) by the main display: all paths pass (S01), exposed branch isolated (S05–S08), Earth silent with the tests waiting (S09: S08 → S09), then local pass, dish and feedthrough fail, data card out and the exposed-branch fault label (S10 on, doc 09); main display: outside-clearance readings (S09), stable care board (S10) |
| EX-CH07-S10 on | LOC-01 | Care-planning desk where the eclipse desk stood: founder case checked without opening, vault register, the saved relay-bypass diagram (S09 → S10), the "Queued for Earth" outbox (clue 22 setup; D10 OPT01 adds Mei's photo strip for N.), and in S10 the December spare's sealed case (S10 → S11); the home-night ledger in S12 |
| EX-CH07-S02 on | LOC-04 | The storm shelter: roll-call board names five with April's four-name first-night card beside it; shelter diagram by the hatch (markers parked S02, on the five seats from S03: S02 → S03); hatch latch and seal indications (both agree S06–S08: S05 → S06); valve diagram on the water wall from S04 (four units held, return after the step-6 sample: S03 → S04); founder case on the seed latch S04–S09 (latched 15 + 15 from S05: S04 → S05); life-support and response board; forecast table under the local telemetry ("four steps left" in S07: S07 → S08); archive player with the last log quoted word for word in S07 (clue 21), the packet, signed page and founder ledger beside it and Alo's pressed petal by the case; storm steps at 50 % practicals (42 % in the lull) with amber guide strips |
| EX-CH07-S11 on | LOC-02 | EN_Fabrication: the bench facing the walkway with the December spare in its cradle, the case open beside it with Kai's note clipped inside the lid (S10 → S11), battery, connectors, echo unit and isolation checklist; the surveyed-route simulator with its three pins parked. Chapter 6's guide light, test panel and lamp clip stay |
| EX-CH07-S12 | LOC-01 | **EN_Garage (M3-4A) is not built**, so the departure plays in the Commons, where the roster puts all five: the main display shows the two destination boards (rover: Ferreira, Kai, Rafi; Aurora: Mei, Amara) and the rover loadout stands on a table by the airlock door (packed spare Kai labelled, battery, three helmets, three-site route card, three repeater cases, duplicate route and shelter checklists dated 8 Apr 00:00: S11 → S12, CH07 → CH08); D12 packs Kai's copy of the observation he sent home. Restage it in EN_Garage when that room exists |

In the Safe Room a cast member whose scene anchor is an installed seat sits (the storm steps, S05–S08); one at a staged
work anchor stands (S02–S04). There are no stand-in benches.

Run `game/tools/run_tests.sh chapter6_rooms` / `chapter7_rooms` (mapping, rosters, stations, navigation, collision,
resting props, readable signs and screens, every §2.9 join, echoes, re-staging back to Chapter 1, cast placement), and
`production/qa/evidence/M3-6R_capture.sh` / `M3-7R_capture.sh` for the windowed screenshots and frame timings.

# Chapter 2 rooms (M3-2R)

The explicit CH02 scene map already used by the mission gates is retained:

| Scenes | Room | Physical story carriers |
|---|---|---|
| S01–S02, S06 | LOC-03 | Earth console beside Tara (contact returns 30 Apr), equal-size paired flower portraits and identity records; cross-pollination protocol, labelled brushes, magnifier, nonliving practice flower and paper bee; seven-date care strip with three bee stamps (one crooked), prediction threaded to the family-tree page, clean seed tray |
| S03–S05 | LOC-05 | Approved airlock kit and its running pressure interlock; Alo behind sealed glove-port glazing, sealed carrier pass-through, sample bench and microscope, separate brush directions; real out-and-back route with four boundaries beside Kai's incomplete sketch, space-weather check reminder, paired care record and saved contact image |
| S07 | LOC-01 | Life-cycle cards distinguish current flower, old unflowered seedlings and a reference drawing of later pods; clean tray beside the care strip, paper bee's wing at the recorder's HORT-01 label. The mission-table top is a ring (r 0.42–0.86 m) round a recessed display, so the record sits on the near side, the strip and tray on the far side and the recorder on the display |
| S08–S10 | LOC-02 | Recorder service bench, original plate beneath the service sticker, three sourced metadata cards, Observed / Inferred / Unknown board with the person's space blank; reconstruction slots, dated playback and both 2034 transcripts loaded word for word from the catalog |
| S11–S12 | LOC-01 | Sent/receipt/reply columns kept separate; cup by the pending indicator (rattles in S12); marked brace zone with four name tokens, moved service cover; on the atmosphere panel the tank row turns red in S12 (the oxygen-tank symbol and TANK PRESSURE · WARNING) |
| CH03 S01 | LOC-02 | Same red pressure warning at 22:05 on the air console's status screen, standing on PR_OxygenUnit: the S12 panel's rows word for word, the oxygen-tank symbol red; recorder and evidence board remain through the same night's work (S05) |

The LOC-05 shell reuses `en_airlock.gd` from M3-2A, turned half a revolution about the room centre
(`"shell_yaw_deg": 180` in `LOC-05.json`, applied by `HabitatRoomBuilder.build_airlock`): the garden wall with the
glove ports, pass-through and sample bench is the north wall, the inner door to the Commons the east wall and the
surface hatch the west wall, so every station is approached from +Z like the other rooms' equipment walls (the
campaign flow test reaches each station from 1 m on +Z). Its hatches, lids, panels and pump retain that service's rules;
floor/ceiling tiles are batched, room practicals replace its standalone lighting, and the Commons portal uses the
existing pressure-door and corridor builder. Samples cross the garden interface; people stay on the vestibule side.
Collision, navigation clearance, furniture footprints and crew positions are authored in `LOC-05.json`. Alo stands on
a 0.2 m stand at the back of the sealed chamber so her flowers sit in the pressure window's sightline. The
`EN_Airlock_GlovePort` GLB closes its back with a grey plate behind the window, so the room builder drops that plate
from its placed copy (`HabitatRoomBuilder.open_window_back`) until M3-104 fixes the asset build.
Chapter 1, 6 and 7 layers and the Chapter 1 base layouts are preserved; returning to Chapter 1 removes the Chapter 2
staging. Three campaign-side steps are Atik's (board task M3-103): `LoadPreparation` registering `airlock.tscn` for
LOC-05 (until then the campaign builds LOC-05 as a bare `CampaignRoom` from `LOC-05.json`, so the kit and airlock
GLBs load on the main thread instead of with the loading card), the `door_commons_airlock` boundary in
`RouteNavigation` (until then that door reads closed; `WorldRoute.restore` already gives older checkpoints its
default once it exists), and `Chapter1Campaign` passing `story_log.choices` to `CampaignCrew.place` and binding
mission targets to the room's `stations` (until then D4's prediction and D5's inference card show only where the
caller passes the choices, as `test_chapter2_rooms.gd` does).

`test_chapter2_rooms.gd` checks all twelve scenes in their room state, physical traversal, interaction sightlines,
navigation, prop support, sign orientation, crew placement, echoes and the CH02 → CH03 join. Crew anchors keep 0.8 m
from every station approach the scene uses and 0.4 m from its line to the station (crew bodies block the player and
the interaction ray), except the brace zone where all four stand. Anything resting on furniture is ray-tested against
the visible meshes over its whole footprint, not the square collision boxes, and a 1.6 m eye at the glove-port
station must see Alo's flowers through glass only. The S12 panel and the CH03-S01 screen must show the same rows with
the tank symbol red on both, and the S11–S12 cup is one of the table's four mugs with or without the named mugs.

`production/qa/evidence/M3-2R_capture.sh` writes the 25 screenshots and four frame-time probes; the `--capture` pass
only renders (the checks stay headless). Its watchdog starts when Godot starts, not while it queues for the two-slot
gate; a stalled pass is stack-sampled and retried once. macOS stops Godot drawing when the window is reported covered
(another capture window, the lock screen), which used to hang the capture on `frame_post_draw`; the test now renders
those frames itself and records any frame timing it could not measure as not measured. Narrative timing, dated
cards, puzzle receipts and resource charges stay with their existing mission services.

# Exterior terrain (M1-82, for Atik's M1-36)

`exterior_terrain.json` places each playable exterior on the real LOLA terrain (M1-34) for the terrain provider
(`game/scripts/terrain/terrain_stream.gd`, Atik's). Authored per room: `region_id`, `origin_xz_m` (site frame),
`ephemeris_site` (whose JPL Horizons rows give the Sun and Earth directions), `horizon_site` (whose computed terrain
horizon holds where the room stands, or ""), `omit_staging_floor` and `placement` (why there). `game/tools/
test_exterior_terrain.gd -- --write` derives the rest from the region's detail heightfield; every test run re-derives
and compares, so a moved prop or a new heightfield fails until it is re-written.

| Room | Region, origin | Why | Earth |
|---|---|---|---|
| LOC-06 mast courtyard | `aurora_ridge` at the Aurora site | the site of the Horizons rows and terrain horizon | dated rows where Earth clears the horizon |
| LOC-09 surveyed ridge | `cold_trap` at the computed road's last bend (-620, -1000) | EX-CH04-S04's corner, 146 m above the basin | never: no horizon computed there |
| LOC-10 vault approach | `cold_trap` at the cold-trap site | the PSR floor of the S05/S06 rows | its rows put Earth below the horizon |
| LOC-11 relay route | `relay_road` at relay_road_mid, **pending** | the 80 m corridor is too coarse to walk; needs the 10 m patch | — |

Frame: room-local = site frame - `origin_m`, same axes, no rotation. The campaign keeps the room at its origin, puts
the stream at `-origin_m`, `configure(region_id, origin_m + player anchor, exclusions)` and `move_focus(player.position
+ origin_m)`. Published (room-local unless noted): `origin_m`, `anchors`, `focus_targets`, `focus_approaches` (1.5 m from
each target, a straight lane from the player anchor), `detours` (one waypoint where a door or prop collider cuts the
lane), `props`, `fixtures`, `doors` (resting at the lowest ground under the part that meets the ground: nothing floats;
`bury_m`, `footprint_m`), `exclusions` (site frame, the provider's rock clear areas over every spot and lane),
`max_walk_slope_deg` (at most 15 deg), `ground_y_range_m`.

- `CampaignRoom.terrain_ground = true` (before the room enters the tree) is the explicit flag: with a placement that
  sets `omit_staging_floor`, the room builds no staging floor, apron rails, flat navigation or greybox light rig, and
  stands its anchors, focus targets, props, fixtures and doors on the published spots. Every id, door, pressure marker
  and scene id is the same; `on_terrain()` reports it, `terrain_anchors()` gives the anchors, and `CampaignCrew.place`
  uses them. Without the flag (or for LOC-11) the flat greybox is exactly as before.
- `RoomContract.terrain(room_id)` returns the placement; `RoomContract.earth(room_id, scene_id)` the dated Earth:
  `presented` only when the room stands at the row's site with a computed horizon, the scene has a bundled row
  (`lola/sun_positions.json` `scene_lighting`) that puts Earth above the terrain horizon, and Earth is not over the Sun
  (the EX-CH06-S07 eclipse is canon only through the filtered camera). It carries `direction`, `sun_direction`,
  `angular_diameter_deg` (1.899: 2 atan(6,371 / 384,400 km)), `illuminated_fraction` and its source; otherwise a
  `reason`. `EarthSky.apply(environment, spec, sun_energy)` (`game/assets/environment/terrain/earth_sky.gd`) draws it
  in the sky pass of the provider's rig environment (`sky_env_earth.gdshader`), lit by the dated Sun, so the terrain
  in front hides it; a hidden date leaves the black sky. LOC-06 shows Earth in EX-CH01-S01, EX-CH01-S12, EX-CH04-S02,
  EX-CH04-S09 and EX-CH05-S01.

Run `game/tools/run_tests.sh exterior_terrain` (placements against the heightfields, walkable lanes, rock clearance,
the terrain-mode and flat rooms, a real player walking on the provider's collision to every approach and crew anchor,
the Earth rules) and `production/qa/evidence/M1-82_capture.sh` (windowed wide and ground views on the terrain, and the
rendered Earth's measured size).
