# M1-85 - import investigation and verified owned protection

11 November2026, Tanvir/codex. **Final investigation acceptance is under independent review.** The required current full run reports133/133 assertion/runner passes, with24raw suite ERRORs:5intentional negative fixtures and19remaining diagnostics. **Raw-log integrity remains FAILED.** The merged-source mandatory import/font recheck is clean1/1. No native crash cause or universal engine repair is claimed. M1-122/M1-123 remain Done; manual QA/videos stay deferred.

## Delivered owned source

The Game-scoped LF checkout rule preserves2939already-LF canonical sidecars without authored asset/font/renderer/settings changes. Mandatory setup now rejects ERROR diagnostics even at native exit0 and retains editor/phase exits; existing script/native/timeout guards remain. [Actual-shell tests](unit_runner.txt):11total methods,10passed and1POSIX-only signal fixture skipped on Windows. [Canonical metadata](canonical_metadata.json), [consolidated audit](audit.json). Suite exit files are runner phase statuses; forced fatal/timeout paths also retain the native child status in the raw log.

## Bounded native proof

| Matched restoration | Metadata byte changes | Raw setup / runner exit | Observation |
|---|---:|---|---|
| [Original checkout1](red1_restore/runner.json) |960CRLF-only|0 /1|Two get_multiple_md5 file-open ERRORs; guard stops before suites|
| [LF checkout1](green1_restore/runner.json) |0|0 /0|Clean setup and real font probe5/0|
| [Original checkout2](red2_restore/runner.json) |960CRLF-only|139 /139|Fresh native failure; no suite, ERROR or backtrace|
| [LF checkout2](green2_restore/runner.json) |0|0 /0|Clean setup and real font probe5/0|

Every same-path control is clean. Baselines are separately prepared clones of the same retained warm input, not independent cold-cache generations. [Executed replay](replay_policy.py), [stopped state](run.json):complete intentionally remainsfalse after the safety stop. The separately recorded [green-only continuation](green_continuation.json) ran after [native capture](native_capture.json), never retried red2, and reverified its hashes unchanged. The legacy reimport_steps field counts progress lines, not imported assets.

The197474-byte fresh native setup log has no stack. Final adjacent font progress cannot identify a failing importer. [Complete snapshot manifest](native_inputs.json) records5359post-crash files and5352matching pre-control baseline files. An independent post-full-run rehash checked all10711files, exact file sets, sizes, hashes and timestamps with0changes. The baseline is reconstructible pre-control state, not the exact cache immediately before failure; red2 is post-crash. No linked stack/dump was found in the [narrow recorded search](native_system_events.json). The faulting image/module and historical crash's identical cause remain unproved.

## Current acceptance gate - distinct outcomes

- [Fresh current cold attempt](current_gate.json):FAILED, raw editor0/runner1, one dummy texture_2d_initialize ERROR, no suites. Its original state remains preserved. The editor also autosaved project.godot; allother setting values match, and only an explicit web renderer value equal to Godot's default was removed. The original byte-source/full flags remainfalse.
- [First warm attempt](current_warm/current_gate.json):incomplete and rejected. The isolated collector omitted six outside-Game fixtures. Its17reported results, missing-fixture failure and intentional stop are retained; it is not a game-regression claim or full pass.
- [Complete-input warm run](current_complete/current_gate.json):frozen revisionf9469d73/Gamee7759669, all133assertion/phase verdicts pass in5480.034s. The exact recorded editor normalization is disclosed; allother tracked nonimport source, six [frozen support files](current_complete/support_manifest.json), real-player save and original failed snapshot guards pass. [Full verdicts](current_complete/full_gate.txt), [all raw logs](current_complete/current_full/raw_logs.zip). Its generated full_pass/qualified_warm_full_pass flags are runner/coverage/source-guard verdicts; they do not override the separate FAILED raw-log audit.
- [Merged current mandatory recheck](postmerge/run.json):revision92e96a72/Game23550681, clean1/1, font5/0, setup/suite0,0rawERRORs. The sole Game delta is a teammate's export callbacks; import/campaign code is unchanged. The independent review accepts a mandatory parse/import recheck for this delta; no export/package was made. The earlier133result remains pinned to its original source.

Current comms45/0, runtime performance548/0, player_text13038/0 and Garden collision19/0 + movement54/0 pass. Their old failures are not reported as current. Both full and merged calls use the mandatory game/tools/run_tests.sh; no thresholds or expected suites were removed.

## Remaining diagnostics and exact handoff

The full assertion pass is not error-free. [audit.json](audit.json) lists all24raw diagnostics. Five are source-backed negative fixtures:3malformed-GLB errors in test_asset_geometry_recovery,1unknown HelmetRoles role and1unknown narrative variant. The other19 remain failed log-integrity observations:

| Count | Recorded boundary | Follow-up scope |
|---:|---|---|
|9|Directory-open errors from game/tools/support/isolated_storage.gd:29|Shared test-support cache-directory preparation|
|1|Dummy texture t-null from game/scripts/campaign/care_round_runtime.gd:206|Care runtime/renderer boundary|
|2|p.d-null from game/scripts/ui/chapter1_campaign_hud.gd:1652|HUD renderer boundary|
|7|RID/allocator/resource-in-use exit errors in campaign_session and chapter_select|Runtime/test teardown and engine resources|

No new owner/task claim or repair is invented for these nonowned paths. Current integration/runtime/test-support owners must coordinate exact-file reservations for follow-up; assignment of an additional Tanvir implementation task requires an explicit reassignment. Preserve Asif's campaign work and Ramim's active M4-20 handbook reservation. A new native-cause investigation should use a copy of the retained input with linked native symbols/stack or a minimized reproducer; original-artifact waiting is no longer needed.

[Upstream handoff](upstream_report.md) provides exact raw/source recovery, fresh failure and version-pinned engine boundaries. It is saved, not posted externally. Earlier engine hashes identify the console launcher; [postmerge provenance](postmerge/run.json) additionally measures its companion executable before that recheck, not retroactively before the earlier crash. [Saved handbook entry](handbook_handoff.md) awaits Ramim's coordinated application. No other member's source/settings/assets or task status was changed.
