# Current-source acceptance blockers and saved work

10 November 2026, Tanvir. Work is limited to M1-122, M1-123 and M1-85. The collision correction is published in e5ed6178 and actual-input regression in 630c9278; M1-85 evidence/status are published in 2b848e34/76621158. No other task is claimed or repaired.

The synchronized test snapshot is game tree `8edef085d1dcc51ee5c4b6974c31905cd6441da1`, source 2b848e34 (the later status-only commit 76621158 has the same game tree). New care props, opening activity, campaign/player changes and other members' work were preserved. The tested local import metadata and pre-existing project blank-line edit are retained in run metadata; this is not a pristine committed-import baseline.

## Focused checks

The mandatory garden runner passes 2/2 suites: collision 19/0 and real-input movement 54/0. Mandatory habitat_rooms passes 360/0. The same Garden and habitat suites pass inside the broader attempt. First-five-minutes 57/0, Chapter1 room hooks 117/0 and outcome134/0 also pass. These are actual production campaign/body checks; they are not a human playthrough or an exact replay of the unrecorded historical screenshot pose.

## Full attempt and continuation are separate

`game/tools/run_tests.sh` ran with mandatory setup, unchanged 300-second per-suite timeout and unchanged 50ms performance limits. A separate diagnostic wrapper stopped the whole collection at **2,400.220 seconds**, during player-text. **89/115 suites reported: 73 passed, 16 failed. No full-suite summary was emitted.** The collection cap is not a game-test budget or the runner's per-suite timeout. [Invocation/source](regression_post_sync/run.json), [raw runner](regression_post_sync/full/runner.txt), [complete retained-log audit](regression_post_sync/log_audit.json), [interrupted raw player-text log](regression_post_sync/outer_timeout_logs/).

The 26 unreported targets were then evaluated through separate mandatory-runner filters: **24 passed, 2 failed**, in 23 invocations. The terrain substring also rechecks an earlier exterior suite; it is retained and excluded from the 26-target count. [Continuation state](regression_post_sync/continuation/state.json), [target verdicts](regression_post_sync/diagnostic_summary.json). This gives every frozen-source suite a verdict across separate invocations; it is **not** one complete full-run pass, and no completion gate is claimed.

The earlier pre-sync full runner completed **91/95** on a different game tree. Its long wall-clock gap is explicitly recorded; its total duration is not a controlled benchmark. [Earlier run](regression/run.json), [clock observation](regression/clock_observation.json). Do not substitute that older result for the current 115-suite source.

## Current recorded failures

The 16 failures reported by the full attempt are:

- [test_ch01_game_feel.gd](regression_post_sync/full/logs/test_ch01_game_feel.gd.log): exit 1 :: CH01 GAME FEEL RESULT: FAIL (98 checks, 3 failures)
- [test_ch06_missions.gd](regression_post_sync/full/logs/test_ch06_missions.gd.log): exit 1 :: CH06 MISSIONS RESULT: FAIL (149 checks, 105 failures)
- [test_ch08_missions.gd](regression_post_sync/full/logs/test_ch08_missions.gd.log): exit 1 :: CH08 MISSIONS RESULT: FAIL (173 checks, 123 failures)
- [test_chapter1_campaign_flow.gd](regression_post_sync/full/logs/test_chapter1_campaign_flow.gd.log): exit 1 :: CHAPTER 1 CAMPAIGN FLOW RESULT: FAIL (502 checks, 1 failures)
- [test_chapter1_ui_regressions.gd](regression_post_sync/full/logs/test_chapter1_ui_regressions.gd.log): exit 124 ::
- [test_chapter2_rooms.gd](regression_post_sync/full/logs/test_chapter2_rooms.gd.log): exit 1 :: CHAPTER 2 ROOMS RESULT: FAIL (3603 checks, 7 failures)
- [test_chapter3_rooms.gd](regression_post_sync/full/logs/test_chapter3_rooms.gd.log): exit 1 :: CHAPTER 3 ROOMS RESULT: FAIL (4717 checks, 3 failures)
- [test_chapter5_rooms.gd](regression_post_sync/full/logs/test_chapter5_rooms.gd.log): exit 1 :: CHAPTER 5 ROOMS RESULT: FAIL (2837 checks, 32 failures)
- [test_chapter6_puzzles.gd](regression_post_sync/full/logs/test_chapter6_puzzles.gd.log): exit 1 :: CHAPTER 6 PUZZLES RESULT: FAIL (18 checks, 1 failures)
- [test_chapter6_rooms.gd](regression_post_sync/full/logs/test_chapter6_rooms.gd.log): exit 1 :: CHAPTER 6 ROOMS RESULT: FAIL (3579 checks, 33 failures)
- [test_chapter8_puzzles.gd](regression_post_sync/full/logs/test_chapter8_puzzles.gd.log): exit 1 :: CHAPTER 8 PUZZLES RESULT: FAIL (41 checks, 2 failures)
- [test_comms.gd](regression_post_sync/full/logs/test_comms.gd.log): no result line
- [test_journal_tabs.gd](regression_post_sync/full/logs/test_journal_tabs.gd.log): exit 1 :: JOURNAL TABS RESULT: FAIL (320 checks, 94 failures)
- [test_outpost_status.gd](regression_post_sync/full/logs/test_outpost_status.gd.log): exit 1 :: OUTPOST STATUS RESULT: FAIL (62 checks, 29 failures)
- [test_p01_inputs.gd](regression_post_sync/full/logs/test_p01_inputs.gd.log): exit 1 :: P01 INPUTS RESULT: FAIL (319 checks, 1 failures)
- [test_performance_runtime.gd](regression_post_sync/full/logs/test_performance_runtime.gd.log): exit 1 :: PERFORMANCE RUNTIME RESULT: FAIL (544 checks, 3 failures)

The separate continuation adds:

- [player-text](regression_post_sync/continuation/player_text/runner.txt): runner exit124 after its own unchanged 300-second limit; route-B witness/current-goal assertions are retained in the raw suite log. This is distinct from the earlier whole-collection interruption.
- [upgrade profiles](regression_post_sync/continuation/upgrade_profiles/runner.txt): P-09 commit-sequence witnesses reject timestamp/conclusion inputs across profile masks.

P-01 feedback, forecast purity, prerequisite fixtures, UI null access, lunar-gravity assertion, Chapter6/8 campaign entry/puzzles, visible narrative-prop support/labels, comms output marker and performance need their respective owners' integration follow-up. The comms script prints45/0 but lacks the marker the mandatory runner recognizes; this is not a claim that those45 assertions failed. Current M1-68 failures are campaign77.264ms, garden50.784ms and full-cast51.851ms against50ms.

Read-only staging inspection shows the newly added Alo/Tara nameholders are visual props from M3-101. The support test measures visible mesh surfaces, not the three obstacle volumes changed here. Their placement/lifecycle and R/E label failures are retained for the narrative/puzzle owners; no staging or test expectation was changed to hide them.

## Resume condition

M1-122 and M1-123 remain **blocked on required global acceptance**, with verified narrow source work saved/pushed. Owners must resolve the listed campaign/UI/staging/fixture/marker/performance failures, then a complete mandatory full runner must pass. No additional runtime-controller cause has been established in the recorded Garden contact cases. The original screenshot's exact transform/input/camera were not recorded, and the selected candidate starts are labeled honestly. Manual QA, release packaging, submission and video work remain deferred; they are not invented blockers here.
