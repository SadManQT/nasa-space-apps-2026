# M1-99 ? message state survives physical retry

9 November 2026, Ramim executing Atik's task under explicit user authorization. Git identity remains Ramim.

Source: d0c32b81a1a47de6afe8fdb106ba6f8fad3bcadd. Two production lines capture Director.message_metadata before the route restores the gameplay snapshot and union-reapply it immediately afterward. No core, authored content or visible UI changes.

Behavioral RED: 31 checks / 10 failures, all message-retention checks. Final focused route suite:31 checks/0 failures; unchanged Director metadata suite:76/0. Both through game/tools/run_tests.sh including mandatory setup, with no errors/warnings. Real Chapter1Route retry twice, paused/unpaused, real PuzzleHost preview/commit rollback, receipts removed, gameplay/revision restored, empty messages unchanged. Independent source review:0 Critical/Important/Minor.

Last lines: `1/1 suites passed` for each focused invocation. Full repository runner has not yet run on this candidate; task acceptance remains pending the integrated batch gate. No visual change, so no new screenshot. Raw setup/runner/suite/run manifests, including initial fixture mistake, are retained in the task workspace. The initial fixture omitted PuzzleHost.preview and is not used as behavioral RED.
