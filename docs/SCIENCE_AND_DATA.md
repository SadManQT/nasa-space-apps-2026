# Science check and NASA data plan (v7 FINAL)

**Team The Last BrainCell** · LAST LIGHT ACADEMY · 6 October 2026

This document makes the game's science defensible to NASA judges. It has five parts:
- **A** checks every scientific claim in the game and says what we fixed.
- **B** lists the NASA datasets the game uses, and exactly how.
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

## B. NASA datasets and tools: what we use, where, and how

| # | NASA dataset or tool | What it is | Where to get it | What we compute | Where it shows in the game | Priority |
|---|---|---|---|---|---|---|
| 1 | **LROC WAC polar illumination map** (`WAC_POLE_ILL_PCT_SOUTH`, also time-weighted `…_TWI_SOUTH`) | Measured % of time each 100 m pixel (88–90°S) was sunlit, from 3,807 WAC images over a lunar year (2010–11) | LROC RDR browser: `data.lroc.im-ldi.com/lroc/view_rdr/WAC_POLE_ILL_PCT_SOUTH` (PNG and GeoTIFF) | Mark the base pixel; read its illumination % | Title screen "Why here?" map and the debrief card "What was real" | **Must** |
| 2 | **LROC WAC south pole illumination movie** (`WAC_POLE_MOVIE_SOUTH`) | A year of real sunlight and shadow sweeping across the pole | LROC RDR browser | Nothing; it's shown as is | Pitch video; optional title background | Should |
| 3 | **LOLA south-pole DEMs** (PGDA "South Pole Landing Site LOLA DEMs", 5 m/px Shackleton rim site; 20 m/px polar DEM) | Laser-altimeter terrain | NASA Goddard PGDA: `pgda.gsfc.nasa.gov/products/78` | **Horizon mask**: the horizon elevation in 360 directions from the base | The **horizon strip** silhouette (real mountains), and the input to #4 | Should |
| 4 | **JPL Horizons API** (topocentric observer `coord@301`) | Sun and Earth azimuth/elevation seen from a point on the Moon, for any date | `ssd.jpl.nasa.gov/horizons` (API or astroquery) | With #3: find a **real future night** at the base (Sun below the horizon mask for ~36 h while Earth is down). Gives exact Last Light, Earth-set and First Light times | "Night One: this night will really happen on [date]"; the Sun and Earth paths in the horizon strip | Should (Must if #3 is done) |
| 5 | **NASA DONKI** (flare, CME and SEP records) | Space-weather event database (CCMC) | `ccmc.gsfc.nasa.gov/DONKI-API/get/{FLR,CME,SEP}` for 2017-09-04 → 2017-09-12 | Event times: X9.3 (6 Sep), X8.2 start/peak, SEP onset | Rafi's forecast (shift 2), the storm timeline, debrief card | **Must** (bundled JSON) |
| 6 | **LRO CRaTER** dose rates (PDS PPI, Level 2) | Radiation dose measured **at the Moon** by LRO | `pds-ppi.igpp.ucla.edu` → LRO CRaTER derived data, 2017-09-04 → 2017-09-14 | The storm's dose-rate curve, scaled to zaps per storm shift | Storm profile and the debrief chart "The real storm at the Moon" | Should |
| 7 | **MSL RAD** (Curiosity) | Radiation on the surface of Mars; the same storm more than doubled the dose on 11 Sep 2017 | PDS (MSL RAD), or NASA/JPL published values | A Moon vs Mars comparison | Debrief card "Same storm, two worlds" | Should |
| 8 | **NASA BVAD** (Rev 2, 2022) | Crew consumables | NTRS 20210024855 | O₂, water and food per person per day | Air rules; Engineer Mode units | **Must** |
| 9 | **NASA VSAT / relocatable array study** | Lunar south-pole vertical solar arrays (~10 m masts, ~10 kW) | NTRS 20220013210; NASA TM-20210011743 | The solar output scale | Kai's masts; Engineer Mode | **Must** |
| 10 | **NASA radiation shielding guidance** (lunar radiation protection, NASA-STD-3001 context) | Storm-shelter shielding ~20 g/cm²; normal operations ~2 g/cm² | NTRS 20210009760 (Clowdsley) | The wall's g/cm² scale | Rafi's wall in Engineer Mode | **Must** |
| 11 | **NASA LEAF** (built for the first Artemis landings) and **Veggie** | Plants on the Moon and the ISS | NASA / Space Lab pages | Facts only | Alo's story; debrief | **Must** |
| 12 | **NASA SVS** visualizations (#5027 south-pole illumination; #4491 the X8.2 flare from SDO) | Real NASA animations | `svs.gsfc.nasa.gov/5027`, `/4491` | Nothing | Pitch video | **Must** (video) |
| 13 | **LRO Diviner** polar temperatures | Measured surface temperatures: the coldest polar craters are below 40 K (Cabeus ≈ 38 K); Shackleton's floor stays below ~90 K (Kaguya terrain model) | Diviner / PDS | Facts only | Kai's "why heat costs so much" tip | Could |
| 14 | **NASA OLTARIS** | Dose behind a given shield thickness | `oltaris.nasa.gov` | Dose vs. water depth for an SEP spectrum | Calibrates the zap table | Could |
| 15 | **NASA Moon Trek** | Interactive maps of the south pole | `trek.nasa.gov/moon` | Nothing; for exploring | Teacher guide: "visit our base on Moon Trek" | Could |

**On 28 October**, NASA publishes the challenge's official datasets. Map each one into this table, and prefer the official dataset wherever it covers the same thing.

**What judges will notice:**
- The storm timeline is taken from NASA records (#5), and sunlight, Earth visibility and the dose curve are **computed from NASA data** (#1, #3, #4, #6) once those pipeline steps are done and checked. Anything not yet computed is labelled *training scenario*, never "NASA measured".
- The game shows the real charts in the debrief.

---

## C. Data pipeline for the hackathon (one team member, about 6–8 hours)

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
