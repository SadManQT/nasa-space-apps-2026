# M1-115 source review

Range: `d35c3bfa7e90e35523873a84640ac7895e43cbf8..51f91cb8f2f6c1d7538679d74315373b04918140`
Scope: P-01 label payload contract, profile, fixtures, and tests. Read-only source and saved-runner review.

## Strengths

- `game/scripts/missions/p01_commission_plant.gd:159-186` validates an explicit String label against the profile before preview or commit and stores the chosen payload. The existing receipt lookup at lines 89-100 still accepts old duplicate calls before new validation.
- `game/scripts/missions/chapter1_route.gd:436-451,487-505` previews through that model before Director commit and applies the P-01 flag only after an accepted model commit. The campaign forecast uses a restored route's same `perform` path, so rejected labels cannot create live flags, resources, or receipts.
- `game/tools/test_p01_labels.gd:15-71` covers nine bad inputs for each label, preview purity, committed chosen values, real route rejection and flags, duplicate replay, and legacy primitive JSON restore. The shared test fixture supplies both target and action aliases. Saved mandatory runner results show behavioral RED (104 checks, 38 failures), then GREEN across labels/inputs/nearby (104+317+29 checks, zero failures; 3/3 suites), plus Chapter 1 logic regressions (34 checks, zero failures). `git diff --check` is clean.

## Issues

### Critical

None found.

### Important

None found.

### Minor

None found.

## Declined to judge

- M1-08 P-01 UI choices and label-selection presentation: separate saved branch, outside this contract range; this review does not certify a complete player flow.
- Full integrated runner and native UI: pending; only the recorded focused and Chapter 1 logic suites were assessed.
- Existing ObjectDB leak warnings in the focused runner: disclosed in saved logs, outside this diff.
- Fresh Godot execution: prohibited for this review; assessment uses saved `run_tests.sh` artifacts.

## Assessment

**Source ready to merge: Yes.** The narrow contract enforces an explicit correct label without breaking old stored strings or receipt replay, and the real model and route tests cover the failure paths. Full game acceptance still depends on the separate UI work and integrated runner.
