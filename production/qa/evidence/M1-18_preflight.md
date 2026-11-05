# Ramim preflight ? 6 November 2026

No gameplay/UI source was changed. The runtime tested is main 990126b; subsequent Ramim commits change the board, AI disclosure and evidence only.

## Checks

Pinned Godot 4.7.2.stable.official.ed1daf0bf, Windows, Git Bash 5.2.37. Executed the repository runner, not a bare Godot exit code.

- Full `game/tools/run_tests.sh`: **35/37 suites passed**, exit 1. [Full output](M1-18_baseline.txt).
- One focused `game/tools/run_tests.sh performance_runtime` retry after warmup: **0/1 suites passed**, exit 1, 537 checks / 7 failures. [Retry output](M1-18_performance_retry.txt). The runner prints at most five failure details.
- `board.py check` passes after the owner requests and claim releases.

## Owner prerequisites

- **M1-66, Atik:** P-01 campaign/mission code supplies correct calibration/watering answers and lacks validation of player-selected calibration values. Add authoritative explicit-input validation and panel/route hooks before Ramim resumes M1-08. A UI-only rejection would leave the underlying bypass.
- **M1-67, Sadman:** the M1-63 registry ships only `sci_polar_sun`, while its test requires two real sample clips. Build/register `sci_proton_flux_chart` through the approved pipeline; do not weaken the test.
- **M1-68, Atik:** investigate reproduced loading intervals above 50 ms. Initial title/new-campaign measurements were 59.455/128.056 ms; warm retry also reported five raw character loads at 50.826?57.689 ms. Do not assume reference-Mac performance or relax the gate silently.

M1-08 and M1-18 are **blocked**, not complete. M1-19, M1-29 and M1-55 were released without implementation. No Ramim claims remain in progress.

## Resume M1-18 after the full gate is green

Reuse UiDesign and existing MainMenu, CampaignPanels, campaign HUD and main.gd. Work on title/setup, contextual first-use teaching, controller focus, remapping and 150% text in Ramim-owned files; preserve existing state/save services. Use truthful Story/Cadet/Expedition and Family timer-free behavior; Class co-op remains M1-37. Preserve explicit single-slot overwrite confirmation and safe cancel; multi-slot storage belongs to Atik M3-71. Trainer integration is M1-29.

Add behavioral RED/GREEN tests before implementation, extend the player-text walker, obtain actual changed-screen captures and the required 60-second cold-start recording, then run the full suite and independent review. No UI screenshots/recording were produced in this preflight because no UI was implemented.

Original checkout import settings, local ignore policy, handbook note and editor preferences were backed up and preserved outside these commits. No import files, asset edits, paid generations or AI co-author lines were pushed.
