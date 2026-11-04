# Chapter 1 audit and fixes

Date: 3 November 2026. Scope: EX-CH01-S01 through EX-CH01-S12, production boot/HUD, P-01/P-02, plant state, checkpoint/retry and the Chapter 2 boundary.

## 4 November integration

Integrated the audit changes with upstream `8d94618`, preserving all 24 intervening commits. The upstream authored room presentation supersedes the audit's temporary room-shell implementation; the keyboard fixes, readable settings, pause copy and actual-key regression checks are retained. The floor regression now checks the authored room's visible floor. The test runner supplies the player suite's required fixed timing, and the showcase's Python gate uses the installed Windows command.

Fresh Windows / Godot 4.7.2 verification: `game/tools/run_tests.sh` completed with **27/27 suites passed, exit 0**. Current checks include Chapter 1 plus its playable Chapter 2 handoff **230/230**, UI **42/42**, later route **635/635**, save recovery **92/92**, world/missions **429/429**, player **105/105** and showcase **372/372**. Conflict-marker and whitespace checks are clean. A safety branch, stash and separate file backup preserve the pre-sync state. No fresh manual playthrough or export certification was performed for this synchronization.

The original 3 November results and limitations below are historical. Current production status remains in the handbook and team board.

## Fixed

- Restored normal keyboard input: all seven keyboard bindings incorrectly required device 16. They now accept any keyboard. The regression sends actual key events, including E through the production input handler.
- Made the existing floor and wall geometry visible. Its meshes remain under VisualRoot and its physics bodies under CollisionRoot. Previously the room appeared as floating props against a blank background.
- Fixed HUD/title controls outside the 1280x720 viewport; added scrolling and focus following, kept settings reachable at 150% text, and restored readable enabled-toggle labels. Pause now explains how to resume.
- Isolated title geometry/lighting from gameplay; kept the pointer available; wired nearby operations to real room, distance and line-of-sight checks; preserved rejection explanations and modal focus/pause state.
- Used the authored scene viewpoint and authoritative plant stages. Future Alo/Tara flowers no longer appear at planting time; Alo first bloom appears on April 27.
- Prevented P-01 confirmation from applying an empty watering payload and then applying the action twice. Invalid watering cannot create a receipt.
- Enforced P-02 prerequisites at the shared command boundary, preserved cumulative blackout counts, and stopped terminal unsafe outcomes from advancing to bloom. Failed plants cannot revive through a later care action.
- Validated nested route/puzzle/plant checkpoints transactionally, made retries coherent, bounded receipt snapshots, and validated dates and the explicit seven-shift transition.
- Recovered a valid backup when the primary is absent or corrupt; rejected invalid saves before writing; staged replacement files and preserved earlier files when write/repair fails. Invalid, incomplete and legacy saves no longer silently start and autosave a replacement campaign.
- Isolated save-writing integration tests from the player's profile. Corrected the Chapter 1 room fixture after the global room registry expanded to later chapters.

## Verification

Godot 4.7.2 on Windows. All 24 `game/tools/test_*.gd` suites were exercised. The initial generic runner omitted the player suite's documented `--fixed-fps 60` flag and timed out; rerunning with that flag passed. LipSync passed separately with its intentional missing-cue warning. A warning is not a runtime failure.

| Check | Result |
|---|---:|
| Real production controller, all 12 Chapter 1 scenes, garden save/reload, Chapter 2 transition | 90/90 |
| Chapter 1 logic and malformed-state regressions | 34/34 |
| Production UI, real keyboard events, pause/focus, accessibility and invalid saves | 42/42 |
| Save recovery and write failures | 34/34 |
| Worker A systems | 101/101 |
| Worker B world/missions, including five visible room shells | 192/192 |
| Worker C content/UI | 577/577 |
| Production session | 8/8 |
| Commissioning / S03 / boot / content | 16/16, 7/7, 4/4, 9/9 |
| Player controller, with fixed timing | 105/105 |
| Approved GLBs loaded by `verify_assets.gd` | 49/49 |

The production flow test performs operations beside actual room targets with approved assets loaded; it does not bypass the controller using distance zero. The garden checkpoint is reloaded after planting and sealing, before continuing the route.

Native Forward+ window inspection at 1280x720 covered title scrolling, normal/150% settings, readable toggles, New Expedition briefing, gameplay HUD, out-of-range mouse-operation feedback, visible Commons geometry, pause message and Continue. New tests and the graphical QA launcher use separate save profiles. Native keyboard injection did not give reliable visual feedback in this desktop session; the physical-key event path is covered by the automated integration test instead.

## Still open

- This is a functional audit, not final production sign-off. A human should play all 12 scenes with ordinary keyboard/mouse and a controller; device performance, Windows export and interruption/power-loss testing remain open.
- The reusable room shells and prop placement still need authored environment dressing and visual polish. Early Alo/Tara seedlings and Tara buds have no approved models; their labelled bays show the actual stage rather than a future flower.
- Runtime voice/music/SFX, final cutscene integration, learner review and release credits presentation remain production work. No new assets or media were generated and no paid tools were used.
- Later chapter implementations changed concurrently in the shared workspace. Their existing route suites were checked, but this audit did not perform a full visual playthrough of Chapters 2-8.

The original audit did not commit or push. Another session created shared-workspace checkpoint `ff09cfd` during that audit; the remaining fixes and this report are included in the user's authorized 4 November pull/merge/push.
