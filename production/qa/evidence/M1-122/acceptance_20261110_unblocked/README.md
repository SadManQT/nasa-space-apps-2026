# M1-122 / M1-123 acceptance reconciliation

10 November 2026, Tanvir/codex. The published integration dependency is cleared. **M1-122 and M1-123 are Done for their bounded implementation scope**, using the preserved geometry/input source, focused and native evidence, and the explicitly accepted combined119 result. No new gameplay, collision, movement, asset or settings edit is needed.

## Current published gate

Synced from the prior Tanvir publication abb80481 to integration closure1faf2d76 before this administration. Current committed game tree is `e5c5d5ed86b88301088451b472e6be747d57ae69`, identical to11722b7d,54be6a6f and87707938. The [accepted combined gate](../../M1-125_117_gate_2026-11-10/combined119/README.md) reports **119/119 suites passing,0 reported failures**, with all119 exact current suite names covered once across its accepted partitions.

This is the owner's recorded user-accepted Windows1-41 plus macOS42-119 result. It is **not one uninterrupted full-run invocation**: the Windows collection has no enclosing full119 final line/exit; the peer half used a sequential loop with runner-equivalent checks and did not publish raw suite logs. Those limits remain explicit. The Windows portion ran through `game/tools/run_tests.sh`; no bare editor exit is used as a test verdict. No game suite was rerun for this administration.

The [loading repair evidence](../../M1-125_117_gate_2026-11-10/raw_cleanup/provenance.json) includes two original-Windows fresh-process **618/0** checks through the mandatory runner, each ending **1/1 suites passed**, against the unchanged50ms limits. It supersedes the old615/5 loading blocker. The former frozen97/117 report and earlier comms-marker failure are historical evidence, not current failures.

## Task acceptance and retained evidence

| Requirement | Evidence and result |
|---|---|
| M1-122 excess geometry corrected; solid furniture retained | Delivered collisione5ed6178, currentLOC-03 unchanged. Preserved [native baseline20/3 to corrected20/0](../README.md#recorded-8edef-verification), inspected paired campaign captures and positive enclosure assertions. |
| Meaningful collision and Chapter1 route coverage | Current accepted gate reports collision19/0, habitat_rooms360/0, Chapter1 campaign flow508/0 and player105/0. Habitat coverage checks navigation/door approaches and door-state collision; it is not input-driven crossing of every doorway. |
| M1-123 actual controller contact and center recovery | Preserved [ordinary native62/0](../../M1-123/current_pilot_20261110/README.md): actual saved campaign EX-CH01-S11/LOC-03, BLOOM and MISSION_STOPPED, keyboard and gamepad events, four grounded stopped arrivals within25cm. Eight inspected current-refinement PNGs and input/collider/camera traces retained. |
| Regression preserves normal physics and mission state | Current accepted movement54/0. Production capsule0.27m, world+crew mask3, solids, camera and mission/resource guards retained; no recovery teleport, velocity write or global controller edit. Driver correction stays within360sampling iterations. |
| Integrated mandatory coverage | Accepted combined119 on the identical current game tree, plus two original-Windows618/0 performance results. See qualifications above rather than an invented single-run summary. |
| Independent acceptance review | [Review](review.md), required by MASTER_PLAN section10. No remaining scoped acceptance gap found. |

The native evidence remains tied to its original source base df7b435e plus the recorded approved pilot bytes, Windows/Arc130V, Godot4.7.2, Compatibility1280x720. The verifier confirms LOC-03, collision test and player_controller Git blobs are unchanged from that native base and the recorded pilot SHA matches current bytes. Later campaign/loading code is qualified by the accepted current gate; the old native capture is not relabeled as a fresh current-tree capture, physical-controller test, Forward+ qualification or manual playthrough.

The original screenshot transform/input/yaw was never recorded. The evidence establishes measured excess-volume correction and recovery from recorded candidate contacts in the production campaign, not an exact historical replay or proof against every possible trap. Both optional10FPS diagnostics retain54/0 movement assertions **and79shader-cache errors each**, so remain failed for log integrity. The earlier62/1 native failure is preserved. None is erased by closure or called a game-wide rendering fix.

## Evidence verification

[Validation script](validate_acceptance.py) checks119 current suite names/order, identical committed game trees,77 published Windows raw hashes,274 existing scoped artifact hashes/sizes, two618/0 loading logs/traces, and the original62/0 native four-case trace/eight PNG hashes. [Machine-readable result](validation.json). This is read-only evidence reconciliation; no game process, cache conversion, save mutation or repeated full gate is performed.

## Remaining work: M1-85 only

**M1-85 remains blocked.** The runtime loading cleanup/full119 acceptance does not reproduce or diagnose its historical editor-import exit139. Its [bounded cold/warm report](../../../chapters/ch01/M1-85_cold_import_2026-11-10/current_recheck_20261110/README.md) retains five clean cold/warm observations, restored-sidecar285UID/file-access errors despite exit0 (correctly failed), and a clean unchanged retry. The last printed font and unrelated September dump do not establish cause.

Dependency/owner: original reporting host/SDD-artifact holder (filed Ramim/codex), with Tanvir owning the follow-up. Resume on the original198663-byte raw log/cache/backtrace or a new bounded native failure with source/cache/diagnostics. Original raw-log SHA: `effac2b310a27c472845d20f7175dfd4ec35052c5f912919ffa433cf190f43ac`. Preserved input-cache/sidecar manifests and exact collectors remain saved; the old QA baseline is untouched. No unsupported asset/configuration repair is made.

Manual QA, videos, submission, release packaging and separate platform qualification remain deferred. No extra task is claimed. Other members' rows, exact reservations and unfinished source are preserved. Only task handoffs, board status and repository-required handbook/AI attribution are updated.
