# M3-2R Chapter 2 rooms — review notes

## Scope (ported 6 Nov, Sadman/night-codex-main)

The parked `origin/night/M3-2R` work is ported onto current main (no task file had changed on main since the parked
base). All twelve Chapter 2 scenes are staged in their STORY_FULL rooms: garden (LOC-03: S01, S02, S06), the approved
8 × 4 m M3-2A airlock (LOC-05: S03–S05), the Commons (LOC-01: S07, S11, S12) and the recorder service bench
(LOC-02: S08–S10), with the CH02 → CH03 join in LOC-02. The room README (`game/resources/campaign/rooms/README.md`)
lists the physical story carriers per scene. Collision, navigation, practical lighting, the running interlock,
authored stations, saved-choice echoes (D4, D5) and the old-checkpoint boundary restore reuse the existing services.

## Fix round — 7 November 2026 (Sadman/night-claude2, Claude Opus 5.5)

What stopped the task: the host capture (`M3-2R_capture.sh`) timed out with no screenshots. Two causes, both fixed:

1. The script's 1,200 s watchdog counted the wait for a slot in the two-slot Godot gate, and the windowed pass also
   re-ran every room check (about two minutes of frames). Now the `--capture` pass only renders the 25 views and four
   frame probes (the checks stay in the headless suite), each Godot's limits start when its banner appears, a pass
   with no new progress line for 150 s is stack-sampled and retried once, and the whole script stays inside the night
   shift's 2,400 s limit.
2. The real hang: macOS reports the window covered (another worker's capture window at the same position, or the lock
   screen), Godot stops drawing, and `await RenderingServer.frame_post_draw` never returns. Reproduced on 7 Nov
   (attempt stalled at "staging EX-CH02-S03"; the sampled main loop sat idle in Godot's frame-delay sleep) and confirmed
   with a minimized window (0 draws in 60 frames). The capture now waits half a second for a real draw, then renders
   every viewport itself with `RenderingServer.force_draw(false)`; frame timings are only taken while the window is
   really drawing and are written as "not measured" otherwise.

Defects the screenshots then exposed, fixed in room data with regression checks that fail on the old layout:

- **Crew stood on the stations.** Crew bodies block the player (collision layer 2) and the interaction ray, yet in
  S03–S05 and S08–S10 crew anchors stood 0.25–0.5 m from the approach of a station the scene uses (e.g. Amara on the
  carrier pass-through, Kai on the route diagram, Amara in front of the evidence board) and blocked several
  evidence cameras. Eighteen anchors moved to the nearest clear spot. New check: every crew anchor keeps 0.8 m from each
  station approach the scene uses and 0.4 m from its line to the station (the S12 brace zone, where all four stand, is
  exempt).
- **S07 props hung off the mission table.** The layout assumed the table's square 2.1 m collision box; the visible top
  is a ring (r 0.42–0.86 m) round a recessed display. The recorder overhung by about 0.3 m, the life-cycle sheet, care
  strip and seed tray by 0.1–0.2 m. Now the life-cycle record is centred on the near side, the care strip and the clean
  tray beside it on the far side, and the recorder stands on the central display with its HORT-01 sticker toward the
  player and the paper bee against its front (clue 4). New check: anything resting on furniture is ray-tested against
  trimesh copies of the visible meshes at nine points 1.5 cm in from its edges (seam-tolerant to 1 cm).
- **Alo was invisible behind the glove ports.** The pot sat below the pressure window's sightline, and the approved
  `EN_Airlock_GlovePort` GLB closes its back with a 1.0 × 2.6 m grey plate behind the window (kit window-frame
  reuse), so the window showed paint. Alo now stands on a 0.2 m stand at the back of the sealed chamber, and
  `HabitatRoomBuilder.open_window_back` drops that one plate from LOC-05's placed copy (the GLB is unchanged). New
  check: a 1.6 m eye at the glove-port station sees the top of Alo's flowers through glass only (fails without the
  opening). The source fix is board task **M3-104** (filed as M3-102 on this branch; main had already used that id; rebuild the module with an open back, then remove the runtime
  opening).
- **Ferreira's caption ran through the handrail.** The garden's Earth console sat so low that the caption under the
  screen crossed the 1.0 m kit handrail and the console ledge. Screen, title and focus point rise 0.18 m, the ledge
  drops below the rail.
- **Unreadable titles.** "ALO AND TARA" (lineage board) and "BOTANICAL BENCH" (bench front) were navy text on navy;
  now the light label colour used on the airlock panels.
- Evidence cameras for the evidence board, playback screen, growth record and glove ports now stand where the player
  interacts. (One duplicated doc comment in `chapter1_campaign.gd` was removed here; that file is Atik's and stays as
  on main, see M3-103.)

No story text, puzzle numbers, mission rules or asset files changed; no generation or credits.

## Landing round — 7 November 2026 (Sadman/claude, Claude Opus 5.5)

The parked commit (310b817) no longer rebased: main had gained M1-84 (Care Round hooks, named mugs, the `moments`
argument), M1-82 (exterior terrain staging) and M3-102 (anti-aliasing) in the same files. It was merged by hand;
the scratch `.night_merge/` files and the branch's board files were dropped.

- **Every chapter's entries are kept.** `_STAGING_LISTS` has the branch's `models` and main's `care_round`; the
  README keeps the Chapter 1 hooks, the Chapter 6/7 table, Chapter 2 and the exterior terrain sections; LOC-01 and
  LOC-03 carry `ch01_named_mugs` / `ch01_care_round` beside the Chapter 2, 5, 6 and 7 layers.
- **Atik's files stay as on main** (folder ownership, MASTER_PLAN §7): `chapter1_campaign.gd` (station binding,
  choices to crew placement), `load_preparation.gd` (LOC-05 scene), `route_navigation.gd` (the
  `door_commons_airlock` boundary) and the two campaign tests. They are board task **M3-103** for Atik, with the
  exact changes. `world_route.gd` is Sadman's and lands: it now gives older checkpoints the vestibule door only once
  `RouteNavigation` defines it, so it is correct before and after M3-103.
- **`test_chapter2_rooms.gd` stands on its own:** it builds LOC-05 from `airlock.tscn` itself and checks reachability
  through `RoomContract` (LOC-05 shares `door_commons_airlock` with the Commons and `airlock_exterior` with the
  surface); the loader, WorldRoute-state and traversal checks moved to M3-103's acceptance.
- **LOC-05 is turned half a revolution** (`"shell_yaw_deg": 180`, `HabitatRoomBuilder.build_airlock`): the garden wall
  is now the north wall, the Commons door the east wall and the surface hatch the west wall. With the garden wall on
  +Z, main's `test_chapter1_campaign_flow` (Atik's) failed at EX-CH02-S03 (`check_space_weather`): it stands the
  player 1 m on +Z from each target, which put them outside the 4 m deep vestibule. Every other room's equipment
  wall is approached from +Z, so the vestibule now follows that convention; all positions, yaws, enclosures,
  portals, walk probes and evidence views in `LOC-05.json` and the `RoomContract` fallback were turned together
  (x → −x, z → −z, yaw + 180°). The campaign flow suite passes unchanged (448 checks).
- **Named mugs and the S11 cup.** With CH01-MUGS-NAMED recorded, S11–S12 would have shown Amara's named mug and the
  nameless "reply cup" 3 cm apart. The cup is the table's own mug, moved: Amara's named mug moves to the pending-reply
  indicator in S11–S12 and rattles in S12 (`by_scene` in `ch01_named_mugs`); the nameless cup is its own layer
  (`ch02_reply_cup`) shown only while the mugs are nameless (new `"unless_moment"` gate in `RoomContract.staging_for`).
  New check: four mugs, exactly one at the indicator, none sharing a spot, with and without the moment.
- **The S12 and CH03-S01 warnings are now the same warning** (review point 2; changed). S12 showed a small red square
  and 1.4 cm type on a panel crossed by the 1.0 m handrail; CH03-S01 showed different words ("OXYGEN TANK PRESSURE
  WARNING") on a screen floating 15 cm above and in front of PR_OxygenUnit. Canon says "The oxygen-tank symbol is
  red" and doc 24 §2.9 "the same red pressure warning". Both displays now carry the same layout: ATMOSPHERE, OXYGEN
  SUPPLY · OK, CARBON DIOXIDE · OK and the red oxygen-tank symbol with TANK PRESSURE · WARNING, type size 3.2 cm. The
  Commons panel is raised clear of the rail; the air-console screen stands on the unit's visible top (1.917 m, front
  edge z −1.55, measured from its mesh; its AABB is larger). New checks: same rows word for word, tank symbol red on
  both, not red before the quake.
- **The recorder stays on the Mission Table's central display** (review point 1; kept). Canon ties the three together
  ("Rafi places the paper bee beside the finished record. Its folded wing brushes the horticulture recorder"): a
  service cart would separate the recorder from the bee and the record. The ring top is 0.44 m wide and the recorder
  (0.6 m tall, a cased unit with a carrying handle) does not fit on it; the table display is not used in S07 (the
  life-cycle cards are printed and the display is dark in the screenshots); and setting a cased unit down in the middle of the table reads naturally.
- **Other screenshot fixes:** the S11 evidence-package type was 1.6–1.8 cm and unreadable from the station (now
  2.8 cm); the LOC-05 overview camera had Kai's face in the corner (now from the Commons-door end).

Left as they are, for Sadman's eye: the two bright ovals in the glove-port glass (approved glass, roughness 0.05;
in M3-104's prompt); small type on the airlock route board, the space-weather screen and the evidence board cards
(1.0–1.7 cm, readable only from close by); the practice flower's ANTHER and STIGMA tags float beside the
model without leader lines.

## Verification

Night fix round (7 Nov, before the landing): `test_chapter2_rooms` 3,434 checks PASS, capture PASS with frame times
p50 16.69–16.71 ms, full runner 56/56.

Landing round, on the rebased tree (main 89b6237 + this change):

- `game/tools/run_tests.sh chapter2_rooms`: **CHAPTER 2 ROOMS RESULT: PASS (3510 checks, 0 failures)** (named-cup and
  same-warning checks added; the loader and WorldRoute checks moved to M3-103).
- `game/tools/run_tests.sh chapter1_campaign_flow` (Atik's, unchanged): PASS (448 checks); it failed at
  EX-CH02-S03 `check_space_weather` before LOC-05 was turned.
- Full runner `GODOT=.../godot_gated game/tools/run_tests.sh`, saved in `M3-2R_tests.txt`: **60/60 suites passed (chapter1_campaign_flow 448, chapter2_rooms 3510, performance_runtime 537 checks)**.
- Windowed capture `bash production/qa/evidence/M3-2R_capture.sh`: `CHAPTER 2 ROOMS CAPTURE RESULT: PASS (50 checks, 0
  failures)`, 25 fresh PNGs, every one inspected. In the final pass another session's capture window and the user's
  own apps covered the Godot window, so the test rendered each frame itself and wrote the timings as not measured
  (`M3-2R_runtime.txt`); an earlier pass the same session with the window drawing measured p50 16.67–16.86 ms in all
  four rooms with the cast, p95 17.6–20.0 ms (one 43.5 ms p95 spike in the Commons), draw calls 347 / 378 / 447 / 385
  (`M3-2R_capture_output.txt`).

## Works only once Atik's M3-103 lands

- LOC-05 is preloaded with the loading card (until then the campaign builds it as a bare `CampaignRoom` from
  `LOC-05.json`: same room, GLBs loaded on the main thread when EX-CH02-S03 starts).
- The Commons-to-vestibule door opens (until then `door_commons_airlock` has no WorldRoute state and reads closed;
  scene changes are authored viewpoint cuts, so no scene is blocked).
- D4's prediction card and D5's voice card appear in the played campaign, on Continue and across CH02 -> CH03, and
  M1-84's named mugs (until then the campaign passes no choices or moments to `CampaignCrew.place`; the room data and
  `test_chapter2_rooms` already show both echoes when the choices are passed).
- Mission actions highlight their authored room stations (until then the gate catalogue's room-level focus is used;
  every action still has a reachable target, as the campaign flow suite shows).

## For Sadman's eye

- `M3-2R_S12_red_warning.png` against `M3-2R_CH03_S01_same_warning.png`: now the same panel and the red oxygen-tank
  symbol on both (changed, see the landing round).
- `M3-2R_S07_mission_table.png` / `M3-2R_S07_bee_and_recorder.png`: the recorder stays on the table's central display
  (kept, see the landing round).
- `M3-2R_S03_airlock_vestibule.png` / `M3-2R_S03_player.png`: the vestibule turned half a revolution (garden wall
  north, Commons door east).
- `M3-2R_S04_alo_glove_ports.png` / `M3-2R_S05_care_and_route_record.png`: the two bright ovals in the approved glass
  (roughness 0.05); M3-104 can soften them when it rebuilds the module.
- `M3-2R_S01_earth_console_tara.png`: the raised garden console with Ferreira's caption; the small cyan title above it
  is hard to read.

Evidence: `M3-2R_S01_earth_console_tara.png`, `M3-2R_S01_paired_identity_cards.png`, `M3-2R_S01_player.png`,
`M3-2R_S02_botanical_bench.png`, `M3-2R_S02_practice_model_close.png`, `M3-2R_S03_airlock_vestibule.png`,
`M3-2R_S03_route_and_kai_line.png`, `M3-2R_S03_player.png`, `M3-2R_S04_alo_glove_ports.png`,
`M3-2R_S04_carrier_microscope.png`, `M3-2R_S05_care_and_route_record.png`, `M3-2R_S06_seven_dates_prediction.png`,
`M3-2R_S06_seed_tray_bench.png`, `M3-2R_S07_mission_table.png`, `M3-2R_S07_bee_and_recorder.png`,
`M3-2R_S08_recorder_bench.png`, `M3-2R_S08_evidence_board.png`, `M3-2R_S09_reconstruction.png`,
`M3-2R_S10_playback_transcripts.png`, `M3-2R_S10_inference_board.png`, `M3-2R_S11_evidence_package.png`,
`M3-2R_S11_cup_reply_pending.png`, `M3-2R_S12_brace_zone.png`, `M3-2R_S12_red_warning.png`,
`M3-2R_CH03_S01_same_warning.png`, `M3-2R_runtime.txt`, `M3-2R_capture.txt`, `M3-2R_capture_output.txt`, `M3-2R_import.txt`, `M3-2R_tests.txt`.
