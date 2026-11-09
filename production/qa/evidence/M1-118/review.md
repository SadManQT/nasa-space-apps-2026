# M1-118 read-only source review

Range: `67d53d3..50db8f0799feb53891e5c2894f173fc57b5e215b`; game tree `7872f1133b93e8425dc258f930541a8e59ab55f2`. Reviewed the exact board prompt, the panel/lifetime-test diff, connected open/render/focus/hint/HUD paths, existing P02 tests and saved RED/GREEN/native evidence. No engine or tests were run. Only this requested report was written.

## Strengths

- `game/scripts/ui/mission_table_panel.gd:759-776` removes both awaits from the instance method. The static continuation holds only the live SceneTree and a WeakRef to the original scroll; after the same two process frames it validates that scroll before writing. Freeing the panel cannot resume its dead instance. No panel/route state is retained by the continuation.
- Existing hint suppression, valid/in-tree/not-queued target checks and initial focus remain unchanged (`759-764`). Re-rendered children are removed and queued for deletion (`313-327`); the weak reference stays tied to the old scroll and cannot reset a replacement found by name. The HUD's pause/commit ownership is untouched.
- `game/tools/test_mission_table_lifetime.gd:10-24,49-68` records actual engine errors and exercises the production deferred focus entry, freeing immediately, between the two callbacks, and through queue_free. The meaningful saved RED2 is **11 checks/1 failure**, containing both original freed-instance errors at old lines767/768. The earlier direct-call false-negative attempt is separately retained.
- Saved mandatory GREEN is **198 checks/0 failures, 3/3 suites** (109 existing UI, 11 lifetime, 78 P02); unchanged payload checks are **160/0**. Native frozen50db8f0 is **14/0**, exit0, with two screenshots. I viewed both normal/150% images: the guide and selected focus remain visible with the footer reachable. `git diff --check` is clean.

## Issues

### Critical

None found.

### Important

None found.

### Minor

None found.

## Declined to judge and limitations

- Full-suite acceptance of50db8f0: not run for this review. The earlier83/84 result belongs toe78f5bc, not this follow-up.
- M1-68 performance and unrelated renderer causes: unchanged and outside this lifetime fix.
- Native exit reports **two leaked ObjectDB instances**; no leak cause or repair is established. Focused logs have no errors/warnings; native has no engine errors, with that warning retained.
- The native manifest names the actual panel script and scene and records both PNG hashes/times; the parent's complete provenance verification remains separate from this source review.
- M1-98 collection bytes/source attribution and broad team changes are untouched by this three-file range.
- Hardware input and human playtests: not observed. Fresh Godot/native/test execution was prohibited for this review.

## Assessment

**Source ready: Yes — C0/I0/M0.** The minimal continuation change fixes the demonstrated freed-instance resume while preserving focus guards and the two-frame layout delay. This is a focused follow-up approval, not a current full-suite or release claim.
