# M1-128 — seated crew and trainer navigation, 13 November 2026

User-authorized repair on Shanto's Windows workspace. Baseline game source: f72e3c49; synchronized board/evidence through 2341b574 before implementation. Commits use the existing verified local identity, ShantoNull11. Published exact-file reservations preserve Asif's campaign controller, handbook and AI log reservations.

## Reported bugs and repairs

- **Mission Trainer mouse Back:** reproduced with real `InputEventMouseButton` events through the viewport. The original callback used a ternary expression with void-returning methods, producing `Trying to get a return value of a method that returns "void"` at `mission_trainer.gd:76`. Mouse/controller/keyboard Back now share an explicit handler, preserving modal ordering and returning brief/report pages to the catalog before leaving the trainer. Repeated exit requests are ignored during teardown.
- **Seated characters:** the original floor anchors ignored differing offsets in each imported `SitIdle_loop`. Actual skeleton measurements showed 0.167–0.193 m lateral offsets; Amara's pelvis was at 0.640 m, while Mei's was 0.504 m, and both were behind the intended cushion contact. The new placement aligns the actual pelvis to the installed chair's centered contact frame (0.54 m high, 0.12 m forward of its pivot). Chair facing, staged rotations and scales are respected. The gameplay capsule stays at its authored floor anchor; seated foot IK is disabled. Re-entering a standing scene clears the visual offset and restores foot IK.
- **Related void-result expressions:** the audit also found the same pattern in Moon Trainer Field/Console, controller Start, Tab and walking headlamp controls, and Chapter 1's shift-2 preview pause. These use explicit conditionals and have targeted regression checks.

No generated/replaced assets, story/science changes or save-format changes. No settings/import changes are staged. Before running the editor refresh, 2,950 existing project/import files were copied to `D:/NASA/shanto-fix-backup-20261113` for preservation.

## Verification in progress

- Required runner baseline, real mouse Back: **0/1**, runtime diagnostic retained in `baseline-trainer/`.
- Required runner baseline, real seated skeletons: **0/1**, three lateral alignment failures retained in `baseline-seat/`.
- Initial fixed Mission Trainer runner: **953 checks, zero failures, 1/1**. Expanded rendered Windows Vulkan/Forward+ run: **960 checks, zero failures**, exit 0, including brief Back and three real pointer open/close cycles. Campaign save canaries remain unchanged.
- Initial comprehensive seating attempt: **577 checks, one failure** because the test selected a Chapter 7 work scene rather than a seated scene. The test was corrected to the authored storm-step seating scene; no production behavior was changed to satisfy that assertion.
- Rendered Windows Vulkan/Forward+ on NVIDIA RTX 4050: **745 checks, zero failures**, exit 0. All five cast models checked over animation frames in Safe Room and rotated/staged Commons chairs, with repeated sitting/standing transitions. The inspected Safe Room capture shows centered supported characters. Initial Commons capture was above its ceiling; capture camera correction is verification-only, and a corrected capture remains pending.
- Full required `game/tools/run_tests.sh`: running with `PLAYER_TEXT_TIMEOUT=1500`, the runner's documented full-campaign text process guard. Assertions and performance budgets are unchanged. Final per-suite results and limitations will be recorded before task closure.

Logs are retained under `D:/NASA/shanto-game-checks`; final evidence archive and delivery commit will be added after verification. These are automated/scripted checks, not a claim that every possible bug or human playthrough has been covered.
