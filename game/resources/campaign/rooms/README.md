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
  navigation map), `focus_targets` (stations). M3-5R: a `texture` print with `"screen": true` is a lit display and
  `uv_rect` crops its image; a prop may carry `parts` (node name -> `visible`, `position`, `rotation_degrees` in the
  prop's own space, e.g. one 2034 record moved or turned over alone; or M3-4R's bare `[x, y, z]` rotation, both read by
  `_pose_parts`) and `surfaces` (material name -> `texture`, drawn
  unshaded, e.g. the impact monitor's `Screen`).
- Changes: `hide` (base node ids, including their obstacles), `hide_signs` (base sign texts),
  `focus_labels`, `anchors` (merged by key; later layers win), `lighting` (`practical_scale`,
  `strip_scale`, `ambient_energy`), `carried` (an object on a cast member's bone, e.g. Kai's lamp).
- `stations` maps each scene action to the focus target it happens at; `RoomContract.station_focus()`
  answers it for the mission catalogue.

| Scenes | Room | What the staging shows |
|---|---|---|
| EX-CH06-S01..S05, S10, S11 | LOC-02 | Guide light leaving the protected supply at Kai's taped junction box (CH05 → CH06) and running low along the aisle to the Commons door; protected-bus test panel with F2 (A-42) beside that door; two decorative floods (shed in S10–S11); allocation board above the guide line (five cards from S01, the P-11 accepted plan and 7-unit forecast from S04); camera repeater desk with Kai's dated log; the lamp in its clip in the wall locker (S01, and from S12), on Kai's hip S02–S11; per-scene crew anchors (Ferreira in the Commons doorway; D11 companion at Kai's shoulder in S10); practicals at 18 % in S10 (the amber guide line is the only warm light), 55 % in S11 |
| EX-CH05-S01 on | LOC-01 | Five seats and five mugs; Ferreira's chair at the head until EX-CH07-S01 moves it. Her mug: on its clip above the table (S01), at her place (S02–S05), at the corridor watch in LOC-02 (S06–S10, canon), beside the four again from S11 |
| EX-CH05-S06..CH07-S12 | LOC-01 | D9: the ascent manifest or greenhouse service note at her place (under her mug from S11) |
| EX-CH05-S11 on | LOC-01 | D10 (OPT02): the seed-label holder marked "N." |
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

A cast member whose scene anchor is an installed seat's sitting point sits in it, facing the way the seat faces
(`CampaignRoom.installed_seat_facing`, base or staged seats): the Safe Room's storm steps (S05–S08) and, from M3-5R, the
Commons table where a scene seats the crew (EX-CH05-S05, S11). One at a staged work anchor stands (EX-CH07-S02–S04).
There are no stand-in benches.

Run `game/tools/run_tests.sh chapter6_rooms` / `chapter7_rooms` (mapping, rosters, stations, navigation, collision,
resting props, readable signs and screens, every §2.9 join, echoes, re-staging back to Chapter 1, cast placement), and
`production/qa/evidence/M3-6R_capture.sh` / `M3-7R_capture.sh` for the windowed screenshots and frame timings.

# Chapter 5 rooms (M3-5R)

The CH05 scene map is explicit in `room_contract.gd` (and `scene_rosters.json` agrees): S01 LOC-08, S02 LOC-02,
S03–S07 LOC-01, S08 LOC-02, S09–S11 LOC-01, S12 LOC-03. From EX-CH05-S01 Ferreira is a physical cast member at Aurora.

| Scenes | Room | Physical story carriers (doc 24 §2.5, §2.9, §4, §5.2; doc 22 §7.1–7.4) |
|---|---|---|
| EX-CH04-S12..CH05-S01 | LOC-01 | The fifth mug on its clip above the table on a ceiling rail, with Ferreira's name tag (CH04 → CH05); from S02 it stands at her place |
| EX-CH05-S01 | LOC-08 | The arrival at the garage dock, staged by M3-105 (see "LOC-08, the rover garage"): Ferreira on the landing-pad camera, dust settled; the tunnel SEALED until two checks agree; the relief cargo in the cargo lock for its seal check; the five-person roster on the departure boards (S01 → S02) |
| EX-CH05-S02 | LOC-02 | Ferreira's corridor watch: her locker shelf with the sealed document sleeve, unopened (S02 → S03), the watch desk and log (her round passes the annex hatch N.R., doc 24 §3.5 F11); the spare's sealed crate with the received manifest; the inventory board (stored once in the Commons spare locker, procedure saved locally); the atmosphere panel with Amara's dated, reasoned correction still visible and the reading to sign against the independent gauge on its hook (M3-3R's CH03-S05 gauge, hung by `ch03_gauge_on_its_hook`) |
| EX-CH05-S02..S12 | LOC-01 | The Commons spare locker beside the records desk with the sealed crate; in S06 the crate open, the controller packed, Kai's compatibility note clipped inside the lid (the note CH07-S11 finds there) |
| EX-CH05-S03..S05 | LOC-01 | PR_Records2034 on the near arc of the table, each sheet moved alone: S03 set down out of order, S04–S05 in the supported order (numbered 1–4; 08 P-09 times; FER and N.R. the highlighted signatures; four departed, four boarded); S05 the evacuation order turned over with Ferreira's margin note (clue 18). The opened PR_DocumentSleeve beside them. D5 (CH02-S10 choice): the voice card in S03. The frozen-tray photograph (S03 → S04); S04 the close photograph, Alo's pressed petal, the 2034 growth sheet and Alo's own record apart, Mei's draft caption, revised in S05 (S04 → S05). S05: CS-09's shared frame, Ferreira seated at the head with Kai, Amara and Rafi in theirs, practicals 80 % |
| EX-CH05-S06..S12 | LOC-01 | The records desk on the north wall (where the CH06 eclipse desk and CH07 care desk stand later): S06 the 2034 relay diagram beside the spare's service card and the replacement procedure that opens without Earth (S06 → S07); from S07 PR_ImpactMonitor with an authored M3-5A candidate frame on its Screen, Rafi's frame log (0 of 6 in S07, complete from S09) and "amplified camera view"; S06 Mei's question card beside a current photograph |
| EX-CH05-S07 | LOC-01 | Night observation: practicals 30 %, strips 25 %, a cool spill from the monitor; the crew round the screen |
| EX-CH05-S08 | LOC-02 | Maintenance console (panel trend: reference 8, today 6, after the first observation phase: S07 → S08) with the cleaning card and kit; the isolated garden spur's own pressure trace, patch kit at its safe side, "living enclosure stays closed"; Ferreira's mug on the watch desk |
| EX-CH05-S09 | LOC-01 | Tonight's observation record beside the 2034 damage report on the evidence table; the main display's bounded report (supported, unsupported, the honest blank "not established") |
| EX-CH05-S10 | LOC-01 | Rao on the Earth screen; the signed page (consented; the 2034 portrait only here) beside the ALO / N. packet, the permission note, the signature card (manifest N.R. beside the page's), the report receipts (made versus delivered) |
| EX-CH05-S11 | LOC-01 | The message composer addressed to Dr Noor Rahman with both authored openings and the current garden photograph; D10: once chosen, the opening shows delivered once, receipt kept, no reply yet (and OPT02's N. holder); Ferreira seated at the head beside her mug, Kai and Amara seated |
| EX-CH05-S12 | LOC-03 | One cotton seed planted in Tara's bay (PL_Cotton_Seed in Tara's pot; Alo and Tara hidden: records now), Tara's name on the frame, Alo's pressed petal beside the label (M3-3R's lineage-board petal and its caption, moved there for this scene by `by_scene`), a pin board at eye height with Noor's text word for word (clue 20), the vault manifest note "Let one grow further." (clue 14) and the dated care card into January; the quarantine record and vault ledger (1 planted + 11 stored = 12) on the care bench, the founder reserve's separate ledger (30, sealed) on the seed archive; Kai carries the marker tape (CH05 → CH06, which opens beside his taped junction box) |

`CampaignRoom.load_assets_incremental()` also prepares, on the loader thread, the models the coming scene's staging shows
(`RoomContract.staging_asset_paths(layout, scene)`: staged props, photographed print subjects, carried and attached
objects; the scene is `upcoming_scene` or the owning campaign's route scene), so staging it decodes nothing on the main
thread (the EX-CH05-S02 full-cast entry in `test_performance_runtime`).

Not staged as their own models: the panel-cleaning kit, spur patch kit, relay-controller crate,
message composer and signed identity page are fixtures and words until their assets exist (board task filed by M3-5R).
Run `game/tools/run_tests.sh chapter5_rooms` (every check) and `production/qa/evidence/M3-5R_capture.sh` (windowed
screenshots and frame timings; that pass only renders, and draws its frames itself when macOS reports the window covered,
leaving the timings "not measured").

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

# Chapter 3 and LOC-07, the Expedition Zero annex (M3-3R)

`LOC-07.json` / `annex.tscn` is a real two-deck room. The **warm-side access bay** (8 × 6 m, the approved kit, its
pressure door `door_service_annex` to the service rooms) has the M3-3A `EN_ZeroAnnex_FloorHatch` module in its deck;
`floor_openings` leaves the kit floor tiles and floor collision out of the 2 × 2 m hatch well. The **2034 annex**
(`lower_deck`: 10 × 6 m, 3 m below, `EN_ZeroAnnex` grating, frosted ceiling with eight dead fixtures, riveted walls) is
batched like the kit, with its own floor, wall and ceiling collision and a lined well. The ladder stands in the well.
Navigation has two decks that are not joined (the ladder is climbed, not walked); each obstacle belongs to the deck its
centre stands on. A walking-height obstacle round the coaming keeps anyone from stepping into an open well. The N.R.
leaf is the `annex_hatch` boundary (`hatch_doors`): `set_door_open("annex_hatch", ...)` swings it, and the leaf's own
collision blocks or clears the opening.

New layout and staging keys (all optional):
- `kit_props`: live kit or annex pieces with collision, named by `id`: `parts` (moving part → open fraction, e.g. the
  quake's displaced `Cover`), `texts` (words on a full-UV `Screen`/`Document_*` slot through a SubViewport; `paper`,
  `font` hand/print, `flip` h/v for a slot whose UVs run mirrored; `camera` {from, to, fov} shows a live camera view
  instead, the S06 hatch camera), `inks` (Label3D words on small plates, optionally riding a moving `part`, e.g. N.R.
  on the leaf) and `attach` (a GLB or M3-99 narrative prop seated in a socket, e.g. the frozen trays).
- Staging maps `kit_parts`, `kit_texts`, `kit_attach` change those per scene; `clear()` restores the base room's.
- Staging map `outfits` (cast id → `eva`): `CampaignCrew` puts that cadet in the fitted EVA suit (`CH_<Name>_EVA`) with the
  role helmet seated, visor up, and a helmet lamp. Bodies are kept per outfit, so a cut never duplicates anyone.
- A staged `<room>_player` anchor replaces the base player anchor the caller passes (S07 starts on the cold side).
- A staged `earth_screen` fixture gives `CampaignCrew` an Earth-link screen in any room (Ferreira in S03 and S06).
- `local_lights[].shadow` (a lamp on one deck never lights the other); `signs[].roll` (a crooked label);
  `signs[].font_path` (Mei's handwriting on Tara's card).
- `walk_probe` points may carry a third value, the deck height.

| Scenes | Room | What the staging shows |
|---|---|---|
| EX-CH03-S01..S05 | LOC-02 | The atmosphere service corridor: M3-2R's air-console status screen keeps the red TANK PRESSURE warning (CH02 → CH03, no time jump) until the five checks clear it (S05); the independent gauge on its work stand by the recorder bench (which stays the same night); taps 1–3 on the real service points (main 100/100, garden spur 82/74, return 100/100); the free-standing diagnostic board at the air bay's mouth with the simplified piping diagram, Kai's hypothesis (S01 → S02), the saved readings and proposed boundary (S02 → S03), the paused previews and rollback (S03 → S04), the approved sequence (S04) and the five checks, corrected note and camera-only annex handover (S05 → S06); Ferreira's repair diagram with her line word for word under an Earth-link panel in the power bay (S03); the work boundary (S04); practicals at 85 % until the warning clears |
| EX-CH03-S01 on / S04 on / S05 on | LOC-02 | The crooked GARDEN SPUR label (straight from S06); the seated clamp; the gauge on its hook. They stay (doc 09) |
| EX-CH03-S06 | LOC-07 | The camera-only inspection: displaced cover, N.R. hatch (clue 10), feed isolated, zero differential, port open, the hatch camera's live view on the warm-side screen, the safety drawing, the 8 May entry schedule, Ferreira's Earth link |
| EX-CH03-S07 | LOC-07 | The suited entry: hatch open; Mei and Rafi in EVA suits below, Kai and Amara at the station on the local radio; frozen trays, the growth chart ending "Day 12. Leaves curling. Heat" (clue 12), the 2034 tag and the route sheet under its sealed cover (clue 11), the gear-wheel tool tag on the station (clue 12, S07–S08), the return boundary at the ladder foot |
| EX-CH03-S08 | LOC-07 | The warm-side evidence table: the scanned route sheet, the tray photograph, the care visits to 16 May (S08 → S09); the planning board's provenance and present-day checks (clue 13) |
| EX-CH03-S08, S12 | LOC-03 | `care_round` (doc 24 §7.2): Alo and Tara in S08, Tara only in S12 |
| EX-CH03-S09..S11 | LOC-03 | The drying bench: the five-day dry-down card, the pod record; the contained tray, 42 = 12 + 30, the open founder case and the sleeved petal (S10 → S11); the sealed case and seal record (S11). Vigil photos per moment `CH03-ALO-VIGIL-1..5` (Kai's tea from the fourth) |
| EX-CH03-S10 on | LOC-03 | The lineage board: Alo's nameplate and record (S10), her pressed petal (S11), Tara's nameplate level with it, Tara × Alo working stock and the first lineage photograph (S12). It stays |
| EX-CH03-S11..CH04-S01 | LOC-03 | The planting rack (PL_Descendants_Planted, then the October PL_Descendants with a few green stems among purple), parent line Alo × Tara, Kai's position 1; D6 dedication `EX-CH03-S11-DEDICATION-OPT01..03` (Light and Star / For Alo and Tara / The Next Small Thing); the May prediction (D4, M3-2R's card) stays on the lineage board through CH04-S01 (CH03 → CH04) |
| EX-CH03-S12 | LOC-03 | Tara's farewell in her bay (dry pods, the sealed Tara × Alo envelope with no count, Mei's card, her name kept on the frame), the care ledger for the days between, the survey board's preparation list; D2 at the bench (S09–S10) and the bay (S12); Tara's last photograph with `CH03-TARA-FAREWELL` |

Run `game/tools/run_tests.sh chapter3_rooms` and `production/qa/evidence/M3-3R_capture.sh` (windowed, 37 screenshots and
frame timings).

# LOC-08, the rover garage (M3-105, Chapter 4 rooms M3-4R)

`LOC-08.json` / `garage.tscn` is the approved M3-4A garage (`en_garage.gd` from `garage.json`, Sadman's "Approve all 12",
decisions 1-7) built as a kit room by `HabitatRoomBuilder.build_garage`. Room coordinates are garage.json's minus
(6, 1.4, 4.5) (`shell_offset_m`), so the room centre is the origin and the **ready room** (habitat air, 12 x 3 m along
the north wall) has its deck at y 0 like every kit room; the **vacuum bay** floor is y -1.40 and the **EVA porch** at the
rover's rear is level with the deck (decision 4). The pieces named in `garage_roles` and the docked VH_Rover stand under
VisualRoot by role; floor and ceiling tiles are batched; the room's four practicals replace the kit light strips; the
bay keeps three 5,000 K floods (`bay_floods`, under `VisualRoot/BayFloods`); the porch stair, drawn on the porch piece
without collision, gets one ramp (`stair`). The inner door is the room's portal `door_commons_garage` with its kit
corridor (decision 2); the dock hatch (`garage_dock_hatch`) and the rover door (`rover_bay_door`) are driven through
`CampaignRoom.set_door_open` / `garage()`. The ready room is the room's pressure (`pressurised`); `zones` names the
vacuum porch and bay.

Navigation uses the new `navigation.areas` (walkable rectangles at their own height, a `ramp` for the stair, `open`
edges that join another area; an obstacle with `area` blocks only that area): the deck, the porch, the stair and the
bay floor. The pressure wall keeps the deck and the vacuum apart; a suited cadet can walk the porch, the stair and the
aisle beside the rover's wheels to the rover door. `sealed_enclosures` names the dry cargo lock's chamber (what rests
in it rests on its cradle) and `interior_walls` the pressure wall, for the staging checks.

The dock (garage.json `dock`, en_garage.gd): the tunnel is equalised to the cabin (`habitat`, SAFE TO OPEN) or pumped
down (`vacuum`, SEALED); `request_dock_cycle()` runs EQUALISING for 8 s on screen (about 2.5 min real, the labelled time
card on the panel and from `time_card()`), with the pump hum (SFX_PUMP_PRESSURE) in the ready room only; the hatch opens
only on SAFE TO OPEN; `dock_snapshot()` / `dock_restore()` save it. The staging map `garage` sets each scene's start
(`dock`, `lock_door`, `relief_locker_open`, `rover_door_open`); `clear()` puts the garage back at rest.

New staging list `kit_screens`: live words on a piece's named slot (`node`, `slot` Screen / Screen2 / Screen3 / Label,
`text`, `fg`, `bg`), laid as a Label3D on the slot's own plane (`Kit.surface_frame`) and fitted to it, so they read the
right way round whatever the slot's UVs; the slot glows dark behind them. (`kit_texts`, M3-3R, paints the slot's UVs
instead.)

| Scenes | What the garage shows |
|---|---|
| EX-CH04-S02 | One ledger per destination on the two departure boards (ROVER: Rafi, Kai, own 48 h manifest; AURORA: Mei, Amara, base ledger), the closed recovery carrier and the ice scanner by the cargo lock, Kai's spare light in its labelled clip, the suit seals, the rover manifest on the cargo rack apart from the base ledger, Amara's handover console; the tunnel SAFE TO OPEN |
| EX-CH04-S03 | Route cards A / B / C on the route board with the reason each passes or fails (B: 12 km, max 12 deg, 30 + 30 of 100, 40 left against 30), the beacon plan on the console (S03 -> S04) |
| EX-CH04-S09 | The return: the tunnel starts SEALED (the player equalises it), the sealed case in its MLI sleeve in the dry cargo lock with the inner door open (decision 5), the sealed sample on its own shelf and record, the same report shape on the console, the return link chain; Kai suited on the EVA porch (outfit `eva`) (S09 -> S10, the garden glovebox) |
| EX-CH04-S12 .. CH05-S01 | The relief locker labelled for the 8-12 Dec flight (decision 6); CH05-S01: Ferreira on the landing-pad camera (Screen3), the relief cargo in the lock awaiting its seal check, the tunnel SEALED until two checks agree, the five-person roster, Ferreira's corridor watch by the inner door |
| EX-CH07-S12, EX-CH08-S01 | The two destination boards (ROVER: Ferreira, Kai, Rafi; AURORA: Mei, Amara), the journey card and the home-night ledger on the console, the rover loadout on a table by the corridor door (Kai's packed controller, battery, three repeater cases, three helmets, the route card, the duplicate checklists dated 8 Apr 00:00); D12 Kai's family copy. CH07-S12 moved here from the Commons (decision 7): its roster is LOC-08 and the Commons' S12-only layers are gone |
| EX-CH08-S11 | The return home: the tunnel starts SEALED, ROVER HOME 10 Apr 03:00, FIVE HOME |

`exterior_terrain.json` LOC-08 places the garage on the Aurora ridge with the M1-82 frame (`site_from`: 80 m from Aurora at
azimuth 150, the rover door turned to azimuth 100, `yaw_deg`; the bay floor on the ground at the apron; the pad's relief
and slope under the berm), derived by `test_exterior_terrain.gd -- --write`. Its floors are the room's own
(`omit_staging_floor` false); the terrain is the ground outside the berm and the rover door.

Campaign-side steps are Atik's (board task M3-109): registering `garage.tscn` in `LoadPreparation.ROOM_SCENES`, the three
boundaries in `RouteNavigation`, driving the dock cycle and its time card from the scenes that start SEALED, and the
turned TerrainStream outside the rover door. Run `game/tools/run_tests.sh chapter4_rooms` and
`production/qa/evidence/M3-105_capture.sh` (windowed, 19 screenshots).

# LOC-09 and LOC-10, the cold-trap road and the vault shelf (M3-106)

`LOC-09.json` / `ridge.tscn` and `LOC-10.json` / `vault_shelf.tscn` are exterior sites built from the approved M3-4A
EN_ColdTrap pieces and the vault set (new assembly `site_kit`: props are kit pieces by `piece` with their LOD0 collision
and mount offset, a GLB by `path`, or a scene by `scene`, e.g. `VH_Rover_Lit.tscn` with its headlights; `box_collider`
makes the rover solid; `follow_ground` lets it pitch and roll with the terrain; PBR materials; no door nodes on open
ground). `dated_sun` turns the flat fallback floor's key light into the scene's dated Sun from its Horizons row (in the
room's frame), and puts it out when that row says the Sun is below the local terrain horizon.

LOC-09 (decision 8) is played at the three computed beacon corners of EX-CH04-S04 and at the last bend: its room frame
runs the road along -Z with the corner's road cell at the origin; `exterior_terrain.json` LOC-09 `segments` B1 (1.02 km,
aurora_ridge, sunlit), B2 (1.88 km, sunlit) and B3 (5.24 km, cold_trap, in terrain shadow) each carry their own region,
origin and `yaw_deg` (the road's bearing), and `sun_positions.json` has a row per segment with the horizon where it
stands; the room's own placement stays the 7.82 km bend, EX-CH04-S05's reference and sample station. `clear_lanes` keeps
scattered rock off the road. Staging layers or items with `segment` show only on that segment (the slope sign's value).
LOC-10 is the shelf in the cold-trap site frame (coldtrap.json `staging.shelf`), bounds 34 x 34 m so the rover stands
15 m back inside them. A fixture laid at an angle (the boot prints, the tether) carries `rotation_degrees` [pitch, yaw,
roll]; a bare `yaw` on a fixture stays the wall an Earth-screen fixture hangs on (CampaignCrew) and does not turn its box.

| Scenes | Room | What stands there |
|---|---|---|
| EX-CH04-S04 B1 / B2 / B3 | LOC-09 segments | The 5 m beacon mast left of the road before the blind corner, its head reading BEACON n, NEXT HOP and LINK NOT TESTED (a mounted beacon with no test does not count); the return marker; the slope sign with that corner's own slope (2, 6, 9 deg, under the rover's 15); the rover 8 m back, lamps on; Rafi and Kai suited. B1 and B2 sunlit at 08:00 UTC with Earth low on the horizon, B3 in terrain shadow (S04 -> S05: an unbroken chain home) |
| EX-CH04-S05 | LOC-09 (last bend) | The dry reference plate with the calibrated scanner on its socket and three numbered sample stakes in the headlights; the readings stay in the scanner (reference 2, threshold 12, samples 2/18/19); the Sun below the terrain |
| EX-CH04-S06 | LOC-10 | The sealed sample's holder at its stake; vault V12 as deposited (thin dust film on its window), the unfaded 2034 marker with its archival tag (SURVEY MARK 2034, DEPOSIT V12: names nobody), two tether anchors, the 2034 crew's crisp boot prints; the closed carrier still on the rover |
| EX-CH04-S07 .. S08 | LOC-10 | The carrier tethered beside the vault to the first anchor (S06 -> S07), the thermal probe by the outer socket, the lid shut (probe, sleeve, cradle: S07 -> S08); the cargo mount station at the rover's rear rack |

On the terrain the far crater rims that shade the shelf and B3 lie outside the cold_trap heightfield, so the evidence
captures stand a shadow-only wall 400 m toward the Sun at the row's terrain horizon (`test_chapter4_rooms.gd`
`_dated_rig`); the campaign side (segments, turned stream, segment rows, that occluder or a cold_trap vista) is Atik's
board task M3-110. Run `game/tools/run_tests.sh chapter4_rooms`, `game/tools/run_tests.sh exterior_terrain` and
`production/qa/evidence/M3-106_capture.sh` (windowed, 10 screenshots).

# Chapter 4 in the base rooms (M3-4R)

Every Chapter 4 scene now plays in its own location (doc 24 §2.4): the field scenes in LOC-08, LOC-09 and LOC-10
(M3-105, M3-106) and the four base scenes below, staged on the M1-06 garden and Commons by the `ch04_*` layers of
`LOC-03.json` and `LOC-01.json`. The October rack (`ch03_descendant_rack`) and its dedication (D6) stay in the garden
through Chapter 4. A staged prop can now pose its moving parts and carry words on them (`"parts"`: node -> rotation in
degrees, `"inks"` as on a kit prop, with `"part"` to ride on one): vault V12's hinged lid and clue 15.

| Scene | Room | What stands there |
|---|---|---|
| EX-CH04-S01 | LOC-03 | The October rack with its count line (seven purple, five green in this sample, not a ratio); the observation card added beside the May prediction, which stays as written (D4 shows the player's own sentence, D2 files the count in the day-one Growth Record layout, D6 keeps the dedication on the rack); the limits card (the twelve current descendants, the sealed founder reserve of 30 and Alo's archived petal and photograph on separate lines); the rover checklist with Rafi's next-observation question (S01 -> S02) |
| EX-CH04-S10 | LOC-03 | The vault's dry quarantine glovebox on the care bench (a glass enclosure with two glove ports: the M1 glovebox is too small for the 0.60 m case and is set aside for the scene), its status strip (sealed warming done, no condensation, viability pending, not assumed); vault V12 inside it with the lid open, twelve capped wells and, under the lid, the handwritten line (clue 15, S10 -> S11); on the north wall the reconciled manifest (12 of 12) with N.'s note beside cotton in the packet's hand (clue 14) and the three ledgers kept apart, and the survey board with both field cadets home |
| EX-CH04-S11 | LOC-01 | The Earth screen: the lid image and the manifest sent and delivered, Ferreira's channel open on her empty chair for the quiet moment while Rao answers (EX-CH04-S11-L03), Mei's request delivered with no reply yet; on the Mission Table the exact inscription saved with its open question (stays into S12) and the claims card (what the lid supports; who N. is, abandonment and viability not supported) |
| EX-CH04-S12 | LOC-01 | The relief flight notice (8-12 Dec 2046, Rao stays at the Earth desk, Ferreira's "I owe you the story"); the relief cargo manifest on the table; the fifth locker in the crew locker bank named FERREIRA from 1 Dec (kept from then on) with the fifth-occupant handover sheet; the dated board of the days in between (22 Oct to 12 Dec). The fifth mug on its clip above the table comes with M3-5R's `ch05_fifth_mug_clip` (CH04-S12 to her arrival); the garage's relief locker is labelled from this scene (M3-105) |

Run `game/tools/run_tests.sh chapter4_rooms` and `production/qa/evidence/M3-4R_capture.sh` (windowed, 15 screenshots).



# Chapter 8 rooms (M3-8R)

| Scenes | Room | Physical story carriers |
|---|---|---|
| S01, S11 | LOC-08 | The departure boards and the arrival dock are EN_Garage's (M3-4A); M3-105 builds and stages that room. Commons: Ferreira's mug waits on the care desk S01–S10 and is back beside the others from S11 (S11 → S12); Aurora's copy of the home-night ledger lies on the care desk S02–S11 |
| S02–S04 | LOC-11 `relay_road.tscn` | The marker-two sector of the surveyed road (M3-8A EN_RelayRoad): 6 m road, amber guide lights every 18 m on alternate sides, the 20 × 15 m service pad of repeater R2 (dark, bay closed) with its tether anchor and eight markers, the unsupported bypass closed by the turnback barrier and slope sign. S02 the start of cruise (no pad on this stretch); S03 the rover braking on the road at the known pad (S03 → S04); S04 the rover braked on the pad with its roof floods on, Kai and Rafi suited, Ferreira aboard with the cabin checklist, the replacement battery module by the repeater. Dark by the dated rows: no Sun, no Earth, faint stars (ART_BIBLE §2 rule 12; 0.35 under the work floods) |
| S05, S12 | LOC-03 | Home-loop panel on the north wall (COOL, DIM, return OPEN, two independent readings, the 33 h + 3 h home forecast: S05 → S06), Amara's manual gauge, the small guide light by the Commons door, the flowering descendants on the rack, D1 day-one photo; S12: final records (five home, 30 sealed, 11 retained, cotton alive), the first-light photo board with the D2, D9, D10, D11 echoes and D6 on the lineage board, the D13 dedication plaque once chosen, the Earth console live |
| S06, S10 | LOC-01 | S06: the main display carries the new summit packet beside the stale approach packet, home checks first and the guide light where planned; S10: the three-place call (Rao and Noor on the Earth screen, M4-06), voice checks, telemetry and the 03:00 return on the care desk, the invitation open on Mei's tablet (D10). From S09 the outbox has sent and the diagnostic reads the Earth link live via the relay (clue 22) |
| S07–S09 (and the S06/S10 cut) | LOC-12 `malapert_summit.tscn` | The approved EN_MalapertSummit platform: relay deck (dish on the dated Earth, local antenna on R3), housing, isolator, pedestal, solar mast, tether anchors, 20 markers, umbilical, viewpoint rail, cable trays, VH_Rover_Lit parked west-facing. S06 housing dark beyond the cabin window (S06 → S07); S07 door braced open, spare beside it, panel unpowered; S08 two amber lamps, labelled scenario bearings and a separate blockage check (S07 → S08); S09 three green lamps, ALO42 and the two backlogs crossing (S08 → S09, clue 22); S10 the return time on the cabin console (S10 → S11). Sunlit by the dated row; Earth the 3 % crescent at 1.9 deg |

- **`assembly: "exterior_kit"`** (LOC-11, LOC-12): an exterior whose JSON authors every piece, obstacle and navigation cell like the
  habitat kit rooms, on the flat staging floor with apron rails. A prop with `"piece"` is instanced from the M3-8A catalogue
  (`chapter8_assets.gd`: both LODs, the game LOD's collision); a `.tscn` path is a packed scene (VH_Rover_Lit); `"walk_over": true`
  drops a low piece's collision (the 6 cm cable trays). `door_positions` (`[x, y, z, yaw]`) places each boundary marker. Navigation
  cells are 0.5 m outside (a 0.25 m grid on a 60 m road exceeds the path query's 4,096-polygon search).
- **LOC-12's frame** is the LOLA tile frame (exterior_terrain.json): the M3-8A layout is turned `platform_yaw_deg` (2.33 deg) so the
  platform's -Z is true north, and the dish stays on the dated Earth within 0.5 deg (tested).
- **`piece_states`** (staging map, piece id -> `{lamps, parts, screens, lights}`): lamp slots (`"#rrggbb"` or `"off"`), moving parts'
  rotation (the housing `DoorHinge`, the isolator `Handle`), live screen slots in plain words and the rover's light state
  (`rover_lights.json`: driving, eva_stop, parked_dark). `clear()` restores every piece.
- **`aboard`** (staging map, cast id -> `{at, facing}`): who rides inside the sealed rover cabin. `CampaignCrew` never draws them outside;
  passengers are switched off; the playable rider sits hidden at the cab seat, collides with nothing, reaches the cab console station
  (`"cab": true` focus) and gets a chase view over the roof. Driving and the cab view proper are the rover runtime's (board task for Atik).
- **`outfits`** (`id -> "eva"`, M3-3R's shape): the M3-3A EVA suit and role helmet; outside in vacuum the visor is down, indoors up.
- **Sky on the flat floor** (`RoomStaging.apply_sky`): the dated Earth where `RoomContract.earth` presents it, with the key light turned to
  the same dated Sun; otherwise black, with `lighting.stars` (a faint sparse field, `sky_env_stars.gdshader`) only on the dark road.
  `exterior_terrain.json` LOC-12 `sky_rows` gives S07 the S06 row (00:00) and S09 the S10 row (02:00), both inside their windows.
- **Terrain:** LOC-11 waits for the 10 m patch (M1-87). LOC-12 has its summit placement and dated sky but stays on the flat floor: the raw
  5 m tile falls up to 2.4 m across the pad M3-8A cuts and fills level, and the provider cannot grade a pad yet (board task).

Run `game/tools/run_tests.sh chapter8_rooms` (mapping and the two teams, stations, navigation, walking, collision, words, aboard and EVA
cast, the Moon rules and the dish aim, every §2.9 join, the echoes, re-staging) and `production/qa/evidence/M3-8R_capture.sh`.
