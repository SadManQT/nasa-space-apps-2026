# Science check and NASA data plan (v7 FINAL)

**Team The Last BrainCell** · LAST LIGHT ACADEMY · 6 October 2026

This document makes the game's science defensible to NASA judges. It has five parts:
- **A** checks every scientific claim in the game and says what we fixed.
- **B** maps every NASA and partner dataset to the puzzle and number it drives (rewritten 3 Nov 2026, board M0-13).
- **C** is the step-by-step data pipeline for the hackathon.
- **D** sets out the honesty rules.
- **E** (new, 7 October) checks the facts and data for Season 1, Chapters 2–8 ([`CAMPAIGN_SEASON1.md`](CAMPAIGN_SEASON1.md)).

Everything here is design work. The data processing itself happens during the hackathon (13–14 Nov), as the rules require.

**Revised 24 October 2026 (STORY-04/05):** rows 1–3, 12 and 13, the "What judges will notice" note in §B and the honesty rules in §D now match the stricter claim register in [`game-design/16_SCIENTIFIC_ACCURACY.md`](../game-design/16_SCIENTIFIC_ACCURACY.md). Site-specific sky claims are a **training scenario** until pipeline step 4 is done and checked.

---

## A. Science audit: every claim, checked

**Legend**

| Mark | Meaning |
|---|---|
| ✅ | Correct as written |
| ✏️ | Was wrong or loose in v6, now fixed |
| 🎮 | A deliberate gameplay simplification, with the real basis named |

| # | Claim in the game | Verdict | The accurate version we now use | Source |
|---|---|---|---|---|
| 1 | "The Sun sets for 43 hours" | ✏️ | The 43 hours in Speyerer & Robinson (2013) is the longest time **three outposts** near Shackleton were dark at once, not one site. For a single sunny site on **Shackleton's rim**, the longest continuous darkness is **about 1.5 days** (Mazarico et al. 2011). Our night is **≈ 36 hours = 5 shifts of ≈ 7 h**. On the Shackleton–de Gerlache ridge, the worst case over a 19-year cycle is 3–5 days (Gläser et al. 2014), so 36 h is a fair "longest night of the year" for a rim site. **On screen it is a training scenario sized to these studies**, not a measured night at Aurora, until step 4 computes one | Mazarico et al. 2011, *Icarus*; Speyerer & Robinson 2013, *Icarus*; Gläser et al. 2014, *Icarus* |
| 2 | "Sunlit 94% of the time" | ✏️ | That 94% is also a combined figure for two or three sites. The v7 replacement, "about 240 days in a row", is **withdrawn** (24 Oct): it is not verified for Aurora's fictional site. We say "rim sites like this are among the best-lit places on the Moon", then show the base pixel's measured % from the LROC map once step 2 has read it | Mazarico 2011; LROC `WAC_POLE_ILL_PCT_SOUTH` |
| 3 | Earth sinks below the horizon, and the radio goes silent | ✏️ | From the south pole, Earth bobs up and down by about ±6.7° every ~27 days, so whether it is visible depends on the exact site, libration and terrain; one proposed site has ~51% direct-to-Earth availability. We no longer say "visible about half of each month" as a general rule. Aurora's Earth-set timing is a training scenario until step 4. The base has **no relay satellite yet**, like early Artemis missions. Earth stays down for about two weeks, so it doesn't return during the night | JPL IPN Progress Report 42-176; Speyerer & Robinson, LEAG 2025 |
| 4 | The storm replays 10 Sep 2017 | ✅ | X8.2 flare: started 15:35 UT, peaked 16:06 UT. First relativistic particles detected at the ground (GLE 72) at about 16:15 UT. >100 MeV protons from 16:25 UT; >10 MeV from 16:45 UT. LRO's CRaTER instrument **measured this event at the Moon** | NASA DONKI; GLE 72 papers; LRO CRaTER (PDS) |
| 5 | Rafi's forecast: "sunspot 2673 just fired a giant flare" | ✅ | The X9.3 flare of 6 Sep 2017 came from active region 12673, four days before the X8.2 | NASA DONKI |
| 6 | The alarm comes from Rafi's counter, not from seeing the flare | ✅ (was implicit) | During the night the Sun is below the local horizon, so the base can't see the flash, and Earth is down, so no forecast arrives. The first warning is the onboard radiation counter catching the fastest particles, as Orion's HERA sensor would | NASA (Orion HERA) |
| 7 | A full water wall protects the crew | ✅ 🎮 | A full wall = 6 units ≈ **20 g/cm² ≈ 20 cm of water**, NASA's storm-shelter guideline (normal operations ≈ 2 g/cm²). The zap table (3/2/1/0 per storm shift) is a simplified scale; NASA's analyses show the dose falls sharply up to ~20 g/cm², with little gain beyond. To be calibrated with the CRaTER storm profile (§B) | NASA lunar radiation protection talk (Clowdsley); NASA Water Walls study |
| 8 | Pumping the wall costs power | ✏️ | Pumping a few hundred litres takes almost no energy. The real costs are **time** (pumps move ~one wall level per shift, so only +2 in the ~40-minute warning) and **where the water comes from**. Our shelter water is the **garden's hydroponic reservoir**: a wall holding 4 or more units leaves Alo's roots thirsty | Pump physics; hydroponic practice (roots dry fast without solution) |
| 9 | The air maker uses water | ✏️ | Electrolysis makes 1 kg of O₂ from ~1.1 L of water, a negligible amount per shift. The real cost is **energy**: ~9–10 kWh per kg of O₂ in practice, so 1 sun-drop ≈ one shift of oxygen for 4 crew | NASA BVAD (O₂ ≈ 0.82–0.90 kg per person per day); ISS oxygen generator |
| 10 | CO₂ scrubbers | ✅ (now explained) | Oxygen can be stored and made later, but CO₂ must be removed all the time. That's why the scrubbers sit in "base basics", which can never be switched off | NASA ECLSS |
| 11 | Alo droops with no lamp | ✏️ (explained) | In the dark, plants keep respiring and burn stored sugar: **OFF = −1**. A DIM lamp is about the **light compensation point**, where growth and respiration break even: **±0**. FULL light gives net growth: **+1** | Plant physiology |
| 12 | Alo and cold | ✅ | Cool temperatures slow *Brassica rapa* (COOL −1). Near freezing, frost damages leaves and flowers (COLD −2). The 2019 Chang'e-4 sprout did not survive its first lunar night (we no longer quote a tissue temperature; see SCI-10) | Chang'e-4 reports (UPI, Smithsonian); crop cold-tolerance basics |
| 13 | The storm and Alo | ✏️ (new fact) | Plants tolerate far more radiation than people. *Arabidopsis* has a lethal dose above 600 Gy, while a few gray can kill a person. **In this scenario the storm is not Alo's main danger**: cold and thirst are. We do not claim plants are immune (SCI-11) | Radiation-biology literature (Arabidopsis LD₅₀) |
| 14 | Growing plants costs mostly light | ✅ (now explained) | In controlled-environment crop production at a lunar outpost, electric lighting is the single biggest energy demand. That's why Mei's lamp costs sun-drops | Poulet et al. 2014, *Life Sciences in Space Research*; NASA LED research |
| 15 | Alo's species | ✏️ (upgrade) | Alo was a zinnia; now it is **Brassica rapa**. That is the species NASA's **LEAF** experiment will grow on the Moon (picked for Artemis III in 2024; after NASA reshaped Artemis in February 2026, LEAF has no fixed flight yet and is being prepared for one of the first Artemis landings, planned from 2028), the **Wisconsin Fast Plant** used in 20,000+ classrooms (seed to flower in ~14 days), and the same species as Bangladesh's **Tori mustard (সরিষা)** | NASA/Space Lab LEAF; Fast Plants program; BARI mustard varieties |
| 16 | Alo's chamber sits outside on the surface | ✅ | LEAF itself is a sealed chamber on the lunar surface with its own lights, water and air. Alo's dome is a bigger cousin, heated through Kai's heater line | Space Lab / NASA LEAF |
| 17 | Solar panels on tall masts | ✅ | Like NASA's **VSAT** project: vertical arrays on ~10 m masts to catch the low polar Sun. NASA's relocatable-array study targets 10 kW. Our two masts give ≈ 11 kW on average in daylight (8 sun-drops per 7-hour shift) | NASA VSAT (Game Changing Development); NASA TM-20210011743 |
| 18 | Battery jar = 20 sun-drops | 🎮 | 20 × 10 kWh = 200 kWh, about what a small habitat needs for a ~36-hour night at ~4–5 kW, or a regenerative fuel cell. An [E] estimate | Our energy budget (§A, item 24) |
| 19 | Breathing | ✅ | 4 crew × ~0.84 kg O₂ per day ≈ 1 kg per 7-hour shift = **1 air unit**. The 6-unit starting reserve (~2 days) is a gameplay choice [G] | NASA BVAD 2022 |
| 20 | Water recycling, 98% | ✅ (fun fact only) | The ISS recovers 98% of its water, sweat and urine included. It's in the debrief, not a game rule | NASA ECLSS (2023) |
| 21 | Moonquake surprise card | ✅ | Shallow moonquakes near the south pole could shake the ground and trigger landslides | Watters et al. 2024 |
| 22 | Kelly's zinnias | ✅ | Zinnias on the ISS nearly died of mould in Dec 2015. NASA let Scott Kelly care for them on his own judgement, and they bloomed on 16 Jan 2016 | NASA; Space.com |
| 23 | Heat levels | 🎮 | In the garden chamber, COZY ≈ 20 °C, COOL ≈ 10 °C and COLD ≈ 0 °C. Heater power is an [E] estimate: COZY ≈ 2.8 kW, COOL ≈ 1.4 kW | Engineering estimate |
| 24 | The energy scale | 🎮 | 1 sun-drop ≈ 10 kWh; 1 shift ≈ 7.2 h; solar ≈ 11 kW average (two 10-m masts); base basics ≈ 1.4 kW (scrubbers, fans, radio, computers, water recycler) | Engineering estimate |
| 25 | Crew first, science second | ✅ (now explicit) | Mission priorities are (1) crew safe, (2) base running, (3) science goal (Alo). Running out of air ends the mission whatever happens to Alo, as real flight rules would | NASA mission rules practice |

**What judges will notice:**
- Every number in Engineer Mode carries a tag: [M] measured, [E] estimate, [G] gameplay or [F] fiction.
- Every simplification has a named real basis.

---

## B. NASA-data-first map: every dataset, what we compute, which number it drives

**Revised 3 November 2026 (board M0-13).** One question decides Relevance: *is this NASA-data-first or NASA-data-added?* The answer is B1 (each dataset → what we compute → the puzzle and number it drives → how the player sees it) and B2 (each puzzle P-01 to P-16 → its datasets). The game's four life-support levers come from NASA numbers: air units are NASA BVAD oxygen use, the energy scale is NASA's 10 kW south-pole solar array, the water wall is NASA's 20 g/cm² shielding guidance, and the storm is a replay of NASA DONKI and GOES records. Partner data (NOAA, USGS/IAU, ESA, ISRO, JAXA, CNSA, UW–Madison) is labelled with its agency.

Every row was checked live on **3 November 2026**: each URL answered HTTP 200 (`curl -sIL`), each API returned the records listed, and each DOI resolved through doi.org and Crossref. The official 28 October Resources tab has not been pasted into the repo yet (board M0-12), so these are the best NASA and partner sources we could verify; the reconciliation list is at the end of this file.

**Fixtures.** `production/tools/fetch_nasa_data.py` (board M0-14) writes one small JSON file per row to `game/resources/data/nasa/<fixture>.json` with the source URL, ID/DOI, retrieval date, licence, the extracted values and the derived game numbers with their formulas. The Data Card (board M0-15) reads those files, so the player sees the dataset name, what was measured, what the game computed, the URL and the citation. `puzzle_sources.json` in the same folder maps P-01 to P-16 to their fixtures.

**Licence shorthand:** *US Gov* = a U.S. Government work (NASA, NOAA, USGS), no U.S. copyright, free to use with credit. *Quoted* = facts and values quoted with a citation; the article text stays © its publisher. *CC BY-NC-SA* = Wisconsin Fast Plants open resources (non-commercial, attribution).

### B1. Datasets → computation → game number → what the player sees

| # | Dataset or source (agency) | ID / DOI | URL | Licence | What we compute | Drives (puzzle · number) | Player sees | Fixture |
|---|---|---|---|---|---|---|---|---|
| 1 | **NASA DONKI** flares, CMEs and SEPs, 4–12 Sep 2017 (NASA GSFC CCMC) | DONKI records `2017-09-10T15:35:00-FLR-001`, `2017-09-10T16:25:00-SEP-001`, `2017-09-10T16:45:00-SEP-001`, `2017-09-10T16:09:00-CME-001`, `2017-09-06T11:53:00-FLR-001` | <https://ccmc.gsfc.nasa.gov/DONKI-API/get/FLR?startDate=2017-09-04&endDate=2017-09-12> (and `/SEP`, `/CME`) | US Gov | Observed times: X9.3 flare 6 Sep 11:53–12:02 UT; X8.2 flare 10 Sep 15:35 start, 16:06 peak (AR 12673); CME 2,650 km/s; GOES >100 MeV onset 16:25, >10 MeV 16:45. Warning lead time = onset − flare start = **70 min** (>10 MeV) | P-02 shift-5 alarm and Rafi's shift-2 forecast; CH1 replay label "10 Sep 2017" | Storm timeline and Data Card "Observed: NASA DONKI" | `donki_2017_09` |
| 2 | **GOES-13 EPEAD corrected integral proton flux**, 5-min (NOAA NCEI; partner agency) | `g13_epead_cpflux_5m_20170901_20170930` (west-facing detector, `ZPGT10W`, `ZPGT100W`) | <https://www.ncei.noaa.gov/data/goes-space-environment-monitor/access/avg/2017/09/goes13/csv/g13_epead_cpflux_5m_20170901_20170930.csv> | US Gov | Hourly >10 and >100 MeV flux 10 Sep 12:00 → 12 Sep 12:00. >10 MeV passes 10 pfu at 16:45 UT and peaks at **1,347 pfu** (11 Sep 00:55). Mean flux in the first 7.2 h after onset 359 pfu, in the next 7.2 h 923 pfu, so the second storm shift is **2.6×** the first | P-02 storm shifts 5–6 (Z table); debrief chart | "The real storm at Earth orbit" chart | `goes13_protons_2017_09` |
| 3 | **NASA DONKI**, 22–26 Jul 2012 (NASA GSFC CCMC) | `2012-07-23T02:36:00-CME-001`; SEPs `2012-07-23T03:59:00-SEP-001` (STEREO-A), `2012-07-23T14:00:00-SEP-001` (GOES-13); shock `2012-07-23T20:55:00-IPS-001` | <https://ccmc.gsfc.nasa.gov/DONKI-API/get/CME?startDate=2012-07-22&endDate=2012-07-26> (and `/SEP`, `/IPS`) | US Gov | CME speed **3,435 km/s**, aimed at STEREO-A, not Earth; particle onset 03:59 UT; shock arrival 20:55 UT | P-13/P-14 counterfactual storm, labelled "what if" | Data Card "Observed at STEREO-A; the Moon strike is fiction" | `donki_2012_07` |
| 4 | **STEREO-A HET proton flux** (NASA SPDF CDAWeb, HAPI) | CDAWeb `STA_L1_HET`, parameter `Proton_Flux` (11 energy bins, 1-min) | <https://cdaweb.gsfc.nasa.gov/hapi/data?id=STA_L1_HET&parameters=Proton_Flux&time.min=2012-07-23T00:00:00Z&time.max=2012-07-26T00:00:00Z&format=csv> | US Gov | Fluence in six 7.2 h steps from the 03:59 UT onset, normalised to the largest step: 80 MeV **[0.16, 0.69, 1.00, 0.02, 0.01, 0.00]**; 14 MeV [0.03, 0.09, 1.00, 0.09, 0.03, 0.01] | P-13/P-14 step multipliers [1,1,2,2,1,1] (comparison; see B3) | Real curve beside the game's three waves | `stereo_a_het_2012_07` |
| 5 | **LRO CRaTER daily dose rate** (NASA LRO; CRaTER team, UNH; archived at PDS PPI) | CRaTER L30 detector daily dose, D1–D6, mGy(Si)/day | <https://crater-products.sr.unh.edu/data/inst/dose/table_l30drate.php> | US Gov (NASA mission data) | D1 dose 22 Jul 2012 **0.57** → 24 Jul **3.92 mGy/day** (×6.8): the Moon saw particles from the July 2012 events even though the CME itself missed | P-13/P-14 boundary: what really reached the Moon | "Measured at the Moon" line on the CH7 Data Card | `crater_dose_2012_07` |
| 6 | **LOLA illumination study**, Mazarico et al. 2011 (NASA GSFC) | NTRS 20120010094; DOI 10.1016/j.icarus.2010.10.030 | <https://ntrs.nasa.gov/citations/20120010094> | Quoted | A Shackleton-rim site is sunlit for 240 days in a row and its longest total darkness is **about 1.5 days** → the game night 5 × 7.2 h = 36 h | P-02 night length (shifts 3–7) | Data Card "Training scenario sized to LOLA" | `lro_mazarico_2011_illumination` |
| 7 | **JPL Horizons**, Sun from the lunar south pole (NASA JPL, DE441) | Horizons observer table, target 10, `coord@301` 0°E −90° h 0 km, daily 2046–2047 | <https://ssd.jpl.nasa.gov/api/horizons.api> | US Gov (JPL service) | Sun elevation swings **−1.56° to +1.59°**; midwinter minimum 1 May 2046 and 21 Apr 2047, midsummer 16 Oct 2046; +0.14° on 12 Jan 2047 | E1 seasons; P-02 dates near midwinter; P-11 Sun near the horizon | "Why the Sun stays low" strip | `jpl_horizons_pole_season` |
| 8 | **JPL Horizons**, Earth and Sun from the pole, 1 Apr → 5 May 2046, 6-hourly | Horizons, targets 399 and 10, same site | <https://ssd.jpl.nasa.gov/api/horizons.api> | US Gov (JPL service) | Earth set at the pole on **15 Apr 2046** and rose on **28 Apr 2046**; through the CH1 night (25 Apr 18:00 → 27 Apr 06:00) it was 3.4° → 1.4° below the horizon | P-02 "Earth down all night"; shift-4 Earth-set (see B3) | Earth path in the horizon strip | `jpl_horizons_ch1_sky` |
| 9 | **JPL Horizons**, Earth from Mons Malapert and from the pole, 8–10 Apr 2047 | Horizons, target 399, sites −1.67°E −85.98° and 0°E −90° | <https://ssd.jpl.nasa.gov/api/horizons.api> | US Gov (JPL service) | From Mons Malapert at 9 Apr 00:45–01:45 UT Earth is at azimuth **357.9°–358.0°**, elevation **−2.3°** (geometric); it clears a smooth horizon from any point ≥ **1.4 km** above the 1,737.4 km sphere. From the pole Earth is 4.3°–6.7° down | P-16 Earth bearing E3; why Aurora needs the relay | Dish-aiming dial labelled "Computed, no terrain" | `jpl_horizons_ch8_relay` |
| 10 | **Gazetteer of Planetary Nomenclature** (USGS / IAU; partner) | Feature IDs 16338 Mons Malapert (−85.98°, −1.67°), 5450 Shackleton (−89.67°, 129.78°), 1439 de Gerlache | <https://planetarynames.wr.usgs.gov/Feature/16338> | US Gov | Great-circle distance on a 1,737.4 km sphere: pole → Mons Malapert **121.9 km**, Shackleton centre → Mons Malapert 128.7 km; bearing from Malapert to Shackleton **176.7°** | P-15 "120 km each way"; P-16 local bearing L2 | Route map distance and dial | `usgs_gazetteer_south_pole` |
| 11 | **Lunar eclipse catalog 2001–2100** (NASA GSFC, Espenak) | Catalog number 09755, 12 Jan 2047, Saros 125 | <https://eclipse.gsfc.nasa.gov/LEcat5/LE2001-2100.html> | US Gov | Greatest eclipse 01:26:14 TD (ΔT 90 s → 01:24:44 UT); penumbral 337.2 min, partial 208.9 min, total **70.0 min**. Contacts U1 23:40, U2 00:50, U3 02:00, U4 03:09 UT. A point on the Moon is fully shadowed for between 70 and 209 min | P-11 five segments; P-12 ingress/ring/egress; E19/E20 | Eclipse timeline Data Card | `nasa_eclipse_2047_01_12` |
| 12 | **NASA BVAD Rev 2** (2022), Table 3-31, p. 58 | NASA/TP-2015-218570/REV2; NTRS 20210024855 | <https://ntrs.nasa.gov/citations/20210024855> | US Gov | O₂ 0.895 kg, CO₂ 1.085 kg, food 0.800 kg, water 3.217 kg per crew member per day; cabin 101.3 kPa (ISS) or 57 kPa (exploration). **1 air unit = 4 crew × 0.895 × 7.2/24 = 1.07 kg O₂**, so air per shift = crew/4 (4 → 1, 5 → 1.25, 2 → 0.5); food per shift = crew × 0.3 crew-days | P-02 A−1, R−1.2; P-10/P-13 A1.25, R1.5; P-07/P-15 A0.5 | Engineer Mode units on the air and food bars | `bvad_2022_metabolic` |
| 13 | **Relocatable 10 kW Solar Array for Lunar South Pole Missions** (NASA LaRC TM, part of VSAT) | NASA/TM-20210011743; NTRS 20210011743 (VSAT overview NTRS 20220013210) | <https://ntrs.nasa.gov/citations/20210011743> | US Gov | 10 kW per array, blanket raised 10 m. Daylight income 8 sun-drops × 10 kWh / 7.2 h = **11.1 kW mean = 56 % of two 10 kW arrays** [E] | P-02 day income +8, cap 20; P-10 dust 8 → 6 | Kai's mast panel in Engineer Mode | `vsat_relocatable_array` |
| 14 | **Protecting Astronauts from Space Radiation on the Lunar Surface** (NASA LaRC, Clowdsley 2021) | NTRS 20210009760 | <https://ntrs.nasa.gov/citations/20210009760> | US Gov | Surround crew with **20 g/cm²** of hydrogen-rich shielding; more adds little. Full wall 6 units = 20 g/cm² of water, **1 unit = 3.3 cm**. Slide 37 (Aug 1972 SPE, rover shelter): 185 mSv at 5 g/cm², 137 at 7, 105 at 10, 85 at 15 | P-02 W cap 6 and S table; P-13 W4 + K2 = S6 | Wall gauge in g/cm² and the real dose curve | `clowdsley_2021_shielding` |
| 15 | **Apollo shallow moonquake locations** (NASA PDS Geosciences; Nakamura 1979) | `urn:nasa:pds:apollo_seismic_event_catalog`, `nakamura_1979_sm_locations.csv` | <https://pds-geosciences.wustl.edu/lunar/urn-nasa-pds-apollo_seismic_event_catalog/data/nakamura_1979_sm_locations.csv> | US Gov | 28 shallow quakes, 1971–1976; the south-polar one on **13 Mar 1973** at 84°S 134°W, magnitude 3.2 (largest in the list, tied) | P-05 phase-2 aftershock; CH3 quake | Seismogram card "Real Apollo record" | `apollo_shallow_moonquakes` |
| 16 | **NASA Lunar Impact Monitoring** (NASA MSFC Meteoroid Environment Office) | NTRS 20150016513 (Suggs et al. 2014 summary); NTRS 20170004471 (2015 Geminids) | <https://www.nasa.gov/meteoroid-environment-office/lunar-impact-monitoring/> | US Gov | Two telescopes, about 10 nights a month; **126 calibrated flashes** in 5 years, 62 % linked to meteor showers; the Geminids gave over 80 detections | P-10 eight candidates, six verified, two fixed artifacts | Flash-review card | `meo_lunar_impact_flashes` |
| 17 | **LCROSS water in Cabeus** (NASA ARC), Colaprete et al. 2010 | DOI 10.1126/science.1186986 | <https://science.nasa.gov/mission/lcross/> | Quoted | Water ice **5.6 ± 2.9 %** by mass at the impact site | P-07 positive ice samples; E12 | Ice-scanner Data Card | `lcross_water_2009` |
| 18 | **LRO Diviner cold traps** (NASA LRO), Paige et al. 2010 | DOI 10.1126/science.1187726 | <https://www.diviner.ucla.edu/science> | Quoted | Subsurface temperature at the LCROSS site **38 K** | P-07 cold trap; P-08 why the vault stays frozen; E11 | Heat tip and vault card | `diviner_cold_traps` |
| 19 | **Moon Mineralogy Mapper on Chandrayaan-1** (ISRO mission, NASA instrument), Li et al. 2018 | DOI 10.1073/pnas.1802345115 | <https://doi.org/10.1073/pnas.1802345115> | Quoted | Exposed ice in some cold traps, up to ~30 wt % in some pixels, but only **~3.5 %** of cold traps show it | P-07 "ice is patchy: survey, don't assume" | Partner-data line on the ice card | `chandrayaan1_m3_ice` |
| 20 | **SELENE (Kaguya) Terrain Camera** (JAXA), Haruyama et al. 2008 | DOI 10.1126/science.1164020 | <https://darts.isas.jaxa.jp/planet/pdap/selene/> | Quoted | Shackleton floor below ~90 K, but no exposed pure ice at 10 m resolution | P-07/P-08 boundary | Partner-data line | `kaguya_shackleton_floor` |
| 21 | **VIPER rover** (NASA) | NASA VIPER rover and instruments page | <https://science.nasa.gov/mission/viper/rover-and-instruments> | US Gov | Inclines up to **15°** | P-07 rover limit 15°; P-15 surveyed road ≤ 12° | Route-card slope limit | `viper_slope_limit` |
| 22 | **NASA OSDR: Brassica rapa grown on the ISS** (NASA GeneLab / OSDR; OSD-59 with Roscosmos) | OSD-59 (Lada, Expedition 22, 27 days); OSD-412 (Veggie VEG-03D, SpaceX-12) | <https://osdr.nasa.gov/bio/repo/data/studies/OSD-59> | US Gov | Mizuna (*Brassica rapa*) grown 27 days in Lada at 125–250 µmol m⁻² s⁻¹; Veggie VEG-03D protocol 200–300 µmol m⁻² s⁻¹, 16 h light, 23 °C (ground chambers simulating the ISS) | P-02 light OFF/DIM/FULL and crop C; P-01 one plant per cassette | Garden-lamp Data Card | `osdr_brassica_rapa_iss` |
| 23 | **Seed-to-seed Brassica rapa on Mir** (NASA-funded), Musgrave et al. 2000 | NTRS 20040141614 | <https://ntrs.nasa.gov/citations/20040141614> | Quoted | Full life cycles completed in microgravity in a 122-day run (Svet greenhouse) | P-03 hand pollination; P-06 seed harvest; E3 | Seed Vault fact | `mir_brassica_seed_to_seed` |
| 24 | **Wisconsin Fast Plants FAQ** (UW–Madison; partner) | Fast Plants FAQ | <https://fastplants.org/frequently-asked-questions/> | CC BY-NC-SA | Flowers in ~14 days; self-incompatible; stigma receptive 2–4 days; pollinate 15–21 days after planting; pods mature ~20 days after pollination; seeds ~40 days after planting | P-03 dates 30 Apr–6 May; P-06 maturity day 35 and dry-down to day 40 | Plant-care Data Card | `fast_plants_lifecycle` |
| 25 | **Chang'e-4 Lunar Lander Neutrons and Dosimetry** (CNSA mission; Kiel instrument), Zhang et al. 2020 | DOI 10.1126/sciadv.aaz1334 | <https://doi.org/10.1126/sciadv.aaz1334> | Quoted | First surface dose: **13.2 ± 1 µGy/h** in silicon (quiet Sun) | P-14 route-dosimeter scale; Engineer Mode context | "Measured on the Moon's surface" line | `change4_lnd_surface_dose` |
| 26 | **Chang'e-4 cotton experiment** (CNSA mission; Chongqing University), Qiu et al. 2021 | DOI 10.3390/ijms222111723 | <https://doi.org/10.3390/ijms222111723> | Quoted | A cotton seed germinated in 2019: the first green leaf grown on the Moon | P-09 a real lunar plant trial that ended at the seedling stage; finale cotton (fiction) | SRC-COTTON2019 card | `change4_cotton` |
| 27 | **Moonlight lunar communications** (ESA; partner) | ESA Moonlight page | <https://www.esa.int/Applications/Connectivity_and_Secure_Communications/Moonlight2> | Quoted (© ESA) | Terrain and curvature can block direct line of sight to Earth at the south pole; relays fix it | P-15/P-16 why the repeater chain exists | Relay Data Card | `esa_moonlight_relay` |
| 28 | **Lunar pole illumination and communications maps** (NASA JPL IPN, Bryant 2009) | IPN Progress Report 42-176 | <https://ipnpr.jpl.nasa.gov/progress_report/42-176/176C.pdf> | US Gov | Best south-pole site: **92 %** solar availability, **51 %** direct-to-Earth; some peaks have continuous Earth view | P-16 why Malapert; row 2–3 of §A | Relay Data Card | `jpl_ipn_42_176_dte` |

**Kept from the old table, not yet processed** (they stay *pending*, never shown as measured): LROC `WAC_POLE_ILL_PCT_SOUTH` illumination map and LOLA DEMs (<https://pgda.gsfc.nasa.gov/products/78>, <https://pgda.gsfc.nasa.gov/products/90>) for a horizon mask at a fixed Aurora coordinate (§C step 4); LRO CRaTER Level 2 files for Sep 2017 (<https://pds-ppi.igpp.ucla.edu/data/LRO-L-CRAT-3-CDR-CALIBRATED-V1.0/>); MSL RAD for "same storm, two worlds" (JPL story <https://www.jpl.nasa.gov/news/large-solar-storm-sparks-global-aurora-and-doubles-radiation-levels-on-the-martian-surface/>, which blocks scripted requests, so it is cited, not fetched); NASA OLTARIS (<https://oltaris.nasa.gov/>) to replace the zap table with a computed dose curve; NASA SVS #5027, #4491, #4167 and #3836 animations for the pitch video; NASA Moon Trek (<https://trek.nasa.gov/moon/>) for the teacher guide.

**Not used, and why:** `api.nasa.gov/DONKI` did not answer on 3 Nov (time-out), so the fixtures call the CCMC DONKI API directly, which needs no key. ESA NELIOTA impact flashes: the site needs browser cookies, so it could not be verified by script. NOAA SWPC live JSON only covers the last days, so the 2017 extract comes from the NCEI archive.

### B2. Every puzzle traced (P-01 to P-16)

Tags: **[M]** measured (a fixture holds the value), **[C]** computed from a fixture, **[E]** engineering estimate with a named basis, **[G]** gameplay value, **[F]** fiction. Numbers are from [08_PUZZLE_DESIGNS.md](../game-design/08_PUZZLE_DESIGNS.md) and are not changed here.

| Puzzle | Game numbers | Datasets (rows in B1) | Traceability |
|---|---|---|---|
| **P-01** Commission and Plant | probe offset +10; references dry 10 / wet 110; target 0/100; fill 40–60, 50 nominal; one seed per cassette | 22 OSDR (Veggie pillows thinned to one plant), 24 Fast Plants (moist, never dry) — <https://osdr.nasa.gov/bio/repo/data/studies/OSD-412> | One seed per cassette [M-practice]. **Calibration numbers have no dataset** [G] (B3-1) |
| **P-02** Seven Shifts, One Night | E14/cap 20, day +8; A6/cap 10, −1/shift; R12, −1.2/shift; W0–6; K0–2; S table 3/2/1/0; Z ≤ 3; 7 × 7.2 h, dark 36 h; storm in shifts 5–6; Earth-set shift 4; heat 2/1/0; light 0/1/2 | 1 DONKI, 2 GOES-13, 6 Mazarico, 7–8 Horizons, 12 BVAD, 13 10 kW array, 14 Clowdsley, 22 OSDR — <https://ccmc.gsfc.nasa.gov/DONKI-API/get/SEP?startDate=2017-09-04&endDate=2017-09-12> | Storm times [M]; air and food rates [C]; +8 [E]; W = 20 g/cm² [C]; 36 h [E]; S table, heat costs, battery cap, Earth-set timing [G] (B3-2 to B3-6) |
| **P-03** Alo Meets Tara | three reciprocal runs, days 1/4/7 (30 Apr–6 May, plant days 19–25); E1/A1 per run; donor ≠ recipient | 24 Fast Plants (self-incompatible; pollinate days 15–21; stigma 2–4 days), 23 Mir *B. rapa*, 1 DONKI (space-weather check) — <https://fastplants.org/frequently-asked-questions/> | Biology [M]; run dates [F] but inside the flowering window; E1/A1 [G] |
| **P-04** Recorder Reconstruction | 2034-04, HORT-01, ENGINEERING | 15 Apollo seismic PDS bundle as the real model of date / instrument / channel metadata — <https://pds-geosciences.wustl.edu/lunar/urn-nasa-pds-apollo_pse/> | All tokens [F]. **No dataset can support fictional history**; the card teaches real archive metadata |
| **P-05** Find the Falling Pressure | 4 phases × 7.2 h; gauge MAIN 100, GARDEN 82 → 74; leak A1/phase; aftershock at phase 2; 6 candidates | 15 Apollo shallow quakes (13 Mar 1973, 84°S), 12 BVAD (101.3 kPa nominal; A1 = 4-crew O₂) — <https://pds-geosciences.wustl.edu/lunar/urn-nasa-pds-apollo_seismic_event_catalog/data/nakamura_1979_sm_locations.csv> | Quake [M]; air [C]; **gauge numbers [G]** (B3-7) |
| **P-06** A Harvest With a Future | maturity 16 May (day 35); dry 70 → ≤ 20 by 21 May (day 40); 42 = 6 × 7; 12 + 30 | 24 Fast Plants (pods ~20 days after pollination; seeds ~40 days after planting), 23 Mir — <https://fastplants.org/frequently-asked-questions/> | Timing [M]; 42 seeds [F] (story canon); moisture 70/20 [G] |
| **P-07** Survey and Return | routes 8/12/10 km, slopes 24°/12°/18°, limit 15°; cost 35/30/40, reserve 30; scanner dry 2, samples 2/18/19, threshold +10 | 21 VIPER (15°), 17 LCROSS (5.6 %), 18 Diviner (38 K), 19 M3/Chandrayaan-1 (patchy ice), 20 Kaguya, 12 BVAD (A0.5 for two home cadets) — <https://science.nasa.gov/mission/viper/rover-and-instruments> | Slope limit [M]; route lengths, slopes, costs, scanner counts [G] (B3-8) |
| **P-08** Recover Without Ruining | cold → cool → room in three stages; 12 specimens | 18 Diviner (38 K), 20 Kaguya (< 90 K floor) — <https://www.diviner.ucla.edu/science> | Cold-trap temperatures [M]; stages [G]; 12 specimens [F] |
| **P-09** Reconstruct the Departure | 3 Apr; 4 Apr 12:00 / 12:10 / 12:40 (2034); 4 departed / 4 boarded | 26 Chang'e-4 cotton (a real trial that ended at the seedling stage) — <https://doi.org/10.3390/ijms222111723> | All [F]. **No dataset can support fictional history**; the card shows the real parallel |
| **P-10** Flashes and a Signature | 8 transients + 2 artifacts, 6 verified (8 for Golden); dust 8 → 6; leak A1 (0.5 with seals); breathing 1.25; witness E16, A4.25 | 16 NASA MEO (two telescopes reject noise; 126 flashes; 62 % in showers), 12 BVAD, 13 10 kW array — <https://www.nasa.gov/meteoroid-environment-office/lunar-impact-monitoring/> | Method [M]; 1.25 [C]; counts and dust loss [G] (B3-9) |
| **P-11** Protect the Small Light | 5 segments; 7 of 14 units; essentials 1 per segment, pump 1, camera 1, floods 3 | 11 NASA eclipse catalog (70.0 / 208.9 / 337.2 min), 7 Horizons (Sun +0.14° at the pole on 12 Jan 2047) — <https://eclipse.gsfc.nasa.gov/LEcat5/LE2001-2100.html> | Eclipse durations [M]; segment allocation [G], already disclosed as a fallback in 08 (B3-10) |
| **P-12** Observe, Isolate, Restore | ingress, ring, egress records; F2 isolate → 0 → reset → test | 11 NASA eclipse catalog (U1–U4 contact times) — <https://eclipse.gsfc.nasa.gov/LEcat5/LE2001-2100.html> | Event order [M]; feeder procedure [G] |
| **P-13** One Integrated Storm Plan | 6 steps × 7.2 h; multipliers [1,1,2,2,1,1]; W4 + K2 = S6 → zero dose; E30/32; A1.25, R1.5; seeds 15 + 15 | 3 DONKI 2012, 4 STEREO-A HET, 5 CRaTER, 14 Clowdsley, 12 BVAD — <https://cdaweb.gsfc.nasa.gov/hapi/info?id=STA_L1_HET> | Event [M]; A and R [C]; S6 = 20 g/cm² [C]; **multipliers and "zero dose" [G]** (B3-11, B3-12) |
| **P-14** Three Waves and a Broken Link | Z ≤ 6; route readings 0.4, 0.3 (clear), 1.2 (not), threshold 1 | 4 STEREO-A HET, 25 Chang'e-4 surface dose — <https://doi.org/10.1126/sciadv.aaz1334> | Real decay after the peak [M]; readings and threshold [G] (B3-13) |
| **P-15** Two Teams, One Road | 120 km each way; 24 + 3 + 24 = 51 h ≤ 72 h; road ≤ 12° vs shortcut 22°; rover E14, allowances 5/5 (3.5), reserve 2; home A0.5 then 1.25 per 7.2 h = 2.8125 | 10 USGS gazetteer (pole → Mons Malapert 121.9 km), 21 VIPER (15°), 12 BVAD, 27 ESA Moonlight — <https://planetarynames.wr.usgs.gov/Feature/16338> | Distance [C]; air [C]; slope limit [M]; road slopes, durations, rover units [G] |
| **P-16** The Link and the Living Garden | local bearing L2, Earth bearing E3; 3 s lock; checksum ALO42; return 24 h | 9 Horizons (Earth az 358°, el −2.3° from Malapert; below Aurora's horizon), 10 USGS (bearing 176.7° to Aurora), 27 ESA Moonlight, 28 JPL IPN (51 % DTE; continuous-view peaks) — <https://ssd.jpl.nasa.gov/api/horizons.api> | Bearings [C] (no terrain, so labelled *Computed*); ALO42 [F]; lock time [G] |

### B3. Numbers no dataset supports, and the smallest change that makes each traceable

These are **proposals for the user to approve**. Nothing in `08_PUZZLE_DESIGNS.md` has been changed.

1. **P-01 calibration (+10 offset, dry 10 / wet 110, band 40–60).** No dataset. *Proposal:* keep the numbers, tag them [G] on the card, and say what they teach (two-point calibration). If a source is wanted, the Veggie and APH root-zone moisture set-points would need a NASA paper with numbers; we did not find one.
2. **P-02 energy scale (+8 per daylight shift, cap 20, battery 200 kWh).** Only the 10 kW array is a NASA number. *Proposal:* show the formula on the card: 8 drops × 10 kWh / 7.2 h = 11.1 kW = 56 % of two 10 kW arrays [E]. Keep the cap 20 as [G].
3. **P-02 shelter table 3/2/1/0 and "0 at S6".** NASA's curve (Clowdsley slide 37) falls from 185 to 85 mSv between 5 and 15 g/cm² but never reaches zero. *Proposal:* keep the table, rename S6's "0" on screen as "below the storm limit" and show the real curve next to it. No number changes.
4. **P-02 both storm shifts score the same table.** GOES-13 says the second 7.2 h after onset had 2.6× the >10 MeV flux of the first. *Proposal (needs balance re-run):* none now; show the real two-shift ratio on the debrief card. If the team wants it in the rules, add a ×2 multiplier on shift 6 only after re-running the P-02 balance count.
5. **P-02 "Earth sets at shift 4" (25–26 Apr 2046).** JPL Horizons says Earth set at the pole on 15 Apr 2046 and stayed 3.4°–1.4° below the horizon all night, rising on 28 Apr. "Earth is down all night" is supported; "Earth sets during the night" is not. *Proposal:* keep the scene, but word the shift-4 beat as "the last Earth relay window closes" or label it *training scenario* on screen.
6. **P-02 heat costs (COZY 2 / COOL 1 / COLD 0) and plant damage (0/1/2).** Engineering estimate (≈ 2.8 / 1.4 kW, §A row 23). *Proposal:* tag [E] and cite Diviner's 38 K and Kaguya's < 90 K as "why heating costs power"; no number change.
7. **P-05 gauge units (100 / 82 / 74).** *Proposal:* label the gauge "% of nominal cabin pressure" with BVAD's 101.3 kPa as 100 %. No number change.
8. **P-07 route lengths, slopes (24°/12°/18°), costs and scanner counts.** Only the 15° limit is NASA data. *Proposal:* after a fixed Aurora coordinate is chosen, compute real slopes along three candidate routes from the LOLA 20 m DEM (PGDA product 90) and replace the slopes only if they keep route B as the only valid one. Show scanner counts as counts [G] beside LCROSS's 5.6 % as the real reference.
9. **P-10 dust loss 8 → 6.** No dataset. *Proposal:* tag [G]; the card cites NASA's Electrodynamic Dust Shield demonstration (Blue Ghost, March 2025, §E row E18) as the real fix.
10. **P-11 seven-unit allocation.** Already disclosed in 08 as a fallback until a verified curve exists. *Proposal:* when the Aurora coordinate is fixed, use the catalog contacts (row 11) and Horizons to time the five segments, then rescale as 08 already specifies (segment-hours / 7.2).
11. **P-13/P-14 multipliers [1,1,2,2,1,1].** STEREO-A shows one main peak in step 3 (80 MeV fluence [0.16, 0.69, 1.00, 0.02, 0.01, 0.00]), not three waves. *Proposal:* keep the three waves as the labelled counterfactual and show the real STEREO-A curve on the card; if the team wants the rules data-derived, set multiplier 2 where step fluence ≥ 50 % of peak and 1 otherwise ([1,2,2,1,1,1] at 80 MeV) after a balance re-run.
12. **P-13 "S6 gives zero game dose".** Same as item 3: show "below the storm limit", not zero.
13. **P-14 route readings 0.4 / 0.3 / 1.2, threshold 1.** *Proposal:* define 1.0 as "twice the quiet surface dose rate measured by Chang'e-4 (13.2 µGy/h)" so the threshold has a real anchor; readings stay as they are.
14. **P-15 road slopes 12°/22°, 24 h drive, rover units.** *Proposal:* same LOLA slope pass as item 8 for the road; the drive time stays [G] (the playable road is compressed).
15. **P-16 lock duration 3 s and checksum ALO42.** Gameplay and fiction; no proposal.

**Related claim to re-word in §E (no game number):** E7 says shallow moonquakes reached "about magnitude 5". The PDS Nakamura catalog's largest shallow-quake magnitude is 3.2 on its own scale; the "~5" comes from a different magnitude estimate. Cite which scale before showing it.

---

## C. Data pipeline for the hackathon (one team member, about 6–8 hours)

**3 Nov 2026:** step 1 (DONKI) and the storm, sky, eclipse and source extracts in §B1 are now automated by `production/tools/fetch_nasa_data.py` (board M0-14), which writes `game/resources/data/nasa/`. Steps 2–4 (LROC pixel, CRaTER 2017, horizon mask) are still to do.

1. **DONKI (30 min, Must).**
   - Download `FLR`, `CME` and `SEP` records for 2017-09-04 → 2017-09-12.
   - Save them as `data/donki_2017-09.json`. Keep the raw response and the URL used.
2. **LROC illumination map (45 min, Must).**
   - Download the `WAC_POLE_ILL_PCT_SOUTH` browse PNG and GeoTIFF.
   - Mark the base's latitude/longitude on Shackleton's rim, then read and record that pixel's % illumination.
   - Export a small PNG for the game.
3. **CRaTER (1.5 h, Should).**
   - Download the Level 2 dose-rate files for 2017-09-04 → 2017-09-14.
   - Plot dose rate vs time and mark the flare times from DONKI.
   - Average over the two storm shifts (≈ 7 h each, after onset).
   - Scale the zap table so that a bare base (wall 0) gets 3 zaps per storm shift. Keep the shape of the real curve.
   - Save `data/crater_2017-09.json` and the chart PNG.
4. **Horizon and real night (3–4 h, Should).**
   1. Load the PGDA south-pole DEM.
   2. From the base point, plus a 10 m mast, march rays every 1° in azimuth out to ~100 km. Record the maximum elevation angle for each direction: that's the **horizon mask**.
   3. Query JPL Horizons for the Sun's and Earth's azimuth/elevation from `coord@301` (the base's latitude, longitude and height), hourly, around the two Season 1 midwinters: April 2046 (Chapter 1) and April 2047 (Chapter 8).
   4. Mark when the Sun's center is below the mask (dark) and whether Earth is above it.
   5. Find a night of ≈ 30–40 h where Earth is down. Record Last Light, Earth-set and First Light.
   6. Save `data/real_night.json` and `data/horizon_mask.json`.
5. **Acceptance checks.**
   - Each file states its source URL, the download date and the processing script.
   - Every number shown in the game comes from these files or carries a tag.
   - **Fallbacks if a step fails:** use the published values: ~1.5-day longest night (Mazarico 2011), and the "doubled on Mars" figure from JPL.

---

## D. Honesty rules (shown in the game's "Science" tab)

- The storm is a **replay** of 10 Sep 2017's timing and strength, re-dated to the game's night. We never claim it happened at our base.
- Every number carries a tag: [M] measured, [E] estimate, [G] gameplay or [F] fiction.
- Zaps are game points, not sieverts. Engineer Mode shows the real units next to them.
- Every science display carries one of three labels: **Observed** (historical records such as DONKI, CRaTER, RAD, LROC), **Computed** (our processed LOLA/Horizons geometry, shown only after it is checked) or **Simulated** (game units, the 2046 timeline, the station and what happens to it).
- Aurora Station, the cadets and Alo are fiction set in the 2040s. Crew needs and plant behaviour follow published sources but are simplified game rules.
- Season 1's Expedition Zero, Dr. Noor Rahman, Tara, the seed vault and the Malapert relay story are fiction [F]. Chapter 7's storm is labelled on screen as a **"what if"**.
- No NASA logos, and no claim that NASA endorses us. NASA imagery in videos is credited.

---

## E. Season 1: facts and data for Chapters 2–8

Season 1 ([`CAMPAIGN_SEASON1.md`](CAMPAIGN_SEASON1.md)) adds seven chapters. Every new claim is checked here with the same legend as §A, plus the tags [M] measured, [E] estimate, [G] gameplay and [F] fiction.

| # | Claim in the season | Verdict | The accurate version we use | Source |
|---|---|---|---|---|
| E1 | The south pole has seasons, and its "year" is about 350 days | ✅ [E] | The Moon's axis is tilted ~1.54°, so the Sun's height at the pole swings between about +1.5° and −1.5°. The cycle follows the eclipse year (~347 days). Our computed peaks: midwinter ~25 Apr 2046 and ~10 Apr 2047; midsummer ~19 Oct 2046. Computed with PyEphem; to be confirmed with JPL Horizons | Lunar geometry; PyEphem; JPL Horizons |
| E2 | Alo can't make seeds alone | ✅ | Wisconsin Fast Plants are self-incompatible: the pollen must come from another plant | Fast Plants program |
| E3 | Michael Foale's bee stick on Mir, 1997 | ✅ | *Brassica rapa* grew in Mir's Svet greenhouse; Foale pollinated it by hand with a bee's thorax on a stick; seeds made in space were planted and grew | UW–Madison; NASA NTRS |
| E4 | Flowers at ~14 days, seeds at ~40; stop watering to dry the pods | ✅ | A 35–40-day life cycle under 24-hour light; flowers at ~14 days; seed harvest ~40 days after planting | Fast Plants growing instructions |
| E5 | One gene for purple vs green stems; purple wins | ✅ | The *anthocyaninless* gene: *anl/anl* = green stem; one or two *ANL* = purple | Carolina / Fast Plants genetics |
| E6 | Mei's grandmother pollinated apple trees by hand | ✅ [F for Mei] | In Maoxian County, China, farmers hand-pollinated apple orchards after pollinators declined | Partap & Ya 2012 |
| E7 | 28 shallow moonquakes, up to about magnitude 5; the Moon shrank ~50 m | ✅ | Recorded by four Apollo seismometers, 1969–1977 | NASA (2019); Watters et al. 2019 |
| E8 | The 13 March 1973 quake near the south pole | ✅ | One of the strongest shallow moonquakes was located in the south-polar region; its exact epicentre is uncertain | Watters et al. 2024 |
| E9 | Real Apollo seismograms in the game | ✅ [M] | The Apollo Passive Seismic Experiment bundle (MiniSEED and GeoCSV) at the PDS Geosciences Node | PDS Geosciences |
| E10 | The rover can't climb slopes over 15° | ✅ 🎮 | VIPER is designed for 15° slopes (25–30° if it must); it is NASA's first rover with headlights | NASA VIPER |
| E11 | Colder than −230 °C in the cold trap | ✅ [M] | Diviner measured below 40 K in permanently shadowed craters (Cabeus ≈ 38 K ≈ −235 °C) | LRO Diviner |
| E12 | Ice mixed into the soil | ✅ [M] | LCROSS (2009) measured 5.6 ± 2.9% water by mass in Cabeus | LCROSS results |
| E13 | Noor's seed vault in a cold crater | ✅ idea / [F] vault | Smithsonian scientists proposed a lunar biorepository in permanently shadowed craters (2024), cold enough to keep samples frozen without power | Hagedorn et al. 2024, *BioScience* |
| E14 | ShadowCam sees inside always-dark craters | ✅ [M] | A NASA camera on Korea's Danuri orbiter, ~200× more sensitive than earlier cameras; it imaged Shackleton's interior | NASA |
| E15 | Impact flashes on the Moon during meteor showers | ✅ [M] | NASA Marshall has monitored lunar impact flashes since 2006: hundreds recorded, with higher rates during showers such as the Geminids | NASA NTRS |
| E16 | 222 new craters | ✅ [M] | LROC before-and-after images found 222 new impact craters; the top 2 cm of soil is churned ~100× faster than thought | Speyerer et al. 2016, *Nature* |
| E17 | "Lunar hay fever" | ✅ | Apollo 17's Harrison Schmitt sneezed and had a swollen nose after breathing Moon dust | Space.com |
| E18 | The Dust Shield works on the Moon | ✅ [M] | NASA's Electrodynamic Dust Shield cleared regolith from glass and a radiator on Blue Ghost Mission 1 (March 2025) | NASA |
| E19 | A total lunar eclipse on 12 January 2047 | ✅ | Greatest eclipse at 01:24:51 UT; totality 70 min (Saros 125) | Espenak, EclipseWise |
| E20 | From the pole, Earth hides the Sun for ~2 h 40 min | 🎮 [E] | Our model (PyEphem positions, the IAU model of the Moon's pole, Earth's shadow enlarged 2% for its air): fully hidden ~00:00–02:42 UT, partly hidden ~22:58–03:44 UT. In every lunar eclipse the Sun and Earth sit within ~0.4° of the pole's flat horizon (here +0.1°), so the base's real view depends on its local horizon. To be checked with JPL Horizons + LOLA | Our calculation |
| E21 | Bangladesh's sunrise is part of the red ring | ✅ [E] | Dhaka's sunrise on 12 Jan 2047 is at ≈ 00:43 UT, inside the total-shadow window; the ring is Earth's sunrise-and-sunset line | PyEphem |
| E22 | Why the ring is red | ✅ | Sunlight passing through Earth's air loses its blue and bends into the shadow, as at sunset | NASA SVS |
| E23 | The 23 July 2012 storm | ✅ / [F] "what if" | A CME at ~1,800–2,200 miles per second, seen by STEREO-A; it missed Earth by about 9 days and would have rivalled the 1859 Carrington event. The game's Moon strike is a labelled "what if" | NASA SVS |
| E24 | The August 1972 storm | ✅ | The storm fell between Apollo 16 and Apollo 17; one estimate puts a moonwalker's dose near 400 rem | Space.com; National Academies |
| E25 | Dry seeds survive space | ✅ [M] | SEEDS: 12.5 million tomato seeds spent 69 months in orbit on LDEF (1984–1990); 3.3 million students grew them | Park Seed / NASA |
| E26 | Malapert's summit sees Earth almost always | ✅ (wording) | Malapert (~5 km high, ~120 km from the pole) has near-continuous Earth visibility and has been proposed as a relay site. We say "almost always" | Malapert outpost papers |
| E27 | The Seed Vault's 16 facts | ✅ | Each is sourced in `CAMPAIGN_SEASON1.md` (Mir 1997, China's rice 2022, Kelly 2016, Veggie lettuce 2015, chiles 2021, radish 2020, tomato 2023, LDEF, Mir wheat, Pettit 2012, Chang'e-4 2019) | See Sources |
| E28 | Cotton survives the finale | [F] | A symbolic ending. The real 2019 cotton sprout froze | — |

**New NASA data for the later chapters** (built after the hackathon):

| Chapter | Dataset | What we compute |
|---|---|---|
| 3 | Apollo PSE waveforms (PDS Geosciences) | Shake strength over time and the quake's sound (sonified) |
| 4, 8 | LOLA 20 m/px polar DEM (PGDA) | A slope map with a 15° limit for the rover route |
| 4 | ShadowCam images | The view inside the dark crater |
| 5 | NASA lunar impact flash records | The flash rate during the Geminids |
| 6 | Eclipse catalog + JPL Horizons | The minute-by-minute darkness at the base |
| 7 | STEREO-A particle data (via DONKI) | The three-wave storm profile |
| 8 | JPL Horizons (Earth seen from Malapert) | The dish-aiming puzzle |

**At the hackathon** only Chapter 1's data is needed (§C). The Season map needs no new data.

---

## Sources

**Sunlight and Earth visibility**
- Mazarico et al. 2011, *Icarus* — illumination of the lunar polar regions from LOLA: <https://ui.adsabs.harvard.edu/abs/2011Icar..211.1066M>
- Speyerer & Robinson 2013, *Icarus* — persistently illuminated regions: <https://www.sciencedirect.com/science/article/abs/pii/S0019103512004174>
- Gläser et al. 2014, *Icarus* — Connecting Ridge illumination: <https://www.sciencedirect.com/science/article/abs/pii/S0019103514004278>
- LROC polar illumination maps: <https://data.lroc.im-ldi.com/lroc/view_rdr/WAC_POLE_ILL_PCT_SOUTH>
- NASA PGDA, south-pole LOLA DEMs: <https://pgda.gsfc.nasa.gov/products/78>
- JPL IPN Progress Report 42-176: <https://ipnpr.jpl.nasa.gov/progress_report/42-176/176C.pdf>
- JPL Horizons manual: <https://ssd.jpl.nasa.gov/horizons/manual.html>

**The September 2017 storm**
- NASA DONKI (CCMC): <https://ccmc.gsfc.nasa.gov/>
- GLE 72 analysis: <https://arxiv.org/abs/1810.10536>
- LRO CRaTER archive (PDS PPI): <https://pds-ppi.igpp.ucla.edu/>
- CRaTER-based dose study including Sep 2017: <https://www.sciencedirect.com/science/article/abs/pii/S0019103523000544>
- JPL, the storm at Mars: <https://www.jpl.nasa.gov/news/nasa-watches-mars-light-up-during-epic-solar-storm/>

**Shielding**
- NASA lunar radiation protection (Clowdsley): <https://ntrs.nasa.gov/api/citations/20210009760/downloads/Clowdsley_Lunar_Radiation_Talk_v2.pdf>
- NASA Water Walls: <https://ntrs.nasa.gov/api/citations/20190001191/downloads/20190001191.pdf>
- NASA Orion storm shelter: <https://www.nasa.gov/missions/artemis/orion/scientists-and-engineers-evaluate-orion-radiation-protection-plan/>

**Power and life support**
- NASA VSAT: <https://ntrs.nasa.gov/citations/20220013210>
- NASA relocatable 10 kW array: <https://ntrs.nasa.gov/api/citations/20210011743/downloads/NASA-TM-20210011743.pdf>
- NASA BVAD 2022: <https://ntrs.nasa.gov/api/citations/20210024855/downloads/BVAD_2.15.22-final.pdf>
- ISS 98% water recovery: <https://www.space.com/astronaut-pee-iss-water-recycling-98-percent-milestone>

**Plants**
- NASA LEAF (Space Lab): <https://www.spacelabtech.com/lunar-payload-leaf---lunar-effects-on-agricultural-flora.html>
- Space.com on LEAF: <https://www.space.com/nasa-artemis-3-plant-growth-experiment-moon>
- Wisconsin Fast Plants: <https://en.wikipedia.org/wiki/Wisconsin_Fast_Plants>
- Bangladesh mustard varieties (Tori-7 is *B. rapa*): <https://www.researchgate.net/publication/311545831_Performance_of_Rapeseed_and_Mustard_Brassica_sp_VarietiesLines_in_North-East_Region_Sylhet_of_Bangladesh>
- Plant radiation tolerance: <https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7284948/>
- Lighting energy for space crops: <https://www.sciencedirect.com/science/article/abs/pii/S2214552414000327>
- Chang'e-4 sprout: <https://www.upi.com/Science_News/2019/01/17/Change-4s-sprouted-cotton-seeds-die-during-first-lunar-night/6511547728052/>
- Kelly's zinnias: <https://www.space.com/31702-how-this-flower-was-saved-from-space-station-mold.html>
- Moonquakes (Watters 2024): <https://dashboard.si.edu/es/newsdesk/releases/shrinking-moon-causes-temblors-and-faults-lunar-south-polar-region>

**Season 1 (§E)**
- Fast Plants growing instructions: <https://fastplants.org/pdf/growing_instructions.pdf>
- Fast Plants phenotypes and genetics: <https://knowledge.carolina.com/?p=15925>
- Mir 1997, seeds from seeds in space: <https://news.wisc.edu/?p=1828> · <https://ntrs.nasa.gov/citations/20040141614>
- Hand pollination in Maoxian (Partap & Ya 2012): <https://bioone.org/journals/mountain-research-and-development/volume-32/issue-2/MRD-JOURNAL-D-11-00108.1/The-Human-Pollinators-of-Fruit-Crops-in-Maoxian-County-Sichuan/10.1659/MRD-JOURNAL-D-11-00108.1.short>
- NASA, the shrinking Moon and moonquakes (2019): <https://www.nasa.gov/press-release/goddard/2019/Moonquakes>
- Watters et al. 2024, south-pole faults and quakes: <https://doaj.org/article/f70d4bb2d83a4c538d8245b3c74ac96e>
- Apollo seismic data (PDS Geosciences): <https://pds-geosciences.wustl.edu/missions/apollo/apollo_pse.htm>
- VIPER rover and instruments: <https://science.nasa.gov/mission/viper/rover-and-instruments>
- LCROSS results: <https://www.jpl.nasa.gov/news/lunar-impact-may-impact-lunar-science-for-years-to-come/>
- Lunar biorepository (Smithsonian, 2024): <https://www.nationalzoo.si.edu/node/17362>
- ShadowCam: <https://www.nasa.gov/feature/nasa-s-shadowcam-images-lunar-south-pole-region/>
- NASA lunar impact monitoring: <https://ntrs.nasa.gov/citations/20170004471>
- LRO's new craters (2016): <https://www.nasa.gov/news-release/earths-moon-hit-by-surprising-number-of-meteoroids>
- Lunar hay fever: <https://www.space.com/moon-dust-problem-lunar-exploration.html>
- NASA's Dust Shield on the Moon (2025): <https://www.nasa.gov/image-article/nasas-dust-shield-successfully-repels-lunar-regolith-on-moon>
- Total lunar eclipse of 12 January 2047: <https://eclipsewise.com/lunar/LEprime/2001-2100/LE2047Jan12Tprime.html>
- An eclipse seen from the Moon (NASA SVS): <https://svs.gsfc.nasa.gov/3836>
- The storm that missed Earth, July 2012 (NASA SVS): <https://svs.gsfc.nasa.gov/4167/>
- The August 1972 storm: <https://www.space.com/749-bad-week-moon.html>
- SEEDS tomato seeds on LDEF: <https://parkseed.com/blogs/park-seed-blog/seeds-in-space>
- Malapert Mountain outpost: <https://www3.nd.edu/~cneal/lunar-l/Malapert-Mt-Outpost.pdf>
- LEAF after the 2026 Artemis changes (SpaceNews): <https://spacenews.com/three-companies-building-the-tech-to-grow-crops-on-the-moon/>
- NASA's 2026 Artemis changes (Live Science): <https://livescience.com/space/space-exploration/nasa-announces-sweeping-overhaul-of-artemis-return-to-moon-targeting-a-2028-landing-and-a-2027-in-orbit-docking-flight>

**Data sources added 3 Nov 2026 (§B, board M0-13):** every URL, ID and DOI is in the B1 table; they are not repeated here.

---

## Open questions (data, 3 Nov 2026)

1. **Aurora's coordinate.** The game has no fixed latitude, longitude and height for Aurora. The night length, the Earth-set beat, the eclipse segments and the road slopes all need one. Proposal: pick a Shackleton–de Gerlache ridge point from Mazarico et al. 2011, then run §C step 4 (LOLA horizon mask + Horizons).
2. **Mons Malapert line of sight.** Horizons puts Earth 2.3° below the geometric horizon from the Mons Malapert centre on 9 Apr 2047, visible from any point ≥ 1.4 km above the reference sphere. The summit height and the terrain to the north still need the LOLA DEM.
3. **CRaTER for September 2017.** The UNH daily table ends in 2012, so the 2017 lunar dose curve needs the PDS PPI Level 2 files or the 2023 CRaTER dose study. Until then the 2017 card shows GOES-13 (Earth orbit), labelled as such.
4. **Data-derived storm rules.** B3 items 4 and 11 would change balance. They need the user's approval and a full P-02 / P-13 balance re-run before any number moves.
5. **§E row E1 dates.** Horizons gives the polar midwinter Sun minimum on 1 May 2046 and 21 Apr 2047 and midsummer on 16 Oct 2046 (PyEphem said ~25 Apr, ~10 Apr, ~19 Oct). The minimum is broad (within 0.02° for about two weeks), so the story dates still sit in midwinter; only the wording "peaks on" should change.
6. **GOES detector choice.** The fixture uses the west-facing EPEAD detector (`ZPGT10W`). NOAA's operational alerts may use a different channel; the card says which.
7. **Fast Plants licence.** Their resources are CC BY-NC-SA; we quote facts only, which is compatible with an Apache-2.0 code licence, but the team should confirm no Fast Plants images are copied.
8. **api.nasa.gov DONKI.** It timed out on 3 Nov; the CCMC endpoint works without a key. Re-check before the hackathon.

## Reconcile with the official Resources tab (M0-12)

The 28 October Resources tab is not in the repo yet. When `docs/challenge-statement-2026.md` lands:

1. List every dataset link from the Resources tab, with its retrieval date.
2. For each one, find the B1 row that covers the same thing. Where the official dataset covers it, make it the primary source of that row and keep ours as a backup; where nothing covers it, add a new B1 row and say which puzzle it drives.
3. Check these rows first, because the challenge is about life support, shielding, power and food: B1 rows 1–2 (storm), 12 (BVAD), 13 (power), 14 (shielding), 22 (plants), and the sky rows 6–9 if the tab lists LRO data.
4. If the tab favours Mars data, add a "same storm, two worlds" card from MSL RAD and keep the Moon as the setting.
5. Add each new source to `production/tools/fetch_nasa_data.py`, re-run it, update `game/resources/data/nasa/puzzle_sources.json`, and make sure every P-01 to P-16 row in B2 cites at least one official dataset where one fits.
6. Close the open questions above that the official list answers.
