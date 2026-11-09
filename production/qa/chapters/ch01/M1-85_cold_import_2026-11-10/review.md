# Independent review - M1-85

10 November 2026. Read-only second-AI review required by MASTER_PLAN section 10. Reviewer: separate OpenAI GPT-family agent `review_m1_93` (historical task name; review scope here is M1-85 only).

Final finding: no material issue in the report or corrected collector. Independently checked original/current collector fingerprints, executed script snapshots, source/cache manifests, current audit self-check, all 20 README artifact links and complete retained log counts. Confirmed 440 restored-setup errors (422 UID + 18 f.is_null), 19 warm-control suite warnings, separate frozen source trees and deletion of the supplemental scratch by the old outer-output success decision.

Earlier collector-review findings were corrected: bounded termination and abort-on-timeout, independent log directories, overwrite refusal, per-copy capacity checks, monotonic duration, native crash classification separate from generic engine errors, cache-copy hashes, clean-control prerequisite and normalized-text attribution. Final audit found the nested-log blind spot; executed scripts and raw records are preserved, the corrected collector now inspects setup/suite logs and the new retained-log/stub check passes. The full engine matrix was not repeated after that audit correction.

Recommendation: publish bounded evidence and keep M1-85 blocked. No historical crash cause, fix or full regression certification is established. Resume requires original/fresh failing native diagnostics sufficient to identify the importer/engine boundary. No other member task was edited.
