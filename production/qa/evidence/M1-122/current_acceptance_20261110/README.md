# M1-122 / M1-123 - frozen Windows acceptance recheck

**Newer post-sync check atf328c0c5 plus the approved pilot patch:** Garden2/2 passes; loading615/5 still fails after the published HUD repair (52.109,80.204,64.977,59.503,56.240ms for title/campaign/Garden/cast/terrain). [Current raw evidence](post_sync_f328/run.json). These five current intervals supersede the nine older measurements below for the present blocker. Newer room/handoff/text/profile repairs are also published in the [integration owner's handoff](../../M1-125_117_gate_2026-11-10/README.md); the20frozen failures below are not automatically current.


10 November 2026, Tanvir. Scope: M1-122, M1-123 and M1-85 only. Delivered collision and actual-input source is preserved. This report records a completed frozen test invocation; it does not certify later integrated source.

Source `daa014145922e2646027140f3bd34c53a0afe3cb`, game tree `1c3a0dd3517226d7c9c3a79138249593e4955d2a`. Windows 11 / Core Ultra 5 226V / Intel Arc 130V, Godot 4.7.2 official.ed1daf0bf. Engine hash, tracked-file hashes and exact commands are in [run.json](run.json).

| Mandatory invocation | Result |
|---|---|
| Garden focused | 2/2: collision19/0, actual movement54/0 |
| Habitat rooms focused | 360/0,1/1 |
| Comms focused | 45/0,1/1 |
| P01 inputs focused | 319/0,1/1 |
| Full runner | **97/117 suites passed**, exit1, all117 unique suites reported; no outer timeout |

The complete full run took3836.995 seconds. The invocation used `SUITE_TIMEOUT=1500` for the known long text walk and a separate10800-second whole-collection cap. One already-script-failed UI child was externally stopped at the normal300-second bound: its null `.visible` error, exact PID/creation/command rechecks, raw pre-stop log and confirmed process-tree exit are retained in [ui_watchdog.json](ui_watchdog.json) and [raw error](ui_script_error_before_termination.txt). This forced termination is not a native crash or a normal runner timeout. The subsequently published runner supports `PLAYER_TEXT_TIMEOUT` and stops fatal-script children itself; that newer runner was not substituted into this running snapshot.

The starting checkout preserved a generated Steel_Normal import-sidecar difference and the pre-existing project blank-line edit. Across the collection,62 tracked `.import` sidecars changed through engine generation; no gameplay/test/project source hash changed. This is verification of that disclosed local import state, not pristine committed import settings. The source/save guards confirm the original player save is unchanged; no raw save, profile or cache is published. [Complete log audit](log_audit.json) counts3567 generic ERROR lines and4 SCRIPT ERROR lines separately from20 failed suites. [Artifact manifest](artifacts.json) verifies141 copied logs/traces/manifests byte for byte.

Comms45/0 and P01 inputs319/0 also pass inside this full run. Their old reporting/baseline failures are superseded. Player text finished with18162 checks/3026 failures, not a timeout. Performance is a fresh Windows observation545/9 (standard checks without opt-in trace retention): Kai52.905, Amara56.248, Mei74.598, Rafi64.726, title97.908, campaign173.179, Garden113.439, full cast94.215 and terrain81.581ms against the unchanged<50ms limit. These measurements do not establish a timing cause or fix. The separate Atik M4 results remain host/source-specific.

## Subsequent published repairs

After this frozen invocation, commits5ad5017e andaa632b28 publish nine successful focused suites on the reporter's Windows Ryzen7/RTX4060 host with Godot4.7. These are newer counter-evidence to the corresponding frozen failures, not a fresh full/laptop pass:

- [Chapter prerequisites](../../M1-125_117_gate_2026-11-10/focused_chapters/provenance.json): CH06 missions116/0, CH08 missions132/0, Chapter6 puzzles59/0 and Chapter8 puzzles110/0.
- [UI/prerequisites](../../M1-125_117_gate_2026-11-10/focused_ui/provenance.json): game feel102/0, Chapter1 UI42/0, Journal322/0, outpost63/0 and main-menu focus/input170/0.

Do not report those nine earlier failures as still present solely from this snapshot. Source and active exact-file reservations must be rechecked before resuming acceptance. Current campaign/progression integration is reserved by Ramim/M3-64; Asif retains main and route/bridge reservations. Shared room/staging and performance-test prerequisite files are reserved by Ramim/M1-125. Upgrade/text consumers have Ramim's explicit reservations. Atik/M1-68 owns the actual timing investigation. These are real active reservations and technical dependencies, not historical folder-owner restrictions.

## Owned movement finding

The full collision test passes19/0. The movement test is54/2 here despite the earlier focused54/0. Only BLOOM keyboard's center/grounded-at-center assertions fail. [Actual trace](full/logs/movement_trace.json) records floor-only contact, free/unlocked movement and braking drift: final-leg position[-0.00630015,0.00083865,0.75011706] is about0.250196m from the unchanged center goal[0,0,0.5]. It is not evidence of another furniture trap or a grounding failure.

The approved repair is confined to the M1-123 test input pilot: clear real key/stick input, wait for normal deceleration, recheck the unchanged25cm arrival limit and apply corrective input within the same360 sampling-iteration budget. Runtime/controller, transforms, velocity, capsule and collision are unchanged. The user explicitly approved an exact-file exception while keeping M1-123 blocked after automatic approval review refused reopening a globally blocked task. [Pilot verification handoff](../../M1-123/current_pilot_20261110/README.md) records the resulting focused/native verification when complete. No pass is claimed here before those checks finish.

## Frozen failure index

This is the exact older-snapshot failure list, with subsequent repairs qualified above:

| Suite | Frozen mandatory result |
|---|---|
| [test_campaign_later_runtime.gd](full/logs/test_campaign_later_runtime.gd.log) | exit 1 :: LATER CAMPAIGN RUNTIME RESULT: FAIL (78 checks, 30 failures) |
| [test_ch01_game_feel.gd](full/logs/test_ch01_game_feel.gd.log) | exit 1 :: CH01 GAME FEEL RESULT: FAIL (101 checks, 3 failures) |
| [test_ch06_missions.gd](full/logs/test_ch06_missions.gd.log) | exit 1 :: CH06 MISSIONS RESULT: FAIL (149 checks, 105 failures) |
| [test_ch08_missions.gd](full/logs/test_ch08_missions.gd.log) | exit 1 :: CH08 MISSIONS RESULT: FAIL (173 checks, 123 failures) |
| [test_chapter1_campaign_flow.gd](full/logs/test_chapter1_campaign_flow.gd.log) | exit 1 :: CHAPTER 1 CAMPAIGN FLOW RESULT: FAIL (314 checks, 7 failures) |
| [test_chapter1_outcomes.gd](full/logs/test_chapter1_outcomes.gd.log) | exit 1 :: CHAPTER 1 OUTCOMES RESULT: FAIL (134 checks, 2 failures) |
| [test_chapter1_ui_regressions.gd](full/logs/test_chapter1_ui_regressions.gd.log) | exit 1 ::  |
| [test_chapter2_rooms.gd](full/logs/test_chapter2_rooms.gd.log) | exit 1 :: CHAPTER 2 ROOMS RESULT: FAIL (3603 checks, 7 failures) |
| [test_chapter3_rooms.gd](full/logs/test_chapter3_rooms.gd.log) | exit 1 :: CHAPTER 3 ROOMS RESULT: FAIL (4717 checks, 3 failures) |
| [test_chapter5_rooms.gd](full/logs/test_chapter5_rooms.gd.log) | exit 1 :: CHAPTER 5 ROOMS RESULT: FAIL (2837 checks, 32 failures) |
| [test_chapter6_puzzles.gd](full/logs/test_chapter6_puzzles.gd.log) | exit 1 :: CHAPTER 6 PUZZLES RESULT: FAIL (18 checks, 1 failures) |
| [test_chapter6_rooms.gd](full/logs/test_chapter6_rooms.gd.log) | exit 1 :: CHAPTER 6 ROOMS RESULT: FAIL (3579 checks, 33 failures) |
| [test_chapter8_puzzles.gd](full/logs/test_chapter8_puzzles.gd.log) | exit 1 :: CHAPTER 8 PUZZLES RESULT: FAIL (41 checks, 2 failures) |
| [test_garden_movement.gd](full/logs/test_garden_movement.gd.log) | exit 1 :: GARDEN MOVEMENT RESULT: FAIL (54 checks, 2 failures) |
| [test_journal_tabs.gd](full/logs/test_journal_tabs.gd.log) | exit 1 :: JOURNAL TABS RESULT: FAIL (320 checks, 94 failures) |
| [test_main_menu_contrast.gd](full/logs/test_main_menu_contrast.gd.log) | exit 1 :: MAIN MENU CONTRAST RESULT: FAIL (154 checks, 12 failures) |
| [test_outpost_status.gd](full/logs/test_outpost_status.gd.log) | exit 1 :: OUTPOST STATUS RESULT: FAIL (62 checks, 29 failures) |
| [test_performance_runtime.gd](full/logs/test_performance_runtime.gd.log) | exit 1 :: PERFORMANCE RUNTIME RESULT: FAIL (545 checks, 9 failures) |
| [test_player_text.gd](full/logs/test_player_text.gd.log) | exit 1 :: PLAYER TEXT RESULT: FAIL (18162 checks, 3026 failures) |
| [test_upgrade_profiles.gd](full/logs/test_upgrade_profiles.gd.log) | exit 1 :: UPGRADE PROFILES RESULT: FAIL (3180 checks, 129 failures) |

The source/capture evidence already delivered for M1-122/M1-123 remains intact. Done requires a complete passing mandatory runner on the accepted current integration after owner repairs and the owned pilot verification. Saved work, dependency/owner and precise resume conditions are retained here and in the task handoffs. Manual QA, videos, submission and release packaging remain deferred; they are not invented blockers.
