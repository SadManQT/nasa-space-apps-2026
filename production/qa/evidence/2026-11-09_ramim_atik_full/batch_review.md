# Integrated Atik/Ramim source review

Reviewed `19af82e..e78f5bc3f6a3df2481ad55ccecac7a4853b86345` (frozen game tree `108a384a95a17d5581e4d50b6a1c3e1ac08ea89b`). Scope: M1-99, M1-69, M1-95, M1-101, M1-115, M1-08, M1-107 and M1-97, against the integration plan and full board prompts. Read connected Director/SaveService/routes, campaign/crew/player placement, HUD/panel/hint/source lifecycle, production loading/audio callers, tests and saved evidence. No engine or tests were run; only this requested review report was written.

## Strengths

- **Retry and saving share the bounded store.** `game/scripts/missions/campaign_route.gd:71-73` retains live messages through route restore and mirrors them back through the existing Director setter. `game/scripts/campaign/chapter1_campaign.gd:479-492` delegates validation, saves accepted duplicates so failed writes can be retried, rejects malformed updates before saving, and distinguishes live acceptance from persistence. The connected Director setter preserves gameplay revision/checkpoints; no second store or restore-for-read path was introduced. Saved real-backend tests cover repeated/paused retries, checkpoint/receipt rollback, malformed update/file equality, Continue, legacy/fresh state, disk failure and recovery (route31/core76/campaign28, zero failures).
- **P01 uses current chosen inputs.** `game/scripts/ui/p01_panel.gd:83-138,187-190` invalidates edited predictions, binds confirmation to current gameplay/route/choices, ignores presentation-only changes, and dispatches through physical campaign validation. `game/scripts/missions/p01_commission_plant.gd:159-186` validates and applies explicit label payloads; profile2 preserves canonical saved values. Both real labels are available without a default (`p01_panel.gd:279-281`), while packet, label and completion changes appear in actual/projected readings (`314-325`). Existing preview/commit atomicity, legacy receipt replay and physical rejection remain intact.
- **Modal and world lifetimes remain coherent.** `game/scripts/ui/chapter1_campaign_hud.gd:162-180,911-959` integrates P01 with the existing pause union and disables underlying HUD controls; covering hint/source readers preserve choices and return to the panel. `p01_panel.gd:359-381` preserves action focus while revealing large-text projections. HUD world readers now require live tree membership (`chapter1_campaign_hud.gd:656-667,1001-1031`). Saved focused/native evidence includes real typed input, keyboard/controller navigation, hint/source returns, dirty leave, stale forecasts and detached-node rebuilds. I also viewed the final 150% prediction, wrong-label and real-E observed-result PNGs.
- **Ownership stays narrow across current team integration.** Campaign `_place_crew()` disables only the active actor's generic E poll (`chapter1_campaign.gd:685-686`); the default and explicit standalone API remain (`player_controller.gd:18,242-243,293-297`). Shared placement still covers incremental, normal, wardrobe/EVA and restored rooms. The corrected real-input fixture waits for an actor that can accept Inspect; saved native old-behavior43/1 versus fixed43/0 demonstrates sensitivity, with focused38/0 and five PNGs. The merge diff against incoming team parent preserves the inspected campaign/loading/main/audio/AssetGeometry source; performance differences there are the retained diagnostics only.
- **Trace retention respects current measurement boundaries.** `game/tools/test_performance_runtime.gd:111-128,261-315` snapshots window metadata and writes original stages after all measurements. It includes the latest terrain window and keeps the unchanged 50ms checks. `production/qa/perf/collect_loading.py:57-60,91-104` retains revision/hash provenance and fails a requested missing artifact. The latest saved `M1-97_landed_team/loading_trace.json` has 16 windows/322 stages, including 66 appended terrain stages; all37 retention checks pass. Existing raw/gait windows remain honestly marked trace-disabled. Earlier 272-stage evidence is separately retained, not presented as this latest run.

## Issues

### Critical

None found.

### Important

None found in the reviewed integrated source.

### Minor

None found.

## Evidence and limitations

- Relevant source/test diff whitespace checks pass. Inspected saved P01 focused589/0 and native606/0/34PNG evidence, corrected E-input focused38/0 and native43/0 evidence, prior independent reviews and their documented RED/GREEN fixes. Independent Tanvir focused589/0 plus38/0 and Compatibility native44/0 support the same input path; his separate Forward+ timeout is not a clean native process pass.
- Latest saved performance result is **581 checks/6 timing failures**, with retained dummy-renderer RID errors and one ObjectDB warning. These remain disclosed M1-68/owner investigation work; no causal or performance-fix claim follows from this review.
- The frozen integrated full runner was still active at review handoff. This report does not certify its outcome, the extended eight-chapter text walk, full-game completion, or a release gate.

## Declined to judge

- M1-56 inbox/unlocks/arrivals: explicitly deferred to the next batch; the reviewed bridge is its prerequisite, not an inbox implementation.
- Other owners' new terrain, EVA, assets and audio behavior beyond caller/merge preservation: outside the authorized eight deliveries.
- Timing optimization, dummy-renderer RID/ObjectDB causes, original-host recollection and cross-host cache equivalence: separate existing investigations; retained ranges do not supply absent stage timestamps/thread IDs or establish each heartbeat's cause.
- The player's reported seated-looking pose: no reproduced Sit/SitIdle cause in this evidence.
- Physical controller/keyboard hardware and fresh human playtests: evidence uses injected engine events.
- Fresh Godot/native/test execution: prohibited for this review while the parent runs the integrated gate.

## Assessment

**Source ready: Yes — C0/I0/M0 in this scope.** The eight deliveries fit their contracts and preserve the inspected current team integrations. Full acceptance remains pending the frozen runner and existing disclosed performance/native-host blockers; no full-game completion claim.
