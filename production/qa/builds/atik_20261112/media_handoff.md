# Media snapshot equality — bounded owner handoff, 12 November 2026

Atik/codex; release qualification under M1-20. Canonical source `game/tools/test_campaign_media.gd` is unchanged. Its SHA-256 is `387aa7c1bf4d6c568c492409da1311acf3778886d58ebb3476522c8e88b10cd0`.

The fresh default full gate reports 136/138. One failure is the media assertion at line 172: watching/skipping and input under a film must not change gameplay state. An isolated mandatory runner then passed 115/0, and the diagnostic copy passed once. These passes are retained and are not a fix.

The diagnostic copy preserves that assertion exactly and only prints both snapshots on failure. Eight bounded forensic repeats yielded seven passes followed by the same 115/1 failure. `media_repeat_08.log` and `media_repeats.json` capture the sole delta:

- `presentation_resume.slot_metadata.saved_at_utc`: `2026-11-12 14:08:02 UTC` → `2026-11-12 14:08:03 UTC`.
- No resource, route, mission-clock, inventory, story or other snapshot field changed in this captured reproduction.

`SaveSlots.enrich_snapshot()` regenerates this wall-clock label on every read. A comparison crossing a UTC second can therefore fail without gameplay mutation. This reproduction demonstrates the fixture mechanism; it does not claim a runtime repair or explain the older Mac rendering hitch.

## Reviewed change requested from the media QA/freeze owner

Sadman / M1-24: review `media_snapshot_owner.patch`. It proposes excluding only the generated wall-clock save timestamp from the two gameplay snapshot comparisons, preserves every runtime operation and gameplay-state field, and proposes regressions for timestamp tolerance, input-snapshot purity and detection of an actual scenario-clock mutation. Runtime `SaveSlots` and campaign source should retain their current behavior. The patch is unapplied and unverified; no test source was edited under Atik's export scope.

After owner review/delivery, run `game/tools/run_tests.sh campaign_media`, then one fresh full gate with the runner's documented `PLAYER_TEXT_TIMEOUT=1500`. The old full gate stays failed. Separately, the current text-only rerun completed all 13048 checks with zero failures in 519.809 s, process exit 0. Its longer process guard did not alter any test assertion or performance limit.

The saved patch uses zero context. Check the recorded source hash and use `git apply --check --unidiff-zero` before any owner-reviewed application.
