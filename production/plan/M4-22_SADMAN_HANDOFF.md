# M4-22 - Sadman takeover (12 November 2026)

The user explicitly stopped Ramim's implementation because of the remaining usage limit and asked Sadman to take over the full UI plan. This is a saved-work handoff, not task completion.

## Start here

- Fetch `origin/ramim/ui-proposals-20261111`. All UI source, approved reference images and current captures are on that branch. Preserve its commits and teammates' changes; do not redo the work from scratch or restore the rejected M4-20 industrial design.
- Full plan: `production/plan/ui_proposal_20261111.md`. Approved references and adaptation map: `ui_proposal/README.md` (15 PNGs,1672x941).
- Evidence: `production/qa/evidence/M4-22/`. Latest native log: `M4-22-native-refined-v4.log` (19 captures,0 failures,exit0; no new parse/import/runtime ERROR diagnostics).
- Original IDE checkout was intentionally left untouched: it has thousands of pre-existing generated import changes, local project.godot editor churn, and the user's untracked proposal images. Do not stage/reset/overwrite them. Current implementation checkout: `C:/Users/User/.codex/worktrees/nasa-gohud-setup-20261110`.
- The UI branch is a review branch, not yet merged into main. The latest team story/narrated explainer changes were merged through shared main415244a5/bf932a61. Fetch again before final integration and preserve both sides.

## Implemented

Cinematic full-screen title (sheet01;02/03 atmosphere alternatives), shared soft navy/ivory/gold kit and licensed Cinzel display/Barlow headings/Roboto body; authored settings, chapter selector, Mission Table, calibration, greenhouse, HUD, comms, trainer and shared overlay shells. Existing route/rover/EVA and later puzzle interfaces inherit the shared kit and preserve their real providers.

Full persistent Settings now opens from title and pause. All tabs, controls, saves, chapters, remaps, accessibility, first-time guidance replay and slot continuation remain connected. Fixed stale legacy key bindings overwriting full settings; Family/session flags and subtitle scale persist through restart and actual campaign launch. Use hints display the configured key.

Mission Table retains preview/confirm, crew constraints, seven shifts and Class controls. Calibration retains every P01 action and actual forecast/commit safeguards; new blank reference photograph, step ribbon, larger numeric inputs, initial top-of-panel view. Greenhouse binds actual dated plant records and reuses approved GLB models for dated previews, never flowering art for a seed or archived founder. Comms has actual cadet-model portraits, five channels, chat reader, delivered-sender sidebar filtering and read/unread persistence; Noor remains a neutral mark to protect reveal/live gates. Portrait viewports release on close.

Chapter selection has curved eight-marker timeline, illustrated cards, real lock/spoiler/progress/achievement rules and fixed footer. It remains read-only: no fake replay/resume API. Trainer has an ivory catalog, three illustrated feature cards, Observe/Try/Review guide, all16 scenario entries and the actual Moon Trainer. P02 is the one implemented scenario,15 remain honestly Coming soon. No decorative Class switch: its trainer adapter lacks the complete crew-signoff provider chain; existing campaign Class features are preserved. Do not implement new gameplay simply to imitate the mockup.

Final source fixes saved in the last handoff commit: chapter/comms brand label width/wrap fixes, calibration initial scroll-to-top, capture teardown guard. Native normal/150% screenshots show the header fixes and full initial probe.

## Verification already performed

Use `game/tools/run_tests.sh`, never bare Godot exit0 as proof. Local engine is Godot4.7.stable.official on NVIDIA RTX4060; project target remains4.7.2. Godot MCP unavailable, so CLI and actual native Forward+ Vulkan captures were used. Do not claim all hardware, full-project or manual playthrough qualification.

Latest `tests/closeout/`: UI kit522/0, UI families84/0, UI polish19/0, UI proposal69/0, campaign UI regressions42/0, Comms45/0, Chapters119/0, P01 panel140/0, Settings80/0, title contrast155/0. `tests/mission_trainer/`:968/0, including real outcomes/retries/source navigation, modal states,150% scroll/focus and save canaries. Fixture teardown drains owned look-ahead; these latest logs contain no corresponding resource-in-use errors.

Earlier focused checks retained under `tests/prior_ui_checks/`: Mission Table109/0 and lifetime11/0, Class60/0, first-five-minutes59/0, How-to227/0, care32/0, Chapter2 wiring149/0, Chapter3 wiring17/0, P09/P10 panels330/0, P13/P14 panels406/0, manual wiring15/0, campaign input39/0, hints124/0. Exact commands/logs are saved. These earlier results predate the final narrow layout fixes and/or latest teammate merge; repeat only affected gates as needed.

Moon Trainer142/0 in `tests/earlier_complete/` used the runner's explicit SUITE_TIMEOUT=600; two earlier standard300s attempts timed out during finite physics movement. Assertions and loop bounds were unchanged. This is not a performance fix or universal readiness claim.

Native captures:01title(normal/large),04settings(normal/large),05actual campaignHUD,06MissionTable,07initialcalibration+prediction,08journal,09actualdatedgreenhouse,11starting+actualS03crew(normal/large),13chapters(normal/large),14Mission/MoonTrainer(normal/largewhereapplicable),15pause. Probe/atlas images import<=2048. Four asset entries are still in_progress pending final qualified review records.

Independent gpt-6-astra/high read-only review inspected source and normal/150% captures: no runtime blocker found; clean probe/title/atlas/mark artwork accepted in its messages. The agent hit a usage limit before its final signed report. Preserve that qualification; do not invent a completed final signoff.

## Remaining plan - finish only the UI

1. Read this handoff and existing plan, fetch latest main, inspect board reservations and claim M4-22 as Sadman using your own account. Exact-file reservations must be published before source edits; previous Ramim reservations are released after the saved branch is pushed.
2. Fix the capture harness only: standalone MissionTable showcase is added over a still-running campaign in `capture_ui_proposal.gd`; the ambient ventilation caption overlaps its Try it button. Reviewer traced this to bypassing the real HUD modal opened signal. Real gameplay correctly calls set_ui_paused(true), which suppresses ambient captions while the modal is open. Smallest fix: pause the background campaign before the standalone showcase or capture through the real HUD gate. Do NOT change audio runtime to fix this artifact.
3. Re-capture that view; complete final independent source/visual review. Compare to approved sheets, especially calibration, Messages, Chapters and Trainer. Preserve accessibility and all gameplay providers. Other references are supported compositions/adaptations, not pixel-exact replicas.
4. Record final UI-only asset verification in asset_verification.md / visual_review.md (do not overwrite unrelated3D reports); finalize four UI registry entries only after real checks. Manifests and generation prompts already exist, asset SHA/source dimensions in asset_manifest.json. Atlas is conceptual category art, not NASA dataset terrain; all dynamic labels/counts remain engine nodes.
5. Update handbook status, plan checkboxes, evidence README and a qualified final review. A full134-suite claim is not authorized by these focused results; use appropriate affected tests and scan complete logs for ERROR as well as passing result lines.
6. Fetch/merge safely, preserve teammates' commits and reservations, stage only scoped UI/evidence/docs. Push reviewed source, merge to main only when verified, then release reservations/mark Done truthfully. User wants a concise update after every push.
7. Safely update the user's original checkout without disturbing its local imports/project.godot or new proposal files. Identical untracked proposal images may need a backed-up SHA-checked move before ff; preserve all originals. No force push/reset/blanket staging, no unrelated gameplay/video/release work.

## Assets and tools

`game/assets/ui/title/aurora_cinematic.png` = clean user01-backed title plate; `branding/aurora_mark.svg` = original crescent/four-petal motif. `proposal/probe_setup.png` and `practice_atlas.png` are reference-guided image_gen artwork (source prompt/input/human changes in AI_PROMPT_LOG.md). Atlas source2172x724, texture import size_limit2048; derive region width from actual texture width/3. It is illustrative category artwork and never substitutes for an individual plant record.

Installed skills: godot-ui-integration and gohud; Gohud1.3.0 already installed. Major formal layouts are authored .tscn nodes, runtime binds data and repeated entries. No dependency update is needed. User allows slight refinement, not a return to previous industrial styling. Avoid new UI features unsupported by existing providers.

No further implementation was performed after the user's stop/takeover request. The last work is saving evidence, this handoff and remaining source, pushing, and board administration.

## Published handoff receipt

UI source/evidence push confirmed: `ac3603b7` on `origin/ramim/ui-proposals-20261111`. Main advanced to `2dd5efe5` during handoff with newer teammate HUD/status/caption checks; these newer changes have NOT been merged into the UI review branch. Sadman must integrate both, resolving shared HUD edits without losing either implementation, then recheck affected tests. All47 Ramim UI file reservations are released. M4-22 is Todo for Sadman to claim; no final completion or merge is claimed.
