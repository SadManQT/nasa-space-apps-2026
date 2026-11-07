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
  opening). The source fix is board task **M3-102** (rebuild the module with an open back, then remove the runtime
  opening).
- **Ferreira's caption ran through the handrail.** The garden's Earth console sat so low that the caption under the
  screen crossed the 1.0 m kit handrail and the console ledge. Screen, title and focus point rise 0.18 m, the ledge
  drops below the rail.
- **Unreadable titles.** "ALO AND TARA" (lineage board) and "BOTANICAL BENCH" (bench front) were navy text on navy;
  now the light label colour used on the airlock panels.
- Evidence cameras for the evidence board, playback screen, growth record and glove ports now stand where the player
  interacts. One duplicated doc comment in `chapter1_campaign.gd` removed.

No story text, puzzle numbers, mission rules or asset files changed; no generation or credits.

## Verification

- `test_chapter2_rooms.gd` headless: **CHAPTER 2 ROOMS RESULT: PASS (3434 checks, 0 failures)** (3,208 before this
  round; the new station, footprint and window checks each failed on the old data first).
- Windowed capture `bash production/qa/evidence/M3-2R_capture.sh` (run from this session, window on top):
  `CHAPTER 2 ROOMS CAPTURE RESULT: PASS (50 checks, 0 failures)`, 25 fresh PNGs, all inspected. Frame times with the
  cast (`M3-2R_runtime.txt`): p50 16.69–16.71 ms in all four rooms (vsync 60 Hz), p95 17.5–20.2 ms; draw calls
  347 / 367 / 447 / 385.
- Full runner `GODOT=.../godot_gated game/tools/run_tests.sh` (exit 0), saved in `M3-2R_tests.txt`: **56/56 suites passed**.

## For Sadman's eye

- `M3-2R_S04_alo_glove_ports.png`: Alo through the pressure window. The two bright ovals are ceiling lights mirrored
  in the approved glass (roughness 0.05); M3-102 can soften that when it rebuilds the module.
- `M3-2R_S07_mission_table.png` / `M3-2R_S07_bee_and_recorder.png`: the recorder now stands on the table's central
  display. If that display should stay clear, the alternative is a small service cart beside the table.
- `M3-2R_S01_earth_console_tara.png`: the raised garden console with Ferreira's caption.
- `M3-2R_S12_red_warning.png` against `M3-2R_CH03_S01_same_warning.png` for the chapter join.

Evidence: `M3-2R_S01_earth_console_tara.png`, `M3-2R_S01_paired_identity_cards.png`, `M3-2R_S01_player.png`,
`M3-2R_S02_botanical_bench.png`, `M3-2R_S02_practice_model_close.png`, `M3-2R_S03_airlock_vestibule.png`,
`M3-2R_S03_route_and_kai_line.png`, `M3-2R_S03_player.png`, `M3-2R_S04_alo_glove_ports.png`,
`M3-2R_S04_carrier_microscope.png`, `M3-2R_S05_care_and_route_record.png`, `M3-2R_S06_seven_dates_prediction.png`,
`M3-2R_S06_seed_tray_bench.png`, `M3-2R_S07_mission_table.png`, `M3-2R_S07_bee_and_recorder.png`,
`M3-2R_S08_recorder_bench.png`, `M3-2R_S08_evidence_board.png`, `M3-2R_S09_reconstruction.png`,
`M3-2R_S10_playback_transcripts.png`, `M3-2R_S10_inference_board.png`, `M3-2R_S11_evidence_package.png`,
`M3-2R_S11_cup_reply_pending.png`, `M3-2R_S12_brace_zone.png`, `M3-2R_S12_red_warning.png`,
`M3-2R_CH03_S01_same_warning.png`, `M3-2R_runtime.txt`, `M3-2R_capture.txt`, `M3-2R_import.txt`, `M3-2R_tests.txt`.
