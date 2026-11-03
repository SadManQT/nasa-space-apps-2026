# Contest bootstrap slice handoff

**Task:** SYS19 bootstrap + bounded commissioning integration
**Date:** 2 November 2026
**Source baseline:** `5f94bc0e8e6ffc49aea5a2ae36570b13d0bfc4c1`
**Scope:** a truthful, playable-intent demo slice; not the complete campaign

## Delivered

- `game/project.godot` now points at `res://scenes/main.tscn` and uses a 1280×720 presentation baseline.
- `game/scenes/main.tscn` and `game/scripts/main.gd` provide a production title route, a styled Aurora diorama, New/Continue protection, science disclosure and a separate developer showcase route.
- `game/scenes/ui/main_menu.tscn` + `game/scripts/ui/main_menu.gd` provide the judge-facing menu, briefing, role cards, source labels and accessibility-first copy.
- `game/scenes/campaign/ch01_commissioning.tscn` + `game/scripts/campaign/ch01_commissioning.gd` provide a compact Commons-style room using existing approved runtime assets, a controllable Mei, interactable mission-table proxies and captioned commissioning flow.
- `game/resources/campaign/ch01_slice.json` is a derived, hashed excerpt of canonical `full-game-story/story-data.json` for `EX-CH01-S01` through `EX-CH01-S03`.
- `game/scripts/campaign/content_loader.gd` validates the source fingerprint and final scene IDs.
- `game/scripts/campaign/slice_state.gd` provides primitive snapshots, atomic user save/load, compatibility checks and exact checkpoint retry support.
- `game/scripts/campaign/slice_rules.gd` provides the single preview/commit transition for the three commissioning decisions, with state revisions and duplicate command receipts.
- `game/scenes/ui/slice_hud.tscn` + `game/scripts/ui/slice_hud.gd` provide captions, role/origin labels, decision cards, preview, explicit commit, journal, pause, retry and result states.
- `game/tools/test_campaign_content.gd`, `test_slice_state.gd`, `test_ch01_commissioning.gd` and `test_campaign_boot.gd` cover content integrity, preview purity, duplicate commits, save round trips, the three-scene route and cold boot.
- `execution/AGENT_SYNC_PLAN.md` records the parallel review ownership and integration fence.

## Canon and contest safeguards

- Runtime copy is English-only and does not use a NASA logo or imply endorsement.
- The station, cadets, 2046 timeline and resource display are explicitly `SIMULATED`/`TRAINING SCENARIO`.
- No plant face, future Noor identity, full-Chapter-1 claim, hidden audio-only clue or cutscene-driven puzzle completion was added.
- Existing player, toon, face, hair, showcase and installed GLB/OGV files were not regenerated.
- The showcase remains a separate developer route; it is not the production main scene.

## Evidence

- `python -m json.tool game/resources/campaign/ch01_slice.json` — **passed**.
- Canonical source hash check — **passed**: `02fa2dee03d11d455f67406de28a4da3cee97b1f8f19fda2cee0e6c1e895a272`.
- JSON slice contains 3 final-source scenes and 13 dialogue lines — **passed**.
- Godot 4.7.2 headless content/state/route/boot tests — **passed**: 9 + 13 + 12 + 4 checks, 0 failures.
- Existing foundations — **passed**: ToonMaterials 12, FaceAtlas 17, HairSprings 5, LipSync, player 105, review 447 and showcase 369 checks. The current face-atlas integration test passes 68 checks. The campaign scene also launches headlessly for three seconds without an error.
- `verify_assets.gd` — **passed** against the installed 49-asset inventory (current characters report 44 animations; 65 bones except Mei at 68; all inspected assets load at expected floor/texture/size values).
- Godot visual review and export remain **unverified**; no screenshot/render/export result is claimed.

## Remaining blockers

1. Review the menu and campaign room visually at 1280×720 and 1920×1080.
3. Extend the frozen services to P-01/P-02 and the remaining Chapter 1 scenes before claiming Chapter 1 complete.
4. Bundle validated NASA source products and provenance before labeling any runtime quantity `OBSERVED` or `COMPUTED`.
5. Keep remaining audio, cutscenes, chapters, learner review and release export explicitly unverified until their evidence exists.
