# M1-97 source review

Range: `415aa2330182b38e282384724ddc562d27237b0f..0bbb7d2f2e9319f5e1545109ffacafb81585ddae`
Scope: opt-in performance trace retention and collector metadata. Read-only source and saved-artifact review; no engine run.

## Strengths

- `game/tools/test_performance_runtime.gd:113-128,247-300` records the existing 16 measurement windows, then writes the original `LoadTrace.steps` after measurement. Existing interval assertions remain in place. The report explicitly says stage records lack timestamps/thread IDs and that nested/background durations are not additive frame costs.
- `production/qa/perf/collect_loading.py:57-60,91-104` records source and game-tree revisions, keeps trace path/byte count/SHA-256 for each opt-in run, and fails collection if a requested trace is absent or unreadable. Its injected-runner tests cover successful and failed suites, missing trace, and the default path.
- Saved final trace contains 16 windows and 272 stage records, including the terrain exterior window. Saved runner result: 580 checks, two unchanged title/new-campaign interval failures (54.825 and 98.655 ms), with all 37 retention checks passing. Three Python tests and four scenarios pass. The one-ULP JSON readback difference recorded in the precision diagnostic is 1.4e-14 ms; the final 1e-9 ms comparison is below the 0.001 ms timer resolution. `git diff --check` is clean.

## Issues

### Critical

None found.

### Important

None found.

### Minor

None found.

## Declined to judge

- Existing production title/new-campaign timing failures: measured and retained, but optimization belongs to M1-68; this diff does not change the loading path or its 50 ms gate.
- Absolute timing comparison across hosts or cache states: the artifact documents process-relative clock and existing-cache policy, not a cold-cache claim.
- Fresh Godot/native execution: prohibited for this review; conclusions use saved runner, trace, and collector-test artifacts.

## Assessment

**Source ready to merge: Yes.** The opt-in trace keeps the requested windows and original stage records with provenance and explicit measurement limits. **Performance acceptance remains failing** on two unchanged 50 ms assertions.
