# M1-85 upstream handoff - Windows native editor import failure

Prepared11 November2026 by Tanvir/codex. Saved for review, not submitted externally. This report provides a fresh source/cache-linked native failure and a verified checkout/runner mitigation. It does not establish the original crash cause or repair Godot's native importer.

## Fresh bounded reproduction

Use standard Windows Godot4.7.2.stable.official.ed1daf0bf console executable, SHA256 `c8f0a6bc45a19b33541501e57f6f7cd972ab18453743266339d495cbbe846643`. [Host hardware/driver and original isolated paths](../recovered_repro_20261110/environment.json). Matching version does not establish original-host/binary/cache equivalence.

[Executed replay](replay_policy.py), [stopped execution/provenance](run.json): reconstruct original046662c Game tree `f59fcc7b080618dc5388cf84c56fd5938ced76ab` (2568files/902391503bytes), preserving all nonimport source except declared hashed checkout rule/runner/font-probe overrides. Original source is verified from recovered patch, Git blobs and LFS payloads. Use isolated project/profile copies, no real saves or renderer/project-setting changes. Red and green Git export contexts pin GIT_DIR, index, object store and working directory independently.

For each pair, clone the same retained warm Game/cache/profile into separately prepared baseline, red and green projects; verify complete byte hashes match before controls. These are two baseline clones of one retained warm input, not independent cold-cache generations. Run a clean same-path control through `game/tools/run_tests.sh m185_import_integrity`. Restore960logically identical tracked sidecars: original `core.autocrlf=true` checkout exports CRLF; candidate Game rule preserves LF. Run the same mandatory editor setup and probe again.

| Restoration | Raw editor / runner exit | Observation |
|---|---|---|
| [Original1](red1_restore/runner.json) |0 /1|Two get_multiple_md5 file-open ERRORs; guard stops before suites|
| [LF1](green1_restore/runner.json) |0 /0|Clean setup and probe5/0,0byte sidecar changes|
| [Original2](red2_restore/runner.json) |139 /139|Fresh native failure after16.614s; no suite, ERROR or stack|
| [LF2](green2_restore/runner.json) |0 /0|Clean setup and probe5/0,0byte sidecar changes|

Every control is clean5/0. Native failure occurs in one of two observed CRLF trials, not deterministically. Its [197474-byte raw setup](red2_restore/runner_logs/setup.log) and outer log retain Bash's segmentation-fault report. Final printed imports are GochiHand-Regular.ttf, BarlowSemiCondensed-SemiBold.ttf, GochiHand-Regular.ttf. Parallel progress cannot identify the actual failing importer or imply a font defect. No source edit or warm retry clears this failed observation.

The original collector stops immediately on native failure: `run.json.complete=false` is intentionally retained. After read-only capture, a [separate green-only collector](green_continuation.py) ran only green2control/LFrestore, passed, and reverified the complete red2 post-crash hashes unchanged. [Continuation results](green_continuation.json). Red2 was never retried.

## Preserved native state and limits

[Capture/provenance](native_capture.json), [complete SHA256/size/mtime manifest](native_inputs.json): baseline2 and initially untouched green2 each have5352files/1715305723bytes and match pre-control clone aggregate `0a81343830d47950ff859034938984d2463a6ac2df4165d21125ea33455fe759`. Red2 has5359post-crash files retained locally with source/cache/UIDs/profile. The exact retained paths and engine/script/command hashes are recorded. Baseline2 retains reconstructed pre-control state, not the exact cache at the instant before the crash; red2 is explicitly post-crash state. Generated cache/profile files are retained locally, not committed as bulk binaries or personal saves.

A [narrow host diagnostic search](native_system_events.json) found no linked Application1000/1001/1002 event in the recorded time window or nearby Godot dump in the two recorded CrashDumps locations. No native stack is available. A minimized fatal reproduction and failing native call/thread are still absent; the new linked failure resolves the previous reproduction dependency without supplying those missing diagnostics.

## Original historical incident

The original mandatory setup in `game/tools/run_tests.sh hint_player`, equivalent to `Godot --headless --path . --editor --quit` from Game, exited139 before any suite. Exact198663-byte raw log SHA256 `effac2b310a27c472845d20f7175dfd4ec35052c5f912919ffa433cf190f43ac`; no engine/script ERROR or backtrace. Last printed import is GochiHand-Regular.ttf; an unchanged retry completed setup and hint assertions. [Original log/source recovery](../recovered_original_20261110/README.md), [reconstruction](../recovered_repro_20261110/reconstruction.json), [analysis](../recovered_repro_20261110/original_analysis.json). Original pre-crash cache/stack remain unavailable. Similar observable failure does not establish an identical native cause.

Earlier recovered-source hint experiments separately emit historical audio-lifetime ERRORs; their overall results remain failed despite85/0 and exit0. They are not current audio regressions. The real imported-font probe avoids that unrelated teardown without bypassing mandatory setup, normal resource import or font loading.

## Engine boundary and next useful diagnostics

The version-pinned [FileAccess implementation](https://github.com/godotengine/godot/blob/4.7.2-stable/core/io/file_access.cpp#L961-L974) opens each path while computing a combined hash and continues after a failed open. The generic message does not identify the pathname. This locates the observed nonfatal errors at a file-open boundary; it does not explain native139. An upstream diagnostic build should record requested pathname/open error/importer and capture native thread stacks or a minidump on a fatal process, using a copy of the retained input and leaving red2 untouched.

[Godot issue125245](https://github.com/godotengine/godot/issues/125245) describes intermittent Linux Mono/C#4.7.2 headless import crashes with parallel import. Different OS/runtime and absent linked stack make it only a comparison lead. No match, threading workaround or production setting change is asserted.

## Owned mitigation and current acceptance

The scoped LF rule avoids checkout-only invalidation and its associated observed failures in these copies. All2939current canonical Game sidecars are already LF; no font/asset parameters, renderer or game settings changed. The mandatory runner fails closed on setup ERRORs even at exit0 and retains raw phase exits. [Actual-shell tests](unit_runner.txt):11methods total:10passed and one POSIX-only signal fixture skipped on Windows; original script/native/timeout protections remain. Warnings and expected suite diagnostics retain their prior scope.

Two LF comparisons and their controls are clean; the first red case verifies the real zero-exit ERROR guard, and the second preserves native139 rather than passing on a warm retry. The current-source cold focused gate FAILED and ran no suite: raw setup0 but one texture_2d_initialize ERROR at dummy texture_storage.h:85, so the new runner returns1. The active editor also autosaved project.godot; both original byte-source and full acceptance flags remain false. The complete-input warm continuation reports133/133 assertion passes with24raw errors (5intentional/19remaining), so raw-log integrity remainsFAILED. No global full pass, deterministic fatal mechanism or universal native crash repair is claimed.

## Separate current cold-import diagnostic

Frozen current revisionf9469d73/Gamee7759669 was materialized from canonical Git/LFS with a fresh project cache and isolated profile. [Record](current_gate.json), [complete raw archive](current_full/raw_logs.zip), [source manifest](current_source_manifest.json). Setup finished after361.625s at rawexit0 with one `Parameter"t"isnull` ERROR at texture_2d_initialize, [dummy texture storage](https://github.com/godotengine/godot/blob/4.7.2-stable/servers/rendering/dummy/storage/texture_storage.h#L85). Nearby GuideLight progress is not proof of the failed asset. This remains a failed cold import and is not attributed to the historical native139 or repaired by the LF rule.

The GoHUD editor plugin calls ProjectSettings.save during declaration. The resulting isolated project change reorders sections/keys and removes explicit renderer/rendering_method.web="gl_compatibility"; [Godot4.7.2 registers the same default](https://github.com/godotengine/godot/blob/4.7.2-stable/main/main.cpp#L2483). No authored production setting changed. The separately recorded warm collector records the exact config delta/hashes, qualify its derived configuration, verify all other committed source bytes and preserve the original failed state; it cannot turn this cold failure into a pass.

## Final versioned verification and remaining engine diagnostics

Complete-input frozenf9469d73/Gamee7759669 reports133/133 runner/assertion passes in5480.034s, with all source/support/save/preserved-state guards. This is not a clean raw gate:24suite ERRORs comprise5source-backed negative fixtures and19other diagnostics. Nine directory-open errors stack to isolated_storage.gd:29; one dummy texture error to care_round_runtime.gd:206; two p.d-null errors to chapter1_campaign_hud.gd:1652; seven teardown resource/allocator errors occur in campaign_session/chapter_select. File-access errors remain failed log-integrity observations even at exit0. Full raw archive and source-backed classification are linked in README/audit.json. No asset or native crash cause is inferred from these call sites.

After synchronizing the sole later export-hook source change, revision92e96a72/Game23550681 passes mandatory editor setup plus real font probe1/1,5/0,raw phases0 and0ERRORs. Its export callbacks are not invoked by the campaign tests; no release export/package was made. The full133run remains explicitly tied to its earlier source. The failed current fresh-cold ERROR remainsFAILED.

An independent final preservation rehash verifies10711native red2/baseline2files with0missing/extra paths or SHA/size/mtime changes. Earlier c8f0a6bc... hashes identify the198152-byte console launcher. The180858888-byte companion executable was additionally hashed before the merged recheck: ab1824f85bfd8e0e4128182c000c4003a3e042245b2967848d089b2a04b22424. This is a later measurement, not retroactive binary pinning for the earlier crash; the faulting image/module remains unknown without a native stack.

Independent final review accepts M1-85 completion as a bounded investigation under its owned-protection/actionable-engine-evidence alternative. The native cause/image and current cold/raw-integrity failures remain unresolved. Final sync added only two optional uninvoked capture/benchmark utilities; existing runtime/import code and133test suite list are unchanged. No clean global certification or external issue submission is claimed.
