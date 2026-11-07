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
  may carry `"moment"`; staging props may carry `"variant"` (an M3-99 narrative prop variant).

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
  line), `prints` (`solar_image`, `eclipse_frame`), `local_lights`, `obstacles` (collision and the rebuilt
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
