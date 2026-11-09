# M1-98 evidence review

Scope: `production/qa/evidence/M1-68_windows/2026-11-09_retained_ramim/` against board M1-98. Read-only review of the captured source IDs and original artifacts; current HEAD is not assumed to equal collection HEAD.

## Strengths

- The collector manifest records source `12d82528e1c6e89d7b0d076880767b5a6016547a`, game tree `108a384a95a17d5581e4d50b6a1c3e1ac08ea89b` (confirmed from that commit), Godot 4.7.2, hardware, workload/cache policy, two sequential mandatory-runner commands, exits, durations, and trace hashes. The README links the earlier Windows baseline.
- All 14 indexed raw files exist and match `artifacts.json` byte counts and SHA-256 hashes; no raw file is unindexed. Both collector manifest trace hashes match. Before/after fingerprints match for 3,178 tracked game files, including 1,190 import sidecars and 1,988 other files.
- Both fresh processes reached the final suite result: 581 checks with seven and six unchanged 50 ms timing failures. Each retained trace has 16 ordered measurement windows and 322 original stages with valid index ranges; all 37 retention checks pass. The complete logs preserve one ObjectDB warning per run and seven additional dummy-renderer RID/mesh errors in run 2. The report makes no cold-cache, idle-host, root-cause, or performance-fix claim.

## Issues

### Critical

None found.

### Important

None found.

### Minor

1. `README.md:21` says the run-2 RID errors include `LoadingCard._process47` in a backtrace. The retained `run-2/test_performance_runtime.gd.log:206-219` shows only native Godot `at:` sites; no retained raw artifact contains `LoadingCard`. Remove that backtrace attribution or add the original evidence that supports it. The seven errors themselves are recorded accurately.

## Declined to judge

- M1-68 root-cause diagnosis and optimization: this collection shows candidate regions only; stage durations cannot identify the exact longest heartbeat or be added as frame cost.
- Full game/performance acceptance: the two collected runs fail existing timing assertions; collection completion does not close that gate.
- Current worktree state after collection: later separate work can advance HEAD; the preserved source IDs and before/after fingerprints define this review's scope.
- Fresh engine or native runs: prohibited for this review.

## Assessment

**Collection evidence complete, with one documentation correction.** The requested two runs and raw diagnostics are preserved and verifiable. The README backtrace phrase needs correction before publishing this evidence as reviewed; M1-68 remains unresolved.
