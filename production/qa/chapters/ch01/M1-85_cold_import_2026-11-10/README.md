# M1-85 - Windows editor-import investigation

## Latest recovered-source replay - 10 November2026

[Bounded exact-source investigation](recovered_repro_20261110/README.md) reconstructs originalGamef59fcc7b from recovered parent/patch. All8 focused calls show85/0 assertion markers/phase exits0 but remain FAILED on historical suite audio errors. The configured Git-filter restoration also emits2setup file-access errors despite exit0; copied retry has0setup errors. Original native139 remains unreproduced; no production fix/cause is claimed. Raw/source recovery is complete; remaining dependency is original pre-crash cache/host-linked native diagnostics or a fresh linked native failure. No supported native-crash fix is available from this pass.

The older reports below keep their recorded snapshot/status. Their former missing-original-log/source statements are superseded by [recovery](recovered_original_20261110/README.md); they are not current blockers.

## Earlier source-specific investigations (preserved)

10 November2026 - [new corrected-collector engine recheck](current_recheck_20261110/README.md): five cold/warm observations are clean; restoring tracked sidecars in a clean warm control produces285UID/file-access errors despite exit0/1of1. This is correctly FAILED for import integrity. Unchanged retry is clean, with no historical native-crash reproduction or cause identified. Only Steel_Normal differs beyond line endings in this new comparison; the older440-error/two-file comparison below remains at its separate frozen inputs.

All2493warm-input cache hashes and1190sidecar hashes still match the untouched QA source. The retained experiment copy is post-retry, not a frozen pre-error cache. Original full log/cache/backtrace are unidentified in the checked locations; the September minidump remains unlinked. M1-85 stays blocked on original or fresh failing native diagnostics.

## Earlier investigation evidence

10 November 2026, Tanvir. **Blocked: historical native crash not reproduced or diagnosed.** Bounded evidence and a reusable collector are delivered; no game, font, asset, renderer, runner, cache policy or timing threshold was changed.

The historical observation was a mandatory setup exit 139, with GochiHand-Regular.ttf the last printed import. The [published excerpt](../../../evidence/M1-64_setup_failure.txt) records the original 198,663-byte log's SHA-256 `effac2b310a27c472845d20f7175dfd4ec35052c5f912919ffa433cf190f43ac`; that complete log, native backtrace and original cache are unavailable in this checkout. The last printed filename is not a cause diagnosis.

## Controlled observations

Godot 4.7.2 official.ed1daf0bf on Windows 11 Home build 26300, Intel Core Ultra 5 226V / Arc 130V, driver 32.0.101.9150, about 16 GB RAM. [Engine hash, hardware and source](final/repro_state.json), [source/LFS payload manifest](final/source_manifest.json). Both project copies began with no `.godot` cache and isolated application data. The OS filesystem cache was not evicted. The collector verified local LFS payloads and used one copy at a time, with bounded invocation/termination and fresh log directories.

The cold matrix freezes **e11809d**, game tree **e687631faf17a0eab5a773ccfd981919129938a1** (3,206 files / 1,075,612,298 bytes / 1,197 LFS payloads). All direct editor and nested setup logs in this matrix have zero engine/script errors.

| Invocation | Seconds | Raw exit | Evidence |
|---|---:|---:|---|
| Fresh-cache direct editor | 250.848 | 0 | [raw log](final/native_first/cold_editor.txt), [record](final/native_first/cold_editor.json) |
| Unchanged warm editor | 4.578 | 0 | [raw log](final/native_first/warm_editor.txt) |
| Mandatory warm hint runner | 12.308 | 0 | [setup and suite](final/native_first/warm_runner_logs/); 1/1, hint 124/0 |
| Independent fresh-cache mandatory hint runner | 258.334 | 0 | [setup and suite](final/runner_first/cold_runner_logs/); 1/1, hint 124/0 |
| Unchanged warm hint retry | 12.235 | 0 | [setup and suite](final/runner_first/warm_runner_logs/); 1/1, hint 124/0 |

The supplemental comparison separately freezes **64a2d08**, game tree **d17b0474af0497de3bb53101a62db2dbfc7b4a42**. It copies only imported resources, UID/class caches and filesystem-cache metadata, not editor preferences, export credentials or saves. The [cache input manifest](sidecar_restore/cache_input_manifest.json) verifies 2,493 copied files. This is not the same source tree as the earlier matrix; each comparison is internally frozen.

| Supplemental mandatory hint runner | Seconds | Raw exit | Full log interpretation |
|---|---:|---:|---|
| Warm cache + generated-sidecar control | 42.947 | 0 | Setup has zero errors; hint 124/0 has 19 existing kit UID fallback warnings |
| Retain cache; restore tracked sidecars through Git checkout filters | 277.973 | 0 | **440 setup engine errors**, no script errors; hint 124/0 still passes |
| Unchanged retry | 12.160 | 0 | Setup and hint logs error-free; hint 124/0 |

All three runner summaries report 1/1. Those summaries do **not** establish clean import. The authoritative [full setup/suite audit](setup_log_audit.json) finds 422 UID errors (211 Unrecognized UID + 211 Can't find file) and 18 `f.is_null` errors in [restored setup](sidecar_restore/restored_sidecars_runner_logs/setup.log), with none in other setup/editor logs. The recorded engine boundary is resource UID lookup/reimport and `get_multiple_md5` at `core/io/file_access.cpp:967`. This is an observed import-integrity symptom, not the historical native crash.

[Restored metadata hashes](sidecar_restore/restored_sidecars.json) compare **post-control** bytes with restored bytes: 1,190 raw differences, of which only two differ after CRLF normalization (`T_Kit_Paint_ORM.png.import`, `T_Kit_Steel_Normal.png.import`). Errors also name the kit paint ORM LOD1 UID. These are investigation leads; this experiment does not isolate which metadata/cache interaction produces the errors. The known external-resource UID fallback paths identify Paint_ORM, Steel_Normal and Paint_ORM_LOD1. No asset or UID rewrite is justified by this evidence alone.

## Collector integrity and limits

The exactly executed scripts are preserved under [executed_scripts/](executed_scripts/) and match their recorded run hashes. Their original `all_runs_successful=true` fields audited only the short runner stdout. **That field is superseded by the complete setup audit for the supplemental comparison.** The original cleanup consequently deleted the supplemental scratch despite its hidden setup errors; the raw logs, source/cache hashes and sidecar manifests remain, but that cache copy was not retained.

The current [collector](cold_import_repro.py) now audits the runner's nested setup/suite logs before deciding whether a copy is clean or safe to delete. [Post-audit self-check](post_audit_selfcheck.json) verifies the actual 440-error log, an error-free control, detection of a stub nested error despite exit 0 / 1/1, and exact executed-script fingerprints. [Earlier bounded-process self-check](diagnostic_selfcheck.json) verifies timeout termination, overwrite refusal and independent log directories. These stub checks do not count as Godot runs. At the original publication the audit correction had only retained-log/stub checks. The newer current_recheck_20261110 now exercises it on five clean cold/warm runs and a real285-error restored-sidecar setup despite exit0.

[One preliminary attempt](preliminary_interrupted/) was intentionally stopped to finish collector review. It is explicitly labeled and excluded from crash/success statistics; it was not a game crash. Both final collectors completed without a native crash or timeout.

[Font identity](font_identity.json) proves current GochiHand font and import-sidecar Git blobs are identical to reachable historical ed86d7b. Identical bytes and today's successful import do not prove the font is innocent under every cache state, or identify a cause for the old failure.

To repeat, use `cold_import_repro.py --source-root <checkout> --revision <frozen-commit> --godot <console-exe> --scratch-root <disposable-directory> --output <new-evidence-directory> --timeout 600`. The sidecar collector takes the same arguments and reads the warm cache and generated sidecars from `--source-root`; choose a checkout whose warm imports match that frozen source. Run `--help` for its exact interface. Never overwrite retained evidence. Sources and user saves are read-only; failed or uncertain generated copies are retained by the corrected collector. No test setup guard is bypassed.

## Resume condition

M1-85 remains blocked until the original full log/cache or a bounded failing native reproduction supplies the importer/native boundary and supports an owned fix or an actionable upstream engine case. Preserve the existing fail-fast runner. The kit owner can investigate the named UID/cache consistency symptom using these manifests; a separate source patch, font deletion, engine downgrade or clean-cache workaround is not claimed. Full campaign regression results for the simultaneous Garden work are reported separately in [M1-122](../../../evidence/M1-122/README.md); they do not resolve this import incident. Manual QA, packaging and release work remain deferred.
