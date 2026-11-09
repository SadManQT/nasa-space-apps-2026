# M1-08 independent source review

Reviewed `b2075e7b3949627bfec85718a3f1f58c3301a8c7..948ef2f` against board M1-08, `execution/PUZZLE_P01.md`, `execution/UI_09_SCIENTIFIC_PUZZLE.md`, the P-01 profile, mission adapter, campaign forecast/physical commit contract, HUD caller, tests, and native capture record. Read-only source review; no source, index or HEAD changed.

## Findings

**Important — The observed and projected columns cannot show the result of scan or label actions.** `game/scripts/ui/p01_panel.gd:310-313` renders only reference numbers, calibration phase, seed counts, moisture and seal state. It omits `packet_scanned`, `alo_label`, `tara_label` and completion even though `P01CommissionPlant.view()` supplies them. Consequently a successful forecast for packet scan or either label displays the same projected data as the observed column; compare `M1-08_label_alo.png`. A generic “Prediction accepted” notice and the action title do not show what changed. This misses UI09's observation/result feedback and P-01's distinct label evidence. Include the relevant state in both readings (or a concise action delta), with a test that projected scan/label differs visibly from observed and the committed result is visible.

**Important — Label selection is still a one-answer gate.** `game/scripts/ui/p01_panel.gd:192-193,266-282` treats label actions as simple actions and `_render_inputs` provides one button whose text already names the correct label. The player cannot choose the other label, see why it is wrong, or test the distinct-label hypothesis. `game/scripts/missions/p01_commission_plant.gd:159-166` likewise receives no label choice to validate, so this needs coordination with the Atik-owned rule contract rather than a panel-only fake choice. The board explicitly calls for chosen values and wrong hypotheses; P-01 says to select EXTERNAL TEST for Alo and INDOOR REFERENCE for Tara. Add a real label choice to the shared forecast/commit payload path and test both wrong and correct selections.

**Minor — The “Observed data” heading describes target reference values as already observed.** `game/scripts/ui/p01_panel.gd:310-313` always prints `dry raw 10 → 0; wet raw 110 → 100` from the static profile, including while `probe_zeroed` is false (see `M1-08_calibration_unset.png`). The profile's calibrated numbers are expected outcomes, while the source initial observation is raw dry 10/wet 110 with an offset probe. Label these as reference targets until the relevant zero/span/recheck step has actually been performed, or show current calibrated readings by calibration state. This matters to the first-use comprehension report on the board.

## Integration risk outside this diff

Native E ownership remains unresolved in current source: `Chapter1Campaign._unhandled_input` calls `interact_nearby()` (`game/scripts/campaign/chapter1_campaign.gd:608-616`), while `PlayerController._physics_process` separately polls the same `interact` action and calls its generic `interact()` (`game/scripts/player/player_controller.gd:239-240,290-294`). The new HUD hookup opens the panel, but these two consumers can still produce the reported generic Inspect pose from one E press. M1-107 owns the fix and its required genuine production-input regression. The reviewed tests and capture call `campaign.interact_nearby()` directly, so they do not resolve this risk.

## Evidence and limits

- `git diff --check` on the reviewed UI, scene and panel test files: exit 0.
- Inspected `game/tools/test_p01_panel.gd`, `test_p01_inputs.gd`, `test_p01_nearby.gd`, `test_player_text.gd`, and `capture_p01_panel.gd`. The panel suite asserts explicit calibration, inclusive/fractional moisture, stale forecast rejection, physical range rejection/retry, dirty leave, pause, duplicate receipt and save/restore. It does not assert visible packet/label deltas or a wrong label choice.
- Existing `.superpowers/sdd/2026-11-09-message-integration/M1-08_native4/native.txt` reports `M1-08 CAPTURE RESULT: PASS (29 captures, 0 failures)`. `production/qa/evidence/M1-08_capture_probe.txt` has 510 PASS records. The parent verified capture input and PNG hashes against the frozen source. These are inspected artifacts, not a test execution by this reviewer.
- Declined to certify full-suite acceptance, live E input ownership, real controller hardware, audio timing, or the entire eight-screen player-text walk. The parent owns the integrated batch and native E follow-up.

**Verdict:** C0 / I2 / M1 in the reviewed source. The panel has a real campaign connection and substantial focused evidence, but the two Important feedback/choice gaps need resolution before calling M1-08 source-ready. Full production acceptance also depends on M1-107 and the integrated batch.
