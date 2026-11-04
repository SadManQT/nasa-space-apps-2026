# Real NASA Mission Practice Behind Every Decision

**Board task:** `M1-39` · **Last updated:** 4 November 2026  
**Canon alignment:** Numbers come unchanged from [`game-design/08_PUZZLE_DESIGNS.md`](08_PUZZLE_DESIGNS.md); story scenes follow [`full-game-story/STORY_FULL.md`](../full-game-story/STORY_FULL.md) (`EX-CHxx-Sxx`); datasets and honesty tags (`[M]` measured, `[C]` computed, `[E]` engineering estimate, `[G]` gameplay, `[F]` fiction) follow [`docs/SCIENCE_AND_DATA.md`](../docs/SCIENCE_AND_DATA.md); Moon science and presentation locks follow [`production/ART_BIBLE.md`](../production/ART_BIBLE.md) §2.

> **Plain summary for a 10–12-year-old:** In *Last Light Academy*, you never guess in the dark—every choice you make uses the same eight teamwork habits that real NASA engineers and flight controllers use to keep astronauts and plants alive in space.

---

## 0. Master Index of the Eight NASA Practices and Their Offline Fixtures

Every public NASA and partner source cited in this document was verified live on **4 November 2026** (`curl -sIL` HTTP 200) and is backed by an offline JSON fixture with provenance in [`game/resources/data/nasa/`](../game/resources/data/nasa/) and indexed in [`game/resources/data/nasa/puzzle_sources.json`](../game/resources/data/nasa/puzzle_sources.json).

| ID | NASA Mission Practice | Primary NASA Document & Number | Verified URL | Page / Section | Offline Fixture(s) in `game/resources/data/nasa/` |
|---|---|---|---|---|---|
| **MP-01** | **Engineering Trade Studies** | *NASA Systems Engineering Handbook*, `NASA/SP-2016-6105 Rev 2` (`HQ-E-DAA-TN38707`, NTRS `20170001761`) | <https://ntrs.nasa.gov/citations/20170001761> | §2.5 (p. 14 / PDF p. 26), §4.3 (pp. 82–83 / PDF pp. 94–95), §6.8 *Decision Analysis* (pp. 193–201 / PDF pp. 206–214), App. B (p. 235 / PDF p. 247) | `nasa_se_handbook_trade_studies.json` |
| **MP-02** | **Pre-Agreed Flight Rules** | *Flight Rules Critical Readiness Review*, `JSC-CN-19880` (NTRS `20100008453`); *Updates to NASA's Break-in-Prebreathe Flight Rules*, `NASA/TP-20240016139` (NTRS `20240016139`) | <https://ntrs.nasa.gov/citations/20100008453> · <https://ntrs.nasa.gov/citations/20240016139> | `JSC-CN-19880` PDF pp. 1–4 (Volume B §B13/B14 constraints); `NASA/TP-20240016139` §1–2 | `nasa_iss_flight_rules_go_nogo.json`, `viper_slope_limit.json` |
| **MP-03** | **Go / No-Go Console Polls** | *ISS Mechanisms and Maintenance Flight Control Documentation and Training Development*, `JSC-CN-22496` (NTRS `20100042411`); *Shuttle & ISS GNC Flight Controllers* (NTRS `20070016005`) | <https://ntrs.nasa.gov/citations/20100042411> · <https://ntrs.nasa.gov/citations/20070016005> | `JSC-CN-22496` PDF pp. 2–6 (MCC console disciplines & simulations) | `nasa_iss_flight_rules_go_nogo.json` |
| **MP-04** | **ISS Procedures & Checklists (ODF)** | *An XML Representation for Crew Procedures* (NTRS `20050202022`); *NASA Spaceflight Human-System Standard Vol 2 Rev E*, `NASA-STD-3001 Vol 2 Rev E` (NTRS `20250004555`) | <https://ntrs.nasa.gov/citations/20050202022> · <https://ntrs.nasa.gov/citations/20250004555> | NTRS `20050202022` PDF pp. 1, 3–6; `NASA-STD-3001 Vol 2 Rev E` §10.6 (procedure & Caution/Warning formatting) | `nasa_iss_crew_procedures_odf.json` |
| **MP-05** | **Consumables & Margins (BVAD)** | *Life Support Baseline Values and Assumptions Document (BVAD)*, `NASA/TP-2015-218570/REV2` (NTRS `20210024855`); *Relocatable 10 kW Solar Array*, `NASA/TM-20210011743` (NTRS `20210011743`) | <https://ntrs.nasa.gov/citations/20210024855> · <https://ntrs.nasa.gov/citations/20210011743> | BVAD Table 3-31 (printed p. 58 / PDF p. 72), cabin pressure (PDF pp. 62, 75, 155); `TM-20210011743` PDF pp. 5, 8 | `bvad_2022_metabolic.json`, `vsat_relocatable_array.json`, `osdr_brassica_rapa_iss.json` |
| **MP-06** | **Radiation PELs & ALARA** | *NASA Space Flight Human-System Standard, Volume 1: Crew Health*, `NASA-STD-3001 Vol 1 Rev B`; *Design for Ionizing Radiation Protection*, `OCHMO-TB-020 Rev E`; Clowdsley (NTRS `20210009760`) | <https://www.nasa.gov/wp-content/uploads/2020/10/2022-01-05_nasa-std-3001_vol.1_rev._b_final_draft_with_signature_010522.pdf> · <https://ntrs.nasa.gov/citations/20210009760> | `NASA-STD-3001 Vol 1 Rev B` §4.8.1 `[V1 4029]` (p. 29), §4.8.2 `[V1 4030]` & Table 3 (pp. 29–30), §4.8.3 `[V1 4031]` (pp. 31–32), §4.8.4 `[V1 4032]` (p. 33); Clowdsley slides 15, 16, 31, 37 | `nasa_std_3001_radiation.json`, `clowdsley_2021_shielding.json`, `donki_2017_09.json`, `goes13_protons_2017_09.json`, `donki_2012_07.json`, `stereo_a_het_2012_07.json`, `crater_dose_2012_07.json`, `change4_lnd_surface_dose.json` |
| **MP-07** | **5×5 Risk Matrix, MER Anomaly Resolution & Debrief** | *NASA Risk Management Handbook*, `NASA/SP-2011-3422` (NTRS `20120000033`) & *Ver 2.0 Part 1*, `NASA/SP-20240014019`; *Anomaly Resolution in the ISS*, `JSC-CN-6337` (NTRS `20100036651`); *Constellation Lessons Learned Vol 2*, `NASA/SP-2011-6127-VOL-2` (NTRS `20110015803`) | <https://ntrs.nasa.gov/citations/20120000033> · <https://ntrs.nasa.gov/citations/20100036651> · <https://ntrs.nasa.gov/citations/20110015803> · <https://llis.nasa.gov/> | `SP-2011-3422` §4.3 / Fig. 53 (PDF pp. 101–165); `SP-2016-6105 Rev 2` §6.4 (PDF pp. 172–180); `JSC-CN-6337` pp. 1–2 | `nasa_risk_and_anomaly_mer.json`, `apollo_shallow_moonquakes.json`, `meo_lunar_impact_flashes.json` |
| **MP-08** | **CAPCOM Voice Protocol, Link Windows & Light-Time Delay** | *NSSDCA Moon Fact Sheet*; *JPL Horizons Ephemeris System (DE441)*; *Lunar Pole Illumination & Communications Maps*, JPL `IPN Progress Report 42-176`; *ESA Moonlight* | <https://nssdc.gsfc.nasa.gov/planetary/factsheet/moonfact.html> · <https://ssd.jpl.nasa.gov/horizons/> · <https://ipnpr.jpl.nasa.gov/progress_report/42-176/176C.pdf> | NSSDCA Orbital Parameters table; JPL `IPN PR 42-176` p. 1 | `nssdca_moon_light_time.json`, `jpl_horizons_ch1_sky.json`, `jpl_horizons_ch8_relay.json`, `jpl_horizons_pole_season.json`, `jpl_ipn_42_176_dte.json`, `esa_moonlight_relay.json` |

---

## 1. Engineering Trade Studies (`MP-01`)

> **Plain sentence first:** A trade study is a side-by-side comparison chart where you test two or more plans to see what each one costs in power, air, water, time, and safety before you pick the best balance and explain why.

### 1.1 NASA Source and Engineering Basis

- **Title:** *NASA Systems Engineering Handbook*
- **Document Number:** `NASA/SP-2016-6105 Rev 2` (`HQ-E-DAA-TN38707`; NTRS `20170001761`)
- **URL:** <https://ntrs.nasa.gov/citations/20170001761> (PDF: <https://ntrs.nasa.gov/api/citations/20170001761/downloads/20170001761.pdf>)
- **Sections & Pages:**
  - **Section 2.5 *Cost Effectiveness Considerations*** (printed p. 14, PDF p. 26): defines systems engineering as balancing **technical performance, cost (resources), schedule, and risk**.
  - **Section 4.3 *Logical Decomposition*** (printed pp. 82–83, PDF pp. 94–95): states that trade studies must be conducted openly and inclusively across specialty disciplines (power, life support, payload science, safety).
  - **Section 6.8 *Decision Analysis*** (printed pp. 193–201, PDF pp. 206–214), Figure 6.8-1 (*Decision Analysis Process*) and Figure 6.8-2 (*Risk Analysis of Decision Alternatives*): specifies the formal decision analysis report structure:
    1. **Decision to be made** and mission context,
    2. **Decision criteria** and mandatory constraints,
    3. **Alternatives evaluated** across the decision space,
    4. **Decision matrix scores** (quantitative resource and performance deltas),
    5. **Risks and benefits** of each option,
    6. **Recommendation / Final Decision and Rationale** (why the chosen option wins), and
    7. **Dissent** (any discipline's objection and how it was resolved).
  - **Appendix B *Glossary*** (printed p. 235, PDF p. 247): defines a **Trade Study** as *"a means of evaluating system designs by devising alternative means to meet functional requirements, evaluating these alternatives in terms of the measures of effectiveness and system cost, ranking the alternatives according to appropriate criteria."*
- **Fixture:** [`game/resources/data/nasa_practice/nasa_se_handbook_trade_studies.json`](../game/resources/data/nasa_practice/nasa_se_handbook_trade_studies.json)

### 1.2 How Trade Studies Work in *Last Light Academy*

Every major planning decision at Aurora's Mission Table or Rover Console compares candidate options across the five NASA trade dimensions adapted to outpost operations:

1. **Power (`E`, sun-drops):** battery draw or daylight solar income (`1 sun-drop ≈ 10 kWh` `[E]`; battery cap `20`; rover energy `100` in P-07 or `14` in P-15).
2. **Mass / Consumables (`A`, `W`, `K`, `R`, `C`, `H`):** oxygen tank units (`A`), shared water wall vs. garden reservoir (`W`, where `garden water = 6 - W`), cargo crate shielding (`K`), stored crew-day rations (`R`), edible crop condition (`C`), and Alo health (`H`).
3. **Risk (`Z`, slope, pressure):** crew storm exposure (`Z`), terrain slope (`deg` vs. `15°` rover limit), or cabin pressure loss (`A` leak per phase).
4. **Crew Time & Schedule:** shift duration (`7.2 h` per shift), alarm window (`15 s` guided valve task for `PUMP` vs. `30 s` bundle task for `STACK` vs. `0 s` for `WAIT`, with untimed assisted equivalents), or rover round-trip hours (`24 h + 3 h + 24 h = 51 h ≤ 72 h` in P-15).
5. **Decision Rationale & Dissent Resolution:** when two cadets hold competing priorities (for example, in P-02 shift 3–4, Rafi wants `W4` in the shelter wall before the storm while Mei warns that `W ≥ 4` leaves Alo's roots thirsty for `-1 H`), the Mission Table's side-by-side **Preview A vs. Preview B** lets the team compare both options, resolve the dissent (fill before the alarm, drain back to the garden in shifts 6–7), and commit with an explicit one-sentence **Decision Rationale**.

### 1.3 Standard In-Game Trade-Study Card Layout

Every Mission Table shift, route selection, alarm response, eclipse schedule, and chapter upgrade uses this unified card layout (extending the wireframe in [`game-design/13_UI_UX_DESIGN.md`](13_UI_UX_DESIGN.md) lines 44–55):

```text
+-----------------------------------------------------------------------------------+
| TRADE STUDY · [Decision Title, e.g., P-02 Shift 5 Storm Alarm Response]    [Back] |
| Plain goal: Protect all 4 cadets from the solar storm without losing the base.    |
| Flight Rule active: FR-03 Crew in Safe Room [LOCKED ✓] · Max Exposure Z <= 3      |
+-----------------------------------------------------------------------------------+
| CRITERION            | OPTION A: PUMP (+2 W) | OPTION B: STACK (+2 K) | OPTION C: WAIT |
|----------------------|-----------------------|------------------------|----------------|
| 1. Power (E)         | Uses chosen heat/lamp | Forces COOL/O0/L-OFF   | Uses chosen    |
|                      | (-2 to -5 E)          | (-2 E total)           | (-2 to -5 E)   |
| 2. Consumables       | Borrows +2 W from     | Keeps W in garden      | W unchanged;   |
|    (A / W / H / C)   | garden (thirst if W>=4| (no new thirst); K=2   | no extra water |
| 3. Risk / Shielding  | Shield S = min(6,W+2) | Shield S = min(6,W+2)  | Shield S = W+K |
|    [SIMULATED]       | Dose +1 Z (at S=4..5) | Dose +1 Z (at S=4..5)  | Dose +3 if S<=1|
| 4. Crew Time / Task  | 15 s 3-valve sequence | 30 s 4-bundle latch    | 0 s immediate  |
|                      | (or Assisted untimed) | (or Assisted untimed)  | (if pre-filled)|
+-----------------------------------------------------------------------------------+
| DISSENT & ROLE POLL  | Kai [GO] · Amara [GO] · Mei [ADVISORY: W>=4] · Rafi [GO]   |
| DECISION RATIONALE   | "Stage K2 bundles (or pre-fill W4) so S>=4 keeps storm     |
| (NASA SP-6105 §6.8)  |  dose to +1 Z while saving garden water for return."       |
| EVIDENCE CHIP        | [OBSERVED: DONKI 2017-09-10] [SIMULATED: S & Z table]      |
|                      | [Save as Preview A]  [Compare A vs B]  [Commit Decision]   |
+-----------------------------------------------------------------------------------+
```

**Required Card Fields (Data Contract):**
- `decision_id` and `plain_question` (one sentence for a 10–12-year-old).
- `active_flight_rules` (badge + hard constraint threshold).
- `options[]`: each with `power_delta`, `consumables_delta`, `risk_delta`, `crew_time_schedule`, and `feasibility_status` (`VALID`, `ADVISORY`, `BLOCKED_BY_FLIGHT_RULE`).
- `dissent_note`: names which two roles pull in opposite directions and how the chosen option balances them.
- `rationale_statement`: auto-summarised from the winning deltas (or chosen by the team in Class Mode) and saved to the Chapter Debrief.
- `evidence_chips[]`: `OBSERVED`, `COMPUTED`, or `SIMULATED` opening the corresponding Data Card from `game/resources/data/nasa/`.

---

## 2. Pre-Agreed Flight Rules (`MP-02`)

> **Plain sentence first:** Flight rules are safety promises the team agrees on before danger starts—like never letting breathing air hit zero or never driving a rover up a cliff—so nobody takes a reckless gamble during an emergency.

### 2.1 NASA Sources and Engineering Basis

- **Title 1:** *Flight Rules Critical Readiness Review (Increment 23/24)*
  - **Document Number:** `JSC-CN-19880` (NTRS `20100008453`)
  - **URL:** <https://ntrs.nasa.gov/citations/20100008453> (PDF: <https://ntrs.nasa.gov/api/citations/20100008453/downloads/20100008453.pdf>)
  - **Page / Section:** PDF pp. 1–4 (ISS Flight Rules Volume B, §B13/B14: pre-vetted operational constraints and contingency actions designed so each rule *"protects hardware, station and crew"* before the increment begins).
- **Title 2:** *Updates to NASA's Break-in-Prebreathe Flight Rules Due to Type II Decompression Sickness Risk Considerations*
  - **Document Number:** `NASA/TP-20240016139` (NTRS `20240016139`)
  - **URL:** <https://ntrs.nasa.gov/citations/20240016139>
  - **Page / Section:** Sections 1–2 (demonstrating how NASA codifies physiological risk limits into operational Flight Rules that govern crew timelines).
- **Title 3 (Rover Hardware Limit):** *VIPER Rover and Instruments*
  - **Document Number:** NASA VIPER Mission Page (`viper_slope_limit`)
  - **URL:** <https://science.nasa.gov/mission/viper/rover-and-instruments>
  - **Section:** Rover specifications (`15°` maximum operational slope limit).
- **Fixture:** [`game/resources/data/nasa_practice/nasa_iss_flight_rules_go_nogo.json`](../game/resources/data/nasa_practice/nasa_iss_flight_rules_go_nogo.json) and [`game/resources/data/nasa/viper_slope_limit.json`](../game/resources/data/nasa/viper_slope_limit.json)

### 2.2 Aurora Station's Six Core Flight Rules (`FR-01` to `FR-06`)

| Rule ID | Flight Rule Name | Pre-Agreed Constraint (from `08_PUZZLE_DESIGNS.md`) | How the Game Shows It | What Happens When Broken (or Attempted) |
|---|---|---|---|---|
| **FR-01** | **Crew First, Science Second** | Priority order is always: **(1) Crew safe** (`A > 0`, sheltered, `Z` within limit), **(2) Station running** (`E >= 0`, trunk pressurised), **(3) Science goal** (`Alo H > 0`, `C > 0`). | Displayed on the charter card in `EX-CH01-S01` and at the top of every Mission Table and Debrief screen (`13_UI_UX_DESIGN.md` §GAME-07: *"No suggestion ever drops crew shelter to gain flower health"*). | If `H = 0` while the crew is safe, the shift completes as *Alo Lost* (crew safe, retry offered). If `A <= 0` or `Z` exceeds limit, **FR-01** stops the mission immediately even if `H = 10`. |
| **FR-02** | **Minimum Air Margin & Protected Trunk Reserve** | Cabin oxygen `A > 0` after breathing (`1.0/shift` for 4 crew, `0.5/shift` for 2 crew, `1.25/shift` for 5 crew). The `MAIN` oxygen trunk valve must remain open during leak isolation (`P-05`). | Air bar shows red reserve zone at `A <= 1`; Preview flashes `NO-GO: Air would hit 0`. In `P-05`, `MAIN` valve carries an orange `PROTECTED RESERVE` collar. | Attempting to close `MAIN` in `P-05` triggers a **Protected Reserve Warning** and reopens immediately (`08` p. 76). Committing a shift with `A <= 0` triggers an automatic pre-loaded Flight Rule abort and restores the pre-shift checkpoint. |
| **FR-03** | **Storm Shelter & EVA Hatch Interlock** | All crew must shelter in the Safe Room during solar particle alarms (`P-02` shifts 5–6, `P-13/P-14` steps 1–6). Cumulative exposure `Z <= 3` in CH01 and `Z <= 6` in CH07. No storm EVA: outer hatch stays locked until **two** route dosimeter readings `< 1.0` taken `10 scenario minutes` apart (`P-14`). | On the `P-02` alarm panel, line 1 is pre-ticked and locked: `"Crew into Safe Room: required (flight rule)"` (`13_UI_UX_DESIGN.md` line 87). In `P-14`, the airlock hatch shows `INTERLOCKED: STORM ACTIVE`. | The player cannot uncheck Safe Room occupancy or open the EVA hatch during a storm (`08` p. 211). A single reading `< 1.0` or a `1.2` reading keeps the hatch locked with `"Second clear reading required"`. Exceeding `Z` triggers a Flight Rule stop and checkpoint retry. |
| **FR-04** | **Protected Power Bus & Recovery Allocation** | Base Basics (`1 E/shift`: CO₂ scrubbers, fans, computers) cannot be switched off. In `P-11` (eclipse), `7` of `14 E` are reserved for recovery (`allocation <= 7`). In `P-12`, the protected main habitat bus cannot be tripped while isolating faulty camera feeder `F2`. | Base Basics is locked `ON` in every shift. In `P-11`, the battery jar shows a locked `7 E RECOVERY RESERVE` bracket. In `P-12`, the main bus switch is guarded. | Spending `E < 0` in `P-02` causes a **Blackout** (`E = 0`, penalty `A - 2`, `H - 2`, `C - 2`, loses the *No Blackout* star). In `P-11`, allocating `> 7 E` warns about the reserved recovery margin and blocks Commit. In `P-12`, selecting the main bus displays a survival-services warning and refuses to trip (`08` p. 181). |
| **FR-05** | **Rover Slope Limit & Mandatory Return Reserve** | Rover slope must never exceed `15°` (NASA VIPER limit). Outbound + return energy must leave mandatory reserve `>= 30` (of `100`) in `P-07` and `>= 2` (of `14`) with total trip `51 h <= 72 h` supplies in `P-15`. Rover must be parked and braked before exterior repair. | Route cards highlight `Slope > 15°` and `Reserve < 30` (or `< 2`) in red with `[BLOCKED BY FLIGHT RULE FR-05]`. Road edges have warning boundaries. | Selecting Route A (`24°` slope) or Route C (`18°` slope, `100 - 80 = 20 < 30` reserve) in `P-07`, or the `22°` shortcut in `P-15`, is blocked at the route table with the exact rule reason. Off-road driving gently brakes at the boundary; unbraked EVA repair is interlocked (`08` pp. 106, 226). |
| **FR-06** | **Calibration & Containment Before Commit** | Instruments must pass two-point/reference calibration before measurements count (`P-01` dry `0`/wet `100`; `P-07` dry reference `2`, threshold `12`). Biological transfers require sealed carriers (`P-03`), verified pod maturity (`P-06`), and 3-stage dry warm-up before opening cold specimens (`P-08`). | Uncalibrated controls show `UNCALIBRATED — Check reference first`. The `P-08` glovebox displays `CONDENSATION HAZARD` until all three dry warm-up stages (`cold → cool → room`) are confirmed. | Sealing cassettes before calibration (`P-01`), stopping irrigation before pods mature (`P-06`), or opening the cold vault outside/before dry warm-up (`P-08`) is blocked by a non-destructive interlock that explains the physical cause (e.g., moisture condensation ruining dry seeds) without destroying specimens. |

---

## 3. Go / No-Go Console Polls (`MP-03`)

> **Plain sentence first:** Before the team locks in any big decision, all four specialists—Power, Air, Garden, and Safety—give a quick "Go" or "No-Go" check from their own station, just like NASA's Flight Director polling Mission Control.

### 3.1 NASA Sources and Engineering Basis

- **Title 1:** *International Space Station Mechanisms and Maintenance Flight Control Documentation and Training Development*
  - **Document Number:** `JSC-CN-22496` (NTRS `20100042411`)
  - **URL:** <https://ntrs.nasa.gov/citations/20100042411> (PDF: <https://ntrs.nasa.gov/api/citations/20100042411/downloads/20100042411.pdf>)
  - **Page / Section:** PDF pp. 2–6 (ISS Flight Control Operations, console discipline responsibilities, and coordinated crew/flight-controller execution).
- **Title 2:** *Conceptual Inquiry of the Space Shuttle and International Space Station GNC Flight Controllers*
  - **Document Number:** NTRS `20070016005`
  - **URL:** <https://ntrs.nasa.gov/citations/20070016005>
  - **Page / Section:** PDF pp. 1–5 (how specialized flight control disciplines evaluate telemetry against Flight Rules and report readiness to the Flight Director).
- **Fixture:** [`game/resources/data/nasa_practice/nasa_iss_flight_rules_go_nogo.json`](../game/resources/data/nasa_practice/nasa_iss_flight_rules_go_nogo.json)

### 3.2 Mapping Aurora's Crew to NASA Mission Control (MCC) Disciplines

| Aurora Character | Role & Colour (`ART_BIBLE.md` §3) | Real NASA MCC Console Equivalent | What This Station Checks in Every Go / No-Go Poll |
|---|---|---|---|
| **Kai** (19) | Power & Thermal (`#F26B21` Orange) | **SPARTAN / EECOM** (Station Power, Articulation, Thermal, and Analysis) | Battery charge `E` (`>= 0`, cap `20`), solar mast income (`+8` day, `+6` dusty), heater setting (`COZY 2 / COOL 1 / COLD 0`), feeder isolation (`F2`), and eclipse 7-unit protected reserve. |
| **Amara** (20) | Atmosphere & Verification (`#20B8C9` Cyan) | **ECLSS / ETHOS** (Environmental and Thermal Operating Systems) | Oxygen reserve `A` (`> 0`, cap `10`), electrolysis (`O = 0/1/2`), crew breathing rate (`N/4`), independent mechanical pressure gauge (`MAIN/GARDEN/RETURN`), and two-point sensor calibration. |
| **Mei** (19) | Horticulture & Science (`#4CAF50` Green) | **PAYCOM / POD** (Payload Operations Director / Science Lead) | Alo health `H` (`> 0`), edible crop `C`, lamp PAR setting (`OFF/DIM/FULL`), shared reservoir thirst (`W >= 4` causes `-1 H, -1 C`), pollination containment, pod dry-down, and the `12 + 30 = 42` seed ledger. |
| **Rafi** (20) | Safety, Radiation & EVA/Rover (`#8E5CC2` Purple) | **SR&QA / Space Weather / EVA Officer** | Solar storm forecast (DONKI replay), effective shelter `S = min(6, W + K)`, cumulative exposure `Z` (`<= 3` or `<= 6`), Safe Room occupancy, EVA hatch interlock, and rover slope (`<= 15°`) & return reserve (`>= 30` or `>= 2`). |
| **Commander Ferreira** | Mission Commander (`#B8A06A` Gold) | **Flight Director** (Earth screen CH01–04; on-site Commander CH05–08) | Final commit authority and pre-loaded Flight Rules enforcement when Earth link is down. |
| **Rao** | Earth Flight Controller | **CAPCOM** (Capsule Communicator, Houston/Earth Desk) | Single voice bridge between Earth specialists and the lunar crew; calls out link windows, telemetry checks, and uplink handovers. |

### 3.3 Poll States and Integration with Class Mode (`M1-37`) and Solo Mode

Before the **Commit** button executes a shift or multi-role operation (`P-02`, `P-05`, `P-07`, `P-11`, `P-13`, `P-14`, `P-15`, `P-16`), the Mission Table displays a four-station **Go / No-Go Poll Bar**:

1. **`GO` (Checkmark + Role Colour):** All Flight Rules and domain margins for that role are satisfied (e.g., `AMARA — GO: Air 6 -> 5 (-1 breathing), reserve safe`).
2. **`GO WITH ADVISORY` (Amber Triangle + Plain Cause):** No Flight Rule is broken, but a soft margin takes a known trade-off that the team should acknowledge (e.g., `MEI — ADVISORY: Wall W=4 borrows garden water; Alo -1 H from thirst this shift`).
3. **`NO-GO` (Octagon Stop + Flight Rule ID):** A Flight Rule would be violated or a mandatory preparation item is missing (e.g., `RAFI — NO-GO [FR-05]: Route A slope 24° exceeds 15° rover limit`, or `MEI — NO-GO [FR-06]: Founder seed case compartments 15+15 not latched`).

**How Class Mode (`M1-37`) and Solo Mode Use the Poll:**
- **In Class Mode (2–4 local players / classroom groups):** Each player or student group receives their cadet's **private role card** (via pass-the-laptop privacy screen or printed classroom envelopes per [`game-design/10_GAMEPLAY_SYSTEMS.md`](10_GAMEPLAY_SYSTEMS.md) lines 145–160). Because no single cadet sees all four clues at once (for example, in `P-02`, only Rafi sees the sunspot 2673 storm replay warning at shift 2 and only Mei sees that `W >= 4` causes root thirst at shift 3), the four players must talk out loud, compare Preview A vs. Preview B on the shared Mission Table, and **each player clicks/taps their own role's `GO` sign-off button** before `Commit Shift` unlocks.
- **In Solo Mode:** Switching cadets (`1–4` or role wheel) or opening the Journal shows all four role cards, and the confirmation modal summarizes all four station polls (`Kai: GO · Amara: GO · Mei: ADVISORY · Rafi: GO`) before a single confirm click commits the shift.

---

## 4. Procedures and Checklists in ISS Style (`MP-04`)

> **Plain sentence first:** Whenever astronauts calibrate a sensor, fix a leak, or reset a tripped power breaker, they follow a step-by-step checklist with clear warnings and a "verify" check after every move so they never skip a safety step.

### 4.1 NASA Sources and Engineering Basis

- **Title 1:** *An XML Representation for Crew Procedures*
  - **Document Number:** NASA Faculty Fellowship Program Final Report, NASA Johnson Space Center (NTRS `20050202022`)
  - **URL:** <https://ntrs.nasa.gov/citations/20050202022> (PDF: <https://ntrs.nasa.gov/api/citations/20050202022/downloads/20050202022.pdf>)
  - **Page / Section:** PDF pp. 1, 3–6 (describes how Space Shuttle and ISS Operations Data File [ODF] procedures encode expert operational knowledge into prerequisites, sequenced steps, resource constraints, and verification gates).
- **Title 2:** *NASA Spaceflight Human-System Standard, Volume 2: Human Factors, Habitability, and Environmental Health, Revision E*
  - **Document Number:** `NASA-STD-3001, Volume 2, Revision E` (NTRS `20250004555`)
  - **URL:** <https://ntrs.nasa.gov/citations/20250004555> (PDF: <https://ntrs.nasa.gov/api/citations/20250004555/downloads/NASA-STD-3001%20Vol%202%20Rev%20E%20FINAL_05022025.pdf>)
  - **Page / Section:** Section 10.6 (Electronic Procedures and Caution & Warning callout hierarchy).
- **Title 3:** *ISS Mechanisms and Maintenance Flight Control Documentation and Training Development*
  - **Document Number:** `JSC-CN-22496` (NTRS `20100042411`)
  - **URL:** <https://ntrs.nasa.gov/citations/20100042411>
  - **Page / Section:** PDF pp. 4–6 (ISS Maintenance Work Area [MWA] containment and Orbital Replacement Unit [ORU] procedure support).
- **Fixture:** [`game/resources/data/nasa_practice/nasa_iss_crew_procedures_odf.json`](../game/resources/data/nasa_practice/nasa_iss_crew_procedures_odf.json)

### 4.2 The ISS Operations Data File (ODF) Callout Hierarchy

In NASA's Operations Data File, callouts always appear **immediately before** the step to which they apply, using three strict severity levels (always paired with text + icon, never colour alone, per `SYS-10`):

1. **`[ ! WARNING ]` (Crew Safety Hazard):** An operating condition or step that, if not strictly followed, could injure the crew, exhaust breathable air, or expose astronauts to radiation (e.g., `P-05` closing the `MAIN` oxygen trunk; `P-14` opening the EVA hatch during a solar storm).
2. **`[ ▲ CAUTION ]` (Hardware, Specimen, or Data Hazard):** An operating condition or step that could damage equipment, ruin biological specimens, or corrupt mission data if done out of order (e.g., `P-01` sealing cassettes before probe calibration; `P-08` opening the cold-trap vault before the 3-stage dry warm-up; `P-12` resetting breaker `F2` before isolating the fault).
3. **`[ i NOTE ]` (Operational Context):** Essential physical or biological information that explains *why* the step works that way (e.g., `P-03` noting that *Brassica rapa* is self-incompatible and needs partner pollen; `P-10` noting that a real meteoroid impact flash appears in one frame while a hot pixel stays fixed across frames).

### 4.3 Standard In-Game Procedure Checklist Format (`Step → Action → ✓ VERIFY`)

Every hands-on repair, calibration, containment transfer, and harvest puzzle (`P-01`, `P-03`, `P-04`, `P-05`, `P-06`, `P-07`, `P-08`, `P-10`, `P-12`, `P-15`, `P-16`) presents its instructions as an interactive **ISS Procedure Card** on the left side of the puzzle screen:

```text
+-------------------------------------------------------------------------+
| ODF PROCEDURE · P-12: RESTORE CAMERA FEEDER F2 (LOC-02 POWER ROOM)      |
| Specialist: Kai (Power) · Radio Support: Rafi (Safety)                  |
+-------------------------------------------------------------------------+
| [ ! WARNING ] Do NOT trip Protected Main Bus. Habitat life support and  |
|               garden heat depend on the protected bus.                  |
| [ ▲ CAUTION ] Isolate fault current on Feeder F2 before resetting       |
|               breaker, or the breaker will trip onto a live fault.      |
|                                                                         |
| [✓] Step 1: Log Eclipse Ingress & Red Ring on Filtered Remote Camera    |
|     └── ✓ VERIFY: Ingress & Ring frames archived; Earth-limb inset seen |
| [>] Step 2: Open Feeder F2 Isolation Switch                             |
|     └── ✓ VERIFY: F2 Current = 0 A and status reads FAULT CLEARED       |
| [ ] Step 3: Reset Feeder F2 Breaker                                     |
|     └── ✓ VERIFY: Breaker latched CLOSED (0 A while isolated)           |
| [ ] Step 4: Close Feeder F2 Isolation Switch to Reconnect               |
|     └── ✓ VERIFY: Camera branch voltage nominal; main bus undisturbed   |
| [ ] Step 5: Run Camera Branch Test & Log Eclipse Egress                 |
|     └── ✓ VERIFY: Egress recorded; Rafi radio check acknowledged        |
+-------------------------------------------------------------------------+
```

**Why this teaches real NASA practice:**
- In `P-01` (*Commission and Plant*), the checklist enforces **two-point calibration** (`Step 1: Zero on DRY reference [10 -> 0] -> ✓ VERIFY: Dry reads 0`; `Step 2: Span on WET reference [110 -> 100] -> ✓ VERIFY: Wet reads 100`) before unlocking cassette watering (`40–60`, `50` nominal) and sealing.
- In `P-05` (*Find the Falling Pressure*), the checklist enforces **safe-side depressurised repair** (`Isolate GARDEN valve -> ✓ VERIFY: MAIN holds 100 and GARDEN holds 74 -> Fit captive clamp from pressurised safe side -> Slowly reopen GARDEN -> ✓ VERIFY: Five consecutive 2-second readings at 100/100/100`), because a clamp cannot seat on a pressurised leaking line.
- In `P-08` (*Recover Without Ruining*), the checklist enforces **cryogenic condensation prevention** (`Field: Probe -> Insulated Sleeve -> Cradle -> Rover Mount -> Base: Dock in Dry Glovebox -> Stage 1 Cold -> Stage 2 Cool -> Stage 3 Room -> ✓ VERIFY: Condensation = NONE -> Open Inner Seal -> Inventory 12 Specimens`).

---

## 5. Consumables and Margins from NASA BVAD (`MP-05`)

> **Plain sentence first:** Every breath of air, bite of food, drop of water, and watt of solar power in the game is scaled from NASA's real life-support rulebook so the numbers behave like a real lunar habitat.

### 5.1 NASA Sources and Engineering Basis

- **Title 1:** *Life Support Baseline Values and Assumptions Document (BVAD)*
  - **Document Number:** `NASA/TP-2015-218570/REV2` (NTRS `20210024855`)
  - **Authors:** Ewert, M.K., Chen, T.T. & Powell, C.D. (February 2022), NASA Lyndon B. Johnson Space Center
  - **URL:** <https://ntrs.nasa.gov/citations/20210024855> (PDF: <https://ntrs.nasa.gov/api/citations/20210024855/downloads/BVAD_2.15.22-final.pdf>)
  - **Page / Section:**
    - **Table 3-31 *Crewmember Mass Balance Values*** (printed p. 58, PDF p. 72): reference 82 kg crewmember daily metabolic loads:
      - Oxygen ($\text{O}_2$) consumed: **$0.895\text{ kg / crew-day}$**
      - Carbon dioxide ($\text{CO}_2$) produced: **$1.085\text{ kg / crew-day}$**
      - Dry food solids consumed: **$0.800\text{ kg / crew-day}$** (food energy $12.778\text{ MJ / crew-day}$)
      - Potable water consumed: **$3.217\text{ kg / crew-day}$**
    - **Section 3.2 & Table 4-1 *Cabin Atmosphere*** (PDF pp. 62, 75, 155): nominal ISS cabin total pressure **$101.3\text{ kPa}$** ($14.7\text{ psia}$); lunar/planetary exploration habitat atmosphere **$57\text{ kPa}$** ($8.2\text{ psia}$, $34\%\text{ O}_2$).
- **Title 2:** *Relocatable 10 kW Solar Array for Lunar South Pole Missions*
  - **Document Number:** `NASA/TM-20210011743` (NTRS `20210011743`; VSAT overview NTRS `20220013210`)
  - **URL:** <https://ntrs.nasa.gov/citations/20210011743>
  - **Page / Section:** PDF p. 5 ($10\text{ kW}$ vertical solar array blanket raised $10\text{ m}$ above the lunar surface) and PDF p. 8 ($16\text{ m}$ telescopic mast).
- **Title 3:** *Brassica rapa Grown on the ISS (NASA OSDR / GeneLab)*
  - **Document Number:** `OSD-59` (Lada, ISS Expedition 22) and `OSD-412` (Veggie `VEG-03D`, SpaceX-12)
  - **URL:** <https://osdr.nasa.gov/bio/repo/data/studies/OSD-59>
  - **Section:** Study Protocol (`125–250` and `200–300 µmol m⁻² s⁻¹` photosynthetic photon flux density, `16 h / 8 h` photoperiod, `23 °C`).
- **Fixtures:** [`bvad_2022_metabolic.json`](../game/resources/data/nasa/bvad_2022_metabolic.json), [`vsat_relocatable_array.json`](../game/resources/data/nasa/vsat_relocatable_array.json), [`osdr_brassica_rapa_iss.json`](../game/resources/data/nasa/osdr_brassica_rapa_iss.json)

### 5.2 Exact Simulation Formulas and How Game Units Map to Physical Units

Every shift in `P-02`, `P-03`, `P-05`, `P-07`, `P-10`, `P-13`, `P-14`, and `P-15` lasts **$7.2\text{ hours} = 0.3\text{ Earth days}$**, so $5\text{ dark shifts} = 36\text{ hours} = 1.5\text{ days}$ (sized to Mazarico et al. 2011, NTRS `20120010094`).

| Consumable / Lever | Game Unit & Bounds (`08_PUZZLE_DESIGNS.md`) | Physical Anchor & Conversion Formula | Simulation Update Formula per `7.2 h` Shift | Where Used |
|---|---|---|---|---|
| **Air (`A`) — Breathing** | `0..10` air units (starts `A6` in P-02; `A10` in P-03/05/13; `A8` in P-07/10/15) | $1\text{ air unit} = 4\text{ crew} \times 0.895\text{ kg/d} \times \frac{7.2\text{ h}}{24\text{ h}} = \mathbf{1.074\text{ kg O}_2}$ `[C]` (BVAD Table 3-31) | $$\Delta A_{\text{breath}} = -\frac{N_{\text{crew}}}{4}$$• $N=2 \rightarrow \mathbf{-0.5\text{ A}}$<br>• $N=4 \rightarrow \mathbf{-1.0\text{ A}}$<br>• $N=5 \rightarrow \mathbf{-1.25\text{ A}}$ | `P-02`, `P-03`, `P-05`, `P-07`, `P-10`, `P-13`, `P-14`, `P-15` |
| **Air (`O`) — Electrolysis** | `O ∈ {0, 1, 2}` air units produced per shift | Electrolysis of $\approx 1.2\text{ L}$ water yields $1.074\text{ kg O}_2$ for $\approx 10\text{ kWh} = \mathbf{1\text{ sun-drop}}$ `[E]` | $$A_{\text{pre-breath}} = \min(10,\, A + O)$$$$\Delta E_{\text{air}} = -O$$ (clamped to `10` *before* breathing is subtracted) | `P-02`, `P-03`, `P-05`, `P-07`, `P-10`, `P-13`, `P-14`, `P-15` |
| **CO₂ Scrubbing (Base Basics)** | Always `1 E/shift` (`Basics = 1`) | $4\text{ crew} \times 1.085\text{ kg/d} \times 0.3\text{ d} = \mathbf{1.302\text{ kg CO}_2\text{/shift}}$ `[C]` (BVAD Table 3-31). Unlike $\text{O}_2$, which can be stored and made later, $\text{CO}_2$ builds up within hours and must never be allowed to, so scrubbers never turn off (BVAD Rev 2 <https://ntrs.nasa.gov/api/citations/20210024855/downloads/BVAD_2.15.22-final.pdf>). | $$\Delta E_{\text{basics}} = -1\text{ (every shift, mandatory)}$$ | All shift simulations |
| **Rations (`R`) & Crop (`C`)** | `R` in crew-days (starts `12` in P-02; `18` in P-03/05/07/10/13/15). `C ∈ 0..10` (starts `8`) | $1\text{ crew-day} = \mathbf{0.800\text{ kg dry food}}$ ($12.778\text{ MJ}$) and $3.217\text{ kg}$ cycled water (BVAD Table 3-31) `[C]` | $$\Delta R = -N_{\text{crew}} \times \frac{7.2}{24} = -0.3\,N_{\text{crew}}\text{ crew-days}$$• $N=2 \rightarrow \mathbf{-0.6}$ (`P-07` 2 shifts = `-1.2`; `P-15` 33 h + 3 h = `-3.375`)<br>• $N=4 \rightarrow \mathbf{-1.2\text{/shift}}$<br>• $N=5 \rightarrow \mathbf{-1.5\text{/shift}}$<br>Mature crop harvest between chapters: $\text{Yield} = \text{round}(4 \times C / 10,\, 1)$ crew-days `[G]` | `P-02`, `P-03`, `P-05`, `P-07`, `P-10`, `P-13`, `P-14`, `P-15` |
| **Energy (`E`) — Solar & Battery** | `0..20` sun-drops (`0..32` in CH07; `0..26` in CH08); day income `+8` (`+6` when dusty in P-10) | $1\text{ sun-drop} \approx \mathbf{10\text{ kWh}}$ `[E]`. Two $10\text{ kW}$ VSAT masts (`NASA/TM-20210011743`) at $56\%$ mean polar factor produce $80\text{ kWh} / 7.2\text{ h} = \mathbf{11.1\text{ kW}} = +8\text{ drops/shift}$ `[E]` | $$E_{\text{avail}} = \min(E_{\text{cap}},\, E + E_{\text{solar}})$$$$E_{\text{next}} = E_{\text{avail}} - (\text{Basics} + \text{Heat} + O + L)$$(If $E_{\text{next}} < 0$: **Blackout** $\rightarrow E=0,\, A-2,\, H-2,\, C-2$; $E=0$ exact is **not** a blackout) | `P-02`, `P-03`, `P-05`, `P-07`, `P-10`, `P-11`, `P-13`, `P-14`, `P-15` |
| **Shared Water (`W`) & Crate Shielding (`K`)** | `W ∈ 0..6` (`FILL +2`, `HOLD 0`, `DRAIN -2`), `K ∈ 0..2` (`0..3` with Safe Room upgrade) | $6\text{ W units} = \mathbf{20\text{ g/cm}^2} = 20\text{ cm water}$ (`1 unit = 3.33 g/cm²`, Clowdsley 2021 NTRS `20210009760`) `[C]`. Borrowed from the garden hydroponic reservoir. | $$\text{Garden usable water} = 6 - W$$If post-transfer $W \ge 4$: **Thirst** applies $\Delta H_{\text{thirst}} = -1$ and $\Delta C_{\text{thirst}} = -1$ `[G]` | `P-02`, `P-13`, `P-14` |
| **Garden Heat & Light (`L`)** | Heat: `COZY (2 E)`, `COOL (1 E)`, `COLD (0 E)` (daylight automatically warm `0 E`). Light: `OFF (0 E)`, `DIM (1 E)`, `FULL (2 E)` | Heat: `COZY ≈ 20 °C (2.8 kW)`, `COOL ≈ 10 °C (1.4 kW)`, `COLD` near or below freezing (`≈ 0 °C`; heavy *Brassica* frost is below `−2 °C`, Canola Council of Canada <https://www.canolacouncil.org/canola-watch/2017/09/07/fall-frost-swathing-and-straight-combining-considerations>) `[E]`. Light: `FULL ≈ 200–300 µmol m⁻² s⁻¹` (OSDR `OSD-412`), `DIM ≈ light compensation point`, `OFF = dark respiration` `[M/E]` | • **Alo (`H`):** $\Delta H = \Delta H_{\text{light}} (-1/0/+1) + \Delta H_{\text{heat}} (-2/-1/0) + \Delta H_{\text{thirst}} (-1\text{ if }W\ge 4)$<br>• **Crop (`C`):** $\Delta C = \Delta C_{\text{light}} (-1/0/+1) + \Delta C_{\text{heat}} (-1\text{ if COLD else }0) + \Delta C_{\text{thirst}} (-1\text{ if }W\ge 4)$ | `P-02`, `P-03`, `P-05`, `P-07`, `P-10`, `P-13`, `P-14`, `P-15` |

---

## 6. Radiation: Permissible Exposure Limits and ALARA (`MP-06`)

> **Plain sentence first:** Radiation in space is invisible, so astronauts use instruments to spot solar storms early and put water and cargo walls around their shelter to keep crew dose as low as reasonably achievable (ALARA).

### 6.1 NASA Sources and Engineering Basis

- **Title 1:** *NASA Space Flight Human-System Standard, Volume 1: Crew Health*
  - **Document Number:** `NASA-STD-3001, Volume 1, Revision B` (Approved 5 January 2022), NASA Office of the Chief Health and Medical Officer (OCHMO)
  - **URL:** <https://www.nasa.gov/wp-content/uploads/2020/10/2022-01-05_nasa-std-3001_vol.1_rev._b_final_draft_with_signature_010522.pdf>
  - **Sections & Pages:**
    - **Section 4.8.1 `[V1 4029]` *As Low as Reasonably Achievable (ALARA) Principle*** (p. 29): *"All crew radiation exposures shall be minimized using the ALARA principle… which requires programs to minimize radiation exposures below the limits/standards within the design constraints of the mission."*
    - **Section 4.8.2 `[V1 4030]` *Career Space Permissible Exposure Limit*** (pp. 29–30): individual astronaut total career effective radiation dose shall be **less than $600\text{ mSv}$**.
    - **Table 3 *Dose Limits for Short-Term or Career Non-Cancer Effects*** (p. 30): Blood-Forming Organs (BFO) **30-day limit $= 250\text{ mGy-Eq}$**, 1-year limit $= 500\text{ mGy-Eq}$; Circulatory System 30-day limit $= 250\text{ mGy-Eq}$; Lens 30-day limit $= 1,000\text{ mGy-Eq}$; Skin 30-day limit $= 1,500\text{ mGy-Eq}$.
    - **Section 4.8.3 `[V1 4031]` *Short-Term Radiation Limits – Solar Particle Events*** (pp. 31–32): *"The program shall protect crewmembers from exposure to the design reference solar particle event (SPE) environment proton energy spectrum (sum of the October 1989 events) to less than a NASA effective dose of **$250\text{ mSv}$**."*
    - **Section 4.8.4 `[V1 4032]` *Crew Radiation Limits for Nuclear Technologies*** (p. 33): less than **$20\text{ mSv}$** effective dose per mission year.
- **Title 2:** *NASA-STD-3001 Technical Brief: Design for Ionizing Radiation Protection*
  - **Document Number:** `OCHMO-TB-020 Rev E`
  - **URL:** <https://www.nasa.gov/wp-content/uploads/2023/03/radiation-protection-technical-brief-ochmo.pdf>
  - **Pages:** pp. 1–2 (summarising `[V1 4029]`–`[V1 4032]` and `[V2 6095]`–`[V2 6101]` space weather monitoring, alerting, and dosimetry).
- **Title 3:** *Protecting Astronauts from Space Radiation on the Lunar Surface*
  - **Document Number:** NTRS `20210009760` (Clowdsley, M., 9 February 2021, NASA Langley Research Center)
  - **URL:** <https://ntrs.nasa.gov/citations/20210009760> (PDF: <https://ntrs.nasa.gov/api/citations/20210009760/downloads/Clowdsley_Lunar_Radiation_Talk_v2.pdf>)
  - **Pages / Slides:** Slides 15 (`250 mGy-Eq` BFO limit), 16 & 31 (`20 g/cm²` of hydrogen-rich shielding as the target **for GCR protection**; slides 21–22 recommend storm shelters for SPEs; PDF <https://ntrs.nasa.gov/api/citations/20210009760/downloads/Clowdsley_Lunar_Radiation_Talk_v2.pdf>), and 37 (August 1972 SPE effective dose inside a lunar rover shelter: **$185.4\text{ mSv}$ at $5\text{ g/cm}^2$**, **$136.9\text{ mSv}$ at $7\text{ g/cm}^2$**, **$105.4\text{ mSv}$ at $10\text{ g/cm}^2$**, **$85.1\text{ mSv}$ at $15\text{ g/cm}^2$**).
- **Fixtures:** [`nasa_std_3001_radiation.json`](../game/resources/data/nasa_practice/nasa_std_3001_radiation.json), [`clowdsley_2021_shielding.json`](../game/resources/data/nasa/clowdsley_2021_shielding.json), [`donki_2017_09.json`](../game/resources/data/nasa/donki_2017_09.json), [`goes13_protons_2017_09.json`](../game/resources/data/nasa/goes13_protons_2017_09.json), [`donki_2012_07.json`](../game/resources/data/nasa/donki_2012_07.json), [`stereo_a_het_2012_07.json`](../game/resources/data/nasa/stereo_a_het_2012_07.json), [`crater_dose_2012_07.json`](../game/resources/data/nasa/crater_dose_2012_07.json), [`change4_lnd_surface_dose.json`](../game/resources/data/nasa/change4_lnd_surface_dose.json)

### 6.2 Honest Mapping Between Real Shielding / Dose Limits and Game Teaching Units (`S` and `Z`)

Per [`production/ART_BIBLE.md`](../production/ART_BIBLE.md) §2 rule 6 and [`game-design/16_SCIENTIFIC_ACCURACY.md`](16_SCIENTIFIC_ACCURACY.md) (`SCI-11`), radiation is **never visible outside** (only instruments detect it), and game exposure `Z` ("zaps") is explicitly labelled as a **`SIMULATED` teaching unit**, never called millisieverts (`mSv`).

| Game Parameter | Game Rule (`08_PUZZLE_DESIGNS.md`) | Real NASA Standard / Physical Basis | How Engineer Mode & Data Cards Label It Honestly |
|---|---|---|---|
| **Effective Shelter `S = min(6, W + K)`** | `W ∈ 0..6` (water wall) + `K ∈ 0..2` (supply bundles, `K=3` with upgrade), capped at `S = 6` | **$20\text{ g/cm}^2$ of water** keeps the worst recorded solar storms under the 25 rem 30-day limit (Townsend, Nealy & Wilson 1988, NTRS `19880016043`, p. 4, <https://ntrs.nasa.gov/citations/19880016043>); the current SPE shelter requirement is `NASA-STD-3001 Vol 1 Rev B [V1 4031]` (250 mSv for the design SPE, <https://www.nasa.gov/wp-content/uploads/2020/10/2022-01-05_nasa-std-3001_vol.1_rev._b_final_draft_with_signature_010522.pdf>). Clowdsley 2021 (slides 16 & 31) uses the same thickness as its target for GCR protection. Each unit of `W` or `K` represents **$20 / 6 \approx 3.33\text{ g/cm}^2$** ($\approx 3.3\text{ cm}$ of water equivalent) `[C]`. | Wall bar shows `0..6 units` with Engineer Mode subtitle `0..20 g/cm² water-equivalent shielding [C]`. |
| **Storm Shift Dose Table (`3 / 2 / 1 / 0`)** | Base dose per storm shift (`P-02` shifts 5–6; multiplied by `[1,1,2,2,1,1]` in `P-13/P-14`):<br>• `S ∈ {0, 1}` $\rightarrow \mathbf{+3\text{ Z}}$<br>• `S ∈ {2, 3}` $\rightarrow \mathbf{+2\text{ Z}}$<br>• `S ∈ {4, 5}` $\rightarrow \mathbf{+1\text{ Z}}$<br>• `S = 6` $\rightarrow \mathbf{+0\text{ Z}}$ | Clowdsley (slide 37) shows dose drops steeply from $185.4\text{ mSv}$ ($5\text{ g/cm}^2$) to $136.9\text{ mSv}$ ($7\text{ g/cm}^2$), $105.4\text{ mSv}$ ($10\text{ g/cm}^2$), and $85.1\text{ mSv}$ ($15\text{ g/cm}^2$), with diminishing returns above $20\text{ g/cm}^2$, but **physical dose never reaches zero**. | Tagged `SIMULATED [G]`. On screen and in the Science Card, `0 Z` at `S = 6` is explained as **"0 storm-excess points (below the storm operational limit)"**, displayed alongside Clowdsley's real $185 \rightarrow 85\text{ mSv}$ curve (`SCIENCE_AND_DATA.md` §B3-3, §B3-12). |
| **Permissible Exposure Limit (`Z <= 3` in CH01; `Z <= 6` in CH07)** | Mission stops if cumulative `Z > 3` (`P-02`) or `Z > 6` (`P-14`), or if any crewmember is outside the Safe Room during a storm shift. | Represents `NASA-STD-3001 Vol 1 Rev B [V1 4031]` short-term SPE limit (**$< 250\text{ mSv}$** effective dose per event) and `Table 3` 30-day BFO limit (**$250\text{ mGy-Eq}$**). | Labelled `Flight Rule FR-03: Max Storm Exposure Z <= 3 (CH1) / Z <= 6 (CH7) [SIMULATED teaching threshold for NASA-STD-3001 250 mSv SPE limit]`. |
| **ALARA Principle (`[V1 4029]`)** | Even though `Z = 3` passes `P-02`, the team uses Rafi's shift-2 forecast (`DONKI 2017-09-06 X9.3 flare`) to stage `W4` or `K2` before the shift-5 alarm (`2017-09-10 X8.2 flare, 70 min lead time`), finishing the Bloom and Golden witnesses at **`Z = 2`** (and **`Z = 0`** in the `P-13/P-14` witness with `W4 + K2 = S6`). | `NASA-STD-3001 [V1 4029]` requires driving crew radiation exposure **As Low As Reasonably Achievable** below the hard limit, balanced against mission system constraints (power and garden water). | Debrief highlights **ALARA in action**: how early space-weather warning + water/cargo staging kept `Z` below the maximum allowed limit without killing Alo from thirst. |
| **Post-Storm Route Dosimeter (`P-14`)** | Two readings `< 1.0` (`0.4`, then `0.3` ten scenario minutes apart) clear the exterior route; `1.2` blocks EVA. | Anchored to Chang'e-4 LND quiet-Sun lunar surface dose rate (**$13.2 \pm 1\text{ µGy/h}$** in silicon, Zhang et al. 2020, `change4_lnd_surface_dose.json`) and STEREO-A HET post-peak decay (`stereo_a_het_2012_07.json`). | Tagged `SIMULATED [G]` with Engineer Mode note: `Threshold 1.0 represents returning to near-quiet surface background (Chang'e-4 reference: 13.2 µGy/h)`. |

---

## 7. Risk: The NASA 5×5 Matrix, ISS MER Anomaly Resolution, and Debrief (`MP-07`)

> **Plain sentence first:** When something breaks or behaves strangely, NASA scores how likely and how serious the danger is on a 5-by-5 grid, tests one branch at a time with a backup gauge before fixing it, and holds a blame-free team debrief afterwards.

### 7.1 NASA Sources and Engineering Basis

- **Title 1:** *NASA Risk Management Handbook*
  - **Document Number:** `NASA/SP-2011-3422-Version-1.0` (`HQ-STI-11-205`, NTRS `20120000033`) and *Version 2.0, Part 1*, `NASA/SP-20240014019` (NTRS `20240014019`); complemented by *NASA Systems Engineering Handbook*, `NASA/SP-2016-6105 Rev 2`, Section 6.4 *Technical Risk Management* (printed pp. 160–168, PDF pp. 172–180).
  - **URL:** <https://ntrs.nasa.gov/citations/20120000033> · <https://ntrs.nasa.gov/citations/20240014019> · <https://ntrs.nasa.gov/citations/20170001761>
  - **Page / Section:** `SP-2011-3422` Section 4.3 (PDF pp. 101–165, Figure 45 & Figure 53) and `SP-2016-6105 Rev 2` Section 6.4: defines the standard **If–Then Risk Statement** (*"Given that [CONDITION], there is a possibility of [DEPARTURE], leading to [CONSEQUENCE]"*) and the **5×5 Likelihood × Consequence Risk Matrix** across Safety, Technical/Performance, Cost/Consumables, and Schedule.
- **Title 2:** *Anomaly Resolution in the International Space Station* & *Apollo Experience Report: Flight Anomaly Resolution*
  - **Document Numbers:** `JSC-CN-6337` (Evans, W.A., 2000, NTRS `20100036651`) and `NASA-TN-D-7968` / `JSC-S-412` (Lobb, J.D., 1975, NTRS `19750017909`)
  - **URL:** <https://ntrs.nasa.gov/citations/20100036651> · <https://ntrs.nasa.gov/citations/19750017909>
  - **Page / Section:** `JSC-CN-6337` pp. 1–2 (ISS Mission Evaluation Room [MER] groundrules, fault-tree isolation, manual fault isolation, and post-mission analysis).
- **Title 3:** *Constellation Program Lessons Learned: Detailed Lessons Learned – Volume 2* & *NASA Lessons Learned Information System (LLIS)*
  - **Document Number:** `NASA/SP-2011-6127-VOL-2` (`JSC-CN-24727`, NTRS `20110015803`)
  - **URL:** <https://ntrs.nasa.gov/citations/20110015803> · <https://llis.nasa.gov/>
  - **Page / Section:** `SP-2011-6127-VOL-2` Preface (factual, non-blaming presentation of context, root cause, and actionable lessons learned).
- **Fixture:** [`game/resources/data/nasa_practice/nasa_risk_and_anomaly_mer.json`](../game/resources/data/nasa_practice/nasa_risk_and_anomaly_mer.json)

### 7.2 The NASA 5×5 Likelihood × Consequence Risk Matrix in Gameplay

Every hazard and anomaly in *Last Light Academy* is scored on NASA's $5 \times 5$ grid (`Likelihood 1..5` $\times$ `Consequence 1..5`), where **Consequence `5`** is a crew safety breach or mission loss, **`4`** is a major threat to Alo/crops or reserve margin, **`3`** is moderate reserve drain, **`2`** is minor consumable/comfort loss, and **`1`** is negligible:

```text
           CONSEQUENCE (1 = Negligible  --->  5 = Catastrophic Crew/Mission Loss)
LIKELIHOOD |   1: Negligible   |    2: Minor     |   3: Moderate   |    4: Major     | 5: Catastrophic
-----------+-------------------+-----------------+-----------------+-----------------+-----------------
5: Very    | MODERATE (Yellow) | MODERATE (Yel)  | HIGH (Red)      | HIGH (Red)      | HIGH (Red)
   Likely  |                   |                 | P-02 Thirst W>=4| P-02 Blackout   | P-02/13 Unshielded
-----------+-------------------+-----------------+-----------------+-----------------+-----------------
4: Likely  | LOW (Green)       | MODERATE (Yel)  | HIGH (Red)      | HIGH (Red)      | HIGH (Red)
           |                   | P-10 Panel Dust | P-05 Garden Leak| P-14 Ext Uplink | P-07 Route A 24°
-----------+-------------------+-----------------+-----------------+-----------------+-----------------
3: Possible| LOW (Green)       | MODERATE (Yel)  | MODERATE (Yel)  | HIGH (Red)      | HIGH (Red)
           |                   | P-10 Hot Pixels | P-12 Feeder F2  | P-08 Cold Vault | P-05 Aftershock
-----------+-------------------+-----------------+-----------------+-----------------+-----------------
2: Unlikely| LOW (Green)       | LOW (Green)     | MODERATE (Yel)  | MODERATE (Yel)  | HIGH (Red)
           |                   |                 |                 |                 | P-05 Close MAIN
-----------+-------------------+-----------------+-----------------+-----------------+-----------------
1: Very    | LOW (Green)       | LOW (Green)     | LOW (Green)     | MODERATE (Yel)  | HIGH (Red)
   Unlikely|                   |                 |                 |                 | Storm EVA (P-14)
```

- **`HIGH (Red)` risks** are either blocked outright by a **Flight Rule interlock** (e.g., `1×5` Storm EVA in `P-14`, `2×5` closing `MAIN` trunk in `P-05`, `4×5` driving a `24°` slope in `P-07`) or require **mandatory mitigation before Commit** (e.g., `5×5` unshielded storm in `P-02`/`P-13` mitigated down to `LOW/MODERATE` by staging `W4 + K2`).
- **`MODERATE (Yellow)` risks** trigger a role **Advisory** on the Mission Table and a dedicated **ISS MER Anomaly Resolution** task (`P-05` leak, `P-10` dust/micro-leak, `P-12` feeder `F2` trip).

### 7.3 Five-Step ISS Mission Evaluation Room (MER) Anomaly Resolution Workflow

When an anomaly strikes Aurora (`P-04`, `P-05`, `P-09`, `P-10`, `P-12`, `P-14`, `P-15`, `P-16`), the cadets never guess or mash switches. They follow the five-step ISS MER workflow (`JSC-CN-6337`, NTRS `20100036651`):

1. **Step 1 — Safe the Crew and Protected Systems:** Brace during the moonquake (`EX-CH02-S12`), verify automatic annex isolation after the phase-2 aftershock (`P-05`), or keep the Protected Main Bus untouched when `F2` trips (`P-12`).
2. **Step 2 — Verify with an Independent Instrument (Reject Sensor Artifacts):**
   - In `P-05`, panel location labels have initial uncertainty, so Amara uses the **independent mechanical gauge** across `MAIN` (`100/100`), `GARDEN` (`82 → 74`), and `RETURN` (`100/100`).
   - In `P-10`, the crew compares **two camera frames** (NASA MEO method, `meo_lunar_impact_flashes.json`) to separate `6–8` genuine meteoroid impact flashes from `2` persistent fixed hot-pixel detector artifacts.
   - In `P-04` and `P-09`, the crew cross-checks primary timestamps, serial plates (`2034-04`, `HORT-01`, `ENGINEERING`), and all four boarding signatures before drawing a conclusion.
3. **Step 3 — Isolate Branches Along a Fault Tree:**
   - In `P-05`, compare all `6` candidate branches (`main tank, habitat trunk, garden feedthrough, return line, airlock seal, annex branch`) at `≤ 2` inspections per phase, then close **only** the `GARDEN` isolation valve.
   - In `P-14`, test three communication branches in order: `Local Network = PASS`, `Direct Dish Path = FAIL`, `External Feedthrough = FAIL` $\rightarrow$ uniquely isolating fault **`F-EXT`**.
4. **Step 4 — Repair on the De-Energised / Safe Side:**
   - Apply the captive clamp to the `GARDEN` feedthrough from the pressurised safe side (`P-05`), patch the isolated dome spur (`P-10`), reset `F2` only after confirming `0 A` (`P-12`), swap the repeater battery with the rover braked (`P-15`), and replace the summit controller with the housing isolated at `0 V` (`P-16`).
5. **Step 5 — Reconnect and Run Multi-Sample Verification:**
   - Reopen `GARDEN` slowly and verify **five consecutive 2-second readings at `100/100/100`** (`P-05`); test the camera branch and log egress (`P-12`); verify repeater chain `R1 → R2 → R3` (`P-15`) and `ALO42` checksum + dual voice checks (`P-16`).

### 7.4 Blame-Free Lessons-Learned Debrief (`GAME-07` & Chapter Upgrades)

Following NASA's Lessons Learned standard (`NASA/SP-2011-6127-VOL-2` and `llis.nasa.gov`), every chapter ends with a calm, blame-free **5-Panel Debrief** (`13_UI_UX_DESIGN.md` §GAME-07):
1. **Factual Outcome Line** (crew safety, blackout status, Alo/garden state, named ending).
2. **Most Influential Decision** (computed by re-running the real simulation with one shift changed at a time across safe alternatives, e.g., `"Shift 4: FILL -> HOLD would have left Alo +1"`).
3. **One Trade-Off Explained** with its `OBSERVED` / `COMPUTED` / `SIMULATED` evidence chip.
4. **One-Change Replay** from the checkpoint using the exact same simulation rules.
5. **Who Knew What & Engineering Upgrade Selection:** reviews how the four roles shared private clues and lets the team turn their lesson learned into one persistent station upgrade for the next chapter (e.g., *Taller Mast* vs. *Fuel-Cell Battery* after CH01; *Dust Shield* vs. *Whipple Bumper* after CH05, per `10_GAMEPLAY_SYSTEMS.md` lines 168–179).

---

## 8. Communication: CAPCOM Call-Outs, Horizons Link Windows, and Light-Time Delay (`MP-08`)

> **Plain sentence first:** Because radio waves travel in straight lines at the speed of light, messages to Earth take about 1.3 seconds each way and stop completely whenever the Moon's mountains or rim hide Earth below the horizon.

### 8.1 NASA Sources and Engineering Basis

- **Title 1:** *Moon Fact Sheet* (NASA GSFC Space Science Data Coordinated Archive, NSSDCA)
  - **Author / Agency:** Williams, D.R. (2024), NASA Goddard Space Flight Center
  - **URL:** <https://nssdc.gsfc.nasa.gov/planetary/factsheet/moonfact.html>
  - **Section:** Orbital Parameters table (Semimajor axis $0.3844 \times 10^6\text{ km} = 384,400\text{ km}$; mean perigee $363,300\text{ km}$; mean apogee $405,500\text{ km}$). Dividing by $c = 299,792.458\text{ km/s}$ gives:
    - **One-way light-time:** **$1.282\text{ s}$ mean** ($1.212\text{ s}$ at perigee to $1.353\text{ s}$ at apogee) `[C]`.
    - **Two-way round-trip light-time:** **$2.564\text{ s}$ mean** ($2.424\text{–}2.705\text{ s}$) `[C]`.
- **Title 2:** *JPL Horizons On-Line Ephemeris System (DE441)*
  - **Agency:** NASA Jet Propulsion Laboratory
  - **URL:** <https://ssd.jpl.nasa.gov/horizons/> (API documentation: <https://ssd-api.jpl.nasa.gov/doc/horizons.html>)
  - **Datasets:** Target `399` (Earth) and Target `10` (Sun) from `coord@301` lunar south pole (`0°E, -90°`) and Mons Malapert (`-1.67°E, -85.98°`).
- **Title 3:** *Lunar Pole Illumination and Communications Maps Computed from Goldstone Solar System Radar Elevation Data*
  - **Document Number:** JPL *Interplanetary Network (IPN) Progress Report 42-176* (Bryant, S., 15 February 2009)
  - **URL:** <https://ipnpr.jpl.nasa.gov/progress_report/42-176/176C.pdf>
  - **Page:** p. 1 (best south-pole site has **$92\%$ solar availability** and **$51\%$ direct-to-Earth [DTE] availability** due to monthly $\pm 6.7^\circ$ latitude libration, while elevated peaks near the pole can maintain continuous Earth view).
- **Title 4:** *ESA Moonlight Programme* (Partner Agency)
  - **URL:** <https://www.esa.int/Applications/Connectivity_and_Secure_Communications/Moonlight2>
  - **Section:** Programme overview (terrain and curvature at the lunar south pole block direct line-of-sight to Earth, requiring surface/orbital relays).
- **Fixtures:** [`nssdca_moon_light_time.json`](../game/resources/data/nasa_practice/nssdca_moon_light_time.json), [`jpl_horizons_ch1_sky.json`](../game/resources/data/nasa/jpl_horizons_ch1_sky.json), [`jpl_horizons_ch8_relay.json`](../game/resources/data/nasa/jpl_horizons_ch8_relay.json), [`jpl_horizons_pole_season.json`](../game/resources/data/nasa/jpl_horizons_pole_season.json), [`jpl_ipn_42_176_dte.json`](../game/resources/data/nasa/jpl_ipn_42_176_dte.json), [`esa_moonlight_relay.json`](../game/resources/data/nasa/esa_moonlight_relay.json)

### 8.2 How Communication Works in Gameplay

1. **CAPCOM Voice Protocol Through Rao (`CH_Rao`):**
   - Just as NASA's **CAPCOM** in Houston is the single voice bridge to the crew, **Rao** at the Earth Control Desk consolidates ground telemetry into concise call-outs using real voice procedure:
     - **Station Calling:** `"Aurora, Earth Control..."` / `"Earth Control, Aurora copies."`
     - **Closed-Loop Readbacks:** Critical numbers and Flight Rule handovers require explicit readback (e.g., in `EX-CH01-S09` / `CS-02`, Ferreira instructs: *"Local rules remain active. Read back the next safe action"* before the link greys out).
     - **No Invented Radio During LOS:** After the authored Earth-link cutoff (`P-02` shifts 4–7; Earth is below the pole's horizon from 15 to 28 Apr 2046 and rising during this night, JPL Horizons <https://ssd.jpl.nasa.gov/api/horizons.api>) or when the external uplink feedthrough `F-EXT` is damaged (`P-14`, `P-15`), live calls from Rao or Earth are physically impossible (`10_GAMEPLAY_SYSTEMS.md` line 206: *"while Earth is down it is stored guidance or a local companion, never a new live Rao transmission"*).
2. **Earth Link Windows from JPL Horizons Fixtures:**
   - **Chapter 1 (`jpl_horizons_ch1_sky.json`):** At the exact south pole (`0°E, -90°`), Earth set on `15 Apr 2046` and stayed `$3.4° \rightarrow 1.4°$` below the ideal horizon across `25–27 Apr 2046`, rising on `28 Apr 2046`, and rising all through the night. Height cannot turn a rising Earth into a setting one, so the shift-4 **Earth-link cutoff** is an authored training event, not an Earth-set (`SCIENCE_AND_DATA.md` §B3-5, `production/review/science_review_ch01.md` B1), labelled **`SIMULATED · training scenario`** on the HUD horizon strip. Source: JPL Horizons <https://ssd.jpl.nasa.gov/api/horizons.api>.
   - **Chapter 8 (`jpl_horizons_ch8_relay.json` & `usgs_gazetteer_south_pole.json`):** On `9 Apr 2047 00:45–01:45 UT`, Earth is $4.3^\circ\text{–}6.7^\circ$ below the horizon at the pole (so Aurora is cut off after its direct uplink fails), but from **Mons Malapert** (`-1.67°E, -85.98°`, `121.9 km` great-circle distance from the pole) Earth sits at azimuth **`357.9°–358.0°`**, geometric elevation **`-2.3°`**, which clears a smooth lunar horizon from any point **$\ge 1.40\text{ km}$** above the $1,737.4\text{ km}$ reference sphere (`Malapert summit ≈ 5 km`).
   - **Four-Hop Surface Repeater Chain (`P-15` & `P-16`):** Because line-of-sight is blocked by lunar curvature and ridges over the `120 km` road, the rover crew restores Marker 2's battery to link **Aurora $\rightarrow$ R1 $\rightarrow$ R2 $\rightarrow$ R3 $\rightarrow$ Malapert Summit** (local bearing `L2` $\approx 176.7^\circ$ toward Shackleton) and aims the summit dish at Earth (`E3` $\approx 358^\circ$ azimuth).
3. **Light-Time Delay (`1.28 s` One-Way / `2.56 s` Round-Trip):**
   - Displayed on the Earth Console status header (`Link: LIVE · 1.3 s one-way / 2.6 s round-trip [C: NSSDCA 384,400 km]`) and felt as a natural ~2.6-second turnaround pause before Earth replies during `P-16`'s `ALO42` checksum handshake and Dr. Noor Rahman's first live call in `EX-CH08-S10` (`CS-15`).

---

## 9. Complete 16-Puzzle Traceability Matrix (`P-01` to `P-16`)

> **Plain sentence first:** This table shows which of the eight NASA practices and which exact verified data files power every single puzzle from Chapter 1 to Chapter 8.

Tags follow [`docs/SCIENCE_AND_DATA.md`](../docs/SCIENCE_AND_DATA.md) §B2: **`[M]`** measured in a fixture, **`[C]`** computed from a fixture, **`[E]`** engineering estimate with a named basis, **`[G]`** gameplay value, **`[F]`** fiction. All numbers match [`game-design/08_PUZZLE_DESIGNS.md`](08_PUZZLE_DESIGNS.md) word for word.

| Puzzle & Mission | Plain 1-Sentence Learner Goal | NASA Mission Practices Used (`MP-01`..`MP-08`) | Exact Game Numbers (`08_PUZZLE_DESIGNS.md`) & Honesty Tags | Offline Fixtures in `game/resources/data/nasa/` |
|---|---|---|---|---|
| **P-01** Commission and Plant (`EX-M0101`) | Calibrate the moisture probe with dry and wet references before watering and sealing Alo and Tara's cassettes. | • **MP-02** Flight Rule `FR-06` (no sealing before calibration)<br>• **MP-04** ISS ODF Checklist (`Zero -> Span -> Recheck -> Scan -> 1+1 Seeds -> Water 50 -> Seal`) | • One seed per cassette `[M-practice]` (Veggie pillow thinning)<br>• Probe offset `+10`; dry `10 -> 0`, wet `110 -> 100` `[G]`<br>• Moisture band `40–60`, nominal `50`; seed count `1 + 1` `[G]` | `osdr_brassica_rapa_iss.json`, `fast_plants_lifecycle.json`, `nasa_iss_crew_procedures_odf.json`, `nasa_iss_flight_rules_go_nogo.json` |
| **P-02** Seven Shifts, One Night (`EX-M0102`) | Balance battery power, breathing air, garden warmth, and water-wall radiation shielding across a 36-hour lunar night and solar storm. | • **MP-01** Trade Studies (Preview A/B on Mission Table)<br>• **MP-02** Flight Rules `FR-01`..`FR-04`<br>• **MP-03** Go/No-Go Polls (Kai, Amara, Mei, Rafi; Class Mode `M1-37`)<br>• **MP-05** BVAD Consumables & VSAT Power<br>• **MP-06** Radiation PELs (`Z <= 3`) & ALARA (`Z = 2`)<br>• **MP-07** 5×5 Risk Matrix & 5-Panel Debrief<br>• **MP-08** CAPCOM Handover & Horizons Sky | • `7` shifts $\times$ `7.2 h` (`5` dark = `36 h` `[E]`, Mazarico `1.5 d` `[M]`)<br>• `E14/20` `[G]`, day `+8` (`11.1 kW` from two `10 kW` VSAT masts `[E]`), basics `-1` `[E]`<br>• `A6/10` `[G]`, breathing `-1/shift` (`1.074 kg O2` for 4 crew `[C]`), `O ∈ {0,1,2}` `[E]`<br>• `R12`, `-1.2 crew-days/shift` (`4 × 0.3 d` `[C]`); crop `C8/10`, yield `round(4*C/10, 1)` `[G]`<br>• `H6/10`; heat `COZY 2 / COOL 1 / COLD 0` (`0/-1/-2 H`) `[E/G]`; light `OFF 0 / DIM 1 / FULL 2` (`-1/0/+1 H`) `[M/G]`<br>• `W0..6` (`20 g/cm²` `[C]`), `K0..2`, `S = min(6, W+K)`, thirst at `W >= 4` (`-1 H, -1 C`) `[G]`<br>• Storm shifts `5–6` (`DONKI 2017-09-10` X8.2, `70 min` lead `[M]`; `GOES-13` east-facing detector `1,493.5 pfu` peak `[M]`), dose `3/2/1/0` `[G]`, limit `Z <= 3`, Bloom/Golden witness `Z = 2` | `donki_2017_09.json`, `goes13_protons_2017_09.json`, `lro_mazarico_2011_illumination.json`, `jpl_horizons_pole_season.json`, `jpl_horizons_ch1_sky.json`, `bvad_2022_metabolic.json`, `vsat_relocatable_array.json`, `clowdsley_2021_shielding.json`, `osdr_brassica_rapa_iss.json`, `nasa_se_handbook_trade_studies.json`, `nasa_iss_flight_rules_go_nogo.json`, `nasa_std_3001_radiation.json`, `nasa_risk_and_anomaly_mer.json`, `nssdca_moon_light_time.json` |
| **P-03** Alo Meets Tara (`EX-M0201`) | Cross-pollinate Alo and Tara three times with clean brushes through a sealed interlock after checking space weather. | • **MP-01** Trade Study (daylight `E1/A1` budget per bee run)<br>• **MP-02** Flight Rule `FR-06` (containment & space-weather check)<br>• **MP-04** ISS ODF Checklist (Brush A Tara$\rightarrow$Alo, Brush B Alo$\rightarrow$Tara)<br>• **MP-05** BVAD 4-crew breathing & 7-day ration ledger | • Self-incompatible; stigma receptive `2–4 d`; pollinate days `15–21` `[M]`<br>• `3` reciprocal runs on days `1, 4, 7` (`30 Apr–6 May`, plant days `19–25`) `[F/M]`<br>• Entry `E14/20, A10/10, H6, C8, R18`; `E1/A1` per run; witness `E16, A4, H9, C10, R14.4` `[C/G]`<br>• Background 7-day crew consumption `28` crew-days (`4 crew × 7 d`) `[C]` | `fast_plants_lifecycle.json`, `mir_brassica_seed_to_seed.json`, `donki_2017_09.json`, `bvad_2022_metabolic.json`, `nasa_se_handbook_trade_studies.json`, `nasa_iss_flight_rules_go_nogo.json`, `nasa_iss_crew_procedures_odf.json` |
| **P-04** Recorder Reconstruction (`EX-M0202`) | Match the date, device, and channel labels from equipment plates to unlock the 2034 engineering audio log. | • **MP-04** ISS ODF Verification (match all 3 metadata fields before playback)<br>• **MP-07** MER Investigation (primary plate evidence; suspicion vs. proof)<br>• **MP-08** CAPCOM / Earth Transmission to Ferreira | • Tokens `A.DATE = 2034-04`, `B.DEVICE = HORT-01`, `C.CHANNEL = ENGINEERING` `[F]`<br>• Modeled on NASA PDS date/instrument/channel archive metadata (`urn:nasa:pds:apollo_seismic_event_catalog`) `[M-practice]` | `apollo_shallow_moonquakes.json`, `nasa_iss_crew_procedures_odf.json`, `nasa_risk_and_anomaly_mer.json`, `nssdca_moon_light_time.json` |
| **P-05** Find the Falling Pressure (`EX-M0301`) | Use an independent mechanical gauge to isolate a moonquake pressure leak to the garden feedthrough and clamp it safely. | • **MP-01** Trade Study (4 investigation phases, `<= 2` checks/phase)<br>• **MP-02** Flight Rule `FR-02` (`MAIN` trunk protected reserve interlock)<br>• **MP-03** Go/No-Go Poll before valve isolation<br>• **MP-04** ISS ODF Repair Checklist (isolate $\rightarrow$ clamp $\rightarrow$ `5 × 2 s` verify)<br>• **MP-05** BVAD `101.3 kPa` nominal & `A1/phase` breathing<br>• **MP-07** ISS MER 6-branch fault tree & aftershock annex isolation | • Apollo `28` shallow moonquakes; `13 Mar 1973` (`84°S, 134°W`, mag `3.2`) `[M]`<br>• `4` phases $\times$ `7.2 h`; entry `E14, A10, H6, C8, R18`; `DIM/O0` (`-2 E/phase`); leak `-1 A` in phases `1–3`; witness `E18, A3, H6, C8, R13.2` `[C/G]`<br>• Mechanical gauge `t0/t10`: `MAIN 100/100`, `GARDEN 82/74`, `RETURN 100/100` `[G]` (anchored to `101.3 kPa` `[M]`)<br>• Reopen verify: `5` consecutive `2 s` checks at `100/100/100` `[G]` | `apollo_shallow_moonquakes.json`, `bvad_2022_metabolic.json`, `nasa_se_handbook_trade_studies.json`, `nasa_iss_flight_rules_go_nogo.json`, `nasa_iss_crew_procedures_odf.json`, `nasa_risk_and_anomaly_mer.json` |
| **P-06** A Harvest With a Future (`EX-M0302`) | Confirm Alo's seed pods are mature, dry them down to safe storage moisture, and allocate 12 seeds for planting and 30 for the founder reserve. | • **MP-01** Trade Study (`12` active planting vs. `30` protected founder reserve)<br>• **MP-02** Flight Rule `FR-06` (block dry-down before maturity; protect live Tara)<br>• **MP-04** ISS ODF Harvest & Containment Checklist | • Pod maturity `16 May` (plant day `35`); dry-down to `21 May` (day `40`) `[M]` (Fast Plants `~20 d` post-pollination, `~40 d` total)<br>• Moisture `70 -> <= 20` `[G]`<br>• `6` pods $\times$ `7` = `42` seeds (`12` planting + `30` founder reserve) `[F]` | `fast_plants_lifecycle.json`, `mir_brassica_seed_to_seed.json`, `nasa_se_handbook_trade_studies.json`, `nasa_iss_flight_rules_go_nogo.json`, `nasa_iss_crew_procedures_odf.json` |
| **P-07** Survey and Return (`EX-M0401`) | Pick the only cold-trap rover route that respects the 15° slope limit and 30-unit return reserve, place three beacons, and calibrate the ice scanner. | • **MP-01** Trade Study (Route A vs. Route B vs. Route C)<br>• **MP-02** Flight Rules `FR-05` (`<= 15°` slope, `>= 30` reserve) & `FR-06` (dry ref calibration)<br>• **MP-03** Go/No-Go Poll (Aurora slope card + Rover headlight card)<br>• **MP-04** ISS ODF Calibration Checklist<br>• **MP-05** BVAD `A0.5/shift` for 2 home cadets<br>• **MP-07** 5×5 Risk Matrix (slope & blind-corner mitigation) | • VIPER slope limit **`15°`** `[M]`; LCROSS ice **`5.6 ± 2.9%`** `[M]`; Diviner **`38 K`** `[M]`; M3 patchy ice **`~3.5%`** of traps `[M]`<br>• Rover `100`, reserve `>= 30` `[G]`; Route A (`8 km`, cost `35×2=70`, `24°` FAIL), **Route B (`12 km`, cost `30×2=60`, reserve `40 >= 30`, `12° <= 15°` PASS)**, Route C (`10 km`, cost `40×2=80`, reserve `20 < 30`, `18°` FAIL) `[G]`<br>• Scanner dry ref `2`, threshold `2 + 10 = 12`, samples `2` (neg), `18` & `19` (pos) `[G]`<br>• Base `2` shifts (`N=2` home): `E14->18, A8->7 (-0.5/shift), R18->16.8 (-0.6/shift)` `[C/G]` | `viper_slope_limit.json`, `lcross_water_2009.json`, `diviner_cold_traps.json`, `chandrayaan1_m3_ice.json`, `kaguya_shackleton_floor.json`, `bvad_2022_metabolic.json`, `nasa_se_handbook_trade_studies.json`, `nasa_iss_flight_rules_go_nogo.json`, `nasa_iss_crew_procedures_odf.json`, `nasa_risk_and_anomaly_mer.json` |
| **P-08** Recover Without Ruining (`EX-M0402`) | Bring the cold-trap seed vault home in an insulated sleeve and warm it through three dry glovebox stages so condensation never touches the 12 seed packets. | • **MP-02** Flight Rule `FR-06` (interlock against opening cold vault in humid cabin air)<br>• **MP-04** ISS ODF 3-Stage Dry Glovebox Checklist (`cold -> cool -> room`)<br>• **MP-07** Risk Management (viability marked *pending evaluation*, not assumed) | • Cold-trap floor **`38 K`** (`-235 °C`, Diviner) `[M]` and **`< 90 K`** (Kaguya) `[M]`<br>• Field sequence: `Probe -> Sleeve -> Cradle -> Mount` `[G]`<br>• Glovebox sequence: `Cold -> Cool -> Room -> Condensation Check -> Open` `[G]`<br>• `12` distinct vault specimens `[F]` | `diviner_cold_traps.json`, `kaguya_shackleton_floor.json`, `nasa_iss_flight_rules_go_nogo.json`, `nasa_iss_crew_procedures_odf.json`, `nasa_risk_and_anomaly_mer.json` |
| **P-09** Reconstruct the Departure (`EX-M0501`) | Place four primary 2034 records in timestamp order and verify from boarding signatures that all four Expedition Zero crew returned safely. | • **MP-04** ISS ODF Evidence Verification<br>• **MP-07** MER Investigation (chronology reconstruction `Apr 3 -> Apr 4 12:00 -> 12:10 -> 12:40`; reject unsupported accusation) | • Chang'e-4 `2019` cotton sprouted but ended at seedling stage `[M]`<br>• Chronology: Seedling chart (`Apr 3`) $\rightarrow$ Relay/power fault (`Apr 4 12:00`) $\rightarrow$ Evacuation order (`12:10`) $\rightarrow$ Boarding manifest (`12:40`, `4 departed / 4 boarded`, `FER` & `N.R.`) `[F]` | `change4_cotton.json`, `nasa_iss_crew_procedures_odf.json`, `nasa_risk_and_anomaly_mer.json` |
| **P-10** Flashes and a Signature (`EX-M0502`) | Separate genuine lunar meteoroid impact flashes from fixed camera hot pixels, clean solar dust and patch a dome micro-leak, and send Noor's invitation. | • **MP-01** Trade Study (immediate maintenance restores `+8` solar and stops `-1 A` leak)<br>• **MP-02** Flight Rule `FR-06` (two-frame verification; consent gate)<br>• **MP-04** ISS ODF Maintenance Checklist (panel clean + safe-side spur patch)<br>• **MP-05** BVAD 5-crew breathing (`A1.25/phase`) & rations (`R1.5/phase`)<br>• **MP-07** MER Artifact Rejection (`8` flashes vs. `2` fixed hot pixels)<br>• **MP-08** Earth Message Transmission | • NASA MEO two-telescope coincidence method (`126` flashes, `62%` in showers) `[M]`<br>• `8` genuine transients (`>= 6` required, `8` for Golden) + `2` fixed artifacts `[G]`<br>• `3` phases $\times$ `7.2 h` with `5` crew (incl. Ferreira): breathing **`1.25 A/phase`**, food **`1.5 R/phase`** `[C]`<br>• Dust cuts solar `8 -> 6` `[G]`; micro-leak costs `1 A/phase` (`0.5` with flexible seals) `[G]`<br>• Witness: `E14 -> E16`, `A8 -> A4.25`, `H6`, `C8`, `R18 -> R13.5`, `Z0` `[C/G]` | `meo_lunar_impact_flashes.json`, `bvad_2022_metabolic.json`, `vsat_relocatable_array.json`, `nasa_se_handbook_trade_studies.json`, `nasa_iss_flight_rules_go_nogo.json`, `nasa_iss_crew_procedures_odf.json`, `nasa_risk_and_anomaly_mer.json`, `nssdca_moon_light_time.json` |
| **P-11** Protect the Small Light (`EX-M0601`) | Schedule battery power across the five phases of the 12 January 2047 total lunar eclipse while protecting the 7-unit recovery reserve. | • **MP-01** Trade Study (`7 E` eclipse budget vs. `7 E` recovery reserve; decorative floods `3 E` rejected)<br>• **MP-02** Flight Rule `FR-04` (essentials mandatory in all 5 segments; `allocation <= 7`)<br>• **MP-03** Go/No-Go Poll across all 5 segments<br>• **MP-08** Earth Contact Window (eclipse feed & family audio call) | • NASA Eclipse Catalog `#09755` (`12 Jan 2047`, Saros `125`): greatest `01:24:44 UT`, penumbral **`337.2 min`**, partial **`208.9 min`**, total **`70.0 min`** `[M]`; Sun `+0.14°` at pole `[C]`<br>• `5` segments (`precharge, ingress, totality, egress, recovery`); `7` of `14 E` allocated (`E7` reserved) `[G]`<br>• Essentials `[1,1,1,1,1] = 5`, pump `1` (seg 1), camera `1` (seg 2), floods `0` (`3 E` each OFF) $\rightarrow$ total `7 E` `[G]` | `nasa_eclipse_2047_01_12.json`, `jpl_horizons_pole_season.json`, `nasa_se_handbook_trade_studies.json`, `nasa_iss_flight_rules_go_nogo.json`, `nssdca_moon_light_time.json` |
| **P-12** Observe, Isolate, Restore (`EX-M0602`) | Record the eclipse through a filtered camera and safely isolate, reset, and test tripped feeder F2 without disturbing the protected habitat bus. | • **MP-02** Flight Rule `FR-04` (Protected Main Bus interlocked)<br>• **MP-04** ISS ODF Electrical Fault Procedure (`Isolate F2 -> Verify 0 A & FAULT CLEARED -> Reset -> Reconnect -> Test Branch`)<br>• **MP-07** MER Fault Isolation with companion radio check (Kai + Rafi) | • Eclipse contacts `U1 23:40`, `U2 00:50`, `U3 02:00`, `U4 03:09 UT` (`ingress -> ring -> egress`) `[M]`<br>• Feeder `F2` trip recovery: `Isolate -> Current = 0 -> Reset -> Close -> Camera Test` `[G]` | `nasa_eclipse_2047_01_12.json`, `nasa_iss_flight_rules_go_nogo.json`, `nasa_iss_crew_procedures_odf.json`, `nasa_risk_and_anomaly_mer.json` |
| **P-13** One Integrated Storm Plan (`EX-M0701`) | Build a six-step shelter, power, water, and seed-protection plan for all five crew before the three-wave counterfactual July 2012 superstorm hits. | • **MP-01** Trade Study (6-step plan balancing `W4 + K2 = S6`, `E30/32`, and `H1/C3` survival)<br>• **MP-02** Flight Rules `FR-01`..`FR-04` & `FR-06` (`15+15` seeds latched, uplink isolated)<br>• **MP-03** 5-Person Go/No-Go Poll (Cadets assume command under Ferreira's eyes)<br>• **MP-05** BVAD 5-crew rates (`A1.25`, `R1.5/step`)<br>• **MP-06** Radiation PELs & ALARA (`S6 = 20 g/cm²` $\rightarrow$ `Z = 0`)<br>• **MP-07** 5×5 Risk Mitigation | • `23 Jul 2012` CME **`3,435 km/s`**, onset `03:59 UT`, shock `20:55 UT` (`DONKI` `[M]`); `STEREO-A HET` 80 MeV step fluence `[0.16, 0.69, 1.00, 0.02, 0.01, 0.00]` `[C]`; `LRO CRaTER` D1 `0.57 -> 3.92 mGy/d` `[M]`<br>• `6` dark steps $\times$ `7.2 h`; multipliers `[1,1,2,2,1,1]` `[G]`<br>• Entry `E30/32, A10/10, H6, C8, R18`; `W [4,4,4,4,4,2]`, `K2` $\rightarrow$ `S6` (`0` game dose), `COZY/DIM/O0` (`4 E/step × 6 = 24 E`), 5-crew breathing `1.25/step`, food `1.5/step` `[C/G]`<br>• Witness: `E6, A2.5, H1, C3, R9, Z0`, founder reserve `15 + 15 = 30` safe `[C/G/F]` | `donki_2012_07.json`, `stereo_a_het_2012_07.json`, `crater_dose_2012_07.json`, `clowdsley_2021_shielding.json`, `bvad_2022_metabolic.json`, `nasa_se_handbook_trade_studies.json`, `nasa_iss_flight_rules_go_nogo.json`, `nasa_std_3001_radiation.json`, `nasa_risk_and_anomaly_mer.json` |
| **P-14** Three Waves and a Broken Link (`EX-M0702`) | Execute the six-step storm plan inside the Safe Room, diagnose why the Earth link failed after the storm, and verify the outside route is safe with two dosimeter checks. | • **MP-02** Flight Rule `FR-03` (`Z <= 6`; storm EVA hatch interlock; `2` clear readings `< 1.0` ten minutes apart)<br>• **MP-04** ISS ODF Post-Storm Diagnostic & Dosimetry Checklist<br>• **MP-06** Radiation PELs (`Z <= 6`) & Surface Dosimetry (`change4_lnd_surface_dose`)<br>• **MP-07** ISS MER 3-branch Comms Fault Tree (`Local PASS, Dish FAIL, Feedthrough FAIL -> F-EXT`) | • `STEREO-A HET` post-peak decay `[M]`; Chang'e-4 quiet surface dose **`13.2 ± 1 µGy/h`** `[M]`<br>• Execute `6` steps (`Z <= 6`, witness `Z = 0`) `[G]`<br>• Fault isolation: `Local PASS`, `Direct Dish FAIL`, `External Feedthrough FAIL` $\rightarrow$ select **`F-EXT`** `[G]`<br>• Route dosimeter threshold `1.0`: readings **`0.4`** then **`0.3`** (`10 min` apart) clear route; **`1.2`** blocks EVA `[G]` | `stereo_a_het_2012_07.json`, `donki_2012_07.json`, `change4_lnd_surface_dose.json`, `clowdsley_2021_shielding.json`, `bvad_2022_metabolic.json`, `nasa_iss_flight_rules_go_nogo.json`, `nasa_iss_crew_procedures_odf.json`, `nasa_std_3001_radiation.json`, `nasa_risk_and_anomaly_mer.json` |
| **P-15** Two Teams, One Road (`EX-M0801`) | Split the five-person crew between the 120 km Malapert rover expedition and Aurora Station, keeping both teams within power, air, slope, and return reserves while restoring Repeater 2. | • **MP-01** Trade Study (surveyed road `12°` / cost `5` vs. shortcut `22°` / cost `3.5`; home `COOL/DIM/returnOPEN`)<br>• **MP-02** Flight Rules `FR-02` (home air) & `FR-05` (`<= 15°` slope, rover reserve `>= 2`, `51 h <= 72 h` supplies, brake before EVA)<br>• **MP-03** Dual-Team Go/No-Go Poll (`FER/KAI/RAF` Rover + `MEI/AMA` Home)<br>• **MP-04** ISS ODF Repeater 2 Battery Swap Checklist<br>• **MP-05** BVAD split-crew breathing (`2.8125 A`)<br>• **MP-07** MER Repeater Chain Test (`R1 -> R2 -> R3`) | • Pole $\rightarrow$ Mons Malapert **`121.9 km`** great circle (`USGS Gazetteer #16338`, `-85.98°, -1.67°`) `[C]`; VIPER limit **`15°`** `[M]`<br>• Rover `E14`, outbound `5` + return `5` = `10`, reserve **`4 >= 2`**; time `24 h + 3 h + 24 h = 51 h <= 72 h` `[G]`<br>• Surveyed road max **`12° <= 15°`** PASS; shortcut **`22° > 15°`** FAIL `[G/M]`<br>• Home (`E20/26, A8, H6, C8, R18`): `5` shifts `COOL/DIM/basic` = `15 E` $\rightarrow$ `E5, H1, C8` `[G]`<br>• Home air: `33 h` at `2` crew (`4.5833 × 0.5 = 2.29167 A`) + `3 h` at `5` crew (`0.4167 × 1.25 = 0.52083 A`) = **`2.8125 A`** $\rightarrow$ ends **`A5.1875`**; rations **`R14.625`** `[C]` | `usgs_gazetteer_south_pole.json`, `viper_slope_limit.json`, `bvad_2022_metabolic.json`, `esa_moonlight_relay.json`, `nasa_se_handbook_trade_studies.json`, `nasa_iss_flight_rules_go_nogo.json`, `nasa_iss_crew_procedures_odf.json`, `nasa_risk_and_anomaly_mer.json` |
| **P-16** The Link and the Living Garden (`EX-M0802`) | Replace the damaged Malapert summit relay controller, lock both antennas onto Aurora and Earth, verify the `ALO42` checksum and Noor's live voice, and pass the final five-point sunrise safety check at home. | • **MP-01** Trade Study (link handover before Earth-set window)<br>• **MP-02** Flight Rules `FR-04` (isolate power before opening housing) & `FR-06` (5 final sunrise checks before opening shutter)<br>• **MP-03** Final 5-Crew Go/No-Go Poll before sunrise shutter<br>• **MP-04** ISS ODF Controller Replacement & Link Validation Checklist<br>• **MP-07** MER End-to-End Link Verification (`ALO42`)<br>• **MP-08** Horizons Earth/Local Bearings, CAPCOM/Noor Live Call & `2.56 s` Light-Time Delay | • Horizons (`9 Apr 2047 00:45–01:45 UT`): Earth from Malapert az **`357.9°–358.0°`**, el **`-2.3°`** (clears smooth horizon at **`>= 1.40 km`** height); Earth at pole `-4.3°` to `-6.7°` `[C]`<br>• Bearing Malapert $\rightarrow$ Shackleton **`176.7°`** (`USGS Gazetteer`) `[C]`; JPL IPN `42-176` (`51%` DTE at pole, continuous view on peaks) `[M]`<br>• Light-time delay **`1.282 s`** one-way / **`2.564 s`** round-trip (`NSSDCA 384,400 km`) `[C]`<br>• Presets `L2` (Aurora chain) + `E3` (Earth), `3 s` lock `[G]`, checksum **`ALO42`** `[F]`, return `24 h` `[G]`, `5` final sunrise checks (`crew 5 safe, reserve 30 + 11 vault seeds, pressure stable, temp stable, cotton alive`) | `jpl_horizons_ch8_relay.json`, `usgs_gazetteer_south_pole.json`, `esa_moonlight_relay.json`, `jpl_ipn_42_176_dte.json`, `nssdca_moon_light_time.json`, `nasa_se_handbook_trade_studies.json`, `nasa_iss_flight_rules_go_nogo.json`, `nasa_iss_crew_procedures_odf.json`, `nasa_risk_and_anomaly_mer.json` |

---

## 10. Proposals for User Review (No Numbers Changed in `08_PUZZLE_DESIGNS.md`)

Per `AGENTS.md` and `M1-39`, **no number in [`game-design/08_PUZZLE_DESIGNS.md`](08_PUZZLE_DESIGNS.md) has been altered**. Below are optional, zero-breakage presentation proposals for the user to approve that reinforce the eight NASA mission practices on screen while keeping every existing puzzle number and solution witness identical:

1. **Proposal MP-P1 (Show `NASA-STD-3001 [V1 4031]` and `[V1 4029]` on the Storm Shielding Card — `P-02`, `P-13`, `P-14`):**
   - *Current state:* `08_PUZZLE_DESIGNS.md` defines `Z <= 3` (CH01) and `Z <= 6` (CH07) as game exposure limits and `S = 6` as giving `0` game dose.
   - *Proposal:* Keep the exact `3/2/1/0` table and `Z <= 3` / `Z <= 6` rules, and add one line on the Safe Room UI and `SRC-SHIELDING` card citing `NASA-STD-3001 Vol 1 Rev B [V1 4031]` ($250\text{ mSv}$ short-term SPE limit) and `[V1 4029]` (ALARA), wording `0 Z` at `S = 6` as *"0 storm-excess points (below the storm operational limit; physical dose in Clowdsley 2021 is ~85 mSv at 15 g/cm²)"*.
2. **Proposal MP-P2 (Name the Four MCC Console Roles on Class Mode Role Cards — `M1-37`, All Chapters):**
   - *Current state:* Cadets are labelled Power/Heat (Kai), Atmosphere (Amara), Horticulture (Mei), and Safety (Rafi).
   - *Proposal:* In Engineer Mode and on the printable Class Mode role cards (`M1-37`), show the real ISS Mission Control console badge beside each cadet's title (`Kai — SPARTAN/EECOM`, `Amara — ECLSS/ETHOS`, `Mei — PAYCOM`, `Rafi — SR&QA / Space Weather / EVA`, `Rao — CAPCOM`, `Ferreira — Flight Director`).
3. **Proposal MP-P3 (Display the `1.28 s` One-Way / `2.56 s` Round-Trip Light-Time Chip on Earth Calls — `P-02`, `P-04`, `P-10`, `P-11`, `P-16`):**
   - *Current state:* Earth link windows and `ALO42` checksum are shown, without a numeric light-time label.
   - *Proposal:* Display `Link: LIVE · 1.28 s one-way (384,400 km) [C: NSSDCA]` on the Earth Console header whenever Earth is above the horizon or connected through the Malapert relay (`nssdca_moon_light_time.json`), with a skip-friendly `2.5 s` audio/caption turnaround beat on the first `ALO42` handshake in `P-16`.
4. **Proposal MP-P4 (Include the 15 Data-Traceability Proposals from `docs/SCIENCE_AND_DATA.md` §B3):**
   - Retain all 15 proposals already catalogued in [`docs/SCIENCE_AND_DATA.md`](../docs/SCIENCE_AND_DATA.md) §B3 (labelling `P-05` gauge `100` as `% of 101.3 kPa ISS nominal pressure` from BVAD; anchoring `P-14` route threshold `1.0` to twice Chang'e-4's `13.2 µGy/h` quiet-Sun surface dose; showing the `GOES-13` east-facing detector's `1.6×` shift-6/shift-5 proton flux ratio and `STEREO-A HET`'s single-peak curve on the debrief cards without altering game balance unless approved).
