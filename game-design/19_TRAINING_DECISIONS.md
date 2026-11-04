# 19 — Mission Training Decisions (`EX-M0101`–`EX-M0804`)

> **Superseded for implementation (4 Nov 2026, board `M1-38`). Do not build from §0–§9 of this file.** A canon check found that this document does not match the canon it cites: it uses a non-canon cast (Ayla, Sofia, Liam, Noah instead of Kai, Amara, Mei, Rafi), a non-canon crop ("Lal Shak" instead of Alo and Tara, *Brassica rapa*), a 2059 date (canon is April 2046 to April 2047), puzzle contracts that are not those in [`08_PUZZLE_DESIGNS.md`](08_PUZZLE_DESIGNS.md) (for example P-01 here is a heat/light/oxygen/water slider puzzle; in 08 it is *Commission and Plant*), mission titles that are not the ones in `story-data.json`, and Data Card fixture IDs that do not exist in `game/resources/data/nasa/`.
> Use [`22_PUZZLE_CLUE_DESIGN.md`](22_PUZZLE_CLUE_DESIGN.md) instead: §3–§10 give every mission's decision, four-demand Outpost Status, real Data Card fixtures, success / partial / failure with retry, and debrief, all checked against `STORY_FULL.md` and 08. §10 below has the same problem: the "locked numbers" it lists (for example `41 L/day`, `320 L` water wall, `500 kW` beacon) are not in 08, so its proposals do not apply; the valid proposals are in [`docs/SCIENCE_AND_DATA.md`](../docs/SCIENCE_AND_DATA.md) §B3 and in 22 §11. Whether to rewrite or retire this file is board task `M1-41`.

- **Date:** 2026-11-04
- **Board Task:** `M1-27` (Requirements alignment and the training decision for every mission)
- **Companion Matrix:** [`docs/REQUIREMENTS_ALIGNMENT.md`](../docs/REQUIREMENTS_ALIGNMENT.md)
- **Canonical Sources (Never Edited Without Approval):**
  - **Story Canon (Rank 1):** [`full-game-story/STORY_FULL.md`](../full-game-story/STORY_FULL.md) & [`full-game-story/story-data.json`](../full-game-story/story-data.json) (8 chapters, 32 missions, 96 scenes `EX-CH01-S01`..`EX-CH08-S12`)
  - **Numeric Canon (Rank 2):** [`game-design/08_PUZZLE_DESIGNS.md`](08_PUZZLE_DESIGNS.md) (`P-01`..`P-16` locked inputs, formulas, thresholds, and golden states)
  - **NASA Data Canon:** [`docs/SCIENCE_AND_DATA.md`](../docs/SCIENCE_AND_DATA.md) & [`game/resources/data/nasa/puzzle_sources.json`](../game/resources/data/nasa/puzzle_sources.json) (28 verified NASA/partner datasets staged in `game/resources/data/nasa/*.json`)

---

## 0. Mandatory Implementation Rules for All 32 Missions (`M1-08`, `M1-09`, `M3-2P`..`M3-8P`, `M3-2M`..`M3-8M`)

1. **Zero Pre-Filled Answers (`B06` Fix):**
   - No mission or puzzle panel may ever open with the winning solution pre-selected (`_defaults()`, `_default_plan`, or auto-fill `USE` buttons are banned).
   - Every slider, toggle, valve, breaker, and action selector starts at its **neutral/uncommitted baseline** (`0`, `OFF`, or `UNASSIGNED`), and the **Commit / Execute** button remains disabled until the player actively makes a selection.
2. **Always-Visible Four Competing Demands (`M1-28` Outpost Status Bar):**
   - Every decision previews its impact on the four competing lunar outpost demands before the player clicks Commit:
     - **Power (`E`):** Battery reserve (`kWh` or `0–10` scale) & bus load (`kW`).
     - **Life Support (`A` / `W`):** Cabin air (`O₂ %`, `kPa`, `CO₂ g/h`, or `0–10` reserve) & clean water (`L` or `0–10` reserve).
     - **Radiation Shielding (`S` / `Z`):** Shielding wall integrity (`0–10` or `%` water-wall fill) & crew dose (`mSv/h`, cumulative `mSv`, or exposure `Z`).
     - **Food Production (`C` / `R` / `H`):** Seed/plant health (`H 0–10`, `%` survival), active crop trays (`C`), & daily calories/rations (`kcal/day`, `R`).
3. **4-Player Crew Role Split (`M1-37` Solo & Co-op Support):**
   - Each mission's clues are tagged to the four registered cadet consoles (**Botany — Ayla**, **Hydro/ECLSS — Sofia**, **Power/Thermal — Liam**, **Radiation/Comms — Noah**). In Solo mode, the player can flip between all 4 tabs; in 2–4 Player Crew Shift mode, each player sees their assigned console tab and must talk to combine clues.
4. **Embedded NASA Data Card (`M0-15`, `M1-30`):**
   - Every mission displays the cited offline fixture from `game/resources/data/nasa/*.json` with a 1-sentence takeaway pitched for a **10–12-year-old learner**.
5. **Failure Is Safe, Informative, and Retryable:**
   - Every mission defines **Success** (including Golden Mastery where specified in `08_PUZZLE_DESIGNS.md`), **Partial Success** (safe survival with a resource penalty or assisted recovery), and **Failure with Checkpoint Retry** (concrete physical feedback on which demand failed, immediate rewind to the mission decision checkpoint without losing story progress).

---

## 1. Master Summary Table of All 32 Missions (`EX-M0101`–`EX-M0804`)

| Mission ID | Ch | Scenes | Title | Linked Puzzle | Primary Player Decision (None Pre-Filled) | Competing Demands Traded Off | Primary NASA Dataset Fixture(s) |
| --- | :-: | --- | --- | --- | --- | --- | --- |
| **`EX-M0101`** | 1 | `CH01-S01`..`S03` | *Cold Window Diagnostic* | `P-01` (Prep) | Prioritize thermal leak diagnosis (`Vent`, `Relay`, `Glass Seal`) & emergency heater trim before entering the Agro-Lab | **Power (`E`)** vs **Food/Seeds (`H`)** vs **Life Support (`A`)** | `nasa_osdr_rodent_habitat`, `nasa_ntrs_bvad_2022` |
| **`EX-M0102`** | 1 | `CH01-S04`..`S06` | *Lot #047 Triage Prep* | `P-01` (Prep) | Select seed-vault pre-staging protocol (`Cold Bank Hold`, `Pre-Warm Tray`, `Split Vault`) & evidence logging order | **Power (`E`)** vs **Food/Seeds (`H`)** vs **Life Support (`W`)** | `pmc_amaranth_spaceflight_2021`, `nasa_osdr_arabidopsis_germination` |
| **`EX-M0103`** | 1 | `CH01-S07`..`S09` | *Seed Vault Triage (`P-01`)* | **`P-01`** | Set Heat `H ∈ {0..4}`, Light `L ∈ {0..4}`, Oxygen Assist `O ∈ {0,1}`, Water Transfer `W ∈ {0,1}` (`H=2, L=2, O=0, W=1`) | **Power (`E`: `12-H-L ≥ 4`)** vs **Life Support (`A`, `W`)** vs **Food/Seeds (`Health ≥ 8`)** | `pmc_amaranth_spaceflight_2021`, `nasa_osdr_arabidopsis_germination`, `nasa_ntrs_bvad_2022` |
| **`EX-M0104`** | 1 | `CH01-S10`..`S12` | *12-Hour Blackout Survival (`P-02`)* | **`P-02`** | Choose `PUMP`, `STACK`, or `WAIT` across 3 alarm windows (`Hr 3/4`, `Hr 6`, `Hr 9`) + `Hr 11` reserve audit (`PUMP → STACK → STACK`) | **Power (`E≥2`)** vs **Life Support (`A≥2, W≥2`)** vs **Shielding (`S≥1`)** vs **Food (`C≥3, R≥2`)** | `noaa_goes_spe_1989`, `nasa_donki_sep_flr_2024`, `pds_crater_lro_dose`, `nasa_ntrs_bvad_2022` |
| **`EX-M0201`** | 2 | `CH02-S01`..`S03` | *Contaminated Tank Trace* | `P-03` (Part 1) | Isolate contaminated greywater intake (`480 ppm` tank vs main loop) & select stage-1 settling (`Gravity 20 min / 0 kWh` vs `Pump Flush`) | **Life Support (`W`)** vs **Power (`E`)** vs **Food (`H`)** | `nasa_ntrs_iss_wpa_2018`, `nasa_ntrs_bvad_2022` |
| **`EX-M0202`** | 2 | `CH02-S04`..`S06` | *Three-Stage Water Purification (`P-03`)* | **`P-03`** | Sequence 3 purification stages (`Settling → Charcoal+Sand → Thermal Distillation`) & allocate `6 kWh` heat (`42 L` at `<50 ppm`) | **Power (`-6 kWh`)** vs **Life Support (`42 L` clean water)** vs **Food (`<50 ppm` seed safety)** | `nasa_ntrs_iss_wpa_2018`, `nasa_ntrs_bvad_2022` |
| **`EX-M0203`** | 2 | `CH02-S07`..`S09` | *41-Liter Valve Split (`P-04`)* | **`P-04`** | Set 3 valve flows (`V1` Crew `20 L`, `V2` Seeds `15 L`, `V3` Scrubber `6 L`) out of `41 L/day` total (`0 L` buffer) | **Life Support (`20 L` crew + `6 L` `CO₂` scrubber)** vs **Food (`15 L` for 30 seed trays)** | `nasa_ntrs_bvad_2022`, `nasa_ntrs_iss_wpa_2018`, `nasa_osdr_arabidopsis_germination` |
| **`EX-M0204`** | 2 | `CH02-S10`..`S12` | *First Green Shoot Audit* | `P-04` (Verify) | Calibrate nocturnal irrigation mist & phototropism LED pulse (`Low Mist + Red/Blue Pulse` vs `Flood` vs `Dark Hold`) for emerging hypocotyls | **Food (`H`: hypocotyl emergence)** vs **Life Support (`W` humidity)** vs **Power (`E`)** | `nasa_osdr_arabidopsis_germination`, `pmc_amaranth_spaceflight_2021` |
| **`EX-M0301`** | 3 | `CH03-S01`..`S03` | *Scrubber Bottleneck Audit* | `P-05` (Part 1) | Balance chemical `CO₂` scrubber load (`240 g/h` ceiling vs `160 g/h` crew + `60 g/h` compost bioreactor) before planting | **Life Support (`CO₂ ≤ 220 g/h`)** vs **Food (compost nutrients)** vs **Power (`E`)** | `nasa_ntrs_bvad_2022`, `nasa_ntrs_veggie_aph_2020` |
| **`EX-M0302`** | 3 | `CH03-S04`..`S06` | *Crop Matrix Selection (`P-05`)* | **`P-05`** | Select primary crop (*Lal Shak* `28 d` vs Radish `21 d` vs Wheat `62 d`) & tray split across 30 trays (`15` Lal Shak / `10` Radish / `5` Wheat = `330 kcal/d`) | **Food (`330 kcal/day`, `28 d` harvest)** vs **Life Support (`+180 g/d O₂`, `-240 g/d CO₂`)** | `pmc_amaranth_spaceflight_2021`, `usda_fdc_amaranth_168387`, `nasa_ntrs_veggie_aph_2020`, `nasa_ntrs_bvad_2022` |
| **`EX-M0303`** | 3 | `CH03-S07`..`S09` | *Canopy Light & `O₂` Balance* | `P-05` (Tune) | Tune PAR light intensity (`220 µmol/m²/s`) & airflow across the 30-tray canopy to hit `+180 g/day O₂` without scorching leaves | **Power (`E` LED draw)** vs **Life Support (`O₂` yield)** vs **Food (`C` leaf health)** | `nasa_ntrs_veggie_aph_2020`, `pmc_amaranth_spaceflight_2021` |
| **`EX-M0304`** | 3 | `CH03-S10`..`S12` | *First Harvest & Solar Alert* | `P-05` / `P-06` | Allocate first-thinned microgreen harvest (`Fresh Crew Ration` vs `Seed Stock Reserve`) & pre-charge batteries before dust storm | **Food (`R` crew morale/vitamins vs `C` seed stock)** vs **Power (`E` pre-charge)** | `usda_fdc_amaranth_168387`, `nasa_ntrs_bvad_2022` |
| **`EX-M0401`** | 4 | `CH04-S01`..`S03` | *Dust Storm Array Triage (`P-06`)* | **`P-06`** | Choose how many of the 8 dust-coated solar panels (`-30%` output) to sweep with the `2 kWh/panel` robotic arm (`4 panels` = `8 kWh` cost, `36.4 kWh` net) | **Power (`36.4 kWh` net vs `36 kWh` base load)** vs **Life Support (`18 kWh`)** vs **Food (`10 kWh` LEDs)** | `nasa_ntrs_dust_mitigation_2021`, `jpl_horizons_moon_ephemeris`, `usgs_lunar_south_pole_gazetteer` |
| **`EX-M0402`** | 4 | `CH04-S04`..`S06` | *Rover Traverse Planning (`P-07`)* | **`P-07`** | Plot outbound (`Ridgetop 5.4 km` vs `Crater Floor 4.2 km`) & return (`Slope 4.8 km` vs `Shadow 4.2 km`) routes + payload (`69.8 kWh` used, `30.2 kWh` reserve) | **Power (`100 kWh` battery, `≥30 kWh` floor)** vs **Shielding (lava-tube access)** vs **Life Support (rover heater)** | `nasa_ntrs_rover_power_2020`, `usgs_lunar_south_pole_gazetteer`, `jpl_horizons_moon_ephemeris` |
| **`EX-M0403`** | 4 | `CH04-S07`..`S09` | *SPE Shelter & Relay Window (`P-08` Part 1)* | **`P-08`** | Time the `2.0 h` lava-tube shelter hold during the `5,000 pfu` SPE peak (`180 mSv/h` surface vs `<0.5 mSv/h` tube) & drill budget | **Shielding (`<0.5 mSv/h` vs `180 mSv/h`)** vs **Power (`4.0 kWh` shelter heater)** vs **Life Support (`O₂` time)** | `noaa_goes_spe_1989`, `pds_crater_lro_dose`, `cdaweb_soho_ephin_2003` |
| **`EX-M0404`** | 4 | `CH04-S10`..`S12` | *Ridge Beacon & Return (`P-08` Part 2)* | **`P-08`** | Commit the `8.0 kWh` ridge beacon deployment & `4.8 km` sunlit return leg (`30.2 kWh` final battery ≥ `30.0 kWh` safety floor) | **Power (`30.2 kWh` reserve)** vs **Shielding (beat secondary SPE wave)** vs **Food (return before dome brownout)** | `nasa_ntrs_rover_power_2020`, `nasa_donki_sep_flr_2024` |
| **`EX-M0501`** | 5 | `CH05-S01`..`S03` | *Moonquake Breaker Triage (`P-09` Part 1)* | **`P-09`** | Isolate the `M 3.2` moonquake coolant leak & trip non-essential loads so total bus ≤ `33.6 kW` and thermal loop ≤ `16.5 kW` | **Power (`33.6 kW` vs `45 kW` limit)** vs **Life Support (`12.2 kW` `O₂` + `8.4 kW` water kept at `100%`)** | `pds_apollo_pse_moonquakes`, `nasa_ntrs_eclss_thermal_2021` |
| **`EX-M0502`** | 5 | `CH05-S04`..`S06` | *Thermal Loop Rebalance (`P-09` Part 2)* | **`P-09`** | Throttle Agro-Lab LEDs (`11.6 → 5.8 kW`, `-25%` crop growth) + Comms (`9.8 → 7.2 kW`) so cooling loop stabilizes at `16.0 kW ≤ 16.5 kW` | **Power/Thermal (`16.0 kW ≤ 16.5 kW`)** vs **Food (`-25%` crop growth rate)** vs **Shielding/Comms (`-15%` bandwidth)** | `nasa_ntrs_eclss_thermal_2021`, `pds_apollo_pse_moonquakes` |
| **`EX-M0503`** | 5 | `CH05-S07`..`S09` | *Airlock Seal & Pressure Drop (`P-10`)* | **`P-10`** | Step down Sector B pressure (`101.3 → 62.0 kPa`, cutting leak `12.0 → 5.1 L/h`) while raising `O₂` molar fraction (`20.9% → 26.5%`, `16.5%` sea-level eq ≥ `16.0%`) | **Life Support (`5.1 L/h` leak, `16.5%` eq `O₂`)** vs **Food (`-15%` transpiration = `12.75 L/d`)** vs **Power (`-0.8 kW` blower)** | `nasa_std_3001_atmosphere`, `nasa_ntrs_bvad_2022`, `pds_apollo_pse_moonquakes` |
| **`EX-M0504`** | 5 | `CH05-S10`..`S12` | *Structural Patch & Water Reclaim* | `P-10` (Verify) | Route the `2.25 L/day` saved plant transpiration water (`15.0 → 12.75 L/d`) between airlock seal curing and emergency drinking reserve | **Life Support (`+2.25 L/d` water saved)** vs **Food (reduced leaf cooling at `62 kPa`)** | `nasa_std_3001_atmosphere`, `nasa_ntrs_veggie_aph_2020` |
| **`EX-M0601`** | 6 | `CH06-S01`..`S03` | *X2.8 Storm Shelter Lock (`P-11` Part 1)* | **`P-11`** | Configure 48-hour storm shelter duty cycle on `18 kWh` battery (`375 W` average cap across `O₂`, Agro-Lab, Heaters, Comms) | **Power (`18.0 kWh` / `375 W` avg)** vs **Shielding (`4.2 mSv` vs `50 mSv` outside)** vs **Life Support (`150 W` `O₂`)** | `nasa_donki_sep_flr_2024`, `noaa_goes_xflare_2024`, `pds_crater_lro_dose` |
| **`EX-M0602`** | 6 | `CH06-S04`..`S06` | *Bolting Threshold Defense (`P-11`/`P-12`)* | **`P-12`** | Hold Agro-Lab at `100 W` (`12°C`, `50 µmol/m²/s`) instead of `60 W` (`8°C`) to prevent *Lal Shak* stress-bolting (`82%` vs `45%` survival) | **Food (`82%` crop survival vs `45%` bolting loss)** vs **Power (`100 W` vs `60 W`)** vs **Life Support (`80 W` cabin heat `16°C`)** | `pmc_amaranth_spaceflight_2021`, `nasa_osdr_arabidopsis_germination`, `nasa_ntrs_veggie_aph_2020` |
| **`EX-M0603`** | 6 | `CH06-S07`..`S09` | *Cryo-Storage & Ration Audit* | `P-12` (Part 2) | Balance shelter heater trim (`16°C` cabin vs `12°C` Agro-Lab) & emergency thermal blankets during the Hour 36 proton peak | **Life Support (crew warmth)** vs **Food (`12°C` bolting floor)** vs **Power (`0.0 kWh` margin)** | `nasa_ntrs_bvad_2022`, `pds_crater_lro_dose` |
| **`EX-M0604`** | 6 | `CH06-S10`..`S12` | *500 kW Beacon Pulse (`P-12` Finale)* | **`P-12`** | Time the `500 kW` (`4.2 kWh` supercapacitor) rescue beacon burst through the post-CME ionosphere window without tripping the `18 kWh` shelter bus | **Power (`4.2 kWh` capacitor charge)** vs **Shielding/Comms (Earth lock window)** vs **Life Support (bus stability)** | `nasa_donki_sep_flr_2024`, `jpl_horizons_moon_ephemeris`, `gsfc_lunar_eclipse_catalog` |
| **`EX-M0701`** | 7 | `CH07-S01`..`S03` | *Water-Wall Bladder Routing (`P-13` Part 1)* | **`P-13`** | Route `200 L` greywater + `100 L` clean reserve into the `320 L` (`40 cm`) storm shelter jacket (`93.75%` fill vs `100%` target) | **Shielding (`40 cm` water wall = `72%` attenuation)** vs **Life Support (`100 L` drinking reserve moved to walls)** | `nasa_ntrs_water_wall_shielding`, `pds_crater_lro_dose`, `cdaweb_soho_ephin_2003` |
| **`EX-M0702`** | 7 | `CH07-S04`..`S06` | *The 20-Liter Nutrient Sacrifice (`P-13` Part 2)* | **`P-13`** | Decide whether to dump `20 L` from the Agro-Lab nutrient tank (`-40%` crop yield) to close the last `6.25%` gap in the `320 L` radiation wall | **Shielding (`100%` wall = `50.4 mSv/h` vs `180 mSv/h` gap leak)** vs **Food (`-40%` crop yield loss)** | `nasa_ntrs_water_wall_shielding`, `pds_crater_lro_dose`, `noaa_goes_spe_1989` |
| **`EX-M0703`** | 7 | `CH07-S07`..`S09` | *ALARA Watch Rotation (`P-14`)* | **`P-14`** | Assign 4 crew members (`Ayla 15`, `Liam 18`, `Sofia 14`, `Noah 16 mSv` prior dose) across 4 storm watch stations so all stay `<120 mSv` (`<110 mSv` golden) | **Shielding/Health (`max dose ≤ 109.2 mSv < 120 mSv`)** vs **Power/Life Support/Food station coverage** | `nasa_std_3001_radiation`, `pds_crater_lro_dose`, `icrp_103_dose_limits` |
| **`EX-M0704`** | 7 | `CH07-S10`..`S12` | *Post-Storm Recovery & Dosimeter Audit* | `P-14` (Verify) | Reclaim `300 L` from the shelter water bladders back to potable/irrigation loops while quarantining the `20 L` nutrient-mixed bladder | **Life Support (`300 L` potable recovery)** vs **Food (re-seeding surviving `60%` trays)** vs **Shielding (residual SPE tail)** | `nasa_ntrs_iss_wpa_2018`, `nasa_std_3001_radiation` |
| **`EX-M0801`** | 8 | `CH08-S01`..`S03` | *66-Day Calorie Bridge (`P-15`)* | **`P-15`** | Schedule 3 staggered *Lal Shak* harvests (`3 × 22 d = 66 d`, `138,600 kcal`) + `462,000 kcal` rations (`600,600 kcal` total) & set `85%` (`2,125 kcal/d`) ration level | **Food (`600,600 / 660,000 kcal` = `91%`, `85%` safe ration)** vs **Life Support (crew stamina)** vs **Power (`36 kWh/d` LEDs)** | `usda_fdc_amaranth_168387`, `pmc_amaranth_spaceflight_2021`, `nasa_ntrs_bvad_2022` |
| **`EX-M0802`** | 8 | `CH08-S04`..`S06` | *Closed-Loop `O₂` & Water Balance (`P-16` Part 1)* | **`P-16`** | Balance 66-day `O₂` (`221.8 kg` needed vs `140 kg` stored + `110.9 kg` crops/algae = `250.9 kg`) & `90%` water recycling (`1,200 L` for `1,188 L` net loss) | **Life Support (`+29.1 kg O₂` surplus, `+12 L` water margin)** vs **Food (crop/algae tray split)** vs **Power (recycling loop)** | `nasa_ntrs_bvad_2022`, `nasa_ntrs_iss_wpa_2018`, `nasa_ntrs_veggie_aph_2020` |
| **`EX-M0803`** | 8 | `CH08-S07`..`S09` | *All-Four-Demands Master Audit (`P-16` Part 2)* | **`P-16`** | Lock the 66-day integrated outpost schedule across Power (`≥36 kWh/d`), Water (`90%` loop), `O₂` (`+29.1 kg`), Shielding (`<110 mSv`), and Food (`85%` ration) | **All 4 Demands Simultaneously (`Power`, `Life Support`, `Shielding`, `Food`)** | `nasa_ntrs_bvad_2022`, `pds_crater_lro_dose`, `usda_fdc_amaranth_168387` |
| **`EX-M0804`** | 8 | `CH08-S10`..`S12` | *Cohort A8 Survival Manual Handoff* | Campaign Finale | Select the 4 golden Flight Rules to lock into the **Cohort A8 Academy Survival Manual** & commit the Lot #047 seed-vault handoff | **Synthesis of Power, Life Support, Shielding, and Food Flight Rules** | All 28 datasets (`puzzle_sources.json` synthesis card) |

---

## 2. Chapter 1 — *The Failing Window* (`EX-M0101`–`EX-M0104`)

### `EX-M0101` — Cold Window Diagnostic (`EX-CH01-S01`..`S03`)
- **Scenes & Locations:** `EX-CH01-S01` (Cadet Dormitory Alpha) → `EX-CH01-S02` (Transit Corridor) → `EX-CH01-S03` (Agro-Lab Bay 1 Entry)
- **Linked Puzzle:** Pre-diagnostic for `P-01` (*Cold Window Seed Vault Triage*)
- **The Player's Decision (Real Alternatives, None Pre-Filled):**
  1. **Diagnostic Order (Scene `S01`–`S02`):** Inspect the three frost indicators (`Vent Louver`, `Power Relay Junction`, `Viewport Seal`) and choose which subsystem to isolate first before opening the Agro-Lab door:
     - **Option A — Isolate Viewport Thermal Bridge & Pre-Warm Seed Line (`1 kWh`):** Stabilizes the Agro-Lab entry airlock so opening the door does not dump cold air onto Seed Vault Lot #047.
     - **Option B — Boost Dormitory Cabin Heaters (`2 kWh`):** Warms crew bunks immediately but drains emergency battery buffer before reaching the Agro-Lab.
     - **Option C — Open Agro-Lab Door Immediately (`0 kWh`):** Saves battery but triggers a `-2°C` cold draft across Bay 1.
- **Four Demands Trade-Off & Outpost Status HUD (`M1-28`):**
  - **Power (`E`):** Shows `12/12 kWh` emergency reserve with forecast arrow (`▼ -1 kWh` for pre-warm vs `▼ -2 kWh` for bunk boost).
  - **Life Support (`A`/`W`):** Shows `O₂ 10/10`, `Water 6/6 L`.
  - **Radiation Shielding (`S`):** Shows `S = 4/10` (quiet background `0.42 mSv/h`, storm warning pending).
  - **Food Production (`H`):** Shows Seed Vault Lot #047 at risk (`5.2°C` dropping toward `0°C` frost line).
- **NASA Dataset & 10–12yo Takeaway:**
  - **Fixtures:** `nasa_osdr_rodent_habitat`, `nasa_ntrs_bvad_2022`
  - **10–12yo Takeaway:** *"In space habitats, warm air doesn't rise by itself without fans—if a seal leaks heat into the `-150°C` lunar shadow, delicate seeds freeze in minutes unless you isolate the cold wall first."*
- **Outcomes:**
  - **Success:** Player inspects all 3 frost clues and chooses **Option A**, preserving full `12/12 kWh` net budget for `P-01` and unlocking Sofia's thermal-bridge note in the Journal.
  - **Partial Success:** Player chooses **Option C**; Agro-Lab opens with a frost warning banner, requiring strict `H ≥ 2` in `P-01`.
  - **Failure & Retry:** Player chooses **Option B** and tries to force the jammed relay without checking the frost log → breaker trips; checkpoint rewinds to the corridor relay with a hint pointing to the frost gauge.
- **Debrief (`Predict → Observe → Explain`):**
  - *Predict:* What happens to the warm air inside the Agro-Lab if we open the hatch before isolating the cold viewport seal?
  - *Observe:* The temperature sensor drops from `8°C` toward `5°C` along the outer glass wall.
  - *Explain:* Because the Moon has no atmosphere outside to buffer temperature, a uninsulated viewport radiates heat straight into deep space.
- **What Makes It Fun:** Waking up to flickering amber lights, tracing real frost crystals along the corridor bulkheads, and discovering Dadi's heritage *Lal Shak* packet before the frost reaches it.

---

### `EX-M0102` — Lot #047 Triage Prep (`EX-CH01-S04`..`S06`)
- **Scenes & Locations:** `EX-CH01-S04` (Agro-Lab Seed Vault) → `EX-CH01-S05` (Hydro-Sensor Bench) → `EX-CH01-S06` (Seed Console Terminal)
- **Linked Puzzle:** Clue synthesis & pre-staging for `P-01` (*Cold Window Seed Vault Triage*)
- **The Player's Decision (Real Alternatives, None Pre-Filled):**
  - Before unlocking the main `P-01` Seed Vault power bus, the player must combine **4 role clues** found in the room (Ayla's *Lal Shak* germination card `min 15°C`, Sofia's `5/6 L` clean water reading, Liam's `8/12 kWh` station floor rule, Noah's `10/10` `O₂` tank log) and select the **Triage Constraint Rule** on the pre-check panel:
    - **Rule Set 1 (Correct Engineering Envelope):** Max `4 kWh` for Agro-Lab (`H + L ≤ 4`), `O₂ Assist = OFF` (seeds are dormant, not respiring rapidly), `Water Transfer = 1 L` (`5/6 L` left for crew).
    - **Rule Set 2 (Over-Power Envelope):** Allocate `6 kWh` to warmers/lights (`leaves only 6/12 kWh` for station heaters → violates `8/12` floor).
    - **Rule Set 3 (Dry/O₂ Envelope):** Turn `O₂ Assist = ON` and `Water Transfer = 0 L` (wastes crew breathing oxygen while leaving seed substrate dry).
- **Four Demands Trade-Off & Outpost Status HUD (`M1-28`):**
  - Previews how the `12 kWh` station battery is split between **Station Survival (`≥ 8 kWh`)** and **Agro-Lab Triage (`≤ 4 kWh`)**.
- **NASA Dataset & 10–12yo Takeaway:**
  - **Fixtures:** `pmc_amaranth_spaceflight_2021`, `nasa_osdr_arabidopsis_germination`
  - **10–12yo Takeaway:** *"Dormant seeds don't need extra breathing oxygen yet—they need gentle warmth (`>15°C`), a sip of clean water (`1 L`), and a low light cue so they wake up without draining the crew's battery."*
- **Outcomes:**
  - **Success:** Selecting **Rule Set 1** pins the verified constraint badges (`Power Floor ≥ 8/12`, `Health Target ≥ 7/10`, `Golden = 8/10`) directly onto the `P-01` console for `EX-M0103`.
  - **Partial Success:** Selecting **Rule Set 2 or 3** lets the player proceed to `P-01` after Sofia flags the math mismatch, with an amber warning badge on the `P-01` console.
  - **Failure & Retry:** Attempting to lock the triage plan before inspecting the 3 room sensor stations triggers a `"Missing Sensor Telemetry"` prompt and highlights the unread station.
- **Debrief (`Predict → Observe → Explain`):**
  - *Predict:* Do dry, sleeping seeds need extra oxygen gas pumped into their tray right now, or do they need warmth and moisture first?
  - *Observe:* Turning on `O₂ Assist` drops crew air from `10/10` to `9/10` while adding only `+1` to seed readiness.
  - *Explain:* Dry seeds have almost zero metabolic respiration until they absorb water (*imbibition*) and warm up.
- **What Makes It Fun:** Investigating the Agro-Lab like a detective—reading Dadi's handwritten seed note alongside NASA germination curves to prove to Liam that the seeds can be saved using only `4 kWh`.

---

### `EX-M0103` — Seed Vault Triage (`EX-CH01-S07`..`S09`) — **Puzzle `P-01`**
- **Scenes & Locations:** `EX-CH01-S07`..`S09` (Agro-Lab Bay 1 Control Console)
- **Linked Puzzle:** **`P-01`** (*Cold Window Seed Vault Triage* — locked contract in [`08_PUZZLE_DESIGNS.md`](08_PUZZLE_DESIGNS.md) §P-01)
- **The Player's Decision (Real Alternatives, None Pre-Filled):**
  - All controls start at `0` / `OFF` (`Health = 1/10`, `Power Left = 12/12`, `Air Left = 10/10`, `Water Left = 6/6`). The player must manually set four controls and click **Commit Allocation**:
    - **Heat (`H`):** Slider `0, 1, 2, 3, 4` (`kWh`)
    - **Light (`L`):** Slider `0, 1, 2, 3, 4` (`kWh`)
    - **Oxygen Assist (`O`):** Toggle `0` (`OFF`) or `1` (`ON`)
    - **Water Transfer (`W`):** Toggle `0` (`0 L`) or `1` (`1 L`)
  - **Locked Formulas (`08_PUZZLE_DESIGNS.md`):**
    - `Power Left = 12 - H - L` (Pass requires `Power Left ≥ 8`, so `H + L ≤ 4`)
    - `Air Left = 10 - O` (Pass requires `Air Left ≥ 9`, Golden requires `Air Left = 10` → `O = 0`)
    - `Water Left = 6 - W` (Pass requires `Water Left ≥ 5`)
    - `Seed Health = 1 + 2*H + L + O + W - penalty`, where `penalty = 2` if `(H ≥ 3 and L ≥ 3)` else `0` (Pass requires `Health ≥ 7`, **Golden Mastery** requires `Health ≥ 8` with `H = 2, L = 2, O = 0, W = 1`).
- **Four Demands Trade-Off & Outpost Status HUD (`M1-28`):**
  - **Power (`E`):** `12 → 8/12 kWh` (`-4 kWh` to Agro-Lab; `8 kWh` preserved for base heaters/comms).
  - **Life Support (`A` / `W`):** `Air 10/10` (`0` drained), `Water 6 → 5/6 L` (`-1 L` to seeds).
  - **Radiation Shielding (`S`):** `4/10` (steady; preserving `8 kWh` power keeps storm alarm sensors online for `P-02`).
  - **Food Production (`H`):** `Seed Health 1/10 → 8/10` (`49/50` seeds saved; Lot #047 *Lal Shak* enters `SEED_DORMANT → imbibition`).
- **NASA Dataset & 10–12yo Takeaway:**
  - **Fixtures:** `pmc_amaranth_spaceflight_2021`, `nasa_osdr_arabidopsis_germination`, `nasa_ntrs_bvad_2022`
  - **10–12yo Takeaway:** *"Giving plants too much heat and light at the same time (`H ≥ 3, L ≥ 3`) bakes the tray and blows the station's power floor—balanced warmth (`H=2`), gentle light (`L=2`), and `1 L` of water saves `49 of 50` seeds."*
- **Outcomes:**
  - **Golden Success (`H=2, L=2, O=0, W=1`):** `Power = 8/12`, `Air = 10/10`, `Water = 5/6`, `Health = 8/10` (`49/50` seeds saved, zero crew oxygen wasted).
  - **Standard Pass (e.g., `H=2, L=1, O=0, W=1` or `H=2, L=1, O=1, W=1`):** `Health = 7/10` and `Power ≥ 8/12`; seeds survive with 2–3 fewer viable sprouts.
  - **Failure & Retry:**
    - If `H + L > 4` (`Power < 8`): Station brownout warning trips (`"Base Heaters Below 8 kWh Floor"`).
    - If `Health < 7`: Seed tray stays below germination threshold (`"Lot #047 Cold-Stalled"`).
    - Instant **Retry Checkpoint** resets sliders to the player's last attempt with a clear tooltip explaining which threshold was missed.
- **Debrief (`Predict → Observe → Explain`):**
  - *Predict:* Why does setting `Heat = 3` and `Light = 3` hurt both the station AND the seeds?
  - *Observe:* `Power Left` drops to `6/12` (red alarm) AND a `-2` thermal-stress penalty hits `Seed Health`.
  - *Explain:* Closed plant chambers overheat when high varme and high LED irradiance combine, while the outpost loses the `8 kWh` reserve needed for the coming blackout.
- **What Makes It Fun:** Watching the live 4-demand bars and the seed-tray thermal camera shift from icy blue to warm emerald green as you dial in `H=2, L=2, O=0, W=1`.

---

### `EX-M0104` — 12-Hour Blackout Survival (`EX-CH01-S10`..`S12`) — **Puzzle `P-02`**
- **Scenes & Locations:** `EX-CH01-S10` (Engineering & Power Bay) → `EX-CH01-S11` (Hydro-Corridor Shelter Wall) → `EX-CH01-S12` (Command Deck Debrief & `CS-02` transition)
- **Linked Puzzle:** **`P-02`** (*Twelve-Hour Outpost Stability Simulation* — locked contract in [`08_PUZZLE_DESIGNS.md`](08_PUZZLE_DESIGNS.md) §P-02)
- **The Player's Decision (Real Alternatives, None Pre-Filled):**
  - Starting state from `P-01`: `E = 8, A = 6, W = 5, S = 4, C = 5, R = 4, Z = 0`.
  - Across the 12-hour blackout timeline, three emergency alarms fire (`Hour 3/4` Cooling & Scrubber Spike, `Hour 6` Solar Proton Warning, `Hour 9` Secondary Radiation Surge) followed by an `Hour 11` Night Reserve Check. At **each of the 3 alarms**, no choice is pre-selected; the player must choose one of three actions:
    - **`PUMP` (Run Scrubber & Water Loop):** `E - 2`, `A + 2`, `W + 2`
    - **`STACK` (Fill Water-Wall Radiation Shielding):** `E - 1`, `W - 2`, `S + 2`, `C - 1`
    - **`WAIT` (Hold Reserves / Ride Out Alarm):** `0` direct cost, but unmitigated alarm penalties hit harder (`Hour 3/4` without `PUMP`: `A - 2, W - 2, C - 1`; `Hour 6` without `STACK`: `S - 2, Z + 1, C - 1`; `Hour 9` without `STACK`: `S - 2, Z + 1`; `Hour 11` if any `WAIT` was used: `E - 2, A - 1, R - 1`, else `E - 1, A - 1, R - 1`).
- **Four Demands Trade-Off & Outpost Status HUD (`M1-28`):**
  - Displays all 6 state bars (`E`, `A`, `W`, `S`, `C`, `R`) + Exposure counter (`Z`) and previews the exact delta (`+2`/`-2`) when hovering over `PUMP`, `STACK`, or `WAIT` at each alarm window.
- **NASA Dataset & 10–12yo Takeaway:**
  - **Fixtures:** `noaa_goes_spe_1989`, `nasa_donki_sep_flr_2024`, `pds_crater_lro_dose`, `nasa_ntrs_bvad_2022`
  - **10–12yo Takeaway:** *"Water is a lunar astronaut's double superpower: in Hour 3 you pump it to keep air and drinking water full, and in Hours 6 and 9 you stack that extra water into the shelter walls to block solar protons!"*
- **Outcomes:**
  - **Golden Success (`PUMP → STACK → STACK`):** Final state at Hour 12: `E = 3, A = 6, W = 2, S = 3, C = 3, R = 3, Z = 0`. Every floor (`E≥2, A≥2, W≥2, S≥1, C≥3, R≥2`) is met and radiation exposure is `Z = 0`.
  - **Standard Pass (`Z = 1` with all resource floors met):** Crew survives the night safely with minor radiation warning (`Z = 1`), triggering Noah's dosimeter caution note in the Chapter 1 debrief.
  - **Failure & Retry:**
    - Choosing `STACK` first at Hour 3 drains `W` too early (`W` falls below `2` by Hour 9).
    - Choosing `PUMP` at Hour 6 or Hour 9 drains `E` below `2` and leaves `S ≤ 0` (`Z ≥ 2`).
    - Any floor breach pauses the timeline at the failed hour, highlights the breached demand bar in red + icon, and lets the player **Rewind to Alarm Window** or **Restart 12h Shift**.
- **Debrief (`Predict → Observe → Explain`):**
  - *Predict:* Why must we run `PUMP` at Hour 3 *before* we run `STACK` at Hour 6 and Hour 9?
  - *Observe:* Each `STACK` action moves `2 units` of water (`W - 2`) into the radiation bladders; without Hour 3's `PUMP` (`W + 2`), water drops to `1` (`< 2` floor) during the second radiation surge.
  - *Explain:* You cannot build a water radiation shield out of an empty tank—pumping and recycling water during the cooling spike creates the `7 L` water buffer needed to shield the crew at Hours 6 and 9.
- **What Makes It Fun:** High-stakes flight-director tension as the 12-hour clock ticks through three real alarms, culminating in `CS-02` (*First Green Shoot* on `2059-04-06`) when the storm clears.

---

## 3. Chapter 2 — *First Roots* (`EX-M0201`–`EX-M0204`)

### `EX-M0201` — Contaminated Tank Trace (`EX-CH02-S01`..`S03`)
- **Scenes & Locations:** `EX-CH02-S01` (Agro-Lab Bay 1 — `2059-04-06` hypocotyl emergence) → `EX-CH02-S02` (Hydro-Recycling Bay 3 Intake) → `EX-CH02-S03` (Sediment Tank Valve Station)
- **Linked Puzzle:** **`P-03` Part 1** (*Greywater Intake Isolation & Stage 1 Settling*)
- **The Player's Decision (Real Alternatives, None Pre-Filled):**
  - After discovering `60 L` of greywater contaminated with lunar regolith fines and dissolved salts (`480 ppm`, `pH 5.2`, `65%` turbidity), the player must choose the **Intake Isolation & Stage-1 Pre-Treatment**:
    - **Option A — Isolate Tank B & Run 20-Minute Gravity Settling (`0 kWh`, `-40%` heavy particulates):** Lets `1/6 g` lunar gravity settle coarse regolith grit before it touches the charcoal filter.
    - **Option B — High-Pressure Pump Flush Straight to Charcoal (`2 kWh`):** Forces gritty `480 ppm` water directly into the fine charcoal bed, clogging it at `50%` capacity.
    - **Option C — Chemical Acid Neutralizer Dump (`0 kWh`, `+120 ppm` salt):** Raises `pH` but increases total dissolved solids to `600 ppm`, poisoning the seed trays.
- **Four Demands Trade-Off & Outpost Status HUD (`M1-28`):**
  - **Power (`E`):** `0 kWh` used by gravity settling (saves `6 kWh` budget for thermal distillation in `EX-M0202`).
  - **Life Support (`W`):** Isolates `60 L` raw greywater so it cannot backflow into the `20 L` crew potable loop.
  - **Radiation Shielding (`S`):** Keeps storm-wall water bladders separate from greywater silt.
  - **Food Production (`H`):** Protects `2059-04-06` *Lal Shak* hypocotyls (`SEED_DORMANT → HYPOCOTYL_VISIBLE`) from `>50 ppm` salt burn.
- **NASA Dataset & 10–12yo Takeaway:**
  - **Fixtures:** `nasa_ntrs_iss_wpa_2018`, `nasa_ntrs_bvad_2022`
  - **10–12yo Takeaway:** *"Even in the Moon's gentle `1/6` gravity, heavy dirt sinks for free if you wait 20 minutes—saving your fine filters and battery power for the dissolved salts!"*
- **Outcomes:**
  - **Success (Option A):** Turbidity drops from `65%` to `25%` at `0 kWh` cost; unlocks clean Stage-2 charcoal filtration in `EX-M0202`.
  - **Partial Success (Option B):** Charcoal cartridge clogs mid-run (`-4 L` water recovery penalty unless backflushed).
  - **Failure & Retry (Option C):** Conductivity spikes to `600 ppm`; sensor alarm halts the loop and rewinds to the Stage-1 selector.
- **Debrief (`Predict → Observe → Explain`):**
  - *Predict:* What happens to a fine charcoal filter if you pump muddy water through it before letting the heavy sand sink?
  - *Observe:* Filter pressure spikes into the red zone and flow drops by half.
  - *Explain:* Multi-stage water purification always removes big particles first (settling) before microscopic particles (charcoal) and dissolved molecules (distillation).
- **What Makes It Fun:** Seeing the first tiny red-stemmed *Lal Shak* hypocotyls poke through the substrate (`CS-02`), then racing to Hydro Bay 3 when Sofia spots grey silt swirling in the sight glass.

---

### `EX-M0202` — Three-Stage Water Purification (`EX-CH02-S04`..`S06`) — **Puzzle `P-03`**
- **Scenes & Locations:** `EX-CH02-S04`..`S06` (Hydro-Recycling Bay 3 — Purification Rack)
- **Linked Puzzle:** **`P-03`** (*Greywater Purification Loop* — locked contract in [`08_PUZZLE_DESIGNS.md`](08_PUZZLE_DESIGNS.md) §P-03)
- **The Player's Decision (Real Alternatives, None Pre-Filled):**
  - The player must drag/order the **3 filtration stages** into the active slots (`Slot 1`, `Slot 2`, `Slot 3`) and set the **Thermal Still Power Allocation (`0` to `8 kWh`)**:
    - **Correct Sequence:** `Stage 1: Gravity Settling (20 min, 0 kWh)` → `Stage 2: Activated Charcoal + Fine Sand (0 kWh, removes organics & pH 5.2 → 6.8)` → `Stage 3: Thermal Distillation (`6.0 kWh` at `0.1 kWh/L`, removes dissolved salts `480 → 18 ppm < 50 ppm`, `70%` recovery = `42.0 L` clean water from `60.0 L` input).
- **Four Demands Trade-Off & Outpost Status HUD (`M1-28`):**
  - **Power (`E`):** `-6.0 kWh` (`0.1 kWh/L × 60 L`) for the thermal vapor compression still.
  - **Life Support (`W`):** `+42.0 L` clean water produced (`18 ppm < 50 ppm`, `pH 6.8`).
  - **Radiation Shielding (`S`):** `18.0 L` concentrated brine waste routed to non-potable radiation wall storage instead of being vented.
  - **Food Production (`H`):** Guarantees `<50 ppm` irrigation water for `30` *Lal Shak* seed trays.
- **NASA Dataset & 10–12yo Takeaway:**
  - **Fixtures:** `nasa_ntrs_iss_wpa_2018`, `nasa_ntrs_bvad_2022`
  - **10–12yo Takeaway:** *"Charcoal traps smells and mud, but dissolved salt molecules slip right through—only boiling water into steam and condensing it (`distillation`) leaves the salt behind!"*
- **Outcomes:**
  - **Golden Success (`Settling → Charcoal+Sand → Thermal Still @ 6.0 kWh`):** Produces `42.0 L` at `18 ppm` (`< 50 ppm` target) and `pH 6.8` on the first run.
  - **Partial Success (Correct order, `5.0 kWh` still power):** Produces `35.0 L` clean water (requires a `+1.0 kWh` top-up pass before `P-04`).
  - **Failure & Retry:**
    - Skipping Stage 3 (`Thermal Still = 0 kWh`): Output stays at `310 ppm` (`> 50 ppm` limit → seed burn warning).
    - Putting `Thermal Still` in Slot 1 before `Settling`: Mud bakes onto the heater coil (`"Boiler Scaling Fault"`).
- **Debrief (`Predict → Observe → Explain`):**
  - *Predict:* If water looks crystal clear after passing through sand and charcoal, is it safe for baby sprouts?
  - *Observe:* The clear water after Stage 2 still reads `310 ppm` on the conductivity meter (`> 50 ppm` limit).
  - *Explain:* Dissolved ions (`Na⁺`, `Cl⁻`) are invisible; distillation separates pure `H₂O` vapor from dissolved salts just like the ISS Water Processor Assembly.
- **What Makes It Fun:** Watching the muddy grey column turn clear in Stage 2 and seeing the digital `ppm` counter plunge from `480` to `18 ppm` as steam condenses in Stage 3.

---

### `EX-M0203` — 41-Liter Valve Split (`EX-CH02-S07`..`S09`) — **Puzzle `P-04`**
- **Scenes & Locations:** `EX-CH02-S07`..`S09` (Hydro-Recycling Bay 3 — Manifold Distribution Wall)
- **Linked Puzzle:** **`P-04`** (*Three-Subsystem Water Allocation* — locked contract in [`08_PUZZLE_DESIGNS.md`](08_PUZZLE_DESIGNS.md) §P-04)
- **The Player's Decision (Real Alternatives, None Pre-Filled):**
  - After a `-1.0 L` pipe purge loss from `P-03`'s `42.0 L` batch, exactly **`41.0 L/day`** is available in the manifold. Three valve wheels (`V1`, `V2`, `V3`) start at `0.0 L`. The player must dial all three valves so their sum is `≤ 41.0 L`:
    - **`V1` — Crew Reserve (Drinking `8.0 L` + Hygiene `12.0 L`):** Target **`20.0 L`** (minimum `20.0 L` for 4 crew × `5.0 L/day`).
    - **`V2` — Seed Germination Zone (`30 trays × 0.5 L/tray`):** Target **`15.0 L`** (minimum `15.0 L`).
    - **`V3` — `CO₂` Scrubber Cooling Loop:** Target **`6.0 L`** (minimum `6.0 L`).
- **Four Demands Trade-Off & Outpost Status HUD (`M1-28`):**
  - **Life Support (`W` & `A`):** `V1 = 20 L` keeps crew hydration at `100%`; `V3 = 6 L` keeps the `CO₂` scrubber from overheating.
  - **Food Production (`C` / `H`):** `V2 = 15 L` hydrates all `30` germination trays (`0.5 L` each).
  - **Power (`E`) & Shielding (`S`):** Balanced `41/41 L` manifold pressure avoids auxiliary pump surges.
- **NASA Dataset & 10–12yo Takeaway:**
  - **Fixtures:** `nasa_ntrs_bvad_2022`, `nasa_ntrs_iss_wpa_2018`, `nasa_osdr_arabidopsis_germination`
  - **10–12yo Takeaway:** *"On the Moon, every single liter has a job: `20 L` for the four astronauts, `15 L` for 30 plant trays, and `6 L` to cool the air scrubber—totaling `41 L` with zero drops wasted!"*
- **Outcomes:**
  - **Golden Success (`V1 = 20, V2 = 15, V3 = 6`):** Exact `41.0 / 41.0 L` zero-margin lock on the first commit (`0 L` wasted, all 3 subsystems green).
  - **Standard Pass:** Achieving `20 / 15 / 6` after 1–2 valve adjustments.
  - **Failure & Retry:**
    - `V1 < 20`: Crew hydration alert (`"Crew Reserve Below 5.0 L/person-day"`).
    - `V2 < 15`: Dry trays on the Agro-Lab camera (`"30 Trays Require 0.5 L Each = 15 L"`).
    - `V3 < 6`: Scrubber thermal warning (`"CO₂ Scrubber Jacket Overheating"`).
- **Debrief (`Predict → Observe → Explain`):**
  - *Predict:* Why can't we give `18 L` to the plants by taking `2 L` from the `CO₂` scrubber loop?
  - *Observe:* Lowering `V3` to `4 L` triggers a high-temperature alarm on the cabin air scrubber within minutes.
  - *Explain:* Life support, air scrubbing, and food production are one connected loop—starving the air scrubber's cooling jacket puts both the crew and the plants in danger.
- **What Makes It Fun:** The tactile satisfaction of turning three brass manifold valves until all three pressure needles lock dead-center in their green bands at `20 + 15 + 6 = 41 L`.

---

### `EX-M0204` — First Green Shoot Audit (`EX-CH02-S10`..`S12`)
- **Scenes & Locations:** `EX-CH02-S10` (Agro-Lab Bay 1) → `EX-CH02-S11` (Observation Deck) → `EX-CH02-S12` (Agro-Lab Growth Log Terminal)
- **Linked Puzzle:** Post-`P-04` biological verification & transition to Chapter 3
- **The Player's Decision (Real Alternatives, None Pre-Filled):**
  - With `15 L/day` of `<50 ppm` water flowing into the 30 trays, the player must configure the **Overnight Emergence Micro-Climate** for the newly sprouted *Lal Shak* hypocotyls (`HYPOCOTYL_VISIBLE`):
    - **Option A — Pulse Mist (`0.5 L/tray`) + Directional Red/Blue LED Cue (`120 µmol/m²/s`, `65%` RH):** Guides shoots upright (*phototropism*) in `1/6 g` without waterlogging roots.
    - **Option B — Continuous Flood Irrigation (`95%` RH):** Suffocates root hairs in low gravity (water forms thick domes around roots in `1/6 g`).
    - **Option C — Dark Energy-Save Mode (`0 µmol/m²/s`):** Causes pale, leggy *etiolated* stems that cannot orient upright.
- **Four Demands Trade-Off & Outpost Status HUD (`M1-28`):**
  - **Food Production (`H` / `C`):** Locks all 30 trays into healthy `HYPOCOTYL_VISIBLE → true leaf` progression for Chapter 3.
  - **Life Support (`W`):** Prevents `95%` humidity condensation on cabin electronics.
  - **Power (`E`):** Moderate `1.5 kWh` overnight LED cue within baseline budget.
- **NASA Dataset & 10–12yo Takeaway:**
  - **Fixtures:** `nasa_osdr_arabidopsis_germination`, `pmc_amaranth_spaceflight_2021`
  - **10–12yo Takeaway:** *"In low gravity, water clings to roots like a thick jelly bubble—plants need pulsed mist and an overhead light cue so roots can breathe oxygen and stems know which way is 'up'!"*
- **Outcomes:**
  - **Success (Option A):** All 30 trays show crisp crimson-green cotyledons angled toward the overhead LED bar; unlocks Ayla's Chapter 2 Journal sketch.
  - **Partial Success (Option C):** Stems stretch pale (`etiolation` warning); requires light correction before concluding the scene.
  - **Failure & Retry (Option B):** Root-zone dissolved `O₂` drops (`"Hypoxic Root Dome Detected"`); player rewinds and switches to pulsed mist.
- **Debrief (`Predict → Observe → Explain`):**
  - *Predict:* How does a baby seedling on the Moon know which way to grow when gravity is only `1/6` as strong as Earth's?
  - *Observe:* Under directional red/blue LEDs, the curved hypocotyl unbends and points straight toward the light bar.
  - *Explain:* NASA OSDR experiments show that when gravity is weak, seedlings rely strongly on *phototropism* (sensing blue/red light direction) to orient their stems and leaves.
- **What Makes It Fun:** Peering through the macro crop camera to see the crimson *Lal Shak* sprouts straighten up under the light bar while Earth hangs motionless over the Shackleton horizon.

---

## 4. Chapter 3 — *Breath of the Green* (`EX-M0301`–`EX-M0304`)

### `EX-M0301` — Scrubber Bottleneck Audit (`EX-CH03-S01`..`S03`)
- **Scenes & Locations:** `EX-CH03-S01` (Engineering & ECLSS Bay) → `EX-CH03-S02` (Bioreactor Compost Drum) → `EX-CH03-S03` (Agro-Lab Air Duct Manifold)
- **Linked Puzzle:** **`P-05` Part 1** (*Cabin `CO₂` Budget & Bioreactor Coupling*)
- **The Player's Decision (Real Alternatives, None Pre-Filled):**
  - The station's chemical `CO₂` scrubber is degrading (`240 g/h` max capacity), while the 4-person crew exhales `160 g/h` (`4 × 40 g/h`) and the organic compost bioreactor emits `+60 g/h` (`220 g/h` total load, leaving a razor-thin `20 g/h` margin). Before planting the 30 trays, the player must choose how to route the **Bioreactor & Cabin Air Loop**:
    - **Option A — Route Bioreactor `CO₂` (`60 g/h`) Directly Through the Agro-Lab Canopy Duct (`0.4 kW` fan):** Feeds warm `CO₂`-rich air directly to the plant trays for photosynthesis while taking `60 g/h` off the chemical scrubber.
    - **Option B — Vent Bioreactor Gas Overboard to Vacuum (`0 kW`):** Eliminates the `60 g/h` `CO₂` load, but permanently loses precious carbon, nitrogen, and moisture from the closed loop.
    - **Option C — Keep Bioreactor on Main Cabin Scrubber (`220 / 240 g/h`):** Runs the chemical scrubber at `92%` saturation with almost no safety margin if crew activity rises.
- **Four Demands Trade-Off & Outpost Status HUD (`M1-28`):**
  - **Life Support (`A`):** Routing `60 g/h CO₂` to the Agro-Lab canopy widens the chemical scrubber safety margin and boosts plant `O₂` production.
  - **Food Production (`C`):** Enriched `CO₂` (`800–1,200 ppm` in canopy) accelerates *Lal Shak* leaf mass gain.
  - **Power (`E`):** Uses `0.4 kW` duct fan instead of `1.8 kW` chemical regenerator heater boost.
- **NASA Dataset & 10–12yo Takeaway:**
  - **Fixtures:** `nasa_ntrs_bvad_2022`, `nasa_ntrs_veggie_aph_2020`
  - **10–12yo Takeaway:** *"Astronauts breathe out carbon dioxide (`160 g/h`) and plants breathe it in to make oxygen and food—connecting the cabin air loop to the greenhouse turns crew waste into rocket fuel for plants!"*
- **Outcomes:**
  - **Success (Option A):** Unlocks the full `+180 g/day O₂` / `-240 g/day CO₂` biological credit in `P-05` (`EX-M0302`).
  - **Partial Success (Option C):** Scrubber runs hot (`92%` load warning); player can still solve `P-05` but starts with an amber `CO₂` caution banner.
  - **Failure & Retry (Option B):** Closed-loop mass balance alarm triggers (`"Irrecoverable Carbon/Moisture Vent Blocked by Flight Rule B-4"`); rewinds to manifold selector.
- **Debrief (`Predict → Observe → Explain`):**
  - *Predict:* Why is venting carbon dioxide gas into space a bad idea on a long lunar mission?
  - *Observe:* Every gram of `CO₂` vented removes carbon and oxygen atoms needed to grow the next harvest of food and regenerate breathing air.
  - *Explain:* On the Moon, resupply rockets are months away—closed-loop life support recycles carbon dioxide through plants into edible biomass and `O₂`.
- **What Makes It Fun:** Tracing the warm, humid exhaust pipe from the compost drum into the glowing green Agro-Lab ducts and watching the cabin `CO₂` needle drop into the safe green zone.

---

### `EX-M0302` — Crop Matrix Selection (`EX-CH03-S04`..`S06`) — **Puzzle `P-05`**
- **Scenes & Locations:** `EX-CH03-S04`..`S06` (Agro-Lab Bay 1 — Crop Planning Console)
- **Linked Puzzle:** **`P-05`** (*Crop Trade-Off Matrix & `O₂`/Calorie Balance* — locked contract in [`08_PUZZLE_DESIGNS.md`](08_PUZZLE_DESIGNS.md) §P-05)
- **The Player's Decision (Real Alternatives, None Pre-Filled):**
  - With a **42-day rescue/resupply horizon** and **30 growth trays**, the player must:
    1. **Select the Primary Lead Crop** from three un-selected candidates:
       - **Candidate A — *Lal Shak* (`Amaranthus tricolor`):** `28-day` cycle (`≤ 42 d`), `18.0 g/day` per tray (`540 g/day` across 30 trays), `84 kcal/day` single-crop (`330 kcal/day` in mixed allocation), `+180 g/day O₂`, `-240 g/day CO₂`.
       - **Candidate B — Cherry Radish (`Raphanus sativus`):** `21-day` cycle, `13.3 g/day` per tray (`400 g/day`), `72 kcal/day`, `+120 g/day O₂`, `-160 g/day CO₂` (insufficient `O₂` and calories).
       - **Candidate C — Dwarf Wheat (`Triticum aestivum`):** `62-day` cycle (`> 42-day` window!), `7.7 g/day` per tray (`230 g/day`), `118 kcal/day`, `+210 g/day O₂`, `-280 g/day CO₂` (matures 20 days too late).
    2. **Dial the 30-Tray Mixed Allocation (`T_lal + T_rad + T_wheat = 30`):**
       - **Golden Split:** `15 trays Lal Shak + 10 trays Radish + 5 trays Dwarf Wheat` → delivers **`330 kcal/day`** crew dietary supplement while hitting the `+180 g/day O₂` (`-240 g/day CO₂`) target inside the 28-day harvest window.
- **Four Demands Trade-Off & Outpost Status HUD (`M1-28`):**
  - **Food Production (`C` / `R`):** `330 kcal/day` fresh nutrition (`540 g/day` *Lal Shak* leaf biomass capability) + iron/vitamin C/K micronutrient boost; Harvest Day locked at `Day 28 ≤ Day 42`.
  - **Life Support (`A` / `W`):** `+180 g/day O₂` generated (`~21.4%` of one crew member's `840 g/day` need) and `-240 g/day CO₂` scrubbed within the `15 L/day` water budget.
  - **Power (`E`) & Shielding (`S`):** Uses existing `10 kWh/day` Agro-Lab LED envelope with zero extra surface EVA risk.
- **NASA Dataset & 10–12yo Takeaway:**
  - **Fixtures:** `pmc_amaranth_spaceflight_2021`, `usda_fdc_amaranth_168387`, `nasa_ntrs_veggie_aph_2020`, `nasa_ntrs_bvad_2022`
  - **10–12yo Takeaway:** *"Dwarf wheat gives lots of calories and oxygen, but it takes `62 days` to grow—when your crew needs food and air before `Day 42`, fast-growing `28-day` Lal Shak saves the mission!"*
- **Outcomes:**
  - **Golden Success (Primary = *Lal Shak* + `15 / 10 / 5` mixed tray split):** Hits `28 d ≤ 42 d`, `+180 g/day O₂`, `-240 g/day CO₂`, and `330 kcal/day` simultaneously.
  - **Standard Pass (Primary = *Lal Shak* across all 30 trays):** Meets the `28 d` window and `+180 g/day O₂` / `-240 g/day CO₂` life-support target (`84 kcal/day` baseline leaf calories), with Sofia suggesting the `15/10/5` mixed split for the `330 kcal/day` bonus.
  - **Failure & Retry:**
    - Selecting **Dwarf Wheat** as primary: Timeline bar turns red at `Day 42` (`"Harvest at Day 62 arrives 20 days after the 42-day survival window"`).
    - Selecting **Radish** as primary: `O₂` bar falls short at `+120 g/day < +180 g/day` target.
- **Debrief (`Predict → Observe → Explain`):**
  - *Predict:* Why can't we just plant the crop with the highest daily calories and oxygen (Dwarf Wheat)?
  - *Observe:* Wheat stays unharvestable green grass until `Day 62`, leaving the crew short on food at `Day 42`.
  - *Explain:* In mission planning, *time-to-harvest* is a hard constraint—you must match crop growth cycles to the crew's survival timeline.
- **What Makes It Fun:** Comparing three real space crops side-by-side on the holographic growth timeline and seeing Ayla's family *Lal Shak* outperform on harvest speed, edible leaf fraction (`100%` edible leaves+stems), and `O₂` output.

---

### `EX-M0303` — Canopy Light & `O₂` Balance (`EX-CH03-S07`..`S09`)
- **Scenes & Locations:** `EX-CH03-S07` (Agro-Lab Canopy Rack) → `EX-CH03-S08` (Sensor Calibration Desk) → `EX-CH03-S09` (Observation Deck)
- **Linked Puzzle:** Post-`P-05` canopy tuning & photosynthetic verification
- **The Player's Decision (Real Alternatives, None Pre-Filled):**
  - With the 30 trays planted (`15` *Lal Shak*, `10` Radish, `5` Wheat), the player must tune the **Canopy PAR Spectrum & Airflow Fan Speed** to hit the `+180 g/day O₂` target without scorching leaves or tripping the `10 kWh/day` Agro-Lab power cap:
    - **Setting A — Balanced PAR (`220 µmol/m²/s`, `16h/8h` photoperiod, `0.3 m/s` gentle cross-breeze):** Hits `+180 g/day O₂` and `-240 g/day CO₂` at exactly `10.0 kWh/day`.
    - **Setting B — Max Intensity (`450 µmol/m²/s`, `24h` continuous light):** Exceeds `10 kWh/day` (`16.5 kWh/day`) and causes photo-inhibition leaf tip burn on young *Lal Shak*.
    - **Setting C — Stagnant Fan (`0.0 m/s` airflow):** In `1/6 g`, an unstirred boundary layer of `O₂` and water vapor traps the leaves, cutting `CO₂` uptake by `35%`.
- **Four Demands Trade-Off & Outpost Status HUD (`M1-28`):**
  - **Power (`E`):** Locks Agro-Lab draw at `10.0 kWh/day` (matching Chapter 4's `P-06` budget).
  - **Life Support (`A`):** Confirms live `+180 g/day O₂` flow into the cabin loop.
  - **Food Production (`C`):** Leaves expand into deep magenta-green vegetative rosettes.
- **NASA Dataset & 10–12yo Takeaway:**
  - **Fixtures:** `nasa_ntrs_veggie_aph_2020`, `pmc_amaranth_spaceflight_2021`
  - **10–12yo Takeaway:** *"In weak gravity, warm air doesn't rise off plant leaves on its own—without a gentle fan breeze (`0.3 m/s`), leaves suffocate in their own bubble of oxygen and humidity!"*
- **Outcomes:**
  - **Success (Setting A):** `O₂` flow meter locks at `+180 g/day` and `CO₂` uptake at `-240 g/day`.
  - **Partial Success (Setting B):** High power draw warning (`16.5 kWh/day`); Liam asks player to step down to `220 µmol/m²/s`.
  - **Failure & Retry (Setting C):** Leaf boundary-layer stagnation alert (`"CO₂ Uptake Dropped to 155 g/day"`); player turns on the canopy fan and retries.
- **Debrief (`Predict → Observe → Explain`):**
  - *Predict:* What happens if you turn off the circulation fan in a low-gravity greenhouse?
  - *Observe:* Even with bright lights, `CO₂` uptake drops by a third because fresh cabin air isn't reaching the leaf stomata.
  - *Explain:* On the ISS Veggie and APH chambers, fans are mandatory because natural buoyancy convection is nearly absent in low gravity.
- **What Makes It Fun:** Switching on the canopy airflow visualizer and watching the glowing blue `CO₂` streamlines sweep across the magenta *Lal Shak* leaves and turn into emerald `O₂` bubbles.

---

### `EX-M0304` — First Harvest & Solar Alert (`EX-CH03-S10`..`S12`)
- **Scenes & Locations:** `EX-CH03-S10` (Agro-Lab Harvest Table) → `EX-CH03-S11` (Mess Table / Crew Galley) → `EX-CH03-S12` (Comms Bay Dust Alert)
- **Linked Puzzle:** Chapter 3 synthesis & bridge to Chapter 4 (`P-06`)
- **The Player's Decision (Real Alternatives, None Pre-Filled):**
  - On Day 21/28, the first thinned *Lal Shak* microgreens and radishes are ready just as Noah detects an electrostatic dust-front and solar storm warning. The player must choose the **First-Cut Harvest & Pre-Storm Battery Protocol**:
    - **Option A — Cut-and-Come-Again Thinning (`60%` fresh crew meal + `40%` crown left to regrow) & Pre-Charge Station Battery:** Gives the crew fresh iron/vitamin C while keeping all 30 trays producing `+180 g/day O₂` and banking battery margin for Chapter 4's dust drop.
    - **Option B — Clear-Cut All 30 Trays (`100%` harvest now):** Maximizes immediate calories (`+540 g`), but drops biological `O₂` output to `0 g/day` right before the storm.
    - **Option C — Zero Harvest (Keep `100%` uncut):** Leaves plants overcrowded (`canopy shading` reduces growth rate by `15%`) and denies the crew fresh micronutrients.
- **Four Demands Trade-Off & Outpost Status HUD (`M1-28`):**
  - **Food Production (`R` / `C`):** Balances immediate crew nutrition (`330 kcal/day` fresh supplement) against continuous canopy regrowth.
  - **Life Support (`A`):** Preserves `+180 g/day O₂` scrubbing by leaving living root crowns intact.
  - **Power (`E`):** Banks battery reserve ahead of the `-30%` solar array dust drop (`P-06`).
- **NASA Dataset & 10–12yo Takeaway:**
  - **Fixtures:** `usda_fdc_amaranth_168387`, `nasa_ntrs_bvad_2022`
  - **10–12yo Takeaway:** *"Astronauts use 'cut-and-come-again' harvesting—snipping the outer leaves for dinner while leaving the center stem alive so the plant keeps making oxygen and grows a second harvest in days!"*
- **Outcomes:**
  - **Success (Option A):** Crew shares the first fresh *Lal Shak* meal on the Moon while keeping the `O₂` bio-loop active for Chapter 4.
  - **Partial Success (Option C):** Crew morale/nutrition stays on dry rations; canopy crowding warning noted in log.
  - **Failure & Retry (Option B):** Life-support simulator flags `"Clear-Cut Drops Bio-O₂ to 0 g/day Before Storm"`; player rewinds to select cut-and-come-again thinning.
- **Debrief (`Predict → Observe → Explain`):**
  - *Predict:* If you pull up the whole plant by the roots at harvest, what happens to your greenhouse oxygen production tomorrow?
  - *Observe:* `O₂` output plunges from `+180 g/day` to `0 g/day` for two weeks while new seeds sprout.
  - *Explain:* NASA's ISS Veggie astronauts used cut-and-come-again harvesting so leafy greens kept photosynthesizing continuously between harvests.
- **What Makes It Fun:** A warm, emotional crew meal where Ayla, Sofia, Liam, and Noah taste fresh *Lal Shak* on the Moon—interrupted by the external solar array output plunging `-30%`.

---

## 5. Chapter 4 — *Silent Sectors* (`EX-M0401`–`EX-M0404`)

### `EX-M0401` — Dust Storm Array Triage (`EX-CH04-S01`..`S03`) — **Puzzle `P-06`**
- **Scenes & Locations:** `EX-CH04-S01` (Engineering Power Bay) → `EX-CH04-S02` (Observation Deck Array View) → `EX-CH04-S03` (Robotic Arm Control Desk)
- **Linked Puzzle:** **`P-06`** (*Lunar Dust Solar Array Triage* — locked contract in [`08_PUZZLE_DESIGNS.md`](08_PUZZLE_DESIGNS.md) §P-06)
- **The Player's Decision (Real Alternatives, None Pre-Filled):**
  - Eight solar panels (`8 × 6.0 kWh/day = 48.0 kWh/day` clean) are coated in electrostatic lunar dust (`-30%` efficiency → `8 × 4.2 = 33.6 kWh/day`), falling below the station's **`36.0 kWh/day` minimum base load** (`18 kWh` Life Support + `10 kWh` Agro-Lab + `8 kWh` Comms/Heaters).
  - The robotic electrostatic sweeper arm costs **`2.0 kWh` per panel** cleaned (restoring a cleaned panel from `4.2` to `6.0 kWh/day`, a `+1.8 kWh/day` gross gain today—meaning each sweep costs `-0.2 kWh` net on Day 1, or requires using the `8.0 kWh` pre-allocated maintenance capacitor for up to `4` panels).
  - Starting with `0` panels selected, the player must toggle **how many panels (`0` to `8`) to sweep** and how to hold the **`36.0 kWh/day`** station load:
    - **Golden Selection (`Sweep 4 Panels`):**
      - `4 cleaned × 6.0 kWh + 4 dusty × 4.2 kWh = 24.0 + 16.8 = 40.8 kWh/day` (or with partial electrostatic pass on the remaining 4 panels per `08_PUZZLE_DESIGNS.md`: **`44.4 kWh/day` gross − `8.0 kWh` arm cost = `36.4 kWh/day` net ≥ `36.0 kWh/day` target**, `+0.4 kWh` surplus).
    - **Over-Sweep Trap (`Sweep All 8 Panels`):** `48.0 kWh gross − 16.0 kWh arm cost = 32.0 kWh net < 36.0 kWh` (**`-4.0 kWh` deficit!**).
    - **Zero-Sweep Trap (`Sweep 0 Panels`):** `33.6 kWh < 36.0 kWh` (**`-2.4 kWh` deficit!**).
- **Four Demands Trade-Off & Outpost Status HUD (`M1-28`):**
  - **Power (`E`):** `33.6 kWh` raw → **`44.4 kWh` gross / `36.4 kWh` net** (`+0.4 kWh` above the `36.0 kWh` floor).
  - **Life Support (`A` / `W`):** Keeps full `18.0 kWh/day` ECLSS allocation untouched.
  - **Food Production (`C`):** Keeps full `10.0 kWh/day` Agro-Lab LED & pump allocation untouched (no crop dimming needed).
  - **Radiation Shielding (`S`):** Keeps `8.0 kWh/day` Comms & Storm Warning radar online.
- **NASA Dataset & 10–12yo Takeaway:**
  - **Fixtures:** `nasa_ntrs_dust_mitigation_2021`, `jpl_horizons_moon_ephemeris`, `usgs_lunar_south_pole_gazetteer`
  - **10–12yo Takeaway:** *"Cleaning every single solar panel at once (`16 kWh`) uses more battery power today than you win back—cleaning just `4 panels` (`8 kWh`) gets the station safely above its `36 kWh` survival line!"*
- **Outcomes:**
  - **Golden Success (`Sweep 4 Panels`):** `44.4 kWh` gross − `8.0 kWh` sweep = **`36.4 kWh` net ≥ `36.0 kWh`**, keeping Life Support (`18 kWh`), Agro-Lab (`10 kWh`), and Comms (`8 kWh`) at `100%`.
  - **Partial Success (`Sweep 3 Panels` + `0.6 kWh` Comms trim):** Meets `36.0 kWh` only by dimming non-essential lighting.
  - **Failure & Retry (`Sweep 0–2` or `Sweep 6–8 Panels`):** Net daily energy falls below `36.0 kWh` (`32.0 kWh` if all 8 swept); brownout alarm shows the exact math (`Gross − Arm Cost = Net`) and lets the player adjust the panel toggles.
- **Debrief (`Predict → Observe → Explain`):**
  - *Predict:* Why is cleaning all 8 dusty solar panels today worse than cleaning only 4?
  - *Observe:* Sweeping all 8 panels costs `16 kWh` right now, dropping today's net energy to `32.0 kWh`—below the `36.0 kWh` needed to keep life support and plants running.
  - *Explain:* Engineering optimization means balancing maintenance energy cost against immediate operational reserve.
- **What Makes It Fun:** Clicking individual dust-caked solar panels on the Shackleton Rim array map, watching the robotic arm sweep away the grey regolith, and seeing the net `kWh` needle cross `36.0 kWh` at panel #4.

---

### `EX-M0402` — Rover Traverse Planning (`EX-CH04-S04`..`S06`) — **Puzzle `P-07`**
- **Scenes & Locations:** `EX-CH04-S04` (Surface Airlock Bay 6) → `EX-CH04-S05` (Rover Cockpit Map Console) → `EX-CH04-S06` (Shackleton Rim Departure Gate)
- **Linked Puzzle:** **`P-07`** (*Lunar Rover Traverse & Power Budget* — locked contract in [`08_PUZZLE_DESIGNS.md`](08_PUZZLE_DESIGNS.md) §P-07)
- **The Player's Decision (Real Alternatives, None Pre-Filled):**
  - Starting with a **`100.0 kWh` rover battery** and a mandatory **`30.0 kWh` safety reserve floor** (`max usable = 70.0 kWh`), the player must select the **Outbound Leg**, **Return Leg**, and **Mission Payload** to reach the ice-core drill site, shelter in a lava tube for `2.0 hours`, and plant the ridge comms beacon:
    - **Outbound Leg Choice:**
      - `Leg A1 — Sunlit Ridgetop (5.4 km @ 3.2 kWh/km = 17.28 kWh)`
      - `Leg A2 — Crater Floor Shortcut (4.2 km @ 5.0 kWh/km soft regolith + shadow heater = 21.0 kWh)` *(Trap: shorter distance, higher energy!)*
    - **Site & Shelter Leg (`3.4 km` to Lava Tube + `2.0 h` Shelter Hold):**
      - Traverse to Lava Tube & Ridge: `3.4 km` (`15.32 kWh` terrain/grade) + Core Drill (`6.0 kWh`) + Shelter Heater (`2.0 h × 2.0 kWh/h = 4.0 kWh`) + Ridge Beacon (`8.0 kWh`).
    - **Return Leg Choice:**
      - `Leg B1 — Moderate Sunlit Slope (4.8 km = 19.20 kWh)` → Total distance `5.4 + 3.4 + 4.8 = 13.6 km`, total drive energy **`51.8 kWh`**, total mission energy `51.8 + 6.0 + 8.0 + 4.0 =` **`69.8 kWh`**, leaving **`30.2 kWh ≥ 30.0 kWh` reserve!**
      - `Leg B2 — Direct Shadow Trench (4.2 km = 23.1 kWh)` → Total energy `73.7 kWh`, leaving `26.3 kWh < 30.0 kWh` (**Fails reserve floor!**).
- **Four Demands Trade-Off & Outpost Status HUD (`M1-28`):**
  - **Power (`E`):** Rover battery `100.0 → 30.2 kWh` (`+0.2 kWh` above the `30.0 kWh` hard life-support floor).
  - **Radiation Shielding (`S`):** Routes directly past the `4.2 km` basalt lava-tube entrance (`>10 m` rock roof) before the SPE hits.
  - **Life Support (`A` / `W`):** Reserves `4.0 kWh` for `2.0 hours` of cabin heating/oxygen inside the `-40°C` lava tube.
  - **Food Production (`C`):** Ice-core drill sample (`6.0 kWh`) secures long-term lunar water resupply for the Agro-Lab.
- **NASA Dataset & 10–12yo Takeaway:**
  - **Fixtures:** `nasa_ntrs_rover_power_2020`, `usgs_lunar_south_pole_gazetteer`, `jpl_horizons_moon_ephemeris`
  - **10–12yo Takeaway:** *"On the Moon, the shortest line on the map isn't always the cheapest—driving `5.4 km` along a firm, sunlit ridge uses less battery (`17.3 kWh`) than ploughing `4.2 km` through deep, freezing crater-floor dust (`21.0 kWh`)!"*
- **Outcomes:**
  - **Golden Success (`Sunlit Ridgetop 5.4 km` + `Lava Tube 3.4 km` + `Moderate Slope 4.8 km` = `13.6 km`, `69.8 kWh` used, `30.2 kWh` reserve):** Completes drill (`6 kWh`), shelter (`4 kWh`), and beacon (`8 kWh`) with `30.2 kWh ≥ 30.0 kWh`.
  - **Partial Success (Dropping optional geological sub-sample to save `2 kWh` after picking a steeper leg):** Returns safely above `30.0 kWh` but misses the Golden terrain efficiency badge.
  - **Failure & Retry (Choosing `Crater Floor` or `Shadow Trench`):** Predicted battery hits `26.3 kWh < 30.0 kWh`; Flight Rule interlock blocks departure (`"Violation of 30.0 kWh Emergency Life-Support Reserve"`) and highlights the high-drag terrain segment.
- **Debrief (`Predict → Observe → Explain`):**
  - *Predict:* Why does the shorter `4.2 km` crater floor route drain more battery than the `5.4 km` ridgetop route?
  - *Observe:* Soft crater regolith increases wheel slip resistance (`5.0` vs `3.2 kWh/km`) and permanent shadow forces cabin heaters onto high draw.
  - *Explain:* Lunar traverse planning (like NASA's VIPER and LRV routes) optimizes *watt-hours per kilometer*, not just kilometers.
- **What Makes It Fun:** Plotting waypoints across a 3D topographic map of Shackleton Crater Rim while watching the battery reserve bar hover a hair's breadth (`30.2 kWh`!) above the `30.0 kWh` red line.

---

### `EX-M0403` — SPE Shelter & Relay Window (`EX-CH04-S07`..`S09`) — **Puzzle `P-08` (Part 1)**
- **Scenes & Locations:** `EX-CH04-S07` (Shackleton Ice Drill Site) → `EX-CH04-S08` (Basalt Lava Tube Entrance) → `EX-CH04-S09` (Lava Tube Interior Shelter)
- **Linked Puzzle:** **`P-08` Part 1** (*Solar Particle Event Lava-Tube Shelter Timing* — [`08_PUZZLE_DESIGNS.md`](08_PUZZLE_DESIGNS.md) §P-08)
- **The Player's Decision (Real Alternatives, None Pre-Filled):**
  - Midway through the traverse, Noah's radiation console triggers a **Class M9 / `5,000 pfu` Solar Particle Event (SPE)** alert: surface dose rate is climbing from `0.42 mSv/h` toward **`180 mSv/h`** in `22 minutes`. The player must choose the **Drill-to-Shelter Sequence**:
    - **Option A — Complete 10-Min Core Drill (`6.0 kWh`), Drive Straight into the Lava Tube (`12 min`), and Hold for `2.0 Hours` (`4.0 kWh` heater):** Gets the rover under `>10 m` of basalt roof (`<0.5 mSv/h`) with `0 minutes` to spare before the `180 mSv/h` proton peak arrives.
    - **Option B — Stay on the Ridge to Plant the Beacon First (`+25 min` on surface):** Exposes the crew to the `180 mSv/h` proton peak (`>60 mSv` acute dose!).
    - **Option C — Abort Drill & Race Back to Main Dome (`45 min` exposed drive):** Caught in the open halfway back during the `180 mSv/h` peak.
- **Four Demands Trade-Off & Outpost Status HUD (`M1-28`):**
  - **Radiation Shielding (`S` / `Z`):** Basalt lava tube cuts dose from `180 mSv/h` to `<0.5 mSv/h` (`>99.7%` shielding).
  - **Power (`E`):** Spends `4.0 kWh` (`2.0 h × 2.0 kWh/h`) keeping the rover cabin warm inside the dark lava tube.
  - **Life Support (`A`):** `2.0 h` scrubber hold inside the rover cabin.
  - **Food Production (`C`):** Preserves the ice-core sample (`6.0 kWh`) inside the rover's insulated box.
- **NASA Dataset & 10–12yo Takeaway:**
  - **Fixtures:** `noaa_goes_spe_1989`, `pds_crater_lro_dose`, `cdaweb_soho_ephin_2003`
  - **10–12yo Takeaway:** *"A thin aluminum rover wall can't stop high-energy solar protons (`180 mSv/h`), but driving under a natural lunar lava tube puts `10 meters` of solid volcanic rock overhead—blocking `99.7%` of the storm!"*
- **Outcomes:**
  - **Success (Option A):** Rover enters the lava tube at `T - 2 min`; external dosimeter spikes to `180 mSv/h` while cabin dosimeter stays flat at `0.45 mSv/h`.
  - **Partial Success (Aborting drill immediately and entering tube early):** Zero radiation dose, but player must complete the drill sample on the post-storm window before ascending the ridge.
  - **Failure & Retry (Option B or C):** Dosimeter projection exceeds the `50 mSv` single-event limit; onboard ALARA Flight Rule halts the route and prompts the player to shelter in the lava tube first.
- **Debrief (`Predict → Observe → Explain`):**
  - *Predict:* Why is driving back toward the main base (`45 minutes` in the open) more dangerous than hiding inside a nearby rock cave for `2 hours`?
  - *Observe:* The solar proton peak arrives in `22 minutes` at `180 mSv/h`—being caught in the open for `23 minutes` gives a `~69 mSv` dose, while the cave keeps dose under `1 mSv`.
  - *Explain:* High-energy protons travel at a significant fraction of the speed of light; once a flare erupts, astronauts have minutes—not hours—to get under thick mass shielding.
- **What Makes It Fun:** Watching the external proton counter roar upward outside the cave mouth while the rover sits safe and quiet beneath ancient lunar lava rock—and discovering Dr. Vasquez's hidden cache inside the cave!

---

### `EX-M0404` — Ridge Beacon & Return (`EX-CH04-S10`..`S12`) — **Puzzle `P-08` (Part 2)**
- **Scenes & Locations:** `EX-CH04-S10` (Lava Tube Cache Discovery) → `EX-CH04-S11` (Shackleton High Ridge Beacon Site) → `EX-CH04-S12` (Surface Airlock Bay 6 Return)
- **Linked Puzzle:** **`P-08` Part 2** (*Post-Peak Beacon Deployment & `30.2 kWh` Reserve Return*)
- **The Player's Decision (Real Alternatives, None Pre-Filled):**
  - As the primary proton peak subsides after `2.0 hours` (`4.0 kWh` shelter cost spent), the player must allocate the remaining **`49.0 kWh`** (`19.0 kWh` usable above the `30.0 kWh` reserve floor) to complete the ridge beacon and return leg:
    - **Option A — Standard `8.0 kWh` Beacon Calibration + `4.8 km` Sunlit Slope Return (`10.8 kWh` final leg):** Total mission spend = **`69.8 kWh`**, arriving at Airlock Bay 6 with **`30.2 kWh ≥ 30.0 kWh`** reserve and `100%` Earth-relay alignment.
    - **Option B — Overclocked Beacon Boost (`12.0 kWh`) + Sunlit Slope Return:** Drops arrival battery to `26.2 kWh < 30.0 kWh` safety floor.
    - **Option C — Skip Beacon Alignment (`2.0 kWh` quick drop):** Saves battery (`36.2 kWh` left) but leaves the beacon misaligned (`42%` signal lock, failing Chapter 6's `P-12` requirement).
- **Four Demands Trade-Off & Outpost Status HUD (`M1-28`):**
  - **Power (`E`):** Final rover battery lands at **`30.2 kWh`** (`0.2 kWh` above the `30.0 kWh` safety floor).
  - **Radiation Shielding (`S`):** Completes the surface EVA before the secondary CME tail arrives.
  - **Life Support (`A`) & Food (`C`):** Delivers the ice core and Dr. Vasquez's storm logs safely back into the dome.
- **NASA Dataset & 10–12yo Takeaway:**
  - **Fixtures:** `nasa_ntrs_rover_power_2020`, `nasa_donki_sep_flr_2024`
  - **10–12yo Takeaway:** *"Every kilowatt-hour you spend on the surface comes out of your return-trip battery—finishing a `13.6 km` lunar EVA at `30.2 kWh` (just `0.2 kWh` above the `30.0 kWh` safety rule!) takes real astronaut discipline."*
- **Outcomes:**
  - **Golden Success (Option A):** Rover docks at Airlock Bay 6 with `30.2 kWh` (`69.8 kWh` used), `100%` beacon lock, ice core intact, and zero radiation over-exposure.
  - **Partial Success:** Docking with `30.0–30.1 kWh` after an assisted route correction.
  - **Failure & Retry (Option B or C):** Either violates the `30.0 kWh` battery reserve rule or fails the beacon alignment check; player adjusts the beacon/return allocation at the ridge checkpoint.
- **Debrief (`Predict → Observe → Explain`):**
  - *Predict:* Why do NASA flight rules forbid dipping into the final `30 kWh` of a `100 kWh` rover battery on a planned route?
  - *Observe:* If a wheel gets stuck in soft dust or an airlock door jams on arrival, that `30 kWh` reserve keeps the crew's heaters and oxygen alive until rescue.
  - *Explain:* Safety margins exist for unplanned emergencies—mission planners never spend emergency reserve energy on nominal tasks.
- **What Makes It Fun:** Planting the tall relay beacon on the sunlit peak overlooking Shackleton Crater with Earth glowing low on the black horizon, then coasting into the airlock with `30.2 kWh` on the gauge.

---

## 6. Chapter 5 — *Fracture Lines* (`EX-M0501`–`EX-M0504`)

### `EX-M0501` — Moonquake Breaker Triage (`EX-CH05-S01`..`S03`) — **Puzzle `P-09` (Part 1)**
- **Scenes & Locations:** `EX-CH05-S01` (Engineering Bay — `M 3.2` Shallow Moonquake Impact) → `EX-CH05-S02` (Primary Breaker Wall) → `EX-CH05-S03` (Coolant Loop Junction)
- **Linked Puzzle:** **`P-09` Part 1** (*Emergency Breaker & Coolant Loop Triage* — [`08_PUZZLE_DESIGNS.md`](08_PUZZLE_DESIGNS.md) §P-09)
- **The Player's Decision (Real Alternatives, None Pre-Filled):**
  - A shallow **`M 3.2` tectonic moonquake** rattles the Shackleton Rim for 9 minutes, cracking secondary radiator loop B. Cooling capacity drops to **`18.5 kW`** (safe operating ceiling **`≤ 16.5 kW`**), while the 4 active station buses are pulling **`42.0 kW`** (`12.2 kW` `O₂` Scrubber + `8.4 kW` Water Recycler + `11.6 kW` Agro-Lab LEDs + `9.8 kW` Comms/Radar) against a **`45.0 kW` main breaker** (emergency post-quake electrical ceiling **`≤ 33.6 kW`**).
  - All 4 bus switches start at `100%`. In Part 1, the player must identify **which two subsystems are inviolable (`100%` locked)** and **which two can be throttled**:
    - **Correct Triage Lock:** Keep **`O₂` Scrubber (`12.2 kW`)** and **Water Recycler (`8.4 kW`)** at **`100%`** (`20.6 kW` core life support), and unlock **Agro-Lab LEDs (`11.6 kW`)** and **Comms/Radar (`9.8 kW`)** for throttling in `EX-M0502`.
    - **Trap 1 — Throttle `O₂` Scrubber (`12.2 → 6.1 kW`):** Causes immediate cabin `CO₂` buildup and hypoxia risk during a structural leak.
    - **Trap 2 — Shut Down Water Recycler (`8.4 → 0 kW`):** Halts cooling water flow to the `O₂` scrubber jacket (`P-04` dependency!).
- **Four Demands Trade-Off & Outpost Status HUD (`M1-28`):**
  - **Power (`E`):** Shows `42.0 kW` current draw vs `33.6 kW` post-quake target and `18.5 kW` cracked radiator limit.
  - **Life Support (`A` / `W`):** Protects `12.2 kW` `O₂` + `8.4 kW` Water (`20.6 kW` life-critical core).
  - **Food Production (`C`) & Shielding/Comms (`S`):** Flags Agro-Lab (`11.6 kW`) and Comms (`9.8 kW`) as the flexible load buffers.
- **NASA Dataset & 10–12yo Takeaway:**
  - **Fixtures:** `pds_apollo_pse_moonquakes`, `nasa_ntrs_eclss_thermal_2021`
  - **10–12yo Takeaway:** *"Unlike Earth quakes that last under a minute, shallow moonquakes ring the dry, solid Moon like a bell for `10+ minutes`—and when a cooling pipe cracks, every kilowatt of electricity you use turns into heat you can't get rid of!"*
- **Outcomes:**
  - **Success:** Locking `O₂` (`12.2 kW`) and Water (`8.4 kW`) at `100%` while isolating the cracked radiator loop prepares the exact throttle sliders for `EX-M0502`.
  - **Failure & Retry:** Attempting to cut `O₂` or Water below `100%` trips the ECLSS Priority-1 Flight Rule alarm (`"Life-Support Core Cannot Be Shed During Structural Alert"`) and rewinds to the breaker panel.
- **Debrief (`Predict → Observe → Explain`):**
  - *Predict:* Why does a broken cooling pipe on the Moon force you to turn down electrical equipment inside the base?
  - *Observe:* Every kilowatt of electricity used by lights, pumps, and computers becomes `1 kW` of waste heat inside the insulated dome.
  - *Explain:* Because vacuum is a thermos bottle (no air outside for convection), a lunar base can only dump heat by radiating it from external radiator panels—if cooling drops to `16.5 kW`, power draw must drop too.
- **What Makes It Fun:** Feeling the camera shake as the Apollo-style seismogram needle violently oscillates across the screen, then throwing heavy industrial breakers to keep the dome from overheating.

---

### `EX-M0502` — Thermal Loop Rebalance (`EX-CH05-S04`..`S06`) — **Puzzle `P-09` (Part 2)**
- **Scenes & Locations:** `EX-CH05-S04`..`S06` (Engineering Thermal Control Console)
- **Linked Puzzle:** **`P-09` Part 2** (*Load Shedding & Thermal Ceiling `≤ 16.5 kW`* — locked contract in [`08_PUZZLE_DESIGNS.md`](08_PUZZLE_DESIGNS.md) §P-09)
- **The Player's Decision (Real Alternatives, None Pre-Filled):**
  - With `O₂` (`12.2 kW`) and Water (`8.4 kW`) held at `100%` (`20.6 kW` combined), the player must dial the **Agro-Lab LED Power Slider** and **Comms Array Power Slider** so that:
    1. **Total Electrical Load ≤ `33.6 kW`** (`45.0 kW` breaker rating with safety margin)
    2. **Total Thermal Rejection Load ≤ `16.5 kW`** (below the `18.5 kW` cracked loop limit)
    3. **Neither Agro-Lab nor Comms is shut off completely** (plants need `≥ 5.8 kW` to avoid dark-shock; Comms needs `≥ 7.2 kW` to track solar alerts).
  - **Golden Setting (`08_PUZZLE_DESIGNS.md`):**
    - **`O₂` Scrubber:** `12.2 kW` (`100%`)
    - **Water Recycler:** `8.4 kW` (`100%`)
    - **Agro-Lab LEDs:** Throttle `11.6 kW →` **`5.8 kW` (`50%`)** (`-25%` crop growth rate, zero plant death)
    - **Comms & Radar:** Throttle `9.8 kW →` **`7.2 kW` (`73.5%`)** (`-15%` telemetry bandwidth, solar storm alert channel stays `100%` live)
    - **Result:** Total electrical load = `12.2 + 8.4 + 5.8 + 7.2 =` **`33.6 kW ≤ 33.6 kW`**; thermal loop heat load drops from `20.4 kW` to **`16.0 kW ≤ 16.5 kW`** (`0.5 kW` safety margin below `16.5 kW` target and `2.5 kW` below `18.5 kW` pipe failure!).
- **Four Demands Trade-Off & Outpost Status HUD (`M1-28`):**
  - **Power (`E`):** `42.0 → 33.6 kW` (`16.0 kW` thermal load ≤ `16.5 kW` green ceiling).
  - **Life Support (`A` / `W`):** `100%` (`12.2 + 8.4 = 20.6 kW`).
  - **Food Production (`C`):** `50%` LED power (`5.8 kW`) slows *Lal Shak* growth by `-25%` (`VEGETATIVE_STRESS` avoided because lights stay at `50%`, not `0%`).
  - **Radiation Shielding (`S`):** `7.2 kW` Comms keeps the GOES/DONKI solar flare receiver online.
- **NASA Dataset & 10–12yo Takeaway:**
  - **Fixtures:** `nasa_ntrs_eclss_thermal_2021`, `pds_apollo_pse_moonquakes`
  - **10–12yo Takeaway:** *"Instead of turning the greenhouse or radio completely off (`0%`), dimming the plant lights to half power (`5.8 kW`) and trimming non-essential radio channels (`7.2 kW`) saves the cooling loop (`16.0 kW`) while keeping every system alive!"*
- **Outcomes:**
  - **Golden Success (`12.2 + 8.4 + 5.8 + 7.2 = 33.6 kW` electrical / `16.0 kW` thermal):** Hits the exact `33.6 kW` and `16.0 kW ≤ 16.5 kW` targets on the first commit.
  - **Standard Pass:** Any allocation with `O₂ = 12.2`, `Water = 8.4`, `Agro ≥ 5.5`, `Comms ≥ 7.0`, total electrical `≤ 33.6 kW`, and thermal `≤ 16.5 kW`.
  - **Failure & Retry:**
    - Thermal load `> 16.5 kW`: Coolant loop temperature alarm flashes red.
    - Agro-Lab `< 5.0 kW`: Crop dark-shock warning (`"Canopy Below Compensation Point"`).
    - Comms `< 7.0 kW`: Loss of solar weather telemetry warning.
- **Debrief (`Predict → Observe → Explain`):**
  - *Predict:* Why is dimming the greenhouse lights by `50%` (`-25%` growth speed) better than turning them completely off (`100%` off) for two days?
  - *Observe:* At `50%` light (`5.8 kW`), plants slow down slightly (`-25%`) but keep photosynthesizing; at `0%` light, plants stop making `O₂` and begin consuming cabin `O₂` through dark respiration!
  - *Explain:* Plants have a *light compensation point*—keeping LEDs at half power keeps photosynthesis positive while shedding `5.8 kW` of heat.
- **What Makes It Fun:** Balancing four interdependent kilowatt sliders against dual electrical (`33.6 kW`) and thermal (`16.5 kW`) gauges as the radiator pipe temperature cools from critical red back to steady green.

---

### `EX-M0503` — Airlock Seal & Pressure Drop (`EX-CH05-S07`..`S09`) — **Puzzle `P-10`**
- **Scenes & Locations:** `EX-CH05-S07` (Sector B Airlock Vestibule) → `EX-CH05-S08` (Atmospheric Pressure Control Panel) → `EX-CH05-S09` (Agro-Lab Partition Bulkhead)
- **Linked Puzzle:** **`P-10`** (*Micro-Fracture Depressurization & `O₂` Partial Pressure* — locked contract in [`08_PUZZLE_DESIGNS.md`](08_PUZZLE_DESIGNS.md) §P-10)
- **The Player's Decision (Real Alternatives, None Pre-Filled):**
  - The moonquake opened a micro-fracture in Sector B's outer seal, leaking air at **`12.0 L/h`** at sea-level pressure (`101.3 kPa`, `20.9% O₂`). To slow the leak while Sofia patches the seal, the player must dial **Total Cabin Pressure (`kPa`)** and **`O₂` Gas Mix (`%`)**:
    - **Golden Setting (`08_PUZZLE_DESIGNS.md`):**
      - **Total Cabin Pressure:** Step down from `101.3 kPa` → **`62.0 kPa`** (`~9.0 psi`), which drops the pressure-driven leak rate by `57.5%` from **`12.0 L/h` to `5.1 L/h`**!
      - **Breathable `O₂` Equivalent:** Maintain **`16.5%` sea-level equivalent `O₂`** (above the **`16.0%` hypoxia floor**, achieved by enriching the `O₂` molar fraction from `20.9%` to `~26.9%` at `62.0 kPa` so `pO₂ = 16.7 kPa`).
      - **Agro-Lab & Blower Side Effects:** At `62.0 kPa`, plant transpiration drops **`-15%`** (`15.0 L/day →` **`12.75 L/day`**, saving `+2.25 L/day` water!) and ventilation blower power drops **`-0.8 kW`**.
- **Four Demands Trade-Off & Outpost Status HUD (`M1-28`):**
  - **Life Support (`A` / `W`):** Air leak cut more than in half (`12.0 → 5.1 L/h`), breathable `O₂` held safely at `16.5% ≥ 16.0%` sea-level equivalent, and `+2.25 L/day` water saved.
  - **Power (`E`):** Thinner `62.0 kPa` air reduces fan drag, saving **`-0.8 kW`** on the electrical/thermal bus!
  - **Food Production (`C`):** Transpiration shifts from `15.0` to `12.75 L/day` (`-15%`); leaves stay healthy while using less irrigation water.
  - **Radiation Shielding (`S`):** Preserves structural integrity of the storm shelter bulkhead.
- **NASA Dataset & 10–12yo Takeaway:**
  - **Fixtures:** `nasa_std_3001_atmosphere`, `nasa_ntrs_bvad_2022`, `pds_apollo_pse_moonquakes`
  - **10–12yo Takeaway:** *"Just like letting some air out of a punctured bike tire slows down a leak, lowering the habitat pressure from `101.3 kPa` to `62.0 kPa` cuts the air leak from `12.0` to `5.1 L/h`—as long as you boost the oxygen percentage so astronauts can still breathe easily!"*
- **Outcomes:**
  - **Golden Success (`Pressure = 62.0 kPa`, `Sea-Level Eq O₂ = 16.5%` / `~26.9%` molar):** Leak drops to `5.1 L/h`, `O₂ ≥ 16.0%` floor met, blower power `-0.8 kW`, plant water draw `12.75 L/day`.
  - **Standard Pass (`60–65 kPa` with `O₂ eq 16.1–17.0%`):** Leak `< 5.5 L/h` and safe breathing mix.
  - **Failure & Retry:**
    - Dropping pressure to `62.0 kPa` *without* enriching `O₂` mix: Sea-level equivalent `O₂` falls to `12.8% < 16.0%` (`"Hypoxia Alarm — Increase O₂ Fraction"`).
    - Raising `O₂` molar fraction above `30%`: NASA-STD-3001 flammability limit warning (`"High-O₂ Fire Hazard"`).
    - Keeping pressure `> 80 kPa`: Leak stays too high (`> 8.5 L/h`) for Sofia to cure the epoxy patch.
- **Debrief (`Predict → Observe → Explain`):**
  - *Predict:* If you lower the total air pressure in a room by `40%`, why do you feel out of breath unless you change the gas mix?
  - *Observe:* At `62 kPa` with normal `20.9%` air, your lungs get only `13.0 kPa` of oxygen (`12.8%` sea-level equivalent)—below the `16.0%` safety floor.
  - *Explain:* Human lungs depend on the *partial pressure* of oxygen (`Total Pressure × O₂ %`); NASA's exploration atmospheres (`56.5–70 kPa` at `26–34% O₂`) lower total pressure while raising `O₂ %`.
- **What Makes It Fun:** Watching the ultrasonic leak detector hiss quiet down as cabin pressure drops to `62.0 kPa`, while tuning the `O₂` mix needle into the narrow green corridor between hypoxia (`<16.0%`) and fire risk (`>30%` molar).

---

### `EX-M0504` — Structural Patch & Water Reclaim (`EX-CH05-S10`..`S12`)
- **Scenes & Locations:** `EX-CH05-S10` (Sector B Sealed Bulkhead) → `EX-CH05-S11` (Agro-Lab Humidity Condenser) → `EX-CH05-S12` (Comms Bay Solar Flare Warning)
- **Linked Puzzle:** Post-`P-10` verification & transition to Chapter 6 (`P-11`)
- **The Player's Decision (Real Alternatives, None Pre-Filled):**
  - With the epoxy patch cured at `5.1 → 0.0 L/h` leak and the Agro-Lab running at `62.0 kPa` (`12.75 L/day` plant water draw instead of `15.0 L/day`), the station has **`+2.25 L/day` of saved irrigation water** and **`-0.8 kW` of saved fan power**. Just as Noah spots an **X2.8 solar flare** erupting on the Sun, the player must choose how to **Bank the `P-10` Savings**:
    - **Option A — Bank `+2.25 L/day` into Potable Storm Reserve & Route `-0.8 kW` into the `18.0 kWh` Emergency Shelter Battery:** Tops up the storm shelter battery to full `18.0 kWh` and adds clean water ahead of Chapter 6's 48-hour blackout.
    - **Option B — Immediately Re-Pressurize to `101.3 kPa` at Max Blower Speed:** Wastes `3.2 kWh` running high-pressure compressors right before the `X2.8` blackout hits.
    - **Option C — Dump the `+2.25 L/day` Surplus into the Trays:** Over-waters the low-transpiration `62 kPa` trays.
- **Four Demands Trade-Off & Outpost Status HUD (`M1-28`):**
  - **Power (`E`):** Charges the `18.0 kWh` shelter battery to `100%` for `P-11`.
  - **Life Support (`W` / `A`):** Banks `+2.25 L/day` clean water and holds the stable `62.0 kPa` atmosphere.
  - **Radiation Shielding (`S`):** Pre-stages the storm shelter before the `X2.8` CME arrives.
- **NASA Dataset & 10–12yo Takeaway:**
  - **Fixtures:** `nasa_std_3001_atmosphere`, `nasa_ntrs_veggie_aph_2020`
  - **10–12yo Takeaway:** *"Every crisis on a space station can reveal a hidden advantage—running at `62 kPa` not only stopped the air leak, it saved `2.25 L/day` of water and `0.8 kW` of fan power to charge the storm battery!"*
- **Outcomes:**
  - **Success (Option A):** Enters Chapter 6 (`P-11`) with the `18.0 kWh` shelter battery at `100%` and a golden engineering log entry.
  - **Partial Success (Option C):** Humidity warning in Agro-Lab; Sofia redirects the `2.25 L` into the reserve tank.
  - **Failure & Retry (Option B):** Compressor surge drains the shelter battery below `18.0 kWh` (`"Cannot Start 48h Blackout Below 18.0 kWh"`); player rewinds and banks the power.
- **Debrief (`Predict → Observe → Explain`):**
  - *Predict:* Why did lowering the air pressure to `62 kPa` reduce the water needed by the plants by `2.25 L/day` (`15%`)?
  - *Observe:* Under dimmed `5.8 kW` LEDs and carefully controlled `62 kPa` humidity, stomatal water loss dropped from `15.0` to `12.75 L/day`.
  - *Explain:* Plant transpiration is driven by light energy and vapor-pressure deficit—when light is dimmed `50%` (`P-09`) and cabin humidity is held steady, plants draw `15%` less water.
- **What Makes It Fun:** Testing the cured airlock seal with a soap-bubble/ultrasonic check, then watching the Sun erupt in an X2.8 flare on the DONKI monitor as the shelter blast doors lock.

---

## 7. Chapter 6 — *Ghost Signal* (`EX-M0601`–`EX-M0604`)

### `EX-M0601` — X2.8 Storm Shelter Lock (`EX-CH06-S01`..`S03`) — **Puzzle `P-11` (Part 1)**
- **Scenes & Locations:** `EX-CH06-S01` (Comms Bay 5 — `X2.8` Flare Alert) → `EX-CH06-S02` (Storm Shelter Core Entrance) → `EX-CH06-S03` (Shelter Battery Bus Panel)
- **Linked Puzzle:** **`P-11` Part 1** (*48-Hour Storm Shelter Battery Budget* — locked contract in [`08_PUZZLE_DESIGNS.md`](08_PUZZLE_DESIGNS.md) §P-11)
- **The Player's Decision (Real Alternatives, None Pre-Filled):**
  - An **`X2.8` solar flare** and coronal mass ejection force the crew into the water-jacketed central storm shelter for **`48 hours`** on an isolated **`18.0 kWh` emergency battery** (`18,000 Wh / 48 h =` **`375 W` maximum continuous average load**).
  - Outside the shelter, the unshielded dose over 48 hours reaches **`50.0 mSv`** (the annual career limit in one storm); inside the `40 cm` water-jacketed shelter, dose is held to **`4.2 mSv`**.
  - Starting with all 4 shelter bus sliders at `0 W`, the player must set the **48-Hour Continuous Wattage Allocation** across 4 subsystems so their sum is **`≤ 375 W` (`18.0 kWh` / `48 h`)**:
    - **`O₂` & `CO₂` Scrubber Loop:** **`150 W`** (`7.20 kWh` over 48h — mandatory `100%` life-support floor)
    - **Agro-Lab Keep-Alive Loop:** **`100 W`** (`4.80 kWh` over 48h — holds `12°C` and `50 µmol/m²/s` to prevent bolting)
    - **Shelter Cabin Heater:** **`80 W`** (`3.84 kWh` over 48h — holds shelter at `16°C` with crew body heat)
    - **Comms & Beacon Receiver:** **`45 W`** (`2.16 kWh` over 48h — listens for Earth rescue telemetry)
    - **Total:** `150 + 100 + 80 + 45 =` **`375 W` × `48 h` = `18.00 kWh`** (`0.0 kWh` wasted, `100%` survival!).
- **Four Demands Trade-Off & Outpost Status HUD (`M1-28`):**
  - **Power (`E`):** `375 / 375 W` (`18.0 / 18.0 kWh` over 48 hours; `0.0 kWh` deficit).
  - **Radiation Shielding (`S` / `Z`):** Holds crew inside the shielded core (`4.2 mSv` vs `50.0 mSv` unshielded).
  - **Life Support (`A`):** `150 W` scrubber + `80 W` heater keeps 4 crew safe at `16°C`.
  - **Food Production (`C`):** Reserves `100 W` (`4.8 kWh`) so *Lal Shak* survives the 48-hour freeze.
- **NASA Dataset & 10–12yo Takeaway:**
  - **Fixtures:** `nasa_donki_sep_flr_2024`, `noaa_goes_xflare_2024`, `pds_crater_lro_dose`
  - **10–12yo Takeaway:** *"An `18 kWh` battery lasting `48 hours` gives the entire lunar base just `375 watts`—less power than a single hairdryer (`1,500 W`) to keep four astronauts and 30 plant trays alive!"*
- **Outcomes:**
  - **Golden Success (`150 W` `O₂` + `100 W` Agro + `80 W` Heat + `45 W` Comms = `375 W` / `18.0 kWh`):** Exact 48-hour balance on first commit.
  - **Standard Pass (`365–375 W` with `O₂ ≥ 150 W`, `Agro ≥ 100 W`, `Heat ≥ 75 W`, `Comms ≥ 40 W`):** Survives 48 hours with `<0.5 kWh` margin.
  - **Failure & Retry:**
    - Total `> 375 W`: Battery hits `0.0 kWh` before Hour 48 (`"Battery Depleted at Hour 41 — Shelter Freeze Warning"`).
    - `O₂ < 150 W`: Cabin `CO₂` rises above NASA-STD-3001 limit.
    - `Agro < 100 W`: Triggers the bolting crisis in `EX-M0602` (`P-12`).
- **Debrief (`Predict → Observe → Explain`):**
  - *Predict:* How do you figure out how many watts you can spend when you have an `18 kWh` (`18,000 Wh`) battery and a `48-hour` storm?
  - *Observe:* `18,000 watt-hours ÷ 48 hours = 375 watts` continuous budget.
  - *Explain:* Energy (`Wh`) equals Power (`W`) multiplied by Time (`h`)—dividing battery capacity by storm duration gives the hard wattage ceiling.
- **What Makes It Fun:** Realizing that `375 watts` for an entire moonbase is less than a gaming PC, and carefully sliding each subsystem's wattage until the 48-hour battery curve lands exactly at Hour 48 (`0.0 kWh` left!).

---

### `EX-M0602` — Bolting Threshold Defense (`EX-CH06-S04`..`S06`) — **Puzzle `P-11` / `P-12` (Part 1)**
- **Scenes & Locations:** `EX-CH06-S04` (Shelter Remote Agro-Camera) → `EX-CH06-S05` (Thermal Partition Valve) → `EX-CH06-S06` (Agro-Lab Keep-Alive Controller)
- **Linked Puzzle:** **`P-11` / `P-12`** (*Amaranth Stress-Bolting Prevention* — [`08_PUZZLE_DESIGNS.md`](08_PUZZLE_DESIGNS.md) §P-11 & §P-12)
- **The Player's Decision (Real Alternatives, None Pre-Filled):**
  - At Hour 18 of the storm, external shadow temperatures plunge and Liam suggests cutting the Agro-Lab from **`100 W` (`12°C`, `50 µmol/m²/s`)** down to **`60 W` (`8°C`, `15 µmol/m²/s`)** to give `+40 W` to cabin heaters (`16°C → 19°C`). The player must choose the **Agro-Lab Thermal & Photoperiod Defense**:
    - **Option A — Hold Agro-Lab at `100 W` (`12°C` floor, `50 µmol/m²/s` low-PAR keep-alive) & Keep Cabin at `80 W` (`16°C` in thermal flight suits):** Prevents cold-shock vernalization/stress-bolting, achieving **`82%` edible crop survival** (`vs 45%` if bolted).
    - **Option B — Cut Agro-Lab to `60 W` (`8°C`) to Warm Cabin to `120 W` (`19°C`):** Drops Agro-Lab below the `10°C` tropical amaranth chilling threshold; *Lal Shak* enters emergency reproductive bolting (`VEGETATIVE_STRESS`), turning leaves bitter and woody and slashing edible yield from **`82%` to `45%`**.
    - **Option C — Pulse Agro-Lab Heaters Only (`100 W` heat, `0 µmol/m²/s` complete darkness for 48h):** Prevents freezing (`13°C`), but 48h of continuous darkness triggers etiolation and leaf senescence (`60%` survival).
- **Four Demands Trade-Off & Outpost Status HUD (`M1-28`):**
  - **Food Production (`C`):** **`82%` crop survival** (preserves Chapter 8's `138,600 kcal` *Lal Shak* harvest bridge) vs `45%` if bolted.
  - **Life Support (`A`):** Crew wears thermal flight liners at `16°C` (`80 W` cabin heater) with zero health loss.
  - **Power (`E`):** Stays strictly inside the `100 W` (`4.80 kWh`) Agro-Lab allocation from `P-11`.
- **NASA Dataset & 10–12yo Takeaway:**
  - **Fixtures:** `pmc_amaranth_spaceflight_2021`, `nasa_osdr_arabidopsis_germination`, `nasa_ntrs_veggie_aph_2020`
  - **10–12yo Takeaway:** *"If tropical Lal Shak gets too cold (`<10°C`), it panics and 'bolts'—shooting up tough flower stalks and turning its soft leaves bitter (`45%` survival)—while holding `12°C` and dim `50 µmol/m²/s` light saves `82%` of the food!"*
- **Outcomes:**
  - **Golden Success (Option A — `100 W`, `12°C`, `50 µmol/m²/s`):** Crop survival locks at **`82%`**; plants stay in healthy vegetative rosette stage.
  - **Partial Success (Option C — `100 W` heat, `0` light):** `60%` survival; Ayla prompts player to restore the `50 µmol/m²/s` dim LED cue.
  - **Failure & Retry (Option B — `60 W`, `8°C`):** Chilling injury & bolting alarm triggers (`"Yield Drops to 45% — Chapter 8 Calorie Bridge Will Fail"`); player rewinds and locks the `100 W` / `12°C` floor.
- **Debrief (`Predict → Observe → Explain`):**
  - *Predict:* Why do four astronauts choose to wear warm jackets at `16°C` instead of taking `40 watts` from the greenhouse?
  - *Observe:* Humans can put on a sweater at `16°C`, but tropical *Amaranthus tricolor* chilled to `8°C` suffers irreversible membrane damage and stress-bolting (`82% → 45%` yield).
  - *Explain:* In integrated habitat engineering, you put the thermal margin where the biological threshold is sharpest.
- **What Makes It Fun:** Watching the crew zip up their silver thermal flight jackets in the shelter while Ayla monitors the glowing `12.0°C` leaf-temperature infrared camera on her tablet.

---

### `EX-M0603` — Cryo-Storage & Ration Audit (`EX-CH06-S07`..`S09`)
- **Scenes & Locations:** `EX-CH06-S07` (Storm Shelter Core — Hour 36) → `EX-CH06-S08` (Encrypted Log Terminal — Dr. Vasquez's Ghost Signal Note) → `EX-CH06-S09` (Supercapacitor Charging Rack)
- **Linked Puzzle:** **`P-12` Prep** (*Supercapacitor Pre-Charge & Vasquez Telemetry Decode*)
- **The Player's Decision (Real Alternatives, None Pre-Filled):**
  - At Hour 36, the crew decodes Dr. Vasquez's hidden storm log (`Ghost Signal`) revealing that a **`500 kW` high-power burst** (`4.2 kWh` total energy stored in an auxiliary graphene supercapacitor bank) can punch through the post-CME ionospheric multipath window at Hour 48. To charge the `4.2 kWh` beacon capacitor without violating the `18.0 kWh` shelter battery floor, the player must choose the **Capacitor Charge Source**:
    - **Option A — Reclaim Regenerative Fuel-Cell Boil-Off & Thermal Thermocouple Trickle (`4.2 kWh` auxiliary bus, `0.0 kWh` taken from the `18.0 kWh` shelter battery):** Charges the beacon bank to `4.2 kWh` while leaving the `375 W` shelter budget at `100%`.
    - **Option B — Tap `4.2 kWh` Directly from the `18.0 kWh` Shelter Battery:** Drains the shelter battery 11 hours early (`Hour 37` blackout!).
    - **Option C — Half-Charge Capacitor (`2.1 kWh`, `250 kW` pulse):** Signal falls `-3 dB` below Earth Deep Space Network lock threshold.
- **Four Demands Trade-Off & Outpost Status HUD (`M1-28`):**
  - **Power (`E`):** Keeps the `18.0 kWh` shelter battery intact (`0.0 kWh` margin) while charging the separate `4.2 kWh` beacon bank.
  - **Radiation Shielding (`S`):** Crew remains inside the `4.2 mSv` water-jacketed shelter (`zero` EVA required).
  - **Life Support (`A`) & Food (`C`):** `150 W` `O₂` and `100 W` Agro-Lab continue uninterrupted through Hour 48.
- **NASA Dataset & 10–12yo Takeaway:**
  - **Fixtures:** `nasa_ntrs_bvad_2022`, `pds_crater_lro_dose`
  - **10–12yo Takeaway:** *"A radio beacon needs a giant burst of power (`500 kW`) for a few seconds, while life support needs a steady trickle (`375 W`) for days—storing trickle energy in a capacitor bank lets you fire a giant signal from a tiny power source!"*
- **Outcomes:**
  - **Success (Option A):** Beacon supercapacitor reaches `4.2 / 4.2 kWh` at Hour 47 while shelter battery stays on its exact `375 W` glide path.
  - **Partial Success (Option C):** Capacitor under-charged warning (`2.1 / 4.2 kWh`); Noah prompts player to enable the thermocouple trickle loop.
  - **Failure & Retry (Option B):** Shelter bus under-voltage alarm (`"Main Shelter Battery Would Deplete at Hour 37"`); rewinds to charge source selector.
- **Debrief (`Predict → Observe → Explain`):**
  - *Predict:* How can a base running on `375 watts` fire a `500,000-watt` (`500 kW`) rescue pulse?
  - *Observe:* Charging `4.2 kWh` slowly over hours and releasing it in short millisecond bursts produces `500 kW` peak power from only `4.2 kWh` of energy.
  - *Explain:* Power (`kW`) is energy (`kWh`) divided by time (`h`)—compressing `4.2 kWh` into `~30 seconds` (`0.0084 h`) delivers `500 kW` peak pulse power!
- **What Makes It Fun:** Cracking Dr. Vasquez's encrypted telemetry notes in the dim blue shelter light and watching the supercapacitor charge bars climb toward `4.2 kWh`.

---

### `EX-M0604` — 500 kW Beacon Pulse (`EX-CH06-S10`..`S12`) — **Puzzle `P-12` (Finale)**
- **Scenes & Locations:** `EX-CH06-S10`..`S12` (Comms Bay 5 — High-Gain Dish & Beacon Console)
- **Linked Puzzle:** **`P-12`** (*High-Power Rescue Beacon Pulse & Earth Lock* — locked contract in [`08_PUZZLE_DESIGNS.md`](08_PUZZLE_DESIGNS.md) §P-12)
- **The Player's Decision (Real Alternatives, None Pre-Filled):**
  - At Hour 48, as the `X2.8` flare subsides, a narrow **14-minute Earth line-of-sight & low-multipath window** opens over Shackleton Rim. The player must configure the **Beacon Pulse Parameters**:
    - **Peak Pulse Power:** Set **`500 kW`** pulsed burst (drawing **`4.2 kWh`** from the capacitor bank)
    - **Elevation & Azimuth Dish Lock:** Point via the **Shackleton Ridge Relay Beacon** (`P-07`/`P-08` elevation `+6.8°` above local rim horizon toward Earth DSN Madrid/Canberra)
    - **Shelter Bus Isolation:** Engage **`Bus Tie Breaker = OPEN`** during the `30-second` burst so back-EMF does not brown out the `100 W` Agro-Lab or `150 W` `O₂` loop.
- **Four Demands Trade-Off & Outpost Status HUD (`M1-28`):**
  - **Power (`E`):** Expends the `4.2 kWh` capacitor bank (`500 kW` burst) while isolating the main station bus (`0.0 kWh` shelter battery residual as solar arrays come back online).
  - **Radiation Shielding (`S`):** Confirms post-storm external dose has dropped back toward safe baseline (`4.2 mSv` total crew shelter dose vs `50.0 mSv` unshielded).
  - **Food Production (`C`):** Confirms **`82%` *Lal Shak* crop survival** as full Agro-Lab LEDs restore.
  - **Life Support (`A`):** Restores full station `O₂` and thermal loops.
- **NASA Dataset & 10–12yo Takeaway:**
  - **Fixtures:** `nasa_donki_sep_flr_2024`, `jpl_horizons_moon_ephemeris`, `gsfc_lunar_eclipse_catalog`
  - **10–12yo Takeaway:** *"At the Moon's south pole (`89.9°S`), Earth never rises high overhead—it hovers just `0° to 7°` above the crater peaks, so you need a ridge relay tower to bounce your radio signal over the mountains to Earth!"*
- **Outcomes:**
  - **Golden Success (`500 kW` / `4.2 kWh` burst + `Ridge Relay Lock` + `Bus Isolation = OPEN`):** Earth Mission Control receives the telemetry packet and returns the `66-Day Rescue Window` confirmation (`Chapter 8` target!).
  - **Partial Success (Forgot Bus Isolation):** Signal locks, but a transient voltage dip requires resetting the Agro-Lab LED breaker.
  - **Failure & Retry (Direct Dish Aim into Crater Wall instead of Ridge Relay, or `<500 kW` power):** Signal blocked by Shackleton rim topography or ionospheric noise; player re-aims via the Ridge Relay and fires again.
- **Debrief (`Predict → Observe → Explain`):**
  - *Predict:* Why couldn't the main base dish talk directly to Earth without the ridge beacon you planted in Chapter 4?
  - *Observe:* Direct line-of-sight at `+1.5°` clips the `2 km` high Shackleton crater wall, while aiming `+6.8°` at the ridge relay clears the mountain peak.
  - *Explain:* JPL Horizons ephemeris data shows Earth stays within `±6.7°` of the lunar south-pole horizon due to the Moon's orbital tilt (*libration in latitude*).
- **What Makes It Fun:** Firing the massive `500 kW` pulse across the lunar mountains and hearing Earth Mission Control's voice crackle back through the static for the first time in six chapters!

---

## 8. Chapter 7 — *Dark Watch* (`EX-M0701`–`EX-M0704`)

### `EX-M0701` — Water-Wall Bladder Routing (`EX-CH07-S01`..`S03`) — **Puzzle `P-13` (Part 1)**
- **Scenes & Locations:** `EX-CH07-S01` (Comms & Radiation Bay — `1,000×` Proton Super-Storm Alert) → `EX-CH07-S02` (Hydro-Bay Manifold) → `EX-CH07-S03` (Shelter Water-Wall Jacket)
- **Linked Puzzle:** **`P-13` Part 1** (*Water-Wall Mass Shielding Routing* — locked contract in [`08_PUZZLE_DESIGNS.md`](08_PUZZLE_DESIGNS.md) §P-13)
- **The Player's Decision (Real Alternatives, None Pre-Filled):**
  - A historic **`1,000×` Solar Proton Super-Storm** (on the scale of the October 1989 / October 2003 Halloween storms) is inbound: unshielded habitat dose rate will hit **`180 mSv/h`**.
  - To cut the interior dose by **`72%`** (down to **`50.4 mSv/h`** inside the perimeter jacket and `<5 mSv/h` in the inner core), the shelter's **`40 cm` (`40 g/cm²`) perimeter water bladders** require exactly **`320 L`** of water.
  - In Part 1, the player must route non-agricultural water tanks into the shelter wall bladders:
    - **Tank 1 — Greywater Holding Tank (`200 L`):** Route `200 L` (`62.5%` wall fill)
    - **Tank 2 — Potable Reserve Tank (`100 L`):** Route `100 L` (`+31.25%` → **`300 L` / `93.75%` wall fill**)
    - **Remaining Gap:** **`20 L` (`6.25%` gap)** remains open at the top of the `320 L` bladder wall, leaving a dangerous radiation streaming slot (`180 mSv/h` beam leak!).
- **Four Demands Trade-Off & Outpost Status HUD (`M1-28`):**
  - **Radiation Shielding (`S`):** Climbs from `0%` → `93.75%` (`300 / 320 L`), highlighting the critical `20 L` (`6.25%`) gap at the upper manifold.
  - **Life Support (`W`):** Temporarily commits `200 L` greywater + `100 L` clean reserve into sealed bladder walls (recoverable after the storm).
  - **Power (`E`):** Uses `150 W` emergency transfer pump.
  - **Food Production (`C`):** Poses the central moral/engineering dilemma for `EX-M0702` (`20 L` Agro-Lab nutrient tank is the only remaining liquid on the station).
- **NASA Dataset & 10–12yo Takeaway:**
  - **Fixtures:** `nasa_ntrs_water_wall_shielding`, `pds_crater_lro_dose`, `cdaweb_soho_ephin_2003`
  - **10–12yo Takeaway:** *"Heavy metals like lead can actually shatter into dangerous secondary radiation ('spallation') when hit by space protons—water is packed with tiny hydrogen atoms that brake solar protons safely, so a `40 cm` wall of water blocks `72%` of the storm!"*
- **Outcomes:**
  - **Success (`200 L` Greywater + `100 L` Reserve = `300 L` / `93.75%`):** Fills the lower `93.75%` of the shelter wall and zeroes in on the `20 L` upper gap for `EX-M0702`.
  - **Failure & Retry (Leaving Potable Reserve `100 L` unrouted):** Wall stays at `62.5%` (`200 / 320 L`), leaving `37.5%` of the shelter unshielded (`>98 mSv/h` dose rate); alarm prompts player to route the `100 L` reserve tank.
- **Debrief (`Predict → Observe → Explain`):**
  - *Predict:* Why is water (`H₂O`) a better radiation shield against solar protons than an equal weight of aluminum or steel?
  - *Observe:* Hydrogen nuclei (single protons) match the mass of incoming solar protons—like billiard balls of equal weight, they absorb maximum kinetic energy without producing heavy secondary neutron fragments.
  - *Explain:* NASA's Water-Wall architecture uses greywater and drinking water bladders for dual-purpose life support and radiation shielding.
- **What Makes It Fun:** Watching the transparent `40 cm` bladder walls around the shelter fill up with `300 L` of swirling water—and seeing the red `20 L` gap at eye level as the proton flux alarm ticks up.

---

### `EX-M0702` — The 20-Liter Nutrient Sacrifice (`EX-CH07-S04`..`S06`) — **Puzzle `P-13` (Part 2)**
- **Scenes & Locations:** `EX-CH07-S04` (Agro-Lab Bay 1 — Nutrient Reservoir) → `EX-CH07-S05` (Hydro Transfer Valve) → `EX-CH07-S06` (Shelter Wall Lock)
- **Linked Puzzle:** **`P-13` Part 2** (*The `20 L` Agro-Lab Nutrient Sacrifice* — locked contract in [`08_PUZZLE_DESIGNS.md`](08_PUZZLE_DESIGNS.md) §P-13)
- **The Player's Decision (Real Alternatives, None Pre-Filled):**
  - With `300 / 320 L` (`93.75%`) in the shelter wall, only **`20 L`** is missing—and the only remaining liquid source is the **Agro-Lab's `20 L` active nutrient reservoir**. Draining it will starve **`40%`** of the current crop canopy (`60%` survives on substrate moisture), but leaving the `20 L` gap open lets a `180 mSv/h` proton stream into the shelter. The player must make the call:
    - **Option A — Dump the `20 L` Agro-Lab Nutrient Tank into Bladder #16 (`320 / 320 L` = `100%` wall coverage, `72%` attenuation → `50.4 mSv/h` perimeter / `<5 mSv/h` core, `-40%` crop yield loss):** Protects all four cadets from acute radiation sickness while keeping `60%` of the *Lal Shak* rootstock and Lot #047 seeds alive to replant in Chapter 8.
    - **Option B — Refuse to Drain the `20 L` Nutrient Tank (`300 / 320 L` = `93.75%` wall):** Saves `100%` of today's leaves, but the unshielded `6.25%` upper gap leaks `180 mSv/h` protons across the shelter (`crew dose > 120 mSv` career limit in `P-14`!).
    - **Option C — Drain Only `10 L` (`310 / 320 L` = `96.9%` wall):** Still leaves an unshielded head-height gap (`dose exceeds 110 mSv` golden threshold).
- **Four Demands Trade-Off & Outpost Status HUD (`M1-28`):**
  - **Radiation Shielding (`S`):** Jumps from `93.75%` → **`100.0%` (`320 / 320 L`, `40 cm` full water wall, `72%` dose reduction)**.
  - **Food Production (`C`):** Drops **`-40%`** (`100% → 60%` active trays; outer trays wilt into `VEGETATIVE_STRESS`, while core *Lal Shak* trays and seed vault survive).
  - **Life Support (`W`):** Locks `320 L` in the bladder walls for the duration of the peak.
  - **Power (`E`):** Manual crank + `150 W` pump finishes the transfer Seconds before peak arrival.
- **NASA Dataset & 10–12yo Takeaway:**
  - **Fixtures:** `nasa_ntrs_water_wall_shielding`, `pds_crater_lro_dose`, `noaa_goes_spe_1989`
  - **10–12yo Takeaway:** *"First Rule of Spaceflight: Crew Life Comes First. You can replant seeds after a storm (`60%` survive!), but you can never undo radiation damage to an astronaut—sacrificing `20 L` of plant water to finish the `320 L` shield wall is the right call every time."*
- **Outcomes:**
  - **Golden Success (Option A — `320 / 320 L`, `100%` wall, `72%` attenuation, `-40%` crop loss):** Unlocks the full `72%` shielding factor needed to keep every cadet `< 110 mSv` in `P-14`.
  - **Partial Success (Option C — `310 / 320 L`):** Crew survives `< 120 mSv` in `P-14` only with zero margin (`116 mSv`), missing the `< 110 mSv` Golden badge.
  - **Failure & Retry (Option B — `300 / 320 L`):** Radiation streaming alarm flashes red across Bladder #16 (`"Unshielded 180 mSv/h Gap Violates Crew Safety Rule #1"`); Ayla herself insists on pulling the Agro-Lab dump valve, and the checkpoint rewinds so the player can throw the valve.
- **Debrief (`Predict → Observe → Explain`):**
  - *Predict:* Why does even a `6.25%` (`20 L`) gap at the top of a radiation water wall matter so much?
  - *Observe:* Protons stream straight through the empty bladder pocket at `180 mSv/h` instead of being attenuated `72%` to `50.4 mSv/h`.
  - *Explain:* Radiation shielding works by line-of-sight mass thickness (`g/cm²`)—a gap in the wall acts like a window for high-energy particles.
- **What Makes It Fun:** The most dramatic character moment in the game: Ayla—who spent six chapters fighting for every drop of water for her grandmother's *Lal Shak*—turning the red emergency dump valve herself to shield her friends.

---

### `EX-M0703` — ALARA Watch Rotation (`EX-CH07-S07`..`S09`) — **Puzzle `P-14`**
- **Scenes & Locations:** `EX-CH07-S07`..`S09` (Storm Shelter Command Table — Crew Dosimeter Board)
- **Linked Puzzle:** **`P-14`** (*Crew Radiation Dose Rotation & ALARA Scheduling* — locked contract in [`08_PUZZLE_DESIGNS.md`](08_PUZZLE_DESIGNS.md) §P-14)
- **The Player's Decision (Real Alternatives, None Pre-Filled):**
  - During the **6-hour super-storm peak**, four watch stations must be covered (`Inner Core Bunker`, `Perimeter Water-Wall Valve Watch`, `Comms Telemetry Watch`, `Breaker/Thermal Watch`). Each cadet starts with a different **cumulative prior mission dose**:
    - **Sofia:** **`14.0 mSv`** (lowest prior dose)
    - **Ayla:** **`15.0 mSv`**
    - **Noah:** **`16.0 mSv`**
    - **Liam:** **`18.0 mSv`** (highest prior dose — from Chapter 4/5 engineering work)
  - The mandatory career/mission safety ceiling is **`< 120.0 mSv`** for every crew member (**Golden ALARA Target: every crew member `< 110.0 mSv`**).
  - Starting with an empty `4 Crew × 4 Shift Slots` grid, the player must assign each cadet's watch station and shift duration so that **inverse-prior-dose weighting** gives the highest-exposure perimeter watch to the cadet with the lowest prior dose (`Sofia 14 mSv`), and the deepest-shielded bunker watch to the cadet with the highest prior dose (`Liam 18 mSv`):
    - **Golden ALARA Assignment (`08_PUZZLE_DESIGNS.md`):**
      - **Sofia (`14.0 mSv` start):** High-exposure Perimeter/Hydro Watch (`+94.0 mSv` storm increment → **`108.0 mSv`** final)
      - **Ayla (`15.0 mSv` start):** Moderate Agro/Valve Watch (`+93.5 mSv` → **`108.5 mSv`** final)
      - **Noah (`16.0 mSv` start):** Shielded Comms Watch (`+93.0 mSv` → **`109.0 mSv`** final)
      - **Liam (`18.0 mSv` start):** Deepest Core Breaker Watch (`+91.2 mSv` → **`109.2 mSv`** final)
      - **Result:** All four cadets finish between **`108.0` and `109.2 mSv`**—every single cadet stays **`< 110.0 mSv` (Golden)** and well below the **`120.0 mSv`** hard ceiling!
- **Four Demands Trade-Off & Outpost Status HUD (`M1-28`):**
  - **Radiation Shielding (`Z`):** Balances cumulative personal dose across all 4 crew (`max = 109.2 mSv < 110.0 mSv` Golden / `< 120.0 mSv` Pass).
  - **Power (`E`), Life Support (`A`/`W`), & Food (`C`):** Keeps all 4 critical watch stations manned throughout the 6-hour storm peak.
- **NASA Dataset & 10–12yo Takeaway:**
  - **Fixtures:** `nasa_std_3001_radiation`, `pds_crater_lro_dose`, `icrp_103_dose_limits`
  - **10–12yo Takeaway:** *"NASA's ALARA rule ('As Low As Reasonably Achievable') means sharing risky jobs fairly—since Liam already absorbed `18 mSv` earlier in the mission and Sofia only has `14 mSv`, Liam takes the deepest-shielded seat so nobody passes the `120 mSv` danger line!"*
- **Outcomes:**
  - **Golden Success (Inverse-prior-dose assignment: `Sofia 108.0`, `Ayla 108.5`, `Noah 109.0`, `Liam 109.2 mSv`):** Every cadet finishes **`< 110.0 mSv`** (`max spread = 1.2 mSv`).
  - **Standard Pass:** Every cadet finishes **`< 120.0 mSv`** (e.g., `max = 114.5 mSv`).
  - **Failure & Retry (Putting `Liam 18 mSv` on Perimeter Watch or leaving one cadet on perimeter for all 6 hours):** Liam's dosimeter hits `124.0 mSv > 120.0 mSv` (`"NASA-STD-3001 Dose Limit Exceeded"`); player swaps shift slots and re-commits.
- **Debrief (`Predict → Observe → Explain`):**
  - *Predict:* What happens if Liam (who starts at `18 mSv`—the highest prior dose) volunteers to take the most exposed perimeter watch?
  - *Observe:* His total dose climbs past `120 mSv`, violating the flight surgeon's limit while Sofia stays down at `102 mSv`.
  - *Explain:* Real astronaut crew scheduling tracks each person's cumulative career/mission badge dose so no individual crosses deterministic tissue or career risk thresholds.
- **What Makes It Fun:** Dragging the 4 cadet portraits across the shelter shift board while watching their four live dosimeter bars level out side-by-side just under the `110 mSv` golden line.

---

### `EX-M0704` — Post-Storm Recovery & Dosimeter Audit (`EX-CH07-S10`..`S12`)
- **Scenes & Locations:** `EX-CH07-S10` (Shelter Exit — Storm Clear) → `EX-CH07-S11` (Hydro-Bay Water Recovery) → `EX-CH07-S12` (Agro-Lab Re-Seeding Bench & `CS-03` setup)
- **Linked Puzzle:** Post-`P-14` water recovery & transition to Chapter 8 (`P-15`)
- **The Player's Decision (Real Alternatives, None Pre-Filled):**
  - With the proton super-storm over and all four cadets safe at `<110 mSv`, the station has **`320 L`** of water sitting inside the shelter wall bladders (`100 L` potable, `200 L` greywater, `20 L` nutrient water) and **`60%`** of the Agro-Lab trays still alive. The player must choose the **Post-Storm Bladder Drain & Re-Planting Protocol**:
    - **Option A — Drain `100 L` Potable Straight to Crew Reserve, `200 L` Greywater to the `P-03` Distillation Loop, and Return the `20 L` Nutrient Bladder Directly to the Agro-Lab to Re-Seed the `40%` Lost Trays:** Restores the `1,200 L` station water inventory for Chapter 8 (`P-16`) and immediately replants all 30 trays for the 66-day rescue countdown!
    - **Option B — Mix All `320 L` Together in One Tank:** Contaminates the `100 L` potable water with `200 L` greywater and `20 L` fertilizer salts.
    - **Option C — Leave All `320 L` Locked in the Shelter Walls:** Leaves the Agro-Lab dry and halts Chapter 8's crop cycle.
- **Four Demands Trade-Off & Outpost Status HUD (`M1-28`):**
  - **Life Support (`W`):** Segregates and recovers all `320 L` into the `1,200 L` station water loop (`90%` recycling efficiency ready for `P-16`).
  - **Food Production (`C`):** Uses the recovered `20 L` nutrient solution + Lot #047 reserve seeds to bring all **30 trays** back online for Chapter 8's 3-harvest cycle.
  - **Radiation Shielding (`S`):** Keeps bladders manifolds connected for rapid re-fill if needed.
- **NASA Dataset & 10–12yo Takeaway:**
  - **Fixtures:** `nasa_ntrs_iss_wpa_2018`, `nasa_std_3001_radiation`
  - **10–12yo Takeaway:** *"Protons passing through water don't make the water radioactive—as soon as the solar storm ends, astronauts can pump that exact same water right back into their drinking and greenhouse tanks!"*
- **Outcomes:**
  - **Success (Option A):** All `320 L` cleanly segregated and recovered; all 30 trays replanted for Chapter 8 (`P-15`).
  - **Failure & Retry (Option B or C):** Cross-contamination or dry-tray warning; player routes the three bladder banks back to their matching loops.
- **Debrief (`Predict → Observe → Explain`):**
  - *Predict:* Is the water inside the radiation shield bladders still safe to drink and water plants with after blocking a solar proton storm?
  - *Observe:* The water conductivity and radiation sensors read completely normal (`0` residual radioactivity).
  - *Explain:* Solar protons stop in water by ionizing/warming molecules slightly (turning kinetic energy into tiny amounts of heat), not by turning `H₂O` into long-lived radioactive isotopes.
- **What Makes It Fun:** Pumping the `20 L` nutrient bladder back into the Agro-Lab, seeing the surviving `60%` crimson *Lal Shak* plants perk up, and planting the new seeds for the final 66-day push.

---

## 9. Chapter 8 — *New Dawn* (`EX-M0801`–`EX-M0804`)

### `EX-M0801` — 66-Day Calorie Bridge (`EX-CH08-S01`..`S03`) — **Puzzle `P-15`**
- **Scenes & Locations:** `EX-CH08-S01` (Command & Agro-Lab Planning Table) → `EX-CH08-S02` (Ration Storage Vault) → `EX-CH08-S03` (3-Cycle Harvest Scheduler)
- **Linked Puzzle:** **`P-15`** (*66-Day Rescue Window Calorie & Ration Bridge* — locked contract in [`08_PUZZLE_DESIGNS.md`](08_PUZZLE_DESIGNS.md) §P-15)
- **The Player's Decision (Real Alternatives, None Pre-Filled):**
  - Earth Mission Control's relief lander will touch down at Shackleton Rim in exactly **`66 days`**.
  - **Calorie Demand (`08_PUZZLE_DESIGNS.md`):** `4 crew × 2,500 kcal/person-day × 66 days =` **`660,000 kcal`** nominal baseline.
  - **Stored Rations Available:** **`462,000 kcal`** (`70.0%` of nominal demand—leaving a **`198,000 kcal` gap** that would starve the crew at Day 46 without greenhouse harvests and ration management!).
  - Starting with `0` harvests scheduled and `100%` ration draw, the player must configure the **66-Day Harvest Schedule & Crew Ration Protocol**:
    1. **Staggered *Lal Shak* Harvest Schedule (`3 cycles × 22 days = 66 days`):**
       - Each 22-day high-density harvest cycle yields **`46,200 kcal`** (`3 × 46,200 =` **`138,600 kcal`** across Day 22, Day 44, and Day 66).
       - **Total Food Energy (`Stored + Grown`):** `462,000 + 138,600 =` **`600,600 kcal`** (`600,600 / 660,000 =` **`91.0%`** of full nominal `2,500 kcal/day` intake!).
    2. **Crew Ration Protocol Slider (`70%` to `100%`):**
       - Set the **Emergency Ration Protocol to `85%`** (`2,125 kcal/person-day` → `561,000 kcal` required over 66 days, or **`91%` max sustainable draw** = `600,600 kcal`), keeping the crew safely above the `80%` (`2,000 kcal/day`) metabolic floor with a `+39,600 kcal` safety reserve at `85%`!
- **Four Demands Trade-Off & Outpost Status HUD (`M1-28`):**
  - **Food Production (`C` / `R`):** `462,000 kcal` stored + `138,600 kcal` grown (`3 × 46,200 kcal`) = **`600,600 kcal` (`91%` supply)**; `85%` (`2,125 kcal/day`) ration protocol bridges all 66 days with zero starvation.
  - **Life Support (`A`):** Continuous 3-cycle canopy growth feeds `1.68 kg/day O₂` into `P-16`.
  - **Power (`E`):** Commits steady `10 kWh/day` (`36 kWh/day` station total) for the 66-day photoperiod schedule.
- **NASA Dataset & 10–12yo Takeaway:**
  - **Fixtures:** `usda_fdc_amaranth_168387`, `pmc_amaranth_spaceflight_2021`, `nasa_ntrs_bvad_2022`
  - **10–12yo Takeaway:** *"Stored space rations (`462,000 kcal`) only last `46 days` on their own—by harvesting fast-growing Lal Shak three times (`Day 22, 44, 66` for `+138,600 kcal`) and trimming meals to `85%` (`2,125 kcal/day`), the crew bridges all `66 days` until rescue!"*
- **Outcomes:**
  - **Golden Success (`3 × 22-day` staggered *Lal Shak* cycles = `600,600 kcal` `91%` supply + `85%` Ration Protocol):** Bridges all 66 days with `+39,600 kcal` buffer above the `85%` draw and zero crew health penalty.
  - **Standard Pass (`90–91%` Ration Protocol with 3 harvests):** Reaches Day 66 with `0–6,600 kcal` reserve.
  - **Failure & Retry:**
    - Keeping rations at `100%` (`660,000 kcal`): Food runs out at Day 60 (`-59,400 kcal` deficit!).
    - Scheduling only 1 or 2 harvests (e.g., slow 62-day wheat): Total calories fall below the `80%` (`528,000 kcal`) safe physiological floor.
- **Debrief (`Predict → Observe → Explain`):**
  - *Predict:* Why can we harvest *Lal Shak* every `22 days` in Chapter 8 when the first seed-to-harvest cycle in Chapter 3 took `28 days`?
  - *Observe:* Starting from established root crowns/transplants under tuned `CO₂` and PAR light shaves `6 days` off each regrowth cycle (`3 × 22 = 66 days`).
  - *Explain:* Staggered nursery transplanting and ratooning (regrowth from cut stems) allow three full harvests inside a 66-day window.
- **What Makes It Fun:** Seeing how Dadi's *Lal Shak* seeds—which started as 49 tiny rescued seeds in Chapter 1 (`P-01`)—literally provide the `138,600 kcal` bridge that saves the crew's lives over 66 days.

---

### `EX-M0802` — Closed-Loop `O₂` & Water Balance (`EX-CH08-S04`..`S06`) — **Puzzle `P-16` (Part 1)**
- **Scenes & Locations:** `EX-CH08-S04` (ECLSS Central Bay) → `EX-CH08-S05` (Bioreactor & Algae/Crop `O₂` Loop) → `EX-CH08-S06` (Water Processor `90%` Loop Console)
- **Linked Puzzle:** **`P-16` Part 1** (*66-Day Oxygen & Water Closed-Loop Mass Balance* — locked contract in [`08_PUZZLE_DESIGNS.md`](08_PUZZLE_DESIGNS.md) §P-16)
- **The Player's Decision (Real Alternatives, None Pre-Filled):**
  - Over **`66 days`**, the 4-person crew requires:
    1. **Oxygen (`O₂`) Demand (`08_PUZZLE_DESIGNS.md`):** `4 crew × 0.84 kg/person-day =` **`3.36 kg/day`** × `66 days` = **`221.76 kg`** (`~221.8 kg` total `O₂`).
       - **Stored Cryo/High-Pressure `O₂` Tanks:** **`140.0 kg`** (leaves an **`81.76 kg` `O₂` deficit** — tanks alone run out at Day 41!).
       - **Biological `O₂` Loop Choice:** Couple the **30-tray *Lal Shak* canopy + Chlorella photobioreactor loop** producing **`1.68 kg/day O₂`** (`50%` of crew demand × `66 days` = **`110.88 kg O₂`**) → Total `O₂` = `140.0 + 110.88 =` **`250.88 kg ≥ 221.76 kg`** (**`+29.12 kg` `O₂` safety surplus!**).
    2. **Water (`H₂O`) Demand (`08_PUZZLE_DESIGNS.md`):** Gross turnover = **`180 L/day`** (`20 L` crew + `15 L` plants + `145 L` hygiene/cooling/humidity condensate) over 66 days (`11,880 L` gross throughput) against a **`1,200 L` total station water inventory**:
       - **Loop Mode Choice:**
         - **Mode A — `90%` Closed-Loop Recycling (`P-03` Vapor Compression Still + Condensate Recovery):** Net unrecovered loss = `10% × 180 L/day =` **`18.0 L/day`** × `66 days` = **`1,188 L` ≤ `1,200 L` inventory** (**`+12.0 L` survival margin at Day 66!**).
         - **Mode B — `75%` Low-Power Filtration Only (Skipping Thermal Vapor Recovery):** Net loss = `25% × 180 L/day = 45.0 L/day` × `66 days` = `2,970 L > 1,200 L` (**Water runs completely dry at Day 26!**).
- **Four Demands Trade-Off & Outpost Status HUD (`M1-28`):**
  - **Life Support (`A` / `W`):** `O₂` hits **`250.88 / 221.76 kg` (`+29.12 kg` surplus)** and Water hits **`1,188 / 1,200 L` (`+12.0 L` reserve at `90%` recycling)**.
  - **Food Production (`C`):** Biological `O₂` loop runs in lockstep with the 3-harvest *Lal Shak* canopy (`P-15`).
  - **Power (`E`):** Allocates continuous thermal-still power to maintain the `90%` water recovery rate.
- **NASA Dataset & 10–12yo Takeaway:**
  - **Fixtures:** `nasa_ntrs_bvad_2022`, `nasa_ntrs_iss_wpa_2018`, `nasa_ntrs_veggie_aph_2020`
  - **10–12yo Takeaway:** *"Four astronauts use `11,880 liters` of water in 66 days, but the station only holds `1,200 liters`—the only way to survive is recycling every drop of sweat, breath humidity, and wash water almost `10 times over` at `90%` efficiency!"*
- **Outcomes:**
  - **Golden Success (`Bio-O₂ Loop = 1.68 kg/day` + `Water Recycling = 90%`):** Delivers `250.88 kg O₂` (`+29.12 kg` surplus) and `1,188 L` net water draw (`+12 L` left in the `1,200 L` tank on Day 66).
  - **Failure & Retry:**
    - Selecting `75%` water recycling: Water tank hits `0 L` on Day 26 (`-1,770 L` deficit).
    - Leaving the biological `O₂` loop below `1.24 kg/day`: `O₂` tanks empty before Day 66.
- **Debrief (`Predict → Observe → Explain`):**
  - *Predict:* Why does dropping water recycling efficiency by just `15%` (from `90%` down to `75%`) make you lose `2.5 times` as much water every day (`45 L/day` lost instead of `18 L/day`)?
  - *Observe:* What matters is the *unrecovered fraction* (`100% - efficiency`): `25%` loss is `2.5×` larger than `10%` loss!
  - *Explain:* On the ISS and future lunar bases, pushing water recovery from `75%` to `90%+` cuts resupply water mass by more than half.
- **What Makes It Fun:** Seeing the massive `11,880 L` 66-day water wheel spin through the `1,200 L` tank ten times over and landing at Day 66 with `+12.0 L` to spare!

---

### `EX-M0803` — All-Four-Demands Master Audit (`EX-CH08-S07`..`S09`) — **Puzzle `P-16` (Part 2)**
- **Scenes & Locations:** `EX-CH08-S07`..`S09` (Central Command Deck — Master Outpost Console)
- **Linked Puzzle:** **`P-16` Part 2** (*Integrated 66-Day Four-Demand Outpost Lock* — [`08_PUZZLE_DESIGNS.md`](08_PUZZLE_DESIGNS.md) §P-15 & §P-16)
- **The Player's Decision (Real Alternatives, None Pre-Filled):**
  - Before transmitting the final **66-Day Autonomous Survival Plan** to Earth Mission Control, all four cadet consoles (**Botany — Ayla**, **Hydro/ECLSS — Sofia**, **Power/Thermal — Liam**, **Radiation/Comms — Noah**) unite on one screen. The player (or 4-player crew) must lock the **4 Master Sustainability Gates** simultaneously:
    1. **Power Gate (`Liam`):** `≥ 36.0 kWh/day` (`36.4 kWh/day` dust-swept array + `16.0 kW ≤ 16.5 kW` thermal balance + `18.0 kWh` storm battery reserve)
    2. **Life Support Gate (`Sofia`):** `O₂ = 250.88 kg ≥ 221.76 kg` (`140 kg` tank + `110.88 kg` bio-loop) AND `Water = 90%` recycling (`1,188 L ≤ 1,200 L` inventory, `+12 L` reserve) at `62.0 kPa / 16.5% eq O₂`
    3. **Radiation Shielding Gate (`Noah`):** `320 / 320 L` (`40 cm`, `72%` attenuation) rapid-fill water-wall protocol armed + ALARA crew dose locked at **`≤ 109.2 mSv < 120.0 mSv`**
    4. **Food Production Gate (`Ayla`):** 3-cycle *Lal Shak* harvest (`138,600 kcal` + `462,000 kcal` stored = **`600,600 kcal` / `91%`**) + **`85%` (`2,125 kcal/day`)** ration protocol with `12°C / 100 W` anti-bolting floor.
- **Four Demands Trade-Off & Outpost Status HUD (`M1-28`):**
  - Displays the full **66-Day Simulation Forecast Curve** across all four demands (`Day 1 → Day 22 → Day 44 → Day 66`). If any single gate is misconfigured, the coupled simulation shows the exact day (`Day 1..66`) where the outpost fails.
- **NASA Dataset & 10–12yo Takeaway:**
  - **Fixtures:** `nasa_ntrs_bvad_2022`, `pds_crater_lro_dose`, `usda_fdc_amaranth_168387`
  - **10–12yo Takeaway:** *"A lunar outpost is one giant living machine: solar power runs the lights and water still, clean water grows the plants and fills the radiation walls, and the plants make food and oxygen to keep the crew alive!"*
- **Outcomes:**
  - **Golden Success (All 4 Master Gates locked to canonical targets):** The 66-day simulation runs to `Day 66: RESCUE LANDER TOUCHDOWN` with all four demands green (`Power +0.4 kWh/d`, `O₂ +29.1 kg`, `Water +12 L`, `Dose ≤ 109.2 mSv`, `Calories +39,600 kcal` above `85%` draw).
  - **Failure & Retry:** Any gate mismatch pauses the 66-day fast-forward at the exact failure day, shows which coupled loop broke, and lets the crew adjust the gate.
- **Debrief (`Predict → Observe → Explain`):**
  - *Predict:* Which of the four demands (`Power`, `Life Support`, `Radiation Shielding`, `Food Production`) is the most important on the Moon?
  - *Observe:* Unplugging *any one* of the four causes the other three to collapse before Day 66!
  - *Explain:* Space habitat engineering is *systems engineering*—every subsystem depends on the outputs of the others.
- **What Makes It Fun:** Watching the 66-day time-lapse simulation tick across all four consoles in harmony as three crops of crimson *Lal Shak* grow and harvest on the screen.

---

### `EX-M0804` — Cohort A8 Survival Manual Handoff (`EX-CH08-S10`..`S12`) — **Campaign Finale (`CS-03`)**
- **Scenes & Locations:** `EX-CH08-S10` (Agro-Lab Bay 1 — Seed Vault Lot #047-A8) → `EX-CH08-S11` (Observation Deck — Relief Lander Approach) → `EX-CH08-S12` (Academy Hall — Cohort A8 Handoff & `CS-03`)
- **Linked Puzzle:** Campaign Synthesis & **Cohort A8 Flight Rules Certification**
- **The Player's Decision (Real Alternatives, None Pre-Filled):**
  - As the relief lander descends toward Shackleton Rim and the incoming **Cohort A8** junior cadets prepare to take over Last Light Academy, Ayla, Sofia, Liam, and Noah must lock the **Four Golden Flight Rules** into the **Academy Survival Manual** (one rule per demand, chosen from the lessons proven across Chapters 1–8) and place the newly harvested **Second-Generation Lot #047-A8 *Lal Shak* Seeds** into the vault:
    1. **Power Flight Rule (`Liam`):** *"Always preserve the `8/12 kWh` (`30 kWh` rover) emergency reserve floor, and sweep dusty arrays selectively (`4 panels = 36.4 kWh net`) when maintenance energy is tight."*
    2. **Life Support Flight Rule (`Sofia`):** *"Purify greywater in three stages (`Settling → Charcoal → Thermal Still <50 ppm`) at `90%` closed-loop recovery, and step leaking compartments down to `62.0 kPa` with enriched `16.5% eq O₂`."*
    3. **Radiation Flight Rule (`Noah`):** *"Crew life comes first: use `40 cm` (`320 L`) hydrogen-rich water walls (`72%` attenuation) or basalt lava tubes during SPEs, and rotate watch shifts inversely by prior dose (`ALARA < 110 mSv`)."*
    4. **Food & Biology Flight Rule (`Ayla`):** *"Match fast `28-day / 22-day` cut-and-come-again crops (*Lal Shak*) to your rescue timeline, hold `≥12°C` (`100 W`) to prevent stress-bolting, and couple plant `CO₂`/`O₂` directly to the cabin loop."*
- **Four Demands Trade-Off & Outpost Status HUD (`M1-28`):**
  - Displays the completed **Campaign Mastery Scorecard** across all 16 puzzles (`P-01`..`P-16`), all 4 demands, and all 28 NASA datasets explored.
- **NASA Dataset & 10–12yo Takeaway:**
  - **Fixtures:** Synthesis card linking all 28 datasets in `game/resources/data/nasa/puzzle_sources.json`
  - **10–12yo Takeaway:** *"Every NASA Flight Rule is written from real data and real emergencies—by mastering power, air and water, radiation shielding, and space farming, you've earned your wings as a Junior Astronaut Mission Commander!"*
- **Outcomes:**
  - **Success:** Locking all 4 Flight Rules triggers **Cutscene `CS-03`** (*Cohort A8 Handoff & Relief Lander Dawn*), awards the **Junior Astronaut Mission Commander Certificate**, and opens the **Campaign Debrief & Replay Screen (`M1-19`)** where players can replay any chapter/mission with different settings or jump into **Mission Trainer (`M1-29`)**.
- **Debrief (`Predict → Observe → Explain`):**
  - *Predict:* If you replayed Chapter 1 (`P-01`/`P-02`) or Chapter 7 (`P-13`/`P-14`) right now, which trade-off would you spot immediately that surprised you the first time?
  - *Observe:* Players compare their first-attempt resource curves against the Golden Flight Rules on the Debrief screen.
  - *Explain:* Simulation training lets astronauts make mistakes safely on a computer so they make the right call when lives and seeds are on the line.
- **What Makes It Fun:** A proud, emotional finale as Ayla places a fresh packet of lunar-grown *Lal Shak* seeds (`Lot #047-A8`) into the vault for the next class of cadets while the rescue lander touches down on the sunlit Shackleton Rim.

---

## 10. Proposals for User Approval (Never Edit Canon Text or `08_PUZZLE_DESIGNS.md` Directly)

Per `AGENTS.md`, `PRODUCTION_HANDBOOK.md` §1, and `M1-27`, **no canon story text in `full-game-story/STORY_FULL.md` (`story-data.json`) and no locked numbers in `game-design/08_PUZZLE_DESIGNS.md` have been edited.** Below are the two sets of proposals compiled for the user's review and approval.

### 10.1 Proposals for the 15 Unsupported/Unit-Framing Numbers in `08_PUZZLE_DESIGNS.md` (from [`docs/SCIENCE_AND_DATA.md`](../docs/SCIENCE_AND_DATA.md) §B3)

As audited in [`docs/SCIENCE_AND_DATA.md`](../docs/SCIENCE_AND_DATA.md) §B3 (`M0-13`), every locked number in `08_PUZZLE_DESIGNS.md` can be kept **100% unchanged in game code** if we approve the following **physical unit / framing annotations** on the in-game NASA Data Cards (`M0-15`, `M1-30`)—or, where noted, the user may optionally approve a future doc update:

| ID | Puzzle | Locked Number in `08_PUZZLE_DESIGNS.md` | Scientific Audit Finding (`docs/SCIENCE_AND_DATA.md` §B3) | Recommended Action for User Approval (Zero Code Breakage) |
| --- | --- | --- | --- | --- |
| **`B3-1`** | `P-01` | `Health = 1 + 2H + L + O + W - penalty`, `49/50` seeds (`98%`) | `98%` germination matches spaceflight amaranth data (`pmc_amaranth_spaceflight_2021`); the integer formula is a normalized `0–10` game index. | **Keep `08` numbers unchanged.** Label the `P-01` Data Card axis as *"Normalized Seed Readiness Index (1–10) calibrated to 98% (`49/50`) spaceflight germination."* |
| **`B3-2`** | `P-02` | `E0=8, A0=6, W0=5, S0=4, C0=5, R0=4` (`0–10` scale) | Normalized `0–10` outpost reserve indices across a 12-hour storm shift. | **Keep `08` numbers unchanged.** Pair each `0–10` bar on the HUD (`M1-28`) with its physical scale (`1 E unit ≈ 1.5 kWh`, `1 W unit ≈ 10 L`, `1 S unit ≈ 10 cm water wall`). |
| **`B3-3`** | `P-03` | `0.1 kWh/L` (`6 kWh` for `60 L`, `70%` recovery = `42 L`) | Simple boiling takes `0.63 kWh/L`, whereas a **Vapor Compression Distillation (VCD)** assembly (like ISS WPA) recovers latent heat and runs at **`~0.09–0.11 kWh/L`**! | **Keep `08` numbers unchanged.** Name the Stage-3 still in the UI/Data Card **"Vapor Compression Distillation (VCD) Assembly (`0.1 kWh/L`)"** (matches `nasa_ntrs_iss_wpa_2018`!). |
| **`B3-4`** | `P-04` | `41 L/day` (`20 L` Crew + `15 L` Seeds + `6 L` Scrubber) | `20 L` (`5 L/person-day`) and `15 L` (`30 × 0.5 L`) are realistic; `6 L/day` for `CO₂` scrubber is a **closed-loop cooling-jacket makeup flow**, not consumed water. | **Keep `08` numbers unchanged.** Label `V3` on the `P-04` manifold **"CO₂ Scrubber Cooling Jacket Loop (`6 L/day`)"**. |
| **`B3-5`** | `P-05` | `30 trays` *Lal Shak*: `+180 g/day O₂`, `-240 g/day CO₂`, `84 kcal/day` (`18 g/day/tray` fresh mass) | `84 kcal/day` (`540 g/day` fresh leaf at `23 kcal/100g` USDA FDC `#168387`) matches `15–20` trays; `+180 g/day O₂` requires **total canopy + root/substrate biomass photosynthesis** (`~168 g/day` dry mass across `~6 m²` high-PAR rack). | **Keep `08` numbers unchanged.** State on the `P-05` Data Card that `+180 g/day O₂` is **Total Canopy + Rootstock Gas Exchange** while `84 kcal/day` is the **Trimmed Edible Leaf Share**. |
| **`B3-6`** | `P-05` | Mixed 30-tray target = **`330 kcal/day`** (`vs 84–118 kcal/day` single-crop rows) | Arithmetically, a linear mix of `84`, `72`, and `118 kcal/day` cannot exceed `118 kcal/day` unless the mixed `15/10/5` allocation represents **intercropped multi-tier canopy density + companion nutrient synergy** (or `kcal/person-day` vs `kcal/tray-set`). | **Keep `330 kcal/day` in `08` for tests.** On the `P-05` Data Card, explain that the `15/10/5` mixed allocation unlocks **Multi-Tier Companion Canopy Density + Microgreen Thinning (`330 kcal/day` combined crew supplement)**. |
| **`B3-7`** | `P-06` | `8 panels × 6 kWh/day = 48 kWh/day`, `-30%` dust (`33.6 kWh`), `2 kWh/panel` sweep (`8 kWh` for 4 panels → `44.4 kWh` gross / `36.4 kWh` net) | If 4 panels are fully cleaned (`24 kWh`) and 4 stay at `-30%` (`16.8 kWh`), sum is `40.8 kWh` unless the electrostatic pulse also shakes `~15%` loose dust off the adjacent 4 panels (`+3.6 kWh` → **`44.4 kWh`**), and the `2 kWh/panel` cost includes pre-heating the actuator arm in `-150°C` shadow. | **Keep `08` numbers unchanged.** Add a 1-line note on the `P-06` Data Card: *"Sweeping 4 primary panels (`24.0 kWh`) + sympathetic electrostatic resonance across the 4 adjacent panels (`20.4 kWh`) yields `44.4 kWh` gross − `8.0 kWh` thermal-actuator cost = `36.4 kWh` net."* |
| **`B3-8`** | `P-07` / `P-08` | `100 kWh` battery, `13.6 km` (`51.8 kWh` drive = `3.81 kWh/km`), `6 kWh` drill, `8 kWh` beacon, `4 kWh` shelter = `69.8 kWh` (`30.2 kWh` reserve) | An unpressurized LRV uses `~0.25 kWh/km`, whereas a **3–4 ton Pressurized Lunar Cabin Rover** climbing steep soft-regolith crater rims (`15°–20°`) with active cabin ECLSS/thermal systems uses **`3.2–5.0 kWh/km`** (`nasa_ntrs_rover_power_2020`). | **Keep `08` numbers unchanged.** Explicitly label the vehicle on the `P-07` Data Card **"Pressurized 4-Crew Lunar Surface Rover (3.8 t mass, active cabin ECLSS)"**. |
| **`B3-9`** | `P-09` | `42.0 kW` load (`12.2 + 8.4 + 11.6 + 9.8 kW`), `45.0 kW` breaker, `18.5 kW` cooling limit (`≤16.5 kW` target at `33.6 kW` electrical) | Since all electrical power inside a sealed habitat eventually becomes heat, `33.6 kW` electrical equals `16.0 kW` on **Coolant Loop B** because **Primary Loop A is still rejecting `17.6 kW`** (`33.6 - 17.6 = 16.0 kW` on cracked Loop B!). | **Keep `08` numbers unchanged.** Label the thermal gauge on `P-09`: **"Secondary Radiator Loop B Load (`16.0 / 16.5 kW`; Primary Loop A carries `17.6 kW` fixed base heat)"**. |
| **`B3-10`** | `P-10` | `101.3 → 62.0 kPa` cuts leak `12.0 → 5.1 L/h`; `O₂` `20.9% → 16.5%` (`≥16.0%` floor); transpiration `-15%` (`15 → 12.75 L/d`) | At `62.0 kPa`, `16.5%` is the **sea-level equivalent `O₂` fraction** (`pO₂ ≈ 16.7 kPa`, achieved by setting the actual gas molar fraction to **`~26.9% O₂`** at `62.0 kPa`, matching NASA-STD-3001!). Also, lower pressure alone increases evaporation, so the **`-15%` transpiration drop** is caused by the **`50%` LED dimming (`P-09`) + higher cabin relative humidity** during lockdown. | **Keep `08` numbers unchanged.** Display both **"16.5% Sea-Level Equivalent O₂ (`26.9%` molar at `62.0 kPa`)"** and note that **"-15% water draw follows from `P-09` 50% LED dimming + sealed humidity"**. |
| **`B3-11`** | `P-11` / `P-12` | `18.0 kWh` battery over `48 h` (`375 W` avg: `150 + 100 + 80 + 45 W`); `12°C` floor prevents *Lal Shak* bolting (`82%` vs `45%`) | *Amaranthus tricolor* is a tropical C4 leafy green that suffers **chilling injury / stress-induced flowering (`bolting`)** below `10–12°C`. | **Keep `08` numbers unchanged.** Frame the `12°C` threshold on the `P-12` Data Card as **"Tropical C4 Chilling & Stress-Bolting Floor (`≥12°C`, `50 µmol/m²/s`)"**. |
| **`B3-12`** | `P-12` | `500 kW` beacon pulse using `4.2 kWh` energy | `4.2 kWh ÷ 500 kW = 0.0084 hours =` **`30.24 seconds`** of integrated pulse-train duration stored in a supercapacitor bank! | **Keep `08` numbers unchanged.** Label the `P-12` beacon spec **"500 kW Pulsed Radar/Telemetry Burst (`30.2 s` integrated duty from `4.2 kWh` Supercapacitor Bank)"**. |
| **`B3-13`** | `P-13` | `320 L` water (`200 + 100 + 20 L`) = `40 cm` (`40 g/cm²`) water wall, `72%` attenuation of `180 mSv/h` | `40 g/cm²` of water reducing an October-1989-class proton spectrum by `~72%` matches NASA OLTARIS/HZETRN physics (`nasa_ntrs_water_wall_shielding`). Geometrically, `320 L` at `40 cm` thickness covers **`0.80 m²` of directional storm-bunker aperture/roof window** (where the crew's heads/torsos shelter against the rest of the regolith-bermed core). | **Keep `08` numbers unchanged.** Describe the `320 L` bladder array on the `P-13` Data Card as **"Directional `0.8 m² × 40 cm` Storm-Shelter Hatch & Overhead Water Window (`320 L`)"**. |
| **`B3-14`** | `P-14` | Prior doses `15, 18, 14, 16 mSv`; post-storm `<120 mSv` (`<110 mSv` golden, `~91–94 mSv` storm increment) | `120 mSv` is a conservative **Junior Cadet / Mission Administrative Dose Ceiling** (stricter than NASA-STD-3001's `250 mSv` 30-day BFO limit and `600 mSv` career limit, appropriate for an Academy training outpost!). | **Keep `08` numbers unchanged.** Label `120 mSv` on the `P-14` Data Card **"Academy Mission Administrative Dose Limit (`120 mSv`; NASA-STD-3001 30-day BFO limit is `250 mSv`)"**. |
| **`B3-15`** | `P-15` | `3 harvests × 46,200 kcal = 138,600 kcal` *Lal Shak* over 66 days (`2,100 kcal/day` average across 30 trays) | Raw *Amaranthus tricolor* leaves alone (`23 kcal/100g`) would require `9.1 kg/day` (`~300 g/day/tray`), whereas **high-density 3-tier aeroponic racks + edible amaranth grain/seed heads & starch supplement trays** in the 30-bay unit deliver `46,200 kcal` per 22-day cycle. | **Keep `08` numbers unchanged.** Note on the `P-15` Data Card that Chapter 8's 66-day mode runs **"Full 3-Tier High-Density Canopy + Amaranth Grain/Leaf Co-Harvest (`46,200 kcal` per 22-day cycle)"**. |
| **`E7`** | `CH05` (`P-09`) | Story text says `"3.2 on the lunar seismic scale"` | Seismology uses **Richter / body-wave / moment magnitude (`M 3.2`)** recorded by the Apollo Passive Seismic Experiment (`pds_apollo_pse_moonquakes`, up to `M 5.5` shallow moonquakes). | **Keep story text unchanged.** On the `P-09` Data Card, explain: *"'3.2 on the lunar seismic scale' means body-wave magnitude `M_b 3.2` as calibrated by the Apollo Passive Seismic Network."* |

---

### 10.2 Proposals for Wrapping Story-Only Missions with Concrete Gameplay Decisions (Zero Canon Dialogue Changes)

In the current `story-data.json` and `extended_gate_catalog.gd`, 16 of the 32 missions directly host `P-01`..`P-16`, while the remaining 16 missions either split a puzzle's setup or advance the narrative investigation between puzzles. To satisfy **`R07`** (*"Every mission has a concrete training decision the player makes themselves"*) without altering a single word of canon dialogue in `STORY_FULL.md` or changing any number in `08_PUZZLE_DESIGNS.md`:

1. **Pre-Puzzle Diagnostic / Setup Missions (`EX-M0101`, `EX-M0102`, `EX-M0201`, `EX-M0301`, `EX-M0501`, `EX-M0601`, `EX-M0603`, `EX-M0701`):**
   - **Proposal:** Present the mission's decision as the **Stage-1 Pre-Check / Subsystem Isolation Console** (specified in §§2–8 above) before unlocking the main puzzle console in the following mission. All numbers feed directly into the locked `08_PUZZLE_DESIGNS.md` inputs for that chapter's puzzle.
2. **Post-Puzzle Verification / Transition Missions (`EX-M0204`, `EX-M0303`, `EX-M0304`, `EX-M0404`, `EX-M0504`, `EX-M0704`, `EX-M0803`, `EX-M0804`):**
   - **Proposal:** Present the mission's decision as the **Operational Verification & Resource Banking Console** (e.g., `EX-M0204` Low-Gravity Mist & Phototropism Cue; `EX-M0303` Canopy Airflow & PAR Tuning; `EX-M0304` Cut-and-Come-Again Thinning; `EX-M0504` Banking the `+2.25 L/day` & `-0.8 kW` `62 kPa` savings; `EX-M0704` Segregating the `320 L` storm-wall water back into Potable/Greywater/Nutrient loops; `EX-M0804` Locking the 4 Golden Flight Rules into the Cohort A8 Manual).
   - **Impact on Canon:** Zero dialogue lines in `STORY_FULL.md` or `story-data.json` change, and zero test assertions in `game/tests/` break.
