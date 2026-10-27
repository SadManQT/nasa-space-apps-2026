# Last Light Academy — readiness audit

27 October 2026, 11:32 Asia/Dhaka. Godot **4.7.2.stable.official.ed1daf0bf**. Scope: every item in Production Handbook §8, the hold layer, and tonight's patch/toon/face fixes. No rendering, asset generation, paid calls, commits, or writes under `game/assets` / `production/models` were performed by this review.

## First priority: a playable Chapter 1 hackathon slice

**The assets import, but Chapter 1 is not assembled or playable yet.** There are 49 installed GLBs and three screen portraits; the only five scenes are player, locomotion test, character review, and two look-dev scenes. `project.godot` has no main scene. Props are inventory, not completed interactions.

1. **Build the Chapter 1 rooms and route:** Commons, habitat connections, Garden/Tara reference bay, Power/Atmosphere rooms, Safe Room, and mast courtyard. The three existing environment GLBs are reusable pieces, not those locations. Add collision, navigation, room lighting and interaction points. The current prop imports have no post-import script configured.
2. **Make the Chapter 1 loop and readable UI work:** planning/forecast, power and air allocation, planting and paired care, PUMP/STACK/WAIT shelter preparation, roll call, shutter/first-flower reveal. HUD, mission journal, captions, decisions, debrief and accessibility settings are still absent. Wire a launchable main scene and progression.
3. **Complete the plant timeline and care tools:** Alo seed/sprout and Tara's matching early stages, stress states, two usable planting cassettes, moisture probe/reference and calibration station. Existing Alo bud/bloom models cannot stand in for an unflowered sprout. Build the growth chamber's usable shutter; its GLB is a static single mesh.
4. **Connect the v7 presentation to gameplay:** the player loader currently installs movement, gaze and foot placement, but does not apply `ToonMaterials`, `FaceAtlas` or hair springs. Look-dev applies toon to the cast and three props; only Kai gets FaceAtlas there. Keep Ferreira on an Earth screen in Chapter 1; Rao's new portrait is available. Supply the correct screen outfit and live console content.
5. **Restyle the Chapter 1 props and plants:** start with toon materials and reduced PBR detail, then remodel only the interaction pieces listed below. Preserve transparent patch materials, readable screens, four mugs and four supply bundles. Do not count an old PBR review as anime approval.
6. **Deliver Chapter 1 audio and cutscene integration:** 49 Chapter 1 VO lines, CUE-01–04, 16 SFX first used in Chapter 1 plus the three general UI effects are planned, with no audio files installed. Captions must carry the story without VO. CS-01/02/03 have old-style MP4 shots, not integrated v7 cutscenes. No `.ogv` files exist in the game.

## Verified inventory and limits

| Category | Installed | Result |
|---|---:|---|
| Characters | 5 GLBs | All load; 44 clips each, 13 importer-marked loops; 65 bones, Mei 68 |
| Plants | 7 GLBs | All load; static meshes, no animation clips |
| Props | 31 GLBs | All load; static meshes, no animation clips |
| Environment pieces | 3 GLBs | All load; no assembled chapter locations |
| Vehicles | 3 GLBs | All load; no vehicle gameplay/boarding animation setup |
| Screen portraits | 3 PNGs | All load as 1376×768 textures: Rao, Noor 2034, Noor present |
| Audio | 0 files | 385 VO rows, 12 score cues, 35 SFX specifications only |
| Game cutscenes | 0 files | Production has 23 MP4 shot masters, 134 planned seconds total |

`game/tools/verify_assets.gd` returned **49/49 loaded**, with floor height 0.0 m and textures 1024–4096 px. Its output was also checked with the existing `verify_gate.py` `specs()` / `check()` functions: **49/49 pass**, without overwriting the existing verification report. All 49 GLBs match their `production/models/final/<ID>/<ID>.glb` counterparts byte for byte. All 49 import-cache source MD5s match the current GLBs. No missing model resource, texture import, parse, or shader-resource loading error appeared in the required checks.

The gate permits 1% triangle overrun: Ferreira has 60,022 triangles against 60,000, and the dosimeter has 8,004 against 8,000. These are passes under the existing gate, not exact-budget compliance. The gate does not verify collision, movable parts, shader appearance, accessibility, story completeness, or exact seed counts.

Evidence: manifests and file inventory; actual GLB JSON/material/animation inspection; Godot imported scenes and runtime `GLTFDocument` loading; existing `contact_plants.png`, `contact_props.png`, `contact_environment.png`, `contact_vehicles.png`, and existing mug/pollination-kit/ice-scanner previews. **No new images or frames were rendered.** Old character contact sheets describe retired characters and were not used to approve v7. Style recommendations below are based on existing previews and material/runtime evidence, not a new GPU look review.

For every installed model named below, its game path is `game/assets/<category>/<ID>/<ID>.glb`, where the categories are `characters`, `plants`, `props`, `environment`, `vehicles`. Its finished production source is `production/models/final/<ID>/<ID>.glb`. `EN_Kit` maps to planned `EN_HabitatKit`; `EN_Malapert` maps to planned `EN_MalapertSummit`; `PL_ZeroSeedlings` maps to installed `PL_ZeroSeedlingTray`.

## Handbook §8.1 — characters

| Item | What exists | Remaining work / priority |
|---|---|---|
| CH_Kai | Anime coverall, 59,164 tris, 1.74 m, 65 bones, 44 clips; eyes/mouth, no brow layers; two patch layers | P0: integrate toon/face into player; visual hold/prop-contact sign-off |
| CH_Amara | Anime coverall, 58,533 tris, 1.72 m, 65 bones, 44 clips; five face layers and patches | P0: NPC face/runtime wiring; preserve teal shoulder tabs/name tape |
| CH_Mei | Anime coverall, 59,925 tris, 1.60 m, 68 bones including three ponytail bones; 44 clips | P0: face and springs in actual gameplay; visual hair/hand contacts |
| CH_Rafi | Anime coverall, 57,857 tris, 1.84 m, 65 bones, 44 clips; face/patch layers | P0: gameplay presentation; existing handoff notes a faint filled rectangle in PBR on upper back |
| CH_Ferreira | Anime coverall, 60,022 tris, 1.68 m, 65 bones, 44 clips; face/patch layers | P0: Earth screen presentation/outfit still distinct from the physical cast; physical arrival only 12 December; same PBR fill note as Rafi |
| Cadet variants | The four main v7 models already supply indoor navy coveralls. One installed `PR_Helmet`; old alternatives/rebuilds are intermediates/archive, not approved variants | EVA outfits and per-cadet fitted/role-striped helmets absent. Do not regenerate the already-existing indoor coveralls just because the old planned-assets row remains |
| Rao (A-61) | `production/concept/screen_v7/CH_Rao_screen.png` and matching `game/assets/ui/portraits/CH_Rao_screen.png`; anime portrait with headset/control-room background | P0: screen placement, caption/voice use. No separate bust, animated portrait or desk scene |
| Noor (A-09) | `screen_v7/CH_Noor_2034_portrait.png`, `CH_Noor_present_portrait.png`, both installed under `ui/portraits`; older realistic present-day portrait also remains under `concept/characters` | Use the new portraits after the CH05 identity reveal. No v7 rooftop scene/live talking portrait; CH08 live voice and rooftop staging pending |
| Voices only | Family and Engineer have one planned line each in `audio/vo_lines.csv` | No voice files. Noor/N. archive versus older live voice also not produced |

Both `CarryBox_pose` and `HoldRight_pose` are now present in all five source GLBs. A headless runtime check of each actual clip changed exactly 38 selected bones for BOX and 19 for RIGHT, leaving every other bone's local pose unchanged. Missing clips are independently tested with synthetic fixtures. Poses loop in the runtime motion library even though their names do not end in `_loop`.

## Handbook §8.2 — plants

All seven installed plant models are pre-v7 PBR assets. Their existing previews show realistic leaf detail, muted shading and textured containers. Try the world toon material first, with leaf readability and normal strength checked at gameplay distance; rebuild simplified silhouettes or containers only if that treatment is insufficient. None has a plant sway shader or animated growth/stress state installed.

| Item | Existing source/model | Missing / treatment |
|---|---|---|
| Alo seed, sprout, bud, first bloom, flowering, pollinated, pods, mature-dry; frost/thirst; sway | `PL_Alo_Bud`, `PL_Alo_Bloom`, `PL_Alo_Pods`; approved concepts under `concept/plants` | P0 seed/sprout, frost/thirst and sway. Bloom is available for first flower; independent flowering/pollinated states absent. Pods can be a mature-dry starting asset, but harvested/empty state is absent. No faces may be added |
| Tara same stages, green stem, own label | `PL_Tara_Bloom` only | P0 early reference-bay stages and readable own label; seed/sprout/bud/pollinated/pods/dry/stress variants missing |
| Pressed petal (A-30) | Planned `PR_PressedPetal` | Missing petal, dated sleeve and later display presentation |
| Descendants | Planned `PL_Descendants`; Alo/Tara meshes available to instance | Missing 12-position planting assembly, CH04 exact 7-purple/5-green sample and mixed final garden. Counts are not established by having a generic tray |
| Zero seedlings | `PL_ZeroSeedlingTray`, 15,000 tris, 0.50 m longest | Existing preview shows young seedlings without flowers; apply toon treatment. Needs annex placement and cold/story states; never substitute Alo bud here |
| Cotton seed, sprout, young, first-light alive | `PL_Cotton_Young`, 15,000 tris, 0.32 m | Seed/sprout and cassette missing; young mesh can serve the later alive state after staging. Keep it without bolls |
| Edible crop rack | `PL_CropRack`, 29,998 tris, 2.0 m | P0 material simplification; shiny detailed metal in old preview. Food/resource interaction and garden placement absent |

## Handbook §8.3 — environments

No complete location below exists as a playable scene or finished location GLB. The 14 environment rows in `manifest/planned_assets.csv` are plans, while Fabrication is only in the handbook. Reusable pieces have production/final and game copies; those do not close the location requirement.

| Location | Existing pieces / evidence | Missing |
|---|---|---|
| EN_Commons | `PR_MissionTable`, `PR_ControlConsole`, `PR_CrewSeat`, `PR_Mug`, `PR_CrewBunk`; Rao background portrait | **P0:** actual room, Earth screen, lockers, galley, four mugs then five, crew/NPC placement |
| EN_Kit / EN_HabitatKit | `EN_CorridorSegment` (2.6 m high) and `EN_ExteriorModule` (4 m longest); reuse sources | **P0:** modular walls/floors, 1.2 m usable doorways, lights, connectors, collision/navigation. Corridor's old padded/metal look needs simplification; exterior module is highly reflective foil |
| EN_ServiceRooms | `PR_BatteryJar`, `PR_PowerPanel`, `PR_ControlConsole`, `PR_OxygenUnit`, `PR_ManualGauge`, `PR_WaterValve` | **P0:** power/air rooms, corridor, heater controls, oxygen tank, diagnostic taps, pipes, garden spur, lamp locker and later F2/protected bus arrangement |
| EN_Garden | `PR_GrowthChamber`, `PR_Glovebox`, plant meshes/rack | **P0:** pressurised exterior chamber placement, operative viewing shutter, Tara indoor bay, paired care/calibration benches; later drying bench, planting rack, reserve store, lineage board |
| EN_SafeRoom | `PR_CrewSeat`, `PR_WaterWallPanel`, `PR_WaterValve`, `PR_HatchDoor`, `PR_SupplyBundles` | **P0:** five-seat room, four bundle slots, reservoir, roll-call board, response controls, archive player, seed-case latch |
| EN_Exterior | `EN_SolarMast` (12 m); `EN_ExteriorModule` | **P0:** courtyard, twin mast placement/function, lunar terrain/horizon, landing pad. Black sky, low Sun/hard shadows, no fog/wind/dust plumes |
| EN_EarthDesk | Rao's new screen portrait includes a control-room backdrop | **P0 screen integration:** no separate desk scene or animated screen; portrait can cover a static screen shot |
| EN_Airlock | `PR_HatchDoor`, `PR_Helmet`, corridor candidate | CH02+: double interlock, suit lockers, pressure cycle and sealed pollen pass-through absent |
| EN_ZeroAnnex | `PL_ZeroSeedlingTray`, `PR_AnnexDrum`, `PR_HatchDoor`, recorder candidate | CH03: floor cover/N.R. hatch, viewing port, cold annex, warm-side station, chart archive/map pouch absent. Drum includes regolith; keep out of clean rooms |
| EN_Garage | `VH_Rover`, cargo/seat/controller candidates | CH04+: bay, cargo rack, departure boards, landing camera and boarding path absent |
| EN_ColdTrap | `PR_SurveyBeacon`, `PR_IceScanner`, `PR_VaultCase`, `PR_SampleHolder` | CH04: road/ridge, three placed beacons, reference plate, sample points and vault shelf absent |
| EN_Fabrication | No dedicated finished asset or planned-manifest row | CH07: fabrication bench and route simulator absent |
| EN_RelayRoad | Rover and beacon meshes | CH08: five playable segments, R1/R2/R3 placement, marker-two service pad absent |
| EN_Malapert / EN_MalapertSummit | `PR_MalapertRelay` static assembly | CH08: summit terrain, separable controller/isolator, local/Earth controls and functional tether platform absent |
| EN_NoorRooftop | Old-style CS-15 shot masters; new Noor portrait | CH08: no v7 rooftop set/plate or integrated live-call scene |

## Handbook §8.4 — props, chapter by chapter

**Present** means a model imports, **partial** means a related shell/model exists but the named function/count/variant does not, and **missing** means no dedicated game asset or completed production final was found. Text in the story/manifest and a prop depicted inside a movie do not count as playable props. All existing non-character GLBs have zero animation clips; most are a single combined mesh. Movable shutters, needles, clamps, lids, individual brushes and seed wells need separable geometry or an explicitly built runtime counterpart.

### Chapter 1 — build these first

| Handbook item | Status and next step |
|---|---|
| Power console and battery jar (A-12) | Present `PR_PowerPanel`, `PR_ControlConsole`, `PR_BatteryJar`; partial live power readout/allocation controls |
| Air console and oxygen tank | Console shell and `PR_OxygenUnit` present; no dedicated tank or live air-system UI |
| Mast status panel | Missing live display; console shell is reusable |
| Charter and emergency card | Missing readable in-game documents/UI |
| Four crew name tokens | Missing tokens/labels and placement |
| Practice fault panel | Missing interactive fault variant; generic power panel exists |
| Seed packet “ALO / N.” (A-20) | `PR_SeedPacket` present; label intentionally blank, final Latin text/decal absent |
| Calibration bench | Missing |
| Moisture probe and reference sample | Missing; the ice scanner is not this instrument |
| Two planting cassettes (A-15) | Plants have modelled pots; two empty/plantable cassettes and their states missing |
| Kai hand light and equipment-board spot (A-34) | `PR_HandLight` present; pickup/offer attachment, actual light and board spot absent |
| Horizon/timeline display | Missing |
| Water panels, valve, reservoir (A-16) | `PR_WaterWallPanel` and `PR_WaterValve` present; reservoir, fluid/state display and usable controls missing |
| Four supply bundles (A-22) | `PR_SupplyBundles` is one cargo-group model; four selectable/placed bundles and shelter slots not built |
| Exposure instrument (A-29) | `PR_Dosimeter` present with separate Screen material surface; live readout still missing |
| Horticulture recorder (A-19) | `PR_Recorder2034` present; playback UI/audio/story triggers missing |
| Four mugs | `PR_Mug` present; instantiate four in Commons. Old preview shows lumpy lid/handle; clean the mesh for hand close-ups if toon shading cannot hide it |

### Chapter 2

| Handbook item | Status and next step |
|---|---|
| Origami paper bee | Planned `PR_PaperBee`; missing |
| Brushes A/B and closed pollen carrier | `PR_PollinationKit` depicts brushes and case; partial. Separate brushes, labels/grips and a closed/transfer state are missing |
| Transfer interlock | Missing as a usable airlock/pollen interaction |
| Nonliving flower model | Missing |
| Magnified flower diagrams | Missing |
| Seven-date care strip with bee stamps | Missing |
| Recorder service sticker over serial plate | Recorder shell present; readable layered sticker/serial evidence missing |
| 2034 trial-stage chart | Missing |
| Evidence board | Missing game UI/board |
| Earth-link transmit console | Console shell present; transmit/status UI missing |
| Trembling cup | Mug available; vibration/trigger absent |
| Displaced service cover | Missing |
| Brace-zone markers | Missing |

### Chapter 3

| Handbook item | Status and next step |
|---|---|
| Independent mechanical gauge (A-25) | `PR_ManualGauge` present; separate controllable needle/readout missing |
| Three diagnostic taps | Missing |
| Piping diagram | Missing |
| Isolation valves and clamp (A-26) | `PR_WaterValve`, `PR_RepairClamp` reusable; working isolation/clamping parts and pipe placement missing |
| Annex floor cover and N.R. hatch | Hatch shell present; floor cover, N.R. label and correct annex assembly missing |
| Camera viewing port | Missing |
| Growth chart | Missing |
| Map pouch | Missing |
| Maturity camera | Missing |
| Drying profile display | Missing |
| Contained harvest tray and counting wells | Missing; do not infer 42 counted seeds from pod geometry |
| Reserve container (30 seeds) | CH07 `PR_SeedCase` exists, but no distinct 30-seed harvest container/count logic |
| 12-position planting tray (A-28) | Missing descendant planting assembly; Zero seedlings tray is not a harvested/plantable substitute |

### Chapter 4

| Handbook item | Status and next step |
|---|---|
| Descendant rack and prediction notebook | Crop rack is reusable; exact 7 purple + 5 green sample/notebook missing |
| Pressurised three-seat rover (A-31) | `VH_Rover` exterior present; three-seat functional interior/boarding, storage and instruments not built |
| Consumables manifest | Missing |
| Route cards A/B/C | Missing |
| Three beacons (A-33) | `PR_SurveyBeacon` present; three route placements and controls missing |
| Ice scanner (A-32) | `PR_IceScanner` present; live display/probe feedback absent |
| Sealed sample holder (A-35) | `PR_SampleHolder` present; sampling interaction absent |
| Insulated vault case and 12-well inner container (A-37) | Closed `PR_VaultCase` present; lid/open state and 12 distinct specimen wells missing |
| Probe, sleeve and cradle | Missing separate extraction/protection components |
| Rover cargo mount | Missing usable attachment |
| Lid inscription | Missing readable final inscription |
| Fifth mug | Reuse `PR_Mug`; introduction/placement missing |
| Prepared locker | Missing |

### Chapter 5

| Handbook item | Status and next step |
|---|---|
| Relief lander on landing camera (A-39) | `VH_ReliefLander` and CS-08 old MP4s present; v7 camera presentation missing |
| Relief cargo crates | Reuse `PR_SupplyBundles`; arrangement/state missing |
| Replacement relay-controller crate | `PR_RelayController` present with crate/cable; movable contents and interaction absent |
| Atmosphere panel with handwritten correction | Console shell present; readable correction absent |
| Four primary records: relay fault report, greenhouse note, evacuation order, ascent manifest | Story text exists; four usable record pages/inspection UI missing |
| Impact-camera monitor frames (A-40) | Planned `PR_ImpactMonitor`; missing game frames/footage/UI |
| Panel-cleaning kit | Missing |
| Spur patch kit | Missing |
| Signed identity page | Missing usable signed page |
| Message composer | Missing |
| Cotton cassette | Young cotton mesh present; plantable cassette/seed stage absent |
| Dust Shield / Whipple bumper upgrades | Missing visible upgrade variants |

### Chapter 6

| Handbook item | Status and next step |
|---|---|
| Five segment cards and protected-service board | Missing |
| Guide-light branch and decorative floods | Missing placed controllable lights/fixtures |
| Protected-bus test panel and feeder F2 (A-42) | `PR_PowerPanel` shell present; separate switch, labels, allocation/test feedback missing |
| Filtered remote camera, monitor, labelled Earth-limb inset | Old CS-11 MP4 exists; camera asset, filtered feed and labelled conceptual overlay missing |
| Family audio-call UI | Missing, and Family VO file absent |
| Monitoring calendar | Missing |
| Active-region solar image | Missing game science image/display |

### Chapter 7

| Handbook item | Status and next step |
|---|---|
| Five shelter seat markers | `PR_CrewSeat` present; five placements/markers/roll call missing |
| Seed case, two 15-seed compartments | `PR_SeedCase` present; old top-view review records two compartments of vials. Exact 15+15 logical seeds/interactive compartments remain unverified |
| Water-wall valve diagram | Missing diagram; valve model exists |
| Local telemetry displays | Missing |
| Archive player | Recorder shell present; player UI, archive audio and timed captions absent |
| Damaged external uplink feedthrough (A-43) | `PR_UplinkFeedthrough` present; diagnosis/repair states absent |
| Local network diagnostic panel | Missing live panel; console reusable |
| Spare battery | Battery jar exists but is not a portable repeater spare; dedicated spare missing |
| Repeater site models | Beacon available; battery access, site assemblies and miniature/planning representations missing |
| Departure boards | Missing |

### Chapter 8

| Handbook item | Status and next step |
|---|---|
| Rover loadout: controller, battery spare, service diagram | Controller crate present; portable spare/diagram and verified mounted loadout missing |
| Route-planning console | Console shell present; actual route UI absent |
| Repeater battery bay | Missing |
| Malapert controller housing and isolator | Relay assembly and controller prop present; separable/serviceable housing and isolator absent |
| Local and Earth dish controls | Visible dish/antenna in `PR_MalapertRelay`; functional controls and separate-link verification UI absent |
| ALO42 data-check panel | Missing |
| Shared expedition photo (A-46) | No final in-game still; an old ending movie is not the collectible photo |
| MARS drawer post-credit still (A-47) | Missing; no CS-18 game file/master in the 23-shot set |

### All installed non-character GLBs: toon treatment or rebuild

These 44 models account for the entire installed non-character inventory. All import successfully. “Remodel parts” means retain useful geometry and make the named pieces functional; it is not an instruction to regenerate everything.

| Priority / treatment | Complete installed ID list | Reason |
|---|---|---|
| P0: toon first, simplify texture/normal detail | `PL_Alo_Bud`, `PL_Alo_Bloom`, `PL_Tara_Bloom`, `PL_CropRack`, `PR_BatteryJar`, `PR_CrewBunk`, `PR_CrewSeat`, `PR_HandLight`, `PR_OxygenUnit`, `PR_SupplyBundles`, `PR_SeedPacket`, `EN_SolarMast` | Existing PBR look; silhouettes mostly reusable. Missing gameplay/data/variants remain as listed above |
| P0: toon plus usable parts/UI | `PR_ControlConsole`, `PR_PowerPanel`, `PR_MissionTable`, `PR_Recorder2034`, `PR_Dosimeter`, `PR_GrowthChamber`, `PR_HatchDoor`, `PR_WaterValve`, `PR_WaterWallPanel` | Live screens, operative shutter/hatch/valve and water state are needed. Dosimeter already has a Screen material; others need appropriate screen separation/overlays |
| P0: likely mesh cleanup/rebuild of close-up parts | `PR_Mug`, `EN_CorridorSegment`, `EN_ExteriorModule` | Mug lid/handle visibly irregular; corridor is a noisy combined padded/metal tube rather than a habitat kit; exterior module is highly reflective foil. Rebuild the modular room kit; do not stretch these into whole rooms |
| Later: toon first | `PL_Alo_Pods`, `PL_Cotton_Young`, `PL_ZeroSeedlingTray`, `PR_CrewSeat` (reuse), `PR_AnnexDrum`, `PR_SampleHolder`, `PR_UplinkFeedthrough`, `VH_ReliefLander`, `VH_ZeroAscent` | Old PBR/photoreal surface detail. Drum includes regolith. Ascent vehicle is archive dressing only |
| Later: toon plus functional parts/variants | `PR_Glovebox`, `PR_Helmet`, `PR_PollinationKit`, `PR_ManualGauge`, `PR_RepairClamp`, `PR_IceScanner`, `PR_RelayController`, `PR_SeedCase`, `PR_VaultCase`, `PR_SurveyBeacon`, `PR_MalapertRelay`, `VH_Rover` | Gloves/interlocks, fitted helmet variants, separate brushes/needle/clamp/lids/seed wells, actual displays, battery/controller access and a three-seat rover interior need modelling/integration |

The existing toon converter does not replace baked text, split a combined mesh, create interaction geometry or make fake glass transparent. Its opaque shaders now deliberately leave transparent source materials alone, including the new sleeve decals. A matching toon transparency pass and a visual lighting check are still needed for those surfaces; the current helper is not a universal material converter.

## Handbook §8.5 — animation, UI and audio

| Requirement | Present | Missing / readiness |
|---|---|---|
| Locomotion | Walk/Run, basic variants, Sprint, Idle/IdleAlt/Breathe/LookAround, six turn clips, RunToWalk, SprintStop, SitIdle/SitDown/StandUp; player/camera/foot-placement runtime | Brace clip absent. Runtime tests pass, but touchdown/toe-off scuff quality limits remain. Do not mark all animation finished from clip count alone |
| Carry/holds | Legacy full-body `Carry_loop`; new `CarryBox_pose`/`HoldRight_pose`; NONE/BOX/RIGHT API, arm filters, 0.2 s fades, BOX run-speed cap | No held-item spawn/attachment or scene-specific hand-contact offsets were requested/added. Visual contact review still required |
| Care hands | Pollinate, Water, Inspect, PickUp, KneelStand, six Hand poses | Exact planting, seed counting, petal sleeving and scanner/brush/glove-port contacts are not authored/connected as specific interactions |
| Repair and vehicle | Repair, Type, Push, OpenDoor | Valve turning, clamp/isolate/connector/battery-swap contacts, rover entry and tether animation absent as dedicated integrated beats |
| Gestures | Wave, Agree, Cheer, Drink, Talk, Listen | Offer lamp, place mug, roll-call response, grief pause and group-photo blocking still need authored use/contacts |
| HUD and Mission Table | Developer overlays/review controls only | Gameplay HUD, forecast/preview and planning UI missing |
| Decision review, journal, evidence board, debrief | Story/design specifications only | All missing; journal needs Mission/People/Garden/Evidence/Science sections |
| Class role cards | Design requirement | Printable finished cards missing |
| Settings/accessibility | Input bindings, captions in SFX plan | Settings, caption runtime, 150% text, timer-free mode, and icons paired with English words still missing |
| Voices | 385 text lines; lip-sync/atlas runtimes and one timing fixture | Zero recorded files. Cast, Rao, Noor archive/live, Family and Engineer voices all unproduced. Preserve full story via captions |
| SFX | 35 rows with captions where specified | Zero files. Fans/valves/water/doors/suit/rover/alarms all outstanding; exterior sound must remain suit/contact/cabin only |
| Score | CUE-01 through CUE-12 defined | Zero audio files. Prioritise CUE-01–04; do not rely on the 134 seconds of silent old movie shots for an audio-complete slice |

The 23 `production/cutscenes/masters/*.mp4` files are old-style footage, with prompts explicitly saying stylised-realistic and old suits. They need v7 replacements or in-engine restaging. No new movie was generated or converted. CS-01-B lip-sync remains open; CS-18 MARS is absent. The handbook's Theora encoder warning was not re-verified by installing or converting anything.

## Code review and changes made

- **Player hold layer:** `PlayerAnimation.Hold.NONE/BOX/RIGHT`, forwarded by `PlayerController.set_hold(mode)`. Two filtered Blend2 layers sit after the existing action/turn output. Both arm chains contain shoulder, upper arm, forearm, hand and Thumb/Index/Middle/Ring/Pinky joints 1–3. BOX includes both sides; RIGHT only the right side. Two independent weights crossfade in/out over 0.2 s, including mode changes; no method snaps a weight. Missing clips use a valid zero-weight idle node. Runtime copies of pose clips are looped. BOX caps the target speed at run while retaining the controller's existing smooth deceleration. H cycles modes in the locomotion test scene's script, with a label.
- **Patch cleanup:** the old rasterizer accepted a 5% triangle overshoot, upper-body selection used triangle centroids, and all unoccupied UV padding was eligible. These could include protected areas. Safe garment triangles now require all vertices below the neck/above hips and no head/neck/hand/ponytail/hair skin weights; protected UV coverage wins, including at auxiliary-map resolution. Green must connect to a red disc. Bright teal, pale name tape, skin-like colours, isolated shaded teal and protected UVs are excluded from mask expansion. Green-only ambiguous placeholders remain for review.
- **Patch fill:** old seam smoothing rewrote donor pixels, and sparse/empty normal/roughness regions could fall back to albedo fabric RGB. Fill now writes only the hole, samples each map independently, and fails before export when no valid donor exists. Empty/degenerate garment areas are handled. Only images connected to the Normal/Roughness inputs are included, rather than every texture node. Normal/packed-map channels still use local map samples; alpha stays unchanged. `dilate`, `nb_sum`, `pull_push` and `blobs` were retained and tested on edge/odd/single-axis cases.
- **Toon ramp:** Claude's light-only calculation is correct; no ALBEDO multiplication was reintroduced. The common ramp is used by character, world and face. A zero-softness setting previously gave equal `smoothstep` edges; it now has a tiny nonzero width. Reference: [Godot 4.7 spatial shader light built-ins](https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/spatial_shader.html#light-built-ins).
- **Outline:** uses the normal matrix for nonuniform transforms and clip-space viewport-height extrusion, including orthographic cameras. A zero screen-facing normal no longer gets an arbitrary diagonal offset. Depth is moved behind the surface without shifting its screen coordinates. GPU appearance has not been rendered for approval.
- **Materials:** scalar metallic=1 was still suppressing diffuse light despite the texture-metal fix. These diffuse toon materials now use metallic=0 consistently. Disabled normal maps stay disabled. Transparent materials are preserved to avoid turning sleeve-patch margins opaque; a dedicated toon transparent pass is future work.
- **FaceAtlas:** repeated application preserves the atlas/material and now also respects a changed mirror setting and the current speech mouth. A source material with no texture gets a valid fallback. Face and character use the same shadow tint. `mirror_left_eye=false` is correct for the side-specific v7 images. Top-left, row-major atlas addressing agrees with `make_toon_face_atlas.py`; the shader row formula was retained.

The patch code was **not run to export any character**. It cannot retrospectively undo any damage already baked into the installed GLBs. Its new masks are conservative heuristics, not a semantic image proof: review a mask before using it on a new design, especially if protected details share flag colours/UVs. Exact material appearance, face seams and sleeve-patch lighting still need a later visual check.

## Tests, warnings and reproducibility

| Check | Result |
|---|---|
| `test_player_controller.gd` (existing v4 fixture) | **PASS: 92 checks**; original checks retained, 43 hold checks added |
| Same test, `-- --glb=res://assets/characters/CH_Kai/CH_Kai.glb` | **PASS: 94 checks** including v7 sprint/stop |
| `test_face_atlas.gd` | **PASS: 17 checks** |
| `test_face_expression.gd` | **PASS: 65 checks**, v4 Kai morph/head-accent fixture |
| `test_hair_springs.gd` | **PASS: 5 checks** |
| `test_lip_sync.gd` | **PASS: 15 checks** |
| `test_review_scene.gd` | **PASS: 447 checks**, all five v4 fixtures |
| `test_toon_materials.gd` | **PASS: 12 checks** |
| `production/tools/test_add_patches.py` | **PASS**, array-only raster/mask/interpolation/map-link regressions |
| `verify_assets.gd` + existing gate predicates | **49/49 loaded and passing** |
| Additional read-only probe | All five actual v7 BOX/RIGHT clips work through the production runtime loader; all three portraits load; **0 failures** |

Commands used (each test run separately):

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game -s res://tools/<test>.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game --fixed-fps 60 -s res://tools/test_player_controller.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game --fixed-fps 60 -s res://tools/test_player_controller.gd -- --glb=res://assets/characters/CH_Kai/CH_Kai.glb
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game -s res://tools/verify_assets.gd
python3 production/tools/test_add_patches.py
```

Logs were directed to `/private/tmp/lla-codex-tests/` with `--log-file`; the separate v7 player log is `/tmp/lla-player-v7.log`. They are temporary local evidence, not required project assets.

Warnings / limits, in priority order:

1. **No playable Chapter 1 integration or v7 visual sign-off.** Headless tests do not establish GPU rendering quality, frame rate, cloth/hair appearance, hand contacts, or accessibility.
2. **Pre-existing contact quality limits remain.** The normal player suite explicitly reports touchdown/toe-off motion above 0.20 m/s; it passes the planted-foot checks. On v7 Kai, reported maximum near-floor surface speeds were 9.66 m/s walking, 0.54 m/s running and 9.19 m/s during run-to-walk. These include transition/contact classification spikes. `--strict-contact` was not passed and is not claimed to pass.
3. **Loader naming differs.** The editor's imported PackedScene strips `_loop` (e.g. `Walk_loop` becomes `Walk`) and sets the loop mode. The current player and character look-dev use runtime `GLTFDocument`, which preserves names. An initial audit probe using PackedScene directly could not initialise `LocomotionClips`; rerunning through the actual production loader passed all five. Do not swap loaders without normalising clip names or adjusting the motion contract.
4. **Legacy tests depend on local v4 scratch files.** FaceExpression and review tests are deliberately v4 morph-rig checks; a pass there does not prove v7 atlas integration. Player v7 and actual hold clips were checked separately. These fixture paths are not portable CI assets.
5. **macOS certificate diagnostic:** headless Godot emitted `Condition "ret != noErr" is true` from `get_system_ca_certificates (platform/macos/os_macos.mm:1035)`. All required scripts still exited 0; no asset import error accompanied it.
6. **Expected missing-cue warning:** LipSync deliberately loads `res://tools/test_data/does_not_exist.json` to test graceful failure.
7. **Blender integration check unavailable:** an additional read-only in-memory patch probe was attempted with Blender 5.2.2, but Blender exited **139** during startup after `ARCH_CACHE_LINE_SIZE != Arch_ObtainCacheLineSize()` and wrote its crash log. The probe did not reach the model import or paint function. Array regressions pass; Blender end-to-end execution of the revised cleanup is still unverified. No render/export was requested by the probe.
8. **Registry/document drift:** `ASSET_REGISTRY.csv` still describes the old 24-bone/25-clip cast and older heights; `game/assets/README.md` says 78 bones. The current character manifest and actual models are 65/68 bones, 44 clips. The planned-assets CSV contains 26 rows, not the historical “29”; its cadet indoor-coverall and portrait rows now overlap delivered assets. Historical visual reviews retain old approvals. The handbook's latest status and this audit distinguish current availability from historical milestones.
