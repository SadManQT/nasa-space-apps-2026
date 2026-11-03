# Worker B world and missions checkpoint

**Owner:** supervisor integration lane
**Date:** 3 November 2026
**Status:** functional-pass for the Chapter 1–8 route contracts; visual review remains open

## Delivered

- `game/scripts/world/room_contract.gd` and `campaign_room.gd`: Commons, Service Rooms, Garden, Safe Room and Exterior contracts with named visual/collision/focus/pressure/door/navigation/anchor roots.
- `game/scripts/navigation/`: bounded room navigation, pressure boundaries, airlock and shutter interlocks.
- `game/scripts/interactions/interaction_dispatcher.gd`: focus → inspect → use → preview → confirm with frozen command dictionaries, cancel, stale and duplicate semantics.
- `game/scripts/companions/companion_roster.gd`: Chapter 1/2 presence plus later chapter location/team projections.
- `game/scripts/missions/`: Chapter 1/P-01/P-02, Chapter 2/P-03/P-04 and the shared Chapter 3–8/P-05–P-16 gate routes, with physical-only scene completion.
- Room scenes and `game/tools/test_worker_b_world_missions.gd`.

## Verification

- Room contracts, approved asset path presence, named roots, collision geometry, pressure boundaries, airlock/shutter behavior, rosters, interaction transaction fixture, save/pause/duplicate/stale behavior and honest 32-mission registry reached passing checks in the headless fixture.
- `Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tools/test_worker_b_world_missions.gd` — **functional-pass, 187 checks, 0 failures**. The fixture traverses all 12 canonical scenes, P-01, P-02, physical-only gates, retry/pause/duplicate/stale/save behavior, roster continuity and CH02 readiness.
- Focused S03 regression `res://tools/test_ch01_s03_route.gd` — **functional-pass, 7 checks, 0 failures**.
- Production integration `res://tools/test_campaign_session.gd` — **6/6 checks, exit code 0** for title boot, Chapter 1 entry, HUD/panels, first authoritative action, validated save and evidence-preserving restore.
- `res://tools/test_chapter2_route.gd` — **94/94**; all Chapter 2 scenes, P-03/P-04 sequences and route restore.
- `res://tools/test_extended_campaign_route.gd` — **452/452**; all 72 Chapter 3–8 scenes, P-05–P-16 receipts, boundaries and EX-CH08-S12 completion.
- `res://tools/test_campaign_later_runtime.gd` — **7/7**; production restore, CH02→CH03 transition, physical P-05 target and save.
- `res://tools/test_campaign_session.gd` — **8/8** after the full-runtime hardening.
- No visual, learner, controller-device or export review was run.

## Known blockers

- Production boot selects the current chapter route; the commissioning scene remains a compatibility path.
- Headless functional coverage does not replace visual, learner, controller/device, audio, export or performance review.
