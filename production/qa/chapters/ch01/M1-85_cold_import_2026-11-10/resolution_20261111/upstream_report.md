# M1-85 upstream handoff draft - Windows editor import diagnostics

Prepared11 November2026; saved for review, not submitted externally. Historical native crash and the controlled nonfatal file-access observation are separate findings.

## Historical native failure (not newly reproduced)

Godot reported4.7.2.stable.official.ed1daf0bf. Original setup was the mandatory editor class-cache/import refresh in `game/tools/run_tests.sh hint_player`, equivalent to `Godot --headless --path . --editor --quit` from Game. It exited139 before any suite. The exact original198663-byte raw log has SHA256 `effac2b310a27c472845d20f7175dfd4ec35052c5f912919ffa433cf190f43ac`; no engine/script ERROR or native backtrace appears. The last printed reimport is GochiHand-Regular.ttf. Concurrent import progress cannot identify the failing asset. An unchanged retry completed setup and the hint assertions.

Original046662c reconstructed Game tree `f59fcc7b080618dc5388cf84c56fd5938ced76ab` has2568 files/902391503 bytes. [Exact log/source recovery](../recovered_original_20261110/README.md), [reconstruction](../recovered_repro_20261110/reconstruction.json), [original analysis](../recovered_repro_20261110/original_analysis.json). Original pre-crash cache and linked host native stack are unavailable. Exact original-host engine-binary/cache equivalence is not established. No crash cause or font fault is claimed.

## Controlled Windows metadata observation

This laptop uses the standard Windows console binary4.7.2.stable.official.ed1daf0bf, SHA256 `c8f0a6bc45a19b33541501e57f6f7cd972ab18453743266339d495cbbe846643`. [Hardware/driver and isolated paths](../recovered_repro_20261110/environment.json). Existing historical-source experiments with all nonimport source frozen showed a healthy import control, then960 CRLF-only sidecar checkout changes under `core.autocrlf=true`, then two setup file-access errors at `get_multiple_md5`, despite editor exit0. [Earlier exact raw setup](../recovered_repro_20261110/filtered_restore/runner_logs/setup.log). Its hint suite separately emits the historical audio lifetime error, so those earlier overall cases are failed and do not prove a clean runtime or native139 cause.

New [paired replay](replay_policy.py) uses a real imported-font probe to avoid that unrelated historical hint teardown. Separate original-red and candidate-green Git attribute contexts pin both GIT_DIR and working directory. They export identical logical metadata: original checkout gives CRLF, candidate `game/.gitattributes` preserves LF. Each pair starts as SHA-matched clones of the same retained warm project/cache/profile, runs a clean same-path control, restores only sidecar bytes, then runs the mandatory setup plus probe. Two baseline clones derive from one retained warm input; they are not independent cold-cache generations. Candidate files are declared and hashed in [run.json](run.json). Matrix results remain pending until complete; no repeatability claim yet.

## Engine boundary and useful next diagnostics

The version-pinned [FileAccess implementation](https://github.com/godotengine/godot/blob/4.7.2-stable/core/io/file_access.cpp#L961-L974) opens each path while computing a combined hash and continues after a failed open. Its generic message does not identify the failed pathname. This supports a file-open boundary for the observed nonfatal errors; it does not establish a segmentation-fault mechanism. An upstream diagnostic build should record the requested pathname, open error, importer and native thread stack at that boundary, and retain a minidump/backtrace for any fatal process. Preserve the failing cache/profile/source before retrying. A minimized fatal repro cannot be supplied without a new linked native failure or the original pre-crash state.

[Godot issue125245](https://github.com/godotengine/godot/issues/125245) describes intermittent headless import segmentation faults in Linux Mono/C#4.7.2 with parallel import. Different OS/runtime and missing linked stack mean it is a comparison lead only; no match or production thread-setting change is justified here.

## Owned mitigation and acceptance limits

The scoped metadata policy removes checkout-only CRLF changes without editing asset/font parameters, renderer or project settings. All2939 current canonical tracked Game import blobs are already LF. The runner now rejects setup ERRORs even at native exit0 and retains raw phase exits. Actual-shell regression tests preserve script/native/timeout guards and verify UID/file-access/ANSI diagnostics; warnings and expected suite diagnostics retain their prior scope. Paired mitigation verification, current-source mandatory/full results and independent acceptance review will be appended when measured. The historical native139 remains unproved; this handoff must not be read as a repaired native crash.

## Fresh linked native failure - resolution replay stopped

The second original/CRLF restoration now supplies a fresh native reproduction: setup and runner exit139 after16.614s, no suites,0engine/GDScript ERRORs and no backtrace. [Full raw setup](red2_restore/runner_logs/setup.log), [invocation and hashes](red2_restore/runner.json). Final printed imports are GochiHand-Regular.ttf, BarlowSemiCondensed-SemiBold.ttf, GochiHand-Regular.ttf; parallel progress still cannot identify the failing importer. The prior same-path control was clean5/0 at8.836s;960CRLF-only sidecar bytes were then restored. The first analogous red restoration had nonfatal file-open errors rather than a fatal exit, so fatal repeatability is one of two observed trials, not deterministic.

The collector stopped immediately and retains complete failed project/cache/UID/profile state locally. [Capture](native_capture.json) and [5359 post-crash file hashes/sizes/timestamps](native_inputs.json) link that state to this exact source, executable, script and command. Baseline2 and initially untouched green2 each have5352 files/1715305723bytes and match the recorded pre-control clone aggregate. This is a reconstructed pre-control input, not the exact cache at the instant before the crash; the failed snapshot is post-crash. No host-linked WER event or nearby Godot dump was found in the narrowly searched locations/time window; no native stack is available. No red2 retry is permitted. Green-only continuation/current-source full gate remain pending.

## Green-only mitigation verification

After complete post-crash preservation, a separately hashed collector ran only green2 control and LF restoration. Both are clean5/0, phaseexits0 and no raw errors; restoration changes0metadata bytes. [Continuation](green_continuation.json). Complete red2 post-crash file hashes were reverified unchanged afterward; it was not retried. The first green pair was also clean. This validates prevention of these two checkout-triggered failure paths in the observed copies; it does not prove every future native import safe. Current-source full acceptance remains pending.
