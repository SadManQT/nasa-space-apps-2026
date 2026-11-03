# Production boot/session checkpoint

**Date:** 3 November 2026
**Engine:** Godot 4.7.2 headless
**Fixtures:** `game/tools/test_campaign_session.gd`, `test_chapter2_route.gd`, `test_extended_campaign_route.gd`, `test_campaign_later_runtime.gd`

## Result

**PASS — production session 8/8 checks, exit code 0.**

The smoke uses the production `main.tscn`, launches `chapter1_campaign.tscn`, and
exercises the real runtime stack:

1. Title menu appears on cold boot.
2. New Expedition enters `EX-CH01-S01`.
3. The campaign builds the accessible HUD and panel layer.
4. `commission_route` commits through the authoritative route.
5. `SaveService` writes a validated primitive checkpoint.
6. A second campaign instance restores the same scene and physical evidence.
7. The Chapter 1 controller traverses all 12 scenes and transitions into Chapter 2.
8. A later runtime restores Chapter 2, crosses into Chapter 3 and commits a physical P-05 target.

The commissioning scene and legacy save adapter remain available for compatibility;
they are not the production launch path.

## Regression commands

- `res://tools/test_campaign_boot.gd` — 4/4
- `res://tools/test_campaign_content.gd` — 9/9
- `res://tools/test_worker_a_systems.gd` — 101/101
- `res://tools/test_worker_b_world_missions.gd` — 187/187
- `res://tools/test_ch01_s03_route.gd` — 7/7
- `res://tools/test_ch01_commissioning.gd` — 16/16
- `res://tools/test_worker_c_content.gd` — 577/577
- `res://tools/test_chapter1_campaign_flow.gd` — 90/90
- `res://tools/test_chapter1_ui_regressions.gd` — 32/32
- `res://tools/test_chapter1_logic_regressions.gd` — 34/34
- `res://tools/test_save_service_recovery.gd` — 34/34
- `res://tools/test_chapter2_route.gd` — 94/94
- `res://tools/test_extended_campaign_route.gd` — 452/452
- `res://tools/test_campaign_later_runtime.gd` — 7/7

Visual playthrough, learner/device review, Windows export, runtime audio and final
credits presentation remain unverified.
