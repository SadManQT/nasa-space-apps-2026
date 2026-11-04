# Chapter 1 science review (M1-40)

Independent review of Chapter 1 *Night One* as built, before the demo freeze (M1-24). Reviewer: Claude Code (Opus 5.5) subagent for Sadman, 4 Nov 2026. Nobody's conclusions were handed over. Every number below was checked against a primary source fetched today, or recomputed from one.

**Scope:**
- the twelve scenes EX-CH01-S01..S12 in `full-game-story/STORY_FULL.md`
- the 49 Chapter 1 voice lines in `production/audio/vo_lines.csv`
- P-01, P-02 and the P-02 numeric contract in `game-design/08_PUZZLE_DESIGNS.md`
- the EX-M0101..M0104 cards in `game/resources/campaign/content/mission_data_cards.json`
- the fixtures that `puzzle_sources.json` maps to P-01 and P-02, and how `game/scripts/science/science_data.gd` and `game/scripts/ui/campaign_panels.gd` draw them
- the Chapter 1 gate labels, the Science + Sources screen and the learning-edition boundary text
- §3 of `game-design/22_PUZZLE_CLUE_DESIGN.md`
- the Chapter 1 rows of `README.md` (the judges read it)
- the three composed cutscenes `production/cutscenes/v7/CS-01..03` (frames extracted every 0.5 to 2 s; the game's `.ogv` copies have the same durations)

**Not checked:** the running game. I did not launch Godot. Engineer Mode subtitles and the role cards in 22 §3 are not in the runtime yet; I reviewed them as designs.

**Severity:**
- **Blocker** means change it before the demo freeze. A finding is a blocker when the game's own bundled data contradicts it, it breaks an ART_BIBLE §2 rule on screen, or it tells judges something false.
- **Should fix** means wrong or misleading, but labelled or off the main path.
- **Nit** covers wording precision, docs and polish.

## Summary

| Severity | Count | Findings |
|---|---|---|
| Blocker | 4 | B1 Earth-set at shift 4 is the opposite of the computed sky · B2 the hero Alo flower in CS-03 has five petals · B3 CS-03 sunrise shows a glowing band in the sky · B4 the Science + Sources screen says no AI-generated asset is used |
| Should fix | 9 | S1 to S9 |
| Nit | 9 | N1 to N9 |

28 further items were checked and found correct, or correct as labelled teaching simplifications (see "Verified"). All 49 voice lines are science-safe as written. The only one tied to a finding is EX-CH01-S09-L04 (Ferreira live at 25 Apr 18:00, B1).

Follow-up board tasks: **M1-42** (P0, judge-facing text), **M1-43** (P0, CS-03), **M1-44** (P1, fixture code), **M1-45** (P1, CS-01/CS-02 exterior), **M1-46** (P1, science docs). The freeze task M1-24 does not yet depend on M1-42 and M1-43; Sadman may want to add that.

---

## Blockers

### B1. "Earth-set at shift 4" is the opposite of the April 2046 sky the game ships with

**What the game says.**
- 08 line 27: "Drill at shift 2, Earth-set at shift 4, alarm at shift 5."
- STORY_FULL S09 line 389 ("Earth contact ends at its separate shift gate") and exit gate line 420 ("Earth-set acknowledged").
- Gate label `game/scripts/missions/chapter1_gate_catalog.gd:152`: "Acknowledge the Earth-set cutoff".
- VO `EX-CH01-S09-L04` (vo_lines.csv:38), Ferreira live "before cutoff" at 25 Apr 18:00. CS-02 plays it at 12.6 s with Ferreira on the Earth screen.
- Science boundary (`campaign_catalog.json:36615`, from `full-game-story/content/learning-and-continuity.json:113`): "Earth-set [is an] authored training condition **until** local terrain and ephemerides are validated".
- `main_menu.gd:460`: "A teaching model until the offline lunar processing bundle is validated."
- README.md:67 ("After Earth sets, there is no help from Mission Control"), :79 ("Earth-set in Chapter 1") and :343 ("Earth sinks and the radio turns to static").

**What is true.** I queried JPL Horizons live: target 399, site `coord@301` 0°E −90° h 0, 3-hourly ([query](https://ssd.jpl.nasa.gov/api/horizons.api?format=text&COMMAND=%27399%27&OBJ_DATA=%27NO%27&MAKE_EPHEM=%27YES%27&EPHEM_TYPE=%27OBSERVER%27&CENTER=%27coord%40301%27&COORD_TYPE=%27GEODETIC%27&SITE_COORD=%270%2C-90%2C0%27&START_TIME=%272046-04-25%2012:00%27&STOP_TIME=%272046-04-27%2012:00%27&STEP_SIZE=%273+h%27&QUANTITIES=%274%27&ANG_FORMAT=%27DEG%27)). The result matches the bundled `jpl_horizons_ch1_sky.json`:

- Earth set at the pole on **15 Apr 2046 03:17 UT** and rose on **28 Apr 06:03 UT**.
- Through the whole night (25 Apr 18:00 → 27 Apr 06:00) Earth's elevation **rises** steadily, from −3.44° to −1.40°.
- Height cannot turn a rising Earth into a setting one. A higher site only sees Earth earlier. If Aurora sits 1.5 to 2.5 km above the 1,737.4 km sphere (an assumption: Aurora has no coordinate yet), the horizon dip is 2.4° to 3.1°. Earth would then **rise into view during shifts 3 to 5**, the same window in which the story has it set.
- Earth's disc is about 1.9° wide from the Moon. That shifts these times by hours, not the direction.
- Ferreira's live call at 25 Apr 18:00 needs Earth's centre in view at −3.44°. That takes a site at least about 3.1 km above the sphere with clear terrain toward azimuth ~7°.
- So the cutoff cannot come from Earth setting. "Until validated" promises a check that has now run and gone the other way.
- The P-02 Data Card already shows this to the player: `earth_below_horizon_all_night: true` and "set 15 Apr".
- Not a problem: S01 to S03 (11 Apr) have Earth at +5°, and the 30 Apr return (Ch2) comes after the 28 Apr rise.

**Smallest correct fix.**
1. **Non-canon text, now (M1-42).** Rename the gate to "Acknowledge the Earth-link cutoff (training scenario)". Rewrite the fixture boundary and takeaway, `main_menu.gd:460` and README :67/:79/:343 to say: *"In the computed April 2046 sky, Earth was below the exact pole's horizon from 15 to 28 April and rising during this night. Aurora's shift-4 Earth-link cutoff is an authored training event, not an Earth-set."*
2. **Canon, for Sadman's approval (exact wording in the decisions section).** 08 line 27, the S09 exit gate and the learning-edition boundary.
3. The CS-02 title "The Horizon Closes One Door" can stay. Its exterior shot shows the **sunset**, which is literally true.

**Task:** M1-42.

### B2. The first-bloom close-up shows a five-petal flower

**What the game shows.** In CS-03 shot C (about 18 to 34 s, behind N.'s line at 24 s), the central open Alo flower has **five** petals. I checked frames at 22, 26, 28 and 30 s. The M1-25 prompt asked for four petals (`production/cutscenes/v8/notes_A.md:58`), but the output did not obey.

**What is true.** Every Brassicaceae flower, *Brassica rapa* included, has four petals in a cross: the family's old name, Cruciferae, means "cross-bearers". It also has six stamens, four long and two short ([UAF plant family sheet](https://www.geobotany.uaf.edu/teaching/plant_family_pdf/brassicaceae.pdf): "Petals 4, distinct, often forming a cross"). ART_BIBLE §2 rule 8 requires "four-petal yellow cross-shaped flowers". This is the chapter's emotional peak, and Fast Plants teachers (the target classroom) know the cross on sight.

The rest of the shot is correct: purple stem, lobed leaves, buds above, no face.

**Smallest correct fix.** Re-generate shot C, or paint over it, so every open flower has four petals in a cross. Gate the result on a petal count, not on the prompt text. Alternatively, cut to a render of the approved Alo bloom model. Keep the shot length so the VO timings (12.0, 24.0, 35.0, 38.8 s) do not move.

**Task:** M1-43.

### B3. CS-03 sunrise draws a glowing band of light across the sky

**What the game shows.** From about 0.5 to 4.5 s (under the title card), a broad, soft-edged luminous band sweeps along the horizon and glows into the black sky. It reads as atmospheric twilight. After that the greenhouse window glows, which is fine: it is lamp light.

**What is true.** The Moon has no atmosphere to scatter sunlight, so there is no twilight, glow or light band. At a polar sunrise, first the distant peaks light up with hard edges, then the Sun's disc appears. ART_BIBLE §2 rule 1 says: "No atmosphere glow, fog, haze." NASA describes the exosphere as "extremely tenuous" ([NASA Moon facts](https://science.nasa.gov/moon/facts/), already the SRC-MOON card).

**Smallest correct fix.** Mask the band or re-grade the first 4.5 s of CS-03-A, keeping only hard-edged lit ridge tops and a point-like Sun. Alternatively, re-generate the shot with "airless Moon: no glow or light band in the sky; sunrise is a hard-edged lit ridge and the Sun's disc". If the shot is re-generated, also make the arrays vertical (see S5).

**Task:** M1-43.

### B4. The Science + Sources screen says the chapter uses no AI-generated asset

**What the game says.** `game/scripts/ui/main_menu.gd:466`: "AI disclosure: current gameplay code uses no newly generated asset in this chapter."

**What is true.** Chapter 1 uses things that were all generated with AI:
- CS-01..CS-03 (Seedance 2.5)
- all 49 voice lines (ElevenLabs)
- the character models

The project's own disclosure says so (README.md:119, docs/AI_USE.md), and the competition rules require naming every AI tool (docs/competition-rules.md:160–162). A judge who opens this screen reads a false statement.

**Smallest correct fix.** Replace the sentence with: "AI disclosure: this demo uses AI-generated 3D models, cutscene video and voices; every generation and the team's own work are logged in production/AI_PROMPT_LOG.md (summary: docs/AI_USE.md)."

**Task:** M1-42.

---

## Should fix

**S1. The 20 g/cm² water wall is credited to a source that says it is the GCR target.**
- Where: README.md:65, :82 and :344; SCIENCE_AND_DATA.md:36 (row 7, "NASA's storm-shelter guideline"); 23_NASA_MISSION_PRACTICE.md:300 and :309; fixture `clowdsley_2021_shielding.json` (`guideline_g_cm2: 20`, read as the shelter rule).
- True: Clowdsley 2021 says 20 g/cm² of hydrogen-rich shielding is the target **"for GCR protection"**: slide 16, and the summary on slide 31 ([PDF](https://ntrs.nasa.gov/api/citations/20210009760/downloads/Clowdsley_Lunar_Radiation_Talk_v2.pdf)). For solar particle events it recommends storm shelters or wearables (slides 21–22) and gives the slide-37 table.
- Better SPE anchor: Townsend, Nealy & Wilson 1988 found that keeping the worst historical flares under the astronauts' 25 rem 30-day limit needs **20 g/cm² of water** ([NTRS 19880016043](https://ntrs.nasa.gov/citations/19880016043), p. 4). Today's matching limit is the 250 mGy-Eq 30-day BFO limit, and NASA-STD-3001 Vol 1 Rev B [V1 4031] sets 250 mSv for the design SPE ([PDF](https://www.nasa.gov/wp-content/uploads/2020/10/2022-01-05_nasa-std-3001_vol.1_rev._b_final_draft_with_signature_010522.pdf)).
- Fix: keep the number and change the citation and wording: "20 g/cm² of water: enough to keep the worst recorded solar storms under the 30-day limit (Townsend et al. 1988, NASA); NASA's 2021 lunar guidance uses the same thickness as its target against cosmic rays (Clowdsley)." M1-42 covers README and the fixture; M1-46 covers the docs.

**S2. The storm card says GOES-13 was "inside Earth's magnetic shield".**
- Where: `mission_data_cards.json:361` (built by `build_mission_cards.py:111`); fixture boundary `fetch_nasa_data.py:270`.
- True: geostationary orbit sees ≥10 MeV solar protons almost unshielded. A 2025 comparison of GOES with L1 found "minimal near-Earth modulation of ≥10 MeV proton access at GEO" ([Ali & Sadykov, arXiv:2511.04793](https://arxiv.org/abs/2511.04793)). That is why NOAA uses GOES for its storm scale. As worded, the card implies the Moon would get much more.
- Fix: "GOES-13 measured this 36,000 km above Earth, where Earth's magnetic field barely slows protons this fast. The Moon has no magnetic field or air, so a storm like this reaches its surface. This is a flux, not a dose at the Moon." Task M1-42.

**S3. "Highest 5-minute reading: 1,347 pfu" is not NOAA's official number.**
- Where: `mission_data_cards.json:344`; fixture `goes13_protons_2017_09` uses only the west-facing detector (`fetch_nasa_data.py:231`).
- True: NOAA's official event list gives **1,490 pfu at 11 Sep 11:45 UT** ([NOAA SWPC list, NASA mirror](https://umbra.nascom.nasa.gov/SEP/)). In the same NCEI file ([CSV](https://www.ncei.noaa.gov/data/goes-space-environment-monitor/access/avg/2017/09/goes13/csv/g13_epead_cpflux_5m_20170901_20170930.csv)) the **east-facing** detector peaks at 1,493.5 pfu at 11:45, and the west one at 1,347.2 pfu at 00:55 (my computation).
- The detector choice also changes the derived "second storm shift is 2.6× the first" (SCIENCE_AND_DATA B3-4, 22 §3.4). Per-shift means after onset: west 359 / 923 / 938 / 516 pfu; east 707 / 1153 / 1257 / 938 pfu, a ratio of **1.6×**.
- Fix: use the east detector, or carry both and show NOAA's 1,490. Recompute the ratio. Tasks M1-44 (data) and M1-42 (card label).

**S4. The card's own chart shows the storm continuing after Aurora drains the wall.**
- Where: the EX-M0104 card `for_aurora` (`mission_data_cards.json:359`) and debrief: the storm lasts shifts 5–6, then "the water must go back to the garden".
- True: the >10 MeV flux stayed above the 10 pfu storm level from 10 Sep 16:45 until **13 Sep 21:50 (west) / 14 Sep 17:25 (east)**, about 3¼ to 4 days. The third 7.2 h block after onset (the game's shift 7) was as strong as the second (numbers in S3). The card's chart runs to 12 Sep 11:00 and is still at 233 pfu.
- The rule itself is canon (08), and draining after the exposure resolves is the right lesson. Only the card needs to say the replay is shortened.
- Fix, card limits only: "The real storm stayed above storm level for about three and a half days. Aurora's replay shortens it to two shifts; that is a game rule." Task M1-42 (M1-44 adds a derived `storm_level_end`).

**S5. The solar arrays in CS-01, CS-02 and CS-03 are not what the cited VSAT study describes.**
- Where: shot A of each cutscene: four small square panels (roughly 9 m²) on about 8 m poles. One is tilted back about 30°, and both face the camera while the Sun is to the side (CS-01 at 5 s).
- True: the NASA 10 kW relocatable array is a **vertical 36 m² blanket on a 16 m mast that "must rotate to track the Sun"** ([NASA/TM-20210011743](https://ntrs.nasa.gov/api/citations/20210011743/downloads/NASA-TM-20210011743.pdf), pp. 2, 6). Data Card EX-M0101 tells players the power comes from "low, sideways sunlight".
- Fix: at the next exterior re-render, use tall vertical blankets, face-on to the low Sun. Not a blocker. Tasks M1-43 (CS-03-A) and M1-45 (CS-01-A, CS-02-A).

**S6. The P-02 sky Data Card plots Earth's azimuth, not its elevation.**
- Where: `science_data.gd` `_visual()` draws `columns[1]`, and `jpl_horizons_ch1_sky` puts `earth_azimuth_deg` first (`fetch_nasa_data.py:419`, same at :449 for Ch 8).
- The chart is a meaningless sawtooth (353° → 359.7° → 0.05° → 7°). The quantity that matters, elevation crossing 0°, is not drawn.
- Fix: order the columns as `utc, earth_elevation_deg, earth_azimuth_deg, sun_elevation_deg`. Task M1-44.

**S7. The OSDR fixture tells players the Veggie protocol had no 16 h light and no 23 °C.**
- Where: `osdr_brassica_rapa_iss.json` has `photoperiod_16_8: false` and `temperature_23C: false`, shown under "WHAT WAS MEASURED / SUPPLIED".
- True: OSD-412 states "16 h/8 h light dark … temperature 23 C … 200–300 µmol m⁻² s⁻¹" ([OSDR OSD-412](https://osdr.nasa.gov/osdr/data/osd/meta/412)). The substring test at `fetch_nasa_data.py:553` fails because OSDR uses a thin space (U+2009).
- Fix: normalise whitespace before matching, then regenerate. Task M1-44.

**S8. "Computed by NASA JPL" overstates NASA's role.**
- Where: EX-M0101 card limits, `mission_data_cards.json:175` (`build_mission_cards.py:66`).
- True: the team computed the curve with JPL's Horizons service (DE441). NASA did not compute it for the game. Honesty rule D in SCIENCE_AND_DATA says "no claim that NASA endorses us".
- Fix: "Computed with NASA JPL's Horizons service for a flat horizon at the exact pole…" Task M1-42.

**S9. The README describes visible radiation and a sinking Earth that the game does not show.**
- Where: README.md:344 "Sparks fizzle in the blue water wall"; :343 "Earth sinks and the radio turns to static".
- True: radiation is never visible (ART_BIBLE §2 rule 6), and the code has no such effect (grep for spark/fizzle finds nothing relevant). Earth is not drawn, and during this night it rises (B1).
- Fix: "The wall gauge fills and the exposure meter stays low" and "The Earth link greys out and stored guidance takes over". Task M1-42.

---

## Nits

**N1.**
- Where: EX-M0103 card, `mission_data_cards.json:241` and `:265`: "NASA's LRO spacecraft mapped the sunlight…" and "one measured spot".
- True: Mazarico et al. 2011 *calculated* illumination from LOLA terrain maps ([NTRS 20120010094](https://ntrs.nasa.gov/citations/20120010094)). The 240-day and 1.5-day figures are correct.
- Fix: "Scientists used maps from NASA's LRO laser altimeter to calculate…" and "one modelled spot". Optionally add the paper's point that 10 m of height can shorten the night: Aurora's masts are 10 m. (M1-42)

**N2.**
- Where: Rafi's shift-2 card in 22 §3.3 clue 4: "sunspot 2673 fired a large flare".
- True: the X9.3 flare (6 Sep 11:53) and the X8.2 flare (10 Sep 15:35) were **4 days 3.7 h apart** ([DONKI FLR](https://ccmc.gsfc.nasa.gov/DONKI-API/get/FLR?startDate=2017-09-04&endDate=2017-09-12)). The replay puts them less than a day apart.
- Fix: one debrief line, "The replay squeezes four days into one." (M1-46)

**N3.**
- Where: COLD "≈ 0 °C" labelled frost damage (SCIENCE_AND_DATA:52, 23:274, the Mei role fact in 10_GAMEPLAY_SYSTEMS.md:154, 22 §3.3 clue 6).
- True: for *Brassica* crops, "heavy frost" means **below −2 °C**; a light frost above −2 °C is "of little concern" ([Canola Council of Canada, fall frost](https://www.canolacouncil.org/canola-watch/2017/09/07/fall-frost-swathing-and-straight-combining-considerations)). At 0 °C a field mustard is chilled, not frosted.
- Fix: label COLD "near or below freezing" and keep the damage numbers. (M1-46)

**N4.**
- Where: SCIENCE_AND_DATA:37 "Pumping a few hundred litres".
- True: a 20 cm water wall (20 g/cm²) around even a small four-person shelter (about 11 m² of wall) holds about 2,000 L. The energy claim still holds: lifting 2 t by 2 m in lunar gravity takes about 7 kJ. The same row's "~40-minute warning" also disagrees with the card's 70 min (DONKI: >10 MeV onset 70 min after flare start; first >100 MeV particles 50 min after).
- Fix: correct both numbers. (M1-46)

**N5.**
- Where: 23:270, "CO₂ cannot build up in cabin air, so scrubbers never turn off".
- Fix: "CO₂ builds up within hours and must never be allowed to, so scrubbers never turn off." (M1-46)

**N6.**
- Where: the Data Card for `fast_plants_lifecycle` draws "Alo bloom day 16 · Computed from fixture". The 16 comes from story dates (its formula says "(story)").
- Fix: draw `days_to_flower` 14, or label story values "story date". (M1-44)

**N7.**
- Where: CS-01 at 1–5 s.
- The Sun disc is about 2° wide (real: 0.53°) and has a soft halo.
- Fix: smaller disc, no halo, at the next re-render. (M1-45)

**N8.**
- Where: STORY_FULL S03 line 115: "two seeds, Bengali lettering and a single initial".
- This is not science, but it conflicts with the locked rule "No Bangla script in the game" (CLAUDE.md; ART_BIBLE §7: the packet reads "ALO" and "N." in Latin letters, as in 22 §3.1 clue 6).
- Fix: canon wording, Sadman decides (see below).

**N9.**
- Where: EX-M0104 plain, `mission_data_cards.json:284`: "a huge flare on the Sun threw out a storm of protons".
- True: the 10 Sep 2017 particles were accelerated by the flare **and** the 2,650 km/s CME shock (DONKI links SEP 16:25 to both FLR and CME).
- Fix: "a huge flare and a very fast cloud of solar gas sped up a storm of protons". (M1-42)

---

## Verified: correct, or correct as a labelled simplification

| # | Claim (where) | Source checked | Verdict |
|---|---|---|---|
| V1 | O₂ 0.895, CO₂ 1.085, food 0.800, water 3.217 kg per crew-day; 82 kg reference (fixture `bvad_2022_metabolic`; 23 §5.1) | [BVAD Rev 2 Table 3-31, p. 58](https://ntrs.nasa.gov/api/citations/20210024855/downloads/BVAD_2.15.22-final.pdf) (text extracted) | Correct |
| V2 | 1 air unit = 4 × 0.895 × 7.2/24 = 1.074 kg O₂; 4 crew breathe 1 unit per shift; A6 runs out in 7 shifts without O (22 §3.3) | Arithmetic from V1 | Correct |
| V3 | Rations −1.2 crew-days per shift; 12 − 8.4 = R3.6 at dawn | Arithmetic from 08 | Correct |
| V4 | 7 shifts × 7.2 h; 5 dark shifts = 36 h; 25 Apr 03:36 → 18:00 = 2 shifts; night ends 27 Apr 06:00 | Arithmetic from STORY_FULL S06–S12 | Correct |
| V5 | Shackleton-rim site: sunlit 240 days in a row, longest total darkness about 1.5 days → 36 h night (EX-M0103 card) | [Mazarico et al. 2011 abstract, NTRS](https://ntrs.nasa.gov/citations/20120010094) | Correct as a labelled training scenario |
| V6 | Sun within about 1.6° of the horizon at the pole in 2046–47; "less than a thumb at arm's length" (EX-M0101) | Fixture −1.56° to +1.59° (Horizons; spot-checked live); [thumb ≈ 2°, SDSU](https://aty.sdsu.edu/explain/atmos_refr/angles.html) | Correct |
| V7 | Earth up on 11 Apr (S01–S03 Earth link, +5.1°); Earth back by the 30 Apr live link (Ch 2) | Horizons, as in B1 | Correct |
| V8 | X8.2 flare 15:35 start, 16:06 peak, AR 12673; >100 MeV 16:25; >10 MeV 16:45; 70 min lead; CME 2,650 km/s | [DONKI FLR](https://ccmc.gsfc.nasa.gov/DONKI-API/get/FLR?startDate=2017-09-04&endDate=2017-09-12) and [SEP](https://ccmc.gsfc.nasa.gov/DONKI-API/get/SEP?startDate=2017-09-10&endDate=2017-09-10) (live); NOAA list 10/1645 start | Correct |
| V9 | "Sunspot 2673 fired a large flare" (X9.3, 6 Sep 2017 11:53) | DONKI FLR | Correct (timing compressed, N2) |
| V10 | pfu = protons per cm² per second per steradian ("from one patch of sky") | GOES CSV header | Correct |
| V11 | Mizuna (*B. rapa*) grew 27 days in Lada at 125–250 µmol m⁻² s⁻¹ (EX-M0102) | [OSDR OSD-59 metadata](https://osdr.nasa.gov/osdr/data/osd/meta/59) | Correct |
| V12 | Veggie VEG-03D 200–300 µmol m⁻² s⁻¹ (FULL lamp reference) | [OSDR OSD-412](https://osdr.nasa.gov/osdr/data/osd/meta/412) | Correct |
| V13 | Fast Plants: flower in 14 days; self-incompatible; stigma receptive 2–4 days; pollinate days 15–21; pods 20 days; seed by day 40 | [Fast Plants FAQ](https://fastplants.org/frequently-asked-questions/) (all six quotes found) | Correct |
| V14 | Alo planted 11 Apr, bud by 24 Apr, blooms 27 Apr (day 16) through one cold, dark 36 h night; "Alo needs a friend" (self-incompatible) | Fast Plants FAQ: 14 days under 24 h light at about 21 °C | Correct as a labelled simplification (SRC-PLANTS boundary) |
| V15 | "A sealed experiment grew a cotton seedling on the Moon in 2019" (VO S03-L05; S03; SRC-COTTON2019) | [Qiu et al. 2021 §4.2](https://doi.org/10.3390/ijms222111723) ([full text, PMC8583895](https://www.ebi.ac.uk/europepmc/webservices/rest/PMC8583895/fullTextXML)): sealed 0.82 L payload; cotton germinated 22 h after watering, first leaf at 82 h; no flowering | Correct. Optional enrichment: the same payload also carried rapeseed, a *Brassica*, which did not germinate in view |
| V16 | Plants stay inside pressurised chambers (S03, S04; all cutscenes) | ART_BIBLE §2 rule 5 | Correct |
| V17 | Storm shown as an instrument trace, cabin and suit sound only, no glowing particles (S10; CS-01..03 audio is music and voice) | ART_BIBLE §2 rules 6 and 7 | Correct |
| V18 | Clowdsley slide 37: 185.4 / 136.9 / 105.4 / 85.1 mSv at 5 / 7 / 10 / 15 g/cm²; dose never reaches zero (22 §3.4 Engineer Mode) | Clowdsley PDF, slide 37 table | Correct |
| V19 | Z ≤ 3 stands for the NASA-STD-3001 [V1 4031] 250 mSv design-SPE limit; ALARA [V1 4029] (23 §6) | NASA-STD-3001 Vol 1 Rev B, pp. 29–33 | Correct as a labelled teaching threshold |
| V20 | Full wall 6 units = 20 g/cm² = 20 cm of water; 1 unit = 3.3 cm | Water density 1 g/cm³ | Correct (attribution: S1) |
| V21 | 10 kW array, blanket raised 10 m, 16 m mast; 8 drops × 10 kWh / 7.2 h = 11.1 kW = 56 % of two arrays | [NASA/TM-20210011743](https://ntrs.nasa.gov/citations/20210011743) | Correct as a labelled estimate [E] |
| V22 | Electrolysis: about 10 kWh and about 1.2 L of water per 1.07 kg O₂ | Stoichiometry (1.125 kg water per kg O₂); thermoneutral minimum ΔH = 285.8 kJ/mol ([NIST](https://webbook.nist.gov/cgi/cbook.cgi?ID=C7732185&Mask=2)) = 5.0 kWh per kg O₂, so 8–10 kWh at real efficiency | Correct as a labelled estimate [E] |
| V23 | Light OFF −1 / DIM 0 (compensation point) / FULL +1; scrubbers can never be switched off; "making oxygen does not remove CO₂" (misconception card) | Plant physiology; BVAD | Correct as a labelled simplification |
| V24 | P-02 worked plans | Recomputed Bloom/WAIT (E2 A1 H1 W0 K0 C3 R3.6 Z2) and Golden (E0 A1 H5 W0 K0 C9 R3.6 Z2) by hand from the 08 contract | Correct |
| V25 | Two-point probe calibration (dry 10 → 0, wet 110 → 100; band 40–60) | Instrument practice | Correct as labelled [G] |
| V26 | CS-01/02: black sky, hard near-black shadows, Sun on the horizon, grey regolith, no dust, no Earth drawn; Alo purple and Tara green stems; no plant faces; magenta-white grow light on Tara | ART_BIBLE §2 rules 1–5, 8, 11 and §4 | Correct, apart from B2, B3, S5 and N7 |
| V27 | Earth light-time 1.28 s one way (23 §8) | [NSSDCA Moon fact sheet](https://nssdc.gsfc.nasa.gov/planetary/factsheet/moonfact.html): 384,400 km / c | Correct |
| V28 | Agency labels: NOAA NCEI as a partner, DONKI as NASA GSFC CCMC, OSD-59 with Russia's space agency, Chang'e-4 as CNSA and Chongqing University | Fixtures and sources above | Correct (S8 aside) |

---

## Changes that need Sadman's approval (canon)

No canon number changes are needed. The canon text proposals:

1. **08 line 27.** Replace "Earth-set at shift 4" with "**Earth-link cutoff at shift 4 (authored training event; Earth is already below the pole's horizon and rising this night)**".
2. **STORY_FULL S09 exit gate (line 420)**, and the same string in story-data.json and the catalog. Replace "Earth-set acknowledged" with "**Earth-link cutoff acknowledged**". The prose at line 389 ("Earth contact ends at its separate shift gate") and the title "The Horizon Closes One Door" (the sunset) can stay.
3. **learning-and-continuity.json:113 scienceBoundary.** New text: "The 36-hour darkness and the shift-4 Earth-link cutoff are authored training conditions. The computed April 2046 sky (JPL Horizons) has Earth below the pole's horizon and rising during this night. Water shielding illustrates mass and geometry; zaps are not measured doses and plants are not radiation-immune."
4. **Optional, not for the freeze.** Make the Earth-link loss physical rather than authored. Two ways: move the Chapter 1 calendar about 10 days earlier so the night straddles the 15 Apr Earth-set, which ripples into the P-03 and P-06 dates; or give the cutoff a non-geometric cause. I recommend items 1–3 only before 13 Nov.
5. **STORY_FULL S03 line 115.** Replace "Bengali lettering" with "**the word ALO and a single initial, N., in Latin letters**" to match the no-Bangla-script lock (N8).
6. **Freeze dependencies.** Make M1-24 depend on M1-42 and M1-43 if the blockers must gate the freeze.

## Follow-up tasks added to the board

| Id | Tool | Pri | Covers |
|---|---|---|---|
| M1-42 | claude | P0 | B1 (non-canon text, then canon after approval), B4, S1 (README and fixture), S2, S3 (label), S4, S8, S9, N1, N9 |
| M1-43 | claude | P0 | B2, B3 (CS-03), plus S5 for CS-03-A |
| M1-44 | codex | P1 | S3 (data), S6, S7, N6, plus a derived storm-end time for S4 |
| M1-45 | claude | P1 | S5 (CS-01-A, CS-02-A), N7 |
| M1-46 | claude | P1 | S1 (docs), N2, N3, N4, N5, and the B1 wording in SCIENCE_AND_DATA B3-5, 16_SCIENTIFIC_ACCURACY row 48 and 23 §8.2 |

## Method

- **Primary sources, all fetched or queried on 4 Nov 2026:** JPL Horizons (live API); NASA CCMC DONKI (live API); NOAA SWPC SEP list; NOAA NCEI GOES-13 EPEAD 5-min CSV (peaks and storm duration recomputed); NASA BVAD Rev 2; Clowdsley 2021; Townsend et al. 1988; NASA-STD-3001 Vol 1 Rev B; NASA/TM-20210011743; Mazarico et al. 2011 (NTRS); NASA OSDR OSD-59 and OSD-412 metadata; Fast Plants FAQ; Qiu et al. 2021 full text (Europe PMC); Ali & Sadykov 2025; Canola Council of Canada frost guide; UAF Brassicaceae family sheet; NIST WebBook (water).
- **Recomputed by hand or script:** the P-02 witnesses, the air and ration arithmetic, horizon dip for a range of site heights, GOES per-shift means and storm-level crossings.
- **Cutscenes:** frames every 2 s across all three, every 0.5 s across the CS-02 and CS-03 exteriors, and zoomed crops of the Alo bloom at 22, 26, 28 and 30 s.
- **Not done:** I did not launch the game. Run-and-observe screenshots belong to M1-21 and to the fix tasks above.
