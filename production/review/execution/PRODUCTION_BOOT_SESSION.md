# Production boot/session checkpoint

**Date:** 3 November 2026
**Engine:** Godot 4.7.2 headless
**Fixture:** `game/tools/test_campaign_session.gd`

## Result

**PASS — 6/6 checks, exit code 0.**

The smoke uses the production `main.tscn`, launches `chapter1_campaign.tscn`, and
exercises the real runtime stack:

1. Title menu appears on cold boot.
2. New Expedition enters `EX-CH01-S01`.
3. The campaign builds the accessible HUD and panel layer.
4. `commission_route` commits through `Chapter1Route` and `CampaignDirector`.
5. `SaveService` writes a validated primitive checkpoint.
6. A second campaign instance restores the same scene and physical evidence.

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

Visual playthrough, learner/device review, Windows export, runtime audio, Chapters
2–8 and final endings/credits remain unverified.
