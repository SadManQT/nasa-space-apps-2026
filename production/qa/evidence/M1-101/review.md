# M1-101 source review

Range: `763616c5a6be500ddd563c59a4bd3c4bddc59c3b..3d031599d26d0f93a1e2377e9a96dc269fb65c86`
Scope: HUD world-node lifetime guards and new regression test. Source, callers, and saved runner logs reviewed without running Godot or modifying source.

## Strengths

- `game/scripts/ui/chapter1_campaign_hud.gd:635-643,976-981,1005` rejects detached or freed player/goal nodes before reading their transforms and hides the goal marker when its node leaves the tree.
- `game/tools/test_hud_world_lifetime.gd:15-49` uses a real campaign scene, detaches and reattaches real player/target nodes, checks live 3–4–5 geometry, and rebuilds two rooms. Saved runner logs show behavioral RED (12 checks, 4 failures) then GREEN (12 checks, 0 failures); detached-transform errors disappear. `git diff --check` is clean.

## Issues

### Critical

None found.

### Important

1. **Nearby prompt still reads a detached target's transform.** `game/scripts/ui/chapter1_campaign_hud.gd:995-1002` checks only `nearby_node != null` before `nearby_node.global_position`. `physical_target()` can return a child of a referenced but detached room/focus root, and `_nearby_id` may remain set until the next physics update. This path can still log the same outside-tree transform error and show a stale prompt. Apply the same validity and tree-membership guard used for `_marker_node`; extend `game/tools/test_hud_world_lifetime.gd:22-41` with a nearby prompt case whose resolved target is detached.

### Minor

None found.

## Declined to judge

- `game/scripts/audio/audio_director.gd:303` resumes `_stream()` after its owner is freed, with one ObjectDB leak warning: present in both RED and GREEN logs and owned by a separate Sadman task.
- M1-08 HUD work and untracked P-01 inputs: separate WIP outside this commit range.
- Full runner and native display: pending; this review uses the saved focused runner artifacts and does not certify either gate.

## Assessment

**Source ready to merge: With fix.** The tested goal-marker and distance paths are corrected, but the nearby prompt is another transform reader in the same overlay function and needs the same lifetime guard before this task's stated scope is complete.
