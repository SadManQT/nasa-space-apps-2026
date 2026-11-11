# Independent merge-readiness review

Read-only reviewer assessed six commits unique to asif/class-provider-20261111@41a2bd07 against main@eb4a096f, merge-base52d78591.

Important: commit174c2e1e requires Class signatures for every non-P02 puzzle commit. The new class_team_plan_requested/sign_class_team_plan API has no production UI consumer (only campaign and bridge tests), so a fresh Class run would block at P01 calibrate_probe. M1-37 remains explicitly blocked until the UI consumer exists. M1-103/M1-105 docs say focused/full follow-up acceptance is pending. No duplicate implementation exists on main for these six commits.

Decision: preserve all six commits on the remote branch; do not merge an incomplete activation guard. Crew-query and preview corrections could receive a separately scoped review, but this merge audit does not take over Asif's active source reservations.

Historical origin/night/* branches remain archived per production/qa/evidence/M1-121/README.md. origin/sadman/m110-m111-media is superseded/archival per that audit's foreign_review.md. Existing local historical branches and WIP remain untouched.

The UI candidate received a prior read-only review. Its important missing developer-showcase finding was corrected; UI public signals/query/save APIs remain. Escape/large-text/lower-navigation/contrast checks were added and verified before integration.
