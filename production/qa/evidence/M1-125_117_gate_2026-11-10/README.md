# Integrated117-suite repair -10November2026

The user explicitly authorized Ramim to override former folder/task owners for this integration repair. Existing peer commits, claims and saved WIP remain preserved. Videos, submission, release packaging and manual qualification remain deferred.

## Current gate

The frozen original-Windows baseline at `daa0141` ran all117suites: **98/117passed**, with complete setup/suite logs in [baseline_daa0141](baseline_daa0141/provenance.json). The Chapter1UI null-instance failure was stopped and retained as a failure. No full117pass is claimed by the focused results below.

Machine: Windows, Ryzen7 7700, RTX4060,32GB. Engine: `4.7.stable.official.5b4e0cb0f`. Thresholds, including the50ms loading heartbeat, remain unchanged.

## Published repairs and focused verification

| Change | Published commit | Actual focused evidence |
|---|---|---|
| Chapter6/8 entry follows the authored P09/P10/P13/P14 data and public puzzle witnesses |5ad5017| [Mission/puzzle suites](focused_chapters/provenance.json):116/0,132/0,59/0,110/0 |
| Probe fixtures complete rack-to-bench transfer before dry-zero; briefing focus visits every assistance option |aa632b2| [Five UI suites](focused_ui/provenance.json):102/0,42/0,322/0,63/0,170/0 |
| Nameplates mount existing bench faces; mug lettering faces an accessible approach; restaging preserves only the two canonical Chapter1plates |5d13dc0| [Five prop/room suites](focused_rooms/provenance.json):81/0,3603/0,4717/0,2837/0,3579/0 |
| Indoor Moon gravity; string-key upgrade saves; close the upgrade modal before committing the next chapter profile |c9bf18f| [Real campaign/HUD handoff](focused_handoff/provenance.json):140/0,82/0,508/0 |
| Native probe/MissionTable captures follow physical prerequisites and close first-use teaching before table input |0c985a4| [Native panels](native_ui/provenance_panels.json):34probe captures/0; MissionTable0failures |
| Text/native goal walks use public puzzle inputs and earn/save upgrades at each chapter boundary |246a1f8| [Text/native goal evidence](text_walk/provenance.json): engine13092/0; native627/0 |

The text engine completed8chapters/96scenes and283later jobs. Its enclosing long-running shell was changed during the run and ended with a shell error. That invocation is **not** a clean runner/full-gate pass; final verification must use immutable source.

Scripted native evidence exercises actual windows, pixels and injected keyboard/mouse/controller events. It does not certify manual playthroughs, physical-controller input, low-spec hardware or unavailable original Arc/native-host blockers. Selected PNGs were inspected directly; original capture sets remain saved in the isolated worktree.

## Remaining verification

- All128upgrade profiles through96real scenes now pass130308checks/0failures in8independent engine batches. The original serial1500s timeout is retained. [Complete coverage and runner evidence](profiles_runner/provenance.json) includes9runner tests/0failures/1POSIX-onlyskip and real Windows descendant cleanup. Its bounded correctness guard is separate from runtime performance assertions.
- Reproduce and repair original-host loading failures. Instrumented diagnostic615checks/2fails measured newcampaign98.431ms and terrain59.351ms during concurrent CPU model testing. A synchronous92.072ms HUDsetup span is confirmed; split setup, trace retention and exact descendant cleanup remain saved/unqualified until measured.
- Run two controlled fresh-process loading checks, then a fresh frozen `game/tools/run_tests.sh` over all117suites. Retain every failed attempt and the eventual source-specific result.
- Close board acceptance rows only after their declared dependencies and actual full gates pass. Unrelated native/raw-loader/profiling blockers remain separate.
