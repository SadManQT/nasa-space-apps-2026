# M1-65 dry-zero integration retest - 9 November 2026

Tanvir/Codex independently checked the UI/input changes pulled from main `415aa23`. Tested commit `cc4e18075dc999a2af300edea237cd6b971162b9` adds only Tanvir's board claim; game tree `7651c4be9d89d50217db934f3632a37acd7fcf11`. The original checkout and its unfinished collision changes were left untouched. This report does not close M1-65, M1-08 or M1-107.

## Result

The actual production dry-zero panel now opens from an injected E event. Cancellation preserves the route snapshot; reopening, choosing Dry reference, typing raw 10/calibrated 0, predicting and explicitly confirming sets probe_zeroed with exactly one receipt. Closing restores the unpaused/enabled state asserted by the fixture. Campaign E samples contain no unrelated Inspect; standalone console E still requests Inspect. The trace identifies Mei in the campaign and Kai in the standalone scene. This does not establish the cause of Tanvir's original seated-looking pose.

| Run | Result | Evidence |
|---|---|---|
| Mandatory runner `p01` | 4/4 suites passed; 317+104+29+139=589 checks, 0 failures; exit 0 | [summary](p01_runner.txt), [metadata](p01_run.json), raw `p01/*.log` |
| Mandatory runner `campaign_interaction_input` | 1/1 suites passed; 38 checks, 0 failures; exit 0 | [summary](campaign_input_runner.txt), [metadata](campaign_input_run.json), raw `campaign_input/*.log` |
| Forward+ Vulkan windowed | Behavior marker 44/0 and 5 captures, but process exceeded 180.017 s; timeout 124. **Failed process run**, not a native acceptance pass. | [run manifest](native/run.json), [log](native/capture.txt), [trace](native/input_trace.json) |
| Compatibility/OpenGL windowed | 44 checks, 0 failures; 5 captures; exit 0 in 13.450 s | [run manifest](native_compatibility/run.json), [log](native_compatibility/capture.txt), [trace](native_compatibility/input_trace.json) |

Machine: the previously identified weakest team laptop, Windows 11 / Intel Arc 130V, Godot 4.7.2.stable.official.ed1daf0bf, 1280x720. Rendering identity is recorded in each raw native log. No new hardware inventory was collected.

Both renderer attempts' five PNGs were opened and inspected. The [unset Compatibility panel](native_compatibility/M1-65_retest_dry_zero_panel.png) visibly shows Not chosen numeric fields; the [observed result](native_compatibility/M1-65_retest_dry_zero_observed.png) says Probe: zero set. Equivalent Forward+ images were captured before the exit timeout. Each native manifest records 12 source hashes and 5 PNG hashes/timestamps. [artifacts.json](artifacts.json) records all raw artifact bytes; local .gitattributes preserves them across checkout.

## Method and limits

[capture_dry_zero.gd](capture_dry_zero.gd) extends the existing reviewed `game/tools/test_campaign_interaction_input.gd`; it redirects screenshots/trace to Tanvir's folder and adds one trace-write check. Behavioral assertions are inherited. Exact native arguments are in the manifests; set TEST_LOG_DIR to a new output directory and run the same adapter after the mandatory runner. The parent enables capture with `-- --capture`.

The fixture uses isolated temporary saves, disables cutscene autoplay, positions the actor near real targets, and directly performs earlier scene setup/advances. It injects engine key events, assigns control focus, types the values and operates real panel controls. It is automated integration evidence, not a physical-keyboard/controller playthrough, a fresh player's understanding, or a checkpoint-restoration test. No subsequent goal identity or actual walking after closure is asserted. No story, rule, UI, runtime, asset or project source was changed by this QA follow-up.

Forward+ printed its behavioral PASS marker and wrote its trace before the process deadline. The enclosing subprocess timeout is retained as a failed run; a later process check found no Godot process remaining. No driver, deadlock, GPU or original gameplay-lock cause is established. The successful Compatibility attempt does not certify Forward+ teardown. The full integrated suite was not run in this follow-up and remains pending on the owner tasks.

## Diagnostics and owner handoff

- **Atik M1-116:** investigate the post-result Forward+ exit timeout separately from the original no-panel progression problem.
- **Sadman M1-117:** investigate 11 recurring kit LOD1 texture UID fallback warnings per campaign log after normal import. A content diff of the tracked texture .import was empty; local cache/import consistency needs investigation before claiming an authored asset defect. Text-path fallback succeeded; no missing-material defect is established here.
- No ERROR or SCRIPT ERROR lines occur in these retained setup/suite/native logs. They are not warning-free: P01 inputs reports 4 ObjectDB instances leaked, nearby reports 3; the other selected suites do not report those leaks. Existing M1-08 notes retain this runtime/UI concern. Compatibility additionally warns that TAA is only available under Forward+.
- Ramim M1-08 / Atik M1-107: this independent evidence supports the narrow panel/input repair, with owner full-suite acceptance still pending. No seated-clip repair is certified.
- M1-18/M1-31 onboarding and feedback, plus Atik M1-108 physical retrieval/place visualization, remain open. A functioning 2D calibration panel does not satisfy Tanvir's requested 3D work process.

## Human retest

Use the updated QA copy at `.codex/worktrees/tanvir-qa-20261106/game/project.godot`, rather than the original checkout with unfinished local changes. No game was left running. Continue the saved expedition only if it loads normally; checkpoint compatibility was not tested, so preserve it before choosing New Expedition. At the dry-zero goal, E should show the calibration panel. Read its references, make your own choices, use Try it, then Lock in and Confirm choice. Report whether it opens, what you understand you are doing and why, what happens after confirmation, and any new stop (goal text plus screenshot). The exact historical pose remains unverified.

Do not count this coached retest as a new fresh-player study. M1-65 still needs the specified human 20-30 minute run and 1-2 fresh-player observations/screenshots; the current self-report remains around 10 minutes. Broader chapter QA M1-21 still waits on its dependencies. Independent second-AI review passed with no material findings; it verified all 30 artifact hashes, native source/capture hashes, result distinctions and scope limits.
