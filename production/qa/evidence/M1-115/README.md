# M1-115 ? actual cassette label choices

9 November2026, Ramim executing Atik task. Source51f91cb.

P01 profile/view contract2 publishes `labels.alo=EXTERNAL_TEST` and `labels.tara=INDOOR_REFERENCE`. Existing model preview/commit requires explicit String payload.label; missing, wrong or malformed choices reject atomically. Successful commit stores that selected label. No production defaults. All canonical numeric rules, saved primitive label values, route action/receipt IDs and old duplicate receipt replay remain unchanged; no save-schema migration.

Ramim UI should offer both label values for either cassette, send the actual choice, and show packet/label state in before/after readings. M1-08 candidate948ef2f remains preserved locally; it has not been published. It must be updated against this contract before acceptance.

Behavioral RED104/38 -> GREEN labels104/0, existing inputs317/0, nearby29/0 (`3/3 suites passed`); additional Chapter1 logic34/0 (`1/1 suites passed`). Tests cover nine missing/wrong/type cases for both labels, pure forecast/commit identity, real route flags/resources/receipts, duplicates and legacy primitive labelled JSON/receipt restore. Independent source reviewC0/I0/M0. Existing ObjectDB warnings remain in the physical suites; no clean-engine or full/native/UI acceptance claim. Integrated full runner pending batch; raw setup/manifests retained privately.
