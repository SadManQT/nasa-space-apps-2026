# M1-85 - exact recovered-source import investigation

10 November 2026, Tanvir/codex. **This bounded diagnostic pass is complete; the original native editor-import crash remains unresolved. The remaining diagnostic dependency is recorded below.** No production Game source, asset, font, renderer, setting, threshold or saved player data was changed. M1-122/M1-123 remain Done; the player's withdrawn obstacle report is separate.

## Recovered inputs and reconstruction

The [recovered original artifact](../recovered_original_20261110/README.md) is exactly198663bytes/SHA `effac2b310a27c472845d20f7175dfd4ec35052c5f912919ffa433cf190f43ac`. It shows editor setup exit139 before any suite and emits no backtrace or engine/script ERROR. GochiHand-Regular.ttf is the last printed import, which does not identify the failing asset or cause. [Original-log analysis](original_analysis.json).

Published parented86d7b plus the recovered complete source patch reconstructs original046662c's exact committed Game tree `f59fcc7b080618dc5388cf84c56fd5938ced76ab`:2568files/902391503bytes. [Reconstruction proof](reconstruction.json), [source/LFS payload manifest](source_manifest.json). Reconstruction used a private ignored Git object store/index; no main index, branch ref or source file was replaced. [Exactly executed preparation code](executed_prepare.py) matches its recorded SHA; later corrected execution collectors remain separate.

This laptop ran Godot4.7.2.stable.official.ed1daf0bf, executable SHA `c8f0a6bc45a19b33541501e57f6f7cd972ab18453743266339d495cbbe846643`. [Hardware, driver, isolated paths and script hashes](environment.json). Matching the reported version is not proof of original-host/binary/cache equivalence. The original pre-crash cache and linked native stack are unavailable here; the original-host cache-backup pathname in the recovery map does not exist on this machine.

## Focused results - all overall cases failed log integrity

Every call used the unmodified historical `game/tools/run_tests.sh hint_player`. The historical runner deletes successful setup/suite logs and ignores TEST_LOG_DIR. The [logging adapter](godot_log_shim.sh) forwards the unchanged Godot arguments/exits and retains those discarded raw logs. I/O plumbing and timing differ from an uninstrumented launch. Three [negative self-checks](collector_selfcheck.json) verify an ERROR hidden behind exit0/1of1, nonzero exit7 propagation and script-error fail-fast. They are stubs, not engine runs.

All8 real calls print hint85checks/0assertion failures and1/1 suites passed; both editor and suite phase exits are0. Each suite nevertheless emits1-2 historical audio lifetime ERRORs, so **every overall case remains FAILED**. No native editor setup exit139 was reproduced. No bare exit code or pass marker overrides raw errors.

| Case / directory | Seconds | Setup / suite exit | Setup ERRORs | Suite ERRORs | Overall raw-log verdict |
|---|---:|---|---:|---:|---|
| cold | 274.964 | 0 / 0 | 0 | 1 | FAIL |
| warm | 17.041 | 0 / 0 | 0 | 2 | FAIL |
| clone_control | 14.043 | 0 / 0 | 0 | 2 | FAIL |
| restored | 38.831 | 0 / 0 | 0 | 1 | FAIL |
| retry | 17.678 | 0 / 0 | 0 | 2 | FAIL |
| filtered_control | 17.917 | 0 / 0 | 0 | 2 | FAIL |
| filtered_restore | 290.326 | 0 / 0 | 2 | 1 | FAIL |
| filtered_retry | 17.206 | 0 / 0 | 0 | 2 | FAIL |

The13 suite errors all have the same historical line: `Resumed function '_stream()' after await, but class instance is gone`, audio_director.gd:283. ObjectDB exit warnings are also retained. They occur in the hint-suite phase after its85/0 marker; they are not the original editor-import crash. Current main already has a different delivered RefCounted stream-task implementation, so this investigation makes no historical/current audio repair or extra claim.

## Protocols and limits

1. [Original corrected collector](recovered_repro.py), [stopped execution](execution.json): first fresh-project-cache import completed with0setup errors; suite audio ERROR triggered the strict stop. Original failed project/profilea is retained untouched. Its planned same-path warm case did not run; collection_complete remainsfalse.
2. [Separate phase-qualified continuation](continued_repro.py), [state](continuation.json): copya Game/profile tob, run copied warm and repeat/pre-restore control (directoryclone_control) on the sameb/profileb. Import controls require setup0/no setup errors,85/0 and1/1, no native/script failure, and no suite ERROR other than the exact observed audio line. Any other error stops progression; all audio errors still make the overall verdict fail. Restoring960 raw committed sidecars changed0bytes, so it was a content no-op. Copied retryc has a different absolute path; it is not a same-path historical retry.
3. [Final configured Git-filter variant](filtered_repro.py), [state](filtered_continuation.json): copyb Game/profile tod; healthy import control and restoration share d/profiled. Current and private-original attribute queries for all960sidecars are identically empty; unchanged local core.autocrlf=true produces960CRLF-only differences,0non-CRLF differences. This is the observed local checkout conversion, not proven original-host settings/cache equivalence. Retry copies both Game/profile toe at new absolute paths.

The filtered restoration reimports960assets and emits exactly2setup errors: `Condition "f.is_null()" is true. Continuing.` at `get_multiple_md5 (core/io/file_access.cpp:967)`. [Full raw setup](filtered_restore/runner_logs/setup.log), [complete invocation](filtered_restore/runner.json). There are0UID and0SCRIPT errors. Exit0 and85/0 do not clear this failed import. The copied retry has0setup errors while retaining its separate suite audio errors.

This is one preliminary upstream file-access observation with a healthy import control and a CRLF-only restoration sequence. Repeatability of that error count is unmeasured; it is not a reliable native139 reproduction or its cause. Nearby OGG/texture progress lines are interleaved and do not identify the file that failed to open. The original crash stopped at the first printed import; these nonfatal file-access messages appear later in the batch. No font, compression, UID, mipmap or renderer cause is inferred.

## Retained evidence and automated verification

All5 project/profile copies stay local under the ignored scratch root. [a/b input hashes](retained_inputs.json) and [b/d input hashes](filtered_retained_inputs.json) cover imported-cache, sidecar, generated UID and profile state. Source guards permit engine-generated import-sidecar changes only; all tracked non-import source bytes remain frozen. The retaineda/b andb/d hashes still match after their copied retries. Original user-save SHA remains `7500982b1be85d08848421a6e1d3b4386c344a59d6a74f05a7b8504e77d47b51`; raw saves, caches, profiles and dumps are not committed.

[Artifact manifest](artifacts.json) and [independent verifier](verify_evidence.py), [audit result](audit.json). The verifier checks all raw artifact/script fingerprints,8case/16phase outcomes, strict ERROR accounting,960file deltas and optional local retained-state/save hashes. [Independent review](review.md). Exact scripts/commands are evidence for the recorded protocols, not a one-command minimal native-crash repro; collectors deliberately refuse existing outputs. A repeat needs a fresh evidence layout and ignored scratch directory.

**Full-suite coverage is separate:** no new full current-campaign gate was run for this source-only historical diagnostic. The previously [accepted combined119](../../../../evidence/M1-125_117_gate_2026-11-10/combined119/README.md) belongs to game treee5c5d5ed across two hosts and predates newer main/UI changes. It is not relabeled as a fresh current-tree or originalf59 full pass. All8 calls here are focused historical hint-runner observations.

## Precise remaining blocker and resume

Task **M1-85, Tanvir**. Saved work: exact recovered source/log reconstruction, three negative self-checks,8focused observations, the original stopped failure and two distinct continuations, complete raw phase exits/arguments/errors, preliminary2-error file-access case, retained input hashes and user-save/source guards.

The missing-raw-log/source wait is resolved. The remaining blocker is a supported reproduction/linked native diagnostic for the historical editor-import139. The single nonfatal file-access observation does not supply its cause. Dependency/owner: original reporting host/artifact holder (Ramim/codex) for pre-crash import/cache state or host-linked native diagnostics; Tanvir owns continuation. The later `import-cache-fc3a3ddc.json` pathname in the recovery map is only a lead. Resume when that state can be inspected or a fresh native failure is captured with exact source/cache, phase exit and backtrace/dump metadata before retry.

No speculative production fix or further unrelated variant is justified by this pass. Manual QA, videos, release packaging and submission remain deferred. No outside task is claimed. The shared handbook has an actual active M4-20/Ramim reservation, so its proposed status paragraph is saved in [handbook handoff](handbook_handoff.md); that file is left untouched while reserved.
