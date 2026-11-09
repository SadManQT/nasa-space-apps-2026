# M3-75 — Science Fact-Check: Chapters 1–4 (`ch01.json`, `ui_text.json`, `mission_data_cards.json`, `explainers.json`)

**Date:** 9 November 2026
**Reviewer:** Sadman/antigravity
**Verdict:** **PASS** (0 science errors, 0 canon drift, 0 Bangla script or NASA logos)

---

## 1. Reference Sources Checked
- `docs/SCIENCE_AND_DATA.md` (Moon South Pole geometry, solar constant, regolith thermal/shielding properties, EVA oxygen & water budgets, SEP propagation, radio link geometry, plant biology)
- `game/resources/data/nasa/artemis_iii_regions.json` (Malapert Massif coordinates `85.97° S, 0.25° E`, lighting fraction `0.86`, slope bounds, Earth elevation `2.1°`)
- `game/resources/data/nasa/lunar_environment.json` (surface gravity `1.625 m/s²`, solar irradiance `1361 W/m²`, escape velocity `2.38 km/s`, orbital period `27.32 d`, PSR floor temperature `38 K`, illuminated ridge `220 K`, regolith density `1500 kg/m³`)
- `game/resources/data/nasa/lro_surface_temperatures.json` (Diviner radiometer thermal profiles for sunlit ridge, shadow transition, and PSR basin)
- `game/resources/data/nasa/space_weather_events.json` (CME transit speeds `850–1800 km/s`, warning windows `20–45 min`, proton flux thresholds, regolith shielding half-value thicknesses)
- `game/resources/data/nasa/plant_growth_profiles.json` (*Brassica rapa*, *Lactuca sativa*, *Raphanus sativus*, *Arabidopsis thaliana* PAR targets `150–260 µmol/m²/s`, temperature `18–24 °C`, photoperiod `16 h`, harvest cycle)
- `full-game-story/STORY_FULL.md` & `game-design/08_PUZZLE_DESIGNS.md` (canonical puzzle numbers for P-01 through P-08)

---

## 2. File-by-File Science Audit

### 2.1 `game/resources/strings/en/ch01.json` (28 strings) & `ui_text.json` (285 strings)
| ID / Section | Claim in String Table | Reference Value (`SCIENCE_AND_DATA.md` / `nasa/*.json`) | Status |
|---|---|---|---|
| `CH01_BRIEF_BODY` / `CH01_S01_001` | Malapert Ridge station at `85.97° S`, low-angle polar sunlight (`~1.5°–3°` horizon graze), black airless sky | `artemis_iii_regions.json`: Malapert Massif `85.97° S`, `0.25° E`; airless body with `0 Pa` atmosphere | **PASS** |
| `CH01_S04_001`..`005` / `UI_POWER_*` | Solar array generation `25.0 kW` nominal -> `9.0 kW` dust-degraded; minimum essential load (`4.8 kW` life support + `2.1 kW` thermal + `1.4 kW` comms = `8.3 kW`) | `08_PUZZLE_DESIGNS.md` P-01 & `SCIENCE_AND_DATA.md` §3: solar constant `1361 W/m²`, triple-junction GaAs efficiency `~30%`, electrostatic dust occlusion reduces output by `60–65%` | **PASS** |
| `CH01_S08_001`..`004` / `UI_ COMMS_*` | Earth-link pointing from Malapert (`~4.0°` elevation to Earth center / `2.1°` above local skyline); `1.28 s` one-way light time (`~2.56 s` round-trip) | `SCIENCE_AND_DATA.md` §4: mean Earth–Moon distance `384,400 km` / `c = 299,792 km/s` = `1.282 s` one-way (`2.56 s` RTT) | **PASS** |
| `CH01_S10_001`..`006` / `UI_STORM_*` | Solar energetic particle (SEP) storm warning: hard X-rays/relativistic electrons arrive near light speed (`~8 min` from 1 AU), bulk proton front follows `30–45 min` later; safe room uses regolith + water-wall hydrogen shielding | `space_weather_events.json` & `SCIENCE_AND_DATA.md` §5: `1 AU / c = 499 s (8.3 min)`; `10–100 MeV` protons take `25–60 min`; low-Z hydrogen-rich water + `1.5 g/cm³` regolith minimizes secondary neutron Bremsstrahlung | **PASS** |

### 2.2 `game/resources/data/mission_data_cards.json` (Chapters 1–4: `EX-M0101`..`EX-M0404`, 16 cards)
| Mission ID | Chapter & Topic | Verified Scientific Claims & Numbers | Status |
|---|---|---|---|
| `EX-M0101` | Ch 1 — Solar Grazing & Power Bus (`P-01`) | `1361 W/m²` AM0 irradiance; `86%` annual illumination on Malapert peak; `9.0 kW` post-dust supply vs `8.3 kW` critical life-support/thermal/comms floor | **PASS** |
| `EX-M0102` | Ch 1 — High-Gain Earth Link (`P-02`) | Ka/S-band dish pointing tolerance; `384,400 km` path; `1.28 s` one-way light delay; libration shifts Earth `±6.5°` in longitude and `±6.7°` in latitude | **PASS** |
| `EX-M0103` | Ch 1 — SEP Shelter & Water Mass Shielding | Proton flux attenuation in hydrogenous water bladders (`1 g/cm³`) + sintered basalt regolith (`1.5–1.8 g/cm³`); ALARA dose budgeting | **PASS** |
| `EX-M0104` | Ch 1 — Post-Storm Bus Recovery | Sequential bus re-energization to avoid inrush current tripping solid-state power controllers (SSPCs) | **PASS** |
| `EX-M0201` | Ch 2 — Airlock Depress/Repress & Suit Loop (`P-03`) | Cabin `56.5 kPa` (`8.2 psi`, `34% O2` normoxic exploration atmosphere) vs suit `29.6 kPa` (`4.3 psi` pure `O2`) minimizing pre-breathe nitrogen decompression risk | **PASS** |
| `EX-M0202` | Ch 2 — Electrostatic Lunar Dust Mitigation (`P-03`) | Crushed silicate agglutinates (`< 20 µm`), UV photoemission positive charging on sunlit side, seal abrasion and inhalation toxicity | **PASS** |
| `EX-M0203` | Ch 2 — Phytochrome & Red/Blue LED Photobiology (`P-04`) | *Brassica rapa* & *Arabidopsis* chlorophyll A/B absorption peaks at `450 nm` (blue) and `660 nm` (red); PAR `220 µmol/m²/s`; `16 h / 8 h` photoperiod | **PASS** |
| `EX-M0204` | Ch 2 — Closed-Loop Transpiration & Humidity | Plant transpiration returns `> 95%` of irrigation water as condensate potable water while fixing `CO2` via Calvin cycle | **PASS** |
| `EX-M0301` | Ch 3 — CELSS Water & Oxygen Mass Balance (`P-05`) | Human metabolic intake `0.84 kg O2/day`, potable + hygiene water recycle `93–98%`, Sabatier + electrolysis loop | **PASS** |
| `EX-M0302` | Ch 3 — Thermal Control & Radiator Rejection | Vacuum heat rejection exclusively via radiation (`q = εσT⁴`); ammonia/glycol cold plates and louver turndown during shadow | **PASS** |
| `EX-M0303` | Ch 3 — Crew Circadian Rhythm & Polar Daylight | Absence of 24-hour solar cycle at `86° S`; tunable solid-state lighting (`6500 K` blue-enriched morning to `2700 K` evening) | **PASS** |
| `EX-M0304` | Ch 3 — Structural Pressure Integrity & Micro-Leaks | Acoustic ultrasonic leak localization in vacuum; pressure decay rate `dP/dt` proportional to orifice area | **PASS** |
| `EX-M0401` | Ch 4 — Traverse Kinematics & Slope Stability (`P-06`) | `1.625 m/s²` (`0.166 g`) reduces normal force and traction; regolith angle of repose `~35°`, rover safe pitch/roll limit `15°–20°` | **PASS** |
| `EX-M0402` | Ch 4 — Permanently Shadowed Regions (`P-06`/`P-07`) | LRO Diviner PSR floor temperatures `38–50 K` (`-235 °C`); cold-trapped water ice stable over gigayears below `110 K` sublimation threshold | **PASS** |
| `EX-M0403` | Ch 4 — Line-of-Sight Relay & Knife-Edge Diffraction (`P-07`) | Airless Moon lacks ionosphere (`no skywave bounce`); radio horizon `d ≈ 1.87 √h` km (`~2.4 km` for a `1.6 m` mast on flat sphere), requiring elevated ridge relays | **PASS** |
| `EX-M0404` | Ch 4 — Cryogenic Regolith Coring & Volatiles (`P-08`) | Auger frictional heating risk: warming icy regolith above `110 K` sublimates `H2O` and `CO/H2S/NH3` volatiles in vacuum before sealing | **PASS** |

### 2.3 `game/resources/data/explainers.json` (12 Explainer Cards)
- Verified all 12 explainer entries (`solar_geometry`, `dust_charging`, `light_time_delay`, `sep_radiation_shielding`, `exploration_atmosphere`, `led_photosynthesis`, `water_recovery_loop`, `radiative_cooling`, `lunar_gravity_traction`, `psr_cold_traps`, `line_of_sight_relay`, `volatile_sublimation`) against `docs/SCIENCE_AND_DATA.md` and `game/resources/data/nasa/*.json`.
- Every unit (`kW`, `W/m²`, `kPa`, `µmol/m²/s`, `K`, `m/s²`, `km`, `s`) and physical mechanism is accurate and matches the puzzle numbers in `08_PUZZLE_DESIGNS.md`.

---

## 3. Conclusion
All Chapter 1–4 strings, UI labels, mission data cards, and explainers pass scientific verification with zero discrepancies.
