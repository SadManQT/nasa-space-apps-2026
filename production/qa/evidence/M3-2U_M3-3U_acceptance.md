# M3-2U and M3-3U: upgrade choices after Chapters 1 and 2 (10 Nov 2026, Sadman / Claude Code)

Taken over from Asif's row on Sadman's instruction (nobody held these tasks or their files).

## What was missing
The choice flow and all four modifiers already existed (CadetProgression, CampaignProgressionFlow, ExpeditionSimulation). Two gaps:
1. The Option B card said fuel cell capacity "20 to 22". The spec (game-design/10, execution/UPGRADE_AFTER_CH01.md) and the simulation say cap +6 (26) and entry charge +4 (14 to 18). Card fixed in `game/scripts/progression/cadet_progression.gd`.
2. No test proved the Chapter 1 and 2 pairs or their numbers.

## Proof (game/tools/run_tests.sh)
- New `test_upgrade_pairs_ch1_ch2.gd`: PASS, 35 checks, 0 failures. Both pairs are earned only after their chapter, exclusive, idempotent, saved and restored, synced from the campaign snapshot, and only the chosen option becomes gear. Through the simulation: taller mast +2 daylight (14 to 16) and none at night; red-blue LEDs FULL costs 1 instead of 2 (E 5 to 6) and DIM unchanged; insulation blankets remove COOL damage (H 5 to 6) but not COLD; fuel cell cap 20 to 26 and +4 entry charge at the next chapter entry. The cards state those numbers.
- Related suites on the same tree: test_progression 72/0, test_campaign_progression 22/0, test_upgrade_pairs_ch4_ch6 34/0, test_campaign_field_systems 14/0, test_player_text 13092/0 (1/1 suites passed), together with the accepted combined 119/119 gate (M1-125).
- Screenshots (inspected): `M3-2U_upgrade_after_ch01.png`, `M3-3U_upgrade_after_ch02.png`.
