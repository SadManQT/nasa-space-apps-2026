# M1-85 original artifact recovered

The user asked Ramim to remove this blocker. The exact original7November failure log has now been found on the reporting machine in the preserved `nasa-ramim-20261106/.superpowers/sdd/2026-11-06-ramim-continue` folder.

- [Full original setup failure](original_setup_failure.txt): **198663bytes**, SHA-256 **effac2b310a27c472845d20f7175dfd4ec35052c5f912919ffa433cf190f43ac**, exactly matching the value Tanvir was waiting for. Original bytes, including ANSI output, are retained.
- [Existing unchanged retry](unchanged_retry.txt): hint85/0,1/1 suites. This is the historical retry; no new test was run.
- Original commit `046662cf278bd8b30ac5cbdcbbbafc08f00c61aa` is also present locally, directly on published parent `ed86d7bb596a93b8811f5c0849ae9078d65dc98a`. [Complete original source patch](original_source.patch) makes that exact committed source reconstructable without relying on the old local object. Game tree: `f59fcc7b080618dc5388cf84c56fd5938ced76ab`. The patch is evidence only and was not applied to the current game.
- [Later rebase map](later_rebase_map.json) preserves the subsequent cache-metadata backup pathname and historical commit mapping. It is a diagnostic lead; no original cache has been recovered from that reference.

**M1-85 is unblocked to resume investigation (Todo), still assigned to Tanvir. It is not marked fixed or Done.** The previous wait for an unidentified original raw artifact is resolved. Tanvir can inspect this exact failure, reconstruct its committed source from the published parent, and continue the existing bounded collector in an isolated copy. No need to wait for Ramim to supply the raw log.

The log confirms native setup exit139 with no suites executed and no emitted backtrace. The last printed import is GochiHand-Regular.ttf; that does not identify the cause. The original pre-crash import cache and a linked native backtrace remain unavailable. If another failure reproduces, retain its complete source/cache/native diagnostics before retrying. No production source, font, import metadata, renderer, engine setting, threshold or saved player data was changed.

Earlier Tanvir experiments and all failures remain preserved in the sibling `current_recheck_20261110` folder. Their clean cold/warm attempts and UID-integrity failures are not rewritten as a historical crash fix. `provenance.json` records exact hashes and limits.
