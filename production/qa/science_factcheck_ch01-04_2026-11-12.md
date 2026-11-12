# Science fact-check, Chapters 1–4 (M3-75), 12 Nov 2026

Checked all Chapter 1–4 player text against the NASA data fixtures in `game/resources/data/nasa/`, `docs/SCIENCE_AND_DATA.md`, `game-design/16_SCIENTIFIC_ACCURACY.md` and `game-design/08_PUZZLE_DESIGNS.md`:
- **Text checked:** `ui_text.json`, `journal_text.json`, `messages/ch01–ch04`, `mission_data_cards.json`, the P-03 to P-06 content files, `chapter4_puzzles.json`, `how_to.json`, the science explainer captions, and the CH01–CH04 dialogue.
- **Who checked:** Sadman/claude, with a read-only audit agent.

## Fixed

| # | Where | Was | Now | Source |
|---|---|---|---|---|
| 1 | `messages/ch02.json` message 18 | "May 1 to May 6 pollination log" | "30 April to 6 May" | `fast_plants_lifecycle.json` p03_run_days (30 Apr – 6 May); P-03 runs 30 Apr, 3 May, 6 May |
| 2 | `mission_data_cards.json` EX-M0303 | "Alo's pods ripen on 16 May" | "full-size on 16 May (Aurora's story calendar is compressed; real Brassica pods take about 20 days after pollination)" | `fast_plants_lifecycle.json` pod_maturity_days_after_pollination = 20; SCIENCE_AND_DATA P-06 keeps day 35 on purpose |
| 3 | `ui_text.json` station field Z and `verify_exposure_order` | "Radiation dose", "Check the radiation dose", "Dose checked", "Dose first" | "Exposure (game score)", "Check the exposure score", "Exposure checked", "Exposure first" | EX-M0104 limits: "exposure Z is a game score, not a real radiation dose"; `clowdsley_2021_shielding.json`: game zaps are not mSv |

## Reviewed and kept

| # | Where | Finding | Decision |
|---|---|---|---|
| 4 | `journal_text.json` J-CH01-S09-NOW title "The Horizon Closes One Door" | Could suggest an Earth-set; the cutoff is an authored drill | Kept: it is the canon scene title in `full-game-story/STORY_FULL.md` (canon order rule). The entry body and the sibling entry already call it a link cutoff drill. |
| 5 | `sci_proton_flux_chart` caption 2 | pfu given as "protons per square centimetre, each second" without "per steradian" | Kept as an age-appropriate simplification; the Data Card EX-M0104 gives the full unit ("from one patch of sky"). Changing it would mean re-recording the narrated clip. |
| 6 | `sci_polar_sun` caption 6, `sci_cold_traps` caption 4 | "smaller than your thumb" follows the 3.1° range; Diviner −235 °C is an estimate | Kept: the line before says "just a peek above or below" (each peek ≤ 1.6°, under a thumb's ~2°), and the cold-trap clip's next caption says "That number is an estimate for one spot." |

**Known gap, documented:** `sci_laser_mapping` gives the computed road to the cold trap as 8.6 km, while P-07 Route B is 12 km. The fixture records that the game keeps 12 km on purpose (a longer surveyed route). No player line explains the difference yet.

## Confirmed correct (sample)

- **2017 storm:** X8.2 flare at 15:35 UTC; 10 pfu crossed at 16:45 (70 minutes later); peak 1,493.5 pfu; GOES-13 altitude.
- **Polar Sun:** −1.56° to +1.59°. The 36-hour night is 5 × 7.2 h, sized to Mazarico (2011).
- **Earth below the horizon:** 15–28 April 2046.
- **BVAD per person per day:** 0.895 kg O₂, 3.2 kg water, 0.8 kg food.
- **Brassica rapa:** OSDR mizuna, 27 days on the ISS. Fast Plants flower at about 14 days and set seed at about 40. Mir hand-pollination, 122 days.
- **Moonquakes:** 28 shallow quakes, the largest magnitude 3.2, on 13 March 1973 near 84° S.
- **Ice and cold:** VIPER 15° slope limit; LCROSS 5.6 ± 2.9 %; M3 3.5 % of cold traps; Diviner 38 K; Kaguya below 90 K.
- **Power and shielding:** VSAT 10 kW array; Clowdsley 185 and 85 mSv.
- **Agencies:** each source is credited to its own agency.
