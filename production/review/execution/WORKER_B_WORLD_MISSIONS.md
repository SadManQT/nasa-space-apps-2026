# Worker B world and missions checkpoint

**Owner:** supervisor integration lane
**Date:** 3 November 2026
**Status:** functional-pass for the Chapter 1 route fixture; visual review remains open

## Delivered

- `game/scripts/world/room_contract.gd` and `campaign_room.gd`: Commons, Service Rooms, Garden, Safe Room and Exterior contracts with named visual/collision/focus/pressure/door/navigation/anchor roots.
- `game/scripts/navigation/`: bounded room navigation, pressure boundaries, airlock and shutter interlocks.
- `game/scripts/interactions/interaction_dispatcher.gd`: focus → inspect → use → preview → confirm with frozen command dictionaries, cancel, stale and duplicate semantics.
- `game/scripts/companions/companion_roster.gd`: Chapter 1 presence plus CH04/CH08 location/team constraints.
- `game/scripts/missions/`: Chapter 1 gate catalog, P-01/P-02 adapters, four mission compositions, 12 canonical scene order, and an honest registry with 28 later missions explicitly blocked rather than falsely complete.
- Room scenes and `game/tools/test_worker_b_world_missions.gd`.

## Verification

- Room contracts, approved asset path presence, named roots, collision geometry, pressure boundaries, airlock/shutter behavior, rosters, interaction transaction fixture, save/pause/duplicate/stale behavior and honest 32-mission registry reached passing checks in the headless fixture.
- `Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tools/test_worker_b_world_missions.gd` — **functional-pass, 187 checks, 0 failures**. The fixture traverses all 12 canonical scenes, P-01, P-02, physical-only gates, retry/pause/duplicate/stale/save behavior, roster continuity and CH02 readiness.
- Focused S03 regression `res://tools/test_ch01_s03_route.gd` — **functional-pass, 7 checks, 0 failures**.
- No visual, learner, controller-device or export review was run.

## Known blockers

- `main.gd` still requires supervisor wiring to inject the full director/content/world services; the existing commissioning route remains the production boot path.
- Chapters 2–8 are registered with explicit blocked gates but are not playable implementations.
